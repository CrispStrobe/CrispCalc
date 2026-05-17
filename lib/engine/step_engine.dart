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
class MathStep {
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

  const MathStep({
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
  static List<MathStep> differentiate(
      String expression, String variable, CalculatorEngine engine) {
    final steps = <MathStep>[];
    _trace(expression, variable, engine, steps);

    // Append a "Result" step with the simplified canonical form from
    // SymEngine. That's what the user actually wants to copy, even if
    // they enjoy the path.
    final simplified = engine.differentiate(expression, variable);
    steps.add(MathStep(
      rule: 'Result',
      formula: '',
      before: 'd/d$variable[$expression]',
      after: simplified,
    ));

    return steps;
  }

  /// Produce a step-by-step trace for solving [input] for [variable].
  /// [input] may be `lhs = rhs` (we split on top-level `=`) or just a
  /// polynomial expression to set equal to zero. Detects degree via
  /// SymEngine derivatives: linear if d/dvar is a non-zero constant,
  /// quadratic if d²/dvar² is a non-zero constant. Anything else
  /// falls through to a single "Symbolic solve" step carrying
  /// SymEngine's `solve()` result — still useful, just un-elaborated.
  static List<MathStep> solve(
      String input, String variable, CalculatorEngine engine) {
    final steps = <MathStep>[];

    // 1. Normalize to `lhs - rhs = 0`.
    String body;
    final eqSplit = _splitTopLevelOnce(input, '=');
    if (eqSplit != null) {
      steps.add(MathStep(
        rule: 'Original equation',
        formula: '',
        before: input,
        after: '${eqSplit.lhs} = ${eqSplit.rhs}',
      ));
      final combined = '(${eqSplit.lhs}) - (${eqSplit.rhs})';
      body = engine.simplify(combined);
      if (body.startsWith('Error')) body = combined;
      steps.add(MathStep(
        rule: 'Move all terms to one side',
        formula: r"f(x) = g(x) \;\Longleftrightarrow\; f(x) - g(x) = 0",
        before: '${eqSplit.lhs} = ${eqSplit.rhs}',
        after: '$body = 0',
      ));
    } else {
      body = input;
      steps.add(MathStep(
        rule: 'Treat as equation = 0',
        formula: '',
        before: input,
        after: '$body = 0',
        note: 'No `=` in input; treating as $body = 0.',
      ));
    }

    if (!_containsVar(body, variable)) {
      steps.add(MathStep(
        rule: 'No variable present',
        formula: '',
        before: '$body = 0',
        after: body.trim() == '0' ? 'always true' : 'no solution',
        note: 'The equation does not depend on $variable.',
      ));
      return steps;
    }

    // 2. Degree detection via derivatives.
    final firstDeriv = engine.differentiate(body, variable);
    final secondDeriv = engine.differentiate(firstDeriv, variable);
    final firstHasVar = _containsVar(firstDeriv, variable);
    final secondIsZero = _looksLikeZero(secondDeriv);

    if (!firstHasVar && firstDeriv.trim() != '0') {
      // Linear: body = a*x + b
      _linearSteps(body, firstDeriv, variable, engine, steps);
    } else if (secondIsZero == false && !_containsVar(secondDeriv, variable)) {
      // Quadratic: body = a*x^2 + b*x + c
      _quadraticSteps(body, variable, engine, steps);
    } else {
      // Fall through — let SymEngine handle it.
      steps.add(MathStep(
        rule: 'Symbolic solve',
        formula: '',
        before: '$body = 0',
        after: engine.solve(body, variable),
        note: 'Not a standard linear or quadratic form — handing off '
            'to the symbolic solver for the answer.',
      ));
    }
    return steps;
  }

  // === Solve helpers =======================================================

  static void _linearSteps(String body, String coefA, String variable,
      CalculatorEngine engine, List<MathStep> steps) {
    // body = a*x + b, with a = d/dx[body] (constant).
    // b = body | x=0.
    final b = engine.evaluate(_substitute(body, variable, '0'));
    final a = coefA.trim();

    steps.add(MathStep(
      rule: 'Identify coefficients',
      formula: r"a\,$variable + b = 0",
      before: '$body = 0',
      after: 'a = $a,  b = $b',
    ));

    // a*x = -b
    final negB = engine.simplify('-($b)');
    steps.add(MathStep(
      rule: 'Subtract the constant',
      formula: r"a\,$variable = -b",
      before: '$a·$variable + ($b) = 0',
      after: '$a·$variable = $negB',
    ));

    // x = -b/a
    final solution = engine.simplify('-($b)/($a)');
    steps.add(MathStep(
      rule: 'Divide by the coefficient',
      formula: r"$variable = -\dfrac{b}{a}",
      before: '$a·$variable = $negB',
      after: '$variable = $solution',
    ));

    steps.add(MathStep(
      rule: 'Result',
      formula: '',
      before: 'solve($body, $variable)',
      after: '$variable = $solution',
    ));
  }

  static void _quadraticSteps(String body, String variable,
      CalculatorEngine engine, List<MathStep> steps) {
    // body = a*x^2 + b*x + c with
    //   a = (d^2/dvar^2 body) / 2
    //   b = (d/dvar body) | var=0
    //   c = body | var=0
    final d2 =
        engine.differentiate(engine.differentiate(body, variable), variable);
    final d1 = engine.differentiate(body, variable);
    final a = engine.simplify('($d2)/2');
    final b = engine.simplify(_substitute(d1, variable, '0'));
    final c = engine.simplify(_substitute(body, variable, '0'));

    steps.add(MathStep(
      rule: 'Identify coefficients',
      formula: r"a\,x^2 + b\,x + c = 0",
      before: '$body = 0',
      after: 'a = $a,  b = $b,  c = $c',
    ));

    // Discriminant.
    final disc = engine.simplify('($b)^2 - 4·($a)·($c)');
    steps.add(MathStep(
      rule: 'Compute the discriminant',
      formula: r"\Delta = b^2 - 4ac",
      before: 'a = $a,  b = $b,  c = $c',
      after: 'Δ = $disc',
    ));

    // Roots via quadratic formula.
    final rootPlus = engine.simplify('(-($b) + sqrt($disc))/(2·($a))');
    final rootMinus = engine.simplify('(-($b) - sqrt($disc))/(2·($a))');
    steps.add(MathStep(
      rule: 'Apply the quadratic formula',
      formula: r"x = \dfrac{-b \pm \sqrt{\Delta}}{2a}",
      before: 'a = $a,  b = $b,  c = $c,  Δ = $disc',
      after: '$variable = $rootPlus  or  $variable = $rootMinus',
    ));

    // Final canonical result via SymEngine.solve — confirms our answer
    // and presents it in whatever shape SymEngine prefers.
    steps.add(MathStep(
      rule: 'Result',
      formula: '',
      before: 'solve($body, $variable)',
      after: engine.solve(body, variable),
    ));
  }

  /// Inline a substitution like `subst(expr, var, value)` as a raw
  /// expression we can hand to the bridge. We don't have a public
  /// substitute method on CalculatorEngine, so build the SymEngine-style
  /// `subs(...)` form which the parser accepts.
  static String _substitute(String expr, String variable, String value) {
    // Wrap each variable occurrence with the value in parens. Doesn't
    // handle every edge case but covers the polynomial cases this
    // engine generates internally.
    final pattern =
        RegExp('(?<![a-zA-Z_])${RegExp.escape(variable)}(?![a-zA-Z_0-9])');
    return expr.replaceAll(pattern, '($value)');
  }

  static bool _looksLikeZero(String s) {
    final t = s.trim();
    if (t == '0' || t == '0.0' || t == '-0') return true;
    final n = double.tryParse(t);
    return n != null && n == 0.0;
  }

  /// Produce a step-by-step trace for the indefinite integral of [expr]
  /// with respect to [variable]. Mirrors the spirit of SymPy's
  /// `manualintegrate`: a fixed rule list tried in order, each rule
  /// either emits a step and recurses on a simpler sub-integrand or
  /// declines and lets the next rule try. The final step always carries
  /// SymEngine's canonical antiderivative — so even when our rule walker
  /// can't elaborate, the user still gets the right answer.
  ///
  /// V1 covers constant, identity, power (constant exponent ≠ -1),
  /// reciprocal (1/x → ln|x|), sum/difference, constant-multiple, and
  /// standard antiderivatives for sin/cos/exp/sinh/cosh when the
  /// argument is exactly [variable].
  ///
  /// V2 adds: linear u-substitution (∫f(ax+b)dx = F(ax+b)/a) for the
  /// power rule, the logarithm rule, and standard sin/cos/exp/sinh/cosh;
  /// integration by parts for ∫x·f(x)dx with f ∈ {sin, cos, exp, sinh,
  /// cosh}; and the special case ∫ln(x)dx = x·ln(x) − x.
  static List<MathStep> integrate(
      String expr, String variable, CalculatorEngine engine) {
    final steps = <MathStep>[];
    final antideriv = _traceIntegrate(expr, variable, engine, steps);

    // Append the assembled antiderivative as the final Result step.
    // When the rule walker fully elaborated the trace we have an
    // accurate Dart-computed answer; only when nothing matched do we
    // fall back to whatever SymEngine returned in the last step's
    // `after` field (which on a bridge that lacks integrate() will be
    // an error string — but at least the trace itself is honest).
    steps.add(MathStep(
      rule: 'Result',
      formula: '',
      before: '∫ $expr d$variable',
      after: antideriv != null
          ? '$antideriv + C'
          : steps.isNotEmpty
              ? steps.last.after
              : 'Unable to integrate',
    ));

    return steps;
  }

  /// Recursive walker. Returns the assembled antiderivative string
  /// when a rule (possibly with nested rules) handled the input, or
  /// null when the integrator fell through and the final step's
  /// `after` field is the only available answer.
  static String? _traceIntegrate(String expr, String variable,
      CalculatorEngine engine, List<MathStep> steps) {
    final s = _stripOuterParens(expr.trim());

    // Leading minus: ∫(-f) dx = -∫f dx. This is structurally a
    // constant-multiple step but the splitter only sees an explicit `*`,
    // so we handle it inline.
    if (s.startsWith('-') && s.length > 1) {
      final body = s.substring(1).trim();
      steps.add(MathStep(
        rule: 'Constant multiple',
        formula: r"\int -f(x) \, dx = -\int f(x) \, dx",
        before: '∫ $s d$variable',
        after: '-∫ $body d$variable',
      ));
      final inner = _traceIntegrate(body, variable, engine, steps);
      return inner == null ? null : '-($inner)';
    }

    // Constant rule: ∫c d/var = c·var
    if (!_containsVar(s, variable)) {
      final result = '($s)·$variable';
      steps.add(MathStep(
        rule: 'Constant rule',
        formula: r"\int c \, dx = c\,x",
        before: '∫ $s d$variable',
        after: result,
        note: '$s does not depend on $variable.',
      ));
      return result;
    }

    // Identity: ∫x dx = x²/2  (power rule with n = 1)
    if (s == variable) {
      final result = '($variable)^2/2';
      steps.add(MathStep(
        rule: 'Power rule (n=1)',
        formula: r"\int x \, dx = \frac{x^2}{2}",
        before: '∫ $s d$variable',
        after: result,
      ));
      return result;
    }

    // Sum/difference rule: ∫(f ± g) dx = ∫f dx ± ∫g dx
    final sumTerms = _splitTopLevelSum(s);
    if (sumTerms != null && sumTerms.length >= 2) {
      final parts =
          sumTerms.map((t) => '${t.sign}∫ ${t.body} d$variable').join(' ');
      steps.add(MathStep(
        rule: 'Sum/difference rule (linearity)',
        formula: r"\int (f \pm g) \, dx = \int f \, dx \pm \int g \, dx",
        before: '∫ $s d$variable',
        after: parts,
      ));
      final pieces = <String>[];
      var allMatched = true;
      for (final term in sumTerms) {
        final sub = _traceIntegrate(term.body, variable, engine, steps);
        if (sub == null) {
          allMatched = false;
          break;
        }
        pieces.add('${term.sign}($sub)');
      }
      return allMatched ? pieces.join(' ') : null;
    }

    // Constant multiple: ∫c·f(x) dx = c·∫f(x) dx.
    final factors = _splitTopLevelProduct(s);
    if (factors != null) {
      final constFactors = <String>[];
      final varFactors = <String>[];
      for (final f in factors) {
        (_containsVar(f, variable) ? varFactors : constFactors).add(f);
      }
      if (constFactors.isNotEmpty && varFactors.isNotEmpty) {
        final constPart = constFactors.join('·');
        final varPart = varFactors.join('·');
        steps.add(MathStep(
          rule: 'Constant multiple',
          formula: r"\int c\,f(x)\,dx = c \int f(x)\,dx",
          before: '∫ $s d$variable',
          after: '$constPart · ∫ $varPart d$variable',
        ));
        final inner = _traceIntegrate(varPart, variable, engine, steps);
        return inner == null ? null : '($constPart)·($inner)';
      }
    }

    // Power rule: ∫x^n dx = x^(n+1)/(n+1) for constant n ≠ -1, plus
    // the linear-u-sub generalization ∫(a·x+b)^n dx = (a·x+b)^(n+1)/(a·(n+1)).
    final powSplit = _splitTopLevelOnce(s, '^');
    if (powSplit != null) {
      final base = powSplit.lhs;
      final exp = powSplit.rhs;
      if (base == variable && !_containsVar(exp, variable)) {
        if (exp.trim() == '-1' || exp.trim() == '(-1)') {
          final result = 'ln|$variable|';
          steps.add(MathStep(
            rule: 'Logarithm rule',
            formula: r"\int \frac{1}{x} \, dx = \ln|x|",
            before: '∫ $s d$variable',
            after: result,
          ));
          return result;
        }
        final nPlusOne = engine.simplify('($exp) + 1');
        final newExp = nPlusOne.startsWith('Error') ? '$exp + 1' : nPlusOne;
        final result = '($variable)^($newExp)/($newExp)';
        steps.add(MathStep(
          rule: 'Power rule',
          formula: r"\int x^n \, dx = \frac{x^{n+1}}{n+1}",
          before: '∫ $s d$variable',
          after: result,
        ));
        return result;
      }
      // Linear u-substitution on the power rule.
      final slope = _linearSlope(base, variable);
      if (slope != null && !_containsVar(exp, variable)) {
        final baseStripped = _stripOuterParens(base);
        if (exp.trim() == '-1' || exp.trim() == '(-1)') {
          final result = 'ln|$baseStripped|/($slope)';
          steps.add(MathStep(
            rule: 'Linear u-substitution (logarithm rule)',
            formula: r"\int \frac{1}{ax+b} \, dx = \frac{\ln|ax+b|}{a}",
            before: '∫ $s d$variable',
            after: result,
            note: 'Let u = $baseStripped; then du = ($slope)·d$variable.',
          ));
          return result;
        }
        final nPlusOne = engine.simplify('($exp) + 1');
        final newExp = nPlusOne.startsWith('Error') ? '$exp + 1' : nPlusOne;
        final result = '($baseStripped)^($newExp)/(($slope)·($newExp))';
        steps.add(MathStep(
          rule: 'Linear u-substitution (power rule)',
          formula:
              r"\int (ax+b)^n \, dx = \frac{(ax+b)^{n+1}}{a(n+1)}",
          before: '∫ $s d$variable',
          after: result,
          note: 'Let u = $baseStripped; then du = ($slope)·d$variable.',
        ));
        return result;
      }
    }

    // Reciprocal: ∫(1/x) dx = ln|x|, plus ∫1/(linear) dx via linear u-sub.
    final divSplit = _splitTopLevelOnce(s, '/');
    if (divSplit != null) {
      final num = divSplit.lhs.trim();
      final den = divSplit.rhs.trim();
      if (num == '1' && den == variable) {
        final result = 'ln|$variable|';
        steps.add(MathStep(
          rule: 'Logarithm rule',
          formula: r"\int \frac{1}{x} \, dx = \ln|x|",
          before: '∫ $s d$variable',
          after: result,
        ));
        return result;
      }
      if (num == '1') {
        final denStripped = _stripOuterParens(den);
        final slope = _linearSlope(den, variable);
        if (slope != null) {
          final result = 'ln|$denStripped|/($slope)';
          steps.add(MathStep(
            rule: 'Linear u-substitution (logarithm rule)',
            formula: r"\int \frac{1}{ax+b} \, dx = \frac{\ln|ax+b|}{a}",
            before: '∫ $s d$variable',
            after: result,
            note: 'Let u = $denStripped; then du = ($slope)·d$variable.',
          ));
          return result;
        }
      }
    }

    // Standard antiderivatives for f(var).
    final fc = _matchFunctionCall(s);
    if (fc != null &&
        fc.arg.trim() == variable &&
        _standardAntiderivatives.containsKey(fc.name)) {
      final rule = _standardAntiderivatives[fc.name]!;
      final result = rule.after(variable);
      steps.add(MathStep(
        rule: rule.ruleName,
        formula: rule.formula,
        before: '∫ $s d$variable',
        after: result,
      ));
      return result;
    }

    // Linear u-substitution for f(ax+b) where f has a standard
    // antiderivative.
    if (fc != null && _standardAntiderivatives.containsKey(fc.name)) {
      final slope = _linearSlope(fc.arg, variable);
      if (slope != null) {
        final rule = _standardAntiderivatives[fc.name]!;
        // Substitute the linear arg into the standard antiderivative
        // template by reusing `rule.after()` on the arg directly.
        final F = rule.after(fc.arg);
        final result = '($F)/($slope)';
        steps.add(MathStep(
          rule: 'Linear u-substitution (${rule.ruleName.toLowerCase()})',
          formula:
              r"\int f(ax+b) \, dx = \frac{F(ax+b)}{a}",
          before: '∫ $s d$variable',
          after: result,
          note: 'Let u = ${fc.arg}; then du = ($slope)·d$variable. The '
              'antiderivative of ${fc.name} is the standard form, '
              'evaluated at u and divided by the slope.',
        ));
        return result;
      }
    }

    // Integration by parts: ∫ln(x) dx = x·ln(x) − x.
    if (fc != null &&
        (fc.name == 'ln' || fc.name == 'log') &&
        fc.arg.trim() == variable) {
      final result = '$variable·ln($variable) - $variable';
      steps.add(MathStep(
        rule: 'Integration by parts',
        formula: r"\int \ln(x) \, dx = x \ln(x) - x",
        before: '∫ $s d$variable',
        after: result,
        note: 'Let u = ln($variable), dv = d$variable. Then '
            'du = (1/$variable)·d$variable and v = $variable, so '
            '∫u·dv = u·v − ∫v·du = $variable·ln($variable) − ∫1 d$variable.',
      ));
      return result;
    }

    // Integration by parts for x · f(x) where f is standard. Picks
    // u = x (the algebraic factor), dv = f(x)·dx (the standard-antideriv
    // factor) — LIATE places Algebraic before Trig/Exponential.
    final factorsForIbp = _splitTopLevelProduct(s);
    if (factorsForIbp != null && factorsForIbp.length == 2) {
      for (var i = 0; i < 2; i++) {
        final left = _stripOuterParens(factorsForIbp[i].trim());
        final right = _stripOuterParens(factorsForIbp[1 - i].trim());
        if (left != variable) continue;
        final rightFc = _matchFunctionCall(right);
        if (rightFc == null || rightFc.arg.trim() != variable) continue;
        if (!_standardAntiderivatives.containsKey(rightFc.name)) continue;
        final vRule = _standardAntiderivatives[rightFc.name]!;
        final v = vRule.after(variable);
        steps.add(MathStep(
          rule: 'Integration by parts',
          formula: r"\int u \, dv = u v - \int v \, du",
          before: '∫ $s d$variable',
          after: '$variable·($v) - ∫ ($v) d$variable',
          note: 'Let u = $variable (so du = d$variable) and '
              'dv = $right·d$variable, giving v = $v.',
        ));
        final innerResult = _traceIntegrate(v, variable, engine, steps);
        if (innerResult == null) return null;
        return '($variable)·($v) - ($innerResult)';
      }
    }

    // Fall through — emit a "Symbolic integration" step that lets the
    // bridge try. Returns null so the caller knows we couldn't compute
    // an answer Dart-side.
    steps.add(MathStep(
      rule: 'Symbolic integration',
      formula: '',
      before: '∫ $s d$variable',
      after: engine.integrate(s, variable),
      note: 'No standard textbook rule matched this shape — handing off '
          'to the symbolic integrator.',
    ));
    return null;
  }

  /// If [expr] is linear in [variable] with a non-zero slope and is NOT
  /// just `variable` alone (that case is handled by the basic power /
  /// standard-antideriv rules), return the slope as an expression string.
  /// Returns null when the expression is non-linear or constant in
  /// [variable].
  ///
  /// Linearity here means: a top-level sum of signed terms where each
  /// term is either a constant (no [variable]) or a product whose only
  /// [variable]-containing factor is exactly [variable] (so things like
  /// `x^2`, `sin(x)`, or `1/x` disqualify the term).
  static String? _linearSlope(String expr, String variable) {
    final s = _stripOuterParens(expr.trim());
    if (s == variable) return null; // trivial case — handled elsewhere
    if (!_containsVar(s, variable)) return null;

    final terms = _splitTopLevelSum(s) ?? [_SignedTerm('+', s)];
    String? slopeAccum;
    var hasVarTerm = false;

    for (final term in terms) {
      final body = _stripOuterParens(term.body);
      if (!_containsVar(body, variable)) continue; // pure constant term

      // The body must be a product where exactly one factor is `variable`
      // and the rest are variable-free constants.
      final factors = _splitTopLevelProduct(body) ?? [body];
      String? coeff;
      var seenVar = false;
      for (final f in factors) {
        final ft = _stripOuterParens(f);
        if (ft == variable) {
          if (seenVar) return null; // var twice → not linear
          seenVar = true;
        } else if (_containsVar(ft, variable)) {
          return null; // var inside something non-trivial
        } else {
          coeff = coeff == null ? ft : '($coeff)·($ft)';
        }
      }
      if (!seenVar) return null;

      var slope = coeff ?? '1';
      if (term.sign == '-') slope = '-($slope)';
      slopeAccum = slopeAccum == null ? slope : '($slopeAccum) + ($slope)';
      hasVarTerm = true;
    }

    return hasVarTerm ? slopeAccum : null;
  }

  /// Lookup table of antiderivatives for standard 1-arg functions when
  /// the argument is just the integration variable. Argument-is-variable
  /// is enforced by the caller; this only knows about names.
  static final Map<String, _StdAntiderivative> _standardAntiderivatives = {
    'sin': _StdAntiderivative(
      ruleName: 'Antiderivative of sin',
      formula: r"\int \sin x \, dx = -\cos x",
      after: (v) => '-cos($v)',
    ),
    'cos': _StdAntiderivative(
      ruleName: 'Antiderivative of cos',
      formula: r"\int \cos x \, dx = \sin x",
      after: (v) => 'sin($v)',
    ),
    'exp': _StdAntiderivative(
      ruleName: 'Antiderivative of exp',
      formula: r"\int e^x \, dx = e^x",
      after: (v) => 'exp($v)',
    ),
    'sinh': _StdAntiderivative(
      ruleName: 'Antiderivative of sinh',
      formula: r"\int \sinh x \, dx = \cosh x",
      after: (v) => 'cosh($v)',
    ),
    'cosh': _StdAntiderivative(
      ruleName: 'Antiderivative of cosh',
      formula: r"\int \cosh x \, dx = \sinh x",
      after: (v) => 'sinh($v)',
    ),
  };

  // === Recursive rule walker ==============================================

  static void _trace(String expr, String variable, CalculatorEngine engine,
      List<MathStep> steps) {
    final s = _stripOuterParens(expr.trim());

    // Constant rule
    if (!_containsVar(s, variable)) {
      steps.add(MathStep(
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
      steps.add(MathStep(
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
      steps.add(MathStep(
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
      steps.add(MathStep(
        rule: 'Quotient rule',
        formula:
            r"\frac{d}{dx}\left[\frac{f}{g}\right] = \frac{f'g - fg'}{g^2}",
        before: 'd/d$variable[$s]',
        after: '(d/d$variable[$f]·$g - $f·d/d$variable[$g]) / ($g)^2',
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
      steps.add(MathStep(
        rule: 'Product rule',
        formula: r"\frac{d}{dx}[fg] = f'g + fg'",
        before: 'd/d$variable[$s]',
        after: 'd/d$variable[$first]·($rest) + $first·d/d$variable[$rest]',
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
        steps.add(MathStep(
          rule: 'Power rule',
          formula: r"\frac{d}{dx}[x^n] = n x^{n-1}",
          before: 'd/d$variable[$s]',
          after: '$exp·($base)^($exp - 1)·d/d$variable[$base]',
          note: base == variable
              ? null
              : 'Combined with chain rule because the base is not just $variable.',
        ));
        if (base != variable) _trace(base, variable, engine, steps);
        return;
      }
      if (!baseHasVar && expHasVar) {
        steps.add(MathStep(
          rule: 'Exponential rule',
          formula: r"\frac{d}{dx}[a^{u(x)}] = a^{u(x)} \ln(a) \, u'(x)",
          before: 'd/d$variable[$s]',
          after: '($base)^($exp)·ln($base)·d/d$variable[$exp]',
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
      steps.add(MathStep(
        rule: argIsVar
            ? rule.simpleRuleName
            : 'Chain rule (${rule.simpleRuleName})',
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
    steps.add(MathStep(
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
        if (prev == '*' ||
            prev == '/' ||
            prev == '^' ||
            prev == '(' ||
            prev == 'e' ||
            prev == 'E') {
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

class _StdAntiderivative {
  final String ruleName;
  final String formula;
  final String Function(String variable) after;
  const _StdAntiderivative({
    required this.ruleName,
    required this.formula,
    required this.after,
  });
}
