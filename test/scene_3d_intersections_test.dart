// P9-A4: tests for pairwise intersections. One happy + at least
// one degenerate case per pair. Pure-Dart math — no widget tree.

import 'package:flutter_test/flutter_test.dart';

import 'package:crisp_calc/engine/plane_math.dart' show Vector3;
import 'package:crisp_calc/engine/scene_3d/intersections.dart';
import 'package:crisp_calc/engine/scene_3d/scene_object.dart';

PlaneObject plane(double a, double b, double c, double d) =>
    PlaneObject(id: 'p', label: 'P', color: 0, a: a, b: b, c: c, d: d);

LineObject line(Vector3 p, Vector3 d) =>
    LineObject(id: 'l', label: 'L', color: 0, point: p, direction: d);

SphereObject sphere(Vector3 c, double r) =>
    SphereObject(id: 's', label: 'S', color: 0, center: c, radius: r);

void expectVec(Vector3 actual, Vector3 expected, {double tol = 1e-6}) {
  expect(actual.x, closeTo(expected.x, tol));
  expect(actual.y, closeTo(expected.y, tol));
  expect(actual.z, closeTo(expected.z, tol));
}

bool _vecParallel(Vector3 a, Vector3 b, {double tol = 1e-6}) {
  // Cross product magnitude near zero ⇒ parallel.
  final c = a.cross(b);
  return c.dot(c) < tol;
}

void main() {
  group('plane × plane', () {
    test('xy plane × yz plane → y-axis through origin', () {
      // z = 0 (n = (0,0,1)) and x = 0 (n = (1,0,0)).
      final result = intersect(
        plane(0, 0, 1, 0),
        plane(1, 0, 0, 0),
      );
      expect(result, isA<LineIntersection>());
      final line = result! as LineIntersection;
      // Direction should be parallel to ±(0, 1, 0).
      expect(_vecParallel(line.direction, const Vector3(0, 1, 0)), isTrue);
      // Any point on the line must satisfy both equations: x = 0, z = 0.
      expect(line.point.x.abs() < 1e-6, isTrue);
      expect(line.point.z.abs() < 1e-6, isTrue);
    });

    test('parallel but distinct planes → no intersection', () {
      final result = intersect(
        plane(0, 0, 1, 0), // z = 0
        plane(0, 0, 1, 5), // z = 5
      );
      expect(result, isA<NoIntersection>());
      expect((result! as NoIntersection).reasonKey, 'parallelPlanes');
    });

    test('coincident planes → coincident result', () {
      final result = intersect(
        plane(1, 2, 3, 4),
        plane(2, 4, 6, 8),
      );
      expect(result, isA<CoincidentIntersection>());
    });
  });

  group('plane × line', () {
    test('xy plane × vertical line through (0,0,1) → origin', () {
      final result = intersect(
        plane(0, 0, 1, 0),
        line(const Vector3(0, 0, 1), const Vector3(0, 0, -1)),
      );
      expect(result, isA<PointIntersection>());
      expectVec((result! as PointIntersection).point, const Vector3(0, 0, 0));
    });

    test('plane × line parallel-to-plane-but-outside → no intersection', () {
      final result = intersect(
        plane(0, 0, 1, 0),
        line(const Vector3(0, 0, 5), const Vector3(1, 0, 0)),
      );
      expect(result, isA<NoIntersection>());
      expect((result! as NoIntersection).reasonKey, 'lineParallelToPlane');
    });

    test('plane × line lying in plane → contained', () {
      final result = intersect(
        plane(0, 0, 1, 0),
        line(const Vector3(0, 0, 0), const Vector3(1, 1, 0)),
      );
      expect(result, isA<ContainedIntersection>());
    });

    test('swapped arg order also works', () {
      final result = intersect(
        line(const Vector3(0, 0, 1), const Vector3(0, 0, -1)),
        plane(0, 0, 1, 0),
      );
      expect(result, isA<PointIntersection>());
    });
  });

  group('plane × sphere', () {
    test('xy plane × unit sphere at origin → unit circle in xy', () {
      final result = intersect(
        plane(0, 0, 1, 0),
        sphere(const Vector3(0, 0, 0), 1),
      );
      expect(result, isA<CircleIntersection>());
      final c = result! as CircleIntersection;
      expectVec(c.center, const Vector3(0, 0, 0));
      expect(c.radius, closeTo(1.0, 1e-9));
      expect(_vecParallel(c.normal, const Vector3(0, 0, 1)), isTrue);
    });

    test('tangent plane → single point', () {
      // z = 1 tangent to sphere of radius 1 at origin.
      final result = intersect(
        plane(0, 0, 1, 1),
        sphere(const Vector3(0, 0, 0), 1),
      );
      expect(result, isA<PointIntersection>());
      expectVec((result! as PointIntersection).point, const Vector3(0, 0, 1));
    });

    test('plane that misses the sphere → none', () {
      final result = intersect(
        plane(0, 0, 1, 5),
        sphere(const Vector3(0, 0, 0), 1),
      );
      expect(result, isA<NoIntersection>());
      expect((result! as NoIntersection).reasonKey, 'sphereMissesPlane');
    });
  });

  group('line × line', () {
    test('crossing lines through origin → origin', () {
      final result = intersect(
        line(const Vector3(0, 0, 0), const Vector3(1, 0, 0)),
        line(const Vector3(0, 0, 0), const Vector3(0, 1, 0)),
      );
      expect(result, isA<PointIntersection>());
      expectVec((result! as PointIntersection).point, const Vector3(0, 0, 0));
    });

    test('skew lines → no intersection', () {
      // x-axis and a line offset along z.
      final result = intersect(
        line(const Vector3(0, 0, 0), const Vector3(1, 0, 0)),
        line(const Vector3(0, 0, 1), const Vector3(0, 1, 0)),
      );
      expect(result, isA<NoIntersection>());
      expect((result! as NoIntersection).reasonKey, 'skewLines');
    });

    test('parallel-but-distinct lines → parallel', () {
      final result = intersect(
        line(const Vector3(0, 0, 0), const Vector3(1, 0, 0)),
        line(const Vector3(0, 1, 0), const Vector3(2, 0, 0)),
      );
      expect(result, isA<NoIntersection>());
      expect((result! as NoIntersection).reasonKey, 'parallelLines');
    });

    test('coincident lines (same direction, point on both) → coincident', () {
      final result = intersect(
        line(const Vector3(0, 0, 0), const Vector3(1, 0, 0)),
        line(const Vector3(5, 0, 0), const Vector3(3, 0, 0)),
      );
      expect(result, isA<CoincidentIntersection>());
    });
  });

  group('line × sphere', () {
    test('x-axis × unit sphere → (-1,0,0) and (1,0,0)', () {
      final result = intersect(
        line(const Vector3(0, 0, 0), const Vector3(1, 0, 0)),
        sphere(const Vector3(0, 0, 0), 1),
      );
      expect(result, isA<TwoPointsIntersection>());
      final two = result! as TwoPointsIntersection;
      // Order is t1 ≤ t2 → a is the negative side.
      expectVec(two.a, const Vector3(-1, 0, 0));
      expectVec(two.b, const Vector3(1, 0, 0));
    });

    test('tangent line → single point', () {
      // Line z=1 along x, sphere at origin radius 1: tangent at (0,0,1).
      final result = intersect(
        line(const Vector3(0, 0, 1), const Vector3(1, 0, 0)),
        sphere(const Vector3(0, 0, 0), 1),
      );
      expect(result, isA<PointIntersection>());
      expectVec((result! as PointIntersection).point, const Vector3(0, 0, 1));
    });

    test('line that misses sphere → none', () {
      final result = intersect(
        line(const Vector3(0, 0, 5), const Vector3(1, 0, 0)),
        sphere(const Vector3(0, 0, 0), 1),
      );
      expect(result, isA<NoIntersection>());
      expect((result! as NoIntersection).reasonKey, 'lineMissesSphere');
    });

    test('swapped arg order also works', () {
      final result = intersect(
        sphere(const Vector3(0, 0, 0), 1),
        line(const Vector3(0, 0, 0), const Vector3(1, 0, 0)),
      );
      expect(result, isA<TwoPointsIntersection>());
    });
  });

  group('sphere × sphere', () {
    test('two unit spheres at (0,0,0) and (1,0,0) → circle', () {
      final result = intersect(
        sphere(const Vector3(0, 0, 0), 1),
        sphere(const Vector3(1, 0, 0), 1),
      );
      expect(result, isA<CircleIntersection>());
      final c = result! as CircleIntersection;
      // Circle center sits at x = 1/2.
      expect(c.center.x, closeTo(0.5, 1e-9));
      expect(c.center.y, closeTo(0, 1e-9));
      expect(c.center.z, closeTo(0, 1e-9));
      // Radius = sqrt(1 - 1/4) = sqrt(3)/2.
      expect(c.radius, closeTo(0.866025403784, 1e-9));
      // Normal aligned with x-axis.
      expect(_vecParallel(c.normal, const Vector3(1, 0, 0)), isTrue);
    });

    test('externally tangent spheres → single point on axis', () {
      // Radii 1 + 2 = 3 = distance.
      final result = intersect(
        sphere(const Vector3(0, 0, 0), 1),
        sphere(const Vector3(3, 0, 0), 2),
      );
      expect(result, isA<PointIntersection>());
      expectVec((result! as PointIntersection).point, const Vector3(1, 0, 0));
    });

    test('disjoint spheres → none', () {
      final result = intersect(
        sphere(const Vector3(0, 0, 0), 1),
        sphere(const Vector3(10, 0, 0), 1),
      );
      expect(result, isA<NoIntersection>());
      expect((result! as NoIntersection).reasonKey, 'spheresApart');
    });

    test('sphere inside sphere (no contact) → none', () {
      final result = intersect(
        sphere(const Vector3(0, 0, 0), 5),
        sphere(const Vector3(0, 0, 0), 1),
      );
      expect(result, isA<NoIntersection>());
      expect((result! as NoIntersection).reasonKey, 'sphereInsideSphere');
    });

    test('identical spheres → coincident', () {
      final result = intersect(
        sphere(const Vector3(1, 2, 3), 4),
        sphere(const Vector3(1, 2, 3), 4),
      );
      expect(result, isA<CoincidentIntersection>());
    });
  });

  group('dispatcher', () {
    test('returns null for unsupported pairs (quadric × anything)', () {
      const q = QuadricObject(
        id: 'q',
        label: 'Q',
        color: 0,
        cA: 1,
        cB: 1,
        cC: 1,
        cD: 0,
        cE: 0,
        cF: 0,
        cG: 0,
        cH: 0,
        cI: 0,
        cJ: -1,
      );
      expect(intersect(q, plane(0, 0, 1, 0)), isNull);
      expect(intersect(plane(0, 0, 1, 0), q), isNull);
    });
  });
}
