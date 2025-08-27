/// lib/screens/calculator_screen.dart:

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../engine/calculator_engine.dart';
import '../widgets/keypad_grid.dart';

/// The main calculator screen, featuring a rich math display and a tabbed keypad.
class CalculatorScreen extends StatefulWidget {
  final bool Function(KeyEvent)? onKeyEvent;
  
  const CalculatorScreen({super.key, this.onKeyEvent});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();

  // Method to handle keyboard input from parent
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

  // Instantiate the calculator engine to handle all logic.
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

  bool handleKeyboardInput(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      final character = event.character;
      
      // Handle digits
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
      
      // Handle operators by character
      else if (character == '+') _onButtonPressed('+');
      else if (character == '-') _onButtonPressed('-');
      else if (character == '*') _onButtonPressed('*');
      else if (character == '/') _onButtonPressed('/');
      else if (character == '.') _onButtonPressed('.');
      
      // Handle special keys
      else if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.enter) _onButtonPressed('=');
      else if (key == LogicalKeyboardKey.backspace) _onButtonPressed('⌫');
      else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.delete) _onButtonPressed('C');
      else return false;
      
      return true;
    }
    return false;
  }

  /// Handles all button presses from the keypads.
  void _onButtonPressed(String value) {
    if (value == 'solve') {
      _showSolveDialog();
      return;
    }

    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        if (_expression.isNotEmpty) {
          try {
            // This is where the FFI bridge to SymEngine is called.
            _result = _engine.evaluate(_expression);
          } catch (e) {
            _result = 'Error';
          }
        }
      } else {
        _expression += value;
      }
    });
  }

  /// Shows the dialog for the equation solver.
  void _showSolveDialog() {
    final TextEditingController equationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Solve Equation'),
          content: TextField(
            controller: equationController,
            decoration: const InputDecoration(
              hintText: 'e.g., x^2 - 4 = 0',
              labelText: 'Equation (in terms of x)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (equationController.text.isNotEmpty) {
                  String expression =
                      equationController.text.split('=')[0].trim();
                  
                  // This is where the FFI bridge to the solver is called.
                  final solution = _engine.solve(expression, 'x');

                  setState(() {
                    _expression = "solve(${equationController.text})";
                    _result = "x = {$solution}";
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Solve'),
            ),
          ],
        );
      },
    );
  }

  /// Converts a plain text expression to a LaTeX-compatible string for rendering.
  String _toLaTeX(String input) {
    if (input.isEmpty) return '';
    
    String latex = input;
    
    // Handle basic replacements more carefully
    latex = latex.replaceAll('*', r' \times ');
    latex = latex.replaceAll('pi', r'\pi');
    latex = latex.replaceAll('sqrt(', r'\sqrt{');
    
    // Handle division - this is tricky, need to find the operands
    // For now, just display as is and let the math renderer handle it
    latex = latex.replaceAll('/', r' \div ');
    
    // Handle functions
    latex = latex.replaceAll('sin(', r'\sin(');
    latex = latex.replaceAll('cos(', r'\cos(');
    latex = latex.replaceAll('tan(', r'\tan(');
    latex = latex.replaceAll('ln(', r'\ln(');
    latex = latex.replaceAll('log(', r'\log(');
    
    // Handle exponents
    latex = latex.replaceAll('^', r'^');
    
    return latex;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // --- Display Area ---
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Display expression as plain text
                    Container(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _expression.isEmpty ? '0' : _expression,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: 24, 
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Keypad Area ---
          Expanded(
            flex: 5,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '123'),
                    Tab(text: 'f(x)'),
                    Tab(text: 'CAS'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      KeypadGrid(
                        buttons: const [
                          'C', '⌫', '%', '/',
                          '7', '8', '9', '*',
                          '4', '5', '6', '-',
                          '1', '2', '3', '+',
                          '0', '.', '00', '=',
                        ],
                        onButtonPressed: _onButtonPressed,
                      ),
                      KeypadGrid(
                        buttons: const [
                          'sin(', 'cos(', 'tan(', '^',
                          'ln(', 'log(', 'sqrt(', '(',
                          'e', 'pi', ')', 'C',
                          'abs(', '!', '%', '=',
                        ],
                        onButtonPressed: _onButtonPressed,
                      ),
                      KeypadGrid(
                        buttons: const [
                          '∫ dx', 'd/dx', 'lim', 'solve',
                          'matrix', 'vector', '[', ']',
                          'simplify', 'factor', '{', '}',
                          'expand', ',', ':', '=',
                        ],
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