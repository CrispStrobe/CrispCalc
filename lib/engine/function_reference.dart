// lib/engine/function_reference.dart
//
// P6 Function Reference data model + catalogue.
//
// Each entry has:
//
//   - A stable `id` used for i18n keys.
//   - A `category` for filtering.
//   - A canonical `signature` shown in the detail panel (e.g.
//     `solve(equation, variable)`).
//   - A `shortDescription` for the list row (one sentence).
//   - `examples`: 2–3 (input, expected, hint) triples that the
//     dialog can render in the detail panel. The first example's
//     `hint` doubles as the "in CrispCalc, X returns Y; the
//     underlying call is SymEngine's / MPFR's / FLINT's Z" prose
//     that PLAN P6 §97 asks for.
//   - `seeAlso`: ids of related FunctionRef entries (for cross-
//     links inside the dialog).
//   - `workedExampleId`: optional id of a `WorkedExample` to
//     cross-link to. Lets the dialog offer "See worked example" on
//     entries that have a paste-ready problem under the same
//     concept. The widget will look this up in
//     `WorkedExamples.all`; an unknown id degrades to no button.
//
// Round 96 shipped the scaffolding + 3 seed entries. Round 97
// fills out CAS (`expand` / `simplify` / `factor` / `diff` /
// `integrate` / `subst` / `limit` / `gcd` / `lcm` / `factorial` /
// `fibonacci`) and grows the precision arc to cover `e(N)`,
// `sqrt(2, N)`, `EulerGamma(N)`, `factorint`, `nextprime`,
// `prevprime`. PLAN names `series` / `taylor` too — those aren't
// in the bridge yet (no SymEngine `series_expansion` binding),
// so they're deferred. Round 98 fills the matrix category:
// `Matrix(...)` literal syntax, `det`, `inv`, `transpose`,
// `rref`, plus a combined matrix-arithmetic entry. Eigenvalues
// are NOT shipped (PLAN's "if shipped" carve-out) and are
// deferred until a bridge binding exists. Round 99 grows stats /
// constraints categories.

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
  /// V1 catalogue. Rounds 98-99 grow matrix / statistics /
  /// constraints categories — the dialog handles the "empty
  /// category" case so adding entries doesn't require dialog
  /// changes.
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
          hint: 'In CrispCalc, `solve(x^2 - 1, x)` returns a Python-style list '
              'of roots. The underlying call is SymEngine\'s `solve()` (the '
              'rational-root branch for polynomials), wrapped by the bridge '
              'and serialised back to a Dart string.',
        ),
        FunctionRefExample(
          input: 'solve(2*x + 3 = 0, x)',
          expected: '[-3/2]',
          hint: '`=` on the input is accepted as equation syntax — the '
              'preprocessor normalises `lhs = rhs` to `lhs - rhs` before the '
              'bridge call.',
        ),
        FunctionRefExample(
          input: 'solve(x^2 + 1, x)',
          expected: '[-I, I]',
          hint: 'Complex roots come back as SymEngine\'s `I` literal. Mix into '
              'further calls (e.g. `expand((-I)*(I))`) and the bridge keeps '
              'them symbolic.',
        ),
      ],
      seeAlso: ['expand', 'factor', 'simplify'],
      workedExampleId: 'quadraticFormula',
    ),
    FunctionRef(
      id: 'expand',
      category: FunctionRefCategory.cas,
      signature: 'expand(expression)',
      shortDescription:
          'Distribute products and powers into a sum-of-monomials form.',
      examples: [
        FunctionRefExample(
          input: 'expand((x + 1)^2)',
          expected: 'x^2 + 2*x + 1',
          hint: 'In CrispCalc, `expand((x + 1)^2)` returns the binomial '
              'expansion. The underlying call is SymEngine\'s `expand()`, '
              'which flattens `Pow` and `Mul` nodes and collects like terms.',
        ),
        FunctionRefExample(
          input: 'expand((x + 2)^5)',
          expected: 'x^5 + 10*x^4 + 40*x^3 + 80*x^2 + 80*x + 32',
          hint: 'Coefficients match Pascal\'s triangle row 5: 1, 5, 10, 10, '
              '5, 1, each multiplied by the appropriate power of 2.',
        ),
        FunctionRefExample(
          input: 'expand((a + b)*(a - b))',
          expected: 'a^2 - b^2',
          hint: 'The classic difference-of-squares identity — useful when '
              'pairing with `factor` to cycle between forms.',
        ),
      ],
      seeAlso: ['simplify', 'factor', 'solve'],
      workedExampleId: 'expandBinomial',
    ),
    FunctionRef(
      id: 'simplify',
      category: FunctionRefCategory.cas,
      signature: 'simplify(expression)',
      shortDescription:
          'Combine like terms, cancel common factors, and apply standard '
          'algebraic identities.',
      examples: [
        FunctionRefExample(
          input: 'simplify((x^2 - 4)/(x - 2))',
          expected: 'x + 2',
          hint: 'In CrispCalc, `simplify` cancels the common `(x - 2)` factor. '
              'The underlying call is SymEngine\'s `simplify()`, which '
              'tries `rational_simplify` plus a small bag of rewrite rules.',
        ),
        FunctionRefExample(
          input: 'simplify(x*x + 2*x^2)',
          expected: '3*x^2',
          hint: 'Like-term collection on polynomial input — internally this is '
              'just `expand` followed by coefficient merge.',
        ),
        FunctionRefExample(
          input: 'simplify(sin(x)^2 + cos(x)^2)',
          expected: '1',
          hint: 'Pythagorean identity; SymEngine applies the trig rewrite rule '
              'before returning the literal `1`.',
        ),
      ],
      seeAlso: ['expand', 'factor', 'subst'],
      workedExampleId: 'simplifyRational',
    ),
    FunctionRef(
      id: 'factor',
      category: FunctionRefCategory.cas,
      signature: 'factor(expression)',
      shortDescription:
          'Factor a polynomial over the rationals into irreducible pieces.',
      examples: [
        FunctionRefExample(
          input: 'factor(x^2 - 1)',
          expected: '(x - 1)*(x + 1)',
          hint: 'In CrispCalc, `factor(x^2 - 1)` returns the difference-of-'
              'squares factorisation. The underlying call is SymEngine\'s '
              '`factor()`, which uses Berlekamp / Cantor–Zassenhaus for '
              'univariate polynomials over Q.',
        ),
        FunctionRefExample(
          input: 'factor(x^3 - 8)',
          expected: '(x - 2)*(x^2 + 2*x + 4)',
          hint: 'Sum/difference-of-cubes identity: one linear factor times an '
              'irreducible quadratic over Q.',
        ),
        FunctionRefExample(
          input: 'factor(x^4 - 1)',
          expected: '(x - 1)*(x + 1)*(x^2 + 1)',
          hint: 'Factoring stops at irreducibility over Q — `x^2 + 1` does '
              'not split further without admitting complex roots.',
        ),
      ],
      seeAlso: ['expand', 'solve', 'gcd'],
      workedExampleId: 'factorCubic',
    ),
    FunctionRef(
      id: 'diff',
      category: FunctionRefCategory.cas,
      signature: 'diff(expression, variable)',
      shortDescription:
          'First-order symbolic derivative with respect to one variable.',
      examples: [
        FunctionRefExample(
          input: 'diff(x^3 - 4*x + 7, x)',
          expected: '3*x^2 - 4',
          hint: 'In CrispCalc, `diff(...)` applies the power and constant '
              'rules term-by-term. The underlying call is SymEngine\'s '
              '`diff()`, which walks the expression tree and emits a new '
              'symbolic `Add` node.',
        ),
        FunctionRefExample(
          input: 'diff(sin(x^2), x)',
          expected: '2*x*cos(x^2)',
          hint: 'Chain rule: SymEngine applies `diff(sin(u))/du * du/dx` for '
              'the inner `u = x^2`.',
        ),
        FunctionRefExample(
          input: 'diff(exp(x)*x, x)',
          expected: 'x*exp(x) + exp(x)',
          hint: 'Product rule — note SymEngine keeps the result unfactored. '
              'Pipe through `factor` to collect `exp(x)`.',
        ),
      ],
      seeAlso: ['integrate', 'limit', 'subst'],
      workedExampleId: 'derivPoly',
    ),
    FunctionRef(
      id: 'integrate',
      category: FunctionRefCategory.cas,
      signature: 'integrate(expression, variable[, lower, upper])',
      shortDescription:
          'Indefinite integral (3 args) or definite integral (5 args) with '
          'numeric fallback.',
      examples: [
        FunctionRefExample(
          input: 'integrate(x*sin(x), x)',
          expected: 'sin(x) - x*cos(x)',
          hint: 'In CrispCalc, indefinite `integrate(...)` delegates to '
              'SymEngine\'s `integrate()`. Integration by parts is applied '
              'automatically when one factor differentiates to a polynomial.',
        ),
        FunctionRefExample(
          input: 'integrate(x^2, x, 0, 1)',
          expected: '1/3',
          hint:
              'Definite form: when SymEngine has a closed-form antiderivative '
              'it applies the fundamental theorem. If symbolic fails, '
              'CrispCalc falls back to Simpson\'s rule (200 panels).',
        ),
        FunctionRefExample(
          input: 'integrate(1/(x^2 - 1), x)',
          expected: '-log(x + 1)/2 + log(x - 1)/2',
          hint: 'Partial fractions: 1/(x²-1) = 1/(2(x-1)) - 1/(2(x+1)). '
              'SymEngine handles the cover-up automatically.',
        ),
      ],
      seeAlso: ['diff', 'limit', 'subst'],
      workedExampleId: 'integralByParts',
    ),
    FunctionRef(
      id: 'subst',
      category: FunctionRefCategory.cas,
      signature: 'subst(expression, variable, value)',
      shortDescription:
          'Substitute `value` for every free occurrence of `variable` in '
          '`expression`. Also exposed as `substitute(...)`.',
      examples: [
        FunctionRefExample(
          input: 'subst(x^2 + 1, x, 2)',
          expected: '5',
          hint: 'In CrispCalc, `subst` rewrites the expression tree and then '
              'tries one simplify pass. The underlying call is SymEngine\'s '
              '`xreplace()` (variable-only replacement, not pattern matching).',
        ),
        FunctionRefExample(
          input: 'subst(sin(x), x, pi/2)',
          expected: '1',
          hint: 'Numeric constants `pi`, `e`, and the imaginary unit `I` are '
              'recognised by SymEngine and folded through the trig identity.',
        ),
        FunctionRefExample(
          input: 'subst(a*x + b, x, 10)',
          expected: '10*a + b',
          hint: 'Substitution is symbolic — unrelated free variables `a` and '
              '`b` survive untouched.',
        ),
      ],
      seeAlso: ['solve', 'simplify', 'diff'],
    ),
    FunctionRef(
      id: 'limit',
      category: FunctionRefCategory.cas,
      signature: 'limit(expression, variable, point)',
      shortDescription:
          'Numerical limit as `variable` approaches `point`. `point` may be '
          'a finite value or `oo` / `-oo`.',
      examples: [
        FunctionRefExample(
          input: 'limit(sin(x)/x, x, 0)',
          expected: '1',
          hint:
              'In CrispCalc, `limit(...)` is a numerical approach: the bridge '
              'evaluates the expression at a sequence of points converging '
              'on `point` and reports the limit when consecutive samples '
              'agree to the working precision. No symbolic Series.',
        ),
        FunctionRefExample(
          input: 'limit(1/x, x, oo)',
          expected: '0',
          hint: 'The literal `oo` is the SymEngine infinity sentinel — the '
              'preprocessor recognises it before dispatch. Use `-oo` for '
              'negative infinity.',
        ),
        FunctionRefExample(
          input: 'limit((1 + 1/n)^n, n, oo)',
          expected: '2.71828...',
          hint: 'Approaches Euler\'s number. Because the path is numerical, '
              'the result is a float — use `e(N)` for the high-precision '
              'constant instead.',
        ),
      ],
      seeAlso: ['diff', 'integrate', 'e_precision'],
      workedExampleId: 'sinxOverX',
    ),
    FunctionRef(
      id: 'gcd',
      category: FunctionRefCategory.cas,
      signature: 'gcd(a, b)',
      shortDescription:
          'Greatest common divisor of two integers or polynomials.',
      examples: [
        FunctionRefExample(
          input: 'gcd(252, 105)',
          expected: '21',
          hint:
              'In CrispCalc, integer `gcd(...)` uses the Euclidean recurrence '
              'gcd(a, b) = gcd(b, a mod b). The underlying call is '
              'SymEngine\'s `gcd()` which dispatches to GMP\'s `mpz_gcd` for '
              'the integer case.',
        ),
        FunctionRefExample(
          input: 'gcd(x^2 - 1, x - 1)',
          expected: 'x - 1',
          hint: 'Polynomial GCD via the subresultant PRS algorithm. Useful as '
              'a prelude to `simplify` for cancellation.',
        ),
        FunctionRefExample(
          input: 'gcd(0, 7)',
          expected: '7',
          hint: 'Convention: `gcd(0, n) = |n|`. Matches the mathematical '
              'definition treating 0 as a multiple of every integer.',
        ),
      ],
      seeAlso: ['lcm', 'factor', 'isprime'],
      workedExampleId: 'gcdEuclid',
    ),
    FunctionRef(
      id: 'lcm',
      category: FunctionRefCategory.cas,
      signature: 'lcm(a, b)',
      shortDescription: 'Least common multiple of two integers or polynomials.',
      examples: [
        FunctionRefExample(
          input: 'lcm(4, 6)',
          expected: '12',
          hint: 'In CrispCalc, integer `lcm(...)` is computed via the identity '
              '`lcm(a, b) = |a*b| / gcd(a, b)`. The underlying call is '
              'SymEngine\'s `lcm()` which delegates to GMP\'s `mpz_lcm`.',
        ),
        FunctionRefExample(
          input: 'lcm(12, 18)',
          expected: '36',
          hint: '36 = 2²·3², which is the union of prime-power factors from '
              '12 = 2²·3 and 18 = 2·3².',
        ),
        FunctionRefExample(
          input: 'lcm(x^2 - 1, x + 1)',
          expected: 'x^2 - 1',
          hint: 'Polynomial LCM picks the higher-degree multiple — `x^2 - 1` '
              'already contains `x + 1` as a factor.',
        ),
      ],
      seeAlso: ['gcd', 'factor', 'factorint'],
    ),
    FunctionRef(
      id: 'factorial',
      category: FunctionRefCategory.cas,
      signature: 'factorial(n)   or   n!',
      shortDescription:
          'Exact integer factorial. Small `n` uses Dart `BigInt`; large `n` '
          'hands off to SymEngine.',
      examples: [
        FunctionRefExample(
          input: '5!',
          expected: '120',
          hint: 'In CrispCalc, the `n!` postfix and `factorial(n)` are '
              'equivalent — the preprocessor rewrites the postfix to the '
              'call. For `n ≤ 1000` we evaluate in Dart with `BigInt` '
              'multiplication; beyond that the underlying call is '
              'SymEngine\'s `factorial()`.',
        ),
        FunctionRefExample(
          input: '100!',
          expected: '9332621544394415268169923885626670049071596826438162146859'
              '2963895217599993229915608941463976156518286253697920827223'
              '758251185210916864000000000000000000000000',
          hint: '158 digits, preserved exactly thanks to the BigInt path — '
              'switching to IEEE-754 here would round to 1.0 × 10^157.',
        ),
        FunctionRefExample(
          input: '0!',
          expected: '1',
          hint: 'Empty-product convention: 0! = 1. Required so that recursion '
              'n! = n · (n-1)! grounds out at 1.',
        ),
      ],
      seeAlso: ['fibonacci', 'gcd', 'isprime'],
      workedExampleId: 'factorial100',
    ),
    FunctionRef(
      id: 'fibonacci',
      category: FunctionRefCategory.cas,
      signature: 'fibonacci(n)   or   fib(n)',
      shortDescription: 'Nth Fibonacci number. `fib(n)` is the short alias.',
      examples: [
        FunctionRefExample(
          input: 'fib(10)',
          expected: '55',
          hint: 'In CrispCalc, `fib(n)` and `fibonacci(n)` are the same call. '
              'For `n ≤ 90` we use a precomputed table; for larger `n` the '
              'underlying call is SymEngine\'s `fibonacci()`, which uses '
              'fast-doubling (O(log n) multiplications via GMP).',
        ),
        FunctionRefExample(
          input: 'fib(50)',
          expected: '12586269025',
          hint: 'The 50th Fibonacci number — well beyond the table cap of '
              'small terms but still fits in a 64-bit signed integer.',
        ),
        FunctionRefExample(
          input: 'fib(200)',
          expected: '280571172992510140037611932413038677189525',
          hint: 'Crosses into the GMP-backed path. Fast-doubling avoids the '
              'O(n) linear recurrence, so even fib(10000) is sub-second.',
        ),
      ],
      seeAlso: ['factorial', 'gcd', 'isprime'],
      workedExampleId: 'fibonacci50',
    ),
    // === Number theory =======================================================
    FunctionRef(
      id: 'isprime',
      category: FunctionRefCategory.numberTheory,
      signature: 'isprime(n)',
      shortDescription: 'Probabilistic primality test on integers.',
      examples: [
        FunctionRefExample(
          input: 'isprime(2027)',
          expected: 'true',
          hint: 'In CrispCalc, `isprime(n)` returns a boolean chip. The '
              'underlying call is GMP\'s `mpz_probab_prime_p` (25 Miller-'
              'Rabin rounds, error bound 4^-25 ≈ 9×10^-16) via SymEngine\'s '
              '`ntheory` module. 2027 is the 308th prime.',
        ),
        FunctionRefExample(
          input: 'isprime(2024)',
          expected: 'false',
          hint: '2024 = 2³·11·23.',
        ),
        FunctionRefExample(
          input: 'isprime(2^61 - 1)',
          expected: 'true',
          hint: 'The ninth Mersenne prime, M61. Miller-Rabin still settles in '
              'microseconds at this size — the cost is in the modular '
              'exponentiations, not the bit-length.',
        ),
      ],
      seeAlso: ['nextprime', 'prevprime', 'factorint'],
      workedExampleId: 'isprime',
    ),
    FunctionRef(
      id: 'nextprime',
      category: FunctionRefCategory.numberTheory,
      signature: 'nextprime(n)',
      shortDescription: 'Smallest prime strictly greater than `n`.',
      examples: [
        FunctionRefExample(
          input: 'nextprime(1000)',
          expected: '1009',
          hint: 'In CrispCalc, `nextprime(n)` iterates from `n+1` and tests '
              'each candidate. The underlying call is SymEngine\'s '
              '`ntheory::nextprime()`, which uses FLINT\'s sieve over short '
              'windows when the gap is large.',
        ),
        FunctionRefExample(
          input: 'nextprime(2)',
          expected: '3',
          hint: 'Strictly greater — `nextprime(p)` is never `p` itself, even '
              'when `p` is prime.',
        ),
      ],
      seeAlso: ['isprime', 'prevprime', 'factorint'],
      workedExampleId: 'nextprime1000',
    ),
    FunctionRef(
      id: 'prevprime',
      category: FunctionRefCategory.numberTheory,
      signature: 'prevprime(n)',
      shortDescription:
          'Largest prime strictly less than `n`. Errors if no such prime '
          'exists (e.g. `prevprime(2)`).',
      examples: [
        FunctionRefExample(
          input: 'prevprime(100)',
          expected: '97',
          hint: 'In CrispCalc, `prevprime(n)` walks downward from `n-1`. The '
              'underlying call is SymEngine\'s `ntheory::prevprime()`.',
        ),
        FunctionRefExample(
          input: 'prevprime(2)',
          expected: 'Error: no prime less than 2',
          hint: 'No primes exist below 2; the bridge raises rather than '
              'returning a sentinel. CrispCalc surfaces the error chip.',
        ),
      ],
      seeAlso: ['isprime', 'nextprime', 'factorint'],
    ),
    FunctionRef(
      id: 'factorint',
      category: FunctionRefCategory.numberTheory,
      signature: 'factorint(n)',
      shortDescription:
          'Prime factorisation as `p₁^e₁ · p₂^e₂ · …` with Unicode '
          'superscript exponents.',
      examples: [
        FunctionRefExample(
          input: 'factorint(360)',
          expected: '2³ · 3² · 5',
          hint: 'In CrispCalc, `factorint(n)` returns a rendered prime '
              'decomposition. The underlying call is FLINT\'s '
              '`fmpz_factor`, fronted by SymEngine\'s ntheory wrapper; '
              'CrispCalc converts the (prime, exponent) list into the '
              'Unicode superscript display.',
        ),
        FunctionRefExample(
          input: 'factorint(2147483647)',
          expected: '2147483647',
          hint: 'The 8th Mersenne prime, M31. A single factor (itself) — '
              '`factorint` short-circuits when the input is prime.',
        ),
        FunctionRefExample(
          input: 'factorint(1)',
          expected: '1',
          hint: 'Edge case: by convention 1 has the empty factorisation; '
              'CrispCalc renders this as the literal `1` rather than an '
              'empty string.',
        ),
      ],
      seeAlso: ['isprime', 'nextprime', 'gcd'],
      workedExampleId: 'factorint360',
    ),
    // === Precision arc =======================================================
    FunctionRef(
      id: 'pi_precision',
      category: FunctionRefCategory.precision,
      signature: 'pi(N)',
      shortDescription:
          'π to N decimal digits via MPFR; returns the literal digit string.',
      examples: [
        FunctionRefExample(
          input: 'pi(50)',
          expected: '3.14159265358979323846264338327950288419716939937510',
          hint: 'In CrispCalc, `pi(N)` is a special-cased call routed to the '
              'high-precision path before SymEngine sees it. The underlying '
              'call is MPFR\'s `mpfr_const_pi` at precision ⌈N·log2(10)⌉ + '
              '16 guard bits, followed by base-10 conversion.',
        ),
        FunctionRefExample(
          input: 'pi(100)',
          expected: '3.14159265358979323846264338327950288419716939937510'
              '58209749445923078164062862089986280348253421170679',
          hint: 'At N = 100 the working precision is ≈ 348 bits. The guard '
              'bits prevent base conversion from showing rounded trailing '
              'digits.',
        ),
      ],
      seeAlso: ['e_precision', 'sqrt_precision', 'eulergamma_precision'],
      workedExampleId: 'piPrecision',
    ),
    FunctionRef(
      id: 'e_precision',
      category: FunctionRefCategory.precision,
      signature: 'e(N)',
      shortDescription: 'Euler\'s number e to N decimal digits via MPFR.',
      examples: [
        FunctionRefExample(
          input: 'e(50)',
          expected: '2.71828182845904523536028747135266249775724709369995',
          hint: 'In CrispCalc, `e(N)` mirrors the `pi(N)` pipeline: MPFR\'s '
              '`mpfr_const_e` (which uses the Taylor series Σ 1/k!) at '
              'precision ⌈N·log2(10)⌉ + 16 guard bits, then base-10 '
              'rendering.',
        ),
        FunctionRefExample(
          input: 'e(20)',
          expected: '2.71828182845904523536',
          hint: 'Short enough to memorise — useful as a quick precision '
              'sanity check against `limit((1 + 1/n)^n, n, oo)`.',
        ),
      ],
      seeAlso: ['pi_precision', 'sqrt_precision', 'limit'],
      workedExampleId: 'ePrecision',
    ),
    FunctionRef(
      id: 'sqrt_precision',
      category: FunctionRefCategory.precision,
      signature: 'sqrt(k, N)',
      shortDescription:
          'Square root of integer `k` to N decimal digits via MPFR. The '
          '2-argument form picks the high-precision path.',
      examples: [
        FunctionRefExample(
          input: 'sqrt(2, 50)',
          expected: '1.41421356237309504880168872420969807856967187537694',
          hint: 'In CrispCalc, the 2-argument `sqrt(k, N)` is the high-'
              'precision route. The underlying call is MPFR\'s '
              '`mpfr_sqrt_ui` at precision ⌈N·log2(10)⌉ + 16 guard bits. '
              'The 1-argument `sqrt(2)` instead returns the symbolic '
              '`sqrt(2)` via SymEngine.',
        ),
        FunctionRefExample(
          input: 'sqrt(3, 30)',
          expected: '1.73205080756887729352744634150',
          hint: 'Useful for verification — `sqrt(3, N)` should agree with '
              '`pi_precision` digits derived independently.',
        ),
      ],
      seeAlso: ['pi_precision', 'e_precision', 'simplify'],
    ),
    FunctionRef(
      id: 'eulergamma_precision',
      category: FunctionRefCategory.precision,
      signature: 'EulerGamma(N)',
      shortDescription:
          'Euler–Mascheroni constant γ ≈ 0.5772… to N decimal digits via '
          'MPFR.',
      examples: [
        FunctionRefExample(
          input: 'EulerGamma(20)',
          expected: '0.57721566490153286061',
          hint:
              'In CrispCalc, `EulerGamma(N)` uses MPFR\'s `mpfr_const_euler`, '
              'which evaluates γ via the Brent–McMillan formula '
              '(modified Bessel functions). Precision is ⌈N·log2(10)⌉ + 16 '
              'guard bits, matching the `pi(N)` and `e(N)` pipeline.',
        ),
        FunctionRefExample(
          input: 'EulerGamma(50)',
          expected: '0.57721566490153286060651209008240243104215933593992',
          hint: 'γ has no known closed form. The MPFR routine is the '
              'standard reference implementation; CrispCalc just renders '
              'the digit string.',
        ),
      ],
      seeAlso: ['pi_precision', 'e_precision', 'sqrt_precision'],
    ),
    // === Matrix / linear algebra =============================================
    FunctionRef(
      id: 'matrix_literal',
      category: FunctionRefCategory.matrix,
      signature: 'Matrix([[a, b, ...], [c, d, ...], ...])',
      shortDescription:
          'Matrix literal: a list of rows, each row a list of cell '
          'expressions. Cells can be numbers, fractions, or symbolic.',
      examples: [
        FunctionRefExample(
          input: 'Matrix([[1, 2], [3, 4]])',
          expected: 'Matrix([[1, 2], [3, 4]])',
          hint: 'In CrispCalc, the `Matrix(...)` literal is recognised by the '
              'matrix evaluator before the engine sees the expression. The '
              'underlying call is SymEngine\'s `DenseMatrix` constructor — '
              'the row/col layout is fixed at construction.',
        ),
        FunctionRefExample(
          input: 'Matrix([[1/2, 0], [0, 1/3]])',
          expected: 'Matrix([[1/2, 0], [0, 1/3]])',
          hint: 'Cells stay symbolic — rationals don\'t collapse to floats. '
              'Same goes for free symbols: `Matrix([[a, b], [c, d]])` is '
              'accepted and propagated through `det` / `inv` / `rref`.',
        ),
        FunctionRefExample(
          input: 'Matrix([[1, 2, 3], [4, 5, 6]])',
          expected: 'Matrix([[1, 2, 3], [4, 5, 6]])',
          hint: 'Non-square matrices are fine for `transpose` and `rref` but '
              'will fail for `det` / `inv`, which require square input.',
        ),
      ],
      seeAlso: ['det', 'inv', 'transpose', 'rref'],
    ),
    FunctionRef(
      id: 'det',
      category: FunctionRefCategory.matrix,
      signature: 'det(Matrix(...))',
      shortDescription:
          'Determinant of a square matrix. Returns a symbolic scalar.',
      examples: [
        FunctionRefExample(
          input: 'det(Matrix([[1, 2], [3, 4]]))',
          expected: '-2',
          hint: 'In CrispCalc, `det(M)` evaluates as a single scalar. The '
              'underlying call is SymEngine\'s `DenseMatrix::det()`, which '
              'uses the Bareiss fraction-free algorithm — exact for '
              'symbolic / rational entries, no float blow-up.',
        ),
        FunctionRefExample(
          input: 'det(Matrix([[1, 2, 3], [0, 1, 4], [5, 6, 0]]))',
          expected: '1',
          hint: 'Classic 3×3 textbook example — Laplace cofactor expansion '
              'gives the same answer in 6 terms.',
        ),
        FunctionRefExample(
          input: 'det(Matrix([[a, b], [c, d]]))',
          expected: 'a*d - b*c',
          hint: 'Symbolic entries pass through unchanged. Bareiss keeps the '
              'result as a SymEngine `Add` rather than a float.',
        ),
      ],
      seeAlso: ['inv', 'transpose', 'rref', 'matrix_literal'],
      workedExampleId: 'matrixDet',
    ),
    FunctionRef(
      id: 'inv',
      category: FunctionRefCategory.matrix,
      signature: 'inv(Matrix(...))',
      shortDescription:
          'Inverse of a square non-singular matrix. Errors when `det = 0`.',
      examples: [
        FunctionRefExample(
          input: 'inv(Matrix([[4, 7], [2, 6]]))',
          expected: 'Matrix([[3/5, -7/10], [-1/5, 2/5]])',
          hint: 'In CrispCalc, `inv(M)` returns `adj(M)/det(M)`. The '
              'underlying call is SymEngine\'s `DenseMatrix::inv()`, which '
              'uses Gauss–Jordan elimination over the rationals — entries '
              'come back as exact fractions, not floats.',
        ),
        FunctionRefExample(
          input: 'inv(Matrix([[1, 0], [0, 1]]))',
          expected: 'Matrix([[1, 0], [0, 1]])',
          hint: 'Identity matrix is self-inverse — a quick smoke test that '
              'the bridge round-trips correctly.',
        ),
        FunctionRefExample(
          input: 'inv(Matrix([[1, 2], [2, 4]]))',
          expected: 'Error: inv failed: singular matrix',
          hint: 'Singular input (det = 0) errors out cleanly rather than '
              'returning bogus large numbers. The error chip surfaces in '
              'the calculator history.',
        ),
      ],
      seeAlso: ['det', 'rref', 'transpose', 'matrix_literal'],
      workedExampleId: 'matrixInverse',
    ),
    FunctionRef(
      id: 'transpose',
      category: FunctionRefCategory.matrix,
      signature: 'transpose(Matrix(...))',
      shortDescription:
          'Transpose: swap rows and columns. Works on rectangular matrices.',
      examples: [
        FunctionRefExample(
          input: 'transpose(Matrix([[1, 2], [3, 4]]))',
          expected: 'Matrix([[1, 3], [2, 4]])',
          hint: 'In CrispCalc, `transpose(M)` is implemented Dart-side because '
              'the bridge doesn\'t expose a transpose entry point. We '
              'allocate a fresh `SymEngineMatrix` with swapped dimensions '
              'and copy cells element-by-element.',
        ),
        FunctionRefExample(
          input: 'transpose(Matrix([[1, 2, 3], [4, 5, 6]]))',
          expected: 'Matrix([[1, 4], [2, 5], [3, 6]])',
          hint: 'Rectangular input: a 2×3 becomes a 3×2 — useful for paired '
              'sample data layouts.',
        ),
        FunctionRefExample(
          input: 'transpose(transpose(Matrix([[1, 2], [3, 4]])))',
          expected: 'Matrix([[1, 2], [3, 4]])',
          hint: 'Idempotent under two applications. Verifies the cell-swap '
              'preserves the symbolic content untouched.',
        ),
      ],
      seeAlso: ['det', 'inv', 'rref', 'matrix_literal'],
    ),
    FunctionRef(
      id: 'rref',
      category: FunctionRefCategory.matrix,
      signature: 'rref(Matrix(...))',
      shortDescription:
          'Reduced row echelon form via Gauss–Jordan elimination. Works '
          'over symbolic / rational entries.',
      examples: [
        FunctionRefExample(
          input: 'rref(Matrix([[1, 2, 5], [3, 4, 11]]))',
          expected: 'Matrix([[1, 0, -1], [0, 1, 3]])',
          hint: 'In CrispCalc, `rref` runs Gauss–Jordan in Dart and calls '
              'SymEngine\'s `simplify()` per cell update. The bridge '
              'doesn\'t expose `rref` directly, so the algorithm walks '
              'columns left-to-right, scales the pivot row, then '
              'eliminates the column above and below.',
        ),
        FunctionRefExample(
          input: 'rref(Matrix([[1, 2], [2, 4]]))',
          expected: 'Matrix([[1, 2], [0, 0]])',
          hint: 'Rank-deficient input: the second row reduces to all zeros. '
              'Useful for spotting linear dependence visually.',
        ),
        FunctionRefExample(
          input: 'rref(Matrix([[2, 4], [0, 6]]))',
          expected: 'Matrix([[1, 0], [0, 1]])',
          hint: 'Pivot scaling normalises leading entries to 1. Symbolic '
              'non-zero detection is the soft spot — see the algorithm '
              'note in `matrix_evaluator.dart`.',
        ),
      ],
      seeAlso: ['det', 'inv', 'transpose', 'matrix_literal'],
      workedExampleId: 'rref',
    ),
    FunctionRef(
      id: 'matrix_arithmetic',
      category: FunctionRefCategory.matrix,
      signature: 'Matrix(...) + / - / *  Matrix(...)',
      shortDescription:
          'Element-wise addition / subtraction and matrix multiplication '
          'on `Matrix(...)` literals.',
      examples: [
        FunctionRefExample(
          input: 'Matrix([[1, 2], [3, 4]]) + Matrix([[5, 6], [7, 8]])',
          expected: 'Matrix([[6, 8], [10, 12]])',
          hint: 'In CrispCalc, matrix binary ops are dispatched by the '
              'matrix evaluator when both operands parse as `Matrix(...)` '
              'literals. The underlying call is SymEngine\'s `add_dense_'
              'dense`; subtraction goes through `add_dense_dense` with '
              'an element-wise negation of the right-hand side.',
        ),
        FunctionRefExample(
          input: 'Matrix([[1, 2], [3, 4]]) * Matrix([[1, 0], [0, 1]])',
          expected: 'Matrix([[1, 2], [3, 4]])',
          hint: 'Multiplication is the standard row-by-column dot product '
              'via SymEngine\'s `mul_dense_dense`. Right-multiplication '
              'by the identity is a sanity check.',
        ),
        FunctionRefExample(
          input: 'Matrix([[1, 2], [3, 4]]) - Matrix([[1, 1], [1, 1]])',
          expected: 'Matrix([[0, 1], [2, 3]])',
          hint: 'Subtraction is element-wise; dimension mismatch errors '
              'cleanly with `Error: matrix - failed: …`.',
        ),
      ],
      seeAlso: ['det', 'inv', 'matrix_literal'],
    ),
  ];
}
