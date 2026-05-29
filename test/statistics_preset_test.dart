// test/statistics_preset_test.dart
//
// Round 95 follow-up (P6): `open:statistics?preset=<id>` sentinels not
// only pick the Tests tab but pre-select a test kind and fill its
// input fields from StatisticsPresets. This file verifies the AppState
// slot, the screen drain + pre-fill side effect, graceful degrade on
// an unknown id, and catalog/preset cross-consistency.

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/statistics_presets.dart';
import 'package:crisp_calc/engine/worked_examples.dart';
import 'package:crisp_calc/screens/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  await AppState().load(force: true);
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AppState().consumePendingStatisticsTab();
    AppState().consumePendingStatisticsPresetId();
  });

  group('AppState statistics-preset slot', () {
    test('round-trips and is one-shot', () {
      AppState().requestLoadStatisticsPreset('statsWelchTwoSample');
      expect(AppState().pendingStatisticsPresetId, 'statsWelchTwoSample');
      expect(
          AppState().consumePendingStatisticsPresetId(), 'statsWelchTwoSample');
      // Drained.
      expect(AppState().pendingStatisticsPresetId, isNull);
      expect(AppState().consumePendingStatisticsPresetId(), isNull);
    });
  });

  group('StatisticsScreen drains pendingStatisticsPresetId', () {
    testWidgets('Welch preset lands on Tests tab and pre-fills data',
        (tester) async {
      AppState().requestLoadStatisticsPreset('statsWelchTwoSample');
      await _pump(tester, const StatisticsScreen());

      // Slot consumed.
      expect(AppState().pendingStatisticsPresetId, isNull);
      // Tests tab is active (its unique chip is visible)...
      expect(find.text('One-sample t'), findsOneWidget);
      // ...and the Welch group-A data from the preset is in a field.
      final preset = StatisticsPresets.all['statsWelchTwoSample']!;
      expect(find.text(preset.fields['twoSampleA']!), findsOneWidget);
    });

    testWidgets('ANOVA preset fills the multi-line group field',
        (tester) async {
      AppState().requestLoadStatisticsPreset('statsAnovaThreeGroups');
      await _pump(tester, const StatisticsScreen());

      expect(AppState().pendingStatisticsPresetId, isNull);
      final preset = StatisticsPresets.all['statsAnovaThreeGroups']!;
      expect(find.text(preset.fields['anovaGroups']!), findsOneWidget);
    });

    testWidgets('unknown preset id degrades to the default Descriptive tab',
        (tester) async {
      AppState().requestLoadStatisticsPreset('no-such-preset');
      await _pump(tester, const StatisticsScreen());

      expect(AppState().pendingStatisticsPresetId, isNull);
      // Descriptive default sample is visible; Tests chip is not.
      expect(find.text('2, 4, 4, 4, 5, 5, 7, 9'), findsOneWidget);
      expect(find.text('One-sample t'), findsNothing);
    });
  });

  group('catalog ↔ presets cross-consistency', () {
    test('every open:statistics?preset=<id> targets a known preset', () {
      var seen = 0;
      for (final e in WorkedExamples.all) {
        if (!e.expression.startsWith('open:statistics?preset=')) continue;
        seen++;
        final id = e.expression.substring('open:statistics?preset='.length);
        expect(StatisticsPresets.all.containsKey(id), isTrue,
            reason: '${e.id} targets unknown preset "$id"');
      }
      expect(seen, greaterThan(0),
          reason: 'expected at least one preset sentinel in the catalog');
    });

    test('every preset has a non-empty tab and at least one field', () {
      for (final entry in StatisticsPresets.all.entries) {
        expect(entry.value.tab.trim(), isNotEmpty,
            reason: '${entry.key} has an empty tab');
        expect(entry.value.fields, isNotEmpty,
            reason: '${entry.key} has no field overrides');
      }
    });
  });
}
