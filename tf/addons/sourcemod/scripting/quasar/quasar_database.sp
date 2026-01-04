#include <sourcemod>
#include <sdktools>
#include <quasar/core>
#include <quasar/database>

#include <autoexecconfig>

// Core Variables
static Database gH_db = null;
bool     gB_late = false;
static Transaction gH_DBTransaction = null;

// Database
static char gS_subserver[64];
static char gS_dbProfile[64]; // The database profile name in databases.cfg
static bool gB_dbConnected = false; // Are we connected to the database yet?
static bool gB_logTransactions = false; // Do we log all queries in a transaction?
static char gS_dbVersion[24]; // The version number of our database.
static bool gB_isTableUpdated[view_as<int>(NUM_DBTABLES)];
static QSRDBSetupStep gE_currentStep = WAITING_FOR_SETUP;

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
ConVar gH_CVR_dbLogTrans = null;

// Forwards
Handle gH_FWD_dbConnected = null; // Called when we've successfully connected to the database.
Handle gH_FWD_dbVersionRetrieved = null;

public Plugin myinfo =
{
    name = "[QUASAR] Quasar Plugin Suite (Database Handler)",
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
    gH_CVR_subserver            = AutoExecConfig_CreateConVar("sm_quasar_subserver",            "srv0",             "Controls what server subserver the system is running on. [koth1].server.tf The boxed area is a subserver. Used to get and set player statistics across different servers.", FCVAR_NONE);
    gH_CVR_dbLogTrans           = AutoExecConfig_CreateConVar("sm_quasar_log_transactions",     "0",                "Controls whether we wi ll log all queries in a transaction.", FCVAR_NONE, true, 0.0, true, 1.0);
    
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    gH_FWD_dbConnected = CreateGlobalForward("QSR_OnDatabaseConnected", ET_Ignore, Param_CellByRef, Param_String);
    gH_FWD_dbVersionRetrieved = CreateGlobalForward("QSR_OnDBVersionRetrieved", ET_Ignore, Param_String);

    HookConVarChange(gH_CVR_dbLogTrans, OnConVarChanged);

    RegAdminCmd("sm_qdb_refresh", CMD_DB_Refresh, ADMFLAG_UNBAN, "Refresh the connection to the Quasar Database.");
    RegAdminCmd("sm_qdb_drop_tables", CMD_DB_DropAllTables, ADMFLAG_ROOT, "Drops all tables in the Quasar Database without saving data!");
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
    gH_CVR_subserver.GetString(gS_subserver, sizeof(gS_subserver));
    gB_logTransactions = gH_CVR_dbLogTrans.BoolValue;
    Database.Connect(SQLCB_OnConnect, gS_dbProfile);
}

public void OnMapStart() {

}

public void OnMapEnd() {

}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == gH_CVR_dbLogTrans)
        gB_logTransactions = convar.BoolValue;
}

public void QSR_OnDBVersionRetrieved(const char[] dbVersion)
{
    if (gH_DBTransaction != null)
        gH_DBTransaction.Close();

    char s_directory[256];
    switch (Internal_IsDatabaseUpToDate()) {
        case DBVer_FirstTime: {
            BuildPath(
                Path_SM,
                s_directory,
                sizeof(s_directory),
                SQL_SETUP_DIR);
            for (gE_currentStep = DBStep_CreateVersionTable; 
                 gE_currentStep < NUM_SETUP_STEPS; 
                 gE_currentStep++) {
                    gH_DBTransaction = new Transaction();
                    Internal_DirectoryToTransaction(s_directory);
                    Internal_SendTableTrans(
                        SQLTxn_OnTablesCreated, 
                        SQLTxn_FailedToCreateTables,
                        _,
                        DBPrio_High);
                }
            }
        case DBVer_NeedsUpdated: {
            BuildPath(
                Path_SM,
                s_directory,
                sizeof(s_directory),
                SQL_ALTER_DIR);
            Internal_DirectoryToTransaction(s_directory);
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

void Internal_DropTables() {
    char s_query[512];
    for (int i = view_as<int>(NUM_DBTABLES); i > -1; i--) {
        FormatEx(
            s_query,
            sizeof(s_query),
            "DROP TABLE IF EXISTS `quasar`.`%s`",
            gS_tableNames[i]);
        gH_DBTransaction.AddQuery(s_query, i);
    }

    Internal_SendTableTrans(
        SQLTxn_OnTablesErased,
        SQLTxn_FailedToEraseTables,
        _, 
        DBPrio_High);
}

void Internal_DirectoryToTransaction(const char[] directory) {
    char s_tempPath[256];
    char s_finalPath[256];
    DirectoryListing h_dir = OpenDirectory(directory);
    FileType h_currentFileType = FileType_Unknown;
    if (h_dir == null) {
        QSR_LogMessage(
            MODULE_NAME,
            "ERROR! COULD NOT OPEN DIRECTORY %s",
            directory);
        return;
    }

    while(
        h_dir.GetNext(
            s_tempPath,
            sizeof(s_tempPath),
            h_currentFileType)) {
        char c_currentStep[3];

        if (gE_currentStep < view_as<QSRDBSetupStep>(10))
            FormatEx(
                c_currentStep,
                sizeof(c_currentStep),
                "0%d",
                view_as<int>(gE_currentStep));
        else
            IntToString(
                view_as<int>(gE_currentStep),
                c_currentStep,
                sizeof(c_currentStep));

        if (StrEqual(s_tempPath, ".") || 
            StrEqual(s_tempPath, "..") ||
            StrEqual(s_tempPath, "disabled", false))
            continue;

        FormatEx(
            s_finalPath,
            sizeof(s_finalPath),
            "%s/%s",
            directory,
            s_tempPath);

        if (StrContains(s_finalPath, c_currentStep) == -1)
            continue;
        
        switch (h_currentFileType) {
            case FileType_Directory:
                Internal_DirectoryToTransaction(s_finalPath);
            case FileType_File:
                Internal_AddSQLFileToTrans(s_finalPath);
            default:
                continue;
        }
    } // End of while loop 2
    h_dir.Close();
}

void Internal_AddSQLFileToTrans(const char[] sqlFile) {
    if (gH_DBTransaction == null) {
        QSR_LogMessage(
            MODULE_NAME,
            "ERROR! DB TRANSACTION DOESN'T EXIST");
        return;
    }
    File h_sqlFile = OpenFile(sqlFile, "r");
    // This shouldn't happen, but just in case.
    if (h_sqlFile == null || StrContains(sqlFile, ".sql") == -1) {
        QSR_LogMessage(
            MODULE_NAME,
            "ERROR! Attempting to open a null sql file: %s",
            sqlFile);
        return;
    }
    else if (StrContains(sqlFile, ".sql") == -1) {
        QSR_LogMessage(
            MODULE_NAME,
            "ERROR! Attempting to open a non-sql file: %s",
            sqlFile);
        h_sqlFile.Close();
        return;
    }

    char s_totalQuery[3256];
    char s_currentLine[1024];
    QSRDBTable e_currentTable;
    while (h_sqlFile.ReadLine(s_currentLine, sizeof(s_currentLine))) {
        if (StrContains(s_currentLine, "-- ?") != -1) {
            ReplaceString(s_currentLine,
                          sizeof(s_currentLine),
                          "-- ?",
                          "");
            e_currentTable = view_as<QSRDBTable>(StringToInt(s_currentLine[4]));
            continue;
        }

        ReplaceString(
            s_currentLine,
            sizeof(s_currentLine),
            "PLREPLACE",
            gS_subserver);

        FormatEx(
            s_totalQuery,
            sizeof(s_totalQuery),
            "%s%s",
            s_totalQuery,
            s_currentLine);
    }

    if (gB_logTransactions) {
        QSR_SilentLog(
            MODULE_NAME,
            "Table %d (%s):\n\n%s\n",
            view_as<int>(e_currentTable),
            gS_tableNames[view_as<int>(e_currentTable)],
            s_totalQuery);
    }
    
    gH_DBTransaction.AddQuery(s_totalQuery, e_currentTable);
    h_sqlFile.Close();
}

void Internal_SendTableTrans( SQLTxnSuccess success = INVALID_FUNCTION, 
                                    SQLTxnFailure fail = INVALID_FUNCTION,
                                    any data = 0,
                                    DBPriority dbPriority = DBPrio_Normal) {
    gH_db.Execute(
        gH_DBTransaction,
        success,
        fail,
        data,
        dbPriority);
    gH_DBTransaction = null;
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

// NATIVES
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
        gB_dbConnected = false;
        return;
    }

    // Make sure we actually SET the database handle. :eyeroll:
    gH_db = db;
    gB_dbConnected = true;

    Call_StartForward(gH_FWD_dbConnected);
    Call_PushCellRef(gH_db);
    Call_PushStringEx(gS_subserver, sizeof(gS_subserver), 0, SM_PARAM_STRING_COPY);
    Call_Finish();

    QSR_StartCheckDatabaseVersion();
}

void SQLCB_DatabaseVersionCB(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0]) {
        strcopy(
            gS_dbVersion,
            sizeof(gS_dbVersion),
            "NULL VERSION");
    } else {
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
    }

    Call_StartForward(gH_FWD_dbVersionRetrieved);
    Call_PushString(gS_dbVersion);
    Call_Finish();
}

void SQLCB_TableQueryError(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0]) {
        QSR_LogMessage(
            MODULE_NAME,
            "\nTable %d: %s\nERROR: %s\n",
            view_as<int>(data),
            gS_tableNames[view_as<int>(data)],
            error);
        return;
    }
}

void SQLTxn_OnTablesErased(Database db, any data, int numQueries, Handle[] results, QSRDBTable[] queryData)
{
    int tableNum;
    for (int i=0; i < numQueries; i++) {
        tableNum = view_as<int>(queryData[i]);
        gB_isTableUpdated[tableNum] = true;
        QSR_LogMessage(
            MODULE_NAME,
            "Table erased: %s",
            gS_tableNames[tableNum]);
    }
}

void SQLTxn_FailedToEraseTables(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    int tableNum;
    for (int i=0; i < numQueries; i++) {
        tableNum = view_as<int>(queryData[i]);
        if (i < failIndex) {
            gB_isTableUpdated[tableNum] = true;
            QSR_LogMessage(
               MODULE_NAME,
               "Table erased: %s",
               gS_tableNames[tableNum]);
            continue;
        }

        gB_isTableUpdated[tableNum] = false;
        QSR_LogMessage(
           MODULE_NAME,
           "Unable to erase table: %s",
           gS_tableNames[tableNum]);
    } 

    QSR_LogMessage(
        MODULE_NAME,
        "UNABLE TO ERASE TABLES!");
    QSR_LogMessage(
        MODULE_NAME,
        "ERROR AT QUERY %d/%d!\n%s",
        failIndex,
        numQueries,
        error);
    QSR_LogMessage(MODULE_NAME,"");
}

void SQLTxn_OnTablesCreated(Database db, any data, int numQueries, Handle[] results, QSRDBTable[] queryData)
{
    int tableNum;
    for (int i=0; i < numQueries; i++) {
        tableNum = view_as<int>(queryData[i]);
        gB_isTableUpdated[tableNum] = true;
        QSR_LogMessage(
            MODULE_NAME,
            "Table created: %s",
            gS_tableNames[tableNum]);
    }
}

void SQLTxn_FailedToCreateTables(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    int tableNum;
    for (int i=0; i < numQueries; i++) {
        tableNum = view_as<int>(queryData[i]);
        if (i < failIndex) {
            gB_isTableUpdated[tableNum] = true;
            QSR_LogMessage(
               MODULE_NAME,
               "Table created: %s",
               gS_tableNames[tableNum]);
            continue;
        }

        gB_isTableUpdated[tableNum] = false;
        QSR_LogMessage(
           MODULE_NAME,
           "Unable to create table: %s",
           gS_tableNames[tableNum]);
    } 

    QSR_LogMessage(
        MODULE_NAME,
        "UNABLE TO GENERATE TABLES!");
    QSR_LogMessage(
        MODULE_NAME,
        "ERROR AT QUERY %d/%d!\n%s",
        failIndex+1,
        numQueries,
        error);
    QSR_LogMessage(MODULE_NAME,"");
}

Action CMD_DB_DropAllTables(int client, int args) {
    Internal_DropTables();
    return Plugin_Handled;
}

Action CMD_DB_Refresh(int client, int args)
{
    RefreshDatabaseConfig();
    RefreshDatabaseConnection();

    return Plugin_Handled;
}