// lib/widgets/history_help_modal.dart
//
// Round 103 (P6): history-row help modal. The modal explains how a
// given Calculator history row was computed — which engine / library
// ran, what FunctionRef row covers it, and (when applicable) re-runs
// the [StepEngine] trace via the host screen's callback.
//
// The detection routing table ([detectHistoryHelp]) is a pure function
// over the row's readable expression — kept in this file so the widget
// tests can drive both halves without spinning up the full calculator.

import 'package:flutter/material.dart';

import '../engine/app_state.dart';
import '../engine/function_reference.dart';
import '../localization/app_localizations.dart';
import '../utils/expression_preprocessing_utils.dart';

/// Which [StepEngine] entry-point applies to a row, or `none` when the
/// row's computation has no step trace.
enum HistoryStepKind { none, solve, diff, integrate }

/// Detection result for a history row. `engineLabel` and `refId` are
/// null when the row is bare arithmetic — the modal then falls back to
/// the "Direct numerical evaluation" blurb with no Learn-more link.
class HistoryHelpInfo {
  final String? engineLabel;
  final String? refId;
  final HistoryStepKind stepKind;

  /// Args extracted from the call, for the step-trace re-run. Both null
  /// when [stepKind] is [HistoryStepKind.none].
  final String? stepExpr;
  final String? stepVar;

  const HistoryHelpInfo._({
    this.engineLabel,
    this.refId,
    this.stepKind = HistoryStepKind.none,
    this.stepExpr,
    this.stepVar,
  });

  static const HistoryHelpInfo direct = HistoryHelpInfo._();

  bool get hasEngine => engineLabel != null;
  bool get hasSteps => stepKind != HistoryStepKind.none;
}

/// Map a history row's readable expression to its compute path.
/// Patterns are anchored against the trimmed expression's leading
/// `name(` token, with two extra forms handled specially: button-shape
/// derivatives `(d)/(d?)(...)` and bare equations `... = ...`.
HistoryHelpInfo detectHistoryHelp(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return HistoryHelpInfo.direct;

  // --- Function-call form `name(args)` ----------------------------------
  if (s.startsWith('solve(')) {
    final args = _parseCallArgs(s, 'solve');
    final body = args == null || args.isEmpty ? '' : args[0];
    String? variable;
    if (args != null && args.length >= 2) {
      variable = args[1].trim();
    } else if (body.isNotEmpty) {
      variable = ExpressionPreprocessingUtils.detectVariable(body);
    }
    return HistoryHelpInfo._(
      engineLabel: 'SymEngine.solve',
      refId: 'solve',
      stepKind: HistoryStepKind.solve,
      stepExpr: body.isEmpty ? null : body,
      stepVar: variable,
    );
  }
  if (s.startsWith('factor(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'SymEngine.factor', refId: 'factor');
  }
  if (s.startsWith('expand(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'SymEngine.expand', refId: 'expand');
  }
  if (s.startsWith('simplify(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'SymEngine.simplify', refId: 'simplify');
  }
  if (s.startsWith('diff(')) {
    final args = _parseCallArgs(s, 'diff');
    return HistoryHelpInfo._(
      engineLabel: 'SymEngine.diff',
      refId: 'diff',
      stepKind: HistoryStepKind.diff,
      stepExpr: args == null || args.isEmpty ? null : args[0],
      stepVar: args == null || args.length < 2 ? null : args[1].trim(),
    );
  }
  if (s.startsWith('integrate(')) {
    final args = _parseCallArgs(s, 'integrate');
    return HistoryHelpInfo._(
      engineLabel: 'SymEngine.integrate',
      refId: 'integrate',
      stepKind: HistoryStepKind.integrate,
      stepExpr: args == null || args.isEmpty ? null : args[0],
      stepVar: args == null || args.length < 2 ? null : args[1].trim(),
    );
  }
  if (s.startsWith('limit(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'SymEngine.limit', refId: 'limit');
  }
  if (s.startsWith('gcd(')) {
    return const HistoryHelpInfo._(engineLabel: 'SymEngine.gcd', refId: 'gcd');
  }
  if (s.startsWith('lcm(')) {
    return const HistoryHelpInfo._(engineLabel: 'SymEngine.lcm', refId: 'lcm');
  }

  // Number theory (FLINT bindings on the bridge side).
  if (s.startsWith('isprime(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'FLINT.ntheory', refId: 'isprime');
  }
  if (s.startsWith('nextprime(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'FLINT.ntheory', refId: 'nextprime');
  }
  if (s.startsWith('prevprime(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'FLINT.ntheory', refId: 'prevprime');
  }
  if (s.startsWith('factorint(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'FLINT.ntheory', refId: 'factorint');
  }

  // Precision arc (MPFR). Require a leading digit in the first arg so
  // we don't false-match `e + 5` or `pi*2`.
  if (RegExp(r'^pi\(\s*\d').hasMatch(s)) {
    return const HistoryHelpInfo._(engineLabel: 'MPFR', refId: 'pi_precision');
  }
  if (RegExp(r'^e\(\s*\d').hasMatch(s)) {
    return const HistoryHelpInfo._(engineLabel: 'MPFR', refId: 'e_precision');
  }
  if (RegExp(r'^EulerGamma\(\s*\d').hasMatch(s)) {
    return const HistoryHelpInfo._(
        engineLabel: 'MPFR', refId: 'eulergamma_precision');
  }
  // Precision sqrt is the two-arg form `sqrt(2, 50)`; single-arg falls
  // through to SymEngine.
  if (RegExp(r'^sqrt\(\s*\d+\s*,').hasMatch(s)) {
    return const HistoryHelpInfo._(
        engineLabel: 'MPFR', refId: 'sqrt_precision');
  }

  // Matrix evaluator (Dart).
  if (s.startsWith('Matrix(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'Dart (matrix)', refId: 'matrix_literal');
  }
  if (s.startsWith('det(')) {
    return const HistoryHelpInfo._(engineLabel: 'Dart (matrix)', refId: 'det');
  }
  if (s.startsWith('inv(')) {
    return const HistoryHelpInfo._(engineLabel: 'Dart (matrix)', refId: 'inv');
  }
  if (s.startsWith('transpose(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'Dart (matrix)', refId: 'transpose');
  }
  if (s.startsWith('rref(')) {
    return const HistoryHelpInfo._(engineLabel: 'Dart (matrix)', refId: 'rref');
  }

  // BigInt helpers (Dart).
  if (s.startsWith('fib(') || s.startsWith('fibonacci(')) {
    return const HistoryHelpInfo._(
        engineLabel: 'Dart (BigInt)', refId: 'fibonacci');
  }

  // --- Special forms ----------------------------------------------------
  // Button-shape derivative: `\frac{d}{dx}\bigg(...\bigg)` lands here
  // post-readable-conversion as `(d)/(dx)(...)`. Manual entry `d/dx(...)`
  // is also covered.
  final dxMatch =
      RegExp(r'^(?:\(d\)/\(d([a-zA-Z])\)|d/d([a-zA-Z]))\(').firstMatch(s);
  if (dxMatch != null) {
    final variable = dxMatch.group(1) ?? dxMatch.group(2) ?? 'x';
    final openIdx = dxMatch.end - 1;
    final body = _extractParenBody(s, openIdx);
    return HistoryHelpInfo._(
      engineLabel: 'SymEngine.diff',
      refId: 'diff',
      stepKind: HistoryStepKind.diff,
      stepExpr: body,
      stepVar: variable,
    );
  }

  // Bare equation: `2x + 3 = 0` or `x^2 - 4 = x + 2`. Auto-routed to
  // SymEngine.solve by the calculator. Skip equations without a free
  // letter (those are direct numeric checks like `2 + 3 = 5`).
  if (s.contains('=') && RegExp(r'[a-zA-Z]').hasMatch(s)) {
    final parts = s.split('=');
    if (parts.length == 2) {
      final lhs = parts[0].trim();
      final rhs = parts[1].trim();
      final body = (rhs.isEmpty || rhs == '0') ? lhs : '($lhs) - ($rhs)';
      final variable = ExpressionPreprocessingUtils.detectVariable(body);
      return HistoryHelpInfo._(
        engineLabel: 'SymEngine.solve',
        refId: 'solve',
        stepKind: HistoryStepKind.solve,
        stepExpr: body,
        stepVar: variable,
      );
    }
  }

  return HistoryHelpInfo.direct;
}

/// Parse the args of a call like `solve(x^2-1, x)` into
/// `['x^2-1', 'x']`. Splits on top-level commas only — nested calls
/// like `solve(f(x,y), x)` produce `['f(x,y)', 'x']`. Returns null
/// when the parens don't balance.
List<String>? _parseCallArgs(String s, String fnName) {
  final prefix = '$fnName(';
  if (!s.startsWith(prefix)) return null;
  if (!s.endsWith(')')) return null;
  final inner = s.substring(prefix.length, s.length - 1);
  final out = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < inner.length; i++) {
    final ch = inner[i];
    if (ch == '(') {
      depth++;
    } else if (ch == ')') {
      if (depth == 0) return null;
      depth--;
    } else if (ch == ',' && depth == 0) {
      out.add(inner.substring(start, i).trim());
      start = i + 1;
    }
  }
  if (depth != 0) return null;
  out.add(inner.substring(start).trim());
  return out;
}

/// Substring between [s][openParenIdx] (which must be `(`) and its
/// matching `)`, or null when no balanced close is found.
String? _extractParenBody(String s, int openParenIdx) {
  if (openParenIdx >= s.length || s[openParenIdx] != '(') return null;
  var depth = 0;
  for (var i = openParenIdx; i < s.length; i++) {
    final ch = s[i];
    if (ch == '(') {
      depth++;
    } else if (ch == ')') {
      depth--;
      if (depth == 0) {
        return s.substring(openParenIdx + 1, i);
      }
    }
  }
  return null;
}

/// The history-row help modal. Construction is decoupled from the
/// calculator screen — the screen passes already-bound callbacks for
/// "Show steps" (re-runs [StepEngine]) and "Learn more" (opens the
/// Function Reference dialog).
class HistoryRowHelpModal extends StatelessWidget {
  const HistoryRowHelpModal({
    super.key,
    required this.entry,
    required this.info,
    this.onShowSteps,
    this.onLearnMore,
  });

  final CalculationEntry entry;
  final HistoryHelpInfo info;
  final VoidCallback? onShowSteps;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ref = info.refId == null
        ? null
        : FunctionReferences.all.firstWhere(
            (e) => e.id == info.refId,
            orElse: () => const FunctionRef(
              id: '',
              category: FunctionRefCategory.cas,
              signature: '',
              shortDescription: '',
            ),
          );

    return AlertDialog(
      title: Text(t.historyHelpTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.expression,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 4),
              Text(
                '= ${entry.result}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (info.hasEngine) ...[
                Text(
                  t.historyHelpComputedVia(info.engineLabel!),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (ref != null && ref.id.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    ref.signature,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(ref.shortDescription),
                ],
              ] else
                Text(t.historyHelpDirectEvaluation),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.dialogClose),
        ),
        if (onShowSteps != null)
          TextButton(
            onPressed: onShowSteps,
            child: Text(t.historyHelpShowSteps),
          ),
        if (onLearnMore != null)
          FilledButton.tonal(
            onPressed: onLearnMore,
            child: Text(t.keypadHelpLearnMore),
          ),
      ],
    );
  }
}
