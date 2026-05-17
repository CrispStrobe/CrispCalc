# CrispCalc — CAS Calculator

A cross-platform scientific and graphing calculator built with Flutter. It
features an adaptive UI (mobile bottom-nav / desktop side-rail / wide-screen
split-view) and is powered by the SymEngine Computer Algebra System for
symbolic math.

Status: work in progress. It at least showcases how to set up a CAS wrapper
from Flutter to C++ and how to interact with Flutter's irksome TextField.

## Core Features

- **LaTeX display:** Textbook-style rendering of expressions and history via
  `flutter_math_fork`.
- **Symbolic CAS engine:** Algebra and calculus operations, not just numerical
  calculations.
  - Solver: `solve(x^2 - 4, x)` returns `x = {-2, 2}`.
  - Calculus: symbolic differentiation (`d/dx`). Integration and limits are
    UI-staged but not yet wired through to the native bridge — see Known
    Limitations.
  - Algebraic: `factor`, `expand`, `simplify`, `gcd`, `lcm`.
  - Numerics: `factorial`, `fibonacci`, constants `π`, `e`, `γ`.
- **Interactive graphing:** Y1..Y10 function slots, pan + pinch-to-zoom, axis
  labelling, curve sketching (Kurvendiskussion).
- **Adaptive layout:**
  - `< 720 px` — bottom navigation bar (mobile).
  - `720–1199 px` — side rail (tablets / narrow desktop windows).
  - `≥ 1200 px` — side rail plus a secondary pane so calculator + graph (or
    calculator + analysis) can be shown at the same time. Pick the right-pane
    content from the lower half of the rail.
- **Localization scaffolding:** English and German strings via a custom
  `AppLocalizations` (Flutter's i18n delegates are wired up but most strings
  are still in `EnLocalizations`).

## Architecture

Three layers:

1. **Flutter UI** (`lib/screens`, `lib/widgets`) — renders the keypad,
   captures input, displays results. No knowledge of FFI.
2. **`CalculatorEngine`** (`lib/engine/calculator_engine.dart`) — Dart facade
   over the `symbolic_math_bridge` plugin. Every method returns a `String` so
   the UI can treat errors and successes the same way. When the native bridge
   isn't loaded (e.g. under `flutter test` on the host), every method returns
   `'Error: <op> requires native library'` instead of crashing.
3. **`symbolic_math_bridge`** (separate package) — Flutter FFI plugin that
   wraps the SymEngine C API.

```mermaid
graph LR
    A[Flutter UI] --> B[CalculatorEngine]
    B --> C[symbolic_math_bridge / FFI]
    C --> D[SymEngine C++ library]
```

## Project layout

```
CrispCalc/
├── lib/
│   ├── main.dart                       # App entry, adaptive shell, settings
│   ├── controllers/
│   │   └── latex_controller.dart       # Cursor-aware LaTeX text controller
│   ├── engine/
│   │   ├── app_state.dart              # Singleton: history, variables, fns
│   │   ├── calculator_engine.dart      # Bridge facade
│   │   └── analysis_engine.dart        # Curve sketching pipeline
│   ├── localization/
│   │   └── app_localizations.dart      # i18n strings (en/de)
│   ├── screens/
│   │   ├── calculator_screen.dart      # Calc keypad + display
│   │   ├── graphing_screen.dart        # Plotter
│   │   ├── function_editor_screen.dart # Y= editor
│   │   ├── analysis_hub_screen.dart    # Module picker
│   │   ├── curve_analysis_input_screen.dart
│   │   ├── curve_analysis_results_screen.dart
│   │   └── matrix_editor_screen.dart
│   ├── utils/
│   │   ├── expression_preprocessing_utils.dart  # Implicit-* / mod / Y(x) inlining
│   │   ├── latex_conversion_utils.dart          # LaTeX <-> engine syntax
│   │   ├── math_display_utils.dart              # Result formatting
│   │   └── keyboard_input_handler.dart          # Hardware-keyboard mapping
│   └── widgets/
│       ├── calculator_keypad.dart      # Tabbed keypad
│       ├── calculator_button.dart      # Single key
│       ├── keypad_grid.dart            # Layout grid
│       ├── latex_input_field.dart      # Live LaTeX-rendered input
│       ├── function_picker_dialogs.dart
│       ├── memory_dialogs.dart
│       ├── progress_overlay.dart
│       ├── variable_viewer.dart
│       └── calculator_display.dart
├── test/                               # Unit tests (no native bridge needed)
├── PLAN.md                             # Open work items
├── HISTORY.md                          # Completed work log
└── pubspec.yaml
```

## Building and running

```bash
flutter pub get
flutter test            # 120+ unit tests run without the native bridge
flutter run             # Runs the app; SymEngine bridge required for math
```

The native side lives in the `symbolic_math_bridge` plugin (separate
repository / path-dependency). See its README for the SymEngine build.

## Known limitations

- `integrate()` and `limit()` are not yet implemented in the native bridge —
  the calculator surfaces an "Error: not yet implemented" message when you
  try to use them.
- Matrix entry via the dedicated editor works; running operations like `det`
  and `inv` depends on SymEngine being able to parse the `Matrix([...])`
  syntax we emit.
- High-precision evaluation (GMP/MPFR direct calls) is stubbed in the bridge
  and not yet wired into the engine.
- Localization covers tab labels and a few error strings; most user-facing
  text is still English.

See `PLAN.md` for the current punch list and `HISTORY.md` for what landed
recently.
