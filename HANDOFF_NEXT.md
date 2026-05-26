# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (late) session** that shipped
Round 110 (P7 kickoff — relational operators) on top of the
already-shipped Round E (FlatZinc + MUS) and Rounds 91-92
(precision-arc surfacing). The longer-lived `HANDOFF.md` is still
the load-bearing reference for repo conventions; this file is a
focused pickup note for what to do *next*.

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
| **main HEAD** | (this session — Round 110 + docs) |
| **Tests** | **1832 pass** (1810 → 1832 from Round 110's 22 new tests) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (FlatZinc frontend + QuickXplain MUS) |
| **CI** | Round-110 push not yet observed; previous push was green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped (Round 110)

| Round | What |
|---|---|
| **Round 110** | Relational-operator preprocessor (P7 kickoff). New `ExpressionPreprocessingUtils.preprocessRelationalOperators` does a paren-depth-0 scan + longest-match rewrite of `==` `!=` `<=` `>=` `<` `>` into SymEngine's `Eq` `Ne` `Le` `Ge` `Lt` `Gt`. Calculator + notepad assignment regexes tightened with `=(?!=)` so `x == 1` doesn't get pulled into the assignment route. New `normalizeBooleanResult` lowercases SymEngine's `True` / `False` for display consistency. Calculator history renders bool results as a colored chip (secondaryContainer / errorContainer) via `_buildBooleanChip`. 22 tests. |

## Pickup points — next strategic slot

P7 is mid-arc; rounds 111-114 are the obvious next steps.
Alternatives below if the user wants to switch tracks.

1. **Round 111 — logical operators + conditional** (next P7
   step). Preprocessor maps `a and b` → `And(a, b)`,
   `a or b` → `Or(a, b)`, `a xor b` → `Xor(a, b)`, `not a`
   → `Not(a)`, `if(c, t, e)` → `Piecewise((t, c), (e, true))`.
   Round 110 already shows `x < 5 and y > 3` rewrites only the
   first relational — round 111 closes that gap by handling the
   logical connective. Should be straightforward following the
   same scan-at-depth-0 pattern.
2. **Round 112 — Boolean keypad + worked examples**. New Adv-tab
   keys (`==`, `!=`, `<`, `>`, `and`, `or`, `not`, `xor`, `if`)
   plus 3-4 classroom-flavored worked-example entries
   (`isprime(17) and 17 < 20`, etc.).
3. **Round 113 — Notepad boolean integration**. Notepad result
   cells render bool chips like the calculator does. Plus the
   decision on what arithmetic-with-boolean coerces to
   (0/1 vs. error).
4. **P6 rounds 93-95** — Move Worked Examples out of Settings.
   Three small rounds, independent of P7.
5. **CSP Round E.5** (deferred) — bundle `dart_csp_fzn` CLI as a
   MiniZinc solver. Blocked on P4 distribution pipeline.
6. **P9 follow-ups** (A5d / A7 / A8) — 3D Scene polish.
7. **Precision arc round 4** (`modpow` / `modinv` / `totient` /
   `jacobi`) — multi-repo. See `HANDOFF_PRECISION.md`. Cross-repo
   arc; ask before starting.

## Known issues / context (Round 110)

- **First-top-level-operator wins.** `x < 5 and y > 3` currently
  rewrites to `Lt(x, 5 and y > 3)` — SymEngine will reject this
  because the `and` isn't yet a function call. Round 111 fixes
  the chained case by recursing on the RHS once logical ops
  are lowered too. For now the scope is single-relational
  inputs, which covers the common classroom case.
- **Inside-parens not lifted.** `(x < 5)` stays as `(x < 5)` and
  SymEngine handles the parenthesized form natively. Only the
  top-level scan is rewritten.
- **`=(?!=)` tightening.** Both `calculator_screen.dart`'s
  assignment regex and notepad's `_assignmentRegex` got a
  negative-lookahead on `==` so the double-equal stays in the
  expression path. Any other code that pattern-matches `=` for
  assignment-like syntax should pick up the same fix.
- **History chip rendering is calculator-only.** Notepad result
  cells still show `true` / `false` as plain text. Round 113
  brings the chip there.
- **SymEngine prints `True`/`False` (capitalized);** the codebase
  convention is lowercase. `normalizeBooleanResult` does the
  conversion at the end of the calculator + notepad dispatchers
  so the chip detection (`entry.result.trim() == 'true'`) and
  any downstream lookups see the canonical form.

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

- Relational preprocessor: `lib/utils/expression_preprocessing_utils.dart`
  (Round 110: `preprocessRelationalOperators`, `normalizeBooleanResult`)
- Calculator dispatch: `lib/screens/calculator_screen.dart`
  (Round 110: `_calculate` hook + tightened assignment regex
   + `_buildBooleanChip` + history chip render branch)
- Notepad dispatch: `lib/screens/notepad_screen.dart`
  (Round 110: relational rewrite in `_dispatcher`'s `preNative`
   + `normalizeBooleanResult` at evaluate tail)
- Notepad classifier: `lib/engine/notepad_evaluator.dart`
  (Round 110: `_assignmentRegex` tightened with `(?!=)`)
- Tests this session: `test/relational_preprocessor_test.dart`

Good luck.
