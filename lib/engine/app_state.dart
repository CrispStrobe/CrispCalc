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

import '../utils/exact_integer.dart';
import 'notepad.dart';
import 'scene_3d/scene_object.dart';
import 'scene_3d/scene_state.dart';

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

/// A named, user-defined function. Stored by AppState and inlined by
/// [ExpressionPreprocessingUtils] when the calculator encounters
/// `<name>(<arg>)` in an expression. Supports composition via
/// successive expansion passes (`g(f(x))` works as long as both `f` and
/// `g` are defined). One single-letter parameter per function — kept
/// minimal to match the calculator-app norm and avoid having to ship a
/// real argument-list parser.
class UserFunction {
  /// Identifier used in expressions. Must be a single letter so it can
  /// never collide with built-in function names like `sin`, `gcd`,
  /// `Matrix`. Lowercased on save; ASCII letters only.
  final String name;

  /// Parameter variable. Defaults to `x`.
  final String paramVar;

  /// Right-hand side of the definition. e.g. `x^2 + 1`.
  final String body;

  const UserFunction({
    required this.name,
    required this.paramVar,
    required this.body,
  });

  Map<String, dynamic> toJson() => {
        'n': name,
        'v': paramVar,
        'b': body,
      };

  static UserFunction fromJson(Map<String, dynamic> j) => UserFunction(
        name: (j['n'] as String? ?? '').toLowerCase(),
        paramVar: j['v'] as String? ?? 'x',
        body: j['b'] as String? ?? '',
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
  static const _kDecimalPlaces = 'crisp.decimalPlaces';
  static const _kThemeMode = 'crisp.themeMode';
  static const _kHistory = 'crisp.history';
  static const _kVariables = 'crisp.variables';
  static const _kFunctions = 'crisp.functions';
  static const _kParameters = 'crisp.parameters';
  static const _kExactIntegerMode = 'crisp.exactIntegerMode';
  static const _kOnboardingDismissed = 'crisp.onboardingDismissed';
  static const _kAutoBindSolve = 'crisp.autoBindSolve';
  static const _kUserFunctions = 'crisp.userFunctions';
  static const _kNotepadDocs = 'crisp.notepadDocs';
  static const _kCurrentNotepadDoc = 'crisp.currentNotepadDoc';
  static const _kScene3D = 'crisp.scene3d';

  static const int _kGraphSlotCount = 10;
  static const int _kHistoryCap = 200;

  SharedPreferences? _prefs;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  NumberDisplayFormat _numberFormat = NumberDisplayFormat.auto;
  NumberDisplayFormat get numberFormat => _numberFormat;

  /// Arbitrary-N decimal-places setting. Replaces the
  /// [NumberDisplayFormat] enum's hard-coded 0/1/2-only choices.
  /// `-1` means "auto" (existing default — keep integers as integers,
  /// non-integer doubles render with Dart's `toString`). `0` ≤ n
  /// means render via `toStringAsFixed(n)`.
  ///
  /// The legacy enum is kept for backwards-compat (existing tests +
  /// older prefs blobs round-trip cleanly) but the int is the
  /// canonical setting now. [setNumberFormat] migrates to the int.
  int _decimalPlaces = -1;
  int get decimalPlaces => _decimalPlaces;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  /// When true (default), integer-shaped engine results like `100!` are
  /// kept verbatim — full digit string preserved through the display
  /// pipeline rather than going through a lossy double round-trip.
  /// Toggle off to fall back to the old `numberFormat`-driven behavior
  /// (handy if someone wants compact scientific-notation displays even
  /// for big factorials).
  bool _exactIntegerMode = true;
  bool get exactIntegerMode => _exactIntegerMode;

  /// True once the user has completed or skipped the first-launch tour
  /// (or pressed "Don't show again" from the Settings re-trigger). The
  /// main screen checks this on each launch and shows the
  /// `OnboardingTour` overlay when false.
  bool _onboardingDismissed = false;
  bool get onboardingDismissed => _onboardingDismissed;

  /// When true, `solve(eq, x)` in the calculator/notepad also stores
  /// the solution into `AppState.userVariables` (variable `x`), so a
  /// subsequent `x + 1`-style expression resolves with that value.
  /// Default off — standard CAS behavior is stateless (Mathematica,
  /// SymPy, TI all return a solution without rebinding the variable).
  /// Multi-solution results pick the first numeric value; if no
  /// numeric value can be extracted nothing is stored.
  bool _autoBindSolve = false;
  bool get autoBindSolve => _autoBindSolve;

  /// Read persisted settings into memory. Must be awaited before runApp.
  /// Pass `force: true` (from tests) to re-read prefs after they've been
  /// mocked with new values — production callers should leave this alone.
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    // Reset to defaults before reading so an empty mock prefs map gives
    // defaults instead of whatever the previous test left behind.
    _locale = const Locale('en');
    _numberFormat = NumberDisplayFormat.auto;
    _decimalPlaces = -1;
    _themeMode = ThemeMode.dark;
    _exactIntegerMode = true;
    _onboardingDismissed = false;
    _autoBindSolve = false;
    history.clear();
    userVariables.clear();
    userFunctions.clear();
    functionParameters.clear();
    notepadDocuments.clear();
    _currentNotepadDocId = null;
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
        // Migrate legacy enum to the int. Persisted int takes
        // precedence (read just below); this line only matters when
        // the saved blob predates the int setting.
        _decimalPlaces = _enumToDecimalPlaces(_numberFormat);
      }
      final dp = _prefs!.getInt(_kDecimalPlaces);
      if (dp != null) _decimalPlaces = dp;
      final themeName = _prefs!.getString(_kThemeMode);
      if (themeName != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (v) => v.name == themeName,
          orElse: () => ThemeMode.dark,
        );
      }
      final exactMode = _prefs!.getBool(_kExactIntegerMode);
      if (exactMode != null) _exactIntegerMode = exactMode;
      final onboarded = _prefs!.getBool(_kOnboardingDismissed);
      if (onboarded != null) _onboardingDismissed = onboarded;
      final autoBind = _prefs!.getBool(_kAutoBindSolve);
      if (autoBind != null) _autoBindSolve = autoBind;
      final udfJson = _prefs!.getString(_kUserFunctions);
      if (udfJson != null) {
        try {
          final list = jsonDecode(udfJson) as List<dynamic>;
          for (final raw in list) {
            final f = UserFunction.fromJson(raw as Map<String, dynamic>);
            if (f.name.isNotEmpty) userFunctions[f.name] = f;
          }
        } catch (e) {
          debugPrint('STATE: failed to parse user functions: $e');
        }
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
              for (final p in inner.entries) p.key: (p.value as num).toDouble(),
            };
          }
        } catch (e) {
          debugPrint('STATE: failed to parse parameters: $e');
        }
      }
      final notepadJson = _prefs!.getString(_kNotepadDocs);
      if (notepadJson != null) {
        try {
          final list = jsonDecode(notepadJson) as List<dynamic>;
          for (final raw in list) {
            if (raw is Map) {
              final doc =
                  NotepadDocument.fromJson(Map<String, dynamic>.from(raw));
              if (doc.id.isNotEmpty) notepadDocuments[doc.id] = doc;
            }
          }
        } catch (e) {
          debugPrint('STATE: failed to parse notepad docs: $e');
        }
      }
      _currentNotepadDocId = _prefs!.getString(_kCurrentNotepadDoc);
      final sceneJson = _prefs!.getString(_kScene3D);
      if (sceneJson != null) {
        try {
          final raw = jsonDecode(sceneJson);
          if (raw is Map) {
            _scene3D = Scene3D.fromJson(Map<String, dynamic>.from(raw));
          }
        } catch (e) {
          debugPrint('STATE: failed to parse scene3D: $e');
        }
      }
    } catch (e) {
      debugPrint('STATE: failed to load prefs: $e');
    }
    // First-launch seed (decision #7): empty `Untitled` + the static
    // `Welcome` sample. Runs whenever there are zero notepad docs,
    // not just on a literal first launch — if a user deletes every
    // doc (including Welcome) and relaunches, they get a clean slate
    // back. The Welcome sample is always recreated from the constant
    // so its content stays in sync across releases.
    if (notepadDocuments.isEmpty) {
      final untitled = NotepadDocument.fresh(name: 'Untitled');
      final welcome = buildWelcomeNotepadDocument();
      notepadDocuments[untitled.id] = untitled;
      notepadDocuments[welcome.id] = welcome;
      _currentNotepadDocId = untitled.id;
      _persistNotepadDocs();
      _persistCurrentNotepadDoc();
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
    final dp = _enumToDecimalPlaces(format);
    if (_numberFormat == format && _decimalPlaces == dp) return;
    _numberFormat = format;
    _decimalPlaces = dp;
    _prefs?.setString(_kNumberFormat, format.name);
    _prefs?.setInt(_kDecimalPlaces, dp);
    notifyListeners();
  }

  /// Canonical API for "render numeric results with N decimal places".
  /// `-1` = auto (integer-shaped values stay integers; non-integer
  /// doubles render with Dart's `toString`). `0` ≤ N ≤ 15 renders
  /// via `toStringAsFixed(N)`. Values are clamped on the caller side
  /// (the Settings slider goes 0–10).
  void setDecimalPlaces(int n) {
    if (_decimalPlaces == n) return;
    _decimalPlaces = n;
    // Keep the legacy enum in sync for serialization parity and
    // for any consumer that still reads `numberFormat`. Anything
    // outside the enum's range maps to `auto`.
    _numberFormat = _decimalPlacesToEnum(n);
    _prefs?.setInt(_kDecimalPlaces, n);
    _prefs?.setString(_kNumberFormat, _numberFormat.name);
    notifyListeners();
  }

  static int _enumToDecimalPlaces(NumberDisplayFormat f) {
    switch (f) {
      case NumberDisplayFormat.auto:
        return -1;
      case NumberDisplayFormat.integer:
        return 0;
      case NumberDisplayFormat.oneDecimal:
        return 1;
      case NumberDisplayFormat.twoDecimal:
        return 2;
    }
  }

  static NumberDisplayFormat _decimalPlacesToEnum(int n) {
    switch (n) {
      case 0:
        return NumberDisplayFormat.integer;
      case 1:
        return NumberDisplayFormat.oneDecimal;
      case 2:
        return NumberDisplayFormat.twoDecimal;
      default:
        return NumberDisplayFormat.auto;
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _prefs?.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  void setExactIntegerMode(bool enabled) {
    if (_exactIntegerMode == enabled) return;
    _exactIntegerMode = enabled;
    _prefs?.setBool(_kExactIntegerMode, enabled);
    notifyListeners();
  }

  void setOnboardingDismissed(bool dismissed) {
    if (_onboardingDismissed == dismissed) return;
    _onboardingDismissed = dismissed;
    _prefs?.setBool(_kOnboardingDismissed, dismissed);
    notifyListeners();
  }

  void setAutoBindSolve(bool enabled) {
    if (_autoBindSolve == enabled) return;
    _autoBindSolve = enabled;
    _prefs?.setBool(_kAutoBindSolve, enabled);
    notifyListeners();
  }

  void setUserFunction(UserFunction fn) {
    userFunctions[fn.name] = fn;
    _persistUserFunctions();
    notifyListeners();
  }

  void removeUserFunction(String name) {
    if (userFunctions.remove(name) != null) {
      _persistUserFunctions();
      notifyListeners();
    }
  }

  void _persistUserFunctions() {
    _prefs?.setString(
      _kUserFunctions,
      jsonEncode(userFunctions.values.map((f) => f.toJson()).toList()),
    );
  }

  void _persistNotepadDocs() {
    _prefs?.setString(
      _kNotepadDocs,
      jsonEncode(notepadDocuments.values
          .map((d) => d.toJson())
          .toList(growable: false)),
    );
  }

  void _persistCurrentNotepadDoc() {
    final id = _currentNotepadDocId;
    if (id == null) {
      _prefs?.remove(_kCurrentNotepadDoc);
    } else {
      _prefs?.setString(_kCurrentNotepadDoc, id);
    }
  }

  /// Insert or update a notepad document. The `updatedAt` timestamp
  /// is the caller's responsibility — bump it on the doc before
  /// passing it in if you want the doc list to re-sort.
  void setNotepadDocument(NotepadDocument doc) {
    notepadDocuments[doc.id] = doc;
    _persistNotepadDocs();
    notifyListeners();
  }

  /// Remove a notepad document. If [id] was the current doc, the
  /// next one (alphabetically by id) becomes current, or `null` if
  /// none remain. Callers that want snackbar-undo (decision #18)
  /// should snapshot the doc *before* calling this.
  void deleteNotepadDocument(String id) {
    final removed = notepadDocuments.remove(id);
    if (removed == null) return;
    if (_currentNotepadDocId == id) {
      _currentNotepadDocId =
          notepadDocuments.isEmpty ? null : notepadDocuments.keys.first;
      _persistCurrentNotepadDoc();
    }
    _persistNotepadDocs();
    notifyListeners();
  }

  void setCurrentNotepadDoc(String? id) {
    if (_currentNotepadDocId == id) return;
    if (id != null && !notepadDocuments.containsKey(id)) return;
    _currentNotepadDocId = id;
    _persistCurrentNotepadDoc();
    notifyListeners();
  }

  // -- P9-A2: 3D scene mutations ------------------------------------

  /// Append [obj] to the scene, or replace the existing entry with
  /// the same id. Persists immediately.
  void addOrUpdateSceneObject(SceneObject obj) {
    _scene3D = _scene3D.withObject(obj);
    _persistScene3D();
    notifyListeners();
  }

  /// Remove the scene object with the given [id]. No-op if it
  /// doesn't exist.
  void removeSceneObject(String id) {
    final next = _scene3D.withoutObject(id);
    if (identical(next.objects, _scene3D.objects)) return;
    _scene3D = next;
    _persistScene3D();
    notifyListeners();
  }

  /// Live viewport update for rotate / zoom gestures. Persists on
  /// every commit — cheap because the JSON is small and SharedPrefs
  /// debounces under the hood.
  void updateSceneViewport({
    double? azimuth,
    double? elevation,
    double? zoom,
    double? range,
  }) {
    if (azimuth != null) _scene3D.azimuth = azimuth;
    if (elevation != null) _scene3D.elevation = elevation;
    if (zoom != null) _scene3D.zoom = zoom;
    if (range != null) _scene3D.range = range;
    _persistScene3D();
    notifyListeners();
  }

  /// Reorder the scene object list (drag-handle interactions on
  /// the Scene3D panel). Follows [ReorderableListView]'s newIndex
  /// convention; no-op on out-of-bounds indices.
  void reorderSceneObjects(int oldIndex, int newIndex) {
    final next = _scene3D.withReorderedObjects(oldIndex, newIndex);
    if (identical(next.objects, _scene3D.objects)) return;
    _scene3D = next;
    _persistScene3D();
    notifyListeners();
  }

  /// Reset the viewport to the default starting orientation.
  void resetSceneViewport() {
    _scene3D.azimuth = kDefaultSceneAzimuth;
    _scene3D.elevation = kDefaultSceneElevation;
    _scene3D.zoom = kDefaultSceneZoom;
    _persistScene3D();
    notifyListeners();
  }

  void _persistScene3D() {
    _prefs?.setString(_kScene3D, jsonEncode(_scene3D.toJson()));
  }

  // --- Volatile (now also persisted) state --------------------------------

  final List<CalculationEntry> history = [];
  final Map<String, String> userVariables = {};
  late final List<String> graphFunctions;

  /// Named user-defined functions keyed by `UserFunction.name` (always
  /// lowercase). The calculator preprocessor inlines `<name>(arg)`
  /// occurrences before sending the expression to SymEngine, with up to
  /// `_kUdfExpansionDepth` passes so `g(f(x))` composes correctly.
  final Map<String, UserFunction> userFunctions = {};

  /// Notepad / document-mode state (P5 strategic next, Phase 1).
  /// Keyed by `NotepadDocument.id`. The static Welcome sample lives
  /// under the reserved id [kWelcomeNotepadDocId] so first-launch
  /// seeding and the "Open Welcome sample" menu action never
  /// double-create it.
  final Map<String, NotepadDocument> notepadDocuments = {};

  /// Active document on the Notepad screen. Persisted so the
  /// notepad re-opens whichever doc was last viewed.
  String? _currentNotepadDocId;
  String? get currentNotepadDocId => _currentNotepadDocId;

  /// P9-A2: the (single) 3D scene the user is editing. V1 ships one
  /// global scene; multi-scene named documents are deferred to a
  /// later round. Always non-null — defaults to an empty scene that
  /// can be populated via [addOrUpdateSceneObject].
  Scene3D _scene3D = Scene3D.empty(name: 'Scene');
  Scene3D get scene3D => _scene3D;

  /// Cross-screen "insert this expression into the calculator field"
  /// signal. Set by [requestInsertExpression] (typically from a dialog
  /// in another tab); the main screen listens and switches to the
  /// Calculator tab; the calculator screen reads + clears via
  /// [consumePendingInsert] on its post-frame callback.
  String? _pendingInsertExpression;
  String? get pendingInsertExpression => _pendingInsertExpression;

  /// Asks the app to switch to the Calculator tab and pre-fill its
  /// input field with [expression]. Returns immediately; the actual
  /// navigation + insertion happen on the next listener tick.
  void requestInsertExpression(String expression) {
    _pendingInsertExpression = expression;
    notifyListeners();
  }

  /// One-shot read: returns the pending expression and clears the slot.
  /// Called by the calculator screen after it's inserted the value.
  String? consumePendingInsert() {
    final value = _pendingInsertExpression;
    if (value != null) {
      _pendingInsertExpression = null;
      // Don't notify — we're being called from a listener already.
    }
    return value;
  }

  /// Round 73: pending "open the Constraints DSL tab and load this
  /// example" signal. Mirrors [_pendingInsertExpression] but
  /// targets the Constraints screen's Free-form tab. Set by the
  /// worked-examples dialog when a `dsl:<id>` sentinel is tapped;
  /// drained by the DSL tab's initState. The value is the gallery
  /// id (e.g. `magicSquare3`) — the tab owns the id → program
  /// mapping so the rest of the app doesn't need to.
  String? _pendingDslProgramId;
  String? get pendingDslProgramId => _pendingDslProgramId;

  void requestLoadDslProgram(String id) {
    _pendingDslProgramId = id;
    notifyListeners();
  }

  String? consumePendingDslProgramId() {
    final value = _pendingDslProgramId;
    if (value != null) {
      _pendingDslProgramId = null;
    }
    return value;
  }

  /// Parameter values per graph slot. Keyed by slot index, then by
  /// parameter name. Used by the graphing screen's slider panel: any
  /// identifier in a function string that isn't `x` (or a reserved
  /// constant / function name) becomes a parameter; this map carries
  /// its current value, defaulting to 1.0 the first time it's seen.
  final Map<int, Map<String, double>> functionParameters = {};

  String formatNumber(String numberString) {
    // Big-int literal handling: `100!`'s 158-digit result, etc.
    //   - Exact integer mode ON  → preserve the full digit string.
    //   - Exact integer mode OFF → render as compact scientific
    //     notation (`9.332622e+157`). The previous fall-through
    //     to `double.tryParse` + `number.round().toString()`
    //     silently clamped huge doubles to int64 max
    //     (`9223372036854775807`), which looked correct but was
    //     completely wrong; scientific notation is the documented
    //     "off" behavior per the Settings subtitle.
    final digitCount = ExactInteger.digitCount(numberString);
    if (digitCount > 15) {
      if (_exactIntegerMode) return numberString.trim();
      final n = double.tryParse(numberString);
      return n == null ? numberString.trim() : n.toStringAsExponential(6);
    }

    final number = double.tryParse(numberString);
    if (number == null) return numberString;

    if (_decimalPlaces < 0) {
      // Auto: integer-shaped doubles stay integers; non-integer
      // values fall through to Dart's `toString`.
      return number == number.roundToDouble()
          ? number.round().toString()
          : number.toString();
    }
    final n = _decimalPlaces.clamp(0, 15);
    if (n == 0) return number.round().toString();
    return number.toStringAsFixed(n);
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

  /// Serialize every piece of user-mutable state into a single JSON
  /// document. Used by Settings → Export data so a user can copy it
  /// out (clipboard, a Notes app, a backup file) before reinstalling.
  /// The schema is intentionally simple — each top-level key is the
  /// same name we use for the matching shared_preferences entry, so a
  /// future import-from-JSON path can just round-trip these.
  /// Restores everything in [json] over the current AppState. Returns
  /// a short human-readable summary describing what was imported (used
  /// by the import dialog's toast). Throws [FormatException] on a
  /// malformed payload — caller surfaces that to the user.
  ///
  /// Missing keys are tolerated: a payload from an older export round
  /// won't crash, it just leaves the unknown fields alone. Same for a
  /// payload from a newer release with extra keys we don't yet
  /// recognize.
  String importFromJson(Map<String, dynamic> json) {
    final imported = <String>[];

    if (json['locale'] is String) {
      final code = json['locale'] as String;
      if (const {'en', 'de', 'fr', 'es'}.contains(code)) {
        setLocale(Locale(code));
        imported.add('locale');
      }
    }
    if (json['numberFormat'] is String) {
      final fmt = NumberDisplayFormat.values
          .where((v) => v.name == json['numberFormat'])
          .firstOrNull;
      if (fmt != null) {
        setNumberFormat(fmt);
        imported.add('number format');
      }
    }
    if (json['themeMode'] is String) {
      final mode = ThemeMode.values
          .where((v) => v.name == json['themeMode'])
          .firstOrNull;
      if (mode != null) {
        setThemeMode(mode);
        imported.add('theme');
      }
    }
    if (json['exactIntegerMode'] is bool) {
      setExactIntegerMode(json['exactIntegerMode'] as bool);
      imported.add('exact integer mode');
    }
    if (json['history'] is List) {
      history.clear();
      for (final raw in (json['history'] as List)) {
        if (raw is Map) {
          history
              .add(CalculationEntry.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
      _persistHistory();
      imported.add('${history.length} history entries');
    }
    if (json['variables'] is Map) {
      userVariables.clear();
      (json['variables'] as Map).forEach((k, v) {
        userVariables[k.toString()] = v.toString();
      });
      _persistVariables();
      imported.add('${userVariables.length} variables');
    }
    if (json['functions'] is List) {
      final list = json['functions'] as List;
      for (var i = 0; i < graphFunctions.length; i++) {
        graphFunctions[i] = i < list.length ? (list[i]?.toString() ?? '') : '';
      }
      _persistFunctions();
      imported.add('graph functions');
    }
    if (json['parameters'] is Map) {
      functionParameters.clear();
      (json['parameters'] as Map).forEach((k, v) {
        final slot = int.tryParse(k.toString());
        if (slot == null || v is! Map) return;
        functionParameters[slot] = {
          for (final p in v.entries)
            p.key.toString():
                (p.value is num ? (p.value as num).toDouble() : 0.0)
        };
      });
      _persistParameters();
      imported.add('parameters');
    }
    if (json['userFunctions'] is List) {
      userFunctions.clear();
      for (final raw in (json['userFunctions'] as List)) {
        if (raw is Map) {
          final f = UserFunction.fromJson(Map<String, dynamic>.from(raw));
          if (f.name.isNotEmpty) userFunctions[f.name] = f;
        }
      }
      _persistUserFunctions();
      imported.add('${userFunctions.length} user functions');
    }
    if (json['notepadDocuments'] is List) {
      // Drop user docs but keep the Welcome sample (always recreated
      // by load(); excluded from export). Import only user docs.
      notepadDocuments.removeWhere((id, _) => id != kWelcomeNotepadDocId);
      var importedCount = 0;
      for (final raw in (json['notepadDocuments'] as List)) {
        if (raw is Map) {
          final doc = NotepadDocument.fromJson(Map<String, dynamic>.from(raw));
          if (doc.id.isEmpty || doc.id == kWelcomeNotepadDocId) continue;
          notepadDocuments[doc.id] = doc;
          importedCount++;
        }
      }
      _persistNotepadDocs();
      imported.add('$importedCount notepad documents');
    }
    if (json['currentNotepadDocId'] is String) {
      final id = json['currentNotepadDocId'] as String;
      if (notepadDocuments.containsKey(id)) {
        _currentNotepadDocId = id;
        _persistCurrentNotepadDoc();
      }
    }
    if (json['scene3D'] is Map) {
      try {
        _scene3D =
            Scene3D.fromJson(Map<String, dynamic>.from(json['scene3D'] as Map));
        _persistScene3D();
        imported.add('3D scene');
      } catch (_) {
        // Tolerated — older exports won't have this key, malformed
        // payloads just keep the existing scene.
      }
    }

    notifyListeners();
    return imported.isEmpty
        ? 'Nothing recognized in payload'
        : imported.join(', ');
  }

  Map<String, dynamic> exportToJson() {
    return {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'locale': _locale.languageCode,
      'numberFormat': _numberFormat.name,
      'themeMode': _themeMode.name,
      'exactIntegerMode': _exactIntegerMode,
      'userFunctions':
          userFunctions.values.map((f) => f.toJson()).toList(growable: false),
      'history': history.map((e) => e.toJson()).toList(),
      'variables': Map<String, String>.from(userVariables),
      'functions': List<String>.from(graphFunctions),
      'parameters': functionParameters
          .map((slot, params) => MapEntry(slot.toString(), params)),
      // Notepad docs (excluding the always-recreated Welcome sample
      // — it's reseeded on import / reinstall from the static
      // constant in lib/engine/notepad.dart so its body stays in
      // sync with the release).
      'notepadDocuments': notepadDocuments.values
          .where((d) => d.id != kWelcomeNotepadDocId)
          .map((d) => d.toJson())
          .toList(growable: false),
      'currentNotepadDocId': _currentNotepadDocId,
      'scene3D': _scene3D.toJson(),
    };
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
