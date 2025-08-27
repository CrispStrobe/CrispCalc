/// lib/main.dart:

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'screens/calculator_screen.dart';
import 'screens/graphing_screen.dart';

void main() {
  runApp(const CrispCalcApp());
}

/// The root widget of the CrispCalc application.
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

/// The main screen widget with keyboard support and proper desktop sizing.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      CalculatorScreen(onKeyEvent: _handleKeyEvent),
      const GraphingScreen(),
      const PlaceholderScreen(title: 'Functions Library'),
      const PlaceholderScreen(title: 'Settings'),
    ];
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && _selectedIndex == 0) {
      // Forward keyboard events to calculator
      final calculatorScreen = _screens[0] as CalculatorScreen;
      return calculatorScreen.handleKeyboardInput(event);
    }
    return false;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 400,
            minHeight: 600,
          ),
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF222222),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.chartLine),
            label: 'Graphing',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.functionVariant),
            label: 'Functions',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// A generic placeholder screen for features that are not yet implemented.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              '$title\n(Coming Soon!)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}