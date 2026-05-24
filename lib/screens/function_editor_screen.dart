// lib/screens/function_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../controllers/latex_controller.dart';

import '../engine/app_state.dart';

import '../localization/app_localizations.dart';
import '../utils/keyboard_input_handler.dart';
import '../utils/latex_conversion_utils.dart';
import '../utils/math_display_utils.dart';

import '../widgets/calculator_keypad.dart';
import '../widgets/latex_input_field.dart';

import '../screens/curve_analysis_input_screen.dart';
import '../screens/graphing_screen.dart';

class FunctionEditorScreen extends StatefulWidget {
  final void Function(int functionIndex)? onSwitchToGraphing;

  const FunctionEditorScreen({super.key, this.onSwitchToGraphing});

  @override
  State<FunctionEditorScreen> createState() => _FunctionEditorScreenState();
}

class _FunctionEditorScreenState extends State<FunctionEditorScreen>
    with SingleTickerProviderStateMixin {
  final AppState _appState = AppState();
  late final LatexController _activeController; // Single active controller
  final FocusNode _screenFocusNode = FocusNode();
  int? _activeFunctionIndex; // Which function is currently being edited
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _activeController = LatexController();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _activeController.dispose();
    _screenFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _analyzeFunction(int index) {
    final function = _appState.graphFunctions[index];
    if (function.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              CurveAnalysisInputScreen(initialFunction: function),
        ),
      );
    }
  }

  void _graphFunction(int index) {
    final function = _appState.graphFunctions[index];
    if (function.isNotEmpty) {
      // Prefer the tab-switch callback supplied by the main nav. Falls
      // back to a Navigator.push when the editor is opened outside the
      // main scaffold (e.g. from a test harness).
      if (widget.onSwitchToGraphing != null) {
        widget.onSwitchToGraphing!(index);
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GraphingScreen(),
          ),
        );
      }
    }
  }

  void _activateFunction(int index) {
    if (_activeFunctionIndex == index) return; // Already active

    // Save current function if there was one active
    if (_activeFunctionIndex != null) {
      _saveFunctionFromController();
    }

    // Load new function into controller
    setState(() {
      _activeFunctionIndex = index;
      _activeController.clear();
      final functionText = _appState.graphFunctions[index];
      if (functionText.isNotEmpty) {
        _activeController.insert(functionText);
      }
    });

    // Request focus for the keyboard listener
    _screenFocusNode.requestFocus();
  }

  void _deactivateFunction() {
    if (_activeFunctionIndex != null) {
      _saveFunctionFromController();
      setState(() {
        _activeFunctionIndex = null;
        _activeController.clear();
      });
      // Ensure the screen can still receive focus after deactivating
      _screenFocusNode.requestFocus();
    }
  }

  void _saveFunctionFromController() {
    if (_activeFunctionIndex != null) {
      final text = _activeController.text.trim();
      final plainText = LatexConversionUtils.fromLatex(text);
      _appState.updateFunction(_activeFunctionIndex!, plainText);
    }
  }

  void _insertVariable(String name) {
    if (_activeFunctionIndex != null) {
      _activeController.insert(name);
    } else {
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.funcEditorSelectFirst)),
      );
    }
  }

  void _onButtonPressed(String value) {
    if (_activeFunctionIndex == null) {
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.funcEditorSelectFirst)),
      );
      return;
    }

    // Handle button presses and insert into the active controller
    switch (value) {
      case 'C':
        _activeController.clear();
        break;
      case '⌫':
        _activeController.backspace();
        break;
      case 'EXE':
        _deactivateFunction(); // Acts as a "Done" button
        break;
      case '◀':
        _activeController.moveCursor(-1);
        break;
      case '▶':
        _activeController.moveCursor(1);
        break;
      // --- LaTeX Template Insertions ---
      case '/':
        _activeController.insert(r'\frac{}{}', cursorOffsetFromEnd: -3);
        break;
      case 'sqrt':
        _activeController.insert(r'\sqrt{}', cursorOffsetFromEnd: -1);
        break;
      case 'sin':
        _activeController.insert(r'\sin()', cursorOffsetFromEnd: -1);
        break;
      case 'cos':
        _activeController.insert(r'\cos()', cursorOffsetFromEnd: -1);
        break;
      case 'tan':
        _activeController.insert(r'\tan()', cursorOffsetFromEnd: -1);
        break;
      case 'ln':
        _activeController.insert(r'\ln()', cursorOffsetFromEnd: -1);
        break;
      case 'log':
        _activeController.insert(r'\log()', cursorOffsetFromEnd: -1);
        break;
      case 'abs':
        _activeController.insert(r'abs()', cursorOffsetFromEnd: -1);
        break;
      case 'asin':
        _activeController.insert(r'\arcsin()', cursorOffsetFromEnd: -1);
        break;
      case 'acos':
        _activeController.insert(r'\arccos()', cursorOffsetFromEnd: -1);
        break;
      case 'atan':
        _activeController.insert(r'\arctan()', cursorOffsetFromEnd: -1);
        break;
      case 'sinh':
        _activeController.insert(r'\sinh()', cursorOffsetFromEnd: -1);
        break;
      case 'cosh':
        _activeController.insert(r'\cosh()', cursorOffsetFromEnd: -1);
        break;
      case 'tanh':
        _activeController.insert(r'\tanh()', cursorOffsetFromEnd: -1);
        break;
      case '^':
        _activeController.insert(r'^{}', cursorOffsetFromEnd: -1);
        break;
      case '_':
        _activeController.insert(r'_{}', cursorOffsetFromEnd: -1);
        break;
      case 'π':
        _activeController.insert(r'\pi');
        break;
      case 'e':
        _activeController.insert('E');
        break;
      case 'γ':
        _activeController.insert('EulerGamma');
        break;
      case '!':
        _activeController.insert('!');
        break;
      case '∞':
        _activeController.insert(r'\infty');
        break;
      default:
        _activeController.insert(value);
        break;
    }
  }

  bool _handleKeyboardInput(KeyEvent event) {
    return KeyboardInputHandler.handleKeyboardInput(
      event,
      (text) => _onButtonPressed(text), // Reuse button handler logic
      () => _onButtonPressed('⌫'),
      () => _onButtonPressed('C'),
      () => _onButtonPressed('EXE'),
      (amount) => _onButtonPressed(amount > 0 ? '▶' : '◀'),
    );
  }

  /// Convert function text to LaTeX for passive display
  String _toLatex(String text) {
    return MathDisplayUtils.toHistoryDisplayLatex(text);
  }

  Widget _buildFunctionDisplay(int index) {
    final function = _appState.graphFunctions[index];
    final isActive = _activeFunctionIndex == index;

    if (isActive) {
      // Active function with LaTeX input field
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: LatexInputField(controller: _activeController),
        ),
      );
    } else if (function.isNotEmpty) {
      // Passive function with LaTeX display
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            _toLatex(function),
            textStyle: const TextStyle(fontSize: 18),
            onErrorFallback: (err) => Text(
              function,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    } else {
      // Empty function placeholder
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          'Y${index + 1}(x)',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _screenFocusNode,
      // No autofocus — see calculator_screen.dart for the reasoning.
      onKeyEvent: _handleKeyboardInput,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, child) {
          final t = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(t.funcEditorTitle),
              actions: [
                if (_activeFunctionIndex != null)
                  TextButton(
                    onPressed: _deactivateFunction,
                    child: Text(t.funcEditorDone),
                  ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildFunctionList(),
                ),
                const Divider(height: 1),
                Expanded(
                  flex: 5,
                  child: CalculatorKeypad(
                    tabController: _tabController,
                    onButtonPressed: _onButtonPressed,
                    localizations: AppLocalizations.of(context),
                    appState: _appState,
                    onVariableTap: _insertVariable,
                    memory: null,
                    onMemoryAction: null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFunctionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _appState.graphFunctions.length,
      itemBuilder: (context, index) {
        final isActive = _activeFunctionIndex == index;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => isActive
                      ? _deactivateFunction()
                      : _activateFunction(index),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        width: isActive ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isActive
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.05)
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Function label
                        Container(
                          width: 60,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _getColorForFunction(index)
                                .withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Y${index + 1}',
                            style: TextStyle(
                              color: _getColorForFunction(index),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        // Function display (active input or passive display)
                        Expanded(
                          child: _buildFunctionDisplay(index),
                        ),

                        // Action buttons
                        if (_appState.graphFunctions[index].isNotEmpty &&
                            !isActive)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.analytics, size: 18),
                                tooltip: AppLocalizations.of(context)
                                    .funcEditorAnalyzeTooltip,
                                onPressed: () => _analyzeFunction(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.show_chart, size: 18),
                                tooltip: AppLocalizations.of(context)
                                    .funcEditorGraphTooltip,
                                onPressed: () => _graphFunction(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                tooltip: AppLocalizations.of(context)
                                    .clearFunctionSlotTooltip,
                                onPressed: () => _appState.clearFunction(index),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColorForFunction(int index) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }
}
