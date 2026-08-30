// integration_test/notepad_web_live_test.dart
//
// Live-browser regression tests for the Notepad, run against the real
// SymEngine WASM module in Chrome.
//
// This harness exists because `flutter test` cannot see these bugs:
// the headless test VM has no CAS bridge at all, so every expression
// falls through to the pure-Dart path and the WASM-specific failures
// are invisible. Measured in a real browser, the web build used to
// answer "Error: evaluate failed: [object Object]" for every symbolic
// expression (`sin(x)`, `x*y`, `1/x`), every math error (`1/0`), and
// every half-typed line (`2 +`, `y=`) — because the exported
// `flutter_symengine_evaluate` is a *numeric* evaluator that throws a
// bare Emscripten `{excPtr}` object the moment it meets a free symbol.
//
// Run:
//   chromedriver --port=4444 &
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/notepad_web_live_test.dart \
//     -d web-server --browser-name=chrome
import 'package:crisp_math/engine/app_state.dart';
import 'package:crisp_math/engine/calculator_engine.dart';
import 'package:crisp_math/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a single notepad line should produce.
class Expectation {
  final String input;

  /// Exact expected result, or null when the line should show nothing.
  final String? result;

  /// Substring the error must contain, or null when there must be no
  /// error at all.
  final String? errorContains;

  const Expectation(this.input, {this.result, this.errorContains});

  /// The line is still being typed: no result, and — the whole point —
  /// no error either.
  const Expectation.silent(this.input)
      : result = null,
        errorContains = null;
}

const _cases = <Expectation>[
  // --- arithmetic
  Expectation('2 + 3', result: '5'),
  Expectation('10 / 4', result: '2.5'),
  Expectation('2^10', result: '1024'),
  Expectation('-5 + 2', result: '-3'),
  Expectation('5!', result: '120'),
  Expectation('abs(-3)', result: '3'),
  Expectation('sin(pi/2)', result: '1'),

  // --- half-typed lines must stay silent, not shout [object Object]
  Expectation.silent('2 +'),
  Expectation.silent('2 *'),
  Expectation.silent('y='),
  Expectation.silent('(3+4'),
  Expectation.silent('sin('),
  Expectation.silent('+'),
  Expectation.silent('.'),

  // --- symbolic input: the WASM bridge throws on every one of these,
  //     so each is answered by the pure-Dart symbolic layer.
  Expectation('x + 1', result: 'x + 1'),
  Expectation('sin(x)', result: 'sin(x)'),
  Expectation('x*y', result: 'xy'),
  Expectation('1/x', result: '1/x'),
  Expectation('sqrt(x)', result: 'sqrt(x)'),
  Expectation('abc', result: 'abc'),

  // --- errors must name the actual problem
  Expectation('1/0', errorContains: 'division by zero'),
  Expectation('foo(1)', errorContains: 'unknown function foo'),

  // --- CAS calls, including the unary-minus display fix: these used to
  //     render as `x = {2, - 2}` and `(1 + x)*( - 1 + x)`.
  Expectation('diff(x^3, x)', result: '3x²'),
  Expectation('expand((x+1)^2)', result: '1 + 2x + x²'),
  Expectation('solve(x^2 - 4, x)', result: 'x = {2, -2}'),
  Expectation('factor(x^2 - 1)', result: '(1 + x)*(-1 + x)'),
  Expectation('simplify(x/x)', result: '1'),

  // --- a comma inside a call used to be rewritten as a decimal point,
  //     silently merging two arguments: `gcd(12,18)` -> `gcd(12.18)`,
  //     `Matrix([[1,2],[3,4]])` -> `Matrix([[1.2],[3.4]])` (which is
  //     also what broke det()).
  Expectation('gcd(12, 18)', result: '6'),
  Expectation('lcm(4, 6)', result: '12'),
  Expectation('Matrix([[1,2],[3,4]])', result: 'Matrix([[1, 2], [3, 4]])'),
  Expectation('det(Matrix([[1,2],[3,4]]))', result: '-2'),

  // --- a function name ending in a digit used to be split by the
  //     implicit-multiplication rule: `log10(1000)` -> `log10*(1000)`,
  //     which rendered as the nonsense result `1000log10`.
  Expectation('log10(1000)', result: '3'),
  Expectation('log2(8)', result: '3'),

  // --- units
  Expectation('5 km + 3 m', result: '5.003 km'),
  Expectation('100 km in miles', result: '62.1371192237 mi'),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notepad lines evaluate correctly in a real browser',
      (tester) async {
    SharedPreferences.setMockInitialValues({'crisp.onboardingDismissed': true});
    final appState = AppState();
    await appState.load(force: true);
    await pollForNativeBridge(timeout: const Duration(seconds: 30));
    expect(nativeBridgeStatus.value, NativeBridgeStatus.ready,
        reason: 'the SymEngine WASM module must be loaded, otherwise this '
            'test silently degrades to the pure-Dart path and proves nothing');

    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    await tester.pumpWidget(const CrispMathApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Notepad').first);
    await tester.pumpAndSettle();

    final failures = <String>[];
    for (final c in _cases) {
      final fields = find.byType(TextField);
      final n = fields.evaluate().length;
      await tester.enterText(fields.at(n - 1), c.input);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final doc = appState.notepadDocuments[appState.currentNotepadDocId]!;
      final matches = doc.lines.where((l) => l.source == c.input).toList();
      final line = matches.isNotEmpty ? matches.last : doc.lines.last;
      final res = line.cachedResult;
      final err = line.cachedError;

      if (c.errorContains != null) {
        if (err == null || !err.contains(c.errorContains!)) {
          failures.add('"${c.input}": expected error containing '
              '"${c.errorContains}", got error=$err result=$res');
        }
        continue;
      }
      if (err != null) {
        failures.add('"${c.input}": expected no error, got "$err"');
        continue;
      }
      if (res != c.result) {
        failures.add('"${c.input}": expected result ${c.result == null ? //
            'nothing' : '"${c.result}"'}, got ${res == null ? 'nothing' : '"$res"'}');
      }
    }

    expect(failures, isEmpty,
        reason: 'live browser mismatches:\n${failures.join('\n')}');
  });

  testWidgets('typing an expression character by character never errors',
      (tester) async {
    // The reported symptom, reproduced literally: type `2 + 3` one
    // keystroke at a time, waiting past the 300 ms debounce after each
    // so the evaluator really does see every intermediate state. Before
    // the fix, `2 +` painted "evaluate failed: [object Object]" under
    // the cursor.
    SharedPreferences.setMockInitialValues({'crisp.onboardingDismissed': true});
    final appState = AppState();
    await appState.load(force: true);
    await pollForNativeBridge(timeout: const Duration(seconds: 30));

    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    await tester.pumpWidget(const CrispMathApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Notepad').first);
    await tester.pumpAndSettle();

    const target = '2 + 3';
    final seen = <String, String>{};
    for (var i = 1; i <= target.length; i++) {
      final prefix = target.substring(0, i);
      final fields = find.byType(TextField);
      final n = fields.evaluate().length;
      await tester.enterText(fields.at(n - 1), prefix);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final doc = appState.notepadDocuments[appState.currentNotepadDocId]!;
      final line = doc.lines.last;
      if (line.cachedError != null) seen[prefix] = line.cachedError!;
    }
    expect(seen, isEmpty,
        reason: 'no keystroke on the way to "$target" may show an error, '
            'but these did: $seen');

    final doc = appState.notepadDocuments[appState.currentNotepadDocId]!;
    expect(doc.lines.last.cachedResult, '5',
        reason: 'the finished expression must still evaluate');
  });
}
