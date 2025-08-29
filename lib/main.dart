/// lib/main.dart - REMOVE DUPLICATE KEYBOARD HANDLING

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'screens/calculator_screen.dart';
import 'screens/graphing_screen.dart';
import 'screens/function_editor_screen.dart';

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
      const PlaceholderScreen(title: 'Settings'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text('$title\n(Coming Soon!)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}