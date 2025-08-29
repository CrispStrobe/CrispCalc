/// lib/engine/app_state.dart

import 'package:flutter/foundation.dart';

enum HistoryEntryType { calculation, solve }

class CalculationEntry {
  final String expression;
  final String result;
  final HistoryEntryType type;

  CalculationEntry({
    required this.expression,
    required this.result,
    this.type = HistoryEntryType.calculation,
  });
}

// FIX: AppState now uses ChangeNotifier to instantly sync UI updates across all screens.
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  
  AppState._internal() {
    graphFunctions = List.generate(10, (_) => '');
    // Add some default functions for demonstration
    graphFunctions[0] = 'sin(x)';
    graphFunctions[1] = 'x^2 - 2';
  }

  final List<CalculationEntry> history = [];
  late final List<String> graphFunctions;

  void addHistoryEntry(String expression, String result, {HistoryEntryType type = HistoryEntryType.calculation}) {
    history.insert(0, CalculationEntry(expression: expression, result: result, type: type));
    notifyListeners(); // Notify all listening widgets of the change
  }

  void updateFunction(int index, String expression) {
    if (index >= 0 && index < graphFunctions.length) {
      if (graphFunctions[index] != expression) {
        graphFunctions[index] = expression;
        notifyListeners(); // Notify all listening widgets
      }
    }
  }

  void clearFunction(int index) {
     if (index >= 0 && index < graphFunctions.length) {
      if (graphFunctions[index].isNotEmpty) {
        graphFunctions[index] = '';
        notifyListeners(); // Notify all listening widgets
      }
    }
  }
}