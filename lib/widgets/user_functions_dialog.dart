// lib/widgets/user_functions_dialog.dart
//
// Manage named user-defined functions like `f(x) = x^2 + 1`. The
// preprocessor inlines them inside calculator expressions so
// `f(3) + 1` evaluates to `10 + 1 = 11`. Compose freely:
// `g(f(x))` works as long as both `f` and `g` are defined (the
// preprocessor expands repeatedly up to its depth budget).
//
// One single-letter name per function — keeps the parser simple and
// matches the calculator-app norm. Body can reference any single
// parameter variable (defaulting to `x`).

import 'package:flutter/material.dart';

import '../engine/app_state.dart';
import '../localization/app_localizations.dart';

class UserFunctionsDialog extends StatefulWidget {
  const UserFunctionsDialog({super.key});

  @override
  State<UserFunctionsDialog> createState() => _UserFunctionsDialogState();
}

class _UserFunctionsDialogState extends State<UserFunctionsDialog> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.userFunctionsTitle),
      content: SizedBox(
        width: 480,
        child: ListenableBuilder(
          listenable: _appState,
          builder: (context, _) {
            final fns = _appState.userFunctions.values.toList()
              ..sort((a, b) => a.name.compareTo(b.name));
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.userFunctionsHelp,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        )),
                const SizedBox(height: 12),
                if (fns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      t.userFunctionsEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: fns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final fn = fns[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${fn.name}(${fn.paramVar}) = ${fn.body}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: t.userFunctionsEdit,
                                onPressed: () => _editDialog(context, fn),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                tooltip: t.userFunctionsDelete,
                                onPressed: () =>
                                    _appState.removeUserFunction(fn.name),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(t.userFunctionsAdd),
                    onPressed: () => _editDialog(context, null),
                  ),
                ),
              ],
            );
          },
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

  Future<void> _editDialog(BuildContext context, UserFunction? existing) async {
    final t = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final varCtrl = TextEditingController(text: existing?.paramVar ?? 'x');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title:
              Text(existing == null ? t.userFunctionsAdd : t.userFunctionsEdit),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: t.userFunctionsName,
                      hintText: 'f',
                      helperText: t.userFunctionsNameHelp,
                    ),
                    validator: (s) {
                      final v = s?.trim().toLowerCase() ?? '';
                      if (v.isEmpty) return t.userFunctionsNameRequired;
                      if (!RegExp(r'^[a-z]$').hasMatch(v)) {
                        return t.userFunctionsNameInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: varCtrl,
                    decoration: InputDecoration(
                      labelText: t.userFunctionsParam,
                      hintText: 'x',
                    ),
                    validator: (s) {
                      final v = s?.trim() ?? '';
                      if (v.isEmpty) return t.userFunctionsNameRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: bodyCtrl,
                    decoration: InputDecoration(
                      labelText: t.userFunctionsBody,
                      hintText: 'x^2 + 1',
                    ),
                    validator: (s) => (s?.trim().isEmpty ?? true)
                        ? t.userFunctionsBodyRequired
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                _appState.setUserFunction(UserFunction(
                  name: nameCtrl.text.trim().toLowerCase(),
                  paramVar: varCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                ));
                Navigator.of(ctx).pop();
              },
              child: Text(t.dialogInsert),
            ),
          ],
        );
      },
    );
  }
}
