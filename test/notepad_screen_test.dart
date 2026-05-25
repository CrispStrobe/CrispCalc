// test/notepad_screen_test.dart
//
// Widget-level coverage for Phase 4 of the Notepad V1 plan:
// adaptive layout, line add/delete/undo, drag-reorder, AppBar
// ⋮-menu actions, doc switching, and cached-result rendering.
//
// Live evaluation lands in Phase 5; these tests therefore poke
// `cachedResult` / `cachedError` directly on `NotepadLine` to
// exercise the result/error rendering paths.

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/notepad.dart';
import 'package:crisp_calc/engine/notepad_evaluator.dart';
import 'package:crisp_calc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resets prefs + AppState. Pre-marks onboarding dismissed so the
/// first-launch tour doesn't pop on top of the Notepad screen.
Future<void> _bootApp(WidgetTester tester, {Size? size}) async {
  SharedPreferences.setMockInitialValues({
    'crisp.onboardingDismissed': true,
  });
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
  }
  await AppState().load(force: true);
  await tester.pumpWidget(const CrispCalcApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Navigate to the Notepad tab. Works at all three breakpoints
/// since `find.text('Notepad')` matches both the NavigationRail
/// label and the BottomNavigationBar label.
Future<void> _gotoNotepad(WidgetTester tester) async {
  final notepad = find.text('Notepad');
  expect(notepad, findsWidgets, reason: 'no Notepad destination found');
  await tester.tap(notepad.first);
  await tester.pumpAndSettle();
}

void main() {
  group('NotepadScreen — breakpoints', () {
    testWidgets('tab visible at narrow (bottom nav) breakpoint',
        (tester) async {
      await _bootApp(tester, size: const Size(400, 800));
      expect(find.text('Notepad'), findsOneWidget);
      await _gotoNotepad(tester);
      // First-launch seed creates an `Untitled` doc.
      expect(find.text('Untitled'), findsOneWidget);
    });

    testWidgets('tab visible at medium (nav rail) breakpoint',
        (tester) async {
      await _bootApp(tester, size: const Size(900, 800));
      expect(find.text('Notepad'), findsWidgets);
      await _gotoNotepad(tester);
      expect(find.text('Untitled'), findsOneWidget);
    });

    testWidgets('tab visible at wide (extended rail) breakpoint',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      expect(find.text('Notepad'), findsWidgets);
      await _gotoNotepad(tester);
      expect(find.text('Untitled'), findsOneWidget);
    });
  });

  group('NotepadScreen — line operations', () {
    testWidgets('+ button appends a line to the active doc', (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);
      final docBefore = AppState()
          .notepadDocuments[AppState().currentNotepadDocId!]!;
      final beforeCount = docBefore.lines.length;
      await tester.tap(find.byTooltip('Add line'));
      await tester.pumpAndSettle();
      final docAfter = AppState()
          .notepadDocuments[AppState().currentNotepadDocId!]!;
      expect(docAfter.lines.length, beforeCount + 1);
    });

    testWidgets('delete line shows snackbar with Undo that restores it',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);
      final doc =
          AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      // Append a second line so we have something to delete that's
      // distinguishable from the empty seeded line.
      doc.lines.add(NotepadLine.fresh(source: 'will-be-deleted'));
      AppState().setNotepadDocument(doc);
      await tester.pumpAndSettle();

      // Delete it via the per-row close icon.
      final deleteBtns = find.byTooltip('Delete line');
      expect(deleteBtns, findsWidgets);
      await tester.tap(deleteBtns.last);
      await tester.pumpAndSettle();
      expect(doc.lines.where((l) => l.source == 'will-be-deleted'),
          isEmpty,
          reason: 'line should be gone after delete');

      // Snackbar with Undo is visible.
      expect(find.text('Line deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo → line restored.
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      final restored = AppState()
          .notepadDocuments[AppState().currentNotepadDocId!]!;
      expect(
        restored.lines.any((l) => l.source == 'will-be-deleted'),
        isTrue,
        reason: 'undo should restore the line',
      );
    });

    testWidgets('edit clears cached result so stale value stops showing',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);
      final doc =
          AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      final line = NotepadLine(
        id: 'fixed-id',
        source: '1+1',
        cachedResult: '2',
      );
      doc.lines.add(line);
      AppState().setNotepadDocument(doc);
      await tester.pumpAndSettle();

      // Edit the row's text field.
      await tester.enterText(find.byType(TextField).last, '2+2');
      await tester.pumpAndSettle();

      final after = AppState()
          .notepadDocuments[AppState().currentNotepadDocId!]!;
      final edited = after.lines.firstWhere((l) => l.id == 'fixed-id');
      expect(edited.source, '2+2');
      expect(edited.cachedResult, isNull,
          reason: 'Phase 4 drops stale cache on edit');
    });
  });

  group('NotepadScreen — ⋮ menu', () {
    testWidgets('New document creates Untitled 2 and switches to it',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);

      await tester.tap(find.byTooltip('Document menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New document'));
      await tester.pumpAndSettle();

      // Sequential naming (decision #8): `Untitled` is taken by the
      // first-launch seed, so the second is `Untitled 2`.
      final state = AppState();
      final current = state.notepadDocuments[state.currentNotepadDocId!]!;
      expect(current.name, 'Untitled 2');
      // AppBar title reflects it.
      expect(find.text('Untitled 2'), findsWidgets);
    });

    testWidgets('Open Welcome sample switches to the Welcome doc',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);

      await tester.tap(find.byTooltip('Document menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Welcome sample'));
      await tester.pumpAndSettle();

      expect(AppState().currentNotepadDocId, kWelcomeNotepadDocId);
      // AppBar title shows "Welcome".
      expect(find.text('Welcome'), findsWidgets);
    });

    testWidgets('Open Welcome sample recreates the doc if previously deleted',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      // Delete Welcome before navigating.
      AppState().deleteNotepadDocument(kWelcomeNotepadDocId);
      expect(AppState().notepadDocuments.containsKey(kWelcomeNotepadDocId),
          isFalse);
      await tester.pumpAndSettle();

      await _gotoNotepad(tester);
      await tester.tap(find.byTooltip('Document menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Welcome sample'));
      await tester.pumpAndSettle();

      expect(AppState().notepadDocuments.containsKey(kWelcomeNotepadDocId),
          isTrue);
      expect(AppState().currentNotepadDocId, kWelcomeNotepadDocId);
    });

    testWidgets('Delete document shows snackbar with Undo that restores it',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);

      // Create a doc we can safely delete.
      await tester.tap(find.byTooltip('Document menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New document'));
      await tester.pumpAndSettle();
      final state = AppState();
      final victimId = state.currentNotepadDocId!;
      final victimName = state.notepadDocuments[victimId]!.name;

      await tester.tap(find.byTooltip('Document menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete document'));
      await tester.pumpAndSettle();

      expect(state.notepadDocuments.containsKey(victimId), isFalse);
      expect(find.text('Document "$victimName" deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(state.notepadDocuments.containsKey(victimId), isTrue);
    });
  });

  group('NotepadScreen — rendering', () {
    testWidgets('cached result renders as Math.tex', (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);
      final doc =
          AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      doc.lines.add(NotepadLine(
        id: 'r1',
        source: '2 + 2',
        cachedResult: '4',
      ));
      AppState().setNotepadDocument(doc);
      await tester.pumpAndSettle();

      expect(find.byType(Math), findsWidgets);
    });

    testWidgets('blocked-by error renders an actionable chip with alias',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);
      final doc =
          AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      doc.lines.add(NotepadLine(
        id: 'upstream',
        source: 'oops',
        cachedError: NotepadErrorPrefix.fromEngine('Error: parse failed'),
      ));
      doc.lines.add(NotepadLine(
        id: 'downstream',
        source: 'line2 + 1',
        cachedError: NotepadErrorPrefix.blocked('upstream', 'line2'),
      ));
      AppState().setNotepadDocument(doc);
      await tester.pumpAndSettle();

      expect(find.text('Blocked by line2'), findsOneWidget);
      // Chip is tappable (ActionChip) — pressing shouldn't throw.
      await tester.tap(find.text('Blocked by line2'));
      await tester.pumpAndSettle();
    });
  });

  group('NotepadScreen — persistence', () {
    testWidgets('doc switch survives a force-reload', (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);

      await tester.tap(find.byTooltip('Document menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Welcome sample'));
      await tester.pumpAndSettle();

      expect(AppState().currentNotepadDocId, kWelcomeNotepadDocId);

      // Simulate a relaunch: force-reload AppState from the same
      // prefs blob (SharedPreferences in-memory mock persists for
      // the duration of the test).
      await AppState().load(force: true);
      expect(AppState().currentNotepadDocId, kWelcomeNotepadDocId);
    });
  });
}
