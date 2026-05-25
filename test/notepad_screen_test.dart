// test/notepad_screen_test.dart
//
// Widget-level coverage for Phases 4 + 5 of the Notepad V1 plan:
// adaptive layout, line add/delete/undo, drag-reorder, AppBar
// ⋮-menu actions, doc switching, cached-result rendering, and the
// live-recalc pipeline (debounced edits, pending state, dispatcher
// → EngineService).
//
// The native SymEngine bridge isn't loaded in widget-test env, so
// the engine dispatcher returns "Error: requires native library"
// — which is enough to verify that the recalc pipeline actually
// ran end-to-end. Tests that poke `cachedResult` / `cachedError`
// directly stay reliable because no engine call is made.

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/notepad.dart';
import 'package:crisp_calc/engine/notepad_evaluator.dart';
import 'package:crisp_calc/main.dart';
import 'package:crisp_calc/services/engine_service.dart';
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
  // Phase 5: the screen now schedules engine work via the persistent
  // worker isolate. Tear it down between tests so a hung worker
  // from a prior test can't leak into the next one.
  tearDown(() async {
    await EngineService.shutdownForTest();
  });

  group('NotepadScreen — breakpoints', () {
    testWidgets('tab visible at narrow (bottom nav) breakpoint',
        (tester) async {
      await _bootApp(tester, size: const Size(400, 800));
      expect(find.text('Notepad'), findsOneWidget);
      await _gotoNotepad(tester);
      // First-launch seed creates an `Untitled` doc.
      expect(find.text('Untitled'), findsOneWidget);
    });

    testWidgets('tab visible at medium (nav rail) breakpoint', (tester) async {
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
      final docBefore =
          AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      final beforeCount = docBefore.lines.length;
      await tester.tap(find.byTooltip('Add line'));
      await tester.pumpAndSettle();
      final docAfter =
          AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      expect(docAfter.lines.length, beforeCount + 1);
    });

    testWidgets('delete line shows snackbar with Undo that restores it',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);
      final doc = AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      // Append a second line so we have something to delete that's
      // distinguishable from the empty seeded line.
      doc.lines.add(NotepadLine.fresh(source: 'will-be-deleted'));
      AppState().setNotepadDocument(doc);
      await tester.pumpAndSettle();

      // Delete it via the per-row close icon. Use bounded pumps
      // rather than pumpAndSettle so the test doesn't block on the
      // Phase-5 300 ms-debounced recalc timer that fires after a
      // delete (the recalc itself is exercised by its own tests).
      // The snackbar's slide-in animation takes ~250 ms; pump in
      // chunks so its Undo button is hit-testable before the
      // recalc timer fires at +300 ms.
      final deleteBtns = find.byTooltip('Delete line');
      expect(deleteBtns, findsWidgets);
      await tester.tap(deleteBtns.last);
      // Pump short of 300ms — past the snackbar slide-in but
      // before the recalc timer.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 250));
      expect(doc.lines.where((l) => l.source == 'will-be-deleted'), isEmpty,
          reason: 'line should be gone after delete');

      // Snackbar with Undo is visible + hit-testable.
      expect(find.text('Line deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo → line restored, with warnIfMissed disabled in
      // case the Undo button is slightly clipped by the surface
      // bottom — we just need the tap to land.
      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
      final restored =
          AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      expect(
        restored.lines.any((l) => l.source == 'will-be-deleted'),
        isTrue,
        reason: 'undo should restore the line',
      );
    });

    testWidgets('edit clears stale cached result immediately', (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);
      final doc = AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      final line = NotepadLine(
        id: 'fixed-id',
        source: '1+1',
        cachedResult: '2',
      );
      doc.lines.add(line);
      AppState().setNotepadDocument(doc);
      await tester.pumpAndSettle();

      // Edit the row's text field. Bounded pump so we don't block
      // on the 300 ms debounce + engine recalc; the cache is
      // cleared synchronously inside `_onLineEdited`.
      await tester.enterText(find.byType(TextField).last, '2+2');
      await tester.pump(const Duration(milliseconds: 50));

      final after =
          AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      final edited = after.lines.firstWhere((l) => l.id == 'fixed-id');
      expect(edited.source, '2+2');
      expect(edited.cachedResult, isNull,
          reason:
              'edit drops stale cache synchronously; recalc runs after debounce');
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
      final doc = AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
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
      final doc = AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
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

  group('NotepadScreen — Phase 5 recalc', () {
    // Widget tests run on FakeAsync; the engine worker isolate runs
    // on real wall-clock, so we can't drive a full dispatcher round-
    // trip from a fake-clock pump. What we *can* verify is that the
    // 300 ms debounce timer fires and the screen flips into the
    // pending state — that's enough to prove the recalc pipeline is
    // wired up; the real engine round-trip is exercised in the
    // running app.

    testWidgets('typing into a line clears cache and arms a debounced recalc',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);
      final doc = AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      doc.lines.add(NotepadLine(
        id: 'p5-eval',
        source: '',
        cachedResult: 'stale',
      ));
      AppState().setNotepadDocument(doc);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '2 + 3');
      // Stale cache is cleared synchronously inside _onLineEdited
      // — no wait needed.
      final line = AppState()
          .notepadDocuments[AppState().currentNotepadDocId!]!
          .lines
          .firstWhere((l) => l.id == 'p5-eval');
      expect(line.source, '2 + 3');
      expect(line.cachedResult, isNull);
      expect(line.cachedError, isNull);

      // Advance past the 300 ms debounce → recalc fires, screen
      // marks the line as pending. The CircularProgressIndicator
      // in `_NotepadResultColumn` is the visual signal.
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(CircularProgressIndicator), findsWidgets,
          reason: 'pending state should appear after the debounce fires');
    });

    testWidgets('⋮ menu Recalculate all triggers an immediate recalc',
        (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);
      final doc = AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
      doc.lines.add(NotepadLine(id: 'p5-recalc-all', source: '1 + 1'));
      AppState().setNotepadDocument(doc);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Document menu'));
      await tester.pumpAndSettle();
      expect(find.text('Recalculate all'), findsOneWidget);
      await tester.tap(find.text('Recalculate all'));
      // Recalculate-all calls _runRecalc synchronously; the setState
      // marking the line pending fires before any await, so a single
      // small pump is enough to observe the indicator.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsWidgets,
          reason: 'Recalculate all should flip the row into pending state');
    });
  });

  group('NotepadScreen — Phase 6 use directive', () {
    testWidgets('unknown import flags the use line as errored', (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      await _gotoNotepad(tester);

      // Build a doc with `use foo` against a variable that doesn't
      // exist in AppState.userVariables.
      final doc = NotepadDocument.fresh(name: 'P6 unknown');
      doc.lines.clear();
      doc.lines.addAll([
        NotepadLine.fresh(source: 'use foo'),
        NotepadLine.fresh(source: '2 + 3'),
      ]);
      AppState().setNotepadDocument(doc);
      AppState().setCurrentNotepadDoc(doc.id);
      await tester.pumpAndSettle();

      // Recalculate all → resolver sets the unknown-import error
      // BEFORE the evaluator runs (post-eval ordering would be
      // engine-isolate-dependent and unreliable in test env).
      await tester.tap(find.byTooltip('Document menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recalculate all'));
      // A short pump is enough — the use-line error is set
      // synchronously inside _runRecalcBody before any await.
      await tester.pump(const Duration(milliseconds: 100));
      final useLine = AppState()
          .notepadDocuments[AppState().currentNotepadDocId!]!
          .lines[0];
      expect(useLine.cachedError, contains('unknownImport:foo'));
    });

    testWidgets('known import populates the document scope', (tester) async {
      await _bootApp(tester, size: const Size(1280, 800));
      AppState().setVariable('mytax', '0.085');
      final doc = NotepadDocument.fresh(name: 'P6 known');
      doc.lines.clear();
      doc.lines.addAll([
        NotepadLine.fresh(source: 'use mytax'),
        NotepadLine.fresh(source: 'mytax'),
      ]);
      AppState().setNotepadDocument(doc);
      AppState().setCurrentNotepadDoc(doc.id);
      await _gotoNotepad(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Document menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recalculate all'));
      await tester.pump(const Duration(milliseconds: 100));

      final useLine = AppState()
          .notepadDocuments[AppState().currentNotepadDocId!]!
          .lines[0];
      // Resolver finds mytax → no unknown-import error set.
      expect(useLine.cachedError, isNull,
          reason: 'resolved import should not set an error');
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
