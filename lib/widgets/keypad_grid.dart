/// lib/widgets/keypad_grid.dart:

import 'package:flutter/material.dart';
import 'calculator_button.dart';

/// A widget that arranges calculator buttons in a responsive grid.
class KeypadGrid extends StatelessWidget {
  final List<String> buttons;
  final void Function(String) onButtonPressed;

  const KeypadGrid({
    super.key,
    required this.buttons,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    // This LayoutBuilder creates a perfectly responsive grid that fills the available space.
    return LayoutBuilder(
      builder: (context, constraints) {
        const double crossAxisSpacing = 10;
        const double mainAxisSpacing = 10;
        const double horizontalPadding = 24; // 12 left + 12 right from parent
        const double verticalPadding = 24;   // 12 top + 12 bottom from parent

        final double cellWidth = (constraints.maxWidth - horizontalPadding - (3 * crossAxisSpacing)) / 4;
        final double cellHeight = (constraints.maxHeight - verticalPadding - (4 * mainAxisSpacing)) / 5;
        
        // Prevent division-by-zero or negative aspect ratio if constraints are not ready.
        final double aspectRatio = (cellHeight > 0 && cellWidth > 0) ? cellWidth / cellHeight : 1.0;

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
            return CalculatorButton(
              text: buttonText,
              onPressed: () => onButtonPressed(buttonText),
            );
          },
        );
      },
    );
  }
}