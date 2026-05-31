// test/native_bridge_wiring_test.dart
//
// Covers the async native/WASM bridge handshake added so the web build's
// SymEngine WASM module is actually picked up once it finishes loading.
//
// The headless test env has no native bridge (symbol lookups fail), so
// `SymbolicMathBridge()` always throws here — the same shape as a web build
// before WASM resolves. That lets us exercise the lifecycle: engines start
// in fallback, a poll that never finds a bridge settles on `unavailable`,
// and the status enum drives `nativeBridgeReady`.

import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('native bridge wiring', () {
    setUp(() {
      // Reset the process-wide signal — it's a singleton and other tests in
      // this file mutate it.
      nativeBridgeStatus.value = NativeBridgeStatus.loading;
    });

    test('nativeBridgeReady mirrors the status enum', () {
      nativeBridgeStatus.value = NativeBridgeStatus.loading;
      expect(nativeBridgeReady, isFalse);

      nativeBridgeStatus.value = NativeBridgeStatus.unavailable;
      expect(nativeBridgeReady, isFalse);

      nativeBridgeStatus.value = NativeBridgeStatus.ready;
      expect(nativeBridgeReady, isTrue);
    });

    test('pollForNativeBridge settles on unavailable when no bridge loads',
        () async {
      nativeBridgeStatus.value = NativeBridgeStatus.loading;
      await pollForNativeBridge(
        interval: const Duration(milliseconds: 5),
        timeout: const Duration(milliseconds: 40),
      );
      expect(nativeBridgeStatus.value, NativeBridgeStatus.unavailable);
      expect(nativeBridgeReady, isFalse);
    });

    test('pollForNativeBridge returns immediately when already ready',
        () async {
      nativeBridgeStatus.value = NativeBridgeStatus.ready;
      // A long timeout would hang the test if the early-return guard were
      // missing.
      await pollForNativeBridge(timeout: const Duration(seconds: 30));
      expect(nativeBridgeStatus.value, NativeBridgeStatus.ready);
    });

    test('engine reports unavailable and serves the pure-Dart fallback',
        () {
      nativeBridgeStatus.value = NativeBridgeStatus.loading;
      final engine = CalculatorEngine();
      expect(engine.isNativeAvailable, isFalse);
      // The web/native-less polynomial fallback still resolves the common
      // CAS subset rather than erroring.
      expect(engine.expand('(x+1)^2'), contains('x^2'));
    });

    test('flipping status to ready makes the engine re-attempt acquisition',
        () {
      nativeBridgeStatus.value = NativeBridgeStatus.loading;
      final engine = CalculatorEngine();
      expect(engine.isNativeAvailable, isFalse);

      // Simulate the WASM module finishing. In this headless env the
      // re-acquisition still fails (no native symbols), so the engine stays
      // in fallback — but the important contract is that querying it after
      // the flip doesn't throw and re-attempts cleanly.
      nativeBridgeStatus.value = NativeBridgeStatus.ready;
      expect(engine.isNativeAvailable, isFalse);
      expect(engine.expand('(x+1)^2'), contains('x^2'));
    });
  });
}
