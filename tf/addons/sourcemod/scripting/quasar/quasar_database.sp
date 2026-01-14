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
static QSRDBSetupStep gE_currentSetupStep = WAITING_FOR_SETUP;

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
    "quasar.color_packs",
    "quasar.SUBSERVER_stats",
    "quasar.SUBSERVER_maps",
    "quasar.SUBSERVER_vote_logs",
    "quasar.SUBSERVER_chat_logs",
    "quasar.tf_items_classes",
    "quasar.tf_items_attributes",
    "quasar.players_groups",
    "quasar.colors_in_packs",
    "quasar.player_items",
    "quasar.quasar_loadouts",
    "quasar.tf_loadouts",
    "quasar.taunt_loadouts",
    "quasar.SUBSERVER_maps_feedback",
    "quasar.SUBSERVER_maps_ratings",
    "quasar.[inventories]",
    "quasar.[SUBSERVER_map_ratings]"
};

static char gS_stepNumbers[][] = {
    "00",
    "01", "02", "03", "04", "05", "06",
    "07", "08", "09", "10", "11", "12"
};

static char gS_setupStepNames[NUM_SETUP_STEPS][] = {
    "Setup Init",
    "Create Version Table",
    "Create Team Fortress Tables",
    "Create Main Tables",
    "Create Subserver Tables",
    "Create Junction Tables",
    "Create Team Fortress Loadout Tables",
    "Create Taunt Loadout Tables",
    "Create Database Views",
    "Fill Main Tables with Defaults",
    "Fill Junction Tables with Defaults"
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
            gE_currentSetupStep = DBStep_SetupInit;
            BuildPath(
                Path_SM,
                s_directory,
                sizeof(s_directory),
                SQL_SETUP_DIR);
            Internal_SendDBTransaction(
                SQLTxn_OnTablesCreated, 
                SQLTxn_SetupQueryFailed,
                _,
                DBPrio_High);
        }
        case DBVer_UpdateRequired: {
            if (gH_DBTransaction != null)
                gH_DBTransaction.Close();

            // Before we can dump the tables to preserve data,
            // we have to get the column information for each table
            // because columns are not stored in any particular order.
            gH_DBTransaction = new Transaction();
            for (QSRDBTable i = DBTable_TFClasses;
                 i < NUM_DBTABLES;
                 i++)
                Internal_AddTableToInfoTransaction(i);
            
            Internal_SendDBTransaction(
                SQLTxn_OnColumnInfoFetched,
                SQLTxn_FailedToFetchColumnInfo,
                _,
                DBPrio_High);
        }
        default:
            QSR_LogMessage(
                MODULE_NAME,
                "QUASAR DB UP TO DATE! VERSION %s",
                gS_dbVersion);
    }

}

// Here we create the query to check the DB version
void QSR_StartCheckDatabaseVersion() {
    char s_query[512];
    strcopy(s_query, sizeof(s_query),
        "SELECT `qdb_version` \
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
        return DBVer_UpdateRequired;

    return DBVer_Equal;
}

void Internal_DropTables() {
    gH_DBTransaction = new Transaction();
    char s_query[512];
    for (int i = view_as<int>(NUM_DBTABLES)-1; 
         i > view_as<int>(DBTable_Version);
         i--) {
        FormatEx(
            s_query,
            sizeof(s_query),
            "DROP TABLE IF EXISTS `quasar`.`%s`",
            gS_tableNames[i]);

        if (StrContains(s_query, "SUBSERVER") != -1) {
            ReplaceString(
                s_query,
                sizeof(s_query),
                "SUBSERVER",
                gS_subserver,
                false);
        }
        
        QSR_LogMessage(
            MODULE_NAME,
            "%s",
            s_query);
        gH_DBTransaction.AddQuery(s_query, i);
    }

    Internal_SendDBTransaction(
        SQLTxn_OnTablesErased,
        SQLTxn_SetupQueryFailed,
        _, 
        DBPrio_High);
}

void Internal_Setup_DirectoryToTransaction(const char[] directory) {
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
    if (gH_DBTransaction == null)
        gH_DBTransaction = new Transaction();
    
    while(
        h_dir.GetNext(
            s_tempPath,
            sizeof(s_tempPath),
            h_currentFileType)) {

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
        switch (h_currentFileType) {
            case FileType_Directory: {
                if (StrContains(s_tempPath, gS_stepNumbers[view_as<int>(gE_currentSetupStep)]) == -1)
                    continue;

                Internal_Setup_DirectoryToTransaction(s_finalPath);
            }
            case FileType_File: {
                // // If we're not on the current step, we shouldn't be
                // // adding any files from this directory, as long as
                // // it's not the main setup directory.
                if (StrContains(directory, gS_stepNumbers[view_as<int>(gE_currentSetupStep)]) == -1 &&
                    !StrEqual(directory, SQL_SETUP_DIR, false))
                    continue;
                
                // each sql file is its own step.
                if (StrEqual(s_tempPath, "01_version_table.sql", false) && 
                    gE_currentSetupStep != DBStep_CreateVersionTable)
                    continue;
                else if (StrEqual(s_tempPath, "06_tf_loadouts.sql", false) && 
                    gE_currentSetupStep != DBStep_CreateTFLoadoutTable)
                    continue;
                else if (StrEqual(s_tempPath, "07_taunt_loadouts.sql", false) && 
                    gE_currentSetupStep != DBStep_CreateTauntLoadoutTable)
                    continue;

                Internal_AddSQLFileToTrans(s_finalPath);
            }
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
    if (h_sqlFile == null) {
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
    char s_currentLine[196];
    QSRDBTable e_currentTable;
    bool b_isInsert = false;
    char s_tableName[64];
    while (h_sqlFile.ReadLine(s_currentLine, sizeof(s_currentLine))) {
        if (StrContains(s_currentLine, "-- ?", false) != -1) {
            ReplaceString(s_currentLine,
                          sizeof(s_currentLine),
                          "-- ?",
                          "");
            e_currentTable = view_as<QSRDBTable>(StringToInt(s_currentLine));
            continue;
        }

        if (StrContains(s_currentLine, "PLREPLACE", false) != -1) {
            ReplaceString(
                s_currentLine,
                sizeof(s_currentLine),
                "PLREPLACE",
                gS_subserver,
                false);
        }

        // Check if this is an INSERT or REPLACE statement, but NOT a CREATE statement (like CREATE VIEW)
        if ((StrContains(s_currentLine, "INSERT INTO", false) != -1 ||
             StrContains(s_currentLine, "REPLACE INTO", false) != -1) &&
            StrContains(s_currentLine, "CREATE", false) == -1) {
            b_isInsert = true;
        }

        if (b_isInsert) {
            static char s_insertLine[196];

            // If we're on the INSERT / REPLACE line, store it for later.
            if (StrContains(s_currentLine, "VALUES", false) != -1) {
                strcopy(
                    s_insertLine,
                    sizeof(s_insertLine),
                    s_currentLine);
                continue;
            }

            // First we need to get the table name 
            strcopy(
                s_tableName,
                sizeof(s_tableName),
                gS_tableNames[view_as<int>(e_currentTable)]);

            // Make sure we replace SUBSERVER with the actual
            // subserver name if needed.
            if (StrContains(s_tableName, "SUBSERVER") != -1) {
                ReplaceString(
                    s_tableName,
                    sizeof(s_tableName),
                    "SUBSERVER",
                    gS_subserver,
                    false);
            }

            // Remove any semicolons at the end of the line
            if (StrContains(s_currentLine, ";", false) != -1) {
                ReplaceString(
                    s_currentLine,
                    sizeof(s_currentLine),
                    ";\n",
                    "",
                    false);
            }

            // Gotta remove any commas and new lines for the statement
            if (StrContains(s_currentLine, "),\n", false) != -1)
                ReplaceString(
                    s_currentLine,
                    sizeof(s_currentLine),
                    "),\n",
                    ")",
                    false);
            else if (StrContains(s_currentLine, "), ", false) != -1)
                ReplaceString(
                    s_currentLine,
                    sizeof(s_currentLine),
                    "), ",
                    ")",
                    false);
            else if (StrContains(s_currentLine, "),", false) != -1)
                ReplaceString(
                    s_currentLine,
                    sizeof(s_currentLine),
                    "),",
                    ")",
                    false);

            // Now we can format the full query
            FormatEx(
                s_totalQuery,
                sizeof(s_totalQuery),
                "%s%s;\n",
                s_insertLine,
                s_currentLine);

            DataPack h_queryInfo = new DataPack();
            h_queryInfo.WriteString(s_totalQuery);
            h_queryInfo.WriteCell(e_currentTable);

            gH_DBTransaction.AddQuery(s_totalQuery, h_queryInfo);
            continue;
        } // End of insert check

        // Send a normal query
        FormatEx(
            s_totalQuery,
            sizeof(s_totalQuery),
            "%s%s",
            s_totalQuery,
            s_currentLine);
    }

    if (gB_logTransactions)
        QSR_SilentLog(
            MODULE_NAME,
            "Table %d (%s):\n\n%s",
            view_as<int>(e_currentTable),
            gS_tableNames[view_as<int>(e_currentTable)],
            s_totalQuery);

    DataPack h_queryInfo = new DataPack();
    h_queryInfo.WriteString(s_totalQuery);
    h_queryInfo.WriteCell(e_currentTable);

    gH_DBTransaction.AddQuery(s_totalQuery, h_queryInfo);
    h_sqlFile.Close();
}

void Internal_SendDBTransaction( SQLTxnSuccess success = INVALID_FUNCTION, 
                                    SQLTxnFailure fail = INVALID_FUNCTION,
                                    any data = 0,
                                    DBPriority dbPriority = DBPrio_Normal) {


    if (gE_currentSetupStep == DBStep_SetupInit) {
        char s_directory[256];
        BuildPath(
            Path_SM,
            s_directory,
            sizeof(s_directory),
            SQL_SETUP_DIR);
        
        gE_currentSetupStep++;
        Internal_Setup_DirectoryToTransaction(s_directory);
    }
    
    QSR_LogMessage(
        MODULE_NAME,
        "Current Step: %s %s",
        gS_stepNumbers[view_as<int>(gE_currentSetupStep)],
        gS_setupStepNames[view_as<int>(gE_currentSetupStep)]
    );

    gH_db.Execute(
        gH_DBTransaction,
        success,
        fail,
        data,
        dbPriority);
    gH_DBTransaction = null;
}

// This will automatically replace the subserver
// placeholder in the table name with the current subserver name
bool Internal_GetTableName(QSRDBTable e_table, char[] s_tableName, int maxlength) {
    if (e_table < DBTable_Version ||
        e_table >= NUM_DBTABLES)
        return false;

    char s_temp[64];
    strcopy(s_temp, 
            sizeof(s_temp), 
            gS_tableNames[view_as<int>(e_table)]);
    ReplaceString(s_temp, 
                  sizeof(s_temp),
                  "SUBSERVER", 
                  gS_subserver, 
                  false);
    strcopy(
        s_tableName, 
        maxlength, 
        s_temp);
    return true;
}

QSRDBTable Internal_GetTableFromName(const char[] s_tableName) {
    for (int i = 0; i < view_as<int>(NUM_DBTABLES); i++)
        if (StrEqual(gS_tableNames[i], s_tableName))
            return view_as<QSRDBTable>(i);

    return view_as<QSRDBTable>(-1);
}

void Internal_AddTableToInfoTransaction(QSRDBTable e_table)
{
    char s_query[512],
         s_tableName[64];

    Internal_GetTableName(e_table,
                          s_tableName,
                          sizeof(s_tableName));

    ReplaceString(s_tableName,
                  sizeof(s_tableName),
                  "SUBSERVER",
                  gS_subserver,
                  false);

    FormatEx(s_query,
             sizeof(s_query),
             "SELECT `column_name`, `data_type` \
             FROM INFORMATION_SCHEMA.COLUMNS \
             WHERE `table_name` = '%s';",
             s_tableName);

    if (gB_logTransactions)
        QSR_SilentLog(
            MODULE_NAME,
            "Table %d (%s):\n\n%s",
            view_as<int>(e_table),
            gS_tableNames[view_as<int>(e_table)],
            s_query);

    gH_DBTransaction.AddQuery(s_query, e_table);
}

bool Internal_CreateSelectQueryForUnknownColumns(char[] query, int maxlength, ArrayList columnList) {
    char s_tableName[64],
         s_columnName[64];

    strcopy (query,
             maxlength,
             "SELECT ");

    StringMap h_columnInfo;
    for (int i; i < columnList.Length; i++) {
        h_columnInfo = columnList.Get(i);

        if (h_columnInfo == null)
            return false;

        h_columnInfo.GetString(SQL_TABLE_NAME_KEY, s_tableName, sizeof(s_tableName));
        h_columnInfo.GetString(SQL_COLUMN_NAME_KEY, s_columnName, sizeof(s_columnName));

        FormatEx(s_columnName,
                sizeof(s_columnName),
                "`%s`",
                s_columnName);
        if (i < columnList.Length - 1)
            StrCat(s_columnName, 
                   sizeof(s_columnName),
                   ", ");
        StrCat(query,
               maxlength,
               s_columnName);
    }
    
    char s_temp[128];
    FormatEx(s_temp,
             sizeof(s_temp),
             "FROM `%s`;",
             s_tableName);
    StrCat(query,
           maxlength,
           s_temp);
    return true;
}

void Internal_GetColumnDataType(const char[] s_dataType, QSRDBColDataType &e_dataType) {
    if (StrEqual(s_dataType, "INT", false) ||
        StrEqual(s_dataType, "INTEGER", false) ||
        StrEqual(s_dataType, "BIGINT", false) ||
        StrEqual(s_dataType, "MEDIUMINT", false) ||
        StrEqual(s_dataType, "SMALLINT", false) ||
        StrEqual(s_dataType, "TINYINT", false))
        e_dataType = DBColType_Int;
    else if (StrEqual(s_dataType, "FLOAT", false) ||
             StrEqual(s_dataType, "DOUBLE", false) ||
             StrEqual(s_dataType, "DECIMAL", false) ||
             StrEqual(s_dataType, "NUMERIC", false))
        e_dataType = DBColType_Float;
    else if (StrEqual(s_dataType, "CHAR", false) ||
             StrEqual(s_dataType, "VARCHAR", false) ||
             StrEqual(s_dataType, "TEXT", false))
        e_dataType = DBColType_String;
    else
        e_dataType = DBColType_Bool;
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

void SQLTxn_OnColumnInfoFetched(Database db, any data, int numQueries, DBResultSet[] results, QSRDBTable[] queryData)
{
    char s_tableName[64],
         s_columnName[64],
         s_dataType[64],
         s_temp[64],
         s_query[1024];

    if (gH_DBTransaction != null)
        gH_DBTransaction.Close(); 
    gH_DBTransaction = new Transaction();

    int i_currentColumn = 0;
    for (int i; i < numQueries; i++) {
        Internal_GetTableName(queryData[i],
                              s_tableName,
                              sizeof(s_tableName));
        FormatEx(s_temp,
                 sizeof(s_temp),
                 "%s_%d",
                 SQL_TABLE_NAME_KEY,
                 i);

        ArrayList h_tableColumnList = new ArrayList();
        while (results[i].FetchRow()) {
            results[i].FetchString(0,
                    s_columnName,
                    sizeof(s_columnName));
            results[i].FetchString(1,
                    s_dataType,
                    sizeof(s_dataType));

            StringMap h_columnInfo = new StringMap();
            FormatEx(s_temp,
                     sizeof(s_temp),
                     "%s_%d",
                     SQL_COLUMN_NAME_KEY,
                     i_currentColumn); 
            h_columnInfo.SetString(s_temp, s_columnName);

            FormatEx(s_temp,
                     sizeof(s_temp),
                     "%s_%d",
                     SQL_COLUMN_DATA_TYPE_KEY,
                     i_currentColumn);
            h_columnInfo.SetString(s_temp, s_dataType);
            h_tableColumnList.Push(h_columnInfo);
        }

        Internal_CreateSelectQueryForUnknownColumns(s_query, sizeof(s_query), h_tableColumnList);
        if (gB_logTransactions)
            QSR_SilentLog(MODULE_NAME,
                          "Select Query: %s",
                          s_query);

        gH_DBTransaction.AddQuery(s_query, h_tableColumnList);
    }

    Internal_SendDBTransaction(
        SQLTxn_OnTableFetchedForDump, 
        SQLTxn_OnFailedToFetchTableForDump,
        _,
        DBPrio_High);
}

void SQLTxn_FailedToFetchColumnInfo(Database db, any data, int numQueries, const char[] error, int failIndex, QSRDBTable[] queryData)
{
    QSR_ThrowError(
        MODULE_NAME,
        "COULD NOT FETCH COLUMN INFO FOR TABLES!\nERROR AT QUERY %d/%d!\nTable: %s\nERROR: %s\n",
        failIndex+1,
        numQueries,
        gS_tableNames[view_as<int>(queryData[failIndex])],
        error);
}

void SQLTxn_OnTableFetchedForDump(Database db, any data, int numQueries, DBResultSet[] results, ArrayList[] columnList)
{
    char s_tableName[64],
         s_columnName[64],
         s_dataType[64],
         s_temp[64],
         s_query[MAX_QUERY_LENGTH];
    QSRDBColDataType e_dataType;
    QSRDBTable e_currentTable;

    for (int i; i < numQueries; i++) {
        File h_sqlDumpFile = null;
        while (results[i].FetchRow()) {
            StringMap h_tempStringMap = columnList[i].Get(0);
            FormatEx(s_temp,
                    sizeof(s_temp),
                    "%s_%d",
                    SQL_TABLE_NAME_KEY,
                    i);
            h_tempStringMap.GetString(s_temp,
                                    s_tableName, 
                                    sizeof(s_tableName));
            h_tempStringMap.Close();
            e_currentTable = Internal_GetTableFromName(s_tableName);

            if (h_sqlDumpFile == null) {
                FormatEx(s_temp,
                        sizeof(s_temp),
                        "quasar_%s_dump.sql",
                        s_tableName);
                h_sqlDumpFile = OpenFile(s_temp, "w");
            }

            FormatEx(s_query,
                    sizeof(s_query),
                    "-- ?%d\nINSERT INTO `quasar`.`%s` (",
                    view_as<int>(e_currentTable),
                    s_tableName);
            
            StringMap h_columnValues = new StringMap();
            char s_columnKey[196];
            for (int j; j < columnList[i].Length; j++) {
                FormatEx(s_columnKey,
                        sizeof(s_columnKey),
                        "%s_column_%d",
                        s_tableName,
                        j);

                StringMap h_columnInfo = view_as<StringMap>(columnList[i].Get(j));
                FormatEx(s_temp,
                        sizeof(s_temp),
                        "%s_%d",
                        SQL_COLUMN_NAME_KEY,
                        i);
                h_columnInfo.GetString(s_temp, 
                                    s_columnName, 
                                    sizeof(s_columnName));

                FormatEx(s_query,
                        sizeof(s_query),
                        "%s`%s`",
                        s_query,
                        s_columnName);

                bool b_endOfList = (j == columnList[i].Length - 1);
                if (!b_endOfList)
                    FormatEx(s_query,
                            sizeof(s_query),
                            "%s, ",
                            s_query);
                else
                    FormatEx(s_query,
                            sizeof(s_query),
                            "%s) VALUES\n(",
                            s_query);

                FormatEx(s_temp,
                        sizeof(s_temp),
                        "%s_%d",
                        SQL_COLUMN_DATA_TYPE_KEY,
                        i);
                h_columnInfo.GetString(SQL_COLUMN_DATA_TYPE_KEY, s_dataType, sizeof(s_dataType));
                Internal_GetColumnDataType(s_dataType, e_dataType);

                switch(e_dataType) {
                    case DBColType_Bool: {
                        char s_value[16];
                        results[i].FetchString(j,
                                                s_value,
                                                sizeof(s_value));
                        if (!b_endOfList)
                            FormatEx(s_query,
                                 sizeof(s_query),
                                 "%s'%s', ",
                                 s_query,
                                 s_value);
                        else
                            FormatEx(s_query,
                                     sizeof(s_query),
                                     "%s'%s');",
                                     s_query,
                                     s_value);
                    }
                    case DBColType_Int: {
                        int i_value = results[i].FetchInt(j);
                        h_columnValues.SetValue(s_columnKey, i_value);

                        if (!b_endOfList)
                            FormatEx(s_query,
                                 sizeof(s_query),
                                 "%s%d, ",
                                 s_query,
                                 i_value);
                        else
                            FormatEx(s_query,
                                     sizeof(s_query),
                                     "%s%d);",
                                     s_query,
                                     i_value);
                    }
                    case DBColType_Float: {
                        float f_value = results[i].FetchFloat(j);
                        h_columnValues.SetValue(s_columnKey, f_value);

                        if (!b_endOfList)
                            FormatEx(s_query,
                                 sizeof(s_query),
                                 "%s%f, ",
                                 s_query,
                                 f_value);
                        else
                            FormatEx(s_query,
                                     sizeof(s_query),
                                     "%s%f)",
                                     s_query,
                                     f_value);
                    }
                    case DBColType_String: {
                        char s_value[256];
                        results[i].FetchString(j, s_value, sizeof(s_value));
                        h_columnValues.SetString(s_columnKey, s_value);

                        if (!b_endOfList)
                            FormatEx(s_query,
                                 sizeof(s_query),
                                 "%s'%s', ",
                                 s_query,
                                 s_value);
                        else
                            FormatEx(s_query,
                                     sizeof(s_query),
                                     "%s'%s'),\n",
                                     s_query,
                                     s_value);
                    }
                    default: {
                        QSR_ThrowError(
                            MODULE_NAME,
                            "UNKNOWN DATA TYPE ENCOUNTERED FOR COLUMN: `%s` IN TABLE `quasar`.`%s`",
                            s_columnName,
                            s_tableName);
                    }
                } // End of switch statement
            } // End of 2nd for loop (Parse all columns for current table)
            h_columnValues.Close();
        } // End of while loop (Parse each row for current table)

        s_query[sizeof(s_query)-2] = ';'; // Replace the last comma with a semicolon
                                          // to finish the statement.
        if (h_sqlDumpFile != null) {
            h_sqlDumpFile.WriteLine(s_query);
            h_sqlDumpFile.Close();
        }

        columnList[i].Close();
    } // End of 1st for loop (Parse all queries)

    // All tables have been dumped
    // we can now move on to dropping existing
    // tables so we can recreate them with the new schema
} // End of function

void SQLTxn_OnFailedToFetchTableForDump(Database db, any data, int numQueries, const char[] error, int failIndex, QSRDBTable[] queryData)
{
    QSR_ThrowError(
        MODULE_NAME,
        "COULD NOT FETCH TABLES TO SAVE DATA!\nERROR AT QUERY %d/%d!\nTable: %s\nERROR: %s\n",
        failIndex+1,
        numQueries,
        gS_tableNames[view_as<int>(queryData[failIndex])],
        error);
}

void SQLTxn_OnTablesErased(Database db, any data, int numQueries, DBResultSet[] results, QSRDBTable[] queryData)
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

void SQLTxn_OnTablesCreated(Database db, any data, int numQueries, Handle[] results, QSRDBTable[] queryData)
{
    gE_currentSetupStep++;

    char s_directory[256];
    BuildPath(
        Path_SM,
        s_directory,
        sizeof(s_directory),
        SQL_SETUP_DIR);
    Internal_Setup_DirectoryToTransaction(s_directory);

    if (gE_currentSetupStep >= DBStep_FillMainWithDefaults) {
        Internal_SendDBTransaction(
            SQLTxn_OnTablesFilled, 
            SQLTxn_SetupQueryFailed,
            _,
            DBPrio_High);
        return;
    }

    Internal_SendDBTransaction(
        SQLTxn_OnTablesCreated, 
        SQLTxn_SetupQueryFailed,
        _,
        DBPrio_High);
}

void SQLTxn_OnTablesFilled(Database db, any data, int numQueries, Handle[] results, QSRDBTable[] queryData)
{
    gE_currentSetupStep++;
    if (gE_currentSetupStep >= NUM_SETUP_STEPS) {
        char s_query[512];
        FormatEx(
            s_query,
            sizeof(s_query),
            "INSERT INTO `quasar`.`db_version` (`qdb_version`) \
             VALUES ('%s') \
             ON DUPLICATE KEY UPDATE `qdb_version` = '%s';",
             DATABASE_VERSION,
             DATABASE_VERSION);
        QSR_LogQuery(
            gH_db,
            s_query,
            SQLCB_TableQueryError,
            _,
            DBPrio_High);
        QSR_LogMessage(
            MODULE_NAME,
            "Database setup complete! Current version: %s",
            DATABASE_VERSION);
        return;
    }

    char s_directory[256];
    BuildPath(
        Path_SM,
        s_directory,
        sizeof(s_directory),
        SQL_SETUP_DIR);
    Internal_Setup_DirectoryToTransaction(s_directory);
    Internal_SendDBTransaction(
        SQLTxn_OnTablesFilled, 
        SQLTxn_SetupQueryFailed,
        _,
        DBPrio_High);
}

void SQLTxn_SetupQueryFailed(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    int i_tableNum;
    char s_failedQuery[3256];
    QSRDBTable e_tableNumber;
    
    // Extract the data from the pack
    DataPack h_failedQuery = view_as<DataPack>(queryData[failIndex]);
    h_failedQuery.Reset();
    h_failedQuery.ReadString(s_failedQuery, sizeof(s_failedQuery));
    e_tableNumber = view_as<QSRDBTable>(h_failedQuery.ReadCell());
    h_failedQuery.Close();

    // Change the enum to an int
    i_tableNum = view_as<int>(e_tableNumber);
    QSR_LogMessage(
        MODULE_NAME,
        "TRANSACTION FAILED!"
    );
    QSR_LogMessage(
        MODULE_NAME,
        "TABLE FAILED (%s)",
        gS_tableNames[i_tableNum]);
    QSR_LogMessage(
        MODULE_NAME,
        "ERROR AT QUERY %d/%d!\n%s\n",
        failIndex+1,
        numQueries,
        error);
    QSR_LogMessage(
        MODULE_NAME,
        "%s",
        s_failedQuery);
    QSR_LogMessage(MODULE_NAME,"END OF FAILED QUERY\n");
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