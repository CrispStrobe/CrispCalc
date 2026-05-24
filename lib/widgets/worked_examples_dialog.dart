// lib/widgets/worked_examples_dialog.dart
//
// Browse a curated catalog of worked examples (round 54). Filter by
// category chip + substring search; tap any row to copy the
// expression to the clipboard. Mirrors the ConstantsDialog layout —
// scrollable list with per-row Copy icon.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/worked_examples.dart';
import '../localization/app_localizations.dart';

class WorkedExamplesDialog extends StatefulWidget {
  const WorkedExamplesDialog({super.key});

  @override
  State<WorkedExamplesDialog> createState() => _WorkedExamplesDialogState();
}

class _WorkedExamplesDialogState extends State<WorkedExamplesDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  WorkedExampleCategory? _category;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = WorkedExamples.all.where((e) {
      if (_category != null && e.category != _category) return false;
      if (query.isEmpty) return true;
      return e.title.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query) ||
          e.expression.toLowerCase().contains(query);
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
                  for (final c in WorkedExampleCategory.values) ...[
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
                          title: Text(e.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(e.description,
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
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: t.workedExamplesCopy,
                            onPressed: () => _copy(context, e.expression),
                          ),
                          onTap: () => _copy(context, e.expression),
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
}
