// lib/widgets/variable_viewer.dart
// Displays a scrollable list of all user-defined variables, functions, and memory slots.

import 'package:flutter/material.dart';
import '../engine/app_state.dart';

class VariableViewer extends StatelessWidget {
  const VariableViewer({
    super.key,
    required this.appState,
    required this.onVariableTap,
    this.memory,
    this.onMemoryAction,
  });

  final AppState appState;
  final void Function(String name) onVariableTap;
  final Map<String, String>? memory;
  final void Function(String action)? onMemoryAction;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        final variableKeys = appState.userVariables.keys.toList();

        // Get non-empty graph functions (Y1, Y2, etc.)
        final graphFunctionEntries = appState.graphFunctions
            .asMap()
            .entries
            .where((entry) => entry.value.isNotEmpty)
            .toList();

        final hasMemory = memory != null && onMemoryAction != null;
        final hasAnyContent = variableKeys.isNotEmpty ||
            graphFunctionEntries.isNotEmpty ||
            (hasMemory && memory!.isNotEmpty);

        // Single scroll container so the memory controls don't overflow on
        // short viewports — previously they were pinned to the bottom and
        // would clip when the side panel got compressed.
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasAnyContent)
                _buildEmptyState()
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Variables Section ---
                    if (variableKeys.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Variables',
                        icon: Icons.abc,
                        onClear: () => _showClearDialog(context, 'variables',
                            () => appState.clearAllVariables()),
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
                        onClear: () =>
                            _showClearDialog(context, 'graph functions', () {
                          for (int i = 0;
                              i < appState.graphFunctions.length;
                              i++) {
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
                          onTap: () => onVariableTap(entry.value),
                          onDelete: () => appState.clearFunction(entry.key),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // --- Memory Section ---
                    if (hasMemory && memory!.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Memory Slots',
                        icon: Icons.memory,
                        onClear: () => _showClearDialog(context, 'memory slots',
                            () => onMemoryAction!('CLEAR_ALL')),
                      ),
                      ...List.generate(9, (i) {
                        final memKey = 'M$i';
                        final memName = 'M${i + 1}';
                        final memValue = memory![memKey];

                        if (memValue != null) {
                          return _MemoryTile(
                            name: memName,
                            value: memValue,
                            onTap: () => onMemoryAction!(memName),
                            onDelete: () => onMemoryAction!('DELETE_$memName'),
                          );
                        }
                        return const SizedBox.shrink();
                      }).where((widget) => widget is! SizedBox),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
              if (hasMemory) _buildMemoryControls(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
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

  Widget _buildMemoryControls(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Memory action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MemoryActionButton(
                label: 'STO',
                icon: Icons.save,
                color: Colors.green,
                onPressed: () => onMemoryAction!('STO'),
              ),
              _MemoryActionButton(
                label: 'DEL',
                icon: Icons.delete,
                color: Colors.red,
                onPressed: () => onMemoryAction!('DEL'),
              ),
              _MemoryActionButton(
                label: 'Ans',
                icon: Icons.replay,
                color: Colors.blue,
                onPressed: () => onMemoryAction!('Ans'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Memory slots — fixed-size tiles in a wrap so they never stretch
          // to cover the parent's full width on wide screens (the old
          // GridView blew the maxHeight when crossAxisCount didn't divide
          // the width neatly).
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(9, (i) {
              final memKey = 'M$i';
              final memName = 'M${i + 1}';
              final hasValue = memory!.containsKey(memKey);
              return SizedBox(
                width: 64,
                height: 36,
                child: _MemorySlotButton(
                  name: memName,
                  hasValue: hasValue,
                  value: hasValue ? memory![memKey] : null,
                  onPressed: () => onMemoryAction!(memName),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(
      BuildContext context, String itemType, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Clear All ${itemType.split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}'),
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
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
      Colors.indigo,
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
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
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
        backgroundColor: color.withValues(alpha: 0.2),
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

class _MemoryTile extends StatelessWidget {
  final String name;
  final String value;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MemoryTile({
    required this.name,
    required this.value,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withValues(alpha: 0.2),
        radius: 16,
        child: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.orange,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.orange,
        ),
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
            tooltip: 'Delete memory slot',
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _MemoryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _MemoryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemorySlotButton extends StatelessWidget {
  final String name;
  final bool hasValue;
  final String? value;
  final VoidCallback onPressed;

  const _MemorySlotButton({
    required this.name,
    required this.hasValue,
    this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: hasValue
          ? Colors.orange.withValues(alpha: 0.15)
          : Colors.grey.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasValue
                  ? Colors.orange.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: hasValue ? Colors.orange : Colors.grey[600],
                ),
              ),
              if (hasValue && value != null) ...[
                const SizedBox(height: 2),
                Text(
                  value!.length > 8 ? '${value!.substring(0, 8)}...' : value!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
