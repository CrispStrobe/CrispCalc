# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (late) session** that shipped
Rounds 110 + 111 (P7 — relational + logical operators) on top of
the already-shipped Round E (FlatZinc + MUS) and Rounds 91-92
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
| **main HEAD** | (this session — Round 111 + docs) |
| **Tests** | **1856 pass** (1810 → 1832 from Round 110, → 1856 from Round 111) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (FlatZinc frontend + QuickXplain MUS) |
| **CI** | Round-110 + 111 pushes not yet observed; previous push was green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped

| Round | What |
|---|---|
| **Round 110** | Relational-operator preprocessor (P7 kickoff). `preprocessRelationalOperators` does a paren-depth-0 scan + longest-match rewrite of `==` `!=` `<=` `>=` `<` `>` into SymEngine's `Eq` `Ne` `Le` `Ge` `Lt` `Gt`. Calculator + notepad assignment regexes tightened with `=(?!=)`. New `normalizeBooleanResult` lowercases `True`/`False` for display. Calculator history renders bool results as a colored chip (secondaryContainer / errorContainer) via `_buildBooleanChip`. 22 tests. |
| **Round 111** | Logical-operator preprocessor. `preprocessLogicalOperators` does a two-phase walk: phase A recurses into parens, phase B splits at depth 0 in precedence order (`or` < `xor` < `and`) and checks for leading `not`, then falls through to the relational rewrite at the leaf. Python-style precedence (`not` binds tighter than `and`; relational tighter than `not`). Chained collapse to n-ary `And`/`Or`/`Xor`. Calculator + notepad swapped from the relational call to the combined logical entry point. 24 tests. |

## Pickup points — next strategic slot

P7 is in mid-flight; the remaining round is Round 112 (keypad +
worked examples) and Round 113 (notepad boolean integration).
Plus the deferred Round 111b. Alternatives if the user wants to
switch tracks are listed below.

1. **Round 111b — `if(cond, thenExpr, elseExpr)`** (deferred from
   111). Lowering to `Piecewise(...)` is blocked because
   SymEngine's text parser doesn't recognize `Piecewise`. Clean
   path: a Dart-side `_evaluateIfConditional(s)` that recognizes
   `if(...)` at the top level, evaluates the condition first
   (via `preprocessLogicalOperators` + `EngineService`), and
   returns `thenExpr` / `elseExpr` based on whether the result
   is `true` / `false`. Symbolic conditions stay as `if(...)`
   unchanged. Tested via condition-folding.
2. **Round 112 — Boolean keypad + worked examples**. New Adv-tab
   keys (`==`, `!=`, `<`, `>`, `and`, `or`, `not`, `xor`, `if`)
   plus 3-4 classroom-flavored worked-example entries
   (`isprime(17) and 17 < 20`, etc.). Pattern matches the
   round-92 keypad/worked-examples surfacing.
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

## Known issues / context (Rounds 110 + 111)

- **`if(cond, t, e)` not yet handled.** Round 111 deliberately
  stops at `not`/`and`/`or`/`xor`. The PLAN suggested lowering
  to SymEngine `Piecewise(...)` but the text parser doesn't
  expose it — the C++ class exists, the parser registration
  doesn't. Round 111b will fold the condition Dart-side.
- **Inside-parens not lifted (round 110 relational).** `(x < 5)`
  stays as `(x < 5)` after the relational pass — but
  `preprocessLogicalOperators` now recurses into parens, so the
  inner `<` does get rewritten when round-111 runs. Net result:
  `(x < 5)` → `(Lt(x, 5))`. SymEngine accepts either form.
- **History chip rendering is calculator-only.** Notepad result
  cells still show `true` / `false` as plain text. Round 113
  brings the chip there.
- **Chained mixed-precedence collapses correctly.** `a and b and
  c` → `And(a, b, c)` (n-ary). `a or b and c` → `Or(a, And(b,
  c))`. Trace test cases live in
  `test/logical_preprocessor_test.dart`.
- **Word-boundary safety.** `random` / `factor` / `notation` are
  safe — the splitter checks both sides for `[A-Za-z0-9_]`. New
  reserved words: `and`, `or`, `xor`, `not`. A variable literally
  named one of these would collide; users would notice fast
  enough.

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
  (Round 110: `preprocessRelationalOperators`,
   `normalizeBooleanResult`; Round 111:
   `preprocessLogicalOperators`, private helpers
   `_logicalDescendIntoParens`, `_logicalTopLevel`,
   `_splitAtTopLevelWord`)
- Calculator dispatch: `lib/screens/calculator_screen.dart`
  (Round 110/111: `_calculate` hook + tightened assignment
   regex + `_buildBooleanChip` + history chip render branch)
- Notepad dispatch: `lib/screens/notepad_screen.dart`
  (Round 110/111: combined rewrite in `_dispatcher`'s
   `preNative` + `normalizeBooleanResult` at evaluate tail)
- Notepad classifier: `lib/engine/notepad_evaluator.dart`
  (Round 110: `_assignmentRegex` tightened with `(?!=)`)
- Tests this session: `test/relational_preprocessor_test.dart`,
  `test/logical_preprocessor_test.dart`

Good luck.
