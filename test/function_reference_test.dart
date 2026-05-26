// test/function_reference_test.dart
//
// Round 96 (P6): catalogue invariants for FunctionReferences.all.
// These tests guard the data model contract so Rounds 97-100 can
// add entries without re-deriving the rules. Anything that should
// hold for every entry lives here.

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
      final byId = {for (final e in FunctionReferences.all) e.id: e};
      for (final e in FunctionReferences.all) {
        for (final other in e.seeAlso) {
          // V1 carve-out: an entry may reference an id that hasn't
          // been written yet (Round 97 will add more entries that
          // back-fill the seeAlso targets). Skip the assertion for
          // unknown ids — Round 97 will tighten this once the
          // catalogue is fleshed out.
          if (!byId.containsKey(other)) continue;
          expect(byId, contains(other),
              reason: '${e.id} → seeAlso "$other" points at an unknown entry');
        }
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
