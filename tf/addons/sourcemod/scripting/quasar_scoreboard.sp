#include <sourcemod>
#include <sdktools>

#include <quasar/core>
#include <quasar/players>
#include <quasar/scoreboard>
#undef  MODULE_NAME
#define MODULE_NAME "Scoreboard"

#include <autoexecconfig>

// General
QSRStatInfo       gST_scores[MAXPLAYERS + 1];
QSRChatFormat     gST_chatFormatting;
QSRGeneralSounds  gST_sounds;
Database          gH_db = null
File              gH_logFile = null;
char              gS_subdomain[32];

// Forwards
Handle gH_FWD_onNewMostDamageTaken;
Handle gH_FWD_onNewMostDamageDone;

// ConVars
ConVar gH_CVR_subdomain         = null;
ConVar gH_CVR_useAFKSystem      = null;
ConVar gH_CVR_pointsOnKill      = null;
ConVar gH_CVR_pointsOnAssist    = null;
ConVar gH_CVR_pointsOnDeath     = null;
ConVar gH_CVR_creditsOnKill     = null;
ConVar gH_CVR_creditsOnAssist   = null;
ConVar gH_CVR_creditsOnDeath    = null;
ConVar gH_CVR_awardPointsNoSP   = null;
ConVar gH_CVR_awardCreditsNoSP  = null;
ConVar gH_CVR_pointModNoSP      = null;
ConVar gH_CVR_creditModNoSP     = null;
ConVar gH_CVR_killstreakModulo  = null;

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Scoreboard Handler)",
    author = PLUGIN_AUTHOR,
    description = "Description",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public void OnPluginStart()
{
    // Register ConVars
    AutoExecConfig_SetFile("plugin.quasar_scoreboard");

    gH_CVR_useAFKSystem     = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_use_afk",               "1",    "Use the quasar AFK system");
    gH_CVR_pointsOnKill     = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_points_on_kill",        "15.0", "The amount of points to award to a player when they kill someone.");
    gH_CVR_pointsOnAssist   = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_points_on_assist",      "7.5",  "The amount of points to award to a player when they help kill someone.");
    gH_CVR_pointsOnDeath    = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_points_on_death",       "-1.0", "The amount of points to award (or remove) from a player when they die.");
    gH_CVR_creditsOnKill    = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_credits_on_kill",       "2",    "The amount of credits to award to a player when they kill someone.");
    gH_CVR_creditsOnAssist  = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_credits_on_assist",     "1",    "The amount of credits to award to a player when they help kill someone.");
    gH_CVR_creditsOnDeath   = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_credits_on_death",      "0",    "The amount of credits to award (or remove) from a player when they die.");
    gH_CVR_awardPointsNoSP  = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_award_points_nosp",     "1",    "Will we award points when theres no spawn protection?")
    gH_CVR_awardCreditsNoSP = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_award_credits_nosp",    "1",    "Will we award credits when there's no spawn protection?")
    gH_CVR_pointModNoSP     = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_pointmod_nosp",         "0.1",  "How much will we scale the points when there's no spawn protection?");
    gH_CVR_creditModNoSP    = AutoExecConfig_CreateConVar("sm_quasar_scoreboard_creditmod_nosp",        "0",    "How much will we scale the credits when there's no spawn protection? (int only)");


    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    // Register Forwards
    gH_FWD_onNewMostDamageTaken = CreateGlobalForward("QSR_OnNewMostDamageTaken", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    gH_FWD_onNewMostDamageDone = CreateGlobalForward("QSR_OnNewMostDamageDone", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

    // Register Commands
    RegConsoleCmd("sm_stats", CMD_StatsMenu, "Use this to open the stats menu!");
    RegConsoleCmd("sm_stat", CMD_StatsMenu, "Use this to open the stats menu!");
    RegConsoleCmd("sm_rank", CMD_StatsMenu, "Use this to open the stats menu!");
    RegConsoleCmd("sm_ranks", CMD_StatsMenu, "Use this to open the stats menu!");
    RegAdminCmd("sm_modpoints", CMD_ModPoints, ADMFLAG_BAN, "Use this to add or remove points from a player.");

    // Load Translations
    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    LoadTranslations("quasar_core.phrases");
    LoadTranslations("quasar_players.phrases");
    LoadTranslations("quasar_scoreboard.phrases");

    // Hook Events
    HookEventEx("player_hurt", Event_OnPlayerHurt);
    HookEventEx("player_death", Event_OnPlayerDeath);
}

public void OnPluginEnd()
{
    gH_CVR_awardCreditsNoSP.Close();
    gH_CVR_awardPointsNoSP.Close();
    gH_CVR_creditModNoSP.Close();
    gH_CVR_creditsOnAssist.Close();
    gH_CVR_creditsOnDeath.Close();
    gH_CVR_creditsOnKill.Close();
    gH_CVR_pointModNoSP.Close();
    gH_CVR_pointsOnAssist.Close();
    gH_CVR_pointsOnDeath.Close();
    gH_CVR_pointsOnKill.Close();
    gH_CVR_useAFKSystem.Close();
}

public void OnClientPostAdminCheck(int client)
{
    gST_scores[client].Reset();
}

public void OnClientDisconnect_Post(int client)
{
    gST_scores[client].Reset();
}

public void OnConfigsExecuted()
{
    gH_CVR_subdomain.GetString(gS_subdomain, sizeof(gS_subdomain));
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    
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
            case 0: { formatting.GetString(key, gST_chatFormatting.s_prefix, sizeof(gST_chatFormatting.s_prefix)); }
            case 1: { formatting.GetString(key, gST_chatFormatting.s_defaultColor, sizeof(gST_chatFormatting.s_defaultColor)); }
            case 2: { formatting.GetString(key, gST_chatFormatting.s_successColor, sizeof(gST_chatFormatting.s_successColor)); }
            case 3: { formatting.GetString(key, gST_chatFormatting.s_errorColor, sizeof(gST_chatFormatting.s_errorColor)); }
            case 4: { formatting.GetString(key, gST_chatFormatting.s_warnColor, sizeof(gST_chatFormatting.s_warnColor)); }
            case 5: { formatting.GetString(key, gST_chatFormatting.s_actionColor, sizeof(gST_chatFormatting.s_actionColor)); }
            case 6: { formatting.GetString(key, gST_chatFormatting.s_infoColor, sizeof(gST_chatFormatting.s_infoColor)); }
            case 7: { formatting.GetString(key, gST_chatFormatting.s_commandColor, sizeof(gST_chatFormatting.s_commandColor)); }
            case 8: { formatting.GetString(key, gST_chatFormatting.s_creditColor, sizeof(gST_chatFormatting.s_creditColor)); }
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

public void QSR_OnPointsChanged(int userid, float amtGiven, float oldTotal, float newTotal, bool &notify)
{
    char s_query[512], s_steam64ID[MAX_AUTHID_LENGTH];
    GetClientAuthId(GetClientOfUserId(userid), AuthId_SteamID64, s_steam64ID, sizeof(s_steam64ID));

    FormatEx(s_query, sizeof(s_query), "\
    UPDATE `srv_%s_players` \
    SET `points`=`%.2f` \
    WHERE `steam64_id`='%s'", gS_subdomain, newTotal, s_steam64ID);
    QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_DefaultCallback);
}

public void QSR_OnNewMostDamageDone(int userid, int oldDamage, int newDamage)
{
    QSR_PrintToChat(userid, "%sYou've done more damage than you have previously! Old: %d New: %d", gST_chatFormatting.s_infoColor, oldDamage, newDamage);
}

public void QSR_OnNewMostDamageTaken(int userid, int oldDamage, int newDamage)
{
    QSR_PrintToChat(userid, "%sYou've taken more damage than you have previously! Old: %d New: %d", gST_chatFormatting.s_infoColor, oldDamage, newDamage);
}

void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int i_attacker  = event.GetInt("attacker"),
        i_victim    = event.GetInt("userid"),
        i_damage    = event.GetInt("damageamount"),
        i_weapon    = event.GetInt("weaponid"),
        i_atkClient = GetClientOfUserId(i_attacker),
        i_vicClient = GetClientOfUserId(i_victim);

    QSR_LogMessage(gH_logFile, MODULE_NAME, "Attacker %d hurt Victim %d with weapon %d for %d damage", i_attacker, i_victim, i_damage, i_weapon);

    if (QSR_IsValidClient(i_atkClient) && QSR_IsPlayerFetched(i_attacker))
    {
        if (i_attacker == i_victim)
        {
            return;
        }

        gST_scores[i_atkClient].i_damageDone += i_damage;
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Attacker %d Total Damage: %d", i_attacker, gST_scores[i_atkClient].i_damageDone);

        if (i_damage > gST_scores[i_atkClient].i_mostDamageDone)
        {
            Call_StartForward(gH_FWD_onNewMostDamageDone);
            Call_PushCell(i_attacker);
            Call_PushCell(gST_scores[i_atkClient].i_mostDamageDone);
            Call_PushCell(i_damage);
            Call_Finish();

            gST_scores[i_atkClient].i_mostDamageDone = i_damage;
        }
    }

    if (QSR_IsValidClient(i_vicClient) && QSR_IsPlayerFetched(i_victim))
    {
        // Probably redundant, but better safe than sorry?
        if (i_victim == i_attacker)
        {
            return;
        }

        gST_scores[i_vicClient].i_damageTaken += i_damage;
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Victim %d Total Damage: %d", i_attacker, gST_scores[i_vicClient].i_damageTaken);

        if (i_damage > gST_scores[i_vicClient].i_mostDamageTaken)
        {

            Call_StartForward(gH_FWD_onNewMostDamageTaken);
            Call_PushCell(i_victim);
            Call_PushCell(gST_scores[i_vicClient].i_mostDamageTaken);
            Call_PushCell(i_damage);
            Call_Finish();

            gST_scores[i_vicClient].i_mostDamageTaken = i_damage;
        }
    }
}

void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int i_attacker  = event.GetInt("attacker"),
        i_victim    = event.GetInt("userid"),
        i_assister  = event.GetInt("assister"),
        i_atkClient = GetClientOfUserId(i_attacker),
        i_vicClient = GetClientOfUserId(i_victim),
        i_astClient = GetClientOfUserId(i_assister);

    if (QSR_IsValidClient(i_atkClient) && QSR_IsPlayerFetched(i_attacker) &&
        QSR_IsValidClient(i_vicClient) && QSR_IsPlayerFetched(i_victim))
    {
        // We'll handle suicides first.
        if (i_attacker == i_victim)
        {
            gST_scores[i_atkClient].i_totalSuicides++;
            QSR_ResetKillstreak(i_atkClient);

            Call_StartForward(gH_FWD_onPlayerSuicide);
            Call_PushCell(i_attacker);
            Call_Finish();
        
            if (i_assister)
            {
                Call_StartForward(gH_FWD_playerAssistedSuicide);
                Call_PushCell(i_attacker);
                Call_PushCell(i_assister);
                Call_Finish();
            }

            return;
        }

        int     i_creditsOnKill = gH_CVR_creditsOnKill.IntValue,
                i_creditsOnAssist = gH_CVR_creditsOnAssist.IntValue,
                i_creditsOnDeath = gH_CVR_creditsOnDeath.IntValue;

        float   f_pointsOnKill = gH_CVR_pointsOnKill.FloatValue,
                f_pointsOnAssist = gH_CVR_pointsOnAssist.FloatValue,
                f_pointsOnDeath = gH_CVR_pointsOnDeath.FloatValue;

        gST_scores[i_atkClient].i_totalKills++;
        gST_scores[i_atkClient].i_currentKillStreak++;

        // Now we'll check to see if we're using the afk system
        // And if the victim is afk.
        if (gH_CVR_useAFKSystem.BoolValue && QSR_IsPlayerAFK(i_victim))
        {
            // If both are true, we'll modify the amount of points the player is supposed to get.

            Action a_afkFWDAction = Plugin_Continue;

            Call_StartForward(gH_FWD_onVictimAFKPre);
            Call_PushCellRef(i_creditsOnKill);
            Call_PushCellRef(i_creditsOnAssist);
            Call_PushCellRef(i_creditsOnDeath);
            Call_PushCellRef(f_pointsOnKill);
            Call_PushCellRef(f_pointsOnAssist);
            Call_PushCellRef(f_pointsOnDeath);
            Call_Finish(a_afkFWDAction);
        }
    }
}

// custom
void QSR_ResetKillstreak(int client)
{
    Call_StartForward(gH_FWD_onPlayerLostKillstreak);
    Call_PushCell(GetClientUserId(client));
    Call_PushCell(gST_scores[client].i_currentKillStreak);
    Call_PushCell(gST_scores[client].f_currentMultiplier);
    Call_Finish();

    gST_scores[client].i_currentKillStreak = 0;
    gST_scores[client].f_currentMultiplier = 0.0;
}

// Callback
void SQLCB_DefaultCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0])
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, error);
    }
}

int Handler_StatMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {

    }

    return 0;
}

Action CMD_ModPoints(int client, int args)
{
    return Plugin_Handled;
}

Action CMD_StatsMenu(int client, int args)
{
    switch(args)
    {
        // No args, send the menu
        case 0:
        {
            char display[128];
            Menu statMenu = new Menu(Handler_StatMenuHandler);
            statMenu.SetTitle("%T", "QSR_StatMenuTitle");
            
            FormatEx(display, sizeof(display), "%T", "QSR_YourStats", client);
            statMenu.AddItem("0", display);

            FormatEx(display, sizeof(display), "%T", "QSR_OthersStats", client);
            statMenu.AddItem("1", display);

            FormatEx(display, sizeof(display), "%T", "QSR_Top10Points", client);
            statMenu.AddItem("2", display);

            FormatEx(display, sizeof(display), "%T", "QSR_Top10TotalDamage", client);
            statMenu.AddItem("3", display);

            FormatEx(display, sizeof(display), "%T", "QSR_Top10HighestDamage", client);
            statMenu.AddItem("4", display);
        
            statMenu.Display(client, 20);
        }

        // Player Name or SteamID
        case 1:
        {

        }

        case 2:
        {

        }
    }

    return Plugin_Handled;
}