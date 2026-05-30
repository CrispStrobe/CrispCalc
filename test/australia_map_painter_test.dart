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

  group('region geometry', () {
    final polys = AustraliaMapView.regionPolygons;

    // The Russell & Norvig adjacency list (the `mapColoringAustralia`
    // DSL program's `!=` constraints). Tasmania is intentionally absent
    // — an island with no land border.
    const adjacencies = <List<String>>[
      ['wa', 'nt'],
      ['wa', 'sa'],
      ['nt', 'sa'],
      ['nt', 'q'],
      ['sa', 'q'],
      ['sa', 'nsw'],
      ['sa', 'v'],
      ['q', 'nsw'],
      ['nsw', 'v'],
    ];

    int sharedVertices(String a, String b) {
      final pa = polys[a]!.toSet();
      return polys[b]!.where(pa.contains).length;
    }

    test('every region has a polygon over the 0..100 grid', () {
      expect(polys.keys.toSet(), AustraliaMapView.regionKeys);
      for (final entry in polys.entries) {
        expect(entry.value.length, greaterThanOrEqualTo(3),
            reason: '${entry.key} must be a polygon');
        for (final p in entry.value) {
          expect(p.dx, inInclusiveRange(0, 100), reason: '${entry.key} x');
          expect(p.dy, inInclusiveRange(0, 100), reason: '${entry.key} y');
        }
      }
    });

    test('each adjacency is a genuine shared edge (>=2 common vertices)', () {
      for (final pair in adjacencies) {
        expect(sharedVertices(pair[0], pair[1]), greaterThanOrEqualTo(2),
            reason: '${pair[0]}–${pair[1]} should share a border edge');
      }
    });

    test('non-adjacent region pairs do not form a shared edge', () {
      final adjSet = {for (final p in adjacencies) '${p[0]}-${p[1]}'};
      final names = AustraliaMapView.regionKeys.toList();
      for (var i = 0; i < names.length; i++) {
        for (var j = i + 1; j < names.length; j++) {
          final a = names[i], b = names[j];
          if (adjSet.contains('$a-$b') || adjSet.contains('$b-$a')) continue;
          expect(sharedVertices(a, b), lessThan(2),
              reason: '$a–$b are not adjacent and must not share an edge');
        }
      }
    });

    test('Tasmania is a separate island (shares no vertex with the mainland)',
        () {
      for (final other in AustraliaMapView.regionKeys.where((k) => k != 't')) {
        expect(sharedVertices('t', other), 0,
            reason: 't should not touch $other');
      }
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
