/// lib/engine/calculator_engine.dart:

import 'dart:ffi';
import 'dart:math' as math;
import 'package:ffi/ffi.dart';
import 'cas_bridge.dart';

/// A high-level Dart API for the CAS engine.
/// It handles all FFI calls and memory management.
class CalculatorEngine {
  late final CASBridge _bridge;
  bool _nativeAvailable = false;

  CalculatorEngine() {
    try {
      _bridge = CASBridge();
      _nativeAvailable = true;
    } catch (e) {
      print('Native library not available, using fallback: $e');
      _nativeAvailable = false;
    }
  }

  /// Evaluates a simple numerical expression.
  String evaluate(String expression) {
    if (_nativeAvailable) {
      try {
        return _callNative('evaluate', expression);
      } catch (e) {
        print('Native evaluation failed: $e');
      }
    }
    
    // Fallback to built-in evaluator
    try {
      final result = _evaluateSimpleExpression(expression);
      return result.toString();
    } catch (e) {
      return 'Error';
    }
  }

  /// Solves an equation for a given variable.
  String solve(String expression, String symbol) {
    if (_nativeAvailable) {
      try {
        return _callNativeTwoArg('solve', expression, symbol);
      } catch (e) {
        print('Native solve failed: $e');
      }
    }
    
    return 'Native solver not available';
  }

  // A generic wrapper for single-argument native functions.
  String _callNative(String functionName, String expression) {
    Pointer<Utf8> expressionPtr = expression.toNativeUtf8();
    Pointer<Utf8> resultPtr;
    
    switch(functionName){
       case 'evaluate':
          resultPtr = _bridge.evaluate(expressionPtr);
          break;
       default:
          throw Exception("Unknown native function: $functionName");
    }

    final result = resultPtr.toDartString();

    // CRITICAL: Free the memory allocated by the C++ code.
    _bridge.free_string(resultPtr);
    malloc.free(expressionPtr);

    return result;
  }

  // A generic wrapper for two-argument native functions.
  String _callNativeTwoArg(String functionName, String arg1, String arg2) {
    Pointer<Utf8> arg1Ptr = arg1.toNativeUtf8();
    Pointer<Utf8> arg2Ptr = arg2.toNativeUtf8();
    Pointer<Utf8> resultPtr;
    
    switch(functionName){
       case 'solve':
          resultPtr = _bridge.solve(arg1Ptr, arg2Ptr);
          break;
       default:
          throw Exception("Unknown native function: $functionName");
    }

    final result = resultPtr.toDartString();

    // CRITICAL: Free all allocated memory.
    _bridge.free_string(resultPtr);
    malloc.free(arg1Ptr);
    malloc.free(arg2Ptr);

    return result;
  }

  // Enhanced evaluator for basic mathematical expressions
  double _evaluateSimpleExpression(String expression) {
    try {
      // Clean up the expression
      expression = expression.toLowerCase().replaceAll(' ', '');
      
      // Replace constants
      expression = expression.replaceAll('pi', math.pi.toString());
      expression = expression.replaceAll('e', math.e.toString());
      
      // Handle basic arithmetic operations using simple parsing
      return _parseExpression(expression);
    } catch (e) {
      print('Evaluation error: $e');
      return 0.0;
    }
  }

  double _parseExpression(String expr) {
    // Handle basic mathematical functions first
    if (expr.startsWith('sin(')) {
      final inner = _extractParentheses(expr, 4);
      return math.sin(_parseExpression(inner));
    }
    if (expr.startsWith('cos(')) {
      final inner = _extractParentheses(expr, 4);
      return math.cos(_parseExpression(inner));
    }
    if (expr.startsWith('tan(')) {
      final inner = _extractParentheses(expr, 4);
      return math.tan(_parseExpression(inner));
    }
    if (expr.startsWith('sqrt(')) {
      final inner = _extractParentheses(expr, 5);
      return math.sqrt(_parseExpression(inner));
    }
    if (expr.startsWith('ln(')) {
      final inner = _extractParentheses(expr, 3);
      return math.log(_parseExpression(inner));
    }
    if (expr.startsWith('log(')) {
      final inner = _extractParentheses(expr, 4);
      return math.log(_parseExpression(inner)) / math.ln10;
    }

    // Handle power operations
    if (expr.contains('^')) {
      final parts = expr.split('^');
      if (parts.length == 2) {
        return math.pow(_parseExpression(parts[0]), _parseExpression(parts[1])).toDouble();
      }
    }

    // Handle basic arithmetic: +, -, *, /
    // Simple left-to-right evaluation (not proper precedence, but works for basic cases)
    
    // Handle multiplication and division first
    for (int i = 0; i < expr.length; i++) {
      if (expr[i] == '*' || expr[i] == '/') {
        final left = _parseExpression(expr.substring(0, i));
        final right = _parseExpression(expr.substring(i + 1));
        if (expr[i] == '*') {
          return left * right;
        } else {
          return right != 0 ? left / right : double.infinity;
        }
      }
    }
    
    // Handle addition and subtraction
    for (int i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == '+' || (expr[i] == '-' && i > 0)) {
        final left = _parseExpression(expr.substring(0, i));
        final right = _parseExpression(expr.substring(i + 1));
        if (expr[i] == '+') {
          return left + right;
        } else {
          return left - right;
        }
      }
    }

    // If no operators found, try to parse as number
    return double.parse(expr);
  }

  String _extractParentheses(String expr, int startIndex) {
    int depth = 0;
    int start = startIndex;
    for (int i = startIndex; i < expr.length; i++) {
      if (expr[i] == '(') {
        if (depth == 0) start = i + 1;
        depth++;
      } else if (expr[i] == ')') {
        depth--;
        if (depth == 0) {
          return expr.substring(start, i);
        }
      }
    }
    return expr.substring(start, expr.length - 1); // fallback
  }
}