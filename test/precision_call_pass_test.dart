// test/precision_call_pass_test.dart
//
// Round 91 (P6) — top-level precision-arc call detection.
//
// We run these against `CalculatorEngine` headless: the bridge isn't
// loaded in `flutter test` on Linux CI, so the precision constants
// fall back to the double-precision literals embedded in
// `_precisionConstant`. That's enough to verify the pre-pass dispatch
// shape (which call routes where, format of factorint output, error
// path on bad precision). End-to-end MPFR-backed precision is
// already covered by the round-85/86/89/90 native tests.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CalculatorEngine engine;

  setUp(() {
    engine = CalculatorEngine();
  });

  group('tryEvaluatePrecisionCall — dispatch', () {
    test('pi(N) → fallback constant string when bridge unavailable', () {
      // Bridge isn't loaded in headless test, so the result is the
      // double-precision fallback regardless of N — we just assert
      // we routed to *some* string rather than null.
      final r = engine.tryEvaluatePrecisionCall('pi(50)');
      expect(r, isNotNull);
      // The fallback `3.141592653589793` starts with the canonical
      // first digits even when MPFR isn't available.
      expect(r, startsWith('3.14'));
    });

    test('e(N) routes through getEWithPrecision', () {
      final r = engine.tryEvaluatePrecisionCall('e(100)');
      expect(r, isNotNull);
      expect(r, startsWith('2.71'));
    });

    test('EulerGamma(N) routes through getEulerGammaWithPrecision', () {
      final r = engine.tryEvaluatePrecisionCall('EulerGamma(20)');
      expect(r, isNotNull);
      expect(r, startsWith('0.57'));
    });

    test('sqrt(2, N) routes through getSqrt2WithPrecision', () {
      final r = engine.tryEvaluatePrecisionCall('sqrt(2, 30)');
      expect(r, isNotNull);
      expect(r, startsWith('1.41'));
    });

    test('sqrt(x) single-arg passes through (returns null)', () {
      // `sqrt(2)` without a precision arg is the SymEngine path —
      // the precision pre-pass must not intercept it.
      expect(engine.tryEvaluatePrecisionCall('sqrt(2)'), isNull);
      expect(engine.tryEvaluatePrecisionCall('sqrt(x)'), isNull);
    });

    test('isprime(n) uses the headless fallback for small n', () {
      // Bridge unavailable → falls back to deterministic sieve for
      // n ≤ 2^31 in calculator_engine.dart:_fallbackIsprime.
      expect(engine.tryEvaluatePrecisionCall('isprime(7)'), 'true');
      expect(engine.tryEvaluatePrecisionCall('isprime(8)'), 'false');
      expect(engine.tryEvaluatePrecisionCall('isprime(2027)'), 'true');
    });

    test('nextprime / prevprime route to the bridge', () {
      // Without the bridge these return an error string ("nextprime
      // requires native library"). Routing is what we're testing
      // here, not the native result.
      final n = engine.tryEvaluatePrecisionCall('nextprime(100)');
      expect(n, isNotNull);
      final p = engine.tryEvaluatePrecisionCall('prevprime(100)');
      expect(p, isNotNull);
    });

    test('factorint(n) on bridge-less engine surfaces an error', () {
      // factorint requires the bridge — pre-pass catches the
      // StateError thrown by CalculatorEngine.factorint and wraps
      // it in an error string.
      final r = engine.tryEvaluatePrecisionCall('factorint(360)');
      expect(r, isNotNull);
      // Either a native-success string OR our wrapper error.
      expect(
          r!.startsWith('Error') || r.contains('·') || r.contains('²'), isTrue);
    });
  });

  group('tryEvaluatePrecisionCall — non-matches return null', () {
    test('plain identifiers / arithmetic untouched', () {
      expect(engine.tryEvaluatePrecisionCall('x + 1'), isNull);
      expect(engine.tryEvaluatePrecisionCall('pi'), isNull);
      expect(engine.tryEvaluatePrecisionCall('e'), isNull);
    });

    test('in-expression calls are NOT intercepted (V1 scope)', () {
      // `pi(50) + 1` falls through; existing preprocessor handles it.
      expect(engine.tryEvaluatePrecisionCall('pi(50) + 1'), isNull);
      expect(engine.tryEvaluatePrecisionCall('isprime(7) and isprime(11)'),
          isNull);
    });

    test('case-sensitive: PI(50) is not intercepted', () {
      expect(engine.tryEvaluatePrecisionCall('PI(50)'), isNull);
      expect(engine.tryEvaluatePrecisionCall('Eulergamma(20)'), isNull);
    });

    test('non-precision-arc function calls return null', () {
      expect(engine.tryEvaluatePrecisionCall('sin(1)'), isNull);
      expect(engine.tryEvaluatePrecisionCall('integrate(x^2, x)'), isNull);
      expect(engine.tryEvaluatePrecisionCall('totient(12)'), isNull);
    });
  });

  group('tryEvaluatePrecisionCall — error paths', () {
    test('precision out of range → friendly error', () {
      final r = engine.tryEvaluatePrecisionCall('pi(0)');
      expect(r, contains('1..10000'));
      final r2 = engine.tryEvaluatePrecisionCall('pi(10001)');
      expect(r2, contains('1..10000'));
    });

    test('whitespace tolerated', () {
      expect(engine.tryEvaluatePrecisionCall(' pi ( 20 ) '), isNotNull);
      expect(engine.tryEvaluatePrecisionCall('sqrt(  2 ,  30 )'), isNotNull);
    });
  });

  group('formatFactorint — Unicode superscript formatting', () {
    test('omits exponent 1, uses · separator', () {
      final s = engine.formatFactorint(
        [
          (prime: 2, exponent: 3),
          (prime: 3, exponent: 2),
          (prime: 5, exponent: 1)
        ],
        originalInput: '360',
      );
      expect(s, '2³ · 3² · 5');
    });

    test('single prime to the first power', () {
      final s = engine.formatFactorint(
        [(prime: 7, exponent: 1)],
        originalInput: '7',
      );
      expect(s, '7');
    });

    test('two-digit exponents superscript every digit', () {
      // 2^12 has a two-digit exponent; expect "²¹" → wait, 12 → ¹²
      final s = engine.formatFactorint(
        [(prime: 2, exponent: 12)],
        originalInput: '4096',
      );
      expect(s, '2¹²');
    });

    test('empty factor list returns the original input verbatim', () {
      // Maps to factorint(0) / factorint(1) — we want the user to see
      // the input back rather than a confusing "1" for both.
      expect(engine.formatFactorint([], originalInput: '0'), '0');
      expect(engine.formatFactorint([], originalInput: '1'), '1');
      expect(engine.formatFactorint([], originalInput: '-1'), '-1');
    });
  });
}
