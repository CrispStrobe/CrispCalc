// lib/screens/sudoku_screen.dart
//
// Analysis-hub Sudoku module. UX flow:
//
//   1. User picks a preset puzzle (size + difficulty) OR taps cells
//      to enter their own clues.
//   2. Solve button kicks off a trace solve via [SudokuSolver]
//      that records every search decision.
//   3. When recording finishes, the visualizer replays the trace
//      at a user-controlled speed (Slow / Med / Fast) with
//      play / pause / restart controls. The just-changed cell
//      gets a brief tint per frame.
//
// V1 supports 4×4 and 9×9 grids. PLAN.md tracks the variant
// roadmap (6×6, 8×8, 10×10, 12×12, 15×15, 16×16, 25×25,
// irregular regions, killer).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/app_state.dart';
import '../engine/sudoku.dart';
import '../localization/app_localizations.dart';
import '../widgets/sudoku_grid.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  // Round 95 (P6): the field initialiser stays on `standard9x9Easy`
  // so the existing "open without args" entry point is unchanged.
  // `initState` may overwrite this if the user got here via an
  // `open:sudoku?preset=<id>` worked-example sentinel.
  SudokuPuzzle _puzzle = SudokuPresets.standard9x9Easy;
  // Clues are captured at puzzle load so the visualizer can tell
  // user/preset values apart from solver-filled ones. Round 87:
  // NEVER re-captured on user edit — before round 87, every user
  // entry was being added to _clueIndexes so the user couldn't
  // overwrite their own digits.
  late Set<int> _clueIndexes = _captureClueIndexes(_puzzle);
  // Round 87: cells of the puzzle as last loaded (preset /
  // generated / layout-switched). Used by "clear to start" and by
  // the win-check (which compares _displayed to the unique
  // solution of _baseCells, not the live-edited _puzzle.cells).
  late List<int> _baseCells = List<int>.from(_puzzle.cells);
  // Live editable cells. Mutated by tap-to-enter and by the
  // visualizer when replaying frames.
  late List<int> _displayed = List<int>.from(_puzzle.cells);

  /// Round 87: the unique solution to the puzzle as last loaded
  /// (i.e. to [_baseCells]). Used by the win-check chip. Null on
  /// load; populated lazily when the user first completes the grid.
  /// Invalidated to null on every preset / generate / layout switch.
  List<int>? _solution;
  bool _computingSolution = false;

  /// Round 87b: whether the user has dismissed the current win
  /// celebration overlay. Reset to false on every edit / clear /
  /// preset switch so a fresh win shows the overlay again.
  bool _winOverlayDismissed = false;

  /// Round 87: focus node for cell-keyboard input. When a cell is
  /// selected, pressing a digit key fills it; Backspace / Delete /
  /// 0 clears it; arrow keys move the selection.
  final FocusNode _keyboardFocus = FocusNode();

  int? _selected;
  SudokuTrace? _trace;
  int _frameIndex = 0;
  Timer? _ticker;
  bool _playing = false;
  bool _solving = false;
  bool _generating = false;
  SudokuHintLevel _hintLevel = SudokuHintLevel.off;
  // Advanced (SAC-pruned) candidates for the current displayed grid.
  // Null when not yet computed for the current grid. Lifecycle:
  //   - Invalidated to null on any puzzle / displayed-cells change.
  //   - Recomputed asynchronously when [_hintLevel] is advanced.
  //   - The request-id pattern below cancels stale in-flight
  //     computes so a fast sequence of edits only commits the
  //     latest result.
  List<Set<int>>? _advancedCandidates;
  bool _computingAdvanced = false;
  int _advancedRequestId = 0;
  SudokuDifficulty _genDifficulty = SudokuDifficulty.medium;
  _Speed _speed = _Speed.medium;

  /// Round 65: uniqueness check result for the *currently displayed*
  /// puzzle. Null when not yet computed (or cleared on any edit /
  /// preset switch). True = exactly one solution; false = zero or
  /// many. The check is opt-in via a "Check uniqueness" button
  /// because for non-unique 9×9 (e.g. killer9x9) it can take
  /// seconds to confirm.
  bool? _unique;
  bool _checkingUnique = false;

  /// V2: when the user picks a different size or variant via the
  /// top selectors (not via a preset), we wipe the grid. Round 87:
  /// instead of falling to an empty grid, look for a preset
  /// matching the new (layout, variant) first — so the "Rätsel"
  /// dropdown stays in sync. Only when no preset exists for the
  /// combination do we fall through to an empty grid (which lets
  /// the user compose their own).
  ///
  /// V3-Killer: an empty Killer puzzle is invalid (the cages
  /// list is required), so Killer mode always loads a preset.
  void _switchLayoutOrVariant(
      SudokuLayout? newLayout, SudokuVariant? newVariant) {
    _stopVisualizer();
    final layout = newLayout ?? _puzzle.layout;
    final variant = newVariant ?? _puzzle.variant;
    // Round 87: try to find a preset that matches the new (layout,
    // variant) exactly. If found, load it — keeps the preset
    // dropdown showing the active entry. Falls through to an empty
    // grid only when no preset matches the combination.
    final match = SudokuPresets.all.where((p) =>
        p.puzzle.layout.side == layout.side && p.puzzle.variant == variant);
    if (match.isNotEmpty) {
      _loadPreset(match.first.puzzle);
      return;
    }
    if (variant == SudokuVariant.killer) {
      // Killer can't be empty — fall back to any Killer preset.
      final any = SudokuPresets.all
          .firstWhere((p) => p.puzzle.variant == SudokuVariant.killer);
      _loadPreset(any.puzzle);
      return;
    }
    final empty = SudokuPuzzle(
      layout: layout,
      cells: List<int>.filled(layout.side * layout.side, 0),
      variant: variant,
    );
    setState(() {
      _puzzle = empty;
      _baseCells = List<int>.from(empty.cells);
      _clueIndexes = {};
      _displayed = List<int>.from(empty.cells);
      _selected = null;
      _trace = null;
      _frameIndex = 0;
      _unique = null;
      _solution = null;
      _winOverlayDismissed = false;
      _advancedCandidates = null;
    });
    _maybeRecomputeAdvanced();
  }

  @override
  void initState() {
    super.initState();
    // Round 95 (P6): drain a pending sudoku preset id stashed by
    // a worked-example `open:sudoku?preset=<id>` sentinel. Match
    // against `SudokuPresets.all` and replace the default puzzle
    // before the first build. Unknown ids degrade gracefully —
    // the field initialiser's standard9x9Easy stays in effect.
    final pendingPreset = AppState().consumePendingSudokuPresetId();
    if (pendingPreset != null) {
      for (final entry in SudokuPresets.all) {
        if (entry.id == pendingPreset) {
          _puzzle = entry.puzzle;
          _baseCells = List<int>.from(_puzzle.cells);
          _clueIndexes = _captureClueIndexes(_puzzle);
          _displayed = List<int>.from(_puzzle.cells);
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _keyboardFocus.dispose();
    super.dispose();
  }

  Set<int> _captureClueIndexes(SudokuPuzzle p) => {
        for (var i = 0; i < p.cells.length; i++)
          if (p.cells[i] != 0) i,
      };

  void _loadPreset(SudokuPuzzle p) {
    _stopVisualizer();
    setState(() {
      _puzzle = p;
      _baseCells = List<int>.from(p.cells);
      _clueIndexes = _captureClueIndexes(p);
      _displayed = List<int>.from(p.cells);
      _selected = null;
      _trace = null;
      _frameIndex = 0;
      _unique = null;
      _solution = null;
      _winOverlayDismissed = false;
      _advancedCandidates = null;
    });
    _maybeRecomputeAdvanced();
  }

  void _onTapCell(int idx) {
    setState(() => _selected = idx);
    // Round 87: keep keyboard focus on the screen so digit keys
    // route to _setDigit rather than getting lost.
    _keyboardFocus.requestFocus();
  }

  /// Round 87: write digit [d] (or clear, when null/0) into the
  /// currently selected cell. Originally re-captured _clueIndexes
  /// on every edit so user entries became un-editable clues — the
  /// re-capture is now removed. _clueIndexes only changes via
  /// _loadPreset / _generate / _switchLayoutOrVariant.
  void _setDigit(int? d) {
    final sel = _selected;
    if (sel == null) return;
    if (_clueIndexes.contains(sel)) return; // preset clue — read-only
    setState(() {
      _displayed[sel] = d ?? 0;
      _puzzle = _puzzle.withCell(
          sel ~/ _puzzle.layout.side, sel % _puzzle.layout.side, d ?? 0);
      _trace = null;
      _frameIndex = 0;
      _unique = null;
      _advancedCandidates = null;
      // Round 87b: the user is editing again — a previous win was
      // dismissed; if they re-complete the grid (e.g. fix an
      // error), show the celebration overlay again.
      _winOverlayDismissed = false;
    });
    _maybeRecomputeAdvanced();
    _maybeCheckWin();
  }

  /// Round 87: invoked by [DragTarget<int>] on a cell when the user
  /// drops a digit from the [_DigitPad]. The selection moves to
  /// the drop target so subsequent keyboard input lands on the
  /// same cell.
  void _onDropDigitOnCell(int idx, int? digit) {
    if (_clueIndexes.contains(idx)) return;
    setState(() => _selected = idx);
    _setDigit(digit);
  }

  /// Round 87: clear the user's edits and restore the puzzle to
  /// the cells it had at load time. Clues remain (they're part of
  /// _baseCells); only user-entered digits are wiped.
  void _clearToStart() {
    _stopVisualizer();
    setState(() {
      _displayed = List<int>.from(_baseCells);
      _puzzle = SudokuPuzzle(
        layout: _puzzle.layout,
        cells: List<int>.from(_baseCells),
        variant: _puzzle.variant,
        cages: _puzzle.cages,
      );
      _trace = null;
      _frameIndex = 0;
      _selected = null;
      _advancedCandidates = null;
    });
    _maybeRecomputeAdvanced();
  }

  Future<void> _generate() async {
    _stopVisualizer();
    setState(() => _generating = true);
    // Use the current puzzle's layout as the target so the user's
    // 4×4 / 9×9 selection drives generation too.
    final puzzle = await SudokuGenerator.generate(
      layout: _puzzle.layout,
      difficulty: _genDifficulty,
      variant: _puzzle.variant,
    );
    if (!mounted) return;
    setState(() {
      _generating = false;
      _puzzle = puzzle;
      _baseCells = List<int>.from(puzzle.cells);
      _clueIndexes = _captureClueIndexes(puzzle);
      _displayed = List<int>.from(puzzle.cells);
      _selected = null;
      _trace = null;
      _frameIndex = 0;
      _unique = null;
      _solution = null;
      _winOverlayDismissed = false;
      _advancedCandidates = null;
    });
    _maybeRecomputeAdvanced();
  }

  /// Round 87: kicks off step-by-step solver visualization. Before
  /// this round, _solve set the trace and stopped at frame 0 — the
  /// user had to know to press play. Now we auto-start the ticker
  /// so "Lösen" produces visible motion immediately.
  Future<void> _solve() async {
    _stopVisualizer();
    setState(() => _solving = true);
    final trace = await SudokuSolver.solveWithTrace(_puzzle);
    if (!mounted) return;
    setState(() {
      _solving = false;
      _trace = trace;
      _frameIndex = 0;
      if (trace.frames.isNotEmpty) {
        _displayed = List<int>.from(trace.frames.first.assigned);
      }
    });
    // Round 87: auto-play so the user sees the solver fill the
    // grid step-by-step. Skip auto-play when the solve failed
    // (no frames / error) so we don't spin an empty ticker.
    if (trace.solved && trace.frames.length > 1) {
      _playPause();
    }
  }

  /// Round 87: win-check chip. Lazy-solves [_baseCells] on the
  /// first call and caches the result in [_solution]; subsequent
  /// calls are O(N) comparison only. Triggered after every
  /// [_setDigit] so the chip lights up the instant the user
  /// completes the grid.
  ///
  /// Returns silently when the trace is active (visualizer
  /// playback) or when the grid still has empty cells.
  Future<void> _maybeCheckWin() async {
    if (_trace != null) return;
    if (_displayed.any((v) => v == 0)) return;
    if (_solution == null) {
      if (_computingSolution) return;
      setState(() => _computingSolution = true);
      final base = SudokuPuzzle(
        layout: _puzzle.layout,
        cells: List<int>.from(_baseCells),
        variant: _puzzle.variant,
        cages: _puzzle.cages,
      );
      final solved = await SudokuSolver.solve(base);
      if (!mounted) return;
      setState(() {
        _computingSolution = false;
        _solution = solved;
      });
    }
    // After lazy solve, re-check the displayed grid (it may have
    // been edited during the await).
    if (_displayed.any((v) => v == 0)) return;
    setState(() {}); // rebuild to surface the chip
  }

  /// Round 87: true when the displayed grid is fully filled AND
  /// matches the cached solution. False when fully filled but
  /// wrong; null when not yet evaluable (empty cells, no solution
  /// cached, or trace active).
  bool? get _winStatus {
    if (_trace != null) return null;
    if (_displayed.any((v) => v == 0)) return null;
    final sol = _solution;
    if (sol == null) return null;
    for (var i = 0; i < _displayed.length; i++) {
      if (_displayed[i] != sol[i]) return false;
    }
    return true;
  }

  Future<void> _checkUnique() async {
    setState(() => _checkingUnique = true);
    // Capture the puzzle snapshot at click time so a later edit
    // doesn't attribute the result to a different state.
    final snapshot = _puzzle;
    final result = await SudokuSolver.hasUniqueSolution(snapshot);
    if (!mounted) return;
    // Only commit the result if the puzzle hasn't changed in the
    // meantime — otherwise the indicator would be misleading.
    if (!identical(_puzzle, snapshot)) {
      setState(() => _checkingUnique = false);
      return;
    }
    setState(() {
      _checkingUnique = false;
      _unique = result;
    });
  }

  /// Switches the hint level. Off and basic are pure UI decisions
  /// (rendering branches off `_hintLevel`); advanced additionally
  /// kicks off the async SAC-pruning compute below.
  void _setHintLevel(SudokuHintLevel level) {
    setState(() {
      _hintLevel = level;
      // Drop any cached advanced result so a flip to advanced
      // forces a fresh compute against the current grid (rather
      // than briefly flashing a stale set from a previous puzzle).
      _advancedCandidates = null;
    });
    _maybeRecomputeAdvanced();
  }

  /// Recompute advanced hints if (and only if) advanced mode is on
  /// and the visualizer isn't replaying a trace. Uses a monotonic
  /// request id so a sequence of quick edits cancels stale results
  /// — only the latest in-flight compute commits to state.
  ///
  /// dart_csp doesn't expose mid-search cancellation, so a busy
  /// solve still runs to completion; we just drop its result.
  Future<void> _maybeRecomputeAdvanced() async {
    if (_hintLevel != SudokuHintLevel.advanced || _trace != null) {
      return;
    }
    final id = ++_advancedRequestId;
    setState(() => _computingAdvanced = true);
    final livePuzzle = SudokuPuzzle(
      layout: _puzzle.layout,
      cells: _displayed,
      variant: _puzzle.variant,
      cages: _puzzle.cages,
    );
    final result = await SudokuSolver.computeCandidatesPruned(livePuzzle);
    if (!mounted || id != _advancedRequestId) return;
    setState(() {
      _computingAdvanced = false;
      _advancedCandidates = result;
    });
  }

  void _stopVisualizer() {
    _ticker?.cancel();
    _ticker = null;
    _playing = false;
  }

  void _playPause() {
    if (_trace == null) return;
    if (_playing) {
      setState(_stopVisualizer);
      return;
    }
    // If we're at the end, snap to start so play starts fresh.
    if (_frameIndex >= _trace!.frames.length - 1) {
      _frameIndex = 0;
      _displayed = List<int>.from(_trace!.frames.first.assigned);
    }
    setState(() => _playing = true);
    _ticker = Timer.periodic(_speed.interval, (_) => _advance());
  }

  void _advance() {
    if (_trace == null) return;
    if (_frameIndex >= _trace!.frames.length - 1) {
      setState(_stopVisualizer);
      return;
    }
    setState(() {
      _frameIndex++;
      _displayed = List<int>.from(_trace!.frames[_frameIndex].assigned);
    });
  }

  void _restart() {
    if (_trace == null) return;
    setState(() {
      _stopVisualizer();
      _frameIndex = 0;
      _displayed = List<int>.from(_trace!.frames.first.assigned);
    });
  }

  void _setSpeed(_Speed s) {
    setState(() => _speed = s);
    if (_playing) {
      _ticker?.cancel();
      _ticker = Timer.periodic(s.interval, (_) => _advance());
    }
  }

  /// Round 87: keyboard handler. Digit keys (1..9, plus 0 = clear)
  /// fill the selected cell. Backspace / Delete also clear. Arrow
  /// keys move the selection. Returns "handled" so the event
  /// doesn't bubble to other listeners (e.g. the AppBar).
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final side = _puzzle.layout.side;

    // Digit input: '1'..'9' + numpad. For 16×16 the user reaches
    // 10..16 via drag-and-drop from the digit pad (single-key
    // 10..16 is ambiguous on a regular keyboard).
    const digitKeys = <(int, LogicalKeyboardKey, LogicalKeyboardKey)>[
      (1, LogicalKeyboardKey.digit1, LogicalKeyboardKey.numpad1),
      (2, LogicalKeyboardKey.digit2, LogicalKeyboardKey.numpad2),
      (3, LogicalKeyboardKey.digit3, LogicalKeyboardKey.numpad3),
      (4, LogicalKeyboardKey.digit4, LogicalKeyboardKey.numpad4),
      (5, LogicalKeyboardKey.digit5, LogicalKeyboardKey.numpad5),
      (6, LogicalKeyboardKey.digit6, LogicalKeyboardKey.numpad6),
      (7, LogicalKeyboardKey.digit7, LogicalKeyboardKey.numpad7),
      (8, LogicalKeyboardKey.digit8, LogicalKeyboardKey.numpad8),
      (9, LogicalKeyboardKey.digit9, LogicalKeyboardKey.numpad9),
    ];
    for (final entry in digitKeys) {
      final (digit, top, numpad) = entry;
      if (digit > side) break;
      if (key == top || key == numpad) {
        _setDigit(digit);
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.digit0 ||
        key == LogicalKeyboardKey.numpad0 ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _setDigit(null);
      return KeyEventResult.handled;
    }
    // Arrow keys move the selection by one cell.
    final sel = _selected;
    if (sel != null) {
      var r = sel ~/ side, c = sel % side;
      if (key == LogicalKeyboardKey.arrowLeft && c > 0) {
        setState(() => _selected = r * side + (c - 1));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight && c < side - 1) {
        setState(() => _selected = r * side + (c + 1));
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp && r > 0) {
        setState(() => _selected = (r - 1) * side + c);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown && r < side - 1) {
        setState(() => _selected = (r + 1) * side + c);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final layout = _puzzle.layout;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final highlightIdx =
        _trace == null ? null : _trace!.frames[_frameIndex].justChangedIndex;

    // V3/Round 73: pencil-mark candidates per empty cell against
    // the *displayed* grid. Always disabled while the visualizer is
    // replaying a trace (two competing "what's in this cell"
    // overlays is confusing).
    //
    //   - `basic` runs the cheap synchronous eliminator on every
    //     build, so candidates stay live as the user edits.
    //   - `advanced` uses the SAC-pruned set cached in
    //     `_advancedCandidates`. While that's being recomputed
    //     (after an edit or a level flip) we fall back to the basic
    //     set so the grid never blanks — the spinner subtitle below
    //     tells the user a tighter set is on the way.
    List<Set<int>>? candidates;
    if (_hintLevel != SudokuHintLevel.off && _trace == null) {
      final livePuzzle = SudokuPuzzle(
        layout: layout,
        cells: _displayed,
        variant: _puzzle.variant,
        cages: _puzzle.cages,
      );
      if (_hintLevel == SudokuHintLevel.advanced &&
          _advancedCandidates != null) {
        candidates = _advancedCandidates;
      } else {
        candidates = SudokuSolver.computeCandidates(livePuzzle);
      }
    }

    // Round 88: compute conflicts against the live displayed grid
    // so the SudokuGrid can red-wash any cell participating in a
    // constraint violation. Skip during visualizer playback (the
    // mid-frame solver state legitimately has duplicates the user
    // shouldn't see flagged).
    final conflicts = _trace == null
        ? SudokuSolver.computeConflicts(_puzzle, _displayed)
        : const <int>{};

    // Round 87b: stack the grid + an animated win-celebration
    // overlay. The overlay appears when [_winStatus == true] and
    // the user hasn't dismissed it; it fades + scales in from
    // half-size for a celebratory pop. Tap to dismiss.
    final gridBlock = Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          SudokuGrid(
            layout: layout,
            cells: _displayed,
            clueIndexes: _clueIndexes,
            selectedIndex: _selected,
            highlightIndex: highlightIdx,
            candidates: candidates,
            cages: _puzzle.cages,
            onTapCell: _onTapCell,
            // Round 87: drag-and-drop digit entry from the digit
            // pad. Non-null digit fills the cell; null clears it.
            // Wired only when the visualizer isn't active.
            onDropDigit: _trace == null ? _onDropDigitOnCell : null,
            conflictIndexes: conflicts,
          ),
          if (_winStatus == true && !_winOverlayDismissed)
            Positioned.fill(
              child: _WinOverlay(
                label: t.sudokuSolvedCorrectly,
                onDismiss: () => setState(() => _winOverlayDismissed = true),
              ),
            ),
        ],
      ),
    );

    final controlsBlock = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SizeVariantPickers(
            layout: _puzzle.layout,
            variant: _puzzle.variant,
            onLayoutChanged: (l) => _switchLayoutOrVariant(l, null),
            onVariantChanged: (v) => _switchLayoutOrVariant(null, v),
            labels: t,
          ),
          const SizedBox(height: 12),
          _PresetPicker(
            current: _puzzle,
            onPick: _loadPreset,
            labelOf: (p) => _localizedPresetLabel(t, p),
          ),
          const SizedBox(height: 12),
          _GeneratorRow(
            difficulty: _genDifficulty,
            generating: _generating,
            // Killer generation isn't shipped in V1 — cage
            // partition + per-cage sum is a separate solver
            // pass. Keep the controls visible but disabled so
            // the UX is consistent across variants.
            disabled: _puzzle.variant == SudokuVariant.killer,
            onDifficulty: (d) => setState(() => _genDifficulty = d),
            onGenerate: _generate,
            labels: t,
          ),
          const SizedBox(height: 16),
          _DigitPad(
            side: layout.side,
            onPress: _setDigit,
          ),
          const SizedBox(height: 8),
          // Round 87: clear-to-start + win-check chip.
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _trace == null ? _clearToStart : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(t.sudokuClearToStart),
              ),
              if (_computingSolution)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (_winStatus != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _winStatus!
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  label: Text(
                    _winStatus!
                        ? t.sudokuSolvedCorrectly
                        : t.sudokuFilledWithErrors,
                    style: TextStyle(
                      color: _winStatus!
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _HintLevelPicker(
            level: _hintLevel,
            computing: _computingAdvanced,
            onChanged: _setHintLevel,
            labels: t,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _solving ? null : _solve,
            icon: _solving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(t.sudokuSolveButton),
          ),
          const SizedBox(height: 8),
          // Wrap rather than Row so a narrow right panel can flow
          // the chip below the button instead of overflowing.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: _checkingUnique ? null : _checkUnique,
                icon: _checkingUnique
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint, size: 18),
                label: Text(t.sudokuCheckUnique),
              ),
              if (_unique != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _unique!
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  label: Text(
                    _unique!
                        ? t.sudokuUniqueSolution
                        : t.sudokuMultipleSolutions,
                    style: TextStyle(
                      color: _unique!
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
          if (_trace != null) ...[
            const SizedBox(height: 16),
            _VisualizerControls(
              total: _trace!.frames.length,
              current: _frameIndex,
              playing: _playing,
              speed: _speed,
              caption: _captionForFrame(t, _trace!, _frameIndex),
              onPlayPause: _playPause,
              onRestart: _restart,
              onScrub: (i) => setState(() {
                _stopVisualizer();
                _frameIndex = i;
                _displayed = List<int>.from(_trace!.frames[i].assigned);
              }),
              onSpeed: _setSpeed,
              labels: t,
            ),
            const SizedBox(height: 8),
            if (_trace!.error != null)
              Text(_trace!.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(t.moduleSudokuTitle)),
      // Round 87: Focus + onKeyEvent wrap so digit / arrow / delete
      // keys land on _handleKey when the user has selected a cell.
      // autofocus true so the user can start typing without an
      // initial tap on the screen background.
      body: Focus(
        focusNode: _keyboardFocus,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: isWide
            ? Row(
                children: [
                  Expanded(child: gridBlock),
                  SizedBox(
                    width: 360,
                    // Round 70: the right panel got taller after the
                    // uniqueness chip + variant picker landed. Wrap in
                    // a scroll view so short windows don't overflow
                    // the column at the bottom.
                    child: SingleChildScrollView(child: controlsBlock),
                  ),
                ],
              )
            : ListView(children: [gridBlock, controlsBlock]),
      ),
    );
  }

  String _localizedPresetLabel(AppLocalizations t, SudokuPuzzle p) {
    // Match by identity — the presets are constants.
    for (final preset in SudokuPresets.all) {
      if (identical(preset.puzzle, p)) {
        return t.sudokuPresetLabel(preset.id);
      }
    }
    // Custom (user-entered) — call it "custom".
    return t.sudokuPresetCustom;
  }

  /// Round 81: format the constraint-context caption for the
  /// visualizer's current frame. Joins every overlay the just-
  /// assigned cell sits in into a " · "-separated string. Returns
  /// the localized "starting position" caption for the very first
  /// frame (no cell has changed yet).
  String _captionForFrame(
    AppLocalizations t,
    SudokuTrace trace,
    int frameIndex,
  ) {
    final frame = trace.frames[frameIndex];
    final idx = frame.justChangedIndex;
    if (idx == null) return t.sudokuConstraintStartingPosition;
    final ctx = _puzzle.contextAt(idx);
    final parts = <String>[
      t.sudokuConstraintRow(ctx.row),
      t.sudokuConstraintCol(ctx.col),
      t.sudokuConstraintBox(ctx.box),
      if (ctx.cageIndex != null && ctx.cageSum != null)
        t.sudokuConstraintCage(ctx.cageIndex!, ctx.cageSum!),
      if (ctx.onMainDiagonal) t.sudokuConstraintMainDiagonal,
      if (ctx.onAntiDiagonal) t.sudokuConstraintAntiDiagonal,
      if (ctx.disjointGroup != null)
        t.sudokuConstraintDisjointGroup(ctx.disjointGroup!),
    ];
    return parts.join(' · ');
  }
}

enum _Speed {
  slow(Duration(milliseconds: 800)),
  medium(Duration(milliseconds: 250)),
  fast(Duration(milliseconds: 50));

  final Duration interval;
  const _Speed(this.interval);
}

/// Round 73: three-level hint mode.
///
/// - `off` — no pencil marks.
/// - `basic` — sync naive elimination (rows / cols / boxes /
///   diagonals / cage residue). Cheap enough to recompute on every
///   keystroke.
/// - `advanced` — async singleton arc consistency via the dart_csp
///   solver. Catches hidden singles + naked pairs / triples that
///   the naive eliminator misses, at the cost of seconds-per-edit
///   on hard 9×9 puzzles. Opt-in only.
enum SudokuHintLevel { off, basic, advanced }

class _PresetPicker extends StatelessWidget {
  final SudokuPuzzle current;
  final ValueChanged<SudokuPuzzle> onPick;
  final String Function(SudokuPuzzle) labelOf;

  const _PresetPicker({
    required this.current,
    required this.onPick,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    // Match by identity so the dropdown shows the active preset
    // when one is loaded; render no selection ("Custom") when the
    // current puzzle was built fresh (variant/layout switch,
    // generator output, hand-entered clues). Returning a non-item
    // value here trips the DropdownButton "exactly one item with
    // this value" assertion — passing null avoids the crash.
    final matched = SudokuPresets.all
        .map((e) => e.puzzle)
        .where((p) => identical(p, current))
        .firstOrNull;
    return DropdownButtonFormField<SudokuPuzzle>(
      initialValue: matched,
      isExpanded: true, // round 70: stop long preset labels from
      // overflowing the 360 px right panel; text now ellipsises.
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).sudokuPresetLabelChooser,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final preset in SudokuPresets.all)
          DropdownMenuItem(
            value: preset.puzzle,
            child: Text(
              labelOf(preset.puzzle),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (p) {
        if (p != null) onPick(p);
      },
    );
  }
}

/// Round 87: each digit button is also a [Draggable<int>] so the
/// user can drag a digit onto a grid cell instead of select-then-tap.
/// Tapping still works for non-drag users. The clear button drags
/// a null (sentinel via [Draggable<int>] with data = 0; receiver
/// treats 0 as "clear").
class _DigitPad extends StatelessWidget {
  final int side;
  final ValueChanged<int?> onPress;

  const _DigitPad({required this.side, required this.onPress});

  Widget _digitFeedback(BuildContext context, String label) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(6),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var d = 1; d <= side; d++)
          Draggable<int>(
            data: d,
            feedback: _digitFeedback(context, '$d'),
            childWhenDragging: Opacity(
              opacity: 0.4,
              child: _digitButton(context, '$d', () => onPress(d)),
            ),
            child: _digitButton(context, '$d', () => onPress(d)),
          ),
        // Clear button — also draggable. Data 0 = "clear this cell".
        Draggable<int>(
          data: 0,
          feedback: _digitFeedback(context, t.sudokuClearCell),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: _clearButton(context, t, () => onPress(null)),
          ),
          child: _clearButton(context, t, () => onPress(null)),
        ),
      ],
    );
  }

  Widget _digitButton(BuildContext context, String label, VoidCallback onTap) =>
      SizedBox(
        width: 40,
        height: 40,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: onTap,
          child: Text(label),
        ),
      );

  Widget _clearButton(
          BuildContext context, AppLocalizations t, VoidCallback onTap) =>
      SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.clear, size: 16),
          label: Text(t.sudokuClearCell),
        ),
      );
}

class _VisualizerControls extends StatelessWidget {
  final int total;
  final int current;
  final bool playing;
  final _Speed speed;
  final String caption;
  final VoidCallback onPlayPause;
  final VoidCallback onRestart;
  final ValueChanged<int> onScrub;
  final ValueChanged<_Speed> onSpeed;
  final AppLocalizations labels;

  const _VisualizerControls({
    required this.total,
    required this.current,
    required this.playing,
    required this.speed,
    required this.caption,
    required this.onPlayPause,
    required this.onRestart,
    required this.onScrub,
    required this.onSpeed,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(labels.sudokuVisualizerHeader,
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text('${current + 1} / $total',
                  style: const TextStyle(fontFamily: 'monospace')),
            ],
          ),
          // Round 81: constraint-context caption — names the row /
          // column / box / cage / diagonal / disjoint-group overlays
          // the just-assigned cell sits in.
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Slider(
            min: 0,
            max: (total - 1).toDouble(),
            divisions: total > 1 ? total - 1 : null,
            value: current.toDouble().clamp(0, (total - 1).toDouble()),
            onChanged: (v) => onScrub(v.round()),
          ),
          // Round 87: switched from Row to Wrap. Previous Row
          // overflowed by ~135 px in the 360 px right panel
          // (restart icon + play icon + 12 px gap + 3-segment
          // speed button = ~440 px). Wrap lets the speed segments
          // flow to a second line on narrow panels.
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: labels.sudokuRestart,
                icon: const Icon(Icons.restart_alt),
                onPressed: onRestart,
              ),
              IconButton(
                tooltip: playing ? labels.sudokuPause : labels.sudokuPlay,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                onPressed: onPlayPause,
              ),
              SegmentedButton<_Speed>(
                segments: [
                  ButtonSegment(
                    value: _Speed.slow,
                    label: Text(labels.sudokuSpeedSlow),
                  ),
                  ButtonSegment(
                    value: _Speed.medium,
                    label: Text(labels.sudokuSpeedMed),
                  ),
                  ButtonSegment(
                    value: _Speed.fast,
                    label: Text(labels.sudokuSpeedFast),
                  ),
                ],
                selected: {speed},
                onSelectionChanged: (s) => onSpeed(s.first),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SizeVariantPickers extends StatelessWidget {
  final SudokuLayout layout;
  final SudokuVariant variant;
  final ValueChanged<SudokuLayout> onLayoutChanged;
  final ValueChanged<SudokuVariant> onVariantChanged;
  final AppLocalizations labels;

  const _SizeVariantPickers({
    required this.layout,
    required this.variant,
    required this.onLayoutChanged,
    required this.onVariantChanged,
    required this.labels,
  });

  String _sizeLabel(SudokuLayout l) => '${l.side}×${l.side}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Size picker — wrap so 4 segments fit on narrow phones.
        Wrap(
          spacing: 4,
          children: [
            for (final l in SudokuLayout.all)
              ChoiceChip(
                label: Text(_sizeLabel(l)),
                selected: l.side == layout.side,
                onSelected: (_) => onLayoutChanged(l),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Wrap rather than SegmentedButton so the three variant
        // labels can flow to a second line on narrow right panels
        // (round 70: the segmented version overflowed by 80+ px at
        // the standard 360 px panel width).
        Wrap(
          spacing: 4,
          children: [
            for (final v in SudokuVariant.values)
              ChoiceChip(
                label: Text(switch (v) {
                  SudokuVariant.regular => labels.sudokuVariantRegular,
                  SudokuVariant.x => labels.sudokuVariantX,
                  SudokuVariant.killer => labels.sudokuVariantKiller,
                  SudokuVariant.disjoint => labels.sudokuVariantDisjoint,
                }),
                selected: variant == v,
                onSelected: (_) => onVariantChanged(v),
              ),
          ],
        ),
      ],
    );
  }
}

class _GeneratorRow extends StatelessWidget {
  final SudokuDifficulty difficulty;
  final bool generating;
  final bool disabled;
  final ValueChanged<SudokuDifficulty> onDifficulty;
  final VoidCallback onGenerate;
  final AppLocalizations labels;

  const _GeneratorRow({
    required this.difficulty,
    required this.generating,
    required this.disabled,
    required this.onDifficulty,
    required this.onGenerate,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    // Round 70: Wrap so the difficulty picker + Generate button
    // flow onto a second line on narrow right panels rather than
    // overflowing horizontally.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: 4,
          children: [
            for (final d in SudokuDifficulty.values)
              ChoiceChip(
                label: Text(switch (d) {
                  SudokuDifficulty.easy => labels.sudokuDifficultyEasy,
                  SudokuDifficulty.medium => labels.sudokuDifficultyMedium,
                  SudokuDifficulty.hard => labels.sudokuDifficultyHard,
                }),
                selected: difficulty == d,
                onSelected: disabled ? null : (_) => onDifficulty(d),
              ),
          ],
        ),
        FilledButton.icon(
          onPressed: (generating || disabled) ? null : onGenerate,
          icon: generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.shuffle),
          label: Text(labels.sudokuGenerateButton),
        ),
      ],
    );
  }
}

/// Round 73: three-state hint-level selector replacing the V3
/// on/off switch. Chips wrap, so it survives the 360 px right
/// panel without overflow. A spinner subtitle appears while the
/// advanced level is recomputing.
class _HintLevelPicker extends StatelessWidget {
  final SudokuHintLevel level;
  final bool computing;
  final ValueChanged<SudokuHintLevel> onChanged;
  final AppLocalizations labels;

  const _HintLevelPicker({
    required this.level,
    required this.computing,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(labels.sudokuShowHints,
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            Tooltip(
              message: labels.sudokuHintLevelAdvancedHelp,
              child: Icon(
                Icons.help_outline,
                size: 18,
                color: scheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final l in SudokuHintLevel.values)
              ChoiceChip(
                label: Text(switch (l) {
                  SudokuHintLevel.off => labels.sudokuHintLevelOff,
                  SudokuHintLevel.basic => labels.sudokuHintLevelBasic,
                  SudokuHintLevel.advanced => labels.sudokuHintLevelAdvanced,
                }),
                selected: level == l,
                onSelected: (_) => onChanged(l),
              ),
          ],
        ),
        if (computing) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  labels.sudokuHintLevelComputing,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Round 87b: full-grid win celebration overlay. Fades + scales in
/// from 60% size for a celebratory "pop". Tap the backdrop or the
/// card to dismiss. Renders absolutely over the [SudokuGrid] via
/// the parent's `Stack`.
///
/// The card has a layered design: a large translucent green disk
/// behind a check icon + the localized "Solved!" text + a small
/// dismiss hint. Style is calibrated to feel celebratory without
/// looking out of place in a CAS calculator (no cartoonish
/// confetti — the green-disk pulse + a subtle scale-bounce does
/// the work).
class _WinOverlay extends StatelessWidget {
  final String label;
  final VoidCallback onDismiss;

  const _WinOverlay({required this.label, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, _) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: Container(
              color: Colors.black.withValues(alpha: 0.25 * t),
              alignment: Alignment.center,
              child: Transform.scale(
                scale: 0.6 + 0.4 * t,
                child: _WinCard(label: label, scheme: scheme),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WinCard extends StatelessWidget {
  final String label;
  final ColorScheme scheme;

  const _WinCard({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final hint = AppLocalizations.of(context).sudokuWinOverlayTapHint;
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      // Tertiary container is the green-ish accent on Material 3;
      // it stays distinct from the primary blue of the highlight
      // tint so the overlay reads as a different kind of state.
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulse disk + check icon stack.
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.30),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  size: 76,
                  color: scheme.onTertiaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: scheme.onTertiaryContainer,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onTertiaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
