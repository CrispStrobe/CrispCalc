// P9-A1: pure-Dart 3D scene object model.
//
// The 3D Scene module (PLAN P9) lets the user define multiple 3D
// objects in a shared scene and compute pairwise intersections. This
// file is the engine layer: data classes only, no rendering, no
// intersection algorithms (round A4), no UI (rounds A2-A3).
//
// Coordinate system: right-handed. Vector3 is reused from
// plane_math.dart so the existing Plane Analyzer module and the new
// 3D Scene module share one vector type.

import 'dart:math';

import '../plane_math.dart' show Vector3;

/// Kinds of objects the V1 scene supports. Persisted as a string
/// discriminator in JSON; do not rename existing values.
enum SceneObjectKind {
  plane,
  line,
  sphere,
  quadric,
  parametricSurface,
  parametricCurve,
}

/// Common base type for everything that can live in a [Scene3D].
/// Subclasses carry their own geometry-specific fields. Equality is
/// structural by id (every scene object has a unique id at
/// construction time); use [equalsByGeometry] to compare values.
sealed class SceneObject {
  final String id;
  final String label;
  final SceneObjectKind kind;

  /// ARGB int (e.g. `Color(0xFFE53935).value`). Stored as int so the
  /// engine layer doesn't pull in flutter/material.
  final int color;

  /// Visibility toggle. Hidden objects participate in intersection
  /// math but aren't drawn.
  final bool visible;

  const SceneObject({
    required this.id,
    required this.label,
    required this.kind,
    required this.color,
    this.visible = true,
  });

  /// Compact JSON keyed for prefs storage. Short keys match the
  /// `CalculationEntry` / `NotepadLine` style elsewhere in the
  /// project.
  Map<String, dynamic> toJson();

  /// Dispatches on the `k` field to the concrete subclass.
  static SceneObject fromJson(Map<String, dynamic> j) {
    final kindStr = j['k'] as String?;
    final kind = SceneObjectKind.values.firstWhere(
      (v) => v.name == kindStr,
      orElse: () => SceneObjectKind.plane,
    );
    switch (kind) {
      case SceneObjectKind.plane:
        return PlaneObject.fromJson(j);
      case SceneObjectKind.line:
        return LineObject.fromJson(j);
      case SceneObjectKind.sphere:
        return SphereObject.fromJson(j);
      case SceneObjectKind.quadric:
        return QuadricObject.fromJson(j);
      case SceneObjectKind.parametricSurface:
        return ParametricSurfaceObject.fromJson(j);
      case SceneObjectKind.parametricCurve:
        return ParametricCurveObject.fromJson(j);
    }
  }

  /// Subclasses override to provide a value-based equality check. The
  /// renderer / scene state uses this to detect when a re-evaluation
  /// is needed.
  bool equalsByGeometry(SceneObject other);
}

/// Plane stored in coordinate form: `a x + b y + c z = d`. The
/// constructor accepts the four coefficients directly;
/// [PlaneObject.fromParametric] builds one from a point + two
/// direction vectors.
class PlaneObject extends SceneObject {
  final double a, b, c, d;

  const PlaneObject({
    required super.id,
    required super.label,
    required super.color,
    super.visible,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
  }) : super(kind: SceneObjectKind.plane);

  /// Build a plane from a point + two direction vectors. The plane
  /// normal is `u × v`; throws [ArgumentError] if the vectors are
  /// parallel (cross product zero).
  factory PlaneObject.fromParametric({
    required String id,
    required String label,
    required int color,
    bool visible = true,
    required Vector3 point,
    required Vector3 u,
    required Vector3 v,
  }) {
    final n = u.cross(v);
    if (n.x == 0 && n.y == 0 && n.z == 0) {
      throw ArgumentError('Direction vectors are parallel — no plane.');
    }
    return PlaneObject(
      id: id,
      label: label,
      color: color,
      visible: visible,
      a: n.x,
      b: n.y,
      c: n.z,
      d: n.dot(point),
    );
  }

  Vector3 get normal => Vector3(a, b, c);

  /// True when the point lies on the plane (within [eps] tolerance).
  bool contains(Vector3 p, {double eps = 1e-9}) =>
      (a * p.x + b * p.y + c * p.z - d).abs() < eps;

  @override
  Map<String, dynamic> toJson() => {
        'k': kind.name,
        'i': id,
        'l': label,
        'c': color,
        if (!visible) 'h': true,
        'a': a,
        'b': b,
        'cc': c,
        'd': d,
      };

  factory PlaneObject.fromJson(Map<String, dynamic> j) => PlaneObject(
        id: j['i'] as String? ?? _newId(),
        label: j['l'] as String? ?? 'Plane',
        color: (j['c'] as num?)?.toInt() ?? 0xFF1976D2,
        visible: !(j['h'] as bool? ?? false),
        a: (j['a'] as num?)?.toDouble() ?? 0,
        b: (j['b'] as num?)?.toDouble() ?? 0,
        c: (j['cc'] as num?)?.toDouble() ?? 0,
        d: (j['d'] as num?)?.toDouble() ?? 0,
      );

  @override
  bool equalsByGeometry(SceneObject other) =>
      other is PlaneObject &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.d == d;
}

/// Line in 3D, stored as point + direction (a.k.a. parametric form
/// `r(t) = point + t · direction`). Direction is not auto-normalized
/// — the renderer normalizes if it wants to draw a unit-length
/// arrow; intersection math doesn't care.
class LineObject extends SceneObject {
  final Vector3 point;
  final Vector3 direction;

  const LineObject({
    required super.id,
    required super.label,
    required super.color,
    super.visible,
    required this.point,
    required this.direction,
  }) : super(kind: SceneObjectKind.line);

  /// Build a line through two points. Throws when [p] and [q] are
  /// identical (no direction).
  factory LineObject.throughPoints({
    required String id,
    required String label,
    required int color,
    bool visible = true,
    required Vector3 p,
    required Vector3 q,
  }) {
    final dir = Vector3(q.x - p.x, q.y - p.y, q.z - p.z);
    if (dir.x == 0 && dir.y == 0 && dir.z == 0) {
      throw ArgumentError('Two points coincide — no line.');
    }
    return LineObject(
      id: id,
      label: label,
      color: color,
      visible: visible,
      point: p,
      direction: dir,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'k': kind.name,
        'i': id,
        'l': label,
        'c': color,
        if (!visible) 'h': true,
        'px': point.x,
        'py': point.y,
        'pz': point.z,
        'dx': direction.x,
        'dy': direction.y,
        'dz': direction.z,
      };

  factory LineObject.fromJson(Map<String, dynamic> j) => LineObject(
        id: j['i'] as String? ?? _newId(),
        label: j['l'] as String? ?? 'Line',
        color: (j['c'] as num?)?.toInt() ?? 0xFF43A047,
        visible: !(j['h'] as bool? ?? false),
        point: Vector3(
          (j['px'] as num?)?.toDouble() ?? 0,
          (j['py'] as num?)?.toDouble() ?? 0,
          (j['pz'] as num?)?.toDouble() ?? 0,
        ),
        direction: Vector3(
          (j['dx'] as num?)?.toDouble() ?? 1,
          (j['dy'] as num?)?.toDouble() ?? 0,
          (j['dz'] as num?)?.toDouble() ?? 0,
        ),
      );

  @override
  bool equalsByGeometry(SceneObject other) =>
      other is LineObject &&
      other.point == point &&
      other.direction == direction;
}

/// Sphere: center + radius. Radius is stored as-is (can be 0 → degenerate point).
class SphereObject extends SceneObject {
  final Vector3 center;
  final double radius;

  const SphereObject({
    required super.id,
    required super.label,
    required super.color,
    super.visible,
    required this.center,
    required this.radius,
  }) : super(kind: SceneObjectKind.sphere);

  @override
  Map<String, dynamic> toJson() => {
        'k': kind.name,
        'i': id,
        'l': label,
        'c': color,
        if (!visible) 'h': true,
        'cx': center.x,
        'cy': center.y,
        'cz': center.z,
        'r': radius,
      };

  factory SphereObject.fromJson(Map<String, dynamic> j) => SphereObject(
        id: j['i'] as String? ?? _newId(),
        label: j['l'] as String? ?? 'Sphere',
        color: (j['c'] as num?)?.toInt() ?? 0xFFFF7043,
        visible: !(j['h'] as bool? ?? false),
        center: Vector3(
          (j['cx'] as num?)?.toDouble() ?? 0,
          (j['cy'] as num?)?.toDouble() ?? 0,
          (j['cz'] as num?)?.toDouble() ?? 0,
        ),
        radius: (j['r'] as num?)?.toDouble() ?? 1,
      );

  @override
  bool equalsByGeometry(SceneObject other) =>
      other is SphereObject && other.center == center && other.radius == radius;
}

/// General 3D quadric surface:
/// `A x² + B y² + C z² + D xy + E xz + F yz + G x + H y + I z + J = 0`.
/// Covers ellipsoids, paraboloids, hyperboloids (1- and 2-sheet),
/// cones, cylinders, and degenerate cases. Classification happens
/// downstream (round A5).
class QuadricObject extends SceneObject {
  /// Coefficients in the order they appear in the canonical form.
  /// Stored individually rather than as a Map so JSON keys are
  /// stable and renaming a single field is a compile error.
  final double cA, cB, cC, cD, cE, cF, cG, cH, cI, cJ;

  const QuadricObject({
    required super.id,
    required super.label,
    required super.color,
    super.visible,
    required this.cA,
    required this.cB,
    required this.cC,
    required this.cD,
    required this.cE,
    required this.cF,
    required this.cG,
    required this.cH,
    required this.cI,
    required this.cJ,
  }) : super(kind: SceneObjectKind.quadric);

  /// Evaluate the quadric polynomial at (x, y, z). Zero means the
  /// point is on the surface.
  double evaluate(double x, double y, double z) =>
      cA * x * x +
      cB * y * y +
      cC * z * z +
      cD * x * y +
      cE * x * z +
      cF * y * z +
      cG * x +
      cH * y +
      cI * z +
      cJ;

  @override
  Map<String, dynamic> toJson() => {
        'k': kind.name,
        'i': id,
        'l': label,
        'c': color,
        if (!visible) 'h': true,
        'qa': cA,
        'qb': cB,
        'qc': cC,
        'qd': cD,
        'qe': cE,
        'qf': cF,
        'qg': cG,
        'qh': cH,
        'qi': cI,
        'qj': cJ,
      };

  factory QuadricObject.fromJson(Map<String, dynamic> j) => QuadricObject(
        id: j['i'] as String? ?? _newId(),
        label: j['l'] as String? ?? 'Quadric',
        color: (j['c'] as num?)?.toInt() ?? 0xFF8E24AA,
        visible: !(j['h'] as bool? ?? false),
        cA: (j['qa'] as num?)?.toDouble() ?? 0,
        cB: (j['qb'] as num?)?.toDouble() ?? 0,
        cC: (j['qc'] as num?)?.toDouble() ?? 0,
        cD: (j['qd'] as num?)?.toDouble() ?? 0,
        cE: (j['qe'] as num?)?.toDouble() ?? 0,
        cF: (j['qf'] as num?)?.toDouble() ?? 0,
        cG: (j['qg'] as num?)?.toDouble() ?? 0,
        cH: (j['qh'] as num?)?.toDouble() ?? 0,
        cI: (j['qi'] as num?)?.toDouble() ?? 0,
        cJ: (j['qj'] as num?)?.toDouble() ?? 0,
      );

  @override
  bool equalsByGeometry(SceneObject other) =>
      other is QuadricObject &&
      other.cA == cA &&
      other.cB == cB &&
      other.cC == cC &&
      other.cD == cD &&
      other.cE == cE &&
      other.cF == cF &&
      other.cG == cG &&
      other.cH == cH &&
      other.cI == cI &&
      other.cJ == cJ;
}

/// Parametric surface `r(u, v) = (x(u,v), y(u,v), z(u,v))`. The
/// component expressions are stored as strings — evaluated by the
/// renderer (round A6) via the same `CalculatorEngine` pipeline the
/// 2D and 3D graphers already use.
class ParametricSurfaceObject extends SceneObject {
  final String exprX, exprY, exprZ;
  final double uMin, uMax, vMin, vMax;
  final int uSteps, vSteps;

  const ParametricSurfaceObject({
    required super.id,
    required super.label,
    required super.color,
    super.visible,
    required this.exprX,
    required this.exprY,
    required this.exprZ,
    this.uMin = 0,
    this.uMax = 1,
    this.vMin = 0,
    this.vMax = 1,
    this.uSteps = 24,
    this.vSteps = 24,
  }) : super(kind: SceneObjectKind.parametricSurface);

  @override
  Map<String, dynamic> toJson() => {
        'k': kind.name,
        'i': id,
        'l': label,
        'c': color,
        if (!visible) 'h': true,
        'ex': exprX,
        'ey': exprY,
        'ez': exprZ,
        'um': uMin,
        'uM': uMax,
        'vm': vMin,
        'vM': vMax,
        'us': uSteps,
        'vs': vSteps,
      };

  factory ParametricSurfaceObject.fromJson(Map<String, dynamic> j) =>
      ParametricSurfaceObject(
        id: j['i'] as String? ?? _newId(),
        label: j['l'] as String? ?? 'Surface',
        color: (j['c'] as num?)?.toInt() ?? 0xFF00897B,
        visible: !(j['h'] as bool? ?? false),
        exprX: j['ex'] as String? ?? 'u',
        exprY: j['ey'] as String? ?? 'v',
        exprZ: j['ez'] as String? ?? '0',
        uMin: (j['um'] as num?)?.toDouble() ?? 0,
        uMax: (j['uM'] as num?)?.toDouble() ?? 1,
        vMin: (j['vm'] as num?)?.toDouble() ?? 0,
        vMax: (j['vM'] as num?)?.toDouble() ?? 1,
        uSteps: (j['us'] as num?)?.toInt() ?? 24,
        vSteps: (j['vs'] as num?)?.toInt() ?? 24,
      );

  @override
  bool equalsByGeometry(SceneObject other) =>
      other is ParametricSurfaceObject &&
      other.exprX == exprX &&
      other.exprY == exprY &&
      other.exprZ == exprZ &&
      other.uMin == uMin &&
      other.uMax == uMax &&
      other.vMin == vMin &&
      other.vMax == vMax &&
      other.uSteps == uSteps &&
      other.vSteps == vSteps;
}

/// Parametric curve `r(t) = (x(t), y(t), z(t))`. Same shape as
/// [ParametricSurfaceObject] but with one parameter.
class ParametricCurveObject extends SceneObject {
  final String exprX, exprY, exprZ;
  final double tMin, tMax;
  final int steps;

  const ParametricCurveObject({
    required super.id,
    required super.label,
    required super.color,
    super.visible,
    required this.exprX,
    required this.exprY,
    required this.exprZ,
    this.tMin = 0,
    this.tMax = 1,
    this.steps = 100,
  }) : super(kind: SceneObjectKind.parametricCurve);

  @override
  Map<String, dynamic> toJson() => {
        'k': kind.name,
        'i': id,
        'l': label,
        'c': color,
        if (!visible) 'h': true,
        'ex': exprX,
        'ey': exprY,
        'ez': exprZ,
        'tm': tMin,
        'tM': tMax,
        'ts': steps,
      };

  factory ParametricCurveObject.fromJson(Map<String, dynamic> j) =>
      ParametricCurveObject(
        id: j['i'] as String? ?? _newId(),
        label: j['l'] as String? ?? 'Curve',
        color: (j['c'] as num?)?.toInt() ?? 0xFFFDD835,
        visible: !(j['h'] as bool? ?? false),
        exprX: j['ex'] as String? ?? 't',
        exprY: j['ey'] as String? ?? '0',
        exprZ: j['ez'] as String? ?? '0',
        tMin: (j['tm'] as num?)?.toDouble() ?? 0,
        tMax: (j['tM'] as num?)?.toDouble() ?? 1,
        steps: (j['ts'] as num?)?.toInt() ?? 100,
      );

  @override
  bool equalsByGeometry(SceneObject other) =>
      other is ParametricCurveObject &&
      other.exprX == exprX &&
      other.exprY == exprY &&
      other.exprZ == exprZ &&
      other.tMin == tMin &&
      other.tMax == tMax &&
      other.steps == steps;
}

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

final Random _rng = Random.secure();

/// Generate a stable id for a scene object. Same shape as
/// `generateNotepadId()` so eyeballing the prefs JSON is consistent.
String generateSceneObjectId() => _newId();

String _newId() {
  // 8 random bytes → base36 string. Collision-resistant enough for
  // per-scene ids; not a security primitive.
  var n = BigInt.zero;
  for (var i = 0; i < 8; i++) {
    n = (n << 8) | BigInt.from(_rng.nextInt(256));
  }
  return n.toRadixString(36);
}
