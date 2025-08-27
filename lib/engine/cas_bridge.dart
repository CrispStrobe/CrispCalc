/// lib/engine/cas_bridge.dart:

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// --- C function signatures ---
// Note: Pointer<Utf8> is used for C-style strings (char*).
typedef _EvaluateC = Pointer<Utf8> Function(Pointer<Utf8> expression);
typedef _SolveC = Pointer<Utf8> Function(Pointer<Utf8> expression, Pointer<Utf8> symbol);
typedef _FreeStringC = Void Function(Pointer<Utf8> str);

// --- Dart function signatures ---
typedef _EvaluateDart = Pointer<Utf8> Function(Pointer<Utf8> expression);
typedef _SolveDart = Pointer<Utf8> Function(Pointer<Utf8> expression, Pointer<Utf8> symbol);
typedef _FreeStringDart = void Function(Pointer<Utf8> str);

/// A bridge class that loads and interacts with the native C++ CAS library.
class CASBridge {
  late final _EvaluateDart evaluate;
  late final _SolveDart solve;
  late final _FreeStringDart free_string;

  CASBridge() {
    final dylib = DynamicLibrary.open(_getLibraryPath());

    evaluate = dylib
        .lookup<NativeFunction<_EvaluateC>>('evaluate')
        .asFunction<_EvaluateDart>();

    solve = dylib
        .lookup<NativeFunction<_SolveC>>('solve')
        .asFunction<_SolveDart>();

    free_string = dylib
        .lookup<NativeFunction<_FreeStringC>>('free_string')
        .asFunction<_FreeStringDart>();
  }

  /// Helper to find the correct library file based on the operating system.
  String _getLibraryPath() {
    if (Platform.isMacOS || Platform.isIOS) {
      // NOTE: For iOS, you typically link against a framework.
      // This might require a different path or setup.
      return 'libcas_wrapper.dylib';
    }
    if (Platform.isWindows) {
      return 'cas_wrapper.dll';
    }
    // Default for Android and Linux.
    return 'libcas_wrapper.so';
  }
}