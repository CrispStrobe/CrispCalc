// lib/engine/notepad_evaluator.dart
//
// Per-line classification + document-scope construction + scope
// substitution for the Notepad surface (Phase 2 of the notepad V1
// implementation plan).
//
// Pure Dart — no engine bridge. Phase 3 layers a dependency graph
// + `EngineService` dispatch on top of these primitives; Phase 6
// wires the `use` directive's resolved imports to AppState's
// global namespaces.

import 'notepad.dart';

/// Kind of a single notepad line, surfaced to Phase 3 so the
/// dependency walker knows how to treat it.
enum NotepadLineKind {
  /// Empty / whitespace-only.
  blank,

  /// `//` or `#` to EOL — entire line was a comment.
  comment,

  /// `use name1, name2, ...` directive — only valid as the first
  /// non-blank, non-comment line of the document (decision #20).
  useDirective,

  /// `<name> = <expr>` with LHS matching a single identifier that
  /// isn't a reserved CAS keyword (decision #14).
  assignment,

  /// Anything else — passed verbatim to the engine.
  expression,
}

/// Parse-once result for a line.
class ParsedNotepadLine {
  final NotepadLineKind kind;

  /// For `assignment`: the LHS identifier (case-sensitive).
  final String? name;

  /// For `assignment` and `expression`: the post-comment-strip
  /// body. `null` for blank, comment, and useDirective.
  final String? body;

  /// For `useDirective`: deduped, non-empty identifier list.
  final List<String> imports;

  /// For `useDirective`: structured error code if the directive
  /// is malformed (e.g. an invalid identifier in the import list,
  /// or an empty list). Phase 6 maps this to an
  /// `AppLocalizations` string.
  final String? directiveError;

  const ParsedNotepadLine._({
    required this.kind,
    this.name,
    this.body,
    this.imports = const [],
    this.directiveError,
  });

  factory ParsedNotepadLine.blank() =>
      const ParsedNotepadLine._(kind: NotepadLineKind.blank);

  factory ParsedNotepadLine.comment() =>
      const ParsedNotepadLine._(kind: NotepadLineKind.comment);

  factory ParsedNotepadLine.useDirective(List<String> imports,
          {String? error}) =>
      ParsedNotepadLine._(
        kind: NotepadLineKind.useDirective,
        imports: imports,
        directiveError: error,
      );

  factory ParsedNotepadLine.assignment(String name, String body) =>
      ParsedNotepadLine._(
        kind: NotepadLineKind.assignment,
        name: name,
        body: body,
      );

  factory ParsedNotepadLine.expression(String body) =>
      ParsedNotepadLine._(
        kind: NotepadLineKind.expression,
        body: body,
      );
}

/// Builtin / CAS-reserved identifiers that can't be reused as an
/// assignment LHS. Deliberately a superset — a false positive just
/// forces the user to pick a less-collision-y name; a false
/// negative would let them shadow a CAS function.
const Set<String> kReservedNotepadNames = {
  // Magic / notepad
  'Ans', 'ans', 'use', 'line',
  // Trig + inverse + hyperbolic
  'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'atan2',
  'sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh',
  // Logs & exp
  'exp', 'log', 'ln', 'log10', 'log2',
  // Roots, abs, rounding
  'sqrt', 'cbrt', 'abs', 'floor', 'ceil', 'round', 'sign',
  // Number theory
  'gcd', 'lcm', 'factorial', 'fibonacci', 'isprime', 'nextprime',
  'prevprime', 'factorint', 'divisors', 'totient', 'modinv', 'modpow',
  'jacobi', 'factor', 'prime',
  // Calculus / CAS ops
  'integrate', 'diff', 'limit', 'solve', 'expand', 'simplify', 'subst',
  // Matrix / linear algebra
  'Matrix', 'det', 'inv', 'transpose', 'rref',
  // Constants (commonly typed)
  'pi', 'Pi', 'PI', 'e', 'E', 'euler', 'EulerGamma', 'gamma',
  // Stats-ish
  'min', 'max', 'mean', 'median', 'sum', 'mod',
};

/// Classify a single line.
///
/// [lineIndex] — position of this line in the document (0-based).
/// [firstCodeLineIndex] — index of the first non-blank, non-comment
/// line in the doc (-1 if the doc has no code lines). A `use` line
/// is only legal when `lineIndex == firstCodeLineIndex`; everywhere
/// else, `use ...` is reclassified as an expression so the engine
/// surfaces a single, consistent "name `use` not defined" error.
ParsedNotepadLine classifyNotepadLine(
  String source, {
  required int lineIndex,
  required int firstCodeLineIndex,
}) {
  if (source.trim().isEmpty) {
    return ParsedNotepadLine.blank();
  }
  final stripped = _stripComment(source).trim();
  if (stripped.isEmpty) {
    // Entire line was a comment.
    return ParsedNotepadLine.comment();
  }

  final useMatch = _useDirectiveRegex.firstMatch(stripped);
  if (useMatch != null) {
    if (lineIndex != firstCodeLineIndex) {
      return ParsedNotepadLine.expression(stripped);
    }
    final raw = useMatch.group(1)!.trimLeft();
    // Quick sanity: the import list must start with an
    // identifier-ish char (letter / digit / underscore) or a comma
    // (which signals an attempted-but-empty import). Anything else
    // (`= 5`, `+ 5`, `(foo)`) means the user didn't intend a use
    // directive, so fall through to expression.
    if (raw.isEmpty || !_importListStartRegex.hasMatch(raw[0])) {
      return ParsedNotepadLine.expression(stripped);
    }
    final names = <String>[];
    for (final part in raw.split(',')) {
      final n = part.trim();
      if (n.isEmpty) continue;
      if (!_identifierRegex.hasMatch(n)) {
        return ParsedNotepadLine.useDirective(
          names,
          error: 'invalidImport:$n',
        );
      }
      if (!names.contains(n)) names.add(n);
    }
    if (names.isEmpty) {
      return ParsedNotepadLine.useDirective(names,
          error: 'emptyImportList');
    }
    return ParsedNotepadLine.useDirective(names);
  }

  final asgMatch = _assignmentRegex.firstMatch(stripped);
  if (asgMatch != null) {
    final name = asgMatch.group(1)!;
    final body = asgMatch.group(2)!.trim();
    if (!kReservedNotepadNames.contains(name) && body.isNotEmpty) {
      return ParsedNotepadLine.assignment(name, body);
    }
    // Reserved LHS or empty body — fall through to expression. The
    // engine will then complain about `Ans = 5` etc. with a clear
    // error rather than us silently shadowing a builtin.
  }

  return ParsedNotepadLine.expression(stripped);
}

/// Index of the first non-blank, non-comment line in [doc]. Returns
/// -1 if the doc is entirely empty / comments.
int firstCodeLineIndexOf(NotepadDocument doc) {
  for (var i = 0; i < doc.lines.length; i++) {
    final stripped = _stripComment(doc.lines[i].source).trim();
    if (stripped.isNotEmpty) return i;
  }
  return -1;
}

/// Build the document's name → cached-result scope.
///
/// Every line that produced a result contributes its 1-based
/// auto-alias (`line1`, `line2`, …); assignment lines additionally
/// contribute their explicit LHS. [externalScope] (typically
/// populated by Phase 6 from the doc's `use` imports) is seeded
/// first, so any in-doc assignment of the same name shadows it.
///
/// Callers that need to preprocess a *specific* line should remove
/// that line's own contributions from the returned scope before
/// calling [preprocessNotepadLine] — otherwise `x = x + 1` would
/// substitute its own previous result into itself. Cycle detection
/// proper lives in Phase 3.
Map<String, String> buildNotepadScope(
  NotepadDocument doc, {
  Map<String, String> externalScope = const {},
}) {
  final scope = <String, String>{};
  scope.addAll(externalScope);

  final firstCode = firstCodeLineIndexOf(doc);
  for (var i = 0; i < doc.lines.length; i++) {
    final line = doc.lines[i];
    final cached = line.cachedResult;
    if (cached == null) continue;

    final parsed = classifyNotepadLine(line.source,
        lineIndex: i, firstCodeLineIndex: firstCode);
    if (parsed.kind == NotepadLineKind.blank ||
        parsed.kind == NotepadLineKind.comment ||
        parsed.kind == NotepadLineKind.useDirective) {
      continue;
    }
    scope['line${i + 1}'] = cached;
    if (parsed.kind == NotepadLineKind.assignment) {
      scope[parsed.name!] = cached;
    }
  }
  return scope;
}

/// Substitute scope names + `Ans` into [parsed]'s body, producing
/// the string Phase 3 will pass to the engine.
///
/// Returns `null` for line kinds that aren't sent to the engine
/// (blank, comment, useDirective).
///
/// Scope names are matched longest-first with word-boundary
/// anchors so e.g. `total2` substitutes before `total`, and a
/// name like `pi` doesn't accidentally splice into `epigraph`.
/// The substitution wraps the value in parens (`(value)`) so
/// surrounding operators bind correctly.
String? preprocessNotepadLine(
  ParsedNotepadLine parsed, {
  required NotepadDocument doc,
  required int lineIndex,
  required Map<String, String> scope,
}) {
  if (parsed.body == null) return null;
  var out = parsed.body!;

  if (out.contains('Ans')) {
    final ansValue = _resolveAns(doc, lineIndex);
    if (ansValue != null) {
      out = out.replaceAll(
        RegExp(r'(?<![A-Za-z0-9_])Ans(?![A-Za-z0-9_])'),
        '($ansValue)',
      );
    }
  }

  final names = scope.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final name in names) {
    if (!out.contains(name)) continue;
    final pattern = RegExp(
      r'(?<![A-Za-z0-9_])' + RegExp.escape(name) + r'(?![A-Za-z0-9_])',
    );
    out = out.replaceAll(pattern, '(${scope[name]!})');
  }
  return out;
}

/// Walk backward from [lineIndex] to the first non-blank,
/// non-comment line above. Return its `cachedResult` if it has
/// one; otherwise null (the engine will then see the literal
/// `Ans` and error, which Phase 3 turns into a "blocked by
/// line N" badge on dependents).
String? _resolveAns(NotepadDocument doc, int lineIndex) {
  for (var i = lineIndex - 1; i >= 0; i--) {
    final line = doc.lines[i];
    final stripped = _stripComment(line.source).trim();
    if (stripped.isEmpty) continue;
    return line.cachedResult;
  }
  return null;
}

String _stripComment(String source) {
  final m = _commentRegex.firstMatch(source);
  if (m == null) return source;
  return source.substring(0, m.start);
}

/// `//` or `#` anywhere in a line. We don't currently have string
/// literals in expressions, so the simple first-match heuristic is
/// correct for V1. If string literals ever appear, this needs to
/// skip matches that fall inside quoted text.
final RegExp _commentRegex = RegExp(r'(//|#)');
final RegExp _useDirectiveRegex = RegExp(r'^use\s+(.+)$');
final RegExp _assignmentRegex = RegExp(
  r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$',
);
final RegExp _identifierRegex = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
final RegExp _importListStartRegex = RegExp(r'[A-Za-z_0-9,]');
