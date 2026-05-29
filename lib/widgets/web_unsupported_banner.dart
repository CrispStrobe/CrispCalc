// lib/widgets/web_unsupported_banner.dart
//
// Path A web build: the browser has no native CAS / MPFR / FLINT bridge,
// so symbolic, high-precision and number-theory features degrade to an
// error. This banner sets expectations up front — what works in the
// browser, what needs the desktop/mobile app — and links to the
// downloadable releases. Renders nothing off-web, so it can be dropped
// into the shell unconditionally.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_localizations.dart';

class WebUnsupportedBanner extends StatelessWidget {
  const WebUnsupportedBanner({super.key});

  static final Uri _releases =
      Uri.parse('https://github.com/CrispStrobe/CrispCalc/releases');

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 18, color: scheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.webBannerCasUnavailable,
                style:
                    TextStyle(color: scheme.onSecondaryContainer, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () =>
                  launchUrl(_releases, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.download, size: 16),
              label: Text(t.webDownloadApp),
            ),
          ],
        ),
      ),
    );
  }
}
