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
          t.module3DTitle,
          t.module3DSubtitle,
          t.module3DFunctionLabel,
          t.module3DRangeLabel,
          t.module3DResample,
          t.module3DTapPlot,
          t.moduleUnitConverterTitle,
          t.moduleUnitConverterSubtitle,
          t.sectionVariables,
          t.sectionGraphFunctions,
          t.sectionMemorySlots,
          t.funcCtxShowOnGraph,
          t.funcCtxAnalyze,
          t.funcCtxDifferentiate,
          t.funcCtxIntegrate,
          t.funcCtxSolve,
          t.funcCtxCopy,
          t.funcEditorTitle,
          t.funcEditorDone,
          t.funcEditorSelectFirst,
          t.funcEditorAnalyzeTooltip,
          t.funcEditorGraphTooltip,
          t.unitDimLength,
          t.unitDimTime,
          t.unitDimMass,
          t.unitDimTemperature,
          t.unitDimVelocity,
          t.unitDimAngle,
          t.planeAnalysisTitle,
          t.planeRepCoordinate,
          t.planeRepParametric,
          t.buttonAnalyze,
          t.buttonClassify,
          t.curveAnalysisEnterFunction,
          t.curveResultWarnings,
          t.curveResultDerivatives,
          t.curveResultKeyPoints,
          t.curveResultYIntercept,
          t.curveResultRoots,
          t.curveResultExtrema,
          t.curveResultInflectionPoints,
          t.curveResultNoExtrema,
          t.curveResultNoInflection,
          t.extremumLocalMinimum,
          t.extremumLocalMaximum,
          t.extremumCriticalPoint,
          t.extremumInflectionPoint,
          t.extremumNoCriticalPoints,
          t.extremumConstantConcavity,
          t.statisticsTitle,
          t.statsTabDescriptive,
          t.statsTabRegression,
          t.statsTabDistributions,
          t.statsTabTests,
          t.statsDescCount,
          t.statsDescSum,
          t.statsDescMean,
          t.statsDescMedian,
          t.statsDescMode,
          t.statsDescMin,
          t.statsDescMax,
          t.statsDescRange,
          t.statsDescVariance,
          t.statsDescStddev,
          t.statsDescQ1,
          t.statsDescQ3,
          t.statsDescIqr,
          t.helpGroupProbability,
          t.helpFnRrefDescription,
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

      test('constants library strings are present', () {
        for (final s in [
          t.constantsTitle,
          t.constantsSearchHint,
          t.constantsNoMatches,
          t.constantsAllCategory,
          t.constantsCategoryMathematical,
          t.constantsCategoryPhysical,
          t.constantsCategoryChemistry,
          t.constantsCategoryAstronomy,
          t.constantsCopyValue,
          t.constantsCopiedToast('c'),
          t.settingsConstants,
          t.settingsConstantsSubtitle,
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

      test('exact integer mode strings are present', () {
        for (final s in [
          t.settingsExactIntegerMode,
          t.settingsExactIntegerModeSubtitle,
          t.exactIntegerTapToCopy,
          t.exactIntegerBadge(158),
        ]) {
          expect(s.trim(), isNotEmpty);
        }
        // Templated badge interpolates the digit count.
        expect(t.exactIntegerBadge(158), contains('158'));
      });

      test('accessibility tooltip strings are present', () {
        for (final s in [
          t.clearSearchTooltip,
          t.clearFunctionSlotTooltip,
          t.deleteMemorySlotTooltip,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('long-eval calculating string is present', () {
        expect(t.calculating.trim(), isNotEmpty);
      });

      test('Sudoku module strings are present', () {
        for (final s in [
          t.moduleSudokuTitle,
          t.moduleSudokuSubtitle,
          t.sudokuSolveButton,
          t.sudokuClearCell,
          t.sudokuPresetLabelChooser,
          t.sudokuPresetCustom,
          t.sudokuVisualizerHeader,
          t.sudokuPlay,
          t.sudokuPause,
          t.sudokuRestart,
          t.sudokuSpeedSlow,
          t.sudokuSpeedMed,
          t.sudokuSpeedFast,
          t.sudokuGenerateButton,
          t.sudokuDifficultyEasy,
          t.sudokuDifficultyMedium,
          t.sudokuDifficultyHard,
          t.sudokuVariantRegular,
          t.sudokuVariantX,
          t.sudokuVariantKiller,
          t.sudokuCheckUnique,
          t.sudokuUniqueSolution,
          t.sudokuMultipleSolutions,
          t.sudokuShowHints,
          t.sudokuShowHintsSubtitle,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
        // Preset-id dispatch should resolve every preset to a
        // non-empty label.
        for (final id in [
          'small4x4Easy',
          'small4x4Medium',
          'small4x4Hard',
          'medium6x6',
          'standard9x9Easy',
          'standard9x9Medium',
          'standard9x9Hard',
          'killer4x4',
          'killer9x9',
        ]) {
          expect(t.sudokuPresetLabel(id).trim(), isNotEmpty);
        }
        // Unknown id falls back to the id itself (not null).
        expect(t.sudokuPresetLabel('bogus'), 'bogus');
      });

      test('CSP / Constraints module strings are present', () {
        for (final s in [
          t.moduleConstraintsTitle,
          t.moduleConstraintsSubtitle,
          t.constraintsTabDiophantine,
          t.constraintsTabCryptarithm,
          t.constraintsDiophantineIntro,
          t.constraintsCryptarithmIntro,
          t.constraintsVariablesLabel,
          t.constraintsVariablesHint,
          t.constraintsConstraintsLabel,
          t.constraintsConstraintsHint,
          t.constraintsCryptarithmInputLabel,
          t.constraintsSolveButton,
          t.constraintsBadVarLine,
          t.constraintsNoSolutions,
          t.constraintsCryptarithmFoundHeader,
          t.constraintsCopyResult,
          t.constraintsCopiedToast,
          t.constraintsSolutionsHeader(1),
          t.constraintsSolutionsHeader(5),
          t.constraintsTruncatedHeader(100),
        ]) {
          expect(s.trim(), isNotEmpty);
        }
        // Pluralization sanity.
        expect(t.constraintsSolutionsHeader(5), contains('5'));
        expect(t.constraintsTruncatedHeader(100), contains('100'));
      });

      test('worked examples strings are present', () {
        for (final s in [
          t.workedExamplesTitle,
          t.workedExamplesSearchHint,
          t.workedExamplesEmpty,
          t.workedExamplesCopy,
          t.workedExamplesCopied,
          t.workedExamplesInsert,
          t.workedExamplesCatAll,
          t.workedExamplesCatCalculus,
          t.workedExamplesCatAlgebra,
          t.workedExamplesCatLinearAlgebra,
          t.workedExamplesCatNumberTheory,
          t.workedExamplesCatStatistics,
          t.workedExamplesCatUnits,
          t.settingsWorkedExamples,
          t.settingsWorkedExamplesSubtitle,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('import data strings are present', () {
        for (final s in [
          t.importDataTitle,
          t.importDataSubtitle,
          t.importDataWarning,
          t.importDataApply,
          t.importDataEmpty,
          t.importDataNotObject,
          t.importDataApplied,
          t.settingsImportData,
          t.settingsImportDataSubtitle,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('user-defined functions strings are present', () {
        for (final s in [
          t.userFunctionsTitle,
          t.userFunctionsHelp,
          t.userFunctionsEmpty,
          t.userFunctionsAdd,
          t.userFunctionsEdit,
          t.userFunctionsDelete,
          t.userFunctionsName,
          t.userFunctionsNameHelp,
          t.userFunctionsNameRequired,
          t.userFunctionsNameInvalid,
          t.userFunctionsParam,
          t.userFunctionsBody,
          t.userFunctionsBodyRequired,
          t.settingsUserFunctions,
          t.settingsUserFunctionsSubtitle,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
      });

      test('onboarding tour strings are present', () {
        for (final s in [
          t.onboardingSkip,
          t.onboardingNext,
          t.onboardingDone,
          t.onboardingPage(1, 4),
          t.onboardingKeypadTitle,
          t.onboardingKeypadBody,
          t.onboardingHistoryTitle,
          t.onboardingHistoryBody,
          t.onboardingFunctionsTitle,
          t.onboardingFunctionsBody,
          t.onboardingAnalysisTitle,
          t.onboardingAnalysisBody,
          t.settingsReplayTour,
          t.settingsReplayTourSubtitle,
        ]) {
          expect(s.trim(), isNotEmpty);
        }
        // Templated page indicator interpolates both numbers.
        expect(t.onboardingPage(2, 4), contains('2'));
        expect(t.onboardingPage(2, 4), contains('4'));
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
