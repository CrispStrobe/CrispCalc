/// lib/screens/analysis_hub_screen.dart
/// A menu for selecting different advanced analysis modules.

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'curve_analysis_input_screen.dart';

class AnalysisHubScreen extends StatelessWidget {
  const AnalysisHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Modules'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          _ModuleCard(
            icon: MdiIcons.chartLineVariant,
            title: 'Kurvendiskussion',
            subtitle: 'Full analysis of a function f(x)',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CurveAnalysisInputScreen(),
              ));
            },
          ),
          _ModuleCard(
            icon: MdiIcons.cubeOutline,
            title: 'Ebenen (Planes)',
            subtitle: '3D analytical geometry for planes',
            onTap: () {
              // In a future step, this would navigate to a plane geometry screen.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plane geometry module coming soon!')),
              );
            },
          ),
          _ModuleCard(
            icon: MdiIcons.ellipseOutline,
            title: 'Kegelschnitte (Conic Sections)',
            subtitle: 'Analyze circles, ellipses, parabolas, etc.',
            onTap: () {
              // In a future step, this would navigate to a conic sections screen.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conic sections module coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A reusable card widget for displaying a module in the hub.
class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        leading: Icon(icon, size: 40, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}