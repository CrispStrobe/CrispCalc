// P9-A2 + A3: dialogs for adding / editing scene objects. A2 ships
// the Add/Edit Plane dialog; A3 adds Line + Sphere; A5 / A6 follow
// with quadric + parametric.

import 'package:flutter/material.dart';

import '../engine/plane_math.dart' show Vector3;
import '../engine/scene_3d/scene_object.dart';
import '../localization/app_localizations.dart';

/// Curated palette of distinguishable colors used by the scene
/// object pickers. Each kind gets a default index so freshly
/// created objects don't all start the same color.
const List<int> kSceneObjectPalette = [
  0xFFE53935, // red
  0xFF1E88E5, // blue
  0xFF43A047, // green
  0xFFFB8C00, // orange
  0xFF8E24AA, // purple
  0xFFFDD835, // amber
  0xFF00897B, // teal
  0xFF6D4C41, // brown
];

/// Show the Add/Edit Plane dialog. Returns the new / edited
/// [PlaneObject] on save, or null if cancelled.
Future<PlaneObject?> showPlaneEditorDialog(
  BuildContext context, {
  PlaneObject? existing,
  int defaultColor = 0xFF1E88E5,
}) async {
  final t = AppLocalizations.of(context);
  final labelCtrl = TextEditingController(text: existing?.label ?? 'Plane');
  final aCtrl = TextEditingController(text: (existing?.a ?? 1).toString());
  final bCtrl = TextEditingController(text: (existing?.b ?? 0).toString());
  final cCtrl = TextEditingController(text: (existing?.c ?? 0).toString());
  final dCtrl = TextEditingController(text: (existing?.d ?? 0).toString());
  var color = existing?.color ?? defaultColor;
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<PlaneObject>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setStateDlg) {
        return AlertDialog(
          title:
              Text(existing == null ? t.scene3DAddPlane : t.scene3DEditPlane),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'a·x + b·y + c·z = d',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      labelText: t.scene3DObjectLabel,
                      isDense: true,
                    ),
                    validator: (s) => (s?.trim().isEmpty ?? true)
                        ? t.scene3DLabelRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _coef(aCtrl, 'a', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(bCtrl, 'b', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(cCtrl, 'c', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(dCtrl, 'd', t)),
                  ]),
                  const SizedBox(height: 16),
                  Text(
                    t.scene3DColor,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final swatch in kSceneObjectPalette)
                        _ColorSwatch(
                          color: Color(swatch),
                          selected: color == swatch,
                          onTap: () => setStateDlg(() => color = swatch),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final a = double.tryParse(aCtrl.text.trim()) ?? 0;
                final b = double.tryParse(bCtrl.text.trim()) ?? 0;
                final c = double.tryParse(cCtrl.text.trim()) ?? 0;
                final d = double.tryParse(dCtrl.text.trim()) ?? 0;
                if (a == 0 && b == 0 && c == 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(t.scene3DPlaneZeroNormal),
                    duration: const Duration(seconds: 2),
                  ));
                  return;
                }
                Navigator.of(ctx).pop(PlaneObject(
                  id: existing?.id ?? generateSceneObjectId(),
                  label: labelCtrl.text.trim(),
                  color: color,
                  visible: existing?.visible ?? true,
                  a: a,
                  b: b,
                  c: c,
                  d: d,
                ));
              },
              child: Text(existing == null ? t.scene3DAdd : t.scene3DSave),
            ),
          ],
        );
      });
    },
  );
  return saved;
}

Widget _coef(TextEditingController c, String label, AppLocalizations t) {
  return TextFormField(
    controller: c,
    keyboardType:
        const TextInputType.numberWithOptions(signed: true, decimal: true),
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    validator: (s) {
      final v = s?.trim() ?? '';
      if (v.isEmpty) return t.scene3DCoefRequired;
      if (double.tryParse(v) == null) return t.scene3DCoefInvalid;
      return null;
    },
  );
}

enum _LineInputMode { pointDirection, twoPoints }

/// Show the Add/Edit Line dialog. Returns the new / edited
/// [LineObject] on save, or null if cancelled. The user can pick
/// between point+direction and two-points input modes; the
/// underlying storage is always point+direction (the second mode
/// derives a direction from `q - p`).
Future<LineObject?> showLineEditorDialog(
  BuildContext context, {
  LineObject? existing,
  int defaultColor = 0xFF43A047,
}) async {
  final t = AppLocalizations.of(context);
  final labelCtrl = TextEditingController(text: existing?.label ?? 'Line');
  final px = TextEditingController(text: (existing?.point.x ?? 0).toString());
  final py = TextEditingController(text: (existing?.point.y ?? 0).toString());
  final pz = TextEditingController(text: (existing?.point.z ?? 0).toString());
  final dx =
      TextEditingController(text: (existing?.direction.x ?? 1).toString());
  final dy =
      TextEditingController(text: (existing?.direction.y ?? 0).toString());
  final dz =
      TextEditingController(text: (existing?.direction.z ?? 0).toString());
  var color = existing?.color ?? defaultColor;
  var mode = _LineInputMode.pointDirection;
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<LineObject>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setStateDlg) {
        return AlertDialog(
          title: Text(existing == null ? t.scene3DAddLine : t.scene3DEditLine),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<_LineInputMode>(
                    segments: [
                      ButtonSegment(
                        value: _LineInputMode.pointDirection,
                        label: Text(t.scene3DLinePointDir),
                      ),
                      ButtonSegment(
                        value: _LineInputMode.twoPoints,
                        label: Text(t.scene3DLineTwoPoints),
                      ),
                    ],
                    selected: {mode},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setStateDlg(() => mode = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      labelText: t.scene3DObjectLabel,
                      isDense: true,
                    ),
                    validator: (s) => (s?.trim().isEmpty ?? true)
                        ? t.scene3DLabelRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mode == _LineInputMode.pointDirection
                        ? t.scene3DLinePoint
                        : t.scene3DLineFirstPoint,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: _coef(px, 'x', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(py, 'y', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(pz, 'z', t)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    mode == _LineInputMode.pointDirection
                        ? t.scene3DLineDirection
                        : t.scene3DLineSecondPoint,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: _coef(dx, 'x', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(dy, 'y', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(dz, 'z', t)),
                  ]),
                  const SizedBox(height: 16),
                  Text(t.scene3DColor,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final swatch in kSceneObjectPalette)
                      _ColorSwatch(
                        color: Color(swatch),
                        selected: color == swatch,
                        onTap: () => setStateDlg(() => color = swatch),
                      ),
                  ]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final p = Vector3(
                  double.tryParse(px.text.trim()) ?? 0,
                  double.tryParse(py.text.trim()) ?? 0,
                  double.tryParse(pz.text.trim()) ?? 0,
                );
                final second = Vector3(
                  double.tryParse(dx.text.trim()) ?? 0,
                  double.tryParse(dy.text.trim()) ?? 0,
                  double.tryParse(dz.text.trim()) ?? 0,
                );
                final dir = mode == _LineInputMode.pointDirection
                    ? second
                    : Vector3(second.x - p.x, second.y - p.y, second.z - p.z);
                if (dir.x == 0 && dir.y == 0 && dir.z == 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(t.scene3DLineZeroDirection),
                    duration: const Duration(seconds: 2),
                  ));
                  return;
                }
                Navigator.of(ctx).pop(LineObject(
                  id: existing?.id ?? generateSceneObjectId(),
                  label: labelCtrl.text.trim(),
                  color: color,
                  visible: existing?.visible ?? true,
                  point: p,
                  direction: dir,
                ));
              },
              child: Text(existing == null ? t.scene3DAdd : t.scene3DSave),
            ),
          ],
        );
      });
    },
  );
  return saved;
}

/// Show the Add/Edit Sphere dialog. Returns the new / edited
/// [SphereObject] on save, or null if cancelled.
Future<SphereObject?> showSphereEditorDialog(
  BuildContext context, {
  SphereObject? existing,
  int defaultColor = 0xFFFB8C00,
}) async {
  final t = AppLocalizations.of(context);
  final labelCtrl = TextEditingController(text: existing?.label ?? 'Sphere');
  final cx = TextEditingController(text: (existing?.center.x ?? 0).toString());
  final cy = TextEditingController(text: (existing?.center.y ?? 0).toString());
  final cz = TextEditingController(text: (existing?.center.z ?? 0).toString());
  final radius =
      TextEditingController(text: (existing?.radius ?? 1).toString());
  var color = existing?.color ?? defaultColor;
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<SphereObject>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setStateDlg) {
        return AlertDialog(
          title:
              Text(existing == null ? t.scene3DAddSphere : t.scene3DEditSphere),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      labelText: t.scene3DObjectLabel,
                      isDense: true,
                    ),
                    validator: (s) => (s?.trim().isEmpty ?? true)
                        ? t.scene3DLabelRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(t.scene3DSphereCenter,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: _coef(cx, 'x', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(cy, 'y', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(cz, 'z', t)),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: radius,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: t.scene3DSphereRadius,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (s) {
                      final v = double.tryParse(s?.trim() ?? '');
                      if (v == null) return t.scene3DCoefInvalid;
                      if (v <= 0) return t.scene3DSpherePositiveRadius;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(t.scene3DColor,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final swatch in kSceneObjectPalette)
                      _ColorSwatch(
                        color: Color(swatch),
                        selected: color == swatch,
                        onTap: () => setStateDlg(() => color = swatch),
                      ),
                  ]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.of(ctx).pop(SphereObject(
                  id: existing?.id ?? generateSceneObjectId(),
                  label: labelCtrl.text.trim(),
                  color: color,
                  visible: existing?.visible ?? true,
                  center: Vector3(
                    double.tryParse(cx.text.trim()) ?? 0,
                    double.tryParse(cy.text.trim()) ?? 0,
                    double.tryParse(cz.text.trim()) ?? 0,
                  ),
                  radius: double.tryParse(radius.text.trim()) ?? 1,
                ));
              },
              child: Text(existing == null ? t.scene3DAdd : t.scene3DSave),
            ),
          ],
        );
      });
    },
  );
  return saved;
}

/// Show the Add/Edit Quadric dialog. Preset-based: the user picks
/// a kind (ellipsoid / cone / cylinder / paraboloid /
/// hyperboloid-1-sheet / hyperboloid-2-sheets) + center + semi-
/// axes (a, b, c). The dialog builds the [QuadricPreset]; the
/// caller stores the resulting [QuadricObject] which also carries
/// the derived 10-coefficient canonical form for downstream math.
Future<QuadricObject?> showQuadricEditorDialog(
  BuildContext context, {
  QuadricObject? existing,
  int defaultColor = 0xFF8E24AA,
}) async {
  final t = AppLocalizations.of(context);
  final initialPreset = existing?.preset ??
      const QuadricPreset(
        kind: QuadricKind.ellipsoid,
        center: Vector3(0, 0, 0),
        a: 2,
        b: 2,
        c: 2,
      );
  final labelCtrl =
      TextEditingController(text: existing?.label ?? t.quadricKindEllipsoid);
  final cx = TextEditingController(text: initialPreset.center.x.toString());
  final cy = TextEditingController(text: initialPreset.center.y.toString());
  final cz = TextEditingController(text: initialPreset.center.z.toString());
  final aCtrl = TextEditingController(text: initialPreset.a.toString());
  final bCtrl = TextEditingController(text: initialPreset.b.toString());
  final cCtrl = TextEditingController(text: initialPreset.c.toString());
  var kind = initialPreset.kind;
  var color = existing?.color ?? defaultColor;
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<QuadricObject>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setStateDlg) {
        return AlertDialog(
          title: Text(
              existing == null ? t.scene3DAddQuadric : t.scene3DEditQuadric),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.scene3DQuadricKind,
                        style: Theme.of(ctx).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<QuadricKind>(
                      initialValue: kind,
                      isExpanded: true,
                      items: [
                        for (final k in QuadricKind.values)
                          DropdownMenuItem(
                            value: k,
                            child:
                                Text(_quadricKindLabel(k, t), softWrap: false),
                          ),
                      ],
                      onChanged: (k) {
                        if (k == null) return;
                        setStateDlg(() => kind = k);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: labelCtrl,
                      decoration: InputDecoration(
                        labelText: t.scene3DObjectLabel,
                        isDense: true,
                      ),
                      validator: (s) => (s?.trim().isEmpty ?? true)
                          ? t.scene3DLabelRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(t.scene3DSphereCenter,
                        style: Theme.of(ctx).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: _coef(cx, 'x', t)),
                      const SizedBox(width: 8),
                      Expanded(child: _coef(cy, 'y', t)),
                      const SizedBox(width: 8),
                      Expanded(child: _coef(cz, 'z', t)),
                    ]),
                    const SizedBox(height: 12),
                    Text(t.scene3DQuadricSemiAxes,
                        style: Theme.of(ctx).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: _coef(aCtrl, 'a', t)),
                      const SizedBox(width: 8),
                      Expanded(child: _coef(bCtrl, 'b', t)),
                      const SizedBox(width: 8),
                      Expanded(child: _coef(cCtrl, 'c', t)),
                    ]),
                    const SizedBox(height: 16),
                    Text(t.scene3DColor,
                        style: Theme.of(ctx).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final swatch in kSceneObjectPalette)
                        _ColorSwatch(
                          color: Color(swatch),
                          selected: color == swatch,
                          onTap: () => setStateDlg(() => color = swatch),
                        ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final a = double.tryParse(aCtrl.text.trim()) ?? 1;
                final b = double.tryParse(bCtrl.text.trim()) ?? 1;
                final c = double.tryParse(cCtrl.text.trim()) ?? 1;
                if (a <= 0 || b <= 0 || c <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(t.scene3DQuadricPositiveSemiAxes),
                    duration: const Duration(seconds: 2),
                  ));
                  return;
                }
                final preset = QuadricPreset(
                  kind: kind,
                  center: Vector3(
                    double.tryParse(cx.text.trim()) ?? 0,
                    double.tryParse(cy.text.trim()) ?? 0,
                    double.tryParse(cz.text.trim()) ?? 0,
                  ),
                  a: a,
                  b: b,
                  c: c,
                );
                Navigator.of(ctx).pop(QuadricObject.fromPreset(
                  id: existing?.id ?? generateSceneObjectId(),
                  label: labelCtrl.text.trim(),
                  color: color,
                  visible: existing?.visible ?? true,
                  preset: preset,
                ));
              },
              child: Text(existing == null ? t.scene3DAdd : t.scene3DSave),
            ),
          ],
        );
      });
    },
  );
  return saved;
}

String _quadricKindLabel(QuadricKind k, AppLocalizations t) {
  switch (k) {
    case QuadricKind.ellipsoid:
      return t.quadricKindEllipsoid;
    case QuadricKind.ellipticCone:
      return t.quadricKindCone;
    case QuadricKind.ellipticCylinder:
      return t.quadricKindCylinder;
    case QuadricKind.ellipticParaboloid:
      return t.quadricKindParaboloid;
    case QuadricKind.hyperboloid1Sheet:
      return t.quadricKindHyperboloid1;
    case QuadricKind.hyperboloid2Sheets:
      return t.quadricKindHyperboloid2;
  }
}

/// P9-A6: Add/Edit Parametric Surface dialog.
/// `r(u, v) = (x(u, v), y(u, v), z(u, v))` evaluated via the
/// shared CalculatorEngine pipeline. Defaults render a torus.
Future<ParametricSurfaceObject?> showParametricSurfaceEditorDialog(
  BuildContext context, {
  ParametricSurfaceObject? existing,
  int defaultColor = 0xFF00897B,
}) async {
  final t = AppLocalizations.of(context);
  final labelCtrl = TextEditingController(
      text: existing?.label ?? t.scene3DParametricSurface);
  final exX =
      TextEditingController(text: existing?.exprX ?? '(2 + cos(v)) * cos(u)');
  final exY =
      TextEditingController(text: existing?.exprY ?? '(2 + cos(v)) * sin(u)');
  final exZ = TextEditingController(text: existing?.exprZ ?? 'sin(v)');
  final uMin = TextEditingController(text: (existing?.uMin ?? 0).toString());
  final uMax =
      TextEditingController(text: (existing?.uMax ?? 6.2832).toString());
  final vMin = TextEditingController(text: (existing?.vMin ?? 0).toString());
  final vMax =
      TextEditingController(text: (existing?.vMax ?? 6.2832).toString());
  final uSteps =
      TextEditingController(text: (existing?.uSteps ?? 18).toString());
  final vSteps =
      TextEditingController(text: (existing?.vSteps ?? 18).toString());
  var color = existing?.color ?? defaultColor;
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<ParametricSurfaceObject>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDlg) {
      return AlertDialog(
        title: Text(existing == null
            ? t.scene3DAddParametricSurface
            : t.scene3DEditParametricSurface),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      labelText: t.scene3DObjectLabel,
                      isDense: true,
                    ),
                    validator: (s) => (s?.trim().isEmpty ?? true)
                        ? t.scene3DLabelRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _exprField(exX, 'x(u, v)', t),
                  const SizedBox(height: 6),
                  _exprField(exY, 'y(u, v)', t),
                  const SizedBox(height: 6),
                  _exprField(exZ, 'z(u, v)', t),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _coef(uMin, 'u min', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(uMax, 'u max', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _intField(uSteps, 'u steps', t)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _coef(vMin, 'v min', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(vMax, 'v max', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _intField(vSteps, 'v steps', t)),
                  ]),
                  const SizedBox(height: 16),
                  Text(t.scene3DColor,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final swatch in kSceneObjectPalette)
                      _ColorSwatch(
                        color: Color(swatch),
                        selected: color == swatch,
                        onTap: () => setStateDlg(() => color = swatch),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(ctx).pop(ParametricSurfaceObject(
                id: existing?.id ?? generateSceneObjectId(),
                label: labelCtrl.text.trim(),
                color: color,
                visible: existing?.visible ?? true,
                exprX: exX.text.trim(),
                exprY: exY.text.trim(),
                exprZ: exZ.text.trim(),
                uMin: double.tryParse(uMin.text.trim()) ?? 0,
                uMax: double.tryParse(uMax.text.trim()) ?? 1,
                vMin: double.tryParse(vMin.text.trim()) ?? 0,
                vMax: double.tryParse(vMax.text.trim()) ?? 1,
                uSteps: int.tryParse(uSteps.text.trim()) ?? 18,
                vSteps: int.tryParse(vSteps.text.trim()) ?? 18,
              ));
            },
            child: Text(existing == null ? t.scene3DAdd : t.scene3DSave),
          ),
        ],
      );
    }),
  );
  return saved;
}

/// P9-A6: Add/Edit Parametric Curve dialog. Defaults render a
/// helix.
Future<ParametricCurveObject?> showParametricCurveEditorDialog(
  BuildContext context, {
  ParametricCurveObject? existing,
  int defaultColor = 0xFFFDD835,
}) async {
  final t = AppLocalizations.of(context);
  final labelCtrl =
      TextEditingController(text: existing?.label ?? t.scene3DParametricCurve);
  final exX = TextEditingController(text: existing?.exprX ?? 'cos(t)');
  final exY = TextEditingController(text: existing?.exprY ?? 'sin(t)');
  final exZ = TextEditingController(text: existing?.exprZ ?? 't/5');
  final tMin = TextEditingController(text: (existing?.tMin ?? 0).toString());
  final tMax =
      TextEditingController(text: (existing?.tMax ?? 12.5664).toString());
  final steps =
      TextEditingController(text: (existing?.steps ?? 100).toString());
  var color = existing?.color ?? defaultColor;
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<ParametricCurveObject>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setStateDlg) {
      return AlertDialog(
        title: Text(existing == null
            ? t.scene3DAddParametricCurve
            : t.scene3DEditParametricCurve),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      labelText: t.scene3DObjectLabel,
                      isDense: true,
                    ),
                    validator: (s) => (s?.trim().isEmpty ?? true)
                        ? t.scene3DLabelRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _exprField(exX, 'x(t)', t),
                  const SizedBox(height: 6),
                  _exprField(exY, 'y(t)', t),
                  const SizedBox(height: 6),
                  _exprField(exZ, 'z(t)', t),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _coef(tMin, 't min', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _coef(tMax, 't max', t)),
                    const SizedBox(width: 8),
                    Expanded(child: _intField(steps, 'steps', t)),
                  ]),
                  const SizedBox(height: 16),
                  Text(t.scene3DColor,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final swatch in kSceneObjectPalette)
                      _ColorSwatch(
                        color: Color(swatch),
                        selected: color == swatch,
                        onTap: () => setStateDlg(() => color = swatch),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(ctx).pop(ParametricCurveObject(
                id: existing?.id ?? generateSceneObjectId(),
                label: labelCtrl.text.trim(),
                color: color,
                visible: existing?.visible ?? true,
                exprX: exX.text.trim(),
                exprY: exY.text.trim(),
                exprZ: exZ.text.trim(),
                tMin: double.tryParse(tMin.text.trim()) ?? 0,
                tMax: double.tryParse(tMax.text.trim()) ?? 1,
                steps: int.tryParse(steps.text.trim()) ?? 100,
              ));
            },
            child: Text(existing == null ? t.scene3DAdd : t.scene3DSave),
          ),
        ],
      );
    }),
  );
  return saved;
}

Widget _exprField(TextEditingController c, String label, AppLocalizations t) {
  return TextFormField(
    controller: c,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      hintStyle: const TextStyle(fontFamily: 'monospace'),
    ),
    style: const TextStyle(fontFamily: 'monospace'),
    validator: (s) =>
        (s?.trim().isEmpty ?? true) ? t.scene3DCoefRequired : null,
  );
}

Widget _intField(TextEditingController c, String label, AppLocalizations t) {
  return TextFormField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(),
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    validator: (s) {
      final v = int.tryParse(s?.trim() ?? '');
      if (v == null || v < 2) return t.scene3DCoefInvalid;
      return null;
    },
  );
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2.5,
          ),
        ),
      ),
    );
  }
}
