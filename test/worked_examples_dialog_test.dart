// test/worked_examples_dialog_test.dart
//
// Round 94 (P6): the worked-examples dialog filters the category
// row by the active surface — calculator shows all 7 categories,
// notepad scopes down to calculus / algebra / linear algebra /
// number theory and hides module-bound categories (statistics /
// units / constraints).

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/widgets/worked_examples_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _showDialog(
  WidgetTester tester,
  WorkedExamplesSurface surface,
) async {
  SharedPreferences.setMockInitialValues({});
  await AppState().load(force: true);
  // Default tester surface is 800×600; the dialog content is
  // 560×480 plus AlertDialog chrome. Give it room so the ListView
  // viewport is tall enough that the first few items render.
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => WorkedExamplesDialog(surface: surface),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('WorkedExamplesDialog — Round 94 surface filtering', () {
    testWidgets('calculator surface shows every category chip', (tester) async {
      await _showDialog(tester, WorkedExamplesSurface.calculator);

      // The seven category chips (plus the "All" chip).
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Calculus'), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Linear algebra'), findsOneWidget);
      expect(find.text('Number theory'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Units'), findsOneWidget);
      expect(find.text('Constraints'), findsOneWidget);
    });

    testWidgets('notepad surface hides module-bound categories',
        (tester) async {
      await _showDialog(tester, WorkedExamplesSurface.notepad);

      // The four notepad-friendly category chips stay visible.
      expect(find.text('Calculus'), findsOneWidget);
      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('Linear algebra'), findsOneWidget);
      expect(find.text('Number theory'), findsOneWidget);

      // The three module-bound categories disappear.
      expect(find.text('Statistics'), findsNothing);
      expect(find.text('Units'), findsNothing);
      expect(find.text('Constraints'), findsNothing);
    });

    testWidgets('notepad surface filters the example list itself',
        (tester) async {
      await _showDialog(tester, WorkedExamplesSurface.notepad);

      // A units example shouldn't appear in the list.
      expect(find.text('100 km/h in mph'), findsNothing);
      // A constraints `open:` sentinel shouldn't appear either.
      // Round 95 upgraded `open:sudoku` to `open:sudoku?preset=killer9x9`
      // but the constraints category is still hidden from notepad.
      expect(find.text('open:sudoku?preset=killer9x9'), findsNothing);
      expect(find.text('open:constraints'), findsNothing);
    });

    testWidgets('calculator surface still surfaces module examples',
        (tester) async {
      await _showDialog(tester, WorkedExamplesSurface.calculator);

      // Tap the Units category chip (chip row scrolls horizontally; find
      // the specific ChoiceChip whose label is 'Units' rather than any
      // other 'Units' text on screen).
      final unitsChip = find.byWidgetPredicate(
        (w) =>
            w is ChoiceChip &&
            w.label is Text &&
            (w.label as Text).data == 'Units',
      );
      // Scroll the horizontal chip row so the Units chip is on-screen,
      // then tap it.
      final chipScroll = find.ancestor(
        of: unitsChip,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(unitsChip, 50,
          scrollable: chipScroll.first);
      await tester.pumpAndSettle();
      await tester.tap(unitsChip);
      await tester.pumpAndSettle();

      // The first units example is now in the filtered list.
      expect(find.text('Inline unit conversion'), findsOneWidget);
    });
  });

  group('WorkedExamplesDialog — Round 96 follow-up: initialSearch', () {
    Future<void> showWithSearch(WidgetTester tester, String? initial) async {
      SharedPreferences.setMockInitialValues({});
      await AppState().load(force: true);
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => WorkedExamplesDialog(
                      initialSearch: initial,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('initialSearch pre-fills the search field', (tester) async {
      await showWithSearch(tester, 'piPrecision');

      // Search controller text appears inside the TextField.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'piPrecision');
    });

    testWidgets('initialSearch filters the list to the linked entry',
        (tester) async {
      await showWithSearch(tester, 'piPrecision');

      // Only the pi-precision entry should remain after filtering by
      // its id. Verifying it via its expression (which is stable
      // across locales — the title may vary).
      expect(find.text('pi(100)'), findsOneWidget);
      // Unrelated entries should be absent.
      expect(find.text('100!'), findsNothing);
      expect(find.text('100 km/h in mph'), findsNothing);
    });

    testWidgets('filter matches against id (id-substring search)',
        (tester) async {
      await showWithSearch(tester, null);
      // Type the id substring "factorial100" — id-search added in
      // this round so that locale-independent deep links work.
      await tester.enterText(find.byType(TextField), 'factorial100');
      await tester.pumpAndSettle();

      // The matching expression appears.
      expect(find.text('100!'), findsOneWidget);
    });

    testWidgets('empty initialSearch is a no-op (default behaviour holds)',
        (tester) async {
      await showWithSearch(tester, '');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '');
    });
  });
}
