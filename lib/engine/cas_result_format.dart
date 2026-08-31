// lib/engine/cas_result_format.dart
//
// One reading order for every symbolic result the app prints.
//
// The CAS surfaces disagreed with each other about how to write the
// same algebra, because each result was whatever its own backend
// happened to emit:
//
//   diff(x^3, x)        ->  3x²                 high-degree-first
//   expand((x+1)^2)     ->  1 + 2x + x²         low-degree-first
//   factor(x^2 - 1)     ->  (1 + x)*(-1 + x)    constant-first factors
//   integrate(x^2, x)   ->  1/3x^3 + C          reads as 1/(3x^3)
//
// The last one is not merely inconsistent — `1/3x^3` is ambiguous
// enough to be read as a reciprocal, which is the wrong expression.
//
// This module re-renders such a result through the canonical printer in
// `symbolic_expr.dart`, so everything the app prints follows the one
// convention already documented there: highest degree first, constants
// last, negative powers folded into a division.
//
// Safety
// ------
// Reformatting a result the user is about to trust is only worth doing
// if it cannot change what the result *says*. Three guards, all of
// which fall back to the original string untouched:
//
//   1. A narrow gate on what is even considered — no equations, sets,
//      matrices, complex numbers, or decimals (see [_isReformattable]).
//      Purely numeric results are left alone entirely: turning `2.5`
//      into `5/2` would be a display regression, not a fix.
//   2. The rewrite has to survive a round trip through the parser.
//   3. The rewrite is checked *numerically* against the original at
//      several sample points, using `NumericFallbackEvaluator` — a
//      parser written independently of this one. If the two strings
//      ever disagree about a value, the rewrite is discarded.
//
// Guard 3 is the one that matters: it catches a misparse of the
// backend's output, which is the only way this could otherwise print
// something untrue.

import 'numeric_fallback.dart';
import 'symbolic_expr.dart';

/// Sample points for the numeric cross-check. Deliberately awkward
/// values — no 0 or 1, nothing that makes a common denominator vanish,
/// and far enough apart that an accidental agreement is unlikely.
const List<double> _samplePoints = [2.7182818, -1.4142136, 3.3166248];

/// Relative tolerance for the cross-check. Loose enough for ordinary
/// floating-point reassociation (summing terms in a different order),
/// tight enough that a genuine algebraic difference cannot slip past.
const double _tolerance = 1e-9;

/// Re-render [raw] in the app's canonical order, or return it unchanged
/// when that can't be done safely.
///
/// [raw] is expected to be backend output *before* display sugar
/// (superscripts, `I` -> `i`) has been applied; `**` is accepted as a
/// synonym for `^`.
String canonicalizeCasResult(String raw) {
  final trimmed = raw.trim();
  if (!_isReformattable(trimmed)) return raw;

  final source = trimmed.replaceAll('**', '^');

  final parsed = SymbolicExpressionEvaluator.tryParse(source);
  if (parsed == null) return raw;

  // Numeric results are none of this module's business: they are
  // already formatted the way the user asked for (decimal places,
  // exact-integer mode), and re-rendering would fight that.
  final symbols = _freeSymbols(source);
  if (symbols.isEmpty) return raw;

  final rendered = renderSymExpr(parsed);
  if (rendered == source) return raw; // nothing to do

  // Guard 2: the rewrite must parse back to the same canonical tree.
  final reparsed = SymbolicExpressionEvaluator.tryParse(rendered);
  if (reparsed == null || reparsed.key != parsed.key) return raw;

  // Guard 3: and must agree numerically with the *original text*.
  if (!_agreesNumerically(source, rendered, symbols)) return raw;

  return rendered;
}

/// Whether [s] is the kind of string this module is willing to touch.
///
/// Everything excluded here is either not a plain expression (solution
/// sets, equations, matrices, intervals) or would be actively made
/// worse by an exact-rational rewrite (decimals).
bool _isReformattable(String s) {
  if (s.isEmpty) return false;
  if (s.startsWith('Error')) return false;
  // Solution sets, equations, matrices, intervals, ranges.
  if (RegExp(r'[{}\[\]=<>;]').hasMatch(s)) return false;
  // Complex results — the imaginary unit isn't in the expression model.
  if (RegExp(r'\bI\b|\bi\b').hasMatch(s)) return false;
  // Infinities and other non-finite markers.
  if (RegExp(r'\b(inf|oo|nan|zoo)\b', caseSensitive: false).hasMatch(s)) {
    return false;
  }
  // Any decimal literal: rewriting `0.5x` as `x/2` changes the
  // presentation the user chose, and float results must pass through
  // the number formatter untouched.
  if (RegExp(r'\d\.\d').hasMatch(s)) return false;
  // Display sugar already applied — this should run before that step.
  if (RegExp(r'[²³⁴⁵]').hasMatch(s)) return false;
  return true;
}

/// Identifiers in [s] that behave as free variables, excluding known
/// function names (which are always followed by `(`).
Set<String> _freeSymbols(String s) {
  final out = <String>{};
  for (final m in RegExp(r'[A-Za-z_][A-Za-z0-9_]*').allMatches(s)) {
    final name = m.group(0)!;
    final after = m.end < s.length ? s.substring(m.end).trimLeft() : '';
    if (after.startsWith('(')) continue; // a call, not a variable
    if (kKnownConstants.contains(name)) continue;
    out.add(name);
  }
  return out;
}

/// Evaluate both strings at several points and require agreement.
///
/// Uses [NumericFallbackEvaluator], whose parser is separate from
/// [SymParser] — so a misreading of the backend's output shows up as a
/// numeric disagreement rather than being confirmed by its own author.
bool _agreesNumerically(String a, String b, Set<String> symbols) {
  var checked = 0;
  for (final seed in _samplePoints) {
    final vars = <String, double>{};
    var k = 0;
    for (final name in symbols) {
      // Spread the symbols apart so `x` and `y` never collide, which
      // would hide a mix-up between them.
      vars[name] = seed + k * 0.7379181;
      k++;
    }
    final va = NumericFallbackEvaluator.evalNumeric(a, vars);
    final vb = NumericFallbackEvaluator.evalNumeric(b, vars);
    // A sample the evaluator can't handle (a pole, an unsupported
    // function) proves nothing either way — skip it.
    if (va == null || vb == null) continue;
    if (!va.isFinite || !vb.isFinite) continue;
    final scale = va.abs() > 1 ? va.abs() : 1.0;
    if ((va - vb).abs() > _tolerance * scale) return false;
    checked++;
  }
  // Never accept a rewrite that was never actually verified.
  return checked > 0;
}
