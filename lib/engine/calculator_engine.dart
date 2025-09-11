/// lib/engine/calculator_engine.dart
import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';
/// The Dart interface that communicates with the underlying native C++ bridge.
/// This class abstracts away the low-level FFI calls by using your
/// existing 'symbolic_math_bridge' plugin.

class CalculatorEngine {
  late final SymbolicMathBridge? _bridge;
  bool _nativeAvailable = false;


  CalculatorEngine() {
    try {
      _bridge = SymbolicMathBridge();
      _nativeAvailable = true;
      print('✅ SymbolicMathBridge loaded successfully');
    } catch (e) {
      print('❌ SymbolicMathBridge not available, using fallback: $e');
      _nativeAvailable = false;
      _bridge = null;
    }
  }

  /// Evaluates a mathematical expression using SymEngine.
  String evaluate(String expression) {
    print('ENGINE: Evaluating expression: "$expression"');
    
    if (_nativeAvailable && _bridge != null) {
      try {
        final result = _bridge!.evaluate(expression);
        print('ENGINE: Evaluation result: "$result"');
        return result;
      } catch (e) {
        print('ENGINE: Evaluation error: $e');
        return 'Error';
      }
    }
    return 'Error: Native Library Failed';
  }

  // handles SymEngine complex number format
  String evaluateForGraphing(String expression) {
    // print('ENGINE_GRAPH: Evaluating for graphing: "$expression"');
    
    if (!_nativeAvailable || _bridge == null) {
      return 'Error: Native Library Failed';
    }
    
    try {
      // Use minimal preprocessing for graphing
      String cleanExpression = expression.trim();
      cleanExpression = cleanExpression.replaceAll(',', '.');
      cleanExpression = cleanExpression.replaceAll(' ', '');
      
      final result = _bridge!.evaluate(cleanExpression);
      // print('ENGINE_GRAPH: Raw result: "$result"');
      
      // Apply complex number extraction
      final realPart = _extractRealPartForGraphing(result);
      // print('ENGINE_GRAPH: Extracted real part: "$realPart"');
      
      return realPart;
    } catch (e) {
      print('ENGINE_GRAPH: Error: $e');
      return 'Error';
    }
  }

  String _extractRealPartForGraphing(String complexResult) {
    if (complexResult.isEmpty) return complexResult;
    
    String result = complexResult.trim();
    
    // Remove zero imaginary parts: "number + 0*I" -> "number"
    result = result.replaceAll(RegExp(r'\s*[+\-]\s*0(\.0*)?\s*\*?\s*I\b'), '');
    
    // Remove any remaining I terms for graphing (we only want real values)
    result = result.replaceAll(RegExp(r'\s*[+\-]\s*[^+\-]*I[^+\-]*'), '');
    
    // Clean up spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // If empty or just operators, try to extract first number
    if (result.isEmpty || RegExp(r'^[\+\-\*\s]*$').hasMatch(result)) {
      RegExp numberPattern = RegExp(r'([+\-]?\d*\.?\d+)');
      Match? match = numberPattern.firstMatch(complexResult);
      if (match != null) {
        result = match.group(1)!;
      } else {
        result = '0'; // Fallback for graphing
      }
    }
    
    return result;
  }

  /// Solves an equation for a given variable using SymEngine.
  String solve(String expression, String symbol) {
    print('SOLVE: Solving expression: "$expression", symbol: "$symbol"');
    
    if (_nativeAvailable && _bridge != null) {
      try {
        final result = _bridge!.solve(expression, symbol);
        print('SOLVE: Solve result: "$result"');
        
        // Format the result nicely
        if (result != "Error" && !result.startsWith('Error')) {
          // Parse the solution list format from SymEngine
          if (result.startsWith('[') && result.endsWith(']')) {
            final solutions = result.substring(1, result.length - 1);
            if (solutions.contains(',')) {
              // Multiple solutions
              return '$symbol = {$solutions}';
            } else if (solutions.isNotEmpty) {
              // Single solution
              return '$symbol = $solutions';
            }
          }
          
          // Fallback formatting
          return '$symbol = $result';
        }
        
        return result;
      } catch (e) {
        print('SOLVE: Solve error: $e');
        return 'Solve error';
      }
    }
    return 'Solver requires native library';
  }

  /// Factors a symbolic expression using SymEngine.
  String factor(String expression) {
    print('FACTOR: Factoring expression: "$expression"');
    if (_nativeAvailable && _bridge != null) {
      try {
        final result = _bridge!.factor(expression);
        print('FACTOR: Result: "$result"');
        return result;
      } catch (e) {
        print('FACTOR: Error: $e');
        return 'Factor Error';
      }
    }
    return 'Factor requires native library';
  }

  /// Expands a symbolic expression using SymEngine.
  String expand(String expression) {
    print('EXPAND: Expanding expression: "$expression"');
    if (_nativeAvailable && _bridge != null) {
      try {
        final result = _bridge!.expand(expression);
        print('EXPAND: Result: "$result"');
        return result;
      } catch (e) {
        print('EXPAND: Error: $e');
        return 'Expand Error';
      }
    }
    return 'Expand requires native library';
  }

  /// Differentiates an expression with respect to a variable.
  String differentiate(String expression, String variable) {
    print('DIFF: Differentiating expression: "$expression" w.r.t. $variable');
    if (_nativeAvailable && _bridge != null) {
      try {
        final result = _bridge!.differentiate(expression, variable);
        print('DIFF: Result: "$result"');
        return result;
      } catch (e) {
        print('DIFF: Error: $e');
        return 'Differentiation Error';
      }
    }
    return 'Differentiation requires native library';
  }

  /// Substitutes a variable with a value in an expression.
  String substitute(String expression, String variable, String value) {
    print('SUBST: Substituting $variable = $value in "$expression"');
    if (_nativeAvailable && _bridge != null) {
      try {
        final result = _bridge!.substitute(expression, variable, value);
        print('SUBST: Result: "$result"');
        return result;
      } catch (e) {
        print('SUBST: Error: $e');
        return 'Substitution Error';
      }
    }
    return 'Substitution requires native library';
  }

  /// Calls a unary mathematical function (sin, cos, log, etc.).
  String callUnary(String funcName, String expression) {
    print('UNARY: Calling $funcName on "$expression"');
    if (_nativeAvailable && _bridge != null) {
      try {
        final result = _bridge!.callUnary(funcName, expression);
        print('UNARY: Result: "$result"');
        return result;
      } catch (e) {
        print('UNARY: Error: $e');
        return 'Function Error';
      }
    }
    return 'Function requires native library';
  }

  /// Gets mathematical constants.
  String getPi() => _nativeAvailable && _bridge != null ? _bridge!.getPi() : '3.14159';
  String getE() => _nativeAvailable && _bridge != null ? _bridge!.getE() : '2.71828';
  String getEulerGamma() => _nativeAvailable && _bridge != null ? _bridge!.getEulerGamma() : '0.57721';

  /// Number theory functions.
  String factorial(int n) {
    if (_nativeAvailable && _bridge != null) {
      try {
        return _bridge!.factorial(n);
      } catch (e) {
        print('FACTORIAL: Error: $e');
        return 'Factorial Error';
      }
    }
    return 'Factorial requires native library';
  }

  String fibonacci(int n) {
    if (_nativeAvailable && _bridge != null) {
      try {
        return _bridge!.fibonacci(n);
      } catch (e) {
        print('FIBONACCI: Error: $e');
        return 'Fibonacci Error';
      }
    }
    return 'Fibonacci requires native library';
  }

  String gcd(String a, String b) {
    if (_nativeAvailable && _bridge != null) {
      try {
        return _bridge!.gcd(a, b);
      } catch (e) {
        print('GCD: Error: $e');
        return 'GCD Error';
      }
    }
    return 'GCD requires native library';
  }

  String lcm(String a, String b) {
    if (_nativeAvailable && _bridge != null) {
      try {
        return _bridge!.lcm(a, b);
      } catch (e) {
        print('LCM: Error: $e');
        return 'LCM Error';
      }
    }
    return 'LCM requires native library';
  }

  /// Matrix operations using the bridge.
  SymEngineMatrix? createMatrix(int rows, int cols) {
    if (_nativeAvailable && _bridge != null) {
      try {
        return _bridge!.createMatrix(rows, cols);
      } catch (e) {
        print('MATRIX: Creation error: $e');
        return null;
      }
    }
    return null;
  }

  /// Checks if the native bridge is available.
  bool get isNativeAvailable => _nativeAvailable;
}