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
    // Clean up the expression
    expression = expression.toLowerCase();
    expression = expression.replaceAll(' ', '');
    expression = expression.replaceAll('pi', math.pi.toString());
    expression = expression.replaceAll('e', math.e.toString());
    
    // Handle basic mathematical functions
    if (expression.startsWith('sin(')) {
      final inner = expression.substring(4, expression.length - 1);
      return math.sin(_evaluateSimpleExpression(inner));
    }
    if (expression.startsWith('cos(')) {
      final inner = expression.substring(4, expression.length - 1);
      return math.cos(_evaluateSimpleExpression(inner));
    }
    if (expression.startsWith('tan(')) {
      final inner = expression.substring(4, expression.length - 1);
      return math.tan(_evaluateSimpleExpression(inner));
    }
    if (expression.startsWith('sqrt(')) {
      final inner = expression.substring(5, expression.length - 1);
      return math.sqrt(_evaluateSimpleExpression(inner));
    }
    if (expression.startsWith('ln(')) {
      final inner = expression.substring(3, expression.length - 1);
      return math.log(_evaluateSimpleExpression(inner));
    }
    if (expression.startsWith('log(')) {
      final inner = expression.substring(4, expression.length - 1);
      return math.log(_evaluateSimpleExpression(inner)) / math.ln10;
    }
    
    // Handle power operations
    if (expression.contains('^')) {
      final parts = expression.split('^');
      if (parts.length == 2) {
        final base = _evaluateSimpleExpression(parts[0]);
        final exp = _evaluateSimpleExpression(parts[1]);
        return math.pow(base, exp).toDouble();
      }
    }
    
    // Handle basic arithmetic (very simplified)
    try {
      return double.parse(expression);
    } catch (e) {
      // For complex expressions, return 0 as fallback
      return 0.0;
    }
  }
}