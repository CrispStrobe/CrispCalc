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

import '../engine/plane_math.dart' show Vector3;
import '../engine/scene_3d/intersections.dart';
import '../engine/scene_3d/scene_object.dart';
import '../engine/scene_3d/scene_state.dart';

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
        case QuadricObject _:
        case ParametricSurfaceObject _:
        case ParametricCurveObject _:
          // Rendering for these kinds lands in A5 / A6.
          break;
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

  @override
  bool shouldRepaint(covariant Scene3DPainter old) =>
      old.scene != scene ||
      old.intersections != intersections ||
      old.scene.azimuth != scene.azimuth ||
      old.scene.elevation != scene.elevation ||
      old.scene.zoom != scene.zoom ||
      old.scene.range != scene.range;
}
