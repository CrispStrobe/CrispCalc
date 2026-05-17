# CrispCalc — History

Completed work, newest first.

## 2026-05-17 (round 21) — Step-by-step equation solving (P5 #1, V2)

Second slice of the step-by-step workstream from round 20: equation
solving. Same `StepEngine` + `StepsDialog` infrastructure reused.

### Degree detection

`StepEngine.solve(input, variable, engine)` first splits on top-level
`=` (or treats the input as `expr = 0`), then asks SymEngine to
differentiate the simplified equation. If `d/dvar[body]` is a non-zero
expression that no longer contains `variable`, the equation is linear.
If `d²/dvar²[body]` is a non-zero variable-free expression, it's
quadratic. Anything else falls through to `engine.solve()` with a
single "Symbolic solve" step explaining the handoff.

### Linear trace

For `2x + 3 = 7`:

1. Original equation — `2x + 3 = 7`
2. Move all terms to one side — `2*x - 4 = 0`
3. Identify coefficients — `a = 2, b = -4`
4. Subtract the constant — `2*x = 4`
5. Divide by the coefficient — `x = 2`
6. Result — `x = 2`

### Quadratic trace

For `x^2 - 5x + 6 = 0` (or `x^2 - 5x + 6` treated as `… = 0`):

1. Treat as equation = 0 / Move all terms to one side
2. Identify coefficients — `a, b, c` derived from `d²`, `d|_{x=0}`,
   `body|_{x=0}`
3. Compute the discriminant — `Δ = b² - 4ac`
4. Apply the quadratic formula — `x = (-b ± √Δ) / (2a)`
5. Result — both roots, cross-checked against SymEngine's `solve()`

### MathStep rename

Renamed the `DerivativeStep` data class to `MathStep` since it now
carries solve steps as well. Pure renaming — same fields (`rule`,
`formula`, `before`, `after`, `note`).

### Dialog flexibility

`StepsDialog` gained optional `subtitle` and `headlineLatex` overrides
so it can render either "Differentiating with respect to x" + the
`d/dx[…]` headline or "Solving for x" + the equation itself. Old
behavior preserved as the default.

### UI entry

New `solve⌄` keypad button in the CAS tab, between `solve` and
`factor`. Opens a small prompt (defaults to `2x + 3 = 7`), runs the
trace, opens the steps dialog. Existing `solve` button is untouched —
users who just want the answer keep getting it as before.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: 277/277 (5 new solve tests).
- macOS release boots clean. Matrix self-test still 7/7.

---

## 2026-05-17 (round 20) — Step-by-step differentiation (P5 #1, V1)

First slice of PLAN P5's top recommendation: when the user
differentiates an expression, show *why* the answer is what it is.

### Architecture

`lib/engine/step_engine.dart` is a rule-tracing walker. For each input
it identifies the top-level expression shape and emits a
`DerivativeStep` carrying the rule name, the generic LaTeX formula,
and the rule-unfolded result. Then it recurses on sub-expressions so
the trace fans out into a complete derivation. The final step's
`after` field comes from SymEngine — so the canonical answer never
drifts even though the trace is computed in Dart.

Rules covered:

- Constant rule, identity (`d/dx[x] = 1`)
- Sum / difference rule (paren-aware top-level split on `+` / `-`)
- Product rule (recurses as `first · rest`, fans out further)
- Quotient rule
- Power rule (numeric exponent in the variable) and exponential rule
  (`a^u(x)`)
- Chain-rule-aware standard derivatives for sin / cos / tan / asin /
  acos / atan / sinh / cosh / tanh / exp / ln / log / sqrt
- Generic fall-through that just emits SymEngine's answer when no
  pattern matches

Each step structure carries an optional `note` for plain-language
explanations — wired today for constant and chain-rule cases, easy to
extend.

### UI

`lib/widgets/steps_dialog.dart` renders the step list as a card stack
with `flutter_math_fork` LaTeX rendering for the formula + before/after
expressions. Result step is highlighted with the primary container
color. Falls back to monospace text on LaTeX parse failures so the
dialog never goes blank on a malformed step.

Entry point: new `d/dx⌄` keypad button in the CAS tab. Pressed → small
dialog asks for expression + variable (pre-filled from the LaTeX field
if there's anything in it) → step list dialog opens. Doesn't touch the
existing `d/dx` flow, so users who just want the answer keep getting
it the old way.

### Why not also integrate + solve

Differentiation rules are finite and well-known; the trace generator
fits in 250 lines of Dart with no SymEngine modifications. Integration
and equation solving need either fork SymEngine to emit traces or
implement enough of the algorithms Dart-side to recognize patterns —
significantly larger. Documented in PLAN as the next two slices.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: 272/272 (13 new step engine tests covering rule
  selection, step content, and the "always ends with a Result step"
  invariant).
- Local release smoke: app boots clean. `CRISPCALC_DIAGNOSTIC=matrix`
  still 7/7.

---

## 2026-05-17 (round 19) — RREF via SymEngine-backed Gauss-Jordan

Added `rref(Matrix([...]))` to the matrix evaluator. The algorithm is
classical Gauss-Jordan, but every elementary row operation is built
as a SymEngine expression string and pushed through
`bridge.simplify()` — so rational and (with caveats) symbolic entries
work, not just floats.

### Algorithm shape

1. Pull cells into a Dart 2-D array of expression strings.
2. Walk columns left-to-right. For each column, find the first row at
   or below the current pivot row whose entry simplifies to something
   non-zero.
3. Swap that row up. Scale it so the leading entry is 1
   (`(cell)/(pivot)` through SymEngine).
4. Use the pivot row to eliminate that column in every other row
   (`(target) - (factor)*(pivot_row_cell)` through SymEngine).
5. Move to the next column.

Symbolic non-zero detection asks SymEngine to simplify each candidate
and treats the literal string "0" as zero. Expressions that are
mathematically zero but don't reduce to "0" textually are treated as
non-zero pivots — the result is still a valid row-reduced form, just
possibly not fully canonical. That's the safe direction.

### Wired in

- `MatrixEvaluator` recognizes `rref` alongside `det` / `inv` /
  `transpose`.
- Keypad gets a new `rref` button next to the existing matrix keys.
- The matrix self-test battery picks up a 7th check — the canonical
  textbook 2×3 system `[[2,1,0],[-1,1,3]]` which reduces to
  `[[1,0,-1],[0,1,2]]`. Self-test now reports **7 of 7 pass** on the
  macOS release binary; CI runs the same battery on every push and
  fails on regression.

### Verification

`flutter analyze`: 0 issues. `flutter test`: 259/259 (updated the
diagnostic-runner shape test to expect 7 results). Release smoke:
`CRISPCALC_DIAGNOSTIC=matrix … crisp_calc` reports the new check as
`PASS  RREF of a 2x3 system — Matrix([[1, 0, -1], [0, 1, 2]])`.

### Out of scope

- Bringing matrix expressions into `inv` / `transpose` / `rref` as
  *nested* operands (currently the operand must be a literal `Matrix(…)`).
- Symbolic non-zero detection beyond "simplify and compare to '0'"
  — would need SymEngine's `is_zero` test, which the bridge doesn't
  expose yet.

---

## 2026-05-17 (round 18) — CI catches matrix + symbol-keep regressions

Two tightenings to `build-macos.yml`:

1. **Switched the workflow from `--debug` to `--release`.** The
   symbol-keep trick that HISTORY round 13 fixed lives in the bridge
   plugin, not in CrispCalc. It can silently regress on a bridge bump.
   Running the release link in CI directly exercises the same path
   that release builds use locally, so a regression in the asm-clobber
   keepalive can't slip through unnoticed.

2. **Added a headless matrix-diagnostic step.** After the `nm`
   symbol-presence check, CI now runs
   `CRISPCALC_DIAGNOSTIC=matrix <app>`, which exits non-zero on any
   matrix self-test failure. The presence check verifies symbols are
   statically linked; the diagnostic verifies they actually round-trip
   through the FFI matrix bindings. Together they catch both
   regression classes that bit us in rounds 13 and 16.

PLAN.md's open "GitHub Actions to run analyze + test on PR" item was
also redundant — `ci.yml` has provided that since round 8. Marked done.

---

## 2026-05-17 (round 17) — French + Spanish locales

Added `FrLocalizations` and `EsLocalizations` to
`lib/localization/app_localizations.dart` (full mirror of the German
override block — nav, history, graphing, analysis hub, settings, about,
matrix diagnostics, picker dialogs, error strings, and tab labels;
~95 strings each).

- Extended the abstract `AppLocalizations` class with two new
  language-name getters (`settingsLanguageFrench`,
  `settingsLanguageSpanish`) — enforces compile-time coverage on each
  locale class.
- `AppLocalizationsDelegate.isSupported` and `load` extended to handle
  `'fr'` and `'es'`. Unknown language codes still fall through to
  English.
- `main.dart`: added `Locale('fr','')` and `Locale('es','')` to
  `supportedLocales`, and two new `RadioListTile`s in the language
  card.

### Safety net

New `test/localizations_test.dart` walks every locale and asserts
every string getter + templated method returns non-empty content. A
new string on the abstract class catches at compile-time (Dart's
missing-override error); this test catches accidentally-empty
translations and broken templated formatters that wouldn't compile-
fail. 20 checks pass across the 4 locales.

### Verification

`flutter analyze`: 0 issues. `flutter test`: 259/259 (20 new locale
checks). macOS release builds and boots clean.

---

## 2026-05-17 (round 16) — Matrix arithmetic actually works end-to-end

PLAN P2 "matrix arithmetic end-to-end" turned up a real bug that the
unit tests couldn't have caught — the preprocessor was emitting strings
SymEngine's text parser couldn't accept.

### The self-test that surfaced the bug

Added `lib/engine/matrix_diagnostics.dart` with a six-check battery
(2x2 det, 3x3 identity det, transpose, inverse of identity, addition,
multiplication). Exposed two entry points to run it:

- Settings → "Matrix self-test" tile opens a dialog with PASS/FAIL per
  check and the raw expected vs. actual strings.
- `CRISPCALC_DIAGNOSTIC=matrix <app>` runs the battery headlessly and
  exits non-zero on any failure. (Reaches `Platform.environment` from
  `main()` — `Platform.executableArguments` is Dart-VM args, not user
  argv, so the obvious `--matrix-diagnostic` flag wouldn't have worked
  from a launched binary.)

First run on a fresh release build: **0 of 6 checks passed**. Every
matrix expression came back `SymbolicMathException: evaluate -
parse failed`. The preprocessor builds `Matrix([[1,2],[3,4]])` strings,
but SymEngine's `parse()` doesn't have a `Matrix` constructor in its
grammar.

### The fix: route matrix ops through the FFI matrix bindings

New `lib/engine/matrix_evaluator.dart`. `CalculatorEngine.evaluate()`
now checks for `Matrix(` in the expression and, if found, hands off to
`MatrixEvaluator.tryEvaluate()` instead of the string-evaluate path.
The evaluator:

- Recognizes three top-level shapes: `det/inv/transpose(<matrix>)`,
  `<matrix> {+,-,*} <matrix>`, and a bare `<matrix>` literal.
- Parses `Matrix([[a,b],[c,d]])` into a fresh `SymEngineMatrix` via the
  `createMatrix` + `set` FFI calls.
- Routes operations to the matrix API (`getDeterminant`, `inverse`,
  `operator+`, `operator*`).
- Implements `transpose` and `-` in Dart (no native entry points) by
  copying cells into a new matrix.
- Formats the result as canonical `Matrix([[a, b], [c, d]])` instead
  of the bridge's native multi-line `[a, b]\n[c, d]` shape, so results
  feed back into the engine cleanly and look right in history.

### A bonus user-visible improvement

`_bridgeCall` was hiding the underlying bridge exception under a
generic "Error: <op> failed". Now it appends the exception's message:
"Error: evaluate failed: SymbolicMathException: evaluate - parse
failed". That's how the parse-failure diagnosis was possible in the
first place. Future debugging gets cheaper.

### Verification

`CRISPCALC_DIAGNOSTIC=matrix build/macos/Build/Products/Release/crisp_calc.app/Contents/MacOS/crisp_calc`:

```
PASS  2x2 determinant — actual: -2
PASS  3x3 identity determinant — actual: 1
PASS  Transpose 2x2 — actual: Matrix([[1, 3], [2, 4]])
PASS  Inverse of identity — actual: Matrix([[1, 0], [0, 1]])
PASS  Matrix addition — actual: Matrix([[2, 2], [3, 5]])
PASS  Matrix multiplication — actual: Matrix([[3, 4], [5, 6]])
6 of 6 checks passed
```

`flutter analyze`: 0 issues. `flutter test`: 239/239 (3 new
diagnostics tests for the runner shape).

### Out of scope

Mixed scalar-matrix expressions (e.g. `det(M) + 3`), chained matrix
expressions (`A * B + C`), scalar-times-matrix, matrix substitution
with stored variables. Today's evaluator handles literal-only operands
at top level. Wider parsing is a future iteration.

---

## 2026-05-17 (round 15) — Plot annotations + zero-issue analyze

### Plot annotations

New AppBar toggle on the graphing screen overlays roots and extrema
markers on every active curve. Numerical implementation:

- Scan ~200 samples across the visible x-range using the painter's
  existing per-point evaluator (`_evaluateFunction`).
- **Roots**: sign change in f(x), refined by 40-iter bisection.
- **Extrema**: sign change in finite-difference f'(x), refined by
  parabolic interpolation through three samples bracketing the change.
  Classification (`min` / `max`) from the parabola's curvature sign.
- Markers: filled colored dot + white outline, with a labeled coord
  pair above-right (flipped if it would clip the canvas).

Why fully numerical rather than reusing AnalysisEngine: AnalysisEngine
does symbolic root/extremum solving via SymEngine, which is slow and
overkill for an interactive overlay that needs to repaint on every pan
and zoom. The numerical scan is fast enough to rerun each frame and
adapts to whatever x-range is on screen, so it shows roots/extrema
outside the analytic solution set too (e.g., for transcendental
functions where SymEngine can't find closed-form roots).

### Zero-issue analyze

In the same round, drove `flutter analyze` from 31 issues down to **0**:

- Dropped 6 redundant `flutter/foundation.dart` and `flutter/services.dart`
  imports that were fully shadowed by `flutter/material.dart`.
- Migrated 18 deprecated `Radio.groupValue` / `Radio.onChanged` usages
  in `main.dart` to the new `RadioGroup<T>` ancestor pattern
  (Flutter 3.32+). Cleaner shape too — one set of group state at the
  Card level instead of repeated on every `RadioListTile`.
- Added `super.key` to `IntegralDialog`, `NthRootDialog`, `LimitDialog`
  constructors; tightened a stale `Key? key` in `progress_overlay.dart`.
- Three `const` constructor lints (Text, KeyUpEvent, GraphingScreen
  push).

`flutter test`: 236/236. macOS release builds clean and launches with
all bridge symbols linked.

---

## 2026-05-17 (round 14) — P2: substitute dialog + history search

Two user-facing improvements with the bridge fix from round 13
unblocked.

### Variable substitution dialog

The `subst` keypad button used to just stuff `subst(, , )` into the
input and let the user fill the holes — fiddly and easy to break. New
`SubstituteDialog` (in `lib/widgets/function_picker_dialogs.dart`)
mirrors the existing `LimitDialog` pattern: three LaTeX fields
(Expression, Variable, Value) and an "Insert" button that builds
`subst(expr, var, value)` and drops it in.

Nice bit: when `appState.userVariables` is non-empty, the dialog shows
a row of `ActionChip`s for each stored variable. Tapping one fills the
Value field — same gesture as picking from memory, no typing.

### History search

Added a search icon to the calculator history toolbar (next to the
LaTeX/plain toggle + clear). Toggle reveals a TextField that filters
the rendered history live — case-insensitive `contains` against both
expression and result. Empty filter shows the usual list; non-matching
filter shows a "no matching entries" placeholder. Search state is per-
session (intentionally not persisted — feels weird to come back to the
app with a stale filter).

### i18n

Added en/de strings for `searchHistory`, `searchHistoryHint`,
`historyNoMatches`. The new dialog itself is still hardcoded English to
match the rest of `function_picker_dialogs.dart`; that whole file
should get a localization pass in a follow-up.

### Verification

- `flutter analyze`: 31 issues — same count as before, no new
  warnings/errors.
- `flutter test`: 236 tests pass.
- macOS release build: 69.2 MB, boots cleanly with the linked-symbols
  log from round 13.

---

## 2026-05-17 (round 13) — P1#2 finally closed (macOS release link)

The macOS release build kept dropping every `flutter_symengine_*`
wrapper symbol despite five rounds of -ldflags / podspec / xcframework
gymnastics. Root cause turned out to live in the bridge plugin, not in
the host Runner: iOS already had a `SymEngineBridge.m` with a `+load`
method that took the address of every wrapper function, plus a
`@_silgen_name("force_all_math_symbols_linking")` declaration in Swift
to pull the .m's translation unit into the link. macOS had neither.

### Iteration 1 — port iOS verbatim

Created `macos/Classes/SymEngineBridge.m` mirroring iOS, added the
`@_silgen_name` + `force_all_math_symbols_linking()` call to the macOS
Swift plugin. Build succeeded but `nm` showed zero `flutter_symengine_*`
symbols in the release binary. `otool -tV` on `+[SymEngineBridge load]`
revealed why: the entire `static void* refs[] = { … }` array plus the
`if (refs[0] == NULL) { … }` check had been constant-folded out by LTO
(the compiler proved `refs[0]` is a function address ⇒ never NULL ⇒
the if-branch is unreachable ⇒ the array reads are dead ⇒ the array
itself is dead). What remained was a single `NSLog` and a `ret`.

### Iteration 2 — volatile sink

Replaced the if-check with a loop writing each pointer into a `static
volatile void* sink`. Build still dropped every symbol. Disassembly
showed only the *last* store survived: writes to the same volatile
location are still subject to dead-store elimination when the optimizer
proves only the final value is observed.

### Iteration 3 — asm-clobber DoNotOptimize

Switched to the standard `DoNotOptimize` pattern:

```c
for (size_t i = 0; i < n; i++) {
    __asm__ __volatile__("" : : "r"(refs[i]) : "memory");
}
```

The empty `asm volatile` with an `r` input constraint forces the
compiler to materialize each pointer in a register as if external code
consumes it — undeletable side effect. Release binary jumped from
53.7MB → 69.2MB, and 39 wrapper symbols landed.

### Iteration 4 — audit the missing six

Dart FFI bindings turned out to reference 45 distinct
`flutter_symengine_*` entry points; the iOS-ported refs[] only listed
39. Added the missing six: `simplify`, `integrate`, `version`,
`test_basic_operations`, `test_symbolic` (`free_string` was already
there). All 45 now in the release binary.

### Result

- `nm crisp_calc | grep -c flutter_symengine_` → **45**
- Runtime launch logs: `[SYMBOLIC_MATH] Linked 93 math symbols` followed
  by a clean Flutter startup — no `dlsym` failures.
- Bridge commits: `36c29bf` (port iOS), `26f1faa` (volatile attempt),
  `e9a8526` (asm-clobber), `6652199` (missing 6).
- CrispCalc pinned to bridge ref `6652199`.

### Lesson

When forcing the linker to keep symbols that are otherwise only reached
via `dlsym`, neither a constant if-check nor a single volatile sink
survives LTO. The bulletproof pattern is one asm-clobber per reference.
This is the same trick Google Benchmark uses for `DoNotOptimize`, and
it's the only thing that worked under Xcode 26.2 + Flutter 3.38.5 on
macOS Release.

---

## 2026-05-17 (round 12) — v0.1.0 cut

- Fast-forwarded main from `latex-input-field` (18 commits, ~9k
  insertions covering everything from the first audit forward).
- Tagged `v0.1.0` with a release-note commit message covering features
  and known limitations.
- The `release.yml` workflow fired automatically on the tag push and
  ran 6 jobs in parallel: macOS, iOS, Linux, Windows, Android, publish.
  All six green; publish step created the GitHub Release and attached
  every artifact.
- Release page: https://github.com/CrispStrobe/CrispCalc/releases/tag/v0.1.0
  - `crisp_calc-v0.1.0-macos.zip` (22.8 MiB, release build, unsigned)
  - `crisp_calc-v0.1.0-ios-unsigned.zip` (10.4 MiB)
  - `crisp_calc-v0.1.0-linux-x64.tar.gz` (19.7 MiB, degraded mode)
  - `crisp_calc-v0.1.0-windows-x64.zip` (13.6 MiB, degraded mode)
  - `crisp_calc-v0.1.0-android.apk` (54.4 MiB, degraded mode)
- Release-note body documents that symbolic operations work on
  iOS/macOS only at this version and macOS release builds have the
  known SymEngine wrapper-symbol drop (PLAN P1#2).

## 2026-05-17 (round 11) — P1#2 round 2 (still open, partial progress)

### What I learned
- Built a tiny universal static archive
  `libflutter_symengine_wrapper_only.a` (56 KB, just the 45 C entry
  points without any SymEngine internals) by `lipo -thin → ar -x → ar
  rcs → lipo -create`. Bundled into a real
  `FlutterSymEngineWrapperOnly.xcframework` with iOS and macOS slices
  and committed to the bridge repo so it ships alongside the big
  `SymEngineFlutterWrapper.xcframework`.
- Verified the small archive: `nm -arch arm64
  libflutter_symengine_wrapper_only.a` → 45 `T _flutter_symengine_*`.

### What didn't work
- Wiring the new archive into the bridge podspec
  (`vendored_frameworks` + `-Wl,-force_load,<path>`): CocoaPods adds
  `-lflutter_symengine_wrapper_only` automatically; that combined with
  the existing `-all_load -lsymengine_flutter_wrapper` ended up
  breaking even the debug link (0 symbols instead of 45). Removed the
  wiring; the archive is in the bridge repo for the next attempt.
- Inspecting `crisp_calc-linker-args.resp` shows the macOS Runner's
  actual `ld` invocation receives ONLY Swift `-add_ast_path` entries.
  The `-all_load`, `-l"symengine_flutter_wrapper"`, etc. from
  `Pods-Runner.*.xcconfig` never show up there. So the standard
  CocoaPods linker-flag plumbing doesn't reach the link step on this
  Xcode 26.2 / Flutter 3.38.5 combination. Debug builds work via
  Flutter's separate `crisp_calc.debug.dylib` link pipeline, which
  somehow does consume the flags.

### State after this round
- Bridge HEAD at `c3fd26a` — carries the wrapper-only archive without
  wiring (so debug builds stay green) and the comment trail of what
  was tried.
- CrispCalc's Podfile is back to the working `-all_load`-only state.
- Debug: 45 `flutter_symengine_*` symbols in
  `crisp_calc.debug.dylib`. App fully functional.
- Release: 0 symbols. Symbolic operations return "Error: requires
  native library". Open P1#2.

## 2026-05-17 (round 10) — Cross-platform builds + P1#2 deep-dive

### P1#2: release-build SymEngine investigation (still open)
- Forensic finding: the static archive holds **two** kinds of symbols.
  ~3000 mangled C++ `__ZN9SymEngine…` and 45 C wrapper
  `flutter_symengine_*`. Release builds link the C++ side fine — the
  C wrapper `flutter_symengine_wrapper.o` is silently dropped.
- Tried, in order:
  1. `STRIP_INSTALLED_PRODUCT = NO` + `DEAD_CODE_STRIPPING = NO` on
     the Runner xcconfig → symbols still missing.
  2. `-Wl,-force_load,<xcframework-slice>` → missing alone, duplicates
     when combined with `-all_load`.
  3. Patching `LIBRARY_SEARCH_PATHS` on the bridge POD so the framework
     pre-links → duplicate symbols (framework + Runner both pull the
     same archive, both with -all_load).
- Reverted to the known-debug-working state (`-all_load` only, no
  patches). 45 symbols in `crisp_calc.debug.dylib` confirmed; release
  has 0 symbols. The real fix lives upstream in the bridge plugin: the
  C wrapper needs to be in a separate static lib, or the framework
  binary needs to pre-link the wrapper objects explicitly. Updated
  PLAN with the full failure timeline.

### Cross-platform builds: Android / Linux / Windows
- `flutter create --platforms=android,linux,windows --org=be.crispstro .`
  added the three platforms (~50 new files: Gradle, CMake, Win32 runner,
  manifests, mipmap dirs).
- Android launcher icons sized for every mipmap density (48/72/96/144/192).
- `CalculatorEngine` already handles a missing bridge gracefully —
  `DynamicLibrary.open('libSymEngineFlutterWrapper.so')` throws on
  platforms without the lib, the constructor catches and stays in
  `_nativeAvailable = false` mode. The UI, persistence, plane/conic
  analysis, vector/tensor math, plot rendering all still work.
  Symbolic operations (`solve`, `factor`, etc.) return clear "requires
  native library" error strings.
- Three new CI workflows:
  - `build-android.yml` — Ubuntu + Temurin 17 + Android SDK → debug APK.
  - `build-linux.yml` — Ubuntu + GTK 3 + Ninja → release bundle (tar.gz).
  - `build-windows.yml` — Windows-latest → release zip.
- `release.yml` extended to build all 5 platforms (macOS, iOS, Linux,
  Windows, Android) on `v*` tags. Release body explains which builds
  have full symbolic support vs degraded mode.
- macOS/iOS still 236 tests passing. analyze clean.

## 2026-05-17 (round 9) — Repo public

- `gh repo edit CrispStrobe/CrispCalc --visibility public` — flipped
  after the green CI confirmation. The bridge plugin was already
  public.
- Added a description and topics: calculator, cas, dart, ffi, flutter,
  ios, macos, symbolic-computation, symengine.
- GitHub Actions minutes are now unlimited on the runner. The build
  matrix (CI + Build macOS + Build iOS, ~7 min total per push) will
  comfortably fit even with frequent pushes.

## 2026-05-17 (round 8) — About screen, LICENSE, GH Actions CI

### LICENSE + AGPL choice
- Added `LICENSE` at repo root: GNU Affero General Public License v3
  (fetched verbatim from gnu.org).
- The bundled GMP/MPFR/MPC/FLINT libraries are LGPL; statically linking
  them into a Flutter app effectively requires a strong-copyleft outer
  license. AGPL-3 fits and matches the sibling CrisperWeaver app.

### About / Über CrispCalc screen
- New `lib/screens/about_screen.dart`, modeled on CrisperWeaver's: app
  header (icon + name + version from `package_info_plus`), then cards
  for service provider, contact (tappable email), privacy, disclaimer,
  license link. Bottom button opens Flutter's `showLicensePage` which
  lists every pub dep.
- Added `lib/services/native_licenses.dart` + asset
  `assets/licenses/SYMENGINE_STACK.txt` with text/links for SymEngine,
  GMP, MPFR, MPC, FLINT. `main.dart` calls `registerNativeLicenses()`
  before `runApp` so they appear in the license page alongside pub deps.
- Settings screen got a new "About CrispCalc" / "Über CrispCalc" tile
  that pushes the new screen. Strings localized (en + de).
- Added `package_info_plus: ^8.0.0` and `url_launcher: ^6.2.0` deps.

### Bridge plugin pushed to public repo
- Committed and pushed the macOS support pieces I'd been keeping local:
  the Swift plugin class rename, the xcframework symlinks under `macos/`,
  the podspec update, and the optional FFI binding for native
  `integrate`. Commit `6c9f232` on `CrispStrobe/symbolic_math_bridge` main.
- Switched CrispCalc's `pubspec.yaml` to a `git:` dependency pinned to
  that SHA so CI runners (which don't have a sibling `../symbolic_math_bridge`
  directory) build the same source as local dev.

### GitHub Actions workflows
- `.github/workflows/ci.yml` — runs on every push/PR. Ubuntu runner.
  `flutter pub get`, `dart format --set-exit-if-changed`,
  `flutter analyze --no-fatal-infos`, `flutter test`. Linux runners cost
  1× compared to macOS's 10× — cheapest gate possible.
- `.github/workflows/build-macos.yml` — macOS-14 runner. Builds the
  debug `.app` and asserts at least 30 `flutter_symengine_*` symbols
  landed in the binary (catches the link regression I hit in this
  round). Uploads a zipped `.app` as a 14-day artifact.
- `.github/workflows/build-ios.yml` — same shape but `flutter build ios
  --release --no-codesign`. Unsigned IPA so reviewers can verify the
  build path without needing Apple Developer credentials.
- `.github/workflows/release.yml` — triggered by `v*` tags. Builds
  release artifacts for macOS and iOS, attaches them to a GitHub
  Release with auto-generated notes. macOS symbol-count check is a
  warning (not a hard fail) because release link is the open P1.

### Housekeeping
- Ran `dart format` on the full tree (52 files; 40 changed). CI's
  format gate would have rejected them otherwise.

### Status
- `flutter analyze`: 31 info hints, no errors / warnings.
- `flutter test`: **236 passing.**
- macOS debug build still works; SymEngine symbols linked.
- Ready to go public after these changes land.

## 2026-05-17 (round 7) — Native integrate (PLAN P1#1)

### Discovery
- The SymEngine static archive *already* exports `flutter_symengine_integrate`
  (single `nm` of the macOS slice confirms it). The header file warned
  "Not implemented in SymEngine's C API" but the symbol is there. The
  bridge plugin just never bound it.

### Bridge binding
- Added a `_SolveDart? _integrate` field on `SymbolicMathBridge` and an
  optional lookup. When the wrapper exposes the symbol, the field is
  populated; when it doesn't (older builds), it stays null. Exposed a
  public `bool get hasIntegrate` so callers can switch paths cleanly.
- New `String integrate(String expression, String symbol)` method that
  marshals the call through FFI exactly like `differentiate`.

### CalculatorEngine integration
- `integrate(expression, variable)` (no bounds) now returns the symbolic
  antiderivative from the native wrapper, e.g. `integrate(x^2, x)` →
  `x^3/3`.
- `integrate(expression, variable, lower, upper)` (definite) tries the
  fundamental-theorem-of-calculus route first: ask for an antiderivative
  `F`, substitute the bounds, return `F(b) - F(a)` (a clean exact value
  like `1/3` for `∫₀¹ x² dx`). If anything fails — wrapper rejects the
  integrand, antiderivative isn't elementary, etc. — falls back to
  Simpson's rule with 200 subintervals.
- Both paths defer to the existing "requires native library" error when
  the bridge isn't loaded (so unit tests stay deterministic).

### Tests
- Updated `test/limit_integrate_test.dart` to cover the new definite path.
- Full suite: **236 passing.** `flutter analyze` clean.

### Status of `limit`
- The native archive does *not* export a `limit` entry point. Adding one
  would require rebuilding the C++ wrapper from source (lives in a
  separate repo). Filed in PLAN as the remaining symbolic-CAS gap;
  numerical one-sided / infinity limits remain as the best-effort answer.

## 2026-05-17 (round 6) — 2-pane keypad, release build investigation

### Wide-screen keypad: 2 panes, independently switchable
- Previous 4-up layout (whether one-row or 2×2 grid) crammed buttons too
  small. New layout: exactly two panes side-by-side. Each pane has its
  own little `ChoiceChip` row at the top to pick which content to
  display — Num / Trig / CAS / Advanced / Vars. Defaults: left = Num,
  right = CAS. The user can swap either side independently.
- Threshold for 2-pane mode: 900 px. Below that the 5-tab compact mode
  kicks in unchanged.
- Buttons are now properly sized — each pane gets ~half the keypad
  width with 4 columns, so cells are large enough to read & tap.

### Release build attempted, debug still working
- Tried `flutter build macos --release`. Build succeeds (52.7 MB universal
  binary) but `nm` reports 0 `flutter_symengine_*` symbols in the
  Runner binary — the static archive isn't getting linked in for
  release configs even though the Pods-Runner.release.xcconfig has the
  same `-all_load` we use successfully in debug.
- Experimented with `-Wl,-force_load,<xcframework-slice>` instead of
  `-all_load`: works for either path alone but produces duplicate
  symbols when combined. Couldn't find a combination that works for
  both debug AND release in one Podfile pass.
- Reverted to the working `-all_load` configuration so debug stays
  green; added a P1 entry to PLAN.md with the failure details so the
  release-link investigation can continue.



### Matrix editor reachable
- It's already wired up: tap the `matrix` button on the Symbolic keypad and
  the calculator pushes the `MatrixEditorScreen`. The "Use Matrix" button
  in the editor returns `[1,2; 3,4]`-style syntax back into the input.
  (The button label wasn't very discoverable — left as-is for now; see
  PLAN.)

### Keypad: full inventory back, smarter wide layout
- I had over-corrected the previous "too overcrowded" feedback by dropping
  buttons. Restored the full inventory:
  - **Num** (24 keys): digits, parens, basic operators, `^`, `sqrt`, `π`,
    `EXE`.
  - **Trig** (16): `sin/cos/tan`, inverse + hyperbolic + inverse-hyperbolic
    families, `ln/log/exp/abs`.
  - **CAS** (16): `solve`, `factor`, `expand`, `simplify`, `d/dx`, `∫`,
    `lim`, `subst`, `gcd`, `lcm`, equals, comma, `f(x)`, cursor arrows,
    `EXE`.
  - **Advanced** (20): `gamma`, `!`, `fib`, `prime`, `mod`, `ⁿ√x`, `γ`,
    `∞`, matrix ops (`matrix`, `det`, `inv`, `transpose`), the new vector
    ops (`dot`, `cross`, `norm`, `unit`), `x`, `Ans`, `i`, `EXE`.
- TabController length back to 5; mobile sees five clean tabs.
- Wide layout no longer crams all four sections side-by-side — uses a 2×2
  grid (Num+Trig on top, CAS+Advanced below) plus the Vars panel on the
  right. Cells stay a comfortable size.
- Wide threshold moved from 760 → 900 px since the layout is now beefier.

### Tensor core (rank-N, pure Dart)
- New `lib/engine/tensor.dart` with a shape-aware `Tensor` class:
  - Constructors: `scalar`, `vector`, `matrix`, `fromNested` (auto-infers
    shape from arbitrarily nested lists), `filled`.
  - Indexed access (1-based check, range-validated): `getAt`, `setAt`
    (immutable — `setAt` returns a new tensor).
  - Element-wise `+`, `-`, scalar `scale(s)`.
  - General contraction over a chosen axis pair on each side. For matched
    rank-1 ↔ rank-1, the result is a scalar (a `String` of the dot
    product). Otherwise a new tensor with the contracted axes removed.
  - Vector helpers: `dot`, `cross` (3D only, validates), `norm` (symbolic),
    `numericNorm` (returns `double?` when all components parse as reals).
- Components stay as SymEngine-compatible strings so symbolic content
  (e.g. `'x'`, `'2*y+1'`) flows through arithmetic and reaches the engine
  for simplification.

### Vector preprocessor
- New `lib/engine/vector_math.dart` rewrites `dot(...)`, `cross(...)`,
  `norm(...)`, `unit(...)` calls on inline vector literals into plain
  arithmetic before the engine sees them:
  - `dot([1,2,3], [4,5,6])` → `((1)*(4) + (2)*(5) + (3)*(6))` → 32.
  - `cross([1,0,0], [0,1,0])` → `[0, 0, 1]` (after SymEngine simplifies).
  - `norm([3,4])` → `sqrt((3)^2 + (4)^2)` → 5.
  - `unit([1,0,0])` → `[(1)/sqrt(...), (0)/sqrt(...), (0)/sqrt(...)]`.
- Walks the expression with a fixed-point loop so nested calls like
  `norm(cross(a, b))` resolve fully. Vector-returning rewrites emit a
  bare `[...]` literal so the outer call can re-parse it.
- Hooked in at the top of `ExpressionPreprocessingUtils.preprocessNativeExpression`
  so the calculator and graphing screens both benefit.

### Calculator handlers added
- `exp`, `subst`, `i`, plus all four vector ops — they were missing
  button handlers when I restored the keypad.

### Tests (51 new → 235 total, all passing)
- `test/tensor_test.dart` — 23 cases: construction, indexing, shape
  validation, element-wise ops, scale, dot/cross/norm/contract.
- `test/vector_math_test.dart` — 13 cases: dot/cross/norm/unit
  expansions, length/arity validation, non-vector pass-through,
  partial-word safety (`dotty(...)` doesn't trigger), nested calls.

### Status
- `flutter analyze`: clean (no errors / warnings).
- `flutter test`: **235 passing.**
- macOS debug build succeeds, SymEngine still linked, app launches.



### App icon
- The icon assets had been correct since the previous round, but macOS's
  Launch Services cache was holding on to the old icon. Killed the
  running app, re-registered the bundle via `lsregister -f`, restarted
  Dock and Finder, relaunched. New blue squircle now shows.

### Auto-solve bare equations
- The calculator used to print "Error: evaluate failed" if you typed an
  equation like `2x+3=0` or `x^2 - 4 = 0` without wrapping it in
  `solve(...)`. Now anything containing `=` that didn't already match
  the variable-assignment or function-definition patterns is routed
  through the solver automatically. `2x + 3 = 0` → `x = -3/2`.
- The handler builds `LHS - (RHS)` and asks `detectVariable` what to
  solve for, then dispatches `_engine.solve`.

### `detectVariable` regex bug
- The single-letter detector used `\b([a-zA-Z])\b`, but `\b` doesn't fire
  between a digit and a letter, so `2k+5` returned zero candidates and
  fell through to the default `x`. Switched to explicit
  `(?<![a-zA-Z])([a-zA-Z])(?![a-zA-Z])` so digit-adjacent variables
  (`2k`, `3y`, `100z`) are now detected correctly. Confirmed with a new
  test (`detectVariable('2k+5')` → `'k'`).

### Tests
- New `test/auto_solve_test.dart` covers the bare-equation heuristic
  and the `detectVariable` cases that now work.
- 184 + 9 new = **193 tests passing**; `flutter analyze` still clean.



### Pure-math helpers extracted for unit testing
- Moved the plane analysis math from the screen's `_analyze` into
  `lib/engine/plane_math.dart` as `analyzePlaneFromCoordinate` /
  `analyzePlaneFromParametric` returning a `PlaneAnalysis` record.
- Moved the conic classifier into `lib/engine/conic_math.dart` as
  `analyzeConic(...)` returning a `ConicAnalysis`.
- Extracted Simpson's rule, one-sided limit, limit-at-infinity into
  `lib/engine/numerical.dart`. `CalculatorEngine.limit` / `integrate`
  now call these helpers so production and tests run the same code.

### New test files (60 tests added → 184 total, all passing)
- `test/plane_math_test.dart` — Vector3 ops, coordinate-form analysis,
  parametric form, point-on-plane verification, zero/parallel error paths.
- `test/conic_math_test.dart` — unit circle, axis-aligned ellipse,
  parabola, hyperbola, translated circle, xy=1 (45° rotation),
  degenerate cases, discriminant signs.
- `test/numerical_test.dart` — `∫₀¹ x dx`, `∫₀¹ x² dx`, `∫₀^π sin(x) dx`,
  reversed limits, non-finite integrand, odd-n correction, `sin(x)/x`
  removable singularity, jump discontinuity, infinity convergence.
- `test/limit_integrate_test.dart` — fallback paths when the bridge
  isn't loaded (so unit tests run on host without the native lib).
- `test/app_state_persistence_test.dart` — locale and number-format
  load/save round-trip, history JSON encoding, 200-entry cap,
  variables JSON, graph functions JSON, theme mode load/save.

### Persisted everything else
- `AppState` now persists *all* user data, not just locale + number
  format: history (JSON, capped at 200), user variables (JSON map),
  graph functions Y1..Y10 (JSON array), and theme mode.
- Added `AppState.load({force: false})` flag so tests can reset the
  singleton with a fresh `SharedPreferences.setMockInitialValues`.

### History clear button
- Added a sweep icon next to the LaTeX/plain segmented toggle on the
  calculator screen. Pops a confirm dialog, calls `AppState.clearHistory`,
  which also writes the empty list back to prefs. Localized (English +
  German).

### Light / dark / system theme picker
- `AppState.themeMode` is a new persistent `ThemeMode`.
- `MaterialApp` now has both `theme` (light) and `darkTheme` (dark) plus
  `themeMode: appState.themeMode`. The NavigationRail / BottomNavBar
  surfaces use `Theme.of(context).colorScheme` so light mode actually
  looks correct.
- Settings has a new card with three options (System / Light / Dark),
  fully localized.

### Tests still green
- `flutter analyze`: no errors / warnings — 19 info-only hints.
- `flutter test`: **184 / 184 passing.**



### macOS build & native bridge linkage
- Installed CocoaPods correctly (the Homebrew install was already there but
  was tripping over a stale `~/.gem/ruby/3.1.3/gems/bigdecimal` from a Ruby
  upgrade — `flutter build macos` now runs with `GEM_HOME` / `GEM_PATH`
  unset so `pod` uses its bundled gems).
- `symbolic_math_bridge` plugin was missing its macOS bits. Fixed by:
  - Renaming `macos/Classes/SymbolicMathBridgePlugin.swift` →
    `SwiftSymbolicMathBridgePlugin.swift` and aligning the class name with
    the iOS one so `pluginClass: SwiftSymbolicMathBridgePlugin` resolves
    on both platforms.
  - Pointing the macOS podspec at the existing xcframeworks (GMP, MPFR,
    MPC, FLINT, SymEngineFlutterWrapper) via in-directory symlinks — the
    xcframeworks already shipped a `macos-arm64_x86_64` slice, just hadn't
    been wired up.
  - Adding `-all_load` to the Runner's `OTHER_LDFLAGS` in a Podfile
    `post_install` hook. Without it the linker drops every SymEngine
    symbol (they're reached only via `dart:ffi`, not by static reference).
- Removed the stale "Run Script" build phase in `macos/Runner.xcodeproj`
  that called a missing `copy_native_lib.sh` script — the project no
  longer ships a per-build dylib.
- `nm` now reports ~45 `flutter_symengine_*` symbols in the built binary
  and `evaluate("1+1")` returns `2` instead of "requires native library".

### Crash / focus fixes
- Three `KeyboardListener(autofocus: true)` instances (calculator,
  graphing, function-editor) were alive at once in the `IndexedStack`.
  After a few clicks they'd corrupt the focus tree and the app would
  freeze. All three now use `autofocus: false`; `MainScreen.requestFocus()`
  explicitly drives focus when the user changes destinations.
- Three function-picker dialogs (Integral, NthRoot, Limit) created
  `FocusNode()` inline in `build()` — a new node every rebuild, never
  disposed. Replaced with state-held FocusNodes that get disposed.

### Keypad / layout redesign
- User feedback: "we do NOT need all the tabs … on a large enough screen"
  and "now it is way to overcrowded. half of the buttons would be much
  better. so 2 and not 4 or 5 tabs?". So:
  - Consolidated the keypad from 5 tabs (Num / Trig / CAS / Advanced / Vars)
    down to 3 (Basic / Symbolic / Vars), each with a curated key list.
  - Above ~760 px the keypad drops the tab bar and shows Basic + Symbolic
    + Variables side by side ("flat" layout).
  - TabController length lowered from 5 → 3 in all four screens that
    embed the keypad (was crashing graphing once the keypad shrank).
- Dropped the secondary-pane split layout from `MainScreen` — it added
  complexity without much value. Wide screens now just use a single
  `NavigationRail` (extended above 1100 px) and one content area.

### Graphing screen
- Default `_showKeypad = false` so the plot has the full graph area at
  launch. The toolbar toggle still works.
- When the keypad is shown, plot flex 3 vs keypad flex 2 keeps the plot
  dominant.
- Added explicit Zoom In, Zoom Out, Reset View buttons in the app bar
  (the pinch gesture still works too).

### Variable / Memory panel overflow
- The memory grid was `GridView.count(crossAxisCount: 3, aspectRatio: 2.2)`
  inside `maxHeight: 120`. On wide parents the cells stretched and the
  grid blew past `maxHeight`, causing yellow/black overflow stripes.
  Replaced with a `Wrap` of fixed `64×36` tiles.
- Wrapped the entire viewer in a single `SingleChildScrollView` so short
  viewports scroll instead of clipping.

### Numerical limit + integrate
- Added Dart-side numerical implementations because the C++ wrapper
  doesn't expose `limit`/`integrate` yet:
  - `limit(expr, var, point)` evaluates the expression at `point ± 1e-7`
    (and at `1e10` for `oo`), checks one-sided agreement, returns the
    converged real value or a clear "limits differ" / "does not
    converge" error.
  - `integrate(expr, var, lower, upper)` does composite Simpson's rule
    with `n = 200` subintervals. Indefinite integration still returns
    a "not yet supported" error.
- Calculator screen now routes `integrate(...)` and `limit(...)` through
  those new handlers (was returning the placeholder error before).

### F → Y compatibility
- `F<N> = expr` no longer hard-errors; it stores into the same slot as
  `Y<N>` so old muscle memory works.

### Analysis modules — Planes & Conic Sections
- Built `plane_analysis_screen.dart`: accepts either coordinate form
  (`ax + by + cz = d`) or parametric form (point + two direction
  vectors), then reports the other form, unit normal, Hessian normal,
  signed distance from origin, and axis intercepts. Pure Dart, no
  SymEngine needed.
- Built `conic_section_screen.dart`: classifies `Ax² + Bxy + Cy² + Dx +
  Ey + F = 0` using the discriminant. Reports type (ellipse / circle /
  parabola / hyperbola), center for central conics, rotation angle when
  `B ≠ 0`, and semi-axes + eccentricity when the shape is non-degenerate.
- Replaced the analysis hub's two "coming soon" snackbars with real
  navigation to the new screens.

### Persistence + full i18n
- Added `shared_preferences: ^2.2.0`. `AppState` now has an async
  `load()` that runs before `runApp` and persists locale + number
  format. Changes are saved on the spot.
- Settings screen got a language picker (English / Deutsch). It writes
  through `AppState.setLocale`, the `MaterialApp` rebuilds with the new
  locale, and the choice survives restarts.
- `AppLocalizations` grew to cover nav destinations, graphing screen,
  analysis modules, settings, dialogs, snack bars, and keypad section
  labels. The German translation tracks every key.

### App icon
- Generated a 1024×1024 master with the BFL FLUX API (deep-blue → cyan
  gradient squircle, white sine wave + plus sign, no text). Sized down
  to every slot in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
  (16, 32, 64, 128, 256, 512, 1024) and
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (every required
  `@1x/@2x/@3x` combination 20 → 1024).

### Tests still green
- 124 tests passing under `flutter test` after every round of changes.
- `flutter analyze` is at 19 info-only hints, no errors, no warnings.

---

## 2026-05-16 — Audit, fixes, tests, adaptive layout

### Build / dependency
- Restored the missing `symbolic_math_bridge` path dependency from backup so
  `flutter pub get` succeeds. Moved the project to `/Volumes/backups/code/`
  to free space on the cramped main volume.
- Fixed the only compile-error in the test suite (`test/widget_test.dart`
  referenced the non-existent `MyApp` class).

### Correctness bugs
- `_handleSimplifyFunction` was wired to `_engine.expand()`. Added
  `simplify()` to `CalculatorEngine` and pointed the handler at it.
- `KeyboardInputHandler` unconditionally swapped Y↔Z and rewrote every `*`
  via physical-key checks, so any non-German keyboard misbehaved. Rewrote to
  use `event.character` (already layout-resolved by the OS) and added a
  `multiplicationAsCdot` flag so the `*` → `\cdot ` rewrite is overridable.
- `\frac{}{}` insertions used `cursorOffsetFromEnd: -4`, which placed the
  cursor *outside* the first brace pair. Corrected to `-3` so typing into a
  freshly-inserted fraction goes into the numerator.
- `LatexConversionUtils.fromLatex` ran power/subscript rewrites before
  integral/limit/sum/product rewrites, which stripped the `_{...}^{...}`
  groups those depend on. Reordered.
- `fromLatex` also called `result.replaceAll('|', '')` at the top, which
  broke `|x|` → `abs(x)`. Removed; pipes are now content.
- `ExpressionPreprocessingUtils.preprocessNativeExpression` produced
  `Matrix([[1,2],[3,4]])` without spaces; the subsequent German-comma rule
  rewrote `1,2` → `1.2`. Matrix conversion now emits `1, 2` with a space.
- `detectVariable` was lower-casing the equation before scanning, so `X`
  became `x`. Made the matcher case-sensitive (SymEngine treats them as
  distinct).
- `preprocessExpression` had no recursion guard, so a cyclic Y1 → Y2 → Y1
  reference would loop forever. Added a depth cap (4) and a regression test.

### Dead code / deprecated APIs
- Replaced every `RawKeyboardListener` (calculator, graphing, curve-analysis,
  function-editor, three dialog widgets) with `KeyboardListener`.
- Replaced every `withOpacity(x)` with `withValues(alpha: x)` across
  `graphing_screen.dart`, `variable_viewer.dart`, `curve_analysis_input_screen.dart`,
  `function_editor_screen.dart`.
- Deleted `_toLatex_old` from `calculator_screen.dart`, `latex_input_field.dart`,
  `function_picker_dialogs.dart`. Deleted `_normalizeForDisplay_old` from
  `analysis_engine.dart`. Deleted `_getColorForUserFunction` from
  `variable_viewer.dart`. Deleted the unused `_analysisEngine` field and
  unreferenced `onSave` parameter.
- Replaced 50+ `print(...)` calls with `debugPrint(...)` or guarded them
  behind `kDebugMode`.
- Converted top-of-file `///` doc comments to `//` where they weren't real
  library-level docs.
- Dropped unused imports.

### Engine surface
- `CalculatorEngine` exposes `simplify`, plus a graceful fallback for every
  method when the native bridge isn't loaded so unit tests can run.

### Tests (124 total, all passing)
- Test files cover preprocessing, LaTeX conversion, display formatting, app
  state, controller, keyboard handler, engine fallbacks, analysis pipeline.

### Responsive layout (v1)
- Initial adaptive shell: bottom nav below 720 px, NavigationRail above.
  Dropped the `BoxConstraints(minWidth: 400, …)` that was clipping smaller
  desktop windows.

### Docs
- Rewrote `readme.md`: corrected file structure, removed dead CMake
  instructions, documented the adaptive layout and known limitations.

### Static analysis
- 210 issues (1 error) → 19 info-only hints by the end of this round.
