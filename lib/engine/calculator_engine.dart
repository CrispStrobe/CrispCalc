/// lib/engine/calculator_engine.dart:

import 'dart:ffi'; // FIX: Corrected the import syntax for the FFI library.
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
    if (_nativeAvailable) return _callNative('evaluate', expression);
    return 'Error: Native Library Failed';
  }

  /// Solves an equation for a given variable.
  String solve(String expression, String symbol) {
    if (_nativeAvailable) return _callNativeTwoArg('solve', expression, symbol);
    return 'Solver requires native library';
  }

  /// Factors a symbolic expression.
  String factor(String expression) {
    if (_nativeAvailable) return _callNative('factor', expression);
    return 'Factor requires native library';
  }

  /// Expands a symbolic expression.
  String expand(String expression) {
    if (_nativeAvailable) return _callNative('expand', expression);
    return 'Expand requires native library';
  }

  // Generic wrapper for single-argument native functions
  String _callNative(String functionName, String expression) {
    if (_bridge == null) throw Exception('Bridge not available');
    
    Pointer<Utf8> expressionPtr = expression.toNativeUtf8();
    Pointer<Utf8> resultPtr;

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
    _bridge!.free_string(resultPtr);
    malloc.free(expressionPtr);
    return result;
  }

  // Generic wrapper for two-argument native functions
  String _callNativeTwoArg(String functionName, String arg1, String arg2) {
    if (_bridge == null) throw Exception('Bridge not available');
    
    Pointer<Utf8> arg1Ptr = arg1.toNativeUtf8();
    Pointer<Utf8> arg2Ptr = arg2.toNativeUtf8();
    Pointer<Utf8> resultPtr;

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
    _bridge!.free_string(resultPtr);
    malloc.free(arg1Ptr);
    malloc.free(arg2Ptr);
    return result;
  }
}