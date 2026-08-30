// test_driver/integration_test.dart
//
// Driver for `flutter drive`, which is how the `integration_test/`
// suites get to run in a real browser (`-d web-server
// --browser-name=chrome`) with the SymEngine WASM module actually
// loaded. `flutter test` cannot substitute: the headless VM has no CAS
// bridge, so every expression quietly takes the pure-Dart path and the
// web-only failures never appear.
//
// Requires a chromedriver matching the installed Chrome:
//   chromedriver --port=4444 &
//
// When a test sets `binding.reportData`, it lands in
// `build/probe_report.json` — useful when adding a case and you want to
// see what the browser actually produced rather than just pass/fail.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      responseDataCallback: (Map<String, dynamic>? data) async {
        if (data == null) return;
        final out = File('build/probe_report.json');
        await out.parent.create(recursive: true);
        await out
            .writeAsString(const JsonEncoder.withIndent('  ').convert(data));
        stdout.writeln('Wrote build/probe_report.json');
      },
    );
