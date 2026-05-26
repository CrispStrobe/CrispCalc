// test/relational_preprocessor_test.dart
//
// Round 110 (P7 kickoff) — relational-operator preprocessor.
//
// The rewrite step lowers `a == b`, `a != b`, `a < b`, `a <= b`,
// `a > b`, `a >= b` into SymEngine's named-function form so the
// expression flows through the generic `evaluate` path. SymEngine
// itself isn't loaded in `flutter test` headless runs, so we only
// pin the rewrite shape + the boolean-result normalizer here.
// End-to-end constant-folding through `Eq(2, 2) → True` runs in
// the on-device builds.

import 'package:crisp_calc/engine/notepad_evaluator.dart';
import 'package:crisp_calc/utils/expression_preprocessing_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preprocessRelationalOperators — shape', () {
    test('== → Eq', () {
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('2 == 2'),
        'Eq(2, 2)',
      );
    });

    test('!= → Ne', () {
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('a != b'),
        'Ne(a, b)',
      );
    });

    test('<= → Le (longest-match over <)', () {
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('x <= 5'),
        'Le(x, 5)',
      );
    });

    test('>= → Ge (longest-match over >)', () {
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('x >= 5'),
        'Ge(x, 5)',
      );
    });

    test('< → Lt', () {
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('3 < 5'),
        'Lt(3, 5)',
      );
    });

    test('> → Gt', () {
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('7 > 3'),
        'Gt(7, 3)',
      );
    });

    test('symbolic operands preserved', () {
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('x == y'),
        'Eq(x, y)',
      );
    });

    test('whitespace-free input', () {
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('2==2'),
        'Eq(2, 2)',
      );
    });

    test('compound LHS gets carried through', () {
      // V1 leaves the LHS as-is rather than trying to parenthesize —
      // SymEngine's parser handles the natural infix arithmetic.
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('x + 1 < 5'),
        'Lt(x + 1, 5)',
      );
    });
  });

  group('preprocessRelationalOperators — non-matches', () {
    test('plain arithmetic untouched', () {
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('x + 1'),
        'x + 1',
      );
    });

    test('single `=` is left for assignment / solver', () {
      // Round 110 deliberately doesn't touch single-equal: that's
      // still assignment territory (or `_solveBareEquation` for
      // calculator input with letters and an `=`).
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('x = 5'),
        'x = 5',
      );
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators(
            '2*x + 3 = 0'),
        '2*x + 3 = 0',
      );
    });

    test('relational inside parens stays inside', () {
      // Top-level scan only — a parenthesized `<` isn't lifted out.
      // The whole expression has no top-level relational so we get
      // it back unchanged. The inner relational still gets lowered
      // when SymEngine parses `(x < 5)` — but that's the engine's
      // job, not the preprocessor's.
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('(x < 5)'),
        '(x < 5)',
      );
    });

    test('empty operand bails (defensive)', () {
      // `< 5` and `5 <` have empty LHS/RHS — return unchanged so the
      // engine sees the original syntax error rather than a malformed
      // `Lt(, 5)` we'd have to fix downstream.
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('< 5'),
        '< 5',
      );
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators('5 <'),
        '5 <',
      );
    });

    test('first top-level operator wins', () {
      // `x < 5 and y > 3` — V1 rewrites the first relational only;
      // round 111 will pick up the `and`. Until then the expression
      // ends up `Lt(x, 5 and y > 3)` which SymEngine will reject —
      // that's fine for round 110; chaining isn't a documented
      // feature yet.
      expect(
        ExpressionPreprocessingUtils.preprocessRelationalOperators(
            'x < 5 and y > 3'),
        'Lt(x, 5 and y > 3)',
      );
    });
  });

  group('normalizeBooleanResult', () {
    test('SymEngine True → lowercase true', () {
      expect(
          ExpressionPreprocessingUtils.normalizeBooleanResult('True'), 'true');
    });

    test('SymEngine False → lowercase false', () {
      expect(ExpressionPreprocessingUtils.normalizeBooleanResult('False'),
          'false');
    });

    test('trims whitespace before matching', () {
      expect(ExpressionPreprocessingUtils.normalizeBooleanResult('  True  '),
          'true');
    });

    test('non-boolean strings pass through unchanged', () {
      expect(ExpressionPreprocessingUtils.normalizeBooleanResult('Eq(x, 1)'),
          'Eq(x, 1)');
      expect(ExpressionPreprocessingUtils.normalizeBooleanResult('42'), '42');
      expect(ExpressionPreprocessingUtils.normalizeBooleanResult(''), '');
    });
  });

  group('notepad classify — assignment vs relational', () {
    test('`x == 1` classifies as expression, not assignment', () {
      // With the tightened regex (`=(?!=)`), the double-equal no
      // longer matches the assignment route — it falls through to
      // expression and the relational rewrite catches it in the
      // dispatcher.
      final parsed =
          classifyNotepadLine('x == 1', lineIndex: 0, firstCodeLineIndex: 0);
      expect(parsed.kind, NotepadLineKind.expression);
      expect(parsed.body, 'x == 1');
    });

    test('single-equal still routes through assignment', () {
      final parsed =
          classifyNotepadLine('x = 1', lineIndex: 0, firstCodeLineIndex: 0);
      expect(parsed.kind, NotepadLineKind.assignment);
      expect(parsed.name, 'x');
      expect(parsed.body, '1');
    });

    test('`x <= 5` is an expression (not an assignment)', () {
      final parsed =
          classifyNotepadLine('x <= 5', lineIndex: 0, firstCodeLineIndex: 0);
      expect(parsed.kind, NotepadLineKind.expression);
    });

    test('`x != y` is an expression', () {
      final parsed =
          classifyNotepadLine('x != y', lineIndex: 0, firstCodeLineIndex: 0);
      expect(parsed.kind, NotepadLineKind.expression);
    });
  });
}
