# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (Round 99) session**. Closed
P6 §99 by filling the statistics / constraints / sudoku
categories with 19 module-surface entries. The catalogue now
spans all nine categories that the model defined back in Round
96. Next slot is Round 100 (i18n pass — ~30k words across 4
locales).

- **99** — P6 stats + constraints + sudoku entries. 26 → 45
  entries. New `runnable: bool` field on `FunctionRef`. Tests
  1953 → 1955.

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
| **main HEAD** | `3406f77` (Round 99) — docs commit to follow |
| **Tests** | **1955 pass** (1953 → 1955) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (FlatZinc frontend + QuickXplain MUS) |
| **CI** | Rounds 97-99 push not yet observed; previous pushes were green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped

| Round | What |
|---|---|
| **Round 97** | Function Reference CAS + precision entries. Catalogue 3 → 20. CAS: solve upgraded + 11 new entries. Precision arc: pi_precision upgraded + 3 new entries. Number theory: isprime upgraded + 3 new entries. `series` / `taylor` deferred. +2 slate tests, tightened seeAlso resolver. |
| **Round 98** | Function Reference matrix entries. Catalogue 20 → 26. `matrix_literal`, `det`, `inv`, `transpose`, `rref`, `matrix_arithmetic`. Eigenvalues deferred (no bridge binding). 3 of 6 entries cross-link to existing worked examples. +1 slate test. |
| **Round 99** | Function Reference stats + constraints + sudoku entries. Catalogue 26 → 45. New `runnable: bool` field on `FunctionRef` — `runnable: false` rows hide the Try-in-Calculator button (module-surface entries). 9 stats + 6 constraints DSL + 4 sudoku variants. All cross-link to existing worked examples. +1 slate test, +1 dialog widget test. |

## Pickup points — next strategic slot

P6 rounds 93-99 done; Round 100 is the natural next slot.

1. **Round 100 — i18n pass (~30k words)**. PLAN says triage:
   - **100a**: EN-only refinements. Read through the 45
     entries for typos / phrasing / consistency. Spot-check
     that every entry's "underlying call" prose actually
     reflects the current implementation (some Round-97 prose
     was based on the audit, not a direct code read).
   - **100b**: DE (high priority — user's local audience).
   - **100c**: FR + ES batched.

   The 45 entries × ~150 words each × 4 locales ≈ 27k words.
   Lots of strings to add to `app_localizations.dart`. The
   existing 11 strings per locale (Round 96) cover the
   *dialog chrome*; Round 100 adds per-entry strings keyed by
   id (probably `functionRefShortDescription_<id>`,
   `functionRefExampleHint_<id>_<i>` style).

   Currently `signature` and `shortDescription` are hardcoded
   English on the `FunctionRef` const. Round 100 needs to
   either:
   - Move them out of the const into a lookup table keyed by
     id, or
   - Keep the English defaults on the const but have the
     dialog overlay localised strings when present (graceful
     fallback to the default).

   The second option is less invasive and matches the
   existing worked-examples pattern (catalog has English
   defaults, dialog asks AppLocalizations by id and falls
   back when no translation exists).

2. **Round 101 — Help-mode design + state**.
   `_helpMode` toggle on Calculator + Notepad AppBars
   (using `Icons.help_outline` — reserved for this).
   `HelpModeNotifier` in AppState.

3. **Rounds 102-104** — Help popovers on the keypad,
   history rows, and notepad lines. Round-97/98/99 catalogue
   is the content source for these popovers, so no
   duplication.

4. **Round 95 follow-up** — Statistics input pre-fill.
   `pendingStatisticsTab` slot could grow to a richer
   payload. Defer until demand surfaces.

5. **Series / taylor entries (P6 §97 carry-over)** —
   blocked on a bridge addition (`SymEngine::series_expansion`).

6. **Eigenvalues entry (P6 §98 carry-over)** —
   blocked on a bridge addition (`DenseMatrix::eigvals`).

7. **`open:` / `dsl:` dispatch in Try-in-Calculator (P6 §99
   follow-up)** — currently the Try button is hidden on
   `runnable: false` entries. A future round could teach the
   `_tryInCalculator` helper to recognise `open:` and `dsl:`
   sentinels the same way `WorkedExamplesDialog._tap` already
   does. Then `runnable: true` could be the default again
   and the field could mean "the input is dispatchable" (true
   for both calculator calls AND module sentinels). For now
   `runnable: false` + cross-link works fine.

8. **CSP Round E.5** (deferred) — `dart_csp_fzn` CLI as a
   MiniZinc solver. Blocked on P4 distribution pipeline.

9. **P9 follow-ups** (A5d / A7 / A8) — 3D Scene polish.

10. **Precision arc round 4** (`modpow` / `modinv` /
    `totient` / `jacobi`) — multi-repo. Cross-repo arc; ask
    before starting.

## Known issues / context

### P7 (rounds 110-113)

- **Symbolic `if(...)` doesn't render usefully.** When the
  condition stays symbolic, `tryFoldIfConditional` returns
  null. Acceptable V1.
- **Bool-chip detection is a string match** on `'true'` /
  `'false'`.
- **Arithmetic-with-boolean is uncoerced.** PLAN P7 R113.

### P6 (rounds 93-99)

- **Calculator top toolbar always renders** (was guarded by
  `history.isNotEmpty`).
- **`menu_book_outlined`, not `help_outline`** — the latter
  is reserved for Round 101.
- **Round 95 sentinel parser is lenient**: unknown keys
  silently ignored.
- **Statistics pre-load is tab-pick only.** Input fields use
  built-in defaults.
- **`FunctionRef.workedExampleId` is an id pointer**, not a
  structured cross-link.
- **Function Reference rows use ExpansionTile** (inline
  detail) instead of a side-by-side master/detail layout.
- **Action buttons use `Wrap` (not `Row`)** in the row's
  detail area.
- **`_openWorkedExample` is deep-linked** via the
  `initialSearch` ctor param on `WorkedExamplesDialog`.
- **Round-97+ catalogue pushes rows below the 480px viewport.**
  Tests that find a specific row by signature should filter
  via the search field first if the entry isn't in the top
  ~8 rows.
- **`series` / `taylor` / eigenvalues deferred.** No bridge
  binding.
- **`matrix_arithmetic` is one entry, not three.**
- **`runnable: false` entries (Round 99) hide the Try
  button.** The dialog renders the See-worked-example
  cross-link only — which is fine because every Round-99
  entry has a worked-example cross-link.

## Hygiene reminders

- **`dart format`** before push. Format only files you touched,
  not `lib/` wholesale (HANDOFF §4.17).
- **Don't run multiple `flutter test` in parallel** — they race
  on `.dart_tool/test/incremental_kernel_*`.
- **Don't touch `.claude/`** — harness state.
- **Working on main now.** If you start a feature branch out of
  habit, ask first.

## Quick-reference paths

- Boolean preprocessor: `lib/utils/expression_preprocessing_utils.dart`
- Shared boolean chip widget: `lib/widgets/boolean_chip.dart`
- Worked Examples dialog: `lib/widgets/worked_examples_dialog.dart`
- **Function Reference model**: `lib/engine/function_reference.dart`
  (Rounds 96-99: 45 entries across all nine categories. New
  `runnable: bool` field on `FunctionRef` as of Round 99.)
- **Function Reference dialog**: `lib/widgets/function_reference_dialog.dart`
  (Round 99: gated the Try button on `entry.runnable`)
- Hypothesis tests engine: `lib/engine/hypothesis_tests.dart`
  (Round 99 cited it for stats prose)
- CSP / DSL engine: `lib/engine/csp_solver.dart`
  (Round 99 cited the `DslToFlatZinc` transpiler)
- Sudoku engine: `lib/engine/sudoku.dart`
  (Round 99 cited `SudokuVariant` + `SudokuPresets`)
- Matrix evaluator: `lib/engine/matrix_evaluator.dart`
- AppState pending slots: `lib/engine/app_state.dart`
- Calculator: `lib/screens/calculator_screen.dart`
- Notepad: `lib/screens/notepad_screen.dart`
- Sudoku receiver: `lib/screens/sudoku_screen.dart`
- Statistics receiver: `lib/screens/statistics_screen.dart`
- Calculator keypad: `lib/widgets/calculator_keypad.dart`
- Notepad classifier: `lib/engine/notepad_evaluator.dart`
- Worked-examples catalog: `lib/engine/worked_examples.dart`
- Localization: `lib/localization/app_localizations.dart`
  (Round 100 will add per-entry strings here)

Good luck.
