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

    // n! for literal small n -> compute directly; otherwise gamma(n+1).
    p = p.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n <= 20) {
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

  /// Inlines user-defined `Y1`..`Y10` function references with a recursion
  /// guard so cyclic definitions can't loop forever.
  static String preprocessExpression(
    String expression,
    AppState appState, {
    int maxDepth = 4,
  }) {
    return _expandFunctions(expression, appState, maxDepth);
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
    normalized = normalized
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*\+\s*'), ' + ')
        .replaceAll(RegExp(r'\s*-\s*'), ' - ')
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
