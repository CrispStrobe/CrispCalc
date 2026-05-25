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

import '../engine/sudoku.dart';
import '../localization/app_localizations.dart';
import '../widgets/sudoku_grid.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  SudokuPuzzle _puzzle = SudokuPresets.standard9x9Easy;
  // Clues are captured at puzzle load so the visualizer can tell
  // user/preset values apart from solver-filled ones.
  late Set<int> _clueIndexes = _captureClueIndexes(_puzzle);
  // Live editable cells. Mutated by tap-to-enter and by the
  // visualizer when replaying frames.
  late List<int> _displayed = List<int>.from(_puzzle.cells);

  int? _selected;
  SudokuTrace? _trace;
  int _frameIndex = 0;
  Timer? _ticker;
  bool _playing = false;
  bool _solving = false;
  bool _generating = false;
  bool _showHints = false;
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
  /// top selectors (not via a preset), we wipe the grid to empty
  /// so the user can fill in fresh clues OR hit Generate / pick a
  /// matching preset. Doing this also resets the trace.
  ///
  /// V3-Killer: an empty Killer puzzle is invalid (the cages
  /// list is required). When switching INTO Killer mode, auto-
  /// load the matching Killer preset; when switching OUT of
  /// Killer mode, drop the cages.
  void _switchLayoutOrVariant(
      SudokuLayout? newLayout, SudokuVariant? newVariant) {
    _stopVisualizer();
    final layout = newLayout ?? _puzzle.layout;
    final variant = newVariant ?? _puzzle.variant;
    if (variant == SudokuVariant.killer) {
      // Killer can't be empty — pick a preset whose layout matches
      // (or fall back to any Killer preset we ship).
      final match = SudokuPresets.all.firstWhere(
        (p) =>
            p.puzzle.variant == SudokuVariant.killer &&
            p.puzzle.layout.side == layout.side,
        orElse: () => SudokuPresets.all.firstWhere(
          (p) => p.puzzle.variant == SudokuVariant.killer,
        ),
      );
      _loadPreset(match.puzzle);
      return;
    }
    final empty = SudokuPuzzle(
      layout: layout,
      cells: List<int>.filled(layout.side * layout.side, 0),
      variant: variant,
    );
    setState(() {
      _puzzle = empty;
      _clueIndexes = {};
      _displayed = List<int>.from(empty.cells);
      _selected = null;
      _trace = null;
      _frameIndex = 0;
      _unique = null;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
      _clueIndexes = _captureClueIndexes(p);
      _displayed = List<int>.from(p.cells);
      _selected = null;
      _trace = null;
      _frameIndex = 0;
      _unique = null;
    });
  }

  void _onTapCell(int idx) {
    setState(() => _selected = idx);
  }

  void _setDigit(int? d) {
    final sel = _selected;
    if (sel == null) return;
    if (_clueIndexes.contains(sel)) return; // preset — don't allow overwrite
    setState(() {
      _displayed[sel] = d ?? 0;
      _puzzle = _puzzle.withCell(
          sel ~/ _puzzle.layout.side, sel % _puzzle.layout.side, d ?? 0);
      // Re-capture clue indexes if the user is composing their own
      // puzzle — anything non-zero becomes a clue.
      _clueIndexes = _captureClueIndexes(_puzzle);
      _trace = null;
      _frameIndex = 0;
      _unique = null;
    });
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
      _clueIndexes = _captureClueIndexes(puzzle);
      _displayed = List<int>.from(puzzle.cells);
      _selected = null;
      _trace = null;
      _frameIndex = 0;
      _unique = null;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final layout = _puzzle.layout;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final highlightIdx =
        _trace == null ? null : _trace!.frames[_frameIndex].justChangedIndex;

    // V3: when "Show hints" is on, compute the candidate set per
    // empty cell against the *displayed* grid (so as the user
    // fills in digits or the visualizer plays, candidates update
    // live). Disabled while the visualizer trace is mid-replay to
    // avoid two competing "what's in this cell" overlays.
    List<Set<int>>? candidates;
    if (_showHints && _trace == null) {
      final livePuzzle = SudokuPuzzle(
        layout: layout,
        cells: _displayed,
        variant: _puzzle.variant,
      );
      candidates = SudokuSolver.computeCandidates(livePuzzle);
    }

    final gridBlock = Padding(
      padding: const EdgeInsets.all(16),
      child: SudokuGrid(
        layout: layout,
        cells: _displayed,
        clueIndexes: _clueIndexes,
        selectedIndex: _selected,
        highlightIndex: highlightIdx,
        candidates: candidates,
        cages: _puzzle.cages,
        onTapCell: _onTapCell,
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
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(t.sudokuShowHints),
            subtitle: Text(t.sudokuShowHintsSubtitle,
                style: Theme.of(context).textTheme.bodySmall),
            value: _showHints,
            onChanged: (v) => setState(() => _showHints = v),
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
          Row(
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
              const SizedBox(width: 12),
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
      body: isWide
          ? Row(
              children: [
                Expanded(child: gridBlock),
                SizedBox(width: 360, child: controlsBlock),
              ],
            )
          : ListView(children: [gridBlock, controlsBlock]),
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
}

enum _Speed {
  slow(Duration(milliseconds: 800)),
  medium(Duration(milliseconds: 250)),
  fast(Duration(milliseconds: 50));

  final Duration interval;
  const _Speed(this.interval);
}

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
    return DropdownButtonFormField<SudokuPuzzle>(
      initialValue: SudokuPresets.all
          .map((e) => e.puzzle)
          .firstWhere((p) => identical(p, current), orElse: () => current),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).sudokuPresetLabelChooser,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final preset in SudokuPresets.all)
          DropdownMenuItem(
            value: preset.puzzle,
            child: Text(labelOf(preset.puzzle)),
          ),
      ],
      onChanged: (p) {
        if (p != null) onPick(p);
      },
    );
  }
}

class _DigitPad extends StatelessWidget {
  final int side;
  final ValueChanged<int?> onPress;

  const _DigitPad({required this.side, required this.onPress});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var d = 1; d <= side; d++)
          SizedBox(
            width: 40,
            height: 40,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              onPressed: () => onPress(d),
              child: Text('$d'),
            ),
          ),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: () => onPress(null),
            icon: const Icon(Icons.clear, size: 16),
            label: Text(t.sudokuClearCell),
          ),
        ),
      ],
    );
  }
}

class _VisualizerControls extends StatelessWidget {
  final int total;
  final int current;
  final bool playing;
  final _Speed speed;
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
          Slider(
            min: 0,
            max: (total - 1).toDouble(),
            divisions: total > 1 ? total - 1 : null,
            value: current.toDouble().clamp(0, (total - 1).toDouble()),
            onChanged: (v) => onScrub(v.round()),
          ),
          Row(
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
              const SizedBox(width: 12),
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
        SegmentedButton<SudokuVariant>(
          segments: [
            ButtonSegment(
              value: SudokuVariant.regular,
              label: Text(labels.sudokuVariantRegular),
            ),
            ButtonSegment(
              value: SudokuVariant.x,
              label: Text(labels.sudokuVariantX),
            ),
            ButtonSegment(
              value: SudokuVariant.killer,
              label: Text(labels.sudokuVariantKiller),
            ),
          ],
          selected: {variant},
          onSelectionChanged: (s) => onVariantChanged(s.first),
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
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<SudokuDifficulty>(
            segments: [
              ButtonSegment(
                value: SudokuDifficulty.easy,
                label: Text(labels.sudokuDifficultyEasy),
              ),
              ButtonSegment(
                value: SudokuDifficulty.medium,
                label: Text(labels.sudokuDifficultyMedium),
              ),
              ButtonSegment(
                value: SudokuDifficulty.hard,
                label: Text(labels.sudokuDifficultyHard),
              ),
            ],
            selected: {difficulty},
            onSelectionChanged: disabled ? null : (s) => onDifficulty(s.first),
          ),
        ),
        const SizedBox(width: 8),
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
