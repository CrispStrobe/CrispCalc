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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate appropriate button size based on available space
        final buttonHeight = (constraints.maxHeight - 60) / 5; // 5 rows with padding
        final buttonWidth = (constraints.maxWidth - 60) / 4; // 4 columns with padding
        final buttonSize = buttonHeight.clamp(50.0, 90.0); // Reasonable size limits
        
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: buttonWidth / buttonSize,
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