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
in release builds. **What's missing is the flat-C
`flutter_symengine_*` wrappers (one extra .c function per
exposed feature) plus the Dart bindings + +load keepalive
entries.** The wrapper source IS editable — it lives in the
sibling `math-stack-ios-builder` repo and uses SymEngine's
`basic_evalf` / `ntheory_*` cwrapper functions, which already
do the heavy lifting. PLAN.md's "tiny: one FFI call per
constant" framing is approximately right; it just spans three
repos. See §3 for the pipeline.

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

## 3. The three-repo pipeline

The precision arc spans three sibling repos. Edits flow
upstream → downstream; CI gates fire at each boundary.

```
math-stack-ios-builder            ← C wrapper source + build scripts
  src/flutter_symengine_wrapper.{c,h}
  build_symengine.sh, build_all.sh
  → produces SymEngineFlutterWrapper.xcframework + GMP/MPFR/MPC/FLINT
  ↓ via symbolic_math_bridge/copy_xcframeworks.sh
symbolic_math_bridge              ← Flutter plugin (pinned by CrispCalc)
  lib/symbolic_math_bridge.dart   ← Dart FFI bindings
  ios/Classes/SymEngineBridge.m   ← +load keepalive list
  ios/*.xcframework/              ← copied from math-stack-ios-builder
  ↓ git SHA pin
CrispCalc                         ← this repo
  pubspec.yaml ref: <bridge SHA>
  lib/engine/calculator_engine.dart  ← parser bindings for pi(N) etc.
```

**Local paths** (verify before acting — repos can move):

| Repo                      | Path                                                |
| ------------------------- | --------------------------------------------------- |
| math-stack-ios-builder    | `/Users/christianstrobele/code/math-stack-ios-builder/` |
| symbolic_math_bridge      | `/Volumes/backups/code/symbolic_math_bridge/`       |
| symengine (vendored)      | `/Volumes/backups/code/symengine/`                  |
| CrispCalc                 | `/Volumes/backups/code/CrispCalc/`                  |

### Wrapper source (math-stack-ios-builder)

The flat-C `flutter_symengine_*` functions are defined in
`src/flutter_symengine_wrapper.c` — 23 functions today,
including `flutter_symengine_get_pi`, `flutter_symengine_evaluate`,
`flutter_symengine_gcd`, `flutter_symengine_factorial`. All
call into SymEngine's `cwrapper.h` C API (e.g.,
`basic_evalf`, `ntheory_gcd`, `ntheory_factorial`).

**Adding a new precision function is "edit one .c file +
rebuild":**

```c
// In src/flutter_symengine_wrapper.c
char* flutter_symengine_pi_with_precision(int decimal_digits) {
    basic pi_sym, pi_evalf;
    basic_new_stack(pi_sym);
    basic_new_stack(pi_evalf);
    basic_const_pi(pi_sym);
    // bits ≈ digits × 3.322 + safety
    unsigned long bits = (unsigned long)(decimal_digits * 3.322 + 8);
    basic_evalf(pi_evalf, pi_sym, bits, 1);  // real=1
    char* result = basic_str(pi_evalf);
    basic_free_stack(pi_sym);
    basic_free_stack(pi_evalf);
    return result;
}
```

Add the matching declaration to
`src/flutter_symengine_wrapper.h`. SymEngine's `basic_evalf`
does the heavy lifting — it routes pi to MPFR internally and
returns a string at the requested precision.

### Rebuild flow

```bash
cd /Users/christianstrobele/code/math-stack-ios-builder
# Only the SymEngine + wrapper step is needed if GMP/MPFR/MPC/
# FLINT haven't changed. The README's build_all.sh rebuilds
# everything; build_symengine.sh just rebuilds the wrapper +
# SymEngine.
./build_symengine.sh           # ~5–15 min on Apple Silicon

cd /Volumes/backups/code/symbolic_math_bridge
./copy_xcframeworks.sh         # pulls fresh xcframeworks

# Commit + push symbolic_math_bridge so CrispCalc can repin.
git add ios/SymEngineFlutterWrapper.xcframework
git commit -m "wrapper: flutter_symengine_pi_with_precision"
git push origin main
```

Then in CrispCalc:

```bash
# Repin to the new bridge SHA
gh api repos/CrispStrobe/symbolic_math_bridge/commits/main --jq .sha
# Update pubspec.yaml's ref: <new-sha>
flutter pub get
flutter clean   # the pub-cache caches the static archive
flutter test
```

### Add to Dart bindings + keepalive list

In `symbolic_math_bridge/lib/symbolic_math_bridge.dart`,
replace the stub:

```dart
// Replace lines 815–818:
String mpfrHighPrecisionPi(int decimalDigits) {
  if (!isAvailable) {
    throw SymbolicMathNotAvailableException('MPFR high-precision pi');
  }
  final piPtr = _piWithPrecision(decimalDigits);
  if (piPtr == nullptr) {
    throw SymbolicMathException('mpfr pi returned null');
  }
  final result = piPtr.toDartString();
  _freeString(piPtr);   // existing helper
  return result;
}
```

…with a matching `lookupFunction` call in
`_initializeSymEngine()` (mirror line 296's pattern).

In `symbolic_math_bridge/ios/Classes/SymEngineBridge.m`, add to
the extern block (around line 11) and the `+load` array (around
line 124):

```objc
extern char* flutter_symengine_pi_with_precision(int decimal_digits);

// In +load:
static void* refs[] = {
    // ... existing 45 symbols ...
    flutter_symengine_pi_with_precision,
};
```

Without this, the symbol gets dead-stripped in release builds
even though it's in the static archive (see HANDOFF.md §4.1).

### Three viable implementation paths

**Path A — Rebuild via the documented pipeline** (above).
**This is the recommended path** — the pipeline exists, the
README documents it, the wrapper source is < 200 lines of C
that already uses `basic_evalf` / `ntheory_*`, and the
rebuild ergonomics are one script. The 5–15 min rebuild cost
is amortized across the whole arc (one rebuild per round; one
rebuild per ~3–8 new functions).

**Path B — Direct FFI to GMP/MPFR/FLINT (skip the wrapper).**
The `+load` keepalive list already keeps `mpfr_const_pi`,
`__gmpz_*`, `fmpz_*` alive in the binary. Dart can dlsym
those directly via `DynamicLibrary.process()`, bypassing the
wrapper layer. **Use as a fast-iteration fallback** during
dev when you want to test a precision flow without waiting
for SymEngine to recompile. Don't ship via this path — the
wrapper layer exists for a reason (error handling, consistent
string lifetimes, single Dart-side API surface).

**Path C — SymEngine `basic_evalf` direct.** `cwrapper.h`
exposes `basic_evalf(basic s, const basic b, unsigned long
bits, int real)` (line ~772). Path A's wrapper functions
already use it. There's no scenario where you'd want to dlsym
`basic_evalf` directly from Dart instead of going through
Path A's wrapper — Path A IS this approach, wrapped properly.

## 4. Round breakdown (5 rounds)

### Round 1 — MPFR arbitrary-precision constants (~1 session)

- **Wrapper** (math-stack-ios-builder): add four C functions to
  `src/flutter_symengine_wrapper.c`:
  `flutter_symengine_pi_with_precision(int digits)`,
  `flutter_symengine_e_with_precision(int digits)`,
  `flutter_symengine_euler_gamma_with_precision(int digits)`,
  `flutter_symengine_sqrt2_with_precision(int digits)`. All
  four go through SymEngine's `basic_evalf` (real=1) after
  starting from `basic_const_pi` / `basic_const_e` /
  `basic_const_euler_gamma` / a `basic_parse("sqrt(2)")`.
  Add matching `extern` declarations in
  `flutter_symengine_wrapper.h`. Run `./build_symengine.sh`.
- **Bridge** (symbolic_math_bridge): in
  `lib/symbolic_math_bridge.dart`, replace the
  `mpfrHighPrecisionPi` stub with a real `lookupFunction`
  call + helper, add three siblings. Update
  `ios/Classes/SymEngineBridge.m` with new extern + +load
  array entries (mirror in `macos/`). Run
  `./copy_xcframeworks.sh`, commit, push.
- **CrispCalc**: bump bridge SHA pin in `pubspec.yaml`,
  `flutter pub get`, `flutter clean`.
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

### Round 2 — Number-theory primitives — **SHIPPED in CrispCalc round 89**

Three new wrappers landed:
- `flutter_symengine_isprime(const char* n)` — straight GMP
  `mpz_probab_prime_p(x, 25)`. SymEngine's cwrapper.h does NOT
  expose `ntheory_isprime` (only `ntheory_nextprime`); using
  GMP directly is fine because `__gmpz_*` symbols are already
  keepalive'd since round 13.
- `flutter_symengine_nextprime(const char* n)` — via
  `basic_parse` + `ntheory_nextprime`; result inherits
  SymEngine's bigint formatting.
- `flutter_symengine_prevprime(const char* n)` — no GMP
  function exists. Decrements `x` and Miller-Rabin-checks each
  candidate. Average gap ≈ ln(N), so the loop runs few
  iterations on typical inputs. Errors when input < 3.

Bridge bindings use the existing `_UnaryFuncDart` shape
(string-in/string-out). `CalculatorEngine` adds `isprime`,
`nextprime`, `prevprime`; `isprime` has a sqrt-bounded
trial-division fallback for headless CI on Linux.

6 new tests in `precision_test.dart`. Suite size at the merge:
1457 tests.

**Land mine averted**: my original design draft assumed
`ntheory_probab_prime_p` was on the cwrapper. It isn't — only
`ntheory_nextprime` is. The Round 89 implementation uses GMP
directly for the two missing functions; future rounds doing
number-theory should check `cwrapper.h` first and skip
straight to GMP / FLINT direct calls for anything missing.

### Round 3 — Factorint — **SHIPPED in CrispCalc round 90**

`flutter_symengine_factorint` lands via FLINT's `fmpz_factor`
directly. Output format `"p1^e1*p2^e2*..."` (no spaces, `^1`
omitted) parsed Dart-side into
`List<({int prime, int exponent})>`. 90-bit input cap to keep
per-call time bounded.

**Land mine added**: the original FLINT keepalive block in
`SymEngineBridge.m` (round 12) only covered basic arithmetic.
Round 90 added 9 more `fmpz_*` externs
(`fmpz_set_str`, `fmpz_sizeinbase`, `fmpz_is_zero`,
`fmpz_is_one`, `fmpz_sgn`, `fmpz_neg`,
`fmpz_factor_init`, `fmpz_factor_clear`, `fmpz_factor`).
Future FLINT-backed wrappers should check the keepalive list
first; release-build dead-strip is unforgiving.

**Divisors** (not yet shipped): pure-Dart derivation from
factorint by enumerating subsets of the prime exponents. No
new wrapper. Trivial follow-up once a UI surface needs it.

### Round 4 — Modular arithmetic + totient + jacobi

- **Wrapper**: `flutter_symengine_modpow(a, e, m)`,
  `flutter_symengine_modinv(a, m)`,
  `flutter_symengine_totient(n)`,
  `flutter_symengine_jacobi(a, n)`. SymEngine's cwrapper has
  `ntheory_mod`, `ntheory_quotient_mod` (line 748 / 751),
  `ntheory_gcd_ext` (line 739). For modinv: use
  `ntheory_gcd_ext` then verify gcd==1. For modpow: SymEngine
  has `basic_pow` + `ntheory_mod`, OR call GMP's
  `__gmpz_powm` directly (faster, simpler).
- **Bridge + CrispCalc**: bindings + parser + tests.
- **Tests**: classroom values (totient(12) = 4; jacobi(2, 7)
  = 1; modinv(3, 11) = 4; modpow(2, 100, 1000000007)).

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
MPFR `pi(N)` function end-to-end across all three repos.
Validates the whole three-repo pipeline (and the release-build
keepalive trick) before committing more functions.

1. `math-stack-ios-builder`: add
   `flutter_symengine_pi_with_precision(int digits)` to
   `src/flutter_symengine_wrapper.{c,h}`. Run
   `./build_symengine.sh` (~5–15 min).
2. `symbolic_math_bridge`: `./copy_xcframeworks.sh`, replace
   the `mpfrHighPrecisionPi` Dart stub, add extern + +load
   entry in `SymEngineBridge.m` and the macOS mirror, commit,
   push.
3. CrispCalc: bump bridge SHA pin, `flutter pub get`,
   `flutter clean`, wire `pi(N)` parser shape in
   `lib/engine/calculator_engine.dart`. One integration test
   asserts `pi(50)` returns a 51-character string starting
   `3.14159265358979323846264338327950288419716939937510`.
4. `flutter build macos --release` + verify the new symbol
   survives dead-strip via `nm` on the binary (HANDOFF.md
   §4.1 — this is the load-bearing check). Commit + push.

Even shipping just this slice answers the open questions: does
the build pipeline reproduce, does the +load keepalive cover
the new wrapper, does the Dart FFI find the symbol under
release. Those three questions are the entire risk of the arc.

## 6. Land mines (specific to this arc)

### 6.1 Iterating without a full push cycle

The pin in `pubspec.yaml` is to a git SHA, which forces a push
every iteration. To iterate on the bridge locally without
pushing every time:

```yaml
dependency_overrides:
  symbolic_math_bridge:
    path: /Volumes/backups/code/symbolic_math_bridge
```

After each change in the bridge (especially the xcframeworks),
`flutter pub get` + `flutter clean` is required because the
pub cache and the build artefacts hold stale archives. CI will
fail on the override (CI machines don't have the sibling path)
— remove `dependency_overrides` before committing CrispCalc
changes that touch precision functions.

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

`math-stack-ios-builder` is one step further upstream — its
output (the xcframeworks) lands in `symbolic_math_bridge` via
`copy_xcframeworks.sh`, not via git pin. So a force-push there
doesn't break CrispCalc CI directly; it just means a future
rebuild can't reproduce against the same source state. Tag
each round's wrapper revision in `math-stack-ios-builder` so
the rebuild is reproducible.

### 6.4 SymEngine's `basic_str` output format

SymEngine's `basic_evalf` produces an MPFR-backed basic; calling
`basic_str` on it returns the standard SymEngine pretty-print
format. Verify experimentally on round 1: does π at 50 digits
come back as `3.14159...` (natural) or `3.14159...e0` (scientific
with zero exponent)? If the latter, add a small formatter helper
on the Dart side or in the wrapper C that strips trailing `e0`
suffixes. Either way, ship a `_formatPrecisionString` helper in
round 1 so rounds 2–4 inherit consistent formatting without
re-deciding.

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

- `flutter_symengine_pi_with_precision` defined in
  `math-stack-ios-builder/src/flutter_symengine_wrapper.c`,
  rebuilt into the xcframework, copied into
  `symbolic_math_bridge`.
- Dart binding in `symbolic_math_bridge/lib/symbolic_math_bridge.dart`
  replaces the `mpfrHighPrecisionPi` stub.
- `+load` keepalive list in `SymEngineBridge.m` includes the
  new symbol; verified via `nm` on a release-build binary.
- CrispCalc parser recognizes `pi(N)` as a function call;
  routes through the bridge.
- `pi(50)` returns a 51-character string starting
  `3.14159265358979323846264338327950288419716939937510`.
- `pi(100)`, `pi(500)`, `pi(1000)` all return correct prefixes
  (cross-check against https://www.piday.org/million/).
- New test file `test/precision_test.dart` covers the
  prefixes. CI matrix passes on all 6 jobs.
- HISTORY.md round entry. Three commits pushed in order:
  math-stack-ios-builder, symbolic_math_bridge, CrispCalc.

End of round 5:

- All eight number-theory functions surface in the Adv keypad.
- Five new worked-examples entries cover them with cross-
  locale titles.
- Suite ~+50 tests (precision + number-theory + locale
  coverage).
- `symbolic_math_bridge/lib/symbolic_math_bridge.dart`'s
  "HIGH-PRECISION METHODS — Add implementations as needed"
  comment block is gone — the three stubs that previously
  threw `SymbolicMathNotAvailableException` are now real, and
  the section has grown to ~12 functions.
- PLAN.md "Precision & number theory" group A marked SHIPPED;
  group B (polynomial arithmetic, continued fractions, Bessel
  /zeta / theta) remains for a future arc.
