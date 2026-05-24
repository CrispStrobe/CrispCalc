# CrispCalc — Repair & Completion Plan

Living document. Each task: `[ ]` pending · `[~]` in-progress · `[x]` done.
Completed items are moved (with date) to `HISTORY.md`.

See `HISTORY.md` for the most recent work: 60 new unit tests covering plane,
conic, numerical helpers and full AppState persistence; the calculator
history clear button; persistent history / variables / graph functions;
and the light/dark/system theme picker.

---

## P1 — Open follow-ups

- [x] ~~Make `CrispCalc` repo public.~~ Done 2026-05-17 — see HISTORY.
- [ ] **Native `limit`.** The native bridge doesn't expose a `limit`
  entry point and SymEngine itself doesn't ship a general
  `limit(f, x, a)` — there's nothing to bind to yet. To unblock, work
  has to land in the bridge's C++ layer first, then a one-line Dart
  binding follows. Three tiers, increasing effort:
  1. **Series-based**: use SymEngine's `series_n` to compute a Taylor
     expansion at the point and return the constant term. Handles
     analytic functions with finite limits. Misses `sin(x)/x`, most
     transcendental ratios.
  2. **L'Hôpital loop**: handcrafted in C++ over SymEngine's `diff`
     and `subs`. Handles 0/0 and ∞/∞ for ratios; iterates until the
     limit is determinate or a step budget is hit. Covers the common
     calculus-textbook cases.
  3. **Gruntz algorithm**: full general limit-finding. Real CAS
     engineering — port from SymPy's reference implementation. Wide
     coverage but a multi-week project.
  Numerical one-sided / infinity limits (`lib/engine/numerical.dart`)
  stay as the safety net regardless of which tier ships. Native
  `integrate` was bound similarly — see HISTORY round 7.
- [x] ~~**`flutter build macos --release`: SymEngine wrapper symbols dropped.**~~
  Fixed 2026-05-17 — see HISTORY round 13. Bridge plugin now uses an
  `+load` keepalive with an asm-clobber `DoNotOptimize` loop over every
  `flutter_symengine_*` function pointer. Release builds keep all 45
  wrapper symbols.
- [ ] **iOS smoke test.** Not run since the recent changes.

## P2 — Engine + native bridge

- [ ] **High-precision evaluation.** `SymbolicMathBridge.evaluateWithPrecision`
  / `gmpPower` / `mpfrHighPrecisionPi` still throw — wire them when the
  C++ wrapper exposes the corresponding symbols.
- [x] ~~**Matrix arithmetic end-to-end.** Confirm `det(Matrix([[…]]))`,
  `inv(...)`, `transpose(...)` round-trip cleanly through the engine
  with a release SymEngine build.~~ Done 2026-05-17 — see HISTORY
  round 16. Required a new `MatrixEvaluator` that routes matrix
  expressions through the FFI matrix bindings (SymEngine's text
  parser doesn't recognize `Matrix(...)` literals). 6/6 self-test
  checks pass in the release build; trigger them with the
  `CRISPCALC_DIAGNOSTIC=matrix` env var or via Settings → "Matrix
  self-test".

## P2 — UX polish

- [x] ~~**More translations.** German is up to date; Spanish / French
  would be cheap follow-ups.~~ Done 2026-05-17 — see HISTORY round 17.
  Full FR and ES locales (~95 strings each) plus a per-locale
  non-emptiness test suite (20 checks) so missing strings would fail
  CI rather than a runtime UI lookup.
- [x] ~~**Variable substitution dialog** — no more typing `subst(...)`.~~
  Done 2026-05-17 — see HISTORY round 14.
- [x] ~~**Plot annotations** — mark extrema and roots on the graph
  when an analysis is open.~~ Done 2026-05-17 — see HISTORY round 15.
  Toggleable from the graphing screen toolbar; uses numerical scan
  with bisection / parabolic refinement so no SymEngine round-trip
  per point.

## P3 — Long tail

- [x] ~~Symbolic Gauss / RREF on matrices.~~ Done 2026-05-17 — see
  HISTORY round 19. `rref(...)` is wired into the matrix evaluator,
  the keypad, and the self-test battery; the canonical 2×3 textbook
  example reduces correctly in release.
- [x] ~~CI: GitHub Actions to run `flutter analyze` + `flutter test` on PR.~~
  In place since round 8 (`.github/workflows/ci.yml`). Round 18 also
  switched the macOS build workflow to `--release` and added a
  headless matrix-diagnostic step, so the bridge plugin's release
  symbol-keep regression risk is caught in CI now.
- [x] ~~History view filtering / search.~~ Done 2026-05-17 — see
  HISTORY round 14.

---

## P4 — Production-readiness (gaps for a real release)

Things that matter once real users install the app, separate from any
single feature. Roughly in priority order — top items unblock the next.

### Operability

- [ ] **Crash reporting (opt-in)**. Today a release crash on a user's
  device is invisible to us. Add a privacy-respecting crash reporter
  (Sentry self-hosted, or just a "send a crash log" button that emails
  the report rather than uploading silently). Opt-in only — keeps the
  "no telemetry" promise from the About screen honest.
- [~] **Storage hardening**. History persists via `shared_preferences`
  which has no size guarantees and is the wrong tool for a growing log.
  - LRU cap (200 entries) shipped since round 1.
  - **Export-to-clipboard** done 2026-05-17 — Settings → "Export
    data" produces pretty-printed JSON of every persisted piece
    (history, variables, graph functions, parameters, locale,
    number format, theme). User pastes into a notes/cloud doc as
    backup. No new dependency needed.
  - **Import-from-JSON** done 2026-05-24 — Settings → "Import data"
    pairs with the existing Export. Paste-or-edit JSON in a
    multiline textarea, Apply validates and restores into
    AppState; partial payloads (missing keys) are tolerated so
    older exports still apply forward-compatibly.
  - Pending: file-system export via `file_saver` / share sheet;
    move to `sembast` or `sqflite` (only matters when storage size
    becomes a real problem).
- [ ] **Distribution pipeline**. macOS and iOS builds are unsigned, so
  the App Store / TestFlight / hardened-runtime paths aren't open. Apple
  Developer enrollment + notarization workflow + automatic version
  bumping on tag. Same shape for Android via Play.
- [~] **Long-evaluation off-main-thread**. Big integrals or matrix ops
  can freeze the UI for several seconds. Wrap bridge calls in a Dart
  isolate (or at least `compute()`) and show the progress overlay
  (`lib/widgets/progress_overlay.dart` already exists, just isn't wired
  in for engine calls).
  - **V1 partial** (HISTORY round 51): new `EngineService` offloads
    "potentially slow" evaluations to a worker isolate via `compute()`.
    A `shouldRunAsync` heuristic decides per expression — long inputs,
    CAS function calls (integrate/factor/simplify/expand/solve/limit),
    matrix shapes, factorials > 50, fibonacci > 100. Short bare
    arithmetic stays on the main thread (isolate-init cost would dwarf
    the work). Calculator screen wraps the bare-evaluate path with a
    300 ms-watchdog `ProgressOverlay` so quick ops don't flash and
    slow ops surface a "Calculating…" card.
  - **V2 pending**: extend the async path to the dedicated function
    handlers (integrate/limit/solve special-case branches), wire a
    long-lived worker isolate to amortize the bridge-init cost, add a
    cancel button.

### Quality

- [~] **UI flow tests**. Widget tests today cover "app boots." Every
  calculator gesture — enter expression, tap solve, store as variable,
  open substitute dialog, run analysis — has zero test coverage. A
  button rename can break a flow without CI flagging it.
  - Settings + Analysis hub flows shipped 2026-05-17 — 7 tests
    covering Help screen / Constants dialog / Unit converter /
    Export data / locale switch / Statistics module open / Analysis
    hub layout (`test/ui_flows_test.dart`).
  - Calculator-keypad-driven flows still pending — better fit for
    `integration_test` since they depend on the keypad layout
    breakpoint.
- [~] **Integration tests via `integration_test` package**. The
  matrix-diagnostic env-var hack is a stand-in for what should be a
  real integration suite that drives the actual UI in CI. Once the
  package is in place, port the matrix battery and add flows that the
  widget tests can't easily exercise.
  - Package wired up 2026-05-17. `integration_test/app_smoke_test.dart`
    has two boot-and-find tests; running locally with
    `flutter test integration_test/app_smoke_test.dart`. CI
    integration (real devices / simulators) and richer flows pending.
- [~] **Golden tests for plot painter + LaTeX rendering**.
  - Structural anchor test for HelpScreen shipped
    (`test/golden/about_card_golden_test.dart`) — scrolls the
    function reference and asserts every section heading and group
    title is present. Catches dropped sections / empty cards.
  - Pixel-comparison goldens for plot painter + LaTeX rendering
    still pending — renderer-version drift would make CI fragile,
    so we'd need a fixed Flutter-version pin first.
- [ ] **Accessibility audit**. Add `Semantics` widgets to keypad
  buttons, label every IconButton, verify keyboard navigation for the
  full settings flow, audit color contrast in both themes, test with
  VoiceOver / TalkBack. Currently the keypad is a wall of unlabeled
  buttons to a screen reader.

### User experience

- [x] ~~**Real error messages**. A student typing `det(x)` gets
  "Error: evaluate failed: SymbolicMathException: evaluate - parse
  failed". Replace with plain-language explanations…~~
  Done 2026-05-17 — see HISTORY round 27. New
  `EngineErrorFormatter` pattern-matches the raw engine error
  strings (parse failed, requires native, not implemented,
  invalid X() syntax, …) and returns localized friendly messages.
  History entries that look like errors render with an italic
  warning style in the theme's error color instead of the normal
  blue result. Unrecognized errors get a `⚠ ` prefix and keep their
  detail. Fragment-underlining and fix suggestions deferred to V2.
- [x] ~~**Onboarding tour**. First launch shows a 4-card tour: keypad
  tabs, history scroll, function picker, analysis hub. Skippable.
  Discoverable features stop being a problem.~~ Done 2026-05-24 —
  see HISTORY round 48. New `OnboardingTour` widget renders a paged
  Dialog with the four canonical cards; `AppState.onboardingDismissed`
  (persisted) gates the auto-show in MainScreen's initState
  post-frame callback. Settings gains a "Replay onboarding tour"
  tile that re-triggers the same dialog on demand. Localized
  across en/de/fr/es.
- [x] ~~**User documentation**.~~ Done 2026-05-17 — in-app Help
  screen reachable from Settings → "Help & function reference".
  Lists every supported op grouped by category (Arithmetic, CAS,
  Calculus, Trig, Vector/Tensor, Matrix, Probability) plus the
  matrix syntax cheatsheet and step-by-step trigger summary.
  Static content, no engine reflection.
- [~] **Share / export**.
  - Copy result + Copy as LaTeX shipped 2026-05-17 — long-press a
    history entry → bottom sheet with Copy result, Copy as LaTeX,
    Reuse expression.
  - Export-all-data shipped — Settings → "Export data" pretty-
    prints AppState as JSON for clipboard backup.
  - Pending: platform share sheet (needs `share_plus`), PDF export
    of the history (needs `pdf` package).

### Polish

- [x] ~~**Localize the picker dialogs**. `IntegralDialog`,
  `LimitDialog`, `NthRootDialog`, `SubstituteDialog` are still
  hardcoded English.~~ Done 2026-05-17 — see HISTORY round 26.
  All picker + step-by-step entry dialogs now route their labels,
  titles, hints, and action buttons through `AppLocalizations`.
  The bottom-sheet pickers too (`showSolveFunctionPicker`,
  `_showPicker`). 21 new strings × 4 locales added with locale-test
  coverage for every new key.
- [ ] **Perf instrumentation**. Frame-timing overlay in debug, jank
  detection in CI for one canonical flow, repeatable benchmark for the
  graph painter at common viewport sizes. Currently we don't know if
  CrispCalc feels sluggish on a low-end Android device.

---

## P5 — Feature surface: gaps to close

Things we don't do today that have become standard in the calculator-
app category. Some are pedagogy features, some are graphing features,
some are knowledge-domain expansions. Each costs roughly 1–2 weeks of
focused work; doing all four of the "recommended next" cluster would
roughly double the perceived value of the app.

### Recommended next (top 4, in priority order)

- [~] **Step-by-step solutions** for `diff`, `integrate`, and `solve`.
  Show *why* an answer is what it is — the rule applied at each step
  (chain rule, product rule, u-substitution, partial fractions, …) —
  not just the final symbolic result. The single biggest perceived-
  value gap.
  - **Differentiation done** (HISTORY round 20): `lib/engine/step_engine.dart`
    walks the top-level expression shape and emits rule-named steps
    (constant, identity, sum/difference, product, quotient, power,
    exponential, chain rule for sin/cos/tan/asin/acos/atan/sinh/cosh/
    tanh/exp/ln/sqrt). Final answer comes from SymEngine so we don't
    drift from canonical. `StepsDialog` renders each step as a card
    with LaTeX-rendered formula + before/after. New `d/dx⌄` keypad
    button as the entry point.
  - **Equation solving done** (HISTORY round 21): same engine extended
    with `StepEngine.solve()`. Detects polynomial degree via SymEngine
    derivatives; linear (1-step isolation), quadratic (discriminant +
    formula), and a graceful fall-through to SymEngine's `solve()` for
    higher-order / transcendental cases. New `solve⌄` keypad button.
  - **Integration done (V1)** (HISTORY round 22): same engine extended
    with `StepEngine.integrate()`. Modeled on SymPy's
    `manualintegrate` — fixed rule list, each rule either emits a
    step and recurses on a simpler sub-integrand or declines.
    Coverage: constant, identity (∫x dx), power rule, logarithm rule
    (1/x and x^-1), sum/linearity, constant multiple, and standard
    antiderivatives for sin/cos/exp/sinh/cosh when the argument is
    just the variable.
  - **Integration V2 done** (HISTORY round 34): linear u-substitution
    for the power rule (∫(ax+b)^n dx), logarithm rule (∫1/(ax+b) dx),
    and the standard sin/cos/exp/sinh/cosh antiderivatives; integration
    by parts for ∫x·f(x)dx with f ∈ {sin,cos,exp,sinh,cosh} (LIATE
    chooses u = the algebraic factor) and the special case ∫ln(x)dx;
    plus a leading-minus normalization rule so the IBP recursion
    cleanly resolves the sub-integral. Verified end-to-end against the
    native SymEngine via the steps diagnostic battery (37/37 specs).
  - **V3 partial** (HISTORY round 49): repeated integration by parts
    (∫x^n·f(x)dx for f ∈ {sin, cos, exp, sinh, cosh} now recurses
    on x^(n-1)·F(x) instead of bailing); non-linear u-substitution
    (∫c·g'(x)·f(g(x))dx → c·F(g(x))) using the bridge to verify
    `(other_factor)/g'(x)` is constant; logarithmic-derivative rule
    (∫(c·f'(x)/f(x))dx → c·ln|f(x)|). Three new `StepNote` keys
    (`ibpRepeated`, `uSubNonlinear`, `integralLogDerivative`) across
    en/de/fr/es.
  - **V4 partial** (HISTORY round 53): partial-fraction decomposition
    for ∫P(x)/Q(x)dx when Q has distinct integer roots in [-20..20];
    cover-up method (A_i = P(r_i)/Q'(r_i)) emits one ln-term per
    root. Plus two textbook trig-shaped closed forms: ∫1/(x²+a²)dx
    → (1/a)arctan(x/a) and ∫1/√(a²−x²)dx → arcsin(x/a). Four new
    `StepNote` keys across en/de/fr/es.
    **V5 deferred**: partial fractions for repeated roots / quadratic
    factors (need symbolic system-solve), full trig substitution
    (∫√(a²−x²)dx, ∫√(a²+x²)dx, ∫√(x²−a²)dx — needs an inverse-sub
    pass).
- [x] ~~**Interactive parameter sliders** on the graphing screen.~~
  Done 2026-05-17 — see HISTORY round 23. Identifiers in a function
  string that aren't the plot variable or a reserved name become
  parameters; a compact slider per parameter appears under each
  function chip, and the curve repaints live as the user drags.
  Values persist across restarts via shared_preferences.
- [~] **Statistics + probability module**. Descriptive stats on a list
  of numbers, linear / polynomial / exponential regression, normal /
  binomial / t / chi-square distributions and quantiles, basic
  hypothesis tests.
  - **V1 done** (HISTORY round 25): three-tab Statistics screen in
    the Analysis hub. Descriptive (count, mean, median, mode,
    quartiles, IQR, sample + population variance/stddev, range),
    linear regression (slope, intercept, R²), normal distribution
    (PDF, CDF, quantile via bisection on the CDF), binomial
    distribution (PMF, CDF, mean/variance, log-domain for large n).
    50 unit tests covering known textbook values.
  - **V2 partial** (HISTORY round 30): added Student's t-distribution
    (PDF/CDF/quantile via Lanczos log-gamma + Simpson on PDF) and
    chi-square distribution (same), plus least-squares polynomial
    regression (Gaussian-elim solve of normal equations, returns
    coefficient vector + R² + a `.evaluate(x)` helper). Verified
    against textbook z- and chi-square critical values; cubic /
    quadratic fits recover exact coefficients.
  - **V3 partial** (HISTORY round 32): hypothesis tests UI shipped
    as a 4th tab in the Statistics screen. One-sample t-test, paired
    t-test, χ² goodness-of-fit. Each takes inputs + a significance
    level α, returns the test statistic, df, p-values, and a colored
    "reject H₀" / "fail to reject H₀" verdict block.
  - **V4 partial** (HISTORY round 36): exponential regression
    (`y = a·exp(b·x)`) via log-linearization, plus a chip-row picker
    in the Regression tab so users can switch between linear,
    polynomial (degree 2–5), and exponential fits without leaving
    the screen.
  - **V5 partial** (HISTORY round 37): Welch's two-sample t-test for
    independent samples with possibly unequal variances. Added as a
    4th chip in the Tests tab next to one-sample t, paired t, and
    χ² goodness-of-fit. Welch-Satterthwaite df, two- and one-sided
    p-values, verdict block at α.
  - **V6 partial** (HISTORY round 38): one-way ANOVA + Snedecor's
    F-distribution. ANOVA appears as a 5th chip on the Tests tab.
    F-distribution gains a `sf()` survival-function method using the
    reciprocal-F relation (P(X > x) = F(d2,d1).cdf(1/x)) so deep
    upper-tail p-values for huge F statistics stay accurate.
  - **V7 partial** (HISTORY round 39): χ² test of independence on
    a contingency table. Computes expected counts under the null
    `E[i,j] = (rowTotal[i]·colTotal[j])/grand`, then χ² = Σ(O−E)²/E
    with df = (R−1)(C−1). Added as a 6th chip on the Tests tab.
  - **V8 partial** (HISTORY round 41): Fisher's exact test for 2×2
    tables. Enumerates all tables with the same row/column margins
    and computes exact two-sided + one-sided p-values via the
    hypergeometric distribution (log-domain for numerical stability
    on large totals). 7th chip on the Tests tab. Use this when any
    expected count in χ² independence is below ~5.
  - **V9 partial** (HISTORY round 46): paired sign test (Binomial
    on positives, drops zero-difference pairs) and Wilcoxon rank-sum
    / Mann-Whitney U (pooled-ranks with average-rank tie correction;
    normal-approximation p-value with tie-corrected σ_U). Added as
    8th and 9th chips on the Tests tab — the nonparametric
    counterparts to paired t and Welch's two-sample t.
- [~] **Unit-aware arithmetic**. `5 km / 30 min in mph`, `1 mile + 5 ft`,
  full SI prefix handling, dimension checking on results. Opens the
  engineering / physics / chemistry audience.
  - **V1 done** (HISTORY round 24): single-dimension converter with
    a Unit Converter dialog reachable from Settings. ~40 units across
    six dimensions (length, time, mass, temperature, velocity, angle)
    with proper offset handling for °C / °F. Conversion math fully
    unit-tested (50 examples).
  - **V2 partial** (HISTORY round 31): inline syntax shipped.
    `5 km + 3 m`, `1 mile + 5 ft`, `100 km/h in mph` etc. parse
    directly in the calculator — a separate `UnitExpressionEvaluator`
    tokenizes the input (longest-match against catalog symbols +
    natural-spelling aliases like `mile`/`feet`/`hour`) and intercepts
    before SymEngine would mis-parse the symbols as variables. Same-
    dimension `+`/`-` and `in <unit>` conversion suffix. Refuses
    temperature arithmetic explicitly (offset units are ambiguous;
    conversion still works).
  - **V3 partial** (HISTORY round 35): SI prefix parser shipped.
    Synthesizes prefixed forms (`pm`, `Tm`, `Gg`, `μK`, `dam`, `hm`,
    etc.) on demand by combining one of the 21 SI prefixes with one
    of the prefixable canonical bases (`m`, `s`, `g`, `K`, `rad`).
    Longest-prefix-first lookup so `da` (deca, 1e1) wins over `d`
    (deci, 1e-1). Curated catalog symbols (`mg`, `min`, `t`) still
    take precedence over a prefix interpretation.
  - **V4 partial** (HISTORY round 40): scalar arithmetic on a
    quantity — `2 * 5 km`, `5 km * 2`, `1 mile / 2`, chained
    `5 km * 2 / 4`. Scalar mul/div is rejected once a `+`/`-` has
    appeared, because mixing without a Shunting-yard parser would
    give wrong precedence (`5 km + 3 m * 2` is ambiguous). Quantity-
    × -quantity still falls through to V5.
  - **V5 partial** (HISTORY round 47): composite-dimension arithmetic.
    New `Dimensions` 4-vector (length / mass / time / temperature
    exponents); quantity × quantity and quantity / quantity now
    extend the running dimension vector (`100 m / 10 s = 10 m/s`,
    `5 m * 3 m = 15 m^2`). New `DerivedUnits` catalog (N, J, W, Pa,
    Hz) with SI-prefix support (kN, MJ, mW, …). The formatter prefers
    a curated single-dim unit, falls through to derived units, and
    only emits a base-units string (`15 m^2`) when no catalog match
    exists. Mixing composite-dim multiplication with `+`/`-` is
    refused with a clear error.
    **V6 deferred**: parentheses (need a real Shunting-yard pass),
    variables (need to plumb AppState into the unit-expression
    evaluator), exponentiation on units (`5 m^2`).

### Other meaningful gaps

#### Learning / pedagogy

- [ ] **Worked-example library**. Curated catalogue of problem types
  (related rates, optimization, vector projection, eigenvalue) with
  click-to-try examples. Discoverability + learning.
- [x] ~~**Plain-language step explanations**.~~ Done 2026-05-24 —
  see HISTORY round 45.
  - **V1** (HISTORY round 42): every common differentiation,
    integration, and solve rule emits a clear one-sentence English
    note explaining *why* the rule applies, on top of the formal
    formula. The StepsDialog already renders the note italicized
    below each step's before/after row.
  - **V2** (HISTORY round 45): notes translated to DE/FR/ES via a
    `StepNote(key, params)` sidecar on `MathStep`. AppLocalizations
    gains a `String? stepNote(StepNote)` resolver per locale; the
    StepsDialog asks for a translation and falls back to the
    embedded English `note` when the locale doesn't carry the key.
    34 unique keys × 4 locales with an exhaustive coverage test.

#### Input

- [ ] **Photo OCR of handwritten or printed equations**. Camera-to-
  equation has become table stakes in the consumer math-help category.
  Possible on-device with TFLite or Apple's `VisionKit` (iOS); cloud
  OCR is faster to ship but conflicts with the on-device promise.
- [ ] **Pen / handwriting input**. Apple Pencil + macOS trackpad
  handwriting recognition (`PKCanvasView` + `MLHandwritingRecognizer`)
  for math expressions. Niche but high-end feature.

#### Math surface area

- [x] ~~**3D graphing (V1)**.~~ Done 2026-05-17 — see HISTORY round 33.
  Wireframe surface plot z = f(x, y) over a configurable ±range, on a
  32×32 grid. Touch-rotate (azimuth + elevation) and pinch-zoom via
  `GestureDetector.onScaleUpdate`. Hand-rolled rotation matrix +
  orthographic projection (no `vector_math` dep). Height-tinted wires
  (blue → red HSV), three colored axes, z-range/orientation legend.
  Listed as a 5th `_ModuleCard` in the Analysis hub.
  **V2 deferred**: hidden-line removal, perspective projection,
  contour overlays, parametric 3D curves, intersection with planes.
- [x] ~~**User-defined function namespace**. Today's graph slots
  Y1..Y10 are a partial story. Allow named functions
  (`f(x) = x^2 + 1`), composition (`g(f(x))`), and a tab to browse /
  edit / rename them.~~ Done 2026-05-24 — see HISTORY round 50.
  New `UserFunction` model + persisted `AppState.userFunctions` map.
  Preprocessor inlines `<name>(arg)` references with paren-balanced
  argument capture and per-pass identifier-bounded parameter
  substitution; up to four expansion passes so `g(f(x))` composes.
  Settings tile opens a `UserFunctionsDialog` with add / edit /
  delete. Single-letter lowercase names (a..z) to avoid collisions
  with built-ins. Localized across en/de/fr/es.
- [x] ~~**Built-in constants library**.~~ Done 2026-05-17 — see
  HISTORY round 29. 30 constants across mathematical, physical,
  chemistry, and astronomy categories. Settings → "Constants
  reference" opens a dialog with category chips, substring search,
  and per-row copy-value-to-clipboard. CODATA 2022 / exact-SI
  values where applicable.

#### Precision & number theory (native libs already linked)

The SymEngine xcframework we ship on iOS/macOS bundles **GMP**
(arbitrary-precision integers), **MPFR** (correctly-rounded
arbitrary-precision floats), **MPC** (arbitrary-precision complex),
and **FLINT** (advanced number theory + polynomial arithmetic). All
four are already loaded at runtime — we just don't expose anything
beyond what SymEngine's parser surfaces. The work below is mostly
"add the FFI bindings + a few keypad buttons," not "add a new
dependency."

Group A (recommended first — ship together as one round):

- [x] ~~**Arbitrary-precision integer mode** (GMP / SymEngine integer).~~
  Done 2026-05-24 — see HISTORY round 44. Settings toggle "Exact
  integer mode" (on by default) guards `AppState.formatNumber` so
  results past double precision (digit count > 15) are passed
  through verbatim instead of being silently truncated. Calculator
  history renders any integer with >20 digits with an italic
  "Exact integer · N digits · tap to copy" badge underneath, and
  tapping the row copies the full untruncated value to the
  clipboard. Mid-row ellipsis abbreviates the display past 60
  digits so a single 158-digit `100!` doesn't dominate the screen,
  but the clipboard always sees the full string.

- [ ] **Arbitrary-precision real constants on demand** (MPFR).
  Templated calls: `pi(50)`, `e(100)`, `EulerGamma(200)`,
  `sqrt(2, 50)`, `ln(10, 100)`. The argument sets the decimal
  precision (1..10000). Backed by MPFR's `mpfr_const_pi`,
  `mpfr_const_euler`, etc. Pedagogically delightful for "what's π to
  100 digits?" classroom moments. Tiny: one FFI call per constant +
  a precision-aware formatter that uses the requested digit count.

- [ ] **Number-theory toy set** (FLINT + GMP). New keypad buttons /
  CAS shortcuts on the Adv tab:
  - `isprime(n)` → bool (FLINT BPSW + Miller-Rabin, exact for n &lt; 2^64)
  - `nextprime(n)` / `prevprime(n)` → next/previous prime
  - `factorint(n)` → list of `(prime, exponent)` tuples
  - `divisors(n)` → list of divisors
  - `totient(n)` → Euler's φ
  - `modinv(a, m)` → modular inverse via extended GCD
  - `modpow(a, e, m)` → fast modular exponentiation
  - `jacobi(a, n)` → Jacobi symbol
  Sits below `prime` / `factor` on the Adv tab (we already have
  those as one-shot, but FLINT-backed versions return structured
  results, not strings). Use case: high-school olympiad problems,
  introductory crypto.

Group B (V2 — more specialized, ship after Group A lands):

- [ ] **Polynomial arithmetic over Z, Q, F_p** (FLINT). New CAS
  ops: `polyfactor(p, mod=5)`, `polygcd(p, q)`, `polyresultant(p, q)`,
  `polydiscriminant(p)`. FLINT's `nmod_poly` / `fmpz_poly` already
  do all the heavy lifting; we'd add a small Dart-side type to
  represent polynomial-with-modulus and the bindings. Audience:
  abstract algebra students, undergrad cryptography homework.

- [ ] **Continued fractions** (GMP + MPFR). `cfrac(x, n)` returns
  the first n terms of the continued-fraction expansion as a list;
  `convergent(x, k)` returns the k-th rational convergent
  `Fraction(p, q)`. Tiny — n iterations of `floor` + `frac` against
  an MPFR mantissa. `cfrac(pi, 10)` → `[3; 7, 15, 1, 292, 1, 1, 1,
  2, 1]` is the kind of thing that should "just work" in a CAS.

- [ ] **Bessel / zeta / theta special functions** (MPFR). Plottable
  on the graphing screen: `BesselJ(n, x)`, `BesselY(n, x)`,
  `BesselI(n, x)`, `BesselK(n, x)`, `zeta(s)`, `theta(s, q)`, plus
  the existing `gamma` / `digamma`. MPFR has correctly-rounded
  implementations for all of these. Mostly an evaluator+grapher
  wiring round; the math is in the linked binary already.

- [ ] **Arbitrary-precision complex** (MPC). When the user opts into
  "high-precision mode," complex arithmetic stops collapsing to
  `Complex(double, double)` and uses MPC under the hood, giving
  correctly-rounded answers for `gamma(1+i)`, `(1+i)^100`,
  `BesselJ(2, 3+4i)`, etc. Useful only after Bessel/zeta land,
  since those are where double-precision complex first hurts.

---

#### Engagement / sharing

- [ ] **Shareable state links**. URL-encode the full calculator state
  (graphed functions, viewport, stored variables) so a link drops a
  recipient onto the same view. Pairs naturally with the web build.
- [ ] **Web build**. Flutter Web + a WASM backend for the bridge
  plugin would widen reach roughly 10× (instant-try in any browser,
  embeddable in textbooks / docs sites). Significant porting work
  but plausible — the bridge would need a `web/` platform target
  that compiles SymEngine to WASM.

---

## Out of scope this round

- C++ implementation of symbolic `limit` and `integrate`.
- Rewriting the LaTeX↔engine parsing as a real grammar.
- Full accessibility audit.
