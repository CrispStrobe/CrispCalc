# CrispCalc — History

Completed work, newest first.

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
