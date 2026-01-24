#include <sourcemod>
#include <sdktools>
#include <quasar/core>
#include <quasar/database>

#include <autoexecconfig>

// Core Variables
static Database gH_db = null;
bool     gB_late = false;

// Internal transaction for this plugin.
static Transaction gH_DBTransaction = null;

// Database
static char gS_subserver[64];
static char gS_dbProfile[64]; // The database profile name in databases.cfg
static bool gB_dbConnected = false; // Are we connected to the database yet?
static bool gB_logTransactions = false; // Do we log all queries in a transaction?
static char gS_dbVersion[24]; // The version number of our database.
static bool gB_isTableUpdated[view_as<int>(NUM_DBTABLES)] = {false, ...};
static QSRDBSetupStep gE_currentSetupStep = DBStep_WaitingForSetup;

static int  gI_maxTransactions;
static bool gB_allowNewTransactions;
static ArrayList gH_transactionArray = null; // Transaction array for external plugins

// Replace PLREPLACE with gS_subserver if you
// use these table names!!!!
static char gS_tableNames[NUM_DBTABLES][] = {
    "db_version",
    "tf_classes",
    "tf_items",
    "tf_attributes",
    "tf_qualities",
    "tf_particles",
    "tf_paint_kits",
    "tf_war_paints",
    "players",
    "rank_titles",
    "ignores",
    "groups",
    "sounds",
    "trails",
    "tags",
    "upgrades",
    "fun_stuff",
    "chat_colors",
    "color_packs",
    "PLREPLACE_stats",
    "PLREPLACE_maps",
    "PLREPLACE_vote_log",
    "PLREPLACE_chat_log",
    "tf_items_classes",
    "tf_items_attributes",
    "players_groups",
    "colors_in_packs",
    "players_items",
    "quasar_loadouts",
    "tf_loadouts",
    "taunt_loadouts",
    "PLREPLACE_maps_feedback",
    "PLREPLACE_maps_ratings",
    "inventories",
    "PLREPLACE_total_map_ratings",
    "PLREPLACE_map_categories",
    "PLREPLACE_maps_map_categories"
};

static char gS_stepNumbers[][] = {
    "00",
    "01", "02", "03", "04", "05", "06",
    "07", "08", "09", "10", "11", "12"
};

static char gS_setupStepNames[view_as<int>(NUM_SETUP_STEPS)+1][] = {
    "Setup Initialization",
    "Create Version Table",
    "Create Team Fortress Tables",
    "Create Main Tables",
    "Create Subserver Tables",
    "Create Junction Tables",
    "Create Team Fortress Loadout Tables",
    "Create Taunt Loadout Tables",
    "Create Database Views",
    "Fill Main Tables with Defaults",
    "Fill Junction Tables with Defaults",
    "Clean Up",
};

// ConVars
ConVar gH_CVR_subserver = null;
ConVar gH_CVR_dbConfig = null;
ConVar gH_CVR_dbLogTrans = null;
ConVar gH_CVR_maxTransactions = null;

// Forwards
GlobalForward gH_FWD_dbConnected = null; // Called when we've successfully connected to the database.
GlobalForward gH_FWD_dbVersionRetrieved = null;

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
    CreateNative("QSR_IsDatabaseConnected",         Native_QSRIsDatabaseConnected);
    CreateNative("QSR_RefreshDatabase",             Native_QSRRefreshDatabase);
    CreateNative("QSR_LogQuery",                    Native_QSRLogQuery);
    CreateNative("QSR_SilentLogQuery",              Native_QSRSilentLogQuery);
    CreateNative("QSR_AutoOpenTransaction",         Native_QSRAutoOpenTransaction);
    CreateNative("QSR_OpenTransaction",             Native_QSROpenTransaction);
    CreateNative("QSR_ForceCloseTransaction",       Native_QSRForceCloseTransaction);
    CreateNative("QSR_AreNewTransactionsAllowed",   Native_QSRAreNewTransactionsAllowed);
    CreateNative("QSR_IsTransactionArrayFull",      Native_QSRIsTransactionArrayFull);
    CreateNative("QSR_IsTransactionIdAvailable",    Native_QSRIsTransactionIdAvailable);
    CreateNative("QSR_AddQueryToTransaction",       Native_QSRAddQueryToTransaction);
    CreateNative("QSR_SendTransaction",             Native_QSRSendTransaction);
    CreateNative("QSR_GetTableFromName",            Native_QSRGetTableFromName);
    CreateNative("QSR_GetNameFromTable",            Native_QSRGetNameFromTable);
    CreateNative("QSR_ResetTransactionArray",       Native_QSRResetTransactionArray);
    CreateNative("QSR_ClearTransactionId",          Native_QSRClearTransactionId);
}

/*----------*\
|  FORWARDS  |
\*----------*/

public void OnPluginStart()
{
    AutoExecConfig_SetFile("plugins.quasar_database");

    gH_CVR_dbConfig             = AutoExecConfig_CreateConVar("sm_quasar_db_profile",           "quasar",           "The default database configuration to use for Quasar", FCVAR_PROTECTED);
    gH_CVR_subserver            = AutoExecConfig_CreateConVar("sm_quasar_subserver",            "srv0",             "Controls what server subserver the system is running on. [koth1].server.tf The boxed area is a subserver. Used to get and set player statistics across different servers.", FCVAR_NONE);
    gH_CVR_dbLogTrans           = AutoExecConfig_CreateConVar("sm_quasar_log_transactions",     "0",                "Controls whether we wi ll log all queries in a transaction.", FCVAR_NONE, true, 0.0, true, 1.0);
    gH_CVR_maxTransactions      = AutoExecConfig_CreateConVar("sm_quasar_max_transactions",     "16",               "The amount of database transactions allowed simultaneously. Transactions are collections of queries that get sent all at once. IF YOU CHANGE THIS MAKE SURE TO RUN `sm_qdb_refresh` AFTER CHECKING ALL TRANSACTIONS ARE DONE WITH `sm_qdb_open_transactions`!");

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    gH_FWD_dbConnected          = new GlobalForward("QSR_OnDatabaseConnected", ET_Ignore);
    gH_FWD_dbVersionRetrieved   = new GlobalForward("QSR_OnDBVersionRetrieved", ET_Ignore, Param_String);

    HookConVarChange(gH_CVR_dbLogTrans, OnConVarChanged);

    RegAdminCmd("sm_qdb_refresh", CMD_DB_Refresh, ADMFLAG_UNBAN, "Refresh the connection to the Quasar Database.");
    RegAdminCmd("sm_qdb_drop_tables", CMD_DB_DropAllTables, ADMFLAG_ROOT, "Drops all tables in the Quasar Database without saving data!");
    RegAdminCmd("sm_qdb_force_update", CMD_DB_ForceUpdate, ADMFLAG_ROOT, "Forces a database update to the latest version.");
    RegAdminCmd("sm_qdb_force_create", CMD_DB_ForceCreate, ADMFLAG_ROOT, "Forces the creation of all tables in the Quasar Database.");
}

public void OnPluginEnd()
{
    gH_CVR_dbConfig.Close();
    gH_CVR_subserver.Close();
    gH_CVR_dbLogTrans.Close();
    gH_CVR_maxTransactions.Close();
    gH_FWD_dbConnected.Close();
    gH_FWD_dbVersionRetrieved.Close();
    
    for (int i; i < gH_transactionArray.Length; i++) {
        Transaction h_temp = gH_transactionArray.Get(i);
        h_temp.Close();
    }

    gH_transactionArray.Close();
    gH_db.Close();
}

public void OnConfigsExecuted()
{
    gH_CVR_dbConfig.GetString(gS_dbProfile, sizeof(gS_dbProfile));
    gH_CVR_subserver.GetString(gS_subserver, sizeof(gS_subserver));
    gB_logTransactions = gH_CVR_dbLogTrans.BoolValue;
    gI_maxTransactions = gH_CVR_maxTransactions.IntValue;

    Database.Connect(SQLCB_OnConnect, gS_dbProfile);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == gH_CVR_dbConfig ||
        convar == gH_CVR_subserver)
        QSR_RefreshDatabase();

    if (convar == gH_CVR_dbLogTrans)
        gB_logTransactions = convar.BoolValue;
}

public void QSR_OnDBVersionRetrieved(const char[] dbVersion)
{
    if (gH_DBTransaction != null)
        gH_DBTransaction.Close();

    switch (Internal_IsDatabaseUpToDate()) {
        case DBVer_FirstTime:
            Internal_StartDBSetup();
        case DBVer_UpdateRequired: 
            Internal_StartDBUpdate();
        default:
            QSR_LogMessage(
                MODULE_NAME,
                "QUASAR DB UP TO DATE! CURRENT VERSION: %s",
                gS_dbVersion);
    }
}

/*---------*\
|  NATIVES  |
\*---------*/
any Native_QSRIsDatabaseConnected(Handle plugin, int numParams) {
    return gB_dbConnected;
}

void Native_QSRRefreshDatabase(Handle plugin, int numParams)
{
    RefreshDatabaseConnection();
}

void Native_QSRLogQuery(Handle plugin, int numParams)
{
    char s_queryFormatted[(MAX_QUERY_LENGTH * 2) + 1],
         s_moduleName[64];
    any data;
    DBPriority e_dbPrio;
    Function h_callback;

    GetNativeString(1, 
                    s_moduleName, 
                    sizeof(s_moduleName));

    int currentTime = GetTime();
    char s_time[64];
    FormatTime(s_time, sizeof(s_time), "%D %T", currentTime);

    h_callback = GetNativeFunction(2);
    data = GetNativeCell(3);
    e_dbPrio = GetNativeCell(4);
    SetGlobalTransTarget(SERVER);
    FormatNativeString(0,
                       5,
                       6,
                       sizeof(s_queryFormatted),
                       .out_string=s_queryFormatted);
    QSR_LogMessage(MODULE_NAME,
                   "QUERY:\n%s",
                   s_queryFormatted);

    PrivateForward h_sqlCallbackFwd = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell);
    h_sqlCallbackFwd.AddFunction(plugin, h_callback);

    DataPack h_queryData = new DataPack();
    h_queryData.WriteCell(data);
    h_queryData.WriteCell(h_sqlCallbackFwd);

    gH_db.Query(SQLCB_ExternalQueryReceived,
                s_queryFormatted,
                h_queryData,
                e_dbPrio);
}

void Native_QSRSilentLogQuery(Handle plugin, int numParams)
{
    char s_queryFormatted[(MAX_QUERY_LENGTH * 2) + 1],
         s_moduleName[64];
    any _data;
    DBPriority e_dbPrio;
    Function h_callback;

    GetNativeString(1, 
                    s_moduleName, 
                    sizeof(s_moduleName));

    int currentTime = GetTime();
    char s_time[64];
    FormatTime(s_time, sizeof(s_time), "%D %T", currentTime);

    h_callback = GetNativeFunction(2);
    _data = GetNativeCell(3);
    e_dbPrio = GetNativeCell(4);
    SetGlobalTransTarget(SERVER);
    FormatNativeString(0,
                       5,
                       6,
                       sizeof(s_queryFormatted),
                       .out_string=s_queryFormatted);

    QSR_SilentLogLarge(MODULE_NAME,
                   "QUERY:\n%s",
                   s_queryFormatted);

    PrivateForward h_sqlCallbackFwd = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell);
    h_sqlCallbackFwd.AddFunction(plugin, h_callback);

    DataPack h_queryData = new DataPack();
    h_queryData.WriteCell(_data);
    h_queryData.WriteCell(h_sqlCallbackFwd);

    gH_db.Query(SQLCB_ExternalQueryReceived, 
                s_queryFormatted, 
                h_queryData,
                e_dbPrio);
}

int Native_QSRAutoOpenTransaction(Handle plugin, int numParams)
{
    if (!gB_allowNewTransactions) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: NEW TRANSACTIONS NOT ALLOWED AT THIS TIME!");
        return -1;
    }

    int i_transactionId;
    for (i_transactionId = 0;
         i_transactionId < gI_maxTransactions; 
         i_transactionId++)
        if (QSR_IsTransactionIdAvailable(i_transactionId)) {
            gH_transactionArray.Set(i_transactionId, new Transaction());
            return i_transactionId;
        }

    QSR_LogMessage(MODULE_NAME,
                    "ERROR: TRANSACTION ARRAY FULL. UNABLE TO OPEN TRANSACTION!");
    return -1;
}

any Native_QSROpenTransaction(Handle plugin, int numParams)
{
    int i_transactionId = GetNativeCell(1);

    if (!gB_allowNewTransactions) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: NEW TRANSACTIONS NOT ALLOWED AT THIS TIME!");
        return false;
    }

    if (QSR_IsTransactionArrayFull()) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ARRAY FULL. UNABLE TO OPEN TRANSACTION %d!",
                       i_transactionId);
        return false;
    }

    if (i_transactionId < 0 ||
        i_transactionId >= gI_maxTransactions) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ID %d IS OUT OF RANGE!\nVALID IDs ARE 0 THROUGH %d INCLUSIVE!",
                       i_transactionId,
                       gI_maxTransactions-1);
        return false;
    }

    if (gH_transactionArray.Get(i_transactionId) != INVALID_TRANSACTION) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ID %d ALREADY EXISTS!\nMAKE SURE YOU CHECK IF THE TRANSACTION IS OPEN WITH QSR_IsTransactionIdAvailable(%d)",
                       i_transactionId,
                       i_transactionId);
        return false;
    }

    gH_transactionArray.Set(i_transactionId, new Transaction());
    return true;
}

any Native_QSRForceCloseTransaction(Handle plugin, int numParams)
{
    if (gH_transactionArray.Length == 0) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ARRAY EMPTY! UNABLE TO CLOSE TRANSACTION!");
        return false;
    }

    int i_transactionId = GetNativeCell(1);
    if (i_transactionId < 0 ||
        i_transactionId >= gI_maxTransactions) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ID %d IS OUT OF RANGE!\nVALID IDs ARE 0 THROUGH %d INCLUSIVE!",
                       i_transactionId,
                       gI_maxTransactions-1);
        return false;
    }

    if (gH_transactionArray.Get(i_transactionId) == INVALID_TRANSACTION) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ID %d DOESN'T EXIST!\nMAKE SURE YOU CHECK IF THE TRANSACTION IS OPEN WITH QSR_IsTransactionIdAvailable(%d)",
                       i_transactionId,
                       i_transactionId);
        return false;
    }

    Transaction h_temp = gH_transactionArray.Get(i_transactionId);
    h_temp.Close();
    gH_transactionArray.Set(i_transactionId, INVALID_TRANSACTION);
    return true;
}

any Native_QSRAreNewTransactionsAllowed(Handle plugin, int numParams)
{
    return gB_allowNewTransactions;
}

any Native_QSRIsTransactionArrayFull(Handle plugin, int numParams) {
    for (int i; i < gI_maxTransactions; i++)
        if (gH_transactionArray.Get(i) == INVALID_TRANSACTION)
            return false;

    return true;
}

any Native_QSRClearTransactionId(Handle plugin, int numParams) {
    int i_transactionId = GetNativeCell(1);
    if (i_transactionId < 0 ||
        i_transactionId >= gI_maxTransactions) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ID %d IS OUT OF RANGE!\nVALID IDs ARE 0 THROUGH %d INCLUSIVE!",
                       i_transactionId,
                       gI_maxTransactions-1);
        return false;
    }

    if (gH_transactionArray.Get(i_transactionId) == INVALID_TRANSACTION) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ID %d IS ALREADY CLEAR!",
                       i_transactionId);
        return false;
    }
    
    Transaction h_transaction = gH_transactionArray.Get(i_transactionId);
    if (h_transaction == null) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ID %d IS SOMEHOW NULL!",
                       i_transactionId);
        return false;
    }

    h_transaction.Close();
    gH_transactionArray.Set(i_transactionId, INVALID_HANDLE);
    return true;
}

void Native_QSRResetTransactionArray(Handle plugin, int numParams) {
    gB_allowNewTransactions = false;
    QSR_LogMessage(MODULE_NAME,
                    "RESETTING TRANSACTION ARRAY, TRANSACTIONS NOT ALLOWED!");

    if (gH_transactionArray == null) {
        gH_transactionArray = new ArrayList(.startsize=gI_maxTransactions);
        for (int i; i < gI_maxTransactions; i++)
            gH_transactionArray.Set(i, INVALID_TRANSACTION);
        
        // We should be good!
        gB_allowNewTransactions = true;
        QSR_LogMessage(MODULE_NAME,
                "TRANSACTIONS ALLOWED!");
        return;
    }

    for (int i; i < gH_transactionArray.Length; i++) {
        any h_temp = gH_transactionArray.Get(i);
        if (h_temp != INVALID_TRANSACTION)
            view_as<Transaction>(h_temp).Close();
    }

    // Resize to the new max transaction size
    gH_transactionArray.Resize(gI_maxTransactions);

    // Fill with defaults
    for (int i; i < gI_maxTransactions; i++)
        gH_transactionArray.Set(i, INVALID_TRANSACTION);

    // We should be good!
    gB_allowNewTransactions = true;
    QSR_LogMessage(MODULE_NAME,
            "TRANSACTIONS ALLOWED!");
}

any Native_QSRIsTransactionIdAvailable(Handle plugin, int numParams)
{
    return (gH_transactionArray.Get(GetNativeCell(1)) == INVALID_TRANSACTION);
}

any Native_QSRAddQueryToTransaction(Handle plugin, int numParams)
{
    static char s_formattedQuery[(MAX_QUERY_LENGTH*2)+1];
    char s_moduleName[64];
    GetNativeString(1, s_moduleName, sizeof(s_moduleName));
    int i_transactionId = GetNativeCell(2);
    any _queryData = GetNativeCell(3);


    if (i_transactionId < 0 ||
        i_transactionId >= gI_maxTransactions) {
        QSR_LogMessage(s_moduleName,
                       "ERROR: TRANSACTION ID %d IS OUT OF RANGE!\nVALID IDs ARE 0 THROUGH %d INCLUSIVE!",
                       i_transactionId,
                       gI_maxTransactions-1);
        return false;
    }

    if (gH_transactionArray.Get(i_transactionId) == INVALID_TRANSACTION) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: TRANSACTION ID %d DOESN'T EXIST!\nMAKE SURE YOU CHECK IF THE TRANSACTION IS OPEN WITH QSR_IsTransactionIdAvailable(%d) IF YOU HAVEN'T OPENED IT YOURSELF!",
                       i_transactionId,
                       i_transactionId);
        return false;
    }

    FormatNativeString(0,
                       4,
                       5,
                       sizeof(s_formattedQuery),
                       .out_string = s_formattedQuery);

    if (gB_logTransactions)
        QSR_SilentLogLarge(MODULE_NAME,
                      "QUERY ADDED TO TRANSACTION %d:\n%s",
                      i_transactionId,
                      s_formattedQuery);

    Transaction h_temp = gH_transactionArray.Get(i_transactionId);
    h_temp.AddQuery(s_formattedQuery, _queryData);
    return true;
}

any Native_QSRSendTransaction(Handle plugin, int numParams)
{
    char s_moduleName[64];
    GetNativeString(1, s_moduleName, sizeof(s_moduleName));
    int i_transactionId = GetNativeCell(2);
    Function h_transactionSuccess = GetNativeFunction(3);
    Function h_transactionFailure = GetNativeFunction(4);
    any _transactionData = GetNativeCell(5);
    DBPriority e_dbPriority = GetNativeCell(6);

    if (h_transactionSuccess == INVALID_FUNCTION ||
        h_transactionFailure == INVALID_FUNCTION) {
            ThrowNativeError(-1, "ERROR! EITHER YOUR SQLTxnSuccess or SQLTxnFailure function is invalid!");
            return false;
    }

    if (i_transactionId < 0 ||
        i_transactionId >= gI_maxTransactions) {
        QSR_LogMessage(s_moduleName,
                       "ERROR: TRANSACTION ID %d IS OUT OF RANGE!\nVALID IDs ARE 0 THROUGH %d INCLUSIVE!",
                       i_transactionId,
                       gI_maxTransactions-1);
        return false;
    }

    if (gH_transactionArray.Get(i_transactionId) == INVALID_TRANSACTION) {
        QSR_LogMessage(s_moduleName,
                       "ERROR: TRANSACTION ID %d DOESN'T EXIST!\nMAKE SURE YOU CHECK IF THE TRANSACTION IS OPEN WITH QSR_IsTransactionIdAvailable(%d) IF YOU HAVEN'T OPENED IT YOURSELF!",
                       i_transactionId,
                       i_transactionId);
        return false;
    }

    PrivateForward h_successCB = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array);
    PrivateForward h_failureCB = new PrivateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_Array);
    h_successCB.AddFunction(plugin, h_transactionSuccess);
    h_failureCB.AddFunction(plugin, h_transactionFailure);

    DataPack h_transactionInfo = new DataPack();
    h_transactionInfo.WriteCell(_transactionData);
    h_transactionInfo.WriteCell(h_successCB);
    h_transactionInfo.WriteCell(h_failureCB);

    Transaction h_temp = gH_transactionArray.Get(i_transactionId);
    gH_transactionArray.Set(i_transactionId, INVALID_TRANSACTION);
    gH_db.Execute(h_temp,
                  SQLTxn_ExternalTransactionSuccess,
                  SQLTxn_ExternalTransactionFailure,
                  h_transactionInfo,
                  e_dbPriority);
    return true;
}

any Native_QSRGetTableFromName(Handle plugin, int numParams)
{
    char s_requestedTable[64];
    GetNativeString(1, s_requestedTable, sizeof(s_requestedTable));
    return Internal_GetTableFromName(s_requestedTable);
}

void Native_QSRGetNameFromTable(Handle plugin, int numParams)
{
    QSRDBTable e_table = GetNativeCell(1);
    if (e_table < DBTable_Version ||
        e_table >= NUM_DBTABLES) {
        
        SetNativeString(2,
                        "NULL_TABLE",
                        GetNativeCell(3));
        return;
    }

    SetNativeString(2,
                    gS_tableNames[view_as<int>(e_table)], 
                    GetNativeCell(3));
}

/*---------------------*\
|  INTERNAL FUNCTIONS  |
\*---------------------*/
void Internal_StartDBSetup() {
    QSR_LogMessage(MODULE_NAME,
                   "DATABASE NOT DETECTED. BUILDING DATABASE");
    
    gE_currentSetupStep = DBStep_SetupInit;
    Internal_DropAllTables(SQLTxn_Setup_OnTablesErased);
}

void Internal_StartDBUpdate() {
    QSR_LogMessage(MODULE_NAME,
                    "DATABASE UPDATE REQUIRED! CURRENT VERSION: `%s` NEW VERSION: `%s`",
                    gS_dbVersion,
                    DATABASE_VERSION);
    if (gH_DBTransaction != null)
        gH_DBTransaction.Close();

    // Before we can dump the tables to preserve data,
    // we have to get the column information for each table
    // because columns are not stored in any particular order.
    gH_DBTransaction = new Transaction();
    QSR_LogMessage(MODULE_NAME,
                    "PREPARING TO DUMP TABLES FOR DATABASE UPDATE");
    for (QSRDBTable i = DBTable_TFClasses;
            i < NUM_DBTABLES;
            i++)
        Internal_AddTableToInfoTransaction(i);

    gH_db.Execute(gH_DBTransaction,
                    SQLTxn_OnColumnInfoFetched,
                    SQLTxn_FailedToFetchColumnInfo,
                    .priority=DBPrio_High);
    gH_DBTransaction = null;
}

void Internal_DeleteAllRows() {
    gH_DBTransaction = new Transaction();
    char s_query[512];
    for (int i = view_as<int>(NUM_DBTABLES)-1; 
         i >= view_as<int>(DBTable_Version);
         i--) {

        if (i == view_as<int>(DBTable_InventoryView) ||
            i == view_as<int>(DBTable_MapRatingView))
            continue;

        FormatEx(
            s_query,
            sizeof(s_query),
            "DELETE FROM `quasar`.`%s`",
            gS_tableNames[i]);

        if (StrContains(s_query, "PLREPLACE") != -1) {
            ReplaceString(
                s_query,
                sizeof(s_query),
                "PLREPLACE",
                gS_subserver,
                false);
        }

        QSR_LogMessage(
            MODULE_NAME,
            "%s",
            s_query);
        DataPack h_dataPack = new DataPack();
        h_dataPack.WriteString(s_query);
        h_dataPack.WriteCell(i);
        gH_DBTransaction.AddQuery(s_query, h_dataPack);
    }

    Internal_SendDBTransaction(
        SQLTxn_OnTablesCleared,
        SQLTxn_SetupQueryFailed,
        _, 
        DBPrio_High);
}

void Internal_DropAllTables(SQLTxnSuccess success) {
    gH_DBTransaction = new Transaction();
    char s_query[512];
    for (int i = view_as<int>(NUM_DBTABLES)-1; 
         i >= view_as<int>(DBTable_Version);
         i--) {

        if (i == view_as<int>(DBTable_InventoryView) ||
            i == view_as<int>(DBTable_MapRatingView))
            FormatEx(
                s_query,
                sizeof(s_query),
                "DROP VIEW IF EXISTS `quasar`.`%s`",
                gS_tableNames[i]);
        else
            FormatEx(
                s_query,
                sizeof(s_query),
                "DROP TABLE IF EXISTS `quasar`.`%s`",
                gS_tableNames[i]);

        if (StrContains(s_query, "PLREPLACE") != -1) {
            ReplaceString(
                s_query,
                sizeof(s_query),
                "PLREPLACE",
                gS_subserver,
                false);
        }
        
        QSR_LogMessage(
            MODULE_NAME,
            "%s",
            s_query);
        DataPack h_dataPack = new DataPack();
        h_dataPack.WriteString(s_query);
        h_dataPack.WriteCell(i);
        gH_DBTransaction.AddQuery(s_query, h_dataPack);
    }

    
    Internal_SendDBTransaction(
        success,
        SQLTxn_SetupQueryFailed,
        _, 
        DBPrio_High);
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
                  "PLREPLACE", 
                  gS_subserver, 
                  false);
    strcopy(
        s_tableName, 
        maxlength, 
        s_temp);
    return true;
}

QSRDBTable Internal_GetTableFromName(const char[] s_tableName) {
    for (int i = 0; i < view_as<int>(NUM_DBTABLES); i++) {
        if (StrEqual(gS_tableNames[i], s_tableName, false)) {
            return view_as<QSRDBTable>(i);
        }
    }

    return view_as<QSRDBTable>(-1);
}


// Refreshes the connection to the database.
void RefreshDatabaseConnection()
{
    if (gH_db != null)
    {
        gB_dbConnected = false;
        gH_db.Close();
        gH_db = null;
    }

    gH_CVR_dbConfig.GetString(gS_dbProfile, sizeof(gS_dbProfile));

    Database.Connect(SQLCB_OnConnect, gS_dbProfile);
}

/*-----------------*\
|  SETUP FUNCTIONS  |
\*-----------------*/

// Here we create the query to check the DB version
void Internal_SendVersionQuery() {
    QSR_LogQuery(MODULE_NAME,
                 SQLCB_DatabaseVersionCB,
                 _,
                 DBPrio_High,
                 "SELECT `qdb_version`\nFROM `quasar`.`db_version`;");
}

QSRDBVersionStatus Internal_IsDatabaseUpToDate() {
    if (StrEqual(gS_dbVersion, "NULL VERSION") || StrEqual(gS_dbVersion, ""))
        return DBVer_FirstTime;

    if (!StrEqual(gS_dbVersion, DATABASE_VERSION))
        return DBVer_UpdateRequired;

    return DBVer_Equal;
}

void Internal_Setup_DirectoryToTransaction(const char[] directory, int transactionId) {
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

    if (transactionId == -1)
        return;

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
                QSR_SilentLog(MODULE_NAME, "Step %d: Checking directory: %s (looking for '%s')", 
                              gE_currentSetupStep, s_tempPath, gS_stepNumbers[view_as<int>(gE_currentSetupStep)]);
                if (StrContains(s_tempPath, 
                                gS_stepNumbers[view_as<int>(gE_currentSetupStep)]) == -1)
                    continue;

                QSR_SilentLog(MODULE_NAME, "Step %d: Recursing into directory: %s", gE_currentSetupStep, s_finalPath);
                Internal_Setup_DirectoryToTransaction(s_finalPath, transactionId);
            }
            case FileType_File: {
                // Skip files if directory doesn't match current step AND we're not in the main setup directory
                if (StrContains(directory, gS_stepNumbers[view_as<int>(gE_currentSetupStep)]) == -1 &&
                    StrContains(directory, SQL_SETUP_DIR) == -1) {
                    QSR_SilentLog(MODULE_NAME, "Step %d: Skipping file %s (dir: %s)", gE_currentSetupStep, s_tempPath, directory);
                    continue;
                }
                
                // each sql file is its own step.
                if (StrEqual(s_tempPath, "01_version_table.sql", false) && 
                    gE_currentSetupStep != DBStep_CreateVersionTable) {
                    continue;
                }
                else if (StrEqual(s_tempPath, "06_tf_loadouts.sql", false) && 
                    gE_currentSetupStep != DBStep_CreateTFLoadoutTable) {
                    continue;
                }
                else if (StrEqual(s_tempPath, "07_taunt_loadouts.sql", false) && 
                    gE_currentSetupStep != DBStep_CreateTauntLoadoutTable) {
                    continue;
                }
                QSR_SilentLog(MODULE_NAME, "Step %d: Adding SQL file: %s", gE_currentSetupStep, s_finalPath);
                Internal_AddSQLFileToTrans(s_finalPath, transactionId);
            }
            default:
                continue;
        }
    } // End of while loop 2
    h_dir.Close();
}

void Internal_Update_DirectoryToTransaction(const char[] directory, int transactionId) {
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

    if (transactionId == -1)
        return;

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
            case FileType_Directory:
                Internal_Update_DirectoryToTransaction(s_finalPath, transactionId);
            case FileType_File:
                Internal_AddInsertSQLToTrans(s_finalPath, transactionId);
            default:
                continue;
        }
    } // End of while loop 2
    h_dir.Close();
}

void Internal_DirectoryToTransaction(const char[] directory, int transactionId) {
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

    if (transactionId == -1)
        return;

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
            case FileType_Directory:
                Internal_DirectoryToTransaction(s_finalPath, transactionId);
            case FileType_File:
                Internal_AddSQLFileToTrans(s_finalPath, transactionId);
            default:
                continue;
        }
    } // End of while loop 2
    h_dir.Close();
}

// Has special checks for setup setps
void Internal_Setup_SendDBTransaction(SQLTxnSuccess success, 
                                      SQLTxnFailure fail,
                                      int transactionId) {

    if (gE_currentSetupStep == DBStep_SetupInit) {
        char s_directory[256];
        BuildPath(
            Path_SM,
            s_directory,
            sizeof(s_directory),
            SQL_SETUP_DIR);
        
        gE_currentSetupStep++;
        Internal_Setup_DirectoryToTransaction(s_directory, transactionId);
    }

    QSR_SendTransaction(MODULE_NAME,
                             transactionId,
                             success,
                             fail,
                             transactionId,
                             DBPrio_High);
}

void Internal_SendDBTransaction(SQLTxnSuccess success,
                                SQLTxnFailure fail,
                                any data=0,
                                DBPriority dbPriority=DBPrio_Normal){
    gH_db.Execute(
        gH_DBTransaction,
        success,
        fail,
        data,
        dbPriority);
    gH_DBTransaction = null;
}

void Internal_AddSQLFileToTrans(const char[] sqlFile, int transactionId) {
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

    char s_totalQuery[MAX_QUERY_LENGTH];
    char s_currentLine[MAX_LINE_SIZE];
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
            static char s_insertLine[MAX_LINE_SIZE];

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

            // Make sure we replace PLREPLACE with the actual
            // subserver name if needed.
            if (StrContains(s_tableName, "PLREPLACE") != -1) {
                ReplaceString(
                    s_tableName,
                    sizeof(s_tableName),
                    "PLREPLACE",
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

            QSR_AddQueryToTransaction(MODULE_NAME,
                                      transactionId,
                                      h_queryInfo,
                                      s_totalQuery);
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

    DataPack h_queryInfo = new DataPack();
    h_queryInfo.WriteString(s_totalQuery);
    h_queryInfo.WriteCell(e_currentTable);

    QSR_AddQueryToTransaction(MODULE_NAME,
                              transactionId,
                              h_queryInfo,
                              s_totalQuery);
    h_sqlFile.Close();
}

void Internal_AddInsertSQLToTrans(const char[] sqlFile, int transactionId) {
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

    char s_totalQuery[MAX_QUERY_LENGTH],
         s_currentLine[MAX_LINE_SIZE],
         s_escapedLine[(MAX_LINE_SIZE*2)+1],
         s_insertLine[MAX_LINE_SIZE],
         s_tableName[64];
    QSRDBTable e_currentTable;
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
        if ((StrContains(s_currentLine, "INSERT INTO", false) == -1 ||
             StrContains(s_currentLine, "REPLACE INTO", false) == -1) &&
            StrContains(s_currentLine, "CREATE", false) != -1) {
            QSR_LogMessage(MODULE_NAME,
                           "FILE %s IS NOT AN INSERT QUERY!",
                            sqlFile);
            continue;
        }


        
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

        // Make sure we replace PLREPLACE with the actual
        // subserver name if needed.
        if (StrContains(s_tableName, "PLREPLACE") != -1) {
            ReplaceString(
                s_tableName,
                sizeof(s_tableName),
                "PLREPLACE",
                gS_subserver,
                false);
        }

        TrimString(s_currentLine);
        // Remove any semicolons at the end of the line
        if (StrContains(s_currentLine, ";", false) != -1) {
            ReplaceString(
                s_currentLine,
                sizeof(s_currentLine),
                ";\n",
                "",
                false);
        }

        if (StrContains(s_currentLine, "),\n", false) != -1)
            ReplaceString(
                s_currentLine,
                sizeof(s_currentLine),
                "),\n",
                ")",
                false);
        else if (StrContains(s_currentLine, "),", false) != -1)
            ReplaceString(
                s_currentLine,
                sizeof(s_currentLine),
                "),",
                ")",
                false);
        /*
        // Now we have to escape single quotes.
        // SQL_EscapeString ends up escaping single quotes that
        // start a value, not just the single quotes within the value itself.
        bool b_inValue = false;
        int  i_writeCursor = 0;
        for (int i; i < strlen(s_currentLine); i++) {
            // 39 is ascii for a single quote
            if (s_currentLine[i] == 39 &&
                !b_inValue) {
                b_inValue = true;
                s_escapedLine[i_writeCursor++] = s_currentLine[i];
                continue;
            }

            else if (s_currentLine[i] == 39 &&
                     b_inValue) {
                if (s_currentLine[i+1] == ')' ||
                   (s_currentLine[i+1] == ',')) {
                    s_escapedLine[i_writeCursor++] = s_currentLine[i];
                    b_inValue = false;
                    continue;
                }

                s_escapedLine[i_writeCursor++] = 39;
                s_escapedLine[i_writeCursor++] = 39;
                continue;
            }

            s_escapedLine[i_writeCursor++] = s_currentLine[i];
        }
        s_escapedLine[i_writeCursor] = '\0';
        */
        FormatEx(
            s_totalQuery,
            sizeof(s_totalQuery),
            "%s%s;\n",
            s_insertLine,
            s_currentLine);

        DataPack h_queryInfo = new DataPack();
        h_queryInfo.WriteString(s_totalQuery);
        h_queryInfo.WriteCell(e_currentTable);

        QSR_AddQueryToTransaction(MODULE_NAME,
                                    transactionId,
                                    h_queryInfo,
                                    s_totalQuery);
        continue;
    }

    DataPack h_queryInfo = new DataPack();
    h_queryInfo.WriteString(s_totalQuery);
    h_queryInfo.WriteCell(e_currentTable);

    QSR_AddQueryToTransaction(MODULE_NAME,
                              transactionId,
                              h_queryInfo,
                              s_totalQuery);
    h_sqlFile.Close();
}

/*------------------*\
|  UPDATE FUNCTIONS  |
\*------------------*/

void Internal_AddTableToInfoTransaction(QSRDBTable e_table)
{
    char s_query[512],
         s_tableName[64];

    Internal_GetTableName(e_table,
                          s_tableName,
                          sizeof(s_tableName));

    ReplaceString(s_tableName,
                  sizeof(s_tableName),
                  "PLREPLACE",
                  gS_subserver,
                  false);

    FormatEx(s_query,
             sizeof(s_query),
             "SELECT `column_name`, `data_type` \n"...
             "FROM INFORMATION_SCHEMA.COLUMNS \n"...
             "WHERE `table_schema` = 'quasar' AND `table_name` = '%s';",
             s_tableName);

    if (gB_logTransactions)
        QSR_SilentLogLarge(
            MODULE_NAME,
            "Table %d (%s):\n%s",
            view_as<int>(e_table),
            gS_tableNames[view_as<int>(e_table)],
            s_query);

    gH_DBTransaction.AddQuery(s_query, e_table);
}

bool Internal_CreateSelectQueryForUnknownColumns(char[] query, int maxlength, ArrayList columnList) {
    char s_tableName[64],
         s_columnName[64],
         s_columnList[1024];

    if (columnList.Length == 0)
        return false;

    s_columnList[0] = '\0'; // Initialize to empty string

    StringMap h_columnInfo;
    char s_tempColumn[64];
    for (int i; i < columnList.Length; i++) {
        
        h_columnInfo = columnList.Get(i);
        if (h_columnInfo == null)
            return false;

        // Do this once.
        if (!s_tableName[0])
            h_columnInfo.GetString(SQL_TABLE_NAME_KEY, s_tableName, sizeof(s_tableName));
        h_columnInfo.GetString(SQL_COLUMN_NAME_KEY, s_columnName, sizeof(s_columnName));

        // Put backticks around column name
        FormatEx(s_tempColumn,
                 sizeof(s_tempColumn),
                 "`%s`",
                 s_columnName);

        // Append the column name to the column list
        StrCat(s_columnList,
               sizeof(s_columnList),
               s_tempColumn);

        // Add comma if we haven't hit the last column
        // otherwise add a spacer
        if (i < columnList.Length - 1)
            StrCat(s_columnList,  
                   sizeof(s_columnList),
                   ", ");
        else
            StrCat(s_columnList,
                   sizeof(s_columnList),
                   " ");
    } // End of column loop

    FormatEx(query,
             maxlength,
             "SELECT %s\nFROM `quasar`.`%s`;",
             s_columnList,
             s_tableName);
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

/*---------------*\
|  SQL CALLBACKS  |
\*---------------*/

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
    Call_Finish();

    QSR_ResetTransactionArray();
    Internal_SendVersionQuery();
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

void SQLCB_ExternalQueryReceived(Database db, DBResultSet results, const char[] error, DataPack data) {
    any _queryData;
    PrivateForward h_callback;

    data.Reset();
    _queryData = data.ReadCell();
    h_callback = data.ReadCell();
    data.Close();

    if (h_callback == INVALID_HANDLE) {
        QSR_ThrowError(MODULE_NAME,
                       "ERROR:\nINVALID SQLQueryCallback FUNCTION! CANNOT PROCESS QUERY!");
        return;
    }

    Call_StartForward(h_callback);
    Call_PushCell(db);
    Call_PushCell(results);
    Call_PushString(error);
    Call_PushCell(_queryData);
    Call_Finish();
}

void SQLTxn_ExternalTransactionSuccess(Database db, DataPack data, int numQueries, DBResultSet[] results, any[] queryData)
{
    // Handle datapack information first.
    data.Reset();
    any _transactionData = data.ReadCell();
    PrivateForward h_successCB = data.ReadCell();
    PrivateForward h_failureCB = data.ReadCell();
    h_failureCB.Close();
    data.Close();

    // Pass info along to the external forward
    Call_StartForward(h_successCB);
    Call_PushCell(db);
    Call_PushCell(_transactionData);
    Call_PushCell(numQueries);
    Call_PushArray(results, numQueries);
    Call_PushArray(queryData, numQueries);
    Call_Finish();
}

void SQLTxn_ExternalTransactionFailure(Database db, DataPack data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    QSR_LogMessage(
        MODULE_NAME,
        "TRANSACTION FAILED!\nERROR AT QUERY %d/%d!\nERROR: %s\n",
        failIndex+1,
        numQueries,
        error);

    // Handle datapack information first.
    data.Reset();
    any _transactionData = data.ReadCell();
    PrivateForward h_successCB = data.ReadCell();
    PrivateForward h_failureCB = data.ReadCell();
    h_successCB.Close();
    data.Close();

    // Pass info along to the user's forward
    Call_StartForward(h_failureCB);
    Call_PushCell(db);
    Call_PushCell(_transactionData);
    Call_PushCell(numQueries);
    Call_PushString(error);
    Call_PushCell(failIndex);
    Call_PushArray(queryData, numQueries);
}

void SQLTxn_OnColumnInfoFetched(Database db, any data, int numQueries, DBResultSet[] results, QSRDBTable[] queryData)
{
    char s_tableName[64],
         s_columnName[64],
         s_dataType[64],
         s_query[MAX_QUERY_LENGTH];

    gH_DBTransaction = new Transaction();
    for (int i; i < numQueries; i++) {

        Internal_GetTableName(queryData[i],
                              s_tableName,
                              sizeof(s_tableName));

        ArrayList h_tableColumnList = new ArrayList();
        while (results[i].FetchRow()) {
            results[i].FetchString(0,
                    s_columnName,
                    sizeof(s_columnName));
            results[i].FetchString(1,
                    s_dataType,
                    sizeof(s_dataType));

            // Keep all column names lowercase
            for (int letter; letter < sizeof(s_columnName); letter++)
                s_columnName[letter] = CharToLower(s_columnName[letter]);

            StringMap h_columnInfo = new StringMap();
            h_columnInfo.SetString(SQL_COLUMN_NAME_KEY, s_columnName);
            h_columnInfo.SetString(SQL_COLUMN_DATA_TYPE_KEY, s_dataType);
            h_columnInfo.SetString(SQL_TABLE_NAME_KEY, s_tableName);

            h_tableColumnList.Push(h_columnInfo);
        } // End of while loop

        if (!Internal_CreateSelectQueryForUnknownColumns(s_query, sizeof(s_query), h_tableColumnList)) {
            QSR_LogMessage(MODULE_NAME,
                          "WARNING: Could not create SELECT query for table %s (possibly empty or no columns found)",
                          s_tableName);
            continue;
        }

        if (gB_logTransactions)
            QSR_SilentLogLarge(MODULE_NAME,
                          "QUERY:\n%s",
                           s_query);

        DataPack h_tableInfo = new DataPack();
        h_tableInfo.WriteCell(QSR_GetTableFromName(s_tableName));
        ReplaceString(s_tableName,
                      sizeof(s_tableName),
                      "PLREPLACE",
                      gS_subserver,
                      false);
        h_tableInfo.WriteString(s_tableName);
        h_tableInfo.WriteCell(h_tableColumnList);
        gH_DBTransaction.AddQuery(s_query, h_tableInfo);
    } // end of loop to parse all queries

    QSR_LogMessage(MODULE_NAME,
                   "SUCCESSFULLY CREATED COLUMN LISTS. MOVING TO CREATE TABLE DUMPS");
    Internal_SendDBTransaction(
        SQLTxn_OnTableFetchedForDump, 
        SQLTxn_OnFailedToFetchTableForDump,
        _,
        DBPrio_High);
    gH_DBTransaction = null;
}

void SQLTxn_FailedToFetchColumnInfo(Database db, any data, int numQueries, const char[] error, int failIndex, QSRDBTable[] queryData)
{
    QSR_LogMessage(
        MODULE_NAME,
        "COULD NOT FETCH COLUMN INFO FOR TABLES!\nERROR AT QUERY %d/%d!\nTABLE: %s\nERROR: %s\n",
        failIndex+1,
        numQueries,
        gS_tableNames[view_as<int>(queryData[failIndex])],
        error);
}

void SQLTxn_OnTableFetchedForDump(Database db, any data, int numQueries, DBResultSet[] results, DataPack[] tableInfo)
{
    bool b_endOfList;
    char s_tableName[64],
        s_columnName[64],
        s_dataType[64],
        s_columnKey[64],
        s_filePath[256],
        s_line[MAX_LINE_SIZE];
    ArrayList h_columnList = new ArrayList();
    QSRDBColDataType e_dataType;
    QSRDBTable e_currentTable;
    QSR_LogMessage(MODULE_NAME,
                   "STARTING TABLE DUMP PROCESS");
    for (int i; i < numQueries; i++) {
        File h_sqlDumpFile = null;
        tableInfo[i].Reset();
        e_currentTable = view_as<QSRDBTable>(tableInfo[i].ReadCell());
        tableInfo[i].ReadString(s_tableName, sizeof(s_tableName));
        h_columnList = view_as<ArrayList>(tableInfo[i].ReadCell());
        tableInfo[i].Close();

        if (results[i].RowCount == 0) {
            h_columnList.Close();
            continue;
        }

        QSR_LogMessage(MODULE_NAME,
                       "DUMPING TABLE: %s",
                       s_tableName);
        if (e_currentTable < DBTable_TFItemsClasses)
            FormatEx(s_filePath,
                    sizeof(s_filePath),
                    "%s/main_tables/%s_dump.sql",
                    SQL_DUMP_DIR,
                    s_tableName);
        else
            FormatEx(s_filePath,
                    sizeof(s_filePath),
                    "%s/junc_tables/%s_dump.sql",
                    SQL_DUMP_DIR,
                    s_tableName);

        BuildPath(Path_SM,
                    s_filePath,
                    sizeof(s_filePath),
                    s_filePath);

        if (FileExists(s_filePath))
            DeleteFile(s_filePath);
        
        h_sqlDumpFile = OpenFile(s_filePath, "w+");
        FormatEx(s_line,
                 sizeof(s_line),
                 "-- ?%d\nINSERT INTO `quasar`.`%s` (",
                 view_as<int>(e_currentTable),
                 s_tableName);

        h_sqlDumpFile.WriteString(s_line, false);

        // Add column names to the INSERT statement (only once, before processing rows)
        for (int j; j < h_columnList.Length; j++) {
            b_endOfList = (j == h_columnList.Length - 1);
            StringMap h_columnInfo = view_as<StringMap>(h_columnList.Get(j));
            if (h_columnInfo == null) {
                QSR_LogMessage(MODULE_NAME, "COLUMN INFO NULL FOR TABLE %s COLUMN INDEX %d", s_tableName, j);
                continue;
            }

            h_columnInfo.GetString(SQL_COLUMN_NAME_KEY, 
                                   s_columnName, 
                                   sizeof(s_columnName));

            if (!b_endOfList) { 
                FormatEx(s_line,
                         sizeof(s_line),
                         "`%s`, ",
                         s_columnName);
                h_sqlDumpFile.WriteString(s_line, false);
            } else {
                FormatEx(s_line,
                         sizeof(s_line),
                         "`%s`) VALUES\n",
                         s_columnName);
                h_sqlDumpFile.WriteString(s_line, false);
            }
        } // End of adding columns to query

        bool b_firstRow = true;
        while (results[i].FetchRow()) {
            StringMap h_columnValues = new StringMap();
            
            // Add row separator (comma + newline) for all rows except the first
            if (!b_firstRow)
                h_sqlDumpFile.WriteLine(",");

            b_firstRow = false;

            h_sqlDumpFile.WriteString("(", false);
            for (int j;  j < h_columnList.Length; j++) {
                b_endOfList = (j == h_columnList.Length - 1);
                StringMap h_columnInfo = view_as<StringMap>(h_columnList.Get(j));
                if (h_columnInfo == null) {
                    QSR_LogMessage(MODULE_NAME, "COLUMN INFO NULL FOR TABLE %s COLUMN INDEX %d", s_tableName, j);
                    continue;
                }

                h_columnInfo.GetString(SQL_COLUMN_DATA_TYPE_KEY, s_dataType, sizeof(s_dataType));
                Internal_GetColumnDataType(s_dataType, e_dataType);

                switch(e_dataType) {
                    case DBColType_Bool,
                        DBColType_String: {
                        char s_value[256];
                        results[i].FetchString(j,
                                                s_value,
                                                sizeof(s_value));
                        h_columnValues.SetString(s_columnKey, s_value);

                        if (StrContains(s_value, "'") != -1)
                            ReplaceString(s_value,
                                          sizeof(s_value),
                                          "'",
                                          "\\'");

                        if (!b_endOfList)
                            FormatEx(s_line,
                                sizeof(s_line),
                                "'%s', ",
                                s_value);
                        else
                            FormatEx(s_line,
                                    sizeof(s_line),
                                    "'%s')",
                                    s_value);
                        h_sqlDumpFile.WriteString(s_line, false);
                    }
                    case DBColType_Int: {
                        int i_value = results[i].FetchInt(j);
                        h_columnValues.SetValue(s_columnKey, i_value);

                        if (!b_endOfList)
                            FormatEx(s_line,
                                sizeof(s_line),
                                "%d, ",
                                i_value);
                        else
                            FormatEx(s_line,
                                    sizeof(s_line),
                                    "%d)",
                                    i_value);
                        h_sqlDumpFile.WriteString(s_line, false);
                    }
                    case DBColType_Float: {
                        float f_value = results[i].FetchFloat(j);
                        h_columnValues.SetValue(s_columnKey, f_value);

                        if (!b_endOfList)
                            FormatEx(s_line,
                                sizeof(s_line),
                                "%f, ",
                                f_value);
                        else
                            FormatEx(s_line,
                                    sizeof(s_line),
                                    "%f)",
                                    f_value);
                        h_sqlDumpFile.WriteString(s_line, false);
                    }
                    default: {
                        QSR_LogMessage(
                            MODULE_NAME,
                            "UNKNOWN DATA TYPE ENCOUNTERED FOR COLUMN: `%s` IN TABLE `quasar`.`%s`",
                            s_columnName,
                            s_tableName);
                    }
                } // End of switch statement
            } // End of 2nd for loop (Parsed all columns for current row)

            // Set up statement to handle duplicates upon insert
            FormatEx(s_line,
                     sizeof(s_line),
                     "\nON DUPLICATE KEY UPDATE\n");
            h_sqlDumpFile.WriteLine(s_line);

            for (int j; j < h_columnList.Length; j++) {
                FormatEx(s_columnKey,
                         sizeof(s_columnKey),
                         "%s_%d",
                         SQL_COLUMN_NAME_KEY,
                         j);
                StringMap h_columnInfo = view_as<StringMap>(h_columnList.Get(j));
                h_columnInfo.GetString(s_columnKey, s_columnKey, sizeof(s_columnKey));
                FormatEx(s_line,
                         sizeof(s_line),
                         "\t`%s` = VALUES(`%s`)\n",
                         s_columnKey,
                         s_columnKey,
                         (j < h_columnList.Length - 1) ? "," : "");
                h_sqlDumpFile.WriteLine(s_line);
            }

            h_columnValues.Close();
        } // End of while loop (Parsed each row for current table)

        h_sqlDumpFile.WriteLine(";");
        if (h_sqlDumpFile != null) {
            h_sqlDumpFile.Flush();
            h_sqlDumpFile.Close();
            QSR_LogMessage(MODULE_NAME,
                           "FINISHED DUMPING TABLE: %s",
                           s_tableName);
        }
        h_columnList.Close();
    } // End of 1st for loop (Parse all queries)

    QSR_LogMessage(MODULE_NAME,
                   "TABLES HAVE BEEN DUMPED. MOVING TO DROP EXISTING TABLES.");
    Internal_DeleteAllRows();
    Internal_DropAllTables(SQLTxn_Update_OnTablesErased);
} // End of function

void SQLTxn_OnFailedToFetchTableForDump(Database db, any data, int numQueries, const char[] error, int failIndex, DataPack[] queryData)
{
    char s_tableName[64];
    ArrayList h_tableColumnList = new ArrayList();

    for (int i; i < numQueries; i++) {
        queryData[i].Reset();
        queryData[i].ReadCell(); // Table number not needed.
        queryData[i].ReadString(s_tableName, sizeof(s_tableName));
        h_tableColumnList = view_as<ArrayList>(queryData[i].ReadCell());
        h_tableColumnList.Close();
        queryData[i].Close();
    }

    QSR_LogMessage(
        MODULE_NAME,
        "COULD NOT FETCH TABLES TO SAVE DATA!\nERROR AT QUERY %d/%d!\nTABLE: %s\nERROR: %s\n",
        failIndex+1,
        numQueries,
        s_tableName,
        error);
}

void SQLTxn_OnTablesErased(Database db, any data, int numQueries, DBResultSet[] results, DataPack[] queryData)
{
    int tableNum;
    char s_query[1];
    for (int i=0; i < numQueries; i++) {
        queryData[i].Reset();
        queryData[i].ReadString(s_query, sizeof(s_query));
        tableNum = view_as<int>(queryData[i].ReadCell());
        queryData[i].Close();
        QSR_LogMessage(
            MODULE_NAME,
            "ERASED DATA FOR TABLE: %s",
            gS_tableNames[tableNum]);
    }
}

void SQLTxn_OnTablesCleared(Database db, any data, int numQueries, DBResultSet[] results, DataPack[] queryData)
{
    int tableNum;
    char s_query[1];
    for (int i=0; i < numQueries; i++) {
        queryData[i].Reset();
        queryData[i].ReadString(s_query, sizeof(s_query));
        tableNum = view_as<int>(queryData[i].ReadCell());
        queryData[i].Close();
        QSR_LogMessage(
            MODULE_NAME,
            "DROPPED TABLE: %s",
            gS_tableNames[tableNum]);
    }
}

void SQLTxn_Setup_OnTablesErased(Database db, any data, int numQueries, DBResultSet[] results, DataPack[] queryData)
{
    QSR_LogMessage(MODULE_NAME,
                   "STEP %d (%s) FINISHED!",
                   view_as<int>(gE_currentSetupStep),
                   gS_setupStepNames[view_as<int>(gE_currentSetupStep)]);
    
    gE_currentSetupStep++;
    char s_directory[256];
    BuildPath(
        Path_SM,
        s_directory,
        sizeof(s_directory),
        SQL_SETUP_DIR);

    int i_transactionId = QSR_AutoOpenTransaction();
    if (i_transactionId == -1)
        return;

    Internal_Setup_DirectoryToTransaction(s_directory, 
                                            i_transactionId);

    Internal_Setup_SendDBTransaction(
        SQLTxn_OnTablesCreated, 
        SQLTxn_SetupQueryFailed,
        i_transactionId);
}

void SQLTxn_Update_OnTablesErased(Database db, any data, int numQueries, DBResultSet[] results, QSRDBTable[] queryData)
{
    char s_directory[PLATFORM_MAX_PATH];

    QSR_LogMessage(MODULE_NAME,
                   "TABLES HAVE BEEN ERASED. MOVING TO CREATE NEW TABLES.");
    gE_currentSetupStep = DBStep_CreateVersionTable;
    BuildPath(
        Path_SM,
        s_directory,
        sizeof(s_directory),
        SQL_SETUP_DIR);

    int i_transactionId = QSR_AutoOpenTransaction();
    if (i_transactionId == -1)
        return;

    Internal_Setup_DirectoryToTransaction(s_directory, 
                                            i_transactionId);

    Internal_Setup_SendDBTransaction(
        SQLTxn_Update_OnTablesCreated, 
        SQLTxn_SetupQueryFailed,
        i_transactionId);
}

void SQLTxn_OnTablesCreated(Database db, any prevTransactionId, int numQueries, Handle[] results, QSRDBTable[] queryData)
{
    QSR_LogMessage(MODULE_NAME,
                   "STEP %d (%s) FINISHED! %d/%d QUERIES EXECUTED",
                   view_as<int>(gE_currentSetupStep),
                   gS_setupStepNames[view_as<int>(gE_currentSetupStep)],
                   numQueries,
                   numQueries);
    gE_currentSetupStep++;
    char s_directory[256];
    BuildPath(
        Path_SM,
        s_directory,
        sizeof(s_directory),
        SQL_SETUP_DIR);

    if (!QSR_OpenTransaction(prevTransactionId)) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: COULD NOT REOPEN TRANSACTION %d IN SQLTxn_OnTablesCreated!",
                       prevTransactionId);
        return;
    }
    int i_transactionId = prevTransactionId;

    Internal_Setup_DirectoryToTransaction(s_directory, i_transactionId);
    
    // Move to fill tables
    if (gE_currentSetupStep > DBStep_FillJuncWithDefaults) {
        Internal_Setup_SendDBTransaction(
            SQLTxn_OnTablesFilled, 
            SQLTxn_SetupQueryFailed,
            i_transactionId);
        return;
    }

    // continue through setup
    Internal_Setup_SendDBTransaction(
        SQLTxn_OnTablesCreated, 
        SQLTxn_SetupQueryFailed,
        i_transactionId);
}

void SQLTxn_Update_OnTablesCreated(Database db, any prevTransactionId, int numQueries, Handle[] results, QSRDBTable[] queryData)
{
    QSR_LogMessage(MODULE_NAME,
                   "STEP %d (%s) FINISHED! %d/%d QUERIES EXECUTED",
                   view_as<int>(gE_currentSetupStep),
                   gS_setupStepNames[view_as<int>(gE_currentSetupStep)],
                   numQueries,
                   numQueries);
    
    gE_currentSetupStep++;

    char s_directory[256];
    BuildPath(
        Path_SM,
        s_directory,
        sizeof(s_directory),
        SQL_SETUP_DIR);

    if (!QSR_OpenTransaction(prevTransactionId)) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: COULD NOT REOPEN TRANSACTION %d IN SQLTxn_Update_OnTablesCreated!",
                       prevTransactionId);
        return;
    }
    int i_transactionId = prevTransactionId;
    
    if (gE_currentSetupStep > DBStep_FillJuncWithDefaults) {
        FormatEx(
            s_directory,
            sizeof(s_directory),
            "%s/main_tables/",
            SQL_DUMP_DIR);
        BuildPath(
            Path_SM,
            s_directory,
            sizeof(s_directory),
            s_directory);
        Internal_Update_DirectoryToTransaction(s_directory, i_transactionId);
        Internal_Setup_SendDBTransaction(
            SQLTxn_Update_RefillTables,
            SQLTxn_Update_FillQueryFailed,
            i_transactionId);
        return;
    }

    Internal_Setup_DirectoryToTransaction(s_directory, i_transactionId);
    Internal_Setup_SendDBTransaction(
        SQLTxn_Update_OnTablesCreated, 
        SQLTxn_SetupQueryFailed,
        i_transactionId);
}

void SQLTxn_OnTablesFilled(Database db, int prevTransactionId, int numQueries, Handle[] results, QSRDBTable[] queryData)
{
    QSR_LogMessage(MODULE_NAME,
                   "STEP %d (%s) FINISHED! %d/%d QUERIES EXECUTED",
                   view_as<int>(gE_currentSetupStep),
                   gS_setupStepNames[view_as<int>(gE_currentSetupStep)],
                   numQueries,
                   numQueries);
    
    gE_currentSetupStep++;
    if (gE_currentSetupStep >= NUM_SETUP_STEPS) {
        char s_query[512];
        FormatEx(
            s_query,
            sizeof(s_query),
            "INSERT INTO `quasar`.`db_version` (`qdb_version`) "...
            "VALUES ('%s') "...
            "ON DUPLICATE KEY UPDATE `qdb_version` = '%s';",
             DATABASE_VERSION,
             DATABASE_VERSION);
        QSR_LogQuery(
            MODULE_NAME,
            SQLCB_TableQueryError,
            _,
            DBPrio_High,
            s_query);
        QSR_LogMessage(
            MODULE_NAME,
            "DATABASE SETUP COMPLETE! CURRENT VERSION: %s",
            DATABASE_VERSION);
        return;
    }

    char s_directory[256];
    BuildPath(
        Path_SM,
        s_directory,
        sizeof(s_directory),
        SQL_SETUP_DIR);

    int i_transactionId = prevTransactionId;
    if (!QSR_OpenTransaction(prevTransactionId)) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: COULD NOT REOPEN TRANSACTION %d IN SQLTxn_Update_OnTablesFilled!",
                       prevTransactionId);
        i_transactionId = QSR_AutoOpenTransaction();
    }

    Internal_Setup_DirectoryToTransaction(s_directory, i_transactionId);
    Internal_Setup_SendDBTransaction(
        SQLTxn_OnTablesFilled, 
        SQLTxn_SetupQueryFailed,
        i_transactionId);
}

void SQLTxn_Update_RefillTables(Database db, int prevTransactionId, int numQueries, Handle[] results, QSRDBTable[] queryData)
{
    QSR_LogMessage(MODULE_NAME,
                    "TABLES HAVE BEEN CREATED. REFILLING TABLES WITH PREVIOUS DATA.");

    gE_currentSetupStep++;
    char s_directory[256];
    FormatEx(
        s_directory,
        sizeof(s_directory),
        "%s/junc_tables/",
        SQL_DUMP_DIR);

    BuildPath(
        Path_SM,
        s_directory,
        sizeof(s_directory),
        s_directory);

    int i_transactionId = prevTransactionId;
    if (!QSR_OpenTransaction(prevTransactionId)) {
        QSR_LogMessage(MODULE_NAME,
                       "ERROR: COULD NOT REOPEN TRANSACTION %d IN SQLTxn_Update_RefillTables!",
                       prevTransactionId);
        i_transactionId = QSR_AutoOpenTransaction();
    }

    Internal_Update_DirectoryToTransaction(s_directory, i_transactionId);
    Internal_Setup_SendDBTransaction(
        SQLTxn_Update_OnTablesRefilled, 
        SQLTxn_Update_FillQueryFailed,
        i_transactionId);
}

void SQLTxn_Update_OnTablesRefilled(Database db, any data, int numQueries, Handle[] results, any[] queryData)
{
    gE_currentSetupStep = DBStep_SetupInit;

    QSR_LogMessage(MODULE_NAME,
                   "TABLES HAVE BEEN REFILLED AND UPDATED!");
    QSR_LogQuery(
        MODULE_NAME,
        SQLCB_TableQueryError,
        _,
        DBPrio_High,
        "REPLACE INTO `quasar`.`db_version` (`qdb_version`) VALUES ('%s');",
        DATABASE_VERSION);
    QSR_LogMessage(
        MODULE_NAME,
        "DATABASE SETUP COMPLETE! CURRENT VERSION: %s",
        DATABASE_VERSION);
}


void SQLTxn_SetupQueryFailed(Database db, int transactionId, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    int i_tableNum;
    char s_failedQuery[3256];
    QSRDBTable e_tableNumber;
    
    DataPack h_failedQuery = null;
    // Extract the data from the pack
    if (queryData[failIndex] != INVALID_HANDLE) {
        h_failedQuery = view_as<DataPack>(queryData[failIndex]);
        if (h_failedQuery != null) {
            h_failedQuery.Reset();
            h_failedQuery.ReadString(s_failedQuery, sizeof(s_failedQuery));
            e_tableNumber = view_as<QSRDBTable>(h_failedQuery.ReadCell());
            h_failedQuery.Close();
        }
        else
        {
            QSR_LogMessage(
                MODULE_NAME,
                "ERROR: FAILED TO VIEW DATA PACK FOR QUERY %d/%d!",
                failIndex+1,
                numQueries);
        }
    }

    // Change the enum to an int
    i_tableNum = view_as<int>(e_tableNumber);
    QSR_LogMessage(
        MODULE_NAME,
        "\n--------------------\nTRANSACTION (ID%d) FAILED!",
        transactionId);
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
    
    if (s_failedQuery[0])
        QSR_LogMessage(
            MODULE_NAME,
            "%s",
            s_failedQuery);
    QSR_LogMessage(MODULE_NAME,
                   "END OF FAILED QUERY\n--------------------");
}

void SQLTxn_Update_FillQueryFailed(Database db, int transactionId, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    int i_tableNum;
    char s_failedQuery[3256];
    QSRDBTable e_tableNumber;
    
    DataPack h_failedQuery = null;
    // Extract the data from the pack
    if (queryData[failIndex] != INVALID_HANDLE) {
        h_failedQuery = view_as<DataPack>(queryData[failIndex]);
        if (h_failedQuery != null) {
            h_failedQuery.Reset();
            h_failedQuery.ReadString(s_failedQuery, sizeof(s_failedQuery));
            e_tableNumber = view_as<QSRDBTable>(h_failedQuery.ReadCell());
            h_failedQuery.Close();
        }
        else
        {
            QSR_LogMessage(
                MODULE_NAME,
                "ERROR: FAILED TO VIEW DATA PACK FOR QUERY %d/%d!",
                failIndex+1,
                numQueries);
        }
    }

    char s_mainDirectory[PLATFORM_MAX_PATH],
         s_juncDirectory[PLATFORM_MAX_PATH];

    BuildPath(Path_SM,
              s_mainDirectory,
              sizeof(s_mainDirectory),
              "%s/main_tables",
              SQL_DUMP_DIR);
    BuildPath(Path_SM,
              s_juncDirectory,
              sizeof(s_juncDirectory),
              "%s/junc_tables",
              SQL_DUMP_DIR);

    DirectoryListing h_mainDir = OpenDirectory(s_mainDirectory);
    DirectoryListing h_juncDir = OpenDirectory(s_juncDirectory);
    char s_fileName[PLATFORM_MAX_PATH];
    if (h_mainDir != null) {
        while (h_mainDir.GetNext(s_fileName, sizeof(s_fileName))) 
            DeleteFile(s_fileName);
        h_mainDir.Close();
    }

    if (h_juncDir != null) {
        while (h_juncDir.GetNext(s_fileName, sizeof(s_fileName)))
            DeleteFile(s_fileName);
        h_juncDir.Close();
    }

    // Change the enum to an int
    i_tableNum = view_as<int>(e_tableNumber);
    QSR_LogMessage(
        MODULE_NAME,
        "\n--------------------\nTRANSACTION (ID%d) FAILED!",
        transactionId);
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
    
    if (s_failedQuery[0])
        QSR_LogMessage(
            MODULE_NAME,
            "%s",
            s_failedQuery);
    QSR_LogMessage(MODULE_NAME,
                   "END OF FAILED QUERY\n--------------------");
}

/*------------------*\
|  COMMAND HANDLERS  |
\*------------------*/

Action CMD_DB_DropAllTables(int client, int args) {
    Internal_DeleteAllRows();
    Internal_DropAllTables(SQLTxn_OnTablesErased);
    return Plugin_Handled;
}

Action CMD_DB_ForceUpdate(int client, int args)
{
    Internal_StartDBUpdate();
    return Plugin_Handled;
}

Action CMD_DB_ForceCreate(int client, int args)
{
    Internal_StartDBSetup();
    return Plugin_Handled;
}

Action CMD_DB_Refresh(int client, int args)
{
    RefreshDatabaseConnection();
    return Plugin_Handled;
}