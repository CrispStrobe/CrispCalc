// test/exact_integer_test.dart
//
// Detection / digit count / abbreviation helpers for arbitrary-precision
// integer results from the SymEngine bridge (e.g. 100! = 158 digits).

import 'package:crisp_calc/utils/exact_integer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExactInteger.matches', () {
    test('accepts plain non-negative integers', () {
      expect(ExactInteger.matches('0'), isTrue);
      expect(ExactInteger.matches('5'), isTrue);
      expect(ExactInteger.matches('12345'), isTrue);
    });

    test('accepts negative integers', () {
      expect(ExactInteger.matches('-1'), isTrue);
      expect(ExactInteger.matches('-9876543210'), isTrue);
    });

    test('accepts surrounding whitespace', () {
      expect(ExactInteger.matches('  42  '), isTrue);
      expect(ExactInteger.matches('\n100\t'), isTrue);
    });

    test('accepts a 158-digit integer (100!)', () {
      // 100! = a 158-digit number. Use a synthesized string of digits.
      final long = '9332621544394415268169923885626670049071596826438' * 3;
      expect(long.length > 100, isTrue);
      expect(ExactInteger.matches(long), isTrue);
    });

    test('rejects empty / sign-only strings', () {
      expect(ExactInteger.matches(''), isFalse);
      expect(ExactInteger.matches('   '), isFalse);
      expect(ExactInteger.matches('-'), isFalse);
    });

    test('rejects floats and scientific notation', () {
      expect(ExactInteger.matches('5.0'), isFalse);
      expect(ExactInteger.matches('1e10'), isFalse);
      expect(ExactInteger.matches('3.14'), isFalse);
    });

    test('rejects symbolic and error strings', () {
      expect(ExactInteger.matches('Error: parse failed'), isFalse);
      expect(ExactInteger.matches('5*x'), isFalse);
      expect(ExactInteger.matches('1/2'), isFalse);
      expect(ExactInteger.matches('+5'), isFalse); // leading + not accepted
      expect(ExactInteger.matches('5 + 3*I'), isFalse);
    });
  });

  group('ExactInteger.digitCount', () {
    test('counts digits in a positive integer', () {
      expect(ExactInteger.digitCount('42'), 2);
      expect(ExactInteger.digitCount('1000000'), 7);
    });

    test('counts digits in a negative integer (excludes sign)', () {
      expect(ExactInteger.digitCount('-1'), 1);
      expect(ExactInteger.digitCount('-12345'), 5);
    });

    test('returns 0 for non-integer strings', () {
      expect(ExactInteger.digitCount('5.0'), 0);
      expect(ExactInteger.digitCount('Error'), 0);
      expect(ExactInteger.digitCount(''), 0);
    });
  });

  group('ExactInteger.abbreviate', () {
    test('returns short integers unchanged', () {
      expect(ExactInteger.abbreviate('42'), '42');
      expect(ExactInteger.abbreviate('-100'), '-100');
    });

    test('elides middle of very long integers', () {
      final long = '1${'0' * 200}'; // 201-digit integer
      final abbr = ExactInteger.abbreviate(long);
      expect(abbr.contains('…'), isTrue);
      expect(abbr.length < long.length, isTrue);
    });

    test('preserves leading minus when abbreviating', () {
      final long = '-${'9' * 200}';
      final abbr = ExactInteger.abbreviate(long);
      expect(abbr.startsWith('-'), isTrue);
      expect(abbr.contains('…'), isTrue);
    });

    test('non-integer strings are returned unchanged', () {
      expect(ExactInteger.abbreviate('Error: bad parse'), 'Error: bad parse');
      expect(ExactInteger.abbreviate('5.0'), '5.0');
    });
  });
}
