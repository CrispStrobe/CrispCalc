// lib/engine/step_diagnostics.dart
//
// End-to-end math correctness battery for the step engine. Runs a
// fixed list of differentiation, integration, and solve examples
// through StepEngine, and checks the final Result step's `after`
// field against an expected substring (after whitespace stripping).
//
// Like MatrixDiagnostics, this exists in two forms:
//   - Settings → "Step engine self-test" dialog
//   - CRISPCALC_DIAGNOSTIC=steps for headless CI verification
//
// The native bridge isn't loaded in `flutter test`, so this can only
// run in a real launched binary. Designed to be invariant to small
// SymEngine formatting changes — whitespace, multiplication-as-* vs
// `·`, and exponent style are all normalized away before comparison.

import 'calculator_engine.dart';
import 'step_engine.dart';
import '../utils/expression_preprocessing_utils.dart';

class StepDiagnosticResult {
  final String name;
  final String operation; // 'diff', 'integrate', 'solve'
  final String expression;
  final String expected;
  final String actual;
  final bool passed;

  const StepDiagnosticResult({
    required this.name,
    required this.operation,
    required this.expression,
    required this.expected,
    required this.actual,
    required this.passed,
  });
}

class StepDiagnostics {
  /// Run every spec and return results. Each spec specifies one of
  /// (diff, integrate, solve), an input expression, and one or more
  /// substrings that the canonical result must contain after
  /// whitespace + case normalization.
  static List<StepDiagnosticResult> run(CalculatorEngine engine) {
    final out = <StepDiagnosticResult>[];

    for (final spec in _diffSpecs) {
      out.add(_runOne(spec, 'diff', engine, (e, v) {
        final steps = StepEngine.differentiate(_pp(e), v, engine);
        return steps.last.after;
      }));
    }
    for (final spec in _integrateSpecs) {
      out.add(_runOne(spec, 'integrate', engine, (e, v) {
        final steps = StepEngine.integrate(_pp(e), v, engine);
        return steps.last.after;
      }));
    }
    for (final spec in _solveSpecs) {
      out.add(_runOne(spec, 'solve', engine, (e, v) {
        final steps = StepEngine.solve(_pp(e), v, engine);
        return steps.last.after;
      }));
    }

    return out;
  }

  static StepDiagnosticResult _runOne(_Spec spec, String op,
      CalculatorEngine engine, String Function(String e, String v) runner) {
    String actual;
    try {
      actual = runner(spec.expression, spec.variable);
    } catch (e) {
      actual = 'Error: $e';
    }
    final passed = _matches(actual, spec.expected);
    return StepDiagnosticResult(
      name: spec.name,
      operation: op,
      expression: spec.expression,
      expected: spec.expected,
      actual: actual,
      passed: passed,
    );
  }

  static String _pp(String e) =>
      ExpressionPreprocessingUtils.preprocessNativeExpression(e);

  /// Normalize an expression string for substring matching. Strips
  /// whitespace, lowercases, replaces the middle-dot multiplier we use
  /// in step traces with `*`, collapses `**` (Python-style power that
  /// SymEngine emits) to `^`, and drops parens entirely. This makes
  /// the diagnostic invariant to incidental formatting choices —
  /// `(x)^2/2` and `x^2/2` and `x**2/2` all compare equal.
  static String _normalize(String s) {
    var out = s
        .replaceAll('·', '*')
        .replaceAll('**', '^')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('|', '') // strip absolute-value bars so ln|x| → lnx
        .toLowerCase();
    return out;
  }

  static bool _matches(String actual, String expected) {
    // Match any of the | -separated alternates as a substring on the
    // normalized actual. Lets us encode "either 2*x or x*2" without
    // overconstraining the canonical SymEngine output shape.
    final na = _normalize(actual);
    for (final alt in expected.split('|')) {
      if (na.contains(_normalize(alt))) return true;
    }
    return false;
  }

  // === Differentiation specs ==============================================
  //
  // Each: (name, expression, variable, expected-substring(s)). The
  // expected string can use `|` to list alternates — SymEngine sometimes
  // returns `2*x` and sometimes `2x`, etc.

  static const _diffSpecs = <_Spec>[
    _Spec('d/dx [5]', '5', 'x', '0'),
    _Spec('d/dx [x]', 'x', 'x', '1'),
    _Spec('d/dx [x^2]', 'x^2', 'x', '2*x|2x'),
    _Spec('d/dx [x^3]', 'x^3', 'x', '3*x^2|3x^2'),
    _Spec('d/dx [sin(x)]', 'sin(x)', 'x', 'cos(x)'),
    _Spec('d/dx [cos(x)]', 'cos(x)', 'x', '-sin(x)'),
    _Spec('d/dx [exp(x)]', 'exp(x)', 'x', 'exp(x)|e^x'),
    _Spec('d/dx [ln(x)]', 'log(x)', 'x', '1/x|x^-1|x^(-1)'),
    _Spec('d/dx [x*sin(x)]', 'x*sin(x)', 'x', 'sin(x)'),
    _Spec('d/dx [(x+1)^2]', '(x+1)^2', 'x', '2'),
    _Spec('d/dx [sin(x^2)] (chain)', 'sin(x^2)', 'x', '2*x*cos|2xcos'),
    _Spec('d/dx [2*x + 3]', '2*x + 3', 'x', '2'),
    _Spec('d/dx [1/x]', '1/x', 'x', '-1/x^2|-x^(-2)'),
  ];

  // === Integration specs ==================================================

  static const _integrateSpecs = <_Spec>[
    _Spec('∫ 5 dx', '5', 'x', '5*x|5x'),
    _Spec('∫ x dx', 'x', 'x', 'x^2/2|(1/2)x^2|(1/2)*x^2'),
    _Spec('∫ x^2 dx', 'x^2', 'x', 'x^3/3|(1/3)x^3|(1/3)*x^3'),
    _Spec('∫ x^3 dx', 'x^3', 'x', 'x^4/4|(1/4)x^4|(1/4)*x^4'),
    _Spec('∫ 1/x dx', '1/x', 'x', 'log(x)|ln(x)'),
    _Spec('∫ sin(x) dx', 'sin(x)', 'x', '-cos(x)'),
    _Spec('∫ cos(x) dx', 'cos(x)', 'x', 'sin(x)'),
    _Spec('∫ exp(x) dx', 'exp(x)', 'x', 'exp(x)|e^x'),
    _Spec('∫ (x + 1) dx', 'x + 1', 'x', 'x^2/2|x/2'),
    _Spec('∫ 3*x^2 dx', '3*x^2', 'x', 'x^3'),
    _Spec('∫ x^2 + x dx', 'x^2 + x', 'x', 'x^3/3'),
    // V2 — linear u-substitution
    _Spec(
        '∫ sin(2*x) dx',
        'sin(2*x)',
        'x',
        '-cos(2*x)/2|-1/2*cos(2*x)|'
            '-(1/2)*cos(2*x)'),
    _Spec('∫ cos(3*x) dx', 'cos(3*x)', 'x', 'sin(3*x)/3|(1/3)*sin(3*x)'),
    _Spec(
        '∫ exp(3*x) dx',
        'exp(3*x)',
        'x',
        'exp(3*x)/3|(1/3)*exp(3*x)|'
            '(1/3)*e^(3*x)|e^(3*x)/3'),
    _Spec('∫ (2*x + 1)^3 dx', '(2*x + 1)^3', 'x', '(2*x + 1)^4|(2x+1)^4'),
    _Spec(
        '∫ 1/(x + 1) dx',
        '1/(x + 1)',
        'x',
        'log(x + 1)|ln(x + 1)|'
            'log(x+1)|ln(x+1)'),
    _Spec(
        '∫ 1/(2*x + 1) dx',
        '1/(2*x + 1)',
        'x',
        'log(2*x + 1)/2|log(2x+1)/2|(1/2)*log(2*x + 1)|'
            'ln(2*x + 1)/2|(1/2)*ln(2*x + 1)'),
    // V2 — integration by parts
    _Spec(
        '∫ ln(x) dx',
        'ln(x)',
        'x',
        'x*log(x) - x|x*ln(x) - x|'
            'x*log(x)-x|x*ln(x)-x'),
    _Spec(
        '∫ x*sin(x) dx',
        'x*sin(x)',
        'x',
        '-x*cos(x) + sin(x)|sin(x) - x*cos(x)|-cos(x)*x + sin(x)|'
            'x*-cos(x) - -sin(x)|x*-cos(x)--sin(x)'),
    _Spec('∫ x*exp(x) dx', 'x*exp(x)', 'x',
        'x*exp(x) - exp(x)|(x - 1)*exp(x)|x*e^x - e^x'),
  ];

  // === Solve specs ========================================================

  static const _solveSpecs = <_Spec>[
    _Spec('solve 2x + 3 = 7', '2*x + 3 = 7', 'x', 'x=2|x=2,'),
    _Spec('solve x - 5 = 0', 'x - 5 = 0', 'x', 'x=5|5'),
    _Spec('solve x^2 = 4', 'x^2 = 4', 'x', '2'),
    _Spec('solve x^2 - 5x + 6 = 0', 'x^2 - 5*x + 6 = 0', 'x', '3|2'),
  ];
}

class _Spec {
  final String name;
  final String expression;
  final String variable;
  final String expected;
  const _Spec(this.name, this.expression, this.variable, this.expected);
}
