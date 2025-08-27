/// lib/engine/cas_bridge.dart:

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// --- C function signatures ---
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
    if (Platform.isMacOS) {
      // For macOS app bundles, try the bundle path first
      try {
        // Try app bundle paths
        final bundlePaths = [
          'libcas_wrapper.dylib', // Relative to app
          './libcas_wrapper.dylib',
        ];
        
        for (final path in bundlePaths) {
          if (File(path).existsSync()) {
            print('Found native library at: $path');
            return path;
          }
        }
        
        // Fallback - for now, just throw the exception to use fallback
        throw Exception('Library not found in app bundle');
      } catch (e) {
        print('Native library search failed: $e');
        rethrow;
      }
    }
    
    // Default fallback for other platforms
    throw Exception('Platform not supported for native library');
  }
}