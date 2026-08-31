// test/cas_result_format_test.dart
//
// The canonicalizer must do exactly two things: put symbolic results
// into one reading order, and never change what a result means. The
// second half of this file is the important half.

import 'package:crisp_math/engine/cas_result_format.dart';
import 'package:crisp_math/engine/numeric_fallback.dart';
import 'package:flutter_test/flutter_test.dart';

String canon(String s) => canonicalizeCasResult(s);

void main() {
  group('one reading order across the CAS surfaces', () {
    test('sums are highest-degree-first', () {
      // expand() emitted low-degree-first while diff() emitted
      // high-degree-first, for the same algebra.
      expect(canon('1 + 2*x + x**2'), 'x^2 + 2x + 1');
      expect(canon('1 + 3*x + 3*x**2 + x**3'), 'x^3 + 3x^2 + 3x + 1');
      expect(canon('3 + 2*x'), '2x + 3');
    });

    test('factors lead with the variable, not the constant', () {
      // `(x - 1)*(x + 1)` — the same order SymPy prints, and stable
      // because the factors sort by their constant term.
      expect(canon('(1 + x)*(-1 + x)'), '(x - 1)*(x + 1)');
    });

    test('a fractional coefficient is not left looking like a reciprocal', () {
      // `1/3x^3` reads as 1/(3x^3) — a different expression.
      expect(canon('1/3*x**3 + C'), 'x^3/3 + C');
    });

    test('multi-variable terms keep a stable order', () {
      expect(canon('2*x*y + x**2 + y**2'), 'x^2 + 2*x*y + y^2');
    });
  });

  group('leaves alone what it must not touch', () {
    // Each of these would be made worse, not better, by a rewrite.
    const untouched = [
      '2.5', // numeric result
      '0.333333333333',
      '5', // bare integer
      '1.41421356237',
      'x = {2, -2}', // solution set
      'x = -3/2', // equation
      'Matrix([[1, 2], [3, 4]])', // matrix
      '0.0 + 1.0*I', // complex
      '2 + 3*I',
      'inf',
      'Error: division by zero',
      '0.5*x + 1.5', // decimals: rewriting to x/2 + 3/2 changes the style
      '',
    ];

    for (final s in untouched) {
      test('"$s" passes through unchanged', () {
        expect(canon(s), s);
      });
    }

    test('a purely numeric expression is never turned into a fraction', () {
      // The exact-rational printer would render 5/2, undoing whatever
      // the number formatter was asked to produce.
      expect(canon('10/4'), '10/4');
      expect(canon('2/6'), '2/6');
    });
  });

  group('never changes the value', () {
    // The guard that actually matters: whatever comes out has to agree
    // with what went in, checked against an independent evaluator.
    const inputs = [
      '1 + 2*x + x**2',
      '1 + 3*x + 3*x**2 + x**3',
      '(1 + x)*(-1 + x)',
      '1/3*x**3 + C',
      '2*x*y + x**2 + y**2',
      'x + sin(x)',
      '3*x - 7',
      '-x - y',
      'x**2*y/x',
      '2*x + 3*x',
      'a/b/c',
      '1/x + x',
      'sin(x)*cos(x)',
      '(x + 1)/(x + 2)',
    ];

    for (final input in inputs) {
      test('"$input" keeps its value', () {
        final out = canon(input);
        final source = input.replaceAll('**', '^');
        // Sample well away from the tidy points.
        for (final t in [1.7182818, -2.3166248, 0.6180339]) {
          final vars = {
            'x': t,
            'y': t + 0.911,
            'a': t + 1.37,
            'b': t + 2.11,
            'c': t + 3.03,
            'C': t + 4.29,
          };
          final va = NumericFallbackEvaluator.evalNumeric(source, vars);
          final vb = NumericFallbackEvaluator.evalNumeric(out, vars);
          if (va == null || vb == null) continue;
          if (!va.isFinite || !vb.isFinite) continue;
          final scale = va.abs() > 1 ? va.abs() : 1.0;
          expect((va - vb).abs() <= 1e-9 * scale, isTrue,
              reason: '"$input" -> "$out" disagree at $t: $va vs $vb');
        }
      });
    }

    test('is idempotent — reformatting a formatted result is a no-op', () {
      for (final input in inputs) {
        final once = canon(input);
        expect(canon(once), once, reason: '"$input" is not a fixed point');
      }
    });
  });

  group('degrades safely on anything unexpected', () {
    test('unparseable input is returned untouched', () {
      for (final s in ['x +', '((', 'foo bar baz )(', '@@@']) {
        expect(canon(s), s);
      }
    });
  });
}
