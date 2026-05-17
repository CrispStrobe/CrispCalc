// Smoke test: the app boots without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:crisp_calc/main.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const CrispCalcApp());
    await tester.pump();
    expect(find.byType(CrispCalcApp), findsOneWidget);
  });
}
