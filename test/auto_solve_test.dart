// Tests for the auto-solve helper logic. We can't easily exercise the full
// _calculate path (it's private to a State class and touches the SymEngine
// bridge), but we can verify the heuristics behave correctly.

import 'package:crisp_calc/utils/expression_preprocessing_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bare-equation detection — what should auto-route to solve()', () {
    // Mirrors the _looksLikeBareEquation predicate.
    bool looksLikeBare(String converted) {
      if (!converted.contains('=')) return false;
      return RegExp(r'[a-zA-Z]').hasMatch(converted);
    }

    test('linear equation', () {
      expect(looksLikeBare('2x+3=0'), isTrue);
    });

    test('quadratic equation', () {
      expect(looksLikeBare('x^2-4=0'), isTrue);
    });

    test('equation with both sides non-trivial', () {
      expect(looksLikeBare('x^2 = 2x + 1'), isTrue);
    });

    test('plain arithmetic has no =', () {
      expect(looksLikeBare('2+3'), isFalse);
    });

    test('digits-only equation with = (shouldn\'t happen in practice)', () {
      // `3=3` has no variable so we don't try to solve it.
      expect(looksLikeBare('3=3'), isFalse);
    });
  });

  group('free-variable detection — function-vs-variable assignment', () {
    // Mirrors _hasFreeVariable in CalculatorScreen.
    bool hasFreeVar(String expr) {
      const reserved = {'e', 'E', 'I'};
      final regex = RegExp(r'(?<![a-zA-Z])([a-zA-Z])(?![a-zA-Z])');
      for (final m in regex.allMatches(expr)) {
        if (!reserved.contains(m.group(1))) return true;
      }
      return false;
    }

    test('pure number → variable, no free variable', () {
      expect(hasFreeVar('5'), isFalse);
    });

    test('arithmetic only → variable', () {
      expect(hasFreeVar('3 + 2*4'), isFalse);
    });

    test('linear in x → function', () {
      expect(hasFreeVar('2x - 5'), isTrue);
    });

    test('quadratic in x → function', () {
      expect(hasFreeVar('x^2 + 1'), isTrue);
    });

    test('e (Euler constant) alone → variable', () {
      expect(hasFreeVar('e + 1'), isFalse);
    });

    test('imaginary unit I → variable (numeric)', () {
      expect(hasFreeVar('3 + 2*I'), isFalse);
    });
  });

  group('detectVariable on equation bodies', () {
    test('linear in x', () {
      expect(ExpressionPreprocessingUtils.detectVariable('2x+3'), equals('x'));
    });

    test('quadratic in x', () {
      expect(ExpressionPreprocessingUtils.detectVariable('x^2-4'), equals('x'));
    });

    test('letter that isn\'t a reserved token', () {
      expect(ExpressionPreprocessingUtils.detectVariable('2k+5'), equals('k'));
    });

    test('multiple variables — prefers x', () {
      expect(
          ExpressionPreprocessingUtils.detectVariable('a*x + b'), equals('x'));
    });
  });
}
