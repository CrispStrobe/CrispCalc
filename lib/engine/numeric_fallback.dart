// lib/engine/numeric_fallback.dart
//
// Pure-Dart numeric expression evaluator — the web (and any other
// native-less) fallback for CalculatorEngine.evaluate().
//
// SymEngine (the symbolic core) is C++/FFI and does not run on the web
// target, so on the browser build every scalar expression — even
// `123 + 45` — used to return "requires native library". This evaluator
// resolves the *numeric* subset (arithmetic, the common transcendental
// functions, and the usual constants) entirely in Dart, so basic math
// works in the browser. It deliberately does NOT attempt symbolic work:
// anything with a free variable, a matrix literal, or an unknown
// function returns null, and the caller falls back to the native-only
// path (which surfaces the "get the app" message for genuinely symbolic
// input).
//
// Results are decimal (double) — exact rationals / symbolic simplification
// (`1/3`, `sqrt(2)`) remain native-only; here `1/3` → `0.333333333333`.
//
// Input is the already-preprocessed, SymEngine-flavoured string
// (`^` for power, `*`/`/`, `pi`, `E`, `sqrt(...)`, …) produced by
// ExpressionPreprocessingUtils, so the grammar mirrors that dialect.

import 'dart:math' as math;

class NumericFallbackEvaluator {
  /// Evaluate [expression] numerically and return a formatted result
  /// string, or null when it can't be handled purely in Dart (free
  /// variables, unknown functions, matrices, parse errors, or a
  /// non-finite result). Returning null lets the caller fall through to
  /// the native bridge / "requires native library" path.
  static String? tryEvaluate(String expression) {
    final value = evalNumeric(expression);
    if (value == null || !value.isFinite) return null;
    return _format(value);
  }

  /// Core numeric evaluation. [vars] binds free identifiers (e.g.
  /// `{'x': 2.0}`) so the same evaluator can back graphing later;
  /// unbound identifiers (other than known constants) make the parse
  /// fail and yield null. Returns null on any parse/eval failure.
  static double? evalNumeric(String expression, [Map<String, double>? vars]) {
    try {
      final parser = _Parser(expression, vars ?? const {});
      final result = parser.parse();
      return result;
    } catch (_) {
      return null;
    }
  }

  static String _format(double v) {
    if (v == 0) return '0'; // also collapses -0.0
    // Integer-valued within double's exact-integer range → no ".0".
    if (v == v.roundToDouble() && v.abs() < 1e16) {
      return v.toStringAsFixed(0);
    }
    var s = v.toStringAsPrecision(12);
    if (s.contains('e') || s.contains('E')) return s; // keep sci-notation
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}

/// Thrown internally on any unparseable / unsupported construct; caught
/// by [NumericFallbackEvaluator.evalNumeric] and turned into null.
class _EvalException implements Exception {
  final String message;
  _EvalException(this.message);
  @override
  String toString() => 'EvalException: $message';
}

const _constants = <String, double>{
  'pi': math.pi,
  'PI': math.pi,
  'e': math.e,
  'E': math.e,
  'tau': math.pi * 2,
};

final _functions = <String, double Function(double)>{
  'sqrt': math.sqrt,
  'cbrt': (x) =>
      x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble(),
  'exp': math.exp,
  'ln': math.log,
  'log': math.log, // natural log, matching SymEngine
  'log10': (x) => math.log(x) / math.ln10,
  'lg': (x) => math.log(x) / math.ln10,
  'log2': (x) => math.log(x) / math.ln2,
  'abs': (x) => x.abs(),
  'sin': math.sin,
  'cos': math.cos,
  'tan': math.tan,
  'asin': math.asin,
  'acos': math.acos,
  'atan': math.atan,
  'sinh': (x) => (math.exp(x) - math.exp(-x)) / 2,
  'cosh': (x) => (math.exp(x) + math.exp(-x)) / 2,
  'tanh': (x) {
    final a = math.exp(x), b = math.exp(-x);
    return (a - b) / (a + b);
  },
  'asinh': (x) => math.log(x + math.sqrt(x * x + 1)),
  'acosh': (x) => math.log(x + math.sqrt(x * x - 1)),
  'atanh': (x) => 0.5 * math.log((1 + x) / (1 - x)),
  'floor': (x) => x.floorToDouble(),
  'ceil': (x) => x.ceilToDouble(),
  'ceiling': (x) => x.ceilToDouble(),
  'round': (x) => x.roundToDouble(),
  'trunc': (x) => x.truncateToDouble(),
  'sign': (x) => x.sign,
  'gamma': _gamma,
};

/// Lanczos approximation of the Gamma function (g=7, n=9), reflection
/// for x < 0.5. Good to ~14 digits — enough for the numeric fallback.
double _gamma(double x) {
  const g = 7.0;
  const c = <double>[
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];
  if (x < 0.5) {
    return math.pi / (math.sin(math.pi * x) * _gamma(1 - x));
  }
  x -= 1;
  var a = c[0];
  final t = x + g + 0.5;
  for (var i = 1; i < c.length; i++) {
    a += c[i] / (x + i);
  }
  return math.sqrt(2 * math.pi) * math.pow(t, x + 0.5) * math.exp(-t) * a;
}

/// Recursive-descent parser/evaluator over the SymEngine-flavoured
/// numeric dialect. Tokenizes lazily via index walking on the source.
class _Parser {
  final String src;
  final Map<String, double> vars;
  int _pos = 0;

  _Parser(this.src, this.vars);

  double parse() {
    final v = _parseExpr();
    _skipWs();
    if (_pos != src.length) {
      throw _EvalException('trailing input at $_pos');
    }
    return v;
  }

  // expr := term (('+' | '-') term)*
  double _parseExpr() {
    var value = _parseTerm();
    while (true) {
      _skipWs();
      final c = _peek();
      if (c == '+') {
        _pos++;
        value += _parseTerm();
      } else if (c == '-') {
        _pos++;
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  // term := unary (('*' | '/' | '%') unary | implicit-mult unary)*
  double _parseTerm() {
    var value = _parseUnary();
    while (true) {
      _skipWs();
      final c = _peek();
      if (c == '*') {
        _pos++;
        value *= _parseUnary();
      } else if (c == '/') {
        _pos++;
        value /= _parseUnary();
      } else if (c == '%') {
        _pos++;
        value = value % _parseUnary();
      } else if (_startsImplicitFactor(c)) {
        // Implicit multiplication: `2pi`, `2sin(1)`, `(1+1)pi`.
        value *= _parseUnary();
      } else {
        return value;
      }
    }
  }

  bool _startsImplicitFactor(String? c) {
    if (c == null) return false;
    return _isDigit(c) || c == '.' || c == '(' || _isAlpha(c);
  }

  // unary := ('+' | '-')* power
  double _parseUnary() {
    _skipWs();
    final c = _peek();
    if (c == '+') {
      _pos++;
      return _parseUnary();
    }
    if (c == '-') {
      _pos++;
      return -_parseUnary();
    }
    return _parsePower();
  }

  // power := primary ('^' unary)?   (right-associative; `2^-3`, `-2^2`)
  double _parsePower() {
    final base = _parsePrimary();
    _skipWs();
    if (_peek() == '^') {
      _pos++;
      final exp = _parseUnary();
      return math.pow(base, exp).toDouble();
    }
    return base;
  }

  // primary := number | constant | func '(' expr ')' | '(' expr ')' | var
  double _parsePrimary() {
    _skipWs();
    final c = _peek();
    if (c == null) throw _EvalException('unexpected end');
    if (c == '(') {
      _pos++;
      final v = _parseExpr();
      _skipWs();
      if (_peek() != ')') throw _EvalException('expected )');
      _pos++;
      return v;
    }
    if (_isDigit(c) || c == '.') return _parseNumber();
    if (_isAlpha(c)) return _parseIdentifier();
    throw _EvalException('unexpected "$c"');
  }

  double _parseNumber() {
    final start = _pos;
    while (_pos < src.length && _isDigit(src[_pos])) {
      _pos++;
    }
    if (_pos < src.length && src[_pos] == '.') {
      _pos++;
      while (_pos < src.length && _isDigit(src[_pos])) {
        _pos++;
      }
    }
    // Scientific notation: e/E followed by optional sign + digits, only
    // when digits actually follow (otherwise the `e` is Euler's constant
    // sitting after an implicit-multiplication boundary).
    if (_pos < src.length && (src[_pos] == 'e' || src[_pos] == 'E')) {
      var look = _pos + 1;
      if (look < src.length && (src[look] == '+' || src[look] == '-')) {
        look++;
      }
      if (look < src.length && _isDigit(src[look])) {
        _pos = look;
        while (_pos < src.length && _isDigit(src[_pos])) {
          _pos++;
        }
      }
    }
    final text = src.substring(start, _pos);
    final v = double.tryParse(text);
    if (v == null) throw _EvalException('bad number "$text"');
    return v;
  }

  double _parseIdentifier() {
    final start = _pos;
    while (_pos < src.length && _isWordChar(src[_pos])) {
      _pos++;
    }
    final name = src.substring(start, _pos);
    _skipWs();
    // Function call?
    if (_peek() == '(') {
      final fn = _functions[name];
      if (fn == null) throw _EvalException('unknown function "$name"');
      _pos++; // consume '('
      final arg = _parseExpr();
      _skipWs();
      // Reject multi-arg calls — this evaluator only does unary funcs.
      if (_peek() == ',') throw _EvalException('multi-arg "$name"');
      if (_peek() != ')') throw _EvalException('expected ) after $name(');
      _pos++;
      return fn(arg);
    }
    // Constant?
    final konst = _constants[name];
    if (konst != null) return konst;
    // Bound variable?
    final bound = vars[name];
    if (bound != null) return bound;
    // Free variable / unknown symbol → not numeric.
    throw _EvalException('free symbol "$name"');
  }

  String? _peek() => _pos < src.length ? src[_pos] : null;

  void _skipWs() {
    while (_pos < src.length && src[_pos] == ' ') {
      _pos++;
    }
  }

  static bool _isDigit(String c) {
    final u = c.codeUnitAt(0);
    return u >= 48 && u <= 57;
  }

  static bool _isAlpha(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 65 && u <= 90) || (u >= 97 && u <= 122) || c == '_';
  }

  static bool _isWordChar(String c) => _isAlpha(c) || _isDigit(c);
}
