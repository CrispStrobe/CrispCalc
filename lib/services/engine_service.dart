// lib/services/engine_service.dart
//
// Long-evaluation off-main-thread wrapper. The native SymEngine bridge
// is synchronous FFI — calls block the calling isolate until they
// return. For a big integral or matrix inversion that can mean
// 1–5 seconds of UI freeze. This service offloads that work to a
// long-lived worker isolate that owns one `SymbolicMathBridge`
// instance and processes requests via SendPort/ReceivePort.
//
// V1 (round 51) used `compute()` per call. V2 (round 56) added a
// generic op dispatch. V3 (this round) replaces compute() with a
// persistent worker so the bridge is initialized once per app
// lifetime instead of per call — typical evaluations gain back
// the ~tens of ms init cost. The other big win: `cancelInFlight()`
// can actually `Isolate.kill` the worker (previously cancel was
// discard-on-completion).
//
// Tests don't have the native bridge available, but the worker still
// boots and returns "requires native library" strings — the public
// API surface is unchanged from V2.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../engine/calculator_engine.dart';

class EngineService {
  /// Heuristic: returns true when [expression] looks slow enough to
  /// warrant the off-thread trip. Short bare-arithmetic expressions
  /// return false (the cross-isolate message cost would dwarf the
  /// work even with a persistent worker). Anything with an integral,
  /// factor, simplify, or matrix shape, or a long expression, returns
  /// true.
  static bool shouldRunAsync(String expression) {
    if (expression.length > 80) return true;
    final slowFunctions = [
      'integrate(',
      'factor(',
      'simplify(',
      'expand(',
      'solve(',
      'limit(',
      'Matrix(',
      'rref(',
      'inv(',
      'det(',
    ];
    for (final fn in slowFunctions) {
      if (expression.contains(fn)) return true;
    }
    // Factorial or fibonacci of large numbers.
    final factMatch = RegExp(r'(\d+)!').firstMatch(expression);
    if (factMatch != null) {
      final n = int.tryParse(factMatch.group(1)!) ?? 0;
      if (n > 50) return true;
    }
    final fibMatch = RegExp(r'fib(?:onacci)?\((\d+)\)').firstMatch(expression);
    if (fibMatch != null) {
      final n = int.tryParse(fibMatch.group(1)!) ?? 0;
      if (n > 100) return true;
    }
    return false;
  }

  static final _PersistentWorker _worker = _PersistentWorker();

  /// Run `engine.evaluate(expression)` on the persistent worker.
  /// Returns the same string the synchronous path would return,
  /// including error prefixes.
  static Future<String> evaluateAsync(String expression) {
    return _worker
        .send(const EngineOp('evaluate', '_placeholder')._withArg1(expression));
  }

  /// V2: generic dispatch for the specialized CalculatorEngine methods
  /// (expand, simplify, factor, solve, differentiate, integrate,
  /// limit, gcd, lcm, factorial, fibonacci). Each is its own bridge
  /// call routed through the persistent worker.
  static Future<String> runOpAsync(EngineOp op) {
    return _worker.send(op);
  }

  /// V3: kill the worker (cancels all in-flight requests). The next
  /// `runOpAsync` call spawns a fresh worker, paying the
  /// bridge-initialization cost again — same trade as the V1
  /// compute() approach, but only when cancel actually fires.
  /// Pending futures complete with an [EngineCancelled] error.
  static Future<void> cancelInFlight() => _worker.kill();

  /// Test-only hook to tear down the worker between tests. Production
  /// code never calls this — the worker lives for the app's lifetime.
  static Future<void> shutdownForTest() => _worker.kill();
}

/// Tag + args for a generic worker dispatch. Held minimal (5 strings)
/// so it transports cleanly across the isolate boundary.
class EngineOp {
  final String kind;
  final String arg1;
  final String? arg2;
  final String? arg3;
  final String? arg4;
  const EngineOp(this.kind, this.arg1, [this.arg2, this.arg3, this.arg4]);

  EngineOp _withArg1(String newArg1) =>
      EngineOp(kind, newArg1, arg2, arg3, arg4);
}

/// Raised by [_PersistentWorker.send] when [EngineService.cancelInFlight]
/// kills the worker while a request was pending.
class EngineCancelled implements Exception {
  const EngineCancelled();
  @override
  String toString() => 'EngineCancelled';
}

/// Owns the worker isolate. Spawns lazily on the first request;
/// `kill()` tears it down so the next request respawns.
class _PersistentWorker {
  // Web has no `Isolate.spawn` (it throws `UnsupportedError`), so on web
  // every op runs inline on the main isolate against this one engine. The
  // WASM bridge is single-threaded anyway, so there's no thread to offload
  // to — the cost is a (usually fast) synchronous CAS call. The shared
  // instance lazily re-acquires the bridge once the WASM module loads, same
  // as every other CalculatorEngine.
  CalculatorEngine? _inlineEngine;

  Isolate? _isolate;
  SendPort? _commandPort;
  ReceivePort? _responsePort;
  StreamSubscription<dynamic>? _responseSub;
  int _nextId = 0;
  final Map<int, Completer<String>> _pending = {};
  Completer<void>? _startup;

  Future<void> _ensureStarted() async {
    if (_commandPort != null) return;
    if (_startup != null) return _startup!.future;
    // Capture local references so a kill() racing between awaits
    // doesn't NPE us on `_startup!`. If we get cancelled mid-spawn,
    // we'll still complete the future cleanly.
    final startup = _startup = Completer<void>();
    _responsePort = ReceivePort();
    _responseSub = _responsePort!.listen(_onResponse);
    _isolate = await Isolate.spawn(
      _workerEntry,
      _responsePort!.sendPort,
      errorsAreFatal: false,
    );
    await startup.future;
  }

  void _onResponse(dynamic msg) {
    if (msg is SendPort) {
      _commandPort = msg;
      _startup?.complete();
      return;
    }
    if (msg is _WorkerResponse) {
      final completer = _pending.remove(msg.id);
      completer?.complete(msg.result);
    }
  }

  Future<String> send(EngineOp op) async {
    if (kIsWeb) {
      // No isolate on web — run the op directly. Still async so callers'
      // `await` + progress-overlay flow is identical to native.
      final engine = _inlineEngine ??= CalculatorEngine();
      return _runOp(engine, op);
    }
    await _ensureStarted();
    final id = _nextId++;
    final completer = Completer<String>();
    _pending[id] = completer;
    _commandPort!.send(_WorkerRequest(id, op));
    return completer.future;
  }

  Future<void> kill() async {
    final pending = _pending.values.toList();
    _pending.clear();
    // If we were still in the middle of starting up, fail the
    // startup future so anything `await`ing it bails out cleanly
    // rather than hanging forever.
    final startup = _startup;
    _isolate?.kill(priority: Isolate.immediate);
    await _responseSub?.cancel();
    _responsePort?.close();
    _isolate = null;
    _commandPort = null;
    _responsePort = null;
    _responseSub = null;
    _startup = null;
    if (startup != null && !startup.isCompleted) {
      // Attach a no-op error listener BEFORE completing so the
      // microtask reporter doesn't flag this as an unhandled error
      // if `_ensureStarted`'s `await startup.future` hadn't yet
      // re-registered after `await Isolate.spawn` returned. Both
      // listeners fire — the await still throws EngineCancelled.
      startup.future.then((_) {}, onError: (_) {});
      startup.completeError(const EngineCancelled());
    }
    for (final c in pending) {
      if (!c.isCompleted) {
        // Same trick: pre-attach a swallow so the error is observed.
        c.future.then((_) {}, onError: (_) {});
        c.completeError(const EngineCancelled());
      }
    }
  }
}

/// Request payload sent main → worker. Just (id, EngineOp).
class _WorkerRequest {
  final int id;
  final EngineOp op;
  const _WorkerRequest(this.id, this.op);
}

/// Response payload worker → main. Just (id, result string).
class _WorkerResponse {
  final int id;
  final String result;
  const _WorkerResponse(this.id, this.result);
}

// Top-level so Isolate.spawn can find it.
void _workerEntry(SendPort mainPort) {
  final commands = ReceivePort();
  mainPort.send(commands.sendPort);
  // One engine + bridge instance lives in the worker for its full
  // lifetime. Lazy-init via CalculatorEngine's own factory — the
  // bridge loads its FFI symbols on first construction.
  final engine = CalculatorEngine();
  commands.listen((msg) {
    if (msg is _WorkerRequest) {
      final result = _runOp(engine, msg.op);
      mainPort.send(_WorkerResponse(msg.id, result));
    }
  });
}

String _runOp(CalculatorEngine engine, EngineOp op) {
  try {
    switch (op.kind) {
      case 'evaluate':
        return engine.evaluate(op.arg1);
      case 'expand':
        return engine.expand(op.arg1);
      case 'simplify':
        return engine.simplify(op.arg1);
      case 'factor':
        return engine.factor(op.arg1);
      case 'solve':
        return engine.solve(op.arg1, op.arg2!);
      case 'differentiate':
        return engine.differentiate(op.arg1, op.arg2!);
      case 'integrate':
        return engine.integrate(op.arg1, op.arg2!, op.arg3, op.arg4);
      case 'limit':
        return engine.limit(op.arg1, op.arg2!, op.arg3!);
      case 'gcd':
        return engine.gcd(op.arg1, op.arg2!);
      case 'lcm':
        return engine.lcm(op.arg1, op.arg2!);
      case 'factorial':
        return engine.factorial(int.parse(op.arg1));
      case 'fibonacci':
        return engine.fibonacci(int.parse(op.arg1));
      default:
        return 'Error: unknown engine op ${op.kind}';
    }
  } catch (e) {
    return 'Error: $e';
  }
}
