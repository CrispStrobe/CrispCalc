import 'package:flutter_test/flutter_test.dart';
import 'package:crisp_calc/controllers/latex_controller.dart';

void main() {
  group('insert', () {
    test('appends text and advances cursor', () {
      final c = LatexController();
      c.insert('abc');
      expect(c.text, equals('abc'));
      expect(c.selection.baseOffset, equals(3));
    });

    test('cursorOffsetFromEnd places the cursor inside an inserted template',
        () {
      // For \frac{}{} (9 chars), -3 puts the cursor between the first { and }.
      final c = LatexController();
      c.insert(r'\frac{}{}', cursorOffsetFromEnd: -3);
      expect(c.text, equals(r'\frac{}{}'));
      expect(c.selection.baseOffset, equals(c.text.length - 3));
    });

    test('subsequent inserts go in at the cursor', () {
      final c = LatexController();
      c.insert(r'\frac{}{}', cursorOffsetFromEnd: -3);
      c.insert('x');
      expect(c.text, equals(r'\frac{x}{}'));
    });
  });

  group('backspace', () {
    test('deletes a single character', () {
      final c = LatexController()..insert('abc');
      c.backspace();
      expect(c.text, equals('ab'));
    });

    test('deletes an empty bracket pair atomically', () {
      final c = LatexController()..insert('{}');
      c.backspace();
      expect(c.text, equals(''));
    });

    test('deletes a whole \\func{} block', () {
      final c = LatexController()..insert(r'\sqrt{}');
      c.backspace();
      expect(c.text, equals(''));
    });

    test('is a no-op on an empty controller', () {
      final c = LatexController();
      c.backspace();
      expect(c.text, equals(''));
    });
  });

  group('clear and moveCursor', () {
    test('clear resets text and selection', () {
      final c = LatexController()..insert('abc');
      c.clear();
      expect(c.text, equals(''));
      expect(c.selection.baseOffset, equals(0));
    });

    test('moveCursor clamps to text bounds', () {
      final c = LatexController()..insert('ab');
      c.moveCursor(100);
      expect(c.selection.baseOffset, equals(2));
      c.moveCursor(-100);
      expect(c.selection.baseOffset, equals(0));
    });
  });

  test('notifyListeners fires on insert', () {
    final c = LatexController();
    var calls = 0;
    c.addListener(() => calls++);
    c.insert('a');
    expect(calls, greaterThanOrEqualTo(1));
  });
}
