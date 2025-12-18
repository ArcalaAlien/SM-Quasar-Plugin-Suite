#include <sourcemod>
#include <clientprefs>
#include <tf2>
#include <tf2_stocks>
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
int gI_spMode = 0; // 0 - Default, 1 - Always On, 2 - Always Off

// Third Person
QSRPov gE_customPOVs[MAXPLAYERS + 1] = {POV_FirstPerson, ...};
QSRPov gE_defaultPOVs[MAXPLAYERS + 1] = {POV_FirstPerson, ...};

// FOV
int gI_customFOV[MAXPLAYERS+1]  = {DEFAULT_FOV, ...};
int gI_defaultFOV[MAXPLAYERS+1] = {DEFAULT_FOV, ...};

// Friendly
bool gB_isFriendly[MAXPLAYERS + 1] = {false, ...};

// Respawn Time
QSRRepsawnInfo gST_respawnTimes[MAXPLAYERS + 1];

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
ConVar gH_CVR_useCustomFOV              = null;
ConVar gH_CVR_useFriendly               = null;
ConVar gH_CVR_teleportBread             = null;
ConVar gH_CVR_breadPerTele              = null;
ConVar gH_CVR_totalAmountOfBread        = null;
ConVar gH_CVR_breadLifetime             = null;
ConVar gH_CVR_breadChance               = null;
ConVar gH_CVR_spawnProtectionLength     = null;
ConVar gH_CVR_spawnProtectionColor      = null;
ConVar gH_CVR_spawnProtectionMode       = null;
ConVar gH_CVR_allowManualSPChange       = null;
ConVar gH_CVR_spawnProtectionStatus     = null;
ConVar gH_CVR_disableSPOnRoundEnd       = null;
ConVar gH_CVR_respawnTimeMinimum        = null;
ConVar gH_CVR_respawnTimeMaximum        = null;
ConVar gH_CVR_respawnTimeDefault        = null;
ConVar gH_CVR_skipEndingScoreboard      = null;
ConVar gH_CVR_customFOVMinimum          = null;
ConVar gH_CVR_customFOVMaximum          = null;
ConVar gH_CVR_changePOVWhileTaunting    = null;

//* COOKIES */
Cookie gH_CK_autoEnableFriendly         = null;
Cookie gH_CK_autoEnableSP               = null;
Cookie gH_CK_usingCustomRespawn         = null;
Cookie gH_CK_customRespawnLength        = null;
Cookie gH_CK_autoEnableTP               = null;
Cookie gH_CK_customPOV                  = null;
Cookie gH_CK_customFOV                  = null;

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
    CreateNative("QSR_UsingMiscModule",         Native_QSRUsingMiscModule);

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
    CreateNative("QSR_GetPlayerDefaultFOV",     Native_QSRGetPlayerDefaultFOV);
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
    gH_FWD_onProtectedPlayerHurt    = CreateGlobalForward("QSR_OnProtectedPlayerHurt",  ET_Ignore,  Param_Cell, Param_Cell, Param_Cell);
    gH_FWD_onChangeFOV              = CreateGlobalForward("QSR_OnPlayerChangeFOV",      ET_Ignore,  Param_Cell, Param_Cell, Param_Cell)

    // Handle ConVars
    AutoExecConfig_SetFile("plugin.quasar_misc");

    gH_CVR_disableFallDamage        = AutoExecConfig_CreateConVar("sm_quasar_misc_disable_fall_damage",                 "0",                "");
    gH_CVR_disableFallDamageNoise   = AutoExecConfig_CreateConVar("sm_quasar_misc_disable_fall_damage_noise",           "1",                "");
    gH_CVR_useSpawnProtection       = AutoExecConfig_CreateConVar("sm_quasar_miscmod_spawn_protection_enabled",         "1",                "");
    gH_CVR_useAutoRestart           = AutoExecConfig_CreateConVar("sm_quasar_miscmod_auto_restart_enabled",             "1",                "");
    gH_CVR_useCustomRespawnTimes    = AutoExecConfig_CreateConVar("sm_quasar_miscmod_custom_respawn_times_enabled",     "1",                "");
    gH_CVR_useThirdPerson           = AutoExecConfig_CreateConVar("sm_quasar_miscmod_third_person_enabled",             "1",                "");
    gH_CVR_useCustomFOV             = AutoExecConfig_CreateConVar("sm_quasar_miscmod_custom_fov_enabled",               "1",                "");
    gH_CVR_useFriendly              = AutoExecConfig_CreateConVar("sm_quasar_miscmod_friendly_enabled",                 "1",                "");
    gH_CVR_teleportBread            = AutoExecConfig_CreateConVar("sm_quasar_miscmod_teleport_bread_enabled",           "1",                "");
    gH_CVR_breadPerTele             = AutoExecConfig_CreateConVar("sm_quasar_misc_bread_per_tele",                      "2",                "");
    gH_CVR_totalAmountOfBread       = AutoExecConfig_CreateConVar("sm_quasar_misc_total_bread_allowed",                 "24",               "");
    gH_CVR_breadLifetime            = AutoExecConfig_CreateConVar("sm_quasar_misc_bread_lifetime",                      "3.0",              "");
    gH_CVR_breadChance              = AutoExecConfig_CreateConVar("sm_quasar_misc_bread_chance",                        "100",              "");
    gH_CVR_spawnProtectionLength    = AutoExecConfig_CreateConVar("sm_quasar_misc_spawn_protection_length",             "5.0",              "");
    gH_CVR_spawnProtectionColor     = AutoExecConfig_CreateConVar("sm_quasar_misc_spawn_protection_color",              "120 255 120 120",  "");
    gH_CVR_spawnProtectionMode      = AutoExecConfig_CreateConVar("sm_quasar_misc_spawn_protection_mode",               "0",                "");
    gH_CVR_allowManualSPChange      = AutoExecConfig_CreateConVar("sm_quasar_misc_spawn_protection_manual_change",      "1",                "");
    gH_CVR_spawnProtectionStatus    = AutoExecConfig_CreateConVar("sm_quasar_misc_spawn_protection_status",             "1",                "");
    gH_CVR_disableSPOnRoundEnd      = AutoExecConfig_CreateConVar("sm_quasar_misc_spawn_protection_disable_round_end",  "1",                "");
    gH_CVR_respawnTimeMinimum       = AutoExecConfig_CreateConVar("sm_quasar_misc_respawn_time_minimum",                "0",                "");
    gH_CVR_respawnTimeMaximum       = AutoExecConfig_CreateConVar("sm_quasar_misc_respawn_time_maximum",                "0",                "Set automatically by the plugin, always matches mp_respawnwavetime");
    gH_CVR_respawnTimeDefault       = AutoExecConfig_CreateConVar("sm_quasar_misc_respawn_time_default",                "-1",               "");
    gH_CVR_skipEndingScoreboard     = AutoExecConfig_CreateConVar("sm_quasar_misc_skip_scoreboard",                     "1",                "Skips the ending scoreboard allowing for quicker map transitions.");
    gH_CVR_customFOVMinimum         = AutoExecConfig_CreateConVar("sm_quasar_misc_fov_minimum",                         "10",               "");
    gH_CVR_customFOVMaximum         = AutoExecConfig_CreateConVar("sm_quasar_misc_fov_maximum",                         "100",              "");
    gH_CVR_changePOVWhileTaunting   = AutoExecConfig_CreateConVar("sm_quasar_misc_change_pov_while_taunting",           "1",                "");

    gH_CVR_disableFallDamage.AddChangeHook(OnConVarChanged);
    gH_CVR_disableFallDamageNoise.AddChangeHook(OnConVarChanged);
    gH_CVR_useSpawnProtection.AddChangeHook(OnConVarChanged);
    gH_CVR_useAutoRestart.AddChangeHook(OnConVarChanged);
    gH_CVR_useCustomRespawnTimes.AddChangeHook(OnConVarChanged);
    gH_CVR_useThirdPerson.AddChangeHook(OnConVarChanged);
    gH_CVR_useFriendly.AddChangeHook(OnConVarChanged);
    gH_CVR_teleportBread.AddChangeHook(OnConVarChanged);
    gH_CVR_useCustomFOV.AddChangeHook(OnConVarChanged);

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    // Handle Cookies
    gH_CK_autoEnableFriendly    = new Cookie("sm_quasar_misc_auto_enable_friendly", "Auto enable friendly mode on spawn?",                                      CookieAccess_Public);
    gH_CK_autoEnableSP          = new Cookie("sm_quasar_misc_auto_enable_sp",       "Auto enable spawn protection on spawn?",                                   CookieAccess_Public);
    gH_CK_customRespawnLength   = new Cookie("sm_quasar_misc_respawn_length",       "How long is this player's respawn time? 0 - Instant, -1 - Server Default", CookieAccess_Public);
    gH_CK_usingCustomRespawn    = new Cookie("sm_quasar_misc_using_custom_respawn", "User set thier own respawn time.",                                         CookieAccess_Public);
    gH_CK_customPOV             = new Cookie("sm_quasar_misc_player_pov",           "User's current pov. 0 - First Person, 1 - Third Person",                   CookieAccess_Public);
    gH_CK_customFOV             = new Cookie("sm_quasar_misc_player_fov",           "User's current FOV. Default is set to player's current FOV",               CookieAccess_Public);

    // Load Translations
    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    LoadTranslations("quasar_core.phrases");
    LoadTranslations("quasar_misc.phrases");

    RegConsoleCmd("sm_qmisc", CMD_MiscellaneousMenu, "Use this to open the misc. functions menu!");
    //RegAdminCmd("sm_breadplayer", CMD_BreadPlayer, ADMFLAG_GENERIC);

    HookEvent("player_spawn", Event_OnPlayerSpawn);
    HookEvent("player_hurt", Event_OnPlayerHurt);
    HookEvent("player_teleported", Event_OnPlayerTeleported);
    HookEvent("player_death", Event_OnPlayerDeath);

    // TODO: Handle late load here!
    if (gB_late)
    {

    }
}

public void OnPluginEnd()
{
    gH_CK_autoEnableFriendly.Close();
    gH_CK_autoEnableSP.Close();
    gH_CK_autoEnableTP.Close();
    gH_CK_customRespawnLength.Close();
    gH_CK_usingCustomRespawn.Close();
    gH_CK_customFOV.Close();
    gH_CK_customPOV.Close();

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
    gH_CVR_allowManualSPChange.Close();
    gH_CVR_spawnProtectionLength.Close();
    gH_CVR_spawnProtectionStatus.Close();
    gH_CVR_disableSPOnRoundEnd.Close();
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
        if (!CommandExists("sm_sp"))
            RegConsoleCmd("sm_sp",              CMD_SpawnProtection, "Use this to enable / disable spawn protection!");

        if (!CommandExists("sm_spawnprotection"))
            RegConsoleCmd("sm_spawnprotection", CMD_SpawnProtection, "Use this to enable / disable spawn protection!");
    }

    if (gH_CVR_useCustomRespawnTimes.BoolValue)
    {
        gI_moduleFlags |= MISCMOD_CRT;
        if (!CommandExists("sm_kc"))
            RegConsoleCmd("sm_kc",          CMD_RespawnTime);

        if (!CommandExists("sm_killcam"))
            RegConsoleCmd("sm_killcam",     CMD_RespawnTime);

        if (!CommandExists("sm_spawntime"))
            RegConsoleCmd("sm_spawntime",   CMD_RespawnTime);

        if (!CommandExists("sm_respawntime"))
            RegConsoleCmd("sm_respawntime", CMD_RespawnTime);

        if (!CommandExists("sm_rst"))
            RegConsoleCmd("sm_rst",         CMD_RespawnTime);

        ConVar mp_respawnwavetime = FindConVar("mp_respawnwavetime");
        if (mp_respawnwavetime != null &&
            gH_CVR_respawnTimeMaximum.IntValue != mp_respawnwavetime.IntValue)
        {
            if (mp_respawnwavetime <= 0.0) { gH_CVR_respawnTimeMaximum.SetInt(5); }
            else                           { gH_CVR_respawnTimeMaximum.SetInt(mp_respawnwavetime.IntValue); }
            mp_respawnwavetime.Close();
        }

        ServerCommand("mp_disable_respawn_times 0");
    }

    if (gH_CVR_useThirdPerson.BoolValue)
    {
        gI_moduleFlags |= MISCMOD_TP;
        if (!CommandExists("sm_tp"))
            RegConsoleCmd("sm_tp",          CMD_ChangePOV);

        if (!CommandExists("sm_fp"))
            RegConsoleCmd("sm_fp",          CMD_ChangePOV);

        if (!CommandExists("sm_3"))
            RegConsoleCmd("sm_3",           CMD_ChangePOV);

        if (!CommandExists("sm_1"))
            RegConsoleCmd("sm_1",           CMD_ChangePOV);

        if (!CommandExists("sm_firstperson"))
            RegConsoleCmd("sm_firstperson", CMD_ChangePOV);

        if (!CommandExists("sm_thirdperson"))
            RegConsoleCmd("sm_thirdperson", CMD_ChangePOV);

        if (!CommandExists("sm_pov"))
            RegConsoleCmd("sm_pov",         CMD_ChangePOV);
    }

    if (gH_CVR_useFriendly.BoolValue)
    {
        gI_moduleFlags |= MISCMOD_FRIENDLY;
        if (!CommandExists("sm_friendly"))
            RegConsoleCmd("sm_friendly",    CMD_Friendly);

        if (!CommandExists("sm_friend"))
            RegConsoleCmd("sm_friend",      CMD_Friendly);

        if (!CommandExists("sm_fr"))
            RegConsoleCmd("sm_fr",          CMD_Friendly);
    }

    if (gH_CVR_useCustomFOV.BoolValue)
    {
        gI_moduleFlags |= MISCMOD_FOV;
        if (!CommandExists("sm_fov"))
            RegConsoleCmd("sm_fov", CMD_ChangeFOV);
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

        if (gH_breadSpawnedArray != null) { gH_breadSpawnedArray = new ArrayList(); }
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
    else if (convar == gH_CVR_useCustomFOV           && (StringToInt(newValue) == 1 || StrEqual(newValue, "true", false)))                   { gI_moduleFlags |= MISCMOD_FOV; }

    // Misc Module disabled.
    else if (convar == gH_CVR_disableFallDamage      && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_NOFALL; }
    else if (convar == gH_CVR_disableFallDamageNoise && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_NOFALLNOISE; }
    else if (convar == gH_CVR_teleportBread          && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_BREAD; }
    else if (convar == gH_CVR_useAutoRestart         && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_AR; }
    else if (convar == gH_CVR_useCustomRespawnTimes  && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_CRT; }
    else if (convar == gH_CVR_useFriendly            && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_FRIENDLY; }
    else if (convar == gH_CVR_useSpawnProtection     && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_SP; }
    else if (convar == gH_CVR_useThirdPerson         && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_TP; }
    else if (convar == gH_CVR_useCustomFOV           && (StringToInt(newValue) == 0 || StrEqual(newValue, "false", false)))  { gI_moduleFlags &= MISCMOD_FOV; }

    // Spawn Protection Settings
    else if (convar == gH_CVR_spawnProtectionMode)
    {
        int mode = StringToInt(newValue);
        if (mode > 2)       { mode = 2; }
        else if (mode < 0)  { mode = 0; }

        gI_spMode = mode;
    }
}

public void OnMapStart()
{
    if (GetExtensionFileStatus("SteamWorks.ext") < 1) { gB_SteamWorks = false; }
    else                                              { gB_SteamWorks = true;  }
}

public void OnClientPostAdminCheck(int client)
{
    if (QSR_IsValidClient(client))
    {
        gI_defaultFOV[client] = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
    }
}

public void OnClientConnected(int client)
{
    gI_customFOV[client] = gI_defaultFOV[client];
    gE_customPOVs[client] = POV_FirstPerson;
    gE_defaultPOVs[client] = POV_FirstPerson;
    gB_isFriendly[client] = false;
    gST_respawnTimes[client].Reset();
    gST_playerSPInfo[client].Reset();
}

public void OnClientDisconnect_Post(int client)
{
    gE_customPOVs[client] = POV_FirstPerson;
    gE_defaultPOVs[client] = POV_FirstPerson;
    gI_customFOV[client] = DEFAULT_FOV;
    gI_defaultFOV[client] = DEFAULT_FOV;
    gB_isFriendly[client] = false;
    gST_respawnTimes[client].Reset();
    gST_playerSPInfo[client].Reset();
}

public void OnClientCookiesCached(int client)
{
    // Todo: Organize this
    gI_customFOV[client]                    = gH_CK_customFOV.GetInt(client);
    gE_defaultPOVs[client]                  = view_as<QSRPov>(gH_CK_customPOV.GetInt(client));
    gB_isFriendly[client]                   = view_as<bool>(gH_CK_autoEnableFriendly.GetInt(client));
    gST_respawnTimes[client].f_respawnTime  = gH_CK_customRespawnLength.GetFloat(client);
    gST_playerSPInfo[client].b_enabled      = view_as<bool>(gH_CK_autoEnableSP.GetInt(client));
}

// Update player's custom POV and FOVs every frame to make sure
// they aren't overwritten by the game.
public void OnGameFrame()
{
    int userid;
    for (int i=1; i < MaxClients; i++)
    {
        userid = QSR_IsValidClientEX(i);
        if (userid)
        {
            if (QSR_UsingMiscModule(MiscModule_FOV))
            {
                QSR_InternalSetPlayerFOV(userid, gI_customFOV[i]);
            }

            if (QSR_UsingMiscModule(MiscModule_ThirdPerson))
            {
                if (!QSR_GetPlayerPOV(userid) != gE_customPOVs[i] &&
                    !TF2_IsPlayerInCondition(i, TFCond_Taunting))
                {
                    QSR_InternalSetPlayerPOV(userid, gE_customPOVs[i]);
                }
            }
        }
    }
}

void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int i_player = event.GetInt("userid"),
        i_client = GetClientOfUserId(i_player);

    if (gH_CVR_useSpawnProtection.BoolValue)
    {
        switch(gI_spMode)
        {
            // Default mode.
            case 0:
            {
                if (QSR_PlayerEnabledSP(i_player))
                {
                    QSR_GrantSpawnProtection(i_player);
                }
            }

            // Always on
            case 1:
            {
                QSR_GrantSpawnProtection(i_player);
            }

            // Always off
            case 2:
            {
                // nothing to do currently.
            }
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

void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int i_userid = event.GetInt("userid"),
        i_client = GetClientOfUserId(i_userid);

    if (gH_CVR_useCustomRespawnTimes.BoolValue && QSR_IsValidClient(i_client))
    {
        if (gST_respawnTimes[i_client].f_respawnTime <= 0.0)
        {
            TF2_RespawnPlayer(i_client);
            Call_StartForward(gH_FWD_onPlayerRespawned);
            Call_PushCell(i_userid);
            Call_PushCell(TF2_GetClientTeam(i_client));
            Call_Finish();
            return;
        }

        gST_respawnTimes[i_client].f_respawnTimeLeft = gST_respawnTimes[i_client].f_respawnTime;
        gST_respawnTimes[i_client].b_waiting = true;
        gST_respawnTimes[i_client].h_respawnTimer = CreateTimer(0.1, Timer_Respawn, i_userid);
    }
}

public void QSR_OnLogFileMade(File& file)
{
    gH_logFile = file;
}

public void QSR_OnSystemFormattingRetrieved(StringMap formatting)
{
    char key[2];
    for (int i; i < formatting.Size; i++)
    {
        IntToString(i, key, sizeof(key));
        switch(i)
        {
            case 0: { formatting.GetString(key, gST_chatFormatting.s_prefix, sizeof(gST_chatFormatting.s_prefix)); }
            case 1: { formatting.GetString(key, gST_chatFormatting.s_defaultColor, sizeof(gST_chatFormatting.s_defaultColor)); }
            case 2: { formatting.GetString(key, gST_chatFormatting.s_successColor, sizeof(gST_chatFormatting.s_successColor)); }
            case 3: { formatting.GetString(key, gST_chatFormatting.s_errorColor, sizeof(gST_chatFormatting.s_errorColor)); }
            case 4: { formatting.GetString(key, gST_chatFormatting.s_warnColor, sizeof(gST_chatFormatting.s_warnColor)); }
            case 5: { formatting.GetString(key, gST_chatFormatting.s_actionColor, sizeof(gST_chatFormatting.s_actionColor)); }
            case 6: { formatting.GetString(key, gST_chatFormatting.s_infoColor, sizeof(gST_chatFormatting.s_infoColor)); }
            case 7: { formatting.GetString(key, gST_chatFormatting.s_commandColor, sizeof(gST_chatFormatting.s_commandColor)); }
            case 8: { formatting.GetString(key, gST_chatFormatting.s_creditColor, sizeof(gST_chatFormatting.s_creditColor)); }
        }
    }
}

public void QSR_OnSystemSoundsRetrieved(StringMap sounds)
{
    char key[2];
    for (int i; i < sounds.Size; i++)
    {
        IntToString(i, key, sizeof(key));
        switch(i)
        {
            case 0: { sounds.GetString(key, gST_sounds.s_afkWarnSound, sizeof(gST_sounds.s_afkWarnSound)); }
            case 1: { sounds.GetString(key, gST_sounds.s_afkMoveSound, sizeof(gST_sounds.s_afkMoveSound)); }
            case 2: { sounds.GetString(key, gST_sounds.s_errorSound, sizeof(gST_sounds.s_errorSound)); }
            case 3: { sounds.GetString(key, gST_sounds.s_loginSound, sizeof(gST_sounds.s_loginSound)); }
            case 4: { sounds.GetString(key, gST_sounds.s_addCreditsSound, sizeof(gST_sounds.s_addCreditsSound)); }
            case 5: { sounds.GetString(key, gST_sounds.s_buyItemSound, sizeof(gST_sounds.s_buyItemSound)); }
            case 6: { sounds.GetString(key, gST_sounds.s_infoSound, sizeof(gST_sounds.s_infoSound)); }
        }
    }
}

public Action SteamWorks_RestartRequested()
{
    if (gB_SteamWorks && QSR_UsingMiscModule(MiscModule_AutoRestart))
    {
        if (GetClientCount() > 0)
        {
            QSR_PrintCenterTextAllEx({-1.0, 0.25}, 5.0, HUDCOLOR_RED, HUDCOLOR_RED, 2, .message="Server will be restarting in 10 seconds!");
            CreateTimer(10.0, Timer_RestartServer);
            return Plugin_Continue;
        }

        ServerCommand("exit");
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

    TF2_AddCondition(i_client, TFCond_UberchargedHidden);
    gST_playerSPInfo[i_client].b_protected = true;
    gST_playerSPInfo[i_client].f_timeLeft = gH_CVR_spawnProtectionLength.FloatValue;

    if (gST_playerSPInfo[i_client].h_protectionTimer != INVALID_HANDLE)
    {
        KillTimer(gST_playerSPInfo[i_client].h_protectionTimer);
    }

    gST_playerSPInfo[i_client].h_protectionTimer = CreateTimer(0.1, Timer_SpawnProtection, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

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
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_RemoveSpawnProtection: Tried removing spawn protection from invalid client %d", i_client);
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

    TF2_RemoveCondition(i_client, TFCond_UberchargedHidden);
    gST_playerSPInfo[i_client].b_protected = false;
    gST_playerSPInfo[i_client].f_timeLeft = 0.0;

    // void QSR_OnPlayerLoseSP(int userid);
    Call_StartForward(gH_FWD_onPlayerLoseSP);
    Call_PushCell(userid);
    Call_Finish();
}

void QSR_InternalSetPlayerPOV(int userid, QSRPov pov)
{
    int i_client = GetClientOfUserId(userid);
    if (!QSR_IsValidClientEX(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Attempted to change POV of invalid client %d (userid %d)!", i_client, userid);
        return;
    }

    if (TF2_IsPlayerInCondition(i_client, TFCond_Taunting) &&
        QSR_GetPlayerPOV(userid) == POV_ThirdPerson)
    { return; }
    else if (TF2_IsPlayerInCondition(i_client, TFCond_Taunting) &&
             QSR_GetPlayerPOV(userid) == POV_FirstPerson )
    {
        QSR_InternalSetPlayerPOV(userid, POV_ThirdPerson);
        return;
    }

    // Set client to first person.
    if (pov == POV_FirstPerson)
    {
        //QSR_LogMessage(gH_logFile, MODULE_NAME, "Set POV of client %d (userid %d) to First Person.", i_client, userid);
        gE_customPOVs[i_client] = POV_FirstPerson;
        SetVariantInt(0);
        AcceptEntityInput(i_client, "SetForcedTauntCam", i_client);
        return;
    }

    //QSR_LogMessage(gH_logFile, MODULE_NAME, "Set POV of client %d (userid %d) to Third Person.", i_client, userid);
    // Set client to third person.
    gE_customPOVs[i_client] = POV_ThirdPerson;
    SetVariantInt(1);
    AcceptEntityInput(i_client, "SetForcedTauntCam", i_client);
}

void QSR_InternalSetPlayerFOV(int userid, int fov)
{
    int i_client = GetClientOfUserId(userid);
    if (!QSR_IsValidClientEX(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Attempted to change FOV of invalid client %d (userid %d)!", i_client, userid);
        return;
    }

    // TODO: Cookies!

    // Are we resetting the player's FOV?
    if (fov == 0)
    {
        //QSR_LogMessage(gH_logFile, MODULE_NAME, "Reset client %d (userid %d)'s FOV to %d.", i_client, userid, gI_defaultFOV[i_client]);
        gI_customFOV[i_client] = gI_defaultFOV[i_client];
        SetEntProp(i_client, Prop_Send, "m_iFOV", gI_defaultFOV[i_client]);
        SetEntProp(i_client, Prop_Send, "m_iDefaultFOV", gI_defaultFOV[i_client]);
        return;
    }

    // We're setting a new custom FOV
    //QSR_LogMessage(gH_logFile, MODULE_NAME, "Set client %d (userid %d)'s FOV to %d.", i_client, userid, fov);
    gI_customFOV[i_client] = fov;
    SetEntProp(i_client, Prop_Send, "m_iFOV", gI_customFOV[i_client]);
    SetEntProp(i_client, Prop_Send, "m_iDefaultFOV", gI_customFOV[i_client]);
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
        case MiscModule_FOV:                { return gI_moduleFlags & MISCMOD_FOV; }
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
            bread.EntTimer = CreateTimer(0.1, Timer_BreadLifetime, bread, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

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
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_PlayerHasCRespawnTime: ERROR! userid %d is not valid!", i_userid);
        return false;
    }

    return (gST_respawnTimes[client].f_respawnTime !=
            gH_CVR_respawnTimeDefault.FloatValue);
}

any Native_QSRGetPlayerCRespawnTime(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_GetPlayerCRespawnTime: ERROR! userid %d is not valid!", userid);
        return -1.0;
    }

    return (gST_respawnTimes[client].f_respawnTime);
}

void Native_QSRSetPlayerCRespawnTime(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_SetPlayerCRespawnTime: ERROR! userid %d is not valid!", userid);
        return;
    }

    //void QSR_OnChangedRespawnTime(int userid, float oldTime, float newTime)
    Call_StartForward(gH_FWD_onChangedRespawnTime);
    Call_PushCell(i_userid);
    Call_PushCell(gST_respawnTimes[client].f_respawnTime);
    gST_respawnTimes[client].f_respawnTime = GetNativeCell(2);
    Call_PushCell(GetNativeCell(2));
    Call_Finish();
}

any Native_QSRGetRespawnTimeLeft(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_GetRespawnTimeLeft: ERROR! userid %d is not valid!", userid);
        return -1.0;
    }

    return gST_respawnTimes[client].f_respawnTimeLeft;
}

any Native_QSRIsPlayerRespawning(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_IsPlayerRespawning: ERROR! userid %d is not valid!", userid);
        return false;
    }

    return gST_respawnTimes[client].b_waiting;
}

void Native_QSRForcePlayerRespawn(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "QSR_ForcePlayerRespawn: ERROR! userid %d is not valid!", userid);
        return;
    }

    gST_respawnTimes[client].Reset();

    Call_StartForward(gH_FWD_onPlayerRespawned);
    Call_PushCell(i_userid);
    Call_PushCell(TF2_GetClientTeam(i_client));
    Call_Finish();
    TF2_RespawnPlayer(i_client);
}

// Third Person

// QSRPov QSR_GetPlayerPOV(int userid)
any Native_QSRGetPlayerPOV(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClientEX(i_client))
    {
        return view_as<QSRPov>(-1);
    }

    return gE_customPOVs[i_client];
}

// void QSR_SetPlayerPOV(int userid, QSRPov pov)
void Native_QSRSetPlayerPOV(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);
    QSRPov newPOV = GetNativeCell(2);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to set invalid client %d (userid %d)'s FOV!", i_client, i_userid);
        return;
    }

    // void QSR_OnPlayerChangePOV(int userid, QSRPov oldPov, QSRPov newPov)
    Call_StartForward(gH_FWD_onChangePOV);
    Call_PushCell(i_userid);
    Call_PushCell(gE_customPOVs[i_client]);

    QSR_InternalSetPlayerPOV(i_userid, newPOV);

    Call_PushCell(gE_customPOVs[i_client]);
    Call_Finish();
}

// int QSR_GetPlayerFOV(int userid)
int Native_QSRGetPlayerFOV(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to request invalid client %d (userid %d)'s FOV!", i_client, i_userid);
        return -1;
    }

    return gI_customFOV[i_client];
}

// int QSR_GetPlayerDefaultFOV(int userid)
int Native_QSRGetPlayerDefaultFOV(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to request invalid client %d's default FOV!", i_client);
        return -1;
    }

    return gI_defaultFOV[i_client];
}

// void QSR_SetPlayerFOV(int userid, int fov)
void Native_QSRSetPlayerFOV(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid),
        i_fov    = GetNativeCell(2);

    if (!QSR_IsValidClient(i_client))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to set invalid client %d's FOV!", i_client);
        return;
    }

    // void QSR_OnPlayerChangeFOV(int userid, int oldFOV, int newPOV);
    Call_StartForward(gH_FWD_onChangeFOV);
    Call_PushCell(i_userid);
    Call_PushCell(QSR_GetPlayerFOV(i_userid));

    QSR_InternalSetPlayerFOV(i_userid, i_fov);

    Call_PushCell(QSR_GetPlayerFOV(i_userid));
    Call_Finish();
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

// General Functions
void ShowMiscMenu(int client)
{
    Menu miscMenu = new Menu(Handler_MiscMenuMain,  MenuAction_Select |
                                                    MenuAction_Cancel |
                                                    MenuAction_End |
                                                    MenuAction_DrawItem);
    miscMenu.SetTitle("%t", "QSR_MiscMainMenuTitle");

    // Let's set up a display for the user
    /**
     * Miscellaneous Settings
     *
     * Friendly:            On
     * Spawn Protection:    On
     * Respawn Time:        Instant
     * POV:                 First
     * FOV:                 75
     *
     * 1. Toggle Friendly
     * 2. Toggle Spawn Protection
     * 3. Change Respawn Time
     * 4. Change POV
     * 5. Reset FOV
     */

    char display[256];

    (gB_isFriendly[client]) ?
        FormatEx(display, sizeof(display),
            "\n%T On\n", "QSR_MiscMenuFriendlyDisplay", client):
        FormatEx(display, sizeof(display),
            "\n%T Off\n", "QSR_MiscMenuFriendlyDisplay", client);

    (gST_playerSPInfo[client].b_enabled) ?
        FormatEx(display, sizeof(display),
            "%s%T On\n", display, "QSR_MiscMenuSPDisplay", client):
        FormatEx(display, sizeof(display),
            "%s%T Off\n", display, "QSR_MiscMenuSPDisplay", client);

    if (gST_respawnTimes[client].f_respawnTime <= 0.0)
        FormatEx(display, sizeof(display),
            "%s%T %T\n", display, "QSR_MiscMenuRTDisplay", client, "QSR_RespawnTimeInstant", client);
    else
        FormatEx(display, sizeof(display),
            "%s%T %.2f\n", display, "QSR_MiscMenuRTDisplay", gST_respawnTimes[client].f_respawnTime);

    (gE_customPOVs[client] == POV_FirstPerson) ?
        FormatEx(display, sizeof(display),
            "%s%T %T\n", display, "QSR_MiscMenuPOVDisplay", client, "QSR_POVFirstPerson", client):
        FormatEx(display, sizeof(display),
            "%s%T %T\n", display, "QSR_MiscMenuPOVDisplay", client, "QSR_POVThirdPerson", client);

    FormatEx(display, sizeof(display),
        "%s%T %d\n", display, "QSR_MiscMenuFOVDisplay", client, gI_customFOV[client]);

    miscMenu.AddItem("X", display, ITEMDRAW_DISABLED);

    FormatEx(display, sizeof(display),
        "%T", "QSR_MiscMenuFriendlyOption", client);
    miscMenu.AddItem("1", display);

    FormatEx(display, sizeof(display),
        "%T", "QSR_MiscMenuSPOption", client);
    miscMenu.AddItem("2", display);

    FormatEx(display, sizeof(display),
        "%T", "QSR_MiscMenuRTOption", client);
    miscMenu.AddItem("3", display);

    FormatEx(display, sizeof(display),
        "%T", "QSR_MiscMenuPOVOption", client);
    miscMenu.AddItem("4", display);

    FormatEx(display, sizeof(display),
        "%T", "QSR_MiscMenuFOVOption", client);
    miscMenu.AddItem("5", display);

    miscMenu.Display(client, 20);
}

// Respawn Times
void ShowRespawnTimeMenu(int client, bool exitBack = false)
{
    Menu rtMenu = new Menu(Handler_RespawnTimeMenu);
    rtMenu.SetTitle("Choose a new respawn time:");
    rtMenu.ExitBackButton = exitBack;

    char info[8], display[32];
    for (float i; i < gH_CVR_respawnTimeMaximum.FloatValue; i += 0.5)
    {
        FloatToString(i, info, sizeof(info));

        if (i == 0.0)
            FormatEx(display, sizeof(display),
                "%T", "QSR_RespawnTimeInstant", client);
        else
            FormatEx(display, sizeof(display),
                "%T", "QSR_RespawnTimeDisplay", client, i);
        rtMenu.AddItem(info, display);
    }

    rtMenu.Display(client, 20);
}

// CALLBACKS

// GENERAL
void Timer_RestartServer(Handle timer)
{
    ServerCommand("exit");
}

Action Timer_PollForCookies(Handle timer, int client)
{
    if (AreClientCookiesCached(client))
    {

        return Plugin_Stop;
    }

    return Plugin_Continue;
}

int Handler_MiscMenuMain(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            int i_userid = QSR_IsValidClient(param1);
            if (i_userid)
            {
                char info[4];
                GetMenuItem(menu, param2, info, sizeof(info));
                switch (info[0])
                {
                    // Toggle Friendly
                    case '1':
                    {
                        ShowMiscMenu(param1);
                    }

                    // Toggle Spawn Protection
                    case '2':
                    {
                        if (!QSR_UsingMiscModule(MiscModule_SpawnProtection))
                        {
                            ShowMiscMenu(param1);
                            return 0;
                        }

                        // Spawn Protection will be handled by the plugin.
                        if (!gH_CVR_allowManualSPChange.BoolValue)
                        {
                            QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_CantChangeSPManually",
                                gST_chatFormatting.s_warnColor);
                            ShowMiscMenu(param1);
                            return 0;
                        }

                        // Is spawn protection enabled on the server?
                        // This already assumes that the spawn protection module is
                        // enabled since this is a per map value.
                        if (!gH_CVR_spawnProtectionStatus.BoolValue)
                        {
                            QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_SpawnProtectionNotAvailable",
                                gST_chatFormatting.s_warnColor);
                            ShowMiscMenu(param1);
                            return 0;
                        }

                        if (i_userid)
                        {
                            gST_playerSPInfo[param1].b_enabled = !gST_playerSPInfo[param1].b_enabled
                            if (gST_playerSPInfo[param1].b_enabled)
                                gH_CK_autoEnableSP.SetInt(param1, 1);
                            else
                            {
                                gH_CK_autoEnableSP.SetInt(param1, 0);

                                if (gST_playerSPInfo[param1].b_protected)
                                {
                                    QSR_InternalRemoveSpawnProtection(i_userid);
                                }
                            }
                        }

                        ShowMiscMenu(param1);
                    }

                    // Change Respawn Time
                    case '3':
                    {
                        ShowRespawnTimeMenu(param1, true);
                    }

                    // Change POV
                    case '4':
                    {
                        (QSR_GetPlayerPOV(i_userid) == POV_FirstPerson) ?
                            QSR_SetPlayerPOV(i_userid, POV_ThirdPerson):
                            QSR_SetPlayerPOV(i_userid, POV_FirstPerson);

                        ShowMiscMenu(param1);
                    }

                    // Reset FOV
                    case '5':
                    {
                        QSR_SetPlayerFOV(i_userid, 0);
                        ShowMiscMenu(param1);
                    }
                }
            }

        }

        case MenuAction_DrawItem:
        {
            char info[4];
            GetMenuItem(menu, param2, info, sizeof(info));

            switch (info[0])
            {
                case '1':
                {
                    if (!gH_CVR_useFriendly.BoolValue)
                        return ITEMDRAW_DISABLED;
                }
                case '2':
                {
                    if (!gH_CVR_useSpawnProtection.BoolValue ||
                        !gH_CVR_allowManualSPChange.BoolValue)
                        return ITEMDRAW_DISABLED;
                }
                case '3':
                {
                    if (!gH_CVR_useCustomRespawnTimes.BoolValue)
                        return ITEMDRAW_DISABLED;
                }
                case '4':
                {
                    if (!gH_CVR_useThirdPerson.BoolValue)
                        return ITEMDRAW_DISABLED;
                }
                case '5':
                {
                    if (!gH_CVR_useCustomFOV.BoolValue)
                        return ITEMDRAW_DISABLED;
                }
                default:
                    return ITEMDRAW_DISABLED;
            }

            return ITEMDRAW_DEFAULT;
        }

        case MenuAction_Cancel: {}

        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

// Bread

Action Timer_BreadLifetime(Handle timer, QSRBreadEntity bread)
{
    if (!bread.Validate())
    {
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

Action Timer_SpawnProtection(Handle timer, int userid)
{
    int i_client = GetClientOfUserId(userid);

    if (!QSR_IsValidClientEX(i_client)) { return Plugin_Stop; }

    if (gST_playerSPInfo[i_client].f_timeLeft <= 0.0)
    {
        QSR_RemoveSpawnProtection(userid);
        gST_playerSPInfo[i_client].h_protectionTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    else if (gST_playerSPInfo[i_client].f_timeLeft <= (gH_CVR_spawnProtectionLength.FloatValue * 0.15))
    {
        if (!(RoundToFloor(gST_playerSPInfo[i_client].f_timeLeft) % 2))
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
    int i_userid = QSR_IsValidClient(client);

    if (!client || !QSR_UsingMiscModule(MiscModule_SpawnProtection))
    {
        return Plugin_Handled;
    }

    // Spawn Protection will be handled by the plugin.
    if (!gH_CVR_allowManualSPChange.BoolValue)
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_CantChangeSPManually",
            gST_chatFormatting.s_warnColor);
        return Plugin_Handled;
    }

    // Is spawn protection enabled on the server?
    // This already assumes that the spawn protection module is
    // enabled since this is a per map value.
    if (!gH_CVR_spawnProtectionStatus.BoolValue)
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_SpawnProtectionNotAvailable",
            gST_chatFormatting.s_warnColor);

        return Plugin_Handled;
    }

    if (i_userid)
    {
        gST_playerSPInfo[client].b_enabled = !gST_playerSPInfo[client].b_enabled
        if (gST_playerSPInfo[client].b_enabled)
        {
            QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t", "QSR_EnabledSpawnProtection",
                gST_chatFormatting.s_successColor);
            gH_CK_autoEnableSP.SetInt(client, 1);
        }
        else
        {
            QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t", "QSR_DisabledSpawnProtection",
                gST_chatFormatting.s_warnColor);
            gH_CK_autoEnableSP.SetInt(client, 0);

            if (gST_playerSPInfo[client].b_protected)
            {
                QSR_InternalRemoveSpawnProtection(i_userid);
            }
        }
    }

    return Plugin_Handled;
}

// Respawn Times

int Handler_RespawnTimeMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[8];
            GetMenuItem(menu, param2, info, sizeof(info));

            int i_userid = QSR_IsValidClient(param1);
            if (i_userid)
            {
                float desiredRT = StringToFloat(info);
                if (desiredRT == 0.0)
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t",
                        "QSR_ChangedRespawnTime", gST_chatFormatting.s_actionColor,
                        gST_chatFormatting.s_commandColor, "QSR_RespawnTimeInstant");
                }
                else
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t",
                        "QSR_ChangedRespawnTime", gST_chatFormatting.s_actionColor,
                        gST_chatFormatting.s_commandColor, "QSR_RespawnTimeDisplay", desiredRT);
                }

                QSR_SetPlayerCRespawnTime(i_userid, desiredRT);

                if (menu.ExitBackButton)
                {
                    ShowMiscMenu(param1);
                }
            }
        }

        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
            {
                ShowMiscMenu(param1);
            }
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }
}

Action Timer_Respawn(Handle timer, int userid)
{
    int i_client = GetClientOfUserId(userid);

    if (QSR_IsValidClient(i_client))
    {
        if (gST_respawnTimes[i_client].f_respawnTimeLeft > 0.0)
        {
            gST_respawnTimes[i_client].f_respawnTimeLeft -= 0.1;
            return Plugin_Continue;
        }

        gST_respawnTimes[i_client].Reset();
        TF2_RespawnPlayer(i_client);
        Call_StartForward(gH_FWD_onPlayerRespawned);
        Call_PushCell(userid);
        Call_PushCell(TF2_GetClientTeam(i_client));
        Call_Finish();
    }

    return Plugin_Stop;
}

Action CMD_RespawnTime(int client, int args)
{
    if (!client || !QSR_UsingMiscModule(MiscModule_CustomRespawnTimes))
    {
        return Plugin_Handled;
    }

    int i_userid = QSR_IsValidClient(client);

    if (i_userid)
    {
        if (!args) { ShowRespawnTimeMenu(client); }
        else
        {
            char info[8];
            float desiredRT;
            GetCmdArg(1, info, sizeof(info));
            desiredRT = StringToFloat(info);

            if (desiredRT == 0.0)
            {
                QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t",
                    "QSR_ChangedRespawnTime", gST_chatFormatting.s_actionColor,
                    gST_chatFormatting.s_commandColor, "QSR_RespawnTimeInstant");
                QSR_SetPlayerCRespawnTime(i_userid, 0.0);
                return Plugin_Handled;
            }
            else if (desiredRT > gH_CVR_respawnTimeMaximum.FloatValue)
            {
                QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t",
                    "QSR_InvalidRespawnTime", gST_chatFormatting.s_errorColor,
                    gST_chatFormatting.s_commandColor, desiredRT,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_commandColor,
                    gH_CVR_respawnTimeMaximum.FloatValue, gST_chatFormatting.s_errorColor);
                return Plugin_Handled;
            }
            else if (desiredRT < gH_CVR_respawnTimeMinimum.FloatValue)
            {
                QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t",
                    "QSR_InvalidRespawnTime", gST_chatFormatting.s_errorColor,
                    gST_chatFormatting.s_commandColor, desiredRT,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_commandColor,
                    gH_CVR_respawnTimeMaximum.FloatValue, gST_chatFormatting.s_errorColor);
                return Plugin_Handled;
            }

            QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t",
                "QSR_ChangedRespawnTime", gST_chatFormatting.s_actionColor,
                gST_chatFormatting.s_commandColor, "QSR_RespawnTimeDisplay", desiredRT);
            QSR_SetPlayerCRespawnTime(i_userid, desiredRT);
        }
    }

    return Plugin_Handled;
}

// Third Person

Action CMD_ChangePOV(int client, int args)
{
    if (!client|| !QSR_UsingMiscModule(MiscModule_ThirdPerson))
    {
        return Plugin_Handled;
    }

    int i_userid = QSR_IsValidClientEX(client);

    if (i_userid)
    {
        if (gE_customPOVs[client] == POV_FirstPerson)
        {
            gH_CK_customPOV.SetInt(client, view_as<int>(POV_ThirdPerson));
            QSR_SetPlayerPOV(i_userid, POV_ThirdPerson);
            QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t",
                "QSR_ChangedPOV", gST_chatFormatting.s_actionColor,
                gST_chatFormatting.s_commandColor, "QSR_POVThirdPerson");
        }
        else
        {
            gH_CK_customPOV.SetInt(client, view_as<int>(POV_FirstPerson));
            QSR_SetPlayerPOV(i_userid, POV_FirstPerson);
            QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t",
                "QSR_ChangedPOV", gST_chatFormatting.s_actionColor,
                gST_chatFormatting.s_commandColor, "QSR_POVFirstPerson");
        }
    }
    else
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t",
            "QSR_ChangePOVDeadOrSpectator", gST_chatFormatting.s_errorColor);
    }

    return Plugin_Handled;
}

// FOV
Action CMD_ChangeFOV(int client, int args)
{
    if (!client || !QSR_UsingMiscModule(MiscModule_FOV))
    {
        return Plugin_Handled;
    }

    int i_userid = GetClientUserId(client);

    if (i_userid)
    {
        int i_desiredFOV = GetCmdArgInt(1);
        if (!i_desiredFOV || !args)
        {
            i_desiredFOV = gI_defaultFOV[client];
        }
        else if (i_desiredFOV > gH_CVR_customFOVMaximum.IntValue)
        {
            QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t",
                "QSR_InvalidFOV", gST_chatFormatting.s_errorColor,
                gST_chatFormatting.s_commandColor, i_desiredFOV,
                gST_chatFormatting.s_errorColor, gST_chatFormatting.s_commandColor,
                gH_CVR_customFOVMaximum.IntValue, gST_chatFormatting.s_errorColor);

            return Plugin_Handled;
        }
        else if (i_desiredFOV < gH_CVR_customFOVMinimum.IntValue && i_desiredFOV != 0)
        {
            QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t",
                "QSR_InvalidFOV", gST_chatFormatting.s_errorColor,
                gST_chatFormatting.s_commandColor, i_desiredFOV,
                gST_chatFormatting.s_errorColor, gST_chatFormatting.s_commandColor,
                gH_CVR_customFOVMinimum.IntValue, gST_chatFormatting.s_errorColor);

            return Plugin_Handled;
        }

        gH_CK_customFOV.SetInt(client, i_desiredFOV);
        QSR_SetPlayerFOV(i_userid, i_desiredFOV);
        QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t",
            "QSR_ChangedFOV", gST_chatFormatting.s_actionColor,
            gST_chatFormatting.s_commandColor, i_desiredFOV);
    }
    else
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t",
            "QSR_ChangeFOVDeadOrSpectator", gST_chatFormatting.s_errorColor);
    }

    return Plugin_Handled;
}

// Friendly

Action CMD_Friendly(int client, int args)
{
    if (!client|| !QSR_UsingMiscModule(MiscModule_Friendly))
    {
        return Plugin_Handled;
    }

    return Plugin_Handled;
}

// Main Menu

Action CMD_MiscellaneousMenu(int client, int args)
{
    ShowMiscMenu(client);

    return Plugin_Handled;
}
