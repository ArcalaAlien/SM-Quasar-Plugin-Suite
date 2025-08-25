#include <sourcemod>

#include <quasar/core>
#include <quasar/plugin>

#include <autoexecconfig>

// Core Variables
Database gH_db = null;
File     gH_logFile = null;
bool     gB_late = false;

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Template)",
    author = PLUGIN_AUTHOR,
    description = "Description",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    
}

public void OnPluginStart()
{
    AutoExecConfig_SetFile("plugins.quasar_plugin");

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}