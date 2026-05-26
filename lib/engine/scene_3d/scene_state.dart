// P9-A1: container for a 3D scene — an ordered list of [SceneObject]s
// plus viewport state. JSON-round-trippable so it can be persisted
// in shared_preferences alongside notepad documents and user
// variables (round A2 will wire this into AppState; round A1 just
// defines the container).

import 'scene_object.dart';

/// Default viewport — same starting orientation as Graphing3DScreen
/// so the new module feels visually familiar.
const double kDefaultSceneAzimuth = 0.5;
const double kDefaultSceneElevation = 0.6;
const double kDefaultSceneZoom = 1.0;
const double kDefaultSceneRange = 5.0;

/// A 3D scene is an ordered list of [SceneObject]s plus the
/// viewport orientation used by the renderer. Persisting the
/// viewport with the scene lets the user reopen a scene at the
/// angle they last left it.
class Scene3D {
  /// Stable id for cross-scene references (round A6 plans
  /// `{scene:taxes}.intersect(plane1, sphere2)`-style lookups; A1
  /// just needs the id present in JSON).
  final String id;

  String name;
  final List<SceneObject> objects;

  double azimuth;
  double elevation;
  double zoom;

  /// World-space radius for the rendered region (axes + viewport
  /// extent). The renderer clamps drawing to ±range; objects
  /// outside still participate in intersection math.
  double range;

  Scene3D({
    required this.id,
    required this.name,
    List<SceneObject>? objects,
    this.azimuth = kDefaultSceneAzimuth,
    this.elevation = kDefaultSceneElevation,
    this.zoom = kDefaultSceneZoom,
    this.range = kDefaultSceneRange,
  }) : objects = objects ?? <SceneObject>[];

  factory Scene3D.empty({String? id, String? name}) => Scene3D(
        id: id ?? generateSceneObjectId(),
        name: name ?? 'Scene',
      );

  Map<String, dynamic> toJson() => {
        'i': id,
        'n': name,
        'o': objects.map((o) => o.toJson()).toList(growable: false),
        'az': azimuth,
        'el': elevation,
        'zo': zoom,
        'rg': range,
      };

  static Scene3D fromJson(Map<String, dynamic> j) {
    final rawObjects = (j['o'] as List<dynamic>? ?? const []);
    final objects = <SceneObject>[];
    for (final raw in rawObjects) {
      if (raw is Map<String, dynamic>) {
        objects.add(SceneObject.fromJson(raw));
      } else if (raw is Map) {
        objects.add(SceneObject.fromJson(Map<String, dynamic>.from(raw)));
      }
    }
    return Scene3D(
      id: j['i'] as String? ?? generateSceneObjectId(),
      name: j['n'] as String? ?? 'Scene',
      objects: objects,
      azimuth: (j['az'] as num?)?.toDouble() ?? kDefaultSceneAzimuth,
      elevation: (j['el'] as num?)?.toDouble() ?? kDefaultSceneElevation,
      zoom: (j['zo'] as num?)?.toDouble() ?? kDefaultSceneZoom,
      range: (j['rg'] as num?)?.toDouble() ?? kDefaultSceneRange,
    );
  }

  /// Replace the object at the same id, or append when no match.
  /// Returns a new scene; the caller is expected to drive the
  /// AppState mutation (round A2 wires that).
  Scene3D withObject(SceneObject obj) {
    final next = List<SceneObject>.from(objects);
    final idx = next.indexWhere((o) => o.id == obj.id);
    if (idx >= 0) {
      next[idx] = obj;
    } else {
      next.add(obj);
    }
    return Scene3D(
      id: id,
      name: name,
      objects: next,
      azimuth: azimuth,
      elevation: elevation,
      zoom: zoom,
      range: range,
    );
  }

  Scene3D withoutObject(String objectId) {
    final next = objects.where((o) => o.id != objectId).toList();
    return Scene3D(
      id: id,
      name: name,
      objects: next,
      azimuth: azimuth,
      elevation: elevation,
      zoom: zoom,
      range: range,
    );
  }

  /// Move the object at [oldIndex] to [newIndex]. Mirrors the
  /// [ReorderableListView] index semantics: when moving down,
  /// `newIndex` is the destination after the item is removed (i.e.
  /// the caller passes a one-past-the-target value). Returns a new
  /// scene on success, or the same scene on out-of-bounds.
  Scene3D withReorderedObjects(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= objects.length) return this;
    if (newIndex < 0 || newIndex > objects.length) return this;
    final next = List<SceneObject>.from(objects);
    final item = next.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    next.insert(insertAt, item);
    return Scene3D(
      id: id,
      name: name,
      objects: next,
      azimuth: azimuth,
      elevation: elevation,
      zoom: zoom,
      range: range,
    );
  }
}
