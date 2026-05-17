// lib/engine/unit_catalog.dart
//
// Catalog of physical units we know how to convert. Each unit has a
// symbol, a human name, and a (scale, offset) pair that takes it to
// the canonical SI base unit for its dimension: `value_in_base =
// value * scale + offset`. The offset handles temperatures (°C, °F),
// which aren't simple proportionals to Kelvin. Everything else has
// offset = 0.
//
// V1 covers six dimensions: length, time, mass, temperature,
// velocity (a derived dimension we keep separate for UX clarity),
// and angle. Composite-dimension arithmetic (e.g. force = mass *
// acceleration) is V2 — for now the converter only works within a
// single dimension category, which covers ~95% of homework and
// engineering quick-conversion use cases.

enum UnitDimension { length, time, mass, temperature, velocity, angle }

class Unit {
  /// Short symbol the user picks from a dropdown. e.g. "km", "°C".
  final String symbol;

  /// Human-readable name shown alongside the symbol.
  final String name;

  /// Multiplier into the canonical base unit for [dimension].
  final double scale;

  /// Additive offset (after scaling) into the base unit. Zero except
  /// for temperatures: °C → K is (x * 1.0) + 273.15, °F → K is
  /// (x * 5/9) + (459.67 * 5/9).
  final double offset;

  final UnitDimension dimension;

  const Unit({
    required this.symbol,
    required this.name,
    required this.dimension,
    required this.scale,
    this.offset = 0.0,
  });

  /// Convert a value expressed in this unit to its dimension's base.
  double toBase(double value) => value * scale + offset;

  /// Inverse of [toBase].
  double fromBase(double baseValue) => (baseValue - offset) / scale;
}

class UnitCatalog {
  /// All known units, grouped by dimension. Order within a list is the
  /// order the picker shows.
  static const Map<UnitDimension, List<Unit>> _byDimension = {
    // === Length (base: metre) ============================================
    UnitDimension.length: [
      Unit(
          symbol: 'm',
          name: 'metre',
          dimension: UnitDimension.length,
          scale: 1.0),
      Unit(
          symbol: 'km',
          name: 'kilometre',
          dimension: UnitDimension.length,
          scale: 1000.0),
      Unit(
          symbol: 'cm',
          name: 'centimetre',
          dimension: UnitDimension.length,
          scale: 0.01),
      Unit(
          symbol: 'mm',
          name: 'millimetre',
          dimension: UnitDimension.length,
          scale: 0.001),
      Unit(
          symbol: 'μm',
          name: 'micrometre',
          dimension: UnitDimension.length,
          scale: 1e-6),
      Unit(
          symbol: 'nm',
          name: 'nanometre',
          dimension: UnitDimension.length,
          scale: 1e-9),
      Unit(
          symbol: 'mi',
          name: 'mile',
          dimension: UnitDimension.length,
          scale: 1609.344),
      Unit(
          symbol: 'yd',
          name: 'yard',
          dimension: UnitDimension.length,
          scale: 0.9144),
      Unit(
          symbol: 'ft',
          name: 'foot',
          dimension: UnitDimension.length,
          scale: 0.3048),
      Unit(
          symbol: 'in',
          name: 'inch',
          dimension: UnitDimension.length,
          scale: 0.0254),
      Unit(
          symbol: 'nmi',
          name: 'nautical mile',
          dimension: UnitDimension.length,
          scale: 1852.0),
      Unit(
          symbol: 'AU',
          name: 'astronomical unit',
          dimension: UnitDimension.length,
          scale: 1.495978707e11),
      Unit(
          symbol: 'ly',
          name: 'light-year',
          dimension: UnitDimension.length,
          scale: 9.4607304725808e15),
    ],

    // === Time (base: second) =============================================
    UnitDimension.time: [
      Unit(
          symbol: 's',
          name: 'second',
          dimension: UnitDimension.time,
          scale: 1.0),
      Unit(
          symbol: 'ms',
          name: 'millisecond',
          dimension: UnitDimension.time,
          scale: 0.001),
      Unit(
          symbol: 'μs',
          name: 'microsecond',
          dimension: UnitDimension.time,
          scale: 1e-6),
      Unit(
          symbol: 'ns',
          name: 'nanosecond',
          dimension: UnitDimension.time,
          scale: 1e-9),
      Unit(
          symbol: 'min',
          name: 'minute',
          dimension: UnitDimension.time,
          scale: 60.0),
      Unit(
          symbol: 'h',
          name: 'hour',
          dimension: UnitDimension.time,
          scale: 3600.0),
      Unit(
          symbol: 'd',
          name: 'day',
          dimension: UnitDimension.time,
          scale: 86400.0),
      Unit(
          symbol: 'wk',
          name: 'week',
          dimension: UnitDimension.time,
          scale: 604800.0),
      Unit(
          symbol: 'yr',
          name: 'year (365.25 d)',
          dimension: UnitDimension.time,
          scale: 31557600.0),
    ],

    // === Mass (base: kilogram) ===========================================
    UnitDimension.mass: [
      Unit(
          symbol: 'kg',
          name: 'kilogram',
          dimension: UnitDimension.mass,
          scale: 1.0),
      Unit(
          symbol: 'g',
          name: 'gram',
          dimension: UnitDimension.mass,
          scale: 0.001),
      Unit(
          symbol: 'mg',
          name: 'milligram',
          dimension: UnitDimension.mass,
          scale: 1e-6),
      Unit(
          symbol: 't',
          name: 'tonne',
          dimension: UnitDimension.mass,
          scale: 1000.0),
      Unit(
          symbol: 'lb',
          name: 'pound',
          dimension: UnitDimension.mass,
          scale: 0.45359237),
      Unit(
          symbol: 'oz',
          name: 'ounce',
          dimension: UnitDimension.mass,
          scale: 0.028349523125),
      Unit(
          symbol: 'st',
          name: 'stone',
          dimension: UnitDimension.mass,
          scale: 6.35029318),
    ],

    // === Temperature (base: Kelvin) ======================================
    // Temperature is the only dimension where offset != 0. °C and °F
    // are NOT scale multiples of Kelvin — converting between them
    // requires the full affine transform.
    UnitDimension.temperature: [
      Unit(
          symbol: 'K',
          name: 'kelvin',
          dimension: UnitDimension.temperature,
          scale: 1.0),
      Unit(
          symbol: '°C',
          name: 'celsius',
          dimension: UnitDimension.temperature,
          scale: 1.0,
          offset: 273.15),
      // °F → K: K = (F - 32) * 5/9 + 273.15
      //       = F * 5/9 + (273.15 - 32 * 5/9)
      //       = F * 5/9 + 255.3722...
      // So scale = 5/9, offset = 273.15 - 32*5/9 = 255.37222...
      Unit(
          symbol: '°F',
          name: 'fahrenheit',
          dimension: UnitDimension.temperature,
          scale: 5.0 / 9.0,
          offset: 459.67 * 5.0 / 9.0),
    ],

    // === Velocity (base: m/s) ============================================
    UnitDimension.velocity: [
      Unit(
          symbol: 'm/s',
          name: 'metre per second',
          dimension: UnitDimension.velocity,
          scale: 1.0),
      Unit(
          symbol: 'km/h',
          name: 'kilometre per hour',
          dimension: UnitDimension.velocity,
          scale: 1000.0 / 3600.0),
      Unit(
          symbol: 'mph',
          name: 'mile per hour',
          dimension: UnitDimension.velocity,
          scale: 1609.344 / 3600.0),
      Unit(
          symbol: 'ft/s',
          name: 'foot per second',
          dimension: UnitDimension.velocity,
          scale: 0.3048),
      Unit(
          symbol: 'kn',
          name: 'knot',
          dimension: UnitDimension.velocity,
          scale: 1852.0 / 3600.0),
      Unit(
          symbol: 'c',
          name: 'speed of light',
          dimension: UnitDimension.velocity,
          scale: 299792458.0),
    ],

    // === Angle (base: radian) ============================================
    UnitDimension.angle: [
      Unit(
          symbol: 'rad',
          name: 'radian',
          dimension: UnitDimension.angle,
          scale: 1.0),
      // 1 degree = π/180 radians ≈ 0.017453292519943295
      Unit(
          symbol: '°',
          name: 'degree',
          dimension: UnitDimension.angle,
          scale: 0.017453292519943295),
      // 1 gradian = π/200 radians
      Unit(
          symbol: 'grad',
          name: 'gradian',
          dimension: UnitDimension.angle,
          scale: 0.015707963267948967),
      // 1 turn = 2π radians
      Unit(
          symbol: 'turn',
          name: 'turn',
          dimension: UnitDimension.angle,
          scale: 6.283185307179586),
      // 1 arcminute = 1/60 degree
      Unit(
          symbol: 'arcmin',
          name: 'arcminute',
          dimension: UnitDimension.angle,
          scale: 0.017453292519943295 / 60.0),
      Unit(
          symbol: 'arcsec',
          name: 'arcsecond',
          dimension: UnitDimension.angle,
          scale: 0.017453292519943295 / 3600.0),
    ],
  };

  static List<Unit> unitsFor(UnitDimension dim) =>
      _byDimension[dim] ?? const [];

  static List<UnitDimension> allDimensions() =>
      UnitDimension.values.toList(growable: false);

  /// Look up a unit by its [symbol] in the curated catalog. Returns null
  /// if not found. The inline parser uses [bySymbolWithPrefixes] instead,
  /// which additionally tries to interpret unrecognized symbols as SI
  /// prefix + prefixable base.
  static Unit? bySymbol(String symbol) {
    for (final units in _byDimension.values) {
      for (final u in units) {
        if (u.symbol == symbol) return u;
      }
    }
    return null;
  }

  // === SI prefix parser ====================================================
  //
  // The curated catalog hardcodes the most common prefixed forms (km,
  // cm, mm, μm, nm, ms, μs, ns, mg). Less common but mathematically
  // valid forms — pm, fm, am, dm, hm, Mm, Gm, Tm, Pm, Em, Zm, Ym, ps,
  // fs, as, das, hs, Ms, Gs, Ts, etc. — are synthesized on demand by
  // [bySymbolWithPrefixes].

  /// Standard SI prefixes (and their powers-of-ten multipliers).
  /// Longest spellings first; `da` and `μ`-vs-`u` are intentional.
  static const Map<String, double> siPrefixes = {
    // Long prefixes first so longest-match works.
    'da': 1e1,
    'Y': 1e24,
    'Z': 1e21,
    'E': 1e18,
    'P': 1e15,
    'T': 1e12,
    'G': 1e9,
    'M': 1e6,
    'k': 1e3,
    'h': 1e2,
    'd': 1e-1,
    'c': 1e-2,
    'm': 1e-3,
    'μ': 1e-6,
    'u': 1e-6, // ASCII alternative for μ
    'n': 1e-9,
    'p': 1e-12,
    'f': 1e-15,
    'a': 1e-18,
    'z': 1e-21,
    'y': 1e-24,
  };

  /// Catalog symbols that accept SI prefixes. Restricted to the canonical
  /// SI metric units so the prefix parser can't accidentally turn `min`
  /// into "milli-inches" or `kt` into "kilo-tonnes".
  static const Set<String> prefixableSymbols = {
    'm', // metre
    's', // second
    'g', // gram
    'K', // kelvin
    'rad', // radian
  };

  /// Like [bySymbol], plus the SI prefix parser. If [symbol] isn't in
  /// the curated catalog, tries to split off an SI prefix and re-look
  /// up the remainder against [prefixableSymbols], returning a
  /// synthesized [Unit] with the prefix's scale folded in.
  static Unit? bySymbolWithPrefixes(String symbol) {
    final direct = bySymbol(symbol);
    if (direct != null) return direct;

    // Try every prefix in longest-first order so `da` (deca) is tried
    // before `d` (deci).
    final prefixesByLength = siPrefixes.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final prefix in prefixesByLength) {
      if (!symbol.startsWith(prefix)) continue;
      final rest = symbol.substring(prefix.length);
      if (!prefixableSymbols.contains(rest)) continue;
      final base = bySymbol(rest);
      if (base == null) continue;
      final scale = siPrefixes[prefix]! * base.scale;
      return Unit(
        symbol: symbol,
        name: '$prefix${base.name}',
        dimension: base.dimension,
        scale: scale,
      );
    }
    return null;
  }

  /// All synthesizable prefixed symbols beyond the curated set — used by
  /// the inline-parser tokenizer to extend its longest-first match list.
  static List<String> prefixedSymbols() {
    final out = <String>[];
    for (final base in prefixableSymbols) {
      for (final prefix in siPrefixes.keys) {
        final combined = '$prefix$base';
        // Skip combinations already curated (e.g. km, cm, mm, ms, μs).
        if (bySymbol(combined) != null) continue;
        // Skip if the combined string collides with another curated
        // symbol (e.g. `t` alone is tonne in the mass dimension, so
        // never let prefix `t` produce something with collision).
        out.add(combined);
      }
    }
    return out;
  }
}
