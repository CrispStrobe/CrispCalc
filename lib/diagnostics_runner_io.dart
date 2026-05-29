// Native (dart:io) implementation of the headless diagnostic self-test.
//
// Invoked with CRISPCALC_DIAGNOSTIC=matrix|steps on a desktop binary: it
// runs the matrix / step battery against the native bridge, prints
// PASS/FAIL lines, and exits with a non-zero code on any failure (so CI
// can assert on it). Selected by the conditional import in main.dart on
// platforms that have dart:io; the web build gets the no-op stub.

import 'dart:io';

import 'engine/calculator_engine.dart';
import 'engine/matrix_diagnostics.dart';
import 'engine/step_diagnostics.dart';

/// Runs the diagnostic battery if CRISPCALC_DIAGNOSTIC is set on a
/// desktop platform, then exits the process. Returns normally (a no-op)
/// otherwise. Never returns on web — the stub variant handles that.
void runDiagnosticsIfRequested() {
  final diag = Platform.environment['CRISPCALC_DIAGNOSTIC'];
  if (!(Platform.isMacOS || Platform.isLinux || Platform.isWindows) ||
      diag == null) {
    return;
  }
  if (diag == 'matrix') {
    final results = MatrixDiagnostics.run(CalculatorEngine());
    var anyFailed = false;
    for (final r in results) {
      stdout.writeln('${r.passed ? "PASS" : "FAIL"}  ${r.name}');
      stdout.writeln('  expr:     ${r.expression}');
      stdout.writeln('  expected: ${r.expected}');
      stdout.writeln('  actual:   ${r.actual}');
      if (!r.passed) anyFailed = true;
    }
    final passed = results.where((r) => r.passed).length;
    stdout.writeln('---');
    stdout.writeln('$passed of ${results.length} checks passed');
    exit(anyFailed ? 1 : 0);
  }
  if (diag == 'steps') {
    final results = StepDiagnostics.run(CalculatorEngine());
    var anyFailed = false;
    for (final r in results) {
      stdout.writeln(
          '${r.passed ? "PASS" : "FAIL"}  [${r.operation}]  ${r.name}');
      stdout.writeln('  expr:     ${r.expression}');
      stdout.writeln('  expected: ${r.expected}');
      stdout.writeln('  actual:   ${r.actual}');
      if (!r.passed) anyFailed = true;
    }
    final passed = results.where((r) => r.passed).length;
    stdout.writeln('---');
    stdout.writeln('$passed of ${results.length} checks passed');
    exit(anyFailed ? 1 : 0);
  }
}
