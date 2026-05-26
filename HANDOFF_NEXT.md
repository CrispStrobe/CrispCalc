# CrispCalc — handover for the next session

Single-shot briefing from the **2026-05-26 (afternoon) session** that
shipped CSP Round E's first chunk. The longer-lived `HANDOFF.md` is
still the load-bearing reference for repo conventions; this file is
a focused pickup note for what to do *next*.

---

## State

| | |
|---|---|
| **Main worktree** | `/Volumes/backups/code/CrispCalc` (branch `main`) |
| **Feature worktree (reusable)** | `/Volumes/backups/code/CrispCalc-csp-e` (branch `feat/csp-round-e`) |
| **Notepad worktree (kept in sync)** | `/Volumes/backups/code/CrispCalc-notepad-phase-1` (branch `feature/notepad-phase-1`) |
| **All three branches HEAD** | `82de781` docs: PLAN — Round E shipped marks |
| **Tests** | **1730 pass** (1708 carried + 4 FlatZinc-tab + 18 fzn-evaluator), `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (HEAD with FlatZinc frontend + QuickXplain MUS) |
| **CI** | green at the end of the previous session; this session pushed in one batch, watch the first run |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped (4 commits)

| Round | Commit | What |
|---|---|---|
| Prereq | `2ca864f` | Bumped `dart_csp` pin from `e3cce21` → `69a9cfb`. Full suite green; no `Problem` API drift. |
| **E.1** | `e853874` | New 4th "FlatZinc" tab on `ConstraintsScreen`. Textarea + Solve + `All solutions` FilterChip + 2-entry gallery (NQueens-4 with diagonals via `int_lin_ne`; Bin-packing via `bin_packing_load`). Result-block header switches between "First solution" / "N solutions (exhaustive)" / "Unsatisfiable" by inspecting the trailer. Localized en/de/fr/es (7 chrome keys + 2 gallery titles). 4 tests in `test/flatzinc_tab_test.dart`. |
| **E.4 (inline variant)** | `d90280b` | Notepad lines starting with `fzn:` get sent to dart_csp's FlatZinc frontend. TextField's `maxLines: null` means a single notepad row can carry multi-line FlatZinc — no multi-line cell model needed for V1. New `NotepadLineKind.flatzinc` + `NotepadLine.cachedExports` (JSON-persisted, key `'x'`) + `NotepadFlatZincDispatcher`. `buildNotepadScope` merges exports so downstream lines reference solved values by their FlatZinc names. Output_array values stay in formatted text but don't enter scope. Unsatisfiable → standard `blockedBy` chip on dependents. 18 tests in `test/notepad_flatzinc_test.dart`. |
| Docs | `82de781` | PLAN.md struck prereq + E.1 + E.4-inline; E.4 multi-line cell variant now noted as deferred-V2 since the inline variant already handles multi-line bodies. |

## Pickup points — Round E continuation

PLAN.md → search `CSP Round E`. What's left:

1. **E.2 — "Why no solution?" panel using QuickXplain MUS** (~1 day).
   When a Diophantine/DSL/FlatZinc problem returns no solution, run
   QuickXplain over the labeled constraints and surface the minimal
   conflicting subset inline. Requires threading `ConstraintRef`
   labels through every `addConstraint` / `addLinearEquals` /
   `addAllDifferent` call in `lib/engine/csp_solver.dart`. The
   dart_csp pin already has QuickXplain since the bump (commits
   `66b1a31` + `47beb59` + `a483980`). "Explain failure" button on
   the result block, only fires on unsat (running QuickXplain isn't
   free).
2. **E.3 — DSL → FlatZinc export** (~½ day). "Export as FlatZinc"
   button on the DSL tab result panel. Emits a `.fzn` text the user
   can paste into Choco/Gecode/OR-Tools/MiniZinc IDE for
   cross-solver verification. Maps the existing DSL AST to FlatZinc
   declarations — algebraic since both share variables, linear
   constraints, `allDifferent`, `noOverlap` (FlatZinc's
   `disjunctive`), `cumulative`.
3. **E.5 — Bundle `dart_csp_fzn` CLI as a MiniZinc solver**. Deferred
   until P4 distribution pipeline lands (App Store / notarization).

After Round E, the strategic next slot is **P7 booleans** (5-round
arc starting at round 110) or **P6 discoverability** (15-round arc
starting at round 91). PLAN.md has both writeups.

## Known issues / context (Round E)

- **FlatZinc output_array values stay in the formatted text but
  don't enter Notepad scope.** A single FlatZinc array doesn't map
  cleanly to a scalar scope value, so we only export the scalar
  `:: output_var` annotations. If you need array values in scope
  later, the cleanest path is to also export them under
  `name[1]`, `name[2]`, ... keys, parsed from the `array1d(...)`
  output text.
- **`fzn:` detection is case-sensitive.** `FZN:` falls through to
  expression so the user gets a clean "name FZN not defined" error
  instead of silent miscategorization. Test `case-sensitive: FZN:
  is treated as an expression` locks this in.
- **`_flatzincScalarLineRegex` in `notepad_evaluator.dart`**
  deliberately disallows `(` in the value field so `array1d(...)`
  lines fall through. If FlatZinc ever adds a scalar value that
  needs parens (unlikely), revisit the regex.
- **NotepadScreen's `_buildResult` branches on
  `line.source.trimLeft().startsWith('fzn:')`** to route FlatZinc
  results to a monospace block instead of `Math.tex`. If you
  refactor the result renderer, preserve this branch (Math.tex on
  multi-line FlatZinc output renders as a fallback text block but
  with the wrong font / size).

## Hygiene reminders (unchanged from previous handoff)

- **`dart format`** before push — CI's "Verify formatting" step
  rejects unformatted files. Use `dart format <files-you-touched>`
  not `dart format lib/` to avoid sweeping unrelated user WIP into
  your diff (see HANDOFF §4.17).
- **Both branches in sync** — when you commit to `main`,
  fast-forward `feature/notepad-phase-1` in
  `/Volumes/backups/code/CrispCalc-notepad-phase-1` and push too.
  This session pushed both.
- **Don't touch `.claude/`** — harness state.

## Quick-reference paths

- Notepad UI: `lib/screens/notepad_screen.dart`
  (new: `_flatzincDispatcher`, `_buildFlatZincResult`)
- Notepad evaluator: `lib/engine/notepad_evaluator.dart`
  (new: `NotepadLineKind.flatzinc`, `NotepadFlatZincDispatcher`,
  `NotepadFlatZincResult`, `flatzincOutputVarsIn`,
  `parseFlatZincScalarOutputs`, `_evaluateFlatZincLine`)
- Notepad data model: `lib/engine/notepad.dart`
  (new: `NotepadLine.cachedExports` + JSON round-trip)
- CSP UI: `lib/screens/constraints_screen.dart`
  (new: `_FlatZincTab`, `_FlatZincErrorBlock`, `_FlatZincOutputBlock`)
- CSP wrapper: `lib/engine/csp_solver.dart`
  (untouched this session — E.2 will add `ConstraintRef` plumbing here)
- Localization: `lib/localization/app_localizations.dart`
  (7 new constraint keys × 4 locales)
- Tests: `test/flatzinc_tab_test.dart`, `test/notepad_flatzinc_test.dart`

Good luck.
