#include <sourcemod>
#include <sdktools>

#include <quasar/core>
#include <quasar/database>
#undef  MODULE_NAME
#define MODULE_NAME "Voting"

#include <autoexecconfig>

ConVar gH_CVR_useAFKSystem = null;

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Vote Handler)",
    author = PLUGIN_AUTHOR,
    description = "Description",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public void OnPluginStart()
{

}
