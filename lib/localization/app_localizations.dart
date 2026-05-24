// lib/localization/app_localizations.dart
//
// Centralized i18n. Add a new locale by subclassing AppLocalizations and
// wiring it into the delegate at the bottom. Strings are grouped by feature
// so it's easy to spot what's missing when adding a language.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../engine/step_engine.dart' show StepNote;

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const EnLocalizations();
  }

  // -- Nav destinations --
  String get navCalculator;
  String get navGraphing;
  String get navFunctions;
  String get navAnalysis;
  String get navSettings;

  // -- Calculator screen --
  String get historyHere;
  String get historyLabel;
  String get clearButton;
  String get clearHistory;
  String get clearHistoryConfirm;
  String get searchHistory;
  String get searchHistoryHint;
  String get historyNoMatches;

  // -- Graphing screen --
  String graphingTitle(int count);
  String functionAdded(int slot);
  String functionRemoved(int slot);
  String get allSlotsFull;
  String get clearAllFunctions;
  String get clearAllFunctionsConfirm;
  String get cancel;
  String get clearAll;
  String get zoomIn;
  String get zoomOut;
  String get resetView;
  String get showKeypad;
  String get hideKeypad;
  String get showAnnotations;
  String get hideAnnotations;
  String get analyzeFunctions;
  String get selectFunctionToAnalyze;
  String get plotButton;
  String get enterFunctionPrompt;

  // -- Analysis hub --
  String get analysisModulesTitle;
  String get moduleCurveSketching;
  String get moduleCurveSketchingSubtitle;
  String get modulePlanes;
  String get modulePlanesSubtitle;
  String get moduleConics;
  String get moduleConicsSubtitle;
  String get moduleStatistics;
  String get moduleStatisticsSubtitle;
  String get module3DTitle;
  String get module3DSubtitle;
  String get module3DFunctionLabel;
  String get module3DRangeLabel;
  String get module3DResample;
  String get module3DTapPlot;
  String get moduleUnitConverterTitle;
  String get moduleUnitConverterSubtitle;
  // -- Variable / function panel --
  String get sectionVariables;
  String get sectionGraphFunctions;
  String get sectionMemorySlots;
  // -- Function context menu (long-press / right-click on a function tile) --
  String get funcCtxShowOnGraph;
  String get funcCtxAnalyze;
  String get funcCtxDifferentiate;
  String get funcCtxIntegrate;
  String get funcCtxSolve;
  String get funcCtxCopy;
  // -- Function editor --
  String get funcEditorTitle;
  String get funcEditorDone;
  String get funcEditorSelectFirst;
  String get funcEditorAnalyzeTooltip;
  String get funcEditorGraphTooltip;
  // -- Unit dimension labels (used in the Unit Converter dialog) --
  String get unitDimLength;
  String get unitDimTime;
  String get unitDimMass;
  String get unitDimTemperature;
  String get unitDimVelocity;
  String get unitDimAngle;
  // -- Plane analysis --
  String get planeAnalysisTitle;
  String get planeRepCoordinate;
  String get planeRepParametric;
  // -- Generic action buttons --
  String get buttonAnalyze;
  String get buttonClassify;
  // -- Curve analysis input + results --
  String get curveAnalysisEnterFunction;
  String get curveResultWarnings;
  String get curveResultDerivatives;
  String get curveResultKeyPoints;
  String get curveResultYIntercept;
  String get curveResultRoots;
  String get curveResultExtrema;
  String get curveResultInflectionPoints;
  String get curveResultNoExtrema;
  String get curveResultNoInflection;
  String curveAnalysisOfFunction(String function);
  String curveResultPointPrefix(String point);
  // -- Classifications from the analysis engine (rendered via the
  //    `translateClassification` helper below) --
  String get extremumLocalMinimum;
  String get extremumLocalMaximum;
  String get extremumCriticalPoint;
  String get extremumInflectionPoint;
  String get extremumNoCriticalPoints;
  String get extremumConstantConcavity;
  // -- Statistics screen --
  String get statisticsTitle;
  String get statsTabDescriptive;
  String get statsTabRegression;
  String get statsTabDistributions;
  String get statsTabTests;
  String get statsDescCount;
  String get statsDescSum;
  String get statsDescMean;
  String get statsDescMedian;
  String get statsDescMode;
  String get statsDescMin;
  String get statsDescMax;
  String get statsDescRange;
  String get statsDescVariance;
  String get statsDescStddev;
  String get statsDescQ1;
  String get statsDescQ3;
  String get statsDescIqr;
  // -- Help screen pieces --
  String get helpGroupProbability;
  String get helpFnRrefDescription;

  // -- Settings --
  String get settingsTitle;
  String get settingsNumberFormat;
  String get settingsNumberFormatAuto;
  String get settingsNumberFormatInteger;
  String get settingsNumberFormatOneDecimal;
  String get settingsNumberFormatTwoDecimal;
  String get settingsLanguage;
  String get settingsLanguageEnglish;
  String get settingsLanguageGerman;
  String get settingsLanguageFrench;
  String get settingsLanguageSpanish;
  String get settingsTheme;
  String get settingsThemeSystem;
  String get settingsThemeLight;
  String get settingsThemeDark;
  String get settingsLayoutTitle;
  String get settingsLayoutBody;

  // -- About screen --
  String get aboutTitle;
  String get aboutTagline;
  String aboutVersion(String version);
  String get aboutServiceProvider;
  String get aboutContact;
  String get aboutPrivacy;
  String get aboutPrivacyText;
  String get aboutDisclaimer;
  String get aboutDisclaimerText;
  String get aboutLicense;
  String get aboutLicenseText;
  String get aboutOpenSourceLicenses;
  String get settingsAbout;
  String get matrixDiagnosticsTitle;
  String get matrixDiagnosticsSubtitle;
  String matrixDiagnosticsSummary(int passed, int total);
  String get unitConverterTitle;
  String get unitConverterSubtitle;

  // -- Picker dialogs --
  String get selectEquation;
  String get continueTyping;
  String get selectFunction;
  String get dismissPanel;
  String solveFor(int n);
  String whereY(int n, String func);

  // -- Shared dialog actions / labels --
  String get dialogInsert;
  String get dialogClose;
  String get dialogShowSteps;
  String get dialogVariable;
  String get dialogExpression;
  String get dialogValue;
  String get dialogFunction;

  // -- Integral / NthRoot / Limit / Substitute dialogs --
  String get integralTitle;
  String get integralLowerBound;
  String get integralUpperBound;
  String get integralDefinite;
  String get nthRootTitle;
  String get nthRootBase;
  String get limitTitle;
  String get limitApproaches;
  String get substituteTitle;
  String get substituteUseStoredVariable;

  // -- Step-by-step dialogs (entry-prompt + headlines) --
  String get differentiationStepsTitle;
  String differentiationStepsHeader(String variable);
  String get solveStepsTitle;
  String get solveStepsEquationLabel;
  String get solveStepsSolveFor;
  String get solveStepsHint;
  String solveStepsHeader(String variable);
  String get integrationStepsTitle;
  String get integrationStepsIntegrandLabel;
  String get integrationStepsWrt;
  String get integrationStepsHint;
  String integrationStepsHeader(String variable);

  // -- Calculator errors --
  String get errorSolveFormat;
  String get errorInvalidSolve;
  String get errorInvalidDiff;
  String get errorInvalidFactor;
  String get errorInvalidExpand;
  String get errorInvalidSimplify;
  String get errorGcdArgs;
  String get errorInvalidGcd;
  String get errorLcmArgs;
  String get errorInvalidLcm;

  // -- Friendly errors (shown in history when an op fails) --
  String get errorParse;
  String get errorNativeRequired;
  String get errorIntegrateNotImplemented;
  String get errorMatrixLiteral;
  String get errorInternalMatrixDisposed;
  String errorInvalidSyntax(String op);

  // -- Export + share --
  String get exportDataTitle;
  String get exportDataSubtitle;
  String get exportDataCopy;
  String get exportDataCopied;
  String get historyEntryCopyResult;
  String get historyEntryCopyLatex;
  String get historyEntryCopyLatexSubtitle;
  String get historyEntryReuse;
  String get historyEntryCopied;

  // -- Settings tile labels for the new entries --
  String get settingsExportData;
  String get settingsExportDataSubtitle;
  String get settingsHelp;
  String get settingsHelpSubtitle;

  // -- Exact integer mode (arbitrary-precision results) --
  String get settingsExactIntegerMode;
  String get settingsExactIntegerModeSubtitle;
  String exactIntegerBadge(int digits);
  String get exactIntegerTapToCopy;

  // -- Long-evaluation progress overlay (V2) --
  String get calculating;

  // -- Sudoku module (Analysis hub / CSP Round B) --
  String get moduleSudokuTitle;
  String get moduleSudokuSubtitle;
  String get sudokuSolveButton;
  String get sudokuClearCell;
  String get sudokuPresetLabelChooser;
  String get sudokuPresetCustom;
  String sudokuPresetLabel(String id);
  String get sudokuVisualizerHeader;
  String get sudokuPlay;
  String get sudokuPause;
  String get sudokuRestart;
  String get sudokuSpeedSlow;
  String get sudokuSpeedMed;
  String get sudokuSpeedFast;
  String get sudokuGenerateButton;
  String get sudokuDifficultyEasy;
  String get sudokuDifficultyMedium;
  String get sudokuDifficultyHard;
  String get sudokuVariantRegular;
  String get sudokuVariantX;

  // -- Constraints module (Analysis hub / CSP Round A) --
  String get moduleConstraintsTitle;
  String get moduleConstraintsSubtitle;
  String get constraintsTabDiophantine;
  String get constraintsTabCryptarithm;
  String get constraintsDiophantineIntro;
  String get constraintsCryptarithmIntro;
  String get constraintsVariablesLabel;
  String get constraintsVariablesHint;
  String get constraintsConstraintsLabel;
  String get constraintsConstraintsHint;
  String get constraintsCryptarithmInputLabel;
  String get constraintsSolveButton;
  String get constraintsBadVarLine;
  String get constraintsNoSolutions;
  String get constraintsCryptarithmFoundHeader;
  String constraintsSolutionsHeader(int n);
  String constraintsTruncatedHeader(int n);
  String get constraintsCopyResult;
  String get constraintsCopiedToast;

  // -- Accessibility tooltips (V1 a11y pass) --
  String get clearSearchTooltip;
  String get clearFunctionSlotTooltip;
  String get deleteMemorySlotTooltip;

  // -- Worked examples library --
  String get workedExamplesTitle;
  String get workedExamplesSearchHint;
  String get workedExamplesEmpty;
  String get workedExamplesCopy;
  String get workedExamplesCopied;
  String get workedExamplesInsert;

  /// Localized title for the worked example with the given [id].
  /// Returns null when the locale doesn't have a translation — caller
  /// falls back to the English string in `WorkedExamples.all`.
  String? workedExampleTitle(String id);

  /// Same as [workedExampleTitle] for the description line.
  String? workedExampleDescription(String id);

  String get workedExamplesCatAll;
  String get workedExamplesCatCalculus;
  String get workedExamplesCatAlgebra;
  String get workedExamplesCatLinearAlgebra;
  String get workedExamplesCatNumberTheory;
  String get workedExamplesCatStatistics;
  String get workedExamplesCatUnits;
  String get settingsWorkedExamples;
  String get settingsWorkedExamplesSubtitle;

  // -- Import data --
  String get importDataTitle;
  String get importDataSubtitle;
  String get importDataWarning;
  String get importDataApply;
  String get importDataEmpty;
  String get importDataNotObject;
  String get importDataApplied;
  String get settingsImportData;
  String get settingsImportDataSubtitle;

  // -- User-defined functions --
  String get userFunctionsTitle;
  String get userFunctionsHelp;
  String get userFunctionsEmpty;
  String get userFunctionsAdd;
  String get userFunctionsEdit;
  String get userFunctionsDelete;
  String get userFunctionsName;
  String get userFunctionsNameHelp;
  String get userFunctionsNameRequired;
  String get userFunctionsNameInvalid;
  String get userFunctionsParam;
  String get userFunctionsBody;
  String get userFunctionsBodyRequired;
  String get settingsUserFunctions;
  String get settingsUserFunctionsSubtitle;

  // -- Onboarding tour (first-launch overlay) --
  String get onboardingSkip;
  String get onboardingNext;
  String get onboardingDone;
  String onboardingPage(int current, int total);
  String get onboardingKeypadTitle;
  String get onboardingKeypadBody;
  String get onboardingHistoryTitle;
  String get onboardingHistoryBody;
  String get onboardingFunctionsTitle;
  String get onboardingFunctionsBody;
  String get onboardingAnalysisTitle;
  String get onboardingAnalysisBody;
  String get settingsReplayTour;
  String get settingsReplayTourSubtitle;

  // -- Step-engine plain-language notes (V2). Returns a localized
  //    sentence for the given key, interpolating `note.params`.
  //    Returns null when the locale doesn't carry a translation for
  //    the key — the caller should fall back to the English `note`
  //    field carried alongside `noteI18n` on each MathStep.
  String? stepNote(StepNote note);

  // -- Help screen --
  String get helpTitle;
  String get helpFunctionsHeading;
  String get helpMatrixHeading;
  String get helpStepsHeading;
  String get helpMatrixBody;
  String get helpStepsBody;

  // -- Constants library --
  String get constantsTitle;
  String get constantsSearchHint;
  String get constantsNoMatches;
  String get constantsAllCategory;
  String get constantsCategoryMathematical;
  String get constantsCategoryPhysical;
  String get constantsCategoryChemistry;
  String get constantsCategoryAstronomy;
  String get constantsCopyValue;
  String constantsCopiedToast(String symbol);
  String get settingsConstants;
  String get settingsConstantsSubtitle;

  // -- Keypad tab labels --
  String get tabNum;
  String get tabTrig;
  String get tabCas;
  String get tabAdvanced;
  String get tabVars;
  String get tabBasic;
  String get tabSymbolic;
}

class EnLocalizations implements AppLocalizations {
  const EnLocalizations();

  @override
  String get navCalculator => 'Calculator';
  @override
  String get navGraphing => 'Graphing';
  @override
  String get navFunctions => 'Functions';
  @override
  String get navAnalysis => 'Analysis';
  @override
  String get navSettings => 'Settings';

  @override
  String get historyHere => 'Calculation history will appear here.';
  @override
  String get historyLabel => 'History:';
  @override
  String get clearButton => 'C';
  @override
  String get clearHistory => 'Clear History';
  @override
  String get clearHistoryConfirm =>
      'Remove all calculation entries from history?';
  @override
  String get searchHistory => 'Search history';
  @override
  String get searchHistoryHint => 'Filter history…';
  @override
  String get historyNoMatches => 'No matching entries.';

  @override
  String graphingTitle(int count) => 'Graphing ($count functions)';
  @override
  String functionAdded(int slot) => 'Function added to Y$slot';
  @override
  String functionRemoved(int slot) => 'Removed Y$slot';
  @override
  String get allSlotsFull =>
      'All function slots are full. Clear a function first.';
  @override
  String get clearAllFunctions => 'Clear All Functions';
  @override
  String get clearAllFunctionsConfirm =>
      'Are you sure you want to clear all graphed functions?';
  @override
  String get cancel => 'Cancel';
  @override
  String get clearAll => 'Clear All';
  @override
  String get zoomIn => 'Zoom In';
  @override
  String get zoomOut => 'Zoom Out';
  @override
  String get resetView => 'Reset View';
  @override
  String get showKeypad => 'Show Keypad';
  @override
  String get hideKeypad => 'Hide Keypad';
  @override
  String get showAnnotations => 'Show roots & extrema';
  @override
  String get hideAnnotations => 'Hide roots & extrema';
  @override
  String get analyzeFunctions => 'Analyze Functions';
  @override
  String get selectFunctionToAnalyze => 'Select Function to Analyze';
  @override
  String get plotButton => 'Plot';
  @override
  String get enterFunctionPrompt => 'Enter a function below to start graphing.';

  @override
  String get analysisModulesTitle => 'Analysis Modules';
  @override
  String get moduleCurveSketching => 'Curve Sketching';
  @override
  String get moduleCurveSketchingSubtitle => 'Full analysis of a function f(x)';
  @override
  String get modulePlanes => 'Planes';
  @override
  String get modulePlanesSubtitle =>
      'Analyze 3D planes in coordinate or parametric form';
  @override
  String get moduleConics => 'Conic Sections';
  @override
  String get moduleConicsSubtitle =>
      'Classify Ax² + Bxy + Cy² + Dx + Ey + F = 0';
  @override
  String get moduleStatistics => 'Statistics';
  @override
  String get moduleStatisticsSubtitle =>
      'Descriptive stats, linear regression, normal & binomial distributions';
  @override
  String get module3DTitle => '3D Graphing';
  @override
  String get module3DSubtitle =>
      'Plot z = f(x, y) as a rotatable wireframe surface';
  @override
  String get module3DFunctionLabel => 'f(x, y)';
  @override
  String get module3DRangeLabel => 'Range';
  @override
  String get module3DResample => 'Re-sample grid';
  @override
  String get module3DTapPlot => 'Enter a function of x and y, then tap Plot.';
  @override
  String get moduleUnitConverterTitle => 'Unit Converter';
  @override
  String get moduleUnitConverterSubtitle =>
      'Convert across length, time, mass, temperature, velocity, angle';
  @override
  String get sectionVariables => 'Variables';
  @override
  String get sectionGraphFunctions => 'Graph Functions';
  @override
  String get sectionMemorySlots => 'Memory Slots';
  @override
  String get funcCtxShowOnGraph => 'Show on graph';
  @override
  String get funcCtxAnalyze => 'Analyze (curve sketching)';
  @override
  String get funcCtxDifferentiate => 'Differentiate';
  @override
  String get funcCtxIntegrate => 'Integrate';
  @override
  String get funcCtxSolve => 'Solve f(x) = 0';
  @override
  String get funcCtxCopy => 'Copy expression';
  @override
  String get funcEditorTitle => 'Function Editor (Y=)';
  @override
  String get funcEditorDone => 'Done';
  @override
  String get funcEditorSelectFirst => 'Please select a function field to edit.';
  @override
  String get funcEditorAnalyzeTooltip => 'Analyze this function';
  @override
  String get funcEditorGraphTooltip => 'Graph this function';
  @override
  String get unitDimLength => 'Length';
  @override
  String get unitDimTime => 'Time';
  @override
  String get unitDimMass => 'Mass';
  @override
  String get unitDimTemperature => 'Temperature';
  @override
  String get unitDimVelocity => 'Velocity';
  @override
  String get unitDimAngle => 'Angle';
  @override
  String get planeAnalysisTitle => 'Plane Analysis';
  @override
  String get planeRepCoordinate => 'Coordinate';
  @override
  String get planeRepParametric => 'Parametric';
  @override
  String get buttonAnalyze => 'Analyze';
  @override
  String get buttonClassify => 'Classify';
  @override
  String get curveAnalysisEnterFunction => 'Enter a function to analyze:';
  @override
  String get curveResultWarnings => 'Warnings';
  @override
  String get curveResultDerivatives => 'Derivatives';
  @override
  String get curveResultKeyPoints => 'Key Points';
  @override
  String get curveResultYIntercept => 'Y-Intercept';
  @override
  String get curveResultRoots => 'Roots';
  @override
  String get curveResultExtrema => 'Extrema (Minima/Maxima)';
  @override
  String get curveResultInflectionPoints => 'Inflection Points';
  @override
  String get curveResultNoExtrema => 'No extrema found.';
  @override
  String get curveResultNoInflection => 'No inflection points found.';
  @override
  String curveAnalysisOfFunction(String function) =>
      'Analysis of f(x) = $function';
  @override
  String curveResultPointPrefix(String point) => 'Point: $point';
  @override
  String get extremumLocalMinimum => 'Local Minimum';
  @override
  String get extremumLocalMaximum => 'Local Maximum';
  @override
  String get extremumCriticalPoint => 'Critical Point';
  @override
  String get extremumInflectionPoint => 'Inflection Point';
  @override
  String get extremumNoCriticalPoints => 'No critical points found';
  @override
  String get extremumConstantConcavity =>
      'Function has constant concavity (f\'\'(x) = 0 everywhere)';
  @override
  String get statisticsTitle => 'Statistics';
  @override
  String get statsTabDescriptive => 'Descriptive';
  @override
  String get statsTabRegression => 'Regression';
  @override
  String get statsTabDistributions => 'Distributions';
  @override
  String get statsTabTests => 'Tests';
  @override
  String get statsDescCount => 'Count';
  @override
  String get statsDescSum => 'Sum';
  @override
  String get statsDescMean => 'Mean';
  @override
  String get statsDescMedian => 'Median';
  @override
  String get statsDescMode => 'Mode';
  @override
  String get statsDescMin => 'Min';
  @override
  String get statsDescMax => 'Max';
  @override
  String get statsDescRange => 'Range';
  @override
  String get statsDescVariance => 'Variance';
  @override
  String get statsDescStddev => 'Std. deviation';
  @override
  String get statsDescQ1 => 'Q1';
  @override
  String get statsDescQ3 => 'Q3';
  @override
  String get statsDescIqr => 'IQR';
  @override
  String get helpGroupProbability => 'Probability';
  @override
  String get helpFnRrefDescription => 'Reduced row echelon form (Gauss-Jordan)';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get settingsNumberFormat => 'Number Display Format';
  @override
  String get settingsNumberFormatAuto => 'Auto (129, 129.5)';
  @override
  String get settingsNumberFormatInteger => 'Integer (129)';
  @override
  String get settingsNumberFormatOneDecimal => 'One Decimal (129.0)';
  @override
  String get settingsNumberFormatTwoDecimal => 'Two Decimals (129.00)';
  @override
  String get settingsLanguage => 'Language';
  @override
  String get settingsLanguageEnglish => 'English';
  @override
  String get settingsLanguageGerman => 'Deutsch';
  @override
  String get settingsLanguageFrench => 'Français';
  @override
  String get settingsLanguageSpanish => 'Español';
  @override
  String get settingsTheme => 'Theme';
  @override
  String get settingsThemeSystem => 'Follow system';
  @override
  String get settingsThemeLight => 'Light';
  @override
  String get settingsThemeDark => 'Dark';
  @override
  String get settingsLayoutTitle => 'Layout';
  @override
  String get settingsLayoutBody =>
      'CrispCalc adapts to window width: bottom nav on phones, a side rail on '
      'tablets and desktop. Above ~760 px the calculator keypad drops its tab '
      'bar and shows every function key at once.';

  @override
  String get aboutTitle => 'About CrispCalc';
  @override
  String get aboutTagline => 'Symbolic CAS calculator powered by SymEngine';
  @override
  String aboutVersion(String version) => 'Version $version';
  @override
  String get aboutServiceProvider => 'Service provider';
  @override
  String get aboutContact => 'Contact';
  @override
  String get aboutPrivacy => 'Privacy';
  @override
  String get aboutPrivacyText =>
      'CrispCalc runs entirely on-device. No calculation, history entry, '
      'or user variable is ever sent to a server. The app does not collect '
      'analytics or contact remote services.';
  @override
  String get aboutDisclaimer => 'Disclaimer';
  @override
  String get aboutDisclaimerText =>
      'CrispCalc is provided "as is", without warranty of any kind. The '
      'symbolic engine may return imprecise results for ill-conditioned '
      'numeric inputs or unsupported symbolic constructs. Verify critical '
      'computations independently.';
  @override
  String get aboutLicense => 'License';
  @override
  String get aboutLicenseText =>
      'CrispCalc is free software, distributed under the GNU Affero '
      'General Public License version 3 or later. This choice mirrors the '
      'copyleft requirements of the bundled GMP/MPFR/MPC/FLINT math '
      'libraries, which are statically linked.';
  @override
  String get aboutOpenSourceLicenses => 'Open-source licenses';
  @override
  String get settingsAbout => 'About CrispCalc';
  @override
  String get matrixDiagnosticsTitle => 'Matrix self-test';
  @override
  String get matrixDiagnosticsSubtitle =>
      'Verify det / inv / transpose / + / * through the native bridge.';
  @override
  String matrixDiagnosticsSummary(int passed, int total) =>
      '$passed of $total checks passed';
  @override
  String get unitConverterTitle => 'Unit converter';
  @override
  String get unitConverterSubtitle =>
      'Length / time / mass / temperature / velocity / angle.';

  @override
  String get selectEquation => 'Select equation or continue typing:';
  @override
  String get continueTyping => 'Continue Typing';
  @override
  String get selectFunction => 'Select function or continue typing:';
  @override
  String get dismissPanel => 'Dismiss this panel';
  @override
  String solveFor(int n) => 'Solve Y$n = 0';
  @override
  String whereY(int n, String func) => 'where Y$n = $func';

  @override
  String get dialogInsert => 'Insert';
  @override
  String get dialogClose => 'Close';
  @override
  String get dialogShowSteps => 'Show steps';
  @override
  String get dialogVariable => 'Variable';
  @override
  String get dialogExpression => 'Expression';
  @override
  String get dialogValue => 'Value';
  @override
  String get dialogFunction => 'Function f(x)';

  @override
  String get integralTitle => 'Integral';
  @override
  String get integralLowerBound => 'Lower bound';
  @override
  String get integralUpperBound => 'Upper bound';
  @override
  String get integralDefinite => 'Definite Integral';
  @override
  String get nthRootTitle => 'Nth Root';
  @override
  String get nthRootBase => 'Base';
  @override
  String get limitTitle => 'Limit';
  @override
  String get limitApproaches => 'Approaches';
  @override
  String get substituteTitle => 'Substitute';
  @override
  String get substituteUseStoredVariable => 'Use a stored variable as value:';

  @override
  String get differentiationStepsTitle => 'Differentiation steps';
  @override
  String differentiationStepsHeader(String variable) =>
      'Differentiating with respect to $variable:';
  @override
  String get solveStepsTitle => 'Solve steps';
  @override
  String get solveStepsEquationLabel => 'Equation or expression';
  @override
  String get solveStepsSolveFor => 'Solve for';
  @override
  String get solveStepsHint => 'e.g. 2x + 3 = 7  or  x^2 - 5x + 6';
  @override
  String solveStepsHeader(String variable) => 'Solving for $variable:';
  @override
  String get integrationStepsTitle => 'Integration steps';
  @override
  String get integrationStepsIntegrandLabel => 'Integrand';
  @override
  String get integrationStepsWrt => 'Integrate with respect to';
  @override
  String get integrationStepsHint => 'e.g. x^2  or  sin(x) + 2x';
  @override
  String integrationStepsHeader(String variable) =>
      'Integrating with respect to $variable:';

  @override
  String get errorSolveFormat =>
      'Error: solve() format is solve(equation, variable)';
  @override
  String get errorInvalidSolve => 'Error: Invalid solve() syntax';
  @override
  String get errorInvalidDiff => 'Error: Invalid d/dx() syntax';
  @override
  String get errorInvalidFactor => 'Error: Invalid factor() syntax';
  @override
  String get errorInvalidExpand => 'Error: Invalid expand() syntax';
  @override
  String get errorInvalidSimplify => 'Error: Invalid simplify() syntax';
  @override
  String get errorGcdArgs => 'Error: gcd() requires exactly 2 arguments';
  @override
  String get errorInvalidGcd => 'Error: Invalid gcd() syntax';
  @override
  String get errorLcmArgs => 'Error: lcm() requires exactly 2 arguments';
  @override
  String get errorInvalidLcm => 'Error: Invalid lcm() syntax';

  @override
  String get errorParse =>
      'Couldn\'t understand the expression. Check for unmatched parentheses, typos, or missing operators.';
  @override
  String get errorNativeRequired =>
      'This operation needs the native math library, which isn\'t loaded on this platform.';
  @override
  String get errorIntegrateNotImplemented =>
      'Symbolic integration isn\'t available in this build. Use the ∫ button with bounds for a numerical (definite) result.';
  @override
  String get errorMatrixLiteral =>
      'The matrix literal looks malformed. Use the format [a,b; c,d] or build it with the matrix editor.';
  @override
  String get errorInternalMatrixDisposed =>
      'Internal matrix reference is no longer valid. Please run the operation again.';
  @override
  String errorInvalidSyntax(String op) =>
      'The arguments to $op() weren\'t in the expected shape. Check the example in the help / About screen.';

  @override
  String get exportDataTitle => 'Export data';
  @override
  String get exportDataSubtitle =>
      'JSON below contains everything CrispCalc has stored on this device — history, variables, graph functions, parameters, settings. Copy it to a notes app or cloud doc before reinstalling.';
  @override
  String get exportDataCopy => 'Copy to clipboard';
  @override
  String get exportDataCopied => 'Copied to clipboard';
  @override
  String get historyEntryCopyResult => 'Copy result';
  @override
  String get historyEntryCopyLatex => 'Copy as LaTeX';
  @override
  String get historyEntryCopyLatexSubtitle =>
      'Paste into a Word/Notion/Markdown editor for typeset math';
  @override
  String get historyEntryReuse => 'Reuse expression';
  @override
  String get historyEntryCopied => 'Copied';

  @override
  String get settingsExportData => 'Export data';
  @override
  String get settingsExportDataSubtitle =>
      'Copy everything stored on this device (history, variables, settings).';
  @override
  String get settingsHelp => 'Help & function reference';
  @override
  String get settingsHelpSubtitle =>
      'Supported functions, matrix syntax, and step-by-step triggers.';

  @override
  String get settingsExactIntegerMode => 'Exact integer mode';
  @override
  String get settingsExactIntegerModeSubtitle =>
      'Show full digit string for arbitrary-precision integer results '
      '(e.g. 100! = 158 digits). Off: round to double precision.';
  @override
  String exactIntegerBadge(int digits) => 'Exact integer · $digits digits';
  @override
  String get exactIntegerTapToCopy => 'Tap to copy';

  @override
  String get calculating => 'Calculating…';

  @override
  String get moduleSudokuTitle => 'Sudoku';
  @override
  String get moduleSudokuSubtitle =>
      'Solve 4×4 and 9×9 puzzles, watch the search step-by-step.';
  @override
  String get sudokuSolveButton => 'Solve';
  @override
  String get sudokuClearCell => 'Clear';
  @override
  String get sudokuPresetLabelChooser => 'Puzzle';
  @override
  String get sudokuPresetCustom => 'Custom';
  @override
  String sudokuPresetLabel(String id) {
    switch (id) {
      case 'small4x4Easy':
        return '4×4 easy';
      case 'small4x4Medium':
        return '4×4 medium';
      case 'small4x4Hard':
        return '4×4 hard';
      case 'medium6x6':
        return '6×6 medium';
      case 'standard9x9Easy':
        return '9×9 easy';
      case 'standard9x9Medium':
        return '9×9 medium';
      case 'standard9x9Hard':
        return '9×9 hard (AI Escargot)';
      case 'standard9x9XEasy':
        return '9×9 Sudoku-X easy';
    }
    return id;
  }

  @override
  String get sudokuVisualizerHeader => 'Search visualizer';
  @override
  String get sudokuPlay => 'Play';
  @override
  String get sudokuPause => 'Pause';
  @override
  String get sudokuRestart => 'Restart';
  @override
  String get sudokuSpeedSlow => 'Slow';
  @override
  String get sudokuSpeedMed => 'Med';
  @override
  String get sudokuSpeedFast => 'Fast';
  @override
  String get sudokuGenerateButton => 'Generate';
  @override
  String get sudokuDifficultyEasy => 'Easy';
  @override
  String get sudokuDifficultyMedium => 'Medium';
  @override
  String get sudokuDifficultyHard => 'Hard';
  @override
  String get sudokuVariantRegular => 'Regular';
  @override
  String get sudokuVariantX => 'Sudoku-X';

  @override
  String get moduleConstraintsTitle => 'Constraint problems';
  @override
  String get moduleConstraintsSubtitle =>
      'Diophantine equations and cryptarithms — find integer '
      'solutions and digit assignments.';
  @override
  String get constraintsTabDiophantine => 'Diophantine';
  @override
  String get constraintsTabCryptarithm => 'Cryptarithm';
  @override
  String get constraintsDiophantineIntro =>
      'Declare bounded integer variables, list the constraints they '
      'must satisfy, and the solver enumerates all integer solutions '
      '(capped at 100).';
  @override
  String get constraintsCryptarithmIntro =>
      'Enter a puzzle of the form `WORD1 + WORD2 = WORD3` (or `−` '
      'instead of `+`). Each letter is a digit 0..9; leading digits '
      'are non-zero; all letters carry distinct digits.';
  @override
  String get constraintsVariablesLabel => 'Variables';
  @override
  String get constraintsVariablesHint =>
      'One per line, format: name in min..max';
  @override
  String get constraintsConstraintsLabel => 'Constraints';
  @override
  String get constraintsConstraintsHint =>
      'One per line. Comparisons, arithmetic, in/not-in sets all '
      'supported.';
  @override
  String get constraintsCryptarithmInputLabel => 'Puzzle';
  @override
  String get constraintsSolveButton => 'Solve';
  @override
  String get constraintsBadVarLine =>
      'Could not parse variable line. Expected `name in min..max`';
  @override
  String get constraintsNoSolutions => 'No solutions.';
  @override
  String get constraintsCryptarithmFoundHeader => 'Digit assignment';
  @override
  String constraintsSolutionsHeader(int n) =>
      n == 1 ? '1 solution' : '$n solutions';
  @override
  String constraintsTruncatedHeader(int n) =>
      'Showing first $n solutions (more exist)';
  @override
  String get constraintsCopyResult => 'Copy solutions';
  @override
  String get constraintsCopiedToast => 'Copied to clipboard.';

  @override
  String get clearSearchTooltip => 'Clear search';
  @override
  String get clearFunctionSlotTooltip => 'Clear function slot';
  @override
  String get deleteMemorySlotTooltip => 'Delete memory slot';

  @override
  String get workedExamplesTitle => 'Worked examples';
  @override
  String get workedExamplesSearchHint => 'Search examples…';
  @override
  String get workedExamplesEmpty => 'No examples match this filter.';
  @override
  String get workedExamplesCopy => 'Copy expression';
  @override
  String get workedExamplesCopied =>
      'Copied to clipboard. Paste into the calculator to try it.';
  @override
  String get workedExamplesInsert => 'Insert into calculator';
  @override
  String get workedExamplesCatAll => 'All';
  @override
  String get workedExamplesCatCalculus => 'Calculus';
  @override
  String get workedExamplesCatAlgebra => 'Algebra';
  @override
  String get workedExamplesCatLinearAlgebra => 'Linear algebra';
  @override
  String get workedExamplesCatNumberTheory => 'Number theory';
  @override
  String get workedExamplesCatStatistics => 'Statistics';
  @override
  String get workedExamplesCatUnits => 'Units';
  @override
  String? workedExampleTitle(String id) {
    // The English catalog has the canonical titles; the
    // fallback-to-catalog path in the dialog uses these directly.
    // Returning null for every id keeps EN behavior identical to V1.
    return null;
  }

  @override
  String? workedExampleDescription(String id) => null;
  @override
  String get settingsWorkedExamples => 'Worked examples library';
  @override
  String get settingsWorkedExamplesSubtitle =>
      'Browse and copy ready-to-paste calculator expressions covering '
      'the major problem types.';

  @override
  String get importDataTitle => 'Import data';
  @override
  String get importDataSubtitle =>
      'Paste a JSON payload from a previous Export data run to restore '
      'your history, variables, functions, and settings.';
  @override
  String get importDataWarning =>
      'This overwrites your current history, variables, and graph '
      'functions. There is no undo — copy your current state first if '
      'you want to keep it.';
  @override
  String get importDataApply => 'Apply';
  @override
  String get importDataEmpty => 'Paste a JSON payload to import.';
  @override
  String get importDataNotObject =>
      'The payload must be a JSON object (starts with `{`).';
  @override
  String get importDataApplied => 'Imported';
  @override
  String get settingsImportData => 'Import data';
  @override
  String get settingsImportDataSubtitle =>
      'Paste a JSON payload from a previous export to restore.';

  @override
  String get userFunctionsTitle => 'User-defined functions';
  @override
  String get userFunctionsHelp =>
      'Define a function once, call it from any expression. e.g. '
      '`f(x) = x^2 + 1`, then `f(3) + 1` evaluates to 11. Composition '
      '`g(f(x))` works as long as both are defined.';
  @override
  String get userFunctionsEmpty =>
      'No user-defined functions yet. Tap Add to create your first.';
  @override
  String get userFunctionsAdd => 'Add';
  @override
  String get userFunctionsEdit => 'Edit';
  @override
  String get userFunctionsDelete => 'Delete';
  @override
  String get userFunctionsName => 'Name';
  @override
  String get userFunctionsNameHelp =>
      'Single lowercase letter (a..z) that won\'t collide with built-ins.';
  @override
  String get userFunctionsNameRequired => 'Required';
  @override
  String get userFunctionsNameInvalid =>
      'Must be a single lowercase letter (a..z).';
  @override
  String get userFunctionsParam => 'Parameter';
  @override
  String get userFunctionsBody => 'Body';
  @override
  String get userFunctionsBodyRequired => 'Function body required';
  @override
  String get settingsUserFunctions => 'User-defined functions';
  @override
  String get settingsUserFunctionsSubtitle =>
      'Define named functions like f(x) = x^2 + 1 and reuse them in any '
      'expression.';

  @override
  String get onboardingSkip => 'Skip';
  @override
  String get onboardingNext => 'Next';
  @override
  String get onboardingDone => 'Got it';
  @override
  String onboardingPage(int current, int total) => '$current / $total';
  @override
  String get onboardingKeypadTitle => 'Tabbed keypad';
  @override
  String get onboardingKeypadBody =>
      'Switch between Num, Trig, CAS, and Advanced tabs to find the '
      'operation you need. On larger windows every key fits on one '
      'screen — no tabs needed.';
  @override
  String get onboardingHistoryTitle => 'Scroll your history';
  @override
  String get onboardingHistoryBody =>
      'Every calculation is saved. Scroll up to revisit, long-press to '
      'copy or reuse, tap the search icon to filter.';
  @override
  String get onboardingFunctionsTitle => 'Pick a function';
  @override
  String get onboardingFunctionsBody =>
      'The ∫⌄, d/dx⌄, and solve⌄ buttons open step-by-step pickers '
      'that walk you through the answer one rule at a time.';
  @override
  String get onboardingAnalysisTitle => 'Analysis hub';
  @override
  String get onboardingAnalysisBody =>
      'Curve sketching, planes, conics, 3D plotting, statistics, and '
      'the unit converter all live in the Analysis tab.';
  @override
  String get settingsReplayTour => 'Replay onboarding tour';
  @override
  String get settingsReplayTourSubtitle =>
      'Show the first-launch tour again next time you open the app.';

  @override
  String get helpTitle => 'Help';
  @override
  String get helpFunctionsHeading => 'Supported functions';
  @override
  String get helpMatrixHeading => 'Matrix syntax';
  @override
  String get helpStepsHeading => 'Step-by-step solutions';
  @override
  String get helpMatrixBody =>
      'Type matrices with rows separated by `;` and cells by `,`:\n\n    [1, 2; 3, 4]\n\nThe calculator converts this to `Matrix([[1, 2], [3, 4]])` internally. Operations: det, inv, transpose, rref, +, -, *.';
  @override
  String get helpStepsBody =>
      'Three keypad buttons in the CAS tab open step-by-step traces:\n\n  • d/dx⌄ for differentiation steps\n  • solve⌄ for equation solving\n  • ∫⌄ for indefinite integration\n\nEach shows the rule applied at every step plus a final answer.';

  @override
  String get constantsTitle => 'Constants reference';
  @override
  String get constantsSearchHint => 'Search by symbol, name, or unit…';
  @override
  String get constantsNoMatches => 'No constants match this filter.';
  @override
  String get constantsAllCategory => 'All';
  @override
  String get constantsCategoryMathematical => 'Mathematical';
  @override
  String get constantsCategoryPhysical => 'Physical';
  @override
  String get constantsCategoryChemistry => 'Chemistry';
  @override
  String get constantsCategoryAstronomy => 'Astronomy';
  @override
  String get constantsCopyValue => 'Copy value';
  @override
  String constantsCopiedToast(String symbol) => 'Copied $symbol to clipboard';
  @override
  String get settingsConstants => 'Constants reference';
  @override
  String get settingsConstantsSubtitle =>
      'Physical, mathematical, chemistry, and astronomy constants.';

  @override
  String get tabNum => 'Num';
  @override
  String get tabTrig => 'Trig';
  @override
  String get tabCas => 'CAS';
  @override
  String get tabAdvanced => 'Advanced';
  @override
  String get tabVars => 'Variables';
  @override
  String get tabBasic => 'Basic';
  @override
  String get tabSymbolic => 'Symbolic';

  @override
  String? stepNote(StepNote note) {
    final p = note.params;
    switch (note.key) {
      case 'startEquation':
        return 'Start with the equation as given.';
      case 'moveRightSideOver':
        return 'Subtracting the right side from both sides puts the '
            'equation in standard form `expression = 0`, which lets us '
            'apply the linear or quadratic solver.';
      case 'noEqualsSign':
        return 'No `=` in input; treating as ${p['body']} = 0.';
      case 'doesNotDependOn':
        return 'The equation does not depend on ${p['var']}.';
      case 'solveFallthroughSymbolic':
        return 'Not a standard linear or quadratic form — handing off '
            'to the symbolic solver for the answer.';
      case 'linearIdentifyCoefs':
        return 'Pick off the leading coefficient and the constant term — '
            'this is a linear equation.';
      case 'moveConstant':
        return 'Move the constant to the other side.';
      case 'divideByCoef':
        return 'Divide both sides by the leading coefficient to isolate '
            '${p['var']}.';
      case 'quadraticIdentifyCoefs':
        return 'Read the three coefficients off the polynomial. We pull '
            'a from the second derivative ÷ 2, b from the first derivative '
            'at ${p['var']} = 0, and c from the polynomial at ${p['var']} = 0.';
      case 'discriminant':
        return 'The discriminant tells us how many real roots: positive → '
            'two distinct real roots; zero → one double root; negative → '
            'two complex conjugate roots.';
      case 'quadFormulaApply':
        return 'Plug a, b, and Δ into the quadratic formula. The `±` gives '
            'both roots in one step.';
      case 'integralPullMinusOut':
        return 'Pull the leading minus sign out of the integral; the rest '
            'is just ∫f.';
      case 'exprDoesNotDependOn':
        return '${p['expr']} does not depend on ${p['var']}.';
      case 'integralIdentityPower1':
        return 'The power rule for n=1: bump the exponent up to 2 and '
            'divide by the new exponent.';
      case 'integralLinearity':
        return 'Integration is linear: the integral of a sum is the sum of '
            'the integrals.';
      case 'integralPullConstantOut':
        return 'Pull `${p['const']}` outside the integral — constants '
            'multiply through.';
      case 'integralReciprocalLog':
        return 'The integral of 1/${p['var']} is the natural log of its '
            'absolute value.';
      case 'integralPowerRule':
        return 'Bump the exponent up by 1 and divide by the new exponent. '
            'Works for any constant n ≠ −1.';
      case 'uSubLinear':
        return 'Let u = ${p['u']}; then du = (${p['slope']})·d${p['var']}.';
      case 'integralStandardAntideriv':
        return 'Use the standard antiderivative for ${p['fn']}.';
      case 'uSubLinearFn':
        return 'Let u = ${p['u']}; then du = (${p['slope']})·d${p['var']}. '
            'The antiderivative of ${p['fn']} is the standard form, '
            'evaluated at u and divided by the slope.';
      case 'ibpLnX':
        final v = p['var']!;
        return 'Let u = ln($v), dv = d$v. Then du = (1/$v)·d$v and v = $v, '
            'so ∫u·dv = u·v − ∫v·du = $v·ln($v) − ∫1 d$v.';
      case 'ibpXTimesF':
        return 'Let u = ${p['var']} (so du = d${p['var']}) and '
            'dv = ${p['right']}·d${p['var']}, giving v = ${p['v']}.';
      case 'ibpRepeated':
        return 'Let u = ${p['u']} and dv = ${p['right']}·d${p['var']}. '
            'Then du = ${p['n']}·… (one lower power of ${p['var']}) and '
            'v = ${p['v']}, so the new integrand drops a power of '
            '${p['var']} — recursing.';
      case 'uSubNonlinear':
        return 'Let u = ${p['u']}; then du = (${p['du']})·d${p['var']}. '
            'The integrand has the form f(u)·du, so substitution turns '
            'it into ∫f(u) du = standard antiderivative of ${p['fn']} '
            'evaluated at u'
            '${p['ratio'] == '1' ? '.' : ', times the constant factor ${p['ratio']}.'}';
      case 'integralLogDerivative':
        return 'The numerator is (${p['ratio']})·(d/d${p['var']}[${p['den']}]), '
            'so the integral is ${p['ratio']}·ln|${p['den']}|.';
      case 'partialFractions':
        return 'The denominator has distinct integer roots ${p['roots']}. '
            'Cover-up gives A_i = P(r_i) / Q\'(r_i) for each root.';
      case 'partialFractionsIntegrate':
        return 'Each `A/(x-r)` piece integrates to A·ln|x-r|.';
      case 'trigArctanForm':
        return 'Match a² = ${p['aSq']}, so a = ${p['a']}. The standard '
            'form gives (1/a)·arctan(${p['var']}/a).';
      case 'trigArcsinForm':
        return 'Match a² = ${p['aSq']}, so a = ${p['a']}. The standard '
            'form gives arcsin(${p['var']}/a).';
      case 'integralFallthroughSymbolic':
        return 'No standard textbook rule matched this shape — handing off '
            'to the symbolic integrator.';
      case 'diffIdentity':
        return 'Differentiating ${p['var']} with respect to itself is 1.';
      case 'diffSumDifference':
        return 'Differentiate each term on its own; the derivative '
            'distributes across `+` and `−`.';
      case 'diffQuotient':
        return 'For a quotient, the numerator gets `f′g − fg′` and the '
            'denominator gets squared.';
      case 'diffProduct':
        return 'For a product, differentiate each factor and add the pieces '
            '— `(fg)′ = f′g + fg′`.';
      case 'diffPowerSimple':
        return 'Bring the exponent down as a coefficient and reduce the '
            'exponent by 1.';
      case 'diffPowerChain':
        return 'Bring the exponent down and reduce it by 1, then multiply '
            'by the derivative of the inner base — that '
            '`d/d${p['var']}[${p['base']}]` factor is the chain rule.';
      case 'diffExponential':
        return 'When the variable is in the exponent, the derivative is the '
            'same expression times `ln(base)` times the derivative of the '
            'exponent.';
      case 'diffStandardSimple':
        return 'Apply the standard derivative for ${p['fn']}.';
      case 'diffStandardChain':
        return 'The argument depends on ${p['var']}, so multiply by its '
            'derivative (chain rule).';
      case 'diffFallthrough':
        return 'No higher-level rule pattern recognized for this shape.';
    }
    return null;
  }
}

class DeLocalizations implements AppLocalizations {
  const DeLocalizations();

  @override
  String get navCalculator => 'Rechner';
  @override
  String get navGraphing => 'Graphen';
  @override
  String get navFunctions => 'Funktionen';
  @override
  String get navAnalysis => 'Analyse';
  @override
  String get navSettings => 'Einstellungen';

  @override
  String get historyHere => 'Hier erscheint der Berechnungsverlauf.';
  @override
  String get historyLabel => 'Verlauf:';
  @override
  String get clearButton => 'C';
  @override
  String get clearHistory => 'Verlauf löschen';
  @override
  String get clearHistoryConfirm =>
      'Alle Einträge aus dem Berechnungsverlauf entfernen?';
  @override
  String get searchHistory => 'Verlauf durchsuchen';
  @override
  String get searchHistoryHint => 'Verlauf filtern…';
  @override
  String get historyNoMatches => 'Keine passenden Einträge.';

  @override
  String graphingTitle(int count) => 'Graphen ($count Funktionen)';
  @override
  String functionAdded(int slot) => 'Funktion zu Y$slot hinzugefügt';
  @override
  String functionRemoved(int slot) => 'Y$slot entfernt';
  @override
  String get allSlotsFull =>
      'Alle Funktionsplätze sind belegt. Bitte erst eine Funktion löschen.';
  @override
  String get clearAllFunctions => 'Alle Funktionen löschen';
  @override
  String get clearAllFunctionsConfirm =>
      'Sind Sie sicher, dass Sie alle gezeichneten Funktionen löschen möchten?';
  @override
  String get cancel => 'Abbrechen';
  @override
  String get clearAll => 'Alle löschen';
  @override
  String get zoomIn => 'Vergrößern';
  @override
  String get zoomOut => 'Verkleinern';
  @override
  String get resetView => 'Ansicht zurücksetzen';
  @override
  String get showKeypad => 'Tastatur einblenden';
  @override
  String get hideKeypad => 'Tastatur ausblenden';
  @override
  String get showAnnotations => 'Nullstellen & Extrema einblenden';
  @override
  String get hideAnnotations => 'Nullstellen & Extrema ausblenden';
  @override
  String get analyzeFunctions => 'Funktionen analysieren';
  @override
  String get selectFunctionToAnalyze => 'Zu analysierende Funktion wählen';
  @override
  String get plotButton => 'Zeichnen';
  @override
  String get enterFunctionPrompt =>
      'Funktion unten eingeben, um sie zu zeichnen.';

  @override
  String get analysisModulesTitle => 'Analyse-Module';
  @override
  String get moduleCurveSketching => 'Kurvendiskussion';
  @override
  String get moduleCurveSketchingSubtitle =>
      'Vollständige Analyse einer Funktion f(x)';
  @override
  String get modulePlanes => 'Ebenen';
  @override
  String get modulePlanesSubtitle =>
      '3D-Ebenen in Koordinaten- oder Parameterform analysieren';
  @override
  String get moduleConics => 'Kegelschnitte';
  @override
  String get moduleConicsSubtitle =>
      'Klassifiziere Ax² + Bxy + Cy² + Dx + Ey + F = 0';
  @override
  String get moduleStatistics => 'Statistik';
  @override
  String get moduleStatisticsSubtitle =>
      'Beschreibende Statistik, lineare Regression, Normal- & Binomialverteilung';
  @override
  String get module3DTitle => '3D-Grafik';
  @override
  String get module3DSubtitle =>
      'Zeichne z = f(x, y) als drehbare Drahtgitter-Fläche';
  @override
  String get module3DFunctionLabel => 'f(x, y)';
  @override
  String get module3DRangeLabel => 'Bereich';
  @override
  String get module3DResample => 'Gitter neu abtasten';
  @override
  String get module3DTapPlot =>
      'Funktion in x und y eingeben, dann auf Zeichnen tippen.';
  @override
  String get moduleUnitConverterTitle => 'Einheitenumrechner';
  @override
  String get moduleUnitConverterSubtitle =>
      'Umrechnung zwischen Längen, Zeit, Masse, Temperatur, Geschwindigkeit, Winkel';
  @override
  String get sectionVariables => 'Variablen';
  @override
  String get sectionGraphFunctions => 'Graphfunktionen';
  @override
  String get sectionMemorySlots => 'Speicherplätze';
  @override
  String get funcCtxShowOnGraph => 'Im Graphen anzeigen';
  @override
  String get funcCtxAnalyze => 'Kurvendiskussion';
  @override
  String get funcCtxDifferentiate => 'Ableiten';
  @override
  String get funcCtxIntegrate => 'Integrieren';
  @override
  String get funcCtxSolve => 'Lösen f(x) = 0';
  @override
  String get funcCtxCopy => 'Ausdruck kopieren';
  @override
  String get funcEditorTitle => 'Funktionseditor (Y=)';
  @override
  String get funcEditorDone => 'Fertig';
  @override
  String get funcEditorSelectFirst =>
      'Bitte ein Funktionsfeld zum Bearbeiten auswählen.';
  @override
  String get funcEditorAnalyzeTooltip => 'Diese Funktion analysieren';
  @override
  String get funcEditorGraphTooltip => 'Diese Funktion zeichnen';
  @override
  String get unitDimLength => 'Länge';
  @override
  String get unitDimTime => 'Zeit';
  @override
  String get unitDimMass => 'Masse';
  @override
  String get unitDimTemperature => 'Temperatur';
  @override
  String get unitDimVelocity => 'Geschwindigkeit';
  @override
  String get unitDimAngle => 'Winkel';
  @override
  String get planeAnalysisTitle => 'Ebenenanalyse';
  @override
  String get planeRepCoordinate => 'Koordinaten';
  @override
  String get planeRepParametric => 'Parametrisch';
  @override
  String get buttonAnalyze => 'Analysieren';
  @override
  String get buttonClassify => 'Klassifizieren';
  @override
  String get curveAnalysisEnterFunction =>
      'Zu analysierende Funktion eingeben:';
  @override
  String get curveResultWarnings => 'Warnungen';
  @override
  String get curveResultDerivatives => 'Ableitungen';
  @override
  String get curveResultKeyPoints => 'Wichtige Punkte';
  @override
  String get curveResultYIntercept => 'Y-Achsenabschnitt';
  @override
  String get curveResultRoots => 'Nullstellen';
  @override
  String get curveResultExtrema => 'Extrema (Minima/Maxima)';
  @override
  String get curveResultInflectionPoints => 'Wendepunkte';
  @override
  String get curveResultNoExtrema => 'Keine Extrema gefunden.';
  @override
  String get curveResultNoInflection => 'Keine Wendepunkte gefunden.';
  @override
  String curveAnalysisOfFunction(String function) =>
      'Analyse von f(x) = $function';
  @override
  String curveResultPointPrefix(String point) => 'Punkt: $point';
  @override
  String get extremumLocalMinimum => 'Lokales Minimum';
  @override
  String get extremumLocalMaximum => 'Lokales Maximum';
  @override
  String get extremumCriticalPoint => 'Kritischer Punkt';
  @override
  String get extremumInflectionPoint => 'Wendepunkt';
  @override
  String get extremumNoCriticalPoints => 'Keine kritischen Punkte gefunden';
  @override
  String get extremumConstantConcavity =>
      'Funktion hat konstante Krümmung (f\'\'(x) = 0 überall)';
  @override
  String get statisticsTitle => 'Statistik';
  @override
  String get statsTabDescriptive => 'Deskriptiv';
  @override
  String get statsTabRegression => 'Regression';
  @override
  String get statsTabDistributions => 'Verteilungen';
  @override
  String get statsTabTests => 'Tests';
  @override
  String get statsDescCount => 'Anzahl';
  @override
  String get statsDescSum => 'Summe';
  @override
  String get statsDescMean => 'Mittelwert';
  @override
  String get statsDescMedian => 'Median';
  @override
  String get statsDescMode => 'Modus';
  @override
  String get statsDescMin => 'Min';
  @override
  String get statsDescMax => 'Max';
  @override
  String get statsDescRange => 'Spannweite';
  @override
  String get statsDescVariance => 'Varianz';
  @override
  String get statsDescStddev => 'Standardabweichung';
  @override
  String get statsDescQ1 => 'Q1';
  @override
  String get statsDescQ3 => 'Q3';
  @override
  String get statsDescIqr => 'IQR';
  @override
  String get helpGroupProbability => 'Wahrscheinlichkeit';
  @override
  String get helpFnRrefDescription => 'Reduzierte Stufenform (Gauß-Jordan)';

  @override
  String get settingsTitle => 'Einstellungen';
  @override
  String get settingsNumberFormat => 'Zahlendarstellung';
  @override
  String get settingsNumberFormatAuto => 'Auto (129, 129,5)';
  @override
  String get settingsNumberFormatInteger => 'Ganzzahl (129)';
  @override
  String get settingsNumberFormatOneDecimal => 'Eine Nachkommastelle (129,0)';
  @override
  String get settingsNumberFormatTwoDecimal => 'Zwei Nachkommastellen (129,00)';
  @override
  String get settingsLanguage => 'Sprache';
  @override
  String get settingsLanguageEnglish => 'English';
  @override
  String get settingsLanguageGerman => 'Deutsch';
  @override
  String get settingsLanguageFrench => 'Français';
  @override
  String get settingsLanguageSpanish => 'Español';
  @override
  String get settingsTheme => 'Erscheinungsbild';
  @override
  String get settingsThemeSystem => 'Systemeinstellung';
  @override
  String get settingsThemeLight => 'Hell';
  @override
  String get settingsThemeDark => 'Dunkel';
  @override
  String get settingsLayoutTitle => 'Layout';
  @override
  String get settingsLayoutBody =>
      'CrispCalc passt sich an die Fensterbreite an: untere Navigation auf '
      'Smartphones, Seitenleiste auf Tablets und Desktop. Ab ~760 px zeigt die '
      'Tastatur alle Funktionstasten gleichzeitig (ohne Reiter).';

  @override
  String get aboutTitle => 'Über CrispCalc';
  @override
  String get aboutTagline => 'Symbolischer CAS-Rechner basierend auf SymEngine';
  @override
  String aboutVersion(String version) => 'Version $version';
  @override
  String get aboutServiceProvider => 'Anbieter';
  @override
  String get aboutContact => 'Kontakt';
  @override
  String get aboutPrivacy => 'Datenschutz';
  @override
  String get aboutPrivacyText =>
      'CrispCalc läuft vollständig auf dem Gerät. Keine Berechnung, kein '
      'Verlaufseintrag und keine benutzerdefinierte Variable wird je an '
      'einen Server übertragen. Die App erhebt keine Analysedaten und '
      'kontaktiert keine entfernten Dienste.';
  @override
  String get aboutDisclaimer => 'Haftungsausschluss';
  @override
  String get aboutDisclaimerText =>
      'CrispCalc wird "wie besehen" bereitgestellt, ohne jegliche '
      'Gewährleistung. Die symbolische Engine kann bei schlecht '
      'konditionierten numerischen Eingaben oder nicht unterstützten '
      'symbolischen Ausdrücken ungenaue Ergebnisse liefern. Kritische '
      'Berechnungen unabhängig überprüfen.';
  @override
  String get aboutLicense => 'Lizenz';
  @override
  String get aboutLicenseText =>
      'CrispCalc ist freie Software, veröffentlicht unter der GNU Affero '
      'General Public License Version 3 oder neuer. Diese Wahl folgt aus '
      'den Copyleft-Anforderungen der mitgelieferten GMP-/MPFR-/MPC-/FLINT-'
      'Bibliotheken, die statisch eingebunden sind.';
  @override
  String get aboutOpenSourceLicenses => 'Open-Source-Lizenzen';
  @override
  String get settingsAbout => 'Über CrispCalc';
  @override
  String get matrixDiagnosticsTitle => 'Matrix-Selbsttest';
  @override
  String get matrixDiagnosticsSubtitle =>
      'det / inv / transpose / + / * über die native Bridge prüfen.';
  @override
  String matrixDiagnosticsSummary(int passed, int total) =>
      '$passed von $total Prüfungen bestanden';
  @override
  String get unitConverterTitle => 'Einheitenumrechner';
  @override
  String get unitConverterSubtitle =>
      'Länge / Zeit / Masse / Temperatur / Geschwindigkeit / Winkel.';

  @override
  String get selectEquation => 'Gleichung auswählen oder weiter tippen:';
  @override
  String get continueTyping => 'Weiter tippen';
  @override
  String get selectFunction => 'Funktion auswählen oder weiter tippen:';
  @override
  String get dismissPanel => 'Dieses Panel schließen';
  @override
  String solveFor(int n) => 'Löse Y$n = 0';
  @override
  String whereY(int n, String func) => 'wobei Y$n = $func';

  @override
  String get dialogInsert => 'Einfügen';
  @override
  String get dialogClose => 'Schließen';
  @override
  String get dialogShowSteps => 'Schritte anzeigen';
  @override
  String get dialogVariable => 'Variable';
  @override
  String get dialogExpression => 'Ausdruck';
  @override
  String get dialogValue => 'Wert';
  @override
  String get dialogFunction => 'Funktion f(x)';

  @override
  String get integralTitle => 'Integral';
  @override
  String get integralLowerBound => 'Untere Grenze';
  @override
  String get integralUpperBound => 'Obere Grenze';
  @override
  String get integralDefinite => 'Bestimmtes Integral';
  @override
  String get nthRootTitle => 'n-te Wurzel';
  @override
  String get nthRootBase => 'Basis';
  @override
  String get limitTitle => 'Grenzwert';
  @override
  String get limitApproaches => 'strebt gegen';
  @override
  String get substituteTitle => 'Einsetzen';
  @override
  String get substituteUseStoredVariable =>
      'Gespeicherte Variable als Wert verwenden:';

  @override
  String get differentiationStepsTitle => 'Ableitungsschritte';
  @override
  String differentiationStepsHeader(String variable) =>
      'Ableiten nach $variable:';
  @override
  String get solveStepsTitle => 'Lösungsschritte';
  @override
  String get solveStepsEquationLabel => 'Gleichung oder Ausdruck';
  @override
  String get solveStepsSolveFor => 'Lösen nach';
  @override
  String get solveStepsHint => 'z. B. 2x + 3 = 7  oder  x^2 - 5x + 6';
  @override
  String solveStepsHeader(String variable) => 'Lösen nach $variable:';
  @override
  String get integrationStepsTitle => 'Integrationsschritte';
  @override
  String get integrationStepsIntegrandLabel => 'Integrand';
  @override
  String get integrationStepsWrt => 'Integrieren nach';
  @override
  String get integrationStepsHint => 'z. B. x^2  oder  sin(x) + 2x';
  @override
  String integrationStepsHeader(String variable) =>
      'Integrieren nach $variable:';

  @override
  String get errorSolveFormat =>
      'Fehler: solve()-Format ist solve(Gleichung, Variable)';
  @override
  String get errorInvalidSolve => 'Fehler: Ungültige solve()-Syntax';
  @override
  String get errorInvalidDiff => 'Fehler: Ungültige d/dx()-Syntax';
  @override
  String get errorInvalidFactor => 'Fehler: Ungültige factor()-Syntax';
  @override
  String get errorInvalidExpand => 'Fehler: Ungültige expand()-Syntax';
  @override
  String get errorInvalidSimplify => 'Fehler: Ungültige simplify()-Syntax';
  @override
  String get errorGcdArgs => 'Fehler: gcd() benötigt genau 2 Argumente';
  @override
  String get errorInvalidGcd => 'Fehler: Ungültige gcd()-Syntax';
  @override
  String get errorLcmArgs => 'Fehler: lcm() benötigt genau 2 Argumente';
  @override
  String get errorInvalidLcm => 'Fehler: Ungültige lcm()-Syntax';

  @override
  String get errorParse =>
      'Der Ausdruck konnte nicht verstanden werden. Bitte auf unausgewogene Klammern, Tippfehler oder fehlende Operatoren prüfen.';
  @override
  String get errorNativeRequired =>
      'Diese Operation benötigt die native Mathematik-Bibliothek, die auf dieser Plattform nicht geladen ist.';
  @override
  String get errorIntegrateNotImplemented =>
      'Symbolische Integration ist in diesem Build nicht verfügbar. Bitte ∫ mit Integrationsgrenzen verwenden für ein numerisches (bestimmtes) Ergebnis.';
  @override
  String get errorMatrixLiteral =>
      'Das Matrix-Literal ist fehlerhaft. Bitte Format [a,b; c,d] verwenden oder den Matrix-Editor öffnen.';
  @override
  String get errorInternalMatrixDisposed =>
      'Interne Matrix-Referenz ist nicht mehr gültig. Bitte die Operation erneut ausführen.';
  @override
  String errorInvalidSyntax(String op) =>
      'Die Argumente an $op() hatten nicht die erwartete Form. Bitte das Beispiel in Hilfe / Über prüfen.';

  @override
  String get exportDataTitle => 'Daten exportieren';
  @override
  String get exportDataSubtitle =>
      'Das JSON unten enthält alles, was CrispCalc auf diesem Gerät gespeichert hat — Verlauf, Variablen, Funktionen, Parameter, Einstellungen. Vor einer Neuinstallation in eine Notiz oder Cloud-Datei kopieren.';
  @override
  String get exportDataCopy => 'In Zwischenablage kopieren';
  @override
  String get exportDataCopied => 'In Zwischenablage kopiert';
  @override
  String get historyEntryCopyResult => 'Ergebnis kopieren';
  @override
  String get historyEntryCopyLatex => 'Als LaTeX kopieren';
  @override
  String get historyEntryCopyLatexSubtitle =>
      'In Word/Notion/Markdown einfügen für gesetzte Mathematik';
  @override
  String get historyEntryReuse => 'Ausdruck wiederverwenden';
  @override
  String get historyEntryCopied => 'Kopiert';

  @override
  String get settingsExportData => 'Daten exportieren';
  @override
  String get settingsExportDataSubtitle =>
      'Alles auf diesem Gerät Gespeicherte kopieren (Verlauf, Variablen, Einstellungen).';
  @override
  String get settingsHelp => 'Hilfe & Funktionsreferenz';
  @override
  String get settingsHelpSubtitle =>
      'Unterstützte Funktionen, Matrix-Syntax und Schritt-für-Schritt-Auslöser.';

  @override
  String get settingsExactIntegerMode => 'Exakter Ganzzahl-Modus';
  @override
  String get settingsExactIntegerModeSubtitle =>
      'Vollständige Ziffernfolge für beliebig genaue Ganzzahlergebnisse '
      'anzeigen (z. B. 100! = 158 Ziffern). Aus: auf double-Genauigkeit runden.';
  @override
  String exactIntegerBadge(int digits) => 'Exakte Ganzzahl · $digits Ziffern';
  @override
  String get exactIntegerTapToCopy => 'Tippen zum Kopieren';

  @override
  String get calculating => 'Berechne …';

  @override
  String get moduleSudokuTitle => 'Sudoku';
  @override
  String get moduleSudokuSubtitle =>
      '4×4- und 9×9-Rätsel lösen, die Suche Schritt für Schritt mitverfolgen.';
  @override
  String get sudokuSolveButton => 'Lösen';
  @override
  String get sudokuClearCell => 'Leeren';
  @override
  String get sudokuPresetLabelChooser => 'Rätsel';
  @override
  String get sudokuPresetCustom => 'Eigen';
  @override
  String sudokuPresetLabel(String id) {
    switch (id) {
      case 'small4x4Easy':
        return '4×4 leicht';
      case 'small4x4Medium':
        return '4×4 mittel';
      case 'small4x4Hard':
        return '4×4 schwer';
      case 'medium6x6':
        return '6×6 mittel';
      case 'standard9x9Easy':
        return '9×9 leicht';
      case 'standard9x9Medium':
        return '9×9 mittel';
      case 'standard9x9Hard':
        return '9×9 schwer (AI Escargot)';
      case 'standard9x9XEasy':
        return '9×9 Sudoku-X leicht';
    }
    return id;
  }

  @override
  String get sudokuVisualizerHeader => 'Such-Visualisierung';
  @override
  String get sudokuPlay => 'Start';
  @override
  String get sudokuPause => 'Pause';
  @override
  String get sudokuRestart => 'Neu';
  @override
  String get sudokuSpeedSlow => 'Langsam';
  @override
  String get sudokuSpeedMed => 'Mittel';
  @override
  String get sudokuSpeedFast => 'Schnell';
  @override
  String get sudokuGenerateButton => 'Erzeugen';
  @override
  String get sudokuDifficultyEasy => 'Leicht';
  @override
  String get sudokuDifficultyMedium => 'Mittel';
  @override
  String get sudokuDifficultyHard => 'Schwer';
  @override
  String get sudokuVariantRegular => 'Klassisch';
  @override
  String get sudokuVariantX => 'Sudoku-X';

  @override
  String get moduleConstraintsTitle => 'Bedingungsprobleme';
  @override
  String get moduleConstraintsSubtitle =>
      'Diophantische Gleichungen und Kryptarithmen — ganzzahlige '
      'Lösungen und Ziffernzuordnungen finden.';
  @override
  String get constraintsTabDiophantine => 'Diophantisch';
  @override
  String get constraintsTabCryptarithm => 'Kryptarithmus';
  @override
  String get constraintsDiophantineIntro =>
      'Beschränkte ganzzahlige Variablen deklarieren, die zu '
      'erfüllenden Bedingungen auflisten — der Löser zählt alle '
      'ganzzahligen Lösungen auf (gedeckelt bei 100).';
  @override
  String get constraintsCryptarithmIntro =>
      'Ein Rätsel der Form `WORT1 + WORT2 = WORT3` eingeben (oder `−` '
      'statt `+`). Jeder Buchstabe ist eine Ziffer 0..9; führende '
      'Ziffern ungleich null; alle Buchstaben tragen verschiedene Ziffern.';
  @override
  String get constraintsVariablesLabel => 'Variablen';
  @override
  String get constraintsVariablesHint =>
      'Eine pro Zeile, Format: name in min..max';
  @override
  String get constraintsConstraintsLabel => 'Bedingungen';
  @override
  String get constraintsConstraintsHint =>
      'Eine pro Zeile. Vergleiche, Arithmetik, in/not-in Mengen alle '
      'unterstützt.';
  @override
  String get constraintsCryptarithmInputLabel => 'Rätsel';
  @override
  String get constraintsSolveButton => 'Lösen';
  @override
  String get constraintsBadVarLine =>
      'Variablenzeile nicht erkannt. Erwartet: `name in min..max`';
  @override
  String get constraintsNoSolutions => 'Keine Lösungen.';
  @override
  String get constraintsCryptarithmFoundHeader => 'Ziffernzuordnung';
  @override
  String constraintsSolutionsHeader(int n) =>
      n == 1 ? '1 Lösung' : '$n Lösungen';
  @override
  String constraintsTruncatedHeader(int n) =>
      'Die ersten $n Lösungen (weitere existieren)';
  @override
  String get constraintsCopyResult => 'Lösungen kopieren';
  @override
  String get constraintsCopiedToast => 'In Zwischenablage kopiert.';

  @override
  String get clearSearchTooltip => 'Suche leeren';
  @override
  String get clearFunctionSlotTooltip => 'Funktion löschen';
  @override
  String get deleteMemorySlotTooltip => 'Speicherplatz löschen';

  @override
  String get workedExamplesTitle => 'Beispielaufgaben';
  @override
  String get workedExamplesSearchHint => 'Beispiele suchen…';
  @override
  String get workedExamplesEmpty => 'Keine Beispiele passen zum Filter.';
  @override
  String get workedExamplesCopy => 'Ausdruck kopieren';
  @override
  String get workedExamplesCopied =>
      'In Zwischenablage kopiert. Im Rechner einfügen zum Ausprobieren.';
  @override
  String get workedExamplesInsert => 'In Rechner einfügen';
  @override
  String get workedExamplesCatAll => 'Alle';
  @override
  String get workedExamplesCatCalculus => 'Analysis';
  @override
  String get workedExamplesCatAlgebra => 'Algebra';
  @override
  String get workedExamplesCatLinearAlgebra => 'Lineare Algebra';
  @override
  String get workedExamplesCatNumberTheory => 'Zahlentheorie';
  @override
  String get workedExamplesCatStatistics => 'Statistik';
  @override
  String get workedExamplesCatUnits => 'Einheiten';
  @override
  String? workedExampleTitle(String id) {
    switch (id) {
      case 'derivPoly':
        return 'Ableitung eines Polynoms';
      case 'chainRule':
        return 'Beispiel zur Kettenregel';
      case 'integralByParts':
        return 'Unbestimmtes Integral mit partieller Integration';
      case 'definiteIntegral':
        return 'Bestimmtes Integral';
      case 'sinxOverX':
        return 'Grenzwert an einer behebbaren Singularität';
      case 'partialFractions':
        return 'Partialbruchzerlegung';
      case 'quadraticFormula':
        return 'Mitternachtsformel';
      case 'factorCubic':
        return 'Polynom faktorisieren';
      case 'expandBinomial':
        return 'Binom ausmultiplizieren';
      case 'simplifyRational':
        return 'Rationalen Ausdruck vereinfachen';
      case 'matrixDet':
        return 'Determinante einer Matrix';
      case 'matrixInverse':
        return 'Inverse einer Matrix';
      case 'rref':
        return 'Reduzierte Zeilenstufenform';
      case 'factorial100':
        return 'Fakultät — exakte Ganzzahl';
      case 'fibonacci50':
        return 'Fibonacci-Zahl';
      case 'gcdEuclid':
        return 'ggT mit Euklid';
      case 'isprime':
        return 'Primzahltest (kleines n)';
      case 'compoundInterest':
        return 'Zinseszins';
      case 'zScore':
        return 'Z-Wert nachschlagen';
      case 'unitConversion':
        return 'Einheitenumrechnung inline';
      case 'compositeDim':
        return 'Arithmetik mit zusammengesetzten Dimensionen';
    }
    return null;
  }

  @override
  String? workedExampleDescription(String id) {
    switch (id) {
      case 'derivPoly':
        return 'd/dx von x³ − 4x + 7 an beliebigem x.';
      case 'chainRule':
        return 'd/dx von sin(x²) — Kettenregel auf das innere x².';
      case 'integralByParts':
        return '∫ x·sin(x) dx — wähle u = x, dv = sin(x) dx.';
      case 'definiteIntegral':
        return '∫₀¹ x² dx = 1/3 nach dem Hauptsatz.';
      case 'sinxOverX':
        return 'lim x→0 sin(x)/x = 1 (der Klassiker).';
      case 'partialFractions':
        return '∫ 1/(x² − 1) dx mit Cover-up an x = ±1.';
      case 'quadraticFormula':
        return 'Löse 2x² + 5x − 3 = 0 über die Diskriminante.';
      case 'factorCubic':
        return 'Faktorisiere x³ − 8 — Summen-/Differenzformel.';
      case 'expandBinomial':
        return '(x + 2)⁵ ausmultiplizieren — Pascalsches Dreieck.';
      case 'simplifyRational':
        return '(x² − 4)/(x − 2) auf einfachste Form kürzen.';
      case 'matrixDet':
        return 'det einer 3×3 — Laplace-Entwicklung oder Zeilen­reduktion.';
      case 'matrixInverse':
        return 'Inverse einer 2×2 — A⁻¹ = adj(A)/det(A).';
      case 'rref':
        return 'rref einer 2×3-erweiterten Systemmatrix.';
      case 'factorial100':
        return '100! — 158 Ziffern, im Exakt-Ganzzahl-Modus erhalten.';
      case 'fibonacci50':
        return 'fib(50) — Rekursion bis zu einem großen Glied.';
      case 'gcdEuclid':
        return 'gcd(252, 105) — die ursprüngliche Rekursion.';
      case 'isprime':
        return 'isprime(2027) — schnelle Probedivision.';
      case 'compoundInterest':
        return '1000 € zu 5 % über 10 Jahre, jährliche Verzinsung.';
      case 'zScore':
        return 'Zum Statistik-Reiter → Verteilungen wechseln, um Φ(1,96) '
            '≈ 0,975 zu berechnen.';
      case 'unitConversion':
        return '100 km/h in mph umgerechnet — V2 inline-Parser.';
      case 'compositeDim':
        return '100 m / 10 s ergibt eine Geschwindigkeit in m/s — V5-Parser.';
    }
    return null;
  }

  @override
  String get settingsWorkedExamples => 'Bibliothek mit Beispielaufgaben';
  @override
  String get settingsWorkedExamplesSubtitle =>
      'Vorgefertigte Rechnerausdrücke zu den wichtigsten Aufgabentypen '
      'durchsuchen und kopieren.';

  @override
  String get importDataTitle => 'Daten importieren';
  @override
  String get importDataSubtitle =>
      'Füge ein JSON aus einem früheren Export ein, um Verlauf, '
      'Variablen, Funktionen und Einstellungen wiederherzustellen.';
  @override
  String get importDataWarning =>
      'Dies überschreibt den aktuellen Verlauf, Variablen und '
      'Graphfunktionen. Es gibt keine Rückgängig-Funktion — kopiere '
      'vorher den aktuellen Zustand, wenn du ihn behalten möchtest.';
  @override
  String get importDataApply => 'Anwenden';
  @override
  String get importDataEmpty => 'Füge ein JSON ein, um zu importieren.';
  @override
  String get importDataNotObject =>
      'Das JSON muss ein Objekt sein (beginnt mit `{`).';
  @override
  String get importDataApplied => 'Importiert';
  @override
  String get settingsImportData => 'Daten importieren';
  @override
  String get settingsImportDataSubtitle =>
      'Füge ein JSON aus einem früheren Export zum Wiederherstellen ein.';

  @override
  String get userFunctionsTitle => 'Benutzerdefinierte Funktionen';
  @override
  String get userFunctionsHelp =>
      'Definiere eine Funktion einmal, rufe sie aus jedem Ausdruck auf. '
      'Z. B. `f(x) = x^2 + 1`, dann ergibt `f(3) + 1` den Wert 11. Auch '
      'die Komposition `g(f(x))` funktioniert, sofern beide definiert sind.';
  @override
  String get userFunctionsEmpty =>
      'Noch keine benutzerdefinierten Funktionen. Tippe Hinzufügen, um '
      'die erste anzulegen.';
  @override
  String get userFunctionsAdd => 'Hinzufügen';
  @override
  String get userFunctionsEdit => 'Bearbeiten';
  @override
  String get userFunctionsDelete => 'Löschen';
  @override
  String get userFunctionsName => 'Name';
  @override
  String get userFunctionsNameHelp =>
      'Einzelner Kleinbuchstabe (a..z), der nicht mit eingebauten Namen '
      'kollidiert.';
  @override
  String get userFunctionsNameRequired => 'Pflichtfeld';
  @override
  String get userFunctionsNameInvalid =>
      'Muss ein einzelner Kleinbuchstabe (a..z) sein.';
  @override
  String get userFunctionsParam => 'Parameter';
  @override
  String get userFunctionsBody => 'Rumpf';
  @override
  String get userFunctionsBodyRequired => 'Funktionsrumpf erforderlich';
  @override
  String get settingsUserFunctions => 'Benutzerdefinierte Funktionen';
  @override
  String get settingsUserFunctionsSubtitle =>
      'Definiere benannte Funktionen wie f(x) = x^2 + 1 und nutze sie '
      'in jedem Ausdruck wieder.';

  @override
  String get onboardingSkip => 'Überspringen';
  @override
  String get onboardingNext => 'Weiter';
  @override
  String get onboardingDone => 'Verstanden';
  @override
  String onboardingPage(int current, int total) => '$current / $total';
  @override
  String get onboardingKeypadTitle => 'Tastenfeld mit Reitern';
  @override
  String get onboardingKeypadBody =>
      'Wechsle zwischen den Reitern Num, Trig, CAS und Erweitert, um die '
      'gewünschte Operation zu finden. Bei breiteren Fenstern passt das '
      'ganze Tastenfeld auf einen Bildschirm — ohne Reiter.';
  @override
  String get onboardingHistoryTitle => 'Verlauf durchblättern';
  @override
  String get onboardingHistoryBody =>
      'Jede Berechnung wird gespeichert. Nach oben scrollen, um sie '
      'erneut zu sehen, lange drücken zum Kopieren oder erneut '
      'Verwenden, Suchsymbol antippen zum Filtern.';
  @override
  String get onboardingFunctionsTitle => 'Funktion auswählen';
  @override
  String get onboardingFunctionsBody =>
      'Die Tasten ∫⌄, d/dx⌄ und solve⌄ öffnen Schritt-für-Schritt-'
      'Auswahlen, die das Ergebnis Regel für Regel erklären.';
  @override
  String get onboardingAnalysisTitle => 'Analyse-Hub';
  @override
  String get onboardingAnalysisBody =>
      'Kurvendiskussion, Ebenen, Kegelschnitte, 3D-Diagramme, Statistik '
      'und der Einheitenrechner finden sich alle im Reiter Analyse.';
  @override
  String get settingsReplayTour => 'Einführungstour erneut anzeigen';
  @override
  String get settingsReplayTourSubtitle =>
      'Die Erststart-Tour beim nächsten Öffnen der App noch einmal zeigen.';

  @override
  String get helpTitle => 'Hilfe';
  @override
  String get helpFunctionsHeading => 'Unterstützte Funktionen';
  @override
  String get helpMatrixHeading => 'Matrix-Syntax';
  @override
  String get helpStepsHeading => 'Schritt-für-Schritt-Lösungen';
  @override
  String get helpMatrixBody =>
      'Matrizen mit `;` als Zeilen- und `,` als Spaltentrenner eingeben:\n\n    [1, 2; 3, 4]\n\nIntern wird das in `Matrix([[1, 2], [3, 4]])` umgewandelt. Operationen: det, inv, transpose, rref, +, -, *.';
  @override
  String get helpStepsBody =>
      'Drei Tasten im CAS-Reiter öffnen Schritt-für-Schritt-Spuren:\n\n  • d/dx⌄ für Ableitungsschritte\n  • solve⌄ für Gleichungen lösen\n  • ∫⌄ für unbestimmte Integration\n\nJede zeigt die angewandte Regel pro Schritt plus das Endergebnis.';

  @override
  String get constantsTitle => 'Konstantenreferenz';
  @override
  String get constantsSearchHint => 'Nach Symbol, Name oder Einheit suchen…';
  @override
  String get constantsNoMatches => 'Keine Konstanten passen zum Filter.';
  @override
  String get constantsAllCategory => 'Alle';
  @override
  String get constantsCategoryMathematical => 'Mathematisch';
  @override
  String get constantsCategoryPhysical => 'Physikalisch';
  @override
  String get constantsCategoryChemistry => 'Chemie';
  @override
  String get constantsCategoryAstronomy => 'Astronomie';
  @override
  String get constantsCopyValue => 'Wert kopieren';
  @override
  String constantsCopiedToast(String symbol) =>
      '$symbol in Zwischenablage kopiert';
  @override
  String get settingsConstants => 'Konstantenreferenz';
  @override
  String get settingsConstantsSubtitle =>
      'Physikalische, mathematische, chemische und astronomische Konstanten.';

  @override
  String get tabNum => 'Num';
  @override
  String get tabTrig => 'Trig';
  @override
  String get tabCas => 'CAS';
  @override
  String get tabAdvanced => 'Erweitert';
  @override
  String get tabVars => 'Variablen';
  @override
  String get tabBasic => 'Basis';
  @override
  String get tabSymbolic => 'Symbolisch';

  @override
  String? stepNote(StepNote note) {
    final p = note.params;
    switch (note.key) {
      case 'startEquation':
        return 'Wir beginnen mit der gegebenen Gleichung.';
      case 'moveRightSideOver':
        return 'Subtrahieren der rechten Seite von beiden Seiten bringt '
            'die Gleichung in die Standardform `Ausdruck = 0`, sodass der '
            'lineare oder quadratische Löser anwendbar ist.';
      case 'noEqualsSign':
        return 'Kein `=` in der Eingabe; wir behandeln sie als '
            '${p['body']} = 0.';
      case 'doesNotDependOn':
        return 'Die Gleichung hängt nicht von ${p['var']} ab.';
      case 'solveFallthroughSymbolic':
        return 'Keine standardmäßige lineare oder quadratische Form — '
            'die Antwort übernimmt der symbolische Löser.';
      case 'linearIdentifyCoefs':
        return 'Lies den Leitkoeffizienten und den konstanten Term ab — '
            'dies ist eine lineare Gleichung.';
      case 'moveConstant':
        return 'Bringe die Konstante auf die andere Seite.';
      case 'divideByCoef':
        return 'Teile beide Seiten durch den Leitkoeffizienten, um '
            '${p['var']} zu isolieren.';
      case 'quadraticIdentifyCoefs':
        return 'Lies die drei Koeffizienten am Polynom ab. Wir nehmen a aus '
            'der zweiten Ableitung ÷ 2, b aus der ersten Ableitung bei '
            '${p['var']} = 0 und c aus dem Polynom bei ${p['var']} = 0.';
      case 'discriminant':
        return 'Die Diskriminante sagt uns, wie viele reelle Wurzeln es '
            'gibt: positiv → zwei verschiedene reelle Wurzeln; null → eine '
            'Doppelwurzel; negativ → zwei komplex konjugierte Wurzeln.';
      case 'quadFormulaApply':
        return 'Setze a, b und Δ in die Mitternachtsformel ein. Das `±` '
            'liefert beide Wurzeln in einem Schritt.';
      case 'integralPullMinusOut':
        return 'Ziehe das führende Minuszeichen aus dem Integral; der '
            'Rest ist einfach ∫f.';
      case 'exprDoesNotDependOn':
        return '${p['expr']} hängt nicht von ${p['var']} ab.';
      case 'integralIdentityPower1':
        return 'Die Potenzregel für n=1: Erhöhe den Exponenten auf 2 und '
            'teile durch den neuen Exponenten.';
      case 'integralLinearity':
        return 'Integration ist linear: Das Integral einer Summe ist die '
            'Summe der Integrale.';
      case 'integralPullConstantOut':
        return 'Ziehe `${p['const']}` vor das Integral — Konstanten '
            'lassen sich herausziehen.';
      case 'integralReciprocalLog':
        return 'Das Integral von 1/${p['var']} ist der natürliche '
            'Logarithmus des Betrags.';
      case 'integralPowerRule':
        return 'Erhöhe den Exponenten um 1 und teile durch den neuen '
            'Exponenten. Funktioniert für jede Konstante n ≠ −1.';
      case 'uSubLinear':
        return 'Setze u = ${p['u']}; dann ist du = '
            '(${p['slope']})·d${p['var']}.';
      case 'integralStandardAntideriv':
        return 'Verwende die Standard-Stammfunktion für ${p['fn']}.';
      case 'uSubLinearFn':
        return 'Setze u = ${p['u']}; dann ist du = '
            '(${p['slope']})·d${p['var']}. Die Stammfunktion von '
            '${p['fn']} ist die Standardform, ausgewertet an u und durch '
            'die Steigung geteilt.';
      case 'ibpLnX':
        final v = p['var']!;
        return 'Setze u = ln($v), dv = d$v. Dann ist du = (1/$v)·d$v und '
            'v = $v, also ∫u·dv = u·v − ∫v·du = $v·ln($v) − ∫1 d$v.';
      case 'ibpXTimesF':
        return 'Setze u = ${p['var']} (also du = d${p['var']}) und '
            'dv = ${p['right']}·d${p['var']}, woraus v = ${p['v']} folgt.';
      case 'ibpRepeated':
        return 'Setze u = ${p['u']} und dv = ${p['right']}·d${p['var']}. '
            'Dann ist du = ${p['n']}·… (eine Potenz von ${p['var']} weniger) '
            'und v = ${p['v']}, sodass das neue Integral eine Potenz von '
            '${p['var']} verliert — Rekursion.';
      case 'uSubNonlinear':
        return 'Setze u = ${p['u']}; dann ist du = '
            '(${p['du']})·d${p['var']}. Der Integrand hat die Form '
            'f(u)·du, daher liefert die Substitution ∫f(u) du = '
            'Standard-Stammfunktion von ${p['fn']} ausgewertet an u'
            '${p['ratio'] == '1' ? '.' : ', mal dem konstanten Faktor ${p['ratio']}.'}';
      case 'integralLogDerivative':
        return 'Der Zähler ist (${p['ratio']})·(d/d${p['var']}[${p['den']}]), '
            'also ist das Integral ${p['ratio']}·ln|${p['den']}|.';
      case 'partialFractions':
        return 'Der Nenner hat unterschiedliche ganzzahlige Nullstellen '
            '${p['roots']}. Die Cover-up-Methode liefert '
            'A_i = P(r_i) / Q\'(r_i) für jede Nullstelle.';
      case 'partialFractionsIntegrate':
        return 'Jedes Stück `A/(x-r)` integriert sich zu A·ln|x-r|.';
      case 'trigArctanForm':
        return 'Setze a² = ${p['aSq']}, also a = ${p['a']}. Die '
            'Standardform liefert (1/a)·arctan(${p['var']}/a).';
      case 'trigArcsinForm':
        return 'Setze a² = ${p['aSq']}, also a = ${p['a']}. Die '
            'Standardform liefert arcsin(${p['var']}/a).';
      case 'integralFallthroughSymbolic':
        return 'Keine standardmäßige Lehrbuchregel passt zu dieser Form '
            '— die Antwort übernimmt der symbolische Integrator.';
      case 'diffIdentity':
        return 'Die Ableitung von ${p['var']} nach sich selbst ist 1.';
      case 'diffSumDifference':
        return 'Leite jeden Summanden einzeln ab; die Ableitung verteilt '
            'sich über `+` und `−`.';
      case 'diffQuotient':
        return 'Für einen Quotienten gilt: Zähler `f′g − fg′`, Nenner '
            'wird quadriert.';
      case 'diffProduct':
        return 'Für ein Produkt: leite jeden Faktor ab und addiere die '
            'Stücke — `(fg)′ = f′g + fg′`.';
      case 'diffPowerSimple':
        return 'Ziehe den Exponenten als Koeffizient herunter und '
            'reduziere den Exponenten um 1.';
      case 'diffPowerChain':
        return 'Ziehe den Exponenten herunter und reduziere ihn um 1, '
            'multipliziere dann mit der Ableitung der inneren Basis — '
            'dieser Faktor `d/d${p['var']}[${p['base']}]` ist die '
            'Kettenregel.';
      case 'diffExponential':
        return 'Wenn die Variable im Exponenten steht, ist die Ableitung '
            'der gleiche Ausdruck mal `ln(Basis)` mal die Ableitung des '
            'Exponenten.';
      case 'diffStandardSimple':
        return 'Wende die Standardableitung für ${p['fn']} an.';
      case 'diffStandardChain':
        return 'Das Argument hängt von ${p['var']} ab, also multipliziere '
            'mit dessen Ableitung (Kettenregel).';
      case 'diffFallthrough':
        return 'Kein Muster einer höherwertigen Regel erkannt für diese '
            'Form.';
    }
    return null;
  }
}

class FrLocalizations implements AppLocalizations {
  const FrLocalizations();

  @override
  String get navCalculator => 'Calculatrice';
  @override
  String get navGraphing => 'Graphes';
  @override
  String get navFunctions => 'Fonctions';
  @override
  String get navAnalysis => 'Analyse';
  @override
  String get navSettings => 'Paramètres';

  @override
  String get historyHere => 'L\'historique des calculs apparaîtra ici.';
  @override
  String get historyLabel => 'Historique :';
  @override
  String get clearButton => 'C';
  @override
  String get clearHistory => 'Effacer l\'historique';
  @override
  String get clearHistoryConfirm =>
      'Supprimer toutes les entrées de l\'historique des calculs ?';
  @override
  String get searchHistory => 'Rechercher dans l\'historique';
  @override
  String get searchHistoryHint => 'Filtrer l\'historique…';
  @override
  String get historyNoMatches => 'Aucune entrée correspondante.';

  @override
  String graphingTitle(int count) => 'Graphes ($count fonctions)';
  @override
  String functionAdded(int slot) => 'Fonction ajoutée à Y$slot';
  @override
  String functionRemoved(int slot) => 'Y$slot supprimée';
  @override
  String get allSlotsFull =>
      'Tous les emplacements de fonction sont occupés. Effacez-en une d\'abord.';
  @override
  String get clearAllFunctions => 'Effacer toutes les fonctions';
  @override
  String get clearAllFunctionsConfirm =>
      'Voulez-vous vraiment effacer toutes les fonctions tracées ?';
  @override
  String get cancel => 'Annuler';
  @override
  String get clearAll => 'Tout effacer';
  @override
  String get zoomIn => 'Zoom avant';
  @override
  String get zoomOut => 'Zoom arrière';
  @override
  String get resetView => 'Réinitialiser la vue';
  @override
  String get showKeypad => 'Afficher le clavier';
  @override
  String get hideKeypad => 'Masquer le clavier';
  @override
  String get showAnnotations => 'Afficher racines et extréma';
  @override
  String get hideAnnotations => 'Masquer racines et extréma';
  @override
  String get analyzeFunctions => 'Analyser les fonctions';
  @override
  String get selectFunctionToAnalyze => 'Choisir la fonction à analyser';
  @override
  String get plotButton => 'Tracer';
  @override
  String get enterFunctionPrompt =>
      'Saisissez une fonction ci-dessous pour la tracer.';

  @override
  String get analysisModulesTitle => 'Modules d\'analyse';
  @override
  String get moduleCurveSketching => 'Étude de fonction';
  @override
  String get moduleCurveSketchingSubtitle =>
      'Analyse complète d\'une fonction f(x)';
  @override
  String get modulePlanes => 'Plans';
  @override
  String get modulePlanesSubtitle =>
      'Analyser des plans 3D en forme cartésienne ou paramétrique';
  @override
  String get moduleConics => 'Coniques';
  @override
  String get moduleConicsSubtitle =>
      'Classer Ax² + Bxy + Cy² + Dx + Ey + F = 0';
  @override
  String get moduleStatistics => 'Statistiques';
  @override
  String get moduleStatisticsSubtitle =>
      'Statistiques descriptives, régression linéaire, lois normale & binomiale';
  @override
  String get module3DTitle => 'Graphique 3D';
  @override
  String get module3DSubtitle =>
      'Tracer z = f(x, y) comme une surface filaire rotative';
  @override
  String get module3DFunctionLabel => 'f(x, y)';
  @override
  String get module3DRangeLabel => 'Plage';
  @override
  String get module3DResample => 'Rééchantillonner la grille';
  @override
  String get module3DTapPlot =>
      'Saisissez une fonction de x et y, puis appuyez sur Tracer.';
  @override
  String get moduleUnitConverterTitle => 'Convertisseur d\'unités';
  @override
  String get moduleUnitConverterSubtitle =>
      'Convertir longueurs, temps, masse, température, vitesse, angle';
  @override
  String get sectionVariables => 'Variables';
  @override
  String get sectionGraphFunctions => 'Fonctions graphiques';
  @override
  String get sectionMemorySlots => 'Emplacements mémoire';
  @override
  String get funcCtxShowOnGraph => 'Afficher dans le graphique';
  @override
  String get funcCtxAnalyze => 'Analyser (étude de fonction)';
  @override
  String get funcCtxDifferentiate => 'Dériver';
  @override
  String get funcCtxIntegrate => 'Intégrer';
  @override
  String get funcCtxSolve => 'Résoudre f(x) = 0';
  @override
  String get funcCtxCopy => 'Copier l\'expression';
  @override
  String get funcEditorTitle => 'Éditeur de fonctions (Y=)';
  @override
  String get funcEditorDone => 'Terminé';
  @override
  String get funcEditorSelectFirst =>
      'Sélectionnez un champ de fonction à modifier.';
  @override
  String get funcEditorAnalyzeTooltip => 'Analyser cette fonction';
  @override
  String get funcEditorGraphTooltip => 'Tracer cette fonction';
  @override
  String get unitDimLength => 'Longueur';
  @override
  String get unitDimTime => 'Temps';
  @override
  String get unitDimMass => 'Masse';
  @override
  String get unitDimTemperature => 'Température';
  @override
  String get unitDimVelocity => 'Vitesse';
  @override
  String get unitDimAngle => 'Angle';
  @override
  String get planeAnalysisTitle => 'Analyse de plan';
  @override
  String get planeRepCoordinate => 'Coordonnées';
  @override
  String get planeRepParametric => 'Paramétrique';
  @override
  String get buttonAnalyze => 'Analyser';
  @override
  String get buttonClassify => 'Classifier';
  @override
  String get curveAnalysisEnterFunction =>
      'Saisissez une fonction à analyser :';
  @override
  String get curveResultWarnings => 'Avertissements';
  @override
  String get curveResultDerivatives => 'Dérivées';
  @override
  String get curveResultKeyPoints => 'Points clés';
  @override
  String get curveResultYIntercept => 'Ordonnée à l\'origine';
  @override
  String get curveResultRoots => 'Racines';
  @override
  String get curveResultExtrema => 'Extrema (Minima/Maxima)';
  @override
  String get curveResultInflectionPoints => 'Points d\'inflexion';
  @override
  String get curveResultNoExtrema => 'Aucun extremum trouvé.';
  @override
  String get curveResultNoInflection => 'Aucun point d\'inflexion trouvé.';
  @override
  String curveAnalysisOfFunction(String function) =>
      'Analyse de f(x) = $function';
  @override
  String curveResultPointPrefix(String point) => 'Point : $point';
  @override
  String get extremumLocalMinimum => 'Minimum local';
  @override
  String get extremumLocalMaximum => 'Maximum local';
  @override
  String get extremumCriticalPoint => 'Point critique';
  @override
  String get extremumInflectionPoint => 'Point d\'inflexion';
  @override
  String get extremumNoCriticalPoints => 'Aucun point critique trouvé';
  @override
  String get extremumConstantConcavity =>
      'La fonction a une concavité constante (f\'\'(x) = 0 partout)';
  @override
  String get statisticsTitle => 'Statistiques';
  @override
  String get statsTabDescriptive => 'Descriptive';
  @override
  String get statsTabRegression => 'Régression';
  @override
  String get statsTabDistributions => 'Distributions';
  @override
  String get statsTabTests => 'Tests';
  @override
  String get statsDescCount => 'Effectif';
  @override
  String get statsDescSum => 'Somme';
  @override
  String get statsDescMean => 'Moyenne';
  @override
  String get statsDescMedian => 'Médiane';
  @override
  String get statsDescMode => 'Mode';
  @override
  String get statsDescMin => 'Min';
  @override
  String get statsDescMax => 'Max';
  @override
  String get statsDescRange => 'Étendue';
  @override
  String get statsDescVariance => 'Variance';
  @override
  String get statsDescStddev => 'Écart-type';
  @override
  String get statsDescQ1 => 'Q1';
  @override
  String get statsDescQ3 => 'Q3';
  @override
  String get statsDescIqr => 'EIQ';
  @override
  String get helpGroupProbability => 'Probabilité';
  @override
  String get helpFnRrefDescription => 'Forme échelonnée réduite (Gauss-Jordan)';

  @override
  String get settingsTitle => 'Paramètres';
  @override
  String get settingsNumberFormat => 'Format des nombres';
  @override
  String get settingsNumberFormatAuto => 'Auto (129, 129,5)';
  @override
  String get settingsNumberFormatInteger => 'Entier (129)';
  @override
  String get settingsNumberFormatOneDecimal => 'Une décimale (129,0)';
  @override
  String get settingsNumberFormatTwoDecimal => 'Deux décimales (129,00)';
  @override
  String get settingsLanguage => 'Langue';
  @override
  String get settingsLanguageEnglish => 'English';
  @override
  String get settingsLanguageGerman => 'Deutsch';
  @override
  String get settingsLanguageFrench => 'Français';
  @override
  String get settingsLanguageSpanish => 'Español';
  @override
  String get settingsTheme => 'Apparence';
  @override
  String get settingsThemeSystem => 'Selon le système';
  @override
  String get settingsThemeLight => 'Clair';
  @override
  String get settingsThemeDark => 'Sombre';
  @override
  String get settingsLayoutTitle => 'Disposition';
  @override
  String get settingsLayoutBody =>
      'CrispCalc s\'adapte à la largeur de la fenêtre : navigation '
      'inférieure sur smartphone, rail latéral sur tablette et bureau. '
      'À partir de ~760 px, le pavé affiche toutes les touches sans onglets.';

  @override
  String get aboutTitle => 'À propos de CrispCalc';
  @override
  String get aboutTagline => 'Calculatrice symbolique CAS basée sur SymEngine';
  @override
  String aboutVersion(String version) => 'Version $version';
  @override
  String get aboutServiceProvider => 'Fournisseur';
  @override
  String get aboutContact => 'Contact';
  @override
  String get aboutPrivacy => 'Confidentialité';
  @override
  String get aboutPrivacyText =>
      'CrispCalc fonctionne entièrement sur l\'appareil. Aucun calcul, '
      'entrée d\'historique ou variable utilisateur n\'est jamais transmis '
      'à un serveur. L\'application ne collecte aucune donnée d\'analyse '
      'et ne contacte aucun service distant.';
  @override
  String get aboutDisclaimer => 'Avertissement';
  @override
  String get aboutDisclaimerText =>
      'CrispCalc est fourni « tel quel », sans aucune garantie. Le moteur '
      'symbolique peut renvoyer des résultats imprécis pour des entrées '
      'numériques mal conditionnées ou des expressions symboliques non '
      'prises en charge. Vérifiez de manière indépendante les calculs '
      'critiques.';
  @override
  String get aboutLicense => 'Licence';
  @override
  String get aboutLicenseText =>
      'CrispCalc est un logiciel libre publié sous la GNU Affero General '
      'Public License version 3 ou ultérieure. Ce choix découle des '
      'exigences de copyleft des bibliothèques GMP/MPFR/MPC/FLINT '
      'incluses, liées statiquement.';
  @override
  String get aboutOpenSourceLicenses => 'Licences open source';
  @override
  String get settingsAbout => 'À propos de CrispCalc';
  @override
  String get matrixDiagnosticsTitle => 'Auto-test matriciel';
  @override
  String get matrixDiagnosticsSubtitle =>
      'Vérifier det / inv / transpose / + / * via le pont natif.';
  @override
  String matrixDiagnosticsSummary(int passed, int total) =>
      '$passed vérifications sur $total réussies';
  @override
  String get unitConverterTitle => 'Convertisseur d\'unités';
  @override
  String get unitConverterSubtitle =>
      'Longueur / temps / masse / température / vitesse / angle.';

  @override
  String get selectEquation =>
      'Sélectionnez une équation ou continuez à taper :';
  @override
  String get continueTyping => 'Continuer la saisie';
  @override
  String get selectFunction =>
      'Sélectionnez une fonction ou continuez à taper :';
  @override
  String get dismissPanel => 'Fermer ce panneau';
  @override
  String solveFor(int n) => 'Résoudre Y$n = 0';
  @override
  String whereY(int n, String func) => 'où Y$n = $func';

  @override
  String get dialogInsert => 'Insérer';
  @override
  String get dialogClose => 'Fermer';
  @override
  String get dialogShowSteps => 'Voir les étapes';
  @override
  String get dialogVariable => 'Variable';
  @override
  String get dialogExpression => 'Expression';
  @override
  String get dialogValue => 'Valeur';
  @override
  String get dialogFunction => 'Fonction f(x)';

  @override
  String get integralTitle => 'Intégrale';
  @override
  String get integralLowerBound => 'Borne inférieure';
  @override
  String get integralUpperBound => 'Borne supérieure';
  @override
  String get integralDefinite => 'Intégrale définie';
  @override
  String get nthRootTitle => 'Racine n-ième';
  @override
  String get nthRootBase => 'Base';
  @override
  String get limitTitle => 'Limite';
  @override
  String get limitApproaches => 'tend vers';
  @override
  String get substituteTitle => 'Substituer';
  @override
  String get substituteUseStoredVariable =>
      'Utiliser une variable stockée comme valeur :';

  @override
  String get differentiationStepsTitle => 'Étapes de dérivation';
  @override
  String differentiationStepsHeader(String variable) =>
      'Dérivation par rapport à $variable :';
  @override
  String get solveStepsTitle => 'Étapes de résolution';
  @override
  String get solveStepsEquationLabel => 'Équation ou expression';
  @override
  String get solveStepsSolveFor => 'Résoudre pour';
  @override
  String get solveStepsHint => 'p. ex. 2x + 3 = 7  ou  x^2 - 5x + 6';
  @override
  String solveStepsHeader(String variable) => 'Résolution pour $variable :';
  @override
  String get integrationStepsTitle => 'Étapes d\'intégration';
  @override
  String get integrationStepsIntegrandLabel => 'Intégrande';
  @override
  String get integrationStepsWrt => 'Intégrer par rapport à';
  @override
  String get integrationStepsHint => 'p. ex. x^2  ou  sin(x) + 2x';
  @override
  String integrationStepsHeader(String variable) =>
      'Intégration par rapport à $variable :';

  @override
  String get errorSolveFormat =>
      'Erreur : le format de solve() est solve(équation, variable)';
  @override
  String get errorInvalidSolve => 'Erreur : syntaxe solve() invalide';
  @override
  String get errorInvalidDiff => 'Erreur : syntaxe d/dx() invalide';
  @override
  String get errorInvalidFactor => 'Erreur : syntaxe factor() invalide';
  @override
  String get errorInvalidExpand => 'Erreur : syntaxe expand() invalide';
  @override
  String get errorInvalidSimplify => 'Erreur : syntaxe simplify() invalide';
  @override
  String get errorGcdArgs => 'Erreur : gcd() requiert exactement 2 arguments';
  @override
  String get errorInvalidGcd => 'Erreur : syntaxe gcd() invalide';
  @override
  String get errorLcmArgs => 'Erreur : lcm() requiert exactement 2 arguments';
  @override
  String get errorInvalidLcm => 'Erreur : syntaxe lcm() invalide';

  @override
  String get errorParse =>
      'L\'expression n\'a pas pu être analysée. Vérifiez les parenthèses non appariées, les fautes de frappe ou les opérateurs manquants.';
  @override
  String get errorNativeRequired =>
      'Cette opération nécessite la bibliothèque mathématique native, non chargée sur cette plateforme.';
  @override
  String get errorIntegrateNotImplemented =>
      'L\'intégration symbolique n\'est pas disponible dans cette version. Utilisez ∫ avec des bornes pour un résultat numérique (défini).';
  @override
  String get errorMatrixLiteral =>
      'Le littéral de matrice est mal formé. Utilisez le format [a,b; c,d] ou l\'éditeur de matrice.';
  @override
  String get errorInternalMatrixDisposed =>
      'Référence de matrice interne non valide. Veuillez relancer l\'opération.';
  @override
  String errorInvalidSyntax(String op) =>
      'Les arguments passés à $op() n\'avaient pas la forme attendue. Consultez l\'exemple dans l\'aide / À propos.';

  @override
  String get exportDataTitle => 'Exporter les données';
  @override
  String get exportDataSubtitle =>
      'Le JSON ci-dessous contient tout ce que CrispCalc a stocké sur cet appareil — historique, variables, fonctions, paramètres, réglages. Copiez-le dans une note ou un document cloud avant de réinstaller.';
  @override
  String get exportDataCopy => 'Copier dans le presse-papiers';
  @override
  String get exportDataCopied => 'Copié dans le presse-papiers';
  @override
  String get historyEntryCopyResult => 'Copier le résultat';
  @override
  String get historyEntryCopyLatex => 'Copier en LaTeX';
  @override
  String get historyEntryCopyLatexSubtitle =>
      'Coller dans Word/Notion/Markdown pour des maths composées';
  @override
  String get historyEntryReuse => 'Réutiliser l\'expression';
  @override
  String get historyEntryCopied => 'Copié';

  @override
  String get settingsExportData => 'Exporter les données';
  @override
  String get settingsExportDataSubtitle =>
      'Copier tout ce qui est stocké sur cet appareil (historique, variables, réglages).';
  @override
  String get settingsHelp => 'Aide & référence des fonctions';
  @override
  String get settingsHelpSubtitle =>
      'Fonctions prises en charge, syntaxe matricielle et déclencheurs pas-à-pas.';

  @override
  String get settingsExactIntegerMode => 'Mode entier exact';
  @override
  String get settingsExactIntegerModeSubtitle =>
      'Afficher la chaîne complète de chiffres pour les résultats entiers '
      'en précision arbitraire (par ex. 100! = 158 chiffres). Désactivé : '
      'arrondi à la précision double.';
  @override
  String exactIntegerBadge(int digits) => 'Entier exact · $digits chiffres';
  @override
  String get exactIntegerTapToCopy => 'Toucher pour copier';

  @override
  String get calculating => 'Calcul en cours …';

  @override
  String get moduleSudokuTitle => 'Sudoku';
  @override
  String get moduleSudokuSubtitle =>
      'Résoudre des grilles 4×4 et 9×9, suivre la recherche pas à pas.';
  @override
  String get sudokuSolveButton => 'Résoudre';
  @override
  String get sudokuClearCell => 'Effacer';
  @override
  String get sudokuPresetLabelChooser => 'Grille';
  @override
  String get sudokuPresetCustom => 'Personnalisée';
  @override
  String sudokuPresetLabel(String id) {
    switch (id) {
      case 'small4x4Easy':
        return '4×4 facile';
      case 'small4x4Medium':
        return '4×4 moyen';
      case 'small4x4Hard':
        return '4×4 difficile';
      case 'medium6x6':
        return '6×6 moyen';
      case 'standard9x9Easy':
        return '9×9 facile';
      case 'standard9x9Medium':
        return '9×9 moyen';
      case 'standard9x9Hard':
        return '9×9 difficile (AI Escargot)';
      case 'standard9x9XEasy':
        return '9×9 Sudoku-X facile';
    }
    return id;
  }

  @override
  String get sudokuVisualizerHeader => 'Visualiseur de recherche';
  @override
  String get sudokuPlay => 'Lecture';
  @override
  String get sudokuPause => 'Pause';
  @override
  String get sudokuRestart => 'Redémarrer';
  @override
  String get sudokuSpeedSlow => 'Lent';
  @override
  String get sudokuSpeedMed => 'Moyen';
  @override
  String get sudokuSpeedFast => 'Rapide';
  @override
  String get sudokuGenerateButton => 'Générer';
  @override
  String get sudokuDifficultyEasy => 'Facile';
  @override
  String get sudokuDifficultyMedium => 'Moyen';
  @override
  String get sudokuDifficultyHard => 'Difficile';
  @override
  String get sudokuVariantRegular => 'Classique';
  @override
  String get sudokuVariantX => 'Sudoku-X';

  @override
  String get moduleConstraintsTitle => 'Problèmes de contraintes';
  @override
  String get moduleConstraintsSubtitle =>
      'Équations diophantiennes et cryptarithmes — trouver des '
      'solutions entières et des attributions de chiffres.';
  @override
  String get constraintsTabDiophantine => 'Diophantien';
  @override
  String get constraintsTabCryptarithm => 'Cryptarithme';
  @override
  String get constraintsDiophantineIntro =>
      'Déclare des variables entières bornées, liste les contraintes '
      'à satisfaire — le solveur énumère toutes les solutions '
      'entières (plafonnées à 100).';
  @override
  String get constraintsCryptarithmIntro =>
      'Entre une énigme de la forme `MOT1 + MOT2 = MOT3` (ou `−` au '
      'lieu de `+`). Chaque lettre est un chiffre 0..9 ; les chiffres '
      'de tête sont non nuls ; toutes les lettres portent des chiffres '
      'distincts.';
  @override
  String get constraintsVariablesLabel => 'Variables';
  @override
  String get constraintsVariablesHint =>
      'Une par ligne, format : name in min..max';
  @override
  String get constraintsConstraintsLabel => 'Contraintes';
  @override
  String get constraintsConstraintsHint =>
      'Une par ligne. Comparaisons, arithmétique, in/not-in ensembles '
      'tous pris en charge.';
  @override
  String get constraintsCryptarithmInputLabel => 'Énigme';
  @override
  String get constraintsSolveButton => 'Résoudre';
  @override
  String get constraintsBadVarLine =>
      'Ligne de variable non reconnue. Attendu : `name in min..max`';
  @override
  String get constraintsNoSolutions => 'Aucune solution.';
  @override
  String get constraintsCryptarithmFoundHeader => 'Attribution des chiffres';
  @override
  String constraintsSolutionsHeader(int n) =>
      n == 1 ? '1 solution' : '$n solutions';
  @override
  String constraintsTruncatedHeader(int n) =>
      'Affichage des $n premières solutions (d\'autres existent)';
  @override
  String get constraintsCopyResult => 'Copier les solutions';
  @override
  String get constraintsCopiedToast => 'Copié dans le presse-papiers.';

  @override
  String get clearSearchTooltip => 'Effacer la recherche';
  @override
  String get clearFunctionSlotTooltip => 'Effacer l\'emplacement de fonction';
  @override
  String get deleteMemorySlotTooltip => 'Supprimer l\'emplacement mémoire';

  @override
  String get workedExamplesTitle => 'Exemples résolus';
  @override
  String get workedExamplesSearchHint => 'Rechercher des exemples…';
  @override
  String get workedExamplesEmpty => 'Aucun exemple ne correspond au filtre.';
  @override
  String get workedExamplesCopy => 'Copier l\'expression';
  @override
  String get workedExamplesCopied =>
      'Copié dans le presse-papiers. Colle dans la calculatrice pour '
      'l\'essayer.';
  @override
  String get workedExamplesInsert => 'Insérer dans la calculatrice';
  @override
  String get workedExamplesCatAll => 'Tous';
  @override
  String get workedExamplesCatCalculus => 'Analyse';
  @override
  String get workedExamplesCatAlgebra => 'Algèbre';
  @override
  String get workedExamplesCatLinearAlgebra => 'Algèbre linéaire';
  @override
  String get workedExamplesCatNumberTheory => 'Théorie des nombres';
  @override
  String get workedExamplesCatStatistics => 'Statistiques';
  @override
  String get workedExamplesCatUnits => 'Unités';
  @override
  String? workedExampleTitle(String id) {
    switch (id) {
      case 'derivPoly':
        return 'Dérivée d\'un polynôme';
      case 'chainRule':
        return 'Exemple de règle de la chaîne';
      case 'integralByParts':
        return 'Intégrale indéfinie par parties';
      case 'definiteIntegral':
        return 'Intégrale définie';
      case 'sinxOverX':
        return 'Limite en une singularité supprimable';
      case 'partialFractions':
        return 'Décomposition en éléments simples';
      case 'quadraticFormula':
        return 'Formule quadratique';
      case 'factorCubic':
        return 'Factoriser un polynôme';
      case 'expandBinomial':
        return 'Développer un binôme';
      case 'simplifyRational':
        return 'Simplifier une expression rationnelle';
      case 'matrixDet':
        return 'Déterminant d\'une matrice';
      case 'matrixInverse':
        return 'Inverse d\'une matrice';
      case 'rref':
        return 'Forme échelonnée réduite';
      case 'factorial100':
        return 'Factorielle — entier exact';
      case 'fibonacci50':
        return 'Nombre de Fibonacci';
      case 'gcdEuclid':
        return 'PGCD par Euclide';
      case 'isprime':
        return 'Test de primalité (petit n)';
      case 'compoundInterest':
        return 'Intérêts composés';
      case 'zScore':
        return 'Lecture d\'un score Z';
      case 'unitConversion':
        return 'Conversion d\'unités en ligne';
      case 'compositeDim':
        return 'Arithmétique à dimensions composées';
    }
    return null;
  }

  @override
  String? workedExampleDescription(String id) {
    switch (id) {
      case 'derivPoly':
        return 'd/dx de x³ − 4x + 7 en tout x.';
      case 'chainRule':
        return 'd/dx de sin(x²) — règle de la chaîne sur le x² intérieur.';
      case 'integralByParts':
        return '∫ x·sin(x) dx — pose u = x, dv = sin(x) dx.';
      case 'definiteIntegral':
        return '∫₀¹ x² dx = 1/3 par le théorème fondamental.';
      case 'sinxOverX':
        return 'lim x→0 sin(x)/x = 1 (le classique).';
      case 'partialFractions':
        return '∫ 1/(x² − 1) dx par la méthode du masque en x = ±1.';
      case 'quadraticFormula':
        return 'Résoudre 2x² + 5x − 3 = 0 via le discriminant.';
      case 'factorCubic':
        return 'Factoriser x³ − 8 — somme/différence de cubes.';
      case 'expandBinomial':
        return 'Développer (x + 2)⁵ — triangle de Pascal.';
      case 'simplifyRational':
        return 'Réduire (x² − 4)/(x − 2) à sa forme la plus simple.';
      case 'matrixDet':
        return 'det d\'une 3×3 — développement de Laplace ou réduction.';
      case 'matrixInverse':
        return 'Inverse d\'une 2×2 — A⁻¹ = adj(A)/det(A).';
      case 'rref':
        return 'rref d\'un système 2×3 augmenté.';
      case 'factorial100':
        return '100! — 158 chiffres, conservés en mode entier exact.';
      case 'fibonacci50':
        return 'fib(50) — récurrence jusqu\'à un grand terme.';
      case 'gcdEuclid':
        return 'gcd(252, 105) — la récurrence d\'origine.';
      case 'isprime':
        return 'isprime(2027) — division d\'essai rapide.';
      case 'compoundInterest':
        return '1000 € à 5 % sur 10 ans, capitalisation annuelle.';
      case 'zScore':
        return 'Aller dans l\'écran Statistiques → Distributions pour '
            'calculer Φ(1,96) ≈ 0,975.';
      case 'unitConversion':
        return '100 km/h converti en mph — analyseur inline V2.';
      case 'compositeDim':
        return '100 m / 10 s donne une vitesse en m/s — analyseur V5.';
    }
    return null;
  }

  @override
  String get settingsWorkedExamples => 'Bibliothèque d\'exemples résolus';
  @override
  String get settingsWorkedExamplesSubtitle =>
      'Parcourir et copier des expressions de calculatrice prêtes à '
      'coller couvrant les grands types de problèmes.';

  @override
  String get importDataTitle => 'Importer les données';
  @override
  String get importDataSubtitle =>
      'Colle un JSON issu d\'un export précédent pour restaurer '
      'l\'historique, les variables, les fonctions et les réglages.';
  @override
  String get importDataWarning =>
      'Cela écrase l\'historique actuel, les variables et les fonctions '
      'graphiques. Pas d\'annulation — copie d\'abord l\'état actuel '
      'si tu veux le conserver.';
  @override
  String get importDataApply => 'Appliquer';
  @override
  String get importDataEmpty => 'Colle un JSON pour importer.';
  @override
  String get importDataNotObject =>
      'Le JSON doit être un objet (commence par `{`).';
  @override
  String get importDataApplied => 'Importé';
  @override
  String get settingsImportData => 'Importer les données';
  @override
  String get settingsImportDataSubtitle =>
      'Colle un JSON d\'un export précédent pour restaurer.';

  @override
  String get userFunctionsTitle => 'Fonctions personnalisées';
  @override
  String get userFunctionsHelp =>
      'Définis une fonction une fois, appelle-la depuis n\'importe quelle '
      'expression. Par ex. `f(x) = x^2 + 1`, alors `f(3) + 1` vaut 11. '
      'La composition `g(f(x))` fonctionne tant que les deux sont définies.';
  @override
  String get userFunctionsEmpty =>
      'Pas encore de fonctions personnalisées. Appuie sur Ajouter pour en '
      'créer une.';
  @override
  String get userFunctionsAdd => 'Ajouter';
  @override
  String get userFunctionsEdit => 'Modifier';
  @override
  String get userFunctionsDelete => 'Supprimer';
  @override
  String get userFunctionsName => 'Nom';
  @override
  String get userFunctionsNameHelp =>
      'Une seule lettre minuscule (a..z) qui n\'entre pas en conflit '
      'avec les noms intégrés.';
  @override
  String get userFunctionsNameRequired => 'Obligatoire';
  @override
  String get userFunctionsNameInvalid =>
      'Doit être une seule lettre minuscule (a..z).';
  @override
  String get userFunctionsParam => 'Paramètre';
  @override
  String get userFunctionsBody => 'Corps';
  @override
  String get userFunctionsBodyRequired => 'Corps de fonction requis';
  @override
  String get settingsUserFunctions => 'Fonctions personnalisées';
  @override
  String get settingsUserFunctionsSubtitle =>
      'Définis des fonctions nommées comme f(x) = x^2 + 1 et réutilise-les '
      'dans toute expression.';

  @override
  String get onboardingSkip => 'Passer';
  @override
  String get onboardingNext => 'Suivant';
  @override
  String get onboardingDone => 'Compris';
  @override
  String onboardingPage(int current, int total) => '$current / $total';
  @override
  String get onboardingKeypadTitle => 'Clavier à onglets';
  @override
  String get onboardingKeypadBody =>
      'Bascule entre les onglets Num, Trig, CAS et Avancé pour '
      'trouver l\'opération recherchée. Sur les écrans plus larges, '
      'tout le clavier tient en une seule vue — sans onglets.';
  @override
  String get onboardingHistoryTitle => 'Parcourir l\'historique';
  @override
  String get onboardingHistoryBody =>
      'Chaque calcul est enregistré. Fais défiler vers le haut pour '
      'le revoir, appuie longuement pour copier ou réutiliser, touche '
      'l\'icône de recherche pour filtrer.';
  @override
  String get onboardingFunctionsTitle => 'Choisir une fonction';
  @override
  String get onboardingFunctionsBody =>
      'Les boutons ∫⌄, d/dx⌄ et solve⌄ ouvrent des sélecteurs pas-à-pas '
      'qui détaillent la réponse règle par règle.';
  @override
  String get onboardingAnalysisTitle => 'Hub d\'analyse';
  @override
  String get onboardingAnalysisBody =>
      'Étude de fonction, plans, coniques, tracé 3D, statistiques et '
      'le convertisseur d\'unités sont tous dans l\'onglet Analyse.';
  @override
  String get settingsReplayTour => 'Revoir la visite guidée';
  @override
  String get settingsReplayTourSubtitle =>
      'Afficher à nouveau la visite de premier lancement la prochaine fois '
      'que tu ouvres l\'app.';

  @override
  String get helpTitle => 'Aide';
  @override
  String get helpFunctionsHeading => 'Fonctions prises en charge';
  @override
  String get helpMatrixHeading => 'Syntaxe matricielle';
  @override
  String get helpStepsHeading => 'Solutions pas-à-pas';
  @override
  String get helpMatrixBody =>
      'Saisissez des matrices avec `;` pour les lignes et `,` pour les cellules :\n\n    [1, 2; 3, 4]\n\nLa calculatrice convertit en `Matrix([[1, 2], [3, 4]])` en interne. Opérations : det, inv, transpose, rref, +, -, *.';
  @override
  String get helpStepsBody =>
      'Trois boutons du pavé CAS ouvrent des traces pas-à-pas :\n\n  • d/dx⌄ pour les étapes de dérivation\n  • solve⌄ pour la résolution d\'équations\n  • ∫⌄ pour l\'intégration indéfinie\n\nChaque vue montre la règle appliquée à chaque étape plus la réponse finale.';

  @override
  String get constantsTitle => 'Référence des constantes';
  @override
  String get constantsSearchHint => 'Rechercher par symbole, nom ou unité…';
  @override
  String get constantsNoMatches =>
      'Aucune constante ne correspond à ce filtre.';
  @override
  String get constantsAllCategory => 'Toutes';
  @override
  String get constantsCategoryMathematical => 'Mathématiques';
  @override
  String get constantsCategoryPhysical => 'Physique';
  @override
  String get constantsCategoryChemistry => 'Chimie';
  @override
  String get constantsCategoryAstronomy => 'Astronomie';
  @override
  String get constantsCopyValue => 'Copier la valeur';
  @override
  String constantsCopiedToast(String symbol) =>
      '$symbol copié dans le presse-papiers';
  @override
  String get settingsConstants => 'Référence des constantes';
  @override
  String get settingsConstantsSubtitle =>
      'Constantes physiques, mathématiques, chimiques et astronomiques.';

  @override
  String get tabNum => 'Num';
  @override
  String get tabTrig => 'Trig';
  @override
  String get tabCas => 'CAS';
  @override
  String get tabAdvanced => 'Avancé';
  @override
  String get tabVars => 'Variables';
  @override
  String get tabBasic => 'Base';
  @override
  String get tabSymbolic => 'Symbolique';

  @override
  String? stepNote(StepNote note) {
    final p = note.params;
    switch (note.key) {
      case 'startEquation':
        return 'Partons de l\'équation telle qu\'elle est donnée.';
      case 'moveRightSideOver':
        return 'Soustraire le membre de droite des deux côtés met '
            'l\'équation sous la forme standard `expression = 0`, ce qui '
            'permet d\'appliquer le solveur linéaire ou quadratique.';
      case 'noEqualsSign':
        return 'Pas de `=` dans l\'entrée ; on la traite comme '
            '${p['body']} = 0.';
      case 'doesNotDependOn':
        return 'L\'équation ne dépend pas de ${p['var']}.';
      case 'solveFallthroughSymbolic':
        return 'Pas de forme linéaire ou quadratique standard — la réponse '
            'est confiée au solveur symbolique.';
      case 'linearIdentifyCoefs':
        return 'Repérons le coefficient dominant et le terme constant — '
            'c\'est une équation linéaire.';
      case 'moveConstant':
        return 'Passe la constante de l\'autre côté.';
      case 'divideByCoef':
        return 'Divise les deux membres par le coefficient dominant pour '
            'isoler ${p['var']}.';
      case 'quadraticIdentifyCoefs':
        return 'Lis les trois coefficients sur le polynôme. On prend a à '
            'partir de la dérivée seconde ÷ 2, b à partir de la dérivée '
            'première en ${p['var']} = 0, et c à partir du polynôme en '
            '${p['var']} = 0.';
      case 'discriminant':
        return 'Le discriminant indique le nombre de racines réelles : '
            'positif → deux racines réelles distinctes ; nul → une racine '
            'double ; négatif → deux racines complexes conjuguées.';
      case 'quadFormulaApply':
        return 'Substitue a, b et Δ dans la formule quadratique. Le `±` '
            'donne les deux racines en une étape.';
      case 'integralPullMinusOut':
        return 'Sors le signe moins de l\'intégrale ; le reste est '
            'simplement ∫f.';
      case 'exprDoesNotDependOn':
        return '${p['expr']} ne dépend pas de ${p['var']}.';
      case 'integralIdentityPower1':
        return 'La règle des puissances pour n=1 : monte l\'exposant à 2 '
            'et divise par le nouvel exposant.';
      case 'integralLinearity':
        return 'L\'intégration est linéaire : l\'intégrale d\'une somme '
            'est la somme des intégrales.';
      case 'integralPullConstantOut':
        return 'Sors `${p['const']}` de l\'intégrale — les constantes se '
            'factorisent.';
      case 'integralReciprocalLog':
        return 'L\'intégrale de 1/${p['var']} est le logarithme naturel '
            'de sa valeur absolue.';
      case 'integralPowerRule':
        return 'Augmente l\'exposant de 1 et divise par le nouvel '
            'exposant. Valable pour toute constante n ≠ −1.';
      case 'uSubLinear':
        return 'Pose u = ${p['u']} ; alors du = '
            '(${p['slope']})·d${p['var']}.';
      case 'integralStandardAntideriv':
        return 'Utilise la primitive standard de ${p['fn']}.';
      case 'uSubLinearFn':
        return 'Pose u = ${p['u']} ; alors du = '
            '(${p['slope']})·d${p['var']}. La primitive de ${p['fn']} est '
            'la forme standard, évaluée en u et divisée par la pente.';
      case 'ibpLnX':
        final v = p['var']!;
        return 'Pose u = ln($v), dv = d$v. Alors du = (1/$v)·d$v et '
            'v = $v, donc ∫u·dv = u·v − ∫v·du = $v·ln($v) − ∫1 d$v.';
      case 'ibpXTimesF':
        return 'Pose u = ${p['var']} (donc du = d${p['var']}) et '
            'dv = ${p['right']}·d${p['var']}, ce qui donne v = ${p['v']}.';
      case 'ibpRepeated':
        return 'Pose u = ${p['u']} et dv = ${p['right']}·d${p['var']}. '
            'Alors du = ${p['n']}·… (une puissance de ${p['var']} en moins) '
            'et v = ${p['v']}, et la nouvelle intégrale perd une puissance '
            'de ${p['var']} — récursion.';
      case 'uSubNonlinear':
        return 'Pose u = ${p['u']} ; alors du = (${p['du']})·d${p['var']}. '
            'L\'intégrande a la forme f(u)·du, donc la substitution donne '
            '∫f(u) du = primitive standard de ${p['fn']} évaluée en u'
            '${p['ratio'] == '1' ? '.' : ', multipliée par le facteur constant ${p['ratio']}.'}';
      case 'integralLogDerivative':
        return 'Le numérateur vaut (${p['ratio']})·(d/d${p['var']}[${p['den']}]), '
            'donc l\'intégrale est ${p['ratio']}·ln|${p['den']}|.';
      case 'partialFractions':
        return 'Le dénominateur a des racines entières distinctes '
            '${p['roots']}. La méthode du masque donne '
            'A_i = P(r_i) / Q\'(r_i) pour chaque racine.';
      case 'partialFractionsIntegrate':
        return 'Chaque terme `A/(x-r)` s\'intègre en A·ln|x-r|.';
      case 'trigArctanForm':
        return 'Pose a² = ${p['aSq']}, donc a = ${p['a']}. La forme '
            'standard donne (1/a)·arctan(${p['var']}/a).';
      case 'trigArcsinForm':
        return 'Pose a² = ${p['aSq']}, donc a = ${p['a']}. La forme '
            'standard donne arcsin(${p['var']}/a).';
      case 'integralFallthroughSymbolic':
        return 'Aucune règle classique ne correspond à cette forme — la '
            'réponse est confiée à l\'intégrateur symbolique.';
      case 'diffIdentity':
        return 'La dérivée de ${p['var']} par rapport à elle-même vaut 1.';
      case 'diffSumDifference':
        return 'Dérive chaque terme séparément ; la dérivation se '
            'distribue sur `+` et `−`.';
      case 'diffQuotient':
        return 'Pour un quotient, le numérateur devient `f′g − fg′` et le '
            'dénominateur est mis au carré.';
      case 'diffProduct':
        return 'Pour un produit, dérive chaque facteur et additionne les '
            'morceaux — `(fg)′ = f′g + fg′`.';
      case 'diffPowerSimple':
        return 'Descends l\'exposant comme coefficient et diminue '
            'l\'exposant de 1.';
      case 'diffPowerChain':
        return 'Descends l\'exposant et diminue-le de 1, puis multiplie '
            'par la dérivée de la base — ce facteur '
            '`d/d${p['var']}[${p['base']}]` est la règle de la chaîne.';
      case 'diffExponential':
        return 'Quand la variable est en exposant, la dérivée est la même '
            'expression multipliée par `ln(base)` et par la dérivée de '
            'l\'exposant.';
      case 'diffStandardSimple':
        return 'Applique la dérivée standard de ${p['fn']}.';
      case 'diffStandardChain':
        return 'L\'argument dépend de ${p['var']}, donc multiplie par sa '
            'dérivée (règle de la chaîne).';
      case 'diffFallthrough':
        return 'Aucun motif de règle de plus haut niveau reconnu pour '
            'cette forme.';
    }
    return null;
  }
}

class EsLocalizations implements AppLocalizations {
  const EsLocalizations();

  @override
  String get navCalculator => 'Calculadora';
  @override
  String get navGraphing => 'Gráficos';
  @override
  String get navFunctions => 'Funciones';
  @override
  String get navAnalysis => 'Análisis';
  @override
  String get navSettings => 'Ajustes';

  @override
  String get historyHere => 'El historial de cálculos aparecerá aquí.';
  @override
  String get historyLabel => 'Historial:';
  @override
  String get clearButton => 'C';
  @override
  String get clearHistory => 'Borrar historial';
  @override
  String get clearHistoryConfirm =>
      '¿Eliminar todas las entradas del historial de cálculos?';
  @override
  String get searchHistory => 'Buscar en el historial';
  @override
  String get searchHistoryHint => 'Filtrar historial…';
  @override
  String get historyNoMatches => 'No hay entradas coincidentes.';

  @override
  String graphingTitle(int count) => 'Gráficos ($count funciones)';
  @override
  String functionAdded(int slot) => 'Función añadida a Y$slot';
  @override
  String functionRemoved(int slot) => 'Y$slot eliminada';
  @override
  String get allSlotsFull =>
      'Todas las posiciones de función están ocupadas. Borra una primero.';
  @override
  String get clearAllFunctions => 'Borrar todas las funciones';
  @override
  String get clearAllFunctionsConfirm =>
      '¿Seguro que quieres borrar todas las funciones representadas?';
  @override
  String get cancel => 'Cancelar';
  @override
  String get clearAll => 'Borrar todo';
  @override
  String get zoomIn => 'Acercar';
  @override
  String get zoomOut => 'Alejar';
  @override
  String get resetView => 'Restablecer vista';
  @override
  String get showKeypad => 'Mostrar teclado';
  @override
  String get hideKeypad => 'Ocultar teclado';
  @override
  String get showAnnotations => 'Mostrar raíces y extremos';
  @override
  String get hideAnnotations => 'Ocultar raíces y extremos';
  @override
  String get analyzeFunctions => 'Analizar funciones';
  @override
  String get selectFunctionToAnalyze => 'Selecciona la función a analizar';
  @override
  String get plotButton => 'Representar';
  @override
  String get enterFunctionPrompt =>
      'Escribe una función abajo para representarla.';

  @override
  String get analysisModulesTitle => 'Módulos de análisis';
  @override
  String get moduleCurveSketching => 'Estudio de funciones';
  @override
  String get moduleCurveSketchingSubtitle =>
      'Análisis completo de una función f(x)';
  @override
  String get modulePlanes => 'Planos';
  @override
  String get modulePlanesSubtitle =>
      'Analiza planos 3D en forma cartesiana o paramétrica';
  @override
  String get moduleConics => 'Cónicas';
  @override
  String get moduleConicsSubtitle =>
      'Clasifica Ax² + Bxy + Cy² + Dx + Ey + F = 0';
  @override
  String get moduleStatistics => 'Estadística';
  @override
  String get moduleStatisticsSubtitle =>
      'Estadística descriptiva, regresión lineal, distribuciones normal y binomial';
  @override
  String get module3DTitle => 'Gráfica 3D';
  @override
  String get module3DSubtitle =>
      'Representa z = f(x, y) como superficie rotable de alambre';
  @override
  String get module3DFunctionLabel => 'f(x, y)';
  @override
  String get module3DRangeLabel => 'Rango';
  @override
  String get module3DResample => 'Remuestrear cuadrícula';
  @override
  String get module3DTapPlot =>
      'Introduce una función de x e y y pulsa Representar.';
  @override
  String get moduleUnitConverterTitle => 'Conversor de unidades';
  @override
  String get moduleUnitConverterSubtitle =>
      'Convierte longitud, tiempo, masa, temperatura, velocidad, ángulo';
  @override
  String get sectionVariables => 'Variables';
  @override
  String get sectionGraphFunctions => 'Funciones gráficas';
  @override
  String get sectionMemorySlots => 'Espacios de memoria';
  @override
  String get funcCtxShowOnGraph => 'Mostrar en la gráfica';
  @override
  String get funcCtxAnalyze => 'Analizar (estudio de la función)';
  @override
  String get funcCtxDifferentiate => 'Derivar';
  @override
  String get funcCtxIntegrate => 'Integrar';
  @override
  String get funcCtxSolve => 'Resolver f(x) = 0';
  @override
  String get funcCtxCopy => 'Copiar expresión';
  @override
  String get funcEditorTitle => 'Editor de funciones (Y=)';
  @override
  String get funcEditorDone => 'Listo';
  @override
  String get funcEditorSelectFirst =>
      'Selecciona un campo de función para editar.';
  @override
  String get funcEditorAnalyzeTooltip => 'Analizar esta función';
  @override
  String get funcEditorGraphTooltip => 'Representar esta función';
  @override
  String get unitDimLength => 'Longitud';
  @override
  String get unitDimTime => 'Tiempo';
  @override
  String get unitDimMass => 'Masa';
  @override
  String get unitDimTemperature => 'Temperatura';
  @override
  String get unitDimVelocity => 'Velocidad';
  @override
  String get unitDimAngle => 'Ángulo';
  @override
  String get planeAnalysisTitle => 'Análisis de plano';
  @override
  String get planeRepCoordinate => 'Coordenadas';
  @override
  String get planeRepParametric => 'Paramétrica';
  @override
  String get buttonAnalyze => 'Analizar';
  @override
  String get buttonClassify => 'Clasificar';
  @override
  String get curveAnalysisEnterFunction =>
      'Introduce una función para analizar:';
  @override
  String get curveResultWarnings => 'Advertencias';
  @override
  String get curveResultDerivatives => 'Derivadas';
  @override
  String get curveResultKeyPoints => 'Puntos clave';
  @override
  String get curveResultYIntercept => 'Intersección con Y';
  @override
  String get curveResultRoots => 'Raíces';
  @override
  String get curveResultExtrema => 'Extremos (Mínimos/Máximos)';
  @override
  String get curveResultInflectionPoints => 'Puntos de inflexión';
  @override
  String get curveResultNoExtrema => 'No se encontraron extremos.';
  @override
  String get curveResultNoInflection =>
      'No se encontraron puntos de inflexión.';
  @override
  String curveAnalysisOfFunction(String function) =>
      'Análisis de f(x) = $function';
  @override
  String curveResultPointPrefix(String point) => 'Punto: $point';
  @override
  String get extremumLocalMinimum => 'Mínimo local';
  @override
  String get extremumLocalMaximum => 'Máximo local';
  @override
  String get extremumCriticalPoint => 'Punto crítico';
  @override
  String get extremumInflectionPoint => 'Punto de inflexión';
  @override
  String get extremumNoCriticalPoints => 'No se encontraron puntos críticos';
  @override
  String get extremumConstantConcavity =>
      'La función tiene concavidad constante (f\'\'(x) = 0 en todas partes)';
  @override
  String get statisticsTitle => 'Estadística';
  @override
  String get statsTabDescriptive => 'Descriptiva';
  @override
  String get statsTabRegression => 'Regresión';
  @override
  String get statsTabDistributions => 'Distribuciones';
  @override
  String get statsTabTests => 'Pruebas';
  @override
  String get statsDescCount => 'Conteo';
  @override
  String get statsDescSum => 'Suma';
  @override
  String get statsDescMean => 'Media';
  @override
  String get statsDescMedian => 'Mediana';
  @override
  String get statsDescMode => 'Moda';
  @override
  String get statsDescMin => 'Mín';
  @override
  String get statsDescMax => 'Máx';
  @override
  String get statsDescRange => 'Rango';
  @override
  String get statsDescVariance => 'Varianza';
  @override
  String get statsDescStddev => 'Desviación típica';
  @override
  String get statsDescQ1 => 'Q1';
  @override
  String get statsDescQ3 => 'Q3';
  @override
  String get statsDescIqr => 'RIQ';
  @override
  String get helpGroupProbability => 'Probabilidad';
  @override
  String get helpFnRrefDescription =>
      'Forma escalonada reducida (Gauss-Jordan)';

  @override
  String get settingsTitle => 'Ajustes';
  @override
  String get settingsNumberFormat => 'Formato numérico';
  @override
  String get settingsNumberFormatAuto => 'Auto (129; 129,5)';
  @override
  String get settingsNumberFormatInteger => 'Entero (129)';
  @override
  String get settingsNumberFormatOneDecimal => 'Un decimal (129,0)';
  @override
  String get settingsNumberFormatTwoDecimal => 'Dos decimales (129,00)';
  @override
  String get settingsLanguage => 'Idioma';
  @override
  String get settingsLanguageEnglish => 'English';
  @override
  String get settingsLanguageGerman => 'Deutsch';
  @override
  String get settingsLanguageFrench => 'Français';
  @override
  String get settingsLanguageSpanish => 'Español';
  @override
  String get settingsTheme => 'Tema';
  @override
  String get settingsThemeSystem => 'Según el sistema';
  @override
  String get settingsThemeLight => 'Claro';
  @override
  String get settingsThemeDark => 'Oscuro';
  @override
  String get settingsLayoutTitle => 'Diseño';
  @override
  String get settingsLayoutBody =>
      'CrispCalc se adapta al ancho de la ventana: navegación inferior en '
      'móviles, raíl lateral en tabletas y escritorio. A partir de ~760 px '
      'el teclado muestra todas las teclas sin pestañas.';

  @override
  String get aboutTitle => 'Acerca de CrispCalc';
  @override
  String get aboutTagline => 'Calculadora CAS simbólica basada en SymEngine';
  @override
  String aboutVersion(String version) => 'Versión $version';
  @override
  String get aboutServiceProvider => 'Proveedor';
  @override
  String get aboutContact => 'Contacto';
  @override
  String get aboutPrivacy => 'Privacidad';
  @override
  String get aboutPrivacyText =>
      'CrispCalc funciona íntegramente en el dispositivo. Ningún cálculo, '
      'entrada del historial o variable de usuario se envía a un servidor. '
      'La aplicación no recopila datos de telemetría ni contacta servicios '
      'remotos.';
  @override
  String get aboutDisclaimer => 'Aviso legal';
  @override
  String get aboutDisclaimerText =>
      'CrispCalc se ofrece «tal cual», sin garantía alguna. El motor '
      'simbólico puede devolver resultados imprecisos para entradas '
      'numéricas mal condicionadas o expresiones simbólicas no '
      'soportadas. Verifica de forma independiente los cálculos críticos.';
  @override
  String get aboutLicense => 'Licencia';
  @override
  String get aboutLicenseText =>
      'CrispCalc es software libre publicado bajo la GNU Affero General '
      'Public License versión 3 o posterior. Esta elección se debe a los '
      'requisitos de copyleft de las bibliotecas GMP/MPFR/MPC/FLINT '
      'incluidas, enlazadas estáticamente.';
  @override
  String get aboutOpenSourceLicenses => 'Licencias de código abierto';
  @override
  String get settingsAbout => 'Acerca de CrispCalc';
  @override
  String get matrixDiagnosticsTitle => 'Autoprueba de matrices';
  @override
  String get matrixDiagnosticsSubtitle =>
      'Comprobar det / inv / transpose / + / * vía el puente nativo.';
  @override
  String matrixDiagnosticsSummary(int passed, int total) =>
      '$passed de $total comprobaciones superadas';
  @override
  String get unitConverterTitle => 'Conversor de unidades';
  @override
  String get unitConverterSubtitle =>
      'Longitud / tiempo / masa / temperatura / velocidad / ángulo.';

  @override
  String get selectEquation => 'Selecciona una ecuación o sigue escribiendo:';
  @override
  String get continueTyping => 'Continuar escribiendo';
  @override
  String get selectFunction => 'Selecciona una función o sigue escribiendo:';
  @override
  String get dismissPanel => 'Cerrar este panel';
  @override
  String solveFor(int n) => 'Resolver Y$n = 0';
  @override
  String whereY(int n, String func) => 'donde Y$n = $func';

  @override
  String get dialogInsert => 'Insertar';
  @override
  String get dialogClose => 'Cerrar';
  @override
  String get dialogShowSteps => 'Ver pasos';
  @override
  String get dialogVariable => 'Variable';
  @override
  String get dialogExpression => 'Expresión';
  @override
  String get dialogValue => 'Valor';
  @override
  String get dialogFunction => 'Función f(x)';

  @override
  String get integralTitle => 'Integral';
  @override
  String get integralLowerBound => 'Límite inferior';
  @override
  String get integralUpperBound => 'Límite superior';
  @override
  String get integralDefinite => 'Integral definida';
  @override
  String get nthRootTitle => 'Raíz n-ésima';
  @override
  String get nthRootBase => 'Base';
  @override
  String get limitTitle => 'Límite';
  @override
  String get limitApproaches => 'tiende a';
  @override
  String get substituteTitle => 'Sustituir';
  @override
  String get substituteUseStoredVariable =>
      'Usar una variable guardada como valor:';

  @override
  String get differentiationStepsTitle => 'Pasos de derivación';
  @override
  String differentiationStepsHeader(String variable) =>
      'Derivando respecto a $variable:';
  @override
  String get solveStepsTitle => 'Pasos de resolución';
  @override
  String get solveStepsEquationLabel => 'Ecuación o expresión';
  @override
  String get solveStepsSolveFor => 'Resolver para';
  @override
  String get solveStepsHint => 'p. ej. 2x + 3 = 7  o  x^2 - 5x + 6';
  @override
  String solveStepsHeader(String variable) => 'Resolviendo para $variable:';
  @override
  String get integrationStepsTitle => 'Pasos de integración';
  @override
  String get integrationStepsIntegrandLabel => 'Integrando';
  @override
  String get integrationStepsWrt => 'Integrar respecto a';
  @override
  String get integrationStepsHint => 'p. ej. x^2  o  sin(x) + 2x';
  @override
  String integrationStepsHeader(String variable) =>
      'Integrando respecto a $variable:';

  @override
  String get errorSolveFormat =>
      'Error: el formato de solve() es solve(ecuación, variable)';
  @override
  String get errorInvalidSolve => 'Error: sintaxis de solve() inválida';
  @override
  String get errorInvalidDiff => 'Error: sintaxis de d/dx() inválida';
  @override
  String get errorInvalidFactor => 'Error: sintaxis de factor() inválida';
  @override
  String get errorInvalidExpand => 'Error: sintaxis de expand() inválida';
  @override
  String get errorInvalidSimplify => 'Error: sintaxis de simplify() inválida';
  @override
  String get errorGcdArgs => 'Error: gcd() requiere exactamente 2 argumentos';
  @override
  String get errorInvalidGcd => 'Error: sintaxis de gcd() inválida';
  @override
  String get errorLcmArgs => 'Error: lcm() requiere exactamente 2 argumentos';
  @override
  String get errorInvalidLcm => 'Error: sintaxis de lcm() inválida';

  @override
  String get errorParse =>
      'No se pudo analizar la expresión. Revisa paréntesis sin pareja, erratas u operadores ausentes.';
  @override
  String get errorNativeRequired =>
      'Esta operación necesita la biblioteca matemática nativa, no cargada en esta plataforma.';
  @override
  String get errorIntegrateNotImplemented =>
      'La integración simbólica no está disponible en esta versión. Usa ∫ con límites para un resultado numérico (definido).';
  @override
  String get errorMatrixLiteral =>
      'El literal de matriz no es válido. Usa el formato [a,b; c,d] o el editor de matrices.';
  @override
  String get errorInternalMatrixDisposed =>
      'La referencia interna a la matriz ya no es válida. Vuelve a ejecutar la operación.';
  @override
  String errorInvalidSyntax(String op) =>
      'Los argumentos pasados a $op() no tenían el formato esperado. Consulta el ejemplo en la ayuda / Acerca de.';

  @override
  String get exportDataTitle => 'Exportar datos';
  @override
  String get exportDataSubtitle =>
      'El JSON de abajo contiene todo lo que CrispCalc ha guardado en este dispositivo: historial, variables, funciones, parámetros, ajustes. Cópialo a una nota o documento en la nube antes de reinstalar.';
  @override
  String get exportDataCopy => 'Copiar al portapapeles';
  @override
  String get exportDataCopied => 'Copiado al portapapeles';
  @override
  String get historyEntryCopyResult => 'Copiar resultado';
  @override
  String get historyEntryCopyLatex => 'Copiar como LaTeX';
  @override
  String get historyEntryCopyLatexSubtitle =>
      'Pegar en Word/Notion/Markdown para matemáticas con formato';
  @override
  String get historyEntryReuse => 'Reutilizar expresión';
  @override
  String get historyEntryCopied => 'Copiado';

  @override
  String get settingsExportData => 'Exportar datos';
  @override
  String get settingsExportDataSubtitle =>
      'Copia todo lo guardado en este dispositivo (historial, variables, ajustes).';
  @override
  String get settingsHelp => 'Ayuda y referencia de funciones';
  @override
  String get settingsHelpSubtitle =>
      'Funciones soportadas, sintaxis de matrices y disparadores paso a paso.';

  @override
  String get settingsExactIntegerMode => 'Modo entero exacto';
  @override
  String get settingsExactIntegerModeSubtitle =>
      'Mostrar la cadena completa de dígitos para resultados enteros de '
      'precisión arbitraria (p. ej. 100! = 158 dígitos). Desactivado: '
      'redondear a precisión double.';
  @override
  String exactIntegerBadge(int digits) => 'Entero exacto · $digits dígitos';
  @override
  String get exactIntegerTapToCopy => 'Toca para copiar';

  @override
  String get calculating => 'Calculando…';

  @override
  String get moduleSudokuTitle => 'Sudoku';
  @override
  String get moduleSudokuSubtitle =>
      'Resuelve cuadrículas 4×4 y 9×9, sigue la búsqueda paso a paso.';
  @override
  String get sudokuSolveButton => 'Resolver';
  @override
  String get sudokuClearCell => 'Borrar';
  @override
  String get sudokuPresetLabelChooser => 'Cuadrícula';
  @override
  String get sudokuPresetCustom => 'Personalizada';
  @override
  String sudokuPresetLabel(String id) {
    switch (id) {
      case 'small4x4Easy':
        return '4×4 fácil';
      case 'small4x4Medium':
        return '4×4 medio';
      case 'small4x4Hard':
        return '4×4 difícil';
      case 'medium6x6':
        return '6×6 medio';
      case 'standard9x9Easy':
        return '9×9 fácil';
      case 'standard9x9Medium':
        return '9×9 medio';
      case 'standard9x9Hard':
        return '9×9 difícil (AI Escargot)';
      case 'standard9x9XEasy':
        return '9×9 Sudoku-X fácil';
    }
    return id;
  }

  @override
  String get sudokuVisualizerHeader => 'Visualizador de búsqueda';
  @override
  String get sudokuPlay => 'Reproducir';
  @override
  String get sudokuPause => 'Pausa';
  @override
  String get sudokuRestart => 'Reiniciar';
  @override
  String get sudokuSpeedSlow => 'Lento';
  @override
  String get sudokuSpeedMed => 'Medio';
  @override
  String get sudokuSpeedFast => 'Rápido';
  @override
  String get sudokuGenerateButton => 'Generar';
  @override
  String get sudokuDifficultyEasy => 'Fácil';
  @override
  String get sudokuDifficultyMedium => 'Medio';
  @override
  String get sudokuDifficultyHard => 'Difícil';
  @override
  String get sudokuVariantRegular => 'Clásico';
  @override
  String get sudokuVariantX => 'Sudoku-X';

  @override
  String get moduleConstraintsTitle => 'Problemas de restricciones';
  @override
  String get moduleConstraintsSubtitle =>
      'Ecuaciones diofánticas y criptoaritmos — encontrar soluciones '
      'enteras y asignaciones de dígitos.';
  @override
  String get constraintsTabDiophantine => 'Diofántico';
  @override
  String get constraintsTabCryptarithm => 'Criptoaritmo';
  @override
  String get constraintsDiophantineIntro =>
      'Declara variables enteras acotadas, lista las restricciones a '
      'satisfacer — el solver enumera todas las soluciones enteras '
      '(limitado a 100).';
  @override
  String get constraintsCryptarithmIntro =>
      'Introduce un puzzle de la forma `PALABRA1 + PALABRA2 = '
      'PALABRA3` (o `−` en vez de `+`). Cada letra es un dígito 0..9; '
      'los dígitos de cabecera no son cero; todas las letras llevan '
      'dígitos distintos.';
  @override
  String get constraintsVariablesLabel => 'Variables';
  @override
  String get constraintsVariablesHint =>
      'Una por línea, formato: name in min..max';
  @override
  String get constraintsConstraintsLabel => 'Restricciones';
  @override
  String get constraintsConstraintsHint =>
      'Una por línea. Comparaciones, aritmética, in/not-in conjuntos '
      'todos soportados.';
  @override
  String get constraintsCryptarithmInputLabel => 'Puzzle';
  @override
  String get constraintsSolveButton => 'Resolver';
  @override
  String get constraintsBadVarLine =>
      'No se pudo analizar la línea de variable. Esperado: '
      '`name in min..max`';
  @override
  String get constraintsNoSolutions => 'Sin soluciones.';
  @override
  String get constraintsCryptarithmFoundHeader => 'Asignación de dígitos';
  @override
  String constraintsSolutionsHeader(int n) =>
      n == 1 ? '1 solución' : '$n soluciones';
  @override
  String constraintsTruncatedHeader(int n) =>
      'Mostrando las primeras $n soluciones (existen más)';
  @override
  String get constraintsCopyResult => 'Copiar soluciones';
  @override
  String get constraintsCopiedToast => 'Copiado al portapapeles.';

  @override
  String get clearSearchTooltip => 'Borrar búsqueda';
  @override
  String get clearFunctionSlotTooltip => 'Borrar función';
  @override
  String get deleteMemorySlotTooltip => 'Eliminar espacio de memoria';

  @override
  String get workedExamplesTitle => 'Ejemplos resueltos';
  @override
  String get workedExamplesSearchHint => 'Buscar ejemplos…';
  @override
  String get workedExamplesEmpty => 'Ningún ejemplo coincide con el filtro.';
  @override
  String get workedExamplesCopy => 'Copiar expresión';
  @override
  String get workedExamplesCopied =>
      'Copiado al portapapeles. Pega en la calculadora para probarlo.';
  @override
  String get workedExamplesInsert => 'Insertar en la calculadora';
  @override
  String get workedExamplesCatAll => 'Todos';
  @override
  String get workedExamplesCatCalculus => 'Cálculo';
  @override
  String get workedExamplesCatAlgebra => 'Álgebra';
  @override
  String get workedExamplesCatLinearAlgebra => 'Álgebra lineal';
  @override
  String get workedExamplesCatNumberTheory => 'Teoría de números';
  @override
  String get workedExamplesCatStatistics => 'Estadística';
  @override
  String get workedExamplesCatUnits => 'Unidades';
  @override
  String? workedExampleTitle(String id) {
    switch (id) {
      case 'derivPoly':
        return 'Derivada de un polinomio';
      case 'chainRule':
        return 'Ejemplo de la regla de la cadena';
      case 'integralByParts':
        return 'Integral indefinida por partes';
      case 'definiteIntegral':
        return 'Integral definida';
      case 'sinxOverX':
        return 'Límite en una singularidad evitable';
      case 'partialFractions':
        return 'Fracciones parciales';
      case 'quadraticFormula':
        return 'Fórmula cuadrática';
      case 'factorCubic':
        return 'Factorizar un polinomio';
      case 'expandBinomial':
        return 'Desarrollar un binomio';
      case 'simplifyRational':
        return 'Simplificar una expresión racional';
      case 'matrixDet':
        return 'Determinante de una matriz';
      case 'matrixInverse':
        return 'Inversa de una matriz';
      case 'rref':
        return 'Forma escalonada reducida por filas';
      case 'factorial100':
        return 'Factorial — entero exacto';
      case 'fibonacci50':
        return 'Número de Fibonacci';
      case 'gcdEuclid':
        return 'MCD por Euclides';
      case 'isprime':
        return 'Test de primalidad (n pequeño)';
      case 'compoundInterest':
        return 'Interés compuesto';
      case 'zScore':
        return 'Consulta de puntuación Z';
      case 'unitConversion':
        return 'Conversión de unidades en línea';
      case 'compositeDim':
        return 'Aritmética con dimensiones compuestas';
    }
    return null;
  }

  @override
  String? workedExampleDescription(String id) {
    switch (id) {
      case 'derivPoly':
        return 'd/dx de x³ − 4x + 7 en cualquier x.';
      case 'chainRule':
        return 'd/dx de sin(x²) — regla de la cadena sobre el x² interior.';
      case 'integralByParts':
        return '∫ x·sin(x) dx — toma u = x, dv = sin(x) dx.';
      case 'definiteIntegral':
        return '∫₀¹ x² dx = 1/3 por el teorema fundamental.';
      case 'sinxOverX':
        return 'lim x→0 sin(x)/x = 1 (el clásico).';
      case 'partialFractions':
        return '∫ 1/(x² − 1) dx por el método de cobertura en x = ±1.';
      case 'quadraticFormula':
        return 'Resuelve 2x² + 5x − 3 = 0 mediante el discriminante.';
      case 'factorCubic':
        return 'Factoriza x³ − 8 — suma/diferencia de cubos.';
      case 'expandBinomial':
        return 'Desarrolla (x + 2)⁵ — triángulo de Pascal.';
      case 'simplifyRational':
        return 'Reduce (x² − 4)/(x − 2) a su forma más simple.';
      case 'matrixDet':
        return 'det de una 3×3 — desarrollo de Laplace o reducción.';
      case 'matrixInverse':
        return 'Inversa de una 2×2 — A⁻¹ = adj(A)/det(A).';
      case 'rref':
        return 'rref de un sistema 2×3 aumentado.';
      case 'factorial100':
        return '100! — 158 dígitos, conservados en modo entero exacto.';
      case 'fibonacci50':
        return 'fib(50) — recurrencia hasta un término grande.';
      case 'gcdEuclid':
        return 'gcd(252, 105) — la recurrencia original.';
      case 'isprime':
        return 'isprime(2027) — división de prueba rápida.';
      case 'compoundInterest':
        return '1000 € al 5 % durante 10 años, capitalización anual.';
      case 'zScore':
        return 'Ve a la pantalla Estadística → Distribuciones para '
            'calcular Φ(1,96) ≈ 0,975.';
      case 'unitConversion':
        return '100 km/h convertido a mph — analizador inline V2.';
      case 'compositeDim':
        return '100 m / 10 s da una velocidad en m/s — analizador V5.';
    }
    return null;
  }

  @override
  String get settingsWorkedExamples => 'Biblioteca de ejemplos resueltos';
  @override
  String get settingsWorkedExamplesSubtitle =>
      'Explora y copia expresiones de la calculadora listas para pegar '
      'que cubren los principales tipos de problemas.';

  @override
  String get importDataTitle => 'Importar datos';
  @override
  String get importDataSubtitle =>
      'Pega un JSON de una exportación anterior para restaurar el '
      'historial, las variables, las funciones y los ajustes.';
  @override
  String get importDataWarning =>
      'Esto sobrescribe el historial actual, las variables y las '
      'funciones gráficas. No hay deshacer — copia primero el estado '
      'actual si quieres conservarlo.';
  @override
  String get importDataApply => 'Aplicar';
  @override
  String get importDataEmpty => 'Pega un JSON para importar.';
  @override
  String get importDataNotObject =>
      'El JSON debe ser un objeto (empieza con `{`).';
  @override
  String get importDataApplied => 'Importado';
  @override
  String get settingsImportData => 'Importar datos';
  @override
  String get settingsImportDataSubtitle =>
      'Pega un JSON de una exportación anterior para restaurar.';

  @override
  String get userFunctionsTitle => 'Funciones definidas por el usuario';
  @override
  String get userFunctionsHelp =>
      'Define una función una vez, llámala desde cualquier expresión. '
      'P. ej. `f(x) = x^2 + 1`, entonces `f(3) + 1` evalúa a 11. La '
      'composición `g(f(x))` funciona mientras ambas estén definidas.';
  @override
  String get userFunctionsEmpty =>
      'Aún no hay funciones definidas por el usuario. Pulsa Añadir para '
      'crear la primera.';
  @override
  String get userFunctionsAdd => 'Añadir';
  @override
  String get userFunctionsEdit => 'Editar';
  @override
  String get userFunctionsDelete => 'Eliminar';
  @override
  String get userFunctionsName => 'Nombre';
  @override
  String get userFunctionsNameHelp =>
      'Una sola letra minúscula (a..z) que no entre en conflicto con '
      'nombres integrados.';
  @override
  String get userFunctionsNameRequired => 'Obligatorio';
  @override
  String get userFunctionsNameInvalid =>
      'Debe ser una sola letra minúscula (a..z).';
  @override
  String get userFunctionsParam => 'Parámetro';
  @override
  String get userFunctionsBody => 'Cuerpo';
  @override
  String get userFunctionsBodyRequired => 'Cuerpo de la función requerido';
  @override
  String get settingsUserFunctions => 'Funciones definidas por el usuario';
  @override
  String get settingsUserFunctionsSubtitle =>
      'Define funciones con nombre como f(x) = x^2 + 1 y reutilízalas en '
      'cualquier expresión.';

  @override
  String get onboardingSkip => 'Omitir';
  @override
  String get onboardingNext => 'Siguiente';
  @override
  String get onboardingDone => 'Entendido';
  @override
  String onboardingPage(int current, int total) => '$current / $total';
  @override
  String get onboardingKeypadTitle => 'Teclado con pestañas';
  @override
  String get onboardingKeypadBody =>
      'Cambia entre las pestañas Núm, Trig, CAS y Avanzado para '
      'encontrar la operación que necesitas. En ventanas más anchas '
      'todo el teclado cabe en una sola pantalla — sin pestañas.';
  @override
  String get onboardingHistoryTitle => 'Desplaza por el historial';
  @override
  String get onboardingHistoryBody =>
      'Cada cálculo se guarda. Desplázate hacia arriba para revisarlo, '
      'mantén pulsado para copiar o reutilizar, toca el icono de '
      'búsqueda para filtrar.';
  @override
  String get onboardingFunctionsTitle => 'Elegir una función';
  @override
  String get onboardingFunctionsBody =>
      'Los botones ∫⌄, d/dx⌄ y solve⌄ abren selectores paso a paso '
      'que explican la respuesta regla por regla.';
  @override
  String get onboardingAnalysisTitle => 'Centro de análisis';
  @override
  String get onboardingAnalysisBody =>
      'Estudio de curvas, planos, cónicas, gráficos 3D, estadística y '
      'el conversor de unidades están todos en la pestaña Análisis.';
  @override
  String get settingsReplayTour => 'Repetir la visita guiada';
  @override
  String get settingsReplayTourSubtitle =>
      'Mostrar la visita de primer inicio la próxima vez que abras la '
      'aplicación.';

  @override
  String get helpTitle => 'Ayuda';
  @override
  String get helpFunctionsHeading => 'Funciones soportadas';
  @override
  String get helpMatrixHeading => 'Sintaxis de matrices';
  @override
  String get helpStepsHeading => 'Soluciones paso a paso';
  @override
  String get helpMatrixBody =>
      'Escribe matrices con `;` para filas y `,` para celdas:\n\n    [1, 2; 3, 4]\n\nLa calculadora lo convierte internamente a `Matrix([[1, 2], [3, 4]])`. Operaciones: det, inv, transpose, rref, +, -, *.';
  @override
  String get helpStepsBody =>
      'Tres botones del teclado CAS abren trazas paso a paso:\n\n  • d/dx⌄ para pasos de derivación\n  • solve⌄ para resolución de ecuaciones\n  • ∫⌄ para integración indefinida\n\nCada vista muestra la regla aplicada en cada paso más la respuesta final.';

  @override
  String get constantsTitle => 'Referencia de constantes';
  @override
  String get constantsSearchHint => 'Buscar por símbolo, nombre o unidad…';
  @override
  String get constantsNoMatches =>
      'Ninguna constante coincide con este filtro.';
  @override
  String get constantsAllCategory => 'Todas';
  @override
  String get constantsCategoryMathematical => 'Matemáticas';
  @override
  String get constantsCategoryPhysical => 'Física';
  @override
  String get constantsCategoryChemistry => 'Química';
  @override
  String get constantsCategoryAstronomy => 'Astronomía';
  @override
  String get constantsCopyValue => 'Copiar valor';
  @override
  String constantsCopiedToast(String symbol) =>
      '$symbol copiado al portapapeles';
  @override
  String get settingsConstants => 'Referencia de constantes';
  @override
  String get settingsConstantsSubtitle =>
      'Constantes físicas, matemáticas, químicas y astronómicas.';

  @override
  String get tabNum => 'Núm';
  @override
  String get tabTrig => 'Trig';
  @override
  String get tabCas => 'CAS';
  @override
  String get tabAdvanced => 'Avanzado';
  @override
  String get tabVars => 'Variables';
  @override
  String get tabBasic => 'Básico';
  @override
  String get tabSymbolic => 'Simbólico';

  @override
  String? stepNote(StepNote note) {
    final p = note.params;
    switch (note.key) {
      case 'startEquation':
        return 'Partimos de la ecuación tal como está dada.';
      case 'moveRightSideOver':
        return 'Restar el lado derecho en ambos lados deja la ecuación en '
            'la forma estándar `expresión = 0`, lo que permite aplicar el '
            'solver lineal o cuadrático.';
      case 'noEqualsSign':
        return 'No hay `=` en la entrada; se trata como '
            '${p['body']} = 0.';
      case 'doesNotDependOn':
        return 'La ecuación no depende de ${p['var']}.';
      case 'solveFallthroughSymbolic':
        return 'No es una forma lineal o cuadrática estándar — la '
            'respuesta la calcula el solver simbólico.';
      case 'linearIdentifyCoefs':
        return 'Identifica el coeficiente principal y el término '
            'constante — esta es una ecuación lineal.';
      case 'moveConstant':
        return 'Pasa la constante al otro lado.';
      case 'divideByCoef':
        return 'Divide ambos lados entre el coeficiente principal para '
            'despejar ${p['var']}.';
      case 'quadraticIdentifyCoefs':
        return 'Lee los tres coeficientes en el polinomio. Tomamos a de '
            'la segunda derivada ÷ 2, b de la primera derivada en '
            '${p['var']} = 0, y c del polinomio en ${p['var']} = 0.';
      case 'discriminant':
        return 'El discriminante indica cuántas raíces reales hay: '
            'positivo → dos raíces reales distintas; cero → una raíz '
            'doble; negativo → dos raíces complejas conjugadas.';
      case 'quadFormulaApply':
        return 'Sustituye a, b y Δ en la fórmula cuadrática. El `±` '
            'entrega ambas raíces en un solo paso.';
      case 'integralPullMinusOut':
        return 'Saca el signo menos de la integral; el resto es '
            'simplemente ∫f.';
      case 'exprDoesNotDependOn':
        return '${p['expr']} no depende de ${p['var']}.';
      case 'integralIdentityPower1':
        return 'La regla de la potencia para n=1: sube el exponente a 2 '
            'y divide entre el nuevo exponente.';
      case 'integralLinearity':
        return 'La integración es lineal: la integral de una suma es la '
            'suma de las integrales.';
      case 'integralPullConstantOut':
        return 'Saca `${p['const']}` de la integral — las constantes '
            'se factorizan.';
      case 'integralReciprocalLog':
        return 'La integral de 1/${p['var']} es el logaritmo natural de '
            'su valor absoluto.';
      case 'integralPowerRule':
        return 'Sube el exponente en 1 y divide entre el nuevo '
            'exponente. Vale para cualquier constante n ≠ −1.';
      case 'uSubLinear':
        return 'Sea u = ${p['u']}; entonces du = '
            '(${p['slope']})·d${p['var']}.';
      case 'integralStandardAntideriv':
        return 'Usa la antiderivada estándar de ${p['fn']}.';
      case 'uSubLinearFn':
        return 'Sea u = ${p['u']}; entonces du = '
            '(${p['slope']})·d${p['var']}. La antiderivada de ${p['fn']} '
            'es la forma estándar, evaluada en u y dividida por la '
            'pendiente.';
      case 'ibpLnX':
        final v = p['var']!;
        return 'Sea u = ln($v), dv = d$v. Entonces du = (1/$v)·d$v y '
            'v = $v, así ∫u·dv = u·v − ∫v·du = $v·ln($v) − ∫1 d$v.';
      case 'ibpXTimesF':
        return 'Sea u = ${p['var']} (entonces du = d${p['var']}) y '
            'dv = ${p['right']}·d${p['var']}, dando v = ${p['v']}.';
      case 'ibpRepeated':
        return 'Sea u = ${p['u']} y dv = ${p['right']}·d${p['var']}. '
            'Entonces du = ${p['n']}·… (una potencia de ${p['var']} menos) '
            'y v = ${p['v']}, por lo que el nuevo integrando pierde una '
            'potencia de ${p['var']} — recursión.';
      case 'uSubNonlinear':
        return 'Sea u = ${p['u']}; entonces du = (${p['du']})·d${p['var']}. '
            'El integrando tiene la forma f(u)·du, así la sustitución '
            'lo convierte en ∫f(u) du = antiderivada estándar de ${p['fn']} '
            'evaluada en u'
            '${p['ratio'] == '1' ? '.' : ', multiplicada por el factor constante ${p['ratio']}.'}';
      case 'integralLogDerivative':
        return 'El numerador es (${p['ratio']})·(d/d${p['var']}[${p['den']}]), '
            'así que la integral es ${p['ratio']}·ln|${p['den']}|.';
      case 'partialFractions':
        return 'El denominador tiene raíces enteras distintas '
            '${p['roots']}. El método de cobertura da '
            'A_i = P(r_i) / Q\'(r_i) para cada raíz.';
      case 'partialFractionsIntegrate':
        return 'Cada término `A/(x-r)` se integra a A·ln|x-r|.';
      case 'trigArctanForm':
        return 'Iguala a² = ${p['aSq']}, así a = ${p['a']}. La forma '
            'estándar da (1/a)·arctan(${p['var']}/a).';
      case 'trigArcsinForm':
        return 'Iguala a² = ${p['aSq']}, así a = ${p['a']}. La forma '
            'estándar da arcsin(${p['var']}/a).';
      case 'integralFallthroughSymbolic':
        return 'Ninguna regla de libro de texto encaja con esta forma — '
            'la respuesta la calcula el integrador simbólico.';
      case 'diffIdentity':
        return 'La derivada de ${p['var']} con respecto a sí misma es 1.';
      case 'diffSumDifference':
        return 'Deriva cada término por separado; la derivación se '
            'distribuye sobre `+` y `−`.';
      case 'diffQuotient':
        return 'Para un cociente, el numerador queda `f′g − fg′` y el '
            'denominador se eleva al cuadrado.';
      case 'diffProduct':
        return 'Para un producto, deriva cada factor y suma las piezas '
            '— `(fg)′ = f′g + fg′`.';
      case 'diffPowerSimple':
        return 'Baja el exponente como coeficiente y reduce el exponente '
            'en 1.';
      case 'diffPowerChain':
        return 'Baja el exponente y redúcelo en 1, luego multiplica por '
            'la derivada de la base interna — ese factor '
            '`d/d${p['var']}[${p['base']}]` es la regla de la cadena.';
      case 'diffExponential':
        return 'Cuando la variable está en el exponente, la derivada es '
            'la misma expresión multiplicada por `ln(base)` y por la '
            'derivada del exponente.';
      case 'diffStandardSimple':
        return 'Aplica la derivada estándar de ${p['fn']}.';
      case 'diffStandardChain':
        return 'El argumento depende de ${p['var']}, así que multiplica '
            'por su derivada (regla de la cadena).';
      case 'diffFallthrough':
        return 'No se reconoce ningún patrón de regla de alto nivel para '
            'esta forma.';
    }
    return null;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const ['en', 'de', 'fr', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    final AppLocalizations resolved;
    switch (locale.languageCode) {
      case 'de':
        resolved = const DeLocalizations();
        break;
      case 'fr':
        resolved = const FrLocalizations();
        break;
      case 'es':
        resolved = const EsLocalizations();
        break;
      default:
        resolved = const EnLocalizations();
    }
    return SynchronousFuture<AppLocalizations>(resolved);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsExtensions on AppLocalizations {
  /// Best-effort translation of engine-emitted classification strings
  /// (e.g. "Local Minimum: (x, y)" → "Lokales Minimum: (x, y)"). Patterns
  /// match case-sensitively against the well-known English markers the
  /// analysis engine produces; unrecognized text passes through.
  ///
  /// Long markers (sentences) are tried before short labels so a string
  /// like "No inflection points found" doesn't get partially clobbered
  /// by the short labels.
  String translateClassification(String raw) {
    final replacements = <String, String>{
      'Function has constant concavity (f\'\'(x) = 0 everywhere)':
          extremumConstantConcavity,
      'No critical points found': extremumNoCriticalPoints,
      'No inflection points found': curveResultNoInflection,
      'Local Minimum': extremumLocalMinimum,
      'Local Maximum': extremumLocalMaximum,
      'Critical Point': extremumCriticalPoint,
      'Inflection Point': extremumInflectionPoint,
    };
    var out = raw;
    for (final entry in replacements.entries) {
      if (out.contains(entry.key)) out = out.replaceAll(entry.key, entry.value);
    }
    return out;
  }
}
