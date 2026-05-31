import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

// The numerical limit/integrate paths in CalculatorEngine *need* the native
// bridge to evaluate the inner expressions — they call `bridge.substitute`
// and `bridge.evaluate`. In the test host the bridge isn't loaded so we
// verify the fallback paths (error strings) and the input-validation
// branches that don't need the bridge.

void main() {
  final engine = CalculatorEngine();

  group('limit() — fallback when native unavailable', () {
    test('returns an error string (not a crash)', () {
      final result = engine.limit('1/x', 'x', '0');
      expect(result, isA<String>());
      expect(result, startsWith('Error'));
    });

    test('infinity sentinel does not crash', () {
      final result = engine.limit('1/x', 'x', 'oo');
      expect(result, isA<String>());
      expect(result, startsWith('Error'));
    });

    test('negative infinity sentinel does not crash', () {
      final result = engine.limit('1/x', 'x', '-oo');
      expect(result, isA<String>());
      expect(result, startsWith('Error'));
    });
  });

  group('integrate() — fallback / validation', () {
    test('polynomial definite integral resolves without the native bridge', () {
      // The C wrapper stubs integrate(); the polynomial case is computed
      // exactly in Dart, so a definite integral works even with no bridge.
      final result = engine.integrate('x', 'x', '0', '1');
      expect(result, '1/2'); // ∫₀¹ x dx
    });

    test('indefinite integral resolves without the native bridge', () {
      // Exact Dart antiderivative for polynomials, plus the StepEngine rule
      // walker for standard trig/exp — all bridge-free. Only non-elementary
      // integrands (no antiderivative rule) still error.
      expect(engine.integrate('x', 'x'), '1/2x^2 + C');
      expect(engine.integrate('sin(x)', 'x'), '-cos(x) + C');
      if (!engine.isNativeAvailable) {
        expect(engine.integrate('exp(x^2)', 'x'), startsWith('Error'));
      }
    });

    test(
        'definite integration returns a string (numerical fallback or '
        'symbolic FTC)', () {
      // Bridge isn't loaded in tests — the helper returns the "requires
      // native library" sentinel. The point of this test is to make sure
      // the new code path doesn't throw.
      final result = engine.integrate('x^2', 'x', '0', '1');
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });
  });
}
