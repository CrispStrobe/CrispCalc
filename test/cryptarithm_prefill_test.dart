// test/cryptarithm_prefill_test.dart
//
// Coverage for the cryptarithm worked-example discovery path:
// `open:constraints?cryptarithm=<puzzle>` lands the user on the
// Cryptarithm tab with the puzzle pre-filled, mirroring the DSL /
// statistics-preset prefill pattern. Uses a NON-default puzzle
// (`TWO+TWO=FOUR`) so the assertion proves the prefill actually ran —
// the tab's own default is already `SEND + MORE = MONEY`.

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/worked_examples.dart';
import 'package:crisp_calc/screens/constraints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pending puzzle lands on the Cryptarithm tab, prettified', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    AppState().requestLoadCryptarithm('TWO+TWO=FOUR');
    await tester.pumpWidget(const MaterialApp(home: ConstraintsScreen()));
    await tester.pumpAndSettle();

    // Visible (not offstage) → the screen auto-selected the Cryptarithm
    // tab, and the compact sentinel value was re-spaced to the field's
    // style.
    expect(find.text('TWO + TWO = FOUR'), findsOneWidget);
    // One-shot slot is drained.
    expect(AppState().pendingCryptarithmPuzzle, isNull);
  });

  testWidgets('without a pending puzzle the tab keeps its default', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    AppState().consumePendingCryptarithmPuzzle(); // clear any stale slot
    await tester.pumpWidget(const MaterialApp(home: ConstraintsScreen()));
    await tester.pumpAndSettle();
    // Default opens on the Diophantine tab; navigate to Cryptarithm (1).
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    // The field keeps its hard-coded default (asserted on the controller,
    // since the field's hintText carries the same string and would
    // otherwise double-count under find.text).
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'SEND + MORE = MONEY');
  });

  test('catalog has the SEND+MORE=MONEY entry with the routing sentinel', () {
    final e = WorkedExamples.all.firstWhere(
      (e) => e.id == 'cryptSendMoreMoney',
    );
    expect(e.expression, 'open:constraints?cryptarithm=SEND+MORE=MONEY');
    expect(e.category, WorkedExampleCategory.constraints);
  });
}
