// lib/localization/app_localizations.dart
//
// Centralized i18n. Add a new locale by subclassing AppLocalizations and
// wiring it into the delegate at the bottom. Strings are grouped by feature
// so it's easy to spot what's missing when adding a language.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../engine/module_help_kind.dart';
import '../engine/step_engine.dart' show StepNote;

export '../engine/module_help_kind.dart' show ModuleHelpKind;

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const EnLocalizations();
  }

  // -- Nav destinations --
  String get navCalculator;
  String get navNotepad;
  String get navGraphing;
  String get navFunctions;
  String get navAnalysis;
  String get navSettings;

  // -- Notepad screen --
  String get notepadDefaultDocName;
  String get notepadAddLine;
  String get notepadDeleteLine;
  String get notepadDocumentMenu;
  String get notepadNewDocument;
  String get notepadOpenWelcomeSample;
  String get notepadRecalculateAll;
  String get notepadRename;
  String get notepadDuplicate;
  String get notepadCopyAsMarkdown;
  String get notepadDeleteDocument;
  String get notepadUndo;
  String get notepadLineDeleted;
  String notepadDocumentDeleted(String name);
  String get notepadCopiedAsMarkdown;
  String get notepadCopyResult;
  String get notepadCopyAsLatex;
  String get notepadCopiedResult;
  String get notepadCopiedAsLatex;
  String get notepadEmptyTitle;
  String get notepadEmptyBody;
  String notepadFreeVars(String names);
  String notepadBlockedBy(String alias);
  String notepadCycle(String path);
  String notepadUnknownImport(String name);
  String notepadInvalidImport(String name);
  String get notepadEmptyImportList;
  String notepadUseDirective(String code);
  String get notepadManageTitle;
  String get notepadManageNotepads;
  String get notepadOpenDocument;
  String get notepadExportAsJson;
  String get notepadImportFromJson;
  String get notepadImport;
  String get notepadImportJsonHint;
  String get notepadJsonCopied;
  String notepadJsonImported(String name);
  String get notepadJsonImportFailed;

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
  String get graphErrorEmpty;
  String get graphErrorUnbalanced;
  String get graphErrorTrailingOperator;
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

  // -- P9-A2: 3D Scene module --
  String get module3DScene;
  String get module3DSceneSubtitle;
  String get scene3DAddPlane;
  String get scene3DEditPlane;
  String get scene3DEmpty;
  String get scene3DPanelEmpty;
  String get scene3DObjectLabel;
  String get scene3DColor;
  String get scene3DAdd;
  String get scene3DSave;
  String get scene3DEdit;
  String get scene3DDelete;
  String get scene3DHide;
  String get scene3DShow;
  String get scene3DLabelRequired;
  String get scene3DCoefRequired;
  String get scene3DCoefInvalid;
  String get scene3DPlaneZeroNormal;

  // -- P9-A3: lines + spheres --
  String get scene3DAddObject;
  String get scene3DAddLine;
  String get scene3DEditLine;
  String get scene3DAddSphere;
  String get scene3DEditSphere;
  String get scene3DLinePointDir;
  String get scene3DLineTwoPoints;
  String get scene3DLinePoint;
  String get scene3DLineDirection;
  String get scene3DLineFirstPoint;
  String get scene3DLineSecondPoint;
  String get scene3DLineZeroDirection;
  String get scene3DSphereCenter;
  String get scene3DSphereRadius;
  String get scene3DSpherePositiveRadius;

  // -- P9-A4: intersections panel --
  String get scene3DIntersectionsEmpty;
  String scene3DIntersectionsTitle(int n);
  String get intersectionPoint;
  String get intersectionTwoPoints;
  String get intersectionLine;
  String get intersectionCircle;
  String intersectionReason(String key);

  // -- P9-A5: quadrics --
  String get scene3DAddQuadric;
  String get scene3DEditQuadric;
  String get scene3DQuadricKind;
  String get scene3DQuadricSemiAxes;
  String get scene3DQuadricPositiveSemiAxes;
  String get quadricKindEllipsoid;
  String get quadricKindCone;
  String get quadricKindCylinder;
  String get quadricKindParaboloid;
  String get quadricKindHyperboloid1;
  String get quadricKindHyperboloid2;

  // -- P9-A5c.3: Conic Section → 3D Scene bridge --
  String get conicOpenIn3DScene;
  String get conicLiftNotAConic;

  // -- P9-A6: parametric surfaces + curves --
  String get scene3DAddParametricSurface;
  String get scene3DEditParametricSurface;
  String get scene3DAddParametricCurve;
  String get scene3DEditParametricCurve;
  String get scene3DParametricSurface;
  String get scene3DParametricCurve;

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
  String settingsNumberFormatDecimalPlaces(int n);
  String get settingsAutoBindSolve;
  String get settingsAutoBindSolveSubtitle;
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

  // Round 91: Store result as variable / function (right-click /
  // long-press on a Calculator history row or a Notepad result).
  String get storeAsVariable;
  String get storeAsFunction;
  String get storeVariableTitle;
  String get storeFunctionTitle;
  String get storeNameLabel;
  String get storeFunctionParamLabel;
  String get storeButton;
  String get storeNameReserved;
  String storeSavedAs(String name);

  // -- R91b: overwrite confirmation --
  String storeOverwriteTitle(String name);
  String storeOverwriteCurrent(String existing);
  String get storeOverwriteConfirm;

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
  // Round 87: Sudoku UI overhaul (clear-to-start + win chip).
  String get sudokuClearToStart;
  String get sudokuSolvedCorrectly;
  String get sudokuFilledWithErrors;
  // Round 87b: dismissable win celebration overlay.
  String get sudokuWinOverlayTapHint;
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
  String get sudokuVariantKiller;
  String get sudokuVariantDisjoint;
  String get sudokuCheckUnique;
  String get sudokuUniqueSolution;
  String get sudokuMultipleSolutions;
  String get sudokuShowHints;
  String get sudokuShowHintsSubtitle;
  String get sudokuHintLevelOff;
  String get sudokuHintLevelBasic;
  String get sudokuHintLevelAdvanced;
  String get sudokuHintLevelAdvancedHelp;
  String get sudokuHintLevelComputing;

  // Round 81: step-trace constraint-context captions. Each
  // visualizer frame can name the row / column / box / cage /
  // diagonal / disjoint-group `allDifferent` overlays the
  // just-assigned cell sits in. Variant-specific overlays only
  // appear when the puzzle's variant uses them.
  String sudokuConstraintRow(int row);
  String sudokuConstraintCol(int col);
  String sudokuConstraintBox(int box);
  String sudokuConstraintCage(int cage, int sum);
  String get sudokuConstraintMainDiagonal;
  String get sudokuConstraintAntiDiagonal;
  String sudokuConstraintDisjointGroup(int group);

  /// Caption shown on the very first visualizer frame (no cell has
  /// changed yet — the displayed grid is the user's starting input).
  String get sudokuConstraintStartingPosition;

  // -- Constraints module (Analysis hub / CSP Round A) --
  String get moduleConstraintsTitle;
  String get moduleConstraintsSubtitle;
  String get constraintsTabDiophantine;
  String get constraintsTabCryptarithm;
  String get constraintsTabDsl;
  String get constraintsTabFlatZinc;
  String get constraintsDslIntro;
  String get constraintsDslInputLabel;
  String get constraintsDslExamplesButton;
  String get constraintsDslExamplesTooltip;
  String constraintsDslExampleTitle(String id);
  String get constraintsFlatZincIntro;
  String get constraintsFlatZincInputLabel;
  String get constraintsFlatZincAllSolutions;
  String get constraintsFlatZincFirstSolution;
  String get constraintsFlatZincExhaustiveOne;
  String constraintsFlatZincExhaustiveN(int n);
  String get constraintsFlatZincUnsatisfiable;
  String constraintsFlatZincExampleTitle(String id);
  String get constraintsExplainFailure;
  String get constraintsExplainHeader;
  String get constraintsExplainSatisfiable;
  String constraintsExplainEntryCount(int n);
  String get constraintsExportFlatZinc;
  String get constraintsExportedHeader;
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
  String constraintsOptimalHeader(num objective);

  // -- Accessibility tooltips (V1 a11y pass) --
  String get clearSearchTooltip;
  String get clearFunctionSlotTooltip;
  String get deleteMemorySlotTooltip;

  // -- Help mode (Round 101 / P6) --
  /// Tooltip on the AppBar `(?)` toggle when help mode is off.
  String get helpModeEnableTooltip;

  /// Tooltip on the AppBar `(?)` toggle when help mode is on.
  String get helpModeDisableTooltip;

  /// Round 102: action-button label on the keypad help popover
  /// that deep-links into the full Function Reference dialog.
  String get keypadHelpLearnMore;

  /// Round 103: title of the history-row help modal — "How this was
  /// computed".
  String get historyHelpTitle;

  /// Round 103: "Computed via {engine}" — `engine` is a literal label
  /// like `SymEngine.solve`, `MPFR`, `FLINT.ntheory`, or `Dart`.
  String historyHelpComputedVia(String engine);

  /// Round 103: fallback line for bare arithmetic rows that don't
  /// route through any named engine call.
  String get historyHelpDirectEvaluation;

  /// Round 103: action-button label on the history help modal that
  /// opens the step-by-step trace dialog (only shown when the call
  /// has a step trace — solve / diff / integrate).
  String get historyHelpShowSteps;

  /// Round 105: tooltip on the `(?)` AppBar button rendered on every
  /// Analyze-hub module screen.
  String get moduleHelpTooltip;

  /// Round 105: title shown in the [ModuleHelpDialog] for a given
  /// module. Caller passes the enum value; localizations dispatch
  /// per locale.
  String moduleHelpTitle(ModuleHelpKind kind);

  /// Round 105: body text — what the module does, the inputs, the
  /// outputs. 2-3 sentences each.
  String moduleHelpDescription(ModuleHelpKind kind);

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
  String get workedExamplesCatConstraints;
  String get settingsWorkedExamples;
  String get settingsWorkedExamplesSubtitle;

  // -- Function reference (Round 96 P6) --
  String get functionRefTitle;
  String get functionRefSearchHint;
  String get functionRefEmpty;
  String get functionRefSeeAlso;
  String get functionRefTryInCalculator;
  String get functionRefSeeWorkedExample;

  /// Round 100: localized override for a [FunctionRef]'s
  /// `shortDescription`, keyed by the entry `id`. Returns null when
  /// this locale has no translation for the entry yet; the dialog
  /// then falls back to the English string baked into the catalog.
  /// EN always returns null (the catalog is the English source of
  /// truth). Signatures and example input/expected stay untranslated
  /// (they're code), so only the prose flows through here.
  String? functionRefDescription(String id);

  /// Round 100: localized override for the `hint` on the example at
  /// [index] of the [FunctionRef] with the given `id`. Null → the
  /// dialog falls back to the catalog hint. EN always returns null.
  String? functionRefExampleHint(String id, int index);
  String get functionRefCatCas;
  String get functionRefCatNumberTheory;
  String get functionRefCatPrecision;
  String get functionRefCatMatrix;
  String get functionRefCatGraphing;
  String get functionRefCatStatistics;
  String get functionRefCatConstraints;
  String get functionRefCatSudoku;
  String get functionRefCatUnits;
  String get settingsFunctionRef;
  String get settingsFunctionRefSubtitle;

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
  String get navNotepad => 'Notepad';
  @override
  String get notepadDefaultDocName => 'Untitled';
  @override
  String get notepadAddLine => 'Add line';
  @override
  String get notepadDeleteLine => 'Delete line';
  @override
  String get notepadDocumentMenu => 'Document menu';
  @override
  String get notepadNewDocument => 'New document';
  @override
  String get notepadOpenWelcomeSample => 'Open Welcome sample';
  @override
  String get notepadRecalculateAll => 'Recalculate all';
  @override
  String get notepadRename => 'Rename';
  @override
  String get notepadDuplicate => 'Duplicate';
  @override
  String get notepadCopyAsMarkdown => 'Copy as Markdown';
  @override
  String get notepadDeleteDocument => 'Delete document';
  @override
  String get notepadUndo => 'Undo';
  @override
  String get notepadLineDeleted => 'Line deleted';
  @override
  String notepadDocumentDeleted(String name) => 'Document "$name" deleted';
  @override
  String get notepadCopiedAsMarkdown => 'Copied as Markdown';
  @override
  String get notepadCopyResult => 'Copy result';
  @override
  String get notepadCopyAsLatex => 'Copy as LaTeX';
  @override
  String get notepadCopiedResult => 'Copied result';
  @override
  String get notepadCopiedAsLatex => 'Copied as LaTeX';
  @override
  String get notepadEmptyTitle => 'No documents yet';
  @override
  String get notepadEmptyBody =>
      'Create a new document or open the Welcome sample to get started.';
  @override
  String notepadFreeVars(String names) => 'free: $names';
  @override
  String notepadBlockedBy(String alias) => 'Blocked by $alias';
  @override
  String notepadCycle(String path) => 'Cycle: $path';
  @override
  String notepadUnknownImport(String name) =>
      'Unknown import: "$name" not in global variables';
  @override
  String notepadInvalidImport(String name) => 'Invalid import name: "$name"';
  @override
  String get notepadEmptyImportList => 'Empty import list';
  @override
  String notepadUseDirective(String code) => 'Use directive: $code';
  @override
  String get notepadManageTitle => 'Manage notepads';
  @override
  String get notepadManageNotepads => 'Manage notepads…';
  @override
  String get notepadOpenDocument => 'Open';
  @override
  String get notepadExportAsJson => 'Export as JSON';
  @override
  String get notepadImportFromJson => 'Import from JSON';
  @override
  String get notepadImport => 'Import';
  @override
  String get notepadImportJsonHint => 'Paste a notepad JSON payload here…';
  @override
  String get notepadJsonCopied => 'Notepad JSON copied to clipboard';
  @override
  String notepadJsonImported(String name) => 'Imported "$name"';
  @override
  String get notepadJsonImportFailed =>
      'Import failed: payload is not valid notepad JSON';
  @override
  String get graphErrorEmpty => 'Function is empty';
  @override
  String get graphErrorUnbalanced =>
      'Unbalanced parentheses or brackets — the function can\'t be plotted';
  @override
  String get graphErrorTrailingOperator =>
      'Function ends with an operator — add the right-hand side';
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

  // -- P9-A2 --
  @override
  String get module3DScene => '3D Scene';
  @override
  String get module3DSceneSubtitle =>
      'Render multiple 3D objects together — planes, lines, spheres, quadrics';
  @override
  String get scene3DAddPlane => 'Add plane';
  @override
  String get scene3DEditPlane => 'Edit plane';
  @override
  String get scene3DEmpty =>
      'Drag to rotate · pinch to zoom · tap the + button to add a plane';
  @override
  String get scene3DPanelEmpty => 'No objects yet';
  @override
  String get scene3DObjectLabel => 'Label';
  @override
  String get scene3DColor => 'Color';
  @override
  String get scene3DAdd => 'Add';
  @override
  String get scene3DSave => 'Save';
  @override
  String get scene3DEdit => 'Edit';
  @override
  String get scene3DDelete => 'Delete';
  @override
  String get scene3DHide => 'Hide';
  @override
  String get scene3DShow => 'Show';
  @override
  String get scene3DLabelRequired => 'Label required';
  @override
  String get scene3DCoefRequired => 'Required';
  @override
  String get scene3DCoefInvalid => 'Not a number';
  @override
  String get scene3DPlaneZeroNormal =>
      'Normal vector (a, b, c) must be non-zero';

  // -- P9-A3 --
  @override
  String get scene3DAddObject => 'Add object';
  @override
  String get scene3DAddLine => 'Add line';
  @override
  String get scene3DEditLine => 'Edit line';
  @override
  String get scene3DAddSphere => 'Add sphere';
  @override
  String get scene3DEditSphere => 'Edit sphere';
  @override
  String get scene3DLinePointDir => 'Point + direction';
  @override
  String get scene3DLineTwoPoints => 'Two points';
  @override
  String get scene3DLinePoint => 'Point';
  @override
  String get scene3DLineDirection => 'Direction';
  @override
  String get scene3DLineFirstPoint => 'First point';
  @override
  String get scene3DLineSecondPoint => 'Second point';
  @override
  String get scene3DLineZeroDirection =>
      'Direction vector must be non-zero (or pick two distinct points)';
  @override
  String get scene3DSphereCenter => 'Center';
  @override
  String get scene3DSphereRadius => 'Radius';
  @override
  String get scene3DSpherePositiveRadius => 'Radius must be greater than zero';

  // -- P9-A4 --
  @override
  String get scene3DIntersectionsEmpty =>
      'Add two or more objects to see their intersections';
  @override
  String scene3DIntersectionsTitle(int n) =>
      n == 1 ? '1 intersection' : '$n intersections';
  @override
  String get intersectionPoint => 'Point';
  @override
  String get intersectionTwoPoints => 'Two points';
  @override
  String get intersectionLine => 'Line';
  @override
  String get intersectionCircle => 'Circle';
  @override
  String intersectionReason(String key) {
    switch (key) {
      case 'parallelPlanes':
        return 'Planes are parallel (no intersection)';
      case 'coincidentPlanes':
        return 'Planes are coincident';
      case 'lineParallelToPlane':
        return 'Line is parallel to plane (no intersection)';
      case 'lineInPlane':
        return 'Line lies in the plane';
      case 'sphereMissesPlane':
        return 'Plane does not touch the sphere';
      case 'degeneratePlane':
        return 'Degenerate plane (zero normal)';
      case 'parallelLines':
        return 'Lines are parallel (no intersection)';
      case 'coincidentLines':
        return 'Lines are coincident';
      case 'skewLines':
        return 'Lines are skew (do not meet)';
      case 'lineMissesSphere':
        return 'Line does not touch the sphere';
      case 'degenerateLine':
        return 'Degenerate line (zero direction)';
      case 'spheresApart':
        return 'Spheres are too far apart';
      case 'sphereInsideSphere':
        return 'One sphere lies inside the other';
      case 'coincidentSpheres':
        return 'Spheres are identical';
      case 'numericalFailure':
        return 'Numerical edge case (try slightly different values)';
      // P9-A5b: plane × quadric → conic.
      case 'circle':
        return 'Circle';
      case 'ellipse':
        return 'Ellipse';
      case 'parabola':
        return 'Parabola';
      case 'hyperbola':
        return 'Hyperbola';
      case 'degenerateConic':
        return 'Degenerate conic (pair of lines or a point)';
      case 'noConic':
        return 'Plane misses the quadric';
      case 'planeOnQuadric':
        return 'Plane lies on the quadric';
      default:
        return key;
    }
  }

  // -- P9-A5 --
  @override
  String get scene3DAddQuadric => 'Add quadric';
  @override
  String get scene3DEditQuadric => 'Edit quadric';
  @override
  String get scene3DQuadricKind => 'Type';
  @override
  String get scene3DQuadricSemiAxes => 'Semi-axes';
  @override
  String get scene3DQuadricPositiveSemiAxes =>
      'Semi-axes must be positive (a, b, c > 0)';
  @override
  String get quadricKindEllipsoid => 'Ellipsoid';
  @override
  String get quadricKindCone => 'Elliptic cone';
  @override
  String get quadricKindCylinder => 'Elliptic cylinder';
  @override
  String get quadricKindParaboloid => 'Elliptic paraboloid';
  @override
  String get quadricKindHyperboloid1 => 'Hyperboloid (1 sheet)';
  @override
  String get quadricKindHyperboloid2 => 'Hyperboloid (2 sheets)';

  // -- P9-A5c.3 --
  @override
  String get conicOpenIn3DScene => 'Open in 3D Scene';
  @override
  String get conicLiftNotAConic =>
      'Not a conic — nothing to lift. Add quadratic terms first.';

  // -- P9-A6 --
  @override
  String get scene3DAddParametricSurface => 'Add parametric surface';
  @override
  String get scene3DEditParametricSurface => 'Edit parametric surface';
  @override
  String get scene3DAddParametricCurve => 'Add parametric curve';
  @override
  String get scene3DEditParametricCurve => 'Edit parametric curve';
  @override
  String get scene3DParametricSurface => 'Parametric surface';
  @override
  String get scene3DParametricCurve => 'Parametric curve';

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
  String settingsNumberFormatDecimalPlaces(int n) => 'Decimal places: $n';
  @override
  String get settingsAutoBindSolve => 'Auto-bind solve results';
  @override
  String get settingsAutoBindSolveSubtitle =>
      'When on, solve(eq, x) also assigns the solution to x.';
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

  // -- Round 91: Store result as variable / function --
  @override
  String get storeAsVariable => 'Store result as variable';
  @override
  String get storeAsFunction => 'Store as function';
  @override
  String get storeVariableTitle => 'Save as variable';
  @override
  String get storeFunctionTitle => 'Save as function';
  @override
  String get storeNameLabel => 'Name';
  @override
  String get storeFunctionParamLabel => 'Parameter';
  @override
  String get storeButton => 'Save';
  @override
  String get storeNameReserved => 'Reserved by a built-in';
  @override
  String storeSavedAs(String name) => 'Saved as $name';

  // -- R91b --
  @override
  String storeOverwriteTitle(String name) => 'Overwrite "$name"?';
  @override
  String storeOverwriteCurrent(String existing) => 'Currently: $existing';
  @override
  String get storeOverwriteConfirm => 'Overwrite';

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
  String get sudokuClearToStart => 'Reset puzzle';
  @override
  String get sudokuSolvedCorrectly => 'Solved!';
  @override
  String get sudokuFilledWithErrors => 'Has errors';
  @override
  String get sudokuWinOverlayTapHint => 'Tap to dismiss';
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
      case 'eight8x8':
        return '8×8 medium';
      case 'eight8x8X':
        return '8×8 Sudoku-X medium';
      case 'eight8x8Disjoint':
        return '8×8 Disjoint medium';
      case 'eight8x8Killer':
        return '8×8 Killer';
      case 'ten10x10':
        return '10×10 medium';
      case 'twelve12x12':
        return '12×12 medium';
      case 'fifteen15x15':
        return '15×15 medium';
      case 'standard9x9Easy':
        return '9×9 easy';
      case 'standard9x9Medium':
        return '9×9 medium';
      case 'standard9x9Hard':
        return '9×9 hard (AI Escargot)';
      case 'standard9x9XEasy':
        return '9×9 Sudoku-X easy';
      case 'killer4x4':
        return '4×4 Killer';
      case 'killer9x9':
        return '9×9 Killer';
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
  String get sudokuVariantKiller => 'Killer';
  @override
  String get sudokuVariantDisjoint => 'Disjoint';
  @override
  String get sudokuCheckUnique => 'Check uniqueness';
  @override
  String get sudokuUniqueSolution => 'Unique solution';
  @override
  String get sudokuMultipleSolutions => 'Multiple solutions';
  @override
  String get sudokuShowHints => 'Show hints';
  @override
  String get sudokuShowHintsSubtitle =>
      'Pencil-marks: for each empty cell, the digits not yet '
      'eliminated by row, column, box, or diagonal.';
  @override
  String get sudokuHintLevelOff => 'Off';
  @override
  String get sudokuHintLevelBasic => 'Basic';
  @override
  String get sudokuHintLevelAdvanced => 'Advanced';
  @override
  String get sudokuHintLevelAdvancedHelp =>
      'Advanced runs the full CSP solver on every candidate, so it '
      'also catches hidden singles and naked pairs. Slower — takes '
      'a few seconds on hard 9×9 puzzles.';
  @override
  String get sudokuHintLevelComputing => 'Computing advanced hints…';

  @override
  String sudokuConstraintRow(int row) => 'Row $row';
  @override
  String sudokuConstraintCol(int col) => 'Column $col';
  @override
  String sudokuConstraintBox(int box) => 'Box $box';
  @override
  String sudokuConstraintCage(int cage, int sum) => 'Cage $cage (sum $sum)';
  @override
  String get sudokuConstraintMainDiagonal => 'Main diagonal';
  @override
  String get sudokuConstraintAntiDiagonal => 'Anti diagonal';
  @override
  String sudokuConstraintDisjointGroup(int group) => 'Disjoint group $group';
  @override
  String get sudokuConstraintStartingPosition => 'Starting position';

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
  String get constraintsTabDsl => 'Free-form';
  @override
  String get constraintsTabFlatZinc => 'FlatZinc';
  @override
  String get constraintsDslIntro =>
      'Declare variables with `vars: x, y in 1..9`, '
      'use `allDifferent(x, y, z)` for distinctness, and '
      'write any other line as a constraint (e.g. `x + 2*y == 10`).';
  @override
  String get constraintsDslInputLabel => 'Constraint program';
  @override
  String get constraintsDslExamplesButton => 'Examples';
  @override
  String get constraintsDslExamplesTooltip => 'Load a pre-built example';
  @override
  String constraintsDslExampleTitle(String id) {
    switch (id) {
      case 'magicSum':
        return '3-digit magic sum';
      case 'magicSquare3':
        return '3×3 magic square';
      case 'mapColoring':
        return 'Map coloring (K4)';
      case 'orderedTriples':
        return 'Ordered triples summing to 20';
      case 'coinChangeMin':
        return 'Coin change (minimize coins)';
      case 'schedulingMakespan':
        return 'Scheduling — minimize makespan';
      case 'cumulativeScheduling':
        return 'Cumulative scheduling — capacity 2';
      case 'rcpsp':
        return 'RCPSP — crew + equipment';
    }
    return id;
  }

  @override
  String get constraintsFlatZincIntro =>
      'Paste a FlatZinc model (typically produced by mzn2fzn from a '
      'MiniZinc source). The solver returns standard FlatZinc output: '
      '`name = value;` lines per `:: output_var` annotation, ended by '
      '`----------`, with `==========` after the last solution.';
  @override
  String get constraintsFlatZincInputLabel => 'FlatZinc source';
  @override
  String get constraintsFlatZincAllSolutions => 'All solutions';
  @override
  String get constraintsFlatZincFirstSolution => 'First solution';
  @override
  String get constraintsFlatZincExhaustiveOne => '1 solution (exhaustive)';
  @override
  String constraintsFlatZincExhaustiveN(int n) => '$n solutions (exhaustive)';
  @override
  String get constraintsFlatZincUnsatisfiable => 'Unsatisfiable';
  @override
  String constraintsFlatZincExampleTitle(String id) {
    switch (id) {
      case 'nqueens4':
        return '4-Queens';
      case 'binPacking':
        return 'Bin packing (3 items, 2 bins)';
    }
    return id;
  }

  @override
  String get constraintsExplainFailure => 'Explain failure';
  @override
  String get constraintsExplainHeader => 'Minimal conflict (QuickXplain)';
  @override
  String get constraintsExplainSatisfiable =>
      'No conflict — the model is actually satisfiable.';
  @override
  String constraintsExplainEntryCount(int n) =>
      n == 1 ? '1 conflicting constraint' : '$n conflicting constraints';
  @override
  String get constraintsExportFlatZinc => 'Export as FlatZinc';
  @override
  String get constraintsExportedHeader => 'FlatZinc translation';

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
  String constraintsOptimalHeader(num objective) =>
      'Optimal: objective = $objective';

  @override
  String get clearSearchTooltip => 'Clear search';
  @override
  String get clearFunctionSlotTooltip => 'Clear function slot';
  @override
  String get deleteMemorySlotTooltip => 'Delete memory slot';

  @override
  String get helpModeEnableTooltip =>
      'Help mode: tap any control for an explanation';
  @override
  String get helpModeDisableTooltip => 'Exit help mode';
  @override
  String get keypadHelpLearnMore => 'Learn more';
  @override
  String get historyHelpTitle => 'How this was computed';
  @override
  String historyHelpComputedVia(String engine) => 'Computed via $engine';
  @override
  String get historyHelpDirectEvaluation =>
      'Direct numerical evaluation — no symbolic call involved.';
  @override
  String get historyHelpShowSteps => 'Show steps';

  @override
  String get moduleHelpTooltip => 'What does this module do?';
  @override
  String moduleHelpTitle(ModuleHelpKind kind) {
    switch (kind) {
      case ModuleHelpKind.curveSketching:
        return 'Curve sketching';
      case ModuleHelpKind.planes:
        return 'Plane analysis';
      case ModuleHelpKind.conicSections:
        return 'Conic sections';
      case ModuleHelpKind.statistics:
        return 'Statistics';
      case ModuleHelpKind.graphing3D:
        return '3D graphing';
      case ModuleHelpKind.scene3D:
        return '3D scene';
      case ModuleHelpKind.constraints:
        return 'Constraints';
      case ModuleHelpKind.sudoku:
        return 'Sudoku';
    }
  }

  @override
  String moduleHelpDescription(ModuleHelpKind kind) {
    switch (kind) {
      case ModuleHelpKind.curveSketching:
        return 'Full analysis of a single-variable function f(x): '
            'domain, intercepts, derivative + critical points, extrema, '
            'inflection points, asymptotes, and a sketch. Enter the '
            'function in the input box; results appear on tap.';
      case ModuleHelpKind.planes:
        return 'Analyze 3D planes given in coordinate form '
            '(ax + by + cz = d) or parametric form (point + two direction '
            'vectors). Computes the normal vector, intersections with the '
            'coordinate axes, and pairwise plane relationships.';
      case ModuleHelpKind.conicSections:
        return 'Classify a general conic Ax² + Bxy + Cy² + Dx + Ey + F = 0 '
            'as ellipse, hyperbola, parabola, or degenerate, and extract '
            'centre, axes, foci, and eccentricity. Uses the discriminant '
            'B² − 4AC for the classification.';
      case ModuleHelpKind.statistics:
        return 'Descriptive statistics (mean, median, variance, …), '
            'linear regression with R² and residuals, the normal and '
            'binomial distributions with PDF / CDF / quantile lookups, '
            'and hypothesis tests: Welch t, paired t, one-way ANOVA, '
            'chi-square goodness-of-fit and independence, Fisher exact, '
            'Wilcoxon signed-rank, and the sign test. Tests report the '
            'statistic, the p-value, and (where applicable) a confidence '
            'interval at the chosen α.';
      case ModuleHelpKind.graphing3D:
        return 'Plot z = f(x, y) as a rotatable wireframe surface. '
            'Drag to rotate; pinch / scroll to zoom. The resample action '
            'rebuilds the mesh at the current zoom level so detail '
            'tracks the camera distance.';
      case ModuleHelpKind.scene3D:
        return 'Render multiple 3D objects together — planes, lines, '
            'spheres, and quadrics — in a shared scene. Useful for '
            'visualizing intersections (e.g. two planes meeting along a '
            'line) and for building up geometric arguments piece by piece.';
      case ModuleHelpKind.constraints:
        return 'Solve combinatorial problems: Diophantine equations '
            '(integer solutions to ax + by = c), cryptarithms '
            '(SEND + MORE = MONEY style digit assignments), a small DSL '
            'for finite-domain constraint programming (`allDifferent`, '
            '`noOverlap`, `cumulative`, `minimize` / `maximize`), and a '
            'FlatZinc compatibility tab for problems written in the '
            'MiniZinc intermediate format.';
      case ModuleHelpKind.sudoku:
        return 'Solve 4×4 and 9×9 puzzles including X (diagonal), '
            'Killer (cage-sum), and Disjoint-Groups variants. The '
            'step-by-step solver shows the search tree so you can see '
            'how the engine narrows the candidates. Hint levels expose '
            'either the next-cell answer or a logical reason for it.';
    }
  }

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
  String get workedExamplesCatConstraints => 'Constraints';
  @override
  String? workedExampleTitle(String id) {
    // The English catalog has the canonical titles; the
    // fallback-to-catalog path in the dialog uses these directly.
    // Returning null for every id keeps EN behavior identical to V1.
    return null;
  }

  @override
  String? workedExampleDescription(String id) => null;
  // Round 100: EN returns null for both — the catalog holds the
  // canonical English prose and the dialog falls back to it.
  @override
  String? functionRefDescription(String id) => null;
  @override
  String? functionRefExampleHint(String id, int index) => null;
  @override
  String get settingsWorkedExamples => 'Worked examples library';
  @override
  String get settingsWorkedExamplesSubtitle =>
      'Now also reachable from the open-book icon at the top of the '
      'Calculator and Notepad screens. Tap here for the full library.';
  @override
  String get functionRefTitle => 'Function reference';
  @override
  String get functionRefSearchHint => 'Search functions…';
  @override
  String get functionRefEmpty => 'No functions match this filter.';
  @override
  String get functionRefSeeAlso => 'See also:';
  @override
  String get functionRefTryInCalculator => 'Try in Calculator';
  @override
  String get functionRefSeeWorkedExample => 'See worked example';
  @override
  String get functionRefCatCas => 'CAS';
  @override
  String get functionRefCatNumberTheory => 'Number theory';
  @override
  String get functionRefCatPrecision => 'Precision';
  @override
  String get functionRefCatMatrix => 'Matrix';
  @override
  String get functionRefCatGraphing => 'Graphing';
  @override
  String get functionRefCatStatistics => 'Statistics';
  @override
  String get functionRefCatConstraints => 'Constraints';
  @override
  String get functionRefCatSudoku => 'Sudoku';
  @override
  String get functionRefCatUnits => 'Units';
  @override
  String get settingsFunctionRef => 'Function reference';
  @override
  String get settingsFunctionRefSubtitle =>
      'Browse every CrispCalc function: signature, examples, related '
      'functions, and a paste-into-calculator shortcut.';

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
  String get navNotepad => 'Rechenblock';
  @override
  String get notepadDefaultDocName => 'Unbenannt';
  @override
  String get notepadAddLine => 'Zeile hinzufügen';
  @override
  String get notepadDeleteLine => 'Zeile löschen';
  @override
  String get notepadDocumentMenu => 'Dokumentmenü';
  @override
  String get notepadNewDocument => 'Neues Dokument';
  @override
  String get notepadOpenWelcomeSample => 'Willkommen-Beispiel öffnen';
  @override
  String get notepadRecalculateAll => 'Alles neu berechnen';
  @override
  String get notepadRename => 'Umbenennen';
  @override
  String get notepadDuplicate => 'Duplizieren';
  @override
  String get notepadCopyAsMarkdown => 'Als Markdown kopieren';
  @override
  String get notepadDeleteDocument => 'Dokument löschen';
  @override
  String get notepadUndo => 'Rückgängig';
  @override
  String get notepadLineDeleted => 'Zeile gelöscht';
  @override
  String notepadDocumentDeleted(String name) => 'Dokument „$name" gelöscht';
  @override
  String get notepadCopiedAsMarkdown => 'Als Markdown kopiert';
  @override
  String get notepadCopyResult => 'Ergebnis kopieren';
  @override
  String get notepadCopyAsLatex => 'Als LaTeX kopieren';
  @override
  String get notepadCopiedResult => 'Ergebnis kopiert';
  @override
  String get notepadCopiedAsLatex => 'Als LaTeX kopiert';
  @override
  String get notepadEmptyTitle => 'Noch keine Dokumente';
  @override
  String get notepadEmptyBody =>
      'Lege ein neues Dokument an oder öffne das Willkommen-Beispiel.';
  @override
  String notepadFreeVars(String names) => 'frei: $names';
  @override
  String notepadBlockedBy(String alias) => 'Blockiert durch $alias';
  @override
  String notepadCycle(String path) => 'Zyklus: $path';
  @override
  String notepadUnknownImport(String name) =>
      'Unbekannter Import: „$name" nicht in globalen Variablen';
  @override
  String notepadInvalidImport(String name) => 'Ungültiger Importname: „$name"';
  @override
  String get notepadEmptyImportList => 'Leere Importliste';
  @override
  String notepadUseDirective(String code) => 'Use-Anweisung: $code';
  @override
  String get notepadManageTitle => 'Rechenblöcke verwalten';
  @override
  String get notepadManageNotepads => 'Rechenblöcke verwalten…';
  @override
  String get notepadOpenDocument => 'Öffnen';
  @override
  String get notepadExportAsJson => 'Als JSON exportieren';
  @override
  String get notepadImportFromJson => 'Aus JSON importieren';
  @override
  String get notepadImport => 'Importieren';
  @override
  String get notepadImportJsonHint => 'Hier ein Rechenblock-JSON einfügen…';
  @override
  String get notepadJsonCopied =>
      'Rechenblock-JSON in die Zwischenablage kopiert';
  @override
  String notepadJsonImported(String name) => '„$name" importiert';
  @override
  String get notepadJsonImportFailed =>
      'Import fehlgeschlagen: kein gültiges Rechenblock-JSON';
  @override
  String get graphErrorEmpty => 'Funktion ist leer';
  @override
  String get graphErrorUnbalanced =>
      'Klammern unausgewogen — die Funktion kann nicht gezeichnet werden';
  @override
  String get graphErrorTrailingOperator =>
      'Funktion endet mit einem Operator — bitte rechte Seite ergänzen';
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

  // -- P9-A2 --
  @override
  String get module3DScene => '3D-Szene';
  @override
  String get module3DSceneSubtitle =>
      'Mehrere 3D-Objekte zusammen darstellen — Ebenen, Geraden, Kugeln, Quadriken';
  @override
  String get scene3DAddPlane => 'Ebene hinzufügen';
  @override
  String get scene3DEditPlane => 'Ebene bearbeiten';
  @override
  String get scene3DEmpty =>
      'Ziehen zum Drehen · Pinch zum Zoomen · + tippen, um eine Ebene hinzuzufügen';
  @override
  String get scene3DPanelEmpty => 'Noch keine Objekte';
  @override
  String get scene3DObjectLabel => 'Bezeichnung';
  @override
  String get scene3DColor => 'Farbe';
  @override
  String get scene3DAdd => 'Hinzufügen';
  @override
  String get scene3DSave => 'Speichern';
  @override
  String get scene3DEdit => 'Bearbeiten';
  @override
  String get scene3DDelete => 'Löschen';
  @override
  String get scene3DHide => 'Ausblenden';
  @override
  String get scene3DShow => 'Einblenden';
  @override
  String get scene3DLabelRequired => 'Bezeichnung erforderlich';
  @override
  String get scene3DCoefRequired => 'Erforderlich';
  @override
  String get scene3DCoefInvalid => 'Keine gültige Zahl';
  @override
  String get scene3DPlaneZeroNormal =>
      'Normalenvektor (a, b, c) darf nicht null sein';

  // -- P9-A3 --
  @override
  String get scene3DAddObject => 'Objekt hinzufügen';
  @override
  String get scene3DAddLine => 'Gerade hinzufügen';
  @override
  String get scene3DEditLine => 'Gerade bearbeiten';
  @override
  String get scene3DAddSphere => 'Kugel hinzufügen';
  @override
  String get scene3DEditSphere => 'Kugel bearbeiten';
  @override
  String get scene3DLinePointDir => 'Punkt + Richtung';
  @override
  String get scene3DLineTwoPoints => 'Zwei Punkte';
  @override
  String get scene3DLinePoint => 'Punkt';
  @override
  String get scene3DLineDirection => 'Richtung';
  @override
  String get scene3DLineFirstPoint => 'Erster Punkt';
  @override
  String get scene3DLineSecondPoint => 'Zweiter Punkt';
  @override
  String get scene3DLineZeroDirection =>
      'Richtungsvektor darf nicht null sein (oder zwei verschiedene Punkte wählen)';
  @override
  String get scene3DSphereCenter => 'Mittelpunkt';
  @override
  String get scene3DSphereRadius => 'Radius';
  @override
  String get scene3DSpherePositiveRadius => 'Radius muss größer als null sein';

  // -- P9-A4 --
  @override
  String get scene3DIntersectionsEmpty =>
      'Zwei oder mehr Objekte hinzufügen, um Schnittmengen zu sehen';
  @override
  String scene3DIntersectionsTitle(int n) =>
      n == 1 ? '1 Schnittmenge' : '$n Schnittmengen';
  @override
  String get intersectionPoint => 'Punkt';
  @override
  String get intersectionTwoPoints => 'Zwei Punkte';
  @override
  String get intersectionLine => 'Gerade';
  @override
  String get intersectionCircle => 'Kreis';
  @override
  String intersectionReason(String key) {
    switch (key) {
      case 'parallelPlanes':
        return 'Ebenen sind parallel (kein Schnitt)';
      case 'coincidentPlanes':
        return 'Ebenen fallen zusammen';
      case 'lineParallelToPlane':
        return 'Gerade verläuft parallel zur Ebene (kein Schnitt)';
      case 'lineInPlane':
        return 'Gerade liegt in der Ebene';
      case 'sphereMissesPlane':
        return 'Ebene berührt die Kugel nicht';
      case 'degeneratePlane':
        return 'Degenerierte Ebene (Nullnormalvektor)';
      case 'parallelLines':
        return 'Geraden sind parallel (kein Schnitt)';
      case 'coincidentLines':
        return 'Geraden fallen zusammen';
      case 'skewLines':
        return 'Geraden sind windschief (treffen sich nicht)';
      case 'lineMissesSphere':
        return 'Gerade berührt die Kugel nicht';
      case 'degenerateLine':
        return 'Degenerierte Gerade (Nullrichtung)';
      case 'spheresApart':
        return 'Kugeln liegen zu weit auseinander';
      case 'sphereInsideSphere':
        return 'Eine Kugel liegt in der anderen';
      case 'coincidentSpheres':
        return 'Kugeln sind identisch';
      case 'numericalFailure':
        return 'Numerischer Grenzfall (leicht andere Werte versuchen)';
      // P9-A5b: plane × quadric → conic.
      case 'circle':
        return 'Kreis';
      case 'ellipse':
        return 'Ellipse';
      case 'parabola':
        return 'Parabel';
      case 'hyperbola':
        return 'Hyperbel';
      case 'degenerateConic':
        return 'Degenerierter Kegelschnitt (Geradenpaar oder Punkt)';
      case 'noConic':
        return 'Ebene verfehlt die Quadrik';
      case 'planeOnQuadric':
        return 'Ebene liegt auf der Quadrik';
      default:
        return key;
    }
  }

  // -- P9-A5 --
  @override
  String get scene3DAddQuadric => 'Quadrik hinzufügen';
  @override
  String get scene3DEditQuadric => 'Quadrik bearbeiten';
  @override
  String get scene3DQuadricKind => 'Typ';
  @override
  String get scene3DQuadricSemiAxes => 'Halbachsen';
  @override
  String get scene3DQuadricPositiveSemiAxes =>
      'Halbachsen müssen positiv sein (a, b, c > 0)';
  @override
  String get quadricKindEllipsoid => 'Ellipsoid';
  @override
  String get quadricKindCone => 'Elliptischer Kegel';
  @override
  String get quadricKindCylinder => 'Elliptischer Zylinder';
  @override
  String get quadricKindParaboloid => 'Elliptisches Paraboloid';
  @override
  String get quadricKindHyperboloid1 => 'Einschaliges Hyperboloid';
  @override
  String get quadricKindHyperboloid2 => 'Zweischaliges Hyperboloid';

  // -- P9-A5c.3 --
  @override
  String get conicOpenIn3DScene => 'In 3D-Szene öffnen';
  @override
  String get conicLiftNotAConic =>
      'Kein Kegelschnitt — nichts anzuheben. Erst quadratische Terme hinzufügen.';

  // -- P9-A6 --
  @override
  String get scene3DAddParametricSurface => 'Parametrische Fläche hinzufügen';
  @override
  String get scene3DEditParametricSurface => 'Parametrische Fläche bearbeiten';
  @override
  String get scene3DAddParametricCurve => 'Parametrische Kurve hinzufügen';
  @override
  String get scene3DEditParametricCurve => 'Parametrische Kurve bearbeiten';
  @override
  String get scene3DParametricSurface => 'Parametrische Fläche';
  @override
  String get scene3DParametricCurve => 'Parametrische Kurve';

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
  String settingsNumberFormatDecimalPlaces(int n) => 'Nachkommastellen: $n';
  @override
  String get settingsAutoBindSolve => 'Lösungen automatisch zuweisen';
  @override
  String get settingsAutoBindSolveSubtitle =>
      'Wenn aktiv, weist solve(gleichung, x) die Lösung auch x zu.';
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

  // -- Round 91 --
  @override
  String get storeAsVariable => 'Ergebnis als Variable speichern';
  @override
  String get storeAsFunction => 'Als Funktion speichern';
  @override
  String get storeVariableTitle => 'Als Variable speichern';
  @override
  String get storeFunctionTitle => 'Als Funktion speichern';
  @override
  String get storeNameLabel => 'Name';
  @override
  String get storeFunctionParamLabel => 'Parameter';
  @override
  String get storeButton => 'Speichern';
  @override
  String get storeNameReserved => 'Name ist von einer Funktion belegt';
  @override
  String storeSavedAs(String name) => 'Als $name gespeichert';

  // -- R91b --
  @override
  String storeOverwriteTitle(String name) => '„$name" überschreiben?';
  @override
  String storeOverwriteCurrent(String existing) => 'Aktuell: $existing';
  @override
  String get storeOverwriteConfirm => 'Überschreiben';

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
  String get sudokuClearToStart => 'Rätsel zurücksetzen';
  @override
  String get sudokuSolvedCorrectly => 'Gelöst!';
  @override
  String get sudokuFilledWithErrors => 'Mit Fehlern';
  @override
  String get sudokuWinOverlayTapHint => 'Zum Schließen tippen';
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
      case 'eight8x8':
        return '8×8 mittel';
      case 'eight8x8X':
        return '8×8 Sudoku-X mittel';
      case 'eight8x8Disjoint':
        return '8×8 Disjunkt mittel';
      case 'eight8x8Killer':
        return '8×8 Killer';
      case 'ten10x10':
        return '10×10 mittel';
      case 'twelve12x12':
        return '12×12 mittel';
      case 'fifteen15x15':
        return '15×15 mittel';
      case 'standard9x9Easy':
        return '9×9 leicht';
      case 'standard9x9Medium':
        return '9×9 mittel';
      case 'standard9x9Hard':
        return '9×9 schwer (AI Escargot)';
      case 'standard9x9XEasy':
        return '9×9 Sudoku-X leicht';
      case 'killer4x4':
        return '4×4 Killer';
      case 'killer9x9':
        return '9×9 Killer';
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
  String get sudokuVariantKiller => 'Killer';
  @override
  String get sudokuVariantDisjoint => 'Disjunkt';
  @override
  String get sudokuCheckUnique => 'Eindeutigkeit prüfen';
  @override
  String get sudokuUniqueSolution => 'Eindeutige Lösung';
  @override
  String get sudokuMultipleSolutions => 'Mehrere Lösungen';
  @override
  String get sudokuShowHints => 'Hinweise anzeigen';
  @override
  String get sudokuShowHintsSubtitle =>
      'Bleistift-Notizen: für jedes leere Feld die Ziffern, die noch '
      'nicht durch Zeile, Spalte, Block oder Diagonale ausgeschlossen '
      'sind.';
  @override
  String get sudokuHintLevelOff => 'Aus';
  @override
  String get sudokuHintLevelBasic => 'Einfach';
  @override
  String get sudokuHintLevelAdvanced => 'Erweitert';
  @override
  String get sudokuHintLevelAdvancedHelp =>
      'Erweitert führt für jeden Kandidaten den vollständigen '
      'CSP-Solver aus und erkennt so auch versteckte Einzelne und '
      'nackte Paare. Langsamer — dauert bei schweren 9×9-Rätseln '
      'einige Sekunden.';
  @override
  String get sudokuHintLevelComputing =>
      'Erweiterte Hinweise werden berechnet…';

  @override
  String sudokuConstraintRow(int row) => 'Zeile $row';
  @override
  String sudokuConstraintCol(int col) => 'Spalte $col';
  @override
  String sudokuConstraintBox(int box) => 'Block $box';
  @override
  String sudokuConstraintCage(int cage, int sum) => 'Käfig $cage (Summe $sum)';
  @override
  String get sudokuConstraintMainDiagonal => 'Hauptdiagonale';
  @override
  String get sudokuConstraintAntiDiagonal => 'Antidiagonale';
  @override
  String sudokuConstraintDisjointGroup(int group) => 'Disjunkte Gruppe $group';
  @override
  String get sudokuConstraintStartingPosition => 'Ausgangsstellung';

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
  String get constraintsTabDsl => 'Freitext';
  @override
  String get constraintsTabFlatZinc => 'FlatZinc';
  @override
  String get constraintsDslIntro =>
      'Variablen deklarieren mit `vars: x, y in 1..9`, '
      'für Verschiedenheit `allDifferent(x, y, z)`, '
      'jede weitere Zeile ist eine Bedingung (z.B. `x + 2*y == 10`).';
  @override
  String get constraintsDslInputLabel => 'Bedingungsprogramm';
  @override
  String get constraintsDslExamplesButton => 'Beispiele';
  @override
  String get constraintsDslExamplesTooltip => 'Vorgefertigtes Beispiel laden';
  @override
  String constraintsDslExampleTitle(String id) {
    switch (id) {
      case 'magicSum':
        return '3-stellige magische Summe';
      case 'magicSquare3':
        return '3×3 magisches Quadrat';
      case 'mapColoring':
        return 'Landkartenfärbung (K4)';
      case 'orderedTriples':
        return 'Geordnete Tripel mit Summe 20';
      case 'coinChangeMin':
        return 'Münzwechsel (Anzahl minimieren)';
      case 'schedulingMakespan':
        return 'Scheduling — Makespan minimieren';
      case 'cumulativeScheduling':
        return 'Kumulatives Scheduling — Kapazität 2';
      case 'rcpsp':
        return 'RCPSP — Crew + Ausrüstung';
    }
    return id;
  }

  @override
  String get constraintsFlatZincIntro =>
      'FlatZinc-Modell einfügen (typischerweise von mzn2fzn aus einer '
      'MiniZinc-Quelle erzeugt). Der Solver liefert die Standard-'
      'FlatZinc-Ausgabe: `name = wert;` pro `:: output_var`-Annotation, '
      'beendet mit `----------`, gefolgt von `==========` nach der '
      'letzten Lösung.';
  @override
  String get constraintsFlatZincInputLabel => 'FlatZinc-Quelltext';
  @override
  String get constraintsFlatZincAllSolutions => 'Alle Lösungen';
  @override
  String get constraintsFlatZincFirstSolution => 'Erste Lösung';
  @override
  String get constraintsFlatZincExhaustiveOne => '1 Lösung (vollständig)';
  @override
  String constraintsFlatZincExhaustiveN(int n) => '$n Lösungen (vollständig)';
  @override
  String get constraintsFlatZincUnsatisfiable => 'Unerfüllbar';
  @override
  String constraintsFlatZincExampleTitle(String id) {
    switch (id) {
      case 'nqueens4':
        return '4-Damen-Problem';
      case 'binPacking':
        return 'Bin-Packing (3 Objekte, 2 Behälter)';
    }
    return id;
  }

  @override
  String get constraintsExplainFailure => 'Konflikt erklären';
  @override
  String get constraintsExplainHeader => 'Minimaler Konflikt (QuickXplain)';
  @override
  String get constraintsExplainSatisfiable =>
      'Kein Konflikt — das Modell ist tatsächlich erfüllbar.';
  @override
  String constraintsExplainEntryCount(int n) => n == 1
      ? '1 widersprüchliche Bedingung'
      : '$n widersprüchliche Bedingungen';
  @override
  String get constraintsExportFlatZinc => 'Als FlatZinc exportieren';
  @override
  String get constraintsExportedHeader => 'FlatZinc-Übersetzung';

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
  String constraintsOptimalHeader(num objective) =>
      'Optimal: Zielfunktion = $objective';

  @override
  String get clearSearchTooltip => 'Suche leeren';
  @override
  String get clearFunctionSlotTooltip => 'Funktion löschen';
  @override
  String get deleteMemorySlotTooltip => 'Speicherplatz löschen';

  @override
  String get helpModeEnableTooltip =>
      'Hilfemodus: jedes Bedienelement antippen für eine Erklärung';
  @override
  String get helpModeDisableTooltip => 'Hilfemodus beenden';
  @override
  String get keypadHelpLearnMore => 'Mehr erfahren';
  @override
  String get historyHelpTitle => 'So wurde dies berechnet';
  @override
  String historyHelpComputedVia(String engine) => 'Berechnet über $engine';
  @override
  String get historyHelpDirectEvaluation =>
      'Direkte numerische Auswertung — kein symbolischer Aufruf.';
  @override
  String get historyHelpShowSteps => 'Schritte anzeigen';

  @override
  String get moduleHelpTooltip => 'Was macht dieses Modul?';
  @override
  String moduleHelpTitle(ModuleHelpKind kind) {
    switch (kind) {
      case ModuleHelpKind.curveSketching:
        return 'Kurvendiskussion';
      case ModuleHelpKind.planes:
        return 'Ebenenanalyse';
      case ModuleHelpKind.conicSections:
        return 'Kegelschnitte';
      case ModuleHelpKind.statistics:
        return 'Statistik';
      case ModuleHelpKind.graphing3D:
        return '3D-Diagramme';
      case ModuleHelpKind.scene3D:
        return '3D-Szene';
      case ModuleHelpKind.constraints:
        return 'Bedingungen';
      case ModuleHelpKind.sudoku:
        return 'Sudoku';
    }
  }

  @override
  String moduleHelpDescription(ModuleHelpKind kind) {
    switch (kind) {
      case ModuleHelpKind.curveSketching:
        return 'Vollständige Analyse einer Funktion f(x) einer Variablen: '
            'Definitionsbereich, Nullstellen, Ableitung und kritische '
            'Punkte, Extrema, Wendepunkte, Asymptoten sowie eine Skizze. '
            'Funktion in das Eingabefeld eingeben — Ergebnisse erscheinen '
            'bei Tipp.';
      case ModuleHelpKind.planes:
        return 'Analyse von 3D-Ebenen in Koordinatenform '
            '(ax + by + cz = d) oder Parameterform (Punkt + zwei '
            'Richtungsvektoren). Berechnet Normalenvektor, Achsen-'
            'schnittpunkte und paarweise Lagebeziehungen.';
      case ModuleHelpKind.conicSections:
        return 'Klassifiziert einen allgemeinen Kegelschnitt '
            'Ax² + Bxy + Cy² + Dx + Ey + F = 0 als Ellipse, Hyperbel, '
            'Parabel oder entartet und liefert Mittelpunkt, Achsen, '
            'Brennpunkte und Exzentrizität. Nutzt die Diskriminante '
            'B² − 4AC zur Klassifizierung.';
      case ModuleHelpKind.statistics:
        return 'Deskriptive Statistik (Mittel, Median, Varianz, …), '
            'lineare Regression mit R² und Residuen, Normal- und '
            'Binomialverteilung mit PDF / CDF / Quantilen sowie '
            'Hypothesentests: Welch-t, gepaarter t-Test, einfache '
            'ANOVA, Chi-Quadrat-Anpassungs- und Unabhängigkeitstest, '
            'Fisher-Exakt, Wilcoxon-Vorzeichen-Rang und Vorzeichentest. '
            'Die Tests liefern Teststatistik, p-Wert und (falls '
            'anwendbar) ein Konfidenzintervall zum gewählten α.';
      case ModuleHelpKind.graphing3D:
        return 'Stellt z = f(x, y) als drehbares Drahtgitter dar. '
            'Ziehen zum Drehen; Pinch / Scrollen zum Zoomen. Die '
            'Resample-Aktion baut das Netz für die aktuelle Zoomstufe '
            'neu auf, sodass das Detail der Kameradistanz folgt.';
      case ModuleHelpKind.scene3D:
        return 'Mehrere 3D-Objekte gemeinsam darstellen — Ebenen, '
            'Geraden, Kugeln und Quadriken — in einer geteilten Szene. '
            'Hilfreich zur Visualisierung von Schnitten (etwa zweier '
            'Ebenen entlang einer Geraden) und zum schrittweisen Aufbau '
            'geometrischer Argumentationen.';
      case ModuleHelpKind.constraints:
        return 'Löst kombinatorische Probleme: diophantische '
            'Gleichungen (ganzzahlige Lösungen von ax + by = c), '
            'Kryptarithmen (SEND + MORE = MONEY-Stil), eine kleine '
            'DSL für endliche Bereichsbedingungen (`allDifferent`, '
            '`noOverlap`, `cumulative`, `minimize` / `maximize`) sowie '
            'einen FlatZinc-Tab für Probleme im MiniZinc-Zwischenformat.';
      case ModuleHelpKind.sudoku:
        return 'Löst 4×4- und 9×9-Rätsel einschließlich der Varianten '
            'X (Diagonale), Killer (Käfigsummen) und Disjoint-Groups. '
            'Der schrittweise Solver zeigt den Suchbaum, sodass '
            'nachvollziehbar wird, wie der Algorithmus die Kandidaten '
            'einschränkt. Tippstufen zeigen entweder die nächste '
            'Zellantwort oder eine logische Begründung dafür.';
    }
  }

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
  String get workedExamplesCatConstraints => 'Bedingungen';
  @override
  String? workedExampleTitle(String id) {
    switch (id) {
      case 'killerSudoku':
        return 'Killer-Sudoku (9×9)';
      case 'constraintEditor':
        return 'Freitext-Bedingungseditor';
      case 'dslMagicSquare':
        return '3×3 magisches Quadrat (DSL)';
      case 'dslMapColoring':
        return 'Landkartenfärbung K4 (DSL)';
      case 'dslOrderedTriples':
        return 'Geordnete Tripel mit Summe 20 (DSL)';
      case 'dslCoinChange':
        return 'Münzwechsel — Anzahl minimieren (DSL)';
      case 'dslSchedulingMakespan':
        return 'Einzelmaschinen-Scheduling — Makespan minimieren (DSL)';
      case 'dslCumulativeScheduling':
        return 'Parallele Ressourcen-Planung — cumulative (DSL)';
      case 'dslRcpsp':
        return 'Projektplanung RCPSP — zwei Ressourcen (DSL)';
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
      case 'piPrecision':
        return 'π auf 100 Stellen';
      case 'ePrecision':
        return 'e auf 50 Stellen';
      case 'factorint360':
        return 'Primfaktorzerlegung';
      case 'nextprime1000':
        return 'Nächste Primzahl nach 1000';
      case 'mersenneM31':
        return 'Mersenne-Primzahl M31';
      case 'divisors12':
        return 'Alle Teiler';
      case 'eulerTotient':
        return 'Eulersche φ-Funktion';
      case 'modpowCrypto':
        return 'Modulare Exponentiation';
      case 'contFracPi':
        return 'Kettenbruch von π';
      case 'booleanIsprimeAnd':
        return 'Primzahl und beschränkt';
      case 'booleanEqualityFold':
        return 'Gleichheits-Auswertung';
      case 'booleanNotPrime':
        return 'Negation';
      case 'booleanOrChain':
        return 'Disjunktion über Vergleiche';
      case 'booleanIfFold':
        return 'Bedingte Auswertung';
      case 'compoundInterest':
        return 'Zinseszins';
      case 'zScore':
        return 'Z-Wert nachschlagen';
      case 'statsHypothesisTests':
        return 'Hypothesentests-Bereich';
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
      case 'killerSudoku':
        return 'Öffnet das Sudoku-Modul mit dem 9×9-Killer-Voreinstellung.';
      case 'constraintEditor':
        return 'Öffnet das Bedingungsmodul — Variablen deklarieren, Bedingungen hinzufügen, lösen.';
      case 'dslMagicSquare':
        return 'Lädt das 9-Variablen-Programm für das magische Quadrat in den DSL-Editor.';
      case 'dslMapColoring':
        return 'Lädt eine K4-Graphfärbung mit 3 Farben — bewusst unlösbar, um den "keine Lösungen"-Pfad zu zeigen.';
      case 'dslOrderedTriples':
        return 'Lädt ein DSL-Programm, das (a, b, c) mit a < b < c und a + b + c = 20 aufzählt.';
      case 'dslCoinChange':
        return 'Lädt ein DSL-Programm, das 17¢ mit den wenigsten Münzen aus {1, 5, 10, 25} via `minimize` zahlt.';
      case 'dslSchedulingMakespan':
        return 'Lädt ein DSL-Programm, das drei Aufgaben (Dauern 4/3/2) auf einer Maschine via `noOverlap` plant und den Makespan minimiert.';
      case 'dslCumulativeScheduling':
        return 'Lädt ein DSL-Programm, das drei Aufgaben auf einer Ressource der Kapazität 2 via `cumulative` plant und den Makespan minimiert.';
      case 'dslRcpsp':
        return 'Lädt ein DSL-Programm mit zwei parallelen `cumulative`-Auflagen (Crew + Ausrüstung, je Kapazität 3) über vier Aufgaben; minimiert den Makespan.';
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
      case 'piPrecision':
        return 'pi(100) — hochpräzise Konstante über MPFR.';
      case 'ePrecision':
        return 'e(50) — gleiche MPFR-Pipeline wie pi(N).';
      case 'factorint360':
        return 'factorint(360) → 2³ · 3² · 5 mit Unicode-Hochzahlen.';
      case 'nextprime1000':
        return 'nextprime(1000) — FLINT-gestützt über SymEngine ntheory.';
      case 'mersenneM31':
        return 'factorint(2^31 − 1) — bestätigt die achte Mersenne-Primzahl '
            'als einzelnen Faktor.';
      case 'divisors12':
        return 'divisors(12) → 1, 2, 3, 4, 6, 12 — aus der '
            'Primfaktorzerlegung abgeleitet.';
      case 'eulerTotient':
        return 'totient(36) — Anzahl der zu 36 teilerfremden Reste.';
      case 'modpowCrypto':
        return 'modpow(2, 100, 1000000007) — Kern von RSA / Diffie-Hellman.';
      case 'contFracPi':
        return 'cfrac(pi, 10) — die Entwicklung [3; 7, 15, 1, 292, …] '
            'hinter 355/113.';
      case 'booleanIsprimeAnd':
        return 'isprime(17) und 17 < 20 — beide Teile wahr, also ist die '
            'Konjunktion wahr.';
      case 'booleanEqualityFold':
        return '2 == 2 — konstante Operanden werden zu „wahr" reduziert.';
      case 'booleanNotPrime':
        return 'not isprime(15) — 15 = 3·5, also ergibt die Verneinung wahr.';
      case 'booleanOrChain':
        return '(5 > 3) oder (1 == 2) — der erste Teil ist wahr, deshalb ist '
            'die gesamte Disjunktion wahr.';
      case 'booleanIfFold':
        return 'if(isprime(7), 100, 200) — die Bedingung wird zu „wahr" '
            'ausgewertet, also gewinnt der Then-Zweig.';
      case 'compoundInterest':
        return '1000 € zu 5 % über 10 Jahre, jährliche Verzinsung.';
      case 'zScore':
        return 'Zum Statistik-Reiter → Verteilungen wechseln, um Φ(1,96) '
            '≈ 0,975 zu berechnen.';
      case 'statsHypothesisTests':
        return 'Öffnet das Statistik-Modul direkt auf dem Tests-Reiter — '
            'Einstichproben-t, Zweistichproben-t (Welch), gepaart, ANOVA, '
            'Chi-Quadrat und Wilcoxon — mit vorbefüllten Beispieldaten.';
      case 'unitConversion':
        return '100 km/h in mph umgerechnet — V2 inline-Parser.';
      case 'compositeDim':
        return '100 m / 10 s ergibt eine Geschwindigkeit in m/s — V5-Parser.';
    }
    return null;
  }

  // Round 100: DE function-reference prose. CAS category translated
  // as the pilot; other categories return null and fall back to the
  // English catalog until translated.
  @override
  String? functionRefDescription(String id) {
    switch (id) {
      case 'solve':
        return 'Löst eine Gleichung symbolisch nach einer Variablen auf; '
            'gibt eine Liste von Lösungen zurück.';
      case 'expand':
        return 'Multipliziert Produkte und Potenzen zu einer Summe von '
            'Monomen aus.';
      case 'simplify':
        return 'Fasst gleichartige Terme zusammen, kürzt gemeinsame Faktoren '
            'und wendet algebraische Standardidentitäten an.';
      case 'factor':
        return 'Faktorisiert ein Polynom über den rationalen Zahlen in '
            'irreduzible Faktoren.';
      case 'diff':
        return 'Symbolische erste Ableitung nach einer Variablen.';
      case 'integrate':
        return 'Unbestimmtes Integral (3 Argumente) oder bestimmtes Integral '
            '(5 Argumente) mit numerischem Rückfall.';
      case 'subst':
        return 'Ersetzt jedes freie Vorkommen von `variable` in `expression` '
            'durch `value`. Auch als `substitute(...)` verfügbar.';
      case 'limit':
        return 'Numerischer Grenzwert, wenn `variable` gegen `point` strebt. '
            '`point` kann ein endlicher Wert oder `oo` / `-oo` sein.';
      case 'gcd':
        return 'Größter gemeinsamer Teiler zweier ganzer Zahlen oder Polynome.';
      case 'lcm':
        return 'Kleinstes gemeinsames Vielfaches zweier ganzer Zahlen oder '
            'Polynome.';
      case 'factorial':
        return 'Exakte ganzzahlige Fakultät. Kleine `n` nutzen Darts '
            '`BigInt`; große `n` werden an SymEngine übergeben.';
      case 'fibonacci':
        return 'n-te Fibonacci-Zahl. `fib(n)` ist der Kurzname.';
      // --- Zahlentheorie ---
      case 'isprime':
        return 'Probabilistischer Primzahltest für ganze Zahlen.';
      case 'nextprime':
        return 'Kleinste Primzahl, die echt größer als `n` ist.';
      case 'prevprime':
        return 'Größte Primzahl, die echt kleiner als `n` ist. Fehler, wenn '
            'keine solche Primzahl existiert (z. B. `prevprime(2)`).';
      case 'factorint':
        return 'Primfaktorzerlegung als `p₁^e₁ · p₂^e₂ · …` mit hochgestellten '
            'Unicode-Exponenten.';
      case 'divisors':
        return 'Alle positiven Teiler von `n`, aufsteigend sortiert und durch '
            'Komma getrennt.';
      case 'totient':
        return 'Eulersche φ-Funktion φ(n): Anzahl der zu `n` teilerfremden '
            'Zahlen in 1..n.';
      case 'modpow':
        return 'Modulare Exponentiation `aᵉ mod m`. Ein negativer Exponent '
            'nutzt das modulare Inverse von `a` (sofern es existiert).';
      case 'modinv':
        return 'Modulares Inverses `a⁻¹ mod m` über den erweiterten '
            'euklidischen Algorithmus. Fehler, wenn `ggT(a, m) ≠ 1`.';
      case 'jacobi':
        return 'Jacobi-Symbol (a/n) ∈ {−1, 0, 1} für ungerades positives `n`; '
            'verallgemeinert das Legendre-Symbol.';
      case 'cfrac':
        return 'Kettenbruchentwicklung `[a₀; a₁, …]` von `x` mit `n` Gliedern. '
            '`x` kann `pi` / `e` / `EulerGamma` / `sqrt(2)`, eine rationale '
            'Zahl `p/q` oder eine Dezimalzahl sein.';
      case 'convergent':
        return 'Der k-te Näherungsbruch `p/q` des Kettenbruchs von `x` — eine '
            'beste rationale Näherung für seine Nennergröße.';
      // --- Hochpräzision ---
      case 'pi_precision':
        return 'π auf N Dezimalstellen über MPFR; gibt die reine Ziffernfolge '
            'zurück.';
      case 'e_precision':
        return 'Eulersche Zahl e auf N Dezimalstellen über MPFR.';
      case 'sqrt_precision':
        return 'Quadratwurzel der ganzen Zahl `k` auf N Dezimalstellen über '
            'MPFR. Die zweiargumentige Form wählt den Hochpräzisionspfad.';
      case 'eulergamma_precision':
        return 'Euler-Mascheroni-Konstante γ ≈ 0,5772… auf N Dezimalstellen '
            'über MPFR.';
      // --- Matrizen / Lineare Algebra ---
      case 'matrix_literal':
        return 'Matrix-Literal: eine Liste von Zeilen, jede Zeile eine Liste '
            'von Zellausdrücken. Zellen können Zahlen, Brüche oder symbolisch '
            'sein.';
      case 'det':
        return 'Determinante einer quadratischen Matrix. Gibt einen '
            'symbolischen Skalar zurück.';
      case 'inv':
        return 'Inverse einer quadratischen, regulären Matrix. Fehler, wenn '
            '`det = 0`.';
      case 'transpose':
        return 'Transponierte: Vertauschen von Zeilen und Spalten. '
            'Funktioniert auch für rechteckige Matrizen.';
      case 'rref':
        return 'Reduzierte Zeilenstufenform über den Gauß-Jordan-Algorithmus. '
            'Funktioniert über symbolische/rationale Einträge.';
      case 'matrix_arithmetic':
        return 'Elementweise Addition/Subtraktion und Matrizenmultiplikation '
            'auf `Matrix(...)`-Literalen.';
      // --- Statistik ---
      case 'mean':
        return 'Arithmetisches Mittel einer Stichprobe als Zahlenliste. Im '
            'Reiter „Deskriptive Statistik" des Statistik-Moduls zusammen mit '
            'den üblichen Kennzahlen verfügbar.';
      case 'welch_t':
        return 'Zweistichproben-t-Test bei ungleichen Varianzen '
            '(Welch-Satterthwaite). Robuste Standardwahl, wenn die beiden '
            'Gruppen unterschiedliche Streuungen haben können.';
      case 'paired_t':
        return 'Gepaarter t-Test auf Differenzen innerhalb der '
            'Versuchseinheiten gegen μ₀ = 0. Wird verwendet, wenn dieselben '
            'Einheiten zweimal gemessen werden (vorher/nachher).';
      case 'anova_1':
        return 'Einfaktorielle Varianzanalyse (ANOVA) über K unabhängige '
            'Gruppen. Prüft, ob sich die Gruppenmittelwerte unterscheiden; '
            'gibt eine F-Statistik und einen p-Wert aus.';
      case 'chi2_goodness':
        return 'Chi-Quadrat-Anpassungstest: Stimmen die beobachteten '
            'Häufigkeiten mit einer angenommenen Verteilung überein?';
      case 'chi2_independence':
        return 'Chi-Quadrat-Unabhängigkeitstest auf einer Kontingenztafel — '
            'sind zwei kategoriale Variablen unabhängig?';
      case 'fisher_exact':
        return 'Exakter Test nach Fisher auf einer 2×2-Kontingenztafel. '
            'Exakter hypergeometrischer p-Wert — keine Näherung für große '
            'Stichproben.';
      case 'wilcoxon':
        return 'Wilcoxon-Rangsummentest / Mann-Whitney-U — nichtparametrischer '
            'Zweistichprobentest auf Rängen. Robust gegenüber nicht '
            'normalverteilten Daten.';
      case 'sign_test':
        return 'Gepaarter Vorzeichentest — nichtparametrischer, medianbasierter '
            'Test auf gepaarten Differenzen. Zählt, wie oft `nachher > vorher` '
            'gilt.';
      // --- Constraints-DSL ---
      case 'vars':
        return 'Deklariert ganzzahlige Entscheidungsvariablen und ihren '
            'Wertebereich. Stets die erste Zeile eines CrispCalc-DSL-Programms.';
      case 'all_different':
        return 'Globale Bedingung „alle Werte paarweise verschieden". Die '
            'wichtigste CP-Bedingung — deutlich stärkere Propagation als '
            'n·(n-1)/2 paarweise `!=`-Klauseln.';
      case 'no_overlap':
        return 'Disjunktive Ablaufplanung: Aufgaben mit gegebenen '
            'Startvariablen und festen Dauern dürfen sich auf einer einzelnen '
            'Maschine zeitlich nicht überlappen.';
      case 'cumulative':
        return 'Kumulative Ablaufplanung auf einer erneuerbaren Ressource '
            'fester Kapazität. Jede Aufgabe hat eine Dauer und einen '
            'Ressourcenbedarf pro Aufgabe.';
      case 'minimize':
        return 'Zielfunktion: minimiert einen linearen Ausdruck über die '
            'Entscheidungsvariablen. In Kombination mit Bedingungen lassen '
            'sich Optimierungs-CSPs lösen.';
      case 'maximize':
        return 'Zielfunktion: maximiert einen linearen Ausdruck. Spiegelbild '
            'von `minimize` — dasselbe Branch-and-Bound, in entgegengesetzter '
            'Richtung.';
      // --- Sudoku-Varianten ---
      case 'sudoku_regular':
        return 'Klassische Sudoku-Regeln: Jede Zeile, Spalte und Box enthält '
            'jede Ziffer genau einmal. Vorlagen gibt es für 4×4, 6×6, 8×8, '
            '9×9, 10×10, 12×12, 15×15 und 16×16.';
      case 'sudoku_x':
        return 'Sudoku-X: reguläre Sudoku-Regeln plus die beiden '
            'Hauptdiagonalen sind ebenfalls allDifferent. Wird als '
            '8×8-Vorlage geliefert.';
      case 'sudoku_disjoint':
        return 'Disjunkte Gruppen: reguläre Regeln plus eine zusätzliche '
            'allDifferent-Bedingung über die Zellen an derselben Position '
            'innerhalb der Box über alle Boxen hinweg.';
      case 'sudoku_killer':
        return 'Killer-Sudoku: keine Vorgaben; stattdessen ist das Gitter in '
            '„Käfige" unterteilt, jeder Käfig allDifferent und mit einer '
            'gegebenen Zielsumme.';
      default:
        return null;
    }
  }

  @override
  String? functionRefExampleHint(String id, int index) {
    const hints = <String, List<String>>{
      'solve': [
        'In CrispCalc liefert `solve(x^2 - 1, x)` eine Liste der Nullstellen '
            'im Python-Stil zurück. Der zugrunde liegende Aufruf ist '
            'SymEngines `solve()` (der Zweig für rationale Nullstellen bei '
            'Polynomen), von der Bridge umschlossen und zurück in eine '
            'Dart-Zeichenkette serialisiert.',
        '`=` in der Eingabe wird als Gleichungssyntax akzeptiert — der '
            'Präprozessor normalisiert `lhs = rhs` vor dem Bridge-Aufruf zu '
            '`lhs - rhs`.',
        'Komplexe Nullstellen kommen als SymEngines Literal `I` zurück. '
            'Verwendet man sie in weiteren Aufrufen (z. B. `expand((-I)*(I))`), '
            'hält die Bridge sie symbolisch.',
      ],
      'expand': [
        'In CrispCalc liefert `expand((x + 1)^2)` die binomische Entwicklung. '
            'Der zugrunde liegende Aufruf ist SymEngines `expand()`, das '
            '`Pow`- und `Mul`-Knoten auflöst und gleichartige Terme '
            'zusammenfasst.',
        'Die Koeffizienten entsprechen Zeile 5 des Pascalschen Dreiecks: '
            '1, 5, 10, 10, 5, 1, jeweils multipliziert mit der passenden '
            'Potenz von 2.',
        'Die dritte binomische Formel (Differenz von Quadraten) — nützlich im '
            'Wechselspiel mit `factor`, um zwischen den Formen zu wechseln.',
      ],
      'simplify': [
        'In CrispCalc kürzt `simplify` den gemeinsamen Faktor `(x - 2)`. Der '
            'zugrunde liegende Aufruf ist SymEngines `simplify()`, das '
            '`rational_simplify` sowie eine kleine Sammlung von '
            'Umformungsregeln versucht.',
        'Zusammenfassen gleichartiger Terme bei polynomieller Eingabe — '
            'intern ist das einfach `expand`, gefolgt vom Zusammenführen der '
            'Koeffizienten.',
        'Pythagoreische Identität; SymEngine wendet die trigonometrische '
            'Umformungsregel an, bevor das Literal `1` zurückgegeben wird.',
      ],
      'factor': [
        'In CrispCalc liefert `factor(x^2 - 1)` die Faktorisierung als '
            'Differenz von Quadraten. Der zugrunde liegende Aufruf ist '
            'SymEngines `factor()`, das für univariate Polynome über Q '
            'Berlekamp / Cantor–Zassenhaus verwendet.',
        'Identität für Summe/Differenz von Kuben: ein Linearfaktor mal ein '
            'über Q irreduzibles quadratisches Polynom.',
        'Die Faktorisierung endet bei der Irreduzibilität über Q — `x^2 + 1` '
            'zerfällt nicht weiter, ohne komplexe Nullstellen zuzulassen.',
      ],
      'diff': [
        'In CrispCalc wendet `diff(...)` die Potenz- und Konstantenregel '
            'termweise an. Der zugrunde liegende Aufruf ist SymEngines '
            '`diff()`, das den Ausdrucksbaum durchläuft und einen neuen '
            'symbolischen `Add`-Knoten erzeugt.',
        'Kettenregel: SymEngine wendet `diff(sin(u))/du * du/dx` für das '
            'innere `u = x^2` an.',
        'Produktregel — beachte, dass SymEngine das Ergebnis unfaktorisiert '
            'lässt. Durch `factor` geleitet, wird `exp(x)` ausgeklammert.',
      ],
      'integrate': [
        'In CrispCalc delegiert das unbestimmte `integrate(...)` an '
            'SymEngines `integrate()`. Partielle Integration wird automatisch '
            'angewandt, wenn ein Faktor zu einem Polynom differenziert.',
        'Bestimmte Form: Hat SymEngine eine geschlossene Stammfunktion, wendet '
            'es den Hauptsatz der Differential- und Integralrechnung an. '
            'Schlägt das symbolisch fehl, fällt CrispCalc auf die Simpson-Regel '
            '(200 Streifen) zurück.',
        'Partialbruchzerlegung: 1/(x²-1) = 1/(2(x-1)) - 1/(2(x+1)). SymEngine '
            'erledigt das Abdeckverfahren automatisch.',
      ],
      'subst': [
        'In CrispCalc schreibt `subst` den Ausdrucksbaum um und versucht '
            'anschließend einen Vereinfachungsdurchlauf. Der zugrunde liegende '
            'Aufruf ist SymEngines `xreplace()` (reine Variablenersetzung, '
            'kein Mustervergleich).',
        'Numerische Konstanten `pi`, `e` und die imaginäre Einheit `I` werden '
            'von SymEngine erkannt und über die trigonometrische Identität '
            'gefaltet.',
        'Die Ersetzung ist symbolisch — unbeteiligte freie Variablen `a` und '
            '`b` bleiben unverändert erhalten.',
      ],
      'limit': [
        'In CrispCalc ist `limit(...)` ein numerisches Verfahren: Die Bridge '
            'wertet den Ausdruck an einer Folge von Punkten aus, die gegen '
            '`point` konvergieren, und meldet den Grenzwert, sobald '
            'aufeinanderfolgende Stichproben bis zur Arbeitsgenauigkeit '
            'übereinstimmen. Keine symbolische Reihenentwicklung.',
        'Das Literal `oo` ist SymEngines Unendlichkeits-Sentinel — der '
            'Präprozessor erkennt es vor dem Dispatch. Verwende `-oo` für '
            'negative Unendlichkeit.',
        'Strebt gegen die eulersche Zahl. Da der Weg numerisch ist, ist das '
            'Ergebnis eine Gleitkommazahl — verwende `e(N)` für die '
            'hochpräzise Konstante.',
      ],
      'gcd': [
        'In CrispCalc nutzt der ganzzahlige `gcd(...)` die euklidische '
            'Rekursion gcd(a, b) = gcd(b, a mod b). Der zugrunde liegende '
            'Aufruf ist SymEngines `gcd()`, das im ganzzahligen Fall an GMPs '
            '`mpz_gcd` weiterreicht.',
        'Polynom-GGT über den Subresultanten-PRS-Algorithmus. Nützlich als '
            'Vorstufe zu `simplify` für Kürzungen.',
        'Konvention: `gcd(0, n) = |n|`. Entspricht der mathematischen '
            'Definition, die 0 als Vielfaches jeder ganzen Zahl behandelt.',
      ],
      'lcm': [
        'In CrispCalc wird das ganzzahlige `lcm(...)` über die Identität '
            '`lcm(a, b) = |a*b| / gcd(a, b)` berechnet. Der zugrunde liegende '
            'Aufruf ist SymEngines `lcm()`, das an GMPs `mpz_lcm` delegiert.',
        '36 = 2²·3², die Vereinigung der Primpotenzfaktoren aus 12 = 2²·3 und '
            '18 = 2·3².',
        'Das Polynom-kgV wählt das Vielfache höheren Grades — `x^2 - 1` '
            'enthält `x + 1` bereits als Faktor.',
      ],
      'factorial': [
        'In CrispCalc sind das Postfix `n!` und `factorial(n)` gleichwertig — '
            'der Präprozessor schreibt das Postfix in den Aufruf um. Für '
            '`n ≤ 1000` rechnen wir in Dart mit `BigInt`-Multiplikation; '
            'darüber hinaus ist der zugrunde liegende Aufruf SymEngines '
            '`factorial()`.',
        '158 Stellen, dank des BigInt-Wegs exakt erhalten — ein Wechsel zu '
            'IEEE-754 würde hier auf 1,0 × 10^157 runden.',
        'Konvention des leeren Produkts: 0! = 1. Notwendig, damit die '
            'Rekursion n! = n · (n-1)! bei 1 endet.',
      ],
      'fibonacci': [
        'In CrispCalc sind `fib(n)` und `fibonacci(n)` derselbe Aufruf. Für '
            '`n ≤ 90` nutzen wir eine vorberechnete Tabelle; für größere `n` '
            'ist der zugrunde liegende Aufruf SymEngines `fibonacci()`, das '
            'Fast-Doubling verwendet (O(log n) Multiplikationen über GMP).',
        'Die 50. Fibonacci-Zahl — weit jenseits der Tabellengrenze für kleine '
            'Terme, passt aber noch in eine vorzeichenbehaftete '
            '64-Bit-Ganzzahl.',
        'Wechselt in den GMP-gestützten Weg. Fast-Doubling vermeidet die '
            'lineare Rekurrenz mit O(n), sodass selbst fib(10000) unter einer '
            'Sekunde bleibt.',
      ],
      // --- Zahlentheorie ---
      'isprime': [
        'In CrispCalc gibt `isprime(n)` einen booleschen Chip zurück. Der '
            'zugrunde liegende Aufruf ist GMPs `mpz_probab_prime_p` (25 '
            'Miller-Rabin-Runden, Fehlerschranke 4^-25 ≈ 9×10^-16) über '
            'SymEngines `ntheory`-Modul. 2027 ist die 308. Primzahl.',
        '2024 = 2³·11·23.',
        'Die neunte Mersenne-Primzahl, M61. Miller-Rabin braucht selbst in '
            'dieser Größe nur Mikrosekunden — der Aufwand steckt in den '
            'modularen Potenzierungen, nicht in der Bitlänge.',
      ],
      'nextprime': [
        'In CrispCalc iteriert `nextprime(n)` von `n+1` aufwärts und testet '
            'jeden Kandidaten. Der zugrunde liegende Aufruf ist SymEngines '
            '`ntheory::nextprime()`, das über kurze Fenster FLINTs Sieb '
            'verwendet, wenn die Lücke groß ist.',
        'Echt größer — `nextprime(p)` ist niemals `p` selbst, auch wenn `p` '
            'prim ist.',
      ],
      'prevprime': [
        'In CrispCalc geht `prevprime(n)` von `n-1` abwärts. Der zugrunde '
            'liegende Aufruf ist SymEngines `ntheory::prevprime()`.',
        'Unter 2 existieren keine Primzahlen; die Bridge wirft einen Fehler, '
            'statt einen Sentinel-Wert zurückzugeben. CrispCalc zeigt den '
            'Fehler-Chip an.',
      ],
      'factorint': [
        'In CrispCalc liefert `factorint(n)` eine dargestellte '
            'Primfaktorzerlegung. Der zugrunde liegende Aufruf ist FLINTs '
            '`fmpz_factor`, vorgelagert über SymEngines ntheory-Wrapper; '
            'CrispCalc wandelt die Liste aus (Primzahl, Exponent) in die '
            'Darstellung mit hochgestellten Unicode-Ziffern um.',
        'Die 8. Mersenne-Primzahl, M31. Ein einziger Faktor (sie selbst) — '
            '`factorint` bricht ab, wenn die Eingabe prim ist.',
        'Sonderfall: Per Konvention hat 1 die leere Faktorzerlegung; CrispCalc '
            'stellt dies als das Literal `1` dar statt als leere Zeichenkette.',
      ],
      'divisors': [
        'In CrispCalc wird `divisors(n)` rein in Dart aus `factorint(n)` '
            'abgeleitet: jedes Produkt von Primzahlpotenzen pᵏ mit '
            '0 ≤ k ≤ Exponent. Die Anzahl ist ∏(eᵢ + 1) — hier '
            '(2+1)(1+1) = 6.',
        '28 ist eine vollkommene Zahl: Die Summe ihrer echten Teiler (alle '
            'außer 28 selbst) ergibt 28.',
      ],
      'totient': [
        'Die vier zu 12 teilerfremden Reste sind {1, 5, 7, 11}. CrispCalc '
            'berechnet φ aus der Primfaktorzerlegung über FLINTs '
            '`fmpz_euler_phi`.',
        'Für eine Primzahl p gilt φ(p) = p − 1, da jede kleinere positive '
            'Zahl zu p teilerfremd ist.',
      ],
      'modpow': [
        'Square-and-Multiply über GMPs `mpz_powm` — die Grundoperation '
            'modularer Arithmetik und (im Schulbuch) von RSA / '
            'Diffie-Hellman. Die riesige Zahl `2¹⁰⁰` wird nie explizit '
            'gebildet.',
        'Ein negativer Exponent invertiert zunächst die Basis, daher ist '
            '`modpow(a, -1, m)` gleich `modinv(a, m)` — hier 3⁻¹ ≡ 4 '
            '(mod 11). Fehler, wenn ggT(a, m) ≠ 1.',
      ],
      'modinv': [
        'Das eindeutige x in [0, m) mit a·x ≡ 1 (mod m), über GMPs '
            '`mpz_invert`. Probe: 3·4 = 12 ≡ 1 (mod 11).',
        'Nur Einheiten modulo m sind invertierbar. ggT(2, 4) = 2 ≠ 1, also '
            'existiert kein Inverses.',
      ],
      'jacobi': [
        'Für eine Primzahl n stimmt das Jacobi-Symbol mit dem '
            'Legendre-Symbol überein — hier ist 2 ein quadratischer Rest '
            'modulo 7 (denn 3² ≡ 2). Über GMPs `mpz_jacobi`.',
        'Das Symbol ist genau dann 0, wenn ggT(a, n) ≠ 1; hier ist '
            'ggT(6, 9) = 3.',
      ],
      'cfrac': [
        'In CrispCalc führt `cfrac` eine exakte BigInt-Entwicklung über eine '
            'hochpräzise MPFR-Näherung der Konstante aus. Das große Glied 292 '
            'ist genau der Grund, warum der Näherungsbruch 355/113 π so '
            'bemerkenswert gut annähert.',
        'Für eine exakte rationale Zahl ist die Entwicklung endlich — das ist '
            'nichts anderes als der euklidische Algorithmus, der seine '
            'Quotienten protokolliert.',
      ],
      'convergent': [
        'Milü — die Näherung von π durch Zu Chongzhi (5. Jahrhundert), auf '
            'sechs Dezimalstellen genau. CrispCalc faltet die ersten k+1 '
            'Teilquotienten von `cfrac` zum Bruch zusammen.',
        'Die Schulbuch-Näherung von π; `convergent(x, 0)` ist der ganzzahlige '
            'Anteil ⌊x⌋.',
      ],
      // --- Hochpräzision ---
      'pi_precision': [
        'In CrispCalc ist `pi(N)` ein gesondert behandelter Aufruf, der vor '
            'SymEngine auf den Hochpräzisionspfad geleitet wird. Der zugrunde '
            'liegende Aufruf ist MPFRs `mpfr_const_pi` mit der Genauigkeit '
            '⌈N·log2(10)⌉ + 16 Schutzbits, gefolgt von der Umwandlung ins '
            'Dezimalsystem.',
        'Bei N = 100 beträgt die Arbeitsgenauigkeit ≈ 348 Bit. Die Schutzbits '
            'verhindern, dass die Basisumwandlung gerundete Endziffern '
            'anzeigt.',
      ],
      'e_precision': [
        'In CrispCalc spiegelt `e(N)` die Pipeline von `pi(N)` wider: MPFRs '
            '`mpfr_const_e` (das die Taylor-Reihe Σ 1/k! verwendet) mit der '
            'Genauigkeit ⌈N·log2(10)⌉ + 16 Schutzbits, dann die Darstellung '
            'im Dezimalsystem.',
        'Kurz genug zum Merken — nützlich als schnelle Genauigkeitsprobe gegen '
            '`limit((1 + 1/n)^n, n, oo)`.',
      ],
      'sqrt_precision': [
        'In CrispCalc ist das zweiargumentige `sqrt(k, N)` der '
            'Hochpräzisionsweg. Der zugrunde liegende Aufruf ist MPFRs '
            '`mpfr_sqrt_ui` mit der Genauigkeit ⌈N·log2(10)⌉ + 16 Schutzbits. '
            'Das einargumentige `sqrt(2)` gibt stattdessen das symbolische '
            '`sqrt(2)` über SymEngine zurück.',
        'Nützlich zur Überprüfung — `sqrt(3, N)` sollte mit unabhängig '
            'hergeleiteten Referenzziffern übereinstimmen.',
      ],
      'eulergamma_precision': [
        'In CrispCalc verwendet `EulerGamma(N)` MPFRs `mpfr_const_euler`, das '
            'γ über die Brent-McMillan-Formel (modifizierte Bessel-Funktionen) '
            'auswertet. Die Genauigkeit beträgt ⌈N·log2(10)⌉ + 16 Schutzbits, '
            'passend zur Pipeline von `pi(N)` und `e(N)`.',
        'γ hat keine bekannte geschlossene Form. Die MPFR-Routine ist die '
            'Standard-Referenzimplementierung; CrispCalc stellt lediglich die '
            'Ziffernfolge dar.',
      ],
      // --- Matrizen / Lineare Algebra ---
      'matrix_literal': [
        'In CrispCalc wird das Literal `Matrix(...)` vom Matrix-Auswerter '
            'erkannt, bevor die Engine den Ausdruck sieht. Der zugrunde '
            'liegende Aufruf ist SymEngines Konstruktor `DenseMatrix` — das '
            'Zeilen-/Spaltenlayout wird bei der Konstruktion festgelegt.',
        'Zellen bleiben symbolisch — rationale Zahlen werden nicht zu '
            'Gleitkommazahlen reduziert. Dasselbe gilt für freie Symbole: '
            '`Matrix([[a, b], [c, d]])` wird akzeptiert und durch `det` / '
            '`inv` / `rref` propagiert.',
        'Nicht-quadratische Matrizen sind für `transpose` und `rref` in '
            'Ordnung, schlagen aber bei `det` / `inv` fehl, die quadratische '
            'Eingaben erfordern.',
      ],
      'det': [
        'In CrispCalc wird `det(M)` als einzelner Skalar ausgewertet. Der '
            'zugrunde liegende Aufruf ist SymEngines `DenseMatrix::det()`, das '
            'den bruchfreien Bareiss-Algorithmus verwendet — exakt für '
            'symbolische/rationale Einträge, ohne Aufblähen durch '
            'Gleitkommazahlen.',
        'Klassisches 3×3-Lehrbuchbeispiel — die Laplace-Entwicklung nach '
            'Kofaktoren liefert in 6 Termen dasselbe Ergebnis.',
        'Symbolische Einträge bleiben unverändert. Bareiss behält das Ergebnis '
            'als SymEngine-`Add` statt als Gleitkommazahl.',
      ],
      'inv': [
        'In CrispCalc gibt `inv(M)` `adj(M)/det(M)` zurück. Der zugrunde '
            'liegende Aufruf ist SymEngines `DenseMatrix::inv()`, das den '
            'Gauß-Jordan-Algorithmus über den rationalen Zahlen verwendet — '
            'die Einträge kommen als exakte Brüche zurück, nicht als '
            'Gleitkommazahlen.',
        'Die Einheitsmatrix ist zu sich selbst invers — eine schnelle '
            'Funktionsprobe, dass die Bridge korrekt hin- und zurückrechnet.',
        'Singuläre Eingaben (det = 0) führen zu einem sauberen Fehler, statt '
            'unsinnig große Zahlen zurückzugeben. Der Fehler-Chip erscheint im '
            'Rechnerverlauf.',
      ],
      'transpose': [
        'In CrispCalc ist `transpose(M)` auf der Dart-Seite implementiert, '
            'weil die Bridge keinen Einstiegspunkt zum Transponieren '
            'bereitstellt. Wir legen eine neue `SymEngineMatrix` mit '
            'vertauschten Dimensionen an und kopieren die Zellen Element für '
            'Element.',
        'Rechteckige Eingabe: aus einer 2×3 wird eine 3×2 — nützlich für '
            'gepaarte Datenlayouts.',
        'Idempotent bei zweimaliger Anwendung. Bestätigt, dass das Vertauschen '
            'der Zellen den symbolischen Inhalt unverändert lässt.',
      ],
      'rref': [
        'In CrispCalc führt `rref` Gauß-Jordan in Dart aus und ruft bei jeder '
            'Zellaktualisierung SymEngines `simplify()` auf. Die Bridge stellt '
            '`rref` nicht direkt bereit, daher durchläuft der Algorithmus die '
            'Spalten von links nach rechts, skaliert die Pivotzeile und '
            'eliminiert dann die Spalte darüber und darunter.',
        'Rangdefiziente Eingabe: Die zweite Zeile reduziert sich zu lauter '
            'Nullen. Nützlich, um lineare Abhängigkeit visuell zu erkennen.',
        'Die Pivot-Skalierung normiert die führenden Einträge auf 1. Die '
            'Erkennung symbolischer Nicht-Null-Werte ist die Schwachstelle — '
            'siehe den Algorithmus-Hinweis in `matrix_evaluator.dart`.',
      ],
      'matrix_arithmetic': [
        'In CrispCalc werden binäre Matrixoperationen vom Matrix-Auswerter '
            'verarbeitet, wenn beide Operanden als `Matrix(...)`-Literale '
            'geparst werden. Der zugrunde liegende Aufruf ist SymEngines '
            '`add_dense_dense`; die Subtraktion läuft über `add_dense_dense` '
            'mit elementweiser Negation der rechten Seite.',
        'Die Multiplikation ist das übliche Skalarprodukt Zeile mal Spalte '
            'über SymEngines `mul_dense_dense`. Die Rechtsmultiplikation mit '
            'der Einheitsmatrix ist eine Funktionsprobe.',
        'Die Subtraktion ist elementweise; eine Dimensionsabweichung führt '
            'sauber zum Fehler `Error: matrix - failed: …`.',
      ],
      // --- Statistik ---
      'mean': [
        'In CrispCalc wird `mean` von `DescriptiveStats.mean` berechnet (siehe '
            '`lib/engine/statistics.dart`) — eine Summe in einem Durchlauf / '
            'n. Für gepaarte oder gruppierte Daten stellt das Statistik-Modul '
            'außerdem Standardabweichung, Median, Quartile und den '
            'Interquartilsabstand bereit.',
        'Gleitkomma-Eingabe — die Implementierung summiert in `double`, daher '
            'können sehr große oder größenmäßig gemischte Listen einen stabilen '
            'Summationsalgorithmus erfordern, wenn du >15 Stellen brauchst.',
      ],
      'welch_t': [
        'In CrispCalc liegt `welchT` in `lib/engine/hypothesis_tests.dart`. '
            'Der zugrunde liegende Aufruf berechnet die Teststatistik '
            't = (x̄_A − x̄_B) / √(s_A²/n_A + s_B²/n_B), nähert dann die '
            'Freiheitsgrade über Welch-Satterthwaite an und liest den p-Wert '
            'aus `TDistribution.cdf` ab.',
        'Fall mit winziger Stichprobe — der Welch-Freiheitsgrad ≈ 4, obwohl '
            'n_A + n_B = 6, weil die Zweistichproben-t-Verteilung die '
            'Unsicherheit der Varianzschätzung berücksichtigt.',
      ],
      'paired_t': [
        'In CrispCalc reduziert sich `pairedT` auf einen Einstichproben-t-Test '
            'des Differenzvektors d = nachher − vorher. Der zugrunde liegende '
            'Aufruf ist derselbe `TDistribution.cdf`-Weg wie bei `welchT`, '
            'jedoch mit df = n - 1 (keine Welch-Korrektur, da nur eine '
            'Varianzschätzung vorzunehmen ist).',
        'Sonderfall: Identische Verschiebungen erzeugen eine Varianz von null '
            'in den Differenzen, was die Implementierung als Grenzfall p = 0 '
            'darstellt statt als NaN.',
      ],
      'anova_1': [
        'In CrispCalc zerlegt `anovaOneWay` die Gesamt-Quadratsumme in die '
            'Quadratsumme zwischen den Gruppen und die innerhalb der Gruppen. '
            'Der zugrunde liegende Aufruf ist F = MS_zwischen / MS_innerhalb '
            'mit df1 = K - 1 und df2 = N - K, dann `FDistribution.sf` für den '
            'p-Wert des oberen Endes.',
        'Gleiche Streuung und gut getrennte Mittelwerte erzeugen ein hohes F. '
            'H₀ (alle Mittelwerte gleich) wird bei α = 0,05 verworfen.',
      ],
      'chi2_goodness': [
        'In CrispCalc wertet `chiSquareGof` Σ (O - E)² / E aus und liest den '
            'p-Wert des oberen Endes aus `ChiSquaredDistribution.sf` mit '
            'df = k - 1 ab, wobei k die Anzahl der Kategorien ist. Es wird '
            'angenommen, dass die zugrunde liegenden Zellhäufigkeiten ≥ 5 '
            'sind — die Implementierung wendet keine automatische '
            'Yates-Korrektur an.',
        'Perfekte Übereinstimmung → χ² = 0 → H₀ wird bei keinem α verworfen.',
      ],
      'chi2_independence': [
        'In CrispCalc berechnet `chiSquareIndependence` die erwarteten '
            'Häufigkeiten aus den Randsummen von Zeile × Spalte '
            '(E_ij = Zeile_i · Spalte_j / Gesamt), dann Σ (O - E)² / E mit '
            'df = (Zeilen - 1) · (Spalten - 1). Der zugrunde liegende p-Wert '
            'stammt aus `ChiSquaredDistribution.sf`.',
        'Starke Konzentration außerhalb der Diagonale → niedriger p-Wert. Bei '
            'dünn besetzten 2×2-Tafeln ist `fisher_exact` vorzuziehen, das '
            'nicht auf der Chi-Quadrat-Näherung für große Stichproben beruht.',
      ],
      'fisher_exact': [
        'In CrispCalc zählt `fisherExact` alle 2×2-Tafeln mit denselben '
            'Randsummen auf und summiert die hypergeometrischen '
            'Wahrscheinlichkeiten der Tafeln, die mindestens so extrem wie die '
            'beobachtete sind. Der zugrunde liegende Aufruf berechnet '
            'log-Binomialterme, um einen Überlauf bei großen Summen zu '
            'vermeiden, und potenziert dann; der zweiseitige p-Wert folgt der '
            'Konvention von R (Summe der Endwahrscheinlichkeiten ≤ der '
            'beobachteten).',
        'Symmetrische Tafel → kein Hinweis auf einen Zusammenhang.',
      ],
      'wilcoxon': [
        'In CrispCalc fasst `wilcoxonRankSum` beide Stichproben zusammen, '
            'vergibt mittelwertkorrigierte Ränge, summiert die Ränge der '
            'Gruppe A und gibt das z der Normalnäherung aus. Der zugrunde '
            'liegende Aufruf wendet eine Bindungskorrektur auf die Varianz an '
            'und liest den zweiseitigen p-Wert aus der Normalverteilungs-CDF '
            'ab.',
        'Fall mit winziger Stichprobe — die Normalnäherung ist bei '
            'n_A + n_B = 6 grenzwertig. Für sehr kleine Stichproben ist die '
            'exakte Permutationsverteilung vorzuziehen (noch nicht enthalten).',
      ],
      'sign_test': [
        'In CrispCalc verwirft `pairedSign` Paare mit Differenz null, zählt '
            'die positiven unter den verbleibenden n und testet gegen '
            'Binomial(n, 0,5). Der zugrunde liegende p-Wert nutzt das exakte '
            'Binomialende — keine Normalnäherung, daher die richtige Wahl für '
            'sehr kleine gepaarte Stichproben.',
        'Ein gebundenes Paar (4 → 4) wird verworfen, sodass n = 3 positive von '
            '3 informativen Paaren übrig bleiben. Der zweiseitige exakte '
            'p-Wert ist 2 · min(Binom(3, 0,5).cdf(3), …).',
      ],
      // --- Constraints-DSL ---
      'vars': [
        'In CrispCalc wird die Zeile `vars:` von `DslToFlatZinc` geparst '
            '(siehe `lib/engine/csp_solver.dart`) und erzeugt pro Name eine '
            'FlatZinc-Deklaration `var int: x :: …`. Die Bereichsgrenzen sind '
            'konkrete ganze Zahlen; symbolische Wertebereiche werden nicht '
            'unterstützt.',
        'Ein Wertebereich `0..1` modelliert eine boolesche Variable. FlatZinc '
            'hat einen eigenen Typ `var bool` — der Parser greift ihn nicht '
            'auf, aber der Solver verarbeitet die 0/1-Ganzzahl genauso '
            'effizient.',
      ],
      'all_different': [
        'In CrispCalc wird `allDifferent` in FlatZincs '
            '`all_different_int([a, b, c])` übersetzt. Der zugrunde liegende '
            'Solver (dart_csp) implementiert die Propagation der '
            'Schrankenkonsistenz über Régins Matching-Algorithmus — bei großen '
            'Argumentlisten deutlich schneller als paarweise.',
        'Die Sudoku-Vorlagen im Sudoku-Modul bauen auf Stapeln von '
            '`allDifferent`-Bedingungen auf — eine pro Zeile, Spalte, Box und '
            'etwaige Variantenzonen.',
      ],
      'no_overlap': [
        'In CrispCalc wird `noOverlap` in FlatZincs '
            '`disjunctive([s1, s2, s3], [4, 3, 2])` übersetzt. Der zugrunde '
            'liegende Solver verwendet Edge-Finding plus Vilíms '
            'θ-Baum-Propagator — derselbe Algorithmus wie in MiniZincs '
            'eingebauter Variante.',
        'Klassisches Sequenzierungsproblem auf einer Maschine. In Kombination '
            'mit `minimize` über den Makespan-Ausdruck ergibt sich der optimale '
            'Ablaufplan. Das vollständige DSL-Programm zeigt das zugehörige '
            'Beispiel.',
      ],
      'cumulative': [
        'In CrispCalc wird `cumulative` in FlatZincs '
            '`cumulative([starts], [durations], [resources], capacity)` '
            'übersetzt. Der zugrunde liegende Solver verwendet '
            'Timetable-Propagation plus energetisches Schließen — '
            'kapazitätsbewusste Varianten der `noOverlap`-Propagatoren.',
        'Das ressourcenbeschränkte Projektplanungsproblem (RCPSP) stapelt '
            'mehrere `cumulative`-Bedingungen, eine pro Ressourcentyp. Das '
            'Beispiel `dslRcpsp` zeigt ein Projekt mit zwei Ressourcen.',
      ],
      'minimize': [
        'In CrispCalc erzeugt `minimize` FlatZincs '
            '`solve minimize __obj__;`, nachdem die Zielvariable durch das '
            'Parsen des linearen Ausdrucks konstruiert wurde. Der zugrunde '
            'liegende Solver verwendet Branch-and-Bound — Zulässigkeitsprüfung, '
            'dann Verschärfen der oberen Schranke bei jeder verbessernden '
            'Lösung.',
        'Siehe das Beispiel `dslCoinChange` — minimiere über eine Summe von '
            'Indikatorvariablen, um die kleinste Menge an Münzen zu finden, '
            'die den Zielbetrag ergibt.',
      ],
      'maximize': [
        'In CrispCalc erzeugt `maximize` FlatZincs `solve maximize __obj__;`. '
            'Der zugrunde liegende Solver führt Branch-and-Bound genau wie '
            '`minimize` aus, jedoch mit umgekehrtem Verschärfen der unteren '
            'Schranke.',
        'Klassisches 0/1-Rucksackproblem. Das DSL behandelt dies natürlich als '
            'Deklaration `vars: x_1, ... in 0..1` plus einer linearen '
            'Kapazitätsbedingung und einer linearen Zielfunktion.',
      ],
      // --- Sudoku-Varianten ---
      'sudoku_regular': [
        'In CrispCalc liegt die reguläre Variante in `lib/engine/sudoku.dart` '
            'als `SudokuVariant.regular`. Der zugrunde liegende Solver '
            'instanziiert ein `allDifferent` pro Zeile, Spalte und Box '
            '(insgesamt 27 bei 9×9) und übergibt sie an `dart_csp`.',
      ],
      'sudoku_x': [
        'In CrispCalc ist Sudoku-X `SudokuVariant.x` '
            '(`lib/engine/sudoku.dart`). Der zugrunde liegende Solver fügt '
            'zusätzlich zum regulären Trio aus Zeile/Spalte/Box zwei weitere '
            '`allDifferent`-Bedingungen hinzu — eine pro Diagonale.',
      ],
      'sudoku_disjoint': [
        'In CrispCalc ist dies `SudokuVariant.disjoint`. Für ein N×N-Gitter '
            'mit √N × √N großen Boxen fügt die Bedingung N weitere '
            '`allDifferent`-Überlagerungen hinzu — eine pro Position innerhalb '
            'der Box. Die 8×8 wird als einzelne Vorlage geliefert.',
      ],
      'sudoku_killer': [
        'In CrispCalc ist dies `SudokuVariant.killer`. Der zugrunde liegende '
            'Solver legt über das reguläre Trio aus Zeile/Spalte/Box je Käfig '
            'eine `allDifferent`-Bedingung und je Käfig eine Bedingung '
            '`Summe = Ziel`. Die Killer-Vorlagen für 4×4 und 9×9 werden beide '
            'geliefert.',
      ],
    };
    final list = hints[id];
    if (list == null || index < 0 || index >= list.length) return null;
    return list[index];
  }

  @override
  String get settingsWorkedExamples => 'Bibliothek mit Beispielaufgaben';
  @override
  String get settingsWorkedExamplesSubtitle =>
      'Jetzt auch über das Buchsymbol oben im Rechner und im Notizblock '
      'erreichbar. Hier tippen für die vollständige Bibliothek.';
  @override
  String get functionRefTitle => 'Funktionsreferenz';
  @override
  String get functionRefSearchHint => 'Funktionen durchsuchen…';
  @override
  String get functionRefEmpty => 'Keine Funktion entspricht diesem Filter.';
  @override
  String get functionRefSeeAlso => 'Siehe auch:';
  @override
  String get functionRefTryInCalculator => 'Im Rechner ausprobieren';
  @override
  String get functionRefSeeWorkedExample => 'Beispielaufgabe ansehen';
  @override
  String get functionRefCatCas => 'CAS';
  @override
  String get functionRefCatNumberTheory => 'Zahlentheorie';
  @override
  String get functionRefCatPrecision => 'Hochpräzision';
  @override
  String get functionRefCatMatrix => 'Matrix';
  @override
  String get functionRefCatGraphing => 'Graphen';
  @override
  String get functionRefCatStatistics => 'Statistik';
  @override
  String get functionRefCatConstraints => 'Bedingungen';
  @override
  String get functionRefCatSudoku => 'Sudoku';
  @override
  String get functionRefCatUnits => 'Einheiten';
  @override
  String get settingsFunctionRef => 'Funktionsreferenz';
  @override
  String get settingsFunctionRefSubtitle =>
      'Jede CrispCalc-Funktion durchstöbern: Signatur, Beispiele, '
      'verwandte Funktionen und ein Schnellzugriff in den Rechner.';

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
  String get navNotepad => 'Notes';
  @override
  String get notepadDefaultDocName => 'Sans titre';
  @override
  String get notepadAddLine => 'Ajouter une ligne';
  @override
  String get notepadDeleteLine => 'Supprimer la ligne';
  @override
  String get notepadDocumentMenu => 'Menu du document';
  @override
  String get notepadNewDocument => 'Nouveau document';
  @override
  String get notepadOpenWelcomeSample => 'Ouvrir l\'exemple de bienvenue';
  @override
  String get notepadRecalculateAll => 'Tout recalculer';
  @override
  String get notepadRename => 'Renommer';
  @override
  String get notepadDuplicate => 'Dupliquer';
  @override
  String get notepadCopyAsMarkdown => 'Copier en Markdown';
  @override
  String get notepadDeleteDocument => 'Supprimer le document';
  @override
  String get notepadUndo => 'Annuler';
  @override
  String get notepadLineDeleted => 'Ligne supprimée';
  @override
  String notepadDocumentDeleted(String name) => 'Document « $name » supprimé';
  @override
  String get notepadCopiedAsMarkdown => 'Copié en Markdown';
  @override
  String get notepadCopyResult => 'Copier le résultat';
  @override
  String get notepadCopyAsLatex => 'Copier en LaTeX';
  @override
  String get notepadCopiedResult => 'Résultat copié';
  @override
  String get notepadCopiedAsLatex => 'Copié en LaTeX';
  @override
  String get notepadEmptyTitle => 'Aucun document';
  @override
  String get notepadEmptyBody =>
      'Créez un nouveau document ou ouvrez l\'exemple de bienvenue pour commencer.';
  @override
  String notepadFreeVars(String names) => 'libre : $names';
  @override
  String notepadBlockedBy(String alias) => 'Bloqué par $alias';
  @override
  String notepadCycle(String path) => 'Cycle : $path';
  @override
  String notepadUnknownImport(String name) =>
      'Import inconnu : « $name » absent des variables globales';
  @override
  String notepadInvalidImport(String name) =>
      'Nom d\'import invalide : « $name »';
  @override
  String get notepadEmptyImportList => 'Liste d\'imports vide';
  @override
  String notepadUseDirective(String code) => 'Directive use : $code';
  @override
  String get notepadManageTitle => 'Gérer les notes';
  @override
  String get notepadManageNotepads => 'Gérer les notes…';
  @override
  String get notepadOpenDocument => 'Ouvrir';
  @override
  String get notepadExportAsJson => 'Exporter en JSON';
  @override
  String get notepadImportFromJson => 'Importer depuis JSON';
  @override
  String get notepadImport => 'Importer';
  @override
  String get notepadImportJsonHint =>
      'Collez ici une charge utile JSON de note…';
  @override
  String get notepadJsonCopied => 'JSON de note copié dans le presse-papiers';
  @override
  String notepadJsonImported(String name) => '« $name » importé';
  @override
  String get notepadJsonImportFailed =>
      'Échec de l\'import : charge utile JSON de note invalide';
  @override
  String get graphErrorEmpty => 'La fonction est vide';
  @override
  String get graphErrorUnbalanced =>
      'Parenthèses ou crochets non équilibrés — la fonction ne peut pas être tracée';
  @override
  String get graphErrorTrailingOperator =>
      'La fonction se termine par un opérateur — ajoutez le membre de droite';
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

  // -- P9-A2 --
  @override
  String get module3DScene => 'Scène 3D';
  @override
  String get module3DSceneSubtitle =>
      'Rendre plusieurs objets 3D ensemble — plans, droites, sphères, quadriques';
  @override
  String get scene3DAddPlane => 'Ajouter un plan';
  @override
  String get scene3DEditPlane => 'Modifier le plan';
  @override
  String get scene3DEmpty =>
      'Glisser pour tourner · pincer pour zoomer · appuyer sur + pour ajouter un plan';
  @override
  String get scene3DPanelEmpty => 'Aucun objet pour l\'instant';
  @override
  String get scene3DObjectLabel => 'Étiquette';
  @override
  String get scene3DColor => 'Couleur';
  @override
  String get scene3DAdd => 'Ajouter';
  @override
  String get scene3DSave => 'Enregistrer';
  @override
  String get scene3DEdit => 'Modifier';
  @override
  String get scene3DDelete => 'Supprimer';
  @override
  String get scene3DHide => 'Masquer';
  @override
  String get scene3DShow => 'Afficher';
  @override
  String get scene3DLabelRequired => 'Étiquette requise';
  @override
  String get scene3DCoefRequired => 'Requis';
  @override
  String get scene3DCoefInvalid => 'Nombre invalide';
  @override
  String get scene3DPlaneZeroNormal =>
      'Le vecteur normal (a, b, c) doit être non nul';

  // -- P9-A3 --
  @override
  String get scene3DAddObject => 'Ajouter un objet';
  @override
  String get scene3DAddLine => 'Ajouter une droite';
  @override
  String get scene3DEditLine => 'Modifier la droite';
  @override
  String get scene3DAddSphere => 'Ajouter une sphère';
  @override
  String get scene3DEditSphere => 'Modifier la sphère';
  @override
  String get scene3DLinePointDir => 'Point + direction';
  @override
  String get scene3DLineTwoPoints => 'Deux points';
  @override
  String get scene3DLinePoint => 'Point';
  @override
  String get scene3DLineDirection => 'Direction';
  @override
  String get scene3DLineFirstPoint => 'Premier point';
  @override
  String get scene3DLineSecondPoint => 'Second point';
  @override
  String get scene3DLineZeroDirection =>
      'Le vecteur direction doit être non nul (ou choisir deux points distincts)';
  @override
  String get scene3DSphereCenter => 'Centre';
  @override
  String get scene3DSphereRadius => 'Rayon';
  @override
  String get scene3DSpherePositiveRadius =>
      'Le rayon doit être strictement positif';

  // -- P9-A4 --
  @override
  String get scene3DIntersectionsEmpty =>
      'Ajoutez deux objets ou plus pour voir leurs intersections';
  @override
  String scene3DIntersectionsTitle(int n) =>
      n == 1 ? '1 intersection' : '$n intersections';
  @override
  String get intersectionPoint => 'Point';
  @override
  String get intersectionTwoPoints => 'Deux points';
  @override
  String get intersectionLine => 'Droite';
  @override
  String get intersectionCircle => 'Cercle';
  @override
  String intersectionReason(String key) {
    switch (key) {
      case 'parallelPlanes':
        return 'Plans parallèles (aucune intersection)';
      case 'coincidentPlanes':
        return 'Plans confondus';
      case 'lineParallelToPlane':
        return 'Droite parallèle au plan (aucune intersection)';
      case 'lineInPlane':
        return 'Droite contenue dans le plan';
      case 'sphereMissesPlane':
        return 'Le plan ne touche pas la sphère';
      case 'degeneratePlane':
        return 'Plan dégénéré (vecteur normal nul)';
      case 'parallelLines':
        return 'Droites parallèles (aucune intersection)';
      case 'coincidentLines':
        return 'Droites confondues';
      case 'skewLines':
        return 'Droites non coplanaires (ne se rencontrent pas)';
      case 'lineMissesSphere':
        return 'La droite ne touche pas la sphère';
      case 'degenerateLine':
        return 'Droite dégénérée (direction nulle)';
      case 'spheresApart':
        return 'Sphères trop éloignées';
      case 'sphereInsideSphere':
        return 'Une sphère est contenue dans l\'autre';
      case 'coincidentSpheres':
        return 'Sphères identiques';
      case 'numericalFailure':
        return 'Cas numérique limite (essayer d\'autres valeurs)';
      // P9-A5b: plan × quadrique → conique.
      case 'circle':
        return 'Cercle';
      case 'ellipse':
        return 'Ellipse';
      case 'parabola':
        return 'Parabole';
      case 'hyperbola':
        return 'Hyperbole';
      case 'degenerateConic':
        return 'Conique dégénérée (paire de droites ou point)';
      case 'noConic':
        return 'Le plan ne touche pas la quadrique';
      case 'planeOnQuadric':
        return 'Le plan repose sur la quadrique';
      default:
        return key;
    }
  }

  // -- P9-A5 --
  @override
  String get scene3DAddQuadric => 'Ajouter une quadrique';
  @override
  String get scene3DEditQuadric => 'Modifier la quadrique';
  @override
  String get scene3DQuadricKind => 'Type';
  @override
  String get scene3DQuadricSemiAxes => 'Demi-axes';
  @override
  String get scene3DQuadricPositiveSemiAxes =>
      'Les demi-axes doivent être strictement positifs (a, b, c > 0)';
  @override
  String get quadricKindEllipsoid => 'Ellipsoïde';
  @override
  String get quadricKindCone => 'Cône elliptique';
  @override
  String get quadricKindCylinder => 'Cylindre elliptique';
  @override
  String get quadricKindParaboloid => 'Paraboloïde elliptique';
  @override
  String get quadricKindHyperboloid1 => 'Hyperboloïde (1 nappe)';
  @override
  String get quadricKindHyperboloid2 => 'Hyperboloïde (2 nappes)';

  // -- P9-A5c.3 --
  @override
  String get conicOpenIn3DScene => 'Ouvrir dans la scène 3D';
  @override
  String get conicLiftNotAConic =>
      'Ce n\'est pas une conique — rien à transposer. Ajoutez d\'abord des termes quadratiques.';

  // -- P9-A6 --
  @override
  String get scene3DAddParametricSurface => 'Ajouter une surface paramétrique';
  @override
  String get scene3DEditParametricSurface => 'Modifier la surface paramétrique';
  @override
  String get scene3DAddParametricCurve => 'Ajouter une courbe paramétrique';
  @override
  String get scene3DEditParametricCurve => 'Modifier la courbe paramétrique';
  @override
  String get scene3DParametricSurface => 'Surface paramétrique';
  @override
  String get scene3DParametricCurve => 'Courbe paramétrique';

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
  String settingsNumberFormatDecimalPlaces(int n) => 'Décimales : $n';
  @override
  String get settingsAutoBindSolve => 'Liaison automatique des solutions';
  @override
  String get settingsAutoBindSolveSubtitle =>
      'Si activé, solve(éq, x) assigne aussi la solution à x.';
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

  // -- Round 91 --
  @override
  String get storeAsVariable => 'Enregistrer comme variable';
  @override
  String get storeAsFunction => 'Enregistrer comme fonction';
  @override
  String get storeVariableTitle => 'Enregistrer comme variable';
  @override
  String get storeFunctionTitle => 'Enregistrer comme fonction';
  @override
  String get storeNameLabel => 'Nom';
  @override
  String get storeFunctionParamLabel => 'Paramètre';
  @override
  String get storeButton => 'Enregistrer';
  @override
  String get storeNameReserved => 'Nom réservé par une fonction intégrée';
  @override
  String storeSavedAs(String name) => 'Enregistré comme $name';

  // -- R91b --
  @override
  String storeOverwriteTitle(String name) => 'Remplacer « $name » ?';
  @override
  String storeOverwriteCurrent(String existing) => 'Actuellement : $existing';
  @override
  String get storeOverwriteConfirm => 'Remplacer';

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
  String get sudokuClearToStart => 'Réinitialiser';
  @override
  String get sudokuSolvedCorrectly => 'Résolu !';
  @override
  String get sudokuFilledWithErrors => 'Avec des erreurs';
  @override
  String get sudokuWinOverlayTapHint => 'Toucher pour fermer';
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
      case 'eight8x8':
        return '8×8 moyen';
      case 'eight8x8X':
        return '8×8 Sudoku-X moyen';
      case 'eight8x8Disjoint':
        return '8×8 Disjoint moyen';
      case 'eight8x8Killer':
        return '8×8 Killer';
      case 'ten10x10':
        return '10×10 moyen';
      case 'twelve12x12':
        return '12×12 moyen';
      case 'fifteen15x15':
        return '15×15 moyen';
      case 'standard9x9Easy':
        return '9×9 facile';
      case 'standard9x9Medium':
        return '9×9 moyen';
      case 'standard9x9Hard':
        return '9×9 difficile (AI Escargot)';
      case 'standard9x9XEasy':
        return '9×9 Sudoku-X facile';
      case 'killer4x4':
        return '4×4 Killer';
      case 'killer9x9':
        return '9×9 Killer';
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
  String get sudokuVariantKiller => 'Killer';
  @override
  String get sudokuVariantDisjoint => 'Disjoint';
  @override
  String get sudokuCheckUnique => "Vérifier l'unicité";
  @override
  String get sudokuUniqueSolution => 'Solution unique';
  @override
  String get sudokuMultipleSolutions => 'Plusieurs solutions';
  @override
  String get sudokuShowHints => 'Afficher les indices';
  @override
  String get sudokuShowHintsSubtitle =>
      'Annotations au crayon : pour chaque case vide, les chiffres '
      'pas encore éliminés par la ligne, la colonne, le bloc ou la '
      'diagonale.';
  @override
  String get sudokuHintLevelOff => 'Désactivé';
  @override
  String get sudokuHintLevelBasic => 'Simple';
  @override
  String get sudokuHintLevelAdvanced => 'Avancé';
  @override
  String get sudokuHintLevelAdvancedHelp =>
      'Le mode avancé exécute le solveur CSP complet sur chaque '
      'candidat ; il détecte aussi les singletons cachés et les '
      'paires nues. Plus lent — quelques secondes sur les grilles '
      '9×9 difficiles.';
  @override
  String get sudokuHintLevelComputing => 'Calcul des indices avancés…';

  @override
  String sudokuConstraintRow(int row) => 'Ligne $row';
  @override
  String sudokuConstraintCol(int col) => 'Colonne $col';
  @override
  String sudokuConstraintBox(int box) => 'Bloc $box';
  @override
  String sudokuConstraintCage(int cage, int sum) => 'Cage $cage (somme $sum)';
  @override
  String get sudokuConstraintMainDiagonal => 'Diagonale principale';
  @override
  String get sudokuConstraintAntiDiagonal => 'Anti-diagonale';
  @override
  String sudokuConstraintDisjointGroup(int group) => 'Groupe disjoint $group';
  @override
  String get sudokuConstraintStartingPosition => 'Position de départ';

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
  String get constraintsTabDsl => 'Texte libre';
  @override
  String get constraintsTabFlatZinc => 'FlatZinc';
  @override
  String get constraintsDslIntro =>
      'Déclarer des variables avec `vars: x, y in 1..9`, '
      'utiliser `allDifferent(x, y, z)` pour la distinction, '
      "et écrire toute autre ligne comme contrainte "
      '(p. ex. `x + 2*y == 10`).';
  @override
  String get constraintsDslInputLabel => 'Programme de contraintes';
  @override
  String get constraintsDslExamplesButton => 'Exemples';
  @override
  String get constraintsDslExamplesTooltip =>
      'Charger un exemple pré-construit';
  @override
  String constraintsDslExampleTitle(String id) {
    switch (id) {
      case 'magicSum':
        return 'Somme magique à 3 chiffres';
      case 'magicSquare3':
        return 'Carré magique 3×3';
      case 'mapColoring':
        return 'Coloration de carte (K4)';
      case 'orderedTriples':
        return 'Triplets ordonnés sommant à 20';
      case 'coinChangeMin':
        return 'Rendu de monnaie (minimiser les pièces)';
      case 'schedulingMakespan':
        return 'Ordonnancement — minimiser le makespan';
      case 'cumulativeScheduling':
        return 'Ordonnancement cumulatif — capacité 2';
      case 'rcpsp':
        return 'RCPSP — équipe + équipement';
    }
    return id;
  }

  @override
  String get constraintsFlatZincIntro =>
      'Coller un modèle FlatZinc (typiquement produit par mzn2fzn à '
      "partir d'une source MiniZinc). Le solveur renvoie la sortie "
      'FlatZinc standard : lignes `nom = valeur;` par annotation '
      '`:: output_var`, terminées par `----------`, suivies de '
      '`==========` après la dernière solution.';
  @override
  String get constraintsFlatZincInputLabel => 'Code source FlatZinc';
  @override
  String get constraintsFlatZincAllSolutions => 'Toutes les solutions';
  @override
  String get constraintsFlatZincFirstSolution => 'Première solution';
  @override
  String get constraintsFlatZincExhaustiveOne => '1 solution (exhaustif)';
  @override
  String constraintsFlatZincExhaustiveN(int n) => '$n solutions (exhaustif)';
  @override
  String get constraintsFlatZincUnsatisfiable => 'Insatisfiable';
  @override
  String constraintsFlatZincExampleTitle(String id) {
    switch (id) {
      case 'nqueens4':
        return '4 reines';
      case 'binPacking':
        return 'Bin-packing (3 objets, 2 boîtes)';
    }
    return id;
  }

  @override
  String get constraintsExplainFailure => "Expliquer l'échec";
  @override
  String get constraintsExplainHeader => 'Conflit minimal (QuickXplain)';
  @override
  String get constraintsExplainSatisfiable =>
      'Aucun conflit — le modèle est en fait satisfaisable.';
  @override
  String constraintsExplainEntryCount(int n) =>
      n == 1 ? '1 contrainte conflictuelle' : '$n contraintes conflictuelles';
  @override
  String get constraintsExportFlatZinc => 'Exporter en FlatZinc';
  @override
  String get constraintsExportedHeader => 'Traduction FlatZinc';

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
  String constraintsOptimalHeader(num objective) =>
      'Optimal : objectif = $objective';

  @override
  String get clearSearchTooltip => 'Effacer la recherche';
  @override
  String get clearFunctionSlotTooltip => 'Effacer l\'emplacement de fonction';
  @override
  String get deleteMemorySlotTooltip => 'Supprimer l\'emplacement mémoire';

  @override
  String get helpModeEnableTooltip =>
      'Mode aide : touchez n\'importe quel contrôle pour une explication';
  @override
  String get helpModeDisableTooltip => 'Quitter le mode aide';
  @override
  String get keypadHelpLearnMore => 'En savoir plus';
  @override
  String get historyHelpTitle => 'Comment ceci a été calculé';
  @override
  String historyHelpComputedVia(String engine) => 'Calculé via $engine';
  @override
  String get historyHelpDirectEvaluation =>
      'Évaluation numérique directe — aucun appel symbolique.';
  @override
  String get historyHelpShowSteps => 'Afficher les étapes';

  @override
  String get moduleHelpTooltip => 'Que fait ce module ?';
  @override
  String moduleHelpTitle(ModuleHelpKind kind) {
    switch (kind) {
      case ModuleHelpKind.curveSketching:
        return 'Étude de courbe';
      case ModuleHelpKind.planes:
        return 'Analyse de plans';
      case ModuleHelpKind.conicSections:
        return 'Coniques';
      case ModuleHelpKind.statistics:
        return 'Statistiques';
      case ModuleHelpKind.graphing3D:
        return 'Graphique 3D';
      case ModuleHelpKind.scene3D:
        return 'Scène 3D';
      case ModuleHelpKind.constraints:
        return 'Contraintes';
      case ModuleHelpKind.sudoku:
        return 'Sudoku';
    }
  }

  @override
  String moduleHelpDescription(ModuleHelpKind kind) {
    switch (kind) {
      case ModuleHelpKind.curveSketching:
        return 'Étude complète d\'une fonction à une variable f(x) : '
            'domaine, intersections, dérivée et points critiques, '
            'extrema, points d\'inflexion, asymptotes, et un croquis. '
            'Entrez la fonction dans la zone de saisie ; les résultats '
            'apparaissent au tap.';
      case ModuleHelpKind.planes:
        return 'Analyse de plans 3D donnés sous forme cartésienne '
            '(ax + by + cz = d) ou paramétrique (point + deux vecteurs '
            'directeurs). Calcule le vecteur normal, les intersections '
            'avec les axes de coordonnées et les relations entre plans.';
      case ModuleHelpKind.conicSections:
        return 'Classifie une conique générale '
            'Ax² + Bxy + Cy² + Dx + Ey + F = 0 comme ellipse, '
            'hyperbole, parabole ou dégénérée, et extrait centre, axes, '
            'foyers et excentricité. Utilise le discriminant '
            'B² − 4AC pour la classification.';
      case ModuleHelpKind.statistics:
        return 'Statistiques descriptives (moyenne, médiane, variance, '
            '…), régression linéaire avec R² et résidus, lois normale '
            'et binomiale avec PDF / CDF / quantiles, et tests '
            'd\'hypothèses : t de Welch, t apparié, ANOVA à un facteur, '
            'chi-deux d\'ajustement et d\'indépendance, test exact de '
            'Fisher, test des rangs signés de Wilcoxon et test des '
            'signes. Les tests fournissent la statistique, la valeur '
            'p, et (si applicable) un intervalle de confiance au seuil α '
            'choisi.';
      case ModuleHelpKind.graphing3D:
        return 'Trace z = f(x, y) sous forme de surface filaire '
            'rotative. Faites glisser pour faire pivoter ; pincez / '
            'défilez pour zoomer. L\'action de rééchantillonnage '
            'reconstruit le maillage au niveau de zoom courant pour '
            'que le détail suive la distance de la caméra.';
      case ModuleHelpKind.scene3D:
        return 'Rendu de plusieurs objets 3D ensemble — plans, '
            'droites, sphères et quadriques — dans une scène partagée. '
            'Utile pour visualiser les intersections (par exemple deux '
            'plans se rencontrant le long d\'une droite) et construire '
            'des arguments géométriques étape par étape.';
      case ModuleHelpKind.constraints:
        return 'Résout des problèmes combinatoires : équations '
            'diophantiennes (solutions entières de ax + by = c), '
            'cryptarithmes (style SEND + MORE = MONEY), un petit '
            'DSL de programmation par contraintes à domaines finis '
            '(`allDifferent`, `noOverlap`, `cumulative`, `minimize` / '
            '`maximize`), et un onglet FlatZinc pour les problèmes '
            'écrits au format intermédiaire MiniZinc.';
      case ModuleHelpKind.sudoku:
        return 'Résout les grilles 4×4 et 9×9, y compris les variantes '
            'X (diagonales), Killer (sommes de cages) et Disjoint-'
            'Groups. Le solveur pas à pas montre l\'arbre de recherche '
            'pour observer comment le moteur restreint les candidats. '
            'Les niveaux d\'indice révèlent soit la réponse de la '
            'cellule suivante, soit une justification logique.';
    }
  }

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
  String get workedExamplesCatConstraints => 'Contraintes';
  @override
  String? workedExampleTitle(String id) {
    switch (id) {
      case 'killerSudoku':
        return 'Killer Sudoku (9×9)';
      case 'constraintEditor':
        return 'Éditeur de contraintes libres';
      case 'dslMagicSquare':
        return 'Carré magique 3×3 (DSL)';
      case 'dslMapColoring':
        return 'Coloration de carte K4 (DSL)';
      case 'dslOrderedTriples':
        return 'Triplets ordonnés sommant à 20 (DSL)';
      case 'dslCoinChange':
        return 'Rendu de monnaie — minimiser les pièces (DSL)';
      case 'dslSchedulingMakespan':
        return 'Ordonnancement mono-machine — minimiser le makespan (DSL)';
      case 'dslCumulativeScheduling':
        return 'Ordonnancement parallèle — cumulative (DSL)';
      case 'dslRcpsp':
        return 'Ordonnancement de projet RCPSP — deux ressources (DSL)';
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
      case 'piPrecision':
        return 'π à 100 chiffres';
      case 'ePrecision':
        return 'e à 50 chiffres';
      case 'factorint360':
        return 'Factorisation en facteurs premiers';
      case 'nextprime1000':
        return 'Premier suivant après 1000';
      case 'mersenneM31':
        return 'Premier de Mersenne M31';
      case 'divisors12':
        return 'Tous les diviseurs';
      case 'eulerTotient':
        return "Indicatrice d'Euler";
      case 'modpowCrypto':
        return 'Exponentiation modulaire';
      case 'contFracPi':
        return 'Fraction continue de π';
      case 'booleanIsprimeAnd':
        return 'Premier et borné';
      case 'booleanEqualityFold':
        return 'Évaluation d\'égalité';
      case 'booleanNotPrime':
        return 'Négation';
      case 'booleanOrChain':
        return 'Disjonction sur des comparaisons';
      case 'booleanIfFold':
        return 'Évaluation conditionnelle';
      case 'compoundInterest':
        return 'Intérêts composés';
      case 'zScore':
        return 'Lecture d\'un score Z';
      case 'statsHypothesisTests':
        return 'Espace tests d\'hypothèse';
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
      case 'killerSudoku':
        return 'Ouvre le module Sudoku préchargé avec la grille 9×9 Killer.';
      case 'constraintEditor':
        return 'Ouvre le module Contraintes — déclarer des variables, ajouter des contraintes, résoudre.';
      case 'dslMagicSquare':
        return 'Charge le programme à 9 variables du carré magique dans l\'éditeur DSL.';
      case 'dslMapColoring':
        return 'Charge une coloration K4 à 3 couleurs — volontairement infaisable pour montrer le chemin « aucune solution ».';
      case 'dslOrderedTriples':
        return 'Charge un programme DSL énumérant (a, b, c) avec a < b < c et a + b + c = 20.';
      case 'dslCoinChange':
        return 'Charge un programme DSL qui paie 17 ¢ avec le moins de pièces de {1, 5, 10, 25} via `minimize`.';
      case 'dslSchedulingMakespan':
        return 'Charge un programme DSL qui ordonnance trois tâches (durées 4/3/2) sur une machine via `noOverlap` et minimise le makespan.';
      case 'dslCumulativeScheduling':
        return 'Charge un programme DSL qui ordonnance trois tâches sur une ressource de capacité 2 via `cumulative` et minimise le makespan.';
      case 'dslRcpsp':
        return 'Charge un programme DSL avec deux contraintes `cumulative` parallèles (équipe + équipement, capacité 3 chacune) sur quatre tâches ; minimise le makespan.';
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
      case 'piPrecision':
        return 'pi(100) — constante haute précision via MPFR.';
      case 'ePrecision':
        return 'e(50) — même pipeline MPFR que pi(N).';
      case 'factorint360':
        return 'factorint(360) → 2³ · 3² · 5 avec exposants Unicode.';
      case 'nextprime1000':
        return 'nextprime(1000) — appuyé par FLINT via SymEngine ntheory.';
      case 'mersenneM31':
        return 'factorint(2^31 − 1) — confirme le huitième nombre '
            'premier de Mersenne comme facteur unique.';
      case 'divisors12':
        return 'divisors(12) → 1, 2, 3, 4, 6, 12 — dérivé de la '
            'factorisation en facteurs premiers.';
      case 'eulerTotient':
        return 'totient(36) — nombre de restes premiers avec 36.';
      case 'modpowCrypto':
        return 'modpow(2, 100, 1000000007) — le cœur de RSA / '
            'Diffie-Hellman.';
      case 'contFracPi':
        return 'cfrac(pi, 10) — le développement [3; 7, 15, 1, 292, …] '
            'derrière 355/113.';
      case 'booleanIsprimeAnd':
        return 'isprime(17) et 17 < 20 — les deux clauses sont vraies, '
            'donc la conjonction est vraie.';
      case 'booleanEqualityFold':
        return '2 == 2 — des opérandes constants se réduisent à vrai.';
      case 'booleanNotPrime':
        return 'not isprime(15) — 15 = 3·5, donc le résultat est vrai.';
      case 'booleanOrChain':
        return '(5 > 3) ou (1 == 2) — la première clause est vraie, '
            'donc la disjonction entière est vraie.';
      case 'booleanIfFold':
        return 'if(isprime(7), 100, 200) — la condition se réduit à vrai, '
            'donc la branche then l\'emporte.';
      case 'compoundInterest':
        return '1000 € à 5 % sur 10 ans, capitalisation annuelle.';
      case 'zScore':
        return 'Aller dans l\'écran Statistiques → Distributions pour '
            'calculer Φ(1,96) ≈ 0,975.';
      case 'statsHypothesisTests':
        return 'Ouvre le module Statistiques directement sur l\'onglet '
            'Tests — t à un échantillon, t à deux échantillons (Welch), '
            'apparié, ANOVA, khi-deux et Wilcoxon — avec des données '
            'd\'exemple préchargées.';
      case 'unitConversion':
        return '100 km/h converti en mph — analyseur inline V2.';
      case 'compositeDim':
        return '100 m / 10 s donne une vitesse en m/s — analyseur V5.';
    }
    return null;
  }

  // Round 100: FR function-reference prose. Double-quoted strings
  // throughout because French is full of apostrophes (prefer_single_quotes
  // is not enforced in analysis_options).
  @override
  String? functionRefDescription(String id) {
    switch (id) {
      case 'solve':
        return "Résout symboliquement une équation pour une variable ; "
            "renvoie une liste de solutions.";
      case 'expand':
        return "Développe les produits et les puissances en une somme de "
            "monômes.";
      case 'simplify':
        return "Regroupe les termes semblables, simplifie les facteurs "
            "communs et applique les identités algébriques usuelles.";
      case 'factor':
        return "Factorise un polynôme sur les rationnels en facteurs "
            "irréductibles.";
      case 'diff':
        return "Dérivée première symbolique par rapport à une variable.";
      case 'integrate':
        return "Intégrale indéfinie (3 arguments) ou intégrale définie "
            "(5 arguments) avec repli numérique.";
      case 'subst':
        return "Remplace chaque occurrence libre de `variable` dans "
            "`expression` par `value`. Également disponible sous le nom "
            "`substitute(...)`.";
      case 'limit':
        return "Limite numérique lorsque `variable` tend vers `point`. "
            "`point` peut être une valeur finie ou `oo` / `-oo`.";
      case 'gcd':
        return "Plus grand commun diviseur (PGCD) de deux entiers ou "
            "polynômes.";
      case 'lcm':
        return "Plus petit commun multiple (PPCM) de deux entiers ou "
            "polynômes.";
      case 'factorial':
        return "Factorielle entière exacte. Les petits `n` utilisent le "
            "`BigInt` de Dart ; les grands `n` sont confiés à SymEngine.";
      case 'fibonacci':
        return "n-ième nombre de Fibonacci. `fib(n)` est le nom abrégé.";
      case 'isprime':
        return "Test de primalité probabiliste sur les entiers.";
      case 'nextprime':
        return "Plus petit nombre premier strictement supérieur à `n`.";
      case 'prevprime':
        return "Plus grand nombre premier strictement inférieur à `n`. "
            "Erreur si aucun nombre premier de ce type n'existe "
            "(par ex. `prevprime(2)`).";
      case 'factorint':
        return "Décomposition en facteurs premiers sous la forme "
            "`p₁^e₁ · p₂^e₂ · …` avec des exposants Unicode en exposant.";
      case 'divisors':
        return "Tous les diviseurs positifs de `n`, triés par ordre croissant "
            "et séparés par des virgules.";
      case 'totient':
        return "Indicatrice d'Euler φ(n) : le nombre d'entiers de 1 à n "
            "premiers avec `n`.";
      case 'modpow':
        return "Exponentiation modulaire `aᵉ mod m`. Un exposant négatif "
            "utilise l'inverse modulaire de `a` (lorsqu'il existe).";
      case 'modinv':
        return "Inverse modulaire `a⁻¹ mod m` via l'algorithme d'Euclide "
            "étendu. Erreur lorsque `pgcd(a, m) ≠ 1`.";
      case 'jacobi':
        return "Symbole de Jacobi (a/n) ∈ {−1, 0, 1} pour `n` impair positif ; "
            "généralise le symbole de Legendre.";
      case 'cfrac':
        return "Développement en fraction continue `[a₀; a₁, …]` de `x` sur "
            "`n` termes. `x` peut être `pi` / `e` / `EulerGamma` / "
            "`sqrt(2)`, un rationnel `p/q` ou un décimal.";
      case 'convergent':
        return "La k-ième réduite `p/q` de la fraction continue de `x` — une "
            "meilleure approximation rationnelle pour la taille de son "
            "dénominateur.";
      case 'pi_precision':
        return "π avec N décimales via MPFR ; renvoie la chaîne de chiffres "
            "brute.";
      case 'e_precision':
        return "Nombre d'Euler e avec N décimales via MPFR.";
      case 'sqrt_precision':
        return "Racine carrée de l'entier `k` avec N décimales via MPFR. La "
            "forme à deux arguments choisit le chemin haute précision.";
      case 'eulergamma_precision':
        return "Constante d'Euler-Mascheroni γ ≈ 0,5772… avec N décimales "
            "via MPFR.";
      case 'matrix_literal':
        return "Littéral matriciel : une liste de lignes, chaque ligne étant "
            "une liste d'expressions de cellule. Les cellules peuvent être "
            "des nombres, des fractions ou symboliques.";
      case 'det':
        return "Déterminant d'une matrice carrée. Renvoie un scalaire "
            "symbolique.";
      case 'inv':
        return "Inverse d'une matrice carrée non singulière. Erreur lorsque "
            "`det = 0`.";
      case 'transpose':
        return "Transposée : échange des lignes et des colonnes. Fonctionne "
            "sur les matrices rectangulaires.";
      case 'rref':
        return "Forme échelonnée réduite par lignes via l'élimination de "
            "Gauss-Jordan. Fonctionne sur des entrées symboliques/"
            "rationnelles.";
      case 'matrix_arithmetic':
        return "Addition/soustraction terme à terme et multiplication "
            "matricielle sur des littéraux `Matrix(...)`.";
      case 'mean':
        return "Moyenne arithmétique d'un échantillon sous forme de liste de "
            "nombres. Proposée dans l'onglet « Statistiques descriptives » du "
            "module Statistiques, avec les indicateurs usuels.";
      case 'welch_t':
        return "Test t à deux échantillons à variances inégales "
            "(Welch-Satterthwaite). Choix par défaut robuste lorsque les deux "
            "groupes peuvent avoir des dispersions différentes.";
      case 'paired_t':
        return "Test t apparié sur les différences intra-sujet contre "
            "μ₀ = 0. À utiliser lorsque les mêmes unités sont mesurées deux "
            "fois (avant/après).";
      case 'anova_1':
        return "Analyse de variance (ANOVA) à un facteur sur K groupes "
            "indépendants. Teste si les moyennes des groupes diffèrent ; "
            "fournit une statistique F et une valeur p.";
      case 'chi2_goodness':
        return "Test d'adéquation du khi-deux : les effectifs observés "
            "correspondent-ils à une distribution supposée ?";
      case 'chi2_independence':
        return "Test d'indépendance du khi-deux sur une table de "
            "contingence — deux variables catégorielles sont-elles "
            "indépendantes ?";
      case 'fisher_exact':
        return "Test exact de Fisher sur une table de contingence 2×2. "
            "Valeur p hypergéométrique exacte — sans approximation pour "
            "grands échantillons.";
      case 'wilcoxon':
        return "Test de la somme des rangs de Wilcoxon / U de "
            "Mann-Whitney — test non paramétrique à deux échantillons sur "
            "les rangs. Robuste aux données non normales.";
      case 'sign_test':
        return "Test des signes apparié — test non paramétrique fondé sur la "
            "médiane des différences appariées. Compte combien de fois "
            "`après > avant`.";
      case 'vars':
        return "Déclare les variables de décision entières et leur domaine. "
            "Toujours la première ligne d'un programme DSL de CrispCalc.";
      case 'all_different':
        return "Contrainte globale « toutes les valeurs deux à deux "
            "distinctes ». La contrainte PPC phare — propagation bien plus "
            "forte que n·(n-1)/2 clauses `!=` deux à deux.";
      case 'no_overlap':
        return "Ordonnancement disjonctif : des tâches ayant des variables "
            "de début données et des durées fixes ne peuvent pas se "
            "chevaucher dans le temps sur une même machine.";
      case 'cumulative':
        return "Ordonnancement cumulatif sur une ressource renouvelable de "
            "capacité fixe. Chaque tâche a une durée et une demande de "
            "ressource propre.";
      case 'minimize':
        return "Objectif : minimiser une expression linéaire sur les "
            "variables de décision. À combiner avec des contraintes pour "
            "résoudre des PSC d'optimisation.";
      case 'maximize':
        return "Objectif : maximiser une expression linéaire. Image miroir "
            "de `minimize` — même séparation-évaluation, dans le sens "
            "opposé.";
      case 'sudoku_regular':
        return "Règles classiques du Sudoku : chaque ligne, colonne et bloc "
            "contient chaque chiffre exactement une fois. Des modèles "
            "existent pour 4×4, 6×6, 8×8, 9×9, 10×10, 12×12, 15×15 et 16×16.";
      case 'sudoku_x':
        return "Sudoku-X : règles classiques du Sudoku, plus les deux "
            "diagonales principales sont également « toutes différentes ». "
            "Fourni comme modèle 8×8.";
      case 'sudoku_disjoint':
        return "Groupes disjoints : règles classiques, plus une contrainte "
            "« toutes différentes » supplémentaire sur les cellules occupant "
            "la même position dans le bloc, à travers tous les blocs.";
      case 'sudoku_killer':
        return "Sudoku killer : aucun indice donné ; à la place, la grille "
            "est partitionnée en « cages », chaque cage étant « toutes "
            "différentes » et de somme égale à une cible donnée.";
      default:
        return null;
    }
  }

  @override
  String? functionRefExampleHint(String id, int index) {
    final list = _frHints[id];
    if (list == null || index < 0 || index >= list.length) return null;
    return list[index];
  }

  static const _frHints = <String, List<String>>{
    'solve': [
      "Dans CrispCalc, `solve(x^2 - 1, x)` renvoie une liste de racines à la "
          "manière de Python. L'appel sous-jacent est le `solve()` de "
          "SymEngine (branche des racines rationnelles pour les polynômes), "
          "encapsulé par le pont et sérialisé en chaîne Dart.",
      "`=` dans l'entrée est accepté comme syntaxe d'équation — le "
          "préprocesseur normalise `lhs = rhs` en `lhs - rhs` avant l'appel "
          "au pont.",
      "Les racines complexes reviennent sous le littéral `I` de SymEngine. "
          "Réutilisées dans d'autres appels (par ex. `expand((-I)*(I))`), le "
          "pont les conserve sous forme symbolique.",
    ],
    'expand': [
      "Dans CrispCalc, `expand((x + 1)^2)` renvoie le développement du "
          "binôme. L'appel sous-jacent est le `expand()` de SymEngine, qui "
          "décompose les nœuds `Pow` et `Mul` et regroupe les termes "
          "semblables.",
      "Les coefficients correspondent à la 5ᵉ ligne du triangle de Pascal : "
          "1, 5, 10, 10, 5, 1, chacun multiplié par la puissance de 2 "
          "appropriée.",
      "L'identité de la différence de deux carrés — utile en alternance avec "
          "`factor` pour passer d'une forme à l'autre.",
    ],
    'simplify': [
      "Dans CrispCalc, `simplify` simplifie le facteur commun `(x - 2)`. "
          "L'appel sous-jacent est le `simplify()` de SymEngine, qui essaie "
          "`rational_simplify` ainsi qu'un petit ensemble de règles de "
          "réécriture.",
      "Regroupement des termes semblables sur une entrée polynomiale — en "
          "interne, c'est simplement `expand` suivi de la fusion des "
          "coefficients.",
      "Identité de Pythagore ; SymEngine applique la règle de réécriture "
          "trigonométrique avant de renvoyer le littéral `1`.",
    ],
    'factor': [
      "Dans CrispCalc, `factor(x^2 - 1)` renvoie la factorisation en "
          "différence de deux carrés. L'appel sous-jacent est le `factor()` "
          "de SymEngine, qui utilise Berlekamp / Cantor–Zassenhaus pour les "
          "polynômes à une variable sur Q.",
      "Identité de la somme/différence de cubes : un facteur linéaire "
          "multiplié par un trinôme du second degré irréductible sur Q.",
      "La factorisation s'arrête à l'irréductibilité sur Q — `x^2 + 1` ne se "
          "décompose pas davantage sans admettre de racines complexes.",
    ],
    'diff': [
      "Dans CrispCalc, `diff(...)` applique terme à terme les règles de "
          "dérivation des puissances et des constantes. L'appel sous-jacent "
          "est le `diff()` de SymEngine, qui parcourt l'arbre d'expression et "
          "produit un nouveau nœud `Add` symbolique.",
      "Règle de dérivation en chaîne : SymEngine applique "
          "`diff(sin(u))/du * du/dx` pour l'intérieur `u = x^2`.",
      "Règle du produit — notez que SymEngine laisse le résultat non "
          "factorisé. Passé dans `factor`, `exp(x)` est mis en facteur.",
    ],
    'integrate': [
      "Dans CrispCalc, l'intégrale indéfinie `integrate(...)` est déléguée "
          "au `integrate()` de SymEngine. L'intégration par parties est "
          "appliquée automatiquement lorsqu'un facteur se dérive en un "
          "polynôme.",
      "Forme définie : lorsque SymEngine dispose d'une primitive sous forme "
          "close, il applique le théorème fondamental de l'analyse. En cas "
          "d'échec symbolique, CrispCalc se rabat sur la méthode de Simpson "
          "(200 sous-intervalles).",
      "Décomposition en éléments simples : 1/(x²-1) = 1/(2(x-1)) - "
          "1/(2(x+1)). SymEngine effectue le calcul automatiquement.",
    ],
    'subst': [
      "Dans CrispCalc, `subst` réécrit l'arbre d'expression puis tente une "
          "passe de simplification. L'appel sous-jacent est le `xreplace()` "
          "de SymEngine (remplacement de variables uniquement, sans filtrage "
          "de motif).",
      "Les constantes numériques `pi`, `e` et l'unité imaginaire `I` sont "
          "reconnues par SymEngine et propagées à travers l'identité "
          "trigonométrique.",
      "La substitution est symbolique — les variables libres sans rapport "
          "`a` et `b` restent intactes.",
    ],
    'limit': [
      "Dans CrispCalc, `limit(...)` est une approche numérique : le pont "
          "évalue l'expression en une suite de points convergeant vers "
          "`point` et renvoie la limite dès que des échantillons consécutifs "
          "concordent à la précision de travail. Pas de développement en "
          "série symbolique.",
      "Le littéral `oo` est la sentinelle d'infini de SymEngine — le "
          "préprocesseur la reconnaît avant l'envoi. Utilisez `-oo` pour "
          "l'infini négatif.",
      "Tend vers le nombre d'Euler. Comme le chemin est numérique, le "
          "résultat est un nombre à virgule flottante — utilisez `e(N)` pour "
          "la constante en haute précision.",
    ],
    'gcd': [
      "Dans CrispCalc, le `gcd(...)` entier utilise la récurrence "
          "d'Euclide gcd(a, b) = gcd(b, a mod b). L'appel sous-jacent est le "
          "`gcd()` de SymEngine, qui s'appuie sur `mpz_gcd` de GMP dans le "
          "cas entier.",
      "PGCD polynomial via l'algorithme des sous-résultants (PRS). Utile en "
          "préalable à `simplify` pour les simplifications.",
      "Convention : `gcd(0, n) = |n|`. Conforme à la définition "
          "mathématique qui traite 0 comme un multiple de tout entier.",
    ],
    'lcm': [
      "Dans CrispCalc, le `lcm(...)` entier est calculé via l'identité "
          "`lcm(a, b) = |a*b| / gcd(a, b)`. L'appel sous-jacent est le "
          "`lcm()` de SymEngine, qui délègue à `mpz_lcm` de GMP.",
      "36 = 2²·3², l'union des facteurs en puissances de nombres premiers de "
          "12 = 2²·3 et 18 = 2·3².",
      "Le PPCM polynomial choisit le multiple de plus haut degré — `x^2 - 1` "
          "contient déjà `x + 1` comme facteur.",
    ],
    'factorial': [
      "Dans CrispCalc, le suffixe `n!` et `factorial(n)` sont équivalents — "
          "le préprocesseur réécrit le suffixe en appel. Pour `n ≤ 1000`, "
          "nous calculons en Dart avec la multiplication `BigInt` ; au-delà, "
          "l'appel sous-jacent est le `factorial()` de SymEngine.",
      "158 chiffres, conservés exactement grâce au chemin BigInt — passer en "
          "IEEE-754 arrondirait ici à 1,0 × 10^157.",
      "Convention du produit vide : 0! = 1. Nécessaire pour que la récurrence "
          "n! = n · (n-1)! se termine à 1.",
    ],
    'fibonacci': [
      "Dans CrispCalc, `fib(n)` et `fibonacci(n)` sont le même appel. Pour "
          "`n ≤ 90`, nous utilisons une table précalculée ; pour les `n` plus "
          "grands, l'appel sous-jacent est le `fibonacci()` de SymEngine, qui "
          "utilise le doublement rapide (O(log n) multiplications via GMP).",
      "Le 50ᵉ nombre de Fibonacci — bien au-delà de la limite de la table "
          "pour les petits termes, mais tient encore dans un entier signé de "
          "64 bits.",
      "Bascule sur le chemin appuyé par GMP. Le doublement rapide évite la "
          "récurrence linéaire en O(n), si bien que même fib(10000) reste "
          "sous la seconde.",
    ],
    'isprime': [
      "Dans CrispCalc, `isprime(n)` renvoie une puce booléenne. L'appel "
          "sous-jacent est `mpz_probab_prime_p` de GMP (25 tours de "
          "Miller-Rabin, borne d'erreur 4^-25 ≈ 9×10^-16) via le module "
          "`ntheory` de SymEngine. 2027 est le 308ᵉ nombre premier.",
      "2024 = 2³·11·23.",
      "Le neuvième nombre premier de Mersenne, M61. Miller-Rabin se résout "
          "encore en microsecondes à cette taille — le coût réside dans les "
          "exponentiations modulaires, pas dans la longueur en bits.",
    ],
    'nextprime': [
      "Dans CrispCalc, `nextprime(n)` itère à partir de `n+1` et teste "
          "chaque candidat. L'appel sous-jacent est le "
          "`ntheory::nextprime()` de SymEngine, qui utilise le crible de "
          "FLINT sur de courtes fenêtres lorsque l'écart est grand.",
      "Strictement supérieur — `nextprime(p)` n'est jamais `p` lui-même, "
          "même lorsque `p` est premier.",
    ],
    'prevprime': [
      "Dans CrispCalc, `prevprime(n)` descend à partir de `n-1`. L'appel "
          "sous-jacent est le `ntheory::prevprime()` de SymEngine.",
      "Il n'existe aucun nombre premier en dessous de 2 ; le pont lève une "
          "erreur plutôt que de renvoyer une valeur sentinelle. CrispCalc "
          "affiche la puce d'erreur.",
    ],
    'factorint': [
      "Dans CrispCalc, `factorint(n)` renvoie une décomposition en facteurs "
          "premiers mise en forme. L'appel sous-jacent est `fmpz_factor` de "
          "FLINT, en façade via l'enveloppe ntheory de SymEngine ; CrispCalc "
          "convertit la liste de (nombre premier, exposant) en l'affichage à "
          "chiffres Unicode en exposant.",
      "Le 8ᵉ nombre premier de Mersenne, M31. Un facteur unique (lui-même) — "
          "`factorint` court-circuite lorsque l'entrée est première.",
      "Cas limite : par convention, 1 a la factorisation vide ; CrispCalc "
          "l'affiche comme le littéral `1` plutôt qu'une chaîne vide.",
    ],
    'divisors': [
      "Dans CrispCalc, `divisors(n)` est dérivé en Dart pur de `factorint(n)` : "
          "chaque produit de puissances de nombres premiers pᵏ avec "
          "0 ≤ k ≤ exposant. Le compte vaut ∏(eᵢ + 1) — ici (2+1)(1+1) = 6.",
      "28 est un nombre parfait : la somme de ses diviseurs propres (tous "
          "sauf 28 lui-même) vaut 28.",
    ],
    'totient': [
      "Les quatre restes premiers avec 12 sont {1, 5, 7, 11}. CrispCalc "
          "calcule φ à partir de la décomposition en facteurs premiers via "
          "`fmpz_euler_phi` de FLINT.",
      "Pour un nombre premier p, φ(p) = p − 1, car tout entier positif plus "
          "petit est premier avec p.",
    ],
    'modpow': [
      "Exponentiation rapide (carré-et-multiplie) via `mpz_powm` de GMP — "
          "l'opération de base de l'arithmétique modulaire et (en version "
          "scolaire) de RSA / Diffie-Hellman. Le gigantesque `2¹⁰⁰` n'est "
          "jamais formé explicitement.",
      "Un exposant négatif inverse d'abord la base, donc `modpow(a, -1, m)` "
          "égale `modinv(a, m)` — ici 3⁻¹ ≡ 4 (mod 11). Erreur si "
          "pgcd(a, m) ≠ 1.",
    ],
    'modinv': [
      "L'unique x dans [0, m) tel que a·x ≡ 1 (mod m), via `mpz_invert` de "
          "GMP. Vérification : 3·4 = 12 ≡ 1 (mod 11).",
      "Seules les unités modulo m sont inversibles. pgcd(2, 4) = 2 ≠ 1, donc "
          "aucun inverse n'existe.",
    ],
    'jacobi': [
      "Pour un nombre premier n, le symbole de Jacobi coïncide avec le "
          "symbole de Legendre — ici 2 est un résidu quadratique modulo 7 "
          "(car 3² ≡ 2). Via `mpz_jacobi` de GMP.",
      "Le symbole vaut 0 exactement lorsque pgcd(a, n) ≠ 1 ; ici "
          "pgcd(6, 9) = 3.",
    ],
    'cfrac': [
      "Dans CrispCalc, `cfrac` effectue un développement exact en BigInt sur "
          "une approximation MPFR haute précision de la constante. Le grand "
          "terme 292 est précisément pourquoi la réduite 355/113 approche π "
          "de façon si remarquable.",
      "Pour un rationnel exact, le développement est fini — ce n'est que "
          "l'algorithme d'Euclide consignant ses quotients.",
    ],
    'convergent': [
      "Milü — l'approximation de π par Zu Chongzhi (Ve siècle), exacte à six "
          "décimales. CrispCalc replie les k+1 premiers quotients partiels de "
          "`cfrac` en une fraction.",
      "L'approximation scolaire de π ; `convergent(x, 0)` est la partie "
          "entière ⌊x⌋.",
    ],
    'pi_precision': [
      "Dans CrispCalc, `pi(N)` est un appel traité à part, dirigé vers le "
          "chemin haute précision avant que SymEngine ne le voie. L'appel "
          "sous-jacent est `mpfr_const_pi` de MPFR à la précision "
          "⌈N·log2(10)⌉ + 16 bits de garde, suivi de la conversion en base "
          "10.",
      "À N = 100, la précision de travail est d'environ 348 bits. Les bits "
          "de garde empêchent la conversion de base d'afficher des chiffres "
          "de fin arrondis.",
    ],
    'e_precision': [
      "Dans CrispCalc, `e(N)` reflète le pipeline de `pi(N)` : `mpfr_const_e` "
          "de MPFR (qui utilise la série de Taylor Σ 1/k!) à la précision "
          "⌈N·log2(10)⌉ + 16 bits de garde, puis le rendu en base 10.",
      "Assez court pour être mémorisé — utile comme vérification rapide de "
          "précision face à `limit((1 + 1/n)^n, n, oo)`.",
    ],
    'sqrt_precision': [
      "Dans CrispCalc, le `sqrt(k, N)` à deux arguments est la voie haute "
          "précision. L'appel sous-jacent est `mpfr_sqrt_ui` de MPFR à la "
          "précision ⌈N·log2(10)⌉ + 16 bits de garde. Le `sqrt(2)` à un "
          "argument renvoie plutôt le `sqrt(2)` symbolique via SymEngine.",
      "Utile pour la vérification — `sqrt(3, N)` devrait concorder avec des "
          "chiffres de référence dérivés indépendamment.",
    ],
    'eulergamma_precision': [
      "Dans CrispCalc, `EulerGamma(N)` utilise `mpfr_const_euler` de MPFR, "
          "qui évalue γ via la formule de Brent–McMillan (fonctions de "
          "Bessel modifiées). La précision est ⌈N·log2(10)⌉ + 16 bits de "
          "garde, comme le pipeline de `pi(N)` et `e(N)`.",
      "γ n'a aucune forme close connue. La routine MPFR est l'implémentation "
          "de référence standard ; CrispCalc se contente d'afficher la chaîne "
          "de chiffres.",
    ],
    'matrix_literal': [
      "Dans CrispCalc, le littéral `Matrix(...)` est reconnu par "
          "l'évaluateur de matrices avant que le moteur ne voie l'expression. "
          "L'appel sous-jacent est le constructeur `DenseMatrix` de "
          "SymEngine — la disposition lignes/colonnes est fixée à la "
          "construction.",
      "Les cellules restent symboliques — les rationnels ne sont pas réduits "
          "en nombres à virgule flottante. Idem pour les symboles libres : "
          "`Matrix([[a, b], [c, d]])` est accepté et propagé via `det` / "
          "`inv` / `rref`.",
      "Les matrices non carrées conviennent à `transpose` et `rref` mais "
          "échouent pour `det` / `inv`, qui exigent une entrée carrée.",
    ],
    'det': [
      "Dans CrispCalc, `det(M)` est évalué comme un scalaire unique. L'appel "
          "sous-jacent est le `DenseMatrix::det()` de SymEngine, qui utilise "
          "l'algorithme sans fraction de Bareiss — exact pour des entrées "
          "symboliques/rationnelles, sans explosion en virgule flottante.",
      "Exemple scolaire classique 3×3 — le développement de Laplace par "
          "cofacteurs donne le même résultat en 6 termes.",
      "Les entrées symboliques passent inchangées. Bareiss conserve le "
          "résultat sous forme d'`Add` SymEngine plutôt qu'un nombre à "
          "virgule flottante.",
    ],
    'inv': [
      "Dans CrispCalc, `inv(M)` renvoie `adj(M)/det(M)`. L'appel sous-jacent "
          "est le `DenseMatrix::inv()` de SymEngine, qui utilise "
          "l'élimination de Gauss-Jordan sur les rationnels — les entrées "
          "reviennent en fractions exactes, pas en nombres à virgule "
          "flottante.",
      "La matrice identité est sa propre inverse — un test rapide de bon "
          "fonctionnement confirmant que le pont fait l'aller-retour "
          "correctement.",
      "Une entrée singulière (det = 0) provoque une erreur propre plutôt que "
          "de renvoyer de grands nombres absurdes. La puce d'erreur apparaît "
          "dans l'historique de la calculatrice.",
    ],
    'transpose': [
      "Dans CrispCalc, `transpose(M)` est implémenté côté Dart car le pont "
          "n'expose pas de point d'entrée de transposition. Nous allouons une "
          "nouvelle `SymEngineMatrix` aux dimensions échangées et copions les "
          "cellules une à une.",
      "Entrée rectangulaire : une 2×3 devient une 3×2 — utile pour les "
          "dispositions de données appariées.",
      "Idempotente après deux applications. Vérifie que l'échange des "
          "cellules laisse le contenu symbolique intact.",
    ],
    'rref': [
      "Dans CrispCalc, `rref` exécute Gauss-Jordan en Dart et appelle le "
          "`simplify()` de SymEngine à chaque mise à jour de cellule. Le pont "
          "n'expose pas `rref` directement, donc l'algorithme parcourt les "
          "colonnes de gauche à droite, met à l'échelle la ligne de pivot, "
          "puis élimine la colonne au-dessus et en dessous.",
      "Entrée de rang déficient : la seconde ligne se réduit à des zéros. "
          "Utile pour repérer visuellement une dépendance linéaire.",
      "La mise à l'échelle du pivot normalise les entrées de tête à 1. La "
          "détection symbolique des valeurs non nulles est le point "
          "sensible — voir la note d'algorithme dans `matrix_evaluator.dart`.",
    ],
    'matrix_arithmetic': [
      "Dans CrispCalc, les opérations binaires sur matrices sont prises en "
          "charge par l'évaluateur de matrices lorsque les deux opérandes se "
          "lisent comme des littéraux `Matrix(...)`. L'appel sous-jacent est "
          "`add_dense_dense` de SymEngine ; la soustraction passe par "
          "`add_dense_dense` avec une négation terme à terme du membre de "
          "droite.",
      "La multiplication est le produit scalaire ligne par colonne habituel "
          "via `mul_dense_dense` de SymEngine. La multiplication à droite par "
          "l'identité est un test de bon fonctionnement.",
      "La soustraction est terme à terme ; une discordance de dimensions "
          "échoue proprement avec `Error: matrix - failed: …`.",
    ],
    'mean': [
      "Dans CrispCalc, `mean` est calculée par `DescriptiveStats.mean` (voir "
          "`lib/engine/statistics.dart`) — une somme en une passe / n. Pour "
          "des données appariées ou groupées, le module Statistiques expose "
          "aussi l'écart-type, la médiane, les quartiles et l'écart "
          "interquartile.",
      "Entrée à virgule flottante — l'implémentation accumule en `double`, "
          "si bien que des listes très grandes ou d'ordres de grandeur mêlés "
          "peuvent nécessiter un algorithme de sommation stable si vous "
          "voulez plus de 15 chiffres.",
    ],
    'welch_t': [
      "Dans CrispCalc, `welchT` se trouve dans "
          "`lib/engine/hypothesis_tests.dart`. L'appel sous-jacent calcule la "
          "statistique de test t = (x̄_A − x̄_B) / √(s_A²/n_A + s_B²/n_B), "
          "approche ensuite les degrés de liberté via Welch-Satterthwaite, et "
          "lit la valeur p sur `TDistribution.cdf`.",
      "Cas à très petit échantillon — le ddl de Welch ≈ 4 bien que "
          "n_A + n_B = 6, car la loi t à deux échantillons tient compte de "
          "l'incertitude de l'estimation de la variance.",
    ],
    'paired_t': [
      "Dans CrispCalc, `pairedT` se ramène à un test t à un échantillon sur "
          "le vecteur des différences d = après − avant. L'appel sous-jacent "
          "est la même voie `TDistribution.cdf` que `welchT`, mais avec "
          "ddl = n - 1 (pas de correction de Welch car il n'y a qu'une seule "
          "estimation de variance à faire).",
      "Cas limite : des décalages identiques produisent une variance nulle "
          "des différences, que l'implémentation présente comme la valeur "
          "limite p = 0 plutôt qu'un NaN.",
    ],
    'anova_1': [
      "Dans CrispCalc, `anovaOneWay` partitionne la somme des carrés totale "
          "en somme des carrés inter-groupes et intra-groupes. L'appel "
          "sous-jacent est F = MS_inter / MS_intra avec ddl1 = K - 1 et "
          "ddl2 = N - K, puis `FDistribution.sf` pour la valeur p de la queue "
          "supérieure.",
      "Des dispersions égales et des moyennes bien séparées produisent un F "
          "élevé. On rejette H₀ (toutes les moyennes égales) au seuil "
          "α = 0,05.",
    ],
    'chi2_goodness': [
      "Dans CrispCalc, `chiSquareGof` évalue Σ (O - E)² / E et lit la valeur "
          "p de la queue supérieure sur `ChiSquaredDistribution.sf` avec "
          "ddl = k - 1, où k est le nombre de catégories. On suppose les "
          "effectifs des cellules ≥ 5 — l'implémentation n'applique pas de "
          "correction de Yates automatique.",
      "Concordance parfaite → χ² = 0 → on ne rejette H₀ à aucun seuil α.",
    ],
    'chi2_independence': [
      "Dans CrispCalc, `chiSquareIndependence` calcule les effectifs "
          "attendus à partir des marges ligne × colonne (E_ij = ligne_i · "
          "colonne_j / total), puis Σ (O - E)² / E avec "
          "ddl = (lignes - 1) · (colonnes - 1). La valeur p sous-jacente "
          "provient de `ChiSquaredDistribution.sf`.",
      "Forte concentration hors diagonale → faible valeur p. Pour les tables "
          "2×2 creuses, préférez `fisher_exact`, qui ne repose pas sur "
          "l'approximation du khi-deux pour grands échantillons.",
    ],
    'fisher_exact': [
      "Dans CrispCalc, `fisherExact` énumère toutes les tables 2×2 ayant les "
          "mêmes marges et somme les probabilités hypergéométriques des "
          "tables au moins aussi extrêmes que l'observée. L'appel sous-jacent "
          "calcule des termes log-binomiaux pour éviter le dépassement sur de "
          "grands totaux, puis exponentie ; la valeur p bilatérale suit la "
          "convention de R (somme des probabilités de queue ≤ celle "
          "observée).",
      "Table symétrique → aucun indice d'association.",
    ],
    'wilcoxon': [
      "Dans CrispCalc, `wilcoxonRankSum` réunit les deux échantillons, "
          "attribue des rangs corrigés par les rangs moyens, somme les rangs "
          "du groupe A et fournit le z de l'approximation normale. L'appel "
          "sous-jacent applique une correction de liaisons à la variance et "
          "lit la valeur p bilatérale sur la fonction de répartition normale.",
      "Cas à très petit échantillon — l'approximation normale est limite à "
          "n_A + n_B = 6. Pour de très petits échantillons, on préférera la "
          "loi de permutation exacte (pas encore livrée).",
    ],
    'sign_test': [
      "Dans CrispCalc, `pairedSign` écarte les paires de différence nulle, "
          "compte les positives parmi les n restantes et teste contre une "
          "loi Binomiale(n, 0,5). La valeur p sous-jacente utilise la queue "
          "binomiale exacte — pas d'approximation normale, c'est donc le bon "
          "choix pour de très petits échantillons appariés.",
      "Une paire liée (4 → 4) est écartée, laissant n = 3 positives sur 3 "
          "paires informatives. La valeur p exacte bilatérale est "
          "2 · min(Binom(3, 0,5).cdf(3), …).",
    ],
    'vars': [
      "Dans CrispCalc, la ligne `vars:` est analysée par `DslToFlatZinc` "
          "(voir `lib/engine/csp_solver.dart`) et émet une déclaration "
          "FlatZinc `var int: x :: …` par nom. Les bornes du domaine sont des "
          "entiers concrets ; les domaines symboliques ne sont pas pris en "
          "charge.",
      "Un domaine `0..1` modélise une variable booléenne. FlatZinc a un type "
          "`var bool` distinct — l'analyseur ne le détecte pas, mais le "
          "solveur traite l'entier 0/1 tout aussi efficacement.",
    ],
    'all_different': [
      "Dans CrispCalc, `allDifferent` se traduit en "
          "`all_different_int([a, b, c])` de FlatZinc. Le solveur sous-jacent "
          "(dart_csp) implémente la propagation par cohérence de bornes via "
          "l'algorithme de couplage de Régin — bien plus rapide que le mode "
          "deux à deux sur de grandes listes d'arguments.",
      "Les modèles de Sudoku du module Sudoku reposent sur des piles de "
          "contraintes `allDifferent` — une par ligne, colonne, bloc et "
          "éventuelles zones de variante.",
    ],
    'no_overlap': [
      "Dans CrispCalc, `noOverlap` se traduit en "
          "`disjunctive([s1, s2, s3], [4, 3, 2])` de FlatZinc. Le solveur "
          "sous-jacent utilise l'edge-finding plus le propagateur θ-tree de "
          "Vilím — le même algorithme que celui intégré à MiniZinc.",
      "Problème classique de séquencement sur une machine. Combinez avec "
          "`minimize` sur l'expression du makespan pour obtenir "
          "l'ordonnancement optimal. Voir l'exemple résolu pour le programme "
          "DSL complet.",
    ],
    'cumulative': [
      "Dans CrispCalc, `cumulative` se traduit en "
          "`cumulative([starts], [durations], [resources], capacity)` de "
          "FlatZinc. Le solveur sous-jacent utilise la propagation par "
          "emploi du temps plus le raisonnement énergétique — des variantes "
          "tenant compte de la capacité des propagateurs de `noOverlap`.",
      "Le problème d'ordonnancement de projet à contraintes de ressources "
          "(RCPSP) empile plusieurs contraintes `cumulative`, une par type de "
          "ressource. Voir l'exemple résolu `dslRcpsp` pour un projet à deux "
          "ressources.",
    ],
    'minimize': [
      "Dans CrispCalc, `minimize` émet `solve minimize __obj__;` de FlatZinc "
          "après avoir construit la variable objectif via l'analyse de "
          "l'expression linéaire. Le solveur sous-jacent utilise la "
          "séparation-évaluation — test de faisabilité, puis resserrement de "
          "la borne supérieure à chaque solution améliorante.",
      "Voir l'exemple résolu `dslCoinChange` — minimisez sur une somme de "
          "variables indicatrices pour trouver le plus petit ensemble de "
          "pièces totalisant la cible.",
    ],
    'maximize': [
      "Dans CrispCalc, `maximize` émet `solve maximize __obj__;` de FlatZinc. "
          "Le solveur sous-jacent fait de la séparation-évaluation tout comme "
          "`minimize`, mais avec le resserrement de la borne inférieure "
          "inversé.",
      "Problème du sac à dos 0/1 classique. Le DSL le gère naturellement "
          "comme une déclaration `vars: x_1, ... in 0..1` plus une contrainte "
          "de capacité linéaire et un objectif linéaire.",
    ],
    'sudoku_regular': [
      "Dans CrispCalc, la variante classique se trouve dans "
          "`lib/engine/sudoku.dart` sous `SudokuVariant.regular`. Le solveur "
          "sous-jacent instancie une contrainte `allDifferent` par ligne, "
          "colonne et bloc (27 au total pour le 9×9) et les confie à "
          "`dart_csp`.",
    ],
    'sudoku_x': [
      "Dans CrispCalc, le Sudoku-X est `SudokuVariant.x` "
          "(`lib/engine/sudoku.dart`). Le solveur sous-jacent ajoute deux "
          "contraintes `allDifferent` supplémentaires au trio classique "
          "ligne/colonne/bloc — une par diagonale.",
    ],
    'sudoku_disjoint': [
      "Dans CrispCalc, c'est `SudokuVariant.disjoint`. Pour une grille N×N "
          "avec des blocs √N × √N, la contrainte ajoute N recouvrements "
          "`allDifferent` de plus — un par position dans le bloc. Le 8×8 est "
          "livré comme un modèle unique.",
    ],
    'sudoku_killer': [
      "Dans CrispCalc, c'est `SudokuVariant.killer`. Le solveur sous-jacent "
          "superpose au trio classique ligne/colonne/bloc une contrainte "
          "`allDifferent` par cage et une contrainte `somme = cible` par "
          "cage. Les modèles killer 4×4 et 9×9 sont tous deux livrés.",
    ],
  };

  @override
  String get settingsWorkedExamples => 'Bibliothèque d\'exemples résolus';
  @override
  String get settingsWorkedExamplesSubtitle =>
      'Désormais accessible aussi via l\'icône livre en haut de la '
      'Calculatrice et du Bloc-notes. Appuyez ici pour la bibliothèque '
      'complète.';
  @override
  String get functionRefTitle => 'Référence des fonctions';
  @override
  String get functionRefSearchHint => 'Rechercher des fonctions…';
  @override
  String get functionRefEmpty => 'Aucune fonction ne correspond à ce filtre.';
  @override
  String get functionRefSeeAlso => 'Voir aussi :';
  @override
  String get functionRefTryInCalculator => 'Essayer dans la Calculatrice';
  @override
  String get functionRefSeeWorkedExample => 'Voir l\'exemple résolu';
  @override
  String get functionRefCatCas => 'CAS';
  @override
  String get functionRefCatNumberTheory => 'Théorie des nombres';
  @override
  String get functionRefCatPrecision => 'Haute précision';
  @override
  String get functionRefCatMatrix => 'Matrices';
  @override
  String get functionRefCatGraphing => 'Graphes';
  @override
  String get functionRefCatStatistics => 'Statistiques';
  @override
  String get functionRefCatConstraints => 'Contraintes';
  @override
  String get functionRefCatSudoku => 'Sudoku';
  @override
  String get functionRefCatUnits => 'Unités';
  @override
  String get settingsFunctionRef => 'Référence des fonctions';
  @override
  String get settingsFunctionRefSubtitle =>
      'Parcourez chaque fonction de CrispCalc : signature, exemples, '
      'fonctions liées et un raccourci pour coller dans la Calculatrice.';

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
  String get navNotepad => 'Notas';
  @override
  String get notepadDefaultDocName => 'Sin título';
  @override
  String get notepadAddLine => 'Añadir línea';
  @override
  String get notepadDeleteLine => 'Eliminar línea';
  @override
  String get notepadDocumentMenu => 'Menú del documento';
  @override
  String get notepadNewDocument => 'Nuevo documento';
  @override
  String get notepadOpenWelcomeSample => 'Abrir muestra de bienvenida';
  @override
  String get notepadRecalculateAll => 'Recalcular todo';
  @override
  String get notepadRename => 'Renombrar';
  @override
  String get notepadDuplicate => 'Duplicar';
  @override
  String get notepadCopyAsMarkdown => 'Copiar como Markdown';
  @override
  String get notepadDeleteDocument => 'Eliminar documento';
  @override
  String get notepadUndo => 'Deshacer';
  @override
  String get notepadLineDeleted => 'Línea eliminada';
  @override
  String notepadDocumentDeleted(String name) => 'Documento «$name» eliminado';
  @override
  String get notepadCopiedAsMarkdown => 'Copiado como Markdown';
  @override
  String get notepadCopyResult => 'Copiar resultado';
  @override
  String get notepadCopyAsLatex => 'Copiar como LaTeX';
  @override
  String get notepadCopiedResult => 'Resultado copiado';
  @override
  String get notepadCopiedAsLatex => 'Copiado como LaTeX';
  @override
  String get notepadEmptyTitle => 'Aún no hay documentos';
  @override
  String get notepadEmptyBody =>
      'Crea un nuevo documento o abre la muestra de bienvenida para empezar.';
  @override
  String notepadFreeVars(String names) => 'libre: $names';
  @override
  String notepadBlockedBy(String alias) => 'Bloqueado por $alias';
  @override
  String notepadCycle(String path) => 'Ciclo: $path';
  @override
  String notepadUnknownImport(String name) =>
      'Import desconocido: «$name» no está en las variables globales';
  @override
  String notepadInvalidImport(String name) =>
      'Nombre de import no válido: «$name»';
  @override
  String get notepadEmptyImportList => 'Lista de imports vacía';
  @override
  String notepadUseDirective(String code) => 'Directiva use: $code';
  @override
  String get notepadManageTitle => 'Gestionar notas';
  @override
  String get notepadManageNotepads => 'Gestionar notas…';
  @override
  String get notepadOpenDocument => 'Abrir';
  @override
  String get notepadExportAsJson => 'Exportar como JSON';
  @override
  String get notepadImportFromJson => 'Importar desde JSON';
  @override
  String get notepadImport => 'Importar';
  @override
  String get notepadImportJsonHint => 'Pega aquí una carga JSON de la nota…';
  @override
  String get notepadJsonCopied => 'JSON de la nota copiado al portapapeles';
  @override
  String notepadJsonImported(String name) => '«$name» importado';
  @override
  String get notepadJsonImportFailed =>
      'Importación fallida: la carga no es un JSON de nota válido';
  @override
  String get graphErrorEmpty => 'La función está vacía';
  @override
  String get graphErrorUnbalanced =>
      'Paréntesis o corchetes desequilibrados — la función no se puede graficar';
  @override
  String get graphErrorTrailingOperator =>
      'La función termina con un operador — añade el lado derecho';
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

  // -- P9-A2 --
  @override
  String get module3DScene => 'Escena 3D';
  @override
  String get module3DSceneSubtitle =>
      'Renderiza varios objetos 3D juntos — planos, rectas, esferas, cuádricas';
  @override
  String get scene3DAddPlane => 'Añadir plano';
  @override
  String get scene3DEditPlane => 'Editar plano';
  @override
  String get scene3DEmpty =>
      'Arrastra para rotar · pellizca para hacer zoom · pulsa + para añadir un plano';
  @override
  String get scene3DPanelEmpty => 'Aún no hay objetos';
  @override
  String get scene3DObjectLabel => 'Etiqueta';
  @override
  String get scene3DColor => 'Color';
  @override
  String get scene3DAdd => 'Añadir';
  @override
  String get scene3DSave => 'Guardar';
  @override
  String get scene3DEdit => 'Editar';
  @override
  String get scene3DDelete => 'Eliminar';
  @override
  String get scene3DHide => 'Ocultar';
  @override
  String get scene3DShow => 'Mostrar';
  @override
  String get scene3DLabelRequired => 'Etiqueta requerida';
  @override
  String get scene3DCoefRequired => 'Requerido';
  @override
  String get scene3DCoefInvalid => 'Número no válido';
  @override
  String get scene3DPlaneZeroNormal =>
      'El vector normal (a, b, c) no puede ser cero';

  // -- P9-A3 --
  @override
  String get scene3DAddObject => 'Añadir objeto';
  @override
  String get scene3DAddLine => 'Añadir recta';
  @override
  String get scene3DEditLine => 'Editar recta';
  @override
  String get scene3DAddSphere => 'Añadir esfera';
  @override
  String get scene3DEditSphere => 'Editar esfera';
  @override
  String get scene3DLinePointDir => 'Punto + dirección';
  @override
  String get scene3DLineTwoPoints => 'Dos puntos';
  @override
  String get scene3DLinePoint => 'Punto';
  @override
  String get scene3DLineDirection => 'Dirección';
  @override
  String get scene3DLineFirstPoint => 'Primer punto';
  @override
  String get scene3DLineSecondPoint => 'Segundo punto';
  @override
  String get scene3DLineZeroDirection =>
      'El vector dirección no puede ser cero (o elige dos puntos distintos)';
  @override
  String get scene3DSphereCenter => 'Centro';
  @override
  String get scene3DSphereRadius => 'Radio';
  @override
  String get scene3DSpherePositiveRadius => 'El radio debe ser mayor que cero';

  // -- P9-A4 --
  @override
  String get scene3DIntersectionsEmpty =>
      'Añade dos o más objetos para ver sus intersecciones';
  @override
  String scene3DIntersectionsTitle(int n) =>
      n == 1 ? '1 intersección' : '$n intersecciones';
  @override
  String get intersectionPoint => 'Punto';
  @override
  String get intersectionTwoPoints => 'Dos puntos';
  @override
  String get intersectionLine => 'Recta';
  @override
  String get intersectionCircle => 'Círculo';
  @override
  String intersectionReason(String key) {
    switch (key) {
      case 'parallelPlanes':
        return 'Planos paralelos (sin intersección)';
      case 'coincidentPlanes':
        return 'Planos coincidentes';
      case 'lineParallelToPlane':
        return 'Recta paralela al plano (sin intersección)';
      case 'lineInPlane':
        return 'La recta está contenida en el plano';
      case 'sphereMissesPlane':
        return 'El plano no toca la esfera';
      case 'degeneratePlane':
        return 'Plano degenerado (vector normal cero)';
      case 'parallelLines':
        return 'Rectas paralelas (sin intersección)';
      case 'coincidentLines':
        return 'Rectas coincidentes';
      case 'skewLines':
        return 'Rectas alabeadas (no se encuentran)';
      case 'lineMissesSphere':
        return 'La recta no toca la esfera';
      case 'degenerateLine':
        return 'Recta degenerada (dirección cero)';
      case 'spheresApart':
        return 'Las esferas están demasiado separadas';
      case 'sphereInsideSphere':
        return 'Una esfera está contenida en la otra';
      case 'coincidentSpheres':
        return 'Esferas idénticas';
      case 'numericalFailure':
        return 'Caso numérico límite (prueba con otros valores)';
      // P9-A5b: plano × cuádrica → cónica.
      case 'circle':
        return 'Círculo';
      case 'ellipse':
        return 'Elipse';
      case 'parabola':
        return 'Parábola';
      case 'hyperbola':
        return 'Hipérbola';
      case 'degenerateConic':
        return 'Cónica degenerada (par de rectas o un punto)';
      case 'noConic':
        return 'El plano no toca la cuádrica';
      case 'planeOnQuadric':
        return 'El plano descansa sobre la cuádrica';
      default:
        return key;
    }
  }

  // -- P9-A5 --
  @override
  String get scene3DAddQuadric => 'Añadir cuádrica';
  @override
  String get scene3DEditQuadric => 'Editar cuádrica';
  @override
  String get scene3DQuadricKind => 'Tipo';
  @override
  String get scene3DQuadricSemiAxes => 'Semiejes';
  @override
  String get scene3DQuadricPositiveSemiAxes =>
      'Los semiejes deben ser positivos (a, b, c > 0)';
  @override
  String get quadricKindEllipsoid => 'Elipsoide';
  @override
  String get quadricKindCone => 'Cono elíptico';
  @override
  String get quadricKindCylinder => 'Cilindro elíptico';
  @override
  String get quadricKindParaboloid => 'Paraboloide elíptico';
  @override
  String get quadricKindHyperboloid1 => 'Hiperboloide (1 hoja)';
  @override
  String get quadricKindHyperboloid2 => 'Hiperboloide (2 hojas)';

  // -- P9-A5c.3 --
  @override
  String get conicOpenIn3DScene => 'Abrir en escena 3D';
  @override
  String get conicLiftNotAConic =>
      'No es una cónica — nada que elevar. Añade primero términos cuadráticos.';

  // -- P9-A6 --
  @override
  String get scene3DAddParametricSurface => 'Añadir superficie paramétrica';
  @override
  String get scene3DEditParametricSurface => 'Editar superficie paramétrica';
  @override
  String get scene3DAddParametricCurve => 'Añadir curva paramétrica';
  @override
  String get scene3DEditParametricCurve => 'Editar curva paramétrica';
  @override
  String get scene3DParametricSurface => 'Superficie paramétrica';
  @override
  String get scene3DParametricCurve => 'Curva paramétrica';

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
  String settingsNumberFormatDecimalPlaces(int n) => 'Decimales: $n';
  @override
  String get settingsAutoBindSolve => 'Asignar soluciones automáticamente';
  @override
  String get settingsAutoBindSolveSubtitle =>
      'Si está activo, solve(ec, x) también asigna la solución a x.';
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

  // -- Round 91 --
  @override
  String get storeAsVariable => 'Guardar como variable';
  @override
  String get storeAsFunction => 'Guardar como función';
  @override
  String get storeVariableTitle => 'Guardar como variable';
  @override
  String get storeFunctionTitle => 'Guardar como función';
  @override
  String get storeNameLabel => 'Nombre';
  @override
  String get storeFunctionParamLabel => 'Parámetro';
  @override
  String get storeButton => 'Guardar';
  @override
  String get storeNameReserved => 'Nombre reservado por una función integrada';
  @override
  String storeSavedAs(String name) => 'Guardado como $name';

  // -- R91b --
  @override
  String storeOverwriteTitle(String name) => '¿Sobrescribir "$name"?';
  @override
  String storeOverwriteCurrent(String existing) => 'Actualmente: $existing';
  @override
  String get storeOverwriteConfirm => 'Sobrescribir';

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
  String get sudokuClearToStart => 'Reiniciar';
  @override
  String get sudokuSolvedCorrectly => '¡Resuelto!';
  @override
  String get sudokuFilledWithErrors => 'Con errores';
  @override
  String get sudokuWinOverlayTapHint => 'Toca para cerrar';
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
      case 'eight8x8':
        return '8×8 medio';
      case 'eight8x8X':
        return '8×8 Sudoku-X medio';
      case 'eight8x8Disjoint':
        return '8×8 Disjunto medio';
      case 'eight8x8Killer':
        return '8×8 Killer';
      case 'ten10x10':
        return '10×10 medio';
      case 'twelve12x12':
        return '12×12 medio';
      case 'fifteen15x15':
        return '15×15 medio';
      case 'standard9x9Easy':
        return '9×9 fácil';
      case 'standard9x9Medium':
        return '9×9 medio';
      case 'standard9x9Hard':
        return '9×9 difícil (AI Escargot)';
      case 'standard9x9XEasy':
        return '9×9 Sudoku-X fácil';
      case 'killer4x4':
        return '4×4 Killer';
      case 'killer9x9':
        return '9×9 Killer';
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
  String get sudokuVariantKiller => 'Killer';
  @override
  String get sudokuVariantDisjoint => 'Disjunto';
  @override
  String get sudokuCheckUnique => 'Comprobar unicidad';
  @override
  String get sudokuUniqueSolution => 'Solución única';
  @override
  String get sudokuMultipleSolutions => 'Varias soluciones';
  @override
  String get sudokuShowHints => 'Mostrar pistas';
  @override
  String get sudokuShowHintsSubtitle =>
      'Notas a lápiz: para cada casilla vacía, los dígitos aún no '
      'eliminados por fila, columna, bloque o diagonal.';
  @override
  String get sudokuHintLevelOff => 'Desactivado';
  @override
  String get sudokuHintLevelBasic => 'Básico';
  @override
  String get sudokuHintLevelAdvanced => 'Avanzado';
  @override
  String get sudokuHintLevelAdvancedHelp =>
      'El modo avanzado ejecuta el solver CSP completo en cada '
      'candidato, detectando también los singles ocultos y los pares '
      'desnudos. Más lento — tarda unos segundos en sudokus 9×9 '
      'difíciles.';
  @override
  String get sudokuHintLevelComputing => 'Calculando pistas avanzadas…';

  @override
  String sudokuConstraintRow(int row) => 'Fila $row';
  @override
  String sudokuConstraintCol(int col) => 'Columna $col';
  @override
  String sudokuConstraintBox(int box) => 'Bloque $box';
  @override
  String sudokuConstraintCage(int cage, int sum) => 'Jaula $cage (suma $sum)';
  @override
  String get sudokuConstraintMainDiagonal => 'Diagonal principal';
  @override
  String get sudokuConstraintAntiDiagonal => 'Antidiagonal';
  @override
  String sudokuConstraintDisjointGroup(int group) => 'Grupo disjunto $group';
  @override
  String get sudokuConstraintStartingPosition => 'Posición inicial';

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
  String get constraintsTabDsl => 'Texto libre';
  @override
  String get constraintsTabFlatZinc => 'FlatZinc';
  @override
  String get constraintsDslIntro =>
      'Declare variables con `vars: x, y in 1..9`, '
      'use `allDifferent(x, y, z)` para distinción, '
      'y escriba cualquier otra línea como restricción '
      '(p. ej. `x + 2*y == 10`).';
  @override
  String get constraintsDslInputLabel => 'Programa de restricciones';
  @override
  String get constraintsDslExamplesButton => 'Ejemplos';
  @override
  String get constraintsDslExamplesTooltip => 'Cargar un ejemplo prediseñado';
  @override
  String constraintsDslExampleTitle(String id) {
    switch (id) {
      case 'magicSum':
        return 'Suma mágica de 3 dígitos';
      case 'magicSquare3':
        return 'Cuadrado mágico 3×3';
      case 'mapColoring':
        return 'Coloración de mapa (K4)';
      case 'orderedTriples':
        return 'Tripletes ordenados que suman 20';
      case 'coinChangeMin':
        return 'Cambio de monedas (minimizar piezas)';
      case 'schedulingMakespan':
        return 'Planificación — minimizar el makespan';
      case 'cumulativeScheduling':
        return 'Planificación acumulativa — capacidad 2';
      case 'rcpsp':
        return 'RCPSP — equipo + equipamiento';
    }
    return id;
  }

  @override
  String get constraintsFlatZincIntro =>
      'Pegue un modelo FlatZinc (típicamente generado por mzn2fzn '
      'a partir de una fuente MiniZinc). El solver devuelve la '
      'salida estándar FlatZinc: líneas `nombre = valor;` por cada '
      'anotación `:: output_var`, terminadas con `----------`, '
      'seguidas de `==========` tras la última solución.';
  @override
  String get constraintsFlatZincInputLabel => 'Código fuente FlatZinc';
  @override
  String get constraintsFlatZincAllSolutions => 'Todas las soluciones';
  @override
  String get constraintsFlatZincFirstSolution => 'Primera solución';
  @override
  String get constraintsFlatZincExhaustiveOne => '1 solución (exhaustivo)';
  @override
  String constraintsFlatZincExhaustiveN(int n) => '$n soluciones (exhaustivo)';
  @override
  String get constraintsFlatZincUnsatisfiable => 'Insatisfacible';
  @override
  String constraintsFlatZincExampleTitle(String id) {
    switch (id) {
      case 'nqueens4':
        return '4 reinas';
      case 'binPacking':
        return 'Bin packing (3 objetos, 2 cajas)';
    }
    return id;
  }

  @override
  String get constraintsExplainFailure => 'Explicar el fallo';
  @override
  String get constraintsExplainHeader => 'Conflicto mínimo (QuickXplain)';
  @override
  String get constraintsExplainSatisfiable =>
      'Sin conflicto — el modelo es en realidad satisfacible.';
  @override
  String constraintsExplainEntryCount(int n) =>
      n == 1 ? '1 restricción en conflicto' : '$n restricciones en conflicto';
  @override
  String get constraintsExportFlatZinc => 'Exportar como FlatZinc';
  @override
  String get constraintsExportedHeader => 'Traducción FlatZinc';

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
  String constraintsOptimalHeader(num objective) =>
      'Óptimo: objetivo = $objective';

  @override
  String get clearSearchTooltip => 'Borrar búsqueda';
  @override
  String get clearFunctionSlotTooltip => 'Borrar función';
  @override
  String get deleteMemorySlotTooltip => 'Eliminar espacio de memoria';

  @override
  String get helpModeEnableTooltip =>
      'Modo ayuda: toca cualquier control para ver una explicación';
  @override
  String get helpModeDisableTooltip => 'Salir del modo ayuda';
  @override
  String get keypadHelpLearnMore => 'Más información';
  @override
  String get historyHelpTitle => 'Cómo se calculó esto';
  @override
  String historyHelpComputedVia(String engine) => 'Calculado mediante $engine';
  @override
  String get historyHelpDirectEvaluation =>
      'Evaluación numérica directa — sin llamada simbólica.';
  @override
  String get historyHelpShowSteps => 'Mostrar pasos';

  @override
  String get moduleHelpTooltip => '¿Qué hace este módulo?';
  @override
  String moduleHelpTitle(ModuleHelpKind kind) {
    switch (kind) {
      case ModuleHelpKind.curveSketching:
        return 'Estudio de curvas';
      case ModuleHelpKind.planes:
        return 'Análisis de planos';
      case ModuleHelpKind.conicSections:
        return 'Cónicas';
      case ModuleHelpKind.statistics:
        return 'Estadística';
      case ModuleHelpKind.graphing3D:
        return 'Gráficos 3D';
      case ModuleHelpKind.scene3D:
        return 'Escena 3D';
      case ModuleHelpKind.constraints:
        return 'Restricciones';
      case ModuleHelpKind.sudoku:
        return 'Sudoku';
    }
  }

  @override
  String moduleHelpDescription(ModuleHelpKind kind) {
    switch (kind) {
      case ModuleHelpKind.curveSketching:
        return 'Análisis completo de una función de una variable f(x): '
            'dominio, intersecciones, derivada y puntos críticos, '
            'extremos, puntos de inflexión, asíntotas y un croquis. '
            'Introduce la función en el cuadro de entrada; los '
            'resultados aparecen al tocar.';
      case ModuleHelpKind.planes:
        return 'Analiza planos 3D dados en forma cartesiana '
            '(ax + by + cz = d) o paramétrica (punto + dos vectores '
            'directores). Calcula el vector normal, las intersecciones '
            'con los ejes y las relaciones entre planos.';
      case ModuleHelpKind.conicSections:
        return 'Clasifica una cónica general '
            'Ax² + Bxy + Cy² + Dx + Ey + F = 0 como elipse, hipérbola, '
            'parábola o degenerada, y obtiene centro, ejes, focos y '
            'excentricidad. Usa el discriminante B² − 4AC para la '
            'clasificación.';
      case ModuleHelpKind.statistics:
        return 'Estadística descriptiva (media, mediana, varianza, …), '
            'regresión lineal con R² y residuos, distribuciones normal '
            'y binomial con PDF / CDF / cuantiles, y pruebas de '
            'hipótesis: t de Welch, t pareada, ANOVA de un factor, '
            'chi-cuadrado de bondad de ajuste e independencia, prueba '
            'exacta de Fisher, prueba de los rangos con signo de '
            'Wilcoxon y prueba de signos. Las pruebas devuelven el '
            'estadístico, el valor p y (si procede) un intervalo de '
            'confianza al α elegido.';
      case ModuleHelpKind.graphing3D:
        return 'Representa z = f(x, y) como una superficie alámbrica '
            'rotable. Arrastra para rotar; pellizca / desplaza para '
            'hacer zoom. La acción de remuestreo reconstruye la malla '
            'al nivel de zoom actual para que el detalle siga a la '
            'distancia de la cámara.';
      case ModuleHelpKind.scene3D:
        return 'Renderiza varios objetos 3D juntos — planos, rectas, '
            'esferas y cuádricas — en una escena compartida. Útil para '
            'visualizar intersecciones (por ejemplo dos planos que se '
            'encuentran en una recta) y para construir argumentos '
            'geométricos paso a paso.';
      case ModuleHelpKind.constraints:
        return 'Resuelve problemas combinatorios: ecuaciones '
            'diofánticas (soluciones enteras de ax + by = c), '
            'criptaritmos (estilo SEND + MORE = MONEY), un pequeño DSL '
            'de programación con restricciones de dominio finito '
            '(`allDifferent`, `noOverlap`, `cumulative`, `minimize` / '
            '`maximize`) y una pestaña FlatZinc para problemas '
            'escritos en el formato intermedio MiniZinc.';
      case ModuleHelpKind.sudoku:
        return 'Resuelve puzzles 4×4 y 9×9, incluidas las variantes '
            'X (diagonal), Killer (sumas de jaulas) y Disjoint-Groups. '
            'El solucionador paso a paso muestra el árbol de búsqueda, '
            'permitiendo ver cómo el motor reduce los candidatos. Los '
            'niveles de pista exponen la respuesta de la siguiente '
            'celda o una justificación lógica.';
    }
  }

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
  String get workedExamplesCatConstraints => 'Restricciones';
  @override
  String? workedExampleTitle(String id) {
    switch (id) {
      case 'killerSudoku':
        return 'Killer Sudoku (9×9)';
      case 'constraintEditor':
        return 'Editor de restricciones libres';
      case 'dslMagicSquare':
        return 'Cuadrado mágico 3×3 (DSL)';
      case 'dslMapColoring':
        return 'Coloración de mapa K4 (DSL)';
      case 'dslOrderedTriples':
        return 'Tripletes ordenados que suman 20 (DSL)';
      case 'dslCoinChange':
        return 'Cambio de monedas — minimizar piezas (DSL)';
      case 'dslSchedulingMakespan':
        return 'Planificación mono-máquina — minimizar el makespan (DSL)';
      case 'dslCumulativeScheduling':
        return 'Planificación paralela — cumulative (DSL)';
      case 'dslRcpsp':
        return 'Planificación de proyecto RCPSP — dos recursos (DSL)';
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
      case 'piPrecision':
        return 'π con 100 dígitos';
      case 'ePrecision':
        return 'e con 50 dígitos';
      case 'factorint360':
        return 'Factorización en primos';
      case 'nextprime1000':
        return 'Primo siguiente después de 1000';
      case 'mersenneM31':
        return 'Primo de Mersenne M31';
      case 'divisors12':
        return 'Todos los divisores';
      case 'eulerTotient':
        return 'Función φ de Euler';
      case 'modpowCrypto':
        return 'Exponenciación modular';
      case 'contFracPi':
        return 'Fracción continua de π';
      case 'booleanIsprimeAnd':
        return 'Primo y acotado';
      case 'booleanEqualityFold':
        return 'Evaluación de igualdad';
      case 'booleanNotPrime':
        return 'Negación';
      case 'booleanOrChain':
        return 'Disyunción sobre comparaciones';
      case 'booleanIfFold':
        return 'Evaluación condicional';
      case 'compoundInterest':
        return 'Interés compuesto';
      case 'zScore':
        return 'Consulta de puntuación Z';
      case 'statsHypothesisTests':
        return 'Espacio de pruebas de hipótesis';
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
      case 'killerSudoku':
        return 'Abre el módulo Sudoku precargado con la cuadrícula 9×9 Killer.';
      case 'constraintEditor':
        return 'Abre el módulo Restricciones — declara variables, agrega restricciones, resuelve.';
      case 'dslMagicSquare':
        return 'Carga el programa de 9 variables del cuadrado mágico en el editor DSL.';
      case 'dslMapColoring':
        return 'Carga una coloración K4 con 3 colores — intencionalmente infactible para mostrar la ruta «sin soluciones».';
      case 'dslOrderedTriples':
        return 'Carga un programa DSL que enumera (a, b, c) con a < b < c y a + b + c = 20.';
      case 'dslCoinChange':
        return 'Carga un programa DSL que paga 17 ¢ con el menor número de monedas de {1, 5, 10, 25} mediante `minimize`.';
      case 'dslSchedulingMakespan':
        return 'Carga un programa DSL que planifica tres tareas (duraciones 4/3/2) en una máquina con `noOverlap` y minimiza el makespan.';
      case 'dslCumulativeScheduling':
        return 'Carga un programa DSL que planifica tres tareas sobre un recurso de capacidad 2 con `cumulative` y minimiza el makespan.';
      case 'dslRcpsp':
        return 'Carga un programa DSL con dos restricciones `cumulative` paralelas (equipo + equipamiento, capacidad 3 cada una) sobre cuatro tareas; minimiza el makespan.';
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
      case 'piPrecision':
        return 'pi(100) — constante de alta precisión vía MPFR.';
      case 'ePrecision':
        return 'e(50) — misma canalización MPFR que pi(N).';
      case 'factorint360':
        return 'factorint(360) → 2³ · 3² · 5 con superíndices Unicode.';
      case 'nextprime1000':
        return 'nextprime(1000) — respaldado por FLINT vía SymEngine ntheory.';
      case 'mersenneM31':
        return 'factorint(2^31 − 1) — confirma el octavo primo de '
            'Mersenne como factor único.';
      case 'divisors12':
        return 'divisors(12) → 1, 2, 3, 4, 6, 12 — derivado de la '
            'factorización en primos.';
      case 'eulerTotient':
        return 'totient(36) — cantidad de restos coprimos con 36.';
      case 'modpowCrypto':
        return 'modpow(2, 100, 1000000007) — el núcleo de RSA / '
            'Diffie-Hellman.';
      case 'contFracPi':
        return 'cfrac(pi, 10) — el desarrollo [3; 7, 15, 1, 292, …] '
            'detrás de 355/113.';
      case 'booleanIsprimeAnd':
        return 'isprime(17) y 17 < 20 — ambas cláusulas son verdaderas, '
            'así que la conjunción es verdadera.';
      case 'booleanEqualityFold':
        return '2 == 2 — operandos constantes se reducen a verdadero.';
      case 'booleanNotPrime':
        return 'not isprime(15) — 15 = 3·5, por lo que el resultado '
            'es verdadero.';
      case 'booleanOrChain':
        return '(5 > 3) o (1 == 2) — la primera cláusula es verdadera, '
            'así que la disyunción entera es verdadera.';
      case 'booleanIfFold':
        return 'if(isprime(7), 100, 200) — la condición se reduce a '
            'verdadero, por lo que gana la rama then.';
      case 'compoundInterest':
        return '1000 € al 5 % durante 10 años, capitalización anual.';
      case 'zScore':
        return 'Ve a la pantalla Estadística → Distribuciones para '
            'calcular Φ(1,96) ≈ 0,975.';
      case 'statsHypothesisTests':
        return 'Abre el módulo Estadística directamente en la pestaña '
            'Pruebas — t de una muestra, t de dos muestras (Welch), '
            'pareada, ANOVA, chi-cuadrado y Wilcoxon — con datos de '
            'ejemplo precargados.';
      case 'unitConversion':
        return '100 km/h convertido a mph — analizador inline V2.';
      case 'compositeDim':
        return '100 m / 10 s da una velocidad en m/s — analizador V5.';
    }
    return null;
  }

  // Round 100: ES function-reference prose.
  @override
  String? functionRefDescription(String id) {
    switch (id) {
      case 'solve':
        return "Resuelve simbólicamente una ecuación para una variable; "
            "devuelve una lista de soluciones.";
      case 'expand':
        return "Desarrolla productos y potencias en una suma de monomios.";
      case 'simplify':
        return "Agrupa términos semejantes, cancela factores comunes y "
            "aplica las identidades algebraicas habituales.";
      case 'factor':
        return "Factoriza un polinomio sobre los racionales en factores "
            "irreducibles.";
      case 'diff':
        return "Derivada primera simbólica respecto a una variable.";
      case 'integrate':
        return "Integral indefinida (3 argumentos) o integral definida "
            "(5 argumentos) con respaldo numérico.";
      case 'subst':
        return "Sustituye cada aparición libre de `variable` en `expression` "
            "por `value`. También disponible como `substitute(...)`.";
      case 'limit':
        return "Límite numérico cuando `variable` tiende a `point`. `point` "
            "puede ser un valor finito o `oo` / `-oo`.";
      case 'gcd':
        return "Máximo común divisor (MCD) de dos enteros o polinomios.";
      case 'lcm':
        return "Mínimo común múltiplo (mcm) de dos enteros o polinomios.";
      case 'factorial':
        return "Factorial entero exacto. Los `n` pequeños usan el `BigInt` "
            "de Dart; los `n` grandes se delegan en SymEngine.";
      case 'fibonacci':
        return "n-ésimo número de Fibonacci. `fib(n)` es el alias corto.";
      case 'isprime':
        return "Test de primalidad probabilístico sobre enteros.";
      case 'nextprime':
        return "El menor número primo estrictamente mayor que `n`.";
      case 'prevprime':
        return "El mayor número primo estrictamente menor que `n`. Error si "
            "no existe tal primo (p. ej. `prevprime(2)`).";
      case 'factorint':
        return "Factorización en primos con la forma `p₁^e₁ · p₂^e₂ · …` con "
            "exponentes en superíndice Unicode.";
      case 'divisors':
        return "Todos los divisores positivos de `n`, ordenados de menor a "
            "mayor y separados por comas.";
      case 'totient':
        return "Función φ de Euler φ(n): la cantidad de enteros en 1..n "
            "coprimos con `n`.";
      case 'modpow':
        return "Exponenciación modular `aᵉ mod m`. Un exponente negativo usa "
            "el inverso modular de `a` (cuando existe).";
      case 'modinv':
        return "Inverso modular `a⁻¹ mod m` mediante el algoritmo de Euclides "
            "extendido. Error cuando `mcd(a, m) ≠ 1`.";
      case 'jacobi':
        return "Símbolo de Jacobi (a/n) ∈ {−1, 0, 1} para `n` impar positivo; "
            "generaliza el símbolo de Legendre.";
      case 'cfrac':
        return "Desarrollo en fracción continua `[a₀; a₁, …]` de `x` con `n` "
            "términos. `x` puede ser `pi` / `e` / `EulerGamma` / `sqrt(2)`, "
            "un racional `p/q` o un decimal.";
      case 'convergent':
        return "El k-ésimo convergente `p/q` de la fracción continua de `x` — "
            "una mejor aproximación racional para el tamaño de su "
            "denominador.";
      case 'pi_precision':
        return "π con N cifras decimales mediante MPFR; devuelve la cadena "
            "de dígitos en bruto.";
      case 'e_precision':
        return "Número de Euler e con N cifras decimales mediante MPFR.";
      case 'sqrt_precision':
        return "Raíz cuadrada del entero `k` con N cifras decimales mediante "
            "MPFR. La forma de dos argumentos elige la vía de alta "
            "precisión.";
      case 'eulergamma_precision':
        return "Constante de Euler-Mascheroni γ ≈ 0,5772… con N cifras "
            "decimales mediante MPFR.";
      case 'matrix_literal':
        return "Literal de matriz: una lista de filas, cada fila una lista "
            "de expresiones de celda. Las celdas pueden ser números, "
            "fracciones o simbólicas.";
      case 'det':
        return "Determinante de una matriz cuadrada. Devuelve un escalar "
            "simbólico.";
      case 'inv':
        return "Inversa de una matriz cuadrada no singular. Error cuando "
            "`det = 0`.";
      case 'transpose':
        return "Transpuesta: intercambia filas y columnas. Funciona con "
            "matrices rectangulares.";
      case 'rref':
        return "Forma escalonada reducida por filas mediante eliminación de "
            "Gauss-Jordan. Funciona sobre entradas simbólicas/racionales.";
      case 'matrix_arithmetic':
        return "Suma/resta elemento a elemento y multiplicación de matrices "
            "sobre literales `Matrix(...)`.";
      case 'mean':
        return "Media aritmética de una muestra como lista de números. "
            "Disponible en la pestaña «Estadística descriptiva» del módulo de "
            "Estadística, junto a los estadísticos habituales.";
      case 'welch_t':
        return "Prueba t de dos muestras con varianzas desiguales "
            "(Welch-Satterthwaite). Opción robusta por defecto cuando los dos "
            "grupos pueden tener dispersiones distintas.";
      case 'paired_t':
        return "Prueba t para muestras pareadas sobre las diferencias "
            "intrasujeto frente a μ₀ = 0. Se usa cuando las mismas unidades "
            "se miden dos veces (antes/después).";
      case 'anova_1':
        return "Análisis de varianza (ANOVA) de un factor sobre K grupos "
            "independientes. Contrasta si difieren las medias de los grupos; "
            "da un estadístico F y un valor p.";
      case 'chi2_goodness':
        return "Prueba de bondad de ajuste chi-cuadrado: ¿los recuentos "
            "observados coinciden con una distribución supuesta?";
      case 'chi2_independence':
        return "Prueba de independencia chi-cuadrado sobre una tabla de "
            "contingencia: ¿son independientes dos variables categóricas?";
      case 'fisher_exact':
        return "Prueba exacta de Fisher sobre una tabla de contingencia 2×2. "
            "Valor p hipergeométrico exacto, sin aproximación para muestras "
            "grandes.";
      case 'wilcoxon':
        return "Prueba de suma de rangos de Wilcoxon / U de "
            "Mann-Whitney: prueba no paramétrica de dos muestras sobre "
            "rangos. Robusta ante datos no normales.";
      case 'sign_test':
        return "Prueba de los signos para muestras pareadas: prueba no "
            "paramétrica basada en la mediana de las diferencias pareadas. "
            "Cuenta cuántas veces `después > antes`.";
      case 'vars':
        return "Declara las variables de decisión enteras y su dominio. "
            "Siempre la primera línea de un programa DSL de CrispCalc.";
      case 'all_different':
        return "Restricción global «todos los valores distintos dos a dos». "
            "La restricción estrella de PPC: propagación mucho más fuerte que "
            "n·(n-1)/2 cláusulas `!=` dos a dos.";
      case 'no_overlap':
        return "Planificación disyuntiva: tareas con variables de inicio "
            "dadas y duraciones fijas no pueden solaparse en el tiempo en una "
            "misma máquina.";
      case 'cumulative':
        return "Planificación acumulativa sobre un recurso renovable de "
            "capacidad fija. Cada tarea tiene una duración y una demanda de "
            "recurso propia.";
      case 'minimize':
        return "Objetivo: minimizar una expresión lineal sobre las variables "
            "de decisión. Combínalo con restricciones para resolver PSR de "
            "optimización.";
      case 'maximize':
        return "Objetivo: maximizar una expresión lineal. Imagen especular "
            "de `minimize`: la misma ramificación y acotación, en sentido "
            "opuesto.";
      case 'sudoku_regular':
        return "Reglas clásicas del Sudoku: cada fila, columna y caja "
            "contiene cada dígito exactamente una vez. Hay plantillas para "
            "4×4, 6×6, 8×8, 9×9, 10×10, 12×12, 15×15 y 16×16.";
      case 'sudoku_x':
        return "Sudoku-X: reglas clásicas del Sudoku más las dos diagonales "
            "principales, que también son «todas distintas». Se ofrece como "
            "plantilla 8×8.";
      case 'sudoku_disjoint':
        return "Grupos disjuntos: reglas clásicas más una restricción «todas "
            "distintas» adicional sobre las celdas que ocupan la misma "
            "posición dentro de la caja, en todas las cajas.";
      case 'sudoku_killer':
        return "Sudoku killer: sin pistas dadas; en su lugar, la cuadrícula "
            "se divide en «jaulas», cada una «todas distintas» y con suma "
            "igual a un objetivo dado.";
      default:
        return null;
    }
  }

  @override
  String? functionRefExampleHint(String id, int index) {
    final list = _esHints[id];
    if (list == null || index < 0 || index >= list.length) return null;
    return list[index];
  }

  static const _esHints = <String, List<String>>{
    'solve': [
      "En CrispCalc, `solve(x^2 - 1, x)` devuelve una lista de raíces al "
          "estilo de Python. La llamada subyacente es el `solve()` de "
          "SymEngine (la rama de raíces racionales para polinomios), envuelta "
          "por el puente y serializada de nuevo a una cadena de Dart.",
      "`=` en la entrada se acepta como sintaxis de ecuación: el "
          "preprocesador normaliza `lhs = rhs` a `lhs - rhs` antes de la "
          "llamada al puente.",
      "Las raíces complejas vuelven como el literal `I` de SymEngine. Si las "
          "reutilizas en otras llamadas (p. ej. `expand((-I)*(I))`), el "
          "puente las mantiene simbólicas.",
    ],
    'expand': [
      "En CrispCalc, `expand((x + 1)^2)` devuelve el desarrollo del binomio. "
          "La llamada subyacente es el `expand()` de SymEngine, que descompone "
          "los nodos `Pow` y `Mul` y agrupa los términos semejantes.",
      "Los coeficientes coinciden con la fila 5 del triángulo de Pascal: "
          "1, 5, 10, 10, 5, 1, cada uno multiplicado por la potencia de 2 "
          "correspondiente.",
      "La identidad de la diferencia de cuadrados, útil en combinación con "
          "`factor` para alternar entre las formas.",
    ],
    'simplify': [
      "En CrispCalc, `simplify` cancela el factor común `(x - 2)`. La "
          "llamada subyacente es el `simplify()` de SymEngine, que prueba "
          "`rational_simplify` más un pequeño conjunto de reglas de "
          "reescritura.",
      "Agrupación de términos semejantes en una entrada polinómica: "
          "internamente es simplemente `expand` seguido de la fusión de "
          "coeficientes.",
      "Identidad pitagórica; SymEngine aplica la regla de reescritura "
          "trigonométrica antes de devolver el literal `1`.",
    ],
    'factor': [
      "En CrispCalc, `factor(x^2 - 1)` devuelve la factorización como "
          "diferencia de cuadrados. La llamada subyacente es el `factor()` de "
          "SymEngine, que usa Berlekamp / Cantor–Zassenhaus para polinomios "
          "de una variable sobre Q.",
      "Identidad de la suma/diferencia de cubos: un factor lineal por un "
          "trinomio de segundo grado irreducible sobre Q.",
      "La factorización se detiene en la irreducibilidad sobre Q: `x^2 + 1` "
          "no se descompone más sin admitir raíces complejas.",
    ],
    'diff': [
      "En CrispCalc, `diff(...)` aplica término a término las reglas de la "
          "potencia y de la constante. La llamada subyacente es el `diff()` "
          "de SymEngine, que recorre el árbol de la expresión y emite un "
          "nuevo nodo `Add` simbólico.",
      "Regla de la cadena: SymEngine aplica `diff(sin(u))/du * du/dx` para el "
          "interior `u = x^2`.",
      "Regla del producto: observa que SymEngine deja el resultado sin "
          "factorizar. Pasado por `factor`, se saca `exp(x)` como factor "
          "común.",
    ],
    'integrate': [
      "En CrispCalc, la integral indefinida `integrate(...)` se delega en el "
          "`integrate()` de SymEngine. La integración por partes se aplica "
          "automáticamente cuando un factor se deriva a un polinomio.",
      "Forma definida: cuando SymEngine dispone de una primitiva en forma "
          "cerrada, aplica el teorema fundamental del cálculo. Si falla "
          "simbólicamente, CrispCalc recurre a la regla de Simpson "
          "(200 subintervalos).",
      "Fracciones parciales: 1/(x²-1) = 1/(2(x-1)) - 1/(2(x+1)). SymEngine "
          "realiza el cálculo automáticamente.",
    ],
    'subst': [
      "En CrispCalc, `subst` reescribe el árbol de la expresión y luego "
          "intenta una pasada de simplificación. La llamada subyacente es el "
          "`xreplace()` de SymEngine (sustitución solo de variables, sin "
          "coincidencia de patrones).",
      "Las constantes numéricas `pi`, `e` y la unidad imaginaria `I` las "
          "reconoce SymEngine y se propagan a través de la identidad "
          "trigonométrica.",
      "La sustitución es simbólica: las variables libres no relacionadas `a` "
          "y `b` permanecen intactas.",
    ],
    'limit': [
      "En CrispCalc, `limit(...)` es un método numérico: el puente evalúa la "
          "expresión en una sucesión de puntos que convergen a `point` y "
          "comunica el límite cuando muestras consecutivas concuerdan a la "
          "precisión de trabajo. Sin desarrollo en serie simbólico.",
      "El literal `oo` es el centinela de infinito de SymEngine: el "
          "preprocesador lo reconoce antes del envío. Usa `-oo` para el "
          "infinito negativo.",
      "Tiende al número de Euler. Como la vía es numérica, el resultado es "
          "un número en coma flotante; usa `e(N)` para la constante en alta "
          "precisión.",
    ],
    'gcd': [
      "En CrispCalc, el `gcd(...)` entero usa la recurrencia de Euclides "
          "gcd(a, b) = gcd(b, a mod b). La llamada subyacente es el `gcd()` "
          "de SymEngine, que en el caso entero recurre a `mpz_gcd` de GMP.",
      "MCD de polinomios mediante el algoritmo de subresultantes (PRS). Útil "
          "como paso previo a `simplify` para las cancelaciones.",
      "Convención: `gcd(0, n) = |n|`. Coincide con la definición matemática "
          "que trata el 0 como múltiplo de todo entero.",
    ],
    'lcm': [
      "En CrispCalc, el `lcm(...)` entero se calcula mediante la identidad "
          "`lcm(a, b) = |a*b| / gcd(a, b)`. La llamada subyacente es el "
          "`lcm()` de SymEngine, que delega en `mpz_lcm` de GMP.",
      "36 = 2²·3², la unión de los factores en potencias de primos de "
          "12 = 2²·3 y 18 = 2·3².",
      "El mcm de polinomios elige el múltiplo de mayor grado: `x^2 - 1` ya "
          "contiene `x + 1` como factor.",
    ],
    'factorial': [
      "En CrispCalc, el sufijo `n!` y `factorial(n)` son equivalentes: el "
          "preprocesador reescribe el sufijo como llamada. Para `n ≤ 1000` "
          "calculamos en Dart con multiplicación `BigInt`; más allá, la "
          "llamada subyacente es el `factorial()` de SymEngine.",
      "158 dígitos, conservados exactamente gracias a la vía BigInt: pasar a "
          "IEEE-754 redondearía aquí a 1,0 × 10^157.",
      "Convención del producto vacío: 0! = 1. Necesaria para que la "
          "recurrencia n! = n · (n-1)! termine en 1.",
    ],
    'fibonacci': [
      "En CrispCalc, `fib(n)` y `fibonacci(n)` son la misma llamada. Para "
          "`n ≤ 90` usamos una tabla precalculada; para `n` mayores, la "
          "llamada subyacente es el `fibonacci()` de SymEngine, que usa "
          "duplicación rápida (O(log n) multiplicaciones mediante GMP).",
      "El 50.º número de Fibonacci: muy por encima del límite de la tabla "
          "para términos pequeños, pero aún cabe en un entero con signo de "
          "64 bits.",
      "Pasa a la vía respaldada por GMP. La duplicación rápida evita la "
          "recurrencia lineal O(n), de modo que incluso fib(10000) queda por "
          "debajo de un segundo.",
    ],
    'isprime': [
      "En CrispCalc, `isprime(n)` devuelve una etiqueta booleana. La llamada "
          "subyacente es `mpz_probab_prime_p` de GMP (25 rondas de "
          "Miller-Rabin, cota de error 4^-25 ≈ 9×10^-16) mediante el módulo "
          "`ntheory` de SymEngine. 2027 es el 308.º número primo.",
      "2024 = 2³·11·23.",
      "El noveno número primo de Mersenne, M61. Miller-Rabin se resuelve aún "
          "en microsegundos a este tamaño: el coste está en las "
          "exponenciaciones modulares, no en la longitud en bits.",
    ],
    'nextprime': [
      "En CrispCalc, `nextprime(n)` itera desde `n+1` y prueba cada "
          "candidato. La llamada subyacente es el `ntheory::nextprime()` de "
          "SymEngine, que usa la criba de FLINT sobre ventanas cortas cuando "
          "el hueco es grande.",
      "Estrictamente mayor: `nextprime(p)` nunca es `p` mismo, aunque `p` sea "
          "primo.",
    ],
    'prevprime': [
      "En CrispCalc, `prevprime(n)` desciende desde `n-1`. La llamada "
          "subyacente es el `ntheory::prevprime()` de SymEngine.",
      "Por debajo de 2 no existen primos; el puente lanza un error en lugar "
          "de devolver un valor centinela. CrispCalc muestra la etiqueta de "
          "error.",
    ],
    'factorint': [
      "En CrispCalc, `factorint(n)` devuelve una descomposición en primos "
          "ya formateada. La llamada subyacente es `fmpz_factor` de FLINT, "
          "con la envoltura ntheory de SymEngine por delante; CrispCalc "
          "convierte la lista de (primo, exponente) en la representación con "
          "dígitos Unicode en superíndice.",
      "El 8.º número primo de Mersenne, M31. Un único factor (él mismo): "
          "`factorint` se cortocircuita cuando la entrada es prima.",
      "Caso límite: por convención, 1 tiene la factorización vacía; "
          "CrispCalc lo muestra como el literal `1` en vez de una cadena "
          "vacía.",
    ],
    'divisors': [
      "En CrispCalc, `divisors(n)` se deriva en Dart puro a partir de "
          "`factorint(n)`: cada producto de potencias de primos pᵏ con "
          "0 ≤ k ≤ exponente. La cantidad es ∏(eᵢ + 1) — aquí (2+1)(1+1) = 6.",
      "28 es un número perfecto: la suma de sus divisores propios (todos "
          "salvo el propio 28) es 28.",
    ],
    'totient': [
      "Los cuatro restos coprimos con 12 son {1, 5, 7, 11}. CrispCalc calcula "
          "φ a partir de la factorización en primos mediante `fmpz_euler_phi` "
          "de FLINT.",
      "Para un primo p, φ(p) = p − 1, ya que todo entero positivo menor es "
          "coprimo con p.",
    ],
    'modpow': [
      "Exponenciación rápida (cuadrar y multiplicar) mediante `mpz_powm` de "
          "GMP — la operación básica de la aritmética modular y (en su "
          "versión escolar) de RSA / Diffie-Hellman. El gigantesco `2¹⁰⁰` "
          "nunca se forma de manera explícita.",
      "Un exponente negativo invierte primero la base, así que "
          "`modpow(a, -1, m)` equivale a `modinv(a, m)` — aquí 3⁻¹ ≡ 4 "
          "(mod 11). Error si mcd(a, m) ≠ 1.",
    ],
    'modinv': [
      "El único x en [0, m) con a·x ≡ 1 (mod m), mediante `mpz_invert` de "
          "GMP. Comprobación: 3·4 = 12 ≡ 1 (mod 11).",
      "Solo las unidades módulo m son invertibles. mcd(2, 4) = 2 ≠ 1, así que "
          "no existe inverso.",
    ],
    'jacobi': [
      "Para un primo n, el símbolo de Jacobi coincide con el símbolo de "
          "Legendre — aquí 2 es un residuo cuadrático módulo 7 (pues 3² ≡ 2). "
          "Mediante `mpz_jacobi` de GMP.",
      "El símbolo es 0 exactamente cuando mcd(a, n) ≠ 1; aquí mcd(6, 9) = 3.",
    ],
    'cfrac': [
      "En CrispCalc, `cfrac` realiza un desarrollo exacto en BigInt sobre una "
          "aproximación MPFR de alta precisión de la constante. El término "
          "grande 292 es justamente por qué el convergente 355/113 aproxima "
          "π de forma tan notable.",
      "Para un racional exacto el desarrollo es finito — no es más que el "
          "algoritmo de Euclides registrando sus cocientes.",
    ],
    'convergent': [
      "Milü — la aproximación de π de Zu Chongzhi (siglo V), exacta hasta "
          "seis decimales. CrispCalc pliega los primeros k+1 cocientes "
          "parciales de `cfrac` en la fracción.",
      "La aproximación escolar de π; `convergent(x, 0)` es la parte entera "
          "⌊x⌋.",
    ],
    'pi_precision': [
      "En CrispCalc, `pi(N)` es una llamada con tratamiento especial, "
          "dirigida a la vía de alta precisión antes de que SymEngine la vea. "
          "La llamada subyacente es `mpfr_const_pi` de MPFR con precisión "
          "⌈N·log2(10)⌉ + 16 bits de guarda, seguida de la conversión a "
          "base 10.",
      "Con N = 100 la precisión de trabajo es de unos 348 bits. Los bits de "
          "guarda impiden que la conversión de base muestre dígitos finales "
          "redondeados.",
    ],
    'e_precision': [
      "En CrispCalc, `e(N)` refleja la canalización de `pi(N)`: "
          "`mpfr_const_e` de MPFR (que usa la serie de Taylor Σ 1/k!) con "
          "precisión ⌈N·log2(10)⌉ + 16 bits de guarda, y luego la "
          "representación en base 10.",
      "Lo bastante corto para memorizarlo: útil como comprobación rápida de "
          "precisión frente a `limit((1 + 1/n)^n, n, oo)`.",
    ],
    'sqrt_precision': [
      "En CrispCalc, el `sqrt(k, N)` de dos argumentos es la vía de alta "
          "precisión. La llamada subyacente es `mpfr_sqrt_ui` de MPFR con "
          "precisión ⌈N·log2(10)⌉ + 16 bits de guarda. El `sqrt(2)` de un "
          "argumento devuelve en cambio el `sqrt(2)` simbólico mediante "
          "SymEngine.",
      "Útil para verificar: `sqrt(3, N)` debería concordar con dígitos de "
          "referencia obtenidos de forma independiente.",
    ],
    'eulergamma_precision': [
      "En CrispCalc, `EulerGamma(N)` usa `mpfr_const_euler` de MPFR, que "
          "evalúa γ mediante la fórmula de Brent–McMillan (funciones de "
          "Bessel modificadas). La precisión es ⌈N·log2(10)⌉ + 16 bits de "
          "guarda, igual que la canalización de `pi(N)` y `e(N)`.",
      "γ no tiene forma cerrada conocida. La rutina de MPFR es la "
          "implementación de referencia estándar; CrispCalc se limita a "
          "mostrar la cadena de dígitos.",
    ],
    'matrix_literal': [
      "En CrispCalc, el literal `Matrix(...)` lo reconoce el evaluador de "
          "matrices antes de que el motor vea la expresión. La llamada "
          "subyacente es el constructor `DenseMatrix` de SymEngine: la "
          "disposición de filas/columnas se fija en la construcción.",
      "Las celdas siguen siendo simbólicas: los racionales no se reducen a "
          "coma flotante. Lo mismo ocurre con los símbolos libres: "
          "`Matrix([[a, b], [c, d]])` se acepta y se propaga por `det` / "
          "`inv` / `rref`.",
      "Las matrices no cuadradas valen para `transpose` y `rref` pero fallan "
          "en `det` / `inv`, que exigen una entrada cuadrada.",
    ],
    'det': [
      "En CrispCalc, `det(M)` se evalúa como un único escalar. La llamada "
          "subyacente es el `DenseMatrix::det()` de SymEngine, que usa el "
          "algoritmo sin fracciones de Bareiss: exacto para entradas "
          "simbólicas/racionales, sin desbordamiento en coma flotante.",
      "Ejemplo clásico de libro de texto 3×3: el desarrollo por cofactores "
          "de Laplace da el mismo resultado en 6 términos.",
      "Las entradas simbólicas pasan sin cambios. Bareiss mantiene el "
          "resultado como un `Add` de SymEngine en lugar de un número en coma "
          "flotante.",
    ],
    'inv': [
      "En CrispCalc, `inv(M)` devuelve `adj(M)/det(M)`. La llamada subyacente "
          "es el `DenseMatrix::inv()` de SymEngine, que usa la eliminación de "
          "Gauss-Jordan sobre los racionales: las entradas vuelven como "
          "fracciones exactas, no como coma flotante.",
      "La matriz identidad es su propia inversa: una comprobación rápida de "
          "que el puente hace el viaje de ida y vuelta correctamente.",
      "Una entrada singular (det = 0) da un error limpio en lugar de "
          "devolver números enormes sin sentido. La etiqueta de error aparece "
          "en el historial de la calculadora.",
    ],
    'transpose': [
      "En CrispCalc, `transpose(M)` está implementado del lado de Dart "
          "porque el puente no expone un punto de entrada de transposición. "
          "Reservamos una nueva `SymEngineMatrix` con dimensiones "
          "intercambiadas y copiamos las celdas una a una.",
      "Entrada rectangular: una 2×3 pasa a ser una 3×2, útil para "
          "disposiciones de datos pareados.",
      "Idempotente tras dos aplicaciones. Verifica que el intercambio de "
          "celdas deja intacto el contenido simbólico.",
    ],
    'rref': [
      "En CrispCalc, `rref` ejecuta Gauss-Jordan en Dart y llama al "
          "`simplify()` de SymEngine en cada actualización de celda. El "
          "puente no expone `rref` directamente, así que el algoritmo recorre "
          "las columnas de izquierda a derecha, escala la fila pivote y luego "
          "elimina la columna por encima y por debajo.",
      "Entrada de rango deficiente: la segunda fila se reduce a todo ceros. "
          "Útil para detectar visualmente la dependencia lineal.",
      "El escalado del pivote normaliza a 1 las entradas principales. La "
          "detección simbólica de valores no nulos es el punto débil: véase "
          "la nota del algoritmo en `matrix_evaluator.dart`.",
    ],
    'matrix_arithmetic': [
      "En CrispCalc, las operaciones binarias con matrices las gestiona el "
          "evaluador de matrices cuando ambos operandos se analizan como "
          "literales `Matrix(...)`. La llamada subyacente es `add_dense_dense` "
          "de SymEngine; la resta pasa por `add_dense_dense` con una negación "
          "elemento a elemento del lado derecho.",
      "La multiplicación es el producto escalar fila por columna habitual "
          "mediante `mul_dense_dense` de SymEngine. La multiplicación por la "
          "derecha por la identidad es una comprobación de funcionamiento.",
      "La resta es elemento a elemento; una discrepancia de dimensiones falla "
          "limpiamente con `Error: matrix - failed: …`.",
    ],
    'mean': [
      "En CrispCalc, `mean` la calcula `DescriptiveStats.mean` (véase "
          "`lib/engine/statistics.dart`): una suma en una pasada / n. Para "
          "datos pareados o agrupados, el módulo de Estadística también ofrece "
          "desviación típica, mediana, cuartiles y el rango intercuartílico.",
      "Entrada en coma flotante: la implementación acumula en `double`, así "
          "que listas muy grandes o de magnitudes mezcladas pueden requerir "
          "un algoritmo de suma estable si necesitas más de 15 dígitos.",
    ],
    'welch_t': [
      "En CrispCalc, `welchT` está en "
          "`lib/engine/hypothesis_tests.dart`. La llamada subyacente calcula "
          "el estadístico t = (x̄_A − x̄_B) / √(s_A²/n_A + s_B²/n_B), luego "
          "aproxima los grados de libertad mediante Welch-Satterthwaite y lee "
          "el valor p en `TDistribution.cdf`.",
      "Caso de muestra diminuta: los gl de Welch ≈ 4 aunque n_A + n_B = 6, "
          "porque la distribución t de dos muestras ajusta la incertidumbre "
          "de la estimación de la varianza.",
    ],
    'paired_t': [
      "En CrispCalc, `pairedT` se reduce a una prueba t de una muestra sobre "
          "el vector de diferencias d = después − antes. La llamada subyacente "
          "es la misma vía `TDistribution.cdf` que usa `welchT`, pero con "
          "gl = n - 1 (sin ajuste de Welch, ya que solo hay una estimación de "
          "la varianza que hacer).",
      "Caso límite: desplazamientos idénticos producen varianza nula en las "
          "diferencias, que la implementación presenta como el valor límite "
          "p = 0 en lugar de un NaN.",
    ],
    'anova_1': [
      "En CrispCalc, `anovaOneWay` descompone la suma de cuadrados total en "
          "la suma de cuadrados entre grupos y dentro de los grupos. La "
          "llamada subyacente es F = MC_entre / MC_dentro con gl1 = K - 1 y "
          "gl2 = N - K, y luego `FDistribution.sf` para el valor p de la cola "
          "superior.",
      "Dispersiones iguales y medias bien separadas producen una F alta. Se "
          "rechaza H₀ (todas las medias iguales) al nivel α = 0,05.",
    ],
    'chi2_goodness': [
      "En CrispCalc, `chiSquareGof` evalúa Σ (O - E)² / E y lee el valor p "
          "de la cola superior en `ChiSquaredDistribution.sf` con gl = k - 1, "
          "donde k es el número de categorías. Se supone que los recuentos de "
          "celda son ≥ 5: la implementación no aplica la corrección de Yates "
          "automáticamente.",
      "Coincidencia perfecta → χ² = 0 → no se rechaza H₀ a ningún nivel α.",
    ],
    'chi2_independence': [
      "En CrispCalc, `chiSquareIndependence` calcula los recuentos esperados "
          "a partir de los marginales de fila × columna (E_ij = fila_i · "
          "columna_j / total), luego Σ (O - E)² / E con "
          "gl = (filas - 1) · (columnas - 1). El valor p subyacente proviene "
          "de `ChiSquaredDistribution.sf`.",
      "Fuerte concentración fuera de la diagonal → valor p bajo. Para tablas "
          "2×2 dispersas, prefiere `fisher_exact`, que no depende de la "
          "aproximación chi-cuadrado para muestras grandes.",
    ],
    'fisher_exact': [
      "En CrispCalc, `fisherExact` enumera todas las tablas 2×2 con los "
          "mismos marginales y suma las probabilidades hipergeométricas de "
          "las tablas al menos tan extremas como la observada. La llamada "
          "subyacente calcula términos log-binomiales para evitar el "
          "desbordamiento con totales grandes, y luego exponencia; el valor p "
          "bilateral sigue la convención de R (suma de probabilidades de cola "
          "≤ la observada).",
      "Tabla simétrica → ninguna evidencia de asociación.",
    ],
    'wilcoxon': [
      "En CrispCalc, `wilcoxonRankSum` une ambas muestras, asigna rangos "
          "corregidos por rangos medios, suma los rangos del grupo A e "
          "informa del z de la aproximación normal. La llamada subyacente "
          "aplica una corrección por empates a la varianza y lee el valor p "
          "bilateral en la función de distribución normal.",
      "Caso de muestra diminuta: la aproximación normal está en el límite con "
          "n_A + n_B = 6. Para muestras muy pequeñas conviene la distribución "
          "de permutación exacta (aún no incluida).",
    ],
    'sign_test': [
      "En CrispCalc, `pairedSign` descarta los pares con diferencia nula, "
          "cuenta los positivos entre los n restantes y contrasta frente a "
          "una Binomial(n, 0,5). El valor p subyacente usa la cola binomial "
          "exacta: sin aproximación normal, por lo que es la opción adecuada "
          "para muestras pareadas muy pequeñas.",
      "Un par empatado (4 → 4) se descarta, dejando n = 3 positivos de 3 "
          "pares informativos. El valor p exacto bilateral es "
          "2 · min(Binom(3, 0,5).cdf(3), …).",
    ],
    'vars': [
      "En CrispCalc, la línea `vars:` la analiza `DslToFlatZinc` (véase "
          "`lib/engine/csp_solver.dart`) y emite una declaración FlatZinc "
          "`var int: x :: …` por nombre. Las cotas del dominio son enteros "
          "concretos; los dominios simbólicos no se admiten.",
      "Un dominio `0..1` modela una variable booleana. FlatZinc tiene un tipo "
          "`var bool` aparte: el analizador no lo detecta, pero el solucionador "
          "trata el entero 0/1 con la misma eficiencia.",
    ],
    'all_different': [
      "En CrispCalc, `allDifferent` se traduce a "
          "`all_different_int([a, b, c])` de FlatZinc. El solucionador "
          "subyacente (dart_csp) implementa la propagación por consistencia de "
          "cotas mediante el algoritmo de emparejamiento de Régin: mucho más "
          "rápido que el modo dos a dos en listas de argumentos grandes.",
      "Las plantillas de Sudoku del módulo Sudoku se construyen sobre pilas "
          "de restricciones `allDifferent`: una por fila, columna, caja y las "
          "zonas de variante que haya.",
    ],
    'no_overlap': [
      "En CrispCalc, `noOverlap` se traduce a "
          "`disjunctive([s1, s2, s3], [4, 3, 2])` de FlatZinc. El "
          "solucionador subyacente usa edge-finding más el propagador θ-tree "
          "de Vilím: el mismo algoritmo que el integrado en MiniZinc.",
      "Problema clásico de secuenciación en una máquina. Combínalo con "
          "`minimize` sobre la expresión del makespan para obtener la "
          "planificación óptima. Véase el ejemplo resuelto para el programa "
          "DSL completo.",
    ],
    'cumulative': [
      "En CrispCalc, `cumulative` se traduce a "
          "`cumulative([starts], [durations], [resources], capacity)` de "
          "FlatZinc. El solucionador subyacente usa propagación por "
          "calendario más razonamiento energético: variantes conscientes de "
          "la capacidad de los propagadores de `noOverlap`.",
      "El problema de planificación de proyectos con recursos limitados "
          "(RCPSP) apila varias restricciones `cumulative`, una por tipo de "
          "recurso. Véase el ejemplo resuelto `dslRcpsp` para un proyecto con "
          "dos recursos.",
    ],
    'minimize': [
      "En CrispCalc, `minimize` emite `solve minimize __obj__;` de FlatZinc "
          "tras construir la variable objetivo mediante el análisis de la "
          "expresión lineal. El solucionador subyacente usa ramificación y "
          "acotación: comprobación de factibilidad y luego ajuste de la cota "
          "superior en cada solución que mejora.",
      "Véase el ejemplo resuelto `dslCoinChange`: minimiza sobre una suma de "
          "variables indicadoras para hallar el menor conjunto de monedas que "
          "suma el objetivo.",
    ],
    'maximize': [
      "En CrispCalc, `maximize` emite `solve maximize __obj__;` de FlatZinc. "
          "El solucionador subyacente hace ramificación y acotación igual que "
          "`minimize`, pero con el ajuste de la cota inferior invertido.",
      "Problema clásico de la mochila 0/1. El DSL lo gestiona de forma "
          "natural como una declaración `vars: x_1, ... in 0..1` más una "
          "restricción de capacidad lineal y un objetivo lineal.",
    ],
    'sudoku_regular': [
      "En CrispCalc, la variante clásica está en `lib/engine/sudoku.dart` "
          "como `SudokuVariant.regular`. El solucionador subyacente instancia "
          "una restricción `allDifferent` por fila, columna y caja (27 en "
          "total para el 9×9) y se las pasa a `dart_csp`.",
    ],
    'sudoku_x': [
      "En CrispCalc, el Sudoku-X es `SudokuVariant.x` "
          "(`lib/engine/sudoku.dart`). El solucionador subyacente añade dos "
          "restricciones `allDifferent` adicionales al trío clásico "
          "fila/columna/caja: una por diagonal.",
    ],
    'sudoku_disjoint': [
      "En CrispCalc, es `SudokuVariant.disjoint`. Para una cuadrícula N×N "
          "con cajas √N × √N, la restricción añade N superposiciones "
          "`allDifferent` más: una por posición dentro de la caja. El 8×8 se "
          "ofrece como una sola plantilla.",
    ],
    'sudoku_killer': [
      "En CrispCalc, es `SudokuVariant.killer`. El solucionador subyacente "
          "superpone al trío clásico fila/columna/caja una restricción "
          "`allDifferent` por jaula y una restricción `suma = objetivo` por "
          "jaula. Se ofrecen las plantillas killer de 4×4 y 9×9.",
    ],
  };

  @override
  String get settingsWorkedExamples => 'Biblioteca de ejemplos resueltos';
  @override
  String get settingsWorkedExamplesSubtitle =>
      'Ahora también accesible mediante el icono de libro en la parte '
      'superior de la Calculadora y el Bloc de notas. Toca aquí para la '
      'biblioteca completa.';
  @override
  String get functionRefTitle => 'Referencia de funciones';
  @override
  String get functionRefSearchHint => 'Buscar funciones…';
  @override
  String get functionRefEmpty => 'Ninguna función coincide con este filtro.';
  @override
  String get functionRefSeeAlso => 'Véase también:';
  @override
  String get functionRefTryInCalculator => 'Probar en la Calculadora';
  @override
  String get functionRefSeeWorkedExample => 'Ver ejemplo resuelto';
  @override
  String get functionRefCatCas => 'CAS';
  @override
  String get functionRefCatNumberTheory => 'Teoría de números';
  @override
  String get functionRefCatPrecision => 'Alta precisión';
  @override
  String get functionRefCatMatrix => 'Matrices';
  @override
  String get functionRefCatGraphing => 'Gráficos';
  @override
  String get functionRefCatStatistics => 'Estadística';
  @override
  String get functionRefCatConstraints => 'Restricciones';
  @override
  String get functionRefCatSudoku => 'Sudoku';
  @override
  String get functionRefCatUnits => 'Unidades';
  @override
  String get settingsFunctionRef => 'Referencia de funciones';
  @override
  String get settingsFunctionRefSubtitle =>
      'Explora cada función de CrispCalc: firma, ejemplos, funciones '
      'relacionadas y un atajo para pegar en la Calculadora.';

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
    // Round 71: the analysis engine sometimes emits
    // "No inflection points (f''(x) = <value> ≠ 0)" — the
    // parenthetical value is dynamic, so a literal map entry
    // can't catch it. Reduce the whole sentence to the
    // translated "no inflection points" before falling through
    // to the literal-replacement table below.
    if (raw.startsWith("No inflection points (f''(x)") ||
        raw.startsWith('No inflection points (f\'\'(x)')) {
      return curveResultNoInflection;
    }
    if (raw.startsWith(
        'Error: Cannot find inflection points without second derivative')) {
      return curveResultNoInflection;
    }
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
