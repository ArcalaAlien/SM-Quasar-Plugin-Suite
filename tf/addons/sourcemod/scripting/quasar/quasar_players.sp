#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#include <quasar/core>
#include <quasar/database>
#include <quasar/players>

#include <autoexecconfig>

// Core stuff
bool gB_late = false;
QSRChatFormat gST_chatFormatStrings;
QSRGeneralSounds gST_sounds;
QSRPlayer gST_players[MAXPLAYERS + 1];

// Database Stuff
bool        gB_dbConnected = false;
Database    gH_db = null;

// ConVars

// Forwards
GlobalForward gH_FWD_clientAuthRetrieved   = null;
GlobalForward gH_FWD_playerFetched         = null;
GlobalForward gH_FWD_creditsChanged        = null;


public Plugin myinfo =
{
    name = "[QUASAR] Quasar Plugin Suite (Player Handler)",
    author = PLUGIN_AUTHOR,
    description = "Keeps all of the player info in one place",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("quasar_players");
    CreateNative("QSR_ModPlayerCredits",    Native_QSRModPlayerCredits);
    CreateNative("QSR_SetPlayerCredits",    Native_QSRSetPlayerCredits);
    CreateNative("QSR_GetPlayerCredits",    Native_QSRGetPlayerCredits);
    CreateNative("QSR_IsPlayerFetched",     Native_QSRIsPlayerFetched);
    CreateNative("QSR_GetAuthId",           Native_QSRGetAuthId);
    CreateNative("QSR_GetPlayerName",       Native_QSRGetPlayerName);
    CreateNative("QSR_RefreshPlayer",       Native_QSRRefreshPlayer);
    CreateNative("QSR_FindPlayerByName",    Native_QSRFindPlayerByName);
    CreateNative("QSR_FindPlayerByAuthId",  Native_QSRFindPlayerByAuthId);
    CreateNative("QSR_IsTFPlayerAlive",       Native_QSRIsTFPlayerAlive);
    gB_late = late;
}

public void OnPluginStart()
{
    gH_FWD_clientAuthRetrieved = new GlobalForward("QSR_OnClientAuthRetrieved", ET_Ignore, Param_Cell, Param_String, Param_String, Param_String);
    gH_FWD_playerFetched = new GlobalForward("QSR_OnPlayerInfoFetched", ET_Ignore, Param_Cell, Param_Cell);
    gH_FWD_creditsChanged = new GlobalForward("QSR_OnCreditsChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

    HookEvent("player_changename", Event_OnNameChange);

    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    LoadTranslations("quasar_core.phrases");
    LoadTranslations("quasar_players.phrases");

    if (gB_late)
        for (int i = 1; i < MaxClients; i ++)
            OnClientPostAdminCheck(i);
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

            strcopy(gST_players[client].s_name, sizeof(gST_players[client].s_name), s_name);
            strcopy(gST_players[client].s_steam2ID, sizeof(gST_players[client].s_steam2ID), s_steam2ID);
            strcopy(gST_players[client].s_steam3ID, sizeof(gST_players[client].s_steam3ID), s_steam3ID);
            strcopy(gST_players[client].s_steam64ID, sizeof(gST_players[client].s_steam64ID), s_steam64ID);

            Call_StartForward(gH_FWD_clientAuthRetrieved);
            Call_PushCell(client);
            Call_PushString(s_steam2ID);
            Call_PushString(s_steam3ID);
            Call_PushString(s_steam64ID);
            Call_Finish();

            // Send our client's login info.
            QSR_DB_SendClientLoginInfo(
                client, 
                s_steam2ID, 
                s_steam3ID, 
                s_steam64ID, 
                s_name);
            return;
        }

        if (gST_players[client].h_pollAuthTimer != null)
            KillTimer(gST_players[client].h_pollAuthTimer);
        gST_players[client].h_pollAuthTimer = CreateTimer(
            AUTH_DELAY, 
            Timer_PollAuth, 
            client, 
            TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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

public void QSR_OnSystemFormattingRetrieved(StringMap formatting)
{
    char key[2];
    for (int i; i < formatting.Size; i++)
    {
        IntToString(i, key, sizeof(key));
        switch(i)
        {
            case 0:
                formatting.GetString(key, gST_chatFormatStrings.s_prefix, sizeof(gST_chatFormatStrings.s_prefix));
            case 1:
                formatting.GetString(key, gST_chatFormatStrings.s_defaultColor, sizeof(gST_chatFormatStrings.s_defaultColor));
            case 2:
                formatting.GetString(key, gST_chatFormatStrings.s_successColor, sizeof(gST_chatFormatStrings.s_successColor));
            case 3:
                formatting.GetString(key, gST_chatFormatStrings.s_errorColor, sizeof(gST_chatFormatStrings.s_errorColor));
            case 4:
                formatting.GetString(key, gST_chatFormatStrings.s_warnColor, sizeof(gST_chatFormatStrings.s_warnColor));
            case 5:
                formatting.GetString(key, gST_chatFormatStrings.s_actionColor, sizeof(gST_chatFormatStrings.s_actionColor));
            case 6:
                formatting.GetString(key, gST_chatFormatStrings.s_infoColor, sizeof(gST_chatFormatStrings.s_infoColor));
            case 7:
                formatting.GetString(key, gST_chatFormatStrings.s_commandColor, sizeof(gST_chatFormatStrings.s_commandColor));
            case 8:
                formatting.GetString(key, gST_chatFormatStrings.s_creditColor, sizeof(gST_chatFormatStrings.s_creditColor));
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
            case 0:
                sounds.GetString(key, gST_sounds.s_afkWarnSound, sizeof(gST_sounds.s_afkWarnSound));
            case 1:
                sounds.GetString(key, gST_sounds.s_afkMoveSound, sizeof(gST_sounds.s_afkMoveSound));
            case 2:
                sounds.GetString(key, gST_sounds.s_errorSound, sizeof(gST_sounds.s_errorSound));
            case 3:
                sounds.GetString(key, gST_sounds.s_loginSound, sizeof(gST_sounds.s_loginSound));
            case 4:
                sounds.GetString(key, gST_sounds.s_addCreditsSound, sizeof(gST_sounds.s_addCreditsSound));
            case 5:
                sounds.GetString(key, gST_sounds.s_buyItemSound, sizeof(gST_sounds.s_buyItemSound));
            case 6:
                sounds.GetString(key, gST_sounds.s_infoSound, sizeof(gST_sounds.s_infoSound));
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
        Call_PushCell(gST_players[i_client].i_credits);

        gST_players[i_client].i_credits += i_amount;

        Call_PushCell(gST_players[i_client].i_credits);
        Call_PushCellRef(b_notify);
        Call_Finish();
    }
}

int Native_QSRGetPlayerCredits(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1), 
        client = GetClientOfUserId(i_userid);
    
    if (!QSR_IsPlayerFetched(i_userid) || 
        !client)
        return -1;

    return gST_players[client].i_credits;
}

void Native_QSRSetPlayerCredits(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1), 
        client = GetClientOfUserId(i_userid);
    
    if (!QSR_IsValidClient(client) ||
        !QSR_IsPlayerFetched(i_userid))
        return;

    gST_players[client].i_credits = GetNativeCell(2);
}

any Native_QSRIsPlayerFetched(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1), 
        client = GetClientOfUserId(i_userid);
    if (!QSR_IsValidClient(client))
        return false;

    return gST_players[client].b_isInfoFetched;
}

any Native_QSRGetAuthId(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1), 
        client = GetClientOfUserId(i_userid);
    AuthIdType authType = GetNativeCell(2);

    if (!QSR_IsValidClient(client) ||
        !QSR_IsPlayerFetched(i_userid))
        return false;

    switch (authType)
    {
        case AuthId_Steam2:
            SetNativeString(3,
                            gST_players[client].s_steam2ID,
                            GetNativeCell(4));
        case AuthId_Steam3:
            SetNativeString(3,
                            gST_players[client].s_steam3ID,
                            GetNativeCell(4));
        case AuthId_SteamID64:
            SetNativeString(3,
                            gST_players[client].s_steam64ID,
                             GetNativeCell(4));
        default:
            return false;
    }

    return true;
}

any Native_QSRGetPlayerName(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1), 
        client = GetClientOfUserId(i_userid);
    if (!QSR_IsValidClient(client) || 
        !QSR_IsPlayerFetched(i_userid) || 
        !client)
        return false;

    SetNativeString(2, gST_players[client].s_name, GetNativeCell(3));
    return true;
}

void Native_QSRRefreshPlayer(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1), 
        client = GetClientOfUserId(i_userid);
    OnClientPostAdminCheck(client);
}

int Native_QSRFindPlayerByName(Handle plugin, int numParams)
{
    int len = 0,
        i_userid = -1;

    GetNativeStringLength(1, len);
    char[] s_name = new char[len + 1];
    GetNativeString(1, s_name, len);

    for (int i = 1; i < MaxClients; i++)
    {
        i_userid = GetClientUserId(i);
        if (!QSR_IsValidClient(i) || 
            !QSR_IsPlayerFetched(i_userid))
            continue;
    
        if (StrContains(gST_players[i].s_name, s_name, false) != -1)
        {
            QSR_LogMessage(MODULE_NAME, "Found match for '%s', i_userid '%d'", s_name, i_userid);
            break;
        }
    }

    return i_userid;
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
        if (!QSR_IsValidClient(i) || 
        !QSR_IsPlayerFetched(GetClientUserId(i))) 
            continue;

        switch (authType) {
            case AuthId_Steam2:
                if (StrEqual(gST_players[i].s_steam2ID, authId))
                    return gST_players[i].i_userid;
            case AuthId_Steam3:
                if (StrEqual(gST_players[i].s_steam3ID, authId))
                    return gST_players[i].i_userid;
            case AuthId_SteamID64:
                if (StrEqual(gST_players[i].s_steam64ID, authId))
                    return gST_players[i].i_userid;
        }
    }

    return -1;
}

any Native_QSRIsTFPlayerAlive(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1),
        i_client = GetClientOfUserId(i_userid);

    return  (IsPlayerAlive(i_client) &&
            (TF2_GetClientTeam(i_client) == TFTeam_Blue ||
             TF2_GetClientTeam(i_client) == TFTeam_Red));
}

// General Functions
void QSR_DB_SendClientLoginInfo(int client, const char[] steam2_id, const char[] steam3_id, const char[] steam64_id, const char[] s_name)
{
    int i_nameEscSize = (strlen(s_name)*2)+1;
    char[] s_nameEscaped = new char[i_nameEscSize];
    gH_db.Escape(s_name, s_nameEscaped, i_nameEscSize);

    char s_query[512];
    FormatEx(s_query, 
             sizeof(s_query), 
             "REPLACE INTO `quasar`.`players` \
             (steam2_id, steam3_id, steam64_id, s_name, last_login) \
             VALUES ('%s', '%s', '%s', '%s', '%d');",
             steam2_id,
             steam3_id,
             steam64_id,
             s_nameEscaped,
             GetTime());
    QSR_LogQuery(
        gH_db, 
        s_query, 
        SQLCB_SentLoginInfo, 
        client);
}

// Callbacks
void Event_OnNameChange(Event event, const char[] s_name, bool dontBroadcast)
{
    int i_userid = event.GetInt("i_userid"),
        i_client = GetClientOfUserId(i_userid);
    char s_newName[MAX_NAME_LENGTH],
         s_authID[MAX_AUTHID_LENGTH], 
         s_query[512];
    event.GetString("newname",
                    s_newName,
                    sizeof(s_newName));

    if (!QSR_IsValidClient(i_client) ||
        !QSR_IsPlayerFetched(i_userid))
        return;

    QSR_GetAuthId(i_userid,
                  AuthId_SteamID64, 
                  s_authID, 
                  sizeof(s_authID));

    strcopy(gST_players[i_client].s_name, 
            sizeof(gST_players[i_client].s_name), 
            s_newName);

    char s_escapedName[sizeof(s_newName)*2+1];
    gH_db.Escape(s_newName, 
                 s_escapedName, 
                 sizeof(s_escapedName));

    FormatEx(s_query,
             sizeof(s_query), 
             "UPDATE `quasar`.`players` \
             SET `s_name`='%s' \
             WHERE steam64_id='%s'", 
             s_escapedName, 
             s_authID);

    QSR_LogQuery(
        gH_db, 
        s_query,
        SQLCB_DefaultCallback);
}

// Timers
Action Timer_PollAuth(Handle timer, int client)
{
    char s_steam2ID[64], s_steam3ID[64], s_steam64ID[64], s_name[128];
    if (GetClientAuthId(client, AuthId_Steam2, s_steam2ID, sizeof(s_steam2ID)) &&
        GetClientAuthId(client, AuthId_Steam3, s_steam3ID, sizeof(s_steam3ID)) &&
        GetClientAuthId(client, AuthId_SteamID64, s_steam64ID, sizeof(s_steam64ID)) &&
        !StrEqual(s_steam2ID, "STEAM_ID_PENDING") &&
        !StrEqual(s_steam3ID, "STEAM_ID_PENDING") &&
        !StrEqual(s_steam2ID, "STEAM_ID_LAN") &&
        !StrEqual(s_steam3ID, "STEAM_ID_LAN") &&
        !StrEqual(s_steam2ID, "BOT") && 
        !StrEqual(s_steam3ID, "BOT"))
    {
        // We got our client's steam auths!
        GetClientName(client, s_name, sizeof(s_name));

        strcopy(gST_players[client].s_name, sizeof(gST_players[client].s_name), s_name);
        strcopy(gST_players[client].s_steam2ID, sizeof(gST_players[client].s_steam2ID), s_steam2ID);
        strcopy(gST_players[client].s_steam3ID, sizeof(gST_players[client].s_steam3ID), s_steam3ID);
        strcopy(gST_players[client].s_steam64ID, sizeof(gST_players[client].s_steam64ID), s_steam64ID);

        gST_players[client].b_isLoggedIn = true;
        Call_StartForward(gH_FWD_clientAuthRetrieved);
        Call_PushCell(client);
        Call_PushString(s_steam2ID);
        Call_PushString(s_steam3ID);
        Call_PushString(s_steam64ID);
        Call_Finish();

        // Send our client's login info.
        QSR_DB_SendClientLoginInfo(
            client, 
            s_steam2ID, 
            s_steam3ID, 
            s_steam64ID, 
            s_name);

        // Store our i_userid.
        gST_players[client].i_userid = GetClientUserId(client);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

void Timer_RetrySendLogin(Handle timer, int client)
{
    if (QSR_IsValidClient(GetClientUserId(client)))
    {
        if (gST_players[client].i_loginAttempts >= MAX_LOGIN_ATTEMPTS)
        {
            QSR_LogMessage(MODULE_NAME, "Unable to send login info for Client: %d s_steam64ID: %s after 5 attempts!", client, gST_players[client].s_steam64ID);
            QSR_NotifyUser(
                GetClientUserId(client), 
                gST_sounds.s_errorSound,
                "%t", 
                "QSR_UnableToLogIn", 
                client,
                gST_chatFormatStrings.s_errorColor, 
                gST_chatFormatStrings.s_commandColor, 
                gST_chatFormatStrings.s_errorColor);
            gST_players[client].i_loginAttempts = 0;
            gST_players[client].b_isLoggedIn = false;
            return;
        }

        if (QSR_IsValidClient(GetClientUserId(client)))
            OnClientPostAdminCheck(client);
    }
}


void Timer_PopulatePlayerInfo(Handle timer, int client)
{
    if (QSR_IsValidClient(client))
    {
        if (gST_players[client].i_fetchInfoAttempts >= MAX_FETCH_INFO_ATTEMPTS)
        {
            QSR_LogMessage(
                MODULE_NAME, 
                "ERROR: Unable to get player info for SteamID %s after %d attempts!", 
                gST_players[client].s_steam64ID,
                gST_players[client].i_fetchInfoAttempts);
            QSR_NotifyUser(
                GetClientUserId(client), 
                gST_sounds.s_errorSound,
                "%T", 
                "QSR_UnableToFetchInfo", 
                client,
                gST_chatFormatStrings.s_errorColor, 
                gST_chatFormatStrings.s_commandColor, 
                gST_chatFormatStrings.s_errorColor);

            gST_players[client].i_fetchInfoAttempts = 0;
            gST_players[client].b_isInfoFetched = false;
            return;
        }

        char s_query[512];
        FormatEx(s_query, sizeof(s_query),
            "SELECT p.player_name, p.steam2_id, p.steam3_id, p.steam64_id, p.i_credits \
            FROM `quasar`.`players` \
            WHERE `steam64_id`='%s'",
            gST_players[client].s_steam64ID);

        QSR_LogQuery(
            gH_db, 
            s_query, 
            SQLCB_PopulatePlayerInfo, 
            client);
    }
}

// SQL Callbacks
void SQLCB_DefaultCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0])
        QSR_LogMessage(MODULE_NAME, error);
}


void SQLCB_SentLoginInfo(Database db, DBResultSet results, const char[] error, int client)
{
    if (error[0])
    {
        QSR_LogMessage(MODULE_NAME, "Error sending login info for CLIENT: %d Attempting again in 5s\nERROR: %s", client, error);
        gST_players[client].i_loginAttempts++;
        CreateTimer(
            RETRY_DELAY, 
            Timer_RetrySendLogin, 
            client);
        return;
    }

    CreateTimer(
        FETCH_DELAY, 
        Timer_PopulatePlayerInfo, 
        client);
}

void SQLCB_PopulatePlayerInfo(Database db, DBResultSet results, const char[] error, int client)
{
    if (error[0])
    {
        gST_players[client].i_fetchInfoAttempts++;
        CreateTimer(
            5.0, 
            Timer_PopulatePlayerInfo, 
            client);
        QSR_LogMessage(MODULE_NAME, "Unable to fetch player info! Attempting again in 5s.\nERROR: %s", error);
        return;
    }

    if (results.HasResults)
    {
        if(results.FetchRow())
        {
            // Let's grab the info from the result set
            char    s_name[MAX_NAME_LENGTH],
                    s_steam2ID[MAX_AUTHID_LENGTH],
                    s_steam3ID[MAX_AUTHID_LENGTH],
                    s_steam64ID[MAX_AUTHID_LENGTH];
            
            results.FetchString(0, s_name, sizeof(s_name));
            results.FetchString(1, s_steam2ID, sizeof(s_steam2ID));
            results.FetchString(2, s_steam3ID, sizeof(s_steam3ID));
            results.FetchString(3, s_steam64ID, sizeof(s_steam64ID));
            strcopy(gST_players[client].s_name, sizeof(gST_players[client].s_name), s_name);
            strcopy(gST_players[client].s_steam2ID, sizeof(gST_players[client].s_steam2ID), s_steam2ID);
            strcopy(gST_players[client].s_steam3ID, sizeof(gST_players[client].s_steam3ID), s_steam3ID);
            strcopy(gST_players[client].s_steam64ID, sizeof(gST_players[client].s_steam64ID), s_steam64ID);

            gST_players[client].i_credits = results.FetchInt(4);
        }
        else
        {
            gST_players[client].i_fetchInfoAttempts++;
            CreateTimer(
                FETCH_DELAY, 
                Timer_PopulatePlayerInfo, 
                client);
            QSR_LogMessage(MODULE_NAME, 
                           "Unable to fetch player info! Attempting again in 5s.\nERROR: %s", 
                           error);
            return;
        }

        Call_StartForward(gH_FWD_playerFetched);
        Call_PushCell(GetClientUserId(client));
        Call_PushCell(client);
        Call_Finish();

        gST_players[client].b_isLoggedIn = true;
        gST_players[client].i_fetchInfoAttempts = 0;
        gST_players[client].b_isInfoFetched = true;
        QSR_PrintToChat(GetClientUserId(client), 
                        "%T",
                        "QSR_FetchedPlayerInfo",
                        client,
                        gST_chatFormatStrings.s_successColor);
    }
}
