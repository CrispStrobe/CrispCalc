/// lib/screens/function_editor_screen.dart:

import 'package:flutter/material.dart';
import '../engine/app_state.dart';

class FunctionEditorScreen extends StatefulWidget {
  const FunctionEditorScreen({super.key});

  @override
  State<FunctionEditorScreen> createState() => _FunctionEditorScreenState();
}

class _FunctionEditorScreenState extends State<FunctionEditorScreen> {
  final AppState _appState = AppState();
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _buildControllers();
  }
  
  void _buildControllers() {
    _controllers = _appState.graphFunctions
        .map((func) => TextEditingController(text: func))
        .toList();
  }

  @override
  void dispose() {
    for (int i = 0; i < _controllers.length; i++) {
      _appState.updateFunction(i, _controllers[i].text.trim());
      _controllers[i].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: This screen now listens for changes in AppState to stay in sync.
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, child) {
        // We need to update the text in the controllers without rebuilding them all.
        for (int i = 0; i < _controllers.length; i++) {
          if (_controllers[i].text != _appState.graphFunctions[i]) {
             _controllers[i].text = _appState.graphFunctions[i];
          }
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Function Editor (Y=)')),
          body: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _controllers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextField(
                  controller: _controllers[index],
                  decoration: InputDecoration(
                    prefixIcon: Text('Y${index + 1}', style: TextStyle(color: _getColorForFunction(index), fontWeight: FontWeight.bold, fontSize: 16)),
                    prefixIconConstraints: const BoxConstraints(minWidth: 48),
                    labelText: 'Y${index + 1}(x)',
                    hintText: 'Enter a function of x',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => _appState.updateFunction(index, value.trim()),
                ),
              );
            },
          ),
        );
      }
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