// lib/widgets/function_reference_dialog.dart
//
// Round 96 (P6): browseable Function Reference. Mirrors the
// worked-examples dialog layout (search field, category chip row,
// scrollable list), but each list entry is an `ExpansionTile` that
// reveals the signature, 2–3 examples, "see also" cross-links, and
// "Try in Calculator" + "See worked example" action buttons.
//
// V1 keeps the detail inline (ExpansionTile) rather than a
// side-by-side master / detail layout because the dialog content
// is 560×480 — splitting it leaves both columns cramped on the
// narrow breakpoint. Mobile-first; desktop just gets a wider list.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/app_state.dart';
import '../engine/function_reference.dart';
import '../engine/worked_examples.dart';
import '../localization/app_localizations.dart';
import 'module_navigation.dart';
import 'worked_examples_dialog.dart';

class FunctionReferenceDialog extends StatefulWidget {
  /// Round 102 (P6): pre-fill the search field with [initialSearch]
  /// so callers (e.g. the keypad's "Learn more" deep-link) can land
  /// on a specific FunctionRef row by id. Mirrors the
  /// `WorkedExamplesDialog.initialSearch` ctor param.
  final String? initialSearch;

  const FunctionReferenceDialog({super.key, this.initialSearch});

  @override
  State<FunctionReferenceDialog> createState() =>
      _FunctionReferenceDialogState();
}

class _FunctionReferenceDialogState extends State<FunctionReferenceDialog> {
  late final TextEditingController _searchCtrl;
  FunctionRefCategory? _category;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialSearch ?? '');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _categoryLabel(BuildContext context, FunctionRefCategory c) {
    final t = AppLocalizations.of(context);
    switch (c) {
      case FunctionRefCategory.cas:
        return t.functionRefCatCas;
      case FunctionRefCategory.numberTheory:
        return t.functionRefCatNumberTheory;
      case FunctionRefCategory.precision:
        return t.functionRefCatPrecision;
      case FunctionRefCategory.matrix:
        return t.functionRefCatMatrix;
      case FunctionRefCategory.graphing:
        return t.functionRefCatGraphing;
      case FunctionRefCategory.statistics:
        return t.functionRefCatStatistics;
      case FunctionRefCategory.constraints:
        return t.functionRefCatConstraints;
      case FunctionRefCategory.sudoku:
        return t.functionRefCatSudoku;
      case FunctionRefCategory.units:
        return t.functionRefCatUnits;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = FunctionReferences.all.where((e) {
      if (_category != null && e.category != _category) return false;
      if (query.isEmpty) return true;
      // Round 100: search the localized description too, so a German
      // query matches German text; the English catalog string stays
      // searchable as the fallback.
      final localizedDesc = t.functionRefDescription(e.id);
      return e.id.toLowerCase().contains(query) ||
          e.signature.toLowerCase().contains(query) ||
          e.shortDescription.toLowerCase().contains(query) ||
          (localizedDesc != null &&
              localizedDesc.toLowerCase().contains(query));
    }).toList();

    return AlertDialog(
      title: Text(t.functionRefTitle),
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
                hintText: t.functionRefSearchHint,
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
                  for (final c in FunctionRefCategory.values) ...[
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
                        t.functionRefEmpty,
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
                        return _FunctionRefRow(entry: e);
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
}

class _FunctionRefRow extends StatelessWidget {
  final FunctionRef entry;
  const _FunctionRefRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ExpansionTile(
      title: Text(
        entry.signature,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          // Round 100: prefer the localized description; fall back to
          // the English catalog string when this locale hasn't
          // translated the entry yet.
          t.functionRefDescription(entry.id) ?? entry.shortDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        for (final (i, ex) in entry.examples.indexed)
          _ExampleBlock(entryId: entry.id, index: i, example: ex),
        if (entry.seeAlso.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  t.functionRefSeeAlso,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                for (final id in entry.seeAlso)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      id,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          // Wrap (not Row) so the two action buttons reflow onto a
          // second line at narrow widths — the dialog content is
          // 560px and the row was overflowing by ~90px on the
          // tester's 1280-wide canvas in widget tests.
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (entry.workedExampleId != null &&
                  _hasWorkedExample(entry.workedExampleId!))
                TextButton.icon(
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: Text(t.functionRefSeeWorkedExample),
                  onPressed: () =>
                      _openWorkedExample(context, entry.workedExampleId!),
                ),
              // Round 99: the `runnable` flag suppresses the Try
              // button on module-surface entries (stats hypothesis
              // tests, Constraints DSL operators, Sudoku variants).
              // Pasting `welchT(...)` into the calculator would just
              // error — the See-worked-example cross-link is the
              // proper landing for these entries since the WE
              // dialog dispatches `open:<module>` sentinels.
              if (entry.runnable && entry.examples.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.input, size: 16),
                  label: Text(t.functionRefTryInCalculator),
                  onPressed: () =>
                      _tryInCalculator(context, entry.examples.first.input),
                ),
              // Round 99 follow-up: module-surface entries with an
              // `openTarget` get a direct "Open module" button that
              // routes through the shared module_navigation dispatcher,
              // landing on the module (pre-filled where a preset exists)
              // in one tap instead of the two-hop worked-example path.
              if (entry.openTarget != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(t.functionRefOpenModule),
                  onPressed: () => _openModule(context, entry.openTarget!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasWorkedExample(String id) {
    for (final w in WorkedExamples.all) {
      if (w.id == id) return true;
    }
    return false;
  }

  void _tryInCalculator(BuildContext context, String expression) {
    AppState().requestInsertExpression(expression);
    Navigator.of(context).pop();
  }

  /// Round 99 follow-up: pop the Function Reference dialog and dispatch
  /// an `open:<module>?...` / `dsl:<id>` navigation sentinel via the
  /// shared `module_navigation` helper (the same routing the
  /// worked-examples dialog uses). Pops first, then routes.
  void _openModule(BuildContext context, String target) {
    final navigator = Navigator.of(context);
    final rootCtx = navigator.context;
    navigator.pop();
    dispatchModuleSentinel(rootCtx, target);
  }

  /// Round 96 cross-link, tightened in the Round 96 follow-up: pop
  /// the Function Reference and reopen the Worked Examples dialog
  /// with the `id` pre-filled into the search field. The WE dialog
  /// matches against ids (locale-independent), so this is enough
  /// to surface exactly the linked entry without manual scrolling.
  void _openWorkedExample(BuildContext context, String id) {
    final navigator = Navigator.of(context);
    final rootCtx = navigator.context;
    Navigator.of(context).pop();
    showDialog<void>(
      context: rootCtx,
      builder: (_) => WorkedExamplesDialog(initialSearch: id),
    );
  }
}

class _ExampleBlock extends StatelessWidget {
  final String entryId;
  final int index;
  final FunctionRefExample example;
  const _ExampleBlock({
    required this.entryId,
    required this.index,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  example.input,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: cs.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: t.workedExamplesCopy,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _copy(context, example.input),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '→ ${example.expected}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
          ),
          if (_hint(t).isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _hint(t),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  // Round 100: prefer the localized hint for this (entry, example),
  // falling back to the English catalog hint.
  String _hint(AppLocalizations t) =>
      t.functionRefExampleHint(entryId, index) ?? example.hint;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.workedExamplesCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
