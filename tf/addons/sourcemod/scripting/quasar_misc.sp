#include <sourcemod>
#include <clientprefs>
#include <tf2>
#include <sdktools>
#include <sdkhooks>

#include <quasar/core>
#undef  MODULE_NAME
#define MODULE_NAME "Misc"

#include <quasar/players>
#include <quasar/misc>
#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#include <SteamWorks>

// Core
QSRChatFormat    gST_chatFormatting;
QSRGeneralSounds gST_sounds;
File gH_logFile = null;
bool gB_late = false;
int  gI_moduleFlags = MISCMOD_NONE;

//  Libraries
bool gB_SteamWorks = false;

// Bread
ArrayList gH_breadSpawnedArray = null;
int gI_breadCount = 0;

// Spawn Protection
QSRSpInfo gST_playerSPInfo[MAXPLAYERS + 1];

// Third Person
QSRPov gST_playerPOVs[MAXPLAYERS + 1];

// FOV
int gI_playerFOV[MAXPLAYERS+1];

// Friendly
bool gB_isFriendly[MAXPLAYERS + 1];

//* FORWARDS */

// Bread
Handle gH_FWD_onBreadSpawnedPre         = INVALID_HANDLE;
Handle gH_FWD_onBreadSpawned            = INVALID_HANDLE;

// Spawn Protection
Handle gH_FWD_onProtectedPlayerHurt     = INVALID_HANDLE;
Handle gH_FWD_onPlayerToggleSP          = INVALID_HANDLE;
Handle gH_FWD_onPlayerGrantedSPPre      = INVALID_HANDLE;
Handle gH_FWD_onPlayerGrantedSP         = INVALID_HANDLE;
Handle gH_FWD_onPlayerLoseSPPre         = INVALID_HANDLE;
Handle gH_FWD_onPlayerLoseSP            = INVALID_HANDLE;

// Respawn Time
Handle gH_FWD_onChangedRespawnTime      = INVALID_HANDLE;
Handle gH_FWD_onPlayerWaitForRespawn    = INVALID_HANDLE;
Handle gH_FWD_onPlayerRespawned         = INVALID_HANDLE;

// Third Person
Handle gH_FWD_onChangePOV               = INVALID_HANDLE;     

// FOV
Handle gH_FWD_onChangeFOV               = INVALID_HANDLE;

// Friendly
Handle gH_FWD_onChangedFriendlyState    = INVALID_HANDLE;
Handle gH_FWD_onFriendlyPlayerHurt      = INVALID_HANDLE;

//* CONVARS */
ConVar gH_CVR_disableFallDamage         = null;
ConVar gH_CVR_disableFallDamageNoise    = null;
ConVar gH_CVR_useSpawnProtection        = null;
ConVar gH_CVR_useAutoRestart            = null;
ConVar gH_CVR_useCustomRespawnTimes     = null;
ConVar gH_CVR_useThirdPerson            = null;
ConVar gH_CVR_useFriendly               = null;
ConVar gH_CVR_teleportBread             = null;
ConVar gH_CVR_breadPerTele              = null;
ConVar gH_CVR_totalAmountOfBread        = null;
ConVar gH_CVR_breadLifetime             = null;
ConVar gH_CVR_breadChance               = null;
ConVar gH_CVR_spawnProtectionLength     = null;
ConVar gH_CVR_spawnProtectionColor      = null;
ConVar gH_CVR_respawnTimeMinimum        = null;
ConVar gH_CVR_respawnTimeMaximum        = null;
ConVar gH_CVR_respawnTimeDefault        = null;
ConVar gH_CVR_skipEndingScoreboard      = null;

//* COOKIES */
Cookie gH_CK_autoEnableFriendly         = null;
Cookie gH_CK_autoEnableSP               = null;
Cookie gH_CK_usingCustomRespawn         = null;
Cookie gH_CK_customRespawnLength        = null;
Cookie gH_CK_autoEnableTP               = null;

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Misc Functions)",
    author = PLUGIN_AUTHOR,
    description = "A plugin full of miscellaneous functions and features.",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // General
    CreateNative("QSR_UsingMiscModule", Native_QSRUsingMiscModule);

    // Bread
    CreateNative("QSR_SpawnBreadAtPlayer",      Native_QSRSpawnBreadAtPlayer);

    // Spawn Protection
    CreateNative("QSR_PlayerEnabledSP",         Native_QSRPlayerEnabledSP);
    CreateNative("QSR_IsPlayerProtected",       Native_QSRIsPlayerProtected);
    CreateNative("QSR_ToggleSpawnProtection",   Native_QSRToggleSpawnProtection);
    CreateNative("QSR_GrantSpawnProtection",    Native_QSRGrantSpawnProtection);
    CreateNative("QSR_RemoveSpawnProtection",   Native_QSRRemoveSpawnProtection);
    
    // Respawn Time
    CreateNative("QSR_PlayerHasCRespawnTime",   Native_QSRPlayerHasCRespawnTime)
    CreateNative("QSR_GetPlayerCRespawnTime",   Native_QSRGetPlayerCRespawnTime);
    CreateNative("QSR_SetPlayerCRespawnTime",   Native_QSRSetPlayerCRespawnTime);
    CreateNative("QSR_GetRespawnTimeLeft",      Native_QSRGetRespawnTimeLeft);
    CreateNative("QSR_IsPlayerRespawning",      Native_QSRIsPlayerRespawning);
    CreateNative("QSR_ForcePlayerRespawn",      Native_QSRForcePlayerRespawn);

    // Third/First Person
    CreateNative("QSR_GetPlayerPOV",            Native_QSRGetPlayerPOV);
    CreateNative("QSR_SetPlayerPOV",            Native_QSRSetPlayerPOV);

    // FOV
    CreateNative("QSR_GetPlayerFOV",            Native_QSRGetPlayerFOV);
    CreateNative("QSR_SetPlayerFOV",            Native_QSRSetPlayerFOV);

    // Friendly
    CreateNative("QSR_IsPlayerFriendly",        Native_QSRIsPlayerFriendly);
    CreateNative("QSR_SetPlayerFriendlyState",  Native_QSRSetPlayerFriendlyState);

    gB_late = late;
}

public void OnPluginStart()
{
    // Handle Forwards
    gH_FWD_onBreadSpawnedPre        = CreateGlobalForward("QSR_OnBreadSpawned_Pre",     ET_Hook,    Param_CellByRef);
    gH_FWD_onBreadSpawned           = CreateGlobalForward("QSR_OnBreadSpawned",         ET_Ignore,  Param_Cell)
    gH_FWD_onChangePOV              = CreateGlobalForward("QSR_OnPlayerChangePOV",      ET_Ignore,  Param_Cell, Param_Cell, Param_Cell);
    gH_FWD_onChangedFriendlyState   = CreateGlobalForward("QSR_OnChangedFriendlyState", ET_Ignore,  Param_Cell, Param_Cell, Param_Cell);
    gH_FWD_onChangedRespawnTime     = CreateGlobalForward("QSR_OnChangedRespawnTime",   ET_Ignore,  Param_Cell, Param_Cell, Param_Cell);
    gH_FWD_onFriendlyPlayerHurt     = CreateGlobalForward("QSR_OnFriendlyPlayerHurt",   ET_Ignore,  Param_Cell, Param_Cell, Param_Cell);
    gH_FWD_onPlayerGrantedSP        = CreateGlobalForward("QSR_OnPlayerGrantedSP",      ET_Ignore,  Param_Cell);
    gH_FWD_onPlayerGrantedSPPre     = CreateGlobalForward("QSR_OnPlayerGrantedSP_Pre",  ET_Hook,    Param_Cell);
    gH_FWD_onPlayerLoseSP           = CreateGlobalForward("QSR_OnPlayerLoseSP",         ET_Ignore,  Param_Cell);
    gH_FWD_onPlayerLoseSPPre        = CreateGlobalForward("QSR_OnPlayerLoseSP_Pre",     ET_Hook,    Param_Cell);
    gH_FWD_onPlayerRespawned        = CreateGlobalForward("QSR_OnPlayerRespawned",      ET_Ignore,  Param_Cell, Param_Cell);
    gH_FWD_onPlayerToggleSP         = CreateGlobalForward("QSR_OnPlayerToggleSP",       ET_Ignore,  Param_Cell, Param_Cell, Param_Cell);
    gH_FWD_onPlayerWaitForRespawn   = CreateGlobalForward("QSR_OnPlayerWaitForRespawn", ET_Hook,    Param_Cell, Param_Cell, Param_CellByRef);
    gH_FWD_onProtectedPlayerHurt    = CreateGlobalForward("QSR_OnProtectedPlayerHurt",  ET_Ignore,  Param_Cell, Param_Cell, Param_Cell);

    // Handle ConVars
    AutoExecConfig_SetFile("plugins.quasar_misc");

    gH_CVR_disableFallDamage        = AutoExecConfig_CreateConVar("sm_quasar_misc_disable_fall_damage",         "0",                "");
    gH_CVR_disableFallDamageNoise   = AutoExecConfig_CreateConVar("sm_quasar_misc_disable_fall_damage_noise",   "1",                "");
    gH_CVR_useSpawnProtection       = AutoExecConfig_CreateConVar("sm_quasar_misc_spawn_protection_enabled",    "1",                "");
    gH_CVR_useAutoRestart           = AutoExecConfig_CreateConVar("sm_quasar_misc_auto_restart_enabled",        "1",                "");
    gH_CVR_useCustomRespawnTimes    = AutoExecConfig_CreateConVar("sm_quasar_misc_allow_custom_respawn_times",  "1",                "");
    gH_CVR_useThirdPerson           = AutoExecConfig_CreateConVar("sm_quasar_misc_third_person_enabled",        "1",                "");
    gH_CVR_useFriendly              = AutoExecConfig_CreateConVar("sm_quasar_misc_friendly_enabled",            "1",                "");
    gH_CVR_teleportBread            = AutoExecConfig_CreateConVar("sm_quasar_misc_teleport_bread",              "1",                "");
    gH_CVR_breadPerTele             = AutoExecConfig_CreateConVar("sm_quasar_misc_bread_per_tele",              "2",                "");
    gH_CVR_totalAmountOfBread       = AutoExecConfig_CreateConVar("sm_quasar_misc_total_bread_allowed",         "24",               "");
    gH_CVR_breadLifetime            = AutoExecConfig_CreateConVar("sm_quasar_misc_bread_lifetime",              "3.0",              "");
    gH_CVR_breadChance              = AutoExecConfig_CreateConVar("sm_quasar_misc_bread_chance",                "100",              "");
    gH_CVR_spawnProtectionLength    = AutoExecConfig_CreateConVar("sm_quasar_misc_spawn_protection_length",     "5.0",              "");
    gH_CVR_spawnProtectionColor     = AutoExecConfig_CreateConVar("sm_quasar_misc_spawn_protection_color",      "120 255 120 120",  "");
    gH_CVR_respawnTimeMinimum       = AutoExecConfig_CreateConVar("sm_quasar_misc_respawn_time_minimum",        "0",                "");
    gH_CVR_respawnTimeMaximum       = AutoExecConfig_CreateConVar("sm_quasar_misc_respawn_time_maximum",        "0",                "");
    gH_CVR_respawnTimeDefault       = AutoExecConfig_CreateConVar("sm_quasar_misc_respawn_time_default",        "-1",               "");
    gH_CVR_skipEndingScoreboard     = AutoExecConfig_CreateConVar("sm_quasar_misc_skip_scoreboard",             "1",                "Skips the ending scoreboard allowing for quicker map transitions.");

    gH_CVR_disableFallDamage.AddChangeHook(OnConVarChanged);
    gH_CVR_disableFallDamageNoise.AddChangeHook(OnConVarChanged);
    gH_CVR_useSpawnProtection.AddChangeHook(OnConVarChanged);
    gH_CVR_useAutoRestart.AddChangeHook(OnConVarChanged);
    gH_CVR_useCustomRespawnTimes.AddChangeHook(OnConVarChanged);
    gH_CVR_useThirdPerson.AddChangeHook(OnConVarChanged);
    gH_CVR_useFriendly.AddChangeHook(OnConVarChanged);
    gH_CVR_teleportBread.AddChangeHook(OnConVarChanged);

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    // Handle Cookies
    gH_CK_autoEnableFriendly    = new Cookie("sm_quasar_misc_auto_enable_friendly", "Auto enable friendly mode on spawn?", CookieAccess_Public);
    gH_CK_autoEnableSP          = new Cookie("sm_quasar_misc_auto_enable_sp",       "Auto enable spawn protection on spawn?", CookieAccess_Public);
    gH_CK_autoEnableTP          = new Cookie("sm_quasar_misc_auto_enable_tp",       "Auto enable third person on spawn?", CookieAccess_Public);
    gH_CK_customRespawnLength   = new Cookie("sm_quasar_misc_respawn_length",       "How long is this player's respawn time? 0 - Instant, -1 - Server Default", CookieAccess_Public);
    gH_CK_usingCustomRespawn    = new Cookie("sm_quasar_misc_using_custom_respawn", "User set thier own respawn time.", CookieAccess_Public);

    RegConsoleCmd("sm_qmisc", CMD_MiscellaneousMenu, "Use this to open the misc. functions menu!");

    HookEvent("player_spawn", Event_OnPlayerSpawn);
    HookEvent("player_hurt", Event_OnPlayerHurt);
    HookEvent("player_teleported", Event_OnPlayerTeleported);
}

public void OnPluginEnd()
{
    gH_CK_autoEnableFriendly.Close();
    gH_CK_autoEnableSP.Close();
    gH_CK_autoEnableTP.Close();
    gH_CK_customRespawnLength.Close();
    gH_CK_usingCustomRespawn.Close();

    gH_CVR_breadChance.Close();
    gH_CVR_totalAmountOfBread.Close();
    gH_CVR_breadPerTele.Close();
    gH_CVR_breadLifetime.Close();
    gH_CVR_disableFallDamage.Close();
    gH_CVR_disableFallDamageNoise.Close();
    gH_CVR_respawnTimeDefault.Close();
    gH_CVR_respawnTimeMaximum.Close();
    gH_CVR_respawnTimeMinimum.Close();
    gH_CVR_spawnProtectionColor.Close();
    gH_CVR_spawnProtectionLength.Close();
    gH_CVR_teleportBread.Close();
    gH_CVR_useAutoRestart.Close();
    gH_CVR_useCustomRespawnTimes.Close();
    gH_CVR_useFriendly.Close();
    gH_CVR_useSpawnProtection.Close();
    gH_CVR_useThirdPerson.Close();
    gH_CVR_skipEndingScoreboard.Close();

    gH_FWD_onBreadSpawned.Close();
    gH_FWD_onBreadSpawnedPre.Close();
    gH_FWD_onChangePOV.Close();
    gH_FWD_onChangedFriendlyState.Close();
    gH_FWD_onChangedRespawnTime.Close();
    gH_FWD_onFriendlyPlayerHurt.Close();
    gH_FWD_onPlayerGrantedSP.Close();
    gH_FWD_onPlayerGrantedSPPre.Close();
    gH_FWD_onPlayerLoseSP.Close();
    gH_FWD_onPlayerLoseSPPre.Close();
    gH_FWD_onPlayerRespawned.Close();
    gH_FWD_onPlayerToggleSP.Close();
    gH_FWD_onPlayerWaitForRespawn.Close();
    gH_FWD_onProtectedPlayerHurt.Close();
}

public void OnConfigsExecuted()
{
    if (gH_CVR_useSpawnProtection.BoolValue)
    {
        gI_moduleFlags |= MISCMOD_SP;
        RegConsoleCmd("sm_sp", CMD_SpawnProtection, "Use this to enable / disable spawn protection!");
        RegConsoleCmd("sm_spawnprotection", CMD_SpawnProtection, "Use this to enable / disable spawn protection!");
    }

    if (gH_CVR_useCustomRespawnTimes.BoolValue)
    {
        gI_moduleFlags |= MISCMOD_CRT;
        RegConsoleCmd("sm_kc", CMD_RespawnTime);
        RegConsoleCmd("sm_killcam", CMD_RespawnTime);
        RegConsoleCmd("sm_spawntime", CMD_RespawnTime);
        RegConsoleCmd("sm_respawntime", CMD_RespawnTime);
        RegConsoleCmd("sm_rst", CMD_RespawnTime);
    }

    if (gH_CVR_useThirdPerson.BoolValue)
    {
        gI_moduleFlags |= MISCMOD_TP;
        RegConsoleCmd("sm_tp", CMD_ThirdPerson);
        RegConsoleCmd("sm_fp", CMD_ThirdPerson);
        RegConsoleCmd("sm_3", CMD_ThirdPerson);
        RegConsoleCmd("sm_1", CMD_ThirdPerson);
        RegConsoleCmd("sm_firstperson", CMD_ThirdPerson);
        RegConsoleCmd("sm_thirdperson", CMD_ThirdPerson);
    }

    if (gH_CVR_useFriendly.BoolValue)
    {
        gI_moduleFlags |= MISCMOD_FRIENDLY;
        RegConsoleCmd("sm_friendly", CMD_Friendly);
        RegConsoleCmd("sm_friend", CMD_Friendly);
        RegConsoleCmd("sm_fr", CMD_Friendly);
    }

    if (gH_CVR_useAutoRestart.BoolValue && gB_SteamWorks)   { gI_moduleFlags |= MISCMOD_AR; }
    
    if (gH_CVR_teleportBread.BoolValue)                     
    { 
        gI_moduleFlags |= MISCMOD_BREAD; 
        
        char s_breadPath[PLATFORM_MAX_PATH];
        for (int i = 1; i < 10; i++)
        {
            QSR_BreadEnumToModel(view_as<QSRBreadModel>(i), s_breadPath, sizeof(s_breadPath));
            PrecacheModel(s_breadPath);
        }

        if (gH_breadSpawnedArray != null)
        {
            gH_breadSpawnedArray = new ArrayList();
        }
        else
        {
            QSR_ClearBreadArray();
            gH_breadSpawnedArray = new ArrayList();
        }
    }

    if (gH_CVR_disableFallDamage.BoolValue)                 { gI_moduleFlags |= MISCMOD_NOFALL; }
    if (gH_CVR_disableFallDamageNoise.BoolValue)            { gI_moduleFlags |= MISCMOD_NOFALLNOISE; }
}

public void OnMapEnd()
{
    QSR_ClearBreadArray();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    // Misc Module enabled
    if      (convar == gH_CVR_disableFallDamage      && (StringToInt(newValue) == 1 || StrEqual(newValue, "true", false)))                   { gI_moduleFlags |= MISCMOD_NOFALL; }
    else if (convar == gH_CVR_disableFallDamageNoise && (StringToInt(newValue) == 1 || StrEqual(newValue, "true", false)))                   { gI_moduleFlags |= MISCMOD_NOFALLNOISE; }
    else if (convar == gH_CVR_teleportBread          && (StringToInt(newValue) == 1 || StrEqual(newValue, "true", false)))                   { gI_moduleFlags |= MISCMOD_BREAD; }
    else if (convar == gH_CVR_useAutoRestart         && (StringToInt(newValue) == 1 || StrEqual(newValue, "true", false)) && gB_SteamWorks)  { gI_moduleFlags |= MISCMOD_AR; }
    else if (convar == gH_CVR_useCustomRespawnTimes  && (StringToInt(newValue) == 1 || StrEqual(newValue, "true", false)))                   { gI_moduleFlags |= MISCMOD_CRT; }
    else if (convar == gH_CVR_useFriendly            && (StringToInt(newValue) == 1 || StrEqual(newValue, "true", false)))                   { gI_moduleFlags |= MISCMOD_FRIENDLY; }
    else if (convar == gH_CVR_useSpawnProtection     && (StringToInt(newValue) == 1 || StrEqual(newValue, "true", false)))                   { gI_moduleFlags |= MISCMOD_SP; }
    else if (convar == gH_CVR_useThirdPerson         && (StringToInt(newValue) == 1 || StrEqual(newValue, "true", false)))                   { gI_moduleFlags |= MISCMOD_TP; }

    // Misc Module disabled.
    else if (convar == gH_CVR_disableFallDamage      && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_NOFALL; }
    else if (convar == gH_CVR_disableFallDamageNoise && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_NOFALLNOISE; }
    else if (convar == gH_CVR_teleportBread          && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_BREAD; }
    else if (convar == gH_CVR_useAutoRestart         && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_AR; }
    else if (convar == gH_CVR_useCustomRespawnTimes  && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_CRT; }
    else if (convar == gH_CVR_useFriendly            && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_FRIENDLY; }
    else if (convar == gH_CVR_useSpawnProtection     && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_SP; }
    else if (convar == gH_CVR_useThirdPerson         && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_TP; }
}

public void OnMapStart()
{
    if (GetExtensionFileStatus("SteamWorks.ext") < 1) { gB_SteamWorks = false; }
    else                                              { gB_SteamWorks = true;  }
}

void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int i_player = event.GetInt("userid"),
        i_client = GetClientOfUserId(i_player);

    if (gH_CVR_useSpawnProtection.BoolValue)
    {
        if (QSR_PlayerEnabledSP(i_player))
        {
            QSR_GrantSpawnProtection(i_player);
            gST_playerSPInfo[i_client].h_protectionTimer = CreateTimer(0.1, Timer_SpawnProtectionHandler, i_player, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int i_victim    = event.GetInt("userid"),
        i_attacker  = event.GetInt("attacker"),
        i_damage    = event.GetInt("damageamount");

    if (gH_CVR_useFriendly.BoolValue)
    {
        if (QSR_IsPlayerFriendly(i_victim))
        {
            Call_StartForward(gH_FWD_onFriendlyPlayerHurt);
            Call_PushCell(i_victim);
            Call_PushCell(i_attacker);
            Call_PushCell(i_damage);
            Call_Finish();
        }
    }

    if (gH_CVR_useSpawnProtection.BoolValue)
    {
        if (QSR_IsPlayerProtected(i_victim))
        {
            Call_StartForward(gH_FWD_onProtectedPlayerHurt);
            Call_PushCell(i_victim);
            Call_PushCell(i_attacker);
            Call_PushCell(i_damage);
            Call_Finish();
        }
    }
}

void Event_OnPlayerTeleported(Event event, const char[] name, bool dontBroadcast)
{
    int i_userid = event.GetInt("userid"),
        i_client = GetClientOfUserId(i_userid);

    if (QSR_IsValidClient(i_client))
    {
        int i_breadRoll = GetRandomInt(1, 100);

        if (i_breadRoll <= gH_CVR_breadChance.IntValue)
        {
            int i_amt = GetRandomInt(1, gH_CVR_breadPerTele.IntValue);
            for (int i; i < i_amt; i++)
            {
                QSR_SpawnBreadAtPlayer(i_userid);
            }
        }
    }
}

public void QSR_OnLogFileMade(File& file)
{
    gH_logFile = file;
}

public Action SteamWorks_RestartRequested()
{
    if (gB_SteamWorks)
    {
        if (GetClientCount() > 0)
        {
            QSR_PrintCenterTextAllEx({-1.0, 0.25}, 5.0, HUDCOLOR_RED, HUDCOLOR_RED, 2, .message="Server will be restarting in 10 seconds!");
            CreateTimer(10.0, Timer_RestartServer);
            return Plugin_Continue;
        }

        ServerCommand("restart");
    }
    return Plugin_Continue;
}

// General Functions

// BREAD    

void QSR_ClearBreadArray()
{
    if (gH_breadSpawnedArray != null)
    {
        QSRBreadEntity bread = view_as<QSRBreadEntity>(INVALID_HANDLE);
        for (int i; i < gH_breadSpawnedArray.Length; i++)
        {
            bread = gH_breadSpawnedArray.Get(i);
            
            if (bread != INVALID_HANDLE)
            {
                bread.CleanUp();
                bread.Close();
            }
        }

        gH_breadSpawnedArray.Clear();
        gH_breadSpawnedArray.Close();
        gH_breadSpawnedArray = null;
    }
}

// SPAWN PROTECTION

void QSR_InternalGrantSpawnProtection(int userid)
{
    int i_client = GetClientOfUserId(userid);

    if (!QSR_IsValidClientEX(i_client)) 
    { 
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_GrantSpawnProtection: Tried granting invalid client %d spawn protection!", i_client); 
        return;
    }

    // Action QSR_OnPlayerGrantedSP_Pre;
    Action a_grantSP = Plugin_Continue;
    Call_StartForward(gH_FWD_onPlayerGrantedSPPre);
    Call_PushCell(userid);
    Call_Finish(a_grantSP);
    if (a_grantSP != Plugin_Continue) { return; }

    char s_convar[32], s_rgba[4][8], s_rgb[24];
    gH_CVR_spawnProtectionColor.GetString(s_convar, sizeof(s_convar));
    ExplodeString(s_convar, " ", s_rgba, 4, 8);
    FormatEx(s_rgb, sizeof(s_rgb), "%s %s %s", s_rgba[0], s_rgba[1], s_rgba[2]);
    
    SetEntProp(i_client, Prop_Send, "m_nRenderMode", 1);
    DispatchKeyValue(i_client, "rendercolor", s_rgb);
    DispatchKeyValueInt(i_client, "renderamt", StringToInt(s_rgba[3]));

    TF2_AddCondition(i_client, TFCond_UberchargedOnTakeDamage, .inflictor=i_client);
    gST_playerSPInfo[i_client].b_protected = true;
    gST_playerSPInfo[i_client].f_timeLeft = gH_CVR_spawnProtectionLength.FloatValue;

    // void QSR_OnPlayerGrantedSP(int userid);
    Call_StartForward(gH_FWD_onPlayerGrantedSP);
    Call_PushCell(userid);
    Call_Finish();
}

void QSR_InternalRemoveSpawnProtection(int userid)
{
    int i_client = GetClientOfUserId(userid);

    if (!QSR_IsValidClientEX(i_client)) 
    { 
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_GrantSpawnProtection: Tried granting invalid client %d spawn protection!", i_client); 
        return;
    }

    // Action QSR_OnPlayerLoseSP_Pre(int userid);
    Action a_removeSP = Plugin_Continue;
    Call_StartForward(gH_FWD_onPlayerLoseSPPre);
    Call_PushCell(userid);
    Call_Finish(a_removeSP);
    if (a_removeSP != Plugin_Continue) { return; }
    
    SetEntProp(i_client, Prop_Send, "m_nRenderMode", 0);
    DispatchKeyValue(i_client, "rendercolor", "255 255 255");
    DispatchKeyValueInt(i_client, "renderamt", 255);

    TF2_RemoveCondition(i_client, TFCond_UberchargedOnTakeDamage);
    gST_playerSPInfo[i_client].b_protected = false;
    gST_playerSPInfo[i_client].f_timeLeft = 0.0;

    // void QSR_OnPlayerLoseSP(int userid);
    Call_StartForward(gH_FWD_onPlayerLoseSP);
    Call_PushCell(userid);
    Call_Finish();
}

// Natives

// GENERAL
any Native_QSRUsingMiscModule(Handle plugin, int numParams)
{
    QSRMiscModuleType module = view_as<QSRMiscModuleType>(GetNativeCell(1));

    switch (module)
    {
        case MiscModule_AutoRestart:        { return gI_moduleFlags & MISCMOD_AR; }
        case MiscModule_CustomRespawnTimes: { return gI_moduleFlags & MISCMOD_CRT; }
        case MiscModule_Friendly:           { return gI_moduleFlags & MISCMOD_FRIENDLY; }
        case MiscModule_NoFallDamage:       { return gI_moduleFlags & MISCMOD_NOFALL; }
        case MiscModule_NoFallDamageNoise:  { return gI_moduleFlags & MISCMOD_NOFALLNOISE; }
        case MiscModule_SpawnProtection:    { return gI_moduleFlags & MISCMOD_SP; }
        case MiscModule_TeleportBread:      { return gI_moduleFlags & MISCMOD_BREAD; }
        case MiscModule_ThirdPerson:        { return gI_moduleFlags & MISCMOD_TP; }
        default:                            { return false; }
    }
}

// BREAD
any Native_QSRSpawnBreadAtPlayer(Handle plugin, int numParams)
{
    if (gI_breadCount == gH_CVR_totalAmountOfBread.IntValue)
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "ERROR! Bread Overflow! There are too many bread models to spawn this.");
        return false;
    }

    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);
    
    if (!QSR_IsValidClient(i_client)) 
    { 
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_SpawnBreadAtPlayer: Attempted to spawn bread for invalid client index %d", i_client); 
        return false;
    }

    char s_bread[PLATFORM_MAX_PATH], s_entName[64];
    float f_origin[3], f_angles[3], f_velocity[3];
    QSRBreadModel model = GetNativeCell(2);

    QSR_BreadEnumToModel(model, s_bread, sizeof(s_bread));
    GetClientAbsOrigin(i_client, f_origin);

    QSRBreadEntity bread = new QSRBreadEntity();
    if (bread == view_as<QSRBreadEntity>(INVALID_HANDLE))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "ERROR! QSR_SpawnBreadAtPlayer was unable to create a new BreadEntity handle!\nCurrent amount of bread: %d", gI_breadCount);
        return false;
    }

    int i_modelEnt = CreateEntityByName("prop_physics_multiplayer");
    if (i_modelEnt != -1 && IsValidEdict(i_modelEnt))
    {
        bread.EntReference  = EntIndexToEntRef(i_modelEnt);
        bread.EntLifetime   = gH_CVR_breadLifetime.FloatValue;
        FormatEx(s_entName, sizeof(s_entName), "bread_%d", gI_breadCount);

        DispatchKeyValue(i_modelEnt, "targetname", s_entName);
        DispatchKeyValue(i_modelEnt, "model", s_bread);
        DispatchKeyValueInt(i_modelEnt, "max_health", 1);
        DispatchKeyValueInt(i_modelEnt, "health", 1);
        DispatchKeyValueInt(i_modelEnt, "minhealthdmg", 665);
        DispatchKeyValueInt(i_modelEnt, "physicsmode", 1);
        DispatchKeyValueInt(i_modelEnt, "nodamageforces", 0);
        DispatchKeyValueInt(i_modelEnt, "spawnflags", 4);
        DispatchKeyValueFloat(i_modelEnt, "massscale", 0.75);

        f_origin[1] += 64.0;
        for (int i; i < 3; i++)
        {
            f_angles[i] = GetRandomFloat(-90.0, 90.0);
            if (i != 2)
            {
                f_velocity[i] = GetRandomFloat(-64.0, 64.0);
            }
        }

        f_velocity[2] = -64.0;
        TeleportEntity(i_modelEnt, f_origin, f_angles, f_velocity);

        // Action QSR_OnBreadSpawned_Pre(QSRBreadEntity &bread);
        Action a_spawnBread = Plugin_Continue;
        Call_StartForward(gH_FWD_onBreadSpawnedPre);
        Call_PushCellRef(bread);
        Call_Finish(a_spawnBread);
        
        if (a_spawnBread != Plugin_Continue)
        {
            bread.CleanUp();
            return false;
        }

        if (DispatchSpawn(i_modelEnt))
        {
            bread.EntTimer = CreateTimer(0.1, Timer_BreadLifetimeTimer, bread, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

            gI_breadCount++;
            gH_breadSpawnedArray.Push(bread);

            //void QSR_OnBreadSpawned(QSRBreadEntity bread);
            Call_StartForward(gH_FWD_onBreadSpawned);
            Call_PushCell(bread);
            Call_Finish();

            return true;
        }

        bread.CleanUp();
        bread.Close();
        return false;
    }

    bread.Close();
    return false;
}

// SPAWN PROTECTION
any Native_QSRPlayerEnabledSP(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    { 
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_PlayerEnabledSP: userid %d is not a valid target!", i_userid);
        return false;
    }

    return gST_playerSPInfo[i_client].b_enabled;
}

any Native_QSRIsPlayerProtected(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClientEX(i_client)) 
    { 
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_IsPlayerProtected: userid %d is not a valid target!", i_userid); 
        return false;
    }

    return gST_playerSPInfo[i_client].b_protected;
}

void Native_QSRToggleSpawnProtection(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    { 
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_ToggleSpawnProtection: userid %d is not a valid target!", i_userid); 
        return;
    }

    // void QSR_OnPlayerToggleSP(int userid, bool oldState, bool newState);
    Call_StartForward(gH_FWD_onPlayerToggleSP);
    Call_PushCell(i_userid);
    Call_PushCell(gST_playerSPInfo[i_client].b_enabled);
    gST_playerSPInfo[i_client].b_enabled = !gST_playerSPInfo[i_client].b_enabled;
    Call_PushCell(gST_playerSPInfo[i_client].b_enabled);
    Call_Finish();
}

void Native_QSRGrantSpawnProtection(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1);
    QSR_InternalGrantSpawnProtection(i_userid);
}

void Native_QSRRemoveSpawnProtection(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1);
    QSR_InternalRemoveSpawnProtection(i_userid);
}

// Respawn Time
any Native_QSRPlayerHasCRespawnTime(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    { 
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_PlayerHasCRespawnTime: userid %d is not a valid target!", i_userid); 
        return false;
    }

}

any Native_QSRGetPlayerCRespawnTime(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);
}

void Native_QSRSetPlayerCRespawnTime(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);
}

any Native_QSRGetRespawnTimeLeft(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);
}

any Native_QSRIsPlayerRespawning(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);
}

void Native_QSRForcePlayerRespawn(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);
}

// Third Person
any Native_QSRGetPlayerPOV(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClientEX(i_client))
    {
        return view_as<QSRPov>(-1);
    }

    return gST_playerPOVs[i_client];
}

void Native_QSRSetPlayerPOV(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClientEX(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to change invalid client %d's POV!", i_client);
        return;
    }

    QSRPov newPOV = GetNativeCell(2);

    // void QSR_OnPlayerChangePOV(int userid, QSRPov oldPov, QSRPov newPov)
    Call_StartForward(gH_FWD_onChangePOV);
    Call_PushCell(i_userid);
    Call_PushCell(gST_playerPOVs[i_client]);
    gST_playerPOVs[i_client] = newPOV;
    Call_PushCell(gST_playerPOVs[i_client]);
    Call_Finish();
}

int Native_QSRGetPlayerFOV(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to change invalid client %d's FOV!", i_client);
        return -1;
    }


}

// Friendly
any Native_QSRIsPlayerFriendly(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        return false;
    }

    return gB_isFriendly[i_client];
}

void Native_QSRSetPlayerFriendlyState(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        return;
    }

    bool state = GetNativeCell(2);

    Call_StartForward(gH_FWD_onChangedFriendlyState);
    Call_PushCell(i_userid);
    Call_PushCell(gB_isFriendly[i_client]);
    gB_isFriendly[i_client] = state;
    Call_PushCell(gB_isFriendly[i_client]);
    Call_Finish();
}

// CALLBACKS

// GENERAL
void Timer_RestartServer(Handle timer)
{
    ServerCommand("restart");
}

// Bread

Action Timer_BreadLifetimeTimer(Handle timer, QSRBreadEntity bread)
{
    if (!bread.Validate())
    {
        PrintToServer("Unable to validate bread entity!");

        int i_arrayIdx = gH_breadSpawnedArray.FindValue(bread);
        if (i_arrayIdx != -1) 
        { 
            gH_breadSpawnedArray.Erase(i_arrayIdx); 
        }

        gI_breadCount--;
        bread.Reset();
        return Plugin_Stop;
    }

    if (bread.EntLifetime <= 0.0)
    {
        int i_arrayIdx = gH_breadSpawnedArray.FindValue(bread);
        if (i_arrayIdx != -1)
        {
            gH_breadSpawnedArray.Erase(i_arrayIdx); 
        }

        gI_breadCount--;
        bread.CleanUp();
        return Plugin_Stop;
    }

    bread.EntLifetime -= 0.1;
    return Plugin_Continue;
}

// SPAWN PROTECTION

Action Timer_SpawnProtectionHandler(Handle timer, int userid)
{
    int i_client = GetClientOfUserId(userid);

    if (!QSR_IsValidClientEX(i_client)) { return Plugin_Stop; }
    
    if (gST_playerSPInfo[i_client].f_timeLeft <= 0.0)
    {
        QSR_RemoveSpawnProtection(i_client);
        gST_playerSPInfo[i_client].h_protectionTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    else if (gST_playerSPInfo[i_client].f_timeLeft <= (gH_CVR_spawnProtectionLength.FloatValue * 0.15))
    {
        if (RoundToFloor(gST_playerSPInfo[i_client].f_timeLeft) % 2 == 0)
        {
            DispatchKeyValueInt(i_client, "renderamt", 255);
        }
        else
        {
            DispatchKeyValueInt(i_client, "renderamt", 120);
        }
    }

    gST_playerSPInfo[i_client].f_timeLeft -= 0.1;
    return Plugin_Continue;
}

Action CMD_SpawnProtection(int client, int args)
{

    return Plugin_Handled;
}

// Respawn Times

Action Timer_RespawnHandler(Handle timer, int userid)
{
    
    
    return Plugin_Handled;
}

Action CMD_RespawnTime(int client, int args)
{
    

    return Plugin_Handled;
}

// Third Person

Action CMD_ThirdPerson(int client, int args)
{
    

    return Plugin_Handled;
}

// Friendly

Action CMD_Friendly(int client, int args)
{
    

    return Plugin_Handled;
}

// Main Menu

Action CMD_MiscellaneousMenu(int client, int args)
{


    return Plugin_Handled;
}