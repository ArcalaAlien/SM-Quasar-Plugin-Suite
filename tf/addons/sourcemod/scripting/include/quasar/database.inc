#if defined _quasar_database_included
	#endinput
#endif
#define _quasar_database_included

#undef MODULE_NAME
#define MODULE_NAME "Database"

#define DATABASE_VERSION    "QSRDB_V0.3.1"
/*
    VERSION 0.3.1:
        Changed update database functionality:
        * Now runs through the entire create database
          process, including inserting all default values.
        * The REPLACE INTO statement in table dumps has been
          replaced with a INSERT INTO ... ON DUPLICATE KEY UPDATE
          statement to ensure that existing rows are actually updated.
    VERSION 0.3.0:
        Update database functionality finally works!
        Changed owner of tag_prte to "QUASAR" from "Default"
        Updated groups.sql to replace double quotes with single quotes, and
        also add the id column in the insert values to ensure consistency.
        Removed \n from several areas in store/upgrades.sql
    VERSION 0.2.1:
        Moved category column out of maps.sql
        * Created map_categories.sql:
          This table is for the map plugin to use.
          More functionality will be
          described in `quasar_maps.sp` eventually

        (This name feels dumb)
        * Created maps_map_categories.sql:
          This table is for the map plugin to use.
          More functionality will be
          described in `quasar_maps.sp` eventually
    VERSION 0.2.0:  
        * Updated stats.sql:
            Moved first_login, last_login, playtime,
            afk_time columns to the subserver_stats table
            instead of the player table. The player table
            is for global player information only.

            Created duplicate stats for dealing with
            AFK players for every regular stat column.

            Added indicies for every column in the table.
        * Started making update process:
            Step 1:
                Finished creating the function to write all
                data in tables into INSERT statements and
                save those as SQL files.
    Version 0.1.0: Initial release of Quasar Database
        * Created step-based process for setting up the database
            All tables are successfully created
            Defaults are inserted into tables
*/


#define SQL_SETUP_DIR    "scripting/quasar/database/SQL/setup"
#define SQL_UPDATE_DIR   "scripting/quasar/database/SQL/update"
#define SQL_DUMP_DIR     "scripting/quasar/database/SQL/dumps"

#define WAITING_FOR_SETUP view_as<QSRDBSetupStep>(-1)

#define MAX_QUERY_LENGTH 4096
#define MAX_LINE_SIZE 512
#define SQL_CHUNK_SPLIT_NUM 10  // The number of chunks to break up a large query
#define INVALID_TRANSACTION -1

#define SQL_TABLE_NAME_KEY "table_name"
#define SQL_COLUMN_NAME_KEY "column_name"
#define SQL_COLUMN_DATA_TYPE_KEY "data_type"

enum QSRDBVersionStatus {
    DBVer_Equal,
    DBVer_UpdateRequired,
    DBVer_FirstTime
};

enum QSRDBSetupStep {
    DBStep_SetupInit = 0,
    DBStep_CreateVersionTable,
    DBStep_CreateTFTables,
    DBStep_CreateGlobalTables,
    DBStep_CreateSubserverTables,
    DBStep_CreateJunctionTables,
    DBStep_CreateTFLoadoutTable,
    DBStep_CreateTauntLoadoutTable,
    DBStep_CreateViews,
    DBStep_FillMainWithDefaults,
    DBStep_FillJuncWithDefaults,
    NUM_SETUP_STEPS, // END OF TABLE SETUP!
    DBStep_WaitingForSetup = -1
};

enum QSRDBTable {
    DBTable_Invalid = -1,
    // Main Tables
    DBTable_Version,
    DBTable_TFClasses,
    DBTable_TFItems,
    DBTable_TFAttributes,
    DBTable_TFQualities,
    DBTable_TFParticles,
    DBTable_TFPaintKits,
    DBTable_TFWarPaints,
    DBTable_Players,
    DBTable_RankTitles,
    DBTable_Ignore,
    DBTable_Groups,
    DBTable_Sounds,
    DBTable_Trails,
    DBTable_Tags,
    DBTable_Upgrades,
    DBTable_FunStuff,
    DBTable_ChatColors,
    DBTable_ColorPackNames,
    DBTable_SubserverStats,
    DBTable_SubserverMaps,


    // Junction Tables
    DBTable_SubserverVotes,
    DBTable_SubserverChatLogs,
    DBTable_TFItemsClasses,
    DBTable_TFItemsAttributes,
    DBTable_PlayersGroups,
    DBTable_ColorsColorPacks,
    DBTable_PlayerInventories,
    DBTable_QuasarLoadouts,
    DBTable_TFLoadouts,
    DBTable_TauntLoadouts,
    DBTable_SubserverMapFeedback,
    DBTable_SubserverPlayerMapRatings,
    DBTable_InventoryView,
    DBTable_MapRatingView,

    // V0.2.1 TABLES
    DBTable_MapCategories,
    DBTable_MapsMapCategories,
    NUM_DBTABLES
};

enum QSRDBColDataType {
    DBColType_Int,
    DBColType_Float,
    DBColType_String,
    DBColType_Bool
};

public SharedPlugin __pl_quasardatabase =
{
    name="quasar_database",
    file="quasar_database.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarplugin_SetNTVOptional()
{
    MarkNativeAsOptional("QSR_RefreshDatabase");
    MarkNativeAsOptional("QSR_LogQuery");
    MarkNativeAsOptional("QSR_SilentLogQuery");
    MarkNativeAsOptional("QSR_AutoOpenTransaction");
    MarkNativeAsOptional("QSR_OpenTransaction");
    MarkNativeAsOptional("QSR_IsTransactionAvailable");
    MarkNativeAsOptional("QSR_AddQueryToTransaction");
    MarkNativeAsOptional("QSR_SendTransaction");
}

/*---------*\
|  NATIVES  |
\*---------*/

/**
 *  Returns whether we are connected to the database or not.
 *  
 *  @return True if we're connected, false if we're not.
 */
native bool QSR_IsDatabaseConnected();

/**
 *  Manually refresh the Quasar database.
 * 
 *  @noreturn
*/
native void QSR_RefreshDatabase();

/**
 *  Sends a query to the database, displays it in console, and saves it to the log file.
 * 
 *  @param moduleName   The quasar plugin module this query comes from, important for logging!
 *  @param callback     The SQLQueryCallback function to pass through to the database.
 *  @param data         Any data you want to send with this query.
 *  @param priority     How important this query is.
 *  @param query        The actual query to send, also supports formatting rules.
 *  @param ...          The formatting variables.
 * 
 *  @noreturn
 */
native void QSR_LogQuery(const char[] moduleName, SQLQueryCallback callback, any data=0, DBPriority priority=DBPrio_Normal, const char[] query, any ...);


/**
 *  Sends a query to the database and saves it to the log file, without printing it in console.
 * 
 *  @param moduleName   The quasar plugin module this query comes from, important for logging!
 *  @param callback     The SQLQueryCallback function to pass through to the database.
 *  @param data         Any data you want to send with the query.
 *  @param priority     How important this query is.
 *  @param query        The actual query to send. Also supports formatting rules
 *  @param ...          The formatting variables
 * 
 *  @noreturn
 */
native void QSR_SilentLogQuery(const char[] moduleName, SQLQueryCallback callback, any data=0, DBPriority priority=DBPrio_Normal, const char[] query, any ...);

/**
 *  Opens a new transaction and assigns it to the first open index
 *  
 *  @return     Returns an id between 0 and MAX_TRANSACTION_LIMIT, or -1 if there are no available transactions.
 */
native int  QSR_AutoOpenTransaction();

/**
 *  Attempts to open a new transaction at the specified id.
 *  
 *  @param transactionId    The id to open a new transaction at.
 *  
 *  @return     Returns true if the system opened the transaction, returns false if it couldn't or the id was invalid.
 */
native bool QSR_OpenTransaction(int transactionId);

/**
 *  Attempts to close an open transaction at the specified id.
 * 
 *  @param transactionId    The id of the transaction to try to close
 *  
 *  @return     Returns true if the transaction was closed, returns false if the transaction or id is invalid.
 */
native bool QSR_ForceCloseTransaction(int transactionId);

/**
 *  Returns whether the database is accepting new transactions
 * 
 *  @return     True if new transactions are allowed, false if not.
 */
native bool QSR_AreNewTransactionsAllowed();

/**
 *  Returns whether the transaction array is full or not.
 * 
 *  @return True if array is full, false if not.
 */
native bool QSR_IsTransactionArrayFull();

/**
 *  Clears a transaction at the specified id.
 *  Be cautious when using this as you can accidentally
 *  close other plugin's transactions!
 * 
 *  @param transactionId    The transaction id you want to clear.
 * 
 *  @return True if transaction was cleared, false if id was invalid, transaction is clear already, or transaction is null somehow.
 */
native bool QSR_ClearTransactionId(int transactionId);

/**
 *  VERY DANGEROUS FOR EXTERNAL PLUGINS TO CALL
 *  THIS UNLESS YOU KNOW WHAT YOU ARE DOING!!!!
 * 
 *  Clears the entire transaction array. All transactions
 *  are closed and replaced with INVALID_TRANSACTION values.
 * 
 *  @noreturn
 */
native void QSR_ResetTransactionArray();

/**
 *  Checks to see if a transaction id is available or not
 * 
 *  @param transactionId        The id of the transaction you want to check.
 * 
 *  @return     True if the transaction id is available, false if not or the id is invalid
 */
native bool QSR_IsTransactionIdAvailable(int transactionId);

/**
 *  Adds a query to a specific transaction
 * 
 *  @param transactionId        The transaction to add the query to.
 *  @param data                 Any data to send with the query
 *  @param query                The query to send. Supports formatting rules.
 *  @param ...                  Formatting parameters
 * 
 *  @return True if the query was added, returns false if the transaction or id is invalid.
 */
native bool QSR_AddQueryToTransaction(const char[] module, int transactionId, any data, const char[] query, any ...);

/**
 *  Sends the specified transaction to the database for execution.
 * 
 *  @param module               The name of the module (plugin) that's sending the transaction. IMPORTANT FOR LOGGING!
 *  @param transactionId        The transaction to send to the database.
 *  @param success              The SQLTxnSuccess callback function to use
 *  @param fail                 The SQLTxnFailure callback function to use
 *  @param data                 Any data to send with the transaction
 * 
 *  @return True if transaction was executed, returns false if the transaction or id is invalid.
 */
native bool QSR_SendTransaction(const char[] module, int transactionId, SQLTxnSuccess success, SQLTxnFailure fail, any data=0, DBPriority priority=DBPrio_Normal);

/**
 *  Get a QSRDBTable value from a table name.
 * 
 *  @param tableName            The name of the table.
 * 
 *  @return                     The QSRDBTable value of the table, DBTable_Invalid if unable to find the table.
 */
native QSRDBTable QSR_GetTableFromName(const char[] tableName);

/**
 *  Get a table name from a QSRDBTable value.
 * 
 *  @param table                The QSRDBTable value to get the name of
 *  @param tableName            The char buffer to store the table name
 *  @param maxlength            The length of the char buffer
 * 
 *  @noreturn
 */
native void QSR_GetNameFromTable(const QSRDBTable table, char[] tableName, int maxlength);

/*----------*\
|  FORWARDS  |
\*----------*/

/**
 *  Fires once the database plugin has connected to the Quasar database.
 *  
 *  @param subserver            What subserver tables the server is currently using.
 */
forward void QSR_OnDatabaseConnected(const char[] subserver);

/**
 *  Fires once the database version is retrieved.
 *  @param dbVersion    The database version retrieved
 */
forward void QSR_OnDBVersionRetrieved(const char[] dbVersion);
