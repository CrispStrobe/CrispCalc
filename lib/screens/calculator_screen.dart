// lib/screens/calculator_screen.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

// Engine imports
import '../engine/app_state.dart';
import '../engine/calculator_engine.dart';

// Widget imports
import '../widgets/calculator_keypad.dart';
import '../widgets/latex_input_field.dart';
import '../widgets/memory_dialogs.dart';
import '../widgets/function_picker_dialogs.dart';
import '../widgets/steps_dialog.dart';
import '../engine/step_engine.dart';

// Utils imports
import '../utils/keyboard_input_handler.dart';
import '../utils/latex_conversion_utils.dart';
import '../utils/error_formatter.dart';
import '../utils/expression_preprocessing_utils.dart';
import '../utils/math_display_utils.dart';

// Other imports
import '../controllers/latex_controller.dart';
import '../localization/app_localizations.dart';
import '../screens/matrix_editor_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  final AppState _appState = AppState();
  final CalculatorEngine _engine = CalculatorEngine();
  final Map<String, String> _memory = {};

  late TabController _tabController;
  final LatexController _latexController = LatexController();
  final FocusNode _calculatorFocusNode = FocusNode(); // Dedicated focus node

  String _resultPreview = '';
  bool _justCalculated = false;
  bool _showLatexHistory = false; // History display toggle

  bool _historySearchOpen = false;
  final TextEditingController _historySearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _latexController.addListener(_onInputChanged);
    _historySearchController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatorFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _latexController.removeListener(_onInputChanged);
    _latexController.dispose();
    _calculatorFocusNode.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  /// Allows parent widgets to request focus for the input field.
  void requestFocus() {
    _calculatorFocusNode.requestFocus();
  }

  /// Converts expression to LaTeX for history display.
  String _toLatex(String text) {
    return MathDisplayUtils.toHistoryDisplayLatex(text);
  }

  Widget _buildExpressionDisplay(String expression) {
    if (_showLatexHistory && expression.isNotEmpty) {
      // Try to render as LaTeX
      try {
        return Math.tex(
          _toLatex(expression),
          textStyle: TextStyle(fontSize: 20, color: Colors.grey[500]),
          onErrorFallback: (err) => Text(
            expression,
            style: TextStyle(fontSize: 20, color: Colors.grey[500]),
            textAlign: TextAlign.right,
          ),
        );
      } catch (e) {
        // Fallback to plain text if LaTeX rendering fails
        return Text(
          expression,
          style: TextStyle(fontSize: 20, color: Colors.grey[500]),
          textAlign: TextAlign.right,
        );
      }
    } else {
      // Plain text display
      return Text(
        expression,
        style: TextStyle(fontSize: 20, color: Colors.grey[500]),
        textAlign: TextAlign.right,
      );
    }
  }

  /// Called whenever the input text changes.
  void _onInputChanged() {
    if (_justCalculated && _latexController.text.isNotEmpty) {
      final currentInput = _latexController.text.trim();

      // Correctly handle LaTeX operators like \cdot
      // Define which LaTeX commands should be treated as simple operators for Auto-Ans
      final isLatexOperator = currentInput.startsWith(r'\cdot') ||
          currentInput.startsWith(r'\times') ||
          currentInput.startsWith(r'\div');

      // Trigger Auto-Ans if the input is a non-LaTeX operator, OR if it's one of the approved LaTeX operators.
      // This prevents triggering on templates like \frac{}{}
      if ((!currentInput.startsWith('\\') && _isOperator(currentInput)) ||
          isLatexOperator) {
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

  void _updateLivePreview() {
    String currentText = _latexController.text.trim();

    if (currentText.isEmpty ||
        currentText.toLowerCase().startsWith('solve') ||
        currentText.contains('=') ||
        currentText.length < 2 ||
        RegExp(r'^[a-zA-Z]+$').hasMatch(currentText)) {
      setState(() {
        _resultPreview = '';
      });
      return;
    }

    if (!RegExp(r'[\d\+\-\*/\^\(\)\.\,\\]').hasMatch(currentText)) {
      setState(() {
        _resultPreview = '';
      });
      return;
    }

    try {
      final convertedExpression = LatexConversionUtils.fromLatex(currentText);
      final substituted = ExpressionPreprocessingUtils.substituteVariables(
          convertedExpression, _appState);
      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  substituted, _appState));
      final rawResult = _engine.evaluate(preprocessed);

      final normalizedResult =
          ExpressionPreprocessingUtils.normalizeComplexResult(rawResult);

      if (normalizedResult != "Error" &&
          normalizedResult != currentText &&
          normalizedResult != preprocessed) {
        final numericResult = double.tryParse(normalizedResult);
        if (numericResult != null) {
          setState(() {
            _resultPreview = normalizedResult;
          });
        } else if (!normalizedResult.contains('Error')) {
          setState(() {
            _resultPreview = normalizedResult;
          });
        } else {
          setState(() {
            _resultPreview = '';
          });
        }
      } else {
        setState(() {
          _resultPreview = '';
        });
      }
    } catch (e) {
      setState(() {
        _resultPreview = '';
      });
    }
  }

  bool _handleKeyboardInput(KeyEvent event) {
    KeyboardInputHandler.debugKeyboardInput(event);

    // Handle Enter key specifically to prevent tab switching
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) {
        _onButtonPressed("EXE");
        return true; // Consume the event to prevent tab switching
      }
    }

    return KeyboardInputHandler.handleKeyboardInput(
      event,
      (text) => _latexController.insert(text),
      () => _latexController.backspace(),
      () => _latexController.clear(),
      () => _onButtonPressed("EXE"),
      (amount) => _latexController.moveCursor(amount),
    );
  }

  void _handleMemoryAction(String action) {
    if (action.startsWith('DELETE_')) {
      final memName = action.substring(7); // Remove 'DELETE_' prefix
      final memIndex = int.parse(memName.substring(1)) - 1; // M1 -> 0
      setState(() {
        _memory.remove('M$memIndex');
      });
    } else if (action == 'CLEAR_ALL') {
      setState(() {
        _memory.clear();
      });
    } else {
      // Regular button press, delegate to existing handler
      _onButtonPressed(action);
    }
  }

  void _onButtonPressed(String value) async {
    // Ensure focus stays on calculator
    _calculatorFocusNode.requestFocus();

    if (_justCalculated && _isOperator(value) && _appState.history.isNotEmpty) {
      _latexController.insert('Ans');
    }

    switch (value) {
      case 'C':
        _latexController.clear();
        setState(() {
          _justCalculated = false;
        });
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
        MemoryDialogs.showStoreDialog(context, _appState, _memory);
        break;

      // Memory buttons M1-M9:
      case 'M1':
      case 'M2':
      case 'M3':
      case 'M4':
      case 'M5':
      case 'M6':
      case 'M7':
      case 'M8':
      case 'M9':
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
        MemoryDialogs.showDeleteMemoryDialog(
            context, _memory, () => setState(() {}));
        break;

      // --- LaTeX Template Insertions ---
      case '/': // This is the BUTTON press, should create fractions
        _latexController.insert(r'\frac{}{}', cursorOffsetFromEnd: -3);
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
        FunctionPickerDialogs.showSolveFunctionPicker(
            context, _appState, (text) => _latexController.insert(text));
        break;

      case 'solve⌄':
        await _showSolveSteps();
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

      case 'd/dx⌄':
        await _showDifferentiationSteps();
        break;

      case 'gcd':
        _latexController.insert('gcd(,)', cursorOffsetFromEnd: -2);
        break;

      case 'lcm':
        _latexController.insert('lcm(,)', cursorOffsetFromEnd: -2);
        break;

      case '∫':
        final result = await FunctionPickerDialogs.showIntegralDialog(context);
        if (result != null) {
          _latexController.insert(result);
          // Force refresh after dialog insertion
          setState(() {});
        }
        break;

      case '∫⌄':
        await _showIntegrationSteps();
        break;

      case 'ⁿ√x':
        final result = await FunctionPickerDialogs.showNthRootDialog(context);
        if (result != null) {
          _latexController.insert(result);
          // Force refresh after dialog insertion
          setState(() {});
        }
        break;

      case 'lim':
        final result = await FunctionPickerDialogs.showLimitDialog(context);
        if (result != null) {
          _latexController.insert(result);
          // Force refresh after dialog insertion
          setState(() {});
        }
        break;

      case 'matrix':
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (context) => const MatrixEditorScreen()),
        );
        if (result != null) _latexController.insert(result);
        break;

      case 'f(x)':
        FunctionPickerDialogs.showFunctionPicker(
            context, _appState, (text) => _latexController.insert(text));
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

      case 'rref':
        _latexController.insert('rref()', cursorOffsetFromEnd: -1);
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

      // === Newly restored / added ops ===

      case 'exp':
        _latexController.insert('exp()', cursorOffsetFromEnd: -1);
        break;

      case 'subst':
        final substResult = await FunctionPickerDialogs.showSubstituteDialog(
            context, _appState);
        if (substResult != null) {
          _latexController.insert(substResult);
          setState(() {});
        }
        break;

      case 'dot':
        _latexController.insert('dot([], [])', cursorOffsetFromEnd: -5);
        break;

      case 'cross':
        _latexController.insert('cross([], [])', cursorOffsetFromEnd: -5);
        break;

      case 'norm':
        _latexController.insert('norm([])', cursorOffsetFromEnd: -2);
        break;

      case 'unit':
        _latexController.insert('unit([])', cursorOffsetFromEnd: -2);
        break;

      case 'i':
        _latexController.insert('I');
        break;

      default:
        _latexController.insert(value);
        break;
    }
  }

  // Helper method to check if a value is an operator
  bool _isOperator(String value) {
    return ['+', '-', '*', '/', '^', '%', '=', r'\cdot', r'\times', r'\div']
        .contains(value);
  }

  Future<void> _calculate(String expression) async {
    if (kDebugMode) debugPrint('CALC: "$expression"');
    try {
      final trimmed = expression.trim();

      final assignmentMatch =
          RegExp(r'^([a-zA-Z][a-zA-Z0-9]*)\s*=\s*(.+)$').firstMatch(trimmed);
      if (assignmentMatch != null) {
        await _handleAssignment(expression, assignmentMatch);
        return;
      }

      final functionMatch =
          RegExp(r'^([FY])(\d+)\s*=\s*(.+)$').firstMatch(trimmed);
      if (functionMatch != null) {
        await _handleFunctionDefinition(expression, functionMatch);
        return;
      }

      final convertedExpression = LatexConversionUtils.fromLatex(expression);
      final converted = convertedExpression.trim();

      String result;
      if (_isFunctionCall(converted, 'solve')) {
        result = _handleSolveFunction(converted);
      } else if (_isFunctionCall(converted, 'd/dx')) {
        result = _handleDifferentiateFunction(converted);
      } else if (_isFunctionCall(converted, 'factor')) {
        result = _handleFactorFunction(converted);
      } else if (_isFunctionCall(converted, 'expand')) {
        result = _handleExpandFunction(converted);
      } else if (_isFunctionCall(converted, 'simplify')) {
        result = _handleSimplifyFunction(converted);
      } else if (_isFunctionCall(converted, 'gcd')) {
        result = _handleGcdFunction(converted);
      } else if (_isFunctionCall(converted, 'lcm')) {
        result = _handleLcmFunction(converted);
      } else if (_isFunctionCall(converted, 'integrate')) {
        result = _handleIntegrateFunction(converted);
      } else if (_isFunctionCall(converted, 'limit')) {
        result = _handleLimitFunction(converted);
      } else if (_looksLikeBareEquation(converted)) {
        // `2x + 3 = 0`, `x^2 - 4 = 0`, etc. — anything with a `=` that
        // didn't match the assignment or function-def patterns above. Wrap
        // it in solve(...) automatically so the user doesn't have to.
        result = _solveBareEquation(converted);
      } else {
        final substituted = ExpressionPreprocessingUtils.substituteVariables(
            convertedExpression, _appState);
        final preprocessed =
            ExpressionPreprocessingUtils.preprocessNativeExpression(
          ExpressionPreprocessingUtils.preprocessExpression(
              substituted, _appState),
        );
        final rawResult = _engine.evaluate(preprocessed);
        result = ExpressionPreprocessingUtils.normalizeComplexResult(rawResult);
      }

      setState(() {
        _appState.addHistoryEntry(
            LatexConversionUtils.latexToReadable(expression), result);
        _resultPreview = '';
        _justCalculated = true;
        _latexController.clear();
      });

      _calculatorFocusNode.requestFocus();
    } catch (e) {
      if (kDebugMode) debugPrint('CALC: error: $e');
      setState(() =>
          _appState.addHistoryEntry(expression, 'Error: ${e.toString()}'));
    }
  }

  bool _isFunctionCall(String s, String name) {
    return s.startsWith('$name(') && s.endsWith(')');
  }

  /// True for inputs like `2x+3=0` or `x^2-4=0` — expressions that contain
  /// `=` but didn't already match the variable-assignment or function-def
  /// patterns. We use this to auto-route them through the solver.
  bool _looksLikeBareEquation(String converted) {
    if (!converted.contains('=')) return false;
    // Already handled — assignment / function-def regexes caught it before
    // we got here, so anything still containing `=` is a real equation.
    return RegExp(r'[a-zA-Z]').hasMatch(converted);
  }

  /// Single-letter identifiers that are constants, not variables.
  static const _kReservedLetters = {'e', 'E', 'I'};

  /// True if `expression` contains at least one letter that isn't part of a
  /// reserved constant. Used to distinguish `a = 5` (value) from
  /// `y = 2x - 5` (function of x).
  bool _hasFreeVariable(String expression) {
    final regex = RegExp(r'(?<![a-zA-Z])([a-zA-Z])(?![a-zA-Z])');
    for (final m in regex.allMatches(expression)) {
      if (!_kReservedLetters.contains(m.group(1))) return true;
    }
    return false;
  }

  /// Route `name = <expr-with-free-var>` to the next empty Y-slot so the
  /// function can be plotted / analyzed. We don't try to honor the user's
  /// chosen `name` (e.g. `y` or `f`) for naming — graphing is keyed off
  /// Y1..Y10 — but we do mention it in the history entry so the user can
  /// see what happened.
  Future<void> _handleFunctionAssignment(
      String originalExpression, String name, String body) async {
    final slot = _appState.graphFunctions.indexWhere((f) => f.isEmpty);
    if (slot < 0) {
      setState(() {
        _appState.addHistoryEntry(
            originalExpression, 'Error: all Y slots are full');
        _latexController.clear();
      });
      return;
    }
    _appState.updateFunction(slot, body);
    setState(() {
      _appState.addHistoryEntry(
        originalExpression,
        'Stored Y${slot + 1} ($name): $body',
      );
      _justCalculated = true;
      _latexController.clear();
    });
  }

  /// Detect a variable, build `solve(LHS - (RHS), var)`, dispatch.
  String _solveBareEquation(String converted) {
    final parts = converted.split('=');
    if (parts.length != 2) {
      return 'Error: equations must have exactly one "="';
    }
    final lhs = parts[0].trim();
    final rhs = parts[1].trim();
    final body = (rhs.isEmpty || rhs == '0') ? lhs : '$lhs - ($rhs)';
    final variable = ExpressionPreprocessingUtils.detectVariable(body);

    final preprocessed =
        ExpressionPreprocessingUtils.preprocessNativeExpression(
      ExpressionPreprocessingUtils.preprocessExpression(body, _appState),
    );
    return _engine.solve(preprocessed, variable);
  }

  Future<void> _handleAssignment(
      String originalExpression, RegExpMatch match) async {
    final name = match.group(1)!;
    final valueExpression = match.group(2)!;
    try {
      final convertedValue = LatexConversionUtils.fromLatex(valueExpression);
      final substitutedValue = ExpressionPreprocessingUtils.substituteVariables(
          convertedValue, _appState);

      // Heuristic: if the RHS still has a free variable after substitution,
      // the user meant "define a function", not "store a value". Route it
      // to the next empty Y-slot so it can be plotted and analyzed.
      if (_hasFreeVariable(substitutedValue)) {
        await _handleFunctionAssignment(
            originalExpression, name, convertedValue);
        return;
      }

      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  substitutedValue, _appState));
      final evaluatedValue = _engine.evaluate(preprocessed);
      final normalizedValue =
          ExpressionPreprocessingUtils.normalizeComplexResult(evaluatedValue);

      if (normalizedValue != "Error" && !normalizedValue.contains("Error")) {
        _appState.setVariable(name, normalizedValue);
        setState(() {
          _appState.addHistoryEntry(
              originalExpression, "Stored $name = $normalizedValue");
          _justCalculated = true;
          _latexController.clear();
        });
      } else {
        setState(() {
          _appState.addHistoryEntry(
              originalExpression, "Error: Could not evaluate $valueExpression");
          _latexController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _appState.addHistoryEntry(
            originalExpression, "Error: Invalid assignment");
        _latexController.clear();
      });
    }
  }

  Future<void> _handleFunctionDefinition(
      String originalExpression, RegExpMatch match) async {
    final functionType = match.group(1)!;
    final functionIndex = int.parse(match.group(2)!) - 1;
    final functionExpression = match.group(3)!;
    try {
      final convertedExpression =
          LatexConversionUtils.fromLatex(functionExpression);

      if (functionType == 'Y') {
        if (functionIndex >= 0 &&
            functionIndex < _appState.graphFunctions.length) {
          _appState.updateFunction(functionIndex, convertedExpression);
          setState(() {
            _appState.addHistoryEntry(
                originalExpression, "Stored Y${functionIndex + 1}");
            _justCalculated = true;
            _latexController.clear();
          });
        } else {
          setState(() => _appState.addHistoryEntry(
              originalExpression, "Error: Invalid function index"));
        }
      } else if (functionType == 'F') {
        // F-function syntax (`F1 = ...`) is the calculator's old name for the
        // Y-function slots — same storage, different label. Treat F<N> as Y<N>
        // so muscle memory still works.
        if (functionIndex >= 0 &&
            functionIndex < _appState.graphFunctions.length) {
          _appState.updateFunction(functionIndex, convertedExpression);
          setState(() {
            _appState.addHistoryEntry(
                originalExpression, 'Stored Y${functionIndex + 1} (F → Y)');
            _justCalculated = true;
            _latexController.clear();
          });
        } else {
          setState(() => _appState.addHistoryEntry(
              originalExpression, 'Error: Invalid function index'));
        }
      }
    } catch (e) {
      setState(() {
        _appState.addHistoryEntry(
            originalExpression, "Error: Invalid function definition");
        _latexController.clear();
      });
    }
  }

  String _handleSolveFunction(String expression) {
    try {
      final solveContent =
          expression.substring(6, expression.length - 1).trim();
      String equation, variable;

      final parts = solveContent.split(',');
      if (parts.length == 1) {
        equation = parts[0].trim();
        variable = ExpressionPreprocessingUtils.detectVariable(equation);
      } else if (parts.length == 2) {
        equation = parts[0].trim();
        variable = parts[1].trim();
      } else {
        return 'Error: solve() format: solve(equation) or solve(equation, variable)';
      }

      if (equation.contains('=')) {
        final eqParts = equation.split('=');
        if (eqParts.length == 2) {
          final leftSide = eqParts[0].trim();
          final rightSide = eqParts[1].trim();
          equation = rightSide == '0' || rightSide.isEmpty
              ? leftSide
              : '$leftSide - ($rightSide)';
        }
      }

      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  equation, _appState));

      return _engine.solve(preprocessed, variable);
    } catch (e) {
      return 'Error: Invalid solve() syntax';
    }
  }

  String _handleDifferentiateFunction(String expression) {
    try {
      final content = expression.substring(5, expression.length - 1).trim();
      final parts = content.split(',');

      String expr = parts[0].trim();
      String variable = parts.length > 1
          ? parts[1].trim()
          : ExpressionPreprocessingUtils.detectVariable(expr);

      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  expr, _appState));
      return _engine.differentiate(preprocessed, variable);
    } catch (e) {
      return 'Error: Invalid d/dx() syntax';
    }
  }

  String _handleFactorFunction(String expression) {
    try {
      final content = expression.substring(7, expression.length - 1).trim();
      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  content, _appState));
      return _engine.factor(preprocessed);
    } catch (e) {
      return 'Error: Invalid factor() syntax';
    }
  }

  String _handleExpandFunction(String expression) {
    try {
      final content = expression.substring(7, expression.length - 1).trim();
      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  content, _appState));
      return _engine.expand(preprocessed);
    } catch (e) {
      return 'Error: Invalid expand() syntax';
    }
  }

  String _handleSimplifyFunction(String expression) {
    try {
      final content = expression.substring(9, expression.length - 1).trim();
      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  content, _appState));
      return _engine.simplify(preprocessed);
    } catch (e) {
      return 'Error: Invalid simplify() syntax';
    }
  }

  String _handleGcdFunction(String expression) {
    try {
      final content = expression.substring(4, expression.length - 1).trim();
      final parts = content.split(',');
      if (parts.length != 2) return 'Error: gcd() requires exactly 2 arguments';

      final a = ExpressionPreprocessingUtils.preprocessNativeExpression(
          ExpressionPreprocessingUtils.preprocessExpression(
              parts[0].trim(), _appState));
      final b = ExpressionPreprocessingUtils.preprocessNativeExpression(
          ExpressionPreprocessingUtils.preprocessExpression(
              parts[1].trim(), _appState));
      return _engine.gcd(a, b);
    } catch (e) {
      return 'Error: Invalid gcd() syntax';
    }
  }

  String _handleLcmFunction(String expression) {
    try {
      final content = expression.substring(4, expression.length - 1).trim();
      final parts = content.split(',');
      if (parts.length != 2) return 'Error: lcm() requires exactly 2 arguments';

      final a = ExpressionPreprocessingUtils.preprocessNativeExpression(
          ExpressionPreprocessingUtils.preprocessExpression(
              parts[0].trim(), _appState));
      final b = ExpressionPreprocessingUtils.preprocessNativeExpression(
          ExpressionPreprocessingUtils.preprocessExpression(
              parts[1].trim(), _appState));
      return _engine.lcm(a, b);
    } catch (e) {
      return 'Error: Invalid lcm() syntax';
    }
  }

  /// integrate(expr, var) or integrate(expr, (var, lower, upper))
  String _handleIntegrateFunction(String expression) {
    try {
      final content = expression.substring(10, expression.length - 1).trim();
      // Split into expression and the rest at the first comma at depth 0.
      final firstComma = _findTopLevelComma(content);
      if (firstComma < 0) return 'Error: integrate() needs at least a variable';

      final exprPart = content.substring(0, firstComma).trim();
      final rest = content.substring(firstComma + 1).trim();

      final preprocessedExpr =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
        ExpressionPreprocessingUtils.preprocessExpression(exprPart, _appState),
      );

      // (var, a, b) form — definite integral
      if (rest.startsWith('(') && rest.endsWith(')')) {
        final inner = rest.substring(1, rest.length - 1);
        final parts = inner.split(',').map((s) => s.trim()).toList();
        if (parts.length == 3) {
          return _engine.integrate(
              preprocessedExpr, parts[0], parts[1], parts[2]);
        }
        return 'Error: integrate(expr, (var, lower, upper)) expected';
      }

      // Just a variable — indefinite integral
      return _engine.integrate(preprocessedExpr, rest);
    } catch (e) {
      return 'Error: Invalid integrate() syntax';
    }
  }

  /// limit(expr, var, point)
  String _handleLimitFunction(String expression) {
    try {
      final content = expression.substring(6, expression.length - 1).trim();
      final parts = content.split(',').map((s) => s.trim()).toList();
      if (parts.length != 3) {
        return 'Error: limit(expr, var, point) expected';
      }
      final preprocessedExpr =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
        ExpressionPreprocessingUtils.preprocessExpression(parts[0], _appState),
      );
      return _engine.limit(preprocessedExpr, parts[1], parts[2]);
    } catch (e) {
      return 'Error: Invalid limit() syntax';
    }
  }

  /// Prompt for an expression + variable, then open the step-by-step
  /// derivative trace dialog. The current LaTeX field's text is used as
  /// the default expression so a user can type a function first and then
  /// tap this button.
  Future<void> _showDifferentiationSteps() async {
    final t = AppLocalizations.of(context);
    final expr = _latexController.text.trim();
    final defaultExpr = expr.isEmpty
        ? 'x*sin(x)'
        : LatexConversionUtils.fromLatex(expr);
    final defaultVar =
        ExpressionPreprocessingUtils.detectVariable(defaultExpr);

    final exprCtl = TextEditingController(text: defaultExpr);
    final varCtl = TextEditingController(text: defaultVar);

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.differentiationStepsTitle),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: exprCtl,
                decoration: InputDecoration(
                  labelText: t.dialogExpression,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: varCtl,
                decoration: InputDecoration(
                  labelText: t.dialogVariable,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.dialogShowSteps),
          ),
        ],
      ),
    );

    final exprText = exprCtl.text.trim();
    final varText = varCtl.text.trim();
    exprCtl.dispose();
    varCtl.dispose();

    if (go != true || exprText.isEmpty || varText.isEmpty) return;

    final preprocessed =
        ExpressionPreprocessingUtils.preprocessNativeExpression(
      ExpressionPreprocessingUtils.preprocessExpression(exprText, _appState),
    );
    final steps =
        StepEngine.differentiate(preprocessed, varText, _engine);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StepsDialog(
        title: t.differentiationStepsTitle,
        expression: preprocessed,
        variable: varText,
        steps: steps,
        subtitle: t.differentiationStepsHeader(varText),
      ),
    );
  }

  /// Counterpart to _showDifferentiationSteps: prompts for an equation
  /// (or expression to set to 0) and a variable, then runs StepEngine.solve
  /// and renders the trace.
  Future<void> _showSolveSteps() async {
    final t = AppLocalizations.of(context);
    final raw = _latexController.text.trim();
    final defaultExpr =
        raw.isEmpty ? '2x + 3 = 7' : LatexConversionUtils.fromLatex(raw);
    final defaultVar =
        ExpressionPreprocessingUtils.detectVariable(defaultExpr);

    final exprCtl = TextEditingController(text: defaultExpr);
    final varCtl = TextEditingController(text: defaultVar);

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.solveStepsTitle),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: exprCtl,
                decoration: InputDecoration(
                  labelText: t.solveStepsEquationLabel,
                  hintText: t.solveStepsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: varCtl,
                decoration: InputDecoration(
                  labelText: t.solveStepsSolveFor,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.dialogShowSteps),
          ),
        ],
      ),
    );

    final exprText = exprCtl.text.trim();
    final varText = varCtl.text.trim();
    exprCtl.dispose();
    varCtl.dispose();

    if (go != true || exprText.isEmpty || varText.isEmpty) return;

    // Run the input through the same preprocessor as a normal evaluate
    // call so `2x` becomes `2*x`, German commas become dots, etc.
    final preprocessed =
        ExpressionPreprocessingUtils.preprocessNativeExpression(
      ExpressionPreprocessingUtils.preprocessExpression(exprText, _appState),
    );
    final steps = StepEngine.solve(preprocessed, varText, _engine);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StepsDialog(
        title: t.solveStepsTitle,
        expression: preprocessed,
        variable: varText,
        steps: steps,
        subtitle: t.solveStepsHeader(varText),
        headlineLatex: preprocessed.contains('=')
            ? preprocessed.replaceAll('=', r' \,=\, ')
            : '$preprocessed = 0',
      ),
    );
  }

  /// Prompt for an integrand + variable, then open the integration
  /// step-by-step dialog. Mirrors _showDifferentiationSteps and
  /// _showSolveSteps; same dialog widget with different headline.
  Future<void> _showIntegrationSteps() async {
    final t = AppLocalizations.of(context);
    final raw = _latexController.text.trim();
    final defaultExpr =
        raw.isEmpty ? 'x^2' : LatexConversionUtils.fromLatex(raw);
    final defaultVar =
        ExpressionPreprocessingUtils.detectVariable(defaultExpr);

    final exprCtl = TextEditingController(text: defaultExpr);
    final varCtl = TextEditingController(text: defaultVar);

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.integrationStepsTitle),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: exprCtl,
                decoration: InputDecoration(
                  labelText: t.integrationStepsIntegrandLabel,
                  hintText: t.integrationStepsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: varCtl,
                decoration: InputDecoration(
                  labelText: t.integrationStepsWrt,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.dialogShowSteps),
          ),
        ],
      ),
    );

    final exprText = exprCtl.text.trim();
    final varText = varCtl.text.trim();
    exprCtl.dispose();
    varCtl.dispose();

    if (go != true || exprText.isEmpty || varText.isEmpty) return;

    final preprocessed =
        ExpressionPreprocessingUtils.preprocessNativeExpression(
      ExpressionPreprocessingUtils.preprocessExpression(exprText, _appState),
    );
    final steps = StepEngine.integrate(preprocessed, varText, _engine);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StepsDialog(
        title: t.integrationStepsTitle,
        expression: preprocessed,
        variable: varText,
        steps: steps,
        subtitle: t.integrationStepsHeader(varText),
        headlineLatex:
            r'\int ' + _toLatex(preprocessed) + r' \, d' + varText,
      ),
    );
  }

  void _confirmClearHistory() {
    final t = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.clearHistory),
        content: Text(t.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _appState.clearHistory();
              Navigator.of(context).pop();
            },
            child: Text(t.clearAll),
          ),
        ],
      ),
    );
  }

  /// Returns the index of the first top-level (depth 0) comma in `s`, or -1.
  int _findTopLevelComma(String s) {
    var depth = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(' || c == '[' || c == '{') depth++;
      if (c == ')' || c == ']' || c == '}') depth--;
      if (c == ',' && depth == 0) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _calculatorFocusNode,
      // autofocus is off on purpose: MainScreen calls requestFocus() when this
      // becomes the active pane. Two KeyboardListener(autofocus: true) instances
      // alive at once (calc + graph + editor in the wide split) crash the
      // focus tree after a few clicks.
      onKeyEvent: (KeyEvent event) {
        final handled = _handleKeyboardInput(event);
        if (handled) {
          _calculatorFocusNode.requestFocus();
        }
      },
      child: SafeArea(
        child: Column(
          children: [
            // History display section
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Toggle button for LaTeX/Plain text display (VISIBLE NOW!)
                  if (_appState.history.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            AppLocalizations.of(context).historyLabel,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.text_fields, size: 16),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.functions, size: 16),
                              ),
                            ],
                            selected: {_showLatexHistory},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() {
                                _showLatexHistory = newSelection.first;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _historySearchOpen
                                  ? Icons.search_off
                                  : Icons.search,
                              size: 20,
                            ),
                            tooltip:
                                AppLocalizations.of(context).searchHistory,
                            onPressed: () {
                              setState(() {
                                _historySearchOpen = !_historySearchOpen;
                                if (!_historySearchOpen) {
                                  _historySearchController.clear();
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_sweep, size: 20),
                            tooltip: AppLocalizations.of(context).clearHistory,
                            onPressed: _confirmClearHistory,
                          ),
                        ],
                      ),
                    ),

                  if (_historySearchOpen && _appState.history.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        controller: _historySearchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          hintText:
                              AppLocalizations.of(context).searchHistoryHint,
                          border: const OutlineInputBorder(),
                          suffixIcon: _historySearchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _historySearchController.clear();
                                  },
                                ),
                        ),
                      ),
                    ),

                  // History list
                  Expanded(
                    child: ListenableBuilder(
                        listenable: _appState,
                        builder: (context, child) {
                          if (_appState.history.isEmpty) {
                            return Center(
                              child: Text(
                                AppLocalizations.of(context).historyHere,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          final q = _historySearchController.text
                              .trim()
                              .toLowerCase();
                          final entries = q.isEmpty
                              ? _appState.history
                              : _appState.history
                                  .where((e) =>
                                      e.expression.toLowerCase().contains(q) ||
                                      e.result.toLowerCase().contains(q))
                                  .toList();

                          if (entries.isEmpty) {
                            return Center(
                              child: Text(
                                AppLocalizations.of(context).historyNoMatches,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: entries.length,
                            reverse: true,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 8),
                                child: Builder(builder: (context) {
                                  final tt = AppLocalizations.of(context);
                                  final display = EngineErrorFormatter.format(
                                      entry.result, tt);
                                  final isError =
                                      EngineErrorFormatter.isError(entry.result);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      // Expression display (with LaTeX toggle)
                                      _buildExpressionDisplay(entry.expression),
                                      const SizedBox(height: 4),
                                      // Result display — friendly plain-
                                      // language text for errors, normal
                                      // result text otherwise.
                                      Text(
                                        isError ? display : '= $display',
                                        style: TextStyle(
                                          fontSize: isError ? 16 : 28,
                                          color: isError
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .error
                                              : Colors.blue[300],
                                          fontStyle: isError
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  );
                                }),
                              );
                            },
                          );
                        }),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // LaTeX input field
            Container(
              height: 120,
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 60),
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
                      child: Text("= $_resultPreview",
                          style:
                              TextStyle(fontSize: 20, color: Colors.grey[600])),
                    ),
                ],
              ),
            ),

            // Keypad - Use the existing CalculatorKeypad widget
            Expanded(
              flex: 5,
              child: CalculatorKeypad(
                tabController: _tabController,
                onButtonPressed: _onButtonPressed,
                localizations: AppLocalizations.of(context),
                appState: _appState,
                onVariableTap: (name) => _latexController.insert(name),
                memory: _memory, // Pass memory
                onMemoryAction: _handleMemoryAction, // Pass button handler
              ),
            ),
          ],
        ),
      ),
    );
  }
}
