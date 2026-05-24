// test/user_functions_test.dart
//
// Persistence + preprocessor coverage for named user-defined
// functions. The preprocessor is the load-bearing piece: it inlines
// `f(arg)` into the body before SymEngine sees the string, so the
// evaluator never has to know UDFs exist. Composition + recursion
// budget + collision-with-builtins behavior all covered here.

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/utils/expression_preprocessing_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _freshAppState() async {
  SharedPreferences.setMockInitialValues({});
  final s = AppState();
  await s.load(force: true);
  return s;
}

void main() {
  group('AppState user function persistence', () {
    test('default state has no user functions', () async {
      final s = await _freshAppState();
      expect(s.userFunctions, isEmpty);
    });

    test('setUserFunction writes through to prefs', () async {
      final s = await _freshAppState();
      s.setUserFunction(
        const UserFunction(name: 'f', paramVar: 'x', body: 'x^2 + 1'),
      );
      final fresh = await SharedPreferences.getInstance();
      final raw = fresh.getString('crisp.userFunctions');
      expect(raw, isNotNull);
      expect(raw, contains('"n":"f"'));
      expect(raw, contains('"b":"x^2 + 1"'));
    });

    test('load() restores stored functions', () async {
      SharedPreferences.setMockInitialValues({
        'crisp.userFunctions':
            '[{"n":"f","v":"x","b":"x^2"},{"n":"g","v":"t","b":"sin(t)"}]',
      });
      final s = AppState();
      await s.load(force: true);
      expect(s.userFunctions.length, 2);
      expect(s.userFunctions['f']?.body, 'x^2');
      expect(s.userFunctions['g']?.paramVar, 't');
    });

    test('removeUserFunction drops the entry from prefs', () async {
      final s = await _freshAppState();
      s.setUserFunction(
        const UserFunction(name: 'h', paramVar: 'x', body: 'x'),
      );
      s.removeUserFunction('h');
      final fresh = await SharedPreferences.getInstance();
      expect(fresh.getString('crisp.userFunctions'), '[]');
    });

    test('exportToJson includes user functions', () async {
      final s = await _freshAppState();
      s.setUserFunction(
        const UserFunction(name: 'f', paramVar: 'x', body: 'x*2'),
      );
      final json = s.exportToJson();
      expect(json['userFunctions'], isA<List>());
      expect((json['userFunctions'] as List).length, 1);
    });

    test('idempotent removeUserFunction — no notification when no entry',
        () async {
      final s = await _freshAppState();
      var notifications = 0;
      void cb() => notifications++;
      s.addListener(cb);
      s.removeUserFunction('nonexistent');
      expect(notifications, 0);
      s.removeListener(cb);
    });
  });

  group('preprocessor inlines named user functions', () {
    test('with no functions defined, expression passes through', () async {
      final s = await _freshAppState();
      expect(
        ExpressionPreprocessingUtils.preprocessExpression('sin(x) + 1', s),
        'sin(x) + 1',
      );
    });

    test('simple inline: f(3) with f(x) = x^2 + 1', () async {
      final s = await _freshAppState();
      s.setUserFunction(
        const UserFunction(name: 'f', paramVar: 'x', body: 'x^2 + 1'),
      );
      final out = ExpressionPreprocessingUtils.preprocessExpression('f(3)', s);
      // `(3)` substituted for `x` inside the body, then the whole body
      // wrapped in one outer paren pair to keep precedence.
      expect(out, '((3)^2 + 1)');
    });

    test('composition g(f(x)) expands twice', () async {
      final s = await _freshAppState();
      s.setUserFunction(
        const UserFunction(name: 'f', paramVar: 'x', body: 'x + 1'),
      );
      s.setUserFunction(
        const UserFunction(name: 'g', paramVar: 'x', body: '2*x'),
      );
      final out =
          ExpressionPreprocessingUtils.preprocessExpression('g(f(2))', s);
      // After two passes: f(2) → (((2)) + 1); then g((...)) → (2*(...)).
      expect(out, contains('2*'));
      expect(out, contains('+ 1'));
    });

    test('built-in names are NOT inlined when no UDF shadows them', () async {
      final s = await _freshAppState();
      s.setUserFunction(
        const UserFunction(name: 'f', paramVar: 'x', body: 'x*2'),
      );
      // `sin(x)` should pass through untouched.
      final out =
          ExpressionPreprocessingUtils.preprocessExpression('sin(x) + f(1)', s);
      expect(out, startsWith('sin(x)'));
      expect(out, contains('1'));
    });

    test('depth budget guards against infinite recursion', () async {
      final s = await _freshAppState();
      // Self-referential definition (silly but possible).
      s.setUserFunction(
        const UserFunction(name: 'f', paramVar: 'x', body: 'f(x) + 1'),
      );
      // Should terminate; output still contains some f( residue but
      // doesn't loop forever. The maxDepth=4 default bottoms out and
      // returns whatever we have.
      final out = ExpressionPreprocessingUtils.preprocessExpression('f(5)', s,
          maxDepth: 3);
      expect(out, isNotNull);
      // Sanity: didn't blow stack.
    });

    test('parameter substitution is identifier-bounded', () async {
      final s = await _freshAppState();
      // Body uses `x`; expression uses `xx` as a separate identifier.
      s.setUserFunction(
        const UserFunction(name: 'f', paramVar: 'x', body: 'x + xx'),
      );
      final out = ExpressionPreprocessingUtils.preprocessExpression('f(2)', s);
      // `x` becomes `(2)`, but `xx` stays.
      expect(out, contains('xx'));
      expect(out, contains('(2)'));
    });

    test('different parameter variable: f(t) = sin(t)', () async {
      final s = await _freshAppState();
      s.setUserFunction(
        const UserFunction(name: 'f', paramVar: 't', body: 'sin(t)'),
      );
      final out =
          ExpressionPreprocessingUtils.preprocessExpression('f(0.5)', s);
      expect(out, contains('sin'));
      expect(out, contains('0.5'));
    });
  });
}
