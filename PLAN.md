# CrispCalc — Repair & Completion Plan

Living document. Each task: `[ ]` pending · `[~]` in-progress · `[x]` done.
Completed items are moved (with date) to `HISTORY.md`.

See `HISTORY.md` for the most recent work: 60 new unit tests covering plane,
conic, numerical helpers and full AppState persistence; the calculator
history clear button; persistent history / variables / graph functions;
and the light/dark/system theme picker.

See **Strategic context (May 2026)** below for the framing that drives the
P5 "Strategic next" cluster.

---

## Strategic context (May 2026)

Where the iOS/Mac calculator category sits today and where CrispCalc fits
in it. This frames priorities below.

**Five distinct paradigms** dominate the 2026 calculator category:

1. **System-level integration** — recent OS-bundled calculator + notes
   apps now offer handwriting recognition, variables, and graphing
   built into the platform. On tablets this largely killed the case for
   a third-party "just a nicer calculator."
2. **Notepad / natural-language** — the dominant *innovation* paradigm.
   Type math like prose; results in a side column; edit any line and
   downstream recomputes. Where new users in the category are going.
3. **AI math solvers** — photo → step-by-step via multimodal LLM. The
   big 2024–2026 shift, but most are pure-LLM and hallucinate
   arithmetic.
4. **Graphing** — established standalone graphing apps still dominate
   the segment; no real challenger has emerged.
5. **Scientific / power-user** — mature paid calculators serve this
   tail; no recent innovation.

**Where CrispCalc actually stands.** Competitive-to-ahead on the
scientific/power-user axis and owning ground nobody else does:

- True symbolic CAS (SymEngine FFI) — most rivals don't have this.
- Deterministic step-by-step for `diff` / `solve` / `integrate` with
  plain-language localized notes across en/de/fr/es.
- Hypothesis-testing surface that beats every consumer iOS calculator
  (one-sample / paired / Welch t, ANOVA, χ² GoF, χ² independence,
  Fisher exact, sign, Wilcoxon).
- CSP module via `dart_csp` — Sudoku family (4×4 through 16×16, plus
  X / Killer / Disjoint variants), Diophantine, cryptarithm, generic
  DSL with optimization, scheduling (`noOverlap`, `cumulative`).
  **Nothing in the consumer category does this.**
- Composite-dimension unit arithmetic with SI prefixes and derived
  units (N/J/W/Pa/Hz).
- Cross-platform: iOS / Android / macOS / Linux / Windows. Most rivals
  are mobile-only or Mac-only.

**Where we're behind.** Two gaps, in priority order:

1. **Input paradigm is still 1995.** Keypad + LaTeX text field. The
   notepad-style document is the single biggest 2024–2026 innovation
   and we have none of it. Every primitive needed exists in the engine
   layer; this is a UI surface, not a new engine.
2. **No AI anywhere.** The category is racing toward LLM-frontended
   math. The empty quadrant — and the one CrispCalc is uniquely placed
   to occupy — is **AI as a *verifier-frontend*, never a solver**. AI
   translates input and narrates output; SymEngine + the step engine
   remain the only sources of arithmetic. No hallucinations, natural
   input.

**The bet.** Two strategic adds (P5 "Strategic next" below) reposition
CrispCalc from *"the strongest engine nobody knows about"* to *"the only
CAS-grade calculator with a 2026 input surface."* Existing
differentiators (CAS, CSP, stats, units, cross-platform) become the moat.
Distribution pipeline (P4) is the load-bearing prerequisite — without
TestFlight / App Store the rest compounds at zero.

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

- [~] **High-precision evaluation.** Four MPFR constants
  shipped: `pi(N)` (round 85), `e(N)` + `EulerGamma(N)` +
  `sqrt(2,N)` (round 86). Three number-theory primitives:
  `isprime(n)` + `nextprime(n)` + `prevprime(n)` (round 89 —
  GMP direct for isprime/prevprime; SymEngine ntheory for
  nextprime). Integer factorization: `factorint(n)` via
  FLINT's `fmpz_factor` (round 90). `evaluateWithPrecision`
  and `gmpPower` still throw — future arc work.
  `HANDOFF_PRECISION.md` documents the three-repo pipeline.
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
  **Priority bump (2026 reset)**: load-bearing prerequisite for the
  Strategic-next items above to matter. Without TestFlight / App Store,
  every new feature reaches only people willing to build from source.
  Should land before notepad V1 ships.
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
  - **V2 partial** (HISTORY round 56): every specialized handler
    (`integrate`, `limit`, `solve`, `factor`, `expand`, `simplify`,
    `d/dx`) now routes through the same async wrapper. New
    `EngineService.runOpAsync(EngineOp)` dispatches generic
    (op-kind, args) tuples across the isolate boundary. Cancel
    button on the progress overlay invalidates the in-flight task
    via a monotonic run-id (UI unblocks immediately; bridge call
    runs to completion in the background and its result is
    discarded). New i18n string `calculating`.
  - **V3 partial** (HISTORY round 57): replaced per-call `compute()`
    with a long-lived `_PersistentWorker` isolate that owns one
    `SymbolicMathBridge` for its lifetime — bridge init cost
    amortized across the whole session instead of paid per call.
    `cancelInFlight()` now `Isolate.kill`s the worker for real;
    pending futures complete with `EngineCancelled`. The next
    request lazily respawns a fresh worker.
    **V4 deferred**: progress callbacks (worker → main during a
    long calc), prioritized request queue.

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
- [~] **Accessibility audit**. Add `Semantics` widgets to keypad
  buttons, label every IconButton, verify keyboard navigation for the
  full settings flow, audit color contrast in both themes, test with
  VoiceOver / TalkBack. Currently the keypad is a wall of unlabeled
  buttons to a screen reader.
  - **V1 partial** (HISTORY round 55): every `CalculatorButton` now
    carries a `Semantics(label: ...)` wrapper with a glyph-to-speech
    map (√ → "square root", ⌫ → "backspace", π → "pi", d/dx →
    "derivative", etc.). Plain digits and named functions pass
    through. Plus tooltips wired on the two remaining bare
    `IconButton` sites (function-slot clear, memory-slot delete) +
    the calculator history-search clear-button. Three new
    accessibility-tooltip i18n strings × 4 locales. New
    `calculator_button_test.dart` pins the Semantics labels.
  - **V2 pending**: keyboard navigation audit (Tab order across
    settings + analysis), contrast verification in both themes,
    on-device VoiceOver / TalkBack pass.

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

### Strategic next (May 2026 reset)

Two adds that close the 2026 input-paradigm gap (see "Strategic context"
at the top of the file). Items in "Recommended next" below remain valid
but become *moat-building* rather than *positioning*, since the moat
(engine breadth) is already largely cut.

- [ ] **Notepad / document mode** (notebook-style). New top-level surface
  alongside Calculator / Graphing / Analysis: a multi-line document
  where each line is a referenceable expression, results appear in a
  right-hand column, and editing any line live-recomputes every
  downstream dependent. Every primitive already exists; this is a UI
  layer over the engine, not a new engine.
  - **V1 scope**: new `NotepadScreen` with a plain `TextField` per
    line (no inline LaTeX in input for V1). Right-column result
    rendered via `flutter_math_fork`. Lines evaluated via
    `EngineService` with 300 ms debounced live recalc + in-flight
    cancellation. Lines addressable as `line2`, `line3`, … (stable
    id under the hood; the alias resolves to whatever line is
    currently in that position) or by user-chosen name
    (`tax = 0.085`). Documents are sandboxed by default; an explicit
    `use name1, name2, ...` line at the top imports specific global
    variables / user-defined functions from `AppState` into the
    doc's scope. Drag handle on each row for reorder. Snackbar
    with Undo for delete-doc / delete-line.
  - **V2**: live dependency graph between lines so a single edit
    repaints only affected downstream cells (incremental recalc, not
    full-sheet re-eval). Inline-LaTeX input via `LatexController`
    once the layout has stabilized. Left-rail document list on wide
    screens (V1 ships with a `⋮`-menu doc switcher). `sembast`
    migration if storage-hardening item lands.
  - **V3**: cross-document references (`{doc:taxes}.line4`),
    PDF export of a doc, share-sheet integration (pairs with P4
    "Share / export"), document templates.
  - **Design decisions (V1 interview, 2026-05-25)** — captured to
    keep the Phases below consistent with the agreed surface:
    1. **Scope**: sandboxed by default; opt-in `use name1, name2,
       ...` line at the top of a doc imports specific globals.
    2. **Line addressing**: stable internal id; `lineN` is a
       display alias resolving to whatever is currently at
       position N.
    3. **Input rendering**: plain `TextField` per line for V1 (no
       inline LaTeX in input).
    4. **`Ans`**: result of the nearest non-blank line above;
       document-scoped (not the global calculator history).
    5. **Tab position**: after Calculator, before Graphing.
    6. **Doc switcher**: `⋮` menu in the AppBar (doc list + new
       doc + open Welcome sample).
    7. **First launch**: auto-create empty `Untitled` doc; ship a
       built-in `Welcome` sample doc accessible from the `⋮`
       menu and surfaced as a card in the onboarding tour.
    8. **Default doc name**: sequential — `Untitled`,
       `Untitled 2`, …
    9. **Recalc trigger**: 300 ms debounce on edit; cancel
       in-flight stale work via the existing isolate run-id
       mechanism.
    10. **Error chain**: when line N has an error, dependents
        render "Blocked by line N" with a tap-to-jump link
        instead of propagating the error or using stale values.
    11. **Result format**: always LaTeX via `flutter_math_fork`,
        plain-text fallback on parser error; long-press to copy
        as plain or as LaTeX (mirrors existing history affordance).
    12. **Empty result**: when input is blank the row collapses to
        a small height; no `—` placeholder.
    13. **Comments**: both `//` and `#` are accepted, stripped from
        first match to EOL.
    14. **Assignment**: single-identifier-LHS heuristic — `name =
        expr` with LHS matching `^[A-Za-z_][A-Za-z0-9_]*$` (and
        not a reserved CAS keyword) is an assignment; everything
        else (`x^2 = 4`, `sin(x) = 0`) is treated as a plain
        expression.
    15. **Undefined name**: a referenced name not in the doc's
        scope evaluates as a free symbolic variable (CAS default);
        the result row carries a small `free: x, y` tag so typos
        pop.
    16. **Line reorder**: drag handle on each row
        (`ReorderableListView`). Reordering only changes the
        meaning of positional aliases (`lineN`); explicit names
        follow the line.
    17. **Layout breakpoint**: 720 px (matches the existing nav
        breakpoint) — side-by-side at and above, stacked below.
    18. **Destructive actions**: snackbar with Undo (5 s timeout)
        for delete-doc, delete-line, clear-doc; no upfront
        dialogs.
    19. **Number format**: inherits the global
        `AppState.numberFormat`; no per-doc override in V1.
    20. **Import syntax**: `use name1, name2, ...` on its own
        line at the very top of a doc (must be the first
        non-blank, non-comment line); each imported name binds
        the global into the doc's scope.
  - **Why this first**: closes the single biggest 2026 gap and reuses
    every primitive we've already built. Notepad UX is what new users
    in the category now expect by default.
  - **Implementation plan (V1)** — 8 phases, each independently
    reviewable / mergeable. File references anchored to the
    current tree. Numbered design decisions referenced as **#N**.
    - **Phase 1 done 2026-05-25 (`feature/notepad-phase-1`).** New
      `lib/engine/notepad.dart` with `NotepadDocument { id, name,
      createdAt, updatedAt, lines: List<NotepadLine> }` and
      `NotepadLine { id, source, cachedResult, cachedError,
      cachedFreeVars }`. Both `toJson` / `fromJson` following the
      `CalculationEntry` pattern at
      `lib/engine/app_state.dart:43-56` (single-letter keys to keep
      the prefs blob small). Extend `AppState` with `Map<String,
      NotepadDocument> notepadDocuments` + `String?
      currentNotepadDocId`, `_kNotepadDocs` / `_kCurrentNotepadDoc`
      pref keys (alongside the existing keys at
      `app_state.dart:108-117`), load block patterned on the
      variables lifecycle (`app_state.dart:215-224`),
      `_persistNotepadDocs()` mirroring `_persistVariables()` at
      `app_state.dart:453-455`, and `setNotepadDocument(doc)` /
      `deleteNotepadDocument(id)` mirroring `setVariable(...)` at
      `app_state.dart:506-509`. Add keys to `exportToJson` /
      `importFromJson` at `app_state.dart:663-679`. Bundle a
      static `Welcome` sample doc as a constant in
      `lib/engine/notepad.dart` (one short version per locale,
      see Phase 8) — seeded on first launch alongside the
      auto-created empty `Untitled` per **#7**. **Done when**: an
      empty doc can be created, mutated, persisted, and
      round-tripped through Export → clipboard → Import; the
      Welcome doc appears after a fresh install.
    - **Phase 2 done 2026-05-25 (`feature/notepad-phase-1`).** New
      `lib/engine/notepad_evaluator.dart`. Per-line classification:
      `{blank, comment, useDirective, assignment, expression}`.
      Comment per **#13**: regex `^\s*(//|#)`; everything after the
      marker stripped to EOL. `use` directive per **#20**: matches
      `^\s*use\s+(...)$` *only if it is the first non-blank,
      non-comment line of the doc*; later occurrences are treated
      as plain expressions referencing an identifier called `use`.
      Assignment per **#14**: regex
      `^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$` on a not-reserved
      LHS (reserved list = CAS keywords from
      `expression_preprocessing_utils.dart` + `Ans`). LHS that
      doesn't match the strict identifier pattern (e.g. `x^2 = 4`)
      falls through to `expression` and is passed verbatim to the
      engine. Document-local `Map<String, String> scope` keyed by
      assignment names *or* auto-aliases (`line1`, `line2`, …); the
      `use` import populates the scope from
      `AppState.userVariables` and `AppState.userFunctions` at
      evaluation time. `String preprocessLine(NotepadLine line, Map
      scope)` substitutes scope names with cached results — same
      shape as `ExpressionPreprocessingUtils.substituteVariables`
      at `lib/utils/expression_preprocessing_utils.dart:159-175`.
      `Ans` per **#4** resolves to the cached result of the nearest
      non-blank line above the current line. **Done when**:
      unit-tested at `test/notepad_evaluator_test.dart` covering
      each line kind, the `use` first-line-only constraint, the
      assignment heuristic, scope substitution, and `Ans`
      resolution.
    - **Phase 3 done 2026-05-25 (`feature/notepad-phase-1`).** Same
      file. `Set<String> referencedNames(String preprocessed,
      Set<String> scopeKeys)` — regex `\b[A-Za-z_][A-Za-z0-9_]*\b`
      filtered against scope keys. Build a per-document DAG;
      topo-sort via Kahn's algorithm; evaluate in order via
      `EngineService.evaluateAsync(...)` at
      `lib/services/engine_service.dart:70-73`. `Future<void>
      evaluateAll(NotepadDocument)` + `Future<void>
      evaluateFrom(NotepadDocument, int lineIndex)` (recomputes the
      given line and every downstream dependent only). Cycle
      detection: every line in the cycle gets a structured error
      `circularReference(['a','b','a'])`. **Error-chain UX** per
      **#10**: when line N has an error, every downstream
      dependent's `cachedError` is set to `blockedBy(lineId: N.id,
      alias: "line5")` instead of being evaluated; the UI renders
      this as a tap-to-jump banner. Free variables per **#15**:
      `cachedFreeVars: Set<String>` = `referencedNames` minus
      `scopeKeys` — fed into the UI as the "free: x, y" tag.
      **Done when**: tests cover topo order, cycle detection,
      downstream-only invalidation, blocked-by propagation, and
      free-var tracking.
    - **Phase 4 done 2026-05-25 (`feature/notepad-phase-1`).** New
      `lib/screens/notepad_screen.dart`. `ReorderableListView` per
      **#16** of `_NotepadLineRow` widgets with drag handles on
      each row; each row = left plain `TextField` (no
      `LatexController` per **#3**) + right `Math.tex` result via
      `MathDisplayUtils.toHistoryDisplayLatex` (same pattern as
      `_buildExpressionDisplay` at
      `lib/screens/calculator_screen.dart:152-181`). Adaptive per
      **#17**: at `MediaQuery` width ≥ 720 px render side-by-side;
      below that stack the result under the input. Blank-input
      rows collapse to a small height per **#12** (no `—`
      placeholder). AppBar: document name (tap to rename inline),
      `+` action to append a line, `⋮` menu per **#6**: New doc
      (sequential name per **#8**), Open doc (sub-menu of existing
      docs), Open Welcome sample, Rename, Duplicate, Delete
      (snackbar-undo), Copy as Markdown. Wire into navigation
      shell at `lib/main.dart:192-226` per **#5** — insert
      `const int _kNotepad = 1;` and renumber the existing
      constants (`_kGraphing = 2`, `_kFunctionEditor = 3`,
      `_kAnalysis = 4`, `_kSettings = 5`); insert
      `NotepadScreen()` into `_screens` at index 1; insert the
      destination tuple at the matching position in
      `_destinations()`. First-launch behaviour per **#7**: if
      `AppState.notepadDocuments` is empty, seed one `Untitled`
      doc + the static `Welcome` sample (Welcome is recreated on
      reset; user can delete it and re-open it via the `⋮` menu).
      **Done when**: tab is visible across all breakpoints,
      add / delete / drag-reorder lines all work, doc switching
      via the `⋮` menu persists across relaunch, Welcome doc
      appears once on first launch.
    - **Phase 5 done 2026-05-25 (`main`).** Per **#9**: on every
      line edit, 300 ms debounce → `evaluateFrom(doc, lineIndex)`.
      Use `EngineService.cancelInFlight()` (`engine_service.dart:88`)
      when a fresh edit arrives while the previous run is still
      in flight; the worker's monotonic run-id (HISTORY round 56)
      drops the stale result. Per-row result widget states:
      `idle` (blank input → row collapsed per **#12**), `pending`
      (greyed previous result + tiny progress dot), `computed`
      (LaTeX via **#11** + long-press copy as plain or as LaTeX),
      `blocked` (renders the `blockedBy(...)` chip per **#10** with
      tap-to-scroll-to-line-N), `errored` (renders
      `EngineErrorFormatter.format(raw,
      AppLocalizations.of(context))` in the theme's error color —
      same affordance as `calculator_screen.dart:799-803`).
      Free-var tag per **#15**: when `cachedFreeVars` is
      non-empty, a small italic label `free: x, y` appears
      underneath the result. **Done when**: typing into a line
      updates the result within ~500 ms steady-state; rapid
      typing doesn't queue up stale evals; blocked-by chip jumps
      to the correct upstream line on tap; free-var tag updates
      as variables are defined / removed.
    - **Phase 6 done 2026-05-25 (`main`).** Unit syntax + scope-local assignments + `use`.
      Before the generic `evaluate` route, call
      `UnitExpressionEvaluator.tryEvaluate(preprocessed)` at
      `lib/engine/unit_expression.dart:50-198`; on non-null
      result use it, else fall through. Mirrors
      `calculator_screen.dart:745-753`. Assignment lines per
      **#1**: bind into the document-local scope only — **not**
      into `AppState.userVariables`. `use` line per **#20**, when
      present at doc top: extract the comma-separated identifier
      list, look each name up in `AppState.userVariables` *then*
      `AppState.userFunctions` (variable wins on collision);
      unknown imports flag the `use` line as `errored` with
      `unknownImport(name)`. Number formatting per **#19**: every
      result string passes through the existing
      `AppState.formatNumber(...)` so the global
      `NumberDisplayFormat` setting applies consistently.
      **Done when**: a doc containing `tax = 0.085` /
      `subtotal = 142.50` / `subtotal * (1 + tax)` produces the
      correct total; `5 km + 3 m` parses inline; two parallel
      docs don't leak variables; a doc with
      `use mygridsize` at the top reads the global
      `mygridsize` user variable; an unknown `use foo` flags the
      directive line as errored.
    - **Phase 7 done 2026-05-25 (`main`).** Export / Import + share single doc + snackbar
      undo.** Plumb `notepadDocuments` + `currentNotepadDocId`
      into the JSON shape at `app_state.dart:663-679`
      (forward-compatible: missing keys tolerated, same as
      existing fields). The static `Welcome` sample is excluded
      from export (always recreated from the constant in
      `lib/engine/notepad.dart`). Add a "Copy as Markdown" action
      to the AppBar `⋮` menu — emits one fenced block per line
      `source` with `// → result` comments. Snackbar-with-undo
      per **#18**: introduce a `_pendingDeletion` slot in
      `NotepadScreenState` holding the just-deleted entity (doc
      or line) for 5 seconds; the snackbar `Undo` action restores
      it. `share_plus` integration deferred to V2 (tracked under
      P4 → "Share / export"). **Done when**: a fresh install can
      import a doc previously exported on another device;
      delete-and-undo round-trips a doc or a line with no data
      loss.
    - **Phase 8 — Localization + onboarding + tests.** Add strings
      across en/de/fr/es in
      `lib/localization/app_localizations.dart`: tab name
      (`Notepad` / `Notizen` / `Notes` / `Notas`), default doc
      name (`Untitled` / `Unbenannt` / `Sans titre` / `Sin
      título`), Welcome sample doc body (one short version per
      locale — a 6-line sample covering an assignment, a unit
      expression, an `Ans`, and a comment), empty-state hint,
      and the new error / chrome keys (`blockedByLine`,
      `circularReference`, `useDirectiveNotFirst`, `unknownImport`,
      `freeVariables`, `restored`, `undo`, `copyAsMarkdown`,
      `renameDocument`, `openWelcomeSample`). The existing locale
      non-emptiness test will fail CI if any locale is missed.
      Extend `OnboardingTour`
      (`lib/widgets/onboarding_tour.dart`) per **#7** with a
      5th card describing the Notepad and pointing the user to
      the Welcome sample. New `test/notepad_evaluator_test.dart`
      (parser, scope, cycle, topo, `use` handling, blocked-by
      propagation) and `test/notepad_screen_test.dart` (build,
      add line, drag-reorder, edit + debounce + result, snackbar
      undo). **Done when**: locale tests + unit tests + widget
      tests all green; manual smoke on macOS confirms the doc
      loads after relaunch and the Welcome doc renders.
  - **Out of scope for V1** (push to V2 / V3): incremental
    subgraph recalc (V1 just re-evals from the edited line down,
    full DAG walk, which is fine for docs up to a few hundred
    lines); inline-LaTeX input via `LatexController` (V2);
    left-rail document list on wide screens (V1 uses the `⋮`
    menu); cross-document references (`{doc:taxes}.line4`); PDF
    export of a doc; rich-text formatting / headings within a
    doc; collaborative editing; per-doc number-format override.

- [ ] **AI copilot — verifier-frontend, never solver**. The defining
  property: every numeric or symbolic answer continues to come from
  SymEngine / the step engine; the LLM is restricted to three jobs.
  Pluggable provider (Claude / OpenAI / on-device Apple Foundation
  Models on iOS 18+); user supplies key in Settings; opt-in only;
  expressions sent only on explicit user action; key stored locally.
  - **Job 1 — Translate**: natural language → engine syntax.
    *"integrate x squared from 0 to 1"* → `integrate(x^2, x, 0, 1)`.
    Single button on the calculator + notepad input field; round-trips
    through the engine so the user sees the translated syntax before
    evaluation. Failures fall through to the existing parser (no silent
    acceptance of LLM output).
  - **Job 2 — Narrate**: turn the deterministic step trace from
    `step_engine.dart` into prose. Today each step has a `StepNote`
    with a one-sentence localized explanation; the LLM upgrades this
    to a paragraph that *connects* steps ("we apply the chain rule
    here because the inner function is itself a power"). The formal
    formula + before/after row remains the source of truth.
  - **Job 3 — Explain**: an "Explain this result" button on history
    rows and notepad result cells. Takes the input expression + the
    engine's answer and produces a plain-language interpretation
    ("the area under the curve from 0 to 1 is exactly 1/3 square
    units"). Optional; off by default.
  - **Hard guardrail**: the LLM is never asked "what's the answer." It
    only sees expressions and engine-produced results. The About screen
    should state this verbatim — it's the positioning: *"CrispCalc
    uses AI to read your input and explain the answer. It never uses
    AI to compute the answer."*
  - **V1 scope**: Job 1 only. Cloud provider (Claude default). Setting
    toggle + API-key field. One button on the input field labelled
    "Interpret".
  - **V2**: Job 2 + Job 3. Streaming UI for narrated steps.
  - **V3**: on-device translation via Apple Foundation Models on
    iOS 18+ / macOS 15+ so the basic translator works offline and
    without an API key on Apple platforms. Falls back to cloud provider
    elsewhere.
  - **Audit log**: each LLM call logged locally (opt-in viewer in
    Settings) so the user can see what was sent and what came back —
    helpful for debugging and load-bearing for the privacy story.
  - **Why this second**: notepad mode is more valuable when the input
    field accepts prose. But notepad ships first because it's useful
    on its own (with typed math) and validates the surface before AI
    multiplies its leverage.

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

- [~] **Worked-example library**. Curated catalogue of problem types
  (related rates, optimization, vector projection, eigenvalue) with
  click-to-try examples. Discoverability + learning.
  - **V1 partial** (HISTORY round 54): 21 entries spanning calculus,
    algebra, linear algebra, number theory, statistics, and inline
    unit syntax. New `WorkedExamplesDialog` reachable from
    Settings — category-chip + substring filter; tap row or copy
    icon to push the expression to the clipboard. Dialog chrome is
    fully localized; example titles + descriptions are
    English-only for V1 (translating every example body across 4
    locales is a separate i18n chunk).
  - **V2 partial** (HISTORY round 58): direct insertion via a new
    `AppState.requestInsertExpression` slot — the dialog's tap or
    Insert button pushes the expression there, MainScreen routes to
    the Calculator tab, and the calculator drains the slot on its
    listener. Catalog grew an `id` field per entry;
    `AppLocalizations.workedExampleTitle(id)` /
    `workedExampleDescription(id)` provide translated text per
    locale, falling back to the English fields when null. All 21
    entries translated to DE/FR/ES.
    **V3 pending**: advanced topics (related rates, eigenvalue,
    multivariable, parametric); a way to wire the example back to
    its step-by-step trace dialog when applicable.
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
  **Strategic promotion (2026 reset)**: slots into the AI copilot's
  Job 1 (Translate) — OCR converts image to text, the LLM translates
  that text to engine syntax. Ship after AI copilot V1 so the
  translation pipeline is already proven on typed input.
- [ ] **Pen / handwriting input**. Apple Pencil + macOS trackpad
  handwriting recognition (`PKCanvasView` + `MLHandwritingRecognizer`)
  for math expressions. iPad specifically — closes the parity gap
  with platform-bundled handwriting solvers. **Strategic note (2026
  reset)**: Apple's on-device
  handwriting recognizer is free, latency-friendly, and doesn't need
  an LLM round-trip. Ship as the iPad input modality for the notepad
  surface — the killer combo is "write the equation by hand, see it
  solve in the right column, optionally ask the AI to explain the
  answer." Treat as iPad/Mac-only; Android can fall through to typed
  input until a parity recognizer is identified.

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

#### Constraint Satisfaction Problems (dart_csp integration)

CrispCalc's existing `solve()` is symbolic — it returns parametric
solutions or closed-form roots. There's a whole class of math problems
it can't touch: Diophantine equations with bounded integer variables
(`2x + 3y = 100, x,y ≥ 0`), number-theory puzzles
("smallest n where n, n+2, n+6 are all prime"), cryptarithms
(SEND + MORE = MONEY), Sudoku, magic squares, scheduling. These all
share the same underlying model: variables with finite domains, a set
of constraints, find any/all assignments that satisfy them.

The user's `dart_csp` library (MIT, pure Dart) is a mature CSP solver
— backtracking with AC-3 / GAC, MRV / LCV / dom-wdeg, min-conflicts,
branch-and-bound optimization, reified constraints, global constraints
(`allDifferent`, `gcc`, `circuit`, `cumulative`, …), a string
constraint parser, set variables, soft constraints. Pure Dart, zero
native deps — fits the bridge-free side of the engine layer cleanly.

Roadmap (ship one round at a time):

- [x] ~~**CSP Round A — Diophantine + cryptarithm module**.~~
  Done 2026-05-24 — see HISTORY round 59. `dart_csp` pinned at
  commit `7a05fe5` in pubspec. New `lib/engine/csp_solver.dart`
  exposes two static methods (`solveDiophantine`,
  `solveCryptarithm`) wrapping the dart_csp Problem API; a small
  `_tryParseLinear` pre-pass routes coefficient-bearing forms like
  `2*x + 3*y == 12` through `addLinearEquals` (the string parser
  stumbles on them). New `ConstraintsScreen` is the seventh
  Analysis-hub module; two tabs (Diophantine + Cryptarithm) with
  textarea inputs and a copyable result block. Chrome localized
  en/de/fr/es; example entries in the worked-examples catalog
  deferred to V2 (would need a way to navigate into the
  Constraints screen rather than the calculator).

- [x] ~~**CSP Round B — Sudoku module**.~~ Done 2026-05-24 — see
  HISTORY round 60. Solver wraps dart_csp; new `SudokuGenerator`
  uses `hasMultipleSolutions()` for uniqueness-preserving clue
  peeling. Visualizer captures every search step into a list and
  replays at user-controlled speed. UI: preset picker, generator
  row (easy/med/hard chips + Generate), digit pad, Solve button,
  play/pause/restart/speed/scrub controls. Round-trip test
  (generate → solve → validate) covers both layouts × all
  difficulties × multiple seeds.
  - **V1 scope shipped**: 4×4 (2×2 boxes) and 9×9 (3×3 boxes).
    Visualizer captures every step into a list and replays at
    Slow / Med / Fast.
  - **V2 shipped** (HISTORY round 61): 6×6 (2×3 boxes) and 16×16
    (4×4 boxes) layouts added, plus a **Sudoku-X variant**
    (allDifferent overlay on both diagonals). Screen gains a
    Size chip-row (4×4 / 6×6 / 9×9 / 16×16) and a
    Regular / Sudoku-X segmented picker; switching either wipes
    the grid so the user can re-enter or hit Generate. New 6×6
    preset peeled from a verified canonical grid; no X preset
    ships (standard off-the-shelf puzzles fail the X constraint
    — users get X puzzles via Generate). Round-trip test covers
    6×6 + Sudoku-X.
  - **V3 partial — variant roadmap**. Sudoku is a family, not one
    puzzle. Standard sizes alone span 4..25 with mixed
    aspect-ratio boxes:
    - 6×6 (2×3 boxes) shipped round 61. ~~8×8 (2×4)~~ shipped
      round 75. 10×10 (2×5), 12×12 (2×6 or 3×4), 15×15 (3×5),
      16×16 (4×4) ✓ also shipped round 61, 25×25 (5×5) still
      open — each needs a clue library and validated minimum-clue
      counts (Wikipedia ranges from 4 clues for 4×4 to 55 for
      16×16; 25×25 lower bound is open).
    - Irregular regions ("Du-sum-oh"/Geometry Number Place) —
      boxes are arbitrary same-size polyomino tilings, not the
      regular grid. Still pending.
    - ~~Killer / Samunampure — boxes replaced by sum constraints
      over irregular regions. Maps naturally to dart_csp's
      `addLinearEquals` over per-cage cell sets.~~ **SHIPPED**
      in HISTORY round 63 (4×4 preset, no givens, full overlay).
      Generator + larger Killer presets are V2.
    - Other variants: ~~Sudoku-X~~ shipped round 61. ~~Disjoint
      Groups~~ shipped round 76. Hypercube / NRC / 2-Quasi-Magic
      still open — each reduces to additional `allDifferent`
      overlays.
  - **V3 partial** (HISTORY round 62): **hint mode / pencil-marks**
    shipped. `SudokuSolver.computeCandidates(puzzle)` returns one
    `Set<int>` per cell (legal digits after naive
    row/column/box/diagonal exclusion). Grid widget renders the
    candidates as a small sub-grid of dimmed digits in each empty
    cell. Screen has a "Show hints" toggle that recomputes on
    every edit. Works on all four layouts (4×4 / 6×6 / 9×9 /
    16×16) and respects the Sudoku-X overlay.
  - **V4 — advanced hints** done 2026-05-25 (HISTORY round 73).
    `SudokuHintLevel` now has three positions (off / basic /
    advanced); advanced runs `computeCandidatesPruned` which does
    singleton arc consistency by probing — each (cell, candidate)
    is verified by the full dart_csp solver, catching hidden
    singles + naked pairs that naive elimination misses. Request-id
    cancellation handles in-flight staleness across fast edits.
  - **V5 — uniqueness chip** done 2026-05-25 (HISTORY round 65,
    pre-session). "Check uniqueness" button + chip on the Sudoku
    screen reports "Unique solution" / "Multiple solutions".
  - **V6 — 8×8 + Disjoint Groups** done 2026-05-25 (HISTORY rounds
    75 + 76 + 82). `SudokuLayout.eight` (2×4 boxes) with a 28-clue
    medium preset; `SudokuVariant.disjoint` with the in-box-position
    `_disjointGroups` walker. Both pick up the parameterized
    engine cleanly. Round 82 closed the variant coverage with
    `eight8x8X`, `eight8x8Disjoint`, and `eight8x8Killer` presets
    so the variant picker has a curated puzzle for every
    8×8 variant.
    **V7 SHIPPED** in HISTORY round 81: step-trace
    *constraint-context* annotations. Each visualizer frame now
    names the row / column / box / cage / diagonal /
    disjoint-group `allDifferent` overlays the just-assigned cell
    sits in (Killer also names the cage sum). The original
    framing — "which constraint *fired*" — requires constraint
    identity on the dart_csp propagation callback wire, which
    isn't there today; the context approach gives users
    deterministic per-frame narration without a dart_csp change.
    Future tightening: expose firing-constraint identity through
    dart_csp and wire it into the same caption surface.

- ~~**CSP Round C — Generic constraint mini-DSL**.~~ **V1 SHIPPED**
  in HISTORY round 68. A "Free-form" tab in the Constraints module
  accepts the documented DSL (`vars: x, y in 1..9` + `allDifferent`
  + string-form constraints) and surfaces solutions in the
  Diophantine result-block. V2: trace mode, worked-example
  entries for N-queens / magic-square / map-coloring / scheduling.

- [x] ~~**CSP Round D — Optimization in the DSL**.~~ Done 2026-05-25 —
  see HISTORY round 74. `minimize` / `maximize` directives parsed
  out of the DSL, routed through dart_csp's branch-and-bound via a
  synthetic `__obj__` variable with tight integer bounds. New
  `DiophantineResult.optimal` factory carries the singleton optimum
  plus the proven objective value; `_ResultBlock` UI swaps the
  "N solutions" header for "Optimal: objective = N" when present.
  Coin-change gallery entry demonstrates the canonical least-coins
  problem.

- [x] ~~**CSP Round E — Scheduling (noOverlap + cumulative)**.~~ Done
  2026-05-25 — see HISTORY rounds 77 + 78 + 80.
  `noOverlap(s1=4, s2=3, s3=2)` syntax parses into a
  `NoOverlapGroup` and routes to `Problem.addNoOverlap` (cumulative
  time-table propagator under capacity 1, all heights 1). Composes
  with `minimize` for the single-machine-makespan classic. Round
  78 closed the loop by extending the linear-expression parser to
  accept expressions on both sides of the comparator (`s + d <=
  makespan` is the natural form now). Round 80 added the
  renewable-resource generalization:
  `cumulative(s1=2@2, s2=3@1; capacity=2)` for variable per-task
  demands and an integer capacity — routes to
  `Problem.addCumulative` and shipped with the
  `cumulativeScheduling` gallery + discovery entries.

##### CSP Round D — what's still untapped in dart_csp (May 2026 audit)

`dart_csp` v2.1.0 (ref `e3cce21`) is a *mature* solver — far
more capability than we surface today. The audit below pins
seven candidates, ranked by user-visible impact ÷ effort.
Pure-Dart, zero native deps for all of them. Each item slots
into the existing `ConstraintsScreen` Analysis-hub module or
extends the Sudoku/CSP engine layer directly.

- [ ] **Schedule Gantt renderer** for `noOverlap` / `cumulative`
  output (high impact / small effort — *recommended first*).
  The DSL-tab gallery already produces correct `noOverlap` /
  `cumulative` solutions, but results render as raw text:
  ```
  s1 = 0
  s2 = 4
  s3 = 7
  ```
  A `CustomPainter`-based Gantt chart would 10× the
  legibility: each task drawn as a horizontal bar at its
  start-time with width = duration, colored per resource. For
  `cumulative` problems the bars stack by demand. ~Half a day;
  no engine changes. Doubles as the visual hook the
  worked-examples catalog can point users at.

- [ ] **Optimization tab — LP / IP via `minimize` / `maximize`**
  (big impact / medium effort — *strategically biggest win*).
  Branch-and-bound is genuinely rare in consumer calculator
  apps — Mathematica has it, TI / Casio / Soulver / Numi
  don't. dart_csp ships it for free via `Problem.minimize` /
  `Problem.maximize` with an objective expression. UX: a new
  4th tab in `ConstraintsScreen` (Optimize). User types
  variables + bounds + linear constraints + objective; result
  is the optimal assignment + objective value. Gallery
  entries: production planning (mix of products under
  resource caps), knapsack (max value under weight cap),
  assignment (min cost matrix), transportation (min cost
  shipping). ~1–2 days.

- [ ] **Graph / map coloring puzzles** (high pedagogy / small).
  Classic CSP — `allDifferent` between adjacent regions over
  a small color domain. New gallery entry in the DSL tab with
  a pre-built adjacency list (e.g. Australian states, US
  Midwest, Germany Bundesländer). Bonus: a `CustomPainter`
  region map colored from the solution. ~1 day with the
  visualizer, ~half a day text-only.

- [ ] **Magic squares generator** (curiosity / small). 3×3
  through 6×6 magic squares via `allDifferent` + per-row /
  per-column / per-diagonal `exactSum(targetMagicNumber)`.
  New gallery entry. Reuses the existing DSL parser
  surface — just a different program template. ~Half a day.
  Bonus: the magic-constant input is auto-computed for
  square N as `N(N²+1)/2` (default unless overridden).

- [ ] **Set partitioning ("equal-sum split")** (small).
  Common interview / pedagogy problem — given a list of
  numbers, split them into K groups of equal sum. Variables
  are per-number group assignments (domain `0..K-1`);
  constraint is `exactSum(totalSum/K)` per group. Gallery
  entry. ~Half a day.

- [ ] **Step-trace visualization of AC-3 propagation** (large
  / pedagogy gold). Instrument `dart_csp`'s solver to emit
  propagation steps (variable domain shrinks, constraint
  firings) and render them as a step-by-step replay in the
  DSL tab. Would be a *genuinely unique* feature among
  calculator apps. Requires an upstream solver patch to
  expose propagation events. ~3–5 days end-to-end.

- [ ] **CBJ-aware "explain failure" mode** (power-user /
  medium). The newest dart_csp commit (`e3cce21`) added
  conflict-directed backjumping — when a problem is
  unsatisfiable, the solver knows *which subset of constraints*
  caused the dead-end. Surface that as a "Why no solution?"
  affordance on the result panel: when the DSL produces no
  solution, the screen shows the minimal conflicting subset
  instead of just "No solution found". ~2 days incl. UX
  iteration.

##### CSP Round E — FlatZinc frontend + MUS (May 2026 dart_csp HEAD)

The pinned `dart_csp` (`e3cce21`, May 25) lags by ~15 commits behind
the upstream HEAD which has landed two major features:

1. **FlatZinc frontend** (`8520461`) — a drop-in parser + lowering
   + runner for the FlatZinc format that MiniZinc compiles to.
   Every major constraint-programming solver (Choco, Gecode,
   Chuffed, OR-Tools, JaCoP) integrates at the FlatZinc level, so
   any `.mzn` model in existence becomes runnable on dart_csp via
   `mzn2fzn`. Ships with a `dart_csp_fzn` CLI binary and an
   `.msc` solver-config snippet so dart_csp can register as a
   MiniZinc backend.
2. **QuickXplain MUS** (`66b1a31` + `47beb59` + `a483980`) — Junker
   2004 minimal-unsatisfiable-subset extraction, with per-call
   constraint labels (`ConstraintRef`) so MUS output reads like
   "rows-distinct, columns-distinct, killer-cage-A clash" rather
   than internal constraint indices. The piece that turns the
   PLAN's Round-D `cbjExplain` item into a real feature.

###### Prerequisite — bump the dart_csp pin

- [x] ~~**Bump pubspec `dart_csp.ref:` from `e3cce21` to a HEAD SHA**
  carrying both features.~~ Done 2026-05-26 — bumped to `69a9cfb`
  (commit `2ca864f`). The full 1708-test suite was green against
  the new pin, no API drift to the existing csp_solver / sudoku
  wrappers.

###### CSP Round E — what to ship on top

- [x] ~~**Round E.1 — "Paste FlatZinc" tab** in `ConstraintsScreen`.~~
  Done 2026-05-26 — commit `e853874`. New 4th tab; textarea +
  Solve button + `All solutions` FilterChip + 2-entry gallery
  (NQueens-4 with diagonal `int_lin_ne` pairs, Bin-packing via
  `bin_packing_load`). Result block renders the standard FlatZinc
  output text; header switches between "First solution" /
  "N solutions (exhaustive)" / "Unsatisfiable" by inspecting the
  trailer. Localized en/de/fr/es (7 new chrome keys + 2 gallery
  titles). `test/flatzinc_tab_test.dart` locks both gallery
  snippets through `FlatZinc.solve` plus the exhaustive / unsat
  output shapes (4 tests).

- [x] ~~**Round E.2 — "Why no solution?" panel using QuickXplain
  MUS**.~~ Done 2026-05-26 — commit `79a1067`. Four new explain
  methods on `CspSolver` (`explainDiophantine` / `explainDsl` /
  `explainCryptarithm` / `explainFlatZinc`) rebuild the Problem
  with `label:` threaded through every add* call, then run
  `findMinimalUnsatisfiableSubsetQuickXplain`. Shared
  `_ExplainSection` widget renders an "Explain failure" button on
  every tab when its solve returns 0 solutions /
  `=====UNSATISFIABLE=====` / "No assignment satisfies"; tap
  reveals the MUS as one row per labeled conflict with a
  constraint-kind chip. Localized en/de/fr/es (4 new keys). 12
  new tests in `test/csp_mus_test.dart`. Engine refactor is
  purely additive — happy-path solvers untouched.

- [x] ~~**Round E.3 — DSL → FlatZinc export**.~~ Done 2026-05-26 —
  commit `991f764`. New `DslToFlatZinc.export(input)` produces a
  ready-to-paste FlatZinc model from any DSL program (vars /
  allDifferent / linear ==/<=/>=/</>/!= / noOverlap →
  disjunctive / cumulative / minimize / maximize via synthetic
  __obj__). "Export as FlatZinc" button on the DSL tab; result
  lands in a copyable `_FlatZincExportBlock`. Non-linear
  constraints fail with a friendly "not a linear constraint"
  error rather than producing a partial model. Localized
  en/de/fr/es (2 new keys). 20 new tests in
  `test/dsl_to_flatzinc_test.dart` — 12 structural shape checks,
  5 error paths, and 3 **round-trip** tests that feed the emitted
  FlatZinc back through `FlatZinc.solve` to prove the translation
  is parseable + solvable.

- [~] **Round E.4 — Notepad ↔ FlatZinc integration** *(novel)*.
  Inline `fzn:` directive variant shipped 2026-05-26 (commit
  `d90280b`). A notepad line whose source starts with `fzn:`
  (with optional leading whitespace) treats everything after the
  colon as FlatZinc source. The TextField's `maxLines: null` lets
  one NotepadLine carry multi-line FlatZinc — natural fit, no
  multi-line cell model needed for V1. Result lands in a
  monospace block (rendered by a new `_buildFlatZincResult`);
  scalar `output_var` bindings populate the new
  `NotepadLine.cachedExports` map which `buildNotepadScope`
  merges into doc scope, so downstream lines can reference
  solved values by their FlatZinc names. Output_array values stay
  in the formatted result text but don't enter scope (no clean
  scalar mapping). Unsatisfiable models error the fzn line and
  block dependents via the standard `blockedBy` chip. Tests:
  `test/notepad_flatzinc_test.dart` — 18 cases covering classify,
  the helpers, evaluator with a stub dispatcher, and one
  end-to-end through real `FlatZinc.solve`.

  - **Constraint-block as a multi-line cell** *(deferred V2)*.
    Extend the line model to support multi-line cells (one
    cell containing the whole `.fzn` source) with a header
    `// CSP block`. The V1 inline variant already supports
    multi-line bodies via `maxLines: null`, so the V2 cell
    model is no longer urgent — would be a structural change
    for prettier separation of CSP cells from regular notepad
    lines (toolbar, fold/unfold, etc.).

  - **Why this matters strategically** — calculator apps don't
    do constraint problems. Notebooks don't ship a CAS *and*
    constraint solver in the same surface. The combo isn't a
    polished feature elsewhere; landing it gives CrispCalc a
    defensible "what is this app even" answer for discovery.

- [ ] **Round E.5 — Bundle `dart_csp_fzn` as a MiniZinc solver**.
  Distribution play: ship the compiled CLI + `.msc` config in
  the macOS/Linux app bundles so MiniZinc Challenge entrants
  can register CrispCalc's solver from their existing MiniZinc
  setups. Niche but visible to the CP community. Requires the
  P4 distribution pipeline (Apple Developer enrollment +
  notarization) to land first. Deferred until P4 unblocks.

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

## P6 — Discoverability + help system overhaul (May 2026)

CrispCalc now has five distinct *floors*: Calculator, Notepad,
Graphing, Functions (user-defined), and Analyze (the hub with 9
modules). Each grew independently. The result is a feature-
rich CAS where **most users never find half the features** —
worked examples are buried in Settings, function references
don't exist at all, and the precision-arc work in rounds 85-90
(seven new MPFR/ntheory functions) can only be reached by Dart
code, not from the UI. This section lays out the recovery.

### Current information architecture (the problem)

Where things live today, and the gaps:

| Surface | What's there | What's buried / missing |
|---|---|---|
| **Calculator** | Keypad (Basic / Adv), LaTeX input, history, Settings sheet | Precision functions unreachable. History results give no explanation. No on-demand help on operators. |
| **Notepad** | Document-style scratch with live recalc (Phase 1-8 in progress) | Same: precision functions, no help on operators, no operator/result explanations. |
| **Graphing** | 2D + 3D plots, annotations | No tutorial path for "how do I plot a piecewise?" or "what are the annotation toggles?" |
| **Functions (user-defined)** | Slot-based UDF editor in Settings | No documentation of what syntax is supported. |
| **Analyze (hub)** | 9 module cards | Modules each have their own help-or-not. No cross-module discovery. |
| **Settings** | Locale, theme, number format, **worked examples library**, **import/export**, **about** | "Worked examples" buried here — wrong place; users go to Settings to *configure*, not to *learn*. "Funktionsreferenz" doesn't exist anywhere. |

### The five strategic adds

1. **Move "Worked examples" out of Settings.** Make it a
   first-class surface accessible from a top-of-screen `(?)`
   icon on the Calculator and Notepad. Same dialog content
   today — it's purely a location move. Keep a soft link in
   Settings so old habits don't break, but the *primary*
   entrance is from the surfaces where the user actually does
   math.

2. **New top-level Function Reference.** A dedicated dialog +
   route that catalogs every function/operator CrispCalc
   supports: `solve`, `expand`, `simplify`, `diff`, `integrate`,
   `factor`, `rref`, `pi(N)`, `factorint`, `isprime`, etc.
   Each entry: signature, one-sentence what-it-does, 2-3
   worked examples with expected output, and a *deep link*
   into the calculator that inserts the example. Searchable.

3. **Help (?) overlay system across the app.** Every screen
   gets a `(?)` button in the AppBar. Tapping toggles "help
   mode": cells / buttons / history rows / notepad lines
   render with a subtle blue dotted outline and reveal a
   tooltip + tap-to-expand modal explaining what they are and
   how they work. Tap `(?)` again to exit.

4. **Precision-arc + ntheory surfacing.** Round-85/86/89/90
   wrappers (`pi(N)`, `e(N)`, `EulerGamma(N)`, `sqrt(2,N)`,
   `isprime(n)`, `nextprime(n)`, `prevprime(n)`,
   `factorint(n)`) become first-class user-facing functions in
   Calculator + Notepad parsers, with Adv-keypad buttons, and
   discovery via #1 and #2.

5. **Cross-surface result explanation.** Long-press / right-
   click on any history row in Calculator or any line in
   Notepad opens a "How was this computed?" modal that names
   the engine call(s) used (`SymEngine.solve` / `MPFR.evalf` /
   `FLINT.fmpz_factor` / `dart_csp.getSolutions` / …), with a
   short trace where the engine surfaces one (e.g. solve
   steps, integration steps, Sudoku trace replay).

### Round-by-round plan (rounds 91-105)

Each round is single-session, shippable independently, and
testable in CI. The plan is conservative — each round delivers
visible user value rather than chunks of plumbing.

#### Rounds 91-92: Precision-arc surfacing (the low-hanging fruit)

##### Round 91 — Calculator parser binds precision arc ✅

Done 2026-05-26 — commit `c8ccd6c`. New
`CalculatorEngine.tryEvaluatePrecisionCall(input)` returns the
result for a recognized standalone precision-arc call or `null`
to fall through. Top-level only (in-expression calls left to the
existing preprocessor + SymEngine, since substituting `'true'` /
Unicode-superscript strings mid-expression doesn't always make
algebraic sense).

Hooks: `calculator_screen.dart` `_calculate` and
`notepad_screen.dart` `_dispatcher`, both before the unit
evaluator (since `e(50)` would otherwise tokenize as the bare
symbol `e`). NotepadScreenState gains a main-isolate
`CalculatorEngine` purely for this pre-pass; heavy CAS calls
still route through `EngineService`.

factorint formats with Unicode superscript digits + `·`
separators (`factorint(360) → 2³ · 3² · 5`). Empty result
(n ∈ {0, ±1}) returns the original input verbatim.

18 new tests in `test/precision_call_pass_test.dart` covering
dispatch, non-matches, error paths, and the formatter. Full
suite: 1780 pass.

##### Round 92 — Adv keypad buttons + worked-examples entries ✅

Done 2026-05-26 — commit `c53bb2c`. Seven new Adv-tab keys
(π(N), e(N), γ(N), √(2,N), nextprime, prevprime, factorint) added
to `_advKeys` + dispatch cases in `calculator_screen.dart`. The
existing `prime` button continues to handle isprime, so the eighth
function is already covered. Each new key inserts a template with
the cursor positioned between the parens.

Five new `WorkedExample` entries in the numberTheory category:
`piPrecision` (π to 100 digits), `ePrecision` (e to 50 digits),
`factorint360` (prime factorization → Unicode superscript demo),
`nextprime1000`, `mersenneM31` (factorint(2^31 - 1) shows the
eighth Mersenne prime as a single factor). Titles + descriptions
localized en/de/fr/es; the catalog cap test was raised 30 → 40
to fit the new batch. Full suite: 1810 pass.

Folded into the existing `numberTheory` category rather than
introducing a separate `precision` category — keeps the dialog's
category-chip row compact.

#### Rounds 93-95: Move worked examples out of Settings

##### Round 93 — Add (?) icon + lift dialog to Calculator + Notepad ✅

Both surfaces now carry an open-book `(menu_book_outlined)`
IconButton that opens the existing `WorkedExamplesDialog`. On
the Notepad it slots into the AppBar `actions:` row ahead of
the existing `+` and `⋮` buttons. The Calculator has no AppBar
of its own, so the icon lives in the same top toolbar row that
used to host only the LaTeX/Plain toggle + history search + clear.
That toolbar was previously hidden when history was empty —
now it always renders so the icon stays reachable from a cold
start, with the history controls still gated on
`history.isNotEmpty`.

The Settings entry stays but its subtitle now points at the
new icon, in all four locales.

Used the open-book glyph rather than `Icons.help_outline`
because the latter is reserved for the future Round 101
help-mode toggle, and an open book matches the Settings card's
own `menu_book_outlined` leading icon — users can mentally
connect the two.

##### Round 94 — Pre-filter the dialog by the active surface ✅

`WorkedExamplesDialog` gained a `surface:
WorkedExamplesSurface` parameter (defaults to `calculator` so
the existing call site from Settings keeps full-library
behaviour). The Notepad call site passes `notepad`, which
restricts both the category-chip row and the example list to
`{calculus, algebra, linearAlgebra, numberTheory}`. The three
module-bound categories (statistics — has its own data-table
UI; units — V1 PLAN scopes notepad to math content;
constraints — entries are `open:` / `dsl:` sentinels that
navigate to a different module) disappear from the chip row.

The PLAN's original spec called for `{calculus, algebra,
linearAlgebra}` only; `numberTheory` was added because P7's
boolean predicates + the precision arc both ship entries that
work fine inline in a notepad line (`isprime(2027)`,
`2 == 2`), and hiding them would be a regression.

##### Round 95 — Examples open the right module ✅

The deferred carve-out from earlier in the day shipped after
93+94. Implementation plumbs through four pieces:

- **AppState** gains two pending slots —
  `_pendingSudokuPresetId` and `_pendingStatisticsTab` — each
  with `request*`/`consume*` methods that mirror the round-73
  `_pendingDslProgramId` shape.
- **`WorkedExamplesDialog._insert`** parses
  `open:<module>?key=value` (the `?` separator is new; the
  bare `open:<module>` form still works). Recognised pairs:
  `?preset=<id>` for sudoku, `?tab=<id>` for statistics.
  Unknown keys are silently ignored so the module still opens.
- **`SudokuScreen.initState`** drains
  `pendingSudokuPresetId`, finds the matching entry in
  `SudokuPresets.all`, and overwrites the field initialisers
  for `_puzzle`, `_baseCells`, `_clueIndexes`, `_displayed`
  before the first build. Unknown ids degrade to the default
  `standard9x9Easy`.
- **`StatisticsScreen.initState`** drains
  `pendingStatisticsTab` and sets `_tabs.index` from
  `descriptive`/`regression`/`distributions`/`tests`. V1 stops
  at tab-pick — pre-filling the input fields is a future
  extension once a real demand for it shows up.

Catalog changes:

- **`killerSudoku`** upgraded from `open:sudoku` to
  `open:sudoku?preset=killer9x9` (so the puzzle is pre-loaded
  instead of requiring the user to pick it from the dropdown).
  Description updated in en/de/fr/es.
- New **`statsHypothesisTests`** entry pointing at
  `open:statistics?tab=tests` — lands the user on the Tests
  tab (the deepest tab, with sub-tabs of its own). Localized
  across en/de/fr/es.

44 worked examples now; cap test stays at 50.

Suite 1911 → 1931 (+6 AppState slot tests, +8 receiver/dispatch
tests in `round_95_pre_load_test.dart`, +6 reshuffled passes
from sudoku/statistics initState additions surfacing existing
test counts).

#### Rounds 96-100: Function Reference surface

##### Round 96 — Data model + scaffolding ✅

Shipped. `lib/engine/function_reference.dart` carries the
`FunctionRef` / `FunctionRefCategory` / `FunctionRefExample`
trio plus a 3-entry seed list (`solve` / `isprime` /
`pi_precision`) chosen to validate the full
catalogue → dialog → tests pipeline before Round 97 grows
it. Categories follow the PLAN spec exactly (9 values).

The `FunctionRef` model has one addition over the PLAN
sketch: a `workedExampleId: String?` field. PLAN's "See
worked example" cross-link needed a way to refer to a
worked-examples entry, and an id pointer is the smallest
unit that does the job. The dialog looks it up in
`WorkedExamples.all` and only renders the button when the
id resolves; a future round can grow this to a structured
cross-link without touching the schema.

`lib/widgets/function_reference_dialog.dart` mirrors
`WorkedExamplesDialog` (search field, category-chip row,
scrollable list) but each row is an `ExpansionTile` rather
than a plain ListTile. Tapping expands inline to show the
2–3 examples + see-also pill row + action buttons ("Try in
Calculator" and "See worked example"). "Try in Calculator"
uses the existing `AppState.requestInsertExpression` slot —
same path the worked-examples dialog uses for non-sentinel
expressions.

V1 keeps detail inline (ExpansionTile) rather than a side-
by-side master / detail layout because the dialog content
is 560×480; splitting it would leave both columns cramped
on the narrow breakpoint.

Reach-point: a Settings tile (`Icons.functions` leading) for
Round 96. Round 101's help-mode toggle will surface the
dialog inline from Calculator + Notepad.

Localization: 11 new strings (title / search hint / empty /
see also / two button labels / one settings tile + subtitle
/ each + 9 category labels) shipped across en/de/fr/es.

Suite 1931 → 1944 (+7 catalogue invariants in
`function_reference_test.dart`, +6 dialog widget tests in
`function_reference_dialog_test.dart`).

###### Round 96 follow-up: `initialSearch` cross-link ✅

Shipped immediately after Round 96 lands. The original V1
cross-link in `FunctionReferenceDialog._openWorkedExample`
just opened `WorkedExamplesDialog` with no pre-filter — the
user had to spot the linked entry by hand. This follow-up:

- Adds `initialSearch: String?` to `WorkedExamplesDialog`'s
  ctor and pre-fills the search controller in `initState`.
- Adds `e.id.toLowerCase().contains(query)` to the dialog's
  filter so locale-independent id deep-links work
  (titles/descriptions are translated, ids aren't).
- Threads the workedExampleId through
  `_openWorkedExample` as the `initialSearch`.

Result: tapping "See worked example" on a Function Reference
row now opens Worked Examples filtered down to exactly the
linked entry, regardless of UI locale.

Suite 1944 → 1949 (+5 tests: pre-fill, list filter, id-
search, empty no-op, end-to-end cross-link).

PLAN sketch (kept for reference):

```dart
class FunctionRef {
  final String id;            // 'solve', 'diff', 'pi_precision'
  final FunctionRefCategory category;
  final String signature;     // 'solve(equation, variable)'
  final String shortDescription; // one sentence
  final List<({String input, String expected, String hint})> examples;
  final List<String> seeAlso;  // ids of related FunctionRefs
}

enum FunctionRefCategory {
  cas,             // solve, expand, simplify, factor, diff, integrate
  numberTheory,    // gcd, lcm, isprime, factorint, ...
  precision,       // pi(N), e(N), sqrt(2, N), ...
  matrix,          // det, inv, rref, transpose, ...
  graphing,        // plot annotations, derivative overlay, ...
  statistics,      // mean, stddev, t-test, ...
  constraints,     // DSL operators
  sudoku,          // variant rules
  units,           // unit math
}
```

Plus a `FunctionReferenceDialog` widget (mirrors
WorkedExamplesDialog: search, category chips, list, detail
panel). Cards link to a "Try in Calculator" deep-link
(uses the existing `pendingInsertExpression` AppState slot)
and a "See worked example" cross-link.

##### Round 97 — Write CAS function entries (the meat) — **SHIPPED**

~15 entries for the CAS category alone: `solve`, `expand`,
`simplify`, `factor`, `diff`, `integrate`, `subst`, `limit`,
`series`, `taylor`, `gcd`, `lcm`, `factorial`, `fibonacci`,
plus the precision-arc set. Each gets the 2-3 examples + the
"how SymEngine implements this" one-paragraph explanation.

Importantly: these explanations are NOT the math itself —
they're "in CrispCalc, `solve(x^2 - 1, x)` returns `[-1, 1]`
as a list; the underlying call is SymEngine's
`solve_poly()`; for transcendental equations it falls through
to the numerical solver".

**Shipped (Round 97):** all CAS entries except `series` /
`taylor` (no SymEngine `series_expansion` binding in the
bridge yet — deferred until the binding lands). Precision arc
grew from the 1-entry `pi(N)` seed to cover `e(N)`, `sqrt(k, N)`,
and `EulerGamma(N)`. Number theory grew to cover `nextprime`,
`prevprime`, and `factorint`. The existing `solve` / `isprime` /
`pi_precision` entries each gained a third example and richer
"underlying call" prose in their first hint. Catalogue size went
from 3 → 20 entries. Tests: tightened the seeAlso resolver (every
seeAlso target now resolves to a catalogue entry — the v1
carve-out is gone), added slate-coverage tests for the CAS +
precision sets, plus one new dialog spot-check on the CAS-
filtered list. Two existing dialog tests that found `isprime(n)`
/ `pi(N)` directly were patched to filter via the search field
first because the grown catalogue pushes those rows below the
dialog viewport.

##### Round 98 — Matrix + linear algebra entries — **SHIPPED**

`det`, `inv`, `transpose`, `rref`, `Matrix([[…]])` syntax,
eigenvalues (if shipped). ~8 entries.

**Shipped (Round 98):** six entries — `matrix_literal`, `det`,
`inv`, `transpose`, `rref`, `matrix_arithmetic`. The last folds
the `+ / - / *` operator triplet into one entry rather than
three near-duplicate rows. Eigenvalues deferred (no bridge
binding); the matrix-slate test explicitly excludes them.
Three of six entries cross-link to existing worked examples
(`matrixDet`, `matrixInverse`, `rref`). Catalogue 20 → 26
entries. The underlying-call prose cites Bareiss for `det`,
Gauss–Jordan for `inv` / `rref`, the Dart-side cell-swap for
`transpose` (bridge doesn't expose it), and `add_dense_dense` /
`mul_dense_dense` for binary ops.

##### Round 99 — Statistics + Constraints + Sudoku entries — **SHIPPED**

The Analyze-module categories. ~15 more entries describing the
Statistics module functions (`mean`, `welchT`, `pairedT`,
`anova1`, `chi2Goodness`, `chi2Independence`, `fisherExact`,
`wilcoxon`, `signTest`), the Constraints DSL operators (`vars`,
`allDifferent`, `noOverlap`, `cumulative`, `minimize`,
`maximize`), and the Sudoku variant rules.

**Shipped (Round 99):** 19 entries total — 9 stats, 6
constraints, 4 sudoku variants (`regular` / `x` / `disjoint` /
`killer`). All carry `runnable: false`: the stats tests live
in the Statistics module's Tests tab, the DSL operators inside
the Constraints DSL editor, and the Sudoku variants are module
presets. `FunctionRef` gains a `runnable: bool` field (default
true) — the dialog hides Try-in-Calculator on `runnable: false`
rows. The See-worked-example cross-link is the proper landing
for these (the WE dialog dispatches `open:<module>` sentinels).
All 19 entries cross-link to an existing worked example.
Catalogue 26 → 45 entries.

##### Round 100 — i18n pass

Function reference content × 4 locales. By far the biggest
i18n round to date — 50+ entries × ~150 words each × 4 locales
= ~30k words. Will likely span 2-3 sub-rounds. Triage:
- 100a: EN only (existing primary)
- 100b: DE (high priority — user's local audience)
- 100c: FR + ES batched

#### Rounds 101-104: Help overlay system

##### Round 101 — Help-mode design + state — **SHIPPED 2026-05-26**

State landed on AppState itself (`bool helpMode` +
`setHelpMode` + `toggleHelpMode`) rather than as a separate
`HelpModeNotifier` class — AppState is already a
ChangeNotifier and a singleton, so the extra layer would have
been overhead. Intentionally **not persisted** across launches
(help mode is a momentary exploration state, not a sticky
preference).

`HelpTarget` widget (`lib/widgets/help_target.dart`) wraps a
child and paints a dotted-blue outline via an inline
`CustomPainter` when helpMode is on; pass-through when off.
AppBar toggles on both Calculator and Notepad (`Icons.help` /
`Icons.help_outline` swap). Demonstration wrappers applied to
Calculator history rows and Notepad line rows so the toggle
has a visible effect.

Two new i18n strings × 4 locales:
`helpModeEnableTooltip` / `helpModeDisableTooltip`. New tests:
4 AppState helpMode unit tests + 3 HelpTarget widget tests.
1955 → 1962. Round 102 will hang per-button popovers off
HelpTarget wrappers on the Adv-tab keypad.

##### Round 102 — Help popovers on Calculator keypad — **SHIPPED 2026-05-26**

`HelpTarget` extended with `onHelpTap` (absorbing
`Positioned.fill` GestureDetector when set + help mode on).
`KeypadGrid` extended with `helpRefIdFor` / `onHelpTap`
callbacks that wrap each button. `_kAdvKeyHelpRefId` mapping
in `calculator_keypad.dart` covers 15 of ~36 Adv buttons
(factorial / fibonacci / isprime / matrix_literal / det /
inv / transpose / rref / nextprime / prevprime / factorint
plus the four precision-arc entries). Buttons without a
FunctionRef map (gamma / mod / dot / cross / norm / unit /
i / P7 ops / if) render the outline but stay tap-through
— no "help unavailable" placeholder.

`showKeypadHelpPopover(context, refId)` opens an AlertDialog
with signature + shortDescription + Close + Learn-more.
Learn-more deep-links to `FunctionReferenceDialog(initialSearch:
id)` (new ctor param this round, mirrors WorkedExamplesDialog).
One new i18n string × 4 locales: `keypadHelpLearnMore`. +3
widget tests, 1962 → 1965. CAS-tab coverage left for a
follow-up round.

##### Round 103 — Help on history rows (Calculator)

In help mode, tapping a history row opens a "How was this
computed?" modal:
- Names the engine call(s) (`SymEngine.solve`, `MPFR.evalf`,
  ...)
- For solve / integrate / diff: shows the step trace if
  available (round 24/26-ish step trace work).
- For factorint / isprime: short explanation of the algorithm.
- Always: a link to the relevant FunctionRef entry.

##### Round 104 — Help on Notepad lines

Same pattern as round 103 but for Notepad. The line model
already carries enough info (parsed expression + result + any
errors) for the modal to fire. Long-press on touch
platforms; right-click on desktop.

#### Round 105 — Help on Analyze hub modules

Each module's screen gets a `(?)` button that, in help mode,
explains the module: what it computes, what the inputs mean,
what the output represents, and links into a worked example.
Notable per-module additions:

- **Statistics**: explain p-value, confidence interval, what
  the test types do.
- **Constraints (DSL)**: explain `allDifferent`, `noOverlap`,
  `cumulative`, `minimize` with a side-by-side example.
- **Sudoku**: explain the variant rules (X, Killer,
  Disjoint), the hint levels, the win-check semantics.

### Distribution surfaces (information architecture, refined)

After P6 lands, the new IA:

| Surface | Primary intent | (?) opens | Long-press / right-click opens |
|---|---|---|---|
| Calculator | Type math, see history | Worked Examples + Function Reference modals | On history row: "How was this computed?" |
| Notepad | Document-style math | Same modals (filtered to calc-relevant categories) | On line: same explanation modal |
| Graphing | Plot a function | Function Reference filtered to graphing | On annotation: explanation of extremum / inflection / root algorithm |
| Functions (UDF editor) | Define + edit UDFs | Function Reference + worked examples for UDF syntax | n/a |
| Analyze hub | Pick a module | Module-list explanation | n/a |
| (Inside any Analyze module) | Solve a CSP / draw a Sudoku / … | Module-specific worked examples + reference | Result row → algorithm explanation |

Settings becomes purely *configuration*: locale, theme, number
format, user-defined functions, import/export, about. The
"learning" surfaces all move out.

### Why this matters (and what we measure)

The strategic context from earlier in this file calls out
that CrispCalc is "competitive-to-ahead on the
scientific/power-user axis" but the input paradigm is
"still 1995". P6 doesn't fix the input paradigm — that's the
notepad work — but it fixes the **discovery** of all the
power-user features that already exist. A user who can find
`factorint`, `welchT`, and the CSP DSL is a fundamentally
different user from one who only finds the `+`/`-`/`×`/`÷`
buttons.

Success metric (informal): after P6 lands, a first-time user
should be able to discover, understand, and use a non-trivial
feature (e.g. Sudoku-X with hints, t-test on a small dataset,
factorint of a 20-digit number) within 5 minutes of opening
the app — without reading any external documentation.

### Add-on: result-handling ergonomics (interleaved with P6)

The Calculator's history context menu and the Notepad's line
context menu both already exist (calculator already has
"Show on Graph / Analyze / Differentiate / Integrate / Solve /
Copy / Reuse"), but neither lets the user **capture** what
they just computed into a named slot. Promote the right-click
menu so common follow-ups are one tap away.

##### Round 91 — Right-click "store as variable / function" — **SHIPPED**

Done 2026-05-25 — see HISTORY round 91. Calculator history
rows + Notepad result cells now expose Store-as-variable +
Store-as-function via the shared `StoreResultDialogs`. The
function item is gated on
`ExpressionPreprocessingUtils.extractFreeVariables(expr)`
being non-empty; assignment-line notepad sources are unwrapped
by `classifyNotepadLine` so the body is the RHS only. Variable
Viewer "promote to function" deferred to a follow-up — the
current dialog handles the calc + notepad surfaces cleanly,
and the viewer addition is an isolated +1.

Original spec follows for reference:

Add two new items to both the Calculator history-row menu
(`_showHistoryEntryMenu`) and the Notepad line menu (which
needs to be created if it doesn't exist):

- **Store result as variable.** Prompts for a name; persists
  via `AppState.setVariable(name, result)`. Available on every
  row (every result is a value).
- **Store as function.** Prompts for `name(arg) = expression`.
  Persists via `AppState.setUserFunction(UserFunction(...))`.
  Available only when the expression contains free variables
  the user could parameterise on. We default the arg name to
  the first free variable detected; the user can rename.

The variable name picker reuses the existing variable-naming
dialog (or creates a small one). Name validation: identifier
syntax, no shadowing of built-ins (`pi`, `e`, `i`, …).

Surfaces:
- Calculator history rows (extend `_showHistoryEntryMenu`).
- Notepad lines (add a `_showLineContextMenu` mirror; bind to
  `onLongPress` / `onSecondaryTap` like the calculator does).
- Variable Viewer rows (already has secondary-tap menu via
  `lib/widgets/variable_viewer.dart`; extend with "Promote
  this variable's value to a function" if it makes sense).

i18n: 4-5 new strings × 4 locales.

##### Round 91b — Naming-dialog UX polish — **SHIPPED**

Done 2026-05-26 — see HISTORY round 100. Both dialogs
pre-fill with the next unused single-letter name (a..z,
skipping reserved + existing + parameter), and an
overwrite-confirm AlertDialog now fires when the entered
name already exists. 3 i18n strings × 4 locales.

---

## P7 — Boolean type + relational / logical operators

Round-89 surfaced the first piece of "boolean output" in
CrispCalc (`isprime(n)` returns `true`/`false` as a string).
That's a one-off; users will reach for richer boolean syntax
the moment they start composing predicates. P7 lifts boolean
to a first-class type with the standard relational and
logical operator suite.

### What's missing today

Today's calculator handles:
- Arithmetic + symbolic expressions (numbers in, numbers /
  expressions out).
- One boolean function: `isprime`.

What it doesn't handle:
- **Relational ops** that return booleans: `==`, `!=`, `<`,
  `<=`, `>`, `>=`. Today these are reserved for the CSP DSL
  (constraints).
- **Logical ops**: `and`, `or`, `xor`, `not`. Today none.
- **Conditional**: `if(cond, thenExpr, elseExpr)`.

### What SymEngine already gives us

SymEngine's `cwrapper.h` exposes:
- `bool_set_true(basic s)` / `bool_set_false(basic s)` — boolean
  literals.
- `basic_eq(const basic a, const basic b)` — equality predicate
  (returns int, not basic — but we can wrap it).

What it doesn't expose (would need new wrappers OR direct
construction via `basic_parse("And(...)")`):
- `basic_set_lt`, `basic_set_leq`, `basic_set_gt`, `basic_set_geq`
  for relationals.
- `basic_set_and`, `basic_set_or`, `basic_set_not`,
  `basic_set_xor` for logicals.

Practical option: SymEngine's text parser DOES handle
`Eq(a, b)`, `Ne(a, b)`, `Lt(a, b)`, `Le(a, b)`, `Gt(a, b)`,
`Ge(a, b)`, `And(a, b)`, `Or(a, b)`, `Not(a)`, `Xor(a, b)`
as named functions. So one cheap path is: have the calculator
preprocess `a == b` → `Eq(a, b)`, `a and b` → `And(a, b)`,
etc., then evaluate through the existing `basic_parse` +
`basic_evalf` path.

### Rounds 110+ — Boolean roadmap

##### Round 110 — Relational operators ✅

Done 2026-05-26. New
`ExpressionPreprocessingUtils.preprocessRelationalOperators` does
a paren-depth-0 scan + longest-match rewrite (`==`, `!=`, `<=`,
`>=` ahead of `<`, `>`) and lowers each into SymEngine's named
function form: `2 == 2` → `Eq(2, 2)`, `x + 1 < 5` → `Lt(x + 1, 5)`,
etc. `=` alone is left untouched so the assignment + bare-equation
solver routes still fire. Constant operands fold to SymEngine's
`True` / `False`; symbolic operands stay as the function form
(`Eq(x, 1)`).

The calculator's assignment regex tightened from `=\s*` to
`=(?!=)\s*` so `name == value` no longer captures as an
assignment with body `= value`. Notepad's `_assignmentRegex` got
the same `(?!=)` fix; new test pins the classify behavior for
`x == 1` / `x <= 5` / `x != y`.

Calculator + notepad dispatch both call the rewrite right after
LaTeX conversion + inline-derivative expansion, so the rest of
the pipeline (precision pre-pass, unit eval, CAS dispatch,
generic `evaluate`) sees the `Eq(...)` / `Lt(...)` form. The
boolean result strings (`True` / `False`) flow through a new
`normalizeBooleanResult` that lowercases them to `true` / `false`
for display consistency with the round-89 `isprime` output.

Calculator history rows render `true` / `false` results as a
colored chip (secondaryContainer / errorContainer pair) via a
new `_buildBooleanChip` helper — matches the round-87b Sudoku
win-chip visuals. Notepad keeps the plain-text rendering for
round 110; the chip surfacing in notepad result cells is part
of round 113.

22 new tests in `test/relational_preprocessor_test.dart` covering
shape rewrites (one per operator), non-matches (plain arithmetic,
single `=`, parenthesized relationals, empty operands), the
first-top-level-operator-wins behavior, the boolean-result
normalizer, and the notepad classify tightening. Full suite:
1810 → 1832 pass.

##### Round 111 — Logical operators + connectives ✅ (conditional deferred)

Done 2026-05-26.
`ExpressionPreprocessingUtils.preprocessLogicalOperators` does a
two-phase walk: phase A descends into each parenthesized
subexpression so nested logical ops lower before the top level,
phase B splits at depth 0 in precedence order (`or` ← lowest,
then `xor`, then `and`) and finally checks for a leading `not`
before falling through to the round-110 relational rewrite at
the leaf.

Precedence matches Python: `not` binds tighter than `and` /
`xor`, which bind tighter than `or`. Relationals bind tighter
than `not`, so `not x == 5` reads as `Not(Eq(x, 5))`. Chained
forms collapse to a single n-ary call (`a and b and c` →
`And(a, b, c)`) — SymEngine accepts arbitrary arity on `And` /
`Or` / `Xor`.

Calculator + notepad both swapped their direct
`preprocessRelationalOperators` call for the combined
`preprocessLogicalOperators`, so the dispatch sees the fully
lowered form before the assignment / bare-equation /
precision-call / unit / CAS checks.

Word-boundary checks on every match keep identifiers like
`random`, `factor(x)`, `notation` safe from accidental
rewrites. Unbalanced parens stop the descent without throwing
so SymEngine surfaces the syntax error downstream.

24 new tests in `test/logical_preprocessor_test.dart` cover:
simple infix / unary rewrites for each operator, chained
collapse, precedence (`not x and y` vs `not (x and y)`,
`a and b or c`, `not x == 5`, `isprime(17) and 17 < 20`),
double-negation nesting, word-boundary safety for `random` /
`factor` / `notation`, integration with the round-110
relational rewrite at the leaf, and defensive handling of
trailing operators + unbalanced parens. Full suite: 1832 →
1856 pass.

**Conditional `if(cond, thenExpr, elseExpr)` ✅** Shipped 2026-05-26
as round 111b. New `ExpressionPreprocessingUtils.tryFoldIfConditional`
takes the expression + an async evaluator, detects an `if(...)`
call that spans the whole input, preprocesses the condition via
`preprocessNativeExpression`, and returns the trimmed
then-/else-branch when the condition folds to `true`/`false`.
Symbolic conditions return null so the caller leaves the
original `if(...)` form alone (SymEngine then surfaces the
error since `Piecewise` isn't in its text parser). Calculator
routes the condition through `_runEngineOpMaybeAsync` so it
gets the same worker-isolate amortization as a normal evaluate;
notepad routes through `EngineService.evaluateAsync` directly.

Round 111b also fixed a latent descent bug: when
`preprocessLogicalOperators` recursed into a paren-group
containing top-level commas (`Min(2 == 2, x + 1)` or
`if(cond, t, e)`), the inner relational scan walked past the
commas and produced `Min(Eq(2, 2, x + 1))`. The descent now
splits the inner content by depth-0 commas via the new
`_splitTopLevelByComma`, rewrites each piece independently,
and rejoins with `, `. Each part is trimmed during the split
so the rejoin produces clean single-space separators.

Adv-keypad gains an `if` button (`if(, , )` template with the
cursor right after `(`); new `booleanIfFold` worked-example
entry (`if(isprime(7), 100, 200) → 100`) localised across
en/de/fr/es. The catalog cap test bumped 40 → 50 for the
P7 boolean batch.

18 new tests in `test/logical_preprocessor_test.dart` (4 for
the descent fix, 8 for `tryFoldIfConditional`). Full suite:
1880 → 1898 pass.

##### Round 112 — Boolean keypad + worked examples ✅ (`if` deferred)

Done 2026-05-26. Ten new Adv-tab keys (`==`, `≠`, `<`, `≤`,
`>`, `≥`, `and`, `or`, `not`, `xor`) — button labels use the
mathematical glyphs while dispatch inserts the ASCII form
the round-110 / 111 preprocessor recognises (`!=`, `<=`,
`>=`). Word operators insert with surrounding spaces so they
don't jam against adjacent identifiers. `if` is omitted
while round 111b (Dart-side conditional fold) is still
deferred — adding the button without a working fold would
mislead users.

Four new worked-examples entries in the `numberTheory`
category (`booleanIsprimeAnd`, `booleanEqualityFold`,
`booleanNotPrime`, `booleanOrChain`), all classroom-flavored
predicates that fold to `true` once SymEngine sees them.
Catalog is now 39 entries; the existing test cap of 40 still
holds. Titles + descriptions localised across en/de/fr/es;
the locale-coverage test picked up every new id automatically.

A separate logic-tab section was considered but the existing
Adv tab already groups precision-arc + ntheory in one place,
so the boolean keys slot into the same tab without a new
section. Full suite: 1856 → 1880 pass.

##### Round 113 — Notepad integration ✅

Notepad lines can now contain predicates and have the result
chip render the same way the calculator history does. Lifted
the calculator-local `_buildBooleanChip` to a new shared
`lib/widgets/boolean_chip.dart` (`BooleanChip`) and wired it
into `notepad_screen.dart::_buildResult` — the existing
`normalizeBooleanResult` already lowercases SymEngine's
`True`/`False` before the value reaches the cached result, so
the chip path keys on `res.trim() == 'true'` / `'false'`. The
calculator's `_buildBooleanChip` now just `Align`-wraps the
shared widget (right-anchored inside the history column);
notepad embeds the chip directly into its already-end-aligned
result column.

Font sizes differ across the two surfaces: calculator history
uses 18 (matching the surrounding result text), notepad uses
16. The shared widget defaults to 18 and exposes a `fontSize`
parameter for the notepad embed.

**Arithmetic-with-boolean coercion** (the open V1 decision):
no proactive coercion. If SymEngine's `evaluate` returns a
symbolic form for `1 + (2 == 2)`, the user sees the symbolic
form; if it returns an error, the user sees the error. The
chip path is purely a display layer over already-normalized
boolean strings — it doesn't touch the engine's typing
behaviour. Promoting bool→int or refusing the operation can
be revisited if a real user surface demands it; without that
signal, we'd be building speculative behaviour.

`tryFoldIfConditional` was already shared (Round 111b) so
`if(cond, t, e)` works in notepad lines too. Full suite: 1898
→ 1905 pass (+4 widget tests for `BooleanChip`, +3 notepad
screen tests verifying chip render on `true`/`false` and
absence on numeric results).

##### Round 114 — Reference + help-mode wiring

Round-97 Function Reference gets a new "Logic" category with
entries for every relational + logical operator. Help mode
(round 102) on a logic button shows a quick truth-table popover
for the operator.

### Why P7 is its own thing

Booleans cross-cut the type system, the parser, the result
formatter, and the keypad. It's not a "wrap a SymEngine
function" round like the precision arc — it's a small but
real type extension. Worth designing once and shipping in
sequence rather than smuggling pieces into other rounds.

---

## P8 — Calculator history performance hot spots

User-reported (May 2026, end of session): toggling the
Calculator's ASCII ↔ LaTeX history view is "very very long"
on `flutter run -d macos`. History search is also slow. Both
likely share the same root cause: the history list rebuilds
every entry synchronously on every state change, and each
LaTeX-mode entry runs `flutter_math_fork`'s `Math.tex()` on
every rebuild.

### Diagnosis (best-current-understanding)

`calculator_screen.dart::_buildExpressionDisplay`:

```dart
Widget _buildExpressionDisplay(String expression) {
  if (_showLatexHistory && expression.isNotEmpty) {
    return Math.tex(_toLatex(expression), ...);
  }
  return Text(expression, ...);
}
```

Called for every history row on every rebuild. `Math.tex` is
not free — it parses the LaTeX source, builds an AST, and lays
out math glyphs. With 100+ history entries (typical for a
session), toggling `_showLatexHistory` rebuilds the entire list
which means 100+ fresh LaTeX layouts on the main thread.

History search has the same shape: re-filter + re-render.

### Round 120 — Cache rendered LaTeX per entry — **SHIPPED**

Done 2026-05-25 — see HISTORY round 120. Per-expression
insertion-ordered Map used as an LRU keyed by the raw
expression string, capped at 500 entries. Hits move the key
to MRU; overflow evicts the oldest. Only the LaTeX branch
goes through the cache — plain `Text` is cheap. `Math.tex`
layout now happens once per unique expression per session;
toggling the switch or typing into the search filter only
fires `setState` and the cache serves the same widget tree
on every rebuild. Plain-text branch unchanged.

### Round 121 — `RepaintBoundary` + `ListView.builder` virtualization

If the history isn't already using `ListView.builder` (lazy
itemBuilder), wrap it in one so off-screen rows don't render.
Wrap each row in `RepaintBoundary` so a partial state change
(e.g. selection highlight) doesn't invalidate adjacent rows.

### Round 122 — Async LaTeX precomputation

For NEW entries: precompute the LaTeX source on a microtask
(`scheduleMicrotask`) right after history-write; render the
plain-text view first, swap to LaTeX once ready. Round 120's
cache populates from this path so the first render of a fresh
entry is the only place where the Math.tex layout cost shows.

### Round 123 — Search debounce + index

If the user is typing a search query, the current code probably
re-filters on every keystroke. Add a 200ms debounce on the
search input. For a more aggressive fix: build a token-index
(`Map<String, Set<int>>` of expression-tokens → row ids) on
history-load and use it for O(1) prefix lookups. Likely
unnecessary if 120 + 121 already make the rebuild fast
enough — measure first.

### Round 124 — Profile-guided pass

After 120-123 land, run a `flutter run -d macos --profile`
session and use the DevTools timeline to confirm the toggle +
search drop below 16ms / frame at 60fps. Fix whatever still
shows up red.

### Open question

Is the `Math.tex` cost on the LaTeX path or on the AST → glyph
layout? If layout, there's nothing we can do in CrispCalc
short of caching. If parsing, we might precompute the AST and
hand it directly. Round 124's profiling will answer.

---

## Small follow-ups (debt items, ship anytime)

##### "Matrix self-test" debug-only gate — **SHIPPED**

Done in `f1d084d` ("fix: gate Matrix self-test tile behind
kDebugMode"). Tile at `main.dart:644-655` is now wrapped in
`if (kDebugMode) ...` with a docstring pointing at this PLAN
entry. CI / scripted runs still reach the diagnostic via the
`CRISPCALC_DIAGNOSTIC=matrix` env var at startup
(`main.dart:73-79`).

Follow-up audit pass (2026-05-27): Settings is clean — all 15
tiles (language, number format, theme, exact-integer mode,
auto-bind solve, replay tour, layout info, user functions,
worked examples, function reference, help, export, import,
matrix-diagnostics-debug-only, about) are user-facing or
already gated. No further leaked entries to gate.

---

## P9 — 3D Scene module (May 2026)

User feedback (2026-05-26): the existing **Planes** and **Conic
Sections** modules are text-input analyzers — Planes prints a
coefficient breakdown, Conic Sections classifies the curve, neither
renders anything. We want a real 3D scene where the user can
define multiple objects (planes, lines, spheres, quadrics,
parametric surfaces / curves), see them rendered together, and
compute / visualize pairwise intersections.

### Approach

A new **top-level Analysis-hub module** ("3D Scene" / "3D-Szene")
that supersedes Planes. The existing Plane Analyzer + Conic
Sections stay as cheap quick-analyzers (and remain reachable for a
deprecation cycle), but the new module is where users go when they
need to *see* multiple objects + intersections.

Built on the existing Graphing3D rotation/projection machinery
(`_Surface3DPainter` in `graphing_3d_screen.dart` rounds 33+):
hand-rolled rotation matrices, orthographic projection, height-
tinted wireframes. The renderer learns to draw additional object
kinds; the controller manages a list of objects + viewport state.

### Round-by-round plan

#### Round A1 — Engine scaffolding — **SHIPPED**

Done 2026-05-26 — see HISTORY round 92. New `lib/engine/scene_3d/`
package:

- `scene_object.dart` — sealed `SceneObject` + concrete
  `PlaneObject` (coord form `ax+by+cz=d`), `LineObject` (point +
  direction), `SphereObject` (center + radius), `QuadricObject`
  (10 coefficients), `ParametricSurfaceObject` (r(u,v)),
  `ParametricCurveObject` (r(t)). Each carries id + label +
  ARGB color + visibility. Compact JSON keys for prefs.
- `scene_state.dart` — `Scene3D` container with ordered objects +
  viewport (azimuth, elevation, zoom, range). `withObject` /
  `withoutObject` for immutable mutations.

Pure-Dart, no UI changes. 19 new tests covering construction,
geometry invariants (plane.contains, line.throughPoints,
quadric.evaluate), and JSON round-trip across all six kinds. Total
suite 1465 → 1484.

#### Round A2 — Scene screen + 3D viewport + plane rendering — **SHIPPED**

Done 2026-05-26 — see HISTORY round 93. `Scene3DScreen`
registered as an Analysis-hub module (appended at the end of
the list — original-plan placement next to Planes pushed Sudoku
just past the test viewport and `scrollUntilVisible→tap` raced,
so the card moved to the bottom). Adaptive side-by-side /
stacked layout at the 720px breakpoint. Drag-to-rotate +
pinch-to-zoom on the viewport, persisted via
`AppState.updateSceneViewport`. Add/Edit Plane dialog with
coord-form + label + 8-swatch color picker. The Scene3D
serializes into both prefs and the existing Export/Import
JSON. A fresh painter at `lib/widgets/scene_3d_painter.dart`
draws plane patches (translucent fill + outline + interior
cross-lines + centroid dot); A3+ extends the dispatcher with
line / sphere / quadric / parametric drawing. A shared
projection helper deferred until A3 has settled the rendering
surface.

#### Round A3 — Lines + spheres in the viewport — **SHIPPED**

Done 2026-05-26 — see HISTORY round 94. Painter learned
`_drawLine` (slab-clipped against the view cube + screen-
space arrow tip) and `_drawSphere` (8-ring × 16-meridian
wireframe with depth-cued opacity for the back hemisphere).
Add-Line dialog supports both point+direction and two-points
input modes; Add-Sphere validates radius > 0. The FAB switched
from a plane-only button to an "Add object" chooser sheet, and
the object panel became a `ReorderableListView` with the
color swatch acting as drag handle. New `Scene3D.with
ReorderedObjects` + `AppState.reorderSceneObjects` helpers
(both with engine-level tests).

#### Round A4 — Pairwise intersection algorithms + rendering — **SHIPPED**

Done 2026-05-26 — see HISTORY round 95. Sealed `Intersection`
hierarchy + `intersect(a, b)` dispatcher over the 6 V1 pairs,
all closed-form math, tolerance `1e-9`. Painter overlays
intersection geometry in cyan (point/dot, line segment,
circle as 48-sample polyline). New `Scene3DIntersectionsPanel`
beneath the object list shows the analytical answer per pair.
The screen computes intersections once per build and feeds the
same list to painter + panel. 24 new tests covering every pair
+ degenerate cases (parallel, skew, coincident, contained,
tangent, missed, nested). 7 + 16 i18n strings × 4 locales for
panel chrome + reason keys.

#### Round A5 — Quadrics (preset-based) — **SHIPPED**

Done 2026-05-26 — see HISTORY round 96. Six preset kinds
(ellipsoid, elliptic cone / cylinder / paraboloid,
one-sheet + two-sheet hyperboloid) added via a preset-picker
dialog. QuadricObject gains optional `preset` metadata
(kind + center + semi-axes); `QuadricObject.fromPreset`
derives the 10 generic coefficients (canonical math
representation stays the source of truth). Painter
dispatches on `preset.kind` to draw a 24×24 parametric
wireframe; `_QuadricGridSpec` carries per-kind (u, v)
ranges + wrap flags. FAB chooser sheet gains a Quadric
option; edit / visibility / panel subtitle all learn the
new kind. 11 i18n strings × 4 locales. 5 new tests for the
preset → coefficient pipeline.

#### Round A5b — Plane × quadric → conic projection — **SHIPPED**

Done 2026-05-26 — see HISTORY round 97. New
`ConicSectionIntersection` result type carries the plane's
local frame + the 6 conic coefficients + the `ConicKind`
classification (via the existing `analyzeConic`). Dispatcher
handles `(plane, quadric)` and the swapped pair. Painter
renders the curve via marching-squares on a 64×64
plane-local grid (each crossing maps back to 3D via the
`ConicSectionIntersection.worldAt` helper). Panel shows the
classification + the 6 coefficients so the user can paste
them into the existing Conic Section analyzer.

Deferred to A5c: "Open in 3D Scene" entry on the Conic
Section module; raw-coefficient quadric input mode; full
degenerate-conic detection on `conic_math` (the 3×3
determinant catches the pair-of-parallel-lines case that
the discriminant alone misclassifies as a parabola).

#### Round A6 — Parametric surfaces + curves — **SHIPPED**

Done 2026-05-26 — see HISTORY round 99. Two add/edit
dialogs (surface defaults to a torus, curve to a helix)
with monospaced expression fields. Painter samples the
parametric grid via the shared CalculatorEngine and draws
u/v-direction wireframes for surfaces, polylines for
curves; NaN samples skipped. Process-static
`_ParametricSampleCache` keyed by the full geometry hash
caches projected samples across rotation frames (FIFO at
32 entries) so each edit pays the SymEngine cost once.
6 i18n strings × 4 locales. Numerical intersection with
other kinds (Newton on a fine grid) deferred to A7.

### Cross-cutting concerns

- **Performance**: rendering N objects on every rotation frame
  is fine for N ≤ ~10 with current grid sizes. Past that we'll
  need per-object dirty flags + cached projected-vertex lists
  (similar to round 120's LaTeX cache). Defer until measured.
- **Coordinates**: shared `Vector3` from `plane_math.dart`. If
  the new module's needs grow (e.g. matrices for projections),
  extract `Vector3` + a `Matrix3` to `lib/engine/scene_3d/
  vector_math.dart` and have `plane_math.dart` re-export.
- **i18n**: each round adds 5-15 new strings × 4 locales. The
  existing locale-coverage test enforces non-empty values.
- **Deprecating PlaneAnalysisScreen**: kept through A1-A6.
  After A6 ships, add a "(?)" notice on the old module pointing
  at the new one; remove a release later (it's a small file,
  not load-bearing).

---

## P10 — Web deployment for CrispCalc (deferred, ship when ready)

CrispCalc is Flutter-native today; the desktop and mobile builds
ship a `flutter_symengine_*` dylib that the `SymbolicMathBridge`
loads via `dart:ffi`. A web build (e.g. behind a Vercel /
Cloudflare / GitHub Pages URL) compiles Dart to JS/WASM and
**cannot use `dart:ffi`** — the browser has no `.dylib`/`.so`/
`.dll` loader. The `flutter_symengine_*` bridge would land on
its already-handled "unavailable" path and the CAS / precision /
number-theory features would silently degrade.

Three realistic paths to a real web build, in increasing order of
work and decreasing order of degradation:

### Path A — Reduced-capability web (low risk, ~1 round)

Just ship `flutter build web` as-is. The bridge falls back; the
dispatcher already returns "Error: requires native library" for
every CAS call. What breaks (no FR fallback today):

- **CAS**: `solve`, `factor`, `expand`, `simplify`, `diff`,
  `integrate`, `limit`, `gcd`, `lcm` (SymEngine)
- **Precision arc**: `pi(N)`, `e(N)`, `sqrt(2,N)`,
  `EulerGamma(N)` (MPFR)
- **Number theory**: `isprime`, `nextprime`, `prevprime`,
  `factorint` (FLINT)

What still works (pure Dart):

- **Calculator basics**: arithmetic, history, variables, UDFs,
  notepad
- **Matrix evaluator**: `Matrix(...)`, `det`, `inv`, `transpose`,
  `rref`, `dot`, `cross`, `norm`, `unit`
- **Statistics**: descriptive, regression, distributions,
  hypothesis tests
- **CSP / Constraints**: Diophantine, cryptarithm, DSL
- **Sudoku**: all variants
- **Unit conversion**, **constants catalog**
- **Step engine**: Dart-side rule walker (drives the worked
  examples + Show-steps modal); the *final canonical result*
  step on each trace would surface the bridge-unavailable error
  instead of an answer

Scope checklist when this round ships:

- Add a `flutter build web` target to CI + a web-build workflow
  (`.github/workflows/build-web.yml` mirroring the other
  per-platform builds).
- Detect web at runtime (`kIsWeb`) and surface a banner /
  module-level explainer on Calculator + Notepad: *"Symbolic
  features (solve, integrate, factorint, …) require the desktop
  or mobile build."*
- Per-row error normalization: `_runEngineOpMaybeAsync` returns
  `Error: requires native library` today; on web, rewrite to the
  friendlier *"Not available in browser — try the desktop app"*
  via a `kIsWeb` branch in `EngineErrorFormatter.format`.
- Disable the Adv-tab precision-arc buttons + CAS keypad buttons
  on web (or keep them with a help-mode popover explaining the
  limitation — Round 102 / 102b's wiring is already in place).
- Add a "Download desktop app" CTA in the AppBar on web.

Hosting: any static host. Vercel / Cloudflare Pages / GitHub
Pages all serve `build/web/` cleanly. No backend needed.

### Path B — SymEngine via WebAssembly + JS interop (medium risk, ~3-4 rounds)

Compile SymEngine to WASM with emscripten, wrap it with a thin
JS module, and call into it from Dart via `dart:js_interop`. The
result: CAS calls work in-browser at near-native speed (single-
threaded; WASM SIMD is fine for SymEngine's symbolic
manipulation, less critical than for numerics).

**Prior art**:

- `symengine.wasm` proof-of-concepts exist in the wild (search
  `symengine emscripten github`). None are official; expect to
  fork and patch.
- `flutter_rust_bridge` has shown a pattern for transparently
  bridging native FFI + WASM-JS interop behind one Dart API —
  the analogous pattern for the SymEngine bridge would be
  `SymbolicMathBridge` keeping the same surface, with the
  `dart:ffi` impl on native and a `dart:js_interop` impl on web.

**Rough scope**:

1. **Bridge surface audit**. Inventory every `flutter_symengine_*`
   symbol the existing FFI bindings touch (~30 functions). Define
   the equivalent JS exports from the WASM module so the contract
   is symmetric.
2. **Emscripten build**. Patch `submodules/symengine` (or fork)
   to build a WASM target via emscripten. Pin the SymEngine
   version; cache the build in CI (it's slow).
3. **Conditional import**. Split `lib/services/symengine_bridge/`
   into `bridge_native.dart` (`dart:ffi`) + `bridge_web.dart`
   (`dart:js_interop`) + a stub `bridge_unsupported.dart`. Top-
   level `import 'bridge_stub.dart' if (dart.library.io)
   'bridge_native.dart' if (dart.library.js_interop)
   'bridge_web.dart';`.
4. **WASM asset hosting**. The `.wasm` ships in `web/` and is
   loaded async on app start. Add a splash / loading state to
   the Calculator while it boots.
5. **MPFR / FLINT**. Same emscripten treatment, OR drop these
   on web and accept the precision-arc / number-theory
   degradation from Path A. They're smaller libs but their
   binding surface is wider.

**Risks / unknowns**:

- WASM blob size — SymEngine is C++ with template-heavy headers;
  expect 5-10 MB compressed. May need a "load on first CAS call"
  pattern to keep cold-start fast.
- Worker isolation — the existing `EngineService` uses a worker
  isolate to keep heavy CAS off the UI thread. Browsers offer
  Web Workers; Flutter web's isolate story is "we lie and run
  on the main thread" — long CAS calls will jank. Mitigation:
  defer to `compute()` and accept slower-but-async on web.
- emscripten + SymEngine's `bindings/c/cwrapper.cpp` may not
  build cleanly out-of-the-box; budget for patching.

### Path C — Remote bridge service (medium risk, ongoing operational cost)

Run the existing native bridge on a server; the web client RPCs
into it. Lowest engineering effort to *reach* full CAS in the
browser, but introduces network latency (every solve / integrate
becomes ~50-300 ms instead of instant) and an ongoing service to
keep running.

**Hosting candidates** (free-tier reality, early 2026):

| Service | Free tier | Native bridge fit | Notes |
|---|---|---|---|
| **Cloud Run (GCP)** | 2M req / 360k GiB-s / 180k vCPU-s per month *forever*; scales to zero. | Native dylib via container image — supports any base; SymEngine + MPFR + FLINT layered in cleanly. | Probably **free** for personal calculator traffic. Cleanest "real cloud" pick. |
| **HF Spaces (Docker)** | Free CPU tier: 2 vCPU / 16 GiB RAM for public spaces; sleeps after ~48 h idle, wakes on first request. | First-class Docker support — drop the SymEngine + MPFR + FLINT image straight in. Public URL is the space's. | **Free**, generous CPU budget, lowest setup friction (no GCP account needed). Cold-wake from sleep is the main UX hit. |
| **AWS Lambda** | 1M req + 400k GB-s *forever*; scales to zero. | Native deps via Lambda Layer or container image. Cold-start hits SymEngine init each invocation. | Probably **free** but operationally fiddlier than Cloud Run. |
| **Fly.io** | No real free tier since late 2024; pay-as-you-go. | First-class Docker — best path for a native binary. Scales to zero with `auto_stop_machines`. | **~$2-4/mo** for a `shared-cpu-1x` machine. Not free. |
| **Cloudflare Workers** | Generous free tier. | **Doesn't fit** — Workers can't run native binaries; WASM-only. Would collapse into Path B without the local execution benefit. | Skip. |

**Rough scope**:

1. Wrap the existing FFI bridge in a thin HTTP/JSON server (Dart
   `shelf`, or rewrite as a Go/Rust binary — Dart's small enough).
   One endpoint per bridge call (`POST /solve`, `POST /factor`,
   etc.) with a structured request/response.
2. Build a Docker image that bundles SymEngine + MPFR + FLINT
   shared libs. CI publishes to a registry on tag.
3. `lib/services/symengine_bridge/bridge_remote.dart` — `http`
   client that mirrors the FFI surface. Conditional import same
   as Path B.
4. Add a server-URL setting (`AppState.remoteBridgeUrl`) so
   self-hosters can point at their own instance.
5. Rate-limit on the server (something like `shelf_router` +
   a token bucket per IP) to keep free-tier budget intact.
6. Web-build CSP / CORS rules so the deployed page can reach
   the Cloud Run hostname.

**Risks / unknowns**:

- Latency — every CAS call now hits the network. The notepad's
  300 ms debounce + worker-isolate pipeline assumes local
  millisecond-scale; would need recalibration.
- Privacy — user expressions leave the device. Need a clear
  banner on web ("CAS calls sent to crisp-calc-bridge.run.app").
- Reliability — service has to stay up. Free tiers will
  cold-start (~1-3 s warm-up) on the first request after idle.
- Bot abuse — public CAS endpoint with no auth invites scraping.
  Rate-limit + maybe a per-session token.

### Recommendation when this rolls around

Ship **Path A** first (it's a tidy ~1-round task and unblocks
the "try it in the browser" link on the README). Then evaluate
real web traffic. If users actually use the web version for more
than the pure-Dart features, choose:

- **Path B** if you want offline-capable web with no server cost
  long-term. ~3-4 rounds, sizable but bounded.
- **Path C — Cloud Run** if you want full CAS in-browser sooner
  with minimal Dart-side work. Operational tax (keeping the
  service alive, monitoring) trades against the WASM build
  effort.
- **Path C — HF Spaces (Docker)** if "free + zero infra account
  setup" beats "no cold-wake delay". Reasonable starting point
  for a prototype before deciding whether the bridge needs a
  dedicated cloud spend.

Tracking this in PLAN so future-us doesn't accidentally try to
solve it under time pressure when a user opens an issue.

---

## Out of scope this round

- C++ implementation of symbolic `limit` and `integrate`.
- Rewriting the LaTeX↔engine parsing as a real grammar.
- Full accessibility audit.
