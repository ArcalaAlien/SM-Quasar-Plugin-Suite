#if defined _quasar_database_included
	#endinput
#endif
#define _quasar_database_included

#undef MODULE_NAME
#define MODULE_NAME "Database"

#define DATABASE_VERSION    "QSRDB_V0.1.0"

#define SQL_CREATE_DIR  "scripting/quasar/database/SQL/create/"
#define SQL_ALTER_DIR   "scripting/quasar/database/SQL/alter/"
#define SQL_INSERT_DIR  "scripting/quasar/database/SQL/insert/"


enum QSRDBVersionStatus {
    DBVer_Equal,
    DBVer_NeedsUpdated,
    DBVer_FirstTime
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
forward void QSR_OnDatabaseConnected(Database& db, char[] subdomain, int subdomainLen);

/**
 *  Fires once the database version is retrieved.
 *  @param dbVersion    The database version retrieved
 *  @param len          Length of the version string
 */
forward void QSR_OnDBVersionRetrieved(char[] dbVersion, int len);

/**
 *  Sends a query to the database and logs it in the logfile.
 *
 *  @param log      Log file to save to.
 *  @param db       Database to send query to.
 *  @param query    The query to send.
 *  @param callback The SQLQueryCallback to use for the query.
 *  @param data     Any data you need to pass into the query.
 */
stock void QSR_LogQuery(File log, Database db, const char[] query, SQLQueryCallback callback, any data=0)
{
    char line[512], s_time[24];
    FormatTime(s_time, sizeof(s_time), "%D %T");
    FormatEx(line, sizeof(line), "[QSR (%s) %s] Query Sent: %s", MODULE_NAME, s_time, query);
    if (log != null) { log.WriteLine(line); }

    db.Query(callback, query, data);
}
