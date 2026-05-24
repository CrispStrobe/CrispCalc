// lib/widgets/steps_dialog.dart
//
// Renders a list of MathStep entries as an expandable card list.
// Each card shows the rule name, a LaTeX-rendered formula, the
// before/after expressions (also LaTeX), and any plain-language note.
//
// LaTeX rendering uses flutter_math_fork (already a dep). When LaTeX
// parsing fails on a particular step's expression we fall back to a
// monospace text rendering so the dialog never goes blank.

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../engine/step_engine.dart';
import '../localization/app_localizations.dart';
import '../utils/math_display_utils.dart';

class StepsDialog extends StatelessWidget {
  final String title;
  final String expression;
  final String variable;
  final List<MathStep> steps;

  /// Optional override of the small subtitle line above the headline
  /// expression. When null, the dialog picks a sensible default based
  /// on the title.
  final String? subtitle;

  /// Optional override of the LaTeX shown as the dialog headline. When
  /// null, the headline is `d/dvar[expression]` (differentiation flow).
  final String? headlineLatex;

  const StepsDialog({
    super.key,
    required this.title,
    required this.expression,
    required this.variable,
    required this.steps,
    this.subtitle,
    this.headlineLatex,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle ?? t.differentiationStepsHeader(variable),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              _latex(
                context,
                headlineLatex ??
                    r'\frac{d}{d' +
                        variable +
                        r'}\left[' +
                        _toLatex(expression) +
                        r'\right]',
              ),
              const Divider(height: 24),
              for (final s in steps) _stepCard(context, s),
            ],
          ),
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

  Widget _stepCard(BuildContext context, MathStep s) {
    final isResult = s.rule == 'Result';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isResult ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isResult ? Icons.check_circle : Icons.bolt_outlined,
                  size: 18,
                  color: isResult
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  s.rule,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isResult
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
              ],
            ),
            if (s.formula.isNotEmpty) ...[
              const SizedBox(height: 6),
              _latex(context, s.formula),
            ],
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _latex(context, _bracketToFracLatex(s.before)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.east, size: 18),
                ),
                Expanded(child: _latex(context, _toLatex(s.after))),
              ],
            ),
            if (s.note != null || s.noteI18n != null) ...[
              const SizedBox(height: 6),
              Builder(builder: (ctx) {
                final t = AppLocalizations.of(ctx);
                final localized =
                    s.noteI18n == null ? null : t.stepNote(s.noteI18n!);
                final text = localized ?? s.note ?? '';
                if (text.isEmpty) return const SizedBox.shrink();
                return Text(
                  text,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// Tries to render [latex] with flutter_math_fork; falls back to a
  /// monospace text widget if the parser chokes. flutter_math_fork's
  /// `onErrorFallback` keeps the dialog robust against any malformed
  /// step string.
  Widget _latex(BuildContext context, String latex) {
    return Math.tex(
      latex,
      textStyle: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onErrorFallback: (_) => Text(
        latex,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  /// Engine step strings use `d/dvar[...]` and `·` and a few other
  /// shorthand sigils. Convert to LaTeX so they render nicely.
  String _bracketToFracLatex(String s) {
    // d/dvar[...] → \frac{d}{dvar}[...]
    return s
        .replaceAllMapped(
          RegExp(r'd/d([a-zA-Z_][a-zA-Z0-9_]*)\['),
          (m) => r'\frac{d}{d' + m.group(1)! + r'}\left[',
        )
        .replaceAll(']', r'\right]')
        .let(_toLatex);
  }

  String _toLatex(String s) {
    // MathDisplayUtils handles the common LaTeX-ification (fractions,
    // exponents, basic functions). Step strings additionally use `·` as
    // a multiplication sigil for readability; LaTeX wants `\cdot`.
    final pre = s.replaceAll('·', r' \cdot ');
    return MathDisplayUtils.toHistoryDisplayLatex(pre);
  }
}

extension on String {
  String let(String Function(String) f) => f(this);
}
