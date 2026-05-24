// test/calculator_button_test.dart
//
// Verifies that the screen-reader Semantics label fires on
// glyph-only keypad buttons. Without the wrapper, VoiceOver / TalkBack
// would announce "√" as nothing or "u+221A" depending on platform.

import 'package:crisp_calc/widgets/calculator_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, String text) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: CalculatorButton(text: text, onPressed: () {}),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Glyph-only buttons get a spoken-friendly Semantics label',
      (tester) async {
    await _pump(tester, '√');
    // The wrapper sets excludeSemantics on the FilledButton, so the
    // outer Semantics is the one screen readers see. Find it by
    // matching the override label and check that the visible Text
    // child is "√".
    expect(find.bySemanticsLabel('square root'), findsOneWidget);
    expect(find.text('√'), findsOneWidget);
  });

  testWidgets('Backspace glyph maps to spoken "backspace"', (tester) async {
    await _pump(tester, '⌫');
    expect(find.bySemanticsLabel('backspace'), findsOneWidget);
  });

  testWidgets('Plain digit buttons fall through to their literal text',
      (tester) async {
    await _pump(tester, '7');
    // The Semantics label IS '7' since the map doesn't override
    // digits. find.bySemanticsLabel works for that case too.
    expect(find.bySemanticsLabel('7'), findsOneWidget);
  });

  testWidgets('Named CAS buttons use the symbol-table override',
      (tester) async {
    await _pump(tester, 'd/dx');
    expect(find.bySemanticsLabel('derivative'), findsOneWidget);
  });
}
