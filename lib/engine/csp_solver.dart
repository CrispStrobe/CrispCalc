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
}
