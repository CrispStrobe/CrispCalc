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
// Two-sample t-tests (independent), ANOVA, and chi-square
// independence are V2 territory.

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
