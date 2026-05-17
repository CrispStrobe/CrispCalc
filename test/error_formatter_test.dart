// test/error_formatter_test.dart
//
// Pattern coverage for EngineErrorFormatter. We pass the raw error strings
// the engine actually emits and assert that the friendly message
// reflects the right category. Localized strings are compared
// against the EN locale only here — locale coverage (every category
// non-empty across every locale) is enforced separately by the
// localizations_test.dart sweep.

import 'package:crisp_calc/localization/app_localizations.dart';
import 'package:crisp_calc/utils/error_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const t = EnLocalizations();

  group('isError', () {
    test('returns true for engine error strings', () {
      expect(EngineErrorFormatter.isError('Error: something'), isTrue);
    });
    test('returns true for friendly errors with the warning prefix', () {
      expect(EngineErrorFormatter.isError('⚠ heads up'), isTrue);
    });
    test('returns false for ordinary results', () {
      expect(EngineErrorFormatter.isError('3.14'), isFalse);
      expect(EngineErrorFormatter.isError('Matrix([[1, 2], [3, 4]])'), isFalse);
    });
  });

  group('format — non-error inputs pass through', () {
    test('numeric result returned unchanged', () {
      expect(EngineErrorFormatter.format('3.14', t), equals('3.14'));
    });
    test('matrix result returned unchanged', () {
      const m = 'Matrix([[1, 2], [3, 4]])';
      expect(EngineErrorFormatter.format(m, t), equals(m));
    });
  });

  group('format — parse errors', () {
    test('SymbolicMathException: evaluate - parse failed', () {
      final out = EngineErrorFormatter.format(
          'Error: evaluate failed: SymbolicMathException: evaluate - parse failed',
          t);
      expect(out, equals(t.errorParse));
    });
    test('lowercase parse error variant', () {
      final out =
          EngineErrorFormatter.format('Error: differentiate failed: parse failed', t);
      expect(out, equals(t.errorParse));
    });
    test('ParseException', () {
      final out = EngineErrorFormatter.format('Error: ParseException at column 5', t);
      expect(out, equals(t.errorParse));
    });
  });

  group('format — native library not loaded', () {
    test('differentiate requires native library', () {
      expect(
        EngineErrorFormatter.format('Error: differentiate requires native library', t),
        equals(t.errorNativeRequired),
      );
    });
    test('solve requires native library', () {
      expect(
        EngineErrorFormatter.format('Error: solve requires native library', t),
        equals(t.errorNativeRequired),
      );
    });
  });

  group('format — integrate not implemented', () {
    test('explicit "not implemented in SymEngine C API"', () {
      expect(
        EngineErrorFormatter.format(
            'Error: integrate failed: Error in integrate: not implemented in SymEngine C API',
            t),
        equals(t.errorIntegrateNotImplemented),
      );
    });
    test('engine-side "indefinite integrate() is not available"', () {
      expect(
        EngineErrorFormatter.format(
            'Error: indefinite integrate() is not available in this build of the symbolic_math_bridge',
            t),
        equals(t.errorIntegrateNotImplemented),
      );
    });
  });

  group('format — matrix-literal errors', () {
    test('invalid matrix literal in det', () {
      expect(
        EngineErrorFormatter.format('Error: det invalid matrix literal', t),
        equals(t.errorMatrixLiteral),
      );
    });
  });

  group('format — generic "Invalid X() syntax"', () {
    test('factor syntax', () {
      final out = EngineErrorFormatter.format('Error: Invalid factor() syntax', t);
      expect(out, contains('factor'));
      expect(out, equals(t.errorInvalidSyntax('factor')));
    });
    test('solve syntax', () {
      final out = EngineErrorFormatter.format('Error: Invalid solve() syntax', t);
      expect(out, equals(t.errorInvalidSyntax('solve')));
    });
    test('d/dx syntax', () {
      final out = EngineErrorFormatter.format('Error: Invalid d/dx() syntax', t);
      expect(out, equals(t.errorInvalidSyntax('d/dx')));
    });
  });

  group('format — passes through informative messages', () {
    test('gcd argument count keeps its useful text', () {
      final out =
          EngineErrorFormatter.format('Error: gcd() requires exactly 2 arguments', t);
      expect(out, contains('gcd'));
      expect(out, contains('2 arguments'));
      // No "Error:" prefix in the user-facing string.
      expect(out, isNot(startsWith('Error')));
    });
    test('solve format hint keeps the example', () {
      final out = EngineErrorFormatter.format(
          'Error: solve() format is solve(equation, variable)', t);
      expect(out, contains('solve(equation, variable)'));
      expect(out, isNot(startsWith('Error')));
    });
  });

  group('format — unknown error', () {
    test('unrecognized message gets the warning prefix but keeps detail', () {
      final out = EngineErrorFormatter.format('Error: something unexpected happened', t);
      expect(out, startsWith('⚠'));
      expect(out, contains('something unexpected happened'));
    });
  });
}
