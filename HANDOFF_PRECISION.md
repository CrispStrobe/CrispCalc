# CrispCalc — precision arc handover

Focused handoff for the **MPFR/FLINT precision arc** (PLAN.md
§"Precision & number theory"). Reuse alongside the general
`HANDOFF.md` (which stays the pattern catalog for the whole
project).

Treat this doc as load-bearing context, not background reading.
The wrapper-layer realities below are the kind of thing that
sandbags a session if you discover them four hours in. Cross-
check every claim against the current repo state before acting.

---

## 1. The arc, one paragraph

Surface what the native bridge could already do but doesn't:
**arbitrary-precision real constants** (`pi(50)`, `e(100)`,
`EulerGamma(200)`, `sqrt(2, 50)`, `ln(10, 100)` — argument is
decimal digits, 1..10 000) backed by MPFR, plus a **number-
theory toy set** (`isprime`, `nextprime`/`prevprime`,
`factorint`, `divisors`, `totient`, `modinv`, `modpow`,
`jacobi`) backed by FLINT + GMP through SymEngine's `ntheory_*`
C wrappers. The libraries are shipped, linked, and kept alive
in release builds. **What's missing is the C wrapper layer that
exposes them as flat `flutter_symengine_*` symbols, plus the
Dart bindings.** PLAN.md's optimistic "tiny: one FFI call per
constant" framing is wrong — see §3.

## 2. Why this arc, and why now

PLAN.md added a Strategic Context section (May 2026) framing
two bigger bets: a notepad/document input paradigm, and AI as a
*verifier-frontend*. Those are the moves that reposition the
product. They're also multi-month design efforts with no obvious
"first round."

The precision arc is the **strongest concrete CAS arc available
right now**:

- Strengthens the moat the strategic context calls out
  ("competitive-to-ahead on the scientific/power-user axis").
- Builds on infra that already ships (SymEngine xcframework +
  GMP/MPFR/FLINT linked + keepalive trick in place).
- Discrete, completable, testable in `flutter test` — no UI
  design dependency.
- Not blocked on iOS smoke test (P1) or distribution (P4).

If the next session has < 5 rounds of budget, ship round-1 of
this arc and roll back to strategic discussion. If it has 5+
rounds, ship the whole arc.

## 3. The wrapper-layer reality (critical)

The bridge plugin is `symbolic_math_bridge`, pinned in
`pubspec.yaml` to a git SHA on
`github.com/CrispStrobe/symbolic_math_bridge`. Layout:

```
~/.pub-cache/git/symbolic_math_bridge-<sha>/
├── lib/symbolic_math_bridge.dart            ← Dart side, FFI bindings
├── ios/Classes/SymEngineBridge.m            ← Obj-C +load keepalive
├── ios/SymEngine.xcframework/               ← libsymengine.a + headers
├── ios/SymEngineFlutterWrapper.xcframework/ ← libsymengine_flutter_wrapper.a (45 syms)
├── ios/FlutterSymEngineWrapperOnly.xcframework/  ← duplicate, 45 syms
├── ios/Libraries/libsymengine_wrapper-*.a   ← variant-specific archives
├── ios/GMP.xcframework/ ios/MPFR.xcframework/ ios/MPC.xcframework/ ios/FLINT.xcframework/
└── macos/... (mirrors ios/)
```

**The `flutter_symengine_*` flat-C wrapper functions are
defined inside `libflutter_symengine_wrapper_only.a` — a
prebuilt static archive shipped with the plugin.** No C source
for those wrappers exists in the plugin repo. The 45 wrapper
symbols include `flutter_symengine_evaluate`,
`flutter_symengine_get_pi`, `flutter_symengine_factorial`, etc.
— but NOT precision variants like
`flutter_symengine_pi_with_precision` or
`flutter_symengine_isprime`. **Adding new wrappers requires
rebuilding the static archive from whatever upstream tooling
generated it.**

The three existing Dart stubs (`evaluateWithPrecision`,
`gmpPower`, `mpfrHighPrecisionPi`) at lines 804/810/816 of
`lib/symbolic_math_bridge.dart` throw
`SymbolicMathNotAvailableException('...')` because the C
symbols they'd dlsym don't exist yet.

### Three viable implementation paths

**Path A — Rebuild the static wrapper archive.** Find the
upstream wrapper-source repo (NOT in the bridge plugin itself —
likely a separate `symengine-flutter-wrapper-src` repo, possibly
`https://github.com/CrispStrobe/symengine_flutter_wrapper` or
under the same org), add C functions like
`flutter_symengine_pi_with_precision(unsigned int prec)`,
rebuild `libflutter_symengine_wrapper_only.a` for all 5 targets
(macOS-arm64, macOS-x86_64, iOS-arm64, iOS-sim-arm64,
iOS-sim-x86_64), drop them into the plugin repo, commit, bump
the SHA pin in CrispCalc. **Highest cost; cleanest result; works
for every precision function we'd ever want.**

**Path B — Direct FFI to GMP/MPFR/FLINT.** The `+load` keepalive
list in `SymEngineBridge.m:124–172` already keeps `mpfr_const_pi`,
`mpfr_get_str`, `__gmpz_*`, `fmpz_*` symbols alive. Dart can
dlsym those directly via `DynamicLibrary.process()`, bypassing
the wrapper layer. **Cheapest; works for round 1; can't reach
SymEngine-level helpers (e.g., `ntheory_factor` symbolic
factorization) without rebuilding wrappers.** Round 1 of the
arc can ship via this path. For the number-theory set,
`__gmpz_probab_prime_p` covers `isprime`; `__gmpz_nextprime`
covers `nextprime` (already in the keepalive list at line 168).
For `factorint`, GMP doesn't have a built-in factorizer; would
need to call `fmpz_factor` (FLINT) — check if it's keepalive'd
(it's not in the current list; would need to add).

**Path C — SymEngine `basic_evalf`.** The cwrapper.h header at
line 772 declares
`CWRAPPER_OUTPUT_TYPE basic_evalf(basic s, const basic b,
unsigned long bits, int real)`. This evaluates ANY basic
expression to N bits of precision. So a Dart layer could parse
`pi`, lift to a SymEngine basic via `flutter_symengine_get_pi`
(already there), then evalf at N bits. **Problem**: there's no
`flutter_symengine_evalf` flat-C wrapper either, so this still
requires either path A (rebuild) or path B (direct call to
SymEngine's mangled C++ symbols, harder).

### Recommended path

**Round 1: Path B for MPFR constants** (pi/e/EulerGamma/sqrt(2)
at N digits). All four MPFR `mpfr_const_*` functions are
keepalive'd. Round 1 ships these via direct FFI without any
wrapper-archive rebuild.

**Round 2+**: decide between path A (rebuild) and path B-
extended (add more GMP/FLINT symbols to keepalive list, dlsym
them) based on which is cheaper. The keepalive list is one .m
file; rebuilding the static archive requires finding the
upstream wrapper source.

If round 1 ships smoothly via path B, the bias should be
toward "extend the keepalive list and dlsym directly" for as
many of the number-theory functions as possible. Reach for path
A only when a function genuinely needs SymEngine's symbolic
layer (e.g., `factorint` returning structured `(prime,
exponent)` tuples — GMP's raw factorizer doesn't exist, but
FLINT's `fmpz_factor` does and could be wrapped via path B + a
struct-marshaling helper).

## 4. Round breakdown (5 rounds)

### Round 1 — MPFR arbitrary-precision constants (~1 session)

- **Engine**: replace the `mpfrHighPrecisionPi` stub in
  `lib/symbolic_math_bridge.dart` with a real dlsym call to
  `mpfr_init2` + `mpfr_const_pi` + `mpfr_get_str`. Add three
  siblings: `mpfrHighPrecisionE`, `mpfrHighPrecisionEulerGamma`,
  `mpfrHighPrecisionSqrt2`. Each takes a digit count
  (1..10 000), converts to bits internally (`bits ≈ digits ×
  3.322 + 8`), allocates an `mpfr_t`, calls the constant
  function, converts to string, frees.
- **Calculator binding**: extend `calculator_engine.dart`'s
  parser to recognize `pi(50)`, `e(100)`, `EulerGamma(200)`,
  `sqrt(2, N)`, `ln(10, N)` as new function-call shapes.
  Currently `pi` is a bare constant — the parenthesized form is
  new syntax. Route through the bridge.
- **Display**: high-digit results inherit the round-44 "Exact
  integer · N digits · tap to copy" badge for real-valued
  precision strings. See `lib/screens/calculator_screen.dart`
  around line 500 for the existing badge.
- **Tests**: new file `test/precision_test.dart` exercises
  each constant at 50 / 100 / 500 / 1000 digits; assert known
  prefixes (e.g., π starts with `3.1415926535897932384626433...`).
  Build under macOS only — the precision functions don't run
  in `flutter test` headless mode (no SymEngine init) unless
  the bridge is fully loaded. Mark tests
  `@Tags(['integration'])` and run via
  `flutter test --tags integration`.
- **i18n**: settings string for "Precision (digits)" if a UI
  control surfaces. Round 1 can ship without UI — just the
  CAS expressions.

### Round 2 — Number-theory primitives via direct GMP

- **Bridge methods**: `isprime(int)` → `bool` (Miller-Rabin via
  `__gmpz_probab_prime_p`); `nextprime(int)` / `prevprime(int)`
  via `__gmpz_nextprime` (already keepalive'd; prevprime needs
  a small loop or use of `mpz_prevprime` if available).
- **Calculator binding**: `isprime(n)`, `nextprime(n)`,
  `prevprime(n)`. Return bool / int via the existing string-
  result protocol (`"true"` / `"7"`).
- **Tests**: `isprime(2^31 - 1) == true`, `isprime(2^32) ==
  false`, `nextprime(100) == 101`, etc.

### Round 3 — Factorint + divisors via FLINT

- **Keepalive extension**: add `fmpz_factor_init`,
  `fmpz_factor_clear`, `fmpz_factor`, `fmpz_factor_get_str` to
  `SymEngineBridge.m`'s `+load` list (around line 171). Verify
  the symbols exist in `libflint.a` via `nm`.
- **Bridge method**: `factorint(int n)` → `List<({int prime,
  int exponent})>`. Parses FLINT's structured output via Dart
  side.
- **Calculator binding**: `factorint(360) == [(2,3), (3,2),
  (5,1)]`. Display formatter renders as `2^3 · 3^2 · 5`.
- **Divisors**: derived from factorint by enumerating subsets
  of the prime exponents. Pure Dart on top of round-3's
  factorint result.
- **Tests**: textbook cases + edge cases (n=1 returns empty;
  n prime returns `[(n, 1)]`; n=0 returns error).

### Round 4 — Modular arithmetic + totient + jacobi

- **Bridge methods**: `modinv(a, m)`, `modpow(a, e, m)`,
  `totient(n)`, `jacobi(a, n)`. All map cleanly to GMP
  primitives (`__gmpz_invert`, `__gmpz_powm`, `__gmpz_jacobi`,
  and for totient compose `__gmpz_set_ui` + iterate over
  factorint result).
- **Keepalive extension**: add the new `__gmpz_*` symbols.
- **Tests**: classroom values (totient(12) = 4; jacobi(2, 7)
  = 1; modinv(3, 11) = 4).

### Round 5 — UI polish + worked-examples discovery

- **Settings**: precision-digits control for the four MPFR
  constants. Persisted via `AppState`.
- **Adv keypad tab**: buttons for `isprime`, `factorint`,
  `nextprime`, `divisors`, `totient`, `modinv`, `modpow`,
  `jacobi`. Group under a "Number theory" subsection.
- **Worked examples**: new entries in `lib/engine/worked_
  examples.dart`:
  - `piHighPrecision` — π to 100 digits
  - `factorintExample` — `factorint(2^60 - 1)` (illustrates
    big-number factorization)
  - `eulerTotient` — `totient(360)`
  - `modularPow` — `modpow(2, 100, 1000000007)` (intro to
    crypto)
  - `discreteLogProbe` — `for k in 1..n: modpow(g, k, p)`
    showing the period (no symbolic discrete log; pure
    illustration). Add via the existing 4-touch-point pattern
    (HANDOFF.md §4.10).
- **i18n**: ~30 new strings × 4 locales = 120 entries.
  Round-by-round-test count grows via the auto-generated
  locale-coverage harness.

## 5. The "smallest first slice"

If the next session has less than half a day, ship **just** the
MPFR `pi(N)` function end-to-end:

1. Replace `mpfrHighPrecisionPi` stub in
   `symbolic_math_bridge`. Rebuild the plugin locally, repin
   in CrispCalc's pubspec, `flutter pub get`.
2. Wire one new shape `pi(N)` in `calculator_engine.dart`.
3. One test: `pi(50)` returns a 51-character string starting
   `3.14159265358979323846264338327950288419716939937510`.
4. Commit + push.

Even shipping this slice answers the open question: does
direct-FFI-to-MPFR work at all, or does the keepalive list
actually fail under release builds? The full release-mode
verification on macOS / iOS is the load-bearing test —
HANDOFF.md §4.1 warns about exactly this regression class.

## 6. Land mines (specific to this arc)

### 6.1 You can't `flutter pub get` from a local symbolic_math_bridge fork

The pin in `pubspec.yaml` is to a git SHA. To iterate on the
bridge locally:

```
dependency_overrides:
  symbolic_math_bridge:
    path: /Users/christianstrobele/code/symbolic_math_bridge
```

After each change in the bridge, `flutter pub get` + a clean
build is required because the static archive is cached. Use
`flutter clean` between iterations.

### 6.2 Release builds dead-strip symbols even if dlsym'd at runtime

HANDOFF.md §4.1 already warns about this. The +load keepalive
list in `SymEngineBridge.m:124–172` is what prevents it. Any
new GMP/MPFR/FLINT symbol you dlsym must also be added to that
list AND survive the build process. Verify via:

```
flutter build macos --release
nm build/macos/Build/Products/Release/crisp_calc.app/Contents/MacOS/crisp_calc \
  | grep <symbol_name>
```

The symbol should be present. If it isn't, the +load list
didn't keep it.

### 6.3 dart_csp pin force-pushes also apply to symbolic_math_bridge

HANDOFF.md §4.1 documents the dart_csp force-push issue. The
same risk exists for symbolic_math_bridge — when the bridge SHA
gets force-pushed, CI fails because pub-cache resolves to a
SHA that's gone from origin. Same fix:
`gh api repos/CrispStrobe/symbolic_math_bridge/commits/main
--jq .sha`, repin, `flutter pub get`, commit, push.

### 6.4 `mpfr_get_str` returns a string that needs special handling

The MPFR string format is `<sign>X.YYYY*EZZZZ` with the radix
point AFTER the leading digit (so π at 50 digits comes back as
`3.1415...e0`, not `0.31415...e1`). The Dart formatter wants
the natural form for display. Either strip the trailing `e0`
in the Dart-side helper, OR call `mpfr_get_str(NULL, &exp, 10,
N, mpfr_var, MPFR_RNDN)` with a manual exponent argument and
construct the natural form yourself.

Round 1 should ship a `_formatMpfrString` helper alongside the
bridge call so subsequent rounds (e.g., `sqrt(2, N)` which may
have negative exponents) inherit consistent formatting.

### 6.5 `factorint(2^61 - 1)` is fast; `factorint(2^200 - 1)` is forever

FLINT's `fmpz_factor` uses trial division + Pollard's rho. It
handles up to ~50-60 digit composites in seconds; past that,
times balloon. Cap the input bit-size on the bridge side and
return a friendly error for n > 2^80 or so. The Calculator UI
shouldn't be able to lock the app trying to factor a 1000-bit
number.

### 6.6 SymEngine `basic_evalf` doesn't auto-detect "real" outputs

The `int real` parameter at the end of
`basic_evalf(basic s, const basic b, unsigned long bits, int
real)` (cwrapper.h:772–773) selects between MPFR (real=1) and
MPC (real=0, complex output). For purely real expressions like
`pi`, `e`, `sqrt(2)`, pass `1`. For `sqrt(-1) → i` you'd need
`0` and the MPC path. Round 1 only ships real constants;
complex high-precision is round 6+.

## 7. Cross-references

- `PLAN.md` § "Strategic context (May 2026)" — why the precision
  arc strengthens the moat called out in the strategic frame.
- `PLAN.md` § "Precision & number theory (native libs already
  linked)" — the original arc breakdown. Note: the "tiny: one
  FFI call per constant" estimate is now corrected by this
  doc's §3.
- `HANDOFF.md` § 3 — recently shipped rounds chain (80–84).
- `HANDOFF.md` § 4.1 — the dart_csp pin / force-push pattern
  that also applies here.
- `HISTORY.md` round 44 — the exact-integer-mode precedent.
  Pure-Dart, no bridge call needed; the lesson was *don't
  round-trip exact strings through double.parse*. Same principle
  applies to MPFR strings.
- `HISTORY.md` round 13 — the +load keepalive trick that makes
  the precision arc possible at all.

## 8. What "done" looks like

End of round 1:

- `pi(50)` in the calculator returns a 51-character string
  starting `3.14159265358979323846264338327950288419716939937510`.
- `pi(100)`, `pi(500)`, `pi(1000)` all return correct prefixes
  (cross-check against
  https://www.piday.org/million/).
- `flutter build macos --release` succeeds with the new MPFR
  symbol still present in the binary (verify with `nm`).
- New test file `test/precision_test.dart` passes under both
  `flutter test --tags integration` and the CI matrix.
- HISTORY.md round entry + this doc updated with the actual
  path chosen (B vs A vs C).

End of round 5:

- All eight number-theory functions surface in the Adv keypad.
- Five new worked-examples entries cover them with cross-
  locale titles.
- Suite ~+50 tests (precision + number-theory + locale
  coverage).
- `lib/symbolic_math_bridge.dart`'s "stub" comment block is
  gone — all three (now expanded to ~12) functions are real.
- PLAN.md "Precision & number theory" group A marked SHIPPED;
  group B (polynomial arithmetic, continued fractions, Bessel
  /zeta / theta) remains for a future arc.
