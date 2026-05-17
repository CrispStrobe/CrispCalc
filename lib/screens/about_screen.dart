// lib/screens/about_screen.dart
//
// About / legal info for CrispCalc. Layout mirrors the sibling CrisperWeaver
// app so the two are visually consistent: app header card, then sections for
// service provider, contact, privacy, disclaimer, license. The bottom button
// opens Flutter's `showLicensePage`, which lists every pub dep plus the
// native SymEngine stack (registered via `registerNativeLicenses` in main).

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _email = 'postmaster@crispstro.be';
  static const _appName = 'CrispCalc';
  static const _providerJoin =
      'Christian Ströbele\nNikolausstr. 5\n70190 Stuttgart\nDeutschland / Germany';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _AppHeader(),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.business,
            label: l.aboutServiceProvider,
            child: const Text(_providerJoin),
          ),
          _SectionCard(
            icon: Icons.alternate_email,
            label: l.aboutContact,
            child: InkWell(
              onTap: () => _open('mailto:$_email'),
              child: Text(
                _email,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          _SectionCard(
            icon: Icons.privacy_tip_outlined,
            label: l.aboutPrivacy,
            child: Text(l.aboutPrivacyText),
          ),
          _SectionCard(
            icon: Icons.gavel,
            label: l.aboutDisclaimer,
            child: Text(l.aboutDisclaimerText),
          ),
          _SectionCard(
            icon: Icons.copyright,
            label: l.aboutLicense,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.aboutLicenseText),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () =>
                      _open('https://www.gnu.org/licenses/agpl-3.0.html'),
                  child: const Text(
                    'https://www.gnu.org/licenses/agpl-3.0.html',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: Text(l.aboutOpenSourceLicenses),
            onPressed: () async {
              final info = await PackageInfo.fromPlatform();
              if (!context.mounted) return;
              showLicensePage(
                context: context,
                applicationName: _appName,
                applicationVersion: '${info.version}+${info.buildNumber}',
                applicationLegalese:
                    '© ${DateTime.now().year} Christian Ströbele — AGPL-3.0',
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final v = snap.hasData
            ? '${snap.data!.version} (${snap.data!.buildNumber})'
            : '…';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calculate,
                    size: 28,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AboutScreen._appName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.aboutVersion(v),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.aboutTagline,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
