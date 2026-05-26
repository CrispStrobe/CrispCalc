// P9-A4: results panel shown below the object list on the 3D Scene
// screen. Lists every pairwise intersection of visible objects with
// the analytical description.

import 'package:flutter/material.dart';

import '../engine/plane_math.dart' show Vector3;
import '../engine/scene_3d/intersections.dart';
import '../engine/scene_3d/scene_object.dart';
import '../localization/app_localizations.dart';

/// Bundles a [SceneObject] pair with their [Intersection] result so
/// the panel can show "Plane 1 × Plane 2: Line through (0, 0, 0)
/// with direction (1, 0, 0)" alongside the highlighted geometry.
class IntersectionEntry {
  final SceneObject a;
  final SceneObject b;
  final Intersection result;
  const IntersectionEntry({
    required this.a,
    required this.b,
    required this.result,
  });
}

class Scene3DIntersectionsPanel extends StatelessWidget {
  final List<IntersectionEntry> entries;

  const Scene3DIntersectionsPanel({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            t.scene3DIntersectionsEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            t.scene3DIntersectionsTitle(entries.length),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final entry = entries[i];
              return ListTile(
                dense: true,
                title: Text(
                  '${entry.a.label} ∩ ${entry.b.label}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _describe(entry.result, t),
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Localized description of an intersection result. Kept as a
/// free function so the painter (which only needs to draw, not
/// describe) doesn't pull the localizations dep.
String _describe(Intersection result, AppLocalizations t) {
  switch (result) {
    case NoIntersection r:
      return t.intersectionReason(r.reasonKey);
    case PointIntersection p:
      return '${t.intersectionPoint}: ${_pt(p.point)}';
    case TwoPointsIntersection p:
      return '${t.intersectionTwoPoints}: ${_pt(p.a)}, ${_pt(p.b)}';
    case LineIntersection l:
      return '${t.intersectionLine}: P=${_pt(l.point)}, '
          'D=${_pt(l.direction)}';
    case CircleIntersection c:
      return '${t.intersectionCircle}: C=${_pt(c.center)}, '
          'r=${_fmt(c.radius)}, n=${_pt(c.normal)}';
    case CoincidentIntersection r:
      return t.intersectionReason(r.reasonKey);
    case ContainedIntersection r:
      return t.intersectionReason(r.reasonKey);
  }
}

String _pt(Vector3 v) => '(${_fmt(v.x)}, ${_fmt(v.y)}, ${_fmt(v.z)})';

String _fmt(double v) {
  if ((v - v.roundToDouble()).abs() < 1e-9) return v.toInt().toString();
  return v
      .toStringAsPrecision(6)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
