// lib/engine/sudoku.dart
//
// Sudoku model + solver wrapper around dart_csp. Parameterized by
// (side, boxRows, boxCols) so V1's 4×4 (2×2 boxes) and 9×9 (3×3
// boxes) share one engine — and the variant roadmap in PLAN.md
// (6×6 = 2×3, 8×8 = 2×4, 16×16 = 4×4, 25×25 = 5×5, irregular
// regions, killer) all reduce to swapping the constructor args
// or, for irregular boxes, replacing the `_boxes()` walker.
//
// The solver does two passes:
//
//   1. **Quick solve** via `Problem.getSolution()` — returns the
//      filled grid for production "Solve" buttons.
//
//   2. **Trace solve** via `setOptions(callback: ...)` — records
//      every search step as a `SudokuTrace` so the UI can replay
//      the search at user-controlled speed. The recorded trace is
//      independent of the live solve, so play/pause/scrub in the
//      UI doesn't need to coordinate with dart_csp.

import 'dart:math';

import 'package:dart_csp/dart_csp.dart' as csp;

/// A single Sudoku puzzle layout. Standard 9×9 has `side=9,
/// boxRows=3, boxCols=3`; the V1 mini variant is `side=4,
/// boxRows=2, boxCols=2`. The constructor asserts that
/// `boxRows * boxCols == side` — required for the box-partition
/// to cover the grid exactly.
class SudokuLayout {
  final int side;
  final int boxRows;
  final int boxCols;

  const SudokuLayout({
    required this.side,
    required this.boxRows,
    required this.boxCols,
  }) : assert(boxRows * boxCols == side, 'boxRows*boxCols must equal side');

  static const small = SudokuLayout(side: 4, boxRows: 2, boxCols: 2);
  static const standard = SudokuLayout(side: 9, boxRows: 3, boxCols: 3);
}

/// A Sudoku puzzle = layout + initial clues. `cells` is a flat
/// length-`side²` int list where 0 = empty cell and 1..side = clue.
class SudokuPuzzle {
  final SudokuLayout layout;
  final List<int> cells;

  SudokuPuzzle({required this.layout, required this.cells})
      : assert(cells.length == layout.side * layout.side);

  int get(int row, int col) => cells[row * layout.side + col];

  SudokuPuzzle withCell(int row, int col, int value) {
    final copy = List<int>.from(cells);
    copy[row * layout.side + col] = value;
    return SudokuPuzzle(layout: layout, cells: copy);
  }
}

/// One frame in a recorded solve trace. `assigned` is a flat
/// length-`side²` list mirroring [SudokuPuzzle.cells]: original
/// clues + every cell the solver has placed so far. 0 means
/// "still unassigned at this step".
class SudokuTraceFrame {
  final List<int> assigned;
  final int? justChangedIndex;

  const SudokuTraceFrame({required this.assigned, this.justChangedIndex});
}

/// The recorded trace plus the final solution (if any).
class SudokuTrace {
  final List<SudokuTraceFrame> frames;
  final List<int>? solution;
  final String? error;

  const SudokuTrace({
    required this.frames,
    required this.solution,
    required this.error,
  });

  bool get solved => error == null && solution != null;
}

class SudokuSolver {
  /// Single-shot solve. Returns the filled cell list (length
  /// `side²`) on success, or null when the puzzle is infeasible.
  /// Throws nothing — callers can treat null as "no solution".
  static Future<List<int>?> solve(SudokuPuzzle puzzle) async {
    final problem = _buildProblem(puzzle);
    final result = await problem.getSolution();
    if (result is! Map<String, dynamic>) return null;
    return _flatten(puzzle.layout, result);
  }

  /// Trace solve. Same input as [solve] but records every
  /// solver decision into a list of frames so the UI can replay
  /// the search at its own pace. Trace length is bounded — we
  /// stop capturing after `maxFrames` to avoid running out of
  /// memory on pathological puzzles.
  static Future<SudokuTrace> solveWithTrace(
    SudokuPuzzle puzzle, {
    int maxFrames = 5000,
  }) async {
    final problem = _buildProblem(puzzle);
    final frames = <SudokuTraceFrame>[];
    // Always include the starting frame so the replay shows the
    // user's input before any solver decision.
    final initial = List<int>.from(puzzle.cells);
    frames.add(SudokuTraceFrame(assigned: List<int>.from(initial)));
    var capped = false;
    // Track the previous frame so we can flag which cell just changed.
    var prev = List<int>.from(initial);
    problem.setOptions(
      timeStep: 0,
      callback: (assigned, unassigned) {
        if (capped) return;
        if (frames.length >= maxFrames) {
          capped = true;
          return;
        }
        final snapshot = List<int>.from(initial);
        var changed = -1;
        for (final entry in assigned.entries) {
          // `assigned` values come back as a singleton-list domain.
          final values = entry.value;
          if (values.isEmpty) continue;
          final v = (values.first as num).toInt();
          final idx = _indexOf(puzzle.layout, entry.key);
          snapshot[idx] = v;
          if (snapshot[idx] != prev[idx]) changed = idx;
        }
        frames.add(SudokuTraceFrame(
          assigned: snapshot,
          justChangedIndex: changed >= 0 ? changed : null,
        ));
        prev = snapshot;
      },
    );

    final result = await problem.getSolution();
    if (result is! Map<String, dynamic>) {
      return SudokuTrace(
        frames: frames,
        solution: null,
        error: 'No solution exists for this puzzle.',
      );
    }
    final solution = _flatten(puzzle.layout, result);
    // Tack a final "complete" frame on so the replay ends on the
    // full grid even if dart_csp didn't emit a callback for the
    // last decision.
    frames.add(SudokuTraceFrame(assigned: solution));
    return SudokuTrace(frames: frames, solution: solution, error: null);
  }

  // === Internals ==========================================================

  /// `r0c0`, `r0c1`, … `r8c8`. Single string per cell because
  /// dart_csp keys variables by string.
  static String _key(int row, int col) => 'r${row}c$col';

  static int _indexOf(SudokuLayout layout, String key) {
    // Expect format `rRcC` where R, C are 1+ digits.
    final m = RegExp(r'^r(\d+)c(\d+)$').firstMatch(key);
    if (m == null) {
      throw ArgumentError('Bad cell key: $key');
    }
    final row = int.parse(m.group(1)!);
    final col = int.parse(m.group(2)!);
    return row * layout.side + col;
  }

  static csp.Problem _buildProblem(SudokuPuzzle puzzle) {
    final p = csp.Problem();
    final n = puzzle.layout.side;
    // Cell variables. Clued cells get a singleton domain (which
    // dart_csp treats as a known assignment); empty cells get
    // 1..n.
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final v = puzzle.get(r, c);
        if (v == 0) {
          p.addVariable(_key(r, c), [for (var i = 1; i <= n; i++) i]);
        } else {
          p.addVariable(_key(r, c), [v]);
        }
      }
    }
    // Row, column, and box `allDifferent` constraints. dart_csp's
    // alldifferent propagator is the Régin-style hyper-arc-
    // consistent one — strong enough that 4×4 and most 9×9
    // puzzles finish in milliseconds.
    for (var r = 0; r < n; r++) {
      p.addAllDifferent([for (var c = 0; c < n; c++) _key(r, c)]);
    }
    for (var c = 0; c < n; c++) {
      p.addAllDifferent([for (var r = 0; r < n; r++) _key(r, c)]);
    }
    for (final box in _boxes(puzzle.layout)) {
      p.addAllDifferent(box);
    }
    return p;
  }

  /// Yields the box partition as a list of (row, col) -> key
  /// groups. For the standard 9×9 this is nine 3×3 squares; for
  /// 4×4 it's four 2×2 squares; for 6×6 it would be six 2×3 blocks
  /// (V2 work).
  static Iterable<List<String>> _boxes(SudokuLayout layout) sync* {
    for (var br = 0; br < layout.side; br += layout.boxRows) {
      for (var bc = 0; bc < layout.side; bc += layout.boxCols) {
        final box = <String>[];
        for (var dr = 0; dr < layout.boxRows; dr++) {
          for (var dc = 0; dc < layout.boxCols; dc++) {
            box.add(_key(br + dr, bc + dc));
          }
        }
        yield box;
      }
    }
  }

  /// Converts dart_csp's `Map<String, int>` solution into the flat
  /// cell-list shape the rest of the app uses.
  static List<int> _flatten(SudokuLayout layout, Map<String, dynamic> result) {
    final out = List<int>.filled(layout.side * layout.side, 0);
    for (final entry in result.entries) {
      out[_indexOf(layout, entry.key)] = (entry.value as num).toInt();
    }
    return out;
  }
}

/// Difficulty knob for [SudokuGenerator.generate]. Maps to an
/// approximate clue count: easier puzzles keep more clues, harder
/// ones peel further. The generator may stop short if it can't
/// remove a clue without breaking uniqueness.
enum SudokuDifficulty {
  easy,
  medium,
  hard,
}

class SudokuGenerator {
  /// Generates a fresh puzzle of the given [layout] + [difficulty].
  /// Two-stage process:
  ///
  ///   1. **Fill a complete grid.** We seed the all-empty
  ///      problem with a single random clue and ask dart_csp for
  ///      one solution. The random seed (varied per call when
  ///      [seed] is null) makes each call return a different
  ///      grid.
  ///
  ///   2. **Peel clues** while uniqueness holds. Walk the grid in
  ///      shuffled order; for each non-empty cell, tentatively
  ///      blank it and call `hasMultipleSolutions`. If the result
  ///      is unique, keep the cell blank; otherwise put the value
  ///      back. Stop when we've peeled enough clues to hit the
  ///      difficulty's target or run out of removable cells.
  ///
  /// Returns the generated puzzle. The randomness budget is per
  /// call — if [seed] is null we use `DateTime.now().microsecond`.
  static Future<SudokuPuzzle> generate({
    SudokuLayout layout = SudokuLayout.standard,
    SudokuDifficulty difficulty = SudokuDifficulty.medium,
    int? seed,
  }) async {
    final rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final n = layout.side;

    // === Stage 1: full grid ===============================================
    // Seed with one random clue so the solver doesn't always return
    // the same canonical grid. We pick an arbitrary cell and value;
    // dart_csp completes the rest.
    final seedRow = rng.nextInt(n);
    final seedCol = rng.nextInt(n);
    final seedVal = 1 + rng.nextInt(n);
    final seedPuzzle = SudokuPuzzle(
      layout: layout,
      cells: List<int>.filled(n * n, 0),
    ).withCell(seedRow, seedCol, seedVal);
    final full = await SudokuSolver.solve(seedPuzzle);
    if (full == null) {
      // Vanishingly unlikely (a single clue can't conflict with
      // anything), but degrade gracefully by retrying with a
      // different seed.
      return generate(
          layout: layout, difficulty: difficulty, seed: rng.nextInt(1 << 31));
    }

    // === Stage 2: peel while unique =======================================
    // Target clue counts are calibrated to the standard 4×4 and
    // 9×9. The minimum-clue research for other sizes lives in
    // PLAN.md's variant roadmap.
    final targetClues = _targetClueCount(layout, difficulty);

    final cells = List<int>.from(full);
    final indices = List.generate(n * n, (i) => i)..shuffle(rng);
    var remainingClues = n * n;
    for (final idx in indices) {
      if (remainingClues <= targetClues) break;
      final saved = cells[idx];
      cells[idx] = 0;
      final candidate = SudokuPuzzle(layout: layout, cells: cells);
      final ambiguous = await _hasMultipleSolutions(candidate);
      if (ambiguous) {
        cells[idx] = saved;
      } else {
        remainingClues--;
      }
    }

    return SudokuPuzzle(layout: layout, cells: cells);
  }

  /// Wraps the dart_csp `hasMultipleSolutions` call for a Sudoku
  /// puzzle. Returns true when ≥ 2 distinct solutions exist
  /// (puzzle is ambiguous — caller would put the clue back).
  static Future<bool> _hasMultipleSolutions(SudokuPuzzle puzzle) async {
    final problem = SudokuSolver._buildProblem(puzzle);
    return problem.hasMultipleSolutions();
  }

  static int _targetClueCount(
      SudokuLayout layout, SudokuDifficulty difficulty) {
    // Per the Wikipedia minimum-clue table (and CrispCalc's
    // PLAN.md notes): 4×4 minimum is 4 clues, 9×9 minimum is 17.
    // We pad above the minimum for "easy" so the puzzle is
    // approachable; sit near the minimum for "hard". Values
    // chosen so easy < medium < hard always reduces the count.
    if (layout.side == 4) {
      switch (difficulty) {
        case SudokuDifficulty.easy:
          return 10;
        case SudokuDifficulty.medium:
          return 7;
        case SudokuDifficulty.hard:
          return 4;
      }
    }
    // 9×9 (the standard case) and any other size fall back here.
    switch (difficulty) {
      case SudokuDifficulty.easy:
        return 40;
      case SudokuDifficulty.medium:
        return 30;
      case SudokuDifficulty.hard:
        return 22;
    }
  }
}

/// A handful of preset puzzles for the V1 module's puzzle picker.
/// Each layout has three difficulties (easy / med / hard) — the
/// 4×4 ones are hand-picked, the 9×9 ones are public-domain
/// classics. Numbers chosen so the user can verify a solve by
/// eye.
class SudokuPresets {
  // The 4×4 presets are peeled from the canonical full grid
  //   1 2 3 4 / 3 4 1 2 / 2 1 4 3 / 4 3 2 1
  // so they're guaranteed to have at least one valid solution.

  /// 4×4 with 8 clues — easiest. Solved by AC-3 alone.
  static final SudokuPuzzle small4x4Easy = SudokuPuzzle(
    layout: SudokuLayout.small,
    cells: [
      1,
      0,
      0,
      4,
      0,
      4,
      1,
      0,
      0,
      1,
      4,
      0,
      4,
      0,
      0,
      1,
    ],
  );

  /// 4×4 with 6 clues — medium.
  static final SudokuPuzzle small4x4Medium = SudokuPuzzle(
    layout: SudokuLayout.small,
    cells: [
      0,
      2,
      0,
      4,
      0,
      0,
      1,
      0,
      0,
      1,
      0,
      0,
      4,
      0,
      2,
      0,
    ],
  );

  /// 4×4 with 4 clues — exercises real search. (Minimum for the
  /// canonical full grid above; the published "minimum 4 clues"
  /// theorem assures any 4-clue 4×4 with a unique solution
  /// exists, but we pick a known-feasible one.)
  static final SudokuPuzzle small4x4Hard = SudokuPuzzle(
    layout: SudokuLayout.small,
    cells: [
      1,
      0,
      0,
      0,
      0,
      4,
      0,
      0,
      0,
      0,
      4,
      0,
      0,
      0,
      0,
      1,
    ],
  );

  /// 9×9 easy — many clues, AC-3 + minimal search.
  static final SudokuPuzzle standard9x9Easy = SudokuPuzzle(
    layout: SudokuLayout.standard,
    cells: [
      5,
      3,
      0,
      0,
      7,
      0,
      0,
      0,
      0,
      6,
      0,
      0,
      1,
      9,
      5,
      0,
      0,
      0,
      0,
      9,
      8,
      0,
      0,
      0,
      0,
      6,
      0,
      8,
      0,
      0,
      0,
      6,
      0,
      0,
      0,
      3,
      4,
      0,
      0,
      8,
      0,
      3,
      0,
      0,
      1,
      7,
      0,
      0,
      0,
      2,
      0,
      0,
      0,
      6,
      0,
      6,
      0,
      0,
      0,
      0,
      2,
      8,
      0,
      0,
      0,
      0,
      4,
      1,
      9,
      0,
      0,
      5,
      0,
      0,
      0,
      0,
      8,
      0,
      0,
      7,
      9,
    ],
  );

  /// 9×9 medium — fewer clues, moderate backtracking.
  static final SudokuPuzzle standard9x9Medium = SudokuPuzzle(
    layout: SudokuLayout.standard,
    cells: [
      0,
      0,
      0,
      2,
      6,
      0,
      7,
      0,
      1,
      6,
      8,
      0,
      0,
      7,
      0,
      0,
      9,
      0,
      1,
      9,
      0,
      0,
      0,
      4,
      5,
      0,
      0,
      8,
      2,
      0,
      1,
      0,
      0,
      0,
      4,
      0,
      0,
      0,
      4,
      6,
      0,
      2,
      9,
      0,
      0,
      0,
      5,
      0,
      0,
      0,
      3,
      0,
      2,
      8,
      0,
      0,
      9,
      3,
      0,
      0,
      0,
      7,
      4,
      0,
      4,
      0,
      0,
      5,
      0,
      0,
      3,
      6,
      7,
      0,
      3,
      0,
      1,
      8,
      0,
      0,
      0,
    ],
  );

  /// 9×9 hard — Arto Inkala's "AI Escargot" (often cited as one
  /// of the hardest published puzzles). Will exercise the
  /// visualizer noticeably more than the others.
  static final SudokuPuzzle standard9x9Hard = SudokuPuzzle(
    layout: SudokuLayout.standard,
    cells: [
      1,
      0,
      0,
      0,
      0,
      7,
      0,
      9,
      0,
      0,
      3,
      0,
      0,
      2,
      0,
      0,
      0,
      8,
      0,
      0,
      9,
      6,
      0,
      0,
      5,
      0,
      0,
      0,
      0,
      5,
      3,
      0,
      0,
      9,
      0,
      0,
      0,
      1,
      0,
      0,
      8,
      0,
      0,
      0,
      2,
      6,
      0,
      0,
      0,
      0,
      4,
      0,
      0,
      0,
      3,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      4,
      0,
      0,
      0,
      0,
      0,
      0,
      7,
      0,
      0,
      7,
      0,
      0,
      0,
      3,
      0,
      0,
    ],
  );

  /// Friendly preset list with (id, layout) pairs the picker uses.
  static final List<({String id, SudokuPuzzle puzzle})> all = [
    (id: 'small4x4Easy', puzzle: small4x4Easy),
    (id: 'small4x4Medium', puzzle: small4x4Medium),
    (id: 'small4x4Hard', puzzle: small4x4Hard),
    (id: 'standard9x9Easy', puzzle: standard9x9Easy),
    (id: 'standard9x9Medium', puzzle: standard9x9Medium),
    (id: 'standard9x9Hard', puzzle: standard9x9Hard),
  ];
}
