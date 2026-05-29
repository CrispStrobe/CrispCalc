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
// DE coverage is COMPLETE: every catalog entry has a German
// description and a German hint for every example. Adding a new
// catalog entry without its DE translation fails CI — same contract
// as worked_examples_localization_test. FR/ES are not translated yet
// and intentionally fall back to English; when they're done, add them
// to the `complete` map below.

import 'package:crisp_calc/engine/function_reference.dart';
import 'package:crisp_calc/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Locales whose function-reference prose is fully translated and
  // therefore held to completeness.
  final complete = <String, AppLocalizations>{
    'de': const DeLocalizations(),
    'fr': const FrLocalizations(),
    'es': const EsLocalizations(),
  };

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

  for (final entry in complete.entries) {
    final tag = entry.key;
    final t = entry.value;

    group('$tag translates every function-reference entry', () {
      for (final e in FunctionReferences.all) {
        test('${e.id}: description present + non-empty', () {
          final d = t.functionRefDescription(e.id);
          expect(d, isNotNull,
              reason: 'Locale $tag missing description for ${e.id}');
          expect(d!.trim(), isNotEmpty);
        });

        test('${e.id}: every example hint present + non-empty', () {
          for (var i = 0; i < e.examples.length; i++) {
            final h = t.functionRefExampleHint(e.id, i);
            expect(h, isNotNull,
                reason: 'Locale $tag missing hint for ${e.id} example $i');
            expect(h!.trim(), isNotEmpty);
          }
        });
      }
    });
  }

  group('DE hint lookup is bounds-safe', () {
    const t = DeLocalizations();
    test('out-of-range / negative index returns null, not a throw', () {
      final solve = FunctionReferences.all.firstWhere((e) => e.id == 'solve');
      expect(t.functionRefExampleHint('solve', solve.examples.length), isNull);
      expect(t.functionRefExampleHint('solve', -1), isNull);
    });
    test('unknown id returns null', () {
      expect(t.functionRefDescription('bogus_unknown_id'), isNull);
      expect(t.functionRefExampleHint('bogus_unknown_id', 0), isNull);
    });
  });
}
