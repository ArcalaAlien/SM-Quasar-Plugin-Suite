#include <sourcemod>
#include <sdktools>

#include <quasar/core>

#include <umc-core>
#include <umc_utils>
#include <autoexecconfig>

bool gB_UMCLoaded = false;
bool gB_late      = false;

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Map Rating/Feedback Handler)",
    author = PLUGIN_AUTHOR,
    description = "Description",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (LibraryExists("umccore"))
    {
        gB_UMCLoaded = true;
    }

    gB_late = late;
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_maplist");
    RegConsoleCmd("sm_maps");

    RegConsoleCmd("sm_rate");
}

public void OnMapStart()
{
    
}

public void OnMapEnd()
{
    
}