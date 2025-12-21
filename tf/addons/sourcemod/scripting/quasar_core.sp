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
static char gS_subserver[64];
static char gS_dbProfile[64]; // The database profile name in databases.cfg
static bool gB_dbConnected = false; // Are we connected to the database yet?
static char gS_dbVersion[64]; // The version number of our database.
static bool gB_makeSubserverTables = false; // Do the subserver tables exist?
static Database gH_db = null; // The handle for the Database
static File gH_dbLogFile = null;

// Forwards
Handle gH_FWD_dbConnected = null; // Called when we've successfully connected to the database.
Handle gH_FWD_logCreated = null; // Called when the log file has been created sucessfully.
Handle gH_FWD_chatFormatRetrieved = null;
Handle gH_FWD_soundsRetrieved = null;
Handle gH_FWD_dbVersionRetrieved = null;
Handle gH_FWD_subserverTablesValidated = null;

// ConVars
ConVar gH_CVR_subserver = null;
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
    gH_FWD_dbConnected = CreateGlobalForward("QSR_OnDatabaseConnected", ET_Ignore, Param_CellByRef, Param_Array, Param_Cell);
    gH_FWD_logCreated = CreateGlobalForward("QSR_OnLogFileMade", ET_Ignore, Param_CellByRef);
    gH_FWD_chatFormatRetrieved = CreateGlobalForward("QSR_OnSystemFormattingRetrieved", ET_Ignore, Param_Cell);
    gH_FWD_soundsRetrieved = CreateGlobalForward("QSR_OnSystemSoundsRetrieved", ET_Ignore, Param_Cell);
    gH_FWD_dbVersionRetrieved = CreateGlobalForward("QSR_OnDBVersionRetrieved", ET_Ignore, Param_String, Param_Cell);
    gH_FWD_subserverTablesValidated = CreateGlobalForward("QSR_OnSubserverTablesValidated", ET_IGNORE, Param_Cell);

    // AutoExecConfig Setup
    AutoExecConfig_SetFile("plugin.quasar_core");

    // Important Options
    gH_CVR_dbConfig             = AutoExecConfig_CreateConVar("sm_quasar_db_profile",           "",                 "The default database configuration to use for Quasar", FCVAR_PROTECTED);
    gH_CVR_subserver            = AutoExecConfig_CreateConVar("sm_quasar_subserver",            "",                 "Controls what server subserver the system is running on. [surf0].surfnturf.games The boxed area is a subserver. Used to get and set player statistics across different servers.", FCVAR_NONE);
    gH_CVR_queryLogFile         = AutoExecConfig_CreateConVar("sm_quasar_logfile",              "logs/quasar-logs", "The default file to store queries and messages from the plugin suite, relative to the sourcemod folder. Leave off the file extension.", FCVAR_NONE);

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
    gH_CVR_subserver.Close();
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
    gH_FWD_dbVersionRetrieved.Close();
    gH_FWD_subserverTablesValidated.Close();
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
    gH_CVR_subserver.GetString(gS_subserver, sizeof(gS_subserver));

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

#include "SQL/quasar_generate_tables.sp"
//#include "SQL/quasar_update_tables.sp"
#include "SQL/quasar_check_db_version.sp"

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

//TODO: MOVE BELOW CODE TO quasar_check_db_version.sp
enum QSRDBVersionStatus {
    DBVer_Equal,
    DBVer_NeedsUpdated,
    DBVer_FirstTime
};

public void QSR_OnDBVersionRetrieved(char[] dbVersion, int len)
{
    switch (Internal_IsDatabaseUpToDate()) {
        case DBVer_FirstTime: {
            Internal_GenerateTFTables(SERVER);
            Internal_GenerateGlobalTables(SERVER);
            Internal_GenerateSubserverTables(SERVER);
            Internal_GenerateGlobalJunctionTables(SERVER);
            Internal_GenerateSubserverJunctionTables(SERVER);
            Internal_GenerateTableViews(SERVER);
            Internal_GenerateSQLTriggers(SERVER);
            Internal_FillTableDefaults(SERVER);

        }
        case DBVer_NeedsUpdated: {
            //Internal_UpdateTFTables();
            //Internal_UpdateGlobalTables();
            //Internal_UpdateSubserverTables();
            //Internal_UpdateJunctionTables();
            //Internal_GenerateTableViews();
            //Internal_GenerateSQLTriggers();
            //Internal_FillTableDefaults();
        }
        default:
            return;
    }
}

// Here we create the query to check the DB version
void QSR_StartCheckDatabaseVersion() {
    char s_query[512];
    strcopy(s_query, sizeof(s_query),
        "SELECT `version` \
         FROM `quasar`.`db_version`;");

    QSR_LogQuery(
        gH_dbLogFile,
        gH_db,
        s_query,
        SQLCB_DatabaseVersionCB);
}

void QSR_StartValidateSubserverTable() {
    char s_query[512];
    FormatEx(
        s_query,
        sizeof(s_query),
        "SELECT * FROM `quasar`.`%s_chat_log`",
        gS_subserver);
    QSR_LogQuery(
        gH_dbLogFile,
        gH_db,
        SQLCB_ValidateSubserverTable,
        s_query);
}

QSRDBVersionStatus Internal_IsDatabaseUpToDate() {
    if (StrEqual(gS_dbVersion, "NULL VERSION"))
        return DBVer_FirstTime;

    if (!StrEqual(gS_dbVersion, DATABASE_VERSION))
        return DBVer_NeedsUpdated;

    return DBVer_Equal;
}

void SQLCB_DatabaseVersionCB(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0]) {
        QSR_LogMessage(
            gH_dbLogFile,
            MODULE_NAME,
            error);

        strcopy(
            gS_dbVersion,
            sizeof(gS_dbVersion),
            "NULL VERSION");

        return;
    }

    char s_version[32];

    DBResult res;
    while (results.FetchRow()) {
        results.FetchString(0, s_version, sizeof(s_version), res);
        if (res != DBVal_Data)
            strcopy(
                gS_dbVersion,
                sizeof(gS_dbVersion),
                "NULL VERSION");
        else
            strcopy(
                gS_dbVersion,
                sizeof(gS_dbVersion),
                s_version);
    }

    Call_StartForward(gH_FWD_dbVersionRetrieved);
    Call_PushString(gS_dbVersion);
    Call_PushCell(strlen(gS_dbVersion));
    Call_Finish();
}
// TODO: MOVE ABOVE CODE TO quasar_check_db_version.sp

//TODO: MOVE BELOW CODE TO quasar_generate_tables.sp
#define SEND_CREATE_TABLE_QUERY QSR_LogQuery(gH_dbLogFile, gH_db, s_query, SQLCB_CreateTableCB, s_tableName)
// Eventually I want to modify this system to
// be closer to how shavit-bhop-timer handles
// database migrations, but hopefully this will
// work for now.
void Internal_GenerateTFTables() {
    char s_query[2048];
    char s_tableName[64];

    QSR_LogMessage(gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING TEAM FORTRESS 2 TABLES======");

    // Team Fortress 2 Tables
    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_classes");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_classes`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_classes` (\
            `id`        INT NOT NULL AUTO_INCREMENT,\
            `name`      VARCHAR(16) NOT NULL DEFAULT `UNKNOWN`,\
            PRIMARY KEY (\
                `id`\
            )) AUTO_INCREMENT = 1;");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_items");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_items`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_items` (\
            `id`        INT NOT NULL DEFAULT -1,\
            `name`      VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            `classname` VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            `min_level` INT NOT NULL DEFAULT 0,\
            `max_level` INT NOT NULL DEFAULT 99,\
            `slot_name` VARCHAR(16) NOT NULL DEFAULT `UNKNOWN`,\
            PRIMARY KEY (\
                `id`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_attributes");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_attributes`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_attributes` (\
            `id`            INT NOT NULL DEFAULT -1,\
            `name`          VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            `classname`     VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            `description`   VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            PRIMARY KEY (\
                `id`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_qualities");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_qualities`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_qualities` (\
            `id`    INT NOT NULL\
            `name`  VARCHAR(64) NOT NULL DEFAULT `UNKNOWN`\
            PRIMARY KEY (\
                `id`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_particles");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_particles`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_particles` (\
            `id`            INT NOT NULL DEFAULT -1,\
            `name`          VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`\
            `type`          VARCHAR(16)  NOT NULL DEFAULT `WEAPON`\
            `system_name`   VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            PRIMARY KEY (\
                `id`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_paint_kits");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_paint_kits`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_paint_kits` (\
            `id`        INT NOT NULL DEFAULT -1,\
            `name`      VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            `red_color` INT NOT NULL DEFAULT 0,\
            `blu_color` INT NOT NULL DEFAULT 0,\
            PRIMARY KEY (\
                `id`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_war_paints");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_war_paints`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_war_paints` (\
            `id`    INT NOT NULL DEFAULT -1,\
            `name`  VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            PRIMARY KEY (\
                `id`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_items_attributes");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_items_attributes`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_items_attributes` (\
            `item_id`       INT NOT NULL DEFAULT -1,\
            `attribute_id`  VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            `value`         DECIMAL(10)  NOT NULL DEFAULT 0.0,\
            PRIMARY KEY (\
                `item_id`,\
                `attribute_id`\
            ),\
            CONSTRAINT `FK_tf_ia_items`\
                FOREIGN KEY (`item_id`) \
                REFERENCES `quasar`.`tf_items` (`id`)\
                ON DELETE NO ACTION\
                ON UPDATE NO ACTION,\
            CONSTRAINT `FK_tf_ia_attributes`\
                FOREIGN KEY (`attribute_id`)\
                REFERENCES `quasar`.`tf_attributes` (`id`)\
                ON DELETE NO ACTION\
                ON UPDATE NO ACTION);");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_items_classes");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_items_classes`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_items_classes` (\
            `item_id`    INT NOT NULL DEFAULT -1,\
            `class_id`   INT NOT NULL DEFAULT -1,\
            PRIMARY KEY (\
                `item_id`,\
                `class_id`,\
            )\
            CONSTRAINT `FK_tf_ic_items`\
                FOREIGN KEY (`item_id`)\
                REFERENCES `quasar`.`tf_items` (`id`)\
                ON DELETE NO ACTION\
                ON UPDATE NO ACTION,\
            CONSTRAINT `FK_tf_ic_classes`\
                FOREIGN KEY (`class_id`)\
                REFERENCES `quasar`.`tf_classes` (`id`)\
                ON DELETE NO ACTION\
                ON UPDATE NO ACTION);");
    SEND_CREATE_TABLE_QUERY;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATED TEAM FORTRESS 2 TABLES======");
}

void Internal_GenerateGlobalTables() {
    char s_query[2048];
    char s_tableName[64];

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING MAIN GLOBAL TABLES======");

    // GENERAL TABLES//
    // Version Table //
    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.db_version (VERSION TABLE)");
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`db_version`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`db_version` (\
            `version` VARCHAR (16) NOT NULL \
            PRIMARY KEY (`version`));\
        INSERT INTO `quasar`.`db_version`\
        VALUES (`%s`);",
        DATABASE_VERSION);
    SEND_CREATE_TABLE_QUERY;

    // Player Table//
    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.players (PLAYER TABLE)");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`players`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`players` (\
            `id`                INT NOT NULL AUTO_INCREMENT,\
            `steam2_id`         VARCHAR(64)     NOT NULL DEFAULT `UNKNOWN`,\
            `steam3_id`         VARCHAR(64)     NOT NULL DEFAULT `UNKNOWN`,\
            `steam64_id`        VARCHAR(64)     NOT NULL DEFAULT `UNKNOWN`,\
            `name`              VARCHAR(128)    NOT NULL DEFAULT `QUASAR_NAME_UNKNOWN`,\
            `can_vote`          INT             NOT NULL DEFAULT 1,\
            `num_loadouts`      INT             NOT NULL DEFAULT 1,\
            `equipped_loadout`  INT             NOT NULL DEFAULT 0,\
            PRIMARY KEY (\
                `id`,\
                `steam2_id`,\
                `steam3_id`,\
                `steam64_id`),\
            UNIQUE INDEX `id_UNIQUE` (`id` ASC) VISIBLE,\
            UNIQUE INDEX `steam2_id_UNIQUE` (`steam2_id` ASC) VISIBLE,\
            UNIQUE INDEX `steam3_id_UNIQUE` (`steam3_id` ASC) VISIBLE,\
            UNIQUE INDEX `steam64_id_UNIQUE` (`steam64_id` ASC) VISIBLE);");
    SEND_CREATE_TABLE_QUERY;

    // Ignore Table
    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.players_ignore (IGNORE TABLE)");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`players_ignore`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`players_ignore` (\
            `steam64_id`        VARCHAR(64) NOT NULL DEFAULT `UNKNOWN`,\
            `ignore_target_id`  VARCHAR(64) NOT NULL DEFAULT `UNKNOWN`,\
            `ignoring_voice`    INT         NOT NULL DEFAULT 0,\
            `ignoring_text`     INT         NOT NULL DEFAULT 0,\
            PRIMARY KEY (\
                `steam64_id`,\
                `ignore_target_id`\
            ),\
            CONSTRAINT `steam64_id`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players_ignore` (`steam64_id`)\
                ON DELETE NO ACTION\
                ON UPDATE NO ACTION);");
    SEND_CREATE_TABLE_QUERY;

    // Store Tables
    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_groups");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`store_groups`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`store_groups` (\
            `id`    INT         NOT NULL AUTO_INCREMENT,\
            `name`  VARCHAR(64) NULL\
            PRIMARY KEY (`id`));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_sounds");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`store_sounds`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`store_sounds` (\
            `item_id`       VARCHAR(64) NOT NULL DEFAULT `INVALID`,\
            `name`          VARCHAR(64) NOT NULL DEFAULT `INVALID`,\
            `filepath`      VARCHAR(256) NOT NULL DEFAULT `INVALID`,\
            `cooldown`      DECIMAL NOT NULL DEFAULT 0.1,\
            `price`         INT NOT NULL DEFAULT 0,\
            `creator_id`      VARCHAR(64) NOT NULL DEFAULT `QUASAR`\
            PRIMARY KEY (\
                `item_id`,\
                `name`,\
                `filepath`,\
                `creator_id`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_trails");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`store_trails`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`store_trails` (\
            `item_id`       VARCHAR(64) NOT NULL DEFAULT `INVALID`,\
            `name`          VARCHAR(64) NOT NULL DEFAULT `INVALID`,\
            `vtf_filepath`  VARCHAR(256) NOT NULL DEFAULT `INVALID`,\
            `vmt_filepath`  VARCHAR(256) NOT NULL DEFAULT `INVALID`,\
            `price`         INT NOT NULL DEFAULT 0,\
            `creator_id`      VARCHAR(64) NOT NULL DEFAULT `QUASAR`,\
            PRIMARY KEY (\
                `item_id`,\
                `name`,\
                `creator_id`,\
                `vtf_filepath`,\
                `vmt_filepath`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_tags");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`store_tags`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`store_tags` (\
            `item_id`       VARCHAR(64) NOT NULL DEFAULT `INVALID`,\
            `name`          VARCHAR(64) NOT NULL DEFAULT `INVALID`,\
            `display`       VARCHAR(64) NOT NULL DEFAULT `{pink}[IN{black}VAL{PINK}ID]`,\
            `price`         INT NOT NULL DEFAULT 0,\
            `creator_id`    VARCHAR(64) NOT NULL DEFAULT `QUASAR`,\
            PRIMARY KEY (\
                `item_id`,\
                `name`,\
                `display`,\
                `creator_id`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_upgrades");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`store_upgrades`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`store_upgrades` (\
            `item_id`       VARCHAR(64)  NOT NULL DEFAULT `INVALID`,\
            `name`          VARCHAR(64)  NOT NULL DEFAULT `INVALID`,\
            `description    VARCHAR(128) NOT NULL DEFAULT `INVALID`\
            `price`         INT NOT NULL DEFAULT 0,\
            `function_name` VARCHAR(128) NOT NULL DEFAULT `INVALID`,\
            `plugin_name`   VARCHAR(128) NOT NULL DEFAULT `INVALID`,\
            `creator_id`    VARCHAR(64) NOT NULL DEFAULT `QUASAR`,\
            PRIMARY KEY (\
                `item_id`,\
                `name`,\
                `function_name`,\
                `creator_id`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    //TODO: CHAT COLORS WILL BE HANDLED UNDER NEW "CUSTOM NICKNAME"
    //SYSTEM.
    //
    //Players will be able to paint their name or their chat
    //an entire color as before, or they can save their name
    //with color tags to have a multicolored name.
    //
    //Players will need Custom Nickname, then Custom Name Colors
    //Players can buy Custom Chat Colors separately.
    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_chat_colors");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`store_chat_colors`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`store_chat_colors` (\
            `color_id`          INT NOT NULL AUTO_INCREMENT,\
            `color_format`      VARCHAR(64) NOT NULL DEFAULT `INVALID`\
            `color_name`        VARCHAR(64) NOT NULL DEFAULT `INVALID`\
            `color_category`    VARCHAR(16) NOT NULL DEFAULT `INVALID`\
            PRIMARY KEY (\
                `color_id`,\
                `color_format`,\
                `color_name`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_chat_pack_names");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`store_chat_pack_names`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`store_chat_pack_names` (\
            `id`    INT NOT NULL AUTO_INCREMENT,\
            `name`  VARCHAR(64) NOT NULL DEFAULT `UNKNOWN`,\
            PRIMARY KEY (\
                `id`,\
                `name`\
            ));");
    SEND_CREATE_TABLE_QUERY;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATED MAIN GLOBAL TABLES======"
    )
}

void Internal_GenerateSubserverTables() {
    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING MAIN TABLES FOR %s======",
        gS_subserver);

    char s_query[2048];
    char s_tableName[64];
    // Per sub-server main tables
    // Player Stats Table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_stats (PLAYER STATS TABLE FOR SUBSERVER %s)",
        gS_subserver, gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_stats`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_stats` (\
            `id`            INT         NOT NULL AUTO_INCREMENT,\
            `steam64_id`    VARCHAR(64) NOT NULL DEFAULT `UNKNOWN`,\
            `points`        DECIMAL     NOT NULL DEFAULT `0.0`,\
            `kills`         INT         UNSIGNED NOT NULL DEFAULT 0,\
            `afk_points`    DECIMAL     NOT NULL DEFAULT `0.0`\
            `afk_kills`     INT         UNSIGNED NOT NULL DEFAULT 0,\
            `first_login`   INT         NOT NULL DEFAULT `-1`\
            `last_login`    INT         NOT NULL DEFAULT `-1`\
            `playtime`      INT         NOT NULL DEFAULT `0`\
            `time_afk`      INT         NOT NULL DEFAULT `0`,\
            PRIMARY KEY (\
                `id`,\
                `steam64_id`),\
            CONSTRAINT `FK_players_%s_stats`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);",
        gS_subserver,
        gS_subserver,
        gS_subserver);
    SEND_CREATE_TABLE_QUERY;

    // Map Table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_maps (MAP TABLE FOR %s)",
        gS_subserver, gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_maps`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_maps`(\
            `id`            INT             NOT NULL AUTO_INCREMENT,\
            `name`          VARCHAR(128)    NOT NULL DEFAULT `UNKNOWN`\
            `category`      VARCHAR(64)     NOT NULL DEFAULT `NONE`,\
            `author`        VARCHAR(128)    NOT NULL DEFAULT `UNKNOWN`\
            `workshop_id`   VARCHAR(128)    NULL DEFAULT NULL\
            PRIMARY KEY (\
                `id`,\
                `name`),\
            UNIQUE INDEX `id_UNIQUE` (`id` ASC) VISIBLE,\
            UNIQUE INDEX `name_UNIQUE` (`name` ASC) VISIBLE);",
        gS_subserver,
        gS_subserver);
    SEND_CREATE_TABLE_QUERY;

    // Vote Log Table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_vote_log (VOTE LOGS FOR SUBSERVER %s)",
        gS_subserver,
        gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_vote_log`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_vote_log` (\
            `id`                INT NOT NULL AUTO_INCREMENT,\
            `vote_type`         INT NOT NULL DEFAULT 0,\
            `voter_steam_id`    VARCHAR(64) NOT NULL DEFAULT `UNKNOWN`,\
            `target_steam_id`   VARCHAR(64) NOT NULL DEFAULT `UNKNOWN`,\
            `voter_name`        VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            `target_name`       VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            `date`              INT NOT NULL DEFAULT -1,\
            PRIMARY KEY (\
                `id`,\
                `voter_steam_id`),\
            INDEX `FK_vote_log_players_idx` (`voter_steam_id` ASC) VISIBLE,\
            INDEX `FK_vote_log_players2_idx` (`target_steam_id` ASC) VISIBLE,\
            CONSTRAINT `FK_vote_log_players`\
                FOREIGN KEY (`voter_steam_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE,\
            CONSTRAINT `FK_vote_log_players2`\
                FOREIGN KEY (`target_steam_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`)\
                ON DELETE NO ACTION\
                ON UPDATE NO ACTION);",
        gS_subserver,
        gS_subserver);
    SEND_CREATE_TABLE_QUERY;

    // Chat log table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_chat_log (CHAT LOGS FOR SUBSERVER %s)",
        gS_subserver,
        gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_chat_log`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_chat_log` (\
            `id`            INT NOT NULL AUTO_INCREMENT,\
            `steam64_id`    VARCHAR(64) NOT NULL DEFAULT `UNKNOWN`,\
            `message`       VARCHAR(256) NULL DEFAULT `NONE`,\
            `date`          INT NOT NULL -1,\
            PRIMARY KEY (\
                `id`,\
                `steam64_id`),\
            INDEX `FK_%s_chat_log_players_idx` (`steam64_id` ASC) VISIBLE,\
            CONSTRAINT `FK_%s_chat_log_players`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);",
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver);
    SEND_CREATE_TABLE_QUERY;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATED MAIN TABLES FOR %s======",
        gS_subserver);
}

void Internal_GenerateTFJunctionTables() {
    char s_query[2048];
    char s_tableName[64];

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING TF JUNCTION TABLES======");

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_items_classes");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.``;\
        CREATE TABLE IF NOT EXISTS `quasar`.`` (\
            ``\
            PRIMARY KEY (\
                ``\
            ),\
            CONSTRAINT `FK_`\
                FOREIGN KEY (``)\
                REFERENCES `quasar`.`` (``)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_items_attributes");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.``;\
        CREATE TABLE IF NOT EXISTS `quasar`.`` (\
            ``\
            PRIMARY KEY (\
                ``\
            ),\
            CONSTRAINT `FK_`\
                FOREIGN KEY (``)\
                REFERENCES `quasar`.`` (``)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);");
    SEND_CREATE_TABLE_QUERY;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATED TF JUNCTION TABLES======");
}

void Internal_GenerateGlobalJunctionTables() {
    char s_query[2048];
    char s_tableName[64];

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING GLOBAL JUNCTION TABLES======");

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_players_groups");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`store_players_groups`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`store_players_groups` (\
            `steam64_id` VARCHAR(64)    NOT NULL DEFAULT `UNKNOWN`\
            `group_id`   INT            NULL     DEFAULT NULL\
            PRIMARY KEY (\
                `steam64_id`,\
                `group_id`\
            ),\
            CONSTRAINT `FK_storeplayersgroups_groups`\
                FOREIGN KEY (`group_id`)\
                REFERENCES `quasar`.`store_groups` (`id`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_colors_packs");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.``;\
        CREATE TABLE IF NOT EXISTS `quasar`.`` (\
            ``\
            PRIMARY KEY (\
                ``\
            ),\
            CONSTRAINT `FK_`\
                FOREIGN KEY (``)\
                REFERENCES `quasar`.`` (``)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_players_items");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.``;\
        CREATE TABLE IF NOT EXISTS `quasar`.`` (\
            ``\
            PRIMARY KEY (\
                ``\
            ),\
            CONSTRAINT `FK_`\
                FOREIGN KEY (``)\
                REFERENCES `quasar`.`` (``)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_quasar_loadouts");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.``;\
        CREATE TABLE IF NOT EXISTS `quasar`.`` (\
            ``\
            PRIMARY KEY (\
                ``\
            ),\
            CONSTRAINT `FK_`\
                FOREIGN KEY (``)\
                REFERENCES `quasar`.`` (``)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_tf_loadouts");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.``;\
        CREATE TABLE IF NOT EXISTS `quasar`.`` (\
            ``\
            PRIMARY KEY (\
                ``\
            ),\
            CONSTRAINT `FK_`\
                FOREIGN KEY (``)\
                REFERENCES `quasar`.`` (``)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_sound_loadouts");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.``;\
        CREATE TABLE IF NOT EXISTS `quasar`.`` (\
            ``\
            PRIMARY KEY (\
                ``\
            ),\
            CONSTRAINT `FK_`\
                FOREIGN KEY (``)\
                REFERENCES `quasar`.`` (``)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);");
    SEND_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.store_taunt_loadouts");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.``;\
        CREATE TABLE IF NOT EXISTS `quasar`.`` (\
            ``\
            PRIMARY KEY (\
                ``\
            ),\
            CONSTRAINT `FK_`\
                FOREIGN KEY (``)\
                REFERENCES `quasar`.`` (``)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);");
    SEND_CREATE_TABLE_QUERY;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATED GLOBAL JUNCTION TABLES======");
}

void Internal_GenerateSubserverJunctionTables() {
    char s_query[2048];
    char s_tableName[64];

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING JUNCTION TABLES FOR %s======",
        gS_subserver);

    // Map feedback table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_maps_feedback (MAP FEEDBACK FOR SUBSERVER %s)",
        gS_subserver,
        gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_maps_feedback`\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_maps_feedback` (\
            `id`            VARCHAR(64)     NOT NULL AUTO_INCREMENT,\
            `map_name`      VARCHAR(128)    NOT NULL DEFAULT `NONE`,\
            `steam64_id`    VARCHAR(64)     NOT NULL DEFAULT `UNKNOWN`,\
            `pos_x`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `pos_y`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `pos_z`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `ang_x`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `ang_y`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `ang_z`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `feedback`      VARCHAR(128)    NOT NULL DEFAULT ``,\
            PRIMARY KEY (\
                `id`,\
                `map`,\
                `steam64_id`\
            ),\
            UNIQUE INDEX `id_UNIQUE` (`id` ASC) VISIBLE\
            CONSTRAINT `FK_%s_maps_feedback`\
                FOREIGN KEY (`map_name`)\
                REFERENCES `quasar`.`%s_maps` (`name`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE,\
            CONSTRAINT `FK_%s_maps_feedback_players`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);",
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver);
    SEND_CREATE_TABLE_QUERY;

    // Map Ratings Table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_maps_ratings (MAP RATINGS TABLE FOR SUBSERVER %s)",
        gS_subserver,
        gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_maps_ratings`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_maps_ratings` (\
            `map_name`      VARCHAR(128) NOT NULL DEFAULT `UNKNOWN`,\
            `steam64_id`    VARCHAR(64)  NOT NULL DEFAULT `UNKNOWN`,\
            `rating`        INT          NOT NULL DEFAULT 0,\
            PRIMARY KEY (\
                `map_name`,\
                `steam64_id`,\
                `rating`\
            ),\
            CONTRAINT `FK_%s_maps_ratings`\
                FOREIGN KEY (`map_name`)\
                REFERENCES `quasar`.`%s_maps` (`name`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE,\
            CONSTRAINT `FK_%s_players_ratings`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE);",
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver);
    SEND_CREATE_TABLE_QUERY;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATED JUNCTION TABLES FOR %s======",
        gS_subserver);
}

void Internal_GenerateGlobalTableViews() {
    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING GLOBAL VIEWS======");

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATED GLOBAL VIEWS======");
}

void Internal_GenerateSubserverTableViews() {
    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING VIEWS FOR %s======",
        gS_subserver);

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATED VIEWS FOR %s======",
        gS_subserver);
}

void Internal_GenerateSQLTriggers() {
    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING GLOBAL SQL TRIGGERS======");

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATED GLOBAL SQL TRIGGERS======");
}

void Internal_FillTableDefaults() {
        QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======FILLING TABLES WITH DEFAULTS======",
        gS_subserver);

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======FILLED TABLES WITH DEFAULTS======",
        gS_subserver);
}
#undef SEND_CREATE_TABLE_QUERY

void SQLCB_CreateTableCB(Database db, DBResultSet results, const char[] error, const char[] tableName)
{
    if (error[0]) {
        QSR_LogMessage(
            gH_dbLogFile,
            MODULE_NAME,
            "ERROR CREATING %s! %s",
            tableName,
            error);
        return;
    }

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "SUCESSFULLY CREATED %s!", tableName);
}

void SQLCB_FillTableDefaults(Database db, DBResultSet results, const char[] error, const char[] tableName) {
    if (error[0]) {
        QSR_LogMessage(
            gH_dbLogFile,
            MODULE_NAME,
            "ERROR FILLING %s WITH DEFAULTS! %s",
            tableName,
            error);
        return;
    }

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "SUCCESSFULLY FILLED %s WITH DEFAULTS!",
        tableName);
}

// TODO: MOVE ABOVE CODE TO quasar_generate_tables.sp

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
    Call_PushString(gS_subserver);
    Call_PushCell(sizeof(gS_subserver));
    Call_Finish();

    QSR_GenerateSQLTables();
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

