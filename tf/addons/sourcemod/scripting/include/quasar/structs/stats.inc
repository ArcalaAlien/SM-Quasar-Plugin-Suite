enum struct QSRStats {
    int i_currentRank;
    int i_rankTitleLevel;

    int i_firstLogin;   // First login to the server
    int i_lastLogin;    // Last login to the server
    int i_playtime;     // Time spent playing on the server
    int i_timeAfk;      // Time spent AFK on the server

    // Non-AFK Stats
    float   f_points;
    float   f_mostPointsEarned; // Most points earned in a single game
    int     i_kills;
    int     i_teamkills;
    int     i_deaths;
    int     i_assists;
    int     i_suicides;

    int     i_mostDamageDone;
    int     i_mostDamageTaken;
    int     i_mostHealingDone;

    int     i_highestKillStreak; // Highest killstreak for killing non-afk players

    // AFK Stats
    float   f_afkPoints;  // Points earned for killing AFK Players
    float   f_mostAFKPointsEarned; // Most points earned for killing AFK Players

    int     i_afkKills;      // Killing AFK Players
    int     i_afkTeamkills;  // Killing AFK Teammates
    int     i_afkDeaths;     // Dying while AFK
    int     i_afkAssists;    // Assists killing AFK Players

    int     i_afkMostDamageDone;   // Most damage done to an AFK Player
    int     i_afkMostDamageTaken;  // Most damage taken while AFK
    int     i_afkMostHealingDone;  // Most healing done to an AFK player
    int     i_highestAFKKillStreak; // Highest killstreak for killing AFK Players
}