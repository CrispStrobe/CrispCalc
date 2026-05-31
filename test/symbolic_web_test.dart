// test/symbolic_web_test.dart
//
// The pure-Dart web CAS fallback: expand / differentiate / solve for
// single-variable polynomials, with everything outside that grammar
// returning null so the caller falls through to the native-only path.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:crisp_calc/engine/symbolic_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SymbolicWeb.expand', () {
    test('square of a binomial', () {
      expect(SymbolicWeb.expand('(x+1)^2'), 'x^2 + 2x + 1');
    });

    test('difference of squares', () {
      expect(SymbolicWeb.expand('(x+1)(x-1)'), 'x^2 - 1');
    });

    test('cube', () {
      expect(SymbolicWeb.expand('(x+1)^3'), 'x^3 + 3x^2 + 3x + 1');
    });

    test('scalar distribution', () {
      expect(SymbolicWeb.expand('2*(x+3)'), '2x + 6');
      expect(SymbolicWeb.expand('2(x+3)'), '2x + 6'); // implicit mult
    });

    test('product with monomial', () {
      expect(SymbolicWeb.expand('x*(x+1)'), 'x^2 + x');
    });

    test('division by a constant', () {
      expect(SymbolicWeb.expand('(2x+4)/2'), 'x + 2');
    });

    test('collects like terms', () {
      expect(SymbolicWeb.expand('x + x + x'), '3x');
      expect(SymbolicWeb.expand('(x+1)^2 - x^2'), '2x + 1');
    });

    test('non-x variable preserved', () {
      expect(SymbolicWeb.expand('(t+1)^2'), 't^2 + 2t + 1');
    });

    test('accepts ** as power', () {
      expect(SymbolicWeb.expand('(x+1)**2'), 'x^2 + 2x + 1');
    });

    test('rational coefficients stay exact', () {
      expect(SymbolicWeb.expand('(x+1)/2'), '1/2x + 1/2');
    });

    test('unsupported input returns null', () {
      expect(SymbolicWeb.expand('sin(x)'), isNull); // transcendental
      expect(SymbolicWeb.expand('x*y'), isNull); // multivariate
      expect(SymbolicWeb.expand('1/x'), isNull); // rational function
      expect(SymbolicWeb.expand('x^-2'), isNull); // negative power
      expect(SymbolicWeb.expand('x^x'), isNull); // symbolic power
      expect(SymbolicWeb.expand('(x+1'), isNull); // unbalanced
      expect(SymbolicWeb.expand('x = 1'), isNull); // equation
    });
  });

  group('SymbolicWeb.differentiate', () {
    test('power rule', () {
      expect(SymbolicWeb.differentiate('x^3', 'x'), '3x^2');
    });

    test('polynomial', () {
      expect(SymbolicWeb.differentiate('x^2 + 2x + 1', 'x'), '2x + 2');
    });

    test('expands before differentiating', () {
      expect(SymbolicWeb.differentiate('(x+1)^2', 'x'), '2x + 2');
    });

    test('constant', () {
      expect(SymbolicWeb.differentiate('5', 'x'), '0');
    });

    test('with respect to an absent variable is zero', () {
      expect(SymbolicWeb.differentiate('x^2', 'y'), '0');
    });

    test('non-polynomial returns null', () {
      expect(SymbolicWeb.differentiate('sin(x)', 'x'), isNull);
      expect(SymbolicWeb.differentiate('1/x', 'x'), isNull);
    });
  });

  group('SymbolicWeb.solveList', () {
    test('linear', () {
      expect(SymbolicWeb.solveList('2x + 3 = 7', 'x'), ['2']);
      expect(SymbolicWeb.solveList('2x - 4', 'x'), ['2']);
    });

    test('linear with rational root', () {
      expect(SymbolicWeb.solveList('2x - 1', 'x'), ['1/2']);
    });

    test('quadratic, rational roots', () {
      expect(SymbolicWeb.solveList('x^2 - 4', 'x'), ['2', '-2']);
      expect(SymbolicWeb.solveList('x^2 - 5x + 6', 'x'), ['3', '2']);
    });

    test('quadratic, double root', () {
      expect(SymbolicWeb.solveList('x^2 - 2x + 1', 'x'), ['1']);
    });

    test('quadratic, surd roots', () {
      expect(SymbolicWeb.solveList('x^2 - 2', 'x'), ['sqrt(2)', '-sqrt(2)']);
    });

    test('quadratic, surd roots with rational part', () {
      expect(
        SymbolicWeb.solveList('x^2 - x - 1', 'x'),
        ['1/2 + 1/2*sqrt(5)', '1/2 - 1/2*sqrt(5)'],
      );
    });

    test('quadratic, pure imaginary roots', () {
      expect(SymbolicWeb.solveList('x^2 + 1', 'x'), ['I', '-I']);
    });

    test('quadratic, complex roots', () {
      expect(
        SymbolicWeb.solveList('x^2 + 2x + 5', 'x'),
        ['-1 + 2*I', '-1 - 2*I'],
      );
    });

    test('equation form, both sides', () {
      expect(SymbolicWeb.solveList('x^2 = 2x + 1', 'x'),
          ['1 + sqrt(2)', '1 - sqrt(2)']);
    });

    test('no solution for a non-zero constant', () {
      expect(SymbolicWeb.solveList('5', 'x'), equals(<String>[]));
    });

    test('unsupported returns null', () {
      expect(SymbolicWeb.solveList('x^3 - 1', 'x'), isNull); // cubic
      expect(SymbolicWeb.solveList('sin(x)', 'x'), isNull);
      expect(SymbolicWeb.solveList('x^2 - 4', 'y'), isNull); // wrong var
    });
  });

  group('CalculatorEngine routes CAS through the web fallback native-less', () {
    late CalculatorEngine engine;
    setUpAll(() => engine = CalculatorEngine());

    test('expand / differentiate / solve resolve instead of erroring', () {
      // The test host has no native bridge, mirroring the web build.
      if (engine.isNativeAvailable)
        return; // native present → SymEngine owns it
      expect(engine.expand('(x+1)^2'), 'x^2 + 2x + 1');
      expect(engine.differentiate('x^3', 'x'), '3x^2');
      expect(engine.solve('x^2 - 4', 'x'), 'x = {2, -2}');
      expect(engine.solve('2x + 3 = 7', 'x'), 'x = 2');
    });

    test('unsupported CAS input still reports the native requirement', () {
      if (engine.isNativeAvailable) return;
      expect(engine.differentiate('sin(x)', 'x'),
          contains('requires native library'));
      expect(engine.solve('x^3 - 1', 'x'), contains('requires native library'));
    });
  });
}
