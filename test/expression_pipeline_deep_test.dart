// test/expression_pipeline_deep_test.dart
//
// Deep coverage for the bits of the expression pipeline that
// recent calculator/notepad bugs landed in:
//   - normalizeComplexResult (unary minus spacing, i/I, ^, etc.)
//   - substituteVariables (Ans + user vars)
//   - preprocessExpression (UDF + Y-slot inlining, depth budget)
//   - AppState.formatNumber (NumberDisplayFormat + exact-int mode
//     + arbitrary-N decimalPlaces)
//
// All pure-Dart, no engine bridge required.

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/utils/expression_preprocessing_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // -------------------------------------------------------------------------
  // normalizeComplexResult — spacing + cleanup
  // -------------------------------------------------------------------------

  group('normalizeComplexResult — unary minus', () {
    // The fix for "negatives showed as 9223372036854775807" lived in
    // here — binary-minus gets ` - ` spacing, unary-minus stays glued
    // to its operand so `double.tryParse` still works downstream.
    final cases = <String, String>{
      '-5': '-5',
      '-5.0': '-5.0',
      '1-2': '1 - 2',
      'x-1': 'x - 1',
      'a-b-c': 'a - b - c',
      '-x': '-x',
      // leading + - operator alone should drop, per existing rule
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(
          ExpressionPreprocessingUtils.normalizeComplexResult(input),
          want,
        );
      });
    });
  });

  group('normalizeComplexResult — complex-number cleanup', () {
    final cases = <String, String>{
      // I -> i
      '3*I': '3i',
      '3 + 4*I': '3 + 4i',
      // Drop +0*I
      '5 + 0*I': '5',
      '5 + 0.0*I': '5',
      '5 + -0*I': '5',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(
          ExpressionPreprocessingUtils.normalizeComplexResult(input),
          want,
        );
      });
    });
  });

  group('normalizeComplexResult — Python exponents', () {
    final cases = <String, String>{
      'x**2': 'x²',
      'x**3': 'x³',
      'x**4': 'x^4',
      'x**10': 'x^10',
      '2*x**2 + 3*x': '2x² + 3x',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(
          ExpressionPreprocessingUtils.normalizeComplexResult(input),
          want,
        );
      });
    });
  });

  group('normalizeComplexResult — coefficient * variable', () {
    final cases = <String, String>{
      '2 * x': '2x',
      '3*y': '3y',
      // Multi-letter ident stays explicit
      '2*sin': '2*sin',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(
          ExpressionPreprocessingUtils.normalizeComplexResult(input),
          want,
        );
      });
    });
  });

  // -------------------------------------------------------------------------
  // substituteVariables — Ans + user vars
  // -------------------------------------------------------------------------

  group('substituteVariables', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppState().load(force: true);
    });

    test('Ans pulls from last history entry', () {
      AppState().addHistoryEntry('1+2', '3');
      final out = ExpressionPreprocessingUtils.substituteVariables(
          'Ans*5', AppState());
      expect(out, '3*5');
    });

    test('Ans defaults to 0 when history is empty', () {
      final out = ExpressionPreprocessingUtils.substituteVariables(
          'Ans+1', AppState());
      expect(out, '0+1');
    });

    test('user variable inlines wrapped in parens', () {
      AppState().setVariable('a', '7');
      final out = ExpressionPreprocessingUtils.substituteVariables(
          'a*2', AppState());
      expect(out, '(7)*2');
    });

    test('multiple variables', () {
      AppState().setVariable('a', '5');
      AppState().setVariable('b', '3');
      final out = ExpressionPreprocessingUtils.substituteVariables(
          'a + b', AppState());
      expect(out, '(5) + (3)');
    });

    test('word-boundary respect — `at` does not match `a`', () {
      AppState().setVariable('a', '7');
      final out = ExpressionPreprocessingUtils.substituteVariables(
          'at + a', AppState());
      // `at` is untouched, the standalone `a` gets substituted.
      expect(out, 'at + (7)');
    });

    test('Ans with extracted solve numeric', () {
      AppState().addHistoryEntry('solve(x-3, x)', 'x = 3');
      final out = ExpressionPreprocessingUtils.substituteVariables(
          'Ans+2', AppState());
      expect(out, '3+2');
    });
  });

  // -------------------------------------------------------------------------
  // preprocessExpression — UDF + Y-slot inlining
  // -------------------------------------------------------------------------

  group('preprocessExpression — Y-slot inlining', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppState().load(force: true);
    });

    test('Y1 inlines the slot 0 expression with argument substituted', () {
      AppState().updateFunction(0, 'x^2 + 1');
      final out = ExpressionPreprocessingUtils.preprocessExpression(
          'Y1(3)', AppState());
      expect(out, '((3)^2 + 1)');
    });

    test('Y2 inlines the slot 1 expression', () {
      AppState().updateFunction(1, '2*x');
      final out = ExpressionPreprocessingUtils.preprocessExpression(
          'Y2(5)', AppState());
      expect(out, '(2*(5))');
    });

    test('empty Y slot leaves the call unchanged', () {
      final out = ExpressionPreprocessingUtils.preprocessExpression(
          'Y3(5)', AppState());
      expect(out, 'Y3(5)');
    });
  });

  group('preprocessExpression — user-function inlining', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppState().load(force: true);
    });

    test('single-letter UDF inlines and substitutes argument', () {
      AppState().setUserFunction(const UserFunction(
        name: 'f',
        paramVar: 'x',
        body: 'x^2 + 1',
      ));
      final out = ExpressionPreprocessingUtils.preprocessExpression(
          'f(3)', AppState());
      expect(out, contains('3'));
      expect(out, contains('^2'));
    });

    test('UDF composition g(f(x))', () {
      AppState().setUserFunction(const UserFunction(
        name: 'f',
        paramVar: 'x',
        body: 'x + 1',
      ));
      AppState().setUserFunction(const UserFunction(
        name: 'g',
        paramVar: 'x',
        body: 'x * 2',
      ));
      final out = ExpressionPreprocessingUtils.preprocessExpression(
          'g(f(5))', AppState());
      // After expansion both should be inlined: g(f(5)) -> ((5+1))*2 -ish.
      expect(out, contains('5'));
      expect(out, contains('1'));
      expect(out, contains('2'));
    });

    test('depth budget prevents recursive UDF blow-up', () {
      // Self-referential UDF; expander should stop after maxDepth=4
      // passes rather than recursing forever.
      AppState().setUserFunction(const UserFunction(
        name: 'f',
        paramVar: 'x',
        body: 'f(x) + 1',
      ));
      final stopwatch = Stopwatch()..start();
      final out = ExpressionPreprocessingUtils.preprocessExpression(
          'f(2)', AppState(),
          maxDepth: 4);
      stopwatch.stop();
      // Must return in well under a second.
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      // Output should be a string (non-null), no exception thrown.
      expect(out, isNotNull);
    });

    test('built-in names like sin do NOT get expanded as UDFs', () {
      // No UDF named "sin" registered; built-in should pass through.
      final out = ExpressionPreprocessingUtils.preprocessExpression(
          'sin(0)', AppState());
      expect(out, 'sin(0)');
    });
  });

  // -------------------------------------------------------------------------
  // AppState.formatNumber — full coverage
  // -------------------------------------------------------------------------

  group('AppState.formatNumber — basic + edge cases', () {
    late AppState s;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      s = AppState();
      await s.load(force: true);
    });

    test('auto: integer-shaped doubles stay integers', () {
      expect(s.formatNumber('5'), '5');
      expect(s.formatNumber('5.0'), '5');
      expect(s.formatNumber('-5'), '-5');
      expect(s.formatNumber('-5.0'), '-5');
      expect(s.formatNumber('0'), '0');
    });

    test('auto: non-integer doubles round-trip via toString', () {
      expect(s.formatNumber('3.14'), '3.14');
      expect(s.formatNumber('-2.5'), '-2.5');
    });

    test('integer format rounds half-away-from-zero', () {
      s.setDecimalPlaces(0);
      expect(s.formatNumber('5.4'), '5');
      expect(s.formatNumber('5.5'), '6');
      expect(s.formatNumber('-5.5'), '-6');
    });

    test('1 decimal place', () {
      s.setDecimalPlaces(1);
      expect(s.formatNumber('5'), '5.0');
      expect(s.formatNumber('3.14'), '3.1');
      expect(s.formatNumber('-2.5'), '-2.5');
    });

    test('arbitrary N decimal places — 4', () {
      s.setDecimalPlaces(4);
      expect(s.formatNumber('3.14159265'), '3.1416');
    });

    test('arbitrary N decimal places — 8', () {
      s.setDecimalPlaces(8);
      expect(s.formatNumber('3.14159265358979'), '3.14159265');
    });

    test('non-numeric strings pass through unchanged', () {
      expect(s.formatNumber('x^2 + 1'), 'x^2 + 1');
      expect(s.formatNumber('Error: foo'), 'Error: foo');
    });

    test('exact-int mode ON: bignum preserves all digits', () {
      // 25! is 25 digits, well above the 15-digit threshold
      expect(
        s.formatNumber('15511210043330985984000000'),
        '15511210043330985984000000',
      );
    });

    test('exact-int mode OFF: bignum renders as scientific notation', () {
      s.setExactIntegerMode(false);
      // 100! literal
      const hundredFact =
          '93326215443944152681699238856266700490715968264381621468592963895'
          '21759999322991560894146397615651828625369792082722375825118521091'
          '6864000000000000000000000000';
      final out = s.formatNumber(hundredFact);
      // Should be scientific, not int64-clamped to 9223372036854775807.
      expect(out, contains('e+'));
      expect(out, isNot('9223372036854775807'),
          reason: 'pre-fix bug clamped to int64 max');
    });

    test('decimalPlaces clamped to 0..15', () {
      s.setDecimalPlaces(20);
      // Even if set above 15, formatNumber clamps internally.
      expect(s.formatNumber('1.234567890123456789').length,
          lessThanOrEqualTo(20));
    });
  });

  // -------------------------------------------------------------------------
  // extractNumericFromSolveResult — Ans-from-solve coercion
  // -------------------------------------------------------------------------

  group('extractNumericFromSolveResult', () {
    final cases = <String, String>{
      'x = 1': '1',
      'x = -3': '-3',
      'x = 3.14': '3.14',
      // Multi-solution result — returns original
      'x = 1, x = 2': 'x = 1, x = 2',
      // Plain numeric — returns as-is (no match for the var=N pattern)
      '5': '5',
      // Symbolic — returns as-is
      '2*x + 1': '2*x + 1',
    };
    cases.forEach((input, want) {
      test('"$input" -> "$want"', () {
        expect(
          ExpressionPreprocessingUtils.extractNumericFromSolveResult(input),
          want,
        );
      });
    });
  });
}
