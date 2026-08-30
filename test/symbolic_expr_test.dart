// test/symbolic_expr_test.dart
//
// Unit coverage for the pure-Dart symbolic expression layer that
// backs the web build (and any other native-less target).
//
// Three things are under test:
//   1. `tryEvaluate` renders a correct, canonical result.
//   2. `diagnose` separates "still typing" from real mistakes — the
//      distinction the Notepad relies on to stay quiet mid-keystroke.
//   3. Correct-or-silent: nothing here may return a *wrong* answer.

import 'package:crisp_math/engine/symbolic_expr.dart';
import 'package:flutter_test/flutter_test.dart';

String? ev(String s) => SymbolicExpressionEvaluator.tryEvaluate(s);
ExpressionProblem diag(String s) =>
    SymbolicExpressionEvaluator.diagnose(s).problem;

void main() {
  group('numeric folding (exact)', () {
    test('integer arithmetic', () {
      expect(ev('2 + 3'), '5');
      expect(ev('10 - 4'), '6');
      expect(ev('6 * 7'), '42');
      expect(ev('2^10'), '1024');
      expect(ev('-5 + 2'), '-3');
    });

    test('division stays exact', () {
      expect(ev('10 / 4'), '5/2');
      expect(ev('1 / 3'), '1/3');
      expect(ev('9 / 3'), '3');
    });

    test('decimals become exact rationals', () {
      expect(ev('1.5 * 4'), '6');
      expect(ev('0.1 + 0.2'), '3/10'); // exactly 3/10, not 0.30000000000000004
      expect(ev('2.5'), '5/2');
    });

    test('scientific notation', () {
      expect(ev('1e3'), '1000');
      expect(ev('1e3 + 1'), '1001');
      expect(ev('2.5e-1'), '1/4');
    });

    test('negative and nested powers', () {
      expect(ev('2^-2'), '1/4');
      expect(ev('2^3^2'), '512'); // right-associative: 2^(3^2)
      expect(ev('-2^2'), '-4'); // unary minus binds looser than ^
    });
  });

  group('symbolic simplification', () {
    test('like terms combine', () {
      expect(ev('x + x'), '2x');
      expect(ev('x - x'), '0');
      expect(ev('3x + 2x'), '5x');
      expect(ev('x + 1'), 'x + 1');
    });

    test('like factors combine', () {
      expect(ev('x * x'), 'x^2');
      expect(ev('x * x^2'), 'x^3');
      expect(ev('x / x'), '1');
      expect(ev('x^2 / x'), 'x');
    });

    test('multiple symbols', () {
      expect(ev('x*y'), 'xy');
      expect(ev('2*x*y'), '2xy');
      expect(ev('x*y + y*x'), '2xy');
    });

    test('reciprocals render as division', () {
      expect(ev('1/x'), '1/x');
      expect(ev('x/y'), 'x/y');
      expect(ev('3/(2x)'), '3/(2x)');
    });

    test('zero and identity laws', () {
      expect(ev('0 * x'), '0');
      expect(ev('1 * x'), 'x');
      expect(ev('x^0'), '1');
      expect(ev('x^1'), 'x');
      expect(ev('x + 0'), 'x');
    });

    test('polynomial ordering is high-degree-first', () {
      expect(ev('1 + 2x + x^2'), 'x^2 + 2x + 1');
      expect(ev('x + x^3'), 'x^3 + x');
    });

    test('sums are not auto-expanded', () {
      expect(ev('(x+1)^2'), '(x + 1)^2');
    });

    test('function calls stay symbolic', () {
      expect(ev('sin(x)'), 'sin(x)');
      expect(ev('sin(x) + x'), 'x + sin(x)');
      expect(ev('sqrt(x)'), 'sqrt(x)');
      // `*` before a function call, matching SymEngine's own printing —
      // `2sin(x)` would juxtapose a coefficient onto a call, which the
      // native path never emits.
      expect(ev('sin(x) + sin(x)'), '2*sin(x)');
      expect(ev('x*sin(x)'), 'x*sin(x)');
    });

    test('multi-letter symbols work like single-letter ones', () {
      // The native bridge rejects `abc` on web; the fallback must not.
      expect(ev('abc'), 'abc');
      expect(ev('abc + abc'), '2abc');
      expect(ev('foo_bar * 2'), '2foo_bar');
    });

    test('exactly-representable function values fold', () {
      expect(ev('sqrt(4)'), '2');
      expect(ev('sqrt(9/4)'), '3/2');
      expect(ev('abs(-3)'), '3');
      expect(ev('sin(0)'), '0');
      expect(ev('cos(0)'), '1');
      expect(ev('exp(0)'), '1');
      expect(ev('ln(1)'), '0');
    });

    test('inexact function values stay symbolic rather than going float', () {
      expect(ev('sqrt(2)'), 'sqrt(2)');
      expect(ev('sin(1)'), 'sin(1)');
    });

    test('implicit multiplication', () {
      expect(ev('2x'), '2x');
      expect(ev('2(x+1)'), '2*(x + 1)');
      expect(ev('x y'), 'xy');
    });

    test('constants stay symbolic', () {
      expect(ev('pi'), 'pi');
      expect(ev('2pi'), '2pi');
    });
  });

  group('diagnosis — incomplete (user is still typing)', () {
    test('trailing binary operator', () {
      expect(diag('2 +'), ExpressionProblem.incomplete);
      expect(diag('2 *'), ExpressionProblem.incomplete);
      expect(diag('2 -'), ExpressionProblem.incomplete);
      expect(diag('2 /'), ExpressionProblem.incomplete);
      expect(diag('2 ^'), ExpressionProblem.incomplete);
      expect(diag('x +'), ExpressionProblem.incomplete);
    });

    test('unclosed grouping', () {
      expect(diag('(3+4'), ExpressionProblem.incomplete);
      expect(diag('(('), ExpressionProblem.incomplete);
      expect(diag('sin('), ExpressionProblem.incomplete);
      expect(diag('sin(x'), ExpressionProblem.incomplete);
      expect(diag('max(1,'), ExpressionProblem.incomplete);
    });

    test('bare operators and empty input', () {
      expect(diag('+'), ExpressionProblem.incomplete);
      expect(diag('-'), ExpressionProblem.incomplete);
      expect(diag('.'), ExpressionProblem.incomplete);
      expect(diag(''), ExpressionProblem.incomplete);
      expect(diag('   '), ExpressionProblem.incomplete);
    });

    test('complete expressions are not incomplete', () {
      expect(diag('2 + 3'), ExpressionProblem.none);
      expect(diag('sin(x)'), ExpressionProblem.none);
      expect(diag('(3+4)'), ExpressionProblem.none);
    });
  });

  group('diagnosis — real mistakes', () {
    test('unbalanced close bracket', () {
      expect(diag(')'), ExpressionProblem.unbalancedClose);
      expect(diag('2+3)'), ExpressionProblem.unbalancedClose);
    });

    test('unknown function', () {
      final d = SymbolicExpressionEvaluator.diagnose('foo(1)');
      expect(d.problem, ExpressionProblem.unknownFunction);
      expect(d.name, 'foo');
    });

    test('wrong arity', () {
      final d = SymbolicExpressionEvaluator.diagnose('sin(1, 2)');
      expect(d.problem, ExpressionProblem.wrongArity);
      expect(d.name, 'sin');
    });

    test('division by zero', () {
      expect(diag('1/0'), ExpressionProblem.divisionByZero);
      expect(diag('x/0'), ExpressionProblem.divisionByZero);
    });

    test('malformed', () {
      expect(diag('2..3'), ExpressionProblem.malformed);
      expect(diag('2,,3'), ExpressionProblem.malformed);
    });
  });

  group('numeric calls fold to a number, never echo', () {
    // Echoing `gcd(12, 18)` back reads like an answer rather than a
    // failure, so a numeric call either produces a value or is refused.
    test('integer functions', () {
      expect(ev('gcd(12, 18)'), '6');
      expect(ev('lcm(4, 6)'), '12');
      expect(ev('mod(17, 5)'), '2');
      expect(ev('min(3, 7)'), '3');
      expect(ev('max(3, 7)'), '7');
      expect(ev('factorial(5)'), '120');
    });

    test('rounding family', () {
      expect(ev('floor(2.7)'), '2');
      expect(ev('floor(-2.3)'), '-3');
      expect(ev('ceiling(2.3)'), '3');
      expect(ev('ceiling(-2.7)'), '-2');
      expect(ev('round(2.5)'), '3');
      expect(ev('round(-2.5)'), '-3');
      expect(ev('round(2.4)'), '2');
    });

    test('exact logarithms', () {
      expect(ev('log10(1000)'), '3');
      expect(ev('log2(8)'), '3');
      expect(ev('log10(1/100)'), '-2');
    });

    test('undefined or inexact numeric calls are refused, not echoed', () {
      expect(ev('ln(0)'), isNull);
      expect(ev('log10(0)'), isNull);
      expect(ev('gcd(1/2, 3)'), isNull);
      // A positive log with no exact value stays symbolic, like sqrt(2).
      expect(ev('log10(50)'), 'log10(50)');
      expect(ev('ln(2)'), 'ln(2)');
    });

    test('symbolic arguments still stay symbolic', () {
      expect(ev('gcd(x, y)'), 'gcd(x, y)');
      expect(ev('max(x, 1)'), 'max(x, 1)');
    });
  });

  group('unknown vs merely unsupported functions', () {
    test('a genuine typo is reported as unknown', () {
      final d = SymbolicExpressionEvaluator.diagnose('sinn(x)');
      expect(d.problem, ExpressionProblem.unknownFunction);
      expect(d.name, 'sinn');
      expect(engineErrorForDiagnosis(d), contains('unknown function sinn'));
    });

    test('a real app function this layer cannot do is not called unknown', () {
      // `taylor` and `besselj` are in the app's own catalogue. Saying
      // they do not exist would be a lie, so nothing is claimed and the
      // real engine keeps its own error.
      for (final name in ['taylor', 'besselj', 'factorint', 'zeta']) {
        final d = SymbolicExpressionEvaluator.diagnose('$name(x)');
        expect(d.problem, ExpressionProblem.unsupportedFunction,
            reason: '$name is a documented app function');
        expect(engineErrorForDiagnosis(d), isNull,
            reason: 'nothing should be claimed about $name');
      }
    });
  });

  group('correct-or-silent', () {
    test('unparseable input yields null, never a guess', () {
      expect(ev('2 +'), isNull);
      expect(ev('foo(1)'), isNull);
      expect(ev('1/0'), isNull);
      expect(ev(')'), isNull);
      expect(ev(''), isNull);
    });

    test('round-trip: rendering a result re-parses to the same value', () {
      const inputs = [
        'x + 1',
        'x^2 + 2x + 1',
        'x*y',
        '1/x',
        'x/y',
        'sin(x) + x',
        '3/(2x)',
        '2*(x + 1)',
        'x^2 + 2x + 1',
        '-x + 1',
        '5/2',
      ];
      for (final input in inputs) {
        final once = ev(input);
        expect(once, isNotNull, reason: 'failed to evaluate $input');
        final twice = ev(once!);
        expect(twice, once,
            reason: 'rendering of "$input" is not a fixed point: '
                '"$once" re-evaluated to "$twice"');
      }
    });
  });
}
