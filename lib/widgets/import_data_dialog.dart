// lib/widgets/import_data_dialog.dart
//
// Counterpart to ExportDataDialog: accepts a pasted JSON payload (the
// same shape produced by AppState.exportToJson) and restores it over
// the current state. Validation happens on AppState.importFromJson —
// missing keys are tolerated so an older export still applies.

import 'dart:convert';

import 'package:flutter/material.dart';

import '../engine/app_state.dart';
import '../localization/app_localizations.dart';

class ImportDataDialog extends StatefulWidget {
  const ImportDataDialog({super.key});

  @override
  State<ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends State<ImportDataDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.importDataTitle),
      content: SizedBox(
        width: 520,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.importDataSubtitle,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
                decoration: InputDecoration(
                  hintText: '{ "version": 1, "history": [...], ... }',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.importDataWarning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.upload, size: 16),
          label: Text(t.importDataApply),
          onPressed: _onApply,
        ),
      ],
    );
  }

  void _onApply() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).importDataEmpty);
      return;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        setState(
            () => _error = AppLocalizations.of(context).importDataNotObject);
        return;
      }
      final summary =
          AppState().importFromJson(Map<String, dynamic>.from(decoded));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context).importDataApplied}: $summary'),
          duration: const Duration(seconds: 4),
        ),
      );
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }
}
