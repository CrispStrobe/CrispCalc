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

import '../engine/app_state.dart';
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
    // Round 73: if a DSL worked-example was tapped, the AppState
    // slot will be populated. Jump directly to the Free-form tab
    // so the user lands on the editor (the _DslTab itself drains
    // the slot + sets the program text in its own initState).
    if (AppState().pendingDslProgramId != null) {
      _tabs.index = 2;
    }
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
      // Optimization mode is always one assignment — drop the
      // numbering so the result reads "x=3, y=4" rather than
      // "1. x=3, y=4".
      lines.add(result.objective != null ? entries : '${i + 1}.  $entries');
    }
    final body = lines.isEmpty ? t.constraintsNoSolutions : lines.join('\n');
    // Round 74: optimization results get a dedicated header showing
    // the optimal objective value; enumeration results keep the
    // "N solutions" header (or "first N" when truncated).
    final headerText = result.objective != null
        ? t.constraintsOptimalHeader(result.objective!)
        : result.truncated
            ? t.constraintsTruncatedHeader(result.solutions.length)
            : t.constraintsSolutionsHeader(result.solutions.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              headerText,
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
  // Round 72 gallery: each entry's `program` is a complete DSL
  // text that replaces the TextField on pick. The `id` doubles as
  // the i18n key for the localized title.
  static const List<({String id, String program})> _gallery = [
    (
      id: 'magicSum',
      program: '''vars: x, y, z in 1..9
allDifferent(x, y, z)
x + y + z == 15''',
    ),
    (
      // Classic 3×3 magic square: 9 distinct digits 1..9 with
      // every row, column, and main diagonal summing to 15.
      id: 'magicSquare3',
      program: '''vars: a, b, c, d, e, f, g, h, i in 1..9
allDifferent(a, b, c, d, e, f, g, h, i)
a + b + c == 15
d + e + f == 15
g + h + i == 15
a + d + g == 15
b + e + h == 15
c + f + i == 15
a + e + i == 15
c + e + g == 15''',
    ),
    (
      // Four mutually-adjacent regions colored with 3 colors.
      // Adjacency: 1-2, 1-3, 1-4, 2-3, 2-4, 3-4 — a complete
      // K4 graph, which is NOT 3-colorable, so this enumerates
      // zero solutions. Edit to drop one edge for solutions.
      id: 'mapColoring',
      program: '''vars: r1, r2, r3, r4 in 1..3
r1 != r2
r1 != r3
r2 != r3
r3 != r4
r2 != r4''',
    ),
    (
      // Triples of strictly-increasing positive integers summing
      // to 20: a < b < c, a+b+c=20, with a,b,c in 1..20.
      id: 'orderedTriples',
      program: '''vars: a, b, c in 1..20
a + b + c == 20
a < b
b < c''',
    ),
    (
      // Round 74: textbook coin-change. Pay 17 cents with the
      // fewest coins drawn from {1, 5, 10, 25}. The minimize
      // directive returns the unique optimum (one 10 + one 5 +
      // two 1s = four coins) plus the objective value.
      id: 'coinChangeMin',
      program: '''vars: pennies in 0..17
vars: nickels in 0..3
vars: dimes in 0..1
vars: quarters in 0..0
pennies + 5*nickels + 10*dimes + 25*quarters == 17
minimize pennies + nickels + dimes + quarters''',
    ),
    (
      // Round 77: single-machine scheduling with minimum makespan.
      // Three tasks of durations 4, 3, 2 must run without overlap;
      // the `noOverlap` overlay enforces pairwise disjointness on
      // the half-open intervals [start, start+duration). The
      // makespan variable bounds each task's end and is what we
      // minimize. Optimal makespan = 4+3+2 = 9; in this instance
      // the solver returns one of the equally-good orderings.
      id: 'schedulingMakespan',
      program: '''vars: s1, s2, s3 in 0..9
vars: makespan in 0..9
noOverlap(s1=4, s2=3, s3=2)
s1 + 4 <= makespan
s2 + 3 <= makespan
s3 + 2 <= makespan
minimize makespan''',
    ),
    (
      // Round 80: parallel-resource scheduling. Three tasks share a
      // renewable resource of capacity 2: task s1 alone consumes the
      // whole resource (demand 2, duration 2), while s2 and s3 each
      // demand 1 and so can run in parallel with each other. Total
      // work = 2·2 + 3·1 + 4·1 = 11; with capacity 2 the makespan
      // lower bound is ⌈11/2⌉ = 6. Achieved e.g. by running s2 + s3
      // parallel from t=0..3, s3 alone t=3..4, then s1 from t=4..6.
      id: 'cumulativeScheduling',
      program: '''vars: s1, s2, s3 in 0..6
vars: makespan in 0..6
cumulative(s1=2@2, s2=3@1, s3=4@1; capacity=2)
s1 + 2 <= makespan
s2 + 3 <= makespan
s3 + 4 <= makespan
minimize makespan''',
    ),
  ];

  final _ctl = TextEditingController(text: _gallery.first.program);
  DiophantineResult? _result;
  bool _solving = false;

  @override
  void initState() {
    super.initState();
    // Round 73: if the user got here via a `dsl:<id>` worked-
    // example sentinel, AppState carries the pending gallery id.
    // Drain it and load the matching program.
    final pendingId = AppState().consumePendingDslProgramId();
    if (pendingId != null) {
      for (final entry in _gallery) {
        if (entry.id == pendingId) {
          _ctl.text = entry.program;
          break;
        }
      }
    }
  }

  void _loadExample(String programText) {
    setState(() {
      _ctl.text = programText;
      _result = null;
    });
  }

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
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
              // Round 72: pre-built example programs. Selecting a
              // menu item replaces the TextField with that program.
              PopupMenuButton<String>(
                tooltip: t.constraintsDslExamplesTooltip,
                onSelected: _loadExample,
                itemBuilder: (context) => [
                  for (final entry in _gallery)
                    PopupMenuItem<String>(
                      value: entry.program,
                      child: Text(t.constraintsDslExampleTitle(entry.id)),
                    ),
                ],
                child: OutlinedButton.icon(
                  // The PopupMenuButton's child handles taps; the
                  // button's own onPressed is intentionally null.
                  onPressed: null,
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(t.constraintsDslExamplesButton),
                ),
              ),
            ],
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
