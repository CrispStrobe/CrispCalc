// lib/engine/matrix_diagnostics.dart
//
// Self-test battery for matrix arithmetic. Runs a handful of well-known
// matrix operations through the engine and the bridge to give the user
// (and HISTORY round 13's verification story) a quick way to confirm
// `det` / `inv` / `transpose` / `+` / `*` work end-to-end against a
// release SymEngine build. If the native bridge isn't loaded, every
// test fails with whatever error string the engine emits — which is
// itself useful diagnostic output.

import 'calculator_engine.dart';
import '../utils/expression_preprocessing_utils.dart';

class MatrixDiagnosticResult {
  final String name;
  final String expression;
  final String expected;
  final String actual;
  final bool passed;

  const MatrixDiagnosticResult({
    required this.name,
    required this.expression,
    required this.expected,
    required this.actual,
    required this.passed,
  });
}

class MatrixDiagnostics {
  /// Runs the matrix self-test battery against [engine] and returns a list
  /// of (name, expression, expected, actual, passed) tuples. Each check is
  /// a "result contains expected substring after whitespace stripping" —
  /// SymEngine's formatting tends to vary slightly (spaces, ordering) but
  /// the canonical shape is stable enough for substring matching.
  static List<MatrixDiagnosticResult> run(CalculatorEngine engine) {
    const specs = <_Spec>[
      _Spec('2x2 determinant', 'det([1,2; 3,4])', '-2'),
      _Spec('3x3 identity determinant', 'det([1,0,0; 0,1,0; 0,0,1])', '1'),
      _Spec('Transpose 2x2', 'transpose([1,2; 3,4])',
          'Matrix([[1, 3], [2, 4]])'),
      _Spec(
          'Inverse of identity', 'inv([1,0; 0,1])', 'Matrix([[1, 0], [0, 1]])'),
      _Spec('Matrix addition', '[1,2; 3,4] + [1,0; 0,1]',
          'Matrix([[2, 2], [3, 5]])'),
      _Spec('Matrix multiplication', '[1,0; 0,1] * [3,4; 5,6]',
          'Matrix([[3, 4], [5, 6]])'),
      // 2x3 system whose RREF is [[1, 0, -1], [0, 1, 2]] — the canonical
      // textbook example. Catches sign and pivot-scaling bugs in one shot.
      _Spec('RREF of a 2x3 system', 'rref([2,1,0; -1,1,3])',
          'Matrix([[1, 0, -1], [0, 1, 2]])'),
    ];

    final out = <MatrixDiagnosticResult>[];
    for (final spec in specs) {
      String actual;
      try {
        final processed = ExpressionPreprocessingUtils.preprocessNativeExpression(
            spec.expression);
        actual = engine.evaluate(processed);
      } catch (e) {
        actual = 'Error: $e';
      }
      final passed = _normalize(actual).contains(_normalize(spec.expected));
      out.add(MatrixDiagnosticResult(
        name: spec.name,
        expression: spec.expression,
        expected: spec.expected,
        actual: actual,
        passed: passed,
      ));
    }
    return out;
  }

  static String _normalize(String s) =>
      s.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}

class _Spec {
  final String name;
  final String expression;
  final String expected;
  const _Spec(this.name, this.expression, this.expected);
}
