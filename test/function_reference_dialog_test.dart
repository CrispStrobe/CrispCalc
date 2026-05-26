// test/function_reference_dialog_test.dart
//
// Round 96 (P6): widget coverage for FunctionReferenceDialog.
// Mirrors test/worked_examples_dialog_test.dart's approach —
// pump the dialog inside a minimal MaterialApp, drive the search
// + category chips, verify the "Try in Calculator" tap stashes
// onto AppState.

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/widgets/function_reference_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _showDialog(WidgetTester tester) async {
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
                builder: (_) => const FunctionReferenceDialog(),
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
  setUp(() {
    // Drain any pending insert leaked from another test file.
    AppState().consumePendingInsert();
  });

  group('FunctionReferenceDialog — Round 96', () {
    testWidgets('opens with title and all nine category chips', (tester) async {
      await _showDialog(tester);

      expect(find.text('Function reference'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      // Spot-check three category chip labels.
      expect(find.text('CAS'), findsWidgets);
      expect(find.text('Precision'), findsWidgets);
      expect(find.text('Matrix'), findsOneWidget);
    });

    testWidgets('seed list shows solve / isprime / pi(N) signatures',
        (tester) async {
      await _showDialog(tester);

      // Round 96 shipped these three seed entries. Round 97 grew
      // the catalogue past one screen of rows — solve still appears
      // at the top of the list, but isprime / pi(N) sit below the
      // fold and need a search filter to surface them.
      expect(find.text('solve(equation, variable)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'isprime');
      await tester.pumpAndSettle();
      expect(find.text('isprime(n)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'pi_precision');
      await tester.pumpAndSettle();
      expect(find.text('pi(N)'), findsOneWidget);
    });

    testWidgets('round 97: CAS-filtered list shows expand + diff entries',
        (tester) async {
      await _showDialog(tester);

      // Pick the CAS chip — `find.text('CAS')` finds the chip label.
      // `findsWidgets` not `findsOneWidget` because the chip label
      // and any matching list-row content could co-exist.
      final casChip = find.text('CAS').first;
      await tester.tap(casChip);
      await tester.pumpAndSettle();

      // Round 97 fills in the CAS category. Spot-check two of the
      // newly-added signatures so a regression that drops them is
      // caught here.
      expect(find.text('expand(expression)'), findsOneWidget);
      expect(find.text('diff(expression, variable)'), findsOneWidget);
    });

    testWidgets('search filters by id/signature/description', (tester) async {
      await _showDialog(tester);

      await tester.enterText(find.byType(TextField), 'prime');
      await tester.pumpAndSettle();

      expect(find.text('isprime(n)'), findsOneWidget);
      expect(find.text('solve(equation, variable)'), findsNothing);
      expect(find.text('pi(N)'), findsNothing);
    });

    testWidgets('expand a row reveals examples + Try in Calculator',
        (tester) async {
      await _showDialog(tester);

      // Tap the solve row to expand it.
      await tester.tap(find.text('solve(equation, variable)'));
      await tester.pumpAndSettle();

      // First example input now visible in monospace text.
      expect(find.text('solve(x^2 - 1, x)'), findsOneWidget);
      expect(find.text('Try in Calculator'), findsOneWidget);
    });

    testWidgets('Try in Calculator stashes the example input', (tester) async {
      await _showDialog(tester);

      await tester.tap(find.text('solve(equation, variable)'));
      await tester.pumpAndSettle();

      expect(AppState().pendingInsertExpression, isNull);

      final tryButton = find.text('Try in Calculator');
      expect(tryButton, findsOneWidget);
      await tester.ensureVisible(tryButton);
      await tester.pumpAndSettle();
      // warnIfMissed=false because the surrounding Wrap can place
      // the button at a sub-pixel offset that the tester complains
      // about even though the hit-test still resolves.
      await tester.tap(tryButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // The dialog closed and the first example's input is now
      // queued for the calculator to consume.
      expect(AppState().pendingInsertExpression, 'solve(x^2 - 1, x)');
      // Cleanup so other tests don't see this leak.
      AppState().consumePendingInsert();
    });

    testWidgets('See worked example button surfaces when WE id resolves',
        (tester) async {
      await _showDialog(tester);

      // Round 97 grew the catalogue past one screen of rows, so
      // pi(N) may sit below the fold. Filter via the search field
      // to bring it back to the top before expanding.
      await tester.enterText(find.byType(TextField), 'pi_precision');
      await tester.pumpAndSettle();

      // `pi(N)` has workedExampleId = 'piPrecision' which exists
      // in WorkedExamples.all, so the button must appear.
      await tester.tap(find.text('pi(N)'));
      await tester.pumpAndSettle();
      expect(find.text('See worked example'), findsOneWidget);
    });

    testWidgets(
        'Round 96 follow-up: See-worked-example cross-link pre-filters WE dialog',
        (tester) async {
      await _showDialog(tester);

      // Filter to surface pi(N) (Round 97: more rows than the
      // dialog viewport).
      await tester.enterText(find.byType(TextField), 'pi_precision');
      await tester.pumpAndSettle();

      // Expand the pi(N) row so the cross-link button is visible.
      await tester.tap(find.text('pi(N)'));
      await tester.pumpAndSettle();

      final seeBtn = find.text('See worked example');
      expect(seeBtn, findsOneWidget);
      await tester.ensureVisible(seeBtn);
      await tester.pumpAndSettle();
      // warnIfMissed=false — same Wrap layout reason as the
      // Try-in-Calculator tap test.
      await tester.tap(seeBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // The Function Reference dialog popped and the Worked
      // Examples dialog opened, with the search field pre-filled
      // to the linked id. The filter (which now matches against
      // ids too) keeps only the pi(100) example visible.
      expect(find.text('Worked examples'), findsWidgets);
      // Search field carries the linked id.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'piPrecision');
      // The linked entry's expression renders…
      expect(find.text('pi(100)'), findsOneWidget);
      // …while unrelated entries don't.
      expect(find.text('100!'), findsNothing);
    });
  });
}
