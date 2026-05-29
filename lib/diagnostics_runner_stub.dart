// Web stub for the headless diagnostic self-test.
//
// The browser has no process environment, stdout, or exit(), and the
// native bridge is unavailable anyway — so the diagnostic battery is a
// no-op on web. Selected by the conditional import in main.dart when
// dart.library.io is absent (dart2js / dart2wasm).

/// No-op on web: there is no process to inspect or exit.
void runDiagnosticsIfRequested() {}
