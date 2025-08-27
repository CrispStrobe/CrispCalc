/// lib/screens/graphing_screen.dart:

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../engine/calculator_engine.dart';

/// A screen for plotting and interacting with 2D function graphs.
class GraphingScreen extends StatefulWidget {
  const GraphingScreen({super.key});

  @override
  State<GraphingScreen> createState() => _GraphingScreenState();
}

class _GraphingScreenState extends State<GraphingScreen> {
  final List<String> _functions = ['sin(x)'];
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  
  // For smooth panning and zooming
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _focalStart = Offset.zero;

  final TextEditingController _functionController = TextEditingController();
  final CalculatorEngine _engine = CalculatorEngine();

  void _addFunction() {
    if (_functionController.text.isNotEmpty) {
      setState(() {
        _functions.add(_functionController.text.trim());
        _functionController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  void _removeFunction(int index) {
    setState(() {
      _functions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphing'),
        actions: [
          IconButton(
            onPressed: _resetView,
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Reset View',
          ),
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
                painter: GraphPainter(
                  functions: _functions,
                  scale: _scale,
                  offset: _offset,
                  engine: _engine,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          // Enhanced UI for adding and viewing functions
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _functionController,
                        decoration: const InputDecoration(
                          labelText: 'Enter a function of x',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., x^2, 2*sin(x), x^3-2*x+1',
                          prefixText: 'y = ',
                        ),
                        onSubmitted: (_) => _addFunction(),
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
                // Enhanced function list with better styling
                if (_functions.isNotEmpty)
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _functions.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              'y = ${_functions[index]}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: _getColorForFunction(index).withOpacity(0.2),
                            side: BorderSide(
                              color: _getColorForFunction(index),
                              width: 1.5,
                            ),
                            onDeleted: () => _removeFunction(index),
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

/// Enhanced custom painter with robust function plotting
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

    // Draw grid with adaptive spacing
    _drawAdaptiveGrid(canvas, size, centerX, centerY, unit, gridPaint);
    
    // Draw main axes
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);

    // Draw axis labels with intelligent spacing
    _drawAxisLabels(canvas, size, centerX, centerY, unit);

    // Plot each function with enhanced error handling
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

  void _drawAdaptiveGrid(Canvas canvas, Size size, double centerX, double centerY, double unit, Paint gridPaint) {
    // Adaptive grid spacing based on zoom level
    double gridSpacing = unit;
    if (unit < 10) {
      gridSpacing = unit * 5;
    } else if (unit > 100) {
      gridSpacing = unit / 2;
    }

    // Vertical grid lines
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

    // Horizontal grid lines
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
    
    // Much finer sampling for smooth curves - especially important for trig functions
    final double stepSize = math.min(0.1, math.max(0.01, 1.0 / unit));
    final double startX = (-size.width / 2 - offset.dx) / unit;
    final double endX = (size.width / 2 - offset.dx) / unit;

    for (double mathX = startX; mathX <= endX; mathX += stepSize) {
      try {
        double mathY = _evaluateFunctionSafely(func, mathX);
        
        // Skip if result is not finite
        if (!mathY.isFinite) {
          hasStarted = false;
          lastY = null;
          continue;
        }
        
        // Convert to screen coordinates
        double screenX = centerX + mathX * unit;
        double screenY = centerY - mathY * unit;
        
        // Skip points far outside screen bounds
        if (screenY < -size.height * 2 || screenY > size.height * 3) {
          hasStarted = false;
          lastY = null;
          continue;
        }
        
        // Check for discontinuities (large jumps in y value)
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
        // Skip this point and break the line
        hasStarted = false;
        lastY = null;
      }
    }
    
    canvas.drawPath(path, paint);
  }

  double _evaluateFunctionSafely(String func, double x) {
    // Pre-process function to handle implicit multiplication
    String processedFunc = func;
    
    // Handle patterns like "2x", "3sin(x)", etc.
    processedFunc = processedFunc.replaceAllMapped(RegExp(r'(\d)([a-zA-Z(])'), (m) => '${m[1]}*${m[2]}');
    processedFunc = processedFunc.replaceAllMapped(RegExp(r'(\))([a-zA-Z\d(])'), (m) => '${m[1]}*${m[2]}');
    
    // Replace x with the value, using parentheses for safety
    String valueStr = x.toString();
    if (x < 0 || valueStr.contains('e')) {
      valueStr = '($valueStr)';
    }
    
    String expressionWithX = processedFunc.replaceAll('x', valueStr);
    
    // Use the robust calculator engine
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
    
    // Intelligent label spacing based on zoom
    int step = math.max(1, (50 / unit).ceil());
    
    // X-axis labels
    for (int i = -100; i <= 100; i += step) {
      if (i == 0) continue;
      final x = centerX + i * unit;
      if (x < 30 || x > size.width - 30) continue;
      
      textPainter.text = TextSpan(text: i.toString(), style: textStyle);
      textPainter.layout();
      
      double labelY = centerY + 15;
      if (labelY > size.height - 20) labelY = centerY - 25;
      
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, labelY));
    }
    
    // Y-axis labels
    for (int i = -100; i <= 100; i += step) {
      if (i == 0) continue;
      final y = centerY - i * unit;
      if (y < 30 || y > size.height - 30) continue;
      
      textPainter.text = TextSpan(text: i.toString(), style: textStyle);
      textPainter.layout();
      
      double labelX = centerX + 15;
      if (labelX > size.width - 50) labelX = centerX - textPainter.width - 15;
      
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