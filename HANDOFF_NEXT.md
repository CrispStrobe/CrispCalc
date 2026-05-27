# CrispCalc — handover for the next session

Pickup note from the **2026-05-27 (Rounds 103 + 102b + 104) session**.
Shipped the P6 help-popover sweep across Calculator history rows
(R103), CAS-tab keypad buttons (R102b — Adv was already in R102),
and Notepad lines (R104). All three surfaces now reuse the same
`HistoryRowHelpModal` + `detectHistoryHelp` routing table.

- **103** — `HistoryRowHelpModal` + `detectHistoryHelp` in
  `lib/widgets/history_help_modal.dart`. Routing table maps
  ~25 expression prefixes to (engine label, FunctionRef id,
  optional step kind). `_showHistoryHelpModal` /
  `_runStepTraceForHistory` on `CalculatorScreenState` wire
  Learn-more (deep-link `FunctionReferenceDialog`) and Show-steps
  (re-runs `StepEngine.solve / .differentiate / .integrate` and
  pops `StepsDialog`). 4 new i18n strings × 4 locales. +17
  tests (1965 → 1982).
- **102b** — `_kCasKeyHelpRefId` (10 mappings: solve / factor /
  expand / simplify / d/dx / ∫ / lim / subst / gcd / lcm) plus
  `helpRefIdFor` + `onHelpTap` wiring on the CAS pane in both
  narrow tabbed and wide two-pane layouts. The `⌄` step-trace
  variants and `=` / `,` / `f(x)` punctuation are deliberately
  omitted (calculator UX, not engine surface). +2 widget tests
  (1982 → 1984).
- **104** — `_NotepadLineRow._showLineHelp` wires `HelpTarget
  .onHelpTap` on both notepad row layouts to the same
  `HistoryRowHelpModal`. Constructs a `CalculationEntry` from
  `line.source` + `cachedError ?? cachedResult ?? ''`. Show-steps
  intentionally omitted — the row doesn't have a `CalculatorEngine`
  reference; pasting the line into Calculator + tapping `solve⌄` /
  `d/dx⌄` / `∫⌄` is the workflow. +2 widget tests (1984 → 1986).

`HANDOFF.md` remains the load-bearing pattern reference.

---

## ⚠ Working-mode change

**Parallel-arc work is paused.** All edits now go **directly on
`main`** in `/Volumes/backups/code/CrispCalc`. The old "create a
feature branch / worktree for every round" rule (HANDOFF §0a) is
suspended until the user reactivates the parallel worker.

If you accidentally start editing in a feature-branch worktree,
either move the edits to `/Volumes/backups/code/CrispCalc` or
remind yourself the user wants main.

---

## State

| | |
|---|---|
| **Main worktree** | `/Volumes/backups/code/CrispCalc` (branch `main`) |
| **main HEAD** | R103 at `c226d91`; R102b + R104 commit to follow |
| **Tests** | **1986 pass** (1965 → 1982 → 1984 → 1986), 1 pre-existing skip — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (unchanged) |
| **CI** | R102 pushed; R97-99 + R101 + R102 + R103 status not yet observed |

Only dirty file at session start was `.claude/scheduled_tasks.lock`
(harness state — left alone).

## What this session shipped

| Round | What |
|---|---|
| **103** | History-row help popover on Calculator. New `lib/widgets/history_help_modal.dart`: `HistoryHelpInfo` + `HistoryStepKind` + `detectHistoryHelp` (pure routing table) + `HistoryRowHelpModal` widget. Wiring on `HelpTarget.onHelpTap` for history rows in `calculator_screen.dart`. Modal explains the engine (`SymEngine.solve`, `MPFR`, `FLINT.ntheory`, `Dart (matrix)` / `Dart (BigInt)`, or fallback `Direct evaluation`), shows the FunctionRef signature + shortDescription, and offers Learn-more (deep-link) plus Show-steps (re-runs `StepEngine`). 4 new i18n strings × 4 locales (`historyHelpTitle`, `historyHelpComputedVia(engine)`, `historyHelpDirectEvaluation`, `historyHelpShowSteps`). +17 tests (1965 → 1982). |
| **102b** | CAS-tab keypad popovers in `lib/widgets/calculator_keypad.dart`. New `_kCasKeyHelpRefId` map (10 mappings); both narrow tabbed and wide two-pane layouts now wire `helpRefIdFor` + `onHelpTap` on the CAS pane via `showKeypadHelpPopover`. `⌄` step-trace variants and `=` / `,` / `f(x)` punctuation are deliberately omitted — they're calculator UX, not engine surface. +2 widget tests (1982 → 1984). |
| **104** | Notepad line help popovers. `_NotepadLineRow._showLineHelp` wires `HelpTarget.onHelpTap` on both row layouts (sideBySide + stacked) to the shared `HistoryRowHelpModal`. Reuses `detectHistoryHelp` over `line.source`; result is `cachedError ?? cachedResult ?? ''`. Show-steps suppressed (no engine reference); Learn-more deep-links to `FunctionReferenceDialog`. +2 widget tests (1984 → 1986). |

## Pickup points — next strategic slot

P6 §103 + §102b + §104 done. The help-popover sweep across all
three "row" surfaces is now complete (Calculator history,
Notepad lines, Calculator keypad CAS + Adv tabs). Next obvious
moves:

1. **Round 105 — Help on Analyze hub modules**. `(?)` button
   per module screen. See PLAN P6 §105. With history + notepad +
   keypad covered, the Analyze hub is the largest remaining
   surface area without help affordances.

2. **Round 100 — Function Reference i18n pass (~30k words)**.
   Still pending. With Rounds 103 + 104 shipped, the FR strings
   (`signature`, `shortDescription`) are now visible to users
   in **7 contexts** (FR dialog list, FR dialog detail, Adv
   keypad popover, **CAS keypad popover**, deep-linked FR
   dialog, **Calculator history popover**, **Notepad line
   popover**). Translating raises the user-visible payoff
   materially.
   - **100a**: EN-only refinements / typos / consistency.
   - **100b**: DE.
   - **100c**: FR + ES.

3. **Round 104 follow-up — Notepad Show-steps wiring**. The
   modal supports `onShowSteps` but Round 104 omits it because
   `_NotepadLineRow` doesn't carry a `CalculatorEngine`. To wire
   it: thread the `_engine` reference from `_NotepadScreenState`
   down through `_NotepadLineRow` (constructor param), then
   build an `onShowSteps` closure that calls
   `StepEngine.solve / .differentiate / .integrate` with the
   parsed args. Small, mechanical.

4. **Other deferred carry-overs** (unchanged from prior pickup):
   - Round 95 follow-up — Statistics input pre-fill.
   - Series / taylor entries (P6 §97) — blocked on bridge.
   - Eigenvalues entry (P6 §98) — blocked on bridge.
   - `open:` / `dsl:` dispatch in Try-in-Calculator (R99
     follow-up).
   - CSP Round E.5 — `dart_csp_fzn` CLI (blocked on P4).
   - P9 follow-ups (A5d / A7 / A8) — 3D Scene polish.
   - Precision arc round 4 (`modpow` / `modinv` / `totient` /
     `jacobi`) — multi-repo. Ask before starting.

## Known issues / context

### Round 103 specifically

- **Detection is by leading prefix only** on the trimmed
  readable expression. No semantic parse — `solve(x^2-1, x)`
  matches `solve(` but a contrived nested form like
  `2 + solve(...)` falls through to direct-evaluation. That's
  correct: the calculator dispatcher itself doesn't route
  non-leading function calls to engine handlers either.
- **Modal `onShowSteps` calls `StepEngine` re-using the same
  preprocessor as the calculator's input pipeline.** That
  means `2k + 3` (implicit multiplication) round-trips to
  `2*k + 3` before the step engine sees it, matching what
  the live evaluation did.
- **`pi(N)` vs `pi*2`**: precision-call detection regex
  requires a leading digit in the first arg (`r'^pi\(\s*\d'`)
  so call-shape lookalikes that AREN'T precision routes don't
  false-positive to MPFR.
- **`sqrt` is dual**: `sqrt(x)` (symbolic) and `sqrt(2, 50)`
  (precision) — Round 103 only labels the two-arg comma form
  as MPFR; bare `sqrt(...)` falls through to direct evaluation
  (matches actual engine routing).
- **Public exports**: `HistoryHelpInfo`, `HistoryStepKind`,
  `detectHistoryHelp`, `HistoryRowHelpModal` are all public so
  the test file can drive both halves without spinning up the
  full `CalculatorScreen`. The State-side wiring
  (`_showHistoryHelpModal`, `_runStepTraceForHistory`) stays
  private — only the State has the `_engine` instance.

### Round 104 specifically

- **Show-steps omitted on Notepad**. The modal supports
  `onShowSteps` but Notepad's `_NotepadLineRow` is a
  StatelessWidget with no `CalculatorEngine` reference. The
  user's escape hatch is to copy the line into Calculator and
  tap the `⌄` step-trace button there. Wiring it through is a
  small follow-up (see pickup §3) — not blocking.
- **`cachedError` shown ahead of `cachedResult`** in the modal's
  result line. Error rows therefore still display sensibly
  ("= Error: parse failed") rather than empty.
- **Blank lines suppress the popover**. `_showLineHelp` short-
  circuits on empty `line.source.trim()` so the modal can't open
  on the blank seed row.

### Round 102b specifically

- **`_kCasKeyHelpRefId` skips `=` / `,` / `f(x)`** by design —
  punctuation has no FunctionRef row. `solve⌄` / `d/dx⌄` / `∫⌄`
  are also skipped because the step-trace prompt isn't really a
  function-reference topic. Tests assert `=` / `,` fall through
  to normal insert in help mode.
- **Both layouts wired**: narrow tabbed (CAS at tab index 2) and
  wide two-pane (`_PaneKind.cas`).

### Round 102 (carry-over)

- `HelpTarget.onHelpTap` uses an absorbing Stack overlay;
  tests on wrapped widgets need `warnIfMissed: false`.
- Help popover content currently English-only for the
  `shortDescription`; after Round 100 lands, popovers will
  resolve through the per-id i18n table.

### Round 101 (carry-over)

- `helpMode` is ephemeral (not persisted).
- Dotted outline adds 4px when on; `HelpTarget(padding:
  EdgeInsets.zero)` overrides for tight constraints.
- `CustomPaint` finders in tests must be scoped via
  `find.descendant(of: HelpTarget, ...)`.

### P7 (rounds 110-113) — unchanged

- Symbolic `if(...)` doesn't render usefully.
- Bool-chip detection is a string match.
- Arithmetic-with-boolean is uncoerced.

### P6 (rounds 93-102) — unchanged carry-overs

- Calculator top toolbar always renders.
- Round 95 sentinel parser is lenient.
- Statistics pre-load is tab-pick only.
- `FunctionRef.workedExampleId` is an id pointer.
- `series` / `taylor` / eigenvalues deferred.
- `runnable: false` entries (Round 99) hide the Try button.

## Hygiene reminders

- **`dart format`** before push. Format only files you touched.
- **Don't run multiple `flutter test` in parallel** — they race
  on `.dart_tool/test/incremental_kernel_*`.
- **Don't touch `.claude/`** — harness state.
- **Working on main now.** Ask before starting a feature branch.
- **`flutter_symengine_*` symbol-not-found lines** in
  `flutter test` stderr are expected — the test VM doesn't
  load the plugin's compiled dylib. Bridge catches the
  failure; pure-Dart tests don't depend on it. Look for
  `+NNNN ~1: All tests passed!` at the end.
- **Avoid running 4+ parallel `Edit` calls on the same file**
  — the linter or auto-formatter can race between them and
  silently drop edits. Sequence edits to a single hot file
  (e.g. `app_localizations.dart`) rather than parallelising.

## Quick-reference paths

- **History-row help modal**:
  `lib/widgets/history_help_modal.dart` (Round 103:
  `HistoryHelpInfo` + `detectHistoryHelp` routing table +
  `HistoryRowHelpModal` widget)
- **History-row help wiring**: `lib/screens/calculator_screen.dart`
  (`_showHistoryHelpModal` + `_runStepTraceForHistory`)
- **Help-mode state**: `lib/engine/app_state.dart`
  (`helpMode` getter, `setHelpMode`, `toggleHelpMode`)
- **HelpTarget widget**: `lib/widgets/help_target.dart`
  (Round 101: outline; Round 102: optional `onHelpTap`
  with absorbing overlay)
- **Keypad popover**: `lib/widgets/calculator_keypad.dart`
  (`_kAdvKeyHelpRefId` + `_kCasKeyHelpRefId` maps +
  `showKeypadHelpPopover` helper; both Adv and CAS panes
  wired in narrow tabbed AND wide two-pane layouts)
- **Notepad line popover wiring**: `lib/screens/notepad_screen.dart`
  (`_NotepadLineRow._showLineHelp` — reuses
  `HistoryRowHelpModal`)
- **KeypadGrid help wiring**: `lib/widgets/keypad_grid.dart`
  (`helpRefIdFor` + `onHelpTap` ctor params)
- **FunctionReferenceDialog deep-link**:
  `lib/widgets/function_reference_dialog.dart`
  (`initialSearch: String?` ctor param)
- Calculator AppBar toggle: `lib/screens/calculator_screen.dart`
- Notepad AppBar toggle: `lib/screens/notepad_screen.dart`
- Boolean preprocessor: `lib/utils/expression_preprocessing_utils.dart`
- Shared boolean chip widget: `lib/widgets/boolean_chip.dart`
- Worked Examples dialog: `lib/widgets/worked_examples_dialog.dart`
- **Function Reference model**: `lib/engine/function_reference.dart`
  (45 entries; `runnable: bool` field; Round 103's modal
  reads `signature` + `shortDescription` from this catalog)
- Hypothesis tests engine: `lib/engine/hypothesis_tests.dart`
- CSP / DSL engine: `lib/engine/csp_solver.dart`
- Sudoku engine: `lib/engine/sudoku.dart`
- Matrix evaluator: `lib/engine/matrix_evaluator.dart`
- AppState pending slots: `lib/engine/app_state.dart`
- Calculator: `lib/screens/calculator_screen.dart`
- Notepad: `lib/screens/notepad_screen.dart`
- Calculator keypad: `lib/widgets/calculator_keypad.dart`
- Step engine: `lib/engine/step_engine.dart`
  (Round 103's Show-steps button re-runs
  `StepEngine.solve / .differentiate / .integrate` over
  args extracted from the history row)
- Worked-examples catalog: `lib/engine/worked_examples.dart`
- Localization: `lib/localization/app_localizations.dart`
  (R101: `helpModeEnable/Disable`; R102: `keypadHelpLearnMore`;
  R103: `historyHelpTitle` / `historyHelpComputedVia` /
  `historyHelpDirectEvaluation` / `historyHelpShowSteps`.
  Round 100 will add per-entry FunctionRef strings.)

Good luck.
