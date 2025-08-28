/// lib/screens/calculator_screen.dart

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
  
  // Memory system for storing results
  final Map<String, String> _memory = {}; // M1, M2, ... M9
  int _memoryCounter = 1;

  @override
  void initState() {
    super.initState();
    _currentState = this;
    _tabController = TabController(length: 4, vsync: this);
    _controller.addListener(_onInputChanged);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        requestFocus();
      }
    });
  }
  
  void requestFocus() {
    if (!mounted) return;
    _inputFocusNode.requestFocus();
  }

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
      _resultPreview = (result != "Error" && result != currentText && double.tryParse(result) != null) ? result : '';
    } catch (e) {
      _resultPreview = '';
    }
  }

  bool handleKeyboardInput(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;

    // Only handle special keys, let normal typing go through TextField
    if (key == LogicalKeyboardKey.enter) { 
      _onButtonPressed("EXE"); 
      return true; 
    }
    if (key == LogicalKeyboardKey.escape) { 
      _onButtonPressed('C'); 
      return true; 
    }
    
    // Don't intercept normal keys - let TextField handle them
    return false;
  }

  void _onButtonPressed(String value) {
    if (_justCalculated && !_isUtilityButton(value)) {
      final lastResult = _appState.history.firstOrNull?.result ?? '';
      final isOperator = ['+', '-', '*', '/', '^', '%', '='].contains(value);
      
      setState(() {
        if (isOperator && lastResult.isNotEmpty && !lastResult.contains('Error')) {
          String valueToUse = lastResult;
          if (lastResult.contains(' = ')) {
            valueToUse = _extractNumericFromSolveResult(lastResult);
          }
          _controller.text = valueToUse + value;
          _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        } else {
          _controller.text = value;
          _controller.selection = TextSelection.collapsed(offset: value.length);
        }
        _justCalculated = false;
      });
      requestFocus();
      return;
    }

    if (_justCalculated) setState(() => _justCalculated = false);
    
    // Handle memory operations
    if (value.startsWith('M') && value.length == 2) {
      final memKey = value;
      if (_memory.containsKey(memKey)) {
        _insertTextAtCursor(_memory[memKey]!);
        return;
      }
    }
    
    // Handle memory store
    if (value == 'STO') {
      _showMemoryStoreDialog();
      return;
    }
    
    // Handle advanced calculus operations
    if (value.startsWith('d/dx') || value.startsWith('∫') || value == 'lim') {
      _insertAdvancedFunction(value);
      return;
    }
    
    const functionsWithBrackets = ['sin(', 'cos(', 'tan(', 'ln(', 'log(', 'sqrt(', 'abs('];
    if (functionsWithBrackets.contains(value)) {
      _insertFunctionSyntax(value);
    } else if (value == 'solve') {
      _insertFunctionSyntax('solve(');
    } else if (value == 'f(x)') {
      _showFunctionPicker();
    } else if (value == 'factor' || value == 'simplify' || value == 'expand') {
      _applyCasFunction(value);
    } else {
      _handleSpecialInput(value);
    }
    requestFocus();
  }
  
  // Centralized, robust text and selection update
  void _updateTextAndSelection(String newText, int newOffset) {
    if (!mounted) return;
    
    // Ensure offset is within bounds
    final safeOffset = newOffset.clamp(0, newText.length);
    
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: safeOffset),
    );
    
    // Ensure focus without triggering text selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.selection = TextSelection.collapsed(offset: safeOffset);
      }
    });
  }

  // Insert text at current cursor position
  void _insertTextAtCursor(String text) {
    final selection = _controller.selection;
    final currentText = _controller.text;
    
    final start = selection.start.clamp(0, currentText.length);
    final end = selection.end.clamp(start, currentText.length);
    
    final newText = currentText.substring(0, start) + text + currentText.substring(end);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  void _handleSpecialInput(String value) {
    switch (value) {
      case 'C':
        _controller.clear();
        break;
      case '⌫':
        final selection = _controller.selection;
        final currentText = _controller.text;
        if (selection.start > 0) {
          if (selection.isCollapsed) {
            // Delete character before cursor
            final newText = currentText.substring(0, selection.start - 1) + currentText.substring(selection.start);
            _controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: selection.start - 1),
            );
          } else {
            // Delete selected text
            final newText = currentText.substring(0, selection.start) + currentText.substring(selection.end);
            _controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: selection.start),
            );
          }
        }
        break;
      case 'DEL':
        final selection = _controller.selection;
        final currentText = _controller.text;
        if (selection.start < currentText.length) {
          if (selection.isCollapsed) {
            // Delete character after cursor
            final newText = currentText.substring(0, selection.start) + currentText.substring(selection.start + 1);
            _controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: selection.start),
            );
          } else {
            // Delete selected text
            final newText = currentText.substring(0, selection.start) + currentText.substring(selection.end);
            _controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: selection.start),
            );
          }
        }
        break;
      case 'EXE':
        if (_controller.text.isNotEmpty) _calculate(_controller.text);
        break;
      case '◀':
        final selection = _controller.selection;
        if (selection.start > 0) {
          _controller.selection = TextSelection.collapsed(offset: selection.start - 1);
        }
        break;
      case '▶':
        final selection = _controller.selection;
        if (selection.start < _controller.text.length) {
          _controller.selection = TextSelection.collapsed(offset: selection.start + 1);
        }
        break;
      default:
        _insertTextAtCursor(value);
    }
  }
  
  void _insertFunctionSyntax(String func) {
    final selection = _controller.selection;
    final currentText = _controller.text;
    
    final start = selection.start.clamp(0, currentText.length);
    final end = selection.end.clamp(start, currentText.length);
    
    final textToInsert = '$func)';
    final newText = currentText.substring(0, start) + textToInsert + currentText.substring(end);
    
    // Position cursor inside the parentheses
    final cursorPosition = start + func.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
  
  bool _isUtilityButton(String value) => ['C', '⌫', 'DEL', "EXE", '◀', '▶', 'STO'].contains(value) || value.startsWith('M');

  void _showMemoryStoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store to Memory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Store current result to which memory slot?'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: List.generate(9, (index) {
                final memKey = 'M${index + 1}';
                final hasValue = _memory.containsKey(memKey);
                return ElevatedButton(
                  onPressed: () {
                    final lastResult = _appState.history.firstOrNull?.result ?? '';
                    if (lastResult.isNotEmpty && !lastResult.contains('Error')) {
                      String valueToStore = lastResult;
                      if (lastResult.contains(' = ')) {
                        valueToStore = _extractNumericFromSolveResult(lastResult);
                      }
                      _memory[memKey] = valueToStore;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Stored $valueToStore to $memKey')),
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasValue ? Colors.green.shade700 : null,
                  ),
                  child: Text(memKey),
                );
              }),
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

  void _insertAdvancedFunction(String funcName) {
    final selection = _controller.selection;
    final currentText = _controller.text;
    
    final start = selection.start.clamp(0, currentText.length);
    final end = selection.end.clamp(start, currentText.length);
    
    String textToInsert;
    int cursorOffset;
    
    switch (funcName) {
      case 'd/dx':
        textToInsert = 'diff(, x)';
        cursorOffset = 5; // Position after "diff("
        break;
      case '∫':
        textToInsert = 'integrate(, x)';
        cursorOffset = 10; // Position after "integrate("
        break;
      case 'lim':
        textToInsert = 'limit(, x, 0)';
        cursorOffset = 6; // Position after "limit("
        break;
      default:
        textToInsert = '$funcName()';
        cursorOffset = funcName.length + 1;
    }
    
    final newText = currentText.substring(0, start) + textToInsert + currentText.substring(end);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + cursorOffset),
    );
  }

  void _calculate(String expression) {
    try {
      String result;
      HistoryEntryType type = HistoryEntryType.calculation;
      final cleanedExpr = expression.trim().toLowerCase();
      final ySubstitutedExpr = _preprocessExpression(expression);

      if (cleanedExpr.startsWith('solve(')) {
        type = HistoryEntryType.solve;
        var regExp = RegExp(r'solve\((.+),\s*([a-zA-Z])\s*\)');
        var match = regExp.firstMatch(ySubstitutedExpr);
        if (match == null) {
          regExp = RegExp(r'solve\((.+)\)');
          match = regExp.firstMatch(ySubstitutedExpr);
        }

        if (match != null) {
          final equation = match.group(1)!.trim();
          final variable = match.groupCount > 1 ? match.group(2)!.trim() : 'x';
          String expressionForSolver;
          List<String> parts = equation.split('=');
          if (parts.length == 2) {
            expressionForSolver = '${parts[0].trim()} - (${parts[1].trim()})';
          } else {
            expressionForSolver = equation;
          }
          final solution = _engine.solve(_preprocessNativeExpression(expressionForSolver), variable);
          result = "$variable = $solution";
          
          // Auto-store solve results in memory for easy access
          if (!solution.contains('Error') && _memoryCounter <= 9) {
            _memory['M$_memoryCounter'] = _extractNumericFromSolveResult(result);
            _memoryCounter++;
          }
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
        requestFocus();
      });
    } catch (e) {
      setState(() => _appState.addHistoryEntry(expression, "Error", type: HistoryEntryType.calculation));
    }
  }
  
  // Extract numeric value from solve results like "x = 6" -> "6"
  String _extractNumericFromSolveResult(String solveResult) {
    final match = RegExp(r'[a-zA-Z]\s*=\s*([+-]?[\d.]+(?:,\s*[+-]?[\d.]+)*)').firstMatch(solveResult);
    if (match != null) {
      final values = match.group(1)!;
      // If single value, return it; if multiple, keep original format
      if (!values.contains(',')) {
        return values.trim();
      }
    }
    return solveResult; // Keep original if not simple numeric
  }

  void _applyCasFunction(String funcName) {
    final lastResult = _appState.history.firstOrNull?.result ?? '';
    if (lastResult.isEmpty || lastResult.contains("Error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous result to apply CAS function to')),
      );
      return;
    }

    final exprToProcess = lastResult.startsWith('=') ? lastResult.substring(1).trim() : lastResult;
    
    String result;
    switch (funcName) {
      case 'factor':
        result = _engine.factor(exprToProcess);
        break;
      case 'expand':
        result = _engine.expand(exprToProcess);
        break;
      case 'simplify':
        result = _engine.expand(exprToProcess);
        break;
      default:
        result = 'Unknown CAS function';
    }
    
    setState(() {
      final expr = '$funcName($exprToProcess)';
      _appState.addHistoryEntry(expr, result);
      _justCalculated = true;
      _controller.clear();
      requestFocus();
    });
  }

  String _preprocessNativeExpression(String expression) {
    String processed = expression;
    processed = processed.replaceAllMapped(RegExp(r'(\d|\))(\()'), (m) => '${m[1]}*${m[2]}');
    processed = processed.replaceAllMapped(RegExp(r'(\))(\d|[a-zA-Z])'), (m) => '${m[1]}*${m[2]}');
    processed = processed.replaceAllMapped(RegExp(r'(\d)([a-zA-Z])'), (m) => '${m[1]}*${m[2]}');
    processed = processed.replaceAllMapped(RegExp(r'([a-zA-Z])(\d)'), (m) => '${m[1]}*${m[2]}');
    
    // Fix factorial handling - match number or parenthesized expression followed by !
    processed = processed.replaceAllMapped(RegExp(r'(\d+(?:\.\d+)?|\([^)]*\))!'), (m) {
      final base = m.group(1)!;
      return 'factorial($base)';
    });
    
    processed = processed.replaceAllMapped(RegExp(r'([\w\.\(\)]+)\s*%\s*([\w\.\(\)]+)'), (m) => 'Mod(${m[1]},${m[2]})');
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
      } catch (e) { 
        return match.group(0)!; 
      }
      return match.group(0)!;
    });
    return processed;
  }
  
  void _showPlotSolveDialog(CalculationEntry entry) {
    var regExp = RegExp(r'solve\((.+),\s*[a-zA-Z]\s*\)');
    var match = regExp.firstMatch(entry.expression);
    if (match == null) {
      final regExp2 = RegExp(r'solve\((.+)\)');
      match = regExp2.firstMatch(entry.expression);
    }
    if (match == null) return;
    
    final equation = match.group(1)!.trim();
    String functionToPlot = '';
    List<String> parts = equation.split('=');
    functionToPlot = (parts.length == 2) ? '${parts[0].trim()} - (${parts[1].trim()})' : equation;
    
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Add to Function List'),
        content: Text('Add "$functionToPlot" to the next available Y= slot to graph it?'),
        actions: [
          TextButton(
            child: const Text('Cancel'), 
            onPressed: () => Navigator.of(context).pop()
          ),
          ElevatedButton(
            child: const Text('Add to Y='), 
            onPressed: () {
              final emptySlotIndex = _appState.graphFunctions.indexWhere((f) => f.isEmpty);
              if (emptySlotIndex != -1) {
                _appState.updateFunction(emptySlotIndex, functionToPlot);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added to Y${emptySlotIndex + 1}')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All function slots are full')),
                );
              }
              Navigator.of(context).pop();
            }
          ),
        ],
      )
    );
  }
  
  void _showSolveFunctionPicker() {
    showModalBottomSheet(
      context: context, 
      builder: (context) {
        return ListView(
          children: [
            if (_appState.graphFunctions.any((f) => f.isNotEmpty)) ...[
              const ListTile(
                title: Text('Select function to solve:', style: TextStyle(fontWeight: FontWeight.bold))
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
                    final currentText = _controller.text;
                    final selection = _controller.selection;
                    final start = selection.start.clamp(0, currentText.length);
                    final end = selection.end.clamp(start, currentText.length);
                    
                    final textToInsert = 'solve(Y${index+1}=0, x)';
                    final newText = currentText.substring(0, start) + textToInsert + currentText.substring(end);
                    _controller.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: start + textToInsert.length),
                    );
                  },
                );
              }).toList()
            ] else ...[
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('No functions available'),
                subtitle: Text('Add functions in the graphing screen first'),
              ),
            ]
          ],
        );
      }
    );
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
                  _insertFunctionSyntax('Y${index+1}(');
                },
              );
            }).toList()
          ],
        );
      }
    );
  }

  String _toLaTeX(String input) {
    if (input.isEmpty) return '';
    String latex = input;
    latex = latex.replaceAllMapped(RegExp(r'sqrt\((.*?)\)'), (match) => '\\sqrt{${match.group(1)}}');
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
                          onTap: () => setState(() {
                            _controller.text = entry.expression;
                            _controller.selection = TextSelection.collapsed(offset: entry.expression.length);
                            _justCalculated = false;
                          }),
                          child: Text(
                            entry.expression, 
                            style: TextStyle(fontSize: 20, color: Colors.grey[500]), 
                            textAlign: TextAlign.right
                          ),
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
                                onTap: () {
                                  if (_justCalculated) {
                                    _controller.text = entry.result;
                                    _controller.selection = TextSelection.collapsed(offset: entry.result.length);
                                  } else {
                                    final currentText = _controller.text;
                                    final selection = _controller.selection;
                                    final start = selection.start.clamp(0, currentText.length);
                                    final end = selection.end.clamp(start, currentText.length);
                                    
                                    final newText = currentText.substring(0, start) + entry.result + currentText.substring(end);
                                    _controller.value = TextEditingValue(
                                      text: newText,
                                      selection: TextSelection.collapsed(offset: start + entry.result.length),
                                    );
                                  }
                                  _justCalculated = false;
                                },
                                child: Math.tex(
                                  _toLaTeX("= ${entry.result}"), 
                                  textStyle: TextStyle(
                                    fontSize: 28, 
                                    color: Colors.blue[300], 
                                    fontWeight: FontWeight.w500
                                  )
                                ),
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
                  readOnly: false, // Allow normal typing
                  showCursor: true,
                  autofocus: true,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _justCalculated ? (_appState.history.firstOrNull?.result ?? '0') : '0',
                    hintStyle: TextStyle(
                      fontSize: 48, 
                      color: _justCalculated ? Colors.grey[500] : Colors.grey[700]
                    ),
                  ),
                ),
                if (_resultPreview.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "= $_resultPreview", 
                      style: TextStyle(fontSize: 24, color: Colors.grey[600])
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController, 
                  tabs: const [
                    Tab(text: 'Num'), 
                    Tab(text: 'f(x)'), 
                    Tab(text: 'CAS'),
                    Tab(text: 'Mem')
                  ]
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Numbers and basic operations
                      KeypadGrid(
                        buttons: const [
                          'C', '⌫', '%', '/', 
                          '7', '8', '9', '*', 
                          '4', '5', '6', '-', 
                          '1', '2', '3', '+', 
                          '0', '.', '^', 'EXE'
                        ], 
                        onButtonPressed: _onButtonPressed
                      ),
                      // Functions and trigonometry
                      KeypadGrid(
                        buttons: const [
                          'sin(', 'cos(', 'tan(', 'x', 
                          'ln(', 'log(', 'sqrt(', '(', 
                          'e', 'pi', '!', ')', 
                          'abs(', 'deg', 'rad', 'EXE'
                        ], 
                        onButtonPressed: _onButtonPressed
                      ),
                      // CAS and advanced calculus operations
                      KeypadGrid(
                        buttons: const [
                          'solve', 'f(x)', 'd/dx', '∫', 
                          'factor', 'expand', 'lim', '◀', 
                          'simplify', '=', ',', '▶', 
                          '{', '}', '[', ']'
                        ], 
                        onButtonPressed: _onButtonPressed
                      ),
                      // Memory operations
                      KeypadGrid(
                        buttons: const [
                          'STO', 'M1', 'M2', 'M3',
                          'DEL', 'M4', 'M5', 'M6', 
                          '◀', 'M7', 'M8', 'M9',
                          '▶', '(', ')', 'EXE'
                        ], 
                        onButtonPressed: _onButtonPressed
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