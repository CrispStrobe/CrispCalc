/// lib/screens/calculator_screen.dart:

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../engine/calculator_engine.dart';
import '../widgets/keypad_grid.dart';

/// The main calculator screen, featuring a rich math display and a tabbed keypad.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _expression = '';
  String _result = '';

  // Instantiate the calculator engine to handle all logic.
  final CalculatorEngine _engine = CalculatorEngine();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return input
        .replaceAll('*', r'\times ')
        .replaceAll('/', r'\frac')
        .replaceAll('sqrt', r'\sqrt')
        .replaceAll('pi', r'\pi ');
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
                    // Renders the expression using LaTeX.
                    Math.tex(
                      _toLaTeX(_expression),
                      textStyle: const TextStyle(fontSize: 38),
                      mathStyle: MathStyle.display,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result,
                      style: TextStyle(fontSize: 24, color: Colors.grey[400]),
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
                          '7', '8', '9', '/',
                          '4', '5', '6', '*',
                          '1', '2', '3', '-',
                          '0', '.', '⌫', '+'
                        ],
                        onButtonPressed: _onButtonPressed,
                      ),
                      KeypadGrid(
                        buttons: const [
                          'sin(', 'cos(', 'tan(', '^',
                          'ln(', 'log(', 'sqrt(', '(',
                          'e', 'pi', ')', 'C',
                          'abs(', '!', '%', '='
                        ],
                        onButtonPressed: _onButtonPressed,
                      ),
                      KeypadGrid(
                        buttons: const [
                          '∫ dx', 'd/dx', 'lim', 'solve',
                          'matrix', 'vector', '[', ']',
                          'simplify', 'factor', '{', '}',
                          'expand', ',', ':', '='
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