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
  SudokuDifficulty _genDifficulty = SudokuDifficulty.medium;
  _Speed _speed = _Speed.medium;

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

    final gridBlock = Padding(
      padding: const EdgeInsets.all(16),
      child: SudokuGrid(
        layout: layout,
        cells: _displayed,
        clueIndexes: _clueIndexes,
        selectedIndex: _selected,
        highlightIndex: highlightIdx,
        onTapCell: _onTapCell,
      ),
    );

    final controlsBlock = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PresetPicker(
            current: _puzzle,
            onPick: _loadPreset,
            labelOf: (p) => _localizedPresetLabel(t, p),
          ),
          const SizedBox(height: 12),
          _GeneratorRow(
            difficulty: _genDifficulty,
            generating: _generating,
            onDifficulty: (d) => setState(() => _genDifficulty = d),
            onGenerate: _generate,
            labels: t,
          ),
          const SizedBox(height: 16),
          _DigitPad(
            side: layout.side,
            onPress: _setDigit,
          ),
          const SizedBox(height: 16),
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

class _GeneratorRow extends StatelessWidget {
  final SudokuDifficulty difficulty;
  final bool generating;
  final ValueChanged<SudokuDifficulty> onDifficulty;
  final VoidCallback onGenerate;
  final AppLocalizations labels;

  const _GeneratorRow({
    required this.difficulty,
    required this.generating,
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
            onSelectionChanged: (s) => onDifficulty(s.first),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: generating ? null : onGenerate,
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
