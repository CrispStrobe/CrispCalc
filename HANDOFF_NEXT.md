# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (Rounds 101 + 102) session**.
Shipped the P6 help-mode infrastructure (Round 101) and then
hung actual help popovers off it for the Calculator Adv-tab
keypad (Round 102). Calc rounds 103 (history-row modals) and
104 (notepad-line modals) are the natural next steps — the
HelpTarget wrappers are already in place from Round 101.

- **101** — `AppState.helpMode` + `HelpTarget` widget +
  AppBar toggles + demo wrappers on history rows / notepad
  lines. Tests 1955 → 1962.
- **102** — Adv-tab keypad popovers via `HelpTarget.onHelpTap`
  + `KeypadGrid.helpRefIdFor`. Maps 15 Adv glyphs to
  FunctionRef ids. `showKeypadHelpPopover` opens AlertDialog
  → Learn-more deep-links to `FunctionReferenceDialog(initialSearch:
  id)`. Tests 1962 → 1965.

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
| **main HEAD** | R101 pushed at `9673aed`; R102 commit to follow |
| **Tests** | **1965 pass** (1955 → 1962 → 1965), 1 pre-existing skip — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (unchanged) |
| **CI** | R101 pushed; R97-99 + R101 status not yet observed |

Only dirty file at start was `.claude/scheduled_tasks.lock`
(harness state — left alone).

## What this session shipped

| Round | What |
|---|---|
| **101** | Help-mode toggle + dotted-outline affordance. `AppState.helpMode` (ephemeral) + `setHelpMode` / `toggleHelpMode`. New `HelpTarget` widget. AppBar toggles on Calculator + Notepad. Demo wrappers on Calculator history rows + Notepad line rows. Two i18n strings × 4 locales. +7 tests. |
| **102** | Help popovers on Calculator Adv-tab keypad. `HelpTarget.onHelpTap` (absorbing Stack overlay). `KeypadGrid` accepts `helpRefIdFor` + `onHelpTap`. `_kAdvKeyHelpRefId` maps 15 Adv glyphs → FunctionRef ids. `showKeypadHelpPopover` renders AlertDialog → "Learn more" deep-links to `FunctionReferenceDialog(initialSearch: id)` (new ctor param this round). One i18n string × 4 locales. +3 widget tests. |

## Pickup points — next strategic slot

P6 §101 + §102 done. The HelpTarget wrappers are already on
Calculator history rows and Notepad line rows from Round 101,
so Round 103 / 104 are mostly wire-up plus the modal content.

1. **Round 103 — Help popovers on Calculator history rows**.
   `HelpTarget` is already wrapped (Round 101). Round 103
   gives those wrappers an `onHelpTap`:
   - Inspect `entry.expression` to detect the engine call
     (regex on `solve(...)` / `integrate(...)` / `diff(...)` /
     `isprime(...)` / `nextprime(...)` / `factorint(...)` /
     `pi(N)` / `e(N)` / `sqrt(2,N)` / Welch-test invocations
     / matrix calls).
   - Open AlertDialog with:
     - "Computed via SymEngine.solve" (or MPFR / FLINT / Dart
       implementation source)
     - Step trace if available (`step_engine.dart` —
       differentiation / solve / integrate already emit
       MathStep lists with localized `StepNote` keys)
     - "Learn more" → `FunctionReferenceDialog(initialSearch:
       <id>)`
   - Fallback for bare-arithmetic results: "Direct evaluation"
     blurb, no Learn-more link.
   - Build a small `_HistoryRowHelpModal` widget colocated in
     `calculator_screen.dart` (private) — single use-site,
     no need to factor out to lib/widgets/.
   - Tests: widget tests for at least 2 call kinds (e.g. a
     `solve(...)` row gives the engine name + step trace; a
     bare `2+3` row gives the Direct-evaluation fallback).

2. **Round 104 — Help on Notepad lines**.
   Same shape as 103 but for Notepad. `HelpTarget` already
   wraps both row branches (Round 101). The `_NotepadLineRow`
   has access to the full `NotepadLine.source` and any cached
   result / error info, so the detection regex can run on
   the cleaned source. Long-press on touch / right-click on
   desktop alternatively.

3. **Round 102 follow-up — CAS-tab popovers**.
   The CAS pane has `solve`, `factor`, `expand`, `simplify`,
   `d/dx`, `∫`, `lim`, `subst`, `gcd`, `lcm` — all of which
   have FunctionRef entries from Round 97. Wiring is identical
   to Round 102: add `_kCasKeyHelpRefId` map + wire
   `helpRefIdFor` / `onHelpTap` in the CAS pane's KeypadGrid
   constructor (both narrow tabbed and wide two-pane layouts).
   Smaller than a full round; could be a 102b commit or
   bundled with Round 103.

4. **Round 100 — Function Reference i18n pass (~30k words)**.
   Still pending. With Round 102 shipped, the popover/dialog
   strings (`signature`, `shortDescription`) are now visible
   to users in 4 contexts (FR dialog list, FR dialog detail,
   keypad popover, deep-linked FR dialog). Translating them
   raises the user-visible payoff materially.
   - **100a**: EN-only refinements / typos / consistency.
   - **100b**: DE.
   - **100c**: FR + ES.

5. **Round 105 — Help on Analyze hub modules**.
   `(?)` button per module screen. See PLAN P6 §105.

6. **Other deferred carry-overs** (unchanged from prior
   pickup):
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

### Round 102 specifically

- **`HelpTarget.onHelpTap` uses an absorbing Stack overlay**:
  `Positioned.fill` GestureDetector layered above the child
  swallows the tap. This means flutter widget tests on a
  wrapped button in help mode emit `tap()` "would not hit
  test" warnings on the underlying button text — they're false
  alarms (the gesture lands on the overlay, which is the
  intent). Tests pass `warnIfMissed: false` to silence.
- **CAS-tab buttons have FunctionRef coverage** but Round 102
  scoped to Adv only per PLAN. Wire-up is identical when
  someone picks up that follow-up.
- **`FunctionReferenceDialog.initialSearch`** is the deep-link
  point. The dialog filters by id-substring-match AND signature
  AND shortDescription, so passing the id works for the keypad
  case and partial substrings work for fuzzy lookups.
- **Help popover content is currently English only** for the
  `shortDescription`. After Round 100 lands, the popover will
  resolve through the same per-id i18n table.

### Round 101 (carry-over)

- **`helpMode` is ephemeral** (not persisted across launches).
- **The dotted outline adds 4px** when on (zero layout cost
  when off). `HelpTarget(padding: EdgeInsets.zero)` overrides
  for tight constraints — Round 102's keypad wrapper uses this.
- **`CustomPaint` finders in tests** must be scoped via
  `find.descendant(of: HelpTarget, ...)` — Material framework
  uses `CustomPaint` internally.

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

- **Help-mode state**: `lib/engine/app_state.dart`
  (`helpMode` getter, `setHelpMode`, `toggleHelpMode`)
- **HelpTarget widget**: `lib/widgets/help_target.dart`
  (Round 101: outline; Round 102: optional `onHelpTap`
  with absorbing overlay)
- **Keypad popover**: `lib/widgets/calculator_keypad.dart`
  (`_kAdvKeyHelpRefId` map + `showKeypadHelpPopover` helper)
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
  (45 entries; `runnable: bool` field; Round 102's popovers
  read `signature` + `shortDescription` from this catalog)
- Hypothesis tests engine: `lib/engine/hypothesis_tests.dart`
- CSP / DSL engine: `lib/engine/csp_solver.dart`
- Sudoku engine: `lib/engine/sudoku.dart`
- Matrix evaluator: `lib/engine/matrix_evaluator.dart`
- AppState pending slots: `lib/engine/app_state.dart`
- Calculator: `lib/screens/calculator_screen.dart`
- Notepad: `lib/screens/notepad_screen.dart`
- Calculator keypad: `lib/widgets/calculator_keypad.dart`
- Worked-examples catalog: `lib/engine/worked_examples.dart`
- Localization: `lib/localization/app_localizations.dart`
  (R101 added `helpModeEnable/Disable`; R102 added
  `keypadHelpLearnMore`. Round 100 will add per-entry
  FunctionRef strings.)

Good luck.
