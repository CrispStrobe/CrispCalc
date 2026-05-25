// test/precision_test.dart
//
// Round 81 (precision arc) — pi(N) end-to-end test. Exercises the
// three-repo chain (math-stack-ios-builder C wrapper → symbolic_math_
// bridge Dart FFI → CrispCalc engine binding) by asking for π at
// several precisions and verifying the result against known prefixes.
//
// Skips silently when the native bridge isn't available (Linux CI
// runs without the macOS xcframework; the engine method falls back
// to the standard double-precision constant, which has only ~15
// digits, so any precision > 15 with no native bridge means we're
// running headless and should skip).

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

// First 100 digits of pi. Source: https://www.piday.org/million/
const _piRef =
    '3.141592653589793238462643383279502884197169399375105820974944'
    '5923078164062862089986280348253421170679';

void main() {
  group('CalculatorEngine.getPiWithPrecision (round 81 precision arc)', () {
    final engine = CalculatorEngine();

    test('pi(50) returns the first 50 decimal digits', () {
      final result = engine.getPiWithPrecision(50);
      if (result == '3.141592653589793') {
        // Native bridge unavailable (Linux CI). Skip.
        return;
      }
      // Expect: 3.<50 digits>. The first 50 decimal digits of pi are
      // 14159265358979323846264338327950288419716939937510. So the
      // result string should start with that prefix.
      expect(result.length, greaterThanOrEqualTo(51),
          reason: 'pi(50) too short: $result');
      expect(result.substring(0, 52), _piRef.substring(0, 52),
          reason: 'pi(50) prefix mismatch');
    });

    test('pi(100) returns the first 100 decimal digits', () {
      final result = engine.getPiWithPrecision(100);
      if (result == '3.141592653589793') return;
      expect(result.length, greaterThanOrEqualTo(101),
          reason: 'pi(100) too short: $result');
      // Compare first 102 chars (3. + 100 digits).
      expect(result.substring(0, 102), _piRef.substring(0, 102),
          reason: 'pi(100) prefix mismatch');
    });

    test('pi(500) starts with the known prefix and has enough digits', () {
      final result = engine.getPiWithPrecision(500);
      if (result == '3.141592653589793') return;
      // We don't have 500 digits inlined; just check the first 100
      // are correct and the result is the expected length.
      expect(result.length, greaterThanOrEqualTo(501),
          reason: 'pi(500) too short: $result');
      expect(result.substring(0, 102), _piRef.substring(0, 102),
          reason: 'pi(500) first 100 digits should still match pi');
    });

    test('pi(0) rejected with ArgumentError', () {
      expect(
        () => engine.getPiWithPrecision(0),
        throwsArgumentError,
      );
    });

    test('pi(10001) rejected with ArgumentError', () {
      expect(
        () => engine.getPiWithPrecision(10001),
        throwsArgumentError,
      );
    });
  });
}
