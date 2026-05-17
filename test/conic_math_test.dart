import 'dart:math' as math;

import 'package:crisp_calc/engine/conic_math.dart';
import 'package:flutter_test/flutter_test.dart';

const _eps = 1e-6;

void main() {
  group('analyzeConic — classification', () {
    test('unit circle x² + y² = 1', () {
      final r = analyzeConic(1, 0, 1, 0, 0, -1);
      expect(r.kind, ConicKind.circle);
      expect(r.center?.x, closeTo(0, _eps));
      expect(r.center?.y, closeTo(0, _eps));
      expect(r.semiMajor, closeTo(1, _eps));
      expect(r.semiMinor, closeTo(1, _eps));
      expect(r.eccentricity, closeTo(0, _eps));
    });

    test('axis-aligned ellipse x²/4 + y² = 1  ⇔  x² + 4y² = 4', () {
      final r = analyzeConic(1, 0, 4, 0, 0, -4);
      expect(r.kind, ConicKind.ellipse);
      expect(r.semiMajor, closeTo(2, _eps));
      expect(r.semiMinor, closeTo(1, _eps));
      // e = sqrt(1 - b²/a²) = sqrt(1 - 1/4) = sqrt(3)/2
      expect(r.eccentricity, closeTo(math.sqrt(3) / 2, _eps));
    });

    test('parabola y² = 4x ⇔  y² - 4x = 0', () {
      final r = analyzeConic(0, 0, 1, -4, 0, 0);
      expect(r.kind, ConicKind.parabola);
      expect(r.discriminant.abs(), lessThan(_eps));
      // No center for parabolas in this representation.
      expect(r.center, isNull);
    });

    test('hyperbola x²/4 - y² = 1  ⇔  x² - 4y² = 4', () {
      final r = analyzeConic(1, 0, -4, 0, 0, -4);
      expect(r.kind, ConicKind.hyperbola);
      // Semi-transverse axis along x is 2.
      expect(r.semiMajor, closeTo(2, _eps));
      expect(r.semiMinor, closeTo(1, _eps));
      // e = sqrt(1 + b²/a²) = sqrt(1 + 1/4) = sqrt(5)/2
      expect(r.eccentricity, closeTo(math.sqrt(5) / 2, _eps));
    });

    test('linear (no quadratic) reports notAConic', () {
      final r = analyzeConic(0, 0, 0, 1, 1, -1);
      expect(r.kind, ConicKind.notAConic);
    });

    test('translated circle (x-1)² + (y+2)² = 9', () {
      // x² - 2x + 1 + y² + 4y + 4 = 9 → x² + y² - 2x + 4y - 4 = 0
      final r = analyzeConic(1, 0, 1, -2, 4, -4);
      expect(r.kind, ConicKind.circle);
      expect(r.center?.x, closeTo(1, _eps));
      expect(r.center?.y, closeTo(-2, _eps));
      expect(r.semiMajor, closeTo(3, _eps));
      expect(r.semiMinor, closeTo(3, _eps));
    });

    test('point (degenerate ellipse): x² + y² = 0', () {
      final r = analyzeConic(1, 0, 1, 0, 0, 0);
      expect(r.kind, ConicKind.degenerate);
    });
  });

  group('analyzeConic — rotation', () {
    test('xy = 1 (rotated hyperbola) has 45° rotation', () {
      // xy = 1 → 0·x² + 1·xy + 0·y² + 0·x + 0·y - 1 = 0
      final r = analyzeConic(0, 1, 0, 0, 0, -1);
      expect(r.kind, ConicKind.hyperbola);
      expect(r.rotationRadians, isNotNull);
      // atan2(B=1, A-C=0) = π/2; half of that = π/4 = 45°.
      expect(r.rotationRadians!, closeTo(math.pi / 4, _eps));
    });

    test('no xy term means no rotation', () {
      final r = analyzeConic(1, 0, 4, 0, 0, -4);
      expect(r.rotationRadians, isNull);
    });
  });

  group('analyzeConic — discriminant sign', () {
    test('ellipse has Δ < 0', () {
      expect(analyzeConic(1, 0, 4, 0, 0, -4).discriminant, lessThan(0));
    });
    test('parabola has Δ ≈ 0', () {
      expect(
          analyzeConic(0, 0, 1, -4, 0, 0).discriminant.abs(), lessThan(_eps));
    });
    test('hyperbola has Δ > 0', () {
      expect(analyzeConic(1, 0, -4, 0, 0, -4).discriminant, greaterThan(0));
    });
  });
}
