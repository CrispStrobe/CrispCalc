/// lib/engine/calculator_engine.dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'cas_bridge.dart';

/// A high-level Dart API for the CAS engine.
/// It handles all FFI calls and memory management.
class CalculatorEngine {
  late final CASBridge? _bridge;
  bool _nativeAvailable = false;

  CalculatorEngine() {
    try {
      _bridge = CASBridge();
      _nativeAvailable = true;
      print('✅ Native CAS library loaded successfully');
    } catch (e) {
      print('❌ Native library not available, using fallback: $e');
      _nativeAvailable = false;
      _bridge = null;
    }
  }

  /// Evaluates a mathematical expression by calling the native library.
  String evaluate(String expression) {
    print('ENGINE: Evaluating expression: "$expression"');
    
    if (_nativeAvailable) {
      final result = _callNative('evaluate', expression);
      print('ENGINE: Evaluation result: "$result"');
      return result;
    }
    return 'Error: Native Library Failed';
  }

  /// Solves an equation for a given variable.
  String solve(String expression, String symbol) {
    print('SOLVE: Native solve called with expression: "$expression", symbol: "$symbol"');
    
    if (_nativeAvailable) {
      final result = _callNativeTwoArg('solve', expression, symbol);
      print('SOLVE: Native solve result: "$result"');
      
      // Format the result nicely
      if (result != "Solve error" && result != "No solutions found") {
        // If we get numeric solutions, format them with the variable name
        if (result.contains(',')) {
          // Multiple solutions
          return '$symbol = {$result}';
        } else {
          // Single solution
          return '$symbol = $result';
        }
      }
      
      return result;
    }
    return 'Solver requires native library';
  }

  /// Factors a symbolic expression.
  String factor(String expression) {
    print('FACTOR: Factoring expression: "$expression"');
    if (_nativeAvailable) {
      final result = _callNative('factor', expression);
      print('FACTOR: Result: "$result"');
      return result;
    }
    return 'Factor requires native library';
  }

  /// Expands a symbolic expression.
  String expand(String expression) {
    print('EXPAND: Expanding expression: "$expression"');
    if (_nativeAvailable) {
      final result = _callNative('expand', expression);
      print('EXPAND: Result: "$result"');
      return result;
    }
    return 'Expand requires native library';
  }

  // Generic wrapper for single-argument native functions
  String _callNative(String functionName, String expression) {
    if (_bridge == null) throw Exception('Bridge not available');
    
    print('NATIVE: Calling $functionName with: "$expression"');
    
    Pointer<Utf8> expressionPtr = expression.toNativeUtf8();
    Pointer<Utf8> resultPtr;

    try {
      switch (functionName) {
        case 'evaluate':
          resultPtr = _bridge!.evaluate(expressionPtr);
          break;
        case 'factor':
          resultPtr = _bridge!.factor(expressionPtr);
          break;
        case 'expand':
          resultPtr = _bridge!.expand(expressionPtr);
          break;
        default:
          malloc.free(expressionPtr);
          throw Exception("Unknown native function: $functionName");
      }

      final result = resultPtr.toDartString();
      print('NATIVE: $functionName returned: "$result"');
      
      _bridge!.free_string(resultPtr);
      malloc.free(expressionPtr);
      
      return result;
    } catch (e) {
      print('NATIVE: Error in $functionName: $e');
      malloc.free(expressionPtr);
      return 'Error';
    }
  }

  // Generic wrapper for two-argument native functions  
  String _callNativeTwoArg(String functionName, String arg1, String arg2) {
    if (_bridge == null) throw Exception('Bridge not available');
    
    print('NATIVE: Calling $functionName with: "$arg1", "$arg2"');
    
    Pointer<Utf8> arg1Ptr = arg1.toNativeUtf8();
    Pointer<Utf8> arg2Ptr = arg2.toNativeUtf8();
    Pointer<Utf8> resultPtr;

    try {
      switch (functionName) {
        case 'solve':
          resultPtr = _bridge!.solve(arg1Ptr, arg2Ptr);
          break;
        default:
          malloc.free(arg1Ptr);
          malloc.free(arg2Ptr);
          throw Exception("Unknown native function: $functionName");
      }

      final result = resultPtr.toDartString();
      print('NATIVE: $functionName returned: "$result"');
      
      _bridge!.free_string(resultPtr);
      malloc.free(arg1Ptr);
      malloc.free(arg2Ptr);
      
      return result;
    } catch (e) {
      print('NATIVE: Error in $functionName: $e');
      malloc.free(arg1Ptr);
      malloc.free(arg2Ptr);
      return 'Error';
    }
  }
}