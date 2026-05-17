// lib/engine/vector_math.dart
//
// Rewrites `dot(...)`, `cross(...)`, `norm(...)`, `unit(...)` calls on
// inline vector literals into plain SymEngine arithmetic — so the user can
// type `dot([1,2,3], [4,5,6])` in the calculator and get back `32` without
// us needing to teach the C wrapper about vectors.
//
// Only inline literals like `[1, 2, 3]` are expanded here. Named vectors
// (variables holding a Matrix(...) value) are not yet inlined; the
// preprocessor falls through and SymEngine handles `dot(u, v)` itself if
// it has the means.

import 'tensor.dart';

class VectorMath {
  /// Walks `expression` and rewrites recognized vector calls. Iterates to a
  /// fixed point so nested calls like `norm(cross(a, b))` resolve fully.
  static String preprocess(String expression) {
    var s = expression;
    for (var iter = 0; iter < 8; iter++) {
      final next = _onePass(s);
      if (next == s) return s;
      s = next;
    }
    return s;
  }

  static String _onePass(String s) {
    // Vector-producing rewrites first so they expand to `[...]` literals
    // that the scalar-producing ones can then consume.
    s = _rewrite(s, 'cross', _rewriteCross);
    s = _rewrite(s, 'unit', _rewriteUnit);
    s = _rewrite(s, 'dot', _rewriteDot);
    s = _rewrite(s, 'norm', _rewriteNorm);
    return s;
  }

  /// Walks `s` looking for a function call `name(...)`. For each match, hands
  /// the raw arg list to `rewrite`. The replacement string is dropped in
  /// verbatim — scalar-returning rewrites should wrap themselves in parens;
  /// vector-returning ones leave the `[...]` literal bare so a containing
  /// call (e.g. `norm(cross(...))`) can still parse it.
  static String _rewrite(
    String s,
    String name,
    String? Function(List<String> args) rewrite,
  ) {
    final out = StringBuffer();
    var i = 0;
    while (i < s.length) {
      if (_matchesAt(s, i, name) &&
          i + name.length < s.length &&
          s[i + name.length] == '(' &&
          (i == 0 || !_isWordChar(s[i - 1]))) {
        final argsStart = i + name.length + 1;
        final argsEnd = _findMatchingParen(s, argsStart - 1);
        if (argsEnd > argsStart) {
          final argText = s.substring(argsStart, argsEnd);
          final args = _splitTopLevelArgs(argText);
          final replaced = rewrite(args);
          if (replaced != null) {
            out.write(replaced);
            i = argsEnd + 1;
            continue;
          }
        }
      }
      out.write(s[i]);
      i++;
    }
    return out.toString();
  }

  // Scalar-returning rewrites wrap themselves in parens so they compose with
  // surrounding arithmetic. Vector-returning rewrites emit a bare `[...]`
  // literal so an outer call (e.g. `norm(cross(...))`) can parse it.

  static String? _rewriteDot(List<String> args) {
    if (args.length != 2) return null;
    final a = _parseVectorLiteral(args[0]);
    final b = _parseVectorLiteral(args[1]);
    if (a == null || b == null || a.length != b.length) return null;
    final terms = <String>[];
    for (var i = 0; i < a.length; i++) {
      terms.add('(${a[i]}) * (${b[i]})');
    }
    return '(${terms.join(' + ')})';
  }

  static String? _rewriteCross(List<String> args) {
    if (args.length != 2) return null;
    final a = _parseVectorLiteral(args[0]);
    final b = _parseVectorLiteral(args[1]);
    if (a == null || b == null || a.length != 3 || b.length != 3) return null;
    final c = Tensor.vector(a).cross(Tensor.vector(b));
    return '[${c.data.join(', ')}]';
  }

  static String? _rewriteNorm(List<String> args) {
    if (args.length != 1) return null;
    final v = _parseVectorLiteral(args[0]);
    if (v == null) return null;
    return '(${Tensor.vector(v).norm()})';
  }

  static String? _rewriteUnit(List<String> args) {
    if (args.length != 1) return null;
    final v = _parseVectorLiteral(args[0]);
    if (v == null) return null;
    final t = Tensor.vector(v);
    final n = t.norm();
    return '[${v.map((c) => '($c) / ($n)').join(', ')}]';
  }

  /// `[1, 2, 3]` → `['1', '2', '3']`. `[1, 2; 3, 4]` (matrix) → null.
  /// Whitespace around components is trimmed. Components may be arbitrary
  /// sub-expressions provided they don't contain a top-level semicolon.
  static List<String>? _parseVectorLiteral(String text) {
    final t = text.trim();
    if (!t.startsWith('[') || !t.endsWith(']')) return null;
    final inner = t.substring(1, t.length - 1).trim();
    if (inner.contains(';')) return null;
    if (inner.isEmpty) return null;
    return _splitTopLevelArgs(inner);
  }

  /// Split on top-level commas (depth-0). Brackets count as openers too so
  /// nested vectors work.
  static List<String> _splitTopLevelArgs(String s) {
    final out = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[' || c == '{') depth++;
      if (c == ')' || c == ']' || c == '}') depth--;
      if (c == ',' && depth == 0) {
        out.add(s.substring(start, i).trim());
        start = i + 1;
      }
    }
    out.add(s.substring(start).trim());
    return out;
  }

  static int _findMatchingParen(String s, int openIndex) {
    if (s[openIndex] != '(') return -1;
    var depth = 0;
    for (var i = openIndex; i < s.length; i++) {
      if (s[i] == '(') depth++;
      if (s[i] == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  static bool _matchesAt(String s, int i, String name) {
    if (i + name.length > s.length) return false;
    for (var k = 0; k < name.length; k++) {
      if (s[i + k] != name[k]) return false;
    }
    return true;
  }

  static bool _isWordChar(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 0x30 && code <= 0x39) || // 0–9
        (code >= 0x41 && code <= 0x5A) || // A–Z
        (code >= 0x61 && code <= 0x7A) || // a–z
        c == '_';
  }
}
