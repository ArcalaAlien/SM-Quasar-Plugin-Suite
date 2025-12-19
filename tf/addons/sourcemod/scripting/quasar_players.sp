#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#include <quasar/core>
#include <quasar/players>

#undef   MODULE_NAME
#define  MODULE_NAME "Player"

#include <autoexecconfig>

// Core stuff
bool gB_late = false;
QSRChatFormat gST_chatFormatStrings;
QSRGeneralSounds gST_sounds;
QSRPlayer gST_players[MAXPLAYERS + 1];

// Database Stuff
bool        gB_dbConnected = false;
char        gS_subdomain[64];
Database    gH_db = null;
File        gH_logFile = null;

// ConVars
ConVar      gH_CVR_subdomain = null;
ConVar      gH_CVR_walletName = null;
ConVar      gH_CVR_creditName = null;

// Forwards
Handle gH_FWD_clientAuthRetrieved   = INVALID_HANDLE;
Handle gH_FWD_playerFetched         = INVALID_HANDLE;
Handle gH_FWD_creditsChanged        = INVALID_HANDLE;
Handle gH_FWD_pointsChanged         = INVALID_HANDLE;

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Player Handler)",
    author = PLUGIN_AUTHOR,
    description = "Keeps all of the player info in one place",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("quasar_players");
    CreateNative("QSR_ModPlayerPoints",     Native_QSRModPlayerPoints);
    CreateNative("QSR_ModPlayerCredits",    Native_QSRModPlayerCredits);
    CreateNative("QSR_GetPlayerPoints",     Native_QSRGetPlayerPoints);
    CreateNative("QSR_GetPlayerCredits",    Native_QSRGetPlayerCredits);
    CreateNative("QSR_GetPlaytime",         Native_QSRGetPlaytime);
    CreateNative("QSR_GetFirstLogin",       Native_QSRGetFirstLogin);
    CreateNative("QSR_GetLastLogin",        Native_QSRGetLastLogin);
    CreateNative("QSR_IsPlayerFetched",     Native_QSRIsPlayerFetched);
    CreateNative("QSR_GetAuthId",           Native_QSRGetAuthId);
    CreateNative("QSR_GetPlayerName",       Native_QSRGetPlayerName);
    CreateNative("QSR_RefreshPlayer",       Native_QSRRefreshPlayer);
    CreateNative("QSR_FindPlayerByName",    Native_QSRFindPlayerByName);
    CreateNative("QSR_FindPlayerByAuthId",  Native_QSRFindPlayerByAuthId);
    CreateNative("QSR_CheckForUpgrade",     Native_QSRCheckForUpgrade);
    CreateNative("QSR_AddUpgrade",          Native_QSRAddUpgrade);
    CreateNative("QSR_IsPlayerAlive",       Native_QSRIsPlayerAlive);

    gB_late = late;
}

public void OnPluginStart()
{
    gH_FWD_clientAuthRetrieved = CreateGlobalForward("QSR_OnClientAuthRetrieved", ET_Ignore, Param_Cell, Param_String, Param_String, Param_String);
    gH_FWD_playerFetched = CreateGlobalForward("QSR_OnPlayerInfoFetched", ET_Ignore, Param_Cell, Param_Cell);
    gH_FWD_creditsChanged = CreateGlobalForward("QSR_OnCreditsChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    gH_FWD_pointsChanged = CreateGlobalForward("QSR_OnPointsChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

    HookEvent("player_changename", Event_OnNameChange);

    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    LoadTranslations("quasar_core.phrases");
    LoadTranslations("quasar_players.phrases");

    if (gB_late)
    {
        for (int i = 1; i < MaxClients; i ++)
        {
            OnClientPostAdminCheck(i);
        }
    }
}

public void OnConfigsExecuted()
{
    gH_CVR_subdomain = FindConVar("sm_quasar_subdomain");
    gH_CVR_creditName = FindConVar("sm_quasar_bank_credit_name");
    gH_CVR_walletName = FindConVar("sm_quasar_bank_wallet_name");
    if (gH_CVR_subdomain != null)
    {
        gH_CVR_subdomain.GetString(gS_subdomain, sizeof(gS_subdomain));
    }
}

public void OnClientPostAdminCheck(int client)
{
    if (QSR_IsValidClient(client) && gB_dbConnected)
    {
        gST_players[client].Reset();

        char s_steam2ID[64], s_steam3ID[64], s_steam64ID[64], s_name[128];
        if (GetClientAuthId(client, AuthId_Steam2, s_steam2ID, sizeof(s_steam2ID)) &&
            GetClientAuthId(client, AuthId_Steam3, s_steam3ID, sizeof(s_steam3ID)) &&
            GetClientAuthId(client, AuthId_SteamID64, s_steam64ID, sizeof(s_steam64ID)))
        {
            GetClientName(client, s_name, sizeof(s_name));

            strcopy(gST_players[client].name, sizeof(gST_players[client].name), s_name);
            strcopy(gST_players[client].steam2ID, sizeof(gST_players[client].steam2ID), s_steam2ID);
            strcopy(gST_players[client].steam3ID, sizeof(gST_players[client].steam3ID), s_steam3ID);
            strcopy(gST_players[client].steam64ID, sizeof(gST_players[client].steam64ID), s_steam64ID);

            Call_StartForward(gH_FWD_clientAuthRetrieved);
            Call_PushCell(client);
            Call_PushString(s_steam2ID);
            Call_PushString(s_steam3ID);
            Call_PushString(s_steam64ID);
            Call_Finish();

            // Send our client's login info.
            QSR_DB_SendClientLoginInfo(gS_subdomain, client, s_steam2ID, s_steam3ID, s_steam64ID, s_name);
        }
        else
        {
            if (gST_players[client].pollAuthTimer != null) { KillTimer(gST_players[client].pollAuthTimer); }
            gST_players[client].pollAuthTimer = CreateTimer(2.0, Timer_PollAuth, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void OnClientDisconnect_Post(int client)
{
    gST_players[client].Reset();
}

public void QSR_OnDatabaseConnected(Database& db)
{
    gH_db = db;
    gB_dbConnected = true;
}

public void QSR_OnLogFileMade(File& file)
{
    gH_logFile = file;
}

public void QSR_OnSystemFormattingRetrieved(StringMap formatting)
{
    char key[2];
    for (int i; i < formatting.Size; i++)
    {
        IntToString(i, key, sizeof(key));
        switch(i)
        {
            case 0: { formatting.GetString(key, gST_chatFormatStrings.s_prefix, sizeof(gST_chatFormatStrings.s_prefix)); }
            case 1: { formatting.GetString(key, gST_chatFormatStrings.s_defaultColor, sizeof(gST_chatFormatStrings.s_defaultColor)); }
            case 2: { formatting.GetString(key, gST_chatFormatStrings.s_successColor, sizeof(gST_chatFormatStrings.s_successColor)); }
            case 3: { formatting.GetString(key, gST_chatFormatStrings.s_errorColor, sizeof(gST_chatFormatStrings.s_errorColor)); }
            case 4: { formatting.GetString(key, gST_chatFormatStrings.s_warnColor, sizeof(gST_chatFormatStrings.s_warnColor)); }
            case 5: { formatting.GetString(key, gST_chatFormatStrings.s_actionColor, sizeof(gST_chatFormatStrings.s_actionColor)); }
            case 6: { formatting.GetString(key, gST_chatFormatStrings.s_infoColor, sizeof(gST_chatFormatStrings.s_infoColor)); }
            case 7: { formatting.GetString(key, gST_chatFormatStrings.s_commandColor, sizeof(gST_chatFormatStrings.s_commandColor)); }
            case 8: { formatting.GetString(key, gST_chatFormatStrings.s_creditColor, sizeof(gST_chatFormatStrings.s_creditColor)); }
        }
    }
}

public void QSR_OnSystemSoundsRetrieved(StringMap sounds)
{
    char key[2];
    for (int i; i < sounds.Size; i++)
    {
        IntToString(i, key, sizeof(key));
        switch(i)
        {
            case 0: { sounds.GetString(key, gST_sounds.s_afkWarnSound, sizeof(gST_sounds.s_afkWarnSound)); }
            case 1: { sounds.GetString(key, gST_sounds.s_afkMoveSound, sizeof(gST_sounds.s_afkMoveSound)); }
            case 2: { sounds.GetString(key, gST_sounds.s_errorSound, sizeof(gST_sounds.s_errorSound)); }
            case 3: { sounds.GetString(key, gST_sounds.s_loginSound, sizeof(gST_sounds.s_loginSound)); }
            case 4: { sounds.GetString(key, gST_sounds.s_addCreditsSound, sizeof(gST_sounds.s_addCreditsSound)); }
            case 5: { sounds.GetString(key, gST_sounds.s_buyItemSound, sizeof(gST_sounds.s_buyItemSound)); }
            case 6: { sounds.GetString(key, gST_sounds.s_infoSound, sizeof(gST_sounds.s_infoSound)); }
        }
    }
}

// Natives
void Native_QSRModPlayerPoints(Handle plugin, int numParams)
{
    int     i_userid = GetNativeCell(1),
            i_client = GetClientOfUserId(i_userid);
    float   f_amount = GetNativeCell(2);
    bool    b_notify = GetNativeCell(3);
    if (QSR_IsValidClient(i_client) && QSR_IsPlayerFetched(i_userid))
    {
        Call_StartForward(gH_FWD_pointsChanged);
        Call_PushCell(i_userid);
        Call_PushCell(f_amount);
        Call_PushCell(gST_players[i_client].points);

        gST_players[i_client].points += f_amount;

        Call_PushCell(gST_players[i_client].points);
        Call_PushCellRef(b_notify);
        Call_Finish();

        if (f_amount >= 0.0)
        {
            if (b_notify)
            {
                QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%T", "QSR_PointsAdded", i_client,
                gST_chatFormatStrings.s_actionColor, gST_chatFormatStrings.s_commandColor,
                f_amount, gST_chatFormatStrings.s_actionColor,
                gST_chatFormatStrings.s_commandColor, gST_players[i_client].points);
            }
        }
        else
        {
            if (b_notify)
            {
                QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%T", "QSR_PointsLost", i_client,
                gST_chatFormatStrings.s_actionColor, gST_chatFormatStrings.s_commandColor,
                f_amount, gST_chatFormatStrings.s_actionColor,
                gST_chatFormatStrings.s_commandColor, gST_players[i_client].points);
            }
        }
    }
}

void Native_QSRModPlayerCredits(Handle plugin, int numParams)
{
    int  i_userid = GetNativeCell(1),
         i_client = GetClientOfUserId(i_userid),
         i_amount = GetNativeCell(2);
    bool b_notify = GetNativeCell(3);

    if (QSR_IsValidClient(i_client) && QSR_IsPlayerFetched(i_userid))
    {
        Call_StartForward(gH_FWD_creditsChanged);
        Call_PushCell(i_userid);
        Call_PushCell(i_amount);
        Call_PushCell(gST_players[i_client].credits);

        gST_players[i_client].credits += i_amount;

        Call_PushCell(gST_players[i_client].credits);
        Call_PushCellRef(b_notify);
        Call_Finish();
    }
}

any Native_QSRGetPlayerPoints(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return -1.0; }

    return gST_players[client].points;
}

int Native_QSRGetPlayerCredits(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return -1; }

    int credits = gST_players[client].credits;
    return credits;
}

int Native_QSRGetPlaytime(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return -1; }

    return gST_players[client].playtime;
}

int Native_QSRGetFirstLogin(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return -1; }

    return gST_players[client].firstLogin;
}

int Native_QSRGetLastLogin(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return -1; }

    return gST_players[client].lastLogin;
}

any Native_QSRIsPlayerFetched(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !client) { return false; }

    return gST_players[client].isInfoFetched;
}

any Native_QSRGetAuthId(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    AuthIdType authType = GetNativeCell(2);

    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid)) { return false; }

    switch (authType)
    {
        case AuthId_Steam2:     { SetNativeString(3, gST_players[client].steam2ID,  GetNativeCell(4)); }
        case AuthId_Steam3:     { SetNativeString(3, gST_players[client].steam3ID,  GetNativeCell(4)); }
        case AuthId_SteamID64:  { SetNativeString(3, gST_players[client].steam64ID, GetNativeCell(4)); }
        default:                { return false; }
    }

    return true;
}

any Native_QSRGetPlayerName(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return false; }

    SetNativeString(2, gST_players[client].name, GetNativeCell(3));
    return true;
}

void Native_QSRRefreshPlayer(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    OnClientPostAdminCheck(client);
}

int Native_QSRFindPlayerByName(Handle plugin, int numParams)
{
    int len;
    GetNativeStringLength(1, len);
    char[] name = new char[len + 1];
    GetNativeString(1, name, len);

    int userid = -1;
    for (int i = 1; i < MaxClients; i++)
    {

        if (!QSR_IsValidClient(i) || !QSR_IsPlayerFetched(GetClientUserId(i))) { continue; }
        userid = GetClientUserId(i);


        if (StrContains(gST_players[i].name, name, false) != -1)
        {
            QSR_LogMessage(gH_logFile, MODULE_NAME, "Found match for '%s', userid '%d'", name, userid);
            userid = GetClientUserId(i);
            break;
        }
    }

    return userid;
}

int Native_QSRFindPlayerByAuthId(Handle plugin, int numParams)
{
    AuthIdType authType = view_as<AuthIdType>(GetNativeCell(1));

    if (authType == AuthId_Engine) { return -1; }

    int len;
    GetNativeStringLength(2, len);
    char[] authId = new char[len+1];
    GetNativeString(2, authId, len+1);

    for (int i = 1; i < MaxClients; i++)
    {
        if (!QSR_IsValidClient(i) || !QSR_IsPlayerFetched(GetClientUserId(i))) { continue; }

        switch (authType)
        {
            case AuthId_Steam2:
            {
                if (StrEqual(gST_players[i].steam2ID, authId))
                {
                    return gST_players[i].userid;
                }
            }

            case AuthId_Steam3:
            {
                if (StrEqual(gST_players[i].steam3ID, authId))
                {
                    return gST_players[i].userid;
                }
            }

            case AuthId_SteamID64:
            {
                if (StrEqual(gST_players[i].steam64ID, authId))
                {
                    return gST_players[i].userid;
                }
            }
        }
    }

    return -1;
}

any Native_QSRCheckForUpgrade(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return false; }
    QSRUpgradeType upgrade = GetNativeCell(2);

    return (gST_players[client].upgradeFlags & QSR_UpgradeTypeToFlag(upgrade));
}

void Native_QSRAddUpgrade(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return; }

    QSRUpgradeType upgrade = GetNativeCell(2);
    char upgradeName[64];
    QSR_UpgradeTypeToItemId(upgrade, upgradeName, sizeof(upgradeName));

    gST_players[client].upgradeFlags |= QSR_UpgradeTypeToFlag(upgrade);
}

any Native_QSRIsPlayerAlive(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    return  (IsPlayerAlive(i_client) &&
            (TF2_GetClientTeam(i_client) == TFTeam_Blue ||
             TF2_GetClientTeam(i_client) == TFTeam_Red));
}

// General Functions
void QSR_DB_SendClientLoginInfo(const char[] subdomain, int client, const char[] steam2_id, const char[] steam3_id, const char[] steam64_id, const char[] name)
{
    int i_nameEscSize = (strlen(name)*2)+1;
    char[] s_nameEscaped = new char[i_nameEscSize];
    gH_db.Escape(name, s_nameEscaped, i_nameEscSize);

    char s_query[512];
    FormatEx(s_query, sizeof(s_query), "INSERT INTO `srv_%s_players` (steam2_id, steam3_id, steam64_id, name, last_login) \
                                        VALUES ('%s', '%s', '%s', '%s', '%d') \
                                        ON DUPLICATE KEY UPDATE \
                                        `steam2_id`='%s', `steam3_id`='%s', `steam64_id`='%s', `name`='%s', `last_login`='%d'",
                                        subdomain, steam2_id, steam3_id, steam64_id, s_nameEscaped, GetTime(),
                                        steam2_id, steam3_id, steam64_id, s_nameEscaped, GetTime());
    QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_SentLoginInfo, client);
}

// Callbacks
void Event_OnNameChange(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid"), client = GetClientOfUserId(userid);
    char newName[MAX_NAME_LENGTH], authID[MAX_AUTHID_LENGTH], query[512];
    event.GetString("newname", newName, sizeof(newName));

    if (!userid || !client || !QSR_IsPlayerFetched(userid)) { return; }
    QSR_GetAuthId(userid, AuthId_SteamID64, authID, sizeof(authID));

    strcopy(gST_players[client].name, sizeof(gST_players[client].name), newName);
    FormatEx(query, sizeof(query), "\
    UPDATE `srv_%s_players` \
    SET `name`='%s' \
    WHERE steam64_id='%s'", gS_subdomain, newName, authID);
    QSR_LogQuery(gH_logFile, gH_db, query, SQLCB_DefaultCallback);
}

// Timers
Action Timer_PollAuth(Handle timer, int client)
{
    char s_steam2ID[64], s_steam3ID[64], s_steam64ID[64], s_name[128];
    if (GetClientAuthId(client, AuthId_Steam2, s_steam2ID, sizeof(s_steam2ID)) &&
        GetClientAuthId(client, AuthId_Steam3, s_steam3ID, sizeof(s_steam3ID)) &&
        GetClientAuthId(client, AuthId_SteamID64, s_steam64ID, sizeof(s_steam64ID)))
    {
        // We got our client's steam auths!
        GetClientName(client, s_name, sizeof(s_name));

        strcopy(gST_players[client].name, sizeof(gST_players[client].name), s_name);
        strcopy(gST_players[client].steam2ID, sizeof(gST_players[client].steam2ID), s_steam2ID);
        strcopy(gST_players[client].steam3ID, sizeof(gST_players[client].steam3ID), s_steam3ID);
        strcopy(gST_players[client].steam64ID, sizeof(gST_players[client].steam64ID), s_steam64ID);

        gST_players[client].isLoggedIn = true;
        gST_players[client].lastLogin = GetTime();
        Call_StartForward(gH_FWD_clientAuthRetrieved);
        Call_PushCell(client);
        Call_PushString(s_steam2ID);
        Call_PushString(s_steam3ID);
        Call_PushString(s_steam64ID);
        Call_Finish();

        // Send our client's login info.
        QSR_DB_SendClientLoginInfo(gS_subdomain, client, s_steam2ID, s_steam3ID, s_steam64ID, s_name);

        // Store our userid.
        gST_players[client].userid = GetClientUserId(client);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

void Timer_RetrySendLogin(Handle timer, int client)
{
    if (QSR_IsValidClient(GetClientUserId(client)))
    {
        if (gST_players[client].loginAttempts == 5)
        {
            QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to send login info for Client: %d Steam64ID: %s after 5 attempts!", client, gST_players[client].steam64ID);
            QSR_NotifyUser(GetClientUserId(client), gST_sounds.s_errorSound,
            "%t", "QSR_UnableToLogIn", client,
            gST_chatFormatStrings.s_errorColor, gST_chatFormatStrings.s_commandColor, gST_chatFormatStrings.s_errorColor);
            gST_players[client].loginAttempts = 0;
            gST_players[client].isLoggedIn = false;
            return;
        }

        if (QSR_IsValidClient(GetClientUserId(client))) { OnClientPostAdminCheck(client); }
    }
}


void Timer_PopulatePlayerInfo(Handle timer, int client)
{
    if (QSR_IsValidClient(client))
    {
        if (gST_players[client].fetchInfoAttempts == 5)
        {
            QSR_LogMessage(gH_logFile, MODULE_NAME, "ERROR: Unable to get player info for SteamID %s after 5 attempts!", gST_players[client].steam64ID);
            QSR_NotifyUser(GetClientUserId(client), gST_sounds.s_errorSound,
            "%T", "QSR_UnableToFetchInfo", client,
            gST_chatFormatStrings.s_errorColor, gST_chatFormatStrings.s_commandColor, gST_chatFormatStrings.s_errorColor);
            gST_players[client].fetchInfoAttempts = 0;
            gST_players[client].isInfoFetched = false;
            return;
        }

        char s_query[512];
        FormatEx(s_query, sizeof(s_query),
        "SELECT name, steam2_id, steam3_id, steam64_id, \
        points, credits, first_login, playtime, time_afk \
        FROM `[%s Player Info]` \
        WHERE `steam64_id`='%s'",
        gS_subdomain, gST_players[client].steam64ID);

        QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_PopulatePlayerInfo, client);
    }
}

// SQL Callbacks
void SQLCB_DefaultCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0])
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, error);
    }
}


void SQLCB_SentLoginInfo(Database db, DBResultSet results, const char[] error, int client)
{
    if (error[0])
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Error sending login info for CLIENT: %d Attempting again in 5s\nERROR: %s", client, error);
        gST_players[client].loginAttempts++;
        CreateTimer(5.0, Timer_RetrySendLogin, client);
        return;
    }

    CreateTimer(0.1, Timer_PopulatePlayerInfo, client);
}

void SQLCB_PopulatePlayerInfo(Database db, DBResultSet results, const char[] error, int client)
{
    if (error[0])
    {
        gST_players[client].fetchInfoAttempts++;
        CreateTimer(5.0, Timer_PopulatePlayerInfo, client);
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to fetch player info! Attempting again in 5s.\nERROR: %s", error);
        return;
    }

    if (results.HasResults)
    {
        if(results.FetchRow())
        {
            // Let's grab the info from the result set
            char    name[MAX_NAME_LENGTH],
                    steam2ID[MAX_AUTHID_LENGTH],
                    steam3ID[MAX_AUTHID_LENGTH],
                    steam64ID[MAX_AUTHID_LENGTH];
            float   points;
            int     credits,
                    firstLogin,
                    totalPlaytime,
                    totalTimeAFK;
            results.FetchString(0, name, sizeof(name));
            results.FetchString(1, steam2ID, sizeof(steam2ID));
            results.FetchString(2, steam3ID, sizeof(steam3ID));
            results.FetchString(3, steam64ID, sizeof(steam64ID));
            strcopy(gST_players[client].name, sizeof(gST_players[client].name), name);
            strcopy(gST_players[client].steam2ID, sizeof(gST_players[client].steam2ID), steam2ID);
            strcopy(gST_players[client].steam3ID, sizeof(gST_players[client].steam3ID), steam3ID);
            strcopy(gST_players[client].steam64ID, sizeof(gST_players[client].steam64ID), steam64ID);

            points = results.FetchFloat(4);
            credits = results.FetchInt(5);
            firstLogin = results.FetchInt(6);
            totalPlaytime = results.FetchInt(7);
            totalTimeAFK = results.FetchInt(8);

            if (firstLogin == -1)
            {
                firstLogin = GetTime();
                char query[512];
                FormatEx(query, sizeof(query), "\
                UPDATE `srv_%s_players`\
                SET `first_login`='%d'\
                WHERE `steam64_id`='%s'", gS_subdomain, firstLogin, gST_players[client].steam64ID);
                QSR_LogQuery(gH_logFile, gH_db, query, SQLCB_DefaultCallback);
            }

            gST_players[client].points = points;
            gST_players[client].credits = credits;
            gST_players[client].firstLogin = firstLogin;
            gST_players[client].totalPlaytime = totalPlaytime;
            gST_players[client].totalTimeAFK = totalTimeAFK;
        }
        else
        {
            gST_players[client].fetchInfoAttempts++;
            CreateTimer(5.0, Timer_PopulatePlayerInfo, client);
            QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to fetch player info! Attempting again in 5s.\nERROR: %s", error);
            return;
        }

        Call_StartForward(gH_FWD_playerFetched);
        Call_PushCell(GetClientUserId(client));
        Call_PushCell(client);
        Call_Finish();

        gST_players[client].isLoggedIn = true;
        gST_players[client].fetchInfoAttempts = 0;
        gST_players[client].isInfoFetched = true;
        QSR_PrintToChat(GetClientUserId(client), "%T", "QSR_FetchedPlayerInfo", client, gST_chatFormatStrings.s_successColor);
    }
}
