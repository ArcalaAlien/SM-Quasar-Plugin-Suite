any Native_QSRCheckForUpgrade(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return false; }
    QSRUpgradeType upgrade = GetNativeCell(2);

    return (gST_players[client].upgradeFlags & QSR_UpgradeTypeToFlag(upgrade));
}

void Native_QSRAddUpgrade(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return; }

    QSRUpgradeType upgrade = GetNativeCell(2);
    char upgradeName[64];
    QSR_UpgradeTypeToItemId(upgrade, upgradeName, sizeof(upgradeName));

    gST_players[client].upgradeFlags |= QSR_UpgradeTypeToFlag(upgrade);
}