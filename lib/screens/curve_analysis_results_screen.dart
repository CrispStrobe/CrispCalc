// lib/screens/curve_analysis_results_screen.dart
// Displays the formatted results of a curve analysis in a clear, readable report.

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../engine/analysis_engine.dart';
import '../localization/app_localizations.dart';

class CurveAnalysisResultsScreen extends StatelessWidget {
  final AnalysisResult results;
  final VoidCallback? onSaveAsFunction;
  final void Function(String name, String value)? onSaveResultAsVariable;

  const CurveAnalysisResultsScreen({
    super.key,
    required this.results,
    this.onSaveAsFunction,
    this.onSaveResultAsVariable,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Safely access the function string, providing a fallback.
    final functionString =
        results.originalFunction.isNotEmpty ? results.originalFunction : 'f(x)';

    return Scaffold(
      appBar: AppBar(
        title: Text(t.curveAnalysisOfFunction(functionString)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // Show errors if any
          if (results.errors.isNotEmpty)
            _ResultCard(
              title: t.curveResultWarnings,
              children: results.errors
                  .map((error) => ListTile(
                        leading:
                            const Icon(Icons.warning, color: Colors.orange),
                        title: Text(error,
                            style: const TextStyle(color: Colors.orange)),
                      ))
                  .toList(),
            ),

          _ResultCard(title: t.curveResultDerivatives, children: [
            _ResultTile(label: "f'(x)", value: results.firstDerivative),
            _ResultTile(label: "f''(x)", value: results.secondDerivative),
          ]),

          _ResultCard(title: t.curveResultKeyPoints, children: [
            _ResultTile(label: t.curveResultRoots, value: results.roots.join(', ')),
            _ResultTile(label: t.curveResultYIntercept, value: results.yIntercept),
          ]),

          _ResultCard(title: t.curveResultExtrema, children: [
            // Handle the case where there might be no extrema.
            if (results.extrema.isEmpty)
              Text(t.curveResultNoExtrema)
            else
              ...results.extrema.map((extremum) => ListTile(
                    visualDensity: VisualDensity.compact,
                    title: Text(t.translateClassification(extremum),
                        style: const TextStyle(fontSize: 16)),
                  )),
          ]),

          _ResultCard(title: t.curveResultInflectionPoints, children: [
            // Handle the case where there might be no inflection points.
            if (results.inflectionPoints.isEmpty)
              Text(t.curveResultNoInflection)
            else
              ...results.inflectionPoints.map((point) => ListTile(
                    visualDensity: VisualDensity.compact,
                    title: Text(t.curveResultPointPrefix(
                            t.translateClassification(point)),
                        style: const TextStyle(fontSize: 16)),
                  )),
          ]),
        ],
      ),
    );
  }
}

/// A styled card to group related analysis results.
class _ResultCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ResultCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A styled tile to display a single piece of analysis data (e.g., "Roots: [0, 1]").
/// It uses the flutter_math_fork package to render the value as LaTeX.
class _ResultTile extends StatelessWidget {
  final String label;
  final String? value;

  const _ResultTile({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    // Provide a fallback for null or empty values.
    final displayValue = (value == null || value!.isEmpty) ? 'N/A' : value!;

    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Math.tex(
          displayValue,
          textStyle: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          // Fallback in case the LaTeX string is invalid.
          onErrorFallback: (err) => Text(
            displayValue,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      ),
    );
  }
}
