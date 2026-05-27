// Round 102 (P6): help-mode popover on Adv-tab keypad buttons.
// Round 102b extends the same wiring to the CAS tab — the
// `CalculatorKeypad`-level test at the bottom verifies the CAS
// pane's `solve` button surfaces the SymEngine.solve popover.
//
// Wraps each Adv button in a HelpTarget; when helpMode is on and
// the button has a FunctionRef mapping, a tap opens a small
// AlertDialog with the signature + short description + "Learn more"
// deep-link to the full FunctionReferenceDialog.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/function_reference.dart';
import 'package:crisp_calc/localization/app_localizations.dart';
import 'package:crisp_calc/widgets/calculator_keypad.dart';
import 'package:crisp_calc/widgets/function_reference_dialog.dart';
import 'package:crisp_calc/widgets/keypad_grid.dart';

void main() {
  setUp(() => AppState().setHelpMode(false));

  Widget host(Widget child) => MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: SizedBox(width: 320, height: 480, child: child),
        ),
      );

  testWidgets('popover opens for an Adv button with a FunctionRef mapping',
      (tester) async {
    var pressed = <String>[];
    await tester.pumpWidget(host(KeypadGrid(
      buttons: const ['factorint', 'fib', 'mod'],
      onButtonPressed: pressed.add,
      helpRefIdFor: (t) => const {
        'factorint': 'factorint',
        'fib': 'fibonacci',
        // 'mod' deliberately absent → no popover
      }[t],
      onHelpTap: (refId) {
        // Surface the popover from the test context — production
        // wiring (in calculator_keypad.dart) calls
        // showKeypadHelpPopover(context, refId), but we recreate
        // the call here so the assertion runs against the same
        // dialog content.
        final el = tester.element(find.byType(KeypadGrid));
        showKeypadHelpPopover(el, refId);
      },
    )));

    // Help-mode off: a tap presses the button normally.
    await tester.tap(find.text('factorint'));
    await tester.pump();
    expect(pressed, equals(['factorint']));
    expect(find.byType(AlertDialog), findsNothing);

    pressed.clear();
    AppState().setHelpMode(true);
    await tester.pump();

    // Help-mode on + mapped button: the absorbing overlay intercepts
    // the tap and opens the popover instead of firing onPressed.
    // warnIfMissed: false — the absorbing Stack overlay sits above
    // the FilledButton's Text in help mode, so the text's hit-test
    // point lands on the overlay (which is what we want). The
    // warning is a false alarm.
    await tester.tap(find.text('factorint'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(pressed, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);

    final factorintRef =
        FunctionReferences.all.firstWhere((e) => e.id == 'factorint');
    expect(find.text(factorintRef.signature), findsOneWidget);
    expect(find.textContaining(factorintRef.shortDescription.split('.').first),
        findsOneWidget);
    expect(find.text('Learn more'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('"Learn more" opens FunctionReferenceDialog seeded with the id',
      (tester) async {
    await tester.pumpWidget(host(KeypadGrid(
      buttons: const ['factorint'],
      onButtonPressed: (_) {},
      helpRefIdFor: (t) => t == 'factorint' ? 'factorint' : null,
      onHelpTap: (refId) {
        final el = tester.element(find.byType(KeypadGrid));
        showKeypadHelpPopover(el, refId);
      },
    )));

    AppState().setHelpMode(true);
    await tester.pump();

    // warnIfMissed: false — the absorbing Stack overlay sits above
    // the FilledButton's Text in help mode, so the text's hit-test
    // point lands on the overlay (which is what we want). The
    // warning is a false alarm.
    await tester.tap(find.text('factorint'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Learn more'), findsOneWidget);
    await tester.tap(find.text('Learn more'));
    await tester.pumpAndSettle();

    expect(find.byType(FunctionReferenceDialog), findsOneWidget);
    // The dialog's search field starts pre-filled with the id so
    // the user lands directly on the factorint row.
    expect(find.widgetWithText(TextField, 'factorint'), findsOneWidget);
  });

  testWidgets('unmapped button still fires onPressed in help mode',
      (tester) async {
    var pressed = <String>[];
    await tester.pumpWidget(host(KeypadGrid(
      buttons: const ['mod'],
      onButtonPressed: pressed.add,
      helpRefIdFor: (_) => null,
      onHelpTap: (_) => fail('onHelpTap must not fire for unmapped buttons'),
    )));

    AppState().setHelpMode(true);
    await tester.pump();

    await tester.tap(find.text('mod'));
    await tester.pump();

    expect(pressed, equals(['mod']));
    expect(find.byType(AlertDialog), findsNothing);
  });

  // === Round 102b: CAS-tab popover wiring on CalculatorKeypad ============

  testWidgets('CalculatorKeypad: CAS tab `solve` opens the solve popover',
      (tester) async {
    final tabController = _DummyTabController(length: 5, initialIndex: 2);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: Builder(builder: (innerContext) {
          // Force the narrow tabbed layout so we don't need to deal
          // with the wide two-pane layout's chip-selector dance.
          return CalculatorKeypad(
            tabController: tabController,
            onButtonPressed: (_) {},
            localizations: AppLocalizations.of(innerContext),
            appState: AppState(),
            onVariableTap: (_) {},
            forceCompact: true,
          );
        }),
      ),
    ));
    // Let TabController land on CAS (index 2).
    await tester.pumpAndSettle();

    // Help-mode on: tap `solve`. Absorbing-overlay false-alarm
    // suppressed exactly like the Adv-tab tests.
    AppState().setHelpMode(true);
    await tester.pump();
    await tester.tap(find.text('solve'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    final solveRef = FunctionReferences.all.firstWhere((e) => e.id == 'solve');
    expect(find.text(solveRef.signature), findsOneWidget);
    expect(find.text('Learn more'), findsOneWidget);
  });

  testWidgets('CalculatorKeypad: `=` / `,` CAS punctuation skip the popover',
      (tester) async {
    // The `_kCasKeyHelpRefId` map deliberately omits `=` and `,` —
    // they're not engine surface. Pressing them in help mode should
    // fall through to the normal insert handler, not open a dialog.
    final tabController = _DummyTabController(length: 5, initialIndex: 2);
    final pressed = <String>[];

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: Builder(builder: (innerContext) {
          return CalculatorKeypad(
            tabController: tabController,
            onButtonPressed: pressed.add,
            localizations: AppLocalizations.of(innerContext),
            appState: AppState(),
            onVariableTap: (_) {},
            forceCompact: true,
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();

    AppState().setHelpMode(true);
    await tester.pump();
    await tester.tap(find.text(','));
    await tester.pump();

    expect(pressed, equals([',']));
    expect(find.byType(AlertDialog), findsNothing);
  });
}

class _DummyTabController extends TabController {
  _DummyTabController({required super.length, required super.initialIndex})
      : super(vsync: const TestVSync());
}
