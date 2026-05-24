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

  group('SI prefix parser (V3)', () {
    test('1 pm in m', () {
      // 1 picometre = 1e-12 m
      final r = _eval('1 pm in m');
      expect(_numericResultMatches(r, 1e-12, unit: 'm'), isTrue,
          reason: 'got $r');
    });
    test('1 Tm in km — 1 terametre = 1e9 km', () {
      final r = _eval('1 Tm in km');
      expect(_numericResultMatches(r, 1e9, unit: 'km'), isTrue,
          reason: 'got $r');
    });
    test('1 Gm in m — 1 gigametre = 1e9 m', () {
      final r = _eval('1 Gm in m');
      expect(_numericResultMatches(r, 1e9, unit: 'm'), isTrue,
          reason: 'got $r');
    });
    test('1 fm in nm — femtometre into nanometre', () {
      // 1 fm = 1e-15 m = 1e-6 nm
      final r = _eval('1 fm in nm');
      expect(_numericResultMatches(r, 1e-6, unit: 'nm'), isTrue,
          reason: 'got $r');
    });
    test('500 dm in m — decimetre prefix', () {
      // 500 dm = 50 m
      final r = _eval('500 dm in m');
      expect(_numericResultMatches(r, 50.0, unit: 'm'), isTrue,
          reason: 'got $r');
    });
    test('1 hm in m — hectometre prefix', () {
      final r = _eval('1 hm in m');
      expect(_numericResultMatches(r, 100.0, unit: 'm'), isTrue,
          reason: 'got $r');
    });
    test('1 dam in m — deca prefix is 2 chars (longest-match)', () {
      // 1 dam = 10 m. The `da` prefix must beat the bare `d` prefix.
      final r = _eval('1 dam in m');
      expect(_numericResultMatches(r, 10.0, unit: 'm'), isTrue,
          reason: 'got $r');
    });
    test('5 ps + 3 ns in ns — picosecond + nanosecond mix', () {
      // 5 ps + 3 ns = 5e-12 + 3e-9 = 3.005e-9 s
      final r = _eval('5 ps + 3 ns in ns');
      expect(_numericResultMatches(r, 3.005, unit: 'ns'), isTrue,
          reason: 'got $r');
    });
    test('1 Gg in t — gigagram into tonne', () {
      // 1 Gg = 1e9 g = 1e6 kg = 1000 tonnes
      final r = _eval('1 Gg in t');
      expect(_numericResultMatches(r, 1000.0, unit: 't'), isTrue,
          reason: 'got $r');
    });
    test('300 μK in K — microkelvin', () {
      final r = _eval('300 μK in K');
      expect(_numericResultMatches(r, 3e-4, unit: 'K'), isTrue,
          reason: 'got $r');
    });
    test('1 ums (ASCII μ → u) parses as microsecond', () {
      // The catalog already has μs explicitly. We're testing the ASCII
      // fallback `us` produced via the prefix parser. 1 us = 1e-6 s.
      final r = _eval('1 us in ns');
      expect(_numericResultMatches(r, 1000.0, unit: 'ns'), isTrue,
          reason: 'got $r');
    });
    test('curated symbol still wins over prefix interpretation', () {
      // `mg` is curated → milligram (mass). The prefix parser would
      // also recognize it as milli-gram, with the same scale, so the
      // dimension must stay mass.
      final r = _eval('5 mg in g');
      expect(_numericResultMatches(r, 0.005, unit: 'g'), isTrue,
          reason: 'got $r');
    });
    test('1 min stays as minute, NOT milli-inch', () {
      // The `m` + `in` prefix combo MUST NOT shadow the explicit `min`.
      // We don't claim "min" is parsed as a prefix anyway — `in` is the
      // conversion keyword — but make sure the test confirms the
      // catalog-side meaning by converting.
      final r = _eval('1 min in s');
      expect(_numericResultMatches(r, 60.0, unit: 's'), isTrue,
          reason: 'got $r');
    });
  });

  group('scalar arithmetic on quantities (V4)', () {
    test('quantity * scalar — `5 km * 2 = 10 km`', () {
      expect(
          _numericResultMatches(_eval('5 km * 2'), 10.0, unit: 'km'), isTrue);
    });
    test('scalar * quantity — `2 * 5 km = 10 km`', () {
      expect(
          _numericResultMatches(_eval('2 * 5 km'), 10.0, unit: 'km'), isTrue);
    });
    test('quantity / scalar — `5 km / 2 = 2.5 km`', () {
      expect(_numericResultMatches(_eval('5 km / 2'), 2.5, unit: 'km'), isTrue);
    });
    test('mixed-unit-then-conversion — `3 km / 2 in m = 1500 m`', () {
      expect(_numericResultMatches(_eval('3 km / 2 in m'), 1500.0, unit: 'm'),
          isTrue);
    });
    test('chained scalar ops — `5 km * 2 / 4 = 2.5 km`', () {
      expect(_numericResultMatches(_eval('5 km * 2 / 4'), 2.5, unit: 'km'),
          isTrue);
    });
    test('scalar mul on leading term, then sum — `5 km * 2 + 3 m`', () {
      // 5·2 = 10 km, + 3 m = 10.003 km.
      expect(_numericResultMatches(_eval('5 km * 2 + 3 m'), 10.003, unit: 'km'),
          isTrue);
    });
    test('scalar mul AFTER a sum-op falls through (precedence rejection)', () {
      // `5 km + 3 m * 2` is ambiguous without precedence — we refuse it
      // rather than silently apply the wrong meaning. tryEvaluate returns
      // null → caller falls through to the scalar/CAS evaluator.
      expect(UnitExpressionEvaluator.tryEvaluate('5 km + 3 m * 2'), isNull);
    });
    test('scalar × scalar (no unit on RHS) — `5 km * 2 * 3 = 30 km`', () {
      expect(_numericResultMatches(_eval('5 km * 2 * 3'), 30.0, unit: 'km'),
          isTrue);
    });
    test('division by zero gives a friendly error', () {
      final r = _eval('5 km / 0');
      expect(r, isNotNull);
      expect(r, startsWith('Error'));
      expect(r, contains('zero'));
    });
    test('quantity × quantity now produces a composite dimension (V5)', () {
      // `5 km * 2 s` = 5000 m * 2 s = 10000 m·s. V5 enables this.
      final r = UnitExpressionEvaluator.tryEvaluate('5 km * 2 s');
      expect(r, '10000 m·s');
    });
    test('1 mile / 2 in km — combine scalar div with conversion', () {
      // 1 mile / 2 = 0.5 mile = 0.804672 km.
      expect(
          _numericResultMatches(_eval('1 mile / 2 in km'), 0.804672,
              unit: 'km'),
          isTrue);
    });
  });

  group('composite-dimension arithmetic (V5)', () {
    test('100 m / 10 s → 10 m/s (length / time = velocity)', () {
      // Result dim = (length=1, time=-1), which is the velocity dim and
      // formats as the coherent SI base unit `m/s`.
      expect(_eval('100 m / 10 s'), '10 m/s');
    });

    test('km / h dim cancels to the velocity dim and converts cleanly', () {
      // 36 km / 1 h = 36000 m / 3600 s = 10 m/s.
      expect(_eval('36 km / 1 h'), '10 m/s');
    });

    test('5 m * 3 m → 15 m^2 (length × length)', () {
      // No catalog match for area; falls through to base-units format.
      expect(_eval('5 m * 3 m'), '15 m^2');
    });

    test('quantity / quantity to convert via in', () {
      // 100 m / 10 s in km/h. 10 m/s = 36 km/h.
      expect(
          _numericResultMatches(_eval('100 m / 10 s in km/h'), 36.0,
              unit: 'km/h'),
          isTrue);
    });

    test('dimensionless when same-dim cancel', () {
      // 5 m / 5 m = 1 (dimensionless).
      expect(_eval('5 m / 5 m'), startsWith('1'));
    });

    test('mixing composite-dim multiplication and sum is refused', () {
      // 5 m + 2 m * 3 s is ambiguous (precedence). Returns null so the
      // scalar fallback can try; SymEngine will choke on the unit
      // symbols and the user will see a parse error.
      // Actually: the current code path treats `+` as setting hadSumOp
      // first, then `*` finds a quantity RHS and would normally bail.
      // The "sum after composite" message fires the other direction:
      // 5 m * 2 s + … — verify that.
      final r = _eval('5 m * 2 s + 1 m');
      expect(r, isNotNull);
      expect(r, startsWith('Error'));
      expect(r, contains('composite'));
    });
  });

  group('derived SI units (V5)', () {
    test('5 N as a standalone quantity', () {
      // Carries (mass=1, length=1, time=-2). With no further math, the
      // output keeps the N symbol via the derived-unit catalog match.
      final r = _eval('5 N');
      expect(r, isNotNull);
      // Single quantity uses curated `singleDim` formatter — but `N` is
      // derived, so the anchorSingleDim is null and we go through
      // matchingBaseDim which returns 'N'.
      expect(r, '5 N');
    });

    test('1 kN — SI prefix on derived unit', () {
      // 1 kN = 1000 N. Output picks derived `N` (closest matching base).
      expect(_eval('1 kN'), '1000 N');
    });

    test('1 J / 1 s → 1 W (joule per second = watt)', () {
      expect(_eval('1 J / 1 s'), '1 W');
    });

    test('60 Hz exposes the inverse-time dimension', () {
      expect(_eval('60 Hz'), '60 Hz');
    });
  });
}
