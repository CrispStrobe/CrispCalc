import 'package:flutter_test/flutter_test.dart';
import 'package:crisp_calc/utils/math_display_utils.dart';

void main() {
  group('toLatexFormat', () {
    test('passes through expressions that already have LaTeX commands', () {
      const input = r'\frac{1}{x}';
      expect(MathDisplayUtils.toLatexFormat(input), equals(input));
    });

    test('converts sqrt(x) to \\sqrt{x}', () {
      expect(
        MathDisplayUtils.toLatexFormat('sqrt(x+1)'),
        equals(r'\sqrt{x+1}'),
      );
    });

    test('converts pi to \\pi', () {
      expect(MathDisplayUtils.toLatexFormat('2pi'), contains(r'\pi'));
    });

    test('marks standard functions as upright', () {
      expect(MathDisplayUtils.toLatexFormat('sin(x)'), contains(r'\sin'));
      expect(MathDisplayUtils.toLatexFormat('log(x)'), contains(r'\log'));
    });

    test('converts * to \\cdot ', () {
      expect(MathDisplayUtils.toLatexFormat('2*x'), contains(r'\cdot'));
    });

    test('converts integrate(expr, x) to \\int', () {
      expect(
        MathDisplayUtils.toLatexFormat('integrate(x, x)'),
        contains(r'\int'),
      );
    });

    test('converts limit(expr, x, 0) to \\lim_{x \\to 0}', () {
      expect(
        MathDisplayUtils.toLatexFormat('limit(sin(x)/x, x, 0)'),
        contains(r'\lim_{x \to 0}'),
      );
    });
  });

  group('toHistoryDisplayLatex', () {
    test('passes empty strings through', () {
      expect(MathDisplayUtils.toHistoryDisplayLatex(''), equals(''));
    });

    test('strips cursor artifacts from LaTeX content', () {
      expect(
        MathDisplayUtils.toHistoryDisplayLatex(r'\frac{1}{2}\|'),
        equals(r'\frac{1}{2}'),
      );
    });
  });

  group('formatMathResult', () {
    test('returns Error and empty unchanged', () {
      expect(MathDisplayUtils.formatMathResult(''), equals(''));
      expect(MathDisplayUtils.formatMathResult('Error'), equals('Error'));
    });

    test('formats results containing sqrt as LaTeX', () {
      expect(
        MathDisplayUtils.formatMathResult('sqrt(2)'),
        contains(r'\sqrt'),
      );
    });
  });

  group('createDisplayFormats', () {
    test('returns both raw and latex keys', () {
      final formats = MathDisplayUtils.createDisplayFormats('x^2');
      expect(formats.keys, containsAll(['raw', 'latex']));
      expect(formats['raw'], equals('x^2'));
    });
  });
}
