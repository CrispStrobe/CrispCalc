# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (late) session** that
finished P7 and shipped all three sub-rounds of P6's
worked-examples discoverability arc. Today's rounds:

- **110, 111, 111b, 112, 113** — P7 booleans (relational +
  logical operators, `if(...)` fold, Adv-keypad keys, worked
  examples, notepad chip rendering).
- **93, 94, 95** — P6 worked-examples discoverability (icon
  on Calculator + Notepad, surface-scoped filtering, per-
  module pre-loading via parameterised sentinels).

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
| **main HEAD** | (this session — Round 95 + docs) |
| **Tests** | **1931 pass** (1810 → 1832 → 1856 → 1880 → 1898 → 1905 → 1911 → 1931 across rounds 110/111/112/111b/113/93+94/95) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (FlatZinc frontend + QuickXplain MUS) |
| **CI** | Round 95 push not yet observed; previous pushes were green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped

| Round | What |
|---|---|
| **Round 110** | Relational-operator preprocessor (P7 kickoff). `preprocessRelationalOperators` does a paren-depth-0 scan + longest-match rewrite of `==` `!=` `<=` `>=` `<` `>` into SymEngine's `Eq` `Ne` `Le` `Ge` `Lt` `Gt`. Calculator + notepad assignment regexes tightened with `=(?!=)`. New `normalizeBooleanResult` lowercases `True`/`False`. Calculator history renders bool results as a colored chip. 22 tests. |
| **Round 111** | Logical-operator preprocessor. Two-phase walk that recurses into parens then splits at depth 0 in precedence order. Python-style precedence; chained collapse to n-ary `And`/`Or`/`Xor`. 24 tests. |
| **Round 112** | Adv-keypad keys + worked examples for P7. Ten new keys + 4 boolean worked-examples entries. |
| **Round 111b** | `if(cond, t, e)` Dart-side fold + paren-descent comma split. `tryFoldIfConditional` reads the condition through the engine and returns the chosen branch. Descent now splits inner-paren content by top-level commas before recursing. 18 tests. |
| **Round 113** | Notepad boolean integration via shared `BooleanChip` widget. V1 stance: no arithmetic-with-boolean coercion. 7 tests. |
| **Round 93** | Worked Examples library out of Settings — `menu_book_outlined` IconButton on Calculator top toolbar + Notepad AppBar. Settings card subtitle updated. |
| **Round 94** | Surface-scoped filtering. `WorkedExamplesSurface` enum (`calculator`/`notepad`). Notepad allowlist: `{calculus, algebra, linearAlgebra, numberTheory}`. |
| **Round 95** | Per-module pre-loading via parameterised sentinels. New AppState slots (`pendingSudokuPresetId`, `pendingStatisticsTab`), receiver drain on Sudoku + Statistics, dialog parser extension for `open:<module>?key=value`. `killerSudoku` upgraded to `open:sudoku?preset=killer9x9`; new `statsHypothesisTests` → `open:statistics?tab=tests`. V1 stops at tab-pick; Statistics input pre-fill is a future extension. 14+ tests. |

## Pickup points — next strategic slot

P7 done. P6 rounds 93+94+95 shipped. Order below is roughly
by follow-on value.

1. **Round 96 — Function Reference data model + scaffolding**.
   New `lib/engine/function_reference.dart` with `FunctionRef`
   + `FunctionRefCategory` enum (9 categories). Plus a
   `FunctionReferenceDialog` widget mirroring the worked-
   examples layout. Cards link to a "Try in Calculator" deep-
   link (`AppState.pendingInsertExpression`) and a "See worked
   example" cross-link. This is the foundation for rounds
   97-100.

2. **Round 97 — CAS function entries (the meat)**.
   ~15 entries for the CAS category alone: `solve`, `expand`,
   `simplify`, `factor`, `diff`, `integrate`, `subst`,
   `limit`, `series`, `taylor`, `gcd`, `lcm`, `factorial`,
   `fibonacci`, + precision-arc set.

3. **Round 114 — P7 Function Reference + help-mode wiring**
   (depends on Round 97 landing first).

4. **Rounds 98-100** — Matrix + statistics + constraints +
   sudoku entries + i18n pass.

5. **Round 95 follow-up — Statistics input pre-fill**. The V1
   stops at tab-pick; if a real demand surfaces, the
   `pendingStatisticsTab` slot could grow to carry a JSON-ish
   payload with sample-data overrides. Defer until needed.

6. **CSP Round E.5** (deferred) — bundle `dart_csp_fzn` CLI
   as a MiniZinc solver. Blocked on P4 distribution pipeline.

7. **P9 follow-ups** (A5d / A7 / A8) — 3D Scene polish.

8. **Precision arc round 4** (`modpow` / `modinv` / `totient` /
   `jacobi`) — multi-repo. See `HANDOFF_PRECISION.md`. Cross-
   repo arc; ask before starting.

## Known issues / context

### P7 (rounds 110-113)

- **Symbolic `if(...)` doesn't render usefully.** When the
  condition stays symbolic, `tryFoldIfConditional` returns
  null and the original `if(...)` form flows to SymEngine,
  which doesn't understand it. Acceptable V1.
- **Bool-chip detection is a string match** on `'true'`/
  `'false'`. `normalizeBooleanResult` runs before the cache
  write so the lowercase form reaches the chip path.
- **Arithmetic-with-boolean is uncoerced.** Documented in
  PLAN P7 Round 113.
- **`if(cond, t, e)` requires the engine.** Headless tests
  use a stub evaluator.

### P6 (rounds 93-95)

- **Calculator top toolbar now always renders** (was guarded
  by `history.isNotEmpty`). Needed so the worked-examples
  icon is reachable from cold start.
- **`menu_book_outlined`, not `help_outline`.** Round 101's
  future help-mode toggle will use `help_outline`.
- **`numberTheory`** is in the notepad allowlist beyond
  PLAN's `{calculus, algebra, linearAlgebra}` spec — P7 +
  precision arc both ship `numberTheory` entries that work
  inline in notepad.
- **Round 95 sentinel parser is lenient.** Unknown keys are
  silently ignored — `open:sudoku?foo=bar` opens Sudoku with
  no pre-load. Typos in catalog entries degrade gracefully
  rather than crashing.
- **Statistics pre-load is tab-pick only.** Input fields use
  their built-in default sample data; no AppState payload for
  overriding them yet. A future round can extend
  `_pendingStatisticsTab` to a richer payload if needed.
- **Sudoku initState writes to `late` fields directly.** Dart's
  `late` semantics: assigning before reading skips the
  initialiser, which is what we want — `_clueIndexes` /
  `_baseCells` / `_displayed` get the killer-preset values
  before the first build. Not using `setState` in `initState`
  per Flutter convention.

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
- **Worked Examples dialog**: `lib/widgets/worked_examples_dialog.dart`
  (Round 94: `WorkedExamplesSurface` enum + `surface:` ctor
   parameter + `_allowedCategories()`; Round 95: sentinel
   parser with `?key=value` suffix in `_insert`)
- **AppState pending slots**: `lib/engine/app_state.dart`
  (Round 95: `_pendingSudokuPresetId`,
   `_pendingStatisticsTab`)
- Calculator: `lib/screens/calculator_screen.dart`
- Notepad: `lib/screens/notepad_screen.dart`
- **Sudoku receiver**: `lib/screens/sudoku_screen.dart`
  (Round 95: new `initState` drains the preset slot before
   first build)
- **Statistics receiver**: `lib/screens/statistics_screen.dart`
  (Round 95: `initState` sets `_tabs.index` from the pending
   tab slot)
- Calculator keypad: `lib/widgets/calculator_keypad.dart`
- Notepad classifier: `lib/engine/notepad_evaluator.dart`
- Worked-examples catalog: `lib/engine/worked_examples.dart`
  (Round 95: `killerSudoku` and new `statsHypothesisTests`
   entry)
- Localization: `lib/localization/app_localizations.dart`
- Tests this session: `test/relational_preprocessor_test.dart`,
  `test/logical_preprocessor_test.dart`,
  `test/worked_examples_test.dart`,
  `test/boolean_chip_test.dart`,
  `test/notepad_screen_test.dart`,
  `test/worked_examples_dialog_test.dart`,
  `test/ui_flows_test.dart`,
  `test/app_state_test.dart` (Round 95 slot tests),
  `test/round_95_pre_load_test.dart` (Round 95 receivers +
   sentinel dispatch)

Good luck.
