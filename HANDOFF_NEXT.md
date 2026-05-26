# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (Round 101) session**.
Scaffolded the P6 help-mode infrastructure: an AppState bool
+ ChangeNotifier hook, a `HelpTarget` overlay widget, and
toggle buttons in the Calculator + Notepad AppBars. **No
popovers yet** — Round 101 ships the affordance only, per
the PLAN spec. Rounds 102-104 wire actual help content into
the keypad / history / notepad rows.

- **101** — Help-mode toggle + dotted-outline affordance.
  New `AppState.helpMode` (ephemeral), `HelpTarget` widget,
  AppBar toggles on Calculator + Notepad. Demonstration
  wrappers around Calculator history rows and Notepad line
  rows. Tests 1955 → 1962.

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
| **main HEAD** | Round 101 commit (to follow this docs commit) |
| **Tests** | **1962 pass** (1955 → 1962), 1 pre-existing skip — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (unchanged) |
| **CI** | Rounds 97-99 push not yet observed; previous pushes were green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped

| Round | What |
|---|---|
| **Round 101** | Help-mode toggle + dotted-outline affordance. `AppState.helpMode` (bool, not persisted) + `setHelpMode` / `toggleHelpMode`. New `HelpTarget` widget paints a dotted blue outline via `CustomPainter` (no new dep). Toggle `IconButton` on Calculator top toolbar + Notepad AppBar — `Icons.help` (filled, primary color) when on, `Icons.help_outline` when off. Demonstration wrappers on Calculator history rows + Notepad line rows. Two i18n strings × 4 locales. +7 tests (4 AppState + 3 HelpTarget widget). |

## Pickup points — next strategic slot

P6 rounds 93-99 + 101 done. **Round 102 (Help popovers on
Calculator Adv-tab keypad)** is the natural next slot since the
HelpTarget scaffolding is now in place.

1. **Round 102 — Help popovers on Calculator Adv-tab keypad**.
   For each Adv-tab button:
   - Wrap the button (or just the Adv tab's button row) with
     `HelpTarget`.
   - When `helpMode` is on, intercept the tap to open a small
     popover (`showMenu` or a tiny `AlertDialog`) showing:
     - Function name + signature (from the FunctionRef catalog
       — Round 96-99 already populated 45 entries)
     - One-line `shortDescription`
     - "Learn more" link → opens `FunctionReferenceDialog`
       with `initialSearch: <id>` (the Round 96 deep-link
       affordance)
   - When helpMode is **off**, the button works normally
     (insert the glyph).
   - The Adv tab has ~30 buttons; the popover content all
     comes from `FunctionReferences.findById(...)` so no
     duplication. Buttons without a matching FunctionRef get
     no popover (silent no-op or a "no help available" tooltip
     — picker's call).
   - `HelpTarget` already wraps targets visually; Round 102 is
     mostly tap-handling + popover content + per-button id
     mapping (probably a `Map<String glyph, String functionRefId>`
     in calculator_keypad.dart).
   - Tests: a couple of widget tests that switch to Adv tab,
     enable help mode, tap a known button (e.g. `solve`),
     and verify the popover appears with the expected
     signature.

2. **Round 100 — Function Reference i18n pass (~30k words)**.
   Still pending; can be interleaved with Round 102.
   - **100a**: EN-only refinements / typos / consistency.
   - **100b**: DE (user's local audience — high priority).
   - **100c**: FR + ES batched.
   - Pattern: dialog overlays per-id localized strings on the
     English defaults baked into the const.
   - Keys (suggested): `functionRefShortDescription_<id>`,
     `functionRefExampleHint_<id>_<i>`.

3. **Round 103 — Help popovers on Calculator history rows**.
   Already have `HelpTarget` wrapped around each row
   (Round 101). Round 103 swaps `onTap` semantics in helpMode:
   open a "How was this computed?" modal naming the engine
   call, showing the step trace if available, and linking to
   the relevant FunctionRef entry.

4. **Round 104 — Help on Notepad lines**.
   Same pattern as Round 103 but for Notepad. `HelpTarget`
   already wrapped both row branches (Round 101).

5. **Round 105 — Help on Analyze hub modules**.
   `(?)` button per module screen explaining what the module
   computes. See PLAN P6 §105.

6. **Other deferred carry-overs**:
   - Round 95 follow-up — Statistics input pre-fill.
   - Series / taylor entries (P6 §97) — blocked on bridge.
   - Eigenvalues entry (P6 §98) — blocked on bridge.
   - `open:` / `dsl:` dispatch in Try-in-Calculator (Round 99
     follow-up).
   - CSP Round E.5 — `dart_csp_fzn` CLI as MiniZinc solver
     (blocked on P4 distribution pipeline).
   - P9 follow-ups (A5d / A7 / A8) — 3D Scene polish.
   - Precision arc round 4 (`modpow` / `modinv` / `totient` /
     `jacobi`) — multi-repo. Cross-repo arc; ask before
     starting.

## Known issues / context

### Round 101 specifically

- **`helpMode` is ephemeral** (not persisted across launches).
  If the user prefers it sticky, add `_kHelpMode` prefs key +
  persistence in `setHelpMode` (mirrors `setAutoBindSolve`).
- **The dotted outline adds 4px** (`EdgeInsets.all(2)`) of
  padding to wrapped widgets when `helpMode` is on. Zero
  layout cost when off (pure pass-through). Notepad rows
  already have 8/4-px symmetric padding so this is invisible;
  Calculator history rows likewise (24/8). If a future
  wrapper sits inside tight constraints (e.g. small keypad
  buttons in Round 102), pass `padding: EdgeInsets.zero` to
  `HelpTarget` to avoid layout drift.
- **`CustomPaint` finders in tests** must be scoped via
  `find.descendant(of: HelpTarget, matching: CustomPaint)` —
  the Material framework uses `CustomPaint` internally in
  Scaffold / InkWell / etc., so a bare `find.byType(CustomPaint)`
  matches false positives. `test/help_target_test.dart`
  models the pattern.
- **No popovers yet.** The toggle currently only changes the
  outline — tapping a wrapped widget still runs its normal
  handler. That's intentional per the Round 101 spec
  ("ships just the toggle + outline"). Round 102 changes
  this on a per-target basis.

### P7 (rounds 110-113) — unchanged from prior pickup

- **Symbolic `if(...)` doesn't render usefully.**
- **Bool-chip detection is a string match.**
- **Arithmetic-with-boolean is uncoerced.** PLAN P7 R113.

### P6 (rounds 93-101) — unchanged carry-overs

- **Calculator top toolbar always renders** (was guarded by
  `history.isNotEmpty`).
- **Round 95 sentinel parser is lenient**: unknown keys
  silently ignored.
- **Statistics pre-load is tab-pick only.**
- **`FunctionRef.workedExampleId` is an id pointer**.
- **`series` / `taylor` / eigenvalues deferred.**
- **`runnable: false` entries (Round 99) hide the Try
  button.**

## Hygiene reminders

- **`dart format`** before push. Format only files you touched,
  not `lib/` wholesale (HANDOFF §4.17).
- **Don't run multiple `flutter test` in parallel** — they race
  on `.dart_tool/test/incremental_kernel_*`.
- **Don't touch `.claude/`** — harness state.
- **Working on main now.** If you start a feature branch out of
  habit, ask first.
- **`flutter_symengine_*` symbol-not-found lines** in
  `flutter test` stderr are expected — the test VM doesn't
  load the plugin's compiled dylib. The bridge catches the
  failure and pure-Dart tests don't depend on it. Look for
  the `+NNNN ~1: All tests passed!` line at the end, not the
  per-test stderr noise.

## Quick-reference paths

- **Help-mode state**: `lib/engine/app_state.dart`
  (`helpMode` getter, `setHelpMode`, `toggleHelpMode`)
- **HelpTarget widget**: `lib/widgets/help_target.dart`
  (wrap a child to render a dotted-blue outline when
  `helpMode` is on)
- Calculator AppBar toggle: `lib/screens/calculator_screen.dart`
  (top toolbar, next to the menu_book_outlined icon)
- Notepad AppBar toggle: `lib/screens/notepad_screen.dart`
  (`_buildActions`)
- Boolean preprocessor: `lib/utils/expression_preprocessing_utils.dart`
- Shared boolean chip widget: `lib/widgets/boolean_chip.dart`
- Worked Examples dialog: `lib/widgets/worked_examples_dialog.dart`
- **Function Reference model**: `lib/engine/function_reference.dart`
  (Rounds 96-99: 45 entries; `runnable: bool` field from R99.
  Round 102 will read this to populate keypad popovers.)
- **Function Reference dialog**: `lib/widgets/function_reference_dialog.dart`
- Hypothesis tests engine: `lib/engine/hypothesis_tests.dart`
- CSP / DSL engine: `lib/engine/csp_solver.dart`
- Sudoku engine: `lib/engine/sudoku.dart`
- Matrix evaluator: `lib/engine/matrix_evaluator.dart`
- AppState pending slots: `lib/engine/app_state.dart`
- Calculator: `lib/screens/calculator_screen.dart`
- Notepad: `lib/screens/notepad_screen.dart`
- Calculator keypad (Round 102 target): `lib/widgets/calculator_keypad.dart`
- Worked-examples catalog: `lib/engine/worked_examples.dart`
- Localization: `lib/localization/app_localizations.dart`
  (Round 101 added `helpModeEnableTooltip` /
  `helpModeDisableTooltip`. Round 100 will add the per-entry
  Function Reference strings.)

Good luck.
