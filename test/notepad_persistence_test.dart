// test/notepad_persistence_test.dart
//
// Phase 1 acceptance: NotepadDocument / NotepadLine round-trip
// through JSON, AppState persists them across reloads, first-launch
// seeding produces the expected pair (empty Untitled + static
// Welcome sample), and export/import handle the Welcome-sample
// recreation contract correctly.

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/notepad.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // AppState is a singleton; reset its mutable notepad state before
  // every test so prior tests can't leak through.
  setUp(() {
    final s = AppState();
    s.notepadDocuments.clear();
    s.setCurrentNotepadDoc(null);
  });

  group('NotepadLine JSON round-trip', () {
    test('source-only line round-trips', () {
      final original = NotepadLine.fresh(source: 'tax = 0.085');
      final restored = NotepadLine.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.source, 'tax = 0.085');
      expect(restored.cachedResult, isNull);
      expect(restored.cachedError, isNull);
      expect(restored.cachedFreeVars, isEmpty);
    });

    test('line with cached result + free vars round-trips', () {
      final original = NotepadLine(
        id: 'line-42',
        source: '2 * x + y',
        cachedResult: '2*x + y',
        cachedFreeVars: ['x', 'y'],
      );
      final json = original.toJson();
      expect(json['r'], '2*x + y');
      expect(json['f'], ['x', 'y']);
      final restored = NotepadLine.fromJson(json);
      expect(restored.id, 'line-42');
      expect(restored.cachedResult, '2*x + y');
      expect(restored.cachedFreeVars, ['x', 'y']);
    });

    test('line with cached error round-trips', () {
      final original = NotepadLine(
        id: 'line-err',
        source: '1/0',
        cachedError: 'Error: divide by zero',
      );
      final restored = NotepadLine.fromJson(original.toJson());
      expect(restored.cachedError, 'Error: divide by zero');
      expect(restored.cachedResult, isNull);
    });

    test('fromJson tolerates missing keys', () {
      final restored = NotepadLine.fromJson({});
      expect(restored.source, '');
      expect(restored.id, isNotEmpty);
    });
  });

  group('NotepadDocument JSON round-trip', () {
    test('empty doc round-trips', () {
      final doc = NotepadDocument.fresh(name: 'Test');
      final restored = NotepadDocument.fromJson(doc.toJson());
      expect(restored.id, doc.id);
      expect(restored.name, 'Test');
      expect(restored.lines.length, 1);
      expect(restored.lines.first.source, '');
    });

    test('multi-line doc preserves line order and content', () {
      final doc = NotepadDocument(
        id: 'doc-1',
        name: 'Sample',
        createdAt: DateTime.utc(2026, 5, 25, 10),
        updatedAt: DateTime.utc(2026, 5, 25, 11),
        lines: [
          NotepadLine(id: 'l1', source: 'a = 1'),
          NotepadLine(id: 'l2', source: 'b = 2'),
          NotepadLine(id: 'l3', source: 'a + b'),
        ],
      );
      final restored = NotepadDocument.fromJson(doc.toJson());
      expect(restored.lines.map((l) => l.source).toList(),
          ['a = 1', 'b = 2', 'a + b']);
      expect(restored.lines.map((l) => l.id).toList(), ['l1', 'l2', 'l3']);
      expect(restored.createdAt, DateTime.utc(2026, 5, 25, 10));
      expect(restored.updatedAt, DateTime.utc(2026, 5, 25, 11));
    });

    test('Welcome sample doc has the reserved id', () {
      final welcome = buildWelcomeNotepadDocument();
      expect(welcome.id, kWelcomeNotepadDocId);
      expect(welcome.name, 'Welcome');
      expect(welcome.lines, isNotEmpty);
    });
  });

  group('AppState first-launch seeding', () {
    test('empty prefs → seeds Untitled + Welcome', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      expect(s.notepadDocuments.length, 2);
      expect(s.notepadDocuments.containsKey(kWelcomeNotepadDocId), isTrue);
      final names = s.notepadDocuments.values.map((d) => d.name).toSet();
      expect(names, containsAll(['Untitled', 'Welcome']));
    });

    test('current doc on first launch is Untitled (not Welcome)', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final current = s.notepadDocuments[s.currentNotepadDocId];
      expect(current, isNotNull);
      expect(current!.name, 'Untitled');
      expect(current.id, isNot(kWelcomeNotepadDocId));
    });

    test('seeding does not re-run when docs already exist', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final firstIds = s.notepadDocuments.keys.toSet();
      // Reload with the seeded prefs already in place.
      await s.load(force: true);
      expect(s.notepadDocuments.keys.toSet(), firstIds);
      expect(s.notepadDocuments.length, 2);
    });
  });

  group('AppState persists notepad docs across reload', () {
    test('setNotepadDocument survives a reload', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final doc = NotepadDocument(
        id: 'taxes-2026',
        name: 'Taxes',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 5, 25),
        lines: [
          NotepadLine(id: 'l1', source: 'income = 50000'),
          NotepadLine(id: 'l2', source: 'income * 0.25'),
        ],
      );
      s.setNotepadDocument(doc);
      await s.load(force: true);
      final restored = s.notepadDocuments['taxes-2026'];
      expect(restored, isNotNull);
      expect(restored!.name, 'Taxes');
      expect(restored.lines.length, 2);
      expect(restored.lines[1].source, 'income * 0.25');
    });

    test('setCurrentNotepadDoc persists', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final doc = NotepadDocument.fresh(name: 'Pinned');
      s.setNotepadDocument(doc);
      s.setCurrentNotepadDoc(doc.id);
      await s.load(force: true);
      expect(s.currentNotepadDocId, doc.id);
    });

    test('deleteNotepadDocument removes from store', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final doc = NotepadDocument.fresh(name: 'Scratch');
      s.setNotepadDocument(doc);
      expect(s.notepadDocuments.containsKey(doc.id), isTrue);
      s.deleteNotepadDocument(doc.id);
      expect(s.notepadDocuments.containsKey(doc.id), isFalse);
    });

    test('deleting current doc reassigns to another', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final doc = NotepadDocument.fresh(name: 'Active');
      s.setNotepadDocument(doc);
      s.setCurrentNotepadDoc(doc.id);
      expect(s.currentNotepadDocId, doc.id);
      s.deleteNotepadDocument(doc.id);
      expect(s.currentNotepadDocId, isNotNull);
      expect(s.currentNotepadDocId, isNot(doc.id));
      // The reassignment lands on one of the seed docs.
      expect(s.notepadDocuments.containsKey(s.currentNotepadDocId), isTrue);
    });

    test('setCurrentNotepadDoc rejects unknown ids', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final before = s.currentNotepadDocId;
      s.setCurrentNotepadDoc('nope-not-a-real-id');
      expect(s.currentNotepadDocId, before);
    });
  });

  group('exportToJson / importFromJson', () {
    test('export excludes the Welcome sample doc', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final exported = s.exportToJson();
      final exportedDocs = exported['notepadDocuments'] as List;
      final exportedIds =
          exportedDocs.map((raw) => (raw as Map)['i']).toSet();
      expect(exportedIds, isNot(contains(kWelcomeNotepadDocId)));
      // The seeded Untitled should still be in the export.
      expect(exportedDocs.length, 1);
    });

    test('round-trip preserves user docs without duplicating Welcome',
        () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final taxes = NotepadDocument(
        id: 'taxes',
        name: 'Taxes',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 5, 25),
        lines: [NotepadLine(id: 'l1', source: '5000 * 0.25')],
      );
      s.setNotepadDocument(taxes);
      s.setCurrentNotepadDoc('taxes');

      final exported = s.exportToJson();

      // Wipe and reload — first-launch seeding re-runs.
      SharedPreferences.setMockInitialValues({});
      await s.load(force: true);
      expect(s.notepadDocuments.containsKey('taxes'), isFalse);

      // Re-import.
      final summary = s.importFromJson(exported);
      expect(summary, contains('notepad documents'));
      expect(s.notepadDocuments.containsKey('taxes'), isTrue);
      expect(s.notepadDocuments['taxes']!.lines.first.source, '5000 * 0.25');
      // Welcome stays exactly once — not double-imported.
      final welcomeCount = s.notepadDocuments.values
          .where((d) => d.id == kWelcomeNotepadDocId)
          .length;
      expect(welcomeCount, 1);
      // currentNotepadDocId restored to the imported doc.
      expect(s.currentNotepadDocId, 'taxes');
    });

    test('importing a payload with a doc claiming the Welcome id is rejected',
        () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final originalWelcomeLines =
          s.notepadDocuments[kWelcomeNotepadDocId]!.lines.length;
      // Craft a malicious payload that pretends to be the Welcome doc.
      s.importFromJson({
        'notepadDocuments': [
          {
            'i': kWelcomeNotepadDocId,
            'n': 'Spoofed Welcome',
            'c': DateTime.utc(2026, 1, 1).toIso8601String(),
            'u': DateTime.utc(2026, 1, 1).toIso8601String(),
            'l': [
              {'i': 'l1', 's': 'NOT THE REAL WELCOME'}
            ],
          }
        ],
      });
      final welcome = s.notepadDocuments[kWelcomeNotepadDocId]!;
      expect(welcome.name, 'Welcome');
      expect(welcome.lines.length, originalWelcomeLines);
      expect(welcome.lines.first.source, isNot('NOT THE REAL WELCOME'));
    });

    test('import with no notepadDocuments key leaves docs alone', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final docsBefore = Set<String>.from(s.notepadDocuments.keys);
      s.importFromJson({'locale': 'de'});
      expect(s.notepadDocuments.keys.toSet(), docsBefore);
    });
  });
}
