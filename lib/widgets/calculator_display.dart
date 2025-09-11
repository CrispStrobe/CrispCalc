/// lib/widgets/calculator_display.dart
/// Renders the interactive calculation history list.

import 'package:flutter/material.dart';
import '../engine/app_state.dart';

class CalculatorDisplay extends StatelessWidget {
  const CalculatorDisplay({
    super.key,
    required this.appState,
    required this.onHistoryEntryTap,
  });

  final AppState appState;
  final void Function(String result) onHistoryEntryTap;

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder ensures that this widget rebuilds whenever the AppState
    // notifies its listeners (e.g., when a new entry is added to the history).
    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        if (appState.history.isEmpty) {
          return const Center(
            child: Text(
              'Calculation history will appear here.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          // Reversing the list and the builder shows the newest entry at the bottom.
          reverse: true,
          itemCount: appState.history.length,
          itemBuilder: (context, index) {
            // Because the list is reversed, index 0 is the newest item.
            final entry = appState.history[index];
            return InkWell(
              // The InkWell provides visual feedback on tap and makes history interactive.
              onTap: () => onHistoryEntryTap(entry.result),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Display the original expression.
                    Text(
                      entry.expression,
                      style: TextStyle(fontSize: 20, color: Colors.grey[500]),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    // Display the calculated result.
                    Text(
                      "= ${entry.result}",
                      style: TextStyle(fontSize: 28, color: Colors.blue[300]),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}