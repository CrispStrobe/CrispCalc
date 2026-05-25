// test/worked_examples_test.dart
//
// Sanity-checks the curated catalog so an accidental empty entry,
// duplicate, or wrong-category drift fails CI rather than ships.

import 'package:crisp_calc/engine/worked_examples.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkedExamples catalog', () {
    test('has at least one example in every category', () {
      final seen = <WorkedExampleCategory>{};
      for (final e in WorkedExamples.all) {
        seen.add(e.category);
      }
      expect(seen, equals(WorkedExampleCategory.values.toSet()),
          reason: 'every category should have at least one entry');
    });

    test('no empty title / description / expression', () {
      for (final e in WorkedExamples.all) {
        expect(e.title.trim(), isNotEmpty,
            reason: 'title empty for ${e.category}');
        expect(e.description.trim(), isNotEmpty,
            reason: 'description empty for ${e.title}');
        expect(e.expression.trim(), isNotEmpty,
            reason: 'expression empty for ${e.title}');
      }
    });

    test('titles are unique (no copy-paste drift)', () {
      final titles = WorkedExamples.all.map((e) => e.title).toList();
      expect(titles.toSet().length, titles.length,
          reason: 'duplicate titles in catalog');
    });

    test('ids are unique (V2 needs stable keys for translation lookup)', () {
      final ids = WorkedExamples.all.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'duplicate ids in catalog');
      for (final id in ids) {
        expect(id, isNotEmpty, reason: 'empty id in catalog');
      }
    });

    test('total entries is in the curated range', () {
      // V1 promised 12-20 entries; below 12 means we under-delivered.
      // Cap raised to 30 in round 73 to accommodate the constraints
      // category (Killer + DSL sentinels). If we go past 30 the
      // dialog should grow proper category-grouping rather than the
      // flat ListView it has today.
      expect(WorkedExamples.all.length, greaterThanOrEqualTo(12));
      expect(WorkedExamples.all.length, lessThanOrEqualTo(30));
    });

    test('round 69: constraints category surfaces Killer + DSL entries', () {
      final byId = {for (final e in WorkedExamples.all) e.id: e};
      expect(byId['killerSudoku']?.category, WorkedExampleCategory.constraints);
      expect(byId['killerSudoku']?.expression, 'open:sudoku');
      expect(byId['constraintEditor']?.category,
          WorkedExampleCategory.constraints);
      expect(byId['constraintEditor']?.expression, 'open:constraints');
    });

    test('round 69: every open: sentinel targets a known module', () {
      const knownModules = {'sudoku', 'constraints'};
      for (final e in WorkedExamples.all) {
        if (!e.expression.startsWith('open:')) continue;
        final module = e.expression.substring('open:'.length);
        expect(knownModules, contains(module),
            reason: '${e.id} targets unknown module "$module"');
      }
    });

    test('round 73: dsl: sentinels target known gallery ids', () {
      // The gallery lives inside _DslTabState; we mirror its ids
      // here so a catalog typo + a missing gallery entry fail CI
      // rather than silently load nothing.
      const knownDslIds = {
        'magicSum',
        'magicSquare3',
        'mapColoring',
        'orderedTriples',
        'coinChangeMin',
        'schedulingMakespan',
        'cumulativeScheduling',
      };
      var seen = 0;
      for (final e in WorkedExamples.all) {
        if (!e.expression.startsWith('dsl:')) continue;
        seen++;
        final id = e.expression.substring('dsl:'.length);
        expect(knownDslIds, contains(id),
            reason: '${e.id} targets unknown DSL gallery id "$id"');
      }
      expect(seen, greaterThan(0),
          reason:
              'expected at least one dsl:<id> sentinel — round 73 added three');
    });
  });
}
