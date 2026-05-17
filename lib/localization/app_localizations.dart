// lib/localization/app_localizations.dart
//
// Centralized i18n. Add a new locale by subclassing AppLocalizations and
// wiring it into the delegate at the bottom. Strings are grouped by feature
// so it's easy to spot what's missing when adding a language.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  // -- Help screen --
  String get helpTitle;
  String get helpFunctionsHeading;
  String get helpMatrixHeading;
  String get helpStepsHeading;
  String get helpMatrixBody;
  String get helpStepsBody;

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
