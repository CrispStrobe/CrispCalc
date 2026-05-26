// lib/screens/constraints_screen.dart
//
// Analysis-hub module for Constraint Satisfaction Problems. Four tabs:
//
//   1. Diophantine — enumerate integer solutions to a system of
//      bounded linear/inequality constraints. The variable list
//      drives a Map<String, (min, max)> and the constraints list is
//      passed through CspSolver.solveDiophantine.
//
//   2. Cryptarithm — solve `WORD1 + WORD2 = WORD3` puzzles via
//      CspSolver.solveCryptarithm.
//
//   3. Free-form DSL — the round-72 mini-DSL with `allDifferent`,
//      arithmetic comparators, `minimize` / `maximize`, `noOverlap`,
//      `cumulative` directives.
//
//   4. FlatZinc — paste a `.fzn` source string (typically produced
//      by `mzn2fzn` from a MiniZinc model) and call dart_csp's
//      FlatZinc frontend directly. Output is the standard FlatZinc
//      output format. Round E.1.
//
// Each tab shows the result in a copyable read-only block. Long-
// running solves are not yet routed through the persistent worker —
// typical CSP problems at this scale finish in milliseconds.

import 'package:dart_csp/dart_csp.dart';
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
    _tabs = TabController(length: 4, vsync: this);
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
          isScrollable: true,
          tabs: [
            Tab(text: t.constraintsTabDiophantine),
            Tab(text: t.constraintsTabCryptarithm),
            Tab(text: t.constraintsTabDsl),
            Tab(text: t.constraintsTabFlatZinc),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _DiophantineTab(),
          _CryptarithmTab(),
          _DslTab(),
          _FlatZincTab(),
        ],
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
  // Round E.2: MUS state. Cleared whenever a fresh solve runs so the
  // user doesn't see a stale conflict tied to inputs that have since
  // changed. Populated by `_explain`.
  CspMusResult? _mus;
  bool _explaining = false;

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

    setState(() {
      _solving = true;
      _mus = null;
    });
    final r = await CspSolver.solveDiophantine(
        variables: variables, constraints: constraints);
    if (!mounted) return;
    setState(() {
      _solving = false;
      _result = r;
    });
  }

  Future<void> _explain() async {
    // Re-parse the live inputs so the MUS reflects whatever's in the
    // textareas right now (which may differ from the last solve if
    // the user edited but hasn't re-solved). Parse errors fall
    // through to a no-op — the user has a stale result and the
    // standard solve-time error path will take over on next Solve.
    final variables = <String, ({int min, int max})>{};
    for (final line in _varsCtl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)) {
      final v = _parseVarLine(line);
      if (v == null) return;
      variables[v.name] = (min: v.min, max: v.max);
    }
    final constraints = _constraintsCtl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    setState(() => _explaining = true);
    final r = await CspSolver.explainDiophantine(
      variables: variables,
      constraints: constraints,
    );
    if (!mounted) return;
    setState(() {
      _explaining = false;
      _mus = r;
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
            if (_result!.ok && _result!.solutions.isEmpty) ...[
              const SizedBox(height: 12),
              _ExplainSection(
                isLoading: _explaining,
                result: _mus,
                onExplain: _explain,
              ),
            ],
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
        // Gantt overlay: present only when the DSL program had
        // `noOverlap` / `cumulative` constraints AND we got at
        // least one solution. Renders the first solution's start
        // times as a horizontal chart over the same time axis.
        if (result.ganttTasks.isNotEmpty && result.solutions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _GanttChart(
            tasks: result.ganttTasks,
            assignment: result.solutions.first,
            capacity: result.ganttCapacity,
          ),
        ],
      ],
    );
  }
}

/// Tiny Gantt chart for schedules produced by the DSL tab. One row
/// per task, sorted by group and start time; bar width = duration.
/// For `cumulative` problems the row's right-edge label includes
/// the demand. Capacity (when known) is shown as a header strip.
class _GanttChart extends StatelessWidget {
  final List<GanttTaskSpec> tasks;
  final DiophantineSolution assignment;
  final int? capacity;

  const _GanttChart({
    required this.tasks,
    required this.assignment,
    this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    // Compute the timeline span from the assignment + durations.
    var maxEnd = 0;
    for (final t in tasks) {
      final start = (assignment[t.startVar] as num?)?.toInt();
      if (start == null) continue;
      final end = start + t.duration;
      if (end > maxEnd) maxEnd = end;
    }
    if (maxEnd <= 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    const rowHeight = 28.0;
    final headerHeight = capacity != null ? 22.0 : 18.0;
    final totalHeight = headerHeight + tasks.length * rowHeight + 4;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SizedBox(
        height: totalHeight,
        child: CustomPaint(
          painter: _GanttPainter(
            tasks: tasks,
            assignment: assignment,
            maxEnd: maxEnd,
            capacity: capacity,
            rowHeight: rowHeight,
            headerHeight: headerHeight,
            scheme: scheme,
            textStyle: Theme.of(context).textTheme.bodySmall ??
                const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _GanttPainter extends CustomPainter {
  final List<GanttTaskSpec> tasks;
  final DiophantineSolution assignment;
  final int maxEnd;
  final int? capacity;
  final double rowHeight;
  final double headerHeight;
  final ColorScheme scheme;
  final TextStyle textStyle;

  _GanttPainter({
    required this.tasks,
    required this.assignment,
    required this.maxEnd,
    required this.capacity,
    required this.rowHeight,
    required this.headerHeight,
    required this.scheme,
    required this.textStyle,
  });

  /// Color palette per group — cycles if there are more groups than
  /// entries. Picked from Material Design's tonal palette so the
  /// bars look at home in both light and dark themes.
  static const List<Color> _groupColors = [
    Color(0xFF1976D2), // blue 700
    Color(0xFFE64A19), // deep orange 700
    Color(0xFF388E3C), // green 700
    Color(0xFF7B1FA2), // purple 700
    Color(0xFFFBC02D), // yellow 700
    Color(0xFF00796B), // teal 700
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Reserve a left gutter for task labels.
    const chartLeft = 56.0;
    final chartWidth = size.width - chartLeft - 8;
    if (chartWidth <= 0) return;
    final pxPerUnit = chartWidth / maxEnd;

    // Time-axis grid (light vertical lines + tick numbers along the top).
    final gridPaint = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 1;
    final axisLabelStyle = textStyle.copyWith(
      color: scheme.onSurfaceVariant,
      fontSize: 10,
    );
    final stepCandidates = [1, 2, 5, 10, 20, 50, 100];
    var step = 1;
    for (final s in stepCandidates) {
      if (maxEnd / s <= 10) {
        step = s;
        break;
      }
      step = s;
    }
    for (var t = 0; t <= maxEnd; t += step) {
      final x = chartLeft + t * pxPerUnit;
      canvas.drawLine(
        Offset(x, headerHeight),
        Offset(x, size.height),
        gridPaint,
      );
      final tp = TextPainter(
        text: TextSpan(text: '$t', style: axisLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + 2, 2));
    }

    // Capacity header strip (only for cumulative problems).
    if (capacity != null) {
      final capLabel = TextPainter(
        text: TextSpan(
          text: 'capacity = $capacity',
          style: axisLabelStyle.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      capLabel.paint(canvas, Offset(chartLeft, headerHeight - capLabel.height));
    }

    // Sort tasks by group then start time so each lane reads left-to-right.
    final sorted = [...tasks]..sort((a, b) {
        if (a.groupIndex != b.groupIndex) {
          return a.groupIndex.compareTo(b.groupIndex);
        }
        final aStart = (assignment[a.startVar] as num?)?.toInt() ?? 0;
        final bStart = (assignment[b.startVar] as num?)?.toInt() ?? 0;
        return aStart.compareTo(bStart);
      });

    final rowPaint = Paint();
    final labelStyle = textStyle.copyWith(color: scheme.onSurface);
    for (var i = 0; i < sorted.length; i++) {
      final task = sorted[i];
      final start = (assignment[task.startVar] as num?)?.toInt();
      if (start == null) continue;
      final yTop = headerHeight + i * rowHeight + 4;
      final yBot = yTop + rowHeight - 8;

      // Left-gutter task name.
      final nameTp = TextPainter(
        text: TextSpan(text: task.startVar, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: chartLeft - 4);
      nameTp.paint(
        canvas,
        Offset(0, yTop + (rowHeight - 8 - nameTp.height) / 2),
      );

      // Bar.
      final barX = chartLeft + start * pxPerUnit;
      final barW = task.duration * pxPerUnit;
      rowPaint.color = _groupColors[task.groupIndex % _groupColors.length];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(barX, yTop, barX + barW, yBot),
          const Radius.circular(3),
        ),
        rowPaint,
      );

      // Inside-bar caption: duration (and demand if cumulative).
      final cap = task.demand != null
          ? '${task.duration}u · d${task.demand}'
          : '${task.duration}u';
      final capTp = TextPainter(
        text: TextSpan(
          text: cap,
          style: labelStyle.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (capTp.width + 8 < barW) {
        capTp.paint(
          canvas,
          Offset(barX + 4, yTop + (rowHeight - 8 - capTp.height) / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GanttPainter old) =>
      old.tasks != tasks ||
      old.assignment != assignment ||
      old.maxEnd != maxEnd ||
      old.capacity != capacity;
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
  CspMusResult? _mus;
  bool _explaining = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    setState(() {
      _solving = true;
      _mus = null;
    });
    final r = await CspSolver.solveCryptarithm(_ctl.text);
    if (!mounted) return;
    setState(() {
      _solving = false;
      _result = r;
    });
  }

  Future<void> _explain() async {
    setState(() => _explaining = true);
    final r = await CspSolver.explainCryptarithm(_ctl.text);
    if (!mounted) return;
    setState(() {
      _explaining = false;
      _mus = r;
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
            // Surface Explain only on the "no assignment" case, not
            // on shape-parse errors where the model wasn't built.
            if (!_result!.ok && _result!.error!.contains('No assignment')) ...[
              const SizedBox(height: 12),
              _ExplainSection(
                isLoading: _explaining,
                result: _mus,
                onExplain: _explain,
              ),
            ],
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
    (
      // Round 84: multi-resource project scheduling (RCPSP — the
      // classical resource-constrained project scheduling
      // problem). Four tasks share two renewable resources, each
      // of capacity 3 — interpret as a crew of 3 and an
      // equipment pool of 3.
      //
      //   Task | dur | crew | equip
      //     s1 |  3  |   2  |   1
      //     s2 |  4  |   1  |   2
      //     s3 |  2  |   2  |   2
      //     s4 |  3  |   1  |   1
      //
      // s2 + s3 together demand equip = 4 > 3 capacity, so they
      // cannot overlap on equipment — that constraint is the
      // binding resource. Lower bound on makespan is
      // max(⌈17/3⌉, ⌈18/3⌉, dur(s2)+dur(s3)) = 6. Achieved by
      // s1=0, s2=0, s3=4, s4=3 → makespan 6.
      id: 'rcpsp',
      program: '''vars: s1, s2, s3, s4 in 0..6
vars: makespan in 0..6
cumulative(s1=3@2, s2=4@1, s3=2@2, s4=3@1; capacity=3)
cumulative(s1=3@1, s2=4@2, s3=2@2, s4=3@1; capacity=3)
s1 + 3 <= makespan
s2 + 4 <= makespan
s3 + 2 <= makespan
s4 + 3 <= makespan
minimize makespan''',
    ),
  ];

  final _ctl = TextEditingController(text: _gallery.first.program);
  DiophantineResult? _result;
  bool _solving = false;
  CspMusResult? _mus;
  bool _explaining = false;

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
      _mus = null;
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    setState(() {
      _solving = true;
      _mus = null;
    });
    final r = await CspSolver.solveDsl(_ctl.text);
    if (!mounted) return;
    setState(() {
      _solving = false;
      _result = r;
    });
  }

  Future<void> _explain() async {
    setState(() => _explaining = true);
    final r = await CspSolver.explainDsl(_ctl.text);
    if (!mounted) return;
    setState(() {
      _explaining = false;
      _mus = r;
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
            if (_result!.ok && _result!.solutions.isEmpty) ...[
              const SizedBox(height: 12),
              _ExplainSection(
                isLoading: _explaining,
                result: _mus,
                onExplain: _explain,
              ),
            ],
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

// === FlatZinc tab (CSP Round E.1) =======================================

class _FlatZincTab extends StatefulWidget {
  const _FlatZincTab();
  @override
  State<_FlatZincTab> createState() => _FlatZincTabState();
}

class _FlatZincTabState extends State<_FlatZincTab> {
  // Gallery of canonical FlatZinc snippets. Hand-written to be
  // small enough to read in the textarea; the dart_csp HEAD's
  // FlatZinc parser handles the full spec, so users can paste
  // anything mzn2fzn produces.
  static const List<({String id, String source})> _gallery = [
    (
      // 4-queens: row index implicit, queen[i] = column. Pairwise
      // diagonals via int_lin_ne (queen[i] - queen[j] != ±(i-j)).
      id: 'nqueens4',
      source: '''array[1..4] of var 1..4: q :: output_array([1..4]);
constraint all_different_int(q);
constraint int_lin_ne([1, -1], [q[1], q[2]], 1);
constraint int_lin_ne([1, -1], [q[1], q[2]], -1);
constraint int_lin_ne([1, -1], [q[1], q[3]], 2);
constraint int_lin_ne([1, -1], [q[1], q[3]], -2);
constraint int_lin_ne([1, -1], [q[1], q[4]], 3);
constraint int_lin_ne([1, -1], [q[1], q[4]], -3);
constraint int_lin_ne([1, -1], [q[2], q[3]], 1);
constraint int_lin_ne([1, -1], [q[2], q[3]], -1);
constraint int_lin_ne([1, -1], [q[2], q[4]], 2);
constraint int_lin_ne([1, -1], [q[2], q[4]], -2);
constraint int_lin_ne([1, -1], [q[3], q[4]], 1);
constraint int_lin_ne([1, -1], [q[3], q[4]], -1);
solve satisfy;
''',
    ),
    (
      // Bin-packing: 3 items of sizes [2, 3, 5] across 2 bins of
      // capacity 5. bin_packing_load propagates load[b] = sum of
      // sizes of items assigned to bin b.
      id: 'binPacking',
      source: '''array[1..2] of var 0..5: load :: output_array([1..2]);
array[1..3] of var 1..2: bin :: output_array([1..3]);
constraint bin_packing_load(load, bin, [2, 3, 5]);
solve satisfy;
''',
    ),
  ];

  final _ctl = TextEditingController(text: _gallery.first.source);
  bool _allSolutions = false;
  bool _solving = false;
  String? _output;
  String? _error;
  CspMusResult? _mus;
  bool _explaining = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _loadExample(String source) {
    setState(() {
      _ctl.text = source;
      _output = null;
      _error = null;
      _mus = null;
    });
  }

  Future<void> _solve() async {
    final source = _ctl.text;
    setState(() {
      _solving = true;
      _output = null;
      _error = null;
      _mus = null;
    });
    String? out;
    String? err;
    try {
      out = await FlatZinc.solve(source, all: _allSolutions);
    } catch (e) {
      err = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _solving = false;
      _output = out;
      _error = err;
    });
  }

  Future<void> _explain() async {
    setState(() => _explaining = true);
    final r = await CspSolver.explainFlatZinc(_ctl.text);
    if (!mounted) return;
    setState(() {
      _explaining = false;
      _mus = r;
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
          Text(t.constraintsFlatZincIntro,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _ctl,
            minLines: 8,
            maxLines: 20,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              labelText: t.constraintsFlatZincInputLabel,
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
              FilterChip(
                label: Text(t.constraintsFlatZincAllSolutions),
                selected: _allSolutions,
                onSelected: (v) => setState(() => _allSolutions = v),
              ),
              PopupMenuButton<String>(
                tooltip: t.constraintsDslExamplesTooltip,
                onSelected: _loadExample,
                itemBuilder: (context) => [
                  for (final entry in _gallery)
                    PopupMenuItem<String>(
                      value: entry.source,
                      child: Text(t.constraintsFlatZincExampleTitle(entry.id)),
                    ),
                ],
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(t.constraintsDslExamplesButton),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _FlatZincErrorBlock(message: _error!),
          ],
          if (_output != null) ...[
            const SizedBox(height: 16),
            _FlatZincOutputBlock(text: _output!),
            if (_output!.contains('=====UNSATISFIABLE=====')) ...[
              const SizedBox(height: 12),
              _ExplainSection(
                isLoading: _explaining,
                result: _mus,
                onExplain: _explain,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FlatZincErrorBlock extends StatelessWidget {
  final String message;
  const _FlatZincErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatZincOutputBlock extends StatelessWidget {
  final String text;
  const _FlatZincOutputBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Standard FlatZinc output ends with `==========` when search
    // is exhaustive (every solution found, or optimization proven
    // optimal), or `=====UNSATISFIABLE=====` when no solution exists.
    final trimmed = text.trim();
    final isUnsat = trimmed.contains('=====UNSATISFIABLE=====');
    final isExhaustive = trimmed.endsWith('==========');
    final solCount = '\n$trimmed'.split('\n----------').length - 1;
    final header = isUnsat
        ? t.constraintsFlatZincUnsatisfiable
        : isExhaustive
            ? (solCount == 1
                ? t.constraintsFlatZincExhaustiveOne
                : t.constraintsFlatZincExhaustiveN(solCount))
            : t.constraintsFlatZincFirstSolution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(header, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: t.constraintsCopyResult,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
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
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// === Round E.2 — shared "Explain failure" / MUS rendering =================

/// Stateless renderer for the QuickXplain MUS panel. Shown by every
/// tab when its solve concluded with no solutions / unsatisfiable.
/// State (the result + busy flag) lives in the parent tab; the
/// onExplain callback runs the actual `CspSolver.explain*` call.
class _ExplainSection extends StatelessWidget {
  final bool isLoading;
  final CspMusResult? result;
  final VoidCallback onExplain;

  const _ExplainSection({
    required this.isLoading,
    required this.result,
    required this.onExplain,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (result == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onExplain,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search, size: 18),
          label: Text(t.constraintsExplainFailure),
        ),
      );
    }
    return _MusBlock(result: result!);
  }
}

class _MusBlock extends StatelessWidget {
  final CspMusResult result;
  const _MusBlock({required this.result});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (result.error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
    if (result.wasSatisfiable) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: scheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t.constraintsExplainSatisfiable,
                  style: TextStyle(color: scheme.onSecondaryContainer)),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.constraintsExplainHeader,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          t.constraintsExplainEntryCount(result.entries.length),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in result.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3, right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.kind,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: scheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          entry.label,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
