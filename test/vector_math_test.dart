import 'package:crisp_calc/engine/vector_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preprocess — dot()', () {
    test('numeric vectors', () {
      final r = VectorMath.preprocess('dot([1, 2, 3], [4, 5, 6])');
      expect(r, '((1) * (4) + (2) * (5) + (3) * (6))');
    });

    test('symbolic vectors', () {
      final r = VectorMath.preprocess('dot([x, y], [a, b])');
      expect(r, '((x) * (a) + (y) * (b))');
    });

    test('wrong arity is left alone', () {
      final r = VectorMath.preprocess('dot([1, 2])');
      expect(r, 'dot([1, 2])');
    });

    test('length mismatch is left alone', () {
      final r = VectorMath.preprocess('dot([1, 2], [3, 4, 5])');
      expect(r, 'dot([1, 2], [3, 4, 5])');
    });
  });

  group('preprocess — cross()', () {
    test('orthonormal basis', () {
      // cross([1,0,0], [0,1,0]) — full expanded form
      final r = VectorMath.preprocess('cross([1, 0, 0], [0, 1, 0])');
      // Should be a vector literal that evaluates to [0, 0, 1] after SymEngine
      // simplifies. We only check the structure here.
      expect(r, contains('['));
      expect(r, contains(','));
    });

    test('rejects non-3D inputs', () {
      final r = VectorMath.preprocess('cross([1, 2], [3, 4])');
      expect(r, 'cross([1, 2], [3, 4])');
    });
  });

  group('preprocess — norm() and unit()', () {
    test('norm() expands to sqrt sum of squares', () {
      final r = VectorMath.preprocess('norm([3, 4])');
      expect(r, contains('sqrt'));
      expect(r, contains('(3)^2'));
      expect(r, contains('(4)^2'));
    });

    test('unit() divides each component by norm', () {
      final r = VectorMath.preprocess('unit([1, 0, 0])');
      expect(r, contains('sqrt'));
      expect(r, contains('/'));
    });
  });

  group('preprocess — passes other text through', () {
    test('plain arithmetic untouched', () {
      expect(VectorMath.preprocess('2 + 3 * 4'), '2 + 3 * 4');
    });

    test('partial-word matches do not trigger', () {
      // `dotty` is not `dot`.
      expect(VectorMath.preprocess('dotty([1,2,3])'), 'dotty([1,2,3])');
    });

    test('expression with both vector op and ordinary math', () {
      final r = VectorMath.preprocess('2 + dot([1, 2], [3, 4])');
      expect(r, '2 + ((1) * (3) + (2) * (4))');
    });
  });

  group('preprocess — nested calls', () {
    test('norm of cross product', () {
      final r = VectorMath.preprocess('norm(cross([1, 0, 0], [0, 1, 0]))');
      // Cross gets expanded to a literal, then norm wraps it in sqrt.
      expect(r, contains('sqrt'));
    });
  });
}
