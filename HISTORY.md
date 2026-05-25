# CrispCalc — History

Completed work, newest first.

## 2026-05-25 (round 78) — DSL linear parser: expression-on-both-sides

Round 77 had to write `makespan - sN >= dN` because the
linear-expression parser required the RHS to be a numeric
literal — `sN + dN <= makespan` failed to parse and fell
through to dart_csp's string-constraint parser, which rejected
it. This round closes that loop.

### Parser

`_parseLinearTerms(expr, knownVars)` now returns
`(vars, coeffs, constant)` — a per-term split where each term is
either a coef×var contribution or a bare integer constant.
Empty expression returns null; otherwise the result is always
well-formed (even with all-constant input).

`_tryParseLinear` switches from "LHS terms op number" to
"expression op expression". A non-greedy LHS-side match plus
the same op set; each side is parsed with
`_parseLinearTerms`; then the RHS is moved to the LHS:

```
lhs op rhs   ⇔   (lhs.vars + rhs.vars; lhs.coeffs + -rhs.coeffs)
               op (rhs.constant - lhs.constant)
```

Constant-only constraints (`5 == 5`) still return null and
fall through to the string parser — `addLinearEquals` requires
a non-empty variable list.

### Objective parser

`solveOptimization` also picks up constant-bearing objectives:
`minimize x + 100` now reports a shifted optimum
(objective value includes the +100 offset). The synthetic
`__obj__` binding constraint is rewritten to
`Σ coef_i·var_i - __obj__ == -constant` so the constant
folds into the bound rather than the variable list.

### Gallery + tests

The `schedulingMakespan` gallery entry reverts to the natural
form `s + d <= makespan` — round 77's HISTORY noted the
workaround; this round removes it.

Five new tests in `csp_solver_test.dart`:
- `x + 1 == y` over 0..5 enumerates the 5 solutions
- mixed-side inequality `x + y <= z + 1`
- objective with constant offset reports the shifted optimum
- scheduling round-trip in the natural form
- regression: constant-only constraint falls through cleanly
  rather than crashing on an empty `addLinearEquals` call

Suite total: 1236 tests.

## 2026-05-25 (round 77) — CSP Round E: noOverlap (single-machine scheduling)

Round 74 added optimization (`minimize` / `maximize`) to the
DSL but the constraint vocabulary was still pure
arithmetic — there was no compact way to express "these tasks
can't run at the same time," the canonical single-machine
scheduling rule. HANDOFF §6 listed `addNoOverlap` /
`addCumulative` as the next CSP arc; this round ships the first
half (no-overlap; cumulative-with-heights stays open for a
follow-up).

### Grammar

```
noOverlap(s1=4, s2=3, s3=2)
```

Each `name=integer` pair declares a task: `name` is a
previously-declared start variable, the integer is its constant
duration. The half-open intervals `[name, name + duration)` are
constrained to be pairwise disjoint. The parser validates that
every name is declared and every duration is non-negative;
empty bodies and malformed pairs surface clear line-numbered
errors.

### Engine

A new `NoOverlapGroup` typedef (`(starts, durations)`) carries
the parsed groups. Both `solveDiophantine` and
`solveOptimization` gain an optional `noOverlap` named
parameter; after the regular constraint loop they call
`problem.addNoOverlap(starts, durations)` per group. dart_csp's
helper itself dispatches to the cumulative time-table
propagator (capacity 1, heights all 1) — strictly stronger
pruning than a hand-rolled O(n²) pairwise disjunction.

### Composition with round 74

The new `schedulingMakespan` gallery entry shows the canonical
"schedule three tasks on one machine, minimize makespan" form:

```
vars: s1, s2, s3 in 0..9
vars: makespan in 0..9
noOverlap(s1=4, s2=3, s3=2)
makespan - s1 >= 4
makespan - s2 >= 3
makespan - s3 >= 2
minimize makespan
```

Optimal makespan is 9 (sum of durations on a single resource).

The constraints are written as `makespan - sN >= dN` rather
than the more natural `sN + dN <= makespan` because the
current linear-expression parser requires the RHS to be a
numeric literal. Extending the parser to handle
expression-on-both-sides is queued as a follow-up.

### Tests

Six new engine tests in `csp_solver_test.dart`:
- noOverlap enumerates only valid schedules (pairwise
  non-overlap verified directly from the solver's output)
- noOverlap + minimize returns the optimum makespan
- undeclared start var, malformed pair, empty body, and
  negative duration each produce clear errors

One new gallery entry + i18n × 4 locales. Both gallery tests
(locale-coverage + dsl: sentinel) updated. Suite total: 1231
tests.

## 2026-05-25 (round 76) — Sudoku Disjoint Groups variant

HANDOFF §6 listed Disjoint Groups as a one-session pick that
mirrors the Sudoku-X pattern: a parameterized overlay on top of
the existing row / column / box constraints. Same engine plumbing,
just a new set of `allDifferent` constraints.

### Rule

For each in-box position p (e.g. "top-left of the box"), the
cells that occupy position p across all boxes form a group; every
group must contain distinct digits 1..N. Standard 9×9 adds 9 new
`allDifferent` constraints, one per in-box position, each of size
9 (one cell per box).

### Engine

- `SudokuVariant.disjoint` enum value.
- New `_disjointGroups(layout)` walker yields the `side` groups
  by iterating in-box (row, col) offsets and collecting the cell
  at that offset inside every grid box.
- `_buildProblem` adds the groups as `allDifferent` when
  `variant == disjoint`.
- `computeCandidates` gains a `disjointUsed[key]` index keyed by
  `(r % boxRows) * boxCols + c % boxCols` (the in-box position).
  Empty cells exclude values already placed at the same key.

### UI + i18n

`SudokuVariant.disjoint` rendered in the variant ChoiceChip row
between Killer and the next variant. Four new locale strings
(`sudokuVariantDisjoint`: Disjoint / Disjunkt / Disjoint /
Disjunto). The `_switchLayoutOrVariant` Killer-special-case
falls through correctly for Disjoint (no cages required — an
empty grid is a valid Disjoint puzzle).

### Tests

Three new engine tests in `sudoku_test.dart`:
- Generator round-trip on 9×9 disjoint easy verifies every
  in-box-position group is duplicate-free in the solved grid.
- `computeCandidates` correctly excludes values from the same
  disjoint group ((3,3) loses 5 when (0,0) is 5; (4,4) keeps it
  since the in-box position differs).
- Regression: the regular variant ignores the disjoint conflict
  (proving the new code path is gated by the variant flag).

Locale-coverage test + UI flow test updated to include the new
variant. Suite total: 1225 tests.

## 2026-05-25 (round 75) — Sudoku 8×8 layout

PLAN's V2 Sudoku roadmap listed 8×8 (2×4 boxes) between the
existing 6×6 and 9×9 stops. The parameterized engine already
handles arbitrary `(side, boxRows, boxCols)` triples — the only
work is one layout constant, one preset, one generator
clue-count entry, and the matching i18n + tests.

### Layout

`SudokuLayout.eight = (side: 8, boxRows: 2, boxCols: 4)`, added
to `SudokuLayout.all` between `medium` and `standard` so the
size-picker chips render in ascending order. The
parameterized box walker handles the 2×4 partition with no
special-casing.

### Preset

`SudokuPresets.eight8x8` — 28 clues peeled from the canonical
full grid
`12345678 / 56781234 / 23416785 / 67852341 / 34127856 / …`
in a checkerboard-ish pattern that keeps each row + col +
2×4 box partially populated. Registered in `SudokuPresets.all`
so the existing "every preset is solvable" sweep covers it.

### Generator

`_targetClueCount` gets an `case 8:` branch with 30 / 24 / 18
clues for easy / medium / hard — scaled from the 9×9 (40/30/22)
counts in roughly the cell-count ratio (64 vs 81), since 8×8
minimum-clue research is less well-developed than 9×9.

### i18n + tests

`'eight8x8'` localized as "8×8 medium" across all four locales.
Three new tests in `sudoku_test.dart`: layout invariants
(side / boxRows / boxCols), preset solves to a valid grid with
clues preserved, and generator round-trip with a fixed seed.
Suite total: 1222 tests.

## 2026-05-25 (round 74) — CSP Round D: minimize / maximize in the DSL

The constraint mini-DSL (round 68) was enumeration-only:
declare variables, list constraints, get every solution. Real
optimization problems — least-coin change, max-revenue mix,
shortest cover — need the solver to *pick* the best feasible
assignment rather than dump all of them. PLAN's CSP Round D
called for `minimize` / `maximize` directives routed through
dart_csp's branch-and-bound (`Problem.minimize` /
`Problem.maximize`).

### Grammar extension

One new directive: `minimize <linear-expr>` or `maximize
<linear-expr>` anywhere in the program. Linear-expr is the same
shape constraints already accept (e.g. `2*x + 3*y - z`). At most
one objective per program; specifying two surfaces a parse error
naming both line numbers. The objective is parsed *before* the
var-declaration / allDifferent / constraint matchers so a stray
`minimize` keyword can't be swallowed by the fallback constraint
path.

### Engine: `solveOptimization`

New static method alongside `solveDiophantine`. Builds the
dart_csp `Problem` identically (same range vars, same constraint
routing), then adds a synthetic `__obj__` variable bound to
`Σ coef_i · var_i` via `addLinearEquals`. The synthetic var gets
a TIGHT integer range computed from the input variable ranges
(per-term min/max contribution summed independently) so dart_csp
can use its interval domain rep — no billion-element list even
for objectives like `3*x + 5*y` with x,y in 0..100.

Calls `problem.minimize('__obj__')` / `.maximize('__obj__')`,
strips the synthetic var from the returned assignment, and
returns a `DiophantineResult.optimal(assignment, objectiveValue)`
— a new factory constructor that puts the singleton optimum
into `solutions` AND populates the new `num? objective` field.
Enumeration mode is unchanged (objective stays null).

### UI: header switches to "Optimal: objective = N"

The shared `_ResultBlock` checks `result.objective != null` and
swaps the "N solutions" header for the new
`constraintsOptimalHeader(num)` string. Solution rendering drops
the index prefix in optimization mode (always one assignment,
the numbering reads weird otherwise). Copy-button + body
formatting are unchanged.

### Refactor

Factored out a `_parseLinearTerms(expr, knownVars)` helper that
both `_tryParseLinear` (constraint LHS) and the new
`solveOptimization` objective parser share. No behaviour change
for existing constraints.

### Gallery + i18n + tests

New `coinChangeMin` gallery entry (pay 17¢ with the fewest coins
from {1, 5, 10, 25}). Two new i18n strings — gallery title plus
`constraintsOptimalHeader(num)` — across all four locales.
Locale-coverage test extended.

Seven new engine tests in `csp_solver_test.dart`:
- minimize returns the proven optimum + correct objective value
- maximize ditto
- two objective directives in one program is rejected
- infeasible optimization surfaces "No assignment" cleanly
- non-linear objective (`x*y`) is rejected at parse time
- objective referencing undeclared variable is rejected
- enumeration mode keeps the old behaviour (objective is null)

Suite total: 1219 tests (+7 net).

## 2026-05-25 (round 73) — Sudoku advanced hints (SAC by probing)

The V3 hint mode (round 62) was naive single-pass elimination:
fast enough to recompute on every keystroke, but it misses
"hidden singles" — a digit that can only legally land in one
cell within a row / column / box even though row + column + box
elimination alone leaves multiple candidates marked. PLAN's V4
follow-up called for an opt-in advanced level routed through
the full CSP solver.

### Engine: `computeCandidatesPruned(puzzle)`

Singleton arc consistency by probing. For each empty cell's
naive candidate v, build `puzzle.withCell(idx, v)` and ask the
dart_csp solver whether it's still satisfiable. Infeasible
candidates are dropped. Two short-circuits keep the work
bounded:

- Fetch one base solution up front. Each cell's base value is
  trivially feasible, so skip the probe for it.
- Every successful probe returns a complete *different*
  solution; harvest its per-cell values into a `confirmed` set
  so subsequent (cell, value) pairs already proven feasible are
  skipped.

dart_csp's `Problem` doesn't expose a "propagate to fixpoint,
return reduced domains" entry point, so we route through the
full backtracker. Each probe is therefore a full search, but
Sudoku probes terminate fast (AC-3 + GAC propagation hits unsat
quickly on contradictory pin assignments). Empirically, a 9×9
hard puzzle with ~60 empty cells runs in 2–4 seconds — too slow
to debounce live on every keystroke, hence the opt-in level.

### UI: three-state hint-level picker

`bool _showHints` becomes `SudokuHintLevel _hintLevel` with
values `off`, `basic` (synchronous naive), `advanced` (async
SAC). The `_HintLevelPicker` widget shows the three options as
ChoiceChips so the picker survives the 360 px right panel
without overflow, plus a tooltip explaining the speed tradeoff
and a spinner subtitle while advanced is recomputing.

State management uses a monotonic `_advancedRequestId`: a fast
sequence of edits cancels in-flight stale results (only the
latest compute commits to state). The advanced cache is
invalidated to null at every puzzle / displayed-cells change
site (`_loadPreset`, `_setDigit`, `_generate`,
`_switchLayoutOrVariant`) — same pattern the round-65 unique
chip uses. While advanced is recomputing, the grid renders the
basic candidates as a fallback so it never blanks.

### i18n + tests

Five new strings × four locales:
`sudokuHintLevelOff/Basic/Advanced/AdvancedHelp/Computing`.
The locale-coverage test catches missing translations.

Four new engine tests in `sudoku_test.dart`:
- pruned ⊆ naive at every cell (regression for any future
  optimization that might accidentally widen the set)
- uniquely-solvable puzzle (generator-produced) collapses every
  empty cell to the singleton solution value — strong proof
  that SAC actually picks up the slack from hidden singles
- infeasible puzzle returns all-empty
- hidden-single regression on a hand-crafted 4×4 where naive
  leaves multiple candidates but SAC tightens.

One UI flow test in `ui_flows_test.dart` cycles Off → Basic →
Advanced → Off without crashing — guards against the request-id
cancellation logic regressing if the recompute trigger sites
get refactored.

## 2026-05-25 (round 69) — Worked-examples library surfaces Killer + CSP DSL

Before this round the worked-examples library was 100% CAS /
calculator entries — so a user browsing for examples had no
way to discover that CrispCalc also does Killer Sudoku or
free-form constraint programming.

This round adds a new `constraints` category with two entries
that navigate to the relevant module screens instead of
inserting an expression into the calculator.

### Pattern

A worked example whose `expression` starts with `open:` is a
**module navigation sentinel** rather than a calculator
expression. The dialog's tap handler detects the prefix and
pushes the corresponding screen onto the navigator:

- `open:sudoku` → `SudokuScreen`
- `open:constraints` → `ConstraintsScreen`

Plain expressions still go through `AppState.requestInsert
Expression` as before. The sentinel keeps the catalog data
model unchanged (no breaking schema migration) — just
new behavior for a new prefix.

### Catalog entries

- **Killer Sudoku (9×9)** — opens the Sudoku module so the
  user can pick `9×9 Killer` from the preset list.
- **Free-form constraint editor** — opens the Constraints
  module on the Diophantine tab; user switches to Free-form
  to type a DSL program.

### i18n + tests

`workedExamplesCatConstraints` + en/de/fr/es translations.
Translated titles + descriptions for the two new entries.
Two new tests in `worked_examples_test.dart`: the constraints
category surfaces both entries with correct sentinels, and
every `open:` sentinel targets a known module — so a typo in
a future entry fails CI rather than silently dead-ends the
navigation.

## 2026-05-25 (round 68) — CSP Round C: free-form constraint mini-DSL

A third tab in the Constraints module lets the user write a
constraint program directly:

```
vars: x, y, z in 1..9
allDifferent(x, y, z)
x + y + z == 15
```

This was the next `[ ]` item after Sudoku in PLAN.md.

### Engine: `CspSolver.solveDsl(text)`

A small line-based parser:

- `vars:` lines declare comma-separated names + a `lo..hi`
  integer range. Multiple `vars:` lines allowed. Names must
  match `[a-zA-Z_][a-zA-Z0-9_]*`; ranges check `hi >= lo` and
  width ≤ 10000 (caps dart_csp domain size). Duplicate
  declarations are an error.
- `allDifferent(x, y, z)` is expanded to pairwise `!=`
  constraints (≥ 2 vars required).
- `#` comments (line and trailing) + blank lines are stripped.
- Anything else is treated as a constraint and routed through
  the existing `solveDiophantine` path — same `_tryParseLinear`
  router that already handles coefficient-bearing
  `2*x + 3*y == 12`.

The parser returns `DiophantineResult` so the existing
`_ResultBlock` widget (truncation badge + copy-to-clipboard
+ error chip) just works.

### UI

`_DslTab` adds a multi-line monospace TextField (pre-seeded
with the magic-sum example), a Solve button with spinner, and
the reused `_ResultBlock`. Three new i18n strings
(`constraintsTabDsl`, `constraintsDslIntro`,
`constraintsDslInputLabel`) across en/de/fr/es, locale-coverage
test extended.

### Tests

Seven DSL tests in `csp_solver_test.dart`: magic-sum example,
comments + blank lines, missing `vars:`, invalid name,
duplicate declaration, `allDifferent` with too few vars, and
the coefficient-bearing linear constraint.

## 2026-05-25 (round 67) — Sudoku: Killer-aware hint mode

The pencil-marks (Show Hints) currently filter by row, column,
box, and Sudoku-X diagonals — but not by cage. In Killer mode
that misses two large eliminations:

- **Cage all-different**: a digit already placed in the same
  cage can't appear in any other cell of that cage.
- **Cage sum residue**: if the cage targets sum S, K cells are
  empty, and the placed cells sum to P, then each empty cell's
  value v must satisfy `residue - (K-1)·n ≤ v ≤ residue - (K-1)`
  where residue = S - P. (Each of the other K-1 cells takes a
  value between 1 and n.)

### Implementation

`computeCandidates` now precomputes per-cage state (which
values are placed, which cells are still empty) and applies
both filters before returning the candidate set. The bound is
**loose** (uses 1..n for each other cell's range) rather than
tight (would enumerate which digits are actually still
available). Tight bounds are V2 — the loose bound already
catches most "this digit can't possibly fit" cases without
needing combinatorial enumeration.

### Tests

- 4×4 Killer with a 2-cell cage summing to 3: every other cell
  in that cage gets candidates ⊆ {1, 2}.
- Cage summing to 7 in 4×4: candidates ⊆ {3, 4} (since 1..4
  range caps at 4, and 7 - 4 = 3 is the lower bound).
- Filled cage cells return empty candidate sets (they're clues).

## 2026-05-25 (round 66) — Sudoku: killer9x9 is now actually unique

The killer9x9 preset shipped in round 64 was feasible but not
unique (horizontal-only cages don't disambiguate). Round 65's
uniqueness chip surfaced this honestly to the user, but the
puzzle still wasn't a "real" Killer — clicking Solve would
return one of many valid grids, and re-solving could give a
different one.

This round replaces the cage layout with one that admits
exactly one solution.

### Layout design

The probe loop (driven by `hasUniqueSolution`) tried several
cage families:
- Horizontal pairs/triples (sums only): not unique.
- Vertical pairs across row blocks: not unique.
- L-tromino tilings: not unique even with 3 singleton clues
  (and took 24s to confirm).
- 11 singleton "clue" cages + greedy 2-cell pair fill: UNIQUE
  in 17ms.

The greedy fill walks the grid row-major and pairs each
unclaimed cell with its right neighbour (else below, else
left), leaving 13 effective singletons (the original 11 plus
two that got stranded next to other singletons). 47 cages
total. The high singleton count is what buys uniqueness on
this 9×9 — generating a Killer with fewer singletons requires
search over cage shapes, deferred to V2.

### Test

`killer9x9 preset has a UNIQUE solution` asserts
`SudokuSolver.hasUniqueSolution(killer9x9)` is true. The
existing feasibility + cage-sum tests still apply.

## 2026-05-25 (round 65) — Sudoku: uniqueness indicator

Adds a "Check uniqueness" button to the Sudoku screen and a
chip that surfaces the result inline. Internally exposes
`SudokuSolver.hasUniqueSolution(puzzle)`, which is `solve` +
dart_csp's `hasMultipleSolutions` on the same constraint set —
runs in milliseconds for a typical 4×4 / 6×6 / 9×9 with one
solution, slower (full tree exhaustion) for puzzles with many.

### Why

The killer9x9 preset shipped in round 64 has multiple
solutions (horizontal-only cages don't disambiguate), so users
fairly asked "is this actually a real puzzle?". The uniqueness
chip answers that question directly — and is generally useful
anywhere a user has hand-entered clues and wants to know if
they've over-constrained or under-constrained.

### Engine

- `SudokuSolver.hasUniqueSolution(puzzle)` — public Future<bool>.
  Returns true iff exactly one solution exists. Internally:
  one `solve` to confirm feasibility, then dart_csp's
  `hasMultipleSolutions` which short-circuits on the first
  second-solution leaf.
- Three tests cover the three cases: generated puzzle (unique),
  empty puzzle (many), infeasible puzzle (none).

### Screen

- Local state `_unique` (nullable bool) + `_checkingUnique`.
  Cleared on every edit / preset switch / variant change /
  layout switch — same code path as the trace, so an inline
  Chip never lies about which puzzle it describes.
- Button captures the puzzle by identity at click time so a
  race against an edit discards the stale result.
- Three new i18n strings (`sudokuCheckUnique`,
  `sudokuUniqueSolution`, `sudokuMultipleSolutions`) across
  en/de/fr/es with the locale-coverage test extended.

## 2026-05-25 (round 64) — Sudoku V4.1: Killer 9×9 preset + propagation fix

Ships a 9×9 Killer preset (derived from a canonical solved grid,
36 cages partitioning all 81 cells into horizontal 2/3-cell
groups, no givens) and fixes a propagation pathology surfaced by
the larger size.

### The bug

While bringing up the 9×9 preset the solver returned no solution
even though a valid assignment provably exists. Bisection across
cages showed that the issue was independent of which cage —
dropping ANY single cage left it feasible. A hand-built dart_csp
problem (sums only, no cage allDifferent) solved instantly; the
same problem WITH cage allDifferent failed.

Root cause: when a cage is entirely within one row, one column,
or one box, adding a cage `addAllDifferent` is redundant with
the existing row/column/box `addAllDifferent`. Stacking two GAC
allDifferent propagators on the same variable subset triggers
incorrect domain pruning in dart_csp's propagator (the redundant
constraint contributes no new information but the propagator
combination prunes values that should be reachable).

### Fix

`_buildProblem` now detects when a cage's cells share a row,
column, or box and skips the cage `addAllDifferent` in that
case. The cage sum (`addLinearEquals`) is always added — sums
carry real information not covered by row/col/box constraints.
A regression test (`horizontal-only cage does not over-constrain
the solver`) pins the behavior.

### killer9x9 preset

Derived from the canonical 9×9 solution:

```
5 3 4 | 6 7 8 | 9 1 2
6 7 2 | 1 9 5 | 3 4 8
1 9 8 | 3 4 2 | 5 6 7
------+-------+------
8 5 9 | 7 6 1 | 4 2 3
4 2 6 | 8 5 3 | 7 9 1
7 1 3 | 9 2 4 | 8 5 6
------+-------+------
9 6 1 | 5 3 7 | 2 8 4
2 8 7 | 4 1 9 | 6 3 5
3 4 5 | 2 8 6 | 1 7 9
```

Partition: 4 cages per row (mix of 2-pair and 3-cell triple),
36 cages total. Cage sums per row total 45 (= 1+…+9), verified
in tests. Ships with no givens — the cage system alone admits
a feasible solution. Note: uniqueness is NOT guaranteed for
horizontal-only cage layouts (cages alone don't disambiguate
between many valid fills); irregular cross-row cage shapes that
would give a unique solution are V2.

### i18n + tests

- `sudokuPresetLabel('killer9x9')` → '9×9 Killer' across en/de/
  fr/es.
- Two new test cases: cage-partition exhaustiveness for the
  killer9x9 preset, and feasibility + cage-sum correctness
  vs. the actual found solution.

## 2026-05-25 (round 63) — Sudoku V4: Killer Sudoku variant

Cage-based Sudoku where each cage is a contiguous (or arbitrary)
set of cells with a target sum, and the digits inside a cage
must be distinct. The 4×4 Killer preset ships with no givens at
all — the cage system alone determines the unique solution. The
dart_csp linear-arithmetic propagator (`addLinearEquals`) handles
the per-cage sum constraint with bounds consistency, so adding
this variant cost no new constraint code in the solver itself —
just a model extension + UI overlay.

### Engine

- **`SudokuVariant.killer`** added to the variant enum.
- **`KillerCage`** model — `cellIndexes` (flat index into the
  side²-cell grid) + `targetSum`. Construction asserts that
  every cell of the grid is covered by exactly one cage.
- **`SudokuPuzzle`** gained an optional `cages: List<KillerCage>?`
  field. Construction asserts `cages != null` when variant is
  killer; otherwise the field is null. The clone helper
  (`withCell`) carries cages forward.
- **`_buildProblem`** now appends one `addAllDifferent(keys)`
  and one `addLinearEquals(keys, [1,…,1], targetSum)` per cage.
  AllDifferent is omitted for singleton cages (degenerate).
- **`SudokuPresets.killer4x4`** — a partition of 16 cells into
  8 cages with verified sums totalling 40 (= 1+2+3+4 × 4 rows).

### Widget

`SudokuGrid` gained an optional `cages: List<KillerCage>?`. When
non-null the grid is wrapped in a Stack with an `IgnorePointer`
`CustomPaint` overlay that draws inset cage edges (only where a
cell's neighbour is in a different cage) and a small target-sum
label in the top-left of each cage's anchor cell. The overlay
ignores taps so cell taps still hit the grid underneath.

### Screen

- Variant `SegmentedButton` gained a third "Killer" segment.
- Switching INTO Killer auto-loads the matching Killer preset
  (an empty Killer grid is invalid — cages are required), and
  loading any non-Killer preset clears the cages field.
- Generator controls are disabled when the variant is Killer
  (cage-partition generation is a separate solver pass, deferred).

### i18n + tests

- `sudokuVariantKiller` added to the abstract Localizations API
  + en/de/fr/es implementations. `sudokuPresetLabel('killer4x4')`
  resolves in every locale.
- New `Sudoku — Killer variant` test group: cage partitioning is
  exhaustive, killer4x4 preset's cage sums match a valid solution,
  the same cages solve from an empty grid (no givens), infeasible
  cage sums return no solution, and constructing a killer puzzle
  without cages throws.

## 2026-05-24 (round 62) — Sudoku V3: hint mode (pencil-marks per cell)

The flagship "real Sudoku app" feature: turn on Show Hints and
every empty cell renders a small sub-grid of dimmed digits showing
which values are still legal given the current row, column, box,
and (for Sudoku-X) diagonal occupants. As the user fills in
clues — or as the solver visualizer plays — the candidates
recompute live.

### Engine

- **`SudokuSolver.computeCandidates(puzzle) → List<Set<int>>`**.
  Pure-Dart single-pass elimination ("naked candidates"). For
  each empty cell, returns the digits 1..N minus the union of
  values already present in the same row, column, box, and
  diagonals (if variant is X). Clue cells return the empty set.
- O(N²) per call — fast enough to recompute on every keystroke
  even on 16×16.
- A stricter "AC-3-pruned" version that propagates iteratively
  to a fixed point would catch more eliminations (some "hidden
  singles" the naive version misses), but each call would route
  through the dart_csp bridge — too expensive for live recompute.
  V4 will expose that as an opt-in advanced level.

### Widget

`SudokuGrid` gained an optional `candidates: List<Set<int>>`
param. When non-null, each empty cell's `_Cell` builds a
`_PencilMarks` widget instead of empty space. Sub-grid layout
mirrors the box layout — 9×9 cell → 3×3 sub-grid, 6×6 cell →
2×3, 4×4 → 2×2, 16×16 → 4×4. Each digit `d` sits in its
conventional position so users learn where each digit "belongs"
in the cell. Missing digits render as blank to keep the visual
density low.

### Screen

New `SwitchListTile` "Show hints" between the digit pad and
Solve button. Hint mode is suppressed while the visualizer is
playing a search trace (the two overlays would compete for the
same cell space), and resumes when the user clears the trace
or edits a cell.

### Interaction with variant + size

- Works identically on all four sizes shipped in V2.
- Sudoku-X variant correctly adds the two diagonals to the
  exclusion set when the cell sits on one of them.
- The same toggle flips state across size + variant changes —
  the puzzle reset on layout/variant switch doesn't reset
  `_showHints` (intentional: the user's pedagogy preference
  shouldn't reset on every nav).

### i18n

Two new strings × 4 locales (`sudokuShowHints`,
`sudokuShowHintsSubtitle`) with the standard non-emptiness
coverage check.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **1150/1150**. New tests:
  - All-empty 4×4 → every cell has candidates {1, 2, 3, 4}.
  - Single clue affects row + column + box but not unrelated cells.
  - Clue cells get the empty set.
  - Sudoku-X variant eliminates diagonal occupants (both diagonals).
  - Regular variant does NOT — confirms the X overlay actually
    only fires when the variant flag is set.
- `dart format`: clean.

## 2026-05-24 (round 61) — Sudoku V2: 6×6 + 16×16 layouts + Sudoku-X variant

Round 60 (Sudoku V1) parameterized the layout but only exposed 4×4
and 9×9. V2 fills in the natural next sizes (6×6, 16×16) and adds
the first non-regular variant (Sudoku-X — `allDifferent` on both
diagonals). All three additions are one-line engine changes thanks
to the V1 parameterization.

### Engine

- **`SudokuVariant.regular` / `.x`**: new enum on
  `SudokuPuzzle`. `_buildProblem` adds two more `allDifferent`
  constraints when the variant is `x` (one per diagonal). Composes
  with everything else.
- **`SudokuLayout.medium`** (6×6, 2×3 boxes) and
  **`SudokuLayout.large`** (16×16, 4×4 boxes). The box-partition
  walker handles non-square boxes (`boxRows × boxCols`) correctly
  since V1 — no code change there.
- **`SudokuLayout.all`** list so the picker iterates rather than
  naming constants. Adding 8×8 / 25×25 in a follow-up will be a
  one-line change to this constant.
- **Generator** preserves the `variant` flag through both stages
  (full-grid seed AND clue-peeling uniqueness check). Without
  this, the X variant generator would peel against regular
  rules and ship a non-X solvable puzzle to a user expecting X.
- **Target clue counts** extended for 6×6 (18 / 13 / 9 for
  easy / med / hard, against Wikipedia's stated minimum of 8) and
  16×16 (180 / 140 / 100, against the known-low of 55 — kept high
  because peeling to the absolute minimum on 16×16 frequently
  blows the per-call time budget).

### UI

`SudokuScreen` gains a **`_SizeVariantPickers`** widget above the
preset dropdown:
- Size chip-row with one ChoiceChip per layout in
  `SudokuLayout.all` (4×4 / 6×6 / 9×9 / 16×16).
- Regular / Sudoku-X SegmentedButton.

Switching either selector wipes the grid to an empty puzzle of
the chosen layout+variant — the user can then enter clues
manually, hit Generate for a fresh random puzzle, or pick a
matching preset.

### Presets

- **6×6 medium** added (peeled from canonical valid 6×6 grid).
- **No 16×16 preset** ships — generation is the right path there
  (the V1 hand-picked-clue approach would need verified
  16×16 puzzles which are rare in the public domain).
- **No Sudoku-X preset** ships either — off-the-shelf 9×9
  puzzles tend to have completions whose diagonals contain
  duplicate digits, making them infeasible under the X overlay.
  Users get X-variant puzzles via Generate + the variant toggle.

### i18n

7 new strings (regular/X variant labels × 4 locales, plus 6×6
preset label, plus updated existing-preset switch). All four
locales (en/de/fr/es) updated with localized "Sudoku-X" /
"Klassisch" / "Classique" / "Clásico" labels.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **1145/1145**. New test cases:
  - `SudokuLayout.medium invariants` (6×6 dims).
  - 6×6 preset solves + generator round-trip.
  - Sudoku-X generator round-trip on 9×9 (verifies main +
    anti-diagonals each contain 1..9 exactly once in the
    final solution).
- `dart format`: clean.

### Lessons learned

The "use the standard9x9Easy preset as a Sudoku-X preset" instinct
I had in my first pass was wrong: that puzzle's known unique
solution has the digit 5 (and the digit 7) twice on the main
diagonal — fine under regular rules, infeasible under X. The
generator was the right path. Future variant rounds (Killer,
Disjoint Groups, Hypercube) should also lean on `Generator` rather
than hand-curated presets unless the variant's clue dynamics are
well-understood.

## 2026-05-24 (round 60) — CSP Round B: Sudoku module with step-by-step visualizer

Second slice of the CSP integration plan and the most visible
single feature in the app: a full Sudoku module with puzzle
generation and an animated step-by-step solver. Sits as the 8th
card on the Analysis hub.

### Engine (`lib/engine/sudoku.dart`)

- **`SudokuLayout(side, boxRows, boxCols)`** with an assert that
  `boxRows * boxCols == side`. V1 ships constants for `small`
  (4×4 with 2×2 boxes) and `standard` (9×9 with 3×3 boxes); the
  PLAN.md variant roadmap covers 6×6 / 8×8 / 10×10 / 12×12 /
  15×15 / 16×16 / 25×25, irregular regions, killer.
- **`SudokuPuzzle(layout, cells)`** — flat length-N² int list,
  0 = empty.
- **`SudokuSolver.solve`** — wraps a `csp.Problem` with one
  variable per cell (clued cells get a singleton domain),
  `addAllDifferent` per row / column / box. Returns the filled
  cell list.
- **`SudokuSolver.solveWithTrace`** — same problem, but uses
  `setOptions(callback: ...)` to capture every solver decision
  as a `SudokuTraceFrame`. Each frame is a complete snapshot
  plus the `justChangedIndex` of the cell that flipped, so the
  visualizer can highlight what just happened.
- **`SudokuGenerator.generate`** — two-stage: (1) ask the solver
  to complete an all-empty board seeded with one random clue
  (varies per call), (2) peel clues in shuffled order while
  `hasMultipleSolutions()` returns false. Difficulty knob maps
  to a target clue count (4×4: 10 / 7 / 4; 9×9: 40 / 30 / 22).

### Widget (`lib/widgets/sudoku_grid.dart`)

Pure layout: N×N grid via nested `Column`/`Row` + `AspectRatio`.
Box boundaries get a heavier border than cell boundaries.
Three visual states per cell: clue (bold), filled (primary
color, normal weight), highlight (just-changed by the solver —
brief primary tint). Selection tint at half alpha. Tappable.

### Screen (`lib/screens/sudoku_screen.dart`)

Three-section layout (responsive: side-by-side on ≥720 px wide):

1. **Grid** — the SudokuGrid widget.
2. **Controls** — preset picker dropdown (3 verified-feasible
   4×4 + 3 standard 9×9 puzzles), Generator row (easy/med/hard
   chips + Generate button), digit pad (1..N + Clear), Solve.
3. **Visualizer** — appears after Solve. Header shows
   `current / total` frame count; slider scrubs to any frame;
   icons for Restart / Play-Pause; segmented Slow/Med/Fast
   speed (800/250/50 ms per frame).

### i18n

20 new strings across en/de/fr/es (module title + subtitle,
solve / clear / generate buttons, preset chooser, custom label,
6 preset IDs via templated method, visualizer header, play /
pause / restart, three speeds, three difficulties). The preset-
label dispatcher returns the unknown id as-is so future preset
additions don't crash before translations land.

### Generator design — uniqueness-first

The PLAN.md spec called for "peel clues until uniqueness fails."
dart_csp's `hasMultipleSolutions()` is the load-bearing primitive:
on every peel candidate we ask whether ≥ 2 distinct solutions
exist; if yes, put the value back. Output is by construction a
puzzle with exactly one solution.

Difficulty calibration uses Wikipedia's minimum-clue table as the
lower bound (4 clues for 4×4, 17 for 9×9 — though we sit at 22
for "hard" 9×9 because puzzles below 25 clues tend to need
deep search and the visualizer would emit thousands of frames).

### Round-trip test

The user explicitly asked for a generate → solve round-trip in
addition to unit tests. Implemented as a parametrized helper
running across (4×4, 9×9) × (easy, medium, hard) × varied seeds.
For each combination, generate a puzzle, solve it, and verify:
solution is non-null, every clue is preserved, solution
satisfies row / column / box `allDifferent`. All five
combinations pass.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **1141/1141**. New tests:
  - 19 in `test/sudoku_test.dart` (layout invariants, solve +
    trace + presets, 3 generator unit tests, 5 round-trip
    parameterized).
  - 7 new locale-coverage strings + Sudoku-preset-id dispatch.
  - The "Analysis hub lists all eight modules" assertion now
    scrolls each card into view before checking (necessary at
    1280×800 with 8 cards).
- `dart format`: clean.

### Bugs caught + fixed during the round

- The original 4×4 easy preset I wrote (`1 0 0 4 / 0 0 2 0 / ...`)
  was actually infeasible: column-0 + row-1 + box constraints
  force a contradiction. Replaced all three 4×4 presets with
  cells peeled from the canonical valid grid
  `1 2 3 4 / 3 4 1 2 / 2 1 4 3 / 4 3 2 1`.
- The "8 modules" UI flow test couldn't find Sudoku because the
  ListView scroll position hid it below 1280×800's fold; the
  test now uses `scrollUntilVisible` for each card.

## 2026-05-24 (round 59) — CSP Round A: Constraints module (Diophantine + cryptarithm)

First slice of the CSP integration plan. Wires the user's pure-Dart
`dart_csp` library into a new Analysis-hub module that solves two
classes of problems CrispCalc's symbolic engine couldn't touch:
bounded-integer Diophantine equations (enumerate ALL solutions to
`2x + 3y == 30, x ≤ y`), and cryptarithms (SEND + MORE = MONEY).

### Mechanism

- **`pubspec.yaml`** gets a git-pinned `dart_csp` entry (commit
  `7a05fe5`). Pure Dart, zero native deps — fits the bridge-free
  side of the engine layer.

- **`lib/engine/csp_solver.dart`** is the wrapper. Two public methods:

  - `CspSolver.solveDiophantine({variables, constraints, maxSolutions})`
    accepts `Map<String, (min, max)>` for the variables and a list
    of dart_csp string constraints. Streams up to N solutions
    (default 100); returns a `DiophantineResult` with `solutions`,
    `error`, and `truncated` flags.

  - `CspSolver.solveCryptarithm(expression)` parses
    `WORD1 +|- WORD2 = WORD3`, builds the standard model
    (one 0..9 variable per letter, `allDifferent`, leading-letter
    non-zero, place-value sum equality), and returns the digit
    assignment.

- **`_tryParseLinear` pre-pass** is the trick that makes both modes
  work. dart_csp's string parser handles `x == y`, `x != y`, and
  simple unit-coefficient sums (`x + y == 7`), but stumbles on
  coefficient-bearing forms like `2*x + 3*y == 12` and the larger
  expressions cryptarithm builds (`10000*M + 1000*O + ... == ...`).
  My pre-pass detects those shapes and routes them to dart_csp's
  dedicated `addLinearEquals` / `addLinearLeq` / `addLinearGeq` API
  — same bounds-consistency propagator that gives the README's
  claimed 1800× speedup on SEND + MORE = MONEY. The cryptarithm
  builder collects per-letter coefficients directly and posts one
  `addLinearEquals` call.

### UI

`ConstraintsScreen` is a new module card on the Analysis hub
(7th module). Two tabs:

- **Diophantine**: variables textarea (`x in 0..50` one per line),
  constraints textarea (one per line), Solve button. Result block
  shows numbered solutions in monospace with a Copy button. Errors
  surface inline in an error-colored container.

- **Cryptarithm**: single line input (default
  `SEND + MORE = MONEY`), Solve button, result block listing each
  letter and its assigned digit.

Both tabs use a small in-button spinner during the (typically
sub-second) solve. Long-eval V3's persistent worker isn't wired in
yet — CSP problems at this scale finish well under the 300 ms
watchdog threshold; reach for the worker only if a future round
adds problems that don't.

### i18n

19 new strings (module title + subtitle, tab labels, intro text per
tab, field labels and hints, solve button, error messages, result
headers, copy + toast) across en/de/fr/es. Two templated methods
(`constraintsSolutionsHeader(int)`,
`constraintsTruncatedHeader(int)`) handle pluralization per locale.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **1118/1118** (11 new `csp_solver_test.dart`
  cases covering both modes, 19 new locale-coverage strings,
  updated "Analysis hub lists all seven modules" assertion).
- `dart format`: clean.

### V2 candidates

- Worked-examples catalog entries for the Constraints screen
  (needs a different navigation slot than `pendingInsertExpression`
  which targets the calculator).
- Multiple-solution display for the cryptarithm tab (currently
  fetches `getSolution()` which returns the first one).
- A "show progress" callback via `setOptions(callback: ...)` for
  visualizing the search step-by-step on the Diophantine tab —
  great for pedagogy on small problems.

## 2026-05-24 (round 58) — Worked-examples V2: direct insertion + localized bodies

V1 (round 54) shipped 21 examples with copy-to-clipboard. V2 closes
the two biggest gaps: tapping a row now puts the expression directly
into the calculator's input field (with auto-tab-switch), and every
title + description is translated to DE/FR/ES.

### Direct insertion

New `AppState.requestInsertExpression(expr)` slot. The dialog's row
tap (and the new Insert icon button) pushes the expression there and
closes the dialog. `MainScreen` listens to AppState; when the slot
fills, it routes to the Calculator tab. `CalculatorScreen` also
listens; on its next listener fire it calls `consumePendingInsert()`
to drain the slot, clears the LaTeX field, inserts the expression,
and requests focus.

The Copy icon stays for users who want clipboard behaviour — that's
the only secondary action. Tapping the row primary-action is now
Insert, which matches the user's expectation when they're browsing
a "try this" library.

### Localized titles + descriptions

Each `WorkedExample` gained a stable `id` slug (`derivPoly`,
`quadraticFormula`, `factorial100`, …). `AppLocalizations` gains
two new methods:

- `String? workedExampleTitle(String id)` — returns the localized
  title, or null when the locale has no translation.
- `String? workedExampleDescription(String id)` — same for the
  description.

The dialog uses `t.workedExampleTitle(e.id) ?? e.title` so a missing
translation gracefully falls back to the catalog English. EN's
implementation returns null for every id by design — the catalog
itself IS the English source.

### Search behavior

Substring search now runs over the *visible* (translated) strings,
so a German user types "Mitternachtsformel" and finds the quadratic
formula example. Expression text remains searchable across locales
since it's locale-independent.

### i18n stats

42 new translated strings per non-English locale (21 examples × 2
fields) = 126 new translation entries. Plus one new chrome string
`workedExamplesInsert` ("Insert into calculator" / "In Rechner
einfügen" / "Insérer dans la calculatrice" / "Insertar en la
calculadora") × 4 locales.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **1103/1103** (3 locales × 21 entries × 2 fields
  = 126 new localization-coverage tests + 1 new catalog id-
  uniqueness test). The `worked_examples_localization_test.dart`
  pins coverage for every entry — a future catalog addition that
  forgets to add DE/FR/ES translations fails CI rather than ships
  mixed-language.
- `dart format`: clean.

## 2026-05-24 (round 57) — Long-evaluation V3: persistent worker + true cancel

Replaces the per-call `compute()` model from V1/V2 with a long-lived
worker isolate that owns one `SymbolicMathBridge` for its lifetime,
and wires the Cancel button to actually `Isolate.kill` it.

### Mechanism

`_PersistentWorker` (private to `engine_service.dart`) spawns one
isolate the first time `EngineService.runOpAsync` or
`evaluateAsync` is called and reuses it for every subsequent
request. Communication is a SendPort/ReceivePort handshake:

1. Main spawns worker with `mainPort` as the entry arg.
2. Worker creates its own `ReceivePort` and sends the matching
   `SendPort` back over `mainPort`.
3. Main records the worker's `SendPort` as `_commandPort` and
   completes the startup completer.
4. Every request gets a monotonic id; main posts
   `_WorkerRequest(id, op)` to `_commandPort`; worker dispatches
   to `_runOp(engine, op)` and posts `_WorkerResponse(id, result)`
   back.

### Why one isolate instead of one-per-call

V1/V2 used `compute()`, which spawns a fresh isolate per call.
Each spawn pays a few tens of ms to load `SymbolicMathBridge`
(FFI symbol lookup, finalizer setup, etc.). For a calculator
session with dozens of evaluations that adds up — and crucially
the user feels the latency on the first slow op when the overlay
takes ~50 ms to actually start computing rather than just
displaying.

The persistent worker pays the bridge cost once. Every subsequent
slow op pays only the message-passing overhead (~ms).

### True cancel

V2's cancel used a monotonic run-id to discard the result; the
underlying bridge call still ran to completion in the background.
V3's `cancelInFlight()` calls `_isolate.kill(priority:
Isolate.immediate)` and clears all state. Pending request futures
complete with `EngineCancelled`. The calculator screen's
`_runWithProgress` catches that and re-throws
`_CancelledByUserException` — the existing surface stays the same.
The next request after a cancel pays the spawn cost again (same as
V1's compute() approach), but only on cancel.

### Race-condition fix

When `kill()` fires DURING the initial spawn handshake, the
startup completer might be completed-with-error before
`_ensureStarted`'s `await startup.future` is registered. Dart's
unhandled-error machinery then flags it. Kill now pre-attaches a
no-op error listener (`startup.future.then((_) {}, onError: (_) {})`)
before calling `completeError` so the error is "observed" even
when no one is awaiting yet. Both listeners fire — the await still
throws EngineCancelled, the no-op swallows the unhandled-error
report.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **975/975** (3 new tests: persistent-worker
  sequential calls, cancel-during-pending, respawn-after-cancel).
- `dart format`: clean.

### V4 deferred

Progress callbacks during long-running ops (worker → main mid-
computation), a prioritized request queue, and persistent-worker
reuse across navigation events (currently the worker is
process-scoped, which is fine).

## 2026-05-24 (round 56) — Long-evaluation V2: cancel + handler coverage

V1 (round 51) wrapped only the bare-evaluate path. V2 extends the
async pipeline to every specialized handler and adds a Cancel button
to the progress overlay.

### Generic op dispatch

`EngineService.runOpAsync(EngineOp(kind, arg1, [arg2..arg4]))` is a
new generic entry point. The worker isolate switches on `op.kind`
and dispatches to the matching `CalculatorEngine` method. Currently
wired ops: `evaluate`, `expand`, `simplify`, `factor`, `solve`,
`differentiate`, `integrate` (with optional bounds), `limit`, `gcd`,
`lcm`, `factorial`, `fibonacci`. Adding a new op is one switch case
+ optional argument plumbing through the 5-string `EngineOp` value.

### Handler conversion

Seven `_handleXxxFunction` methods in `CalculatorScreenState`
changed from sync `String` to `Future<String>`. Each now ends with
a call to a new `_runEngineOpMaybeAsync(op, arg1, ..., fallback:
() => _engine.X(...))` helper that:

- Calls the sync `fallback()` directly when
  `EngineService.shouldRunAsync(arg1)` returns false (cheap
  evaluations stay on the main thread).
- Otherwise pushes the call to `EngineService.runOpAsync` wrapped in
  the existing `_runWithProgress` watchdog.

`_calculate` now `await`s each handler, and the bare-evaluate path
shares the same `_runEngineOpMaybeAsync` helper so the codebase has
one rule for "go async" instead of two branches.

### Cancel button

`ProgressOverlay` already had an `onCancel` slot from V1; the
calculator screen now wires it. Implementation uses a monotonic
`_runId` counter:

1. `_runWithProgress` captures the current `_runId` on entry.
2. The Cancel button bumps `_runId` and pops the overlay.
3. When the worker's future resolves, the wrapper checks
   `myRunId != _runId` and throws `_CancelledByUserException` if
   the user moved on.
4. `_runEngineOpMaybeAsync` catches the sentinel and returns
   `Error: cancelled` so the history entry shows the friendly
   error formatter.

This is **discard-on-completion**, not true cancellation — the
worker isolate keeps running because compute() doesn't expose
`Isolate.kill`. The UI is unblocked immediately, which is what
matters for UX. True kill cancellation needs a long-lived
`Isolate.spawn` we can `kill()`; V3 work.

### i18n

One new string `calculating` ("Calculating…" / "Berechne …" /
"Calcul en cours …" / "Calculando…") wires the watchdog message.
Plus the existing `Cancel` button text in `progress_overlay.dart`
now goes through `AppLocalizations` instead of being hardcoded.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **972/972** (4 new `runOpAsync` round-trip tests
  + 1 new locale string).
- `dart format`: clean.

## 2026-05-24 (round 55) — Accessibility audit V1

First pass at making the calculator usable to screen-reader users.
Until today, VoiceOver / TalkBack would announce the keypad's
glyph-only buttons as either nothing or unicode-codepoint mumble —
"u+221A" instead of "square root", silence instead of "backspace".

### CalculatorButton wrapper

`CalculatorButton` now wraps its `FilledButton` in a `Semantics`
widget with `excludeSemantics: true` on the inner button so the
override is the only label screen readers see. A static
`_semanticLabel` map provides spoken equivalents for the
non-pronounceable glyphs:

- Symbols: `⌫ → backspace`, `±`, `√`, `∛`, `ⁿ√`, `^`, `×`, `÷`,
  `·`, `π`, `e`, `∞`, `°`, `φ`.
- CAS shortcuts: `∫ dx → integral`, `d/dx → derivative`,
  `∫⌄ → integral with bounds picker`, etc.
- Misc: `Ans → last answer`, `EXE → evaluate`, `= → equals`,
  `C → clear`.

Plain digits and named functions (`sin`, `solve`, `factor`) aren't
in the map — the literal text is fine for screen readers as-is.

### IconButton tooltips

A bash awk pass over every `IconButton(` in `lib/` confirmed only
two sites still lacked a `tooltip:`. Both fixed:

- `function_editor_screen.dart` — the per-slot clear (`×`) button.
- `memory_dialogs.dart` — the memory-slot delete button.

The calculator's history-search clear-X also gained a tooltip while
I was in there.

### i18n

Three new strings for the new tooltips (`clearSearchTooltip`,
`clearFunctionSlotTooltip`, `deleteMemorySlotTooltip`) implemented
across en/de/fr/es with the standard non-emptiness coverage check.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **964/964** (4 new `calculator_button_test.dart`
  cases pinning the Semantics override behavior + 3 new locale
  strings).
- `dart format`: clean.

### V2 deferred

Keyboard navigation audit (Tab order through Settings + Analysis),
color-contrast verification in both light/dark themes against WCAG
AA, and an on-device VoiceOver / TalkBack pass are V2 work — they
need physical-device testing or screenshot diffing rather than the
synchronous code/string changes that fit a single round.

## 2026-05-24 (round 54) — Worked-example library

Discoverability win: a curated catalog of 21 example problems
covering the major topic areas. Settings → "Worked examples library"
opens a searchable, category-filterable list; tap any row to copy
the calculator expression to the clipboard ready to paste.

### Catalog

`lib/engine/worked_examples.dart` exposes a flat `WorkedExamples.all`
list — each entry is `(category, title, description, expression)`.
21 entries spread across the six categories:

- **Calculus** (6): polynomial / chain-rule derivative, IBP integral,
  definite integral, classic sin(x)/x limit, partial-fractions
  integral.
- **Algebra** (4): quadratic formula, factor x³−8, expand (x+2)⁵,
  simplify a rational expression.
- **Linear algebra** (3): 3×3 determinant, 2×2 inverse, rref of an
  augmented system.
- **Number theory** (4): 100! exact, fib(50), gcd via Euclid,
  isprime trial division.
- **Statistics** (2): compound interest, z-score textbook constant.
- **Units** (2): inline unit conversion, composite-dimension
  arithmetic.

### Dialog

`WorkedExamplesDialog` mirrors the existing ConstantsDialog UX:
search field + horizontal scrollable category chips (All + 6
categories) + scrollable `ListView.separated`. Each row shows the
title, description, monospace expression preview, and a Copy icon.
Whole row is tappable as a shortcut. Copy-to-clipboard pushes a
"Paste into the calculator to try it" SnackBar.

### Scope decisions

- **Example bodies stay English-only for V1.** Translating 21
  example titles + descriptions × 4 locales = 168 strings is its
  own i18n chunk; the dialog chrome (header, search hint, empty
  state, category labels, copy toast, Settings tile) is fully
  localized so the surrounding navigation feels native.
- **Click-to-copy rather than click-to-insert.** Direct insertion
  would need a callback chain from Settings → MainScreen →
  CalculatorScreen; clipboard + paste is one extra tap but works
  identically across phone / tablet / desktop layouts.
- **Catalog test** asserts ≥ 1 entry per category, all fields
  non-empty, titles unique, total in [12..25] — a future refactor
  that accidentally empties a category or duplicates an entry
  fails CI rather than ships.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **956/956** (4 new catalog tests + 14 new
  locale-coverage strings across 4 locales).
- `dart format`: clean.

## 2026-05-24 (round 53) — Step engine integration V4

Two more integration rule families: partial-fraction decomposition
(for rational integrands with distinct integer roots in the
denominator) and two textbook trig-shaped closed forms.

### Partial fractions (cover-up method)

`_partialFractionsStep` fires when the integrand is `num / den` and
the denominator is a polynomial of degree ≥ 2 in `variable`. It
brute-forces integer roots in `[-20..20]` via
`engine.evaluate(substitute(den, var, r))`; for each root `r` with
`Q'(r) ≠ 0` (simple root only), the residue formula gives
`A_r = P(r) / Q'(r)`. The rule then emits two steps:

1. "Partial-fraction decomposition" — shows the sum
   `Σ A_i / (x − r_i)`.
2. "Integrate each term" — each piece becomes `A_i · ln|x − r_i|`,
   joined into the final string.

Restricted to **distinct integer roots** to keep the algorithm tight
(repeated roots would need higher-order numerators in the
decomposition; irreducible quadratic factors would need a real
system-solve). The native bridge does the per-root arithmetic, so
the rule simply doesn't fire without the bridge — preserving the
"falls through to Symbolic integration" headless behavior.

### Trig-shaped closed forms

`_trigShapedAntiderivative` matches two patterns:

- **`1 / (x² + a²)`** → `(1/a)·arctan(x/a)`. Detects a top-level
  sum where one term is `x²` (sign +) and the other is a
  variable-free constant (sign +). Computes `a = √aSq` via
  `engine.simplify`.
- **`1 / √(a² − x²)`** → `arcsin(x/a)`. Detects `sqrt(c − x²)` in
  the denominator via `_matchFunctionCall` + sum-split with the
  required `-x²` and `+c` signs.

These sit BEFORE the partial-fractions block in the rule walker —
`x² + a²` has no real roots, so partial fractions wouldn't fire, but
without these shortcuts the calculator would fall through to the
symbolic integrator and miss the clean closed form.

### i18n

Four new `StepNote` keys (`partialFractions`,
`partialFractionsIntegrate`, `trigArctanForm`, `trigArcsinForm`)
implemented across en/de/fr/es. The exhaustive-coverage test grows
from 37 to 41 keys.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **948/948** (16 new locale-coverage tests for the
  4 new keys × 4 locales).
- `dart format`: clean.

### What's still pending

- Partial fractions for repeated roots and irreducible quadratic
  factors. Both need symbolic system-solve which the bridge
  doesn't yet expose cleanly.
- Trig substitution proper (∫√(a²−x²)dx, ∫√(a²+x²)dx, ∫√(x²−a²)dx)
  needs an inverse-substitution pass that converts the integrand
  through `x = a·sin(θ)` (etc.), integrates in θ, then back-
  substitutes. Deferred to V5.

## 2026-05-24 (round 52) — Import-from-JSON pairs the existing Export

Round 14 shipped Export → JSON-to-clipboard. This round closes the
loop with Import: Settings → "Import data" pastes the same payload
back. AppState gains `importFromJson(Map)` that round-trips through
the existing `exportToJson()` output.

### Tolerant restore

Each top-level key is restored only when present and well-typed:
locale, numberFormat, themeMode, exactIntegerMode, history,
variables, functions, parameters, userFunctions. Missing keys leave
existing state alone — so an export from round 44 (before
`userFunctions` existed) still applies cleanly to a current build.
Unknown keys are silently ignored — so a payload from a *newer*
release doesn't crash on import either. Returns a human-readable
summary string ("locale, theme, 5 history entries, …") for the toast.

### UI

`ImportDataDialog` mirrors `ExportDataDialog`: a multiline `TextField`
with a hint showing the expected `{ "version": 1, … }` shape, a
prominent red "this overwrites your state, no undo" warning, and an
Apply button that runs the import and dismisses with a SnackBar
showing what was restored. JSON parse errors surface as inline
`errorText` rather than a blocking dialog.

### i18n

9 new strings (`importDataTitle`, `importDataSubtitle`,
`importDataWarning`, `importDataApply`, `importDataEmpty`,
`importDataNotObject`, `importDataApplied`, `settingsImportData`,
`settingsImportDataSubtitle`) across en/de/fr/es.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **932/932** (4 new persistence tests covering the
  full round-trip, partial-payload tolerance, empty-payload
  behavior, and unknown-locale graceful skip).
- `dart format`: clean.

### What's still pending

The PLAN bullet for storage hardening originally asked for
"file-system export" too. Held off because cross-platform file
writes need either `file_saver` (third-party dep) or platform-
specific channels, and the existing clipboard-export already covers
the same use case (paste into iCloud Drive, Google Drive, Notes,
etc.). Will reconsider if users ask.

## 2026-05-24 (round 51) — Long-evaluation off-main-thread (V1)

Big integrals, factorials, and matrix ops no longer freeze the UI.
New `EngineService` offloads "potentially slow" evaluations to a
worker isolate via Flutter's `compute()`, and the calculator screen
shows a `ProgressOverlay` if the work hasn't completed within 300 ms.

### Mechanism

- **`lib/services/engine_service.dart`** — new file. Two parts:
  - `shouldRunAsync(expression)` — pure-function heuristic that
    returns `true` when the isolate-init cost is worth paying.
    Triggers on long inputs (>80 chars), CAS function calls
    (`integrate(`, `factor(`, `simplify(`, `expand(`, `solve(`,
    `limit(`), matrix shapes (`Matrix(`, `det(`, `inv(`, `rref(`),
    factorials > 50 (`51!`, `100!`), fibonacci > 100.
  - `evaluateAsync(expression)` — wraps a top-level
    `_evaluateInIsolate` function with `compute()`. The worker
    re-instantiates `CalculatorEngine`, which re-instantiates
    `SymbolicMathBridge` (per-isolate singleton). FFI symbols are
    process-scoped so `DynamicLibrary.process()` finds them in the
    worker. Bridge init costs ~tens of ms per call — acceptable
    overhead for evaluations that take seconds anyway.

- **Calculator screen `_runWithProgress`** — a small async helper
  that launches a 300 ms watchdog `Timer`. If the task hasn't
  completed by then, it pushes a barrier-dismissal-disabled
  `ProgressOverlay` dialog via `showDialog`; on completion, the
  finally block cancels the watchdog and dismisses the overlay
  via `Navigator.pop`. Quick evaluations never see the dialog
  flash.

- **Bare-evaluate path** in `_calculate` now branches on
  `EngineService.shouldRunAsync(preprocessed)` — slow ones go
  through `EngineService.evaluateAsync` wrapped in the watchdog;
  short ones stay on the main thread. The specialized handlers
  (integrate/limit/solve etc.) still run synchronously for this
  round — wiring those into the async pipeline is V2 work.

### Trade-offs

- **FFI + isolates**: each compute() call pays a fresh
  `SymbolicMathBridge()` initialization in the worker isolate. For
  evaluations < 100 ms this overhead is real and noticeable, which
  is why `shouldRunAsync` is conservative — bare arithmetic always
  stays sync.
- **No cancel button (yet)**: the ProgressOverlay supports one via
  its `onCancel` callback, but cancelling a compute() call cleanly
  requires isolate teardown, which V2 will handle alongside the
  long-lived worker.
- **Specialized handlers stay sync**: `_handleIntegrateFunction`,
  `_handleSolveFunction`, etc. don't yet route through
  `EngineService`. They use bridge calls directly. V2 candidate.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **924/924** (7 new tests: 6 for `shouldRunAsync`
  classification, 1 round-trip that confirms `evaluateAsync`
  completes and returns a string even without native bridge
  available in the headless test VM).
- `dart format`: clean.

## 2026-05-24 (round 50) — User-defined function namespace

Named, reusable functions live alongside the existing Y1..Y10 graph
slots. `f(x) = x^2 + 1` defined once works in any expression:
`f(3) + 1` evaluates to 11; `g(f(x))` composes when both sides are
defined.

### Mechanism

- **`UserFunction(name, paramVar, body)`** value type in `app_state.dart`
  with `toJson`/`fromJson`. Names are lowercased and constrained to
  a single letter `a..z` at the dialog level so they can't shadow
  built-ins like `sin`, `gcd`, `Matrix`.
- **`AppState.userFunctions`** — keyed map, persisted as the
  `crisp.userFunctions` shared-prefs entry, included in
  `exportToJson` so backup/restore round-trips.
- **Preprocessor** (`expression_preprocessing_utils.dart`) gains
  `_expandUserFunctions`: a paren-balanced scanner that finds
  `name(<arg>)` calls and rewrites them as `(<body-with-param-replaced>)`.
  Parameter substitution uses identifier-bounded regex
  (`(?<![a-zA-Z_])param(?![a-zA-Z_0-9])`) so `xx` in the body isn't
  mistaken for `x`. The existing `preprocessExpression` loop is now
  a convergence loop over both UDF and Y1..Y10 expansion, so `g(f(x))`
  resolves in two passes.
- **UI**: a `UserFunctionsDialog` reachable from Settings → "User-defined
  functions". List + add + edit + delete; the editor uses a `Form`
  with validators for name (single lowercase letter), param (non-empty),
  and body (non-empty).

### Coverage / scope

- One single-letter name per function (`a..z`). Multi-letter names
  would collide with built-ins and need a real keyword reservation
  pass — skipped for V1.
- One parameter variable per function. Multi-arg UDFs (`f(x, y) = …`)
  are deferred — they'd need a real argument-list parser.
- Composition depth defaults to 4 (`maxDepth: 4`), which covers
  pedagogically realistic stacks without giving cyclic definitions
  enough rope to hang the UI.

### i18n

15 new strings (`userFunctionsTitle`, `userFunctionsHelp`, …,
`settingsUserFunctions*`) across en/de/fr/es. Same non-emptiness
coverage check as every prior round.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **917/917** (13 new tests covering AppState
  persistence, preprocessor inlining for the simple / composition /
  built-in-shadow / cycle-guard / identifier-boundary / non-x param
  cases, plus localization).
- `dart format`: clean.

## 2026-05-24 (round 49) — Step engine integration V3

Three new integration rules in `StepEngine.integrate()`, closing the
two biggest gaps in V2:

### Repeated IBP (∫x^n · f(x) dx for n ≥ 1)

The V2 single-shot IBP only handled n = 1 (∫x·sin(x)dx etc.). V3
generalizes to n ∈ {2..9} by recognizing `x^N` as the algebraic
factor via a new `_smallIntegerPowerOfVar` helper, emitting the IBP
step, and recursing on `N · x^(N-1) · v` where `v` is the
antiderivative of the trig/exp factor. The recursion drops one
power of x each application and bottoms out at the existing n = 1
path (which in turn recurses into the antiderivative-of-`v` step).

The recursive sub-integrand uses `*` rather than the middle-dot for
operator separator — `_splitTopLevelProduct` only recognizes `*`,
and silently failing to decompose the recursive expression would
leave the rule walker stuck on a single-atom string.

### Non-linear u-substitution (∫c · g'(x) · f(g(x)) dx)

For top-level products of the shape `(constant times g'(x)) · f(g(x))`
where g(x) is non-linear and f has a standard antiderivative, V3
verifies the structural match via the bridge: `simplify(other / g'(x))`
must be variable-free. When it is, the rule emits `c · F(g(x))` and
returns. Covers the canonical textbook cases like `2x·cos(x²)`,
`x·exp(x²)` (ratio 1/2), `6x²·sin(x³)` (ratio 2).

The rule sits between the V2 linear u-substitution block and the V2
IBP block in the rule walker, so it gets the right precedence:
`2x·cos(x²)` is u-sub, not IBP. Without a native bridge the bridge
call fails and the rule simply doesn't fire — keeps the existing
"falls through to Symbolic integration" headless behavior.

### Logarithmic-derivative rule (∫c · f'(x)/f(x) dx)

Detects `num / den` where `simplify(num / den')` is a non-zero
constant `c`. Result: `c · ln|den|`. Reuses the same ratio
technique as the non-linear u-sub. Catches `2x/(x²+1)`,
`cos(x)/sin(x)`, etc. — patterns the bare reciprocal rule (V2)
couldn't see because the denominator was non-linear.

### i18n

Three new `StepNote` keys (`ibpRepeated`, `uSubNonlinear`,
`integralLogDerivative`) implemented across en/de/fr/es. The
existing exhaustive-coverage test grows from 34 to 37 keys with
2 new structural tests for the V3 rule labels.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **900/900** (12 new tests for V3 rules + i18n
  coverage). `step_engine_test.dart` gains structural assertions for
  the repeated-IBP rule label on `x^2*sin(x)` and the V2-preserving
  single-shot label on `x*sin(x)`.
- `dart format`: clean.

### Notes

The placeholder-substitution check in
`step_notes_localization_test.dart` uses ratio = '7' rather than '1'
for the `uSubNonlinear` sample, because the localization templates
have a shorter branch when ratio == '1' that doesn't echo the
value back — testing with '1' would falsely accuse the templates of
dropping the placeholder.

## 2026-05-24 (round 48) — Onboarding tour

First-launch overlay introducing the four big features (keypad tabs,
history scroll, function pickers, Analysis hub) as a paged Dialog
with skippable navigation. The persisted `onboardingDismissed` flag
on AppState gates the auto-show — the tour pops at most once per
device.

### Pieces

- **`lib/widgets/onboarding_tour.dart`** — new file. `OnboardingTour`
  StatefulWidget with a 4-page PageView, page-dot indicator, Skip /
  Next / Got-it bottom bar, and a `static Future<void> show(context)`
  helper that wraps `showDialog` and marks
  `AppState.onboardingDismissed = true` on close (whether user hit
  Done, Skip, or back-dismissed). `barrierDismissible: false` so
  the user must engage with one of the explicit buttons.

- **`AppState.onboardingDismissed`** — new bool, persisted as
  `crisp.onboardingDismissed` in SharedPreferences. Defaults to
  `false` so the tour runs on first install but never again.

- **`MainScreen.initState`** — post-frame callback that calls
  `OnboardingTour.show(context)` when the flag is false. Gated on
  `if (!mounted) return;` so test harnesses that disposed the widget
  before the post-frame fires don't crash.

- **Settings → "Replay onboarding tour"** — a `ListTile` with a
  play-arrow trailing icon that runs the same `OnboardingTour.show`.
  Lets users who skipped through find the cards again later.

- **i18n** — 14 new strings (`onboardingSkip`, `onboardingNext`,
  `onboardingDone`, `onboardingPage(int, int)`, four `*Title` +
  four `*Body` for the four cards, plus `settingsReplayTour` +
  `settingsReplayTourSubtitle`) implemented across en/de/fr/es with
  the standard non-emptiness test extended to cover all of them.

### Test fixture changes

All three widget-test entry points (`widget_test.dart`,
`ui_flows_test.dart`, `integration_test/app_smoke_test.dart`) now
pre-set `crisp.onboardingDismissed: true` in their
`SharedPreferences.setMockInitialValues` calls. Without this every
existing test would race against the tour overlay popping over the
screen they're trying to drive.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **886/886** (8 new locale-string checks + 4 new
  AppState persistence tests for the onboarding flag).
- `dart format`: clean.

## 2026-05-24 (round 47) — Unit V5: composite-dimension arithmetic + derived units

Quantity × quantity and quantity / quantity now extend the running
dimension vector instead of bailing — `100 m / 10 s = 10 m/s`,
`5 m * 3 m = 15 m^2`, `36 km / 1 h = 10 m/s`, `1 J / 1 s = 1 W`. The
derived SI units (N, J, W, Pa, Hz) plus their SI-prefixed variants
(kN, MJ, mW, …) join the inline parser's longest-match list.

### Design

The single-dim `Unit` carries one `UnitDimension` enum value (length,
time, mass, …); that's not enough to represent `m²`, `kg·m/s²`, or
`m/s²`. V5 adds a `Dimensions` value type: an integer 4-vector over
the SI base dims (length, mass, time, temperature) with
element-wise multiplication and division as operators. Each
`UnitDimension` maps to a Dimensions vector via `Dimensions.of(d)`
— `velocity` → `(length: 1, time: -1)`, `angle` → all zeros
(dimensionless ratio), etc.

`DerivedUnit` is a sibling of `Unit` that carries a Dimensions
vector directly (no enum needed, since N, J, W, Pa, Hz have no
sensible enum slot). `DerivedUnits.bySymbolWithPrefixes` is the
derived-side equivalent of `UnitCatalog.bySymbolWithPrefixes`, so
`kN`, `MJ`, `mW`, `GPa`, `MHz` all parse with no extra catalog
entries.

The evaluator tracks the running quantity as
`(double valueInCoherentSI, Dimensions dim)`. The first term sets
the anchor unit (preserved across `+`/`-` chains for display, same
as V1). Multiplication / division of two quantities adds / subtracts
the dim vectors. Result formatting prefers:

1. The anchor unit (if the result dim still matches it — keeps
   `5 km + 3 m` showing as `5.003 km`).
2. The single-dim catalog's coherent SI base (so `100 m / 10 s`
   formats as `10 m/s`, picking up the existing velocity entry).
3. The derived-unit table (`5 N`, `60 Hz`, `1 W`).
4. A synthesized base-units string (`15 m^2`, `0.5 m/s^2`) when
   nothing else matches.

### Restrictions kept from V4

- No precedence parser yet, so `5 m + 2 m * 3 s` is still ambiguous.
  Mixing composite-dim mul/div after a sum op returns null; mixing a
  sum op after a composite-dim mul/div returns a clear error message
  ("cannot add or subtract after a composite-dimension
  multiplication / division").
- Temperature arithmetic still refused — offset units don't survive
  unit multiplication (273.15 K + non-temperature value would be
  nonsense), so we keep refusing both inline temp arithmetic and
  composite ops involving °C/°F.
- Conversion via `in <unit>` still requires a *single-dim* target —
  `100 m / 10 s in km/h` works (km/h is in the catalog), but
  arbitrary derived-unit conversion (`100 N in kgf`) waits for the
  derived catalog to grow.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **878/878** (10 new tests for composite-dim and
  derived-unit shapes — including the `36 km / 1 h → 10 m/s`
  cancellation check, the `5 m / 5 m → 1` dimensionless case, and
  the "mixing composite × with sum after is refused" guardrail).
- `dart format`: clean.

### V6 deferred

Parentheses (needs a real Shunting-yard pass), variables (needs to
plumb AppState into the unit-expression evaluator so
`v = 10; v m / 5 s` works), and unit exponents (`5 m^2` as a
literal, vs. the current `5 m * m` workaround).

## 2026-05-24 (round 46) — Statistics V9: paired sign + Wilcoxon rank-sum

Two more nonparametric tests in the Statistics screen's Tests tab,
the natural pair-ups for paired t (V1) and Welch's two-sample t (V2)
when the data violate the normality assumption.

### Paired sign test

`HypothesisTests.pairedSign(before, after)` returns
`SignTestResult` with positive / negative / zero pair counts and
two- + one-sided p-values. Zero differences are dropped (Cochran's
convention). Under H₀: median(difference) = 0, the count of
positives follows `Binomial(n_nonzero, 0.5)`, so the two-sided
p-value is `2 · min(P(X ≤ k), P(X ≥ k))` with k = min(pos, neg),
clamped at 1. Uses the existing `Binomial` distribution from
`distributions.dart` — no new numerical primitives.

### Wilcoxon rank-sum (Mann-Whitney U)

`HypothesisTests.wilcoxonRankSum(sample1, sample2)` returns
`WilcoxonRankSumResult` with the sample-1 rank sum, both U
statistics, and the standard-normal-approximation z + p-values.
Pools the data, ranks with average-rank tie correction, then uses

    z = (U₁ − μ_U) / σ_U
    μ_U = n₁n₂ / 2
    σ_U² = n₁n₂(n₁+n₂+1)/12 · (1 − Σ(tᵢ³ − tᵢ) / (N³ − N))

No continuity correction (matches R's `wilcox.test(..., exact =
FALSE, correct = FALSE)`). Two-sided p = 2·Φ(−|z|). Reliable for
n₁, n₂ ≳ 10. Tie correction kicks in cleanly: the test "handles ties
with average ranks" check pools `[1,2,3,5] vs [2,3,4,6]` and
verifies R₁ = 15 against the hand-ranked average pattern.

### UI

Two new chips on the Tests tab (8th and 9th, after Fisher's exact).
Sign test reuses the paired-t Before/After layout; rank-sum borrows
the Welch's two-sample layout. Same `_verdictBlock` rendering as
every other test.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **868/868** (12 new test cases — 6 for sign,
  6 for rank-sum). Sign-test edge cases: all-positive, all-negative,
  ties-only-throws, symmetric-data-p≈1. Rank-sum edge cases:
  identical samples → z = 0; clearly separated → very small p;
  U₁ + U₂ = n₁·n₂ algebraic check; tie handling via the
  `[1,2,3,5]/[2,3,4,6]` example; swapping samples flips z sign;
  empty sample throws.
- `dart format`: clean.

## 2026-05-24 (round 45) — Step-engine explanations translated to DE/FR/ES

V2 of the plain-language step explanations shipped in round 42. Until
today, every `MathStep.note` was a hard-coded English sentence, so
French and Spanish users got German UI chrome wrapped around English
explanations of the chain rule, IBP, the quadratic formula, etc. — a
glaring i18n gap right in the pedagogical surface.

### Mechanism

Adding a 34-string flat `t.foo` getter for every rule wasn't great
because most of the sentences interpolate variable names (`Let u =
$baseStripped; then du = ($slope)·d$variable`). Per-call-site getter
wouldn't even let the engine encode which placeholders the renderer
needs to fill.

Instead: a tiny `StepNote(String key, Map<String, String> params)`
sidecar on `MathStep`. The engine emits the structured form alongside
the existing English `note` field:

```dart
note: 'Let u = $baseStripped; then du = ($slope)·d$variable.',
noteI18n: StepNote('uSubLinear',
    {'u': baseStripped, 'slope': slope, 'var': variable}),
```

`AppLocalizations` gains one new method: `String? stepNote(StepNote)`.
Each locale implements it as a single switch over `note.key`,
interpolating from `note.params`. Returns null for unknown keys, so
the StepsDialog can gracefully fall back to the English `note`:

```dart
final localized = s.noteI18n == null ? null : t.stepNote(s.noteI18n!);
final text = localized ?? s.note ?? '';
```

### Coverage

34 distinct keys total — 11 in solve, 13 in integrate, 10 in
differentiate. Notes that fire from multiple code paths (e.g.
`exprDoesNotDependOn` reused by both the integration and the
differentiation constant rules; `uSubLinear` reused by power-rule
and logarithm-rule u-sub branches) share a single key. Conditional
notes (`base == variable ? simple : chainRule` inside the power rule;
`argIsVar ? standardSimple : standardChain` inside the function-call
rule) ship as two separate keys so each can be translated naturally
without ternaries leaking into the locale code.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **856/856**. New
  `test/step_notes_localization_test.dart` pins all 34 keys × 4
  locales (137 individual tests), checking each call returns a
  non-empty string and every `params` value appears in the output —
  so a `${p['var']}` typo in any of the 136 sentences would fail
  CI rather than ship as a dropped variable name.
- `dart format`: clean.

### Notes on translation choices

Where idioms diverge: German uses *Mitternachtsformel* for the
quadratic formula, French *formule quadratique*. Inline math (`u`,
`du`, `dv`, `∫`, `Δ`, `±`) is kept verbatim across locales for
universality. The IBP-for-ln(x) note ships as one sentence per locale
rather than splitting on `;` because German prefers the longer
single-clause form.

## 2026-05-24 (round 44) — Exact integer mode (arbitrary-precision results)

First slice of the **P5 Precision & number theory** section: actually
honour the arbitrary-precision integers SymEngine already returns,
instead of silently rounding them through a `double.tryParse`
round-trip in the display pipeline.

The native bridge has been returning exact digit strings all along
(SymEngine evaluates `factorial(100)` against GMP and emits all 158
digits as a string). What was broken: `AppState.formatNumber` ran
every result through `double.tryParse(numberString)` so it could apply
the user's `NumberDisplayFormat` — and any integer past ~2^53 became
`1e158`-ish on the way out, with the trailing digits gone.

### What shipped

1. **Detector helper** (`lib/utils/exact_integer.dart`). Pure-Dart,
   no Flutter import — testable in isolation. `ExactInteger.matches`
   classifies a string as `^-?\d+$`; `digitCount` returns the digit
   count (excluding the leading minus); `abbreviate` truncates with
   a middle ellipsis past `maxLen` digits (`head…tail`) for display
   while leaving the clipboard value untouched.

2. **AppState short-circuit**. New `bool exactIntegerMode` (default
   true, persisted as `crisp.exactIntegerMode`). `formatNumber` now
   bails before the `double.tryParse` path when the result's digit
   count exceeds 15 — the boundary past which doubles start losing
   integer precision. The user's chosen `NumberDisplayFormat`
   (`auto` / `oneDecimal` / `twoDecimal`) still governs everything
   that *does* fit in a double, so the existing
   `formatNumber("129")` → `"129.0"` behaviour for one-decimal mode
   is preserved.

3. **Settings UI**. New `SwitchListTile` in the Settings screen
   between the Theme card and the Layout card. Subtitle spells out
   the trade-off: full digit string vs. compact double-precision
   display.

4. **Calculator-screen badge + tap-to-copy**. History entries whose
   result is an exact integer with >20 digits now render with:
   - A smaller (18 pt vs. 28 pt) result line that wraps and uses
     mid-string abbreviation past 60 digits.
   - An italic caption below — "Exact integer · N digits · tap to
     copy" — in `onSurface.withValues(alpha: 0.6)`.
   - A plain `onTap` on the row that copies the *full* (not
     abbreviated) value to the clipboard, with the same
     `historyEntryCopied` toast the long-press menu uses.
   The existing long-press / right-click context menu is unchanged.

5. **Localization**. Four new keys (`settingsExactIntegerMode`,
   `settingsExactIntegerModeSubtitle`, `exactIntegerBadge(int)`,
   `exactIntegerTapToCopy`) implemented in en/de/fr/es with a
   non-emptiness test covering all four locales and verifying the
   templated badge interpolates the digit count.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **718/718** (4 new locale strings × 4 locales, 21
  new `ExactInteger` unit tests, 5 new `AppState` persistence /
  preservation tests including a full 158-digit `100!` round-trip
  through `addHistoryEntry`).
- `dart format --output=none --set-exit-if-changed lib/ test/`:
  clean.

### What this *doesn't* do

The toggle is a display-layer fix, not new symbolic capability —
the underlying GMP arithmetic was already happening inside SymEngine.
The next items in Group A (arbitrary-precision real constants via
MPFR templated calls like `pi(50)`, and the FLINT number-theory toy
set: `isprime`, `factorint`, `totient`, etc.) need actual bridge
work in the C++ wrapper before they can ship.

## 2026-05-17 (round 43) — i18n sweep + function context menu

Two coordinated UX improvements driven by user feedback during the
live dev-build session:

1. **Navigation from function tile straight to graphing.** The
   variable viewer's "Graph Functions" section already showed each
   Y-slot, but tapping just inserted the expression back into the
   calculator. Now each tile carries a dedicated chart-icon button
   that switches the main nav to the Graphing tab, plus a richer
   **context menu** on long-press / right-click (`onSecondaryTap`)
   with six actions:
   - Show on graph (switches to the Graphing tab)
   - Analyze (curve sketching) — switches to the Analysis hub
   - Differentiate — inserts `diff(<expr>, x)` into the calculator
   - Integrate — inserts `integrate(<expr>, x)`
   - Solve f(x) = 0 — inserts `solve(<expr> = 0, x)`
   - Copy expression — to clipboard

   The callback chain runs from `MainScreen._select()` →
   `CalculatorScreen` → `CalculatorKeypad` → `VariableViewer` →
   `_FunctionTile`. The FunctionEditor's `Graph this function`
   button now uses the same callback rather than pushing a fresh
   route on top of the IndexedStack, so back-navigation no longer
   pops you into a stale duplicate calculator.

2. **Big i18n sweep.** Replaced the last batch of hardcoded English
   strings the user flagged:
   - Variable viewer: section headers ("Variables", "Graph Functions",
     "Memory Slots") + the function-tile context menu labels.
   - Unit converter dialog: title, the six dimension labels (Length,
     Time, Mass, Temperature, Velocity, Angle), value field, Close
     button.
   - Plane Analysis: title, Coordinate / Parametric segmented-button
     labels, Analyze button.
   - Curve Sketching: input prompt, all result-card titles (Warnings,
     Derivatives, Key Points, Y-Intercept, Roots, Extrema, Inflection
     Points), "no extrema / no inflection" messages, and the
     "Point: ..." prefix.
   - Statistics: screen title, all four tab labels (Descriptive,
     Regression, Distributions, Tests), and every descriptive-stats
     row label (Count, Sum, Mean, Median, Mode, Min, Max, Range,
     Variance, Std. deviation, Q1, Q3, IQR).
   - Conic Sections: screen title, Classify button.
   - Help screen: "Probability" group header and the rref function
     description (rest of the help-text deferred).
   - Function Editor: title, Done button, snackbar message, Analyze
     and Graph tooltips.

3. **Engine-emitted classification strings.** Rather than refactor
   the analysis engine to emit symbolic keys, a small
   `AppLocalizations.translateClassification(raw)` extension method
   maps the well-known English markers ("Local Minimum", "Local
   Maximum", "Critical Point", "Inflection Point", "No critical
   points found", "Function has constant concavity (f''(x) = 0
   everywhere)", "No inflection points found") to their localized
   equivalents at render time. Unrecognized text passes through. The
   curve-analysis results screen uses this when rendering extremum
   and inflection lists.

4. **Unit Converter is now in the Analysis hub.** Previously buried
   in Settings. Surfaced as a 6th `_ModuleCard` with `Icons.swap_horiz`.
   The Settings entry is left in place for backward compatibility.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **694/694** (the existing localization test now
  exercises 50+ new keys across all four locales).
- Updated `ui_flows_test.dart`'s "Analysis hub lists all five modules"
  → "all six modules" to include Unit Converter.

### V2 deferred

The analysis engine still emits English markers for less-common
strings ("No critical points (f'(x) = ...)", "Function is constant",
"Error: Invalid function", etc.) — the `translateClassification`
helper covers the common cases but a fuller engine-side refactor to
return structured kind/payload tuples would be cleaner. Help screen
group titles (Arithmetic, Trigonometric, Vector, Matrix) and per-
function descriptions are still English; only "Probability" + the
rref description are localized.

## 2026-05-17 (round 42) — Step engine: plain-language rule explanations

Every common differentiation, integration, and solve rule now emits
a one-sentence English `note` alongside its formal LaTeX formula.
The StepsDialog already rendered the `note` field italicized below
each step; this round audited which rules were quietly emitting `null`
notes and gave them educational explanations.

### Coverage added

**Differentiation:** Identity (d/dx[x]=1), Sum/difference rule,
Product rule, Quotient rule, Power rule (both pure-power and
chain-rule cases), Exponential rule, standard function derivatives
(sin/cos/tan/asin/.../sqrt) for direct-argument cases.

**Solve (linear):** Original equation, Move all terms to one side,
Identify coefficients, Subtract the constant, Divide by the
coefficient.

**Solve (quadratic):** Identify coefficients, Compute the
discriminant (with a hint about how Δ's sign maps to root count),
Apply the quadratic formula.

**Integration:** Leading-minus Constant multiple, Power rule (both
n=1 and general n), Sum/difference rule (linearity), Constant
multiple, both Logarithm rule emission sites, Standard antiderivative
(sin/cos/exp/sinh/cosh on the variable).

V2 round-34 rules (linear u-substitution, integration by parts)
already had detailed notes and were left untouched.

### Smoke test

Added a `rule notes — educational explanations are present` group to
`step_engine_thorough_test.dart`. It picks 10 representative
expressions, finds the named rule's step, and asserts the note
isn't empty — so a future refactor that accidentally drops a note
will fail loudly.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **694/694** (+10 new note-presence tests).

### V2 deferred

Translate the notes to DE/FR/ES locales. Currently English-only;
the StepsDialog renderer doesn't need any change to localize them
later — only the strings inside the engine.

## 2026-05-17 (round 41) — Statistics V8: Fisher's exact 2×2

Pairs with round 39's χ² independence. When any expected cell count
under H₀ falls below ~5, the large-sample χ² approximation is
unreliable — Fisher's exact gives the right p-value by enumerating
every contingency table with the same row/column margins.

### Math (lib/engine/hypothesis_tests.dart)

`HypothesisTests.fisherExact2x2(a, b, c, d)` returns
`FisherExactResult{a, b, c, d, pObserved, pValueTwoSided,
pValueOneSidedUpper, pValueOneSidedLower, rejectsAt(α)}`.

Conditional on fixed row totals `(a+b, c+d)` and column totals
`(a+c, b+d)`, the count `a` follows a hypergeometric distribution:

```
P(A = k) = C(r1, k) · C(r2, c1 − k) / C(n, c1)
```

The two-sided p-value follows R's `fisher.test()` convention: sum
P(table) over all tables with the same margins whose probability
is `≤ P(observed)`. This is more rigorous than the "double the
smaller tail" doubling convention and handles asymmetric
distributions correctly.

Implementation uses log-domain via the new public `logChoose(n, k)`
helper (exposed from `distributions.dart`), so large totals like
`fisherExact2x2(80, 20, 10, 90)` don't overflow.

### UI (lib/screens/statistics_screen.dart)

7th chip on the Tests tab. Input is a single comma/space-separated
line: `a, b, c, d`, where `[[a, b], [c, d]]` is the 2×2 table.
Result card shows all four cell values, P(observed), two-sided p,
both one-sided p-values, and the verdict block.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **684/684** (+8 new tests, including Fisher 1935's
  original tea-tasting example (3/4 correct → p ≈ 0.486; 4/4 correct
  → p ≈ 0.0286 matching R's `fisher.test()` output) and a large-
  totals stability test).

### V9 deferred

Paired sign test, Wilcoxon rank-sum.

## 2026-05-17 (round 40) — Unit V4: scalar × quantity arithmetic

Round 35 (SI prefixes) handled exotic unit symbols; this round handles
the most common arithmetic-on-quantities pattern the inline parser
was still missing — multiplying or dividing a unit value by a pure
number.

### Now working

- `2 * 5 km` → `10 km` (leading scalar prefix)
- `5 km * 2` → `10 km` (trailing scalar)
- `5 km / 2` → `2.5 km`
- `5 km * 2 / 4` → `2.5 km` (chained)
- `5 km * 2 + 3 m` → `10.003 km` (scalar mul before sum)
- `3 km / 2 in m` → `1500 m` (combine with conversion suffix)
- `1 mile / 2 in km` → `0.804672 km`

### Deliberately refused

- `5 km + 3 m * 2` falls through (returns null → CAS path). Without a
  Shunting-yard parser, applying `*` to "just the last term" vs "the
  whole accumulator" would surprise users half the time; rather than
  guess, V4 only allows scalar mul/div when no `+`/`-` has appeared
  yet. We document this in the file header.
- `5 km * 2 s` (RHS has a unit) falls through — that's quantity-×-
  quantity, which is V5 territory (needs DimensionVector arithmetic
  and derived-unit recognition).
- `5 km / 0` returns `Error: division by zero in unit expression`.

### Implementation (lib/engine/unit_expression.dart)

The parser already split off `in <unit>` suffixes and walked
`(+|-) <quantity>` pairs. Two small additions:

1. **Leading scalar prefix.** If `[number, *, ...]` at the head of
   the working tokens, peel the prefix off and stash it; multiply
   `basePos` by it at the end.
2. **Trailing scalar mul/div in the operator loop.** When we see
   `*` or `/`, require an `_NumberToken` RHS that is *not* followed
   by a `_UnitToken`, and refuse if a `+`/`-` has happened earlier
   (precedence guard).

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **676/676** (+11 new V4 tests covering prefix /
  suffix scalar, chaining, precedence-rejection, division-by-zero,
  and quantity-×-quantity fall-through).

### V5 deferred

Composite-dimension arithmetic, derived-unit catalog entries (N, J,
W, Pa, Hz), parens, variables.

## 2026-05-17 (round 39) — Statistics V7: χ² independence

The seventh and likely last "core" hypothesis test the V1 inferential
toolkit needs. Tests whether two categorical variables are
statistically independent given an R×C contingency table.

### Math (lib/engine/hypothesis_tests.dart)

`HypothesisTests.chiSquareIndependence(observed)` returns
`ChiSquareIndependenceResult{statistic, df, pValue, rowTotals,
colTotals, grandTotal, expected, observed, rejectsAt(α)}`.

Under H₀ (row and column are independent), expected cell counts are
`E[i,j] = (rowTotal[i] · colTotal[j]) / grandTotal`. The test
statistic is `χ² = Σᵢⱼ (Oᵢⱼ − Eᵢⱼ)² / Eᵢⱼ` with df = (R − 1)(C − 1).
p-value comes from the upper tail of χ²(df).

Validation: throws on <2 rows or <2 cols, ragged rows, negative
cells, any zero row or column total, or zero grand total. The zero-
margin checks prevent division-by-zero in the expected-count
calculation and call out the bad cell directly so the user knows
what to fix.

### UI (lib/screens/statistics_screen.dart)

Tests tab now has six chips. The contingency table input is a multi-
line TextField — one row per line, comma- or space-separated cells.
Result card shows χ² statistic, df, grand total, p-value, and the
verdict block.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **665/665** (+9 new tests: proportional table → χ² = 0,
  classic 2×2 smokers/cancer example with strong association,
  hand-checked 3×2 with all-15 expecteds, and six error-path tests).

### V8 deferred

Paired sign test, Wilcoxon rank-sum (non-parametric two-sample),
Fisher's exact test (small-sample 2×2 alternative when expected
counts are below 5).

## 2026-05-17 (round 38) — Statistics V6: ANOVA + F-distribution

Adds the standard one-way analysis of variance to the Tests tab,
plus the underlying Snedecor's F-distribution to the distributions
module. Round 36 covered all the regression V4 + V5 ground (Welch's
t-test); this round closes out the most common K-group hypothesis
test.

### F-distribution (lib/engine/distributions.dart)

`FDistribution(d1, d2)` with `pdf`, `cdf`, `sf` (survival function),
`quantile`, and `mean` (defined when d2 > 2).

Two tricky cases:
- For `d1 = 1`, the PDF has an integrable 1/√x pole at x = 0 that
  Simpson can't handle. Use the t-distribution shortcut:
  `F(1, d2).cdf(x) = 2·t(d2).cdf(√x) − 1`.
- For deep upper-tail probabilities (where `1 − cdf(x)` would lose
  all its significant digits), use the reciprocal-F relation:
  `sf(x) = F(d2, d1).cdf(1/x)`. This is the right thing for ANOVA
  p-values when F is large — without it the test that should reject
  at α = 1e-9 returned `rejectsAt(0.001) = false` because `cdf(F)`
  capped at exactly 1.0.

### One-way ANOVA (lib/engine/hypothesis_tests.dart)

`HypothesisTests.anovaOneWay(List<List<double>> groups)` computes:

```
SS_between = Σᵢ nᵢ (x̄ᵢ − x̄)²,            df_b = K − 1
SS_within  = Σᵢ Σⱼ (xᵢⱼ − x̄ᵢ)²,            df_w = N − K
F          = (SS_between / df_b) / (SS_within / df_w)
p          = FDistribution(df_b, df_w).sf(F)
```

Returns `AnovaResult` with `fStatistic, dfBetween, dfWithin,
ssBetween, ssWithin, msBetween, msWithin, groupMeans, groupSizes,
grandMean, pValue, rejectsAt(α)`.

Validation: throws on <2 groups, any empty group, fewer total obs
than groups, or zero within-group variance (F undefined).

### UI (lib/screens/statistics_screen.dart)

Tests tab now has five chips. The ANOVA input is a multi-line
TextField — one line per group, comma- or space-separated within a
line. Result card shows per-group means and sizes, the full ANOVA
table (SS, df, MS, F), the p-value, and the verdict block.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **656/656** (+14 new tests: 6 F-distribution
  textbook-quantile checks; 8 ANOVA tests including the F ≈ t²
  identity for K = 2 groups).
- Hogg & Tanis chapter 9 worked example reproduces hand-calculated
  SSB ≈ 23.33, SSW = 6, F ≈ 23.33.

### V7 deferred

χ² independence (contingency tables), paired sign test, Wilcoxon
rank-sum.

## 2026-05-17 (round 37) — Statistics V5: Welch's two-sample t-test

Extends `HypothesisTests` and the Statistics screen's Tests tab with
the most-requested missing inferential test from V1.

### Math (lib/engine/hypothesis_tests.dart)

`HypothesisTests.welchT(sample1: ..., sample2: ...)` returns
`TwoSampleTResult{statistic, df, mean1, mean2, stddev1, stddev2, n1,
n2, pValueTwoSided, pValueOneSidedUpper, pValueOneSidedLower,
rejectsAt(α)}`.

Welch's variant is the default in R's `t.test()` and the modern
textbook recommendation over pooled Student's t — it doesn't assume
equal variances and gives sensible inference even when the samples
are heteroscedastic. The formula:

```
t = (x̄₁ − x̄₂) / √(s₁²/n₁ + s₂²/n₂)
df = (s₁²/n₁ + s₂²/n₂)² / ((s₁²/n₁)²/(n₁−1) + (s₂²/n₂)²/(n₂−1))
```

The Welch-Satterthwaite df is non-integer in general; we expose it
as a `double` on the result and round when passing into our t-CDF
(which takes integer df). That's the standard textbook workaround.

Throws if either sample has fewer than 2 observations or zero
variance.

### UI (lib/screens/statistics_screen.dart)

`_TestKind` enum gains `twoSampleT`; the Tests tab's chip-row now
has four chips (one-sample t, two-sample t (Welch), paired t, χ²
GOF). `_buildTwoSample()` mirrors the existing one-sample layout
with two `Sample` inputs and a result card showing both sample
statistics + the Welch-Satterthwaite df.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **642/642** (+7 new tests: equal-means edge case,
  textbook example hand-verified against R's `t.test()` output
  (t=-2.449, df=10), strongly-different-means rejection, p-tail
  symmetry, unequal-variance handling, two error paths).

### V6 deferred

ANOVA (one-way), χ² independence (contingency tables), F-distribution,
paired sign test.

## 2026-05-17 (round 36) — Statistics V4: exponential regression

Rounds out the regression cluster. The Statistics screen's Regression
tab now picks between linear, polynomial (degree 2–5), and
exponential fits via a chip-row at the top — no separate dialog, no
mode switch elsewhere.

### Math (lib/engine/statistics.dart)

`Statistics.expFit(xs, ys)` fits `y = a · exp(b · x)` by log-
linearization: take `ln(y) = ln(a) + b · x` and run an ordinary
linear regression on `(x, ln(y))`. Returns an `ExponentialFit` struct
with `a`, `b`, `rSquared`, `count`, and an `evaluate(x)` helper.

R² reflects the log-space fit (matches R's `lm(log(y) ~ x)` and most
textbooks), which is the right thing to report — recomputing in raw-
y space tends to be dominated by the largest data points and gives a
misleading picture of fit quality. We document the convention in the
class doc comment so users see it next to the value.

Validation: throws on length mismatch, fewer than 2 points, or any
non-positive y (the `log` would be undefined).

### UI (lib/screens/statistics_screen.dart)

`_RegressionTab` now keeps a `_RegressionModel` enum
(`linear | polynomial | exponential`) and a degree selector that
shows only when polynomial is picked. The result card is rendered by
`_resultCard()` which shares headline + formula + details layout
across all three modes.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **635/635** (+7 new tests: exact recovery of `a, b`
  on synthetic data, negative-`b` decay, evaluate() round-trip,
  classic bacterial-growth textbook case, three error-path tests).

### V5 deferred

Two-sample t-test (independent), ANOVA, χ² independence,
F-distribution.

## 2026-05-17 (round 35) — Unit V3: SI prefix parser

Extends `UnitCatalog` so the inline parser recognizes every standard
SI prefix combined with the canonical metric bases, without having
to hardcode hundreds of catalog entries.

### Mechanics

`UnitCatalog.bySymbolWithPrefixes(symbol)` is the new entry point:

1. Try the curated catalog first — `mg`, `km`, `cm`, `μs`, `ms` etc.
   stay as their explicit entries so the dimension classification is
   unambiguous.
2. If miss, walk SI prefixes longest-first (so `da` beats `d`) and
   ask whether the remainder is one of the prefixable bases:
   `{m, s, g, K, rad}`. On match, synthesize a `Unit` with
   `scale = prefix.factor * base.scale`.

Prefixable bases are intentionally tight — restricted to the canonical
SI metric units — so the parser can't accidentally interpret `tin`
("teraInch") or `kt` ("kilotonne") as something the user didn't mean.

### Examples now working inline

- `1 pm in m` → `1e-12 m`
- `1 Tm in km` → `1e9 km`
- `1 dam in m` → `10 m` (deca beats deci)
- `5 ps + 3 ns in ns` → `3.005 ns`
- `1 Gg in t` → `1000 t`
- `300 μK in K` → `0.0003 K`

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **628/628** (+13 new SI-prefix tests).

### V4 deferred

Composite-dimension arithmetic (`m/s² * 2 s = m/s`), scalar-quantity
multiplication, derived-unit catalog entries (N, J, W, Pa, Hz).

## 2026-05-17 (round 34) — Step engine V2: u-substitution + IBP

Extends `StepEngine.integrate()` beyond the V1 fixed-rule list. The
two single biggest textbook techniques — linear u-substitution and
integration by parts — now produce proper step traces instead of
falling through to the symbolic integrator with a "no rule matched"
note.

### New rules

- **Linear u-substitution (power)**: `∫(ax+b)^n dx = (ax+b)^(n+1)/(a(n+1))`
  for constant `n ≠ -1`.
- **Linear u-substitution (logarithm)**: `∫1/(ax+b) dx = ln|ax+b|/a`,
  triggered from both `(ax+b)^(-1)` and `1/(ax+b)` shapes.
- **Linear u-substitution (standard antideriv)**: `∫f(ax+b) dx = F(ax+b)/a`
  for `f ∈ {sin, cos, exp, sinh, cosh}`.
- **Integration by parts (LIATE-Algebraic-vs-rest)**: for `∫x·f(x) dx`
  with `f ∈ {sin, cos, exp, sinh, cosh}`. Picks `u = x` (Algebraic
  beats Trig and Exponential in LIATE), `dv = f(x) dx`, recurses on
  the resulting `∫v du`.
- **Integration by parts (ln)**: `∫ln(x) dx = x·ln(x) − x` as the
  special case where the integrand has no obvious product structure
  but IBP with `dv = dx` collapses cleanly.
- **Leading minus normalization**: `∫(-f) dx = -∫f dx`, so the IBP
  recursion on shapes like `-cos(x)` doesn't dead-end at a function
  call the existing rules didn't see (they only matched the bare
  function name without a leading minus).

### Implementation

`_linearSlope(expr, variable)` is a pure-Dart linearity test that
returns the slope-as-string when `expr` is a top-level sum of
constant-multiple-of-variable terms plus pure-constant terms. It
deliberately excludes function calls, denominators, and powers in
any variable-containing factor, so it picks up `2*x + 1` and `x - 3`
but never `sin(x) + 1`, `x^2 + 1`, or `1/x`.

Outer parens on the inferred `u` are stripped before being woven
into the result string, so the user sees `ln|x+1|/(1)` instead of
`ln|(x+1)|/(1)`.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **615/615** (20 new tests: 8 V2 linear u-sub rule-
  selection, 6 V2 IBP rule-selection, 6 V2 antideriv shape checks).
- Steps diagnostic battery (`CRISPCALC_DIAGNOSTIC=steps` on the
  macOS release binary): 37/37 with new V2 specs for `∫sin(2x)`,
  `∫cos(3x)`, `∫exp(3x)`, `∫(2x+1)^3`, `∫1/(x+1)`, `∫1/(2x+1)`,
  `∫ln(x)`, `∫x·sin(x)`, `∫x·exp(x)`.

### V3 deferred

Non-linear u-substitution via pattern detection (`∫f(g(x))g'(x)dx`),
partial fractions, repeated IBP for `∫x^n·f(x)dx`, trig
substitution, and Weierstrass substitution.

## 2026-05-17 (round 33) — 3D graphing (V1)

A new Analysis-hub module: interactive 3D wireframe surface plots of
z = f(x, y). Hand-rolled rotation + orthographic projection, no
`vector_math` dependency.

### Math + rendering (lib/screens/graphing_3d_screen.dart)

- **Sampler**: evaluates the user's expression on a 33×33 (grid = 32)
  lattice over `[−range, +range]²`. Substitutes numeric `x` and `y`
  literals into the expression *before* the preprocessor pass — so a
  stored AppState variable named `x` can't shadow the coordinate.
  Each cell goes through `evaluateForGraphing` and any non-numeric
  return falls back to NaN, which the wireframe just skips.
- **Projection**: an azimuth rotation around world-z, then an
  elevation rotation around the rotated x-axis, then drop the depth
  coordinate (orthographic). `z` is recentered around its midpoint
  and scaled so the surface visually fits alongside the x/y range.
- **Wireframe**: connects `(i,j) → (i+1,j)` and `(i,j) → (i,j+1)`,
  colored by mid-height z in HSV from blue (low) to red (high).
- **Axes**: three colored lines through the origin (X red, Y green,
  Z blue) so the user always knows where they are after rotating.
- **Legend**: a small `[zMin, zMax]` + azimuth/elevation readout in
  the top-left corner of the canvas.

### UI

- `Graphing3DScreen` with a TextField for the function (defaults to
  `sin(x) * cos(y)`), a Plot button, a ±range slider (1..20), and a
  "Reset view" + "Re-sample grid" action pair.
- `GestureDetector.onScaleUpdate` handles both drag (rotate) and
  pinch (zoom, clamped 0.2..5.0). Elevation is clamped to
  ±π/2 − 0.01 to prevent the gimbal degenerate.
- Listed as the 5th `_ModuleCard` in `analysis_hub_screen.dart`
  with `Icons.threed_rotation`.

### i18n

Six new strings (`module3DTitle`, `module3DSubtitle`,
`module3DFunctionLabel`, `module3DRangeLabel`, `module3DResample`,
`module3DTapPlot`) translated to en/de/fr/es and covered by
`localizations_test.dart`.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **595/595**, including the updated UI flow test
  ("Analysis hub lists all five modules") and the new i18n coverage.
- macOS release build: green.

### V2 deferred

- Hidden-line removal (current wireframe has no depth ordering, so
  a back-facing edge can draw on top of a front-facing one).
- Perspective projection (currently orthographic).
- Contour overlay lines at constant z.
- Parametric 3D curves (`(x(t), y(t), z(t))`).
- Surface-plane intersection (reuses round 23's plane math).

## 2026-05-17 (round 32) — Hypothesis tests UI

V3 of the Statistics module, built on the t/χ² infrastructure from
round 30. The Statistics screen gains a 4th tab — "Tests" — and the
underlying math layer ships three of the most-used:

- **One-sample t-test**: H₀: μ = μ₀. Computes
  t = (x̄ − μ₀)/(s/√n) with df = n−1.
- **Paired t-test**: H₀: μ_diff = 0. Wraps one-sample t over the
  pointwise differences.
- **χ² goodness-of-fit**: χ² = Σ(Oᵢ−Eᵢ)²/Eᵢ with df = k−1 (no
  parameters estimated). p-value is the upper-tail probability
  under χ²(df).

### Math (lib/engine/hypothesis_tests.dart)

`HypothesisTests.oneSampleT()`, `pairedT()`, `chiSquareGof()` return
result structs with statistic, df, p-values, and a `rejectsAt(alpha)`
helper. Both two-sided and one-sided p-values are computed for t-tests
so the UI can show all three. Defensive on inputs — throws
`ArgumentError` on zero variance, length mismatches, or zero/negative
expected counts.

### UI (lib/screens/statistics_screen.dart)

A 4th tab "Tests" with chip-row picker for test type, a shared
significance-level field, per-test inputs (sample data + μ₀ for
one-sample t; before/after lists for paired t; observed/expected
counts for χ²), and a result card with every diagnostic plus a
colored verdict block in the theme's `errorContainer` / `primaryContainer`
depending on whether H₀ is rejected.

### Verification (textbook examples)

- One-sample t: heights [172, 174, 168, 180, 176], μ₀ = 170.
  Hand-computed: x̄ = 174, s = √20 ≈ 4.472, t = 2.0, p ≈ 0.116
  at df=4 — matches.
- χ² GOF: Mendel's pea data {315, 108, 101, 32} against 9:3:3:1
  ratios → χ² ≈ 0.470, df = 3, p ≈ 0.925 — matches historical value.
- Fair die simulation {9,11,10,12,9,9} → χ² = 0.8, not rejected.
- Rigged die {5,5,5,5,5,35} → rejected at α = 0.01 with p < 1e-6.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **595/595** (16 new tests: 6 one-sample t, 4
  paired t, 6 χ² GOF; 1 skipped is documented as intentional —
  identical pairs trigger the zero-variance throw).
- macOS release: matrix self-test 7/7, step self-test 28/28.

---

## 2026-05-17 (round 31) — Inline unit syntax in the calculator

V2 of the unit converter (round 24). Users can now type
`5 km + 3 m`, `1 mile - 200 yd`, or `100 km/h in mph` directly in
the calculator's expression field and get back a quantity with a
unit. The unit converter dialog from round 24 stays — it's still the
right tool for a single conversion — but inline arithmetic was the
real V2 ask.

### Architecture

`lib/engine/unit_expression.dart` is a tiny tokenizer + evaluator
plus a one-line hook in the calculator screen's `_calculate`:

- Tokenizer walks the raw user input and emits `_NumberToken`,
  `_UnitToken`, `_BinaryOp`, or `_InKeyword`. Returns null on any
  unrecognized character — that's the signal to fall through to
  the scalar evaluator.
- Unit symbols are matched longest-first so multi-char tokens like
  `m/s`, `km/h`, `mph` win over substrings.
- Natural-spelling aliases (`mile` → `mi`, `feet` → `ft`,
  `meters` → `m`, `hours` → `h`, etc., ~30 entries) translate
  conversational input to catalog symbols.
- The screen hook lives just after the `solve(...)` / `factor(...)`
  function-name dispatch, before the regex-based preprocessor that
  would otherwise insert implicit multiplication and break the
  `5 km` shape.

### Supported shapes

- `<number> <unit>` (single quantity, returned as-is)
- `<number> <unit> {+|-} <number> <unit> …` — same-dimension
  arithmetic. Result displays in the first term's unit by default.
- Any of the above with a trailing `in <target_unit>` — converts
  to that unit. Dimension mismatch returns a friendly error.
- Temperature: arithmetic refused (offset units make `5 °C + 10 °C`
  ambiguous); single-quantity `in` conversion still works.

### Examples

- `5 km + 3 m` → `5.003 km`
- `1 mile + 5 ft` → `1.0009466 mi`
- `1 m + 50 cm + 100 mm` → `1.6 m`
- `100 km/h in mph` → `62.137 mph`
- `180 ° in rad` → `3.14159 rad`
- `100 °C in °F` → `212 °F`

### What didn't quite work first time

- Dropped `mile` and `feet` from a first commit assuming users would
  type `mi` and `ft`. Tests immediately caught this — added the
  alias map.
- Initial test tolerance of `1e-6` was tighter than the formatter's
  rounded display; loosened to `1e-3` relative tolerance (3 sig
  digits) which is what matters anyway for a calculator UI.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **579/579** (26 new tests: 7 fall-through
  invariants, 3 single-quantity, 3 addition, 2 subtraction,
  2 dimension-mismatch errors, 4 conversion, 3 temperature, 2 angle).
- macOS release: matrix self-test 7/7, step self-test 28/28.

---

## 2026-05-17 (round 30) — UI flows + stats V2: polynomial / t / chi-square

Two threads in one round: PLAN's "UI flow tests" gap and the V2 of the
statistics module from PLAN P5.

### CI: pin Flutter 3.38.5

`channel: stable` was floating to 3.41.9 whose `dart format` rules
differ from local dev's 3.38.5, so the format gate has been flaking on
every push. Pinned `ci.yml` to 3.38.5 explicitly. Build workflows
stay on `stable` since they don't run the format check — they verify
the pipeline.

### UI flow tests

`test/ui_flows_test.dart` covers the most-likely-to-break Settings +
Analysis hub flows:

- Help screen lists the function reference (with scroll-to anchors).
- Constants dialog filters by category (verifying π disappears when
  the Astronomy chip is active and AU appears).
- Unit converter switches dimensions and survives the dropdown
  rebuild.
- Export data dialog renders its Copy button.
- Locale switch from English to German actually updates the live UI.
- Statistics module opens to the Descriptive tab with all three
  tab labels.
- Analysis hub lists all four module cards.

7 tests, all green. Calculator-keypad gestures (type expression, tap
EXE, see history entry) deferred to integration_test since they
depend on the layout breakpoint.

Bonus fix found by the tests: the Unit converter's two side-by-side
dropdowns overflowed at narrow widths because the
`DropdownButtonFormField` wasn't `isExpanded: true`. Now constrained
correctly.

### Statistics V2

`lib/engine/statistics.dart` extended:

- `Statistics.polynomialFit(xs, ys, degree)` — least-squares solver
  for arbitrary polynomial degree. Builds normal equations
  `(XᵀX)c = Xᵀy` via power-sum accumulation, solves with Gaussian
  elimination + partial pivoting, returns coefficients in ascending
  order plus R². `PolynomialFit.evaluate(x)` reconstructs the curve.
- Linear case (degree 1) cross-checks against `linearFit`.
- Quadratic / cubic exact-coefficient recovery tests.
- Singular-system (all-x-equal) and underdetermined (< degree+1
  points) cases throw `ArgumentError`.

`lib/engine/distributions.dart` extended:

- `TDistribution(df)` — PDF in closed form via Lanczos log-gamma,
  CDF via Simpson on the PDF (1000 subintervals), quantile via
  bisection on the monotone CDF.
- `ChiSquare(df)` — same shape. Mean = df, variance = 2df,
  stddev = √(2df) exposed as getters.
- Lanczos approximation replaces the integer-only log-factorial used
  for binomial coefficient calculations, since t and χ² need
  half-integer Γ arguments. Binomial coverage retained.

Test verification against textbook critical values:

- t.quantile(0.975) at df=4 ≈ 2.776 (1d.p. textbook)
- t.quantile(0.95) at df=10 ≈ 1.812
- t.quantile(0.975) at df=1000 ≈ 1.96 (large-df → normal limit)
- chi².quantile(0.95) at df=3 ≈ 7.815
- chi².quantile(0.95) at df=10 ≈ 18.307
- chi² quantile / CDF inverse identity at p ∈ {0.1, 0.5, 0.9, 0.99}

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **553/553** (26 new tests: 7 UI flows + 6 polynomial
  fit + 6 t-distribution + 7 chi-square).
- macOS release matrix self-test 7/7, step self-test 28/28.

---

## 2026-05-17 (round 29) — Built-in constants library

Last of the "small concrete P5 gaps" cluster. Curated catalog of 30
physical, mathematical, chemistry, and astronomy constants reachable
from Settings → "Constants reference".

### Catalog

`lib/engine/constants_catalog.dart`:

- **Mathematical** (5): π, e, φ (golden ratio), γ (Euler-Mascheroni),
  Catalan's constant.
- **Physical** (14): c (speed of light), h, ℏ, G, g (standard
  gravity), k_B, e (elementary charge), ε₀, μ₀, m_e / m_p / m_n
  (electron / proton / neutron mass), σ (Stefan-Boltzmann), R_∞.
- **Chemistry** (5): N_A, R (gas constant), F (Faraday), V_m (molar
  volume), u (atomic mass unit).
- **Astronomy** (6): M_⊙, R_⊕, M_⊕, AU, pc, ly.

Values follow CODATA 2022 where applicable; the 7 constants made
exact by the 2019 SI redefinition (c, h, k_B, e, N_A, …) carry
their defined values.

Each entry has a `symbol`, `name`, `value`, `unit`, `category`, and
an optional one-line `note` explaining what it measures or how it's
derived (e.g. "F = N_A · e", "ℏ = h / (2π)").

### Dialog

`lib/widgets/constants_dialog.dart`:

- Category chip row + an "All" chip for browsing.
- Substring search across symbol / name / unit.
- Each row shows symbol (monospace, bold), name, value-with-unit
  (auto exponential notation when |x| ≥ 10⁶ or < 10⁻³), and the
  note in italic.
- Per-row copy-to-clipboard button — a toast confirms with the
  symbol so a user can chain copies confidently.

### Settings tile

Added between Unit converter and Help in the Settings list.

### i18n

12 new keys × 4 locales = 48 strings (titles, category labels,
search hint, no-matches placeholder, copy button + toast,
Settings tile label + subtitle).

### Tests

`test/constants_catalog_test.dart` covers:

- Coverage: ≥ 25 entries, ≥ 3 per category, every entry has a
  non-empty symbol and name.
- Well-known values: π, e (math), c (exact), elementary e (exact),
  N_A (exact), k_B (exact), h (exact), and the derived-constant
  relationships (R ≈ N_A · k_B, F ≈ N_A · e, ℏ ≈ h / (2π)).
- Search: empty query returns all, substring on name/symbol/unit
  works, case-insensitive, no-match returns empty.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **527/527** (23 new tests: 16 catalog math /
  search + 7 new locale-coverage checks).
- macOS release: matrix self-test 7/7, step self-test 28/28.

---

## 2026-05-17 (round 28) — Polish bundle: export, help, share, integration tests

A grab-bag of P4 production-readiness items shipped in one push, plus
the CI format-check fix that was blocking earlier rounds from going
green.

### CI format-check fix

CI runs Flutter 3.41.9; local dev is on 3.38.5. The newer `dart
format` has slightly different rules (function-argument wrapping,
trailing-comma triggers) so `--set-exit-if-changed` was failing
every push. Ran `dart format` and committed (no logic changes;
75-line diff across 19 files).

### Export data dialog

New Settings → "Export data" tile opens a dialog showing the full
`AppState` as pretty-printed JSON in a scrollable read-only text
area with a "Copy to clipboard" button. The schema mirrors the
shared_preferences keys, so a future import path can round-trip.
No new dependency — uses the built-in `Clipboard.setData`.

`AppState.exportToJson()` serializes everything: history, variables,
graph functions, parameters, locale, number format, theme. Stamped
with `version: 1` and `exportedAt` ISO-8601 UTC.

### History entry context menu

Long-press a history entry on the calculator screen now opens a
bottom sheet with three actions:

- **Copy result** — plain text of the last value.
- **Copy as LaTeX** — `<latex(expression)> = <result>` ready to
  paste into Word / Notion / Markdown.
- **Reuse expression** — pushes it back into the input field for
  quick re-editing.

Cross-platform without `share_plus` — clipboard is enough for V1.

### In-app Help screen

Settings → "Help & function reference" opens a new
`HelpScreen` listing every supported op grouped by category
(Arithmetic, Algebraic CAS, Calculus, Trig & elementary, Vector &
tensor, Matrix, Probability) with a one-line example each. Plus
the matrix syntax cheatsheet (`[1,2; 3,4]` form) and the three
step-by-step entry-point summary. Static content — no engine
reflection, just hand-curated.

### integration_test package wired up

`pubspec.yaml` now declares `integration_test` as a dev dep.
`integration_test/app_smoke_test.dart` ships two boot-and-find
tests using `IntegrationTestWidgetsFlutterBinding`. Locally:
`flutter test integration_test/app_smoke_test.dart`. CI runner
integration (real device/simulator) deferred — that's a per-platform
configuration story.

### Golden / structural anchor test

`test/golden/about_card_golden_test.dart` pumps the Help screen,
scrolls through its function-reference list, and asserts every
section heading and group title is present. Catches the regression
class of "section accidentally removed" or "card built empty"
without depending on pixel-perfect rendering (renderer-version
drift would make pixel goldens fragile across Flutter updates).

### i18n

19 new keys × 4 locales = 76 strings added (export dialog labels,
history-entry menu items, Settings tile labels, Help screen
section headings + bodies). Locale-coverage test grew by 1 group
(export / share / help strings) × 4 locales = 4 new checks.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **504/504** (5 new tests: 3 export/help locale
  coverage + 1 golden anchor + 1 export schema round-trip is
  validated implicitly by the JSON encoder running cleanly).
- macOS release: matrix self-test 7/7, step self-test 28/28.

---

## 2026-05-17 (round 27) — Friendly error messages

Before: a student typing `det(x)` got `Error: evaluate failed:
SymbolicMathException: evaluate - parse failed` in bold blue text
that looked exactly like a successful answer. After: a short italic
warning in the theme's error color saying "Couldn't understand the
expression. Check for unmatched parentheses, typos, or missing
operators."

### How

`lib/utils/error_formatter.dart` adds an `EngineErrorFormatter`
class with two entry points:

- `format(raw, t)` — if `raw` starts with `Error`, pattern-matches
  against known shapes and returns a localized friendly version.
  Falls through with a `⚠ ` prefix and the detail intact when
  nothing matches.
- `isError(text)` — boolean used by the history renderer to switch
  to the warning style.

Categories recognized today:

- **Parse failures** (`parse failed`, `ParseException`, `ParseError`).
- **Native library not loaded** (`requires native library`).
- **Integrate not implemented** (`not implemented in SymEngine C API`,
  `indefinite integrate() is not available`).
- **Invalid X() syntax** — extracts the function name and explains.
- **Matrix literal malformed** (`invalid matrix literal`).
- **Internal disposed matrix reference**.
- Argument-count messages (`gcd() requires exactly 2 arguments`) and
  format hints (`solve() format is …`) keep their useful text but
  lose the hostile `Error:` prefix.

### Visual change

The history renderer was always blue (`Colors.blue[300]`). Now:

- Normal results: `= <value>` in blue, 28pt (unchanged).
- Errors: friendly text in the theme's `colorScheme.error`, italic,
  16pt — visually clear that something went wrong.

The detection is via `EngineErrorFormatter.isError(entry.result)`
on the raw stored value, so we can change formatting later without
re-storing history.

### Localization

`errorParse`, `errorNativeRequired`,
`errorIntegrateNotImplemented`, `errorMatrixLiteral`,
`errorInternalMatrixDisposed`, `errorInvalidSyntax(op)` — 6 new
keys × 4 locales = 24 new strings.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **499/499** (19 new tests covering each error
  category, the non-error pass-through, and the unknown-error
  fallback).
- macOS release matrix self-test 7/7, step self-test 28/28.

### Out of scope for V1

The PLAN entry also mentioned underlining the offending fragment
and adding "did you mean" fix suggestions. That needs deeper
parser support (column numbers, token streams) which the bridge
doesn't expose. V2 work.

---

## 2026-05-17 (round 26) — Dialog localization sweep

A P4 polish item from PLAN. The FR/ES locales we added in round 17
were leaking English everywhere users opened a picker or step-by-
step dialog. Mechanical fix, large surface — touches every dialog
in `lib/widgets/function_picker_dialogs.dart` plus the three step
prompts in `lib/screens/calculator_screen.dart` plus the steps view
in `lib/widgets/steps_dialog.dart`.

### Strings added

21 new `AppLocalizations` keys, 84 locale entries (× 4):

- Shared dialog vocabulary: `dialogInsert`, `dialogClose`,
  `dialogShowSteps`, `dialogVariable`, `dialogExpression`,
  `dialogValue`, `dialogFunction`.
- Picker dialogs: `integralTitle`, `integralLowerBound`,
  `integralUpperBound`, `integralDefinite`, `nthRootTitle`,
  `nthRootBase`, `limitTitle`, `limitApproaches`,
  `substituteTitle`, `substituteUseStoredVariable`.
- Step-by-step prompts: `differentiationStepsTitle`,
  `differentiationStepsHeader(var)`, `solveStepsTitle`,
  `solveStepsEquationLabel`, `solveStepsSolveFor`,
  `solveStepsHint`, `solveStepsHeader(var)`,
  `integrationStepsTitle`, `integrationStepsIntegrandLabel`,
  `integrationStepsWrt`, `integrationStepsHint`,
  `integrationStepsHeader(var)`.

`localizations_test.dart` gained two new groups (dialog action
strings, picker/step dialog titles) — 32 new checks total (8 per
locale × 4 locales).

### Reused existing keys

- `continueTyping` and `dismissPanel` were already in `AppLocalizations`
  but never plumbed into the bottom-sheet pickers. Now they are.
- `solveFor(n)` and `whereY(n, func)` already existed too —
  similarly wired in.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **480/480** (8 new locale-coverage tests, no other
  test churn).
- macOS release matrix self-test 7/7, step self-test 28/28.

### Out of scope

The Statistics screen's labels (tab names, field labels) are still
hardcoded English. Same convention as the other analysis screens
(curve sketching, planes, conics) — that whole cluster deserves a
separate localization pass.

---

## 2026-05-17 (round 25) — Statistics + probability (P5 #3, V1)

Last of the P5 top-4 cluster. Pure-Dart statistics + distributions
math, plus a three-tab Statistics screen in the Analysis hub.

### Math layer

`lib/engine/statistics.dart`:

- `DescriptiveStats` (count, sum, mean, median, mode, sample +
  population variance/stddev, min, max, range, Q1/Q3, IQR). Quartiles
  use R-type-7 / Excel linear interpolation.
- `Statistics.linearFit(xs, ys)` — least-squares linear regression
  returning slope, intercept, R², count. Handles the all-x's-equal
  case (returns NaN slope) and constant-y (R² = 1 by convention) so
  the UI doesn't have to special-case anything.

`lib/engine/distributions.dart`:

- `Normal(mean, stddev)` with `pdf(x)`, `cdf(x)` (via the Abramowitz
  & Stegun erf approximation, max error 1.5e-7), and `quantile(p)`
  (bisection on the monotone CDF, ~1e-10 precision in ≤100 iters).
- `Binomial(n, p)` with `pmf(k)`, `cdf(k)`, `mean`, `variance`,
  `stddev`. PMF uses log-domain so it stays finite at large n.

### Screen

`lib/screens/statistics_screen.dart` is a three-tab workspace:

- **Descriptive** — paste comma/space/newline-separated numbers,
  see all 15 statistics in a card.
- **Regression** — two text fields (x's and y's), see the best-fit
  line equation plus slope/intercept/R²/n.
- **Distributions** — Normal section (μ, σ, x for CDF, p for
  quantile), Binomial section (n, p, k) — both with derived moments.

Wired into the Analysis hub as a fourth `_ModuleCard` next to curve
sketching / planes / conics.

### i18n

`moduleStatistics` + `moduleStatisticsSubtitle` strings added for
all four locales (en/de/fr/es). Screen labels themselves are
hardcoded English for V1 — same convention as the other analysis
screens; a localization pass for those would be a separate round.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **472/472** (50 new tests: 23 statistics covering
  textbook values for mean/median/mode/variance/quartiles plus
  regression including the perfect-fit, constant-y, and all-x-equal
  edge cases; 27 distributions covering normal CDF z-tables at
  0/±1/±1.96/±2.58, quantile/CDF inversion, binomial sum-to-1, p=0
  and p=1 corners, large-n log-domain stability).
- macOS release: matrix self-test 7/7, step self-test 28/28.

### P5 top-4 cluster — fully complete

- ✓ Step-by-step solutions for diff / integrate / solve (rounds 20–22)
- ✓ Interactive parameter sliders (round 23)
- ✓ Unit converter (round 24)
- ✓ Statistics + probability (round 25)

---

## 2026-05-17 (round 24) — Unit converter (P5 #4, V1)

Fourth and final of the P5 top-4 cluster. Ships a Unit Converter
dialog reachable from Settings, with a catalog of ~40 common units
across six dimensions and unit-tested conversion math.

### Catalog

`lib/engine/unit_catalog.dart` enumerates units per dimension with
`(scale, offset)` pairs taking each unit to its canonical SI base.
The offset is only non-zero for temperature (°C, °F are affine, not
proportional, to Kelvin); everything else is `offset = 0`.

Dimensions covered:

- **Length** — m, km, cm, mm, μm, nm, mi, yd, ft, in, nmi, AU, ly
- **Time** — s, ms, μs, ns, min, h, d, wk, yr (365.25 d)
- **Mass** — kg, g, mg, t, lb, oz, st
- **Temperature** — K, °C, °F (with proper affine handling)
- **Velocity** — m/s, km/h, mph, ft/s, kn (knot), c (speed of light)
- **Angle** — rad, °, grad, turn, arcmin, arcsec

### Converter

`lib/engine/unit_converter.dart` does single-dimension conversion
through the base unit. Validates that source and target share the
same dimension, rejects NaN / infinity inputs cleanly, and a
companion `format()` helper renders the result with trailing-zero
stripping and scientific notation for extreme magnitudes.

### Dialog

`lib/widgets/unit_converter_dialog.dart` shows a chip row for
dimensions, paired from/to dropdowns with a swap button, and a live
result block. Settings → "Unit converter" launches it. Pure Dart,
no engine integration needed at this stage — the dialog is a
self-contained tool.

### What V1 deliberately omits

- **Inline syntax** in the calculator (`5 km + 3 m`, `9.81 m/s^2 * 2 s`).
  Inline is tricky because unit symbols overlap with variable names
  (`k`, `g`, `t`, `h`, etc.). V2 needs a disambiguating syntax —
  maybe an explicit `[unit]` wrapper or a context-aware parser.
- **Composite-dimension arithmetic** (force = mass × acceleration,
  energy = force × distance). V2.
- **SI prefix parsing** (`5 km` understood as `5 × 10³ m`). Doable
  by detecting a known prefix on an unknown-but-known-base-suffix
  symbol; deferred to V2 alongside inline.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **422/422** (50 new tests covering catalog coverage,
  every dimension's basic conversions, temperature offset correctness
  including the -40 °C = -40 °F coincidence, round-trips, error
  handling, and formatting).
- macOS release: matrix self-test 7/7, step self-test 28/28.

This completes the P5 top-4 cluster I recommended:
**step-by-step solutions ✓, parameter sliders ✓, unit converter ✓**,
and **statistics + probability module** as the only remaining piece.

---

## 2026-05-17 (round 23) — Parameter sliders + thorough test sweep

Two threads in one round: shipping P5 #2 (parameter sliders on the
graphing screen) and a wide testing pass on every step engine that
surfaced — and fixed — a real bug.

### Parameter sliders

`ExpressionPreprocessingUtils.detectParameters(expr, plotVar)` walks
an expression and returns identifiers that aren't the plot variable
or a reserved name/function. `AppState` carries per-slot parameter
values (`functionParameters: Map<int, Map<String, double>>`),
persisted via shared_preferences as JSON. The graphing screen renders
a compact `_ParameterSlider` (range [-10, 10]) under each function
chip that has any parameter. `GraphPainter._withParameters`
substitutes values pre-evaluation via the new
`ExpressionPreprocessingUtils.substituteParameters` utility, so
`a*sin(b*x + c)` plots correctly and the curve animates as the user
drags sliders.

### Bug found by the thorough test sweep

The user asked for thorough unit + math tests on the step engine
work. Added two new test files (`step_engine_thorough_test.dart`
with 58 rule-selection / edge-case checks, `parameter_detection_test.dart`
with 27 checks for the new utility) and a new headless end-to-end
diagnostic: `CRISPCALC_DIAGNOSTIC=steps` runs ~28 examples of diff /
integrate / solve against the live bridge and verifies the final
result.

The first run revealed: **every integration check failed**. Root
cause: the SymEngine C bridge doesn't actually implement
`integrate()` — it returns "not implemented in SymEngine C API".
Round 22's step engine relied on `engine.integrate()` for the final
"Result" step, so every elaborated trace ended in an error string.

Fix: refactor `_traceIntegrate` to return the Dart-computed
antiderivative string from each rule, composing through sum/
constant-multiple recursion. The Result step now carries our own
answer, not SymEngine's — and the rules cover power, log, sum,
constant-multiple, and the standard antiderivatives, which is enough
for the full V1 set.

### Diagnostic normalizer

`StepDiagnostics._normalize` strips parens, whitespace, `|` (so
`ln|x|` matches `ln(x)`), and collapses Python-style `**` to `^` and
the readability middle-dot `·` to `*`. Matches a list of
`|`-separated alternates so we can encode "either `2*x` or `x*2`"
without overfitting SymEngine's canonical output shape.

### CI hookup

`build-macos.yml` gains a second self-test step: after the matrix
diagnostic, the workflow runs `CRISPCALC_DIAGNOSTIC=steps`. The
binary exits non-zero on any failure, so step-engine regressions
land in CI.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: **372/372** (85 new tests for parameter detection,
  parameter substitution, and thorough step engine rule selection).
- macOS release: matrix self-test **7/7**, step self-test **28/28**.

---

## 2026-05-17 (round 22) — Step-by-step integration (P5 #1, V3)

Third slice of the step-by-step workstream. Modeled on SymPy's
`manualintegrate` (the only public reference for "integration steps
on top of a CAS that already has its own integrator"). To our
knowledge, nobody has written one of these on top of SymEngine before
— SymEngine is mostly used as a backend for SymPy, so the audience
that wanted step traces inherited them from SymPy directly.

### Rule walker

`StepEngine.integrate(expr, variable, engine)` tries a fixed rule list
in order. Each rule either emits a `MathStep` and recurses on a
simpler sub-integrand, or declines and lets the next rule try. The
final "Result" step always carries SymEngine's canonical antiderivative
(with `+ C`), so even when the walker can't elaborate, the user still
gets the right answer.

Rules covered in V1:

- Constant rule: ∫c dx = c·x when the integrand doesn't depend on var.
- Power rule (n=1): ∫x dx = x²/2.
- Power rule (general): ∫x^n dx = x^(n+1)/(n+1) for constant n ≠ -1.
- Logarithm rule: ∫1/x dx = ln|x| (catches both `1/x` and `x^-1`).
- Sum/difference (linearity): ∫(f ± g) dx = ∫f dx ± ∫g dx; recurses on
  each term.
- Constant multiple: ∫c·f(x) dx = c·∫f(x) dx; splits factors into
  constant and variable parts, pulls the constant out front, recurses
  on the remainder.
- Standard antiderivatives for sin/cos/exp/sinh/cosh when the argument
  is exactly the variable.
- Fall-through: emits a "Symbolic integration" step that hands off to
  SymEngine, with a note explaining that substitution and by-parts
  aren't yet recognized.

### Deferred (V2)

- **Substitution**: needs a fixed candidate list (composite argument,
  derivative-spotting). Most failures are pedagogical, not correctness
  — if SymEngine still has the right answer the worst case is "no
  steps shown."
- **Integration by parts**: needs LIATE ordering and a recursion
  budget to avoid infinite descent.
- **Partial fractions** and **trig substitution**: niche, defer.

### UI entry

New `∫⌄` button in the CAS keypad tab, right next to `∫`. Opens a
small integrand+variable prompt (defaults to `x^2`), runs the trace,
opens the StepsDialog with the headline rendered as a proper LaTeX
integral (`\int … \, d x`). Existing `∫` flow untouched.

### Walk-through for `3·x^2`

1. Constant multiple — `3 · ∫ x^2 dx`
2. Power rule — `(x)^3 / 3`
3. Result — `x^3 + C` (from SymEngine)

### Why this is unusual

The chat upstream noted that nobody appears to have done this on top
of SymEngine before — SymEngine is primarily a SymPy backend and its
direct users are library authors with no audience for pedagogical
tooling. The combination of (a) a student-facing app, (b) the mobile
on-device constraint that requires C++ speed, and (c) the willingness
to write a parallel rule walker is rare enough that the path is
empty. Documented in PLAN P5 #1.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: 287/287 (10 new integration tests covering rule
  selection, the always-ends-with-Result invariant, and the fall-
  through path for unrecognized shapes).
- macOS release boots clean. Matrix self-test still 7/7.

---

## 2026-05-17 (round 21) — Step-by-step equation solving (P5 #1, V2)

Second slice of the step-by-step workstream from round 20: equation
solving. Same `StepEngine` + `StepsDialog` infrastructure reused.

### Degree detection

`StepEngine.solve(input, variable, engine)` first splits on top-level
`=` (or treats the input as `expr = 0`), then asks SymEngine to
differentiate the simplified equation. If `d/dvar[body]` is a non-zero
expression that no longer contains `variable`, the equation is linear.
If `d²/dvar²[body]` is a non-zero variable-free expression, it's
quadratic. Anything else falls through to `engine.solve()` with a
single "Symbolic solve" step explaining the handoff.

### Linear trace

For `2x + 3 = 7`:

1. Original equation — `2x + 3 = 7`
2. Move all terms to one side — `2*x - 4 = 0`
3. Identify coefficients — `a = 2, b = -4`
4. Subtract the constant — `2*x = 4`
5. Divide by the coefficient — `x = 2`
6. Result — `x = 2`

### Quadratic trace

For `x^2 - 5x + 6 = 0` (or `x^2 - 5x + 6` treated as `… = 0`):

1. Treat as equation = 0 / Move all terms to one side
2. Identify coefficients — `a, b, c` derived from `d²`, `d|_{x=0}`,
   `body|_{x=0}`
3. Compute the discriminant — `Δ = b² - 4ac`
4. Apply the quadratic formula — `x = (-b ± √Δ) / (2a)`
5. Result — both roots, cross-checked against SymEngine's `solve()`

### MathStep rename

Renamed the `DerivativeStep` data class to `MathStep` since it now
carries solve steps as well. Pure renaming — same fields (`rule`,
`formula`, `before`, `after`, `note`).

### Dialog flexibility

`StepsDialog` gained optional `subtitle` and `headlineLatex` overrides
so it can render either "Differentiating with respect to x" + the
`d/dx[…]` headline or "Solving for x" + the equation itself. Old
behavior preserved as the default.

### UI entry

New `solve⌄` keypad button in the CAS tab, between `solve` and
`factor`. Opens a small prompt (defaults to `2x + 3 = 7`), runs the
trace, opens the steps dialog. Existing `solve` button is untouched —
users who just want the answer keep getting it as before.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: 277/277 (5 new solve tests).
- macOS release boots clean. Matrix self-test still 7/7.

---

## 2026-05-17 (round 20) — Step-by-step differentiation (P5 #1, V1)

First slice of PLAN P5's top recommendation: when the user
differentiates an expression, show *why* the answer is what it is.

### Architecture

`lib/engine/step_engine.dart` is a rule-tracing walker. For each input
it identifies the top-level expression shape and emits a
`DerivativeStep` carrying the rule name, the generic LaTeX formula,
and the rule-unfolded result. Then it recurses on sub-expressions so
the trace fans out into a complete derivation. The final step's
`after` field comes from SymEngine — so the canonical answer never
drifts even though the trace is computed in Dart.

Rules covered:

- Constant rule, identity (`d/dx[x] = 1`)
- Sum / difference rule (paren-aware top-level split on `+` / `-`)
- Product rule (recurses as `first · rest`, fans out further)
- Quotient rule
- Power rule (numeric exponent in the variable) and exponential rule
  (`a^u(x)`)
- Chain-rule-aware standard derivatives for sin / cos / tan / asin /
  acos / atan / sinh / cosh / tanh / exp / ln / log / sqrt
- Generic fall-through that just emits SymEngine's answer when no
  pattern matches

Each step structure carries an optional `note` for plain-language
explanations — wired today for constant and chain-rule cases, easy to
extend.

### UI

`lib/widgets/steps_dialog.dart` renders the step list as a card stack
with `flutter_math_fork` LaTeX rendering for the formula + before/after
expressions. Result step is highlighted with the primary container
color. Falls back to monospace text on LaTeX parse failures so the
dialog never goes blank on a malformed step.

Entry point: new `d/dx⌄` keypad button in the CAS tab. Pressed → small
dialog asks for expression + variable (pre-filled from the LaTeX field
if there's anything in it) → step list dialog opens. Doesn't touch the
existing `d/dx` flow, so users who just want the answer keep getting
it the old way.

### Why not also integrate + solve

Differentiation rules are finite and well-known; the trace generator
fits in 250 lines of Dart with no SymEngine modifications. Integration
and equation solving need either fork SymEngine to emit traces or
implement enough of the algorithms Dart-side to recognize patterns —
significantly larger. Documented in PLAN as the next two slices.

### Verification

- `flutter analyze`: 0 issues.
- `flutter test`: 272/272 (13 new step engine tests covering rule
  selection, step content, and the "always ends with a Result step"
  invariant).
- Local release smoke: app boots clean. `CRISPCALC_DIAGNOSTIC=matrix`
  still 7/7.

---

## 2026-05-17 (round 19) — RREF via SymEngine-backed Gauss-Jordan

Added `rref(Matrix([...]))` to the matrix evaluator. The algorithm is
classical Gauss-Jordan, but every elementary row operation is built
as a SymEngine expression string and pushed through
`bridge.simplify()` — so rational and (with caveats) symbolic entries
work, not just floats.

### Algorithm shape

1. Pull cells into a Dart 2-D array of expression strings.
2. Walk columns left-to-right. For each column, find the first row at
   or below the current pivot row whose entry simplifies to something
   non-zero.
3. Swap that row up. Scale it so the leading entry is 1
   (`(cell)/(pivot)` through SymEngine).
4. Use the pivot row to eliminate that column in every other row
   (`(target) - (factor)*(pivot_row_cell)` through SymEngine).
5. Move to the next column.

Symbolic non-zero detection asks SymEngine to simplify each candidate
and treats the literal string "0" as zero. Expressions that are
mathematically zero but don't reduce to "0" textually are treated as
non-zero pivots — the result is still a valid row-reduced form, just
possibly not fully canonical. That's the safe direction.

### Wired in

- `MatrixEvaluator` recognizes `rref` alongside `det` / `inv` /
  `transpose`.
- Keypad gets a new `rref` button next to the existing matrix keys.
- The matrix self-test battery picks up a 7th check — the canonical
  textbook 2×3 system `[[2,1,0],[-1,1,3]]` which reduces to
  `[[1,0,-1],[0,1,2]]`. Self-test now reports **7 of 7 pass** on the
  macOS release binary; CI runs the same battery on every push and
  fails on regression.

### Verification

`flutter analyze`: 0 issues. `flutter test`: 259/259 (updated the
diagnostic-runner shape test to expect 7 results). Release smoke:
`CRISPCALC_DIAGNOSTIC=matrix … crisp_calc` reports the new check as
`PASS  RREF of a 2x3 system — Matrix([[1, 0, -1], [0, 1, 2]])`.

### Out of scope

- Bringing matrix expressions into `inv` / `transpose` / `rref` as
  *nested* operands (currently the operand must be a literal `Matrix(…)`).
- Symbolic non-zero detection beyond "simplify and compare to '0'"
  — would need SymEngine's `is_zero` test, which the bridge doesn't
  expose yet.

---

## 2026-05-17 (round 18) — CI catches matrix + symbol-keep regressions

Two tightenings to `build-macos.yml`:

1. **Switched the workflow from `--debug` to `--release`.** The
   symbol-keep trick that HISTORY round 13 fixed lives in the bridge
   plugin, not in CrispCalc. It can silently regress on a bridge bump.
   Running the release link in CI directly exercises the same path
   that release builds use locally, so a regression in the asm-clobber
   keepalive can't slip through unnoticed.

2. **Added a headless matrix-diagnostic step.** After the `nm`
   symbol-presence check, CI now runs
   `CRISPCALC_DIAGNOSTIC=matrix <app>`, which exits non-zero on any
   matrix self-test failure. The presence check verifies symbols are
   statically linked; the diagnostic verifies they actually round-trip
   through the FFI matrix bindings. Together they catch both
   regression classes that bit us in rounds 13 and 16.

PLAN.md's open "GitHub Actions to run analyze + test on PR" item was
also redundant — `ci.yml` has provided that since round 8. Marked done.

---

## 2026-05-17 (round 17) — French + Spanish locales

Added `FrLocalizations` and `EsLocalizations` to
`lib/localization/app_localizations.dart` (full mirror of the German
override block — nav, history, graphing, analysis hub, settings, about,
matrix diagnostics, picker dialogs, error strings, and tab labels;
~95 strings each).

- Extended the abstract `AppLocalizations` class with two new
  language-name getters (`settingsLanguageFrench`,
  `settingsLanguageSpanish`) — enforces compile-time coverage on each
  locale class.
- `AppLocalizationsDelegate.isSupported` and `load` extended to handle
  `'fr'` and `'es'`. Unknown language codes still fall through to
  English.
- `main.dart`: added `Locale('fr','')` and `Locale('es','')` to
  `supportedLocales`, and two new `RadioListTile`s in the language
  card.

### Safety net

New `test/localizations_test.dart` walks every locale and asserts
every string getter + templated method returns non-empty content. A
new string on the abstract class catches at compile-time (Dart's
missing-override error); this test catches accidentally-empty
translations and broken templated formatters that wouldn't compile-
fail. 20 checks pass across the 4 locales.

### Verification

`flutter analyze`: 0 issues. `flutter test`: 259/259 (20 new locale
checks). macOS release builds and boots clean.

---

## 2026-05-17 (round 16) — Matrix arithmetic actually works end-to-end

PLAN P2 "matrix arithmetic end-to-end" turned up a real bug that the
unit tests couldn't have caught — the preprocessor was emitting strings
SymEngine's text parser couldn't accept.

### The self-test that surfaced the bug

Added `lib/engine/matrix_diagnostics.dart` with a six-check battery
(2x2 det, 3x3 identity det, transpose, inverse of identity, addition,
multiplication). Exposed two entry points to run it:

- Settings → "Matrix self-test" tile opens a dialog with PASS/FAIL per
  check and the raw expected vs. actual strings.
- `CRISPCALC_DIAGNOSTIC=matrix <app>` runs the battery headlessly and
  exits non-zero on any failure. (Reaches `Platform.environment` from
  `main()` — `Platform.executableArguments` is Dart-VM args, not user
  argv, so the obvious `--matrix-diagnostic` flag wouldn't have worked
  from a launched binary.)

First run on a fresh release build: **0 of 6 checks passed**. Every
matrix expression came back `SymbolicMathException: evaluate -
parse failed`. The preprocessor builds `Matrix([[1,2],[3,4]])` strings,
but SymEngine's `parse()` doesn't have a `Matrix` constructor in its
grammar.

### The fix: route matrix ops through the FFI matrix bindings

New `lib/engine/matrix_evaluator.dart`. `CalculatorEngine.evaluate()`
now checks for `Matrix(` in the expression and, if found, hands off to
`MatrixEvaluator.tryEvaluate()` instead of the string-evaluate path.
The evaluator:

- Recognizes three top-level shapes: `det/inv/transpose(<matrix>)`,
  `<matrix> {+,-,*} <matrix>`, and a bare `<matrix>` literal.
- Parses `Matrix([[a,b],[c,d]])` into a fresh `SymEngineMatrix` via the
  `createMatrix` + `set` FFI calls.
- Routes operations to the matrix API (`getDeterminant`, `inverse`,
  `operator+`, `operator*`).
- Implements `transpose` and `-` in Dart (no native entry points) by
  copying cells into a new matrix.
- Formats the result as canonical `Matrix([[a, b], [c, d]])` instead
  of the bridge's native multi-line `[a, b]\n[c, d]` shape, so results
  feed back into the engine cleanly and look right in history.

### A bonus user-visible improvement

`_bridgeCall` was hiding the underlying bridge exception under a
generic "Error: <op> failed". Now it appends the exception's message:
"Error: evaluate failed: SymbolicMathException: evaluate - parse
failed". That's how the parse-failure diagnosis was possible in the
first place. Future debugging gets cheaper.

### Verification

`CRISPCALC_DIAGNOSTIC=matrix build/macos/Build/Products/Release/crisp_calc.app/Contents/MacOS/crisp_calc`:

```
PASS  2x2 determinant — actual: -2
PASS  3x3 identity determinant — actual: 1
PASS  Transpose 2x2 — actual: Matrix([[1, 3], [2, 4]])
PASS  Inverse of identity — actual: Matrix([[1, 0], [0, 1]])
PASS  Matrix addition — actual: Matrix([[2, 2], [3, 5]])
PASS  Matrix multiplication — actual: Matrix([[3, 4], [5, 6]])
6 of 6 checks passed
```

`flutter analyze`: 0 issues. `flutter test`: 239/239 (3 new
diagnostics tests for the runner shape).

### Out of scope

Mixed scalar-matrix expressions (e.g. `det(M) + 3`), chained matrix
expressions (`A * B + C`), scalar-times-matrix, matrix substitution
with stored variables. Today's evaluator handles literal-only operands
at top level. Wider parsing is a future iteration.

---

## 2026-05-17 (round 15) — Plot annotations + zero-issue analyze

### Plot annotations

New AppBar toggle on the graphing screen overlays roots and extrema
markers on every active curve. Numerical implementation:

- Scan ~200 samples across the visible x-range using the painter's
  existing per-point evaluator (`_evaluateFunction`).
- **Roots**: sign change in f(x), refined by 40-iter bisection.
- **Extrema**: sign change in finite-difference f'(x), refined by
  parabolic interpolation through three samples bracketing the change.
  Classification (`min` / `max`) from the parabola's curvature sign.
- Markers: filled colored dot + white outline, with a labeled coord
  pair above-right (flipped if it would clip the canvas).

Why fully numerical rather than reusing AnalysisEngine: AnalysisEngine
does symbolic root/extremum solving via SymEngine, which is slow and
overkill for an interactive overlay that needs to repaint on every pan
and zoom. The numerical scan is fast enough to rerun each frame and
adapts to whatever x-range is on screen, so it shows roots/extrema
outside the analytic solution set too (e.g., for transcendental
functions where SymEngine can't find closed-form roots).

### Zero-issue analyze

In the same round, drove `flutter analyze` from 31 issues down to **0**:

- Dropped 6 redundant `flutter/foundation.dart` and `flutter/services.dart`
  imports that were fully shadowed by `flutter/material.dart`.
- Migrated 18 deprecated `Radio.groupValue` / `Radio.onChanged` usages
  in `main.dart` to the new `RadioGroup<T>` ancestor pattern
  (Flutter 3.32+). Cleaner shape too — one set of group state at the
  Card level instead of repeated on every `RadioListTile`.
- Added `super.key` to `IntegralDialog`, `NthRootDialog`, `LimitDialog`
  constructors; tightened a stale `Key? key` in `progress_overlay.dart`.
- Three `const` constructor lints (Text, KeyUpEvent, GraphingScreen
  push).

`flutter test`: 236/236. macOS release builds clean and launches with
all bridge symbols linked.

---

## 2026-05-17 (round 14) — P2: substitute dialog + history search

Two user-facing improvements with the bridge fix from round 13
unblocked.

### Variable substitution dialog

The `subst` keypad button used to just stuff `subst(, , )` into the
input and let the user fill the holes — fiddly and easy to break. New
`SubstituteDialog` (in `lib/widgets/function_picker_dialogs.dart`)
mirrors the existing `LimitDialog` pattern: three LaTeX fields
(Expression, Variable, Value) and an "Insert" button that builds
`subst(expr, var, value)` and drops it in.

Nice bit: when `appState.userVariables` is non-empty, the dialog shows
a row of `ActionChip`s for each stored variable. Tapping one fills the
Value field — same gesture as picking from memory, no typing.

### History search

Added a search icon to the calculator history toolbar (next to the
LaTeX/plain toggle + clear). Toggle reveals a TextField that filters
the rendered history live — case-insensitive `contains` against both
expression and result. Empty filter shows the usual list; non-matching
filter shows a "no matching entries" placeholder. Search state is per-
session (intentionally not persisted — feels weird to come back to the
app with a stale filter).

### i18n

Added en/de strings for `searchHistory`, `searchHistoryHint`,
`historyNoMatches`. The new dialog itself is still hardcoded English to
match the rest of `function_picker_dialogs.dart`; that whole file
should get a localization pass in a follow-up.

### Verification

- `flutter analyze`: 31 issues — same count as before, no new
  warnings/errors.
- `flutter test`: 236 tests pass.
- macOS release build: 69.2 MB, boots cleanly with the linked-symbols
  log from round 13.

---

## 2026-05-17 (round 13) — P1#2 finally closed (macOS release link)

The macOS release build kept dropping every `flutter_symengine_*`
wrapper symbol despite five rounds of -ldflags / podspec / xcframework
gymnastics. Root cause turned out to live in the bridge plugin, not in
the host Runner: iOS already had a `SymEngineBridge.m` with a `+load`
method that took the address of every wrapper function, plus a
`@_silgen_name("force_all_math_symbols_linking")` declaration in Swift
to pull the .m's translation unit into the link. macOS had neither.

### Iteration 1 — port iOS verbatim

Created `macos/Classes/SymEngineBridge.m` mirroring iOS, added the
`@_silgen_name` + `force_all_math_symbols_linking()` call to the macOS
Swift plugin. Build succeeded but `nm` showed zero `flutter_symengine_*`
symbols in the release binary. `otool -tV` on `+[SymEngineBridge load]`
revealed why: the entire `static void* refs[] = { … }` array plus the
`if (refs[0] == NULL) { … }` check had been constant-folded out by LTO
(the compiler proved `refs[0]` is a function address ⇒ never NULL ⇒
the if-branch is unreachable ⇒ the array reads are dead ⇒ the array
itself is dead). What remained was a single `NSLog` and a `ret`.

### Iteration 2 — volatile sink

Replaced the if-check with a loop writing each pointer into a `static
volatile void* sink`. Build still dropped every symbol. Disassembly
showed only the *last* store survived: writes to the same volatile
location are still subject to dead-store elimination when the optimizer
proves only the final value is observed.

### Iteration 3 — asm-clobber DoNotOptimize

Switched to the standard `DoNotOptimize` pattern:

```c
for (size_t i = 0; i < n; i++) {
    __asm__ __volatile__("" : : "r"(refs[i]) : "memory");
}
```

The empty `asm volatile` with an `r` input constraint forces the
compiler to materialize each pointer in a register as if external code
consumes it — undeletable side effect. Release binary jumped from
53.7MB → 69.2MB, and 39 wrapper symbols landed.

### Iteration 4 — audit the missing six

Dart FFI bindings turned out to reference 45 distinct
`flutter_symengine_*` entry points; the iOS-ported refs[] only listed
39. Added the missing six: `simplify`, `integrate`, `version`,
`test_basic_operations`, `test_symbolic` (`free_string` was already
there). All 45 now in the release binary.

### Result

- `nm crisp_calc | grep -c flutter_symengine_` → **45**
- Runtime launch logs: `[SYMBOLIC_MATH] Linked 93 math symbols` followed
  by a clean Flutter startup — no `dlsym` failures.
- Bridge commits: `36c29bf` (port iOS), `26f1faa` (volatile attempt),
  `e9a8526` (asm-clobber), `6652199` (missing 6).
- CrispCalc pinned to bridge ref `6652199`.

### Lesson

When forcing the linker to keep symbols that are otherwise only reached
via `dlsym`, neither a constant if-check nor a single volatile sink
survives LTO. The bulletproof pattern is one asm-clobber per reference.
This is the same trick Google Benchmark uses for `DoNotOptimize`, and
it's the only thing that worked under Xcode 26.2 + Flutter 3.38.5 on
macOS Release.

---

## 2026-05-17 (round 12) — v0.1.0 cut

- Fast-forwarded main from `latex-input-field` (18 commits, ~9k
  insertions covering everything from the first audit forward).
- Tagged `v0.1.0` with a release-note commit message covering features
  and known limitations.
- The `release.yml` workflow fired automatically on the tag push and
  ran 6 jobs in parallel: macOS, iOS, Linux, Windows, Android, publish.
  All six green; publish step created the GitHub Release and attached
  every artifact.
- Release page: https://github.com/CrispStrobe/CrispCalc/releases/tag/v0.1.0
  - `crisp_calc-v0.1.0-macos.zip` (22.8 MiB, release build, unsigned)
  - `crisp_calc-v0.1.0-ios-unsigned.zip` (10.4 MiB)
  - `crisp_calc-v0.1.0-linux-x64.tar.gz` (19.7 MiB, degraded mode)
  - `crisp_calc-v0.1.0-windows-x64.zip` (13.6 MiB, degraded mode)
  - `crisp_calc-v0.1.0-android.apk` (54.4 MiB, degraded mode)
- Release-note body documents that symbolic operations work on
  iOS/macOS only at this version and macOS release builds have the
  known SymEngine wrapper-symbol drop (PLAN P1#2).

## 2026-05-17 (round 11) — P1#2 round 2 (still open, partial progress)

### What I learned
- Built a tiny universal static archive
  `libflutter_symengine_wrapper_only.a` (56 KB, just the 45 C entry
  points without any SymEngine internals) by `lipo -thin → ar -x → ar
  rcs → lipo -create`. Bundled into a real
  `FlutterSymEngineWrapperOnly.xcframework` with iOS and macOS slices
  and committed to the bridge repo so it ships alongside the big
  `SymEngineFlutterWrapper.xcframework`.
- Verified the small archive: `nm -arch arm64
  libflutter_symengine_wrapper_only.a` → 45 `T _flutter_symengine_*`.

### What didn't work
- Wiring the new archive into the bridge podspec
  (`vendored_frameworks` + `-Wl,-force_load,<path>`): CocoaPods adds
  `-lflutter_symengine_wrapper_only` automatically; that combined with
  the existing `-all_load -lsymengine_flutter_wrapper` ended up
  breaking even the debug link (0 symbols instead of 45). Removed the
  wiring; the archive is in the bridge repo for the next attempt.
- Inspecting `crisp_calc-linker-args.resp` shows the macOS Runner's
  actual `ld` invocation receives ONLY Swift `-add_ast_path` entries.
  The `-all_load`, `-l"symengine_flutter_wrapper"`, etc. from
  `Pods-Runner.*.xcconfig` never show up there. So the standard
  CocoaPods linker-flag plumbing doesn't reach the link step on this
  Xcode 26.2 / Flutter 3.38.5 combination. Debug builds work via
  Flutter's separate `crisp_calc.debug.dylib` link pipeline, which
  somehow does consume the flags.

### State after this round
- Bridge HEAD at `c3fd26a` — carries the wrapper-only archive without
  wiring (so debug builds stay green) and the comment trail of what
  was tried.
- CrispCalc's Podfile is back to the working `-all_load`-only state.
- Debug: 45 `flutter_symengine_*` symbols in
  `crisp_calc.debug.dylib`. App fully functional.
- Release: 0 symbols. Symbolic operations return "Error: requires
  native library". Open P1#2.

## 2026-05-17 (round 10) — Cross-platform builds + P1#2 deep-dive

### P1#2: release-build SymEngine investigation (still open)
- Forensic finding: the static archive holds **two** kinds of symbols.
  ~3000 mangled C++ `__ZN9SymEngine…` and 45 C wrapper
  `flutter_symengine_*`. Release builds link the C++ side fine — the
  C wrapper `flutter_symengine_wrapper.o` is silently dropped.
- Tried, in order:
  1. `STRIP_INSTALLED_PRODUCT = NO` + `DEAD_CODE_STRIPPING = NO` on
     the Runner xcconfig → symbols still missing.
  2. `-Wl,-force_load,<xcframework-slice>` → missing alone, duplicates
     when combined with `-all_load`.
  3. Patching `LIBRARY_SEARCH_PATHS` on the bridge POD so the framework
     pre-links → duplicate symbols (framework + Runner both pull the
     same archive, both with -all_load).
- Reverted to the known-debug-working state (`-all_load` only, no
  patches). 45 symbols in `crisp_calc.debug.dylib` confirmed; release
  has 0 symbols. The real fix lives upstream in the bridge plugin: the
  C wrapper needs to be in a separate static lib, or the framework
  binary needs to pre-link the wrapper objects explicitly. Updated
  PLAN with the full failure timeline.

### Cross-platform builds: Android / Linux / Windows
- `flutter create --platforms=android,linux,windows --org=be.crispstro .`
  added the three platforms (~50 new files: Gradle, CMake, Win32 runner,
  manifests, mipmap dirs).
- Android launcher icons sized for every mipmap density (48/72/96/144/192).
- `CalculatorEngine` already handles a missing bridge gracefully —
  `DynamicLibrary.open('libSymEngineFlutterWrapper.so')` throws on
  platforms without the lib, the constructor catches and stays in
  `_nativeAvailable = false` mode. The UI, persistence, plane/conic
  analysis, vector/tensor math, plot rendering all still work.
  Symbolic operations (`solve`, `factor`, etc.) return clear "requires
  native library" error strings.
- Three new CI workflows:
  - `build-android.yml` — Ubuntu + Temurin 17 + Android SDK → debug APK.
  - `build-linux.yml` — Ubuntu + GTK 3 + Ninja → release bundle (tar.gz).
  - `build-windows.yml` — Windows-latest → release zip.
- `release.yml` extended to build all 5 platforms (macOS, iOS, Linux,
  Windows, Android) on `v*` tags. Release body explains which builds
  have full symbolic support vs degraded mode.
- macOS/iOS still 236 tests passing. analyze clean.

## 2026-05-17 (round 9) — Repo public

- `gh repo edit CrispStrobe/CrispCalc --visibility public` — flipped
  after the green CI confirmation. The bridge plugin was already
  public.
- Added a description and topics: calculator, cas, dart, ffi, flutter,
  ios, macos, symbolic-computation, symengine.
- GitHub Actions minutes are now unlimited on the runner. The build
  matrix (CI + Build macOS + Build iOS, ~7 min total per push) will
  comfortably fit even with frequent pushes.

## 2026-05-17 (round 8) — About screen, LICENSE, GH Actions CI

### LICENSE + AGPL choice
- Added `LICENSE` at repo root: GNU Affero General Public License v3
  (fetched verbatim from gnu.org).
- The bundled GMP/MPFR/MPC/FLINT libraries are LGPL; statically linking
  them into a Flutter app effectively requires a strong-copyleft outer
  license. AGPL-3 fits and matches the sibling CrisperWeaver app.

### About / Über CrispCalc screen
- New `lib/screens/about_screen.dart`, modeled on CrisperWeaver's: app
  header (icon + name + version from `package_info_plus`), then cards
  for service provider, contact (tappable email), privacy, disclaimer,
  license link. Bottom button opens Flutter's `showLicensePage` which
  lists every pub dep.
- Added `lib/services/native_licenses.dart` + asset
  `assets/licenses/SYMENGINE_STACK.txt` with text/links for SymEngine,
  GMP, MPFR, MPC, FLINT. `main.dart` calls `registerNativeLicenses()`
  before `runApp` so they appear in the license page alongside pub deps.
- Settings screen got a new "About CrispCalc" / "Über CrispCalc" tile
  that pushes the new screen. Strings localized (en + de).
- Added `package_info_plus: ^8.0.0` and `url_launcher: ^6.2.0` deps.

### Bridge plugin pushed to public repo
- Committed and pushed the macOS support pieces I'd been keeping local:
  the Swift plugin class rename, the xcframework symlinks under `macos/`,
  the podspec update, and the optional FFI binding for native
  `integrate`. Commit `6c9f232` on `CrispStrobe/symbolic_math_bridge` main.
- Switched CrispCalc's `pubspec.yaml` to a `git:` dependency pinned to
  that SHA so CI runners (which don't have a sibling `../symbolic_math_bridge`
  directory) build the same source as local dev.

### GitHub Actions workflows
- `.github/workflows/ci.yml` — runs on every push/PR. Ubuntu runner.
  `flutter pub get`, `dart format --set-exit-if-changed`,
  `flutter analyze --no-fatal-infos`, `flutter test`. Linux runners cost
  1× compared to macOS's 10× — cheapest gate possible.
- `.github/workflows/build-macos.yml` — macOS-14 runner. Builds the
  debug `.app` and asserts at least 30 `flutter_symengine_*` symbols
  landed in the binary (catches the link regression I hit in this
  round). Uploads a zipped `.app` as a 14-day artifact.
- `.github/workflows/build-ios.yml` — same shape but `flutter build ios
  --release --no-codesign`. Unsigned IPA so reviewers can verify the
  build path without needing Apple Developer credentials.
- `.github/workflows/release.yml` — triggered by `v*` tags. Builds
  release artifacts for macOS and iOS, attaches them to a GitHub
  Release with auto-generated notes. macOS symbol-count check is a
  warning (not a hard fail) because release link is the open P1.

### Housekeeping
- Ran `dart format` on the full tree (52 files; 40 changed). CI's
  format gate would have rejected them otherwise.

### Status
- `flutter analyze`: 31 info hints, no errors / warnings.
- `flutter test`: **236 passing.**
- macOS debug build still works; SymEngine symbols linked.
- Ready to go public after these changes land.

## 2026-05-17 (round 7) — Native integrate (PLAN P1#1)

### Discovery
- The SymEngine static archive *already* exports `flutter_symengine_integrate`
  (single `nm` of the macOS slice confirms it). The header file warned
  "Not implemented in SymEngine's C API" but the symbol is there. The
  bridge plugin just never bound it.

### Bridge binding
- Added a `_SolveDart? _integrate` field on `SymbolicMathBridge` and an
  optional lookup. When the wrapper exposes the symbol, the field is
  populated; when it doesn't (older builds), it stays null. Exposed a
  public `bool get hasIntegrate` so callers can switch paths cleanly.
- New `String integrate(String expression, String symbol)` method that
  marshals the call through FFI exactly like `differentiate`.

### CalculatorEngine integration
- `integrate(expression, variable)` (no bounds) now returns the symbolic
  antiderivative from the native wrapper, e.g. `integrate(x^2, x)` →
  `x^3/3`.
- `integrate(expression, variable, lower, upper)` (definite) tries the
  fundamental-theorem-of-calculus route first: ask for an antiderivative
  `F`, substitute the bounds, return `F(b) - F(a)` (a clean exact value
  like `1/3` for `∫₀¹ x² dx`). If anything fails — wrapper rejects the
  integrand, antiderivative isn't elementary, etc. — falls back to
  Simpson's rule with 200 subintervals.
- Both paths defer to the existing "requires native library" error when
  the bridge isn't loaded (so unit tests stay deterministic).

### Tests
- Updated `test/limit_integrate_test.dart` to cover the new definite path.
- Full suite: **236 passing.** `flutter analyze` clean.

### Status of `limit`
- The native archive does *not* export a `limit` entry point. Adding one
  would require rebuilding the C++ wrapper from source (lives in a
  separate repo). Filed in PLAN as the remaining symbolic-CAS gap;
  numerical one-sided / infinity limits remain as the best-effort answer.

## 2026-05-17 (round 6) — 2-pane keypad, release build investigation

### Wide-screen keypad: 2 panes, independently switchable
- Previous 4-up layout (whether one-row or 2×2 grid) crammed buttons too
  small. New layout: exactly two panes side-by-side. Each pane has its
  own little `ChoiceChip` row at the top to pick which content to
  display — Num / Trig / CAS / Advanced / Vars. Defaults: left = Num,
  right = CAS. The user can swap either side independently.
- Threshold for 2-pane mode: 900 px. Below that the 5-tab compact mode
  kicks in unchanged.
- Buttons are now properly sized — each pane gets ~half the keypad
  width with 4 columns, so cells are large enough to read & tap.

### Release build attempted, debug still working
- Tried `flutter build macos --release`. Build succeeds (52.7 MB universal
  binary) but `nm` reports 0 `flutter_symengine_*` symbols in the
  Runner binary — the static archive isn't getting linked in for
  release configs even though the Pods-Runner.release.xcconfig has the
  same `-all_load` we use successfully in debug.
- Experimented with `-Wl,-force_load,<xcframework-slice>` instead of
  `-all_load`: works for either path alone but produces duplicate
  symbols when combined. Couldn't find a combination that works for
  both debug AND release in one Podfile pass.
- Reverted to the working `-all_load` configuration so debug stays
  green; added a P1 entry to PLAN.md with the failure details so the
  release-link investigation can continue.



### Matrix editor reachable
- It's already wired up: tap the `matrix` button on the Symbolic keypad and
  the calculator pushes the `MatrixEditorScreen`. The "Use Matrix" button
  in the editor returns `[1,2; 3,4]`-style syntax back into the input.
  (The button label wasn't very discoverable — left as-is for now; see
  PLAN.)

### Keypad: full inventory back, smarter wide layout
- I had over-corrected the previous "too overcrowded" feedback by dropping
  buttons. Restored the full inventory:
  - **Num** (24 keys): digits, parens, basic operators, `^`, `sqrt`, `π`,
    `EXE`.
  - **Trig** (16): `sin/cos/tan`, inverse + hyperbolic + inverse-hyperbolic
    families, `ln/log/exp/abs`.
  - **CAS** (16): `solve`, `factor`, `expand`, `simplify`, `d/dx`, `∫`,
    `lim`, `subst`, `gcd`, `lcm`, equals, comma, `f(x)`, cursor arrows,
    `EXE`.
  - **Advanced** (20): `gamma`, `!`, `fib`, `prime`, `mod`, `ⁿ√x`, `γ`,
    `∞`, matrix ops (`matrix`, `det`, `inv`, `transpose`), the new vector
    ops (`dot`, `cross`, `norm`, `unit`), `x`, `Ans`, `i`, `EXE`.
- TabController length back to 5; mobile sees five clean tabs.
- Wide layout no longer crams all four sections side-by-side — uses a 2×2
  grid (Num+Trig on top, CAS+Advanced below) plus the Vars panel on the
  right. Cells stay a comfortable size.
- Wide threshold moved from 760 → 900 px since the layout is now beefier.

### Tensor core (rank-N, pure Dart)
- New `lib/engine/tensor.dart` with a shape-aware `Tensor` class:
  - Constructors: `scalar`, `vector`, `matrix`, `fromNested` (auto-infers
    shape from arbitrarily nested lists), `filled`.
  - Indexed access (1-based check, range-validated): `getAt`, `setAt`
    (immutable — `setAt` returns a new tensor).
  - Element-wise `+`, `-`, scalar `scale(s)`.
  - General contraction over a chosen axis pair on each side. For matched
    rank-1 ↔ rank-1, the result is a scalar (a `String` of the dot
    product). Otherwise a new tensor with the contracted axes removed.
  - Vector helpers: `dot`, `cross` (3D only, validates), `norm` (symbolic),
    `numericNorm` (returns `double?` when all components parse as reals).
- Components stay as SymEngine-compatible strings so symbolic content
  (e.g. `'x'`, `'2*y+1'`) flows through arithmetic and reaches the engine
  for simplification.

### Vector preprocessor
- New `lib/engine/vector_math.dart` rewrites `dot(...)`, `cross(...)`,
  `norm(...)`, `unit(...)` calls on inline vector literals into plain
  arithmetic before the engine sees them:
  - `dot([1,2,3], [4,5,6])` → `((1)*(4) + (2)*(5) + (3)*(6))` → 32.
  - `cross([1,0,0], [0,1,0])` → `[0, 0, 1]` (after SymEngine simplifies).
  - `norm([3,4])` → `sqrt((3)^2 + (4)^2)` → 5.
  - `unit([1,0,0])` → `[(1)/sqrt(...), (0)/sqrt(...), (0)/sqrt(...)]`.
- Walks the expression with a fixed-point loop so nested calls like
  `norm(cross(a, b))` resolve fully. Vector-returning rewrites emit a
  bare `[...]` literal so the outer call can re-parse it.
- Hooked in at the top of `ExpressionPreprocessingUtils.preprocessNativeExpression`
  so the calculator and graphing screens both benefit.

### Calculator handlers added
- `exp`, `subst`, `i`, plus all four vector ops — they were missing
  button handlers when I restored the keypad.

### Tests (51 new → 235 total, all passing)
- `test/tensor_test.dart` — 23 cases: construction, indexing, shape
  validation, element-wise ops, scale, dot/cross/norm/contract.
- `test/vector_math_test.dart` — 13 cases: dot/cross/norm/unit
  expansions, length/arity validation, non-vector pass-through,
  partial-word safety (`dotty(...)` doesn't trigger), nested calls.

### Status
- `flutter analyze`: clean (no errors / warnings).
- `flutter test`: **235 passing.**
- macOS debug build succeeds, SymEngine still linked, app launches.



### App icon
- The icon assets had been correct since the previous round, but macOS's
  Launch Services cache was holding on to the old icon. Killed the
  running app, re-registered the bundle via `lsregister -f`, restarted
  Dock and Finder, relaunched. New blue squircle now shows.

### Auto-solve bare equations
- The calculator used to print "Error: evaluate failed" if you typed an
  equation like `2x+3=0` or `x^2 - 4 = 0` without wrapping it in
  `solve(...)`. Now anything containing `=` that didn't already match
  the variable-assignment or function-definition patterns is routed
  through the solver automatically. `2x + 3 = 0` → `x = -3/2`.
- The handler builds `LHS - (RHS)` and asks `detectVariable` what to
  solve for, then dispatches `_engine.solve`.

### `detectVariable` regex bug
- The single-letter detector used `\b([a-zA-Z])\b`, but `\b` doesn't fire
  between a digit and a letter, so `2k+5` returned zero candidates and
  fell through to the default `x`. Switched to explicit
  `(?<![a-zA-Z])([a-zA-Z])(?![a-zA-Z])` so digit-adjacent variables
  (`2k`, `3y`, `100z`) are now detected correctly. Confirmed with a new
  test (`detectVariable('2k+5')` → `'k'`).

### Tests
- New `test/auto_solve_test.dart` covers the bare-equation heuristic
  and the `detectVariable` cases that now work.
- 184 + 9 new = **193 tests passing**; `flutter analyze` still clean.



### Pure-math helpers extracted for unit testing
- Moved the plane analysis math from the screen's `_analyze` into
  `lib/engine/plane_math.dart` as `analyzePlaneFromCoordinate` /
  `analyzePlaneFromParametric` returning a `PlaneAnalysis` record.
- Moved the conic classifier into `lib/engine/conic_math.dart` as
  `analyzeConic(...)` returning a `ConicAnalysis`.
- Extracted Simpson's rule, one-sided limit, limit-at-infinity into
  `lib/engine/numerical.dart`. `CalculatorEngine.limit` / `integrate`
  now call these helpers so production and tests run the same code.

### New test files (60 tests added → 184 total, all passing)
- `test/plane_math_test.dart` — Vector3 ops, coordinate-form analysis,
  parametric form, point-on-plane verification, zero/parallel error paths.
- `test/conic_math_test.dart` — unit circle, axis-aligned ellipse,
  parabola, hyperbola, translated circle, xy=1 (45° rotation),
  degenerate cases, discriminant signs.
- `test/numerical_test.dart` — `∫₀¹ x dx`, `∫₀¹ x² dx`, `∫₀^π sin(x) dx`,
  reversed limits, non-finite integrand, odd-n correction, `sin(x)/x`
  removable singularity, jump discontinuity, infinity convergence.
- `test/limit_integrate_test.dart` — fallback paths when the bridge
  isn't loaded (so unit tests run on host without the native lib).
- `test/app_state_persistence_test.dart` — locale and number-format
  load/save round-trip, history JSON encoding, 200-entry cap,
  variables JSON, graph functions JSON, theme mode load/save.

### Persisted everything else
- `AppState` now persists *all* user data, not just locale + number
  format: history (JSON, capped at 200), user variables (JSON map),
  graph functions Y1..Y10 (JSON array), and theme mode.
- Added `AppState.load({force: false})` flag so tests can reset the
  singleton with a fresh `SharedPreferences.setMockInitialValues`.

### History clear button
- Added a sweep icon next to the LaTeX/plain segmented toggle on the
  calculator screen. Pops a confirm dialog, calls `AppState.clearHistory`,
  which also writes the empty list back to prefs. Localized (English +
  German).

### Light / dark / system theme picker
- `AppState.themeMode` is a new persistent `ThemeMode`.
- `MaterialApp` now has both `theme` (light) and `darkTheme` (dark) plus
  `themeMode: appState.themeMode`. The NavigationRail / BottomNavBar
  surfaces use `Theme.of(context).colorScheme` so light mode actually
  looks correct.
- Settings has a new card with three options (System / Light / Dark),
  fully localized.

### Tests still green
- `flutter analyze`: no errors / warnings — 19 info-only hints.
- `flutter test`: **184 / 184 passing.**



### macOS build & native bridge linkage
- Installed CocoaPods correctly (the Homebrew install was already there but
  was tripping over a stale `~/.gem/ruby/3.1.3/gems/bigdecimal` from a Ruby
  upgrade — `flutter build macos` now runs with `GEM_HOME` / `GEM_PATH`
  unset so `pod` uses its bundled gems).
- `symbolic_math_bridge` plugin was missing its macOS bits. Fixed by:
  - Renaming `macos/Classes/SymbolicMathBridgePlugin.swift` →
    `SwiftSymbolicMathBridgePlugin.swift` and aligning the class name with
    the iOS one so `pluginClass: SwiftSymbolicMathBridgePlugin` resolves
    on both platforms.
  - Pointing the macOS podspec at the existing xcframeworks (GMP, MPFR,
    MPC, FLINT, SymEngineFlutterWrapper) via in-directory symlinks — the
    xcframeworks already shipped a `macos-arm64_x86_64` slice, just hadn't
    been wired up.
  - Adding `-all_load` to the Runner's `OTHER_LDFLAGS` in a Podfile
    `post_install` hook. Without it the linker drops every SymEngine
    symbol (they're reached only via `dart:ffi`, not by static reference).
- Removed the stale "Run Script" build phase in `macos/Runner.xcodeproj`
  that called a missing `copy_native_lib.sh` script — the project no
  longer ships a per-build dylib.
- `nm` now reports ~45 `flutter_symengine_*` symbols in the built binary
  and `evaluate("1+1")` returns `2` instead of "requires native library".

### Crash / focus fixes
- Three `KeyboardListener(autofocus: true)` instances (calculator,
  graphing, function-editor) were alive at once in the `IndexedStack`.
  After a few clicks they'd corrupt the focus tree and the app would
  freeze. All three now use `autofocus: false`; `MainScreen.requestFocus()`
  explicitly drives focus when the user changes destinations.
- Three function-picker dialogs (Integral, NthRoot, Limit) created
  `FocusNode()` inline in `build()` — a new node every rebuild, never
  disposed. Replaced with state-held FocusNodes that get disposed.

### Keypad / layout redesign
- User feedback: "we do NOT need all the tabs … on a large enough screen"
  and "now it is way to overcrowded. half of the buttons would be much
  better. so 2 and not 4 or 5 tabs?". So:
  - Consolidated the keypad from 5 tabs (Num / Trig / CAS / Advanced / Vars)
    down to 3 (Basic / Symbolic / Vars), each with a curated key list.
  - Above ~760 px the keypad drops the tab bar and shows Basic + Symbolic
    + Variables side by side ("flat" layout).
  - TabController length lowered from 5 → 3 in all four screens that
    embed the keypad (was crashing graphing once the keypad shrank).
- Dropped the secondary-pane split layout from `MainScreen` — it added
  complexity without much value. Wide screens now just use a single
  `NavigationRail` (extended above 1100 px) and one content area.

### Graphing screen
- Default `_showKeypad = false` so the plot has the full graph area at
  launch. The toolbar toggle still works.
- When the keypad is shown, plot flex 3 vs keypad flex 2 keeps the plot
  dominant.
- Added explicit Zoom In, Zoom Out, Reset View buttons in the app bar
  (the pinch gesture still works too).

### Variable / Memory panel overflow
- The memory grid was `GridView.count(crossAxisCount: 3, aspectRatio: 2.2)`
  inside `maxHeight: 120`. On wide parents the cells stretched and the
  grid blew past `maxHeight`, causing yellow/black overflow stripes.
  Replaced with a `Wrap` of fixed `64×36` tiles.
- Wrapped the entire viewer in a single `SingleChildScrollView` so short
  viewports scroll instead of clipping.

### Numerical limit + integrate
- Added Dart-side numerical implementations because the C++ wrapper
  doesn't expose `limit`/`integrate` yet:
  - `limit(expr, var, point)` evaluates the expression at `point ± 1e-7`
    (and at `1e10` for `oo`), checks one-sided agreement, returns the
    converged real value or a clear "limits differ" / "does not
    converge" error.
  - `integrate(expr, var, lower, upper)` does composite Simpson's rule
    with `n = 200` subintervals. Indefinite integration still returns
    a "not yet supported" error.
- Calculator screen now routes `integrate(...)` and `limit(...)` through
  those new handlers (was returning the placeholder error before).

### F → Y compatibility
- `F<N> = expr` no longer hard-errors; it stores into the same slot as
  `Y<N>` so old muscle memory works.

### Analysis modules — Planes & Conic Sections
- Built `plane_analysis_screen.dart`: accepts either coordinate form
  (`ax + by + cz = d`) or parametric form (point + two direction
  vectors), then reports the other form, unit normal, Hessian normal,
  signed distance from origin, and axis intercepts. Pure Dart, no
  SymEngine needed.
- Built `conic_section_screen.dart`: classifies `Ax² + Bxy + Cy² + Dx +
  Ey + F = 0` using the discriminant. Reports type (ellipse / circle /
  parabola / hyperbola), center for central conics, rotation angle when
  `B ≠ 0`, and semi-axes + eccentricity when the shape is non-degenerate.
- Replaced the analysis hub's two "coming soon" snackbars with real
  navigation to the new screens.

### Persistence + full i18n
- Added `shared_preferences: ^2.2.0`. `AppState` now has an async
  `load()` that runs before `runApp` and persists locale + number
  format. Changes are saved on the spot.
- Settings screen got a language picker (English / Deutsch). It writes
  through `AppState.setLocale`, the `MaterialApp` rebuilds with the new
  locale, and the choice survives restarts.
- `AppLocalizations` grew to cover nav destinations, graphing screen,
  analysis modules, settings, dialogs, snack bars, and keypad section
  labels. The German translation tracks every key.

### App icon
- Generated a 1024×1024 master with the BFL FLUX API (deep-blue → cyan
  gradient squircle, white sine wave + plus sign, no text). Sized down
  to every slot in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
  (16, 32, 64, 128, 256, 512, 1024) and
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (every required
  `@1x/@2x/@3x` combination 20 → 1024).

### Tests still green
- 124 tests passing under `flutter test` after every round of changes.
- `flutter analyze` is at 19 info-only hints, no errors, no warnings.

---

## 2026-05-16 — Audit, fixes, tests, adaptive layout

### Build / dependency
- Restored the missing `symbolic_math_bridge` path dependency from backup so
  `flutter pub get` succeeds. Moved the project to `/Volumes/backups/code/`
  to free space on the cramped main volume.
- Fixed the only compile-error in the test suite (`test/widget_test.dart`
  referenced the non-existent `MyApp` class).

### Correctness bugs
- `_handleSimplifyFunction` was wired to `_engine.expand()`. Added
  `simplify()` to `CalculatorEngine` and pointed the handler at it.
- `KeyboardInputHandler` unconditionally swapped Y↔Z and rewrote every `*`
  via physical-key checks, so any non-German keyboard misbehaved. Rewrote to
  use `event.character` (already layout-resolved by the OS) and added a
  `multiplicationAsCdot` flag so the `*` → `\cdot ` rewrite is overridable.
- `\frac{}{}` insertions used `cursorOffsetFromEnd: -4`, which placed the
  cursor *outside* the first brace pair. Corrected to `-3` so typing into a
  freshly-inserted fraction goes into the numerator.
- `LatexConversionUtils.fromLatex` ran power/subscript rewrites before
  integral/limit/sum/product rewrites, which stripped the `_{...}^{...}`
  groups those depend on. Reordered.
- `fromLatex` also called `result.replaceAll('|', '')` at the top, which
  broke `|x|` → `abs(x)`. Removed; pipes are now content.
- `ExpressionPreprocessingUtils.preprocessNativeExpression` produced
  `Matrix([[1,2],[3,4]])` without spaces; the subsequent German-comma rule
  rewrote `1,2` → `1.2`. Matrix conversion now emits `1, 2` with a space.
- `detectVariable` was lower-casing the equation before scanning, so `X`
  became `x`. Made the matcher case-sensitive (SymEngine treats them as
  distinct).
- `preprocessExpression` had no recursion guard, so a cyclic Y1 → Y2 → Y1
  reference would loop forever. Added a depth cap (4) and a regression test.

### Dead code / deprecated APIs
- Replaced every `RawKeyboardListener` (calculator, graphing, curve-analysis,
  function-editor, three dialog widgets) with `KeyboardListener`.
- Replaced every `withOpacity(x)` with `withValues(alpha: x)` across
  `graphing_screen.dart`, `variable_viewer.dart`, `curve_analysis_input_screen.dart`,
  `function_editor_screen.dart`.
- Deleted `_toLatex_old` from `calculator_screen.dart`, `latex_input_field.dart`,
  `function_picker_dialogs.dart`. Deleted `_normalizeForDisplay_old` from
  `analysis_engine.dart`. Deleted `_getColorForUserFunction` from
  `variable_viewer.dart`. Deleted the unused `_analysisEngine` field and
  unreferenced `onSave` parameter.
- Replaced 50+ `print(...)` calls with `debugPrint(...)` or guarded them
  behind `kDebugMode`.
- Converted top-of-file `///` doc comments to `//` where they weren't real
  library-level docs.
- Dropped unused imports.

### Engine surface
- `CalculatorEngine` exposes `simplify`, plus a graceful fallback for every
  method when the native bridge isn't loaded so unit tests can run.

### Tests (124 total, all passing)
- Test files cover preprocessing, LaTeX conversion, display formatting, app
  state, controller, keyboard handler, engine fallbacks, analysis pipeline.

### Responsive layout (v1)
- Initial adaptive shell: bottom nav below 720 px, NavigationRail above.
  Dropped the `BoxConstraints(minWidth: 400, …)` that was clipping smaller
  desktop windows.

### Docs
- Rewrote `readme.md`: corrected file structure, removed dead CMake
  instructions, documented the adaptive layout and known limitations.

### Static analysis
- 210 issues (1 error) → 19 info-only hints by the end of this round.
