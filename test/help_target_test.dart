// Round 101 (P6): HelpTarget renders a dotted-outline overlay when
// AppState.helpMode is true. When off it returns the child unwrapped.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/widgets/help_target.dart';

void main() {
  setUp(() => AppState().setHelpMode(false));

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  // CustomPaint appears throughout the Material framework, so scope
  // the finder to descendants of HelpTarget itself.
  Finder paintInside() => find.descendant(
        of: find.byType(HelpTarget),
        matching: find.byType(CustomPaint),
      );

  // Likewise for Padding — HelpTarget only wraps with one when on.
  Finder paddingInside() => find.descendant(
        of: find.byType(HelpTarget),
        matching: find.byType(Padding),
      );

  testWidgets('returns child unwrapped when helpMode is off', (tester) async {
    await tester.pumpWidget(host(
      const HelpTarget(child: SizedBox(width: 40, height: 20, key: Key('c'))),
    ));
    expect(paintInside(), findsNothing);
    expect(paddingInside(), findsNothing);
    expect(find.byKey(const Key('c')), findsOneWidget);
  });

  testWidgets('paints an outline when helpMode flips on', (tester) async {
    await tester.pumpWidget(host(
      const HelpTarget(child: SizedBox(width: 40, height: 20, key: Key('c'))),
    ));
    expect(paintInside(), findsNothing);

    AppState().setHelpMode(true);
    await tester.pump();

    expect(paintInside(), findsOneWidget);
    expect(paddingInside(), findsOneWidget);
    expect(find.byKey(const Key('c')), findsOneWidget);
  });

  testWidgets('rebuilds when toggled back off', (tester) async {
    AppState().setHelpMode(true);
    await tester.pumpWidget(host(
      const HelpTarget(child: SizedBox(width: 40, height: 20, key: Key('c'))),
    ));
    expect(paintInside(), findsOneWidget);

    AppState().setHelpMode(false);
    await tester.pump();

    expect(paintInside(), findsNothing);
  });
}
