import 'package:flutter_test/flutter_test.dart';
import 'package:crisp_calc/engine/app_state.dart';

void main() {
  // AppState is a singleton. Reset its mutable state between tests.
  setUp(() {
    final s = AppState();
    s.userVariables.clear();
    s.history.clear();
    for (var i = 0; i < s.graphFunctions.length; i++) {
      s.graphFunctions[i] = '';
    }
    s.setNumberFormat(NumberDisplayFormat.auto);
  });

  test('is a singleton', () {
    expect(identical(AppState(), AppState()), isTrue);
  });

  group('history', () {
    test('addHistoryEntry inserts at the front', () {
      final s = AppState();
      s.addHistoryEntry('1+1', '2');
      s.addHistoryEntry('2+2', '4');
      expect(s.history.first.expression, equals('2+2'));
      expect(s.history.first.result, equals('4'));
    });

    test('clearHistory removes everything', () {
      final s = AppState();
      s.addHistoryEntry('a', 'b');
      s.clearHistory();
      expect(s.history, isEmpty);
    });
  });

  group('variables', () {
    test('setVariable and getVariable round-trip', () {
      final s = AppState();
      s.setVariable('a', '5');
      expect(s.getVariable('a'), equals('5'));
    });

    test('removeVariable drops a stored name', () {
      final s = AppState();
      s.setVariable('a', '5');
      s.removeVariable('a');
      expect(s.getVariable('a'), isNull);
    });

    test('clearAllVariables empties the map', () {
      final s = AppState();
      s.setVariable('a', '1');
      s.setVariable('b', '2');
      s.clearAllVariables();
      expect(s.userVariables, isEmpty);
    });
  });

  group('functions', () {
    test('updateFunction stores at the given index', () {
      final s = AppState();
      s.updateFunction(2, 'x^2');
      expect(s.getGraphFunction(2), equals('x^2'));
    });

    test('updateFunction ignores out-of-range indices', () {
      final s = AppState();
      s.updateFunction(-1, 'bad');
      s.updateFunction(99, 'bad');
      expect(s.graphFunctions, everyElement(isEmpty));
    });

    test('clearFunction empties one slot', () {
      final s = AppState();
      s.updateFunction(0, 'sin(x)');
      s.clearFunction(0);
      expect(s.getGraphFunction(0), equals(''));
    });

    test('clearAllFunctions empties every slot', () {
      final s = AppState();
      s.updateFunction(0, 'sin(x)');
      s.updateFunction(1, 'cos(x)');
      s.clearAllFunctions();
      expect(s.graphFunctions, everyElement(isEmpty));
    });
  });

  group('number formatting', () {
    test('auto preserves integers as integers', () {
      final s = AppState();
      s.setNumberFormat(NumberDisplayFormat.auto);
      expect(s.formatNumber('129'), equals('129'));
    });

    test('auto preserves decimals', () {
      final s = AppState();
      s.setNumberFormat(NumberDisplayFormat.auto);
      expect(s.formatNumber('129.5'), equals('129.5'));
    });

    test('integer rounds half-up', () {
      final s = AppState();
      s.setNumberFormat(NumberDisplayFormat.integer);
      expect(s.formatNumber('129.5'), equals('130'));
    });

    test('one-decimal format', () {
      final s = AppState();
      s.setNumberFormat(NumberDisplayFormat.oneDecimal);
      expect(s.formatNumber('129'), equals('129.0'));
    });

    test('two-decimal format', () {
      final s = AppState();
      s.setNumberFormat(NumberDisplayFormat.twoDecimal);
      expect(s.formatNumber('129'), equals('129.00'));
    });

    test('non-numeric values pass through unchanged', () {
      final s = AppState();
      expect(s.formatNumber('x = {-2, 2}'), equals('x = {-2, 2}'));
    });
  });

  group('listener notification', () {
    test('setVariable notifies listeners', () {
      final s = AppState();
      var calls = 0;
      void listener() => calls++;
      s.addListener(listener);
      s.setVariable('a', '1');
      expect(calls, greaterThanOrEqualTo(1));
      s.removeListener(listener);
    });
  });

  group('Round 95: pending sudoku preset slot', () {
    test('starts empty', () {
      // Defensive: another test could leak. Drain first.
      AppState().consumePendingSudokuPresetId();
      expect(AppState().pendingSudokuPresetId, isNull);
    });

    test('request → read → consume → null', () {
      final s = AppState();
      s.requestLoadSudokuPreset('killer9x9');
      expect(s.pendingSudokuPresetId, 'killer9x9');
      expect(s.consumePendingSudokuPresetId(), 'killer9x9');
      expect(s.pendingSudokuPresetId, isNull);
      expect(s.consumePendingSudokuPresetId(), isNull);
    });

    test('request notifies listeners', () {
      final s = AppState();
      var calls = 0;
      void listener() => calls++;
      s.addListener(listener);
      s.requestLoadSudokuPreset('small4x4Easy');
      expect(calls, greaterThanOrEqualTo(1));
      s.removeListener(listener);
      s.consumePendingSudokuPresetId();
    });
  });

  group('Round 95: pending statistics tab slot', () {
    test('starts empty', () {
      AppState().consumePendingStatisticsTab();
      expect(AppState().pendingStatisticsTab, isNull);
    });

    test('request → read → consume → null', () {
      final s = AppState();
      s.requestLoadStatisticsTab('tests');
      expect(s.pendingStatisticsTab, 'tests');
      expect(s.consumePendingStatisticsTab(), 'tests');
      expect(s.pendingStatisticsTab, isNull);
    });

    test('request notifies listeners', () {
      final s = AppState();
      var calls = 0;
      void listener() => calls++;
      s.addListener(listener);
      s.requestLoadStatisticsTab('regression');
      expect(calls, greaterThanOrEqualTo(1));
      s.removeListener(listener);
      s.consumePendingStatisticsTab();
    });
  });
}
