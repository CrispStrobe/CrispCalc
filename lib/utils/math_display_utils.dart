/// lib/utils/math_display_utils.dart
/// Shared utilities for mathematical expression formatting and display

class MathDisplayUtils {
  /// Converts mathematical expressions to LaTeX format for better rendering
  static String toLatexFormat(String expression) {
    String latex = expression;
    
    // Don't double-convert if already has LaTeX commands
    if (latex.contains(r'\')) {
      return latex;
    }

    // Convert mathematical constants first
    latex = latex.replaceAll('EulerGamma', r'\gamma');
    latex = latex.replaceAll('pi', r'\pi');
    latex = latex.replaceAll('infinity', r'\infty');
    latex = latex.replaceAll('oo', r'\infty');
    
    // Convert sqrt functions to LaTeX
    latex = latex.replaceAllMapped(RegExp(r'sqrt\(([^)]+)\)'), (match) {
      return r'\sqrt{' + match.group(1)! + r'}';
    });
    
    // Convert fractions (simple case a/b where a,b are simple expressions)
    latex = latex.replaceAllMapped(RegExp(r'\(([^)]+)\)/\(([^)]+)\)'), (match) {
      return r'\frac{' + match.group(1)! + r'}{' + match.group(2)! + r'}';
    });
    
    // Convert simple fractions like 1/2, x/3
    latex = latex.replaceAllMapped(RegExp(r'([a-zA-Z0-9]+)/([a-zA-Z0-9]+)'), (match) {
      return r'\frac{' + match.group(1)! + r'}{' + match.group(2)! + r'}';
    });
    
    // Convert powers - handle both simple and complex
    latex = latex.replaceAllMapped(RegExp(r'([a-zA-Z0-9)]+)\^([a-zA-Z0-9]+)'), (match) {
      return match.group(1)! + r'^{' + match.group(2)! + r'}';
    });
    
    // Handle more complex powers with parentheses
    latex = latex.replaceAllMapped(RegExp(r'([a-zA-Z0-9)]+)\^\(([^)]+)\)'), (match) {
      return match.group(1)! + r'^{' + match.group(2)! + r'}';
    });
    
    // Convert common functions to upright text
    latex = latex.replaceAllMapped(RegExp(r'\b(sin|cos|tan|ln|log|exp|abs|gamma|lim|det)\b'), (match) {
      return r'\' + match.group(1)!;
    });
    
    // Convert multiplication symbols
    latex = latex.replaceAll('*', r'\cdot ');
    
    // Handle modulo 
    latex = latex.replaceAll(' mod ', r' \bmod ');
    
    // Convert integrals
    latex = latex.replaceAllMapped(RegExp(r'integrate\(([^,]+),\s*([a-zA-Z])\)'), (match) {
      return r'\int ' + match.group(1)! + r' \, d' + match.group(2)!;
    });
    
    // Convert definite integrals
    latex = latex.replaceAllMapped(RegExp(r'integrate\(([^,]+),\s*\(([a-zA-Z]),\s*([^,]+),\s*([^)]+)\)\)'), (match) {
      return r'\int_{' + match.group(3)! + r'}^{' + match.group(4)! + r'} ' + 
             match.group(1)! + r' \, d' + match.group(2)!;
    });
    
    // Convert limits
    latex = latex.replaceAllMapped(RegExp(r'limit\(([^,]+),\s*([a-zA-Z]),\s*([^)]+)\)'), (match) {
      return r'\lim_{' + match.group(2)! + r' \to ' + match.group(3)! + r'} ' + match.group(1)!;
    });
    
    return latex;
  }

  /// Unified method for displaying expressions in history with proper LaTeX
  static String toHistoryDisplayLatex(String expression) {
    if (expression.isEmpty) return expression;
    
    String latex = expression;
    
    // If already contains LaTeX commands, just clean up
    if (latex.contains(r'\')) {
      // Clean up any malformed LaTeX
      latex = latex.replaceAll(r'\|', ''); // Remove cursor artifacts
      return latex;
    }
    
    // Apply full LaTeX conversion for plain text
    return toLatexFormat(latex);
  }

  /// Formats mathematical results for display with LaTeX when appropriate
  static String formatMathResult(String result) {
    if (result.isEmpty || result == 'Error') return result;
    
    String formatted = result;
    
    // Check if it contains mathematical expressions that would benefit from LaTeX
    if (formatted.contains('sqrt') || 
        formatted.contains('^') || 
        formatted.contains('pi') ||
        formatted.contains('/') ||
        formatted.contains('*')) {
      return toLatexFormat(formatted);
    }
    
    return formatted;
  }

  /// Creates a displayable string with both raw and LaTeX versions
  static Map<String, String> createDisplayFormats(String expression) {
    return {
      'raw': expression,
      'latex': toLatexFormat(expression),
    };
  }
}