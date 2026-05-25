# CrispCalc — handover prompt

A self-contained briefing for the next assistant session. Treat
this as **load-bearing context**, not background reading: the
patterns below have been re-discovered (sometimes painfully) more
than once.

Always cross-check this file's claims against the current repo
state before recommending action — file names, APIs, and pins
rot fast. Where this file says "see X", actually open X.

## 1. What the app is

CrispCalc — Flutter CAS calculator, multi-platform (macOS / iOS /
Android / Linux / Windows, debug via `flutter run -d <device>`).

The codebase has grown well past "calculator":

- Calculator screen with hardware-keyboard + on-screen keypad
- Graphing (2D + 3D)
- Analysis hub with 9 module cards (Curve Sketching, Planes, Conic
  Sections, Statistics, 3D Graphing, Unit Converter, Constants,
  Constraint problems, Sudoku)
- Constraint Satisfaction Problems via [dart_csp](../dart_csp):
  Diophantine, cryptarithms, free-form DSL editor, Sudoku
  (regular / Sudoku-X / Killer; 4×4 / 6×6 / 9×9 / 16×16)
- Worked-examples library (~28 curated entries) — discovery
  surface that crosses into the module screens via sentinel
  expressions (see §5)
- Settings: locale (en/de/fr/es), themes, number format,
  user-defined functions

Native code under `symbolic_math_bridge` plugin handles SymEngine;
`dart_csp` is a pure-Dart CSP engine.

## 2. Working style

The user runs **round-based development**: each shippable feature
or fix is a self-contained commit, pushed individually. Common
flow:

1. User picks a task ("ok do it") from a 3-4 item recommendation
2. You implement: engine code → widget code → i18n across 4
   locales → tests
3. Run `flutter analyze` + `flutter test` + `dart format` (all
   must be clean)
4. Update `HISTORY.md` with a round entry describing **why** and
   **what**
5. Commit + push (commits already trigger CI)
6. User offers next pick

### Commit message style

```
P5: <short feature> — <subtitle>

<2-3 paragraph why-and-what body. Concrete: "moved X from Y to Z
because Q". Reference specific files and round numbers when fixing
regressions. End with the Co-Authored-By trailer:>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

The `P5:` prefix groups long-running phases. `fix:` / `ci:` for
non-feature commits.

### User preferences (calibrated over many rounds)

- **Terse responses** — short sentences, no trailing recap, no
  emoji unless explicitly requested
- **No spontaneous markdown docs** — only create *.md files when
  explicitly asked (this file was)
- **Root-cause fixes, not patches** — when something recurs ("we
  fix this time and again"), find the systemic cause. Spot fixes
  are explicitly criticized.
- **Don't claim work that wasn't done** — `pkill -f "flutter run"`
  kills the wrapper, not the compiled app. Verify, don't assume.
- **You can't send keystrokes to backgrounded processes** —
  `run_in_background: true` has no stdin. To hot-reload, you have
  to kill + restart.
- **i18n is non-negotiable** — every user-visible string goes
  through `AppLocalizations` with en/de/fr/es translations. The
  locale-coverage test in `test/localizations_test.dart` enforces.

## 3. Workspace map

```
lib/
  engine/
    sudoku.dart            ← Sudoku engine (layouts, variants, solver, hint mode)
    csp_solver.dart        ← Wraps dart_csp for Diophantine / cryptarithm / DSL
    worked_examples.dart   ← Curated catalog + categories
    app_state.dart         ← Singleton; pending-X slots for cross-screen signals
    analysis_engine.dart   ← Curve sketching (extrema, inflection)
    calculator_engine.dart ← CAS evaluation, history
    ...
  screens/
    calculator_screen.dart ← Big screen; KeyboardListener + LaTeX input
    analysis_hub_screen.dart
    sudoku_screen.dart     ← Module screen; preset picker, variant toggle, visualizer
    constraints_screen.dart← 3 tabs: Diophantine / Cryptarithm / Free-form DSL
    ...
  widgets/
    sudoku_grid.dart       ← Grid + cage overlay CustomPainter
    worked_examples_dialog.dart  ← Catalog browser + sentinel dispatcher
    constants_dialog.dart, unit_converter_dialog.dart
  localization/
    app_localizations.dart ← Abstract + 4 concrete locale impls in ONE file
  main.dart                ← MainScreen, MaterialApp, appRouteObserver
test/
  sudoku_test.dart, csp_solver_test.dart, ui_flows_test.dart,
  localizations_test.dart, worked_examples_test.dart,
  ... (~50 test files, ~1212 tests total)
PLAN.md                    ← Roadmap; mark items SHIPPED with round refs
HISTORY.md                 ← Newest-first changelog (this file's source of truth)
```

dart_csp lives at `~/code/dart_csp/` (sibling checkout); the
project depends on it via a git ref pin in `pubspec.yaml`.

## 4. Land mines we have already hit

### 4.1 dart_csp pin can vanish (force-push)

`pubspec.yaml` git-pins `dart_csp` to a SHA. The upstream remote
sometimes force-pushes / rewrites history. When the pinned SHA no
longer exists, **CI fails on `pub get` with "Could not find a file
named pubspec.yaml"** even though everything works locally (the
pub cache still has the old SHA).

Fix: `gh api repos/CrispStrobe/dart_csp/commits/main --jq .sha`,
update `ref:` in pubspec.yaml, `flutter pub get`, full test sweep
(the API may have shifted), commit + push.

See commit `c39dfd3`.

### 4.2 dart_csp GAC propagator pathology

dart_csp's generalized-arc-consistent allDifferent propagator
**prunes valid solutions when two allDifferent constraints share
the same variable subset**. Hit by Killer Sudoku in round 64
where every cage's allDifferent was being added redundantly even
when the cage was entirely within one row/column/box (already
covered by the existing row/col/box allDifferent).

Workaround in `lib/engine/sudoku.dart` `_buildProblem`: detect
when a cage's cells share a row, column, or box, and SKIP the
cage allDifferent in that case. The cage sum (`addLinearEquals`)
is always added.

Regression test:
`test/sudoku_test.dart` → `regression: horizontal-only cage does
not over-constrain the solver`.

If this comes back, **don't remove the regression test**. The
upstream bug isn't fixed; our workaround is what makes Killer
work at 9×9.

### 4.3 Calculator keyboard focus root cause

The calculator's hardware-keyboard input has been "fixed" several
times via spot patches (HardwareKeyboard reset button,
postFrameCallback refocus, etc.). Root cause was finally addressed
in round 71: focus restoration only fired on tab switch
(`_select(i)` in main.dart), so any **pushed route popping back**
(dialog, module screen, anything) left focus stranded.

Fix: app-wide `RouteObserver` in `main.dart` registered on
`MaterialApp.navigatorObservers`, plus `RouteAware` mixin on
`CalculatorScreenState` with `didPopNext()` re-requesting the
calculator FocusNode.

**If focus regresses again, check `appRouteObserver` is still
wired and `CalculatorScreenState.didPopNext()` still calls
`_calculatorFocusNode.requestFocus()` before patching anything.**

### 4.4 Right-panel overflow on narrow Sudoku screen

The Sudoku right panel is `SizedBox(width: 360)` at the wide
breakpoint. Several widgets break this width:

- `SegmentedButton` with 3+ labeled segments — replaced with
  `ChoiceChip` + `Wrap` (see `_SizeVariantPickers`)
- `DropdownButtonFormField` with long preset labels — use
  `isExpanded: true` + `TextOverflow.ellipsis` on each item's
  Text
- The whole `controlsBlock` Column — wrap in
  `SingleChildScrollView` for the wide layout (narrow already
  uses ListView)

The regression test
`test/ui_flows_test.dart` → `Sudoku screen: variant switcher
cycles without DropdownButton crash` catches both the dropdown
crash AND the overflow.

### 4.5 DropdownButton "exactly one item" assertion

`DropdownButtonFormField<T>` asserts that its `initialValue` is in
the `items` list. The preset picker constructs items from
`SudokuPresets.all` but `_puzzle` can be a freshly-constructed
empty puzzle (from variant/layout switch) that ISN'T identical to
any preset. **Pass `null` for `initialValue` when no preset
matches by identity** (renders as no-selection — "Custom"). Don't
fall back to `current`.

### 4.6 Killer 9×9 uniqueness is hard

Round 64 shipped a "feasible but not unique" killer9x9 preset
(horizontal-only cages). Round 66 replaced it with a "47 cages,
13 singleton clues + greedy 2-cell pairs" layout that's
provably unique. The high singleton count is what bought
uniqueness — generating a 9×9 Killer with FEWER singletons
needs a search loop over cage shapes (V2, see PLAN).

If you ship a new Killer preset, **add a `hasUniqueSolution`
test** so a future "improvement" can't silently break
uniqueness.

### 4.7 Test pollution from AppState singleton

`AppState` is a singleton — pending-X slots survive across
widget tests in the same isolate. Widget tests that touch
pending slots should drain them (or `AppState().load(force:
true)` at the start). The `_pumpApp` helper in `ui_flows_test.dart`
does this.

## 5. Two cross-screen patterns worth knowing

### 5.1 AppState pending slots

For "one screen wants another to do X on its next mount", use a
nullable field on `AppState` + setter + one-shot consumer.
Examples:

- `pendingInsertExpression` / `requestInsertExpression(s)` /
  `consumePendingInsert()` — calculator slot
- `pendingDslProgramId` / `requestLoadDslProgram(id)` /
  `consumePendingDslProgramId()` — Constraints/Free-form slot

Don't notifyListeners() from the consumer (you're already inside
a listener callback when you drain).

### 5.2 Sentinel `expression` field on WorkedExample

Worked examples were originally "tap → insert this string into the
calculator". Two sentinel prefixes extend that:

- `open:<module>` — navigate to a module screen (sudoku,
  constraints)
- `dsl:<gallery_id>` — navigate to Constraints + Free-form tab,
  pre-load the program from `_DslTabState._gallery`

Detection is in `lib/widgets/worked_examples_dialog.dart`
`_insert()`. Catalog-side validation tests in
`test/worked_examples_test.dart` enforce that every sentinel
points at a real target — a typo in a future entry fails CI
rather than silently dead-ending.

## 6. Open arcs, ranked by lift vs. cost

Recommended next picks for a fresh session. Mix of small wins and
fresh feature arcs.

### Small / medium (1 session each)

1. **Disjoint Groups Sudoku variant** (~45 min) — same digits
   forbidden across same-position cells in different boxes. Pure
   per-variant addition to the parameterized engine; mirrors the
   Sudoku-X pattern.
2. ~~**AC-3-pruned hints (advanced level)** — shipped round 73 as
   SAC-by-probing through the full dart_csp solver (Problem
   doesn't expose propagate-only). See HISTORY round 73 for the
   request-id cancellation pattern.~~
3. **8×8 Sudoku layout** (~30 min) — one-line layout addition +
   one preset. Cheap surface area growth.
4. **Step-trace "why" annotations** (medium) — the visualizer
   shows what cell got assigned, not why. Hook into dart_csp's
   propagation events to annotate each frame with the
   constraint that fired.

### Fresh feature arcs (multi-session)

5. **CSP Round D — minimize / maximize in the DSL** — extend
   the DSL grammar (`minimize x + y`, `maximize ...`), route to
   dart_csp's `solveOptimal`. Adds the optimization side to the
   constraint editor. Plus `addNoOverlap` / `addCumulative` for
   scheduling. PLAN has this as the next CSP item.
6. **Killer generator V2** — programmatic cage-layout generation
   with uniqueness guarantee. Requires search over shapes; the
   round-66 probe loop is a starting point.
7. **GMP / MPFR / MPC / FLINT precision arc** — native bridge
   for arbitrary precision + number theory. Plumbed but not
   surfaced. New feature arc, ~5-10 rounds. See PLAN §"Precision
   & number theory".

## 7. Critical commands

```bash
# Run-and-iterate
flutter run -d macos              # dev build (debug, hot reload)
flutter analyze                   # must be clean before commit
flutter test                      # full suite; expect ~1207 tests, ~1 min
dart format <files>               # CI runs format check on pinned Dart toolchain

# CI
gh run list --limit 6             # latest workflow runs (6 jobs per push)
gh run view <id> --log-failed     # failure details for a specific run

# Investigation
grep -rn "<symbol>" lib/          # codebase search (prefer over Agent for known files)
git log -p --grep="<keyword>"     # previous fixes for similar issues
```

CI runs 6 jobs on every push: CI (test + analyze) + Build
{macOS, Linux, Windows, Android, iOS}. All must pass.

## 8. Self-update protocol

If something in this file is wrong by the time you read it,
**fix it as part of your first commit in the session**, don't
work around it. Stale handover docs cause future regressions.

Specifically:
- Test count drifts as features land — update §3's "~1207 tests"
- Pin SHA in §4.1 changes on every dart_csp repin — update
- Lessons from new rounds belong in §4 as new sub-sections

Newest-first round entries continue to live in `HISTORY.md`. This
file is the **pattern catalog**, not the changelog.
