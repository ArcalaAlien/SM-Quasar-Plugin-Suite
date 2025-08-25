#include <sourcemod>

#include <quasar/core>
#include <quasar/calendar>

#include <autoexecconfig>

// Core Variables
Database gH_db = null;
File     gH_logFile = null;
bool     gB_late = false;

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Calendar)",
    author = PLUGIN_AUTHOR,
    description = "Keeps track of server time and allows for date-based events.",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    
}

public void OnPluginStart()
{
    AutoExecConfig_SetFile("plugins.quasar_calendar");

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}