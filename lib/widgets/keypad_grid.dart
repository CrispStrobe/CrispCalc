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
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1, // Adjust for better button shape
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
  }
}