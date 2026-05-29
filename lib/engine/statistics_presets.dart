// lib/engine/statistics_presets.dart
//
// Round 95 follow-up (P6): named pre-fill presets for the Statistics
// module. A worked-example `open:statistics?preset=<id>` sentinel
// stashes the id on AppState; `_StatisticsScreenState` resolves it
// here to (a) pick the tab and (b) — for the Tests tab — pre-select a
// test kind and pre-fill the relevant input fields with a curated
// pedagogical dataset.
//
// Keeping the data here (plain Dart, numeric) rather than embedding it
// in the sentinel string keeps the catalog expressions short, avoids
// URL-style escaping of commas / newlines, and makes the whole flow
// headless-testable without pumping a widget.

/// One pre-fill recipe for the Statistics module.
class StatisticsPreset {
  /// Which tab to land on: `descriptive` / `regression` /
  /// `distributions` / `tests`. Matches the ids the screen already
  /// understands for `open:statistics?tab=<id>`.
  final String tab;

  /// For the Tests tab only: which test chip to pre-select. The value
  /// is a `_TestKind` enum name (e.g. `twoSampleT`, `anovaOneWay`,
  /// `chiSquareGof`). Null leaves the tab's default selection.
  final String? testId;

  /// Controller-name → text overrides applied on the receiving tab.
  /// Keys match the Tests-tab controller names
  /// (`twoSampleA`, `anovaGroups`, `gofObserved`, …). Unknown keys are
  /// ignored, so a typo degrades gracefully rather than crashing.
  final Map<String, String> fields;

  const StatisticsPreset({
    required this.tab,
    this.testId,
    this.fields = const {},
  });
}

/// The curated catalog, keyed by the id used in the
/// `open:statistics?preset=<id>` sentinel.
class StatisticsPresets {
  static const Map<String, StatisticsPreset> all = {
    // Welch two-sample t — two independent groups with (deliberately)
    // unequal spread, so the unequal-variance correction matters.
    'statsWelchTwoSample': StatisticsPreset(
      tab: 'tests',
      testId: 'twoSampleT',
      fields: {
        'twoSampleA': '82, 84, 79, 88, 91, 86, 83',
        'twoSampleB': '76, 78, 74, 80, 77, 75, 79',
        'alpha': '0.05',
      },
    ),
    // One-way ANOVA — three groups whose means clearly separate, a
    // textbook "reject H₀" illustration of the F-test.
    'statsAnovaThreeGroups': StatisticsPreset(
      tab: 'tests',
      testId: 'anovaOneWay',
      fields: {
        'anovaGroups': '21, 19, 23, 20, 22\n'
            '28, 31, 27, 30, 29\n'
            '24, 26, 25, 27, 23',
        'alpha': '0.05',
      },
    ),
    // Chi-square goodness-of-fit — observed die-roll-style counts
    // against a uniform expectation.
    'statsChiSquareGof': StatisticsPreset(
      tab: 'tests',
      testId: 'chiSquareGof',
      fields: {
        'gofObserved': '18, 22, 16, 24, 20',
        'gofExpected': '20, 20, 20, 20, 20',
        'alpha': '0.05',
      },
    ),
  };
}
