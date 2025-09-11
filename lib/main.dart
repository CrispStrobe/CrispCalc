/// lib/main.dart 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'screens/calculator_screen.dart';
import 'screens/graphing_screen.dart';
import 'screens/function_editor_screen.dart';
import 'screens/analysis_hub_screen.dart';
import 'engine/app_state.dart';
import 'localization/app_localizations.dart';

void main() {
  runApp(const CrispCalcApp());
}

class CrispCalcApp extends StatelessWidget {
  const CrispCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrispCalc - CAS Calculator',
      debugShowCheckedModeBanner: false,

      // --- Setup for i18n ---
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('de', ''), // German
      ],

      theme: ThemeData.dark().copyWith(
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
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  final GlobalKey<CalculatorScreenState> _calculatorScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      CalculatorScreen(key: _calculatorScreenKey),
      const GraphingScreen(),
      const FunctionEditorScreen(),
      const AnalysisHubScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      // When switching back to the calculator, ensure its input field is focused.
      if (index == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculatorScreenKey.currentState?.requestFocus();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints(minWidth: 400, minHeight: 600),
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF222222),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Calculator'),
          BottomNavigationBarItem(icon: Icon(MdiIcons.chartLine), label: 'Graphing'),
          BottomNavigationBarItem(icon: Icon(MdiIcons.functionVariant), label: 'Functions'),
          BottomNavigationBarItem(icon: Icon(MdiIcons.chartDonut), label: 'Analysis'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState appState = AppState();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
                      Text('Number Display Format', 
                        style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      
                      RadioListTile<NumberDisplayFormat>(
                        title: const Text('Auto (129, 129.5)'),
                        value: NumberDisplayFormat.auto,
                        groupValue: appState.numberFormat,
                        onChanged: (value) => appState.setNumberFormat(value!),
                      ),
                      RadioListTile<NumberDisplayFormat>(
                        title: const Text('Integer (129)'),
                        value: NumberDisplayFormat.integer,
                        groupValue: appState.numberFormat,
                        onChanged: (value) => appState.setNumberFormat(value!),
                      ),
                      RadioListTile<NumberDisplayFormat>(
                        title: const Text('One Decimal (129.0)'),
                        value: NumberDisplayFormat.oneDecimal,
                        groupValue: appState.numberFormat,
                        onChanged: (value) => appState.setNumberFormat(value!),
                      ),
                      RadioListTile<NumberDisplayFormat>(
                        title: const Text('Two Decimals (129.00)'),
                        value: NumberDisplayFormat.twoDecimal,
                        groupValue: appState.numberFormat,
                        onChanged: (value) => appState.setNumberFormat(value!),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}