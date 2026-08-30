// integration_test/web_cas_fallback_test.dart
//
// Pins the contract between the SymEngine WASM module and the pure-Dart
// fallback that covers for it on web.
//
// The exported `flutter_symengine_evaluate` is a *numeric* evaluator:
// it returns a complex double and throws the moment the expression
// contains a free symbol. Emscripten hands that exception to Dart as a
// bare `{excPtr: <int>}` JS object whose `toString()` is
// `[object Object]`, and this build exports no `getExceptionMessage`
// helper, so there is no message to recover. Every symbolic expression
// on web therefore depends on `SymbolicExpressionEvaluator` picking up
// where the bridge gives up.
//
// The first group documents that bridge behaviour (so a future WASM
// build that *does* handle symbols shows up here as a change rather
// than a mystery); the rest assert that users never see the failure.
//
//   chromedriver --port=4444 &
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/web_cas_fallback_test.dart \
//     -d web-server --browser-name=chrome
import 'package:crisp_math/engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';

/// Raw bridge call: 'ok' when it returned, 'throw' when it did not.
String _bridge(String expr) {
  try {
    SymbolicMathBridge().evaluate(expr);
    return 'ok';
  } catch (_) {
    return 'throw';
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await pollForNativeBridge(timeout: const Duration(seconds: 30));
  });

  testWidgets('the WASM module is actually loaded', (tester) async {
    expect(nativeBridgeStatus.value, NativeBridgeStatus.ready,
        reason: 'without the WASM module this whole file proves nothing');
  });

  testWidgets(
      'the raw bridge is numeric-only — this is why the fallback '
      'exists', (tester) async {
    // Numeric input: handled natively.
    for (final expr in ['2+3', '10/4', 'sqrt(2)', 'sin(pi/2)']) {
      expect(_bridge(expr), 'ok', reason: '$expr is numeric');
    }
    // Any free symbol: throws.
    for (final expr in ['x', 'x+1', 'sin(x)', 'x*y', '1/x', 'abc']) {
      expect(_bridge(expr), 'throw',
          reason: '$expr has a free symbol — if this now returns, the WASM '
              'build gained symbolic support and the fallback ordering in '
              'CalculatorEngine.evaluate should be revisited');
    }
    // The module survives its own exceptions (an early theory for the
    // Notepad failures was that one bad parse poisoned it — it does not).
    expect(_bridge('2+3'), 'ok',
        reason: 'the module must still work after throwing');
  });

  testWidgets('no user-visible result is ever an opaque JS object',
      (tester) async {
    final engine = CalculatorEngine();
    const corpus = [
      '2+3',
      '10/4',
      '2^10',
      'sqrt(2)',
      'sin(pi/2)',
      '5!',
      'x',
      'x+1',
      'x^2+2*x+1',
      'sin(x)',
      'sin(x)+x',
      'x*y',
      '1/x',
      'sqrt(x)',
      'abc',
      'foo_bar*2',
      '1/0',
      '0/0',
      'foo(1)',
      'sin()',
      '2,,3',
      '2..3',
      '2 +',
      '2*',
      'y=',
      '((',
      '(3+4',
      ')',
      '+',
      '.',
    ];
    final offenders = <String>[];
    for (final expr in corpus) {
      final out = engine.evaluate(expr);
      if (out.contains('[object Object]') ||
          out.contains('excPtr') ||
          RegExp(r'failed:\s*$').hasMatch(out)) {
        offenders.add('$expr -> $out');
      }
    }
    expect(offenders, isEmpty,
        reason: 'opaque engine output:\n${offenders.join('\n')}');
  });

  testWidgets('symbolic expressions evaluate on web', (tester) async {
    final engine = CalculatorEngine();
    const expected = {
      'x + 1': 'x + 1',
      'sin(x)': 'sin(x)',
      'x*y': 'xy',
      '1/x': '1/x',
      'sqrt(x)': 'sqrt(x)',
      'abc': 'abc',
      'x + x': '2x',
    };
    final failures = <String>[];
    expected.forEach((input, want) {
      final got = engine.evaluate(input);
      if (got != want) failures.add('"$input": expected "$want", got "$got"');
    });
    expect(failures, isEmpty, reason: failures.join('\n'));

    // `x/x` cancels to a constant inside SymEngine, so the bridge
    // answers it numerically rather than throwing — the raw engine
    // string is its complex-double form, which the display layer
    // normalizes to `1`.
    expect(engine.evaluate('x/x'), '1.0 + 0.0*I');
  });

  testWidgets('math errors name the actual problem', (tester) async {
    final engine = CalculatorEngine();
    expect(engine.evaluate('1/0'), contains('division by zero'));
    expect(engine.evaluate('foo(1)'), contains('unknown function foo'));
  });
}
