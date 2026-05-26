// P9-A4: pairwise intersection algorithms for the 3D Scene module.
//
// Closed-form math for every plane / line / sphere pair. The
// dispatcher returns a sealed [Intersection] result that the UI
// can both render (highlight the geometry in the viewport) and
// describe (analytical answer in the results panel).
//
// All math is pure-Dart, no Flutter or SymEngine imports — exists
// so we can unit-test every pair without a widget tree.
//
// Tolerance: numerical comparisons use [_eps] (default 1e-9).
// Tighter than this would catch genuine geometry as "almost
// parallel"; looser would miss real near-misses.

import 'dart:math' as math;

import '../conic_math.dart' show ConicKind, analyzeConic;
import '../plane_math.dart' show Vector3;
import 'scene_object.dart';

const double _eps = 1e-9;

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

/// Sealed result of intersecting two [SceneObject]s. The painter
/// dispatches on this to draw highlight geometry; the results panel
/// dispatches on it to render the analytical description.
sealed class Intersection {
  /// Stable key for localized messaging. The UI maps this to a
  /// human-readable string via `AppLocalizations.intersectionReason*`.
  String get reasonKey;
}

/// Objects do not intersect (parallel, missed sphere, etc.).
class NoIntersection extends Intersection {
  @override
  final String reasonKey;
  NoIntersection(this.reasonKey);
}

/// Objects intersect at a single point.
class PointIntersection extends Intersection {
  final Vector3 point;
  PointIntersection(this.point);
  @override
  String get reasonKey => 'point';
}

/// Objects intersect along a line (parametric form
/// `point + t · direction`).
class LineIntersection extends Intersection {
  final Vector3 point;
  final Vector3 direction;
  LineIntersection(this.point, this.direction);
  @override
  String get reasonKey => 'line';
}

/// Plane × sphere or sphere × sphere → a 3D circle.
class CircleIntersection extends Intersection {
  final Vector3 center;
  final Vector3 normal;
  final double radius;
  CircleIntersection(this.center, this.normal, this.radius);
  @override
  String get reasonKey => 'circle';
}

/// Line × sphere typically gives 0 / 1 / 2 points. This is the
/// 2-point case; the tangent / miss cases use [PointIntersection] /
/// [NoIntersection].
class TwoPointsIntersection extends Intersection {
  final Vector3 a;
  final Vector3 b;
  TwoPointsIntersection(this.a, this.b);
  @override
  String get reasonKey => 'twoPoints';
}

/// Objects are geometrically identical (e.g. same line, two equal
/// spheres). The renderer skips drawing a separate highlight in
/// this case; the panel says so.
class CoincidentIntersection extends Intersection {
  @override
  final String reasonKey;
  CoincidentIntersection(this.reasonKey);
}

/// One object lies entirely inside the other (e.g. line lies in
/// plane). Like [CoincidentIntersection] there's no separate
/// geometry to highlight — the contained object IS the
/// intersection.
class ContainedIntersection extends Intersection {
  @override
  final String reasonKey;
  ContainedIntersection(this.reasonKey);
}

/// P9-A5b: plane × quadric. Result is a 2D conic curve sitting
/// in the cutting plane. The 6 coefficients
/// `As² + Bst + Ct² + Ds + Et + F = 0` describe the curve in the
/// plane's local frame `x = origin + s·u + t·v`. The plane's
/// frame is carried alongside so the painter can render the
/// curve back in 3D.
class ConicSectionIntersection extends Intersection {
  final Vector3 origin;
  final Vector3 u;
  final Vector3 v;
  final double cA, cB, cC, cD, cE, cF;

  /// Classification from the existing [analyzeConic] pipeline so
  /// the panel can render "Ellipse" / "Parabola" / "Hyperbola"
  /// / "Circle" without re-classifying.
  final ConicKind conicKind;

  ConicSectionIntersection({
    required this.origin,
    required this.u,
    required this.v,
    required this.cA,
    required this.cB,
    required this.cC,
    required this.cD,
    required this.cE,
    required this.cF,
    required this.conicKind,
  });

  /// Evaluate the implicit conic at plane-local (s, t). Zero means
  /// the point lies on the curve.
  double evaluate(double s, double t) =>
      cA * s * s + cB * s * t + cC * t * t + cD * s + cE * t + cF;

  /// Map a plane-local (s, t) back to a 3D world coordinate via
  /// `origin + s·u + t·v`.
  Vector3 worldAt(double s, double t) => Vector3(
        origin.x + s * u.x + t * v.x,
        origin.y + s * u.y + t * v.y,
        origin.z + s * u.z + t * v.z,
      );

  @override
  String get reasonKey {
    switch (conicKind) {
      case ConicKind.circle:
        return 'circle';
      case ConicKind.ellipse:
        return 'ellipse';
      case ConicKind.parabola:
        return 'parabola';
      case ConicKind.hyperbola:
        return 'hyperbola';
      case ConicKind.degenerate:
        return 'degenerateConic';
      case ConicKind.notAConic:
        return 'noConic';
    }
  }
}

// ---------------------------------------------------------------------------
// Dispatcher
// ---------------------------------------------------------------------------

/// Pairwise intersection. Returns `null` when the pair isn't
/// supported (quadrics / parametrics in V1); the caller should
/// hide such pairs from the results panel.
Intersection? intersect(SceneObject a, SceneObject b) {
  // Sort by kind index so each pair has a canonical orientation.
  // Plane < Line < Sphere via the enum declaration order.
  final pair = (a, b);
  switch (pair) {
    case (PlaneObject p1, PlaneObject p2):
      return _planePlane(p1, p2);
    case (PlaneObject p, LineObject l):
    case (LineObject l, PlaneObject p):
      return _planeLine(p, l);
    case (PlaneObject p, SphereObject s):
    case (SphereObject s, PlaneObject p):
      return _planeSphere(p, s);
    case (LineObject l1, LineObject l2):
      return _lineLine(l1, l2);
    case (LineObject l, SphereObject s):
    case (SphereObject s, LineObject l):
      return _lineSphere(l, s);
    case (SphereObject s1, SphereObject s2):
      return _sphereSphere(s1, s2);
    case (PlaneObject p, QuadricObject q):
    case (QuadricObject q, PlaneObject p):
      return _planeQuadric(p, q);
    default:
      return null;
  }
}

// ---------------------------------------------------------------------------
// Plane × plane
// ---------------------------------------------------------------------------

Intersection _planePlane(PlaneObject p1, PlaneObject p2) {
  final n1 = p1.normal;
  final n2 = p2.normal;
  final dir = n1.cross(n2);
  final dirLen2 = dir.dot(dir);
  if (dirLen2 < _eps) {
    // Normals parallel — planes are parallel. Are they coincident?
    // Pick a point on p1 and check if it sits on p2.
    final pointOnP1 = _pointOnPlane(p1);
    final sig = n2.dot(pointOnP1) - p2.d;
    if (sig.abs() < _eps) {
      return CoincidentIntersection('coincidentPlanes');
    }
    return NoIntersection('parallelPlanes');
  }
  // Find a point on the line. The line satisfies n1·x = d1 and
  // n2·x = d2. We need any solution. The classic trick: write
  //   x = a·n1 + b·n2 + t·dir
  // and solve for (a, b) by substituting back. dir·n1 = dir·n2 = 0,
  // so the system collapses to:
  //   a · |n1|² + b · (n1·n2) = d1
  //   a · (n1·n2) + b · |n2|² = d2
  final n1n1 = n1.dot(n1);
  final n2n2 = n2.dot(n2);
  final n1n2 = n1.dot(n2);
  final det = n1n1 * n2n2 - n1n2 * n1n2;
  if (det.abs() < _eps) {
    // Should not happen when normals are non-parallel — defensive.
    return NoIntersection('numericalFailure');
  }
  final a = (p1.d * n2n2 - p2.d * n1n2) / det;
  final b = (p2.d * n1n1 - p1.d * n1n2) / det;
  final pointOnLine = Vector3(
    a * n1.x + b * n2.x,
    a * n1.y + b * n2.y,
    a * n1.z + b * n2.z,
  );
  return LineIntersection(pointOnLine, dir);
}

// ---------------------------------------------------------------------------
// Plane × line
// ---------------------------------------------------------------------------

Intersection _planeLine(PlaneObject p, LineObject l) {
  final n = p.normal;
  final nDotD = n.dot(l.direction);
  final nDotP = n.dot(l.point);
  if (nDotD.abs() < _eps) {
    // Line direction perpendicular to normal — parallel to plane.
    if ((nDotP - p.d).abs() < _eps) {
      return ContainedIntersection('lineInPlane');
    }
    return NoIntersection('lineParallelToPlane');
  }
  final t = (p.d - nDotP) / nDotD;
  return PointIntersection(Vector3(
    l.point.x + t * l.direction.x,
    l.point.y + t * l.direction.y,
    l.point.z + t * l.direction.z,
  ));
}

// ---------------------------------------------------------------------------
// Plane × sphere
// ---------------------------------------------------------------------------

Intersection _planeSphere(PlaneObject p, SphereObject s) {
  final n = p.normal;
  final nLen = math.sqrt(n.dot(n));
  if (nLen < _eps) return NoIntersection('degeneratePlane');
  // Signed distance from sphere center to plane.
  final signedDist = (n.dot(s.center) - p.d) / nLen;
  final absDist = signedDist.abs();
  if (absDist > s.radius + _eps) {
    return NoIntersection('sphereMissesPlane');
  }
  // Project the center onto the plane to get the circle's center.
  final scale = signedDist / nLen;
  final circleCenter = Vector3(
    s.center.x - scale * n.x,
    s.center.y - scale * n.y,
    s.center.z - scale * n.z,
  );
  final unitN = Vector3(n.x / nLen, n.y / nLen, n.z / nLen);
  if ((absDist - s.radius).abs() < _eps) {
    // Tangent — touch at one point (which sits at the projected
    // center).
    return PointIntersection(circleCenter);
  }
  final circleR = math.sqrt(s.radius * s.radius - absDist * absDist);
  return CircleIntersection(circleCenter, unitN, circleR);
}

// ---------------------------------------------------------------------------
// Line × line
// ---------------------------------------------------------------------------

Intersection _lineLine(LineObject l1, LineObject l2) {
  // Closest pair of points on two parametric lines:
  // line1(s) = p1 + s·d1, line2(t) = p2 + t·d2.
  // The closest pair satisfies:
  //   d1·(line1(s) - line2(t)) = 0
  //   d2·(line1(s) - line2(t)) = 0
  // Solve the 2×2 system.
  final p1 = l1.point;
  final d1 = l1.direction;
  final p2 = l2.point;
  final d2 = l2.direction;
  final r = Vector3(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z);

  final a = d1.dot(d1);
  final b = d1.dot(d2);
  final c = d2.dot(d2);
  final d = d1.dot(r);
  final e = d2.dot(r);

  final denom = a * c - b * b;
  if (denom.abs() < _eps) {
    // Lines are parallel. Coincident if r is itself parallel to d1.
    final cross = d1.cross(r);
    if (cross.dot(cross) < _eps) {
      return CoincidentIntersection('coincidentLines');
    }
    return NoIntersection('parallelLines');
  }
  final s = (b * e - c * d) / denom;
  final t = (a * e - b * d) / denom;

  final closest1 = Vector3(
    p1.x + s * d1.x,
    p1.y + s * d1.y,
    p1.z + s * d1.z,
  );
  final closest2 = Vector3(
    p2.x + t * d2.x,
    p2.y + t * d2.y,
    p2.z + t * d2.z,
  );
  final gap = Vector3(
    closest1.x - closest2.x,
    closest1.y - closest2.y,
    closest1.z - closest2.z,
  );
  if (gap.dot(gap) < _eps) {
    // Same point — true intersection.
    return PointIntersection(closest1);
  }
  return NoIntersection('skewLines');
}

// ---------------------------------------------------------------------------
// Line × sphere
// ---------------------------------------------------------------------------

Intersection _lineSphere(LineObject l, SphereObject s) {
  // Substitute line(t) = p + t·d into |x - c|² = r²:
  //   |p + t·d - c|² = r²
  // Expand to a quadratic in t: A·t² + B·t + C = 0
  // with A = |d|², B = 2·d·(p - c), C = |p - c|² - r².
  final pc = Vector3(
    l.point.x - s.center.x,
    l.point.y - s.center.y,
    l.point.z - s.center.z,
  );
  final A = l.direction.dot(l.direction);
  if (A < _eps) return NoIntersection('degenerateLine');
  final B = 2 * l.direction.dot(pc);
  final C = pc.dot(pc) - s.radius * s.radius;
  final disc = B * B - 4 * A * C;
  if (disc < -_eps) {
    return NoIntersection('lineMissesSphere');
  }
  if (disc.abs() < _eps) {
    // Tangent.
    final t = -B / (2 * A);
    return PointIntersection(Vector3(
      l.point.x + t * l.direction.x,
      l.point.y + t * l.direction.y,
      l.point.z + t * l.direction.z,
    ));
  }
  final sq = math.sqrt(disc);
  final t1 = (-B - sq) / (2 * A);
  final t2 = (-B + sq) / (2 * A);
  final pt1 = Vector3(
    l.point.x + t1 * l.direction.x,
    l.point.y + t1 * l.direction.y,
    l.point.z + t1 * l.direction.z,
  );
  final pt2 = Vector3(
    l.point.x + t2 * l.direction.x,
    l.point.y + t2 * l.direction.y,
    l.point.z + t2 * l.direction.z,
  );
  return TwoPointsIntersection(pt1, pt2);
}

// ---------------------------------------------------------------------------
// Sphere × sphere
// ---------------------------------------------------------------------------

Intersection _sphereSphere(SphereObject s1, SphereObject s2) {
  final delta = Vector3(
    s2.center.x - s1.center.x,
    s2.center.y - s1.center.y,
    s2.center.z - s1.center.z,
  );
  final dist = math.sqrt(delta.dot(delta));
  final r1 = s1.radius;
  final r2 = s2.radius;
  if (dist < _eps && (r1 - r2).abs() < _eps) {
    return CoincidentIntersection('coincidentSpheres');
  }
  final sumR = r1 + r2;
  final diffR = (r1 - r2).abs();
  if (dist > sumR + _eps) {
    return NoIntersection('spheresApart');
  }
  if (dist < diffR - _eps) {
    return NoIntersection('sphereInsideSphere');
  }
  if ((dist - sumR).abs() < _eps || (dist - diffR).abs() < _eps) {
    // External or internal tangent — single point on the axis
    // between centers.
    final t = (dist - r2 + r1) / (2 * dist) * dist; // distance from s1
    final unitDelta = Vector3(delta.x / dist, delta.y / dist, delta.z / dist);
    return PointIntersection(Vector3(
      s1.center.x + t * unitDelta.x,
      s1.center.y + t * unitDelta.y,
      s1.center.z + t * unitDelta.z,
    ));
  }
  // Two spheres meet along a circle. Distance from s1's center to
  // the circle plane = (d² + r1² − r2²) / (2·d).
  final a = (dist * dist + r1 * r1 - r2 * r2) / (2 * dist);
  final h2 = r1 * r1 - a * a;
  final h = h2 > 0 ? math.sqrt(h2) : 0.0;
  final unitDelta = Vector3(delta.x / dist, delta.y / dist, delta.z / dist);
  final circleCenter = Vector3(
    s1.center.x + a * unitDelta.x,
    s1.center.y + a * unitDelta.y,
    s1.center.z + a * unitDelta.z,
  );
  return CircleIntersection(circleCenter, unitDelta, h);
}

// ---------------------------------------------------------------------------
// Plane × quadric — produces a 2D conic in the plane's local frame
// ---------------------------------------------------------------------------

Intersection _planeQuadric(PlaneObject p, QuadricObject q) {
  // Build the quadric's symmetric matrix M (upper triangle), linear
  // vector b, and constant c so that Q(x) = xᵀ M x + bᵀ x + c.
  // Off-diagonal entries of M are half the cross-term coefficients
  // (because xᵀ M x writes 2·M[i][j] when i≠j).
  final mDiag = [q.cA, q.cB, q.cC];
  final m01 = q.cD / 2;
  final m02 = q.cE / 2;
  final m12 = q.cF / 2;
  final bx = q.cG, by = q.cH, bz = q.cI;
  final cConst = q.cJ;

  // Plane frame: pick an orthonormal (u, v) spanning the plane plus
  // the closest-to-origin point. Same approach as the painter uses
  // for plane rendering.
  final n = p.normal;
  final nLen2 = n.dot(n);
  if (nLen2 < _eps) return NoIntersection('degeneratePlane');
  final origin = Vector3(
    n.x * p.d / nLen2,
    n.y * p.d / nLen2,
    n.z * p.d / nLen2,
  );
  final seed =
      (n.x.abs() < 0.9) ? const Vector3(1, 0, 0) : const Vector3(0, 1, 0);
  final proj = seed.dot(n) / nLen2;
  final uRaw = Vector3(
    seed.x - proj * n.x,
    seed.y - proj * n.y,
    seed.z - proj * n.z,
  );
  final uLen = math.sqrt(uRaw.dot(uRaw));
  if (uLen < _eps) return NoIntersection('degeneratePlane');
  final u = Vector3(uRaw.x / uLen, uRaw.y / uLen, uRaw.z / uLen);
  final vRaw = n.cross(u);
  final vLen = math.sqrt(vRaw.dot(vRaw));
  final v = Vector3(vRaw.x / vLen, vRaw.y / vLen, vRaw.z / vLen);

  // M·w (general 3×3 symmetric matrix-vector product) for some
  // vector w. Returned as a 3-element list to keep allocations
  // minimal.
  List<double> mDotW(double wx, double wy, double wz) => [
        mDiag[0] * wx + m01 * wy + m02 * wz,
        m01 * wx + mDiag[1] * wy + m12 * wz,
        m02 * wx + m12 * wy + mDiag[2] * wz,
      ];

  // Plane-local coefficients via substitution x = origin + s·u + t·v
  // (derivation in the round 96 commit body — quick recap below):
  //   A = uᵀ M u
  //   B = 2 uᵀ M v
  //   C = vᵀ M v
  //   D = 2 uᵀ M origin + bᵀ u
  //   E = 2 vᵀ M origin + bᵀ v
  //   F = originᵀ M origin + bᵀ origin + c
  double dot3(List<double> a, double x, double y, double z) =>
      a[0] * x + a[1] * y + a[2] * z;

  final mU = mDotW(u.x, u.y, u.z);
  final mV = mDotW(v.x, v.y, v.z);
  final mO = mDotW(origin.x, origin.y, origin.z);

  final cAA = dot3(mU, u.x, u.y, u.z);
  final cBB = 2 * dot3(mU, v.x, v.y, v.z);
  final cCC = dot3(mV, v.x, v.y, v.z);
  final cDD = 2 * dot3(mU, origin.x, origin.y, origin.z) +
      (bx * u.x + by * u.y + bz * u.z);
  final cEE = 2 * dot3(mV, origin.x, origin.y, origin.z) +
      (bx * v.x + by * v.y + bz * v.z);
  final cFF = dot3(mO, origin.x, origin.y, origin.z) +
      (bx * origin.x + by * origin.y + bz * origin.z) +
      cConst;

  // Edge case: all six coefficients are ~0 → plane lies on the
  // quadric (e.g. plane tangent to a degenerate cone of revolution).
  // Treat as "contained" — painter draws nothing extra, panel
  // describes it.
  if (cAA.abs() < _eps &&
      cBB.abs() < _eps &&
      cCC.abs() < _eps &&
      cDD.abs() < _eps &&
      cEE.abs() < _eps &&
      cFF.abs() < _eps) {
    return ContainedIntersection('planeOnQuadric');
  }

  final analysis = analyzeConic(cAA, cBB, cCC, cDD, cEE, cFF);

  return ConicSectionIntersection(
    origin: origin,
    u: u,
    v: v,
    cA: cAA,
    cB: cBB,
    cC: cCC,
    cD: cDD,
    cE: cEE,
    cF: cFF,
    conicKind: analysis.kind,
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Vector3 _pointOnPlane(PlaneObject p) {
  // Use the axis with the largest absolute coefficient — same
  // approach as PlaneAnalysis.
  final ax = p.a.abs();
  final ay = p.b.abs();
  final az = p.c.abs();
  if (ax >= ay && ax >= az && ax > _eps) {
    return Vector3(p.d / p.a, 0, 0);
  }
  if (ay >= az && ay > _eps) {
    return Vector3(0, p.d / p.b, 0);
  }
  if (az > _eps) {
    return Vector3(0, 0, p.d / p.c);
  }
  return const Vector3(0, 0, 0);
}
