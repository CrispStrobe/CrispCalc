// lib/screens/calculator_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../engine/app_state.dart';
import '../engine/calculator_engine.dart';
import '../widgets/keypad_grid.dart';
import 'dart:io' show Platform;
import '../controllers/latex_controller.dart';
import '../engine/analysis_engine.dart';
import '../localization/app_localizations.dart';
import '../screens/matrix_editor_screen.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/latex_input_field.dart';


class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin {
  final AppState _appState = AppState();
  final CalculatorEngine _engine = CalculatorEngine();
  late final AnalysisEngine _analysisEngine;
  final Map<String, String> _memory = {};

  late TabController _tabController;
  final LatexController _latexController = LatexController();
  
  String _resultPreview = '';
  bool _justCalculated = false;

  @override
  void initState() {
    super.initState();
    _analysisEngine = AnalysisEngine(_engine);
    _tabController = TabController(length: 5, vsync: this);
    _latexController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _latexController.removeListener(_onInputChanged);
    _latexController.dispose();
    super.dispose();
  }

  void _debugKeyboardInput(KeyEvent event) {
    if (event is KeyDownEvent) {
      print('=== KEYBOARD DEBUG ===');
      print('Logical Key: ${event.logicalKey}');
      print('Physical Key: ${event.physicalKey}');
      print('Character: "${event.character}"');
      print('Key Label: "${event.logicalKey.keyLabel}"');
      print('========================');
    }
  }
  
  /// Allows parent widgets to request focus for the input field.
  void requestFocus() {
    // The LaTeX input field is always "focused" conceptually.
    print("Requesting focus for CalculatorScreen.");
  }

  /// Called whenever the input text changes.
  void _onInputChanged() {
    if (_justCalculated && _latexController.text.isNotEmpty) {
      final currentInput = _latexController.text.trim();
      
      // Check if user typed just an operator after calculation (including LaTeX operators)
      if (_isOperator(currentInput) || 
          (currentInput.length <= 6 && currentInput.startsWith(r'\cdot'))) {
        
        final lastResult = _appState.history.isNotEmpty ? _appState.history.first.result : '0';
        final cleanResult = _extractNumericFromSolveResult(lastResult);
        
        print('AUTO_ANS: Detected operator "$currentInput" after calculation, inserting Ans');
        
        // Remove listener to avoid recursion
        _latexController.removeListener(_onInputChanged);
        _latexController.clear();
        _latexController.insert('Ans$currentInput');
        _latexController.addListener(_onInputChanged);
        
        setState(() => _justCalculated = false);
        return;
      }
      
      // For any other input, clear the flag  
      setState(() => _justCalculated = false);
    }
    
    _updateLivePreview();
    setState(() {}); // Rebuild to show updated text
  }
  
  void _onInputChanged_old1() {
    if (_justCalculated && _latexController.text.isNotEmpty) {
      final currentInput = _latexController.text;
      
      // Check if user typed just an operator after calculation (for physical keyboard)
      if (currentInput.length == 1 && _isOperator(currentInput)) {
        final lastResult = _appState.history.isNotEmpty ? _appState.history.first.result : '0';
        final cleanResult = _extractNumericFromSolveResult(lastResult);
        
        print('AUTO_ANS: Detected operator "$currentInput" after calculation, inserting Ans');
        
        // Remove listener to avoid recursion
        _latexController.removeListener(_onInputChanged);
        _latexController.clear();
        _latexController.insert('Ans$currentInput');
        _latexController.addListener(_onInputChanged);
        
        setState(() => _justCalculated = false);
        return; // Exit early to avoid double processing
      }
      
      // For any other input, clear the flag
      setState(() => _justCalculated = false);
    }
    
    _updateLivePreview();
    setState(() {}); // Rebuild to show updated text
  }

  void _onInputChanged_old() {
    if (_justCalculated && _latexController.text.isNotEmpty) {
      setState(() => _justCalculated = false);
    }
    _updateLivePreview();
    setState(() {}); // Rebuild to show updated text
  }

  void _updateLivePreview() {
    String currentText = _latexController.text.trim();
    
    if (currentText.isEmpty || 
        currentText.toLowerCase().startsWith('solve') ||
        currentText.contains('=') ||
        currentText.length < 2 ||
        RegExp(r'^[a-zA-Z]+$').hasMatch(currentText)) {
        setState(() { _resultPreview = ''; });
        return;
    }
    
    if (!RegExp(r'[\d\+\-\*/\^\(\)\.\,\\]').hasMatch(currentText)) {
        setState(() { _resultPreview = ''; });
        return;
    }
    
    try {
        final convertedExpression = _fromLatex(currentText);
        final preprocessed = _preprocessNativeExpression(_preprocessExpression(convertedExpression));
        final rawResult = _engine.evaluate(preprocessed);
        
        final normalizedResult = _normalizeComplexResult(rawResult);
        
        if (normalizedResult != "Error" && 
            normalizedResult != currentText && 
            normalizedResult != preprocessed) {
            
            final numericResult = double.tryParse(normalizedResult);
            if (numericResult != null) {
                setState(() { _resultPreview = normalizedResult; });
            } else if (!normalizedResult.contains('Error')) {
                setState(() { _resultPreview = normalizedResult; });
            } else {
                setState(() { _resultPreview = ''; });
            }
        } else {
        setState(() { _resultPreview = ''; });
        }
    } catch (e) {
        setState(() { _resultPreview = ''; });
    }
  }

  bool handleKeyboardInput(KeyEvent event) {
    _debugKeyboardInput(event);
    
    if (event is! KeyDownEvent) return false;

    final physicalKey = event.physicalKey;
    final logicalKey = event.logicalKey;
    final character = event.character;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;

    // --- GERMAN KEYBOARD PHYSICAL KEY MAPPINGS ---
    
    // Key: `+` and `*` (Physical location of `]` on a US keyboard)
    if (physicalKey == PhysicalKeyboardKey.bracketRight) {
      _latexController.insert(isShiftPressed ? r'\cdot ' : '+');
      return true;
    }
    
    // Key: `-` (Physical location of `/` on a US keyboard)
    if (physicalKey == PhysicalKeyboardKey.slash && !isShiftPressed) {
      _latexController.insert('-');
      return true;
    }
    
    // Key: `/` (This is Shift + 7 on a German keyboard)
    if (physicalKey == PhysicalKeyboardKey.digit7 && isShiftPressed) {
      _latexController.insert('/');
      return true;
    }

    // Parentheses: Shift+8 and Shift+9 on German keyboard
    if (physicalKey == PhysicalKeyboardKey.digit8 && isShiftPressed) {
      _latexController.insert('(');
      return true;
    }
    if (physicalKey == PhysicalKeyboardKey.digit9 && isShiftPressed) {
      _latexController.insert(')');
      return true;
    }

    // Equal sign: Shift+0 on German keyboard
    if (physicalKey == PhysicalKeyboardKey.digit0 && isShiftPressed) {
      _latexController.insert('=');
      return true;
    }

    // --- UNIVERSAL ACTION KEYS ---
    if (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter) {
      _onButtonPressed("EXE"); return true;
    }
    if (logicalKey == LogicalKeyboardKey.escape) {
      _onButtonPressed('C'); return true;
    }
    if (logicalKey == LogicalKeyboardKey.backspace) {
      _latexController.backspace(); return true;
    }
    if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      _latexController.moveCursor(-1); return true;
    }
    if (logicalKey == LogicalKeyboardKey.arrowRight) {
      _latexController.moveCursor(1); return true;
    }

    // --- STANDARD CHARACTER INPUT ---
    if (character != null && character.isNotEmpty) {
      final charCode = character.codeUnitAt(0);
      if (charCode < 0xF700 && charCode >= 32) {
        switch (character) {
          case '*':
            _latexController.insert(r'\cdot ');
            break;
          case '^':
            _latexController.insert('^{}', cursorOffsetFromEnd: -1);
            break;
          default:
            _latexController.insert(character);
        }
        return true;
      }
    }

    // --- NUMPAD FALLBACKS ---
    switch (logicalKey) {
      case LogicalKeyboardKey.numpadAdd:
        _latexController.insert('+'); return true;
      case LogicalKeyboardKey.numpadSubtract:
        _latexController.insert('-'); return true;
      case LogicalKeyboardKey.numpadMultiply:
        _latexController.insert(r'\cdot '); return true;
      case LogicalKeyboardKey.numpadDivide:
        _latexController.insert('/'); return true;
      case LogicalKeyboardKey.numpadDecimal:
        _latexController.insert('.'); return true;
      case LogicalKeyboardKey.equal:
        _onButtonPressed("EXE"); return true;
    }

    return false;
  }

  Map<String, String> _getKeyboardCorrections(String locale) {
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

  void _onButtonPressed(String value) async {
    if (_justCalculated && _isOperator(value) && _appState.history.isNotEmpty) {
      _latexController.insert('Ans');
    }

    switch (value) {
      case 'C':
        _latexController.clear();
        setState(() { _justCalculated = false; });
        break;
      
      case '⌫':
        _latexController.backspace();
        break;
      
      case 'EXE':
        if (_latexController.text.isNotEmpty) {
          await _calculate(_latexController.text);
        }
        break;
      
      case '◀':
        _latexController.moveCursor(-1);
        break;
      
      case '▶':
        _latexController.moveCursor(1);
        break;

      // -- Storage --
      case 'STO':
        _showStoreDialog();
        break;

      // Update the memory buttons M1-M9:
      case 'M1': case 'M2': case 'M3': case 'M4': case 'M5': 
      case 'M6': case 'M7': case 'M8': case 'M9':
        final memIndex = int.parse(value.substring(1)) - 1;
        if (_memory.containsKey('M$memIndex')) {
          _latexController.insert(_memory['M$memIndex']!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Memory M${memIndex + 1} is empty')),
          );
        }
        break;

      case 'DEL':
        _showDeleteMemoryDialog();
        break;
      
      // --- LaTeX Template Insertions ---
      case '/': // This is the BUTTON press, should create fractions
        _latexController.insert(r'\frac{}{}', cursorOffsetFromEnd: -4);
        break;
      
      case 'sqrt':
        _latexController.insert(r'\sqrt{}', cursorOffsetFromEnd: -1);
        break;
      
      case 'sin':
        _latexController.insert(r'\sin()', cursorOffsetFromEnd: -1);
        break;
      
      case 'cos':
        _latexController.insert(r'\cos()', cursorOffsetFromEnd: -1);
        break;
      
      case 'tan':
        _latexController.insert(r'\tan()', cursorOffsetFromEnd: -1);
        break;
      
      case 'ln':
        _latexController.insert(r'\ln()', cursorOffsetFromEnd: -1);
        break;
      
      case 'log':
        _latexController.insert(r'\log()', cursorOffsetFromEnd: -1);
        break;
      
      case 'abs':
        _latexController.insert(r'abs()', cursorOffsetFromEnd: -1);
        break;

      case 'asin':
        _latexController.insert(r'\arcsin()', cursorOffsetFromEnd: -1);
        break;
      
      case 'acos':
        _latexController.insert(r'\arccos()', cursorOffsetFromEnd: -1);
        break;
      
      case 'atan':
        _latexController.insert(r'\arctan()', cursorOffsetFromEnd: -1);
        break;

      case 'sinh':
        _latexController.insert(r'\sinh()', cursorOffsetFromEnd: -1);
        break;
      
      case 'cosh':
        _latexController.insert(r'\cosh()', cursorOffsetFromEnd: -1);
        break;
      
      case 'tanh':
        _latexController.insert(r'\tanh()', cursorOffsetFromEnd: -1);
        break;

      case '^':
        _latexController.insert(r'^{}', cursorOffsetFromEnd: -1);
        break;

      case '_':
        _latexController.insert(r'_{}', cursorOffsetFromEnd: -1);
        break;

      case 'π':
        _latexController.insert(r'\pi');
        break;
      
      case 'e':
        _latexController.insert('E');
        break;
      
      case 'γ':
        _latexController.insert('EulerGamma');
        break;

      case 'solve':
        _latexController.insert('solve()', cursorOffsetFromEnd: -1);
        _showSolveFunctionPicker();
        break;

      case 'factor':
        _latexController.insert('factor()', cursorOffsetFromEnd: -1);
        break;

      case 'expand':
        _latexController.insert('expand()', cursorOffsetFromEnd: -1);
        break;

      case 'simplify':
        _latexController.insert('simplify()', cursorOffsetFromEnd: -1);
        break;

      case 'd/dx':
        _latexController.insert(r'\frac{d}{dx}()', cursorOffsetFromEnd: -1);
        break;

      case 'gcd':
        _latexController.insert('gcd(,)', cursorOffsetFromEnd: -2);
        break;

      case 'lcm':
        _latexController.insert('lcm(,)', cursorOffsetFromEnd: -2);
        break;

      case '∫':
        await _showIntegralDialog();
        break;
      
      case 'ⁿ√x':
        await _showNthRootDialog();
        break;
      
      case 'lim':
        await _showLimitDialog();
        break;
      
      case 'matrix':
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (context) => const MatrixEditorScreen()),
        );
        if (result != null) _latexController.insert(result);
        break;

      case 'f(x)':
        _showFunctionPicker();
        break;

      case 'Ans':
        if (_appState.history.isNotEmpty) {
          _latexController.insert('Ans');
        }
        break;

      // === Advanced Mathematical Functions ===
      
      case 'gamma':
        _latexController.insert(r'\Gamma()', cursorOffsetFromEnd: -1);
        break;
      
      case '!':
        // Factorial - append to current expression
        _latexController.insert('!');
        break;
      
      case '∞':
        _latexController.insert(r'\infty');
        break;
      
      case 'fib':
        _latexController.insert('fib()', cursorOffsetFromEnd: -1);
        break;
      
      case 'prime':
        _latexController.insert('isprime()', cursorOffsetFromEnd: -1);
        break;
      
      case 'mod':
        _latexController.insert(' \\bmod ', cursorOffsetFromEnd: 0);
        break;

      // === Matrix Operations ===
      
      case 'det':
        _latexController.insert('det()', cursorOffsetFromEnd: -1);
        break;
      
      case 'inv':
        _latexController.insert('inv()', cursorOffsetFromEnd: -1);
        break;
      
      case 'transpose':
        _latexController.insert('transpose()', cursorOffsetFromEnd: -1);
        break;

      // === Hyperbolic Inverse Functions ===
      
      case 'asinh':
        _latexController.insert(r'asinh()', cursorOffsetFromEnd: -1);
        break;
      
      case 'acosh':
        _latexController.insert(r'acosh()', cursorOffsetFromEnd: -1);
        break;
      
      case 'atanh':
        _latexController.insert(r'atanh()', cursorOffsetFromEnd: -1);
        break;

      default:
        _latexController.insert(value);
        break;
    }
  }

  // Helper method to check if a value is an operator
  bool _isOperator(String value) {
    return ['+', '-', '*', '/', '^', '%', '=', r'\cdot', r'\times', r'\div'].contains(value);
  }

  void _showStoreDialog() {
    if (_appState.history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No result to store')),
      );
      return;
    }

    final lastResult = _appState.history.first.result;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Store: $lastResult'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showSaveAsVariableDialog(lastResult);
                    },
                    child: const Text('Save as Variable'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showSaveToMemoryDialog(lastResult);
                    },
                    child: const Text('Save to Memory'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSaveAsVariableDialog(String value) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Variable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Variable Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., result1',
              ),
            ),
            const SizedBox(height: 8),
            Text('Value: $value'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _appState.setVariable(name, value);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved $name = $value')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSaveToMemoryDialog(String value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Memory'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // Fixed height to prevent overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Save: $value'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: List.generate(9, (i) => ListTile(
                    title: Text('M${i + 1}'),
                    subtitle: Text(_memory['M$i'] ?? 'Empty'),
                    onTap: () {
                      _memory['M$i'] = value;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved to M${i + 1}')),
                      );
                    },
                  )),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMemoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // Fixed height to prevent overflow
          child: ListView(
            shrinkWrap: true,
            children: List.generate(9, (i) => ListTile(
              title: Text('M${i + 1}'),
              subtitle: Text(_memory['M$i'] ?? 'Empty'),
              trailing: _memory['M$i'] != null ? IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _memory.remove('M$i');
                  });
                },
              ) : null,
            )),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _memory.clear();
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All memory cleared')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  String _normalizeComplexResult(String result) {
    if (result.isEmpty) return result;
    
    String normalized = result.trim();
    
    print('NORMALIZE: Input: "$normalized"');
    
    normalized = normalized.replaceAll(RegExp(r'\s*[+\-]\s*0(\.0*)?(\s*\*\s*I|\s*I)\s*'), '');
    normalized = normalized.replaceAll(RegExp(r'\s*\+\s*0\.0\s*\*\s*I\s*\*\s*\d+'), '');
    normalized = normalized.replaceAll(RegExp(r'\s*\*\s*I\s*\*\s*\d+\s*$'), '');
    normalized = normalized.replaceAll(RegExp(r'^\s*0(\.0*)?\s*\*\s*I\s*$'), '0');
    normalized = normalized.replaceAll(RegExp(r'(\d+)\s*\*\s*I\b'), r'\1i');
    normalized = normalized.replaceAll(RegExp(r'\bI\b'), 'i');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s*\+\s*'), ' + ');
    normalized = normalized.replaceAll(RegExp(r'\s*\-\s*'), ' - ');
    normalized = normalized.replaceAll(RegExp(r'\s*\*\s*'), '*');
    normalized = normalized.trim();
    
    if (RegExp(r'^[\+\-\*\s]*$').hasMatch(normalized)) {
      normalized = result;
    }
    
    // Clean up decimal zeros (0.0 -> 0)
    // normalized = normalized.replaceAll(RegExp(r'\.0+(?!\d)'), '');
    
    // Handle pure real numbers that show as "5.0 + 0.0*I"  
    normalized = normalized.replaceAll(RegExp(r'^([+-]?\d+(?:\.\d+)?)\s*\+\s*0\.0\s*\*\s*I$'), r'\1');
    
    // Fix Python-style exponents (**) to readable format
    normalized = normalized.replaceAll('**2', '²');
    normalized = normalized.replaceAll('**3', '³');
    normalized = normalized.replaceAllMapped(RegExp(r'\*\*(\d+)'), (m) => '^${m.group(1)}');
    
    // Clean up multiplication formatting for display
    normalized = normalized.replaceAllMapped(RegExp(r'(\d+)\s*\*\s*([a-zA-Z])(?!\*)'), (m) => '${m.group(1)}${m.group(2)}');
    
    if (RegExp(r'^[\+\-\*\s]*$').hasMatch(normalized)) {
      normalized = result;
    }
    
    print('NORMALIZE: Output: "$normalized"');
    return normalized;
  }

  Future<void> _calculate(String expression) async {
    print('\n=== CALCULATING: "$expression" ===');
    try {
      // STEP 1: Check for assignment (variable = value)
      final assignmentMatch = RegExp(r'^([a-zA-Z][a-zA-Z0-9]*)\s*=\s*(.+)$').firstMatch(expression.trim());
      if (assignmentMatch != null) {
        await _handleAssignment(expression, assignmentMatch);
        return;
      }

      // STEP 2: Check for function definition (F1 = expression, Y1 = expression)
      final functionMatch = RegExp(r'^([FY])(\d+)\s*=\s*(.+)$').firstMatch(expression.trim());
      if (functionMatch != null) {
        await _handleFunctionDefinition(expression, functionMatch);
        return;
      }

      // STEP 3: Convert LaTeX to engine-compatible syntax
      String convertedExpression = _fromLatex(expression);
      print('CALC: Converted from LaTeX: "$convertedExpression"');
      
      String result;
      
      // Handle different function types
      if (convertedExpression.trim().startsWith('solve(') && convertedExpression.trim().endsWith(')')) {
        print('CALC: Detected solve() function, handling specially');
        result = _handleSolveFunction(convertedExpression.trim());
      } else if (convertedExpression.trim().startsWith('d/dx(') && convertedExpression.trim().endsWith(')')) {
        print('CALC: Detected differentiation function');
        result = _handleDifferentiateFunction(convertedExpression.trim());
      } else if (convertedExpression.trim().startsWith('factor(') && convertedExpression.trim().endsWith(')')) {
        print('CALC: Detected factor function');
        result = _handleFactorFunction(convertedExpression.trim());
      } else if (convertedExpression.trim().startsWith('expand(') && convertedExpression.trim().endsWith(')')) {
        print('CALC: Detected expand function');
        result = _handleExpandFunction(convertedExpression.trim());
      } else if (convertedExpression.trim().startsWith('simplify(') && convertedExpression.trim().endsWith(')')) {
        print('CALC: Detected simplify function');
        result = _handleSimplifyFunction(convertedExpression.trim());
      } else if (convertedExpression.trim().startsWith('gcd(') && convertedExpression.trim().endsWith(')')) {
        print('CALC: Detected GCD function');
        result = _handleGcdFunction(convertedExpression.trim());
      } else if (convertedExpression.trim().startsWith('lcm(') && convertedExpression.trim().endsWith(')')) {
        print('CALC: Detected LCM function');
        result = _handleLcmFunction(convertedExpression.trim());
      } else {
        // STEP 4: Replace variables with their values
        convertedExpression = _substituteVariables(convertedExpression);
        
        // Normal expression evaluation with preprocessing
        final preprocessed = _preprocessNativeExpression(_preprocessExpression(convertedExpression));
        print('CALC: Preprocessed expression: "$preprocessed"');
        
        final rawResult = _engine.evaluate(preprocessed);
        print('CALC: Raw result from engine: "$rawResult"');
        
        result = _normalizeComplexResult(rawResult);
      }
      
      print('CALC: Final result: "$result"');
      
      setState(() {
        // _appState.addHistoryEntry(expression, result);
        _appState.addHistoryEntry(_latexToReadable(expression), result);
        _resultPreview = '';
        _justCalculated = true;
        _latexController.clear();
      });
      
      print('CALC: Added to history, cleared input, set _justCalculated = true');
    } catch (e) {
      print('CALC: Calculation error: $e');
      setState(() => _appState.addHistoryEntry(expression, "Error: ${e.toString()}"));
    }
    print('=== END CALCULATION ===\n');
  }

  Future<void> _handleAssignment(String originalExpression, RegExpMatch match) async {
    final name = match.group(1)!;
    final valueExpression = match.group(2)!;
    
    print('ASSIGNMENT: Variable "$name" = "$valueExpression"');
    
    try {
      // Convert the value expression and evaluate it
      final convertedValue = _fromLatex(valueExpression);
      final substitutedValue = _substituteVariables(convertedValue);
      final preprocessed = _preprocessNativeExpression(_preprocessExpression(substitutedValue));
      final evaluatedValue = _engine.evaluate(preprocessed);
      final normalizedValue = _normalizeComplexResult(evaluatedValue);
      
      if (normalizedValue != "Error" && !normalizedValue.contains("Error")) {
        _appState.setVariable(name, normalizedValue);
        setState(() {
          _appState.addHistoryEntry(originalExpression, "Stored $name = $normalizedValue");
          _justCalculated = true;
          _latexController.clear();
        });
      } else {
        setState(() {
          _appState.addHistoryEntry(originalExpression, "Error: Could not evaluate $valueExpression");
          _latexController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _appState.addHistoryEntry(originalExpression, "Error: Invalid assignment");
        _latexController.clear();
      });
    }
  }

  Future<void> _handleFunctionDefinition(String originalExpression, RegExpMatch match) async {
    final functionType = match.group(1)!; // 'F' or 'Y'
    final functionIndex = int.parse(match.group(2)!) - 1; // Convert to 0-based index
    final functionExpression = match.group(3)!;
    
    print('FUNCTION_DEF: $functionType${functionIndex + 1} = "$functionExpression"');
    
    try {
      final convertedExpression = _fromLatex(functionExpression);
      
      if (functionType == 'Y') {
        // Graph function (Y1, Y2, etc.)
        if (functionIndex >= 0 && functionIndex < _appState.graphFunctions.length) {
          _appState.updateFunction(functionIndex, convertedExpression);
          setState(() {
            _appState.addHistoryEntry(originalExpression, "Stored Y${functionIndex + 1}");
            _justCalculated = true;
            _latexController.clear();
          });
        } else {
          setState(() => _appState.addHistoryEntry(originalExpression, "Error: Invalid function index"));
        }
      } else if (functionType == 'F') {
        // User function (F1, F2, etc.)
        if (functionIndex >= 0 && functionIndex < _appState.userFunctions.length) {
          _appState.updateUserFunction(functionIndex, convertedExpression);
          setState(() {
            _appState.addHistoryEntry(originalExpression, "Stored F${functionIndex + 1}");
            _justCalculated = true;
            _latexController.clear();
          });
        } else {
          setState(() => _appState.addHistoryEntry(originalExpression, "Error: Invalid function index"));
        }
      }
    } catch (e) {
      setState(() {
        _appState.addHistoryEntry(originalExpression, "Error: Invalid function definition");
        _latexController.clear();
      });
    }
  }

  /// Substitutes variable names with their stored values in an expression
  String _substituteVariables(String expression) {
    String result = expression;
    
    // Replace 'Ans' with the last calculation result
    if (result.contains('Ans')) {
      final lastResult = _appState.history.isNotEmpty ? _appState.history.first.result : '0';
      final cleanResult = _extractNumericFromSolveResult(lastResult);
      result = result.replaceAll('Ans', cleanResult);
    }
    
    // Replace user-defined variables
    for (final entry in _appState.userVariables.entries) {
      final variableName = entry.key;
      final variableValue = entry.value;
      
      // Use word boundaries to avoid partial replacements
      final pattern = RegExp(r'\b' + RegExp.escape(variableName) + r'\b');
      result = result.replaceAll(pattern, '($variableValue)');
    }
    
    print('SUBSTITUTE: "$expression" -> "$result"');
    return result;
  }

  String _extractNumericFromSolveResult(String solveResult) {
    // Extract numeric value from solve results like "x = 5" -> "5"
    final match = RegExp(r'[a-zA-Z]\s*=\s*([+-]?[\d.]+)\s*$').firstMatch(solveResult);
    if (match != null && !match.group(1)!.contains(',')) {
      return match.group(1)!.trim();
    }
    return solveResult;
  }

  Future<void> _showIntegralDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => IntegralDialog(),
    );
    if (result != null) {
      _latexController.insert(result);
    }
  }

  Future<void> _showNthRootDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => NthRootDialog(),
    );
    if (result != null) {
      _latexController.insert(result);
    }
  }

  Future<void> _showLimitDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => LimitDialog(),
    );
    if (result != null) {
      _latexController.insert(result);
    }
  }

  /// Converts the LaTeX string from the input field to SymEngine-compatible syntax.
  /// Enhanced _fromLatex function that handles all LaTeX syntax from our keypad
  String _fromLatex(String latex) {
    String result = latex;
    
    print('LATEX_CONVERT: Input: "$latex"');
    
    // Remove the cursor character if present
    result = result.replaceAll('|', '');

    // === STEP 1: Handle complex structures first (order matters!) ===
    
    // Handle nth roots: \sqrt[n]{expr} -> (expr)^(1/n)
    result = result.replaceAllMapped(RegExp(r'\\sqrt\[([^\]]+)\]\{([^}]+)\}'), (m) {
      final n = m.group(1)!;
      final expr = m.group(2)!;
      return '($expr)^(1/$n)';
    });
    
    // Handle square roots: \sqrt{expr} -> sqrt(expr)
    result = result.replaceAllMapped(RegExp(r'\\sqrt\{([^}]+)\}'), (m) {
      return 'sqrt(${m.group(1)})';
    });
    
    // Handle fractions: \frac{num}{den} -> (num)/(den)
    result = result.replaceAllMapped(RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'), (m) {
      return '(${m.group(1)})/(${m.group(2)})';
    });
    
    // Handle differentiation: \frac{d}{dx}(expr) -> d/dx(expr)
    result = result.replaceAllMapped(RegExp(r'\\frac\{d\}\{d([a-zA-Z])\}\(([^)]+)\)'), (m) {
      return 'd/d${m.group(1)}(${m.group(2)})';
    });
    
    // Handle differentiation with braces: \frac{d}{dx}{expr} -> d/dx(expr)
    result = result.replaceAllMapped(RegExp(r'\\frac\{d\}\{d([a-zA-Z])\}\{([^}]+)\}'), (m) {
      return 'd/d${m.group(1)}(${m.group(2)})';
    });
    
    // === STEP 2: Handle function notation with braces ===
    
    // Trigonometric functions: \sin{expr} -> sin(expr)
    result = result.replaceAllMapped(RegExp(r'\\(sin|cos|tan|csc|sec|cot)\{([^}]+)\}'), (m) {
      return '${m.group(1)}(${m.group(2)})';
    });
    
    // Inverse trigonometric functions: \arcsin{expr} -> asin(expr)
    result = result.replaceAllMapped(RegExp(r'\\arc(sin|cos|tan|csc|sec|cot)\{([^}]+)\}'), (m) {
      final func = m.group(1)!;
      final expr = m.group(2)!;
      return 'a$func($expr)';
    });
    
    // Hyperbolic functions: \sinh{expr} -> sinh(expr)
    result = result.replaceAllMapped(RegExp(r'\\(sinh|cosh|tanh|csch|sech|coth)\{([^}]+)\}'), (m) {
      return '${m.group(1)}(${m.group(2)})';
    });
    
    // Inverse hyperbolic functions: \asinh{expr} -> asinh(expr)
    result = result.replaceAllMapped(RegExp(r'\\a(sinh|cosh|tanh|csch|sech|coth)\{([^}]+)\}'), (m) {
      return 'a${m.group(1)}(${m.group(2)})';
    });
    
    // Logarithmic functions: \ln{expr} -> ln(expr), \log{expr} -> log(expr)
    result = result.replaceAllMapped(RegExp(r'\\(ln|log)\{([^}]+)\}'), (m) {
      return '${m.group(1)}(${m.group(2)})';
    });
    
    // Logarithm with base: \log_{base}{expr} -> log(expr)/log(base)
    result = result.replaceAllMapped(RegExp(r'\\log_\{([^}]+)\}\{([^}]+)\}'), (m) {
      final base = m.group(1)!;
      final expr = m.group(2)!;
      return 'log($expr)/log($base)';
    });
    
    // === STEP 3: Handle function notation with parentheses (already correct) ===
    
    // These are already in correct format: \sin(expr) -> sin(expr)
    result = result.replaceAllMapped(RegExp(r'\\(sin|cos|tan|csc|sec|cot|sinh|cosh|tanh|csch|sech|coth|ln|log|sqrt|abs)\('), (m) {
      return '${m.group(1)}(';
    });
    
    // Inverse trig with parentheses: \arcsin(expr) -> asin(expr)
    result = result.replaceAllMapped(RegExp(r'\\arc(sin|cos|tan|csc|sec|cot)\('), (m) {
      return 'a${m.group(1)}(';
    });
    
    // === STEP 4: Handle power and subscript notation ===
    
    // Powers with braces: x^{expr} -> x^(expr)
    result = result.replaceAllMapped(RegExp(r'\^\{([^}]+)\}'), (m) {
      final exp = m.group(1)!;
      // If it's a single character/number, parentheses aren't needed
      if (RegExp(r'^[a-zA-Z0-9]$').hasMatch(exp)) {
        return '^$exp';
      }
      return '^($exp)';
    });
    
    // Subscripts with braces: x_{expr} -> x_expr (though SymEngine may not need this)
    result = result.replaceAllMapped(RegExp(r'_\{([^}]+)\}'), (m) {
      return '_${m.group(1)}';
    });
    
    // === STEP 5: Handle constants and symbols ===
    
    // Greek letters and constants
    result = result.replaceAll(r'\pi', 'pi');
    result = result.replaceAll(r'\Pi', 'Pi');
    result = result.replaceAll(r'\e', 'E');
    result = result.replaceAll(r'\gamma', 'EulerGamma');
    result = result.replaceAll(r'\Gamma', 'gamma');
    result = result.replaceAll(r'\alpha', 'alpha');
    result = result.replaceAll(r'\beta', 'beta');
    result = result.replaceAll(r'\delta', 'delta');
    result = result.replaceAll(r'\Delta', 'Delta');
    result = result.replaceAll(r'\theta', 'theta');
    result = result.replaceAll(r'\Theta', 'Theta');
    result = result.replaceAll(r'\lambda', 'lambda');
    result = result.replaceAll(r'\Lambda', 'Lambda');
    result = result.replaceAll(r'\mu', 'mu');
    result = result.replaceAll(r'\sigma', 'sigma');
    result = result.replaceAll(r'\Sigma', 'Sigma');
    result = result.replaceAll(r'\phi', 'phi');
    result = result.replaceAll(r'\Phi', 'Phi');
    result = result.replaceAll(r'\omega', 'omega');
    result = result.replaceAll(r'\Omega', 'Omega');
    
    // Special constants
    result = result.replaceAll(r'\infty', 'oo');
    result = result.replaceAll(r'\infinity', 'oo');
    
    // === STEP 6: Handle operators ===
    
    // Multiplication symbols
    result = result.replaceAll(r'\cdot', '*');
    result = result.replaceAll(r'\times', '*');
    result = result.replaceAll(r'\ast', '*');
    
    // Division symbols (though we prefer \frac)
    result = result.replaceAll(r'\div', '/');
    
    // Plus/minus
    result = result.replaceAll(r'\pm', '+-');
    result = result.replaceAll(r'\mp', '-+');
    
    // === STEP 7: Handle absolute values and norms ===
    
    // Absolute values: |expr| -> abs(expr)
    // This is tricky because we need to match paired pipes
    result = result.replaceAllMapped(RegExp(r'\|([^|]+)\|'), (m) {
      return 'abs(${m.group(1)})';
    });
    
    // === STEP 8: Handle integrals (basic form) ===
    
    // Simple integral: \int expr dx -> integrate(expr, x)
    result = result.replaceAllMapped(RegExp(r'\\int\s+([^d]+)\s+d([a-zA-Z])'), (m) {
      final expr = m.group(1)!.trim();
      final variable = m.group(2)!;
      return 'integrate($expr, $variable)';
    });
    
    // Definite integral: \int_{a}^{b} expr dx -> integrate(expr, (x, a, b))
    result = result.replaceAllMapped(RegExp(r'\\int_\{([^}]+)\}\^\{([^}]+)\}\s+([^d]+)\s+d([a-zA-Z])'), (m) {
      final lower = m.group(1)!;
      final upper = m.group(2)!;
      final expr = m.group(3)!.trim();
      final variable = m.group(4)!;
      return 'integrate($expr, ($variable, $lower, $upper))';
    });
    
    // === STEP 9: Handle limits ===
    
    // Basic limit: \lim_{x \to a} expr -> limit(expr, x, a)
    result = result.replaceAllMapped(RegExp(r'\\lim_\{([a-zA-Z])\s*\\to\s*([^}]+)\}\s*(.+)'), (m) {
      final variable = m.group(1)!;
      final approaches = m.group(2)!;
      final expr = m.group(3)!;
      return 'limit($expr, $variable, $approaches)';
    });
    
    // === STEP 10: Handle matrices (basic support) ===
    
    // Simple matrix notation: \begin{matrix} ... \end{matrix}
    // This is complex and might need special handling depending on SymEngine's matrix syntax
    
    // === STEP 11: Handle summations and products ===
    
    // Summation: \sum_{i=1}^{n} expr -> Sum(expr, (i, 1, n))
    result = result.replaceAllMapped(RegExp(r'\\sum_\{([a-zA-Z])=([^}]+)\}\^\{([^}]+)\}\s*(.+)'), (m) {
      final variable = m.group(1)!;
      final start = m.group(2)!;
      final end = m.group(3)!;
      final expr = m.group(4)!;
      return 'Sum($expr, ($variable, $start, $end))';
    });
    
    // Product: \prod_{i=1}^{n} expr -> Product(expr, (i, 1, n))
    result = result.replaceAllMapped(RegExp(r'\\prod_\{([a-zA-Z])=([^}]+)\}\^\{([^}]+)\}\s*(.+)'), (m) {
      final variable = m.group(1)!;
      final start = m.group(2)!;
      final end = m.group(3)!;
      final expr = m.group(4)!;
      return 'Product($expr, ($variable, $start, $end))';
    });
    
    // === STEP 12: Handle braces (convert to parentheses where needed) ===
    
    // Convert remaining \{ and \} to regular braces (for grouping)
    result = result.replaceAll(r'\{', '{');
    result = result.replaceAll(r'\}', '}');
    
    // === STEP 13: Clean up spacing ===
    
    // Remove extra spaces around operators
    result = result.replaceAll(RegExp(r'\s*\*\s*'), '*');
    result = result.replaceAll(RegExp(r'\s*\+\s*'), '+');
    result = result.replaceAll(RegExp(r'\s*-\s*'), '-');
    result = result.replaceAll(RegExp(r'\s*/\s*'), '/');
    result = result.replaceAll(RegExp(r'\s*\^\s*'), '^');
    
    // Remove multiple spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    print('LATEX_CONVERT: Output: "$result"');
    
    return result;
  }

  String _fromLatexEnhanced(String latex) {
    String result = _fromLatex(latex); // Call the existing function first
    
    // Handle additional advanced LaTeX syntax
    
    // Modulo operation: a \bmod b -> a mod b
    result = result.replaceAllMapped(RegExp(r'(.+?)\s*\\bmod\s*(.+)'), (m) {
      return '${m.group(1)} mod ${m.group(2)}';
    });
    
    // Gamma function: \Gamma(x) -> gamma(x)
    result = result.replaceAll(r'\Gamma', 'gamma');
    
    // Factorial handling is already in _preprocessNativeExpression
    
    // Floor and ceiling functions
    result = result.replaceAllMapped(RegExp(r'\\lfloor\s*(.+?)\s*\\rfloor'), (m) {
      return 'floor(${m.group(1)})';
    });
    
    result = result.replaceAllMapped(RegExp(r'\\lceil\s*(.+?)\s*\\rceil'), (m) {
      return 'ceiling(${m.group(1)})';
    });
    
    // Binomial coefficients: \binom{n}{k} -> binomial(n, k)
    result = result.replaceAllMapped(RegExp(r'\\binom\{([^}]+)\}\{([^}]+)\}'), (m) {
      return 'binomial(${m.group(1)}, ${m.group(2)})';
    });
    
    return result;
  }

  String _handleSolveFunction(String expression) {
    print('SOLVE: Processing solve function: "$expression"');
    
    try {
      final solveContent = expression.substring(6, expression.length - 1).trim();
      print('SOLVE: Content inside solve(): "$solveContent"');
      
      String equation;
      String variable;
      
      final parts = solveContent.split(',');
      if (parts.length == 1) {
        equation = parts[0].trim();
        variable = _detectVariable(equation);
        print('SOLVE: Auto-detected variable: "$variable"');
      } else if (parts.length == 2) {
        equation = parts[0].trim();
        variable = parts[1].trim();
        print('SOLVE: Explicit variable provided: "$variable"');
      } else {
        print('SOLVE: Error - Too many parameters');
        return 'Error: solve() format: solve(equation) or solve(equation, variable)';
      }
      
      print('SOLVE: Equation: "$equation", Variable: "$variable"');
      
      if (equation.contains('=')) {
        final eqParts = equation.split('=');
        if (eqParts.length == 2) {
          final leftSide = eqParts[0].trim();
          final rightSide = eqParts[1].trim();
          
          if (rightSide == '0' || rightSide.isEmpty) {
            equation = leftSide;
          } else {
            equation = '$leftSide - ($rightSide)';
          }
          print('SOLVE: Converted equation to: "$equation"');
        }
      }
      
      final preprocessed = _preprocessNativeExpression(_preprocessExpression(equation));
      print('SOLVE: Preprocessed equation: "$preprocessed"');
      
      return _engine.solve(preprocessed, variable);
      
    } catch (e) {
      print('SOLVE: Error parsing solve function: $e');
      return 'Error: Invalid solve() syntax';
    }
  }

  String _handleDifferentiateFunction(String expression) {
    try {
      final content = expression.substring(5, expression.length - 1).trim();
      final parts = content.split(',');
      
      String expr = parts[0].trim();
      String variable = parts.length > 1 ? parts[1].trim() : _detectVariable(expr);
      
      final preprocessed = _preprocessNativeExpression(_preprocessExpression(expr));
      return _engine.differentiate(preprocessed, variable);
    } catch (e) {
      return 'Error: Invalid d/dx() syntax';
    }
  }

  String _handleFactorFunction(String expression) {
    try {
      final content = expression.substring(7, expression.length - 1).trim();
      final preprocessed = _preprocessNativeExpression(_preprocessExpression(content));
      return _engine.factor(preprocessed);
    } catch (e) {
      return 'Error: Invalid factor() syntax';
    }
  }

  String _handleExpandFunction(String expression) {
    try {
      final content = expression.substring(7, expression.length - 1).trim();
      final preprocessed = _preprocessNativeExpression(_preprocessExpression(content));
      return _engine.expand(preprocessed);
    } catch (e) {
      return 'Error: Invalid expand() syntax';
    }
  }

  String _handleSimplifyFunction(String expression) {
    try {
      final content = expression.substring(9, expression.length - 1).trim();
      final preprocessed = _preprocessNativeExpression(_preprocessExpression(content));
      return _engine.expand(preprocessed); // SymEngine uses expand for simplification
    } catch (e) {
      return 'Error: Invalid simplify() syntax';
    }
  }

  String _handleGcdFunction(String expression) {
    try {
      final content = expression.substring(4, expression.length - 1).trim();
      final parts = content.split(',');
      if (parts.length != 2) {
        return 'Error: gcd() requires exactly 2 arguments';
      }
      
      final a = _preprocessNativeExpression(_preprocessExpression(parts[0].trim()));
      final b = _preprocessNativeExpression(_preprocessExpression(parts[1].trim()));
      return _engine.gcd(a, b);
    } catch (e) {
      return 'Error: Invalid gcd() syntax';
    }
  }

  /// Converts LaTeX back to readable format for history display
  String _latexToReadable(String latex) {
    String readable = latex;
    
    // Convert LaTeX operators back to readable symbols
    readable = readable.replaceAll(r'\cdot ', '*');
    readable = readable.replaceAll(r'\cdot', '*');
    readable = readable.replaceAll(r'\times ', '*');
    readable = readable.replaceAll(r'\times', '*');
    readable = readable.replaceAll(r'\div ', '/');
    readable = readable.replaceAll(r'\div', '/');
    
    // Convert fractions back to parentheses
    readable = readable.replaceAllMapped(RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'), (m) {
      return '(${m.group(1)})/(${m.group(2)})';
    });
    
    // Remove LaTeX function formatting
    readable = readable.replaceAll(r'\sin', 'sin');
    readable = readable.replaceAll(r'\cos', 'cos');
    readable = readable.replaceAll(r'\tan', 'tan');
    readable = readable.replaceAll(r'\ln', 'ln');
    readable = readable.replaceAll(r'\log', 'log');
    
    return readable;
  }

  String _handleLcmFunction(String expression) {
    try {
      final content = expression.substring(4, expression.length - 1).trim();
      final parts = content.split(',');
      if (parts.length != 2) {
        return 'Error: lcm() requires exactly 2 arguments';
      }
      
      final a = _preprocessNativeExpression(_preprocessExpression(parts[0].trim()));
      final b = _preprocessNativeExpression(_preprocessExpression(parts[1].trim()));
      return _engine.lcm(a, b);
    } catch (e) {
      return 'Error: Invalid lcm() syntax';
    }
  }

  String _detectVariable(String equation) {
    print('SOLVE: Auto-detecting variable in: "$equation"');
    
    final knownTokens = {
      'e', 'pi', 'sin', 'cos', 'tan', 'ln', 'log', 'sqrt', 'abs', 
      'exp', 'deg', 'rad', 'gamma', 'factorial'
    };
    
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
    
    final commonVariables = ['x', 'y', 'z', 't', 'n', 'a', 'b', 'c'];
    for (final common in commonVariables) {
      if (foundVariables.contains(common)) {
        print('SOLVE: Selected common variable: "$common"');
        return common;
      }
    }
    
    if (foundVariables.isNotEmpty) {
      final firstVar = foundVariables.first;
      print('SOLVE: Selected first variable: "$firstVar"');
      return firstVar;
    }
    
    print('SOLVE: No variables detected, defaulting to "x"');
    return 'x';
  }

  String _preprocessNativeExpression(String expression) {
    String p = expression;
    
    // Convert German decimal comma to period
    p = p.replaceAll(',', '.');

    // Handle implicit multiplication for numbers and parentheses
    p = p.replaceAllMapped(RegExp(r'(\d|\))(\()'), (m) => '${m[1]}*${m[2]}');
    
    // Handle implicit multiplication for variables
    p = p.replaceAllMapped(RegExp(r'(\b[a-zA-Z]\b)(\()'), (m) => '${m[1]}*${m[2]}');
    p = p.replaceAllMapped(RegExp(r'(\))(\d|\b[a-zA-Z]\b)'), (m) => '${m[1]}*${m[2]}');
    
    // Handle factorial notation: n! -> factorial(n)
    p = p.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n <= 20) {
        // Calculate small factorials directly
        int f = 1;
        for (int i = 1; i <= n; i++) { f *= i; }
        return f.toString();
      } else {
        // Use gamma function for large factorials: n! = gamma(n+1)
        return 'gamma(${n + 1})';
      }
    });
    
    // Handle variable factorial: var! -> factorial(var)
    p = p.replaceAllMapped(RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*)!'), (m) {
      return 'gamma(${m.group(1)} + 1)';
    });
    
    // Handle modulo operations: a mod b -> a % b
    p = p.replaceAllMapped(RegExp(r'(\S+)\s+mod\s+(\S+)'), (m) {
      return '(${m.group(1)}) % (${m.group(2)})';
    });
    
    // Handle special function calls that need preprocessing
    p = _preprocessSpecialFunctions(p);
    
    return p;
  }

  String _preprocessSpecialFunctions(String expression) {
    String result = expression;
    
    // Handle fibonacci function calls
    result = result.replaceAllMapped(RegExp(r'fib\((\d+)\)'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n <= 0) return '0';
      if (n == 1 || n == 2) return '1';
      
      // For small numbers, calculate directly
      if (n <= 40) {
        int a = 0, b = 1;
        for (int i = 2; i <= n; i++) {
          int temp = a + b;
          a = b;
          b = temp;
        }
        return b.toString();
      } else {
        // Use SymEngine's fibonacci function for larger numbers
        return _engine.fibonacci(n);
      }
    });
    
    // Handle prime checking
    result = result.replaceAllMapped(RegExp(r'isprime\((\d+)\)'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n < 2) return 'false';
      if (n == 2) return 'true';
      if (n % 2 == 0) return 'false';
      
      // Simple primality test for small numbers
      for (int i = 3; i * i <= n; i += 2) {
        if (n % i == 0) return 'false';
      }
      return 'true';
    });
    
    return result;
  }

  void _showSolveFunctionPicker() {
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
                leading: const Icon(Icons.keyboard_return),
                title: const Text('Continue Typing'),
                onTap: () => Navigator.of(context).pop(),
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
                        final textToInsert = 'Y${e.key+1}=0, x';
                        _latexController.insert(textToInsert);
                      },
                    )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
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
            _latexController.insert('Y${index+1}()', cursorOffsetFromEnd: -1);
          },
        );
      }).toList();

    _showPicker(title: 'Select function or continue typing:', options: options);
  }

  void _showPicker({required String title, required List<Widget> options}) {
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
                leading: const Icon(Icons.keyboard_return),
                title: const Text('Continue Typing'),
                subtitle: const Text('Dismiss this panel'),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Divider(),
              Flexible(child: ListView(shrinkWrap: true, children: options)),
            ],
          ),
        );
      },
    );
  }

  String _preprocessExpression(String expression) {
    String processed = expression;

    final funcCallRegex = RegExp(r'Y(\d+)\((.*?)\)');
    processed = processed.replaceAllMapped(funcCallRegex, (match) {
      try {
        final funcIndex = int.parse(match.group(1)!) - 1;
        final argValue = match.group(2)!;

        if (funcIndex >= 0 && funcIndex < _appState.graphFunctions.length) {
          String funcBody = _appState.graphFunctions[funcIndex];
          if (funcBody.isNotEmpty) {
            final variable = _detectVariable(funcBody);
            String substitutedBody = funcBody.replaceAll(variable, '($argValue)');
            return '($substitutedBody)';
          }
        }
      } catch (e) {
        return match.group(0)!;
      }
      return match.group(0)!;
    });

    final simpleFuncRegex = RegExp(r'Y(\d+)');
    processed = processed.replaceAllMapped(simpleFuncRegex, (match) {
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
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          // Create KeyDownEvent without timeStamp
          final keyEvent = KeyDownEvent(
            physicalKey: event.physicalKey,
            logicalKey: event.logicalKey,
            character: event.character,
            timeStamp: Duration.zero, // Use Duration.zero instead of event.timeStamp
            synthesized: false,
          );
          handleKeyboardInput(keyEvent);
        }
      },
      child: SafeArea(
        child: Column(
          children: [
            // History display
            Expanded(
              flex: 3, 
              child: ListenableBuilder(
                listenable: _appState, 
                builder: (context, child) {
                  return ListView.builder(
                    itemCount: _appState.history.length, 
                    reverse: true,
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
                }
              )
            ),
            
            const Divider(height: 1),
            
            // LaTeX input field with stable rendering
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 60, // Ensure minimum height for math rendering
                        ),
                        child: SingleChildScrollView(
                          reverse: true,
                          scrollDirection: Axis.horizontal,
                          child: LatexInputField(controller: _latexController),
                        ),
                      ),
                    ),
                  ),
                  if (_resultPreview.isNotEmpty)
                    Container(
                      height: 28,
                      alignment: Alignment.centerRight,
                      child: Text("= $_resultPreview", style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                    ),
                ],
              ),
            ),
            
            // Keypad
            Expanded(
              flex: 5, 
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Num'), 
                      Tab(text: 'Trig'), 
                      Tab(text: 'CAS'), 
                      Tab(text: 'Adv'),
                      Tab(text: 'Var')
                    ]
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController, 
                      children: [
                        // Basic numbers and operations
                        KeypadGrid(buttons: const [
                          'C','⌫','%','/','7','8','9','*','4','5','6','-','1','2','3','+','0','.','^','EXE'
                        ], onButtonPressed: _onButtonPressed),
                        
                        // Trigonometric and basic functions
                        KeypadGrid(buttons: const [
                          'sin','cos','tan','x','asin','acos','atan','(','sinh','cosh','tanh',')','ln','log','sqrt','EXE'
                        ], onButtonPressed: _onButtonPressed),
                        
                        // Computer Algebra System functions
                        KeypadGrid(buttons: const [
                          'solve','factor','expand','d/dx','simplify','f(x)','∫','◀','gcd','lcm','=','▶',',','π','e','γ'
                        ], onButtonPressed: _onButtonPressed),
                        
                        // Advanced mathematical functions
                        KeypadGrid(buttons: const [
                          'abs','gamma','!','∞','matrix','det','inv','◀','asinh','acosh','atanh','▶','fib','prime','mod','EXE'
                        ], onButtonPressed: _onButtonPressed),
                        
                        // Memory operations - placeholder
                        KeypadGrid(buttons: const [
                          'STO','M1','M2','M3','DEL','M4','M5','M6','◀','M7','M8','M9','▶','Ans','','EXE'
                        ], onButtonPressed: _onButtonPressed),
                      ]
                    )
                  ),
                ]
              )
            ),
          ],
        ),
      ),
    );
  } //build

} // class

class IntegralDialog extends StatefulWidget {
  @override
  State<IntegralDialog> createState() => _IntegralDialogState();
}

class _IntegralDialogState extends State<IntegralDialog> {
  final _functionController = TextEditingController();
  final _variableController = TextEditingController(text: 'x');
  final _lowerController = TextEditingController();
  final _upperController = TextEditingController();
  bool _isDefinite = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Integral'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _functionController,
            decoration: const InputDecoration(labelText: 'Function f(x)'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _variableController,
            decoration: const InputDecoration(labelText: 'Variable'),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Definite Integral'),
            value: _isDefinite,
            onChanged: (value) => setState(() => _isDefinite = value!),
          ),
          if (_isDefinite) ...[
            TextField(
              controller: _lowerController,
              decoration: const InputDecoration(labelText: 'Lower Bound'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _upperController,
              decoration: const InputDecoration(labelText: 'Upper Bound'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final func = _functionController.text;
            final variable = _variableController.text;
            
            String result;
            if (_isDefinite && _lowerController.text.isNotEmpty && _upperController.text.isNotEmpty) {
              result = r'\int_{' + _lowerController.text + r'}^{' + _upperController.text + r'} ' + func + r' d' + variable;
            } else {
              result = r'\int ' + func + r' d' + variable;
            }
            
            Navigator.of(context).pop(result);
          },
          child: const Text('Insert'),
        ),
      ],
    );
  }
}

class NthRootDialog extends StatefulWidget {
  @override
  State<NthRootDialog> createState() => _NthRootDialogState();
}

class _NthRootDialogState extends State<NthRootDialog> {
  final _expressionController = TextEditingController();
  final _rootController = TextEditingController(text: '3');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nth Root'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _expressionController,
            decoration: const InputDecoration(labelText: 'Expression'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rootController,
            decoration: const InputDecoration(labelText: 'Root (n)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final expr = _expressionController.text;
            final root = _rootController.text;
            final result = r'\sqrt[' + root + r']{' + expr + r'}';
            Navigator.of(context).pop(result);
          },
          child: const Text('Insert'),
        ),
      ],
    );
  }
}

class LimitDialog extends StatefulWidget {
  @override
  State<LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<LimitDialog> {
  final _functionController = TextEditingController();
  final _variableController = TextEditingController(text: 'x');
  final _approachesController = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Limit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _functionController,
            decoration: const InputDecoration(labelText: 'Function f(x)'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _variableController,
            decoration: const InputDecoration(labelText: 'Variable'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _approachesController,
            decoration: const InputDecoration(labelText: 'Approaches'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final func = _functionController.text;
            final variable = _variableController.text;
            final approaches = _approachesController.text;
            final result = r'\lim_{' + variable + r' \to ' + approaches + r'} ' + func;
            Navigator.of(context).pop(result);
          },
          child: const Text('Insert'),
        ),
      ],
    );
  }
}