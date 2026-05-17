// lib/widgets/memory_dialogs.dart
// Memory management dialogs for storing and retrieving calculator results

import 'package:flutter/material.dart';
import '../engine/app_state.dart';

class MemoryDialogs {
  static void showStoreDialog(
    BuildContext context,
    AppState appState,
    Map<String, String> memory,
  ) {
    if (appState.history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No result to store')),
      );
      return;
    }

    final lastResult = appState.history.first.result;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Store: $lastResult'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showSaveAsVariableDialog(context, appState, lastResult);
                    },
                    child: const Text('Save as Variable'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showSaveToMemoryDialog(context, memory, lastResult);
                    },
                    child: const Text('Save to Memory'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static void _showSaveAsVariableDialog(
    BuildContext context,
    AppState appState,
    String value,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Variable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Variable Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., result1',
              ),
            ),
            const SizedBox(height: 8),
            Text('Value: $value'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                appState.setVariable(name, value);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved $name = $value')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static void _showSaveToMemoryDialog(
    BuildContext context,
    Map<String, String> memory,
    String value,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Memory'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Save: $value'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: List.generate(
                      9,
                      (i) => ListTile(
                            title: Text('M${i + 1}'),
                            subtitle: Text(memory['M$i'] ?? 'Empty'),
                            onTap: () {
                              memory['M$i'] = value;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Saved to M${i + 1}')),
                              );
                            },
                          )),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static void showDeleteMemoryDialog(
    BuildContext context,
    Map<String, String> memory,
    VoidCallback onUpdate,
  ) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete Memory'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView(
              shrinkWrap: true,
              children: List.generate(
                  9,
                  (i) => ListTile(
                        title: Text('M${i + 1}'),
                        subtitle: Text(memory['M$i'] ?? 'Empty'),
                        trailing: memory['M$i'] != null
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    memory.remove('M$i');
                                  });
                                  onUpdate();
                                },
                              )
                            : null,
                      )),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                memory.clear();
                Navigator.of(context).pop();
                onUpdate();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All memory cleared')),
                );
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
      ),
    );
  }
}
