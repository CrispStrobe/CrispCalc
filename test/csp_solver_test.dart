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

  group('CspSolver.solveDsl — Round 74 optimization', () {
    test('minimize returns the proven optimum + its objective value', () async {
      // Pay 17 cents with the fewest coins drawn from {1, 5, 10}.
      // Optimum: one 10 + one 5 + two 1s = four coins, objective = 4.
      const dsl = '''
vars: pennies in 0..17
vars: nickels in 0..3
vars: dimes in 0..1
pennies + 5*nickels + 10*dimes == 17
minimize pennies + nickels + dimes
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.objective, 4);
      expect(r.solutions, hasLength(1));
      final s = r.solutions.first;
      expect(s['pennies']! + 5 * s['nickels']! + 10 * s['dimes']!, 17);
      expect(s['pennies']! + s['nickels']! + s['dimes']!, 4);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('maximize returns the proven optimum', () async {
      // Maximize 3*x + 2*y subject to x + y <= 10, x,y in 0..10.
      // Optimum is x=10, y=0 → 30.
      const dsl = '''
vars: x, y in 0..10
x + y <= 10
maximize 3*x + 2*y
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.objective, 30);
      expect(r.solutions, hasLength(1));
      expect(r.solutions.first['x'], 10);
      expect(r.solutions.first['y'], 0);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('two objective directives in one program is rejected', () async {
      const dsl = '''
vars: x in 0..5
minimize x
maximize x
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('only one minimize/maximize'));
    });

    test('infeasible optimization returns a clear error', () async {
      const dsl = '''
vars: x in 1..5
x == 7
minimize x
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('No assignment'));
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('non-linear objective expression is rejected at parse time', () async {
      const dsl = '''
vars: x, y in 1..5
minimize x*y
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      // Either parse error or unknown-variable error — both are fine
      // as long as it doesn't pass through silently.
      expect(r.error, isNotNull);
    });

    test('objective referencing undeclared variable is rejected', () async {
      const dsl = '''
vars: x in 1..5
minimize x + z
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
    });

    test(
        'enumeration mode (no objective) keeps the old behaviour — '
        'objective is null', () async {
      const dsl = '''
vars: x, y in 1..5
x + y == 6
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue);
      expect(r.objective, isNull);
      expect(r.solutions, isNotEmpty);
    });
  });

  group('CspSolver.solveDsl — Round 77 noOverlap', () {
    test(
        'noOverlap enumerates only the schedules whose tasks do not '
        'overlap', () async {
      // Three tasks of durations 4, 3, 2 in a 0..8 horizon. Every
      // returned (s1, s2, s3) must satisfy pairwise disjointness of
      // [s, s+d).
      const dsl = '''
vars: s1, s2, s3 in 0..8
noOverlap(s1=4, s2=3, s3=2)
''';
      final r = await CspSolver.solveDsl(dsl, maxSolutions: 200);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.solutions, isNotEmpty);
      for (final s in r.solutions) {
        // Intervals: t1=[s1,s1+4), t2=[s2,s2+3), t3=[s3,s3+2).
        final s1 = s['s1']!, s2 = s['s2']!, s3 = s['s3']!;
        bool nonOverlap(int a, int aLen, int b, int bLen) =>
            a + aLen <= b || b + bLen <= a;
        expect(nonOverlap(s1, 4, s2, 3), isTrue,
            reason: 's1=$s1 d=4 overlaps s2=$s2 d=3');
        expect(nonOverlap(s1, 4, s3, 2), isTrue,
            reason: 's1=$s1 d=4 overlaps s3=$s3 d=2');
        expect(nonOverlap(s2, 3, s3, 2), isTrue,
            reason: 's2=$s2 d=3 overlaps s3=$s3 d=2');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test(
        'noOverlap + minimize makespan returns the proven optimum '
        '(sum of durations on a single machine)', () async {
      // Total work = 4+3+2 = 9. With a single machine and no idle,
      // the makespan optimum is exactly 9.
      // Round 78: the linear-parser now accepts expressions on both
      // sides of the comparator, so `s + d <= makespan` is the
      // natural form (rewritten internally to `s - makespan <= -d`).
      const dsl = '''
vars: s1, s2, s3 in 0..9
vars: makespan in 0..9
noOverlap(s1=4, s2=3, s3=2)
s1 + 4 <= makespan
s2 + 3 <= makespan
s3 + 2 <= makespan
minimize makespan
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.objective, 9);
      expect(r.solutions, hasLength(1));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('noOverlap referencing an undeclared start var is rejected', () async {
      const dsl = '''
vars: s1 in 0..5
noOverlap(s1=2, s9=3)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('undeclared'));
    });

    test('noOverlap with malformed pair is rejected', () async {
      const dsl = '''
vars: s1, s2 in 0..5
noOverlap(s1=2, s2)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('expected'));
    });

    test('noOverlap with empty body is rejected', () async {
      const dsl = '''
vars: s1 in 0..5
noOverlap()
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
    });

    test('negative duration is rejected', () async {
      const dsl = '''
vars: s1, s2 in 0..5
noOverlap(s1=2, s2=-1)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('non-negative'));
    });
  });

  group('CspSolver.solveDsl — Round 78 linear parser (both sides)', () {
    test(
        'x + 1 == y is rewritten to (x - y == -1) and finds the right '
        'solutions', () async {
      const dsl = '''
vars: x, y in 0..5
x + 1 == y
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      // Solutions: (0,1), (1,2), (2,3), (3,4), (4,5)
      expect(r.solutions, hasLength(5));
      for (final s in r.solutions) {
        expect(s['x']! + 1, s['y']);
      }
    });

    test('mixed-side linear inequality: x + y <= z + 1', () async {
      const dsl = '''
vars: x, y, z in 0..3
x + y <= z + 1
''';
      final r = await CspSolver.solveDsl(dsl, maxSolutions: 200);
      expect(r.ok, isTrue, reason: r.error);
      for (final s in r.solutions) {
        expect(s['x']! + s['y']! <= s['z']! + 1, isTrue);
      }
    });

    test(
        'objective with a constant offset: minimize x + 100 reports '
        'the shifted optimum', () async {
      const dsl = '''
vars: x in 0..10
x >= 3
minimize x + 100
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      // Optimum: x=3, objective = 3+100 = 103.
      expect(r.objective, 103);
      expect(r.solutions.first['x'], 3);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test(
        'scheduling: natural form `s + d <= makespan` round-trips to '
        'optimum makespan', () async {
      // Same problem as round 77 but written in the natural shape
      // that round-77 couldn't parse before this round landed.
      const dsl = '''
vars: s1, s2, s3 in 0..9
vars: makespan in 0..9
noOverlap(s1=4, s2=3, s3=2)
s1 + 4 <= makespan
s2 + 3 <= makespan
s3 + 2 <= makespan
minimize makespan
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.objective, 9);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('constant-only constraints still fall through to the string parser',
        () async {
      // `5 == 5` has no variables — _tryParseLinear returns null,
      // dart_csp's string parser handles it (or rejects). What we
      // care about: solveDsl shouldn't crash trying to call
      // addLinearEquals with empty vars.
      const dsl = '''
vars: x in 0..3
5 == 5
''';
      final r = await CspSolver.solveDsl(dsl);
      // Either ok with all 4 solutions OR a clean failure — but not
      // an uncaught crash.
      expect(r.solutions.isEmpty || r.solutions.length == 4, isTrue);
    });
  });

  group('CspSolver.solveDsl — Round 80 cumulative', () {
    // Soundness check used in every enumeration assertion: at every
    // integer time t in [0, horizon), the sum of demands across tasks
    // whose half-open interval [s_i, s_i + d_i) covers t must not
    // exceed capacity.
    bool capacityRespected(
      List<int> starts,
      List<int> durations,
      List<int> demands,
      int capacity,
      int horizon,
    ) {
      for (var t = 0; t < horizon; t++) {
        var load = 0;
        for (var i = 0; i < starts.length; i++) {
          if (t >= starts[i] && t < starts[i] + durations[i]) {
            load += demands[i];
          }
        }
        if (load > capacity) return false;
      }
      return true;
    }

    test('capacity=1 with unit demands degenerates to noOverlap', () async {
      // Same shape as the round-77 noOverlap test but routed through
      // the cumulative path — every returned schedule must still be
      // pairwise disjoint.
      const dsl = '''
vars: s1, s2, s3 in 0..8
cumulative(s1=4@1, s2=3@1, s3=2@1; capacity=1)
''';
      final r = await CspSolver.solveDsl(dsl, maxSolutions: 200);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.solutions, isNotEmpty);
      for (final s in r.solutions) {
        final s1 = s['s1']!, s2 = s['s2']!, s3 = s['s3']!;
        expect(
          capacityRespected([s1, s2, s3], [4, 3, 2], [1, 1, 1], 1, 9),
          isTrue,
          reason: 'over capacity at some t: s1=$s1 s2=$s2 s3=$s3',
        );
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('cumulative + minimize makespan finds the proven optimum', () async {
      // Three tasks on a capacity-2 resource. Total work = 2·2 + 3·1
      // + 4·1 = 11, lower bound ⌈11/2⌉ = 6. The schedule s1=4, s2=0,
      // s3=0 (s2+s3 parallel for 3, s3 alone for 1, then s1) achieves
      // makespan 6.
      const dsl = '''
vars: s1, s2, s3 in 0..6
vars: makespan in 0..6
cumulative(s1=2@2, s2=3@1, s3=4@1; capacity=2)
s1 + 2 <= makespan
s2 + 3 <= makespan
s3 + 4 <= makespan
minimize makespan
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.objective, 6);
      expect(r.solutions, hasLength(1));
      final s = r.solutions.first;
      expect(
        capacityRespected(
          [s['s1']!, s['s2']!, s['s3']!],
          [2, 3, 4],
          [2, 1, 1],
          2,
          7,
        ),
        isTrue,
        reason: 'optimal schedule exceeds capacity at some t',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('demand exceeding capacity makes the program infeasible', () async {
      // Single task with demand 3 on a capacity-2 resource: trivially
      // infeasible at every time inside the task interval.
      const dsl = '''
vars: s1 in 0..5
cumulative(s1=2@3; capacity=2)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.solutions, isEmpty);
    });

    test('cumulative referencing an undeclared start var is rejected',
        () async {
      const dsl = '''
vars: s1 in 0..5
cumulative(s1=2@1, s9=3@1; capacity=2)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('undeclared'));
    });

    test('cumulative with malformed pair is rejected', () async {
      const dsl = '''
vars: s1, s2 in 0..5
cumulative(s1=2@1, s2=3; capacity=2)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('name=duration@demand'));
    });

    test('cumulative without capacity clause is rejected', () async {
      const dsl = '''
vars: s1, s2 in 0..5
cumulative(s1=2@1, s2=3@1)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('capacity'));
    });

    test('negative demand is rejected', () async {
      const dsl = '''
vars: s1 in 0..5
cumulative(s1=2@-1; capacity=2)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('non-negative'));
    });

    test('negative capacity is rejected', () async {
      const dsl = '''
vars: s1 in 0..5
cumulative(s1=2@1; capacity=-1)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('non-negative'));
    });

    test('empty task list is rejected', () async {
      const dsl = '''
vars: s1 in 0..5
cumulative(; capacity=2)
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isFalse);
      expect(r.error, contains('at least one task'));
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
