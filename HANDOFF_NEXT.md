# CrispCalc — handover for the next session

Pickup note from the **2026-05-26 (late) session** that closed
out P7's engine work: rounds 110 (relational), 111 (logical),
112 (keypad + worked examples), and 111b (conditional fold +
descent bug fix). The longer-lived `HANDOFF.md` is still the
load-bearing reference for repo conventions.

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
| **main HEAD** | (this session — Round 111b + docs) |
| **Tests** | **1898 pass** (1810 → 1832 → 1856 → 1880 → 1898 across rounds 110/111/112/111b) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (FlatZinc frontend + QuickXplain MUS) |
| **CI** | Round-110 through 111b pushes not yet observed; previous push was green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped

| Round | What |
|---|---|
| **Round 110** | Relational-operator preprocessor (P7 kickoff). `preprocessRelationalOperators` does a paren-depth-0 scan + longest-match rewrite of `==` `!=` `<=` `>=` `<` `>` into SymEngine's `Eq` `Ne` `Le` `Ge` `Lt` `Gt`. Calculator + notepad assignment regexes tightened with `=(?!=)`. New `normalizeBooleanResult` lowercases `True`/`False` for display. Calculator history renders bool results as a colored chip via `_buildBooleanChip`. 22 tests. |
| **Round 111** | Logical-operator preprocessor. `preprocessLogicalOperators` does a two-phase walk: phase A recurses into parens, phase B splits at depth 0 in precedence order (`or` < `xor` < `and`) and checks for leading `not`, then falls through to the relational rewrite at the leaf. Python-style precedence. Chained collapse to n-ary `And`/`Or`/`Xor`. Calculator + notepad swapped from the relational call to the combined entry point. 24 tests. |
| **Round 112** | Adv-keypad keys + worked examples for P7. Ten new Adv keys (`==`, `≠`, `<`, `≤`, `>`, `≥`, `and`, `or`, `not`, `xor`) with glyph labels + ASCII insertion. Four worked-examples entries (boolean predicates) in the `numberTheory` category, localized en/de/fr/es. |
| **Round 111b** | `if(cond, t, e)` Dart-side fold + paren-descent comma-split fix. `tryFoldIfConditional(input, evaluator)` detects an `if(...)` call spanning the whole input, runs the condition through the engine, and returns the chosen branch trimmed (or null for symbolic / non-if). Calculator + notepad both call it after the boolean rewrite. The descent into paren-groups now splits the inner content by top-level commas before recursing — fixes the latent `Min(2 == 2, x + 1)` mangling and makes `if(...)` args lower correctly. New `if` Adv key + `booleanIfFold` worked example. Cap test bumped 40→50. 18 tests. |

## Pickup points — next strategic slot

P7's engine layer is done. The remaining piece is round 113
(notepad boolean integration). After that, P6 discoverability
or the deferred CSP / P9 tracks. Order below is roughly by
follow-on value.

1. **Round 113 — Notepad boolean integration.** Notepad result
   cells render bool chips like the calculator does — lift
   `_buildBooleanChip` to a shared widget (or duplicate). Plus
   the decision on what arithmetic-with-boolean coerces to
   (0/1 vs. error). Smallest remaining P7 piece.

2. **Round 114 — Function Reference + help-mode wiring** (depends
   on P6 round 97 landing first). Catalog entries for every
   relational + logical operator + `if`; help-mode popovers
   showing truth tables on the new logic buttons.

3. **P6 rounds 93-95** — Move Worked Examples out of Settings.
   Three small rounds, independent of P7. Now that P7 has added
   5 worked-examples entries, surfacing the dialog via a `(?)`
   icon on Calculator + Notepad is a higher-leverage win.

4. **CSP Round E.5** (deferred) — bundle `dart_csp_fzn` CLI as a
   MiniZinc solver. Blocked on P4 distribution pipeline.

5. **P9 follow-ups** (A5d / A7 / A8) — 3D Scene polish.

6. **Precision arc round 4** (`modpow` / `modinv` / `totient` /
   `jacobi`) — multi-repo. See `HANDOFF_PRECISION.md`. Cross-repo
   arc; ask before starting.

## Known issues / context

- **Symbolic `if(...)` doesn't render usefully.** When the
  condition stays symbolic (`if(x == 5, ...)` with `x` free),
  `tryFoldIfConditional` returns null and the original
  `if(...)` form flows to SymEngine, which doesn't understand
  it and surfaces an error. Acceptable V1; a future round
  could keep the symbolic form as a structured piecewise.
- **History chip rendering is calculator-only.** Notepad result
  cells still show `true` / `false` as plain text. Round 113
  brings the chip there.
- **Chip detection key is the lowercase string.** Bool-chip
  rendering keys on `entry.result.trim() == 'true'/'false'`.
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
- Calculator dispatch: `lib/screens/calculator_screen.dart`
  (P7: assignment-regex tighten + `_buildBooleanChip` + dispatch
   cases for the new keys + `tryFoldIfConditional` hook)
- Calculator keypad: `lib/widgets/calculator_keypad.dart`
  (P7: 11 new keys appended to `_advKeys`)
- Notepad dispatch: `lib/screens/notepad_screen.dart`
  (P7: combined rewrite + `tryFoldIfConditional` hook in
   `_dispatcher`'s `preNative` + `normalizeBooleanResult` at
   evaluate tail)
- Notepad classifier: `lib/engine/notepad_evaluator.dart`
  (Round 110: `_assignmentRegex` tightened with `(?!=)`)
- Worked-examples catalog: `lib/engine/worked_examples.dart`
  (P7: 5 new boolean* entries in numberTheory category)
- Localization: `lib/localization/app_localizations.dart`
  (P7: titles + descriptions for 5 new ids × 4 locales)
- Tests this session: `test/relational_preprocessor_test.dart`,
  `test/logical_preprocessor_test.dart`,
  `test/worked_examples_test.dart` (cap bump)

Good luck.
