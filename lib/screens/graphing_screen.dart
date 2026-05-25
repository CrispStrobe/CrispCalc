// lib/screens/graphing_screen.dart - with LaTeX Input & Keypad

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../controllers/latex_controller.dart';
import '../engine/calculator_engine.dart';
import '../engine/app_state.dart';
import '../localization/app_localizations.dart';
import '../utils/expression_preprocessing_utils.dart';
import '../utils/keyboard_input_handler.dart';
import '../utils/latex_conversion_utils.dart';
import '../screens/curve_analysis_input_screen.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/latex_input_field.dart';

class GraphingScreen extends StatefulWidget {
  const GraphingScreen({super.key});

  @override
  State<GraphingScreen> createState() => GraphingScreenState();
}

class GraphingScreenState extends State<GraphingScreen>
    with SingleTickerProviderStateMixin {
  final AppState _appState = AppState();
  final LatexController _latexController = LatexController();
  final FocusNode _screenFocusNode = FocusNode(); // For keyboard listener
  final CalculatorEngine _engine = CalculatorEngine();
  late final TabController _tabController;

  // FIX: Start with input unfocused. Focus will be given by MainScreen on tab switch.
  bool _isInputFocused = false;
  // The on-screen keypad starts hidden so the plot has the full graph area.
  // It expands when the user taps the input field, or via the toolbar toggle.
  bool _showKeypad = false;

  // Graph view controls
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _focalStart = Offset.zero;

  // When true, the painter overlays root and extremum markers on each curve.
  bool _showAnnotations = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    debugPrint("DEBUG: GraphingScreen initState - Screen initialized.");
    // FIX: Removed focus logic from here to prevent it from running at app startup.
  }

  // FIX: Public method for the parent widget (MainScreen) to call.
  void requestFocus() {
    debugPrint("DEBUG: GraphingScreen - requestFocus() called by parent.");
    if (mounted) {
      setState(() => _isInputFocused = true);
      _screenFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    debugPrint("DEBUG: GraphingScreen disposing.");
    _latexController.dispose();
    _screenFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onButtonPressed(String value) {
    if (!_isInputFocused) {
      debugPrint(
          "DEBUG: Input field not focused. Focusing now via button press.");
      setState(() => _isInputFocused = true);
      _screenFocusNode.requestFocus();
    }

    switch (value) {
      case 'C':
        _latexController.clear();
        break;
      case '⌫':
        _latexController.backspace();
        break;
      case 'EXE':
        _addFunction();
        break;
      case '◀':
        _latexController.moveCursor(-1);
        break;
      case '▶':
        _latexController.moveCursor(1);
        break;
      case '/':
        _latexController.insert(r'\frac{}{}', cursorOffsetFromEnd: -3);
        break;
      case 'sqrt':
        _latexController.insert(r'\sqrt{}', cursorOffsetFromEnd: -1);
        break;
      case '^':
        _latexController.insert(r'^{}', cursorOffsetFromEnd: -1);
        break;
      case 'π':
        _latexController.insert(r'\pi');
        break;
      default:
        _latexController.insert(value);
        break;
    }
  }

  bool _handleKeyboardInput(KeyEvent event) {
    debugPrint(
        "DEBUG: GraphingScreen _handleKeyboardInput | isFocused: $_isInputFocused");
    if (!_isInputFocused) {
      debugPrint("DEBUG: Input not focused, ignoring key event.");
      return false;
    }

    return KeyboardInputHandler.handleKeyboardInput(
      event,
      (text) => _onButtonPressed(text),
      () => _onButtonPressed('⌫'),
      () => _onButtonPressed('C'),
      () => _addFunction(),
      (amount) => _onButtonPressed(amount > 0 ? '▶' : '◀'),
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
            Text(
              AppLocalizations.of(context).selectFunctionToAnalyze,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...activeFunctionIndices.map((index) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getColorForFunction(index).withValues(alpha: 0.2),
                    child: Text(
                      'Y${index + 1}',
                      style: TextStyle(
                        color: _getColorForFunction(index),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Y${index + 1}(x)'),
                  subtitle: Text(_appState.graphFunctions[index],
                      maxLines: 1, overflow: TextOverflow.ellipsis),
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
          builder: (context) =>
              CurveAnalysisInputScreen(initialFunction: function),
        ),
      );
    }
  }

  void _addFunction() {
    final t = AppLocalizations.of(context);
    final latexInput = _latexController.text.trim();
    final textToAdd = LatexConversionUtils.fromLatex(latexInput);

    if (textToAdd.isEmpty) return;

    // Reject obviously-malformed input before it lands in a graph
    // slot. The plot painter would otherwise silently render
    // nothing for an unparseable expression like `tan(x` or
    // `1/(x-` and the user gets no feedback. This is a cheap
    // syntactic gate; expressions that parse but evaluate to NaN
    // at every sample point still slip through (e.g.
    // `sqrt(-x^2 - 1)`) — that case is handled by the plot
    // painter's empty-curve render.
    final validationError = _validateGraphInput(textToAdd, t);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final emptySlotIndex =
        _appState.graphFunctions.indexWhere((f) => f.isEmpty);
    if (emptySlotIndex != -1) {
      _appState.updateFunction(emptySlotIndex, textToAdd);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.functionAdded(emptySlotIndex + 1)),
          duration: const Duration(seconds: 2),
        ),
      );
      _latexController.clear();
      setState(() => _isInputFocused = true);
      _screenFocusNode.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.allSlotsFull),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Cheap syntactic validation for a graph-function string. Returns
  /// a localized error message when the input is obviously broken
  /// (unbalanced parens / brackets / braces, leftover binary
  /// operators), or `null` if the input looks well-formed enough
  /// to attempt plotting. Cosmetic prefix `y=` is allowed.
  String? _validateGraphInput(String input, AppLocalizations t) {
    var src = input.trim();
    if (src.toLowerCase().startsWith('y=')) {
      src = src.substring(2).trim();
    } else if (src.toLowerCase().startsWith('y =')) {
      src = src.substring(3).trim();
    }
    if (src.isEmpty) return t.graphErrorEmpty;

    // Paren / bracket / brace balance.
    var parens = 0, brackets = 0, braces = 0;
    for (var i = 0; i < src.length; i++) {
      final ch = src[i];
      if (ch == '(') parens++;
      if (ch == ')') parens--;
      if (ch == '[') brackets++;
      if (ch == ']') brackets--;
      if (ch == '{') braces++;
      if (ch == '}') braces--;
      if (parens < 0 || brackets < 0 || braces < 0) {
        return t.graphErrorUnbalanced;
      }
    }
    if (parens != 0 || brackets != 0 || braces != 0) {
      return t.graphErrorUnbalanced;
    }

    // Trailing binary operator (`x +`, `x -`, `x *`, `x /`, `x ^`).
    final lastTok = src.replaceAll(RegExp(r'\s+$'), '');
    if (lastTok.isNotEmpty &&
        '+-*/^'.contains(lastTok[lastTok.length - 1])) {
      return t.graphErrorTrailingOperator;
    }

    return null;
  }

  void _removeFunction(String functionToRemove) {
    final t = AppLocalizations.of(context);
    final index = _appState.graphFunctions.indexOf(functionToRemove);
    if (index != -1) {
      _appState.clearFunction(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.functionRemoved(index + 1)),
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

  void _zoomIn() {
    setState(() {
      _scale = (_scale * 1.4).clamp(0.1, 20.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale / 1.4).clamp(0.1, 20.0);
    });
  }

  void _clearAllFunctions() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.clearAllFunctions),
        content: Text(t.clearAllFunctionsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              for (int i = 0; i < _appState.graphFunctions.length; i++) {
                _appState.clearFunction(i);
              }
              Navigator.of(context).pop();
            },
            child: Text(t.clearAll),
          ),
        ],
      ),
    );
  }

  Color _getColorForFunction(int index) {
    const colors = [
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

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _screenFocusNode,
      // autofocus off — let MainScreen drive focus explicitly so we don't have
      // multiple panes fighting for primary focus on the wide-screen layout.
      onKeyEvent: _handleKeyboardInput,
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
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)
                  .graphingTitle(activeFunctions.length)),
              actions: [
                IconButton(
                  onPressed: _zoomOut,
                  icon: const Icon(Icons.zoom_out),
                  tooltip: AppLocalizations.of(context).zoomOut,
                ),
                IconButton(
                  onPressed: _zoomIn,
                  icon: const Icon(Icons.zoom_in),
                  tooltip: AppLocalizations.of(context).zoomIn,
                ),
                IconButton(
                  onPressed: _resetView,
                  icon: const Icon(Icons.center_focus_strong),
                  tooltip: AppLocalizations.of(context).resetView,
                ),
                if (activeFunctions.isNotEmpty)
                  IconButton(
                    onPressed: _showAnalysisOptions,
                    icon: const Icon(Icons.analytics),
                    tooltip: AppLocalizations.of(context).analyzeFunctions,
                  ),
                if (activeFunctions.isNotEmpty)
                  IconButton(
                    onPressed: () =>
                        setState(() => _showAnnotations = !_showAnnotations),
                    icon: Icon(_showAnnotations
                        ? Icons.bubble_chart
                        : Icons.bubble_chart_outlined),
                    tooltip: _showAnnotations
                        ? AppLocalizations.of(context).hideAnnotations
                        : AppLocalizations.of(context).showAnnotations,
                  ),
                IconButton(
                  onPressed: () {
                    setState(() => _showKeypad = !_showKeypad);
                  },
                  icon: Icon(_showKeypad
                      ? Icons.keyboard_hide_outlined
                      : Icons.keyboard_outlined),
                  tooltip: _showKeypad
                      ? AppLocalizations.of(context).hideKeypad
                      : AppLocalizations.of(context).showKeypad,
                ),
                if (activeFunctions.isNotEmpty)
                  IconButton(
                    onPressed: _clearAllFunctions,
                    icon: const Icon(Icons.clear_all),
                    tooltip: AppLocalizations.of(context).clearAllFunctions,
                  ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // --- Graph display area ---
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () {
                        debugPrint(
                            "DEBUG: Graph area tapped. Unfocusing input field.");
                        setState(() => _isInputFocused = false);
                        _screenFocusNode.unfocus();
                      },
                      onScaleStart: (details) {
                        _focalStart = details.localFocalPoint;
                        _startScale = _scale;
                        _startOffset = _offset;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale =
                              (_startScale * details.scale).clamp(0.1, 20.0);
                          _offset = _startOffset +
                              (details.localFocalPoint - _focalStart);
                        });
                      },
                      // FIX: Wrap the CustomPaint with ClipRect to prevent drawing out of bounds.
                      child: ClipRect(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade800, width: 1),
                          ),
                          child: CustomPaint(
                            painter: GraphPainter(
                              functions: activeFunctions,
                              functionIndices: activeFunctionIndices,
                              scale: _scale,
                              offset: _offset,
                              engine: _engine,
                              getColorForFunction: _getColorForFunction,
                              showAnnotations: _showAnnotations,
                              parameters: {
                                for (final i in activeFunctionIndices)
                                  if (_appState.functionParameters[i] != null &&
                                      _appState
                                          .functionParameters[i]!.isNotEmpty)
                                    i: Map<String, double>.from(
                                        _appState.functionParameters[i]!),
                              },
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- CONTROLS AREA ---
                  const Divider(height: 1),
                  _buildActiveFunctionsList(
                      activeFunctionIndices, activeFunctions),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              debugPrint(
                                  "DEBUG: Input field tapped. Focusing for keyboard input.");
                              setState(() {
                                _isInputFocused = true;
                                _showKeypad = true;
                              });
                              _screenFocusNode.requestFocus();
                            },
                            child: Container(
                              height: 50,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _isInputFocused
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade700,
                                  width: _isInputFocused ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                children: [
                                  const Text("y = ",
                                      style: TextStyle(fontSize: 18)),
                                  Expanded(
                                      child: LatexInputField(
                                          controller: _latexController)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_chart),
                          label: Text(AppLocalizations.of(context).plotButton),
                          onPressed: _addFunction,
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _showKeypad,
                    child: Expanded(
                      // Smaller flex than the plot so graphed functions still
                      // dominate vertically when the keypad is open.
                      flex: 2,
                      child: CalculatorKeypad(
                        tabController: _tabController,
                        onButtonPressed: _onButtonPressed,
                        localizations: AppLocalizations.of(context),
                        appState: _appState,
                        onVariableTap: (name) => _latexController.insert(name),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveFunctionsList(
      List<int> activeFunctionIndices, List<String> activeFunctions) {
    if (activeFunctions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppLocalizations.of(context).enterFunctionPrompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      );
    }

    // Detect parameters per function. Empty list means no sliders for
    // that function — chip-only rendering keeps the layout compact.
    final paramsPerSlot = <int, List<String>>{};
    for (var i = 0; i < activeFunctionIndices.length; i++) {
      final params = ExpressionPreprocessingUtils.detectParameters(
          activeFunctions[i], 'x');
      paramsPerSlot[activeFunctionIndices[i]] = params;
      // Drop stale slider state.
      _appState.pruneParameters(activeFunctionIndices[i], params.toSet());
    }

    final anyParams = paramsPerSlot.values.any((p) => p.isNotEmpty);
    final maxHeight = anyParams ? 130.0 : 50.0;

    return SizedBox(
      height: maxHeight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: activeFunctionIndices.length,
        itemBuilder: (context, index) {
          final funcText = activeFunctions[index];
          final originalIndex = activeFunctionIndices[index];
          final yLabel = 'Y${originalIndex + 1}';
          final color = _getColorForFunction(originalIndex);
          final params = paramsPerSlot[originalIndex] ?? const <String>[];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  avatar: CircleAvatar(backgroundColor: color, radius: 8),
                  label: SizedBox(
                    width: 140,
                    child: Text(
                      '$yLabel = $funcText',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                  side: BorderSide(color: color, width: 1),
                  onDeleted: () => _removeFunction(funcText),
                  deleteIcon: const Icon(Icons.close, size: 16),
                ),
                if (params.isNotEmpty)
                  SizedBox(
                    width: 180,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final p in params)
                          _ParameterSlider(
                            name: p,
                            value: _appState.getParameter(originalIndex, p),
                            color: color,
                            onChanged: (v) =>
                                _appState.setParameter(originalIndex, p, v),
                          ),
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

class GraphPainter extends CustomPainter {
  final List<String> functions;
  final List<int> functionIndices;
  final double scale;
  final Offset offset;
  final CalculatorEngine engine;
  final Color Function(int) getColorForFunction;
  final bool showAnnotations;

  /// Per-function parameter values, keyed by the *original* function
  /// slot index (the same indices that live in `functionIndices`).
  /// Empty when no function has any parameters. Substituted in
  /// before `x` when evaluating, so `a*sin(b*x)` plots correctly.
  final Map<int, Map<String, double>> parameters;

  GraphPainter({
    required this.functions,
    required this.functionIndices,
    required this.scale,
    required this.offset,
    required this.engine,
    required this.getColorForFunction,
    this.showAnnotations = false,
    this.parameters = const {},
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
      final color = getColorForFunction(originalIndex);
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Pre-substitute parameter values so neither _plotFunction nor
      // _drawAnnotations needs to know about parameter storage. Each
      // identifier-as-whole-word is replaced with its current value
      // wrapped in parens (so 2x with parameter `x` doesn't become 21).
      final substituted = _withParameters(func, originalIndex);

      try {
        _plotFunction(canvas, size, substituted, centerX, centerY, unit, paint);
        if (showAnnotations) {
          _drawAnnotations(
              canvas, size, substituted, centerX, centerY, unit, color);
        }
      } catch (e) {
        debugPrint('Error plotting function $func: $e');
      }
    }
  }

  /// Substitute every parameter in [func] for slot [slot] with its
  /// current numeric value. Returns the original string when this slot
  /// has no parameters.
  String _withParameters(String func, int slot) {
    final params = parameters[slot];
    if (params == null || params.isEmpty) return func;
    return ExpressionPreprocessingUtils.substituteParameters(func, params);
  }

  void _drawGrid(
      Canvas canvas, Size size, double centerX, double centerY, double unit) {
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
    canvas.drawLine(
        Offset(centerX, 0), Offset(centerX, size.height), axisPaint);
  }

  void _drawAxisLabels(
      Canvas canvas, Size size, double centerX, double centerY, double unit) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final textStyle = TextStyle(color: Colors.grey.shade300, fontSize: 10);

    double getNiceStep(double idealStep) {
      if (idealStep <= 0) return 1.0;
      final double powerOf10 =
          math.pow(10, (math.log(idealStep) / math.ln10).floor()).toDouble();
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

      textPainter.text =
          TextSpan(text: i.toStringAsFixed(precision), style: textStyle);
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

      textPainter.text =
          TextSpan(text: i.toStringAsFixed(precision), style: textStyle);
      textPainter.layout();

      double labelX = centerX + 8;
      if (labelX > size.width - 30) labelX = centerX - textPainter.width - 8;

      textPainter.paint(canvas, Offset(labelX, y - textPainter.height / 2));
    }
  }

  void _plotFunction(Canvas canvas, Size size, String func, double centerX,
      double centerY, double unit, Paint paint) {
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
    processedFunc = processedFunc.replaceAllMapped(
        RegExp(r'(\d)([a-zA-Z(])'), (m) => '${m[1]}*${m[2]}');
    processedFunc = processedFunc.replaceAllMapped(
        RegExp(r'(\))([a-zA-Z\d(])'), (m) => '${m[1]}*${m[2]}');

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

  void _drawAnnotations(Canvas canvas, Size size, String func, double centerX,
      double centerY, double unit, Color color) {
    // Numerical scan across the visible x-range, detecting sign changes in
    // f(x) (roots) and in a finite-difference f'(x) (extrema). Roots refined
    // by bisection; extrema by parabolic interpolation of the three samples
    // bracketing the derivative sign change. All numerical — no SymEngine
    // roundtrip per point.

    final double startX = (-size.width / 2 - offset.dx) / unit;
    final double endX = (size.width / 2 - offset.dx) / unit;
    final double span = endX - startX;
    if (span <= 0) return;

    // ~200 scan steps across the visible width is plenty for picking up
    // every reasonable root/extremum and stays well under the per-point
    // budget of the plot loop.
    const int scanSteps = 200;
    final double dx = span / scanSteps;

    final samples = <double, double>{};
    double? safeEval(double x) {
      final cached = samples[x];
      if (cached != null) return cached.isFinite ? cached : null;
      try {
        final y = _evaluateFunction(func, x);
        samples[x] = y;
        return y.isFinite ? y : null;
      } catch (_) {
        samples[x] = double.nan;
        return null;
      }
    }

    final roots = <double>[];
    final extrema = <_Extremum>[];

    // Step 1: roots via sign change in f, refined by bisection.
    double? prevX;
    double? prevY;
    for (int i = 0; i <= scanSteps; i++) {
      final x = startX + i * dx;
      final y = safeEval(x);
      if (y == null) {
        prevX = null;
        prevY = null;
        continue;
      }
      if (prevX != null && prevY != null) {
        if (prevY.sign != y.sign && (y - prevY).abs() < 50 / scale) {
          // Sign change without a huge jump — likely a real root, not a
          // discontinuity. Refine.
          final root = _bisectRoot(func, prevX, x);
          if (root != null) {
            roots.add(root);
          }
        }
      }
      prevX = x;
      prevY = y;
    }

    // Step 2: extrema via sign change in central-difference derivative.
    final double h = dx; // step for central difference matches scan
    double? prevDeriv;
    double? prevXForDeriv;
    for (int i = 1; i < scanSteps; i++) {
      final x = startX + i * dx;
      final left = safeEval(x - h);
      final right = safeEval(x + h);
      final mid = safeEval(x);
      if (left == null || right == null || mid == null) {
        prevDeriv = null;
        prevXForDeriv = null;
        continue;
      }
      final deriv = (right - left) / (2 * h);
      if (prevDeriv != null && prevXForDeriv != null) {
        if (prevDeriv.sign != deriv.sign &&
            (deriv - prevDeriv).abs() < 50 / scale) {
          // Refine by parabolic interpolation through the three derivative
          // samples bracketing the sign change. Falls back to the midpoint.
          final ext = _refineExtremum(func, prevXForDeriv, x);
          if (ext != null) extrema.add(ext);
        }
      }
      prevDeriv = deriv;
      prevXForDeriv = x;
    }

    // Step 3: draw markers + labels.
    final fillPaint = Paint()..color = color;
    final outlinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    void drawMarker(double mx, double my, String label) {
      final sx = centerX + mx * unit;
      final sy = centerY - my * unit;
      if (sx < 0 || sx > size.width || sy < 0 || sy > size.height) return;

      canvas.drawCircle(Offset(sx, sy), 5, fillPaint);
      canvas.drawCircle(Offset(sx, sy), 5, outlinePaint);

      tp.text = TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          backgroundColor: Colors.black.withValues(alpha: 0.55),
        ),
      );
      tp.layout();
      // Position label above-right of the marker, with a small offset; flip
      // if it would clip the canvas edge.
      double lx = sx + 8;
      double ly = sy - tp.height - 8;
      if (lx + tp.width > size.width - 4) lx = sx - tp.width - 8;
      if (ly < 4) ly = sy + 8;
      tp.paint(canvas, Offset(lx, ly));
    }

    for (final r in roots) {
      drawMarker(r, 0, '(${_fmt(r)}, 0)');
    }
    for (final e in extrema) {
      drawMarker(e.x, e.y, '${e.kind} (${_fmt(e.x)}, ${_fmt(e.y)})');
    }
  }

  /// Bisect for f(a) and f(b) of opposite sign. Returns null if either
  /// endpoint can't be evaluated. Up to 40 iterations, stops when the
  /// interval is below 1/100th of a screen pixel.
  double? _bisectRoot(String func, double a, double b) {
    double? evalSafe(double x) {
      try {
        final y = _evaluateFunction(func, x);
        return y.isFinite ? y : null;
      } catch (_) {
        return null;
      }
    }

    final faInit = evalSafe(a);
    final fbInit = evalSafe(b);
    if (faInit == null || fbInit == null) return null;
    if (faInit == 0) return a;
    if (fbInit == 0) return b;
    if (faInit.sign == fbInit.sign) return null;

    double lo = a, hi = b;
    double fa = faInit;
    for (int i = 0; i < 40; i++) {
      final mid = (lo + hi) / 2;
      final fm = evalSafe(mid);
      if (fm == null) return null;
      if (fm == 0) return mid;
      if (fm.sign == fa.sign) {
        lo = mid;
        fa = fm;
      } else {
        hi = mid;
      }
      if ((hi - lo).abs() < 0.01 / (25 * scale)) break;
    }
    return (lo + hi) / 2;
  }

  /// Parabolic refinement of an extremum bracketed by [a, b]. Samples three
  /// equally-spaced points and fits a parabola; returns the vertex if it
  /// lies in (a, b), else the better of the bracket midpoints. Classifies
  /// max vs min by the sign of the second derivative.
  _Extremum? _refineExtremum(String func, double a, double b) {
    double? evalSafe(double x) {
      try {
        final y = _evaluateFunction(func, x);
        return y.isFinite ? y : null;
      } catch (_) {
        return null;
      }
    }

    final mid = (a + b) / 2;
    final ya = evalSafe(a);
    final ym = evalSafe(mid);
    final yb = evalSafe(b);
    if (ya == null || ym == null || yb == null) return null;

    double bestX = mid;
    final denom = (ya - 2 * ym + yb);
    if (denom.abs() > 1e-12) {
      final shift = 0.5 * (ya - yb) / denom;
      final candidate = mid + shift * (b - a) / 2;
      if (candidate > a && candidate < b) bestX = candidate;
    }
    final bestY = evalSafe(bestX);
    if (bestY == null) return null;

    // Classify by second derivative sign (concave up = min, down = max).
    final kind = denom > 0 ? 'min' : 'max';
    return _Extremum(bestX, bestY, kind);
  }

  String _fmt(double v) {
    if (v.abs() < 1e-9) return '0';
    final abs = v.abs();
    if (abs >= 1000 || abs < 0.01) return v.toStringAsExponential(2);
    return v.toStringAsFixed(abs >= 10 ? 1 : (abs >= 1 ? 2 : 3));
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.functions.length != functions.length ||
        oldDelegate.functions.toString() != functions.toString() ||
        oldDelegate.functionIndices.toString() != functionIndices.toString() ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.showAnnotations != showAnnotations ||
        oldDelegate.parameters.toString() != parameters.toString();
  }
}

class _Extremum {
  final double x;
  final double y;
  final String kind; // 'min' or 'max'
  const _Extremum(this.x, this.y, this.kind);
}

/// Compact one-line slider for a single function parameter. Range is
/// fixed at [-10, 10] for V1 — wide enough for typical textbook
/// parameters, narrow enough to feel responsive. The current value is
/// shown inline next to the name; tapping the value would open a
/// numeric input (deferred).
class _ParameterSlider extends StatelessWidget {
  final String name;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _ParameterSlider({
    required this.name,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: color,
              thumbColor: color,
            ),
            child: Slider(
              value: value.clamp(-10.0, 10.0),
              min: -10,
              max: 10,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
