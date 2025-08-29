import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../engine/app_state.dart';
import '../engine/calculator_engine.dart';
import '../widgets/keypad_grid.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin {
  final AppState _appState = AppState();
  final CalculatorEngine _engine = CalculatorEngine();

  late TabController _tabController;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  
  String _resultPreview = '';
  bool _justCalculated = false;
  bool _modalIsOpen = false;
  
  final Map<String, String> _memory = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller.addListener(_onInputChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  void _onFocusChanged() {
    // Remove this - we'll handle focus more directly
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }
  
  /// Public method to request focus - called from main.dart
  void requestFocus() {
    print('MAIN: requestFocus() called from main.dart');
    if (!_inputFocusNode.hasFocus) {
      print('MAIN: Requesting focus...');
      _inputFocusNode.requestFocus();
    } else {
      print('MAIN: Already has focus');
    }
  }
  
  /// Central hub for reacting to text changes from keyboard or grid
  void _onInputChanged() {
    // A flag to prevent re-triggering this listener while we are modifying text inside it.
    bool isModifying = false;

    // Handle post-calculation state
    if (!isModifying && _justCalculated && _controller.text.isNotEmpty) {
      final input = _controller.text;

      // CRITICAL FIX: Only run post-calc logic for simple inputs (operators/numbers).
      // If the input is a function call (contains a parenthesis), do NOT run this,
      // as it will override the carefully placed cursor.
      final isSimpleInput = !input.contains('(');

      if (isSimpleInput) {
        isModifying = true;
        final lastResult = _appState.history.firstOrNull?.result ?? '0';

        // Prevent recursive listener calls
        _controller.removeListener(_onInputChanged);

        if (['+', '-', '*', '/', '^', '%'].contains(input)) {
          final resultToUse = _extractNumericFromSolveResult(lastResult);
          _controller.text = resultToUse + input;
        }

        _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length));
        
        setState(() { _justCalculated = false; });
        _controller.addListener(_onInputChanged);
        isModifying = false;
      } else {
        // If it's a function call, just reset the flag and do nothing else.
        setState(() { _justCalculated = false; });
      }
    }
    
    _handleFunctionAutocomplete();
    // Use a local variable to prevent rapid firing during modifications.
    if (!isModifying) {
        setState(() => _updateLivePreview());
    }
  }

  /// Auto-completes function names like 'solve' into 'solve()'
  void _handleFunctionAutocomplete() {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;
    if (cursorPos < 0) return;

    // Find start of word before cursor
    int wordStart = cursorPos;
    while (wordStart > 0 && RegExp(r'[a-zA-Z]').hasMatch(text[wordStart - 1])) {
        wordStart--;
    }

    if (wordStart < cursorPos) {
        final word = text.substring(wordStart, cursorPos);
        if (word == 'solve') {
        print('AUTO: Auto-completing "solve" to "solve()"');
        _controller.removeListener(_onInputChanged);
        final textBefore = text.substring(0, wordStart);
        final textAfter = text.substring(cursorPos);
        _controller.text = '$textBefore$word()$textAfter';
        _controller.selection = TextSelection.collapsed(offset: wordStart + word.length + 1);
        _controller.addListener(_onInputChanged);
        
        // Don't show picker immediately - let user type first
        print('AUTO: solve() inserted, cursor positioned inside parentheses');
        }
    }
    }
  
  /// Updates live preview of result as user types
  void _updateLivePreview() {
    String currentText = _controller.text.trim();
    
    // Don't preview if:
    // - Empty or whitespace only
    // - Contains only letters (variables without numbers)
    // - Starts with 'solve'
    // - Too short to be meaningful
    if (currentText.isEmpty || 
        currentText.toLowerCase().startsWith('solve') ||
        
        currentText.contains('=') ||
        currentText.length < 2 ||
        RegExp(r'^[a-zA-Z]+$').hasMatch(currentText)) {
        setState(() { _resultPreview = ''; });
        return;
    }
    
    // Only preview if it looks like a mathematical expression
    if (!RegExp(r'[\d\+\-\*/\^\(\)\.\,]').hasMatch(currentText)) {
        setState(() { _resultPreview = ''; });
        return;
    }
    
    try {
        final preprocessed = _preprocessNativeExpression(_preprocessExpression(currentText));
        final result = _engine.evaluate(preprocessed);
        
        // Only show preview if result is different and numeric
        if (result != "Error" && 
            result != currentText && 
            double.tryParse(result) != null &&
            result != preprocessed) {
        setState(() { _resultPreview = result; });
        } else {
        setState(() { _resultPreview = ''; });
        }
    } catch (e) {
        setState(() { _resultPreview = ''; });
    }
    }

  /// Handles hardware keyboard events
  bool handleKeyboardInput(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    
    print('KEYBOARD: Hardware key pressed: ${event.logicalKey}');
    
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) { 
      _onButtonPressed("EXE"); 
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) { 
      _onButtonPressed('C'); 
      return true;
    }
    
    return false;
  }

  /// Central handler for all keypad buttons
  void _onButtonPressed(String value) {
    // Note: No top-level focus request here. Focus is handled by the
    // specific action methods (_insertTextAndPositionCursor, _handleBackspace)
    // to prevent the "select all" bug.

    switch (value) {
      case 'C':
        _controller.clear();
        setState(() { _justCalculated = false; });
        break;
      case '⌫':
        _handleBackspace();
        break;
      case 'EXE':
        if (_controller.text.isNotEmpty) {
          _calculate(_controller.text);
        }
        break;
      case '◀':
        // Cursor movement should only happen if the field already has focus
        if (_inputFocusNode.hasFocus) {
          final selection = _controller.selection;
          if (selection.baseOffset > 0) {
            final newPosition = selection.baseOffset - 1;
            _controller.selection = TextSelection.collapsed(offset: newPosition);
          }
        }
        break;
      case '▶':
        if (_inputFocusNode.hasFocus) {
          final selection = _controller.selection;
          if (selection.baseOffset < _controller.text.length) {
            final newPosition = selection.baseOffset + 1;
            _controller.selection = TextSelection.collapsed(offset: newPosition);
          }
        }
        break;
      
      // --- WORKFLOW FIXES ARE HERE ---

      case 'solve':
        // 1. First, insert 'solve()' with the cursor correctly positioned inside.
        _insertTextAndPositionCursor('solve()', cursorOffset: -1);
        // 2. Then, show the picker as a helpful overlay.
        _showSolveFunctionPicker();
        break;

      case 'f(x)':
        _showFunctionPicker();
        break;

      // CURSOR FIX: Group all functions that need the cursor placed inside the parentheses.
      case 'sin(':
      case 'cos(':
      case 'tan(':
      case 'ln(':
      case 'log(':
      case 'sqrt(':
      case 'abs(':
        // Extract the function name (e.g., "sin") from the button value (e.g., "sin(").
        final funcName = value.substring(0, value.length - 1);
        // Insert the text with a cursorOffset of -1 to place the cursor before the last character ')'.
        _insertTextAndPositionCursor('$funcName()', cursorOffset: -1);
        break;

      default:
        // Handle all other buttons (numbers, operators, etc.)
        _insertTextAndPositionCursor(value);
        break;
    }
  }

  void _onButtonPressed_old(String value) {
    print('\n=== BUTTON PRESSED: "$value" ===');
    print('Focus before: ${_inputFocusNode.hasFocus}');
    print('Current text: "${_controller.text}"');
    print('Current selection: ${_controller.selection}');
    
    // Ensure focus for all button presses
    if (!_inputFocusNode.hasFocus) {
        _inputFocusNode.requestFocus();
    }

    switch (value) {
        case 'C':
        _controller.clear();
        setState(() { _justCalculated = false; });
        break;
        case '⌫':
        _handleBackspace();
        break;
        case 'EXE':
        if (_controller.text.isNotEmpty) {
            _calculate(_controller.text);
        }
        break;
        case '◀':
        final selection = _controller.selection;
        if (selection.baseOffset > 0) {
            final newPosition = selection.baseOffset - 1;
            _controller.selection = TextSelection.collapsed(offset: newPosition);
        }
        break;
        case '▶':
        final selection = _controller.selection;
        if (selection.baseOffset < _controller.text.length) {
            final newPosition = selection.baseOffset + 1;
            _controller.selection = TextSelection.collapsed(offset: newPosition);
        }
        break;
        case 'solve':
        _insertTextAndPositionCursor('solve()', cursorOffset: -1);
        // Show picker after a short delay to allow the text to be inserted
        Future.delayed(const Duration(milliseconds: 50), () {
            _showSolveFunctionPicker();
        });
        break;
        case 'f(x)':
        _showFunctionPicker();
        break;
        // Function buttons that need cursor inside parentheses - FIXED: Handle all function cases
        case 'sin(': case 'cos(': case 'tan(': case 'ln(': case 'sqrt(': case 'abs(':
        final funcName = value.substring(0, value.length - 1);
        _insertTextAndPositionCursor('$funcName()', cursorOffset: -1);
        break;
        case 'log(': // Special case for log
        _insertTextAndPositionCursor('log()', cursorOffset: -1);
        break;
        case 'log': // In case it's just 'log' without parentheses
        _insertTextAndPositionCursor('log()', cursorOffset: -1);
        break;
        default:
        _insertTextAndPositionCursor(value);
        break;
    }
    
    print('Focus after: ${_inputFocusNode.hasFocus}');
    print('Final text: "${_controller.text}"');
    print('Final selection: ${_controller.selection}');
    print('=== END BUTTON PROCESSING ===\n');
    }
  
  /// THE KEY METHOD - Robust text insertion that prevents auto-selection
  void _insertTextAndPositionCursor(String text, {int cursorOffset = 0}) {
    print('\n=== TEXT INSERTION DEBUG ===');
    print('Inserting: "$text"');
    print('Cursor offset: $cursorOffset');
    print('Before insertion:');
    print('  Text: "${_controller.text}"');
    print('  Selection: ${_controller.selection}');
    
    // Get current state
    final selection = _controller.selection;
    final currentText = _controller.text;

    // Calculate new text and cursor position using replaceRange
    final newText = currentText.replaceRange(selection.start, selection.end, text);
    final newPosition = selection.start + text.length + cursorOffset;
    
    print('Calculated new state:');
    print('  New text: "$newText"');
    print('  New cursor position: $newPosition');

    // If we already have focus, the update can be done synchronously and simply.
    if (_inputFocusNode.hasFocus) {
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newPosition.clamp(0, newText.length)),
      );
    } else {
      // If we DON'T have focus, we request it. This is an asynchronous operation.
      _inputFocusNode.requestFocus();
      
      // We schedule the state update for the very next frame. By the time this
      // callback runs, the focus event will be complete. Our value assignment
      // will now correctly override the TextField's default "select all" behavior.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newPosition.clamp(0, newText.length)),
        );
      });
    }
    
    print('After atomic update:');
    print('  Actual text: "${_controller.text}"');
    print('  Actual selection: ${_controller.selection}');
    print('=== END TEXT INSERTION DEBUG ===\n');
  }
  
  /// Handles backspace for both cursor and selection
  void _handleBackspace() {
    print('\n=== BACKSPACE DEBUG ===');
    final selection = _controller.selection;
    final currentText = _controller.text;
    
    print('Before backspace:');
    print('  Text: "$currentText"');
    print('  Selection: $selection');

    if (!selection.isValid) return; // Do nothing if selection is invalid

    // If text is selected, deleting it is the same as inserting an empty string.
    if (!selection.isCollapsed) {
      _insertTextAndPositionCursor('');
      return;
    }

    // Handle single-character deletion at a collapsed cursor.
    if (selection.start > 0) {
      final currentText = _controller.text;
      final newText = currentText.substring(0, selection.start - 1) + currentText.substring(selection.start);
      final newPos = selection.start - 1;

        print('Single cursor backspace:');
        print('  Removing char at position ${selection.start - 1}');
        print('  New text: "$newText"');
        print('  New cursor: $newPos');

      // Apply the same focus-aware logic as our main insertion function.
      if (_inputFocusNode.hasFocus) {
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newPos),
        );
      } else {
        _inputFocusNode.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newPos),
          );
        });
      }
    }
    
    print('After backspace:');
    print('  Text: "${_controller.text}"');
    print('  Selection: ${_controller.selection}');
    print('=== END BACKSPACE DEBUG ===\n');
  }

  /// Evaluates expression and updates history
  void _calculate(String expression) {
    print('\n=== CALCULATING: "$expression" ===');
    try {
      String result;
      
      // Handle solve() function calls BEFORE preprocessing
      if (expression.trim().startsWith('solve(') && expression.trim().endsWith(')')) {
        print('CALC: Detected solve() function, handling specially');
        result = _handleSolveFunction(expression.trim());
      } else {
        // Normal expression evaluation with preprocessing
        final preprocessed = _preprocessNativeExpression(_preprocessExpression(expression));
        print('CALC: Preprocessed expression: "$preprocessed"');
        result = _engine.evaluate(preprocessed);
      }
      
      print('CALC: Result: "$result"');
      
      setState(() {
        _appState.addHistoryEntry(expression, result);
        _resultPreview = '';
        _justCalculated = true;
        
        // Clear without triggering listener
        _controller.removeListener(_onInputChanged);
        _controller.clear();
        _controller.addListener(_onInputChanged);
      });
      
      print('CALC: Added to history, cleared input, set _justCalculated = true');
    } catch (e) {
      print('CALC: Calculation error: $e');
      setState(() => _appState.addHistoryEntry(expression, "Error: ${e.toString()}"));
    }
    print('=== END CALCULATION ===\n');
  }

  /// Handles solve() function parsing and execution
  String _handleSolveFunction(String expression) {
    print('SOLVE: Processing solve function: "$expression"');
    
    try {
      // Extract content inside solve()
      final solveContent = expression.substring(6, expression.length - 1).trim();
      print('SOLVE: Content inside solve(): "$solveContent"');
      
      String equation;
      String variable;
      
      // Parse the content - check if variable is explicitly provided
      final parts = solveContent.split(',');
      if (parts.length == 1) {
        // Only equation provided, auto-detect variable
        equation = parts[0].trim();
        variable = _detectVariable(equation);
        print('SOLVE: Auto-detected variable: "$variable"');
      } else if (parts.length == 2) {
        // Both equation and variable provided
        equation = parts[0].trim();
        variable = parts[1].trim();
        print('SOLVE: Explicit variable provided: "$variable"');
      } else {
        print('SOLVE: Error - Too many parameters');
        return 'Error: solve() format: solve(equation) or solve(equation, variable)';
      }
      
      print('SOLVE: Equation: "$equation", Variable: "$variable"');
      
      // If equation contains =, split it and move right side to left
      if (equation.contains('=')) {
        final eqParts = equation.split('=');
        if (eqParts.length == 2) {
          final leftSide = eqParts[0].trim();
          final rightSide = eqParts[1].trim();
          
          // Convert "left = right" to "left - (right)"
          if (rightSide == '0' || rightSide.isEmpty) {
            equation = leftSide;
          } else {
            equation = '$leftSide - ($rightSide)';
          }
          print('SOLVE: Converted equation to: "$equation"');
        }
      }
      
      // Now preprocess the equation before solving
      final preprocessed = _preprocessNativeExpression(_preprocessExpression(equation));
      print('SOLVE: Preprocessed equation: "$preprocessed"');
      
      return _engine.solve(preprocessed, variable);
      
    } catch (e) {
      print('SOLVE: Error parsing solve function: $e');
      return 'Error: Invalid solve() syntax';
    }
  }

  /// Auto-detects the variable to solve for in an equation
  String _detectVariable(String equation) {
    print('SOLVE: Auto-detecting variable in: "$equation"');
    
    // Known constants and functions to ignore
    final knownTokens = {
      'e', 'pi', 'sin', 'cos', 'tan', 'ln', 'log', 'sqrt', 'abs', 
      'exp', 'deg', 'rad', 'gamma', 'factorial'
    };
    
    // Find all single letters that could be variables
    final variablePattern = RegExp(r'\b([a-zA-Z])\b');
    final matches = variablePattern.allMatches(equation);
    
    final foundVariables = <String>{};
    for (final match in matches) {
      final variable = match.group(1)!.toLowerCase();
      if (!knownTokens.contains(variable)) {
        foundVariables.add(variable);
      }
    }
    
    print('SOLVE: Found potential variables: $foundVariables');
    
    // Prioritize common variable names
    final commonVariables = ['x', 'y', 'z', 't', 'n', 'a', 'b', 'c'];
    for (final common in commonVariables) {
      if (foundVariables.contains(common)) {
        print('SOLVE: Selected common variable: "$common"');
        return common;
      }
    }
    
    // If no common variables, use the first one found
    if (foundVariables.isNotEmpty) {
      final firstVar = foundVariables.first;
      print('SOLVE: Selected first variable: "$firstVar"');
      return firstVar;
    }
    
    // Fallback to 'x' if no variables detected
    print('SOLVE: No variables detected, defaulting to "x"');
    return 'x';
  }

  String _preprocessNativeExpression(String expression) {
    String p = expression;
    p = p.replaceAll(',', '.');

    // Pass 1: Handle implicit multiplication for numbers and parentheses.
    // This turns (x+1)(x-2) into (x+1)*(x-2) and 2(3) into 2*(3).
    p = p.replaceAllMapped(RegExp(r'(\d|\))(\()'), (m) => '${m[1]}*${m[2]}');

    // Pass 2: Handle implicit multiplication for standalone variables (like x, y, etc.).
    // A word boundary `\b` ensures we only match single letters, not function names.
    // This turns x(2) into x*(2) but leaves cos(2) alone.
    p = p.replaceAllMapped(RegExp(r'(\b[a-zA-Z]\b)(\()'), (m) => '${m[1]}*${m[2]}');

    p = p.replaceAllMapped(RegExp(r'(\))(\d|\b[a-zA-Z]\b)'), (m) => '${m[1]}*${m[2]}');
    p = p.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n <= 20) {
        int f = 1;
        for (int i = 1; i <= n; i++) { f *= i; }
        return f.toString();
      } else {
        return 'gamma(${n + 1})';
      }
    });
    return p;
  }
  
  String _extractNumericFromSolveResult(String solveResult) {
    final match = RegExp(r'[a-zA-Z]\s*=\s*([+-]?[\d.]+)\s*$').firstMatch(solveResult);
    if (match != null && !match.group(1)!.contains(',')) {
      return match.group(1)!.trim();
    }
    return solveResult;
  }
  
  void _showSolveFunctionPicker() {
    final selectionBeforeModal = _controller.selection;
    setState(() { _modalIsOpen = true; });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select equation or continue typing:', style: Theme.of(context).textTheme.titleMedium),
              ),
              ListTile(
                leading: Icon(Icons.keyboard_return),
                title: Text('Continue Typing'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Safely restore focus and selection
                  _inputFocusNode.requestFocus();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _controller.selection = selectionBeforeModal;
                  });
                },
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _appState.graphFunctions.asMap().entries
                    .where((e) => e.value.isNotEmpty)
                    .map((e) => ListTile(
                      title: Text('Solve Y${e.key + 1} = 0'),
                      subtitle: Text('where Y${e.key + 1} = ${e.value}'),
                      onTap: () {
                        Navigator.of(context).pop();

                        // CRITICAL FIX: Surgically insert the text inside solve()
                        final currentText = _controller.text;
                        final openParen = currentText.lastIndexOf('(');
                        final closeParen = currentText.indexOf(')', openParen);

                        if (openParen != -1 && closeParen != -1) {
                          final textToInsert = 'Y${e.key+1}=0, x';
                          final newText = currentText.replaceRange(openParen + 1, closeParen, textToInsert);
                          final newCursorPos = openParen + 1 + textToInsert.length;
                          
                          _inputFocusNode.requestFocus();
                          _controller.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: newCursorPos),
                          );
                        }
                      },
                    )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() => setState(() { _modalIsOpen = false; }));

    // Return focus to allow "just typing" after the modal appears
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_modalIsOpen && mounted && !_inputFocusNode.hasFocus) {
        _inputFocusNode.requestFocus();
        _controller.selection = selectionBeforeModal;
      }
    });
  }

   void _showFunctionPicker() {
    final List<Widget> options = _appState.graphFunctions.asMap().entries
      .where((entry) => entry.value.isNotEmpty)
      .map((entry) {
        int index = entry.key;
        String func = entry.value;
        return ListTile(
          title: Text('Y${index + 1} = $func'),
          onTap: () {
            Navigator.of(context).pop();
            _insertTextAndPositionCursor('Y${index+1}()', cursorOffset: -1);
          },
        );
      }).toList();

    _showPicker(title: 'Select function or continue typing:', options: options);
  }

  /// A generic, robust modal picker that correctly manages focus.
  void _showPicker({required String title, required List<Widget> options}) {
    // Store the exact cursor position before the modal opens.
    final selectionBeforeModal = _controller.selection;
    setState(() { _modalIsOpen = true; });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              ListTile(
                leading: Icon(Icons.keyboard_return),
                title: Text('Continue Typing'),
                subtitle: Text('Dismiss this panel'),
                onTap: () {
                  // This is now the safe way to close and restore state.
                  Navigator.of(context).pop();
                  _inputFocusNode.requestFocus();
                  // A post-frame callback ensures the selection is restored *after*
                  // the focus has been granted, avoiding the "select all" bug.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _controller.selection = selectionBeforeModal;
                  });
                },
              ),
              const Divider(),
              Flexible(child: ListView(shrinkWrap: true, children: options)),
            ],
          ),
        );
      },
    ).whenComplete(() => setState(() { _modalIsOpen = false; }));

    // CRITICAL FIX: After showing the picker, schedule a task to return focus
    // to the text field. This allows the user to ignore the picker and just
    // continue typing with their physical keyboard.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_modalIsOpen && !_inputFocusNode.hasFocus) {
        _inputFocusNode.requestFocus();
        _controller.selection = selectionBeforeModal;
      }
    });
  }

  String _preprocessExpression(String expression) {
    String processed = expression;

    // Regex to find user-defined functions with arguments, e.g., Y1(3) or Y2(x+1)
    final funcCallRegex = RegExp(r'Y(\d+)\((.*?)\)');
    processed = processed.replaceAllMapped(funcCallRegex, (match) {
      try {
        final funcIndex = int.parse(match.group(1)!) - 1;
        final argValue = match.group(2)!;

        if (funcIndex >= 0 && funcIndex < _appState.graphFunctions.length) {
          String funcBody = _appState.graphFunctions[funcIndex];
          if (funcBody.isNotEmpty) {
            // This is now a substitution, not just a simple replacement.
            final variable = _detectVariable(funcBody);
            // Replace all instances of the variable with the argument, wrapped in parentheses
            // for mathematical safety (e.g., handling Y1(2+3)).
            String substitutedBody = funcBody.replaceAll(variable, '($argValue)');
            return '($substitutedBody)'; // Return the result of the substitution
          }
        }
      } catch (e) {
        return match.group(0)!;
      }
      return match.group(0)!;
    });

    // Handle simple replacement for Y-variables without arguments (if any)
    final simpleFuncRegex = RegExp(r'Y(\d+)');
    processed = processed.replaceAllMapped(simpleFuncRegex, (match) {
        // This part remains for backward compatibility if Y variables are used without args
        // but the funcCallRegex above will catch the more important cases.
        try {
            final funcIndex = int.parse(match.group(1)!) - 1;
            if (funcIndex >= 0 && funcIndex < _appState.graphFunctions.length) {
                String funcBody = _appState.graphFunctions[funcIndex];
                if (funcBody.isNotEmpty) return '($funcBody)';
            }
        } catch (e) { return match.group(0)!; }
        return match.group(0)!;
    });

    return processed;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) => handleKeyboardInput(event) 
        ? KeyEventResult.handled 
        : KeyEventResult.ignored,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            print('BACKGROUND: Background tapped, ensuring focus');
            if (!_inputFocusNode.hasFocus) {
              _inputFocusNode.requestFocus();
            }
          },
          child: Column(
            children: [
              Expanded(flex: 3, child: ListenableBuilder(listenable: _appState, builder: (context, child) {
                return ListView.builder(
                  itemCount: _appState.history.length, reverse: true,
                  itemBuilder: (context, index) {
                    final entry = _appState.history[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(entry.expression, style: TextStyle(fontSize: 20, color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text("= ${entry.result}", style: TextStyle(fontSize: 28, color: Colors.blue[300])),
                        ],
                      ),
                    );
                  },
                );
              })),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  TextField(
                    controller: _controller,
                    focusNode: _inputFocusNode,
                    showCursor: true, 
                    autofocus: true,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _justCalculated ? (_appState.history.firstOrNull?.result ?? '0') : '0',
                      hintStyle: TextStyle(fontSize: 48, color: _justCalculated ? Colors.grey[500] : Colors.grey[700]),
                    ),
                  ),
                  if (_resultPreview.isNotEmpty)
                    Text("= $_resultPreview", style: TextStyle(fontSize: 24, color: Colors.grey[600])),
                ]),
              ),
              Expanded(flex: 5, child: Column(children: [
                TabBar(
                  controller: _tabController,
                  onTap: (index) {
                    print('TAB: Tab $index selected, ensuring focus');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_inputFocusNode.hasFocus) {
                        _inputFocusNode.requestFocus();
                      }
                    });
                  },
                  tabs: const [
                    Tab(text: 'Num'), Tab(text: 'f(x)'), Tab(text: 'CAS'), Tab(text: 'Mem')
                  ]
                ),
                Expanded(child: TabBarView(controller: _tabController, children: [
                    KeypadGrid(buttons: const ['C','⌫','%','/','7','8','9','*','4','5','6','-','1','2','3','+','0','.','^','EXE'], onButtonPressed: _onButtonPressed),
                    KeypadGrid(buttons: const ['sin(','cos(','tan(','x','ln(','log(','sqrt(','(','e','pi','!',')','abs(','deg','rad','EXE'], onButtonPressed: _onButtonPressed),
                    KeypadGrid(buttons: const ['solve','f(x)','d/dx','∫','factor','expand','lim','◀','simplify','=','▶',','], onButtonPressed: _onButtonPressed),
                    KeypadGrid(buttons: const ['STO','M1','M2','M3','DEL','M4','M5','M6','◀','M7','M8','M9','▶'], onButtonPressed: _onButtonPressed),
                ])),
              ])),
            ],
          ),
        ),
      ),
    );
  }
}