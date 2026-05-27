//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <symbolic_math_bridge/symbolic_math_bridge_plugin_c_api.h>
#include <url_launcher_windows/url_launcher_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  SymbolicMathBridgePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SymbolicMathBridgePluginCApi"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}
