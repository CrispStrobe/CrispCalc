// lib/controllers/latex_controller.dart
// A custom controller to manage the state of the LaTeX input field.
// This version is "structure-aware" for better editing of math expressions.

import 'package:flutter/material.dart';

class LatexController extends ChangeNotifier {
  String _text = '';
  TextSelection _selection = const TextSelection.collapsed(offset: 0);

  String get text => _text;
  TextSelection get selection => _selection;

  String get textWithCursor {
    if (_selection.isCollapsed) {
      final offset = _selection.baseOffset.clamp(0, _text.length);
      return '${_text.substring(0, offset)}|${_text.substring(offset)}';
    }
    return _text;
  }

  /// Inserts text and optionally positions the cursor relative to the end of the insertion.
  void insert(String textToInsert, {int? cursorOffsetFromEnd}) {
    if (!_selection.isValid) return;

    final start = _selection.start.clamp(0, _text.length);
    final end = _selection.end.clamp(0, _text.length);
    final insertionLength = textToInsert.length;

    _text = _text.replaceRange(start, end, textToInsert);

    // Position cursor: either at the end of insertion or at a custom offset.
    int newOffset = start + insertionLength;
    if (cursorOffsetFromEnd != null) {
      newOffset = (start + insertionLength + cursorOffsetFromEnd)
          .clamp(0, _text.length);
    }

    _selection = TextSelection.collapsed(offset: newOffset);
    notifyListeners();
  }

  /// A "smarter" backspace that can delete matched pairs or function blocks.
  void backspace() {
    if (!_selection.isValid || _text.isEmpty) return;

    if (_selection.isCollapsed) {
      if (_selection.baseOffset > 0) {
        final offset = _selection.baseOffset;
        final charBefore = _text[offset - 1];

        // Smart delete for bracket pairs
        const pairs = {'}': '{', ')': '(', ']': '['};
        if (pairs.containsKey(charBefore) && offset >= 2) {
          final openBracket = pairs[charBefore];

          // Check if text ends with `\func{}`
          final funcPattern = RegExp(r'(\\\w+)\{$');
          final match = funcPattern.firstMatch(_text.substring(0, offset - 1));

          if (match != null) {
            // Delete the entire function block, e.g., \sqrt{}
            final funcName = match.group(1)!;
            final deleteStart = offset - funcName.length - 2;
            if (deleteStart >= 0) {
              _text = _text.substring(0, deleteStart) + _text.substring(offset);
              _selection = TextSelection.collapsed(offset: deleteStart);
            }
          } else if (offset >= 2 && _text[offset - 2] == openBracket) {
            // Just delete the bracket pair, e.g., {}
            _text = _text.substring(0, offset - 2) + _text.substring(offset);
            _selection = TextSelection.collapsed(offset: offset - 2);
          } else {
            // Standard single character delete
            _text = _text.substring(0, offset - 1) + _text.substring(offset);
            _selection = TextSelection.collapsed(offset: offset - 1);
          }
        } else {
          // Standard single character delete
          _text = _text.substring(0, offset - 1) + _text.substring(offset);
          _selection = TextSelection.collapsed(offset: offset - 1);
        }
      }
    } else {
      // If there's a selection, backspace deletes the selection
      insert('');
    }
    notifyListeners();
  }

  void clear() {
    _text = '';
    _selection = const TextSelection.collapsed(offset: 0);
    notifyListeners();
  }

  void moveCursor(int amount) {
    final newOffset = (_selection.baseOffset + amount).clamp(0, _text.length);
    if (_selection.baseOffset != newOffset) {
      _selection = TextSelection.collapsed(offset: newOffset);
      notifyListeners();
    }
  }
}
