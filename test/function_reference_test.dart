// test/function_reference_test.dart
//
// P6 catalogue invariants for FunctionReferences.all. These tests
// guard the data model contract so the catalogue can grow without
// re-deriving the rules.
//
// Round 96 shipped the scaffolding + 3 seed entries; Round 97
// extends CAS + precision so the catalogue now resolves all of
// its own seeAlso pointers — the v1 carve-out is removed.

import 'package:crisp_calc/engine/function_reference.dart';
import 'package:crisp_calc/engine/worked_examples.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FunctionReferences catalogue invariants', () {
    test('round 96: seed list is non-empty and stays under cap', () {
      // Advisory cap on the dialog's flat ListView. Bumped to 70 once
      // the precision arc's Group B (continued fractions, polynomial
      // arithmetic, special functions) grew the catalogue past 60; the
      // dialog already scrolls + searches + filters by category chip,
      // so this is a soft guard, not a hard UX limit.
      expect(FunctionReferences.all.length, greaterThan(0));
      expect(FunctionReferences.all.length, lessThanOrEqualTo(70));
    });

    test('ids are non-empty, unique, and snake_case-shaped', () {
      final seen = <String>{};
      for (final e in FunctionReferences.all) {
        expect(e.id, isNotEmpty);
        expect(seen.add(e.id), isTrue, reason: 'duplicate id: ${e.id}');
        // Lowercase letters + digits + underscores. Forces a stable
        // i18n-friendly shape rather than the loose camelCase used
        // by WorkedExamples.
        expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(e.id), isTrue,
            reason: 'id "${e.id}" should be snake_case');
      }
    });

    test('every entry has a signature and short description', () {
      for (final e in FunctionReferences.all) {
        expect(e.signature, isNotEmpty, reason: '${e.id} has empty signature');
        expect(e.shortDescription, isNotEmpty,
            reason: '${e.id} has empty shortDescription');
      }
    });

    test('seeAlso ids resolve to other catalogue entries', () {
      // Round 97 tightens this from the v1 carve-out: every seeAlso
      // target must now resolve to a catalogue entry. Rounds 98-99
      // add matrix / stats / constraints; any new seeAlso pointer
      // either targets an existing entry or is added in the same
      // round as its target.
      final byId = {for (final e in FunctionReferences.all) e.id: e};
      for (final e in FunctionReferences.all) {
        for (final other in e.seeAlso) {
          expect(byId, contains(other),
              reason: '${e.id} → seeAlso "$other" points at an unknown entry');
        }
      }
    });

    test('round 97: catalogue covers the PLAN P6 §97 CAS slate', () {
      // PLAN §97 names ~15 CAS entries; `series` and `taylor` are
      // deferred (no SymEngine series_expansion binding yet) so the
      // expected list omits them. Anything else dropping from the
      // catalogue should be intentional and tracked here.
      final ids = {for (final e in FunctionReferences.all) e.id};
      const expectedCas = {
        'solve',
        'expand',
        'simplify',
        'factor',
        'diff',
        'integrate',
        'subst',
        'limit',
        'gcd',
        'lcm',
        'factorial',
        'fibonacci',
      };
      for (final id in expectedCas) {
        expect(ids, contains(id), reason: 'Round 97 CAS slate missing "$id"');
      }
    });

    test('round 97: precision arc covers all five MPFR/FLINT entries', () {
      final ids = {for (final e in FunctionReferences.all) e.id};
      const expectedPrecision = {
        'pi_precision',
        'e_precision',
        'sqrt_precision',
        'eulergamma_precision',
      };
      for (final id in expectedPrecision) {
        expect(ids, contains(id),
            reason: 'Round 97 precision arc missing "$id"');
      }
    });

    test('round 99: catalogue covers the stats / constraints / sudoku slate',
        () {
      // PLAN P6 §99 names ~15 module-surface entries; Round 99
      // ships 9 stats + 6 constraints + 4 sudoku = 19. All carry
      // `runnable: false` because they aren't directly calculator-
      // callable.
      final ids = {for (final e in FunctionReferences.all) e.id};
      const expectedStats = {
        'mean',
        'welch_t',
        'paired_t',
        'anova_1',
        'chi2_goodness',
        'chi2_independence',
        'fisher_exact',
        'wilcoxon',
        'sign_test',
      };
      const expectedConstraints = {
        'vars',
        'all_different',
        'no_overlap',
        'cumulative',
        'minimize',
        'maximize',
      };
      const expectedSudoku = {
        'sudoku_regular',
        'sudoku_x',
        'sudoku_disjoint',
        'sudoku_killer',
      };
      for (final id in {
        ...expectedStats,
        ...expectedConstraints,
        ...expectedSudoku
      }) {
        expect(ids, contains(id), reason: 'Round 99 slate missing "$id"');
      }
      // Round 99 entries are module-surface, not calculator-callable —
      // they must all carry runnable: false. Catches a regression
      // where a stats entry gets accidentally flagged runnable and
      // exposes a broken Try-in-Calculator button.
      final byId = {for (final e in FunctionReferences.all) e.id: e};
      for (final id in {
        ...expectedStats,
        ...expectedConstraints,
        ...expectedSudoku
      }) {
        expect(byId[id]!.runnable, isFalse,
            reason: 'Round 99 entry "$id" should carry runnable: false');
      }
    });

    test('round 98: catalogue covers the matrix / linear-algebra slate', () {
      // PLAN P6 §98 names det / inv / transpose / rref / Matrix(...)
      // syntax plus eigenvalues (the last "if shipped" — bridge has
      // no binding, so it stays deferred). Round 98 also folds the
      // matrix binary ops (+ / - / *) into one `matrix_arithmetic`
      // entry rather than spawning three near-duplicate rows.
      final ids = {for (final e in FunctionReferences.all) e.id};
      const expectedMatrix = {
        'matrix_literal',
        'det',
        'inv',
        'transpose',
        'rref',
        'matrix_arithmetic',
      };
      for (final id in expectedMatrix) {
        expect(ids, contains(id),
            reason: 'Round 98 matrix slate missing "$id"');
      }
    });

    test('workedExampleId, when present, resolves to WorkedExamples.all', () {
      final weIds = {for (final w in WorkedExamples.all) w.id};
      for (final e in FunctionReferences.all) {
        final id = e.workedExampleId;
        if (id == null) continue;
        expect(weIds, contains(id),
            reason: '${e.id}.workedExampleId="$id" not in WorkedExamples.all');
      }
    });

    test('examples have non-empty input + expected', () {
      for (final e in FunctionReferences.all) {
        for (final ex in e.examples) {
          expect(ex.input, isNotEmpty,
              reason: '${e.id} example has empty input');
          expect(ex.expected, isNotEmpty,
              reason: '${e.id} example has empty expected');
        }
      }
    });
  });

  group('FunctionRefCategory enum', () {
    test('contains all nine PLAN-specified categories', () {
      // PLAN P6 Round 96 spec — keep these names + count stable
      // so rounds 97-100 can target categories by name rather than
      // ordinal.
      expect(FunctionRefCategory.values.length, 9);
      expect(FunctionRefCategory.values.map((e) => e.name).toSet(), {
        'cas',
        'numberTheory',
        'precision',
        'matrix',
        'graphing',
        'statistics',
        'constraints',
        'sudoku',
        'units',
      });
    });
  });
}
