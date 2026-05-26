// P9-A2: smoke tests for the Scene3DScreen. Verifies the empty
// state, that adding a plane shows up in the object panel, and
// that delete removes it. Doesn't exercise the painter — that's
// covered by the engine tests + the in-app render check.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crisp_calc/engine/app_state.dart';
import 'package:crisp_calc/engine/plane_math.dart' show Vector3;
import 'package:crisp_calc/engine/scene_3d/scene_object.dart';
import 'package:crisp_calc/localization/app_localizations.dart';
import 'package:crisp_calc/screens/scene_3d_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Reset the singleton AppState so each test starts with a clean
    // (empty) scene.
    final s = AppState();
    s.history.clear();
    s.userVariables.clear();
    s.userFunctions.clear();
    s.notepadDocuments.clear();
    // Drain the scene to defaults.
    for (final obj in List.of(s.scene3D.objects)) {
      s.removeSceneObject(obj.id);
    }
  });

  Future<void> pumpScene(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [AppLocalizationsDelegate()],
      supportedLocales: [Locale('en')],
      home: Scene3DScreen(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty hint when no objects are in the scene',
      (tester) async {
    await pumpScene(tester);
    expect(find.text('3D Scene'), findsOneWidget);
    expect(find.textContaining('+ button'), findsOneWidget);
    expect(find.text('No objects yet'), findsOneWidget);
  });

  testWidgets('plane added via AppState appears in the panel', (tester) async {
    AppState().addOrUpdateSceneObject(const PlaneObject(
      id: 'p1',
      label: 'X = 0',
      color: 0xFFE53935,
      a: 1,
      b: 0,
      c: 0,
      d: 0,
    ));
    await pumpScene(tester);
    expect(find.text('X = 0'), findsOneWidget);
    expect(find.text('No objects yet'), findsNothing);
  });

  testWidgets('line + sphere added via AppState appear in the panel',
      (tester) async {
    AppState().addOrUpdateSceneObject(const LineObject(
      id: 'l1',
      label: 'X axis',
      color: 0xFF43A047,
      point: Vector3(0, 0, 0),
      direction: Vector3(1, 0, 0),
    ));
    AppState().addOrUpdateSceneObject(const SphereObject(
      id: 's1',
      label: 'Unit sphere',
      color: 0xFFFB8C00,
      center: Vector3(0, 0, 0),
      radius: 1,
    ));
    await pumpScene(tester);
    expect(find.text('X axis'), findsOneWidget);
    expect(find.text('Unit sphere'), findsOneWidget);
  });

  testWidgets('reorderSceneObjects shuffles panel entries', (tester) async {
    AppState().addOrUpdateSceneObject(const PlaneObject(
      id: 'p1',
      label: 'First',
      color: 0xFFE53935,
      a: 1,
      b: 0,
      c: 0,
      d: 0,
    ));
    AppState().addOrUpdateSceneObject(const PlaneObject(
      id: 'p2',
      label: 'Second',
      color: 0xFF1E88E5,
      a: 0,
      b: 1,
      c: 0,
      d: 0,
    ));
    await pumpScene(tester);
    // Initial order — both visible. (Specific position assertions
    // would couple to the panel layout; ordering is exercised in the
    // engine-level tests.)
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);

    // Move 'First' (index 0) past the end (newIndex=2 == length).
    AppState().reorderSceneObjects(0, 2);
    await tester.pumpAndSettle();
    expect(AppState().scene3D.objects.map((o) => o.label).toList(),
        ['Second', 'First']);
  });

  testWidgets('removeSceneObject empties the panel', (tester) async {
    AppState().addOrUpdateSceneObject(const PlaneObject(
      id: 'p1',
      label: 'X = 0',
      color: 0xFFE53935,
      a: 1,
      b: 0,
      c: 0,
      d: 0,
    ));
    await pumpScene(tester);
    expect(find.text('X = 0'), findsOneWidget);

    AppState().removeSceneObject('p1');
    await tester.pumpAndSettle();
    expect(find.text('X = 0'), findsNothing);
    expect(find.text('No objects yet'), findsOneWidget);
  });
}
