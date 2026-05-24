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
// for contingency tables. V5 adds Fisher's exact test for sparse 2×2
// tables (where χ² isn't reliable).

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

/// Result of Fisher's exact test on a 2×2 contingency table.
class FisherExactResult {
  /// Observed cell counts in [a, b, c, d] form:
  /// `a b`
  /// `c d`
  final int a, b, c, d;

  /// P(observed | margins) under H₀.
  final double pObserved;

  /// Two-sided p-value: sum of P(table) over all tables with the same
  /// row/column margins whose probability is ≤ pObserved.
  final double pValueTwoSided;

  /// Upper-tail (right) one-sided p-value: P(A ≥ a | margins).
  final double pValueOneSidedUpper;

  /// Lower-tail (left) one-sided p-value: P(A ≤ a | margins).
  final double pValueOneSidedLower;

  const FisherExactResult({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.pObserved,
    required this.pValueTwoSided,
    required this.pValueOneSidedUpper,
    required this.pValueOneSidedLower,
  });

  bool rejectsAt(double alpha, {bool twoSided = true}) =>
      (twoSided ? pValueTwoSided : pValueOneSidedUpper) < alpha;
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

/// Result of a paired sign test.
class SignTestResult {
  /// Number of pairs where before > after.
  final int positives;

  /// Number of pairs where before < after.
  final int negatives;

  /// Number of pairs where before == after (excluded from the test).
  final int zeros;

  /// Effective sample size = positives + negatives.
  int get n => positives + negatives;

  /// Two-sided p-value: 2 · min(P(X ≤ k), P(X ≥ k)) clamped to [0, 1].
  /// k is the smaller of [positives] and [negatives]; under H₀ both
  /// follow Binomial(n, 0.5).
  final double pValueTwoSided;

  /// Upper-tail (right) one-sided p-value: P(X ≥ positives | H₀).
  final double pValueOneSidedUpper;

  /// Lower-tail (left) one-sided p-value: P(X ≤ positives | H₀).
  final double pValueOneSidedLower;

  const SignTestResult({
    required this.positives,
    required this.negatives,
    required this.zeros,
    required this.pValueTwoSided,
    required this.pValueOneSidedUpper,
    required this.pValueOneSidedLower,
  });

  bool rejectsAt(double alpha, {bool twoSided = true}) =>
      (twoSided ? pValueTwoSided : pValueOneSidedUpper) < alpha;
}

/// Result of a Wilcoxon rank-sum (Mann-Whitney U) test.
class WilcoxonRankSumResult {
  /// Sum of ranks in sample 1 (after pooled ranking with average-rank
  /// tie correction).
  final double rankSum1;

  /// Mann-Whitney U statistic for sample 1:
  /// U₁ = R₁ − n₁(n₁ + 1)/2. Equivalent in information content to W
  /// (the rank-sum); we keep both for display convenience.
  final double u1;

  /// Mann-Whitney U statistic for sample 2: U₂ = n₁·n₂ − U₁.
  final double u2;

  /// Standard-normal approximation z, with tie correction in σ_U:
  ///   μ_U = n₁n₂ / 2
  ///   σ_U² = n₁n₂(n₁+n₂+1)/12 · (1 − Σ(tᵢ³ − tᵢ) / ((n₁+n₂)³ − (n₁+n₂)))
  /// Continuity correction (±0.5) is *not* applied — matches R's
  /// `wilcox.test(..., exact = FALSE, correct = FALSE)`.
  final double z;

  final int n1;
  final int n2;

  /// Two-sided p-value: 2 · Φ(−|z|), clamped to [0, 1].
  final double pValueTwoSided;

  /// Upper-tail one-sided p-value: P(Z ≥ z).
  final double pValueOneSidedUpper;

  /// Lower-tail one-sided p-value: P(Z ≤ z).
  final double pValueOneSidedLower;

  const WilcoxonRankSumResult({
    required this.rankSum1,
    required this.u1,
    required this.u2,
    required this.z,
    required this.n1,
    required this.n2,
    required this.pValueTwoSided,
    required this.pValueOneSidedUpper,
    required this.pValueOneSidedLower,
  });

  bool rejectsAt(double alpha, {bool twoSided = true}) =>
      (twoSided ? pValueTwoSided : pValueOneSidedUpper) < alpha;
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
        throw ArgumentError('anovaOneWay() group $i has no observations.');
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
      throw ArgumentError('chiSquareIndependence() needs at least 2 rows.');
    }
    final cols = observed.first.length;
    if (cols < 2) {
      throw ArgumentError('chiSquareIndependence() needs at least 2 columns.');
    }
    for (var i = 0; i < observed.length; i++) {
      if (observed[i].length != cols) {
        throw ArgumentError(
            'chiSquareIndependence() rows must have the same length; '
            'row $i has ${observed[i].length} cells (expected $cols).');
      }
      for (final v in observed[i]) {
        if (v < 0) {
          throw ArgumentError('chiSquareIndependence() observed counts must be '
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
      throw ArgumentError('chiSquareIndependence() grand total is zero.');
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

  /// Fisher's exact test on a 2×2 contingency table:
  ///   `a b`
  ///   `c d`
  ///
  /// Conditional on fixed row totals (a+b, c+d) and column totals
  /// (a+c, b+d), the count in cell `a` follows a hypergeometric
  /// distribution. The test enumerates every table with the same
  /// margins and picks p-values directly — no large-sample
  /// approximation.
  ///
  /// Two-sided p-value uses R's `fisher.test()` convention: sum of
  /// P(table) over all tables with the same margins whose probability
  /// is ≤ P(observed). This is more rigorous than the doubling
  /// convention and handles asymmetric distributions correctly.
  ///
  /// Use this instead of χ² independence whenever any expected count
  /// falls below ~5, which is the canonical textbook threshold for
  /// when the χ² large-sample approximation breaks down.
  ///
  /// Throws on any negative count or when all four cells are zero.
  static FisherExactResult fisherExact2x2(int a, int b, int c, int d) {
    if (a < 0 || b < 0 || c < 0 || d < 0) {
      throw ArgumentError(
          'fisherExact2x2() requires non-negative cell counts.');
    }
    if (a + b + c + d == 0) {
      throw ArgumentError('fisherExact2x2() requires at least one count.');
    }
    final r1 = a + b;
    final r2 = c + d;
    final c1 = a + c;
    final n = r1 + r2;

    // Hypergeometric probability P(A = k) for cell `a` given the
    // margins r1, r2, c1, n. Computed in log-domain via log-Choose to
    // stay stable for moderately large totals.
    double pHyper(int k) {
      if (k < 0 || k > r1 || k > c1 || (c1 - k) > r2) return 0.0;
      final lp = logChoose(r1, k) + logChoose(r2, c1 - k) - logChoose(n, c1);
      return math.exp(lp);
    }

    final pObs = pHyper(a);

    // Range of valid `a` values given the margins.
    final kMin = math.max(0, c1 - r2);
    final kMax = math.min(r1, c1);

    var pTwoSided = 0.0;
    var pUpper = 0.0;
    var pLower = 0.0;
    // Use a small epsilon for the "≤ P(observed)" comparison to ensure
    // the observed table is always counted in (avoids floating-point
    // strict inequalities dropping the equality case).
    const eps = 1e-12;
    for (var k = kMin; k <= kMax; k++) {
      final p = pHyper(k);
      if (p <= pObs + eps) pTwoSided += p;
      if (k >= a) pUpper += p;
      if (k <= a) pLower += p;
    }

    return FisherExactResult(
      a: a,
      b: b,
      c: c,
      d: d,
      pObserved: pObs,
      pValueTwoSided: pTwoSided.clamp(0.0, 1.0).toDouble(),
      pValueOneSidedUpper: pUpper.clamp(0.0, 1.0).toDouble(),
      pValueOneSidedLower: pLower.clamp(0.0, 1.0).toDouble(),
    );
  }

  /// Paired sign test on matched samples [before] and [after]. Counts
  /// positive (before > after) and negative (before < after) pair
  /// differences, dropping zeros. Under H₀: median(before − after) = 0,
  /// the count of positives follows Binomial(n_nonzero, 0.5). The
  /// p-value is `2 · min(P(X ≤ k), P(X ≥ k))` with k = min(pos, neg),
  /// clamped to [0, 1].
  ///
  /// This is the nonparametric counterpart to [pairedT]: it makes no
  /// distributional assumption about the differences, so it's the
  /// right choice when the data have outliers, are ordinal, or when
  /// the difference distribution is plainly non-normal. Less powerful
  /// than the paired t-test when the t-test's assumptions hold.
  ///
  /// Throws on length mismatch or when there are zero non-zero
  /// differences (every pair is a tie — the test is undefined).
  static SignTestResult pairedSign({
    required List<double> before,
    required List<double> after,
  }) {
    if (before.length != after.length) {
      throw ArgumentError(
          'pairedSign() expects same-length lists; got ${before.length} vs ${after.length}.');
    }
    if (before.isEmpty) {
      throw ArgumentError(
          'pairedSign() needs at least one paired observation.');
    }
    var positives = 0;
    var negatives = 0;
    var zeros = 0;
    for (var i = 0; i < before.length; i++) {
      final d = before[i] - after[i];
      if (d > 0) {
        positives++;
      } else if (d < 0) {
        negatives++;
      } else {
        zeros++;
      }
    }
    final n = positives + negatives;
    if (n == 0) {
      throw ArgumentError(
          'pairedSign() needs at least one non-zero difference (every '
          'pair was a tie).');
    }
    final binom = Binomial(n: n, p: 0.5);
    final k = math.min(positives, negatives);
    // Lower tail at k, upper tail at k. By symmetry of Binomial(n, 0.5)
    // the smaller-side cumulative probability is what the two-sided
    // p-value doubles. Clamp to 1 (the two-sided sum can exceed 1
    // by a hair when k = n/2 because we count the median bin twice).
    final tail = binom.cdf(k);
    final twoSided = math.min(1.0, 2 * tail);
    // One-sided p-values centered on the observed `positives` count.
    final lower = binom.cdf(positives).clamp(0.0, 1.0).toDouble();
    final upper = positives == 0
        ? 1.0
        : (1.0 - binom.cdf(positives - 1)).clamp(0.0, 1.0).toDouble();
    return SignTestResult(
      positives: positives,
      negatives: negatives,
      zeros: zeros,
      pValueTwoSided: twoSided,
      pValueOneSidedUpper: upper,
      pValueOneSidedLower: lower,
    );
  }

  /// Wilcoxon rank-sum (Mann-Whitney U) test on two independent
  /// samples. Pools and ranks the combined data with average-rank tie
  /// correction, computes the rank-sum of sample 1, then uses the
  /// large-sample normal approximation
  ///
  ///   z = (U₁ − μ_U) / σ_U     with   μ_U = n₁n₂/2
  ///   σ_U² = n₁n₂(n₁+n₂+1)/12 · (1 − Σ(tᵢ³ − tᵢ) / ((N)³ − N))
  ///
  /// where the tᵢ are tie-group sizes. The two-sided p-value is
  /// 2·Φ(−|z|). No continuity correction — matches R's
  /// `wilcox.test(..., exact = FALSE, correct = FALSE)`.
  ///
  /// This is the nonparametric counterpart to [welchT]; use it when
  /// the samples are ordinal or non-normal. The normal approximation
  /// is reliable for n₁, n₂ ≳ 10.
  ///
  /// Throws if either sample is empty.
  static WilcoxonRankSumResult wilcoxonRankSum({
    required List<double> sample1,
    required List<double> sample2,
  }) {
    if (sample1.isEmpty || sample2.isEmpty) {
      throw ArgumentError(
          'wilcoxonRankSum() needs at least one observation in each sample.');
    }
    final n1 = sample1.length;
    final n2 = sample2.length;
    final n = n1 + n2;

    // Pool with origin tags, sort by value, then assign average ranks
    // to tied runs. Tag 1 → sample1, 2 → sample2.
    final pooled = <(double value, int tag)>[
      for (final v in sample1) (v, 1),
      for (final v in sample2) (v, 2),
    ];
    pooled.sort((a, b) => a.$1.compareTo(b.$1));

    final ranks = List<double>.filled(n, 0);
    final tieSizes = <int>[];
    var i = 0;
    while (i < n) {
      var j = i;
      while (j + 1 < n && pooled[j + 1].$1 == pooled[i].$1) {
        j++;
      }
      // Tied run spans indices [i, j]; average rank (1-indexed) is
      // ((i+1) + (j+1)) / 2.
      final avg = ((i + 1) + (j + 1)) / 2.0;
      for (var k = i; k <= j; k++) {
        ranks[k] = avg;
      }
      if (j - i + 1 > 1) tieSizes.add(j - i + 1);
      i = j + 1;
    }

    var rankSum1 = 0.0;
    for (var k = 0; k < n; k++) {
      if (pooled[k].$2 == 1) rankSum1 += ranks[k];
    }
    final u1 = rankSum1 - n1 * (n1 + 1) / 2.0;
    final u2 = n1.toDouble() * n2 - u1;

    final muU = n1 * n2 / 2.0;
    // Tie correction factor for σ_U².
    var tieSum = 0.0;
    for (final t in tieSizes) {
      tieSum += t * t * t - t;
    }
    final varU = (n1.toDouble() * n2 * (n + 1) / 12.0) *
        (1.0 - tieSum / (n.toDouble() * n * n - n));
    final sigmaU = math.sqrt(math.max(varU, 0));

    double z;
    double upper;
    double lower;
    if (sigmaU == 0) {
      // Degenerate (all values tied) — z undefined, treat as no effect.
      z = 0;
      upper = 0.5;
      lower = 0.5;
    } else {
      z = (u1 - muU) / sigmaU;
      upper = (1.0 - standardNormal.cdf(z)).clamp(0.0, 1.0).toDouble();
      lower = standardNormal.cdf(z).clamp(0.0, 1.0).toDouble();
    }
    final twoSided = (2 * math.min(upper, lower)).clamp(0.0, 1.0).toDouble();

    return WilcoxonRankSumResult(
      rankSum1: rankSum1,
      u1: u1,
      u2: u2,
      z: z,
      n1: n1,
      n2: n2,
      pValueTwoSided: twoSided,
      pValueOneSidedUpper: upper,
      pValueOneSidedLower: lower,
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
