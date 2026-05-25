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
    - **Phase 4 — NotepadScreen UI skeleton.** New
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
    - **Phase 5 — Live recalc pipeline.** Per **#9**: on every
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
    - **Phase 6 — Unit syntax + scope-local assignments + `use`.**
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
    - **Phase 7 — Export / Import + share single doc + snackbar
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
