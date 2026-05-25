// test/sudoku_test.dart
//
// SudokuSolver coverage: the canonical preset puzzles must solve
// and round-trip cleanly through dart_csp. Trace mode must record
// frames and end with the same solution as the quick-solve mode.

import 'package:crisp_calc/engine/sudoku.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SudokuLayout', () {
    test('4×4 invariants', () {
      const l = SudokuLayout.small;
      expect(l.side, 4);
      expect(l.boxRows * l.boxCols, 4);
    });

    test('9×9 invariants', () {
      const l = SudokuLayout.standard;
      expect(l.side, 9);
      expect(l.boxRows * l.boxCols, 9);
    });

    test('asserts boxRows * boxCols == side', () {
      expect(
        () => SudokuLayout(side: 9, boxRows: 2, boxCols: 4),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('SudokuSolver.solve', () {
    test('4×4 easy preset solves to a valid grid', () async {
      final puzzle = SudokuPresets.small4x4Easy;
      final out = await SudokuSolver.solve(puzzle);
      expect(out, isNotNull);
      _expectValidSudoku(puzzle.layout, out!);
      // All clues preserved.
      for (var i = 0; i < puzzle.cells.length; i++) {
        if (puzzle.cells[i] != 0) {
          expect(out[i], puzzle.cells[i]);
        }
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('9×9 easy preset solves', () async {
      final out = await SudokuSolver.solve(SudokuPresets.standard9x9Easy);
      expect(out, isNotNull);
      _expectValidSudoku(SudokuLayout.standard, out!);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('infeasible puzzle returns null', () async {
      // Two `1`s in the same row → contradiction.
      final puzzle = SudokuPuzzle(
        layout: SudokuLayout.small,
        cells: [
          1,
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      );
      final out = await SudokuSolver.solve(puzzle);
      expect(out, isNull);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('SudokuSolver.solveWithTrace', () {
    test('records frames and matches quick-solve result', () async {
      final puzzle = SudokuPresets.small4x4Easy;
      final trace = await SudokuSolver.solveWithTrace(puzzle);
      expect(trace.solved, isTrue);
      expect(trace.solution, isNotNull);
      expect(trace.frames, isNotEmpty);
      // First frame = starting clues. Last frame's snapshot must
      // equal the canonical solution.
      expect(trace.frames.first.assigned, puzzle.cells);
      expect(trace.frames.last.assigned, trace.solution);

      // Quick-solve sanity: same final state.
      final quick = await SudokuSolver.solve(puzzle);
      expect(trace.solution, quick);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('infeasible puzzle produces an error trace', () async {
      final puzzle = SudokuPuzzle(
        layout: SudokuLayout.small,
        cells: [
          1,
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      );
      final trace = await SudokuSolver.solveWithTrace(puzzle);
      expect(trace.solved, isFalse);
      expect(trace.solution, isNull);
      expect(trace.error, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('SudokuPresets catalog', () {
    test('all presets have the right cell count', () {
      for (final p in SudokuPresets.all) {
        expect(
            p.puzzle.cells.length, p.puzzle.layout.side * p.puzzle.layout.side,
            reason: '${p.id} length mismatch');
      }
    });

    test('all preset ids are unique', () {
      final ids = SudokuPresets.all.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every preset is solvable', () async {
      for (final p in SudokuPresets.all) {
        final out = await SudokuSolver.solve(p.puzzle);
        expect(out, isNotNull, reason: '${p.id} should have a valid solution');
      }
    }, timeout: const Timeout(Duration(seconds: 120)));
  });

  group('SudokuGenerator.generate', () {
    test('4×4 medium puzzle is solvable + has the right shape', () async {
      final puzzle = await SudokuGenerator.generate(
        layout: SudokuLayout.small,
        difficulty: SudokuDifficulty.medium,
        seed: 42,
      );
      expect(puzzle.cells.length, 16);
      expect(puzzle.layout.side, 4);
      // Some cells are clues, some are blank.
      final clueCount = puzzle.cells.where((v) => v != 0).length;
      expect(clueCount, greaterThan(0));
      expect(clueCount, lessThan(16));
      // The puzzle must be solvable.
      final solved = await SudokuSolver.solve(puzzle);
      expect(solved, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('different seeds produce different puzzles', () async {
      final a = await SudokuGenerator.generate(
        layout: SudokuLayout.small,
        difficulty: SudokuDifficulty.medium,
        seed: 1,
      );
      final b = await SudokuGenerator.generate(
        layout: SudokuLayout.small,
        difficulty: SudokuDifficulty.medium,
        seed: 2,
      );
      // Trivially different seed → likely-different clue layout.
      // (Not strict — two random 4×4 generations could in
      // principle collide; if this flakes we drop the assertion.)
      expect(a.cells, isNot(equals(b.cells)));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('easy difficulty leaves more clues than hard', () async {
      final easy = await SudokuGenerator.generate(
        layout: SudokuLayout.small,
        difficulty: SudokuDifficulty.easy,
        seed: 7,
      );
      final hard = await SudokuGenerator.generate(
        layout: SudokuLayout.small,
        difficulty: SudokuDifficulty.hard,
        seed: 7,
      );
      final easyClues = easy.cells.where((v) => v != 0).length;
      final hardClues = hard.cells.where((v) => v != 0).length;
      expect(easyClues, greaterThanOrEqualTo(hardClues));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('Sudoku generate → solve round-trip', () {
    // Across all (layout × difficulty × seed) combinations, the
    // generator's output must be both well-formed AND solvable by
    // the same CSP backend that powers the Solve button. The
    // generator's internal uniqueness check (hasMultipleSolutions)
    // is *only* a guard against ambiguity; this test additionally
    // proves the puzzle has a valid solution that respects all
    // clues and Sudoku rules.
    Future<void> runRoundtrip(
        SudokuLayout layout, SudokuDifficulty difficulty, int seed) async {
      final puzzle = await SudokuGenerator.generate(
        layout: layout,
        difficulty: difficulty,
        seed: seed,
      );
      // Clues respect the rules pairwise within rows/cols/boxes.
      final clues = {
        for (var i = 0; i < puzzle.cells.length; i++)
          if (puzzle.cells[i] != 0) i: puzzle.cells[i]
      };
      // Solve the freshly-generated puzzle.
      final solution = await SudokuSolver.solve(puzzle);
      expect(solution, isNotNull,
          reason: 'Generated puzzle (layout=${layout.side}, '
              'difficulty=$difficulty, seed=$seed) was unsolvable');
      // Solution preserves every clue.
      for (final entry in clues.entries) {
        expect(solution![entry.key], entry.value,
            reason:
                'Solution dropped clue at index ${entry.key} (was ${entry.value})');
      }
      // Solution satisfies Sudoku rules (no duplicates in any
      // row, column, or box).
      _expectValidSudoku(layout, solution!);
    }

    test('4×4 easy round-trip', () async {
      await runRoundtrip(SudokuLayout.small, SudokuDifficulty.easy, 11);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('4×4 medium round-trip', () async {
      await runRoundtrip(SudokuLayout.small, SudokuDifficulty.medium, 22);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('4×4 hard round-trip', () async {
      await runRoundtrip(SudokuLayout.small, SudokuDifficulty.hard, 33);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('9×9 easy round-trip', () async {
      await runRoundtrip(SudokuLayout.standard, SudokuDifficulty.easy, 44);
    }, timeout: const Timeout(Duration(seconds: 120)));

    test('9×9 medium round-trip', () async {
      await runRoundtrip(SudokuLayout.standard, SudokuDifficulty.medium, 55);
    }, timeout: const Timeout(Duration(seconds: 180)));
  });

  group('Sudoku V2 — 6×6 layout', () {
    test('SudokuLayout.medium invariants', () {
      const l = SudokuLayout.medium;
      expect(l.side, 6);
      expect(l.boxRows, 2);
      expect(l.boxCols, 3);
      expect(l.boxRows * l.boxCols, l.side);
    });

    test('6×6 medium preset solves', () async {
      final out = await SudokuSolver.solve(SudokuPresets.medium6x6);
      expect(out, isNotNull);
      _expectValidSudoku(SudokuLayout.medium, out!);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('generator round-trip: 6×6 medium', () async {
      final puzzle = await SudokuGenerator.generate(
        layout: SudokuLayout.medium,
        difficulty: SudokuDifficulty.medium,
        seed: 6,
      );
      expect(puzzle.cells.length, 36);
      final sol = await SudokuSolver.solve(puzzle);
      expect(sol, isNotNull);
      _expectValidSudoku(SudokuLayout.medium, sol!);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('Sudoku V3 — computeCandidates (hint mode)', () {
    test('empty 4×4 has every digit 1..4 candidate for every cell', () {
      final puzzle = SudokuPuzzle(
        layout: SudokuLayout.small,
        cells: List<int>.filled(16, 0),
      );
      final cands = SudokuSolver.computeCandidates(puzzle);
      expect(cands, hasLength(16));
      for (final s in cands) {
        expect(s, equals({1, 2, 3, 4}));
      }
    });

    test('cell with a row clue loses that value', () {
      final puzzle = SudokuPuzzle(
        layout: SudokuLayout.small,
        cells: [
          1, 0, 0, 0, // row 0: 1 already used
          0, 0, 0, 0,
          0, 0, 0, 0,
          0, 0, 0, 0,
        ],
      );
      final cands = SudokuSolver.computeCandidates(puzzle);
      // (0, 1) — same row as the 1 clue → can't be 1.
      expect(cands[1], equals({2, 3, 4}));
      // (1, 0) — same column → can't be 1.
      expect(cands[4], equals({2, 3, 4}));
      // (1, 1) — same 2×2 box → can't be 1.
      expect(cands[5], equals({2, 3, 4}));
      // (1, 2) — different box, different row, different col → 1 still legal.
      expect(cands[6], contains(1));
    });

    test('clue cells get the empty candidate set', () {
      final cands = SudokuSolver.computeCandidates(SudokuPresets.small4x4Easy);
      for (var i = 0; i < SudokuPresets.small4x4Easy.cells.length; i++) {
        if (SudokuPresets.small4x4Easy.cells[i] != 0) {
          expect(cands[i], isEmpty,
              reason: 'clue cell $i should have empty candidates');
        }
      }
    });

    test('Sudoku-X variant also eliminates diagonal occupants', () {
      // 9×9 X variant: put a `5` at (0, 0) — main diagonal. The
      // cell at (4, 4) (also on the main diagonal) must NOT have
      // 5 as a candidate.
      final cells = List<int>.filled(81, 0);
      cells[0] = 5; // (0, 0)
      final puzzle = SudokuPuzzle(
        layout: SudokuLayout.standard,
        cells: cells,
        variant: SudokuVariant.x,
      );
      final cands = SudokuSolver.computeCandidates(puzzle);
      expect(cands[4 * 9 + 4], isNot(contains(5)),
          reason: 'main diagonal cell (4,4) should exclude 5');
      // (4, 4) is also on the anti-diagonal, so it loses 5 either way.
      // Pick (8, 0) — anti-diagonal but NOT main diagonal — and put
      // a 7 at (0, 8) (also anti-diagonal).
      final cells2 = List<int>.filled(81, 0);
      cells2[0 * 9 + 8] = 7; // (0, 8)
      final p2 = SudokuPuzzle(
        layout: SudokuLayout.standard,
        cells: cells2,
        variant: SudokuVariant.x,
      );
      final c2 = SudokuSolver.computeCandidates(p2);
      expect(c2[8 * 9 + 0], isNot(contains(7)),
          reason: 'anti-diagonal cell (8,0) should exclude 7');
    });

    test('regular variant ignores diagonal occupants', () {
      // Same setup as above, but variant=regular: 5 at (0,0)
      // should NOT prevent 5 at (4,4) (no shared row/col/box).
      final cells = List<int>.filled(81, 0);
      cells[0] = 5;
      final puzzle = SudokuPuzzle(
        layout: SudokuLayout.standard,
        cells: cells,
      );
      final cands = SudokuSolver.computeCandidates(puzzle);
      expect(cands[4 * 9 + 4], contains(5));
    });
  });

  group('Sudoku V2 — Sudoku-X variant', () {
    test('generator round-trip: 9×9 X variant easy', () async {
      final puzzle = await SudokuGenerator.generate(
        layout: SudokuLayout.standard,
        difficulty: SudokuDifficulty.easy,
        variant: SudokuVariant.x,
        seed: 99,
      );
      expect(puzzle.variant, SudokuVariant.x);
      final sol = await SudokuSolver.solve(puzzle);
      expect(sol, isNotNull);
      _expectValidSudoku(SudokuLayout.standard, sol!);
      // Diagonals respect the X variant.
      const n = 9;
      final mainDiag = [for (var i = 0; i < n; i++) sol[i * n + i]];
      final antiDiag = [for (var i = 0; i < n; i++) sol[i * n + (n - 1 - i)]];
      expect(mainDiag.toSet().length, n);
      expect(antiDiag.toSet().length, n);
    }, timeout: const Timeout(Duration(seconds: 180)));
  });

  group('Sudoku — uniqueness check', () {
    test('a generated puzzle has a unique solution', () async {
      final puzzle = await SudokuGenerator.generate(
        layout: SudokuLayout.small,
        difficulty: SudokuDifficulty.easy,
        seed: 42,
      );
      expect(await SudokuSolver.hasUniqueSolution(puzzle), isTrue);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('an empty puzzle has many solutions (not unique)', () async {
      final empty = SudokuPuzzle(
        layout: SudokuLayout.small,
        cells: List<int>.filled(16, 0),
      );
      expect(await SudokuSolver.hasUniqueSolution(empty), isFalse);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('an infeasible puzzle has no solutions (also not unique)', () async {
      final bad = SudokuPuzzle(
        layout: SudokuLayout.small,
        cells: [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      );
      expect(await SudokuSolver.hasUniqueSolution(bad), isFalse);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('Sudoku — Killer variant', () {
    test('killer4x4 preset partitions every cell into exactly one cage', () {
      final puzzle = SudokuPresets.killer4x4;
      final n = puzzle.layout.side;
      final seen = <int>{};
      for (final c in puzzle.cages!) {
        for (final idx in c.cellIndexes) {
          expect(seen.add(idx), isTrue,
              reason: 'cell $idx appears in more than one cage');
        }
      }
      expect(seen.length, n * n,
          reason: 'cages must cover every cell of the grid');
    });

    test('killer4x4 preset has cage sums that match a valid solution',
        () async {
      final puzzle = SudokuPresets.killer4x4;
      final sol = await SudokuSolver.solve(puzzle);
      expect(sol, isNotNull, reason: 'killer4x4 must be feasible');
      _expectValidSudoku(puzzle.layout, sol!);
      // Per-cage sum equals targetSum AND cage values are all-different.
      for (final cage in puzzle.cages!) {
        final values = [for (final idx in cage.cellIndexes) sol[idx]];
        expect(values.reduce((a, b) => a + b), cage.targetSum,
            reason: 'cage with target ${cage.targetSum} sums to wrong total');
        expect(values.toSet().length, values.length,
            reason: 'cage with target ${cage.targetSum} has duplicate digits');
      }
    });

    test('killer4x4 round-trip: stripping all clues still solves under cages',
        () async {
      // Killer puzzles need no givens — the cage system is the
      // entire constraint set. Verify solving from an empty grid
      // with the cage spec alone still recovers a valid solution.
      final preset = SudokuPresets.killer4x4;
      final empty = SudokuPuzzle(
        layout: preset.layout,
        cells: List<int>.filled(preset.layout.side * preset.layout.side, 0),
        variant: SudokuVariant.killer,
        cages: preset.cages,
      );
      final sol = await SudokuSolver.solve(empty);
      expect(sol, isNotNull);
      _expectValidSudoku(preset.layout, sol!);
      for (final cage in preset.cages!) {
        final values = [for (final idx in cage.cellIndexes) sol[idx]];
        expect(values.reduce((a, b) => a + b), cage.targetSum);
        expect(values.toSet().length, values.length);
      }
    });

    test('killer cage with infeasible sum returns no solution', () async {
      // A 2-cell cage that targets sum = 1 cannot be filled with
      // any two distinct digits from 1..4 (smallest pair is 1+2=3).
      final infeasible = SudokuPuzzle(
        layout: SudokuLayout.small,
        cells: List<int>.filled(16, 0),
        variant: SudokuVariant.killer,
        cages: const [
          KillerCage(cellIndexes: [0, 1], targetSum: 1),
          KillerCage(cellIndexes: [2, 3], targetSum: 9),
          KillerCage(
              cellIndexes: [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
              targetSum: 30),
        ],
      );
      final sol = await SudokuSolver.solve(infeasible);
      expect(sol, isNull);
    });

    test('killer9x9 preset partitions every cell into exactly one cage', () {
      final puzzle = SudokuPresets.killer9x9;
      final n = puzzle.layout.side;
      final seen = <int>{};
      for (final c in puzzle.cages!) {
        for (final idx in c.cellIndexes) {
          expect(seen.add(idx), isTrue,
              reason: 'cell $idx appears in more than one cage');
        }
      }
      expect(seen.length, n * n,
          reason: 'cages must cover every cell of the 9×9 grid');
    });

    test('killer9x9 preset is feasible and cage sums match a solution',
        () async {
      final puzzle = SudokuPresets.killer9x9;
      final sol = await SudokuSolver.solve(puzzle);
      expect(sol, isNotNull, reason: 'killer9x9 must be feasible');
      _expectValidSudoku(puzzle.layout, sol!);
      for (final cage in puzzle.cages!) {
        final values = [for (final idx in cage.cellIndexes) sol[idx]];
        expect(values.reduce((a, b) => a + b), cage.targetSum,
            reason: 'cage with target ${cage.targetSum} sums to wrong total');
        expect(values.toSet().length, values.length,
            reason: 'cage with target ${cage.targetSum} has duplicates');
      }
    }, timeout: const Timeout(Duration(seconds: 180)));

    test(
        'regression: horizontal-only cage (subset of one row) does not '
        'over-constrain the solver', () async {
      // Round 64 bisection found that adding a redundant cage
      // allDifferent to dart_csp on top of the existing row
      // allDifferent triggers a propagation pathology that prunes
      // valid solutions. The engine now skips the cage
      // allDifferent when the cage is entirely within one row,
      // one column, or one box. This test asserts a tiny 4×4
      // Killer with all horizontal cages still solves.
      const cages = [
        // Row 0: pairs (3+1=4) and (4+2=6)
        KillerCage(cellIndexes: [0, 1], targetSum: 4),
        KillerCage(cellIndexes: [2, 3], targetSum: 6),
        // Row 1: pairs (4+2=6) and (3+1=4)
        KillerCage(cellIndexes: [4, 5], targetSum: 6),
        KillerCage(cellIndexes: [6, 7], targetSum: 4),
        // Row 2: (1+3=4) and (2+4=6)
        KillerCage(cellIndexes: [8, 9], targetSum: 4),
        KillerCage(cellIndexes: [10, 11], targetSum: 6),
        // Row 3: (2+4=6) and (1+3=4)
        KillerCage(cellIndexes: [12, 13], targetSum: 6),
        KillerCage(cellIndexes: [14, 15], targetSum: 4),
      ];
      final puzzle = SudokuPuzzle(
        layout: SudokuLayout.small,
        cells: List<int>.filled(16, 0),
        variant: SudokuVariant.killer,
        cages: cages,
      );
      final sol = await SudokuSolver.solve(puzzle);
      expect(sol, isNotNull, reason: 'horizontal-only Killer must be feasible');
      _expectValidSudoku(SudokuLayout.small, sol!);
      for (final cage in cages) {
        final values = [for (final idx in cage.cellIndexes) sol[idx]];
        expect(values.reduce((a, b) => a + b), cage.targetSum);
      }
    });

    test('asserts: killer variant without cages throws', () {
      expect(
        () => SudokuPuzzle(
          layout: SudokuLayout.small,
          cells: List<int>.filled(16, 0),
          variant: SudokuVariant.killer,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

void _expectValidSudoku(SudokuLayout layout, List<int> cells) {
  final n = layout.side;
  // Every value in 1..n.
  for (final v in cells) {
    expect(v >= 1 && v <= n, isTrue, reason: 'value $v out of range');
  }
  // Rows and columns all-different.
  for (var r = 0; r < n; r++) {
    final row = [for (var c = 0; c < n; c++) cells[r * n + c]];
    expect(row.toSet().length, n, reason: 'row $r has duplicates');
  }
  for (var c = 0; c < n; c++) {
    final col = [for (var r = 0; r < n; r++) cells[r * n + c]];
    expect(col.toSet().length, n, reason: 'col $c has duplicates');
  }
  // Boxes all-different.
  for (var br = 0; br < n; br += layout.boxRows) {
    for (var bc = 0; bc < n; bc += layout.boxCols) {
      final box = <int>[];
      for (var dr = 0; dr < layout.boxRows; dr++) {
        for (var dc = 0; dc < layout.boxCols; dc++) {
          box.add(cells[(br + dr) * n + (bc + dc)]);
        }
      }
      expect(box.toSet().length, n, reason: 'box at ($br,$bc) has duplicates');
    }
  }
}
