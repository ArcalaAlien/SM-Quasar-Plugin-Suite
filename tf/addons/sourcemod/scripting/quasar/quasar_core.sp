#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <multicolors>
#include <autoexecconfig>
#include <ripext>
#include <SteamWorks>

#include <quasar/core>

//General
bool gB_late = false;
QSRChatFormat gST_chatFormatStrings;
QSRGeneralSounds gST_sounds;
Handle  gH_checkGameUpdateTimer = null;

static File gH_logFile = null;

// Forwards
Handle gH_FWD_logCreated = null; // Called when the log file has been created sucessfully.
Handle gH_FWD_chatFormatRetrieved = null;
Handle gH_FWD_soundsRetrieved = null;

// ConVars
ConVar gH_CVR_logFile = null;
ConVar gH_CVR_skipEndingScoreboard = null;

ConVar gH_CVR_chatPrefix = null;
ConVar gH_CVR_defaultColor = null;
ConVar gH_CVR_successColor = null;
ConVar gH_CVR_errorColor = null;
ConVar gH_CVR_warnColor = null;
ConVar gH_CVR_actionColor = null;
ConVar gH_CVR_infoColor = null;
ConVar gH_CVR_commandColor = null;
ConVar gH_CVR_creditColor = null;

ConVar gH_CVR_afkWarnSound = null;
ConVar gH_CVR_afkMoveSound = null;
ConVar gH_CVR_errorSound = null;
ConVar gH_CVR_loginSound = null;
ConVar gH_CVR_addCreditsSound = null;
ConVar gH_CVR_buyItemSound = null;
ConVar gH_CVR_infoSound = null;

// Cookies
// TODO: create cookies for player settings.

public Plugin myinfo =
{
    name = "[QUASAR] Quasar Plugin Suite (Core)",
    author = PLUGIN_AUTHOR,
    description = "Contains core methods and data shared between Quasar plugin suite.",
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("quasar_core");
    CreateNative("QSR_PrintToChat",             Native_QSRPrintToChat);
    CreateNative("QSR_PrintToChatAll",          Native_QSRPrintToChatAll);
    CreateNative("QSR_PrintCenterTextEx",       Native_QSRPrintCenterTextEx);
    CreateNative("QSR_PrintCenterTextAllEx",    Native_QSRPrintCenterTextAllEx);
    CreateNative("QSR_NotifyUser",              Native_QSRNotifyUser);
    CreateNative("QSR_LogMessage",              Native_QSRLogMessage);
    CreateNative("QSR_SilentLog",               Native_QSRSilentLog);
    CreateNative("QSR_ThrowError",              Native_QSRThrowError);

    gB_late = late;
}

public void OnPluginStart()
{
    // Forwards

    gH_FWD_logCreated = CreateGlobalForward("QSR_OnLogFileMade", ET_Ignore, Param_CellByRef);
    gH_FWD_chatFormatRetrieved = CreateGlobalForward("QSR_OnSystemFormattingRetrieved", ET_Ignore, Param_Cell);
    gH_FWD_soundsRetrieved = CreateGlobalForward("QSR_OnSystemSoundsRetrieved", ET_Ignore, Param_Cell);

    // AutoExecConfig Setup
    AutoExecConfig_SetFile("plugin.quasar_core");
    gH_CVR_logFile              = AutoExecConfig_CreateConVar("sm_quasar_logfile",              "logs/quasar-logs", "The default file to store queries and messages from the plugin suite, relative to the sourcemod folder. Leave off the file extension.", FCVAR_NONE);

    // Chat Options
    gH_CVR_chatPrefix           = AutoExecConfig_CreateConVar("sm_quasar_msg_prefix",           "{mediumorchid}[{turquoise}QSR{mediumorchid}] ", "The prefix the plugin uses when sending messages to chat. 64 chars max.", FCVAR_NONE);
    gH_CVR_defaultColor         = AutoExecConfig_CreateConVar("sm_quasar_default_text_color",   "{default}",                        "", FCVAR_NONE);
    gH_CVR_successColor         = AutoExecConfig_CreateConVar("sm_quasar_success_text_color",   "{green}",                          "", FCVAR_NONE);
    gH_CVR_errorColor           = AutoExecConfig_CreateConVar("sm_quasar_error_text_color",     "{red}",                            "", FCVAR_NONE);
    gH_CVR_warnColor            = AutoExecConfig_CreateConVar("sm_quasar_warn_text_color",      "{orange}",                         "", FCVAR_NONE);
    gH_CVR_actionColor          = AutoExecConfig_CreateConVar("sm_quasar_action_text_color",    "{gold}",                           "", FCVAR_NONE);
    gH_CVR_infoColor            = AutoExecConfig_CreateConVar("sm_quasar_info_text_color",      "{royalblue}",                      "", FCVAR_NONE);
    gH_CVR_commandColor         = AutoExecConfig_CreateConVar("sm_quasar_command_text_color",   "{greenyellow}",                    "", FCVAR_NONE);
    gH_CVR_creditColor          = AutoExecConfig_CreateConVar("sm_quasar_credit_text_color",    "{yellow}",                         "", FCVAR_NONE);

    // Sound options
    gH_CVR_afkWarnSound         = AutoExecConfig_CreateConVar("sm_quasar_afk_warn_sound",       "",              "Controls the sound played when Quasar sends a warning to a player about to be afk. Searches in the tf/sound folder.", FCVAR_NONE);
    gH_CVR_afkMoveSound         = AutoExecConfig_CreateConVar("sm_quasar_afk_move_sound",       "",              "Controls the sound played when Quasar marks a player as AFK. Searches in the tf/sound folder.", FCVAR_NONE);
    gH_CVR_errorSound           = AutoExecConfig_CreateConVar("sm_quasar_error_sound",          "",              "Controls the sound played to let the user know an error has occured. Searches in tf/sound.", FCVAR_NONE);
    gH_CVR_loginSound           = AutoExecConfig_CreateConVar("sm_quasar_login_sound",          "",              "Controls the sound played when a user logs into the server. Searches in the tf/sound folder.", FCVAR_NONE);
    gH_CVR_addCreditsSound      = AutoExecConfig_CreateConVar("sm_quasar_add_credits_sound",    "",              "Controls the sound played when a user gains credits. Searches in the tf/sound folder.", FCVAR_NONE);
    gH_CVR_buyItemSound         = AutoExecConfig_CreateConVar("sm_quasar_buy_item_sound",       "",              "Controls the sound played when a user buys an item from the store. Searches in the tf/sound folder.", FCVAR_NONE);
    gH_CVR_infoSound            = AutoExecConfig_CreateConVar("sm_quasar_info_sound",           "",              "Controls the sound played to alert the user of something. Usually the results of an action they have taken. Searches in the tf/sound folder.", FCVAR_NONE);

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    LoadTranslations("quasar_core.phrases");
    LoadTranslations("quasar_item.phrases")

    // Commands
    RegConsoleCmd("sm_qsettings", CMD_OpenSettingsMenu);
    RegConsoleCmd("sm_qset", CMD_OpenSettingsMenu);
}

public void OnPluginEnd()
{
    if (gH_checkGameUpdateTimer != null)
    {
        KillTimer(gH_checkGameUpdateTimer);
        gH_checkGameUpdateTimer = null;
    }

    gST_chatFormatStrings.Empty();
    gST_sounds.Empty();

    gH_logFile.Close();
    gH_CVR_skipEndingScoreboard.Close();

    // Chat
    gH_CVR_chatPrefix.Close();
    gH_CVR_defaultColor.Close();
    gH_CVR_successColor.Close();
    gH_CVR_errorColor.Close();
    gH_CVR_warnColor.Close();
    gH_CVR_actionColor.Close();
    gH_CVR_infoColor.Close();
    gH_CVR_commandColor.Close();

    // Sound
    gH_CVR_afkWarnSound.Close();
    gH_CVR_afkMoveSound.Close();
    gH_CVR_errorSound.Close();
    gH_CVR_loginSound.Close();
    gH_CVR_addCreditsSound.Close();
    gH_CVR_buyItemSound.Close();
    gH_CVR_infoSound.Close();

    gH_FWD_logCreated.Close();
}

public void OnConfigsExecuted()
{
    // Log File.
    char s_logPath[256], s_logPathCVAR[256], s_time[32];
    gH_CVR_logFile.GetString(s_logPathCVAR, sizeof(s_logPathCVAR));
    FormatTime(s_time, sizeof(s_time), "%b%d%Y");
    FormatEx(s_logPathCVAR, sizeof(s_logPathCVAR), "%s-%s.log", s_logPathCVAR, s_time);

    BuildPath(Path_SM, s_logPath, sizeof(s_logPath), s_logPathCVAR);
    gH_logFile = OpenFile(s_logPath, "a");
    if (gH_logFile != null)
    {
        gH_logFile.WriteLine("----------------------");
        gH_logFile.WriteLine("  QUASAR LOG STARTED  ");
        gH_logFile.WriteLine("----------------------");

        Call_StartForward(gH_FWD_logCreated);
        Call_PushCellRef(gH_logFile);
        Call_Finish();
    }
    else { LogError("COULD NOT CREATE LOG FILE!"); }

    /** CVARS **/

    // Chat
    gH_CVR_chatPrefix.GetString(    gST_chatFormatStrings.s_prefix,         sizeof(gST_chatFormatStrings.s_prefix));
    gH_CVR_defaultColor.GetString(  gST_chatFormatStrings.s_defaultColor,   sizeof(gST_chatFormatStrings.s_defaultColor));
    gH_CVR_successColor.GetString(  gST_chatFormatStrings.s_successColor,   sizeof(gST_chatFormatStrings.s_successColor));
    gH_CVR_errorColor.GetString(    gST_chatFormatStrings.s_errorColor,     sizeof(gST_chatFormatStrings.s_errorColor));
    gH_CVR_warnColor.GetString(     gST_chatFormatStrings.s_warnColor,      sizeof(gST_chatFormatStrings.s_warnColor));
    gH_CVR_actionColor.GetString(   gST_chatFormatStrings.s_actionColor,    sizeof(gST_chatFormatStrings.s_actionColor));
    gH_CVR_infoColor.GetString(     gST_chatFormatStrings.s_infoColor,      sizeof(gST_chatFormatStrings.s_infoColor));
    gH_CVR_commandColor.GetString(  gST_chatFormatStrings.s_commandColor,   sizeof(gST_chatFormatStrings.s_commandColor));
    gH_CVR_creditColor.GetString(   gST_chatFormatStrings.s_creditColor,    sizeof(gST_chatFormatStrings.s_creditColor));

    StringMap h_chatFormatMap = new StringMap();
    h_chatFormatMap.SetString("0",          gST_chatFormatStrings.s_prefix);
    h_chatFormatMap.SetString("1",    gST_chatFormatStrings.s_defaultColor);
    h_chatFormatMap.SetString("2",    gST_chatFormatStrings.s_successColor);
    h_chatFormatMap.SetString("3",      gST_chatFormatStrings.s_errorColor);
    h_chatFormatMap.SetString("4",       gST_chatFormatStrings.s_warnColor);
    h_chatFormatMap.SetString("5",     gST_chatFormatStrings.s_actionColor);
    h_chatFormatMap.SetString("6",       gST_chatFormatStrings.s_infoColor);
    h_chatFormatMap.SetString("7",    gST_chatFormatStrings.s_commandColor);
    h_chatFormatMap.SetString("8",     gST_chatFormatStrings.s_creditColor);

    Call_StartForward(gH_FWD_chatFormatRetrieved);
    Call_PushCell(h_chatFormatMap);
    Call_Finish();
    h_chatFormatMap.Close();


    // Sound
    gH_CVR_afkWarnSound.GetString(      gST_sounds.s_afkWarnSound,      sizeof(gST_sounds.s_afkWarnSound));
    gH_CVR_afkMoveSound.GetString(      gST_sounds.s_afkMoveSound,      sizeof(gST_sounds.s_afkMoveSound));
    gH_CVR_errorSound.GetString(        gST_sounds.s_errorSound,        sizeof(gST_sounds.s_errorSound));
    gH_CVR_loginSound.GetString(        gST_sounds.s_loginSound,        sizeof(gST_sounds.s_loginSound));
    gH_CVR_addCreditsSound.GetString(   gST_sounds.s_addCreditsSound,   sizeof(gST_sounds.s_addCreditsSound));
    gH_CVR_buyItemSound.GetString(      gST_sounds.s_buyItemSound,      sizeof(gST_sounds.s_buyItemSound));
    gH_CVR_infoSound.GetString(         gST_sounds.s_infoSound,         sizeof(gST_sounds.s_infoSound));

    StringMap h_soundMap = new StringMap();
    h_soundMap.SetString("0",     gST_sounds.s_afkWarnSound);
    h_soundMap.SetString("1",     gST_sounds.s_afkMoveSound);
    h_soundMap.SetString("2",        gST_sounds.s_errorSound);
    h_soundMap.SetString("3",        gST_sounds.s_loginSound);
    h_soundMap.SetString("4",  gST_sounds.s_addCreditsSound);
    h_soundMap.SetString("5",     gST_sounds.s_buyItemSound);
    h_soundMap.SetString("6",         gST_sounds.s_infoSound);

    Call_StartForward(gH_FWD_soundsRetrieved);
    Call_PushCell(h_soundMap);
    Call_Finish();
    h_soundMap.Close();
}

public void OnMapStart()
{
    QSR_LogMessage(
        MODULE_NAME,
        "COCKHOLE"
    );
}

/*
    GENERAL
    FUNCTIONS
*/
// General

// Natives
any Native_QSRPrintToChat(Handle plugin, int numParams)
{
    int client = GetClientOfUserId(GetNativeCell(1));
    if (!QSR_IsValidClient(client)) { return false; }

    char f_msg[1025], s_prefix[1025];
    SetGlobalTransTarget(client);
    FormatNativeString(0, 2, 3, sizeof(f_msg), .out_string=f_msg);
    strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
    StrCat(s_prefix, sizeof(s_prefix), " ");
    StrCat(s_prefix, sizeof(s_prefix), f_msg);

    MC_PrintToChat(client, s_prefix);
    return true;
}

any Native_QSRNotifyUser(Handle plugin, int numParams)
{
    int client = GetClientOfUserId(GetNativeCell(1));
    if (!QSR_IsValidClient(client)) { return false; }

    char f_msg[1025], s_sound[256], s_prefix[1025];
    GetNativeString(2, s_sound, sizeof(s_sound));

    SetGlobalTransTarget(client);
    FormatNativeString(0, 3, 4, sizeof(f_msg), .out_string=f_msg);

    strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
    StrCat(s_prefix, sizeof(s_prefix), " ");
    StrCat(s_prefix, sizeof(s_prefix), f_msg);
    MC_PrintToChat(client, s_prefix);
    EmitSoundToClient(client, s_sound);
    return true;
}

void Native_QSRPrintToChatAll(Handle plugin, int numParams)
{
    char f_msg[1025], s_prefix[1025];

    for (int i = 1; i < MaxClients; i++)
    {
        if (!QSR_IsValidClient(i)) { continue; }

        SetGlobalTransTarget(i);
        FormatNativeString(0, 2, 3, sizeof(f_msg), .out_string=f_msg);
        strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
        StrCat(s_prefix, sizeof(s_prefix), " ");
        StrCat(s_prefix, sizeof(s_prefix), f_msg);
        MC_PrintToChat(i, s_prefix);
    }
}

any Native_QSRPrintCenterTextEx(Handle plugin, int numParams)
{
    int userid = GetNativeCell(1), client = GetClientOfUserId(userid);
    if (!QSR_IsValidClient(client)) { return false; }

    char sf_msg[1025], s_prefix[64];
    float f_effectSettings[3], f_pos[2], f_holdTime;
    int i_effect, i_color1[4], i_color2[4];

    // Copy prefix and remove color tags
    strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
    MC_RemoveTags(s_prefix, sizeof(s_prefix));

    // Grab and set hud text params
    GetNativeArray(2, f_pos, 2);
    f_holdTime = GetNativeCell(3);
    GetNativeArray(4, i_color1, 4);
    GetNativeArray(5, i_color2, 4);
    i_effect = GetNativeCell(6);
    GetNativeArray(7, f_effectSettings, 3);
    SetHudTextParamsEx(f_pos[0], f_pos[1], f_holdTime, i_color1, i_color2, i_effect, f_effectSettings[0], f_effectSettings[1], f_effectSettings[2]);

    // Handle translation and formatting, then send to client
    SetGlobalTransTarget(client);
    FormatNativeString(0, 8, 9, sizeof(sf_msg), .out_string=sf_msg);
    ShowHudText(client, -1, "%s %s", s_prefix, sf_msg);
    return true;
}

void Native_QSRPrintCenterTextAllEx(Handle plugin, int numParams)
{
    char sf_msg[1025], s_prefix[64];
    float f_effectSettings[3], f_pos[2], f_holdTime;
    int i_effect, i_color1[4], i_color2[4];

    strcopy(s_prefix, sizeof(s_prefix), gST_chatFormatStrings.s_prefix);
    MC_RemoveTags(s_prefix, sizeof(s_prefix));

    // We can get and set the hud text params outside of the for loop.
    GetNativeArray(1, f_pos, 2);
    f_holdTime = GetNativeCell(2);
    GetNativeArray(3, i_color1, 4);
    GetNativeArray(4, i_color2, 4);
    i_effect = GetNativeCell(5);
    GetNativeArray(6, f_effectSettings, 3);
    SetHudTextParamsEx(f_pos[0], f_pos[1], f_holdTime, i_color1, i_color2, i_effect, f_effectSettings[0], f_effectSettings[1], f_effectSettings[2]);

    for (int i = 1; i < MaxClients; i++)
    {
        if (!QSR_IsValidClient(i)) { continue; }

        // Now we can handle the formatting and translation strings
        SetGlobalTransTarget(i);
        FormatNativeString(0, 7, 8, sizeof(sf_msg), .out_string=sf_msg);
        ShowHudText(i, -1, "%s %s", s_prefix, sf_msg);
    }
}

void Native_QSRLogMessage(Handle plugin, int numParams)
{
    char s_nModule[32],
         f_msg[1024], 
         line[1024], 
         s_time[24];
    
    GetNativeString(1, s_nModule, sizeof(s_nModule));
    SetGlobalTransTarget(LANG_SERVER);
    FormatNativeString(
        0, 2, 3, sizeof(f_msg), .out_string=f_msg);

    FormatTime(s_time, sizeof(s_time), "%D %T");
    FormatEx(line, sizeof(line), "[QUASAR (%s) %s] %s", s_nModule, s_time, f_msg);

    if (gH_logFile != null)  {
        gH_logFile.Flush();
        gH_logFile.WriteLine(line);
        PrintToServer(line);
    }
}

void Native_QSRSilentLog(Handle plugin, int numParams)
{
    char s_nModule[32],
         f_msg[3072], 
         line[3072], 
         s_time[24];
    
    GetNativeString(1, s_nModule, sizeof(s_nModule));
    SetGlobalTransTarget(LANG_SERVER);
    FormatNativeString(
        0, 2, 3, sizeof(f_msg), .out_string=f_msg);

    FormatTime(s_time, sizeof(s_time), "%D %T");
    FormatEx(line, sizeof(line), "[QUASAR (%s) %s]\n%s", s_nModule, s_time, f_msg);

    if (gH_logFile != null) {
        gH_logFile.Flush();
        gH_logFile.WriteLine(line);
    }
}

void Native_QSRThrowError(Handle plugin, int numParams)
{
    char s_nModule[32],
         f_msg[1024], 
         line[1024], 
         s_time[24];
    
    GetNativeString(1, s_nModule, sizeof(s_nModule));
    SetGlobalTransTarget(LANG_SERVER);
    FormatNativeString(
        0, 2, 3, sizeof(f_msg), .out_string=f_msg);

    FormatTime(s_time, sizeof(s_time), "%D %T");
    FormatEx(line, sizeof(line), "[QUASAR_ERROR (%s) %s] %s", s_nModule, s_time, f_msg);

    if (gH_logFile != null) {
        gH_logFile.Flush();
        gH_logFile.WriteLine(line);
    }

    ThrowError(line);
}

// Callbacks
void Timer_RestartServer(Handle timer)
{
    QSR_LogMessage( MODULE_NAME, "Restarting TF2 Server!");
    ServerCommand("exit");
}

Action CMD_OpenSettingsMenu(int client, int args)
{
    QSR_LogMessage( MODULE_NAME, "Settings menu attempted to be open");
    return Plugin_Handled;
}

