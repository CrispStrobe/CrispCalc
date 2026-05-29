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
    // Group B (precision arc): polynomial arithmetic over ℚ.
    WorkedExample(
      id: 'polyGcdShared',
      category: WorkedExampleCategory.algebra,
      title: 'Polynomial GCD',
      description: 'polygcd(x² − 1, x² − 2x + 1) — the shared factor x − 1.',
      expression: 'polygcd(x^2 - 1, x^2 - 2x + 1)',
    ),
    WorkedExample(
      id: 'polyDiscriminantCubic',
      category: WorkedExampleCategory.algebra,
      title: 'Polynomial discriminant',
      description: 'polydiscriminant(x³ − 2) — non-zero ⇒ distinct roots.',
      expression: 'polydiscriminant(x^3 - 2)',
    ),
    WorkedExample(
      id: 'polyFactorMod',
      category: WorkedExampleCategory.algebra,
      title: 'Factor mod p',
      description: 'polyfactor(x⁴ + 1, mod=2) — irreducible over ℚ, '
          '(x + 1)⁴ over 𝔽₂.',
      expression: 'polyfactor(x^4 + 1, mod=2)',
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
    // Round 92 (P6): precision-arc + ntheory surfacing. All five
    // route through CalculatorEngine.tryEvaluatePrecisionCall and
    // produce results without touching SymEngine.
    WorkedExample(
      id: 'piPrecision',
      category: WorkedExampleCategory.numberTheory,
      title: 'π to 100 digits',
      description: 'pi(100) — MPFR-backed high-precision constant.',
      expression: 'pi(100)',
    ),
    WorkedExample(
      id: 'ePrecision',
      category: WorkedExampleCategory.numberTheory,
      title: 'e to 50 digits',
      description: 'e(50) — same MPFR pipeline as pi(N).',
      expression: 'e(50)',
    ),
    WorkedExample(
      id: 'factorint360',
      category: WorkedExampleCategory.numberTheory,
      title: 'Prime factorization',
      description: 'factorint(360) → 2³ · 3² · 5 with Unicode superscripts.',
      expression: 'factorint(360)',
    ),
    WorkedExample(
      id: 'nextprime1000',
      category: WorkedExampleCategory.numberTheory,
      title: 'Next prime after 1000',
      description: 'nextprime(1000) — FLINT-backed via SymEngine ntheory.',
      expression: 'nextprime(1000)',
    ),
    WorkedExample(
      id: 'mersenneM31',
      category: WorkedExampleCategory.numberTheory,
      title: 'Mersenne M31',
      description: 'factorint(2^31 - 1) — confirms the eighth Mersenne '
          'prime as a single factor.',
      expression: 'factorint(2147483647)',
    ),
    // Round 4 (precision arc): modular arithmetic + multiplicative
    // number theory. All route through tryEvaluatePrecisionCall.
    WorkedExample(
      id: 'divisors12',
      category: WorkedExampleCategory.numberTheory,
      title: 'All divisors',
      description: 'divisors(12) → 1, 2, 3, 4, 6, 12 — derived from '
          'factorint.',
      expression: 'divisors(12)',
    ),
    WorkedExample(
      id: 'eulerTotient',
      category: WorkedExampleCategory.numberTheory,
      title: "Euler's totient",
      description: 'totient(36) — count of residues coprime to 36.',
      expression: 'totient(36)',
    ),
    WorkedExample(
      id: 'modpowCrypto',
      category: WorkedExampleCategory.numberTheory,
      title: 'Modular exponentiation',
      description: 'modpow(2, 100, 1000000007) — the heart of RSA / '
          'Diffie–Hellman.',
      expression: 'modpow(2, 100, 1000000007)',
    ),
    WorkedExample(
      id: 'contFracPi',
      category: WorkedExampleCategory.numberTheory,
      title: 'Continued fraction of π',
      description: 'cfrac(pi, 10) — the [3; 7, 15, 1, 292, …] expansion '
          'behind 355/113.',
      expression: 'cfrac(pi, 10)',
    ),

    // === P7 Booleans (Round 112) ============================================
    // Surfaces the relational + logical operator rewrite shipped in
    // rounds 110 + 111. Each evaluates to a colored chip in the
    // history. Folded into number-theory so the boolean entries sit
    // next to isprime / nextprime / factorint without bloating the
    // category-chip row.
    WorkedExample(
      id: 'booleanIsprimeAnd',
      category: WorkedExampleCategory.numberTheory,
      title: 'Prime and bounded',
      description: 'isprime(17) and 17 < 20 — both clauses true, '
          'so the conjunction is true.',
      expression: 'isprime(17) and 17 < 20',
    ),
    WorkedExample(
      id: 'booleanEqualityFold',
      category: WorkedExampleCategory.numberTheory,
      title: 'Equality fold',
      description: '2 == 2 — constant operands collapse to true.',
      expression: '2 == 2',
    ),
    WorkedExample(
      id: 'booleanNotPrime',
      category: WorkedExampleCategory.numberTheory,
      title: 'Negation',
      description: 'not isprime(15) — 15 = 3·5, so the result is true.',
      expression: 'not isprime(15)',
    ),
    WorkedExample(
      id: 'booleanOrChain',
      category: WorkedExampleCategory.numberTheory,
      title: 'Disjunction across comparisons',
      description: '(5 > 3) or (1 == 2) — the first clause is true so the '
          'whole disjunction is true.',
      expression: '(5 > 3) or (1 == 2)',
    ),
    WorkedExample(
      id: 'booleanIfFold',
      category: WorkedExampleCategory.numberTheory,
      title: 'Conditional fold',
      description: 'if(isprime(7), 100, 200) — condition folds to true so '
          'the then-branch wins.',
      expression: 'if(isprime(7), 100, 200)',
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
    // Round 95: `open:statistics?tab=tests` lands the user on the
    // Tests tab pre-selected so they can see the t-test / ANOVA /
    // chi-square / Wilcoxon scaffolding without hunting for it.
    // Default sample data is already populated by the controllers.
    WorkedExample(
      id: 'statsHypothesisTests',
      category: WorkedExampleCategory.statistics,
      title: 'Hypothesis tests workspace',
      description:
          'Opens the Statistics module on the Tests tab — one-sample t, '
          'two-sample t (Welch), paired t, ANOVA, chi-square, and '
          'Wilcoxon — with default sample data pre-filled.',
      expression: 'open:statistics?tab=tests',
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
    // Round 95: `open:sudoku?preset=<id>` pre-loads the named puzzle
    // (id matches `SudokuPresets.all`) so the user lands on the
    // puzzle without going through the dropdown.
    WorkedExample(
      id: 'killerSudoku',
      category: WorkedExampleCategory.constraints,
      title: 'Killer Sudoku (9×9)',
      description:
          'Opens the Sudoku module pre-loaded with the 9×9 Killer preset.',
      expression: 'open:sudoku?preset=killer9x9',
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
    // Round 73: `dsl:<id>` sentinels open the Constraints module
    // AND pre-load a specific DSL program from the gallery. The id
    // after `dsl:` matches the gallery's id in _DslTabState, which
    // owns the actual program text.
    WorkedExample(
      id: 'dslMagicSquare',
      category: WorkedExampleCategory.constraints,
      title: '3×3 magic square (DSL)',
      description:
          'Loads the 9-variable magic-square program into the DSL editor.',
      expression: 'dsl:magicSquare3',
    ),
    WorkedExample(
      id: 'dslMapColoring',
      category: WorkedExampleCategory.constraints,
      title: 'Map coloring K4 (DSL)',
      description:
          'Loads a K4 graph coloring with 3 colors — intentionally infeasible '
          'so you can see the "no solutions" path.',
      expression: 'dsl:mapColoring',
    ),
    WorkedExample(
      id: 'dslOrderedTriples',
      category: WorkedExampleCategory.constraints,
      title: 'Ordered triples summing to 20 (DSL)',
      description:
          'Loads a DSL program enumerating (a, b, c) with a < b < c and '
          'a + b + c = 20.',
      expression: 'dsl:orderedTriples',
    ),
    // Round 79: surface the optimization gallery entries shipped
    // in rounds 74 (coin-change) and 77 (scheduling makespan) via
    // the worked-examples discovery library, mirroring the round-73
    // pattern.
    WorkedExample(
      id: 'dslCoinChange',
      category: WorkedExampleCategory.constraints,
      title: 'Coin change — minimize coins (DSL)',
      description:
          'Loads a DSL program that pays 17¢ with the fewest coins drawn '
          'from {1, 5, 10, 25} via `minimize`.',
      expression: 'dsl:coinChangeMin',
    ),
    WorkedExample(
      id: 'dslSchedulingMakespan',
      category: WorkedExampleCategory.constraints,
      title: 'Single-machine scheduling — minimize makespan (DSL)',
      description:
          'Loads a DSL program that schedules three tasks (durations 4/3/2) '
          'on one machine via `noOverlap` and minimizes the makespan.',
      expression: 'dsl:schedulingMakespan',
    ),
    // Round 80: cumulative (renewable-resource) scheduling — sibling
    // to the round-77 noOverlap entry but on a capacity-2 resource so
    // tasks with low demand can run in parallel.
    WorkedExample(
      id: 'dslCumulativeScheduling',
      category: WorkedExampleCategory.constraints,
      title: 'Parallel-resource scheduling — cumulative (DSL)',
      description:
          'Loads a DSL program that schedules three tasks on a capacity-2 '
          'resource via `cumulative` and minimizes the makespan.',
      expression: 'dsl:cumulativeScheduling',
    ),
    // Round 84: classical RCPSP — multiple parallel cumulative
    // overlays representing distinct resource types.
    WorkedExample(
      id: 'dslRcpsp',
      category: WorkedExampleCategory.constraints,
      title: 'Project scheduling RCPSP — two resources (DSL)',
      description:
          'Loads a DSL program with two parallel `cumulative` overlays '
          '(crew + equipment, each capacity 3) over four tasks; minimizes '
          'the makespan.',
      expression: 'dsl:rcpsp',
    ),
  ];
}
