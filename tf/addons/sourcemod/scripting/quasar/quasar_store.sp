#include <sourcemod>
#include <sdktools>

#include <quasar/core>
#include <quasar/database>
#undef  MODULE_NAME
#define MODULE_NAME "Store"

#include <autoexecconfig>

// Store stuff
int gI_fetchTrailsAttempts = 0;
int gI_fetchSoundsAttempts = 0;

public Plugin myinfo =
{
    name = "[QUASAR] Quasar Plugin Suite (Store Handler)",
    author = PLUGIN_AUTHOR,
    description = "Description",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public void OnPluginStart()
{

}


void Timer_RetryPrecacheTrails(Handle timer)
{
    if (gI_fetchTrailsAttempts == 5)
    {
        QSR_LogMessage( MODULE_NAME, "Unable to precache store sounds after 5 attempts!");
        gI_fetchTrailsAttempts = 0;
        return;
    }

    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT vtf, vmt \
    FROM str_trails");
    QSR_LogQuery(gH_db, s_query, SQLCB_PrecacheTrails);
}

void Timer_RetryPrecacheSounds(Handle timer)
{
    if (gI_fetchSoundsAttempts == 5)
    {
        QSR_LogMessage( MODULE_NAME, "Unable to precache store sounds after 5 attempts!");
        gI_fetchSoundsAttempts = 0;
        timer.Close();
        return;
    }

    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT filepath \
    FROM str_sounds");
    QSR_LogQuery(gH_db, s_query, SQLCB_PrecacheSounds);
}

void SQLCB_PrecacheTrails(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0])
    {
        QSR_LogMessage( MODULE_NAME, "Unable to precache system trail textures! Retrying in 5s.\nERROR: %s", error);
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
        QSR_LogMessage( MODULE_NAME, "Unable to precache system sounds! Retrying in 5s.\nERROR: %s", error);
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