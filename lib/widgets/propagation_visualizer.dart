// lib/widgets/propagation_visualizer.dart
//
// Round F — step-trace visualizer for constraint propagation (the
// "pedagogy gold" item from PLAN's CSP audit). Replays a
// [CspTraceResult] produced by `CspSolver.traceDsl`: a scrubbable,
// auto-playable timeline where each frame shows every variable's
// current domain and a caption naming what the solver just did —
// a decision, a value pruned from a domain by a named constraint, a
// dead-end (domain wipeout), or a backtrack.
//
// Made possible by dart_csp 2.2.0's PropagationTrace API (web-compat
// pin 3212d85): the engine emits a fine-grained event per propagation
// step, and `traceDsl` projects those into per-step domain snapshots
// so this widget renders state by simple indexing — no replay logic
// here, which keeps it deterministic and headless-testable.

import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/csp_solver.dart';
import '../localization/app_localizations.dart';

/// Playback speed for the auto-advance timer.
enum _TraceSpeed { slow, medium, fast }

extension on _TraceSpeed {
  Duration get interval => switch (this) {
        _TraceSpeed.slow => const Duration(milliseconds: 1100),
        _TraceSpeed.medium => const Duration(milliseconds: 550),
        _TraceSpeed.fast => const Duration(milliseconds: 220),
      };
}

class PropagationVisualizer extends StatefulWidget {
  final CspTraceResult trace;

  const PropagationVisualizer({super.key, required this.trace});

  @override
  State<PropagationVisualizer> createState() => _PropagationVisualizerState();
}

class _PropagationVisualizerState extends State<PropagationVisualizer> {
  // Timeline position. -1 is the "initial domains" frame (before any
  // step); 0..steps.length-1 index into the trace steps.
  int _index = -1;
  bool _playing = false;
  _TraceSpeed _speed = _TraceSpeed.medium;
  Timer? _timer;

  int get _lastIndex => widget.trace.steps.length - 1;

  @override
  void didUpdateWidget(PropagationVisualizer old) {
    super.didUpdateWidget(old);
    // A fresh trace (re-ran Visualize) resets the timeline.
    if (!identical(old.trace, widget.trace)) {
      _stop();
      setState(() => _index = -1);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (_playing) _playing = false;
  }

  void _tick() {
    if (_index >= _lastIndex) {
      setState(() => _playing = false);
      _timer?.cancel();
      _timer = null;
      return;
    }
    setState(() => _index++);
  }

  void _togglePlay() {
    if (_playing) {
      setState(_stop);
      return;
    }
    // Replaying from the end restarts from the beginning.
    setState(() {
      if (_index >= _lastIndex) _index = -1;
      _playing = true;
    });
    _timer = Timer.periodic(_speed.interval, (_) => _tick());
  }

  void _setSpeed(_TraceSpeed s) {
    setState(() => _speed = s);
    if (_playing) {
      _timer?.cancel();
      _timer = Timer.periodic(_speed.interval, (_) => _tick());
    }
  }

  void _scrub(int to) {
    setState(() {
      _stop();
      _index = to.clamp(-1, _lastIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final trace = widget.trace;

    // Current step (null on the initial frame) + the domains to draw.
    final CspTraceStep? step = _index < 0 ? null : trace.steps[_index];
    final Map<String, List<int>> domains =
        step?.domains ?? trace.initialDomains;

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
              Text(t.constraintsTraceHeader,
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(
                t.constraintsTraceStepCounter(_index + 1, trace.steps.length),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t.constraintsTraceIntro,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (trace.objectiveIgnored)
            _Note(text: t.constraintsTraceObjectiveNote, scheme: scheme),
          if (trace.truncated)
            _Note(
              text: t.constraintsTraceTruncatedNote(trace.steps.length),
              scheme: scheme,
            ),
          const SizedBox(height: 12),
          // Per-variable domain panel.
          _DomainPanel(
            variables: trace.variables,
            domains: domains,
            step: step,
          ),
          const SizedBox(height: 12),
          // Caption for the current frame.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(step), size: 18, color: _colorFor(step, scheme)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _caption(t, step),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (trace.steps.isNotEmpty)
            Slider(
              min: -1,
              max: _lastIndex.toDouble(),
              divisions: trace.steps.length,
              value: _index.toDouble().clamp(-1, _lastIndex.toDouble()),
              label: '${_index + 1}',
              onChanged: (v) => _scrub(v.round()),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: t.constraintsTraceRestart,
                icon: const Icon(Icons.restart_alt),
                onPressed: trace.steps.isEmpty ? null : () => _scrub(-1),
              ),
              IconButton(
                tooltip: t.constraintsTraceStepBack,
                icon: const Icon(Icons.skip_previous),
                onPressed: _index <= -1 ? null : () => _scrub(_index - 1),
              ),
              IconButton(
                tooltip:
                    _playing ? t.constraintsTracePause : t.constraintsTracePlay,
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                onPressed: trace.steps.isEmpty ? null : _togglePlay,
              ),
              IconButton(
                tooltip: t.constraintsTraceStepForward,
                icon: const Icon(Icons.skip_next),
                onPressed:
                    _index >= _lastIndex ? null : () => _scrub(_index + 1),
              ),
              SegmentedButton<_TraceSpeed>(
                segments: [
                  ButtonSegment(
                    value: _TraceSpeed.slow,
                    label: Text(t.sudokuSpeedSlow),
                  ),
                  ButtonSegment(
                    value: _TraceSpeed.medium,
                    label: Text(t.sudokuSpeedMed),
                  ),
                  ButtonSegment(
                    value: _TraceSpeed.fast,
                    label: Text(t.sudokuSpeedFast),
                  ),
                ],
                selected: {_speed},
                onSelectionChanged: (s) => _setSpeed(s.first),
              ),
            ],
          ),
          // Terminal outcome chip — shown once the timeline reaches
          // the final step.
          if (_index >= _lastIndex && trace.steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: Icon(
                  trace.solved ? Icons.check_circle : Icons.block,
                  size: 18,
                  color: trace.solved ? Colors.green : scheme.error,
                ),
                label: Text(trace.solved
                    ? t.constraintsTraceSolved
                    : t.constraintsTraceUnsat),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _caption(AppLocalizations t, CspTraceStep? step) {
    if (step == null) return t.constraintsTraceInitial;
    final cause = step.causeLabel ?? step.causeKind ?? '';
    switch (step.kind) {
      case CspTraceStepKind.decision:
        return t.constraintsTraceDecision(step.variable!, step.value!);
      case CspTraceStepKind.prune:
        return t.constraintsTracePrune(
            step.removedValues.join(', '), step.variable!, cause);
      case CspTraceStepKind.wipeout:
        return t.constraintsTraceWipeout(step.variable!, cause);
      case CspTraceStepKind.backtrack:
        return t.constraintsTraceBacktrack;
      case CspTraceStepKind.backjump:
        return t.constraintsTraceBackjump(
            step.depth ?? 0, step.targetDepth ?? 0);
      case CspTraceStepKind.solution:
        return t.constraintsTraceSolutionStep;
    }
  }

  IconData _iconFor(CspTraceStep? step) {
    switch (step?.kind) {
      case null:
        return Icons.flag_outlined;
      case CspTraceStepKind.decision:
        return Icons.touch_app_outlined;
      case CspTraceStepKind.prune:
        return Icons.content_cut;
      case CspTraceStepKind.wipeout:
        return Icons.warning_amber_outlined;
      case CspTraceStepKind.backtrack:
        return Icons.undo;
      case CspTraceStepKind.backjump:
        return Icons.fast_rewind;
      case CspTraceStepKind.solution:
        return Icons.check_circle_outline;
    }
  }

  Color _colorFor(CspTraceStep? step, ColorScheme scheme) {
    switch (step?.kind) {
      case CspTraceStepKind.wipeout:
        return scheme.error;
      case CspTraceStepKind.solution:
        return Colors.green;
      case CspTraceStepKind.decision:
        return scheme.primary;
      default:
        return scheme.onSurfaceVariant;
    }
  }
}

/// Small inline notice row (truncation / objective-ignored).
class _Note extends StatelessWidget {
  final String text;
  final ColorScheme scheme;
  const _Note({required this.text, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// The per-variable domain table. Each row is a variable name and the
/// chips of its current domain values. The variable touched by the
/// current step is highlighted; for a prune/wipeout step the just-
/// removed values are appended as struck-through chips so the user
/// sees exactly what the constraint eliminated.
class _DomainPanel extends StatelessWidget {
  final List<String> variables;
  final Map<String, List<int>> domains;
  final CspTraceStep? step;

  const _DomainPanel({
    required this.variables,
    required this.domains,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = step?.variable;
    final removed = (step?.kind == CspTraceStepKind.prune ||
            step?.kind == CspTraceStepKind.wipeout)
        ? step!.removedValues
        : const <int>[];
    final decidedValue =
        step?.kind == CspTraceStepKind.decision ? step!.value : null;

    return Column(
      children: [
        for (final v in variables)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: v == active
                    ? scheme.primaryContainer.withValues(alpha: 0.45)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      v,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final value in (domains[v] ?? const <int>[]))
                          _ValueChip(
                            value: value,
                            decided: v == active && value == decidedValue,
                            scheme: scheme,
                          ),
                        // Just-removed values (this step) — struck out.
                        if (v == active)
                          for (final value in removed)
                            _ValueChip(
                              value: value,
                              removed: true,
                              scheme: scheme,
                            ),
                        if ((domains[v] ?? const <int>[]).isEmpty &&
                            !(v == active && removed.isNotEmpty))
                          Text('∅', style: TextStyle(color: scheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ValueChip extends StatelessWidget {
  final int value;
  final bool removed;
  final bool decided;
  final ColorScheme scheme;

  const _ValueChip({
    required this.value,
    required this.scheme,
    this.removed = false,
    this.decided = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (removed) {
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
    } else if (decided) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
    } else {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurface;
    }
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: fg,
          fontWeight: decided ? FontWeight.bold : FontWeight.normal,
          decoration: removed ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}
