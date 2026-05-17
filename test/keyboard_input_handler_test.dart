import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crisp_calc/utils/keyboard_input_handler.dart';

class _Sink {
  String inserted = '';
  int backspaces = 0;
  int clears = 0;
  int executes = 0;
  int cursorMoves = 0;
}

KeyEvent _down(LogicalKeyboardKey k, {String? character}) {
  return KeyDownEvent(
    physicalKey: PhysicalKeyboardKey.escape,
    logicalKey: k,
    character: character,
    timeStamp: Duration.zero,
  );
}

KeyEvent _char(String c) {
  return KeyDownEvent(
    physicalKey: PhysicalKeyboardKey.escape,
    logicalKey: LogicalKeyboardKey(c.codeUnitAt(0)),
    character: c,
    timeStamp: Duration.zero,
  );
}

bool _dispatch(KeyEvent event, _Sink s, {bool multiplicationAsCdot = true}) {
  return KeyboardInputHandler.handleKeyboardInput(
    event,
    (text) => s.inserted += text,
    () => s.backspaces++,
    () => s.clears++,
    () => s.executes++,
    (_) => s.cursorMoves++,
    multiplicationAsCdot: multiplicationAsCdot,
  );
}

void main() {
  group('action keys', () {
    test('Enter triggers execute', () {
      final s = _Sink();
      expect(_dispatch(_down(LogicalKeyboardKey.enter), s), isTrue);
      expect(s.executes, equals(1));
    });

    test('Escape clears', () {
      final s = _Sink();
      expect(_dispatch(_down(LogicalKeyboardKey.escape), s), isTrue);
      expect(s.clears, equals(1));
    });

    test('Backspace deletes', () {
      final s = _Sink();
      expect(_dispatch(_down(LogicalKeyboardKey.backspace), s), isTrue);
      expect(s.backspaces, equals(1));
    });

    test('Arrows move the cursor', () {
      final s = _Sink();
      expect(_dispatch(_down(LogicalKeyboardKey.arrowLeft), s), isTrue);
      expect(_dispatch(_down(LogicalKeyboardKey.arrowRight), s), isTrue);
      expect(s.cursorMoves, equals(2));
    });
  });

  group('numpad fallbacks', () {
    test('numpad add/subtract/multiply/divide/decimal', () {
      final s = _Sink();
      _dispatch(_down(LogicalKeyboardKey.numpadAdd), s);
      _dispatch(_down(LogicalKeyboardKey.numpadSubtract), s);
      _dispatch(_down(LogicalKeyboardKey.numpadMultiply), s);
      _dispatch(_down(LogicalKeyboardKey.numpadDivide), s);
      _dispatch(_down(LogicalKeyboardKey.numpadDecimal), s);
      expect(s.inserted, equals('+-\\cdot /.'));
    });

    test('numpad multiply respects multiplicationAsCdot=false', () {
      final s = _Sink();
      _dispatch(
        _down(LogicalKeyboardKey.numpadMultiply),
        s,
        multiplicationAsCdot: false,
      );
      expect(s.inserted, equals('*'));
    });
  });

  group('character input', () {
    test('letters are inserted verbatim', () {
      final s = _Sink();
      _dispatch(_char('y'), s);
      expect(s.inserted, equals('y'));
    });

    test(
        'Y is not swapped with Z (regression: old code unconditionally swapped)',
        () {
      final s = _Sink();
      _dispatch(_char('Y'), s);
      _dispatch(_char('Z'), s);
      expect(s.inserted, equals('YZ'));
    });

    test('* becomes \\cdot by default', () {
      final s = _Sink();
      _dispatch(_char('*'), s);
      expect(s.inserted, equals(r'\cdot '));
    });

    test('* stays * when multiplicationAsCdot is false', () {
      final s = _Sink();
      _dispatch(_char('*'), s, multiplicationAsCdot: false);
      expect(s.inserted, equals('*'));
    });

    test('% becomes /100', () {
      final s = _Sink();
      _dispatch(_char('%'), s);
      expect(s.inserted, equals('/100'));
    });

    test('^ inserts an empty exponent template', () {
      final s = _Sink();
      _dispatch(_char('^'), s);
      expect(s.inserted, equals('^{}'));
      expect(s.cursorMoves, equals(1));
    });
  });

  test('non-key-down events are not handled', () {
    final s = _Sink();
    final up = KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.escape,
      logicalKey: LogicalKeyboardKey.enter,
      timeStamp: Duration.zero,
    );
    expect(_dispatch(up, s), isFalse);
    expect(s.executes, equals(0));
  });
}
