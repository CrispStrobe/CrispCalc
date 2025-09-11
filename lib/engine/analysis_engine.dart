/// lib/engine/analysis_engine.dart
/// Orchestrates complex mathematical analyses by calling primitive operations
/// from the CalculatorEngine. The logic lives entirely in Dart.

import 'dart:convert';
import 'calculator_engine.dart';

class AnalysisEngine {
  final CalculatorEngine _engine;

  // The AnalysisEngine depends on the CalculatorEngine to do the actual work.
  AnalysisEngine(this._engine);

  /// Performs a full curve sketching analysis (Kurvendiskussion) in Dart.
  Future<Map<String, dynamic>> performCurveAnalysis(String function) async {
    final Map<String, dynamic> results = {
      'function': function,
    };

    try {
      // Step 1: Calculate Derivatives
      print("ANALYSIS: Differentiating...");
      final f1 = _engine.differentiate(function, 'x');
      results['derivative_f1'] = f1;
      final f2 = _engine.differentiate(f1, 'x');
      results['derivative_f2'] = f2;

      // Step 2: Find Y-Intercept (substitute x=0)
      print("ANALYSIS: Finding Y-Intercept...");
      final yInterceptExpr = function.replaceAll(RegExp(r'\bx\b'), '(0)');
      results['y_intercept'] = _engine.evaluate(yInterceptExpr);
      
      // Step 3: Find Roots (Nullstellen) by solving f(x) = 0
      print("ANALYSIS: Finding Roots...");
      results['roots'] = _engine.solve(function, 'x');

      // Step 4: Find Extrema (Minima/Maxima)
      print("ANALYSIS: Finding Extrema...");
      final criticalPointsStr = _engine.solve(f1, 'x');
      final criticalPoints = _parseSolutionList(criticalPointsStr);
      final List<Map<String, String>> extrema = [];
      for (final p in criticalPoints) {
        final f2AtP = _engine.evaluate(f2.replaceAll(RegExp(r'\bx\b'), '($p)'));
        final yAtP = _engine.evaluate(function.replaceAll(RegExp(r'\bx\b'), '($p)'));
        
        final f2Value = double.tryParse(f2AtP);
        if (f2Value != null) {
          if (f2Value > 0) {
            extrema.add({'x': p, 'y': yAtP, 'type': 'Minimum'});
          } else if (f2Value < 0) {
            extrema.add({'x': p, 'y': yAtP, 'type': 'Maximum'});
          }
        }
      }
      results['extrema'] = extrema;

      // Step 5: Find Inflection Points (Wendepunkte)
      print("ANALYSIS: Finding Inflection Points...");
      final inflectionPointsStr = _engine.solve(f2, 'x');
      final potentialInflectionPoints = _parseSolutionList(inflectionPointsStr);
       final List<Map<String, String>> inflectionPoints = [];
      for (final p in potentialInflectionPoints) {
         final yAtP = _engine.evaluate(function.replaceAll(RegExp(r'\bx\b'), '($p)'));
         inflectionPoints.add({'x': p, 'y': yAtP});
      }
      results['inflection_points'] = inflectionPoints;
      
    } catch (e) {
      print("Analysis Error: $e");
      throw Exception("Failed to perform analysis. Check function syntax.");
    }
    
    return results;
  }
  
  /// Helper to parse a solution string like "[1, -1, 0]" into a List<String>.
  List<String> _parseSolutionList(String solution) {
    if (solution.startsWith('[') && solution.endsWith(']')) {
      final content = solution.substring(1, solution.length - 1);
      if (content.isEmpty) return [];
      return content.split(',').map((s) => s.trim()).toList();
    }
    if (solution.isNotEmpty && !solution.contains('Error')) {
      return [solution];
    }
    return [];
  }
}