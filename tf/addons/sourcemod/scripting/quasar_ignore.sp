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
    name = "[QSR] Quasar Plugin Suite (Ignore)",
    author = PLUGIN_AUTHOR,
    description = "Allows players to ignore others text and voice chat.",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    
}

public void OnPluginStart()
{
    AutoExecConfig_SetFile("plugins.quasar_ignore");

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}