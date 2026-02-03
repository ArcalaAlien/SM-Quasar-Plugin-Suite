#if defined _quasar_players_included
	#endinput
#endif
#define _quasar_players_included

#undef   MODULE_NAME
#define  MODULE_NAME "Player"

#include <quasar/structs/player>

#define MAX_LOGIN_ATTEMPTS          5
#define MAX_FETCH_INFO_ATTEMPTS     5
#define RETRY_DELAY                 5.0
#define FETCH_DELAY                 0.1
#define AUTH_DELAY                  2.0

public SharedPlugin __pl_quasarplayers =
{
    name="quasar_players",
    file="quasar_players.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarplayers_SetNTVOptional()
{
    MarkNativeAsOptional("QSR_ModPlayerCredits");
    MarkNativeAsOptional("QSR_GetPlayerCredits");
    MarkNativeAsOptional("QSR_IsPlayerFetched");
    MarkNativeAsOptional("QSR_GetAuthID");
    MarkNativeAsOptional("QSR_GetPlayerName");
    MarkNativeAsOptional("QSR_RefreshPlayer");
    MarkNativeAsOptional("QSR_FindPlayerByName");
    MarkNativeAsOptional("QSR_FindPlayerByAuthId");
    MarkNativeAsOptional("QSR_IsTFPlayerAlive");
}

/*
    NATIVES
*/
/**
 *  Modifies a player's credits and updates them in the database.
 *  Only supports adding and subtracting credits.
 *
 *  @param userid       The userid of the player to add points to
 *  @param credits      The amount of credits to add or subtract
 *  @param notify       Should we tell the player we messed with their credits?
 */
native void QSR_ModPlayerCredits(int userid, int credits, bool notify=true);

/**
 *  Retrieves a player's credits.
 *
 *  @param userid       The userid of the player whose credits we want.
 *  @return             The player's credits, or -1 if the player is invalid.
 */
native int QSR_GetPlayerCredits(int userid);

/**
 *  Returns whether player info was sucessfully retrieved from the database.
 *
 *  @param userid       The userid of the player who we want to check.
 *  @return             True if fetched, false if not.
 */
native bool QSR_IsPlayerFetched(int userid);



/**
 *  Returns the player's steam ID
 *
 *  @param userid       The userid of the player who's AuthId we want to get.
 *  @param authType     The type of AuthId we want to get.
 *  @param buffer       A buffer to store the AuthId
 *  @param maxlen       The size of the buffer to store the AuthId.
 *
 *  @return             True if we retrieved the player's AuthId, false if not.
 */
native bool QSR_GetAuthId(int userid, AuthIdType authType, char[] buffer, int maxlen);

/**
 *  Returns the player's Name
 *
 *  @param userid       The userid of the player who's name we want.
 *  @param buffer       A buffer to store the player's name.
 *  @param maxlen       The size of the buffer to store the name.
 *
 *  @return             True if we retrieved the player's name, false if not.
 */
native bool QSR_GetPlayerName(int userid, char[] buffer, int maxlen);

/**
 *  Attempts to get player's authids, name, and server info again.
 *
 *  @param userid       The player to refresh
 */
native void QSR_RefreshPlayer(int userid);

/**
 *  Attempts to find a player in game by name
 *
 *  @param name         The name of the player to attempt to find.
 *  @return             The userid of the player, or -1 if no matches
 */
native int QSR_FindPlayerByName(const char[] name)


/**
 *  Attempts to find a player in game by auth id.
 *
 *  @param authType     The type of authid we're user.
 *  @param auth         The authid to search with.
 *
 *  @return             The userid of the player, or -1 if no matches.
 */
native int QSR_FindPlayerByAuthId(AuthIdType authType, const char[] auth);

/**
 *  Is a player alive and on a TFteam?
 *
 *  @param userid       The userid of the client we're checking.
 *
 *  @return             true if player is alive and on a team, false otherwise.
 */
native bool QSR_IsTFPlayerAlive(int userid);

/*
    FORWARDS
*/

/**
 *  Fires once we've successfully grabbed a player's steam auth
 *
 *  @param client       The client index of the user
 *  @param steam2_id    Their steam2 id EG. STEAM:XX:XXXXXX
 *  @param steam3_id    Their steam3 id EG. [U:X:XXXXXXX]
 *  @param steam64_id   Their steam64 id EG. 12345678901234...
 */
forward void QSR_OnClientAuthRetrieved(int client, char[] steam2_id, char[] steam3_id, char[] steam64_id);

/**
 *  Fires once we've successfully grabbed a player's info from the db.
 *
 *  @param userid       The userid of the player we fetched.
 *  @param client       The client index of the player we fetched.
 */
forward void QSR_OnPlayerInfoFetched(int userid, int client);

/**
 *  Fires whenever a players credits have changed.
 *
 *  @param userid       The userid of the player whos credits have changed.
 *  @param amtGiven     The amount of credits given to (or taken from) the player.
 *  @param newTotal     The new amount of credits a player has.
 *  @param notify       Should we notify the player that their credits have changed?
 */
forward void QSR_OnCreditsChanged(int userid, int amtGiven, int oldTotal, int newTotal, bool notify);