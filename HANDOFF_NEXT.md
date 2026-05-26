# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (late) session** that finished
P7. Today's rounds: 110 (relational), 111 (logical), 112 (keypad
+ worked examples), 111b (conditional fold + descent bug fix),
and now **113 (notepad boolean integration)**. The longer-lived
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
| **main HEAD** | (this session — Round 113 + docs) |
| **Tests** | **1905 pass** (1810 → 1832 → 1856 → 1880 → 1898 → 1905 across rounds 110/111/112/111b/113) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (FlatZinc frontend + QuickXplain MUS) |
| **CI** | Round-113 push not yet observed; previous pushes were green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped

| Round | What |
|---|---|
| **Round 110** | Relational-operator preprocessor (P7 kickoff). `preprocessRelationalOperators` does a paren-depth-0 scan + longest-match rewrite of `==` `!=` `<=` `>=` `<` `>` into SymEngine's `Eq` `Ne` `Le` `Ge` `Lt` `Gt`. Calculator + notepad assignment regexes tightened with `=(?!=)`. New `normalizeBooleanResult` lowercases `True`/`False` for display. Calculator history renders bool results as a colored chip via `_buildBooleanChip`. 22 tests. |
| **Round 111** | Logical-operator preprocessor. `preprocessLogicalOperators` does a two-phase walk: phase A recurses into parens, phase B splits at depth 0 in precedence order (`or` < `xor` < `and`) and checks for leading `not`, then falls through to the relational rewrite at the leaf. Python-style precedence. Chained collapse to n-ary `And`/`Or`/`Xor`. Calculator + notepad swapped from the relational call to the combined entry point. 24 tests. |
| **Round 112** | Adv-keypad keys + worked examples for P7. Ten new Adv keys (`==`, `≠`, `<`, `≤`, `>`, `≥`, `and`, `or`, `not`, `xor`) with glyph labels + ASCII insertion. Four worked-examples entries (boolean predicates) in the `numberTheory` category, localized en/de/fr/es. |
| **Round 111b** | `if(cond, t, e)` Dart-side fold + paren-descent comma-split fix. `tryFoldIfConditional(input, evaluator)` detects an `if(...)` call spanning the whole input, runs the condition through the engine, and returns the chosen branch trimmed (or null for symbolic / non-if). Calculator + notepad both call it after the boolean rewrite. The descent into paren-groups now splits the inner content by top-level commas before recursing — fixes the latent `Min(2 == 2, x + 1)` mangling and makes `if(...)` args lower correctly. New `if` Adv key + `booleanIfFold` worked example. Cap test bumped 40→50. 18 tests. |
| **Round 113** | Notepad boolean integration. Lifted calculator's `_buildBooleanChip` to a shared `lib/widgets/boolean_chip.dart` (`BooleanChip`). `notepad_screen.dart::_buildResult` now branches on `trimmedRes == 'true' \|\| trimmedRes == 'false'` and renders the chip (font 16 to match notepad's surrounding text; calc still defaults to 18). Calculator's `_buildBooleanChip` collapses to a single `Align(BooleanChip(...))`. **Arithmetic-with-boolean coercion**: V1 decision is **no coercion** — pass through whatever SymEngine returns (symbolic form or error). Promoting bool→int can be revisited if a real user surface demands it. 7 tests (+4 chip widget, +3 notepad render). |

## Pickup points — next strategic slot

P7's engine + UI is complete. The remaining piece (Round 114)
is gated on P6 round 97. Below is the order by follow-on
value.

1. **Round 114 — Function Reference + help-mode wiring** (depends
   on P6 round 97 landing first). Catalog entries for every
   relational + logical operator + `if`; help-mode popovers
   showing truth tables on the new logic buttons.

2. **P6 rounds 93-95** — Move Worked Examples out of Settings.
   Three small rounds, independent of P7. Now that P7 has added
   5 worked-examples entries, surfacing the dialog via a `(?)`
   icon on Calculator + Notepad is a higher-leverage win. This
   is the most natural next round to pick up.

3. **CSP Round E.5** (deferred) — bundle `dart_csp_fzn` CLI as a
   MiniZinc solver. Blocked on P4 distribution pipeline.

4. **P9 follow-ups** (A5d / A7 / A8) — 3D Scene polish.

5. **Precision arc round 4** (`modpow` / `modinv` / `totient` /
   `jacobi`) — multi-repo. See `HANDOFF_PRECISION.md`. Cross-repo
   arc; ask before starting.

## Known issues / context (P7)

- **Symbolic `if(...)` doesn't render usefully.** When the
  condition stays symbolic (`if(x == 5, ...)` with `x` free),
  `tryFoldIfConditional` returns null and the original
  `if(...)` form flows to SymEngine, which doesn't understand
  it and surfaces an error. Acceptable V1; a future round
  could keep the symbolic form as a structured piecewise.
- **Bool-chip detection is a string match.** Both calculator
  and notepad key on `entry.result.trim()` / `res.trim() ==
  'true'`/`'false'`. `normalizeBooleanResult` runs *before*
  the cache write so the lowercase form is what reaches the
  chip path. If something ever skips that normalize call, the
  `True`/`False` from SymEngine will fall through to Math.tex
  (notepad) or plain text (calc).
- **Arithmetic-with-boolean is uncoerced.** `1 + (2 == 2)` is
  whatever SymEngine returns — usually symbolic. Not promoted
  to 1 + 1 = 2. The V1 decision is documented in PLAN P7
  Round 113.
- **Word-boundary safety.** `random` / `factor` / `notation` are
  safe from accidental rewrites. Variables literally named
  `and`/`or`/`xor`/`not` would collide; users would notice fast
  enough.
- **`if(cond, t, e)` requires the engine** to be loaded. Headless
  `flutter test` runs without SymEngine, so end-to-end folding
  is verified only on-device — the unit tests use a stub
  evaluator and verify the dispatch shape.

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
   `preprocessLogicalOperators`; Round 111b:
   `_splitTopLevelByComma`, `tryFoldIfConditional`)
- **Shared boolean chip widget**: `lib/widgets/boolean_chip.dart`
  (Round 113: `BooleanChip` — `value`, `fontSize`)
- Calculator dispatch: `lib/screens/calculator_screen.dart`
  (P7: assignment-regex tighten + `_buildBooleanChip` collapses
   to `Align(BooleanChip(...))` + dispatch cases for the new
   keys + `tryFoldIfConditional` hook)
- Calculator keypad: `lib/widgets/calculator_keypad.dart`
  (P7: 11 new keys appended to `_advKeys`)
- Notepad dispatch: `lib/screens/notepad_screen.dart`
  (P7: combined rewrite + `tryFoldIfConditional` hook in
   `_dispatcher`'s `preNative` + `normalizeBooleanResult` at
   evaluate tail; Round 113: bool-chip branch in `_buildResult`)
- Notepad classifier: `lib/engine/notepad_evaluator.dart`
  (Round 110: `_assignmentRegex` tightened with `(?!=)`)
- Worked-examples catalog: `lib/engine/worked_examples.dart`
  (P7: 5 new boolean* entries in numberTheory category)
- Localization: `lib/localization/app_localizations.dart`
  (P7: titles + descriptions for 5 new ids × 4 locales)
- Tests this session: `test/relational_preprocessor_test.dart`,
  `test/logical_preprocessor_test.dart`,
  `test/worked_examples_test.dart` (cap bump),
  `test/boolean_chip_test.dart`,
  `test/notepad_screen_test.dart` (Round 113 chip render)

Good luck.
