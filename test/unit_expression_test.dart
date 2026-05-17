// test/unit_expression_test.dart
//
// Inline unit arithmetic — V1 coverage. Verifies the tokenizer's
// "is this a unit expression?" decision (it must return null for
// plain math so the scalar evaluator handles it), the arithmetic
// for same-dimension `+` and `-`, the `in <unit>` conversion suffix,
// and the error cases (mixed dimensions, temperature arithmetic).

import 'package:crisp_calc/engine/unit_expression.dart';
import 'package:flutter_test/flutter_test.dart';

String? _eval(String e) => UnitExpressionEvaluator.tryEvaluate(e);

/// Loose numeric match — formatter rounds and may use scientific
/// notation, so we use a relative tolerance of 1e-3 (3 significant
/// digits), which is enough to catch wrong-unit / wrong-formula
/// regressions without breaking on harmless format drift.
bool _numericResultMatches(String? actual, double expected, {String? unit}) {
  if (actual == null) return false;
  final parts = actual.split(' ');
  if (parts.isEmpty) return false;
  final value = double.tryParse(parts[0]);
  if (value == null) return false;
  final ok = (value - expected).abs() < 1e-3 * (expected.abs() + 1);
  if (!ok) return false;
  if (unit != null && (parts.length < 2 || parts[1] != unit)) return false;
  return true;
}

void main() {
  group('not a unit expression — falls through (returns null)', () {
    test('empty string', () {
      expect(_eval(''), isNull);
    });
    test('plain number', () {
      expect(_eval('42'), isNull);
    });
    test('scalar arithmetic', () {
      expect(_eval('2 + 3'), isNull);
    });
    test('scalar with variable', () {
      expect(_eval('x + 1'), isNull);
    });
    test('SymEngine matrix syntax', () {
      expect(_eval('Matrix([[1, 2], [3, 4]])'), isNull);
    });
    test('solve call', () {
      expect(_eval('solve(x^2 - 4, x)'), isNull);
    });
    test('function call shaped input', () {
      expect(_eval('sin(x)'), isNull);
    });
  });

  group('single quantity', () {
    test('5 km — passes through with unit', () {
      expect(_numericResultMatches(_eval('5 km'), 5.0, unit: 'km'), isTrue);
    });
    test('5km — no space allowed too', () {
      expect(_numericResultMatches(_eval('5km'), 5.0, unit: 'km'), isTrue);
    });
    test('decimal value', () {
      expect(_numericResultMatches(_eval('1.5 m'), 1.5, unit: 'm'), isTrue);
    });
  });

  group('same-dimension addition', () {
    test('5 km + 3 m == 5.003 km', () {
      expect(_numericResultMatches(_eval('5 km + 3 m'), 5.003, unit: 'km'),
          isTrue);
    });
    test('1 mile + 5 ft has the right base value', () {
      // 1 mile + 5 ft = 1609.344 + 1.524 = 1610.868 m
      // Expressed in mi: 1610.868 / 1609.344 ≈ 1.0009466
      final r = _eval('1 mile + 5 ft');
      expect(_numericResultMatches(r, 1.0009466, unit: 'mi'), isTrue,
          reason: 'got $r');
    });
    test('three-term sum', () {
      // 1 m + 50 cm + 100 mm = 1 + 0.5 + 0.1 = 1.6 m
      final r = _eval('1 m + 50 cm + 100 mm');
      expect(_numericResultMatches(r, 1.6, unit: 'm'), isTrue,
          reason: 'got $r');
    });
  });

  group('same-dimension subtraction', () {
    test('1 km - 200 m == 0.8 km', () {
      expect(_numericResultMatches(_eval('1 km - 200 m'), 0.8, unit: 'km'),
          isTrue);
    });
    test('1 h - 30 min == 0.5 h', () {
      expect(
          _numericResultMatches(_eval('1 h - 30 min'), 0.5, unit: 'h'), isTrue);
    });
  });

  group('mixed dimensions → error', () {
    test('km + s rejects cleanly', () {
      final r = _eval('5 km + 10 s');
      expect(r, isNotNull);
      expect(r, startsWith('Error'));
      expect(r, contains('add'));
    });
    test('kg - m rejects cleanly', () {
      final r = _eval('5 kg - 10 m');
      expect(r, isNotNull);
      expect(r, startsWith('Error'));
    });
  });

  group('in <unit> conversion suffix', () {
    test('100 km in mph', () {
      final r = _eval('100 km in mph');
      expect(r, isNotNull);
      // 100 km isn't a velocity, so this should fail — converting
      // length to velocity is a dimension mismatch.
      expect(r, startsWith('Error'));
    });
    test('100 km/h in mph (same dimension)', () {
      final r = _eval('100 km/h in mph');
      // 100 km/h ≈ 62.137 mph
      expect(_numericResultMatches(r, 62.137, unit: 'mph'), isTrue,
          reason: 'got $r');
    });
    test('1 mile in km', () {
      final r = _eval('1 mile in km');
      expect(_numericResultMatches(r, 1.609344, unit: 'km'), isTrue,
          reason: 'got $r');
    });
    test('arithmetic + conversion', () {
      // 5 km + 3 m = 5.003 km; in m: 5003 m.
      final r = _eval('5 km + 3 m in m');
      expect(_numericResultMatches(r, 5003, unit: 'm'), isTrue,
          reason: 'got $r');
    });
  });

  group('temperature — arithmetic is refused, conversion is allowed', () {
    test('°C + °C rejected as ambiguous (offset units)', () {
      final r = _eval('5 °C + 10 °C');
      expect(r, isNotNull);
      expect(r, startsWith('Error'));
      expect(r, contains('temperature'));
    });
    test('°C in °F single-quantity conversion works', () {
      final r = _eval('100 °C in °F');
      expect(_numericResultMatches(r, 212.0, unit: '°F'), isTrue,
          reason: 'got $r');
    });
    test('K in °C', () {
      final r = _eval('0 K in °C');
      expect(_numericResultMatches(r, -273.15, unit: '°C'), isTrue,
          reason: 'got $r');
    });
  });

  group('angle conversions', () {
    test('180° in rad ≈ π', () {
      final r = _eval('180 ° in rad');
      expect(_numericResultMatches(r, 3.14159265, unit: 'rad'), isTrue,
          reason: 'got $r');
    });
    test('1 turn in °', () {
      final r = _eval('1 turn in °');
      expect(_numericResultMatches(r, 360.0, unit: '°'), isTrue,
          reason: 'got $r');
    });
  });
}
