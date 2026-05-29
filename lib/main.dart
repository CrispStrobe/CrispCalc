// lib/main.dart
//
// App entry + adaptive shell. Loads persisted settings (locale, number
// format) before runApp, then watches AppState so a language change in
// Settings takes effect immediately.
//
// Layout:
//   < 720 px  : bottom navigation bar
//   >= 720 px : NavigationRail (extended above 1100 px)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Headless diagnostic self-test. Native (dart:io) impl on desktop/mobile;
// no-op stub on web (no dart:io). Keeps main.dart web-compilable.
import 'diagnostics_runner_stub.dart'
    if (dart.library.io) 'diagnostics_runner_io.dart';
import 'engine/app_state.dart';
import 'engine/calculator_engine.dart';
import 'engine/matrix_diagnostics.dart';
import 'localization/app_localizations.dart';
import 'screens/about_screen.dart';
import 'screens/analysis_hub_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/function_editor_screen.dart';
import 'screens/graphing_screen.dart';
import 'screens/help_screen.dart';
import 'screens/notepad_screen.dart';
import 'services/native_licenses.dart';
import 'widgets/export_data_dialog.dart';
import 'widgets/import_data_dialog.dart';
import 'widgets/onboarding_tour.dart';
import 'widgets/user_functions_dialog.dart';
import 'widgets/function_reference_dialog.dart';
import 'widgets/worked_examples_dialog.dart';
import 'widgets/web_unsupported_banner.dart';

/// Round 71: a single app-wide [RouteObserver] so screens / dialogs
/// pushed onto the root navigator can subscribe via [RouteAware] and
/// react when the user navigates back. The calculator uses this to
/// reclaim hardware-keyboard focus on every `didPopNext` — without
/// it, dismissing a dialog (Unit Converter, Constants, etc.) or
/// returning from a module screen (Sudoku, Constraints, …) leaves
/// focus stranded on whichever widget the dialog/screen last held,
/// and the user can't type into the calculator until they click a
/// keypad button or hit the "reset focus" recovery action.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Silence the "A KeyDownEvent is dispatched, but the state shows that
  // the physical key is already pressed" assertion. It fires inside
  // HardwareKeyboard.handleKeyEvent BEFORE event dispatch in debug mode,
  // which means key events get DROPPED whenever the framework's
  // _pressedKeys map has stale entries — typically after hot reload, a
  // brief volume disconnect, or an abrupt app kill while a key was held.
  // In release mode the assert is removed and the framework just runs
  // through. We delegate to the default reporter for every other error.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('physical key is already pressed') ||
        msg.contains('physical key is not pressed')) {
      return; // swallow
    }
    previousOnError?.call(details);
  };

  await AppState().load();
  // Register native (SymEngine / GMP / MPFR / MPC / FLINT) license texts so
  // they appear in `showLicensePage` alongside the pub deps.
  await registerNativeLicenses();

  // Headless self-test for CI / manual verification. Invoke with the
  // `CRISPCALC_DIAGNOSTIC=matrix|steps` environment variable set (desktop
  // only). Runs the matrix / step battery against the native bridge,
  // prints PASS/FAIL lines, and exits non-zero on any failure. On web this
  // is a no-op (the conditional import resolves to the stub).
  runDiagnosticsIfRequested();

  runApp(const CrispCalcApp());
}

class CrispCalcApp extends StatelessWidget {
  const CrispCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'CrispCalc - CAS Calculator',
          debugShowCheckedModeBanner: false,
          locale: appState.locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('de', ''),
            Locale('fr', ''),
            Locale('es', ''),
          ],
          themeMode: appState.themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          navigatorObservers: [appRouteObserver],
          home: const MainScreen(),
        );
      },
    );
  }
}

ThemeData _buildDarkTheme() {
  return ThemeData.dark().copyWith(
    primaryColor: Colors.blueAccent,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF222222),
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: Colors.blueAccent,
      secondary: Colors.cyanAccent,
    ),
  );
}

ThemeData _buildLightTheme() {
  return ThemeData.light().copyWith(
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE8EAED),
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.light().copyWith(
      primary: Colors.blue,
      secondary: Colors.cyan,
    ),
  );
}

const double _railBreakpoint = 720;
const double _extendedRailBreakpoint = 1100;

// Index constants for the tab order in [_screens] / [_destinations].
// Only a subset is referenced by name today (the cross-tab nav callbacks);
// the rest are kept as documentation so the next person inserting a tab
// can renumber without spelunking through the IndexedStack indices.
const int _kCalculator = 0;
// ignore: unused_element
const int _kNotepad = 1;
const int _kGraphing = 2;
// ignore: unused_element
const int _kFunctionEditor = 3;
const int _kAnalysis = 4;
// ignore: unused_element
const int _kSettings = 5;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = _kCalculator;

  final GlobalKey<CalculatorScreenState> _calculatorKey = GlobalKey();
  final GlobalKey<GraphingScreenState> _graphingKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CalculatorScreen(
        key: _calculatorKey,
        onGoToGraphing: () => _select(_kGraphing),
        onGoToAnalysis: () => _select(_kAnalysis),
      ),
      const NotepadScreen(),
      GraphingScreen(key: _graphingKey),
      FunctionEditorScreen(
        onSwitchToGraphing: (_) => _select(_kGraphing),
      ),
      const AnalysisHubScreen(),
      const SettingsScreen(),
    ];
    // First-launch onboarding tour. Skipped if the user has already
    // dismissed it (persisted) or — pragmatically — when running
    // headless / under widget tests where no MaterialApp ancestor is
    // mounted in the right way to host a Dialog. The setOnboarding flag
    // toggle in OnboardingTour.show prevents re-showing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AppState().onboardingDismissed) {
        OnboardingTour.show(context);
      }
      // Calculator's own initState postFrame already requests focus,
      // but it can lose the focus race when the IndexedStack mounts
      // sibling screens (Notepad, Graphing, etc.) and their
      // TextEditingControllers/FocusNodes get instantiated. Belt-and-
      // suspender re-request here ensures the calculator captures
      // hardware-keyboard focus on cold launch without the user
      // having to tap the "reset focus" recovery action.
      if (_selectedIndex == _kCalculator) {
        _calculatorKey.currentState?.requestFocus();
      }
    });
    // Worked-examples V2: when a dialog signals "insert this into the
    // calculator", switch to the Calculator tab. The CalculatorScreen
    // itself consumes the pending expression and inserts it.
    AppState().addListener(_maybeRouteToCalculator);
  }

  @override
  void dispose() {
    AppState().removeListener(_maybeRouteToCalculator);
    super.dispose();
  }

  void _maybeRouteToCalculator() {
    if (!mounted) return;
    if (AppState().pendingInsertExpression != null &&
        _selectedIndex != _kCalculator) {
      _select(_kCalculator);
    }
  }

  void _select(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (i == _kCalculator) {
        _calculatorKey.currentState?.requestFocus();
      } else if (i == _kGraphing) {
        _graphingKey.currentState?.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= _railBreakpoint) {
          return _buildRailLayout(t,
              extended: width >= _extendedRailBreakpoint);
        }
        return _buildBottomNavLayout(t);
      },
    );
  }

  List<({IconData icon, String label})> _destinations(AppLocalizations t) {
    return [
      (icon: Icons.calculate, label: t.navCalculator),
      (icon: Icons.notes, label: t.navNotepad),
      (icon: Icons.show_chart, label: t.navGraphing),
      (icon: Icons.functions, label: t.navFunctions),
      (icon: Icons.donut_large, label: t.navAnalysis),
      (icon: Icons.settings, label: t.navSettings),
    ];
  }

  /// Wraps a shell body with the web-only "CAS unavailable" banner above
  /// it. Off-web the banner renders nothing, so this is a transparent
  /// pass-through on native.
  Widget _withWebBanner(Widget body) => Column(
        children: [
          const WebUnsupportedBanner(),
          Expanded(child: body),
        ],
      );

  Widget _buildBottomNavLayout(AppLocalizations t) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: _withWebBanner(
          IndexedStack(index: _selectedIndex, children: _screens)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: 0.6),
        currentIndex: _selectedIndex,
        onTap: _select,
        items: _destinations(t)
            .map((d) => BottomNavigationBarItem(
                  icon: Icon(d.icon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildRailLayout(AppLocalizations t, {required bool extended}) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: _withWebBanner(Row(
        children: [
          NavigationRail(
            backgroundColor: cs.surface,
            extended: extended,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _select,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: _destinations(t)
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      )),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.settingsLanguage,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      RadioGroup<String>(
                        groupValue: appState.locale.languageCode,
                        onChanged: (v) {
                          if (v != null) appState.setLocale(Locale(v));
                        },
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: Text(t.settingsLanguageEnglish),
                              value: 'en',
                            ),
                            RadioListTile<String>(
                              title: Text(t.settingsLanguageGerman),
                              value: 'de',
                            ),
                            RadioListTile<String>(
                              title: Text(t.settingsLanguageFrench),
                              value: 'fr',
                            ),
                            RadioListTile<String>(
                              title: Text(t.settingsLanguageSpanish),
                              value: 'es',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.settingsNumberFormat,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.settingsNumberFormatAuto),
                        value: appState.decimalPlaces < 0,
                        onChanged: (auto) {
                          appState.setDecimalPlaces(auto ? -1 : 2);
                        },
                      ),
                      if (appState.decimalPlaces >= 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.settingsNumberFormatDecimalPlaces(
                                    appState.decimalPlaces),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: appState.decimalPlaces.toDouble(),
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: appState.decimalPlaces.toString(),
                          onChanged: (v) =>
                              appState.setDecimalPlaces(v.round()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.settingsTheme,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      RadioGroup<ThemeMode>(
                        groupValue: appState.themeMode,
                        onChanged: (v) {
                          if (v != null) appState.setThemeMode(v);
                        },
                        child: Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              title: Text(t.settingsThemeSystem),
                              value: ThemeMode.system,
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text(t.settingsThemeLight),
                              value: ThemeMode.light,
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text(t.settingsThemeDark),
                              value: ThemeMode.dark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.pin_outlined),
                  title: Text(t.settingsExactIntegerMode),
                  subtitle: Text(t.settingsExactIntegerModeSubtitle),
                  value: appState.exactIntegerMode,
                  onChanged: appState.setExactIntegerMode,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.link),
                  title: Text(t.settingsAutoBindSolve),
                  subtitle: Text(t.settingsAutoBindSolveSubtitle),
                  value: appState.autoBindSolve,
                  onChanged: appState.setAutoBindSolve,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(t.settingsReplayTour),
                  subtitle: Text(t.settingsReplayTourSubtitle),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => OnboardingTour.show(context),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.settingsLayoutTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(t.settingsLayoutBody),
                    ],
                  ),
                ),
              ),
              // Round 71: Unit Converter + Constants live in the
              // Analysis hub only — duplicated entry-points here
              // made Settings noisy and confused new users about
              // which surface owned what.
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.functions),
                  title: Text(t.settingsUserFunctions),
                  subtitle: Text(t.settingsUserFunctionsSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => const UserFunctionsDialog(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(t.settingsWorkedExamples),
                  subtitle: Text(t.settingsWorkedExamplesSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => const WorkedExamplesDialog(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Round 96 (P6): Function Reference dialog. Lives in
              // Settings for V1; Round 101's help-mode toggle will
              // surface it inline from Calculator / Notepad.
              Card(
                child: ListTile(
                  leading: const Icon(Icons.functions),
                  title: Text(t.settingsFunctionRef),
                  subtitle: Text(t.settingsFunctionRefSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => const FunctionReferenceDialog(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(t.settingsHelp),
                  subtitle: Text(t.settingsHelpSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HelpScreen(),
                    ));
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: Text(t.settingsExportData),
                  subtitle: Text(t.settingsExportDataSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => const ExportDataDialog(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: Text(t.settingsImportData),
                  subtitle: Text(t.settingsImportDataSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => const ImportDataDialog(),
                  ),
                ),
              ),
              // Round 91 follow-up: matrix self-test is a developer
              // diagnostic — it runs the SymbolicMathBridge calls and
              // prints a pass/fail report. End users will never need
              // it, and a release-build user who taps it sees raw
              // bridge output. Gate behind kDebugMode so it ships only
              // to dev builds. CI / scripted runs still reach it via
              // the CRISPCALC_DIAGNOSTIC=matrix env-var at startup
              // (see main.dart:73-79).
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(t.matrixDiagnosticsTitle),
                    subtitle: Text(t.matrixDiagnosticsSubtitle),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () => _showMatrixDiagnostics(context, t),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(t.settingsAbout),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AboutScreen(),
                    ));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showMatrixDiagnostics(
      BuildContext context, AppLocalizations t) async {
    final engine = CalculatorEngine();
    final results = MatrixDiagnostics.run(engine);
    final passed = results.where((r) => r.passed).length;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.matrixDiagnosticsTitle),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.matrixDiagnosticsSummary(passed, results.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                for (final r in results) ...[
                  Row(
                    children: [
                      Icon(
                        r.passed ? Icons.check_circle : Icons.cancel,
                        color: r.passed
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 26, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('expr: ${r.expression}',
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12)),
                        Text('expected: ${r.expected}',
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Colors.grey[400])),
                        Text('actual:   ${r.actual}',
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: r.passed
                                    ? Colors.grey[400]
                                    : Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
        ],
      ),
    );
  }
}
