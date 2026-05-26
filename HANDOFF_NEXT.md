# CrispCalc — handover for the next session

Single-shot briefing from the **2026-05-26 (evening) session** that
shipped the remaining Round E chunks (E.2 + E.3). The longer-lived
`HANDOFF.md` is still the load-bearing reference for repo
conventions; this file is a focused pickup note for what to do
*next*.

---

## State

| | |
|---|---|
| **Main worktree** | `/Volumes/backups/code/CrispCalc` (branch `main`) |
| **Feature worktree (reusable)** | `/Volumes/backups/code/CrispCalc-csp-e` (branch `feat/csp-round-e`) |
| **Notepad worktree (kept in sync)** | `/Volumes/backups/code/CrispCalc-notepad-phase-1` (branch `feature/notepad-phase-1`) |
| **All three branches HEAD** | `ff7d645` docs: PLAN — Round E.2 + E.3 shipped |
| **Tests** | **1762 pass** (1730 → 1762 across E.2 + E.3) — `flutter analyze` clean |
| **dart_csp pin** | `69a9cfb` (HEAD with FlatZinc frontend + QuickXplain MUS — bumped earlier today) |
| **CI** | green at the previous push; this session pushed in two batches, watch for the first run |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped (4 commits on top of the morning's 5)

| Round | Commit | What |
|---|---|---|
| **E.2** | `7fa290f` | QuickXplain MUS "Why no solution?" panel for all four Constraints tabs. Four new `CspSolver.explain*` methods rebuild the Problem with `label:` threaded through every add* call, then call `findMinimalUnsatisfiableSubsetQuickXplain`. Shared `_ExplainSection` widget renders the button + the labeled conflict rows. en/de/fr/es (4 keys). 12 tests in `test/csp_mus_test.dart`. |
| **E.3** | `6f6be22` | DSL → FlatZinc export. New `DslToFlatZinc.export(input)` produces a ready-to-paste `.fzn` model from any DSL program (vars / allDifferent / linear ==/<=/>=/</>/!= / noOverlap → disjunctive / cumulative / minimize / maximize via synthetic `__obj__`). "Export as FlatZinc" button on the DSL tab; result lands in a copyable `_FlatZincExportBlock`. Non-linear constraints fail with a friendly error. en/de/fr/es (2 keys). 20 tests in `test/dsl_to_flatzinc_test.dart` — 12 structural, 5 error, **3 round-trip** through `FlatZinc.solve` to prove the translation actually solves. |
| Docs | `ff7d645` | PLAN.md struck E.2 + E.3. Only E.5 (MiniZinc solver bundling) remains on Round E. |

(Earlier in the day: `2ca864f` pin bump + `e853874` E.1 tab + `d90280b` E.4 inline `fzn:` directive + `8bb2fb3` HANDOFF refresh.)

## What's left on Round E

Just **E.5 — Bundle `dart_csp_fzn` CLI as a MiniZinc solver**. Niche
distribution play; ship the compiled CLI + `.msc` config in the
macOS/Linux app bundles so MiniZinc Challenge entrants can register
CrispCalc's solver. **Blocked on P4** (App Store / notarization).
Don't start until the distribution pipeline lands.

## Pickup points — Strategic next

With Round E nearly complete, the strategic next slot opens up:

1. **P7 booleans (5-round arc, starts at round 110)**. Calculator
   preprocessor: `a == b` → `Eq(a, b)`, `a and b` → `And(a, b)`,
   etc. `true`/`false` render as colored chips in history. PLAN P7
   has the full 5-round breakdown. Self-contained engine work; no
   cross-repo work needed.
2. **P6 discoverability + help (15-round arc, starts at round 91)**.
   Move Worked Examples out of Settings; new Function Reference
   dialog; app-wide `(?)` help-mode overlay; precision-arc /
   ntheory surfacing in the parsers. The bigger strategic
   direction. Round 91 (precision-arc calculator binding) is
   load-bearing for surfacing the round-85/86/89/90 wrappers.
3. **P9 follow-ups for the 3D Scene module** — A5d (raw-coefficient
   quadrics), A7 (parametric intersections), A8 (back-to-front
   sorting). Polish, not load-bearing.
4. **Precision arc round 4** (`modpow` / `modinv` / `totient` /
   `jacobi`) — see `HANDOFF_PRECISION.md`. Smallest cross-repo arc;
   the three-repo pipeline is well-trodden now.

## Known issues / context (Round E.2 + E.3)

- **Cryptarithm MUS only fires on the "No assignment satisfies"
  error**, not on shape-parse errors. The shape-parse path
  (`Expected WORD1 + WORD2 = WORD3`) means the model wasn't built
  at all, so MUS would be meaningless. Check
  `constraints_screen.dart` — `_result!.error!.contains('No assignment')`.
- **FlatZinc MUS labels are derived from `kind(vars)`**, not from
  user labels. The dart_csp FlatZinc lowering doesn't currently
  thread user labels through, so a FlatZinc MUS reads like
  `linearEquals(x, y)` rather than `C3: x + y == 7`. If you want
  source-line labels on FlatZinc MUS, that's a dart_csp lowering
  PR (multi-repo).
- **`DslToFlatZinc.export` reuses `CspSolver._tryParseLinear` and
  `CspSolver._parseLinearTerms` directly** (they're library-private
  in the same file). If you split the file, mind the visibility.
- **The export's `__obj__` variable name is reserved** —
  `vars: __obj__ in 0..5` is explicitly rejected with a clear
  error. Same name dart_csp's `CspSolver.solveOptimization` uses,
  so the two solvers stay symmetric.
- **DSL `!=` constraints** in the export go through a small
  separate `_tryParseLinearNe` path (since `_tryParseLinear`
  deliberately declines `!=` to keep it on the dart_csp string-
  parser path during normal solves). For the FlatZinc export we
  want it as `int_lin_ne`, so the shim splits on `!=` and parses
  each side as linear.
- **Background `flutter test` runs race each other** on the
  `.dart_tool/test/incremental_kernel_*` cache. Don't launch
  multiple `flutter test` in parallel — run sync or one at a time.
  Bit me twice this session.

## Hygiene reminders (unchanged)

- **`dart format`** before push — CI's "Verify formatting" step
  rejects unformatted files. Format only files you actually
  touched, not `lib/` wholesale (HANDOFF §4.17).
- **Both branches in sync** — when you commit to `main`,
  fast-forward `feature/notepad-phase-1` in
  `/Volumes/backups/code/CrispCalc-notepad-phase-1` and push too.
  This session did so.
- **Don't push from main** if it has uncommitted WIP. Always
  commit + push from a feature-branch worktree; only do
  `git merge --ff-only` + `git push origin main` from main, and
  check `git status` first.

## Quick-reference paths

- CSP wrapper: `lib/engine/csp_solver.dart`
  (new this session: `MusEntry`, `CspMusResult`, `explainDiophantine`,
  `explainDsl`, `explainCryptarithm`, `explainFlatZinc`,
  `FlatZincExportResult`, `DslToFlatZinc.export`, `_LinearFlatZinc`)
- CSP UI: `lib/screens/constraints_screen.dart`
  (new this session: `_ExplainSection`, `_MusBlock`,
  `_FlatZincExportBlock`; each tab gained `_mus` / `_explaining`
  state and the DSL tab gained `_export`)
- Localization: `lib/localization/app_localizations.dart`
  (6 new constraint keys × 4 locales)
- Tests: `test/csp_mus_test.dart`, `test/dsl_to_flatzinc_test.dart`,
  earlier `test/flatzinc_tab_test.dart`, `test/notepad_flatzinc_test.dart`

Good luck.
