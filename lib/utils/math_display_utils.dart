/// lib/utils/math_display_utils.dart
/// Shared utilities for mathematical expression formatting and display

class MathDisplayUtils {
  /// Converts mathematical expressions to LaTeX format for better rendering
  static String toLatexFormat(String expression) {
    String latex = expression;
    
    // Convert sqrt functions to LaTeX
    latex = latex.replaceAllMapped(RegExp(r'sqrt\(([^)]+)\)'), (match) {
      return r'\sqrt{' + match.group(1)! + r'}';
    });
    
    // Convert common mathematical constants
    latex = latex.replaceAll('pi', r'\pi');
    latex = latex.replaceAll('infinity', r'\infty');
    latex = latex.replaceAll('oo', r'\infty');
    
    // Convert fractions (simple case a/b where a,b are simple expressions)
    latex = latex.replaceAllMapped(RegExp(r'([a-zA-Z0-9]+)/([a-zA-Z0-9]+)'), (match) {
      return r'\frac{' + match.group(1)! + r'}{' + match.group(2)! + r'}';
    });
    
    // Convert powers
    latex = latex.replaceAllMapped(RegExp(r'([a-zA-Z0-9]+)\^([a-zA-Z0-9]+)'), (match) {
      return match.group(1)! + r'^{' + match.group(2)! + r'}';
    });
    
    // Convert common functions to upright text
    latex = latex.replaceAll(RegExp(r'\b(sin|cos|tan|ln|log|exp|abs)\b'), r'\\\1');
    
    return latex;
  }

  /// Formats mathematical results for display with LaTeX when appropriate
  static String formatMathResult(String result) {
    if (result.isEmpty || result == 'Error') return result;
    
    String formatted = result;
    
    // Check if it contains mathematical expressions that would benefit from LaTeX
    if (formatted.contains('sqrt') || 
        formatted.contains('^') || 
        formatted.contains('pi') ||
        formatted.contains('/')) {
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