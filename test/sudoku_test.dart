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
