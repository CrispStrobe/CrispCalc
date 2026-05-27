// Round 103 (P6): help-mode popover on Calculator history rows.
// Tests cover both halves: the pure detection routing
// ([detectHistoryHelp]) and the modal render
// ([HistoryRowHelpModal]) for a representative call kind plus the
// bare-arithmetic fallback.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/function_reference.dart';
import 'package:crisp_calc/localization/app_localizations.dart';
import 'package:crisp_calc/widgets/history_help_modal.dart';

void main() {
  group('detectHistoryHelp — routing table', () {
    test('solve(...) maps to SymEngine.solve with solve step kind', () {
      final info = detectHistoryHelp('solve(x^2 - 1, x)');
      expect(info.engineLabel, equals('SymEngine.solve'));
      expect(info.refId, equals('solve'));
      expect(info.stepKind, equals(HistoryStepKind.solve));
      expect(info.stepExpr, equals('x^2 - 1'));
      expect(info.stepVar, equals('x'));
    });

    test('solve(...) with one arg detects the variable', () {
      final info = detectHistoryHelp('solve(2k + 3)');
      expect(info.stepExpr, equals('2k + 3'));
      expect(info.stepVar, equals('k'));
    });

    test('diff(...) is SymEngine.diff with diff step kind', () {
      final info = detectHistoryHelp('diff(x^2, x)');
      expect(info.engineLabel, equals('SymEngine.diff'));
      expect(info.stepKind, equals(HistoryStepKind.diff));
      expect(info.stepExpr, equals('x^2'));
      expect(info.stepVar, equals('x'));
    });

    test('integrate(...) is SymEngine.integrate with integrate step kind', () {
      final info = detectHistoryHelp('integrate(x^2, x)');
      expect(info.engineLabel, equals('SymEngine.integrate'));
      expect(info.stepKind, equals(HistoryStepKind.integrate));
    });

    test('button-shape d/dx via readable form `(d)/(dx)(...)`', () {
      // `\frac{d}{dx}\bigg(x^2\bigg)` → readable `(d)/(dx)(x^2)`.
      final info = detectHistoryHelp('(d)/(dx)(x^2)');
      expect(info.engineLabel, equals('SymEngine.diff'));
      expect(info.stepKind, equals(HistoryStepKind.diff));
      expect(info.stepExpr, equals('x^2'));
      expect(info.stepVar, equals('x'));
    });

    test('factor / expand / simplify / limit / gcd / lcm carry no step trace',
        () {
      for (final call in const [
        ('factor(x^2 - 1)', 'SymEngine.factor', 'factor'),
        ('expand((x+1)^2)', 'SymEngine.expand', 'expand'),
        ('simplify(x*x)', 'SymEngine.simplify', 'simplify'),
        ('limit(1/x, x, 0)', 'SymEngine.limit', 'limit'),
        ('gcd(12, 18)', 'SymEngine.gcd', 'gcd'),
        ('lcm(4, 6)', 'SymEngine.lcm', 'lcm'),
      ]) {
        final info = detectHistoryHelp(call.$1);
        expect(info.engineLabel, equals(call.$2), reason: call.$1);
        expect(info.refId, equals(call.$3), reason: call.$1);
        expect(info.stepKind, equals(HistoryStepKind.none), reason: call.$1);
      }
    });

    test('FLINT.ntheory family', () {
      for (final pair in const [
        ('isprime(7)', 'isprime'),
        ('nextprime(100)', 'nextprime'),
        ('prevprime(100)', 'prevprime'),
        ('factorint(360)', 'factorint'),
      ]) {
        final info = detectHistoryHelp(pair.$1);
        expect(info.engineLabel, equals('FLINT.ntheory'), reason: pair.$1);
        expect(info.refId, equals(pair.$2), reason: pair.$1);
      }
    });

    test('MPFR precision family requires a leading digit in first arg', () {
      expect(detectHistoryHelp('pi(50)').refId, equals('pi_precision'));
      expect(detectHistoryHelp('e(100)').refId, equals('e_precision'));
      expect(detectHistoryHelp('EulerGamma(20)').refId,
          equals('eulergamma_precision'));
      expect(detectHistoryHelp('sqrt(2, 50)').refId, equals('sqrt_precision'));
      // sqrt(x) without precision falls through to direct evaluation.
      expect(detectHistoryHelp('sqrt(2)').engineLabel, isNull);
    });

    test('matrix calls route to Dart (matrix)', () {
      for (final pair in const [
        ('Matrix([[1,2],[3,4]])', 'matrix_literal'),
        ('det(Matrix([[1,2],[3,4]]))', 'det'),
        ('inv(Matrix([[1,2],[3,4]]))', 'inv'),
        ('transpose(Matrix([[1,2],[3,4]]))', 'transpose'),
        ('rref(Matrix([[1,2],[3,4]]))', 'rref'),
      ]) {
        final info = detectHistoryHelp(pair.$1);
        expect(info.engineLabel, equals('Dart (matrix)'), reason: pair.$1);
        expect(info.refId, equals(pair.$2), reason: pair.$1);
      }
    });

    test('bare equation auto-routes to SymEngine.solve with step trace', () {
      final info = detectHistoryHelp('2x + 3 = 0');
      expect(info.engineLabel, equals('SymEngine.solve'));
      expect(info.stepKind, equals(HistoryStepKind.solve));
      expect(info.stepExpr, equals('2x + 3'));
      expect(info.stepVar, equals('x'));
    });

    test('bare equation with both sides non-trivial', () {
      final info = detectHistoryHelp('x^2 = x + 1');
      expect(info.stepExpr, equals('(x^2) - (x + 1)'));
    });

    test('digits-only `=` is direct evaluation (not solve)', () {
      // No free letter — auto-solve wouldn't fire either.
      final info = detectHistoryHelp('3 = 3');
      expect(info.engineLabel, isNull);
    });

    test('bare arithmetic → direct evaluation', () {
      final info = detectHistoryHelp('2 + 3');
      expect(info.engineLabel, isNull);
      expect(info.refId, isNull);
      expect(info.stepKind, equals(HistoryStepKind.none));
      expect(info.hasEngine, isFalse);
      expect(info.hasSteps, isFalse);
    });

    test('empty input → direct (defensive)', () {
      final info = detectHistoryHelp('   ');
      expect(info.hasEngine, isFalse);
    });
  });

  group('HistoryRowHelpModal — widget render', () {
    Widget host(Widget child) => MaterialApp(
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: child),
        );

    testWidgets(
        'solve(...) row shows engine line + step trace + learn-more buttons',
        (tester) async {
      final entry = CalculationEntry(
        expression: 'solve(x^2 - 1, x)',
        result: '[-1, 1]',
      );
      final info = detectHistoryHelp(entry.expression);
      expect(info.hasSteps, isTrue);
      expect(info.refId, equals('solve'));

      var stepsTapped = false;
      var learnMoreTapped = false;
      await tester.pumpWidget(host(HistoryRowHelpModal(
        entry: entry,
        info: info,
        onShowSteps: () => stepsTapped = true,
        onLearnMore: () => learnMoreTapped = true,
      )));

      // Engine line.
      expect(find.text('Computed via SymEngine.solve'), findsOneWidget);

      // FunctionRef signature + first-sentence-of-shortDescription
      // (the dialog renders the full short description).
      final solveRef =
          FunctionReferences.all.firstWhere((e) => e.id == 'solve');
      expect(find.text(solveRef.signature), findsOneWidget);
      expect(
        find.textContaining(solveRef.shortDescription.split(';').first),
        findsOneWidget,
      );

      // Both action buttons present and wired.
      expect(find.text('Show steps'), findsOneWidget);
      expect(find.text('Learn more'), findsOneWidget);
      await tester.tap(find.text('Show steps'));
      expect(stepsTapped, isTrue);
      await tester.tap(find.text('Learn more'));
      expect(learnMoreTapped, isTrue);
    });

    testWidgets(
        'bare arithmetic row shows Direct-evaluation fallback (no buttons)',
        (tester) async {
      final entry = CalculationEntry(
        expression: '2 + 3',
        result: '5',
      );
      final info = detectHistoryHelp(entry.expression);
      expect(info.hasEngine, isFalse);

      await tester.pumpWidget(host(HistoryRowHelpModal(
        entry: entry,
        info: info,
      )));

      // Fallback blurb shown.
      expect(
        find.text('Direct numerical evaluation — no symbolic call involved.'),
        findsOneWidget,
      );

      // No engine line, no Show-steps, no Learn-more.
      expect(find.textContaining('Computed via'), findsNothing);
      expect(find.text('Show steps'), findsNothing);
      expect(find.text('Learn more'), findsNothing);
      // Close is always present.
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('factor(...) row shows engine + learn-more but no Show-steps',
        (tester) async {
      final entry = CalculationEntry(
        expression: 'factor(x^2 - 1)',
        result: '(x - 1)*(x + 1)',
      );
      final info = detectHistoryHelp(entry.expression);
      expect(info.hasSteps, isFalse);

      await tester.pumpWidget(host(HistoryRowHelpModal(
        entry: entry,
        info: info,
        onLearnMore: () {},
      )));

      expect(find.text('Computed via SymEngine.factor'), findsOneWidget);
      expect(find.text('Learn more'), findsOneWidget);
      expect(find.text('Show steps'), findsNothing);
    });
  });
}
