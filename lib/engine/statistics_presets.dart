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
  /// `chiSquareGof`). Null leaves the tab's default selection. The
  /// Descriptive / Regression / Distributions tabs have no sub-selection
  /// chip, so their presets leave this null and rely on [fields] alone.
  final String? testId;

  /// Controller-name → text overrides applied on the receiving tab.
  /// Keys match the receiving tab's controller names — Tests
  /// (`twoSampleA`, `anovaGroups`, `gofObserved`, …), Descriptive
  /// (`descriptiveData`), Regression (`regressionX` / `regressionY`),
  /// Distributions (`normMean` / `normSd` / `normX` / `normP` / `binN`
  /// / `binP` / `binK`). Unknown keys are ignored, so a typo degrades
  /// gracefully rather than crashing.
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
    // One-sample t — class test scores against a hypothesised mean of
    // 70; the sample sits clearly above it.
    'statsOneSampleT': StatisticsPreset(
      tab: 'tests',
      testId: 'oneSampleT',
      fields: {
        'oneSampleData': '74, 78, 81, 69, 76, 80, 77',
        'oneSampleMu': '70',
        'alpha': '0.05',
      },
    ),
    // Paired t — before/after measurements on the same units with a
    // consistent downward shift.
    'statsPairedT': StatisticsPreset(
      tab: 'tests',
      testId: 'pairedT',
      fields: {
        'pairedBefore': '80, 82, 79, 85, 88, 81',
        'pairedAfter': '76, 79, 75, 80, 84, 78',
        'alpha': '0.05',
      },
    ),
    // Chi-square test of independence — a 2×2 contingency table with a
    // clear association between the row and column factors.
    'statsChiSquareIndep': StatisticsPreset(
      tab: 'tests',
      testId: 'chiSquareIndep',
      fields: {
        'indepTable': '30, 10\n12, 28',
        'alpha': '0.05',
      },
    ),
    // Fisher's exact test — a small 2×2 table where expected counts are
    // low, so the exact test is preferred over χ².
    'statsFisherExact': StatisticsPreset(
      tab: 'tests',
      testId: 'fisherExact',
      fields: {
        'fisherTable': '8, 2, 1, 9',
        'alpha': '0.05',
      },
    ),
    // Paired sign test — the nonparametric counterpart to the paired t;
    // most pairs decrease from before to after.
    'statsSignTest': StatisticsPreset(
      tab: 'tests',
      testId: 'pairedSign',
      fields: {
        'signBefore': '12, 15, 14, 11, 13, 16, 10',
        'signAfter': '10, 12, 13, 9, 11, 14, 8',
        'alpha': '0.05',
      },
    ),
    // Wilcoxon rank-sum (Mann–Whitney U) — two independent groups whose
    // distributions are clearly separated.
    'statsWilcoxon': StatisticsPreset(
      tab: 'tests',
      testId: 'wilcoxonRankSum',
      fields: {
        'wilcoxonA': '12, 14, 11, 13, 15',
        'wilcoxonB': '20, 22, 19, 21, 23',
        'alpha': '0.05',
      },
    ),
    // Descriptive statistics — a single numeric sample with enough
    // spread that mean, median, SD, quartiles and IQR all differ
    // visibly. Lands on the Descriptive Stats tab.
    'statsDescriptive': StatisticsPreset(
      tab: 'descriptive',
      fields: {
        'descriptiveData': '12, 15, 14, 10, 18, 13, 16, 11, 17, 14',
      },
    ),
    // Linear regression — six (x, y) points lying close to y = 2x, so
    // the least-squares fit has a slope ≈ 2 and a high R². Lands on the
    // Regression tab with its default linear model.
    'statsLinearRegression': StatisticsPreset(
      tab: 'regression',
      fields: {
        'regressionX': '1, 2, 3, 4, 5, 6',
        'regressionY': '2.1, 3.9, 6.2, 7.8, 10.1, 11.9',
      },
    ),
    // Normal distribution — an IQ-style N(100, 15); the CDF point and
    // the 0.95 quantile illustrate the tail/inverse-CDF readouts. Lands
    // on the Distributions tab.
    'statsNormalDist': StatisticsPreset(
      tab: 'distributions',
      fields: {
        'normMean': '100',
        'normSd': '15',
        'normX': '130',
        'normP': '0.95',
      },
    ),
    // Binomial distribution — a quality-control flavour: n = 20 trials
    // with a 10 % defect rate, asking about k = 2 defects (the mean).
    // Lands on the Distributions tab (binomial section).
    'statsBinomialDist': StatisticsPreset(
      tab: 'distributions',
      fields: {
        'binN': '20',
        'binP': '0.1',
        'binK': '2',
      },
    ),
  };
}
