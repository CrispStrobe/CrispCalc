import 'dart:math' as math;

import 'package:crisp_calc/engine/plane_math.dart';
import 'package:flutter_test/flutter_test.dart';

const _eps = 1e-9;

void main() {
  group('Vector3', () {
    test('cross product of basis vectors', () {
      const i = Vector3(1, 0, 0);
      const j = Vector3(0, 1, 0);
      expect(i.cross(j), const Vector3(0, 0, 1));
    });

    test('dot product', () {
      expect(const Vector3(1, 2, 3).dot(const Vector3(4, 5, 6)),
          closeTo(32, _eps));
    });

    test('length and normalization', () {
      const v = Vector3(3, 4, 0);
      expect(v.length, closeTo(5, _eps));
      final n = v.normalized();
      expect(n.length, closeTo(1, _eps));
    });

    test('normalizing zero vector returns zero, not NaN', () {
      const z = Vector3(0, 0, 0);
      final n = z.normalized();
      expect(n, const Vector3(0, 0, 0));
    });
  });

  group('analyzePlaneFromCoordinate', () {
    test('basic xy-plane (z = 0)', () {
      final r = analyzePlaneFromCoordinate(0, 0, 1, 0);
      expect(r.isValid, isTrue);
      expect(r.unitNormal, const Vector3(0, 0, 1));
      expect(r.signedDistanceFromOrigin, closeTo(0, _eps));
      expect(r.xIntercept, isNull); // parallel to x-axis
      expect(r.yIntercept, isNull);
      expect(r.zIntercept, isNotNull);
      expect(r.zIntercept!.z, closeTo(0, _eps));
    });

    test('plane x + y + z = 3 intercepts at (3,0,0) etc.', () {
      final r = analyzePlaneFromCoordinate(1, 1, 1, 3);
      expect(r.isValid, isTrue);
      expect(r.xIntercept!.x, closeTo(3, _eps));
      expect(r.yIntercept!.y, closeTo(3, _eps));
      expect(r.zIntercept!.z, closeTo(3, _eps));
      // Distance from origin: -3/sqrt(3) = -sqrt(3); signed normal points away.
      expect(r.signedDistanceFromOrigin, closeTo(-math.sqrt(3), 1e-6));
    });

    test('point on plane lies on the plane', () {
      final r = analyzePlaneFromCoordinate(2, -3, 4, 12);
      final p = r.pointOnPlane;
      expect(2 * p.x - 3 * p.y + 4 * p.z, closeTo(12, _eps));
    });

    test('unit normal has length 1', () {
      final r = analyzePlaneFromCoordinate(2, -3, 4, 5);
      expect(r.unitNormal.length, closeTo(1, _eps));
    });

    test('zero normal vector is invalid', () {
      final r = analyzePlaneFromCoordinate(0, 0, 0, 5);
      expect(r.isValid, isFalse);
      expect(r.error, isNotNull);
    });
  });

  group('analyzePlaneFromParametric', () {
    test('xy-plane via two basis directions', () {
      final r = analyzePlaneFromParametric(
        const Vector3(0, 0, 0),
        const Vector3(1, 0, 0),
        const Vector3(0, 1, 0),
      );
      expect(r.isValid, isTrue);
      // Normal should be ±(0, 0, 1) and unit.
      expect(r.unitNormal.x, closeTo(0, _eps));
      expect(r.unitNormal.y, closeTo(0, _eps));
      expect(r.unitNormal.z.abs(), closeTo(1, _eps));
    });

    test('parallel direction vectors error out', () {
      final r = analyzePlaneFromParametric(
        const Vector3(0, 0, 0),
        const Vector3(1, 0, 0),
        const Vector3(2, 0, 0),
      );
      expect(r.isValid, isFalse);
    });

    test('roundtrip parametric → coordinate', () {
      final r = analyzePlaneFromParametric(
        const Vector3(1, 2, 3),
        const Vector3(0, 1, 0),
        const Vector3(0, 0, 1),
      );
      // Normal is e_x; plane is x = 1, so a=1, b=0, c=0, d=1.
      expect(r.a.abs(), closeTo(1, _eps));
      expect(r.b, closeTo(0, _eps));
      expect(r.c, closeTo(0, _eps));
      expect(r.d.abs(), closeTo(1, _eps));
    });
  });
}
