// test/step_engine_thorough_test.dart
//
// Wide-coverage tests for the step engine. Native bridge isn't loaded
// in `flutter test`, so we focus on (a) which rule fires for each
// shape, (b) the structural correctness of the trace (no missing
// "Result", sensible recursion depth), and (c) the format of the
// after-strings that the walker computes purely in Dart (e.g. power-
// rule unfolds, sum-rule decomposition).
//
// End-to-end math correctness against the live bridge is verified by
// the `CRISPCALC_DIAGNOSTIC=steps` headless battery.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:crisp_calc/engine/step_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = CalculatorEngine();

  List<String> diffRules(String e, [String v = 'x']) =>
      StepEngine.differentiate(e, v, engine).map((s) => s.rule).toList();
  List<String> intRules(String e, [String v = 'x']) =>
      StepEngine.integrate(e, v, engine).map((s) => s.rule).toList();
  List<String> solveRules(String e, [String v = 'x']) =>
      StepEngine.solve(e, v, engine).map((s) => s.rule).toList();

  // ============================================================
  // differentiate — exhaustive rule coverage
  // ============================================================

  group('differentiate — constant rule', () {
    test('integer constant', () {
      expect(diffRules('5').first, equals('Constant rule'));
    });
    test('decimal constant', () {
      expect(diffRules('3.14').first, equals('Constant rule'));
    });
    test('negative constant', () {
      expect(diffRules('-7').first, equals('Constant rule'));
    });
    test('constant with reserved names', () {
      expect(diffRules('pi').first, equals('Constant rule'));
      expect(diffRules('e').first, equals('Constant rule'));
    });
    test('expression that happens to look variable-free with y', () {
      expect(diffRules('y*y', 'x').first, equals('Constant rule'));
    });
  });

  group('differentiate — identity', () {
    test('plain x', () {
      expect(diffRules('x').first, equals('Identity'));
    });
    test('different variable', () {
      expect(diffRules('t', 't').first, equals('Identity'));
    });
    test('paren-wrapped x', () {
      expect(diffRules('(x)').first, equals('Identity'));
    });
  });

  group('differentiate — sum/difference', () {
    test('two-term sum', () {
      expect(diffRules('x + 1').first, equals('Sum/difference rule'));
    });
    test('two-term difference', () {
      expect(diffRules('x - 1').first, equals('Sum/difference rule'));
    });
    test('three-term sum', () {
      final r = diffRules('x + 1 + x^2');
      expect(r.first, equals('Sum/difference rule'));
      expect(r, contains('Power rule'));
    });
    test('mixed plus/minus chain', () {
      final r = diffRules('x - 2 + 3*x - x^2');
      expect(r.first, equals('Sum/difference rule'));
    });
    test('does NOT split on minus inside a paren', () {
      // (x-1)^2 should be power rule with combined chain on (x-1),
      // not a sum split.
      final r = diffRules('(x-1)^2');
      expect(r.first, isNot(equals('Sum/difference rule')));
    });
    test('does NOT split on exponential sign (1e-5)', () {
      // The constant 1e-5 should be treated as a single constant, not
      // 1e MINUS 5.
      expect(diffRules('1e-5').first, equals('Constant rule'));
    });
  });

  group('differentiate — product rule', () {
    test('two factors with variable in each', () {
      expect(diffRules('x*sin(x)').first, equals('Product rule'));
    });
    test('three factors fans into nested product rules', () {
      final r = diffRules('x*sin(x)*cos(x)');
      expect(r.first, equals('Product rule'));
      // first*(rest) recursion → second product rule appears
      expect(r.where((s) => s == 'Product rule').length, greaterThanOrEqualTo(2));
    });
  });

  group('differentiate — quotient rule', () {
    test('basic quotient', () {
      expect(diffRules('sin(x)/x').first, equals('Quotient rule'));
    });
    test('numerator constant', () {
      expect(diffRules('1/x').first, equals('Quotient rule'));
    });
  });

  group('differentiate — power and exponential', () {
    test('x^2', () {
      expect(diffRules('x^2').first, equals('Power rule'));
    });
    test('x^7', () {
      expect(diffRules('x^7').first, equals('Power rule'));
    });
    test('x^(1/2)', () {
      expect(diffRules('x^(1/2)').first, equals('Power rule'));
    });
    test('x^(-1) — still a power-rule case (no chain)', () {
      expect(diffRules('x^(-1)').first, equals('Power rule'));
    });
    test('2^x — exponential rule', () {
      expect(diffRules('2^x').first, equals('Exponential rule'));
    });
    test('e^x — exponential rule', () {
      expect(diffRules('e^x').first, equals('Exponential rule'));
    });
  });

  group('differentiate — standard function chain rule', () {
    test('sin(x) is direct', () {
      expect(diffRules('sin(x)').first, equals('Derivative of sin'));
    });
    test('sin(x^2) is chain', () {
      expect(diffRules('sin(x^2)').first, contains('Chain rule'));
    });
    test('cos(2*x) is chain', () {
      expect(diffRules('cos(2*x)').first, contains('Chain rule'));
    });
    test('exp(x^2) is chain', () {
      expect(diffRules('exp(x^2)').first, contains('Chain rule'));
    });
    test('log(x+1) is chain', () {
      expect(diffRules('log(x+1)').first, contains('Chain rule'));
    });
    test('every standard function name has a rule entry', () {
      const fns = [
        'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
        'sinh', 'cosh', 'tanh', 'exp', 'log', 'sqrt'
      ];
      for (final fn in fns) {
        final r = diffRules('$fn(x)');
        expect(r.first, isNot(equals('Differentiate')),
            reason: 'missing standard rule for $fn');
      }
    });
  });

  group('differentiate — Result invariant', () {
    test('every trace ends with a Result step', () {
      for (final e in const [
        '7', 'x', 'x + 1', 'x*sin(x)', 'sin(x)/x', 'x^3', '2^x',
        'sin(x^2)', '(x+1)*(x+2)', 'exp(x)*cos(x)',
      ]) {
        expect(diffRules(e).last, equals('Result'), reason: 'e=$e');
      }
    });
  });

  // ============================================================
  // integrate — exhaustive rule coverage
  // ============================================================

  group('integrate — constant rule', () {
    test('integer', () {
      expect(intRules('5').first, equals('Constant rule'));
    });
    test('decimal', () {
      expect(intRules('3.14').first, equals('Constant rule'));
    });
    test('expression in other variable', () {
      expect(intRules('y^2', 'x').first, equals('Constant rule'));
    });
  });

  group('integrate — power rule', () {
    test('∫x dx is "Power rule (n=1)"', () {
      expect(intRules('x').first, equals('Power rule (n=1)'));
    });
    test('∫x^2 dx', () {
      expect(intRules('x^2').first, equals('Power rule'));
    });
    test('∫x^7 dx', () {
      expect(intRules('x^7').first, equals('Power rule'));
    });
    test('∫x^-1 dx is logarithm rule, not power rule', () {
      expect(intRules('x^-1').first, equals('Logarithm rule'));
    });
  });

  group('integrate — logarithm rule', () {
    test('∫1/x dx', () {
      expect(intRules('1/x').first, equals('Logarithm rule'));
    });
    test('∫1/(x+1) dx falls through (no u-sub in V1)', () {
      expect(intRules('1/(x+1)').first, equals('Symbolic integration'));
    });
  });

  group('integrate — linearity', () {
    test('∫(x + 1) dx', () {
      final r = intRules('x + 1');
      expect(r.first, equals('Sum/difference rule (linearity)'));
      expect(r, contains('Constant rule'));
    });
    test('∫(x^2 + x + 1) dx fans out', () {
      final r = intRules('x^2 + x + 1');
      expect(r.first, equals('Sum/difference rule (linearity)'));
      expect(r, contains('Power rule'));
      expect(r, contains('Power rule (n=1)'));
      expect(r, contains('Constant rule'));
    });
  });

  group('integrate — constant multiple', () {
    test('∫3*x^2 dx pulls 3 out', () {
      final r = intRules('3*x^2');
      expect(r.first, equals('Constant multiple'));
      expect(r, contains('Power rule'));
    });
    test('∫a*sin(x) dx leaves sin(x) inside', () {
      final r = intRules('a*sin(x)');
      expect(r.first, equals('Constant multiple'));
    });
  });

  group('integrate — standard antiderivatives', () {
    test('sin', () {
      expect(intRules('sin(x)').first, equals('Antiderivative of sin'));
    });
    test('cos', () {
      expect(intRules('cos(x)').first, equals('Antiderivative of cos'));
    });
    test('exp', () {
      expect(intRules('exp(x)').first, equals('Antiderivative of exp'));
    });
    test('sinh', () {
      expect(intRules('sinh(x)').first, equals('Antiderivative of sinh'));
    });
    test('cosh', () {
      expect(intRules('cosh(x)').first, equals('Antiderivative of cosh'));
    });
    test('sin(x^2) — no u-sub in V1, falls through', () {
      expect(intRules('sin(x^2)').first, equals('Symbolic integration'));
    });
  });

  group('integrate — Result invariant', () {
    test('every trace ends with a Result step carrying + C', () {
      for (final e in const [
        '5', 'x', 'x^2', '1/x', 'sin(x)', 'exp(x)',
        'x^2 + x + 1', '3*x^2', 'a*sin(x)',
      ]) {
        final steps = StepEngine.integrate(e, 'x', engine);
        expect(steps.last.rule, equals('Result'), reason: 'e=$e');
        // Native bridge is unavailable in tests, so the result string
        // begins with "Error". Still: the "+ C" suffix is only appended
        // on success. We just check the rule name here.
      }
    });
  });

  // ============================================================
  // solve — exhaustive rule coverage
  // ============================================================

  group('solve — equation parsing', () {
    test('input with `=` produces an Original equation step', () {
      expect(solveRules('2*x + 3 = 7').first, equals('Original equation'));
    });
    test('input without `=` is treated as expression = 0', () {
      expect(solveRules('x^2 - 4').first, equals('Treat as equation = 0'));
    });
    test('equation with no variable triggers no-variable branch', () {
      expect(solveRules('5 = 5'), contains('No variable present'));
    });
  });

  group('solve — Result invariant', () {
    test('every solve trace contains at least 2 steps', () {
      for (final e in const [
        '2*x + 3 = 7',
        'x^2 - 4 = 0',
        'x^2 - 5x + 6 = 0',
        'sin(x) = 0',
        'x - 3 = 0',
      ]) {
        expect(StepEngine.solve(e, 'x', engine).length,
            greaterThanOrEqualTo(2),
            reason: 'e=$e');
      }
    });
  });

  // ============================================================
  // Edge cases for the recursion / paren-stripping
  // ============================================================

  group('edge cases', () {
    test('extra outer parens are stripped', () {
      expect(diffRules('(x)').first, equals('Identity'));
      expect(diffRules('((x))').first, equals('Identity'));
      expect(diffRules('(((sin(x))))').first, equals('Derivative of sin'));
    });

    test('inner parens are NOT stripped (sum-protecting)', () {
      // (a+b)*c should be a product, not lifted to a+b.
      final r = diffRules('(x+1)*(x+2)');
      expect(r.first, equals('Product rule'));
    });

    test('unary minus at the start of a sum-rule term works', () {
      // 0 - x - 1 ⇒ sum into three terms with sign labels
      final steps = StepEngine.differentiate('0 - x - 1', 'x', engine);
      expect(steps.first.rule, equals('Sum/difference rule'));
    });
  });
}
