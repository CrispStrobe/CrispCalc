// test/step_notes_localization_test.dart
//
// Every StepNote key emitted by `StepEngine` (differentiation,
// integration, equation solving) must have a translation in every
// supported locale — otherwise the StepsDialog silently falls back to
// the English `note` field and the i18n V2 promise breaks. This test
// pins all 34 keys with a representative param map and verifies each
// of en/de/fr/es returns a non-empty string with all placeholders
// substituted.

import 'package:crisp_calc/engine/step_engine.dart';
import 'package:crisp_calc/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final locales = <String, AppLocalizations>{
    'en': const EnLocalizations(),
    'de': const DeLocalizations(),
    'fr': const FrLocalizations(),
    'es': const EsLocalizations(),
  };

  // Each entry: (key, params used at emission sites). Keep in sync
  // with step_engine.dart. The values are representative samples —
  // the resolver should interpolate every placeholder it references.
  final samples = <StepNote>[
    const StepNote('startEquation'),
    const StepNote('moveRightSideOver'),
    const StepNote('noEqualsSign', {'body': 'x + 1'}),
    const StepNote('doesNotDependOn', {'var': 'x'}),
    const StepNote('solveFallthroughSymbolic'),
    const StepNote('linearIdentifyCoefs'),
    const StepNote('moveConstant'),
    const StepNote('divideByCoef', {'var': 'x'}),
    const StepNote('quadraticIdentifyCoefs', {'var': 'x'}),
    const StepNote('discriminant'),
    const StepNote('quadFormulaApply'),
    const StepNote('integralPullMinusOut'),
    const StepNote('exprDoesNotDependOn', {'expr': '5', 'var': 'x'}),
    const StepNote('integralIdentityPower1'),
    const StepNote('integralLinearity'),
    const StepNote('integralPullConstantOut', {'const': '3'}),
    const StepNote('integralReciprocalLog', {'var': 'x'}),
    const StepNote('integralPowerRule'),
    const StepNote('uSubLinear', {'u': '2x+1', 'slope': '2', 'var': 'x'}),
    const StepNote('integralStandardAntideriv', {'fn': 'sin'}),
    const StepNote(
        'uSubLinearFn', {'u': '2x+1', 'slope': '2', 'var': 'x', 'fn': 'cos'}),
    const StepNote('ibpLnX', {'var': 'x'}),
    const StepNote(
        'ibpXTimesF', {'var': 'x', 'right': 'sin(x)', 'v': '-cos(x)'}),
    const StepNote('ibpRepeated', {
      'u': 'x^2',
      'n': '2',
      'right': 'sin(x)',
      'v': '-cos(x)',
      'var': 'x',
    }),
    const StepNote('uSubNonlinear', {
      'u': 'x^2',
      'du': '2*x',
      'var': 'x',
      'fn': 'cos',
      // Use a non-unity ratio so the placeholder appears in every
      // locale's output — when ratio == '1' the templates use a
      // shorter branch that doesn't echo the value back.
      'ratio': '7',
    }),
    const StepNote('integralLogDerivative', {
      'den': 'x^2+1',
      'ratio': '1',
      'var': 'x',
    }),
    const StepNote('integralFallthroughSymbolic'),
    const StepNote('diffIdentity', {'var': 'x'}),
    const StepNote('diffSumDifference'),
    const StepNote('diffQuotient'),
    const StepNote('diffProduct'),
    const StepNote('diffPowerSimple'),
    const StepNote('diffPowerChain', {'base': '2x+1', 'var': 'x'}),
    const StepNote('diffExponential'),
    const StepNote('diffStandardSimple', {'fn': 'sin'}),
    const StepNote('diffStandardChain', {'var': 'x'}),
    const StepNote('diffFallthrough'),
  ];

  test('there are exactly 37 distinct keys to translate', () {
    expect(samples.length, 37);
    expect(samples.map((n) => n.key).toSet().length, 37);
  });

  for (final entry in locales.entries) {
    final tag = entry.key;
    final t = entry.value;

    group('$tag locale resolves every StepNote key', () {
      for (final note in samples) {
        test(note.key, () {
          final localized = t.stepNote(note);
          expect(localized, isNotNull,
              reason: 'Locale $tag missing translation for ${note.key}');
          expect(localized!.trim(), isNotEmpty);
          // Every placeholder we passed should appear in the output —
          // catches `${p['var']}` typos in the resolver. Skip when the
          // value contains LaTeX-like glyphs that templates may transform.
          for (final param in note.params.entries) {
            expect(localized, contains(param.value),
                reason: 'Locale $tag stepNote(${note.key}) dropped '
                    'placeholder "${param.key}" with value "${param.value}"');
          }
        });
      }
    });
  }

  test('unknown StepNote key returns null in every locale', () {
    for (final t in locales.values) {
      expect(t.stepNote(const StepNote('bogusNoSuchKey')), isNull);
    }
  });
}
