/// lib/engine/app_state.dart
/// A singleton class to hold the global state of the application.
/// This includes calculation history, user-defined functions, and variables.
/// It uses ChangeNotifier to notify listening widgets of any changes.

import 'package:flutter/foundation.dart';

enum HistoryEntryType { calculation, solve }
enum NumberDisplayFormat {
  integer,        // 129
  oneDecimal,     // 129.0  
  twoDecimal,     // 129.00
  auto,           // Smart: 129 for integers, 129.5 for decimals
}

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

// Uses ChangeNotifier to instantly sync UI updates across all screens.
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  NumberDisplayFormat _numberFormat = NumberDisplayFormat.auto;
  NumberDisplayFormat get numberFormat => _numberFormat;
  
  void setNumberFormat(NumberDisplayFormat format) {
    if (_numberFormat != format) {
      _numberFormat = format;
      notifyListeners();
    }
  }

  // Number formatting method
  String formatNumber(String numberString) {
    final number = double.tryParse(numberString);
    if (number == null) return numberString;
    
    switch (_numberFormat) {
      case NumberDisplayFormat.integer:
        return number.round().toString();
      case NumberDisplayFormat.oneDecimal:
        return number.toStringAsFixed(1);
      case NumberDisplayFormat.twoDecimal:
        return number.toStringAsFixed(2);
      case NumberDisplayFormat.auto:
        return number == number.roundToDouble() 
          ? number.round().toString() 
          : number.toString();
    }
  }
  
  AppState._internal() {
    // Initialize with 10 empty function slots and add some examples.
    graphFunctions = List.generate(10, (_) => '');
    userFunctions = List.generate(10, (_) => '');
    
    // Add some default functions for demonstration
    graphFunctions[0] = 'sin(x)';
    graphFunctions[1] = 'x^2 - 2';
  }

  /// The list of past calculations.
  final List<CalculationEntry> history = [];
  
  /// A map of user-defined variables (e.g., 'a' = '5', 'myVar' = '3.14').
  final Map<String, String> userVariables = {};
  
  /// A list of user-definable functions for graphing (Y1, Y2, etc.).
  late final List<String> graphFunctions;
  
  /// A list of user-definable functions for general use (F1, F2, etc.).
  late final List<String> userFunctions;

  /// Adds a new entry to the top of the calculation history.
  void addHistoryEntry(String expression, String result, {HistoryEntryType type = HistoryEntryType.calculation}) {
    String formattedResult = formatNumber(result);
    history.insert(0, CalculationEntry(expression: expression, result: formattedResult, type: type));
    notifyListeners(); // Notify all listening widgets of the change
  }

  /// Sets or updates a variable in the store.
  void setVariable(String name, String value) {
    userVariables[name] = value;
    print("STATE: Set variable '$name' to '$value'");
    notifyListeners();
  }

  /// Gets a variable value by name.
  String? getVariable(String name) {
    return userVariables[name];
  }

  /// Removes a variable from the store.
  void removeVariable(String name) {
    if (userVariables.containsKey(name)) {
      userVariables.remove(name);
      print("STATE: Removed variable '$name'");
      notifyListeners();
    }
  }

  /// Updates a graph function at a specific index (Y1, Y2, etc.).
  void updateFunction(int index, String expression) {
    if (index >= 0 && index < graphFunctions.length) {
      if (graphFunctions[index] != expression) {
        graphFunctions[index] = expression;
        print("STATE: Updated Y${index + 1} to '$expression'");
        notifyListeners(); // Notify all listening widgets
      }
    }
  }

  /// Clears a graph function at a specific index.
  void clearFunction(int index) {
     if (index >= 0 && index < graphFunctions.length) {
      if (graphFunctions[index].isNotEmpty) {
        print("STATE: Cleared Y${index + 1}");
        graphFunctions[index] = '';
        notifyListeners(); // Notify all listening widgets
      }
    }
  }

  /// Updates a user function at a specific index (F1, F2, etc.).
  void updateUserFunction(int index, String expression) {
    if (index >= 0 && index < userFunctions.length) {
      if (userFunctions[index] != expression) {
        userFunctions[index] = expression;
        print("STATE: Updated F${index + 1} to '$expression'");
        notifyListeners(); // Notify all listening widgets
      }
    }
  }

  /// Clears a user function at a specific index.
  void clearUserFunction(int index) {
     if (index >= 0 && index < userFunctions.length) {
      if (userFunctions[index].isNotEmpty) {
        print("STATE: Cleared F${index + 1}");
        userFunctions[index] = '';
        notifyListeners(); // Notify all listening widgets
      }
    }
  }

  /// Gets a user function by index.
  String getUserFunction(int index) {
    if (index >= 0 && index < userFunctions.length) {
      return userFunctions[index];
    }
    return '';
  }

  /// Gets a graph function by index.
  String getGraphFunction(int index) {
    if (index >= 0 && index < graphFunctions.length) {
      return graphFunctions[index];
    }
    return '';
  }

  /// Clears all calculation history.
  void clearHistory() {
    history.clear();
    print("STATE: Cleared calculation history");
    notifyListeners();
  }

  /// Clears all variables.
  void clearAllVariables() {
    userVariables.clear();
    print("STATE: Cleared all variables");
    notifyListeners();
  }

  /// Clears all functions.
  void clearAllFunctions() {
    for (int i = 0; i < graphFunctions.length; i++) {
      graphFunctions[i] = '';
    }
    for (int i = 0; i < userFunctions.length; i++) {
      userFunctions[i] = '';
    }
    print("STATE: Cleared all functions");
    notifyListeners();
  }
}