// lib/screens/plane_analysis_screen.dart
//
// A small 3D-plane analyzer. The user supplies a plane in either parametric
// (point + two direction vectors) or normal/coordinate form (ax + by + cz = d),
// and we report:
//   - both forms (parametric ↔ normal),
//   - the unit normal,
//   - signed distance from the origin,
//   - the Hessian normal form (n̂·x = p),
//   - intercepts with the axes when finite.
//
// All math is plain Dart — no SymEngine dependency. The actual geometry is
// in engine/plane_math.dart so it can be unit tested without a widget tree.

import 'package:flutter/material.dart';

import '../engine/plane_math.dart';

class PlaneAnalysisScreen extends StatefulWidget {
  const PlaneAnalysisScreen({super.key});

  @override
  State<PlaneAnalysisScreen> createState() => _PlaneAnalysisScreenState();
}

enum _Form { coordinate, parametric }

class _PlaneAnalysisScreenState extends State<PlaneAnalysisScreen> {
  _Form _form = _Form.coordinate;

  // Coordinate form: a x + b y + c z = d
  final _a = TextEditingController(text: '1');
  final _b = TextEditingController(text: '2');
  final _c = TextEditingController(text: '-2');
  final _d = TextEditingController(text: '6');

  // Parametric form: P + s*U + t*V
  final _px = TextEditingController(text: '1');
  final _py = TextEditingController(text: '0');
  final _pz = TextEditingController(text: '0');
  final _ux = TextEditingController(text: '0');
  final _uy = TextEditingController(text: '1');
  final _uz = TextEditingController(text: '0');
  final _vx = TextEditingController(text: '0');
  final _vy = TextEditingController(text: '0');
  final _vz = TextEditingController(text: '1');

  String? _output;

  @override
  void dispose() {
    for (final c in [
      _a,
      _b,
      _c,
      _d,
      _px,
      _py,
      _pz,
      _ux,
      _uy,
      _uz,
      _vx,
      _vy,
      _vz
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _analyze() {
    PlaneAnalysis result;
    if (_form == _Form.coordinate) {
      result = analyzePlaneFromCoordinate(
          _parse(_a), _parse(_b), _parse(_c), _parse(_d));
    } else {
      result = analyzePlaneFromParametric(
        Vector3(_parse(_px), _parse(_py), _parse(_pz)),
        Vector3(_parse(_ux), _parse(_uy), _parse(_uz)),
        Vector3(_parse(_vx), _parse(_vy), _parse(_vz)),
      );
    }

    if (!result.isValid) {
      setState(() => _output = 'Error: ${result.error}');
      return;
    }

    final buf = StringBuffer();
    buf.writeln('Coordinate form:');
    buf.writeln(
        '  ${_term(result.a, 'x')} ${_termSigned(result.b, 'y')} ${_termSigned(result.c, 'z')} = ${_fmt(result.d)}');
    buf.writeln();
    buf.writeln(
        'Normal vector n = (${_fmt(result.a)}, ${_fmt(result.b)}, ${_fmt(result.c)})');
    buf.writeln(
        'Unit normal n̂ = (${_fmt(result.unitNormal.x)}, ${_fmt(result.unitNormal.y)}, ${_fmt(result.unitNormal.z)})');
    buf.writeln(
        'Hessian normal form: n̂·x = ${_fmt(-result.signedDistanceFromOrigin)}');
    buf.writeln(
        'Signed distance from origin: ${_fmt(result.signedDistanceFromOrigin)}');
    buf.writeln();
    buf.writeln(
        'Point on plane: (${_fmt(result.pointOnPlane.x)}, ${_fmt(result.pointOnPlane.y)}, ${_fmt(result.pointOnPlane.z)})');
    buf.writeln();
    buf.writeln('Axis intercepts:');
    buf.writeln(result.xIntercept != null
        ? '  x-axis: (${_fmt(result.xIntercept!.x)}, 0, 0)'
        : '  x-axis: parallel (no intercept)');
    buf.writeln(result.yIntercept != null
        ? '  y-axis: (0, ${_fmt(result.yIntercept!.y)}, 0)'
        : '  y-axis: parallel (no intercept)');
    buf.writeln(result.zIntercept != null
        ? '  z-axis: (0, 0, ${_fmt(result.zIntercept!.z)})'
        : '  z-axis: parallel (no intercept)');

    setState(() => _output = buf.toString());
  }

  static String _fmt(double v) {
    if ((v - v.roundToDouble()).abs() < 1e-9) return v.toInt().toString();
    return v
        .toStringAsPrecision(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  static String _term(double coeff, String letter) {
    if (coeff == 0) return '0';
    if (coeff == 1) return letter;
    if (coeff == -1) return '-$letter';
    return '${_fmt(coeff)}$letter';
  }

  static String _termSigned(double coeff, String letter) {
    if (coeff == 0) return '';
    if (coeff > 0) return '+ ${_term(coeff, letter)}';
    return '- ${_term(-coeff, letter)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plane Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_Form>(
              segments: const [
                ButtonSegment(
                  value: _Form.coordinate,
                  label: Text('Coordinate'),
                  icon: Icon(Icons.linear_scale),
                ),
                ButtonSegment(
                  value: _Form.parametric,
                  label: Text('Parametric'),
                  icon: Icon(Icons.view_in_ar),
                ),
              ],
              selected: {_form},
              onSelectionChanged: (s) => setState(() => _form = s.first),
            ),
            const SizedBox(height: 16),
            if (_form == _Form.coordinate)
              _buildCoordinateForm()
            else
              _buildParametricForm(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.calculate),
              label: const Text('Analyze'),
              onPressed: _analyze,
            ),
            const SizedBox(height: 16),
            if (_output != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _output!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinateForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('a·x + b·y + c·z = d'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _num(_a, 'a')),
              const SizedBox(width: 8),
              Expanded(child: _num(_b, 'b')),
              const SizedBox(width: 8),
              Expanded(child: _num(_c, 'c')),
              const SizedBox(width: 8),
              Expanded(child: _num(_d, 'd')),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildParametricForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('x = P + s·U + t·V'),
            ),
            const SizedBox(height: 12),
            _vecRow('Point P', _px, _py, _pz),
            const SizedBox(height: 8),
            _vecRow('Direction U', _ux, _uy, _uz),
            const SizedBox(height: 8),
            _vecRow('Direction V', _vx, _vy, _vz),
          ],
        ),
      ),
    );
  }

  Widget _vecRow(String label, TextEditingController x, TextEditingController y,
      TextEditingController z) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(child: _num(x, 'x')),
        const SizedBox(width: 8),
        Expanded(child: _num(y, 'y')),
        const SizedBox(width: 8),
        Expanded(child: _num(z, 'z')),
      ],
    );
  }

  Widget _num(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType:
          const TextInputType.numberWithOptions(signed: true, decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
