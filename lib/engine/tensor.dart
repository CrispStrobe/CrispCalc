// lib/engine/tensor.dart
//
// Rank-N tensor with symbolic-string components. SymEngine has no native
// tensor type beyond matrices, so we build a thin pure-Dart container here.
// Components stay as strings (e.g. '2', 'x', '2*y + 1') so symbolic content
// survives the trip through arithmetic operations — SymEngine can simplify
// the resulting expressions when they go back through `evaluate`.
//
// Shape conventions: `shape[0]` is the slowest-varying axis (row-major /
// "C" order). A 3-vector has shape `[3]`. A 2×3 matrix has shape `[2, 3]`.
// A rank-3 tensor with shape `[2, 2, 2]` holds 8 components.

import 'dart:math' as math;

class Tensor {
  final List<int> shape;
  final List<String> data;

  Tensor._(this.shape, this.data) {
    final expected = _productOfShape(shape);
    if (data.length != expected) {
      throw ArgumentError(
        'Tensor data length ${data.length} does not match shape '
        '$shape (expected $expected elements).',
      );
    }
  }

  /// Scalar (rank-0) tensor.
  factory Tensor.scalar(String value) => Tensor._(const [], [value]);

  /// 1-D tensor (vector).
  factory Tensor.vector(List<String> elements) {
    if (elements.isEmpty) {
      throw ArgumentError('Vector must have at least one element.');
    }
    return Tensor._([elements.length], List.of(elements));
  }

  /// 2-D tensor (matrix). Each inner list is a row.
  factory Tensor.matrix(List<List<String>> rows) {
    if (rows.isEmpty || rows.first.isEmpty) {
      throw ArgumentError('Matrix must have at least one row and column.');
    }
    final cols = rows.first.length;
    for (final r in rows) {
      if (r.length != cols) {
        throw ArgumentError('Matrix rows must all have the same length.');
      }
    }
    final flat = <String>[];
    for (final r in rows) {
      flat.addAll(r);
    }
    return Tensor._([rows.length, cols], flat);
  }

  /// General N-D tensor from a nested list. Inspects shape by descending the
  /// first element. Validates the nesting is uniform.
  factory Tensor.fromNested(dynamic nested) {
    final shape = _inferShape(nested);
    final flat = <String>[];
    _flatten(nested, flat);
    if (flat.length != _productOfShape(shape)) {
      throw ArgumentError('Nested list is jagged — non-rectangular shape.');
    }
    return Tensor._(shape, flat);
  }

  /// Fill a tensor of the given shape with a single component.
  factory Tensor.filled(List<int> shape, String value) {
    final n = _productOfShape(shape);
    return Tensor._(List.of(shape), List.filled(n, value));
  }

  int get rank => shape.length;
  int get size => data.length;

  /// Read a single component. Length of `indices` must equal `rank`.
  String getAt(List<int> indices) {
    return data[_flatIndex(indices)];
  }

  /// Returns a *new* tensor with one component replaced. Tensors are
  /// otherwise treated as immutable.
  Tensor setAt(List<int> indices, String value) {
    final next = List.of(data);
    next[_flatIndex(indices)] = value;
    return Tensor._(List.of(shape), next);
  }

  int _flatIndex(List<int> indices) {
    if (indices.length != rank) {
      throw ArgumentError(
        'Expected $rank indices, got ${indices.length}.',
      );
    }
    var idx = 0;
    for (var d = 0; d < rank; d++) {
      final i = indices[d];
      if (i < 0 || i >= shape[d]) {
        throw RangeError(
            'Index $i out of range for axis $d (size ${shape[d]}).');
      }
      idx = idx * shape[d] + i;
    }
    return idx;
  }

  Tensor operator +(Tensor other) => _elementwise(other, (a, b) => '($a + $b)');
  Tensor operator -(Tensor other) => _elementwise(other, (a, b) => '($a - $b)');

  Tensor _elementwise(Tensor other, String Function(String, String) op) {
    if (!_shapeMatches(shape, other.shape)) {
      throw ArgumentError(
        'Shape mismatch for element-wise op: $shape vs ${other.shape}.',
      );
    }
    final out = <String>[];
    for (var i = 0; i < data.length; i++) {
      out.add(op(data[i], other.data[i]));
    }
    return Tensor._(List.of(shape), out);
  }

  /// Multiply every component by `scalar` (string-symbolic).
  Tensor scale(String scalar) {
    final out = data.map((c) => '($scalar * $c)').toList();
    return Tensor._(List.of(shape), out);
  }

  /// Tensor contraction: sum over axis `axisA` of this and axis `axisB` of
  /// `other`. The sizes along the two axes must match. The result tensor has
  /// shape `(this.shape without axisA) ++ (other.shape without axisB)`.
  ///
  /// Examples:
  ///   - matrix * vector: `A.contract(1, v, 0)`
  ///   - matrix * matrix: `A.contract(1, B, 0)`
  ///   - dot product of vectors: `u.contract(0, v, 0)` (result is rank-0).
  Tensor contract(int axisA, Tensor other, int axisB) {
    if (axisA < 0 || axisA >= rank) {
      throw RangeError('axisA $axisA out of range (rank $rank).');
    }
    if (axisB < 0 || axisB >= other.rank) {
      throw RangeError('axisB $axisB out of range (rank ${other.rank}).');
    }
    if (shape[axisA] != other.shape[axisB]) {
      throw ArgumentError(
        'Contraction axes have different sizes: '
        '${shape[axisA]} vs ${other.shape[axisB]}.',
      );
    }
    final n = shape[axisA];

    final shapeA = [...shape]..removeAt(axisA);
    final shapeB = [...other.shape]..removeAt(axisB);
    final outShape = [...shapeA, ...shapeB];

    if (outShape.isEmpty) {
      // Two vectors of the same length → scalar.
      final terms = <String>[];
      for (var k = 0; k < n; k++) {
        terms.add('(${getAt([k])} * ${other.getAt([k])})');
      }
      return Tensor._(const [], [terms.join(' + ')]);
    }

    final outSize = _productOfShape(outShape);
    final out = List<String>.filled(outSize, '0');
    final shapeASize = _productOfShape(shapeA);

    String sumTerm(List<int> coordA, List<int> coordB) {
      final terms = <String>[];
      for (var k = 0; k < n; k++) {
        final ai = [...coordA]..insert(axisA, k);
        final bi = [...coordB]..insert(axisB, k);
        terms.add('(${getAt(ai)} * ${other.getAt(bi)})');
      }
      return terms.join(' + ');
    }

    for (var i = 0; i < outSize; i++) {
      // Split flat output index `i` back into (coordA, coordB).
      final aOffset =
          shapeASize == 0 ? 0 : i ~/ (outSize ~/ shapeASize.clamp(1, outSize));
      final bOffset = i %
          (shapeASize == 0
              ? outSize
              : (outSize ~/ shapeASize.clamp(1, outSize)));
      out[i] = sumTerm(
        _unflattenIndex(aOffset, shapeA),
        _unflattenIndex(bOffset, shapeB),
      );
    }
    return Tensor._(outShape, out);
  }

  /// Dot product of two vectors → scalar string.
  String dot(Tensor other) {
    if (rank != 1 || other.rank != 1) {
      throw ArgumentError('dot() needs two rank-1 tensors.');
    }
    return contract(0, other, 0).data[0];
  }

  /// Cross product of two 3-vectors → rank-1 tensor.
  Tensor cross(Tensor other) {
    if (rank != 1 || other.rank != 1) {
      throw ArgumentError('cross() needs two rank-1 tensors.');
    }
    if (shape[0] != 3 || other.shape[0] != 3) {
      throw ArgumentError('cross() requires 3-D vectors.');
    }
    final a = data;
    final b = other.data;
    return Tensor.vector([
      '((${a[1]}) * (${b[2]}) - (${a[2]}) * (${b[1]}))',
      '((${a[2]}) * (${b[0]}) - (${a[0]}) * (${b[2]}))',
      '((${a[0]}) * (${b[1]}) - (${a[1]}) * (${b[0]}))',
    ]);
  }

  /// Euclidean norm string for a rank-1 tensor: `sqrt(sum(v_i^2))`.
  String norm() {
    if (rank != 1) {
      throw ArgumentError('norm() expects a rank-1 tensor.');
    }
    final terms = data.map((c) => '($c)^2').join(' + ');
    return 'sqrt($terms)';
  }

  /// Numeric value of `norm()` if all components are real numbers, else null.
  double? numericNorm() {
    var sum = 0.0;
    for (final c in data) {
      final v = double.tryParse(c.trim());
      if (v == null) return null;
      sum += v * v;
    }
    return math.sqrt(sum);
  }

  /// Pretty-printed shape, e.g. "Tensor[2, 3, 2]: ...".
  @override
  String toString() => 'Tensor$shape${data.toString()}';

  // ---- helpers ----

  static int _productOfShape(List<int> shape) {
    var p = 1;
    for (final d in shape) {
      p *= d;
    }
    return p;
  }

  static bool _shapeMatches(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<int> _unflattenIndex(int flat, List<int> shape) {
    if (shape.isEmpty) return const [];
    final out = List<int>.filled(shape.length, 0);
    for (var d = shape.length - 1; d >= 0; d--) {
      out[d] = flat % shape[d];
      flat ~/= shape[d];
    }
    return out;
  }

  static List<int> _inferShape(dynamic nested) {
    final shape = <int>[];
    dynamic cur = nested;
    while (cur is List) {
      shape.add(cur.length);
      if (cur.isEmpty) break;
      cur = cur.first;
    }
    return shape;
  }

  static void _flatten(dynamic nested, List<String> out) {
    if (nested is List) {
      for (final c in nested) {
        _flatten(c, out);
      }
    } else {
      out.add(nested.toString());
    }
  }
}
