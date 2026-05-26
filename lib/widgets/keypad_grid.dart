// lib/widgets/keypad_grid.dart:

import 'package:flutter/material.dart';
import 'calculator_button.dart';
import 'help_target.dart';

/// A widget that arranges calculator buttons in a responsive grid.
///
/// Round 102 (P6): when [helpRefIdFor] AND [onHelpTap] are both
/// supplied, every button is wrapped in a [HelpTarget]. While help
/// mode is on, tapping a button whose `helpRefIdFor(text)` returns a
/// non-null id calls `onHelpTap(id)` instead of the normal press
/// handler. Buttons without a matching id still render the
/// help-mode outline but stay functional on tap.
class KeypadGrid extends StatelessWidget {
  final List<String> buttons;
  final void Function(String) onButtonPressed;

  /// Round 102: per-button glyph→FunctionRef-id resolver. Returns
  /// `null` for buttons without a catalogued help entry.
  final String? Function(String buttonText)? helpRefIdFor;

  /// Round 102: invoked with the resolved FunctionRef id when a
  /// button is tapped in help mode.
  final void Function(String refId)? onHelpTap;

  const KeypadGrid({
    super.key,
    required this.buttons,
    required this.onButtonPressed,
    this.helpRefIdFor,
    this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    // This LayoutBuilder creates a perfectly responsive grid that fills the available space.
    return LayoutBuilder(
      builder: (context, constraints) {
        const double crossAxisSpacing = 10;
        const double mainAxisSpacing = 10;
        const double horizontalPadding = 24; // 12 left + 12 right from parent
        const double verticalPadding = 24; // 12 top + 12 bottom from parent

        final double cellWidth = (constraints.maxWidth -
                horizontalPadding -
                (3 * crossAxisSpacing)) /
            4;
        final double cellHeight =
            (constraints.maxHeight - verticalPadding - (4 * mainAxisSpacing)) /
                5;

        // Prevent division-by-zero or negative aspect ratio if constraints are not ready.
        final double aspectRatio =
            (cellHeight > 0 && cellWidth > 0) ? cellWidth / cellHeight : 1.0;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: buttons.length,
          itemBuilder: (context, index) {
            final buttonText = buttons[index];
            final button = CalculatorButton(
              text: buttonText,
              onPressed: () => onButtonPressed(buttonText),
            );
            if (helpRefIdFor == null || onHelpTap == null) return button;
            final refId = helpRefIdFor!(buttonText);
            return HelpTarget(
              padding: EdgeInsets.zero,
              borderRadius: const Radius.circular(16),
              onHelpTap: refId == null ? null : () => onHelpTap!(refId),
              child: button,
            );
          },
        );
      },
    );
  }
}
