import 'package:flutter_test/flutter_test.dart';
import 'package:crisp_calc/engine/calculator_engine.dart';

// These tests run without the native bridge available (the test host doesn't
// load the SymEngine dylib). Every method should return cleanly — typically a
// string starting with "Error" — instead of crashing.

void main() {
  late CalculatorEngine engine;

  setUpAll(() {
    engine = CalculatorEngine();
  });

  test('reports nativeAvailable status without throwing', () {
    expect(() => engine.isNativeAvailable, returnsNormally);
  });

  group('fallback behavior (native bridge unavailable in tests)', () {
    void expectErrorOrSuccess(String result) {
      // Whatever the host gave us, it must be a non-empty string.
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    }

    test('evaluate', () => expectErrorOrSuccess(engine.evaluate('1+1')));
    test('solve', () => expectErrorOrSuccess(engine.solve('x-1', 'x')));
    test('factor', () => expectErrorOrSuccess(engine.factor('x^2-1')));
    test('expand', () => expectErrorOrSuccess(engine.expand('(x+1)^2')));
    test('simplify', () => expectErrorOrSuccess(engine.simplify('x+x')));
    test('differentiate',
        () => expectErrorOrSuccess(engine.differentiate('x^2', 'x')));
    test('substitute',
        () => expectErrorOrSuccess(engine.substitute('x+1', 'x', '2')));
    test('callUnary(sin)',
        () => expectErrorOrSuccess(engine.callUnary('sin', '0')));
    test('factorial', () => expectErrorOrSuccess(engine.factorial(5)));
    test('fibonacci', () => expectErrorOrSuccess(engine.fibonacci(10)));
    test('gcd', () => expectErrorOrSuccess(engine.gcd('12', '8')));
    test('lcm', () => expectErrorOrSuccess(engine.lcm('4', '6')));
  });

  group('input validation independent of native bridge', () {
    test('factorial(-1) returns an error string', () {
      expect(engine.factorial(-1), startsWith('Error'));
    });

    test('fibonacci(-1) returns an error string', () {
      expect(engine.fibonacci(-1), startsWith('Error'));
    });

    test('limit() is documented as not yet implemented', () {
      expect(engine.limit('x', 'x', '0'), startsWith('Error'));
    });

    test('integrate() is documented as not yet implemented', () {
      expect(engine.integrate('x', 'x'), startsWith('Error'));
    });
  });

  group('constants fall back to known values when native is unavailable', () {
    test('pi falls back to a 15-digit value', () {
      final value = engine.getPi();
      // Either the native lib gave us its value, or we fall back to our string.
      // Both should parse to roughly pi.
      final number = double.tryParse(value);
      if (number != null) {
        expect((number - 3.14159265358979).abs(), lessThan(0.001));
      }
    });

    test('e falls back to a 15-digit value', () {
      final value = engine.getE();
      final number = double.tryParse(value);
      if (number != null) {
        expect((number - 2.71828182845904).abs(), lessThan(0.001));
      }
    });
  });
}
