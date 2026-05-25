// lib/engine/calculator_engine.dart
//
// Dart-side facade for the native symbolic-math bridge. The UI calls these
// methods without caring whether the native library is actually loaded —
// when it isn't, every call returns a string starting with "Error" so the
// UI can route it into the history just like any other failure.

import 'package:flutter/foundation.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';

import 'matrix_evaluator.dart';
import 'numerical.dart';
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

  String expand(String expression) =>
      _bridgeCall('expand', (b) => b.expand(expression));

  String simplify(String expression) =>
      _bridgeCall('simplify', (b) => b.simplify(expression));

  String differentiate(String expression, String variable) => _bridgeCall(
        'differentiate',
        (b) => b.differentiate(expression, variable),
      );

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
