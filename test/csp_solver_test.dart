// test/csp_solver_test.dart
//
// Coverage for the CspSolver wrapper. Both modes (Diophantine
// enumeration + cryptarithm) are exercised against canonical inputs
// the dart_csp engine handles deterministically.

import 'package:crisp_calc/engine/csp_solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CspSolver.solveDiophantine', () {
    test('2x + 3y == 12 enumerates the 3 non-negative integer solutions',
        () async {
      final r = await CspSolver.solveDiophantine(
        variables: {'x': (min: 0, max: 10), 'y': (min: 0, max: 10)},
        constraints: ['2*x + 3*y == 12'],
      );
      expect(r.ok, isTrue, reason: 'error: ${r.error}');
      // (x=0,y=4), (x=3,y=2), (x=6,y=0)
      expect(r.solutions, hasLength(3));
      final pairs = r.solutions.map((s) => '${s['x']},${s['y']}').toSet();
      expect(pairs, equals({'0,4', '3,2', '6,0'}));
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('multiple constraints intersect', () async {
      final r = await CspSolver.solveDiophantine(
        variables: {'a': (min: 1, max: 10), 'b': (min: 1, max: 10)},
        constraints: ['a + b == 7', 'a < b'],
      );
      expect(r.ok, isTrue);
      // (1,6), (2,5), (3,4) — three pairs.
      expect(r.solutions, hasLength(3));
      for (final s in r.solutions) {
        expect(s['a']! + s['b']!, 7);
        expect(s['a']! < s['b']!, isTrue);
      }
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('infeasible problem returns ok with empty solutions list', () async {
      final r = await CspSolver.solveDiophantine(
        variables: {'x': (min: 0, max: 5)},
        constraints: ['x == 100'],
      );
      expect(r.ok, isTrue);
      expect(r.solutions, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('reversed range surfaces as a validation error', () async {
      final r = await CspSolver.solveDiophantine(
        variables: {'x': (min: 10, max: 0)},
        constraints: ['x == 5'],
      );
      expect(r.ok, isFalse);
      expect(r.error, contains('range max'));
    });

    test('empty variables map errors out', () async {
      final r = await CspSolver.solveDiophantine(
        variables: {},
        constraints: const [],
      );
      expect(r.ok, isFalse);
      expect(r.error, contains('No variables'));
    });

    test('parse failure on bogus constraint surfaces the engine error',
        () async {
      final r = await CspSolver.solveDiophantine(
        variables: {'x': (min: 0, max: 5)},
        constraints: ['this is not a constraint'],
      );
      expect(r.ok, isFalse);
      expect(r.error, contains('parse'));
    });

    test('maxSolutions caps enumeration + sets truncated flag', () async {
      // 6 + 6 = 12 candidate pairs satisfy x<y; cap at 3.
      final r = await CspSolver.solveDiophantine(
        variables: {'x': (min: 1, max: 6), 'y': (min: 1, max: 6)},
        constraints: ['x < y'],
        maxSolutions: 3,
      );
      expect(r.ok, isTrue);
      expect(r.solutions, hasLength(3));
      expect(r.truncated, isTrue);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('CspSolver.solveDsl', () {
    test('classic 3-variable example: x + y + z = 15 over 1..9 all-diff',
        () async {
      const dsl = '''
vars: x, y, z in 1..9
allDifferent(x, y, z)
x + y + z == 15
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.solutions, isNotEmpty);
      for (final s in r.solutions) {
        expect(s['x']! + s['y']! + s['z']!, 15);
        expect({s['x'], s['y'], s['z']}.length, 3);
      }
    });

    test('comments + blank lines are ignored', () async {
      const dsl = '''
# a problem
vars: a, b in 1..5

# all-different
allDifferent(a, b)

a + b == 7  # the constraint
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.solutions.length, 4);
    });

    test('rejects missing vars: line with friendly error', () async {
      final r = await CspSolver.solveDsl('x + y == 10');
      expect(r.ok, isFalse);
      expect(r.error, contains('No variables declared'));
    });

    test('rejects invalid variable name', () async {
      final r = await CspSolver.solveDsl('vars: 1bad in 1..9');
      expect(r.ok, isFalse);
      expect(r.error, contains('invalid variable name'));
    });

    test('rejects duplicate variable declaration', () async {
      final r = await CspSolver.solveDsl('''
vars: x in 1..9
vars: x in 1..9
''');
      expect(r.ok, isFalse);
      expect(r.error, contains('already declared'));
    });

    test('allDifferent with only one var is an error', () async {
      final r = await CspSolver.solveDsl('''
vars: x in 1..9
allDifferent(x)
''');
      expect(r.ok, isFalse);
    });

    test('supports coefficient-bearing linear constraints', () async {
      const dsl = '''
vars: x, y in 1..5
2*x + 3*y == 12
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.solutions, isNotEmpty);
      for (final s in r.solutions) {
        expect(2 * s['x']! + 3 * s['y']!, 12);
      }
    });
  });

  group('CspSolver.solveCryptarithm', () {
    test('SEND + MORE = MONEY finds the unique assignment', () async {
      final r = await CspSolver.solveCryptarithm('SEND + MORE = MONEY');
      expect(r.ok, isTrue, reason: 'error: ${r.error}');
      // Canonical answer: S=9 E=5 N=6 D=7 M=1 O=0 R=8 Y=2
      expect(r.assignment['S'], 9);
      expect(r.assignment['E'], 5);
      expect(r.assignment['N'], 6);
      expect(r.assignment['D'], 7);
      expect(r.assignment['M'], 1);
      expect(r.assignment['O'], 0);
      expect(r.assignment['R'], 8);
      expect(r.assignment['Y'], 2);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('lower-case input is normalized', () async {
      // AB + BA = CC reduces to 11(A+B) = 11C → A+B = C, with the
      // leading-zero + allDifferent constraints picking some valid
      // assignment (e.g. A=1, B=2, C=3).
      final r = await CspSolver.solveCryptarithm('ab + ba = cc');
      expect(r.ok, isTrue, reason: 'error: ${r.error}');
      expect(r.assignment.keys.toSet(), equals({'A', 'B', 'C'}));
      final a = r.assignment['A']!;
      final b = r.assignment['B']!;
      final c = r.assignment['C']!;
      expect(a + b, c);
      expect(a, isNot(0)); // leading letter
      expect(b, isNot(0)); // leading letter
      expect(c, isNot(0));
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('shape mismatch returns a friendly error', () async {
      final r = await CspSolver.solveCryptarithm('SEND + MORE');
      expect(r.ok, isFalse);
      expect(r.error, contains('Expected'));
    });

    test('more than 10 distinct letters rejected', () async {
      final r = await CspSolver.solveCryptarithm(
          'ABCDEF + GHIJK = LM'); // 13 distinct letters
      expect(r.ok, isFalse);
      expect(r.error, contains('distinct letters'));
    });
  });
}
