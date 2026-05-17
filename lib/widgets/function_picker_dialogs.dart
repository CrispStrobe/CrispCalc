// lib/widgets/function_picker_dialogs.dart
// Dialogs for selecting and managing functions - Complete Fixed Version

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'dart:async';
import '../engine/app_state.dart';
import '../utils/keyboard_input_handler.dart';
import '../controllers/latex_controller.dart';
import '../utils/math_display_utils.dart';

class FunctionPickerDialogs {
  static void showSolveFunctionPicker(
    BuildContext context,
    AppState appState,
    Function(String) onInsert,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select equation or continue typing:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.keyboard_return),
                title: const Text('Continue Typing'),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: appState.graphFunctions
                      .asMap()
                      .entries
                      .where((e) => e.value.isNotEmpty)
                      .map((e) => ListTile(
                            title: Text('Solve Y${e.key + 1} = 0'),
                            subtitle: Text('where Y${e.key + 1} = ${e.value}'),
                            onTap: () {
                              Navigator.of(context).pop();
                              final textToInsert = 'Y${e.key + 1}=0, x';
                              onInsert(textToInsert);
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showFunctionPicker(
    BuildContext context,
    AppState appState,
    Function(String) onInsert,
  ) {
    final List<Widget> options = appState.graphFunctions
        .asMap()
        .entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) {
      int index = entry.key;
      String func = entry.value;
      return ListTile(
        title: Text('Y${index + 1} = $func'),
        onTap: () {
          Navigator.of(context).pop();
          onInsert('Y${index + 1}()');
        },
      );
    }).toList();

    _showPicker(
      context: context,
      title: 'Select function or continue typing:',
      options: options,
    );
  }

  static void _showPicker({
    required BuildContext context,
    required String title,
    required List<Widget> options,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              ListTile(
                leading: const Icon(Icons.keyboard_return),
                title: const Text('Continue Typing'),
                subtitle: const Text('Dismiss this panel'),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Divider(),
              Flexible(child: ListView(shrinkWrap: true, children: options)),
            ],
          ),
        );
      },
    );
  }

  static Future<String?> showIntegralDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => IntegralDialog(),
    );
  }

  static Future<String?> showNthRootDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => NthRootDialog(),
    );
  }

  static Future<String?> showLimitDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => LimitDialog(),
    );
  }
}

/// A simple LaTeX input field for dialogs that only shows cursor when focused
/// THIS IS THE DialogLatexField CLASS - INTEGRATED HERE
class DialogLatexField extends StatefulWidget {
  final LatexController controller;
  final String label;
  final bool isFocused;
  final VoidCallback onTap;

  const DialogLatexField({
    super.key,
    required this.controller,
    required this.label,
    required this.isFocused,
    required this.onTap,
  });

  @override
  State<DialogLatexField> createState() => _DialogLatexFieldState();
}

class _DialogLatexFieldState extends State<DialogLatexField>
    with SingleTickerProviderStateMixin {
  Timer? _cursorTimer;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    if (widget.isFocused) {
      _startCursorTimer();
    }
  }

  @override
  void didUpdateWidget(DialogLatexField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start/stop cursor timer based on focus
    if (widget.isFocused != oldWidget.isFocused) {
      if (widget.isFocused) {
        _startCursorTimer();
      } else {
        _stopCursorTimer();
        setState(() => _showCursor = false);
      }
    }
  }

  void _startCursorTimer() {
    _cursorTimer?.cancel();
    setState(() => _showCursor = true);
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && widget.isFocused) {
        setState(() => _showCursor = !_showCursor);
      }
    });
  }

  void _stopCursorTimer() {
    _cursorTimer?.cancel();
    _cursorTimer = null;
  }

  @override
  void dispose() {
    _stopCursorTimer();
    super.dispose();
  }

  /// Converts a plain text string to LaTeX string for rendering.
  String _toLatex(String text) {
    return MathDisplayUtils.toHistoryDisplayLatex(text);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isFocused
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            width: widget.isFocused ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                color: widget.isFocused
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 40,
              width: double.infinity,
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LaTeX content (only show cursor if this field is focused)
                    ListenableBuilder(
                      listenable: widget.controller,
                      builder: (context, child) {
                        final text = widget.controller.text;
                        final selection = widget.controller.selection;
                        final cursorPosition =
                            selection.baseOffset.clamp(0, text.length);

                        if (text.isEmpty) {
                          // Show a cursor for empty field if focused
                          return widget.isFocused && _showCursor
                              ? Container(
                                  width: 2,
                                  height: 30,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                )
                              : const SizedBox(height: 30);
                        }

                        // Split text at cursor position if focused
                        if (widget.isFocused) {
                          final beforeCursor =
                              text.substring(0, cursorPosition);
                          final afterCursor = text.substring(cursorPosition);

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Text before cursor
                              if (beforeCursor.isNotEmpty)
                                Math.tex(
                                  _toLatex(beforeCursor),
                                  textStyle: TextStyle(
                                    fontSize: 20,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  onErrorFallback: (err) => Text(
                                    beforeCursor,
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.red.shade300),
                                  ),
                                ),

                              // Cursor (only if focused and timer shows it)
                              if (_showCursor)
                                Container(
                                  width: 2,
                                  height: 30,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),

                              // Text after cursor
                              if (afterCursor.isNotEmpty)
                                Math.tex(
                                  _toLatex(afterCursor),
                                  textStyle: TextStyle(
                                    fontSize: 20,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  onErrorFallback: (err) => Text(
                                    afterCursor,
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.red.shade300),
                                  ),
                                ),
                            ],
                          );
                        } else {
                          // Not focused, just show the text without cursor
                          return Math.tex(
                            _toLatex(text),
                            textStyle: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onErrorFallback: (err) => Text(
                              text,
                              style: TextStyle(
                                  fontSize: 20, color: Colors.red.shade300),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IntegralDialog extends StatefulWidget {
  @override
  State<IntegralDialog> createState() => _IntegralDialogState();
}

class _IntegralDialogState extends State<IntegralDialog> {
  final _functionController = LatexController();
  final _variableController = LatexController();
  final _lowerController = LatexController();
  final _upperController = LatexController();
  // Long-lived focus node so we don't leak/reallocate every rebuild.
  final FocusNode _keyboardFocus = FocusNode();
  bool _isDefinite = false;

  // Track which field is currently focused for keyboard input
  int _focusedField = 0; // 0=function, 1=variable, 2=lower, 3=upper

  @override
  void initState() {
    super.initState();
    _variableController.insert('x');
  }

  @override
  void dispose() {
    _functionController.dispose();
    _variableController.dispose();
    _lowerController.dispose();
    _upperController.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  bool _handleKeyboardInput(KeyEvent event) {
    return KeyboardInputHandler.handleKeyboardInput(
      event,
      (text) => _insertAtFocusedField(text),
      () => _backspaceAtFocusedField(),
      () => _clearFocusedField(),
      () => _submitDialog(),
      (amount) => _moveCursorAtFocusedField(amount),
    );
  }

  void _insertAtFocusedField(String text) {
    final activeController = _getActiveController();
    activeController?.insert(text);
  }

  void _backspaceAtFocusedField() {
    final activeController = _getActiveController();
    activeController?.backspace();
  }

  void _clearFocusedField() {
    final activeController = _getActiveController();
    activeController?.clear();
  }

  void _submitDialog() {
    _onSubmit();
  }

  void _moveCursorAtFocusedField(int amount) {
    final activeController = _getActiveController();
    activeController?.moveCursor(amount);
  }

  LatexController? _getActiveController() {
    switch (_focusedField) {
      case 0:
        return _functionController;
      case 1:
        return _variableController;
      case 2:
        return _lowerController;
      case 3:
        return _upperController;
      default:
        return _functionController;
    }
  }

  void _onSubmit() {
    final func = _functionController.text.trim();
    final variable = _variableController.text.trim();

    if (func.isEmpty) return;

    String result;
    if (_isDefinite &&
        _lowerController.text.isNotEmpty &&
        _upperController.text.isNotEmpty) {
      final lower = _lowerController.text.trim();
      final upper = _upperController.text.trim();
      result = r'\int_{' +
          lower +
          r'}^{' +
          upper +
          r'} ' +
          func +
          r' \, d' +
          variable;
    } else {
      result = r'\int ' + func + r' \, d' + variable;
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyboardInput,
      child: AlertDialog(
        title: const Text('Integral'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogLatexField(
              controller: _functionController,
              label: 'Function f(x)',
              isFocused: _focusedField == 0,
              onTap: () => setState(() => _focusedField = 0),
            ),
            const SizedBox(height: 12),
            DialogLatexField(
              controller: _variableController,
              label: 'Variable',
              isFocused: _focusedField == 1,
              onTap: () => setState(() => _focusedField = 1),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Definite Integral'),
              value: _isDefinite,
              onChanged: (value) => setState(() => _isDefinite = value!),
            ),
            if (_isDefinite) ...[
              const SizedBox(height: 12),
              DialogLatexField(
                controller: _lowerController,
                label: 'Lower Bound',
                isFocused: _focusedField == 2,
                onTap: () => setState(() => _focusedField = 2),
              ),
              const SizedBox(height: 12),
              DialogLatexField(
                controller: _upperController,
                label: 'Upper Bound',
                isFocused: _focusedField == 3,
                onTap: () => setState(() => _focusedField = 3),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _onSubmit,
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }
}

class NthRootDialog extends StatefulWidget {
  @override
  State<NthRootDialog> createState() => _NthRootDialogState();
}

class _NthRootDialogState extends State<NthRootDialog> {
  final _expressionController = LatexController();
  final _rootController = LatexController();
  final FocusNode _keyboardFocus = FocusNode();

  int _focusedField = 0; // 0=expression, 1=root

  @override
  void initState() {
    super.initState();
    _rootController.insert('3');
  }

  @override
  void dispose() {
    _expressionController.dispose();
    _rootController.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  bool _handleKeyboardInput(KeyEvent event) {
    return KeyboardInputHandler.handleKeyboardInput(
      event,
      (text) => _insertAtFocusedField(text),
      () => _backspaceAtFocusedField(),
      () => _clearFocusedField(),
      () => _submitDialog(),
      (amount) => _moveCursorAtFocusedField(amount),
    );
  }

  void _insertAtFocusedField(String text) {
    final activeController = _getActiveController();
    activeController?.insert(text);
  }

  void _backspaceAtFocusedField() {
    final activeController = _getActiveController();
    activeController?.backspace();
  }

  void _clearFocusedField() {
    final activeController = _getActiveController();
    activeController?.clear();
  }

  void _submitDialog() {
    _onSubmit();
  }

  void _moveCursorAtFocusedField(int amount) {
    final activeController = _getActiveController();
    activeController?.moveCursor(amount);
  }

  LatexController? _getActiveController() {
    switch (_focusedField) {
      case 0:
        return _expressionController;
      case 1:
        return _rootController;
      default:
        return _expressionController;
    }
  }

  void _onSubmit() {
    final expr = _expressionController.text.trim();
    final root = _rootController.text.trim();

    if (expr.isEmpty || root.isEmpty) return;

    final result = r'\sqrt[' + root + r']{' + expr + r'}';
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyboardInput,
      child: AlertDialog(
        title: const Text('Nth Root'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogLatexField(
              controller: _expressionController,
              label: 'Expression',
              isFocused: _focusedField == 0,
              onTap: () => setState(() => _focusedField = 0),
            ),
            const SizedBox(height: 12),
            DialogLatexField(
              controller: _rootController,
              label: 'Root (n)',
              isFocused: _focusedField == 1,
              onTap: () => setState(() => _focusedField = 1),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _onSubmit,
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }
}

class LimitDialog extends StatefulWidget {
  @override
  State<LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<LimitDialog> {
  final _functionController = LatexController();
  final _variableController = LatexController();
  final _approachesController = LatexController();
  final FocusNode _keyboardFocus = FocusNode();

  int _focusedField = 0; // 0=function, 1=variable, 2=approaches

  @override
  void initState() {
    super.initState();
    _variableController.insert('x');
    _approachesController.insert('0');
  }

  @override
  void dispose() {
    _functionController.dispose();
    _variableController.dispose();
    _approachesController.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  bool _handleKeyboardInput(KeyEvent event) {
    return KeyboardInputHandler.handleKeyboardInput(
      event,
      (text) => _insertAtFocusedField(text),
      () => _backspaceAtFocusedField(),
      () => _clearFocusedField(),
      () => _submitDialog(),
      (amount) => _moveCursorAtFocusedField(amount),
    );
  }

  void _insertAtFocusedField(String text) {
    final activeController = _getActiveController();
    activeController?.insert(text);
  }

  void _backspaceAtFocusedField() {
    final activeController = _getActiveController();
    activeController?.backspace();
  }

  void _clearFocusedField() {
    final activeController = _getActiveController();
    activeController?.clear();
  }

  void _submitDialog() {
    _onSubmit();
  }

  void _moveCursorAtFocusedField(int amount) {
    final activeController = _getActiveController();
    activeController?.moveCursor(amount);
  }

  LatexController? _getActiveController() {
    switch (_focusedField) {
      case 0:
        return _functionController;
      case 1:
        return _variableController;
      case 2:
        return _approachesController;
      default:
        return _functionController;
    }
  }

  void _onSubmit() {
    final func = _functionController.text.trim();
    final variable = _variableController.text.trim();
    final approaches = _approachesController.text.trim();

    if (func.isEmpty) return;

    final result = r'\lim_{' + variable + r' \to ' + approaches + r'} ' + func;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _handleKeyboardInput,
      child: AlertDialog(
        title: const Text('Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogLatexField(
              controller: _functionController,
              label: 'Function f(x)',
              isFocused: _focusedField == 0,
              onTap: () => setState(() => _focusedField = 0),
            ),
            const SizedBox(height: 12),
            DialogLatexField(
              controller: _variableController,
              label: 'Variable',
              isFocused: _focusedField == 1,
              onTap: () => setState(() => _focusedField = 1),
            ),
            const SizedBox(height: 12),
            DialogLatexField(
              controller: _approachesController,
              label: 'Approaches',
              isFocused: _focusedField == 2,
              onTap: () => setState(() => _focusedField = 2),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _onSubmit,
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }
}
