// lib/screens/conic_section_screen.dart
//
// Classifies a conic section given as
//   A x² + B x y + C y² + D x + E y + F = 0
// using the discriminant Δ = B² - 4AC and the standard reductions:
//   - Δ <  0 → ellipse (circle when A == C and B == 0; degenerate point if no
//     real solutions)
//   - Δ == 0 → parabola (or degenerate line)
//   - Δ >  0 → hyperbola (or degenerate pair of lines)
//
// We also recover the center for central conics (Δ != 0), and the
// rotation angle when B != 0. The math lives in engine/conic_math.dart so
// it can be unit tested without spinning up a widget tree.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/conic_math.dart';
import '../localization/app_localizations.dart';

class ConicSectionScreen extends StatefulWidget {
  const ConicSectionScreen({super.key});

  @override
  State<ConicSectionScreen> createState() => _ConicSectionScreenState();
}

class _ConicSectionScreenState extends State<ConicSectionScreen> {
  final _a = TextEditingController(text: '1');
  final _b = TextEditingController(text: '0');
  final _c = TextEditingController(text: '1');
  final _d = TextEditingController(text: '-4');
  final _e = TextEditingController(text: '-6');
  final _f = TextEditingController(text: '4');

  String? _output;

  @override
  void dispose() {
    for (final c in [_a, _b, _c, _d, _e, _f]) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _analyze() {
    final result = analyzeConic(
      _parse(_a),
      _parse(_b),
      _parse(_c),
      _parse(_d),
      _parse(_e),
      _parse(_f),
    );

    if (result.kind == ConicKind.notAConic) {
      setState(() => _output = result.notes ?? 'Not a conic.');
      return;
    }

    final buf = StringBuffer();
    buf.writeln('Equation:');
    buf.writeln(
        '  ${_fmtConic(result.a, result.b, result.c, result.d, result.e, result.f)} = 0');
    buf.writeln();
    buf.writeln('Discriminant Δ = B² − 4AC = ${_fmt(result.discriminant)}');
    buf.writeln();
    buf.writeln('Type: ${_kindLabel(result.kind)}');
    buf.writeln();

    if (result.rotationRadians != null) {
      buf.writeln('Rotation angle θ = ${_fmt(result.rotationRadians!)} rad '
          '(${_fmt(result.rotationRadians! * 180 / math.pi)}°)');
    }

    final c = result.center;
    if (c != null) {
      buf.writeln('Center: (${_fmt(c.x)}, ${_fmt(c.y)})');
    } else if (result.kind == ConicKind.parabola) {
      buf.writeln('Parabola — axis along the eigenvector of [A B/2; B/2 C] '
          'with eigenvalue 0.');
    }

    if (result.notes != null) {
      buf.writeln(result.notes);
    }

    if (result.semiMajor != null && result.semiMinor != null) {
      if (result.kind == ConicKind.hyperbola) {
        buf.writeln('Semi-transverse axis a = ${_fmt(result.semiMajor!)}');
        buf.writeln('Semi-conjugate axis b = ${_fmt(result.semiMinor!)}');
      } else {
        buf.writeln('Semi-major axis a = ${_fmt(result.semiMajor!)}');
        buf.writeln('Semi-minor axis b = ${_fmt(result.semiMinor!)}');
      }
    }
    if (result.eccentricity != null) {
      buf.writeln('Eccentricity e = ${_fmt(result.eccentricity!)}');
    }

    setState(() => _output = buf.toString());
  }

  static String _kindLabel(ConicKind k) {
    switch (k) {
      case ConicKind.circle:
        return 'Circle';
      case ConicKind.ellipse:
        return 'Ellipse';
      case ConicKind.parabola:
        return 'Parabola';
      case ConicKind.hyperbola:
        return 'Hyperbola';
      case ConicKind.degenerate:
        return 'Degenerate conic';
      case ConicKind.notAConic:
        return 'Not a conic';
    }
  }

  static String _fmt(double v) {
    if ((v - v.roundToDouble()).abs() < 1e-9) return v.toInt().toString();
    return v
        .toStringAsPrecision(6)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _fmtConic(double A, double B, double C, double D, double E, double F) {
    final parts = <String>[];
    void add(double v, String label) {
      if (v == 0) return;
      final signed =
          parts.isEmpty ? (v < 0 ? '-' : '') : (v < 0 ? ' - ' : ' + ');
      final abs = v.abs();
      final coef = (abs == 1 && label.isNotEmpty) ? '' : _fmt(abs);
      parts.add('$signed$coef$label');
    }

    add(A, 'x²');
    add(B, 'xy');
    add(C, 'y²');
    add(D, 'x');
    add(E, 'y');
    add(F, '');
    return parts.isEmpty ? '0' : parts.join('');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.moduleConics)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A·x² + B·xy + C·y² + D·x + E·y + F = 0'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _num(_a, 'A')),
                      const SizedBox(width: 8),
                      Expanded(child: _num(_b, 'B')),
                      const SizedBox(width: 8),
                      Expanded(child: _num(_c, 'C')),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _num(_d, 'D')),
                      const SizedBox(width: 8),
                      Expanded(child: _num(_e, 'E')),
                      const SizedBox(width: 8),
                      Expanded(child: _num(_f, 'F')),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.calculate),
              label: Text(t.buttonClassify),
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
