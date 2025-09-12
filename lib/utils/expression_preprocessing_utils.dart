/// lib/utils/expression_preprocessing_utils.dart
/// Utilities for preprocessing mathematical expressions before evaluation

import '../engine/calculator_engine.dart';
import '../engine/app_state.dart';

class ExpressionPreprocessingUtils {
  static String preprocessNativeExpression(String expression) {
    String p = expression;
    
    // Convert German decimal comma to period
    p = p.replaceAll(',', '.');

    // Handle implicit multiplication for numbers and parentheses
    p = p.replaceAllMapped(RegExp(r'(\d|\))(\()'), (m) => '${m[1]}*${m[2]}');
    
    // Handle implicit multiplication for variables
    p = p.replaceAllMapped(RegExp(r'(\b[a-zA-Z]\b)(\()'), (m) => '${m[1]}*${m[2]}');
    p = p.replaceAllMapped(RegExp(r'(\))(\d|\b[a-zA-Z]\b)'), (m) => '${m[1]}*${m[2]}');
    
    // Handle factorial notation: n! -> factorial(n)
    p = p.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n <= 20) {
        // Calculate small factorials directly
        int f = 1;
        for (int i = 1; i <= n; i++) { f *= i; }
        return f.toString();
      } else {
        // Use gamma function for large factorials: n! = gamma(n+1)
        return 'gamma(${n + 1})';
      }
    });
    
    // Handle variable factorial: var! -> factorial(var)
    p = p.replaceAllMapped(RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*)!'), (m) {
      return 'gamma(${m.group(1)} + 1)';
    });
    
    // Handle modulo operations: a mod b -> a % b
    p = p.replaceAllMapped(RegExp(r'(\S+)\s+mod\s+(\S+)'), (m) {
      return '(${m.group(1)}) % (${m.group(2)})';
    });
    
    // Handle special function calls that need preprocessing
    p = preprocessSpecialFunctions(p);
    
    return p;
  }

  static String preprocessSpecialFunctions(String expression) {
    String result = expression;
    
    // Handle fibonacci function calls
    result = result.replaceAllMapped(RegExp(r'fib\((\d+)\)'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n <= 0) return '0';
      if (n == 1 || n == 2) return '1';
      
      // For small numbers, calculate directly
      if (n <= 40) {
        int a = 0, b = 1;
        for (int i = 2; i <= n; i++) {
          int temp = a + b;
          a = b;
          b = temp;
        }
        return b.toString();
      } else {
        // Use SymEngine's fibonacci function for larger numbers
        return 'fibonacci($n)';
      }
    });
    
    // Handle prime checking
    result = result.replaceAllMapped(RegExp(r'isprime\((\d+)\)'), (m) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n < 2) return 'false';
      if (n == 2) return 'true';
      if (n % 2 == 0) return 'false';
      
      // Simple primality test for small numbers
      for (int i = 3; i * i <= n; i += 2) {
        if (n % i == 0) return 'false';
      }
      return 'true';
    });
    
    return result;
  }

  /// Substitutes variable names with their stored values in an expression
  static String substituteVariables(String expression, AppState appState) {
    String result = expression;
    
    // Replace 'Ans' with the last calculation result
    if (result.contains('Ans')) {
      final lastResult = appState.history.isNotEmpty ? appState.history.first.result : '0';
      final cleanResult = extractNumericFromSolveResult(lastResult);
      result = result.replaceAll('Ans', cleanResult);
    }
    
    // Replace user-defined variables
    for (final entry in appState.userVariables.entries) {
      final variableName = entry.key;
      final variableValue = entry.value;
      
      // Use word boundaries to avoid partial replacements
      final pattern = RegExp(r'\b' + RegExp.escape(variableName) + r'\b');
      result = result.replaceAll(pattern, '($variableValue)');
    }
    
    print('SUBSTITUTE: "$expression" -> "$result"');
    return result;
  }

  static String extractNumericFromSolveResult(String solveResult) {
    // Extract numeric value from solve results like "x = 5" -> "5"
    final match = RegExp(r'[a-zA-Z]\s*=\s*([+-]?[\d.]+)\s*$').firstMatch(solveResult);
    if (match != null && !match.group(1)!.contains(',')) {
      return match.group(1)!.trim();
    }
    return solveResult;
  }

  static String preprocessExpression(String expression, AppState appState) {
    String processed = expression;

    final funcCallRegex = RegExp(r'Y(\d+)\((.*?)\)');
    processed = processed.replaceAllMapped(funcCallRegex, (match) {
      try {
        final funcIndex = int.parse(match.group(1)!) - 1;
        final argValue = match.group(2)!;

        if (funcIndex >= 0 && funcIndex < appState.graphFunctions.length) {
          String funcBody = appState.graphFunctions[funcIndex];
          if (funcBody.isNotEmpty) {
            final variable = detectVariable(funcBody);
            String substitutedBody = funcBody.replaceAll(variable, '($argValue)');
            return '($substitutedBody)';
          }
        }
      } catch (e) {
        return match.group(0)!;
      }
      return match.group(0)!;
    });

    final simpleFuncRegex = RegExp(r'Y(\d+)');
    processed = processed.replaceAllMapped(simpleFuncRegex, (match) {
        try {
            final funcIndex = int.parse(match.group(1)!) - 1;
            if (funcIndex >= 0 && funcIndex < appState.graphFunctions.length) {
                String funcBody = appState.graphFunctions[funcIndex];
                if (funcBody.isNotEmpty) return '($funcBody)';
            }
        } catch (e) { return match.group(0)!; }
        return match.group(0)!;
    });

    return processed;
  }

  static String detectVariable(String equation) {
    print('SOLVE: Auto-detecting variable in: "$equation"');
    
    final knownTokens = {
      'e', 'pi', 'sin', 'cos', 'tan', 'ln', 'log', 'sqrt', 'abs', 
      'exp', 'deg', 'rad', 'gamma', 'factorial'
    };
    
    final variablePattern = RegExp(r'\b([a-zA-Z])\b');
    final matches = variablePattern.allMatches(equation);
    
    final foundVariables = <String>{};
    for (final match in matches) {
      final variable = match.group(1)!.toLowerCase();
      if (!knownTokens.contains(variable)) {
        foundVariables.add(variable);
      }
    }
    
    print('SOLVE: Found potential variables: $foundVariables');
    
    final commonVariables = ['x', 'y', 'z', 't', 'n', 'a', 'b', 'c'];
    for (final common in commonVariables) {
      if (foundVariables.contains(common)) {
        print('SOLVE: Selected common variable: "$common"');
        return common;
      }
    }
    
    if (foundVariables.isNotEmpty) {
      final firstVar = foundVariables.first;
      print('SOLVE: Selected first variable: "$firstVar"');
      return firstVar;
    }
    
    print('SOLVE: No variables detected, defaulting to "x"');
    return 'x';
  }

  /// Normalizes complex number results and cleans up mathematical expressions
  static String normalizeComplexResult(String result) {
    if (result.isEmpty) return result;
    
    String normalized = result.trim();
    
    print('NORMALIZE: Input: "$normalized"');
    
    // Handle negative zero imaginary parts: "number + -0.0*I" -> "number"
    normalized = normalized.replaceAll(RegExp(r'\s*\+\s*-0(\.0*)?\s*\*?\s*I\b'), '');
    // Handle positive zero imaginary parts: "number + 0.0*I" -> "number"
    normalized = normalized.replaceAll(RegExp(r'\s*\+\s*0(\.0*)?\s*\*?\s*I\b'), '');
    // Handle negative zero with multiplication: "number + 0.0*I*digits" -> "number"
    normalized = normalized.replaceAll(RegExp(r'\s*\+\s*0\.0\s*\*\s*I\s*\*\s*\d+'), '');
    // Handle standalone imaginary zero: "0*I" -> "0"
    normalized = normalized.replaceAll(RegExp(r'^\s*0(\.0*)?\s*\*\s*I\s*$'), '0');
    
    // Convert remaining I to lowercase i
    normalized = normalized.replaceAll(RegExp(r'(\d+)\s*\*\s*I\b'), r'\1i');
    normalized = normalized.replaceAll(RegExp(r'\bI\b'), 'i');
    
    // Clean up spacing
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s*\+\s*'), ' + ');
    normalized = normalized.replaceAll(RegExp(r'\s*\-\s*'), ' - ');
    normalized = normalized.replaceAll(RegExp(r'\s*\*\s*'), '*');
    normalized = normalized.trim();
    
    // Handle pure real numbers that show as "5.0 + 0.0*I"  
    normalized = normalized.replaceAll(RegExp(r'^([+-]?\d+(?:\.\d+)?)\s*\+\s*0\.0\s*\*\s*I$'), r'\1');
    
    // Fix dangling operators (incomplete normalization)
    if (normalized.endsWith(' +') || normalized.endsWith(' -')) {
        normalized = normalized.substring(0, normalized.length - 2).trim();
    }
    
    // Fix Python-style exponents (**) to readable format
    normalized = normalized.replaceAll('**2', '²');
    normalized = normalized.replaceAll('**3', '³');
    normalized = normalized.replaceAllMapped(RegExp(r'\*\*(\d+)'), (m) => '^${m.group(1)}');
    
    // Clean up multiplication formatting for display
    normalized = normalized.replaceAllMapped(RegExp(r'(\d+)\s*\*\s*([a-zA-Z])(?!\*)'), (m) => '${m.group(1)}${m.group(2)}');
    
    // Final check for malformed results
    if (RegExp(r'^[\+\-\*\s]*$').hasMatch(normalized)) {
        normalized = result;
    }
    
    print('NORMALIZE: Output: "$normalized"');
    return normalized;
    }
}