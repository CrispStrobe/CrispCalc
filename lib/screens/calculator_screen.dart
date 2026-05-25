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
import '../widgets/progress_overlay.dart';
import '../widgets/steps_dialog.dart';
import '../engine/step_engine.dart';
import '../engine/unit_expression.dart';

// Utils imports
import '../services/engine_service.dart';
import '../utils/exact_integer.dart';
import '../utils/keyboard_input_handler.dart';
import '../utils/latex_conversion_utils.dart';
import '../utils/error_formatter.dart';
import '../utils/expression_preprocessing_utils.dart';
import '../utils/math_display_utils.dart';

// Other imports
import '../controllers/latex_controller.dart';
import '../localization/app_localizations.dart';
import '../main.dart' show appRouteObserver;
import '../screens/curve_analysis_input_screen.dart';
import '../screens/matrix_editor_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, this.onGoToGraphing, this.onGoToAnalysis});

  /// Optional: switch the main nav to the Graphing tab. Forwarded down
  /// to the VariableViewer's function-tile context menu.
  final VoidCallback? onGoToGraphing;

  /// Optional: switch the main nav to the Analysis hub.
  final VoidCallback? onGoToAnalysis;

  @override
  State<CalculatorScreen> createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final AppState _appState = AppState();
  final CalculatorEngine _engine = CalculatorEngine();
  final Map<String, String> _memory = {};

  late TabController _tabController;
  final LatexController _latexController = LatexController();
  final FocusNode _calculatorFocusNode = FocusNode(); // Dedicated focus node

  String _resultPreview = '';
  bool _justCalculated = false;
  bool _showLatexHistory = false; // History display toggle

  /// Watchdog-installed message for the progress overlay. Populated by
  /// `_runWithProgress` after the 300 ms threshold so quick
  /// evaluations don't flash the dialog.
  String _busyMessage = '';

  bool _historySearchOpen = false;
  final TextEditingController _historySearchController =
      TextEditingController();
  // Dedicated focus node for the history search field. Without this the
  // calculator's top-level KeyboardListener (focusNode: _calculatorFocusNode)
  // wins the focus race and consumes keystrokes before the TextField can
  // see them, so typing into "Verlauf filtern" silently does nothing.
  final FocusNode _historySearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _latexController.addListener(_onInputChanged);
    _historySearchController.addListener(() => setState(() {}));
    // Worked-examples V2: pull in any pre-filled expression that
    // arrived via AppState.requestInsertExpression (the dialog signals
    // here, MainScreen routes us, and we drain the slot on the next
    // listener fire).
    _appState.addListener(_consumePendingInsert);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatorFocusNode.requestFocus();
      _consumePendingInsert();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Round 71: subscribe to the app-wide RouteObserver so we get a
    // didPopNext callback whenever a pushed route (dialog, module
    // screen, anything that puts a ModalRoute on top of us) pops
    // back. This is what restores hardware-keyboard focus to the
    // calculator without requiring the user to click a keypad
    // button or hit the "reset focus" recovery action.
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (!mounted) return;
    // The route that was on top of us just popped — re-grab focus
    // for the hardware-keyboard listener.
    _calculatorFocusNode.requestFocus();
  }

  void _consumePendingInsert() {
    final expr = _appState.consumePendingInsert();
    if (expr == null || !mounted) return;
    _latexController.clear();
    _latexController.insert(expr);
    _calculatorFocusNode.requestFocus();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _appState.removeListener(_consumePendingInsert);
    _tabController.dispose();
    _latexController.removeListener(_onInputChanged);
    _latexController.dispose();
    _calculatorFocusNode.dispose();
    _historySearchController.dispose();
    _historySearchFocusNode.dispose();
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

  /// Recover from a stuck HardwareKeyboard state. Hot reload, a brief
  /// volume disconnect (the project lives on an external SSD), or just
  /// abruptly killing the app while a key was held leaves Flutter's
  /// HardwareKeyboard with stale `_pressedKeys` entries — those then
  /// trip an `assert(...)` inside `handleKeyEvent` that fires BEFORE
  /// dispatch in debug mode, so the keyboard becomes unresponsive.
  ///
  /// Strategy: enumerate every key the framework thinks is held via the
  /// public `physicalKeysPressed` / `logicalKeysPressed` views, then
  /// hand-craft a synthetic `KeyUpEvent` for each and feed it back
  /// through `handleKeyEvent`. The framework removes the entry from its
  /// internal map without firing the assertion (KeyUp on a held key is
  /// expected, KeyDown on a held key is the bug). Crucially this does
  /// NOT clear the framework's registered handlers — TextFields and the
  /// FocusManager's global handler keep working.
  Future<void> _resetFocus() async {
    final hw = HardwareKeyboard.instance;

    // Pair physical → logical from the public sets; for unmatched
    // physicals, fall back to LogicalKeyboardKey.unidentified — what
    // matters for clearing is the physicalKey, since that's the map's
    // key.
    final stalePhysical = hw.physicalKeysPressed.toList();
    final logicals = hw.logicalKeysPressed.toList();
    for (var i = 0; i < stalePhysical.length; i++) {
      final phys = stalePhysical[i];
      final log =
          i < logicals.length ? logicals[i] : LogicalKeyboardKey.unidentified;
      try {
        hw.handleKeyEvent(KeyUpEvent(
          physicalKey: phys,
          logicalKey: log,
          timeStamp: Duration.zero,
        ));
      } catch (_) {
        // ignore — keep clearing the rest
      }
    }

    // Belt-and-suspenders: ask the engine for actually-pressed keys.
    try {
      await hw.syncKeyboardState();
    } catch (_) {}

    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _calculatorFocusNode.requestFocus();
    });
  }

  bool _handleKeyboardInput(KeyEvent event) {
    KeyboardInputHandler.debugKeyboardInput(event);

    // If another widget (e.g. the history-search TextField) has primary
    // focus, the user is typing INTO that widget — let the event pass
    // through. The top-level KeyboardListener still fires here because
    // it sits on the focus ancestor chain, but we mustn't divert the
    // event into the LaTeX input.
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary != _calculatorFocusNode) {
      return false;
    }

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
      // `/` keypad button is now plain division to match keyboard
      // behavior. Earlier it inserted a `\frac{}{}` template which
      // produced confusing two-step "fill the numerator, then move
      // cursor to denominator" UX — users would type `2 / 4` and get
      // `2\frac{4}{}` (empty denominator → parse error). Fractions are
      // still available via the explicit `frac` keypad button below.
      case '/':
        _latexController.insert('/');
        break;
      case 'frac':
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

      // Inline unit arithmetic: `5 km + 3 m`, `100 km in mph`, etc.
      // Runs before the normal dispatcher so SymEngine never sees raw
      // unit symbols (which it would mis-parse as variables).
      final unitResult = UnitExpressionEvaluator.tryEvaluate(converted);
      if (unitResult != null) {
        setState(() {
          _appState.addHistoryEntry(expression, unitResult);
          _justCalculated = true;
        });
        _latexController.clear();
        return;
      }

      String result;
      if (_isFunctionCall(converted, 'solve')) {
        result = await _handleSolveFunction(converted);
      } else if (_isFunctionCall(converted, 'd/dx') ||
          _isFunctionCall(converted, 'diff')) {
        // `diff(expr, var)` is the SymPy / Mathematica convention;
        // `d/dx(expr, var)` is what the calculator's button emits.
        // Both route to the same handler — see _handleDifferentiateFunction.
        result = await _handleDifferentiateFunction(converted);
      } else if (_isFunctionCall(converted, 'factor')) {
        result = await _handleFactorFunction(converted);
      } else if (_isFunctionCall(converted, 'expand')) {
        result = await _handleExpandFunction(converted);
      } else if (_isFunctionCall(converted, 'simplify')) {
        result = await _handleSimplifyFunction(converted);
      } else if (_isFunctionCall(converted, 'gcd')) {
        result = _handleGcdFunction(converted);
      } else if (_isFunctionCall(converted, 'lcm')) {
        result = _handleLcmFunction(converted);
      } else if (_isFunctionCall(converted, 'integrate')) {
        result = await _handleIntegrateFunction(converted);
      } else if (_isFunctionCall(converted, 'limit')) {
        result = await _handleLimitFunction(converted);
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
        // Big expressions (integrate, factor, simplify, matrix, long
        // factorials) get offloaded to a worker isolate via
        // EngineService so the UI stays interactive. Short bare
        // arithmetic stays on the main thread — the isolate-init
        // overhead would dwarf the work.
        final rawResult = await _runEngineOpMaybeAsync('evaluate', preprocessed,
            fallback: () => _engine.evaluate(preprocessed));
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

  Future<String> _handleSolveFunction(String expression) async {
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

      return _runEngineOpMaybeAsync('solve', preprocessed,
          arg2: variable,
          fallback: () => _engine.solve(preprocessed, variable));
    } catch (e) {
      return 'Error: Invalid solve() syntax';
    }
  }

  Future<String> _handleDifferentiateFunction(String expression) async {
    try {
      // Accept both prefixes — `d/dx(EXPR, VAR)` from the keypad and
      // `diff(EXPR, VAR)` from typed input. Slice the right opener.
      final prefix = expression.startsWith('d/dx(') ? 'd/dx(' : 'diff(';
      final content =
          expression.substring(prefix.length, expression.length - 1).trim();
      final parts = content.split(',');

      String expr = parts[0].trim();
      String variable = parts.length > 1
          ? parts[1].trim()
          : ExpressionPreprocessingUtils.detectVariable(expr);

      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  expr, _appState));
      return _runEngineOpMaybeAsync('differentiate', preprocessed,
          arg2: variable,
          fallback: () => _engine.differentiate(preprocessed, variable));
    } catch (e) {
      return 'Error: Invalid d/dx() syntax';
    }
  }

  Future<String> _handleFactorFunction(String expression) async {
    try {
      final content = expression.substring(7, expression.length - 1).trim();
      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  content, _appState));
      return _runEngineOpMaybeAsync('factor', preprocessed,
          fallback: () => _engine.factor(preprocessed));
    } catch (e) {
      return 'Error: Invalid factor() syntax';
    }
  }

  Future<String> _handleExpandFunction(String expression) async {
    try {
      final content = expression.substring(7, expression.length - 1).trim();
      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  content, _appState));
      return _runEngineOpMaybeAsync('expand', preprocessed,
          fallback: () => _engine.expand(preprocessed));
    } catch (e) {
      return 'Error: Invalid expand() syntax';
    }
  }

  Future<String> _handleSimplifyFunction(String expression) async {
    try {
      final content = expression.substring(9, expression.length - 1).trim();
      final preprocessed =
          ExpressionPreprocessingUtils.preprocessNativeExpression(
              ExpressionPreprocessingUtils.preprocessExpression(
                  content, _appState));
      return _runEngineOpMaybeAsync('simplify', preprocessed,
          fallback: () => _engine.simplify(preprocessed));
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
  Future<String> _handleIntegrateFunction(String expression) async {
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
          return _runEngineOpMaybeAsync('integrate', preprocessedExpr,
              arg2: parts[0],
              arg3: parts[1],
              arg4: parts[2],
              fallback: () => _engine.integrate(
                  preprocessedExpr, parts[0], parts[1], parts[2]));
        }
        return 'Error: integrate(expr, (var, lower, upper)) expected';
      }

      // Just a variable — indefinite integral
      return _runEngineOpMaybeAsync('integrate', preprocessedExpr,
          arg2: rest,
          fallback: () => _engine.integrate(preprocessedExpr, rest));
    } catch (e) {
      return 'Error: Invalid integrate() syntax';
    }
  }

  /// limit(expr, var, point)
  Future<String> _handleLimitFunction(String expression) async {
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
      return _runEngineOpMaybeAsync('limit', preprocessedExpr,
          arg2: parts[1],
          arg3: parts[2],
          fallback: () => _engine.limit(preprocessedExpr, parts[1], parts[2]));
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
    final defaultExpr =
        expr.isEmpty ? 'x*sin(x)' : LatexConversionUtils.fromLatex(expr);
    final defaultVar = ExpressionPreprocessingUtils.detectVariable(defaultExpr);

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
    final steps = StepEngine.differentiate(preprocessed, varText, _engine);

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
    final defaultVar = ExpressionPreprocessingUtils.detectVariable(defaultExpr);

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
    final defaultVar = ExpressionPreprocessingUtils.detectVariable(defaultExpr);

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
        headlineLatex: r'\int ' + _toLatex(preprocessed) + r' \, d' + varText,
      ),
    );
  }

  /// Long-press OR right-click on a history entry opens a context menu
  /// with copy/reuse + the same math actions exposed on the function-tile
  /// menu (Show on graph, Analyze, Differentiate, Integrate, Solve f=0).
  Future<void> _showHistoryEntryMenu(
      BuildContext context, CalculationEntry entry) async {
    final t = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: Text(t.funcCtxShowOnGraph),
              onTap: () {
                Navigator.of(ctx).pop();
                _showOnGraph(entry.expression);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: Text(t.funcCtxAnalyze),
              onTap: () {
                Navigator.of(ctx).pop();
                _analyzeExpression(entry.expression);
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: Text(t.funcCtxDifferentiate),
              onTap: () {
                Navigator.of(ctx).pop();
                _latexController.insert('diff(${entry.expression}, x)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.area_chart),
              title: Text(t.funcCtxIntegrate),
              onTap: () {
                Navigator.of(ctx).pop();
                _latexController.insert('integrate(${entry.expression}, x)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(t.funcCtxSolve),
              onTap: () {
                Navigator.of(ctx).pop();
                _latexController.insert('solve(${entry.expression} = 0, x)');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(t.historyEntryCopyResult),
              onTap: () async {
                Navigator.of(ctx).pop();
                await Clipboard.setData(ClipboardData(text: entry.result));
                if (!context.mounted) return;
                _toast(context, t.historyEntryCopied);
              },
            ),
            ListTile(
              leading: const Icon(Icons.functions),
              title: Text(t.historyEntryCopyLatex),
              subtitle: Text(t.historyEntryCopyLatexSubtitle,
                  style: Theme.of(ctx).textTheme.bodySmall),
              onTap: () async {
                Navigator.of(ctx).pop();
                final latex =
                    '${MathDisplayUtils.toHistoryDisplayLatex(entry.expression)} = ${entry.result}';
                await Clipboard.setData(ClipboardData(text: latex));
                if (!context.mounted) return;
                _toast(context, t.historyEntryCopied);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(t.historyEntryReuse),
              onTap: () {
                Navigator.of(ctx).pop();
                _latexController.clear();
                _latexController.insert(entry.expression);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Park the given expression in the first free Y-slot and switch to
  /// the Graphing tab. Used by both the history context menu and the
  /// variable-viewer function-tile menu.
  void _showOnGraph(String expression) {
    final slot = _appState.graphFunctions.indexWhere((f) => f.isEmpty);
    if (slot >= 0) {
      _appState.updateFunction(slot, expression);
    }
    widget.onGoToGraphing?.call();
  }

  /// Push the curve-analysis input screen pre-filled with the expression.
  void _analyzeExpression(String expression) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CurveAnalysisInputScreen(initialFunction: expression),
    ));
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// V1 was a no-cancel watchdog; V2 adds a cancel button via a
  /// monotonic run-id discard pattern. We can't actually `Isolate.kill`
  /// a `compute()` worker, so cancel works by:
  ///   1. Bumping [_runId] when the user taps Cancel.
  ///   2. Popping the overlay and ignoring whatever the worker
  ///      eventually returns.
  /// The bridge call still runs to completion in the background — UI is
  /// unblocked, but the actual computation isn't aborted. Real
  /// isolate-kill cancellation is V3 work.
  int _runId = 0;

  /// Runs [task] and shows the [ProgressOverlay] if it hasn't finished
  /// within 300 ms. The overlay has a Cancel button; tapping it
  /// dismisses the overlay and causes this function to throw
  /// `_CancelledByUserException` (caller catches and surfaces a
  /// friendly "Cancelled" history entry).
  Future<T> _runWithProgress<T>(
    String message,
    Future<T> Function() task,
  ) async {
    final myRunId = ++_runId;
    var overlayOpen = false;
    final watchdog = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || myRunId != _runId) return;
      overlayOpen = true;
      _busyMessage = message;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: ProgressOverlay(
            isVisible: true,
            title: _busyMessage,
            onCancel: () {
              _runId++; // invalidate the in-flight task
              // V3: actually kill the worker isolate. The pending
              // future completes with EngineCancelled, which the
              // catch below reraises as _CancelledByUserException.
              EngineService.cancelInFlight();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
          ),
        ),
      );
    });
    try {
      final result = await task();
      if (myRunId != _runId) {
        throw const _CancelledByUserException();
      }
      return result;
    } on EngineCancelled {
      throw const _CancelledByUserException();
    } finally {
      watchdog.cancel();
      if (overlayOpen && mounted && myRunId == _runId) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  /// Heuristic dispatch: when the input looks slow enough, route the
  /// engine op through the worker isolate with the progress overlay;
  /// otherwise call [fallback] synchronously. The async branch uses
  /// [EngineService.runOpAsync] which serializes (op kind + args)
  /// across the isolate boundary.
  Future<String> _runEngineOpMaybeAsync(
    String op,
    String arg1, {
    String? arg2,
    String? arg3,
    String? arg4,
    required String Function() fallback,
  }) async {
    if (!EngineService.shouldRunAsync(arg1)) return fallback();
    try {
      return await _runWithProgress(
        AppLocalizations.of(context).calculating,
        () => EngineService.runOpAsync(EngineOp(op, arg1, arg2, arg3, arg4)),
      );
    } on _CancelledByUserException {
      return 'Error: cancelled';
    }
  }

  Future<void> _copyBigIntegerToClipboard(
      BuildContext context, String fullValue) async {
    final t = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: fullValue));
    if (!context.mounted) return;
    _toast(context, t.historyEntryCopied);
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
                            tooltip: AppLocalizations.of(context).searchHistory,
                            onPressed: () {
                              setState(() {
                                _historySearchOpen = !_historySearchOpen;
                                if (!_historySearchOpen) {
                                  _historySearchController.clear();
                                }
                              });
                              // Hand focus to the search field when opening.
                              // Without this the calculator's KeyboardListener
                              // (focusNode: _calculatorFocusNode) keeps the
                              // primary focus and the TextField never gets to
                              // see keystrokes.
                              if (_historySearchOpen) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) {
                                    _historySearchFocusNode.requestFocus();
                                  }
                                });
                              } else {
                                // Closed: hand focus back to the calculator.
                                _calculatorFocusNode.requestFocus();
                              }
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
                        focusNode: _historySearchFocusNode,
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
                                  tooltip: AppLocalizations.of(context)
                                      .clearSearchTooltip,
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
                                  final isError = EngineErrorFormatter.isError(
                                      entry.result);
                                  // Arbitrary-precision integer results (e.g.
                                  // 100! = 158 digits) get a digit-count
                                  // badge and tap-to-copy. We abbreviate the
                                  // middle for display past ~60 digits to
                                  // keep the row from dominating the screen,
                                  // but the clipboard always gets the full
                                  // value from entry.result.
                                  final digitCount = isError
                                      ? 0
                                      : ExactInteger.digitCount(entry.result);
                                  final isBigInt = digitCount > 20;
                                  final shownResult = isBigInt
                                      ? ExactInteger.abbreviate(entry.result)
                                      : display;
                                  return GestureDetector(
                                    onTap: isBigInt
                                        ? () => _copyBigIntegerToClipboard(
                                            context, entry.result)
                                        : null,
                                    onLongPress: () =>
                                        _showHistoryEntryMenu(context, entry),
                                    onSecondaryTap: () =>
                                        _showHistoryEntryMenu(context, entry),
                                    behavior: HitTestBehavior.opaque,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        _buildExpressionDisplay(
                                            entry.expression),
                                        const SizedBox(height: 4),
                                        Text(
                                          isError ? display : '= $shownResult',
                                          style: TextStyle(
                                            fontSize: isError
                                                ? 16
                                                : (isBigInt ? 18 : 28),
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
                                          softWrap: true,
                                        ),
                                        if (isBigInt)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '${tt.exactIntegerBadge(digitCount)} · ${tt.exactIntegerTapToCopy}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                                fontStyle: FontStyle.italic,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                      ],
                                    ),
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

            // LaTeX input field + always-visible action row (reset focus,
            // backspace, ◀/▶, =/EXE) so the user never has to hunt for a
            // submit button across keypad tabs and can always recover from
            // a stuck focus state by tapping the refresh icon.
            Container(
              height: 120,
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Toolbar on the LEFT — the LaTeX field below is
                        // right-bound (new characters appear on the right),
                        // so keeping tools on the left keeps them out of
                        // the way of the live input.
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Reset keyboard focus',
                          onPressed: _resetFocus,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.backspace_outlined),
                          tooltip: 'Backspace',
                          onPressed: () => _latexController.backspace(),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Move cursor left',
                          onPressed: () => _latexController.moveCursor(-1),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Move cursor right',
                          onPressed: () => _latexController.moveCursor(1),
                          visualDensity: VisualDensity.compact,
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.keyboard_return, size: 18),
                          label: const Text('='),
                          onPressed: () => _onButtonPressed('EXE'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            alignment: Alignment.centerRight,
                            constraints: const BoxConstraints(minHeight: 60),
                            child: SingleChildScrollView(
                              reverse: true,
                              scrollDirection: Axis.horizontal,
                              child:
                                  LatexInputField(controller: _latexController),
                            ),
                          ),
                        ),
                      ],
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
                onGoToGraphing: widget.onGoToGraphing,
                onGoToAnalysis: widget.onGoToAnalysis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal signal raised by [CalculatorScreenState._runWithProgress]
/// when the user taps the Cancel button on the progress overlay. The
/// in-flight compute() can't be aborted (Isolate.kill via a real
/// long-lived worker is V3 work), so we mark the run as cancelled and
/// the caller surfaces a friendly "Error: cancelled" entry.
class _CancelledByUserException implements Exception {
  const _CancelledByUserException();
}
