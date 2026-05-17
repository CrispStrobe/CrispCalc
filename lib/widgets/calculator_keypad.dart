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
import 'keypad_grid.dart';
import 'variable_viewer.dart';

const double _kFlatKeypadMinWidth = 900;

enum _PaneKind { num, trig, cas, advanced, vars }

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
  });

  final Map<String, String>? memory;
  final void Function(String)? onMemoryAction;

  /// 5-length controller for the narrow (tabbed) layout.
  final TabController tabController;
  final void Function(String) onButtonPressed;
  final AppLocalizations localizations;
  final AppState appState;
  final void Function(String) onVariableTap;

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

  // Full key inventory — same content as the narrow tab bar.
  static const List<String> _numKeys = [
    'C',
    '⌫',
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
    '^',
    'sqrt',
    'π',
    'EXE',
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
    'lim',
    'subst',
    'gcd',
    'lcm',
    '=',
    ',',
    'f(x)',
    '◀',
    '▶',
    'EXE',
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
    'x',
    'Ans',
    'i',
    'EXE',
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
                  buttons: _casKeys, onButtonPressed: widget.onButtonPressed),
              KeypadGrid(
                  buttons: _advKeys, onButtonPressed: widget.onButtonPressed),
              VariableViewer(
                appState: widget.appState,
                onVariableTap: widget.onVariableTap,
                memory: widget.memory,
                onMemoryAction: widget.onMemoryAction,
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
      );
    }
    return KeypadGrid(
      buttons: _keysFor(kind),
      onButtonPressed: widget.onButtonPressed,
    );
  }
}
