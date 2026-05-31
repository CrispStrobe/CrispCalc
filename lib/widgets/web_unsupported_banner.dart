// lib/widgets/web_unsupported_banner.dart
//
// Web build status banner. The browser loads SymEngine as a WASM module
// asynchronously (see web/index.html), so this banner tracks the bridge
// lifecycle via [nativeBridgeStatus]:
//
//   - loading     → "loading the in-browser engine…" (transient, ~1s)
//   - ready       → full CAS works in the browser; only the GMP/MPFR/FLINT-
//                   only functions (isprime, factorint, evalf, Bessel) still
//                   need the native app.
//   - unavailable → WASM never loaded; symbolic features need the app.
//
// Renders nothing off-web, so it can be dropped into the shell
// unconditionally.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../engine/calculator_engine.dart';
import '../localization/app_localizations.dart';

class WebUnsupportedBanner extends StatelessWidget {
  const WebUnsupportedBanner({super.key});

  static final Uri _releases =
      Uri.parse('https://github.com/CrispStrobe/CrispCalc/releases');

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return ValueListenableBuilder<NativeBridgeStatus>(
      valueListenable: nativeBridgeStatus,
      builder: (context, status, _) {
        final t = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;

        final (String message, IconData icon, bool showDownload) =
            switch (status) {
          NativeBridgeStatus.loading => (
              t.webBannerCasLoading,
              Icons.hourglass_top,
              false,
            ),
          NativeBridgeStatus.ready => (
              t.webBannerCasPartial,
              Icons.check_circle_outline,
              true,
            ),
          NativeBridgeStatus.unavailable => (
              t.webBannerCasUnavailable,
              Icons.info_outline,
              true,
            ),
        };

        return Material(
          color: scheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: scheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                        color: scheme.onSecondaryContainer, fontSize: 12),
                  ),
                ),
                if (showDownload) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => launchUrl(_releases,
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.download, size: 16),
                    label: Text(t.webDownloadApp),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
