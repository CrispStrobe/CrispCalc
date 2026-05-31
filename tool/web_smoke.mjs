#!/usr/bin/env node
// tool/web_smoke.mjs
//
// Headless-browser smoke test for the CrispCalc web build. Drives a real
// Chromium via the DevTools Protocol (zero npm deps — Node >= 21 global
// `fetch` + `WebSocket`), loads the deployed SPA, waits for the SymEngine
// WASM module to finish loading, and asserts that the in-browser CAS
// actually computes a battery of expressions. Also checks the Flutter view
// renders.
//
// Why a separate harness: a Flutter `flutter test` runs on the Dart VM and
// cannot launch a browser or load the WASM module. This validates the
// layer that unit tests can't reach — the deployed page + WASM + ccall
// bridge. The Dart-side fallbacks (factor/integrate/expand/diff/solve) are
// covered by `flutter test`; this covers the WASM path and the deploy.
//
// Usage:
//   node tool/web_smoke.mjs [url]
//   CRISPCALC_WEB_SMOKE_URL=https://crisp-calc.vercel.app node tool/web_smoke.mjs
//   CHROME_PATH=/path/to/chrome node tool/web_smoke.mjs http://localhost:8099/
//
// Exit code: 0 = all assertions passed, non-zero = a failure (or no browser
// / page never became ready). Emits a final line `WEB_SMOKE_JSON=<json>`
// with structured results for programmatic consumers (the Dart test parses
// it).

import { spawn } from 'node:child_process';
import { existsSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const URL =
  process.argv[2] ||
  process.env.CRISPCALC_WEB_SMOKE_URL ||
  'https://crisp-calc.vercel.app/';

const READY_TIMEOUT_MS = Number(process.env.WEB_SMOKE_TIMEOUT_MS || 30000);
const DEBUG_PORT = Number(process.env.WEB_SMOKE_PORT || 0) || 9300 + (process.pid % 500);

// Expected in-browser ccall results. Each calls a flutter_symengine_* C
// entry point through the WASM module's `ccall` and compares the string.
const CASES = [
  { name: 'version', fn: 'flutter_symengine_version', types: [], args: [], expect: (v) => /^\d+\.\d+\.\d+/.test(v) },
  { name: 'expand', fn: 'flutter_symengine_expand', types: ['string'], args: ['(x+1)^2'], expect: (v) => v.replace(/\s/g, '') === '1+2*x+x**2' },
  { name: 'differentiate', fn: 'flutter_symengine_differentiate', types: ['string', 'string'], args: ['x^3', 'x'], expect: (v) => v.replace(/\s/g, '') === '3*x**2' },
  { name: 'solve', fn: 'flutter_symengine_solve', types: ['string', 'string'], args: ['x^2 - 4', 'x'], expect: (v) => v.replace(/\s/g, '') === '[2,-2]' || v.replace(/\s/g, '') === '[-2,2]' },
  { name: 'gcd', fn: 'flutter_symengine_gcd', types: ['string', 'string'], args: ['12', '18'], expect: (v) => v.trim() === '6' },
  // The wrapper forces a complex evalf, so a real result reads as
  // "14.0 + 0.0*I" — assert the real part rather than an exact string.
  { name: 'evaluate', fn: 'flutter_symengine_evaluate', types: ['string'], args: ['2 + 3*4'], expect: (v) => Math.abs(parseFloat(v) - 14) < 1e-9 },
  // FLINT/GMP/MPFR-backed (full WASM parity): real factorization, number
  // theory, and arbitrary-precision evaluation in the browser.
  { name: 'factor', fn: 'flutter_symengine_factor', types: ['string'], args: ['x**4 + 4'], expect: (v) => v.includes('2 + 2*x + x**2') && v.includes('2 - 2*x + x**2') },
  { name: 'isprime', fn: 'flutter_symengine_isprime', types: ['string'], args: ['97'], expect: (v) => v.trim() === 'true' },
  { name: 'factorint', fn: 'flutter_symengine_factorint', types: ['string'], args: ['360'], expect: (v) => v.replace(/\s/g, '') === '2^3*3^2*5' },
  // Real simplify (rational cancellation). Multivariate factor is native-
  // only — FLINT's fmpz_mpoly_factor aborts under wasm32 — so it's covered
  // by the native integration suite, not here.
  { name: 'simplify', fn: 'flutter_symengine_simplify', types: ['string'], args: ['(x**2 - 1)/(x - 1)'], expect: (v) => v.replace(/\s/g, '') === '1+x' || v.replace(/\s/g, '') === 'x+1' },
];

function findChrome() {
  if (process.env.CHROME_PATH && existsSync(process.env.CHROME_PATH)) {
    return process.env.CHROME_PATH;
  }
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
    '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
    '/usr/bin/microsoft-edge',
  ];
  return candidates.find((p) => existsSync(p));
}

async function cdp(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0;
  const pending = new Map();
  const handlers = [];
  await new Promise((res, rej) => {
    ws.addEventListener('open', res, { once: true });
    ws.addEventListener('error', rej, { once: true });
  });
  ws.addEventListener('message', (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg);
      pending.delete(msg.id);
      return;
    }
    for (const h of handlers) h(msg);
  });
  return {
    send: (method, params = {}) =>
      new Promise((resolve) => {
        const mid = ++id;
        pending.set(mid, resolve);
        ws.send(JSON.stringify({ id: mid, method, params }));
      }),
    on: (fn) => handlers.push(fn),
    close: () => ws.close(),
  };
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  const chrome = findChrome();
  if (!chrome) {
    console.error('SKIP: no Chromium-family browser found (set CHROME_PATH).');
    process.exit(3);
  }
  console.log(`browser : ${chrome}`);
  console.log(`url     : ${URL}`);

  const profile = mkdtempSync(join(tmpdir(), 'cc-web-smoke-'));
  const proc = spawn(chrome, [
    '--headless=new',
    '--disable-gpu',
    '--no-first-run',
    '--no-default-browser-check',
    `--remote-debugging-port=${DEBUG_PORT}`,
    '--remote-allow-origins=*',
    `--user-data-dir=${profile}`,
    'about:blank',
  ], { stdio: 'ignore' });

  let conn;
  const cleanup = () => {
    try { conn?.close(); } catch {}
    try { proc.kill('SIGKILL'); } catch {}
    try { rmSync(profile, { recursive: true, force: true }); } catch {}
  };

  try {
    // Wait for the CDP HTTP endpoint.
    let target;
    for (let i = 0; i < 50 && !target; i++) {
      await sleep(200);
      try {
        const r = await fetch(`http://127.0.0.1:${DEBUG_PORT}/json`);
        const targets = await r.json();
        target = targets.find((t) => t.type === 'page');
      } catch { /* not up yet */ }
    }
    if (!target) throw new Error('Chrome CDP endpoint never came up');

    conn = await cdp(target.webSocketDebuggerUrl);
    const consoleLines = [];
    conn.on((m) => {
      if (m.method === 'Runtime.consoleAPICalled') {
        consoleLines.push((m.params.args || []).map((a) => a.value ?? '').join(' '));
      }
    });
    await conn.send('Runtime.enable');
    await conn.send('Page.enable');
    await conn.send('Page.navigate', { url: URL });

    // Poll until the WASM loader sets window.symEngineReady. The first
    // visit installs a service worker which can reload the page (resetting
    // the JS context), so we evaluate freshly each tick rather than caching
    // a context id, and tolerate the transient.
    const debug = !!process.env.WEB_SMOKE_DEBUG;
    const deadline = Date.now() + READY_TIMEOUT_MS;
    let ready = false;
    while (Date.now() < deadline) {
      await sleep(500);
      const r = await conn.send('Runtime.evaluate', {
        expression:
          'JSON.stringify({r: !!window.symEngineReady, i: !!window.symEngineInstance, rs: document.readyState})',
        returnByValue: true,
      });
      const raw = r.result?.result?.value;
      if (debug) console.log(`  poll: ${raw ?? r.result?.exceptionDetails?.text ?? '(no value)'}`);
      try {
        const st = JSON.parse(raw);
        if (st.r && st.i) { ready = true; break; }
      } catch { /* stale context mid-reload; retry */ }
    }

    const results = [];
    let allPass = ready;
    if (!ready) {
      console.log('FAIL  wasm-ready  (symEngineReady never became true)');
    } else {
      for (const c of CASES) {
        const expr = `(function(){try{return window.symEngineInstance.ccall(${JSON.stringify(c.fn)},'string',${JSON.stringify(c.types)},${JSON.stringify(c.args)});}catch(e){return 'THREW:'+String(e);}})()`;
        const r = await conn.send('Runtime.evaluate', { expression: expr, returnByValue: true });
        const value = r.result?.result?.value ?? '';
        const pass = (() => { try { return c.expect(String(value)); } catch { return false; } })();
        allPass = allPass && pass;
        results.push({ name: c.name, value: String(value), pass });
        console.log(`${pass ? 'PASS' : 'FAIL'}  ${c.name.padEnd(14)} -> ${JSON.stringify(value)}`);
      }
    }

    // Flutter view render check. CanvasKit boots slower than the WASM
    // module, so poll for the view element rather than checking once.
    let rendered = false;
    const renderDeadline = Date.now() + 20000;
    while (Date.now() < renderDeadline) {
      const dom = await conn.send('Runtime.evaluate', {
        expression: `!!document.querySelector('flutter-view, flt-glass-pane')`,
        returnByValue: true,
      });
      if (dom.result?.result?.value === true) { rendered = true; break; }
      await sleep(500);
    }
    allPass = allPass && rendered;
    console.log(`${rendered ? 'PASS' : 'FAIL'}  flutter-render -> ${rendered}`);

    const wasmLoadedLog = consoleLines.some((l) => /SymEngine WASM loaded/.test(l));
    console.log(`${wasmLoadedLog ? 'PASS' : 'WARN'}  console-load   -> ${wasmLoadedLog}`);

    const summary = { url: URL, ready, rendered, wasmLoadedLog, results, allPass };
    console.log(`\nWEB_SMOKE_JSON=${JSON.stringify(summary)}`);
    cleanup();
    process.exit(allPass ? 0 : 1);
  } catch (e) {
    console.error('ERROR:', e?.message || e);
    cleanup();
    process.exit(2);
  }
}

main();
