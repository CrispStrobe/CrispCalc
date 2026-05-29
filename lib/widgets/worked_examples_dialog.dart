// lib/widgets/worked_examples_dialog.dart
//
// Browse a curated catalog of worked examples (round 54). Filter by
// category chip + substring search; tap any row to copy the
// expression to the clipboard. Mirrors the ConstantsDialog layout —
// scrollable list with per-row Copy icon.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/app_state.dart';
import '../engine/worked_examples.dart';
import '../localization/app_localizations.dart';
import '../screens/constraints_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/sudoku_screen.dart';

/// Round 94 (P6): which surface opened the dialog. Drives category
/// filtering. Calculator surface shows everything (the default that
/// matches the pre-round-94 behaviour); notepad scopes down to
/// categories that fit a free-form expression-per-line document
/// (calculus / algebra / linear algebra / number theory) and hides
/// the module-bound categories (sudoku/constraints / statistics /
/// units), which are surface-specific affordances.
enum WorkedExamplesSurface { calculator, notepad }

class WorkedExamplesDialog extends StatefulWidget {
  final WorkedExamplesSurface surface;

  /// Round 96 follow-up: when set, the search field opens
  /// pre-filled with this string, and the list is filtered against
  /// it. Used by `FunctionReferenceDialog`'s "See worked example"
  /// cross-link to deep-link straight to the related entry.
  /// Free-form text — usually a `WorkedExample.id` (since ids are
  /// locale-independent and the filter matches against id as of
  /// this round) but any substring of title / description /
  /// expression works too.
  final String? initialSearch;

  const WorkedExamplesDialog({
    super.key,
    this.surface = WorkedExamplesSurface.calculator,
    this.initialSearch,
  });

  @override
  State<WorkedExamplesDialog> createState() => _WorkedExamplesDialogState();
}

class _WorkedExamplesDialogState extends State<WorkedExamplesDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  WorkedExampleCategory? _category;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchCtrl.text = widget.initialSearch!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Round 94 (P6): categories surfaced for the active screen. The
  /// notepad surface hides three categories: `statistics` (the
  /// Statistics module has its own data-table UI; inserting a stats
  /// expression into a notepad line doesn't help), `units` (notepad
  /// supports unit math but the PLAN scopes this round to math
  /// content), and `constraints` (the entries are `open:` / `dsl:`
  /// sentinels that navigate to a different module). The calculator
  /// surface keeps the original behaviour and shows everything.
  Iterable<WorkedExampleCategory> _allowedCategories() {
    switch (widget.surface) {
      case WorkedExamplesSurface.calculator:
        return WorkedExampleCategory.values;
      case WorkedExamplesSurface.notepad:
        return const [
          WorkedExampleCategory.calculus,
          WorkedExampleCategory.algebra,
          WorkedExampleCategory.linearAlgebra,
          WorkedExampleCategory.numberTheory,
        ];
    }
  }

  String _categoryLabel(BuildContext context, WorkedExampleCategory c) {
    final t = AppLocalizations.of(context);
    switch (c) {
      case WorkedExampleCategory.calculus:
        return t.workedExamplesCatCalculus;
      case WorkedExampleCategory.algebra:
        return t.workedExamplesCatAlgebra;
      case WorkedExampleCategory.linearAlgebra:
        return t.workedExamplesCatLinearAlgebra;
      case WorkedExampleCategory.numberTheory:
        return t.workedExamplesCatNumberTheory;
      case WorkedExampleCategory.statistics:
        return t.workedExamplesCatStatistics;
      case WorkedExampleCategory.units:
        return t.workedExamplesCatUnits;
      case WorkedExampleCategory.constraints:
        return t.workedExamplesCatConstraints;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final query = _searchCtrl.text.trim().toLowerCase();
    // V2: ask the locale for translated titles/descriptions; fall
    // back to the English fields on WorkedExample when the locale
    // doesn't have a translation. Search runs over the *visible*
    // strings so a German user can find "Mitternachtsformel" by
    // typing "mitter".
    String titleFor(WorkedExample e) => t.workedExampleTitle(e.id) ?? e.title;
    String descFor(WorkedExample e) =>
        t.workedExampleDescription(e.id) ?? e.description;

    final allowed = _allowedCategories().toSet();
    final filtered = WorkedExamples.all.where((e) {
      if (!allowed.contains(e.category)) return false;
      if (_category != null && e.category != _category) return false;
      if (query.isEmpty) return true;
      // Round 96 follow-up: include the locale-independent id so
      // `FunctionReferenceDialog`'s deep-link works regardless of
      // locale. Ids are camelCase but lowercased for the substring
      // check (so a search for "quadratic" still finds
      // `quadraticFormula`).
      return titleFor(e).toLowerCase().contains(query) ||
          descFor(e).toLowerCase().contains(query) ||
          e.expression.toLowerCase().contains(query) ||
          e.id.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: Text(t.workedExamplesTitle),
      content: SizedBox(
        width: 560,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: t.workedExamplesSearchHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(t.workedExamplesCatAll),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  for (final c in _allowedCategories()) ...[
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: Text(_categoryLabel(context, c)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        t.workedExamplesEmpty,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(titleFor(e)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(descFor(e),
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                e.expression,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: t.workedExamplesCopy,
                                onPressed: () => _copy(context, e.expression),
                              ),
                              IconButton(
                                icon: const Icon(Icons.input, size: 18),
                                tooltip: t.workedExamplesInsert,
                                onPressed: () => _insert(context, e.expression),
                              ),
                            ],
                          ),
                          // Tap the row → insert (the V2 primary
                          // action). Copy stays as an explicit icon
                          // for users who want the clipboard.
                          onTap: () => _insert(context, e.expression),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.dialogClose),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, String expression) async {
    await Clipboard.setData(ClipboardData(text: expression));
    if (!context.mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.workedExamplesCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// V2: push the expression into AppState's pending-insert slot and
  /// close the dialog. MainScreen routes to the Calculator tab via
  /// its listener; the calculator screen drains the slot and fills
  /// the input field.
  ///
  /// Round 69: entries whose expression starts with `open:` are not
  /// calculator expressions but module-navigation requests. Close
  /// the dialog and push the requested module screen instead of
  /// touching the AppState insert slot.
  ///
  /// Round 95: `open:<module>` now accepts an optional `?key=value`
  /// suffix that stashes a pre-load id on the appropriate AppState
  /// pending slot before the module screen is pushed. Recognised:
  ///   - `open:sudoku?preset=<id>`     → SudokuPresets.all[id]
  ///   - `open:statistics?tab=<id>`    → 'descriptive' / 'regression'
  ///                                     / 'distributions' / 'tests'
  ///   - `open:statistics?preset=<id>` → StatisticsPresets.all[id]
  ///                                     (picks the tab + fills inputs)
  ///
  /// Unknown keys are silently ignored — the module still opens, just
  /// without the pre-load — so a typo in a catalog entry degrades
  /// gracefully rather than crashing the dialog.
  void _insert(BuildContext context, String expression) {
    if (expression.startsWith('open:')) {
      final spec = expression.substring('open:'.length);
      final qIdx = spec.indexOf('?');
      final module = qIdx < 0 ? spec : spec.substring(0, qIdx);
      final argString = qIdx < 0 ? null : spec.substring(qIdx + 1);
      final args = <String, String>{};
      if (argString != null) {
        for (final pair in argString.split('&')) {
          final eq = pair.indexOf('=');
          if (eq > 0) {
            args[pair.substring(0, eq)] = pair.substring(eq + 1);
          }
        }
      }
      Navigator.of(context).pop();
      switch (module) {
        case 'sudoku':
          final preset = args['preset'];
          if (preset != null) {
            AppState().requestLoadSudokuPreset(preset);
          }
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const SudokuScreen(),
          ));
          break;
        case 'constraints':
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ConstraintsScreen(),
          ));
          break;
        case 'statistics':
          // Round 95 follow-up: `preset=<id>` resolves against
          // StatisticsPresets and both picks the tab and pre-fills the
          // inputs; the older `tab=<id>` just picks the tab.
          final preset = args['preset'];
          final tab = args['tab'];
          if (preset != null) {
            AppState().requestLoadStatisticsPreset(preset);
          }
          if (tab != null) {
            AppState().requestLoadStatisticsTab(tab);
          }
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const StatisticsScreen(),
          ));
          break;
      }
      return;
    }
    // Round 73: `dsl:<id>` opens the Constraints module AND
    // pre-loads the program with that gallery id. The id → text
    // mapping lives in _DslTabState; we just stash the id on
    // AppState and let the tab drain it on init.
    if (expression.startsWith('dsl:')) {
      final id = expression.substring('dsl:'.length);
      AppState().requestLoadDslProgram(id);
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const ConstraintsScreen(),
      ));
      return;
    }
    AppState().requestInsertExpression(expression);
    Navigator.of(context).pop();
  }
}
