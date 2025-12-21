//TODO: MOVE BELOW CODE TO quasar_check_db_version.sp
enum QSRDBVersionStatus {
    DBVer_Equal,
    DBVer_NeedsUpdated,
    DBVer_FirstTime
};

public void QSR_OnDBVersionRetrieved(char[] dbVersion, int len)
{
    switch (QSR_IsDatabaseUpToDate()) {
        case DBVer_FirstTime:
            QSR_GenerateSQLTables();
        case DBVer_NeedsUpdated:
            QSR_UpdateSQLTables();
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

QSRDBVersionStatus QSR_IsDatabaseUpToDate() {
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
