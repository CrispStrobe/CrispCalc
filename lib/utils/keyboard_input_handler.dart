/// lib/utils/keyboard_input_handler.dart
/// Enhanced keyboard input handling with real-time German keyboard correction

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

    // --- GERMAN KEYBOARD PHYSICAL KEY MAPPINGS (Real-time correction) ---
    
    // German Y/Z swap: Physical Y key produces Z on German layout
    if (physicalKey == PhysicalKeyboardKey.keyY) {
        onInsert('z');
        return true;
    }
    if (physicalKey == PhysicalKeyboardKey.keyZ) {
        onInsert('y');
        return true;
    }
    
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

    // --- CHARACTER INPUT WITH IMMEDIATE CORRECTION ---
    if (character != null && character.isNotEmpty) {
        final charCode = character.codeUnitAt(0);
        if (charCode < 0xF700 && charCode >= 32) {
        // Apply real-time corrections for German keyboard characters
        switch (character) {
            case ']': // German keyboard produces ] instead of +
            onInsert('+');
            break;
            case '}': // German keyboard produces } instead of * (becomes LaTeX \cdot)
            onInsert(r'\cdot ');
            break;
            case '*': // Standard * key should become LaTeX \cdot
            onInsert(r'\cdot ');
            break;
            case '%': // Convert percentage to decimal division by 100
            onInsert('/100');
            break;
            case '^': // Handle power operator
            onInsert('^{}');
            onMoveCursor(-1);
            break;
            default:
            // For other characters, insert as-is
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

  /// Gets keyboard corrections for different locales (legacy support)
  static Map<String, String> getKeyboardCorrections(String locale) {
    if (locale.startsWith('de')) {
      return {
        ']': '+', 
        '}': r'\cdot ', 
        '/': '-', 
        '&': '/', 
        '*': '(',
      };
    } else if (locale.startsWith('fr')) {
      return {
        '§': '(', 
        '°': ')', 
        '£': r'\cdot ', 
        'µ': '+', 
        '¨': '^',
        'á': 'a', 
        'é': 'e', 
        'í': 'i', 
        'ó': 'o', 
        'ú': 'u',
      };
    } else if (locale.startsWith('es')) {
      return {
        '¿': '/', 
        'ñ': '+', 
        'Ñ': r'\cdot ', 
        '¡': '(',
        'á': 'a', 
        'é': 'e', 
        'í': 'i', 
        'ó': 'o', 
        'ú': 'u',
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
      print('Shift: ${HardwareKeyboard.instance.isShiftPressed}');
      print('Alt: ${HardwareKeyboard.instance.isAltPressed}');
      print('========================');
    }
  }

  /// Enhanced function specifically for LaTeX fields that need proper \cdot handling
  static bool handleLatexKeyboardInput(
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

    // Handle German keyboard mappings with LaTeX output
    if (physicalKey == PhysicalKeyboardKey.bracketRight) {
      if (isShiftPressed) {
        // German } key should produce LaTeX multiplication
        onInsert(r'\cdot ');
      } else {
        // German ] key should produce +
        onInsert('+');
      }
      return true;
    }
    
    // Use the standard handler for other keys
    return handleKeyboardInput(event, onInsert, onBackspace, onClear, onExecute, onMoveCursor);
  }
}