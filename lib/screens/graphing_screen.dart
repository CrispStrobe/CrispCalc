/// lib/screens/graphing_screen.dart:

import 'package:flutter/material.dart';
import '../engine/calculator_engine.dart';

/// A screen for plotting and interacting with 2D function graphs.
class GraphingScreen extends StatefulWidget {
  const GraphingScreen({super.key});

  @override
  State<GraphingScreen> createState() => _GraphingScreenState();
}

class _GraphingScreenState extends State<GraphingScreen> {
  List<String> _functions = ['x^2 - 2', 'sin(x)'];
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
                  // A clamp to prevent zooming too far in or out.
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
                child: Container(),
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
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_chart),
                      onPressed: _addFunction,
                      tooltip: 'Add Function',
                    ),
                  ],
                ),
                // TODO: Add a list of current functions with options to hide or delete.
              ],
            ),
          ),
        ],
      ),
    );
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

    // A factor to scale the math coordinates.
    final double unit = size.width / (10 * scale);

    // Draw grid lines
    for (int i = 1; i < 10; i++) {
       canvas.drawLine(Offset(centerX + i * unit, 0), Offset(centerX + i * unit, size.height), gridPaint);
       canvas.drawLine(Offset(centerX - i * unit, 0), Offset(centerX - i * unit, size.height), gridPaint);
       canvas.drawLine(Offset(0, centerY + i * unit), Offset(size.width, centerY + i * unit), gridPaint);
       canvas.drawLine(Offset(0, centerY - i * unit), Offset(size.width, centerY - i * unit), gridPaint);
    }

    // Draw main axes
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);

    // Plot each function
    for (final func in functions) {
      final path = Path();
      paint.color = _getColorForFunction(functions.indexOf(func));
      bool hasMoved = false;

      for (double pixelX = 0; pixelX < size.width; pixelX++) {
        double mathX = (pixelX - centerX) / unit;
        
        try {
          String expressionWithX = func.replaceAll('x', '($mathX)');
          double mathY = double.parse(engine.evaluate(expressionWithX));
          double pixelY = centerY - mathY * unit;

          if (!hasMoved) {
            path.moveTo(pixelX, pixelY);
            hasMoved = true;
          } else if (pixelY.isFinite && pixelY > -size.height && pixelY < size.height * 2) {
             path.lineTo(pixelX, pixelY);
          } else {
             hasMoved = false;
          }
        } catch (e) {
          hasMoved = false;
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.functions != functions ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }

  Color _getColorForFunction(int index) {
    final colors = [Colors.cyan, Colors.yellow[600]!, Colors.pinkAccent];
    return colors[index % colors.length];
  }
}