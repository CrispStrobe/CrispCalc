// lib/widgets/export_data_dialog.dart
//
// Settings → Export data. Shows the full AppState as pretty-printed
// JSON in a scrollable read-only text area with a single Copy
// button. Cross-platform without any new dependency — every Flutter
// platform supports the built-in Clipboard.setData. The user can
// then paste into any file / Notes app / cloud doc they like.
//
// Re-importing this blob is V2; for V1 the export is the backup.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/app_state.dart';
import '../localization/app_localizations.dart';

class ExportDataDialog extends StatelessWidget {
  const ExportDataDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final json =
        const JsonEncoder.withIndent('  ').convert(AppState().exportToJson());

    return AlertDialog(
      title: Text(t.exportDataTitle),
      content: SizedBox(
        width: 520,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.exportDataSubtitle,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    json,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
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
        ElevatedButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: Text(t.exportDataCopy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: json));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.exportDataCopied),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}
