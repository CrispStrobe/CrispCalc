// lib/utils/error_formatter.dart
//
// Translates the engine's raw "Error: ..." strings into friendly
// plain-language messages. Engine and bridge layers still emit
// technical detail (parse exceptions, "requires native library",
// "not implemented in SymEngine C API"); this formatter pattern-
// matches against the most common forms and replaces them with
// curated advice. Anything we don't recognize falls through as-is
// so power users keep the diagnostic detail.
//
// Applied at the UI layer (history rendering) — the engine continues
// to emit raw strings unchanged, so tests and the diagnostic
// batteries keep their original assertions.

import 'package:flutter/foundation.dart' show kIsWeb;

import '../localization/app_localizations.dart';

class EngineErrorFormatter {
  /// Returns a user-friendly version of [raw] for display, or [raw]
  /// itself when nothing matches. Only acts on strings that start
  /// with `Error:` — non-errors pass through untouched.
  static String format(String raw, AppLocalizations t) {
    if (!raw.startsWith('Error')) return raw;
    final lower = raw.toLowerCase();

    // Native library not loaded — affects most symbolic ops on
    // platforms without the bridge (Linux / Windows / Android in CI).
    if (lower.contains('requires native library')) {
      // On web the native bridge can never load — point at the app
      // instead of implying a transient platform gap.
      return kIsWeb ? t.errorNativeRequiredWeb : t.errorNativeRequired;
    }

    // Bridge integrate() is a stub in the current SymEngine build.
    if (lower.contains('not implemented in symengine c api') ||
        lower.contains('indefinite integrate() is not available')) {
      return t.errorIntegrateNotImplemented;
    }

    // Precise diagnoses from the pure-Dart parser
    // (`engineErrorForDiagnosis`). These are checked before the generic
    // parse-failure branch below because each one can name the actual
    // problem instead of listing everything it might have been.
    if (lower.contains('unbalanced parenthesis')) {
      return t.errorUnbalancedParen;
    }
    if (lower.contains('division by zero')) {
      return t.errorDivisionByZero;
    }
    final unknownFn = RegExp(r'unknown function\s+(\S+)').firstMatch(raw);
    if (unknownFn != null) {
      return t.errorUnknownFunction(unknownFn.group(1)!);
    }
    final arity =
        RegExp(r'wrong number of arguments for\s+(\S+)').firstMatch(raw);
    if (arity != null) {
      return t.errorWrongArity(arity.group(1)!);
    }

    // A bridge call that failed with nothing to say. The pure-Dart
    // parser already had its turn by this point (see
    // `CalculatorEngine.evaluate`), so all that's left is the generic
    // advice — never the raw `[object Object]`.
    if (RegExp(r'^error:\s+\w+ failed$').hasMatch(lower)) {
      return t.errorParse;
    }

    // SymEngine parser couldn't make sense of the expression.
    if (lower.contains('parse failed') ||
        lower.contains('parseerror') ||
        lower.contains('parseexception')) {
      return t.errorParse;
    }

    // The matrix evaluator's invalid-literal message.
    if (lower.contains('invalid matrix literal')) {
      return t.errorMatrixLiteral;
    }

    // Various "Invalid X() syntax" messages.
    final invalidSyntax = RegExp(r'invalid\s+([a-zA-Z/]+)\(\)\s+syntax');
    final m = invalidSyntax.firstMatch(lower);
    if (m != null) {
      return t.errorInvalidSyntax(m.group(1)!);
    }

    // gcd/lcm "requires exactly 2 arguments" — keep close to the
    // original; just add an example.
    if (lower.contains('requires exactly')) {
      return raw.replaceFirst(RegExp(r'^Error:\s*'), '');
    }

    // solve() format hint — the engine already emits a usable message;
    // strip the "Error:" prefix for friendliness.
    if (lower.contains('format is')) {
      return raw.replaceFirst(RegExp(r'^Error:\s*'), '');
    }

    // Matrix has been disposed (internal lifecycle issue).
    if (lower.contains('matrix has been disposed')) {
      return t.errorInternalMatrixDisposed;
    }

    // Anything else — strip the "Error:" prefix to feel a little less
    // hostile, but leave the technical message intact.
    return raw.replaceFirst(RegExp(r'^Error:\s*'), '⚠ ');
  }

  /// Whether [text] looks like an error result (used by the UI to
  /// pick a different color).
  static bool isError(String text) =>
      text.startsWith('Error') || text.startsWith('⚠');
}
