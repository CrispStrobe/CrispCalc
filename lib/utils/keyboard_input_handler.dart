/// lib/utils/keyboard_input_handler.dart
/// Shared keyboard input handling for German/international keyboards

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardInputHandler {
  /// Handles keyboard input events for mathematical input fields
  /// Returns true if the event was handled, false otherwise
  static bool handleKeyboardInput(
    KeyEvent event, 
    Function(String) onInsert,
    VoidCallback onBackspace,
    VoidCallback onClear,
    VoidCallback onExecute,
    Function(int) onMoveCursor,
  ) {
    if (event is! KeyDownEvent) return false;

    final physicalKey = event.physicalKey;
    final logicalKey = event.logicalKey;
    final character = event.character;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;

    // --- GERMAN KEYBOARD PHYSICAL KEY MAPPINGS ---
    
    // Key: `+` and `*` (Physical location of `]` on a US keyboard)
    if (physicalKey == PhysicalKeyboardKey.bracketRight) {
      onInsert(isShiftPressed ? r'\cdot ' : '+');
      return true;
    }
    
    // Key: `-` (Physical location of `/` on a US keyboard)
    if (physicalKey == PhysicalKeyboardKey.slash && !isShiftPressed) {
      onInsert('-');
      return true;
    }
    
    // Key: `/` (This is Shift + 7 on a German keyboard)
    if (physicalKey == PhysicalKeyboardKey.digit7 && isShiftPressed) {
      onInsert('/');
      return true;
    }

    // Parentheses: Shift+8 and Shift+9 on German keyboard
    if (physicalKey == PhysicalKeyboardKey.digit8 && isShiftPressed) {
      onInsert('(');
      return true;
    }
    if (physicalKey == PhysicalKeyboardKey.digit9 && isShiftPressed) {
      onInsert(')');
      return true;
    }

    // Equal sign: Shift+0 on German keyboard
    if (physicalKey == PhysicalKeyboardKey.digit0 && isShiftPressed) {
      onInsert('=');
      return true;
    }

    // --- UNIVERSAL ACTION KEYS ---
    if (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter) {
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

    // --- STANDARD CHARACTER INPUT ---
    if (character != null && character.isNotEmpty) {
      final charCode = character.codeUnitAt(0);
      if (charCode < 0xF700 && charCode >= 32) {
        switch (character) {
          case '*':
            onInsert(r'\cdot ');
            break;
          case '^':
            onInsert('^{}');
            onMoveCursor(-1);
            break;
          default:
            onInsert(character);
        }
        return true;
      }
    }

    // --- NUMPAD FALLBACKS ---
    switch (logicalKey) {
      case LogicalKeyboardKey.numpadAdd:
        onInsert('+');
        return true;
      case LogicalKeyboardKey.numpadSubtract:
        onInsert('-');
        return true;
      case LogicalKeyboardKey.numpadMultiply:
        onInsert(r'\cdot ');
        return true;
      case LogicalKeyboardKey.numpadDivide:
        onInsert('/');
        return true;
      case LogicalKeyboardKey.numpadDecimal:
        onInsert('.');
        return true;
      case LogicalKeyboardKey.equal:
        onExecute();
        return true;
    }

    return false;
  }

  /// Gets keyboard corrections for different locales
  static Map<String, String> getKeyboardCorrections(String locale) {
    if (locale.startsWith('de')) {
      return {
        ']': '+', '}': r'\cdot ', '/': '-', '&': '/', '*': '(',
      };
    } else if (locale.startsWith('fr')) {
      return {
        '§': '(', '°': ')', '£': r'\cdot ', 'µ': '+', '¨': '^',
        'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      };
    } else if (locale.startsWith('es')) {
      return {
        '¿': '/', 'ñ': '+', 'Ñ': r'\cdot ', '¡': '(',
        'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      };
    }
    return {};
  }

  /// Debug function to log keyboard input events
  static void debugKeyboardInput(KeyEvent event) {
    if (event is KeyDownEvent) {
      print('=== KEYBOARD DEBUG ===');
      print('Logical Key: ${event.logicalKey}');
      print('Physical Key: ${event.physicalKey}');
      print('Character: "${event.character}"');
      print('Key Label: "${event.logicalKey.keyLabel}"');
      print('========================');
    }
  }
}