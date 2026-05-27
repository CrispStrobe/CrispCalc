// Round 104 (P6): help-mode popover on Notepad line rows.
// Wires the existing HelpTarget wrappers (Round 101) to
// HistoryRowHelpModal via _NotepadLineRow._showLineHelp. Reuses
// the calculator-history routing table — the line's `source` is
// the expression, `cachedError ?? cachedResult` the displayed
// result.

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/function_reference.dart';
import 'package:crisp_calc/engine/notepad.dart';
import 'package:crisp_calc/main.dart';
import 'package:crisp_calc/services/engine_service.dart';
import 'package:crisp_calc/widgets/history_help_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<void> _gotoNotepad(WidgetTester tester) async {
  final notepad = find.text('Notepad');
  expect(notepad, findsWidgets);
  await tester.tap(notepad.first);
  await tester.pumpAndSettle();
}

void main() {
  // Same teardown as notepad_screen_test.dart — the persistent
  // worker isolate has to be drained between tests so a hung
  // call can't leak.
  tearDown(() async {
    AppState().setHelpMode(false);
    await EngineService.shutdownForTest();
  });

  testWidgets(
      'help-mode tap on a factor(...) line opens the SymEngine.factor popover',
      (tester) async {
    await _bootApp(tester, size: const Size(1280, 800));
    await _gotoNotepad(tester);

    final doc = AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
    doc.lines.add(NotepadLine(
      id: 'line-factor',
      source: 'factor(x^2 - 1)',
      cachedResult: '(x - 1)*(x + 1)',
    ));
    AppState().setNotepadDocument(doc);
    await tester.pumpAndSettle();

    AppState().setHelpMode(true);
    await tester.pump();

    // Tap the line row. The TextField holds the source as its text,
    // so finding it via the TextField is the most stable handle —
    // and the absorbing-overlay sits above it in help mode.
    final field = find.widgetWithText(TextField, 'factor(x^2 - 1)');
    expect(field, findsOneWidget);
    await tester.tap(field, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Modal opens with the SymEngine.factor engine line and a
    // Learn-more deep-link button.
    expect(find.byType(HistoryRowHelpModal), findsOneWidget);
    expect(find.text('Computed via SymEngine.factor'), findsOneWidget);

    final factorRef =
        FunctionReferences.all.firstWhere((e) => e.id == 'factor');
    expect(find.text(factorRef.signature), findsOneWidget);
    expect(find.text('Learn more'), findsOneWidget);
    // Show-steps is intentionally absent on notepad rows — the row
    // doesn't have a CalculatorEngine reference to re-run StepEngine
    // against. Verify the action is suppressed.
    expect(find.text('Show steps'), findsNothing);
  });

  testWidgets('help-mode tap on bare-arithmetic line shows direct-eval blurb',
      (tester) async {
    await _bootApp(tester, size: const Size(1280, 800));
    await _gotoNotepad(tester);

    final doc = AppState().notepadDocuments[AppState().currentNotepadDocId!]!;
    doc.lines.add(NotepadLine(
      id: 'line-bare',
      source: '2 + 3',
      cachedResult: '5',
    ));
    AppState().setNotepadDocument(doc);
    await tester.pumpAndSettle();

    AppState().setHelpMode(true);
    await tester.pump();

    final field = find.widgetWithText(TextField, '2 + 3');
    expect(field, findsOneWidget);
    await tester.tap(field, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(HistoryRowHelpModal), findsOneWidget);
    expect(
      find.text('Direct numerical evaluation — no symbolic call involved.'),
      findsOneWidget,
    );
    expect(find.textContaining('Computed via'), findsNothing);
    expect(find.text('Learn more'), findsNothing);
    expect(find.text('Show steps'), findsNothing);
    expect(find.text('Close'), findsOneWidget);
  });
}
