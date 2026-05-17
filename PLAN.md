# CrispCalc — Repair & Completion Plan

Living document. Each task: `[ ]` pending · `[~]` in-progress · `[x]` done.
Completed items are moved (with date) to `HISTORY.md`.

See `HISTORY.md` for the most recent work: 60 new unit tests covering plane,
conic, numerical helpers and full AppState persistence; the calculator
history clear button; persistent history / variables / graph functions;
and the light/dark/system theme picker.

---

## P1 — Open follow-ups

- [ ] **Make `CrispCalc` repo public.** LICENSE + About + CI all in
  place now. `gh repo edit --visibility public` and confirm the first
  CI run is green before announcing.
- [ ] **Native `limit`.** The native bridge doesn't expose a `limit`
  entry point and the underlying SymEngine C API is missing one. Numerical
  one-sided / infinity limits stay as the current best effort. (Native
  `integrate` is now bound — see HISTORY.)
- [ ] **`flutter build macos --release`: SymEngine symbols missing.**
  Debug builds link the static archive cleanly via `-all_load` in the
  Pods-Runner xcconfig (45 `flutter_symengine_*` symbols land in
  `crisp_calc.debug.dylib`). The same xcconfig is in effect for the
  release build, but `nm` reports 0 symbols in `Contents/MacOS/crisp_calc`.
  Tried adding `-Wl,-force_load,…libsymengine_flutter_wrapper.a` — got
  duplicate-symbol errors when combined with `-all_load`, and missing
  symbols when used alone. Likely involves: how `static_framework`
  interacts with release `DEAD_CODE_STRIPPING`, framework re-link order,
  or the AOT-compile pipeline. Need to inspect the actual `ld` command
  line via `xcodebuild -verbose` or via instrumenting the Podfile.
- [ ] **iOS smoke test.** Not run since the recent changes.

## P2 — Engine + native bridge

- [ ] **High-precision evaluation.** `SymbolicMathBridge.evaluateWithPrecision`
  / `gmpPower` / `mpfrHighPrecisionPi` still throw — wire them when the
  C++ wrapper exposes the corresponding symbols.
- [ ] **Matrix arithmetic end-to-end.** Confirm `det(Matrix([[…]]))`,
  `inv(...)`, `transpose(...)` round-trip cleanly through the engine
  with a release SymEngine build.

## P2 — UX polish

- [ ] **More translations.** German is up to date; Spanish / French
  would be cheap follow-ups.
- [ ] **Variable substitution dialog** — no more typing `subst(...)`.
- [ ] **Plot annotations** — mark extrema and roots on the graph when
  an analysis is open.

## P3 — Long tail

- [ ] Symbolic Gauss / RREF on matrices.
- [ ] CI: GitHub Actions to run `flutter analyze` + `flutter test` on PR.
- [ ] History view filtering / search.

---

## Out of scope this round

- C++ implementation of symbolic `limit` and `integrate`.
- Rewriting the LaTeX↔engine parsing as a real grammar.
- Full accessibility audit.
