# CrispCalc — handover for the next session

## Latest: 2026-05-29 (cont.) — StatisticsPresets reach all four tabs

Extended the preset pre-fill mechanism beyond the Tests tab. The
**Descriptive / Regression / Distributions** tabs now each read
`StatisticsPreset.fields` in `initState` (mirroring `_TestsTab`), and
the screen routes the resolved preset only to the tab it targets (so a
Tests preset can't leak into the Descriptive controllers).

- 3 new presets: `statsDescriptive`, `statsLinearRegression`,
  `statsNormalDist`.
- Function Reference: `mean` re-pointed to the **Descriptive** tab (it
  was mis-landing on the Tests tab via `statsOneSampleT`); new
  `one_sample_t` entry now owns `statsOneSampleT`; new `linreg`
  (Regression) + `normal_dist` (Distributions). All three new entries
  fully localized **DE/FR/ES** (description + both hints).
- Per-tab pre-fill widget tests; open-module consistency count 9 → 12.
  Full suite **2640 pass / 1 skip / 0 failures**. Pure-Dart, on `main`.
- Also committed a stray `linux/flutter/generated_plugins.cmake` (the
  R130 Linux FFI plugin registration that had never been committed).

Every stats Function Reference entry now opens a pre-filled module in
one tap — the preset surface is effectively complete across all four
tabs. **Note:** FR/ES Function-Reference prose is now *complete* (the
older "FR/ES still return null" note below is stale — they were
finished after R100 and are held to completeness by
`function_reference_localization_test.dart`).

---

## 2026-05-29 (cont.) — Full StatisticsPresets coverage (9/9 stats entries)

`StatisticsPresets` grew 3 → 9 (added one-sample t, paired t, χ²
independence, Fisher's exact, paired sign, Wilcoxon) and the remaining
six stats `FunctionRef` entries got matching `openTarget`s — so every
stats Function Reference entry now shows the direct "Open module" button
landing on a pre-filled Tests tab. Pure-Dart, no new strings. New test
enforces both directions (entry→preset and preset→entry). Full suite
**2616 pass / 1 skip, 0 failures**. Commits sit on `main`; pushed.

If extending further: the Distributions / Regression / Descriptive tabs
have **no** preset-backed entries yet — `StatisticsPreset.tab` already
supports them, but the receiving tabs would each need an `initState`
pre-fill hook like `_TestsTab` has (only the Tests tab reads
`preset.fields` today).

---

## 2026-05-29 (cont.) — Round 99 follow-up: Function Reference "Open module" button

Closed the `open:`/`dsl:` Try-in-Calculator carry-over. Module-surface
Function Reference entries (`runnable: false`) now offer a direct "Open
module" button — the three stats entries with a `StatisticsPresets`
recipe land on the pre-filled Tests tab in one tap (previously only the
two-hop "See worked example" path existed).

- The `open:`/`dsl:` sentinel parser was **extracted** from
  `worked_examples_dialog._insert` into a shared
  `lib/widgets/module_navigation.dart` (`isModuleSentinel` /
  `dispatchModuleSentinel`) — both dialogs import it; the parser lives
  in exactly one place now. Reuse it for any future `open:`/`dsl:`
  surface, don't re-implement.
- `FunctionRef` gained an optional `openTarget` sentinel; the dialog
  shows an "Open module" `ElevatedButton` when it's set. New
  `functionRefOpenModule` string (EN/DE/FR/ES).
- New `test/function_reference_open_module_test.dart`. Full suite
  **2615 pass / 1 skip, 0 failures**. Pure-Dart, single repo, `main`,
  not yet pushed (sits on the Statistics-preset commit `e43a3c0`).

---

## 2026-05-29 (cont.) — Round 95 follow-up: Statistics input pre-fill

Closed the deferred Round-95 carry-over. The `open:statistics?tab=<id>`
worked-example sentinel only picked a tab; the new
`open:statistics?preset=<id>` sentinel **also pre-selects a hypothesis
test and fills its input fields** so a tapped example shows a complete
worked result immediately. Pure-Dart, single repo, on `main`,
headless-testable.

- New `lib/engine/statistics_presets.dart` — `StatisticsPreset` (tab +
  `_TestKind` name + controller-name→text field map) and a 3-entry
  `StatisticsPresets.all`: Welch two-sample t, one-way ANOVA, χ²
  goodness-of-fit. Data lives in Dart, not the sentinel string.
- New one-shot `AppState.pendingStatisticsPresetId` slot (sibling to
  `pendingStatisticsTab`, so that path is unchanged). `_TestsTab` takes
  an optional `preset:` and applies it in `initState`.
- Dialog `_insert` handles `preset=` alongside `tab=`; 3 new statistics
  worked examples (DE/FR/ES). New `test/statistics_preset_test.dart`.
- **Suite 2587 → 2611 pass / 1 skip, 0 failures** (commit `e4b3937`,
  not yet pushed). Pattern to reuse: a named-preset catalog + a
  one-shot AppState slot drained in `initState` is the clean way to
  pre-load *any* module from a worked example (mirrors the sudoku
  `preset=` path).

---

## 2026-05-29 — Group B: continued fractions + polynomial arithmetic

Two **Group B** items shipped, both **pure-Dart** (no native wrapper,
single repo, all on `main`, headless-testable):

1. `cfrac(x, n)` / `convergent(x, k)` — exact BigInt over the existing
   MPFR precision strings. `cfrac(pi, 10)` → `[3; 7, 15, 1, 292, …]`;
   `convergent(pi, 3)` → `355/113`.
2. `polygcd` / `polyresultant` / `polydiscriminant` over ℚ — new
   `lib/engine/polynomial.dart` (exact `Rational`/BigInt, univariate
   parser, Euclidean GCD, Sylvester-determinant resultant,
   discriminant).
3. `polyfactor(p, mod=k)` over 𝔽ₖ — new
   `lib/engine/polynomial_mod.dart` (square-free factorisation +
   Berlekamp). Completes polynomial arithmetic over Z, Q, F_p.
4. **Special functions surfaced** — `zeta`/`erf`/`erfc`/`gamma`/
   `loggamma`/`lambertw`/`dirichlet_eta`/`beta`/`lowergamma`/
   `uppergamma`/`polygamma` already evaluate (SymEngine parser +
   `basic_evalf`) and plot; this round added notepad recognition,
   FunctionReference (gamma/zeta/erf/lambertw/beta, DE/FR/ES), keypad
   buttons, and worked examples. **No native work needed.**
5. **Generic `evalf(expr, N)`** — arbitrary-precision numeric eval of
   ANY real expression via MPFR (3-repo wrapper arc, Round-4 flow:
   `flutter_symengine_evalf_with_precision` → `mpfrEvalf` binding +
   keepalive → engine dispatch). Subsumes `ln(k,N)`; pairs with the
   special functions (`evalf(zeta(2), 50)`). Bridge re-pinned; symbol
   verified surviving release dead-strip via `nm`.

6. **Bessel `besselj`/`bessely`** — first/second kind, integer order,
   real arg, via **MPFR `mpfr_jn`/`yn`** (SymEngine has no Bessel). 3-repo
   wrapper arc; intercepted in `evaluateForGraphing` *before* its
   comma→dot normalisation (which would mangle the 2-arg call) so they
   plot. UI fully surfaced.

7. **`cevalf(expr, N)`** — arbitrary-precision **complex** eval (MPC,
   `basic_evalf` real=0); the complement to `evalf`. `cevalf((1+I)^10,
   20)` = `32i`. 3-repo wrapper arc; reuses the `_EvalfPrecision`
   typedef. UI surfaced.

All fully surfaced. **2587 tests, 0 failures.** **Group B is now
practically complete** (7 increments). The ONLY deferred items are
`BesselI`/`BesselK` (not in MPFR) and `theta` (no MPFR primitive) —
each would need a from-scratch series/AGM implementation in the C
wrapper, not a binding. Next natural directions are *outside* the
precision arc — see PLAN's Strategic Context (notepad/document paradigm,
AI-as-verifier-frontend) and the carry-overs below (hardware smoke test,
Statistics pre-fill, Android ABI matrix).

⚠ **Fixed a latent regression this session:** `precision_call_pass_test`
had been red on `main` since the round-4 merge (a stale Round-91
assertion that `totient(12)` is not intercepted, invalidated when round 4
added `totient` to the dispatch). The flaky `notepad_screen_test`
full-suite failure masked it in per-round greps. Now fixed; full suite is
0-failure. **Lesson: when confirming a "known flake", grep the failing
test names explicitly rather than trusting the summary counter.**

---

## Precision arc Group A complete (Round 4 + 5)

Closed out the precision/number-theory arc's **Group A**. Round 4 added
the last four native functions — `modpow` / `modinv` / `totient` /
`jacobi` — plus pure-Dart `divisors`, across the full three-repo chain
(wrapper C → bridge bindings + `+load` keepalive → CrispCalc engine +
parser). Round 5 surfaced all of them in the UI (Adv-keypad buttons,
FunctionReference entries with DE/FR/ES i18n, worked-examples). **All
three repos merged to their default branches** (math-stack `master`
`39d2e4d8`, bridge `main` `ce8af30`, CrispCalc `main` repinned to
`ce8af30`). Release-build `nm` confirmed the new symbols survive
dead-strip. **2387 tests** (one pre-existing notepad full-suite flake,
passes in isolation). Group A done; **Group B** (polynomial arithmetic,
continued fractions, Bessel/zeta/theta, arbitrary-precision complex) is
the next precision arc. See `HANDOFF_PRECISION.md` + HISTORY top entry.

---

Pickup note from the **2026-05-29 session** (P11 R130 + R100 + R105b).
Three arcs landed: **Linux x86_64 SymEngine** (bridge v1.2.0 — the
last tier-1 platform; every native target now ships full SymEngine),
the **Function Reference i18n** (R100 — full DE/FR/ES coverage of the
~45-entry catalog), and **R105b** per-element help popovers on the
Statistics / Sudoku / Constraints DSL screens; plus the bridge v1.2.1
Windows-loader fix and the **v0.4.1 release**. Prior session
(2026-05-27) cut v0.4.0 with Android + Windows.

## ⚠ Working mode

**Single-repo CrispCalc work** goes **directly on `main`**. A
**multi-repo arc** (CrispCalc + symbolic_math_bridge +
math-stack-ios-builder) uses a **feature branch per repo**, then
merges each to its default branch — per the multi-repo rule (see
`memory/feedback_multi_repo_arc_worktree.md`). The round-4 arc this
session followed exactly that: `precision-round4-modular` in all three,
merged to `master`/`main`. Round-5 (UI-only, CrispCalc) went on `main`.

## State

| | |
|---|---|
| **Main worktree** | `/Volumes/backups/code/CrispCalc` (branch `main`) |
| **main HEAD** | Precision Group A (Round 4 + 5) + Group B (cfrac, poly over ℚ/𝔽ₚ, special fns, evalf, Bessel), on top of R130 + R100 + R105b; **v0.4.1 released** |
| **Tests** | **2587 pass, 0 failures** (… → 2571 bessel → 2587 cevalf); `notepad_screen_test` still a flaky full-suite-only failure (passes in isolation) |
| **dart_csp pin** | `69a9cfb` (unchanged) |
| **bridge pin** | **`afadd2e`** (bridge main, post cevalf merge — Group B complete) — was `535ce5d` pre-session |
| **bridge main HEAD** | `afadd2e` (round-4 + evalf + bessel + cevalf merged); math-stack `master` `2ec2a62d` |
| **platforms** | iOS · macOS · Android arm64-v8a · Windows x86_64 · **Linux x86_64** — all full-CAS. Web still the only CAS-less target. |

## This session — major arcs landed (2026-05-29)

### Arc A: P11 R130 — Linux x86_64 SymEngine (bridge v1.2.0)

The last tier-1 platform. Bridge branch `r130-linux` → `main`
(`0907768`). **Green on the first CI run** (`build-linux.yml`
26604981909, 19m5s) — no iteration. A hybrid of R132 (static-link
the whole math stack into one `.so`) and R131 (three-mode consumer
CMake), but simpler: a Linux `ffiPlugin` needs no registrar `.cc` /
no `flutter` linkage, so the consumer path is pure bundling and there
is no filename-collision workaround (Dart opens
`libsymbolic_math_bridge.so`, exactly what `add_library()` emits).

- vcpkg `x64-linux` static on `ubuntu-22.04` (GLIBC 2.35 baseline).
- 18.3 MB stripped `.so`, only libc/libstdc++/libm/libgcc_s dynamic.
- Committed at `linux/Libraries/`; CrispCalc re-pinned to `0907768`.
- **All 6 CrispCalc CI jobs green** — the Build Linux job moved from
  degraded to full via consumer-prebuilt bundling (no source-compile
  attempt — the v1.1.0 failure mode did NOT recur). README + PLAN +
  `LINUX_STATUS.md` updated.

### Arc B: R100 — Function Reference content i18n (German)

Was the highest-leverage UI item. The dialog localized its chrome but
read entry descriptions + example hints from the English catalog —
fixed by the worked-examples precedent: nullable
`functionRefDescription(id)` / `functionRefExampleHint(id, index)` on
`AppLocalizations`, dialog falls back to the catalog on null.

- **Complete German** coverage of all ~45 entries (every category) —
  descriptions + every hint. Terminology per German math didactics.
- Localization test enforces full DE completeness (new entry without
  DE → CI fails). Tests 1992 → **2129**.
- **FR/ES still return null** (English fallback). The mechanism + test
  are ready; finishing them is a clean follow-up (see open items).

## Smoke-test status (what's verified, what isn't)

| | Verified via CI | Real-hardware verification |
|---|---|---|
| Compile + link + symbols in export table (all 5 platforms) | ✓ | n/a |
| macOS app builds + binaries embed | ✓ | host = macOS, runtime OK |
| Android APK contains the bridge .so | ✓ | **⚠ needs arm64-v8a device/emulator** |
| Windows zip contains the bridge .dll | ✓ | **⚠ needs Windows x86_64 desktop** |
| **Linux bundle contains the bridge .so** | ✓ (consumer-prebuilt build green) | **⚠ needs a Linux x86_64 desktop** |
| iOS unchanged | ✓ | **⚠ needs an iOS device** |

The structural pipeline is end-to-end green on all five platforms.
What's NOT confirmed: the runtime FFI call from a real Android /
Windows / Linux machine. Same wrapper source that works on iOS/macOS
got compiled into each binary — if compile + link + symbol visibility
line up (verified, incl. Linux `ldd`/`.dynsym` checks), runtime should
follow. Still worth a hardware pass.

## What's open / next session pickup

### 1. **Runtime smoke-test on real hardware** (highest priority)

Still the one thing CI can't do. Now FIVE platforms have unverified
runtime FFI: Android / Windows / **Linux** (new) — plus iOS. Grab a
release artifact (or `flutter run -d <device>`), open the calculator,
type `solve(x^2 - 1, x)`, expect `[-1, 1]`. `Error: requires native
library` means the binary didn't load — most likely a filename
mismatch between what Dart's `DynamicLibrary.open` passes and what
Flutter bundled.

- **Linux**: `flutter build linux` then run the bundle; Dart opens
  `libsymbolic_math_bridge.so` (bundled from `linux/Libraries/` via
  consumer-prebuilt mode). GLIBC baseline is 2.35 — older distros may
  refuse to load.
- **Windows**: the loader DLL-name mismatch flagged last revision is
  **fixed in bridge 1.2.1** (`535ce5d`, now pinned) —
  `_openNativeLibrary` tries `libsymbolic_math_bridge.dll` (the
  consumer-bundled wrapper) first, falling back to
  `symbolic_math_bridge_plugin.dll`. Reasoned-correct + non-regressive
  but **still wants a real Windows runtime check** to confirm.
- **Android / iOS**: as before.

If a runtime fail surfaces, iterate the bridge — add diagnostic
logging to `_openNativeLibrary()`, narrow it, push, re-pin, release.

### 2. **Android x86_64 (emulator) and armeabi-v7a (32-bit)**

Extend the `build-android.yml` matrix. Deferred-until-demand per the
workflow comment. Each ABI is its own ~15-min build slot.

### 3. **Carry-overs from prior sessions**

- ~~Round 95 follow-up — Statistics input pre-fill.~~ **SHIPPED
  2026-05-29** — `open:statistics?preset=<id>` (new `StatisticsPresets`
  + `pendingStatisticsPresetId`); Tests tab pre-selects a test + fills
  inputs. See HISTORY top entry.
- ~~`open:` / `dsl:` dispatch in Try-in-Calculator (R99 followup).~~
  **SHIPPED 2026-05-29** — Function Reference "Open module" button +
  shared `lib/widgets/module_navigation.dart` dispatcher (the `open:`/
  `dsl:` parser now lives in one place). See HISTORY top entry.
- CSP Round E.5 — `dart_csp_fzn` CLI (blocked on P4).
- P9 follow-ups (A5d / A7 / A8) — 3D Scene polish.

### 4. **v0.4.1 — RELEASED (2026-05-29)**

Tagged `v0.4.1`, all 5 artifacts published. Linux tarball grew
13.2 → 19.9 MB (the bundled `.so`), confirming the R130 binary
shipped. Next release picks up FR/ES i18n + any hardware-smoke-test
fixes.

## Hygiene reminders

- **`dart format`** before push. Format only files you touched.
- **Don't run multiple `flutter test` in parallel** — they race
  on `.dart_tool/test/incremental_kernel_*`.
- **Don't touch `.claude/`** — harness state.
- **Working on main now.** Ask before starting a feature branch
  inside CrispCalc proper. Bridge plugin still uses feature
  branches per the multi-repo rule.
- **`flutter_symengine_*` symbol-not-found lines** in
  `flutter test` stderr are expected — the test VM doesn't load
  the plugin's compiled binaries. Bridge catches the failure;
  pure-Dart tests don't depend on it.

## Quick-reference paths

### CrispCalc (`/Volumes/backups/code/CrispCalc`)

- Calculator: `lib/screens/calculator_screen.dart`
- Notepad: `lib/screens/notepad_screen.dart`
- Help-mode infrastructure: `lib/widgets/help_target.dart`,
  `history_help_modal.dart`, `module_help_dialog.dart`,
  `calculator_keypad.dart` (popover maps)
- Function Reference catalog: `lib/engine/function_reference.dart`
  (45 entries)
- Step engine: `lib/engine/step_engine.dart`
- Localization: `lib/localization/app_localizations.dart`

### symbolic_math_bridge (`/Volumes/backups/code/symbolic_math_bridge`)

- `main` HEAD: `85bfa7e` (v1.1.0)
- `src/flutter_symengine_wrapper.{c,h}` — the 749-line C wrapper
  vendored from math-stack-ios-builder (same source for Android +
  Windows; iOS/macOS use prebuilt `.xcframework` bundles)
- `android/` — Gradle module + CMakeLists + Kotlin glue
- `windows/` — Flutter Windows plugin + CMakeLists + glue
- `.github/workflows/build-android.yml` + `build-windows.yml`
- `ANDROID_STATUS.md` + `WINDOWS_STATUS.md` — per-platform
  iteration history (essential context if R130 picks up)

### math-stack-ios-builder (`/Users/christianstrobele/code/math-stack-ios-builder`)

- Canonical iOS/macOS xcframework builder. Master branch
  `34ec0fdf`. Source-of-truth for `src/flutter_symengine_wrapper.c`
  (vendored into the bridge by R131 + R132).

Good luck.
