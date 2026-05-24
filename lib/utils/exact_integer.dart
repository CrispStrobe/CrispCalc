// lib/utils/exact_integer.dart
//
// Detects integer-shaped result strings from the engine so AppState can
// preserve their full precision (SymEngine returns the exact digits via
// GMP, but a `double.tryParse` round-trip in our display formatter
// destroys anything past 2^53). The calculator screen also uses this to
// render an "Exact integer · N digits · tap to copy" badge for large
// results that can't fit on one line.

class ExactInteger {
  /// True when [s] is an integer literal `^-?\d+$` after trimming.
  /// Empty strings, "+5", "5.0", "5e10", "Error: ..." all return false.
  static bool matches(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return false;
    var start = 0;
    if (trimmed[0] == '-') {
      if (trimmed.length == 1) return false;
      start = 1;
    }
    for (var i = start; i < trimmed.length; i++) {
      final c = trimmed.codeUnitAt(i);
      if (c < 0x30 || c > 0x39) return false;
    }
    return true;
  }

  /// Digit count of [s], not counting a leading minus sign. Returns 0
  /// if [s] isn't an exact integer.
  static int digitCount(String s) {
    if (!matches(s)) return 0;
    final t = s.trim();
    return t.startsWith('-') ? t.length - 1 : t.length;
  }

  /// Pretty truncation for display: `first…last (N digits)` when the
  /// digit count exceeds [maxLen]. Otherwise returns the trimmed
  /// string unchanged. Always preserves the leading sign.
  static String abbreviate(String s,
      {int maxLen = 60, int head = 30, int tail = 12}) {
    if (!matches(s)) return s;
    final t = s.trim();
    final sign = t.startsWith('-') ? '-' : '';
    final digits = sign.isEmpty ? t : t.substring(1);
    if (digits.length <= maxLen) return t;
    final first = digits.substring(0, head);
    final last = digits.substring(digits.length - tail);
    return '$sign$first…$last';
  }
}
