#if defined _quasar_scoreboard_included
	#endinput
#endif
#define _quasar_scoreboard_included

#include <quasar/structs/scoreboard>

public SharedPlugin __pl_quasarscoreboard =
{
    name="quasar_scoreboard",
    file="quasar_scoreboard.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarscoreboard_SetNTVOptional()
{

}

// Natives


// Forwards
/**
 *
 */
forward void QSR_OnNewMostDamageTaken(int userid, int oldDamage, int newDamage);

/**
 *
 */
forward void QSR_OnNewMostDamageDone(int userid, int oldDamage, int newDamage);

/**
 *
 */
forward void QSR_OnPlayerSuicide(int victim);

/**
 *
 */
forward void QSR_OnPlayerAssistedSuicide(int victim, int assister);

/**
 *
 */
forward void QSR_OnPlayerLostKillStreak(int userid, int killstreak, float multiplier);

/**
 *
 */
forward void QSR_OnPlayerKillstreakChanged(int userid, int killstreak, float multiplier);

/**
 *
 */
forward Action QSR_OnPlayerKilledAFK_Pre(int attacker, int victim, int &creditsOnKill, int &creditsOnAssist, int &creditsOnDeath, float &pointsOnKill, float &pointsOnAssist, float &pointsOnDeath);

/**
 *
 */
forward Action QSR_OnPlayerKilled_Pre(int attacker, int victim);

/**
 *
 */
forward Action QSR_OnPlayerKilled(int attacker, int victim);
