// lib/engine/polynomial_mod.dart
//
// Precision arc Group B — univariate polynomial factorisation over a
// finite field F_p (p prime). Pure Dart, deterministic: square-free
// factorisation (Musser) followed by Berlekamp's algorithm to split
// each square-free part into monic irreducibles. No native bridge.
//
// Completes "polynomial arithmetic over Z, Q, F_p" — factorisation over
// Q is the existing SymEngine `factor`; this adds the modular case used
// by abstract-algebra / coding-theory work. Coefficients are reduced
// from the parsed [Polynomial] (rationals) into F_p; a denominator that
// is a multiple of p makes the reduction impossible and yields null.

import 'polynomial.dart';

/// One monic irreducible factor over F_p with its multiplicity.
/// [factor] is low-degree-first, coefficients in `[0, p)`.
class ModFactor {
  final List<int> factor;
  final int multiplicity;
  const ModFactor(this.factor, this.multiplicity);
}

/// A full factorisation `lead · ∏ factorᵢ^multᵢ` over F_p.
class ModFactorization {
  final int prime;
  final int leadingCoeff;
  final String variable;
  final List<ModFactor> factors;
  const ModFactorization(
      this.prime, this.leadingCoeff, this.variable, this.factors);
}

bool _isPrime(int n) {
  if (n < 2) return false;
  if (n % 2 == 0) return n == 2;
  for (var i = 3; i * i <= n; i += 2) {
    if (n % i == 0) return false;
  }
  return true;
}

/// Factor [f] over F_[prime]. Returns null if [prime] is not prime or a
/// coefficient cannot be reduced mod p (denominator divisible by p).
ModFactorization? factorModP(Polynomial f, int prime) {
  if (!_isPrime(prime)) return null;
  final fp = _Fp(prime);
  final big = BigInt.from(prime);

  final coeffs = <int>[];
  for (final c in f.coeffs) {
    if ((c.denominator % big) == BigInt.zero) return null; // not invertible
    final num = (c.numerator % big).toInt(); // Dart % is non-negative here
    final den = (c.denominator % big).toInt();
    coeffs.add(fp.m(num * fp.inv(den)));
  }
  final poly = fp.trim(coeffs);
  if (poly.isEmpty) return null; // f ≡ 0 mod p
  final lead = poly[poly.length - 1];

  final monic = fp.monic(poly);
  final out = <ModFactor>[];
  for (final part in fp.squareFree(monic)) {
    for (final irr in fp.berlekamp(part.poly)) {
      out.add(ModFactor(irr, part.mult));
    }
  }

  out.sort((a, b) {
    if (a.factor.length != b.factor.length) {
      return a.factor.length - b.factor.length;
    }
    for (var i = 0; i < a.factor.length; i++) {
      if (a.factor[i] != b.factor[i]) return a.factor[i] - b.factor[i];
    }
    return 0;
  });
  return ModFactorization(prime, lead, f.variable, out);
}

/// Render a [ModFactorization] like `2 · (x + 2) · (x + 3)` or
/// `(x + 1)^2 · (x^4 + x^3 + x^2 + x + 1)`.
String formatModFactorization(ModFactorization z) {
  final parts = <String>[];
  for (final mf in z.factors) {
    final body = _fmt(mf.factor, z.variable);
    var piece = (mf.factor.length - 1) >= 1 ? '($body)' : body;
    if (mf.multiplicity > 1) piece = '$piece^${mf.multiplicity}';
    parts.add(piece);
  }
  final product = parts.join(' · ');
  if (z.leadingCoeff != 1) {
    return product.isEmpty
        ? '${z.leadingCoeff}'
        : '${z.leadingCoeff} · $product';
  }
  return product.isEmpty ? '1' : product;
}

String _fmt(List<int> c, String v) {
  if (c.isEmpty) return '0';
  final b = StringBuffer();
  for (var d = c.length - 1; d >= 0; d--) {
    final co = c[d];
    if (co == 0) continue;
    if (b.isNotEmpty) b.write(' + ');
    if (d == 0 || co != 1) b.write('$co');
    if (d >= 1) {
      b.write(v);
      if (d > 1) b.write('^$d');
    }
  }
  return b.isEmpty ? '0' : b.toString();
}

/// Arithmetic of univariate polynomials over F_p, with `p` fixed.
/// Polynomials are `List<int>` low-degree-first, coefficients in
/// `[0, p)`, trimmed of trailing zeros (the zero polynomial is `[]`).
class _Fp {
  final int p;
  _Fp(this.p);

  int m(int x) => ((x % p) + p) % p;

  /// Modular inverse via the extended Euclidean algorithm.
  int inv(int a) {
    a = m(a);
    var t = 0, newT = 1;
    var r = p, newR = a;
    while (newR != 0) {
      final q = r ~/ newR;
      final tmpT = t - q * newT;
      t = newT;
      newT = tmpT;
      final tmpR = r - q * newR;
      r = newR;
      newR = tmpR;
    }
    return m(t); // r == 1 since a is a unit
  }

  List<int> trim(List<int> a) {
    var n = a.length;
    while (n > 0 && a[n - 1] == 0) {
      n--;
    }
    return a.sublist(0, n);
  }

  int deg(List<int> a) => a.length - 1;

  List<int> monic(List<int> a) {
    if (a.isEmpty) return a;
    final lead = a[a.length - 1];
    if (lead == 1) return a;
    final invLead = inv(lead);
    return trim([for (final c in a) m(c * invLead)]);
  }

  List<int> sub(List<int> a, List<int> b) {
    final n = a.length > b.length ? a.length : b.length;
    final out = List<int>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      out[i] = m((i < a.length ? a[i] : 0) - (i < b.length ? b[i] : 0));
    }
    return trim(out);
  }

  List<int> mul(List<int> a, List<int> b) {
    if (a.isEmpty || b.isEmpty) return [];
    final out = List<int>.filled(a.length + b.length - 1, 0);
    for (var i = 0; i < a.length; i++) {
      if (a[i] == 0) continue;
      for (var j = 0; j < b.length; j++) {
        out[i + j] = m(out[i + j] + a[i] * b[j]);
      }
    }
    return trim(out);
  }

  /// Returns `(quotient, remainder)`. [b] must be non-zero.
  ({List<int> q, List<int> r}) divmod(List<int> a, List<int> b) {
    final db = deg(b);
    final invLead = inv(b[db]);
    final r = List<int>.of(a);
    if (deg(a) < db) return (q: <int>[], r: trim(r));
    final q = List<int>.filled(deg(a) - db + 1, 0);
    for (var k = deg(a); k >= db; k--) {
      final coef = r[k];
      if (coef == 0) continue;
      final factor = m(coef * invLead);
      q[k - db] = factor;
      for (var i = 0; i <= db; i++) {
        r[k - db + i] = m(r[k - db + i] - factor * b[i]);
      }
    }
    return (q: trim(q), r: trim(r));
  }

  List<int> gcd(List<int> a, List<int> b) {
    var x = trim(List<int>.of(a));
    var y = trim(List<int>.of(b));
    while (y.isNotEmpty) {
      final rem = divmod(x, y).r;
      x = y;
      y = rem;
    }
    return monic(x);
  }

  List<int> derivative(List<int> a) {
    if (a.length <= 1) return [];
    final out = List<int>.filled(a.length - 1, 0);
    for (var i = 1; i < a.length; i++) {
      out[i - 1] = m(a[i] * i);
    }
    return trim(out);
  }

  /// `base^e mod modulus`, exponent a small non-negative int.
  List<int> powMod(List<int> base, int e, List<int> modulus) {
    var result = <int>[1];
    var b = divmod(base, modulus).r;
    var n = e;
    while (n > 0) {
      if (n & 1 == 1) result = divmod(mul(result, b), modulus).r;
      n >>= 1;
      if (n > 0) b = divmod(mul(b, b), modulus).r;
    }
    return trim(result);
  }

  /// p-th root of a polynomial that is a perfect p-th power: in F_p,
  /// `(Σ bᵢ xⁱ)^p = Σ bᵢ x^{ip}`, so the root reads off the coefficients
  /// at multiples of p.
  List<int> pthRoot(List<int> a) {
    final out = <int>[];
    for (var i = 0; i * p < a.length; i++) {
      out.add(a[i * p]);
    }
    return trim(out);
  }

  /// Square-free factorisation (Musser): monic [f] → list of
  /// `(squarefree monic part, multiplicity)`.
  List<({List<int> poly, int mult})> squareFree(List<int> f) {
    final result = <({List<int> poly, int mult})>[];
    void recur(List<int> g, int scale) {
      final gp = derivative(g);
      if (gp.isEmpty) {
        recur(pthRoot(g), scale * p); // g is a p-th power
        return;
      }
      var c = gcd(g, gp);
      var w = divmod(g, c).q;
      var i = 1;
      while (deg(w) > 0) {
        final y = gcd(w, c);
        final fac = divmod(w, y).q;
        if (deg(fac) > 0) result.add((poly: monic(fac), mult: i * scale));
        w = y;
        c = divmod(c, y).q;
        i++;
      }
      if (deg(c) > 0) recur(pthRoot(c), scale * p);
    }

    recur(f, 1);
    return result;
  }

  /// Berlekamp: split a square-free monic [f] into monic irreducibles.
  List<List<int>> berlekamp(List<int> f) {
    final n = deg(f);
    if (n <= 1) return [f];

    // Rows of the Berlekamp (Petr) matrix: row i = x^(p·i) mod f.
    final xp = powMod([0, 1], p, f);
    final rows = <List<int>>[];
    var cur = <int>[1];
    for (var i = 0; i < n; i++) {
      final row = List<int>.filled(n, 0);
      for (var j = 0; j < cur.length && j < n; j++) {
        row[j] = cur[j];
      }
      rows.add(row);
      cur = divmod(mul(cur, xp), f).r;
    }
    // M = Bᵀ − I; null space gives the Berlekamp subalgebra.
    final mat = List.generate(
        n, (k) => List.generate(n, (j) => m(rows[j][k] - (k == j ? 1 : 0))));
    final basis = _nullSpace(mat, n);
    final r = basis.length;
    if (r <= 1) return [f]; // irreducible

    var factors = [f];
    for (final v in basis) {
      if (factors.length >= r) break;
      final h = trim(List<int>.of(v));
      if (deg(h) <= 0) continue; // the constant basis vector
      final next = <List<int>>[];
      for (final u in factors) {
        next.addAll(_splitWith(u, h));
      }
      factors = next;
    }
    return factors;
  }

  List<List<int>> _splitWith(List<int> u, List<int> h) {
    if (deg(u) <= 1) return [u];
    final out = <List<int>>[];
    for (var c = 0; c < p; c++) {
      final g = gcd(u, sub(h, [c]));
      if (deg(g) >= 1) out.add(monic(g));
    }
    return out.isEmpty ? [u] : out;
  }

  /// Null-space basis of an `n×n` matrix over F_p (RREF).
  List<List<int>> _nullSpace(List<List<int>> a, int n) {
    final mat = [for (final row in a) List<int>.of(row)];
    final pivotRowOf = List<int>.filled(n, -1); // column → pivot row
    var row = 0;
    for (var col = 0; col < n && row < n; col++) {
      var sel = -1;
      for (var i = row; i < n; i++) {
        if (mat[i][col] != 0) {
          sel = i;
          break;
        }
      }
      if (sel == -1) continue;
      final tmp = mat[sel];
      mat[sel] = mat[row];
      mat[row] = tmp;
      final invPivot = inv(mat[row][col]);
      for (var j = 0; j < n; j++) {
        mat[row][j] = m(mat[row][j] * invPivot);
      }
      for (var i = 0; i < n; i++) {
        if (i != row && mat[i][col] != 0) {
          final f = mat[i][col];
          for (var j = 0; j < n; j++) {
            mat[i][j] = m(mat[i][j] - f * mat[row][j]);
          }
        }
      }
      pivotRowOf[col] = row;
      row++;
    }
    final basis = <List<int>>[];
    for (var col = 0; col < n; col++) {
      if (pivotRowOf[col] != -1) continue; // free columns only
      final v = List<int>.filled(n, 0);
      v[col] = 1;
      for (var c2 = 0; c2 < n; c2++) {
        if (pivotRowOf[c2] != -1) v[c2] = m(-mat[pivotRowOf[c2]][col]);
      }
      basis.add(v);
    }
    return basis;
  }
}
