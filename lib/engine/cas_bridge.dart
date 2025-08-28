/// lib/engine/cas_bridge.dart

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef _CallStringOpC = Pointer<Utf8> Function(Pointer<Utf8> expression);
typedef _SolveC = Pointer<Utf8> Function(Pointer<Utf8> expression, Pointer<Utf8> symbol);
typedef _FreeStringC = Void Function(Pointer<Utf8> str);

typedef _CallStringOpDart = Pointer<Utf8> Function(Pointer<Utf8> expression);
typedef _SolveDart = Pointer<Utf8> Function(Pointer<Utf8> expression, Pointer<Utf8> symbol);
typedef _FreeStringDart = void Function(Pointer<Utf8> str);

class CASBridge {
  late final _CallStringOpDart evaluate;
  late final _SolveDart solve;
  late final _FreeStringDart free_string;
  late final _CallStringOpDart factor;
  late final _CallStringOpDart expand;

  CASBridge() {
    final libraryPath = _getLibraryPath();
    final dylib = DynamicLibrary.open(libraryPath);

    // FIX: All lookups now point to the correct C++ function names.
    evaluate = dylib.lookup<NativeFunction<_CallStringOpC>>('evaluate').asFunction<_CallStringOpDart>();
    solve = dylib.lookup<NativeFunction<_SolveC>>('solve').asFunction<_SolveDart>();
    free_string = dylib.lookup<NativeFunction<_FreeStringC>>('free_string').asFunction<_FreeStringDart>();
    factor = dylib.lookup<NativeFunction<_CallStringOpC>>('cas_factor').asFunction<_CallStringOpDart>();
    expand = dylib.lookup<NativeFunction<_CallStringOpC>>('cas_expand').asFunction<_CallStringOpDart>();
  }

  String _getLibraryPath() {
    if (Platform.isMacOS) return _findMacOSLibrary('libcas_wrapper.dylib');
    if (Platform.isLinux) return _findLinuxLibrary('libcas_wrapper.so');
    if (Platform.isWindows) return _findWindowsLibrary('cas_wrapper.dll');
    throw Exception('Unsupported platform');
  }

  String _findMacOSLibrary(String libName) {
    // Path for local development via `flutter run`
    final devPath = File(libName);
    if (devPath.existsSync()) {
      print('✅ Found native library for development at: ${devPath.absolute.path}');
      return devPath.path;
    }

    // Path for bundled application
    final bundlePath = File.fromUri(Uri.file(Platform.resolvedExecutable).resolve('../Frameworks/$libName'));
    if (bundlePath.existsSync()) {
      print('✅ Found native library in app bundle at: ${bundlePath.path}');
      return bundlePath.path;
    }

    throw Exception('''
❌ FATAL: Native library "$libName" not found.

Checked Locations:
  • Development: ${devPath.absolute.path}
  • App Bundle: ${bundlePath.path}

Ensure you have run the bundling script:
👉 ./bundle_symengine.sh
''');
  }

  // Basic search for other platforms
  String _findLinuxLibrary(String libName) {
    // Implement a simple search or assume it's in a standard location
    final devPath = File(libName);
    if (devPath.existsSync()) return devPath.path;
    throw Exception('Linux library "$libName" not found.');
  }

  String _findWindowsLibrary(String libName) {
    // Implement a simple search or assume it's in a standard location
    final devPath = File(libName);
    if (devPath.existsSync()) return devPath.path;
    throw Exception('Windows library "$libName" not found.');
  }
}