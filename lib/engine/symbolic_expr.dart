// lib/engine/symbolic_expr.dart
//
// General pure-Dart symbolic expression layer — the piece that makes
// the web build usable.
//
// Why this exists
// ---------------
// The web CAS is SymEngine compiled to WebAssembly, but the exported
// `flutter_symengine_evaluate` entry point is a *numeric* evaluator:
// it returns a complex double and throws a raw C++ exception the
// moment the expression contains a free symbol. Emscripten surfaces
// that exception to Dart as a bare `{excPtr: <int>}` JS object whose
// `toString()` is `[object Object]`, and the build has no
// `getExceptionMessage` helper exported, so the C++ message is not
// recoverable from Dart.
//
// The practical consequence, measured in a real browser: on web
// `sin(x)`, `x*y`, `1/x`, `sqrt(x)`, `abc`, `1/0` and every partially
// typed line (`2 +`, `y=`, `(3+4`) all produced
// "Error: evaluate failed: [object Object]".
//
// [SymbolicWeb] already covers *single-variable polynomials* in pure
// Dart, which is why `x + 1` and `x^2 + 2x + 1` worked. This module
// generalizes that to arbitrary expressions: multiple symbols,
// rational powers, function calls, and division — everything the
// notepad realistically sees.
//
// Design rules
// ------------
//   * Correct-or-silent. Every entry point returns `null` rather than
//     guessing when the input falls outside what it can represent
//     exactly. It never invents an answer.
//   * Exact arithmetic. Numeric literals become [Rational]s (`1.5` is
//     `3/2`), so no floating-point drift creeps into symbolic output.
//   * No auto-expansion. `(x+1)^2` stays `(x + 1)^2`; expanding is
//     `expand()`'s job, and silently expanding would surprise anyone
//     who typed the factored form deliberately.
//   * Output matches the app's existing convention (`^` for powers,
//     juxtaposed integer coefficients, `high-degree-first`, ` + ` /
//     ` - ` between terms) so results read identically to the native
//     SymEngine path — see `multivariate_poly.dart`'s printer.
//
// The parser is shared with [diagnoseExpression], which is what lets
// the Notepad tell "you are still typing" (`2 +`) apart from "this is
// wrong" (`foo(1)`) without a second grammar to keep in sync.

import 'polynomial.dart' show Rational;

// ---------------------------------------------------------------------------
// Diagnosis
// ---------------------------------------------------------------------------

/// What is wrong with an expression, when something is.
///
/// [incomplete] is the load-bearing one: it means the text is a valid
/// *prefix* of an expression, so the caller should stay quiet instead
/// of reporting an error. Every other value is a genuine mistake worth
/// surfacing to the user.
enum ExpressionProblem {
  /// Parses cleanly.
  none,

  /// Ran out of input mid-expression — `2 +`, `sin(`, `(3+4`, `y=`.
  /// The user is mid-keystroke; this is not an error.
  incomplete,

  /// A closing bracket with nothing open — `)`, `2+3)`.
  unbalancedClose,

  /// Called something that isn't a known function — `foo(1)`.
  unknownFunction,

  /// An exact division (or `0^-n`) by zero — `1/0`, `x/0`.
  divisionByZero,

  /// A known function called with the wrong number of arguments.
  wrongArity,

  /// Syntactically wrong in a way the user has to fix — `2..3`, `2,,3`.
  malformed,
}

/// A parse problem plus the detail the UI needs to phrase a message.
class ExpressionDiagnosis {
  final ExpressionProblem problem;

  /// For [ExpressionProblem.unknownFunction] / [ExpressionProblem.wrongArity]:
  /// the offending function name. `null` otherwise.
  final String? name;

  const ExpressionDiagnosis(this.problem, {this.name});

  static const ok = ExpressionDiagnosis(ExpressionProblem.none);

  bool get isIncomplete => problem == ExpressionProblem.incomplete;
  bool get isOk => problem == ExpressionProblem.none;

  @override
  String toString() =>
      'ExpressionDiagnosis(${problem.name}${name == null ? '' : ', $name'})';
}

/// Functions the symbolic layer recognizes, mapped to their accepted
/// argument counts. Anything outside this table is reported as
/// [ExpressionProblem.unknownFunction] rather than being passed through
/// as an opaque symbol — a typo like `sinn(x)` should say so, not
/// silently render as an unknown function application.
///
/// Kept deliberately close to the set the native bridge accepts so the
/// web and native builds agree on what "unknown function" means.
const Map<String, Set<int>> kKnownFunctions = {
  'sin': {1},
  'cos': {1},
  'tan': {1},
  'asin': {1},
  'acos': {1},
  'atan': {1},
  'atan2': {2},
  'sinh': {1},
  'cosh': {1},
  'tanh': {1},
  'asinh': {1},
  'acosh': {1},
  'atanh': {1},
  'sec': {1},
  'csc': {1},
  'cot': {1},
  'exp': {1},
  'ln': {1},
  'log': {1, 2},
  'log2': {1},
  'log10': {1},
  'sqrt': {1},
  'cbrt': {1},
  'abs': {1},
  'sign': {1},
  'floor': {1},
  'ceiling': {1},
  'ceil': {1},
  'round': {1},
  'min': {1, 2, 3, 4},
  'max': {1, 2, 3, 4},
  'gamma': {1},
  'factorial': {1},
  'gcd': {2},
  'lcm': {2},
  'mod': {2},
  'conjugate': {1},
  're': {1},
  'im': {1},
};

/// Symbols with a reserved mathematical meaning. They parse as plain
/// symbols (the symbolic layer keeps them exact rather than
/// substituting a float), but the printer leaves them untouched.
const Set<String> kKnownConstants = {'pi', 'e', 'E', 'I', 'inf', 'oo', 'gamma'};

// ---------------------------------------------------------------------------
// AST
// ---------------------------------------------------------------------------

/// Node of the symbolic expression tree.
///
/// Deliberately tiny: a rational literal, a symbol, n-ary sum, n-ary
/// product, a power, and a function call. Subtraction is `a + (-1)*b`
/// and division is `a * b^-1`, which is what lets the collectors in
/// [SymExpr.simplify] handle `x - x` and `x/x` without special cases.
abstract class SymExpr {
  const SymExpr();

  /// Canonical form: constants folded, like terms combined, like
  /// factors merged. Structurally equal expressions simplify to
  /// structurally equal trees, which is what [key] relies on.
  SymExpr simplify();

  /// Stable structural identity, used to group like terms/factors.
  String get key;

  /// True when the tree contains no free symbols.
  bool get isNumeric;

  /// Total polynomial-ish degree, used only for output ordering.
  int get sortDegree;
}

/// An exact rational literal.
class SymNum extends SymExpr {
  final Rational value;
  const SymNum(this.value);

  SymNum.fromInt(int v) : value = Rational.fromInt(v);

  static final zero = SymNum(Rational.zero);
  static final one = SymNum(Rational.one);

  bool get isZero => value.isZero;
  bool get isOne => value == Rational.one;

  @override
  SymExpr simplify() => this;
  @override
  String get key => 'n:${value.numerator}/${value.denominator}';
  @override
  bool get isNumeric => true;
  @override
  int get sortDegree => 0;
}

/// A free symbol or a named constant (`x`, `pi`).
class SymSym extends SymExpr {
  final String name;
  const SymSym(this.name);

  @override
  SymExpr simplify() => this;
  @override
  String get key => 's:$name';
  @override
  bool get isNumeric => false;
  @override
  int get sortDegree => 1;
}

/// n-ary sum.
class SymAdd extends SymExpr {
  final List<SymExpr> terms;
  const SymAdd(this.terms);

  @override
  SymExpr simplify() {
    // Flatten nested sums so `(a + b) + c` collects in one pass.
    final flat = <SymExpr>[];
    void flatten(SymExpr e) {
      final s = e.simplify();
      if (s is SymAdd) {
        for (final t in s.terms) {
          flatten(t);
        }
      } else {
        flat.add(s);
      }
    }

    for (final t in terms) {
      flatten(t);
    }

    // Split every term into (rational coefficient, symbolic rest) and
    // sum the coefficients per distinct rest — this is what turns
    // `x + x` into `2x` and `x - x` into `0`.
    var constant = Rational.zero;
    final coeffs = <String, Rational>{};
    final rests = <String, SymExpr>{};
    for (final t in flat) {
      final (coeff, rest) = _splitCoefficient(t);
      if (rest == null) {
        constant = constant + coeff;
        continue;
      }
      final k = rest.key;
      coeffs[k] = (coeffs[k] ?? Rational.zero) + coeff;
      rests[k] = rest;
    }

    final out = <SymExpr>[];
    for (final entry in coeffs.entries) {
      if (entry.value.isZero) continue;
      final rest = rests[entry.key]!;
      out.add(entry.value == Rational.one
          ? rest
          : SymMul([SymNum(entry.value), rest]).simplify());
    }
    if (!constant.isZero) out.add(SymNum(constant));

    if (out.isEmpty) return SymNum.zero;
    if (out.length == 1) return out.first;
    out.sort(_compareForDisplay);
    return SymAdd(out);
  }

  @override
  String get key =>
      'add:${(terms.map((t) => t.key).toList()..sort()).join(',')}';
  @override
  bool get isNumeric => terms.every((t) => t.isNumeric);
  @override
  int get sortDegree =>
      terms.fold(0, (m, t) => t.sortDegree > m ? t.sortDegree : m);
}

/// n-ary product.
class SymMul extends SymExpr {
  final List<SymExpr> factors;
  const SymMul(this.factors);

  @override
  SymExpr simplify() {
    final flat = <SymExpr>[];
    void flatten(SymExpr e) {
      final s = e.simplify();
      if (s is SymMul) {
        for (final f in s.factors) {
          flatten(f);
        }
      } else {
        flat.add(s);
      }
    }

    for (final f in factors) {
      flatten(f);
    }

    // Merge like bases by summing exponents; `x * x^-1` therefore
    // collapses to `x^0` → 1 without a dedicated cancellation rule.
    var coeff = Rational.one;
    final exps = <String, SymExpr>{};
    final bases = <String, SymExpr>{};
    for (final f in flat) {
      if (f is SymNum) {
        coeff = coeff * f.value;
        continue;
      }
      final (base, exp) = _splitPower(f);
      final k = base.key;
      exps[k] = exps.containsKey(k) ? SymAdd([exps[k]!, exp]).simplify() : exp;
      bases[k] = base;
    }

    if (coeff.isZero) return SymNum.zero;

    final out = <SymExpr>[];
    for (final entry in exps.entries) {
      final exp = entry.value;
      if (exp is SymNum && exp.isZero) continue; // x^0 == 1
      final base = bases[entry.key]!;
      out.add(exp is SymNum && exp.isOne ? base : SymPow(base, exp));
    }

    if (out.isEmpty) return SymNum(coeff);
    if (coeff != Rational.one) out.insert(0, SymNum(coeff));
    if (out.length == 1) return out.first;
    return SymMul(out);
  }

  @override
  String get key =>
      'mul:${(factors.map((f) => f.key).toList()..sort()).join(',')}';
  @override
  bool get isNumeric => factors.every((f) => f.isNumeric);
  @override
  int get sortDegree => factors.fold(0, (s, f) => s + f.sortDegree);
}

/// `base ^ exponent`.
class SymPow extends SymExpr {
  final SymExpr base;
  final SymExpr exponent;
  const SymPow(this.base, this.exponent);

  @override
  SymExpr simplify() {
    final b = base.simplify();
    final e = exponent.simplify();

    if (e is SymNum) {
      if (e.isZero) return SymNum.one; // x^0 (0^0 is treated as 1)
      if (e.isOne) return b;
      if (b is SymNum) {
        if (b.isZero && e.value.sign < 0) {
          throw const SymbolicException(ExpressionProblem.divisionByZero);
        }
        final folded = _powRational(b.value, e.value);
        if (folded != null) return SymNum(folded);
      }
      // (x^a)^b == x^(a*b) is only unconditionally sound for integer
      // b; for fractional b it loses a branch (`(x^2)^(1/2) != x`).
      if (b is SymPow && e.value.isInteger) {
        return SymPow(b.base, SymMul([b.exponent, e]).simplify()).simplify();
      }
      // (a*b)^n distributes over a product for integer n.
      if (b is SymMul && e.value.isInteger) {
        return SymMul(b.factors.map((f) => SymPow(f, e).simplify()).toList())
            .simplify();
      }
    }
    if (b is SymNum && b.isOne) return SymNum.one; // 1^x
    return SymPow(b, e);
  }

  @override
  String get key => 'pow:${base.key}^${exponent.key}';
  @override
  bool get isNumeric => base.isNumeric && exponent.isNumeric;
  @override
  int get sortDegree {
    final e = exponent;
    if (e is SymNum && e.value.isInteger) {
      final n = e.value.numerator.toInt();
      return base.sortDegree * (n > 0 ? n : 0);
    }
    return base.sortDegree;
  }
}

/// A function application, e.g. `sin(x)`.
class SymCall extends SymExpr {
  final String name;
  final List<SymExpr> args;
  const SymCall(this.name, this.args);

  @override
  SymExpr simplify() {
    final a = args.map((x) => x.simplify()).toList();
    // Only fold cases whose value is exactly representable as a
    // rational. `sin(1)` stays symbolic rather than becoming a float —
    // the numeric path upstream already handles fully numeric input,
    // and a float here would poison an otherwise exact result.
    final folded = _foldExactCall(name, a);
    if (folded != null) return folded;
    return SymCall(name, a);
  }

  @override
  String get key => 'call:$name(${args.map((a) => a.key).join(',')})';
  @override
  bool get isNumeric => args.every((a) => a.isNumeric);
  @override
  int get sortDegree =>
      args.fold(0, (m, a) => a.sortDegree > m ? a.sortDegree : m);
}

/// Thrown by the parser/simplifier and converted to an
/// [ExpressionDiagnosis] by the public entry points.
class SymbolicException implements Exception {
  final ExpressionProblem problem;
  final String? name;
  const SymbolicException(this.problem, {this.name});

  @override
  String toString() => 'SymbolicException(${problem.name})';
}

// ---------------------------------------------------------------------------
// Simplification helpers
// ---------------------------------------------------------------------------

/// Split [e] into a rational coefficient and the remaining symbolic
/// part (`null` when [e] is purely numeric). `3x` → `(3, x)`.
(Rational, SymExpr?) _splitCoefficient(SymExpr e) {
  if (e is SymNum) return (e.value, null);
  if (e is SymMul) {
    var coeff = Rational.one;
    final rest = <SymExpr>[];
    for (final f in e.factors) {
      if (f is SymNum) {
        coeff = coeff * f.value;
      } else {
        rest.add(f);
      }
    }
    if (rest.isEmpty) return (coeff, null);
    if (rest.length == 1) return (coeff, rest.first);
    return (coeff, SymMul(rest));
  }
  return (Rational.one, e);
}

/// Split [e] into (base, exponent). A non-power is `(e, 1)`.
(SymExpr, SymExpr) _splitPower(SymExpr e) {
  if (e is SymPow) return (e.base, e.exponent);
  return (e, SymNum.one);
}

/// `b ^ e` when the result is an exact rational, else null.
Rational? _powRational(Rational b, Rational e) {
  if (!e.isInteger) return null;
  final n = e.numerator; // exact integer, denominator is 1 here
  if (n.abs() > BigInt.from(4096)) return null; // runaway guard
  if (b.isZero) return n > BigInt.zero ? Rational.zero : null;
  final k = n.abs().toInt();
  var num = BigInt.one, den = BigInt.one;
  for (var i = 0; i < k; i++) {
    num *= b.numerator;
    den *= b.denominator;
  }
  return n > BigInt.zero ? Rational(num, den) : Rational(den, num);
}

/// Exactly-representable function values only. Returns null to leave
/// the call symbolic.
SymExpr? _foldExactCall(String name, List<SymExpr> args) {
  if (args.length == 1 && args.first is SymNum) {
    final v = (args.first as SymNum).value;
    switch (name) {
      case 'abs':
        return SymNum(v.abs);
      case 'sign':
        return SymNum(Rational.fromInt(v.sign));
      case 'sqrt':
        // Only when both numerator and denominator are perfect squares.
        final n = _exactSqrt(v.numerator), d = _exactSqrt(v.denominator);
        if (v.sign >= 0 && n != null && d != null) {
          return SymNum(Rational(n, d));
        }
        return null;
      case 'sin':
      case 'tan':
      case 'asin':
      case 'atan':
      case 'sinh':
      case 'tanh':
        return v.isZero ? SymNum.zero : null;
      case 'cos':
      case 'cosh':
        return v.isZero ? SymNum.one : null;
      case 'exp':
        return v.isZero ? SymNum.one : null;
      case 'ln':
      case 'log':
        return v == Rational.one ? SymNum.zero : null;
    }
  }
  return null;
}

/// Integer square root when [n] is a perfect square, else null.
BigInt? _exactSqrt(BigInt n) {
  if (n < BigInt.zero) return null;
  if (n <= BigInt.one) return n;
  var lo = BigInt.one, hi = n;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    final sq = mid * mid;
    if (sq == n) return mid;
    if (sq < n) {
      lo = mid + BigInt.one;
    } else {
      hi = mid - BigInt.one;
    }
  }
  return null;
}

/// Rank within a single degree: plain algebraic terms read before
/// function applications (`x + sin(x)`), and a bare constant always
/// comes last (`x^2 + 2x + 1`).
int _displayRank(SymExpr e) {
  if (e is SymNum) return 2;
  if (e is SymCall) return 1;
  return 0;
}

/// Display order: higher degree first, then rank, then a stable key
/// comparison so output never flickers between runs.
int _compareForDisplay(SymExpr a, SymExpr b) {
  final r = _displayRank(a).compareTo(_displayRank(b));
  if (r != 0) return r;
  final d = b.sortDegree.compareTo(a.sortDegree);
  if (d != 0) return d;
  return a.key.compareTo(b.key);
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

/// Recursive-descent parser for the expression grammar the notepad and
/// calculator accept. Mirrors `numeric_fallback.dart`'s parser (same
/// precedence, same implicit-multiplication rules) but builds a
/// symbolic tree instead of evaluating to a double.
///
///   expr    := term (('+' | '-') term)*
///   term    := unary (('*' | '/' | implicit) unary)*
///   unary   := ('+' | '-')* power
///   power   := postfix ('^' unary)?            // right-associative
///   postfix := primary '!'*
///   primary := number | ident ('(' args ')')? | '(' expr ')'
class SymParser {
  final String src;
  int _pos = 0;

  SymParser(this.src);

  /// Parse [src] completely. Throws [SymbolicException] describing the
  /// first problem found.
  SymExpr parse() {
    _skipWs();
    if (_pos >= src.length) {
      throw const SymbolicException(ExpressionProblem.incomplete);
    }
    final e = _parseExpr();
    _skipWs();
    if (_pos < src.length) {
      // Trailing junk. A stray `)` is its own diagnosis because it is
      // the one case that is *not* a prefix of anything valid.
      if (src[_pos] == ')') {
        throw const SymbolicException(ExpressionProblem.unbalancedClose);
      }
      throw const SymbolicException(ExpressionProblem.malformed);
    }
    return e;
  }

  SymExpr _parseExpr() {
    var left = _parseTerm();
    while (true) {
      _skipWs();
      final c = _peek();
      if (c != '+' && c != '-') break;
      _pos++;
      _skipWs();
      if (_pos >= src.length) {
        // `2 +` — a valid prefix, so the caller stays quiet.
        throw const SymbolicException(ExpressionProblem.incomplete);
      }
      final right = _parseTerm();
      left = c == '+'
          ? SymAdd([left, right])
          : SymAdd([
              left,
              SymMul([SymNum.fromInt(-1), right])
            ]);
    }
    return left;
  }

  SymExpr _parseTerm() {
    var left = _parseUnary();
    while (true) {
      _skipWs();
      final c = _peek();
      if (c == '*' || c == '/') {
        _pos++;
        _skipWs();
        if (_pos >= src.length) {
          throw const SymbolicException(ExpressionProblem.incomplete);
        }
        final right = _parseUnary();
        left = c == '*'
            ? SymMul([left, right])
            : SymMul([left, SymPow(right, SymNum.fromInt(-1))]);
        continue;
      }
      // Implicit multiplication: `2x`, `2(x+1)`, `x y`, `2 sin(x)`.
      if (_startsFactor(c)) {
        left = SymMul([left, _parseUnary()]);
        continue;
      }
      break;
    }
    return left;
  }

  /// Whether [c] can begin a new factor immediately after one just
  /// ended (which is what makes the juxtaposition implicit-multiply).
  bool _startsFactor(String? c) {
    if (c == null) return false;
    return _isDigit(c) || _isAlpha(c) || c == '(';
  }

  SymExpr _parseUnary() {
    _skipWs();
    final c = _peek();
    if (c == '-') {
      _pos++;
      return SymMul([SymNum.fromInt(-1), _parseUnary()]);
    }
    if (c == '+') {
      _pos++;
      return _parseUnary();
    }
    return _parsePower();
  }

  SymExpr _parsePower() {
    final base = _parsePostfix();
    _skipWs();
    if (_peek() == '^') {
      _pos++;
      _skipWs();
      if (_pos >= src.length) {
        throw const SymbolicException(ExpressionProblem.incomplete);
      }
      // Right-associative, and the exponent may carry a unary minus.
      return SymPow(base, _parseUnary());
    }
    return base;
  }

  SymExpr _parsePostfix() {
    var e = _parsePrimary();
    while (true) {
      _skipWs();
      if (_peek() == '!') {
        _pos++;
        e = SymCall('factorial', [e]);
        continue;
      }
      break;
    }
    return e;
  }

  SymExpr _parsePrimary() {
    _skipWs();
    if (_pos >= src.length) {
      throw const SymbolicException(ExpressionProblem.incomplete);
    }
    final c = src[_pos];

    if (c == '(') {
      _pos++;
      _skipWs();
      if (_pos >= src.length) {
        throw const SymbolicException(ExpressionProblem.incomplete);
      }
      final e = _parseExpr();
      _skipWs();
      if (_pos >= src.length) {
        // `(3+4` — still a valid prefix.
        throw const SymbolicException(ExpressionProblem.incomplete);
      }
      if (src[_pos] != ')') {
        throw const SymbolicException(ExpressionProblem.malformed);
      }
      _pos++;
      return e;
    }

    if (c == ')') {
      throw const SymbolicException(ExpressionProblem.unbalancedClose);
    }

    if (_isDigit(c) || c == '.') return _parseNumber();
    if (_isAlpha(c)) return _parseIdentifier();

    throw const SymbolicException(ExpressionProblem.malformed);
  }

  SymExpr _parseNumber() {
    final start = _pos;
    var sawDot = false;
    while (_pos < src.length) {
      final ch = src[_pos];
      if (_isDigit(ch)) {
        _pos++;
      } else if (ch == '.') {
        // A second dot (`2..3`) is a genuine typo, not a prefix.
        if (sawDot) throw const SymbolicException(ExpressionProblem.malformed);
        sawDot = true;
        _pos++;
      } else {
        break;
      }
    }
    // Scientific notation: `1e3`, `2.5e-4`.
    if (_pos < src.length && (src[_pos] == 'e' || src[_pos] == 'E')) {
      final save = _pos;
      var p = _pos + 1;
      if (p < src.length && (src[p] == '+' || src[p] == '-')) p++;
      if (p < src.length && _isDigit(src[p])) {
        while (p < src.length && _isDigit(src[p])) {
          p++;
        }
        _pos = p;
      } else {
        _pos = save; // bare `e` — it is Euler's constant, not an exponent
      }
    }
    final text = src.substring(start, _pos);
    if (text == '.' || text.isEmpty) {
      // A lone `.` is a prefix of `.5`, so treat it as still-typing.
      throw const SymbolicException(ExpressionProblem.incomplete);
    }
    final r = _rationalFromLiteral(text);
    if (r == null) throw const SymbolicException(ExpressionProblem.malformed);
    return SymNum(r);
  }

  SymExpr _parseIdentifier() {
    final start = _pos;
    while (_pos < src.length && _isWordChar(src[_pos])) {
      _pos++;
    }
    final name = src.substring(start, _pos);
    _skipWs();
    if (_peek() != '(') {
      return SymSym(name);
    }
    // A call. Anything not in the table is a typo worth reporting.
    _pos++; // consume '('
    final args = <SymExpr>[];
    _skipWs();
    if (_pos >= src.length) {
      throw const SymbolicException(ExpressionProblem.incomplete);
    }
    if (_peek() == ')') {
      _pos++;
    } else {
      while (true) {
        args.add(_parseExpr());
        _skipWs();
        if (_pos >= src.length) {
          throw const SymbolicException(ExpressionProblem.incomplete);
        }
        if (_peek() == ',') {
          _pos++;
          _skipWs();
          if (_pos >= src.length) {
            throw const SymbolicException(ExpressionProblem.incomplete);
          }
          continue;
        }
        if (_peek() == ')') {
          _pos++;
          break;
        }
        throw const SymbolicException(ExpressionProblem.malformed);
      }
    }
    final arities = kKnownFunctions[name];
    if (arities == null) {
      throw SymbolicException(ExpressionProblem.unknownFunction, name: name);
    }
    if (!arities.contains(args.length)) {
      throw SymbolicException(ExpressionProblem.wrongArity, name: name);
    }
    return SymCall(name, args);
  }

  String? _peek() => _pos < src.length ? src[_pos] : null;

  void _skipWs() {
    while (_pos < src.length && (src[_pos] == ' ' || src[_pos] == '\t')) {
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

/// Exact [Rational] for a decimal literal: `1.5` → `3/2`, `1e3` → 1000.
Rational? _rationalFromLiteral(String text) {
  var mantissa = text;
  var exponent = 0;
  final eIdx = text.indexOf(RegExp('[eE]'));
  if (eIdx >= 0) {
    mantissa = text.substring(0, eIdx);
    final exp = int.tryParse(text.substring(eIdx + 1));
    if (exp == null) return null;
    exponent = exp;
  }
  final dot = mantissa.indexOf('.');
  var digits = mantissa;
  if (dot >= 0) {
    exponent -= mantissa.length - dot - 1;
    digits = mantissa.substring(0, dot) + mantissa.substring(dot + 1);
  }
  if (digits.isEmpty) return null;
  final n = BigInt.tryParse(digits);
  if (n == null) return null;
  if (exponent >= 0) {
    return Rational(n * BigInt.from(10).pow(exponent), BigInt.one);
  }
  return Rational(n, BigInt.from(10).pow(-exponent));
}

// ---------------------------------------------------------------------------
// Printer
// ---------------------------------------------------------------------------

/// Render [e] using the app's display convention: `^` for powers,
/// integer coefficients juxtaposed (`2x`), monomials juxtaposed
/// (`x^2y`), ` + ` / ` - ` between terms, and negative powers folded
/// into a `/` so `x^-1` reads as `1/x`.
String renderSymExpr(SymExpr e) {
  if (e is SymNum) return _renderRational(e.value);
  if (e is SymSym) return e.name;
  if (e is SymCall) {
    return '${e.name}(${e.args.map(renderSymExpr).join(', ')})';
  }
  if (e is SymPow) return _renderPow(e);
  if (e is SymMul) return _renderMul(e);
  if (e is SymAdd) return _renderAdd(e);
  return e.toString();
}

String _renderRational(Rational r) =>
    r.isInteger ? '${r.numerator}' : '${r.numerator}/${r.denominator}';

/// Wrap in parentheses when [e] would otherwise bind loosely in the
/// surrounding context.
String _atom(SymExpr e) {
  if (e is SymAdd) return '(${renderSymExpr(e)})';
  if (e is SymNum && (!e.value.isInteger || e.value.sign < 0)) {
    return '(${renderSymExpr(e)})';
  }
  if (e is SymMul) return '(${renderSymExpr(e)})';
  return renderSymExpr(e);
}

String _renderPow(SymPow p) {
  final exp = p.exponent;
  // Negative integer exponent renders as a reciprocal.
  if (exp is SymNum && exp.value.isInteger && exp.value.sign < 0) {
    final positive = SymPow(p.base, SymNum(-exp.value)).simplify();
    return '1/${_atom(positive)}';
  }
  return '${_atom(p.base)}^${_atom(exp)}';
}

/// True when [e] is a factor that reads correctly when juxtaposed
/// directly against its neighbours (`x`, `x^2`) rather than needing an
/// explicit `*` (`sin(x)`, `(x + 1)`).
bool _juxtaposable(SymExpr e) {
  if (e is SymSym) return true;
  if (e is SymPow) {
    return e.base is SymSym &&
        e.exponent is SymNum &&
        (e.exponent as SymNum).value.isInteger;
  }
  return false;
}

/// True when [e] binds tightly enough to sit under a `/` without
/// parentheses of its own — a bare symbol, an integer power of one, or
/// a function call (whose own parens already group it).
bool _tightAtom(SymExpr e) => _juxtaposable(e) || e is SymCall;

/// Render a product of [factors] scaled by the integer [lead].
/// Juxtaposable factors run together (`2xy`); everything else is
/// joined with an explicit `*` (`2x*sin(x)`).
String _renderProduct(List<SymExpr> factors, BigInt lead) {
  final sorted = factors.toList()..sort(_compareForDisplay);
  final mono = StringBuffer();
  final loose = <String>[];
  for (final f in sorted) {
    if (_juxtaposable(f)) {
      mono.write(renderSymExpr(f));
    } else {
      loose.add(_atom(f));
    }
  }
  final chunks = <String>[];
  final hasFactors = mono.isNotEmpty || loose.isNotEmpty;
  if (lead != BigInt.one || !hasFactors) chunks.add('$lead');
  if (mono.isNotEmpty) {
    // An integer coefficient juxtaposes directly onto the monomial.
    if (chunks.isNotEmpty) {
      chunks[0] = '${chunks[0]}$mono';
    } else {
      chunks.add(mono.toString());
    }
  }
  chunks.addAll(loose);
  return chunks.isEmpty ? '1' : chunks.join('*');
}

String _renderMul(SymMul m) {
  // Partition into numerator and denominator so `3 * x^-1` prints as
  // `3/x` rather than `3x^-1`, and so a fractional coefficient puts its
  // denominator where it belongs (`3/2 * x^-1` is `3/(2x)`, not
  // `3/2/x`).
  final numer = <SymExpr>[];
  final denom = <SymExpr>[];
  var coeff = Rational.one;
  for (final f in m.factors) {
    if (f is SymNum) {
      coeff = coeff * f.value;
      continue;
    }
    if (f is SymPow) {
      final e = f.exponent;
      if (e is SymNum && e.value.isInteger && e.value.sign < 0) {
        denom.add(SymPow(f.base, SymNum(-e.value)).simplify());
        continue;
      }
    }
    numer.add(f);
  }

  final sign = coeff.sign < 0 ? '-' : '';
  final magnitude = coeff.abs;
  final numText = _renderProduct(numer, magnitude.numerator);
  final denText = _renderProduct(denom, magnitude.denominator);
  if (denText == '1') return '$sign$numText';

  // Parenthesize the divisor unless it is a single tight atom — `3/2x`
  // would otherwise read as `(3/2)x` instead of `3/(2x)`.
  final needsParens = denom.isNotEmpty &&
      (denom.length > 1 ||
          magnitude.denominator != BigInt.one ||
          !_tightAtom(denom.first));
  return '$sign$numText/${needsParens ? '($denText)' : denText}';
}

String _renderAdd(SymAdd a) {
  final buf = StringBuffer();
  final terms = a.terms.toList()..sort(_compareForDisplay);
  for (final t in terms) {
    final (coeff, rest) = _splitCoefficient(t);
    final negative = coeff.sign < 0;
    final magnitude = negative
        ? (rest == null
            ? SymNum(coeff.abs)
            : SymMul([SymNum(coeff.abs), rest]).simplify())
        : t;
    if (buf.isEmpty) {
      if (negative) buf.write('-');
    } else {
      buf.write(negative ? ' - ' : ' + ');
    }
    buf.write(renderSymExpr(magnitude));
  }
  return buf.toString();
}

// ---------------------------------------------------------------------------
// Public entry points
// ---------------------------------------------------------------------------

/// Pure-Dart symbolic evaluation for expressions the WASM/native
/// bridge can't take — most importantly anything containing a free
/// symbol on the web build.
class SymbolicExpressionEvaluator {
  /// Simplify [expression] and render it, or return null when it can't
  /// be parsed (the caller then falls through to its own error path).
  ///
  /// Correct-or-silent: a parse or arithmetic problem yields null, never
  /// a guessed answer. Use [diagnose] to find out *why* it was null.
  static String? tryEvaluate(String expression) {
    final e = tryParse(expression);
    if (e == null) return null;
    return renderSymExpr(e);
  }

  /// Parse + simplify, returning the canonical tree (null on failure).
  static SymExpr? tryParse(String expression) {
    if (expression.trim().isEmpty) return null;
    try {
      return SymParser(expression).parse().simplify();
    } on SymbolicException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Classify [expression] without evaluating it.
  ///
  /// The Notepad uses this to stay silent while a line is still being
  /// typed ([ExpressionProblem.incomplete]) and to phrase a precise
  /// message for the rest.
  static ExpressionDiagnosis diagnose(String expression) {
    if (expression.trim().isEmpty) {
      return const ExpressionDiagnosis(ExpressionProblem.incomplete);
    }
    // `=` isn't part of the expression grammar, but `y=` is the single
    // most common half-typed line in the notepad — someone naming a
    // value before typing it. Split on a lone `=` and diagnose the
    // sides so an empty right-hand side reads as "still typing"
    // rather than as a parse error.
    final eq = _topLevelAssignment(expression);
    if (eq != null) {
      final (lhs, rhs) = eq;
      if (rhs.trim().isEmpty) {
        return const ExpressionDiagnosis(ExpressionProblem.incomplete);
      }
      final left = diagnose(lhs);
      if (!left.isOk) return left;
      return diagnose(rhs);
    }
    try {
      SymParser(expression).parse().simplify();
      return ExpressionDiagnosis.ok;
    } on SymbolicException catch (e) {
      return ExpressionDiagnosis(e.problem, name: e.name);
    } catch (_) {
      return const ExpressionDiagnosis(ExpressionProblem.malformed);
    }
  }

  /// Split on a single top-level `=`, ignoring the comparison operators
  /// (`==`, `<=`, `>=`, `!=`) that merely contain one. Returns null when
  /// there is no such split.
  static (String, String)? _topLevelAssignment(String s) {
    var depth = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(') depth++;
      if (c == ')') depth--;
      if (c != '=' || depth != 0) continue;
      final prev = i > 0 ? s[i - 1] : '';
      final next = i + 1 < s.length ? s[i + 1] : '';
      if (prev == '=' || prev == '<' || prev == '>' || prev == '!') return null;
      if (next == '=') return null;
      return (s.substring(0, i), s.substring(i + 1));
    }
    return null;
  }

  /// True when [expression] is a valid *prefix* of an expression — the
  /// user is still typing and no error should be shown.
  static bool isIncomplete(String expression) =>
      diagnose(expression).isIncomplete;
}

// ---------------------------------------------------------------------------
// Engine-facing error strings
// ---------------------------------------------------------------------------

/// Raw (unlocalized) `Error: ...` string for a diagnosis, in the same
/// shape the rest of the engine emits. `EngineErrorFormatter` turns
/// these into the user-facing localized text at the UI layer.
///
/// Returns null for [ExpressionProblem.none] and for
/// [ExpressionProblem.incomplete] — an incomplete line is not an error
/// and must never reach the user as one; callers check
/// [ExpressionDiagnosis.isIncomplete] and stay quiet instead.
String? engineErrorForDiagnosis(ExpressionDiagnosis d) {
  switch (d.problem) {
    case ExpressionProblem.none:
    case ExpressionProblem.incomplete:
      return null;
    case ExpressionProblem.unbalancedClose:
      return 'Error: unbalanced parenthesis';
    case ExpressionProblem.unknownFunction:
      return 'Error: unknown function ${d.name}';
    case ExpressionProblem.wrongArity:
      return 'Error: wrong number of arguments for ${d.name}';
    case ExpressionProblem.divisionByZero:
      return 'Error: division by zero';
    case ExpressionProblem.malformed:
      return 'Error: parse failed';
  }
}
