// lib/screens/notepad_screen.dart
//
// Phases 4 + 5 of the Notepad V1 plan: UI skeleton (Phase 4) +
// live recalc pipeline (Phase 5) over the data model (Phase 1),
// parser/scope (Phase 2), and dependency-graph evaluator (Phase 3).
//
// Phase 5: every edit schedules a 300 ms-debounced
// `evaluateFrom(doc, lineIndex)`. New edits cancel any in-flight
// engine call via `EngineService.cancelInFlight()` so the worker
// isolate's monotonic run-id drops the stale result. Per-row
// state surfaces a pending indicator while the dispatcher is mid-
// flight. The dispatcher itself wraps `EngineService.evaluateAsync`
// after passing the notepad-preprocessed body through the same
// native-format step the calculator uses
// (`preprocessNativeExpression`) — no global-AppState reach-in
// (those imports land in Phase 6 via the `use` directive).
//
// Strings are intentionally hardcoded English. Phase 8 will pull
// them into `AppLocalizations` across en/de/fr/es with the locale
// non-emptiness test as the guardrail.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../engine/app_state.dart';
import '../engine/notepad.dart';
import '../engine/notepad_evaluator.dart';
import '../localization/app_localizations.dart';
import '../services/engine_service.dart';
import '../utils/error_formatter.dart';
import '../utils/expression_preprocessing_utils.dart';
import '../utils/math_display_utils.dart';

/// Layout breakpoint matching the app shell's nav-rail switch
/// (decision #17). At or above this width the input + result render
/// side-by-side; below, the result stacks under the input.
const double _kSideBySideBreakpoint = 720;

class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  final AppState _appState = AppState();

  /// Per-line text controllers, keyed by `NotepadLine.id`. Created
  /// lazily on first build and disposed when the line goes away (or
  /// the active doc changes). Holding them in state — rather than
  /// `controller: TextEditingController(text: line.source)` inline —
  /// is required for `ReorderableListView`: reordering rebuilds the
  /// children and an inline controller would lose focus + cursor
  /// position on every keystroke.
  final Map<String, TextEditingController> _controllers = {};

  /// Focus nodes per line.id. Used by the "blocked by line N" chip
  /// to scroll-to and focus the upstream errored line.
  final Map<String, FocusNode> _focusNodes = {};

  /// Tracks the document id whose controllers are currently in
  /// [_controllers] — switching docs disposes the old map and
  /// rebuilds for the new one.
  String? _activeControllerDocId;

  /// Inline rename state. When non-null, the AppBar title swaps to
  /// a TextField pre-filled with the current doc name.
  TextEditingController? _renameController;
  FocusNode? _renameFocus;

  /// Snackbar-undo slot (decision #18). The just-deleted doc or
  /// line lives here until the 5-second snackbar dismisses; the
  /// Undo action restores it.
  _PendingDeletion? _pendingDeletion;

  /// Scroll controller for the line list so blocked-by chips can
  /// scroll the upstream line into view on tap.
  final ScrollController _listScrollController = ScrollController();

  // --- Phase 5: live recalc ------------------------------------------------

  /// Debounce timer for per-edit recalc (decision #9, 300 ms).
  Timer? _recalcTimer;

  /// Line ids currently being (re-)evaluated — drives the per-row
  /// "pending" visual.
  final Set<String> _pendingLineIds = {};

  /// Tail of the active-recalc chain — new requests `await` this so
  /// at most one `_runRecalc` runs at a time. Pre-Phase-5 we tried
  /// to cancel the in-flight engine call with `cancelInFlight()`;
  /// the kill was async and the next `send()` raced against it,
  /// leaving the worker dead but `_commandPort` still pointing at
  /// the dead isolate's port — every dispatcher call then hung
  /// forever. Serialization side-steps that entirely: one request
  /// in flight, no concurrent kill races.
  Future<void>? _activeRecalc;

  /// Shared evaluator instance bound to [_dispatcher]. Pure-Dart
  /// orchestrator; the engine calls go through `EngineService`.
  late final NotepadEvaluator _evaluator =
      NotepadEvaluator(dispatcher: _dispatcher);

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _recalcTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _renameController?.dispose();
    _renameFocus?.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Controller lifecycle
  // ---------------------------------------------------------------------------

  /// Rebuild [_controllers] / [_focusNodes] for the doc currently
  /// in focus. Called at the top of build() so the maps always
  /// match the active doc's line set.
  void _syncControllersFor(NotepadDocument? doc) {
    final docId = doc?.id;
    if (_activeControllerDocId != docId) {
      // Doc switched — dispose everything and start fresh.
      for (final c in _controllers.values) {
        c.dispose();
      }
      for (final f in _focusNodes.values) {
        f.dispose();
      }
      _controllers.clear();
      _focusNodes.clear();
      _activeControllerDocId = docId;
      // Phase 5: drop any in-flight recalc tied to the old doc, and
      // re-arm the "initial full-eval on open" trigger for the new doc.
      _recalcTimer?.cancel();
      _pendingLineIds.clear();
    }
    if (doc == null) return;

    final liveIds = doc.lines.map((l) => l.id).toSet();
    // Prune controllers for lines that have been deleted.
    final stale = _controllers.keys.where((k) => !liveIds.contains(k)).toList();
    for (final id in stale) {
      _controllers.remove(id)?.dispose();
      _focusNodes.remove(id)?.dispose();
    }
    // Create controllers for newly-appeared lines.
    for (final line in doc.lines) {
      if (!_controllers.containsKey(line.id)) {
        final c = TextEditingController(text: line.source);
        _controllers[line.id] = c;
      }
      if (!_focusNodes.containsKey(line.id)) {
        _focusNodes[line.id] = FocusNode();
      }
      // Update the controller text if the source changed
      // out-of-band (e.g. undo restored a previous value) and the
      // user isn't actively editing. We compare strings rather
      // than replacing wholesale to avoid clobbering cursor state.
      final c = _controllers[line.id]!;
      if (c.text != line.source && !_focusNodes[line.id]!.hasFocus) {
        c.text = line.source;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Doc lookup helpers
  // ---------------------------------------------------------------------------

  NotepadDocument? get _currentDoc {
    final id = _appState.currentNotepadDocId;
    if (id == null) return null;
    return _appState.notepadDocuments[id];
  }

  /// Other docs sorted alphabetically by name for the ⋮ → Open
  /// submenu. Welcome and the current doc are excluded — Welcome
  /// gets its own menu entry, current is disabled-via-omission.
  List<NotepadDocument> _otherDocsForMenu() {
    final current = _appState.currentNotepadDocId;
    final out = _appState.notepadDocuments.values
        .where((d) => d.id != current && d.id != kWelcomeNotepadDocId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  /// Compute the next "Untitled N" name that isn't already in use.
  /// `Untitled` (no suffix) is preferred when free; otherwise we go
  /// `Untitled 2`, `Untitled 3`, …
  String _nextUntitledName() {
    final used = _appState.notepadDocuments.values.map((d) => d.name).toSet();
    if (!used.contains('Untitled')) return 'Untitled';
    var n = 2;
    while (used.contains('Untitled $n')) {
      n++;
    }
    return 'Untitled $n';
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  void _persistDoc(NotepadDocument doc) {
    doc.updatedAt = DateTime.now().toUtc();
    _appState.setNotepadDocument(doc);
  }

  void _onLineEdited(NotepadDocument doc, NotepadLine line, String value) {
    if (line.source == value) return;
    line.source = value;
    // Drop stale cache immediately so the row stops showing a wrong
    // value during the 300 ms debounce window. The recalc below
    // re-populates it.
    line.cachedResult = null;
    line.cachedError = null;
    line.cachedFreeVars = [];
    _persistDoc(doc);
    _scheduleRecalc(doc, doc.lines.indexOf(line));
  }

  void _appendLine(NotepadDocument doc) {
    final line = NotepadLine.fresh(source: '');
    doc.lines.add(line);
    _persistDoc(doc);
    // Focus the new line on the next frame so the user can type.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNodes[line.id]?.requestFocus();
    });
  }

  void _deleteLine(NotepadDocument doc, int index) {
    if (index < 0 || index >= doc.lines.length) return;
    final removed = doc.lines.removeAt(index);
    _persistDoc(doc);
    _pendingDeletion =
        _PendingDeletion.line(doc: doc, line: removed, index: index);
    // Deleting a line that other lines reference invalidates those
    // downstream — recompute from the spot where the line used to live.
    // No-op when the doc is now empty (no recalc target).
    if (doc.lines.isNotEmpty) {
      final clamped = index < doc.lines.length ? index : doc.lines.length - 1;
      _scheduleRecalc(doc, clamped);
    }
    _showUndoSnackbar(
      label: 'Line deleted',
      onUndo: () {
        final pending = _pendingDeletion;
        if (pending == null || pending.kind != _PendingDeletionKind.line) {
          return;
        }
        final lineIdx = pending.lineIndex!.clamp(0, pending.doc.lines.length);
        pending.doc.lines.insert(lineIdx, pending.line!);
        _persistDoc(pending.doc);
        _scheduleRecalc(pending.doc, lineIdx);
        _pendingDeletion = null;
      },
    );
  }

  void _reorderLines(NotepadDocument doc, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final moved = doc.lines.removeAt(oldIndex);
    doc.lines.insert(newIndex, moved);
    _persistDoc(doc);
    // Positional aliases (`lineN`) shift on reorder; assignment names
    // follow the line. Either way, the safe thing is a full recompute
    // from the lowest affected index.
    _scheduleRecalc(doc, oldIndex < newIndex ? oldIndex : newIndex);
  }

  void _newDocument() {
    final doc = NotepadDocument.fresh(name: _nextUntitledName());
    _appState.setNotepadDocument(doc);
    _appState.setCurrentNotepadDoc(doc.id);
  }

  void _openDocument(String id) {
    _appState.setCurrentNotepadDoc(id);
  }

  void _openWelcomeSample() {
    if (!_appState.notepadDocuments.containsKey(kWelcomeNotepadDocId)) {
      _appState.setNotepadDocument(buildWelcomeNotepadDocument());
    }
    _appState.setCurrentNotepadDoc(kWelcomeNotepadDocId);
  }

  void _duplicateCurrent() {
    final doc = _currentDoc;
    if (doc == null) return;
    final now = DateTime.now().toUtc();
    final copy = NotepadDocument(
      id: generateNotepadId(),
      name: '${doc.name} (copy)',
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
    _appState.setCurrentNotepadDoc(copy.id);
  }

  void _deleteCurrent() {
    final doc = _currentDoc;
    if (doc == null) return;
    final previousCurrent = _appState.currentNotepadDocId;
    _appState.deleteNotepadDocument(doc.id);
    _pendingDeletion = _PendingDeletion.doc(
      doc: doc,
      previousCurrentId: previousCurrent,
    );
    _showUndoSnackbar(
      label: 'Document "${doc.name}" deleted',
      onUndo: () {
        final pending = _pendingDeletion;
        if (pending == null || pending.kind != _PendingDeletionKind.doc) {
          return;
        }
        _appState.setNotepadDocument(pending.doc);
        if (pending.previousCurrentId == pending.doc.id) {
          _appState.setCurrentNotepadDoc(pending.doc.id);
        }
        _pendingDeletion = null;
      },
    );
  }

  void _copyAsMarkdown() {
    final doc = _currentDoc;
    if (doc == null) return;
    final buf = StringBuffer();
    buf.writeln('# ${doc.name}');
    buf.writeln();
    buf.writeln('```');
    for (final line in doc.lines) {
      final src = line.source;
      final res = line.cachedResult;
      if (res != null && res.isNotEmpty) {
        buf.writeln('$src  // → $res');
      } else {
        buf.writeln(src);
      }
    }
    buf.writeln('```');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied as Markdown'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 5: dispatcher + recalc scheduling
  // ---------------------------------------------------------------------------

  /// Engine dispatcher injected into [NotepadEvaluator]. Receives a
  /// notepad-preprocessed body (scope names + Ans already
  /// substituted by Phase 2) and returns either a normalized result
  /// string or an `Error: ...` string the evaluator wraps with
  /// [NotepadErrorPrefix.fromEngine]. No `AppState.userVariables` /
  /// `userFunctions` reach-in here — those land in Phase 6 via the
  /// `use` directive.
  Future<String> _dispatcher(String preprocessed) async {
    if (preprocessed.trim().isEmpty) return '';
    final native =
        ExpressionPreprocessingUtils.preprocessNativeExpression(preprocessed);
    try {
      final raw = await EngineService.evaluateAsync(native);
      if (raw.startsWith('Error')) return raw;
      return ExpressionPreprocessingUtils.normalizeComplexResult(raw);
    } on EngineCancelled {
      return 'Error: cancelled';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Debounce a recalc starting from [startIndex]. Each fresh
  /// keystroke pushes the firing 300 ms further out.
  void _scheduleRecalc(NotepadDocument doc, int startIndex) {
    if (startIndex < 0) return;
    _recalcTimer?.cancel();
    _recalcTimer = Timer(const Duration(milliseconds: 300), () {
      _runRecalc(doc, startIndex: startIndex);
    });
  }

  /// Run the evaluator for the given starting line (or the whole doc
  /// when [startIndex] is null). Cancels any in-flight engine call,
  /// marks downstream lines as pending so the UI greys their
  /// previous results, then awaits the evaluator. Stale completions
  /// (seq mismatch) get discarded.
  Future<void> _runRecalc(
    NotepadDocument doc, {
    int? startIndex,
  }) async {
    if (!mounted) return;
    // Chain after any previous run so we never have two evaluators
    // (and two engine dispatchers) racing on the same doc.
    final previous = _activeRecalc;
    final completer = Completer<void>();
    _activeRecalc = completer.future;
    if (previous != null) {
      try {
        await previous;
      } catch (_) {/* previous run swallowed its own errors */}
      if (!mounted) {
        completer.complete();
        return;
      }
    }

    try {
      await _runRecalcBody(doc, startIndex: startIndex);
    } finally {
      completer.complete();
      if (identical(_activeRecalc, completer.future)) {
        _activeRecalc = null;
      }
    }
  }

  Future<void> _runRecalcBody(
    NotepadDocument doc, {
    required int? startIndex,
  }) async {
    if (!mounted) return;

    final indices = <int>{};
    if (startIndex == null) {
      for (var i = 0; i < doc.lines.length; i++) {
        indices.add(i);
      }
    } else if (startIndex >= 0 && startIndex < doc.lines.length) {
      final graph = buildDependencyGraph(doc);
      indices.addAll(downstreamFrom(startIndex, graph));
    }
    setState(() {
      _pendingLineIds.clear();
      for (final i in indices) {
        if (i < doc.lines.length) {
          _pendingLineIds.add(doc.lines[i].id);
        }
      }
    });

    try {
      if (startIndex == null) {
        await _evaluator.evaluateAll(doc);
      } else if (startIndex >= 0 && startIndex < doc.lines.length) {
        await _evaluator.evaluateFrom(doc, startIndex);
      }
    } catch (_) {/* dispatcher swallows errors into the cache */}

    if (!mounted) return;

    setState(() {
      _pendingLineIds.clear();
    });
    _persistDoc(doc);
  }

  /// Manual "Recalculate all" entry point from the ⋮ menu — runs a
  /// full evaluateAll() over the current doc. Useful when the user
  /// has just opened a doc shipped without cached values (the
  /// built-in Welcome sample is the main case) or wants to force a
  /// re-eval after toggling a global setting that the dispatcher
  /// reads. Edits during normal use already trigger debounced
  /// per-line recalc via [_scheduleRecalc]; this is the one-shot
  /// catch-all.
  void _recalculateAll() {
    final doc = _currentDoc;
    if (doc == null) return;
    _recalcTimer?.cancel();
    _runRecalc(doc, startIndex: null);
  }

  void _showUndoSnackbar(
      {required String label, required VoidCallback onUndo}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(label),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: onUndo,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Rename flow
  // ---------------------------------------------------------------------------

  void _startRename() {
    final doc = _currentDoc;
    if (doc == null) return;
    _renameController?.dispose();
    _renameFocus?.dispose();
    _renameController = TextEditingController(text: doc.name);
    _renameFocus = FocusNode();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _renameFocus?.requestFocus();
      _renameController?.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _renameController?.text.length ?? 0,
      );
    });
  }

  void _commitRename() {
    final doc = _currentDoc;
    final controller = _renameController;
    if (doc == null || controller == null) {
      _cancelRename();
      return;
    }
    final newName = controller.text.trim();
    if (newName.isNotEmpty && newName != doc.name) {
      doc.name = newName;
      _persistDoc(doc);
    }
    _cancelRename();
  }

  void _cancelRename() {
    _renameController?.dispose();
    _renameFocus?.dispose();
    _renameController = null;
    _renameFocus = null;
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Blocked-by → scroll to upstream
  // ---------------------------------------------------------------------------

  void _scrollToLineId(String lineId) {
    final doc = _currentDoc;
    if (doc == null) return;
    final idx = doc.lines.indexWhere((l) => l.id == lineId);
    if (idx < 0) return;
    _focusNodes[doc.lines[idx].id]?.requestFocus();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final doc = _currentDoc;
    _syncControllersFor(doc);

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(doc),
        actions: _buildActions(doc),
      ),
      body: doc == null ? _buildEmptyState() : _buildDocBody(doc),
    );
  }

  Widget _buildTitle(NotepadDocument? doc) {
    if (doc == null) return const Text('Notepad');
    if (_renameController != null) {
      return TextField(
        controller: _renameController,
        focusNode: _renameFocus,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
        ),
        style: Theme.of(context).textTheme.titleLarge,
        onSubmitted: (_) => _commitRename(),
        onTapOutside: (_) => _commitRename(),
      );
    }
    return InkWell(
      onTap: _startRename,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(doc.name),
      ),
    );
  }

  List<Widget> _buildActions(NotepadDocument? doc) {
    return [
      if (doc != null)
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Add line',
          onPressed: () => _appendLine(doc),
        ),
      PopupMenuButton<String>(
        tooltip: 'Document menu',
        onSelected: _onMenuSelected,
        itemBuilder: (context) {
          final items = <PopupMenuEntry<String>>[
            const PopupMenuItem(value: 'new', child: Text('New document')),
          ];
          final others = _otherDocsForMenu();
          if (others.isNotEmpty) {
            items.add(const PopupMenuDivider());
            for (final d in others) {
              items.add(PopupMenuItem(
                value: 'open:${d.id}',
                child: Text(d.name),
              ));
            }
          }
          items.add(const PopupMenuDivider());
          items.add(const PopupMenuItem(
            value: 'open-welcome',
            child: Text('Open Welcome sample'),
          ));
          if (doc != null) {
            items.add(const PopupMenuDivider());
            items.add(const PopupMenuItem(
              value: 'recalc',
              child: Text('Recalculate all'),
            ));
            items.add(const PopupMenuItem(
              value: 'rename',
              child: Text('Rename'),
            ));
            items.add(const PopupMenuItem(
              value: 'duplicate',
              child: Text('Duplicate'),
            ));
            items.add(const PopupMenuItem(
              value: 'copy-markdown',
              child: Text('Copy as Markdown'),
            ));
            items.add(const PopupMenuItem(
              value: 'delete',
              child: Text('Delete document'),
            ));
          }
          return items;
        },
      ),
    ];
  }

  void _onMenuSelected(String value) {
    if (value == 'new') {
      _newDocument();
    } else if (value == 'open-welcome') {
      _openWelcomeSample();
    } else if (value.startsWith('open:')) {
      _openDocument(value.substring('open:'.length));
    } else if (value == 'recalc') {
      _recalculateAll();
    } else if (value == 'rename') {
      _startRename();
    } else if (value == 'duplicate') {
      _duplicateCurrent();
    } else if (value == 'copy-markdown') {
      _copyAsMarkdown();
    } else if (value == 'delete') {
      _deleteCurrent();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notes, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No documents yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a new document or open the Welcome sample to get started.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New document'),
                  onPressed: _newDocument,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Open Welcome sample'),
                  onPressed: _openWelcomeSample,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocBody(NotepadDocument doc) {
    return LayoutBuilder(builder: (context, constraints) {
      final sideBySide = constraints.maxWidth >= _kSideBySideBreakpoint;
      return ReorderableListView.builder(
        scrollController: _listScrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        buildDefaultDragHandles: false,
        itemCount: doc.lines.length,
        onReorder: (oldIndex, newIndex) =>
            _reorderLines(doc, oldIndex, newIndex),
        itemBuilder: (context, index) {
          final line = doc.lines[index];
          return _NotepadLineRow(
            key: ValueKey(line.id),
            line: line,
            index: index,
            sideBySide: sideBySide,
            isPending: _pendingLineIds.contains(line.id),
            controller: _controllers[line.id]!,
            focusNode: _focusNodes[line.id]!,
            onChanged: (v) => _onLineEdited(doc, line, v),
            onDelete: () => _deleteLine(doc, index),
            onScrollToLineId: _scrollToLineId,
          );
        },
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Row
// ---------------------------------------------------------------------------

class _NotepadLineRow extends StatelessWidget {
  final NotepadLine line;
  final int index;
  final bool sideBySide;
  final bool isPending;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;
  final void Function(String lineId) onScrollToLineId;

  const _NotepadLineRow({
    super.key,
    required this.line,
    required this.index,
    required this.sideBySide,
    required this.isPending,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onDelete,
    required this.onScrollToLineId,
  });

  bool get _isBlank => line.source.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    // Decision #12: blank rows collapse to a small height. We still
    // render a TextField so the user can type into the empty row,
    // but skip the result column and tighten the padding.
    if (_isBlank) {
      return Padding(
        key: ValueKey('row-${line.id}'),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DragHandle(index: index),
            Expanded(child: _buildInputField(context, dense: true)),
            _DeleteButton(onPressed: onDelete),
          ],
        ),
      );
    }

    if (sideBySide) {
      return Padding(
        key: ValueKey('row-${line.id}'),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DragHandle(index: index),
            Expanded(
              flex: 3,
              child: _buildInputField(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _NotepadResultColumn(
                line: line,
                isPending: isPending,
                onScrollToLineId: onScrollToLineId,
              ),
            ),
            _DeleteButton(onPressed: onDelete),
          ],
        ),
      );
    }

    // Stacked layout for narrow screens.
    return Padding(
      key: ValueKey('row-${line.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(index: index),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputField(context),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, bottom: 4),
                  child: _NotepadResultColumn(
                    line: line,
                    isPending: isPending,
                    onScrollToLineId: onScrollToLineId,
                    alignStart: true,
                  ),
                ),
              ],
            ),
          ),
          _DeleteButton(onPressed: onDelete),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context, {bool dense = false}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      minLines: 1,
      maxLines: null,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      decoration: InputDecoration(
        isDense: dense,
        border: InputBorder.none,
        hintText: 'line ${index + 1}',
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drag handle / delete button
// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  final int index;
  const _DragHandle({required this.index});

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          Icons.drag_handle,
          size: 20,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _DeleteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
      tooltip: 'Delete line',
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

// ---------------------------------------------------------------------------
// Result column
// ---------------------------------------------------------------------------

class _NotepadResultColumn extends StatelessWidget {
  final NotepadLine line;
  final bool isPending;
  final void Function(String lineId) onScrollToLineId;
  final bool alignStart;

  const _NotepadResultColumn({
    required this.line,
    required this.isPending,
    required this.onScrollToLineId,
    this.alignStart = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final align = alignStart ? Alignment.centerLeft : Alignment.centerRight;
    final textAlign = alignStart ? TextAlign.left : TextAlign.right;

    // Phase 5 pending state: greyed-out previous value (or a small
    // spinner if no previous value to grey) + progress dot.
    if (isPending) {
      return Align(
        alignment: align,
        child: _buildPendingWidget(context, textAlign),
      );
    }

    if (line.cachedError != null) {
      return Align(
        alignment: align,
        child: _buildErrorWidget(context, line.cachedError!, textAlign),
      );
    }

    final res = line.cachedResult;
    final children = <Widget>[];
    if (res != null && res.isNotEmpty) {
      children.add(_buildResult(context, res, textAlign));
    }
    if (line.cachedFreeVars.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'free: ${line.cachedFreeVars.join(', ')}',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: textAlign,
        ),
      ));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: align,
      child: Column(
        crossAxisAlignment:
            alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildPendingWidget(BuildContext context, TextAlign textAlign) {
    final cs = Theme.of(context).colorScheme;
    final res = line.cachedResult;
    final style =
        TextStyle(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.4));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (res != null && res.isNotEmpty)
          Flexible(child: Text(res, style: style, textAlign: textAlign)),
        if (res != null && res.isNotEmpty) const SizedBox(width: 6),
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: cs.primary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context, String res, TextAlign textAlign) {
    final color = Theme.of(context).colorScheme.primary;
    final style = TextStyle(fontSize: 16, color: color);
    final latex = MathDisplayUtils.toHistoryDisplayLatex(res);
    Widget body;
    try {
      body = Math.tex(
        latex,
        textStyle: style,
        onErrorFallback: (_) => Text(res, style: style, textAlign: textAlign),
      );
    } catch (_) {
      body = Text(res, style: style, textAlign: textAlign);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showResultActions(context, res, latex),
      child: body,
    );
  }

  void _showResultActions(BuildContext context, String plain, String latex) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copy result'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: plain));
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied result'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Copy as LaTeX'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: latex));
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied as LaTeX'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
      BuildContext context, String rawError, TextAlign textAlign) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);

    if (rawError.startsWith(NotepadErrorPrefix.blockedBy)) {
      // blockedBy:<lineId>:<alias>
      final payload = rawError.substring(NotepadErrorPrefix.blockedBy.length);
      final sep = payload.indexOf(':');
      final lineId = sep < 0 ? '' : payload.substring(0, sep);
      final alias = sep < 0 ? payload : payload.substring(sep + 1);
      return ActionChip(
        avatar: Icon(Icons.block, size: 16, color: cs.error),
        label: Text(
          'Blocked by $alias',
          style: TextStyle(color: cs.error, fontSize: 12),
        ),
        onPressed: () => onScrollToLineId(lineId),
      );
    }

    if (rawError.startsWith(NotepadErrorPrefix.circularReference)) {
      final path =
          rawError.substring(NotepadErrorPrefix.circularReference.length);
      return Chip(
        avatar: Icon(Icons.sync_problem, size: 16, color: cs.error),
        label: Text(
          'Cycle: $path',
          style: TextStyle(color: cs.error, fontSize: 12),
        ),
        backgroundColor: cs.errorContainer.withValues(alpha: 0.3),
      );
    }

    if (rawError.startsWith(NotepadErrorPrefix.useDirective)) {
      final code = rawError.substring(NotepadErrorPrefix.useDirective.length);
      return Text(
        'Use directive: $code',
        style: TextStyle(color: cs.error, fontSize: 12),
        textAlign: textAlign,
      );
    }

    if (rawError.startsWith(NotepadErrorPrefix.evaluation)) {
      final engine = rawError.substring(NotepadErrorPrefix.evaluation.length);
      final formatted = EngineErrorFormatter.format(engine, t);
      return Text(
        formatted,
        style: TextStyle(color: cs.error, fontSize: 12),
        textAlign: textAlign,
      );
    }

    // Unknown prefix — render verbatim.
    return Text(
      rawError,
      style: TextStyle(color: cs.error, fontSize: 12),
      textAlign: textAlign,
    );
  }
}

// ---------------------------------------------------------------------------
// Snackbar-undo state holder
// ---------------------------------------------------------------------------

enum _PendingDeletionKind { doc, line }

class _PendingDeletion {
  final _PendingDeletionKind kind;
  final NotepadDocument doc;
  final NotepadLine? line;
  final int? lineIndex;
  final String? previousCurrentId;

  _PendingDeletion._({
    required this.kind,
    required this.doc,
    this.line,
    this.lineIndex,
    this.previousCurrentId,
  });

  factory _PendingDeletion.doc({
    required NotepadDocument doc,
    required String? previousCurrentId,
  }) =>
      _PendingDeletion._(
        kind: _PendingDeletionKind.doc,
        doc: doc,
        previousCurrentId: previousCurrentId,
      );

  factory _PendingDeletion.line({
    required NotepadDocument doc,
    required NotepadLine line,
    required int index,
  }) =>
      _PendingDeletion._(
        kind: _PendingDeletionKind.line,
        doc: doc,
        line: line,
        lineIndex: index,
      );
}
