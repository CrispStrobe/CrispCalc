import 'package:crisp_calc/engine/tensor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('construction', () {
    test('scalar', () {
      final t = Tensor.scalar('5');
      expect(t.rank, 0);
      expect(t.shape, isEmpty);
      expect(t.data, ['5']);
    });

    test('vector', () {
      final t = Tensor.vector(['1', '2', '3']);
      expect(t.rank, 1);
      expect(t.shape, [3]);
      expect(t.data, ['1', '2', '3']);
    });

    test('matrix', () {
      final t = Tensor.matrix([
        ['1', '2'],
        ['3', '4']
      ]);
      expect(t.rank, 2);
      expect(t.shape, [2, 2]);
      expect(t.data, ['1', '2', '3', '4']);
    });

    test('matrix with mismatched row lengths throws', () {
      expect(
          () => Tensor.matrix([
                ['1', '2'],
                ['3']
              ]),
          throwsArgumentError);
    });

    test('from nested 3-D list', () {
      final t = Tensor.fromNested([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ],
      ]);
      expect(t.rank, 3);
      expect(t.shape, [2, 2, 2]);
      expect(t.data, ['1', '2', '3', '4', '5', '6', '7', '8']);
    });

    test('jagged nested list throws', () {
      expect(
        () => Tensor.fromNested([
          [1, 2],
          [3]
        ]),
        throwsArgumentError,
      );
    });

    test('filled', () {
      final t = Tensor.filled([2, 3], '0');
      expect(t.data.length, 6);
      expect(t.data.every((c) => c == '0'), isTrue);
    });
  });

  group('indexing', () {
    test('getAt on a matrix', () {
      final t = Tensor.matrix([
        ['1', '2'],
        ['3', '4']
      ]);
      expect(t.getAt([0, 0]), '1');
      expect(t.getAt([0, 1]), '2');
      expect(t.getAt([1, 0]), '3');
      expect(t.getAt([1, 1]), '4');
    });

    test('getAt on a rank-3 tensor', () {
      final t = Tensor.fromNested([
        [
          [1, 2],
          [3, 4]
        ],
        [
          [5, 6],
          [7, 8]
        ],
      ]);
      expect(t.getAt([0, 0, 0]), '1');
      expect(t.getAt([1, 1, 1]), '8');
      expect(t.getAt([1, 0, 1]), '6');
    });

    test('wrong number of indices throws', () {
      final t = Tensor.vector(['1', '2', '3']);
      expect(() => t.getAt([0, 0]), throwsArgumentError);
    });

    test('out-of-range index throws', () {
      final t = Tensor.vector(['1', '2', '3']);
      expect(() => t.getAt([5]), throwsRangeError);
    });

    test('setAt returns a new tensor (immutability)', () {
      final t = Tensor.vector(['1', '2', '3']);
      final t2 = t.setAt([1], '99');
      expect(t.getAt([1]), '2');
      expect(t2.getAt([1]), '99');
    });
  });

  group('element-wise arithmetic', () {
    test('vector + vector', () {
      final a = Tensor.vector(['1', '2', '3']);
      final b = Tensor.vector(['4', '5', '6']);
      final sum = a + b;
      expect(sum.shape, [3]);
      expect(sum.data, ['(1 + 4)', '(2 + 5)', '(3 + 6)']);
    });

    test('matrix - matrix', () {
      final a = Tensor.matrix([
        ['1', '2'],
        ['3', '4']
      ]);
      final b = Tensor.matrix([
        ['5', '6'],
        ['7', '8']
      ]);
      final diff = a - b;
      expect(diff.data, ['(1 - 5)', '(2 - 6)', '(3 - 7)', '(4 - 8)']);
    });

    test('shape mismatch throws', () {
      final a = Tensor.vector(['1', '2']);
      final b = Tensor.vector(['1', '2', '3']);
      expect(() => a + b, throwsArgumentError);
    });

    test('scalar multiplication', () {
      final v = Tensor.vector(['1', '2', '3']);
      final s = v.scale('k');
      expect(s.data, ['(k * 1)', '(k * 2)', '(k * 3)']);
    });
  });

  group('vector ops', () {
    test('dot product (numeric)', () {
      final a = Tensor.vector(['1', '2', '3']);
      final b = Tensor.vector(['4', '5', '6']);
      expect(a.dot(b), '(1 * 4) + (2 * 5) + (3 * 6)');
    });

    test('cross product of orthonormal basis: ex × ey = ez', () {
      final ex = Tensor.vector(['1', '0', '0']);
      final ey = Tensor.vector(['0', '1', '0']);
      final c = ex.cross(ey);
      expect(c.shape, [3]);
      // Components simplify to 0, 0, 1 — but we keep them as expression strings
      // until SymEngine simplifies. Just check the symbolic form is right.
      expect(c.data[0], contains('(0)'));
      expect(c.data[2], contains('(1)'));
    });

    test('norm of (3, 4) = sqrt(9 + 16)', () {
      final v = Tensor.vector(['3', '4']);
      expect(v.norm(), 'sqrt((3)^2 + (4)^2)');
    });

    test('numeric norm of (3, 4) = 5', () {
      final v = Tensor.vector(['3', '4']);
      expect(v.numericNorm(), closeTo(5, 1e-9));
    });

    test('numeric norm of symbolic vector returns null', () {
      final v = Tensor.vector(['x', '2']);
      expect(v.numericNorm(), isNull);
    });

    test('cross() rejects non-3D vectors', () {
      final a = Tensor.vector(['1', '2']);
      final b = Tensor.vector(['3', '4']);
      expect(() => a.cross(b), throwsArgumentError);
    });
  });

  group('contraction', () {
    test('two vectors → scalar (dot via contract)', () {
      final a = Tensor.vector(['1', '2', '3']);
      final b = Tensor.vector(['4', '5', '6']);
      final c = a.contract(0, b, 0);
      expect(c.rank, 0);
    });

    test('contraction with incompatible sizes throws', () {
      final a = Tensor.vector(['1', '2']);
      final b = Tensor.vector(['1', '2', '3']);
      expect(() => a.contract(0, b, 0), throwsArgumentError);
    });
  });
}
