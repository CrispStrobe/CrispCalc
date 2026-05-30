// test/numeric_fallback_test.dart
//
// The pure-Dart numeric fallback that lets the web build resolve basic
// math without the native SymEngine bridge. Tests run with native
// unavailable (the test host never loads the dylib), so they also cover
// the CalculatorEngine.evaluate() routing end-to-end.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:crisp_calc/engine/numeric_fallback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumericFallbackEvaluator.tryEvaluate', () {
    String? ev(String e) => NumericFallbackEvaluator.tryEvaluate(e);

    test('basic arithmetic', () {
      expect(ev('123+45'), '168');
      expect(ev('123 + 45'), '168');
      expect(ev('100-58'), '42');
      expect(ev('6*7'), '42');
      expect(ev('1/2'), '0.5');
      expect(ev('2+3*4'), '14'); // precedence
      expect(ev('(2+3)*4'), '20'); // parens
      expect(ev('10%3'), '1'); // modulo
    });

    test('powers (right-associative) and unary minus', () {
      expect(ev('2^10'), '1024');
      expect(ev('2^-3'), '0.125');
      expect(ev('-2^2'), '-4'); // -(2^2)
      expect(ev('2^3^2'), '512'); // 2^(3^2)
      expect(ev('-5+3'), '-2');
    });

    test('functions (radians)', () {
      expect(ev('sqrt(16)'), '4');
      expect(ev('sqrt(2)'), '1.41421356237');
      expect(ev('abs(-7)'), '7');
      expect(ev('floor(3.7)'), '3');
      expect(ev('ceil(3.2)'), '4');
      expect(ev('exp(0)'), '1');
      expect(ev('ln(1)'), '0');
      expect(ev('log10(1000)'), '3');
    });

    test('trig at notable angles', () {
      expect(ev('sin(0)'), '0');
      expect(ev('cos(0)'), '1');
      // sin(pi/2) ≈ 1 (float) — formatter trims to a clean value.
      expect(double.parse(ev('sin(pi/2)')!), closeTo(1.0, 1e-9));
    });

    test('constants and implicit multiplication', () {
      expect(double.parse(ev('pi')!), closeTo(3.14159265359, 1e-9));
      expect(double.parse(ev('e')!), closeTo(2.71828182846, 1e-9));
      expect(double.parse(ev('2pi')!), closeTo(6.28318530718, 1e-9));
      expect(double.parse(ev('2sin(0)+1')!), closeTo(1.0, 1e-9));
    });

    test('gamma matches factorial', () {
      expect(double.parse(ev('gamma(5)')!), closeTo(24.0, 1e-6)); // 4!
    });

    test('returns null for non-numeric / symbolic input', () {
      expect(ev('x+1'), isNull); // free variable
      expect(ev('2*x'), isNull);
      expect(ev('Matrix([[1,2],[3,4]])'), isNull);
      expect(ev('solve(x-1)'), isNull); // unknown function
      expect(ev('1+'), isNull); // parse error
      expect(ev('foo(2)'), isNull); // unknown function
      expect(ev(''), isNull);
    });

    test('non-finite results yield null (no "Infinity" string)', () {
      expect(ev('1/0'), isNull);
    });

    test('variable binding (for graphing reuse)', () {
      expect(NumericFallbackEvaluator.evalNumeric('x^2+1', {'x': 3}), 10.0);
      expect(
          NumericFallbackEvaluator.evalNumeric('x+y', {'x': 2, 'y': 5}), 7.0);
    });
  });

  group('CalculatorEngine.evaluate routes to the fallback when native-less',
      () {
    late CalculatorEngine engine;
    setUpAll(() => engine = CalculatorEngine());

    test('basic arithmetic resolves instead of "requires native library"', () {
      // In the test host the native bridge is unavailable, mirroring web.
      if (engine.isNativeAvailable) return; // native present → SymEngine owns it
      expect(engine.evaluate('123+45'), '168');
      expect(engine.evaluate('sqrt(16)'), '4');
    });

    test('symbolic input still reports the native requirement', () {
      if (engine.isNativeAvailable) return;
      expect(engine.evaluate('2*x'), contains('requires native library'));
    });
  });
}
