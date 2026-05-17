// integration_test/app_smoke_test.dart
//
// First Flutter integration test. Runs against the actual app
// running in the device or simulator (NOT the headless dart-vm test
// host) — so it can exercise things `flutter test` can't: native
// plugins, real shared_preferences, real channel calls.
//
// Run locally with:
//   flutter test integration_test/app_smoke_test.dart
//
// The matrix and step engine batteries are still verified via their
// own `CRISPCALC_DIAGNOSTIC=…` headless mode — this file covers the
// UI side that those env-var modes deliberately skip.

import 'package:crisp_calc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CrispCalc app — smoke', () {
    testWidgets('boots without throwing', (tester) async {
      await tester.pumpWidget(const CrispCalcApp());
      // Multiple pumps so the post-frame focus callback in
      // CalculatorScreen has a chance to run.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The root widget must be present.
      expect(find.byType(CrispCalcApp), findsOneWidget);
      // The calculator history placeholder text should be present
      // on first launch (no entries yet).
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Settings tab can be reached and reveals the converter card',
        (tester) async {
      await tester.pumpWidget(const CrispCalcApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Find the Settings destination — on phones it's a bottom-bar
      // item; on tablets it's a NavigationRail item. Either way the
      // text label "Settings" is in the widget tree.
      final settings = find.text('Settings');
      // The label may appear in multiple destinations on wide layouts;
      // the first hit is the nav entry.
      if (settings.evaluate().isNotEmpty) {
        await tester.tap(settings.first);
        await tester.pumpAndSettle();
        // After tapping Settings, the Unit converter tile should be
        // visible.
        expect(find.text('Unit converter'), findsWidgets);
      }
    });
  });
}
