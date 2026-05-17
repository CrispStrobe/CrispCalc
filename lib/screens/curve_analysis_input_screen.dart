// lib/screens/curve_analysis_input_screen.dart
// Input screen for the curve sketching module (Kurvendiskussion).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/latex_controller.dart';
import '../engine/calculator_engine.dart';
import '../engine/analysis_engine.dart';
import '../engine/app_state.dart';
import '../localization/app_localizations.dart';
import '../utils/keyboard_input_handler.dart';
import '../utils/latex_conversion_utils.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/latex_input_field.dart';
import 'curve_analysis_results_screen.dart';

class CurveAnalysisInputScreen extends StatefulWidget {
  final String? initialFunction;

  const CurveAnalysisInputScreen({super.key, this.initialFunction});

  @override
  State<CurveAnalysisInputScreen> createState() =>
      _CurveAnalysisInputScreenState();
}

class _CurveAnalysisInputScreenState extends State<CurveAnalysisInputScreen>
    with SingleTickerProviderStateMixin {
  final LatexController _latexController = LatexController();
  final AppState _appState = AppState();
  final FocusNode _focusNode = FocusNode();
  late final TabController _tabController;

  final _calculatorEngine = CalculatorEngine();
  late final AnalysisEngine _analysisEngine;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    final initialText = widget.initialFunction ?? 'x^3 - 3*x';
    _latexController.insert(initialText);
    _analysisEngine = AnalysisEngine(_calculatorEngine);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _latexController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool _handleKeyboardInput(KeyEvent event) {
    return KeyboardInputHandler.handleKeyboardInput(
      event,
      (text) => _onButtonPressed(text),
      () => _onButtonPressed('⌫'),
      () => _onButtonPressed('C'),
      () => _runAnalysis(),
      (amount) => _onButtonPressed(amount > 0 ? '▶' : '◀'),
    );
  }

  void _onButtonPressed(String value) {
    _focusNode.requestFocus();
    switch (value) {
      case 'C':
        _latexController.clear();
        break;
      case '⌫':
        _latexController.backspace();
        break;
      case 'EXE':
        _runAnalysis();
        break;
      case '◀':
        _latexController.moveCursor(-1);
        break;
      case '▶':
        _latexController.moveCursor(1);
        break;
      case '/':
        _latexController.insert(r'\frac{}{}', cursorOffsetFromEnd: -3);
        break;
      case 'sqrt':
        _latexController.insert(r'\sqrt{}', cursorOffsetFromEnd: -1);
        break;
      case '^':
        _latexController.insert(r'^{}', cursorOffsetFromEnd: -1);
        break;
      case 'π':
        _latexController.insert(r'\pi');
        break;
      default:
        _latexController.insert(value);
        break;
    }
  }

  Future<void> _runAnalysis() async {
    final latexFunction = _latexController.text.trim();
    final function = LatexConversionUtils.fromLatex(latexFunction);

    if (function.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a function.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _analysisEngine.performCurveAnalysis(function);

      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => CurveAnalysisResultsScreen(
            results: results,
            onSaveAsFunction: _saveAsFunction,
            onSaveResultAsVariable: _saveResultAsVariable,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during analysis: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveAsFunction() {
    final latexFunction = _latexController.text.trim();
    final function = LatexConversionUtils.fromLatex(latexFunction);
    if (function.isEmpty) return;

    // Find first empty function slot
    for (int i = 0; i < _appState.graphFunctions.length; i++) {
      if (_appState.graphFunctions[i].isEmpty) {
        _appState.updateFunction(i, function);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved as Y${i + 1}')),
        );
        return;
      }
    }

    // If no empty slots, ask user to confirm overwrite
    _showOverwriteFunctionDialog(function);
  }

  void _saveResultAsVariable(String name, String value) {
    _appState.setVariable(name, value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $name = $value')),
    );
  }

  void _showOverwriteFunctionDialog(String function) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All function slots are full'),
        content: const Text('Which function would you like to replace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ...List.generate(
              _appState.graphFunctions.length,
              (i) => TextButton(
                    onPressed: () {
                      _appState.updateFunction(i, function);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Replaced Y${i + 1}')),
                      );
                    },
                    child: Text(
                        'Y${i + 1}${_appState.graphFunctions[i].isNotEmpty ? ' (${_appState.graphFunctions[i]})' : ''}'),
                  )),
        ],
      ),
    );
  }

  void _selectFromFunctions() {
    final nonEmptyFunctions = _appState.graphFunctions
        .asMap()
        .entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (nonEmptyFunctions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved functions available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Function to Analyze',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...nonEmptyFunctions.map((entry) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    child: Text('Y${entry.key + 1}'),
                  ),
                  title: Text('Y${entry.key + 1}(x)'),
                  subtitle: Text(entry.value,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    _latexController.clear();
                    _latexController.insert(entry.value);
                    Navigator.of(context).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curve Sketching'),
        actions: [
          IconButton(
            icon: const Icon(Icons.functions),
            tooltip: 'Select from saved functions',
            onPressed: _selectFromFunctions,
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyboardInput,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter a function to analyze:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade700,
                            width: _focusNode.hasFocus ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            const Text("f(x) = ",
                                style: TextStyle(fontSize: 18)),
                            Expanded(
                                child: LatexInputField(
                                    controller: _latexController)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Save as function',
                    onPressed: _saveAsFunction,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _runAnalysis,
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Analyze'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: CalculatorKeypad(
                  tabController: _tabController,
                  onButtonPressed: _onButtonPressed,
                  localizations: AppLocalizations.of(context),
                  appState: _appState,
                  onVariableTap: (name) => _latexController.insert(name),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
