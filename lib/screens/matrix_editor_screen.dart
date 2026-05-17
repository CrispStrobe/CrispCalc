// lib/screens/matrix_editor_screen.dart
// A dedicated screen for creating, editing, and performing simple
// operations on matrices before using them in the main calculator.

import 'package:flutter/material.dart';

class MatrixEditorScreen extends StatefulWidget {
  const MatrixEditorScreen({super.key});

  @override
  State<MatrixEditorScreen> createState() => _MatrixEditorScreenState();
}

class _MatrixEditorScreenState extends State<MatrixEditorScreen> {
  int _rows = 2;
  int _cols = 2;
  late List<List<TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _generateControllers();
  }

  /// Creates a 2D list of TextEditingControllers to manage the grid's state.
  void _generateControllers() {
    // A new list is created. Old controllers will be disposed of.
    _controllers = List.generate(
      _rows,
      (i) => List.generate(
        _cols,
        (j) => TextEditingController(text: '0'),
      ),
    );
  }

  @override
  void dispose() {
    // It's crucial to dispose of every controller to prevent memory leaks.
    for (var row in _controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  /// Updates the matrix dimensions and regenerates the controller grid.
  void _updateDimensions(int newRows, int newCols) {
    // Enforce a minimum size of 1x1.
    if (newRows < 1 || newCols < 1) return;
    setState(() {
      _rows = newRows;
      _cols = newCols;
      _generateControllers();
    });
  }

  /// Converts the current values in the grid to the defined matrix string format.
  String _matrixToString() {
    final rowsStr = _controllers.map((row) {
      // For each row, join the cell values with a comma.
      return row
          .map((controller) =>
              controller.text.trim().isEmpty ? '0' : controller.text.trim())
          .join(', ');
    }).join('; '); // Join the rows with a semicolon.
    return '[$rowsStr]';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Use Matrix in Calculator',
            onPressed: () {
              // Pop the screen and return the generated matrix string.
              Navigator.of(context).pop(_matrixToString());
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section for dimension controls
            _buildDimensionControls(),
            const Divider(height: 40),

            // Section for the matrix grid
            Text('Matrix Values',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildMatrixGrid(),
            const SizedBox(height: 24),

            // Section for operations
            Text('Quick Operations',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildOperationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Text('Rows:', style: TextStyle(fontSize: 16)),
        Text('$_rows',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Column(
          children: [
            IconButton.filledTonal(
                icon: const Icon(Icons.add),
                iconSize: 18,
                onPressed: () => _updateDimensions(_rows + 1, _cols)),
            IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                iconSize: 18,
                onPressed: () => _updateDimensions(_rows - 1, _cols)),
          ],
        ),
        const SizedBox(width: 24),
        const Text('Columns:', style: TextStyle(fontSize: 16)),
        Text('$_cols',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Column(
          children: [
            IconButton.filledTonal(
                icon: const Icon(Icons.add),
                iconSize: 18,
                onPressed: () => _updateDimensions(_rows, _cols + 1)),
            IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                iconSize: 18,
                onPressed: () => _updateDimensions(_rows, _cols - 1)),
          ],
        ),
      ],
    );
  }

  Widget _buildMatrixGrid() {
    return Center(
      child: SizedBox(
        // The width of the grid adapts to the number of columns.
        width: (_cols * 75.0).clamp(150.0, 450.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _cols,
            childAspectRatio: 1.5,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: _rows * _cols,
          itemBuilder: (context, index) {
            final row = index ~/ _cols;
            final col = index % _cols;
            return TextField(
              controller: _controllers[row][col],
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.zero,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOperationButtons() {
    // This helper function wraps the matrix in a function call and returns it.
    void performOperationAndReturn(String funcName) {
      final matrixStr = _matrixToString();
      final result = '$funcName($matrixStr)';
      Navigator.of(context).pop(result);
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton(
            onPressed: () => performOperationAndReturn('det'),
            child: const Text('det(A)')),
        ElevatedButton(
            onPressed: () => performOperationAndReturn('inv'),
            child: const Text('inv(A)')),
        ElevatedButton(
            onPressed: () => performOperationAndReturn('transpose'),
            child: const Text('transpose(A)')),
      ],
    );
  }
}
