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

/// Sudoku rule variants. `regular` is the classic row + column +
/// box `allDifferent`; `x` adds the two diagonals as further
/// `allDifferent` constraints (Sudoku-X); `killer` replaces the
/// "given clues" pattern with a partition of the grid into
/// **cages** (irregular cell groups), each carrying a target sum.
/// Killer puzzles still respect row / column / box `allDifferent`
/// plus per-cage `allDifferent` (no digit repeats within a cage)
/// plus per-cage sum equality.
enum SudokuVariant { regular, x, killer }

/// One Killer Sudoku cage: a set of cell indexes (into the flat
/// length-`side²` cell list) that together must sum to
/// [targetSum] and contain no repeated digits.
class KillerCage {
  final List<int> cellIndexes;
  final int targetSum;

  const KillerCage({required this.cellIndexes, required this.targetSum});
}

/// A single Sudoku puzzle layout. Standard 9×9 has `side=9,
/// boxRows=3, boxCols=3`; the V1 mini variant is `side=4,
/// boxRows=2, boxCols=2`. V2 adds 6×6 (2×3 boxes) and 16×16
/// (4×4 boxes). The constructor asserts that
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
  static const medium = SudokuLayout(side: 6, boxRows: 2, boxCols: 3);
  static const standard = SudokuLayout(side: 9, boxRows: 3, boxCols: 3);
  static const large = SudokuLayout(side: 16, boxRows: 4, boxCols: 4);

  /// Every layout the V2 module exposes. Generator + UI iterate
  /// over this rather than naming constants directly so adding a
  /// new size (e.g. 8×8 with 2×4 boxes) is a one-line change.
  static const all = <SudokuLayout>[small, medium, standard, large];
}

/// A Sudoku puzzle = layout + variant + initial clues. `cells` is
/// a flat length-`side²` int list where 0 = empty cell and 1..side
/// = clue.
class SudokuPuzzle {
  final SudokuLayout layout;
  final SudokuVariant variant;
  final List<int> cells;

  /// Killer-only: list of cages partitioning the grid. Each cell
  /// index must appear in exactly one cage. Null when
  /// `variant != killer`. The constructor asserts coverage when
  /// the variant is killer.
  final List<KillerCage>? cages;

  SudokuPuzzle({
    required this.layout,
    required this.cells,
    this.variant = SudokuVariant.regular,
    this.cages,
  })  : assert(cells.length == layout.side * layout.side),
        assert(variant != SudokuVariant.killer || cages != null,
            'killer variant requires a cages list'),
        assert(cages == null || _validCages(cages, layout.side * layout.side));

  int get(int row, int col) => cells[row * layout.side + col];

  SudokuPuzzle withCell(int row, int col, int value) {
    final copy = List<int>.from(cells);
    copy[row * layout.side + col] = value;
    return SudokuPuzzle(
        layout: layout, cells: copy, variant: variant, cages: cages);
  }

  /// Every cell index must appear in exactly one cage. Cage
  /// indexes must be in `[0, totalCells)`.
  static bool _validCages(List<KillerCage> cages, int totalCells) {
    final seen = <int>{};
    for (final c in cages) {
      for (final idx in c.cellIndexes) {
        if (idx < 0 || idx >= totalCells) return false;
        if (!seen.add(idx)) return false; // duplicate cell across cages
      }
    }
    return seen.length == totalCells;
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

  /// Round 65: uniqueness check. Returns true iff the puzzle has
  /// exactly one solution. Returns false when the puzzle has
  /// either zero solutions or two-or-more. The cost is roughly
  /// `solve` + the dart_csp effort to find a SECOND solution —
  /// fast when one exists (next leaf in the search tree), slow
  /// when none does (full tree exhaustion). Callers driving this
  /// from a UI should put it behind a button or a timeout.
  static Future<bool> hasUniqueSolution(SudokuPuzzle puzzle) async {
    final first = await solve(puzzle);
    if (first == null) return false;
    final problem = _buildProblem(puzzle);
    return !(await problem.hasMultipleSolutions());
  }

  /// V3: per-cell candidate sets. For each empty cell, returns the
  /// digits 1..N that don't already appear in the same row,
  /// column, box, or — for Sudoku-X — diagonals. Pre-filled (clue)
  /// cells return the empty set. Pure Dart — no bridge / solver
  /// call needed, so it's cheap enough to recompute on every cell
  /// edit when the user has "Show hints" enabled.
  ///
  /// This is the naive single-pass elimination (sometimes called
  /// "naked candidates"). The dart_csp AC-3 pass would produce
  /// strictly tighter sets in some puzzles, but routing through
  /// the bridge for every keystroke isn't free; the V4 follow-up
  /// could expose the AC-3-pruned version as an opt-in
  /// "advanced hints" level.
  static List<Set<int>> computeCandidates(SudokuPuzzle puzzle) {
    final layout = puzzle.layout;
    final n = layout.side;
    final all = {for (var v = 1; v <= n; v++) v};
    final out = List<Set<int>>.generate(n * n, (_) => <int>{});

    // Pre-compute which values appear in each row, column, and box
    // so the per-cell candidate lookup is O(1).
    final rowUsed = List<Set<int>>.generate(n, (_) => <int>{});
    final colUsed = List<Set<int>>.generate(n, (_) => <int>{});
    final boxUsed = <int, Set<int>>{};
    final mainDiagUsed = <int>{};
    final antiDiagUsed = <int>{};

    int boxKey(int r, int c) {
      final br = r ~/ layout.boxRows;
      final bc = c ~/ layout.boxCols;
      return br * layout.boxCols + bc;
    }

    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final v = puzzle.cells[r * n + c];
        if (v == 0) continue;
        rowUsed[r].add(v);
        colUsed[c].add(v);
        boxUsed.putIfAbsent(boxKey(r, c), () => <int>{}).add(v);
        if (puzzle.variant == SudokuVariant.x) {
          if (r == c) mainDiagUsed.add(v);
          if (r + c == n - 1) antiDiagUsed.add(v);
        }
      }
    }

    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (puzzle.cells[r * n + c] != 0) continue;
        final excluded = <int>{
          ...rowUsed[r],
          ...colUsed[c],
          ...?boxUsed[boxKey(r, c)],
          if (puzzle.variant == SudokuVariant.x && r == c) ...mainDiagUsed,
          if (puzzle.variant == SudokuVariant.x && r + c == n - 1)
            ...antiDiagUsed,
        };
        out[r * n + c] = all.difference(excluded);
      }
    }
    return out;
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
    // V2: Sudoku-X overlay. Two more `allDifferent` constraints,
    // one per diagonal. Composes with everything above —
    // dart_csp's propagator handles the extra constraints with no
    // engine-side changes.
    if (puzzle.variant == SudokuVariant.x) {
      p.addAllDifferent(
          [for (var i = 0; i < n; i++) _key(i, i)]); // main diagonal
      p.addAllDifferent(
          [for (var i = 0; i < n; i++) _key(i, n - 1 - i)]); // anti-diagonal
    }
    // Killer Sudoku (round 63): each cage adds two constraints —
    // `allDifferent` on its cells (no digit repeats within a
    // cage) and `addLinearEquals` with all-1 coefficients
    // summing to the cage's target. The linear-arithmetic
    // propagator handles the sum efficiently (same path that
    // makes SEND+MORE solve in ms).
    //
    // Round 64: SKIP the cage allDifferent when it's already
    // implied by an existing row/column/box allDifferent (cage
    // is entirely within one row, one column, or one box).
    // Adding the redundant constraint exposes a propagation
    // pathology in dart_csp's GAC propagator that incorrectly
    // prunes valid solutions when multiple allDifferents share
    // the same variable subset.
    if (puzzle.cages != null) {
      final boxRows = puzzle.layout.boxRows;
      final boxCols = puzzle.layout.boxCols;
      for (final cage in puzzle.cages!) {
        final keys = [
          for (final idx in cage.cellIndexes) _key(idx ~/ n, idx % n),
        ];
        if (keys.length > 1) {
          final rows = {for (final i in cage.cellIndexes) i ~/ n};
          final cols = {for (final i in cage.cellIndexes) i % n};
          final boxes = {
            for (final i in cage.cellIndexes)
              (i ~/ n ~/ boxRows) * (n ~/ boxCols) + (i % n ~/ boxCols)
          };
          final redundant =
              rows.length == 1 || cols.length == 1 || boxes.length == 1;
          if (!redundant) {
            p.addAllDifferent(keys);
          }
        }
        p.addLinearEquals(
          keys,
          List<num>.filled(keys.length, 1),
          cage.targetSum,
        );
      }
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
    SudokuVariant variant = SudokuVariant.regular,
    int? seed,
  }) async {
    final rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final n = layout.side;

    // === Stage 1: full grid ===============================================
    // Seed with one random clue so the solver doesn't always return
    // the same canonical grid. We pick an arbitrary cell and value;
    // dart_csp completes the rest under the same [variant] the
    // user will solve under (matters for Sudoku-X — the diagonals
    // already need to be consistent in the full grid).
    final seedRow = rng.nextInt(n);
    final seedCol = rng.nextInt(n);
    final seedVal = 1 + rng.nextInt(n);
    final seedPuzzle = SudokuPuzzle(
      layout: layout,
      cells: List<int>.filled(n * n, 0),
      variant: variant,
    ).withCell(seedRow, seedCol, seedVal);
    final full = await SudokuSolver.solve(seedPuzzle);
    if (full == null) {
      // Vanishingly unlikely (a single clue can't conflict with
      // anything), but degrade gracefully by retrying with a
      // different seed.
      return generate(
          layout: layout,
          difficulty: difficulty,
          variant: variant,
          seed: rng.nextInt(1 << 31));
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
      final candidate =
          SudokuPuzzle(layout: layout, cells: cells, variant: variant);
      final ambiguous = await _hasMultipleSolutions(candidate);
      if (ambiguous) {
        cells[idx] = saved;
      } else {
        remainingClues--;
      }
    }

    return SudokuPuzzle(layout: layout, cells: cells, variant: variant);
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
    // PLAN.md notes): 4×4 minimum is 4 clues, 6×6 minimum is 8,
    // 9×9 minimum is 17, 16×16 known-low is 55. We pad above the
    // minimum for "easy" so the puzzle is approachable; sit near
    // (but not at) the minimum for "hard" because peeling to the
    // exact minimum often blows the per-call time budget.
    switch (layout.side) {
      case 4:
        switch (difficulty) {
          case SudokuDifficulty.easy:
            return 10;
          case SudokuDifficulty.medium:
            return 7;
          case SudokuDifficulty.hard:
            return 4;
        }
      case 6:
        switch (difficulty) {
          case SudokuDifficulty.easy:
            return 18;
          case SudokuDifficulty.medium:
            return 13;
          case SudokuDifficulty.hard:
            return 9;
        }
      case 16:
        // 16×16 generation is heavy — keep the target high so the
        // peel loop terminates within a reasonable per-call time.
        switch (difficulty) {
          case SudokuDifficulty.easy:
            return 180;
          case SudokuDifficulty.medium:
            return 140;
          case SudokuDifficulty.hard:
            return 100;
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

  // V2: 6×6 medium peeled from the canonical full grid
  //   1 2 3 4 5 6 / 4 5 6 1 2 3 / 2 3 1 5 6 4 /
  //   5 6 4 2 3 1 / 3 1 2 6 4 5 / 6 4 5 3 1 2
  // 18 clues — exercises some search but solves in milliseconds.
  static final SudokuPuzzle medium6x6 = SudokuPuzzle(
    layout: SudokuLayout.medium,
    cells: [
      1,
      0,
      3,
      0,
      5,
      0,
      0,
      5,
      0,
      1,
      0,
      3,
      2,
      0,
      1,
      0,
      6,
      0,
      0,
      6,
      0,
      2,
      0,
      1,
      3,
      0,
      2,
      0,
      4,
      0,
      0,
      4,
      0,
      3,
      0,
      2,
    ],
  );

  // Note: no Sudoku-X preset ships. Off-the-shelf 9×9 puzzles
  // tend to have completions whose main / anti-diagonals contain
  // duplicate digits — fine under regular rules, infeasible
  // under the X overlay. Users get X-variant puzzles via the
  // variant toggle + Generate.

  // === Killer Sudoku presets (round 63) ============================
  //
  // Each preset has an empty cells list (Killer puzzles have no
  // clue digits — the cages carry the information) plus a list
  // of cages that partition every cell into exactly one group.

  /// 4×4 Killer derived from the canonical full grid
  ///   1 2 3 4 / 3 4 1 2 / 2 1 4 3 / 4 3 2 1.
  /// 8 cages partition all 16 cells; one singleton (the upper-
  /// right cell, value 4) acts as a starter clue.
  static final SudokuPuzzle killer4x4 = SudokuPuzzle(
    layout: SudokuLayout.small,
    variant: SudokuVariant.killer,
    cells: List<int>.filled(16, 0),
    cages: const [
      // Indices are row-major: r*4 + c.
      KillerCage(cellIndexes: [0, 4], targetSum: 4), //  (0,0)+(1,0) = 1+3
      KillerCage(cellIndexes: [1, 2], targetSum: 5), //  (0,1)+(0,2) = 2+3
      KillerCage(cellIndexes: [3], targetSum: 4), //     (0,3)       = 4
      KillerCage(
          cellIndexes: [5, 6, 7], targetSum: 7), // (1,1)+(1,2)+(1,3) = 4+1+2
      KillerCage(cellIndexes: [8, 9], targetSum: 3), //  (2,0)+(2,1) = 2+1
      KillerCage(cellIndexes: [10, 11], targetSum: 7), // (2,2)+(2,3) = 4+3
      KillerCage(cellIndexes: [12, 13], targetSum: 7), // (3,0)+(3,1) = 4+3
      KillerCage(cellIndexes: [14, 15], targetSum: 3), // (3,2)+(3,3) = 2+1
    ],
  );

  /// 9×9 Killer derived from a canonical solved grid. The cage
  /// partition uses horizontal 2/3-cell groups (4 cages per row,
  /// 36 cages total). Each row's cage sums total 45 (= 1+2+…+9).
  /// Ships with no givens — solving relies entirely on the cage
  /// sum + all-different constraints + Sudoku rules. Note: this
  /// preset is FEASIBLE rather than provably unique under cages
  /// alone — proper uniqueness for 9×9 Killer requires irregular
  /// cage shapes that cut across rows, deferred to V2.
  static final SudokuPuzzle killer9x9 = SudokuPuzzle(
    layout: SudokuLayout.standard,
    variant: SudokuVariant.killer,
    cells: List<int>.filled(81, 0),
    cages: const [
      // Row 0: 5 3 4 6 7 8 9 1 2 — sum 45 = 8+17+17+3
      KillerCage(cellIndexes: [0, 1], targetSum: 8),
      KillerCage(cellIndexes: [2, 3, 4], targetSum: 17),
      KillerCage(cellIndexes: [5, 6], targetSum: 17),
      KillerCage(cellIndexes: [7, 8], targetSum: 3),
      // Row 1: 6 7 2 1 9 5 3 4 8 — sum 45 = 13+3+17+12
      KillerCage(cellIndexes: [9, 10], targetSum: 13),
      KillerCage(cellIndexes: [11, 12], targetSum: 3),
      KillerCage(cellIndexes: [13, 14, 15], targetSum: 17),
      KillerCage(cellIndexes: [16, 17], targetSum: 12),
      // Row 2: 1 9 8 3 4 2 5 6 7 — sum 45 = 18+7+7+13
      KillerCage(cellIndexes: [18, 19, 20], targetSum: 18),
      KillerCage(cellIndexes: [21, 22], targetSum: 7),
      KillerCage(cellIndexes: [23, 24], targetSum: 7),
      KillerCage(cellIndexes: [25, 26], targetSum: 13),
      // Row 3: 8 5 9 7 6 1 4 2 3 — sum 45 = 13+16+7+9
      KillerCage(cellIndexes: [27, 28], targetSum: 13),
      KillerCage(cellIndexes: [29, 30], targetSum: 16),
      KillerCage(cellIndexes: [31, 32], targetSum: 7),
      KillerCage(cellIndexes: [33, 34, 35], targetSum: 9),
      // Row 4: 4 2 6 8 5 3 7 9 1 — sum 45 = 12+13+10+10
      KillerCage(cellIndexes: [36, 37, 38], targetSum: 12),
      KillerCage(cellIndexes: [39, 40], targetSum: 13),
      KillerCage(cellIndexes: [41, 42], targetSum: 10),
      KillerCage(cellIndexes: [43, 44], targetSum: 10),
      // Row 5: 7 1 3 9 2 4 8 5 6 — sum 45 = 8+14+12+11
      KillerCage(cellIndexes: [45, 46], targetSum: 8),
      KillerCage(cellIndexes: [47, 48, 49], targetSum: 14),
      KillerCage(cellIndexes: [50, 51], targetSum: 12),
      KillerCage(cellIndexes: [52, 53], targetSum: 11),
      // Row 6: 9 6 1 5 3 7 2 8 4 — sum 45 = 15+6+12+12
      KillerCage(cellIndexes: [54, 55], targetSum: 15),
      KillerCage(cellIndexes: [56, 57], targetSum: 6),
      KillerCage(cellIndexes: [58, 59, 60], targetSum: 12),
      KillerCage(cellIndexes: [61, 62], targetSum: 12),
      // Row 7: 2 8 7 4 1 9 6 3 5 — sum 45 = 17+5+15+8
      KillerCage(cellIndexes: [63, 64, 65], targetSum: 17),
      KillerCage(cellIndexes: [66, 67], targetSum: 5),
      KillerCage(cellIndexes: [68, 69], targetSum: 15),
      KillerCage(cellIndexes: [70, 71], targetSum: 8),
      // Row 8: 3 4 5 2 8 6 1 7 9 — sum 45 = 7+7+14+17
      KillerCage(cellIndexes: [72, 73], targetSum: 7),
      KillerCage(cellIndexes: [74, 75], targetSum: 7),
      KillerCage(cellIndexes: [76, 77], targetSum: 14),
      KillerCage(cellIndexes: [78, 79, 80], targetSum: 17),
    ],
  );

  /// Friendly preset list with (id, layout) pairs the picker uses.
  static final List<({String id, SudokuPuzzle puzzle})> all = [
    (id: 'small4x4Easy', puzzle: small4x4Easy),
    (id: 'small4x4Medium', puzzle: small4x4Medium),
    (id: 'small4x4Hard', puzzle: small4x4Hard),
    (id: 'medium6x6', puzzle: medium6x6),
    (id: 'standard9x9Easy', puzzle: standard9x9Easy),
    (id: 'standard9x9Medium', puzzle: standard9x9Medium),
    (id: 'standard9x9Hard', puzzle: standard9x9Hard),
    (id: 'killer4x4', puzzle: killer4x4),
    (id: 'killer9x9', puzzle: killer9x9),
  ];
}
