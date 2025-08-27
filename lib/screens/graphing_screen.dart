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
  List<String> _functions = ['x^2', 'sin(x)'];
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _panStart;

  final TextEditingController _functionController = TextEditingController();
  final CalculatorEngine _engine = CalculatorEngine();

  void _addFunction() {
    if (_functionController.text.isNotEmpty) {
      setState(() {
        _functions.add(_functionController.text);
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
      appBar: AppBar(title: const Text('Graphing')),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetView,
        mini: true,
        child: const Icon(Icons.center_focus_strong),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onScaleStart: (details) {
                _panStart = details.localFocalPoint - _offset;
              },
              onScaleUpdate: (details) {
                setState(() {
                  _offset = details.localFocalPoint - _panStart!;
                  // Clamp scale to prevent zooming too far in or out
                  _scale = details.scale.clamp(0.2, 5.0);
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
          // UI for adding and viewing functions
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                          hintText: 'e.g., x^2, sin(x), x^3-2*x',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_chart),
                      onPressed: _addFunction,
                      tooltip: 'Add Function',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // List of current functions
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _functions.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_functions[index]),
                          backgroundColor: _getColorForFunction(index).withOpacity(0.3),
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
    final colors = [Colors.cyan, Colors.yellow, Colors.pinkAccent, Colors.green];
    return colors[index % colors.length];
  }
}

/// A custom painter that draws the graph axes and function plots on a canvas.
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
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final axisPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 0.5;

    final centerX = size.width / 2 + offset.dx;
    final centerY = size.height / 2 + offset.dy;

    // Scale factor for mathematical coordinates
    final double unit = (size.width / 20) * scale; // Show about ±10 units by default

    // Draw grid lines
    final int gridSpacing = 1;
    for (int i = -20; i <= 20; i++) {
      if (i != 0) {
        // Vertical grid lines
        final x = centerX + i * unit;
        if (x >= 0 && x <= size.width) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        }
        
        // Horizontal grid lines
        final y = centerY + i * unit;
        if (y >= 0 && y <= size.height) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
        }
      }
    }

    // Draw main axes
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);

    // Draw axis labels
    _drawAxisLabels(canvas, size, centerX, centerY, unit);

    // Plot each function
    for (int funcIndex = 0; funcIndex < functions.length; funcIndex++) {
      final func = functions[funcIndex];
      paint.color = _getColorForFunction(funcIndex);
      
      final path = Path();
      bool hasMoved = false;

      // Sample points for plotting
      for (double pixelX = 0; pixelX <= size.width; pixelX += 2) {
        double mathX = (pixelX - centerX) / unit;
        
        try {
          // Replace x with actual value and evaluate
          String expressionWithX = func.replaceAll('x', '($mathX)');
          double mathY = double.parse(engine.evaluate(expressionWithX));
          
          // Convert back to screen coordinates
          double pixelY = centerY - mathY * unit;

          // Only draw if within reasonable bounds
          if (mathY.isFinite && pixelY > -size.height && pixelY < size.height * 2) {
            if (!hasMoved) {
              path.moveTo(pixelX, pixelY);
              hasMoved = true;
            } else {
              path.lineTo(pixelX, pixelY);
            }
          } else {
            hasMoved = false; // Break the line for discontinuities
          }
        } catch (e) {
          hasMoved = false; // Break the line on evaluation errors
        }
      }
      
      canvas.drawPath(path, paint);
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size, double centerX, double centerY, double unit) {
    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Draw x-axis labels
    for (int i = -10; i <= 10; i++) {
      if (i == 0) continue; // Skip origin
      
      final x = centerX + i * unit;
      if (x >= 20 && x <= size.width - 20) {
        textPaint.text = TextSpan(
          text: i.toString(),
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        );
        textPaint.layout();
        textPaint.paint(canvas, Offset(x - textPaint.width / 2, centerY + 5));
      }
    }
    
    // Draw y-axis labels  
    for (int i = -10; i <= 10; i++) {
      if (i == 0) continue; // Skip origin
      
      final y = centerY - i * unit;
      if (y >= 20 && y <= size.height - 20) {
        textPaint.text = TextSpan(
          text: i.toString(),
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        );
        textPaint.layout();
        textPaint.paint(canvas, Offset(centerX + 5, y - textPaint.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.functions != functions ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }

  Color _getColorForFunction(int index) {
    final colors = [Colors.cyan, Colors.yellow, Colors.pinkAccent, Colors.green];
    return colors[index % colors.length];
  }
}