#include <sourcemod>
#include <sdktools>

#include <quasar/core>
#include <quasar/players>
#include <quasar/items>
#undef   MODULE_NAME
#define  MODULE_NAME "Items"

#include <autoexecconfig>

// Prepared statements
DBStatementX gH_DBS_getPlayerSounds = null;
DBStatementX gH_DBS_getPlayerTrails = null;
DBStatementX gH_DBS_getPlayerTags = null;
DBStatementX gH_DBS_getPlayerUpgrades = null;
DBStatementX gH_DBS_getPlayerInventory = null;

Database gH_db = null;
Handle gH_logFile = null;
bool gB_dbConnected = false;

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Item Handler)",
    author = PLUGIN_AUTHOR,
    description = "Description",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_inv", CMD_OpenInventoryMenu);
    RegConsoleCmd("sm_inventory", CMD_OpenInventoryMenu);
    RegConsoleCmd("sm_loadouts", CMD_OpenLoadoutMenu);
    RegConsoleCmd("sm_loadout", CMD_OpenLoadoutMenu);
    RegConsolCmd("sm_equip", CMD_OpenLoadoutMenu);
}

public void OnPluginEnd()
{
    gH_DBS_getPlayerInventory.Close();
    gH_DBS_getPlayerSounds.Close();
    gH_DBS_getPlayerTags.Close();
    gH_DBS_getPlayerTrails.Close();
    gH_DBS_getPlayerUpgrades.Close();
}

// Forwards
public void QSR_OnDatabaseConnected(Database& db)
{
    gH_db = db;
    gB_dbConnected = true;

    char s_error[256];
    gH_DBS_getPlayerSounds = view_as<DBStatementX>(SQL_PrepareQuery(gH_db, "\
    SELECT * \
    FROM `[Player Sounds]` \
    WHERE steam_id = ?", s_error, sizeof(s_error)));
    if (s_error[0])
    {
        QSR_LogMessage(gH_logFile, s_error);
        s_error = EMPTY_STRING;
    }

    gH_DBS_getPlayerTrails = view_as<DBStatementX>(SQL_PrepareQuery(gH_db, "\
    SELECT * \
    FROM `[Player Trails]` \
    WHERE steam_id = ?", s_error, sizeof(s_error)));
    if (s_error[0])
    {
        QSR_LogMessage(gH_logFile, s_error);
        s_error = EMPTY_STRING;
    }

    gH_DBS_getPlayerTags = view_as<DBStatementX>(SQL_PrepareQuery(gH_db, "\
    SELECT * \
    FROM `[Player Tags]` \
    WHERE steam_id = ?", s_error, sizeof(s_error)));
    if (s_error[0])
    {
        QSR_LogMessage(gH_logFile, s_error);
        s_error = EMPTY_STRING;
    }

    gH_DBS_getPlayerUpgrades = view_as<DBStatementX>(SQL_PrepareQuery(gH_db, "\
    SELECT * \
    FROM `[Player Upgrades]` \
    WHERE steam_id = ?", s_error, sizeof(s_error)));
    if (s_error[0])
    {
        QSR_LogMessage(gH_logFile, s_error);
        s_error = EMPTY_STRING;
    }

    gH_DBS_getPlayerInventory = view_as<DBStatementX>(SQL_PrepareQuery(gH_db, "\
    SELECT  item_id, \
            upgrade_name, trail_name, sound_name, tag_name \
            upgrade_price, trail_price, sound_price, tag_price \
            upgrade_description, \
            trail_vtf, trail_vmt \
            sound_filepath, sound_cooldown \
            tag_color, tag_display \
    FROM `[Player Inventory]` \
    WHERE steam_id = ?", s_error, sizeof(s_error)));
    if (s_error[0])
    {
        QSR_LogMessage(gH_logFile, s_error);
        s_error = EMPTY_STRING;
    }

    QSR_LogMessage(gH_logFile, "Prepared all query statements!");
}

public void QSR_OnLogFileMade(File& file)
{
    gH_logFile = file;
}

any Native_QSRCheckForUpgrade(Handle plugin, int numParams)
{
    int client = GetClientOfUserId(GetNativeCell(1));
    return (gST_player[client].IsUpgradeOwned(GetNativeCell(2)));
}

// General Functions

void QSR_SendInventoryMenu(int client)
{
    // Setup menu
    char display[64];
    Menu h_inventoryMenu = new Menu(Handler_InventoryMenu);
    h_inventoryMenu.SetTitle("%T", client, "QSR_InventoryMenuTitle");

    // Add Tag Category
    FormatEx(display, sizeof(display), "%T", client, "QSR_TagCategory");
    h_inventoryMenu.AddItem("0", display);

    // Add Trail Category
    FormatEx(display, sizeof(display), "%T", client, "QSR_SoundCategory");
    h_inventoryMenu.AddItem("1", display);

    // Add Sound Category
    FormatEx(display, sizeof(display), "%T", client, "QSR_TrailCategory");
    h_inventoryMenu.AddItem("2", display);

    // Add Upgrade Category
    FormatEx(display, sizeof(display), "%T", client, "QSR_UpgradeCategory");
    h_inventoryMenu.AddItem("3", display);
    
    h_inventoryMenu.Display(client, 30);
}

// Callbacks

void Timer_PopulatePlayerUpgrades(Handle timer, int client)
{
    if (QSR_IsValidClient(GetClientUserId(client)))
    {
        if (gST_player[client].i_fetchUpgradesAttempts == 5)
        {
            QSR_LogMessage("ERROR: Unable to get player upgrades for SteamID %s after 5 attempts!", gST_player[client].s_steam64ID);
            QSR_NotifyUser(GetClientUserId(client), gST_sounds.s_errorSound, 
            "%t", "QSR_UnableToFetchUpgrade",
            gST_chatFormatStrings.s_errorColor, gST_chatFormatStrings.s_commandColor, gST_chatFormatStrings.s_errorColor);
            gST_player[client].i_fetchUpgradesAttempts = 0;
            gST_player[client].b_fetchedUpgrades = false;
            return;
        }

        char s_query[512];
        FormatEx(s_query, sizeof(s_query),
        "SELECT item_id \
        FROM `[Player Inventory]` \
        WHERE `steam_id`='%s' AND `item_id` LIKE 'ugd_'", gST_player[client].s_steam64ID);
        QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_PopulatePlayerUpgrades, client);
    }
}

void Timer_PopulateQSRLoadout(Handle timer, int client)
{
    if (QSR_IsValidClient(GetClientUserId(client)))
    {
        if (gST_player[client].i_fetchQSRLoadoutAttempts == 5)
        {
            QSR_LogMessage("ERROR: Unable to get Quasar items for SteamID %s after 5 attempts!", gST_player[client].s_steam64ID);
            QSR_NotifyUser(GetClientUserId(client), gST_sounds.s_errorSound, 
            "%t", "QSR_UnableToFetchQSRItems",
            gST_chatFormatStrings.s_errorColor, gST_chatFormatStrings.s_commandColor, gST_chatFormatStrings.s_errorColor);
            gST_player[client].i_fetchQSRLoadoutAttempts = 5;
            gST_player[client].b_fetchedQSRLoadouts = false;
            return;
        }

        char s_query[512];
        FormatEx(s_query, sizeof(s_query),
        "SELECT loadout_id, snd_1_id, snd_2_id, snd_3_id, \
                snd_ct_id, snd_dc_id, snd_dt_id, \
                trl_id, trl_color_r, trl_color_g, trl_color_b, \
                trl_color_a, trl_color_w, \
                tag_id, name_color_trie, chat_color_trie \
        FROM str_qsrloadouts \
        WHERE `steam_id`='%s'", gST_player[client].s_steam64ID);
        QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_PopulateQSRLoadout, client);
    }
}

void Timer_PopulatePlayerSounds(Handle timer, int client)
{
    if (QSR_IsValidClient(GetClientUserId(client)))
    {
        if (gST_player[client].i_fetchSoundIDsAttempts == 5)
        {
            QSR_LogMessage("ERROR: Unable to get the equipped sounds for SteamID %s after 5 attempts!", gST_player[client].s_steam64ID);
            QSR_NotifyUser(GetClientUserId(client), gST_sounds.s_errorSound,
            "%t", "QSR_UnableToFetchSounds",
            gST_chatFormatStrings.s_errorColor, gST_chatFormatStrings.s_commandColor, gST_chatFormatStrings.s_errorColor);
            gST_player[client].i_fetchSoundIDsAttempts = 0;
            gST_player[client].b_fetchedSoundIDs = false;
            return;
        }

        char s_query[512];
        FormatEx(s_query, sizeof(s_query), 
        "SELECT loadout_id, slot, item_id \
        FROM str_soundslots \
        WHERE `steam_id`='%s'", gST_player[client].s_steam64ID);
        QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_PopulatePlayerSounds, client);
    }
}

void Timer_PopulateTFLoadout(Handle timer, int client)
{
    if (QSR_IsValidClient(GetClientUserId(client)))
    {
        if (gST_player[client].i_fetchTFLoadoutAttempts == 5)
        {
            QSR_LogMessage("ERROR: Unable to get TF Items for SteamID %s after 5 attempts!", gST_player[client].s_steam64ID);
            QSR_NotifyUser(GetClientUserId(client), gST_sounds.s_errorSound,
            "%t", "QSR_UnableToFetchTFItems",
            gST_chatFormatStrings.s_errorColor, gST_chatFormatStrings.s_commandColor, gST_chatFormatStrings.s_errorColor);
            gST_player[client].i_fetchTFLoadoutAttempts = 0;
            gST_player[client].b_fetchedTFLoadouts = false;
            return;
        }

        char s_query[512];
        FormatEx(s_query, sizeof(s_query),
        "SELECT loadout_id, class, slot, \
                item_id, quality, level, unusual_id, \
                paintkit_id, warpaint_id, \
                red_team_color, blu_team_color \
        FROM str_tfloadouts \
        WHERE `steam_id`='%s'", gST_player[client].s_steam64ID);
        QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_PopulateTFLoadout, client);
    }
}

// SQL CallBacks
void SQLCB_PopulatePlayerUpgrades(Database db, DBResultSet results, const char[] error, int client)
{
    if (error[0])
    {
        gST_player[client].i_fetchUpgradesAttempts++;
        CreateTimer(5.0, Timer_PopulatePlayerUpgrades, client);
        QSR_LogMessage("Unable to fetch player upgrades! Attempting again in 5s.\nERROR: %s", error);
        return;
    }
    
    char s_itemId[64];
    if (results.HasResults)
    {
        while (results.FetchRow())
        {
            results.FetchString(0, s_itemId, sizeof(s_itemId));
            gST_player[client].AddUpgrade(QSR_ItemIdToUpgradeType(s_itemId));
        }

        gST_player[client].i_fetchUpgradesAttempts = 0;
        gST_player[client].b_fetchedUpgrades = true;
    }
}

void SQLCB_PopulateQSRLoadout(Database db, DBResultSet results, const char[] error, int client)
{
    if (error[0])
    {
        gST_player[client].i_fetchQSRLoadoutAttempts++;
        CreateTimer(5.0, Timer_PopulateQSRLoadout, client);
        QSR_LogMessage("Unable to populate player's Quasar loadout! Retrying in 5s.\nERROR: %s", error);
        return;
    }

    if (results.HasResults)
    {
        int i_loadoutID;
        int i_trailR;
        int i_trailG;
        int i_trailB;
        int i_trailA;
        int i_trailW;
        char s_trailID[64];
        char s_tagID[64];
        char s_nameColor[64];
        char s_chatColor[64];

        while (results.FetchRow())
        {
            i_loadoutID = results.FetchInt(0);
            results.FetchString(1, s_trailID, sizeof(s_trailID));
            i_trailR = results.FetchInt(2);
            i_trailG = results.FetchInt(3);
            i_trailB = results.FetchInt(4);
            i_trailA = results.FetchInt(5);
            i_trailW = results.FetchInt(6);
            results.FetchString(7, s_tagID, sizeof(s_tagID));
            results.FetchString(8, s_nameColor, sizeof(s_nameColor));
            results.FetchString(9, s_chatColor, sizeof(s_chatColor));

            #define CLIENT_QSR_LOADOUT gST_player[client].st_loadout[i_loadoutID-1].st_quasarItems

            strcopy(CLIENT_QSR_LOADOUT.st_equippedTrail.s_itemID,       sizeof(CLIENT_QSR_LOADOUT.st_equippedTrail.s_itemID),       s_trailID);
            strcopy(CLIENT_QSR_LOADOUT.st_equippedTag.s_itemID,         sizeof(CLIENT_QSR_LOADOUT.st_equippedTag.s_itemID),         s_tagID);
            
            // Once we fetch all of the Item IDs we need we can populate each item's info.
            CLIENT_QSR_LOADOUT.st_equippedTag.Get();
            CLIENT_QSR_LOADOUT.st_equippedTrail.Get();
            
            strcopy(CLIENT_QSR_LOADOUT.s_nameColor,                     sizeof(CLIENT_QSR_LOADOUT.s_nameColor), s_nameColor);
            strcopy(CLIENT_QSR_LOADOUT.s_chatColor,                     sizeof(CLIENT_QSR_LOADOUT.s_chatColor), s_chatColor);

            CLIENT_QSR_LOADOUT.st_equippedTrail.SetRGBA(i_trailR, i_trailG, i_trailB, i_trailA);
            CLIENT_QSR_LOADOUT.st_equippedTrail.i_width = i_trailW;

            #undef CLIENT_QSR_LOADOUT
        }
    }
}

void SQLCB_PopulatePlayerSounds(Database db, DBResultSet results, const char[] error, int client)
{
    if (error[0])
    {
        gST_player[client].i_fetchSoundIDsAttempts++;
        CreateTimer(5.0, Timer_PopulatePlayerSounds, client);
        QSR_LogMessage("Unable to populate player's equipped sounds! Retrying in 5s.\nERROR: %s", error);
        return;
    }

    if (results.HasResults)
    {
        char s_itemID[64];
        int i_loadout, i_slot;
        while (results.FetchRow())
        {
            
            i_loadout = results.FetchInt(0);
            i_slot = results.FetchInt(1);
            results.FetchString(2, s_itemID, sizeof(s_itemID));

            #define CLIENT_SOUND gST_player[client].st_loadout[i_loadout-1].st_quasarItems.st_equippedSounds[i_slot]

            strcopy(CLIENT_SOUND.s_itemID, sizeof(CLIENT_SOUND.s_itemID), s_itemID);
            CLIENT_SOUND.Get();
            
            #undef CLIENT_SOUND
        }

        gST_player[client].i_fetchSoundIDsAttempts = 0;
        gST_player[client].b_fetchedSoundIDs = true;
    }
}

void SQLCB_PopulateTFLoadout(Database db, DBResultSet results, const char[] error, int client)
{
    if (error[0])
    {
        gST_player[client].i_fetchTFLoadoutAttempts++;
        CreateTimer(5.0, Timer_PopulateTFLoadout, client);
        QSR_LogMessage("Unable to populate player's TF loadout! Retrying in 5s.\nERROR: %s", error);
        return;
    }

    if (results.HasResults)
    {
        int i_loadoutID;
        int i_class;
        int i_index;
        char s_slot[32];
        int i_quality;
        int i_level;
        int i_unusualID;
        int i_paintkitID;
        int i_warpaintID;
        while (results.FetchRow())
        {
            i_loadoutID = results.FetchInt(0);
            i_class = results.FetchInt(1);
            results.FetchString(2, s_slot, sizeof(s_slot));
            i_index = results.FetchInt(3);
            i_quality = results.FetchInt(4);
            i_level = results.FetchInt(5);
            i_unusualID = results.FetchInt(6);
            i_paintkitID = results.FetchInt(7);
            i_warpaintID = results.FetchInt(9);

            #define TF_ITEM_LOADOUT gST_player[client].st_loadout[i_loadoutID-1]

            switch(s_slot[3])
            {
                // Primary Weapon
                case 'm':
                {
                    TF_ITEM_LOADOUT.st_primary[i_class-1].Reset();
                    TF_ITEM_LOADOUT.st_primary[i_class-1].i_index = i_index;
                    TF_ITEM_LOADOUT.st_primary[i_class-1].i_level = i_level;
                    TF_ITEM_LOADOUT.st_primary[i_class-1].i_quality = i_quality;
                    TF_ITEM_LOADOUT.st_primary[i_class-1].i_paintkit = i_paintkitID;
                    TF_ITEM_LOADOUT.st_primary[i_class-1].i_warpaint = i_warpaintID;
                    TF_ITEM_LOADOUT.st_primary[i_class-1].i_unusual = i_unusualID;
                    
                    strcopy(TF_ITEM_LOADOUT.st_primary[i_class-1].s_slot,
                     sizeof(TF_ITEM_LOADOUT.st_primary[i_class-1].s_slot), s_slot);
                }

                // Secondary Weapon
                case 'o':
                {
                    TF_ITEM_LOADOUT.st_secondary[i_class-1].Reset();
                    TF_ITEM_LOADOUT.st_secondary[i_class-1].i_index = i_index;
                    TF_ITEM_LOADOUT.st_secondary[i_class-1].i_level = i_level;
                    TF_ITEM_LOADOUT.st_secondary[i_class-1].i_quality = i_quality;
                    TF_ITEM_LOADOUT.st_secondary[i_class-1].i_paintkit = i_paintkitID;
                    TF_ITEM_LOADOUT.st_secondary[i_class-1].i_warpaint = i_warpaintID;
                    TF_ITEM_LOADOUT.st_secondary[i_class-1].i_unusual = i_unusualID;
                    
                    strcopy(TF_ITEM_LOADOUT.st_secondary[i_class-1].s_slot,
                     sizeof(TF_ITEM_LOADOUT.st_secondary[i_class-1].s_slot), s_slot);
                }

                // Melee Weapon
                case 'e':
                {
                    TF_ITEM_LOADOUT.st_melee[i_class-1].Reset();
                    TF_ITEM_LOADOUT.st_melee[i_class-1].i_index = i_index;
                    TF_ITEM_LOADOUT.st_melee[i_class-1].i_level = i_level;
                    TF_ITEM_LOADOUT.st_melee[i_class-1].i_quality = i_quality;
                    TF_ITEM_LOADOUT.st_melee[i_class-1].i_paintkit = i_paintkitID;
                    TF_ITEM_LOADOUT.st_melee[i_class-1].i_warpaint = i_warpaintID;
                    TF_ITEM_LOADOUT.st_melee[i_class-1].i_unusual = i_unusualID;
                    
                    strcopy(TF_ITEM_LOADOUT.st_melee[i_class-1].s_slot,
                     sizeof(TF_ITEM_LOADOUT.st_melee[i_class-1].s_slot), s_slot);
                }

                // Cosmetic
                case 'c':
                {
                    if (TF_ITEM_LOADOUT.st_misc1[i_class-1].IsEmpty())
                    {
                        TF_ITEM_LOADOUT.st_misc1[i_class-1].i_level = i_level;
                        TF_ITEM_LOADOUT.st_misc1[i_class-1].i_quality = i_quality;
                        TF_ITEM_LOADOUT.st_misc1[i_class-1].i_paintkit = i_paintkitID;
                        TF_ITEM_LOADOUT.st_misc1[i_class-1].i_warpaint = i_warpaintID;
                        TF_ITEM_LOADOUT.st_misc1[i_class-1].i_unusual = i_unusualID;

                        strcopy(TF_ITEM_LOADOUT.st_misc1[i_class-1].s_slot,
                         sizeof(TF_ITEM_LOADOUT.st_misc1[i_class-1].s_slot), s_slot);
                    }
                    else if (TF_ITEM_LOADOUT.st_misc2[i_class-1].IsEmpty())
                    {
                        TF_ITEM_LOADOUT.st_misc2[i_class-1].i_level = i_level;
                        TF_ITEM_LOADOUT.st_misc2[i_class-1].i_quality = i_quality;
                        TF_ITEM_LOADOUT.st_misc2[i_class-1].i_paintkit = i_paintkitID;
                        TF_ITEM_LOADOUT.st_misc2[i_class-1].i_warpaint = i_warpaintID;
                        TF_ITEM_LOADOUT.st_misc2[i_class-1].i_unusual = i_unusualID;

                        strcopy(TF_ITEM_LOADOUT.st_misc2[i_class-1].s_slot,
                         sizeof(TF_ITEM_LOADOUT.st_misc2[i_class-1].s_slot), s_slot);
                    }
                    else if (TF_ITEM_LOADOUT.st_misc3[i_class-1].IsEmpty())
                    {
                        TF_ITEM_LOADOUT.st_misc3[i_class-1].i_level = i_level;
                        TF_ITEM_LOADOUT.st_misc3[i_class-1].i_quality = i_quality;
                        TF_ITEM_LOADOUT.st_misc3[i_class-1].i_paintkit = i_paintkitID;
                        TF_ITEM_LOADOUT.st_misc3[i_class-1].i_warpaint = i_warpaintID;
                        TF_ITEM_LOADOUT.st_misc3[i_class-1].i_unusual = i_unusualID;

                        strcopy(TF_ITEM_LOADOUT.st_misc3[i_class-1].s_slot,
                         sizeof(TF_ITEM_LOADOUT.st_misc3[i_class-1].s_slot), s_slot);
                    }
                }
            }

            TF_ITEM_LOADOUT.Get();
            #undef TF_ITEM_LOADOUT
        }

        gST_player[client].i_fetchTFLoadoutAttempts = 0;
        gST_player[client].b_fetchedTFLoadouts = true;
    }
}

Action CMD_OpenInventoryMenu(int client, int args)
{
    if (!client || !QSR_IsValidClient(client)) { return Plugin_Handled; }

    QSR_SendInventoryMenu(client);
    return Plugin_Handled;
}

Action QSR_OpenLoadoutMenu(int client, int args)
{
    if (!client || !QSR_IsValidClient(client)) { return Plugin_Handled; }

    QSR_SendLoadoutMenu(client);
    return Plugin_Handled;
}