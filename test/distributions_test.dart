// test/distributions_test.dart
//
// Numerical correctness for the normal and binomial distributions.
// Reference values come from standard statistical tables (z-tables,
// binomial CDF tables) and known closed-form relationships.

import 'package:crisp_calc/engine/distributions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Normal — basic properties', () {
    test('PDF integrates to ~1 over [-5, 5] (Simpson)', () {
      // Simple sanity check: not a proof of normalization but catches
      // grossly wrong PDFs.
      double simpson(double Function(double) f, double a, double b, int n) {
        final h = (b - a) / n;
        var s = f(a) + f(b);
        for (var i = 1; i < n; i++) {
          s += (i.isOdd ? 4 : 2) * f(a + i * h);
        }
        return s * h / 3;
      }

      final area = simpson(standardNormal.pdf, -5, 5, 200);
      expect(area, closeTo(1.0, 1e-4));
    });

    test('PDF peaks at the mean', () {
      const n = Normal(mean: 3, stddev: 2);
      expect(n.pdf(3) > n.pdf(2), isTrue);
      expect(n.pdf(3) > n.pdf(4), isTrue);
    });

    test('PDF is symmetric around the mean', () {
      const n = Normal(mean: 5, stddev: 1.5);
      expect(n.pdf(5 - 2.3), closeTo(n.pdf(5 + 2.3), 1e-12));
    });
  });

  group('Normal — CDF', () {
    test('CDF at the mean is 0.5', () {
      expect(standardNormal.cdf(0), closeTo(0.5, 1e-6));
    });

    test('z=1 cumulative ≈ 0.8413 (textbook)', () {
      expect(standardNormal.cdf(1), closeTo(0.8413, 1e-3));
    });

    test('z=-1 ≈ 0.1587 (textbook)', () {
      expect(standardNormal.cdf(-1), closeTo(0.1587, 1e-3));
    });

    test('z=1.96 ≈ 0.975 (the 95% z-score)', () {
      expect(standardNormal.cdf(1.96), closeTo(0.975, 1e-3));
    });

    test('z=2.58 ≈ 0.995 (the 99% z-score)', () {
      expect(standardNormal.cdf(2.58), closeTo(0.995, 1e-3));
    });

    test('CDF tails approach 0 and 1', () {
      expect(standardNormal.cdf(-5), lessThan(1e-6));
      expect(standardNormal.cdf(5), greaterThan(1 - 1e-6));
    });

    test('non-standard normal CDF — N(100, 15) at 115', () {
      // 115 is 1σ above mean → ≈ 0.8413.
      const n = Normal(mean: 100, stddev: 15);
      expect(n.cdf(115), closeTo(0.8413, 1e-3));
    });
  });

  group('Normal — quantile (inverse CDF)', () {
    test('median is at 0.5', () {
      expect(standardNormal.quantile(0.5), closeTo(0.0, 1e-6));
    });

    test('quantile(0.975) ≈ 1.96', () {
      expect(standardNormal.quantile(0.975), closeTo(1.96, 1e-3));
    });

    test('quantile(0.995) ≈ 2.576', () {
      expect(standardNormal.quantile(0.995), closeTo(2.576, 1e-3));
    });

    test('quantile and CDF are inverses', () {
      for (final p in const [0.1, 0.25, 0.5, 0.75, 0.9, 0.99]) {
        final x = standardNormal.quantile(p);
        expect(standardNormal.cdf(x), closeTo(p, 1e-6), reason: 'p=$p');
      }
    });

    test('endpoints return ±infinity', () {
      expect(standardNormal.quantile(0).isNegative, isTrue);
      expect(standardNormal.quantile(0).isInfinite, isTrue);
      expect(standardNormal.quantile(1).isInfinite, isTrue);
    });

    test('non-standard normal quantile', () {
      const n = Normal(mean: 100, stddev: 15);
      expect(n.quantile(0.5), closeTo(100, 1e-6));
      // 1σ above → ~115.
      expect(n.quantile(0.8413), closeTo(115, 0.1));
    });
  });

  group('Binomial — PMF', () {
    test('coin flip P(X=k) for n=10, p=0.5', () {
      // Symmetric: PMF(0) = PMF(10) = 1/1024.
      const b = Binomial(n: 10, p: 0.5);
      expect(b.pmf(0), closeTo(1.0 / 1024.0, 1e-12));
      expect(b.pmf(10), closeTo(1.0 / 1024.0, 1e-12));
      expect(b.pmf(5), closeTo(252.0 / 1024.0, 1e-12));
    });

    test('PMFs sum to 1 over the full support', () {
      const b = Binomial(n: 12, p: 0.3);
      var s = 0.0;
      for (var k = 0; k <= 12; k++) {
        s += b.pmf(k);
      }
      expect(s, closeTo(1.0, 1e-10));
    });

    test('p=0 puts all mass at k=0', () {
      const b = Binomial(n: 5, p: 0);
      expect(b.pmf(0), closeTo(1.0, 1e-12));
      expect(b.pmf(1), closeTo(0.0, 1e-12));
    });

    test('p=1 puts all mass at k=n', () {
      const b = Binomial(n: 5, p: 1);
      expect(b.pmf(5), closeTo(1.0, 1e-12));
      expect(b.pmf(4), closeTo(0.0, 1e-12));
    });

    test('out-of-range k returns 0', () {
      const b = Binomial(n: 10, p: 0.5);
      expect(b.pmf(-1), equals(0.0));
      expect(b.pmf(11), equals(0.0));
    });
  });

  group('Binomial — CDF and moments', () {
    test('CDF at n is 1', () {
      const b = Binomial(n: 20, p: 0.4);
      expect(b.cdf(20), closeTo(1.0, 1e-10));
    });

    test('CDF below 0 is 0', () {
      const b = Binomial(n: 20, p: 0.4);
      expect(b.cdf(-1), equals(0.0));
    });

    test('CDF is monotone non-decreasing', () {
      const b = Binomial(n: 15, p: 0.6);
      var prev = -1.0;
      for (var k = -2; k <= 16; k++) {
        final c = b.cdf(k);
        expect(c, greaterThanOrEqualTo(prev));
        prev = c;
      }
    });

    test('mean = n*p', () {
      const b = Binomial(n: 100, p: 0.3);
      expect(b.mean, closeTo(30.0, 1e-12));
    });

    test('variance = n*p*(1-p)', () {
      const b = Binomial(n: 100, p: 0.3);
      expect(b.variance, closeTo(21.0, 1e-12));
    });

    test('large n PMFs are still finite (log-domain protects)', () {
      const b = Binomial(n: 200, p: 0.5);
      final pmf100 = b.pmf(100);
      expect(pmf100.isFinite, isTrue);
      expect(pmf100, greaterThan(0));
    });
  });

  group('Student t — CDF / quantile', () {
    test('t-distribution PDF peaks at 0 and is symmetric', () {
      const t = TDistribution(df: 5);
      expect(t.pdf(0) > t.pdf(1), isTrue);
      expect(t.pdf(-2), closeTo(t.pdf(2), 1e-9));
    });

    test('CDF at 0 is 0.5', () {
      const t = TDistribution(df: 10);
      expect(t.cdf(0), closeTo(0.5, 1e-4));
    });

    test('CDF tails approach 0 and 1', () {
      const t = TDistribution(df: 3);
      expect(t.cdf(-30), lessThan(0.001));
      expect(t.cdf(30), greaterThan(0.999));
    });

    test('quantile(0.975) is ~2.776 for df=4 (textbook value)', () {
      const t = TDistribution(df: 4);
      expect(t.quantile(0.975), closeTo(2.776, 1e-2));
    });

    test('quantile(0.95) is ~1.812 for df=10 (textbook value)', () {
      const t = TDistribution(df: 10);
      expect(t.quantile(0.95), closeTo(1.812, 1e-2));
    });

    test('large df approaches the standard normal', () {
      // For df=1000 the t-distribution is essentially N(0, 1).
      const t = TDistribution(df: 1000);
      expect(t.quantile(0.975), closeTo(1.96, 0.05));
    });
  });

  group('Chi-square — CDF / quantile', () {
    test('mean = df', () {
      const c = ChiSquare(df: 5);
      expect(c.mean, equals(5.0));
    });

    test('variance = 2·df', () {
      const c = ChiSquare(df: 8);
      expect(c.variance, equals(16.0));
    });

    test('CDF at 0 is 0', () {
      const c = ChiSquare(df: 4);
      expect(c.cdf(0), equals(0.0));
    });

    test('CDF tails toward 1', () {
      const c = ChiSquare(df: 4);
      expect(c.cdf(100), greaterThan(0.999));
    });

    test('quantile(0.95) ≈ 7.815 for df=3 (textbook value)', () {
      const c = ChiSquare(df: 3);
      expect(c.quantile(0.95), closeTo(7.815, 0.05));
    });

    test('quantile(0.95) ≈ 18.307 for df=10 (textbook value)', () {
      const c = ChiSquare(df: 10);
      expect(c.quantile(0.95), closeTo(18.307, 0.1));
    });

    test('quantile and CDF are inverses', () {
      const c = ChiSquare(df: 5);
      for (final p in const [0.1, 0.5, 0.9, 0.99]) {
        final x = c.quantile(p);
        expect(c.cdf(x), closeTo(p, 1e-3), reason: 'p=$p');
      }
    });
  });

  group('F-distribution — CDF / quantile', () {
    test('PDF is positive on x > 0 and zero at x = 0', () {
      const f = FDistribution(d1: 3, d2: 5);
      expect(f.pdf(0), equals(0.0));
      expect(f.pdf(0.5), greaterThan(0));
      expect(f.pdf(2.0), greaterThan(0));
    });

    test('CDF is monotone non-decreasing', () {
      const f = FDistribution(d1: 5, d2: 10);
      var prev = 0.0;
      for (final x in const [0.1, 0.5, 1.0, 2.0, 5.0, 10.0]) {
        final c = f.cdf(x);
        expect(c, greaterThanOrEqualTo(prev), reason: 'x=$x');
        prev = c;
      }
    });

    test('quantile(0.95) for F(1, 10) ≈ 4.965 (textbook value)', () {
      const f = FDistribution(d1: 1, d2: 10);
      expect(f.quantile(0.95), closeTo(4.965, 0.1));
    });

    test('quantile(0.95) for F(3, 12) ≈ 3.490', () {
      const f = FDistribution(d1: 3, d2: 12);
      expect(f.quantile(0.95), closeTo(3.490, 0.1));
    });

    test('quantile(0.99) for F(5, 20) ≈ 4.103', () {
      const f = FDistribution(d1: 5, d2: 20);
      expect(f.quantile(0.99), closeTo(4.103, 0.15));
    });

    test('mean = d2/(d2-2) for d2 > 2', () {
      expect(const FDistribution(d1: 3, d2: 10).mean, closeTo(10 / 8, 1e-9));
      expect(const FDistribution(d1: 5, d2: 2).mean, isNull);
    });

    test('CDF tails approach 1', () {
      const f = FDistribution(d1: 3, d2: 10);
      expect(f.cdf(100.0), closeTo(1.0, 0.01));
    });
  });
}
