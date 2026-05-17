// test/matrix_diagnostics_test.dart
//
// Smoke-tests the matrix self-test runner. Under `flutter test` the native
// bridge isn't loaded, so every check is expected to fail with an "Error"
// substring. The test verifies the runner produces the expected number of
// results without throwing.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:crisp_calc/engine/matrix_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatrixDiagnostics.run', () {
    test('returns a result for every spec', () {
      final engine = CalculatorEngine();
      final results = MatrixDiagnostics.run(engine);
      expect(results.length, equals(7));
      expect(
        results.map((r) => r.name),
        containsAll(<String>[
          '2x2 determinant',
          'Transpose 2x2',
          'RREF of a 2x3 system',
        ]),
      );
    });

    test('result entries carry expression + expected strings', () {
      final results = MatrixDiagnostics.run(CalculatorEngine());
      for (final r in results) {
        expect(r.name, isNotEmpty);
        expect(r.expression, isNotEmpty);
        expect(r.expected, isNotEmpty);
      }
    });

    test('does not throw when the native bridge is unavailable', () {
      // Native bridge is never loaded in the test runner; ensure we still
      // get well-formed results (pass/fail set, actual populated).
      final results = MatrixDiagnostics.run(CalculatorEngine());
      for (final r in results) {
        expect(r.actual, isNotEmpty);
      }
    });
  });
}
