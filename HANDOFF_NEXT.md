# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (late) session**. Closed P7
end-to-end and shipped four sub-rounds of P6 (worked-examples
discoverability + Function Reference scaffolding). Today's
rounds:

- **110, 111, 111b, 112, 113** — P7 booleans (relational +
  logical operators, `if(...)` fold, Adv-keypad keys, worked
  examples, notepad chip rendering).
- **93, 94, 95** — P6 worked-examples discoverability (icon on
  Calculator + Notepad, surface-scoped filtering, per-module
  pre-loading via parameterised sentinels).
- **96** — P6 Function Reference scaffolding (model + dialog +
  3-entry seed).

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
| **main HEAD** | (this session — Round 96 + docs) |
| **Tests** | **1949 pass** (1810 → 1832 → 1856 → 1880 → 1898 → 1905 → 1911 → 1931 → 1944 → 1949) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (FlatZinc frontend + QuickXplain MUS) |
| **CI** | Round 96 push not yet observed; previous pushes were green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped

| Round | What |
|---|---|
| **Round 110** | Relational-operator preprocessor (P7 kickoff). |
| **Round 111** | Logical-operator preprocessor (two-phase walk; n-ary And/Or/Xor). |
| **Round 112** | Adv-keypad keys + worked examples for P7. |
| **Round 111b** | `if(cond, t, e)` Dart-side fold + paren-descent comma split. |
| **Round 113** | Notepad boolean integration via shared `BooleanChip`. |
| **Round 93** | Worked Examples library out of Settings — `menu_book_outlined` icon on Calculator top toolbar + Notepad AppBar. |
| **Round 94** | Surface-scoped filtering. `WorkedExamplesSurface` enum, notepad allowlist. |
| **Round 95** | Per-module pre-loading via parameterised sentinels. New AppState slots, receivers on Sudoku + Statistics. |
| **Round 96** | Function Reference scaffolding. New `FunctionRef` model + 9-category enum + 3-entry seed list (`solve` / `isprime` / `pi_precision`). New `FunctionReferenceDialog` widget mirroring worked-examples layout but with ExpansionTile rows for the detail panel. "Try in Calculator" deep-link reuses `AppState.requestInsertExpression`. "See worked example" cross-link wired via a new `workedExampleId` field on `FunctionRef`. Reach-point in Settings (Round 101 will surface it via help-mode toggle). 11 i18n strings × 4 locales. 13 tests (+7 catalogue invariants, +6 dialog widget). |
| **Round 96 follow-up** | Tightened the See-worked-example cross-link. `WorkedExamplesDialog` gained an `initialSearch: String?` ctor param (pre-fills the search field on open) + id-based filter search (locale-independent). `FunctionReferenceDialog._openWorkedExample` now passes the linked id as `initialSearch`, so the cross-link surfaces exactly the related entry filtered. 5 tests (+4 dialog initialSearch, +1 end-to-end cross-link). |

## Pickup points — next strategic slot

P6 rounds 93-96 done; Round 97 is the natural next slot.

1. **Round 97 — CAS function entries (the meat)**.
   ~15 entries for the CAS category alone: `solve`,
   `expand`, `simplify`, `factor`, `diff`, `integrate`,
   `subst`, `limit`, `series`, `taylor`, `gcd`, `lcm`,
   `factorial`, `fibonacci`, plus the precision-arc set.
   Each gets 2-3 examples + the "how SymEngine implements
   this" one-paragraph explanation. PLAN says these
   explanations are NOT the math itself — they're "in
   CrispCalc, `solve(x^2 - 1, x)` returns `[-1, 1]`; the
   underlying call is SymEngine's `solve_poly()`...".
   - Round 96 already shipped `solve` and `pi_precision`
     entries; Round 97 fills in the rest and may upgrade
     these two with richer prose.
   - PLAN P7 Round 114 (relational + logical operator
     entries + truth-table help mode) is a separate slice;
     it depends on Round 97 landing first.

2. **Round 98 — Matrix + linear algebra entries**.
   `det`, `inv`, `transpose`, `rref`, `Matrix([[…]])`
   syntax, eigenvalues (if shipped). ~8 entries.

3. **Round 99 — Statistics + Constraints + Sudoku entries**.
   ~15 more entries covering the module functions.

4. **Round 100 — i18n pass (~30k words)**. Triage:
   100a EN-only refinements, 100b DE, 100c FR+ES.

5. **Round 101 — Help-mode design + state**.
   `_helpMode` toggle on Calculator + Notepad AppBars
   (using `Icons.help_outline` — reserved for this).
   `HelpModeNotifier` in AppState.

6. **Rounds 102-104** — Help popovers on the keypad,
   history rows, and notepad lines.

7. **Round 95 follow-up** — Statistics input pre-fill.
   `pendingStatisticsTab` slot could grow to a richer
   payload. Defer until demand surfaces.

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

### P6 (rounds 93-96)

- **Calculator top toolbar always renders** (was guarded by
  `history.isNotEmpty`).
- **`menu_book_outlined`, not `help_outline`** — the latter
  is reserved for Round 101.
- **Round 95 sentinel parser is lenient**: unknown keys
  silently ignored.
- **Statistics pre-load is tab-pick only.** Input fields use
  built-in defaults.
- **`FunctionRef.workedExampleId` is an id pointer**, not a
  structured cross-link. Round 97 can grow this if needed.
- **Function Reference rows use ExpansionTile** (inline
  detail) instead of a side-by-side master/detail layout.
  Reasoning: at 560×480 the dialog isn't wide enough to
  split. If a wider-screen mode is wanted later, the row
  can detect `MediaQuery.size.width` and switch layouts.
- **Action buttons use `Wrap` (not `Row`)** in the row's
  detail area. The widget tester reproduced an overflow on
  the narrow dialog; `Wrap` reflows the buttons onto a
  second line at narrow widths.
- **`_openWorkedExample` is now deep-linked** — pops the
  Function Reference dialog and opens Worked Examples
  filtered down to exactly the linked entry. Done in the
  Round 96 follow-up via the new `initialSearch` ctor param
  on `WorkedExamplesDialog` + id-based filter search.

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
  (Round 96: `FunctionRef`, `FunctionRefCategory`,
   `FunctionRefExample`, `FunctionReferences.all`)
- **Function Reference dialog**: `lib/widgets/function_reference_dialog.dart`
  (Round 96: search + chip row + ExpansionTile rows + Try-in-
   Calculator + See-worked-example)
- AppState pending slots: `lib/engine/app_state.dart`
- Calculator: `lib/screens/calculator_screen.dart`
- Notepad: `lib/screens/notepad_screen.dart`
- Sudoku receiver: `lib/screens/sudoku_screen.dart`
- Statistics receiver: `lib/screens/statistics_screen.dart`
- Calculator keypad: `lib/widgets/calculator_keypad.dart`
- Notepad classifier: `lib/engine/notepad_evaluator.dart`
- Worked-examples catalog: `lib/engine/worked_examples.dart`
- Localization: `lib/localization/app_localizations.dart`
  (Round 96: 11 new strings × 4 locales)
- Tests this session: see HISTORY for the full list. The
  Round-96 additions are `function_reference_test.dart`
  (catalogue invariants) and `function_reference_dialog_test.dart`
  (widget behaviour).

Good luck.
