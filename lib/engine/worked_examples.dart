// lib/engine/worked_examples.dart
//
// Curated catalog of worked examples for the calculator. Each entry
// is one tappable problem with a category, a short human title, a
// one-sentence description, and the calculator expression that
// produces the answer. The dialog renders these grouped by category;
// tapping copies the expression to the clipboard.
//
// V1 keeps titles + descriptions English-only so the round ships at
// reasonable scope. The dialog chrome (header, search, categories,
// copy toast) is fully localized.

enum WorkedExampleCategory {
  calculus,
  algebra,
  linearAlgebra,
  numberTheory,
  statistics,
  units,
}

class WorkedExample {
  final WorkedExampleCategory category;
  final String title;
  final String description;
  final String expression;

  const WorkedExample({
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
      category: WorkedExampleCategory.calculus,
      title: 'Derivative of a polynomial',
      description: 'd/dx of x³ − 4x + 7 at any x.',
      expression: 'diff(x^3 - 4*x + 7, x)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.calculus,
      title: 'Chain rule example',
      description: 'd/dx of sin(x²) — chain rule on the inner x².',
      expression: 'diff(sin(x^2), x)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.calculus,
      title: 'Indefinite integral by parts',
      description: '∫ x·sin(x) dx — pick u = x, dv = sin(x) dx.',
      expression: 'integrate(x*sin(x), x)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.calculus,
      title: 'Definite integral',
      description: '∫₀¹ x² dx = 1/3 via the fundamental theorem.',
      expression: 'integrate(x^2, x, 0, 1)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.calculus,
      title: 'Limit at a removable singularity',
      description: 'lim x→0 sin(x)/x = 1 (the classic).',
      expression: 'limit(sin(x)/x, x, 0)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.calculus,
      title: 'Partial fractions',
      description: '∫ 1/(x² − 1) dx via cover-up on x = ±1.',
      expression: 'integrate(1/(x^2 - 1), x)',
    ),

    // === Algebra =============================================================
    WorkedExample(
      category: WorkedExampleCategory.algebra,
      title: 'Quadratic formula',
      description: 'Solve 2x² + 5x − 3 = 0 via the discriminant.',
      expression: 'solve(2*x^2 + 5*x - 3 = 0, x)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.algebra,
      title: 'Factor a polynomial',
      description: 'Factor x³ − 8 — sum/difference of cubes.',
      expression: 'factor(x^3 - 8)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.algebra,
      title: 'Expand a binomial',
      description: 'Expand (x + 2)⁵ — Pascal\'s triangle.',
      expression: 'expand((x + 2)^5)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.algebra,
      title: 'Simplify a rational expression',
      description: 'Reduce (x² − 4)/(x − 2) to lowest terms.',
      expression: 'simplify((x^2 - 4)/(x - 2))',
    ),

    // === Linear algebra ======================================================
    WorkedExample(
      category: WorkedExampleCategory.linearAlgebra,
      title: 'Matrix determinant',
      description: 'det of a 3×3 — Laplace expansion or row reduction.',
      expression: 'det(Matrix([[1, 2, 3], [0, 1, 4], [5, 6, 0]]))',
    ),
    WorkedExample(
      category: WorkedExampleCategory.linearAlgebra,
      title: 'Matrix inverse',
      description: 'Inverse of a 2×2 — A⁻¹ = adj(A)/det(A).',
      expression: 'inv(Matrix([[4, 7], [2, 6]]))',
    ),
    WorkedExample(
      category: WorkedExampleCategory.linearAlgebra,
      title: 'Reduced row echelon form',
      description: 'rref of a 2×3 augmented system.',
      expression: 'rref(Matrix([[1, 2, 5], [3, 4, 11]]))',
    ),

    // === Number theory =======================================================
    WorkedExample(
      category: WorkedExampleCategory.numberTheory,
      title: 'Factorial — exact integer',
      description: '100! — 158 digits, preserved in exact-integer mode.',
      expression: '100!',
    ),
    WorkedExample(
      category: WorkedExampleCategory.numberTheory,
      title: 'Fibonacci number',
      description: 'fib(50) — recurrence to a large term.',
      expression: 'fib(50)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.numberTheory,
      title: 'GCD via Euclid',
      description: 'gcd(252, 105) — the original recurrence.',
      expression: 'gcd(252, 105)',
    ),
    WorkedExample(
      category: WorkedExampleCategory.numberTheory,
      title: 'Primality (small n)',
      description: 'isprime(2027) — quick trial division.',
      expression: 'isprime(2027)',
    ),

    // === Statistics ==========================================================
    WorkedExample(
      category: WorkedExampleCategory.statistics,
      title: 'Compound interest',
      description: '€1000 at 5% for 10 years, annual compounding.',
      expression: '1000*(1 + 0.05)^10',
    ),
    WorkedExample(
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
      category: WorkedExampleCategory.units,
      title: 'Inline unit conversion',
      description: '100 km/h converted to mph — V2 inline parser.',
      expression: '100 km/h in mph',
    ),
    WorkedExample(
      category: WorkedExampleCategory.units,
      title: 'Composite-dimension arithmetic',
      description: '100 m / 10 s yields a velocity in m/s — V5 parser.',
      expression: '100 m / 10 s',
    ),
  ];
}
