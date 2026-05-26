// test/parsing_pipeline_test.dart
//
// Comprehensive parsing-pipeline coverage — LaTeX conversion,
// expression preprocessing, sized-delimiter normalization,
// inline-CAS detection. These are all pure-Dart string transforms
// (no engine dependency) so the suite is fast and deterministic;
// regressions in dispatch-table prefix matching, fraction
// rewrites, factorial expansion, etc. should land here as a
// failing case before they reach the running app.

import 'package:crisp_calc/utils/expression_preprocessing_utils.dart';
import 'package:crisp_calc/utils/latex_conversion_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LatexConversionUtils.fromLatex — basic operators', () {
    final cases = <String, String>{
      r'2\cdot 3': '2*3',
      r'2\cdot3': '2*3',
      r'a\times b': 'a*b',
      r'6\div 2': '6/2',
      r'\pi': 'pi', // fromLatex strips the backslash; SymEngine takes 'pi'
      r'2\cdot\pi': '2*pi',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(LatexConversionUtils.fromLatex(input), want);
      });
    });
  });

  group('LatexConversionUtils.fromLatex — sqrt + roots', () {
    final cases = <String, String>{
      r'\sqrt{4}': 'sqrt(4)',
      r'\sqrt{x+1}': 'sqrt(x+1)',
      r'\sqrt[3]{8}': '(8)^(1/3)',
      r'\sqrt[n]{x}': '(x)^(1/n)',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(LatexConversionUtils.fromLatex(input), want);
      });
    });
  });

  group('LatexConversionUtils.fromLatex — fractions', () {
    final cases = <String, String>{
      r'\frac{1}{2}': '(1)/(2)',
      r'\frac{x+1}{x-1}': '(x+1)/(x-1)',
      r'\frac{a}{b}+\frac{c}{d}': '(a)/(b)+(c)/(d)',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(LatexConversionUtils.fromLatex(input), want);
      });
    });
  });

  group('LatexConversionUtils.fromLatex — d/dx detection', () {
    // The differentiation rewrite must beat the generic \frac
    // rewrite to the punch, otherwise `\frac{d}{dx}` collapses
    // into `(d)/(dx)` and the dispatch can't route it.
    final cases = <String, String>{
      // Bare parens
      r'\frac{d}{dx}(x^2)': 'd/dx(x^2)',
      r'\frac{d}{dy}(y^3)': 'd/dy(y^3)',
      // Braced form
      r'\frac{d}{dx}{x^2}': 'd/dx(x^2)',
      // Sized delimiters
      r'\frac{d}{dx}\Big(x^2\Big)': 'd/dx(x^2)',
      r'\frac{d}{dx}\bigg(x^2\bigg)': 'd/dx(x^2)',
      r'\frac{d}{dx}\Bigg(x^2\Bigg)': 'd/dx(x^2)',
      r'\frac{d}{dx}\left(x^2\right)': 'd/dx(x^2)',
      // With space between sized-delim command and bracket
      r'\frac{d}{dx}\bigg (x^2\bigg )': 'd/dx(x^2)',
      // Inside compound expression
      r'2+\frac{d}{dx}\bigg(3\cdot x\bigg)': '2+d/dx(3*x)',
      r'a+\frac{d}{dy}(y^2)+b': 'a+d/dy(y^2)+b',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(LatexConversionUtils.fromLatex(input), want);
      });
    });
  });

  group('LatexConversionUtils.fromLatex — sized-delimiter strip', () {
    final cases = <String, String>{
      r'\left(x\right)': '(x)',
      r'\left[x\right]': '[x]',
      r'\Big(x\Big)': '(x)',
      r'\bigg(x\bigg)': '(x)',
      r'\Bigg(x\Bigg)': '(x)',
      // Whitespace between command and bracket
      r'\bigg (x\bigg )': '(x)',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(LatexConversionUtils.fromLatex(input), want);
      });
    });
  });

  group('LatexConversionUtils.fromLatex — trig + log + functions', () {
    final cases = <String, String>{
      r'\sin{x}': 'sin(x)',
      r'\cos{2x}': 'cos(2x)',
      r'\tan{\pi/4}': 'tan(pi/4)',
      r'\arcsin{x}': 'asin(x)',
      r'\sinh{x}': 'sinh(x)',
      r'\ln{x}': 'ln(x)',
      r'\log{x}': 'log(x)',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(LatexConversionUtils.fromLatex(input), want);
      });
    });
  });

  group('LatexConversionUtils.latexToReadable — display', () {
    final cases = <String, String>{
      r'\cdot': '*',
      r'2\cdot 3': '2*3',
      r'\times': '*',
      r'\div': '/',
      r'\frac{d}{dx}': '(d)/(dx)',
      // Sized-delimiter strip in readable form (just the bracket)
      r'\bigg(x\bigg)': '(x)',
      r'\Big(x\Big)': '(x)',
      r'\left(x\right)': '(x)',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(LatexConversionUtils.latexToReadable(input), want);
      });
    });
  });

  group(
      'ExpressionPreprocessingUtils.preprocessNativeExpression — '
      'implicit multiplication', () {
    final cases = <String, String>{
      '2(3+4)': '2*(3+4)',
      ')(': ')*(',
      ')2': ')*2',
      ')x': ')*x',
      '(2)(3)': '(2)*(3)',
      // Single letter then paren = function-like → leave alone? Actually
      // the rule is `\b[a-zA-Z]\b(\()` so single letters do get a `*`.
      'a(b)': 'a*(b)',
      // Multi-letter ident — NOT touched (would break `sin(x)`).
      'sin(x)': 'sin(x)',
      'cos(2x)': 'cos(2x)',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(
          ExpressionPreprocessingUtils.preprocessNativeExpression(input),
          want,
        );
      });
    });
  });

  group(
      'ExpressionPreprocessingUtils.preprocessNativeExpression — '
      'factorial BigInt expansion', () {
    final cases = <int, String>{
      0: '1',
      1: '1',
      2: '2',
      5: '120',
      10: '3628800',
      20: '2432902008176640000',
      // 25! = 15511210043330985984000000 (25 digits) — must be exact,
      // not gamma'd to a float.
      25: '15511210043330985984000000',
    };
    cases.forEach((n, want) {
      test('$n! -> "$want"', () {
        final got =
            ExpressionPreprocessingUtils.preprocessNativeExpression('$n!');
        expect(got, want);
      });
    });
    test('100! is 158 digits all-digit string (BigInt path)', () {
      final got =
          ExpressionPreprocessingUtils.preprocessNativeExpression('100!');
      expect(got.length, 158);
      expect(RegExp(r'^\d+$').hasMatch(got), isTrue,
          reason: 'all digits, no scientific notation');
    });
    test('1001! falls back to gamma', () {
      final got =
          ExpressionPreprocessingUtils.preprocessNativeExpression('1001!');
      expect(got, 'gamma(1002)');
    });
    test('variable factorial -> gamma form', () {
      final got = ExpressionPreprocessingUtils.preprocessNativeExpression('n!');
      expect(got, 'gamma(n + 1)');
    });
  });

  group(
      'ExpressionPreprocessingUtils.preprocessNativeExpression — '
      'fib + isprime', () {
    final fib = <int, String>{
      0: '0',
      1: '1',
      2: '1',
      5: '5',
      10: '55',
      20: '6765',
      45: '1134903170',
      90: '2880067194370816120',
    };
    fib.forEach((n, want) {
      test('fib($n) -> "$want"', () {
        final got =
            ExpressionPreprocessingUtils.preprocessNativeExpression('fib($n)');
        expect(got, want);
      });
    });
    test('fib(91) delegates to fibonacci', () {
      final got =
          ExpressionPreprocessingUtils.preprocessNativeExpression('fib(91)');
      expect(got, 'fibonacci(91)');
    });
    final prime = <int, String>{
      0: 'false',
      1: 'false',
      2: 'true',
      3: 'true',
      4: 'false',
      11: 'true',
      99: 'false',
      101: 'true',
    };
    prime.forEach((n, want) {
      test('isprime($n) -> "$want"', () {
        final got = ExpressionPreprocessingUtils.preprocessNativeExpression(
            'isprime($n)');
        expect(got, want);
      });
    });
  });

  group(
      'ExpressionPreprocessingUtils.preprocessNativeExpression — '
      'matrix literal + German comma', () {
    test('[1,2; 3,4] -> Matrix syntax', () {
      final got =
          ExpressionPreprocessingUtils.preprocessNativeExpression('[1,2; 3,4]');
      expect(got, contains('Matrix'));
      expect(got, contains('[1, 2]'));
      expect(got, contains('[3, 4]'));
    });
    test('German comma between digits -> period', () {
      final got =
          ExpressionPreprocessingUtils.preprocessNativeExpression('3,14');
      expect(got, '3.14');
    });
    test('1,000.5 — only the digit-digit comma gets period-ified', () {
      // The rule converts `(\d),(\d)` to `\1.\2` only between digits.
      // So `1,000.5` becomes `1.000.5` — quirky but documented.
      final got =
          ExpressionPreprocessingUtils.preprocessNativeExpression('1,000.5');
      expect(got, '1.000.5');
    });
  });

  group(
      'ExpressionPreprocessingUtils.preprocessNativeExpression — '
      'a mod b', () {
    final cases = <String, String>{
      '5 mod 3': '(5) % (3)',
      'x mod 7': '(x) % (7)',
      // The `mod` rule is greedy on the LHS — captures the
      // entire `\S+` before the ` mod `, which is `a+b` here.
      'a+b mod c': '(a+b) % (c)',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(
          ExpressionPreprocessingUtils.preprocessNativeExpression(input),
          want,
        );
      });
    });
  });

  group('LatexConversionUtils — round-trips for typical user input', () {
    // End-to-end: keypad-inserted LaTeX → fromLatex → engine-ready
    // string. Mirrors the actual calculator pipeline.
    final cases = <String, String>{
      r'2+\frac{d}{dx}\bigg(3\cdot x\bigg)': '2+d/dx(3*x)',
      r'\sqrt{x^2+1}': 'sqrt(x^2+1)',
      r'\frac{1}{2}\cdot x^2': '(1)/(2)*x^2',
      r'\sin{x}+\cos{x}': 'sin(x)+cos(x)',
      r'\ln{e}': 'ln(e)',
      r'2\cdot\pi\cdot r': '2*pi*r',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(LatexConversionUtils.fromLatex(input), want);
      });
    });
  });
}
