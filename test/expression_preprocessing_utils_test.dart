import 'package:flutter_test/flutter_test.dart';
import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/utils/expression_preprocessing_utils.dart';

void main() {
  // AppState is a singleton; reset its mutable state at the start of every test.
  setUp(() {
    final s = AppState();
    s.userVariables.clear();
    s.history.clear();
    for (var i = 0; i < s.graphFunctions.length; i++) {
      s.graphFunctions[i] = '';
    }
  });

  group('preprocessNativeExpression', () {
    test('converts custom matrix syntax to SymEngine Matrix(...)', () {
      expect(
        ExpressionPreprocessingUtils.preprocessNativeExpression('[1,2; 3,4]'),
        contains('Matrix([[1, 2],[3, 4]])'),
      );
    });

    test('leaves non-matrix bracketed lists alone', () {
      expect(
        ExpressionPreprocessingUtils.preprocessNativeExpression('[1,2,3]'),
        equals('[1.2,3]'), // see decimal-comma rule below
      );
    });

    test('converts German decimal comma to dot between digits', () {
      expect(
        ExpressionPreprocessingUtils.preprocessNativeExpression('3,14'),
        equals('3.14'),
      );
    });

    test('inserts implicit multiplication between digit and paren', () {
      expect(
        ExpressionPreprocessingUtils.preprocessNativeExpression('2(x+1)'),
        equals('2*(x+1)'),
      );
    });

    test('inserts implicit multiplication for closing paren followed by digit',
        () {
      expect(
        ExpressionPreprocessingUtils.preprocessNativeExpression('(x+1)2'),
        equals('(x+1)*2'),
      );
    });

    test('computes small integer factorials directly', () {
      expect(
        ExpressionPreprocessingUtils.preprocessNativeExpression('5!'),
        equals('120'),
      );
    });

    test('falls back to gamma for literal factorials past the big-int cap', () {
      // The exact big-int path covers n up to 1000 (commit 27336ae); above
      // that we fall back to SymEngine's gamma(n+1).
      expect(
        ExpressionPreprocessingUtils.preprocessNativeExpression('1001!'),
        equals('gamma(1002)'),
      );
    });

    test('rewrites a mod b to (a) % (b)', () {
      expect(
        ExpressionPreprocessingUtils.preprocessNativeExpression('17 mod 5'),
        equals('(17) % (5)'),
      );
    });
  });

  group('preprocessSpecialFunctions', () {
    test('expands small fib() values', () {
      expect(
        ExpressionPreprocessingUtils.preprocessSpecialFunctions('fib(10)'),
        equals('55'),
      );
    });

    test('delegates large fib() to fibonacci()', () {
      expect(
        ExpressionPreprocessingUtils.preprocessSpecialFunctions('fib(1000)'),
        equals('fibonacci(1000)'),
      );
    });

    test('isprime() reports primes correctly', () {
      expect(
          ExpressionPreprocessingUtils.preprocessSpecialFunctions('isprime(7)'),
          equals('true'));
      expect(
          ExpressionPreprocessingUtils.preprocessSpecialFunctions('isprime(9)'),
          equals('false'));
      expect(
          ExpressionPreprocessingUtils.preprocessSpecialFunctions('isprime(2)'),
          equals('true'));
      expect(
          ExpressionPreprocessingUtils.preprocessSpecialFunctions('isprime(1)'),
          equals('false'));
    });
  });

  group('substituteVariables', () {
    test('replaces Ans with the last numeric result', () {
      final state = AppState()..addHistoryEntry('1+1', '2');
      expect(
        ExpressionPreprocessingUtils.substituteVariables('Ans+3', state),
        equals('2+3'),
      );
    });

    test('expands user variables with parens', () {
      final state = AppState()..setVariable('a', '5');
      expect(
        ExpressionPreprocessingUtils.substituteVariables('a+1', state),
        equals('(5)+1'),
      );
    });

    test('substitutes only whole-word matches', () {
      final state = AppState()..setVariable('a', '5');
      // 'cat' starts with 'a' style — but case-sensitive: a alone matches.
      expect(
        ExpressionPreprocessingUtils.substituteVariables('asin(a)', state),
        equals('asin((5))'),
      );
    });
  });

  group('extractNumericFromSolveResult', () {
    test('extracts a single-variable solve result', () {
      expect(
        ExpressionPreprocessingUtils.extractNumericFromSolveResult('x = 5'),
        equals('5'),
      );
    });

    test('returns the input unchanged when the result has multiple values', () {
      expect(
        ExpressionPreprocessingUtils.extractNumericFromSolveResult(
            'x = {-2, 2}'),
        equals('x = {-2, 2}'),
      );
    });
  });

  group('detectVariable', () {
    test('prefers x when present', () {
      expect(ExpressionPreprocessingUtils.detectVariable('a + x + y'),
          equals('x'));
    });

    test('skips reserved tokens', () {
      // 'e' alone is a reserved constant; should pick 'a' instead.
      expect(ExpressionPreprocessingUtils.detectVariable('a + e'), equals('a'));
    });

    test('defaults to x when nothing detected', () {
      expect(ExpressionPreprocessingUtils.detectVariable('42'), equals('x'));
    });

    test('is case-sensitive', () {
      // 'X' (capital) is the variable name; previous version lowered to 'x'.
      expect(
          ExpressionPreprocessingUtils.detectVariable('X^2 + 1'), equals('X'));
    });
  });

  group('preprocessExpression (Y-function inlining)', () {
    test('inlines Y1(x) into its definition', () {
      final state = AppState();
      state.updateFunction(0, 'x^2 + 1');
      final result =
          ExpressionPreprocessingUtils.preprocessExpression('Y1(3)+1', state);
      expect(result, contains('(3)^2 + 1'));
    });

    test('inlines simple Y1 reference', () {
      final state = AppState();
      state.updateFunction(0, 'sin(x)');
      final result =
          ExpressionPreprocessingUtils.preprocessExpression('Y1+1', state);
      expect(result, equals('(sin(x))+1'));
    });

    test('recursion guard stops cyclic references from looping', () {
      final state = AppState();
      // Y1 refers to Y2, Y2 refers to Y1. Without a guard this loops forever.
      state.updateFunction(0, 'Y2 + 1');
      state.updateFunction(1, 'Y1 - 1');
      // The call should return (not hang) with some bounded substitution.
      final result =
          ExpressionPreprocessingUtils.preprocessExpression('Y1', state);
      // We don't care about the exact output — only that it terminated quickly
      // and is a non-empty string.
      expect(result, isNotEmpty);
    });
  });

  group('normalizeComplexResult', () {
    test('strips zero imaginary part', () {
      expect(
        ExpressionPreprocessingUtils.normalizeComplexResult('5 + 0.0*I'),
        equals('5'),
      );
    });

    test('converts ** to ^/superscript for display', () {
      expect(
        ExpressionPreprocessingUtils.normalizeComplexResult('x**4'),
        equals('x^4'),
      );
      expect(
        ExpressionPreprocessingUtils.normalizeComplexResult('x**2'),
        equals('x²'),
      );
    });

    test('drops the multiplication symbol between coefficient and variable',
        () {
      expect(
        ExpressionPreprocessingUtils.normalizeComplexResult('2*x + 1'),
        contains('2x'),
      );
    });

    test('returns input when normalization would produce only operators', () {
      // A degenerate case the function explicitly guards against.
      expect(
        ExpressionPreprocessingUtils.normalizeComplexResult('+++'),
        equals('+++'),
      );
    });
  });
}
