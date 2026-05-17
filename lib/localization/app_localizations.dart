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

  // -- Picker dialogs --
  String get selectEquation;
  String get continueTyping;
  String get selectFunction;
  String get dismissPanel;
  String solveFor(int n);
  String whereY(int n, String func);

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

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(locale.languageCode == 'de'
        ? const DeLocalizations()
        : const EnLocalizations());
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
