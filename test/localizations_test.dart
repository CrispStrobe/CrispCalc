// test/localizations_test.dart
//
// Sanity-checks every concrete locale by touching every public string
// getter and every templated method. A new string on the abstract class
// without an override in one of the locales fails compile (Dart-level
// safety net), but this test additionally catches accidentally-empty
// translations and templated methods that throw on edge-case inputs.

import 'package:crisp_calc/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final locales = <String, AppLocalizations>{
    'en': const EnLocalizations(),
    'de': const DeLocalizations(),
    'fr': const FrLocalizations(),
    'es': const EsLocalizations(),
  };

  for (final entry in locales.entries) {
    final tag = entry.key;
    final t = entry.value;

    group('$tag locale strings are non-empty', () {
      test('nav + history strings', () {
        for (final s in [
          t.navCalculator,
          t.navGraphing,
          t.navFunctions,
          t.navAnalysis,
          t.navSettings,
          t.historyHere,
          t.historyLabel,
          t.clearHistory,
          t.clearHistoryConfirm,
          t.searchHistory,
          t.searchHistoryHint,
          t.historyNoMatches,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('graphing strings', () {
        for (final s in [
          t.allSlotsFull,
          t.clearAllFunctions,
          t.cancel,
          t.clearAll,
          t.zoomIn,
          t.zoomOut,
          t.resetView,
          t.showKeypad,
          t.hideKeypad,
          t.showAnnotations,
          t.hideAnnotations,
          t.analyzeFunctions,
          t.plotButton,
          t.enterFunctionPrompt,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('analysis hub + settings', () {
        for (final s in [
          t.analysisModulesTitle,
          t.moduleCurveSketching,
          t.modulePlanes,
          t.moduleConics,
          t.settingsTitle,
          t.settingsLanguage,
          t.settingsLanguageEnglish,
          t.settingsLanguageGerman,
          t.settingsLanguageFrench,
          t.settingsLanguageSpanish,
          t.settingsTheme,
          t.settingsThemeSystem,
          t.settingsLayoutBody,
          t.matrixDiagnosticsTitle,
          t.matrixDiagnosticsSubtitle,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('about strings', () {
        for (final s in [
          t.aboutTitle,
          t.aboutTagline,
          t.aboutPrivacy,
          t.aboutPrivacyText,
          t.aboutDisclaimer,
          t.aboutDisclaimerText,
          t.aboutLicense,
          t.aboutLicenseText,
          t.settingsAbout,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('templated methods produce well-formed strings', () {
        expect(t.graphingTitle(3).trim(), isNotEmpty);
        expect(t.functionAdded(1).trim(), isNotEmpty);
        expect(t.functionRemoved(2).trim(), isNotEmpty);
        expect(t.solveFor(1).trim(), isNotEmpty);
        expect(t.whereY(1, 'x^2').trim(), isNotEmpty);
        expect(t.aboutVersion('1.0').trim(), isNotEmpty);
        expect(t.matrixDiagnosticsSummary(6, 6).trim(), isNotEmpty);
        expect(t.differentiationStepsHeader('x').trim(), isNotEmpty);
        expect(t.solveStepsHeader('x').trim(), isNotEmpty);
        expect(t.integrationStepsHeader('x').trim(), isNotEmpty);
      });

      test('dialog action strings are present', () {
        for (final s in [
          t.dialogInsert,
          t.dialogClose,
          t.dialogShowSteps,
          t.dialogVariable,
          t.dialogExpression,
          t.dialogValue,
          t.dialogFunction,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('export / share / help strings are present', () {
        for (final s in [
          t.exportDataTitle,
          t.exportDataSubtitle,
          t.exportDataCopy,
          t.exportDataCopied,
          t.historyEntryCopyResult,
          t.historyEntryCopyLatex,
          t.historyEntryCopyLatexSubtitle,
          t.historyEntryReuse,
          t.historyEntryCopied,
          t.settingsExportData,
          t.settingsExportDataSubtitle,
          t.settingsHelp,
          t.settingsHelpSubtitle,
          t.helpTitle,
          t.helpFunctionsHeading,
          t.helpMatrixHeading,
          t.helpStepsHeading,
          t.helpMatrixBody,
          t.helpStepsBody,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('picker / step dialog titles are present', () {
        for (final s in [
          t.integralTitle,
          t.integralLowerBound,
          t.integralUpperBound,
          t.integralDefinite,
          t.nthRootTitle,
          t.nthRootBase,
          t.limitTitle,
          t.limitApproaches,
          t.substituteTitle,
          t.substituteUseStoredVariable,
          t.differentiationStepsTitle,
          t.solveStepsTitle,
          t.solveStepsEquationLabel,
          t.solveStepsSolveFor,
          t.solveStepsHint,
          t.integrationStepsTitle,
          t.integrationStepsIntegrandLabel,
          t.integrationStepsWrt,
          t.integrationStepsHint,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });
    });
  }
}
