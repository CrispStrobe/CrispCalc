import 'package:flutter_test/flutter_test.dart';
import 'package:crisp_calc/utils/latex_conversion_utils.dart';

void main() {
  group('fromLatex — roots and fractions', () {
    test('\\sqrt{x} -> sqrt(x)', () {
      expect(
          LatexConversionUtils.fromLatex(r'\sqrt{x+1}'), equals('sqrt(x+1)'));
    });

    test('\\sqrt[3]{x} -> (x)^(1/3)', () {
      expect(
          LatexConversionUtils.fromLatex(r'\sqrt[3]{x}'), equals('(x)^(1/3)'));
    });

    test('\\frac{a}{b} -> (a)/(b)', () {
      expect(LatexConversionUtils.fromLatex(r'\frac{a}{b}'), equals('(a)/(b)'));
    });
  });

  group('fromLatex — trig and inverse trig', () {
    test('plain function braces unwrap', () {
      expect(LatexConversionUtils.fromLatex(r'\sin{x}'), equals('sin(x)'));
      expect(LatexConversionUtils.fromLatex(r'\cos{x}'), equals('cos(x)'));
    });

    test('arc-prefix maps to a-prefix', () {
      expect(LatexConversionUtils.fromLatex(r'\arcsin{x}'), equals('asin(x)'));
      expect(LatexConversionUtils.fromLatex(r'\arctan{x}'), equals('atan(x)'));
    });

    test('hyperbolic and inverse hyperbolic', () {
      expect(LatexConversionUtils.fromLatex(r'\sinh{x}'), equals('sinh(x)'));
      expect(LatexConversionUtils.fromLatex(r'\asinh{x}'), equals('asinh(x)'));
    });

    test('function-paren forms strip the backslash', () {
      expect(LatexConversionUtils.fromLatex(r'\sin(x)'), equals('sin(x)'));
    });
  });

  group('fromLatex — logs', () {
    test('\\ln{x} and \\log{x}', () {
      expect(LatexConversionUtils.fromLatex(r'\ln{x}'), equals('ln(x)'));
      expect(LatexConversionUtils.fromLatex(r'\log{x}'), equals('log(x)'));
    });

    test('logarithm with base', () {
      expect(
        LatexConversionUtils.fromLatex(r'\log_{2}{8}'),
        equals('log(8)/log(2)'),
      );
    });
  });

  group('fromLatex — powers and subscripts', () {
    test('single-char power keeps braces off', () {
      expect(LatexConversionUtils.fromLatex(r'x^{2}'), equals('x^2'));
    });

    test('multi-char power keeps parens', () {
      expect(LatexConversionUtils.fromLatex(r'x^{2y}'), equals('x^(2y)'));
    });

    test('subscript braces collapse', () {
      expect(LatexConversionUtils.fromLatex(r'x_{1}'), equals('x_1'));
    });
  });

  group('fromLatex — constants and symbols', () {
    test('\\pi -> pi', () {
      expect(LatexConversionUtils.fromLatex(r'2\pi r'), contains('pi'));
    });

    test('\\infty -> oo', () {
      expect(LatexConversionUtils.fromLatex(r'\infty'), equals('oo'));
    });

    test('\\cdot, \\times -> *', () {
      expect(LatexConversionUtils.fromLatex(r'2 \cdot x'), equals('2*x'));
      expect(LatexConversionUtils.fromLatex(r'2 \times x'), equals('2*x'));
    });
  });

  group('fromLatex — integrals and limits', () {
    test('indefinite integral', () {
      expect(
        LatexConversionUtils.fromLatex(r'\int x dx'),
        equals('integrate(x, x)'),
      );
    });

    test('definite integral', () {
      final out = LatexConversionUtils.fromLatex(r'\int_{0}^{1} x dx');
      expect(out, equals('integrate(x, (x, 0, 1))'));
    });

    test('basic limit', () {
      final out = LatexConversionUtils.fromLatex(r'\lim_{x \to 0} sin(x)/x');
      expect(out, equals('limit(sin(x)/x, x, 0)'));
    });
  });

  group('fromLatex — absolute value', () {
    test('|x| -> abs(x)', () {
      expect(LatexConversionUtils.fromLatex(r'|x+1|'), equals('abs(x+1)'));
    });
  });

  // Note: pipe characters used to be unconditionally stripped (under the
  // assumption that they were cursor markers from textWithCursor). That broke
  // |x| -> abs(x). Pipes are now content; the cursor marker lives in the
  // controller's selection state, not in the text itself.

  group('latexToReadable', () {
    test('\\cdot back to *', () {
      expect(LatexConversionUtils.latexToReadable(r'2\cdot x'), equals('2*x'));
    });

    test('\\frac{a}{b} back to parenthesized fraction', () {
      expect(
        LatexConversionUtils.latexToReadable(r'\frac{a}{b}'),
        equals('(a)/(b)'),
      );
    });

    test('strips function backslashes', () {
      expect(LatexConversionUtils.latexToReadable(r'\sin'), equals('sin'));
    });
  });
}
