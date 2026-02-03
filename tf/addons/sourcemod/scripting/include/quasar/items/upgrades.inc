// Upgrades
#define UPGRADE_NONE                 0
#define UPGRADE_DEATH_SOUNDS         (1 << 0)
#define UPGRADE_JOINLEAVE_SOUNDS     (1 << 1)
#define UPGRADE_INSPEC_SOUNDS        (1 << 2)
#define UPGRADE_NO_SOUND_COOLDOWN    (1 << 3)
#define UPGRADE_NAME_COLOR           (1 << 4)
#define UPGRADE_CHAT_COLOR           (1 << 5)
#define UPGRADE_CHAT_FORMAT          (1 << 6)
#define UPGRADE_DISPLAY_RANK         (1 << 7)
#define UPGRADE_NICKNAME             (1 << 8)
#define UPGRADE_UNUSUAL_TAUNTS       (1 << 9)
#define UPGRADE_UNUSUAL_WEAPON       (1 << 10)
#define UPGRADE_UNUSUAL_COSMETICS    (1 << 11)
#define UPGRADE_DONATE_CREDITS       (1 << 12)
#define UPGRADE_DROP_CREDITS         (1 << 13)
#define UPGRADE_CUSTOM_PAINT         (1 << 14)

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
    QSRUpgrade_Nickname,
    QSRUpgrade_UnusualTaunts,
    QSRUpgrade_UnusualWeapons,
    QSRUpgrade_UnusualCosmetics,
    QSRUpgrade_DonateCredits,
    QSRUpgrade_DropCredits,
    QSRUpgrade_CustomCosmeticColors
};

    bool HasUpgrade(QSRUpgradeType upgrade)
    {
        switch (upgrade)
        {
            case QSRUpgrade_ChatFormatting:         { if (this.upgradeFlags & UPGRADE_CHAT_FORMAT)           { return true; }}
            case QSRUpgrade_ColoredChat:            { if (this.upgradeFlags & UPGRADE_CHAT_COLOR)            { return true; }}
            case QSRUpgrade_ColoredName:            { if (this.upgradeFlags & UPGRADE_NAME_COLOR)            { return true; }}
            case QSRUpgrade_CustomCosmeticColors:   { if (this.upgradeFlags & UPGRADE_CUSTOM_PAINT)         { return true; }}
            case QSRUpgrade_DeathSound:             { if (this.upgradeFlags & UPGRADE_DEATH_SOUNDS)         { return true; }}
            case QSRUpgrade_DonateCredits:          { if (this.upgradeFlags & UPGRADE_DONATE_CREDITS)        { return true; }}
            case QSRUpgrade_DropCredits:            { if (this.upgradeFlags & UPGRADE_DROP_CREDITS)          { return true; }}
            case QSRUpgrade_JoinLeaveSounds:        { if (this.upgradeFlags & UPGRADE_JOINLEAVE_SOUNDS)     { return true; }}
            case QSRUpgrade_NoSoundCooldown:        { if (this.upgradeFlags & UPGRADE_NO_SOUND_COOLDOWN)    { return true; }}
            case QSRUpgrade_RankTag:                { if (this.upgradeFlags & UPGRADE_DISPLAY_RANK)              { return true; }}}
            case QSRUpgrade_SpectatorSound:         { if (this.upgradeFlags & UPGRADE_INSPEC_SOUNDS)        { return true; }}
            case QSRUpgrade_UnusualCosmetics:       { if (this.upgradeFlags & UPGRADE_UNUSUAL_COSMETICS)        { return true; }}
            case QSRUpgrade_UnusualTaunts:          { if (this.upgradeFlags & UPGRADE_UNUSUAL_TAUNTS)           { return true; }}
            case QSRUpgrade_UnusualWeapons:         { if (this.upgradeFlags & UPGRADE_UNUSUAL_WEAPON)           { return true; }}
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
