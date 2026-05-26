# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (Round 98) session**. Closed
P6 §98 matrix slate (modulo eigenvalues). Catalogue now spans
CAS, number theory, precision, and matrix — 26 entries total.
Next slot is Round 99 (statistics + constraints + sudoku).

- **98** — P6 matrix entries. 20 → 26 entries. Tests 1952 → 1953.

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
| **main HEAD** | `36603be` (Round 98) — docs commit to follow |
| **Tests** | **1953 pass** (1952 → 1953) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (FlatZinc frontend + QuickXplain MUS) |
| **CI** | Rounds 97-98 push not yet observed; previous pushes were green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped

| Round | What |
|---|---|
| **Round 97** | Function Reference CAS + precision entries. Catalogue 3 → 20. CAS: solve upgraded + 11 new entries. Precision arc: pi_precision upgraded + 3 new entries. Number theory: isprime upgraded + 3 new entries. `series` / `taylor` deferred. +2 slate tests, tightened seeAlso resolver. |
| **Round 98** | Function Reference matrix entries. Catalogue 20 → 26. `matrix_literal`, `det`, `inv`, `transpose`, `rref`, `matrix_arithmetic`. Eigenvalues deferred (no bridge binding). 3 of 6 entries cross-link to existing worked examples. +1 slate test. |

## Pickup points — next strategic slot

P6 rounds 93-98 done; Round 99 is the natural next slot.

1. **Round 99 — Statistics + Constraints + Sudoku entries**.
   ~15 more entries covering the module functions. PLAN
   names:
   - **Statistics**: `mean`, `welchT`, `pairedT`, `anova1`,
     `chi2Goodness`, `chi2Independence`, `fisherExact`,
     `wilcoxon`, `signTest`.
   - **Constraints DSL**: `vars`, `allDifferent`, `noOverlap`,
     `cumulative`, `minimize`, `maximize`.
   - **Sudoku**: variant rules (killer cages, hyper-zones,
     thermo, etc. — whatever's actually shipped).
   Many of these are surfaced as worked examples (`zScore`,
   `statsHypothesisTests`, `dslMagicSquare`, `dslMapColoring`,
   `dslOrderedTriples`, `dslCoinChange`, `dslSchedulingMakespan`,
   `dslCumulativeScheduling`, `dslRcpsp`, `killerSudoku`,
   `constraintEditor`) — line up `workedExampleId` pointers.

2. **Round 100 — i18n pass (~30k words)**. Triage:
   100a EN-only refinements, 100b DE, 100c FR+ES.

3. **Round 101 — Help-mode design + state**.
   `_helpMode` toggle on Calculator + Notepad AppBars
   (using `Icons.help_outline` — reserved for this).
   `HelpModeNotifier` in AppState.

4. **Rounds 102-104** — Help popovers on the keypad,
   history rows, and notepad lines. Round-97/98 catalogue is
   the content source for these popovers, so no duplication.

5. **Round 95 follow-up** — Statistics input pre-fill.
   `pendingStatisticsTab` slot could grow to a richer
   payload. Defer until demand surfaces.

6. **Series / taylor entries (P6 §97 carry-over)** —
   blocked on a bridge addition (`SymEngine::series_expansion`
   or equivalent). When the binding lands, drop the deferral
   comment in `function_reference.dart` and add the two
   entries (probably alongside `limit`).

7. **Eigenvalues entry (P6 §98 carry-over)** —
   blocked on a bridge addition (`DenseMatrix::eigvals` or
   equivalent). When the binding lands, drop the deferral
   comment and add the entry alongside `det` / `inv`.

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
  `'false'`. `normalizeBooleanResult` runs before the cache
  write.
- **Arithmetic-with-boolean is uncoerced.** PLAN P7 R113.

### P6 (rounds 93-98)

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
  ~8 rows. The pattern: `enterText(find.byType(TextField), '<id>')`
  then `pumpAndSettle` before tapping.
- **`series` and `taylor` deferred.** No SymEngine binding.
- **Eigenvalues deferred.** No bridge binding.
- **`matrix_arithmetic` is one entry, not three.** Treats the
  `+ / - / *` operator triplet on `Matrix(...)` operands as a
  single concept. If a future round wants per-operator detail,
  the entry can split into three.

## Hygiene reminders

- **`dart format`** before push. Format only files you touched,
  not `lib/` wholesale (HANDOFF §4.17).
- **Don't run multiple `flutter test` in parallel** — they race
  on `.dart_tool/test/incremental_kernel_*` and all fail. Run
  sync or one at a time.
- **Don't touch `.claude/`** — harness state.
- **Working on main now.** If you start a feature branch out of
  habit, ask first.

## Quick-reference paths

- Boolean preprocessor: `lib/utils/expression_preprocessing_utils.dart`
- Shared boolean chip widget: `lib/widgets/boolean_chip.dart`
- Worked Examples dialog: `lib/widgets/worked_examples_dialog.dart`
- **Function Reference model**: `lib/engine/function_reference.dart`
  (Rounds 96-98: 26 entries across CAS / number theory /
  precision / matrix)
- **Function Reference dialog**: `lib/widgets/function_reference_dialog.dart`
  (Round 96 layout; unchanged since)
- Matrix evaluator: `lib/engine/matrix_evaluator.dart`
  (Round 98 cited it for the underlying-call prose)
- AppState pending slots: `lib/engine/app_state.dart`
- Calculator: `lib/screens/calculator_screen.dart`
- Notepad: `lib/screens/notepad_screen.dart`
- Sudoku receiver: `lib/screens/sudoku_screen.dart`
- Statistics receiver: `lib/screens/statistics_screen.dart`
- Calculator keypad: `lib/widgets/calculator_keypad.dart`
- Notepad classifier: `lib/engine/notepad_evaluator.dart`
- Worked-examples catalog: `lib/engine/worked_examples.dart`
- Localization: `lib/localization/app_localizations.dart`
  (Round 96 strings still cover the Function Reference UI;
  Round 100 will i18n the entry bodies)

Good luck.
