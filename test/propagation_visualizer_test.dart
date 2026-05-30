// Widget coverage for the Constraints → DSL tab propagation
// step-trace visualizer (Round F). Drives the real CspSolver.traceDsl
// path end-to-end through the UI: type a tiny 3-coloring program, hit
// Visualize, and assert the replay surface appears and steps.

import 'package:crisp_calc/screens/constraints_screen.dart';
import 'package:crisp_calc/widgets/propagation_visualizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openDslTab(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 1000));
  await tester.pumpWidget(const MaterialApp(home: ConstraintsScreen()));
  await tester.pumpAndSettle();
  // DSL ("Free-form") is the 3rd tab (index 2).
  await tester.tap(find.byType(Tab).at(2));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Visualize reveals the propagation replay and steps forward',
      (tester) async {
    await _openDslTab(tester);

    // Replace the default program with a tiny, fast 3-coloring.
    await tester.enterText(
      find.byType(TextField).first,
      'vars: a, b, c in 1..3\na != b\na != c\nb != c',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visualize'));
    await tester.pumpAndSettle();

    // The visualizer is on screen at its initial frame.
    expect(find.byType(PropagationVisualizer), findsOneWidget);
    expect(find.text('Propagation trace'), findsOneWidget);
    expect(find.text('Step 0 / 6'), findsOneWidget);

    // Step forward → first event is a decision pinning a variable.
    await tester.tap(find.byTooltip('Step forward'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 / 6'), findsOneWidget);
    expect(find.textContaining('Decision:'), findsOneWidget);
  });

  testWidgets('reaching the end shows the Solved outcome chip', (tester) async {
    await _openDslTab(tester);
    await tester.enterText(
      find.byType(TextField).first,
      'vars: a, b, c in 1..3\na != b\na != c\nb != c',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visualize'));
    await tester.pumpAndSettle();

    // Scrub to the end via repeated step-forward (6 events).
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byTooltip('Step forward'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Step 6 / 6'), findsOneWidget);
    expect(find.text('Solved'), findsOneWidget);
  });
}
