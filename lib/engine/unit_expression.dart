// lib/engine/unit_expression.dart
//
// Inline unit arithmetic — V1. Lets a user type `5 km + 3 m`,
// `1 mile - 200 yd`, or `100 km in mph` directly in the calculator
// and get back a quantity with a unit. Same-dimension `+` / `-`
// only; `in <unit>` suffix converts the result.
//
// Why a separate evaluator instead of extending SymEngine: SymEngine's
// parser doesn't know about units (km, ft, hr, …) and treats them as
// free variables, leading to either parse errors or symbolic
// expressions like `5*k*m + 3*m`. We intercept before SymEngine sees
// the input.
//
// V3 adds SI prefix parsing — `5 pm + 3 nm`, `1 Tm`, `42 μK` all parse
// without needing an explicit catalog entry per prefixed form. Built
// on top of UnitCatalog.bySymbolWithPrefixes(), which derives the
// scale automatically from prefix × base.
//
// V4 adds scalar arithmetic on a quantity — `2 * 5 km`, `5 km * 2`,
// `1 mile / 2`. Scalar mul/div is rejected after a `+`/`-` has
// appeared, because we don't run a real precedence parser and silent
// mixing would surprise users (`5 km + 2 m * 3` is ambiguous).
//
// V5 adds composite-dimension arithmetic — `100 m / 10 s = 10 m/s`,
// `5 m * 3 m = 15 m^2`, derived SI units (N, J, W, Pa, Hz with SI
// prefixes), and quantity × quantity inside the same expression. The
// evaluator tracks the running quantity as `(value_in_coherent_SI,
// Dimensions)` so multiplication / division extend the dimension
// vector naturally. Parens and variables are still deferred.

import 'unit_catalog.dart';
import 'unit_converter.dart';

class UnitExpressionEvaluator {
  /// Try to evaluate [expression] as a unit-arithmetic expression.
  /// Returns the formatted result string on success, or null when
  /// the expression doesn't look like one (caller should fall back
  /// to the regular scalar evaluator).
  ///
  /// Supported shapes:
  ///   - `<number> <unit>` (single quantity, returned as-is)
  ///   - `<number> <unit> {+|-} <number> <unit> …` (same dimension)
  ///   - V4: optional leading scalar (`<scalar> * <quantity-expression>`)
  ///     and trailing scalar `*`/`/` on the leading quantity (e.g.
  ///     `5 km * 2`, `5 km / 2`). Scalar arithmetic is rejected once a
  ///     `+`/`-` has appeared, because mixing them silently would give
  ///     wrong precedence (`5 km + 2 m * 3` is ambiguous without a
  ///     proper Shunting-yard pass).
  ///   - any of the above followed by ` in <unit>` to convert
  static String? tryEvaluate(String expression) {
    final tokens = _tokenize(expression);
    if (tokens == null) return null; // unrecognized — let other path handle
    if (tokens.isEmpty) return null;

    // Split off optional `in <unit>` suffix.
    Unit? targetUnit;
    var workingTokens = tokens;
    if (tokens.length >= 2 &&
        tokens[tokens.length - 2] is _InKeyword &&
        tokens.last is _UnitToken) {
      targetUnit = (tokens.last as _UnitToken).unit;
      workingTokens = tokens.sublist(0, tokens.length - 2);
    }

    if (workingTokens.isEmpty) return null;

    // V4: leading scalar prefix like `2 * 5 km`. Peel off the prefix and
    // stash its value to apply at the end. Only applies when the head is
    // [number, *, ...].
    var scalarPrefix = 1.0;
    if (workingTokens.length >= 3 &&
        workingTokens[0] is _NumberToken &&
        workingTokens[1] is _BinaryOp &&
        (workingTokens[1] as _BinaryOp).symbol == '*') {
      scalarPrefix = (workingTokens[0] as _NumberToken).value;
      workingTokens = workingTokens.sublist(2);
    }

    // Must start with a quantity (number + unit).
    final first = _consumeQuantity(workingTokens, 0);
    if (first == null) return null;

    // Running quantity tracked in coherent-SI value + Dimensions vector.
    // We carry an Anchor unit (the first term's display unit) so the
    // output formatter can default to it when no composite-dim result
    // shows up and no explicit `in` target is set.
    var siValue = first.value.toCoherentSi();
    var dim = first.value.dim;
    final anchorSingleDim = first.value.singleDimUnit;
    var hadSumOp = false;
    var sawCompositeOp = false;

    // Walk the rest: a mix of (+/-) <quantity> and (*/÷) (<scalar> or <quantity>).
    var i = first.nextIndex;
    while (i < workingTokens.length) {
      final op = workingTokens[i];
      if (op is! _BinaryOp) return null;

      if (op.symbol == '*' || op.symbol == '/') {
        if (i + 1 >= workingTokens.length) return null;
        final rhs = workingTokens[i + 1];
        if (rhs is! _NumberToken) return null;
        // Distinguish scalar (`* 2`) from quantity (`* 2 m`).
        final rhsIsQuantity =
            i + 2 < workingTokens.length && workingTokens[i + 2] is _UnitToken;
        if (rhsIsQuantity) {
          // V5: composite-dimension arithmetic. Refuse after a sum op
          // — precedence is ambiguous in `5 m + 2 m * 3 s` without a
          // proper expression parser.
          if (hadSumOp) return null;
          // Reject if either side carries an offset (temperature) —
          // would mean adding 273.15 K to a non-temperature value.
          if (_hasNonZeroOffset(anchorSingleDim) ||
              _hasNonZeroOffset(
                  (workingTokens[i + 2] as _UnitToken).singleDim)) {
            return 'Error: temperature arithmetic is ambiguous with '
                'offset units. Use the Unit converter dialog for °C ↔ °F ↔ K.';
          }
          final rhsQty = _Quantity.fromNumberUnit(
              rhs.value, workingTokens[i + 2] as _UnitToken);
          if (op.symbol == '*') {
            siValue *= rhsQty.toCoherentSi();
            dim = dim * rhsQty.dim;
          } else {
            final rhsSi = rhsQty.toCoherentSi();
            if (rhsSi == 0) {
              return 'Error: division by zero in unit expression';
            }
            siValue /= rhsSi;
            dim = dim / rhsQty.dim;
          }
          sawCompositeOp = true;
          i += 3;
          continue;
        }
        // V4 scalar multiply/divide.
        if (hadSumOp) return null;
        if (op.symbol == '*') {
          siValue *= rhs.value;
        } else {
          if (rhs.value == 0) {
            return 'Error: division by zero in unit expression';
          }
          siValue /= rhs.value;
        }
        i += 2;
        continue;
      }

      if (op.symbol != '+' && op.symbol != '-') return null;
      // Composite-dim accumulator can't take a sum op — what would
      // `10 m/s + 5 m` even mean. Bail with a clear error.
      if (sawCompositeOp) {
        return 'Error: cannot add or subtract after a composite-dimension '
            'multiplication / division.';
      }
      hadSumOp = true;
      final next = _consumeQuantity(workingTokens, i + 1);
      if (next == null) return null;
      if (next.value.dim != dim) {
        return 'Error: cannot ${op.symbol == '+' ? 'add' : 'subtract'} '
            '${next.value.label} '
            'to ${first.value.label}';
      }
      // Temperature inline arithmetic is ambiguous (offset units), so
      // we refuse it. Conversion via `in` is fine.
      if (_hasNonZeroOffset(anchorSingleDim)) {
        return 'Error: temperature arithmetic is ambiguous with offset '
            'units. Use the Unit converter dialog for °C ↔ °F ↔ K.';
      }
      final delta = next.value.toCoherentSi();
      siValue += op.symbol == '+' ? delta : -delta;
      i = next.nextIndex;
    }

    // Apply the leading scalar prefix (V4).
    siValue *= scalarPrefix;

    // Decide output unit.
    if (targetUnit != null) {
      if (Dimensions.of(targetUnit.dimension) != dim) {
        return 'Error: cannot convert result (${_dimLabel(dim)}) to '
            '${targetUnit.symbol} (${targetUnit.dimension.name})';
      }
      // The target unit's `toBase` understands offset (for temperature
      // back-conversion if we ever loosen the rejection above). Coherent
      // SI for the supported single-dim catalog matches the target's
      // base, so direct fromBase works.
      final out = targetUnit.fromBase(siValue);
      return UnitConverter.format(out, targetUnit);
    }

    // No explicit target. For pure single-dim results, keep the
    // first-term display unit (`5 km + 3 m` shows in km). For composite
    // results, pick the best derived unit (`100 m / 10 s` → m/s) or
    // synthesize a base-units string (`5 m * 3 m` → 15 m^2).
    return _formatResult(siValue, dim, anchorSingleDim);
  }

  /// Picks the cleanest display for a (value, dimensions) pair.
  ///   1. If dim matches the anchor single-dim unit, use that
  ///      (preserves first-term unit choice across `+`/`-` chains).
  ///   2. Otherwise, search the single-dim catalog for an exact dim
  ///      match (`100 m / 10 s` → m/s via the velocity dim entry).
  ///   3. Otherwise, search the derived-unit table (`5 N`, `60 Hz`).
  ///   4. Otherwise, format as base-unit string (`15 m^2`, `2 m/s^2`).
  static String _formatResult(
      double siValue, Dimensions dim, Unit? anchorSingleDim) {
    if (dim.isZero) {
      // Dimensionless — return the bare number (e.g. `5 m / 5 m`).
      return UnitConverter.format(siValue, _dimensionlessUnit);
    }
    if (anchorSingleDim != null &&
        Dimensions.of(anchorSingleDim.dimension) == dim) {
      final out = anchorSingleDim.fromBase(siValue);
      return UnitConverter.format(out, anchorSingleDim);
    }
    // Search single-dim catalog for a coherent-SI exact match.
    for (final d in UnitCatalog.allDimensions()) {
      if (Dimensions.of(d) != dim) continue;
      // Use the dimension's coherent-SI base (first list entry whose
      // scale == 1 and offset == 0).
      for (final u in UnitCatalog.unitsFor(d)) {
        if (u.scale == 1.0 && u.offset == 0.0) {
          return UnitConverter.format(u.fromBase(siValue), u);
        }
      }
    }
    // Derived-unit table.
    final derived = DerivedUnits.matchingBaseDim(dim);
    if (derived != null) {
      return '${_formatNumber(derived.fromSi(siValue))} ${derived.symbol}';
    }
    // Base-unit string fallback.
    return '${_formatNumber(siValue)} ${dim.toBaseUnitsString()}';
  }

  static bool _hasNonZeroOffset(Unit? u) => u != null && u.offset != 0.0;

  /// Human label for an arbitrary Dimensions vector — used in error
  /// messages so the user sees `m/s` rather than `(length=1, time=-1)`.
  static String _dimLabel(Dimensions d) {
    final base = d.toBaseUnitsString();
    return base.isEmpty ? 'dimensionless' : base;
  }

  /// A synthetic dimensionless unit for `5 m / 5 m`-style results. Just
  /// reuses radian's symbol-free behavior — we don't want to show "rad".
  static const _dimensionlessUnit = Unit(
    symbol: '',
    name: '(dimensionless)',
    dimension: UnitDimension.angle,
    scale: 1.0,
  );

  /// Display a double cleanly — drops trailing zeros, keeps integer
  /// results as integers. Mirrors what `UnitConverter.format` does
  /// internally, but we need it standalone for the derived-unit and
  /// base-units paths since those bypass the curated formatter.
  static String _formatNumber(double v) {
    if (!v.isFinite) return v.toString();
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toInt().toString();
    }
    var s = v.toStringAsFixed(6);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Tokenize [s]. Returns null on any unrecognized token — the caller
  /// will fall through to the scalar evaluator. A successful tokenize
  /// is the signal that "this looks like a unit expression."
  static List<_Token>? _tokenize(String s) {
    final out = <_Token>[];
    var i = 0;
    final n = s.length;

    // Build a list of unit symbols longest-first so multi-char units
    // (m/s, km/h, mph) match before the bare alternatives.
    final symbols = <String>[
      for (final dim in UnitCatalog.allDimensions())
        for (final u in UnitCatalog.unitsFor(dim)) u.symbol,
      // Natural-spelling aliases for the user-facing inline syntax.
      // The longest-first sort handles overlap (`miles` before `mi`).
      ..._aliases.keys,
      // SI-prefixed forms that aren't already in the curated catalog
      // (pm, fm, am, dm, hm, dam, Mm, Gm, Tm, Pm, Em, Zm, Ym, etc., and
      // the analogous time / mass / kelvin / radian variants).
      ...UnitCatalog.prefixedSymbols(),
      // V5: derived SI units (N, J, W, Pa, Hz) and their prefixed
      // variants (kN, MJ, mW, …).
      ...DerivedUnits.allSymbols(),
      ...DerivedUnits.prefixedSymbols(),
    ];
    symbols.sort((a, b) => b.length.compareTo(a.length));

    while (i < n) {
      final c = s[i];
      // Whitespace.
      if (c == ' ' || c == '\t' || c == '\n') {
        i++;
        continue;
      }
      // Number — leading optional sign handled by the parser via `+`/`-`
      // operators; here we accept digits, decimal point, and `e`/`E`
      // for scientific notation.
      if (_isDigit(c) || (c == '.' && i + 1 < n && _isDigit(s[i + 1]))) {
        final start = i;
        var sawDot = false;
        var sawE = false;
        while (i < n) {
          final ch = s[i];
          if (_isDigit(ch)) {
            i++;
            continue;
          }
          if (ch == '.' && !sawDot && !sawE) {
            sawDot = true;
            i++;
            continue;
          }
          if ((ch == 'e' || ch == 'E') && !sawE) {
            sawE = true;
            i++;
            if (i < n && (s[i] == '+' || s[i] == '-')) i++;
            continue;
          }
          break;
        }
        final value = double.tryParse(s.substring(start, i));
        if (value == null) return null;
        out.add(_NumberToken(value));
        continue;
      }
      // `in` keyword (must be a whole word, lowercase).
      if (i + 1 < n &&
          s[i] == 'i' &&
          s[i + 1] == 'n' &&
          (i + 2 == n || _isWordBoundary(s[i + 2]))) {
        out.add(const _InKeyword());
        i += 2;
        continue;
      }
      // Operator.
      if (c == '+' || c == '-' || c == '*' || c == '/') {
        // Special-case: `/` might be the leading character of a unit
        // symbol like `m/s`. Try to match a unit first.
        if (c == '/') {
          final matched = _tryMatchUnitAt(s, i, symbols);
          if (matched != null) {
            // No number ahead of this unit means it's a stray slash —
            // bail out so the scalar evaluator handles it.
            return null;
          }
        }
        out.add(_BinaryOp(c));
        i++;
        continue;
      }
      // Unit symbol (longest match wins).
      final matched = _tryMatchUnitAt(s, i, symbols);
      if (matched != null) {
        out.add(matched.unit != null
            ? _UnitToken.single(matched.unit!)
            : _UnitToken.derived(matched.derived!));
        i = matched.endIndex;
        continue;
      }
      // Unrecognized character — not a unit expression.
      return null;
    }

    return out;
  }

  static _UnitMatch? _tryMatchUnitAt(
      String s, int start, List<String> symbolsLongestFirst) {
    for (final sym in symbolsLongestFirst) {
      if (start + sym.length > s.length) continue;
      if (s.substring(start, start + sym.length) != sym) continue;
      // Word-boundary check: if the next char is alphanumeric or `_`,
      // this was a substring of a longer name and shouldn't match.
      final after = start + sym.length < s.length ? s[start + sym.length] : '';
      if (after.isNotEmpty && _isWordChar(after)) continue;
      // Look up either as a catalog symbol directly, via the natural-
      // spelling alias map, or via the SI prefix parser (which handles
      // forms like `pm`, `Tm`, `μs` that aren't in the curated list).
      final canonical = _aliases[sym] ?? sym;
      final u = UnitCatalog.bySymbolWithPrefixes(canonical);
      if (u != null) {
        return _UnitMatch.single(u, start + sym.length);
      }
      // V5: try the derived-unit catalog (N, J, W, Pa, Hz + SI prefixes).
      final d = DerivedUnits.bySymbolWithPrefixes(canonical);
      if (d != null) {
        return _UnitMatch.derived(d, start + sym.length);
      }
    }
    return null;
  }

  /// Natural-spelling aliases mapping to catalog symbols. The inline
  /// input is conversational ("5 mile + 200 yard"); the catalog uses
  /// standard abbreviations. Kept short to avoid bloating the
  /// tokenizer's longest-match pass.
  static const Map<String, String> _aliases = {
    'mile': 'mi',
    'miles': 'mi',
    'yard': 'yd',
    'yards': 'yd',
    'foot': 'ft',
    'feet': 'ft',
    'inch': 'in',
    'inches': 'in',
    'meter': 'm',
    'meters': 'm',
    'metre': 'm',
    'metres': 'm',
    'sec': 's',
    'secs': 's',
    'second': 's',
    'seconds': 's',
    'minute': 'min',
    'minutes': 'min',
    'hour': 'h',
    'hours': 'h',
    'day': 'd',
    'days': 'd',
    'year': 'yr',
    'years': 'yr',
    'gram': 'g',
    'grams': 'g',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'pound': 'lb',
    'pounds': 'lb',
    'ounce': 'oz',
    'ounces': 'oz',
    'tonne': 't',
    'tonnes': 't',
    'tons': 't',
    'degree': '°',
    'degrees': '°',
  };

  static _Consumed? _consumeQuantity(List<_Token> toks, int i) {
    if (i + 1 >= toks.length) return null;
    final num = toks[i];
    final unit = toks[i + 1];
    if (num is! _NumberToken || unit is! _UnitToken) return null;
    return _Consumed(
      _Quantity.fromNumberUnit(num.value, unit),
      i + 2,
    );
  }

  static bool _isDigit(String c) => '0123456789'.contains(c);
  static bool _isWordChar(String c) =>
      _isDigit(c) || (c.toLowerCase() != c.toUpperCase()) || c == '_';
  static bool _isWordBoundary(String c) => !_isWordChar(c);
}

// === Internal types ======================================================

sealed class _Token {
  const _Token();
}

class _NumberToken extends _Token {
  final double value;
  _NumberToken(this.value);
}

class _UnitToken extends _Token {
  /// Single-dim catalog unit. Null when [derived] is set.
  final Unit? unit;

  /// Composite-dim derived unit (N, J, W, Pa, Hz). Null when [unit] is set.
  final DerivedUnit? derived;

  _UnitToken._(this.unit, this.derived);

  factory _UnitToken.single(Unit u) => _UnitToken._(u, null);
  factory _UnitToken.derived(DerivedUnit d) => _UnitToken._(null, d);

  /// Returns the underlying single-dim Unit, or null if this is a
  /// derived unit. Used by the evaluator's "anchor" tracking so chains
  /// of `+`/`-` can preserve the first-term display unit.
  Unit? get singleDim => unit;

  Dimensions get dim =>
      unit != null ? Dimensions.of(unit!.dimension) : derived!.dim;

  String get symbol => unit?.symbol ?? derived!.symbol;

  /// Convert a value expressed in this unit into the coherent SI form.
  double toSi(double v) => unit != null ? unit!.toBase(v) : derived!.toSi(v);
}

class _BinaryOp extends _Token {
  final String symbol;
  _BinaryOp(this.symbol);
}

class _InKeyword extends _Token {
  const _InKeyword();
}

/// Running-value wrapper for the evaluator. Holds the coherent-SI value,
/// its [Dimensions], the underlying single-dim Unit (when one applies —
/// used for display preservation across `+`/`-` chains), and a label
/// for error messages.
class _Quantity {
  final double siValue;
  final Dimensions dim;
  final Unit? singleDimUnit;
  final String label;

  const _Quantity._(this.siValue, this.dim, this.singleDimUnit, this.label);

  factory _Quantity.fromNumberUnit(double v, _UnitToken t) {
    return _Quantity._(t.toSi(v), t.dim, t.singleDim, '$v ${t.symbol}');
  }

  double toCoherentSi() => siValue;
}

class _UnitMatch {
  final Unit? unit;
  final DerivedUnit? derived;
  final int endIndex;
  const _UnitMatch._(this.unit, this.derived, this.endIndex);
  factory _UnitMatch.single(Unit u, int end) => _UnitMatch._(u, null, end);
  factory _UnitMatch.derived(DerivedUnit d, int end) =>
      _UnitMatch._(null, d, end);
}

class _Consumed {
  final _Quantity value;
  final int nextIndex;
  const _Consumed(this.value, this.nextIndex);
}
