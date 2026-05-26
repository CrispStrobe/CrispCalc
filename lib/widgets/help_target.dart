// lib/widgets/help_target.dart
// Round 101 (P6): wraps a child with a dotted-blue outline whenever
// app-wide help mode (AppState.helpMode) is on.
//
// Round 102 (P6): optional `onHelpTap` callback. When provided and
// help mode is on, an absorbing GestureDetector intercepts taps so
// the wrapped widget's normal action is suppressed and the help
// popover opens instead. When `onHelpTap` is null, the outline still
// renders but taps pass through (Round 101's pure-affordance mode).

import 'package:flutter/material.dart';
import '../engine/app_state.dart';

class HelpTarget extends StatelessWidget {
  const HelpTarget({
    super.key,
    required this.child,
    this.onHelpTap,
    this.padding = const EdgeInsets.all(2),
    this.borderRadius = const Radius.circular(6),
  });

  final Widget child;

  /// Round 102: invoked when the child is tapped while help mode is
  /// on. When null, the child's normal tap handler runs even in
  /// help mode (useful for the Round 101 demonstration wrappers on
  /// history rows / notepad lines where the row itself doesn't
  /// have a help popover yet).
  final VoidCallback? onHelpTap;

  final EdgeInsets padding;
  final Radius borderRadius;

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (!appState.helpMode) return child;
        final outlined = CustomPaint(
          foregroundPainter: _DottedBorderPainter(
            color: Theme.of(context).colorScheme.primary,
            radius: borderRadius,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        );
        if (onHelpTap == null) return outlined;
        // Absorbing overlay: a transparent GestureDetector layered
        // above the child swallows the tap before it reaches the
        // underlying button. The child still paints normally.
        return Stack(
          children: [
            outlined,
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onHelpTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  _DottedBorderPainter({required this.color, required this.radius});

  final Color color;
  final Radius radius;

  static const double _strokeWidth = 1.4;
  static const double _dashLength = 4.0;
  static const double _gapLength = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        _strokeWidth / 2,
        _strokeWidth / 2,
        size.width - _strokeWidth,
        size.height - _strokeWidth,
      ),
      radius,
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end.toDouble()),
          paint,
        );
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DottedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
