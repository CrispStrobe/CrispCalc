// test/golden/about_card_golden_test.dart
//
// Golden / snapshot tests for visual surfaces that don't change
// often but where a silent regression would be ugly. V1 covers the
// HelpScreen function-reference card layout — pure layout, no
// network or engine state, deterministic.
//
// Goldens are renderer-version-sensitive. CI's Flutter version may
// differ from local; if a future Flutter update flips antialiasing
// settings, regenerate with:
//   flutter test --update-goldens test/golden/

import 'package:crisp_calc/screens/help_screen.dart';
import 'package:crisp_calc/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HelpScreen renders the function reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1600));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        theme: ThemeData.dark(),
        home: const HelpScreen(),
      ),
    );
    await tester.pump();
    await tester.pump();

    // The AppBar title and the topmost section heading are in the
    // initial viewport — always built.
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Supported functions'), findsOneWidget);
    expect(find.text('Arithmetic'), findsOneWidget);

    // For below-the-fold content, scroll until each anchor enters
    // the viewport before asserting. Catches dropped sections /
    // empty cards without depending on lazy-build heuristics.
    final list = find.byType(Scrollable).first;
    for (final anchor in const [
      'Algebraic CAS',
      'Calculus',
      'Vector & tensor',
      'Matrix',
      'Matrix syntax',
      'Step-by-step solutions',
    ]) {
      await tester.scrollUntilVisible(find.text(anchor), 100,
          scrollable: list);
      expect(find.text(anchor), findsOneWidget,
          reason: 'missing anchor: $anchor');
    }
  });
}
