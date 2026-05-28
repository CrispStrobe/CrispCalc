// test/function_reference_localization_test.dart
//
// Round 100 — Function Reference content i18n.
//
// The mechanism: AppLocalizations.functionRefDescription(id) and
// .functionRefExampleHint(id, index) return a localized override, or
// null to fall back to the English string baked into the catalog
// (FunctionReferences.all). EN always returns null (the catalog IS
// the English source of truth).
//
// Pilot scope: the CAS category is translated to DE. The category is
// translated as a *whole* so the dialog never shows mixed-language
// content within one category — this test enforces that completeness,
// so adding a CAS entry without its DE translation fails CI. Other
// categories (and FR/ES) intentionally fall back to English for now.

import 'package:crisp_calc/engine/function_reference.dart';
import 'package:crisp_calc/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final casEntries = FunctionReferences.all
      .where((e) => e.category == FunctionRefCategory.cas)
      .toList();

  test('CAS category is non-empty (guards the pilot scope)', () {
    expect(casEntries, isNotEmpty);
  });

  group('EN returns null (catalog is the English source of truth)', () {
    const t = EnLocalizations();
    for (final e in FunctionReferences.all) {
      test('${e.id}: description + hints null', () {
        expect(t.functionRefDescription(e.id), isNull);
        for (var i = 0; i < e.examples.length; i++) {
          expect(t.functionRefExampleHint(e.id, i), isNull);
        }
      });
    }
  });

  group('DE translates the entire CAS category', () {
    const t = DeLocalizations();
    for (final e in casEntries) {
      test('${e.id}: description present + non-empty', () {
        final d = t.functionRefDescription(e.id);
        expect(d, isNotNull, reason: 'DE missing description for ${e.id}');
        expect(d!.trim(), isNotEmpty);
      });

      test('${e.id}: every example hint present + non-empty', () {
        for (var i = 0; i < e.examples.length; i++) {
          final h = t.functionRefExampleHint(e.id, i);
          expect(h, isNotNull,
              reason: 'DE missing hint for ${e.id} example $i');
          expect(h!.trim(), isNotEmpty);
        }
      });
    }
  });

  group('DE hint lookup is bounds-safe', () {
    const t = DeLocalizations();
    test('out-of-range / negative index returns null, not a throw', () {
      final solve = casEntries.firstWhere((e) => e.id == 'solve');
      expect(t.functionRefExampleHint('solve', solve.examples.length), isNull);
      expect(t.functionRefExampleHint('solve', -1), isNull);
    });
    test('unknown id returns null', () {
      expect(t.functionRefDescription('bogus_unknown_id'), isNull);
      expect(t.functionRefExampleHint('bogus_unknown_id', 0), isNull);
    });
  });

  group('DE leaves non-CAS categories to the English fallback (for now)', () {
    const t = DeLocalizations();
    final nonCas = FunctionReferences.all
        .where((e) => e.category != FunctionRefCategory.cas);
    // Not asserting null for every one (a future round may translate
    // more categories); just confirm the fallback contract holds for a
    // representative number-theory entry so a partial translation
    // doesn't silently regress the English path.
    test('isprime falls back (description null) until translated', () {
      final hasIsprime = nonCas.any((e) => e.id == 'isprime');
      if (hasIsprime) {
        expect(t.functionRefDescription('isprime'), isNull);
      }
    });
  });
}
