// lib/engine/numerical.dart
//
// Pure-Dart numerical helpers extracted from CalculatorEngine so they can be
// unit tested without the SymEngine bridge.

/// Composite Simpson's rule with `n` subintervals (must be even).
/// `f` is the integrand. Returns null if any sample is non-finite.
double? simpson(double Function(double x) f, double a, double b,
    {int n = 200}) {
  if (n.isOdd) n++;
  if (a == b) return 0;
  final sign = b > a ? 1.0 : -1.0;
  final lo = a < b ? a : b;
  final hi = a < b ? b : a;
  final h = (hi - lo) / n;
  final f0 = f(lo);
  final fn = f(hi);
  if (!f0.isFinite || !fn.isFinite) return null;
  var sum = f0 + fn;
  for (var i = 1; i < n; i++) {
    final x = lo + i * h;
    final fi = f(x);
    if (!fi.isFinite) return null;
    sum += (i.isEven ? 2 : 4) * fi;
  }
  return sign * sum * h / 3.0;
}

/// One-sided numerical limit. Evaluates `f` near `point ± eps` and at a
/// tighter `eps2`. Returns the converged value or null if the two sides
/// disagree.
double? oneSidedLimit(double Function(double x) f, double point,
    {double eps = 1e-4, double eps2 = 1e-7, double tolerance = 1e-3}) {
  final l2 = f(point - eps2);
  final r2 = f(point + eps2);
  if (!l2.isFinite || !r2.isFinite) return null;
  if ((l2 - r2).abs() / (1 + l2.abs()) > tolerance) return null;
  return (l2 + r2) / 2;
}

/// Limit at +infinity. Evaluates `f` at two large positive arguments;
/// returns the converged value or null if they disagree.
double? limitAtInfinity(double Function(double x) f,
    {double tolerance = 1e-6}) {
  final a = f(1e10);
  final b = f(1e12);
  if (!a.isFinite || !b.isFinite) return null;
  if ((a - b).abs() / (1 + a.abs()) > tolerance) return null;
  return b;
}
