// test/precision_test.dart
//
// Rounds 85 + 86 (precision arc) — end-to-end tests for pi(N),
// e(N), EulerGamma(N), sqrt(2, N). Exercises the three-repo chain
// (math-stack-ios-builder C wrapper → symbolic_math_bridge Dart
// FFI → CrispCalc engine binding) by asking for each constant at
// several precisions and verifying against known reference prefixes.
//
// Each test skips silently when the native bridge isn't available
// (Linux CI runs without the macOS xcframework). Detection: the
// engine method returns the standard double-precision fallback,
// which is the inlined `_*Fallback` constant for that test group.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

// Reference prefixes (≥ 100 decimal digits).
// Sources: https://oeis.org for π, e, γ; computed from MPFR for √2.
const _piRef = '3.141592653589793238462643383279502884197169399375105820974944'
    '5923078164062862089986280348253421170679';
const _piFallback = '3.141592653589793';

const _eRef = '2.7182818284590452353602874713526624977572470936999595749669676'
    '27724076630353547594571382178525166427';
const _eFallback = '2.718281828459045';

const _eulerGammaRef =
    '0.57721566490153286060651209008240243104215933593992359880576723'
    '48848677267776646709369470632917467495';
const _eulerGammaFallback = '0.5772156649015329';

// √2 ≈ 1.41421356... (computed with MPFR / OEIS A002193).
const _sqrt2Ref =
    '1.4142135623730950488016887242096980785696718753769480731766797'
    '37990732478462107038850387534327641573';
const _sqrt2Fallback = '1.4142135623730951';

void main() {
  final engine = CalculatorEngine();

  // Per-constant smoke test factory. [getter] takes the digit count
  // and returns the precision string; [ref] is the reference prefix;
  // [fallback] is the double-precision string returned when the
  // bridge isn't loaded — when [getter] returns it, we skip.
  void runPrecisionGroup({
    required String label,
    required String Function(int) getter,
    required String ref,
    required String fallback,
  }) {
    group('CalculatorEngine.get${label}WithPrecision', () {
      test('$label(50) returns the first 50 decimal digits', () {
        final result = getter(50);
        if (result == fallback) return; // headless skip
        expect(result.length, greaterThanOrEqualTo(51),
            reason: '$label(50) too short: $result');
        expect(result.substring(0, 52), ref.substring(0, 52),
            reason: '$label(50) prefix mismatch');
      });

      test('$label(100) returns the first 100 decimal digits', () {
        final result = getter(100);
        if (result == fallback) return;
        expect(result.length, greaterThanOrEqualTo(101),
            reason: '$label(100) too short: $result');
        expect(result.substring(0, 102), ref.substring(0, 102),
            reason: '$label(100) prefix mismatch');
      });

      test('$label(0) rejected with ArgumentError', () {
        expect(() => getter(0), throwsArgumentError);
      });

      test('$label(10001) rejected with ArgumentError', () {
        expect(() => getter(10001), throwsArgumentError);
      });
    });
  }

  // Round 85.
  runPrecisionGroup(
    label: 'pi',
    getter: engine.getPiWithPrecision,
    ref: _piRef,
    fallback: _piFallback,
  );

  // pi(500) — round-85 stress test, kept separate because it asserts
  // result-length-not-just-prefix.
  group('CalculatorEngine.getpiWithPrecision (extras)', () {
    test('pi(500) has enough digits and the first 100 still match', () {
      final result = engine.getPiWithPrecision(500);
      if (result == _piFallback) return;
      expect(result.length, greaterThanOrEqualTo(501),
          reason: 'pi(500) too short: $result');
      expect(result.substring(0, 102), _piRef.substring(0, 102),
          reason: 'pi(500) first 100 digits should still match pi');
    });
  });

  // Round 86.
  runPrecisionGroup(
    label: 'e',
    getter: engine.getEWithPrecision,
    ref: _eRef,
    fallback: _eFallback,
  );

  runPrecisionGroup(
    label: 'eulerGamma',
    getter: engine.getEulerGammaWithPrecision,
    ref: _eulerGammaRef,
    fallback: _eulerGammaFallback,
  );

  runPrecisionGroup(
    label: 'sqrt2',
    getter: engine.getSqrt2WithPrecision,
    ref: _sqrt2Ref,
    fallback: _sqrt2Fallback,
  );

  // Round 89: number-theory primitives.
  group('CalculatorEngine.isprime', () {
    test('classroom truth table for small inputs', () {
      // The headless fallback covers these too — works whether or
      // not the native bridge is loaded.
      expect(engine.isprime('0'), isFalse);
      expect(engine.isprime('1'), isFalse);
      expect(engine.isprime('2'), isTrue);
      expect(engine.isprime('3'), isTrue);
      expect(engine.isprime('4'), isFalse);
      expect(engine.isprime('5'), isTrue);
      expect(engine.isprime('17'), isTrue);
      expect(engine.isprime('100'), isFalse);
    });

    test('large prime via GMP Miller-Rabin', () {
      // 2^31 - 1 = 2147483647 is a Mersenne prime (M31). Within
      // int range, so the Dart fallback also handles it.
      expect(engine.isprime('2147483647'), isTrue);
    });

    test('arbitrary-precision composite (skipped without bridge)', () {
      // 2^64 + 1 = 18446744073709551617 is composite (= 274177 ×
      // 67280421310721). Only the native bridge handles this; the
      // headless fallback (int.tryParse) returns null → false,
      // which happens to be correct here.
      final v = engine.isprime('18446744073709551617');
      expect(v, isFalse, reason: 'F6 = 2^64+1 is composite');
    });
  });

  group('CalculatorEngine.nextprime / prevprime', () {
    test('nextprime small classroom values', () {
      if (!engine.isNativeAvailable) return; // headless skip
      expect(engine.nextprime('1'), '2');
      expect(engine.nextprime('2'), '3');
      expect(engine.nextprime('10'), '11');
      expect(engine.nextprime('100'), '101');
    });

    test('prevprime small classroom values', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.prevprime('3'), '2');
      expect(engine.prevprime('5'), '3');
      expect(engine.prevprime('100'), '97');
      expect(engine.prevprime('1000'), '997');
    });

    test('prevprime errors when no prime below input', () {
      if (!engine.isNativeAvailable) return;
      // No prime < 2.
      expect(engine.prevprime('2'), startsWith('Error'));
      expect(engine.prevprime('1'), startsWith('Error'));
    });
  });

  group('CalculatorEngine.factorint (round 90)', () {
    test('trivial values: 0, 1 return empty list', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.factorint('0'), isEmpty);
      expect(engine.factorint('1'), isEmpty);
    });

    test('small primes return single (p, 1)', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.factorint('2'), equals([(prime: 2, exponent: 1)]));
      expect(engine.factorint('7'), equals([(prime: 7, exponent: 1)]));
      expect(engine.factorint('101'), equals([(prime: 101, exponent: 1)]));
    });

    test('360 = 2^3 * 3^2 * 5', () {
      if (!engine.isNativeAvailable) return;
      expect(
          engine.factorint('360'),
          equals([
            (prime: 2, exponent: 3),
            (prime: 3, exponent: 2),
            (prime: 5, exponent: 1),
          ]));
    });

    test('1000000 = 2^6 * 5^6', () {
      if (!engine.isNativeAvailable) return;
      expect(
          engine.factorint('1000000'),
          equals([
            (prime: 2, exponent: 6),
            (prime: 5, exponent: 6),
          ]));
    });

    test('repunit 11 (a Mersenne-like prime) returns single factor', () {
      if (!engine.isNativeAvailable) return;
      // 2^31 - 1 = 2147483647 is the Mersenne prime M31.
      expect(engine.factorint('2147483647'),
          equals([(prime: 2147483647, exponent: 1)]));
    });

    test('input above the 90-bit cap surfaces "too large" via bridge', () {
      if (!engine.isNativeAvailable) return;
      // 2^120 = ~36 digits, well above the cap.
      const big = '1329227995784915872903807060280344576';
      expect(
          () => engine.factorint(big),
          throwsA(predicate((e) =>
              e.toString().toLowerCase().contains('too large') ||
              e.toString().toLowerCase().contains('factorint'))));
    });
  });

  // Round 4 (precision arc): modular arithmetic + multiplicative
  // number theory. The native-backed methods gate on isNativeAvailable
  // (bigint, no headless fallback); divisor enumeration is pure-Dart
  // and tested directly.
  group('CalculatorEngine.modpow (round 4)', () {
    test('classroom values', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.modpow('2', '10', '1000'), '24'); // 1024 mod 1000
      expect(engine.modpow('2', '100', '1000000007'), '976371285');
      expect(engine.modpow('7', '0', '13'), '1'); // a^0 = 1
      expect(engine.modpow('10', '3', '1'), '0'); // everything mod 1
    });

    test('negative exponent uses the modular inverse', () {
      if (!engine.isNativeAvailable) return;
      // 3^-1 mod 11 = 4, so 3^-1 mod 11 == modinv(3, 11).
      expect(engine.modpow('3', '-1', '11'), '4');
    });

    test('negative exponent without an inverse errors', () {
      if (!engine.isNativeAvailable) return;
      // gcd(2, 10) = 2 ≠ 1 → no inverse.
      expect(() => engine.modpow('2', '-1', '10'), throwsA(anything));
    });
  });

  group('CalculatorEngine.modinv (round 4)', () {
    test('classroom values', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.modinv('3', '11'), '4'); // 3·4 = 12 ≡ 1 (mod 11)
      expect(engine.modinv('7', '26'), '15'); // 7·15 = 105 ≡ 1 (mod 26)
    });

    test('errors when gcd(a, m) != 1', () {
      if (!engine.isNativeAvailable) return;
      expect(() => engine.modinv('2', '4'), throwsA(anything));
    });
  });

  group('CalculatorEngine.totient (round 4)', () {
    test('classroom values', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.totient('1'), '1');
      expect(engine.totient('12'), '4'); // {1,5,7,11}
      expect(engine.totient('360'), '96');
      expect(engine.totient('97'), '96'); // prime p → p-1
    });

    test('non-positive input errors', () {
      if (!engine.isNativeAvailable) return;
      expect(() => engine.totient('0'), throwsA(anything));
    });
  });

  group('CalculatorEngine.jacobi (round 4)', () {
    test('classroom values', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.jacobi('2', '7'), '1'); // 2 is a QR mod 7
      expect(engine.jacobi('3', '7'), '-1'); // 3 is a non-residue mod 7
      expect(engine.jacobi('6', '9'), '0'); // gcd(6, 9) ≠ 1
      expect(engine.jacobi('1', '1'), '1');
    });

    test('even or non-positive n errors', () {
      if (!engine.isNativeAvailable) return;
      expect(() => engine.jacobi('3', '8'), throwsA(anything));
    });
  });

  group('CalculatorEngine.divisorsFromFactors (round 4, pure-Dart)', () {
    test('empty factorization (n = 1) yields [1]', () {
      expect(CalculatorEngine.divisorsFromFactors(const []), equals([1]));
    });

    test('single prime power 2^3 = 8 → 1,2,4,8', () {
      expect(
          CalculatorEngine.divisorsFromFactors(const [(prime: 2, exponent: 3)]),
          equals([1, 2, 4, 8]));
    });

    test('12 = 2^2·3 → 1,2,3,4,6,12 (sorted)', () {
      expect(
          CalculatorEngine.divisorsFromFactors(const [
            (prime: 2, exponent: 2),
            (prime: 3, exponent: 1),
          ]),
          equals([1, 2, 3, 4, 6, 12]));
    });

    test('36 = 2^2·3^2 → nine divisors', () {
      expect(
          CalculatorEngine.divisorsFromFactors(const [
            (prime: 2, exponent: 2),
            (prime: 3, exponent: 2),
          ]),
          equals([1, 2, 3, 4, 6, 9, 12, 18, 36]));
    });
  });

  group('CalculatorEngine.divisors (round 4, end-to-end)', () {
    test('divisors(1) = [1] without the bridge', () {
      expect(engine.divisors('1'), equals([1]));
    });

    test('divisors(0) is undefined', () {
      expect(() => engine.divisors('0'), throwsStateError);
    });

    test('classroom values via the native bridge', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.divisors('12'), equals([1, 2, 3, 4, 6, 12]));
      expect(engine.divisors('28'), equals([1, 2, 4, 7, 14, 28]));
      expect(engine.divisors('-12'), equals([1, 2, 3, 4, 6, 12]));
    });
  });

  // Group B (precision arc): continued fractions. The pure-Dart core
  // (BigInt expansion + convergent folding) runs headlessly; the
  // constant-backed dispatch tests gate on the bridge for full
  // precision but the fallback double still yields the leading terms.
  group('CalculatorEngine continued fractions (Group B, pure-Dart)', () {
    BigInt b(int v) => BigInt.from(v);

    test('rational 415/93 → [4, 2, 6, 7]', () {
      expect(CalculatorEngine.continuedFractionOfRational(b(415), b(93), 10),
          equals([b(4), b(2), b(6), b(7)]));
    });

    test('rational 43/19 → [2, 3, 1, 4]', () {
      expect(CalculatorEngine.continuedFractionOfRational(b(43), b(19), 10),
          equals([b(2), b(3), b(1), b(4)]));
    });

    test('terminating rational stops early (maxTerms not reached)', () {
      // 415/93 has exactly 4 partial quotients.
      expect(CalculatorEngine.continuedFractionOfRational(b(415), b(93), 50),
          hasLength(4));
    });

    test('integer → single term', () {
      expect(CalculatorEngine.continuedFractionOfRational(b(7), b(1), 5),
          equals([b(7)]));
    });

    test('negative value floors a₀ and keeps later terms positive', () {
      // -415/93 = [-5; 1, 1, 6, 7]  (a₀ = floor(-4.46…) = -5).
      final cf =
          CalculatorEngine.continuedFractionOfRational(b(-415), b(93), 10);
      expect(cf.first, b(-5));
      expect(cf.skip(1).every((t) => t > BigInt.zero), isTrue);
    });

    test('convergentFromTerms folds [4,2,6,7] → 415/93', () {
      final c = CalculatorEngine.convergentFromTerms([b(4), b(2), b(6), b(7)]);
      expect(c.numerator, b(415));
      expect(c.denominator, b(93));
    });

    test('convergentFromTerms of pi terms gives 22/7 then 355/113', () {
      final c1 = CalculatorEngine.convergentFromTerms([b(3), b(7)]);
      expect((c1.numerator, c1.denominator), (b(22), b(7)));
      final c2 =
          CalculatorEngine.convergentFromTerms([b(3), b(7), b(15), b(1)]);
      expect((c2.numerator, c2.denominator), (b(355), b(113)));
    });

    test('cfrac/convergent dispatch on an exact rational (no bridge)', () {
      expect(engine.cfrac('415/93', 10), '[4; 2, 6, 7]');
      expect(engine.convergent('415/93', 2), '58/13');
      expect(engine.convergent('415/93', 3), '415/93');
      expect(engine.cfrac('43/19', 4), '[2; 3, 1, 4]');
    });

    test('cfrac on a decimal literal', () {
      // 3.245 = 649/200 = [3; 4, 12, 4].
      expect(engine.cfrac('3.245', 6), '[3; 4, 12, 4]');
    });

    test('bad argument / range → Error string', () {
      expect(engine.cfrac('1/0', 5), startsWith('Error'));
      expect(engine.cfrac('hello', 5), startsWith('Error'));
      expect(engine.cfrac('5', 0), startsWith('Error'));
      expect(engine.convergent('5', -1), startsWith('Error'));
    });

    test('constants via the native bridge', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.cfrac('pi', 5), '[3; 7, 15, 1, 292]');
      expect(engine.convergent('pi', 1), '22/7');
      expect(engine.convergent('pi', 3), '355/113');
      expect(engine.cfrac('sqrt(2)', 5), '[1; 2, 2, 2, 2]');
    });
  });

  // Group B: generic arbitrary-precision evalf(expr, N).
  group('CalculatorEngine.evalfPrecision (Group B)', () {
    test('precision out of range → friendly error (no bridge needed)', () {
      expect(engine.evalfPrecision('ln(10)', 0), contains('1..10000'));
      expect(engine.evalfPrecision('ln(10)', 10001), contains('1..10000'));
    });

    test('dispatch matches evalf(expr, N) and is not null', () {
      // Matched by the pre-pass; headless it surfaces a native-required
      // error rather than null (distinguishes "matched" from "fell
      // through").
      final r = engine.tryEvaluatePrecisionCall('evalf(ln(10), 50)');
      expect(r, isNotNull);
      // Expression may itself contain commas — beta(2, 3).
      final r2 = engine.tryEvaluatePrecisionCall('evalf(beta(2, 3), 40)');
      expect(r2, isNotNull);
      // Out-of-range precision short-circuits to the range error.
      expect(engine.tryEvaluatePrecisionCall('evalf(pi, 0)'),
          contains('1..10000'));
    });

    test('native-backed high-precision values', () {
      if (!engine.isNativeAvailable) return;
      // ln(10) to 30 digits — 2.302585092994045684017991454684...
      expect(engine.evalfPrecision('ln(10)', 30), startsWith('2.30258509299'));
      // zeta(2) = pi^2/6.
      expect(engine.evalfPrecision('zeta(2)', 20), startsWith('1.6449340668'));
      // a sum of surds.
      expect(engine.evalfPrecision('sqrt(2)+sqrt(3)', 20),
          startsWith('3.1462643699'));
    });
  });

  // Round 4: dispatch through the top-level precision pre-pass.
  group('CalculatorEngine.tryEvaluatePrecisionCall (round 4 shapes)', () {
    test('non-bridge shapes resolve regardless of native availability', () {
      // divisors(1) needs no bridge.
      expect(engine.tryEvaluatePrecisionCall('divisors(1)'), '1');
      // cfrac / convergent on an exact rational need no bridge.
      expect(
          engine.tryEvaluatePrecisionCall('cfrac(415/93, 10)'), '[4; 2, 6, 7]');
      expect(engine.tryEvaluatePrecisionCall('convergent(415/93, 1)'), '9/2');
      // unrecognized input falls through to null.
      expect(engine.tryEvaluatePrecisionCall('2 + 2'), isNull);
    });

    test('native-backed shapes round-trip', () {
      if (!engine.isNativeAvailable) return;
      expect(engine.tryEvaluatePrecisionCall('modpow(2, 10, 1000)'), '24');
      expect(engine.tryEvaluatePrecisionCall('modinv(3, 11)'), '4');
      expect(engine.tryEvaluatePrecisionCall('totient(12)'), '4');
      expect(engine.tryEvaluatePrecisionCall('jacobi(2, 7)'), '1');
      expect(
          engine.tryEvaluatePrecisionCall('divisors(12)'), '1, 2, 3, 4, 6, 12');
    });
  });
}
