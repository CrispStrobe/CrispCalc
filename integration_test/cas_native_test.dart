// integration_test/cas_native_test.dart
//
// Track D: a CAS test suite that runs against the REAL native SymEngine
// bridge (FLINT/GMP/MPFR). Plain `flutter test` is headless and has no
// bridge, so these assertions can only be checked on a device/desktop:
//
//   flutter test integration_test/cas_native_test.dart -d macos
//
// This is where the FLINT-backed factor (Track A) and the native
// number-theory ops are actually exercised end-to-end. If the bridge isn't
// loaded (e.g. run on web), the whole group is skipped rather than failed.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final engine = CalculatorEngine();

  // Normalize SymEngine output for format-agnostic comparison.
  String norm(String s) => s.replaceAll(' ', '').replaceAll('**', '^');

  group('native CAS — real SymEngine bridge', () {
    setUpAll(() {
      expect(engine.isNativeAvailable, isTrue,
          reason: 'native bridge not loaded — run with `-d macos` (or another '
              'native device). On web/headless this suite is meant to skip.');
    });

    group('FLINT factor (Track A)', () {
      // The headline win: complete univariate-over-Z factorization, beyond
      // the Dart rational-linear-only fallback.
      test('difference of squares', () {
        final f = engine.factor('x^2 - 1');
        expect(f, contains('*')); // a genuine product, not the expanded form
        expect(norm(engine.expand(f)), norm(engine.expand('x^2 - 1')));
      });

      test('splits into irreducible quadratics (x^4 + 4)', () {
        // Sophie-Germain: x^4+4 = (x^2-2x+2)(x^2+2x+2). The Dart fallback
        // can't find these (no rational roots); FLINT does.
        final f = engine.factor('x^4 + 4');
        expect(f, contains('*'));
        expect(f, isNot(contains('4 + x'))); // not left as the bare quartic
        expect(norm(engine.expand(f)), norm(engine.expand('x^4 + 4')));
      });

      test('non-monic integer factors (6x^2 + 5x - 4)', () {
        final f = engine.factor('6*x^2 + 5*x - 4');
        expect(f, contains('*'));
        expect(norm(engine.expand(f)), norm(engine.expand('6*x^2 + 5*x - 4')));
      });

      test('repeated factor (x^2 - 2x + 1)', () {
        final f = engine.factor('x^2 - 2*x + 1');
        expect(norm(engine.expand(f)), norm(engine.expand('x^2 - 2*x + 1')));
      });

      test('irreducible stays intact (x^2 + 1)', () {
        expect(norm(engine.factor('x^2 + 1')), norm('1 + x^2'));
      });

      test('multivariate: difference of squares (x^2 - y^2)', () {
        // FLINT fmpz_mpoly_factor — the Dart fallback can't do multivariate.
        final f = engine.factor('x^2 - y^2');
        expect(f, contains('*'));
        expect(norm(engine.expand(f)), norm(engine.expand('x^2 - y^2')));
      });

      test('multivariate: common + binomial factors (x*y + x + y + 1)', () {
        final f = engine.factor('x*y + x + y + 1');
        expect(f, contains('*'));
        expect(norm(engine.expand(f)), norm(engine.expand('x*y + x + y + 1')));
      });
    });

    group('simplify (real, not the expand-alias)', () {
      test('rational cancellation: (x^2 - 1)/(x - 1) -> x + 1', () {
        final s = engine.simplify('(x^2 - 1)/(x - 1)');
        expect(norm(engine.expand(s)), norm(engine.expand('x + 1')));
      });
      test('collects like terms: 2*x + 3*x -> 5*x', () {
        expect(norm(engine.simplify('2*x + 3*x')), norm('5*x'));
      });
    });

    group('integrate (Track C, native)', () {
      test('power rule', () {
        expect(engine.integrate('x^2', 'x'), '1/3x^3 + C');
      });
      test('standard trig', () {
        expect(engine.integrate('sin(x)', 'x'), '-cos(x) + C');
      });
      test('definite, exact', () {
        expect(engine.integrate('x^2', 'x', '0', '1'), '1/3');
      });
    });

    group('number theory (native FLINT/GMP)', () {
      test('isprime', () {
        expect(engine.isprime('97'), isTrue);
        expect(engine.isprime('91'), isFalse); // 7 * 13
      });
      test('factorint', () {
        final f = engine.factorint('360');
        // 360 = 2^3 * 3^2 * 5
        expect(f, contains(const (prime: 2, exponent: 3)));
        expect(f, contains(const (prime: 3, exponent: 2)));
        expect(f, contains(const (prime: 5, exponent: 1)));
      });
    });
  }, skip: false);
}
