/// lib/screens/graphing_screen.dart - Fixed Focus Management

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../engine/calculator_engine.dart';
import '../engine/app_state.dart';
import '../utils/keyboard_input_handler.dart';
import '../screens/curve_analysis_input_screen.dart';

class GraphingScreen extends StatefulWidget {
  const GraphingScreen({super.key});

  @override
  State<GraphingScreen> createState() => _GraphingScreenState();
}

class _GraphingScreenState extends State<GraphingScreen> {
  final AppState _appState = AppState();
  final TextEditingController _functionController = TextEditingController();
  final FocusNode _screenFocusNode = FocusNode(); // For keyboard listener
  final FocusNode _textFieldFocusNode = FocusNode(); // Separate for TextField
  final CalculatorEngine _engine = CalculatorEngine();
  
  // Graph view controls
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _focalStart = Offset.zero;

  @override
  void initState() {
    super.initState();
    // Request focus for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _functionController.dispose();
    _screenFocusNode.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  bool _handleKeyboardInput(KeyEvent event) {
    // Only handle if the text field is focused
    if (!_textFieldFocusNode.hasFocus) {
      return false;
    }
    
    return KeyboardInputHandler.handleKeyboardInput(
      event,
      (text) => _insertAtCursor(text),
      () => _backspaceAtCursor(),
      () => _clearFunction(),
      () => _addFunction(),
      (amount) => _moveCursorInFunction(amount),
    );
  }

  void _insertAtCursor(String text) {
    final selection = _functionController.selection;
    final newText = _functionController.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    _functionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _showAnalysisOptions() {
    final activeFunctions = <String>[];
    final activeFunctionIndices = <int>[];
    
    for (int i = 0; i < _appState.graphFunctions.length; i++) {
      if (_appState.graphFunctions[i].isNotEmpty) {
        activeFunctions.add(_appState.graphFunctions[i]);
        activeFunctionIndices.add(i);
      }
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
            ...activeFunctionIndices.map((index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColorForFunction(index).withOpacity(0.2),
                child: Text(
                  'Y${index + 1}',
                  style: TextStyle(
                    color: _getColorForFunction(index),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text('Y${index + 1}(x)'),
              subtitle: Text(
                _appState.graphFunctions[index], 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
              onTap: () {
                Navigator.of(context).pop();
                _analyzeFunction(index);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _analyzeFunction(int index) {
    final function = _appState.graphFunctions[index];
    if (function.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CurveAnalysisInputScreen(initialFunction: function),
        ),
      );
    }
  }

  void _backspaceAtCursor() {
    final selection = _functionController.selection;
    if (selection.isCollapsed && selection.baseOffset > 0) {
      final newText = _functionController.text.replaceRange(
        selection.baseOffset - 1,
        selection.baseOffset,
        '',
      );
      _functionController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.baseOffset - 1),
      );
    } else if (!selection.isCollapsed) {
      final newText = _functionController.text.replaceRange(
        selection.start,
        selection.end,
        '',
      );
      _functionController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
  }

  void _clearFunction() {
    _functionController.clear();
  }

  void _moveCursorInFunction(int amount) {
    final selection = _functionController.selection;
    final newOffset = (selection.baseOffset + amount).clamp(0, _functionController.text.length);
    _functionController.selection = TextSelection.collapsed(offset: newOffset);
  }

  void _addFunction() {
    final textToAdd = _functionController.text.trim();
    if (textToAdd.isEmpty) return;

    final emptySlotIndex = _appState.graphFunctions.indexWhere((f) => f.isEmpty);
    if (emptySlotIndex != -1) {
      _appState.updateFunction(emptySlotIndex, textToAdd);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Function added to Y${emptySlotIndex + 1}'),
          duration: const Duration(seconds: 2),
        ),
      );
      _functionController.clear();
      _textFieldFocusNode.unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All function slots are full. Clear a function first.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeFunction(String functionToRemove) {
    final index = _appState.graphFunctions.indexOf(functionToRemove);
    if (index != -1) {
      _appState.clearFunction(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed Y${index + 1}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  void _clearAllFunctions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Functions'),
        content: const Text('Are you sure you want to clear all graphed functions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              for (int i = 0; i < _appState.graphFunctions.length; i++) {
                _appState.clearFunction(i);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Color _getColorForFunction(int index) {
    const colors = [
      Colors.blue, Colors.red, Colors.green, Colors.purple,
      Colors.orange, Colors.teal, Colors.pink, Colors.brown,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _screenFocusNode, // Separate focus node for screen
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          final keyEvent = KeyDownEvent(
            physicalKey: event.physicalKey,
            logicalKey: event.logicalKey,
            character: event.character,
            timeStamp: Duration.zero,
            synthesized: false,
          );
          _handleKeyboardInput(keyEvent);
        }
      },
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, child) {
          final activeFunctions = <String>[];
          final activeFunctionIndices = <int>[];
          
          for (int i = 0; i < _appState.graphFunctions.length; i++) {
            if (_appState.graphFunctions[i].isNotEmpty) {
              activeFunctions.add(_appState.graphFunctions[i]);
              activeFunctionIndices.add(i);
            }
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Graphing (${activeFunctions.length} functions)'),
              actions: [
                if (activeFunctions.isNotEmpty)
                  IconButton(
                    onPressed: _showAnalysisOptions,
                    icon: const Icon(Icons.analytics),
                    tooltip: 'Analyze Functions',
                  ),
                IconButton(
                  onPressed: _resetView,
                  icon: const Icon(Icons.center_focus_strong),
                  tooltip: 'Reset View',
                ),
                if (activeFunctions.isNotEmpty)
                  IconButton(
                    onPressed: _clearAllFunctions,
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear All Functions',
                  ),
              ],
            ),
            body: Column(
              children: [
                // Graph display area
                Expanded(
                  child: GestureDetector(
                    onScaleStart: (details) {
                      _focalStart = details.localFocalPoint;
                      _startScale = _scale;
                      _startOffset = _offset;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        _scale = (_startScale * details.scale).clamp(0.1, 20.0);
                        _offset = _startOffset + (details.localFocalPoint - _focalStart);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade800, width: 1),
                      ),
                      child: CustomPaint(
                        painter: GraphPainter(
                          functions: activeFunctions,
                          functionIndices: activeFunctionIndices,
                          scale: _scale,
                          offset: _offset,
                          engine: _engine,
                          getColorForFunction: _getColorForFunction,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
                
                // Controls area
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Function input with German keyboard support
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _functionController,
                              focusNode: _textFieldFocusNode, // Separate focus node
                              decoration: const InputDecoration(
                                labelText: 'Enter function to plot',
                                border: OutlineInputBorder(),
                                prefixText: 'y = ',
                                hintText: 'e.g., x^2, sin(x), ln(x+1)',
                              ),
                              onSubmitted: (_) => _addFunction(),
                              onTap: () {
                                // Give focus to text field when tapped
                                _textFieldFocusNode.requestFocus();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_chart),
                            label: const Text('Plot'),
                            onPressed: _addFunction,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Active functions display
                      if (activeFunctions.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Active Functions:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: activeFunctionIndices.length,
                            itemBuilder: (context, index) {
                              final funcText = activeFunctions[index];
                              final originalIndex = activeFunctionIndices[index];
                              final yLabel = 'Y${originalIndex + 1}';
                              final color = _getColorForFunction(originalIndex);
                              
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: color,
                                    radius: 8,
                                  ),
                                  label: SizedBox(
                                    width: 120,
                                    child: Text(
                                      '$yLabel = $funcText',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  backgroundColor: color.withOpacity(0.1),
                                  side: BorderSide(color: color, width: 1),
                                  onDeleted: () => _removeFunction(funcText),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.functions,
                                size: 48,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No functions plotted',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter a function above to start graphing',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// [Rest of GraphPainter class stays the same as before]
class GraphPainter extends CustomPainter {
  final List<String> functions;
  final List<int> functionIndices;
  final double scale;
  final Offset offset;
  final CalculatorEngine engine;
  final Color Function(int) getColorForFunction;

  GraphPainter({
    required this.functions,
    required this.functionIndices,
    required this.scale,
    required this.offset,
    required this.engine,
    required this.getColorForFunction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2 + offset.dx;
    final centerY = size.height / 2 + offset.dy;
    final double unit = 25 * scale;

    // Draw grid and axes
    _drawGrid(canvas, size, centerX, centerY, unit);
    _drawAxes(canvas, size, centerX, centerY);
    _drawAxisLabels(canvas, size, centerX, centerY, unit);

    // Draw functions
    for (int i = 0; i < functions.length; i++) {
      final func = functions[i];
      final originalIndex = functionIndices[i];
      final paint = Paint()
        ..color = getColorForFunction(originalIndex)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      try {
        _plotFunction(canvas, size, func, centerX, centerY, unit, paint);
      } catch (e) {
        debugPrint('Error plotting function $func: $e');
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size, double centerX, double centerY, double unit) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 0.5;

    double gridSpacing = unit;
    if (unit < 10) {
      gridSpacing = unit * 5;
    } else if (unit > 100) {
      gridSpacing = unit / 2;
    }

    // Vertical lines
    double x = centerX;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      x += gridSpacing;
    }
    x = centerX - gridSpacing;
    while (x > 0) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      x -= gridSpacing;
    }

    // Horizontal lines
    double y = centerY;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      y += gridSpacing;
    }
    y = centerY - gridSpacing;
    while (y > 0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      y -= gridSpacing;
    }
  }

  void _drawAxes(Canvas canvas, Size size, double centerX, double centerY) {
    final axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0;

    // X-axis
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    // Y-axis
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);
  }

  void _drawAxisLabels(Canvas canvas, Size size, double centerX, double centerY, double unit) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final textStyle = TextStyle(color: Colors.grey.shade300, fontSize: 10);

    double getNiceStep(double idealStep) {
      if (idealStep <= 0) return 1.0;
      final double powerOf10 = math.pow(10, (math.log(idealStep) / math.ln10).floor()).toDouble();
      final double normalized = idealStep / powerOf10;

      if (normalized < 1.5) return 1.0 * powerOf10;
      if (normalized < 3.5) return 2.0 * powerOf10;
      if (normalized < 7.5) return 5.0 * powerOf10;
      return 10.0 * powerOf10;
    }

    const double pixelsPerLabel = 80.0;
    final double idealStep = pixelsPerLabel / unit;
    final double step = getNiceStep(idealStep);
    final int precision = (step < 1) ? (-math.log(step) / math.ln10).ceil() : 0;

    // X-axis labels
    final double startX = -centerX / unit;
    final double endX = (size.width - centerX) / unit;

    for (double i = (startX / step).floor() * step; i <= endX; i += step) {
      if (i.abs() < step / 100) continue; // Skip origin
      
      final x = centerX + i * unit;
      if (x < 15 || x > size.width - 15) continue;

      textPainter.text = TextSpan(text: i.toStringAsFixed(precision), style: textStyle);
      textPainter.layout();
      
      double labelY = centerY + 8;
      if (labelY > size.height - 20) labelY = centerY - 20;

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, labelY));
    }

    // Y-axis labels
    final double startY = -(size.height - centerY) / unit;
    final double endY = centerY / unit;

    for (double i = (startY / step).floor() * step; i <= endY; i += step) {
      if (i.abs() < step / 100) continue; // Skip origin
      
      final y = centerY - i * unit;
      if (y < 15 || y > size.height - 15) continue;
      
      textPainter.text = TextSpan(text: i.toStringAsFixed(precision), style: textStyle);
      textPainter.layout();
      
      double labelX = centerX + 8;
      if (labelX > size.width - 30) labelX = centerX - textPainter.width - 8;

      textPainter.paint(canvas, Offset(labelX, y - textPainter.height / 2));
    }
  }

  void _plotFunction(Canvas canvas, Size size, String func, double centerX, double centerY, double unit, Paint paint) {
    final path = Path();
    bool hasStarted = false;
    double? lastY;
    
    final double stepSize = math.min(0.05, math.max(0.001, 1.0 / unit));
    final double startX = (-size.width / 2 - offset.dx) / unit;
    final double endX = (size.width / 2 - offset.dx) / unit;

    for (double mathX = startX; mathX <= endX; mathX += stepSize) {
      try {
        double mathY = _evaluateFunction(func, mathX);
        
        if (!mathY.isFinite) {
          hasStarted = false;
          lastY = null;
          continue;
        }
        
        double screenX = centerX + mathX * unit;
        double screenY = centerY - mathY * unit;
        
        // Skip points way off screen
        if (screenY < -size.height * 2 || screenY > size.height * 3) {
          hasStarted = false;
          lastY = null;
          continue;
        }
        
        // Detect discontinuities
        if (lastY != null && (mathY - lastY).abs() > 50 / scale) {
          hasStarted = false;
        }
        
        if (!hasStarted) {
          path.moveTo(screenX, screenY);
          hasStarted = true;
        } else {
          path.lineTo(screenX, screenY);
        }
        
        lastY = mathY;
        
      } catch (e) {
        hasStarted = false;
        lastY = null;
      }
    }
    
    canvas.drawPath(path, paint);
  }

  double _evaluateFunction(String func, double x) {
    String processedFunc = func;
    
    // Add implicit multiplication
    processedFunc = processedFunc.replaceAllMapped(RegExp(r'(\d)([a-zA-Z(])'), (m) => '${m[1]}*${m[2]}');
    processedFunc = processedFunc.replaceAllMapped(RegExp(r'(\))([a-zA-Z\d(])'), (m) => '${m[1]}*${m[2]}');
    
    // Replace x with actual value, handling negative numbers
    String valueStr = x.toString();
    if (x < 0 || valueStr.contains('e')) {
      valueStr = '($valueStr)';
    }
    
    String expressionWithX = processedFunc.replaceAll('x', valueStr);
    
    // Use the enhanced evaluation method to handle complex number format of SymEngine
    String result = engine.evaluateForGraphing(expressionWithX);
    
    if (result == 'Error' || result.isEmpty) {
      throw Exception('Evaluation failed');
    }
    
    double? value = double.tryParse(result);
    if (value == null) {
      throw Exception('Invalid result: $result');
    }
    
    return value;
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.functions.length != functions.length ||
        oldDelegate.functions.toString() != functions.toString() ||
        oldDelegate.functionIndices.toString() != functionIndices.toString() ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}