// test/step_engine_test.dart
//
// The step engine identifies the top-level rule and recurses. The
// native bridge isn't available under `flutter test`, so the final
// "Result" step's `after` field will be an error string — that's
// fine, the rule-detection logic doesn't depend on the bridge.
// These tests assert which rule gets emitted for each input shape.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:crisp_calc/engine/step_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = CalculatorEngine();

  List<String> rulesFor(String expr, String variable) =>
      StepEngine.differentiate(expr, variable, engine)
          .map((s) => s.rule)
          .toList();

  group('StepEngine.differentiate — rule selection', () {
    test('constant rule fires when expression has no variable', () {
      final rules = rulesFor('7', 'x');
      expect(rules.first, equals('Constant rule'));
    });

    test('identity rule for d/dx[x]', () {
      final rules = rulesFor('x', 'x');
      expect(rules.first, equals('Identity'));
    });

    test('sum rule splits x + 1 into a sum step plus its subderivatives', () {
      final rules = rulesFor('x + 1', 'x');
      expect(rules.first, equals('Sum/difference rule'));
      expect(rules, contains('Identity'));
      expect(rules, contains('Constant rule'));
    });

    test('product rule fires for x*sin(x)', () {
      final rules = rulesFor('x*sin(x)', 'x');
      expect(rules.first, equals('Product rule'));
      expect(rules, contains('Derivative of sin'));
    });

    test('quotient rule fires for sin(x)/x', () {
      final rules = rulesFor('sin(x)/x', 'x');
      expect(rules.first, equals('Quotient rule'));
    });

    test('power rule fires for x^3', () {
      final rules = rulesFor('x^3', 'x');
      expect(rules.first, equals('Power rule'));
    });

    test('exponential rule fires for 2^x', () {
      final rules = rulesFor('2^x', 'x');
      expect(rules.first, equals('Exponential rule'));
    });

    test('standard function: sin(x) emits the direct-derivative step', () {
      final rules = rulesFor('sin(x)', 'x');
      expect(rules.first, equals('Derivative of sin'));
    });

    test('chain rule label appears when the argument is not just x', () {
      final rules = rulesFor('sin(x^2)', 'x');
      expect(rules.first, contains('Chain rule'));
      expect(rules.first, contains('sin'));
    });

    test('every trace ends with a Result step', () {
      for (final expr in const ['7', 'x', 'x + 1', 'sin(x)', 'x^2']) {
        expect(rulesFor(expr, 'x').last, equals('Result'),
            reason: 'expr=$expr');
      }
    });
  });

  group('StepEngine.solve — equation handling without native bridge', () {
    // The native bridge isn't loaded under flutter test, so every call
    // to engine.simplify/solve/differentiate inside StepEngine returns
    // an "Error: …" string. The step engine still produces structurally
    // valid traces — we only check the shape, not the values.

    test('emits an "Original equation" step when input has =', () {
      final steps = StepEngine.solve('2*x + 3 = 7', 'x', engine);
      expect(steps.first.rule, equals('Original equation'));
    });

    test('emits a "Move all terms to one side" step', () {
      final steps = StepEngine.solve('2*x + 3 = 7', 'x', engine);
      expect(steps.map((s) => s.rule), contains('Move all terms to one side'));
    });

    test('input without "=" is treated as expression = 0', () {
      final steps = StepEngine.solve('x^2 - 4', 'x', engine);
      expect(steps.first.rule, equals('Treat as equation = 0'));
    });

    test('"no variable present" branch fires when expression is constant', () {
      final steps = StepEngine.solve('5 = 5', 'x', engine);
      expect(steps.map((s) => s.rule), contains('No variable present'));
    });

    test('every solve trace has at least one step', () {
      for (final input in const [
        '2*x + 3 = 7',
        'x^2 - 4 = 0',
        'sin(x) = 1/2',
      ]) {
        expect(StepEngine.solve(input, 'x', engine), isNotEmpty,
            reason: 'input=$input');
      }
    });
  });

  group('StepEngine.integrate — rule selection', () {
    List<String> rulesFor(String expr, String variable) =>
        StepEngine.integrate(expr, variable, engine)
            .map((s) => s.rule)
            .toList();

    test('constant rule fires for an integrand without the variable', () {
      final rules = rulesFor('7', 'x');
      expect(rules.first, equals('Constant rule'));
    });

    test('identity / power-rule-1 fires for ∫x dx', () {
      final rules = rulesFor('x', 'x');
      expect(rules.first, equals('Power rule (n=1)'));
    });

    test('power rule fires for ∫x^3 dx with a regular exponent', () {
      final rules = rulesFor('x^3', 'x');
      expect(rules.first, equals('Power rule'));
    });

    test('logarithm rule fires for ∫x^(-1) dx', () {
      final rules = rulesFor('x^-1', 'x');
      expect(rules.first, equals('Logarithm rule'));
    });

    test('logarithm rule also fires for the literal 1/x', () {
      final rules = rulesFor('1/x', 'x');
      expect(rules.first, equals('Logarithm rule'));
    });

    test('sum rule splits ∫(x + 1) dx into a sum step', () {
      final rules = rulesFor('x + 1', 'x');
      expect(rules.first, equals('Sum/difference rule (linearity)'));
      // Should contain at least one sub-rule step from recursing on x and 1.
      expect(rules, contains('Constant rule'));
    });

    test('constant multiple pulls out a constant factor', () {
      final rules = rulesFor('3*x^2', 'x');
      expect(rules.first, equals('Constant multiple'));
      expect(rules, contains('Power rule'));
    });

    test('standard antiderivative fires for ∫sin(x) dx', () {
      final rules = rulesFor('sin(x)', 'x');
      expect(rules.first, equals('Antiderivative of sin'));
    });

    test('falls through to "Symbolic integration" for unrecognized shapes', () {
      // sin(x^2) needs substitution but has no factor of 2x to detect
      // it, so even V3's non-linear u-sub doesn't fire — falls through.
      final rules = rulesFor('sin(x^2)', 'x');
      expect(rules.first, equals('Symbolic integration'));
    });

    test('repeated IBP rule label fires for ∫x^2*sin(x) dx', () {
      // x^2 · sin(x) is the canonical repeated-IBP example. The
      // detection logic doesn't require the bridge (pattern-only),
      // even though the recursion does — so the *first* step is
      // always the IBP step regardless of native availability.
      final rules = rulesFor('x^2*sin(x)', 'x');
      expect(rules.first, equals('Integration by parts'));
    });

    test('first-degree IBP still fires for ∫x*sin(x) dx (V2 path)', () {
      // The new n=1 branch must behave exactly like the V2 path.
      final rules = rulesFor('x*sin(x)', 'x');
      expect(rules.first, equals('Integration by parts'));
    });

    test('every trace ends with a Result step', () {
      for (final expr in const ['7', 'x', 'x^2', 'sin(x)', '3*x^2']) {
        expect(rulesFor(expr, 'x').last, equals('Result'),
            reason: 'expr=$expr');
      }
    });
  });

  group('StepEngine.differentiate — step content', () {
    test('product rule step references both factors in the after string', () {
      final steps = StepEngine.differentiate('x*sin(x)', 'x', engine);
      final productStep = steps.first;
      expect(productStep.after, contains('x'));
      expect(productStep.after, contains('sin'));
    });

    test('chain rule note mentions the inner derivative', () {
      final steps = StepEngine.differentiate('sin(x^2)', 'x', engine);
      expect(steps.first.note, isNotNull);
      expect(steps.first.note, contains('x'));
    });

    test('constant rule note explains the independence', () {
      final steps = StepEngine.differentiate('42', 'x', engine);
      expect(steps.first.note, isNotNull);
      expect(steps.first.note, contains('does not depend'));
    });
  });
}
