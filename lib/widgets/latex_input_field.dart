/// lib/widgets/latex_input_field.dart
/// The main input display that renders math in real-time using LaTeX.

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../controllers/latex_controller.dart';
import 'dart:async';

class LatexInputField extends StatefulWidget {
  const LatexInputField({super.key, required this.controller});

  final LatexController controller;

  @override
  State<LatexInputField> createState() => _LatexInputFieldState();
}

class _LatexInputFieldState extends State<LatexInputField> {
  Timer? _cursorTimer;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() => _showCursor = true);
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  /// Converts a plain text string to LaTeX string for rendering (without cursor).
  String _toLatex(String text) {
    String latex = text;
    
    // Replace standard operators with LaTeX equivalents
    latex = latex.replaceAll('*', r'\cdot ');
    
    // Convert fractions
    latex = latex.replaceAllMapped(RegExp(r'\(([^/]+)\)/\(([^/]+)\)'), (m) {
      return r'\frac{' + '${m.group(1)}' + r'}{' + '${m.group(2)}' + r'}';
    });
    
    // Ensure standard functions are rendered upright
    latex = latex.replaceAllMapped(RegExp(r'(\b(sin|cos|tan|ln|log|det|lim|sqrt)\b)(?![a-zA-Z])'), (m) {
      return '\\${m.group(1)}';
    });
    
    return latex;
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.controller.selection;
    final text = widget.controller.text;
    final cursorPosition = selection.baseOffset.clamp(0, text.length);
    
    // Split text at cursor position
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      alignment: Alignment.centerRight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Text before cursor
            if (beforeCursor.isNotEmpty)
              Math.tex(
                _toLatex(beforeCursor),
                textStyle: TextStyle(
                  fontSize: 40,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
                mathStyle: MathStyle.display,
                onErrorFallback: (err) => Text(
                  beforeCursor,
                  style: TextStyle(fontSize: 40, color: Colors.red.shade300, height: 1.3),
                ),
              ),
            
            // Cursor
            Container(
              width: 2,
              height: 50,
              color: _showCursor ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
            ),
            
            // Text after cursor
            if (afterCursor.isNotEmpty)
              Math.tex(
                _toLatex(afterCursor),
                textStyle: TextStyle(
                  fontSize: 40,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
                mathStyle: MathStyle.display,
                onErrorFallback: (err) => Text(
                  afterCursor,
                  style: TextStyle(fontSize: 40, color: Colors.red.shade300, height: 1.3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}