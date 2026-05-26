# CrispCalc — handover for the next session

Single-shot briefing from the **2026-05-26 session** that left the
repo at commit `f4ee630`. The longer-lived `HANDOFF.md` is still
the load-bearing reference for repo conventions; this file is a
focused pickup note for what to do *next*.

---

## State

| | |
|---|---|
| **Main worktree** | `/Volumes/backups/code/CrispCalc` (branch `main`) |
| **Feature worktree** | `/Volumes/backups/code/CrispCalc-notepad-phase-1` (branch `feature/notepad-phase-1`) |
| **Both branches HEAD** | `f4ee630` docs: PLAN — CSP Round E |
| **Tests** | 1708 pass, `flutter analyze` clean |
| **CI** | green on the last main push |
| **App** | builds + runs on macOS (CocoaPods is fixed on this machine) |

Only dirty file is `.claude/scheduled_tasks.lock` (harness state — leave alone).

## What this session shipped

| Area | Commits |
|---|---|
| **Phase 4** Notepad UI skeleton | `b04caf1` (on feature/notepad-phase-1, then merged) |
| **Phase 5** live recalc + serialization fix + `_PersistentWorker` race fix | `72ed15d` |
| **Phase 6** units inline + `use` directive + format toggle | `63d6441` `604226c` |
| **Phase 7** Markdown export + Notepad-manager dialog + DE label "Rechenblock" | `d34b3d7` |
| **Phase 8** partial localization (en/de/fr/es chrome + error chips) | `75e627a` `95adf89` |
| **Bug round 1** — 100! exact integer, negative `-5.0`, decimal-places slider, auto-bind-solve toggle, focus-on-start belt | `27336ae` `755870d` `4fa911c` `4fd26b6` `1c00dc1` `99252af` |
| **Bug round 2** — d/dx LaTeX alignment (`\bigg(`), inline derivative `2 + d/dx(3*x)` expansion, history-cache `GlobalKey` crash | `d82b285` `bb35c95` `e7c1d14` `ab24c43` `8cc6ea3` `cecc37c` `642b913` |
| **Test build-out** — 91 parsing pipeline + 48 expression-deep + 38 edge + 5 Gantt = **182 new pure-Dart tests** (caught 4 real preprocessor bugs along the way) | `ff09b20` `1152ad5` `fd2c017` `68550e2` |
| **CSP Gantt** — `noOverlap` / `cumulative` results render as a horizontal Gantt chart instead of text | `d664303` |
| **PLAN** Round D (7 CSP opportunities) + Round E (FlatZinc + MUS + Notepad integration) | `aa0a390` `f4ee630` |

The 4 real bugs the new tests caught + fixed:

1. Chained binary minus `a-b-c` only spaced the first `-` (regex non-overlapping match issue).
2. `3*I` rendered as literal `\1i` (Dart's `replaceAll(RegExp, String)` doesn't do back-refs).
3. `2*sin` mangled to `2sin` (multi-letter ident shouldn't lose its `*`).
4. `extractNumericFromSolveResult("x = 1, x = 2")` returned `"2"` (silently picking one solution from a multi-solution result).

All fixed in `lib/utils/expression_preprocessing_utils.dart`.

## Pickup points — Round E (FlatZinc + MUS)

PLAN.md → search for `CSP Round E`. The full writeup is there.
Recommended order:

1. **Prereq — bump `dart_csp` pin** from `e3cce21` to a HEAD SHA that includes both the FlatZinc frontend (`8520461`) and QuickXplain MUS (`66b1a31` + `47beb59` + `a483980`). The features are additive but verify the `Problem` API surface didn't shift by running `flutter test test/csp_solver_test.dart` + `test/sudoku_test.dart`.
2. **E.1 — Paste-FlatZinc tab** (~½ day). 4th tab on `ConstraintsScreen`, textarea → `FlatZinc.solve(source)` → render output in `_ResultBlock` style. Two gallery entries (NQueens-4, bin-packing). The CLI binary `dart_csp_fzn` already works.
3. **E.4 — Notepad ↔ FlatZinc** *(novel)* (~1 day for inline `fzn:` directive variant; ~2–3 days for multi-line cell variant). PLAN E.4 has both options written up. The inline variant fits the existing `NotepadEvaluator` (Phase 3) cleanly; the cell variant needs Phase-1 doc-model changes.
4. **E.2** Why-no-solution QuickXplain panel + **E.3** DSL → FlatZinc export are polish, can wait.

## Known issues / context

- **Focus on cold launch** — added belt-and-suspenders re-`requestFocus` in `_MainScreenState.initState` (`1c00dc1`). User confirmed it works now but flag if it regresses.
- **2 + d/dx(3 * x)** — inline-derivative expansion fixed for derivatives only; `2 + integrate(x^2, x)` etc. would need the same treatment but isn't shipped yet.
- **GlobalKey crash on duplicate history expressions** — fixed (`642b913`) by caching the LaTeX *string* instead of the `Math.tex` widget. If you add other widget caches downstream, remember this pattern.
- **CocoaPods on this machine** was repaired earlier in the session (user fix); `flutter build macos --debug` works.

## Hygiene reminders

- **`dart format`** before push — CI's "Verify formatting" step rejects unformatted files (`66ee3b0` was the catch-up commit for last failure).
- **Both branches in sync** — when you commit to `main`, fast-forward `feature/notepad-phase-1` in `/Volumes/backups/code/CrispCalc-notepad-phase-1` and push too.
- **Don't touch `.claude/`** — harness state.
- **Don't touch `lib/engine/calculator_engine.dart`** unless the precision-arc work is explicitly part of the task (the original handover said this; the precision-arc commits have since landed so this is less critical, but still).

## Quick-reference paths

- Notepad UI: `lib/screens/notepad_screen.dart`
- Calculator dispatch: `lib/screens/calculator_screen.dart` (search for `_calculate`)
- Preprocessing: `lib/utils/expression_preprocessing_utils.dart`
- LaTeX conversion: `lib/utils/latex_conversion_utils.dart`
- CSP wrapper: `lib/engine/csp_solver.dart` (Gantt threading lives here)
- CSP UI: `lib/screens/constraints_screen.dart` (4th tab for E.1 lands here)
- AppState: `lib/engine/app_state.dart`
- Localization: `lib/localization/app_localizations.dart` (en/de/fr/es)

## Test files added this session

- `test/parsing_pipeline_test.dart` — 91 cases for LaTeX + preprocessing
- `test/expression_pipeline_deep_test.dart` — 48 cases for normalize/substitute/UDF/formatNumber
- `test/edge_cases_test.dart` — 38 cases for degenerate inputs
- `test/csp_solver_test.dart` — extended to 52 cases (Gantt-metadata threading)

Good luck.
