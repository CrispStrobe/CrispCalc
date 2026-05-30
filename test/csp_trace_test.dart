// test/csp_trace_test.dart
//
// Round F — propagation step-trace (CspSolver.traceDsl), the engine
// half of the AC-3 visualizer. Leverages dart_csp 2.2.0's
// PropagationTrace API (web-compat pin 3212d85). We assert on the
// *structure* of the projected trace and on the faithfulness of the
// per-step domain snapshots — the property the visualizer relies on:
//
//   * every step carries a full domain snapshot for every variable;
//   * a decision pins its variable to a singleton in that snapshot;
//   * a prune's snapshot domain for the pruned variable equals its
//     reported domainAfter;
//   * a backtrack restores domains (no variable left empty after it);
//   * the terminal solution snapshot is all-singleton and matches the
//     reported assignment.

import 'package:crisp_calc/engine/csp_solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('traceDsl — happy path (3-coloring, satisfiable)', () {
    late CspTraceResult r;

    setUp(() async {
      // K3 over 3 colors: a≠b, a≠c, b≠c. Solvable; exercises
      // decision + prune + solution but no backtracking.
      r = await CspSolver.traceDsl('''vars: a, b, c in 1..3
a != b
a != c
b != c''');
    });

    test('builds a real trace that ends solved', () {
      expect(r.ok, isTrue);
      expect(r.unsupported, isFalse);
      expect(r.solved, isTrue);
      expect(r.solution, isNotNull);
      expect(r.steps, isNotEmpty);
      expect(r.truncated, isFalse);
      expect(r.objectiveIgnored, isFalse);
    });

    test('declared variables + initial domains are exposed', () {
      expect(r.variables, ['a', 'b', 'c']);
      expect(r.initialDomains['a'], [1, 2, 3]);
      expect(r.initialDomains['b'], [1, 2, 3]);
      expect(r.initialDomains['c'], [1, 2, 3]);
    });

    test('first step is a decision pinning a variable', () {
      final first = r.steps.first;
      expect(first.kind, CspTraceStepKind.decision);
      expect(first.variable, isNotNull);
      expect(first.value, isNotNull);
      // The decided variable is a singleton in the snapshot.
      expect(first.domains[first.variable!], [first.value]);
    });

    test('every step snapshots every variable', () {
      for (final s in r.steps) {
        expect(s.domains.keys.toSet(), {'a', 'b', 'c'});
      }
    });

    test('prune snapshot for the pruned var equals its domainAfter', () {
      final prunes =
          r.steps.where((s) => s.kind == CspTraceStepKind.prune).toList();
      expect(prunes, isNotEmpty);
      for (final p in prunes) {
        expect(p.domains[p.variable!], p.domainAfter);
        // The removed value is gone from the snapshot.
        for (final removed in p.removedValues) {
          expect(p.domains[p.variable!], isNot(contains(removed)));
        }
        // A prune labels its cause with the originating constraint.
        expect(p.causeKind, isNotNull);
      }
    });

    test('terminal solution snapshot is all-singleton and consistent', () {
      final sol = r.steps.lastWhere((s) => s.kind == CspTraceStepKind.solution);
      expect(sol.assignment, r.solution);
      for (final v in r.variables) {
        expect(sol.domains[v], [r.solution![v]]);
      }
      // It is an actual proper 3-coloring.
      final a = r.solution!['a'], b = r.solution!['b'], c = r.solution!['c'];
      expect(a, isNot(b));
      expect(a, isNot(c));
      expect(b, isNot(c));
    });
  });

  group('traceDsl — backtracking (K4 over 3 colors, unsatisfiable)', () {
    late CspTraceResult r;

    setUp(() async {
      r = await CspSolver.traceDsl('''vars: a, b, c, d in 1..3
a != b
a != c
a != d
b != c
b != d
c != d''');
    });

    test('proves unsatisfiable with no solution', () {
      expect(r.ok, isTrue);
      expect(r.solved, isFalse);
      expect(r.solution, isNull);
    });

    test('the trace contains wipeouts and backtracks', () {
      expect(r.steps.any((s) => s.kind == CspTraceStepKind.wipeout), isTrue);
      expect(r.steps.any((s) => s.kind == CspTraceStepKind.backtrack), isTrue);
    });

    test('a wipeout snapshot empties exactly its variable', () {
      final w = r.steps.firstWhere((s) => s.kind == CspTraceStepKind.wipeout);
      expect(w.domains[w.variable!], isEmpty);
      expect(w.domainAfter, isEmpty);
    });

    test('a backtrack restores domains — no variable is left empty', () {
      final backtracks =
          r.steps.where((s) => s.kind == CspTraceStepKind.backtrack);
      expect(backtracks, isNotEmpty);
      for (final bt in backtracks) {
        for (final v in r.variables) {
          expect(bt.domains[v], isNotEmpty,
              reason: 'after backtrack #${bt.seq}, $v should be restored');
        }
      }
    });

    test('every snapshot domain is a subset of the declared domain', () {
      for (final s in r.steps) {
        for (final v in r.variables) {
          final dom = s.domains[v]!;
          expect(dom.toSet().difference(r.initialDomains[v]!.toSet()), isEmpty,
              reason: 'step #${s.seq}: $v domain escaped its declared range');
        }
      }
    });
  });

  group('traceDsl — edge cases', () {
    test('variable-less program fails gracefully, not a crash', () async {
      final r = await CspSolver.traceDsl('# just a comment\n');
      expect(r.ok, isFalse);
      expect(r.error, isNotNull);
      expect(r.steps, isEmpty);
    });

    test('parse errors surface as a failure', () async {
      final r = await CspSolver.traceDsl('vars: x in 1..oops');
      expect(r.ok, isFalse);
      expect(r.error, isNotNull);
    });

    test('a minimize directive is flagged objectiveIgnored but still traces',
        () async {
      // The feasibility search over the constraints is what gets
      // traced; the objective is ignored (as in the explain pass).
      final r = await CspSolver.traceDsl('''vars: x, y in 0..3
x + y == 3
minimize x''');
      expect(r.ok, isTrue);
      expect(r.objectiveIgnored, isTrue);
      expect(r.solved, isTrue);
    });

    test('maxEvents caps the trace and flags truncation', () async {
      // K4/3-colors emits 45 events; cap well under that.
      final r = await CspSolver.traceDsl('''vars: a, b, c, d in 1..3
a != b
a != c
a != d
b != c
b != d
c != d''', maxEvents: 5);
      expect(r.truncated, isTrue);
      expect(r.steps.length, lessThanOrEqualTo(5));
    });
  });
}
