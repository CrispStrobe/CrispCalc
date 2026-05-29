// test/polynomial_test.dart
//
// Precision arc Group B — univariate polynomial arithmetic over Q.
// Pure-Dart and fully headless: exact Rational/BigInt coefficients,
// no native bridge. Reference values cross-checked against SymPy.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:crisp_calc/engine/polynomial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Rational r(int n, [int d = 1]) => Rational(BigInt.from(n), BigInt.from(d));

  group('Rational', () {
    test('normalises sign and reduces to lowest terms', () {
      expect(r(2, 4).toString(), '1/2');
      expect(r(3, -6).toString(), '-1/2');
      expect(r(6, 3).toString(), '2');
      expect((r(1, 2) + r(1, 3)).toString(), '5/6');
      expect((r(1, 2) * r(2, 3)).toString(), '1/3');
      expect((r(1, 2) - r(1, 2)).isZero, isTrue);
      expect(r(1, 2) == r(2, 4), isTrue);
    });
  });

  group('Polynomial.tryParse / toString', () {
    test('round-trips common forms', () {
      expect(Polynomial.tryParse('x^3 - 2*x + 1').toString(), 'x^3 - 2x + 1');
      expect(Polynomial.tryParse('2x^2+3x-5').toString(), '2x^2 + 3x - 5');
      expect(Polynomial.tryParse('x').toString(), 'x');
      expect(Polynomial.tryParse('-x^2').toString(), '-x^2');
      expect(Polynomial.tryParse('7').toString(), '7');
      expect(Polynomial.tryParse('x**2 - 1').toString(), 'x^2 - 1');
    });

    test('implicit multiplication and rational coefficients', () {
      expect(Polynomial.tryParse('1/2x + 3').toString(), '1/2x + 3');
      expect(Polynomial.tryParse('3x - 3x').toString(), '0'); // cancels
    });

    test('detects the variable (any single letter)', () {
      expect(Polynomial.tryParse('t^2 - 1')!.variable, 't');
      expect(Polynomial.tryParse('y^2 - 1').toString(), 'y^2 - 1');
    });

    test('rejects unsupported input', () {
      expect(Polynomial.tryParse('x*y - 1'), isNull); // multivariate
      expect(Polynomial.tryParse('(x-1)(x+1)'), isNull); // parentheses
      expect(Polynomial.tryParse(''), isNull);
      expect(Polynomial.tryParse('x^-2'), isNull); // negative exponent
    });
  });

  group('Polynomial.gcd (monic, over Q)', () {
    String g(String a, String b) =>
        Polynomial.gcd(Polynomial.tryParse(a)!, Polynomial.tryParse(b)!)
            .toString();

    test('classroom GCDs', () {
      expect(g('x^2-1', 'x^2-2*x+1'), 'x - 1');
      expect(g('x^3-1', 'x^2-1'), 'x - 1');
      expect(g('x^2-3*x+2', 'x^2-4*x+3'), 'x - 1');
      // coprime → monic constant 1
      expect(g('x^2+1', 'x-1'), '1');
    });

    test('content is normalised away (result is monic)', () {
      expect(g('2*x^2-2', '6*x-6'), 'x - 1');
    });
  });

  group('Polynomial.resultant (Sylvester determinant)', () {
    String res(String a, String b) =>
        Polynomial.resultant(Polynomial.tryParse(a)!, Polynomial.tryParse(b)!)
            .toString();

    test('zero iff a common non-constant factor exists', () {
      expect(res('x^2-1', 'x-1'), '0');
      expect(res('x^2-5*x+6', 'x-2'), '0');
    });

    test('non-zero for coprime pairs', () {
      expect(res('x^2+1', 'x'), '1');
      expect(res('x^2-2', 'x^2-3'), '1');
    });
  });

  group('Polynomial.discriminant', () {
    String disc(String a) =>
        Polynomial.discriminant(Polynomial.tryParse(a)!).toString();

    test('quadratics: b^2 - 4c', () {
      expect(disc('x^2-5*x+6'), '1'); // 25 - 24
      expect(disc('x^2+1'), '-4');
      expect(disc('x^2-4*x+4'), '0'); // repeated root
    });

    test('cubics', () {
      expect(disc('x^3-2'), '-108');
      expect(disc('x^3-x'), '4');
    });
  });

  group('polyfactor over F_p (SFF + Berlekamp)', () {
    final engine = CalculatorEngine();
    String pf(String poly, int p) => engine.polyfactor(poly, p);

    test('distinct linear factors', () {
      // x^2 - 1 = (x-1)(x+1); mod 5 the −1 shows as +4.
      expect(pf('x^2-1', 5), '(x + 1) · (x + 4)');
      // x^3 - x = x(x-1)(x+1); mod 7 → x(x+1)(x+6).
      expect(pf('x^3-x', 7), '(x) · (x + 1) · (x + 6)');
    });

    test('repeated factors (square-free factorisation kicks in)', () {
      expect(pf('x^2+1', 2), '(x + 1)^2');
      expect(pf('x^4+1', 2), '(x + 1)^4');
      // x^6+x^5+x+1 = (x+1)^2 (x^4+x^3+x^2+x+1) mod 2.
      expect(pf('x^6+x^5+x+1', 2), '(x + 1)^2 · (x^4 + x^3 + x^2 + x + 1)');
    });

    test('irreducible polynomials are returned whole', () {
      expect(pf('x^3+x+1', 2), '(x^3 + x + 1)');
      expect(pf('x^2+x+1', 2), '(x^2 + x + 1)');
    });

    test('non-monic input keeps the leading coefficient out front', () {
      // 2x^2+2 = 2(x^2+1) = 2(x-2)(x-3) mod 5 → 2·(x+2)(x+3).
      expect(pf('2x^2+2', 5), '2 · (x + 2) · (x + 3)');
    });

    test('factors differently over different primes', () {
      // x^4+1 is irreducible over Q but splits mod every prime.
      expect(pf('x^4+1', 5), '(x^2 + 2) · (x^2 + 3)');
    });

    test('dispatch accepts mod= syntax and validates the modulus', () {
      expect(engine.tryEvaluatePrecisionCall('polyfactor(x^2-1, mod=5)'),
          '(x + 1) · (x + 4)');
      expect(engine.tryEvaluatePrecisionCall('polyfactor(x^2-1, 5)'),
          '(x + 1) · (x + 4)');
      expect(engine.polyfactor('x^2-1', 4), startsWith('Error')); // 4 not prime
    });
  });

  group('CalculatorEngine polynomial dispatch (headless)', () {
    final engine = CalculatorEngine();

    test('direct engine methods', () {
      expect(engine.polygcd('x^2-1', 'x^2-2*x+1'), 'x - 1');
      expect(engine.polyresultant('x^2+1', 'x'), '1');
      expect(engine.polydiscriminant('x^2-5*x+6'), '1');
    });

    test('through tryEvaluatePrecisionCall', () {
      expect(engine.tryEvaluatePrecisionCall('polygcd(x^2-1, x-1)'), 'x - 1');
      expect(engine.tryEvaluatePrecisionCall('polyresultant(x^2-1, x-1)'), '0');
      expect(
          engine.tryEvaluatePrecisionCall('polydiscriminant(x^3-2)'), '-108');
      // unrelated input still falls through.
      expect(engine.tryEvaluatePrecisionCall('2 + 2'), isNull);
    });

    test('error messages for bad input', () {
      expect(engine.polygcd('x*y', 'x'), startsWith('Error'));
      expect(engine.polydiscriminant('5'), startsWith('Error')); // degree 0
    });
  });
}
