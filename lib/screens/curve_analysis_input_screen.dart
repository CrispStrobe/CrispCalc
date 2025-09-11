/// lib/screens/curve_analysis_input_screen.dart
/// Input screen for the curve sketching module (Kurvendiskussion).

import 'package:flutter/material.dart';
import '../engine/calculator_engine.dart';
import '../engine/analysis_engine.dart';
import 'curve_analysis_results_screen.dart';

class CurveAnalysisInputScreen extends StatefulWidget {
  const CurveAnalysisInputScreen({super.key});

  @override
  State<CurveAnalysisInputScreen> createState() => _CurveAnalysisInputScreenState();
}

class _CurveAnalysisInputScreenState extends State<CurveAnalysisInputScreen> {
  final _controller = TextEditingController(text: 'x^3 - 3*x');
  
  // The input screen needs both engines to perform the analysis.
  final _calculatorEngine = CalculatorEngine();
  late final AnalysisEngine _analysisEngine;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the analysis engine with the calculator engine via dependency injection.
    _analysisEngine = AnalysisEngine(_calculatorEngine);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Runs the analysis and navigates to the results screen.
  Future<void> _runAnalysis() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a function.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Call the main Dart-based analysis method.
      final results = await _analysisEngine.performCurveAnalysis(_controller.text);
      
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => CurveAnalysisResultsScreen(results: results),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during analysis: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curve Sketching'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter a function to analyze:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Function f(x)',
                border: OutlineInputBorder(),
                prefixText: 'f(x) = ',
              ),
              onSubmitted: (_) => _runAnalysis(),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _runAnalysis,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Analyze'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}