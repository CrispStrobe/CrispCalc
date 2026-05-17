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
// V2 territory (deferred): derived units (`m/s² * 2 s`), composite
// dimensions for division, scalar * quantity, parens, variables.
// V1 covers the most common conversion + arithmetic flows.

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

    // Must start with a quantity (number + unit).
    final first = _consumeQuantity(workingTokens, 0);
    if (first == null) return null;

    // Initialize the running quantity in the dimension's base unit.
    var basePos = first.value.unit.toBase(first.value.value);
    final dim = first.value.unit.dimension;

    // Walk the rest: (+ | -) <number> <unit> repeated.
    var i = first.nextIndex;
    while (i < workingTokens.length) {
      final op = workingTokens[i];
      if (op is! _BinaryOp || (op.symbol != '+' && op.symbol != '-')) {
        return null;
      }
      final next = _consumeQuantity(workingTokens, i + 1);
      if (next == null) return null;
      if (next.value.unit.dimension != dim) {
        return 'Error: cannot ${op.symbol == '+' ? 'add' : 'subtract'} '
            '${next.value.unit.symbol} (${next.value.unit.dimension.name}) '
            'to ${first.value.unit.symbol} '
            '(${first.value.unit.dimension.name})';
      }
      // Temperature inline arithmetic is ambiguous (offset units), so
      // we refuse it. Conversion via `in` is fine.
      if (dim == UnitDimension.temperature) {
        return 'Error: temperature arithmetic is ambiguous with offset '
            'units. Use the Unit converter dialog for °C ↔ °F ↔ K.';
      }
      final delta = next.value.unit.toBase(next.value.value);
      basePos += op.symbol == '+' ? delta : -delta;
      i = next.nextIndex;
    }

    // Decide output unit.
    if (targetUnit != null) {
      if (targetUnit.dimension != dim) {
        return 'Error: cannot convert ${first.value.unit.symbol} '
            '(${dim.name}) to ${targetUnit.symbol} '
            '(${targetUnit.dimension.name})';
      }
      final out = targetUnit.fromBase(basePos);
      return UnitConverter.format(out, targetUnit);
    }
    // Default output unit = the unit of the first term. Keeps `5 km + 3 m`
    // showing in km, `1 mile - 200 yd` showing in miles. Avoids surprise
    // base-unit results for the user.
    final out = first.value.unit.fromBase(basePos);
    return UnitConverter.format(out, first.value.unit);
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
        out.add(_UnitToken(matched.unit));
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
      // Look up either as a catalog symbol directly, or via the
      // natural-spelling alias map.
      final canonical = _aliases[sym] ?? sym;
      final u = UnitCatalog.bySymbol(canonical);
      if (u == null) continue;
      return _UnitMatch(u, start + sym.length);
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
      _Quantity(num.value, unit.unit),
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
  final Unit unit;
  _UnitToken(this.unit);
}

class _BinaryOp extends _Token {
  final String symbol;
  _BinaryOp(this.symbol);
}

class _InKeyword extends _Token {
  const _InKeyword();
}

class _Quantity {
  final double value;
  final Unit unit;
  const _Quantity(this.value, this.unit);
}

class _UnitMatch {
  final Unit unit;
  final int endIndex;
  const _UnitMatch(this.unit, this.endIndex);
}

class _Consumed {
  final _Quantity value;
  final int nextIndex;
  const _Consumed(this.value, this.nextIndex);
}
