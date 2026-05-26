// P9-A2: CustomPainter for the 3D Scene module.
//
// Iterates [Scene3D.objects] and dispatches by kind. A2 implements
// plane rendering only; later rounds add line (A3), sphere (A3),
// quadric (A5), parametric surface / curve (A6).
//
// Projection: hand-rolled rotation matrix + orthographic projection,
// same shape as Graphing3DScreen's _Surface3DPainter (rounds 33+).
// Factoring out a shared helper is on the table once A3 has landed
// and we've seen the rendering APIs settle.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/calculator_engine.dart';
import '../engine/plane_math.dart' show Vector3;
import '../engine/scene_3d/intersections.dart';
import '../engine/scene_3d/scene_object.dart';
import '../engine/scene_3d/scene_state.dart';
import '../utils/expression_preprocessing_utils.dart';

/// Color used for the intersection highlight overlay. Cyan reads
/// well against every palette color used for objects themselves.
const Color kIntersectionColor = Color(0xFF00E5FF);

class Scene3DPainter extends CustomPainter {
  final Scene3D scene;

  /// Intersection results to draw on top of the regular geometry.
  /// Computed by the screen + handed in so the screen can also feed
  /// the same list into the results panel (single source of truth).
  final List<Intersection> intersections;

  Scene3DPainter({
    required this.scene,
    this.intersections = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final range = scene.range;
    final scale = math.min(w, h) * 0.4 * scene.zoom / range;

    final cosA = math.cos(scene.azimuth);
    final sinA = math.sin(scene.azimuth);
    final cosE = math.cos(scene.elevation);
    final sinE = math.sin(scene.elevation);

    // World (x, y, z) → screen offset. Orthographic — depth is
    // dropped, so back-to-front sorting would be a future enhancement
    // (A3 / A4 will need it for proper occlusion).
    Offset project(double x, double y, double z) {
      final x1 = x * cosA - y * sinA;
      final y1 = x * sinA + y * cosA;
      final y2 = y1 * cosE - z * sinE;
      return Offset(cx + x1 * scale, cy - y2 * scale);
    }

    _drawAxes(canvas, project, range);

    for (final obj in scene.objects) {
      if (!obj.visible) continue;
      switch (obj) {
        case PlaneObject p:
          _drawPlane(canvas, p, project, range);
        case LineObject l:
          _drawLine(canvas, l, project, range, scene);
        case SphereObject s:
          _drawSphere(canvas, s, project);
        case QuadricObject q:
          _drawQuadric(canvas, q, project);
        case ParametricSurfaceObject ps:
          _drawParametricSurface(canvas, ps, project);
        case ParametricCurveObject pc:
          _drawParametricCurve(canvas, pc, project);
      }
    }

    // P9-A4: intersection-highlight overlay. Drawn after the
    // regular geometry so the highlights sit on top.
    for (final result in intersections) {
      switch (result) {
        case PointIntersection pi:
          _drawPoint(canvas, pi.point, project, range);
        case TwoPointsIntersection ti:
          _drawPoint(canvas, ti.a, project, range);
          _drawPoint(canvas, ti.b, project, range);
        case LineIntersection li:
          _drawIntersectionLine(canvas, li, project, range);
        case CircleIntersection ci:
          _drawIntersectionCircle(canvas, ci, project);
        case ConicSectionIntersection cs:
          _drawIntersectionConic(canvas, cs, project, scene.range);
        case NoIntersection _:
        case CoincidentIntersection _:
        case ContainedIntersection _:
          // Nothing extra to highlight — the results panel
          // describes these cases in text form.
          break;
      }
    }
  }

  // ----------------------------------------------------------------
  // Axes
  // ----------------------------------------------------------------

  void _drawAxes(Canvas canvas, Offset Function(double, double, double) project,
      double r) {
    final paint = Paint()..strokeWidth = 1.2;
    paint.color = Colors.red;
    canvas.drawLine(project(-r, 0, 0), project(r, 0, 0), paint);
    paint.color = Colors.green;
    canvas.drawLine(project(0, -r, 0), project(0, r, 0), paint);
    paint.color = Colors.blue;
    canvas.drawLine(project(0, 0, -r), project(0, 0, r), paint);
  }

  // ----------------------------------------------------------------
  // Plane rendering — sample a [range × range] patch in the plane's
  // local (u, v) frame around its closest-to-origin point, draw the
  // outline + a few interior cross-lines for depth.
  // ----------------------------------------------------------------

  void _drawPlane(
    Canvas canvas,
    PlaneObject plane,
    Offset Function(double, double, double) project,
    double range,
  ) {
    final normal = plane.normal;
    final nLen2 = normal.dot(normal);
    if (nLen2 == 0) return;
    final nLen = math.sqrt(nLen2);

    // Closest point on the plane to origin = (d / |n|²) · n.
    final t = plane.d / nLen2;
    final center = Vector3(normal.x * t, normal.y * t, normal.z * t);

    // Two orthonormal vectors spanning the plane. Pick any axis
    // that's not (nearly) parallel to the normal to seed the
    // Gram-Schmidt step.
    final seed = (normal.x.abs() < 0.9)
        ? const Vector3(1, 0, 0)
        : const Vector3(0, 1, 0);
    // u = seed − (seed·n / |n|²) · n, then normalise.
    final proj = seed.dot(normal) / nLen2;
    final uRaw = Vector3(
      seed.x - proj * normal.x,
      seed.y - proj * normal.y,
      seed.z - proj * normal.z,
    );
    final uLen = math.sqrt(uRaw.dot(uRaw));
    if (uLen == 0) return;
    final u = Vector3(uRaw.x / uLen, uRaw.y / uLen, uRaw.z / uLen);
    final vRaw = normal.cross(u);
    final v = Vector3(vRaw.x / nLen, vRaw.y / nLen, vRaw.z / nLen);

    // Sample a square patch in (s, t) ∈ [-range, +range]. 4 boundary
    // edges + a couple of interior cross-lines makes the plane
    // legible after rotation without becoming visual noise.
    Offset cornerAt(double s, double tt) {
      final p3 = Vector3(
        center.x + u.x * s + v.x * tt,
        center.y + u.y * s + v.y * tt,
        center.z + u.z * s + v.z * tt,
      );
      return project(p3.x, p3.y, p3.z);
    }

    final color = Color(plane.color);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.12);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color;
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withValues(alpha: 0.4);

    final r = range;
    final c00 = cornerAt(-r, -r);
    final c10 = cornerAt(r, -r);
    final c11 = cornerAt(r, r);
    final c01 = cornerAt(-r, r);

    // Filled quad (translucent) so the plane has visual weight even
    // when seen edge-on.
    final path = Path()
      ..moveTo(c00.dx, c00.dy)
      ..lineTo(c10.dx, c10.dy)
      ..lineTo(c11.dx, c11.dy)
      ..lineTo(c01.dx, c01.dy)
      ..close();
    canvas.drawPath(path, fill);

    // 3 interior cross-lines per axis — drawn first so the outline
    // sits on top.
    for (var i = 1; i < 4; i++) {
      final s = -r + (2 * r) * i / 4;
      canvas.drawLine(cornerAt(s, -r), cornerAt(s, r), faint);
      canvas.drawLine(cornerAt(-r, s), cornerAt(r, s), faint);
    }

    // Outline + light label dot at the centroid so the user can tell
    // which plane is which when several overlap.
    canvas.drawPath(path, edge);
    final cDot = cornerAt(0, 0);
    canvas.drawCircle(cDot, 3.5, Paint()..color = color);
  }

  // ----------------------------------------------------------------
  // Line rendering — clip the infinite line `point + t · direction`
  // to a bounding cube of side 2·range and draw the resulting
  // segment. A small filled circle marks the stored anchor point so
  // the user can see where the parametric origin sits; a tiny arrow
  // glyph at the +direction end indicates orientation.
  // ----------------------------------------------------------------

  void _drawLine(
    Canvas canvas,
    LineObject line,
    Offset Function(double, double, double) project,
    double range,
    Scene3D scene,
  ) {
    final p = line.point;
    final d = line.direction;
    final dLen2 = d.dot(d);
    if (dLen2 == 0) return;

    // Slab clipping against the axis-aligned bounding cube
    // [-range, range]^3. For each axis i, the line enters/exits when
    //   p[i] + t · d[i] ∈ [-range, range].
    // Track the intersection of all three slab intervals.
    double tMin = double.negativeInfinity;
    double tMax = double.infinity;
    bool clipAxis(double pi, double di) {
      if (di.abs() < 1e-12) {
        // Direction is parallel to this slab — line lies inside if
        // the anchor sits in range, otherwise no intersection.
        return pi.abs() <= range;
      }
      final t1 = (-range - pi) / di;
      final t2 = (range - pi) / di;
      final lo = t1 < t2 ? t1 : t2;
      final hi = t1 < t2 ? t2 : t1;
      if (lo > tMin) tMin = lo;
      if (hi < tMax) tMax = hi;
      return tMin <= tMax;
    }

    if (!clipAxis(p.x, d.x) || !clipAxis(p.y, d.y) || !clipAxis(p.z, d.z)) {
      return; // Line misses the view cube entirely.
    }

    final a = Vector3(
      p.x + tMin * d.x,
      p.y + tMin * d.y,
      p.z + tMin * d.z,
    );
    final b = Vector3(
      p.x + tMax * d.x,
      p.y + tMax * d.y,
      p.z + tMax * d.z,
    );

    final color = Color(line.color);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color;

    canvas.drawLine(project(a.x, a.y, a.z), project(b.x, b.y, b.z), stroke);

    // Anchor dot — only when the anchor is actually inside the view
    // cube; otherwise it'd float at a confusing screen position.
    if (p.x.abs() <= range && p.y.abs() <= range && p.z.abs() <= range) {
      canvas.drawCircle(
        project(p.x, p.y, p.z),
        3.0,
        Paint()..color = color,
      );
    }

    // Arrow glyph at the +direction end of the visible segment.
    // Draw a small triangle perpendicular to the screen-space line
    // direction so the arrow stays legible regardless of viewing
    // angle.
    final endScreen = project(b.x, b.y, b.z);
    final beforeEnd = project(
      p.x + (tMax - 0.1) * d.x,
      p.y + (tMax - 0.1) * d.y,
      p.z + (tMax - 0.1) * d.z,
    );
    final dirScreen = endScreen - beforeEnd;
    final mag =
        math.sqrt(dirScreen.dx * dirScreen.dx + dirScreen.dy * dirScreen.dy);
    if (mag > 1) {
      final ux = dirScreen.dx / mag;
      final uy = dirScreen.dy / mag;
      const size = 8.0;
      final left = endScreen +
          Offset(-ux * size - uy * size * 0.5, -uy * size + ux * size * 0.5);
      final right = endScreen +
          Offset(-ux * size + uy * size * 0.5, -uy * size - ux * size * 0.5);
      final arrow = Path()
        ..moveTo(endScreen.dx, endScreen.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(arrow, Paint()..color = color);
    }
  }

  // ----------------------------------------------------------------
  // Sphere rendering — latitude / longitude wireframe. Depth-cued
  // opacity (back hemisphere fades) so the sphere reads as 3D
  // without doing real hidden-line removal.
  // ----------------------------------------------------------------

  void _drawSphere(
    Canvas canvas,
    SphereObject sphere,
    Offset Function(double, double, double) project,
  ) {
    final r = sphere.radius;
    if (r <= 0) return;
    final c = sphere.center;
    final color = Color(sphere.color);

    const int latRings = 8; // horizontal rings (excluding poles)
    const int lonSegments = 16; // vertical "orange-slice" segments
    const int samples = 32; // points per ring/meridian curve

    // Screen-space depth for a world-space point along the camera's
    // forward axis. Same rotation as project()'s but we want the
    // perpendicular-to-screen component to drive opacity.
    final cosA = math.cos(scene.azimuth);
    final sinA = math.sin(scene.azimuth);
    final cosE = math.cos(scene.elevation);
    final sinE = math.sin(scene.elevation);
    double depthAt(double x, double y, double z) {
      // The view axis (the dropped coordinate in our ortho
      // projection) is: rotate around z by azimuth, then around x'
      // by elevation; the depth direction is the post-rotation
      // y2 = y1*sinE + z*cosE. Positive = farther from viewer.
      final y1 = x * sinA + y * cosA;
      return y1 * sinE + z * cosE;
    }

    Paint paintFor(double depth, double maxDepth) {
      // Back hemisphere (depth > 0) fades to ~25% opacity.
      final t = (depth / maxDepth).clamp(-1.0, 1.0); // -1 (front) .. +1 (back)
      final alpha = 1.0 - (t.clamp(0.0, 1.0)) * 0.75;
      return Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = color.withValues(alpha: alpha);
    }

    // Latitude rings (constant φ).
    for (var i = 1; i < latRings; i++) {
      final phi = math.pi * i / latRings - math.pi / 2; // -π/2..+π/2
      final cphi = math.cos(phi);
      final sphi = math.sin(phi);
      Offset? prev;
      double prevDepth = 0;
      for (var j = 0; j <= samples; j++) {
        final theta = 2 * math.pi * j / samples;
        final x = c.x + r * cphi * math.cos(theta);
        final y = c.y + r * cphi * math.sin(theta);
        final z = c.z + r * sphi;
        final screen = project(x, y, z);
        final d = depthAt(x - c.x, y - c.y, z - c.z);
        if (prev != null) {
          final paint = paintFor((prevDepth + d) / 2, r);
          canvas.drawLine(prev, screen, paint);
        }
        prev = screen;
        prevDepth = d;
      }
    }

    // Longitude meridians (constant θ).
    for (var j = 0; j < lonSegments; j++) {
      final theta = 2 * math.pi * j / lonSegments;
      final ct = math.cos(theta);
      final st = math.sin(theta);
      Offset? prev;
      double prevDepth = 0;
      for (var i = 0; i <= samples; i++) {
        final phi = math.pi * i / samples - math.pi / 2;
        final cphi = math.cos(phi);
        final sphi = math.sin(phi);
        final x = c.x + r * cphi * ct;
        final y = c.y + r * cphi * st;
        final z = c.z + r * sphi;
        final screen = project(x, y, z);
        final d = depthAt(x - c.x, y - c.y, z - c.z);
        if (prev != null) {
          final paint = paintFor((prevDepth + d) / 2, r);
          canvas.drawLine(prev, screen, paint);
        }
        prev = screen;
        prevDepth = d;
      }
    }

    // Center dot so coincident / nested spheres remain
    // distinguishable.
    canvas.drawCircle(project(c.x, c.y, c.z), 3.0, Paint()..color = color);
  }

  // ----------------------------------------------------------------
  // P9-A5: quadric rendering. Each preset kind has an
  // axis-aligned parametric form r(u, v) that we sample on a
  // grid and draw as a wireframe. Quadrics without a preset
  // (raw-coefficient input — not yet wired in V1) are skipped;
  // a marching-cubes-style isosurface extractor is the
  // upgrade path.
  // ----------------------------------------------------------------

  void _drawQuadric(
    Canvas canvas,
    QuadricObject q,
    Offset Function(double, double, double) project,
  ) {
    final preset = q.preset;
    if (preset == null) return;
    final color = Color(q.color);

    Vector3 r(double u, double v) => _quadricSample(preset, u, v);

    // Per-kind (u, v) range. Use enough samples to keep curves
    // smooth at the typical zoom level — performance is fine for
    // a handful of objects.
    const int uSteps = 24;
    const int vSteps = 24;
    final ranges = _quadricParametricRange(preset);
    final uMin = ranges.uMin;
    final uMax = ranges.uMax;
    final vMin = ranges.vMin;
    final vMax = ranges.vMax;
    final closedU = ranges.closedU;
    final closedV = ranges.closedV;

    // Sample the grid into a flat array of Offsets.
    final pts = List<List<Offset>>.generate(uSteps + 1, (i) {
      final u = uMin + (uMax - uMin) * i / uSteps;
      return List<Offset>.generate(vSteps + 1, (j) {
        final v = vMin + (vMax - vMin) * j / vSteps;
        final p = r(u, v);
        return project(p.x, p.y, p.z);
      });
    });

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = color.withValues(alpha: 0.75);

    // u-direction curves (constant v).
    for (var j = 0; j <= vSteps; j++) {
      for (var i = 0; i < uSteps; i++) {
        canvas.drawLine(pts[i][j], pts[i + 1][j], stroke);
      }
      if (closedU) {
        canvas.drawLine(pts[uSteps][j], pts[0][j], stroke);
      }
    }
    // v-direction curves (constant u).
    for (var i = 0; i <= uSteps; i++) {
      for (var j = 0; j < vSteps; j++) {
        canvas.drawLine(pts[i][j], pts[i][j + 1], stroke);
      }
      if (closedV) {
        canvas.drawLine(pts[i][vSteps], pts[i][0], stroke);
      }
    }

    // Center dot for orientation.
    final cp = project(preset.center.x, preset.center.y, preset.center.z);
    canvas.drawCircle(cp, 2.5, Paint()..color = color);
  }

  /// (u, v) parametric range + whether each parameter wraps. The
  /// painter draws closing segments when the range wraps so e.g.
  /// the ellipsoid forms a continuous mesh around the longitude.
  _QuadricGridSpec _quadricParametricRange(QuadricPreset preset) {
    final t = preset.tExtent;
    switch (preset.kind) {
      case QuadricKind.ellipsoid:
        return const _QuadricGridSpec(
          uMin: -math.pi / 2, uMax: math.pi / 2, // latitude
          vMin: 0, vMax: 2 * math.pi, // longitude
          closedU: false, closedV: true,
        );
      case QuadricKind.ellipticCone:
        return _QuadricGridSpec(
          uMin: -t, uMax: t, // axis t (cone has two nappes)
          vMin: 0, vMax: 2 * math.pi, // around-axis
          closedU: false, closedV: true,
        );
      case QuadricKind.ellipticCylinder:
        return _QuadricGridSpec(
          uMin: -t, uMax: t, // along z
          vMin: 0, vMax: 2 * math.pi, // around-axis
          closedU: false, closedV: true,
        );
      case QuadricKind.ellipticParaboloid:
        return _QuadricGridSpec(
          uMin: 0, uMax: t, // radial coord (z = c·u²)
          vMin: 0, vMax: 2 * math.pi,
          closedU: false, closedV: true,
        );
      case QuadricKind.hyperboloid1Sheet:
        return _QuadricGridSpec(
          uMin: -t, uMax: t, // sinh parameter
          vMin: 0, vMax: 2 * math.pi,
          closedU: false, closedV: true,
        );
      case QuadricKind.hyperboloid2Sheets:
        // Drawn as two sheets — sample u from 0 to t, but flip the
        // z sign on alternate halves. We do a single grid and use
        // the trick that the parametric form gives both sheets by
        // sweeping u over [-t, t] with a discontinuity at 0.
        return _QuadricGridSpec(
          uMin: -t,
          uMax: t,
          vMin: 0,
          vMax: 2 * math.pi,
          closedU: false,
          closedV: true,
        );
    }
  }

  /// Parametric sample for a quadric preset. Coordinates are
  /// pre-translated by `preset.center` so the wireframe sits
  /// at the right world location.
  Vector3 _quadricSample(QuadricPreset preset, double u, double v) {
    final cx = preset.center.x;
    final cy = preset.center.y;
    final cz = preset.center.z;
    final a = preset.a;
    final b = preset.b;
    final c = preset.c;
    switch (preset.kind) {
      case QuadricKind.ellipsoid:
        // u = latitude (-π/2..π/2), v = longitude (0..2π).
        final cosU = math.cos(u);
        return Vector3(
          cx + a * cosU * math.cos(v),
          cy + b * cosU * math.sin(v),
          cz + c * math.sin(u),
        );
      case QuadricKind.ellipticCone:
        // u = axis parameter (-t..t), v = around-axis (0..2π).
        return Vector3(
          cx + a * u * math.cos(v),
          cy + b * u * math.sin(v),
          cz + c * u,
        );
      case QuadricKind.ellipticCylinder:
        // u = along z (-t..t), v = around (0..2π).
        return Vector3(
          cx + a * math.cos(v),
          cy + b * math.sin(v),
          cz + u,
        );
      case QuadricKind.ellipticParaboloid:
        // u = radial (0..t), v = around (0..2π).
        // z/c = (x/a)² + (y/b)²  →  pick x = a·u·cos v, y = b·u·sin v,
        // z = c·u².
        return Vector3(
          cx + a * u * math.cos(v),
          cy + b * u * math.sin(v),
          cz + c * u * u,
        );
      case QuadricKind.hyperboloid1Sheet:
        // (x/a)² + (y/b)² − (z/c)² = 1
        // Parametrise as x = a·cosh(u)·cos(v), y = b·cosh(u)·sin(v),
        // z = c·sinh(u). u over (-t..t) gives the whole sheet.
        final coshU = (math.exp(u) + math.exp(-u)) / 2;
        final sinhU = (math.exp(u) - math.exp(-u)) / 2;
        return Vector3(
          cx + a * coshU * math.cos(v),
          cy + b * coshU * math.sin(v),
          cz + c * sinhU,
        );
      case QuadricKind.hyperboloid2Sheets:
        // (z/c)² − (x/a)² − (y/b)² = 1
        // Parametrise as x = a·sinh(u)·cos(v), y = b·sinh(u)·sin(v),
        // z = ±c·cosh(u). Sweep u from -t..t and pick the sign by
        // sign(u) — the two sheets connect at the discontinuity.
        // Visual artifact at u=0 is acceptable for V1; cleanup is
        // an A5 polish item.
        final abs = u.abs();
        final coshU = (math.exp(abs) + math.exp(-abs)) / 2;
        final sinhU = (math.exp(abs) - math.exp(-abs)) / 2;
        return Vector3(
          cx + a * sinhU * math.cos(v),
          cy + b * sinhU * math.sin(v),
          cz + c * coshU * (u < 0 ? -1 : 1),
        );
    }
  }

  // ----------------------------------------------------------------
  // P9-A4: intersection highlight overlays
  // ----------------------------------------------------------------

  void _drawPoint(
    Canvas canvas,
    Vector3 p,
    Offset Function(double, double, double) project,
    double range,
  ) {
    // Skip points that sit well outside the view cube — drawing them
    // at the projected screen position would float a bright dot
    // somewhere disconnected from the visible geometry.
    if (p.x.abs() > range * 1.5 ||
        p.y.abs() > range * 1.5 ||
        p.z.abs() > range * 1.5) {
      return;
    }
    final centerScreen = project(p.x, p.y, p.z);
    // Filled cyan dot + a white ring so it pops against any
    // background.
    canvas.drawCircle(
      centerScreen,
      6.0,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );
    canvas.drawCircle(
      centerScreen,
      4.5,
      Paint()..color = kIntersectionColor,
    );
  }

  void _drawIntersectionLine(
    Canvas canvas,
    LineIntersection li,
    Offset Function(double, double, double) project,
    double range,
  ) {
    // Reuse the slab-clipping logic from _drawLine. Inlined here so
    // the line-of-intersection draws even when no LineObject was
    // created for it.
    final p = li.point;
    final d = li.direction;
    final dLen2 = d.dot(d);
    if (dLen2 == 0) return;
    double tMin = double.negativeInfinity;
    double tMax = double.infinity;
    bool clipAxis(double pi, double di) {
      if (di.abs() < 1e-12) return pi.abs() <= range;
      final t1 = (-range - pi) / di;
      final t2 = (range - pi) / di;
      final lo = t1 < t2 ? t1 : t2;
      final hi = t1 < t2 ? t2 : t1;
      if (lo > tMin) tMin = lo;
      if (hi < tMax) tMax = hi;
      return tMin <= tMax;
    }

    if (!clipAxis(p.x, d.x) || !clipAxis(p.y, d.y) || !clipAxis(p.z, d.z)) {
      return;
    }
    final a = Vector3(p.x + tMin * d.x, p.y + tMin * d.y, p.z + tMin * d.z);
    final b = Vector3(p.x + tMax * d.x, p.y + tMax * d.y, p.z + tMax * d.z);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = kIntersectionColor;
    canvas.drawLine(project(a.x, a.y, a.z), project(b.x, b.y, b.z), stroke);
  }

  void _drawIntersectionCircle(
    Canvas canvas,
    CircleIntersection ci,
    Offset Function(double, double, double) project,
  ) {
    final n = ci.normal;
    final nLen2 = n.dot(n);
    if (nLen2 < 1e-12 || ci.radius <= 0) return;
    final nLen = math.sqrt(nLen2);
    // Build an orthonormal frame (u, v) in the circle plane.
    final seed =
        (n.x.abs() < 0.9) ? const Vector3(1, 0, 0) : const Vector3(0, 1, 0);
    final proj = seed.dot(n) / nLen2;
    final uRaw = Vector3(
      seed.x - proj * n.x,
      seed.y - proj * n.y,
      seed.z - proj * n.z,
    );
    final uLen = math.sqrt(uRaw.dot(uRaw));
    if (uLen == 0) return;
    final u = Vector3(uRaw.x / uLen, uRaw.y / uLen, uRaw.z / uLen);
    final vRaw = n.cross(u);
    final v = Vector3(vRaw.x / nLen, vRaw.y / nLen, vRaw.z / nLen);

    const samples = 48;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = kIntersectionColor;

    Offset? prev;
    for (var i = 0; i <= samples; i++) {
      final theta = 2 * math.pi * i / samples;
      final ct = math.cos(theta);
      final st = math.sin(theta);
      final x = ci.center.x + ci.radius * (u.x * ct + v.x * st);
      final y = ci.center.y + ci.radius * (u.y * ct + v.y * st);
      final z = ci.center.z + ci.radius * (u.z * ct + v.z * st);
      final screen = project(x, y, z);
      if (prev != null) canvas.drawLine(prev, screen, stroke);
      prev = screen;
    }
  }

  /// P9-A5b: plane × quadric → 2D conic in the plane's local
  /// frame. Render via marching-squares-style sampling: evaluate
  /// the implicit form `A·s² + B·s·t + C·t² + D·s + E·t + F = 0`
  /// on a grid in (s, t), find zero-crossings between adjacent
  /// cells, and draw line segments approximating the curve. Each
  /// (s, t) gets mapped back to 3D via `worldAt(s, t)` for the
  /// final projection.
  ///
  /// The plane-local sampling extent is `±range` (the scene's
  /// viewport range) so the rendered conic matches what the user
  /// sees of the plane patch + quadric wireframe.
  void _drawIntersectionConic(
    Canvas canvas,
    ConicSectionIntersection cs,
    Offset Function(double, double, double) project,
    double range,
  ) {
    const int n = 64;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = kIntersectionColor;
    final step = (2 * range) / n;

    // Precompute F at every grid corner.
    final values = List<List<double>>.generate(
      n + 1,
      (i) {
        final s = -range + i * step;
        return List<double>.generate(n + 1, (j) {
          final t = -range + j * step;
          return cs.evaluate(s, t);
        });
      },
    );

    // Linear interpolation along an edge: find where F goes
    // through zero between two corners.
    Offset lerp3D(
        double s1, double t1, double f1, double s2, double t2, double f2) {
      final w = f1 / (f1 - f2);
      final s = s1 + w * (s2 - s1);
      final t = t1 + w * (t2 - t1);
      final p = cs.worldAt(s, t);
      return project(p.x, p.y, p.z);
    }

    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        final s0 = -range + i * step;
        final s1 = s0 + step;
        final t0 = -range + j * step;
        final t1 = t0 + step;
        final f00 = values[i][j];
        final f10 = values[i + 1][j];
        final f11 = values[i + 1][j + 1];
        final f01 = values[i][j + 1];

        // Build the 4-bit case index in standard marching-squares
        // order. Bit i is set when corner i is "outside" (F > 0).
        var idx = 0;
        if (f00 > 0) idx |= 1;
        if (f10 > 0) idx |= 2;
        if (f11 > 0) idx |= 4;
        if (f01 > 0) idx |= 8;

        // Reject all-same cases (no crossing).
        if (idx == 0 || idx == 15) continue;

        // Compute edge intersections only for edges where F
        // actually changes sign. Edges indexed: 0=bottom (s0..s1,
        // t0), 1=right (s1, t0..t1), 2=top (s0..s1, t1), 3=left
        // (s0, t0..t1).
        Offset? edge(int e) {
          switch (e) {
            case 0:
              if (f00 * f10 > 0) return null;
              return lerp3D(s0, t0, f00, s1, t0, f10);
            case 1:
              if (f10 * f11 > 0) return null;
              return lerp3D(s1, t0, f10, s1, t1, f11);
            case 2:
              if (f01 * f11 > 0) return null;
              return lerp3D(s0, t1, f01, s1, t1, f11);
            case 3:
              if (f00 * f01 > 0) return null;
              return lerp3D(s0, t0, f00, s0, t1, f01);
          }
          return null;
        }

        // 15 case mask -> pairs of edges to connect. Saddle
        // cases (5, 10) get two segments; everything else is one.
        // We just collect all valid edge points and pair them
        // sequentially — simple and adequate for V1.
        final pts = <Offset>[];
        for (final e in [0, 1, 2, 3]) {
          final p = edge(e);
          if (p != null) pts.add(p);
        }
        for (var k = 0; k + 1 < pts.length; k += 2) {
          canvas.drawLine(pts[k], pts[k + 1], stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant Scene3DPainter old) =>
      old.scene != scene ||
      old.intersections != intersections ||
      old.scene.azimuth != scene.azimuth ||
      old.scene.elevation != scene.elevation ||
      old.scene.zoom != scene.zoom ||
      old.scene.range != scene.range;
}

/// (u, v) grid descriptor for a parametric quadric. `closedU` /
/// `closedV` say whether the parameter wraps so the painter can
/// draw the closing segment.
class _QuadricGridSpec {
  final double uMin, uMax, vMin, vMax;
  final bool closedU, closedV;
  const _QuadricGridSpec({
    required this.uMin,
    required this.uMax,
    required this.vMin,
    required this.vMax,
    required this.closedU,
    required this.closedV,
  });
}

// ----------------------------------------------------------------
// P9-A6: parametric surface + curve rendering
// ----------------------------------------------------------------

/// Lightweight per-process cache of evaluated parametric samples
/// so we don't pay SymEngine round-trips on every rotation frame.
/// Keyed by the full geometry hash (expression strings + ranges +
/// steps). FIFO eviction at 32 entries; user edits change the
/// hash, so old entries become unreachable and roll off naturally.
class _ParametricSampleCache {
  static const int _cap = 32;
  static final Map<String, List<List<Vector3>>> _surfaces = {};
  static final Map<String, List<Vector3>> _curves = {};
  static final CalculatorEngine _engine = CalculatorEngine();

  static String _surfaceKey(ParametricSurfaceObject o) =>
      '${o.exprX}|${o.exprY}|${o.exprZ}|'
      '${o.uMin}|${o.uMax}|${o.uSteps}|'
      '${o.vMin}|${o.vMax}|${o.vSteps}';

  static String _curveKey(ParametricCurveObject o) =>
      '${o.exprX}|${o.exprY}|${o.exprZ}|'
      '${o.tMin}|${o.tMax}|${o.steps}';

  static List<List<Vector3>> samplesFor(ParametricSurfaceObject o) {
    final key = _surfaceKey(o);
    final cached = _surfaces[key];
    if (cached != null) return cached;
    final samples = _evalSurface(o);
    _surfaces[key] = samples;
    if (_surfaces.length > _cap) {
      _surfaces.remove(_surfaces.keys.first);
    }
    return samples;
  }

  static List<Vector3> samplesForCurve(ParametricCurveObject o) {
    final key = _curveKey(o);
    final cached = _curves[key];
    if (cached != null) return cached;
    final samples = _evalCurve(o);
    _curves[key] = samples;
    if (_curves.length > _cap) {
      _curves.remove(_curves.keys.first);
    }
    return samples;
  }

  /// Evaluate one expression at the given (u, v) numerically.
  /// Mirrors the Graphing3DScreen `_evaluateAt` pattern:
  /// substitute coordinate values into the expression string, run
  /// through the preprocessor, evaluate via CalculatorEngine's
  /// numeric path. NaN on parse / eval errors so the painter can
  /// skip those samples.
  static double _evalAt2(String expr, double u, double v) {
    try {
      final us = u < 0 ? '($u)' : '$u';
      final vs = v < 0 ? '($v)' : '$v';
      var sub = expr.replaceAll(RegExp(r'\bu\b'), us);
      sub = sub.replaceAll(RegExp(r'\bv\b'), vs);
      final pre = ExpressionPreprocessingUtils.preprocessNativeExpression(sub);
      final result = _engine.evaluateForGraphing(pre);
      if (result.startsWith('Error') || result.isEmpty) return double.nan;
      return double.tryParse(result) ?? double.nan;
    } catch (_) {
      return double.nan;
    }
  }

  static double _evalAt1(String expr, double t) {
    try {
      final ts = t < 0 ? '($t)' : '$t';
      final sub = expr.replaceAll(RegExp(r'\bt\b'), ts);
      final pre = ExpressionPreprocessingUtils.preprocessNativeExpression(sub);
      final result = _engine.evaluateForGraphing(pre);
      if (result.startsWith('Error') || result.isEmpty) return double.nan;
      return double.tryParse(result) ?? double.nan;
    } catch (_) {
      return double.nan;
    }
  }

  static List<List<Vector3>> _evalSurface(ParametricSurfaceObject o) {
    final n = o.uSteps;
    final m = o.vSteps;
    final grid = List<List<Vector3>>.generate(
      n + 1,
      (i) {
        final u = o.uMin + (o.uMax - o.uMin) * i / n;
        return List<Vector3>.generate(m + 1, (j) {
          final v = o.vMin + (o.vMax - o.vMin) * j / m;
          return Vector3(
            _evalAt2(o.exprX, u, v),
            _evalAt2(o.exprY, u, v),
            _evalAt2(o.exprZ, u, v),
          );
        });
      },
    );
    return grid;
  }

  static List<Vector3> _evalCurve(ParametricCurveObject o) {
    return List<Vector3>.generate(o.steps + 1, (i) {
      final t = o.tMin + (o.tMax - o.tMin) * i / o.steps;
      return Vector3(
        _evalAt1(o.exprX, t),
        _evalAt1(o.exprY, t),
        _evalAt1(o.exprZ, t),
      );
    });
  }
}

void _drawParametricSurface(
  Canvas canvas,
  ParametricSurfaceObject o,
  Offset Function(double, double, double) project,
) {
  final grid = _ParametricSampleCache.samplesFor(o);
  if (grid.isEmpty || grid.first.isEmpty) return;
  final n = grid.length - 1;
  final m = grid.first.length - 1;
  final color = Color(o.color);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..color = color.withValues(alpha: 0.75);

  Offset? projectIfFinite(Vector3 p) {
    if (!p.x.isFinite || !p.y.isFinite || !p.z.isFinite) return null;
    return project(p.x, p.y, p.z);
  }

  // Pre-project once per cell corner.
  final screen = List<List<Offset?>>.generate(
    n + 1,
    (i) => List<Offset?>.generate(m + 1, (j) => projectIfFinite(grid[i][j])),
  );

  // u-direction (constant v) curves.
  for (var j = 0; j <= m; j++) {
    for (var i = 0; i < n; i++) {
      final a = screen[i][j];
      final b = screen[i + 1][j];
      if (a != null && b != null) canvas.drawLine(a, b, stroke);
    }
  }
  // v-direction (constant u) curves.
  for (var i = 0; i <= n; i++) {
    for (var j = 0; j < m; j++) {
      final a = screen[i][j];
      final b = screen[i][j + 1];
      if (a != null && b != null) canvas.drawLine(a, b, stroke);
    }
  }
}

void _drawParametricCurve(
  Canvas canvas,
  ParametricCurveObject o,
  Offset Function(double, double, double) project,
) {
  final samples = _ParametricSampleCache.samplesForCurve(o);
  if (samples.length < 2) return;
  final color = Color(o.color);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..color = color;

  Offset? prev;
  for (final p in samples) {
    if (!p.x.isFinite || !p.y.isFinite || !p.z.isFinite) {
      prev = null;
      continue;
    }
    final s = project(p.x, p.y, p.z);
    if (prev != null) canvas.drawLine(prev, s, stroke);
    prev = s;
  }
}
