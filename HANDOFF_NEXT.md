# CrispCalc — handover for the next session

Single-shot briefing from the **2026-05-26 (late) session** that
shipped Round E end-to-end plus Round 91 (precision-arc parser
binding). The longer-lived `HANDOFF.md` is still the load-bearing
reference for repo conventions; this file is a focused pickup note
for what to do *next*.

---

## ⚠ Working-mode change

**Parallel-arc work is paused.** All edits now go **directly on
`main`** in `/Volumes/backups/code/CrispCalc`. The old "create a
feature branch / worktree for every round" rule (HANDOFF §0a) is
suspended until the user reactivates the parallel worker. The
existing feature-branch worktrees stay on disk as reference but
have been trimmed (`build/` + `.dart_tool/` removed — about 635
MB reclaimed). `flutter pub get` regenerates them if anyone wants
to resume on a side branch.

If you accidentally start editing in a feature-branch worktree,
either move the edits to `/Volumes/backups/code/CrispCalc` or
remind yourself the user wants main.

---

## State

| | |
|---|---|
| **Main worktree** | `/Volumes/backups/code/CrispCalc` (branch `main`) |
| **main HEAD** | `c53bb2c` Round 92 (P6) Adv-keypad + worked-examples for precision arc |
| **Tests** | **1810 pass** (1708 → 1810 across Round E.1 + E.2 + E.3 + E.4-inline + Round 91 + Round 92) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (HEAD with FlatZinc frontend + QuickXplain MUS) |
| **CI** | Round-91 push at `c8ccd6c` not yet observed; previous push was green |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped (full day total: 9 commits)

| Round | Commit | What |
|---|---|---|
| Prereq | `2ca864f` | Bumped `dart_csp` pin from `e3cce21` → `69a9cfb`. |
| **E.1** | `e853874` | New 4th "FlatZinc" tab on `ConstraintsScreen` — paste FlatZinc source, hit Solve, see standard output. Two gallery entries (NQueens-4, Bin-packing). 4 tests. |
| **E.4 inline** | `d90280b` | Notepad `fzn:` directive — multi-line FlatZinc per row, exports scalar `output_var` bindings into doc scope so downstream lines can reference solved values by name. 18 tests. |
| Docs | `82de781` | PLAN.md prereq + E.1 + E.4-inline marks. |
| Docs | `8bb2fb3` | HANDOFF refresh (mid-day). |
| **E.2** | `7fa290f` | QuickXplain MUS "Why no solution?" panel for all four Constraints tabs. Four new `CspSolver.explain*` methods rebuild the Problem with `label:` threaded through every add* call. Shared `_ExplainSection` widget. 12 tests. |
| **E.3** | `6f6be22` | DSL → FlatZinc export. New `DslToFlatZinc.export(input)` produces a paste-ready `.fzn` model with full operator coverage (vars / allDifferent / linear ==/<=/>=/</>/!= / noOverlap→disjunctive / cumulative / minimize·maximize via synthetic `__obj__`). 20 tests including 3 round-trip through `FlatZinc.solve`. |
| Docs | `ff7d645` | PLAN.md E.2 + E.3 marks. |
| Docs | `23ef461` | HANDOFF refresh (after E.2 + E.3). |
| **Round 91** | `c8ccd6c` | Precision-arc parser binding — `pi(N)` / `e(N)` / `EulerGamma(N)` / `sqrt(2,N)` / `isprime(n)` / `nextprime(n)` / `prevprime(n)` / `factorint(n)` now route to the round-85/86/89/90 wrappers from calculator + notepad input. factorint formats as `2³ · 3² · 5` with Unicode superscripts. 18 tests. |
| **Round 92** | `c53bb2c` | Adv-keypad buttons + worked-examples surfacing for the same 8 functions. Seven new Adv-tab keys (π(N), e(N), γ(N), √(2,N), nextprime, prevprime, factorint; existing `prime` covers isprime); each inserts a template with cursor between parens. Five new worked-examples entries (piPrecision, ePrecision, factorint360, nextprime1000, mersenneM31) localized en/de/fr/es. Catalog cap raised 30→40. |

## Pickup points — next strategic slot

With Round E complete (modulo E.5 distribution play) and the
precision-arc surfacing landed (rounds 91 + 92), the natural
follow-ons:

1. **Round 110 — Booleans (P7 kickoff)**. Preprocessor maps
   `a == b` → `Eq(a, b)`, `a and b` → `And(a, b)`, etc.;
   `true` / `false` render as colored chips in history. P7's
   5-round arc; round 110 is the engine-only piece.
2. **P6 rounds 93-95 — Move Worked Examples out of Settings**.
   `(?)` icon on Calculator + Notepad opens the existing dialog;
   the Settings entry stays as a soft link. Three small rounds
   building on the round-92 catalog growth.
3. **CSP Round E.5** (deferred) — bundle `dart_csp_fzn` CLI as a
   MiniZinc solver. Blocked on P4 distribution pipeline.
4. **P9 follow-ups** (A5d / A7 / A8) — 3D Scene polish.
5. **Precision arc round 4** (`modpow` / `modinv` / `totient` /
   `jacobi`) — multi-repo. See `HANDOFF_PRECISION.md`. The user
   paused parallel work; this would be a cross-repo arc, ask
   before starting.

## Known issues / context (Round 91)

- **`tryEvaluatePrecisionCall` is top-level only by design.** An
  in-expression call like `pi(50) + 1` falls through to the
  existing preprocessor + SymEngine path. Substituting `'true'`,
  `'false'`, or a Unicode-superscript-formatted string mid-
  expression doesn't always make algebraic sense; we keep
  SymEngine the only expression evaluator. If a future round
  wants in-expression precision-constant substitution (the
  numeric `pi(N)` / `e(N)` / etc. would be safe), extend
  this method with a separate substitution pass that only
  replaces the numeric-constant forms.
- **`NotepadScreenState` now instantiates a `CalculatorEngine`
  on the main isolate** purely for the precision-arc pre-pass.
  Heavy CAS calls still route through `EngineService`'s worker
  isolate. If the precision pre-pass gets bigger (e.g.
  computes `pi(10000)`, which is a few hundred ms), consider
  moving it to the worker as well via `EngineOp`.
- **Case-sensitive.** `PI(50)` and `Eulergamma(20)` fall
  through; only the canonical `pi` / `e` / `EulerGamma`
  spellings are intercepted. Matches the rest of the
  expression preprocessor.

## Hygiene reminders

- **`dart format`** before push. Format only files you touched,
  not `lib/` wholesale (HANDOFF §4.17).
- **Don't run multiple `flutter test` in parallel** — they race
  on `.dart_tool/test/incremental_kernel_*` and all fail. Run
  sync or one at a time. Burnt me twice today.
- **Don't touch `.claude/`** — harness state.
- **Working on main now.** If you start a feature branch out of
  habit, ask first.

## Quick-reference paths

- CSP wrapper: `lib/engine/csp_solver.dart`
  (Round E.2: explain* methods; Round E.3: `DslToFlatZinc.export`)
- CSP UI: `lib/screens/constraints_screen.dart`
  (4 tabs incl. FlatZinc, `_ExplainSection`, `_MusBlock`,
  `_FlatZincExportBlock`)
- Calculator engine: `lib/engine/calculator_engine.dart`
  (Round 91: `tryEvaluatePrecisionCall`, `formatFactorint`)
- Calculator screen: `lib/screens/calculator_screen.dart`
  (Round 91 hook in `_calculate` before unit eval)
- Notepad evaluator: `lib/engine/notepad_evaluator.dart`
  (Round E.4: `NotepadLineKind.flatzinc`,
  `flatzincOutputVarsIn`, `parseFlatZincScalarOutputs`)
- Notepad screen: `lib/screens/notepad_screen.dart`
  (Round 91 hook in `_dispatcher`; main-isolate `_engine` field)
- Notepad data model: `lib/engine/notepad.dart`
  (Round E.4: `NotepadLine.cachedExports`)
- Localization: `lib/localization/app_localizations.dart`
  (en/de/fr/es)
- Tests this session: `test/flatzinc_tab_test.dart`,
  `test/notepad_flatzinc_test.dart`, `test/csp_mus_test.dart`,
  `test/dsl_to_flatzinc_test.dart`, `test/precision_call_pass_test.dart`

Good luck.
