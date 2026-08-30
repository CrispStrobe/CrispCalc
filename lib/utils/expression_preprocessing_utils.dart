// lib/utils/expression_preprocessing_utils.dart
//
// Preprocessing for mathematical expressions before they're handed to
// SymEngine. Pure-Dart string transforms; safe to call without a native
// library. No `print` calls — anything debug-worthy goes via assert/log
// at the call site.

import 'package:flutter/foundation.dart';

import '../engine/app_state.dart';
import '../engine/vector_math.dart';

class ExpressionPreprocessingUtils {
  // Names that look like single-letter variables but are really constants or
  // function names. Compared case-sensitively (SymEngine cares).
  static const Set<String> _reservedTokens = {
    'e',
    'E',
    'pi',
    'Pi',
    'I',
    'oo',
    'sin',
    'cos',
    'tan',
    'csc',
    'sec',
    'cot',
    'asin',
    'acos',
    'atan',
    'sinh',
    'cosh',
    'tanh',
    'asinh',
    'acosh',
    'atanh',
    'ln',
    'log',
    'exp',
    'sqrt',
    'abs',
    'gamma',
    'Gamma',
    'EulerGamma',
    'factorial',
    'fibonacci',
    'deg',
    'rad',
    'mod',
    'Ans',
  };

  static void _log(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('PREPROC: $msg');
    }
  }

  static String preprocessNativeExpression(String expression) {
    var p = expression;

    // Percentage operations — must run before any other rewrite because
    // `%` would otherwise collide with the `mod` → `%` rewrite below.
    p = preprocessPercentage(p);

    // Expand vector calls — `dot([1,2,3], [4,5,6])` → `(1*4 + 2*5 + 3*6)` etc.
    // Done first so subsequent rules see plain arithmetic, not call syntax.
    p = VectorMath.preprocess(p);

    // Custom matrix format "[1,2; 3,4]" -> SymEngine "Matrix([[1, 2],[3, 4]])".
    // Spaces after commas keep the German-comma rule below from rewriting
    // matrix cells like 1,2 into 1.2.
    p = p.replaceAllMapped(RegExp(r'\[([^\]]+)\]'), (match) {
      final content = match.group(1)!;
      if (content.contains(';')) {
        final rows = content.split(';');
        final formattedRows = rows.map((row) {
          final cells = row.split(',').map((c) => c.trim()).join(', ');
          return '[$cells]';
        }).join(',');
        return 'Matrix([$formattedRows])';
      }
      return match.group(0)!;
    });

    // German decimal comma -> period (but only between digits).
    p = p.replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]!}.${m[2]!}');

    // Implicit multiplication.
    p = p.replaceAllMapped(RegExp(r'(\d|\))(\()'), (m) => '${m[1]}*${m[2]}');
    p = p.replaceAllMapped(
        RegExp(r'(\b[a-zA-Z]\b)(\()'), (m) => '${m[1]}*${m[2]}');
    p = p.replaceAllMapped(
        RegExp(r'(\))(\d|\b[a-zA-Z]\b)'), (m) => '${m[1]}*${m[2]}');

    // n! for literal n -> compute the exact BigInt product directly
    // and inline the digit string. SymEngine's `gamma(n+1)` returns
    // a float (scientific notation past ~15 digits), which defeats
    // the exact-integer-mode display, so we extend the BigInt path
    // up to n = 1000 (~2568 digits — completes in milliseconds).
    // Above that the cost gets noticeable and we fall back to gamma.
    p = p.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n >= 0 && n <= 1000) {
        var f = BigInt.one;
        for (var i = 2; i <= n; i++) {
          f *= BigInt.from(i);
        }
        return f.toString();
      }
      return 'gamma(${n + 1})';
    });

    // var! -> gamma(var+1)
    p = p.replaceAllMapped(
      RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*)!'),
      (m) => 'gamma(${m.group(1)} + 1)',
    );

    // a mod b -> (a) % (b)
    p = p.replaceAllMapped(
      RegExp(r'(\S+)\s+mod\s+(\S+)'),
      (m) => '(${m.group(1)}) % (${m.group(2)})',
    );

    return preprocessSpecialFunctions(p);
  }

  /// Notepad V2 — percentage operations.
  ///
  /// Rewrites percentage patterns into arithmetic before the engine
  /// sees them. Order matters: longer patterns first to avoid partial
  /// matches.
  ///
  /// Supported forms:
  ///   - `what % of M is N` / `what percent of M is N` → `(N)/(M)*100`
  ///   - `N% of M`          → `(N)/100*(M)`
  ///   - `M + N%`           → `(M)*(1+(N)/100)` (markup)
  ///   - `M - N%`           → `(M)*(1-(N)/100)` (discount)
  ///   - `M * N%`           → `(M)*(N)/100`
  ///   - bare `N%`          → `(N)/100`
  ///
  /// A number here is any run of digits, optional decimal point, and
  /// optional leading minus — or a parenthesized sub-expression.
  @visibleForTesting
  static String preprocessPercentage(String input) {
    var p = input.trim();

    // ---- "what % of M is N" / "what percent of M is N" ----
    // Must run first — longest pattern.
    final whatPctRe = RegExp(
      r'(?:what|wieviel|quel|qué)\s+(?:%|percent|prozent|pourcent|por\s*ciento)'
      r'\s+(?:of|von|de)\s+(.+?)\s+(?:is|ist|est|es)\s+(.+)',
      caseSensitive: false,
    );
    final whatMatch = whatPctRe.firstMatch(p);
    if (whatMatch != null) {
      final m = whatMatch.group(1)!.trim();
      final n = whatMatch.group(2)!.trim();
      return '($n)/($m)*100';
    }

    // ---- N% of M ----
    final pctOfRe = RegExp(
      r'(\(?[\d.]+\)?)\s*%\s+(?:of|von|de)\s+(.+)',
      caseSensitive: false,
    );
    final pctOfMatch = pctOfRe.firstMatch(p);
    if (pctOfMatch != null) {
      final n = pctOfMatch.group(1)!.trim();
      final m = pctOfMatch.group(2)!.trim();
      return '($n)/100*($m)';
    }

    // ---- M + N% / M - N% / M * N% ----
    // Match the rightmost `<number>%` after a `+`, `-`, or `*`.
    // Use a greedy left operand to capture the full M expression.
    final binPctRe = RegExp(
      r'^(.+?)\s*([+\-*])\s*(\(?[\d.]+\)?)\s*%\s*$',
    );
    final binMatch = binPctRe.firstMatch(p);
    if (binMatch != null) {
      final m = binMatch.group(1)!.trim();
      final op = binMatch.group(2)!;
      final n = binMatch.group(3)!.trim();
      if (op == '*') {
        return '($m)*($n)/100';
      }
      // + or -: markup / discount.
      return '($m)*(1$op($n)/100)';
    }

    // ---- Bare N% (possibly with a leading expression via `=`) ----
    // Match a trailing `<number>%` that isn't followed by anything.
    final barePctRe = RegExp(r'^(.*?)(\(?[\d.]+\)?)\s*%\s*$');
    final bareMatch = barePctRe.firstMatch(p);
    if (bareMatch != null) {
      final prefix = bareMatch.group(1)!.trim();
      final n = bareMatch.group(2)!.trim();
      if (prefix.isEmpty) {
        return '($n)/100';
      }
      // There's something before the N% that isn't caught by the
      // binary patterns above (e.g. "tax = 8.5%"). Leave it as
      // `prefix (N)/100`.
      return '$prefix ($n)/100';
    }

    return p;
  }

  /// Round 110 (P7 kickoff): rewrite a top-level relational operator
  /// (`==`, `!=`, `<`, `<=`, `>`, `>=`) into SymEngine's named-function
  /// form so the expression flows through the generic `evaluate` path
  /// and yields `True` / `False` for constant operands or stays
  /// symbolic for free variables. Scans at paren depth 0; longest
  /// match wins so `<=` is recognized before `<`. `=` alone is left
  /// untouched — that's still assignment / bare-equation territory.
  ///
  /// V1 rewrites the first relational it finds and leaves anything to
  /// the right intact (so `isprime(17) and 17 < 20` survives as-is
  /// until round 111 lands logical-operator rewrites). Run BEFORE the
  /// calculator's assignment regex + `_looksLikeBareEquation` checks
  /// so `x == 1` doesn't get misrouted to the solver.
  static String preprocessRelationalOperators(String expression) {
    if (expression.isEmpty) return expression;
    const ops = <List<String>>[
      ['==', 'Eq'],
      ['!=', 'Ne'],
      ['<=', 'Le'],
      ['>=', 'Ge'],
      ['<', 'Lt'],
      ['>', 'Gt'],
    ];
    var depth = 0;
    for (var i = 0; i < expression.length; i++) {
      final c = expression[i];
      if (c == '(' || c == '[' || c == '{') {
        depth++;
        continue;
      }
      if (c == ')' || c == ']' || c == '}') {
        depth--;
        continue;
      }
      if (depth != 0) continue;
      for (final pair in ops) {
        final op = pair[0];
        if (i + op.length > expression.length) continue;
        if (expression.substring(i, i + op.length) != op) continue;
        final lhs = expression.substring(0, i).trim();
        final rhs = expression.substring(i + op.length).trim();
        if (lhs.isEmpty || rhs.isEmpty) return expression;
        return '${pair[1]}($lhs, $rhs)';
      }
    }
    return expression;
  }

  /// Round 111 (P7): rewrite the word-form logical operators
  /// (`not`, `and`, `or`, `xor`) into SymEngine's named-function form
  /// (`Not(...)`, `And(...)`, `Or(...)`, `Xor(...)`), then finish with
  /// the round-110 relational rewrite at the leaf. Precedence matches
  /// Python: `not` binds tighter than `and` which binds tighter than
  /// `xor` which binds tighter than `or`. Relational operators bind
  /// tighter than `not`, so `not x == 5` reads as `Not(Eq(x, 5))`.
  ///
  /// Recurses into parenthesized subexpressions so nested operators
  /// like `not (x and y)` lower correctly. Word-operators are matched
  /// with word-boundary checks so `random` / `noFold` / etc. aren't
  /// mistaken for one. Each split returns the trimmed non-empty
  /// pieces; chained `a and b and c` becomes a single n-ary
  /// `And(a, b, c)` (SymEngine accepts arbitrary arity).
  ///
  /// `=`, `==`, `<`, etc. fall through to
  /// [preprocessRelationalOperators] at the leaf, so callers should
  /// invoke this instead of the relational rewrite directly.
  static String preprocessLogicalOperators(String expression) {
    if (expression.isEmpty) return expression;
    final descended = _logicalDescendIntoParens(expression);
    return _logicalTopLevel(descended);
  }

  static String _logicalDescendIntoParens(String s) {
    final out = StringBuffer();
    var i = 0;
    while (i < s.length) {
      if (s[i] == '(') {
        var depth = 1;
        var j = i + 1;
        while (j < s.length && depth > 0) {
          if (s[j] == '(') {
            depth++;
          } else if (s[j] == ')') {
            depth--;
          }
          if (depth == 0) break;
          j++;
        }
        if (j >= s.length || depth != 0) {
          // Unbalanced — leave the rest of the string alone and stop
          // descending; SymEngine will surface the syntax error.
          out.write(s.substring(i));
          return out.toString();
        }
        final inner = s.substring(i + 1, j);
        // Round 111b: split the inner content by top-level commas
        // before recursing. A paren-group can be a function-call
        // arg list (`Min(a, b)`, `if(c, t, e)`); without the split
        // a relational at depth 0 of the inner would gobble the
        // commas and produce `Min(Eq(2, 2, x + 1))`. Splitting
        // first means each arg is rewritten independently and
        // rejoined with `, `.
        final args = _splitTopLevelByComma(inner);
        final rewritten = args.map(preprocessLogicalOperators).join(', ');
        out.write('(');
        out.write(rewritten);
        out.write(')');
        i = j + 1;
      } else {
        out.write(s[i]);
        i++;
      }
    }
    return out.toString();
  }

  static String _logicalTopLevel(String s) {
    // Lowest precedence first: `or`. Each successive split is tighter.
    for (final pair in const <List<String>>[
      ['or', 'Or'],
      ['xor', 'Xor'],
      ['and', 'And'],
    ]) {
      final parts = _splitAtTopLevelWord(s, pair[0]);
      if (parts.length > 1) {
        final mapped = parts.map(_logicalTopLevel).join(', ');
        return '${pair[1]}($mapped)';
      }
    }
    // Unary `not` at the start of the expression: wrap the rest.
    final notMatch = RegExp(r'^\s*not\s+').matchAsPrefix(s);
    if (notMatch != null) {
      final rest = s.substring(notMatch.end).trim();
      if (rest.isNotEmpty) {
        return 'Not(${_logicalTopLevel(rest)})';
      }
    }
    return preprocessRelationalOperators(s);
  }

  /// Whole-word, depth-0 split. Empty / trailing-only segments are
  /// dropped so `a and b and` doesn't produce a phantom third
  /// operand. Returns a single-element `[s]` if no split point
  /// fires (caller treats this as "no split").
  static List<String> _splitAtTopLevelWord(String s, String word) {
    final wordChar = RegExp(r'[A-Za-z0-9_]');
    final parts = <String>[];
    var depth = 0;
    var start = 0;
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      if (c == '(' || c == '[' || c == '{') {
        depth++;
        i++;
        continue;
      }
      if (c == ')' || c == ']' || c == '}') {
        depth--;
        i++;
        continue;
      }
      if (depth != 0) {
        i++;
        continue;
      }
      if (i + word.length > s.length) {
        i++;
        continue;
      }
      if (s.substring(i, i + word.length) != word) {
        i++;
        continue;
      }
      final beforeOk = i == 0 || !wordChar.hasMatch(s[i - 1]);
      final afterEnd = i + word.length;
      final afterOk = afterEnd == s.length || !wordChar.hasMatch(s[afterEnd]);
      if (!(beforeOk && afterOk)) {
        i++;
        continue;
      }
      parts.add(s.substring(start, i));
      i += word.length;
      start = i;
    }
    parts.add(s.substring(start));
    final cleaned = parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (cleaned.length <= 1) return [s];
    return cleaned;
  }

  /// Split [s] on every top-level comma (depth 0 with respect to
  /// `(` / `[` / `{`). Each piece is trimmed so the rejoin doesn't
  /// introduce double spaces around the separator. Used by the
  /// paren-descent step to break function-call arg lists into
  /// individual operands and by [tryFoldIfConditional] to extract
  /// the three `if(...)` args.
  static List<String> _splitTopLevelByComma(String s) {
    final parts = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[' || c == '{') {
        depth++;
      } else if (c == ')' || c == ']' || c == '}') {
        depth--;
      } else if (c == ',' && depth == 0) {
        parts.add(s.substring(start, i).trim());
        start = i + 1;
      }
    }
    parts.add(s.substring(start).trim());
    return parts;
  }

  /// Round 111b (P7): Dart-side fold of an `if(cond, then, else)`
  /// conditional. Detects the call at the top of [input], runs the
  /// condition through [evaluator] after standard preprocessing, and
  /// returns the chosen branch (trimmed) when the condition folds
  /// to a constant `true` / `false`. Returns null when [input]
  /// isn't an `if(...)` shape, when arg-count isn't 3, or when the
  /// condition stays symbolic — the caller should leave the
  /// original expression in place and let downstream surface the
  /// error.
  ///
  /// SymEngine's text parser has no `Piecewise` entry, so the
  /// PLAN's original lowering target (`Piecewise((t, cond),
  /// (e, true))`) doesn't work. This Dart-side fold is the
  /// practical replacement.
  static Future<String?> tryFoldIfConditional(
    String input,
    Future<String> Function(String) evaluator,
  ) async {
    final trimmed = input.trim();
    if (!trimmed.startsWith('if(') || !trimmed.endsWith(')')) return null;
    // Walk parens from the opening `(` to be sure the closing `)`
    // really matches it (defends against `if(c, t) + 1` where the
    // outer call doesn't actually span the whole input).
    var depth = 0;
    var matchedEnd = -1;
    for (var i = 2; i < trimmed.length; i++) {
      final c = trimmed[i];
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        depth--;
        if (depth == 0) {
          matchedEnd = i;
          break;
        }
      }
    }
    if (matchedEnd != trimmed.length - 1) return null;
    final args = _splitTopLevelByComma(trimmed.substring(3, matchedEnd));
    if (args.length != 3) return null;
    final pre = preprocessNativeExpression(args[0].trim());
    final raw = await evaluator(pre);
    final normalized = normalizeBooleanResult(raw).trim();
    if (normalized == 'true') return args[1].trim();
    if (normalized == 'false') return args[2].trim();
    return null;
  }

  /// Fold a `piecewise(cond1, val1, cond2, val2, …[, default])` call — the
  /// N-branch generalization of [tryFoldIfConditional], and the mechanism
  /// behind piecewise user-defined functions (roadmap C5.4). After UDF
  /// inlining, `f(-3)` with body `piecewise(x<0, -x, x)` becomes
  /// `(piecewise((-3)<0, -3, -3))`; each condition is evaluated in order
  /// and the first true branch's value is returned. An odd argument count
  /// means the last argument is the `else` value. Returns null when the
  /// input isn't a piecewise call or a condition stays symbolic (so the
  /// caller leaves it in place and downstream surfaces the error).
  static Future<String?> tryFoldPiecewise(
    String input,
    Future<String> Function(String) evaluator,
  ) async {
    var trimmed = input.trim();
    // UDF inlining wraps the body in parens — strip a single matched wrap.
    while (trimmed.startsWith('(') &&
        trimmed.endsWith(')') &&
        _parensWrapWhole(trimmed)) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }
    if (!trimmed.startsWith('piecewise(') || !trimmed.endsWith(')')) {
      return null;
    }
    var depth = 0, matchedEnd = -1;
    const open = 'piecewise(';
    for (var i = open.length - 1; i < trimmed.length; i++) {
      final c = trimmed[i];
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        depth--;
        if (depth == 0) {
          matchedEnd = i;
          break;
        }
      }
    }
    if (matchedEnd != trimmed.length - 1) return null;

    final args =
        _splitTopLevelByComma(trimmed.substring(open.length, matchedEnd));
    if (args.length < 2) return null;
    final hasElse = args.length.isOdd;
    final pairCount = hasElse ? (args.length - 1) ~/ 2 : args.length ~/ 2;

    for (var k = 0; k < pairCount; k++) {
      final condRaw = args[2 * k].trim();
      final value = args[2 * k + 1].trim();
      // The condition comes straight from the UDF body, so its relational
      // operators are still raw — lower them before evaluating.
      final cond =
          preprocessNativeExpression(preprocessLogicalOperators(condRaw));
      final raw = await evaluator(cond);
      final verdict = normalizeBooleanResult(raw).trim();
      if (verdict == 'true') return value;
      if (verdict != 'false') return null; // condition stayed symbolic
    }
    return hasElse ? args.last.trim() : null;
  }

  /// True when the outermost `(` … `)` of [t] wraps the whole string.
  static bool _parensWrapWhole(String t) {
    var depth = 0;
    for (var i = 0; i < t.length; i++) {
      if (t[i] == '(') depth++;
      if (t[i] == ')') depth--;
      if (depth == 0 && i < t.length - 1) return false;
    }
    return true;
  }

  /// Normalize SymEngine's capitalized boolean literals (`True` /
  /// `False`) down to the rest of the codebase's `true` / `false`
  /// convention. Applied to result strings, not inputs.
  static String normalizeBooleanResult(String result) {
    final trimmed = result.trim();
    if (trimmed == 'True') return 'true';
    if (trimmed == 'False') return 'false';
    return result;
  }

  static String preprocessSpecialFunctions(String expression) {
    var result = expression;

    // fib(n) — compute for small n, otherwise delegate to fibonacci(n).
    result = result.replaceAllMapped(RegExp(r'fib\((\d+)\)'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n <= 0) return '0';
      if (n == 1 || n == 2) return '1';
      if (n <= 90) {
        var a = BigInt.zero, b = BigInt.one;
        for (var i = 2; i <= n; i++) {
          final temp = a + b;
          a = b;
          b = temp;
        }
        return b.toString();
      }
      return 'fibonacci($n)';
    });

    // isprime(n) — simple deterministic check for small n.
    result = result.replaceAllMapped(RegExp(r'isprime\((\d+)\)'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n < 2) return 'false';
      if (n == 2) return 'true';
      if (n.isEven) return 'false';
      for (var i = 3; i * i <= n; i += 2) {
        if (n % i == 0) return 'false';
      }
      return 'true';
    });

    return result;
  }

  /// Substitutes Ans + user variables. Variable names are matched
  /// case-sensitively.
  static String substituteVariables(String expression, AppState appState) {
    var result = expression;

    if (result.contains('Ans')) {
      // Use the unrounded engine result (ansValue) rather than the
      // display string, so `8/3` (shown `2.66666666667`) followed by
      // `Ans*3` computes from the full-precision value and lands on 8.
      final lastResult =
          appState.history.isNotEmpty ? appState.history.first.ansValue : '0';
      final cleanResult = extractNumericFromSolveResult(lastResult);
      result = result.replaceAll('Ans', cleanResult);
    }

    for (final entry in appState.userVariables.entries) {
      final pattern = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b');
      result = result.replaceAll(pattern, '(${entry.value})');
    }

    return result;
  }

  static String extractNumericFromSolveResult(String solveResult) {
    // Multi-solution result like "x = 1, x = 2" — the regex
    // anchored at end would happily extract "2" from the last
    // `x = N` chunk, which would be misleading (which solution?).
    // Bail when the result has multiple solutions.
    if (solveResult.contains(',')) return solveResult;
    final match =
        RegExp(r'[a-zA-Z]\s*=\s*([+-]?[\d.]+)\s*$').firstMatch(solveResult);
    if (match != null && !match.group(1)!.contains(',')) {
      return match.group(1)!.trim();
    }
    return solveResult;
  }

  /// Inlines user-defined `Y1`..`Y10` graph slots and named user
  /// functions (e.g. `f(x) = x^2 + 1` typed in the calculator). Both
  /// share the same depth budget so compositions like `g(f(x))` work
  /// up to four nested expansions before the guard kicks in.
  static String preprocessExpression(
    String expression,
    AppState appState, {
    int maxDepth = 4,
  }) {
    var out = expression;
    var remaining = maxDepth;
    while (remaining > 0) {
      final before = out;
      out = _expandUserFunctions(out, appState);
      out = _expandFunctions(out, appState, 1); // Y1..Y10
      if (out == before) break;
      remaining--;
    }
    return out;
  }

  /// Single-pass inline of named [UserFunction] references. Caller
  /// loops until convergence or the depth budget runs out — see
  /// [preprocessExpression]. Skips identifiers followed by `(` that
  /// aren't actually user-function calls so built-ins (`sin`, `gcd`,
  /// `Matrix`) stay intact.
  static String _expandUserFunctions(String expression, AppState appState) {
    if (appState.userFunctions.isEmpty) return expression;
    // Build a per-pass regex of `name(` openers. Sorted longest-first
    // for safety, though single-letter names mean there's no overlap.
    final names = appState.userFunctions.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp(
      r'(?<![a-zA-Z_])(' + names.map(RegExp.escape).join('|') + r')\(',
    );
    final out = StringBuffer();
    var i = 0;
    while (i < expression.length) {
      final match = pattern.matchAsPrefix(expression, i);
      if (match == null) {
        out.write(expression[i]);
        i++;
        continue;
      }
      final name = match.group(1)!;
      // Walk the parens to find the matching close.
      var depth = 1;
      var j = match.end;
      while (j < expression.length && depth > 0) {
        final c = expression[j];
        if (c == '(') depth++;
        if (c == ')') depth--;
        if (depth == 0) break;
        j++;
      }
      if (j >= expression.length || depth != 0) {
        // Unbalanced — leave the original text alone, advance one char.
        out.write(expression[i]);
        i++;
        continue;
      }
      final argStr = expression.substring(match.end, j);
      final fn = appState.userFunctions[name]!;
      final args = _splitTopLevelArgs(argStr);
      if (args.length != fn.arity) {
        // Arity mismatch — leave the call untouched (an error surfaces
        // downstream) rather than silently substituting wrong.
        out.write(expression.substring(i, j + 1));
        i = j + 1;
        continue;
      }
      // Substitute all parameters simultaneously: replace each param
      // token with a placeholder first, then fill placeholders. This
      // avoids a just-substituted arg being re-matched as another
      // parameter name (e.g. params [a, b], body `a + b`, call with
      // arg containing `b`).
      var substituted = fn.body;
      for (var p = 0; p < fn.params.length; p++) {
        substituted = substituted.replaceAll(
          RegExp(r'(?<![a-zA-Z_])' +
              RegExp.escape(fn.params[p]) +
              r'(?![a-zA-Z_0-9])'),
          '\u0000$p\u0001',
        );
      }
      for (var p = 0; p < args.length; p++) {
        substituted = substituted.replaceAll('\u0000$p\u0001', '(${args[p]})');
      }
      out.write('($substituted)');
      i = j + 1;
    }
    return out.toString();
  }

  /// Split a user-function argument list on commas that are not nested
  /// inside parentheses/brackets — so `f(g(a, b), c)` yields two args.
  static List<String> _splitTopLevelArgs(String s) {
    if (s.trim().isEmpty) return const [];
    final parts = <String>[];
    var depth = 0, start = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[') depth++;
      if (c == ')' || c == ']') depth--;
      if (c == ',' && depth == 0) {
        parts.add(s.substring(start, i).trim());
        start = i + 1;
      }
    }
    parts.add(s.substring(start).trim());
    return parts;
  }

  static String _expandFunctions(
      String expression, AppState appState, int depthRemaining) {
    if (depthRemaining <= 0) return expression;

    final funcCallRegex = RegExp(r'Y(\d+)\((.*?)\)');
    final beforeCalls = expression;
    var processed = expression.replaceAllMapped(funcCallRegex, (match) {
      try {
        final funcIndex = int.parse(match.group(1)!) - 1;
        final argValue = match.group(2)!;
        if (funcIndex < 0 || funcIndex >= appState.graphFunctions.length) {
          return match.group(0)!;
        }
        final funcBody = appState.graphFunctions[funcIndex];
        if (funcBody.isEmpty) return match.group(0)!;
        final variable = detectVariable(funcBody);
        final substitutedBody = funcBody.replaceAll(variable, '($argValue)');
        return '($substitutedBody)';
      } catch (_) {
        return match.group(0)!;
      }
    });

    final simpleFuncRegex = RegExp(r'\bY(\d+)\b');
    processed = processed.replaceAllMapped(simpleFuncRegex, (match) {
      try {
        final funcIndex = int.parse(match.group(1)!) - 1;
        if (funcIndex < 0 || funcIndex >= appState.graphFunctions.length) {
          return match.group(0)!;
        }
        final funcBody = appState.graphFunctions[funcIndex];
        if (funcBody.isEmpty) return match.group(0)!;
        return '($funcBody)';
      } catch (_) {
        return match.group(0)!;
      }
    });

    if (processed == beforeCalls) {
      return processed;
    }
    return _expandFunctions(processed, appState, depthRemaining - 1);
  }

  /// Picks the variable to solve for. Reserved tokens (constants, function
  /// names) are skipped. Prefers `x, y, z, t, n, a, b, c` in that order.
  /// **Case-sensitive** — `X` and `x` are different variables.
  /// Substitute parameter values into an expression. Each entry in
  /// [params] maps a parameter name to its current numeric value; the
  /// name is matched as an identifier (not as part of a longer name)
  /// and replaced with its value wrapped in parentheses. Identifiers
  /// followed by `(` are left alone so function calls don't get
  /// mangled. Returns [expression] unchanged when [params] is empty.
  static String substituteParameters(
      String expression, Map<String, double> params) {
    if (params.isEmpty) return expression;
    var out = expression;
    for (final entry in params.entries) {
      final pattern = RegExp(
          '(?<![a-zA-Z_0-9])${RegExp.escape(entry.key)}(?![a-zA-Z_0-9\\(])');
      out = out.replaceAll(pattern, '(${entry.value})');
    }
    return out;
  }

  /// Pull out parameter names from a graphable function expression. A
  /// parameter is any identifier in the expression that:
  ///   - is not the plot variable [plotVar]
  ///   - is not a reserved constant or function name
  ///   - is not immediately followed by `(` (so a function call like
  ///     `sin(x)` doesn't get its name harvested)
  ///
  /// Returns a deduplicated, sorted list — the graphing screen uses it
  /// to decide which sliders to render. Returns an empty list when no
  /// parameters are found.
  static List<String> detectParameters(String expression, String plotVar) {
    if (expression.isEmpty) return const [];

    // Identifier candidates: letters (allowing multi-char names like
    // `freq`), with a non-letter/digit boundary on either side, AND not
    // immediately followed by `(`.
    final paramPattern =
        RegExp(r'(?<![a-zA-Z_0-9])([a-zA-Z][a-zA-Z]*)(?![a-zA-Z_0-9\(])');
    final found = <String>{};
    for (final m in paramPattern.allMatches(expression)) {
      final name = m.group(1)!;
      if (name == plotVar) continue;
      if (_reservedTokens.contains(name)) continue;
      found.add(name);
    }
    final list = found.toList()..sort();
    return list;
  }

  static String detectVariable(String equation) {
    // A single letter that isn't adjacent to another letter on either side.
    // `\b` alone would miss `k` in `2k+5` because the digit-letter boundary
    // isn't a `\b` boundary, so we use explicit lookbehind/lookahead.
    final variablePattern = RegExp(r'(?<![a-zA-Z])([a-zA-Z])(?![a-zA-Z])');
    final foundVariables = <String>{};
    for (final match in variablePattern.allMatches(equation)) {
      final variable = match.group(1)!;
      if (!_reservedTokens.contains(variable)) {
        foundVariables.add(variable);
      }
    }

    _log('candidates: $foundVariables');

    const preferred = ['x', 'y', 'z', 't', 'n', 'a', 'b', 'c'];
    for (final p in preferred) {
      if (foundVariables.contains(p)) return p;
    }
    if (foundVariables.isNotEmpty) return foundVariables.first;
    return 'x';
  }

  /// True when [token] collides with a CAS built-in (constant or
  /// function name) or the calculator's `Ans` slot. Public so the
  /// round-91 "Store result as variable / function" dialogs can reject
  /// user-chosen names that would shadow an engine identifier.
  static bool isReservedName(String token) => _reservedTokens.contains(token);

  /// Round 91: collects every identifier in [expression] that isn't a
  /// reserved CAS token or a graph-slot reference (`Y1`..`Y10`). Used
  /// by the "Store result as function" menu item to decide whether the
  /// expression actually has a free parameter to bind on, and to pick
  /// a default `paramVar` for the new UserFunction.
  ///
  /// Returns a stable insertion-ordered set (first occurrence wins).
  static Set<String> extractFreeVariables(String expression) {
    final result = <String>{};
    final pattern = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');
    for (final match in pattern.allMatches(expression)) {
      final token = match.group(0)!;
      if (_reservedTokens.contains(token)) continue;
      if (RegExp(r'^Y\d+$').hasMatch(token)) continue;
      result.add(token);
    }
    return result;
  }

  /// Cleans up SymEngine's complex-number representation, stray operators,
  /// and Python-style exponents in numeric/symbolic results.
  static String normalizeComplexResult(String result) {
    if (result.isEmpty) return result;

    var normalized = result.trim();

    // Drop zero imaginary parts.
    normalized = normalized
        .replaceAll(RegExp(r'\s*\+\s*-0(\.0*)?\s*\*?\s*I\b'), '')
        .replaceAll(RegExp(r'\s*\+\s*0(\.0*)?\s*\*?\s*I\b'), '')
        .replaceAll(RegExp(r'\s*\+\s*0\.0\s*\*\s*I\s*\*\s*\d+'), '')
        .replaceAll(RegExp(r'^\s*0(\.0*)?\s*\*\s*I\s*$'), '0');

    // I -> i for display. Use replaceAllMapped — Dart's plain
    // `replaceAll(RegExp, String)` doesn't interpret `\1`-style
    // back-references; pass-through would otherwise emit the
    // literal text `\1i` instead of the captured digits.
    normalized = normalized
        .replaceAllMapped(RegExp(r'(\d+)\s*\*\s*I\b'), (m) => '${m.group(1)}i')
        .replaceAll(RegExp(r'\bI\b'), 'i');

    // Normalize spacing.
    //
    // For `-` we only space when both sides have a non-whitespace
    // character — i.e. the `-` is a binary operator. The previous
    // unconditional `\s*-\s*` → ` - ` turned a unary minus at the
    // start of a result (`-5`, `-5.0`) into `- 5`, which then broke
    // every consumer that called `double.tryParse` on the value
    // (most importantly `AppState.formatNumber`, so the
    // `NumberDisplayFormat` setting was silently ignored on
    // negative results). The bounded-context replace keeps `x - 1`
    // and `1 - 2` formatted with spaces while leaving the leading
    // unary `-` glued to its operand.
    // Protect scientific-notation exponents from the operator-spacing
    // rules below: `1.5e-14` must stay glued, not become `1.5e - 14`
    // (which is unparseable downstream — it bypassed
    // `AppState.formatNumber`'s display rounding and, substituted for
    // `Ans`, would misread `e` as Euler's constant). The sign is
    // swapped for a sentinel and restored after spacing.
    const ePlus = '\u0001', eMinus = '\u0002';
    normalized = normalized
        .replaceAllMapped(RegExp(r'(\d[eE])\+(?=\d)'), (m) => '${m[1]}$ePlus')
        .replaceAllMapped(RegExp(r'(\d[eE])-(?=\d)'), (m) => '${m[1]}$eMinus');

    normalized = normalized
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*\+\s*'), ' + ');
    // Use a lookahead for the trailing `\S` so it isn't consumed.
    // The old form `(\S)\s*-\s*(\S)` would gobble the right
    // operand and leave a chained `a-b-c` half-spaced as
    // `a - b-c` — the `b` was consumed by the first match and
    // the next iteration's start position skipped past it.
    // Only space a `-` that is genuinely *binary*. The preceding
    // character has to be one that can end an operand — a digit,
    // letter, or a closing bracket. After `(`, `{`, `[`, `,` or another
    // operator the `-` is a unary sign and belongs glued to its
    // operand, otherwise `{2, -2}` renders as `{2, - 2}` and
    // `(-1 + x)` as `( - 1 + x)`.
    normalized = normalized
        .replaceAllMapped(
          RegExp(r'([\w\)\]\}])\s*-\s*(?=\S)'),
          (m) => '${m[1]} - ',
        )
        .replaceAll(RegExp(r'\s*\*\s*'), '*')
        .trim();

    // Restore the exponent signs protected above.
    normalized = normalized.replaceAll(ePlus, '+').replaceAll(eMinus, '-');

    normalized = normalized.replaceAll(
        RegExp(r'^([+-]?\d+(?:\.\d+)?)\s*\+\s*0\.0\s*\*\s*I$'), r'\1');

    if (normalized.endsWith(' +') || normalized.endsWith(' -')) {
      normalized = normalized.substring(0, normalized.length - 2).trim();
    }

    // Python-style exponents for nicer display.
    normalized = normalized
        .replaceAll('**2', '²')
        .replaceAll('**3', '³')
        .replaceAllMapped(RegExp(r'\*\*(\d+)'), (m) => '^${m.group(1)}');

    // Drop the `*` between a coefficient and a single-letter
    // variable. The negative lookahead must include `[a-zA-Z]` so
    // multi-letter idents (`2*sin`, `3*cos`) keep their `*` —
    // otherwise `sin` reads as the letter `s` followed by `in` and
    // we strip the join, mangling `2*sin` → `2sin`.
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d+)\s*\*\s*([a-zA-Z])(?![a-zA-Z\*])'),
      (m) => '${m.group(1)}${m.group(2)}',
    );

    if (RegExp(r'^[\+\-\*\s]*$').hasMatch(normalized)) {
      normalized = result;
    }

    return normalized;
  }
}
