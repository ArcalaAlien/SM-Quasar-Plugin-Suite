#include <quasar/structs/misc>

public SharedPlugin __pl_quasarmisc =
{
    name="quasar_misc",
    file="quasar_misc.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarmisc_SetNTVOptional()
{
    MarkNativeAsOptional("QSR_UsingMiscModule");
    MarkNativeAsOptional("QSR_SpawnBreadAtPlayer");
    MarkNativeAsOptional("QSR_PlayerEnabledSP");
    MarkNativeAsOptional("QSR_IsPlayerProtected");
    MarkNativeAsOptional("QSR_ToggleSpawnProtection");
    MarkNativeAsOptional("QSR_GrantSpawnProtection");
    MarkNativeAsOptional("QSR_RemoveSpawnProtection");
    MarkNativeAsOptional("QSR_GetPlayerCustRespawnTime");
    MarkNativeAsOptional("QSR_SetPlayerCustRespawnTime");
    MarkNativeAsOptional("QSR_GetRespawnTimeLeft");
    MarkNativeAsOptional("QSR_IsPlayerRespawning");
    MarkNativeAsOptional("QSR_ForcePlayerRespawn");
    MarkNativeAsOptional("QSR_GetPlayerPOV");
    MarkNativeAsOptional("QSR_SetPlayerPOV");
    MarkNativeAsOptional("QSR_IsPlayerFriendly");
    MarkNativeAsOptional("QSR_SetPlayerFriendlyState");
}

//** NATIVES */

////////////////////////
//      GENERAL       //
////////////////////////

/**
 * 
 */
native bool QSR_UsingMiscModule(QSRMiscModuleType module);

////////////////////////
//       BREAD        //
////////////////////////

/**
 * 
 */
native bool QSR_SpawnBreadAtPlayer(int userid, QSRBreadModel model=BreadModel_Random);

////////////////////////
//  SPAWN PROTECTION  //
////////////////////////

/**
 * 
 */
native bool QSR_PlayerEnabledSP(int userid);

/**
 * 
 */
native bool QSR_IsPlayerProtected(int userid);

/**
 * 
 */
native void QSR_ToggleSpawnProtection(int userid, int enabled=-1);

/**
 * 
 */
native void QSR_GrantSpawnProtection(int userid);

/**
 * 
 */
native void QSR_RemoveSpawnProtection(int userid);

////////////////////////
//   RESPAWN TIME     //
////////////////////////

/**
 * 
 */
native bool QSR_PlayerHasCRespawnTime(int userid);

/**
 * 
 */
native float QSR_GetPlayerCRespawnTime(int userid);

/**
 * 
 */
native void QSR_SetPlayerCRespawnTime(int userid, float time);

/**
 * 
 */
native float QSR_GetRespawnTimeLeft(int userid);

/**
 * 
 */
native bool QSR_IsPlayerRespawning(int userid);

/**
 * 
 */
native void QSR_ForcePlayerRespawn(int userid);

////////////////////////
//    THIRD PERSON    //
////////////////////////

/**
 * 
 */
native QSRPov QSR_GetPlayerPOV(int userid);

/**
 * 
 */
native void QSR_SetPlayerPOV(int userid, QSRPov pov);

////////////////////////
//   FIELD OF VIEW    //
////////////////////////

/**
 * 
 */
native int QSR_GetPlayerFOV(int userid)

/**
 * 
 */
native void QSR_SetPlayerFOV(int userid);

////////////////////////
//      FRIENDLY      //
////////////////////////

/**
 *  Returns whether a player is friendly or not.
 * 
 *  @param userid       The userid of the player who we want to check.
 *  @return             True if friendly, false if not.
 */
native bool QSR_IsPlayerFriendly(int userid);

/**
 * 
 */
native void QSR_SetPlayerFriendlyState(int userid, bool state);

//** FORWARDS */

////////////////////////
//       BREAD        //
////////////////////////

/**
 * 
 */
forward Action QSR_OnBreadSpawned_Pre(QSRBreadEntity &bread);

/**
 * 
 */
forward void QSR_OnBreadSpawned(QSRBreadEntity bread);

////////////////////////
//  SPAWN PROTECTION  //
////////////////////////

/**
 * 
 */
forward void QSR_OnProtectedPlayerHurt(int victim, int attacker, int damageAttempted);

/**
 * 
 */
forward void QSR_OnPlayerToggleSP(int userid, bool oldState, bool newState);

/**
 * 
 */
forward Action QSR_OnPlayerGrantedSP_Pre(int userid);

/**
 * 
 */
forward void QSR_OnPlayerGrantedSP(int userid);

/**
 * 
 */
forward Action QSR_OnPlayerLoseSP_Pre(int userid);

/**
 * 
 */
forward void QSR_OnPlayerLoseSP(int userid);

////////////////////////
//   RESPAWN TIME     //
////////////////////////

/**
 * 
 */
forward void QSR_OnChangedRespawnTime(int userid, float oldTime, float newTime);

/**
 * 
 */
forward Action QSR_OnPlayerWaitForRespawn(int userid, int team, float &respawnTime);

/**
 * 
 */
forward void QSR_OnPlayerRespawned(int userid, int team);

////////////////////////
//    THIRD PERSON    //
////////////////////////

/**
 * 
 */
forward void QSR_OnPlayerChangePOV(int userid, QSRPov oldPov, QSRPov newPov);

////////////////////////
//   FIELD OF VIEW    //
////////////////////////

/**
 * 
 */
forward void QSR_OnPlayerChangeFOV(int userid, QSRPov oldPov, QSRPov newPov);

////////////////////////
//      FRIENDLY      //
////////////////////////

/**
 * 
 */
forward void QSR_OnChangedFriendlyState(int userid, bool oldState, bool newState);

/**
 * 
 */
forward void QSR_OnFriendlyPlayerHurt(int victim, int attacker, int damageAttempted);

//* STOCKS */

////////////////////////
//       BREAD        //
////////////////////////

stock void QSR_BreadEnumToModel(QSRBreadModel model, char[] buffer, int len)
{
    switch (model)
    {
        case BreadModel_Baguette:       { strcopy(buffer, len, BREADMDL_BAGUETTE); }
        case BreadModel_Burnt:          { strcopy(buffer, len, BREADMDL_BURNT); }
        case BreadModel_Cinnamon:       { strcopy(buffer, len, BREADMDL_CINNAMON); }
        case BreadModel_Cornbread:      { strcopy(buffer, len, BREADMDL_CORNBREAD); }
        case BreadModel_Crumpet:        { strcopy(buffer, len, BREADMDL_CRUMPET); }
        case BreadModel_PlainLoaf:      { strcopy(buffer, len, BREADMDL_PLAINLOAF); }
        case BreadModel_Pretzel:        { strcopy(buffer, len, BREADMDL_PRETZEL); }
        case BreadModel_Ration:         { strcopy(buffer, len, BREADMDL_RATION); }
        case BreadModel_RussianBlack:   { strcopy(buffer, len, BREADMDL_RUSSIANBLACK); }
        default:
        {
            QSRBreadModel e_RandomBread = view_as<QSRBreadModel>(GetRandomInt(1, 9));
            QSR_BreadEnumToModel(e_RandomBread, buffer, len);
        }
    }
}