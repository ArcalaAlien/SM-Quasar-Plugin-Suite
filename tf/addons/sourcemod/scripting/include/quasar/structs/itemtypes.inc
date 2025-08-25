
/* ITEM STRUCTS */
enum struct SoundObj
{
    int  i_owner;
    char s_itemID[64];

    bool b_fetched;
    int  i_attmptsToFetch;

    char s_name[128];
    char s_filepath[256];
    float f_cooldownTime;
    float f_cooldownLeft;
    Handle h_cooldownTimer;

    // Leave item param empty to use the itemID
    // in the sound object itself.
    void Get(const char[] item = EMPTY_STRING)
    {
        char s_query[512];
        if (item[0]) { strcopy(this.s_itemID, sizeof(this.s_itemID), item); }

        FormatEx(s_query, sizeof(s_query),
        "SELECT name, filepath, cooldown \
        FROM str_sounds \
        WHERE `item_id`='%s'", this.s_itemID);
        QSR_LogQuery(s_query, SQLCB_GetSoundInfo, this);
    }

    void Play()
    {
        if (QSR_IsValidClient(this.i_owner))
        {
            // Grab the error noise from the config
            char s_errorSound[256], 
                 s_errorColor[32], 
                 s_infoColor[32],
                 s_commandColor[32];
            AutoExecConfig_FindValue("sm_quasar_errorSound", s_errorSound, sizeof(s_errorSound));
            AutoExecConfig_FindValue("sm_quasar_error_text_color", s_errorColor, sizeof(s_errorColor));
            AutoExecConfig_FindValue("sm_quasar_info_text_color", s_infoColor, sizeof(s_infoColor));
            AutoExecConfig_FindValue("sm_quasar_command_text_color", s_commandColor, sizeof(s_commandColor));

            // Is the sound on cooldown?
            if (this.f_cooldownLeft > 0.0 && !QSR_CheckForUpgrade(this.i_owner, QSRUpgrade_NoSoundCooldown))
            {
                QSR_NotifyUser(this.i_owner, s_errorSound, 
                "%T", "QSR_SoundOnCooldown",
                s_errorColor, s_infoColor, s_commandColor);
                return;
            }

            // Grab the client of the owner, and get their position.
            int client = GetClientOfUserId(this.i_owner);
            float f_clientPos[3];
            GetClientAbsOrigin(client, f_clientPos);

            // Is the player in spectator, and doesn't have the spectator upgrade?
            if ((!IsPlayerAlive(client) &&
                 (TF2_GetClientTeam(client) == TFTeam_Spectator || 
                  TF2_GetClientTeam(client) == TFTeam_Unassigned)) && 
                 !QSR_CheckForUpgrade(this.i_owner, QSRUpgrade_SpectatorSound))
            {
                QSR_NotifyUser(this.i_owner, s_errorSound, 
                "%T", "QSR_NeedSpectatorUpgrade",
                s_errorColor, s_commandColor);
                return;
            }

            // Is the player dead, and doesn't have the Death Sound upgrade?
            else if ((!IsPlayerAlive(client) && 
                      (TF2_GetClientTeam(client) != TFTeam_Spectator) || 
                       TF2_GetClientTeam(client) != TFTeam_Unassigned) && 
                      !QSR_CheckForUpgrade(this.i_owner, QSRUpgrade_DeathSound))
            {
                QSR_NotifyUser(this.i_owner, s_errorSound, 
                "%T", "QSR_NeedDeathSoundsUpgrade",
                s_errorColor, s_commandColor);
                return;
            }

            // Lets play the sound then!
            EmitAmbientSound(this.s_filepath, f_clientPos, client, SNDLEVEL_CONVO);
            this.f_cooldownLeft = this.f_cooldownTime;
            
            // Make sure there is no leftover handle to a timer
            this.KillCooldownTimer();

            // If the player doesn't have the NoSoundCooldown upgrade, they won't be able to play a sound
            // until f_cooldownLeft hits 0.
            if (!QSR_CheckForUpgrade(this.i_owner, QSRUpgrade_NoSoundCooldown)) 
            { 
                this.h_cooldownTimer = CreateTimer(0.1, Timer_SoundCooldown, this, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }

    void KillCooldownTimer()
    {
        if (this.h_cooldownTimer != null)
        {
            KillTimer(this.h_cooldownTimer);
            this.h_cooldownTimer = null;
        }
    }

    void Reset()
    {
        this.i_owner = -1;
        this.s_itemID = EMPTY_STRING;
        this.b_fetched = false;
        this.i_attmptsToFetch = 0;
        this.s_name = EMPTY_STRING;
        this.s_filepath = EMPTY_STRING;
        this.f_cooldownTime = 0.0;
        this.f_cooldownLeft = 0.0;

        this.KillCooldownTimer();
    }
}

enum struct TagObj
{
    int  i_owner;
    char s_itemID[64];

    int  i_attmptsToFetch;
    bool b_fetched;
    bool b_showing;

    char s_name[128];
    char s_display[128];
    char s_trie[64];
    int  i_position;

    // Leave item param empty to use the itemID
    // in the tag object itself.
    void Get(const char[] item = EMPTY_STRING)
    {
        char s_query[512];
        if (!item[0]) { strcopy(this.s_itemID, sizeof(this.s_itemID), item); }

        FormatEx(s_query, sizeof(s_query),
        "SELECT name, display, color_trie \
        FROM str_tags \
        WHERE `item_id`='%s'", this.s_itemID);
        QSR_LogQuery(s_query, SQLCB_GetTagInfo, this);
    }

    void Reset()
    {
        this.i_owner = -1;
        this.s_itemID = EMPTY_STRING;

        this.b_fetched = false;
        this.b_showing = false;
        this.i_attmptsToFetch = 0;
        this.s_name = EMPTY_STRING;
        this.s_display = EMPTY_STRING;
        this.s_trie = EMPTY_STRING;
        this.i_position = 0;
    }
}

enum struct TrailObj
{
    int i_entityRef; // MAKE SURE WE GET THE REFERENCE OF THE ENTITY, NOT THE INDEX.
    char s_entityName[64];

    int  i_owner;
    char s_itemID[64];

    int  i_attmptsToFetch;
    bool b_fetched;
    bool b_enabled;

    char s_name[128];
    char s_vmt[256];
    
    QSRColor st_trailColor;
    int i_width;

    // Leave item param empty to use the itemID
    // in the trail object itself.
    void Get(const char[] item = EMPTY_STRING)
    {
        char s_query[512];
        if (item[0]) { strcopy(this.s_itemID, sizeof(this.s_itemID), item); }

        FormatEx(s_query, sizeof(s_query),
        "SELECT name, vmt \
        FROM str_trails \
        WHERE `item_id`='%s'", this.s_itemID);
        QSR_LogQuery(s_query, SQLCB_GetTrailInfo, this);
    }

    bool Create()
    {
        if (this.i_entityRef > 0)
        {
            this.ForceKill();
        }

        if (!this.s_vmt[0])
        {
            QSR_LogMessage("ERROR! Cannot create trail, vmt file has not been picked!");
            return false;
        }

        if (QSR_IsValidClient(this.i_owner))
        {
            char s_name[128];
            int client = GetClientOfUserId(this.i_owner);
            GetClientName(client, s_name, sizeof(s_name));

            char s_errorSound[256],
                 s_errorColor[32],
                 s_infoColor[32],
                 s_commandColor[32];
            AutoExecConfig_FindValue("sm_quasar_errorSound", s_errorSound, sizeof(s_errorSound));
            AutoExecConfig_FindValue("sm_quasar_error_text_color", s_errorColor, sizeof(s_errorColor));
            AutoExecConfig_FindValue("sm_quasar_info_text_color", s_infoColor, sizeof(s_infoColor));
            AutoExecConfig_FindValue("sm_quasar_command_text_color", s_commandColor, sizeof(s_commandColor));


            int i_entIndex = CreateEntityByName("env_spritetrail");
            if (i_entIndex == -1)
            {
                QSR_LogMessage("Unable to create a trail for player %s", s_name);
                QSR_NotifyUser(this.i_owner, s_errorSound,
                "%T", "QSR_UnableToCreateTrail",
                s_errorColor,
                s_commandColor);
                return false;
            }

            char s_trailName[256], s_trailColor[64];
            FormatEx(s_trailName, sizeof(s_trailName), "quasar_trail_%s", s_name);
            this.st_trailColor.RGBToString(s_trailColor, sizeof(s_trailColor));
            this.i_entityRef = EntIndexToEntRef(i_entIndex);

            DispatchKeyValue(i_entIndex, "targetname", s_trailName);
            DispatchKeyValueFloat(i_entIndex, "lifetime", 1.5);
            DispatchKeyValueFloat(i_entIndex, "endwidth", 0.0);
            DispatchKeyValueFloat(i_entIndex, "startwidth", float(this.i_width));
            DispatchKeyValueInt(i_entIndex, "rendermode", 5);
            DispatchKeyValue(i_entIndex, "rendercolor", s_trailColor);
            DispatchKeyValueInt(i_entIndex, "renderamt", this.st_trailColor.a);
            DispatchKeyValue(i_entIndex, "spritename", this.s_vmt);

            float f_playerPos[3];
            GetClientAbsOrigin(client, f_playerPos);
            f_playerPos[2] += 8.0;
            TeleportEntity(i_entIndex, f_playerPos);
            
            if (!DispatchSpawn(i_entIndex))
            {
                QSR_LogMessage("Unable to dispatch trail spawn for player %s", s_name);
                RemoveEntity(i_entIndex);
                QSR_NotifyUser(this.i_owner, s_errorSound,
                "%T", "QSR_UnableToCreateTrail",
                s_errorColor,
                s_commandColor);
                return false;
            }

            SetEntPropFloat(i_entIndex, Prop_Send, "m_flTextureRes", 0.05);
            SetVariantString("!activator");
            CreateTimer(0.25, Timer_ParentTrail, this);
            if (this.b_enabled) { CreateTimer(0.5, Timer_EnableTrail, i_entIndex); }
            return true;
        }
        else
        {
            QSR_LogMessage("Attempted to create a trail for invalid user %d", this.i_owner);
            return false;
        }
    }

    void SetRGBA(int r = 255, int g = 255, int b = 255, int a = 255)
    {
        char s_color[16];
        FormatEx(s_color, sizeof(s_color), "%d %d %d %d", r, g, b, a);

        this.st_trailColor.RGBAFromString(s_color);

        if (this.Validate())
        {
            DispatchKeyValue(EntRefToEntIndex(this.i_entityRef), "rendercolor", s_color);
            this.Refresh();
        }
    }

    void SetRGB(int r = 255, int g = 255, int b = 255)
    {
        char s_color[16];
        FormatEx(s_color, sizeof(s_color), "%d %d %d %d", r, g, b, this.st_trailColor.a);
        this.st_trailColor.RGBFromString(s_color);

        if (this.Validate())
        {
            DispatchKeyValue(EntRefToEntIndex(this.i_entityRef), "rendercolor", s_color);
            this.Refresh();
        }
    }

    void SetA(int a = 255)
    {
        char s_color[16];
        FormatEx(s_color, sizeof(s_color),
                "%d %d %d %d", 
                this.st_trailColor.r, 
                this.st_trailColor.g, 
                this.st_trailColor.b,
                a);
        this.st_trailColor.RGBAFromString(s_color);

        if (this.Validate())
        {
            DispatchKeyValue(EntRefToEntIndex(this.i_entityRef), "rendercolor", s_color);
            this.Refresh();
        }
    }

    bool Kill()
    {
        if (this.Validate())
        {   
            char s_infoSound[256], 
            s_actionColor[32], 
            s_commandColor[32], 
            s_infoColor[32];
            AutoExecConfig_FindValue("sm_quasar_info_sound", s_infoSound, sizeof(s_infoSound));
            AutoExecConfig_FindValue("sm_quasar_action_text_color", s_actionColor, sizeof(s_actionColor));
            AutoExecConfig_FindValue("sm_quasar_command_text_color", s_commandColor, sizeof(s_commandColor));
            AutoExecConfig_FindValue("sm_quasar_info_text_color", s_infoColor, sizeof(s_infoColor));

            int i_entityIndex = EntRefToEntIndex(this.i_entityRef);
            if (IsValidEdict(i_entityIndex) && IsValidEntity(i_entityIndex))
            {
                RemoveEntity(i_entityIndex);
            }

            this.i_entityRef = -1;
            QSR_LogMessage("Deleted user %d's trail entity from the game.", this.i_owner);
            QSR_NotifyUser(this.i_owner, s_infoSound,
            "%T", "QSR_TrailDeleted",
            s_actionColor, s_commandColor, s_infoColor);

            return true;
        }

        return false;
    }

    void ForceKill()
    {
        int i_entityIndex = EntRefToEntIndex(this.i_entityRef);
        if (i_entityIndex != INVALID_ENT_REFERENCE && i_entityIndex != 0) 
        { 
            RemoveEntity(i_entityIndex); 
            this.i_entityRef = -1; 
        }
    }

    bool Refresh(bool enable = true)
    {
        if (this.Validate())
        {
            this.Hide();
            CreateTimer(0.25, Timer_ParentTrail, this);
            if (enable) { CreateTimer(0.5, Timer_EnableTrail, this); }
            return true;
        }
        return false;
    }

    void Hide()
    {
        if (this.Validate())
        {
            int i_entityIndex = EntRefToEntIndex(this.i_entityRef);
            AcceptEntityInput(i_entityIndex, "HideSprite");
        }
    }

    void Show()
    {
        if (this.Validate())
        {
            int i_entityIndex = EntRefToEntIndex(this.i_entityRef);
            AcceptEntityInput(i_entityIndex, "ShowSprite");
        }
    }

    bool Validate()
    {
        if (QSR_IsValidClient(this.i_owner))
        {
            char s_trailName[256], s_clientName[128];
            int client = GetClientOfUserId(this.i_owner);
            GetClientName(client, s_clientName, sizeof(s_clientName));

            int i_entityIndex = EntRefToEntIndex(this.i_entityRef);
            if (i_entityIndex != INVALID_ENT_REFERENCE)
            {
                GetEntPropString(i_entityIndex, Prop_Send, "targetname", s_trailName, sizeof(s_trailName));
                if (StrContains(s_trailName, s_clientName) != -1)
                {
                    return true;
                }
            }
        }

        return false;
    }

    void Reset()
    {
        this.ForceKill();
        this.i_entityRef = -1;
        this.s_entityName = EMPTY_STRING;

        this.s_itemID = EMPTY_STRING;
        this.b_fetched = false;
        this.b_enabled = false;
        this.i_attmptsToFetch = 0;
        this.s_name   = EMPTY_STRING;
        this.s_vmt    = EMPTY_STRING;

        this.st_trailColor.r = 255;
        this.st_trailColor.g = 255;
        this.st_trailColor.b = 255;
        this.st_trailColor.a = 255;

        this.i_width = 8;
    }
}

/*  TODO (IMPORTANT TFITEM ATTRIBUTES)        
    paintkit_proto_def_index (ID: 834)
    This controls what war paint a weapon has?

    has_team_color_paintkit (ID: 745)
    If a war paint is team colored?

    set_item_tint_rgb (ID: 142)
    Set an item's paint color. Red Team

    set_item_tint_rgb_2 (ID: 261)
    Set an item's 2nd paint color. Blue Teams

    is_festivized (ID: 2053)
    Festivizes weapon?
*/ 
enum struct TFItem
{
    int  i_owner;
    
    int  i_attmptsToFetchInfo;
    int  i_attmptsToFetchAttribs;
    int  i_attmptsToFetchColors;
    bool b_fetchedInfo;
    bool b_fetchedAttribs;
    bool b_fetchedColors;

    int  i_entityRef;
    int  i_index;
    int  i_tempIndex;
    char s_slot[32];
    int  i_paintkit;
    int  i_warpaint;
    int  i_unusual;
    QSRColor st_redColor;
    QSRColor st_bluColor;
    int  i_quality;
    int  i_level;

    char s_classname[128];
    char s_name[128];
    int  i_minLevel;
    int  i_maxLevel;
    
    int  i_numAttributes;
    ArrayList a_attributes;

    void Get(int index = -1)
    {
        if (this.i_index == -1)
        {
            QSR_LogMessage("ERROR: TF Item for player %d does not have a vaild item index!", this.i_owner);
            return;
        }

        char s_query[512];
        if (index != -1) { this.i_index = index; }

        FormatEx(s_query, sizeof(s_query),
        "SELECT name, classname, slot, min_level, max_level \
        FROM tf_items \
        WHERE `id`='%d'", this.i_index);
        QSR_LogQuery(s_query, SQLCB_GetTFItemInfo, this);

        FormatEx(s_query, sizeof(s_query),
        "SELECT a.id, attribute_value \
        FROM tf_items i \
            JOIN tf_itemsattributes ia \
                ON i.id = ia.item_id \
            JOIN tf_attributes a \
                ON a.classname = ia.attribute_classname \
        WHERE `i.id` = '%d'", this.i_index);
        QSR_LogQuery(s_query, SQLCB_GetTFItemAttributeInfo, this);

        if (this.i_paintkit != -1)
        {
            FormatEx(s_query, sizeof(s_query),
            "SELECT name, red_color, blu_color \
            FROM tf_paintkits \
            WHERE `id`='%d'", this.i_paintkit);
            QSR_LogQuery(s_query, SQLCB_GetTFItemColors, this);
        }
    }

    bool IsCosmetic()
    {
        return (StrContains(this.s_classname, "tf_wearable", false) != -1) ? true : false;
    }

    bool Validate()
    {
        int i_entIndex = EntRefToEntIndex(this.i_entityRef);
        if (i_entIndex != INVALID_ENT_REFERENCE && IsValidEdict(i_entIndex))
        {
            if (GetEntPropEnt(i_entIndex, Prop_Send, "m_hOwnerEntity") == GetClientOfUserId(this.i_owner) && 
                !GetEntProp(i_entIndex, Prop_Send, "m_bDisguiseWearable"))
            {
                return true;
            }
        }

        return false;
    }

    bool IsEmpty()
    {
        if (this.i_index == -1 &&
            !this.s_classname[0] &&
            !this.s_name[0] &&
            !this.s_slot[0])
        {
            return true;
        }

        return false;
    }

    void Reset()
    {
        this.i_owner = -1;
        this.b_fetchedInfo = false;
        this.b_fetchedAttribs = false;
        this.i_attmptsToFetchInfo = 0;
        this.i_attmptsToFetchAttribs = 0;
        this.i_entityRef = -1;
        this.i_index = -1;
        this.s_slot = EMPTY_STRING;
        this.i_paintkit = -1;
        this.i_warpaint = -1;
        this.i_unusual = -1;
        this.st_redColor.Reset();
        this.st_bluColor.Reset();
        this.i_quality = 0;
        this.i_level = 1;
        this.i_numAttributes = 0;
        this.s_classname = EMPTY_STRING;
        this.s_name = EMPTY_STRING;
        this.i_minLevel = 1;
        this.i_maxLevel = 100;
        if (this.a_attributes != null)
        {
            this.a_attributes.Clear();
            this.a_attributes.Close();
            this.a_attributes = new ArrayList(2);
        }
    }
}

enum struct TFTaunt
{
    int fuck;
}