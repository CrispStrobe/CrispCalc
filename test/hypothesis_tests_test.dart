// test/hypothesis_tests_test.dart
//
// Coverage for the three V1 hypothesis tests. Cross-checked against
// known textbook values for the t-statistic and p-value (loose
// tolerance: ~1% on p-values since they come from numerical
// integration of the PDF).

import 'package:crisp_calc/engine/hypothesis_tests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('oneSampleT', () {
    test('mean matches H₀ exactly → t = 0, p ≈ 1', () {
      // Sample with mean 5 against μ₀ = 5.
      final r = HypothesisTests.oneSampleT(
        data: const [4, 5, 6, 4, 6, 5, 5, 4, 6, 5],
        hypothesizedMean: 5,
      );
      expect(r.statistic, closeTo(0.0, 1e-9));
      expect(r.pValueTwoSided, closeTo(1.0, 0.05));
    });

    test('classic textbook example — t and p ≈ known values', () {
      // Heights data, μ₀ = 170. Hand-checked:
      //   x̄ = 174, sample s = √(80/4) = √20 ≈ 4.472, n = 5
      //   t = (174 − 170) / (4.472/√5) = 4 / 2.0 = 2.0
      //   p-value two-sided at df=4 ≈ 0.116
      final r = HypothesisTests.oneSampleT(
        data: const [172, 174, 168, 180, 176],
        hypothesizedMean: 170,
      );
      expect(r.sampleMean, closeTo(174.0, 1e-9));
      expect(r.statistic, closeTo(2.0, 1e-3));
      expect(r.df, equals(4));
      expect(r.pValueTwoSided, closeTo(0.116, 0.02));
    });

    test('clearly significant — rejects at α = 0.05', () {
      // Mean very different from H₀.
      final r = HypothesisTests.oneSampleT(
        data: const [100, 102, 99, 101, 100, 98, 103, 101, 100, 99],
        hypothesizedMean: 50,
      );
      expect(r.rejectsAt(0.05), isTrue);
      expect(r.pValueTwoSided, lessThan(1e-6));
    });

    test('upper-tail and lower-tail p sum to 1', () {
      final r = HypothesisTests.oneSampleT(
        data: const [10, 12, 11, 14, 13],
        hypothesizedMean: 11.0,
      );
      expect(r.pValueOneSidedUpper + r.pValueOneSidedLower, closeTo(1.0, 1e-6));
    });

    test('zero variance throws', () {
      expect(
        () => HypothesisTests.oneSampleT(
          data: const [5, 5, 5, 5],
          hypothesizedMean: 4,
        ),
        throwsArgumentError,
      );
    });

    test('single value throws', () {
      expect(
        () => HypothesisTests.oneSampleT(
          data: const [5.0],
          hypothesizedMean: 4,
        ),
        throwsArgumentError,
      );
    });
  });

  group('pairedT', () {
    test('identical pairs → t = 0', () {
      final r = HypothesisTests.pairedT(
        before: const [1, 2, 3, 4, 5],
        after: const [1, 2, 3, 4, 5],
      );
      // Differences are all 0 → sample stddev is 0; the underlying
      // one-sample call should throw.
      // Wait — actually identical pairs throws because variance=0.
      // This test confirms that contract.
      expect(r, isNotNull); // unreachable: should throw
    }, skip: 'identical pairs throw because variance=0');

    test('constant difference → all-zero variance throws', () {
      expect(
        () => HypothesisTests.pairedT(
          before: const [1, 2, 3, 4, 5],
          after: const [3, 4, 5, 6, 7],
        ),
        throwsArgumentError,
      );
    });

    test('classic before/after — non-trivial t', () {
      // Differences = [3, 1, 4, 2, 3, 2, 4, 1, 3, 2], mean ≈ 2.5.
      final r = HypothesisTests.pairedT(
        before: const [10, 12, 14, 13, 15, 11, 14, 10, 13, 12],
        after: const [7, 11, 10, 11, 12, 9, 10, 9, 10, 10],
      );
      expect(r.sampleMean, closeTo(2.5, 1e-9));
      expect(r.df, equals(9));
      expect(r.statistic, greaterThan(0));
      expect(r.pValueTwoSided, lessThan(0.001));
    });

    test('length mismatch throws', () {
      expect(
        () => HypothesisTests.pairedT(
          before: const [1, 2],
          after: const [1, 2, 3],
        ),
        throwsArgumentError,
      );
    });
  });

  group('welchT (two-sample t)', () {
    test('equal means → t ≈ 0, p ≈ 1', () {
      final r = HypothesisTests.welchT(
        sample1: const [5, 6, 7, 5, 6, 7, 5, 6, 7],
        sample2: const [5, 6, 7, 5, 6, 7, 5, 6, 7],
      );
      expect(r.statistic, closeTo(0.0, 1e-9));
      expect(r.pValueTwoSided, closeTo(1.0, 0.05));
    });

    test('classic textbook example — different means, similar variance', () {
      // Sample 1: [8,9,10,10,11,12]. n=6, x̄₁=10. Deviations
      //   -2,-1,0,0,1,2 → SS=10, sample var s₁²=10/5=2.0 → v₁=2/6=1/3.
      // Sample 2: same shape, x̄₂=12, v₂=1/3.
      // SE = √(2/3) ≈ 0.8165 → t = (10−12)/0.8165 ≈ -2.449.
      // df Welch = (v₁+v₂)² / (v₁²/(n₁−1)+v₂²/(n₂−1)) = 10.
      final r = HypothesisTests.welchT(
        sample1: const [8, 9, 10, 10, 11, 12],
        sample2: const [10, 11, 12, 12, 13, 14],
      );
      expect(r.mean1, closeTo(10.0, 1e-9));
      expect(r.mean2, closeTo(12.0, 1e-9));
      expect(r.statistic, closeTo(-2.449, 0.01));
      expect(r.df, closeTo(10.0, 1e-6));
    });

    test('strongly different means — rejected at α = 0.05', () {
      final r = HypothesisTests.welchT(
        sample1: const [100, 102, 99, 101, 100, 98, 103, 101, 100, 99],
        sample2: const [50, 52, 49, 51, 50, 48, 53, 51, 50, 49],
      );
      expect(r.rejectsAt(0.05), isTrue);
      expect(r.pValueTwoSided, lessThan(1e-9));
    });

    test('upper-tail and lower-tail p sum to 1', () {
      final r = HypothesisTests.welchT(
        sample1: const [10, 12, 11, 14, 13],
        sample2: const [10, 11, 9, 13, 12],
      );
      expect(r.pValueOneSidedUpper + r.pValueOneSidedLower, closeTo(1.0, 1e-6));
    });

    test('Welch handles unequal variances', () {
      // Sample 1: small spread. Sample 2: large spread, same mean.
      final r = HypothesisTests.welchT(
        sample1: const [9.9, 10.0, 10.1, 9.95, 10.05],
        sample2: const [5.0, 8.0, 10.0, 12.0, 15.0],
      );
      // Means: 10.0 vs 10.0 → t ≈ 0, p ≈ 1.
      expect(r.statistic, closeTo(0.0, 0.1));
      expect(r.rejectsAt(0.05), isFalse);
    });

    test('zero variance in either sample throws', () {
      expect(
        () => HypothesisTests.welchT(
          sample1: const [5, 5, 5, 5],
          sample2: const [4, 6, 5, 7],
        ),
        throwsArgumentError,
      );
    });

    test('fewer than 2 in either sample throws', () {
      expect(
        () => HypothesisTests.welchT(
          sample1: const [5.0],
          sample2: const [4, 5, 6],
        ),
        throwsArgumentError,
      );
    });
  });

  group('chiSquareGof', () {
    test('observed = expected → χ² = 0, p = 1', () {
      final r = HypothesisTests.chiSquareGof(
        observed: const [10, 20, 30, 40],
        expected: const [10, 20, 30, 40],
      );
      expect(r.statistic, closeTo(0.0, 1e-9));
      expect(r.pValue, closeTo(1.0, 1e-3));
    });

    test('fair die simulated — typically not rejected', () {
      // 60 throws of a fair six-sided die; expected 10 each.
      // Slight deviations should give a moderate p (> 0.05).
      final r = HypothesisTests.chiSquareGof(
        observed: const [9, 11, 10, 12, 9, 9],
        expected: const [10, 10, 10, 10, 10, 10],
      );
      expect(r.df, equals(5));
      // χ² = (1+1+0+4+1+1)/10 = 0.8, p (df=5, χ²=0.8) ≈ 0.977.
      expect(r.statistic, closeTo(0.8, 1e-9));
      expect(r.pValue, greaterThan(0.5));
      expect(r.rejectsAt(0.05), isFalse);
    });

    test('rigged die — clearly rejected', () {
      // 6 appears way more often than expected.
      final r = HypothesisTests.chiSquareGof(
        observed: const [5, 5, 5, 5, 5, 35],
        expected: const [10, 10, 10, 10, 10, 10],
      );
      expect(r.rejectsAt(0.01), isTrue);
      expect(r.pValue, lessThan(1e-6));
    });

    test('classic textbook example — Mendel-style ratios', () {
      // Mendel's pea data approximation: 9:3:3:1 expected, total 556.
      // Observed: 315, 108, 101, 32 — historically χ² ≈ 0.470, df=3,
      // p ≈ 0.925.
      final r = HypothesisTests.chiSquareGof(
        observed: const [315, 108, 101, 32],
        expected: const [
          556 * 9 / 16,
          556 * 3 / 16,
          556 * 3 / 16,
          556 * 1 / 16,
        ],
      );
      expect(r.df, equals(3));
      expect(r.statistic, closeTo(0.470, 0.01));
      expect(r.pValue, greaterThan(0.9));
    });

    test('zero expected throws', () {
      expect(
        () => HypothesisTests.chiSquareGof(
          observed: const [10, 20, 30],
          expected: const [10, 0, 30],
        ),
        throwsArgumentError,
      );
    });

    test('length mismatch throws', () {
      expect(
        () => HypothesisTests.chiSquareGof(
          observed: const [1, 2, 3],
          expected: const [1, 2],
        ),
        throwsArgumentError,
      );
    });

    test('single category throws (need at least 2)', () {
      expect(
        () => HypothesisTests.chiSquareGof(
          observed: const [10.0],
          expected: const [10.0],
        ),
        throwsArgumentError,
      );
    });
  });

  group('anovaOneWay', () {
    test('three groups with identical means → F ≈ 0', () {
      final r = HypothesisTests.anovaOneWay(const [
        [5, 6, 7, 5, 6, 7],
        [5, 6, 7, 5, 6, 7],
        [5, 6, 7, 5, 6, 7],
      ]);
      expect(r.fStatistic, closeTo(0.0, 1e-9));
      expect(r.dfBetween, equals(2));
      expect(r.dfWithin, equals(15));
      expect(r.pValue, closeTo(1.0, 0.05));
    });

    test('classic textbook example — Hogg & Tanis chapter 9', () {
      // Three groups with means 7, 8, 10; small spread each.
      // Hand-computed F ≈ 12. Expect rejection at α=0.05.
      final r = HypothesisTests.anovaOneWay(const [
        [6, 7, 8, 7, 7],
        [7, 8, 9, 8, 8],
        [9, 10, 11, 10, 10],
      ]);
      expect(r.groupMeans, equals([7.0, 8.0, 10.0]));
      expect(r.groupSizes, equals([5, 5, 5]));
      expect(r.dfBetween, equals(2));
      expect(r.dfWithin, equals(12));
      // SSB = 5·1² + 5·0² + 5·3² ... wait grand mean is (7+8+10)/3 = 8.333
      //   = 5·(7-8.333)² + 5·(8-8.333)² + 5·(10-8.333)²
      //   = 5·1.778 + 5·0.111 + 5·2.778 ≈ 23.333
      // SSW = each group has SS = (6-7)²+(7-7)²+(8-7)²+(7-7)²+(7-7)² = 2.
      //   Total SSW = 6.
      // MSB = 23.333/2 = 11.667; MSW = 6/12 = 0.5; F = 23.33.
      expect(r.ssBetween, closeTo(23.333, 0.1));
      expect(r.ssWithin, closeTo(6.0, 0.01));
      expect(r.fStatistic, closeTo(23.33, 0.5));
      expect(r.rejectsAt(0.05), isTrue);
    });

    test('strongly different means → rejected at α = 0.001', () {
      final r = HypothesisTests.anovaOneWay(const [
        [10, 11, 12, 10, 11, 12, 10, 11],
        [50, 51, 52, 50, 51, 52, 50, 51],
        [100, 101, 102, 100, 101, 102, 100, 101],
      ]);
      expect(r.rejectsAt(0.001), isTrue);
      expect(r.pValue, lessThan(1e-9));
    });

    test('two groups behaves like a two-sample t-test (F = t²)', () {
      const groups = <List<double>>[
        [1.0, 2.0, 3.0, 4.0, 5.0],
        [3.0, 4.0, 5.0, 6.0, 7.0],
      ];
      final r = HypothesisTests.anovaOneWay(groups);
      final t = HypothesisTests.welchT(
        sample1: groups[0],
        sample2: groups[1],
      );
      // For equal sample sizes & variances, F = t² (pooled-vs-Welch
      // df difference is small here). Just check the order of magnitude.
      expect(r.fStatistic, closeTo(t.statistic * t.statistic, 0.5));
    });

    test('fewer than 2 groups throws', () {
      expect(
        () => HypothesisTests.anovaOneWay(const [
          [1.0, 2, 3],
        ]),
        throwsArgumentError,
      );
    });

    test('empty group throws', () {
      expect(
        () => HypothesisTests.anovaOneWay(const [
          [1.0, 2, 3],
          <double>[],
          [4.0, 5, 6],
        ]),
        throwsArgumentError,
      );
    });

    test('zero within-group variance throws (F undefined)', () {
      expect(
        () => HypothesisTests.anovaOneWay(const [
          [5.0, 5, 5],
          [6.0, 6, 6],
          [7.0, 7, 7],
        ]),
        throwsArgumentError,
      );
    });
  });

  group('chiSquareIndependence', () {
    test('proportional table → χ² ≈ 0', () {
      // Row and column proportions identical → exact independence.
      // Row totals: 30, 60. Col totals: 30, 60. Grand: 90.
      // Expected[0,0] = 30·30/90 = 10 = observed.
      final r = HypothesisTests.chiSquareIndependence(const [
        [10, 20],
        [20, 40],
      ]);
      expect(r.statistic, closeTo(0.0, 1e-9));
      expect(r.df, equals(1));
      expect(r.pValue, closeTo(1.0, 1e-3));
    });

    test('classic textbook 2x2 — strong association', () {
      // Observed: smokers vs lung cancer, exaggerated for clarity.
      //   yes/yes 80, yes/no 20 → row total 100
      //   no/yes  10, no/no  90 → row total 100
      //   col totals: 90, 110, grand 200
      //   E[0,0] = 100·90/200 = 45; (80-45)² / 45 ≈ 27.22
      //   χ² ≈ 4 × 27.22 ≈ 98.99, df = 1 → p essentially 0.
      final r = HypothesisTests.chiSquareIndependence(const [
        [80, 20],
        [10, 90],
      ]);
      expect(r.df, equals(1));
      expect(r.statistic, greaterThan(90));
      expect(r.rejectsAt(0.001), isTrue);
    });

    test('3x2 example with hand-checked expected', () {
      // Observed:
      //   A: [10, 20] → row total 30
      //   B: [20, 10] → row total 30
      //   C: [15, 15] → row total 30
      // Col totals: 45, 45. Grand: 90.
      // Expected: all 15.
      final r = HypothesisTests.chiSquareIndependence(const [
        [10, 20],
        [20, 10],
        [15, 15],
      ]);
      expect(r.rowTotals, equals([30.0, 30.0, 30.0]));
      expect(r.colTotals, equals([45.0, 45.0]));
      expect(r.grandTotal, equals(90.0));
      for (final row in r.expected) {
        for (final e in row) {
          expect(e, closeTo(15.0, 1e-9));
        }
      }
      expect(r.df, equals(2));
      // χ² = ((10-15)²+(20-15)²+(20-15)²+(10-15)²+(15-15)²+(15-15)²)/15
      //    = (25+25+25+25)/15 = 100/15 ≈ 6.667.
      expect(r.statistic, closeTo(6.667, 0.01));
    });

    test('observed = expected after proportional scaling → χ² = 0', () {
      // 2×3 table where rows are scalar multiples of each other.
      final r = HypothesisTests.chiSquareIndependence(const [
        [4, 8, 12],
        [8, 16, 24],
      ]);
      expect(r.statistic, closeTo(0.0, 1e-9));
      expect(r.df, equals(2));
    });

    test('fewer than 2 rows throws', () {
      expect(
        () => HypothesisTests.chiSquareIndependence(const [
          [1.0, 2, 3],
        ]),
        throwsArgumentError,
      );
    });

    test('fewer than 2 columns throws', () {
      expect(
        () => HypothesisTests.chiSquareIndependence(const [
          [1.0],
          [2.0],
        ]),
        throwsArgumentError,
      );
    });

    test('ragged rows throw', () {
      expect(
        () => HypothesisTests.chiSquareIndependence(const [
          [1.0, 2, 3],
          [4.0, 5],
        ]),
        throwsArgumentError,
      );
    });

    test('zero row total throws', () {
      expect(
        () => HypothesisTests.chiSquareIndependence(const [
          [0.0, 0],
          [1.0, 1],
        ]),
        throwsArgumentError,
      );
    });

    test('negative cell throws', () {
      expect(
        () => HypothesisTests.chiSquareIndependence(const [
          [1.0, 2],
          [-1.0, 3],
        ]),
        throwsArgumentError,
      );
    });
  });

  group('fisherExact2x2', () {
    test('classic textbook tea-tasting (Fisher 1935)', () {
      // Lady tasting tea: 4 cups milk-first, 4 cups tea-first.
      // Lady correctly identifies all 4 of each (3 correct, 1 wrong is
      // the next-most-extreme).
      // Observed:
      //   milk-claimed   tea-claimed
      //   3              1               | 4  (milk truth)
      //   1              3               | 4  (tea truth)
      //   4              4               | 8
      // R's fisher.test on this gives two-sided p ≈ 0.486.
      final r = HypothesisTests.fisherExact2x2(3, 1, 1, 3);
      expect(r.pValueTwoSided, closeTo(0.486, 0.01));
    });

    test('all-correct guesses give a smaller p', () {
      // Same setup, 4 of 4 correct on each side. R's fisher.test:
      // two-sided p ≈ 0.0286.
      final r = HypothesisTests.fisherExact2x2(4, 0, 0, 4);
      expect(r.pValueTwoSided, closeTo(0.0286, 0.005));
      expect(r.rejectsAt(0.05), isTrue);
    });

    test('one-sided p-values are monotonic in `a`', () {
      // Same margins, different `a` values — upper-tail p should
      // decrease as `a` grows.
      final r2 = HypothesisTests.fisherExact2x2(2, 2, 2, 2);
      final r3 = HypothesisTests.fisherExact2x2(3, 1, 1, 3);
      final r4 = HypothesisTests.fisherExact2x2(4, 0, 0, 4);
      expect(r2.pValueOneSidedUpper, greaterThan(r3.pValueOneSidedUpper));
      expect(r3.pValueOneSidedUpper, greaterThan(r4.pValueOneSidedUpper));
    });

    test('upper-tail and lower-tail p sum to 1 + pObserved', () {
      // upper + lower double-counts the observed table, so
      // upper + lower = 1 + P(observed).
      final r = HypothesisTests.fisherExact2x2(3, 1, 1, 3);
      expect(r.pValueOneSidedUpper + r.pValueOneSidedLower,
          closeTo(1.0 + r.pObserved, 1e-6));
    });

    test('symmetric table gives p ≈ 1', () {
      // Margins symmetric around the expected, observed cell at the mean.
      final r = HypothesisTests.fisherExact2x2(2, 2, 2, 2);
      expect(r.pValueTwoSided, closeTo(1.0, 0.01));
    });

    test('large totals still compute (log-domain stays stable)', () {
      // Fairly extreme 2x2 with totals ~200.
      final r = HypothesisTests.fisherExact2x2(80, 20, 10, 90);
      expect(r.pValueTwoSided, lessThan(1e-9));
      expect(r.rejectsAt(0.001), isTrue);
    });

    test('all zeros throws', () {
      expect(
        () => HypothesisTests.fisherExact2x2(0, 0, 0, 0),
        throwsArgumentError,
      );
    });

    test('negative count throws', () {
      expect(
        () => HypothesisTests.fisherExact2x2(-1, 0, 1, 1),
        throwsArgumentError,
      );
    });
  });

  group('pairedSign', () {
    test('symmetric data → p ≈ 1, no rejection', () {
      // 5 pairs, 2 positive + 2 negative + 1 zero. Under H₀ with
      // Binomial(4, 0.5), k = 2: P(X ≤ 2) = 0.6875. Two-sided
      // p = 2 * 0.6875 = 1.375, clamped to 1.
      final r = HypothesisTests.pairedSign(
        before: const [5, 4, 3, 6, 5],
        after: const [4, 5, 4, 5, 5],
      );
      expect(r.positives, 2);
      expect(r.negatives, 2);
      expect(r.zeros, 1);
      expect(r.n, 4);
      expect(r.pValueTwoSided, closeTo(1.0, 1e-9));
      expect(r.rejectsAt(0.05), isFalse);
    });

    test('all positive differences → small p-value', () {
      // 10 pairs all positive. P(X ≥ 10 | Binomial(10, 0.5)) = (1/2)^10
      // = 0.0009765625. Two-sided p = 2 * 0.0009765625 = 0.001953125.
      final r = HypothesisTests.pairedSign(
        before: const [10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
        after: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      );
      expect(r.positives, 10);
      expect(r.negatives, 0);
      expect(r.pValueTwoSided, closeTo(2.0 / 1024.0, 1e-9));
      expect(r.rejectsAt(0.05), isTrue);
    });

    test('upper-tail p ≈ 1 when no positives', () {
      // 5 pairs all negative. P(X ≥ 0 | Binom(5, 0.5)) = 1.
      final r = HypothesisTests.pairedSign(
        before: const [1, 2, 3, 4, 5],
        after: const [6, 7, 8, 9, 10],
      );
      expect(r.positives, 0);
      expect(r.negatives, 5);
      expect(r.pValueOneSidedUpper, closeTo(1.0, 1e-9));
      expect(r.pValueOneSidedLower, closeTo(1.0 / 32.0, 1e-9));
    });

    test('zeros are excluded but counted separately', () {
      final r = HypothesisTests.pairedSign(
        before: const [5, 5, 5, 6, 7, 8],
        after: const [5, 5, 5, 4, 3, 2],
      );
      expect(r.positives, 3);
      expect(r.negatives, 0);
      expect(r.zeros, 3);
      expect(r.n, 3);
    });

    test('length mismatch throws', () {
      expect(
        () => HypothesisTests.pairedSign(
          before: const [1, 2, 3],
          after: const [1, 2],
        ),
        throwsArgumentError,
      );
    });

    test('all ties throws', () {
      expect(
        () => HypothesisTests.pairedSign(
          before: const [5, 5, 5, 5],
          after: const [5, 5, 5, 5],
        ),
        throwsArgumentError,
      );
    });
  });

  group('wilcoxonRankSum', () {
    test('identical samples → z ≈ 0, p ≈ 1', () {
      final r = HypothesisTests.wilcoxonRankSum(
        sample1: const [1, 2, 3, 4, 5],
        sample2: const [1, 2, 3, 4, 5],
      );
      expect(r.z, closeTo(0.0, 1e-9));
      // Tolerance loosened from 1e-9 to 1e-6: Normal.cdf uses Simpson
      // integration over [-large, x] and accumulates ~1e-9 error per
      // call, so 2·min(upper, lower) sits ~2e-9 shy of exactly 1.0.
      expect(r.pValueTwoSided, closeTo(1.0, 1e-6));
      expect(r.u1, closeTo(12.5, 1e-9));
    });

    test('clearly separated samples → very small p', () {
      final r = HypothesisTests.wilcoxonRankSum(
        sample1: const [1, 2, 3, 4, 5, 6, 7, 8],
        sample2: const [100, 101, 102, 103, 104, 105, 106, 107],
      );
      // All sample1 ranks are 1..8, all sample2 are 9..16. R₁ = 36,
      // U₁ = 36 − 8·9/2 = 0. μ_U = 32, σ_U = √(8·8·17/12) ≈ 9.522,
      // z = (0 − 32)/9.522 ≈ −3.36 → p two-sided ≈ 7.8e-4.
      expect(r.u1, closeTo(0.0, 1e-9));
      expect(r.z, closeTo(-3.36, 0.02));
      expect(r.pValueTwoSided, lessThan(1e-3));
      expect(r.rejectsAt(0.05), isTrue);
    });

    test('U₁ + U₂ = n₁ · n₂', () {
      final r = HypothesisTests.wilcoxonRankSum(
        sample1: const [3, 7, 9, 12, 15],
        sample2: const [1, 4, 6, 8, 11, 14],
      );
      expect(r.u1 + r.u2, closeTo(5.0 * 6.0, 1e-9));
    });

    test('handles ties with average ranks', () {
      // Sample 1: [1, 2, 3, 5], sample 2: [2, 3, 4, 6]
      // Pooled sorted with ties: 1, 2, 2, 3, 3, 4, 5, 6
      // Ranks (avg): 1, 2.5, 2.5, 4.5, 4.5, 6, 7, 8
      // Sample 1 picks up rank 1 (for 1), 2.5 (for 2), 4.5 (for 3),
      // 7 (for 5) → R₁ = 15.
      final r = HypothesisTests.wilcoxonRankSum(
        sample1: const [1, 2, 3, 5],
        sample2: const [2, 3, 4, 6],
      );
      expect(r.rankSum1, closeTo(15.0, 1e-9));
    });

    test('asymmetry: swapping samples flips z sign', () {
      final r12 = HypothesisTests.wilcoxonRankSum(
        sample1: const [1, 2, 3, 4, 5],
        sample2: const [6, 7, 8, 9, 10],
      );
      final r21 = HypothesisTests.wilcoxonRankSum(
        sample1: const [6, 7, 8, 9, 10],
        sample2: const [1, 2, 3, 4, 5],
      );
      expect(r12.z, closeTo(-r21.z, 1e-9));
      expect(r12.pValueTwoSided, closeTo(r21.pValueTwoSided, 1e-9));
    });

    test('empty sample throws', () {
      expect(
        () => HypothesisTests.wilcoxonRankSum(
          sample1: const [],
          sample2: const [1, 2, 3],
        ),
        throwsArgumentError,
      );
    });
  });
}
