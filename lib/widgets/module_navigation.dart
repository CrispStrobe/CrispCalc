// lib/widgets/module_navigation.dart
//
// Shared dispatcher for `open:<module>?<key>=<value>` and `dsl:<id>`
// navigation sentinels. Extracted from `worked_examples_dialog.dart`
// (round 95) so the Function Reference dialog can reuse the exact same
// routing instead of duplicating the parser. Both surfaces stash a
// pre-load id on the appropriate one-shot AppState slot, then push the
// target module screen, which drains the slot in its `initState`.
//
// Recognised sentinels:
//   - `open:sudoku?preset=<id>`     → SudokuPresets.all[id]
//   - `open:statistics?tab=<id>`    → 'descriptive' / 'regression'
//                                     / 'distributions' / 'tests'
//   - `open:statistics?preset=<id>` → StatisticsPresets.all[id]
//                                     (picks the tab + fills inputs)
//   - `open:constraints`            → Constraints module
//   - `open:constraints?cryptarithm=<puzzle>`
//                                   → Constraints module + Cryptarithm
//                                     tab pre-filled with the puzzle
//   - `dsl:<id>`                    → Constraints module + load the
//                                     named DSL gallery program
//
// Unknown keys/modules degrade gracefully — the module still opens (or
// nothing happens), rather than throwing.

import 'package:flutter/material.dart';

import '../engine/app_state.dart';
import '../screens/constraints_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/sudoku_screen.dart';

/// True when [sentinel] is a navigation sentinel this dispatcher
/// understands (an `open:` or `dsl:` prefix). Callers use this to
/// decide whether to route via [dispatchModuleSentinel] or treat the
/// string as a plain calculator expression.
bool isModuleSentinel(String sentinel) =>
    sentinel.startsWith('open:') || sentinel.startsWith('dsl:');

/// Parse and dispatch a navigation [sentinel]. Does NOT pop anything —
/// the caller is expected to have already closed its own dialog if
/// needed (mirrors the prior inline behaviour where the dialog popped
/// before pushing). Returns true if the sentinel was recognised and a
/// route was pushed (or a slot stashed); false otherwise so the caller
/// can fall back to its default handling.
bool dispatchModuleSentinel(BuildContext context, String sentinel) {
  if (sentinel.startsWith('open:')) {
    final spec = sentinel.substring('open:'.length);
    final qIdx = spec.indexOf('?');
    final module = qIdx < 0 ? spec : spec.substring(0, qIdx);
    final argString = qIdx < 0 ? null : spec.substring(qIdx + 1);
    final args = <String, String>{};
    if (argString != null) {
      for (final pair in argString.split('&')) {
        final eq = pair.indexOf('=');
        if (eq > 0) {
          args[pair.substring(0, eq)] = pair.substring(eq + 1);
        }
      }
    }
    switch (module) {
      case 'sudoku':
        final preset = args['preset'];
        if (preset != null) {
          AppState().requestLoadSudokuPreset(preset);
        }
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const SudokuScreen(),
        ));
        return true;
      case 'constraints':
        // `cryptarithm=<puzzle>` pre-fills the Cryptarithm tab (e.g.
        // `SEND+MORE=MONEY`). The puzzle is passed verbatim — the `+`
        // and second `=` survive because the arg parser splits on the
        // FIRST `=` only.
        final cryptarithm = args['cryptarithm'];
        if (cryptarithm != null) {
          AppState().requestLoadCryptarithm(cryptarithm);
        }
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ConstraintsScreen(),
        ));
        return true;
      case 'statistics':
        // `preset=<id>` resolves against StatisticsPresets and both
        // picks the tab and pre-fills the inputs; the older `tab=<id>`
        // just picks the tab.
        final preset = args['preset'];
        final tab = args['tab'];
        if (preset != null) {
          AppState().requestLoadStatisticsPreset(preset);
        }
        if (tab != null) {
          AppState().requestLoadStatisticsTab(tab);
        }
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const StatisticsScreen(),
        ));
        return true;
    }
    return false;
  }
  if (sentinel.startsWith('dsl:')) {
    final id = sentinel.substring('dsl:'.length);
    AppState().requestLoadDslProgram(id);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ConstraintsScreen(),
    ));
    return true;
  }
  return false;
}
