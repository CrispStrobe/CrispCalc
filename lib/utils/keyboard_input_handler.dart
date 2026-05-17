// lib/utils/keyboard_input_handler.dart
//
// Keyboard input handling for the LaTeX calculator field.
//
// History note: an earlier version *unconditionally* swapped Y and Z because
// the developer was using a German keyboard. That broke text input on every
// other layout. We now rely on `event.character` (the OS already applied the
// active keyboard layout) and only fall back to physical-key handling for the
// universal action keys (Enter, Esc, Backspace, arrows, numpad).

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class KeyboardInputHandler {
  /// Handles a key event. Returns true if it was consumed.
  ///
  /// [multiplicationAsCdot] — when true, the `*` character is rewritten to
  /// `\cdot ` so it renders in the LaTeX field. Default true (matches the
  /// behavior the rest of the app expects), but tests can disable it.
  static bool handleKeyboardInput(
    KeyEvent event,
    void Function(String) onInsert,
    VoidCallback onBackspace,
    VoidCallback onClear,
    VoidCallback onExecute,
    void Function(int) onMoveCursor, {
    bool multiplicationAsCdot = true,
  }) {
    if (event is! KeyDownEvent) return false;

    final logicalKey = event.logicalKey;
    final character = event.character;

    // Universal action keys
    if (logicalKey == LogicalKeyboardKey.enter ||
        logicalKey == LogicalKeyboardKey.numpadEnter) {
      onExecute();
      return true;
    }
    if (logicalKey == LogicalKeyboardKey.escape) {
      onClear();
      return true;
    }
    if (logicalKey == LogicalKeyboardKey.backspace) {
      onBackspace();
      return true;
    }
    if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      onMoveCursor(-1);
      return true;
    }
    if (logicalKey == LogicalKeyboardKey.arrowRight) {
      onMoveCursor(1);
      return true;
    }

    // Numpad fallbacks — these often don't produce a `character` reliably.
    switch (logicalKey) {
      case LogicalKeyboardKey.numpadAdd:
        onInsert('+');
        return true;
      case LogicalKeyboardKey.numpadSubtract:
        onInsert('-');
        return true;
      case LogicalKeyboardKey.numpadMultiply:
        onInsert(multiplicationAsCdot ? r'\cdot ' : '*');
        return true;
      case LogicalKeyboardKey.numpadDivide:
        onInsert('/');
        return true;
      case LogicalKeyboardKey.numpadDecimal:
        onInsert('.');
        return true;
    }

    // Character input (the OS has already applied the layout).
    if (character != null && character.isNotEmpty) {
      final charCode = character.codeUnitAt(0);
      // Filter out private-use / control characters.
      if (charCode < 32 || charCode >= 0xF700) {
        return false;
      }

      switch (character) {
        case '*':
          onInsert(multiplicationAsCdot ? r'\cdot ' : '*');
          return true;
        case '%':
          onInsert('/100');
          return true;
        case '^':
          onInsert('^{}');
          onMoveCursor(-1);
          return true;
        default:
          onInsert(character);
          return true;
      }
    }

    return false;
  }

  /// Lightweight debug helper kept for development.
  static void debugKeyboardInput(KeyEvent event) {
    if (!kDebugMode) return;
    if (event is! KeyDownEvent) return;
    // ignore: avoid_print
    print('KEY: logical=${event.logicalKey.keyLabel} '
        'physical=${event.physicalKey.debugName} '
        'char="${event.character}" '
        'shift=${HardwareKeyboard.instance.isShiftPressed}');
  }
}
