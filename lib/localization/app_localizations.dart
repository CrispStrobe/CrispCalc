/// lib/localization/app_localizations.dart
/// Contains all logic for internationalization (i18n), providing
/// translated strings for the application in a centralized place.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? const EnLocalizations();
  }

  String get selectEquation;
  String get continueTyping;
  String get selectFunction;
  String get dismissPanel;
  String solveFor(int n);
  String whereY(int n, String func);
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
  String get tabNum;
  String get tabTrig;
  String get tabCas;
  String get tabAdvanced;
  String get tabVars; // Formerly "Mem"
}

// --- English Localizations ---
class EnLocalizations implements AppLocalizations {
  const EnLocalizations();
  
  @override
  String get selectEquation => 'Select equation or continue typing:';
  @override
  String get continueTyping => 'Continue Typing';
  @override
  String get selectFunction => 'Select function or continue typing:';
  @override
  String get dismissPanel => 'Dismiss this panel';
  @override
  String solveFor(int n) => 'Solve F$n = 0';
  @override
  String whereY(int n, String func) => 'where F$n = $func';
  @override
  String get errorSolveFormat => 'Error: solve() format is solve(equation, variable)';
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
}

// --- German Localizations ---
class DeLocalizations implements AppLocalizations {
  const DeLocalizations();

  @override
  String get selectEquation => 'Gleichung auswählen oder weiter tippen:';
  @override
  String get continueTyping => 'Weiter tippen';
  @override
  String get selectFunction => 'Funktion auswählen oder weiter tippen:';
  @override
  String get dismissPanel => 'Dieses Panel schließen';
  @override
  String solveFor(int n) => 'Löse F$n = 0';
  @override
  String whereY(int n, String func) => 'wobei F$n = $func';
  @override
  String get errorSolveFormat => 'Fehler: solve()-Format ist solve(Gleichung, Variable)';
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
}

/// The delegate that Flutter's localization system uses to load the correct language.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    // This is a synchronous operation, so we can wrap it in a SynchronousFuture.
    return SynchronousFuture<AppLocalizations>(
        locale.languageCode == 'de' ? const DeLocalizations() : const EnLocalizations());
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}