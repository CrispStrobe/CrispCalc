/// lib/widgets/variable_viewer.dart
/// Displays a scrollable list of all user-defined variables and functions.

import 'package:flutter/material.dart';
import '../engine/app_state.dart';

class VariableViewer extends StatelessWidget {
  const VariableViewer({
    super.key,
    required this.appState,
    required this.onVariableTap,
  });

  final AppState appState;
  final void Function(String name) onVariableTap;

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder ensures this UI automatically updates whenever
    // a variable or function is added, changed, or removed in AppState.
    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        final variableKeys = appState.userVariables.keys.toList();
        
        // Get non-empty graph functions (Y1, Y2, etc.)
        final graphFunctionEntries = appState.graphFunctions.asMap().entries
            .where((entry) => entry.value.isNotEmpty)
            .toList();
            
        // Get non-empty user functions (F1, F2, etc.)
        final userFunctionEntries = appState.userFunctions.asMap().entries
            .where((entry) => entry.value.isNotEmpty)
            .toList();

        // If no variables or functions have been defined, show a helpful message.
        if (variableKeys.isEmpty && graphFunctionEntries.isEmpty && userFunctionEntries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storage, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No variables or functions defined.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use "name = value" on the main screen to create variables.\nDefine functions in the Function Editor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        // Display the variables and functions in a scrollable list.
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // --- Variables Section ---
            if (variableKeys.isNotEmpty) ...[
              _SectionHeader(
                title: 'Variables',
                icon: Icons.abc,
                onClear: () => _showClearDialog(context, 'variables', () => appState.clearAllVariables()),
              ),
              ...variableKeys.map((key) {
                return _VariableTile(
                  name: key,
                  value: appState.userVariables[key]!,
                  onTap: () => onVariableTap(key),
                  onDelete: () => appState.removeVariable(key),
                );
              }),
              const SizedBox(height: 16),
            ],

            // --- Graph Functions Section (Y1, Y2, etc.) ---
            if (graphFunctionEntries.isNotEmpty) ...[
              _SectionHeader(
                title: 'Graph Functions',
                icon: Icons.show_chart,
                onClear: () => _showClearDialog(context, 'graph functions', () {
                  for (int i = 0; i < appState.graphFunctions.length; i++) {
                    appState.clearFunction(i);
                  }
                }),
              ),
              ...graphFunctionEntries.map((entry) {
                final funcName = 'Y${entry.key + 1}';
                return _FunctionTile(
                  name: funcName,
                  expression: entry.value,
                  color: _getColorForGraphFunction(entry.key),
                  onTap: () => onVariableTap(funcName),
                  onDelete: () => appState.clearFunction(entry.key),
                );
              }),
              const SizedBox(height: 16),
            ],

            // --- User Functions Section (F1, F2, etc.) ---
            if (userFunctionEntries.isNotEmpty) ...[
              _SectionHeader(
                title: 'User Functions',
                icon: Icons.functions,
                onClear: () => _showClearDialog(context, 'user functions', () {
                  for (int i = 0; i < appState.userFunctions.length; i++) {
                    appState.clearUserFunction(i);
                  }
                }),
              ),
              ...userFunctionEntries.map((entry) {
                final funcName = 'F${entry.key + 1}';
                return _FunctionTile(
                  name: funcName,
                  expression: entry.value,
                  color: _getColorForUserFunction(entry.key),
                  onTap: () => onVariableTap(funcName),
                  onDelete: () => appState.clearUserFunction(entry.key),
                );
              }),
            ],

            // Add some bottom padding
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showClearDialog(BuildContext context, String itemType, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All ${itemType.split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}'),
        content: Text('Are you sure you want to clear all $itemType?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Color _getColorForGraphFunction(int index) {
    const colors = [
      Colors.blue, Colors.red, Colors.green, Colors.purple,
      Colors.orange, Colors.teal, Colors.pink, Colors.brown,
      Colors.cyan, Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  Color _getColorForUserFunction(int index) {
    const colors = [
      Colors.deepPurple, Colors.deepOrange, Colors.lightGreen, Colors.amber,
      Colors.blueGrey, Colors.lime, Colors.indigo, Colors.redAccent,
      Colors.tealAccent, Colors.purpleAccent,
    ];
    return colors[index % colors.length];
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClear;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.clear_all, size: 20),
            tooltip: 'Clear all $title',
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _VariableTile extends StatelessWidget {
  final String name;
  final String value;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VariableTile({
    required this.name,
    required this.value,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent.withOpacity(0.2),
        radius: 16,
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blueAccent,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        value,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.keyboard_return, size: 16, color: Colors.grey),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            iconSize: 18,
            tooltip: 'Delete variable',
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _FunctionTile extends StatelessWidget {
  final String name;
  final String expression;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FunctionTile({
    required this.name,
    required this.expression,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        radius: 16,
        child: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color,
        ),
      ),
      subtitle: Text(
        expression,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.keyboard_return, size: 16, color: Colors.grey),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            iconSize: 18,
            tooltip: 'Delete function',
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}