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
      StepEngine.differentiate(expr, variable, engine).map((s) => s.rule).toList();

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
