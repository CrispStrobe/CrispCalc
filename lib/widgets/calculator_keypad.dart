// lib/widgets/calculator_keypad.dart
//
// Adaptive keypad with the full key inventory.
//
// Narrow (mobile, < 900 px): a single tab bar with five tabs — Num /
// Trig / CAS / Advanced / Vars. One section visible at a time.
//
// Wide (desktop, >= 900 px): TWO side-by-side panes (no more, no less),
// each with its own little tab bar so the user can pick which content
// goes into the left vs right pane independently. Defaults: Num on the
// left, CAS on the right. That keeps cells a comfortable size — the
// earlier four-section layouts (single row or 2×2 grid) made the
// buttons too small.

import 'package:flutter/material.dart';

import '../engine/app_state.dart';
import '../localization/app_localizations.dart';
import 'function_ref_help_popover.dart';
import 'keypad_grid.dart';
import 'variable_viewer.dart';

const double _kFlatKeypadMinWidth = 900;

enum _PaneKind { num, trig, cas, advanced, vars }

/// Round 102 (P6): per-glyph → FunctionRef.id mapping for the Adv
/// tab. Buttons not in this map carry no popover content; their
/// HelpTarget still renders the help-mode outline but a tap
/// passes through to the normal insert handler. Mapping derived
/// directly from the insert-text side-effects in
/// `calculator_screen.dart`'s `case '<glyph>':` arms — e.g. the
/// `prime` button inserts `isprime()`, so it maps to the
/// `isprime` FunctionRef row.
const Map<String, String> _kAdvKeyHelpRefId = {
  '!': 'factorial',
  'fib': 'fibonacci',
  'prime': 'isprime',
  'matrix': 'matrix_literal',
  'det': 'det',
  'inv': 'inv',
  'transpose': 'transpose',
  'rref': 'rref',
  'π(N)': 'pi_precision',
  'e(N)': 'e_precision',
  'γ(N)': 'eulergamma_precision',
  '√(2,N)': 'sqrt_precision',
  'nextprime': 'nextprime',
  'prevprime': 'prevprime',
  'factorint': 'factorint',
  'divisors': 'divisors',
  'totient': 'totient',
  'modpow': 'modpow',
  'modinv': 'modinv',
  'jacobi': 'jacobi',
  'cfrac': 'cfrac',
  'convergent': 'convergent',
  'polygcd': 'polygcd',
  'polyresultant': 'polyresultant',
  'polydiscriminant': 'polydiscriminant',
  'polyfactor': 'polyfactor',
  // Special functions (SymEngine + MPFR).
  'gamma': 'gamma',
  'zeta': 'zeta',
  'erf': 'erf',
  'lambertw': 'lambertw',
  'beta': 'beta',
  'evalf': 'evalf',
};

/// Round 102b (P6): per-glyph → FunctionRef.id mapping for the CAS
/// tab. The `⌄` step-trace variants (`solve⌄`, `d/dx⌄`, `∫⌄`),
/// the `=` / `,` punctuation, and the `f(x)` user-function template
/// are deliberately absent — they're calculator UX, not engine
/// surface, and have no FunctionRef row. The Adv tab's
/// [_kAdvKeyHelpRefId] documents the same convention.
const Map<String, String> _kCasKeyHelpRefId = {
  'solve': 'solve',
  'factor': 'factor',
  'expand': 'expand',
  'simplify': 'simplify',
  'd/dx': 'diff',
  '∫': 'integrate',
  'lim': 'limit',
  'subst': 'subst',
  'gcd': 'gcd',
  'lcm': 'lcm',
};

/// Round 102: shows a small AlertDialog explaining a single
/// FunctionRef. "Learn more" deep-links to the full Function Reference
/// filtered by id. Round 105b: the implementation now lives in the
/// shared [showFunctionRefHelpPopover] (also used by the Statistics /
/// Constraints / Sudoku module screens); this keeps the keypad's
/// existing call sites working and picks up the localized-description
/// behaviour for free.
void showKeypadHelpPopover(BuildContext context, String refId) =>
    showFunctionRefHelpPopover(context, refId);

class CalculatorKeypad extends StatefulWidget {
  const CalculatorKeypad({
    super.key,
    required this.tabController,
    required this.onButtonPressed,
    required this.localizations,
    required this.appState,
    required this.onVariableTap,
    this.memory,
    this.onMemoryAction,
    this.forceCompact = false,
    this.onGoToGraphing,
    this.onGoToAnalysis,
  });

  final Map<String, String>? memory;
  final void Function(String)? onMemoryAction;

  /// 5-length controller for the narrow (tabbed) layout.
  final TabController tabController;
  final void Function(String) onButtonPressed;
  final AppLocalizations localizations;
  final AppState appState;
  final void Function(String) onVariableTap;

  /// Forwarded to the VariableViewer's function-tile context menu so
  /// "Show on graph" can switch the main nav.
  final VoidCallback? onGoToGraphing;

  /// Forwarded to the VariableViewer's "Analyze" action.
  final VoidCallback? onGoToAnalysis;

  /// Force the tab-bar layout even when there's room to spread out.
  final bool forceCompact;

  @override
  State<CalculatorKeypad> createState() => _CalculatorKeypadState();
}

class _CalculatorKeypadState extends State<CalculatorKeypad> {
  // Wide-mode pane selections — persisted in widget state, not AppState,
  // because they're a quick UI preference, not user data.
  _PaneKind _leftPane = _PaneKind.num;
  _PaneKind _rightPane = _PaneKind.cas;

  // Full key inventory — same content as the narrow tab bar. Cursor
  // movement, backspace, and EXE live in the always-visible input
  // toolbar (see `calculator_screen.dart`), so the per-tab grids stay
  // focused on operators/functions rather than navigation widgets.
  static const List<String> _numKeys = [
    'C',
    'Ans',
    '%',
    '/',
    '7',
    '8',
    '9',
    '*',
    '4',
    '5',
    '6',
    '-',
    '1',
    '2',
    '3',
    '+',
    '0',
    '.',
    '(',
    ')',
    'x',
    '^',
    'sqrt',
    'frac',
    'π',
  ];
  static const List<String> _trigKeys = [
    'sin',
    'cos',
    'tan',
    'ln',
    'asin',
    'acos',
    'atan',
    'log',
    'sinh',
    'cosh',
    'tanh',
    'exp',
    'asinh',
    'acosh',
    'atanh',
    'abs',
    'C',
  ];
  static const List<String> _casKeys = [
    'solve',
    'solve⌄',
    'factor',
    'expand',
    'simplify',
    'd/dx',
    'd/dx⌄',
    '∫',
    '∫⌄',
    'lim',
    'subst',
    'gcd',
    'lcm',
    '=',
    ',',
    'f(x)',
  ];
  static const List<String> _advKeys = [
    'gamma',
    '!',
    'fib',
    'prime',
    'mod',
    'ⁿ√x',
    'γ',
    '∞',
    'matrix',
    'det',
    'inv',
    'transpose',
    'rref',
    'dot',
    'cross',
    'norm',
    'unit',
    'i',
    // Round 92 (P6): precision-arc + number-theory functions. Templates
    // are inserted with the cursor positioned between the parens so
    // typing the precision / target number lands in the right slot.
    'π(N)',
    'e(N)',
    'γ(N)',
    '√(2,N)',
    'nextprime',
    'prevprime',
    'factorint',
    // Round 4 (precision arc): modular arithmetic + multiplicative
    // number theory.
    'divisors',
    'totient',
    'modpow',
    'modinv',
    'jacobi',
    // Group B (precision arc): continued fractions.
    'cfrac',
    'convergent',
    // Group B (precision arc): polynomial arithmetic over ℚ.
    'polygcd',
    'polyresultant',
    'polydiscriminant',
    'polyfactor',
    // Special functions (SymEngine + MPFR). gamma already has a button
    // above; these add the other showpieces.
    'zeta',
    'erf',
    'lambertw',
    'beta',
    // Generic arbitrary-precision numeric evaluation.
    'evalf',
    // Round 112 (P7): relational + logical operators. Inserts the
    // ASCII form with surrounding spaces so the round-110 / 111
    // preprocessor can lower them into SymEngine's Eq/Lt/.../
    // And/Or/Xor/Not function form before dispatch.
    '==',
    '≠',
    '<',
    '≤',
    '>',
    '≥',
    'and',
    'or',
    'not',
    'xor',
    // Round 111b (P7): conditional. Inserts an `if(, , )`
    // template with the cursor positioned right after the `(`
    // so the user types the condition first.
    'if',
  ];

  List<String> _keysFor(_PaneKind kind) {
    switch (kind) {
      case _PaneKind.num:
        return _numKeys;
      case _PaneKind.trig:
        return _trigKeys;
      case _PaneKind.cas:
        return _casKeys;
      case _PaneKind.advanced:
        return _advKeys;
      case _PaneKind.vars:
        return const []; // handled specially
    }
  }

  String _labelFor(_PaneKind kind) {
    final t = widget.localizations;
    switch (kind) {
      case _PaneKind.num:
        return t.tabNum;
      case _PaneKind.trig:
        return t.tabTrig;
      case _PaneKind.cas:
        return t.tabCas;
      case _PaneKind.advanced:
        return t.tabAdvanced;
      case _PaneKind.vars:
        return t.tabVars;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = !widget.forceCompact &&
            constraints.maxWidth >= _kFlatKeypadMinWidth;
        return wide ? _buildTwoPane(context) : _buildTabbed(context);
      },
    );
  }

  // --- Narrow: five tabs ---
  Widget _buildTabbed(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: widget.tabController,
          isScrollable: true,
          tabs: [
            Tab(text: widget.localizations.tabNum),
            Tab(text: widget.localizations.tabTrig),
            Tab(text: widget.localizations.tabCas),
            Tab(text: widget.localizations.tabAdvanced),
            Tab(text: widget.localizations.tabVars),
          ],
        ),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: widget.tabController,
            children: [
              KeypadGrid(
                  buttons: _numKeys, onButtonPressed: widget.onButtonPressed),
              KeypadGrid(
                  buttons: _trigKeys, onButtonPressed: widget.onButtonPressed),
              KeypadGrid(
                buttons: _casKeys,
                onButtonPressed: widget.onButtonPressed,
                helpRefIdFor: (text) => _kCasKeyHelpRefId[text],
                onHelpTap: (refId) => showKeypadHelpPopover(context, refId),
              ),
              KeypadGrid(
                buttons: _advKeys,
                onButtonPressed: widget.onButtonPressed,
                helpRefIdFor: (text) => _kAdvKeyHelpRefId[text],
                onHelpTap: (refId) => showKeypadHelpPopover(context, refId),
              ),
              VariableViewer(
                appState: widget.appState,
                onVariableTap: widget.onVariableTap,
                memory: widget.memory,
                onMemoryAction: widget.onMemoryAction,
                onGoToGraphing: widget.onGoToGraphing,
                onGoToAnalysis: widget.onGoToAnalysis,
                onInsertExpression: widget.onVariableTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Wide: two independently-switchable panes ---
  Widget _buildTwoPane(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _pane(_leftPane, (k) => setState(() => _leftPane = k))),
        const VerticalDivider(width: 1),
        Expanded(
            child: _pane(_rightPane, (k) => setState(() => _rightPane = k))),
      ],
    );
  }

  Widget _pane(_PaneKind kind, void Function(_PaneKind) onChange) {
    return Column(
      children: [
        _paneSelector(kind, onChange),
        const Divider(height: 1),
        Expanded(child: _paneBody(kind)),
      ],
    );
  }

  Widget _paneSelector(_PaneKind kind, void Function(_PaneKind) onChange) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: _PaneKind.values.map((k) {
          final selected = k == kind;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: ChoiceChip(
              label: Text(_labelFor(k)),
              selected: selected,
              onSelected: (_) => onChange(k),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _paneBody(_PaneKind kind) {
    if (kind == _PaneKind.vars) {
      return VariableViewer(
        appState: widget.appState,
        onVariableTap: widget.onVariableTap,
        memory: widget.memory,
        onMemoryAction: widget.onMemoryAction,
        onGoToGraphing: widget.onGoToGraphing,
        onGoToAnalysis: widget.onGoToAnalysis,
        onInsertExpression: widget.onVariableTap,
      );
    }
    // Round 102 / 102b (P6): Adv and CAS panes wire the help-mode
    // popover machinery through. Num + Trig panes are left untouched
    // until a later round catalogues their entries.
    if (kind == _PaneKind.advanced) {
      return KeypadGrid(
        buttons: _advKeys,
        onButtonPressed: widget.onButtonPressed,
        helpRefIdFor: (text) => _kAdvKeyHelpRefId[text],
        onHelpTap: (refId) => showKeypadHelpPopover(context, refId),
      );
    }
    if (kind == _PaneKind.cas) {
      return KeypadGrid(
        buttons: _casKeys,
        onButtonPressed: widget.onButtonPressed,
        helpRefIdFor: (text) => _kCasKeyHelpRefId[text],
        onHelpTap: (refId) => showKeypadHelpPopover(context, refId),
      );
    }
    return KeypadGrid(
      buttons: _keysFor(kind),
      onButtonPressed: widget.onButtonPressed,
    );
  }
}
