// lib/services/native_licenses.dart
//
// Register licenses for the *native* math stack CrispCalc bundles —
// `showLicensePage` only surfaces pub/Dart packages by default, so
// SymEngine, GMP, MPFR, MPC, and FLINT would otherwise be invisible.
//
// The text lives in `assets/licenses/SYMENGINE_STACK.txt` (declared in
// `pubspec.yaml > flutter > assets`) and is loaded via `rootBundle` and
// fed to `LicenseRegistry`. Same pattern as the sibling CrisperWeaver app.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> registerNativeLicenses() async {
  LicenseRegistry.addLicense(() async* {
    try {
      final text =
          await rootBundle.loadString('assets/licenses/SYMENGINE_STACK.txt');
      yield LicenseEntryWithLineBreaks(
        const ['SymEngine', 'GMP', 'MPFR', 'MPC', 'FLINT'],
        text,
      );
    } catch (e) {
      debugPrint('LICENSES: failed to load SYMENGINE_STACK.txt: $e');
    }
  });
}
