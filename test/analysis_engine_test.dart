import 'package:flutter_test/flutter_test.dart';
import 'package:crisp_calc/engine/calculator_engine.dart';
import 'package:crisp_calc/engine/analysis_engine.dart';

// These tests exercise the analysis pipeline without the native bridge — the
// underlying CalculatorEngine returns "Error: ... requires native library" for
// every operation. The point is to confirm the analysis engine handles those
// errors gracefully and produces structured AnalysisResult objects.

void main() {
  late AnalysisEngine analysis;

  setUpAll(() {
    analysis = AnalysisEngine(CalculatorEngine());
  });

  test('performCurveAnalysis returns a result for any input', () async {
    final result = await analysis.performCurveAnalysis('x^2 - 1');
    expect(result, isA<AnalysisResult>());
    expect(result.originalFunction, equals('x^2 - 1'));
  });

  test('invalid functions produce errors rather than throwing', () async {
    final result = await analysis.performCurveAnalysis('');
    expect(result.errors, isNotEmpty);
  });

  test('result fields are always strings (or lists of strings), never null',
      () async {
    final result = await analysis.performCurveAnalysis('x');
    expect(result.firstDerivative, isA<String>());
    expect(result.secondDerivative, isA<String>());
    expect(result.yIntercept, isA<String>());
    expect(result.roots, isA<List<String>>());
    expect(result.extrema, isA<List<String>>());
    expect(result.inflectionPoints, isA<List<String>>());
    expect(result.errors, isA<List<String>>());
  });
}
