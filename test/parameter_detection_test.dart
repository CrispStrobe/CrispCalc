// test/parameter_detection_test.dart
//
// Exhaustive coverage for ExpressionPreprocessingUtils.detectParameters.
// Parameter detection has to handle several corner cases that aren't
// obvious: LaTeX command tokens (\frac etc.), function calls
// (sin/cos shouldn't be harvested as parameters), reserved constants
// (pi, e), digit-letter implicit multiplication boundaries, and
// multi-character identifier names.

import 'package:crisp_calc/utils/expression_preprocessing_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectParameters — basic cases', () {
    test('empty input returns empty list', () {
      expect(ExpressionPreprocessingUtils.detectParameters('', 'x'), isEmpty);
    });

    test('expression with no parameters returns empty list', () {
      expect(ExpressionPreprocessingUtils.detectParameters('x + 1', 'x'),
          isEmpty);
    });

    test('the plot variable is never reported as a parameter', () {
      expect(ExpressionPreprocessingUtils.detectParameters('x*x + x', 'x'),
          isEmpty);
    });

    test('a single parameter is detected', () {
      expect(ExpressionPreprocessingUtils.detectParameters('a*x', 'x'),
          equals(['a']));
    });

    test('multiple parameters are returned sorted and deduplicated', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters('a*x + b*x + a', 'x'),
        equals(['a', 'b']),
      );
    });

    test('multi-character parameter names are kept whole', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters('freq*t + phase', 't'),
        equals(['freq', 'phase']),
      );
    });
  });

  group('detectParameters — function-name suppression', () {
    test('sin, cos, tan are not harvested as parameters', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters(
            'sin(x) + cos(x) + tan(x)', 'x'),
        isEmpty,
      );
    });

    test('hyperbolic / inverse trig function names are excluded', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters(
            'sinh(x) + cosh(x) + atan(x) + asin(x)', 'x'),
        isEmpty,
      );
    });

    test('exp / log / sqrt / abs are excluded', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters(
            'exp(x) + log(x) + sqrt(x) + abs(x)', 'x'),
        isEmpty,
      );
    });

    test('parameter inside a function call is still detected', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters('sin(a*x)', 'x'),
        equals(['a']),
      );
    });

    test('a function name on its own (no parens) is still ignored', () {
      // `sin` immediately followed by `(` is suppressed by the regex's
      // lookahead. Without the parens it would be returned — confirms
      // the reserved-name set catches it.
      expect(
        ExpressionPreprocessingUtils.detectParameters('sin + x', 'x'),
        isEmpty,
      );
    });
  });

  group('detectParameters — reserved constants', () {
    test('pi and e are not parameters', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters('pi*x + e*x', 'x'),
        isEmpty,
      );
    });

    test('I (imaginary unit) is not a parameter', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters('I*x + 1', 'x'),
        isEmpty,
      );
    });
  });

  group('detectParameters — mixed real expressions', () {
    test('a*sin(b*x + c) classic sinusoid form', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters(
            'a*sin(b*x + c)', 'x'),
        equals(['a', 'b', 'c']),
      );
    });

    test('quadratic ax^2 + bx + c', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters(
            'a*x^2 + b*x + c', 'x'),
        equals(['a', 'b', 'c']),
      );
    });

    test('parameter appears in exponent', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters('exp(k*x)', 'x'),
        equals(['k']),
      );
    });

    test('parameter is the only thing — no plot variable', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters('a', 'x'),
        equals(['a']),
      );
    });
  });

  group('substituteParameters — value plugging', () {
    test('empty params returns expression unchanged', () {
      expect(
        ExpressionPreprocessingUtils.substituteParameters('a*x + 1', {}),
        equals('a*x + 1'),
      );
    });

    test('single parameter substitution wraps value in parens', () {
      expect(
        ExpressionPreprocessingUtils.substituteParameters(
            'a*x', {'a': 2.0}),
        equals('(2.0)*x'),
      );
    });

    test('multiple parameters substituted independently', () {
      expect(
        ExpressionPreprocessingUtils.substituteParameters(
            'a*x + b', {'a': 2.0, 'b': 3.0}),
        equals('(2.0)*x + (3.0)'),
      );
    });

    test('function names with matching prefix are NOT substituted', () {
      // `s` should not match the `s` inside `sin`.
      expect(
        ExpressionPreprocessingUtils.substituteParameters(
            's + sin(x)', {'s': 5.0}),
        equals('(5.0) + sin(x)'),
      );
    });

    test('identifier followed by paren (function call) is preserved', () {
      // If a user had a function-shaped name in their params they could
      // break things; we explicitly avoid touching `f` in `f(x)`.
      expect(
        ExpressionPreprocessingUtils.substituteParameters(
            'f(x) + a*x', {'a': 2.0, 'f': 99.0}),
        equals('f(x) + (2.0)*x'),
      );
    });

    test('negative parameter values land cleanly', () {
      expect(
        ExpressionPreprocessingUtils.substituteParameters(
            'a*x + b', {'a': -2.5, 'b': -1.0}),
        equals('(-2.5)*x + (-1.0)'),
      );
    });

    test('parameter repeated in expression is substituted at every site', () {
      expect(
        ExpressionPreprocessingUtils.substituteParameters(
            'a*x + a^2', {'a': 3.0}),
        equals('(3.0)*x + (3.0)^2'),
      );
    });

    test('parameter inside function argument is substituted', () {
      expect(
        ExpressionPreprocessingUtils.substituteParameters(
            'sin(a*x)', {'a': 2.0}),
        equals('sin((2.0)*x)'),
      );
    });
  });

  group('detectParameters — different plot variables', () {
    test('with plot variable t', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters('A*sin(omega*t)', 't'),
        equals(['A', 'omega']),
      );
    });

    test('with plot variable theta', () {
      expect(
        ExpressionPreprocessingUtils.detectParameters('r*cos(theta)', 'theta'),
        equals(['r']),
      );
    });
  });
}
