// lib/main.dart
//
// App entry + adaptive shell. Loads persisted settings (locale, number
// format) before runApp, then watches AppState so a language change in
// Settings takes effect immediately.
//
// Layout:
//   < 720 px  : bottom navigation bar
//   >= 720 px : NavigationRail (extended above 1100 px)

import 'dart:io' show Platform, exit, stdout;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'engine/app_state.dart';
import 'engine/calculator_engine.dart';
import 'engine/matrix_diagnostics.dart';
import 'engine/step_diagnostics.dart';
import 'localization/app_localizations.dart';
import 'screens/about_screen.dart';
import 'screens/analysis_hub_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/function_editor_screen.dart';
import 'screens/graphing_screen.dart';
import 'screens/help_screen.dart';
import 'services/native_licenses.dart';
import 'widgets/export_data_dialog.dart';
import 'widgets/unit_converter_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().load();
  // Register native (SymEngine / GMP / MPFR / MPC / FLINT) license texts so
  // they appear in `showLicensePage` alongside the pub deps.
  await registerNativeLicenses();

  // Headless self-test for CI / manual verification. Invoke with the
  // `CRISPCALC_DIAGNOSTIC=matrix` environment variable set (desktop only —
  // `Platform.executableArguments` is Dart-VM args, not user argv, so an
  // env var is the cleanest hook from a launched binary). Runs the matrix
  // battery against the native bridge, prints PASS/FAIL lines to stdout,
  // exits non-zero on any failure.
  final diag = Platform.environment['CRISPCALC_DIAGNOSTIC'];
  if (!kIsWebShim &&
      (Platform.isMacOS || Platform.isLinux || Platform.isWindows) &&
      diag != null) {
    if (diag == 'matrix') {
      final results = MatrixDiagnostics.run(CalculatorEngine());
      var anyFailed = false;
      for (final r in results) {
        stdout.writeln('${r.passed ? "PASS" : "FAIL"}  ${r.name}');
        stdout.writeln('  expr:     ${r.expression}');
        stdout.writeln('  expected: ${r.expected}');
        stdout.writeln('  actual:   ${r.actual}');
        if (!r.passed) anyFailed = true;
      }
      final passed = results.where((r) => r.passed).length;
      stdout.writeln('---');
      stdout.writeln('$passed of ${results.length} checks passed');
      exit(anyFailed ? 1 : 0);
    }
    if (diag == 'steps') {
      final results = StepDiagnostics.run(CalculatorEngine());
      var anyFailed = false;
      for (final r in results) {
        stdout.writeln(
            '${r.passed ? "PASS" : "FAIL"}  [${r.operation}]  ${r.name}');
        stdout.writeln('  expr:     ${r.expression}');
        stdout.writeln('  expected: ${r.expected}');
        stdout.writeln('  actual:   ${r.actual}');
        if (!r.passed) anyFailed = true;
      }
      final passed = results.where((r) => r.passed).length;
      stdout.writeln('---');
      stdout.writeln('$passed of ${results.length} checks passed');
      exit(anyFailed ? 1 : 0);
    }
  }

  runApp(const CrispCalcApp());
}

// Tiny shim so the desktop-only platform check above also works at
// analyze time on web builds (which can't import dart:io).
const bool kIsWebShim = bool.fromEnvironment('dart.library.html');

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

const int _kCalculator = 0;
const int _kGraphing = 1;

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
      CalculatorScreen(key: _calculatorKey),
      GraphingScreen(key: _graphingKey),
      const FunctionEditorScreen(),
      const AnalysisHubScreen(),
      const SettingsScreen(),
    ];
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
      (icon: Icons.show_chart, label: t.navGraphing),
      (icon: Icons.functions, label: t.navFunctions),
      (icon: Icons.donut_large, label: t.navAnalysis),
      (icon: Icons.settings, label: t.navSettings),
    ];
  }

  Widget _buildBottomNavLayout(AppLocalizations t) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
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
      body: Row(
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
      ),
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
                      const SizedBox(height: 8),
                      RadioGroup<NumberDisplayFormat>(
                        groupValue: appState.numberFormat,
                        onChanged: (v) {
                          if (v != null) appState.setNumberFormat(v);
                        },
                        child: Column(
                          children: [
                            RadioListTile<NumberDisplayFormat>(
                              title: Text(t.settingsNumberFormatAuto),
                              value: NumberDisplayFormat.auto,
                            ),
                            RadioListTile<NumberDisplayFormat>(
                              title: Text(t.settingsNumberFormatInteger),
                              value: NumberDisplayFormat.integer,
                            ),
                            RadioListTile<NumberDisplayFormat>(
                              title: Text(t.settingsNumberFormatOneDecimal),
                              value: NumberDisplayFormat.oneDecimal,
                            ),
                            RadioListTile<NumberDisplayFormat>(
                              title: Text(t.settingsNumberFormatTwoDecimal),
                              value: NumberDisplayFormat.twoDecimal,
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
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.straighten),
                  title: Text(t.unitConverterTitle),
                  subtitle: Text(t.unitConverterSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => const UnitConverterDialog(),
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
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(t.matrixDiagnosticsTitle),
                  subtitle: Text(t.matrixDiagnosticsSubtitle),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => _showMatrixDiagnostics(context, t),
                ),
              ),
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
