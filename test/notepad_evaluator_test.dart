// test/notepad_evaluator_test.dart
//
// Phase 2 acceptance: line classification, document-scope build,
// scope-name substitution, `Ans` resolution, and `use` directive
// handling.

import 'package:crisp_calc/engine/notepad.dart';
import 'package:crisp_calc/engine/notepad_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedNotepadLine classify(
  String source, {
  int lineIndex = 0,
  int firstCodeLineIndex = 0,
}) =>
    classifyNotepadLine(source,
        lineIndex: lineIndex, firstCodeLineIndex: firstCodeLineIndex);

NotepadDocument docOf(List<({String source, String? cached})> spec) {
  return NotepadDocument(
    id: 'test-doc',
    name: 'Test',
    createdAt: DateTime.utc(2026, 5, 25),
    updatedAt: DateTime.utc(2026, 5, 25),
    lines: [
      for (final s in spec)
        NotepadLine(
          id: 'l${spec.indexOf(s)}',
          source: s.source,
          cachedResult: s.cached,
        ),
    ],
  );
}

void main() {
  group('classifyNotepadLine', () {
    test('blank line', () {
      expect(classify('').kind, NotepadLineKind.blank);
      expect(classify('   ').kind, NotepadLineKind.blank);
      expect(classify('\t').kind, NotepadLineKind.blank);
    });

    test('full-line comment with //', () {
      final p = classify('// hello world');
      expect(p.kind, NotepadLineKind.comment);
      expect(p.body, isNull);
    });

    test('full-line comment with #', () {
      expect(classify('# python style').kind, NotepadLineKind.comment);
    });

    test('full-line comment with leading whitespace', () {
      expect(classify('   // indented').kind, NotepadLineKind.comment);
    });

    test('mid-line comment is stripped, expression remains', () {
      final p = classify('2 + 3 // sum');
      expect(p.kind, NotepadLineKind.expression);
      expect(p.body, '2 + 3');
    });

    test('mid-line # comment is stripped from an assignment', () {
      final p = classify('tax = 0.085 # standard rate');
      expect(p.kind, NotepadLineKind.assignment);
      expect(p.name, 'tax');
      expect(p.body, '0.085');
    });

    test('assignment with single-letter LHS', () {
      final p = classify('x = 5');
      expect(p.kind, NotepadLineKind.assignment);
      expect(p.name, 'x');
      expect(p.body, '5');
    });

    test('assignment with multi-char identifier LHS', () {
      final p = classify('subtotal = 142.50');
      expect(p.kind, NotepadLineKind.assignment);
      expect(p.name, 'subtotal');
      expect(p.body, '142.50');
    });

    test('assignment with underscore in LHS', () {
      expect(classify('my_var = 1').name, 'my_var');
    });

    test('LHS with operator is NOT an assignment — falls through', () {
      final p = classify('x^2 = 4');
      expect(p.kind, NotepadLineKind.expression);
      expect(p.body, 'x^2 = 4');
    });

    test('reserved CAS name as LHS falls through to expression', () {
      for (final reserved in ['sin', 'cos', 'integrate', 'pi', 'Matrix']) {
        final p = classify('$reserved = 1');
        expect(p.kind, NotepadLineKind.expression,
            reason: '$reserved should NOT be assignable');
      }
    });

    test('Ans and use are reserved and fall through', () {
      expect(classify('Ans = 5').kind, NotepadLineKind.expression);
      expect(classify('use = 5').kind, NotepadLineKind.expression);
    });

    test('LHS with leading digit is not an assignment', () {
      final p = classify('2x = 5');
      expect(p.kind, NotepadLineKind.expression);
    });

    test('empty RHS falls through to expression (not a valid assignment)', () {
      final p = classify('x =');
      expect(p.kind, NotepadLineKind.expression);
    });

    test('plain expression', () {
      final p = classify('5 + 3 * 2');
      expect(p.kind, NotepadLineKind.expression);
      expect(p.body, '5 + 3 * 2');
    });

    test('expression with unit syntax remains an expression', () {
      final p = classify('5 km + 3 m');
      expect(p.kind, NotepadLineKind.expression);
      expect(p.body, '5 km + 3 m');
    });
  });

  group('use directive', () {
    test('valid use on first line is a useDirective', () {
      final p = classify('use tax, f, g', lineIndex: 0, firstCodeLineIndex: 0);
      expect(p.kind, NotepadLineKind.useDirective);
      expect(p.imports, ['tax', 'f', 'g']);
      expect(p.directiveError, isNull);
    });

    test('use with single import', () {
      final p = classify('use tax', lineIndex: 0, firstCodeLineIndex: 0);
      expect(p.imports, ['tax']);
    });

    test('use on second non-blank line falls through to expression', () {
      final p = classify('use tax', lineIndex: 1, firstCodeLineIndex: 0);
      expect(p.kind, NotepadLineKind.expression);
      expect(p.body, 'use tax');
    });

    test('use after a leading blank still counts as first code line', () {
      // Doc is: [blank, "use tax", "tax * 2"]. firstCodeLineIndex = 1.
      final p = classify('use tax', lineIndex: 1, firstCodeLineIndex: 1);
      expect(p.kind, NotepadLineKind.useDirective);
    });

    test('use after leading comments still counts as first code line', () {
      // Doc is: ["// hi", "use tax"]. firstCodeLineIndex = 1.
      final p = classify('use tax', lineIndex: 1, firstCodeLineIndex: 1);
      expect(p.kind, NotepadLineKind.useDirective);
    });

    test('use with trailing comma is fine', () {
      final p =
          classify('use a, b,', lineIndex: 0, firstCodeLineIndex: 0);
      expect(p.imports, ['a', 'b']);
      expect(p.directiveError, isNull);
    });

    test('use dedupes', () {
      final p = classify('use a, b, a', lineIndex: 0, firstCodeLineIndex: 0);
      expect(p.imports, ['a', 'b']);
    });

    test('use with invalid identifier flags directiveError', () {
      final p =
          classify('use 2x, tax', lineIndex: 0, firstCodeLineIndex: 0);
      expect(p.kind, NotepadLineKind.useDirective);
      expect(p.directiveError, 'invalidImport:2x');
    });

    test('use with only whitespace flags emptyImportList', () {
      final p = classify('use   ,  ,', lineIndex: 0, firstCodeLineIndex: 0);
      expect(p.kind, NotepadLineKind.useDirective);
      expect(p.directiveError, 'emptyImportList');
    });

    test('use with a trailing comment still parses', () {
      final p = classify('use tax // import the rate',
          lineIndex: 0, firstCodeLineIndex: 0);
      expect(p.kind, NotepadLineKind.useDirective);
      expect(p.imports, ['tax']);
    });
  });

  group('firstCodeLineIndexOf', () {
    test('empty doc returns -1', () {
      final doc = docOf([]);
      expect(firstCodeLineIndexOf(doc), -1);
    });

    test('all blanks returns -1', () {
      final doc = docOf([
        (source: '', cached: null),
        (source: '   ', cached: null),
      ]);
      expect(firstCodeLineIndexOf(doc), -1);
    });

    test('all comments returns -1', () {
      final doc = docOf([
        (source: '// a', cached: null),
        (source: '# b', cached: null),
      ]);
      expect(firstCodeLineIndexOf(doc), -1);
    });

    test('first code line after blanks + comments', () {
      final doc = docOf([
        (source: '', cached: null),
        (source: '// hi', cached: null),
        (source: 'tax = 0.085', cached: '0.085'),
        (source: 'tax * 2', cached: '0.17'),
      ]);
      expect(firstCodeLineIndexOf(doc), 2);
    });

    test('first code line is line 0', () {
      final doc = docOf([
        (source: 'use tax', cached: null),
        (source: 'tax + 1', cached: null),
      ]);
      expect(firstCodeLineIndexOf(doc), 0);
    });
  });

  group('buildNotepadScope', () {
    test('empty doc returns empty scope', () {
      expect(buildNotepadScope(docOf([])), isEmpty);
    });

    test('lines without cached results contribute nothing', () {
      final doc = docOf([
        (source: 'tax = 0.085', cached: null),
      ]);
      expect(buildNotepadScope(doc), isEmpty);
    });

    test('assignment contributes both explicit name and lineN alias', () {
      final doc = docOf([
        (source: 'tax = 0.085', cached: '0.085'),
      ]);
      final scope = buildNotepadScope(doc);
      expect(scope['tax'], '0.085');
      expect(scope['line1'], '0.085');
    });

    test('plain expression contributes only the lineN alias', () {
      final doc = docOf([
        (source: '5 + 3', cached: '8'),
      ]);
      final scope = buildNotepadScope(doc);
      expect(scope['line1'], '8');
      expect(scope.length, 1);
    });

    test('comments and blanks do not contribute', () {
      final doc = docOf([
        (source: '// hi', cached: null),
        (source: '', cached: null),
        (source: 'tax = 0.085', cached: '0.085'),
      ]);
      final scope = buildNotepadScope(doc);
      // Auto-alias is 1-based on the line's *actual* position, not
      // a "code-line count" — so the tax line is line3.
      expect(scope['line3'], '0.085');
      expect(scope['tax'], '0.085');
      expect(scope.containsKey('line1'), isFalse);
      expect(scope.containsKey('line2'), isFalse);
    });

    test('useDirective does not contribute a result', () {
      final doc = docOf([
        // Even if cached somehow, a use directive isn't a value.
        (source: 'use tax', cached: 'whatever'),
        (source: 'tax + 1', cached: '1.085'),
      ]);
      final scope = buildNotepadScope(doc);
      expect(scope.containsKey('use'), isFalse);
      expect(scope['line2'], '1.085');
    });

    test('later assignment of the same name overwrites earlier', () {
      final doc = docOf([
        (source: 'x = 5', cached: '5'),
        (source: 'x = 10', cached: '10'),
      ]);
      final scope = buildNotepadScope(doc);
      expect(scope['x'], '10');
      expect(scope['line1'], '5');
      expect(scope['line2'], '10');
    });

    test('externalScope is seeded first', () {
      final doc = docOf([]);
      final scope = buildNotepadScope(doc,
          externalScope: {'imported': '42'});
      expect(scope['imported'], '42');
    });

    test('in-doc assignment shadows external scope on collision', () {
      final doc = docOf([
        (source: 'tax = 0.085', cached: '0.085'),
      ]);
      final scope = buildNotepadScope(doc,
          externalScope: {'tax': '0.10'});
      expect(scope['tax'], '0.085');
    });
  });

  group('preprocessNotepadLine — scope substitution', () {
    test('substitutes a single name', () {
      final doc = docOf([
        (source: 'tax = 0.085', cached: '0.085'),
        (source: 'tax * 2', cached: null),
      ]);
      final scope = buildNotepadScope(doc);
      final parsed = classify('tax * 2',
          lineIndex: 1, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 1, scope: scope);
      expect(out, '(0.085) * 2');
    });

    test('substitutes lineN alias', () {
      final doc = docOf([
        (source: '5 + 3', cached: '8'),
        (source: 'line1 * 2', cached: null),
      ]);
      final scope = buildNotepadScope(doc);
      final parsed = classify('line1 * 2',
          lineIndex: 1, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 1, scope: scope);
      expect(out, '(8) * 2');
    });

    test('word-boundary anchored: pi does not splice into epigraph', () {
      // (epigraph isn't a real CAS thing, but it makes the point.)
      final doc = docOf([
        (source: 'pi_thing = 3', cached: '3'),
        (source: 'epigraph + pi_thing', cached: null),
      ]);
      // Manually seed scope to test the substitution rule.
      final scope = {'pi_thing': '3'};
      final parsed = classify('epigraph + pi_thing',
          lineIndex: 1, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 1, scope: scope);
      expect(out, 'epigraph + (3)');
    });

    test('longest-first ordering: total2 wins over total', () {
      final scope = {'total': '10', 'total2': '20'};
      final doc = docOf([(source: 'total2 + total', cached: null)]);
      final parsed = classify('total2 + total',
          lineIndex: 0, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 0, scope: scope);
      expect(out, '(20) + (10)');
    });

    test('blank / comment / useDirective return null', () {
      final doc = docOf([(source: '', cached: null)]);
      expect(
          preprocessNotepadLine(ParsedNotepadLine.blank(),
              doc: doc, lineIndex: 0, scope: {}),
          isNull);
      expect(
          preprocessNotepadLine(ParsedNotepadLine.comment(),
              doc: doc, lineIndex: 0, scope: {}),
          isNull);
      expect(
          preprocessNotepadLine(ParsedNotepadLine.useDirective(['x']),
              doc: doc, lineIndex: 0, scope: {}),
          isNull);
    });

    test('expression without any scope refs is returned verbatim', () {
      final doc = docOf([(source: '5 + 3', cached: null)]);
      final parsed = classify('5 + 3',
          lineIndex: 0, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 0, scope: {});
      expect(out, '5 + 3');
    });
  });

  group('preprocessNotepadLine — Ans resolution', () {
    test('Ans resolves to nearest non-blank line above', () {
      final doc = docOf([
        (source: '5 + 3', cached: '8'),
        (source: 'Ans * 2', cached: null),
      ]);
      final parsed = classify('Ans * 2',
          lineIndex: 1, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 1, scope: {});
      expect(out, '(8) * 2');
    });

    test('Ans skips blank lines', () {
      final doc = docOf([
        (source: '5 + 3', cached: '8'),
        (source: '', cached: null),
        (source: 'Ans + 1', cached: null),
      ]);
      final parsed = classify('Ans + 1',
          lineIndex: 2, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 2, scope: {});
      expect(out, '(8) + 1');
    });

    test('Ans skips comments', () {
      final doc = docOf([
        (source: '5 + 3', cached: '8'),
        (source: '// hi', cached: null),
        (source: 'Ans + 1', cached: null),
      ]);
      final parsed = classify('Ans + 1',
          lineIndex: 2, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 2, scope: {});
      expect(out, '(8) + 1');
    });

    test('Ans on line 0 is unresolved (no line above)', () {
      final doc = docOf([(source: 'Ans + 1', cached: null)]);
      final parsed = classify('Ans + 1',
          lineIndex: 0, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 0, scope: {});
      // Ans wasn't substituted — engine will see literal `Ans`.
      expect(out, 'Ans + 1');
    });

    test('Ans is unresolved when nearest line above has no cached result', () {
      final doc = docOf([
        (source: '1/0', cached: null), // errored, no cachedResult
        (source: 'Ans + 1', cached: null),
      ]);
      final parsed = classify('Ans + 1',
          lineIndex: 1, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 1, scope: {});
      expect(out, 'Ans + 1');
    });

    test('Ans is word-boundary anchored: AnsOther is left alone', () {
      final doc = docOf([
        (source: '5', cached: '5'),
        (source: 'AnsOther + Ans', cached: null),
      ]);
      final parsed = classify('AnsOther + Ans',
          lineIndex: 1, firstCodeLineIndex: 0);
      final out = preprocessNotepadLine(parsed,
          doc: doc, lineIndex: 1, scope: {});
      expect(out, 'AnsOther + (5)');
    });
  });

  group('integration: Welcome sample doc classifies as expected', () {
    test('every line of the Welcome doc parses correctly', () {
      final welcome = buildWelcomeNotepadDocument();
      final firstCode = firstCodeLineIndexOf(welcome);
      expect(firstCode, 1, reason: 'line 0 is the comment header');

      final kinds = <NotepadLineKind>[];
      for (var i = 0; i < welcome.lines.length; i++) {
        kinds.add(classify(welcome.lines[i].source,
                lineIndex: i, firstCodeLineIndex: firstCode)
            .kind);
      }
      expect(kinds, [
        NotepadLineKind.comment, // 0: header
        NotepadLineKind.assignment, // 1: tax = 0.085
        NotepadLineKind.expression, // 2: 142.50 * (1 + tax)
        NotepadLineKind.expression, // 3: 5 km + 3000 m
        NotepadLineKind.expression, // 4: Ans in miles
        NotepadLineKind.comment, // 5: trailer
      ]);
    });
  });

  // -------------------------------------------------------------------------
  // Phase 3 — dependency graph + evaluator.
  // -------------------------------------------------------------------------

  group('identifierWordsIn', () {
    test('plain identifiers', () {
      expect(identifierWordsIn('a + b * c'), {'a', 'b', 'c'});
    });

    test('ignores numbers', () {
      expect(identifierWordsIn('2 * 3 + 4'), isEmpty);
    });

    test('underscore allowed', () {
      expect(identifierWordsIn('my_var + foo_bar2'),
          {'my_var', 'foo_bar2'});
    });

    test('digit-leading words are not identifiers', () {
      // `5km` extracts `km` only — leading digit doesn't start an id.
      expect(identifierWordsIn('5km + 3m'), {'km', 'm'});
    });

    test('reserved CAS names show up too', () {
      // identifierWordsIn doesn't filter; callers decide.
      expect(identifierWordsIn('sin(x) + pi'), {'sin', 'x', 'pi'});
    });

    test('duplicate words collapsed', () {
      expect(identifierWordsIn('x + x * x'), {'x'});
    });
  });

  group('dependenciesOfLine + freeVariablesOfLine', () {
    test('expression with one in-scope ref', () {
      final parsed = classify('tax * 2',
          lineIndex: 1, firstCodeLineIndex: 0);
      expect(dependenciesOfLine(parsed, {'tax'}), {'tax'});
      expect(freeVariablesOfLine(parsed, {'tax'}), isEmpty);
    });

    test('expression with one out-of-scope ref → free var', () {
      final parsed = classify('foo + 1',
          lineIndex: 0, firstCodeLineIndex: 0);
      expect(dependenciesOfLine(parsed, {'tax'}), isEmpty);
      expect(freeVariablesOfLine(parsed, {'tax'}), {'foo'});
    });

    test('reserved CAS names are not free vars', () {
      final parsed = classify('sin(x) + pi',
          lineIndex: 0, firstCodeLineIndex: 0);
      expect(freeVariablesOfLine(parsed, {}), {'x'});
    });

    test('Ans is not a free var', () {
      final parsed = classify('Ans + foo',
          lineIndex: 1, firstCodeLineIndex: 0);
      expect(freeVariablesOfLine(parsed, {}), {'foo'});
    });

    test('blank / comment / useDirective return empty deps', () {
      expect(dependenciesOfLine(ParsedNotepadLine.blank(), {'x'}), isEmpty);
      expect(dependenciesOfLine(ParsedNotepadLine.comment(), {'x'}), isEmpty);
      expect(
          dependenciesOfLine(
              ParsedNotepadLine.useDirective(['tax']), {'x'}),
          isEmpty);
    });
  });

  group('buildDependencyGraph', () {
    test('empty doc has zero edges', () {
      final g = buildDependencyGraph(docOf([]));
      expect(g.dependsOn, isEmpty);
      expect(g.dependents, isEmpty);
    });

    test('single line with no refs has empty dep set', () {
      final g = buildDependencyGraph(
          docOf([(source: '5 + 3', cached: null)]));
      expect(g.dependsOn[0], isEmpty);
      expect(g.dependents[0], isEmpty);
    });

    test('explicit-name reference', () {
      final g = buildDependencyGraph(docOf([
        (source: 'tax = 0.085', cached: null),
        (source: 'tax * 2', cached: null),
      ]));
      expect(g.dependsOn[1], {0});
      expect(g.dependents[0], {1});
    });

    test('lineN-alias reference', () {
      final g = buildDependencyGraph(docOf([
        (source: '5 + 3', cached: null),
        (source: 'line1 * 2', cached: null),
      ]));
      expect(g.dependsOn[1], {0});
    });

    test('transitive chain', () {
      final g = buildDependencyGraph(docOf([
        (source: 'a = 1', cached: null),
        (source: 'b = a + 1', cached: null),
        (source: 'c = b + 1', cached: null),
      ]));
      expect(g.dependsOn[1], {0});
      expect(g.dependsOn[2], {1});
      expect(g.dependents[0], {1});
      expect(g.dependents[1], {2});
    });

    test('comments and blanks contribute no edges', () {
      final g = buildDependencyGraph(docOf([
        (source: 'a = 1', cached: null),
        (source: '// hi', cached: null),
        (source: '', cached: null),
        (source: 'a + 1', cached: null),
      ]));
      expect(g.dependsOn[1], isEmpty);
      expect(g.dependsOn[2], isEmpty);
      expect(g.dependsOn[3], {0});
    });

    test('external-scope-only ref produces no in-doc edge', () {
      final g = buildDependencyGraph(
          docOf([(source: 'imported * 2', cached: null)]),
          externalScope: {'imported': '42'});
      expect(g.dependsOn[0], isEmpty);
    });

    test('self-reference via lineN alias is a self-loop', () {
      final g = buildDependencyGraph(docOf([
        (source: 'line1 + 1', cached: null),
      ]));
      expect(g.dependsOn[0], {0});
      expect(g.dependents[0], {0});
    });
  });

  group('kahnTopologicalOrder', () {
    test('empty graph', () {
      final g = buildDependencyGraph(docOf([]));
      expect(kahnTopologicalOrder(g), isEmpty);
    });

    test('linear chain in dependency order', () {
      final g = buildDependencyGraph(docOf([
        (source: 'a = 1', cached: null),
        (source: 'b = a + 1', cached: null),
        (source: 'c = b + 1', cached: null),
      ]));
      expect(kahnTopologicalOrder(g), [0, 1, 2]);
    });

    test('parallel branches both before the join', () {
      final g = buildDependencyGraph(docOf([
        (source: 'a = 1', cached: null),
        (source: 'b = 2', cached: null),
        (source: 'c = a + b', cached: null),
      ]));
      final order = kahnTopologicalOrder(g);
      expect(order.indexOf(0), lessThan(order.indexOf(2)));
      expect(order.indexOf(1), lessThan(order.indexOf(2)));
    });

    test('cycle nodes excluded from order', () {
      final g = buildDependencyGraph(docOf([
        (source: 'a = b + 1', cached: null),
        (source: 'b = a + 1', cached: null),
        (source: 'c = 5', cached: null),
      ]));
      final order = kahnTopologicalOrder(g);
      expect(order, [2]); // only c gets ordered
    });
  });

  group('findCycleParticipants', () {
    test('no cycles', () {
      final g = buildDependencyGraph(docOf([
        (source: 'a = 1', cached: null),
        (source: 'a + 1', cached: null),
      ]));
      expect(findCycleParticipants(g), isEmpty);
    });

    test('two-cycle', () {
      final g = buildDependencyGraph(docOf([
        (source: 'a = b + 1', cached: null),
        (source: 'b = a + 1', cached: null),
      ]));
      expect(findCycleParticipants(g), {0, 1});
    });

    test('self-loop', () {
      final g = buildDependencyGraph(docOf([
        (source: 'x = x + 1', cached: null),
      ]));
      expect(findCycleParticipants(g), {0});
    });

    test('cycle plus innocent bystander', () {
      final g = buildDependencyGraph(docOf([
        (source: 'a = b', cached: null),
        (source: 'b = a', cached: null),
        (source: '5 + 3', cached: null),
      ]));
      expect(findCycleParticipants(g), {0, 1});
    });
  });

  group('downstreamFrom', () {
    test('isolated node only includes itself', () {
      final g = buildDependencyGraph(docOf([
        (source: '5 + 3', cached: null),
      ]));
      expect(downstreamFrom(0, g), {0});
    });

    test('transitive downstream', () {
      final g = buildDependencyGraph(docOf([
        (source: 'a = 1', cached: null),
        (source: 'b = a + 1', cached: null),
        (source: 'c = b + 1', cached: null),
        (source: 'd = a + 1', cached: null),
      ]));
      // Editing line 0 should ripple to b, c, d.
      expect(downstreamFrom(0, g), {0, 1, 2, 3});
      // Editing line 1 should ripple to c only (d branches off a).
      expect(downstreamFrom(1, g), {1, 2});
      // Editing line 2 ripples to itself only.
      expect(downstreamFrom(2, g), {2});
    });
  });

  // ---- NotepadEvaluator integration ----

  // Stub dispatcher helper: echo the input back as the "result".
  NotepadEngineDispatcher echo() => (expr) async => expr;

  group('NotepadEvaluator.evaluateAll', () {
    test('all lines populated when engine echoes', () async {
      final doc = docOf([
        (source: 'tax = 0.085', cached: null),
        (source: 'tax * 2', cached: null),
      ]);
      final ev = NotepadEvaluator(dispatcher: echo());
      await ev.evaluateAll(doc);
      // tax line evaluated with body 0.085 → echo returns '0.085'.
      expect(doc.lines[0].cachedResult, '0.085');
      expect(doc.lines[0].cachedError, isNull);
      // Second line preprocessed body is '(0.085) * 2'; echo returns it.
      expect(doc.lines[1].cachedResult, '(0.085) * 2');
      expect(doc.lines[1].cachedError, isNull);
    });

    test('blank and comment lines cleared', () async {
      final doc = docOf([
        (source: '', cached: 'stale'),
        (source: '// hi', cached: 'stale'),
        (source: 'a = 1', cached: null),
      ]);
      final ev = NotepadEvaluator(dispatcher: echo());
      await ev.evaluateAll(doc);
      expect(doc.lines[0].cachedResult, isNull);
      expect(doc.lines[0].cachedError, isNull);
      expect(doc.lines[1].cachedResult, isNull);
      expect(doc.lines[1].cachedError, isNull);
    });

    test('useDirective with no error → cleared', () async {
      final doc = docOf([
        (source: 'use tax', cached: 'stale'),
        (source: '5 + 3', cached: null),
      ]);
      final ev = NotepadEvaluator(dispatcher: echo());
      await ev.evaluateAll(doc);
      expect(doc.lines[0].cachedResult, isNull);
      expect(doc.lines[0].cachedError, isNull);
    });

    test('useDirective with invalid import → cached error with prefix',
        () async {
      final doc = docOf([
        (source: 'use 2x', cached: null),
      ]);
      final ev = NotepadEvaluator(dispatcher: echo());
      await ev.evaluateAll(doc);
      expect(doc.lines[0].cachedError, startsWith('useDirective:'));
      expect(doc.lines[0].cachedError, contains('invalidImport:2x'));
    });

    test('engine error → cachedError prefixed evaluation:', () async {
      final doc = docOf([(source: '1/0', cached: null)]);
      final ev = NotepadEvaluator(
          dispatcher: (_) async => 'Error: divide by zero');
      await ev.evaluateAll(doc);
      expect(doc.lines[0].cachedResult, isNull);
      expect(doc.lines[0].cachedError,
          'evaluation:Error: divide by zero');
    });

    test('downstream of errored line gets blockedBy with correct alias',
        () async {
      final doc = docOf([
        (source: 'a = 1/0', cached: null),
        (source: 'b = a + 1', cached: null),
        (source: 'c = b + 1', cached: null),
      ]);
      // Engine errors only on the 1/0 expression; everything else echoes.
      final ev = NotepadEvaluator(
        dispatcher: (expr) async =>
            expr.contains('1/0') ? 'Error: divide by zero' : expr,
      );
      await ev.evaluateAll(doc);
      expect(doc.lines[0].cachedError,
          'evaluation:Error: divide by zero');
      expect(doc.lines[1].cachedError, startsWith('blockedBy:'));
      expect(doc.lines[1].cachedError, contains(':line1'));
      // Transitive: c is blocked by b (its immediate upstream).
      expect(doc.lines[2].cachedError, startsWith('blockedBy:'));
      expect(doc.lines[2].cachedError, contains(':line2'));
    });

    test('cycle participants get circularReference error', () async {
      final doc = docOf([
        (source: 'a = b + 1', cached: null),
        (source: 'b = a + 1', cached: null),
        (source: 'c = 5', cached: null),
      ]);
      final ev = NotepadEvaluator(dispatcher: echo());
      await ev.evaluateAll(doc);
      expect(doc.lines[0].cachedError,
          startsWith('circularReference:'));
      expect(doc.lines[1].cachedError,
          startsWith('circularReference:'));
      // The innocent line c still evaluates.
      expect(doc.lines[2].cachedResult, '5');
      expect(doc.lines[2].cachedError, isNull);
    });

    test('self-reference is a cycle (one-element)', () async {
      final doc = docOf([
        (source: 'x = x + 1', cached: null),
      ]);
      final ev = NotepadEvaluator(dispatcher: echo());
      await ev.evaluateAll(doc);
      expect(doc.lines[0].cachedError,
          startsWith('circularReference:'));
    });

    test('free vars populated on success', () async {
      final doc = docOf([
        (source: 'a = 1', cached: null),
        (source: 'a + foo + bar', cached: null),
      ]);
      final ev = NotepadEvaluator(dispatcher: echo());
      await ev.evaluateAll(doc);
      expect(doc.lines[1].cachedFreeVars.toSet(), {'foo', 'bar'});
    });

    test('free vars excluded for reserved names', () async {
      final doc = docOf([
        (source: 'sin(x) + pi', cached: null),
      ]);
      final ev = NotepadEvaluator(dispatcher: echo());
      await ev.evaluateAll(doc);
      // pi + sin are reserved; only x is free.
      expect(doc.lines[0].cachedFreeVars, ['x']);
    });

    test('Ans substituted before dispatch', () async {
      String? lastDispatched;
      final ev = NotepadEvaluator(dispatcher: (expr) async {
        lastDispatched = expr;
        return expr;
      });
      final doc = docOf([
        (source: '5 + 3', cached: null),
        (source: 'Ans * 2', cached: null),
      ]);
      await ev.evaluateAll(doc);
      // Line 1 dispatcher saw the substituted form, not literal `Ans`.
      expect(lastDispatched, '(5 + 3) * 2');
    });

    test('externalScope contributes to substitution and free-var filter',
        () async {
      final doc = docOf([
        (source: 'imported + foo', cached: null),
      ]);
      final ev = NotepadEvaluator(
        dispatcher: echo(),
        externalScope: {'imported': '42'},
      );
      await ev.evaluateAll(doc);
      expect(doc.lines[0].cachedResult, '(42) + foo');
      expect(doc.lines[0].cachedFreeVars, ['foo']);
    });
  });

  group('NotepadEvaluator.evaluateFrom', () {
    test('only the downstream subgraph is re-evaluated', () async {
      // Distinct multipliers so b and d preprocess to different
      // strings (otherwise touched-key collisions would mask the
      // assertion).
      final touched = <String, int>{};
      final ev = NotepadEvaluator(dispatcher: (expr) async {
        touched[expr] = (touched[expr] ?? 0) + 1;
        return expr;
      });
      final doc = docOf([
        (source: 'a = 1', cached: null),
        (source: 'b = a * 10', cached: null),
        (source: 'c = b * 100', cached: null),
        (source: 'd = a * 1000', cached: null),
      ]);
      // Full eval seeds everything.
      await ev.evaluateAll(doc);
      touched.clear();

      // Now evaluate-from line 1 (b). Should hit b and c, not a or d.
      await ev.evaluateFrom(doc, 1);
      // a's body is '1' — should NOT have been re-dispatched.
      expect(touched.containsKey('1'), isFalse);
      // d's body is '(1) * 1000' — should NOT have been re-dispatched.
      expect(touched.containsKey('(1) * 1000'), isFalse);
      // b touched once with '(1) * 10'.
      expect(touched['(1) * 10'], 1);
      // c touched once — its preprocessed body uses b's new echo result.
      expect(
          touched.keys.where((k) => k.contains('* 100')).length, 1);
    });

    test('editing a leaf node only re-evaluates that node', () async {
      final touched = <String>[];
      final ev = NotepadEvaluator(dispatcher: (expr) async {
        touched.add(expr);
        return expr;
      });
      final doc = docOf([
        (source: 'a = 1', cached: null),
        (source: 'b = a + 1', cached: null),
      ]);
      await ev.evaluateAll(doc);
      touched.clear();

      // b is a leaf — nothing depends on it.
      await ev.evaluateFrom(doc, 1);
      expect(touched.length, 1);
    });
  });

  group('error encoding round-trip', () {
    test('blockedBy format', () {
      final encoded = NotepadErrorPrefix.blocked('l-abc-123', 'line5');
      expect(encoded, 'blockedBy:l-abc-123:line5');
    });

    test('circularReference format', () {
      final encoded = NotepadErrorPrefix.circular(['a', 'b', 'a']);
      expect(encoded, 'circularReference:a→b→a');
    });

    test('evaluation format wraps engine error', () {
      final encoded = NotepadErrorPrefix.fromEngine('Error: parse failed');
      expect(encoded, 'evaluation:Error: parse failed');
    });
  });
}
