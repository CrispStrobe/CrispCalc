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
  Diophantine, cryptarithms, free-form DSL editor (with
  `minimize` / `maximize` / `noOverlap` directives), Sudoku
  (Regular / Sudoku-X / Killer / Disjoint Groups; 4×4 / 6×6 /
  8×8 / 9×9 / 16×16)
- Worked-examples library (~30 curated entries) — discovery
  surface that crosses into the module screens via sentinel
  expressions (see §5.2)
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
  ... (~50 test files, ~1465 tests total)
PLAN.md                    ← Roadmap; mark items SHIPPED with round refs
HISTORY.md                 ← Newest-first changelog (this file's source of truth)
```

dart_csp lives at `~/code/dart_csp/` (sibling checkout); the
project depends on it via a git ref pin in `pubspec.yaml`.

### Recently shipped (read HISTORY for context)

- **Round 73** — Sudoku advanced hints (SAC by probing)
- **Round 74** — CSP DSL `minimize` / `maximize`
- **Round 75** — Sudoku 8×8 layout (2×4 boxes)
- **Round 76** — Sudoku Disjoint Groups variant
- **Round 77** — CSP DSL `noOverlap` (single-machine scheduling)
- **Round 78** — DSL linear parser accepts expressions on both
  sides of the comparator
- **Round 79** — worked-examples library surfaces the round-74
  and round-77 DSL gallery entries (`coinChangeMin`,
  `schedulingMakespan`); PLAN.md + this file synced
- **Round 80** — CSP DSL `cumulative(s1=2@2, ...; capacity=N)`
  — renewable-resource generalization of round 77's `noOverlap`;
  closes the round-E bundle
- **Round 81** — Sudoku visualizer step-trace constraint-context
  captions (row / col / box / cage / diagonal / disjoint group)
- **Round 82** — 8×8 Sudoku variant presets (X / Disjoint /
  Killer) on the round-75 2×4-box layout
- **Round 83** — 10×10 / 12×12 / 15×15 Sudoku layouts + medium
  presets; same parameterized engine, no per-size code paths
- **Round 84** — multi-resource RCPSP gallery entry; two parallel
  `cumulative` overlays (crew + equipment) for project scheduling
- **Round 85** — Precision arc round 1: `pi(N)` via MPFR through
  the three-repo pipeline (math-stack-ios-builder → bridge →
  CrispCalc). First multi-repo feature-branch arc; see
  `HANDOFF_PRECISION.md` for the next slices.
- **Round 86** — Precision arc round 2: `e(N)`, `EulerGamma(N)`,
  `sqrt(2,N)` via the same pipeline. Boilerplate factored into
  a wrapper-side macro + bridge-side `_callPrecisionFn` helper.
- **Round 87** — Sudoku UI overhaul: clue-overwrite bug fix,
  layout-switch auto-loads matching preset, solve auto-plays
  the visualizer, visualizer-overflow → `Wrap`, drag-and-drop
  digits, cell-keyboard input + arrow nav, clear-to-start
  button, win-check chip.
- **Round 87b** — Sudoku win-celebration overlay (animated
  scale-in card with check icon + tap-to-dismiss) replaces the
  tiny win chip as the primary "you won" signal.
- **Round 88** — Sudoku conflict highlighting: pure-Dart
  `computeConflicts` flags every cell participating in a
  row/col/box/diagonal/disjoint-group/cage duplicate or a
  fully-filled cage with mismatched sum. Cells render with a
  22% red wash. Plus 8×8 X/Disjoint uniqueness audit (both
  pass — no regen needed).
- **Round 89** — Precision arc round 3: `isprime` + `nextprime`
  + `prevprime` via three new C wrappers. isprime/prevprime
  use GMP's `mpz_probab_prime_p` directly (SymEngine's cwrapper
  only exposes nextprime); nextprime goes through
  `ntheory_nextprime`. Same three-repo pipeline.
- **Round 90** — Precision arc round 4: `factorint(n)` via
  FLINT's `fmpz_factor`. First FLINT-backed wrapper. Output
  format `"p1^e1*p2^e2*..."` parsed Dart-side to structured
  `(prime, exponent)` records. 90-bit input cap. Nine new
  FLINT externs added to the +load keepalive.

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
crash AND the overflow. Round 76 extended the variant rotation
in that test to include Disjoint — keep all four variants in
the cycle when adding more.

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

### 4.8 `__obj__` is a reserved variable name in DSL optimization

`solveOptimization` injects a synthetic `__obj__` range variable
to carry the objective value (dart_csp's `minimize` / `maximize`
require the objective to be a registered variable). The DSL
checks `knownVars.contains('__obj__')` up front and rejects the
program with a friendly error if a user-declared variable
collides.

If a refactor changes the synthetic name (or its bounding
linear-equals constraint), **keep the collision check in sync**.
The bound is computed from input-variable ranges as
`Σ min(coef*lo, coef*hi)` and `Σ max(coef*lo, coef*hi)` plus any
constant offset in the objective expression — this matters
because dart_csp picks its interval-vs-list domain rep based on
span, and an open-ended range balloons the search.

### 4.9 `_parseLinearTerms` returns null for constant-only expressions

Round 78 extended `_tryParseLinear` (CSP) to handle
expression-on-both-sides, but **`addLinearEquals` requires a
non-empty variable list** — so when LHS and RHS cancel out to
zero variables (`5 == 5`, `x - x == 0`), the helper deliberately
returns null and falls through to dart_csp's string parser.
Don't "fix" the empty-list early return — the fallback is
correct, and dart_csp validates the constant comparison
correctly.

Regression test: `test/csp_solver_test.dart` →
`constant-only constraints still fall through to the string
parser`.

### 4.10 DSL gallery vs. worked-examples discovery — keep in sync

The `dsl:<id>` sentinel pattern (round 73) requires two places
to stay aligned when adding a new gallery program:

1. `_DslTabState._gallery` in `lib/screens/constraints_screen.dart`
   — the program text users actually load
2. `WorkedExamples.all` in `lib/engine/worked_examples.dart` —
   the discovery entry that surfaces the program in the
   worked-examples dialog
3. `AppLocalizations.workedExampleTitle/Description` for
   en/de/fr/es (titles are localised per id; English fallback
   comes from the entry itself)
4. `constraintsDslExampleTitle` in app_localizations.dart for
   the Examples-button dropdown inside the DSL tab

The `test/worked_examples_test.dart` →
`round 73: dsl: sentinels target known gallery ids` test
catches typos in (1) vs (2), but **all four touch-points are
needed for full discoverability**. Round 79 surfaced the
round-74 (`coinChangeMin`) and round-77 (`schedulingMakespan`)
entries that had previously only been in the gallery — keep
new entries from drifting again. Round 80 added
`cumulativeScheduling` through this same four-point pattern.

### 4.11 `cumulative` body parses by splitting on `;` — exactly two segments

Round 80 syntax is `cumulative(<tasks>; capacity=N)`. The parser
splits the inner body on `;` and requires *exactly two* segments
— a missing `; capacity=N` clause is a friendly rejection, not a
silent fallback. If someone tries to support more than one
`capacity=N` clause (multi-resource per-overlay) they have to
choose another separator or another keyword — don't relax the
exact-2 check; the malformed-input tests rely on it.

The task-pair regex requires `name=duration@demand` (the `@` is
literal, not optional). Don't let a future "convenience"
fallback to `name=duration` silently treat the demand as 1 —
that overloads what `noOverlap(...)` is for and makes the parser
ambiguous. Keep `cumulative` strict.

### 4.12 dart_csp's `CspCallback` doesn't carry constraint identity

`Problem.setOptions(callback: ...)` (dart_csp/lib/src/problem.dart:205)
takes a `CspCallback(assigned, unassigned)` and fires on every
decision. It does NOT include which constraint propagated — the
propagators don't emit names. Anything that claims "dart_csp's
propagation callback fires per decision with constraint
identity" is wrong (HANDOFF.md §6 made this mistake before
round 81 shipped).

Two options if you need firing-constraint identity:
1. Extend dart_csp's callback signature (multi-repo change +
   repin)
2. Infer post-hoc from the pre/post-state diff (lossy — many
   constraints can produce the same prune)

Round 81 sidestepped this entirely by showing constraint
*context* (which overlays the assigned cell participates in)
rather than constraint *identity* (which propagator fired). See
`SudokuPuzzle.contextAt`.

## 5. Cross-screen + cross-feature patterns worth knowing

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

### 5.3 Singleton arc consistency by probing (when AC-3 isn't exposed)

Round 73 needed "stricter than naive pencil-marks" for Sudoku
hints. dart_csp doesn't expose a propagate-to-fixpoint entry
point (its `_propagate` is private; `Problem` only offers full
`getSolution` / `getSolutions`), so we can't ask for "the
reduced domain after AC-3 + GAC."

The workaround: for each candidate value `v` at empty cell `c`,
build `puzzle.withCell(c, v)` and call the full solver. If it's
satisfiable, keep `v`; otherwise drop it. This is singleton arc
consistency by probing — semantically what AC-3 gives you for
unary constraints, but routed through the backtracker.

Two short-circuits keep it bounded:

- Fetch one base solution up front. Each cell's base value is
  trivially feasible, so skip the probe for it.
- Every successful probe returns a *different* complete
  solution; harvest its per-cell values into a `confirmed` set
  so subsequent (cell, value) pairs already proven feasible
  skip the probe.

`SudokuSolver.computeCandidatesPruned` lives in
`lib/engine/sudoku.dart`. The UI gates this behind an
"Advanced" hint level (off / basic / advanced) because the cost
is seconds-per-edit on hard 9×9 puzzles. A monotonic
`_advancedRequestId` in the screen state cancels stale
in-flight results when the user edits quickly.

If you need the same pattern for a different CSP, reuse the
shape: naive set → base solution → per-candidate probe →
harvest. Don't try to expose dart_csp internals — the probe
loop is robust and the cost is bearable for any problem the
backtracker handles quickly.

### 5.4 Synthetic objective variable for `minimize` / `maximize`

dart_csp's `Problem.minimize(objective)` /
`Problem.maximize(objective)` take the **name of a variable**,
not an expression. To optimize a linear expression like
`x + 2y - z`, round 74 introduced a synthetic `__obj__` range
variable bound to that expression via `addLinearEquals`:

```dart
problem.addRangeVariable('__obj__', objLo, objHi);
problem.addLinearEquals(
  [...exprVars, '__obj__'],
  [...exprCoeffs, -1],
  -constantTerm,   // round 78: any +k in the objective folds here
);
final result = await problem.minimize('__obj__');
```

The tight `(objLo, objHi)` range matters — dart_csp picks
interval-vs-list domain rep based on span. Compute it from the
input-variable ranges (per-term min/max contribution summed
independently). If you forget and use a huge range, the search
balloons.

After the solver returns, strip `__obj__` from the assignment
before handing back to the caller — see `solveOptimization` in
`csp_solver.dart`. The optimum value is `result['__obj__']`.

## 6. Open arcs, ranked by lift vs. cost

### Chosen next arc — MPFR/FLINT precision

`HANDOFF_PRECISION.md` is the load-bearing doc for the next
session. It covers the three-repo pipeline (math-stack-ios-
builder → symbolic_math_bridge → CrispCalc), a 5-round
breakdown, the smallest first slice, and arc-specific land
mines. Read it before opening a file.

The arc strengthens the CAS-grade moat that PLAN.md's
Strategic Context (May 2026) calls out, builds on infra that
already ships (SymEngine + GMP/MPFR/FLINT compiled into
xcframeworks + +load keepalive in place), and ships discrete
completable rounds without blocking on UI/AI design. The C
wrapper source lives in `math-stack-ios-builder/src/` and
already uses SymEngine's `basic_evalf` / `ntheory_*` API — so
adding a precision function is "edit one .c, rebuild, copy
into bridge, repin."

### Other arcs (multi-session, deferred)

1. **dart_csp propagation-callback identity** — round 81
   shipped constraint-*context* captions; the next tightening
   would expose **which** propagator actually fired through
   dart_csp's `CspCallback`. Multi-repo: dart_csp signature
   extension + CrispCalc consumer.
2. **Irregular-region Sudoku (Du-sum-oh)** — boxes become
   arbitrary same-size polyomino tilings. Engine replaces the
   `_boxes` walker with a per-puzzle region list; allDifferent
   overlay + hint elimination reuse the existing path.
   Generator (sampling valid tilings) is its own problem.
3. **Killer generator V2** — programmatic cage-layout
   generation with uniqueness guarantee. Search over shapes;
   the round-66 probe loop is the starting point.
4. **Worked-examples V3** — advanced topics (related rates,
   eigenvalue, multivariable, parametric) + a "view this
   step-by-step" jump from a worked example to its trace
   dialog. Listed as V3 pending in PLAN.

The two strategic adds from PLAN.md's May-2026 Strategic
Context (notepad/document input paradigm + AI as
verifier-frontend) are bigger lifts and don't have an obvious
"first round" yet. They sit above this menu strategically but
below it operationally.

## 7. Critical commands

```bash
# Run-and-iterate
flutter run -d macos              # dev build (debug, hot reload)
flutter analyze                   # must be clean before commit
flutter test                      # full suite; expect ~1465 tests, ~1 min
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
- Test count drifts as features land — update §3's "~1465 tests"
  and §7's "expect ~1465 tests". Adding a WorkedExample entry
  auto-generates 6 tests (3 non-EN locales × title + description)
  via `worked_examples_localization_test.dart`, so the count can
  jump even on docs-only rounds.
- Pin SHA in §4.1 changes on every dart_csp repin — update the
  commit ref
- Lessons from new rounds belong in §4 as new sub-sections;
  cross-cutting patterns belong in §5
- §6 is the moving part — strike completed picks, surface new
  ones discovered while shipping

Newest-first round entries continue to live in `HISTORY.md`.
This file is the **pattern catalog**, not the changelog.
