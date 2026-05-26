// Tests for the P9-A1 scene engine: object construction, geometry
// invariants, JSON round-trip. Pure-Dart; no widget tree, no
// SymEngine bridge.

import 'package:flutter_test/flutter_test.dart';

import 'package:crisp_calc/engine/plane_math.dart' show Vector3;
import 'package:crisp_calc/engine/scene_3d/scene_object.dart';
import 'package:crisp_calc/engine/scene_3d/scene_state.dart';

void main() {
  group('PlaneObject', () {
    test('coordinate form stores coefficients verbatim', () {
      const p = PlaneObject(
        id: 'p1',
        label: 'P',
        color: 0xFF000000,
        a: 1,
        b: 2,
        c: -2,
        d: 6,
      );
      expect(p.a, 1);
      expect(p.normal, const Vector3(1, 2, -2));
    });

    test('contains() recognises a point on the plane', () {
      // 1·x + 2·y − 2·z = 6 passes through (6, 0, 0).
      const p = PlaneObject(
        id: 'p1',
        label: 'P',
        color: 0,
        a: 1,
        b: 2,
        c: -2,
        d: 6,
      );
      expect(p.contains(const Vector3(6, 0, 0)), isTrue);
      expect(p.contains(const Vector3(0, 3, 0)), isTrue);
      expect(p.contains(const Vector3(0, 0, -3)), isTrue);
      expect(p.contains(const Vector3(0, 0, 0)), isFalse);
    });

    test('fromParametric matches the analyzer math for a known plane', () {
      // Point (1, 0, 0), directions (0, 1, 0) and (0, 0, 1) → x = 1.
      final p = PlaneObject.fromParametric(
        id: 'p1',
        label: 'P',
        color: 0,
        point: const Vector3(1, 0, 0),
        u: const Vector3(0, 1, 0),
        v: const Vector3(0, 0, 1),
      );
      // n = u × v = (1, 0, 0); d = n·point = 1.
      expect(p.a, 1);
      expect(p.b, 0);
      expect(p.c, 0);
      expect(p.d, 1);
    });

    test('fromParametric throws on parallel direction vectors', () {
      expect(
        () => PlaneObject.fromParametric(
          id: 'p1',
          label: 'P',
          color: 0,
          point: const Vector3(0, 0, 0),
          u: const Vector3(1, 2, 3),
          v: const Vector3(2, 4, 6),
        ),
        throwsArgumentError,
      );
    });

    test('JSON round-trip preserves all fields', () {
      const original = PlaneObject(
        id: 'plane-abc',
        label: 'My plane',
        color: 0xFFE91E63,
        visible: false,
        a: 1.5,
        b: -2.25,
        c: 3,
        d: 4.75,
      );
      final restored = SceneObject.fromJson(original.toJson()) as PlaneObject;
      expect(restored.id, original.id);
      expect(restored.label, original.label);
      expect(restored.color, original.color);
      expect(restored.visible, original.visible);
      expect(restored.a, original.a);
      expect(restored.b, original.b);
      expect(restored.c, original.c);
      expect(restored.d, original.d);
      expect(restored.equalsByGeometry(original), isTrue);
    });
  });

  group('LineObject', () {
    test('throughPoints derives the direction vector', () {
      final l = LineObject.throughPoints(
        id: 'l1',
        label: 'L',
        color: 0,
        p: const Vector3(1, 2, 3),
        q: const Vector3(4, 6, 11),
      );
      expect(l.point, const Vector3(1, 2, 3));
      expect(l.direction, const Vector3(3, 4, 8));
    });

    test('throughPoints rejects coincident points', () {
      expect(
        () => LineObject.throughPoints(
          id: 'l',
          label: 'L',
          color: 0,
          p: const Vector3(1, 1, 1),
          q: const Vector3(1, 1, 1),
        ),
        throwsArgumentError,
      );
    });

    test('JSON round-trip', () {
      const original = LineObject(
        id: 'line-xyz',
        label: 'L',
        color: 0xFF00FF00,
        point: Vector3(1, 2, 3),
        direction: Vector3(4, 5, 6),
      );
      final restored = SceneObject.fromJson(original.toJson()) as LineObject;
      expect(restored.point, const Vector3(1, 2, 3));
      expect(restored.direction, const Vector3(4, 5, 6));
      expect(restored.equalsByGeometry(original), isTrue);
    });
  });

  group('SphereObject', () {
    test('JSON round-trip preserves center + radius', () {
      const original = SphereObject(
        id: 'sph',
        label: 'Earth',
        color: 0xFF0000FF,
        center: Vector3(-1, 2, 0.5),
        radius: 6.371,
      );
      final restored = SceneObject.fromJson(original.toJson()) as SphereObject;
      expect(restored.center, const Vector3(-1, 2, 0.5));
      expect(restored.radius, 6.371);
      expect(restored.equalsByGeometry(original), isTrue);
    });
  });

  group('QuadricObject', () {
    test('evaluate() of the unit sphere is zero on the surface', () {
      // x² + y² + z² − 1 = 0 ⇒ A=B=C=1, J=-1, all else 0.
      const q = QuadricObject(
        id: 'q',
        label: 'Unit sphere',
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
      expect(q.evaluate(1, 0, 0), closeTo(0, 1e-12));
      expect(q.evaluate(0, 1, 0), closeTo(0, 1e-12));
      expect(q.evaluate(0, 0, 1), closeTo(0, 1e-12));
      expect(q.evaluate(0, 0, 0), -1);
      expect(q.evaluate(2, 0, 0), 3);
    });

    test('JSON round-trip preserves all ten coefficients', () {
      const original = QuadricObject(
        id: 'q1',
        label: 'Ellipsoid',
        color: 0xFF9C27B0,
        cA: 1,
        cB: 4,
        cC: 9,
        cD: 0.5,
        cE: -0.5,
        cF: 0.25,
        cG: -2,
        cH: 3,
        cI: -1.5,
        cJ: -10,
      );
      final restored = SceneObject.fromJson(original.toJson()) as QuadricObject;
      expect(restored.equalsByGeometry(original), isTrue);
    });
  });

  group('ParametricSurfaceObject', () {
    test('JSON round-trip preserves expressions + parameter ranges', () {
      const original = ParametricSurfaceObject(
        id: 'ps1',
        label: 'Torus',
        color: 0xFF607D8B,
        exprX: '(2 + cos(v)) * cos(u)',
        exprY: '(2 + cos(v)) * sin(u)',
        exprZ: 'sin(v)',
        uMin: 0,
        uMax: 6.28319,
        vMin: 0,
        vMax: 6.28319,
        uSteps: 30,
        vSteps: 30,
      );
      final restored =
          SceneObject.fromJson(original.toJson()) as ParametricSurfaceObject;
      expect(restored.exprX, original.exprX);
      expect(restored.uMax, original.uMax);
      expect(restored.uSteps, original.uSteps);
      expect(restored.equalsByGeometry(original), isTrue);
    });
  });

  group('ParametricCurveObject', () {
    test('JSON round-trip', () {
      const original = ParametricCurveObject(
        id: 'pc1',
        label: 'Helix',
        color: 0xFFFFEB3B,
        exprX: 'cos(t)',
        exprY: 'sin(t)',
        exprZ: 't/5',
        tMin: 0,
        tMax: 12.5664,
        steps: 200,
      );
      final restored =
          SceneObject.fromJson(original.toJson()) as ParametricCurveObject;
      expect(restored.exprX, original.exprX);
      expect(restored.tMax, original.tMax);
      expect(restored.steps, 200);
      expect(restored.equalsByGeometry(original), isTrue);
    });
  });

  group('Scene3D container', () {
    test('empty scene has the default viewport', () {
      final s = Scene3D.empty(name: 'Test');
      expect(s.name, 'Test');
      expect(s.objects, isEmpty);
      expect(s.azimuth, kDefaultSceneAzimuth);
      expect(s.elevation, kDefaultSceneElevation);
      expect(s.zoom, kDefaultSceneZoom);
      expect(s.range, kDefaultSceneRange);
    });

    test('withObject appends a fresh id', () {
      final s = Scene3D.empty();
      final p = PlaneObject(
        id: generateSceneObjectId(),
        label: 'P',
        color: 0,
        a: 1,
        b: 0,
        c: 0,
        d: 5,
      );
      final s2 = s.withObject(p);
      expect(s2.objects, hasLength(1));
      expect(s2.objects.first, same(p));
      // Original is unchanged.
      expect(s.objects, isEmpty);
    });

    test('withObject replaces an existing id in place', () {
      final id = generateSceneObjectId();
      final p1 =
          PlaneObject(id: id, label: 'P', color: 0, a: 1, b: 0, c: 0, d: 5);
      final p2 = PlaneObject(
          id: id, label: 'P-edited', color: 0, a: 1, b: 0, c: 0, d: 10);
      final s = Scene3D.empty().withObject(p1).withObject(p2);
      expect(s.objects, hasLength(1));
      expect((s.objects.first as PlaneObject).d, 10);
      expect(s.objects.first.label, 'P-edited');
    });

    test('withoutObject removes by id', () {
      final p1 = PlaneObject(
          id: generateSceneObjectId(),
          label: 'P1',
          color: 0,
          a: 1,
          b: 0,
          c: 0,
          d: 1);
      final p2 = PlaneObject(
          id: generateSceneObjectId(),
          label: 'P2',
          color: 0,
          a: 0,
          b: 1,
          c: 0,
          d: 2);
      final s = Scene3D.empty().withObject(p1).withObject(p2);
      final s2 = s.withoutObject(p1.id);
      expect(s2.objects, hasLength(1));
      expect(s2.objects.first.id, p2.id);
    });

    test('JSON round-trip preserves objects + viewport', () {
      final scene = Scene3D.empty(name: 'Two planes')
        ..azimuth = 1.1
        ..elevation = -0.4
        ..zoom = 1.5
        ..range = 8;
      const p1 = PlaneObject(
          id: 'p1', label: 'X = 0', color: 0xFFE53935, a: 1, b: 0, c: 0, d: 0);
      const p2 = PlaneObject(
          id: 'p2', label: 'Y = 0', color: 0xFF1E88E5, a: 0, b: 1, c: 0, d: 0);
      final s = scene.withObject(p1).withObject(p2);
      // withObject returns a new scene with default viewport; carry
      // the edits over.
      s.azimuth = scene.azimuth;
      s.elevation = scene.elevation;
      s.zoom = scene.zoom;
      s.range = scene.range;

      final restored = Scene3D.fromJson(s.toJson());
      expect(restored.name, 'Two planes');
      expect(restored.objects, hasLength(2));
      expect(restored.objects[0].id, 'p1');
      expect(restored.objects[1].id, 'p2');
      expect(restored.azimuth, 1.1);
      expect(restored.elevation, -0.4);
      expect(restored.zoom, 1.5);
      expect(restored.range, 8);
    });
  });

  group('id generation', () {
    test('generateSceneObjectId produces unique ids across many calls', () {
      final ids = <String>{};
      for (var i = 0; i < 500; i++) {
        ids.add(generateSceneObjectId());
      }
      expect(ids, hasLength(500));
    });
  });
}
