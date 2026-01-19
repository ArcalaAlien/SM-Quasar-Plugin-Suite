#if defined _quasar_core_included
	#endinput
#endif
#define _quasar_core_included

#define CHECK_SERVER_INFO_URL "https://api.steampowered.com/IGameServersService/GetServerList/v1/"
#define CHECK_GAME_UPDATE_URL "https://api.steampowered.com/ISteamApps/UpToDateCheck/v1/"
#define EMPTY_STRING ""

#define PLUGIN_AUTHOR   "ArcalaAlien"
#define PLUGIN_VERSION  "0.1.0"
#define PLUGIN_URL      "https://github.com/ArcalaAlien/SourceMod-QuasarPluginSuite"

#define MODULE_NAME     "Core"

#define SERVER 0

#include <quasar/structs/color>
#include <regex>

public SharedPlugin __pl_quasarcore =
{
    name="quasar_core",
    file="quasar_core.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarcore_SetNTVOptional()
{
    MarkNativeAsOptional("QSR_GetSQLSettings");
    MarkNativeAsOptional("QSR_GetSystemFormatting");
    MarkNativeAsOptional("QSR_PrintToChat");
    MarkNativeAsOptional("QSR_PrintToChatAll");
    MarkNativeAsOptional("QSR_PrintCenterTextEx");
    MarkNativeAsOptional("QSR_PrintCenterTextAllEx");
    MarkNativeAsOptional("QSR_NotifyUser");
}

/*           */
/* CONSTANTS */
/*           */
methodmap DBStatementX < DBStatement
{
    public bool Execute()
    {
        return SQL_Execute(this);
    }
}

enum struct QSRChatFormat
{
    char s_prefix[64];
    char s_defaultColor[32];
    char s_successColor[32];
    char s_errorColor[32];
    char s_warnColor[32];
    char s_actionColor[32];
    char s_infoColor[32];
    char s_commandColor[32];
    char s_creditColor[32];

    void Empty()
    {
        this.s_prefix       = EMPTY_STRING;
        this.s_defaultColor = EMPTY_STRING;
        this.s_successColor = EMPTY_STRING;
        this.s_errorColor   = EMPTY_STRING;
        this.s_warnColor    = EMPTY_STRING;
        this.s_actionColor  = EMPTY_STRING;
        this.s_infoColor    = EMPTY_STRING;
        this.s_commandColor = EMPTY_STRING;
        this.s_creditColor  = EMPTY_STRING;
    }
}

enum struct QSRGeneralSounds
{
    char s_errorSound[256];
    char s_loginSound[256];
    char s_addCreditsSound[256];
    char s_afkWarnSound[256];
    char s_afkMoveSound[256];
    char s_buyItemSound[256];
    char s_infoSound[256];

    void Empty()
    {
        this.s_errorSound       = EMPTY_STRING;
        this.s_loginSound       = EMPTY_STRING;
        this.s_addCreditsSound  = EMPTY_STRING;
        this.s_afkWarnSound     = EMPTY_STRING;
        this.s_afkMoveSound     = EMPTY_STRING;
        this.s_buyItemSound     = EMPTY_STRING;
        this.s_infoSound        = EMPTY_STRING;
    }
}

/*         */
/* NATIVES */
/*         */


/**
 *  Automatically appends the quasar prefix to a message to send to a valid client
 *
 *  @param userid       The client userid to send the message to.
 *  @param message      The message to log.
 *  @param ...          Paramaters for formatting.
 *
 *  @return             true if we printed to client, false otherwise.
 */
native bool QSR_PrintToChat(int userid, const char[] message, any ...);

/**
 *  Automatically appends the quasar prefix to a message to send to all valid clients
 *
 *  @param mesage       The message to send
 *  @param ...          Paramaters for formatting.
 */
native void QSR_PrintToChatAll(const char[] message, any ...);

/**
 *  A wrapper for QSR_PrintCenterText that includes functionality from SetHudTextParams()
 *
 *  @param userid           The userid of the player we're sending the message to.
 *  @param pos              [0] = x, [1] = y, the coordinates to display the text on screen at. See SetHudTextParams() for more details.
 *  @param holdTime         The amount of time to keep the text on screen.
 *  @param color1           The color + alpha of the text we'll send to the client.
 *  @param color2           Optional color as some effects use two.
 *  @param effect           Sets an effect on the text. See SetHudTextParams() for more details.
 *  @param effectSettings   A set of 3 floats that correspond to paramaters in SetHudTextParams(). [0] = fxTime, [1] = fadeIn, [2] = fadeOut
 */
native bool QSR_PrintCenterTextEx(int userid, float pos[2], float holdTime, int color1[4], int color2[4] = {255, 255, 255, 0}, int effect = 0, float effectSettings[3] = {6.0, 0.1, 0.2}, const char[] message, any ...);

/**
 *  A wrapper for QSR_PrintCenterTextAll that includes functionality from SetHudTextParams()
 *
 *  @param pos              [0] = x, [1] = y, the coordinates to display the text on screen at. See SetHudTextParams() for more details.
 *  @param holdTime         The amount of time to keep the text on screen.
 *  @param color1           The color + alpha of the text we'll send to the client.
 *  @param color2           Optional color as some effects use two.
 *  @param effect           Sets an effect on the text. See SetHudTextParams() for more details.
 *  @param effectSettings   A set of 3 floats that correspond to paramaters in SetHudTextParams(). [0] = fxTime, [1] = fadeIn, [2] = fadeOut
 *
native void QSR_PrintCenterTextAllEx(float pos[2], float holdTime, int color1[4], int color2[4] = {255, 255, 255, 0}, int effect = 0, float effectSettings[3] = {6.0, 0.1, 0.2}, const char[] message, any ...);


/**
 *  Does the same thing as QSR_PrintToChat, but plays a sound along with the message.
 *
 *  @param userid       The client userid to send the message to.
 *  @param sound        The sound to play to the user.
 *  @param message      The message to send to the user.    
 *  @param ...          Paramaters for formatting.
 *
 *  @return             True if we notified the client, false if not.
 */
native bool QSR_NotifyUser(int userid, const char[] sound, const char[] message, any ...);

native void QSR_LogMessage(const char[] module, const char[] message, any ...);

native void QSR_SilentLog(const char[] module, const char[] message, any ...);

native void QSR_ThrowError(const char[] module, const char[] message, any ...);
/*          */
/* FORWARDS */
/*          */

/**
 *  Fires once the core plugin has made the log file.
 *
 *  @param file     A reference to the File handle in the core plugin.
 */
forward void QSR_OnLogFileMade(File& file);

/**
 *  Fires once we get the chat formatting strings from the autoexeconfig.
 *  Each key in the stringmap corresponds to a convar.
 *
 *  @param formatting   A clone of the StringMap with all of the formatting strings.
 */
forward void QSR_OnSystemFormattingRetrieved(StringMap formatting);

/**
 *  Fires once we get the soundfiles from the autoexeconfig.
 *  Each key in the stringmap corresponds to a convar.
 *
 *  @param formatting   A clone of the StringMap with all of the soundfiles.
 */
forward void QSR_OnSystemSoundsRetrieved(StringMap sounds);

/*          */
/*  STOCKS  */
/*          */

/**
 *  Checks to see if a client index is valid.
 *
 *  @param client       client index to check
 *  @return             userid of client if true, 0 if false.
 */
stock int QSR_IsValidClient(int client)
{
    if (client && 
        IsClientInGame(client) && 
        !IsFakeClient(client)) 
        return GetClientUserId(client);

    return 0;
}

/**
 *  Checks to see if a client index is valid and alive.
 *
 *  @param client       client index to check
 *  @return             userid of client if true, 0 if false.
 */
stock int QSR_IsValidClientEX(int client)
{
    int i_userid = QSR_IsValidClient(client);

    if (i_userid &&
        IsPlayerAlive(i_userid))
        return i_userid;

    return 0;
}

/**
 *  Checks if a string is a steam authid, and returns the authid type if it is.
 *
 *  @param string   The string to check
 *  @return         The authid type the string is, or -1 if it's not.
 */
stock AuthIdType QSR_IsStringAuthId(const char[] string)
{
    Regex h_authPattern = new Regex("STEAM_[0-9]:[0-9]:[0-9]{8}");
    if (h_authPattern.Match(string) != -1)
    {
        h_authPattern.Close();
        h_authPattern = null;
        return AuthId_Steam2;
    }

    h_authPattern.Close();
    h_authPattern = new Regex("\\[U:[0-9]:[0-9]{9}\\]");
    if (h_authPattern.Match(string) != -1)
    {
        h_authPattern.Close();
        h_authPattern = null;
        return AuthId_Steam3;
    }

    h_authPattern.Close();
    h_authPattern = new Regex("[0-9]{17}");
    if (h_authPattern.Match(string) != -1)
    {
        h_authPattern.Close();
        h_authPattern = null;
        return AuthId_SteamID64;
    }

    if (h_authPattern != null)
    {
        h_authPattern.Close();
        h_authPattern = null;
    }

    return view_as<AuthIdType>(-1);
}
