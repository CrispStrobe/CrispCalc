/// lib/screens/curve_analysis_results_screen.dart
/// Displays the formatted results of a curve analysis in a clear, readable report.

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class CurveAnalysisResultsScreen extends StatelessWidget {
  final Map<String, dynamic> results;
  const CurveAnalysisResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    // Safely access the function string, providing a fallback.
    final functionString = results['function']?.toString() ?? 'f(x)';

    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis of f(x) = $functionString'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _ResultCard(title: 'Derivatives', children: [
            _ResultTile(label: "f'(x)", value: results['derivative_f1']),
            _ResultTile(label: "f''(x)", value: results['derivative_f2']),
          ]),
          _ResultCard(title: 'Key Points', children: [
            _ResultTile(label: 'Roots (Nullstellen)', value: results['roots'].toString()),
            _ResultTile(label: 'Y-Intercept', value: results['y_intercept'].toString()),
          ]),
          _ResultCard(title: 'Extrema (Minima/Maxima)', children: [
            // Handle the case where there might be no extrema.
            if ((results['extrema'] as List).isEmpty)
              const Text('No extrema found.'),
            for (var p in (results['extrema'] as List))
              _ResultTile(label: p['type'], value: '( ${p['x']} | ${p['y']} )'),
          ]),
          _ResultCard(title: 'Inflection Points (Wendepunkte)', children: [
            // Handle the case where there might be no inflection points.
            if ((results['inflection_points'] as List).isEmpty)
              const Text('No inflection points found.'),
            for (var p in (results['inflection_points'] as List))
              _ResultTile(label: 'Point', value: '( ${p['x']} | ${p['y']} )'),
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