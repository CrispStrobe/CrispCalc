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
    print('INPUT: _onInputChanged triggered - text: "${_controller.text}", selection: ${_controller.selection}');
    
    // Handle post-calculation state
    if (_justCalculated && _controller.text.isNotEmpty) {
      print('CALC: Post-calculation input detected');
      final input = _controller.text;
      final lastResult = _appState.history.firstOrNull?.result ?? '0';

      // Prevent recursive listener calls
      _controller.removeListener(_onInputChanged);

      // If input is an operator, continue from last result
      if (['+', '-', '*', '/', '^', '%'].contains(input)) {
        final resultToUse = _extractNumericFromSolveResult(lastResult);
        _controller.text = resultToUse + input;
        print('CALC: Continuing from result: "$resultToUse" + "$input" = "${_controller.text}"');
      } else {
        print('CALC: Starting fresh with: "$input"');
      }

      // Move cursor to end
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
      
      setState(() { _justCalculated = false; });
      _controller.addListener(_onInputChanged);
    }
    
    _handleFunctionAutocomplete();
    setState(() => _updateLivePreview());
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
        _showSolveFunctionPicker();
      }
    }
  }
  
  /// Updates live preview of result as user types
  void _updateLivePreview() {
    String currentText = _controller.text;
    if (currentText.isEmpty || currentText.trim().toLowerCase().startsWith('solve')) {
      _resultPreview = '';
      return;
    }
    try {
      final preprocessed = _preprocessNativeExpression(_preprocessExpression(currentText));
      final result = _engine.evaluate(preprocessed);
      _resultPreview = (result != "Error" && result != currentText && double.tryParse(result) != null) ? result : '';
    } catch (e) {
      _resultPreview = '';
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
    print('\n=== BUTTON PRESSED: "$value" ===');
    print('Focus before: ${_inputFocusNode.hasFocus}');
    print('Current text: "${_controller.text}"');
    print('Current selection: ${_controller.selection}');
    
    switch (value) {
      case 'C':
        print('CLEAR: Clearing textfield');
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
        final currentSelection = _controller.selection;
        if (currentSelection.start > 0) {
          final newPos = currentSelection.start - 1;
          _controller.selection = TextSelection.collapsed(offset: newPos);
          print('CURSOR: Moved cursor left to position $newPos');
        }
        break;
      case '▶':
        final currentSelection = _controller.selection;
        if (currentSelection.end < _controller.text.length) {
          final newPos = currentSelection.end + 1;
          _controller.selection = TextSelection.collapsed(offset: newPos);
          print('CURSOR: Moved cursor right to position $newPos');
        }
        break;
      case 'solve':
        _insertTextAndPositionCursor('solve()', cursorOffset: -1);
        _showSolveFunctionPicker();
        break;
      case 'f(x)':
        _showFunctionPicker();
        break;
      // Function buttons that need cursor inside parentheses
      case 'sin(': case 'cos(': case 'tan(': case 'ln(': case 'log(': case 'sqrt(': case 'abs(':
        final funcName = value.substring(0, value.length - 1);
        _insertTextAndPositionCursor('$funcName()', cursorOffset: -1);
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
  
  /// Ensures focus without causing auto-selection
  void _ensureFocus() {
    if (!_inputFocusNode.hasFocus) {
      print('FOCUS: Need to request focus');
      _inputFocusNode.requestFocus();
      // The focus listener will handle preventing auto-selection
    } else {
      print('FOCUS: Already has focus');
    }
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

    // CRITICAL: Use TextEditingValue for atomic update
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newPosition.clamp(0, newText.length)),
    );
    
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
    
    if (selection.isCollapsed) {
      if (selection.start > 0) {
        final newText = currentText.substring(0, selection.start - 1) + currentText.substring(selection.start);
        final newPos = selection.start - 1;
        
        print('Single cursor backspace:');
        print('  Removing char at position ${selection.start - 1}');
        print('  New text: "$newText"');
        print('  New cursor: $newPos');
        
        // Ensure focus and set value atomically
        if (!_inputFocusNode.hasFocus) {
          _inputFocusNode.requestFocus();
        }
        
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newPos),
        );
      }
    } else {
      print('Selection backspace: deleting selected text');
      _insertTextAndPositionCursor('');
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
      final preprocessed = _preprocessNativeExpression(_preprocessExpression(expression));
      final result = _engine.evaluate(preprocessed);
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

  String _preprocessNativeExpression(String expression) {
    String p = expression;
    p = p.replaceAllMapped(RegExp(r'(\d|\))(\()'), (m) => '${m[1]}*${m[2]}');
    p = p.replaceAllMapped(RegExp(r'(\))(\d|[a-zA-Z])'), (m) => '${m[1]}*${m[2]}');
    p = p.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n <= 20) { int f=1; for(int i=1;i<=n;i++){f*=i;} return f.toString(); } 
      else { return 'gamma(${n + 1})'; }
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
    showModalBottomSheet(
      context: context, 
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Select equation to solve, or type manually:', 
                style: Theme.of(context).textTheme.titleMedium)
            ),
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
                        print('MODAL: Inserting solve function: Y${e.key+1}=0, x');
                        
                        // Insert at current cursor (inside solve parentheses)
                        final currentPos = _controller.selection.baseOffset;
                        final currentText = _controller.text;
                        final beforeCursor = currentText.substring(0, currentPos);
                        final afterCursor = currentText.substring(currentPos);
                        final insertText = 'Y${e.key+1}=0, x';
                        
                        if (!_inputFocusNode.hasFocus) {
                          _inputFocusNode.requestFocus();
                        }
                        
                        _controller.value = TextEditingValue(
                          text: beforeCursor + insertText + afterCursor,
                          selection: TextSelection.collapsed(offset: currentPos + insertText.length),
                        );
                      },
                    )).toList(),
              ),
            ),
          ]
        );
      }
    ).whenComplete(() {
      print('MODAL: Modal closed, ensuring focus');
      if (!_inputFocusNode.hasFocus) {
        _inputFocusNode.requestFocus();
      }
    });
  }
  
  void _showFunctionPicker() {
    showModalBottomSheet(
      context: context, 
      builder: (context) {
        return ListView(
          children: [
            const ListTile(
              title: Text('Select function to evaluate:', style: TextStyle(fontWeight: FontWeight.bold))
            ),
            const Divider(),
            ..._appState.graphFunctions.asMap().entries
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
            }).toList()
          ],
        );
      }
    ).whenComplete(() {
      print('MODAL: Function picker closed, ensuring focus');
      if (!_inputFocusNode.hasFocus) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  String _preprocessExpression(String expression) {
    String processed = expression;
    final funcRegex = RegExp(r'Y(\d+)');
    processed = processed.replaceAllMapped(funcRegex, (match) {
      try {
        final funcIndex = int.parse(match.group(1)!) - 1;
        if (funcIndex >= 0 && funcIndex < _appState.graphFunctions.length) {
          String funcBody = _appState.graphFunctions[funcIndex];
          if (funcBody.isNotEmpty) return '($funcBody)';
        }
      } catch (e) { 
        return match.group(0)!; 
      }
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