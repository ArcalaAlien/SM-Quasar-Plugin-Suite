#if defined _quasar_afk_included
	#endinput
#endif
#define _quasar_afk_included

#include <quasar/structs/afk>

public SharedPlugin __pl_quasarafk =
{
    name="quasar_afk",
    file="quasar_afk.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarafk_SetNTVOptional()
{
}

/**
 *  Returns whether a player is AFK or not.
 *
 *  @param userid       The userid of the player who we want to check.
 *  @return             True if afk, false if not.
 */
native bool QSR_IsPlayerAFK(int userid);

/**
 *  Allows you to set whether a player is AFK or not.
 *
 *  @param userid       The userid of the player we want to change the AFK status for.
 *  @param status       Whether a player will be AFK or not.
 *
 *  @return             True if we changed the player's AFK status, false if not.
 */
native bool QSR_SetPlayerAFK(int userid, bool status);

/**
 *  Retrieves the amount of time a player has been AFK for.
 *
 *  @param userid       The userid of the player whose current time spent AFK we want.
 *  @return             The amount of time currently spent AFK, or -1 if the player is invalid.
 */
native int QSR_GetTimeAFK(int userid);

/**
 *  Retrieves the total amount of time a player has been AFK for.
 *
 *  @param userid       The userid of the player whose total time AFK we want.
 *  @return             The total time spent AFK, or -1 if the player is invalid.
 */
native int QSR_GetTotalTimeAFK(int userid);
