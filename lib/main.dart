/// lib/main.dart:

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'screens/calculator_screen.dart';
import 'screens/graphing_screen.dart';

void main() {
  runApp(const CrispCalcApp());
}

/// The root widget of the CrispCalc application.
/// It sets up the MaterialApp, defines the theme, and specifies the home screen.
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

/// The main screen widget that contains the BottomNavigationBar for top-level navigation.
/// It manages the state for the currently selected screen.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of the main screens in the app.
  static const List<Widget> _screens = <Widget>[
    CalculatorScreen(),
    GraphingScreen(),
    PlaceholderScreen(title: 'Functions Library'),
    PlaceholderScreen(title: 'Settings'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of each screen when switching tabs.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
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
            const Icon(Icons.construction, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$title\n(Coming Soon!)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}