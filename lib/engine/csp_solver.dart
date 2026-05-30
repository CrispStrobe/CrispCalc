// lib/engine/csp_solver.dart
//
// Thin wrapper around the dart_csp library for the two patterns the
// Analysis-hub "Constraints" module surfaces in Round A:
//
//   1. Diophantine equations: a set of named integer variables each
//      bounded to a contiguous range, plus a list of string
//      constraints (dart_csp's parser handles `==`, `!=`, `<`, `<=`,
//      arithmetic, etc.). Returns *all* solutions in a list.
//
//   2. Cryptarithms (SEND + MORE = MONEY): parses a `word1 op word2
//      = word3` expression, builds the standard model — each unique
//      letter is a 0..9 variable, allDifferent on all letters,
//      leading letters cannot be 0, the digit-place expansion of
//      both sides must be equal — then asks dart_csp for the unique
//      digit assignment.
//
// The wrapper exists so the UI layer doesn't take a direct dependency
// on dart_csp's Problem API and so we can swap the underlying engine
// later without rewiring the screen. It also gives us a single place
// to put the safety net (timeouts, max-solution caps).

import 'package:dart_csp/dart_csp.dart' as csp;

/// One (variable → integer) solution from `solveDiophantine`.
typedef DiophantineSolution = Map<String, int>;

/// Round 76: one no-overlap (scheduling) group. The parallel lists
/// `starts` and `durations` describe a set of tasks whose half-open
/// intervals `[start_i, start_i + duration_i)` may not overlap —
/// the canonical single-machine scheduling constraint. Routes to
/// dart_csp's `Problem.addNoOverlap` which expands to the
/// cumulative time-table propagator under the hood.
typedef NoOverlapGroup = ({List<String> starts, List<int> durations});

/// Round 80: one cumulative (renewable-resource) group. Generalises
/// [NoOverlapGroup] from a unary machine to a resource of integer
/// [capacity]: at any time `t`, the sum of `demands[i]` across tasks
/// whose half-open interval `[starts[i], starts[i] + durations[i])`
/// covers `t` may not exceed [capacity]. Routes to dart_csp's
/// `Problem.addCumulative`.
typedef CumulativeGroup = ({
  List<String> starts,
  List<int> durations,
  List<int> demands,
  int capacity,
});

/// Round D / Gantt: per-task metadata threaded from the DSL parser
/// into the result so the screen can render a Gantt chart over the
/// solved start times. `demand` is `null` for `noOverlap`-only
/// tasks; populated only for `cumulative` groups. Pure data
/// container — no engine state.
class GanttTaskSpec {
  final String startVar;
  final int duration;

  /// Renewable-resource demand. `null` for `noOverlap` (implicit
  /// 1-against-capacity-1); set for `cumulative` groups.
  final int? demand;

  /// Tasks from the same `noOverlap` / `cumulative` line share an
  /// index so the renderer can lay them out on the same lane.
  final int groupIndex;

  const GanttTaskSpec({
    required this.startVar,
    required this.duration,
    this.demand,
    required this.groupIndex,
  });
}

/// Result envelope returned by [CspSolver.solveDiophantine]. Holds
/// either a list of solutions or an error message — never both.
class DiophantineResult {
  final List<DiophantineSolution> solutions;
  final String? error;

  /// True when the user-supplied input was valid (even if it yielded
  /// no solutions). False means [error] is populated with a parse /
  /// validation message.
  bool get ok => error == null;

  /// True only when we hit `maxSolutions` and stopped early. The
  /// caller can show a "showing first N" badge.
  final bool truncated;

  /// Round 74: optimal objective value for `minimize` / `maximize`
  /// DSL programs. Null for enumeration-mode results. When present,
  /// [solutions] holds exactly one assignment (the optimum).
  final num? objective;

  /// Schedule metadata threaded through from the DSL parser for
  /// `noOverlap` / `cumulative` programs. Each entry pairs a task
  /// name (the start-time variable) with its duration and (for
  /// cumulative) demand. The Gantt renderer in the DSL tab uses
  /// these alongside [solutions] to draw a chart instead of leaving
  /// the result as a wall of "s1 = 0, s2 = 4" text. Empty when the
  /// program had no scheduling constraints.
  final List<GanttTaskSpec> ganttTasks;
  final int? ganttCapacity;

  const DiophantineResult._({
    required this.solutions,
    required this.error,
    required this.truncated,
    this.objective,
    this.ganttTasks = const [],
    this.ganttCapacity,
  });

  factory DiophantineResult.ok(
    List<DiophantineSolution> solutions, {
    bool truncated = false,
    List<GanttTaskSpec> ganttTasks = const [],
    int? ganttCapacity,
  }) =>
      DiophantineResult._(
        solutions: solutions,
        error: null,
        truncated: truncated,
        ganttTasks: ganttTasks,
        ganttCapacity: ganttCapacity,
      );

  factory DiophantineResult.failure(String message) => DiophantineResult._(
        solutions: const [],
        error: message,
        truncated: false,
      );

  /// Round 74: optimization result (minimize / maximize). Carries a
  /// single optimal assignment plus the corresponding objective value.
  factory DiophantineResult.optimal(
    DiophantineSolution assignment,
    num objective, {
    List<GanttTaskSpec> ganttTasks = const [],
    int? ganttCapacity,
  }) =>
      DiophantineResult._(
        solutions: [assignment],
        error: null,
        truncated: false,
        objective: objective,
        ganttTasks: ganttTasks,
        ganttCapacity: ganttCapacity,
      );
}

/// Result envelope for [CspSolver.solveCryptarithm].
class CryptarithmResult {
  /// Mapping from letter → digit. Empty when [error] is set.
  final Map<String, int> assignment;
  final String? error;
  bool get ok => error == null;

  const CryptarithmResult._({required this.assignment, required this.error});

  factory CryptarithmResult.ok(Map<String, int> assignment) =>
      CryptarithmResult._(assignment: assignment, error: null);

  factory CryptarithmResult.failure(String message) =>
      CryptarithmResult._(assignment: const {}, error: message);
}

/// One row of a minimal-unsatisfiable-subset rendering. Carries the
/// user-meaningful label that was attached when the constraint was
/// posted (or a derived fallback when none was set) plus the
/// constraint kind / variables for context. Round E.2.
class MusEntry {
  /// User-facing description. Either the `label:` threaded into the
  /// `addX` call (DSL source line, "constraint #N", etc.) or, when
  /// the constraint had no label, a derived `kind(variables)` string.
  final String label;

  /// dart_csp coarse-grained kind label — `'binary'`, `'linearEquals'`,
  /// `'allDifferent'`, `'cumulative'`, etc. Useful for grouping /
  /// iconography in the UI.
  final String kind;

  /// Variables this constraint scopes, in posting order.
  final List<String> variables;

  const MusEntry({
    required this.label,
    required this.kind,
    required this.variables,
  });
}

/// Result envelope for the explanation pass.
///
/// Three steady-state shapes:
///   * `error != null` — couldn't build the model (parse error,
///     unknown var name, etc.). The UI surfaces [error] verbatim.
///   * `wasSatisfiable == true` — QuickXplain decided the model is
///     actually satisfiable. Either the user clicked Explain on a
///     run that had hit `maxSolutions` capping, or there's a flake
///     between solver runs. UI shows a "model is satisfiable" hint.
///   * `entries` populated — the MUS itself. Typically 2–6 entries
///     for hand-authored constraint sets.
class CspMusResult {
  final List<MusEntry> entries;
  final String? error;
  final bool wasSatisfiable;

  const CspMusResult._({
    required this.entries,
    required this.error,
    required this.wasSatisfiable,
  });

  factory CspMusResult.ok(List<MusEntry> entries) =>
      CspMusResult._(entries: entries, error: null, wasSatisfiable: false);

  factory CspMusResult.satisfiable() => const CspMusResult._(
        entries: [],
        error: null,
        wasSatisfiable: true,
      );

  factory CspMusResult.failure(String message) => CspMusResult._(
        entries: const [],
        error: message,
        wasSatisfiable: false,
      );
}

/// The kind of a single [CspTraceStep] — a UI-facing mirror of
/// dart_csp's `PropagationEventKind`, decoupled so the screen layer
/// never imports the solver package directly (Round F).
enum CspTraceStepKind {
  /// The search pinned [CspTraceStep.variable] to
  /// [CspTraceStep.value] at [CspTraceStep.depth].
  decision,

  /// A constraint removed [CspTraceStep.removedValues] from
  /// [CspTraceStep.variable]'s domain (which stayed non-empty).
  prune,

  /// A prune that emptied a domain — the immediate cause of the
  /// current branch's dead-end.
  wipeout,

  /// The search abandoned the decision at [CspTraceStep.depth] and
  /// rolled back one level.
  backtrack,

  /// Conflict-directed backjump from [CspTraceStep.depth] to
  /// [CspTraceStep.targetDepth].
  backjump,

  /// A complete consistent assignment ([CspTraceStep.assignment]).
  solution,
}

/// One replayable step of a propagation/search trace. Carries the raw
/// event fields *and* a full post-step domain snapshot
/// ([domains]) so the visualizer can render the state after the step
/// by simple indexing — no replay logic in the widget. Round F
/// (leverages dart_csp 2.2.0's propagation-trace API).
class CspTraceStep {
  final int seq;
  final CspTraceStepKind kind;

  /// Variable decided ([CspTraceStepKind.decision]) or pruned
  /// ([CspTraceStepKind.prune] / [CspTraceStepKind.wipeout]).
  final String? variable;

  /// The pinned value, for a decision.
  final int? value;

  /// Values removed from [variable], for a prune / wipeout.
  final List<int> removedValues;

  /// [variable]'s domain just before the prune (ascending).
  final List<int> domainBefore;

  /// [variable]'s domain just after the prune (empty on a wipeout).
  final List<int> domainAfter;

  /// Coarse kind of the causing constraint — `'binary'` for an AC-3
  /// arc, else the n-ary kind (`'allDifferent'`, `'linearLeq'`, …).
  final String? causeKind;

  /// The causing constraint's user label (the DSL source line, etc.).
  final String? causeLabel;

  /// Variables the causing constraint scopes.
  final List<String> causeScope;

  /// Decision depth (0 at the root), for decision / backtrack /
  /// backjump.
  final int? depth;

  /// Backjump target depth, for a backjump.
  final int? targetDepth;

  /// The complete assignment, for a solution step.
  final Map<String, int>? assignment;

  /// Full domain snapshot of every variable *after* this step is
  /// applied. The visualizer renders this directly.
  final Map<String, List<int>> domains;

  const CspTraceStep({
    required this.seq,
    required this.kind,
    required this.domains,
    this.variable,
    this.value,
    this.removedValues = const [],
    this.domainBefore = const [],
    this.domainAfter = const [],
    this.causeKind,
    this.causeLabel,
    this.causeScope = const [],
    this.depth,
    this.targetDepth,
    this.assignment,
  });
}

/// Result envelope for [CspSolver.traceDsl]. Carries the ordered
/// [steps], the declared variable order + [initialDomains] (so the
/// visualizer can show the starting state before step 0), and the
/// terminal outcome ([solved] / [solution] or unsatisfiable).
///
/// Shapes:
///   * `error != null` — the model failed to build/parse.
///   * `unsupported == true` — the program is valid but can't be
///     traced as-is (e.g. it has no finite-domain variables); the
///     reason is in [error].
///   * otherwise — a real trace; [solved] tells whether the search
///     reached a [solution] or proved unsatisfiability.
class CspTraceResult {
  final String? error;

  /// True when the program parsed but doesn't fit the trace path.
  final bool unsupported;

  /// Declared variables, in source order.
  final List<String> variables;

  /// Each variable's full declared domain, before any propagation.
  final Map<String, List<int>> initialDomains;

  final List<CspTraceStep> steps;

  /// True when the trace ended on a complete assignment.
  final bool solved;

  /// The found assignment when [solved]; null on unsatisfiable.
  final Map<String, int>? solution;

  /// True when the event stream hit the `maxEvents` cap and was cut
  /// short — the trace is a partial prefix.
  final bool truncated;

  /// True when the program carried a `minimize` / `maximize` directive
  /// that the trace path ignores (it visualizes the feasibility
  /// search over the constraints, not the optimization).
  final bool objectiveIgnored;

  bool get ok => error == null;

  const CspTraceResult._({
    required this.error,
    required this.unsupported,
    required this.variables,
    required this.initialDomains,
    required this.steps,
    required this.solved,
    required this.solution,
    required this.truncated,
    required this.objectiveIgnored,
  });

  factory CspTraceResult.failure(String message) => CspTraceResult._(
        error: message,
        unsupported: false,
        variables: const [],
        initialDomains: const {},
        steps: const [],
        solved: false,
        solution: null,
        truncated: false,
        objectiveIgnored: false,
      );

  factory CspTraceResult.unsupportedProgram(String message) => CspTraceResult._(
        error: message,
        unsupported: true,
        variables: const [],
        initialDomains: const {},
        steps: const [],
        solved: false,
        solution: null,
        truncated: false,
        objectiveIgnored: false,
      );

  factory CspTraceResult.ok({
    required List<String> variables,
    required Map<String, List<int>> initialDomains,
    required List<CspTraceStep> steps,
    required bool solved,
    required Map<String, int>? solution,
    required bool truncated,
    required bool objectiveIgnored,
  }) =>
      CspTraceResult._(
        error: null,
        unsupported: false,
        variables: variables,
        initialDomains: initialDomains,
        steps: steps,
        solved: solved,
        solution: solution,
        truncated: truncated,
        objectiveIgnored: objectiveIgnored,
      );
}

class CspSolver {
  /// Solves a small Diophantine-style problem. [variables] maps each
  /// variable name to its inclusive `[min..max]` integer range.
  /// [constraints] is a list of dart_csp string constraints
  /// (`'x + y == 30'`, `'x != y'`, `'x in [1, 3, 5]'`, etc.).
  /// Enumerates up to [maxSolutions] solutions and returns them; the
  /// `truncated` flag on the result tells the caller whether the search
  /// was cut short.
  ///
  /// Returns a `DiophantineResult` rather than throwing — callers
  /// surface `error` to the user when parsing or solving fails. The
  /// caller is expected to have already wrapped this in
  /// `_runWithProgress` if needed (we don't reach for the worker
  /// isolate yet — CSP problems of typical homework size run in
  /// milliseconds).
  static Future<DiophantineResult> solveDiophantine({
    required Map<String, ({int min, int max})> variables,
    required List<String> constraints,
    List<NoOverlapGroup> noOverlap = const [],
    List<CumulativeGroup> cumulative = const [],
    int maxSolutions = 100,
  }) async {
    if (variables.isEmpty) {
      return DiophantineResult.failure('No variables declared.');
    }
    final problem = csp.Problem();
    try {
      for (final entry in variables.entries) {
        final (min: lo, max: hi) = entry.value;
        if (hi < lo) {
          return DiophantineResult.failure(
              'Variable ${entry.key}: range max ($hi) < min ($lo).');
        }
        if (hi - lo > 10000) {
          return DiophantineResult.failure(
              'Variable ${entry.key}: range too large (max−min > 10000).');
        }
        problem.addRangeVariable(entry.key, lo, hi);
      }
      final knownVars = variables.keys.toSet();
      for (final c in constraints) {
        // dart_csp's string parser is reliable for simple shapes
        // (`x == 5`, `x != y`, `x < y`) and unit-coefficient sums
        // (`x + y == 12`), but stumbles on coefficient-bearing
        // linear expressions like `2*x + 3*y == 12`. Detect those
        // and route to the dedicated `addLinearEquals` /
        // `addLinearLeq` / `addLinearGeq` API which uses the same
        // bounds-consistency propagator the linear-arithmetic test
        // in the README exercises.
        final linear = _tryParseLinear(c, knownVars);
        if (linear != null) {
          final (:vars, :coeffs, :op, :bound) = linear;
          switch (op) {
            case '==':
              problem.addLinearEquals(vars, coeffs, bound);
              break;
            case '<=':
              problem.addLinearLeq(vars, coeffs, bound);
              break;
            case '>=':
              problem.addLinearGeq(vars, coeffs, bound);
              break;
            case '<':
              // strict — model as <= bound - 1 for integers.
              problem.addLinearLeq(vars, coeffs, bound - 1);
              break;
            case '>':
              problem.addLinearGeq(vars, coeffs, bound + 1);
              break;
          }
          continue;
        }
        problem.addStringConstraint(c);
      }
      // Round 76: scheduling overlays. Each group routes to
      // dart_csp's cumulative-backed addNoOverlap; the helper
      // validates start vars + non-negative durations itself.
      for (final group in noOverlap) {
        problem.addNoOverlap(group.starts, group.durations);
      }
      // Round 80: renewable-resource scheduling overlays. Same time-
      // table propagator as addNoOverlap but with variable per-task
      // demands and an integer capacity bound.
      for (final group in cumulative) {
        problem.addCumulative(
          group.starts,
          group.durations,
          group.demands,
          group.capacity,
        );
      }
    } catch (e) {
      return DiophantineResult.failure(
          'Failed to parse constraints: ${_friendlyError(e)}');
    }

    try {
      final solutions = <DiophantineSolution>[];
      await for (final s in problem.getSolutions()) {
        // dart_csp returns Map<String, dynamic>; coerce values to int
        // since every range variable carries int values.
        final coerced = <String, int>{
          for (final entry in s.entries)
            entry.key: (entry.value as num).toInt(),
        };
        solutions.add(coerced);
        if (solutions.length >= maxSolutions) {
          return DiophantineResult.ok(
            solutions,
            truncated: true,
            ganttTasks: _buildGanttTasks(noOverlap, cumulative),
            ganttCapacity: _firstCapacity(cumulative),
          );
        }
      }
      return DiophantineResult.ok(
        solutions,
        ganttTasks: _buildGanttTasks(noOverlap, cumulative),
        ganttCapacity: _firstCapacity(cumulative),
      );
    } catch (e) {
      return DiophantineResult.failure('Solver failed: ${_friendlyError(e)}');
    }
  }

  /// Solves a cryptarithm of the form `WORD1 + WORD2 = WORD3` (or
  /// `-` instead of `+`). Each unique letter becomes a 0..9 variable;
  /// all letters are pairwise different; leading letters can't be 0;
  /// the digit-place expansion of both sides must be equal. Returns
  /// the single assignment when one exists.
  ///
  /// Only `+`/`-` between two words on the left and one word on the
  /// right is supported in Round A. More complex shapes
  /// (`A * B = C`, `A + B + C = D`, `A = B`) are V2 work.
  static Future<CryptarithmResult> solveCryptarithm(String expression) async {
    final parsed = _parseCryptarithmExpression(expression);
    if (parsed == null) {
      return CryptarithmResult.failure(
          'Expected `WORD1 + WORD2 = WORD3` (only + / - supported).');
    }
    final (:lhsA, :op, :lhsB, :rhs) = parsed;
    final words = [lhsA, lhsB, rhs];
    final letters = <String>{
      for (final w in words)
        for (final ch in w.split('')) ch,
    }.toList();

    if (letters.length > 10) {
      return CryptarithmResult.failure(
          'Cryptarithm has ${letters.length} distinct letters; '
          'at most 10 fit into digits 0..9.');
    }

    final problem = csp.Problem();
    for (final l in letters) {
      problem.addVariable(l, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    }
    // All letters carry distinct digits.
    problem.addAllDifferent(letters);
    // Leading letters can't be zero (no number with leading zeros).
    for (final w in words) {
      if (w.length > 1) {
        problem.addStringConstraint('${w[0]} != 0');
      }
    }
    // Digit-place equality:
    //   Σ place(c) · c   over lhsA
    //   ±Σ place(c) · c   over lhsB   (sign depends on op)
    //   −Σ place(c) · c   over rhs
    //   == 0
    // We collect coefficients per letter rather than building a
    // string expression because dart_csp's string parser doesn't
    // handle large coefficient-bearing sums reliably.
    final coefs = <String, int>{};
    void accumulate(String word, int sign) {
      for (var i = 0; i < word.length; i++) {
        final letter = word[i];
        final place = _intPow(10, word.length - 1 - i);
        coefs[letter] = (coefs[letter] ?? 0) + sign * place;
      }
    }

    accumulate(lhsA, 1);
    accumulate(lhsB, op == '-' ? -1 : 1);
    accumulate(rhs, -1);
    // Drop letters whose net coefficient is zero (rare for well-
    // formed cryptarithms, but possible — they then act only via
    // the allDifferent / leading-zero constraints).
    final orderedLetters = <String>[];
    final orderedCoeffs = <num>[];
    for (final entry in coefs.entries) {
      if (entry.value == 0) continue;
      orderedLetters.add(entry.key);
      orderedCoeffs.add(entry.value);
    }
    problem.addLinearEquals(orderedLetters, orderedCoeffs, 0);

    try {
      final solution = await problem.getSolution();
      if (solution is! Map<String, dynamic>) {
        return CryptarithmResult.failure('No assignment satisfies the puzzle.');
      }
      final assignment = <String, int>{
        for (final entry in solution.entries)
          entry.key: (entry.value as num).toInt(),
      };
      return CryptarithmResult.ok(assignment);
    } catch (e) {
      return CryptarithmResult.failure('Solver failed: ${_friendlyError(e)}');
    }
  }

  /// Parses `WORD1 op WORD2 = WORD3` into its three parts plus the
  /// operator (`+` or `-`). Strips whitespace; case-insensitive on
  /// letters (canonicalized to uppercase). Returns null on any
  /// shape that doesn't match.
  static ({String lhsA, String op, String lhsB, String rhs})?
      _parseCryptarithmExpression(String input) {
    final cleaned = input.trim().toUpperCase().replaceAll(' ', '');
    final m = RegExp(r'^([A-Z]+)([+\-])([A-Z]+)=([A-Z]+)$').firstMatch(cleaned);
    if (m == null) return null;
    return (
      lhsA: m.group(1)!,
      op: m.group(2)!,
      lhsB: m.group(3)!,
      rhs: m.group(4)!,
    );
  }

  static int _intPow(int base, int exp) {
    var r = 1;
    for (var i = 0; i < exp; i++) {
      r *= base;
    }
    return r;
  }

  /// Detects linear constraints of the form `<expr> op <expr>` where
  /// each side is a sum of `coef*var` terms and bare integer
  /// constants, and `op` ∈ `{==, <, <=, >, >=}`. Returns the
  /// canonicalized `(vars, coeffs, op, bound)` with everything moved
  /// to the LHS (RHS becomes a numeric bound) so the result is
  /// ready for dart_csp's `addLinear*` family. Returns null when the
  /// shape doesn't match — caller falls back to the dart_csp string
  /// parser.
  ///
  /// Round 78: extended from "LHS must be linear, RHS must be a
  /// numeric literal" to expression-on-both-sides. `s1 + 4 <=
  /// makespan` now parses natively (and is rewritten internally to
  /// `s1 - makespan <= -4`), which is the natural shape for
  /// scheduling makespan and similar mixed-variable inequalities.
  ///
  /// Only `==`/`<=`/`>=`/`<`/`>` round-trip cleanly into the linear
  /// API; we deliberately decline `!=` here so it stays on the
  /// string-parser path (which handles it correctly).
  static ({
    List<String> vars,
    List<num> coeffs,
    String op,
    num bound,
  })? _tryParseLinear(String constraint, Set<String> knownVars) {
    final stripped = constraint.replaceAll(' ', '');
    // Match `<LHS><op><RHS>`. Non-greedy LHS so multi-char ops
    // (`==`/`<=`/`>=`) win over their `=`/`<`/`>` prefixes.
    final opMatch = RegExp(r'^(.+?)(==|<=|>=|<|>)(.+)$').firstMatch(stripped);
    if (opMatch == null) return null;
    final lhsText = opMatch.group(1)!;
    final op = opMatch.group(2)!;
    final rhsText = opMatch.group(3)!;

    final lhs = _parseLinearTerms(lhsText, knownVars);
    final rhs = _parseLinearTerms(rhsText, knownVars);
    if (lhs == null || rhs == null) return null;

    // Move every RHS term to the LHS (negate coefficient + constant).
    // `lhs op rhs` ⇔ `lhs - rhs op 0` ⇔ `(lhs.vars + rhs.vars) op
    // (rhs.constant - lhs.constant)`.
    final vars = <String>[...lhs.vars, ...rhs.vars];
    final coeffs = <num>[
      ...lhs.coeffs,
      for (final c in rhs.coeffs) -c,
    ];
    final bound = rhs.constant - lhs.constant;
    // Constant-only constraints (`5 == 5`, `3 < 4`) have no
    // variables to constrain — fall back to the string parser so
    // dart_csp can validate / reject them.
    if (vars.isEmpty) return null;
    return (vars: vars, coeffs: coeffs, op: op, bound: bound);
  }

  /// Round 78: split a sum-of-terms expression like `2*x + y - 3*z + 5`
  /// into matched `(vars, coeffs)` lists plus a running `constant`.
  /// Whitespace tolerant. Each term is either:
  ///
  ///   - `[+-]?coef? \*? name` — a coef×var term (coef defaults to 1)
  ///   - `[+-]? integer` — a pure constant term
  ///
  /// Returns null when a term doesn't match either shape, or any
  /// variable name isn't in [knownVars]. Returns `(vars: [], coeffs: [],
  /// constant: 0)` for an empty input, which callers can treat as
  /// "no usable expression".
  ///
  /// Used by [_tryParseLinear] (constraint parsing on both sides of
  /// the comparator) and the `minimize` / `maximize` directives in
  /// [solveDsl].
  static ({List<String> vars, List<num> coeffs, num constant})?
      _parseLinearTerms(String expr, Set<String> knownVars) {
    final stripped = expr.replaceAll(' ', '');
    if (stripped.isEmpty) return null;
    final terms = <String>[];
    var current = StringBuffer();
    for (var i = 0; i < stripped.length; i++) {
      final c = stripped[i];
      if ((c == '+' || c == '-') && i > 0) {
        terms.add(current.toString());
        current = StringBuffer();
      }
      current.write(c);
    }
    if (current.isNotEmpty) terms.add(current.toString());

    final vars = <String>[];
    final coeffs = <num>[];
    num constant = 0;
    for (final raw in terms) {
      final term = raw.trim();
      // Variable term first; falls back to pure-constant term.
      final mVar =
          RegExp(r'^([+-]?)(\d+(?:\.\d+)?)?\*?([A-Za-z_][A-Za-z0-9_]*)$')
              .firstMatch(term);
      if (mVar != null) {
        final sign = mVar.group(1) == '-' ? -1 : 1;
        final mag = mVar.group(2) == null ? 1 : num.parse(mVar.group(2)!);
        final name = mVar.group(3)!;
        if (!knownVars.contains(name)) return null;
        vars.add(name);
        coeffs.add(sign * mag);
        continue;
      }
      final mConst = RegExp(r'^([+-]?\d+(?:\.\d+)?)$').firstMatch(term);
      if (mConst != null) {
        constant += num.parse(mConst.group(1)!);
        continue;
      }
      return null;
    }
    return (vars: vars, coeffs: coeffs, constant: constant);
  }

  /// Strip the `Exception:` prefix and any stack-trace noise so the
  /// UI shows a clean one-line error.
  /// Flatten the parsed `noOverlap` / `cumulative` groups into a
  /// single list of `GanttTaskSpec`s for the result. Group indices
  /// are unique per call so the renderer can lay out one lane per
  /// scheduling line.
  static List<GanttTaskSpec> _buildGanttTasks(
    List<NoOverlapGroup> noOverlap,
    List<CumulativeGroup> cumulative,
  ) {
    final out = <GanttTaskSpec>[];
    var groupIdx = 0;
    for (final g in noOverlap) {
      for (var i = 0; i < g.starts.length; i++) {
        out.add(GanttTaskSpec(
          startVar: g.starts[i],
          duration: g.durations[i],
          groupIndex: groupIdx,
        ));
      }
      groupIdx++;
    }
    for (final g in cumulative) {
      for (var i = 0; i < g.starts.length; i++) {
        out.add(GanttTaskSpec(
          startVar: g.starts[i],
          duration: g.durations[i],
          demand: g.demands[i],
          groupIndex: groupIdx,
        ));
      }
      groupIdx++;
    }
    return out;
  }

  /// First cumulative capacity seen — surface it so the renderer can
  /// draw the capacity line. Null when only `noOverlap` is in play.
  static int? _firstCapacity(List<CumulativeGroup> cumulative) {
    return cumulative.isEmpty ? null : cumulative.first.capacity;
  }

  static String _friendlyError(Object e) {
    final s = e.toString();
    return s.replaceAll(RegExp(r'^Exception:\s*'), '').split('\n').first;
  }

  // === CSP Round C — generic constraint mini-DSL ==========================

  /// Round 68 / extended round 74: parses a small line-based DSL
  /// and solves it. Grammar:
  ///
  /// ```
  /// # comments start with '#', blank lines ignored
  /// vars: x, y, z in 1..9
  /// allDifferent(x, y, z)
  /// x + y + z == 15
  /// noOverlap(s1=4, s2=3)               # single-resource scheduling
  /// cumulative(s1=2@2, s2=3@1; capacity=2)
  /// minimize x + y      # or `maximize <linear-expr>` — at most one
  /// ```
  ///
  /// `vars:` lines accept comma-separated variable names + an
  /// inclusive `lo..hi` integer range. Multiple `vars:` lines are
  /// allowed. `allDifferent(...)` is expanded to pairwise `!=`
  /// constraints (small N — typical CSP examples have ≤ 10 vars).
  /// `minimize` / `maximize` take a linear expression in the declared
  /// variables and route to dart_csp's branch-and-bound; only one
  /// objective per program (specifying both, or one twice, is an
  /// error). With no objective the result is the enumeration of
  /// all solutions; with an objective the result holds the single
  /// optimal assignment plus its objective value.
  /// Anything else is fed to the existing dart_csp string-constraint
  /// parser / `addLinear*` router via [solveDiophantine].
  static Future<DiophantineResult> solveDsl(String input,
      {int maxSolutions = 100}) async {
    final vars = <String, ({int min, int max})>{};
    final constraints = <String>[];
    final noOverlap = <NoOverlapGroup>[];
    final cumulative = <CumulativeGroup>[];
    ({String op, String expr, int lineNum})? objective;

    final lines = input.split('\n');
    for (var lineNum = 0; lineNum < lines.length; lineNum++) {
      var line = lines[lineNum].trim();
      // Strip trailing '#' comments.
      final hash = line.indexOf('#');
      if (hash >= 0) line = line.substring(0, hash).trim();
      if (line.isEmpty) continue;

      // Objective directive (round 74). Checked before the variable
      // and allDifferent matchers so a stray `minimize` keyword
      // can't be silently swallowed by the constraint fallback.
      final optMatch = RegExp(r'^(minimize|maximize)\s+(.+)$').firstMatch(line);
      if (optMatch != null) {
        if (objective != null) {
          return DiophantineResult.failure(
              'Line ${lineNum + 1}: only one minimize/maximize allowed '
              '(first one was on line ${objective.lineNum + 1}).');
        }
        objective = (
          op: optMatch.group(1)!,
          expr: optMatch.group(2)!.trim(),
          lineNum: lineNum,
        );
        continue;
      }

      // Variable declaration.
      final varsMatch =
          RegExp(r'^vars\s*:\s*(.+?)\s+in\s+(-?\d+)\s*\.\.\s*(-?\d+)$')
              .firstMatch(line);
      if (varsMatch != null) {
        final names = varsMatch
            .group(1)!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final lo = int.parse(varsMatch.group(2)!);
        final hi = int.parse(varsMatch.group(3)!);
        if (names.isEmpty) {
          return DiophantineResult.failure(
              'Line ${lineNum + 1}: vars: declared no names.');
        }
        for (final name in names) {
          if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name)) {
            return DiophantineResult.failure(
                'Line ${lineNum + 1}: invalid variable name "$name".');
          }
          if (vars.containsKey(name)) {
            return DiophantineResult.failure(
                'Line ${lineNum + 1}: variable "$name" already declared.');
          }
          vars[name] = (min: lo, max: hi);
        }
        continue;
      }

      // allDifferent expansion to pairwise !=.
      final allDiffMatch =
          RegExp(r'^allDifferent\s*\(\s*([^)]*)\s*\)$').firstMatch(line);
      if (allDiffMatch != null) {
        final names = allDiffMatch
            .group(1)!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (names.length < 2) {
          return DiophantineResult.failure(
              'Line ${lineNum + 1}: allDifferent needs ≥ 2 variables.');
        }
        for (var i = 0; i < names.length; i++) {
          for (var j = i + 1; j < names.length; j++) {
            constraints.add('${names[i]} != ${names[j]}');
          }
        }
        continue;
      }

      // Round 77: scheduling overlay.
      //
      //   noOverlap(s1=4, s2=3, s3=2)
      //
      // Each `name=int` pair describes a task: `name` is a
      // previously-declared start variable, `int` is its constant
      // duration. The half-open intervals
      // `[name, name + duration)` must be pairwise disjoint —
      // single-machine / single-resource scheduling.
      //
      // We validate names against [vars] (must be declared first)
      // and durations as non-negative integers; the rest is left
      // to dart_csp's `addNoOverlap` itself.
      final noOverlapMatch =
          RegExp(r'^noOverlap\s*\(\s*([^)]*)\s*\)$').firstMatch(line);
      if (noOverlapMatch != null) {
        final inner = noOverlapMatch.group(1)!.trim();
        if (inner.isEmpty) {
          return DiophantineResult.failure(
              'Line ${lineNum + 1}: noOverlap needs at least one '
              'task pair `name=duration`.');
        }
        final starts = <String>[];
        final durations = <int>[];
        for (final raw in inner.split(',')) {
          final pair = raw.trim();
          final m = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(-?\d+)$')
              .firstMatch(pair);
          if (m == null) {
            return DiophantineResult.failure(
                'Line ${lineNum + 1}: noOverlap pair "$pair" — '
                'expected `name=integer`.');
          }
          final name = m.group(1)!;
          final dur = int.parse(m.group(2)!);
          if (!vars.containsKey(name)) {
            return DiophantineResult.failure(
                'Line ${lineNum + 1}: noOverlap references undeclared '
                'variable "$name".');
          }
          if (dur < 0) {
            return DiophantineResult.failure(
                'Line ${lineNum + 1}: noOverlap duration for "$name" '
                'must be non-negative (got $dur).');
          }
          starts.add(name);
          durations.add(dur);
        }
        noOverlap.add((starts: starts, durations: durations));
        continue;
      }

      // Round 80: renewable-resource scheduling overlay.
      //
      //   cumulative(s1=4@2, s2=3@1, s3=5@3; capacity=3)
      //
      // The body splits on `;` into (i) a comma-separated task list
      // and (ii) a single `capacity=N` clause. Each task pair is
      // `name=duration@demand` where `name` is a previously-declared
      // start variable, `duration` is the constant length of the
      // task's half-open interval, and `demand` is the per-unit-time
      // resource consumption. Routes to dart_csp's `addCumulative`.
      final cumulativeMatch =
          RegExp(r'^cumulative\s*\(\s*([^)]*)\s*\)$').firstMatch(line);
      if (cumulativeMatch != null) {
        final inner = cumulativeMatch.group(1)!.trim();
        final parts = inner.split(';');
        if (parts.length != 2) {
          return DiophantineResult.failure(
              'Line ${lineNum + 1}: cumulative expects `tasks; capacity=N` '
              '(found ${parts.length} `;`-separated segments).');
        }
        final taskList = parts[0].trim();
        final capacityClause = parts[1].trim();
        final capMatch =
            RegExp(r'^capacity\s*=\s*(-?\d+)$').firstMatch(capacityClause);
        if (capMatch == null) {
          return DiophantineResult.failure(
              'Line ${lineNum + 1}: cumulative — expected `capacity=N`, '
              'got "$capacityClause".');
        }
        final capacity = int.parse(capMatch.group(1)!);
        if (capacity < 0) {
          return DiophantineResult.failure(
              'Line ${lineNum + 1}: cumulative capacity must be '
              'non-negative (got $capacity).');
        }
        if (taskList.isEmpty) {
          return DiophantineResult.failure(
              'Line ${lineNum + 1}: cumulative needs at least one task '
              'pair `name=duration@demand`.');
        }
        final starts = <String>[];
        final durations = <int>[];
        final demands = <int>[];
        for (final raw in taskList.split(',')) {
          final pair = raw.trim();
          final m =
              RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(-?\d+)\s*@\s*(-?\d+)$')
                  .firstMatch(pair);
          if (m == null) {
            return DiophantineResult.failure(
                'Line ${lineNum + 1}: cumulative pair "$pair" — '
                'expected `name=duration@demand`.');
          }
          final name = m.group(1)!;
          final dur = int.parse(m.group(2)!);
          final dem = int.parse(m.group(3)!);
          if (!vars.containsKey(name)) {
            return DiophantineResult.failure(
                'Line ${lineNum + 1}: cumulative references undeclared '
                'variable "$name".');
          }
          if (dur < 0) {
            return DiophantineResult.failure(
                'Line ${lineNum + 1}: cumulative duration for "$name" '
                'must be non-negative (got $dur).');
          }
          if (dem < 0) {
            return DiophantineResult.failure(
                'Line ${lineNum + 1}: cumulative demand for "$name" '
                'must be non-negative (got $dem).');
          }
          starts.add(name);
          durations.add(dur);
          demands.add(dem);
        }
        cumulative.add((
          starts: starts,
          durations: durations,
          demands: demands,
          capacity: capacity,
        ));
        continue;
      }

      // Anything else is a constraint.
      constraints.add(line);
    }

    if (vars.isEmpty) {
      return DiophantineResult.failure(
          'No variables declared. Use `vars: x, y in 1..9`.');
    }

    if (objective != null) {
      return solveOptimization(
        variables: vars,
        constraints: constraints,
        minimize: objective.op == 'minimize',
        objectiveExpr: objective.expr,
        noOverlap: noOverlap,
        cumulative: cumulative,
      );
    }

    return solveDiophantine(
      variables: vars,
      constraints: constraints,
      noOverlap: noOverlap,
      cumulative: cumulative,
      maxSolutions: maxSolutions,
    );
  }

  /// Round 74: route a linear minimization / maximization through
  /// dart_csp's branch-and-bound. Models the objective as a synthetic
  /// `__obj__` variable bound to `Σ coef_i · var_i` via
  /// [csp.Problem.addLinearEquals]; the synthetic variable gets a
  /// tight integer range derived from the input variable ranges so
  /// dart_csp can use its interval domain rep (no billion-element
  /// list).
  ///
  /// Returns [DiophantineResult.optimal] with the single proven
  /// optimal assignment on success, or `.failure` with a parse /
  /// solver message on error. Returns "no assignment satisfies the
  /// constraints" rather than `.optimal([], …)` when infeasible so
  /// the [_ResultBlock] UI's empty-list branch never lights up for
  /// optimization mode.
  ///
  /// Limitations: only linear objectives in the declared variables.
  /// Non-linear objectives (`x*y`, `x^2`) are rejected at parse time.
  static Future<DiophantineResult> solveOptimization({
    required Map<String, ({int min, int max})> variables,
    required List<String> constraints,
    required bool minimize,
    required String objectiveExpr,
    List<NoOverlapGroup> noOverlap = const [],
    List<CumulativeGroup> cumulative = const [],
  }) async {
    if (variables.isEmpty) {
      return DiophantineResult.failure('No variables declared.');
    }
    final knownVars = variables.keys.toSet();
    final parsed = _parseLinearTerms(objectiveExpr, knownVars);
    if (parsed == null || parsed.vars.isEmpty) {
      return DiophantineResult.failure(
          'Could not parse ${minimize ? 'minimize' : 'maximize'} '
          'expression "$objectiveExpr" — only linear expressions in '
          'the declared variables are supported.');
    }
    final objConst = parsed.constant.toInt();
    // Tight bounds on Σ coef_i · var_i + constant. For each term, the
    // min contribution is coef * varLo when coef ≥ 0 else coef * varHi
    // (symmetric for max). Sum independently, then fold in the
    // constant offset so __obj__'s domain matches the user-visible
    // objective value.
    var objLo = objConst;
    var objHi = objConst;
    for (var i = 0; i < parsed.vars.length; i++) {
      final coef = parsed.coeffs[i].toInt();
      final range = variables[parsed.vars[i]]!;
      final a = coef * range.min;
      final b = coef * range.max;
      objLo += a < b ? a : b;
      objHi += a < b ? b : a;
    }
    const objVar = '__obj__';
    if (knownVars.contains(objVar)) {
      return DiophantineResult.failure(
          'Variable name "$objVar" is reserved for the objective '
          '— rename it in your `vars:` declaration.');
    }

    final problem = csp.Problem();
    try {
      for (final entry in variables.entries) {
        final (min: lo, max: hi) = entry.value;
        if (hi < lo) {
          return DiophantineResult.failure(
              'Variable ${entry.key}: range max ($hi) < min ($lo).');
        }
        if (hi - lo > 10000) {
          return DiophantineResult.failure(
              'Variable ${entry.key}: range too large (max−min > 10000).');
        }
        problem.addRangeVariable(entry.key, lo, hi);
      }
      problem.addRangeVariable(objVar, objLo, objHi);
      // Bind __obj__ = Σ coef_i · var_i + constant.
      // Move __obj__ to the LHS as `-1·__obj__` and the constant to
      // the RHS bound: Σ coef_i·var_i − __obj__ == −constant.
      problem.addLinearEquals(
        [...parsed.vars, objVar],
        [...parsed.coeffs, -1],
        -objConst,
      );
      for (final c in constraints) {
        final linear = _tryParseLinear(c, knownVars);
        if (linear != null) {
          final (:vars, :coeffs, :op, :bound) = linear;
          switch (op) {
            case '==':
              problem.addLinearEquals(vars, coeffs, bound);
              break;
            case '<=':
              problem.addLinearLeq(vars, coeffs, bound);
              break;
            case '>=':
              problem.addLinearGeq(vars, coeffs, bound);
              break;
            case '<':
              problem.addLinearLeq(vars, coeffs, bound - 1);
              break;
            case '>':
              problem.addLinearGeq(vars, coeffs, bound + 1);
              break;
          }
          continue;
        }
        problem.addStringConstraint(c);
      }
      for (final group in noOverlap) {
        problem.addNoOverlap(group.starts, group.durations);
      }
      for (final group in cumulative) {
        problem.addCumulative(
          group.starts,
          group.durations,
          group.demands,
          group.capacity,
        );
      }
    } catch (e) {
      return DiophantineResult.failure(
          'Failed to parse constraints: ${_friendlyError(e)}');
    }

    try {
      final result = minimize
          ? await problem.minimize(objVar)
          : await problem.maximize(objVar);
      if (result is! Map<String, dynamic>) {
        return DiophantineResult.failure(
            'No assignment satisfies the constraints.');
      }
      final objValue = (result[objVar] as num).toInt();
      final assignment = <String, int>{
        for (final entry in result.entries)
          if (entry.key != objVar) entry.key: (entry.value as num).toInt(),
      };
      return DiophantineResult.optimal(
        assignment,
        objValue,
        ganttTasks: _buildGanttTasks(noOverlap, cumulative),
        ganttCapacity: _firstCapacity(cumulative),
      );
    } catch (e) {
      return DiophantineResult.failure(
          'Optimizer failed: ${_friendlyError(e)}');
    }
  }

  // === Round E.2 — QuickXplain MUS explanation ============================

  /// Re-build the Diophantine model with `label:` threaded through
  /// every `add*` call, then ask dart_csp's QuickXplain pass for a
  /// minimal-unsatisfiable subset.
  ///
  /// Mirrors the argument shape of [solveDiophantine] so the UI can
  /// call this with the same inputs the user already submitted. Has
  /// no shared state with the original solve — that solve's Problem
  /// is long gone by the time the user clicks Explain, and rebuilding
  /// is cheap for problems at this scale (CSP homework size).
  ///
  /// The label format mirrors the input's structure:
  ///   - User-supplied string constraints → `C${i+1}: <text>`.
  ///   - `noOverlap` overlays → `noOverlap #${k}`.
  ///   - `cumulative` overlays → `cumulative #${k}`.
  ///
  /// Returns `CspMusResult.satisfiable()` when QuickXplain reports
  /// no MUS (i.e. the model is satisfiable — e.g. the caller hit
  /// `maxSolutions` and only thought it was unsat).
  static Future<CspMusResult> explainDiophantine({
    required Map<String, ({int min, int max})> variables,
    required List<String> constraints,
    List<NoOverlapGroup> noOverlap = const [],
    List<CumulativeGroup> cumulative = const [],
  }) async {
    if (variables.isEmpty) {
      return CspMusResult.failure('No variables declared.');
    }
    final problem = csp.Problem();
    try {
      for (final entry in variables.entries) {
        final (min: lo, max: hi) = entry.value;
        if (hi < lo) {
          return CspMusResult.failure(
              'Variable ${entry.key}: range max ($hi) < min ($lo).');
        }
        problem.addRangeVariable(entry.key, lo, hi);
      }
      final knownVars = variables.keys.toSet();
      for (var i = 0; i < constraints.length; i++) {
        final c = constraints[i];
        final label = 'C${i + 1}: $c';
        final linear = _tryParseLinear(c, knownVars);
        if (linear != null) {
          final (:vars, :coeffs, :op, :bound) = linear;
          switch (op) {
            case '==':
              problem.addLinearEquals(vars, coeffs, bound, label: label);
              break;
            case '<=':
              problem.addLinearLeq(vars, coeffs, bound, label: label);
              break;
            case '>=':
              problem.addLinearGeq(vars, coeffs, bound, label: label);
              break;
            case '<':
              problem.addLinearLeq(vars, coeffs, bound - 1, label: label);
              break;
            case '>':
              problem.addLinearGeq(vars, coeffs, bound + 1, label: label);
              break;
          }
          continue;
        }
        problem.addStringConstraint(c, label: label);
      }
      for (var k = 0; k < noOverlap.length; k++) {
        final g = noOverlap[k];
        problem.addNoOverlap(g.starts, g.durations,
            label: 'noOverlap #${k + 1}');
      }
      for (var k = 0; k < cumulative.length; k++) {
        final g = cumulative[k];
        problem.addCumulative(g.starts, g.durations, g.demands, g.capacity,
            label: 'cumulative #${k + 1}');
      }
    } catch (e) {
      return CspMusResult.failure(
          'Failed to build the constraint model: ${_friendlyError(e)}');
    }

    return _runQuickXplain(problem);
  }

  /// Same shape as [explainDiophantine] but for the DSL. Re-parses
  /// the source, labels each constraint by the originating DSL line,
  /// then runs QuickXplain. `allDifferent(...)` lines expand to
  /// pairwise `!=` constraints that all share one DSL-source label
  /// so the MUS reads `allDifferent(x, y, z)` once even when the
  /// conflict touches several of the pairwise refs.
  static Future<CspMusResult> explainDsl(String input) async {
    final parsed = _parseDslForExplain(input);
    if (parsed.error != null) return CspMusResult.failure(parsed.error!);
    final problem = csp.Problem();
    try {
      for (final entry in parsed.variables.entries) {
        final (min: lo, max: hi) = entry.value;
        problem.addRangeVariable(entry.key, lo, hi);
      }
      final knownVars = parsed.variables.keys.toSet();
      for (final c in parsed.constraints) {
        final label = c.label;
        final linear = _tryParseLinear(c.text, knownVars);
        if (linear != null) {
          final (:vars, :coeffs, :op, :bound) = linear;
          switch (op) {
            case '==':
              problem.addLinearEquals(vars, coeffs, bound, label: label);
              break;
            case '<=':
              problem.addLinearLeq(vars, coeffs, bound, label: label);
              break;
            case '>=':
              problem.addLinearGeq(vars, coeffs, bound, label: label);
              break;
            case '<':
              problem.addLinearLeq(vars, coeffs, bound - 1, label: label);
              break;
            case '>':
              problem.addLinearGeq(vars, coeffs, bound + 1, label: label);
              break;
          }
          continue;
        }
        problem.addStringConstraint(c.text, label: label);
      }
      for (var k = 0; k < parsed.noOverlap.length; k++) {
        final g = parsed.noOverlap[k];
        problem.addNoOverlap(g.starts, g.durations,
            label: 'noOverlap #${k + 1}');
      }
      for (var k = 0; k < parsed.cumulative.length; k++) {
        final g = parsed.cumulative[k];
        problem.addCumulative(g.starts, g.durations, g.demands, g.capacity,
            label: 'cumulative #${k + 1}');
      }
    } catch (e) {
      return CspMusResult.failure(
          'Failed to build the constraint model: ${_friendlyError(e)}');
    }
    return _runQuickXplain(problem);
  }

  /// Cryptarithm-shaped MUS. Re-parses the puzzle and rebuilds the
  /// model with three label families: `'allDifferent letters'`,
  /// `'no leading zero on $WORD'` (one per multi-letter word), and
  /// `'digit-place equality'` (the single linear equation that ties
  /// the words together).
  static Future<CspMusResult> explainCryptarithm(String expression) async {
    final parsed = _parseCryptarithmExpression(expression);
    if (parsed == null) {
      return CspMusResult.failure(
          'Expected `WORD1 + WORD2 = WORD3` (only + / - supported).');
    }
    final (:lhsA, :op, :lhsB, :rhs) = parsed;
    final words = [lhsA, lhsB, rhs];
    final letters = <String>{
      for (final w in words)
        for (final ch in w.split('')) ch,
    }.toList();
    if (letters.length > 10) {
      return CspMusResult.failure(
          'Cryptarithm has ${letters.length} distinct letters; '
          'at most 10 fit into digits 0..9.');
    }
    final problem = csp.Problem();
    for (final l in letters) {
      problem.addVariable(l, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    }
    problem.addAllDifferent(letters, label: 'allDifferent letters');
    for (final w in words) {
      if (w.length > 1) {
        problem.addStringConstraint('${w[0]} != 0',
            label: 'no leading zero on $w');
      }
    }
    final coefs = <String, int>{};
    void accumulate(String word, int sign) {
      for (var i = 0; i < word.length; i++) {
        final letter = word[i];
        final place = _intPow(10, word.length - 1 - i);
        coefs[letter] = (coefs[letter] ?? 0) + sign * place;
      }
    }

    accumulate(lhsA, 1);
    accumulate(lhsB, op == '-' ? -1 : 1);
    accumulate(rhs, -1);
    final orderedLetters = <String>[];
    final orderedCoeffs = <num>[];
    for (final entry in coefs.entries) {
      if (entry.value == 0) continue;
      orderedLetters.add(entry.key);
      orderedCoeffs.add(entry.value);
    }
    problem.addLinearEquals(orderedLetters, orderedCoeffs, 0,
        label: 'digit-place equality');
    return _runQuickXplain(problem);
  }

  /// FlatZinc MUS. Builds the model through dart_csp's FlatZinc
  /// frontend, then runs QuickXplain. The FlatZinc lowering doesn't
  /// (yet) thread user-supplied labels through, so the returned
  /// [MusEntry.label] is derived from `kind(vars)` — still useful
  /// for the user to localize the conflict to specific constraint
  /// kinds + variable scopes.
  static Future<CspMusResult> explainFlatZinc(String source) async {
    csp.LoweredModel lowered;
    try {
      lowered = csp.FlatZinc.build(source);
    } catch (e) {
      return CspMusResult.failure(
          'Failed to parse FlatZinc: ${_friendlyError(e)}');
    }
    return _runQuickXplain(lowered.problem);
  }

  /// Round F — propagation step-trace for the DSL tab. Rebuilds the
  /// program as a *labeled* Problem (identically to [explainDsl], so
  /// every prune cause reads as the originating DSL line) and runs
  /// dart_csp 2.2.0's `solveWithTrace`, then projects the raw
  /// `PropagationEvent` stream into [CspTraceStep]s — each carrying a
  /// full post-step domain snapshot reconstructed via a backtracking
  /// trail, so the visualizer renders state by simple indexing.
  ///
  /// `minimize` / `maximize` directives are ignored (the same as the
  /// explain pass): the trace visualizes the feasibility search over
  /// the constraint set, which is where the AC-3 pedagogy lives.
  ///
  /// [maxEvents] bounds the captured trace (and so the underlying
  /// solve); the default keeps even a pathological program responsive.
  /// A capped trace sets [CspTraceResult.truncated].
  static Future<CspTraceResult> traceDsl(String input,
      {int maxEvents = 20000}) async {
    final parsed = _parseDslForExplain(input);
    if (parsed.error != null) {
      return CspTraceResult.failure(parsed.error!);
    }
    if (parsed.variables.isEmpty) {
      return CspTraceResult.unsupportedProgram('No variables declared.');
    }

    // Declared-order variable list + full initial domains.
    final variables = parsed.variables.keys.toList();
    final initialDomains = <String, List<int>>{
      for (final e in parsed.variables.entries)
        e.key: [for (var v = e.value.min; v <= e.value.max; v++) v],
    };

    final problem = csp.Problem();
    try {
      for (final entry in parsed.variables.entries) {
        problem.addRangeVariable(entry.key, entry.value.min, entry.value.max);
      }
      final knownVars = parsed.variables.keys.toSet();
      for (final c in parsed.constraints) {
        final label = c.label;
        final linear = _tryParseLinear(c.text, knownVars);
        if (linear != null) {
          final (:vars, :coeffs, :op, :bound) = linear;
          switch (op) {
            case '==':
              problem.addLinearEquals(vars, coeffs, bound, label: label);
              break;
            case '<=':
              problem.addLinearLeq(vars, coeffs, bound, label: label);
              break;
            case '>=':
              problem.addLinearGeq(vars, coeffs, bound, label: label);
              break;
            case '<':
              problem.addLinearLeq(vars, coeffs, bound - 1, label: label);
              break;
            case '>':
              problem.addLinearGeq(vars, coeffs, bound + 1, label: label);
              break;
          }
          continue;
        }
        problem.addStringConstraint(c.text, label: label);
      }
      for (var k = 0; k < parsed.noOverlap.length; k++) {
        final g = parsed.noOverlap[k];
        problem.addNoOverlap(g.starts, g.durations,
            label: 'noOverlap #${k + 1}');
      }
      for (var k = 0; k < parsed.cumulative.length; k++) {
        final g = parsed.cumulative[k];
        problem.addCumulative(g.starts, g.durations, g.demands, g.capacity,
            label: 'cumulative #${k + 1}');
      }
    } catch (e) {
      return CspTraceResult.failure(
          'Failed to build the constraint model: ${_friendlyError(e)}');
    }

    csp.PropagationTrace trace;
    try {
      trace = await problem.solveWithTrace(maxEvents: maxEvents);
    } catch (e) {
      return CspTraceResult.failure('Trace failed: ${_friendlyError(e)}');
    }

    final steps =
        _reconstructTraceSteps(trace.events, variables, initialDomains);
    final solved = trace.result is Map;
    final solution = solved
        ? <String, int>{
            for (final e in (trace.result as Map).entries)
              e.key as String: (e.value as num).toInt(),
          }
        : null;

    return CspTraceResult.ok(
      variables: variables,
      initialDomains: initialDomains,
      steps: steps,
      solved: solved,
      solution: solution,
      truncated: trace.truncated,
      objectiveIgnored:
          RegExp(r'(^|\n)\s*(minimize|maximize)\s+').hasMatch(input),
    );
  }

  /// Replays the raw `PropagationEvent` stream into [CspTraceStep]s,
  /// attaching a full domain snapshot after each step. A backtracking
  /// trail makes the snapshots faithful across dead-ends:
  ///
  ///   * `decision`/`prune`/`wipeout` mutate the live domain map; each
  ///     mutation pushes the prior domain onto the current decision
  ///     frame so it can be undone.
  ///   * prunes emitted *before* the first decision are root-level
  ///     propagation — permanent, recorded on no frame.
  ///   * `backtrack @dD` pops the top decision frame, restoring every
  ///     domain it captured (back to the pre-decision-D state). This
  ///     matches dart_csp's observed semantics (a backtrack at depth D
  ///     undoes the decision made at depth D and its consequences).
  ///   * `backjump @dD->tD` pops frames down to level tD.
  static List<CspTraceStep> _reconstructTraceSteps(
    List<csp.PropagationEvent> events,
    List<String> variables,
    Map<String, List<int>> initialDomains,
  ) {
    // Live, mutable domain state (copy of the initial domains).
    final domains = <String, List<int>>{
      for (final e in initialDomains.entries) e.key: List<int>.of(e.value),
    };
    // One frame per active decision level; each frame is the ordered
    // list of (variable, priorDomain) undo records to replay on pop.
    final trail = <List<(String, List<int>)>>[];

    List<int> ints(List<dynamic>? xs) =>
        [for (final x in (xs ?? const [])) (x as num).toInt()];

    Map<String, List<int>> snapshot() => {
          for (final e in domains.entries) e.key: List<int>.of(e.value),
        };

    final steps = <CspTraceStep>[];
    for (final e in events) {
      switch (e.kind) {
        case csp.PropagationEventKind.decision:
          final v = e.variable!;
          final val = (e.value as num).toInt();
          // Open a new decision frame and record the pinned var's
          // prior domain so a backtrack restores it.
          trail.add([(v, List<int>.of(domains[v] ?? const []))]);
          domains[v] = [val];
          steps.add(CspTraceStep(
            seq: e.seq,
            kind: CspTraceStepKind.decision,
            variable: v,
            value: val,
            depth: e.depth,
            domains: snapshot(),
          ));
          break;
        case csp.PropagationEventKind.prune:
        case csp.PropagationEventKind.domainWipeout:
          final v = e.variable!;
          final after = ints(e.domainAfter);
          // Record undo on the current frame (root prunes -> none).
          if (trail.isNotEmpty) {
            trail.last.add((v, List<int>.of(domains[v] ?? const [])));
          }
          domains[v] = after;
          steps.add(CspTraceStep(
            seq: e.seq,
            kind: e.kind == csp.PropagationEventKind.prune
                ? CspTraceStepKind.prune
                : CspTraceStepKind.wipeout,
            variable: v,
            removedValues: ints(e.removedValues),
            domainBefore: ints(e.domainBefore),
            domainAfter: after,
            causeKind: e.causeKind,
            causeLabel: e.causeLabel,
            causeScope: List<String>.of(e.causeScope ?? const []),
            domains: snapshot(),
          ));
          break;
        case csp.PropagationEventKind.backtrack:
          if (trail.isNotEmpty) {
            for (final (v, prior) in trail.removeLast().reversed) {
              domains[v] = List<int>.of(prior);
            }
          }
          steps.add(CspTraceStep(
            seq: e.seq,
            kind: CspTraceStepKind.backtrack,
            depth: e.depth,
            domains: snapshot(),
          ));
          break;
        case csp.PropagationEventKind.backjump:
          final target = e.targetDepth ?? 0;
          while (trail.length > target) {
            for (final (v, prior) in trail.removeLast().reversed) {
              domains[v] = List<int>.of(prior);
            }
          }
          steps.add(CspTraceStep(
            seq: e.seq,
            kind: CspTraceStepKind.backjump,
            depth: e.depth,
            targetDepth: e.targetDepth,
            domains: snapshot(),
          ));
          break;
        case csp.PropagationEventKind.solution:
          final assign = <String, int>{
            for (final me in (e.assignment ?? const {}).entries)
              me.key: (me.value as num).toInt(),
          };
          // Pin the snapshot to the solution's singletons.
          for (final me in assign.entries) {
            domains[me.key] = [me.value];
          }
          steps.add(CspTraceStep(
            seq: e.seq,
            kind: CspTraceStepKind.solution,
            assignment: assign,
            domains: snapshot(),
          ));
          break;
      }
    }
    return steps;
  }

  /// Shared QuickXplain runner. Catches engine errors, translates
  /// the dart_csp `ConstraintRef` list into our UI-facing
  /// [MusEntry] shape (deriving a label from `kind(vars)` when the
  /// ref has none), and folds the satisfiable-after-all case into
  /// [CspMusResult.satisfiable].
  static Future<CspMusResult> _runQuickXplain(csp.Problem problem) async {
    try {
      final mus = await problem.findMinimalUnsatisfiableSubsetQuickXplain();
      if (mus == null) {
        // dart_csp returns null when the problem is satisfiable
        // (no MUS exists) — the user clicked Explain on a flaky
        // unsat or on a result that was capped at maxSolutions.
        return CspMusResult.satisfiable();
      }
      // Deduplicate by ref.id so a binary constraint's forward +
      // reverse arcs don't double-list. (dart_csp already does
      // this; belt-and-suspenders against future refactors.)
      final seen = <String>{};
      final entries = <MusEntry>[];
      for (final ref in mus) {
        if (!seen.add(ref.id)) continue;
        entries.add(MusEntry(
          label: ref.label ?? '${ref.kind}(${ref.variables.join(', ')})',
          kind: ref.kind,
          variables: List<String>.unmodifiable(ref.variables),
        ));
      }
      return CspMusResult.ok(entries);
    } catch (e) {
      return CspMusResult.failure('QuickXplain failed: ${_friendlyError(e)}');
    }
  }

  /// Re-parses a DSL source for the MUS path. Returns a struct
  /// carrying [variables], a list of `(text, label)` constraints,
  /// and the scheduling overlays — exactly what `_runQuickXplain`
  /// needs to rebuild a labeled Problem. Synthesizes labels from
  /// the source line + the DSL keyword (`allDifferent` lines
  /// produce one shared label across all pairwise expansions).
  /// Parse errors live in [error]; everything else is unset when
  /// [error] is non-null.
  static _DslExplainParse _parseDslForExplain(String input) {
    final vars = <String, ({int min, int max})>{};
    final constraintEntries = <_LabeledConstraint>[];
    final noOverlap = <NoOverlapGroup>[];
    final cumulative = <CumulativeGroup>[];
    // The DSL doesn't have an explain-time objective notion — the
    // synthetic __obj__ binding isn't a "real" constraint and
    // there's no value in including it in a MUS. The original
    // optimization path also folds the objective into __obj__ so
    // the existing happy-path code can't be reused cleanly; the
    // parser here intentionally ignores `minimize` / `maximize`.

    final lines = input.split('\n');
    for (var lineNum = 0; lineNum < lines.length; lineNum++) {
      var line = lines[lineNum].trim();
      final hash = line.indexOf('#');
      if (hash >= 0) line = line.substring(0, hash).trim();
      if (line.isEmpty) continue;

      // Skip minimize/maximize for the explain pass.
      if (RegExp(r'^(minimize|maximize)\s+').hasMatch(line)) continue;

      final varsMatch =
          RegExp(r'^vars\s*:\s*(.+?)\s+in\s+(-?\d+)\s*\.\.\s*(-?\d+)$')
              .firstMatch(line);
      if (varsMatch != null) {
        final names = varsMatch
            .group(1)!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final lo = int.parse(varsMatch.group(2)!);
        final hi = int.parse(varsMatch.group(3)!);
        for (final name in names) {
          vars[name] = (min: lo, max: hi);
        }
        continue;
      }

      final allDiffMatch =
          RegExp(r'^allDifferent\s*\(\s*([^)]*)\s*\)$').firstMatch(line);
      if (allDiffMatch != null) {
        final names = allDiffMatch
            .group(1)!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final groupLabel = 'allDifferent(${names.join(', ')})';
        for (var i = 0; i < names.length; i++) {
          for (var j = i + 1; j < names.length; j++) {
            constraintEntries.add(_LabeledConstraint(
              text: '${names[i]} != ${names[j]}',
              label: groupLabel,
            ));
          }
        }
        continue;
      }

      final noOverlapMatch =
          RegExp(r'^noOverlap\s*\(\s*([^)]*)\s*\)$').firstMatch(line);
      if (noOverlapMatch != null) {
        final inner = noOverlapMatch.group(1)!.trim();
        final starts = <String>[];
        final durations = <int>[];
        for (final raw in inner.split(',')) {
          final pair = raw.trim();
          final m = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(-?\d+)$')
              .firstMatch(pair);
          if (m == null) continue;
          starts.add(m.group(1)!);
          durations.add(int.parse(m.group(2)!));
        }
        if (starts.isNotEmpty) {
          noOverlap.add((starts: starts, durations: durations));
        }
        continue;
      }

      final cumulativeMatch =
          RegExp(r'^cumulative\s*\(\s*([^)]*)\s*\)$').firstMatch(line);
      if (cumulativeMatch != null) {
        final inner = cumulativeMatch.group(1)!.trim();
        final parts = inner.split(';');
        if (parts.length == 2) {
          final taskList = parts[0].trim();
          final capacityClause = parts[1].trim();
          final capMatch =
              RegExp(r'^capacity\s*=\s*(-?\d+)$').firstMatch(capacityClause);
          if (capMatch != null) {
            final capacity = int.parse(capMatch.group(1)!);
            final starts = <String>[];
            final durations = <int>[];
            final demands = <int>[];
            for (final raw in taskList.split(',')) {
              final pair = raw.trim();
              final m = RegExp(
                      r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(-?\d+)\s*@\s*(-?\d+)$')
                  .firstMatch(pair);
              if (m == null) continue;
              starts.add(m.group(1)!);
              durations.add(int.parse(m.group(2)!));
              demands.add(int.parse(m.group(3)!));
            }
            if (starts.isNotEmpty) {
              cumulative.add((
                starts: starts,
                durations: durations,
                demands: demands,
                capacity: capacity,
              ));
            }
          }
        }
        continue;
      }

      constraintEntries.add(_LabeledConstraint(
        text: line,
        label: 'line ${lineNum + 1}: $line',
      ));
    }

    if (vars.isEmpty) {
      return _DslExplainParse._error('No variables declared in the DSL '
          'program. Use `vars: x, y in 1..9`.');
    }

    return _DslExplainParse._(
      variables: vars,
      constraints: constraintEntries,
      noOverlap: noOverlap,
      cumulative: cumulative,
      error: null,
    );
  }
}

class _LabeledConstraint {
  final String text;
  final String label;
  const _LabeledConstraint({required this.text, required this.label});
}

class _DslExplainParse {
  final Map<String, ({int min, int max})> variables;
  final List<_LabeledConstraint> constraints;
  final List<NoOverlapGroup> noOverlap;
  final List<CumulativeGroup> cumulative;
  final String? error;

  const _DslExplainParse._({
    required this.variables,
    required this.constraints,
    required this.noOverlap,
    required this.cumulative,
    required this.error,
  });

  factory _DslExplainParse._error(String message) => _DslExplainParse._(
        variables: const {},
        constraints: const [],
        noOverlap: const [],
        cumulative: const [],
        error: message,
      );
}

/// Result of [CspSolver.exportDslToFlatZinc]. Either [source] holds
/// a ready-to-paste FlatZinc model or [error] explains why the DSL
/// couldn't be translated.
class FlatZincExportResult {
  final String? source;
  final String? error;
  bool get ok => source != null;
  const FlatZincExportResult._({this.source, this.error});
  factory FlatZincExportResult.ok(String src) =>
      FlatZincExportResult._(source: src);
  factory FlatZincExportResult.failure(String msg) =>
      FlatZincExportResult._(error: msg);
}

/// Round E.3 — DSL → FlatZinc transpiler.
///
/// Lifts the DSL's vars / allDifferent / linear constraints /
/// noOverlap / cumulative / minimize / maximize directives into the
/// standard FlatZinc subset every CP solver (Choco, Gecode,
/// OR-Tools, MiniZinc IDE) consumes. Output is plain text the user
/// can paste into another solver for cross-verification or to crack
/// problems CrispCalc's in-process search times out on.
///
/// Mapping (DSL → FlatZinc):
///   vars: x in 1..9             →  var 1..9: x :: output_var;
///   allDifferent(x, y, z)       →  constraint all_different_int([x, y, z]);
///   a*x + b*y == k              →  constraint int_lin_eq([a, b], [x, y], k);
///   a*x + b*y <= k              →  constraint int_lin_le([a, b], [x, y], k);
///   a*x + b*y >= k              →  constraint int_lin_le([-a, -b], [x, y], -k);
///   a*x + b*y < k               →  constraint int_lin_le([a, b], [x, y], k - 1);
///   a*x + b*y > k               →  constraint int_lin_le([-a, -b], [x, y], -(k + 1));
///   a*x + b*y != k              →  constraint int_lin_ne([a, b], [x, y], k);
///   noOverlap(s1=4, s2=3)       →  constraint disjunctive([s1, s2], [4, 3]);
///   cumulative(s1=2@2; cap=N)   →  constraint cumulative([s1], [2], [2], N);
///   minimize expr               →  var lo..hi: __obj__ :: output_var;
///                                  constraint int_lin_eq([..., -1], [vars..., __obj__], -const);
///                                  solve minimize __obj__;
///
/// Unsupported lines (free-form non-linear, `!=` with non-linear,
/// arithmetic in scheduling demands) cause a friendly error rather
/// than a partial / wrong FlatZinc model.
class DslToFlatZinc {
  static FlatZincExportResult export(String input) {
    final vars = <String, ({int min, int max})>{};
    final declOrder = <String>[];
    final allDifferentCalls = <List<String>>[];
    final linearConstraints = <_LinearFlatZinc>[];
    final noOverlapGroups = <NoOverlapGroup>[];
    final cumulativeGroups = <CumulativeGroup>[];
    ({String op, String expr, int lineNum})? objective;

    final lines = input.split('\n');
    for (var lineNum = 0; lineNum < lines.length; lineNum++) {
      var line = lines[lineNum].trim();
      final hash = line.indexOf('#');
      if (hash >= 0) line = line.substring(0, hash).trim();
      if (line.isEmpty) continue;

      final optMatch = RegExp(r'^(minimize|maximize)\s+(.+)$').firstMatch(line);
      if (optMatch != null) {
        if (objective != null) {
          return FlatZincExportResult.failure(
              'Line ${lineNum + 1}: only one minimize/maximize allowed.');
        }
        objective = (
          op: optMatch.group(1)!,
          expr: optMatch.group(2)!.trim(),
          lineNum: lineNum,
        );
        continue;
      }

      final varsMatch =
          RegExp(r'^vars\s*:\s*(.+?)\s+in\s+(-?\d+)\s*\.\.\s*(-?\d+)$')
              .firstMatch(line);
      if (varsMatch != null) {
        final names = varsMatch
            .group(1)!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final lo = int.parse(varsMatch.group(2)!);
        final hi = int.parse(varsMatch.group(3)!);
        if (hi < lo) {
          return FlatZincExportResult.failure(
              'Line ${lineNum + 1}: invalid range $lo..$hi.');
        }
        for (final name in names) {
          if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name)) {
            return FlatZincExportResult.failure(
                'Line ${lineNum + 1}: invalid variable name "$name".');
          }
          if (vars.containsKey(name)) {
            return FlatZincExportResult.failure(
                'Line ${lineNum + 1}: variable "$name" already declared.');
          }
          if (name == '__obj__') {
            return FlatZincExportResult.failure(
                'Line ${lineNum + 1}: "__obj__" is reserved for the '
                'objective variable on minimize/maximize.');
          }
          vars[name] = (min: lo, max: hi);
          declOrder.add(name);
        }
        continue;
      }

      final allDiffMatch =
          RegExp(r'^allDifferent\s*\(\s*([^)]*)\s*\)$').firstMatch(line);
      if (allDiffMatch != null) {
        final names = allDiffMatch
            .group(1)!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (names.length < 2) {
          return FlatZincExportResult.failure(
              'Line ${lineNum + 1}: allDifferent needs ≥ 2 variables.');
        }
        for (final n in names) {
          if (!vars.containsKey(n)) {
            return FlatZincExportResult.failure(
                'Line ${lineNum + 1}: allDifferent references undeclared '
                'variable "$n".');
          }
        }
        allDifferentCalls.add(names);
        continue;
      }

      final noOverlapMatch =
          RegExp(r'^noOverlap\s*\(\s*([^)]*)\s*\)$').firstMatch(line);
      if (noOverlapMatch != null) {
        final inner = noOverlapMatch.group(1)!.trim();
        final starts = <String>[];
        final durations = <int>[];
        for (final raw in inner.split(',')) {
          final pair = raw.trim();
          final m = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(-?\d+)$')
              .firstMatch(pair);
          if (m == null) {
            return FlatZincExportResult.failure(
                'Line ${lineNum + 1}: noOverlap pair "$pair" — expected '
                '`name=integer`.');
          }
          final name = m.group(1)!;
          if (!vars.containsKey(name)) {
            return FlatZincExportResult.failure(
                'Line ${lineNum + 1}: noOverlap references undeclared '
                'variable "$name".');
          }
          starts.add(name);
          durations.add(int.parse(m.group(2)!));
        }
        if (starts.isEmpty) {
          return FlatZincExportResult.failure(
              'Line ${lineNum + 1}: noOverlap needs at least one task.');
        }
        noOverlapGroups.add((starts: starts, durations: durations));
        continue;
      }

      final cumulativeMatch =
          RegExp(r'^cumulative\s*\(\s*([^)]*)\s*\)$').firstMatch(line);
      if (cumulativeMatch != null) {
        final inner = cumulativeMatch.group(1)!.trim();
        final parts = inner.split(';');
        if (parts.length != 2) {
          return FlatZincExportResult.failure(
              'Line ${lineNum + 1}: cumulative expects '
              '`tasks; capacity=N`.');
        }
        final capMatch =
            RegExp(r'^capacity\s*=\s*(-?\d+)$').firstMatch(parts[1].trim());
        if (capMatch == null) {
          return FlatZincExportResult.failure(
              'Line ${lineNum + 1}: cumulative — expected `capacity=N`.');
        }
        final capacity = int.parse(capMatch.group(1)!);
        final starts = <String>[];
        final durations = <int>[];
        final demands = <int>[];
        for (final raw in parts[0].trim().split(',')) {
          final pair = raw.trim();
          final m =
              RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(-?\d+)\s*@\s*(-?\d+)$')
                  .firstMatch(pair);
          if (m == null) {
            return FlatZincExportResult.failure(
                'Line ${lineNum + 1}: cumulative pair "$pair" — '
                'expected `name=duration@demand`.');
          }
          final name = m.group(1)!;
          if (!vars.containsKey(name)) {
            return FlatZincExportResult.failure(
                'Line ${lineNum + 1}: cumulative references undeclared '
                'variable "$name".');
          }
          starts.add(name);
          durations.add(int.parse(m.group(2)!));
          demands.add(int.parse(m.group(3)!));
        }
        if (starts.isEmpty) {
          return FlatZincExportResult.failure(
              'Line ${lineNum + 1}: cumulative needs at least one task.');
        }
        cumulativeGroups.add((
          starts: starts,
          durations: durations,
          demands: demands,
          capacity: capacity,
        ));
        continue;
      }

      // Anything else: must be a linear (in)equality. Reuse the
      // existing _tryParseLinear router via CspSolver. We support
      // ==/<=/>=/</>; `!=` falls through to int_lin_ne when both
      // sides parse as linear expressions.
      final knownVars = vars.keys.toSet();
      final neq = _tryParseLinearNe(line, knownVars);
      if (neq != null) {
        linearConstraints.add(_LinearFlatZinc(
            coeffs: neq.coeffs, vars: neq.vars, op: '!=', bound: neq.bound));
        continue;
      }
      final lin = CspSolver._tryParseLinear(line, knownVars);
      if (lin == null) {
        return FlatZincExportResult.failure(
            'Line ${lineNum + 1}: "$line" is not a linear constraint over '
            'the declared variables. Only `a*x + b*y op k` shapes '
            '(==/<=/>=/</>/!=) export to FlatZinc.');
      }
      linearConstraints.add(_LinearFlatZinc(
        coeffs: lin.coeffs,
        vars: lin.vars,
        op: lin.op,
        bound: lin.bound,
      ));
    }

    if (vars.isEmpty) {
      return FlatZincExportResult.failure(
          'No variables declared. Use `vars: x, y in 1..9`.');
    }

    final buf = StringBuffer();
    buf.writeln('% Generated from CrispCalc DSL — CSP Round E.3');
    buf.writeln('% Paste into Choco / Gecode / OR-Tools / MiniZinc IDE.');
    buf.writeln();

    for (final name in declOrder) {
      final (min: lo, max: hi) = vars[name]!;
      buf.writeln('var $lo..$hi: $name :: output_var;');
    }
    buf.writeln();

    for (final group in allDifferentCalls) {
      buf.writeln('constraint all_different_int([${group.join(', ')}]);');
    }
    for (final lc in linearConstraints) {
      buf.writeln(lc.toFlatZinc());
    }
    for (final g in noOverlapGroups) {
      buf.writeln('constraint disjunctive([${g.starts.join(', ')}], '
          '[${g.durations.join(', ')}]);');
    }
    for (final g in cumulativeGroups) {
      buf.writeln('constraint cumulative([${g.starts.join(', ')}], '
          '[${g.durations.join(', ')}], '
          '[${g.demands.join(', ')}], ${g.capacity});');
    }

    if (objective != null) {
      final knownVars = vars.keys.toSet();
      final parsed = CspSolver._parseLinearTerms(objective.expr, knownVars);
      if (parsed == null || parsed.vars.isEmpty) {
        return FlatZincExportResult.failure(
            'Line ${objective.lineNum + 1}: could not parse '
            '${objective.op} expression "${objective.expr}" — must be '
            'linear in the declared variables.');
      }
      // Tight bound on Σ coef·var + constant so __obj__ gets a real
      // domain. Mirrors CspSolver.solveOptimization.
      final objConst = parsed.constant.toInt();
      var objLo = objConst;
      var objHi = objConst;
      for (var i = 0; i < parsed.vars.length; i++) {
        final coef = parsed.coeffs[i].toInt();
        final range = vars[parsed.vars[i]]!;
        final a = coef * range.min;
        final b = coef * range.max;
        objLo += a < b ? a : b;
        objHi += a < b ? b : a;
      }
      buf.writeln();
      buf.writeln('var $objLo..$objHi: __obj__ :: output_var;');
      // Bind __obj__ = Σ coef·var + constant.
      //   ⇔ Σ coef·var − __obj__ == −constant
      final coeffs = [...parsed.coeffs.map((c) => c.toInt()), -1];
      final binds = [...parsed.vars, '__obj__'];
      buf.writeln('constraint int_lin_eq([${coeffs.join(', ')}], '
          '[${binds.join(', ')}], ${-objConst});');
      buf.writeln('solve ${objective.op} __obj__;');
    } else {
      buf.writeln();
      buf.writeln('solve satisfy;');
    }

    return FlatZincExportResult.ok(buf.toString());
  }

  /// Tiny shim for `!=` — splits on `!=` and reuses _parseLinearTerms
  /// on both sides. CspSolver._tryParseLinear deliberately declines
  /// `!=` so it stays on the dart_csp string-parser path, but for
  /// the FlatZinc export we want it as `int_lin_ne` instead.
  static ({List<String> vars, List<num> coeffs, num bound})? _tryParseLinearNe(
    String constraint,
    Set<String> knownVars,
  ) {
    final stripped = constraint.replaceAll(' ', '');
    final m = RegExp(r'^(.+?)!=(.+)$').firstMatch(stripped);
    if (m == null) return null;
    final lhs = CspSolver._parseLinearTerms(m.group(1)!, knownVars);
    final rhs = CspSolver._parseLinearTerms(m.group(2)!, knownVars);
    if (lhs == null || rhs == null) return null;
    final vars = <String>[...lhs.vars, ...rhs.vars];
    final coeffs = <num>[
      ...lhs.coeffs,
      for (final c in rhs.coeffs) -c,
    ];
    if (vars.isEmpty) return null;
    return (vars: vars, coeffs: coeffs, bound: rhs.constant - lhs.constant);
  }
}

class _LinearFlatZinc {
  final List<num> coeffs;
  final List<String> vars;
  final String op; // == / <= / >= / < / > / !=
  final num bound;
  const _LinearFlatZinc({
    required this.coeffs,
    required this.vars,
    required this.op,
    required this.bound,
  });

  String toFlatZinc() {
    final intCoeffs = coeffs.map((c) => c.toInt()).toList();
    final intBound = bound.toInt();
    switch (op) {
      case '==':
        return _emit('int_lin_eq', intCoeffs, vars, intBound);
      case '<=':
        return _emit('int_lin_le', intCoeffs, vars, intBound);
      case '<':
        return _emit('int_lin_le', intCoeffs, vars, intBound - 1);
      case '>=':
        // a·x >= k  ⇔  −a·x <= −k
        return _emit(
            'int_lin_le', intCoeffs.map((c) => -c).toList(), vars, -intBound);
      case '>':
        return _emit('int_lin_le', intCoeffs.map((c) => -c).toList(), vars,
            -(intBound + 1));
      case '!=':
        return _emit('int_lin_ne', intCoeffs, vars, intBound);
    }
    throw StateError('unreachable op $op');
  }

  static String _emit(
    String name,
    List<int> coeffs,
    List<String> vars,
    int bound,
  ) =>
      'constraint $name([${coeffs.join(', ')}], '
      '[${vars.join(', ')}], $bound);';
}
