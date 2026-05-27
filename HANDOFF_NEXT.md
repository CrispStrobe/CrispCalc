# CrispCalc — handover for the next session

Pickup note from the **2026-05-27 (v0.4.0 cut session)**. This
session was a multi-arc landing run — the P6 help-popover sweep
PLUS the P11 cross-platform SymEngine bridge work. v0.4.0 ships
full SymEngine on iOS / macOS / **Android arm64-v8a** / **Windows
x86_64**.

## ⚠ Working-mode change (unchanged)

**Parallel-arc work is paused.** All edits go **directly on `main`**
in `/Volumes/backups/code/CrispCalc`. The bridge plugin work
happens on its own feature branches in
`/Volumes/backups/code/symbolic_math_bridge` per the multi-repo
arc rule (see `memory/feedback_multi_repo_arc_worktree.md`).

## State

| | |
|---|---|
| **Main worktree** | `/Volumes/backups/code/CrispCalc` (branch `main`) |
| **main HEAD** | (TBD — v0.4.0 commit + tag |
| **Tests** | **1992 pass** (1965 → 1992 across the help-popover arc); bridge pin bump doesn't change test surface |
| **dart_csp pin** | `69a9cfb` (unchanged) |
| **bridge pin** | **`85bfa7e`** (bridge 1.1.0 — adds Android + Windows binaries) — was `505074d` |

## This session — major arcs landed

### Arc A: P6 help-popover sweep (rounds 103 + 102b + 104 + 104b + 105)

Calculator history rows (R103), CAS-tab keypad buttons (R102b —
Adv was already in R102), Notepad lines (R104 + R104b), and
per-module explainers on all 8 Analyze-hub screens (R105). All
shipped, all green, all in v0.3.0 (tagged earlier this session
at commit `c226d91`). Tests grew 1965 → 1992. See HISTORY entries
for detail.

### Arc B: P11 cross-platform SymEngine bridge (R131 + R132)

The bigger lift. Closes the platform-support gap the P6 help arc
made visible — "Computed via SymEngine.X" now actually computes
on Android and Windows.

- **R132 Android arm64-v8a**: 7 CI iterations. vcpkg + NDK
  cross-compile via `VCPKG_CHAINLOAD_TOOLCHAIN_FILE`. `.so`
  committed to bridge.
- **R131 Windows x86_64**: vcpkg+MSVC dead-ended at GHA's 6-hour
  Windows runner cap (6 attempts cancelled). Pivoted to
  MSYS2/MinGW64 — flint/mpfr/gmp/mpc/boost pre-built via pacman,
  only SymEngine compiled from source. 4 iterations to green;
  `.dll` committed to bridge.

Bridge merged to main as v1.1.0 (commit `85bfa7e`). CrispCalc
pubspec.yaml `ref` bumped accordingly.

## What's open / next session pickup

### 1. **Smoke-test on actual Android device + Windows desktop** (highest priority)

The R131 + R132 binaries are confirmed at the
compile/link/symbols-in-export-table level by CI. They have NOT
been verified end-to-end: load DLL, invoke a `flutter_symengine_*`
function, observe real output. Two paths:

- **Local manual test**: build CrispCalc for Android on an
  emulator or device; invoke `solve(x^2 - 1, x)` from the calculator;
  expect `[-1, 1]` not `Error: requires native library`.
- Same for Windows: `flutter build windows`, run, exercise the
  calculator.

If a runtime fail surfaces (most likely cause: a transitive
function the wrapper expects isn't actually exported by our DLL),
the iteration is to add the missing symbol to `force_link.c` +
re-run the bridge workflow.

### 2. **R130 — Linux SymEngine build**

The remaining tier-1 platform. Documented in `PLAN.md` P11. Should
mirror the Android pattern closely — same `ubuntu-latest` runner,
same vcpkg dance, but no NDK chainload needed (host IS Linux). 1
day of work; ~5-10 min cold-cache CI build expected.

### 3. **Android x86_64 (emulator) and armeabi-v7a (32-bit)**

Extend the `build-android.yml` matrix. Useful when somebody tests
in an x86 emulator or owns an older phone. Each ABI is its own
~15-min build slot.

### 4. **Strip ARB references from CrispCalc** (cleanup)

While dropping `arb` from the symengine vcpkg port was the right
move (it transitively re-pulled LLVM), CrispCalc has no calls
into ARB-only SymEngine APIs (verified). Nothing to remove
code-side; just verify HISTORY/PLAN entries don't claim we use ARB
anywhere.

### 5. **Carry-overs from prior sessions**

All from the v0.3.0 HANDOFF; none affected by this session:

- Round 100 — Function Reference i18n pass (~30k words). Still
  pending. Now the highest-leverage UI-side open item.
- Round 105b — Per-element popovers inside Statistics /
  Constraints DSL / Sudoku.
- Round 95 follow-up — Statistics input pre-fill.
- `open:` / `dsl:` dispatch in Try-in-Calculator (R99 followup).
- CSP Round E.5 — `dart_csp_fzn` CLI (blocked on P4).
- P9 follow-ups (A5d / A7 / A8) — 3D Scene polish.

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
