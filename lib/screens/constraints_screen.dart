// lib/screens/constraints_screen.dart
//
// Analysis-hub module for Constraint Satisfaction Problems. CSP Round
// A scope: two tabs.
//
//   1. Diophantine — enumerate integer solutions to a system of
//      bounded linear/inequality constraints. The variable list
//      drives a Map<String, (min, max)> and the constraints list is
//      passed through CspSolver.solveDiophantine.
//
//   2. Cryptarithm — solve `WORD1 + WORD2 = WORD3` puzzles via
//      CspSolver.solveCryptarithm.
//
// Both tabs show the result in a copyable read-only block. Long-
// running solves are not yet routed through the persistent worker —
// typical CSP problems at this scale finish in milliseconds.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/csp_solver.dart';
import '../localization/app_localizations.dart';

class ConstraintsScreen extends StatefulWidget {
  const ConstraintsScreen({super.key});

  @override
  State<ConstraintsScreen> createState() => _ConstraintsScreenState();
}

class _ConstraintsScreenState extends State<ConstraintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
        title: Text(t.moduleConstraintsTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: t.constraintsTabDiophantine),
            Tab(text: t.constraintsTabCryptarithm),
            Tab(text: t.constraintsTabDsl),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_DiophantineTab(), _CryptarithmTab(), _DslTab()],
      ),
    );
  }
}

// === Diophantine tab ====================================================

class _DiophantineTab extends StatefulWidget {
  const _DiophantineTab();
  @override
  State<_DiophantineTab> createState() => _DiophantineTabState();
}

class _DiophantineTabState extends State<_DiophantineTab> {
  final _varsCtl = TextEditingController(text: 'x in 0..50\ny in 0..50');
  final _constraintsCtl =
      TextEditingController(text: '2*x + 3*y == 30\nx <= y');
  DiophantineResult? _result;
  bool _solving = false;

  @override
  void dispose() {
    _varsCtl.dispose();
    _constraintsCtl.dispose();
    super.dispose();
  }

  /// Parses one variable line. Accepts:
  ///   `name in min..max`
  /// Returns null on shape mismatch — caller surfaces an error per line.
  ({String name, int min, int max})? _parseVarLine(String line) {
    final m =
        RegExp(r'^([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(-?\d+)\s*\.\.\s*(-?\d+)$')
            .firstMatch(line.trim());
    if (m == null) return null;
    return (
      name: m.group(1)!,
      min: int.parse(m.group(2)!),
      max: int.parse(m.group(3)!),
    );
  }

  Future<void> _solve() async {
    final t = AppLocalizations.of(context);
    final varLines = _varsCtl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final variables = <String, ({int min, int max})>{};
    final parseErrors = <String>[];
    for (final line in varLines) {
      final v = _parseVarLine(line);
      if (v == null) {
        parseErrors.add('${t.constraintsBadVarLine}: $line');
        continue;
      }
      variables[v.name] = (min: v.min, max: v.max);
    }
    if (parseErrors.isNotEmpty) {
      setState(() => _result = DiophantineResult.failure(parseErrors.first));
      return;
    }
    final constraints = _constraintsCtl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    setState(() => _solving = true);
    final r = await CspSolver.solveDiophantine(
        variables: variables, constraints: constraints);
    if (!mounted) return;
    setState(() {
      _solving = false;
      _result = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.constraintsDiophantineIntro,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _varsCtl,
            maxLines: 4,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              labelText: t.constraintsVariablesLabel,
              helperText: t.constraintsVariablesHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _constraintsCtl,
            maxLines: 6,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              labelText: t.constraintsConstraintsLabel,
              helperText: t.constraintsConstraintsHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _solving ? null : _solve,
            icon: _solving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(t.constraintsSolveButton),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultBlock(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ResultBlock extends StatelessWidget {
  final DiophantineResult result;
  const _ResultBlock({required this.result});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (!result.ok) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(result.error!,
                  style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ],
        ),
      );
    }
    final lines = <String>[];
    for (var i = 0; i < result.solutions.length; i++) {
      final entries = result.solutions[i].entries
          .map((e) => '${e.key}=${e.value}')
          .join(', ');
      lines.add('${i + 1}.  $entries');
    }
    final body = lines.isEmpty ? t.constraintsNoSolutions : lines.join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              result.truncated
                  ? t.constraintsTruncatedHeader(result.solutions.length)
                  : t.constraintsSolutionsHeader(result.solutions.length),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (result.solutions.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: t.constraintsCopyResult,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: body));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.constraintsCopiedToast),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(
            body,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// === Cryptarithm tab ====================================================

class _CryptarithmTab extends StatefulWidget {
  const _CryptarithmTab();
  @override
  State<_CryptarithmTab> createState() => _CryptarithmTabState();
}

class _CryptarithmTabState extends State<_CryptarithmTab> {
  final _ctl = TextEditingController(text: 'SEND + MORE = MONEY');
  CryptarithmResult? _result;
  bool _solving = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    setState(() => _solving = true);
    final r = await CspSolver.solveCryptarithm(_ctl.text);
    if (!mounted) return;
    setState(() {
      _solving = false;
      _result = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.constraintsCryptarithmIntro,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _ctl,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            decoration: InputDecoration(
              labelText: t.constraintsCryptarithmInputLabel,
              hintText: 'SEND + MORE = MONEY',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _solving ? null : _solve,
            icon: _solving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(t.constraintsSolveButton),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _CryptarithmResultBlock(result: _result!),
          ],
        ],
      ),
    );
  }
}

// === DSL tab (CSP Round C) ==============================================

class _DslTab extends StatefulWidget {
  const _DslTab();
  @override
  State<_DslTab> createState() => _DslTabState();
}

class _DslTabState extends State<_DslTab> {
  static const _example = '''vars: x, y, z in 1..9
allDifferent(x, y, z)
x + y + z == 15''';

  final _ctl = TextEditingController(text: _example);
  DiophantineResult? _result;
  bool _solving = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    setState(() => _solving = true);
    final r = await CspSolver.solveDsl(_ctl.text);
    if (!mounted) return;
    setState(() {
      _solving = false;
      _result = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.constraintsDslIntro,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _ctl,
            minLines: 6,
            maxLines: 16,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              labelText: t.constraintsDslInputLabel,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _solving ? null : _solve,
            icon: _solving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(t.constraintsSolveButton),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultBlock(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _CryptarithmResultBlock extends StatelessWidget {
  final CryptarithmResult result;
  const _CryptarithmResultBlock({required this.result});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (!result.ok) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(result.error!,
                  style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ],
        ),
      );
    }
    final sorted = result.assignment.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final body = sorted.map((e) => '${e.key} = ${e.value}').join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.constraintsCryptarithmFoundHeader,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(
            body,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ],
    );
  }
}
