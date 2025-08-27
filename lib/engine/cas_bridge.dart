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
    final libraryPath = _getLibraryPath();
    print('Loading native library from: $libraryPath');
    
    try {
      final dylib = DynamicLibrary.open(libraryPath);

      evaluate = dylib
          .lookup<NativeFunction<_EvaluateC>>('evaluate')
          .asFunction<_EvaluateDart>();

      solve = dylib
          .lookup<NativeFunction<_SolveC>>('solve')
          .asFunction<_SolveDart>();

      free_string = dylib
          .lookup<NativeFunction<_FreeStringC>>('free_string')
          .asFunction<_FreeStringDart>();
          
      print('Native library loaded successfully');
    } catch (e) {
      throw Exception('Failed to load native library: $e');
    }
  }

  /// Comprehensive library path resolution for all deployment scenarios
  String _getLibraryPath() {
    final libName = _getLibraryName();
    print('Searching for native library: $libName');
    
    if (Platform.isMacOS) {
      return _findMacOSLibrary(libName);
    } else if (Platform.isLinux) {
      return _findLinuxLibrary(libName);
    } else if (Platform.isWindows) {
      return _findWindowsLibrary(libName);
    }
    
    throw Exception('Unsupported platform: ${Platform.operatingSystem}');
  }

  String _getLibraryName() {
    if (Platform.isMacOS) return 'libcas_wrapper.dylib';
    if (Platform.isLinux) return 'libcas_wrapper.so';
    if (Platform.isWindows) return 'cas_wrapper.dll';
    throw Exception('Unsupported platform');
  }

  String _findMacOSLibrary(String libName) {
    final searchPaths = <String>[];
    
    // Get the executable path for bundle-relative searches
    final executablePath = Platform.resolvedExecutable;
    final executableDir = Directory(executablePath).parent.path;
    
    // 1. Project root (for flutter run)
    searchPaths.add(libName);
    searchPaths.add('./$libName');
    
    // 2. Same directory as executable (for app bundle)
    searchPaths.add('$executableDir/$libName');
    
    // 3. macOS app bundle structure
    searchPaths.add('$executableDir/../Frameworks/$libName');
    searchPaths.add('$executableDir/../Resources/$libName');
    searchPaths.add('$executableDir/../MacOS/$libName');
    
    // 4. Relative to current working directory
    final workingDir = Directory.current.path;
    searchPaths.add('$workingDir/$libName');
    searchPaths.add('$workingDir/native/build/$libName');
    searchPaths.add('$workingDir/build/native/$libName');
    
    // 5. System library paths
    searchPaths.add('/usr/local/lib/$libName');
    searchPaths.add('/opt/homebrew/lib/$libName');
    
    return _findFirstExistingPath(searchPaths, libName);
  }

  String _findLinuxLibrary(String libName) {
    final searchPaths = <String>[
      libName,
      './$libName',
      './native/build/$libName',
      './build/native/$libName',
      '/usr/local/lib/$libName',
      '/usr/lib/$libName',
      '/lib/$libName',
    ];
    
    return _findFirstExistingPath(searchPaths, libName);
  }

  String _findWindowsLibrary(String libName) {
    final searchPaths = <String>[
      libName,
      '.\\$libName',
      '.\\native\\build\\$libName',
      '.\\build\\native\\$libName',
    ];
    
    return _findFirstExistingPath(searchPaths, libName);
  }

  String _findFirstExistingPath(List<String> searchPaths, String libName) {
    final checkedPaths = <String>[];
    
    for (final path in searchPaths) {
      try {
        final normalizedPath = _normalizePath(path);
        checkedPaths.add(normalizedPath);
        
        final file = File(normalizedPath);
        if (file.existsSync()) {
          final absolutePath = file.absolute.path;
          print('Found native library at: $absolutePath');
          
          // Verify the file is readable and not empty
          final stat = file.statSync();
          if (stat.size > 0) {
            return absolutePath;
          } else {
            print('Warning: Library file is empty: $absolutePath');
          }
        }
      } catch (e) {
        // Continue searching if this path fails
        print('Error checking path $path: $e');
        continue;
      }
    }
    
    // Enhanced error message with all checked paths
    final errorMessage = '''
Native library ($libName) not found in any of the following locations:
${checkedPaths.map((p) => '  • $p').join('\n')}

To fix this issue:
1. Build the native library: cd native && mkdir -p build && cd build && cmake .. && make
2. Copy to project root: cp libcas_wrapper.dylib ../../
3. Or run the bundle script: ./bundle_native_lib.sh

Current working directory: ${Directory.current.path}
Executable path: ${Platform.resolvedExecutable}
''';
    
    throw Exception(errorMessage);
  }

  String _normalizePath(String path) {
    // Convert relative paths to absolute and handle path separators
    if (path.startsWith('./') || path.startsWith('.\\')) {
      return '${Directory.current.path}${Platform.pathSeparator}${path.substring(2)}';
    }
    
    if (!path.startsWith('/') && !path.contains(':')) {
      // Relative path
      return '${Directory.current.path}${Platform.pathSeparator}$path';
    }
    
    return path;
  }
}