// lib/widgets/unit_converter_dialog.dart
//
// Modal unit conversion UI. Pick a category (length, time, mass,
// temperature, velocity, angle), pick from/to units within that
// category, type a value, see the converted result update live.
//
// Doesn't try to handle composite-dimension arithmetic — that's
// V2. For a quick "how many km is 5 miles" question, this is the
// shortest path.

import 'package:flutter/material.dart';

import '../engine/unit_catalog.dart';
import '../engine/unit_converter.dart';
import '../localization/app_localizations.dart';

class UnitConverterDialog extends StatefulWidget {
  const UnitConverterDialog({super.key});

  @override
  State<UnitConverterDialog> createState() => _UnitConverterDialogState();
}

class _UnitConverterDialogState extends State<UnitConverterDialog> {
  UnitDimension _dimension = UnitDimension.length;
  late Unit _from;
  late Unit _to;
  final TextEditingController _input = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    final units = UnitCatalog.unitsFor(_dimension);
    _from = units.first;
    _to = units.length > 1 ? units[1] : units.first;
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _switchDimension(UnitDimension d) {
    final units = UnitCatalog.unitsFor(d);
    setState(() {
      _dimension = d;
      _from = units.first;
      _to = units.length > 1 ? units[1] : units.first;
    });
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  String _resultText() {
    final value = double.tryParse(_input.text);
    if (value == null) return '—';
    final r = UnitConverter.convert(value, _from, _to);
    if (!r.ok) return r.error ?? 'Error';
    return UnitConverter.format(r.value, r.unit);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final units = UnitCatalog.unitsFor(_dimension);
    return AlertDialog(
      title: Text(t.moduleUnitConverterTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dimension chip row — quick pick across categories.
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final d in UnitCatalog.allDimensions())
                  ChoiceChip(
                    label: Text(_dimensionLabel(d, t)),
                    selected: _dimension == d,
                    onSelected: (_) => _switchDimension(d),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Value field.
            TextField(
              controller: _input,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: t.dialogValue,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // From/To row with a swap button in the middle.
            Row(
              children: [
                Expanded(
                    child: _unitDropdown(
                        _from, (u) => setState(() => _from = u!), units)),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Swap',
                  onPressed: _swap,
                ),
                Expanded(
                    child: _unitDropdown(
                        _to, (u) => setState(() => _to = u!), units)),
              ],
            ),
            const SizedBox(height: 16),
            // Result block.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.east,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _resultText(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _unitDropdown(
      Unit current, ValueChanged<Unit?> onChanged, List<Unit> units) {
    return DropdownButtonFormField<Unit>(
      initialValue: current,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final u in units)
          DropdownMenuItem(
            value: u,
            child: Text('${u.symbol} — ${u.name}',
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }

  String _dimensionLabel(UnitDimension d, AppLocalizations t) {
    switch (d) {
      case UnitDimension.length:
        return t.unitDimLength;
      case UnitDimension.time:
        return t.unitDimTime;
      case UnitDimension.mass:
        return t.unitDimMass;
      case UnitDimension.temperature:
        return t.unitDimTemperature;
      case UnitDimension.velocity:
        return t.unitDimVelocity;
      case UnitDimension.angle:
        return t.unitDimAngle;
    }
  }
}
