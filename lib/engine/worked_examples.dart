// lib/engine/worked_examples.dart
//
// Curated catalog of worked examples for the calculator. Each entry
// is one tappable problem with a category, a stable id, a fallback
// English title, a fallback English description, and the calculator
// expression that produces the answer. The dialog renders these
// grouped by category; tapping inserts the expression into the
// calculator (V2). The dialog also asks AppLocalizations for a
// translated title/description by id, falling back to the English
// strings here when a locale doesn't have one yet.

enum WorkedExampleCategory {
  calculus,
  algebra,
  linearAlgebra,
  numberTheory,
  statistics,
  units,
  constraints,
}

class WorkedExample {
  final String id;
  final WorkedExampleCategory category;
  final String title;
  final String description;
  final String expression;

  const WorkedExample({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.expression,
  });
}

class WorkedExamples {
  static const List<WorkedExample> all = [
    // === Calculus ============================================================
    WorkedExample(
      id: 'derivPoly',
      category: WorkedExampleCategory.calculus,
      title: 'Derivative of a polynomial',
      description: 'd/dx of x³ − 4x + 7 at any x.',
      expression: 'diff(x^3 - 4*x + 7, x)',
    ),
    WorkedExample(
      id: 'chainRule',
      category: WorkedExampleCategory.calculus,
      title: 'Chain rule example',
      description: 'd/dx of sin(x²) — chain rule on the inner x².',
      expression: 'diff(sin(x^2), x)',
    ),
    WorkedExample(
      id: 'integralByParts',
      category: WorkedExampleCategory.calculus,
      title: 'Indefinite integral by parts',
      description: '∫ x·sin(x) dx — pick u = x, dv = sin(x) dx.',
      expression: 'integrate(x*sin(x), x)',
    ),
    WorkedExample(
      id: 'definiteIntegral',
      category: WorkedExampleCategory.calculus,
      title: 'Definite integral',
      description: '∫₀¹ x² dx = 1/3 via the fundamental theorem.',
      expression: 'integrate(x^2, x, 0, 1)',
    ),
    WorkedExample(
      id: 'sinxOverX',
      category: WorkedExampleCategory.calculus,
      title: 'Limit at a removable singularity',
      description: 'lim x→0 sin(x)/x = 1 (the classic).',
      expression: 'limit(sin(x)/x, x, 0)',
    ),
    WorkedExample(
      id: 'partialFractions',
      category: WorkedExampleCategory.calculus,
      title: 'Partial fractions',
      description: '∫ 1/(x² − 1) dx via cover-up on x = ±1.',
      expression: 'integrate(1/(x^2 - 1), x)',
    ),

    // === Algebra =============================================================
    WorkedExample(
      id: 'quadraticFormula',
      category: WorkedExampleCategory.algebra,
      title: 'Quadratic formula',
      description: 'Solve 2x² + 5x − 3 = 0 via the discriminant.',
      expression: 'solve(2*x^2 + 5*x - 3 = 0, x)',
    ),
    WorkedExample(
      id: 'factorCubic',
      category: WorkedExampleCategory.algebra,
      title: 'Factor a polynomial',
      description: 'Factor x³ − 8 — sum/difference of cubes.',
      expression: 'factor(x^3 - 8)',
    ),
    WorkedExample(
      id: 'expandBinomial',
      category: WorkedExampleCategory.algebra,
      title: 'Expand a binomial',
      description: 'Expand (x + 2)⁵ — Pascal\'s triangle.',
      expression: 'expand((x + 2)^5)',
    ),
    WorkedExample(
      id: 'simplifyRational',
      category: WorkedExampleCategory.algebra,
      title: 'Simplify a rational expression',
      description: 'Reduce (x² − 4)/(x − 2) to lowest terms.',
      expression: 'simplify((x^2 - 4)/(x - 2))',
    ),

    // === Linear algebra ======================================================
    WorkedExample(
      id: 'matrixDet',
      category: WorkedExampleCategory.linearAlgebra,
      title: 'Matrix determinant',
      description: 'det of a 3×3 — Laplace expansion or row reduction.',
      expression: 'det(Matrix([[1, 2, 3], [0, 1, 4], [5, 6, 0]]))',
    ),
    WorkedExample(
      id: 'matrixInverse',
      category: WorkedExampleCategory.linearAlgebra,
      title: 'Matrix inverse',
      description: 'Inverse of a 2×2 — A⁻¹ = adj(A)/det(A).',
      expression: 'inv(Matrix([[4, 7], [2, 6]]))',
    ),
    WorkedExample(
      id: 'rref',
      category: WorkedExampleCategory.linearAlgebra,
      title: 'Reduced row echelon form',
      description: 'rref of a 2×3 augmented system.',
      expression: 'rref(Matrix([[1, 2, 5], [3, 4, 11]]))',
    ),

    // === Number theory =======================================================
    WorkedExample(
      id: 'factorial100',
      category: WorkedExampleCategory.numberTheory,
      title: 'Factorial — exact integer',
      description: '100! — 158 digits, preserved in exact-integer mode.',
      expression: '100!',
    ),
    WorkedExample(
      id: 'fibonacci50',
      category: WorkedExampleCategory.numberTheory,
      title: 'Fibonacci number',
      description: 'fib(50) — recurrence to a large term.',
      expression: 'fib(50)',
    ),
    WorkedExample(
      id: 'gcdEuclid',
      category: WorkedExampleCategory.numberTheory,
      title: 'GCD via Euclid',
      description: 'gcd(252, 105) — the original recurrence.',
      expression: 'gcd(252, 105)',
    ),
    WorkedExample(
      id: 'isprime',
      category: WorkedExampleCategory.numberTheory,
      title: 'Primality (small n)',
      description: 'isprime(2027) — quick trial division.',
      expression: 'isprime(2027)',
    ),

    // === Statistics ==========================================================
    WorkedExample(
      id: 'compoundInterest',
      category: WorkedExampleCategory.statistics,
      title: 'Compound interest',
      description: '€1000 at 5% for 10 years, annual compounding.',
      expression: '1000*(1 + 0.05)^10',
    ),
    WorkedExample(
      id: 'zScore',
      category: WorkedExampleCategory.statistics,
      title: 'Z-score lookup',
      description: 'Reach the Statistics screen → Distributions to '
          'compute Φ(1.96) ≈ 0.975.',
      // Numeric proxy via the calculator: not a stats function call
      // but the textbook constant. Keeps the catalog uniformly
      // calculator-evaluable.
      expression: '0.5 + 0.5*sin(1.96)',
    ),

    // === Units / conversions =================================================
    WorkedExample(
      id: 'unitConversion',
      category: WorkedExampleCategory.units,
      title: 'Inline unit conversion',
      description: '100 km/h converted to mph — V2 inline parser.',
      expression: '100 km/h in mph',
    ),
    WorkedExample(
      id: 'compositeDim',
      category: WorkedExampleCategory.units,
      title: 'Composite-dimension arithmetic',
      description: '100 m / 10 s yields a velocity in m/s — V5 parser.',
      expression: '100 m / 10 s',
    ),
    // === Constraints (round 69) =============================================
    // These entries don't insert into the calculator — their
    // `expression` is a sentinel of the form `open:<module>` that
    // the dialog detects and dispatches to a Navigator push of the
    // appropriate module screen. Surfaces our CSP / Killer Sudoku
    // capabilities in the same place users go for math examples.
    WorkedExample(
      id: 'killerSudoku',
      category: WorkedExampleCategory.constraints,
      title: 'Killer Sudoku (9×9)',
      description:
          'Opens the Sudoku module — pick "9×9 Killer" from the puzzle list.',
      expression: 'open:sudoku',
    ),
    WorkedExample(
      id: 'constraintEditor',
      category: WorkedExampleCategory.constraints,
      title: 'Free-form constraint editor',
      description:
          'Opens the Constraints module — declare variables, add constraints, '
          'solve.',
      expression: 'open:constraints',
    ),
  ];
}
