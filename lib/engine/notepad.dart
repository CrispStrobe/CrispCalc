// lib/engine/notepad.dart
//
// Data model for the Notepad / document mode (P5 strategic next).
// Persisted as JSON inside AppState's shared_preferences blob.
//
// One AppState owns many NotepadDocuments. Each document owns an
// ordered list of NotepadLines. Per-line cached values (result,
// error, free-variable tag) are populated by the notepad evaluator
// (Phase 3) and survive reloads so re-opening a doc shows the last
// known results without an immediate re-eval.

import 'dart:math';

/// Stable id assigned to the built-in Welcome sample document. Lets
/// the seed-on-first-launch logic and the "Open Welcome sample"
/// overflow-menu action both refer to the same document without
/// double-creating it.
const String kWelcomeNotepadDocId = '__welcome__';

class NotepadDocument {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<NotepadLine> lines;

  NotepadDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
  });

  /// Mint a fresh document with a generated id, current timestamps,
  /// and a single empty line. Used by the "+ New document" action
  /// and the first-launch `Untitled` seed.
  factory NotepadDocument.fresh({required String name}) {
    final now = DateTime.now().toUtc();
    return NotepadDocument(
      id: generateNotepadId(),
      name: name,
      createdAt: now,
      updatedAt: now,
      lines: [NotepadLine.fresh(source: '')],
    );
  }

  Map<String, dynamic> toJson() => {
        'i': id,
        'n': name,
        'c': createdAt.toIso8601String(),
        'u': updatedAt.toIso8601String(),
        'l': lines.map((l) => l.toJson()).toList(),
      };

  static NotepadDocument fromJson(Map<String, dynamic> j) {
    final nowFallback = DateTime.now().toUtc();
    return NotepadDocument(
      id: (j['i'] as String?) ?? generateNotepadId(),
      name: (j['n'] as String?) ?? 'Untitled',
      createdAt: _parseIso(j['c']) ?? nowFallback,
      updatedAt: _parseIso(j['u']) ?? nowFallback,
      lines: (j['l'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((raw) => NotepadLine.fromJson(Map<String, dynamic>.from(raw)))
          .toList(),
    );
  }
}

class NotepadLine {
  final String id;
  String source;

  /// Last engine result for this line's source. Cleared on edit and
  /// repopulated when evaluation finishes (Phase 5).
  String? cachedResult;

  /// Last engine error (raw, formatter-ready). Mutually exclusive
  /// with [cachedResult] in steady state.
  String? cachedError;

  /// Identifiers in the line's source that didn't resolve in the
  /// document's scope at evaluation time. Surfaced by the UI as the
  /// `free: x, y` tag (decision #15). List, not Set, for JSON.
  List<String> cachedFreeVars;

  NotepadLine({
    required this.id,
    required this.source,
    this.cachedResult,
    this.cachedError,
    List<String>? cachedFreeVars,
  }) : cachedFreeVars = cachedFreeVars ?? <String>[];

  factory NotepadLine.fresh({required String source}) => NotepadLine(
        id: generateNotepadId(),
        source: source,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'i': id,
      's': source,
    };
    if (cachedResult != null) map['r'] = cachedResult;
    if (cachedError != null) map['e'] = cachedError;
    if (cachedFreeVars.isNotEmpty) map['f'] = cachedFreeVars;
    return map;
  }

  static NotepadLine fromJson(Map<String, dynamic> j) => NotepadLine(
        id: (j['i'] as String?) ?? generateNotepadId(),
        source: (j['s'] as String?) ?? '',
        cachedResult: j['r'] as String?,
        cachedError: j['e'] as String?,
        cachedFreeVars: (j['f'] as List<dynamic>? ?? const [])
            .map((v) => v.toString())
            .toList(),
      );
}

DateTime? _parseIso(dynamic v) {
  if (v is! String) return null;
  return DateTime.tryParse(v);
}

final Random _rng = Random.secure();

/// Timestamp-prefixed identifier with an 8-hex random suffix.
/// Globally unique enough for a single-user local document store;
/// cheap, no dependency. Exposed (not private) so test code can
/// validate the format / inject fakes if needed.
String generateNotepadId() {
  final ts = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36);
  final suffix = _rng.nextInt(0x100000000).toRadixString(16).padLeft(8, '0');
  return '${ts}_$suffix';
}

/// The static "Welcome" sample doc — always reachable from the
/// AppBar overflow menu, seeded on first launch alongside an empty
/// `Untitled`. Recreated from this constant if the user deletes it
/// and then re-opens via the menu (decision #7).
///
/// Body is English-only at this stage; Phase 8 wires localized
/// variants per `AppLocalizations`.
NotepadDocument buildWelcomeNotepadDocument() {
  final now = DateTime.now().toUtc();
  return NotepadDocument(
    id: kWelcomeNotepadDocId,
    name: 'Welcome',
    createdAt: now,
    updatedAt: now,
    lines: [
      NotepadLine.fresh(
          source: '// Welcome — edit any line and results update on the right'),
      NotepadLine.fresh(source: 'tax = 0.085'),
      NotepadLine.fresh(source: '142.50 * (1 + tax)'),
      NotepadLine.fresh(source: '5 km + 3000 m'),
      NotepadLine.fresh(source: 'Ans in miles'),
      NotepadLine.fresh(
          source: '// Change tax above and watch the total update'),
    ],
  );
}
