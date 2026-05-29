// test/function_reference_open_module_test.dart
//
// Round 99 follow-up (P6): module-surface Function Reference entries
// with an `openTarget` sentinel show a direct "Open module" button that
// routes through the shared `module_navigation` dispatcher. Verifies
// catalog↔preset consistency, that every openTarget is a recognized
// navigation sentinel, and the end-to-end widget flow (tap → the
// pre-filled Statistics Tests tab).

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/function_reference.dart';
import 'package:crisp_calc/engine/statistics_presets.dart';
import 'package:crisp_calc/widgets/function_reference_dialog.dart';
import 'package:crisp_calc/widgets/module_navigation.dart';
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

  group('FunctionRef.openTarget catalog consistency', () {
    test('every openTarget is a recognized navigation sentinel', () {
      for (final e in FunctionReferences.all) {
        if (e.openTarget == null) continue;
        expect(isModuleSentinel(e.openTarget!), isTrue,
            reason: '${e.id} openTarget "${e.openTarget}" is not a sentinel');
      }
    });

    test('statistics preset openTargets resolve to a known preset', () {
      const prefix = 'open:statistics?preset=';
      var seen = 0;
      for (final e in FunctionReferences.all) {
        final target = e.openTarget;
        if (target == null || !target.startsWith(prefix)) continue;
        seen++;
        final id = target.substring(prefix.length);
        expect(StatisticsPresets.all.containsKey(id), isTrue,
            reason: '${e.id} targets unknown preset "$id"');
      }
      expect(seen, 12,
          reason: 'all twelve stats entries carry preset openTargets');
    });

    test('the stats entries carry the expected openTargets', () {
      final byId = {for (final e in FunctionReferences.all) e.id: e};
      expect(byId['welch_t']?.openTarget,
          'open:statistics?preset=statsWelchTwoSample');
      expect(byId['anova_1']?.openTarget,
          'open:statistics?preset=statsAnovaThreeGroups');
      expect(byId['chi2_goodness']?.openTarget,
          'open:statistics?preset=statsChiSquareGof');
      // `mean` lands on the Descriptive tab; the dedicated one-sample-t
      // entry owns the statsOneSampleT (Tests-tab) preset.
      expect(
          byId['mean']?.openTarget, 'open:statistics?preset=statsDescriptive');
      expect(byId['one_sample_t']?.openTarget,
          'open:statistics?preset=statsOneSampleT');
      expect(byId['linreg']?.openTarget,
          'open:statistics?preset=statsLinearRegression');
      expect(byId['normal_dist']?.openTarget,
          'open:statistics?preset=statsNormalDist');
      expect(
          byId['paired_t']?.openTarget, 'open:statistics?preset=statsPairedT');
      expect(byId['chi2_independence']?.openTarget,
          'open:statistics?preset=statsChiSquareIndep');
      expect(byId['fisher_exact']?.openTarget,
          'open:statistics?preset=statsFisherExact');
      expect(byId['sign_test']?.openTarget,
          'open:statistics?preset=statsSignTest');
      expect(
          byId['wilcoxon']?.openTarget, 'open:statistics?preset=statsWilcoxon');
    });

    test('every StatisticsPreset is reachable from a FunctionRef entry', () {
      const prefix = 'open:statistics?preset=';
      final referenced = <String>{
        for (final e in FunctionReferences.all)
          if (e.openTarget != null && e.openTarget!.startsWith(prefix))
            e.openTarget!.substring(prefix.length),
      };
      for (final key in StatisticsPresets.all.keys) {
        expect(referenced.contains(key), isTrue,
            reason: 'preset "$key" is not referenced by any FunctionRef');
      }
    });
  });

  group('FunctionReferenceDialog "Open module" button', () {
    testWidgets('welch_t Open module lands on Tests tab pre-filled',
        (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const FunctionReferenceDialog(
                    initialSearch: 'welch_t',
                  ),
                ),
                child: const Text('open ref'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open ref'));
      await tester.pumpAndSettle();

      // The search is pre-filled to 'welch_t', so exactly one row shows.
      // Expand it by tapping the ExpansionTile, then bring the action
      // button into view (it sits below the examples in a scrollable).
      expect(find.byType(ExpansionTile), findsOneWidget);
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // The "Open module" button carries a unique open_in_new icon.
      final openBtn = find.byIcon(Icons.open_in_new);
      await tester.ensureVisible(openBtn);
      await tester.pumpAndSettle();
      expect(openBtn, findsOneWidget);
      await tester.tap(openBtn);
      await tester.pumpAndSettle();

      // Dialog popped, StatisticsScreen pushed, preset slot drained, the
      // Tests tab is active and pre-filled with the Welch group-A data.
      expect(AppState().pendingStatisticsPresetId, isNull);
      expect(find.text('One-sample t'), findsOneWidget);
      final preset = StatisticsPresets.all['statsWelchTwoSample']!;
      expect(find.text(preset.fields['twoSampleA']!), findsOneWidget);
    });
  });
}
