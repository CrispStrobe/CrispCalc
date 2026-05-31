// lib/engine/polynomial.dart
//
// Precision arc Group B — univariate polynomial arithmetic over Q.
//
// Pure Dart with exact BigInt rational coefficients (no native bridge,
// no FFI-runtime dependency, fully headless-testable). Powers the
// calculator's `polygcd(p, q)`, `polyresultant(p, q)`, and
// `polydiscriminant(p)`. SymEngine's C wrapper exposes none of these
// directly (only integer gcd + basic_solve_poly), and a C polynomial
// parser would be fragile — so the whole feature lives here, mirroring
// the continued-fraction implementation.
//
// Scope: a single variable, integer/rational/decimal coefficients, no
// parentheses (already-expanded form). Factorisation over Q is covered
// by the existing SymEngine `factor`; factorisation over F_p (Berlekamp)
// is a separate future item.

/// An exact rational number, always stored in lowest terms with a
/// positive denominator.
class Rational {
  final BigInt numerator;
  final BigInt denominator;

  const Rational._(this.numerator, this.denominator);

  factory Rational(BigInt n, BigInt d) {
    if (d == BigInt.zero) {
      throw ArgumentError('Rational with zero denominator');
    }
    if (d < BigInt.zero) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d); // BigInt.gcd is non-negative
    if (g > BigInt.one) {
      n = n ~/ g;
      d = d ~/ g;
    }
    return Rational._(n, d);
  }

  factory Rational.fromInt(int v) => Rational._(BigInt.from(v), BigInt.one);

  static final Rational zero = Rational._(BigInt.zero, BigInt.one);
  static final Rational one = Rational._(BigInt.one, BigInt.one);

  bool get isZero => numerator == BigInt.zero;
  bool get isInteger => denominator == BigInt.one;
  Rational get abs => Rational._(numerator.abs(), denominator);
  int get sign => numerator.sign;

  Rational operator +(Rational o) => Rational(
      numerator * o.denominator + o.numerator * denominator,
      denominator * o.denominator);
  Rational operator -(Rational o) => Rational(
      numerator * o.denominator - o.numerator * denominator,
      denominator * o.denominator);
  Rational operator *(Rational o) =>
      Rational(numerator * o.numerator, denominator * o.denominator);
  Rational operator /(Rational o) =>
      Rational(numerator * o.denominator, denominator * o.numerator);
  Rational operator -() => Rational._(-numerator, denominator);

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() =>
      denominator == BigInt.one ? '$numerator' : '$numerator/$denominator';
}

/// A univariate polynomial with rational coefficients. [coeffs] is
/// stored low-degree-first (`coeffs[i]` is the coefficient of `xⁱ`) and
/// trimmed of trailing zeros, so the zero polynomial has an empty list
/// and degree −1.
class Polynomial {
  final List<Rational> coeffs;
  final String variable;

  const Polynomial._(this.coeffs, this.variable);

  factory Polynomial.zero(String variable) => Polynomial._(const [], variable);

  /// A degree-0 polynomial holding the constant [c] (or the zero
  /// polynomial when [c] is zero). [variable] only matters once it is
  /// combined with a non-constant polynomial.
  factory Polynomial.constant(Rational c, [String variable = 'x']) => c.isZero
      ? Polynomial.zero(variable)
      : Polynomial._(List.unmodifiable([c]), variable);

  /// The monomial `name` (i.e. `name^1`).
  factory Polynomial.variable(String name) =>
      Polynomial._(List.unmodifiable([Rational.zero, Rational.one]), name);

  int get degree => coeffs.length - 1;
  bool get isZero => coeffs.isEmpty;
  Rational get leading => coeffs[coeffs.length - 1];

  static Polynomial _trim(List<Rational> list, String variable) {
    var n = list.length;
    while (n > 0 && list[n - 1].isZero) {
      n--;
    }
    return Polynomial._(List.unmodifiable(list.sublist(0, n)), variable);
  }

  /// Parse a polynomial like `x^3 - 2*x + 1`, `2x^2 + 3x - 5`, or
  /// `1/2x - 3`. Accepts `*` and `**`/`^`, implicit multiplication, and
  /// integer / `p/q` / decimal coefficients. Returns null for anything
  /// outside this grammar (parentheses, multiple variables, malformed).
  static Polynomial? tryParse(String input) {
    var s = input.replaceAll(' ', '').replaceAll('**', '^');
    if (s.isEmpty || s.contains('(') || s.contains(')')) return null;
    if (!s.startsWith('+') && !s.startsWith('-')) s = '+$s';

    final termRe = RegExp(r'([+-])([^+-]+)');
    final letterRe = RegExp(r'[a-zA-Z]');
    String? variable;
    final byDegree = <int, Rational>{};
    var pos = 0;

    for (final m in termRe.allMatches(s)) {
      if (m.start != pos) return null; // gap → malformed
      pos = m.end;
      final negative = m.group(1)! == '-';
      final body = m.group(2)!;
      final letters = letterRe.allMatches(body).toList();

      Rational coeff;
      int exp;
      if (letters.isEmpty) {
        final c = _parseRational(body);
        if (c == null) return null;
        coeff = c;
        exp = 0;
      } else {
        if (letters.length != 1) return null; // x*y, x^2*x, etc.
        final v = letters.first.group(0)!;
        if (variable != null && variable != v) return null;
        variable ??= v;
        final idx = letters.first.start;
        var coeffStr = body.substring(0, idx);
        if (coeffStr.endsWith('*')) {
          coeffStr = coeffStr.substring(0, coeffStr.length - 1);
        }
        if (coeffStr.isEmpty) {
          coeff = Rational.one;
        } else {
          final c = _parseRational(coeffStr);
          if (c == null) return null;
          coeff = c;
        }
        final after = body.substring(idx + 1);
        if (after.isEmpty) {
          exp = 1;
        } else {
          if (!after.startsWith('^')) return null;
          final e = int.tryParse(after.substring(1));
          if (e == null || e < 0) return null;
          exp = e;
        }
      }

      final signed = negative ? -coeff : coeff;
      byDegree[exp] = (byDegree[exp] ?? Rational.zero) + signed;
    }
    if (pos != s.length || byDegree.isEmpty) return null;

    variable ??= 'x';
    final maxDeg = byDegree.keys.reduce((a, b) => a > b ? a : b);
    final list = List<Rational>.generate(
        maxDeg + 1, (i) => byDegree[i] ?? Rational.zero);
    return _trim(list, variable);
  }

  static Rational? _parseRational(String s) {
    if (RegExp(r'^\d+$').hasMatch(s)) {
      return Rational(BigInt.parse(s), BigInt.one);
    }
    final frac = RegExp(r'^(\d+)/(\d+)$').firstMatch(s);
    if (frac != null) {
      final d = BigInt.parse(frac.group(2)!);
      if (d == BigInt.zero) return null;
      return Rational(BigInt.parse(frac.group(1)!), d);
    }
    final dec = RegExp(r'^(\d+)\.(\d+)$').firstMatch(s);
    if (dec != null) {
      final digits = BigInt.parse('${dec.group(1)}${dec.group(2)}');
      final den = BigInt.from(10).pow(dec.group(2)!.length);
      return Rational(digits, den);
    }
    return null;
  }

  Polynomial scale(Rational k) {
    if (k.isZero) return Polynomial.zero(variable);
    return Polynomial._(List.unmodifiable(coeffs.map((c) => c * k)), variable);
  }

  Polynomial operator -(Polynomial o) {
    final n = degree > o.degree ? degree : o.degree;
    if (n < 0) return Polynomial.zero(isZero ? o.variable : variable);
    final out = List<Rational>.generate(n + 1, (i) {
      final a = i <= degree ? coeffs[i] : Rational.zero;
      final b = i <= o.degree ? o.coeffs[i] : Rational.zero;
      return a - b;
    });
    return _trim(out, isZero ? o.variable : variable);
  }

  Polynomial operator +(Polynomial o) {
    final n = degree > o.degree ? degree : o.degree;
    if (n < 0) return Polynomial.zero(isZero ? o.variable : variable);
    final out = List<Rational>.generate(n + 1, (i) {
      final a = i <= degree ? coeffs[i] : Rational.zero;
      final b = i <= o.degree ? o.coeffs[i] : Rational.zero;
      return a + b;
    });
    return _trim(out, isZero ? o.variable : variable);
  }

  Polynomial operator *(Polynomial o) {
    if (isZero || o.isZero) {
      return Polynomial.zero(isZero ? o.variable : variable);
    }
    final out = List<Rational>.filled(degree + o.degree + 1, Rational.zero);
    for (var i = 0; i <= degree; i++) {
      for (var j = 0; j <= o.degree; j++) {
        out[i + j] = out[i + j] + coeffs[i] * o.coeffs[j];
      }
    }
    return _trim(out, variable);
  }

  /// `this` raised to a non-negative integer power, by binary
  /// exponentiation. `pow(0)` is the constant `1`.
  Polynomial pow(int n) {
    if (n < 0) throw ArgumentError('negative power');
    var result = Polynomial.constant(Rational.one, variable);
    var base = this;
    var e = n;
    while (e > 0) {
      if (e.isOdd) result = result * base;
      e >>= 1;
      if (e > 0) base = base * base;
    }
    return result;
  }

  /// First derivative.
  Polynomial derivative() {
    if (degree < 1) return Polynomial.zero(variable);
    final out = List<Rational>.generate(
        degree, (i) => coeffs[i + 1] * Rational.fromInt(i + 1));
    return _trim(out, variable);
  }

  /// Make the leading coefficient 1 (the canonical representative over a
  /// field). The zero polynomial is returned unchanged.
  Polynomial monic() {
    if (isZero) return this;
    return scale(Rational.one / leading);
  }

  /// Polynomial long division: returns `(quotient, remainder)` with
  /// `this == quotient * divisor + remainder` and `deg remainder < deg
  /// divisor`.
  ({Polynomial quotient, Polynomial remainder}) divmod(Polynomial divisor) {
    if (divisor.isZero) {
      throw ArgumentError('division by the zero polynomial');
    }
    if (degree < divisor.degree) {
      return (quotient: Polynomial.zero(variable), remainder: this);
    }
    final a = List<Rational>.from(coeffs); // mutable working remainder
    final m = divisor.degree;
    final bLead = divisor.leading;
    final q = List<Rational>.filled(degree - m + 1, Rational.zero);
    for (var k = degree; k >= m; k--) {
      final c = a[k];
      if (c.isZero) continue;
      final factor = c / bLead;
      q[k - m] = factor;
      for (var i = 0; i <= m; i++) {
        a[k - m + i] = a[k - m + i] - factor * divisor.coeffs[i];
      }
    }
    return (
      quotient: _trim(q, variable),
      remainder: _trim(a, variable),
    );
  }

  /// Render high-degree-first, e.g. `x^2 - 3x + 2`. Integer coefficients
  /// juxtapose with the variable (`2x`); a unit coefficient is omitted.
  @override
  String toString() {
    if (isZero) return '0';
    final buf = StringBuffer();
    for (var d = degree; d >= 0; d--) {
      final c = coeffs[d];
      if (c.isZero) continue;
      final mag = c.abs;
      final isFirst = buf.isEmpty;
      if (isFirst) {
        if (c.sign < 0) buf.write('-');
      } else {
        buf.write(c.sign < 0 ? ' - ' : ' + ');
      }
      final showMag = d == 0 || !(mag == Rational.one);
      if (showMag) buf.write(mag.toString());
      if (d >= 1) {
        buf.write(variable);
        if (d > 1) buf.write('^$d');
      }
    }
    return buf.toString();
  }

  /// Monic GCD over Q via the Euclidean algorithm. `gcd(0, 0)` is the
  /// zero polynomial; otherwise the result is monic.
  static Polynomial gcd(Polynomial a, Polynomial b) {
    var x = a;
    var y = b;
    while (!y.isZero) {
      final r = x.divmod(y).remainder;
      x = y;
      y = r;
    }
    return x.monic();
  }

  /// The resultant `Res(a, b)`, computed as the determinant of the
  /// Sylvester matrix. Zero iff `a` and `b` share a non-constant factor.
  static Rational resultant(Polynomial a, Polynomial b) {
    final m = a.degree;
    final n = b.degree;
    if (m < 0 || n < 0) return Rational.zero; // resultant with 0
    final size = m + n;
    if (size == 0) return Rational.one; // two non-zero constants
    // Coefficients high-degree-first.
    final ah = [for (var i = m; i >= 0; i--) a.coeffs[i]];
    final bh = [for (var i = n; i >= 0; i--) b.coeffs[i]];
    final matrix =
        List.generate(size, (_) => List<Rational>.filled(size, Rational.zero));
    for (var r = 0; r < n; r++) {
      for (var i = 0; i <= m; i++) {
        matrix[r][r + i] = ah[i];
      }
    }
    for (var r = 0; r < m; r++) {
      for (var i = 0; i <= n; i++) {
        matrix[n + r][r + i] = bh[i];
      }
    }
    return _determinant(matrix);
  }

  /// The discriminant of `a`:
  /// `(-1)^(n(n-1)/2) · Res(a, a') / aₙ`, for `deg a = n ≥ 1`.
  static Rational discriminant(Polynomial a) {
    final n = a.degree;
    if (n < 1) {
      throw ArgumentError('discriminant needs degree ≥ 1');
    }
    final res = resultant(a, a.derivative());
    final quotient = res / a.leading;
    // (-1)^(n(n-1)/2)
    final negate = ((n * (n - 1)) ~/ 2).isOdd;
    return negate ? -quotient : quotient;
  }

  static Rational _determinant(List<List<Rational>> source) {
    final n = source.length;
    if (n == 0) return Rational.one;
    final a = [for (final row in source) List<Rational>.from(row)];
    var det = Rational.one;
    for (var col = 0; col < n; col++) {
      var pivot = -1;
      for (var r = col; r < n; r++) {
        if (!a[r][col].isZero) {
          pivot = r;
          break;
        }
      }
      if (pivot == -1) return Rational.zero;
      if (pivot != col) {
        final t = a[pivot];
        a[pivot] = a[col];
        a[col] = t;
        det = -det;
      }
      det = det * a[col][col];
      final inv = Rational.one / a[col][col];
      for (var r = col + 1; r < n; r++) {
        if (a[r][col].isZero) continue;
        final factor = a[r][col] * inv;
        for (var c = col; c < n; c++) {
          a[r][c] = a[r][c] - factor * a[col][c];
        }
      }
    }
    return det;
  }
}
