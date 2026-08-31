// integration_test/notepad_web_document_test.dart
//
// Live-browser test of a realistic multi-line Notepad document —
// named values, cross-line references, symbolic scratch work and units
// in one sheet — evaluated by the real SymEngine WASM module in Chrome.
//
// `notepad_web_live_test.dart` covers single expressions in isolation;
// this covers what the Notepad actually is: a sheet whose lines depend
// on each other.
//
//   chromedriver --port=4444 &
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/notepad_web_document_test.dart \
//     -d web-server --browser-name=chrome
import 'package:crisp_math/engine/app_state.dart';
import 'package:crisp_math/engine/calculator_engine.dart';
import 'package:crisp_math/engine/notepad.dart';
import 'package:crisp_math/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A sheet of the kind the Notepad is for, paired with the result each
/// line must produce. `null` means the line shows nothing (headings,
/// dividers).
const _sheet = <(String, String?)>[
  ('## Budget', null),
  ('rent = 1200', '1200'),
  ('food = 450', '450'),
  ('transport = 90', '90'),
  ('rent + food + transport', '1740'),
  ('---', null),
  ('## Scratch', null),
  ('x = 5', '5'),
  ('x^2 + 1', '26'),
  ('half = x / 2', '2.5'),
  ('1/x', '0.2'),
  // Free symbols never bound in the sheet: the WASM bridge throws on
  // these, so they are answered by the pure-Dart symbolic layer.
  ('a*b + b*a', '2*a*b'),
  ('---', null),
  ('## Units', null),
  ('5 km + 3 m', '5.003 km'),
  ('100 km in miles', '62.1371192237 mi'),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a whole notepad sheet evaluates in a real browser',
      (tester) async {
    SharedPreferences.setMockInitialValues({'crisp.onboardingDismissed': true});
    final appState = AppState();
    await appState.load(force: true);
    await pollForNativeBridge(timeout: const Duration(seconds: 30));
    expect(nativeBridgeStatus.value, NativeBridgeStatus.ready,
        reason: 'the SymEngine WASM module must be loaded, otherwise this '
            'test silently degrades to the pure-Dart path');

    // Seed the sheet into whichever document the app opens on launch —
    // the screen picks its document from AppState at build time, so a
    // freshly inserted id isn't necessarily the one it shows.
    final docId =
        appState.currentNotepadDocId ?? appState.notepadDocuments.keys.first;
    final doc = appState.notepadDocuments[docId]!;
    doc.lines
      ..clear()
      ..addAll([
        for (var i = 0; i < _sheet.length; i++)
          NotepadLine(id: 'live$i', source: _sheet[i].$1),
      ]);

    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    await tester.pumpWidget(const CrispMathApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Notepad').first);
    await tester.pumpAndSettle();

    // Re-enter each row's own text, top to bottom. Every edit schedules
    // the same debounced recalc a real keystroke would, so the sheet is
    // computed through the production path — no test-only recalc hook.
    final fieldCount = find.byType(TextField).evaluate().length;
    expect(fieldCount, _sheet.length,
        reason: 'every seeded line should have rendered a row');
    for (var i = 0; i < fieldCount; i++) {
      final field = find.byType(TextField).at(i);
      final current = tester.widget<TextField>(field).controller?.text ?? '';
      if (current.trim().isEmpty) continue;
      // `_onLineEdited` ignores an edit that doesn't change the text, so
      // nudge the value and set it back to make this a genuine edit.
      await tester.enterText(field, '$current ');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(field, current);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    final live = appState.notepadDocuments[docId]!;
    final failures = <String>[];
    for (var i = 0; i < _sheet.length; i++) {
      final (src, want) = _sheet[i];
      final line = live.lines[i];
      expect(line.source, src, reason: 'row $i drifted');
      if (line.cachedError != null) {
        failures.add('"$src": unexpected error "${line.cachedError}"');
        continue;
      }
      if (line.cachedResult != want) {
        failures.add('"$src": expected ${want ?? 'nothing'}, '
            'got ${line.cachedResult ?? 'nothing'}');
      }
    }
    expect(failures, isEmpty,
        reason: 'live sheet mismatches:\n${failures.join('\n')}');
  });
}
