// Upgrades
#define UPGRADE_NONE                0
#define UPGRADE_DEATH_SOUNDS        (1 << 0)
#define UPGRADE_JOINLEAVE_SOUNDS    (1 << 1)
#define UPGRADE_INSPEC_SOUNDS       (1 << 2)
#define UPGRADE_NO_SOUND_COOLDOWN   (1 << 3)
#define UPGRADE_NAMECOLOR           (1 << 4)
#define UPGRADE_CHATCOLOR           (1 << 5)
#define UPGRADE_CHATFORMAT          (1 << 6)
#define UPGRADE_RANKTAG             (1 << 7)
#define UPGRADE_RBLXPALLETTE        (1 << 8)
#define UPGRADE_UNUSTAUNTS          (1 << 9)
#define UPGRADE_UNUSWEAPON          (1 << 10)
#define UPGRADE_UNUSCOSMETICS       (1 << 11)
#define UPGRADE_DONATECREDITS       (1 << 12)
#define UPGRADE_DROPCREDITS         (1 << 13)
#define UPGRADE_CUSTOM_PAINT        (1 << 14)

enum QSRUpgradeType
{
    QSRUpgrade_None,
    QSRUpgrade_DeathSound,
    QSRUpgrade_JoinLeaveSounds,
    QSRUpgrade_SpectatorSound,
    QSRUpgrade_NoSoundCooldown,
    QSRUpgrade_ColoredName,
    QSRUpgrade_ColoredChat,
    QSRUpgrade_ChatFormatting,
    QSRUpgrade_RankTag,
    QSRUpgrade_RblxPalette,
    QSRUpgrade_UnusualTaunts,
    QSRUpgrade_UnusualWeapons,
    QSRUpgrade_UnusualCosmetics,
    QSRUpgrade_DonateCredits,
    QSRUpgrade_DropCredits,
    QSRUpgrade_CustomCosmeticColors
}

enum struct QSRPlayer
{
    Handle  playtimeTimer;
    Handle  pollAuthTimer;
    Handle  afkTimer

    bool    isAFK;
    bool    isFriendly;
    bool    isLoggedIn;
    bool    isInfoFetched;
    bool    sentLoginMessage;

    char    steam2ID[MAX_AUTHID_LENGTH];
    char    steam3ID[MAX_AUTHID_LENGTH];
    char    steam64ID[MAX_AUTHID_LENGTH];
    char    name[MAX_NAME_LENGTH];

    float   points;

    int     rank;
    int     credits;
    int     loginAttempts;
    int     fetchInfoAttempts;
    int     firstLogin;
    int     lastLogin;
    int     playtime;
    int     totalPlaytime;
    int     timeAFK;
    int     totalTimeAFK;
    int     userid;
    int     upgradeFlags;

    void CreateTimers(bool usingAFK = true)
    {
        if (this.playtimeTimer != null) 
        { 
            KillTimer(this.playtimeTimer);
            this.playtimeTimer = null;
        }
        
        if (this.afkTimer != null)
        {
            KillTimer(this.afkTimer);         
            this.afkTimer = null;
        }

        this.playtimeTimer = CreateTimer(1.0, Timer_IncPlaytime, this);
        if (usingAFK) { this.afkTimer = CreateTimer(1.0, Timer_IncTimeAFK, this); }
    }

    bool HasUpgrade(QSRUpgradeType upgrade)
    {
        switch (upgrade)
        {
            case QSRUpgrade_ChatFormatting:         { if (this.upgradeFlags & UPGRADE_CHATFORMAT)           { return true; }}
            case QSRUpgrade_ColoredChat:            { if (this.upgradeFlags & UPGRADE_CHATCOLOR)            { return true; }}
            case QSRUpgrade_ColoredName:            { if (this.upgradeFlags & UPGRADE_NAMECOLOR)            { return true; }}
            case QSRUpgrade_CustomCosmeticColors:   { if (this.upgradeFlags & UPGRADE_CUSTOM_PAINT)         { return true; }}
            case QSRUpgrade_DeathSound:             { if (this.upgradeFlags & UPGRADE_DEATH_SOUNDS)         { return true; }}
            case QSRUpgrade_DonateCredits:          { if (this.upgradeFlags & UPGRADE_DONATECREDITS)        { return true; }}
            case QSRUpgrade_DropCredits:            { if (this.upgradeFlags & UPGRADE_DROPCREDITS)          { return true; }}
            case QSRUpgrade_JoinLeaveSounds:        { if (this.upgradeFlags & UPGRADE_JOINLEAVE_SOUNDS)     { return true; }}
            case QSRUpgrade_NoSoundCooldown:        { if (this.upgradeFlags & UPGRADE_NO_SOUND_COOLDOWN)    { return true; }}
            case QSRUpgrade_RankTag:                { if (this.upgradeFlags & UPGRADE_RANKTAG)              { return true; }}
            case QSRUpgrade_RblxPalette:            { if (this.upgradeFlags & UPGRADE_RBLXPALLETTE)         { return true; }}
            case QSRUpgrade_SpectatorSound:         { if (this.upgradeFlags & UPGRADE_INSPEC_SOUNDS)        { return true; }}
            case QSRUpgrade_UnusualCosmetics:       { if (this.upgradeFlags & UPGRADE_UNUSCOSMETICS)        { return true; }}
            case QSRUpgrade_UnusualTaunts:          { if (this.upgradeFlags & UPGRADE_UNUSTAUNTS)           { return true; }}
            case QSRUpgrade_UnusualWeapons:         { if (this.upgradeFlags & UPGRADE_UNUSWEAPON)           { return true; }}
        }

        return false;
    }

    void AddUpgrade(QSRUpgradeType upgrade)
    {
        switch (upgrade)
        {

        }

        PrintToServer("Upgrade Added: %d", upgrade);
    }

    void Reset()
    {
        if (this.playtimeTimer  != null)  { KillTimer(this.playtimeTimer);   this.playtimeTimer = null; }
        if (this.pollAuthTimer  != null)  { KillTimer(this.pollAuthTimer);   this.pollAuthTimer = null; }
        if (this.afkTimer       != null)  { KillTimer(this.afkTimer);        this.afkTimer      = null; }

        this.isAFK              = false;
        this.isFriendly         = false;
        this.isLoggedIn         = false;
        this.isInfoFetched      = false;
        this.sentLoginMessage   = false;

        this.steam2ID           = EMPTY_STRING;
        this.steam3ID           = EMPTY_STRING;
        this.steam64ID          = EMPTY_STRING;
        this.name               = EMPTY_STRING;

        this.points             = 0.0;

        this.credits            = 0;
        this.fetchInfoAttempts  = 0;
        this.firstLogin         = 0;
        this.lastLogin          = 0;
        this.playtime           = 0;
        this.totalPlaytime      = 0;
        this.timeAFK            = 0;
        this.totalTimeAFK       = 0;
        this.upgradeFlags       = 0;
        this.userid             = -1;
    }
}

void Timer_IncPlaytime(Handle timer, QSRPlayer player)
{
    if (player.isAFK) { return; }

    player.playtime++;
}

void Timer_IncTimeAFK(Handle timer, QSRPlayer player)
{
    if (!player.isAFK) { return; }

    player.timeAFK++;
}
