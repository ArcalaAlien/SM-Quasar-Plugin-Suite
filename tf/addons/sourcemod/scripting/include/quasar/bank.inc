#if defined _quasar_bank_included
	#endinput
#endif
#define _quasar_bank_included

#include <quasar/structs/bank>
#undef   MODULE_NAME
#define  MODULE_NAME "Bank"
#define TRIGGER_MODEL "error.mdl"

public SharedPlugin __pl_quasarbank =
{
    name="quasar_bank",
    file="quasar_bank.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarbank_SetNTVOptional()
{
    MarkNativeAsOptional("QSR_CreateCreditPickup");
    MarkNativeAsOptional("QSR_DonateCredits");
}

/**
 *  Donates credits between two players
 *
 *  @param donator      The userid of the donator.
 *  @param donatee      The userid of the donatee.
 *  @param amount       The amount to send between players.
 */
native void QSR_DonateCredits(int donator, int donatee, int amount);

/**
 *  Creates a credit drop at a player's location for the amount given.
 *  Players can use their credits to create a drop at their location
 *  that other players can then "collect" to gain those credits.
 *
 *  These drops have a configurable time limit, after which they'll
 *  disappear and the player will regain the credits they put in.
 *
 *  If a player leaves while they have a credit drop out, the plugin
 *  will automatically refund the player what they dropped, and also
 *  clean up the pickup.
 *
 *  @param  userid          The userid of the owner of the credit pickup.
 *  @param  creditAmount    The amount of credits that you get from grabbing this.
 */
native void QSR_CreateCreditPickup(int userid, int creditAmount);
