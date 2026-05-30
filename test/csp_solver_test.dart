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

  // Pedagogy gallery additions (PLAN P-CSP: map coloring / magic square /
  // set partitioning). These lock the DSL programs shipped as gallery
  // entries in `constraints_screen.dart`; the strings are kept in sync by
  // hand (the gallery list is private to the screen state).
  group('CspSolver.solveDsl — pedagogy gallery', () {
    test('Australia map coloring is 3-colorable and respects adjacency',
        () async {
      const dsl = '''
vars: wa, nt, sa, q, nsw, v, t in 1..3
wa != nt
wa != sa
nt != sa
nt != q
sa != q
sa != nsw
sa != v
q != nsw
nsw != v
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.solutions, isNotEmpty);
      final s = r.solutions.first;
      // Every declared adjacency must differ.
      const edges = [
        ['wa', 'nt'],
        ['wa', 'sa'],
        ['nt', 'sa'],
        ['nt', 'q'],
        ['sa', 'q'],
        ['sa', 'nsw'],
        ['sa', 'v'],
        ['q', 'nsw'],
        ['nsw', 'v'],
      ];
      for (final e in edges) {
        expect(s[e[0]], isNot(equals(s[e[1]])),
            reason: '${e[0]} and ${e[1]} share a color');
      }
      // Only three colors are used at most.
      expect(s.values.every((c) => c >= 1 && c <= 3), isTrue);
    });

    test('4×4 magic square: 16 distinct values, every line sums to 34',
        () async {
      const dsl = '''
vars: a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p in 1..16
allDifferent(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p)
a + b + c + d == 34
e + f + g + h == 34
i + j + k + l == 34
m + n + o + p == 34
a + e + i + m == 34
b + f + j + n == 34
c + g + k + o == 34
d + h + l + p == 34
a + f + k + p == 34
d + g + j + m == 34
''';
      final r = await CspSolver.solveDsl(dsl, maxSolutions: 1);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.solutions, isNotEmpty);
      final s = r.solutions.first;
      // A permutation of 1..16.
      expect(s.values.toSet(), {for (var x = 1; x <= 16; x++) x});
      const lines = [
        ['a', 'b', 'c', 'd'],
        ['e', 'f', 'g', 'h'],
        ['i', 'j', 'k', 'l'],
        ['m', 'n', 'o', 'p'],
        ['a', 'e', 'i', 'm'],
        ['b', 'f', 'j', 'n'],
        ['c', 'g', 'k', 'o'],
        ['d', 'h', 'l', 'p'],
        ['a', 'f', 'k', 'p'],
        ['d', 'g', 'j', 'm'],
      ];
      for (final line in lines) {
        expect(line.fold<int>(0, (sum, key) => sum + s[key]!), 34);
      }
    });

    test('equal-sum split: selected subset and complement both sum to 8',
        () async {
      const weights = {
        'b1': 4,
        'b2': 3,
        'b3': 2,
        'b4': 3,
        'b5': 2,
        'b6': 2,
      };
      const dsl = '''
vars: b1, b2, b3, b4, b5, b6 in 0..1
4*b1 + 3*b2 + 2*b3 + 3*b4 + 2*b5 + 2*b6 == 8
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.solutions, isNotEmpty);
      const total = 16;
      for (final s in r.solutions) {
        var groupA = 0;
        weights.forEach((name, w) {
          if (s[name] == 1) groupA += w;
        });
        expect(groupA, 8);
        expect(total - groupA, 8); // complement is the equal-sum partner
      }
    });
  });

  // Operations-research optimization gallery (PLAN P-CSP "Optimization
  // tab" item, shipped as DSL gallery entries — minimize/maximize already
  // exist in the DSL). Locks the proven optima for each program.
  group('CspSolver.solveDsl — optimization gallery', () {
    test('0/1 knapsack maximizes value within the weight cap', () async {
      const dsl = '''
vars: x1, x2, x3, x4 in 0..1
2*x1 + 3*x2 + 4*x3 + 5*x4 <= 5
maximize 3*x1 + 4*x2 + 5*x3 + 6*x4
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.objective, 7); // items 1+2: weight 5, value 7
      final s = r.solutions.first;
      const weights = [2, 3, 4, 5];
      var totalWeight = 0;
      for (var i = 0; i < 4; i++) {
        totalWeight += weights[i] * s['x${i + 1}']!;
      }
      expect(totalWeight, lessThanOrEqualTo(5));
    });

    test('production planning maximizes profit under both resource caps',
        () async {
      const dsl = '''
vars: a, b in 0..10
2*a + b <= 10
a + 3*b <= 15
maximize 3*a + 5*b
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.objective, 29); // a=3, b=4
      final s = r.solutions.first;
      expect(2 * s['a']! + s['b']!, lessThanOrEqualTo(10));
      expect(s['a']! + 3 * s['b']!, lessThanOrEqualTo(15));
      expect(3 * s['a']! + 5 * s['b']!, 29);
    });

    test('assignment problem minimizes total cost with a valid permutation',
        () async {
      const dsl = '''
vars: x11, x12, x13, x21, x22, x23, x31, x32, x33 in 0..1
x11 + x12 + x13 == 1
x21 + x22 + x23 == 1
x31 + x32 + x33 == 1
x11 + x21 + x31 == 1
x12 + x22 + x32 == 1
x13 + x23 + x33 == 1
minimize 9*x11 + 2*x12 + 7*x13 + 6*x21 + 4*x22 + 3*x23 + 5*x31 + 8*x32 + 1*x33
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.objective, 9); // w1→t2, w2→t1, w3→t3
      final s = r.solutions.first;
      // Exactly one assignment per worker and per task.
      for (var i = 1; i <= 3; i++) {
        expect(
            [for (var j = 1; j <= 3; j++) s['x$i$j']!].reduce((a, b) => a + b),
            1);
        expect(
            [for (var w = 1; w <= 3; w++) s['x$w$i']!].reduce((a, b) => a + b),
            1);
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

    test(
        'round 84: multiple cumulative overlays compose — RCPSP-style '
        'crew + equipment scheduling', () async {
      // Four tasks share two renewable resources (crew + equip,
      // each capacity 3). s2 + s3 together demand equip = 4 > 3
      // so they cannot overlap on equipment; that constraint is
      // binding and produces makespan = 6 as the optimum.
      const dsl = '''
vars: s1, s2, s3, s4 in 0..6
vars: makespan in 0..6
cumulative(s1=3@2, s2=4@1, s3=2@2, s4=3@1; capacity=3)
cumulative(s1=3@1, s2=4@2, s3=2@2, s4=3@1; capacity=3)
s1 + 3 <= makespan
s2 + 4 <= makespan
s3 + 2 <= makespan
s4 + 3 <= makespan
minimize makespan
''';
      final r = await CspSolver.solveDsl(dsl);
      expect(r.ok, isTrue, reason: r.error);
      expect(r.objective, 6);
      expect(r.solutions, hasLength(1));
      final s = r.solutions.first;
      // Verify both resources stay within capacity at every t.
      bool capacityOk(List<int> demands, int capacity) {
        for (var t = 0; t < 7; t++) {
          var load = 0;
          // (s_i, dur_i, dem_i) — aligned with task list above.
          final tasks = [
            (s['s1']!, 3, demands[0]),
            (s['s2']!, 4, demands[1]),
            (s['s3']!, 2, demands[2]),
            (s['s4']!, 3, demands[3]),
          ];
          for (final t1 in tasks) {
            if (t >= t1.$1 && t < t1.$1 + t1.$2) load += t1.$3;
          }
          if (load > capacity) return false;
        }
        return true;
      }

      expect(capacityOk([2, 1, 2, 1], 3), isTrue,
          reason: 'crew capacity violated');
      expect(capacityOk([1, 2, 2, 1], 3), isTrue,
          reason: 'equipment capacity violated');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test(
        'round 84: two cumulative overlays are independently enforced '
        '(over-capacity on either is infeasible)', () async {
      // Two tasks with combined demand 4 > 3 on the second
      // resource. The first overlay is trivially satisfiable;
      // the second forces sequential execution. With only 4
      // time units available, that's infeasible.
      const dsl = '''
vars: s1, s2 in 0..3
cumulative(s1=2@1, s2=2@1; capacity=3)
cumulative(s1=2@2, s2=2@2; capacity=3)
''';
      final r = await CspSolver.solveDsl(dsl, maxSolutions: 200);
      expect(r.ok, isTrue, reason: r.error);
      // Every returned (s1, s2) must keep the SECOND overlay
      // within capacity at every t — i.e., not overlap.
      for (final s in r.solutions) {
        final s1 = s['s1']!, s2 = s['s2']!;
        expect(s1 + 2 <= s2 || s2 + 2 <= s1, isTrue,
            reason: 'overlap violates equip capacity: s1=$s1 s2=$s2');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
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

  // -----------------------------------------------------------------
  // Round D / Gantt — ganttTasks + ganttCapacity threading
  // -----------------------------------------------------------------

  group('DiophantineResult.ganttTasks — schedule metadata', () {
    test('non-scheduling Diophantine: ganttTasks empty', () async {
      final r = await CspSolver.solveDiophantine(
        variables: {
          'x': (min: 0, max: 10),
          'y': (min: 0, max: 10),
        },
        constraints: ['x + y == 7'],
      );
      expect(r.ok, isTrue);
      expect(r.ganttTasks, isEmpty);
      expect(r.ganttCapacity, isNull);
    });

    test('DSL noOverlap: ganttTasks populated with durations', () async {
      final r = await CspSolver.solveDsl('''
vars: s1, s2, s3 in 0..10
noOverlap(s1=4, s2=3, s3=2)
''');
      expect(r.ok, isTrue);
      expect(r.ganttTasks.length, 3);
      expect(r.ganttTasks[0].startVar, 's1');
      expect(r.ganttTasks[0].duration, 4);
      expect(r.ganttTasks[0].demand, isNull);
      expect(r.ganttTasks.every((t) => t.groupIndex == 0), isTrue);
      expect(r.ganttCapacity, isNull);
    });

    test('DSL cumulative: demand + capacity surfaced', () async {
      final r = await CspSolver.solveDsl('''
vars: s1, s2, s3 in 0..10
cumulative(s1=2@2, s2=3@1, s3=4@1; capacity=2)
''');
      expect(r.ok, isTrue);
      expect(r.ganttTasks.length, 3);
      expect(r.ganttTasks[0].demand, 2);
      expect(r.ganttTasks[1].demand, 1);
      expect(r.ganttTasks[2].demand, 1);
      expect(r.ganttCapacity, 2);
    });

    test('mixed noOverlap + cumulative get distinct group indices', () async {
      final r = await CspSolver.solveDsl('''
vars: a1, a2, b1, b2 in 0..20
noOverlap(a1=3, a2=4)
cumulative(b1=2@2, b2=3@1; capacity=2)
''');
      expect(r.ok, isTrue);
      expect(r.ganttTasks.length, 4);
      expect(r.ganttTasks[0].groupIndex, 0);
      expect(r.ganttTasks[1].groupIndex, 0);
      expect(r.ganttTasks[2].groupIndex, 1);
      expect(r.ganttTasks[3].groupIndex, 1);
      expect(r.ganttCapacity, 2);
    });

    test('optimization result also carries ganttTasks', () async {
      final r = await CspSolver.solveDsl('''
vars: s1, s2 in 0..10
vars: makespan in 0..10
noOverlap(s1=3, s2=4)
s1 + 3 <= makespan
s2 + 4 <= makespan
minimize makespan
''');
      expect(r.ok, isTrue);
      expect(r.objective, isNotNull);
      expect(r.ganttTasks.length, 2);
      expect(r.ganttTasks[0].duration, 3);
      expect(r.ganttTasks[1].duration, 4);
    });
  });
}
