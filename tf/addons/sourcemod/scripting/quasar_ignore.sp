#include <sourcemod>
#include <clientprefs>
#include <sdktools>

#include <quasar/core>
#include <quasar/ignore>

#include <autoexecconfig>
#include <chat-processor>

// Core Variables
Database        gH_db = null;
char            gS_subdomain[64];
File            gH_logFile = null;
bool            gB_late = false;
QSRChatFormat   gST_chatFormatStrings;

// ConVars
ConVar gH_CVR_allowIgnoreAdmin = null;
ConVar gH_CVR_allowIgnoreVoice = null;
ConVar gH_CVR_allowIgnoreChat = null;

// Ignore Variables
                 //Ignorer         Ignoree
                 //Ignoree contains the ignore flags, 2 bit flag
                 //00 - None, 01 - Chat, 10 - Voice, 11 - Both
int gI_ignoreArray[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool gB_ignoreAllChat[MAXPLAYERS + 1];
bool gB_ignoreAllVoice[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Ignore)",
    author = PLUGIN_AUTHOR,
    description = "Allows players to ignore others text and voice chat.",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("quasar_ignore");
    CreateNative("QSR_IgnoreTargetPlayer", Native_QSRIgnoreTargetPlayer);
    gB_late = late;
}

public void OnPluginStart()
{
    AutoExecConfig_SetFile("plugins.quasar_ignore");

    gH_CVR_allowIgnoreAdmin = AutoExecConfig_CreateConVar(
        "sm_quasar_ignore_allow_ignore_admins",
        "0",
        "Allows users to ignore an admin's voice/text chat. Recommended to leave off.",
        0, true, _, true, 1.0);

    gH_CVR_allowIgnoreChat = AutoExecConfig_CreateConVar(
        "sm_quasar_ignore_allow_ignore_chat",
        "1", "Allows users to ignore other user's text chat.",
        0, true, _, true, 1.0);

    gH_CVR_allowIgnoreVoice = AutoExecConfig_CreateConVar(
        "sm_qusar_ignore_allow_ignore_voice",
        "1",
        "Allows users to ignore other user's voice chat.", 0, true, _, true, 1.0);

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    RegConsoleCmd(
        "sm_ignore",
        USR_IgnoreUser,
        "Use this to ignore a player's voice or text chat.");

    RegConsoleCmd(
        "sm_i",
        USR_IgnoreUser,
        "Alias for sm_ignore");

    RegConsoleCmd(
        "sm_ig",
        USR_IgnoreUser,
        "Alias for sm_ignore");

    RegConsoleCmd(
        "sm_ignoreall",
        USR_IgnoreAll,
        "Use this to ignore all voice or text chat.");

    RegConsoleCmd(
        "sm_iga",
        USR_IgnoreAll,
        "Alias for sm_ignoreall");

    RegConsoleCmd(
        "sm_ia",
        USR_IgnoreAll,
        "Alias for sm_ignoreall");

    RegAdminCmd(
        "sm_forceignore",
        ADM_ForceIgnore,
        ADMFLAG_GENERIC,
        "Force a user to ignore another user's voice or text chat");

    RegAdminCmd(
        "sm_fig",
        ADM_ForceIgnore,
        ADMFLAG_GENERIC,
        "Alias for sm_forceignore");

    RegAdminCmd(
        "sm_fi",
        ADM_ForceIgnore,
        ADMFLAG_GENERIC,
        "Alias for sm_forceignore");

    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    LoadTranslations("quasar_core.phrases");
    LoadTranslations("quasar_ignore.phrases");
}

public void OnClientPostAdminCheck(int client)
{
    for (int i = 1; i < MaxClients; i++)
    {
        gI_ignoreArray[client][i] = IGNORE_FLAGS_NONE;

        if (QSR_IsValidClient(i))
            Internal_UpdateIgnoreFromSQL(GetClientUserId(i), GetClientUserId(client));
    }
}

public void OnClientCookiesCached(int client)
{
    char s_clientAuth[64];
    char s_targetAuth[64];
    char s_query[512];

    GetClientAuthId(client, AuthId_SteamID64,
                        s_clientAuth, sizeof(s_clientAuth));
    for (int i = 1; i < MaxClients; i++)
    {
        GetClientAuthId(client, AuthId_SteamID64,
                        s_targetAuth, sizeof(s_targetAuth));

        FormatEx(s_query, sizeof(s_query), "\
            SELECT `ignore_flags` \
            FROM `quasar`.`srv_%s_playersignore \
            WHERE `steam_id` = '%s' AND \
            `target_steam_id` = '%s'",
        gS_subdomain, s_clientAuth, s_targetAuth);
    }
}

public void OnClientDisconnect_Post(int client)
{
    for (int i = 1; i < MaxClients; i++)
        gI_ignoreArray[client][i] = IGNORE_FLAGS_NONE;
}

public void QSR_OnDatabaseConnected(Database& db)
{
    gH_db = db;
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
            case 0: {
                formatting.GetString(
                    key,
                    gST_chatFormatStrings.s_prefix,
                    sizeof(gST_chatFormatStrings.s_prefix));
            }
            case 1: {
                formatting.GetString(
                    key,
                    gST_chatFormatStrings.s_defaultColor,
                    sizeof(gST_chatFormatStrings.s_defaultColor));
            }
            case 2: {
                formatting.GetString(
                    key,
                    gST_chatFormatStrings.s_successColor,
                    sizeof(gST_chatFormatStrings.s_successColor));
            }
            case 3: {
                formatting.GetString(
                    key,
                    gST_chatFormatStrings.s_errorColor,
                    sizeof(gST_chatFormatStrings.s_errorColor));
            }
            case 4: {
                formatting.GetString(
                    key,
                    gST_chatFormatStrings.s_warnColor,
                    sizeof(gST_chatFormatStrings.s_warnColor));
            }
            case 5: {
                formatting.GetString(
                    key,
                    gST_chatFormatStrings.s_actionColor,
                    sizeof(gST_chatFormatStrings.s_actionColor));
            }
            case 6: {
                formatting.GetString(
                    key,
                    gST_chatFormatStrings.s_infoColor,
                    sizeof(gST_chatFormatStrings.s_infoColor));
            }
            case 7: {
                formatting.GetString(
                    key,
                    gST_chatFormatStrings.s_commandColor,
                    sizeof(gST_chatFormatStrings.s_commandColor));
            }
            case 8: {
                formatting.GetString(
                    key,
                    gST_chatFormatStrings.s_creditColor,
                    sizeof(gST_chatFormatStrings.s_creditColor));
            }
        }
    }
}

public Action CP_OnChatMessageSendPre(int sender, int reciever, char[] buffer, int maxlength)
{
    // Is there a better way to do this?
    // Probably.
    if (gB_ignoreAllChat[reciever])
    {
        if (GetUserAdmin(sender) != INVALID_ADMIN_ID)
        {
            if (gH_CVR_allowIgnoreAdmin.BoolValue)
                return Plugin_Stop;
        }
        else
            return Plugin_Stop;
    }


    if (Internal_ClientHasIgnored(
            GetClientUserId(reciever),
            GetClientUserId(sender),
            IgnoreType_Chat))
        return Plugin_Stop;
}

Quasar_IgnoreType QSR_StringToIgnoreType(const char[] string)
{
    if (strcmp(string, "v", false) == 0 ||
        strcmp(string, "vc", false) == 0 ||
        StrContains(string, "voice", false))
        return IgnoreType_Voice;

    return IgnoreType_Chat;
}

public void QSR_IgnoreBuildPage1(int userid)
{
    int client = GetClientOfUserId(userid);
    Menu p_ignoreMenuPage1 = new Menu(MenuHandler_IgnorePage1);
    p_ignoreMenuPage1.SetTitle("%t", "QSR_IgnorePage1Title");

    char s_display[128];
    FormatEx(
        s_display,
        sizeof(s_display),
        "%T",
        client,
        "QSR_IgnoreOptionChat");
    p_ignoreMenuPage1.AddItem("c", s_display);

    FormatEx(
        s_display,
        sizeof(s_display),
        "%T",
        client,
        "QSR_IgnoreOptionVoice");
    p_ignoreMenuPage1.AddItem("v", s_display);

    if (gB_ignoreAllChat[client])
        FormatEx(
            s_display,
            sizeof(s_display),
            "%T",
            client,
            "QSR_IgnoreOptionChatAll",
            "QSR_Unignore");
    else
        FormatEx(
            s_display,
            sizeof(s_display),
            "%T",
            client,
            "QSR_IgnoreOptionChatAll",
            "QSR_Ignore");
    p_ignoreMenuPage1.AddItem("C", s_display);

    if (gB_ignoreAllVoice[client])
        FormatEx(
            s_display,
            sizeof(s_display),
            "%T",
            client,
            "QSR_IgnoreOptionVoiceAll",
            "QSR_Unignore");
    else
        FormatEx(
            s_display,
            sizeof(s_display),
            "%T",
            client,
            "QSR_IgnoreOptionVoiceAll",
            "QSR_Ignore");
    p_ignoreMenuPage1.AddItem("V", s_display);

    FormatEx(
        s_display,
        sizeof(s_display),
        "%T",
        client,
        "QSR_IgnoreOptionViewIgnored"
    );
    p_ignoreMenuPage1.AddItem("I", s_display);
    p_ignoreMenuPage1.Display(client, 20);
}

public void QSR_IgnoreBuildClientList(int userId, Quasar_IgnoreType ignoreType)
{
    int client = GetClientOfUserId(userId);
    if (!QSR_IsValidClient(client))
        return;

    char s_info[8], s_display[148], s_ignoreStatus[16];
    Menu p_ignoreMenuClientList = new Menu(MenuHandler_IgnoreClientList);

    if (ignoreType == IgnoreType_Voice)
    {
        p_ignoreMenuClientList.SetTitle(
            "%t",
            "QSR_IgnoreClientListTitle",
            "QSR_IgnoreVoice");

        p_ignoreMenuClientList.AddItem(
            "__V",
            "X",
            ITEMDRAW_IGNORE);
    }
    else
    {
        p_ignoreMenuClientList.SetTitle(
            "%t",
            "QSR_IgnoreClientListTitle",
            "QSR_IgnoreChat");

        p_ignoreMenuClientList.AddItem(
            "__C",
            "X",
            ITEMDRAW_IGNORE);
    }

    for (int i=1; i<MaxClients; i++)
    {
        if (!QSR_IsValidClient(i) || i == client)
            continue;

        IntToString(i, s_info, sizeof(s_info));
        GetClientName(i, s_display, sizeof(s_display));

        if (Internal_ClientHasIgnored(
                userId,
                GetClientUserId(i),
                ignoreType))
        {
            FormatEx(s_ignoreStatus, sizeof(s_ignoreStatus),
                        " [%T]", client, "QSR_IgnoreUnignore");
            StrCat(s_info, sizeof(s_info), "__U");
        }
        else
        {
            FormatEx(s_ignoreStatus, sizeof(s_ignoreStatus),
                        " [%T]", client, "QSR_IgnoreIgnore");
            StrCat(s_info, sizeof(s_info), "__I");
        }
        StrCat(s_display, sizeof(s_display), s_ignoreStatus);

        p_ignoreMenuClientList.AddItem(s_info, s_display);
    }
}

void QSR_IgnoreBuildIgnoredMenu(int userId)
{

}

public int MenuHandler_IgnorePage1(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int userId = GetClientUserId(param1);
            char choice[4];
            menu.GetItem(param2, choice, sizeof(choice));

            switch (choice[0])
            {
                case 'c':
                    QSR_IgnoreBuildClientList(userId, IgnoreType_Chat);

                case 'v':
                    QSR_IgnoreBuildClientList(userId, IgnoreType_Chat);

                case 'C':
                {
                    Internal_ToggleIgnoreAllPlayers(userId, IgnoreType_Chat);
                    QSR_IgnoreBuildPage1(userId);
                }

                case 'V':
                {
                    Internal_ToggleIgnoreAllPlayers(userId, IgnoreType_Chat);
                    QSR_IgnoreBuildPage1(userId);
                }

                case 'I':
                    QSR_IgnoreBuildIgnoredMenu(userId);
            }
        }

        case MenuAction_Cancel:
        {

        }

        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

public int MenuHandler_IgnoreClientList(Menu menu, MenuAction action, int param1, int param2)
{
    return 0;
}

public any Native_QSRIgnoreTargetPlayer(Handle plugin, int numParams)
{
    return Internal_SetClientIgnore(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4));
}

public any Native_QSRClientIgnoredTarget(Handle plugin, int numParams)
{
    return Internal_ClientHasIgnored(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

Quasar_IgnoreResult Internal_SetClientIgnore(int userId, int targetUserId, Quasar_IgnoreType ignoreType, bool targetStatus)
{
    int client = GetClientOfUserId(userId),
        target = GetClientOfUserId(targetUserId);

    if (!QSR_IsValidClient(client))
    {
        QSR_ThrowError(gH_logFile, MODULE_NAME, "Attempt made to set ignore flags for invalid client %d!", client);
        return IgnoreResult_InvalidClient;
    }

    char s_clientAuth[64];
    GetClientAuthId(client, AuthId_Steam3, s_clientAuth, sizeof(s_clientAuth));

    if (!QSR_IsValidClient(target))
    {
        QSR_ThrowError(gH_logFile, MODULE_NAME, "Client %d (%s) attempted to ignore invalid target client %d!", client, s_clientAuth, target);
        return IgnoreResult_InvalidTarget;
    }

    if (GetUserAdmin(target) != INVALID_ADMIN_ID && !gH_CVR_allowIgnoreAdmin.BoolValue)
    {
        QSR_ThrowError(gH_logFile, MODULE_NAME, "Client %d (%s) attempted to ignore an admin!", client, s_clientAuth);
        return IgnoreResult_TargetedAdmin;
    }

    char s_targetAuth[64], s_query[512];
    Quasar_IgnoreResult e_result = IgnoreResult_Unignored;
    GetClientAuthId(target, AuthId_Steam3, s_targetAuth, sizeof(s_targetAuth));

    switch (ignoreType)
    {
        case IgnoreType_Chat:
        {
            // We want to ignore this user's text chat
            // Handled in Chat-Processor forward
            if (targetStatus)
            {
                gI_ignoreArray[client][target] = gI_ignoreArray[client][target] |= IGNORE_FLAGS_CHAT;
                e_result = IgnoreResult_Ignored;
            // We want to unignore this user's text chat
            }
            else
            {
                gI_ignoreArray[client][target] = gI_ignoreArray[client][target] &= IGNORE_FLAGS_CHAT;
            }
        }

        case IgnoreType_Voice:
        {
            // We want to ignore this user's voice chat
            if (targetStatus)
            {
                gI_ignoreArray[client][target] = gI_ignoreArray[client][target] |= IGNORE_FLAGS_VOICE;
                SetListenOverride(client, target, Listen_No);
                e_result = IgnoreResult_Ignored;
            }
            // We want to unignore this user's voice chat
            else
            {
                gI_ignoreArray[client][target] = gI_ignoreArray[client][target] &= IGNORE_FLAGS_VOICE;
                SetListenOverride(client, target, Listen_Default);
            }
        }
    }

    FormatEx(s_query, sizeof(s_query), "INSERT INTO `srv_%s_playersignore`\
                                        VALUES ('%s', '%s', '%d') ON DUPLICATE KEY UPDATE",
                                        gS_subdomain, s_clientAuth, s_targetAuth, gI_ignoreArray[client][target]);
    QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_DefaultCallback);

    return e_result;
}

bool Internal_ClientHasIgnored(int userId, int targetUserId, Quasar_IgnoreType ignoreType)
{
    int client = GetClientOfUserId(userId),
        target = GetClientOfUserId(targetUserId);

    if (ignoreType == IgnoreType_Voice)
        if ((gI_ignoreArray[client][target] & IGNORE_FLAGS_VOICE) == 0)
            return true;
    else
        if ((gI_ignoreArray[client][target] & IGNORE_FLAGS_CHAT) == 0)
            return true;

    return false;
}

Quasar_IgnoreResult Internal_ToggleIgnoreAllPlayers(int userId, Quasar_IgnoreType ignoreType)
{
    int client = GetClientOfUserId(userId);
    Quasar_IgnoreResult e_result = IgnoreResult_UnknownError;

    if (ignoreType == IgnoreType_Chat)
    {
        gB_ignoreAllChat[client] = !gB_ignoreAllChat[client];
        if (gB_ignoreAllChat[client])
            e_result = IgnoreResult_Ignored;
        else
            e_result = IgnoreResult_Unignored;
    }
    else
    {
        gB_ignoreAllVoice[client] = !gB_ignoreAllVoice[client];

        for (int i=1; i<MaxClients; i++)
        {
            if (!QSR_IsValidClient(i) || i == client)
                continue;

            if (gB_ignoreAllVoice[client])
            {
                Internal_SetClientIgnore(userId, GetClientUserId(i),
                                        IgnoreType_Voice, true);
                e_result = IgnoreResult_Ignored;
            }
            else
            {
                Internal_SetClientIgnore(userId, GetClientUserId(i),
                                        IgnoreType_Voice, false);
                e_result = IgnoreResult_Unignored;
            }
        }
    }

    return e_result;
}

void Internal_UpdateIgnoreFromSQL(int userId, int targetUserId)
{
    int i_client = GetClientOfUserId(userId),
        i_target = GetClientOfUserId(targetUserId);
    char s_clientAuth[64], s_targetAuth[64], s_query[512];

    if (!QSR_IsValidClient(i_client) ||
        !QSR_IsValidClient(i_target))
        return;

    //TODO: Handle AuthID return vals
    GetClientAuthId(i_client, AuthId_SteamID64, s_clientAuth, sizeof(s_clientAuth));
    GetClientAuthId(i_target, AuthId_SteamID64, s_targetAuth, sizeof(s_targetAuth));

    FormatEx(s_query, sizeof(s_query), "\
    SELECT ignore_flags \
    FROM srv_%s_playersignore \
    WHERE steam_id='%s' \
    AND target_steam_id='%s'",
    gS_subdomain, s_clientAuth, s_targetAuth);

    DataPack h_playerPack = new DataPack();
    h_playerPack.Reset();
    h_playerPack.WriteCell(i_client);
    h_playerPack.WriteCell(i_target);
    QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_FetchIgnoreStatus, h_playerPack);
}

public void SQLCB_DefaultCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0])
        QSR_ThrowError(gH_logFile, MODULE_NAME, error);
}

public void SQLCB_FetchIgnoreStatus(Database db, DBResultSet results, const char[] error, DataPack playerPack)
{
    if (error[0])
    {
        QSR_ThrowError(gH_logFile, MODULE_NAME, error);
        return;
    }


}

public Action USR_IgnoreUser(int client, int args)
{
    if (client == 0)
    {
        QSR_ThrowError(gH_logFile, MODULE_NAME, "The server is not allowed to ignore user voice or text chat!");
        return Plugin_Handled;
    }

    if (!QSR_IsValidClient(client))
    {
        QSR_ThrowError(gH_logFile, MODULE_NAME, "Invalid client %d attempted to ignore a user!", client);
        return Plugin_Handled;
    }

    int i_userId = GetClientUserId(client),
        i_targetUserId = 0;

    switch (args)
    {
        case 1:
        {
            char s_ignoreMode[32];
            GetCmdArg(1, s_ignoreMode, sizeof(s_ignoreMode));

            Quasar_IgnoreType ignoreType = QSR_StringToIgnoreType(s_ignoreMode);

            if (ignoreType == IgnoreType_Voice && !gH_CVR_allowIgnoreVoice.BoolValue)
            {
                QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreVoiceDisabled",
                                                gST_chatFormatStrings.s_errorColor);
                return Plugin_Handled;
            }
            else if (ignoreType == IgnoreType_Chat && !gH_CVR_allowIgnoreChat.BoolValue)
            {
                QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreChatDisabled",
                                                gST_chatFormatStrings.s_errorColor);
                return Plugin_Handled;
            }

            QSR_IgnoreBuildClientList(i_userId, QSR_StringToIgnoreType(s_ignoreMode));
        }

        case 2:
        {
            char s_playerName[128];
            char s_ignoreMode[32];
            int i_targetClient[2];
            bool tn_is_ml;

            GetCmdArg(1, s_ignoreMode, sizeof(s_ignoreMode));
            GetCmdArg(2, s_playerName, sizeof(s_playerName));

            Quasar_IgnoreType ignoreType = QSR_StringToIgnoreType(s_ignoreMode);

            if (ignoreType == IgnoreType_Voice && !gH_CVR_allowIgnoreVoice.BoolValue)
            {
                QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreVoiceDisabled",
                                                gST_chatFormatStrings.s_errorColor);
                return Plugin_Handled;
            }
            else if (ignoreType == IgnoreType_Chat && !gH_CVR_allowIgnoreChat.BoolValue)
            {
                QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreChatDisabled",
                                                gST_chatFormatStrings.s_errorColor);
                return Plugin_Handled;
            }

            if (ProcessTargetString(s_playerName,
                                    0,
                                    i_targetClient,
                                    2,
                                    COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_MULTI,
                                    s_playerName,
                                    sizeof(s_playerName),
                                    tn_is_ml) <= COMMAND_TARGET_NONE)
            {
                QSR_PrintToChat(i_userId, "%t", "QSR_InvalidTarget",
                                                gST_chatFormatStrings.s_errorColor,
                                                s_playerName);
                return Plugin_Handled;
            }

            if (GetUserAdmin(i_targetClient[0]) != INVALID_ADMIN_ID &&
                !gH_CVR_allowIgnoreAdmin.BoolValue)
            {
                QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreIgnoreAdmin",
                                                gST_chatFormatStrings.s_errorColor);
                return Plugin_Handled;
            }

            if (i_targetClient[0] == client)
            {
                QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreIgnoreSelf",
                                                gST_chatFormatStrings.s_errorColor);
                return Plugin_Handled;
            }

            i_targetUserId = GetClientUserId(i_targetClient[0]);
            if (ignoreType == IgnoreType_Voice)
            {
                if (Internal_ClientHasIgnored(i_userId, i_targetUserId, IgnoreType_Voice))
                {
                    Internal_SetClientIgnore(i_userId, i_targetUserId, IgnoreType_Voice, false);
                    QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreStatusChangedUnignored",
                                                    gST_chatFormatStrings.s_actionColor,
                                                    gST_chatFormatStrings.s_successColor,
                                                    gST_chatFormatStrings.s_defaultColor,
                                                    gST_chatFormatStrings.s_actionColor,
                                                    "QSR_IgnoreVoiceChat");
                }
                else
                {
                    Internal_SetClientIgnore(i_userId, i_targetUserId, IgnoreType_Voice, true);
                    QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreStatusChangedIgnored",
                                                    gST_chatFormatStrings.s_actionColor,
                                                    gST_chatFormatStrings.s_errorColor,
                                                    gST_chatFormatStrings.s_defaultColor,
                                                    gST_chatFormatStrings.s_actionColor,
                                                    "QSR_IgnoreVoiceChat");
                }
            }
            else
            {
                if (Internal_ClientHasIgnored(i_userId, GetClientUserId(i_targetClient[0]), IgnoreType_Chat))
                {
                    Internal_SetClientIgnore(i_userId, i_targetUserId, IgnoreType_Chat, false);
                    QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreStatusChangedUnignored",
                                                    gST_chatFormatStrings.s_actionColor,
                                                    gST_chatFormatStrings.s_successColor,
                                                    gST_chatFormatStrings.s_defaultColor,
                                                    gST_chatFormatStrings.s_actionColor,
                                                    "QSR_IgnoreTextChat");
                }
                else
                {
                    Internal_SetClientIgnore(i_userId, i_targetUserId, IgnoreType_Chat, true);
                    QSR_PrintToChat(i_userId, "%t", "QSR_IgnoreStatusChangedIgnored",
                                                    gST_chatFormatStrings.s_actionColor,
                                                    gST_chatFormatStrings.s_errorColor,
                                                    gST_chatFormatStrings.s_defaultColor,
                                                    gST_chatFormatStrings.s_actionColor,
                                                    "QSR_IgnoreTextChat");
                }
            }
        }

        default:
            QSR_IgnoreBuildPage1(i_userId);
    }

    return Plugin_Handled;
}

public Action ADM_ForceIgnore(int client, int args)
{
    return Plugin_Handled;
}
