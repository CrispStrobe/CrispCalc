// P9-A2: the 3D Scene module screen.
//
// User-facing entry point for the new 3D Scene module described in
// PLAN P9. V1 shows the (single global) [Scene3D] from AppState in
// a rotatable viewport, with an object-list panel for editing.
// A2 ships the Plane object only; A3 wires line + sphere; A4 adds
// pairwise intersections; A5 quadrics; A6 parametrics.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/app_state.dart';
import '../engine/scene_3d/intersections.dart';
import '../engine/scene_3d/scene_object.dart';
import '../localization/app_localizations.dart';
import '../widgets/scene_3d_intersections_panel.dart';
import '../widgets/scene_3d_object_dialogs.dart';
import '../widgets/scene_3d_painter.dart';

class Scene3DScreen extends StatefulWidget {
  const Scene3DScreen({super.key});

  @override
  State<Scene3DScreen> createState() => _Scene3DScreenState();
}

class _Scene3DScreenState extends State<Scene3DScreen> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _showAddSheet() async {
    final t = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.view_in_ar),
              title: Text(t.scene3DAddPlane),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final p = await showPlaneEditorDialog(context);
                if (p != null) _appState.addOrUpdateSceneObject(p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timeline),
              title: Text(t.scene3DAddLine),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final l = await showLineEditorDialog(context);
                if (l != null) _appState.addOrUpdateSceneObject(l);
              },
            ),
            ListTile(
              leading: const Icon(Icons.circle_outlined),
              title: Text(t.scene3DAddSphere),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final s = await showSphereEditorDialog(context);
                if (s != null) _appState.addOrUpdateSceneObject(s);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editObject(SceneObject obj) async {
    switch (obj) {
      case PlaneObject p:
        final updated = await showPlaneEditorDialog(context, existing: p);
        if (updated != null) _appState.addOrUpdateSceneObject(updated);
      case LineObject l:
        final updated = await showLineEditorDialog(context, existing: l);
        if (updated != null) _appState.addOrUpdateSceneObject(updated);
      case SphereObject s:
        final updated = await showSphereEditorDialog(context, existing: s);
        if (updated != null) _appState.addOrUpdateSceneObject(updated);
      case QuadricObject _:
      case ParametricSurfaceObject _:
      case ParametricCurveObject _:
        break;
    }
  }

  void _toggleVisibility(SceneObject obj) {
    final visible = !obj.visible;
    switch (obj) {
      case PlaneObject p:
        _appState.addOrUpdateSceneObject(PlaneObject(
          id: p.id,
          label: p.label,
          color: p.color,
          visible: visible,
          a: p.a,
          b: p.b,
          c: p.c,
          d: p.d,
        ));
      case LineObject l:
        _appState.addOrUpdateSceneObject(LineObject(
          id: l.id,
          label: l.label,
          color: l.color,
          visible: visible,
          point: l.point,
          direction: l.direction,
        ));
      case SphereObject s:
        _appState.addOrUpdateSceneObject(SphereObject(
          id: s.id,
          label: s.label,
          color: s.color,
          visible: visible,
          center: s.center,
          radius: s.radius,
        ));
      case QuadricObject _:
      case ParametricSurfaceObject _:
      case ParametricCurveObject _:
        break;
    }
  }

  /// Compute every pairwise intersection of visible objects. Cheap
  /// to recompute on each build for V1 — handful of objects, all
  /// closed-form math. Returned in (objectA, objectB, result) tuples
  /// so the panel can show the labels alongside the analytical
  /// description and the painter can highlight matching geometry.
  List<IntersectionEntry> _computeIntersections(List<SceneObject> objects) {
    final visible = objects.where((o) => o.visible).toList();
    final results = <IntersectionEntry>[];
    for (var i = 0; i < visible.length; i++) {
      for (var j = i + 1; j < visible.length; j++) {
        final res = intersect(visible[i], visible[j]);
        if (res == null) continue;
        results.add(IntersectionEntry(
          a: visible[i],
          b: visible[j],
          result: res,
        ));
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scene = _appState.scene3D;
    final wide = MediaQuery.of(context).size.width >= 720;
    final intersections = _computeIntersections(scene.objects);
    final intersectionResults =
        intersections.map((e) => e.result).toList(growable: false);

    final sidePanel = Column(
      children: [
        Expanded(
          flex: 3,
          child: _buildObjectPanel(context, t, scene.objects),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: Scene3DIntersectionsPanel(entries: intersections),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.module3DScene),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: t.resetView,
            onPressed: _appState.resetSceneViewport,
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildViewport(context, t, intersectionResults),
                ),
                SizedBox(width: 340, child: sidePanel),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: _buildViewport(context, t, intersectionResults),
                ),
                SizedBox(height: 280, child: sidePanel),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(t.scene3DAddObject),
        onPressed: _showAddSheet,
      ),
    );
  }

  Widget _buildViewport(
    BuildContext context,
    AppLocalizations t,
    List<Intersection> intersections,
  ) {
    final scene = _appState.scene3D;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: GestureDetector(
        onScaleStart: (_) {},
        onScaleUpdate: (d) {
          final newAz = scene.azimuth - d.focalPointDelta.dx * 0.01;
          final newEl = (scene.elevation + d.focalPointDelta.dy * 0.01)
              .clamp(-math.pi / 2 + 0.01, math.pi / 2 - 0.01);
          final newZoom = d.scale != 1.0
              ? (scene.zoom * d.scale).clamp(0.2, 5.0)
              : scene.zoom;
          _appState.updateSceneViewport(
            azimuth: newAz,
            elevation: newEl,
            zoom: newZoom,
          );
        },
        child: CustomPaint(
          painter: Scene3DPainter(
            scene: scene,
            intersections: intersections,
          ),
          size: Size.infinite,
          child: scene.objects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      t.scene3DEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildObjectPanel(
    BuildContext context,
    AppLocalizations t,
    List<SceneObject> objects,
  ) {
    if (objects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            t.scene3DPanelEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: objects.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        _appState.reorderSceneObjects(oldIndex, newIndex);
      },
      itemBuilder: (ctx, i) {
        final obj = objects[i];
        return ListTile(
          key: ValueKey(obj.id),
          leading: ReorderableDragStartListener(
            index: i,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Color(obj.color),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: obj.visible ? Colors.transparent : Colors.grey,
                  width: 1.5,
                ),
              ),
            ),
          ),
          title: Text(obj.label),
          subtitle: Text(
            _subtitleFor(obj),
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  obj.visible ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                tooltip: obj.visible ? t.scene3DHide : t.scene3DShow,
                onPressed: () => _toggleVisibility(obj),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: t.scene3DEdit,
                onPressed: () => _editObject(obj),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: t.scene3DDelete,
                onPressed: () => _appState.removeSceneObject(obj.id),
              ),
            ],
          ),
        );
      },
    );
  }

  String _subtitleFor(SceneObject obj) {
    switch (obj) {
      case PlaneObject p:
        final parts = <String>[];
        void add(double v, String letter) {
          if (v == 0) return;
          final sign =
              parts.isEmpty ? (v < 0 ? '-' : '') : (v < 0 ? ' - ' : ' + ');
          final abs = v.abs();
          final coef = (abs == 1 && letter.isNotEmpty) ? '' : _fmt(abs);
          parts.add('$sign$coef$letter');
        }
        add(p.a, 'x');
        add(p.b, 'y');
        add(p.c, 'z');
        return '${parts.isEmpty ? '0' : parts.join('')} = ${_fmt(p.d)}';
      case LineObject l:
        return '${_pt(l.point)} + t·${_pt(l.direction)}';
      case SphereObject s:
        return '|x − ${_pt(s.center)}| = ${_fmt(s.radius)}';
      case QuadricObject _:
        return 'Quadric';
      case ParametricSurfaceObject _:
        return 'Parametric surface';
      case ParametricCurveObject _:
        return 'Parametric curve';
    }
  }

  static String _pt(dynamic v) {
    // Vector3 from plane_math, but typed dynamic here so this method
    // doesn't have to import it just for formatting.
    return '(${_fmt(v.x as double)}, ${_fmt(v.y as double)}, ${_fmt(v.z as double)})';
  }

  static String _fmt(double v) {
    if ((v - v.roundToDouble()).abs() < 1e-9) return v.toInt().toString();
    return v
        .toStringAsPrecision(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
