// lib/engine/hypothesis_tests.dart
//
// Hypothesis tests built on top of the Statistics and Distributions
// modules. V1 covers the three most-used:
//
//   - One-sample t-test (H₀: μ = μ₀)
//   - Paired t-test (H₀: μ_diff = 0)
//   - Chi-square goodness-of-fit (H₀: observed matches expected)
//
// Each test returns a result struct with the test statistic, degrees
// of freedom, p-value, and a verdict at a user-supplied significance
// level. The UI renders the verdict in plain language.
//
// V2 adds Welch's two-sample t-test for independent samples with
// unequal variances. V3 adds one-way ANOVA. V4 adds χ² independence
// for contingency tables.

import 'dart:math' as math;

import 'distributions.dart';
import 'statistics.dart';

/// Result of a one-sample or paired t-test.
class TTestResult {
  final double statistic;
  final int df;
  final double sampleMean;
  final double sampleStddev;
  final int sampleSize;
  final double hypothesizedMean;

  /// Two-sided p-value: P(|T| ≥ |t|).
  final double pValueTwoSided;

  /// Upper-tail one-sided p-value: P(T ≥ t).
  final double pValueOneSidedUpper;

  /// Lower-tail one-sided p-value: P(T ≤ t).
  final double pValueOneSidedLower;

  const TTestResult({
    required this.statistic,
    required this.df,
    required this.sampleMean,
    required this.sampleStddev,
    required this.sampleSize,
    required this.hypothesizedMean,
    required this.pValueTwoSided,
    required this.pValueOneSidedUpper,
    required this.pValueOneSidedLower,
  });

  bool rejectsAt(double alpha, {bool twoSided = true}) =>
      (twoSided ? pValueTwoSided : pValueOneSidedUpper) < alpha;
}

/// Result of an independent two-sample t-test (Welch's variant).
class TwoSampleTResult {
  final double statistic;

  /// Welch-Satterthwaite df. Non-integer in general — we keep it as a
  /// double; the UI rounds for display.
  final double df;

  final double mean1;
  final double mean2;
  final double stddev1;
  final double stddev2;
  final int n1;
  final int n2;

  final double pValueTwoSided;
  final double pValueOneSidedUpper;
  final double pValueOneSidedLower;

  const TwoSampleTResult({
    required this.statistic,
    required this.df,
    required this.mean1,
    required this.mean2,
    required this.stddev1,
    required this.stddev2,
    required this.n1,
    required this.n2,
    required this.pValueTwoSided,
    required this.pValueOneSidedUpper,
    required this.pValueOneSidedLower,
  });

  bool rejectsAt(double alpha, {bool twoSided = true}) =>
      (twoSided ? pValueTwoSided : pValueOneSidedUpper) < alpha;
}

/// Result of a one-way ANOVA.
class AnovaResult {
  final double fStatistic;

  /// Between-groups df = K − 1.
  final int dfBetween;

  /// Within-groups df = N − K.
  final int dfWithin;

  /// Sum of squares between groups.
  final double ssBetween;

  /// Sum of squares within groups (residual).
  final double ssWithin;

  /// Mean square between groups = SS_between / df_between.
  final double msBetween;

  /// Mean square within groups = SS_within / df_within.
  final double msWithin;

  /// Group means in the same order as the input.
  final List<double> groupMeans;

  /// Group sizes in the same order as the input.
  final List<int> groupSizes;

  /// Grand mean across all groups.
  final double grandMean;

  /// Upper-tail p-value: P(F ≥ fStatistic) under F(dfBetween, dfWithin).
  final double pValue;

  const AnovaResult({
    required this.fStatistic,
    required this.dfBetween,
    required this.dfWithin,
    required this.ssBetween,
    required this.ssWithin,
    required this.msBetween,
    required this.msWithin,
    required this.groupMeans,
    required this.groupSizes,
    required this.grandMean,
    required this.pValue,
  });

  bool rejectsAt(double alpha) => pValue < alpha;
}

/// Result of a chi-square test of independence on a contingency table.
class ChiSquareIndependenceResult {
  final double statistic;
  final int df;
  final double pValue;

  /// Row totals.
  final List<double> rowTotals;

  /// Column totals.
  final List<double> colTotals;

  /// Total of all cells.
  final double grandTotal;

  /// Expected counts, same shape as the input observed table.
  final List<List<double>> expected;

  /// The observed table (echoed back for display convenience).
  final List<List<double>> observed;

  const ChiSquareIndependenceResult({
    required this.statistic,
    required this.df,
    required this.pValue,
    required this.rowTotals,
    required this.colTotals,
    required this.grandTotal,
    required this.expected,
    required this.observed,
  });

  bool rejectsAt(double alpha) => pValue < alpha;
}

/// Result of a chi-square goodness-of-fit test.
class ChiSquareGofResult {
  final double statistic;
  final int df;
  final double pValue;
  final List<double> observed;
  final List<double> expected;

  const ChiSquareGofResult({
    required this.statistic,
    required this.df,
    required this.pValue,
    required this.observed,
    required this.expected,
  });

  bool rejectsAt(double alpha) => pValue < alpha;
}

class HypothesisTests {
  /// One-sample t-test. Computes t = (x̄ − μ₀) / (s / √n) with
  /// df = n − 1, where s is the sample stddev (Bessel-corrected).
  ///
  /// Throws if [data] is shorter than 2 (need variance) or if every
  /// value is identical (s = 0 → division by zero).
  static TTestResult oneSampleT({
    required List<double> data,
    required double hypothesizedMean,
  }) {
    if (data.length < 2) {
      throw ArgumentError('oneSampleT() needs at least 2 data points.');
    }
    final stats = Statistics.describe(data);
    if (stats.sampleStddev == 0) {
      throw ArgumentError(
          'oneSampleT() needs variance in the data (sample stddev is 0).');
    }
    final n = stats.count;
    final se = stats.sampleStddev / math.sqrt(n.toDouble());
    final t = (stats.mean - hypothesizedMean) / se;
    final df = n - 1;
    final tDist = TDistribution(df: df);

    final upper = (1.0 - tDist.cdf(t)).clamp(0.0, 1.0).toDouble();
    final lower = tDist.cdf(t).clamp(0.0, 1.0).toDouble();
    // Two-sided convention: 2 × min(upper, lower).
    final twoSided = (2 * math.min(upper, lower)).clamp(0.0, 1.0).toDouble();

    return TTestResult(
      statistic: t,
      df: df,
      sampleMean: stats.mean,
      sampleStddev: stats.sampleStddev,
      sampleSize: n,
      hypothesizedMean: hypothesizedMean,
      pValueTwoSided: twoSided,
      pValueOneSidedUpper: upper,
      pValueOneSidedLower: lower,
    );
  }

  /// Paired t-test. Computes differences d = before − after, then
  /// runs a one-sample t-test on the differences against μ₀ = 0.
  ///
  /// Throws on length mismatch or fewer than 2 pairs.
  static TTestResult pairedT({
    required List<double> before,
    required List<double> after,
  }) {
    if (before.length != after.length) {
      throw ArgumentError(
          'pairedT() expects same-length lists; got ${before.length} vs ${after.length}.');
    }
    if (before.length < 2) {
      throw ArgumentError('pairedT() needs at least 2 paired observations.');
    }
    final diffs = <double>[
      for (var i = 0; i < before.length; i++) before[i] - after[i],
    ];
    return oneSampleT(data: diffs, hypothesizedMean: 0.0);
  }

  /// Welch's two-sample t-test for independent samples with possibly
  /// unequal variances. This is the default in R's `t.test()` and the
  /// recommended modern choice over the pooled Student's t (which
  /// assumes equal variances).
  ///
  /// Computes:
  ///   t = (x̄₁ − x̄₂) / √(s₁²/n₁ + s₂²/n₂)
  ///   df via Welch-Satterthwaite:
  ///       df = (s₁²/n₁ + s₂²/n₂)² /
  ///            ((s₁²/n₁)²/(n₁−1) + (s₂²/n₂)²/(n₂−1))
  ///
  /// Throws if either sample has fewer than 2 observations or zero
  /// variance.
  static TwoSampleTResult welchT({
    required List<double> sample1,
    required List<double> sample2,
  }) {
    if (sample1.length < 2 || sample2.length < 2) {
      throw ArgumentError(
          'welchT() needs at least 2 observations in each sample.');
    }
    final s1 = Statistics.describe(sample1);
    final s2 = Statistics.describe(sample2);
    if (s1.sampleStddev == 0 || s2.sampleStddev == 0) {
      throw ArgumentError(
          'welchT() needs variance in both samples (one has stddev = 0).');
    }
    final v1 = s1.sampleVariance / s1.count;
    final v2 = s2.sampleVariance / s2.count;
    final se = math.sqrt(v1 + v2);
    final t = (s1.mean - s2.mean) / se;

    // Welch-Satterthwaite df.
    final num = (v1 + v2) * (v1 + v2);
    final den = (v1 * v1) / (s1.count - 1) + (v2 * v2) / (s2.count - 1);
    final df = num / den;

    // For the p-value we need T-distribution CDFs at non-integer df.
    // TDistribution accepts int df; round it (Welch's df is approximate
    // anyway). For a more accurate p, we'd want a real Γ-based pdf
    // integrator — but the round is the standard textbook approach and
    // matches what most stats packages display.
    final dfInt = df.round();
    final tDist = TDistribution(df: math.max(1, dfInt));

    final upper = (1.0 - tDist.cdf(t)).clamp(0.0, 1.0).toDouble();
    final lower = tDist.cdf(t).clamp(0.0, 1.0).toDouble();
    final twoSided = (2 * math.min(upper, lower)).clamp(0.0, 1.0).toDouble();

    return TwoSampleTResult(
      statistic: t,
      df: df,
      mean1: s1.mean,
      mean2: s2.mean,
      stddev1: s1.sampleStddev,
      stddev2: s2.sampleStddev,
      n1: s1.count,
      n2: s2.count,
      pValueTwoSided: twoSided,
      pValueOneSidedUpper: upper,
      pValueOneSidedLower: lower,
    );
  }

  /// One-way ANOVA across K independent groups. Tests
  /// H₀: μ₁ = μ₂ = … = μ_K. Computes
  ///
  ///   SS_between = Σᵢ nᵢ (x̄ᵢ − x̄)²,            df = K − 1
  ///   SS_within  = Σᵢ Σⱼ (xᵢⱼ − x̄ᵢ)²,           df = N − K
  ///   F          = (SS_between / df_b) / (SS_within / df_w)
  ///
  /// p-value is the upper-tail probability under F(K − 1, N − K).
  ///
  /// Throws if fewer than 2 groups are provided, any group has fewer
  /// than 1 observation, or every group has the same (within-zero)
  /// variance with identical means (degenerate, F undefined).
  static AnovaResult anovaOneWay(List<List<double>> groups) {
    if (groups.length < 2) {
      throw ArgumentError('anovaOneWay() needs at least 2 groups.');
    }
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].isEmpty) {
        throw ArgumentError(
            'anovaOneWay() group $i has no observations.');
      }
    }

    final k = groups.length;
    final groupMeans = <double>[];
    final groupSizes = <int>[];
    var totalN = 0;
    var totalSum = 0.0;
    for (final g in groups) {
      final n = g.length;
      final mean = g.reduce((a, b) => a + b) / n;
      groupMeans.add(mean);
      groupSizes.add(n);
      totalN += n;
      totalSum += mean * n;
    }
    if (totalN <= k) {
      throw ArgumentError(
          'anovaOneWay() needs more total observations than groups (got '
          'N=$totalN, K=$k).');
    }
    final grandMean = totalSum / totalN;

    var ssBetween = 0.0;
    for (var i = 0; i < k; i++) {
      final d = groupMeans[i] - grandMean;
      ssBetween += groupSizes[i] * d * d;
    }
    var ssWithin = 0.0;
    for (var i = 0; i < k; i++) {
      for (final x in groups[i]) {
        final d = x - groupMeans[i];
        ssWithin += d * d;
      }
    }

    final dfBetween = k - 1;
    final dfWithin = totalN - k;
    final msBetween = ssBetween / dfBetween;
    final msWithin = ssWithin / dfWithin;

    if (msWithin == 0) {
      throw ArgumentError(
          'anovaOneWay() within-group variance is 0 (F statistic '
          'undefined). Check that the groups have variation.');
    }

    final f = msBetween / msWithin;
    final fDist = FDistribution(d1: dfBetween, d2: dfWithin);
    // Use sf() rather than 1 - cdf() to keep precision deep in the
    // upper tail where ANOVA F statistics often live.
    final p = fDist.sf(f).clamp(0.0, 1.0);

    return AnovaResult(
      fStatistic: f,
      dfBetween: dfBetween,
      dfWithin: dfWithin,
      ssBetween: ssBetween,
      ssWithin: ssWithin,
      msBetween: msBetween,
      msWithin: msWithin,
      groupMeans: List.unmodifiable(groupMeans),
      groupSizes: List.unmodifiable(groupSizes),
      grandMean: grandMean,
      pValue: p.toDouble(),
    );
  }

  /// χ² test of independence on an R × C contingency table.
  ///
  /// Expected counts under H₀ (row and column are independent) are
  /// `E[i,j] = (rowTotal[i] · colTotal[j]) / grandTotal`. The statistic
  /// is `χ² = Σᵢⱼ (Oᵢⱼ − Eᵢⱼ)² / Eᵢⱼ` with df = (R − 1)(C − 1). The
  /// p-value is the upper-tail probability under χ²(df).
  ///
  /// Throws if the table has fewer than 2 rows or 2 columns, any row
  /// is the wrong length, any cell is negative, any row or column
  /// total is zero, or the grand total is zero.
  static ChiSquareIndependenceResult chiSquareIndependence(
    List<List<double>> observed,
  ) {
    if (observed.length < 2) {
      throw ArgumentError(
          'chiSquareIndependence() needs at least 2 rows.');
    }
    final cols = observed.first.length;
    if (cols < 2) {
      throw ArgumentError(
          'chiSquareIndependence() needs at least 2 columns.');
    }
    for (var i = 0; i < observed.length; i++) {
      if (observed[i].length != cols) {
        throw ArgumentError(
            'chiSquareIndependence() rows must have the same length; '
            'row $i has ${observed[i].length} cells (expected $cols).');
      }
      for (final v in observed[i]) {
        if (v < 0) {
          throw ArgumentError(
              'chiSquareIndependence() observed counts must be '
              'non-negative.');
        }
      }
    }

    final rows = observed.length;
    final rowTotals = List<double>.filled(rows, 0);
    final colTotals = List<double>.filled(cols, 0);
    var grandTotal = 0.0;
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        rowTotals[i] += observed[i][j];
        colTotals[j] += observed[i][j];
        grandTotal += observed[i][j];
      }
    }
    if (grandTotal == 0) {
      throw ArgumentError(
          'chiSquareIndependence() grand total is zero.');
    }
    for (var i = 0; i < rows; i++) {
      if (rowTotals[i] == 0) {
        throw ArgumentError(
            'chiSquareIndependence() row $i has total 0 (cannot form '
            'expected counts).');
      }
    }
    for (var j = 0; j < cols; j++) {
      if (colTotals[j] == 0) {
        throw ArgumentError(
            'chiSquareIndependence() column $j has total 0 (cannot '
            'form expected counts).');
      }
    }

    final expected = List<List<double>>.generate(
      rows,
      (i) => List<double>.generate(
        cols,
        (j) => rowTotals[i] * colTotals[j] / grandTotal,
      ),
    );
    var chi2 = 0.0;
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        final d = observed[i][j] - expected[i][j];
        chi2 += d * d / expected[i][j];
      }
    }
    final df = (rows - 1) * (cols - 1);
    final p = (1.0 - ChiSquare(df: df).cdf(chi2)).clamp(0.0, 1.0).toDouble();

    return ChiSquareIndependenceResult(
      statistic: chi2,
      df: df,
      pValue: p,
      rowTotals: List.unmodifiable(rowTotals),
      colTotals: List.unmodifiable(colTotals),
      grandTotal: grandTotal,
      expected: List.unmodifiable([
        for (final row in expected) List<double>.unmodifiable(row),
      ]),
      observed: List.unmodifiable([
        for (final row in observed) List<double>.unmodifiable(row),
      ]),
    );
  }

  /// Chi-square goodness-of-fit. χ² = Σ (Oᵢ − Eᵢ)² / Eᵢ with
  /// df = k − 1 (no parameters estimated from the data). p-value is
  /// the upper-tail probability under χ²(df).
  ///
  /// Throws on length mismatch, negative observed counts, or any zero
  /// expected count (division by zero).
  static ChiSquareGofResult chiSquareGof({
    required List<double> observed,
    required List<double> expected,
  }) {
    if (observed.length != expected.length) {
      throw ArgumentError(
          'chiSquareGof() expects same-length lists; got ${observed.length} vs ${expected.length}.');
    }
    if (observed.length < 2) {
      throw ArgumentError('chiSquareGof() needs at least 2 categories.');
    }
    for (final v in expected) {
      if (v <= 0) {
        throw ArgumentError('chiSquareGof() expected counts must all be > 0.');
      }
    }
    for (final v in observed) {
      if (v < 0) {
        throw ArgumentError(
            'chiSquareGof() observed counts must be non-negative.');
      }
    }
    var chi2 = 0.0;
    for (var i = 0; i < observed.length; i++) {
      final d = observed[i] - expected[i];
      chi2 += d * d / expected[i];
    }
    final df = observed.length - 1;
    final p = (1.0 - ChiSquare(df: df).cdf(chi2)).clamp(0.0, 1.0);
    return ChiSquareGofResult(
      statistic: chi2,
      df: df,
      pValue: p,
      observed: List.unmodifiable(observed),
      expected: List.unmodifiable(expected),
    );
  }
}
