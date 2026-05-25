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
}
