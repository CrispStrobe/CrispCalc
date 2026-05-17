// lib/engine/distributions.dart
//
// Closed-form probability distributions for the statistics module:
// normal (Gaussian) and binomial. Pure Dart, double precision. The
// inverse normal CDF (`quantile`) uses bisection on the CDF — slower
// than rational approximations like Acklam's but trivially correct
// and well within the precision a calculator needs (~1e-10).
//
// erf is approximated with Abramowitz & Stegun 7.1.26, max error
// 1.5e-7 — fine for student stats. The binomial PMF uses log-domain
// computations so it stays accurate at large n.

import 'dart:math' as math;

class Normal {
  final double mean;
  final double stddev;
  const Normal({this.mean = 0, this.stddev = 1});

  /// Probability density at [x]. φ(x; μ, σ) = (1/(σ√(2π))) e^(-(x-μ)²/(2σ²)).
  double pdf(double x) {
    final z = (x - mean) / stddev;
    return math.exp(-0.5 * z * z) / (stddev * math.sqrt(2 * math.pi));
  }

  /// Cumulative probability P(X ≤ x). Computed via erf:
  ///   F(x) = ½(1 + erf((x − μ) / (σ√2))).
  double cdf(double x) {
    final z = (x - mean) / (stddev * math.sqrt2);
    return 0.5 * (1 + _erf(z));
  }

  /// Inverse CDF — returns x such that cdf(x) = p. Bisection on the
  /// monotone CDF, converging to ~1e-10 in well under 100 iterations.
  /// Returns ±infinity for p at the endpoints.
  double quantile(double p) {
    if (p <= 0) return double.negativeInfinity;
    if (p >= 1) return double.infinity;
    // Bracket: mean ± 12σ covers ~38 standard deviations of safety
    // for the normal, far past anything a student will type.
    var lo = mean - 12 * stddev;
    var hi = mean + 12 * stddev;
    for (var i = 0; i < 100; i++) {
      final mid = 0.5 * (lo + hi);
      final c = cdf(mid);
      if ((hi - lo).abs() < 1e-12) return mid;
      if (c < p) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return 0.5 * (lo + hi);
  }
}

/// Standard normal shortcut (mean = 0, stddev = 1).
const Normal standardNormal = Normal();

class Binomial {
  final int n;
  final double p;
  const Binomial({required this.n, required this.p});

  /// P(X = k). Uses log-domain so it stays accurate at large n.
  double pmf(int k) {
    if (k < 0 || k > n) return 0.0;
    if (p == 0) return k == 0 ? 1.0 : 0.0;
    if (p == 1) return k == n ? 1.0 : 0.0;
    final logProb =
        _logChoose(n, k) + k * math.log(p) + (n - k) * math.log(1 - p);
    return math.exp(logProb);
  }

  /// P(X ≤ k). Sums [pmf] up to k. Fine for typical homework n; for
  /// huge n we'd want a tail series or regularized incomplete beta.
  double cdf(int k) {
    if (k < 0) return 0.0;
    if (k >= n) return 1.0;
    var s = 0.0;
    for (var i = 0; i <= k; i++) {
      s += pmf(i);
    }
    return s;
  }

  /// Mean of the distribution (n*p).
  double get mean => n * p;

  /// Variance of the distribution (n*p*(1-p)).
  double get variance => n * p * (1 - p);

  /// Standard deviation of the distribution.
  double get stddev => math.sqrt(variance);
}

/// Student's t-distribution with [df] degrees of freedom. The most
/// common hypothesis-test distribution after the normal — confidence
/// intervals on a small sample, one-sample / paired-sample t tests.
class TDistribution {
  final int df;
  const TDistribution({required this.df})
      : assert(df > 0, 'degrees of freedom must be positive');

  /// PDF: Γ((ν+1)/2) / (√(νπ) · Γ(ν/2)) · (1 + x²/ν)^(-(ν+1)/2).
  double pdf(double x) {
    final v = df.toDouble();
    final logNorm =
        _logGamma((v + 1) / 2) - 0.5 * math.log(v * math.pi) - _logGamma(v / 2);
    final logKernel = -((v + 1) / 2) * math.log(1 + x * x / v);
    return math.exp(logNorm + logKernel);
  }

  /// CDF via numerical integration of the PDF using Simpson's rule
  /// over [-large, x]. Symmetric about 0 so we exploit cdf(-x) = 1 -
  /// cdf(x). 1000 Simpson subintervals give ~6 digits of accuracy
  /// for typical df.
  double cdf(double x) {
    if (x == 0) return 0.5;
    if (x > 0) return 1.0 - cdf(-x);
    // x < 0 — integrate PDF from -∞ approximation to x.
    const lower = -50.0; // 50σ for standard normal is well past any
    // realistic input; for t with low df the tails are heavier but
    // still negligibly small below -50.
    return _simpson(pdf, lower, x, 1000);
  }

  /// Bisection on the monotone CDF. Same approach as Normal.quantile.
  double quantile(double p) {
    if (p <= 0) return double.negativeInfinity;
    if (p >= 1) return double.infinity;
    var lo = -50.0;
    var hi = 50.0;
    for (var i = 0; i < 100; i++) {
      final mid = 0.5 * (lo + hi);
      final c = cdf(mid);
      if ((hi - lo).abs() < 1e-10) return mid;
      if (c < p) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return 0.5 * (lo + hi);
  }
}

/// Chi-square distribution with [df] degrees of freedom. Used in
/// goodness-of-fit tests, variance tests, contingency tables.
/// Support is x ≥ 0. We expose PDF, CDF, quantile, mean, variance.
class ChiSquare {
  final int df;
  const ChiSquare({required this.df})
      : assert(df > 0, 'degrees of freedom must be positive');

  /// PDF: x^(k/2 − 1) · e^(−x/2) / (2^(k/2) · Γ(k/2)). Zero for x < 0.
  double pdf(double x) {
    if (x < 0) return 0.0;
    if (x == 0) return df == 2 ? 0.5 : (df == 1 ? double.infinity : 0.0);
    final k = df.toDouble();
    final logVal = (k / 2 - 1) * math.log(x) -
        x / 2 -
        (k / 2) * math.log(2) -
        _logGamma(k / 2);
    return math.exp(logVal);
  }

  /// CDF via numerical integration of the PDF on [0, x]. 1000 Simpson
  /// subintervals give ~6 digits for typical df.
  double cdf(double x) {
    if (x <= 0) return 0.0;
    return _simpson(pdf, 0, x, 1000);
  }

  /// Bisection on the monotone CDF. Upper bracket scales with df
  /// because the chi-square mean is df.
  double quantile(double p) {
    if (p <= 0) return 0.0;
    if (p >= 1) return double.infinity;
    var lo = 0.0;
    var hi = (df + 50) * 5.0; // generous: 5x mean + 5x df coverage
    for (var i = 0; i < 100; i++) {
      final mid = 0.5 * (lo + hi);
      final c = cdf(mid);
      if ((hi - lo).abs() < 1e-10) return mid;
      if (c < p) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return 0.5 * (lo + hi);
  }

  double get mean => df.toDouble();
  double get variance => 2.0 * df;
  double get stddev => math.sqrt(variance);
}

/// Snedecor's F-distribution with degrees of freedom (d1, d2). Used for
/// ANOVA, F-tests of nested models, and ratios of variances. CDF is
/// computed by Simpson on the PDF over [0, x]; the F tail is heavy at
/// low df but the integration is well-behaved past x ≈ 1.
class FDistribution {
  final int d1;
  final int d2;
  const FDistribution({required this.d1, required this.d2})
      : assert(d1 > 0, 'd1 must be positive'),
        assert(d2 > 0, 'd2 must be positive');

  /// f(x) = (Γ((d1+d2)/2) / (Γ(d1/2) Γ(d2/2))) ·
  ///        (d1/d2)^(d1/2) · x^(d1/2 - 1) / (1 + d1·x/d2)^((d1+d2)/2).
  /// Computed in log-domain to keep ratios stable.
  double pdf(double x) {
    if (x <= 0) return 0.0;
    final n1 = d1.toDouble();
    final n2 = d2.toDouble();
    final logVal = _logGamma((n1 + n2) / 2) -
        _logGamma(n1 / 2) -
        _logGamma(n2 / 2) +
        (n1 / 2) * math.log(n1 / n2) +
        (n1 / 2 - 1) * math.log(x) -
        ((n1 + n2) / 2) * math.log(1 + n1 * x / n2);
    return math.exp(logVal);
  }

  /// CDF via Simpson on the PDF, [0, x]. 1000 subintervals keep ~6
  /// digits for moderate df. Special-cases d1 = 1 via the t-distribution
  /// shortcut F(1, d2).cdf(x) = 2·t(d2).cdf(√x) − 1, because for d1 = 1
  /// the PDF has an integrable 1/√x pole at 0 that Simpson can't handle
  /// directly.
  double cdf(double x) {
    if (x <= 0) return 0.0;
    if (d1 == 1) {
      final t = TDistribution(df: d2);
      return (2 * t.cdf(math.sqrt(x)) - 1).clamp(0.0, 1.0).toDouble();
    }
    // For very large x, the upper tail is the relevant quantity and
    // 1 − cdf(x) suffers from cancellation. Route through sf() in that
    // regime: P(X ≤ x) = 1 − sf(x).
    if (x > (mean ?? 1.0) * 3) {
      return (1.0 - sf(x)).clamp(0.0, 1.0).toDouble();
    }
    return _simpson(pdf, 0, x, 1000).clamp(0.0, 1.0).toDouble();
  }

  /// Survival function (upper-tail probability) P(X > x). Uses the
  /// reciprocal-F relation: if X ~ F(d1, d2) then 1/X ~ F(d2, d1), so
  /// P(X > x) = P(1/X < 1/x) = F(d2, d1).cdf(1/x). This is far more
  /// accurate than 1 − cdf(x) deep in the upper tail, where Simpson on
  /// the original integral approaches a value indistinguishable from 1.
  double sf(double x) {
    if (x <= 0) return 1.0;
    final flipped = FDistribution(d1: d2, d2: d1);
    return flipped.cdf(1.0 / x).clamp(0.0, 1.0).toDouble();
  }

  /// Inverse CDF via bisection on the monotone CDF. Bracket adapts to
  /// the F distribution's mean (d2/(d2-2)) and tail behavior.
  double quantile(double p) {
    if (p <= 0) return 0.0;
    if (p >= 1) return double.infinity;
    var lo = 0.0;
    // F's mean is d2/(d2-2) for d2 > 2; bracket out to ~100× mean to
    // cover deep upper-tail probabilities at low df.
    final meanGuess = d2 > 2 ? d2 / (d2 - 2.0) : (d1 + d2).toDouble();
    var hi = meanGuess * 100.0;
    // Extend if cdf(hi) still < p (very heavy tail).
    while (cdf(hi) < p && hi < 1e9) {
      hi *= 10.0;
    }
    for (var i = 0; i < 100; i++) {
      final mid = 0.5 * (lo + hi);
      final c = cdf(mid);
      if ((hi - lo).abs() < 1e-10) return mid;
      if (c < p) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return 0.5 * (lo + hi);
  }

  double? get mean => d2 > 2 ? d2 / (d2 - 2.0) : null;
}

// === Internal helpers ====================================================

/// Abramowitz & Stegun 7.1.26 — max abs error 1.5e-7 for x ≥ 0.
/// Symmetric for x < 0: erf(-x) = -erf(x).
double _erf(double x) {
  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  const a1 = 0.254829592;
  const a2 = -0.284496736;
  const a3 = 1.421413741;
  const a4 = -1.453152027;
  const a5 = 1.061405429;
  const p = 0.3275911;
  final t = 1.0 / (1.0 + p * ax);
  final y = 1.0 -
      (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
  return sign * y;
}

/// log(C(n, k)) using log-gamma. Works far past plain factorials.
/// Uses the real-valued logGamma so it also accepts half-integer
/// inputs for t- and chi-square calls.
double _logChoose(int n, int k) {
  if (k < 0 || k > n) return double.negativeInfinity;
  if (k == 0 || k == n) return 0.0;
  return _logGamma(n + 1.0) - _logGamma(k + 1.0) - _logGamma((n - k) + 1.0);
}

/// Lanczos approximation to log Γ(z). Good to ~14 digits for z > 0.5;
/// uses the reflection formula for the rest. Standard textbook
/// coefficients (g = 7).
double _logGamma(double x) {
  if (x < 0.5) {
    // Reflection: Γ(z) Γ(1−z) = π / sin(πz).
    return math.log(math.pi / math.sin(math.pi * x)) - _logGamma(1.0 - x);
  }
  const c = <double>[
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];
  const g = 7;
  final z = x - 1.0;
  var a = c[0];
  for (var i = 1; i < g + 2; i++) {
    a += c[i] / (z + i);
  }
  final t = z + g + 0.5;
  return 0.5 * math.log(2 * math.pi) +
      (z + 0.5) * math.log(t) -
      t +
      math.log(a);
}

/// Composite Simpson's rule on [a, b] with [n] sub-intervals (n
/// rounded up to an even count internally). Used by the t and
/// chi-square CDFs.
double _simpson(double Function(double) f, double a, double b, int n) {
  if (n.isOdd) n += 1;
  final h = (b - a) / n;
  var s = f(a) + f(b);
  for (var i = 1; i < n; i++) {
    s += (i.isOdd ? 4 : 2) * f(a + i * h);
  }
  return s * h / 3;
}
