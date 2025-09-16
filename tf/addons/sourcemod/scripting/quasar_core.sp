#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <multicolors>
#include <autoexecconfig>
#include <ripext>
#include <SteamWorks>

#include <quasar/core>

//General
bool gB_late = false;
QSRChatFormat gST_chatFormatStrings;
QSRGeneralSounds gST_sounds;
Handle  gH_checkGameUpdateTimer = null;

// Store stuff
int gI_fetchTrailsAttempts;
int gI_fetchSoundsAttempts;

// Database
char gS_subdomain[64];
char gS_dbProfile[64]; // The database profile name in databases.cfg
bool gB_dbConnected = false; // Are we connected to the database yet?
Database gH_db = null; // The handle for the Database
File gH_dbLogFile = null;

// Forwards
Handle gH_FWD_dbConnected = null; // Called when we've successfully connected to the database.
Handle gH_FWD_logCreated = null; // Called when the log file has been created sucessfully.
Handle gH_FWD_chatFormatRetrieved = null;
Handle gH_FWD_soundsRetrieved = null;

// ConVars
ConVar gH_CVR_subdomain = null;
ConVar gH_CVR_dbConfig = null;
ConVar gH_CVR_queryLogFile = null;
ConVar gH_CVR_skipEndingScoreboard = null;

ConVar gH_CVR_chatPrefix = null;
ConVar gH_CVR_defaultColor = null;
ConVar gH_CVR_successColor = null;
ConVar gH_CVR_errorColor = null;
ConVar gH_CVR_warnColor = null;
ConVar gH_CVR_actionColor = null;
ConVar gH_CVR_infoColor = null;
ConVar gH_CVR_commandColor = null;
ConVar gH_CVR_creditColor = null;

ConVar gH_CVR_afkWarnSound = null;
ConVar gH_CVR_afkMoveSound = null;
ConVar gH_CVR_errorSound = null;
ConVar gH_CVR_loginSound = null;
ConVar gH_CVR_addCreditsSound = null;
ConVar gH_CVR_buyItemSound = null;
ConVar gH_CVR_infoSound = null;

// Cookies
// TODO: create cookies for player settings.

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Core)",
    author = PLUGIN_AUTHOR,
    description = "Contains core methods and data shared between Quasar plugin suite.",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("quasar_core");
    CreateNative("QSR_RefreshDatabase",         Native_QSRRefreshDatabase);
    CreateNative("QSR_PrintToChat",             Native_QSRPrintToChat);
    CreateNative("QSR_PrintToChatAll",          Native_QSRPrintToChatAll);
    CreateNative("QSR_PrintCenterTextEx",       Native_QSRPrintCenterTextEx);
    CreateNative("QSR_PrintCenterTextAllEx",    Native_QSRPrintCenterTextAllEx);
    CreateNative("QSR_NotifyUser",              Native_QSRNotifyUser);

    gB_late = late;
}

public void OnPluginStart()
{
    // Forwards
    gH_FWD_dbConnected = CreateGlobalForward("QSR_OnDatabaseConnected", ET_Ignore, Param_CellByRef);
    gH_FWD_logCreated = CreateGlobalForward("QSR_OnLogFileMade", ET_Ignore, Param_CellByRef);
    gH_FWD_chatFormatRetrieved = CreateGlobalForward("QSR_OnSystemFormattingRetrieved", ET_Ignore, Param_Cell);
    gH_FWD_soundsRetrieved = CreateGlobalForward("QSR_OnSystemSoundsRetrieved", ET_Ignore, Param_Cell);

    // AutoExecConfig Setup
    AutoExecConfig_SetFile("plugin.quasar_core");

    // Important Options
    gH_CVR_dbConfig             = AutoExecConfig_CreateConVar("sm_quasar_db_profile",           "",                 "The default database configuration to use for Quasar", FCVAR_PROTECTED);
    gH_CVR_subdomain            = AutoExecConfig_CreateConVar("sm_quasar_subdomain",            "",                 "Controls what server subdomain the system is running on. [surf0].surfnturf.games The boxed area is a subdomain. Used to get and set player statistics across different servers.", FCVAR_NONE);
    gH_CVR_queryLogFile         = AutoExecConfig_CreateConVar("sm_quasar_logfile",              "logs/quasar-logs", "The default file to store queries and messages from the plugin suite, relative to the sourcemod folder. Leave off the file extension.", FCVAR_NONE);

    // General

    // Chat Options
    gH_CVR_chatPrefix           = AutoExecConfig_CreateConVar("sm_quasar_msg_prefix",           "{mediumorchid}[{turquoise}QSR{mediumorchid}] ", "The prefix the plugin uses when sending messages to chat. 64 chars max.", FCVAR_NONE);
    gH_CVR_defaultColor         = AutoExecConfig_CreateConVar("sm_quasar_default_text_color",   "{default}",                        "", FCVAR_NONE);
    gH_CVR_successColor         = AutoExecConfig_CreateConVar("sm_quasar_success_text_color",   "{green}",                          "", FCVAR_NONE);
    gH_CVR_errorColor           = AutoExecConfig_CreateConVar("sm_quasar_error_text_color",     "{red}",                            "", FCVAR_NONE);
    gH_CVR_warnColor            = AutoExecConfig_CreateConVar("sm_quasar_warn_text_color",      "{orange}",                         "", FCVAR_NONE);
    gH_CVR_actionColor          = AutoExecConfig_CreateConVar("sm_quasar_action_text_color",    "{gold}",                           "", FCVAR_NONE);
    gH_CVR_infoColor            = AutoExecConfig_CreateConVar("sm_quasar_info_text_color",      "{royalblue}",                      "", FCVAR_NONE);
    gH_CVR_commandColor         = AutoExecConfig_CreateConVar("sm_quasar_command_text_color",   "{greenyellow}",                    "", FCVAR_NONE);
    gH_CVR_creditColor          = AutoExecConfig_CreateConVar("sm_quasar_credit_text_color",    "{yellow}",                         "", FCVAR_NONE);

    // Sound options
    gH_CVR_afkWarnSound         = AutoExecConfig_CreateConVar("sm_quasar_afk_warn_sound",       "",              "Controls the sound played when Quasar sends a warning to a player about to be afk. Searches in the tf/sound folder.", FCVAR_NONE);
    gH_CVR_afkMoveSound         = AutoExecConfig_CreateConVar("sm_quasar_afk_move_sound",       "",              "Controls the sound played when Quasar marks a player as AFK", FCVAR_NONE);
    gH_CVR_errorSound           = AutoExecConfig_CreateConVar("sm_quasar_error_sound",          "",              "Controls the sound played to let the user know an error has occured. Searches in tf/sound.", FCVAR_NONE);
    gH_CVR_loginSound           = AutoExecConfig_CreateConVar("sm_quasar_login_sound",          "",              "Controls the sound played when a user first logs into the server.", FCVAR_NONE);
    gH_CVR_addCreditsSound      = AutoExecConfig_CreateConVar("sm_quasar_add_credits_sound",    "",              "Controls the sound played when a user gains credits.", FCVAR_NONE);
    gH_CVR_buyItemSound         = AutoExecConfig_CreateConVar("sm_quasar_buy_item_sound",       "",              "Controls the sound played when a user buys an item from the store.", FCVAR_NONE);
    gH_CVR_infoSound            = AutoExecConfig_CreateConVar("sm_quasar_info_sound",           "",              "Controls the sound played to alert the user of something. Usually the results of an action they have taken.", FCVAR_NONE);

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    LoadTranslations("quasar_core.phrases");
    LoadTranslations("quasar_item.phrases")

    // Commands
    RegAdminCmd("sm_qdb_refresh", CMD_DB_Refresh, ADMFLAG_UNBAN, "Refresh the connection to the Quasar Database.");
    RegConsoleCmd("sm_qsettings", CMD_OpenSettingsMenu);
    RegConsoleCmd("sm_qset", CMD_OpenSettingsMenu);

    if (gB_late)
    {
        CMD_DB_Refresh(0, 0);
    }
}

public void OnPluginEnd()
{
    if (gH_checkGameUpdateTimer != null)
    {
        KillTimer(gH_checkGameUpdateTimer);
        gH_checkGameUpdateTimer = null;
    }

    gST_chatFormatStrings.Empty();
    gST_sounds.Empty();
    gH_db.Close();
    gH_dbLogFile.Close();

    // Important
    gH_CVR_dbConfig.Close();
    gH_CVR_subdomain.Close();
    gH_CVR_queryLogFile.Close();
    gH_CVR_skipEndingScoreboard.Close();

    // Chat
    gH_CVR_chatPrefix.Close();
    gH_CVR_defaultColor.Close();
    gH_CVR_successColor.Close();
    gH_CVR_errorColor.Close();
    gH_CVR_warnColor.Close();
    gH_CVR_actionColor.Close();
    gH_CVR_infoColor.Close();
    gH_CVR_commandColor.Close();

    // Sound
    gH_CVR_afkWarnSound.Close();
    gH_CVR_afkMoveSound.Close();
    gH_CVR_errorSound.Close();
    gH_CVR_loginSound.Close();
    gH_CVR_addCreditsSound.Close();
    gH_CVR_buyItemSound.Close();
    gH_CVR_infoSound.Close();

    gH_FWD_logCreated.Close();
    gH_FWD_dbConnected.Close();
}

public void OnConfigsExecuted()
{
    // Log File.
    char s_logPath[256], s_logPathCVAR[256], s_time[32];
    gH_CVR_queryLogFile.GetString(s_logPathCVAR, sizeof(s_logPathCVAR));
    FormatTime(s_time, sizeof(s_time), "%b%d%Y");
    FormatEx(s_logPathCVAR, sizeof(s_logPathCVAR), "%s-%s.log", s_logPathCVAR, s_time);

    BuildPath(Path_SM, s_logPath, sizeof(s_logPath), s_logPathCVAR);
    gH_dbLogFile = OpenFile(s_logPath, "a+");
    if (gH_dbLogFile != null)
    {
        gH_dbLogFile.WriteLine("----------------------");
        gH_dbLogFile.WriteLine("  QUASAR LOG STARTED  ");
        gH_dbLogFile.WriteLine("----------------------");

        Call_StartForward(gH_FWD_logCreated);
        Call_PushCellRef(gH_dbLogFile);
        Call_Finish();
    }
    else { LogError("COULD NOT CREATE LOG FILE!"); }

    /** CVARS **/

    // Important
    gH_CVR_dbConfig.GetString(gS_dbProfile, sizeof(gS_dbProfile));
    gH_CVR_subdomain.GetString(gS_subdomain, sizeof(gS_subdomain));

    // Chat
    gH_CVR_chatPrefix.GetString(    gST_chatFormatStrings.s_prefix,         sizeof(gST_chatFormatStrings.s_prefix));
    gH_CVR_defaultColor.GetString(  gST_chatFormatStrings.s_defaultColor,   sizeof(gST_chatFormatStrings.s_defaultColor));
    gH_CVR_successColor.GetString(  gST_chatFormatStrings.s_successColor,   sizeof(gST_chatFormatStrings.s_successColor));
    gH_CVR_errorColor.GetString(    gST_chatFormatStrings.s_errorColor,     sizeof(gST_chatFormatStrings.s_errorColor));
    gH_CVR_warnColor.GetString(     gST_chatFormatStrings.s_warnColor,      sizeof(gST_chatFormatStrings.s_warnColor));
    gH_CVR_actionColor.GetString(   gST_chatFormatStrings.s_actionColor,    sizeof(gST_chatFormatStrings.s_actionColor));
    gH_CVR_infoColor.GetString(     gST_chatFormatStrings.s_infoColor,      sizeof(gST_chatFormatStrings.s_infoColor));
    gH_CVR_commandColor.GetString(  gST_chatFormatStrings.s_commandColor,   sizeof(gST_chatFormatStrings.s_commandColor));
    gH_CVR_creditColor.GetString(   gST_chatFormatStrings.s_creditColor,    sizeof(gST_chatFormatStrings.s_creditColor));

    StringMap h_chatFormatMap = new StringMap();
    h_chatFormatMap.SetString("0",          gST_chatFormatStrings.s_prefix);
    h_chatFormatMap.SetString("1",    gST_chatFormatStrings.s_defaultColor);
    h_chatFormatMap.SetString("2",    gST_chatFormatStrings.s_successColor);
    h_chatFormatMap.SetString("3",      gST_chatFormatStrings.s_errorColor);
    h_chatFormatMap.SetString("4",       gST_chatFormatStrings.s_warnColor);
    h_chatFormatMap.SetString("5",     gST_chatFormatStrings.s_actionColor);
    h_chatFormatMap.SetString("6",       gST_chatFormatStrings.s_infoColor);
    h_chatFormatMap.SetString("7",    gST_chatFormatStrings.s_commandColor);
    h_chatFormatMap.SetString("8",     gST_chatFormatStrings.s_creditColor);

    Call_StartForward(gH_FWD_chatFormatRetrieved);
    Call_PushCell(h_chatFormatMap);
    Call_Finish();
    h_chatFormatMap.Close();


    // Sound
    gH_CVR_afkWarnSound.GetString(      gST_sounds.s_afkWarnSound,      sizeof(gST_sounds.s_afkWarnSound));
    gH_CVR_afkMoveSound.GetString(      gST_sounds.s_afkMoveSound,      sizeof(gST_sounds.s_afkMoveSound));
    gH_CVR_errorSound.GetString(        gST_sounds.s_errorSound,        sizeof(gST_sounds.s_errorSound));
    gH_CVR_loginSound.GetString(        gST_sounds.s_loginSound,        sizeof(gST_sounds.s_loginSound));
    gH_CVR_addCreditsSound.GetString(   gST_sounds.s_addCreditsSound,   sizeof(gST_sounds.s_addCreditsSound));
    gH_CVR_buyItemSound.GetString(      gST_sounds.s_buyItemSound,      sizeof(gST_sounds.s_buyItemSound));
    gH_CVR_infoSound.GetString(         gST_sounds.s_infoSound,         sizeof(gST_sounds.s_infoSound));

    StringMap h_soundMap = new StringMap();
    h_soundMap.SetString("0",     gST_sounds.s_afkWarnSound);
    h_soundMap.SetString("1",     gST_sounds.s_afkMoveSound);
    h_soundMap.SetString("2",        gST_sounds.s_errorSound);
    h_soundMap.SetString("3",        gST_sounds.s_loginSound);
    h_soundMap.SetString("4",  gST_sounds.s_addCreditsSound);
    h_soundMap.SetString("5",     gST_sounds.s_buyItemSound);
    h_soundMap.SetString("6",         gST_sounds.s_infoSound);

    Call_StartForward(gH_FWD_soundsRetrieved);
    Call_PushCell(h_soundMap);
    Call_Finish();
    h_soundMap.Close();

    // Database
    Database.Connect(SQLCB_OnConnect, gS_dbProfile);
}

public void OnMapStart()
{
    if (gB_dbConnected)
    {
        char s_query[512];
        FormatEx(s_query, sizeof(s_query),
        "SELECT vtf, vmt \
        FROM str_trails");
        QSR_LogQuery(gH_dbLogFile, gH_db, s_query, SQLCB_PrecacheTrails);

        FormatEx(s_query, sizeof(s_query),
        "SELECT filepath \
        FROM str_sounds");
        QSR_LogQuery(gH_dbLogFile, gH_db, s_query, SQLCB_PrecacheSounds);
    }
}

public void OnMapEnd()
{
    gI_fetchSoundsAttempts = 0;
    gI_fetchTrailsAttempts = 0;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{

}

/*
    GENERAL
    FUNCTIONS
*/
// General

// Natives
void Native_QSRRefreshDatabase(Handle plugin, int numParams)
{
    CMD_DB_Refresh(0, 0);
}

any Native_QSRPrintToChat(Handle plugin, int numParams)
{
    int client = GetClientOfUserId(GetNativeCell(1));
    if (!QSR_IsValidClient(client)) { return false; }

    char f_msg[1025], s_prefix[1025];
    SetGlobalTransTarget(client);
    FormatNativeString(0, 2, 3, sizeof(f_msg), .out_string=f_msg);
    strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
    StrCat(s_prefix, sizeof(s_prefix), " ");
    StrCat(s_prefix, sizeof(s_prefix), f_msg);

    MC_PrintToChat(client, s_prefix);
    return true;
}

any Native_QSRNotifyUser(Handle plugin, int numParams)
{
    int client = GetClientOfUserId(GetNativeCell(1));
    if (!QSR_IsValidClient(client)) { return false; }

    char f_msg[1025], s_sound[256], s_prefix[1025];
    GetNativeString(2, s_sound, sizeof(s_sound));

    SetGlobalTransTarget(client);
    FormatNativeString(0, 3, 4, sizeof(f_msg), .out_string=f_msg);

    strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
    StrCat(s_prefix, sizeof(s_prefix), " ");
    StrCat(s_prefix, sizeof(s_prefix), f_msg);
    MC_PrintToChat(client, s_prefix);
    EmitSoundToClient(client, s_sound);
    return true;
}

void Native_QSRPrintToChatAll(Handle plugin, int numParams)
{
    char f_msg[1025], s_prefix[1025];

    for (int i = 1; i < MaxClients; i++)
    {
        if (!QSR_IsValidClient(i)) { continue; }

        SetGlobalTransTarget(i);
        FormatNativeString(0, 2, 3, sizeof(f_msg), .out_string=f_msg);
        strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
        StrCat(s_prefix, sizeof(s_prefix), " ");
        StrCat(s_prefix, sizeof(s_prefix), f_msg);
        MC_PrintToChat(i, s_prefix);
    }
}

any Native_QSRPrintCenterTextEx(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client)) { return false; }

    char sf_msg[1025], s_prefix[64];
    float f_effectSettings[3], f_pos[2], f_holdTime;
    int i_effect, i_color1[4], i_color2[4];

    // Copy prefix and remove color tags
    strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
    MC_RemoveTags(s_prefix, sizeof(s_prefix));

    // Grab and set hud text params
    GetNativeArray(2, f_pos, 2);
    f_holdTime = GetNativeCell(3);
    GetNativeArray(4, i_color1, 4);
    GetNativeArray(5, i_color2, 4);
    i_effect = GetNativeCell(6);
    GetNativeArray(7, f_effectSettings, 3);
    SetHudTextParamsEx(f_pos[0], f_pos[1], f_holdTime, i_color1, i_color2, i_effect, f_effectSettings[0], f_effectSettings[1], f_effectSettings[2]);

    // Handle translation and formatting, then send to client
    SetGlobalTransTarget(client);
    FormatNativeString(0, 8, 9, sizeof(sf_msg), .out_string=sf_msg);
    ShowHudText(client, -1, "%s %s", s_prefix, sf_msg);
    return true;
}

void Native_QSRPrintCenterTextAllEx(Handle plugin, int numParams)
{
    char sf_msg[1025], s_prefix[64];
    float f_effectSettings[3], f_pos[2], f_holdTime;
    int i_effect, i_color1[4], i_color2[4];

    strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
    MC_RemoveTags(s_prefix, sizeof(s_prefix));

    // We can get and set the hud text params outside of the for loop.
    GetNativeArray(1, f_pos, 2);
    f_holdTime = GetNativeCell(2);
    GetNativeArray(3, i_color1, 4);
    GetNativeArray(4, i_color2, 4);
    i_effect = GetNativeCell(5);
    GetNativeArray(6, f_effectSettings, 3);
    SetHudTextParamsEx(f_pos[0], f_pos[1], f_holdTime, i_color1, i_color2, i_effect, f_effectSettings[0], f_effectSettings[1], f_effectSettings[2]);

    for (int i = 1; i < MaxClients; i++)
    {
        if (!QSR_IsValidClient(i)) { continue; }

        // Now we can handle the formatting and translation strings
        SetGlobalTransTarget(i);
        FormatNativeString(0, 7, 8, sizeof(sf_msg), .out_string=sf_msg);
        ShowHudText(i, -1, "%s %s", s_prefix, sf_msg);
    }
}

// Callbacks
void Timer_RestartServer(Handle timer)
{
    QSR_LogMessage(gH_dbLogFile,  MODULE_NAME, "Restarting TF2 Server!");
    ServerCommand("exit");
}

/*
    DATABASE
    FUNCTIONS
*/

/**
 *  Grabs the db config from the corresponding cvars.
 *
 * */
void RefreshDatabaseConfig()
{
    gH_CVR_dbConfig.GetString(gS_dbProfile, sizeof(gS_dbProfile));
}

/**
 *  Refreshes the connection to the database.
 *  Usefull if cvars change before the map does.
 */
void RefreshDatabaseConnection()
{
    if (gH_db != null)
    {
        gB_dbConnected = false;
        gH_db.Close();
        gH_db = null;
    }

    Database.Connect(SQLCB_OnConnect, gS_dbProfile);
}

// Callbacks
void SQLCB_OnConnect(Database db, const char[] error, any data)
{
    if (error[0])
    {
        if (gH_db != null)
        {
            gH_db.Close();
            gH_db = null;
        }
        LogError(error);
        return;
    }

    // Make sure we actually SET the database handle. :eyeroll:
    gH_db = db;

    Call_StartForward(gH_FWD_dbConnected);
    Call_PushCellRef(gH_db);
    Call_Finish();
}

void SQLCB_PrecacheTrails(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0])
    {
        QSR_LogMessage(gH_dbLogFile,  MODULE_NAME, "Unable to precache system trail textures! Retrying in 5s.\nERROR: %s", error);
        gI_fetchTrailsAttempts++;
        CreateTimer(5.0, Timer_RetryPrecacheTrails);
        return;
    }

    if (results.HasResults)
    {
        char s_vtf[256], s_vmt[256];
        while (results.FetchRow())
        {
            results.FetchString(0, s_vtf, sizeof(s_vtf));
            results.FetchString(1, s_vmt, sizeof(s_vmt));

            AddFileToDownloadsTable(s_vtf);
            PrecacheModel(s_vmt);
        }
    }
}

void SQLCB_PrecacheSounds(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0])
    {
        QSR_LogMessage(gH_dbLogFile,  MODULE_NAME, "Unable to precache system sounds! Retrying in 5s.\nERROR: %s", error);
        gI_fetchSoundsAttempts++;
        CreateTimer(5.0, Timer_RetryPrecacheSounds);
        return;
    }

    if (results.HasResults)
    {
        char s_soundfile[256];
        while (results.FetchRow())
        {
            results.FetchString(0, s_soundfile, sizeof(s_soundfile));

            AddFileToDownloadsTable(s_soundfile);
            PrecacheSound(s_soundfile);
        }
    }
}

void Timer_RetryPrecacheTrails(Handle timer)
{
    if (gI_fetchTrailsAttempts == 5)
    {
        QSR_LogMessage(gH_dbLogFile,  MODULE_NAME, "Unable to precache store sounds after 5 attempts!");
        gI_fetchTrailsAttempts = 0;
        return;
    }

    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT vtf, vmt \
    FROM str_trails");
    QSR_LogQuery(gH_dbLogFile, gH_db, s_query, SQLCB_PrecacheTrails);
}

void Timer_RetryPrecacheSounds(Handle timer)
{
    if (gI_fetchSoundsAttempts == 5)
    {
        QSR_LogMessage(gH_dbLogFile,  MODULE_NAME, "Unable to precache store sounds after 5 attempts!");
        gI_fetchSoundsAttempts = 0;
        return;
    }

    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT filepath \
    FROM str_sounds");
    QSR_LogQuery(gH_dbLogFile, gH_db, s_query, SQLCB_PrecacheSounds);
}

Action CMD_DB_Refresh(int client, int args)
{
    RefreshDatabaseConfig();
    RefreshDatabaseConnection();

    return Plugin_Handled;
}

Action CMD_OpenSettingsMenu(int client, int args)
{
    QSR_LogMessage(gH_dbLogFile,  MODULE_NAME, "Settings menu attempted to be open");
    return Plugin_Handled;
}

