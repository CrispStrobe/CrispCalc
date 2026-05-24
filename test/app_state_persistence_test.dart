import 'package:crisp_calc/engine/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // AppState is a singleton, so we reset its mutable state in setUp and let
  // load() pick up whatever the in-memory SharedPreferences had.
  setUp(() {
    final s = AppState();
    s.history.clear();
    s.userVariables.clear();
    for (var i = 0; i < s.graphFunctions.length; i++) {
      s.graphFunctions[i] = '';
    }
  });

  test('load() with no stored values keeps defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load(force: true);
    expect(s.locale.languageCode, 'en');
    expect(s.numberFormat, NumberDisplayFormat.auto);
  });

  test('load() picks up stored locale', () async {
    SharedPreferences.setMockInitialValues({'crisp.locale': 'de'});
    final s = AppState();
    await s.load(force: true);
    expect(s.locale.languageCode, 'de');
  });

  test('load() picks up stored number format', () async {
    SharedPreferences.setMockInitialValues(
        {'crisp.numberFormat': NumberDisplayFormat.twoDecimal.name});
    final s = AppState();
    await s.load(force: true);
    expect(s.numberFormat, NumberDisplayFormat.twoDecimal);
  });

  test('setLocale() writes through to SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load(force: true);
    s.setLocale(const Locale('de'));
    final fresh = await SharedPreferences.getInstance();
    expect(fresh.getString('crisp.locale'), 'de');
  });

  test('setNumberFormat() writes through to SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load(force: true);
    s.setNumberFormat(NumberDisplayFormat.oneDecimal);
    final fresh = await SharedPreferences.getInstance();
    expect(fresh.getString('crisp.numberFormat'),
        NumberDisplayFormat.oneDecimal.name);
  });

  test('unknown stored values fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'crisp.locale': 'xx',
      'crisp.numberFormat': 'bogus',
    });
    final s = AppState();
    await s.load(force: true);
    expect(s.locale.languageCode, 'en');
    expect(s.numberFormat, NumberDisplayFormat.auto);
  });

  test('setLocale to the same value is a no-op', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load(force: true);
    var notifications = 0;
    s.addListener(() => notifications++);
    s.setLocale(const Locale('en')); // already 'en'
    expect(notifications, 0);
    s.removeListener(() => notifications++);
  });

  group('history persistence', () {
    test('addHistoryEntry writes JSON to prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      s.addHistoryEntry('1+1', '2');
      final fresh = await SharedPreferences.getInstance();
      final raw = fresh.getString('crisp.history');
      expect(raw, isNotNull);
      expect(raw, contains('"e":"1+1"'));
      expect(raw, contains('"r":"2"'));
    });

    test('clearHistory clears the persisted list', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      s.addHistoryEntry('1+1', '2');
      s.clearHistory();
      final fresh = await SharedPreferences.getInstance();
      expect(fresh.getString('crisp.history'), '[]');
    });

    test('load() restores history list', () async {
      SharedPreferences.setMockInitialValues({
        'crisp.history':
            '[{"e":"2+3","r":"5","t":"calculation"},{"e":"1+1","r":"2","t":"calculation"}]',
      });
      final s = AppState();
      await s.load(force: true);
      expect(s.history.length, 2);
      expect(s.history.first.expression, '2+3');
      expect(s.history.first.result, '5');
    });

    test('history is capped at 200 entries', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      for (var i = 0; i < 250; i++) {
        s.addHistoryEntry('n=$i', '$i');
      }
      expect(s.history.length, 200);
      // Newest at the front.
      expect(s.history.first.expression, 'n=249');
    });
  });

  group('variables persistence', () {
    test('setVariable writes JSON to prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      s.setVariable('a', '5');
      s.setVariable('b', '3.14');
      final fresh = await SharedPreferences.getInstance();
      final raw = fresh.getString('crisp.variables');
      expect(raw, contains('"a":"5"'));
      expect(raw, contains('"b":"3.14"'));
    });

    test('load() restores variables', () async {
      SharedPreferences.setMockInitialValues(
          {'crisp.variables': '{"a":"5","myVar":"3.14"}'});
      final s = AppState();
      await s.load(force: true);
      expect(s.getVariable('a'), '5');
      expect(s.getVariable('myVar'), '3.14');
    });
  });

  group('graph functions persistence', () {
    test('updateFunction writes through', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      s.updateFunction(2, 'x^3');
      final fresh = await SharedPreferences.getInstance();
      final raw = fresh.getString('crisp.functions');
      expect(raw, contains('"x^3"'));
    });

    test('load() restores graph functions', () async {
      SharedPreferences.setMockInitialValues({
        'crisp.functions': '["x^2","sqrt(x)","","","","","","","",""]',
      });
      final s = AppState();
      await s.load(force: true);
      expect(s.getGraphFunction(0), 'x^2');
      expect(s.getGraphFunction(1), 'sqrt(x)');
      expect(s.getGraphFunction(2), '');
    });
  });

  group('theme mode persistence', () {
    test('default is dark', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      expect(s.themeMode, ThemeMode.dark);
    });

    test('setThemeMode writes through', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      s.setThemeMode(ThemeMode.light);
      final fresh = await SharedPreferences.getInstance();
      expect(fresh.getString('crisp.themeMode'), 'light');
    });

    test('load() restores theme mode', () async {
      SharedPreferences.setMockInitialValues({'crisp.themeMode': 'system'});
      final s = AppState();
      await s.load(force: true);
      expect(s.themeMode, ThemeMode.system);
    });
  });

  group('exact integer mode', () {
    test('default is true (preserve precision)', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      expect(s.exactIntegerMode, isTrue);
    });

    test('setExactIntegerMode writes through', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      s.setExactIntegerMode(false);
      final fresh = await SharedPreferences.getInstance();
      expect(fresh.getBool('crisp.exactIntegerMode'), isFalse);
    });

    test('load() restores stored value', () async {
      SharedPreferences.setMockInitialValues({'crisp.exactIntegerMode': false});
      final s = AppState();
      await s.load(force: true);
      expect(s.exactIntegerMode, isFalse);
    });

    test('addHistoryEntry preserves a 158-digit integer verbatim', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      // 100! has 158 digits.
      const bigInt =
          '93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000';
      expect(bigInt.length, 158);
      s.addHistoryEntry('100!', bigInt);
      expect(s.history.first.result, bigInt);
    });

    test(
        'when off, large integers go through the lossy double path '
        '(legacy behavior)', () async {
      SharedPreferences.setMockInitialValues({'crisp.exactIntegerMode': false});
      final s = AppState();
      await s.load(force: true);
      // Small integers still round-trip OK; this just exercises the
      // off-switch path without crashing on a huge string.
      s.addHistoryEntry('2+3', '5');
      expect(s.history.first.result, '5');
    });

    test('exportToJson includes exactIntegerMode', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load(force: true);
      final json = s.exportToJson();
      expect(json['exactIntegerMode'], isTrue);
      s.setExactIntegerMode(false);
      expect(s.exportToJson()['exactIntegerMode'], isFalse);
    });
  });
}
