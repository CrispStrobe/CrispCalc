/// lib/widgets/calculator_keypad.dart
/// Renders the tabbed keypad for all calculator functions and the variable viewer.

import 'package:flutter/material.dart';
import '../engine/app_state.dart';
import '../localization/app_localizations.dart';
import '../widgets/keypad_grid.dart';
import '../widgets/variable_viewer.dart';

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({
    super.key,
    required this.tabController,
    required this.onButtonPressed,
    required this.localizations,
    required this.appState,
    required this.onVariableTap,
  });

  final TabController tabController;
  final void Function(String) onButtonPressed;
  final AppLocalizations localizations;
  final AppState appState;
  final void Function(String) onVariableTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: [
            Tab(text: localizations.tabNum),
            Tab(text: localizations.tabTrig),
            Tab(text: localizations.tabCas),
            Tab(text: localizations.tabAdvanced),
            Tab(text: localizations.tabVars), // Updated from "Mem"
          ],
        ),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(), // Prevents swipe-to-change-tab
            controller: tabController,
            children: [
              // 1. Basic numbers and operations
              KeypadGrid(buttons: const [
                'C','⌫','%','/','7','8','9','*','4','5','6','-','1','2','3','+','(',')','^','EXE'
              ], onButtonPressed: onButtonPressed),
              
              // 2. Trigonometric and basic functions
              KeypadGrid(buttons: const [
                'sin','cos','tan','x','asin','acos','atan','(','sinh','cosh','tanh',')','ln','log','sqrt','EXE'
              ], onButtonPressed: onButtonPressed),
              
              // 3. Computer Algebra System functions
              KeypadGrid(buttons: const [
                'solve','factor','expand','d/dx','simplify','f(x)','∫','lim','gcd','lcm','=','◀',',','π','e','γ'
              ], onButtonPressed: onButtonPressed),
              
              // 4. Advanced mathematical functions
              KeypadGrid(buttons: const [
                'abs','gamma','!','matrix','ⁿ√x','det','inv','transpose','◀','asinh','acosh','atanh','▶','fib','prime','mod','EXE'
              ], onButtonPressed: onButtonPressed),
              
              // 5. The new, dynamic variable and function viewer
              VariableViewer(
                appState: appState,
                onVariableTap: onVariableTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}