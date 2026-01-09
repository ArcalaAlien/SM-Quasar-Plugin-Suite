#if defined _quasar_database_included
	#endinput
#endif
#define _quasar_database_included

#undef MODULE_NAME
#define MODULE_NAME "Database"

#define DATABASE_VERSION    "QSRDB_V0.1.0"  // 0.1.0 for now, even with the sql
                                            // files finished there's still more
                                            // updates I have to make.

#define SQL_SETUP_DIR  "scripting/quasar/database/SQL/setup"
#define SQL_UPDATE_DIR   "scripting/quasar/database/SQL/update"

#define WAITING_FOR_SETUP view_as<QSRDBSetupStep>(-1)

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
    NUM_SETUP_STEPS // END OF TABLE SETUP!
};

enum QSRDBTable {
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
    DBTable_SubserverVotes,
    DBTable_SubserverChatLogs,

    // Junction Tables
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
    NUM_DBTABLES
};

public SharedPlugin __pl_quasarplugin =
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

}

/**
 *  Manually refresh the Quasar database.
*/
native void QSR_RefreshDatabase();

/**
 *  Fires once the core plugin has connected to the Quasar database.
 *
 *  @param db           A reference to the Database handle in the core plugin.
 *  @param subdomain    The subdomain used during the creation of the tables, EX. tf2.mywebsite.com's subdomain would be "tf2"
 *  @param subdomainLen length of the subdomain.
 */
forward void QSR_OnDatabaseConnected(Database& db, const char[] subdomain);

/**
 *  Fires once the database version is retrieved.
 *  @param dbVersion    The database version retrieved
 */
forward void QSR_OnDBVersionRetrieved(const char[] dbVersion);

/**
 *  Sends a query to the database and logs it in the logfile.
 *
 *  @param db       The database to send the query to
 *  @param query    The query to send.
 *  @param callback The SQLQueryCallback to use for the query.
 *  @param data     Any data you need to pass into the query.
 *  @param priority Priority of the query
 */
stock void QSR_LogQuery(Database db, 
                        const char[] query, 
                        SQLQueryCallback callback, 
                        any data=0, 
                        DBPriority priority=DBPrio_Normal) {
    db.Query(callback, query, data, priority);
    QSR_LogMessage(
        MODULE_NAME,
        "QUERY: %s",
        query);
}

