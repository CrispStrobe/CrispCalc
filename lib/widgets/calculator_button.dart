/// lib/widgets/calculator_button.dart:

import 'package:flutter/material.dart';

/// A styled button for the calculator keypad.
class CalculatorButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CalculatorButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _getButtonColor(text),
        foregroundColor: Colors.white,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Determines the button color based on its function.
  Color _getButtonColor(String text) {
    const operators = ['/', '*', '-', '+', '=', '^'];
    const casFunctions = ['∫ dx', 'd/dx', 'lim', 'solve', 'simplify', 'factor', 'expand'];

    if (operators.contains(text) || text == '⌫') {
      return Colors.orange[800]!;
    }
    if (casFunctions.contains(text)) {
      return Colors.blueGrey[700]!;
    }
    if (text == 'C') {
        return Colors.red[700]!;
    }
    // Default color for numbers and general functions.
    return Colors.grey[850]!;
  }
}