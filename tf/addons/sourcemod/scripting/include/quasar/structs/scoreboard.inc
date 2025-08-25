enum struct QSRStatInfo
{
    // What rank is this player?
    int i_currentRank;

    // Stats
    int i_totalKills;
    int i_totalAssists;
    int i_totalDeaths;
    int i_totalSuicides;
    int i_damageDone;
    int i_mostDamageDone;
    int i_damageTaken;
    int i_mostDamageTaken;
    int i_healingDone;
    int i_mostHealingDone;    // Over the entire session.

    float f_pointsEarned;
    float f_mostPointsEarned; // Over the entire session.

    // Killstreak stuff
    int i_currentKillStreak;
    int i_highestKillstreak;
    float f_currentMultiplier;
    float f_highestMultiplier;

    void Reset()
    {
        this.i_currentRank       = -1;

        this.i_totalKills        = 0;
        this.i_totalAssists      = 0;
        this.i_totalDeaths       = 0;
        this.i_totalSuicides     = 0;
        this.i_currentKillStreak = 0;
        this.i_highestKillstreak = 0;
        this.i_damageDone        = 0;
        this.i_mostDamageDone    = 0;
        this.i_damageTaken       = 0;
        this.i_mostDamageTaken   = 0;
        this.i_healingDone       = 0;
        this.i_mostHealingDone   = 0;

        this.f_mostPointsEarned  = 0.0;
        this.f_pointsEarned      = 0.0;
        this.f_currentMultiplier = 1.0;
        this.f_highestMultiplier = 1.0;
    }
}