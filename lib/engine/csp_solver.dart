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

  const DiophantineResult._({
    required this.solutions,
    required this.error,
    required this.truncated,
    this.objective,
  });

  factory DiophantineResult.ok(
    List<DiophantineSolution> solutions, {
    bool truncated = false,
  }) =>
      DiophantineResult._(
          solutions: solutions, error: null, truncated: truncated);

  factory DiophantineResult.failure(String message) => DiophantineResult._(
        solutions: const [],
        error: message,
        truncated: false,
      );

  /// Round 74: optimization result (minimize / maximize). Carries a
  /// single optimal assignment plus the corresponding objective value.
  factory DiophantineResult.optimal(
    DiophantineSolution assignment,
    num objective,
  ) =>
      DiophantineResult._(
        solutions: [assignment],
        error: null,
        truncated: false,
        objective: objective,
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
          return DiophantineResult.ok(solutions, truncated: true);
        }
      }
      return DiophantineResult.ok(solutions);
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

  /// Detects linear constraints of the form
  /// `c1*v1 +/- c2*v2 +/- … op N` where each `ci` is an optional
  /// integer literal, each `vi` is a known variable name, `op` ∈
  /// `{==, !=, <, <=, >, >=}`, and `N` is an integer. Returns the
  /// extracted (vars, coeffs, op, bound) or null when the shape
  /// doesn't match — caller falls back to the dart_csp string parser.
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
    // Match `<LHS><op><number>` where op is one of the comparators.
    final opMatch =
        RegExp(r'^(.+?)(==|<=|>=|<|>)(-?\d+(?:\.\d+)?)$').firstMatch(stripped);
    if (opMatch == null) return null;
    final lhs = opMatch.group(1)!;
    final op = opMatch.group(2)!;
    final bound = num.parse(opMatch.group(3)!);

    final parsed = _parseLinearTerms(lhs, knownVars);
    if (parsed == null) return null;
    return (vars: parsed.vars, coeffs: parsed.coeffs, op: op, bound: bound);
  }

  /// Round 74: split a sum-of-terms expression like `2*x + y - 3*z`
  /// into matched `(vars, coeffs)` lists. Whitespace tolerant. Each
  /// term must reference a known variable (returns null otherwise so
  /// callers can decline-and-fallback). Coefficients default to 1
  /// when omitted; an optional leading sign is folded into the
  /// coefficient.
  ///
  /// Used by both [_tryParseLinear] (constraint LHS parsing) and
  /// the `minimize` / `maximize` directives in [solveDsl].
  static ({List<String> vars, List<num> coeffs})? _parseLinearTerms(
      String expr, Set<String> knownVars) {
    final stripped = expr.replaceAll(' ', '');
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
    for (final raw in terms) {
      final term = raw.trim();
      final m = RegExp(r'^([+-]?)(\d+(?:\.\d+)?)?\*?([A-Za-z_][A-Za-z0-9_]*)$')
          .firstMatch(term);
      if (m == null) return null;
      final sign = m.group(1) == '-' ? -1 : 1;
      final mag = m.group(2) == null ? 1 : num.parse(m.group(2)!);
      final name = m.group(3)!;
      if (!knownVars.contains(name)) return null;
      vars.add(name);
      coeffs.add(sign * mag);
    }
    if (vars.isEmpty) return null;
    return (vars: vars, coeffs: coeffs);
  }

  /// Strip the `Exception:` prefix and any stack-trace noise so the
  /// UI shows a clean one-line error.
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
      );
    }

    return solveDiophantine(
      variables: vars,
      constraints: constraints,
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
  }) async {
    if (variables.isEmpty) {
      return DiophantineResult.failure('No variables declared.');
    }
    final knownVars = variables.keys.toSet();
    final parsed = _parseLinearTerms(objectiveExpr, knownVars);
    if (parsed == null) {
      return DiophantineResult.failure(
          'Could not parse ${minimize ? 'minimize' : 'maximize'} '
          'expression "$objectiveExpr" — only linear expressions in '
          'the declared variables are supported.');
    }
    // Tight bounds on Σ coef_i · var_i. For each term, the min
    // contribution is coef * varLo when coef ≥ 0 else coef * varHi
    // (symmetric for max). Sum independently.
    var objLo = 0;
    var objHi = 0;
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
      // Bind __obj__ = Σ coef_i · var_i  ⇔  Σ coef_i · var_i − __obj__ == 0.
      problem.addLinearEquals(
        [...parsed.vars, objVar],
        [...parsed.coeffs, -1],
        0,
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
      return DiophantineResult.optimal(assignment, objValue);
    } catch (e) {
      return DiophantineResult.failure(
          'Optimizer failed: ${_friendlyError(e)}');
    }
  }
}
