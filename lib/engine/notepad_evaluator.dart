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

  /// `fzn: <FlatZinc source>` — the body (possibly multi-line via
  /// the textarea's `maxLines: null`) is sent to dart_csp's
  /// FlatZinc frontend. Round E.4 inline directive variant.
  flatzinc,

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

  factory ParsedNotepadLine.flatzinc(String body) => ParsedNotepadLine._(
        kind: NotepadLineKind.flatzinc,
        body: body,
      );

  factory ParsedNotepadLine.expression(String body) => ParsedNotepadLine._(
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
  // Precision arc Group B — continued fractions + polynomial arithmetic
  'cfrac', 'convergent', 'polygcd', 'polyresultant', 'polydiscriminant',
  'polyfactor',
  // Special functions (SymEngine + MPFR, via basic_evalf)
  'zeta', 'erf', 'erfc', 'loggamma', 'lambertw', 'dirichlet_eta',
  'beta', 'lowergamma', 'uppergamma', 'polygamma',
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
  // FlatZinc detection runs BEFORE comment stripping because the
  // body may contain `//` inside string literals or as part of a
  // future spec extension; FlatZinc itself uses `%` for comments,
  // so leaving the body verbatim is safe for the dart_csp parser.
  final fznMatch = _flatzincDirectiveRegex.firstMatch(source);
  if (fznMatch != null) {
    final body = fznMatch.group(1) ?? '';
    return ParsedNotepadLine.flatzinc(body);
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
      return ParsedNotepadLine.useDirective(names, error: 'emptyImportList');
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
    final parsed = classifyNotepadLine(line.source,
        lineIndex: i, firstCodeLineIndex: firstCode);
    if (parsed.kind == NotepadLineKind.blank ||
        parsed.kind == NotepadLineKind.comment ||
        parsed.kind == NotepadLineKind.useDirective) {
      continue;
    }
    // FlatZinc lines contribute multiple scalar exports (one per
    // `:: output_var` annotation) plus their own `lineN` alias
    // bound to the formatted output text. Each export wins over a
    // pre-seeded external import.
    if (parsed.kind == NotepadLineKind.flatzinc) {
      final cached = line.cachedResult;
      if (cached != null) {
        scope['line${i + 1}'] = cached;
      }
      for (final entry in line.cachedExports.entries) {
        scope[entry.key] = entry.value;
      }
      continue;
    }
    final cached = line.cachedResult;
    if (cached == null) continue;
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
// `=(?!=)` keeps `name == value` out of the assignment route — that's
// a relational predicate (round 110) the engine handles via the
// preprocessor's `Eq(...)` rewrite.
final RegExp _assignmentRegex = RegExp(
  r'^([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)\s*(.+)$',
);
final RegExp _identifierRegex = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
final RegExp _importListStartRegex = RegExp(r'[A-Za-z_0-9,]');
final RegExp _identifierWordRegex = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');

/// `fzn:` directive — must be the first non-whitespace token on the
/// notepad line. Body captures everything after the colon and any
/// immediately following whitespace, including embedded newlines
/// (the screen's TextField uses `maxLines: null` so a single
/// NotepadLine.source can carry multi-line FlatZinc).
final RegExp _flatzincDirectiveRegex = RegExp(
  r'^\s*fzn:\s*([\s\S]*)$',
  caseSensitive: true,
);

/// Names declared with a `:: output_var` annotation in a FlatZinc
/// source. Matched statically so the dependency graph can be built
/// before any evaluation runs. Only scalar output_var names are
/// surfaced; array outputs (`output_array(...)`) stay in the
/// formatted result text but don't enter the document scope, since
/// a single FlatZinc array doesn't map cleanly to a scalar scope
/// value.
Set<String> flatzincOutputVarsIn(String source) {
  final out = <String>{};
  for (final m in _flatzincOutputVarRegex.allMatches(source)) {
    out.add(m.group(1)!);
  }
  return out;
}

/// Parse the standard FlatZinc output format into `name → value`
/// pairs for scalar (non-array) assignments. Array lines (`name =
/// array1d(...);`) are skipped — see [flatzincOutputVarsIn] for the
/// rationale. Anything between `=====UNSATISFIABLE=====` or after
/// the first `----------` separator is also ignored, so multi-
/// solution outputs only contribute the first solution's bindings.
Map<String, String> parseFlatZincScalarOutputs(String output) {
  final out = <String, String>{};
  final firstSolution = output.split('\n----------').first;
  if (firstSolution.contains('=====UNSATISFIABLE=====')) return out;
  for (final line in firstSolution.split('\n')) {
    final m = _flatzincScalarLineRegex.firstMatch(line);
    if (m == null) continue;
    out[m.group(1)!] = m.group(2)!.trim();
  }
  return out;
}

final RegExp _flatzincOutputVarRegex = RegExp(
  r'\b([A-Za-z_][A-Za-z0-9_]*)\b\s*::\s*output_var\b',
);
final RegExp _flatzincScalarLineRegex = RegExp(
  // Value disallows `(` so array1d(...) / array2d(...) lines fall
  // through. A scalar value is a number, a sign-prefixed number,
  // or `true`/`false` — no parens.
  r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^;(]+?)\s*;\s*$',
);

// ---------------------------------------------------------------------------
// Phase 3: dependency graph + topological evaluation.
// ---------------------------------------------------------------------------

/// Every identifier-like word in [source]. Stable ordering of first
/// appearance; duplicates collapsed. Used by both the dependency
/// graph (filter against scope keys) and the free-var tag (filter
/// against scope keys + reserved CAS names).
Set<String> identifierWordsIn(String source) {
  final out = <String>{};
  for (final m in _identifierWordRegex.allMatches(source)) {
    out.add(m.group(0)!);
  }
  return out;
}

/// In-document dependencies for a parsed line: the subset of
/// [scopeKeys] that appears as an identifier in [parsed]'s body.
/// `Ans` is handled separately by the evaluator and isn't a scope
/// key, so it doesn't show up here.
///
/// FlatZinc lines are independent — the body uses FlatZinc's own
/// variable namespace, which is unrelated to the document scope —
/// so they never produce dependency edges.
Set<String> dependenciesOfLine(
  ParsedNotepadLine parsed,
  Set<String> scopeKeys,
) {
  if (parsed.kind == NotepadLineKind.flatzinc) return const {};
  final body = parsed.body;
  if (body == null) return const {};
  final words = identifierWordsIn(body);
  return words.where(scopeKeys.contains).toSet();
}

/// Identifiers in [parsed]'s body that don't resolve to anything —
/// neither a scope name nor a reserved CAS function / constant.
/// Surfaced by the UI as the `free: x, y` tag (decision #15).
///
/// Note: unit symbols (`km`, `mph`, etc.) currently slip through
/// as "free" since the unit catalog isn't consulted at this layer.
/// Phase 6 wires units; if needed, a future refinement subtracts
/// known unit symbols here.
Set<String> freeVariablesOfLine(
  ParsedNotepadLine parsed,
  Set<String> scopeKeys,
) {
  // FlatZinc identifiers live in their own namespace; surfacing
  // them as "free vars" in the doc would be misleading noise.
  if (parsed.kind == NotepadLineKind.flatzinc) return const {};
  final body = parsed.body;
  if (body == null) return const {};
  final words = identifierWordsIn(body);
  return words
      .where((id) =>
          !scopeKeys.contains(id) &&
          !kReservedNotepadNames.contains(id) &&
          id != 'Ans')
      .toSet();
}

/// Per-document dependency graph keyed by line index.
/// `graph[i]` = set of line indices that line `i` depends on.
///
/// Built by mapping each in-scope name back to the line that
/// produced it (assignment name → its line; `lineN` alias → line
/// at index N-1). External-scope names (from `use` imports) are
/// not in the graph since they aren't doc-internal nodes.
///
/// Blank, comment, and `useDirective` lines have empty dependency
/// sets and never appear as targets of another line's edge.
class NotepadDependencyGraph {
  /// Edges keyed by source: `dependsOn[i]` = lines `i` depends on.
  final Map<int, Set<int>> dependsOn;

  /// Reverse edges keyed by target: `dependents[i]` = lines that
  /// depend on `i`. Used for downstream-only invalidation.
  final Map<int, Set<int>> dependents;

  const NotepadDependencyGraph({
    required this.dependsOn,
    required this.dependents,
  });
}

NotepadDependencyGraph buildDependencyGraph(
  NotepadDocument doc, {
  Map<String, String> externalScope = const {},
}) {
  // Map each in-doc scope name to the line index that produced it.
  // Both the auto-alias and the explicit name (for assignments)
  // point at the same line, so a reference to either flows the
  // same edge.
  final nameToLine = <String, int>{};
  final firstCode = firstCodeLineIndexOf(doc);
  final parsedLines = <int, ParsedNotepadLine>{};
  for (var i = 0; i < doc.lines.length; i++) {
    final parsed = classifyNotepadLine(doc.lines[i].source,
        lineIndex: i, firstCodeLineIndex: firstCode);
    parsedLines[i] = parsed;
    switch (parsed.kind) {
      case NotepadLineKind.assignment:
        nameToLine[parsed.name!] = i;
        nameToLine['line${i + 1}'] = i;
        break;
      case NotepadLineKind.expression:
        nameToLine['line${i + 1}'] = i;
        break;
      case NotepadLineKind.flatzinc:
        nameToLine['line${i + 1}'] = i;
        // Statically extract output_var names from the FlatZinc
        // source so downstream refs route correctly even before
        // the line has been evaluated for the first time.
        for (final name in flatzincOutputVarsIn(parsed.body ?? '')) {
          nameToLine[name] = i;
        }
        break;
      case NotepadLineKind.blank:
      case NotepadLineKind.comment:
      case NotepadLineKind.useDirective:
        break;
    }
  }

  // External-scope names take precedence on lookup, but they aren't
  // in-doc nodes — references to them produce no graph edges.
  final inDocScopeKeys = nameToLine.keys.toSet();

  final dependsOn = <int, Set<int>>{
    for (var i = 0; i < doc.lines.length; i++) i: <int>{},
  };
  final dependents = <int, Set<int>>{
    for (var i = 0; i < doc.lines.length; i++) i: <int>{},
  };

  for (var i = 0; i < doc.lines.length; i++) {
    final parsed = parsedLines[i]!;
    final refs = dependenciesOfLine(parsed, inDocScopeKeys);
    for (final name in refs) {
      // Ignore external-scope names (they have no in-doc node).
      if (externalScope.containsKey(name) && !inDocScopeKeys.contains(name)) {
        continue;
      }
      final target = nameToLine[name];
      if (target == null) continue;
      // A line referencing itself by its own auto-alias / name is
      // a self-loop. Surface it as a one-element cycle.
      dependsOn[i]!.add(target);
      dependents[target]!.add(i);
    }
  }

  return NotepadDependencyGraph(
    dependsOn: dependsOn,
    dependents: dependents,
  );
}

/// Kahn's algorithm in pure functional form. Returns the line
/// indices in dependency order (every line appears after all the
/// lines it depends on). Lines that are part of a cycle are
/// excluded from the result — the caller pairs this with
/// [findCycleParticipants] to error those lines instead.
List<int> kahnTopologicalOrder(NotepadDependencyGraph graph) {
  final remainingDeps = {
    for (final entry in graph.dependsOn.entries)
      entry.key: Set<int>.from(entry.value),
  };
  final queue = <int>[
    for (final entry in remainingDeps.entries)
      if (entry.value.isEmpty) entry.key,
  ]..sort();
  final order = <int>[];
  while (queue.isNotEmpty) {
    final node = queue.removeAt(0);
    order.add(node);
    final children = graph.dependents[node] ?? const <int>{};
    final newlyReady = <int>[];
    for (final child in children) {
      remainingDeps[child]!.remove(node);
      if (remainingDeps[child]!.isEmpty) newlyReady.add(child);
    }
    newlyReady.sort();
    queue.addAll(newlyReady);
  }
  return order;
}

/// Indices of every line that is part of any cycle (including
/// self-loops). Computed as the complement of [kahnTopologicalOrder]:
/// anything Kahn can't drain is on a cycle.
Set<int> findCycleParticipants(NotepadDependencyGraph graph) {
  final ordered = kahnTopologicalOrder(graph).toSet();
  return {
    for (final i in graph.dependsOn.keys)
      if (!ordered.contains(i)) i,
  };
}

/// Transitive closure of [start]'s dependents in [graph], inclusive.
/// Used by `evaluateFrom` to limit recompute work to the subgraph
/// rooted at the edited line.
Set<int> downstreamFrom(int start, NotepadDependencyGraph graph) {
  final out = <int>{start};
  final stack = <int>[start];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    for (final child in graph.dependents[node] ?? const <int>{}) {
      if (out.add(child)) stack.add(child);
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Phase 3: error encoding.
// ---------------------------------------------------------------------------

/// String prefixes used on `NotepadLine.cachedError` so the UI can
/// pattern-match on the error kind without a separate structured
/// type. Format is `<prefix>:<payload>`; payload format is per-kind.
class NotepadErrorPrefix {
  static const String blockedBy = 'blockedBy:';
  static const String circularReference = 'circularReference:';
  static const String evaluation = 'evaluation:';
  static const String useDirective = 'useDirective:';

  /// `blockedBy:<lineId>:<alias>` — dependent of an errored line.
  /// The UI parses alias (e.g. `line3`) for the chip label and
  /// uses lineId to scroll-to-line on tap.
  static String blocked(String lineId, String alias) =>
      '$blockedBy$lineId:$alias';

  /// `circularReference:a→b→a` — cycle participants. Body is the
  /// cycle's name path joined with `→`; the UI renders verbatim.
  static String circular(List<String> namePath) =>
      '$circularReference${namePath.join('→')}';

  /// `evaluation:<engine error string>` — engine returned a raw
  /// error. The existing `EngineErrorFormatter` handles the
  /// payload presentation.
  static String fromEngine(String engineError) => '$evaluation$engineError';
}

// ---------------------------------------------------------------------------
// Phase 3: orchestrator.
// ---------------------------------------------------------------------------

/// Signature of the engine-dispatch callback the evaluator calls
/// for each non-blocked line. Tests inject a stub; production
/// wiring uses `EngineService.evaluateAsync`.
typedef NotepadEngineDispatcher = Future<String> Function(
    String preprocessedExpression);

/// Result of running a `fzn:` line: the standard FlatZinc output
/// text (for `cachedResult`) plus the scalar `output_var` bindings
/// extracted from the first solution (for `cachedExports`). Errors
/// from the FlatZinc parser / solver bubble up as a thrown
/// exception — the evaluator catches them and writes the message
/// into `cachedError`.
class NotepadFlatZincResult {
  final String formatted;
  final Map<String, String> scalarBindings;
  const NotepadFlatZincResult({
    required this.formatted,
    required this.scalarBindings,
  });
}

/// Signature of the FlatZinc dispatcher. Tests inject a stub that
/// returns canned bindings; production wires this to
/// `FlatZinc.solve(source)` + [parseFlatZincScalarOutputs].
typedef NotepadFlatZincDispatcher = Future<NotepadFlatZincResult> Function(
    String flatzincSource);

/// Orchestrates per-line evaluation across a `NotepadDocument`:
/// builds the dependency graph, processes lines in topological
/// order, propagates blocked-by errors downstream, flags cycle
/// participants, and updates each line's cached fields in place.
///
/// Engine calls are funnelled through [dispatcher] so the
/// evaluator stays testable without a real `SymEngine` bridge.
class NotepadEvaluator {
  final NotepadEngineDispatcher dispatcher;

  /// Optional FlatZinc dispatcher. When null, `fzn:` lines fail
  /// with a "FlatZinc dispatcher not wired" error — useful in
  /// tests that don't care about FlatZinc support. Production
  /// wiring (NotepadScreen) always passes a real callback that
  /// hits dart_csp's FlatZinc.solve.
  final NotepadFlatZincDispatcher? flatzincDispatcher;

  /// Optional [externalScope] — populated by Phase 6 from the doc's
  /// `use` directive resolved against `AppState.userVariables` /
  /// `userFunctions`. Phase 3 just sees the map and uses it for
  /// scope lookup; the `use` directive line itself never gets
  /// dispatched.
  final Map<String, String> externalScope;

  const NotepadEvaluator({
    required this.dispatcher,
    this.flatzincDispatcher,
    this.externalScope = const {},
  });

  /// Recompute every line in [doc] in topological order. Mutates
  /// the lines' cache fields in place and returns the same doc.
  Future<NotepadDocument> evaluateAll(NotepadDocument doc) async {
    return _evaluateSubset(doc, indices: null);
  }

  /// Recompute the line at [startLineIndex] and every line
  /// transitively downstream of it. Lines outside that subgraph
  /// keep their current cache values.
  Future<NotepadDocument> evaluateFrom(
    NotepadDocument doc,
    int startLineIndex,
  ) async {
    final graph = buildDependencyGraph(doc, externalScope: externalScope);
    final subset = downstreamFrom(startLineIndex, graph);
    return _evaluateSubset(doc, indices: subset);
  }

  /// Core driver. If [indices] is null, every line is in scope;
  /// otherwise only the listed indices get re-evaluated (cache
  /// for the rest is reused as-is for blocked-by lookups).
  Future<NotepadDocument> _evaluateSubset(
    NotepadDocument doc, {
    required Set<int>? indices,
  }) async {
    final graph = buildDependencyGraph(doc, externalScope: externalScope);
    final cycleNodes = findCycleParticipants(graph);
    final order = kahnTopologicalOrder(graph);

    final firstCode = firstCodeLineIndexOf(doc);

    // Cycle nodes first — they never get an engine call. Their
    // downstream gets blockedBy via the standard path below.
    for (final i in cycleNodes) {
      if (indices != null && !indices.contains(i)) continue;
      final cyclePath = _cycleNamePath(i, graph, doc, firstCode);
      doc.lines[i].cachedResult = null;
      doc.lines[i].cachedError = NotepadErrorPrefix.circular(cyclePath);
      doc.lines[i].cachedFreeVars = [];
    }

    // Process the Kahn-acyclic part in dependency order.
    for (final i in order) {
      if (indices != null && !indices.contains(i)) continue;
      await _evaluateLine(doc, i, graph, firstCode);
    }
    return doc;
  }

  /// Evaluate (or skip + error) a single line. Mutates the line.
  Future<void> _evaluateLine(
    NotepadDocument doc,
    int lineIndex,
    NotepadDependencyGraph graph,
    int firstCode,
  ) async {
    final line = doc.lines[lineIndex];
    final parsed = classifyNotepadLine(line.source,
        lineIndex: lineIndex, firstCodeLineIndex: firstCode);

    // Skip non-evaluable kinds.
    switch (parsed.kind) {
      case NotepadLineKind.blank:
      case NotepadLineKind.comment:
        line.cachedResult = null;
        line.cachedError = null;
        line.cachedFreeVars = [];
        return;
      case NotepadLineKind.useDirective:
        line.cachedResult = null;
        // Preserve a pre-existing useDirective: error so callers
        // (Phase 6's screen-level `use` resolver) can set
        // `unknownImport:<name>` against AppState BEFORE the
        // evaluator runs without losing it on the way through.
        // Parse-level errors (invalidImport, emptyImportList) still
        // win because we set them unconditionally here when the
        // pre-existing cachedError isn't already one of ours.
        if (line.cachedError == null ||
            !line.cachedError!.startsWith(NotepadErrorPrefix.useDirective)) {
          line.cachedError = parsed.directiveError == null
              ? null
              : '${NotepadErrorPrefix.useDirective}${parsed.directiveError}';
        }
        line.cachedFreeVars = [];
        return;
      case NotepadLineKind.flatzinc:
        await _evaluateFlatZincLine(line, parsed);
        return;
      case NotepadLineKind.assignment:
      case NotepadLineKind.expression:
        break;
    }

    // Blocked-by upstream propagation. Pick the lowest-index
    // errored dependency as the canonical "blame" line — UI shows
    // its alias on the chip.
    final upstreamErrored = (graph.dependsOn[lineIndex] ?? const <int>{})
        .where((idx) => doc.lines[idx].cachedError != null)
        .toList()
      ..sort();
    if (upstreamErrored.isNotEmpty) {
      final blameIdx = upstreamErrored.first;
      final blame = doc.lines[blameIdx];
      line.cachedResult = null;
      line.cachedError =
          NotepadErrorPrefix.blocked(blame.id, 'line${blameIdx + 1}');
      // Free-var tracking is still useful even when blocked — the
      // user might be debugging via the tag.
      line.cachedFreeVars = freeVariablesOfLine(
        parsed,
        _scopeKeysFor(doc, firstCode),
      ).toList();
      return;
    }

    // Build the line's scope view + free vars.
    final scope = buildNotepadScope(doc, externalScope: externalScope);
    final scopeKeys = scope.keys.toSet();
    final freeVars = freeVariablesOfLine(parsed, scopeKeys).toList()..sort();

    // Strip this line's own contributions to avoid self-substitution
    // (`x = x + 1` shouldn't see its own previous result). Cycle
    // detection above already errored true cycles; this guards the
    // single-step self-reference case where the line writes its
    // own alias.
    scope.remove('line${lineIndex + 1}');
    if (parsed.kind == NotepadLineKind.assignment) {
      scope.remove(parsed.name!);
    }

    final preprocessed = preprocessNotepadLine(parsed,
        doc: doc, lineIndex: lineIndex, scope: scope);
    if (preprocessed == null) {
      // Shouldn't happen for assignment/expression, but be defensive.
      line.cachedResult = null;
      line.cachedError = null;
      line.cachedFreeVars = freeVars;
      return;
    }

    String result;
    try {
      result = await dispatcher(preprocessed);
    } catch (e) {
      result = 'Error: dispatcher threw: $e';
    }

    if (result.startsWith('Error')) {
      line.cachedResult = null;
      line.cachedError = NotepadErrorPrefix.fromEngine(result);
      line.cachedFreeVars = freeVars;
    } else {
      line.cachedResult = result;
      line.cachedError = null;
      line.cachedFreeVars = freeVars;
    }
  }

  /// Dispatch a `fzn:` line to the FlatZinc backend. On success the
  /// formatted FlatZinc output goes to `cachedResult` and the
  /// parsed scalar bindings populate `cachedExports`. Without a
  /// `flatzincDispatcher` wired, surfaces a friendly error so the
  /// missing-dispatcher case isn't silent.
  Future<void> _evaluateFlatZincLine(
    NotepadLine line,
    ParsedNotepadLine parsed,
  ) async {
    final body = parsed.body ?? '';
    if (body.trim().isEmpty) {
      line.cachedResult = null;
      line.cachedError =
          '${NotepadErrorPrefix.evaluation}Error: empty FlatZinc body';
      line.cachedFreeVars = [];
      line.cachedExports = {};
      return;
    }
    final dispatch = flatzincDispatcher;
    if (dispatch == null) {
      line.cachedResult = null;
      line.cachedError =
          '${NotepadErrorPrefix.evaluation}Error: FlatZinc dispatcher not wired';
      line.cachedFreeVars = [];
      line.cachedExports = {};
      return;
    }
    try {
      final result = await dispatch(body);
      // Treat a UNSATISFIABLE marker as an error so dependents
      // block correctly — there is no value to substitute.
      if (result.formatted.contains('=====UNSATISFIABLE=====')) {
        line.cachedResult = null;
        line.cachedError = '${NotepadErrorPrefix.evaluation}Error: '
            'unsatisfiable FlatZinc model';
        line.cachedFreeVars = [];
        line.cachedExports = {};
        return;
      }
      line.cachedResult = result.formatted;
      line.cachedError = null;
      line.cachedFreeVars = [];
      line.cachedExports = Map<String, String>.from(result.scalarBindings);
    } catch (e) {
      line.cachedResult = null;
      line.cachedError = '${NotepadErrorPrefix.evaluation}Error: $e';
      line.cachedFreeVars = [];
      line.cachedExports = {};
    }
  }

  /// Build a name path through a cycle for display. Picks the line
  /// names along one back-edge walk; if no name exists for a node
  /// (a plain expression with no assignment), falls back to its
  /// `lineN` alias.
  List<String> _cycleNamePath(
    int start,
    NotepadDependencyGraph graph,
    NotepadDocument doc,
    int firstCode,
  ) {
    final path = <String>[];
    final visited = <int>{};
    var current = start;
    while (true) {
      path.add(_displayNameFor(current, doc, firstCode));
      if (visited.contains(current)) break;
      visited.add(current);
      final deps = graph.dependsOn[current] ?? const <int>{};
      // Walk into the first dependency that's also a cycle node;
      // if none, break (shouldn't happen for cycle participants
      // but guards against malformed input).
      final cycleDeps =
          deps.where((idx) => visited.contains(idx) || idx == start).toList();
      if (cycleDeps.isEmpty) {
        // Fall back to any dependency to surface SOMETHING in the
        // error path — this branch is mostly defensive.
        if (deps.isEmpty) break;
        current = deps.first;
      } else {
        current = cycleDeps.first;
      }
      if (path.length > doc.lines.length + 2) break; // safety bound
    }
    return path;
  }

  String _displayNameFor(int index, NotepadDocument doc, int firstCode) {
    final parsed = classifyNotepadLine(doc.lines[index].source,
        lineIndex: index, firstCodeLineIndex: firstCode);
    if (parsed.kind == NotepadLineKind.assignment) return parsed.name!;
    return 'line${index + 1}';
  }

  Set<String> _scopeKeysFor(NotepadDocument doc, int firstCode) {
    final scope = buildNotepadScope(doc, externalScope: externalScope);
    return scope.keys.toSet();
  }
}
