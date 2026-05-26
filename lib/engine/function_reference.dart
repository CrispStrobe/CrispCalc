// lib/engine/function_reference.dart
//
// Round 96 (P6): Function Reference data model + a small seed
// catalogue. The reference complements the worked-examples library:
// where worked-examples are "concrete problems with paste-ready
// expressions", function-reference entries are "what does THIS
// function do, what's its signature, what does CrispCalc do under
// the hood, and how does it relate to other functions?"
//
// Each entry has:
//
//   - A stable `id` used for i18n keys.
//   - A `category` for filtering.
//   - A canonical `signature` shown in the detail panel (e.g.
//     `solve(equation, variable)`).
//   - A `shortDescription` for the list row (one sentence; richer
//     prose lives in localized strings via
//     `AppLocalizations.functionRefDetail(id)`, to be wired in
//     Round 97 when the entries grow descriptions).
//   - `examples`: 2–3 (input, expected, hint) triples that the
//     dialog can render in the detail panel.
//   - `seeAlso`: ids of related FunctionRef entries (for cross-
//     links inside the dialog).
//   - `workedExampleId`: optional id of a `WorkedExample` to
//     cross-link to. Lets the dialog offer "See worked example" on
//     entries that have a paste-ready problem under the same
//     concept. The widget will look this up in
//     `WorkedExamples.all`; an unknown id degrades to no button.
//
// Round 96 ships the scaffolding + a 3-entry seed list to validate
// the model end-to-end (model → catalogue → dialog → tests).
// Rounds 97-100 fill out the catalogue per PLAN P6.

import 'worked_examples.dart' show WorkedExample;

/// Top-level categories. The values are deliberately broader than
/// the worked-examples categories so they cover both calc-bound
/// functions (cas, numberTheory, precision, matrix) and module
/// surfaces (statistics, constraints, sudoku, graphing, units).
enum FunctionRefCategory {
  cas,
  numberTheory,
  precision,
  matrix,
  graphing,
  statistics,
  constraints,
  sudoku,
  units,
}

/// A concrete example for the detail panel. `expected` is the
/// string CrispCalc returns; `hint` is a one-line interpretive
/// note.
class FunctionRefExample {
  final String input;
  final String expected;
  final String hint;
  const FunctionRefExample({
    required this.input,
    required this.expected,
    required this.hint,
  });
}

class FunctionRef {
  final String id;
  final FunctionRefCategory category;
  final String signature;
  final String shortDescription;
  final List<FunctionRefExample> examples;
  final List<String> seeAlso;

  /// Optional cross-link to a [WorkedExample] id. Wires the
  /// "See worked example" button on the detail panel.
  final String? workedExampleId;

  const FunctionRef({
    required this.id,
    required this.category,
    required this.signature,
    required this.shortDescription,
    this.examples = const [],
    this.seeAlso = const [],
    this.workedExampleId,
  });
}

class FunctionReferences {
  /// V1 seed list. Round 97-100 grow this; the dialog handles the
  /// "empty category" case so adding entries doesn't require
  /// dialog changes.
  static const List<FunctionRef> all = [
    // === CAS =================================================================
    FunctionRef(
      id: 'solve',
      category: FunctionRefCategory.cas,
      signature: 'solve(equation, variable)',
      shortDescription:
          'Symbolically solve an equation for one variable; returns a list of '
          'solutions.',
      examples: [
        FunctionRefExample(
          input: 'solve(x^2 - 1, x)',
          expected: '[-1, 1]',
          hint: 'Polynomial factor — SymEngine\'s `solve_poly` returns both '
              'roots as a list.',
        ),
        FunctionRefExample(
          input: 'solve(2*x + 3 = 0, x)',
          expected: '[-3/2]',
          hint: '`=` on the input is accepted as equation syntax (the '
              'preprocessor normalises to `equation = 0`).',
        ),
      ],
      seeAlso: ['expand', 'factor'],
      workedExampleId: 'quadraticFormula',
    ),
    // === Number theory =======================================================
    FunctionRef(
      id: 'isprime',
      category: FunctionRefCategory.numberTheory,
      signature: 'isprime(n)',
      shortDescription: 'Probabilistic primality test on integers; uses GMP\'s '
          '`mpz_probab_prime_p` when bridging to SymEngine.',
      examples: [
        FunctionRefExample(
          input: 'isprime(2027)',
          expected: 'true',
          hint: '2027 is the 308th prime.',
        ),
        FunctionRefExample(
          input: 'isprime(2024)',
          expected: 'false',
          hint: '2024 = 2³·11·23.',
        ),
      ],
      seeAlso: ['nextprime', 'factorint'],
      workedExampleId: 'isprime',
    ),
    // === Precision arc =======================================================
    FunctionRef(
      id: 'pi_precision',
      category: FunctionRefCategory.precision,
      signature: 'pi(N)',
      shortDescription:
          'Compute π to N decimal digits via MPFR; returns the literal '
          'digit string.',
      examples: [
        FunctionRefExample(
          input: 'pi(50)',
          expected: '3.14159265358979323846264338327950288419716939937510',
          hint: 'MPFR precision is set to ⌈N·log2(10)⌉ + 16 guard bits '
              'before the constant is requested.',
        ),
      ],
      seeAlso: ['e_precision', 'sqrt_precision'],
      workedExampleId: 'piPrecision',
    ),
  ];
}
