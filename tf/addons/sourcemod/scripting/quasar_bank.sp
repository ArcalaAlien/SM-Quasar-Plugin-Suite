#include <sourcemod>
#include <regex>
#include <sdktools>
#include <sdkhooks>

#include <quasar/core>
#undef   MODULE_NAME
#define  MODULE_NAME "Bank"

#include <quasar/players>
#include <quasar/bank>
#include <autoexecconfig>

// Core stuff
QSRChatFormat    gST_chatFormatting;
QSRGeneralSounds gST_sounds;
QSRBankOptions   gST_bankOptions;
QSRCreditPickup  gST_pickup[MAXPLAYERS + 1];
QSRDonateInfo    gST_donateInfo[MAXPLAYERS + 1];
Database         gH_db      = null;
File             gH_logFile = null;

// Convars
ConVar gH_CVR_walletName = null;
ConVar gH_CVR_creditsName = null;
ConVar gH_CVR_giveCreditsAmount = null;
ConVar gH_CVR_giveCreditsInterval = null;
ConVar gH_CVR_dropModelS = null;
ConVar gH_CVR_dropModelM = null;
ConVar gH_CVR_dropModelL = null;
ConVar gH_CVR_dropModelBBx = null;
ConVar gH_CVR_dropCooldown = null;
ConVar gH_CVR_dropLifetime = null;
ConVar gH_CVR_minimumDrop = null;
ConVar gH_CVR_maximumDrop = null;
ConVar gH_CVR_minimumGive = null;
ConVar gH_CVR_maximumGive = null;

// Cookies
// TODO: create cookies for player settings.

public Plugin myinfo =
{
    name = "[QSR] Quasar Plugin Suite (Credit Handler)",
    author = PLUGIN_AUTHOR,
    description = "Description",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("quasar_bank");
    CreateNative("QSR_CreateCreditPickup", Native_QSRCreateCreditPickup);
    CreateNative("QSR_DonateCredits",      Native_QSRDonateCredits);
}

public void OnPluginStart()
{
    AutoExecConfig_SetFile("plugin.quasar_bank");

    gH_CVR_walletName           = AutoExecConfig_CreateConVar("sm_quasar_bank_wallet_name",         "wallet",                                   "What you want to call the player's wallet.",                                       FCVAR_NONE);
    gH_CVR_creditsName          = AutoExecConfig_CreateConVar("sm_quasar_bank_credit_name",         "credit",                                   "The singular version of what your server currency will be called.",                FCVAR_NONE);
    gH_CVR_giveCreditsAmount    = AutoExecConfig_CreateConVar("sm_quasar_bank_credit_amount",       "5",                                        "How many credits per credit interval to give to a player.",                        FCVAR_NONE);
    gH_CVR_giveCreditsInterval  = AutoExecConfig_CreateConVar("sm_quasar_bank_credit_interval",     "900",                                      "The length of time (in seconds) between adding credits to a player's account.",    FCVAR_NONE);
    gH_CVR_dropModelS           = AutoExecConfig_CreateConVar("sm_quasar_bank_drop_model_s",        "models/items/currencypack_small.mdl",      "The model used for currency drops less than 1000.",                                FCVAR_NONE);
    gH_CVR_dropModelM           = AutoExecConfig_CreateConVar("sm_quasar_bank_drop_model_m",        "models/items/currencypack_medium.mdl",     "The model used for currency drops less than 10000, greater than 1000",             FCVAR_NONE);
    gH_CVR_dropModelL           = AutoExecConfig_CreateConVar("sm_quasar_bank_drop_model_l",        "models/items/currencypack_large.mdl",      "The model used for currency drops greater than 10000",                             FCVAR_NONE);
    gH_CVR_dropModelBBx         = AutoExecConfig_CreateConVar("sm_quasar_bank_drop_bound_box",      "24.0 24.0 24.0",                           "The size of the small currency drop bounding box.",                                FCVAR_NONE);
    gH_CVR_dropCooldown         = AutoExecConfig_CreateConVar("sm_quasar_bank_drop_cooldown",       "120.0",                                    "The amount of time before a player can drop more credits.",                        FCVAR_NONE, true, 30.0);
    gH_CVR_dropLifetime         = AutoExecConfig_CreateConVar("sm_quasar_bank_drop_lifetime",       "30.0",                                     "The amount of time before the credit drop disappears.",                            FCVAR_NONE, true, 10.0);
    gH_CVR_minimumDrop          = AutoExecConfig_CreateConVar("sm_quasar_bank_drop_minimum",        "1",                                        "The minimum amount of credits a player can drop.",                                 FCVAR_NONE, true, 1.0);
    gH_CVR_maximumDrop          = AutoExecConfig_CreateConVar("sm_quasar_bank_drop_maximum",        "10000",                                    "The maximum amount of credits a player can drop.",                                 FCVAR_NONE, true, 1.0);
    gH_CVR_minimumGive          = AutoExecConfig_CreateConVar("sm_quasar_bank_donation_minimum",    "1",                                        "The minimum amount of credits a player can donate to another.",                    FCVAR_NONE, true, 1.0);
    gH_CVR_maximumGive          = AutoExecConfig_CreateConVar("sm_quasar_bank_donation_maximum",    "10000",                                    "The maximum amount of credits a player can donate to another.",                    FCVAR_NONE, true, 1.0);

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    LoadTranslations("quasar_core.phrases");
    LoadTranslations("quasar_players.phrases");
    LoadTranslations("quasar_bank.phrases");

    RegConsoleCmd("sm_dnte",        CMD_DonateCredits,  "Donate an amount of your credits to another player!")
    RegConsoleCmd("sm_donateto",    CMD_DonateCredits,  "Donate an amount of your credits to another player!");
    RegConsoleCmd("sm_giveto",      CMD_DonateCredits,  "Donate an amount of your credits to another player!");
    RegConsoleCmd("sm_drop",        CMD_DropCredits,    "Drop an amount of credits as a pickup for other players to get!");
    RegConsoleCmd("sm_dropc",       CMD_DropCredits,    "Drop an amount of credits as a pickup for other players to get!");
    RegConsoleCmd("sm_upgrade",     CMD_UpgradeTest,    "Upgrade shit");

    RegConsoleCmd("sm_balance", CMD_GetCredits, "Use this to check how many credits you have!")
    RegConsoleCmd("sm_credit",  CMD_GetCredits, "Use this to check how many credits you have!");
    RegConsoleCmd("sm_credits", CMD_GetCredits, "Use this to check how many credits you have!");
    RegConsoleCmd("sm_wallet",  CMD_GetCredits, "Use this to check how many credits you have!");

    RegAdminCmd("sm_qmodcred", CMD_ModCred, ADMFLAG_BAN, "Use this to give or take credits from a player.");
}

public void OnConfigsExecuted()
{
    gH_CVR_creditsName.GetString(gST_bankOptions.s_creditsName, sizeof(gST_bankOptions.s_creditsName));
    gH_CVR_walletName.GetString(gST_bankOptions.s_walletName, sizeof(gST_bankOptions.s_walletName));
    gH_CVR_dropModelS.GetString(gST_bankOptions.s_dropModelS, sizeof(gST_bankOptions.s_dropModelS));
    gH_CVR_dropModelM.GetString(gST_bankOptions.s_dropModelM, sizeof(gST_bankOptions.s_dropModelM));
    gH_CVR_dropModelL.GetString(gST_bankOptions.s_dropModelL, sizeof(gST_bankOptions.s_dropModelL));
    gST_bankOptions.i_giveAmount    = gH_CVR_giveCreditsAmount.IntValue;
    gST_bankOptions.f_giveInterval  = gH_CVR_giveCreditsInterval.FloatValue;
    gST_bankOptions.i_minimumDrop   = gH_CVR_minimumDrop.IntValue;
    gST_bankOptions.i_maximumDrop   = gH_CVR_maximumDrop.IntValue;
    gST_bankOptions.f_dropCooldown  = gH_CVR_dropCooldown.FloatValue;
    gST_bankOptions.f_dropLifetime  = gH_CVR_dropLifetime.FloatValue;
    gST_bankOptions.i_minimumDonation = gH_CVR_minimumGive.IntValue;
    gST_bankOptions.i_maximumDonation = gH_CVR_maximumGive.IntValue;

    char cmd[128], description[128];
    FormatEx(description, sizeof(description), "Use this to check how many %ss you have in your %s!", 
    gST_bankOptions.s_creditsName, gST_bankOptions.s_walletName);

    if (!StrEqual(gST_bankOptions.s_creditsName, "credit", false))
    {
        FormatEx(cmd, sizeof(cmd), "sm_%s", gST_bankOptions.s_creditsName);
        RegConsoleCmd(cmd, CMD_GetCredits, description);
    }

    if (!StrEqual(gST_bankOptions.s_walletName, "wallet", false))
    {
        FormatEx(cmd, sizeof(cmd), "sm_%s", gST_bankOptions.s_walletName);
        RegConsoleCmd(cmd, CMD_GetCredits, description);
    }

    PrecacheModel(TRIGGER_MODEL);
    PrecacheModel(gST_bankOptions.s_dropModelS);
    PrecacheModel(gST_bankOptions.s_dropModelM);
    PrecacheModel(gST_bankOptions.s_dropModelL);
}

public void OnClientPostAdminCheck(int client)
{
    gST_pickup[client].Reset();
    gST_donateInfo[client].Reset();
}

public void OnClientDisconnect_Post(int client)
{
    if (gST_pickup[client].i_modelEntRef != -1 && gST_pickup[client].i_textEntRef != -1) { QSR_ModPlayerCredits(gST_pickup[client].i_ownerID, gST_pickup[client].i_creditAmount); }
    gST_pickup[client].Reset();
    gST_donateInfo[client].Reset();
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

public void QSR_OnCreditsChanged(int userid, int amtGiven, int oldTotal, int newTotal, bool notify)
{
    int client = GetClientOfUserId(userid);
    char s_query[512], s_steam64ID[MAX_AUTHID_LENGTH];
    QSR_GetAuthId(userid, AuthId_SteamID64, s_steam64ID, sizeof(s_steam64ID));

    if (gH_db != null)
    {
        FormatEx(s_query, sizeof(s_query), "\
        UPDATE `str_playersbank` \
        SET `credits`=`credits`+'%d' \
        WHERE `steam_id`='%s'", amtGiven, s_steam64ID);
        QSR_LogQuery(gH_logFile, gH_db, s_query, SQLCB_DefaultCallback);

        if (amtGiven >= 0)
        {
            if (notify)
            {
                QSR_NotifyUser(userid, gST_sounds.s_addCreditsSound, "%T", "QSR_CreditsAdded", client, 
                gST_chatFormatting.s_creditColor, 
                amtGiven, 
                gST_bankOptions.s_creditsName,
                gST_chatFormatting.s_actionColor, 
                gST_chatFormatting.s_creditColor,
                gST_bankOptions.s_walletName, 
                gST_chatFormatting.s_actionColor, 
                gST_chatFormatting.s_creditColor, 
                newTotal,
                gST_bankOptions.s_creditsName);
            }
        }
        else
        {
            if (notify)
            {
                QSR_NotifyUser(userid, gST_sounds.s_addCreditsSound, "%T", "QSR_CreditsLost", client,
                gST_chatFormatting.s_creditColor, 
                amtGiven, 
                gST_bankOptions.s_creditsName,
                gST_chatFormatting.s_actionColor, 
                gST_chatFormatting.s_creditColor,
                gST_bankOptions.s_walletName, 
                gST_chatFormatting.s_actionColor, 
                gST_chatFormatting.s_creditColor, 
                newTotal,
                gST_bankOptions.s_creditsName);
            }
        }
    }
}

void QSR_SendDonateMenu(int mode, int client)
{
    switch (mode)
    {
        // Send player menu, then send credit menu
        case 0:
        {
            QSR_SendDonateMenu(1, client);
        }

        //  Sending credit menu
        case 1:
        {
            Menu h_donateMenu = new Menu(Handler_DonateCreditMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_DrawItem);

            char display[128];
            FormatEx(display, sizeof(display), "1 %s", gST_bankOptions.s_creditsName);
            h_donateMenu.AddItem("1", display);
            
            FormatEx(display, sizeof(display), "10 %ss", gST_bankOptions.s_creditsName);
            h_donateMenu.AddItem("10", display);

            FormatEx(display, sizeof(display), "50 %ss", gST_bankOptions.s_creditsName);
            h_donateMenu.AddItem("50", display);

            FormatEx(display, sizeof(display), "100 %ss", gST_bankOptions.s_creditsName);
            h_donateMenu.AddItem("100", display);

            FormatEx(display, sizeof(display), "500 %ss", gST_bankOptions.s_creditsName);
            h_donateMenu.AddItem("500", display);

            FormatEx(display, sizeof(display), "1000 %ss", gST_bankOptions.s_creditsName);
            h_donateMenu.AddItem("1000", display);

            FormatEx(display, sizeof(display), "5000 %ss", gST_bankOptions.s_creditsName);
            h_donateMenu.AddItem("5000", display);

            FormatEx(display, sizeof(display), "10000 %ss", gST_bankOptions.s_creditsName);
            h_donateMenu.AddItem("10000", display);

            h_donateMenu.Display(client, 20);
        }

        // Sending player menu
        case 2:
        {
            Menu h_donateMenu = new Menu(Handler_DonatePlayerMenu);

            int i_userid;
            for (int i = 1; i < MaxClients; i++)
            {
                if (!QSR_IsValidClient(i)) { continue; }

                i_userid = GetClientUserId(i);
                if (!QSR_IsPlayerFetched(i_userid)) { continue; }

                char s_info[32], s_display[128];
                IntToString(i_userid, s_info, sizeof(s_info));
                QSR_GetPlayerName(i_userid, s_display, sizeof(s_display));
                
                h_donateMenu.AddItem(s_info, s_display);
            }

            h_donateMenu.Display(client, 20);
        }
    }
}

// Natives

void Native_QSRDonateCredits(Handle plugin, int numParams)
{
    int i_donator       = GetNativeCell(1),
        i_donatorClient = GetClientOfUserId(i_donator), 
        i_donatee       = GetNativeCell(2), 
        i_donateeClient = GetClientOfUserId(i_donatee),
        i_amount        = GetNativeCell(3);

    if (!i_donator || !i_donatorClient || !i_donatee || !i_donateeClient) 
    { 
        ThrowNativeError(1, "(Donator / Donatee)'s (userid / client) index cannot be 0!"); 
        return;
    }

    char s_donatorName[MAX_NAME_LENGTH], s_donateeName[MAX_NAME_LENGTH];
    GetClientName(i_donatorClient, s_donatorName, sizeof(s_donatorName));
    GetClientName(i_donateeClient, s_donateeName, sizeof(s_donateeName));

    QSR_NotifyUser(i_donator, gST_sounds.s_buyItemSound, "%T", "QSR_PlayerDonatedFunds", i_donatorClient,
    gST_chatFormatting.s_successColor, gST_chatFormatting.s_creditColor, i_amount,
    gST_bankOptions.s_creditsName, gST_chatFormatting.s_successColor, s_donateeName);
    QSR_ModPlayerCredits(i_donator, -i_amount, false);

    QSR_NotifyUser(i_donatee, gST_sounds.s_buyItemSound, "%T", "QSR_PlayerRecievedDonation", i_donateeClient,
    gST_chatFormatting.s_infoColor, s_donatorName, gST_chatFormatting.s_creditColor, 
    i_amount, gST_bankOptions.s_creditsName, gST_chatFormatting.s_infoColor);
    QSR_ModPlayerCredits(i_donatee, i_amount, false);
}

any Native_QSRCreateCreditPickup(Handle plugin, int numParams)
{
    int i_userid = GetNativeCell(1), 
        i_client = GetClientOfUserId(i_userid), 
        i_creditAmount = GetNativeCell(2), 
        i_modelEntIndex,
        i_triggerEntIndex,
        i_textEntIndex;
    if (!QSR_IsValidClient(i_client) || !QSR_IsPlayerFetched(i_userid) || !i_client)
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Attempted to create a credit drop for invalid client %d!", i_client);
        return false;
    }

    if (gST_pickup[i_client].i_modelEntRef != -1 && gST_pickup[i_client].i_textEntRef != -1)
    {
        gST_pickup[i_client].CleanUp();
    }

    gST_pickup[i_client].i_ownerID = i_userid;
    gST_pickup[i_client].i_creditAmount = i_creditAmount;

    char  s_entityName[MAX_NAME_LENGTH];
    float f_pos[3];
    GetClientAbsOrigin(i_client, f_pos);

    i_modelEntIndex = CreateEntityByName("prop_dynamic");
    if (i_modelEntIndex != -1 && IsValidEdict(i_modelEntIndex))
    {
        FormatEx(s_entityName, sizeof(s_entityName), "qsrpickup_userid%d", i_userid);
        strcopy(gST_pickup[i_client].s_entityName, sizeof(gST_pickup[i_client].s_entityName), s_entityName);

        gST_pickup[i_client].i_modelEntRef= EntIndexToEntRef(i_modelEntIndex);
        DispatchKeyValue(i_modelEntIndex, "targetname", s_entityName);
        DispatchKeyValueInt(i_modelEntIndex, "rendermode", 8);
        
        if (i_creditAmount <= 0) { i_creditAmount = 1; }
        
        if      (i_creditAmount < 1000)                             { DispatchKeyValue(i_modelEntIndex, "model", gST_bankOptions.s_dropModelS); }
        else if (i_creditAmount >= 1000 && i_creditAmount < 10000)  { DispatchKeyValue(i_modelEntIndex, "model", gST_bankOptions.s_dropModelM); }
        else                                                        { DispatchKeyValue(i_modelEntIndex, "model", gST_bankOptions.s_dropModelL); }

        f_pos[2] += 4.0;
        TeleportEntity(i_modelEntIndex, f_pos);
        if (!DispatchSpawn(i_modelEntIndex))
        {
            QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to dispatch model spawn for %d's credit drop!", i_client);
            gST_pickup[i_client].Reset();
            QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_FailedToMakeCreditDrop", i_client, gST_chatFormatting.s_errorColor, "Failed to dispatch spawn for model");
            return false;
        }

        SetVariantString("idle");
        AcceptEntityInput(i_modelEntIndex, "SetAnimation");
    }
    else 
    {
        gST_pickup[i_client].Reset();
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to create prop_dynamic for %d's credit drop!", i_client);
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_FailedToMakeCreditDrop", i_client, gST_chatFormatting.s_errorColor, "Failed to create prop_dynamic");
        return false; 
    }

    i_textEntIndex = CreateEntityByName("point_worldtext");
    if (i_textEntIndex != -1)
    {
        gST_pickup[i_client].i_textEntRef = EntIndexToEntRef(i_textEntIndex);
        FormatEx(s_entityName, sizeof(s_entityName), "%s_text", s_entityName);
        DispatchKeyValue(i_textEntIndex, "targetname", s_entityName);
        DispatchKeyValueInt(i_textEntIndex, "font", 11);
        DispatchKeyValueInt(i_textEntIndex, "orientation", 2);
        DispatchKeyValueFloat(i_textEntIndex, "textsize", 6.0);

        char s_message[256], s_playerName[MAX_NAME_LENGTH];
        GetClientName(i_client, s_playerName, sizeof(s_playerName));
        FormatEx(s_message, sizeof(s_message), "%T", "QSR_CreditDropTextMessage", i_client, i_creditAmount);
        DispatchKeyValue(i_textEntIndex, "message", s_message);
        strcopy(gST_pickup[i_client].s_message, sizeof(gST_pickup[i_client].s_message), s_message);

        f_pos[2] += 32.0;
        TeleportEntity(i_textEntIndex, f_pos);
        if (!DispatchSpawn(i_textEntIndex))
        {
            QSR_LogMessage(gH_logFile, MODULE_NAME, "Failed to dispatch text spawn for %d's credit drop!", i_client);
            gST_pickup[i_client].Reset();
            QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_FailedToMakeCreditDrop", i_client, gST_chatFormatting.s_errorColor, "Failed to dispatch spawn for text")
            return false;
        }

        AcceptEntityInput(i_textEntIndex, "Enable");
        gST_pickup[i_client].f_timeLeft = gH_CVR_dropLifetime.FloatValue;
        gST_pickup[i_client].h_lifetimeTimer = CreateTimer(0.1, Timer_PickupLifetime, gST_pickup[i_client], TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
        gST_pickup[i_client].h_cooldownTimer = CreateTimer(0.1, Timer_PickupCooldown, gST_pickup[i_client], TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
    }
    else
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to create point_worldtext for %d's credit drop!", i_client);
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_FailedToMakeCreditDrop", i_client, gST_chatFormatting.s_errorColor, "Failed to create point_worldtext");
        gST_pickup[i_client].Reset();
        return false;
    }

    i_triggerEntIndex = CreateEntityByName("trigger_multiple");
    if (i_triggerEntIndex != -1)
    {
        char s_format[128];
        gST_pickup[i_client].i_triggerEntRef = EntIndexToEntRef(i_triggerEntIndex);
        FormatEx(s_format, sizeof(s_format), "%s_trigger", s_entityName);
        DispatchKeyValue(i_triggerEntIndex, "targetname", s_format);
        DispatchKeyValueInt(i_triggerEntIndex, "spawnflags", 1);
        DispatchKeyValueVector(i_triggerEntIndex, "origin", f_pos);

        TeleportEntity(i_triggerEntIndex, f_pos);
        if (!DispatchSpawn(i_triggerEntIndex))
        {
            QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to spawn trigger_multiple for %d's credit drop!", i_client);
            gST_pickup[i_client].Reset();
            QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_FailedToMakeCreditDrop", i_client, gST_chatFormatting.s_errorColor, "Failed to spawn trigger_multiple");
            return false;
        }

        DataPack pack = new DataPack();
        pack.WriteCell(i_triggerEntIndex);
        pack.WriteCell(i_client);
        CreateTimer(0.1, Timer_CreatePickupTrigger, pack, TIMER_DATA_HNDL_CLOSE);
    }
    else
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to create trigger_multiple for %d's credit drop!", i_client);
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_FailedToMakeCreditDrop", i_client, gST_chatFormatting.s_errorColor, "Failed to create trigger_multiple");
        gST_pickup[i_client].Reset();
        return false;
    }

    return true;
}

// Callbacks
void SQLCB_DefaultCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0])
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, error);
    }
}

void Timer_CreatePickupTrigger(Handle timer, DataPack info)
{
    info.Reset();
    int i_triggerEntIndex = info.ReadCell();
    int i_client = info.ReadCell();
    int i_userid = GetClientUserId(i_client);
    int effects = GetEntProp(i_triggerEntIndex, Prop_Send, "m_fEffects");
    char s_size[24], s_xyz[3][8];
    float f_mins[3], f_maxs[3];

    gH_CVR_dropModelBBx.GetString(s_size, sizeof(s_size));
    ExplodeString(s_size, " ", s_xyz, 3, 8);
    for (int i; i < 3; i++)
    {
        f_mins[i] = -StringToFloat(s_xyz[i]);
        f_maxs[i] = StringToFloat(s_xyz[i]);
    }

    effects |= 32
    SetEntProp(i_triggerEntIndex, Prop_Send, "m_fEffects", effects);
    SetEntProp(i_triggerEntIndex, Prop_Send, "m_nSolidType", 2);
    SetEntPropVector(i_triggerEntIndex, Prop_Send, "m_vecMins", f_mins);
    SetEntPropVector(i_triggerEntIndex, Prop_Send, "m_vecMaxs", f_maxs);

    SetEntityModel(i_triggerEntIndex, TRIGGER_MODEL);
    AcceptEntityInput(i_triggerEntIndex, "Enable");
    if (!SDKHookEx(i_triggerEntIndex, SDKHook_StartTouchPost, SDKHCB_PickupStartTouchPost))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "Unable to create StartTouchPost hook for %d's credit drop!", i_client);
        gST_pickup[i_client].Reset();
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_FailedToMakeCreditDrop", i_client, gST_chatFormatting.s_errorColor, "Failed to hook StartTouchPost");
        return;
    }

    CreateTimer(0.1, Timer_PickupCooldown, gST_pickup[i_client], TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_PickupLifetime(Handle timer, QSRCreditPickup pickup)
{
    if (pickup.f_timeLeft <= 0.0) 
    { 
        int i_client = GetClientOfUserId(pickup.i_ownerID);
        QSR_NotifyUser(pickup.i_ownerID, gST_sounds.s_infoSound, "%t", "QSR_CreditDropDisappeared",
        gST_chatFormatting.s_defaultColor, gST_chatFormatting.s_creditColor,
        gST_pickup[i_client].i_creditAmount, gST_bankOptions.s_creditsName, 
        gST_chatFormatting.s_defaultColor, gST_chatFormatting.s_creditColor, 
        gST_bankOptions.s_walletName, gST_chatFormatting.s_defaultColor);
        QSR_ModPlayerCredits(pickup.i_ownerID, pickup.i_creditAmount, false);
        pickup.Reset(); 

        return Plugin_Stop; 
    }

    int i_modelIndex = EntRefToEntIndex(pickup.i_modelEntRef);
    int i_textIndex = EntRefToEntIndex(pickup.i_textEntRef);

    if (i_modelIndex == -1 || i_textIndex == -1)
    { 
        pickup.Reset(); 
        return Plugin_Stop;
    }

    char s_message[256];
    FormatEx(s_message, sizeof(s_message), "%s%.2f", pickup.s_message, pickup.f_timeLeft);
    SetVariantString(s_message);
    AcceptEntityInput(i_textIndex, "SetText");
    pickup.f_timeLeft -= 0.1; 
    
    if (pickup.f_timeLeft <= (gH_CVR_dropLifetime.FloatValue * 0.25) && (RoundToFloor(pickup.f_timeLeft) % 2.0) == 0)
    {
        pickup.b_isTransparent = !pickup.b_isTransparent;
        if (pickup.b_isTransparent) { DispatchKeyValueInt(i_modelIndex, "renderamt", 128); }
        else                        { DispatchKeyValueInt(i_modelIndex, "renderamt", 255); }
    }

    return Plugin_Continue;
}

Action Timer_PickupCooldown(Handle timer, QSRCreditPickup pickup)
{
    if (!pickup.OnCooldown()) 
    {
        pickup.h_cooldownTimer = INVALID_HANDLE;
        return Plugin_Stop; 
    }

    pickup.f_cooldown -= 0.1;
    return Plugin_Continue;
}

void SDKHCB_PickupStartTouchPost(int entity, int other)
{
    if (other > MaxClients || !QSR_IsValidClient(other)) { return; }

    int i_userid = GetClientUserId(other);
    if (!QSR_IsPlayerFetched(i_userid))
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%t", "QSR_CreditsNotFetched", 
        gST_chatFormatting.s_errorColor, gST_bankOptions.s_creditsName,
        gST_chatFormatting.s_commandColor, gST_chatFormatting.s_errorColor);
        return;
    }

    if (IsValidEntity(entity))
    {
        char s_entityName[128]
        GetEntPropString(entity, Prop_Data, "m_iName", s_entityName, sizeof(s_entityName));
        ReplaceStringEx(s_entityName, sizeof(s_entityName), "qsrpickup_userid", "");
        ReplaceStringEx(s_entityName, sizeof(s_entityName), "_text_trigger", "");

        int i_pickupOwner = StringToInt(s_entityName), i_pickupOwnerClient = GetClientOfUserId(i_pickupOwner);
        if (!QSR_IsValidClient(i_pickupOwnerClient))
        {
            QSR_LogMessage(gH_logFile, MODULE_NAME, "UserID %d is no longer connected. Deleting pickup.", gST_pickup[i_pickupOwnerClient].i_ownerID);
            QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%t", "QSR_PickupPlayerNotConnected", gST_chatFormatting.s_errorColor);
            
            for (int i = 1; i < MaxClients; i++)
            {
                if (gST_pickup[i].i_triggerEntRef == EntIndexToEntRef(entity))
                {
                    gST_pickup[i].Reset();
                    break;
                }
            }
            return;
        }

        if (i_userid == i_pickupOwner && (gST_pickup[i_pickupOwnerClient].f_timeLeft >= (gH_CVR_dropLifetime.FloatValue * 0.8)) )
        {
            QSR_PrintToChat(i_userid, "%T", "QSR_OwnerCannotPickupYet", other, 
            gST_chatFormatting.s_warnColor, gST_pickup[i_pickupOwnerClient].f_timeLeft - (gH_CVR_dropLifetime.FloatValue * 0.8));
            return;
        }

        QSR_ModPlayerCredits(i_userid, gST_pickup[i_pickupOwnerClient].i_creditAmount);
        gST_pickup[i_pickupOwnerClient].Reset();
    }
}

int Handler_DonatePlayerMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int i_userid, i_donateeid;
            char s_playerid[32];
            menu.GetItem(param2, s_playerid, sizeof(s_playerid));
            i_userid = GetClientUserId(param1);
            i_donateeid = StringToInt(s_playerid);

            if (gST_donateInfo[param1].i_amount != -1)  { QSR_DonateCredits(i_userid, i_donateeid, gST_donateInfo[param1].i_amount); }
            else                                        { QSR_SendDonateMenu(1, param1); }
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

int Handler_DonateCreditMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_DrawItem:
        {
            char s_amt[32];
            int  i_userid, i_amt, i_style;

            i_userid = GetClientUserId(param1);
            menu.GetItem(param2, s_amt, sizeof(s_amt), i_style);
            i_amt = StringToInt(s_amt);

            if (QSR_GetPlayerCredits(i_userid) < i_amt) { return ITEMDRAW_DISABLED; }
            else                                        { return i_style; }
        }

        case MenuAction_Select:
        {
            char s_amt[32]; 
            int  i_userid, i_amt;

            i_userid = GetClientUserId(param1);
            menu.GetItem(param2, s_amt, sizeof(s_amt));
            i_amt = StringToInt(s_amt);

            if (!i_amt) { i_amt = 1; }
            gST_donateInfo[param1].i_amount = i_amt;

            if (gST_donateInfo[param1].i_donatee != -1)     { QSR_DonateCredits(i_userid, gST_donateInfo[param1].i_donatee, i_amt); }
            else                                            { QSR_SendDonateMenu(2, param1); }
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

int Handler_DropCreditMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_DrawItem:
        {
            char s_amt[32];
            int  i_userid, i_amt, i_style;

            i_userid = GetClientUserId(param1);
            menu.GetItem(param2, s_amt, sizeof(s_amt), i_style);
            i_amt = StringToInt(s_amt);

            if (QSR_GetPlayerCredits(i_userid) < i_amt) { return ITEMDRAW_DISABLED; }
            else                                        { return i_style; }
        }

        case MenuAction_Select:
        {
            char s_amt[32];
            int  i_amt, i_userid;

            i_userid = GetClientUserId(param1);

            menu.GetItem(param2, s_amt, sizeof(s_amt));
            i_amt = StringToInt(s_amt);

            QSR_ModPlayerCredits(i_userid, -i_amt, false);
            QSR_NotifyUser(i_userid, gST_sounds.s_addCreditsSound, "%T", "QSR_DroppedCredits", param1,
            gST_chatFormatting.s_successColor, gST_chatFormatting.s_creditColor, 
            i_amt, gST_bankOptions.s_creditsName, gST_chatFormatting.s_successColor);
            QSR_CreateCreditPickup(i_userid, i_amt);
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

// Commands

//** sm_credits */
Action CMD_GetCredits(int client, int args)
{
    if (!QSR_IsValidClient(client) || !client) { return Plugin_Handled; }
    int userid = GetClientUserId(client);

    if (!QSR_IsPlayerFetched(userid))
    {
        QSR_LogMessage(gH_logFile, MODULE_NAME, "userid %d has not been fetched from DB yet, cannot get player credits.", userid);
        QSR_NotifyUser(userid, gST_sounds.s_errorSound, "%T", "QSR_CreditsNotFetched", client,
        gST_chatFormatting.s_errorColor, gST_bankOptions.s_creditsName,
        gST_chatFormatting.s_commandColor, gST_chatFormatting.s_errorColor);
        return Plugin_Handled;
    }

    int credits = QSR_GetPlayerCredits(userid);
    QSR_PrintToChat(userid, "%T", "QSR_PrintPlayerCredits", client,
    gST_chatFormatting.s_infoColor, gST_chatFormatting.s_creditColor,
    credits, gST_bankOptions.s_creditsName, gST_chatFormatting.s_infoColor, 
    gST_chatFormatting.s_creditColor, gST_bankOptions.s_walletName, gST_chatFormatting.s_infoColor);

    return Plugin_Handled;
}

//** sm_donateto (name) (amount) */
Action CMD_DonateCredits(int client, int args)
{
    if (!QSR_IsValidClient(client) || !client) { return Plugin_Handled; }
    
    int i_userid = GetClientUserId(client);
    int i_credits = QSR_GetPlayerCredits(i_userid);

    if (!QSR_CheckForUpgrade(i_userid, QSRUpgrade_DropCredits))
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_NeedDonateUpgrade", client,
        gST_chatFormatting.s_errorColor, gST_chatFormatting.s_commandColor);
        return Plugin_Handled;
    }

    if (i_credits <= 0)
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_NoFunds", client,
        gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gST_bankOptions.s_creditsName, gST_chatFormatting.s_errorColor);
        return Plugin_Handled;
    }

    switch (args)
    {
        // Send player menu AND credit menu
        case 0:
        {
            QSR_SendDonateMenu(0, client);
        }

        // Send player menu, OR credit menu.
        case 1:
        {
            char s_arg[128];
            GetCmdArg(1, s_arg, sizeof(s_arg));

            // User chose someone to donate to.
            if (!StringToInt(s_arg))
            {
                int i_donateeUserID = QSR_FindPlayerByName(s_arg);
                if (i_donateeUserID == -1)
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_InvalidTarget", client,
                    gST_chatFormatting.s_errorColor, s_arg);
                    return Plugin_Handled;
                }

                gST_donateInfo[client].i_donatee = i_donateeUserID;
                QSR_SendDonateMenu(1, client);
            }

            // User chose an amount to donate.
            else
            {
                int i_amt = StringToInt(s_arg);
                if (!i_amt) { i_amt = 1; }

                if (i_credits < i_amt)
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_InsufficientFunds", client,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gST_bankOptions.s_creditsName,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, i_credits, gST_bankOptions.s_creditsName,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, i_amt, gST_bankOptions.s_creditsName);
                
                    return Plugin_Handled;
                }

                gST_donateInfo[client].i_amount = i_amt;
                QSR_SendDonateMenu(2, client);
            }
        }

        // Send neither.
        case 2:
        {
            char s_arg1[128], s_arg2[128];
            GetCmdArg(1, s_arg1, sizeof(s_arg1));
            GetCmdArg(2, s_arg2, sizeof(s_arg2));

            // First argument is amount of credits
            if (!StringToInt(s_arg2))
            {
                int i_donateeUserID = QSR_FindPlayerByName(s_arg2),
                    i_donateeClient = GetClientOfUserId(i_donateeUserID),
                    i_amt           = StringToInt(s_arg1);

                if (i_donateeUserID == -1)
                {
                    switch(QSR_IsStringAuthId(s_arg1))
                    {
                        case AuthId_Steam2:     { i_donateeUserID = QSR_FindPlayerByAuthId(AuthId_Steam2, s_arg1); }
                        case AuthId_Steam3:     { i_donateeUserID = QSR_FindPlayerByAuthId(AuthId_Steam3, s_arg1); }
                        case AuthId_SteamID64:  { i_donateeUserID = QSR_FindPlayerByAuthId(AuthId_SteamID64, s_arg1); }
                    }

                    i_donateeClient = GetClientOfUserId(i_donateeUserID);
                }

                if (!QSR_IsPlayerFetched(i_donateeUserID) || !QSR_IsValidClient(i_donateeClient))
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_InvalidTarget", client,
                    gST_chatFormatting.s_errorColor, s_arg2);
                    
                    return Plugin_Handled;
                }

                if (i_amt > gH_CVR_maximumGive.IntValue && (gH_CVR_maximumGive.IntValue != -1))
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_OverMaximumDonation", client,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gH_CVR_maximumGive.IntValue,
                    gST_bankOptions.s_creditsName, gST_chatFormatting.s_errorColor);

                    return Plugin_Handled;
                }

                if (i_amt < gH_CVR_minimumGive.IntValue && (gH_CVR_minimumGive.IntValue != 0))
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_UnderMinimumDonation", client,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gH_CVR_maximumGive.IntValue,
                    gST_bankOptions.s_creditsName, gST_chatFormatting.s_errorColor);

                    return Plugin_Handled;
                }

                if (i_credits < i_amt)
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_InsufficientFunds", client,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gST_bankOptions.s_creditsName,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, i_credits, gST_bankOptions.s_creditsName,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, i_amt, gST_bankOptions.s_creditsName);

                    return Plugin_Handled;
                }

                if (!i_amt) { i_amt = 1; }

                QSR_DonateCredits(i_userid, i_donateeUserID, i_amt);
            }

            // First argument is a player.
            else
            {
                int i_donateeUserID = QSR_FindPlayerByName(s_arg1),
                    i_donateeClient = GetClientOfUserId(i_donateeUserID),
                    i_amt           = StringToInt(s_arg2);

                if (i_donateeUserID == -1)
                {
                    switch(QSR_IsStringAuthId(s_arg1))
                    {
                        case AuthId_Steam2:     { i_donateeUserID = QSR_FindPlayerByAuthId(AuthId_Steam2, s_arg1); }
                        case AuthId_Steam3:     { i_donateeUserID = QSR_FindPlayerByAuthId(AuthId_Steam3, s_arg1); }
                        case AuthId_SteamID64:  { i_donateeUserID = QSR_FindPlayerByAuthId(AuthId_SteamID64, s_arg1); }
                    }

                    i_donateeClient = GetClientOfUserId(i_donateeUserID)
                }

                if (!QSR_IsPlayerFetched(i_donateeUserID) || !QSR_IsValidClient(i_donateeClient) || i_userid == i_donateeUserID)
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_InvalidTarget", client,
                    gST_chatFormatting.s_errorColor, s_arg1);
                    
                    return Plugin_Handled;
                }

                if (i_amt > gH_CVR_maximumGive.IntValue && (gH_CVR_maximumGive.IntValue != -1))
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_OverMaximumDonation", client,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gH_CVR_maximumGive.IntValue,
                    gST_bankOptions.s_creditsName, gST_chatFormatting.s_errorColor);

                    return Plugin_Handled;
                }

                if (i_amt < gH_CVR_minimumGive.IntValue && (gH_CVR_minimumGive.IntValue != 0))
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_UnderMinimumDonation", client,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gH_CVR_maximumGive.IntValue,
                    gST_bankOptions.s_creditsName, gST_chatFormatting.s_errorColor);

                    return Plugin_Handled;
                }

                if (i_credits < i_amt)
                {
                    QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_InsufficientFunds", client,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gST_bankOptions.s_creditsName,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, i_credits, gST_bankOptions.s_creditsName,
                    gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, i_amt, gST_bankOptions.s_creditsName);
                
                    return Plugin_Handled;
                }

                if (!i_amt) { i_amt = 1; }

                QSR_DonateCredits(i_userid, i_donateeUserID, i_amt);
            }
        }
    }

    return Plugin_Handled;
}

Action CMD_UpgradeTest(int client, int args)
{
    int userid = GetClientUserId(client);
    if (!QSR_IsValidClient(client) || !QSR_IsPlayerFetched(userid) || !client) { return Plugin_Handled; }

    QSR_AddUpgrade(userid, QSRUpgrade_DonateCredits);
    QSR_AddUpgrade(userid, QSRUpgrade_DropCredits);
    return Plugin_Handled;
}

//** sm_drop (amount) */
Action CMD_DropCredits(int client, int args)
{
    if (!QSR_IsValidClient(client) || !client) { return Plugin_Handled; }
    
    int i_userid = GetClientUserId(client);
    int i_credits = QSR_GetPlayerCredits(i_userid);

    if (!QSR_CheckForUpgrade(i_userid, QSRUpgrade_DropCredits))
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_NeedDropUpgrade", client,
        gST_chatFormatting.s_errorColor, gST_chatFormatting.s_commandColor);
        return Plugin_Handled;
    }

    if (i_credits <= 0)
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_NoFunds", client,
        gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gST_bankOptions.s_creditsName, gST_chatFormatting.s_errorColor);
        return Plugin_Handled;
    }

    if (gST_pickup[client].OnCooldown()) 
    { 
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_PickupOnCooldown", client,
        gST_chatFormatting.s_errorColor, gST_pickup[client].f_cooldown);
        return Plugin_Handled; 
    }

    if (args == 0)
    {
        Menu h_dropCreditMenu = new Menu(Handler_DropCreditMenu, MenuAction_Select|MenuAction_Cancel|MenuAction_End|MenuAction_DrawItem);
        h_dropCreditMenu.SetTitle("%T", "QSR_CreditDropMenuTitle", client, gST_bankOptions.s_creditsName);
        
        // I tried to use a loop to do this but I kept getting crashes
        // Something due to bad_alloc, but I couldn't see what the issue was.
        char display[128];
        FormatEx(display, sizeof(display), "1 %s", gST_bankOptions.s_creditsName);
        h_dropCreditMenu.AddItem("1", display);
        
        FormatEx(display, sizeof(display), "10 %ss", gST_bankOptions.s_creditsName);
        h_dropCreditMenu.AddItem("10", display);

        FormatEx(display, sizeof(display), "50 %ss", gST_bankOptions.s_creditsName);
        h_dropCreditMenu.AddItem("50", display);

        FormatEx(display, sizeof(display), "100 %ss", gST_bankOptions.s_creditsName);
        h_dropCreditMenu.AddItem("100", display);

        FormatEx(display, sizeof(display), "500 %ss", gST_bankOptions.s_creditsName);
        h_dropCreditMenu.AddItem("500", display);

        FormatEx(display, sizeof(display), "1000 %ss", gST_bankOptions.s_creditsName);
        h_dropCreditMenu.AddItem("1000", display);

        FormatEx(display, sizeof(display), "5000 %ss", gST_bankOptions.s_creditsName);
        h_dropCreditMenu.AddItem("5000", display);

        FormatEx(display, sizeof(display), "10000 %ss", gST_bankOptions.s_creditsName);
        h_dropCreditMenu.AddItem("10000", display);

        h_dropCreditMenu.Display(client, 20);
        return Plugin_Handled;
    }

    int  i_amtToDrop;
    char s_arg[8];
    GetCmdArg(1, s_arg, sizeof(s_arg));
    i_amtToDrop = StringToInt(s_arg);
    
    if (!i_amtToDrop)
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_CannotDropZero", client,
        gST_chatFormatting.s_errorColor, gST_bankOptions.s_creditsName);
        return Plugin_Handled;
    }

    if (i_amtToDrop < gH_CVR_minimumDrop.IntValue)
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_DropAmountTooSmall", client,
        gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor,
        gH_CVR_minimumDrop.IntValue, gST_bankOptions.s_creditsName, gST_chatFormatting.s_errorColor);
        return Plugin_Handled;
    }

    if (i_amtToDrop > gH_CVR_maximumDrop.IntValue)
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_DropAmountTooLarge", client,
        gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor,
        gH_CVR_maximumDrop.IntValue, gST_bankOptions.s_creditsName, gST_chatFormatting.s_errorColor);
        return Plugin_Handled;
    }

    if (i_amtToDrop > i_credits)
    {
        QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_InsufficientFunds", client,
        gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, gST_bankOptions.s_creditsName,
        gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, i_credits, gST_bankOptions.s_creditsName,
        gST_chatFormatting.s_errorColor, gST_chatFormatting.s_creditColor, i_amtToDrop, gST_bankOptions.s_creditsName);

        return Plugin_Handled;
    }

    QSR_ModPlayerCredits(i_userid, -i_amtToDrop, false);
    QSR_NotifyUser(i_userid, gST_sounds.s_addCreditsSound, "%T", "QSR_DroppedCredits", client,
    gST_chatFormatting.s_successColor, gST_chatFormatting.s_creditColor, 
    i_amtToDrop, gST_bankOptions.s_creditsName, gST_chatFormatting.s_successColor);
    QSR_CreateCreditPickup(i_userid, i_amtToDrop);
    return Plugin_Handled;
}


//** sm_modcred <name/amount> <name/amount> */
Action CMD_ModCred(int client, int args)
{
    int i_userid = GetClientUserId(client);

    char s_arg1[128];
    char s_arg2[128];
    GetCmdArg(1, s_arg1, sizeof(s_arg1));
    GetCmdArg(2, s_arg2, sizeof(s_arg2));

    // First argument is a player
    if (!StringToInt(s_arg1))
    {
        int i_targetUser   = QSR_FindPlayerByName(s_arg1),
            i_targetClient = GetClientOfUserId(i_targetUser),
            i_amt          = StringToInt(s_arg2);

        if (i_targetUser == -1)
        {
            switch(QSR_IsStringAuthId(s_arg1))
            {
                case AuthId_Steam2:     { i_targetUser = QSR_FindPlayerByAuthId(AuthId_Steam2, s_arg1); }
                case AuthId_Steam3:     { i_targetUser = QSR_FindPlayerByAuthId(AuthId_Steam3, s_arg1); }
                case AuthId_SteamID64:  { i_targetUser = QSR_FindPlayerByAuthId(AuthId_SteamID64, s_arg1); }
            }

            QSR_ModPlayerCredits(i_targetUser, i_amt);
        }
        
        if (!QSR_IsValidClient(i_targetClient) || !QSR_IsPlayerFetched(i_targetUser) || !i_targetUser || !i_targetClient)
        {
            QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_InvalidTarget", client,
            gST_chatFormatting.s_errorColor, s_arg1);
            return Plugin_Handled;
        }

        if (i_amt == 0) { i_amt = 1; }

        char s_playerName[MAX_NAME_LENGTH];
        GetClientName(i_targetClient, s_playerName, sizeof(s_playerName));

        QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%T", "QSR_GrantedCredits", client,
        gST_chatFormatting.s_infoColor, gST_chatFormatting.s_creditColor, i_amt,
        gST_bankOptions.s_creditsName, gST_chatFormatting.s_infoColor, s_playerName);
        QSR_ModPlayerCredits(i_targetUser, i_amt);
    }

    // Second argument is a player
    else
    {
        int i_targetUser   = QSR_FindPlayerByName(s_arg2),
            i_targetClient = GetClientOfUserId(i_targetUser),
            i_amt          = StringToInt(s_arg1);

        if (i_targetUser == -1)
        {
            switch(QSR_IsStringAuthId(s_arg2))
            {
                case AuthId_Steam2:     { i_targetUser = QSR_FindPlayerByAuthId(AuthId_Steam2, s_arg2); }
                case AuthId_Steam3:     { i_targetUser = QSR_FindPlayerByAuthId(AuthId_Steam3, s_arg2); }
                case AuthId_SteamID64:  { i_targetUser = QSR_FindPlayerByAuthId(AuthId_SteamID64, s_arg2); }
            }

            i_targetClient = GetClientOfUserId(i_targetUser);
            QSR_ModPlayerCredits(i_targetUser, i_amt);
        }
        
        if (!QSR_IsValidClient(i_targetClient) || !QSR_IsPlayerFetched(i_targetClient) || !i_targetUser || !i_targetClient)
        {
            QSR_NotifyUser(i_userid, gST_sounds.s_errorSound, "%T", "QSR_InvalidTarget", client,
            gST_chatFormatting.s_errorColor, s_arg1);
            return Plugin_Handled;
        }

        if (!i_amt) { i_amt = 1; }

        char s_playerName[MAX_NAME_LENGTH], s_adminName[MAX_NAME_LENGTH], s_authID[MAX_AUTHID_LENGTH];
        GetClientName(i_targetClient, s_playerName, sizeof(s_playerName));
        GetClientName(client, s_adminName, sizeof(s_adminName));
        GetClientAuthId(client, AuthId_SteamID64, s_authID, sizeof(s_authID));

        if (i_amt > 0)
        {
            QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%T", "QSR_NotifyAdminGrantedCredits", client,
            gST_chatFormatting.s_infoColor, gST_chatFormatting.s_creditColor, i_amt,
            gST_bankOptions.s_creditsName, gST_chatFormatting.s_infoColor, s_playerName);

            QSR_NotifyUser(i_targetUser, gST_sounds.s_addCreditsSound, "%T", "QSR_AdminGrantedYouCredits", i_targetClient,
            gST_chatFormatting.s_infoColor, gST_chatFormatting.s_creditColor, i_amt,
            gST_bankOptions.s_creditsName, gST_chatFormatting.s_infoColor);
        }
        else
        {
            QSR_NotifyUser(i_userid, gST_sounds.s_infoSound, "%T", "QSR_NotifyAdminRemovedCredits", client,
            gST_chatFormatting.s_infoColor, gST_chatFormatting.s_creditColor, i_amt,
            gST_bankOptions.s_creditsName, gST_chatFormatting.s_infoColor, s_playerName,
            gST_chatFormatting.s_creditColor, gST_bankOptions.s_walletName, gST_chatFormatting.s_infoColor);

            QSR_NotifyUser(i_targetUser, gST_sounds.s_addCreditsSound, "%T", "QSR_AdminRemovedYourCredits", i_targetClient,
            gST_chatFormatting.s_infoColor, gST_chatFormatting.s_creditColor, i_amt,
            gST_bankOptions.s_creditsName, gST_chatFormatting.s_infoColor, gST_chatFormatting.s_creditColor,
            gST_bankOptions.s_walletName, gST_chatFormatting.s_infoColor);
        }

        QSR_LogMessage(gH_logFile, MODULE_NAME, "Admin %s (%s) gave %s %d %s(2)", s_adminName, s_authID, s_playerName, i_amt, gST_bankOptions.s_creditsName);
        QSR_ModPlayerCredits(i_targetUser, i_amt, false);
    }

    return Plugin_Handled;
}