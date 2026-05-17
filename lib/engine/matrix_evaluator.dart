// lib/engine/matrix_evaluator.dart
//
// Matrix expressions ride a different code path from scalar ones. SymEngine's
// string parser doesn't recognize `Matrix([[1,2],[3,4]])` literals — feed one
// to `flutter_symengine_evaluate` and it returns "parse failed". The
// dedicated `flutter_symengine_matrix_*` FFI entry points are the only way
// in. This module routes the common matrix forms (det/inv/transpose plus the
// `+`, `-`, `*` binary ops) through those entry points and returns a
// formatted result string compatible with the rest of the engine.
//
// Scope is intentionally narrow: matrix literals on both sides, no nested
// matrix expressions inside operands. Discovered the gap during HISTORY
// round 16's end-to-end self-test (every check failed at the parse step).
// Wider support — chained matrix expressions, scalar * matrix, matrix
// substitution — can come later.

import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';

import 'calculator_engine.dart';

class MatrixEvaluator {
  /// Try to evaluate [expression] as a matrix operation. Returns the
  /// formatted result string on success, or null if [expression] doesn't
  /// look like one of the supported matrix patterns (caller should fall
  /// back to the regular scalar evaluator).
  static String? tryEvaluate(String expression, CalculatorEngine engine) {
    final s = expression.trim();
    if (!s.contains('Matrix(')) return null;

    // 1. Unary calls: det / inv / transpose / rref of Matrix(...)
    for (final op in const ['det', 'inv', 'transpose', 'rref']) {
      if (s.startsWith('$op(') && s.endsWith(')')) {
        final inner = s.substring(op.length + 1, s.length - 1).trim();
        if (_looksLikeMatrix(inner)) {
          return _applyUnary(op, inner, engine);
        }
      }
    }

    // 2. Binary ops at top level: Matrix(...) + Matrix(...) etc.
    final binary = _splitBinary(s);
    if (binary != null) {
      return _applyBinary(binary.lhs, binary.op, binary.rhs, engine);
    }

    // 3. Bare matrix literal — return its canonical string form.
    if (_looksLikeMatrix(s)) {
      final m = _buildMatrix(s, engine);
      if (m != null) return _format(m);
    }

    return null;
  }

  // === Pattern recognition =================================================

  static bool _looksLikeMatrix(String s) =>
      s.startsWith('Matrix(') && s.endsWith(')');

  /// Find a top-level `+`, `-`, or `*` between two `Matrix(...)` literals.
  /// Returns null if no such split exists. Respects nested parens/brackets
  /// so `Matrix([[1,-2],...])` doesn't get sliced on the inner minus.
  static _Binary? _splitBinary(String s) {
    var depth = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[') depth++;
      if (c == ')' || c == ']') depth--;
      if (depth != 0) continue;
      if (i == 0) continue;
      if (c == '+' || c == '-' || c == '*') {
        final lhs = s.substring(0, i).trim();
        final rhs = s.substring(i + 1).trim();
        if (_looksLikeMatrix(lhs) && _looksLikeMatrix(rhs)) {
          return _Binary(lhs, c, rhs);
        }
      }
    }
    return null;
  }

  // === Matrix literal parsing ==============================================

  /// Parses `Matrix([[a,b,...],[c,d,...]])` into a fresh native matrix.
  /// Returns null on any parse failure.
  static SymEngineMatrix? _buildMatrix(
      String literal, CalculatorEngine engine) {
    if (!_looksLikeMatrix(literal)) return null;
    final body = literal.substring('Matrix('.length, literal.length - 1).trim();
    final rows = _parseRows(body);
    if (rows == null || rows.isEmpty) return null;
    final cols = rows.first.length;
    if (rows.any((r) => r.length != cols)) return null;

    final m = engine.createMatrix(rows.length, cols);
    if (m == null) return null;
    try {
      for (var r = 0; r < rows.length; r++) {
        for (var c = 0; c < cols; c++) {
          m.set(r, c, rows[r][c].trim());
        }
      }
    } catch (_) {
      return null;
    }
    return m;
  }

  /// Splits the outer `[ ... ]` of a matrix body into per-row cell lists.
  /// `body` is expected to look like `[[1,2],[3,4]]`.
  static List<List<String>>? _parseRows(String body) {
    if (!body.startsWith('[') || !body.endsWith(']')) return null;
    final inner = body.substring(1, body.length - 1).trim();
    final rows = <List<String>>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < inner.length; i++) {
      final c = inner[i];
      if (c == '[' || c == '(') depth++;
      if (c == ']' || c == ')') depth--;
      final atEnd = i == inner.length - 1;
      final atSeparator = c == ',' && depth == 0;
      if (atSeparator || atEnd) {
        final chunk =
            inner.substring(start, atEnd ? i + 1 : i).trim();
        if (chunk.startsWith('[') && chunk.endsWith(']')) {
          rows.add(_parseCells(chunk));
        } else if (chunk.isNotEmpty) {
          // The body wasn't `[[...],[...]]` after all.
          return null;
        }
        start = i + 1;
      }
    }
    return rows.isEmpty ? null : rows;
  }

  /// Splits `[a, b, c]` into `['a', 'b', 'c']` respecting nested parens.
  static List<String> _parseCells(String row) {
    final out = <String>[];
    final inner = row.substring(1, row.length - 1);
    var depth = 0;
    var start = 0;
    for (var i = 0; i < inner.length; i++) {
      final c = inner[i];
      if (c == '(' || c == '[') depth++;
      if (c == ')' || c == ']') depth--;
      final atEnd = i == inner.length - 1;
      if ((c == ',' && depth == 0) || atEnd) {
        final cell = inner.substring(start, atEnd ? i + 1 : i).trim();
        if (cell.isNotEmpty) out.add(cell);
        start = i + 1;
      }
    }
    return out;
  }

  // === Operation routing ===================================================

  static String _applyUnary(
      String op, String matrixLit, CalculatorEngine engine) {
    final m = _buildMatrix(matrixLit, engine);
    if (m == null) return 'Error: $op invalid matrix literal';
    try {
      switch (op) {
        case 'det':
          return m.getDeterminant();
        case 'inv':
          return _format(m.inverse());
        case 'transpose':
          return _format(_transpose(m, engine));
        case 'rref':
          return _format(_rref(m, engine));
      }
    } catch (e) {
      return 'Error: $op failed: $e';
    }
    return 'Error: $op not implemented';
  }

  static String _applyBinary(
      String lhsLit, String op, String rhsLit, CalculatorEngine engine) {
    final a = _buildMatrix(lhsLit, engine);
    final b = _buildMatrix(rhsLit, engine);
    if (a == null || b == null) return 'Error: invalid matrix literal';
    try {
      switch (op) {
        case '+':
          return _format(a + b);
        case '-':
          return _format(a + _negate(b, engine));
        case '*':
          return _format(a * b);
      }
    } catch (e) {
      return 'Error: matrix $op failed: $e';
    }
    return 'Error: unsupported matrix op $op';
  }

  /// Canonical `Matrix([[a, b], [c, d]])` string. The bridge's toString
  /// returns a multi-line `[a, b]\n[c, d]\n` shape, which is hard to feed
  /// back into the engine as an expression and confuses the history view.
  static String _format(SymEngineMatrix m) {
    final rows = <String>[];
    for (var r = 0; r < m.rows; r++) {
      final cells = <String>[];
      for (var c = 0; c < m.cols; c++) {
        cells.add(m.get(r, c));
      }
      rows.add('[${cells.join(', ')}]');
    }
    return 'Matrix([${rows.join(', ')}])';
  }

  /// Element-wise negation. Bridge doesn't expose one, so we build a fresh
  /// matrix and copy `-(cell)` element-by-element.
  static SymEngineMatrix _negate(SymEngineMatrix m, CalculatorEngine engine) {
    final out = engine.createMatrix(m.rows, m.cols);
    if (out == null) {
      throw StateError('matrix negate: failed to allocate result');
    }
    for (var r = 0; r < m.rows; r++) {
      for (var c = 0; c < m.cols; c++) {
        out.set(r, c, '-(${m.get(r, c)})');
      }
    }
    return out;
  }

  /// Transpose by copying elements into a fresh matrix with swapped dims.
  /// The bridge doesn't expose a transpose entry point.
  static SymEngineMatrix _transpose(
      SymEngineMatrix m, CalculatorEngine engine) {
    final out = engine.createMatrix(m.cols, m.rows);
    if (out == null) {
      throw StateError('matrix transpose: failed to allocate result');
    }
    for (var r = 0; r < m.rows; r++) {
      for (var c = 0; c < m.cols; c++) {
        out.set(c, r, m.get(r, c));
      }
    }
    return out;
  }

  /// Reduced row echelon form via Gauss-Jordan elimination. Each elementary
  /// row operation is built as a SymEngine expression string and simplified
  /// through the bridge, so it handles rational and symbolic entries — not
  /// just floats. The algorithm: walk the columns left-to-right, find a
  /// pivot row whose entry in the current column simplifies to a non-zero
  /// expression, swap it up, scale the row so the pivot becomes 1, then
  /// eliminate that column in every other row.
  ///
  /// Symbolic non-zero detection is the soft spot: we ask SymEngine to
  /// simplify each candidate cell and treat the literal string "0" as zero.
  /// Expressions that are mathematically zero but don't simplify to "0"
  /// (rare for the algebraic-rational entries the engine produces) are
  /// treated as non-zero pivots, which is the safe direction — the result
  /// is still a valid row-reduced form, just possibly not fully canonical.
  static SymEngineMatrix _rref(SymEngineMatrix m, CalculatorEngine engine) {
    // Pull cells into a Dart 2-D array of expression strings so we can edit
    // them efficiently and only write the final shape back into a new
    // native matrix at the end.
    final rows = m.rows;
    final cols = m.cols;
    final cells = List<List<String>>.generate(
      rows,
      (r) => List<String>.generate(cols, (c) => m.get(r, c)),
    );

    var pivotRow = 0;
    for (var col = 0; col < cols && pivotRow < rows; col++) {
      // Find the first row at or below pivotRow whose entry in this column
      // simplifies to something non-zero.
      var found = -1;
      for (var r = pivotRow; r < rows; r++) {
        if (!_isZero(cells[r][col], engine)) {
          found = r;
          break;
        }
      }
      if (found == -1) continue;

      // Bring the pivot row to the top of the active submatrix.
      if (found != pivotRow) {
        final tmp = cells[pivotRow];
        cells[pivotRow] = cells[found];
        cells[found] = tmp;
      }

      // Scale the pivot row so the leading entry is 1.
      final pivot = cells[pivotRow][col];
      if (!_isOne(pivot, engine)) {
        for (var c = 0; c < cols; c++) {
          cells[pivotRow][c] =
              _simplify('(${cells[pivotRow][c]})/($pivot)', engine);
        }
      }

      // Eliminate this column in every other row.
      for (var r = 0; r < rows; r++) {
        if (r == pivotRow) continue;
        final factor = cells[r][col];
        if (_isZero(factor, engine)) continue;
        for (var c = 0; c < cols; c++) {
          cells[r][c] = _simplify(
              '(${cells[r][c]}) - ($factor)*(${cells[pivotRow][c]})', engine);
        }
      }

      pivotRow++;
    }

    final out = engine.createMatrix(rows, cols);
    if (out == null) {
      throw StateError('matrix rref: failed to allocate result');
    }
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        out.set(r, c, cells[r][c]);
      }
    }
    return out;
  }

  // === Tiny cell-arithmetic helpers ========================================

  static String _simplify(String expr, CalculatorEngine engine) {
    final result = engine.simplify(expr);
    // engine.simplify returns "Error: …" on bridge failure; in that case
    // keep the original expression — the next pass might still progress.
    if (result.startsWith('Error')) return expr;
    return result;
  }

  static bool _isZero(String expr, CalculatorEngine engine) {
    final s = _simplify(expr, engine).trim();
    if (s == '0' || s == '0.0' || s == '-0') return true;
    final n = double.tryParse(s);
    return n != null && n == 0;
  }

  static bool _isOne(String expr, CalculatorEngine engine) {
    final s = _simplify(expr, engine).trim();
    if (s == '1' || s == '1.0') return true;
    final n = double.tryParse(s);
    return n != null && n == 1.0;
  }
}

class _Binary {
  final String lhs;
  final String op;
  final String rhs;
  const _Binary(this.lhs, this.op, this.rhs);
}
