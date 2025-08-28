/// lib/screens/calculator_screen.dart:

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../engine/app_state.dart';
import '../engine/calculator_engine.dart';
import '../widgets/keypad_grid.dart';

class CalculatorScreen extends StatefulWidget {
  final bool Function(KeyEvent)? onKeyEvent;
  const CalculatorScreen({super.key, this.onKeyEvent});

  @override
  State<CalculatorScreen> createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin {
  static CalculatorScreenState? _currentState;
  final AppState _appState = AppState();
  final CalculatorEngine _engine = CalculatorEngine();

  late TabController _tabController;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  String _resultPreview = '';
  bool _justCalculated = false;

  @override
  void initState() {
    super.initState();
    _currentState = this;
    _tabController = TabController(length: 3, vsync: this);
    _controller.addListener(_onInputChanged);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) requestFocus();
    });
  }
  
  void requestFocus() => _inputFocusNode.requestFocus();

  @override
  void dispose() {
    _currentState = null;
    _tabController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }
  
  void _onInputChanged() {
    if (_controller.text.isNotEmpty && _justCalculated) {
      setState(() { _justCalculated = false; });
    }
    setState(() => _updateLivePreview());
  }
  
  void _updateLivePreview() {
    String currentText = _controller.text;
    if (currentText.isEmpty || currentText.trim().toLowerCase().startsWith('solve')) {
      _resultPreview = '';
      return;
    }
    try {
      final ySubstituted = _preprocessExpression(currentText);
      final preprocessed = _preprocessNativeExpression(ySubstituted);
      final result = _engine.evaluate(preprocessed);
      _resultPreview = (result != "Error") ? result : '';
    } catch (e) {
      _resultPreview = '';
    }
  }

  bool handleKeyboardInput(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    final character = event.character;

    if (key == LogicalKeyboardKey.enter) { _onButtonPressed("EXE"); return true; }
    if (key == LogicalKeyboardKey.backspace) { _onButtonPressed('⌫'); return true; }
    if (key == LogicalKeyboardKey.escape) { _onButtonPressed('C'); return true; }
    if (key == LogicalKeyboardKey.arrowLeft) { _onButtonPressed('◀'); return true; }
    if (key == LogicalKeyboardKey.arrowRight) { _onButtonPressed('▶'); return true; }

    if (character != null && character.isNotEmpty && character != ' ') {
      _onButtonPressed(character);
      return true;
    }
    return false;
  }

  void _onButtonPressed(String value) {
    if (!_controller.selection.isValid) {
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }
    
    if (_justCalculated && !_isUtilityButton(value)) {
      final lastResult = _appState.history.firstOrNull?.result ?? '';
      final isOperator = ['+', '-', '*', '/', '^', '%', '='].contains(value);

      setState(() {
        if (isOperator && lastResult.isNotEmpty && !lastResult.contains('Error')) {
          _controller.text = lastResult + value;
        } else {
          _controller.text = value;
        }
        _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
        _justCalculated = false;
      });
      return;
    }

    if (_justCalculated) setState(() => _justCalculated = false);
    
    const functionsWithBrackets = ['sin(', 'cos(', 'tan(', 'ln(', 'log(', 'sqrt(', 'abs(', 'Y1(', 'Y2('];
    if (functionsWithBrackets.contains(value)) {
      _insertFunctionSyntax(value);
    } else if (value == 'solve') {
      _showSolveFunctionPicker();
    } else {
      _insertText(value);
    }
  }
  
  void _insertText(String value) {
    final currentText = _controller.text;
    final selection = _controller.selection;

    setState(() {
      if (value == 'C') {
        _controller.clear();
      } else if (value == '⌫') {
        if (selection.isCollapsed) {
          if (selection.start > 0) {
            _controller.text = currentText.substring(0, selection.start - 1) + currentText.substring(selection.start);
            _controller.selection = TextSelection.fromPosition(TextPosition(offset: selection.start - 1));
          }
        } else {
          _controller.text = currentText.substring(0, selection.start) + currentText.substring(selection.end);
          _controller.selection = TextSelection.fromPosition(TextPosition(offset: selection.start));
        }
      } 
      else if (value == "EXE") {
        if (currentText.isNotEmpty) _calculate(currentText);
      } else if (value == '◀') {
        if(selection.start > 0) _controller.selection = TextSelection.fromPosition(TextPosition(offset: selection.start - 1));
      } else if (value == '▶') {
        if(selection.start < currentText.length) _controller.selection = TextSelection.fromPosition(TextPosition(offset: selection.start + 1));
      } else {
        final newText = currentText.substring(0, selection.start) + value + currentText.substring(selection.end);
        _controller.text = newText;
        _controller.selection = TextSelection.fromPosition(TextPosition(offset: selection.start + value.length));
      }
    });
  }
  
  void _insertFunctionSyntax(String func) {
    final currentText = _controller.text;
    final selection = _controller.selection;
    final textToInsert = '$func)';
    
    setState(() {
      _controller.text = currentText.substring(0, selection.start) + textToInsert + currentText.substring(selection.end);
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: selection.start + func.length));
    });
  }
  
  bool _isUtilityButton(String value) => ['C', '⌫', "EXE", '◀', '▶'].contains(value);

  void _calculate(String expression) {
    try {
      String result;
      HistoryEntryType type = HistoryEntryType.calculation;
      final cleanedExpr = expression.trim().toLowerCase();

      final ySubstitutedExpr = _preprocessExpression(expression);

      if (cleanedExpr.startsWith('solve(')) {
        type = HistoryEntryType.solve;
        final regExp = RegExp(r'solve\((.+),\s*([a-zA-Z])\s*\)');
        final match = regExp.firstMatch(ySubstitutedExpr);

        if (match != null) {
          final equation = match.group(1)!.trim();
          final variable = match.group(2)!.trim();
          String expressionForSolver;
          List<String> parts = equation.split('=');
          if (parts.length == 2) {
            expressionForSolver = '${parts[0].trim()} - (${parts[1].trim()})';
          } else {
            expressionForSolver = equation;
          }
          final solution = _engine.solve(_preprocessNativeExpression(expressionForSolver), variable);
          result = "$variable = $solution";
        } else {
          result = "Error: Use solve(eq, var)";
        }
      } else {
        final preprocessed = _preprocessNativeExpression(ySubstitutedExpr);
        result = _engine.evaluate(preprocessed);
      }
      
      setState(() {
        _appState.addHistoryEntry(expression, result, type: type);
        _resultPreview = '';
        _justCalculated = true;
        _controller.clear();
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    } catch (e) {
      setState(() => _resultPreview = 'Error: ${e.toString()}');
    }
  }

  String _preprocessNativeExpression(String expression) {
    String processed = expression;
    processed = processed.replaceAllMapped(RegExp(r'(\d|\))(\()'), (m) => '${m[1]}*${m[2]}');
    processed = processed.replaceAllMapped(RegExp(r'(\))(\d|[a-zA-Z])'), (m) => '${m[1]}*${m[2]}');
    processed = processed.replaceAllMapped(RegExp(r'(\d)([a-zA-Z])'), (m) => '${m[1]}*${m[2]}');
    processed = processed.replaceAllMapped(RegExp(r'(\d+|(\(.*?\)))!'), (match) => 'factorial(${match.group(1)})');
    processed = processed.replaceAllMapped(RegExp(r'([a-zA-Z0-9\.\(\)]+)\s*%\s*([a-zA-Z0-9\.\(\)]+)'), (m) => 'Mod(${m[1]},${m[2]})');
    return processed;
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
      } catch (e) { return match.group(0)!; }
      return match.group(0)!;
    });
    return processed;
  }
  
  void _showPlotSolveDialog(CalculationEntry entry) {
    final regExp = RegExp(r'solve\((.+),\s*[a-zA-Z]\s*\)');
    final match = regExp.firstMatch(entry.expression);
    if (match == null) return;
    
    final equation = match.group(1)!.trim();
    String functionToPlot = '';
    
    List<String> parts = equation.split('=');
    if (parts.length == 2) {
      functionToPlot = '${parts[0].trim()} - (${parts[1].trim()})';
    } else {
      functionToPlot = equation;
    }
    
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Add to Function List'),
      content: Text('Add "$functionToPlot" to the next available Y= slot to graph it?'),
      actions: [
        TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(child: const Text('Add to Y='), onPressed: () {
          final emptySlotIndex = _appState.graphFunctions.indexWhere((f) => f.isEmpty);
          if (emptySlotIndex != -1) {
            _appState.updateFunction(emptySlotIndex, functionToPlot);
          }
          Navigator.of(context).pop();
        }),
      ],
    ));
  }
  
  void _showSolveFunctionPicker() {
    showModalBottomSheet(context: context, builder: (context) {
      return ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Type equation manually'),
            onTap: () {
              Navigator.of(context).pop();
              _insertFunctionSyntax('solve(');
            },
          ),
          const Divider(),
          ..._appState.graphFunctions.asMap().entries.where((entry) => entry.value.isNotEmpty).map((entry) {
            int index = entry.key;
            String func = entry.value;
            return ListTile(
              title: Text('Y${index + 1} = $func'),
              onTap: () {
                Navigator.of(context).pop();
                _insertText('solve(Y${index+1}=0, x)');
              },
            );
          })
        ],
      );
    });
  }

  String _toLaTeX(String input) {
    if (input.isEmpty) return '';
    String latex = input;
    latex = latex.replaceAllMapped(RegExp(r'sqrt\((.*?)\)'), (match) => r'\\sqrt{${match.group(1)}}');
    latex = latex.replaceAll('*I', 'i');
    latex = latex.replaceAll('*', r' \cdot ');
    return latex;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: ListenableBuilder(
              listenable: _appState,
              builder: (context, child) => ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: _appState.history.length,
                itemBuilder: (context, index) {
                  final entry = _appState.history[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _controller.text = entry.expression),
                          child: Text(entry.expression, style: TextStyle(fontSize: 20, color: Colors.grey[500]), textAlign: TextAlign.right),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (entry.type == HistoryEntryType.solve && !entry.result.contains("Error"))
                              IconButton(
                                icon: Icon(MdiIcons.chartLine, color: Colors.greenAccent),
                                onPressed: () => _showPlotSolveDialog(entry),
                              ),
                            Flexible(
                              child: InkWell(
                                onTap: () => _onButtonPressed(entry.result),
                                child: Math.tex(_toLaTeX("= ${entry.result}"), textStyle: TextStyle(fontSize: 28, color: Colors.blue[300], fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _inputFocusNode,
                  readOnly: true,
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text("= $_resultPreview", style: TextStyle(fontSize: 24, color: Colors.grey[600])),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                TabBar(controller: _tabController, tabs: const [Tab(text: '123'), Tab(text: 'f(x)'), Tab(text: 'CAS')]),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      KeypadGrid(buttons: const ['C', '⌫', '%', '/', '7', '8', '9', '*', '4', '5', '6', '-', '1', '2', '3', '+', '0', '.', '^', 'EXE'], onButtonPressed: _onButtonPressed),
                      KeypadGrid(buttons: const ['sin(', 'cos(', 'tan(', 'x', 'ln(', 'log(', 'sqrt(', '(', 'e', ')', '!', 'pi', 'abs(', 'deg', 'rad', 'EXE'], onButtonPressed: _onButtonPressed),
                      KeypadGrid(buttons: const ['solve', '(', ')', '^', 'Y1(', 'Y2(', '◀', '▶', 'simplify', 'factor', ',', '=', '{', '}', '[', ']'], onButtonPressed: _onButtonPressed),
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