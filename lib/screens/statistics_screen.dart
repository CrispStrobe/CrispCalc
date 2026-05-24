// lib/screens/statistics_screen.dart
//
// Three-tab statistics workspace:
//   1. Descriptive: paste/type numbers, get count/mean/median/...
//   2. Regression: paste paired x,y data, get slope/intercept/R².
//   3. Distributions: normal CDF/quantile and binomial PMF/CDF.
//
// All math lives in lib/engine/statistics.dart and
// lib/engine/distributions.dart — this file is just the chrome.

import 'package:flutter/material.dart';

import '../engine/distributions.dart';
import '../engine/hypothesis_tests.dart';
import '../engine/statistics.dart';
import '../localization/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.statisticsTitle),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: t.statsTabDescriptive),
            Tab(text: t.statsTabRegression),
            Tab(text: t.statsTabDistributions),
            Tab(text: t.statsTabTests),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _DescriptiveTab(),
          _RegressionTab(),
          _DistributionsTab(),
          _TestsTab(),
        ],
      ),
    );
  }
}

// === Descriptive tab =====================================================

class _DescriptiveTab extends StatefulWidget {
  const _DescriptiveTab();

  @override
  State<_DescriptiveTab> createState() => _DescriptiveTabState();
}

class _DescriptiveTabState extends State<_DescriptiveTab> {
  final _input = TextEditingController(text: '2, 4, 4, 4, 5, 5, 7, 9');

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  List<double> _parse() {
    return _input.text
        .split(RegExp(r'[\s,;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(double.tryParse)
        .whereType<double>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _parse();
    DescriptiveStats? stats;
    String? err;
    try {
      if (data.isNotEmpty) stats = Statistics.describe(data);
    } catch (e) {
      err = e.toString();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _input,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Data (comma, space, or newline-separated)',
              border: OutlineInputBorder(),
              hintText: '1, 2, 3, 4, 5',
            ),
          ),
          const SizedBox(height: 16),
          if (err != null)
            Text('Error: $err',
                style: TextStyle(color: Theme.of(context).colorScheme.error))
          else if (stats != null)
            _StatsTable(stats)
          else
            const Text('Enter at least one number above.'),
        ],
      ),
    );
  }
}

class _StatsTable extends StatelessWidget {
  final DescriptiveStats s;
  const _StatsTable(this.s);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final rows = <_Row>[
      _Row(t.statsDescCount, s.count.toString()),
      _Row(t.statsDescSum, _fmt(s.sum)),
      _Row(t.statsDescMean, _fmt(s.mean)),
      _Row(t.statsDescMedian, _fmt(s.median)),
      _Row(t.statsDescMode,
          s.modes.isEmpty ? '—' : s.modes.map(_fmt).join(', ')),
      _Row(t.statsDescMin, _fmt(s.min)),
      _Row(t.statsDescMax, _fmt(s.max)),
      _Row(t.statsDescRange, _fmt(s.range)),
      _Row('${t.statsDescQ1} (25%)', _fmt(s.q1)),
      _Row('${t.statsDescQ3} (75%)', _fmt(s.q3)),
      _Row(t.statsDescIqr, _fmt(s.iqr)),
      _Row('${t.statsDescVariance} (n−1)', _fmt(s.sampleVariance)),
      _Row('${t.statsDescStddev} (n−1)', _fmt(s.sampleStddev)),
      _Row('${t.statsDescVariance} (n)', _fmt(s.populationVariance)),
      _Row('${t.statsDescStddev} (n)', _fmt(s.populationStddev)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final r in rows) _statRow(context, r),
          ],
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, _Row r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(r.label)),
          Text(r.value,
              style: const TextStyle(
                  fontFamily: 'monospace', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}

// === Regression tab ======================================================

class _RegressionTab extends StatefulWidget {
  const _RegressionTab();
  @override
  State<_RegressionTab> createState() => _RegressionTabState();
}

enum _RegressionModel { linear, polynomial, exponential }

class _RegressionTabState extends State<_RegressionTab> {
  final _xs = TextEditingController(text: '1, 2, 3, 4, 5');
  final _ys = TextEditingController(text: '2.1, 3.9, 6.0, 8.1, 10.0');
  _RegressionModel _model = _RegressionModel.linear;
  int _polyDegree = 2;

  @override
  void dispose() {
    _xs.dispose();
    _ys.dispose();
    super.dispose();
  }

  List<double> _parse(String s) => s
      .split(RegExp(r'[\s,;]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .map(double.tryParse)
      .whereType<double>()
      .toList();

  Widget _resultCard(BuildContext context, String headline, String formula,
      List<String> details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              formula,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
            const SizedBox(height: 12),
            for (final d in details) Text(d),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, List<double> xs, List<double> ys) {
    if (xs.isEmpty || ys.isEmpty) return const SizedBox.shrink();
    try {
      switch (_model) {
        case _RegressionModel.linear:
          final fit = Statistics.linearFit(xs, ys);
          return _resultCard(
            context,
            'Best-fit line:',
            'y = ${_fmt(fit.slope)}·x + ${_fmt(fit.intercept)}',
            [
              'Slope a = ${_fmt(fit.slope)}',
              'Intercept b = ${_fmt(fit.intercept)}',
              'R² = ${_fmt(fit.rSquared)}',
              'n = ${fit.count}',
            ],
          );
        case _RegressionModel.polynomial:
          final fit = Statistics.polynomialFit(xs, ys, _polyDegree);
          final terms = <String>[];
          for (var i = fit.coefficients.length - 1; i >= 0; i--) {
            final c = fit.coefficients[i];
            if (i == 0) {
              terms.add(_fmt(c));
            } else if (i == 1) {
              terms.add('${_fmt(c)}·x');
            } else {
              terms.add('${_fmt(c)}·x^$i');
            }
          }
          return _resultCard(
            context,
            'Best-fit polynomial (degree ${fit.degree}):',
            'y = ${terms.join(' + ')}',
            [
              for (var i = 0; i < fit.coefficients.length; i++)
                'c$i = ${_fmt(fit.coefficients[i])}',
              'R² = ${_fmt(fit.rSquared)}',
              'n = ${fit.count}',
            ],
          );
        case _RegressionModel.exponential:
          final fit = Statistics.expFit(xs, ys);
          return _resultCard(
            context,
            'Best-fit exponential:',
            'y = ${_fmt(fit.a)}·exp(${_fmt(fit.b)}·x)',
            [
              'a = ${_fmt(fit.a)}',
              'b = ${_fmt(fit.b)}',
              'R² (log-space) = ${_fmt(fit.rSquared)}',
              'n = ${fit.count}',
            ],
          );
      }
    } catch (e) {
      return Text('Error: $e',
          style: TextStyle(color: Theme.of(context).colorScheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final xs = _parse(_xs.text);
    final ys = _parse(_ys.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Linear'),
                selected: _model == _RegressionModel.linear,
                onSelected: (_) =>
                    setState(() => _model = _RegressionModel.linear),
              ),
              ChoiceChip(
                label: const Text('Polynomial'),
                selected: _model == _RegressionModel.polynomial,
                onSelected: (_) =>
                    setState(() => _model = _RegressionModel.polynomial),
              ),
              ChoiceChip(
                label: const Text('Exponential'),
                selected: _model == _RegressionModel.exponential,
                onSelected: (_) =>
                    setState(() => _model = _RegressionModel.exponential),
              ),
            ],
          ),
          if (_model == _RegressionModel.polynomial) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Degree: '),
                DropdownButton<int>(
                  value: _polyDegree,
                  items: [
                    for (final d in const [2, 3, 4, 5])
                      DropdownMenuItem(value: d, child: Text('$d')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _polyDegree = v);
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _xs,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'x values',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ys,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'y values',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _buildResults(context, xs, ys),
        ],
      ),
    );
  }
}

// === Distributions tab ===================================================

class _DistributionsTab extends StatefulWidget {
  const _DistributionsTab();
  @override
  State<_DistributionsTab> createState() => _DistributionsTabState();
}

class _DistributionsTabState extends State<_DistributionsTab> {
  // Normal
  final _normMean = TextEditingController(text: '0');
  final _normSd = TextEditingController(text: '1');
  final _normX = TextEditingController(text: '1.96');
  final _normP = TextEditingController(text: '0.975');

  // Binomial
  final _binN = TextEditingController(text: '10');
  final _binP = TextEditingController(text: '0.5');
  final _binK = TextEditingController(text: '5');

  @override
  void dispose() {
    for (final c in [_normMean, _normSd, _normX, _normP, _binN, _binP, _binK]) {
      c.dispose();
    }
    super.dispose();
  }

  Normal? _normal() {
    final m = double.tryParse(_normMean.text);
    final s = double.tryParse(_normSd.text);
    if (m == null || s == null || s <= 0) return null;
    return Normal(mean: m, stddev: s);
  }

  Binomial? _binom() {
    final n = int.tryParse(_binN.text);
    final p = double.tryParse(_binP.text);
    if (n == null || n < 0 || p == null || p < 0 || p > 1) return null;
    return Binomial(n: n, p: p);
  }

  @override
  Widget build(BuildContext context) {
    final norm = _normal();
    final bin = _binom();
    final x = double.tryParse(_normX.text);
    final p = double.tryParse(_normP.text);
    final k = int.tryParse(_binK.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Normal distribution',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_normMean, 'mean μ')),
              const SizedBox(width: 8),
              Expanded(child: _field(_normSd, 'stddev σ')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(_normX, 'x for CDF')),
              const SizedBox(width: 8),
              Expanded(child: _field(_normP, 'p for quantile')),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (norm == null)
                    const Text('Enter μ and σ > 0 to compute normal values.')
                  else ...[
                    if (x != null) _resultRow('PDF(x)', _fmt(norm.pdf(x))),
                    if (x != null)
                      _resultRow('CDF(x) = P(X ≤ x)', _fmt(norm.cdf(x))),
                    if (p != null && p >= 0 && p <= 1)
                      _resultRow('quantile(p)', _fmt(norm.quantile(p))),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Binomial distribution',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_binN, 'n (trials)')),
              const SizedBox(width: 8),
              Expanded(child: _field(_binP, 'p (success)')),
              const SizedBox(width: 8),
              Expanded(child: _field(_binK, 'k')),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bin == null)
                    const Text(
                        'Enter n ≥ 0 and 0 ≤ p ≤ 1 to compute binomial values.')
                  else ...[
                    _resultRow('Mean', _fmt(bin.mean)),
                    _resultRow('Variance', _fmt(bin.variance)),
                    _resultRow('Stddev', _fmt(bin.stddev)),
                    if (k != null) ...[
                      _resultRow('P(X = k)', _fmt(bin.pmf(k))),
                      _resultRow('P(X ≤ k)', _fmt(bin.cdf(k))),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );

  Widget _resultRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'monospace', fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// === Hypothesis tests tab ================================================

enum _TestKind {
  oneSampleT,
  twoSampleT,
  pairedT,
  anovaOneWay,
  chiSquareGof,
  chiSquareIndep,
  fisherExact,
  pairedSign,
  wilcoxonRankSum,
}

class _TestsTab extends StatefulWidget {
  const _TestsTab();
  @override
  State<_TestsTab> createState() => _TestsTabState();
}

class _TestsTabState extends State<_TestsTab> {
  _TestKind _kind = _TestKind.oneSampleT;

  // One-sample t-test inputs.
  final _oneSampleData = TextEditingController(text: '172, 174, 168, 180, 176');
  final _oneSampleMu = TextEditingController(text: '170');

  // Two-sample t-test inputs.
  final _twoSampleA = TextEditingController(text: '8, 9, 10, 10, 11, 12');
  final _twoSampleB = TextEditingController(text: '10, 11, 12, 12, 13, 14');

  // ANOVA inputs — one line per group, semicolon-separated groups
  // OR a single newline-separated multi-line input. We use newlines
  // (each line is a group's space/comma-separated samples).
  final _anovaGroups = TextEditingController(
      text: '6, 7, 8, 7, 7\n7, 8, 9, 8, 8\n9, 10, 11, 10, 10');

  // Paired t-test inputs.
  final _pairedBefore =
      TextEditingController(text: '10, 12, 14, 13, 15, 11, 14, 10, 13, 12');
  final _pairedAfter =
      TextEditingController(text: '7, 11, 10, 11, 12, 9, 10, 9, 10, 10');

  // Chi-square GOF inputs.
  final _gofObserved = TextEditingController(text: '9, 11, 10, 12, 9, 9');
  final _gofExpected = TextEditingController(text: '10, 10, 10, 10, 10, 10');

  // Chi-square independence inputs. One row per line, columns
  // separated by commas/spaces.
  final _indepTable = TextEditingController(text: '10, 20\n20, 10\n15, 15');

  // Fisher's exact inputs — a single line "a, b, c, d" where the 2×2
  // table is [[a, b], [c, d]].
  final _fisherTable = TextEditingController(text: '3, 1, 1, 3');

  // Paired sign test inputs. Reuses the paired t-test layout (before /
  // after) but treats the differences nonparametrically — robust to
  // outliers and non-normality at the cost of statistical power.
  final _signBefore =
      TextEditingController(text: '10, 12, 14, 13, 15, 11, 14, 10, 13, 12');
  final _signAfter =
      TextEditingController(text: '7, 11, 10, 11, 12, 9, 10, 9, 10, 10');

  // Wilcoxon rank-sum (Mann-Whitney U) inputs.
  final _wilcoxonA = TextEditingController(text: '8, 9, 10, 10, 11, 12');
  final _wilcoxonB = TextEditingController(text: '10, 11, 12, 12, 13, 14');

  // Significance level.
  final _alpha = TextEditingController(text: '0.05');

  @override
  void dispose() {
    for (final c in [
      _oneSampleData,
      _oneSampleMu,
      _twoSampleA,
      _twoSampleB,
      _anovaGroups,
      _pairedBefore,
      _pairedAfter,
      _gofObserved,
      _gofExpected,
      _indepTable,
      _fisherTable,
      _signBefore,
      _signAfter,
      _wilcoxonA,
      _wilcoxonB,
      _alpha,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<double> _parse(String s) => s
      .split(RegExp(r'[\s,;]+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .map(double.tryParse)
      .whereType<double>()
      .toList();

  Widget _resultRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'monospace', fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _verdictBlock(BuildContext context, bool rejects) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: rejects ? scheme.errorContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(rejects ? Icons.cancel : Icons.check_circle,
              color: rejects
                  ? scheme.onErrorContainer
                  : scheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rejects
                  ? 'Reject H₀ at α (the data are inconsistent with H₀).'
                  : 'Fail to reject H₀ at α (the data are consistent with H₀).',
              style: TextStyle(
                color: rejects
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOneSample(BuildContext context) {
    final alpha = double.tryParse(_alpha.text) ?? 0.05;
    final data = _parse(_oneSampleData.text);
    final mu0 = double.tryParse(_oneSampleMu.text);
    String? err;
    TTestResult? r;
    if (data.length >= 2 && mu0 != null) {
      try {
        r = HypothesisTests.oneSampleT(data: data, hypothesizedMean: mu0);
      } catch (e) {
        err = e.toString();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _oneSampleData,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Sample data',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _oneSampleMu,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Hypothesized mean μ₀',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (err != null)
          Text(err,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (r != null) ...[
          _resultRow('Sample mean x̄', _fmt(r.sampleMean)),
          _resultRow('Sample stddev s', _fmt(r.sampleStddev)),
          _resultRow('Sample size n', '${r.sampleSize}'),
          _resultRow('Hypothesized μ₀', _fmt(r.hypothesizedMean)),
          _resultRow('t-statistic', _fmt(r.statistic)),
          _resultRow('Degrees of freedom', '${r.df}'),
          _resultRow('p-value (two-sided)', _fmt(r.pValueTwoSided)),
          _resultRow('p-value (upper tail)', _fmt(r.pValueOneSidedUpper)),
          _resultRow('p-value (lower tail)', _fmt(r.pValueOneSidedLower)),
          _verdictBlock(context, r.rejectsAt(alpha)),
        ],
      ],
    );
  }

  Widget _buildTwoSample(BuildContext context) {
    final alpha = double.tryParse(_alpha.text) ?? 0.05;
    final a = _parse(_twoSampleA.text);
    final b = _parse(_twoSampleB.text);
    String? err;
    TwoSampleTResult? r;
    if (a.length >= 2 && b.length >= 2) {
      try {
        r = HypothesisTests.welchT(sample1: a, sample2: b);
      } catch (e) {
        err = e.toString();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _twoSampleA,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Sample 1',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _twoSampleB,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Sample 2',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (err != null)
          Text(err,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (r != null) ...[
          _resultRow('Mean₁ x̄₁', _fmt(r.mean1)),
          _resultRow('Mean₂ x̄₂', _fmt(r.mean2)),
          _resultRow('Stddev₁ s₁', _fmt(r.stddev1)),
          _resultRow('Stddev₂ s₂', _fmt(r.stddev2)),
          _resultRow('Sizes n₁, n₂', '${r.n1}, ${r.n2}'),
          _resultRow('t-statistic (Welch)', _fmt(r.statistic)),
          _resultRow('df (Welch-Satterthwaite)', _fmt(r.df)),
          _resultRow('p-value (two-sided)', _fmt(r.pValueTwoSided)),
          _resultRow('p-value (upper tail)', _fmt(r.pValueOneSidedUpper)),
          _resultRow('p-value (lower tail)', _fmt(r.pValueOneSidedLower)),
          _verdictBlock(context, r.rejectsAt(alpha)),
        ],
      ],
    );
  }

  Widget _buildPaired(BuildContext context) {
    final alpha = double.tryParse(_alpha.text) ?? 0.05;
    final before = _parse(_pairedBefore.text);
    final after = _parse(_pairedAfter.text);
    String? err;
    TTestResult? r;
    if (before.length >= 2 && after.length == before.length) {
      try {
        r = HypothesisTests.pairedT(before: before, after: after);
      } catch (e) {
        err = e.toString();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _pairedBefore,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Before',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pairedAfter,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'After',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (err != null)
          Text(err,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (r != null) ...[
          _resultRow('Mean difference', _fmt(r.sampleMean)),
          _resultRow('Stddev of diffs', _fmt(r.sampleStddev)),
          _resultRow('Pairs n', '${r.sampleSize}'),
          _resultRow('t-statistic', _fmt(r.statistic)),
          _resultRow('Degrees of freedom', '${r.df}'),
          _resultRow('p-value (two-sided)', _fmt(r.pValueTwoSided)),
          _verdictBlock(context, r.rejectsAt(alpha)),
        ],
      ],
    );
  }

  Widget _buildAnova(BuildContext context) {
    final alpha = double.tryParse(_alpha.text) ?? 0.05;
    final lines = _anovaGroups.text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final groups = lines.map(_parse).toList();
    String? err;
    AnovaResult? r;
    if (groups.length >= 2 && groups.every((g) => g.isNotEmpty)) {
      try {
        r = HypothesisTests.anovaOneWay(groups);
      } catch (e) {
        err = e.toString();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _anovaGroups,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Groups (one per line)',
            helperText: 'Each line is one group, comma- or space-separated.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (err != null)
          Text(err,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (r != null) ...[
          for (var i = 0; i < r.groupMeans.length; i++)
            _resultRow('Group ${i + 1} (n=${r.groupSizes[i]})',
                'mean ${_fmt(r.groupMeans[i])}'),
          _resultRow('Grand mean', _fmt(r.grandMean)),
          _resultRow('SS between', _fmt(r.ssBetween)),
          _resultRow('SS within', _fmt(r.ssWithin)),
          _resultRow('df (between, within)', '${r.dfBetween}, ${r.dfWithin}'),
          _resultRow('MS between', _fmt(r.msBetween)),
          _resultRow('MS within', _fmt(r.msWithin)),
          _resultRow('F-statistic', _fmt(r.fStatistic)),
          _resultRow('p-value (upper tail)', _fmt(r.pValue)),
          _verdictBlock(context, r.rejectsAt(alpha)),
        ],
      ],
    );
  }

  Widget _buildIndependence(BuildContext context) {
    final alpha = double.tryParse(_alpha.text) ?? 0.05;
    final lines =
        _indepTable.text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final table = lines.map(_parse).toList();
    String? err;
    ChiSquareIndependenceResult? r;
    if (table.length >= 2 &&
        table.first.length >= 2 &&
        table.every((row) => row.length == table.first.length)) {
      try {
        r = HypothesisTests.chiSquareIndependence(table);
      } catch (e) {
        err = e.toString();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _indepTable,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Contingency table (one row per line)',
            helperText: 'Each line is a row, comma- or space-separated.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (err != null)
          Text(err,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (r != null) ...[
          _resultRow('χ² statistic', _fmt(r.statistic)),
          _resultRow('Degrees of freedom', '${r.df}'),
          _resultRow('Grand total', _fmt(r.grandTotal)),
          _resultRow('p-value (upper tail)', _fmt(r.pValue)),
          _verdictBlock(context, r.rejectsAt(alpha)),
        ],
      ],
    );
  }

  Widget _buildFisher(BuildContext context) {
    final alpha = double.tryParse(_alpha.text) ?? 0.05;
    final ints = _fisherTable.text
        .split(RegExp(r'[\s,;]+'))
        .where((t) => t.isNotEmpty)
        .map((s) => int.tryParse(s.trim()))
        .toList();
    String? err;
    FisherExactResult? r;
    if (ints.length == 4 && ints.every((v) => v != null)) {
      try {
        r = HypothesisTests.fisherExact2x2(
            ints[0]!, ints[1]!, ints[2]!, ints[3]!);
      } catch (e) {
        err = e.toString();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _fisherTable,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: '2×2 cells: a, b, c, d',
            helperText: 'Row 1 = [a, b]; row 2 = [c, d].',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (err != null)
          Text(err,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (r != null) ...[
          _resultRow('a (row1,col1)', '${r.a}'),
          _resultRow('b (row1,col2)', '${r.b}'),
          _resultRow('c (row2,col1)', '${r.c}'),
          _resultRow('d (row2,col2)', '${r.d}'),
          _resultRow('P(observed)', _fmt(r.pObserved)),
          _resultRow('p-value (two-sided)', _fmt(r.pValueTwoSided)),
          _resultRow('p-value (upper)', _fmt(r.pValueOneSidedUpper)),
          _resultRow('p-value (lower)', _fmt(r.pValueOneSidedLower)),
          _verdictBlock(context, r.rejectsAt(alpha)),
        ],
      ],
    );
  }

  Widget _buildSign(BuildContext context) {
    final alpha = double.tryParse(_alpha.text) ?? 0.05;
    final before = _parse(_signBefore.text);
    final after = _parse(_signAfter.text);
    String? err;
    SignTestResult? r;
    if (before.isNotEmpty && after.length == before.length) {
      try {
        r = HypothesisTests.pairedSign(before: before, after: after);
      } catch (e) {
        err = e.toString();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _signBefore,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Before',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _signAfter,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'After',
            helperText: 'Pairs with zero difference are dropped.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (err != null)
          Text(err,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (r != null) ...[
          _resultRow('Positives (before > after)', '${r.positives}'),
          _resultRow('Negatives (before < after)', '${r.negatives}'),
          _resultRow('Ties (excluded)', '${r.zeros}'),
          _resultRow('Effective n', '${r.n}'),
          _resultRow('p-value (two-sided)', _fmt(r.pValueTwoSided)),
          _verdictBlock(context, r.rejectsAt(alpha)),
        ],
      ],
    );
  }

  Widget _buildWilcoxon(BuildContext context) {
    final alpha = double.tryParse(_alpha.text) ?? 0.05;
    final a = _parse(_wilcoxonA.text);
    final b = _parse(_wilcoxonB.text);
    String? err;
    WilcoxonRankSumResult? r;
    if (a.isNotEmpty && b.isNotEmpty) {
      try {
        r = HypothesisTests.wilcoxonRankSum(sample1: a, sample2: b);
      } catch (e) {
        err = e.toString();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _wilcoxonA,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Sample 1',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _wilcoxonB,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Sample 2',
            helperText: 'Normal-approximation p-value; reliable for n ≳ 10.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (err != null)
          Text(err,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (r != null) ...[
          _resultRow('Rank sum R₁', _fmt(r.rankSum1)),
          _resultRow('U₁', _fmt(r.u1)),
          _resultRow('U₂', _fmt(r.u2)),
          _resultRow('n₁ / n₂', '${r.n1} / ${r.n2}'),
          _resultRow('z statistic', _fmt(r.z)),
          _resultRow('p-value (two-sided)', _fmt(r.pValueTwoSided)),
          _verdictBlock(context, r.rejectsAt(alpha)),
        ],
      ],
    );
  }

  Widget _buildGof(BuildContext context) {
    final alpha = double.tryParse(_alpha.text) ?? 0.05;
    final observed = _parse(_gofObserved.text);
    final expected = _parse(_gofExpected.text);
    String? err;
    ChiSquareGofResult? r;
    if (observed.length >= 2 && expected.length == observed.length) {
      try {
        r = HypothesisTests.chiSquareGof(
            observed: observed, expected: expected);
      } catch (e) {
        err = e.toString();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _gofObserved,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Observed counts',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _gofExpected,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Expected counts',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (err != null)
          Text(err,
              style: TextStyle(color: Theme.of(context).colorScheme.error))
        else if (r != null) ...[
          _resultRow('χ² statistic', _fmt(r.statistic)),
          _resultRow('Degrees of freedom', '${r.df}'),
          _resultRow('p-value (upper tail)', _fmt(r.pValue)),
          _verdictBlock(context, r.rejectsAt(alpha)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Test picker.
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('One-sample t'),
                selected: _kind == _TestKind.oneSampleT,
                onSelected: (_) => setState(() => _kind = _TestKind.oneSampleT),
              ),
              ChoiceChip(
                label: const Text('Two-sample t (Welch)'),
                selected: _kind == _TestKind.twoSampleT,
                onSelected: (_) => setState(() => _kind = _TestKind.twoSampleT),
              ),
              ChoiceChip(
                label: const Text('Paired t'),
                selected: _kind == _TestKind.pairedT,
                onSelected: (_) => setState(() => _kind = _TestKind.pairedT),
              ),
              ChoiceChip(
                label: const Text('ANOVA (one-way)'),
                selected: _kind == _TestKind.anovaOneWay,
                onSelected: (_) =>
                    setState(() => _kind = _TestKind.anovaOneWay),
              ),
              ChoiceChip(
                label: const Text('χ² goodness-of-fit'),
                selected: _kind == _TestKind.chiSquareGof,
                onSelected: (_) =>
                    setState(() => _kind = _TestKind.chiSquareGof),
              ),
              ChoiceChip(
                label: const Text('χ² independence'),
                selected: _kind == _TestKind.chiSquareIndep,
                onSelected: (_) =>
                    setState(() => _kind = _TestKind.chiSquareIndep),
              ),
              ChoiceChip(
                label: const Text("Fisher's exact 2×2"),
                selected: _kind == _TestKind.fisherExact,
                onSelected: (_) =>
                    setState(() => _kind = _TestKind.fisherExact),
              ),
              ChoiceChip(
                label: const Text('Paired sign'),
                selected: _kind == _TestKind.pairedSign,
                onSelected: (_) => setState(() => _kind = _TestKind.pairedSign),
              ),
              ChoiceChip(
                label: const Text('Wilcoxon rank-sum'),
                selected: _kind == _TestKind.wilcoxonRankSum,
                onSelected: (_) =>
                    setState(() => _kind = _TestKind.wilcoxonRankSum),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Common: significance level.
          SizedBox(
            width: 200,
            child: TextField(
              controller: _alpha,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Significance level α',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: () {
                switch (_kind) {
                  case _TestKind.oneSampleT:
                    return _buildOneSample(context);
                  case _TestKind.twoSampleT:
                    return _buildTwoSample(context);
                  case _TestKind.pairedT:
                    return _buildPaired(context);
                  case _TestKind.anovaOneWay:
                    return _buildAnova(context);
                  case _TestKind.chiSquareGof:
                    return _buildGof(context);
                  case _TestKind.chiSquareIndep:
                    return _buildIndependence(context);
                  case _TestKind.fisherExact:
                    return _buildFisher(context);
                  case _TestKind.pairedSign:
                    return _buildSign(context);
                  case _TestKind.wilcoxonRankSum:
                    return _buildWilcoxon(context);
                }
              }(),
            ),
          ),
        ],
      ),
    );
  }
}

// === Shared formatting helper ============================================

String _fmt(double v) {
  if (!v.isFinite) return v.toString();
  if (v == 0) return '0';
  final abs = v.abs();
  if (abs >= 1e9 || (abs > 0 && abs < 1e-4)) {
    return v.toStringAsExponential(4);
  }
  var text = v.toStringAsFixed(6);
  if (text.contains('.')) {
    text = text.replaceAll(RegExp(r'0+$'), '');
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  }
  return text;
}
