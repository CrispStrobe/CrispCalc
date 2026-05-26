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
      // Cap matches the dialog's flat ListView assumption — past
      // ~60 entries the dialog should grow grouping by category.
      expect(FunctionReferences.all.length, greaterThan(0));
      expect(FunctionReferences.all.length, lessThanOrEqualTo(60));
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
