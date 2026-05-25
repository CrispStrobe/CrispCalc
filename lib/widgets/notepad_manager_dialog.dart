// lib/widgets/notepad_manager_dialog.dart
//
// "Manage notepads" dialog — a single place to enumerate every
// `NotepadDocument` in `AppState`, with per-row management
// actions (open, rename, duplicate, delete, export as JSON) +
// top-level controls (new document, import from JSON). Reached
// from the ⋮ menu on the Notepad screen.
//
// Files / share-sheets are intentionally out of scope — the JSON
// export goes to the clipboard (paste into a file or message),
// matching the calculator's existing "Export data" pattern. A
// future share-plus integration (PLAN's "Share / export" item)
// would slot in alongside the clipboard path.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/app_state.dart';
import '../engine/notepad.dart';
import '../localization/app_localizations.dart';

/// Opens the manager as a Material dialog. Pass [onSwitchTo] so
/// "Open" rows can also switch the active doc back on the
/// underlying screen.
Future<void> showNotepadManagerDialog(
  BuildContext context, {
  required void Function(String docId) onSwitchTo,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => NotepadManagerDialog(onSwitchTo: onSwitchTo),
  );
}

class NotepadManagerDialog extends StatefulWidget {
  final void Function(String docId) onSwitchTo;

  const NotepadManagerDialog({super.key, required this.onSwitchTo});

  @override
  State<NotepadManagerDialog> createState() => _NotepadManagerDialogState();
}

class _NotepadManagerDialogState extends State<NotepadManagerDialog> {
  final AppState _appState = AppState();
  String? _renamingDocId;
  late final TextEditingController _renameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _renameController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  // -- helpers --

  /// All docs sorted by `updatedAt` desc (most-recent first).
  List<NotepadDocument> _sortedDocs() {
    final docs = _appState.notepadDocuments.values.toList();
    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return docs;
  }

  String _nextUntitledName(String base) {
    final used = _appState.notepadDocuments.values.map((d) => d.name).toSet();
    if (!used.contains(base)) return base;
    var n = 2;
    while (used.contains('$base $n')) {
      n++;
    }
    return '$base $n';
  }

  // -- actions --

  void _newDocument() {
    final t = AppLocalizations.of(context);
    final doc =
        NotepadDocument.fresh(name: _nextUntitledName(t.notepadDefaultDocName));
    _appState.setNotepadDocument(doc);
    _appState.setCurrentNotepadDoc(doc.id);
    widget.onSwitchTo(doc.id);
    Navigator.of(context).pop();
  }

  void _open(NotepadDocument doc) {
    _appState.setCurrentNotepadDoc(doc.id);
    widget.onSwitchTo(doc.id);
    Navigator.of(context).pop();
  }

  void _duplicate(NotepadDocument doc) {
    final now = DateTime.now().toUtc();
    final copy = NotepadDocument(
      id: generateNotepadId(),
      name: _nextUntitledName('${doc.name} (copy)'),
      createdAt: now,
      updatedAt: now,
      lines: doc.lines
          .map((l) => NotepadLine(
                id: generateNotepadId(),
                source: l.source,
                cachedResult: l.cachedResult,
                cachedError: l.cachedError,
                cachedFreeVars: List<String>.from(l.cachedFreeVars),
              ))
          .toList(),
    );
    _appState.setNotepadDocument(copy);
  }

  void _delete(NotepadDocument doc) {
    _appState.deleteNotepadDocument(doc.id);
  }

  void _startRename(NotepadDocument doc) {
    setState(() {
      _renamingDocId = doc.id;
      _renameController.text = doc.name;
      _renameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.name.length,
      );
    });
  }

  void _commitRename(NotepadDocument doc) {
    final newName = _renameController.text.trim();
    if (newName.isNotEmpty && newName != doc.name) {
      doc.name = newName;
      doc.updatedAt = DateTime.now().toUtc();
      _appState.setNotepadDocument(doc);
    }
    setState(() => _renamingDocId = null);
  }

  void _exportJson(NotepadDocument doc) {
    final t = AppLocalizations.of(context);
    final json = const JsonEncoder.withIndent('  ').convert(doc.toJson());
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.notepadJsonCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _importJson() async {
    final t = AppLocalizations.of(context);
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => _ImportJsonDialog(),
    );
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      // Always mint a fresh id so importing a doc twice doesn't
      // overwrite the first; the imported `i` field becomes a
      // historical relic.
      final doc = NotepadDocument.fromJson(decoded);
      final fresh = NotepadDocument(
        id: generateNotepadId(),
        name: _nextUntitledName(doc.name),
        createdAt: doc.createdAt,
        updatedAt: DateTime.now().toUtc(),
        lines: doc.lines
            .map((l) => NotepadLine(
                  id: generateNotepadId(),
                  source: l.source,
                  cachedResult: l.cachedResult,
                  cachedError: l.cachedError,
                  cachedFreeVars: List<String>.from(l.cachedFreeVars),
                ))
            .toList(),
      );
      _appState.setNotepadDocument(fresh);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.notepadJsonImported(fresh.name)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.notepadJsonImportFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // -- build --

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final docs = _sortedDocs();
    final currentId = _appState.currentNotepadDocId;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.notepadManageTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: t.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: docs.isEmpty
                  ? _buildEmpty(t)
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        return _buildRow(t, doc, doc.id == currentId);
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(t.notepadNewDocument),
                    onPressed: _newDocument,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_upload),
                    label: Text(t.notepadImportFromJson),
                    onPressed: _importJson,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          t.notepadEmptyTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildRow(AppLocalizations t, NotepadDocument doc, bool isCurrent) {
    final isRenaming = _renamingDocId == doc.id;
    final subtitle = '${doc.lines.length} '
        '${doc.lines.length == 1 ? 'line' : 'lines'}'
        ' · ${_formatDate(doc.updatedAt)}';
    return ListTile(
      leading: Icon(
        isCurrent ? Icons.description : Icons.description_outlined,
        color: isCurrent ? Theme.of(context).colorScheme.primary : null,
      ),
      title: isRenaming
          ? TextField(
              controller: _renameController,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _commitRename(doc),
            )
          : Text(
              doc.name,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
      subtitle: Text(subtitle),
      onTap: isRenaming ? null : () => _open(doc),
      trailing: isRenaming
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: t.notepadRename,
                  onPressed: () => _commitRename(doc),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: t.cancel,
                  onPressed: () => setState(() => _renamingDocId = null),
                ),
              ],
            )
          : PopupMenuButton<String>(
              tooltip: t.notepadDocumentMenu,
              onSelected: (value) {
                switch (value) {
                  case 'open':
                    _open(doc);
                  case 'rename':
                    _startRename(doc);
                  case 'duplicate':
                    _duplicate(doc);
                  case 'export':
                    _exportJson(doc);
                  case 'delete':
                    _delete(doc);
                }
              },
              itemBuilder: (context) => [
                if (!isCurrent)
                  PopupMenuItem(
                    value: 'open',
                    child: Text(t.notepadOpenDocument),
                  ),
                PopupMenuItem(
                  value: 'rename',
                  child: Text(t.notepadRename),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(t.notepadDuplicate),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Text(t.notepadExportAsJson),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(t.notepadDeleteDocument),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime utc) {
    final local = utc.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _ImportJsonDialog extends StatefulWidget {
  @override
  State<_ImportJsonDialog> createState() => _ImportJsonDialogState();
}

class _ImportJsonDialogState extends State<_ImportJsonDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.notepadImportFromJson),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: t.notepadImportJsonHint,
            border: const OutlineInputBorder(),
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(t.notepadImport),
        ),
      ],
    );
  }
}
