// Coverage for the Australia map-coloring visualization that the DSL
// result panel shows for the `mapColoringAustralia` gallery program.

import 'package:crisp_calc/widgets/australia_map_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AustraliaMapView.matches', () {
    test('accepts exactly the seven region keys', () {
      expect(
        AustraliaMapView.matches(
            {'wa': 1, 'nt': 2, 'sa': 3, 'q': 1, 'nsw': 2, 'v': 1, 't': 1}),
        isTrue,
      );
    });

    test('rejects a subset of the region keys', () {
      expect(
        AustraliaMapView.matches({'wa': 1, 'nt': 2, 'sa': 3}),
        isFalse,
      );
    });

    test('rejects a same-size assignment over different names', () {
      expect(
        AustraliaMapView.matches({
          'a': 1,
          'b': 2,
          'c': 3,
          'd': 1,
          'e': 2,
          'f': 1,
          'g': 1,
        }),
        isFalse,
      );
    });

    test('rejects a superset (extra variable)', () {
      expect(
        AustraliaMapView.matches({
          'wa': 1,
          'nt': 2,
          'sa': 3,
          'q': 1,
          'nsw': 2,
          'v': 1,
          't': 1,
          'extra': 1,
        }),
        isFalse,
      );
    });
  });

  testWidgets('renders without error for a valid 3-coloring', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AustraliaMapView(
            assignment: {
              'wa': 1,
              'nt': 2,
              'sa': 3,
              'q': 1,
              'nsw': 2,
              'v': 1,
              't': 1,
            },
          ),
        ),
      ),
    );
    expect(find.byType(AustraliaMapView), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
