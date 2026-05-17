// lib/engine/step_engine.dart
//
// Step-by-step differentiation. The motivation: SymEngine answers
// "d/dx[x*sin(x)] = sin(x) + x*cos(x)" but never says *why*. For a
// student that's the most important part. This engine inspects the
// top-level structure of the expression, emits a step describing the
// rule that applies, and recurses on the sub-expressions. The final
// answer still comes from SymEngine (so we don't drift from the
// canonical result); the steps explain the path.
//
// Coverage today: constant, identity, sum/difference, product,
// quotient, power (numeric exponent), chain rule for standard
// functions (sin, cos, tan, asin, acos, atan, sinh, cosh, tanh,
// exp, ln/log, sqrt). Anything else falls through to a generic
// "differentiate" step that just shows SymEngine's result without
// elaboration — still useful, just unaugmented.
//
// Scope is deliberately session-one. Integration and equation
// solving get their own engines (PLAN P5 "Recommended next").

import 'calculator_engine.dart';

/// A single step in a derivation. Each piece is plain text that the
/// renderer wraps in LaTeX as needed.
class DerivativeStep {
  /// Human-readable rule name. e.g. "Product rule".
  final String rule;

  /// Generic LaTeX-ready formula for the rule. e.g. r"(fg)' = f'g + fg'".
  /// Empty for the final-result step.
  final String formula;

  /// The expression at the input of this step, in `d/dvar[expr]` form.
  final String before;

  /// The expression after applying the rule (rule-unfolded, not yet
  /// simplified). For the final step this is SymEngine's simplified
  /// answer.
  final String after;

  /// Optional one-sentence plain-language note. Useful for the
  /// "explanations" P5 follow-up; rendered below the formula when set.
  final String? note;

  const DerivativeStep({
    required this.rule,
    required this.formula,
    required this.before,
    required this.after,
    this.note,
  });
}

class StepEngine {
  /// Produce a step-by-step trace for d/d[variable] of [expression].
  /// The last step always carries SymEngine's simplified answer in its
  /// `after` field.
  static List<DerivativeStep> differentiate(
      String expression, String variable, CalculatorEngine engine) {
    final steps = <DerivativeStep>[];
    _trace(expression, variable, engine, steps);

    // Append a "Result" step with the simplified canonical form from
    // SymEngine. That's what the user actually wants to copy, even if
    // they enjoy the path.
    final simplified = engine.differentiate(expression, variable);
    steps.add(DerivativeStep(
      rule: 'Result',
      formula: '',
      before: 'd/d$variable[$expression]',
      after: simplified,
    ));

    return steps;
  }

  // === Recursive rule walker ==============================================

  static void _trace(String expr, String variable, CalculatorEngine engine,
      List<DerivativeStep> steps) {
    final s = _stripOuterParens(expr.trim());

    // Constant rule
    if (!_containsVar(s, variable)) {
      steps.add(DerivativeStep(
        rule: 'Constant rule',
        formula: r"\frac{d}{dx}[c] = 0",
        before: 'd/d$variable[$s]',
        after: '0',
        note: '$s does not depend on $variable.',
      ));
      return;
    }

    // Identity: d/dx[x] = 1
    if (s == variable) {
      steps.add(DerivativeStep(
        rule: 'Identity',
        formula: r"\frac{d}{dx}[x] = 1",
        before: 'd/d$variable[$s]',
        after: '1',
      ));
      return;
    }

    // Sum / difference rule — top-level + or -
    final sumTerms = _splitTopLevelSum(s);
    if (sumTerms != null && sumTerms.length >= 2) {
      final derivedTerms = <String>[];
      for (final term in sumTerms) {
        derivedTerms.add('${term.sign}d/d$variable[${term.body}]');
      }
      steps.add(DerivativeStep(
        rule: 'Sum/difference rule',
        formula: r"\frac{d}{dx}[f \pm g] = f' \pm g'",
        before: 'd/d$variable[$s]',
        after: derivedTerms.join(' '),
      ));
      for (final term in sumTerms) {
        _trace(term.body, variable, engine, steps);
      }
      return;
    }

    // Quotient rule — top-level division at depth 0
    final quotSplit = _splitTopLevelOnce(s, '/');
    if (quotSplit != null) {
      final f = quotSplit.lhs;
      final g = quotSplit.rhs;
      steps.add(DerivativeStep(
        rule: 'Quotient rule',
        formula:
            r"\frac{d}{dx}\left[\frac{f}{g}\right] = \frac{f'g - fg'}{g^2}",
        before: 'd/d$variable[$s]',
        after:
            '(d/d$variable[$f]·$g - $f·d/d$variable[$g]) / ($g)^2',
      ));
      _trace(f, variable, engine, steps);
      _trace(g, variable, engine, steps);
      return;
    }

    // Product rule — top-level multiplication at depth 0
    final prodFactors = _splitTopLevelProduct(s);
    if (prodFactors != null && prodFactors.length >= 2) {
      // Pair up as (first) · (rest) so the rule reads naturally even
      // for 3+ factors. The recursion will fan out further.
      final first = prodFactors.first;
      final rest = prodFactors.skip(1).join('*');
      steps.add(DerivativeStep(
        rule: 'Product rule',
        formula: r"\frac{d}{dx}[fg] = f'g + fg'",
        before: 'd/d$variable[$s]',
        after:
            'd/d$variable[$first]·($rest) + $first·d/d$variable[$rest]',
      ));
      _trace(first, variable, engine, steps);
      _trace(rest, variable, engine, steps);
      return;
    }

    // Power rule — only when the base contains the variable and the
    // exponent doesn't. base^var (exponential) is handled below.
    final powSplit = _splitTopLevelOnce(s, '^');
    if (powSplit != null) {
      final base = powSplit.lhs;
      final exp = powSplit.rhs;
      final baseHasVar = _containsVar(base, variable);
      final expHasVar = _containsVar(exp, variable);
      if (baseHasVar && !expHasVar) {
        steps.add(DerivativeStep(
          rule: 'Power rule',
          formula: r"\frac{d}{dx}[x^n] = n x^{n-1}",
          before: 'd/d$variable[$s]',
          after:
              '$exp·($base)^($exp - 1)·d/d$variable[$base]',
          note: base == variable
              ? null
              : 'Combined with chain rule because the base is not just $variable.',
        ));
        if (base != variable) _trace(base, variable, engine, steps);
        return;
      }
      if (!baseHasVar && expHasVar) {
        steps.add(DerivativeStep(
          rule: 'Exponential rule',
          formula: r"\frac{d}{dx}[a^{u(x)}] = a^{u(x)} \ln(a) \, u'(x)",
          before: 'd/d$variable[$s]',
          after:
              '($base)^($exp)·ln($base)·d/d$variable[$exp]',
        ));
        _trace(exp, variable, engine, steps);
        return;
      }
      // Both contain the variable — fall through to generic step below.
    }

    // Known function calls — emit standard derivative + chain rule.
    final fc = _matchFunctionCall(s);
    if (fc != null && _standardDerivatives.containsKey(fc.name)) {
      final rule = _standardDerivatives[fc.name]!;
      final argIsVar = fc.arg.trim() == variable;
      steps.add(DerivativeStep(
        rule: argIsVar ? rule.simpleRuleName : 'Chain rule (${rule.simpleRuleName})',
        formula: rule.formula,
        before: 'd/d$variable[$s]',
        after: argIsVar
            ? rule.simpleAfter(fc.arg)
            : rule.chainAfter(fc.arg, variable),
        note: argIsVar
            ? null
            : 'The argument depends on $variable, so multiply by its derivative.',
      ));
      if (!argIsVar) _trace(fc.arg, variable, engine, steps);
      return;
    }

    // Fallback — we don't know the structure well enough to elaborate.
    // Emit a single generic step and let SymEngine produce the result.
    steps.add(DerivativeStep(
      rule: 'Differentiate',
      formula: '',
      before: 'd/d$variable[$s]',
      after: engine.differentiate(s, variable),
      note: 'No higher-level rule pattern recognized for this shape.',
    ));
  }

  // === Pattern recognition helpers ========================================

  /// Strip balanced outermost parentheses, e.g. `(x + 1)` → `x + 1`. Only
  /// strips when the outermost pair really wraps the whole expression
  /// (so `(a)+(b)` is left alone).
  static String _stripOuterParens(String s) {
    var t = s.trim();
    while (t.length >= 2 && t.startsWith('(') && t.endsWith(')')) {
      var depth = 0;
      var fullySpans = true;
      for (var i = 0; i < t.length; i++) {
        final c = t[i];
        if (c == '(') depth++;
        if (c == ')') {
          depth--;
          if (depth == 0 && i != t.length - 1) {
            fullySpans = false;
            break;
          }
        }
      }
      if (!fullySpans) break;
      t = t.substring(1, t.length - 1).trim();
    }
    return t;
  }

  /// Whether [s] references [variable] as a standalone identifier (i.e.
  /// not as part of `exp` when looking for `e`, or `xy` when looking
  /// for `x`).
  static bool _containsVar(String s, String variable) {
    // Build a regex with negative lookbehind/lookahead on word chars.
    final escaped = RegExp.escape(variable);
    return RegExp('(?<![a-zA-Z_])$escaped(?![a-zA-Z_0-9])').hasMatch(s);
  }

  /// Split [s] on top-level `+` and `-`, returning a list of (sign, body)
  /// pairs. Returns null if there's no top-level additive split (i.e. the
  /// whole expression is a single term).
  static List<_SignedTerm>? _splitTopLevelSum(String s) {
    final terms = <_SignedTerm>[];
    var depth = 0;
    var start = 0;
    var sign = '+';
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[') depth++;
      if (c == ')' || c == ']') depth--;
      if (depth == 0 && i > 0 && (c == '+' || c == '-')) {
        // Skip if this is an exponent sign (e.g. 1e-5) or a unary minus
        // after another operator.
        final prev = s[i - 1];
        if (prev == '*' || prev == '/' || prev == '^' || prev == '(' ||
            prev == 'e' || prev == 'E') {
          continue;
        }
        final body = s.substring(start, i).trim();
        if (body.isNotEmpty) terms.add(_SignedTerm(sign, body));
        sign = c;
        start = i + 1;
      }
    }
    final body = s.substring(start).trim();
    if (body.isNotEmpty) terms.add(_SignedTerm(sign, body));
    return terms.length >= 2 ? terms : null;
  }

  /// Split [s] once on the first top-level occurrence of [op]. Returns
  /// null if no such occurrence exists.
  static _Binary? _splitTopLevelOnce(String s, String op) {
    var depth = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[') depth++;
      if (c == ')' || c == ']') depth--;
      if (depth == 0 && c == op && i > 0) {
        return _Binary(s.substring(0, i).trim(), s.substring(i + 1).trim());
      }
    }
    return null;
  }

  /// Split [s] on all top-level `*` characters into factor strings.
  /// Returns null when there's only one factor.
  static List<String>? _splitTopLevelProduct(String s) {
    final factors = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[') depth++;
      if (c == ')' || c == ']') depth--;
      if (depth == 0 && c == '*') {
        final piece = s.substring(start, i).trim();
        if (piece.isNotEmpty) factors.add(piece);
        start = i + 1;
      }
    }
    final tail = s.substring(start).trim();
    if (tail.isNotEmpty) factors.add(tail);
    return factors.length >= 2 ? factors : null;
  }

  /// Match `funcname(arg)` where `arg` is paren-balanced. Returns the
  /// function name and the inner arg, else null.
  static _FunctionCall? _matchFunctionCall(String s) {
    final nameMatch = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\(').matchAsPrefix(s);
    if (nameMatch == null) return null;
    final name = nameMatch.group(1)!;
    var depth = 1;
    var i = nameMatch.end;
    final start = i;
    while (i < s.length && depth > 0) {
      final c = s[i];
      if (c == '(') depth++;
      if (c == ')') depth--;
      i++;
    }
    if (depth != 0 || i != s.length) return null;
    return _FunctionCall(name, s.substring(start, i - 1));
  }

  /// Lookup table of known function derivatives. Each entry knows how to
  /// emit both the simple form (d/dx[sin(x)]) and the chain-rule form
  /// (d/dx[sin(u)] = cos(u)·u'(x)).
  static final Map<String, _StdDerivative> _standardDerivatives = {
    'sin': _StdDerivative(
      simpleRuleName: 'Derivative of sin',
      formula: r"\frac{d}{dx}[\sin x] = \cos x",
      simpleAfter: (arg) => 'cos($arg)',
      chainAfter: (arg, v) => 'cos($arg)·d/d$v[$arg]',
    ),
    'cos': _StdDerivative(
      simpleRuleName: 'Derivative of cos',
      formula: r"\frac{d}{dx}[\cos x] = -\sin x",
      simpleAfter: (arg) => '-sin($arg)',
      chainAfter: (arg, v) => '-sin($arg)·d/d$v[$arg]',
    ),
    'tan': _StdDerivative(
      simpleRuleName: 'Derivative of tan',
      formula: r"\frac{d}{dx}[\tan x] = \sec^2 x",
      simpleAfter: (arg) => '(1/cos($arg))^2',
      chainAfter: (arg, v) => '(1/cos($arg))^2·d/d$v[$arg]',
    ),
    'asin': _StdDerivative(
      simpleRuleName: 'Derivative of arcsin',
      formula: r"\frac{d}{dx}[\arcsin x] = \frac{1}{\sqrt{1-x^2}}",
      simpleAfter: (arg) => '1/sqrt(1 - ($arg)^2)',
      chainAfter: (arg, v) => '(1/sqrt(1 - ($arg)^2))·d/d$v[$arg]',
    ),
    'acos': _StdDerivative(
      simpleRuleName: 'Derivative of arccos',
      formula: r"\frac{d}{dx}[\arccos x] = -\frac{1}{\sqrt{1-x^2}}",
      simpleAfter: (arg) => '-1/sqrt(1 - ($arg)^2)',
      chainAfter: (arg, v) => '(-1/sqrt(1 - ($arg)^2))·d/d$v[$arg]',
    ),
    'atan': _StdDerivative(
      simpleRuleName: 'Derivative of arctan',
      formula: r"\frac{d}{dx}[\arctan x] = \frac{1}{1+x^2}",
      simpleAfter: (arg) => '1/(1 + ($arg)^2)',
      chainAfter: (arg, v) => '(1/(1 + ($arg)^2))·d/d$v[$arg]',
    ),
    'sinh': _StdDerivative(
      simpleRuleName: 'Derivative of sinh',
      formula: r"\frac{d}{dx}[\sinh x] = \cosh x",
      simpleAfter: (arg) => 'cosh($arg)',
      chainAfter: (arg, v) => 'cosh($arg)·d/d$v[$arg]',
    ),
    'cosh': _StdDerivative(
      simpleRuleName: 'Derivative of cosh',
      formula: r"\frac{d}{dx}[\cosh x] = \sinh x",
      simpleAfter: (arg) => 'sinh($arg)',
      chainAfter: (arg, v) => 'sinh($arg)·d/d$v[$arg]',
    ),
    'tanh': _StdDerivative(
      simpleRuleName: 'Derivative of tanh',
      formula: r"\frac{d}{dx}[\tanh x] = 1 - \tanh^2 x",
      simpleAfter: (arg) => '1 - tanh($arg)^2',
      chainAfter: (arg, v) => '(1 - tanh($arg)^2)·d/d$v[$arg]',
    ),
    'exp': _StdDerivative(
      simpleRuleName: 'Derivative of exp',
      formula: r"\frac{d}{dx}[e^x] = e^x",
      simpleAfter: (arg) => 'exp($arg)',
      chainAfter: (arg, v) => 'exp($arg)·d/d$v[$arg]',
    ),
    'log': _StdDerivative(
      simpleRuleName: 'Derivative of ln',
      formula: r"\frac{d}{dx}[\ln x] = \frac{1}{x}",
      simpleAfter: (arg) => '1/($arg)',
      chainAfter: (arg, v) => '(1/($arg))·d/d$v[$arg]',
    ),
    'ln': _StdDerivative(
      simpleRuleName: 'Derivative of ln',
      formula: r"\frac{d}{dx}[\ln x] = \frac{1}{x}",
      simpleAfter: (arg) => '1/($arg)',
      chainAfter: (arg, v) => '(1/($arg))·d/d$v[$arg]',
    ),
    'sqrt': _StdDerivative(
      simpleRuleName: 'Derivative of sqrt',
      formula: r"\frac{d}{dx}[\sqrt{x}] = \frac{1}{2\sqrt{x}}",
      simpleAfter: (arg) => '1/(2·sqrt($arg))',
      chainAfter: (arg, v) => '(1/(2·sqrt($arg)))·d/d$v[$arg]',
    ),
  };
}

class _SignedTerm {
  final String sign;
  final String body;
  const _SignedTerm(this.sign, this.body);
}

class _Binary {
  final String lhs;
  final String rhs;
  const _Binary(this.lhs, this.rhs);
}

class _FunctionCall {
  final String name;
  final String arg;
  const _FunctionCall(this.name, this.arg);
}

class _StdDerivative {
  final String simpleRuleName;
  final String formula;
  final String Function(String arg) simpleAfter;
  final String Function(String arg, String variable) chainAfter;
  const _StdDerivative({
    required this.simpleRuleName,
    required this.formula,
    required this.simpleAfter,
    required this.chainAfter,
  });
}
