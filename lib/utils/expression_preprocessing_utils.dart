// lib/utils/expression_preprocessing_utils.dart
//
// Preprocessing for mathematical expressions before they're handed to
// SymEngine. Pure-Dart string transforms; safe to call without a native
// library. No `print` calls — anything debug-worthy goes via assert/log
// at the call site.

import 'package:flutter/foundation.dart';

import '../engine/app_state.dart';
import '../engine/vector_math.dart';

class ExpressionPreprocessingUtils {
  // Names that look like single-letter variables but are really constants or
  // function names. Compared case-sensitively (SymEngine cares).
  static const Set<String> _reservedTokens = {
    'e',
    'E',
    'pi',
    'Pi',
    'I',
    'oo',
    'sin',
    'cos',
    'tan',
    'csc',
    'sec',
    'cot',
    'asin',
    'acos',
    'atan',
    'sinh',
    'cosh',
    'tanh',
    'asinh',
    'acosh',
    'atanh',
    'ln',
    'log',
    'exp',
    'sqrt',
    'abs',
    'gamma',
    'Gamma',
    'EulerGamma',
    'factorial',
    'fibonacci',
    'deg',
    'rad',
    'mod',
    'Ans',
  };

  static void _log(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('PREPROC: $msg');
    }
  }

  static String preprocessNativeExpression(String expression) {
    var p = expression;

    // Expand vector calls — `dot([1,2,3], [4,5,6])` → `(1*4 + 2*5 + 3*6)` etc.
    // Done first so subsequent rules see plain arithmetic, not call syntax.
    p = VectorMath.preprocess(p);

    // Custom matrix format "[1,2; 3,4]" -> SymEngine "Matrix([[1, 2],[3, 4]])".
    // Spaces after commas keep the German-comma rule below from rewriting
    // matrix cells like 1,2 into 1.2.
    p = p.replaceAllMapped(RegExp(r'\[([^\]]+)\]'), (match) {
      final content = match.group(1)!;
      if (content.contains(';')) {
        final rows = content.split(';');
        final formattedRows = rows.map((row) {
          final cells = row.split(',').map((c) => c.trim()).join(', ');
          return '[$cells]';
        }).join(',');
        return 'Matrix([$formattedRows])';
      }
      return match.group(0)!;
    });

    // German decimal comma -> period (but only between digits).
    p = p.replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]!}.${m[2]!}');

    // Implicit multiplication.
    p = p.replaceAllMapped(RegExp(r'(\d|\))(\()'), (m) => '${m[1]}*${m[2]}');
    p = p.replaceAllMapped(
        RegExp(r'(\b[a-zA-Z]\b)(\()'), (m) => '${m[1]}*${m[2]}');
    p = p.replaceAllMapped(
        RegExp(r'(\))(\d|\b[a-zA-Z]\b)'), (m) => '${m[1]}*${m[2]}');

    // n! for literal n -> compute the exact BigInt product directly
    // and inline the digit string. SymEngine's `gamma(n+1)` returns
    // a float (scientific notation past ~15 digits), which defeats
    // the exact-integer-mode display, so we extend the BigInt path
    // up to n = 1000 (~2568 digits — completes in milliseconds).
    // Above that the cost gets noticeable and we fall back to gamma.
    p = p.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n >= 0 && n <= 1000) {
        var f = BigInt.one;
        for (var i = 2; i <= n; i++) {
          f *= BigInt.from(i);
        }
        return f.toString();
      }
      return 'gamma(${n + 1})';
    });

    // var! -> gamma(var+1)
    p = p.replaceAllMapped(
      RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*)!'),
      (m) => 'gamma(${m.group(1)} + 1)',
    );

    // a mod b -> (a) % (b)
    p = p.replaceAllMapped(
      RegExp(r'(\S+)\s+mod\s+(\S+)'),
      (m) => '(${m.group(1)}) % (${m.group(2)})',
    );

    return preprocessSpecialFunctions(p);
  }

  static String preprocessSpecialFunctions(String expression) {
    var result = expression;

    // fib(n) — compute for small n, otherwise delegate to fibonacci(n).
    result = result.replaceAllMapped(RegExp(r'fib\((\d+)\)'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n <= 0) return '0';
      if (n == 1 || n == 2) return '1';
      if (n <= 90) {
        var a = BigInt.zero, b = BigInt.one;
        for (var i = 2; i <= n; i++) {
          final temp = a + b;
          a = b;
          b = temp;
        }
        return b.toString();
      }
      return 'fibonacci($n)';
    });

    // isprime(n) — simple deterministic check for small n.
    result = result.replaceAllMapped(RegExp(r'isprime\((\d+)\)'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n < 2) return 'false';
      if (n == 2) return 'true';
      if (n.isEven) return 'false';
      for (var i = 3; i * i <= n; i += 2) {
        if (n % i == 0) return 'false';
      }
      return 'true';
    });

    return result;
  }

  /// Substitutes Ans + user variables. Variable names are matched
  /// case-sensitively.
  static String substituteVariables(String expression, AppState appState) {
    var result = expression;

    if (result.contains('Ans')) {
      final lastResult =
          appState.history.isNotEmpty ? appState.history.first.result : '0';
      final cleanResult = extractNumericFromSolveResult(lastResult);
      result = result.replaceAll('Ans', cleanResult);
    }

    for (final entry in appState.userVariables.entries) {
      final pattern = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b');
      result = result.replaceAll(pattern, '(${entry.value})');
    }

    return result;
  }

  static String extractNumericFromSolveResult(String solveResult) {
    final match =
        RegExp(r'[a-zA-Z]\s*=\s*([+-]?[\d.]+)\s*$').firstMatch(solveResult);
    if (match != null && !match.group(1)!.contains(',')) {
      return match.group(1)!.trim();
    }
    return solveResult;
  }

  /// Inlines user-defined `Y1`..`Y10` graph slots and named user
  /// functions (e.g. `f(x) = x^2 + 1` typed in the calculator). Both
  /// share the same depth budget so compositions like `g(f(x))` work
  /// up to four nested expansions before the guard kicks in.
  static String preprocessExpression(
    String expression,
    AppState appState, {
    int maxDepth = 4,
  }) {
    var out = expression;
    var remaining = maxDepth;
    while (remaining > 0) {
      final before = out;
      out = _expandUserFunctions(out, appState);
      out = _expandFunctions(out, appState, 1); // Y1..Y10
      if (out == before) break;
      remaining--;
    }
    return out;
  }

  /// Single-pass inline of named [UserFunction] references. Caller
  /// loops until convergence or the depth budget runs out — see
  /// [preprocessExpression]. Skips identifiers followed by `(` that
  /// aren't actually user-function calls so built-ins (`sin`, `gcd`,
  /// `Matrix`) stay intact.
  static String _expandUserFunctions(String expression, AppState appState) {
    if (appState.userFunctions.isEmpty) return expression;
    // Build a per-pass regex of `name(` openers. Sorted longest-first
    // for safety, though single-letter names mean there's no overlap.
    final names = appState.userFunctions.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp(
      r'(?<![a-zA-Z_])(' + names.map(RegExp.escape).join('|') + r')\(',
    );
    final out = StringBuffer();
    var i = 0;
    while (i < expression.length) {
      final match = pattern.matchAsPrefix(expression, i);
      if (match == null) {
        out.write(expression[i]);
        i++;
        continue;
      }
      final name = match.group(1)!;
      // Walk the parens to find the matching close.
      var depth = 1;
      var j = match.end;
      while (j < expression.length && depth > 0) {
        final c = expression[j];
        if (c == '(') depth++;
        if (c == ')') depth--;
        if (depth == 0) break;
        j++;
      }
      if (j >= expression.length || depth != 0) {
        // Unbalanced — leave the original text alone, advance one char.
        out.write(expression[i]);
        i++;
        continue;
      }
      final arg = expression.substring(match.end, j);
      final fn = appState.userFunctions[name]!;
      final substituted = fn.body.replaceAll(
        RegExp(r'(?<![a-zA-Z_])' +
            RegExp.escape(fn.paramVar) +
            r'(?![a-zA-Z_0-9])'),
        '($arg)',
      );
      out.write('($substituted)');
      i = j + 1;
    }
    return out.toString();
  }

  static String _expandFunctions(
      String expression, AppState appState, int depthRemaining) {
    if (depthRemaining <= 0) return expression;

    final funcCallRegex = RegExp(r'Y(\d+)\((.*?)\)');
    final beforeCalls = expression;
    var processed = expression.replaceAllMapped(funcCallRegex, (match) {
      try {
        final funcIndex = int.parse(match.group(1)!) - 1;
        final argValue = match.group(2)!;
        if (funcIndex < 0 || funcIndex >= appState.graphFunctions.length) {
          return match.group(0)!;
        }
        final funcBody = appState.graphFunctions[funcIndex];
        if (funcBody.isEmpty) return match.group(0)!;
        final variable = detectVariable(funcBody);
        final substitutedBody = funcBody.replaceAll(variable, '($argValue)');
        return '($substitutedBody)';
      } catch (_) {
        return match.group(0)!;
      }
    });

    final simpleFuncRegex = RegExp(r'\bY(\d+)\b');
    processed = processed.replaceAllMapped(simpleFuncRegex, (match) {
      try {
        final funcIndex = int.parse(match.group(1)!) - 1;
        if (funcIndex < 0 || funcIndex >= appState.graphFunctions.length) {
          return match.group(0)!;
        }
        final funcBody = appState.graphFunctions[funcIndex];
        if (funcBody.isEmpty) return match.group(0)!;
        return '($funcBody)';
      } catch (_) {
        return match.group(0)!;
      }
    });

    if (processed == beforeCalls) {
      return processed;
    }
    return _expandFunctions(processed, appState, depthRemaining - 1);
  }

  /// Picks the variable to solve for. Reserved tokens (constants, function
  /// names) are skipped. Prefers `x, y, z, t, n, a, b, c` in that order.
  /// **Case-sensitive** — `X` and `x` are different variables.
  /// Substitute parameter values into an expression. Each entry in
  /// [params] maps a parameter name to its current numeric value; the
  /// name is matched as an identifier (not as part of a longer name)
  /// and replaced with its value wrapped in parentheses. Identifiers
  /// followed by `(` are left alone so function calls don't get
  /// mangled. Returns [expression] unchanged when [params] is empty.
  static String substituteParameters(
      String expression, Map<String, double> params) {
    if (params.isEmpty) return expression;
    var out = expression;
    for (final entry in params.entries) {
      final pattern = RegExp(
          '(?<![a-zA-Z_0-9])${RegExp.escape(entry.key)}(?![a-zA-Z_0-9\\(])');
      out = out.replaceAll(pattern, '(${entry.value})');
    }
    return out;
  }

  /// Pull out parameter names from a graphable function expression. A
  /// parameter is any identifier in the expression that:
  ///   - is not the plot variable [plotVar]
  ///   - is not a reserved constant or function name
  ///   - is not immediately followed by `(` (so a function call like
  ///     `sin(x)` doesn't get its name harvested)
  ///
  /// Returns a deduplicated, sorted list — the graphing screen uses it
  /// to decide which sliders to render. Returns an empty list when no
  /// parameters are found.
  static List<String> detectParameters(String expression, String plotVar) {
    if (expression.isEmpty) return const [];

    // Identifier candidates: letters (allowing multi-char names like
    // `freq`), with a non-letter/digit boundary on either side, AND not
    // immediately followed by `(`.
    final paramPattern =
        RegExp(r'(?<![a-zA-Z_0-9])([a-zA-Z][a-zA-Z]*)(?![a-zA-Z_0-9\(])');
    final found = <String>{};
    for (final m in paramPattern.allMatches(expression)) {
      final name = m.group(1)!;
      if (name == plotVar) continue;
      if (_reservedTokens.contains(name)) continue;
      found.add(name);
    }
    final list = found.toList()..sort();
    return list;
  }

  static String detectVariable(String equation) {
    // A single letter that isn't adjacent to another letter on either side.
    // `\b` alone would miss `k` in `2k+5` because the digit-letter boundary
    // isn't a `\b` boundary, so we use explicit lookbehind/lookahead.
    final variablePattern = RegExp(r'(?<![a-zA-Z])([a-zA-Z])(?![a-zA-Z])');
    final foundVariables = <String>{};
    for (final match in variablePattern.allMatches(equation)) {
      final variable = match.group(1)!;
      if (!_reservedTokens.contains(variable)) {
        foundVariables.add(variable);
      }
    }

    _log('candidates: $foundVariables');

    const preferred = ['x', 'y', 'z', 't', 'n', 'a', 'b', 'c'];
    for (final p in preferred) {
      if (foundVariables.contains(p)) return p;
    }
    if (foundVariables.isNotEmpty) return foundVariables.first;
    return 'x';
  }

  /// Cleans up SymEngine's complex-number representation, stray operators,
  /// and Python-style exponents in numeric/symbolic results.
  static String normalizeComplexResult(String result) {
    if (result.isEmpty) return result;

    var normalized = result.trim();

    // Drop zero imaginary parts.
    normalized = normalized
        .replaceAll(RegExp(r'\s*\+\s*-0(\.0*)?\s*\*?\s*I\b'), '')
        .replaceAll(RegExp(r'\s*\+\s*0(\.0*)?\s*\*?\s*I\b'), '')
        .replaceAll(RegExp(r'\s*\+\s*0\.0\s*\*\s*I\s*\*\s*\d+'), '')
        .replaceAll(RegExp(r'^\s*0(\.0*)?\s*\*\s*I\s*$'), '0');

    // I -> i for display.
    normalized = normalized
        .replaceAll(RegExp(r'(\d+)\s*\*\s*I\b'), r'\1i')
        .replaceAll(RegExp(r'\bI\b'), 'i');

    // Normalize spacing.
    //
    // For `-` we only space when both sides have a non-whitespace
    // character — i.e. the `-` is a binary operator. The previous
    // unconditional `\s*-\s*` → ` - ` turned a unary minus at the
    // start of a result (`-5`, `-5.0`) into `- 5`, which then broke
    // every consumer that called `double.tryParse` on the value
    // (most importantly `AppState.formatNumber`, so the
    // `NumberDisplayFormat` setting was silently ignored on
    // negative results). The bounded-context replace keeps `x - 1`
    // and `1 - 2` formatted with spaces while leaving the leading
    // unary `-` glued to its operand.
    normalized = normalized
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*\+\s*'), ' + ')
        .replaceAllMapped(
          RegExp(r'(\S)\s*-\s*(\S)'),
          (m) => '${m[1]} - ${m[2]}',
        )
        .replaceAll(RegExp(r'\s*\*\s*'), '*')
        .trim();

    normalized = normalized.replaceAll(
        RegExp(r'^([+-]?\d+(?:\.\d+)?)\s*\+\s*0\.0\s*\*\s*I$'), r'\1');

    if (normalized.endsWith(' +') || normalized.endsWith(' -')) {
      normalized = normalized.substring(0, normalized.length - 2).trim();
    }

    // Python-style exponents for nicer display.
    normalized = normalized
        .replaceAll('**2', '²')
        .replaceAll('**3', '³')
        .replaceAllMapped(RegExp(r'\*\*(\d+)'), (m) => '^${m.group(1)}');

    // Drop the `*` between coefficient and single-letter variable.
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d+)\s*\*\s*([a-zA-Z])(?!\*)'),
      (m) => '${m.group(1)}${m.group(2)}',
    );

    if (RegExp(r'^[\+\-\*\s]*$').hasMatch(normalized)) {
      normalized = result;
    }

    return normalized;
  }
}
