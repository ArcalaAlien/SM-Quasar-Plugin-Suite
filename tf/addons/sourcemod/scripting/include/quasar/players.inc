#if defined _quasar_players_included
	#endinput
#endif
#define _quasar_players_included

#include <quasar/structs/player>

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
    MarkNativeAsOptional("QSR_ModPlayerPoints");
    MarkNativeAsOptional("QSR_ModPlayerCredits");
    MarkNativeAsOptional("QSR_GetPlayerPoints");
    MarkNativeAsOptional("QSR_GetPlayerCredits");
    MarkNativeAsOptional("QSR_GetPlaytime");
    MarkNativeAsOptional("QSR_GetFirstLogin");
    MarkNativeAsOptional("QSR_GetLastLogin");
    MarkNativeAsOptional("QSR_IsPlayerFetched");
    MarkNativeAsOptional("QSR_GetAuthID");
    MarkNativeAsOptional("QSR_GetPlayerName");
    MarkNativeAsOptional("QSR_RefreshPlayer");
    MarkNativeAsOptional("QSR_FindPlayerByName");
    MarkNativeAsOptional("QSR_FindPlayerByAuthId");
    MarkNativeAsOptional("QSR_CheckForUpgrade");
    MarkNativeAsOptional("QSR_AddUpgrade");
    MarkNativeAsOptional("QSR_IsPlayerAlive");
}

/*
    NATIVES
*/

/**
 *  Modifies a player's points and updates them in the database.
 *  Supports adding and subtracting points.
 *
 *  @param userid       The userid of the player to add points to
 *  @param points       The amount of points to add or subtract
 *  @param notify       Should we tell thep layer we messed with their points?
 */
native void QSR_ModPlayerPoints(int userid, float points, bool notify=true);

/**
 *  Modifies a player's credits and updates them in the database.
 *  Supports adding and subtracting credits.
 *
 *  @param userid       The userid of the player to add points to
 *  @param credits      The amount of credits to add or subtract
 *  @param notify       Should we tell the player we messed with their credits?
 */
native void QSR_ModPlayerCredits(int userid, int credits, bool notify=true);

/**
 *  Retrieves a player's points.
 *
 *  @param userid       The userid of the player whose points we want.
 *  @return             The player's points, or -1 if the player is invalid.
 */
native float QSR_GetPlayerPoints(int userid);

/**
 *  Retrieves a player's credits.
 *
 *  @param userid       The userid of the player whose credits we want.
 *  @return             The player's credits, or -1 if the player is invalid.
 */
native int QSR_GetPlayerCredits(int userid);

/**
 *  Retrieves a player's playtime.
 *
 *  @param userid       The userid of the player whose playtime we want.
 *  @return             The player's playtime, or -1 if the player is invalid.
 */
native int QSR_GetPlaytime(int userid);

/**
 *  Retrieves a player's first login.
 *
 *  @param userid       The userid of the player whose first login to the server we want.
 *  @return             The player's first login time, or -1 if the player is invalid.
 */
native int QSR_GetFirstLogin(int userid);

/**
 *  Retrieves a player's last login.
 *
 *  @param userid       The userid of the player whose last login we want.
 *  @return             The player's last login time, or -1 if the player is invalid.
 */
native int QSR_GetLastLogin(int userid);

/**
 *  Returns whether player info was sucessfully retrieved from the database.
 *
 *  @param userid       The userid of the player who we want to check.
 *  @return             True if fetched, false if not.
 */
native bool QSR_IsPlayerFetched(int userid);

/**
 *  Checks a player to see if they have a specific server upgrade.
 *
 *  @param userid       The userid of the player we're checking
 *  @param upgrade      The upgrade we're checking for.
 *
 *  @return             True if the player has the upgrade, false if the player doesn't or is invalid.
 */
native bool QSR_CheckForUpgrade(int userid, QSRUpgradeType upgrade);


/**
 *  Adds an upgrade to a player.
 *
 *  @param userid       The userid of the player we're adding an upgrade to
 *  @param upgrade      The upgrade that we're adding to the player.
 */
native void QSR_AddUpgrade(int userid, QSRUpgradeType upgrade);

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
 *  Is a player alive and on a team?
 *
 *  @param userid       The userid of the client we're checking.
 *
 *  @return             true if player is alive and on a team, false otherwise.
 */
native bool QSR_IsPlayerAlive(int userid);
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

/**
 *  Fires whenever a players points have changed.
 *
 *  @param userid       The userid of the player whos points have changed.
 *  @param amtGiven     The amount of points given to (or taken from) the player.
 *  @param newTotal     The new amount of points a player has.
 *  @param notify       Should we notify the player that their points have changed?
 */
forward void QSR_OnPointsChanged(int userid, float amtGiven, float oldTotal, float newTotal, bool notify);

/*
    STOCKS
*/
stock QSRUpgradeType QSR_ItemIdToUpgradeType(const char[] itemid)
{
    // This really sucks, but itemids have repeating characters in pretty much each place.
    // TODO: Find a better way of doing this
    if      (StrEqual(itemid, "ugd_ccht"))      { return QSRUpgrade_ColoredChat; }
    else if (StrEqual(itemid, "ugd_clr_rblx"))  { return QSRUpgrade_RblxPalette; }
    else if (StrEqual(itemid, "ugd_cnme"))      { return QSRUpgrade_ColoredName; }
    else if (StrEqual(itemid, "ugd_cfmt"))      { return QSRUpgrade_ChatFormatting; }
    else if (StrEqual(itemid, "ugd_csnd"))      { return QSRUpgrade_JoinLeaveSounds; }
    else if (StrEqual(itemid, "ugd_dsnd"))      { return QSRUpgrade_DeathSound; }
    else if (StrEqual(itemid, "ugd_rank"))      { return QSRUpgrade_RankTag; }
    else if (StrEqual(itemid, "ugd_spcs"))      { return QSRUpgrade_SpectatorSound; }
    else if (StrEqual(itemid, "ugd_uwep"))      { return QSRUpgrade_UnusualWeapons; }
    else if (StrEqual(itemid, "ugd_ucos"))      { return QSRUpgrade_UnusualCosmetics; }
    else if (StrEqual(itemid, "ugd_utnt"))      { return QSRUpgrade_UnusualTaunts; }
    else if (StrEqual(itemid, "ugd_ncld"))      { return QSRUpgrade_NoSoundCooldown; }
    else if (StrEqual(itemid, "ugd_dt_cdt"))    { return QSRUpgrade_DonateCredits; }
    else if (StrEqual(itemid, "ugd_dp_cdt"))    { return QSRUpgrade_DropCredits; }
    else if (StrEqual(itemid, "ugd_cclr"))      { return QSRUpgrade_CustomCosmeticColors; }

    return QSRUpgrade_None;
}

stock void QSR_UpgradeTypeToItemId(QSRUpgradeType upgrade, char[] buffer, int maxlen)
{
    switch (upgrade)
    {
        case QSRUpgrade_ChatFormatting:         { FormatEx(buffer, maxlen, "ugd_cfmt"); }
        case QSRUpgrade_ColoredChat:            { FormatEx(buffer, maxlen, "ugd_ccht"); }
        case QSRUpgrade_ColoredName:            { FormatEx(buffer, maxlen, "ugd_cnme"); }
        case QSRUpgrade_CustomCosmeticColors:   { FormatEx(buffer, maxlen, "ugd_cclr"); }
        case QSRUpgrade_DeathSound:             { FormatEx(buffer, maxlen, "ugd_dsnd"); }
        case QSRUpgrade_DonateCredits:          { FormatEx(buffer, maxlen, "ugd_dt_cdt"); }
        case QSRUpgrade_DropCredits:            { FormatEx(buffer, maxlen, "ugd_dp_cdt"); }
        case QSRUpgrade_JoinLeaveSounds:        { FormatEx(buffer, maxlen, "ugd_csnd"); }
        case QSRUpgrade_NoSoundCooldown:        { FormatEx(buffer, maxlen, "ugd_ncld"); }
        case QSRUpgrade_RankTag:                { FormatEx(buffer, maxlen, "ugd_rank"); }
        case QSRUpgrade_RblxPalette:            { FormatEx(buffer, maxlen, "ugd_clr_rblx"); }
        case QSRUpgrade_SpectatorSound:         { FormatEx(buffer, maxlen, "ugd_spcs"); }
        case QSRUpgrade_UnusualCosmetics:       { FormatEx(buffer, maxlen, "ugd_ucos"); }
        case QSRUpgrade_UnusualTaunts:          { FormatEx(buffer, maxlen, "ugd_utnt"); }
        case QSRUpgrade_UnusualWeapons:         { FormatEx(buffer, maxlen, "ugd_uwep"); }
    }
}

stock int QSR_UpgradeTypeToFlag(QSRUpgradeType upgrade)
{
    switch (upgrade)
    {
        case QSRUpgrade_ChatFormatting:         { return UPGRADE_CHATFORMAT; }
        case QSRUpgrade_ColoredChat:            { return UPGRADE_CHATCOLOR; }
        case QSRUpgrade_ColoredName:            { return UPGRADE_NAMECOLOR; }
        case QSRUpgrade_CustomCosmeticColors:   { return UPGRADE_CUSTOM_PAINT; }
        case QSRUpgrade_DeathSound:             { return UPGRADE_DEATH_SOUNDS; }
        case QSRUpgrade_DonateCredits:          { return UPGRADE_DONATECREDITS; }
        case QSRUpgrade_DropCredits:            { return UPGRADE_DROPCREDITS; }
        case QSRUpgrade_JoinLeaveSounds:        { return UPGRADE_JOINLEAVE_SOUNDS; }
        case QSRUpgrade_NoSoundCooldown:        { return UPGRADE_NO_SOUND_COOLDOWN; }
        case QSRUpgrade_RankTag:                { return UPGRADE_RANKTAG; }
        case QSRUpgrade_RblxPalette:            { return UPGRADE_RBLXPALLETTE; }
        case QSRUpgrade_SpectatorSound:         { return UPGRADE_INSPEC_SOUNDS; }
        case QSRUpgrade_UnusualCosmetics:       { return UPGRADE_UNUSCOSMETICS; }
        case QSRUpgrade_UnusualTaunts:          { return UPGRADE_UNUSTAUNTS; }
        case QSRUpgrade_UnusualWeapons:         { return UPGRADE_UNUSWEAPON; }
    }

    return -1;
}
