// lib/engine/plane_math.dart
//
// Pure-math helpers for 3D plane analysis. No Flutter imports — exists so we
// can drive these from the analysis screen UI *and* exercise them in unit
// tests without spinning up a widget tree.

import 'dart:math' as math;

class Vector3 {
  final double x, y, z;
  const Vector3(this.x, this.y, this.z);
  Vector3 cross(Vector3 o) => Vector3(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );
  double dot(Vector3 o) => x * o.x + y * o.y + z * o.z;
  double get length => math.sqrt(x * x + y * y + z * z);
  Vector3 normalized() {
    final n = length;
    if (n == 0) return const Vector3(0, 0, 0);
    return Vector3(x / n, y / n, z / n);
  }

  @override
  String toString() => '($x, $y, $z)';

  @override
  bool operator ==(Object other) =>
      other is Vector3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);
}

/// Result of analyzing a plane.
class PlaneAnalysis {
  /// `a x + b y + c z = d`
  final double a, b, c, d;

  /// A point on the plane.
  final Vector3 pointOnPlane;

  /// Unit normal (or zero if the plane is degenerate).
  final Vector3 unitNormal;

  /// Signed distance from the origin along the unit normal.
  final double signedDistanceFromOrigin;

  /// x/y/z intercepts. `null` when the plane is parallel to that axis.
  final Vector3? xIntercept;
  final Vector3? yIntercept;
  final Vector3? zIntercept;

  /// Optional error message — null means everything's fine.
  final String? error;

  const PlaneAnalysis({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.pointOnPlane,
    required this.unitNormal,
    required this.signedDistanceFromOrigin,
    required this.xIntercept,
    required this.yIntercept,
    required this.zIntercept,
    this.error,
  });

  bool get isValid => error == null;
}

/// Builds a `PlaneAnalysis` from coordinate form `a x + b y + c z = d`.
PlaneAnalysis analyzePlaneFromCoordinate(
    double a, double b, double c, double d) {
  if (a == 0 && b == 0 && c == 0) {
    return PlaneAnalysis(
      a: a,
      b: b,
      c: c,
      d: d,
      pointOnPlane: const Vector3(0, 0, 0),
      unitNormal: const Vector3(0, 0, 0),
      signedDistanceFromOrigin: 0,
      xIntercept: null,
      yIntercept: null,
      zIntercept: null,
      error: 'Normal vector (a, b, c) must be non-zero.',
    );
  }
  final norm = math.sqrt(a * a + b * b + c * c);
  final unitN = Vector3(a / norm, b / norm, c / norm);
  // Point on plane: pick the axis where the coefficient is non-zero.
  Vector3 point;
  if (a != 0) {
    point = Vector3(d / a, 0, 0);
  } else if (b != 0) {
    point = Vector3(0, d / b, 0);
  } else {
    point = Vector3(0, 0, d / c);
  }
  return PlaneAnalysis(
    a: a,
    b: b,
    c: c,
    d: d,
    pointOnPlane: point,
    unitNormal: unitN,
    signedDistanceFromOrigin: -d / norm,
    xIntercept: a != 0 ? Vector3(d / a, 0, 0) : null,
    yIntercept: b != 0 ? Vector3(0, d / b, 0) : null,
    zIntercept: c != 0 ? Vector3(0, 0, d / c) : null,
  );
}

/// Builds a `PlaneAnalysis` from parametric form `point + s·u + t·v`.
PlaneAnalysis analyzePlaneFromParametric(Vector3 point, Vector3 u, Vector3 v) {
  final n = u.cross(v);
  if (n.x == 0 && n.y == 0 && n.z == 0) {
    return PlaneAnalysis(
      a: 0,
      b: 0,
      c: 0,
      d: 0,
      pointOnPlane: point,
      unitNormal: const Vector3(0, 0, 0),
      signedDistanceFromOrigin: 0,
      xIntercept: null,
      yIntercept: null,
      zIntercept: null,
      error: 'Direction vectors are parallel — they do not span a plane.',
    );
  }
  final d = n.dot(point);
  return analyzePlaneFromCoordinate(n.x, n.y, n.z, d);
}
