/// lib/screens/graphing_screen.dart:

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../engine/calculator_engine.dart';
import '../engine/app_state.dart';

class GraphingScreen extends StatefulWidget {
  const GraphingScreen({super.key});

  @override
  State<GraphingScreen> createState() => _GraphingScreenState();
}

class _GraphingScreenState extends State<GraphingScreen> {
  final AppState _appState = AppState();
  final TextEditingController _functionController = TextEditingController();

  double _scale = 1.0;
  Offset _offset = Offset.zero;

  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _focalStart = Offset.zero;

  final CalculatorEngine _engine = CalculatorEngine();
  
  // FIX: Added clear user feedback via a SnackBar.
  void _addFunction() {
    if (_functionController.text.isNotEmpty) {
      final textToAdd = _functionController.text.trim();
      setState(() {
        final emptySlotIndex = _appState.graphFunctions.indexWhere((f) => f.isEmpty);
        if (emptySlotIndex != -1) {
          _appState.graphFunctions[emptySlotIndex] = textToAdd;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Function saved to Y${emptySlotIndex + 1}'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All function slots are full.')),
          );
        }
        _functionController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }

  void _removeFunction(String functionToRemove) {
    setState(() {
      final index = _appState.graphFunctions.indexOf(functionToRemove);
      if (index != -1) {
        _appState.graphFunctions[index] = '';
      }
    });
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    setState(() {});
    final allFunctions = _appState.graphFunctions.where((f) => f.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphing'),
        actions: [
          IconButton(onPressed: _resetView, icon: const Icon(Icons.center_focus_strong), tooltip: 'Reset View'),
        ],
      ),
      body: Column(
        children: [
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
              child: CustomPaint(
                painter: GraphPainter(functions: allFunctions, scale: _scale, offset: _offset, engine: _engine),
                size: Size.infinite,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _functionController,
                        decoration: const InputDecoration(labelText: 'Enter a function to plot', border: OutlineInputBorder(), prefixText: 'y = '),
                        onSubmitted: (_) => _addFunction(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(icon: const Icon(Icons.add_chart), label: const Text('Plot'), onPressed: _addFunction),
                  ],
                ),
                const SizedBox(height: 12),
                if (allFunctions.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allFunctions.length,
                      itemBuilder: (context, index) {
                        final funcText = allFunctions[index];
                        final yIndex = _appState.graphFunctions.indexOf(funcText);
                        final label = 'Y${yIndex + 1}';
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text('$label = $funcText'),
                            backgroundColor: _getColorForFunction(yIndex).withOpacity(0.2),
                            side: BorderSide(color: _getColorForFunction(yIndex), width: 1.5),
                            onDeleted: () => _removeFunction(funcText),
                            deleteIcon: const Icon(Icons.close, size: 16),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

   Color _getColorForFunction(int index) {
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.purple,
      Colors.orange, Colors.teal, Colors.pink, Colors.brown,
    ];
    return colors[index % colors.length];
  }
}


/// Enhanced custom painter with robust function plotting (This class remains largely the same)
class GraphPainter extends CustomPainter {
  final List<String> functions;
  final double scale;
  final Offset offset;
  final CalculatorEngine engine;

  GraphPainter({
    required this.functions,
    required this.scale,
    required this.offset,
    required this.engine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final axisPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.5;
    
    final gridPaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 0.5;

    final centerX = size.width / 2 + offset.dx;
    final centerY = size.height / 2 + offset.dy;
    final double unit = 25 * scale;

    _drawAdaptiveGrid(canvas, size, centerX, centerY, unit, gridPaint);
    
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);

    _drawAxisLabels(canvas, size, centerX, centerY, unit);

    for (int funcIndex = 0; funcIndex < functions.length; funcIndex++) {
      final func = functions[funcIndex];
      paint.color = _getColorForFunction(funcIndex);
      
      try {
        _plotFunctionRobust(canvas, size, func, centerX, centerY, unit, paint);
      } catch (e) {
        print('Error plotting function $func: $e');
      }
    }
  }

  // --- All helper methods (_drawAdaptiveGrid, _plotFunctionRobust, etc.) remain the same ---
  // --- They are omitted here for brevity but should be kept in your file. ---

  void _drawAdaptiveGrid(Canvas canvas, Size size, double centerX, double centerY, double unit, Paint gridPaint) {
    double gridSpacing = unit;
    if (unit < 10) {
      gridSpacing = unit * 5;
    } else if (unit > 100) {
      gridSpacing = unit / 2;
    }

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

  void _plotFunctionRobust(Canvas canvas, Size size, String func, double centerX, double centerY, double unit, Paint paint) {
    final path = Path();
    bool hasStarted = false;
    double? lastY;
    
    final double stepSize = math.min(0.1, math.max(0.01, 1.0 / unit));
    final double startX = (-size.width / 2 - offset.dx) / unit;
    final double endX = (size.width / 2 - offset.dx) / unit;

    for (double mathX = startX; mathX <= endX; mathX += stepSize) {
      try {
        double mathY = _evaluateFunctionSafely(func, mathX);
        
        if (!mathY.isFinite) {
          hasStarted = false;
          lastY = null;
          continue;
        }
        
        double screenX = centerX + mathX * unit;
        double screenY = centerY - mathY * unit;
        
        if (screenY < -size.height * 2 || screenY > size.height * 3) {
          hasStarted = false;
          lastY = null;
          continue;
        }
        
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

  double _evaluateFunctionSafely(String func, double x) {
    String processedFunc = func;
    
    processedFunc = processedFunc.replaceAllMapped(RegExp(r'(\d)([a-zA-Z(])'), (m) => '${m[1]}*${m[2]}');
    processedFunc = processedFunc.replaceAllMapped(RegExp(r'(\))([a-zA-Z\d(])'), (m) => '${m[1]}*${m[2]}');
    
    String valueStr = x.toString();
    if (x < 0 || valueStr.contains('e')) {
      valueStr = '($valueStr)';
    }
    
    String expressionWithX = processedFunc.replaceAll('x', valueStr);
    
    String result = engine.evaluate(expressionWithX);
    
    if (result == 'Error' || result.isEmpty) {
      throw Exception('Evaluation failed');
    }
    
    double? value = double.tryParse(result);
    if (value == null) {
      throw Exception('Invalid result: $result');
    }
    
    return value;
  }

  void _drawAxisLabels(Canvas canvas, Size size, double centerX, double centerY, double unit) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final textStyle = TextStyle(color: Colors.grey[300], fontSize: 10);

    // Helper function to find a visually pleasing step value.
    double getNiceStep(double idealStep) {
      if (idealStep <= 0) return 1.0;
      final double powerOf10 = math.pow(10, (math.log(idealStep) / math.ln10).floor()).toDouble();
      final double normalized = idealStep / powerOf10;

      if (normalized < 1.5) return 1.0 * powerOf10;
      if (normalized < 3.5) return 2.0 * powerOf10;
      if (normalized < 7.5) return 5.0 * powerOf10;
      return 10.0 * powerOf10;
    }

    const double pixelsPerLabel = 85.0; // Target spacing between labels
    final double idealStep = pixelsPerLabel / unit;
    final double step = getNiceStep(idealStep);

    // Determine the number of digits to show after the decimal point.
    final int precision = (step < 1) ? (-math.log(step) / math.ln10).ceil() : 0;

    // --- X-axis labels ---
    final double startX = -centerX / unit;
    final double endX = (size.width - centerX) / unit;

    for (double i = (startX / step).floor() * step; i <= endX; i += step) {
      if (i.abs() < step / 100) continue; // Skip label at origin

      final x = centerX + i * unit;
      if (x < 15 || x > size.width - 15) continue;

      textPainter.text = TextSpan(text: i.toStringAsFixed(precision), style: textStyle);
      textPainter.layout();
      
      double labelY = centerY + 8;
      if (labelY > size.height - 20) labelY = centerY - 20;

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, labelY));
    }

    // --- Y-axis labels ---
    final double startY = -(size.height - centerY) / unit;
    final double endY = centerY / unit;

    for (double i = (startY / step).floor() * step; i <= endY; i += step) {
      if (i.abs() < step / 100) continue; // Skip label at origin

      final y = centerY - i * unit;
      if (y < 15 || y > size.height - 15) continue;
      
      textPainter.text = TextSpan(text: i.toStringAsFixed(precision), style: textStyle);
      textPainter.layout();
      
      double labelX = centerX + 8;
      if (labelX > size.width - 30) labelX = centerX - textPainter.width - 8;

      textPainter.paint(canvas, Offset(labelX, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.functions.length != functions.length ||
        oldDelegate.functions.toString() != functions.toString() ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }

  Color _getColorForFunction(int index) {
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.purple,
      Colors.orange, Colors.teal, Colors.pink, Colors.brown,
    ];
    return colors[index % colors.length];
  }
}