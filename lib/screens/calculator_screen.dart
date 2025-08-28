/// lib/screens/calculator_screen.dart:

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/calculator_engine.dart';
import '../widgets/keypad_grid.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// The main calculator screen with proper = behavior like traditional calculators
class CalculatorScreen extends StatefulWidget {
  final bool Function(KeyEvent)? onKeyEvent;

  const CalculatorScreen({super.key, this.onKeyEvent});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();

  bool handleKeyboardInput(KeyEvent event) {
    final state = _CalculatorScreenState._currentState;
    return state?.handleKeyboardInput(event) ?? false;
  }
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  static _CalculatorScreenState? _currentState;

  late TabController _tabController;
  String _expression = '';
  String _result = '';
  String _lastResult = ''; // Your state for chained calculations
  bool _justCalculated = false; // Your state for tracking equals press
  bool _isDialogActive = false; // Flag to fix dialog input

  final CalculatorEngine _engine = CalculatorEngine();

  @override
  void initState() {
    super.initState();
    _currentState = this;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _currentState = null;
    _tabController.dispose();
    super.dispose();
  }
  
  // FIX: Keyboard handler now ignores input when dialog is active
  bool handleKeyboardInput(KeyEvent event) {
    if (_isDialogActive) return false;

    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      final character = event.character;

      if (key == LogicalKeyboardKey.digit0) _onButtonPressed('0');
      else if (key == LogicalKeyboardKey.digit1) _onButtonPressed('1');
      else if (key == LogicalKeyboardKey.digit2) _onButtonPressed('2');
      else if (key == LogicalKeyboardKey.digit3) _onButtonPressed('3');
      else if (key == LogicalKeyboardKey.digit4) _onButtonPressed('4');
      else if (key == LogicalKeyboardKey.digit5) _onButtonPressed('5');
      else if (key == LogicalKeyboardKey.digit6) _onButtonPressed('6');
      else if (key == LogicalKeyboardKey.digit7) _onButtonPressed('7');
      else if (key == LogicalKeyboardKey.digit8) _onButtonPressed('8');
      else if (key == LogicalKeyboardKey.digit9) _onButtonPressed('9');
      else if (character == '+') _onButtonPressed('+');
      else if (character == '-') _onButtonPressed('-');
      else if (character == '*') _onButtonPressed('*');
      else if (character == '/') _onButtonPressed('/');
      else if (character == '.') _onButtonPressed('.');
      else if (character == '^') _onButtonPressed('^');
      else if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.enter) _onButtonPressed('=');
      else if (key == LogicalKeyboardKey.backspace) _onButtonPressed('⌫');
      else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.delete) _onButtonPressed('C');
      else return false;

      return true;
    }
    return false;
  }
  
  // RESTORED: This is your correct calculator logic
  void _onButtonPressed(String value) {
    if (value == 'solve') {
      _showSolveDialog();
      return;
    }

    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '';
        _lastResult = '';
        _justCalculated = false;
      } else if (value == '⌫') {
        _justCalculated = false;
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        if (_expression.isNotEmpty) {
          try {
            _result = _engine.evaluate(_expression);
            _lastResult = _result;
            _justCalculated = true;
          } catch (e) {
            _result = 'Error';
            _lastResult = '';
            _justCalculated = false;
          }
        }
      } else if (_isOperator(value)) {
        if (_justCalculated && _lastResult.isNotEmpty) {
          // Start new expression with the last result
          _expression = _lastResult + value;
          _result = ''; // Clear previous result from display
        } else if (_expression.isNotEmpty) {
          _expression += value;
        }
        _justCalculated = false;
      } else { // Handle numbers and functions
        if (_justCalculated) {
          // Start a completely new expression
          _expression = value;
          _result = '';
        } else {
          _expression += value;
        }
        _justCalculated = false;
      }
    });
  }

  bool _isOperator(String value) {
    return ['+', '-', '*', '/', '^', '%'].contains(value);
  }

  // FIX: Dialog handler now correctly manages focus state
  void _showSolveDialog() {
    final TextEditingController equationController = TextEditingController();
    
    setState(() => _isDialogActive = true);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Solve Equation'),
          content: TextField(
            controller: equationController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g., x^2 - 4 = 0',
              labelText: 'Equation (in terms of x)',
            ),
            onSubmitted: (_) {
                _solveEquation(equationController.text);
                Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                 _solveEquation(equationController.text);
                 Navigator.of(context).pop();
              },
              child: const Text('Solve'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      setState(() => _isDialogActive = false);
    });
  }
  
  // FIX: Correctly parses equations like A=B into A-(B)
  void _solveEquation(String userInput) {
      if (userInput.isNotEmpty) {
        String expressionForSolver;

        List<String> parts = userInput.split('=');
        if (parts.length == 2) {
          String lhs = parts[0].trim();
          String rhs = parts[1].trim();
          expressionForSolver = '$lhs - ($rhs)';
        } else {
          expressionForSolver = userInput.trim();
        }
        
        final solution = _engine.solve(expressionForSolver, 'x');

        setState(() {
          _expression = "solve($userInput)";
          _result = "x = $solution";
          _justCalculated = true;
          _lastResult = '';
        });
      }
  }
  
  // Formats result for LaTeX display
  String _toLaTeX(String input) {
    if (input.isEmpty) return '';
    String latex = input;
    latex = latex.replaceAllMapped(RegExp(r'sqrt\((.*?)\)'), (match) => r'\sqrt{${match.group(1)}}');
    latex = latex.replaceAll('*I', 'i');
    latex = latex.replaceAll('*', r' \cdot ');
    return latex;
  }

  @override
  Widget build(BuildContext context) {
    // Determine what to show in the main display and result display
    final displayExpression = _justCalculated ? _lastResult : _expression;
    final displayResult = _justCalculated ? _result : '';

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Faded expression when a result is shown
                    if (_justCalculated && _expression.isNotEmpty)
                      Text(
                        _expression,
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w300),
                        textAlign: TextAlign.right,
                      ),
                    const Spacer(),
                    // Main display
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        displayExpression.isEmpty ? '0' : displayExpression,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    // Result display (only when calculated)
                    if (displayResult.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Math.tex(
                          _toLaTeX("= $displayResult"),
                          textStyle: TextStyle(
                            fontSize: 32,
                            color: Colors.blue[300],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [ Tab(text: '123'), Tab(text: 'f(x)'), Tab(text: 'CAS'), ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      KeypadGrid(
                        buttons: const [ 'C', '⌫', '%', '/', '7', '8', '9', '*', '4', '5', '6', '-', '1', '2', '3', '+', '0', '.', '^', '=', ],
                        onButtonPressed: _onButtonPressed,
                      ),
                      KeypadGrid(
                        buttons: const [ 'sin(', 'cos(', 'tan(', 'pi', 'ln(', 'log(', 'sqrt(', '(', 'e', ')', '!', 'ans', 'abs(', 'deg', 'rad', '=', ],
                        onButtonPressed: _onButtonPressed,
                      ),
                      KeypadGrid(
                        buttons: const [ '∫ dx', 'd/dx', 'lim', 'solve', 'matrix', 'vector', '[', ']', 'simplify', 'factor', '{', '}', 'expand', ',', ':', '=', ],
                        onButtonPressed: _onButtonPressed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}