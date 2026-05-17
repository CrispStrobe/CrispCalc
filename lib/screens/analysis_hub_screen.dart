// lib/screens/analysis_hub_screen.dart
// A menu for selecting different advanced analysis modules.

import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../widgets/unit_converter_dialog.dart';
import 'conic_section_screen.dart';
import 'curve_analysis_input_screen.dart';
import 'graphing_3d_screen.dart';
import 'plane_analysis_screen.dart';
import 'statistics_screen.dart';

class AnalysisHubScreen extends StatelessWidget {
  const AnalysisHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.analysisModulesTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          _ModuleCard(
            icon: Icons.show_chart,
            title: t.moduleCurveSketching,
            subtitle: t.moduleCurveSketchingSubtitle,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CurveAnalysisInputScreen(),
              ));
            },
          ),
          _ModuleCard(
            icon: Icons.view_in_ar,
            title: t.modulePlanes,
            subtitle: t.modulePlanesSubtitle,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const PlaneAnalysisScreen(),
              ));
            },
          ),
          _ModuleCard(
            icon: Icons.circle_outlined,
            title: t.moduleConics,
            subtitle: t.moduleConicsSubtitle,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ConicSectionScreen(),
              ));
            },
          ),
          _ModuleCard(
            icon: Icons.bar_chart,
            title: t.moduleStatistics,
            subtitle: t.moduleStatisticsSubtitle,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const StatisticsScreen(),
              ));
            },
          ),
          _ModuleCard(
            icon: Icons.threed_rotation,
            title: t.module3DTitle,
            subtitle: t.module3DSubtitle,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const Graphing3DScreen(),
              ));
            },
          ),
          _ModuleCard(
            icon: Icons.swap_horiz,
            title: t.moduleUnitConverterTitle,
            subtitle: t.moduleUnitConverterSubtitle,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const UnitConverterDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}

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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        leading: Icon(icon, size: 40, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
