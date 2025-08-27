/// lib/engine/calculator_engine.dart:

import 'dart:ffi';
import 'dart:math' as math;
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
      print('Native CAS library loaded successfully');
    } catch (e) {
      print('Native library not available, using fallback: $e');
      _nativeAvailable = false;
      _bridge = null;
    }
  }

  /// Evaluates a mathematical expression with proper operator precedence.
  String evaluate(String expression) {
    if (_nativeAvailable && _bridge != null) {
      try {
        return _callNative('evaluate', expression);
      } catch (e) {
        print('Native evaluation failed: $e. Using fallback.');
      }
    }

    // Fallback to built-in evaluator with proper precedence
    try {
      final result = _evaluateWithPrecedence(expression);
      if (result.isNaN || result.isInfinite) {
        return 'Error';
      }
      // Format result nicely
      if (result == result.truncateToDouble()) {
        return result.toInt().toString();
      }
      return result.toString();
    } catch (e) {
      print('Evaluation error: $e');
      return 'Error';
    }
  }

  /// Solves an equation for a given variable.
  String solve(String expression, String symbol) {
    if (_nativeAvailable && _bridge != null) {
      try {
        return _callNativeTwoArg('solve', expression, symbol);
      } catch (e) {
        print('Native solve failed: $e');
      }
    }
    return 'Solver requires native library';
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

  // Robust fallback evaluator using Shunting-yard algorithm
  double _evaluateWithPrecedence(String expression) {
    try {
      final tokens = _tokenize(expression);
      final rpnQueue = _toRPN(tokens);
      return _evaluateRPN(rpnQueue);
    } catch (e) {
      throw FormatException('Invalid expression: $e');
    }
  }

  // Operator properties: precedence and associativity
  final Map<String, Map<String, dynamic>> _operators = {
    '+': {'precedence': 2, 'associativity': 'Left'},
    '-': {'precedence': 2, 'associativity': 'Left'},
    '*': {'precedence': 3, 'associativity': 'Left'},
    '/': {'precedence': 3, 'associativity': 'Left'},
    '%': {'precedence': 3, 'associativity': 'Left'},
    '^': {'precedence': 4, 'associativity': 'Right'},
    '!': {'precedence': 5, 'associativity': 'Left'}, // Postfix
    'sin': {'precedence': 6, 'isFunction': true},
    'cos': {'precedence': 6, 'isFunction': true},
    'tan': {'precedence': 6, 'isFunction': true},
    'sqrt': {'precedence': 6, 'isFunction': true},
    'ln': {'precedence': 6, 'isFunction': true},
    'log': {'precedence': 6, 'isFunction': true},
    'abs': {'precedence': 6, 'isFunction': true},
  };

  // Advanced tokenizer with better number and operator recognition
  List<String> _tokenize(String expression) {
    expression = expression.replaceAll(' ', '').toLowerCase();
    expression = expression.replaceAll('pi', math.pi.toString());
    expression = expression.replaceAll('e', math.e.toString());
    
    // Handle implicit multiplication (e.g., "2x" -> "2*x", "3(4)" -> "3*(4)")
    expression = expression.replaceAllMapped(RegExp(r'(\d)([a-zA-Z(])'), (m) => '${m[1]}*${m[2]}');
    expression = expression.replaceAllMapped(RegExp(r'(\))(\d|[a-zA-Z(])'), (m) => '${m[1]}*${m[2]}');

    final tokens = <String>[];
    final regExp = RegExp(r'(-?\d+\.?\d*(?:[eE][+-]?\d+)?)|([+\-*/%^()!])|(?:sin|cos|tan|sqrt|ln|log|abs)');
    
    int index = 0;
    while (index < expression.length) {
      final match = regExp.matchAsPrefix(expression, index);
      if (match != null) {
        String token = match.group(0)!;

        // Handle unary minus more carefully
        if (token == '-') {
          final isUnary = tokens.isEmpty || 
                          ['(', '+', '-', '*', '/', '^', '%'].contains(tokens.last) ||
                          _operators[tokens.last]?['isFunction'] == true;
          
          if (isUnary) {
            // Look ahead for the next number/expression
            final nextMatch = RegExp(r'(\d+\.?\d*(?:[eE][+-]?\d+)?)').matchAsPrefix(expression, match.end);
            if (nextMatch != null) {
              tokens.add('-${nextMatch.group(0)!}');
              index = nextMatch.end;
              continue;
            }
          }
        }
        
        tokens.add(token);
        index = match.end;
      } else {
        index++; // Skip unrecognized characters
      }
    }
    return tokens;
  }

  // Shunting-yard algorithm to convert infix to RPN
  List<String> _toRPN(List<String> tokens) {
    final outputQueue = <String>[];
    final operatorStack = <String>[];

    for (final token in tokens) {
      if (double.tryParse(token) != null) {
        outputQueue.add(token);
      } else if (_operators[token]?['isFunction'] == true) {
        operatorStack.add(token);
      } else if (token == '!') {
        outputQueue.add(token);
      } else if (_operators.containsKey(token) && token != '!') {
        while (operatorStack.isNotEmpty &&
               operatorStack.last != '(' &&
               _operators.containsKey(operatorStack.last) &&
               ((_operators[operatorStack.last]!['precedence'] > _operators[token]!['precedence']) ||
                (_operators[operatorStack.last]!['precedence'] == _operators[token]!['precedence'] &&
                 _operators[token]!['associativity'] == 'Left'))) {
          outputQueue.add(operatorStack.removeLast());
        }
        operatorStack.add(token);
      } else if (token == '(') {
        operatorStack.add(token);
      } else if (token == ')') {
        while (operatorStack.isNotEmpty && operatorStack.last != '(') {
          outputQueue.add(operatorStack.removeLast());
        }
        if (operatorStack.isEmpty) {
          throw const FormatException("Mismatched parentheses");
        }
        operatorStack.removeLast(); // Remove '('
        
        // Handle function calls
        if (operatorStack.isNotEmpty && (_operators[operatorStack.last]?['isFunction'] == true)) {
          outputQueue.add(operatorStack.removeLast());
        }
      }
    }

    // Pop remaining operators
    while (operatorStack.isNotEmpty) {
      if (operatorStack.last == '(') {
        throw const FormatException("Mismatched parentheses");
      }
      outputQueue.add(operatorStack.removeLast());
    }
    
    return outputQueue;
  }

  // Evaluate RPN queue with proper error handling
  double _evaluateRPN(List<String> rpn) {
    final stack = <double>[];
    
    for (final token in rpn) {
      if (double.tryParse(token) != null) {
        stack.add(double.parse(token));
      } else if (token == '!') {
        if (stack.isEmpty) throw const FormatException("Invalid factorial expression");
        stack.add(_factorial(stack.removeLast()));
      } else if (_operators[token]?['isFunction'] == true) {
        if (stack.isEmpty) throw FormatException("Invalid function expression: $token");
        final operand = stack.removeLast();
        switch (token) {
          case 'sin': stack.add(math.sin(operand)); break;
          case 'cos': stack.add(math.cos(operand)); break;
          case 'tan': stack.add(math.tan(operand)); break;
          case 'sqrt': 
            if (operand < 0) throw const FormatException("Square root of negative number");
            stack.add(math.sqrt(operand)); 
            break;
          case 'ln': 
            if (operand <= 0) throw const FormatException("Logarithm of non-positive number");
            stack.add(math.log(operand)); 
            break;
          case 'log': 
            if (operand <= 0) throw const FormatException("Logarithm of non-positive number");
            stack.add(math.log(operand) / math.ln10); 
            break;
          case 'abs': stack.add(operand.abs()); break;
        }
      } else if (_operators.containsKey(token)) {
        if (stack.length < 2) throw FormatException("Invalid binary operation: $token");
        final right = stack.removeLast();
        final left = stack.removeLast();
        
        switch (token) {
          case '+': stack.add(left + right); break;
          case '-': stack.add(left - right); break;
          case '*': stack.add(left * right); break;
          case '/': 
            if (right == 0) throw const FormatException("Division by zero");
            stack.add(left / right); 
            break;
          case '%': 
            if (right == 0) throw const FormatException("Modulo by zero");
            stack.add(left % right); 
            break;
          case '^': stack.add(math.pow(left, right).toDouble()); break;
        }
      }
    }
    
    if (stack.length != 1) {
      throw const FormatException("Invalid expression structure");
    }
    
    return stack.single;
  }

  // Factorial with proper bounds checking
  double _factorial(double n) {
    if (n < 0 || n != n.truncateToDouble()) {
      throw const FormatException("Factorial requires non-negative integer");
    }
    if (n > 170) throw const FormatException("Factorial too large");
    
    if (n == 0) return 1;
    
    double result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }
}