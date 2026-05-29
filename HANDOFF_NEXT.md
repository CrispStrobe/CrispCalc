# CrispCalc — handover for the next session

## Latest: 2026-05-29 (cont.) — Group B started: continued fractions

`cfrac(x, n)` / `convergent(x, k)` shipped — the first **Group B** item,
**pure-Dart** (exact BigInt over the existing MPFR precision strings, no
new wrapper, single repo, all on `main`). `cfrac(pi, 10)` →
`[3; 7, 15, 1, 292, 1, 1, 1, 2, 1]`; `convergent(pi, 3)` → `355/113`.
Full UI surfacing (keypad + FunctionReference DE/FR/ES + worked
example). **2418 tests.** Group B remaining: polynomial arithmetic,
Bessel/zeta/theta, arbitrary-precision complex (each a 3-repo wrapper
arc except where pure-Dart suffices).

---

## Precision arc Group A complete (Round 4 + 5)

Closed out the precision/number-theory arc's **Group A**. Round 4 added
the last four native functions — `modpow` / `modinv` / `totient` /
`jacobi` — plus pure-Dart `divisors`, across the full three-repo chain
(wrapper C → bridge bindings + `+load` keepalive → CrispCalc engine +
parser). Round 5 surfaced all of them in the UI (Adv-keypad buttons,
FunctionReference entries with DE/FR/ES i18n, worked-examples). **All
three repos merged to their default branches** (math-stack `master`
`39d2e4d8`, bridge `main` `ce8af30`, CrispCalc `main` repinned to
`ce8af30`). Release-build `nm` confirmed the new symbols survive
dead-strip. **2387 tests** (one pre-existing notepad full-suite flake,
passes in isolation). Group A done; **Group B** (polynomial arithmetic,
continued fractions, Bessel/zeta/theta, arbitrary-precision complex) is
the next precision arc. See `HANDOFF_PRECISION.md` + HISTORY top entry.

---

Pickup note from the **2026-05-29 session** (P11 R130 + R100 + R105b).
Three arcs landed: **Linux x86_64 SymEngine** (bridge v1.2.0 — the
last tier-1 platform; every native target now ships full SymEngine),
the **Function Reference i18n** (R100 — full DE/FR/ES coverage of the
~45-entry catalog), and **R105b** per-element help popovers on the
Statistics / Sudoku / Constraints DSL screens; plus the bridge v1.2.1
Windows-loader fix and the **v0.4.1 release**. Prior session
(2026-05-27) cut v0.4.0 with Android + Windows.

## ⚠ Working mode

**Single-repo CrispCalc work** goes **directly on `main`**. A
**multi-repo arc** (CrispCalc + symbolic_math_bridge +
math-stack-ios-builder) uses a **feature branch per repo**, then
merges each to its default branch — per the multi-repo rule (see
`memory/feedback_multi_repo_arc_worktree.md`). The round-4 arc this
session followed exactly that: `precision-round4-modular` in all three,
merged to `master`/`main`. Round-5 (UI-only, CrispCalc) went on `main`.

## State

| | |
|---|---|
| **Main worktree** | `/Volumes/backups/code/CrispCalc` (branch `main`) |
| **main HEAD** | Precision Group A (Round 4 + 5) + Group B continued fractions, on top of R130 + R100 + R105b; **v0.4.1 released** |
| **Tests** | **2418 pass** (2317 → 2334 R4 → 2387 R5 → 2418 cfrac); 1 pre-existing notepad full-suite flake |
| **dart_csp pin** | `69a9cfb` (unchanged) |
| **bridge pin** | **`ce8af30`** (bridge main, post round-4 merge — modpow/modinv/totient/jacobi) — was `535ce5d` pre-session |
| **bridge main HEAD** | `ce8af30` (round-4 `precision-round4-modular` merged) |
| **platforms** | iOS · macOS · Android arm64-v8a · Windows x86_64 · **Linux x86_64** — all full-CAS. Web still the only CAS-less target. |

## This session — major arcs landed (2026-05-29)

### Arc A: P11 R130 — Linux x86_64 SymEngine (bridge v1.2.0)

The last tier-1 platform. Bridge branch `r130-linux` → `main`
(`0907768`). **Green on the first CI run** (`build-linux.yml`
26604981909, 19m5s) — no iteration. A hybrid of R132 (static-link
the whole math stack into one `.so`) and R131 (three-mode consumer
CMake), but simpler: a Linux `ffiPlugin` needs no registrar `.cc` /
no `flutter` linkage, so the consumer path is pure bundling and there
is no filename-collision workaround (Dart opens
`libsymbolic_math_bridge.so`, exactly what `add_library()` emits).

- vcpkg `x64-linux` static on `ubuntu-22.04` (GLIBC 2.35 baseline).
- 18.3 MB stripped `.so`, only libc/libstdc++/libm/libgcc_s dynamic.
- Committed at `linux/Libraries/`; CrispCalc re-pinned to `0907768`.
- **All 6 CrispCalc CI jobs green** — the Build Linux job moved from
  degraded to full via consumer-prebuilt bundling (no source-compile
  attempt — the v1.1.0 failure mode did NOT recur). README + PLAN +
  `LINUX_STATUS.md` updated.

### Arc B: R100 — Function Reference content i18n (German)

Was the highest-leverage UI item. The dialog localized its chrome but
read entry descriptions + example hints from the English catalog —
fixed by the worked-examples precedent: nullable
`functionRefDescription(id)` / `functionRefExampleHint(id, index)` on
`AppLocalizations`, dialog falls back to the catalog on null.

- **Complete German** coverage of all ~45 entries (every category) —
  descriptions + every hint. Terminology per German math didactics.
- Localization test enforces full DE completeness (new entry without
  DE → CI fails). Tests 1992 → **2129**.
- **FR/ES still return null** (English fallback). The mechanism + test
  are ready; finishing them is a clean follow-up (see open items).

## Smoke-test status (what's verified, what isn't)

| | Verified via CI | Real-hardware verification |
|---|---|---|
| Compile + link + symbols in export table (all 5 platforms) | ✓ | n/a |
| macOS app builds + binaries embed | ✓ | host = macOS, runtime OK |
| Android APK contains the bridge .so | ✓ | **⚠ needs arm64-v8a device/emulator** |
| Windows zip contains the bridge .dll | ✓ | **⚠ needs Windows x86_64 desktop** |
| **Linux bundle contains the bridge .so** | ✓ (consumer-prebuilt build green) | **⚠ needs a Linux x86_64 desktop** |
| iOS unchanged | ✓ | **⚠ needs an iOS device** |

The structural pipeline is end-to-end green on all five platforms.
What's NOT confirmed: the runtime FFI call from a real Android /
Windows / Linux machine. Same wrapper source that works on iOS/macOS
got compiled into each binary — if compile + link + symbol visibility
line up (verified, incl. Linux `ldd`/`.dynsym` checks), runtime should
follow. Still worth a hardware pass.

## What's open / next session pickup

### 1. **Runtime smoke-test on real hardware** (highest priority)

Still the one thing CI can't do. Now FIVE platforms have unverified
runtime FFI: Android / Windows / **Linux** (new) — plus iOS. Grab a
release artifact (or `flutter run -d <device>`), open the calculator,
type `solve(x^2 - 1, x)`, expect `[-1, 1]`. `Error: requires native
library` means the binary didn't load — most likely a filename
mismatch between what Dart's `DynamicLibrary.open` passes and what
Flutter bundled.

- **Linux**: `flutter build linux` then run the bundle; Dart opens
  `libsymbolic_math_bridge.so` (bundled from `linux/Libraries/` via
  consumer-prebuilt mode). GLIBC baseline is 2.35 — older distros may
  refuse to load.
- **Windows**: the loader DLL-name mismatch flagged last revision is
  **fixed in bridge 1.2.1** (`535ce5d`, now pinned) —
  `_openNativeLibrary` tries `libsymbolic_math_bridge.dll` (the
  consumer-bundled wrapper) first, falling back to
  `symbolic_math_bridge_plugin.dll`. Reasoned-correct + non-regressive
  but **still wants a real Windows runtime check** to confirm.
- **Android / iOS**: as before.

If a runtime fail surfaces, iterate the bridge — add diagnostic
logging to `_openNativeLibrary()`, narrow it, push, re-pin, release.

### 2. **Android x86_64 (emulator) and armeabi-v7a (32-bit)**

Extend the `build-android.yml` matrix. Deferred-until-demand per the
workflow comment. Each ABI is its own ~15-min build slot.

### 3. **Carry-overs from prior sessions**

- Round 95 follow-up — Statistics input pre-fill.
- `open:` / `dsl:` dispatch in Try-in-Calculator (R99 followup).
- CSP Round E.5 — `dart_csp_fzn` CLI (blocked on P4).
- P9 follow-ups (A5d / A7 / A8) — 3D Scene polish.

### 4. **v0.4.1 — RELEASED (2026-05-29)**

Tagged `v0.4.1`, all 5 artifacts published. Linux tarball grew
13.2 → 19.9 MB (the bundled `.so`), confirming the R130 binary
shipped. Next release picks up FR/ES i18n + any hardware-smoke-test
fixes.

## Hygiene reminders

- **`dart format`** before push. Format only files you touched.
- **Don't run multiple `flutter test` in parallel** — they race
  on `.dart_tool/test/incremental_kernel_*`.
- **Don't touch `.claude/`** — harness state.
- **Working on main now.** Ask before starting a feature branch
  inside CrispCalc proper. Bridge plugin still uses feature
  branches per the multi-repo rule.
- **`flutter_symengine_*` symbol-not-found lines** in
  `flutter test` stderr are expected — the test VM doesn't load
  the plugin's compiled binaries. Bridge catches the failure;
  pure-Dart tests don't depend on it.

## Quick-reference paths

### CrispCalc (`/Volumes/backups/code/CrispCalc`)

- Calculator: `lib/screens/calculator_screen.dart`
- Notepad: `lib/screens/notepad_screen.dart`
- Help-mode infrastructure: `lib/widgets/help_target.dart`,
  `history_help_modal.dart`, `module_help_dialog.dart`,
  `calculator_keypad.dart` (popover maps)
- Function Reference catalog: `lib/engine/function_reference.dart`
  (45 entries)
- Step engine: `lib/engine/step_engine.dart`
- Localization: `lib/localization/app_localizations.dart`

### symbolic_math_bridge (`/Volumes/backups/code/symbolic_math_bridge`)

- `main` HEAD: `85bfa7e` (v1.1.0)
- `src/flutter_symengine_wrapper.{c,h}` — the 749-line C wrapper
  vendored from math-stack-ios-builder (same source for Android +
  Windows; iOS/macOS use prebuilt `.xcframework` bundles)
- `android/` — Gradle module + CMakeLists + Kotlin glue
- `windows/` — Flutter Windows plugin + CMakeLists + glue
- `.github/workflows/build-android.yml` + `build-windows.yml`
- `ANDROID_STATUS.md` + `WINDOWS_STATUS.md` — per-platform
  iteration history (essential context if R130 picks up)

### math-stack-ios-builder (`/Users/christianstrobele/code/math-stack-ios-builder`)

- Canonical iOS/macOS xcframework builder. Master branch
  `34ec0fdf`. Source-of-truth for `src/flutter_symengine_wrapper.c`
  (vendored into the bridge by R131 + R132).

Good luck.
