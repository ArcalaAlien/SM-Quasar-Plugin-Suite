#include <sourcemod>
#include <sdktools>
#include <quasar/core>
#include <quasar/database>

#include <autoexecconfig>

// Core Variables
Database gH_db = null;
File     gH_logFile = null;
bool     gB_late = false;
static Transaction gH_DBTransaction = null;

// Store stuff
int gI_fetchTrailsAttempts = 0;
int gI_fetchSoundsAttempts = 0;

// Database
static char gS_subserver[64];
static char gS_dbProfile[64]; // The database profile name in databases.cfg
static bool gB_dbConnected = false; // Are we connected to the database yet?
static char gS_dbVersion[24]; // The version number of our database.
static bool gB_isTableUpdated[view_as<int>(NUM_DBTABLES)];

// Replace SUBSERVER with gS_subserver if you
// use these table names!!!!
static char gS_tableNames[NUM_DBTABLES][] = {
    "quasar.db_version",
    "quasar.tf_classes",
    "quasar.tf_items",
    "quasar.tf_attributes",
    "quasar.tf_qualities",
    "quasar.tf_particles",
    "quasar.tf_paint_kits",
    "quasar.tf_war_paints",
    "quasar.players",
    "quasar.rank_titles",
    "quasar.players_ignore",
    "quasar.groups",
    "quasar.sounds",
    "quasar.trails",
    "quasar.tags",
    "quasar.upgrades",
    "quasar.fun_stuff",
    "quasar.chat_colors",
    "quasar.chat_pack_names",
    "quasar.SUBSERVER_stats",
    "quasar.SUBSERVER_maps",
    "quasar.SUBSERVER_vote_logs",
    "quasar.SUBSERVER_chat_logs",
    "quasar.tf_items_classes",
    "quasar.tf_items_attributes",
    "quasar.players_groups",
    "quasar.colors_packs",
    "quasar.player_items",
    "quasar.quasar_loadouts",
    "quasar.tf_loadouts",
    "quasar.taunt_loadouts",
    "quasar.SUBSERVER_maps_feedback",
    "quasar.SUBSERVER_maps_ratings",
    "quasar.[inventories]",
    "quasar.[SUBSERVER_map_ratings]"
};

// ConVars
ConVar gH_CVR_subserver = null;
ConVar gH_CVR_dbConfig = null;

// Forwards
Handle gH_FWD_dbConnected = null; // Called when we've successfully connected to the database.
Handle gH_FWD_dbVersionRetrieved = null;

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Database Handler)",
    author = PLUGIN_AUTHOR,
    description = "CRUD Controller for the quasar database.",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("quasar_database");
    CreateNative("QSR_RefreshDatabase", Native_QSRRefreshDatabase);
}

public void OnPluginStart()
{
    AutoExecConfig_SetFile("plugins.quasar_database");

    gH_CVR_dbConfig             = AutoExecConfig_CreateConVar("sm_quasar_db_profile",           "quasar",           "The default database configuration to use for Quasar", FCVAR_PROTECTED);
    gH_CVR_subserver            = AutoExecConfig_CreateConVar("sm_quasar_subserver",            "",                 "Controls what server subserver the system is running on. [koth1].server.tf The boxed area is a subserver. Used to get and set player statistics across different servers.", FCVAR_NONE);
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    gH_FWD_dbConnected = CreateGlobalForward("QSR_OnDatabaseConnected", ET_Ignore, Param_CellByRef, Param_Array, Param_Cell);

    RegAdminCmd("sm_qdb_refresh", CMD_DB_Refresh, ADMFLAG_UNBAN, "Refresh the connection to the Quasar Database.");
}

public void OnPluginEnd()
{
    gH_CVR_dbConfig.Close();
    gH_CVR_subserver.Close();
    gH_FWD_dbConnected.Close();
    gH_FWD_dbVersionRetrieved.Close();
    gH_db.Close();
}

public void OnConfigsExecuted()
{
    gH_CVR_dbConfig.GetString(gS_dbProfile, sizeof(gS_dbProfile));

   Database.Connect(SQLCB_OnConnect);
}

public void OnMapStart() {

}

public void OnMapEnd() {

}

public void QSR_OnLogFileMade(File& file)
{
    gH_logFile = file;
}

public void QSR_OnDBVersionRetrieved(char[] dbVersion, int len)
{
    switch (Internal_IsDatabaseUpToDate()) {
        case DBVer_FirstTime:
            Internal_DirectoryToTransaction(SQL_CREATE_DIR);
        case DBVer_NeedsUpdated:
            Internal_DirectoryToTransaction(SQL_ALTER_DIR);
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
        gH_logFile,
        gH_db,
        s_query,
        SQLCB_DatabaseVersionCB);
}

QSRDBVersionStatus Internal_IsDatabaseUpToDate() {
    if (StrEqual(gS_dbVersion, "NULL VERSION"))
        return DBVer_FirstTime;

    if (!StrEqual(gS_dbVersion, DATABASE_VERSION))
        return DBVer_NeedsUpdated;

    return DBVer_Equal;
}

void Internal_DirectoryToTransaction(const char[] directory) {
    gH_DBTransaction = new Transaction();
    char s_smFilePath[256];
    BuildPath(
        Path_SM,
        s_smFilePath,
        sizeof(s_smFilePath),
        directory);

    DirectoryListing h_dir = OpenDirectory(directory);
    FileType h_currentFileType = FileType_Unknown;
    if (h_dir == null) {
        QSR_LogMessage(
            gH_logFile,
            MODULE_NAME,
            "ERROR! COULD NOT OPEN DIRECTORY %s",
            directory);
        return;
    }

    while(
        h_dir.GetNext(
            s_smFilePath,
            sizeof(s_smFilePath),
            h_currentFileType)) {
        switch (h_currentFileType) {
            case FileType_Directory:
                Internal_DirectoryToTransaction(s_smFilePath);
            case FileType_File:
                Internal_AddCreateTableToTrans(s_smFilePath);
            default:
                continue;
        }
    }
}

void Internal_AddCreateTableToTrans(const char[] sqlFile) {
    File h_sqlFile = OpenFile(sqlFile, "r");

    // This shouldn't happen, but just in case.
    if (h_sqlFile == null) {
        QSR_LogMessage(
            gH_logFile,
            MODULE_NAME,
            "ERROR! Attempting to open a null sql file: %s",
            sqlFile
        );
        return;
    }

    char s_totalQuery[2048];
    char s_currentLine[256];
    QSRDBTable e_currentTable;
    while (h_sqlFile.ReadLine(s_currentLine, sizeof(s_currentLine))) {
        if (StrContains(s_currentLine, "--?")) {
            ReplaceString(
                s_currentLine,
                sizeof(s_currentLine),
                "--?",
                "");
            e_currentTable = view_as<QSRDBTable>(StringToInt(s_currentLine));
            continue;
        }

        StrCat(
            s_totalQuery,
            sizeof(s_totalQuery),
            s_currentLine);
    }
    gH_DBTransaction.AddQuery(s_totalQuery, e_currentTable);
}

void Internal_SendCreateTableTrans() {
    gH_db.Execute(
        gH_DBTransaction,
        SQLTxn_OnTablesCreated,
        SQLTxn_FailedToCreateTables,
        .priority=DBPrio_High
    );
    gH_DBTransaction.Close();
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

/**
 *  Grabs the db config from the corresponding cvars.
 *
 * */
void RefreshDatabaseConfig()
{
    gH_CVR_dbConfig.GetString(gS_dbProfile, sizeof(gS_dbProfile));
}

void Timer_RetryPrecacheTrails(Handle timer)
{
    if (gI_fetchTrailsAttempts == 5)
    {
        QSR_LogMessage(gH_logFile,  MODULE_NAME, "Unable to precache store sounds after 5 attempts!");
        gI_fetchTrailsAttempts = 0;
        return;
    }

    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT vtf, vmt \
    FROM str_trails");
    QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_PrecacheTrails);
}

void Timer_RetryPrecacheSounds(Handle timer)
{
    if (gI_fetchSoundsAttempts == 5)
    {
        QSR_LogMessage(gH_logFile,  MODULE_NAME, "Unable to precache store sounds after 5 attempts!");
        gI_fetchSoundsAttempts = 0;
        timer.Close();
        return;
    }

    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT filepath \
    FROM str_sounds");
    QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_PrecacheSounds);
}


void Native_QSRRefreshDatabase(Handle plugin, int numParams)
{
    CMD_DB_Refresh(0, 0);
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
    Call_PushString(gS_subserver);
    Call_PushCell(sizeof(gS_subserver));
    Call_Finish();

    QSR_StartCheckDatabaseVersion();
}

void SQLCB_DatabaseVersionCB(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0]) {
        QSR_LogMessage(
            gH_logFile,
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

void SQLCB_PrecacheTrails(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0])
    {
        QSR_LogMessage(gH_logFile,  MODULE_NAME, "Unable to precache system trail textures! Retrying in 5s.\nERROR: %s", error);
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
        QSR_LogMessage(gH_logFile,  MODULE_NAME, "Unable to precache system sounds! Retrying in 5s.\nERROR: %s", error);
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

void SQLTxn_OnTablesCreated(Database db, any data, int numQueries, Handle[] results, QSRDBTable[] queryData)
{
    for (int i=0; i < numQueries; i++) {
        gB_isTableUpdated[queryData[i]] = true;
        QSR_LogMessage(
            gH_logFile,
            MODULE_NAME,
            "Table Created: %s",
            gS_tableNames[queryData[i]]);
    }
}

void SQLTxn_FailedToCreateTables(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    QSR_LogMessage(
        gH_logFile,
        MODULE_NAME,
        "UNABLE TO GENERATE TABLES! ERROR AT QUERY %d/%d! %s",
        failIndex,
        numQueries,
        error);

    for (int i=0; i < numQueries; i++) {
        if (i < failIndex) {
            gB_isTableUpdated[queryData[i]] = true;
            QSR_LogMessage(
                gH_logFile,
                MODULE_NAME,
                "Table Created: %s",
                gS_tableNames[queryData[i]]);
            continue;
        }

        gB_isTableUpdated[queryData[i]] = false;
        QSR_LogMessage(
            gH_logFile,
            MODULE_NAME,
            "Unable to create table %s",
            gS_tableNames[queryData[i]]);
    }
}

Action CMD_DB_Refresh(int client, int args)
{
    RefreshDatabaseConfig();
    RefreshDatabaseConnection();

    return Plugin_Handled;
}
