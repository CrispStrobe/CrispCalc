// lib/engine/app_state.dart
//
// Singleton app state with a small persistence layer on top of
// shared_preferences. Everything that should survive a relaunch is saved
// the moment it changes:
//   - locale (en/de)
//   - number display format
//   - theme mode (system/light/dark)
//   - calculation history (capped at 200 entries)
//   - user variables
//   - graph function slots (Y1..Y10)
//
// JSON-encoded for the collection fields so they stay readable in a prefs
// dump and don't need a separate format-version field today.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HistoryEntryType { calculation, solve }

enum NumberDisplayFormat {
  integer,
  oneDecimal,
  twoDecimal,
  auto,
}

class CalculationEntry {
  final String expression;
  final String result;
  final HistoryEntryType type;

  CalculationEntry({
    required this.expression,
    required this.result,
    this.type = HistoryEntryType.calculation,
  });

  Map<String, dynamic> toJson() => {
        'e': expression,
        'r': result,
        't': type.name,
      };

  static CalculationEntry fromJson(Map<String, dynamic> j) => CalculationEntry(
        expression: j['e'] as String? ?? '',
        result: j['r'] as String? ?? '',
        type: HistoryEntryType.values.firstWhere(
          (v) => v.name == j['t'],
          orElse: () => HistoryEntryType.calculation,
        ),
      );
}

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  AppState._internal() {
    graphFunctions = List.generate(_kGraphSlotCount, (_) => '');
    // Default examples — replaced once load() restores user data.
    graphFunctions[0] = 'sin(x)';
    graphFunctions[1] = 'x^2 - 2';
  }

  static const _kLocale = 'crisp.locale';
  static const _kNumberFormat = 'crisp.numberFormat';
  static const _kThemeMode = 'crisp.themeMode';
  static const _kHistory = 'crisp.history';
  static const _kVariables = 'crisp.variables';
  static const _kFunctions = 'crisp.functions';
  static const _kParameters = 'crisp.parameters';

  static const int _kGraphSlotCount = 10;
  static const int _kHistoryCap = 200;

  SharedPreferences? _prefs;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  NumberDisplayFormat _numberFormat = NumberDisplayFormat.auto;
  NumberDisplayFormat get numberFormat => _numberFormat;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  /// Read persisted settings into memory. Must be awaited before runApp.
  /// Pass `force: true` (from tests) to re-read prefs after they've been
  /// mocked with new values — production callers should leave this alone.
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    // Reset to defaults before reading so an empty mock prefs map gives
    // defaults instead of whatever the previous test left behind.
    _locale = const Locale('en');
    _numberFormat = NumberDisplayFormat.auto;
    _themeMode = ThemeMode.dark;
    history.clear();
    userVariables.clear();
    functionParameters.clear();
    for (var i = 0; i < graphFunctions.length; i++) {
      graphFunctions[i] = '';
    }
    // Restore the demo examples; user data (if any) overwrites them below.
    graphFunctions[0] = 'sin(x)';
    graphFunctions[1] = 'x^2 - 2';

    try {
      _prefs = await SharedPreferences.getInstance();
      final lang = _prefs!.getString(_kLocale);
      if (lang != null && (lang == 'en' || lang == 'de')) {
        _locale = Locale(lang);
      }
      final formatName = _prefs!.getString(_kNumberFormat);
      if (formatName != null) {
        _numberFormat = NumberDisplayFormat.values.firstWhere(
          (v) => v.name == formatName,
          orElse: () => NumberDisplayFormat.auto,
        );
      }
      final themeName = _prefs!.getString(_kThemeMode);
      if (themeName != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (v) => v.name == themeName,
          orElse: () => ThemeMode.dark,
        );
      }
      _restoreList<CalculationEntry>(
        key: _kHistory,
        target: history,
        fromJson: (j) => CalculationEntry.fromJson(j as Map<String, dynamic>),
      );
      final varJson = _prefs!.getString(_kVariables);
      if (varJson != null) {
        try {
          final map = jsonDecode(varJson) as Map<String, dynamic>;
          for (final entry in map.entries) {
            userVariables[entry.key] = entry.value.toString();
          }
        } catch (e) {
          debugPrint('STATE: failed to parse variables: $e');
        }
      }
      final funcJson = _prefs!.getString(_kFunctions);
      if (funcJson != null) {
        try {
          final list = jsonDecode(funcJson) as List<dynamic>;
          for (var i = 0; i < graphFunctions.length && i < list.length; i++) {
            graphFunctions[i] = list[i]?.toString() ?? '';
          }
        } catch (e) {
          debugPrint('STATE: failed to parse functions: $e');
        }
      }
      final paramJson = _prefs!.getString(_kParameters);
      if (paramJson != null) {
        try {
          final map = jsonDecode(paramJson) as Map<String, dynamic>;
          for (final entry in map.entries) {
            final slot = int.tryParse(entry.key);
            if (slot == null) continue;
            final inner = entry.value as Map<String, dynamic>;
            functionParameters[slot] = {
              for (final p in inner.entries)
                p.key: (p.value as num).toDouble(),
            };
          }
        } catch (e) {
          debugPrint('STATE: failed to parse parameters: $e');
        }
      }
    } catch (e) {
      debugPrint('STATE: failed to load prefs: $e');
    }
    _loaded = true;
  }

  void _restoreList<T>({
    required String key,
    required List<T> target,
    required T Function(dynamic) fromJson,
  }) {
    final raw = _prefs?.getString(key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        target.clear();
        for (final item in decoded) {
          target.add(fromJson(item));
        }
      }
    } catch (e) {
      debugPrint('STATE: failed to restore $key: $e');
    }
  }

  void setLocale(Locale locale) {
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
    _prefs?.setString(_kLocale, locale.languageCode);
    notifyListeners();
  }

  void setNumberFormat(NumberDisplayFormat format) {
    if (_numberFormat == format) return;
    _numberFormat = format;
    _prefs?.setString(_kNumberFormat, format.name);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _prefs?.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  // --- Volatile (now also persisted) state --------------------------------

  final List<CalculationEntry> history = [];
  final Map<String, String> userVariables = {};
  late final List<String> graphFunctions;

  /// Parameter values per graph slot. Keyed by slot index, then by
  /// parameter name. Used by the graphing screen's slider panel: any
  /// identifier in a function string that isn't `x` (or a reserved
  /// constant / function name) becomes a parameter; this map carries
  /// its current value, defaulting to 1.0 the first time it's seen.
  final Map<int, Map<String, double>> functionParameters = {};

  String formatNumber(String numberString) {
    final number = double.tryParse(numberString);
    if (number == null) return numberString;

    switch (_numberFormat) {
      case NumberDisplayFormat.integer:
        return number.round().toString();
      case NumberDisplayFormat.oneDecimal:
        return number.toStringAsFixed(1);
      case NumberDisplayFormat.twoDecimal:
        return number.toStringAsFixed(2);
      case NumberDisplayFormat.auto:
        return number == number.roundToDouble()
            ? number.round().toString()
            : number.toString();
    }
  }

  void addHistoryEntry(String expression, String result,
      {HistoryEntryType type = HistoryEntryType.calculation}) {
    final formatted = formatNumber(result);
    history.insert(
        0,
        CalculationEntry(
            expression: expression, result: formatted, type: type));
    while (history.length > _kHistoryCap) {
      history.removeLast();
    }
    _persistHistory();
    notifyListeners();
  }

  void _persistHistory() {
    _prefs?.setString(
      _kHistory,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }

  void _persistVariables() {
    _prefs?.setString(_kVariables, jsonEncode(userVariables));
  }

  void _persistFunctions() {
    _prefs?.setString(_kFunctions, jsonEncode(graphFunctions));
  }

  void _persistParameters() {
    _prefs?.setString(
      _kParameters,
      jsonEncode(functionParameters.map(
        (slot, params) => MapEntry(slot.toString(), params),
      )),
    );
  }

  /// Current value of [name] for the function in [slot], defaulting to
  /// 1.0 the first time we see it. Auto-creates the per-slot map so
  /// callers don't have to.
  double getParameter(int slot, String name) {
    final params = functionParameters.putIfAbsent(slot, () => {});
    return params.putIfAbsent(name, () => 1.0);
  }

  void setParameter(int slot, String name, double value) {
    final params = functionParameters.putIfAbsent(slot, () => {});
    if (params[name] == value) return;
    params[name] = value;
    _persistParameters();
    notifyListeners();
  }

  /// Drop any parameters for [slot] that aren't in [keep]. Called by the
  /// graphing screen after a function string changes so stale slider
  /// state doesn't accumulate.
  void pruneParameters(int slot, Set<String> keep) {
    final params = functionParameters[slot];
    if (params == null) return;
    var changed = false;
    for (final k in params.keys.toList()) {
      if (!keep.contains(k)) {
        params.remove(k);
        changed = true;
      }
    }
    if (changed) {
      if (params.isEmpty) functionParameters.remove(slot);
      _persistParameters();
      notifyListeners();
    }
  }

  void setVariable(String name, String value) {
    userVariables[name] = value;
    _persistVariables();
    notifyListeners();
  }

  String? getVariable(String name) => userVariables[name];

  void removeVariable(String name) {
    if (userVariables.containsKey(name)) {
      userVariables.remove(name);
      _persistVariables();
      notifyListeners();
    }
  }

  void updateFunction(int index, String expression) {
    if (index >= 0 && index < graphFunctions.length) {
      if (graphFunctions[index] != expression) {
        graphFunctions[index] = expression;
        _persistFunctions();
        notifyListeners();
      }
    }
  }

  void clearFunction(int index) {
    if (index >= 0 && index < graphFunctions.length) {
      if (graphFunctions[index].isNotEmpty) {
        graphFunctions[index] = '';
        functionParameters.remove(index);
        _persistFunctions();
        _persistParameters();
        notifyListeners();
      }
    }
  }

  String getGraphFunction(int index) {
    if (index >= 0 && index < graphFunctions.length) {
      return graphFunctions[index];
    }
    return '';
  }

  void clearHistory() {
    history.clear();
    _persistHistory();
    notifyListeners();
  }

  void clearAllVariables() {
    userVariables.clear();
    _persistVariables();
    notifyListeners();
  }

  void clearAllFunctions() {
    for (int i = 0; i < graphFunctions.length; i++) {
      graphFunctions[i] = '';
    }
    _persistFunctions();
    notifyListeners();
  }
}
