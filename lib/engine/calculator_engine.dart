// lib/engine/calculator_engine.dart
//
// Dart-side facade for the native symbolic-math bridge. The UI calls these
// methods without caring whether the native library is actually loaded —
// when it isn't, every call returns a string starting with "Error" so the
// UI can route it into the history just like any other failure.

import 'package:flutter/foundation.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';

import 'matrix_evaluator.dart';
import 'numeric_fallback.dart';
import 'numerical.dart';
import 'polynomial.dart';
import 'polynomial_mod.dart';
import 'symbolic_web.dart';
import 'unit_expression.dart';

class CalculatorEngine {
  CalculatorEngine() {
    try {
      _bridge = SymbolicMathBridge();
      _nativeAvailable = true;
      _log('SymbolicMathBridge loaded');
    } catch (e) {
      _bridge = null;
      _nativeAvailable = false;
      _log('SymbolicMathBridge unavailable: $e');
    }
  }

  late final SymbolicMathBridge? _bridge;
  bool _nativeAvailable = false;

  bool get isNativeAvailable => _nativeAvailable;

  static void _log(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('ENGINE: $msg');
    }
  }

  String _bridgeCall(String op, String Function(SymbolicMathBridge b) fn) {
    final bridge = _bridge;
    if (!_nativeAvailable || bridge == null) {
      return 'Error: $op requires native library';
    }
    try {
      return fn(bridge);
    } catch (e) {
      _log('$op error: $e');
      // Surface the actual bridge exception. It tends to be a short
      // SymEngine parse/eval message (e.g. "ParseError: Unknown symbol"),
      // which is far more useful for debugging than the old generic
      // "Error: <op> failed".
      final msg = e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      return 'Error: $op failed: $msg';
    }
  }

  String evaluate(String expression) {
    // Matrix expressions can't go through SymEngine's text parser — it
    // doesn't recognize `Matrix([[...]])` literals. Route them through the
    // dedicated matrix FFI bindings first; fall back to the scalar parser
    // when the expression doesn't look matrix-shaped.
    if (_nativeAvailable && expression.contains('Matrix(')) {
      final matrixResult = MatrixEvaluator.tryEvaluate(expression, this);
      if (matrixResult != null) return matrixResult;
    }
    // No native bridge (notably the web build): SymEngine is unavailable,
    // so resolve the *numeric* subset in pure Dart instead of returning
    // "requires native library" for everything. Symbolic input (free
    // variables, matrices, unknown functions) yields null here and falls
    // through to the native-only path below, which surfaces the proper
    // "needs the native app" message.
    if (!_nativeAvailable) {
      final numeric = NumericFallbackEvaluator.tryEvaluate(expression);
      if (numeric != null) return numeric;
    }
    return _bridgeCall('evaluate', (b) => b.evaluate(expression));
  }

  /// Calculator-screen entry point. Tries the inline-unit evaluator on
  /// the raw user input first (so `5 km + 3 m` and `100 km in mph`
  /// work before the implicit-multiplication preprocessor mangles
  /// them), then falls through to the normal preprocessed pipeline.
  /// Returns the rendered result string ready for history.
  String evaluateRaw(String rawExpression, String Function(String) preprocess) {
    final unitResult = UnitExpressionEvaluator.tryEvaluate(rawExpression);
    if (unitResult != null) return unitResult;
    return evaluate(preprocess(rawExpression));
  }

  String evaluateForGraphing(String expression) {
    final bridge = _bridge;
    if (!_nativeAvailable || bridge == null) {
      return 'Error';
    }
    // Bessel functions can't go through SymEngine; intercept a standalone
    // besselj/bessely(n, <number>) here, before the comma→dot
    // normalisation below would mangle the argument comma.
    final bessel = _besselForGraphing(expression);
    if (bessel != null) return bessel;
    try {
      var clean = expression.trim().replaceAll(',', '.').replaceAll(' ', '');
      final result = bridge.evaluate(clean);
      return _extractRealPartForGraphing(result);
    } catch (e) {
      return 'Error';
    }
  }

  String _extractRealPartForGraphing(String complexResult) {
    if (complexResult.isEmpty) return complexResult;

    var result = complexResult.trim();
    result = result.replaceAll(RegExp(r'\s*[+\-]\s*0(\.0*)?\s*\*?\s*I\b'), '');
    result = result.replaceAll(RegExp(r'\s*[+\-]\s*[^+\-]*I[^+\-]*'), '');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (result.isEmpty || RegExp(r'^[\+\-\*\s]*$').hasMatch(result)) {
      final match = RegExp(r'([+\-]?\d*\.?\d+)').firstMatch(complexResult);
      result = match?.group(1) ?? '0';
    }
    return result;
  }

  String solve(String expression, String symbol) {
    final bridge = _bridge;
    if (!_nativeAvailable || bridge == null) {
      // Web / native-less: solve linear & quadratic polynomials in pure
      // Dart so the browser build isn't limited to "requires native
      // library" for the most common cases. Higher-degree / non-
      // polynomial equations return null and fall through.
      final web = SymbolicWeb.solveList(expression, symbol);
      if (web != null) {
        if (web.isEmpty) return '$symbol = (no solutions)';
        if (web.length > 1) return '$symbol = {${web.join(', ')}}';
        return '$symbol = ${web.single}';
      }
      return 'Error: solve requires native library';
    }
    try {
      final result = bridge.solve(expression, symbol);
      if (result.startsWith('Error')) return result;
      if (result.startsWith('[') && result.endsWith(']')) {
        final inner = result.substring(1, result.length - 1);
        if (inner.isEmpty) return '$symbol = (no solutions)';
        if (inner.contains(',')) return '$symbol = {$inner}';
        return '$symbol = $inner';
      }
      return '$symbol = $result';
    } catch (e) {
      _log('solve error: $e');
      return 'Error: solve failed';
    }
  }

  String factor(String expression) =>
      _bridgeCall('factor', (b) => b.factor(expression));

  String expand(String expression) {
    // Web / native-less: expand single-variable polynomials in pure Dart.
    if (!_nativeAvailable) {
      final web = SymbolicWeb.expand(expression);
      if (web != null) return web;
    }
    return _bridgeCall('expand', (b) => b.expand(expression));
  }

  String simplify(String expression) =>
      _bridgeCall('simplify', (b) => b.simplify(expression));

  String differentiate(String expression, String variable) {
    // Web / native-less: differentiate polynomials in pure Dart;
    // transcendental input falls through to the native-only path.
    if (!_nativeAvailable) {
      final web = SymbolicWeb.differentiate(expression, variable);
      if (web != null) return web;
    }
    return _bridgeCall(
      'differentiate',
      (b) => b.differentiate(expression, variable),
    );
  }

  String substitute(String expression, String variable, String value) =>
      _bridgeCall(
        'substitute',
        (b) => b.substitute(expression, variable, value),
      );

  String callUnary(String funcName, String expression) =>
      _bridgeCall(funcName, (b) => b.callUnary(funcName, expression));

  String getPi() => _nativeAvailable && _bridge != null
      ? _bridge!.getPi()
      : '3.141592653589793';
  String getE() => _nativeAvailable && _bridge != null
      ? _bridge!.getE()
      : '2.718281828459045';
  String getEulerGamma() => _nativeAvailable && _bridge != null
      ? _bridge!.getEulerGamma()
      : '0.5772156649015329';

  /// Round 85 (precision arc): π to [decimalDigits] decimal places via
  /// MPFR through SymEngine's `basic_evalf`. Routes through the bridge's
  /// `mpfrHighPrecisionPi`. Returns the standard double-precision π if
  /// the native bridge isn't available — useful for `flutter test`
  /// headless mode on Linux CI where the macOS xcframework doesn't
  /// load. Throws when [decimalDigits] is out of 1..10000.
  String getPiWithPrecision(int decimalDigits) => _precisionConstant('pi',
      decimalDigits, '3.141592653589793', (b, n) => b.mpfrHighPrecisionPi(n));

  /// Round 86: e to [decimalDigits] places. Wraps the bridge's
  /// `mpfrHighPrecisionE` with the same fallback / validation as
  /// [getPiWithPrecision].
  String getEWithPrecision(int decimalDigits) => _precisionConstant('e',
      decimalDigits, '2.718281828459045', (b, n) => b.mpfrHighPrecisionE(n));

  /// Round 86: Euler–Mascheroni γ to [decimalDigits] places.
  String getEulerGammaWithPrecision(int decimalDigits) => _precisionConstant(
      'euler_gamma',
      decimalDigits,
      '0.5772156649015329',
      (b, n) => b.mpfrHighPrecisionEulerGamma(n));

  /// Round 86: √2 to [decimalDigits] places.
  String getSqrt2WithPrecision(int decimalDigits) => _precisionConstant(
      'sqrt2',
      decimalDigits,
      '1.4142135623730951',
      (b, n) => b.mpfrHighPrecisionSqrt2(n));

  /// Validation + dispatch shared by the round-85/86 precision
  /// getters. [fallback] is the standard double-precision value
  /// returned when the bridge isn't loaded (Linux CI headless mode).
  String _precisionConstant(
    String label,
    int decimalDigits,
    String fallback,
    String Function(SymbolicMathBridge, int) call,
  ) {
    if (decimalDigits < 1 || decimalDigits > 10000) {
      throw ArgumentError(
          'decimalDigits must be in 1..10000 (got $decimalDigits)');
    }
    if (!_nativeAvailable || _bridge == null) {
      return fallback;
    }
    return _bridgeCall(
        '${label}_with_precision', (b) => call(b, decimalDigits));
  }

  /// Round 89 (precision arc): primality test via GMP's Miller-Rabin
  /// (25 reps, false-positive probability < 4^-25). Returns `true`
  /// for prime, `false` otherwise. Falls back to a pure-Dart sieve
  /// for n ≤ 2^31 when the bridge isn't loaded.
  bool isprime(String n) {
    if (!_nativeAvailable || _bridge == null) return _fallbackIsprime(n);
    try {
      return _bridge!.ntheoryIsprime(n);
    } catch (e) {
      _log('isprime error: $e');
      return _fallbackIsprime(n);
    }
  }

  /// Round 89: smallest prime > n. Throws or returns error string
  /// when the bridge isn't loaded (the pure-Dart fallback would
  /// overflow on bigints; precision-arc functions live on native).
  String nextprime(String n) =>
      _bridgeCall('nextprime', (b) => b.ntheoryNextprime(n));

  /// Round 89: largest prime < n. Errors when n ≤ 2.
  String prevprime(String n) =>
      _bridgeCall('prevprime', (b) => b.ntheoryPrevprime(n));

  /// Round 90: integer factorization via FLINT's `fmpz_factor`.
  /// Returns a structured list of `(prime, exponent)` pairs sorted
  /// by prime. Throws `StateError` when the native bridge isn't
  /// loaded (the headless CI doesn't get a pure-Dart fallback for
  /// arbitrary-precision factoring). The raw wrapper string format
  /// is `p1^e1*p2^e2*...` with `^1` omitted; this method parses
  /// it into the structured form.
  ///
  /// Special cases: `factorint(0) = []` (empty),
  /// `factorint(1) = []`, `factorint(-1)` errors (no positive prime
  /// factor). Negative composites lose their sign and return the
  /// factors of `|n|` — same convention as SymPy.
  ///
  /// The wrapper rejects inputs over ~90 bits (27 digits) to keep
  /// each call under a second. For larger numbers, raw wrapper
  /// usage via `_bridge!.ntheoryFactorint(...)` still surfaces
  /// the "input too large" error string.
  List<({int prime, int exponent})> factorint(String n) {
    if (!_nativeAvailable || _bridge == null) {
      throw StateError('factorint requires native library');
    }
    final raw = _bridge!.ntheoryFactorint(n);
    // Bridge swallowed an "Error in ..." prefix already — check
    // for "0" / "1" / "-1" trivial cases. The wrapper-side string
    // for negatives prefixes "-1*" but we strip it (factorint is
    // defined on |n| in classroom usage).
    if (raw == '0' || raw == '1' || raw == '-1') return const [];
    final body = raw.startsWith('-1*') ? raw.substring(3) : raw;
    final out = <({int prime, int exponent})>[];
    for (final token in body.split('*')) {
      final caret = token.indexOf('^');
      if (caret < 0) {
        out.add((prime: int.parse(token), exponent: 1));
      } else {
        out.add((
          prime: int.parse(token.substring(0, caret)),
          exponent: int.parse(token.substring(caret + 1)),
        ));
      }
    }
    return out;
  }

  /// Round 4 (precision arc): a^e mod m via GMP's `mpz_powm`. A
  /// negative exponent is honoured when `gcd(a, m) = 1` (the wrapper
  /// inverts the base first). Native-only — bigint modular
  /// exponentiation has no pure-Dart fallback that wouldn't overflow.
  String modpow(String a, String e, String m) =>
      _bridgeCall('modpow', (b) => b.ntheoryModpow(a, e, m));

  /// Round 4: modular inverse `a^-1 mod m` via GMP's `mpz_invert`.
  /// Surfaces the wrapper's "no inverse" error when `gcd(a, m) != 1`.
  String modinv(String a, String m) =>
      _bridgeCall('modinv', (b) => b.ntheoryModinv(a, m));

  /// Round 4: Euler's totient φ(n) via FLINT's `fmpz_euler_phi`.
  /// Capped at ~90 bits wrapper-side (φ needs n's factorization).
  String totient(String n) =>
      _bridgeCall('totient', (b) => b.ntheoryTotient(n));

  /// Round 4: the Jacobi symbol (a/n) as the string `-1` / `0` / `1`.
  /// `n` must be odd and positive (the wrapper errors otherwise).
  String jacobi(String a, String n) =>
      _bridgeCall('jacobi', (b) => b.ntheoryJacobi(a, n));

  /// Round 4: all positive divisors of `n`, sorted ascending. Pure-Dart
  /// derivation from [factorint] — enumerates every product of
  /// `prime^k` for `0 ≤ k ≤ exponent`. Requires the native bridge
  /// (via [factorint]). `divisors(1) = [1]`; negative `n` uses `|n|`;
  /// `divisors(0)` throws (every integer divides 0).
  ///
  /// Bounded by [factorint]'s ~90-bit input cap, but note the
  /// individual divisors are returned as Dart `int`s — for inputs
  /// whose factors exceed 2^63 the underlying [factorint] parse throws
  /// first, so this never silently overflows.
  List<int> divisors(String n) {
    final magnitude = n.startsWith('-') ? n.substring(1) : n;
    if (magnitude == '0') {
      throw StateError('divisors(0) is undefined (every integer divides 0)');
    }
    if (magnitude == '1') return const [1];
    return divisorsFromFactors(factorint(magnitude));
  }

  /// Pure-Dart divisor enumeration from a prime factorization. Returns
  /// the sorted list of every product `∏ pᵢ^kᵢ` with `0 ≤ kᵢ ≤ eᵢ`.
  /// An empty factorization (n = 1) yields `[1]`. Split out from
  /// [divisors] so the enumeration is unit-testable without the native
  /// bridge that [factorint] needs.
  static List<int> divisorsFromFactors(
      List<({int prime, int exponent})> factors) {
    var divs = <int>[1];
    for (final f in factors) {
      final extended = <int>[];
      var power = 1;
      for (var k = 0; k <= f.exponent; k++) {
        for (final d in divs) {
          extended.add(d * power);
        }
        power *= f.prime;
      }
      divs = extended;
    }
    divs.sort();
    return divs;
  }

  // ===== Continued fractions (precision arc, Group B) =====================
  //
  // Pure-Dart, exact BigInt arithmetic. Irrational constants reuse the
  // round-85/86 MPFR precision strings; everything else is an exact
  // rational, so the whole feature runs headlessly (no FFI-runtime
  // dependency beyond the constant getters, which already fall back to
  // double precision when the bridge is absent).

  /// Continued-fraction expansion of [arg]: the first [terms] partial
  /// quotients rendered as `[a₀; a₁, a₂, …]`. [arg] is one of the named
  /// irrational constants (`pi`, `e`, `EulerGamma`, `sqrt(2)`), an
  /// integer, a rational `p/q`, or a decimal literal. For an irrational
  /// constant the expansion comes from a high-precision approximation
  /// (≈ 4·terms + 40 guard digits) so the requested terms are reliable;
  /// an exact rational yields its finite expansion, which may be shorter
  /// than [terms]. Returns an `Error: …` string for an unsupported
  /// argument or an out-of-range count.
  String cfrac(String arg, int terms) {
    if (terms < 1 || terms > 100) {
      return 'Error: cfrac term count must be in 1..100';
    }
    final r = _resolveToRational(arg.trim(), terms * 4 + 40);
    if (r == null) {
      return 'Error: cfrac argument must be pi, e, EulerGamma, sqrt(2), '
          'an integer, a rational p/q, or a decimal';
    }
    return _formatContinuedFraction(
        continuedFractionOfRational(r.numerator, r.denominator, terms));
  }

  /// The k-th convergent (a rational `p/q`) of [arg]'s continued
  /// fraction. `convergent(x, 0)` is `⌊x⌋ / 1`. Argument forms are the
  /// same as [cfrac].
  String convergent(String arg, int k) {
    if (k < 0 || k > 100) {
      return 'Error: convergent index must be in 0..100';
    }
    final r = _resolveToRational(arg.trim(), (k + 1) * 4 + 40);
    if (r == null) {
      return 'Error: convergent argument must be pi, e, EulerGamma, '
          'sqrt(2), an integer, a rational p/q, or a decimal';
    }
    final c = convergentFromTerms(
        continuedFractionOfRational(r.numerator, r.denominator, k + 1));
    return c.denominator == BigInt.one
        ? '${c.numerator}'
        : '${c.numerator}/${c.denominator}';
  }

  /// Resolve a cfrac/convergent argument to an exact rational. For the
  /// irrational constants [guardDigits] sets the MPFR precision of the
  /// decimal approximation that is then read back as a rational. Returns
  /// null for an unrecognised form.
  ({BigInt numerator, BigInt denominator})? _resolveToRational(
      String arg, int guardDigits) {
    if (RegExp(r'^-?\d+$').hasMatch(arg)) {
      return (numerator: BigInt.parse(arg), denominator: BigInt.one);
    }
    final frac = RegExp(r'^(-?\d+)\s*/\s*(-?\d+)$').firstMatch(arg);
    if (frac != null) {
      final q = BigInt.parse(frac.group(2)!);
      if (q == BigInt.zero) return null;
      return (numerator: BigInt.parse(frac.group(1)!), denominator: q);
    }
    if (RegExp(r'^-?\d+\.\d+$').hasMatch(arg)) {
      return _decimalStringToRational(arg);
    }
    String? dec;
    if (arg == 'pi') {
      dec = getPiWithPrecision(guardDigits);
    } else if (arg == 'e') {
      dec = getEWithPrecision(guardDigits);
    } else if (arg == 'EulerGamma') {
      dec = getEulerGammaWithPrecision(guardDigits);
    } else if (RegExp(r'^sqrt\(\s*2\s*\)$').hasMatch(arg)) {
      dec = getSqrt2WithPrecision(guardDigits);
    }
    if (dec == null) return null;
    return _decimalStringToRational(dec);
  }

  static ({BigInt numerator, BigInt denominator})? _decimalStringToRational(
      String s) {
    final neg = s.startsWith('-');
    final body = neg ? s.substring(1) : s;
    final dot = body.indexOf('.');
    if (dot < 0) {
      final v = BigInt.tryParse(body);
      return v == null
          ? null
          : (numerator: neg ? -v : v, denominator: BigInt.one);
    }
    final digits = BigInt.tryParse(body.replaceFirst('.', ''));
    if (digits == null) return null;
    final den = BigInt.from(10).pow(body.length - dot - 1);
    return (numerator: neg ? -digits : digits, denominator: den);
  }

  /// Pure-Dart continued-fraction expansion of `num / den` (den ≠ 0).
  /// Returns up to [maxTerms] partial quotients `[a₀, a₁, …]`; a
  /// terminating rational yields its exact (possibly shorter)
  /// expansion. Uses floor division so every quotient after `a₀` is
  /// positive. Split out for headless unit testing.
  static List<BigInt> continuedFractionOfRational(
      BigInt numerator, BigInt denominator, int maxTerms) {
    if (denominator == BigInt.zero) {
      throw ArgumentError('continued fraction needs a non-zero denominator');
    }
    var a = numerator;
    var b = denominator;
    if (b < BigInt.zero) {
      a = -a;
      b = -b;
    }
    final out = <BigInt>[];
    for (var i = 0; i < maxTerms && b != BigInt.zero; i++) {
      var q = a ~/ b;
      var r = a - q * b;
      if (r < BigInt.zero) {
        q -= BigInt.one;
        r += b;
      }
      out.add(q);
      a = b;
      b = r;
    }
    return out;
  }

  /// Fold continued-fraction partial quotients into their final
  /// convergent `p/q` (already in lowest terms by construction). Empty
  /// input is treated as `0/1`. The denominator is normalised positive.
  static ({BigInt numerator, BigInt denominator}) convergentFromTerms(
      List<BigInt> terms) {
    if (terms.isEmpty) {
      return (numerator: BigInt.zero, denominator: BigInt.one);
    }
    var hPrev = BigInt.one, hPrev2 = BigInt.zero; // numerators p
    var kPrev = BigInt.zero, kPrev2 = BigInt.one; // denominators q
    for (final t in terms) {
      final h = t * hPrev + hPrev2;
      final k = t * kPrev + kPrev2;
      hPrev2 = hPrev;
      hPrev = h;
      kPrev2 = kPrev;
      kPrev = k;
    }
    if (kPrev < BigInt.zero) {
      return (numerator: -hPrev, denominator: -kPrev);
    }
    return (numerator: hPrev, denominator: kPrev);
  }

  static String _formatContinuedFraction(List<BigInt> cf) {
    if (cf.isEmpty) return '[]';
    if (cf.length == 1) return '[${cf.first}]';
    return '[${cf.first}; ${cf.skip(1).join(', ')}]';
  }

  // ===== Polynomial arithmetic (precision arc, Group B) ===================
  //
  // Pure-Dart, exact rational coefficients — see lib/engine/polynomial.dart.
  // Univariate, already-expanded form (no parentheses). Factorisation
  // over Q is the existing `factor`; these add gcd / resultant /
  // discriminant.

  /// Group B: monic GCD of two univariate polynomials over Q.
  String polygcd(String p, String q) {
    final a = Polynomial.tryParse(p);
    final b = Polynomial.tryParse(q);
    if (a == null || b == null) {
      return 'Error: polygcd needs two univariate polynomials';
    }
    if (a.degree >= 1 && b.degree >= 1 && a.variable != b.variable) {
      return 'Error: polygcd arguments use different variables';
    }
    return Polynomial.gcd(a, b).toString();
  }

  /// Group B: the resultant Res(p, q) — zero iff `p` and `q` share a
  /// non-constant common factor.
  String polyresultant(String p, String q) {
    final a = Polynomial.tryParse(p);
    final b = Polynomial.tryParse(q);
    if (a == null || b == null) {
      return 'Error: polyresultant needs two univariate polynomials';
    }
    if (a.degree >= 1 && b.degree >= 1 && a.variable != b.variable) {
      return 'Error: polyresultant arguments use different variables';
    }
    return Polynomial.resultant(a, b).toString();
  }

  /// Group B: the discriminant of a univariate polynomial (degree ≥ 1).
  /// Zero iff `p` has a repeated root.
  String polydiscriminant(String p) {
    final a = Polynomial.tryParse(p);
    if (a == null) {
      return 'Error: polydiscriminant needs a univariate polynomial';
    }
    if (a.degree < 1) {
      return 'Error: polydiscriminant needs degree ≥ 1';
    }
    return Polynomial.discriminant(a).toString();
  }

  /// Group B: factor a univariate polynomial over F_[prime] (prime
  /// modulus) into monic irreducibles. Pure-Dart (square-free
  /// factorisation + Berlekamp). Factorisation over Q is the existing
  /// [factor]; this is the modular case.
  String polyfactor(String poly, int prime) {
    final f = Polynomial.tryParse(poly);
    if (f == null) {
      return 'Error: polyfactor needs a univariate polynomial';
    }
    if (!_isProbablePrimeSmall(prime)) {
      return 'Error: polyfactor modulus must be a prime';
    }
    final z = factorModP(f, prime);
    if (z == null) {
      return 'Error: polyfactor could not reduce the polynomial mod $prime '
          '(a coefficient denominator is divisible by $prime)';
    }
    return formatModFactorization(z);
  }

  static bool _isProbablePrimeSmall(int n) {
    if (n < 2) return false;
    if (n % 2 == 0) return n == 2;
    for (var i = 3; i * i <= n; i += 2) {
      if (n % i == 0) return false;
    }
    return true;
  }

  /// Group B: arbitrary-precision numeric evaluation of any parseable
  /// expression to [decimalDigits] digits via MPFR (real-valued).
  /// `evalf(ln(10), 100)`, `evalf(zeta(2), 50)`, `evalf(sqrt(2)+sqrt(3),
  /// 80)`. Native-only (the generic high-precision path has no pure-Dart
  /// fallback); a non-real result surfaces the wrapper's error.
  String evalfPrecision(String expression, int decimalDigits) {
    if (decimalDigits < 1 || decimalDigits > 10000) {
      return 'Error: precision must be in 1..10000';
    }
    return _bridgeCall('evalf', (b) => b.mpfrEvalf(expression, decimalDigits));
  }

  /// Group B: complex arbitrary-precision numeric evaluation of any
  /// expression to [decimalDigits] digits via MPC (the `basic_evalf`
  /// real=0 path). Returns SymEngine's `a + b*I` string. For complex
  /// values — `cevalf((1+I)^10, 30)`, `cevalf(sqrt(-2), 50)`. Native-only.
  String cevalfPrecision(String expression, int decimalDigits) {
    if (decimalDigits < 1 || decimalDigits > 10000) {
      return 'Error: precision must be in 1..10000';
    }
    return _bridgeCall(
        'cevalf', (b) => b.mpfrCevalf(expression, decimalDigits));
  }

  /// Group B: Bessel function of the first kind Jₙ(x) — integer [order]
  /// `n`, real [x] — via MPFR's `mpfr_jn`. Native-only (SymEngine has no
  /// Bessel functions, so there is no symbolic / fallback path).
  String besselJ(int order, String x) =>
      _bridgeCall('besselj', (b) => b.mpfrBesselJ(order, x));

  /// Group B: Bessel function of the second kind Yₙ(x), via `mpfr_yn`.
  String besselY(int order, String x) =>
      _bridgeCall('bessely', (b) => b.mpfrBesselY(order, x));

  /// Intercept a standalone `besselj(n, <number>)` / `bessely(n, <number>)`
  /// for the graphing path. Bessel cannot go through SymEngine, and
  /// [evaluateForGraphing]'s comma→dot normalisation would mangle the
  /// argument separator — so this runs first, on the raw (already
  /// x-substituted) expression. The numeric argument may be wrapped in
  /// parentheses (the grapher brackets negatives). Returns the value
  /// string, `'Error'` on failure, or null if not a Bessel call.
  String? _besselForGraphing(String expression) {
    final m = RegExp(
            r'^(besselj|bessely)\s*\(\s*(-?\d+)\s*,\s*\(?\s*(-?\d*\.?\d+(?:[eE][+-]?\d+)?)\s*\)?\s*\)$')
        .firstMatch(expression.trim());
    if (m == null) return null;
    final order = int.tryParse(m.group(2)!);
    if (order == null) return null;
    try {
      final v = m.group(1)! == 'besselj'
          ? besselJ(order, m.group(3))
          : besselY(order, m.group(3));
      return v.startsWith('Error') ? 'Error' : v;
    } catch (_) {
      return 'Error';
    }
  }

  /// Round 91 (P6): top-level pre-pass that intercepts precision-arc
  /// calls before SymEngine sees them. Returns the result string when
  /// [input] is a recognized standalone precision-arc call, or null
  /// otherwise — caller falls through to the normal evaluation path.
  ///
  /// Recognized shapes (whitespace-tolerant, case-sensitive):
  ///
  ///   pi(N) / e(N) / EulerGamma(N) → constant to N decimal digits
  ///                                   via the round-85/86 MPFR getters.
  ///   sqrt(2, N)                   → √2 to N digits via round 86.
  ///   isprime(n)                   → 'true' / 'false' via round 89.
  ///   nextprime(n) / prevprime(n)  → next/previous prime (round 89).
  ///   factorint(n)                 → formatted as `p^e · p^e · ...`
  ///                                   with Unicode superscripts
  ///                                   (round 90).
  ///   modpow(a, e, m)              → a^e mod m (round 4).
  ///   modinv(a, m)                 → a^-1 mod m (round 4).
  ///   totient(n)                   → Euler's φ(n) (round 4).
  ///   jacobi(a, n)                 → Jacobi symbol -1/0/1 (round 4).
  ///   divisors(n)                  → comma-separated divisor list
  ///                                   (round 4, pure-Dart from
  ///                                   factorint).
  ///   cfrac(x, n)                  → continued fraction `[a₀; a₁, …]`
  ///                                   (Group B, pure-Dart).
  ///   convergent(x, k)             → k-th rational convergent p/q
  ///                                   (Group B, pure-Dart).
  ///   polygcd(p, q)                → monic GCD of two polynomials
  ///                                   (Group B, pure-Dart).
  ///   polyresultant(p, q)          → resultant Res(p, q) (Group B).
  ///   polydiscriminant(p)          → discriminant of p (Group B).
  ///   polyfactor(p, mod=k)         → factor p over F_k (Group B,
  ///                                   pure-Dart Berlekamp).
  ///   evalf(expr, N)               → expr to N digits via MPFR
  ///                                   (Group B, native).
  ///   cevalf(expr, N)              → complex expr to N digits via MPC
  ///                                   (Group B, native).
  ///   besselj(n, x) / bessely(n, x)→ Bessel J/Y, integer order n,
  ///                                   real x (Group B, MPFR).
  ///
  /// Only matches when the call is the **entire** input (after
  /// trimming whitespace). In-expression calls like `pi(50) + 1` are
  /// deliberately left for the existing `expression_preprocessing_utils`
  /// path; substituting `'true'` or a superscript-formatted string
  /// mid-expression would not make algebraic sense.
  String? tryEvaluatePrecisionCall(String input) {
    final trimmed = input.trim();

    // pi(N) / e(N) / EulerGamma(N).
    var m =
        RegExp(r'^(pi|e|EulerGamma)\s*\(\s*(\d+)\s*\)$').firstMatch(trimmed);
    if (m != null) {
      final n = int.tryParse(m.group(2)!);
      if (n == null || n < 1 || n > 10000) {
        return 'Error: precision must be in 1..10000';
      }
      switch (m.group(1)!) {
        case 'pi':
          return getPiWithPrecision(n);
        case 'e':
          return getEWithPrecision(n);
        case 'EulerGamma':
          return getEulerGammaWithPrecision(n);
      }
    }

    // sqrt(2, N). One-arg `sqrt(x)` falls through to SymEngine.
    m = RegExp(r'^sqrt\s*\(\s*2\s*,\s*(\d+)\s*\)$').firstMatch(trimmed);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n == null || n < 1 || n > 10000) {
        return 'Error: precision must be in 1..10000';
      }
      return getSqrt2WithPrecision(n);
    }

    // isprime / nextprime / prevprime: single arbitrary-precision
    // integer argument (sign allowed, though prevprime errors on
    // small / negative input).
    m = RegExp(r'^(isprime|nextprime|prevprime)\s*\(\s*(-?\d+)\s*\)$')
        .firstMatch(trimmed);
    if (m != null) {
      final name = m.group(1)!;
      final n = m.group(2)!;
      switch (name) {
        case 'isprime':
          return isprime(n) ? 'true' : 'false';
        case 'nextprime':
          return nextprime(n);
        case 'prevprime':
          return prevprime(n);
      }
    }

    // factorint(n) → Unicode-superscript formatted product.
    m = RegExp(r'^factorint\s*\(\s*(-?\d+)\s*\)$').firstMatch(trimmed);
    if (m != null) {
      final n = m.group(1)!;
      try {
        final factors = factorint(n);
        return formatFactorint(factors, originalInput: n);
      } catch (e) {
        return 'Error: factorint failed: $e';
      }
    }

    // Round 4: modpow(a, e, m) — three integer args.
    m = RegExp(r'^modpow\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\)$')
        .firstMatch(trimmed);
    if (m != null) {
      try {
        return modpow(m.group(1)!, m.group(2)!, m.group(3)!);
      } catch (e) {
        return 'Error: modpow failed: $e';
      }
    }

    // Round 4: modinv(a, m) / jacobi(a, n) — two integer args.
    m = RegExp(r'^(modinv|jacobi)\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)$')
        .firstMatch(trimmed);
    if (m != null) {
      final name = m.group(1)!;
      try {
        return name == 'modinv'
            ? modinv(m.group(2)!, m.group(3)!)
            : jacobi(m.group(2)!, m.group(3)!);
      } catch (e) {
        return 'Error: $name failed: $e';
      }
    }

    // Round 4: totient(n) — single integer arg.
    m = RegExp(r'^totient\s*\(\s*(-?\d+)\s*\)$').firstMatch(trimmed);
    if (m != null) {
      try {
        return totient(m.group(1)!);
      } catch (e) {
        return 'Error: totient failed: $e';
      }
    }

    // Round 4: divisors(n) — single integer arg, comma-separated list.
    m = RegExp(r'^divisors\s*\(\s*(-?\d+)\s*\)$').firstMatch(trimmed);
    if (m != null) {
      try {
        return divisors(m.group(1)!).join(', ');
      } catch (e) {
        return 'Error: divisors failed: $e';
      }
    }

    // Group B: cfrac(x, n) — continued-fraction expansion. The first
    // argument is captured loosely (constant name / rational / decimal)
    // and validated inside [cfrac].
    m = RegExp(r'^cfrac\s*\(\s*(.+?)\s*,\s*(\d+)\s*\)$').firstMatch(trimmed);
    if (m != null) {
      final n = int.tryParse(m.group(2)!);
      if (n == null) return 'Error: cfrac term count must be in 1..100';
      return cfrac(m.group(1)!, n);
    }

    // Group B: convergent(x, k) — the k-th rational convergent.
    m = RegExp(r'^convergent\s*\(\s*(.+?)\s*,\s*(\d+)\s*\)$')
        .firstMatch(trimmed);
    if (m != null) {
      final k = int.tryParse(m.group(2)!);
      if (k == null) return 'Error: convergent index must be in 0..100';
      return convergent(m.group(1)!, k);
    }

    // Group B: polygcd(p, q) / polyresultant(p, q) — two polynomials.
    m = RegExp(r'^(polygcd|polyresultant)\s*\(\s*(.+?)\s*,\s*(.+?)\s*\)$')
        .firstMatch(trimmed);
    if (m != null) {
      return m.group(1)! == 'polygcd'
          ? polygcd(m.group(2)!, m.group(3)!)
          : polyresultant(m.group(2)!, m.group(3)!);
    }

    // Group B: polydiscriminant(p) — one polynomial.
    m = RegExp(r'^polydiscriminant\s*\(\s*(.+?)\s*\)$').firstMatch(trimmed);
    if (m != null) {
      return polydiscriminant(m.group(1)!);
    }

    // Group B: evalf(expr, N) — arbitrary-precision numeric evaluation
    // of any expression. The expression (group 1) may itself contain
    // commas (e.g. evalf(beta(2,3), 50)); the trailing `, <digits>)`
    // anchors the precision argument.
    m = RegExp(r'^evalf\s*\(\s*(.+?)\s*,\s*(\d+)\s*\)$').firstMatch(trimmed);
    if (m != null) {
      final n = int.tryParse(m.group(2)!);
      if (n == null || n < 1 || n > 10000) {
        return 'Error: precision must be in 1..10000';
      }
      return evalfPrecision(m.group(1)!, n);
    }

    // Group B: cevalf(expr, N) — complex arbitrary-precision evaluation.
    m = RegExp(r'^cevalf\s*\(\s*(.+?)\s*,\s*(\d+)\s*\)$').firstMatch(trimmed);
    if (m != null) {
      final n = int.tryParse(m.group(2)!);
      if (n == null || n < 1 || n > 10000) {
        return 'Error: precision must be in 1..10000';
      }
      return cevalfPrecision(m.group(1)!, n);
    }

    // Group B: polyfactor(p, mod=k) / polyfactor(p, k) — factor over F_k.
    m = RegExp(r'^polyfactor\s*\(\s*(.+?)\s*,\s*(?:mod\s*=\s*)?(\d+)\s*\)$')
        .firstMatch(trimmed);
    if (m != null) {
      final prime = int.tryParse(m.group(2)!);
      if (prime == null) return 'Error: polyfactor modulus must be an integer';
      return polyfactor(m.group(1)!, prime);
    }

    // Group B: besselj(n, x) / bessely(n, x) — integer order, real arg.
    m = RegExp(
            r'^(besselj|bessely)\s*\(\s*(-?\d+)\s*,\s*(-?\d*\.?\d+(?:[eE][+-]?\d+)?)\s*\)$')
        .firstMatch(trimmed);
    if (m != null) {
      final order = int.tryParse(m.group(2)!);
      if (order == null) return 'Error: bessel order must be an integer';
      return m.group(1)! == 'besselj'
          ? besselJ(order, m.group(3))
          : besselY(order, m.group(3));
    }

    return null;
  }

  /// Format a `factorint` result as a Unicode-superscript product
  /// (`2³ · 3² · 5`). Exponents of 1 are omitted; the middle dot
  /// separates factors. Empty input (0 / ±1) returns `originalInput`
  /// verbatim so the user sees `factorint(0) = 0`, `factorint(1) = 1`.
  String formatFactorint(
    List<({int prime, int exponent})> factors, {
    required String originalInput,
  }) {
    if (factors.isEmpty) return originalInput;
    return factors.map((f) {
      if (f.exponent == 1) return '${f.prime}';
      return '${f.prime}${_superscriptDigits(f.exponent)}';
    }).join(' · ');
  }

  static const Map<String, String> _superscriptMap = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '-': '⁻',
  };

  static String _superscriptDigits(int n) {
    return n.toString().split('').map((d) => _superscriptMap[d] ?? d).join();
  }

  /// Headless-CI fallback for `isprime`. Only correct for inputs
  /// that parse as a regular `int` (≤ 2^31 - 1 on this engine);
  /// large bigints fall back to false, which is wrong but at least
  /// doesn't crash a Linux test runner.
  static bool _fallbackIsprime(String n) {
    final v = int.tryParse(n);
    if (v == null || v < 2) return false;
    if (v < 4) return true;
    if (v % 2 == 0) return false;
    for (var i = 3; i * i <= v; i += 2) {
      if (v % i == 0) return false;
    }
    return true;
  }

  String factorial(int n) {
    if (n < 0) return 'Error: factorial requires non-negative integer';
    return _bridgeCall('factorial', (b) => b.factorial(n));
  }

  String fibonacci(int n) {
    if (n < 0) return 'Error: fibonacci requires non-negative integer';
    return _bridgeCall('fibonacci', (b) => b.fibonacci(n));
  }

  String gcd(String a, String b) => _bridgeCall('gcd', (br) => br.gcd(a, b));

  String lcm(String a, String b) => _bridgeCall('lcm', (br) => br.lcm(a, b));

  /// Numerical limit. SymEngine's C wrapper doesn't expose `limit` directly
  /// yet, so we approximate by evaluating the expression at points
  /// approaching `point` from both sides via the bridge. Returns the
  /// converged value, or a descriptive error if the one-sided limits
  /// disagree. Pass `oo` / `inf` / `\\infty` for +∞; `-oo` / `-inf` for −∞.
  String limit(String expression, String variable, String point) {
    final bridge = _bridge;
    if (!_nativeAvailable || bridge == null) {
      return 'Error: limit requires native library';
    }

    double evalAt(double x) {
      try {
        final substituted =
            bridge.substitute(expression, variable, _formatReal(x));
        final result = bridge.evaluate(substituted);
        return _parseReal(result) ?? double.nan;
      } catch (_) {
        return double.nan;
      }
    }

    final pt = point.trim();
    if (pt == 'oo' || pt == 'inf' || pt == 'infinity' || pt == r'\infty') {
      final v = limitAtInfinity(evalAt);
      return v != null
          ? _formatReal(v)
          : 'Error: limit at infinity does not converge';
    }
    if (pt == '-oo' || pt == '-inf') {
      final v = limitAtInfinity((x) => evalAt(-x));
      return v != null
          ? _formatReal(v)
          : 'Error: limit at -infinity does not converge';
    }

    final pointValue = double.tryParse(pt);
    if (pointValue == null) {
      return 'Error: limit point must be a real number or ±oo';
    }
    final v = oneSidedLimit(evalAt, pointValue);
    if (v == null) {
      final l = evalAt(pointValue - 1e-7);
      final r = evalAt(pointValue + 1e-7);
      if (!l.isFinite || !r.isFinite) {
        return 'Error: limit could not be computed (non-finite near $point)';
      }
      return 'Error: left and right limits differ '
          '(left=${_formatReal(l)}, right=${_formatReal(r)})';
    }
    return _formatReal(v);
  }

  /// Integration. Two paths:
  ///   - Indefinite (`lower == null && upper == null`): asks the native
  ///     bridge for a symbolic antiderivative. Requires the wrapper to
  ///     export `flutter_symengine_integrate`. Falls back to a clear
  ///     "not available" message if it's missing.
  ///   - Definite: tries the fundamental theorem of calculus via the
  ///     symbolic path (antiderivative evaluated at both bounds, returns
  ///     a clean exact result like `1/3` for `∫₀¹ x² dx`). If symbolic
  ///     integration fails or isn't available, falls back to Simpson's
  ///     rule with 200 subintervals.
  String integrate(String expression, String variable,
      [String? lower, String? upper]) {
    final bridge = _bridge;
    if (!_nativeAvailable || bridge == null) {
      return 'Error: integrate requires native library';
    }

    // Indefinite integration: native only.
    if (lower == null || upper == null) {
      if (!bridge.hasIntegrate) {
        return 'Error: indefinite integrate() is not available in this '
            'build of the symbolic_math_bridge';
      }
      try {
        return bridge.integrate(expression, variable);
      } catch (e) {
        return 'Error: $e';
      }
    }

    // Definite integration. Try the exact symbolic route first (FTC).
    if (bridge.hasIntegrate) {
      final exact = _definiteFromAntiderivative(
          bridge, expression, variable, lower, upper);
      if (exact != null) return exact;
    }
    return _definiteNumerical(bridge, expression, variable, lower, upper);
  }

  /// FTC: F(b) - F(a) using the bridge's symbolic integrate + substitute.
  /// Returns null on any failure so the caller can fall back to Simpson.
  String? _definiteFromAntiderivative(SymbolicMathBridge bridge,
      String expression, String variable, String lower, String upper) {
    try {
      final antideriv = bridge.integrate(expression, variable);
      if (antideriv.startsWith('Error')) return null;
      final atUpper = bridge.substitute(antideriv, variable, '($upper)');
      final atLower = bridge.substitute(antideriv, variable, '($lower)');
      // Subtract symbolically; SymEngine will simplify.
      final diff = bridge.evaluate('($atUpper) - ($atLower)');
      if (diff.startsWith('Error')) return null;
      return diff;
    } catch (_) {
      return null;
    }
  }

  String _definiteNumerical(SymbolicMathBridge bridge, String expression,
      String variable, String lower, String upper) {
    double? evalNumeric(String expr) {
      try {
        return _parseReal(bridge.evaluate(expr));
      } catch (_) {
        return null;
      }
    }

    final a = evalNumeric(lower);
    final b = evalNumeric(upper);
    if (a == null || b == null) {
      return 'Error: integration bounds must evaluate to numbers';
    }

    double fAt(double x) {
      try {
        final substituted =
            bridge.substitute(expression, variable, _formatReal(x));
        return _parseReal(bridge.evaluate(substituted)) ?? double.nan;
      } catch (_) {
        return double.nan;
      }
    }

    final result = simpson(fAt, a, b);
    if (result == null) {
      return 'Error: integrand evaluation failed at some sample point';
    }
    return _formatReal(result);
  }

  /// Parses a SymEngine result like `5`, `-2.3`, `5 + 0.0*I` into a double.
  /// Returns null if the value isn't (effectively) real.
  static double? _parseReal(String result) {
    var s = result.trim();
    // Strip trailing zero imaginary parts.
    s = s.replaceAll(RegExp(r'\s*\+\s*-?0(\.0*)?\s*\*?\s*I\b'), '');
    s = s.replaceAll(RegExp(r'\bI\b'), '');
    final d = double.tryParse(s);
    if (d == null) return null;
    if (d.isNaN || d.isInfinite) return null;
    return d;
  }

  static String _formatReal(double v) {
    // Integer if very close to one; otherwise compact decimal.
    if ((v - v.roundToDouble()).abs() < 1e-9 && v.abs() < 1e15) {
      return v.toInt().toString();
    }
    final s = v.toStringAsPrecision(10);
    // Trim trailing zeros after the decimal point.
    return s.contains('.')
        ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
        : s;
  }

  SymEngineMatrix? createMatrix(int rows, int cols) {
    final bridge = _bridge;
    if (!_nativeAvailable || bridge == null) return null;
    try {
      return bridge.createMatrix(rows, cols);
    } catch (e) {
      _log('matrix create error: $e');
      return null;
    }
  }
}
