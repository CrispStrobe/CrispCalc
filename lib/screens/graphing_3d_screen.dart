// lib/screens/graphing_3d_screen.dart
//
// V1 of 3D surface graphing — z = f(x, y) over a rectangular x/y
// range, rendered as a rotated wireframe. Hand-rolled rotation matrix
// (no vector_math dep) and orthographic projection. Function input
// runs through the same SymEngine evaluator the 2D screen uses,
// substituting both variables.
//
// The expensive part — evaluating f at every grid point — is cached.
// Only the rotation/projection is re-run on a drag gesture, so the
// surface stays responsive even with a 40×40 sample grid.
//
// V2 territory (deferred): perspective projection, hidden-line
// removal, contour lines, multiple surfaces, parametric 3D curves.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/calculator_engine.dart';
import '../localization/app_localizations.dart';
import '../utils/expression_preprocessing_utils.dart';

class Graphing3DScreen extends StatefulWidget {
  const Graphing3DScreen({super.key});

  @override
  State<Graphing3DScreen> createState() => _Graphing3DScreenState();
}

class _Graphing3DScreenState extends State<Graphing3DScreen> {
  final _engine = CalculatorEngine();
  final _functionController = TextEditingController(text: 'sin(x) * cos(y)');

  // x/y sampling range.
  double _range = 5.0;
  final int _grid = 32;

  // View angles (radians). Azimuth = rotation around vertical axis,
  // elevation = tilt above the x-y plane.
  double _azimuth = 0.5;
  double _elevation = 0.6;
  double _zoom = 1.0;

  /// Cached samples — a (grid+1) × (grid+1) array of z values.
  /// Null until the user submits a function or we re-sample.
  List<List<double>>? _zs;
  double? _sampledRange;
  String? _error;

  @override
  void dispose() {
    _functionController.dispose();
    super.dispose();
  }

  void _sample() {
    final raw = _functionController.text.trim();
    if (raw.isEmpty) return;

    final zs =
        List.generate(_grid + 1, (_) => List<double>.filled(_grid + 1, 0));
    var anyFinite = false;
    for (var i = 0; i <= _grid; i++) {
      final x = -_range + (2 * _range) * i / _grid;
      for (var j = 0; j <= _grid; j++) {
        final y = -_range + (2 * _range) * j / _grid;
        final z = _evaluateAt(raw, x, y);
        zs[i][j] = z;
        if (z.isFinite) anyFinite = true;
      }
    }
    setState(() {
      _zs = zs;
      _sampledRange = _range;
      _error = anyFinite ? null : 'No finite values in the sampled grid.';
    });
  }

  double _evaluateAt(String expr, double x, double y) {
    try {
      // Substitute x and y values FIRST, before any preprocessor pass
      // — that way a stored AppState variable named `x` can't shadow
      // our coordinates. After substitution the expression is pure
      // arithmetic with no symbolic variables, so we don't need
      // preprocessExpression at all; just the SymEngine-format pass.
      final xs = x < 0 ? '($x)' : '$x';
      final ys = y < 0 ? '($y)' : '$y';
      var sub = expr.replaceAll(RegExp(r'\bx\b'), xs);
      sub = sub.replaceAll(RegExp(r'\by\b'), ys);
      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(sub);
      final result = _engine.evaluateForGraphing(preprocessed);
      if (result.startsWith('Error') || result.isEmpty) return double.nan;
      return double.tryParse(result) ?? double.nan;
    } catch (_) {
      return double.nan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.module3DTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.module3DResample,
            onPressed: _sample,
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: t.resetView,
            onPressed: () => setState(() {
              _azimuth = 0.5;
              _elevation = 0.6;
              _zoom = 1.0;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onScaleUpdate: (d) {
                setState(() {
                  // Single-finger drag → rotate. Two-finger pinch → zoom.
                  _azimuth -= d.focalPointDelta.dx * 0.01;
                  _elevation = (_elevation + d.focalPointDelta.dy * 0.01)
                      .clamp(-math.pi / 2 + 0.01, math.pi / 2 - 0.01);
                  if (d.scale != 1.0) {
                    _zoom = (_zoom * d.scale).clamp(0.2, 5.0);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: _zs == null
                    ? Center(
                        child: Text(
                          t.module3DTapPlot,
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      )
                    : CustomPaint(
                        painter: _Surface3DPainter(
                          zs: _zs!,
                          range: _sampledRange ?? _range,
                          azimuth: _azimuth,
                          elevation: _elevation,
                          zoom: _zoom,
                          error: _error,
                        ),
                        size: Size.infinite,
                      ),
              ),
            ),
          ),
          if (_error != null)
            Container(
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _functionController,
                    decoration: InputDecoration(
                      labelText: t.module3DFunctionLabel,
                      hintText: 'sin(x) * cos(y)',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_chart),
                  label: Text(t.plotButton),
                  onPressed: _sample,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(t.module3DRangeLabel),
                Expanded(
                  child: Slider(
                    value: _range,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    label: '±${_range.toStringAsFixed(0)}',
                    onChanged: (v) => setState(() => _range = v),
                    onChangeEnd: (_) => _sample(),
                  ),
                ),
                Text('±${_range.toStringAsFixed(0)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Surface3DPainter extends CustomPainter {
  final List<List<double>> zs;
  final double range;
  final double azimuth;
  final double elevation;
  final double zoom;
  final String? error;

  _Surface3DPainter({
    required this.zs,
    required this.range,
    required this.azimuth,
    required this.elevation,
    required this.zoom,
    this.error,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (error != null) return;
    final grid = zs.length - 1;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Find finite z range for color gradient + scaling.
    double zMin = double.infinity;
    double zMax = double.negativeInfinity;
    for (final row in zs) {
      for (final z in row) {
        if (!z.isFinite) continue;
        if (z < zMin) zMin = z;
        if (z > zMax) zMax = z;
      }
    }
    if (!zMin.isFinite || zMin == zMax) {
      zMin = -1;
      zMax = 1;
    }
    // Scale z so the surface fits nicely vertically alongside x/y.
    final zScale = range / (zMax - zMin) * 0.5;

    // Pre-rotated grid of screen-space (x', y') for every sample.
    final cosA = math.cos(azimuth);
    final sinA = math.sin(azimuth);
    final cosE = math.cos(elevation);
    final sinE = math.sin(elevation);

    final scale = math.min(w, h) * 0.4 * zoom / range;

    Offset project(double x, double y, double z) {
      // Center z around its midpoint so the surface tilts symmetrically.
      final zRel = (z - (zMin + zMax) / 2) * zScale;
      // Rotate around the world z-axis (azimuth), then around the x'-axis
      // (elevation).
      final x1 = x * cosA - y * sinA;
      final y1 = x * sinA + y * cosA;
      final y2 = y1 * cosE - zRel * sinE;
      // Orthographic projection — drop the depth coordinate.
      return Offset(cx + x1 * scale, cy - y2 * scale);
    }

    // Axes — three colored lines through the origin to orient the user.
    final axisPaint = Paint()..strokeWidth = 1.2;
    final axisLen = range * 1.05;
    axisPaint.color = Colors.red;
    canvas.drawLine(project(-axisLen, 0, 0), project(axisLen, 0, 0), axisPaint);
    axisPaint.color = Colors.green;
    canvas.drawLine(project(0, -axisLen, 0), project(0, axisLen, 0), axisPaint);
    axisPaint.color = Colors.blue;
    canvas.drawLine(
      project(0, 0, (zMin - (zMin + zMax) / 2) * 1.0 / zScale * 0.95),
      project(0, 0, (zMax - (zMin + zMax) / 2) * 1.0 / zScale * 0.95),
      axisPaint,
    );

    // Pre-project all grid points to screen coordinates.
    final pts = List<List<Offset>>.generate(grid + 1, (i) {
      final x = -range + (2 * range) * i / grid;
      return List<Offset>.generate(grid + 1, (j) {
        final y = -range + (2 * range) * j / grid;
        return project(x, y, zs[i][j]);
      });
    });

    // Height-tinted line segments — color from blue (low) to red (high).
    Color colorFor(double z1, double z2) {
      final mid = (z1 + z2) / 2;
      final t = ((mid - zMin) / (zMax - zMin)).clamp(0.0, 1.0);
      // HSV: 240° (blue) → 0° (red) as t goes 0 → 1.
      return HSVColor.fromAHSV(1.0, (1 - t) * 240, 0.8, 1.0).toColor();
    }

    final lp = Paint()..strokeWidth = 1.0;

    // Draw the wireframe — connect (i,j) to (i+1,j) and (i,j+1).
    for (var i = 0; i <= grid; i++) {
      for (var j = 0; j <= grid; j++) {
        final z = zs[i][j];
        if (!z.isFinite) continue;
        if (i < grid) {
          final z2 = zs[i + 1][j];
          if (z2.isFinite) {
            lp.color = colorFor(z, z2);
            canvas.drawLine(pts[i][j], pts[i + 1][j], lp);
          }
        }
        if (j < grid) {
          final z2 = zs[i][j + 1];
          if (z2.isFinite) {
            lp.color = colorFor(z, z2);
            canvas.drawLine(pts[i][j], pts[i][j + 1], lp);
          }
        }
      }
    }

    // Tiny legend in the corner.
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'z ∈ [${zMin.toStringAsFixed(2)}, ${zMax.toStringAsFixed(2)}]   '
            'az ${(azimuth * 180 / math.pi).toStringAsFixed(0)}°  '
            'el ${(elevation * 180 / math.pi).toStringAsFixed(0)}°',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
    tp.layout();
    tp.paint(canvas, const Offset(8, 8));
  }

  @override
  bool shouldRepaint(covariant _Surface3DPainter old) =>
      old.azimuth != azimuth ||
      old.elevation != elevation ||
      old.zoom != zoom ||
      !identical(old.zs, zs);
}
