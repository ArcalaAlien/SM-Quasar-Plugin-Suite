#include <quasar/color>
#include <quasar/core>
#include <quasar/players>
#include <quasar/structs/itemtypes>
#include <autoexecconfig>
#include <tf2_stocks>



// Loadout Stuff
enum struct QuasarItems
{
    char s_nameColor[64];
    char s_chatColor[64];
    SoundObj st_equippedSounds[6]; //0: Soundboard Slot 1, 1: Soundboard Slot 2, 2: Soundboard Slot 3, 3: Connect Sound, 4: Disconnect Sound, 5: Death Sound
    TagObj st_equippedTag;
    TrailObj st_equippedTrail;

    void Get()
    {
        for (int i; i < 6; i++) { this.st_equippedSounds[i].Get(); }
        this.st_equippedTag.Get();
        this.st_equippedTrail.Get();
    }

    bool IsFetched()
    {
        // 6 sounds, 1 trail, 1 tag. 8 items in total to be fetched.
        int i_amountFetched;
        if (this.st_equippedTag.b_fetched)                                   { i_amountFetched++; }
        if (this.st_equippedTrail.b_fetched)                                 { i_amountFetched++; }
        for (int i; i < 6; i++)   { if (this.st_equippedSounds[i].b_fetched) { i_amountFetched++; } }

        return (i_amountFetched == 8) ? true : false
    }

    void Reset()
    {
        this.s_chatColor = EMPTY_STRING;
        this.s_nameColor = EMPTY_STRING;
        this.st_equippedTag.Reset();
        this.st_equippedTrail.Reset();
        for (int i; i < 6; i++)
        {
            this.st_equippedSounds[i].Reset();
        }
    }
}

enum struct Loadout
{
    int i_unusualTaunt;

    TFItem st_primary[9];
    TFItem st_secondary[9];
    TFItem st_melee[9];
    TFItem st_misc1[9];
    TFItem st_misc2[9];
    TFItem st_misc3[9];

    QuasarItems st_quasarItems;

    void Get()
    {
        this.st_quasarItems.Get();
        
        for (int i; i < 9; i++)
        {
            this.st_primary[i].Get();
            this.st_secondary[i].Get();
            this.st_melee[i].Get();
            this.st_misc1[i].Get();
            this.st_misc2[i].Get();
            this.st_misc3[i].Get();
        }
    }

    void SetOwner(int userid)
    {
        this.st_quasarItems.st_equippedTrail.i_owner    = userid;
        this.st_quasarItems.st_equippedTag.i_owner      = userid;

        for (int i; i < 6; i++)
        {
            this.st_quasarItems.st_equippedSounds[i].i_owner = userid;
        }

        for (int i; i < 9; i++)
        {
            this.st_primary[i].i_owner      = userid;
            this.st_secondary[i].i_owner    = userid;
            this.st_melee[i].i_owner        = userid;
            this.st_misc1[i].i_owner        = userid;
            this.st_misc2[i].i_owner        = userid;
            this.st_misc3[i].i_owner        = userid;
        }
    }

    bool IsFetched()
    {
        // 1 Trail, 1 Tag, 6 Sounds, 27 weapons, 27 accessories = 62 items all together need to be fetched.
        int i_amountFetched;
        {
            if (this.st_quasarItems.st_equippedTrail.b_fetched)                                      { i_amountFetched++; }
            if (this.st_quasarItems.st_equippedTag.b_fetched)                                        { i_amountFetched++; } 
            for (int i; i < 6; i++) { if (this.st_quasarItems.st_equippedSounds[i].b_fetched)        { i_amountFetched++; } }

            for (int i; i < 9; i++)
            {
                if (this.st_primary[i].b_fetchedInfo    &&  this.st_primary[i].b_fetchedAttribs)    { i_amountFetched++; }
                if (this.st_secondary[i].b_fetchedInfo  &&  this.st_secondary[i].b_fetchedAttribs)  { i_amountFetched++;}
                if (this.st_melee[i].b_fetchedInfo      &&  this.st_melee[i].b_fetchedAttribs)      { i_amountFetched++; }
                if (this.st_misc1[i].b_fetchedInfo      &&  this.st_misc1[i].b_fetchedAttribs)      { i_amountFetched++; }
                if (this.st_misc2[i].b_fetchedInfo      &&  this.st_misc2[i].b_fetchedAttribs)      { i_amountFetched++; }
                if (this.st_misc3[i].b_fetchedInfo      &&  this.st_misc3[i].b_fetchedAttribs)      { i_amountFetched++; }
            }
        }

        return (i_amountFetched == 62) ? true : false;
    }

    void Reset()
    {
        this.i_unusualTaunt = 0;
        this.st_quasarItems.Reset();

        for (int i; i < 9; i++)
        {
            this.st_primary[i].Reset();
            this.st_secondary[i].Reset();
            this.st_melee[i].Reset();
            this.st_misc1[i].Reset();
            this.st_misc2[i].Reset();
            this.st_misc3[i].Reset();
        }
    }
}

void Timer_ParentTrail(Handle timer, TrailObj trail)
{
    float f_clientPos[3];
    int i_entityIndex = EntRefToEntIndex(trail.i_entityRef);
    int client = GetClientOfUserId(trail.i_owner);
    GetClientAbsOrigin(client, f_clientPos); 
    f_clientPos[2] += 8.0;

    TeleportEntity(i_entityIndex, f_clientPos);
    SetVariantString("!activator");
    AcceptEntityInput(i_entityIndex, "SetParent", client);
}

void Timer_EnableTrail(Handle timer, TrailObj trail)
{
    trail.Show();
}

Action Timer_SoundCooldown(Handle timer, SoundObj sound)
{
    if (sound.f_cooldownLeft == 0.0)
    {
        return Plugin_Stop;
    }

    sound.f_cooldownLeft -= 0.1;
    return Plugin_Continue;
}

void Timer_RetryGetSoundInfo(Handle timer, SoundObj sound)
{
    if (sound.i_attmptsToFetch == 5)
    {
        QSR_LogMessage("ERROR: Unable to fetch sound %s after 5 attempts!", sound.s_itemID);
        sound.i_attmptsToFetch = 0;
        return;
    }

    sound.i_attmptsToFetch += 1;
    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT name, filepath, cooldown \
    FROM str_sounds \
    WHERE `item_id`='%s'", sound.s_itemID);

    QSR_LogQuery(s_query, SQLCB_GetSoundInfo, sound);
}

void Timer_RetryGetTrailInfo(Handle timer, TrailObj trail)
{
    if (trail.i_attmptsToFetch == 5)
    {
        QSR_LogMessage("ERROR: Unable to fetch trail %s after 5 attempts!", trail.s_itemID);
        trail.i_attmptsToFetch = 0;
        return;
    }

    trail.i_attmptsToFetch += 1;
    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT name, vmt \
    FROM str_trails \
    WHERE `item_id`='%s';", trail.s_itemID);

    QSR_LogQuery(s_query, SQLCB_GetTrailInfo, trail);
}

void Timer_RetryGetTagInfo(Handle timer, TagObj tag)
{
    if (tag.i_attmptsToFetch == 5)
    {
        QSR_LogMessage("ERROR: Unable to fetch tag %s after 5 attempts!", tag.s_itemID);
        tag.i_attmptsToFetch = 0;
        return;
    }

    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT name, display, color_trie \
    FROM str_tags \
    WHERE `item_id`='%s'", tag.s_itemID);

    QSR_LogQuery(s_query, SQLCB_GetTagInfo, tag);
}

void Timer_RetryGetTFItemInfo(Handle timer, TFItem item)
{
    if (item.i_attmptsToFetchInfo == 5)
    {
        QSR_LogMessage("ERROR: Unable to fetch info for TF item index %d after 5 attempts!", item.i_index);
        item.i_attmptsToFetchInfo = 0;
        return;
    }

    char s_infoQuery[512];

    FormatEx(s_infoQuery, sizeof(s_infoQuery),
    "SELECT name, classname, min_level, max_level \
    FROM tf_items \
    WHERE `id`='%d'", item.i_index);

    QSR_LogQuery(s_infoQuery, SQLCB_GetTFItemInfo, item);
}

void Timer_RetryGetTFItemAttributeInfo(Handle timer, TFItem item)
{
    if (item.i_attmptsToFetchAttribs == 5)
    {
        QSR_LogMessage("ERROR: Unable to fetch attributes for TF item index %d after 5 attempts!", item.i_index);
        item.i_attmptsToFetchAttribs = 0;
        return;
    }

    char s_attributeQuery[512];
    FormatEx(s_attributeQuery, sizeof(s_attributeQuery),
    "SELECT a.id, attribute_value \
    FROM tf_items i \
        JOIN tf_itemsattributes ia \
            ON i.id = ia.item_id \
        JOIN tf_attributes a \
            ON a.classname = ia.attribute_classname \
    WHERE `i.id` = '%d'", item.i_index);
    QSR_LogQuery(s_attributeQuery, SQLCB_GetTFItemAttributeInfo, item);
}

void Timer_RetryGetTFItemColors(Handle timer, TFItem item)
{
    if (item.i_attmptsToFetchColors == 5)
    {
        QSR_LogMessage("ERROR: Unable to fetch colors for TF item index %d after 5 attempts!", item.i_index);
        item.i_attmptsToFetchColors = 0;
        return;
    }

    char s_query[512];
    FormatEx(s_query, sizeof(s_query),
    "SELECT name, red_color, blu_color \
    FROM tf_paintkits \
    WHERE `id`='%d'", item.i_paintkit);
    QSR_LogQuery(s_query, SQLCB_GetTFItemColors, item);
}

void SQLCB_GetSoundInfo(Database db, DBResultSet results, const char[] error, SoundObj sound)
{
    if (error[0])
    {
        QSR_LogMessage("Unable to fetch info for item: %s. Retrying in 5s.\nERROR: %s", sound.s_itemID, error);
        sound.i_attmptsToFetch++;
        CreateTimer(5.0, Timer_RetryGetSoundInfo, sound);
        return;
    }

    if (results.HasResults)
    {
        while (results.FetchRow())
        {
            results.FetchString(0, sound.s_name, sizeof(sound.s_name));
            results.FetchString(1, sound.s_filepath, sizeof(sound.s_filepath));
            sound.f_cooldownTime = results.FetchFloat(3);
            sound.b_fetched = true;
        }
        sound.i_attmptsToFetch = 0;
    }
}

void SQLCB_GetTrailInfo(Database db, DBResultSet results, const char[] error, TrailObj trail)
{
    if (error[0])
    {
        QSR_LogMessage("Unable to fetch info for item: %s. Retrying in 5s.\nERROR: %s", trail.s_itemID, error);
        trail.i_attmptsToFetch++;
        CreateTimer(5.0, Timer_RetryGetTrailInfo, trail);
        return;
    }

    if (results.HasResults)
    {
        while (results.FetchRow())
        {
            results.FetchString(0, trail.s_name, sizeof(trail.s_name));
            results.FetchString(1, trail.s_vmt, sizeof(trail.s_vmt));
            trail.b_fetched = true;
        }

        trail.i_attmptsToFetch = 0;
        trail.b_fetched = true;
    }
}

void SQLCB_GetTagInfo(Database db, DBResultSet results, const char[] error, TagObj tag)
{
    if (error[0])
    {
        QSR_LogMessage("Unable to fetch info for item: %s. Retrying in 5s\nERROR: %s", tag.s_itemID, error);
        tag.i_attmptsToFetch++;
        CreateTimer(5.0, Timer_RetryGetTagInfo, tag);
        return;
    }

    if (results.HasResults)
    {
        while (results.FetchRow())
        {
            results.FetchString(0, tag.s_name, sizeof(tag.s_name));
            results.FetchString(1, tag.s_display, sizeof(tag.s_display));
            results.FetchString(2, tag.s_trie, sizeof(tag.s_trie));
            tag.b_fetched = true;
        }

        tag.i_attmptsToFetch = 0;
        tag.b_fetched = true;
    }
}

void SQLCB_GetTFItemInfo(Database db, DBResultSet results, const char[] error, TFItem item)
{
    if (error[0])
    {
        QSR_LogMessage("Unable to fetch info for TF item: %d. Retrying in 5s\nERROR: %s", item.i_index, error);
        item.i_attmptsToFetchInfo++;
        CreateTimer(5.0, Timer_RetryGetTFItemInfo, item);
        return;
    }

    if (results.HasResults)
    {
        while (results.FetchRow())
        {
            results.FetchString(0, item.s_name, sizeof(item.s_name));
            results.FetchString(1, item.s_classname, sizeof(item.s_classname));
            item.i_minLevel = results.FetchInt(2);
            item.i_maxLevel = results.FetchInt(3);
        }

        item.i_attmptsToFetchInfo = 0;
        item.b_fetchedInfo = true;
    }
    else
    {
        QSR_LogMessage("ERROR: Item index %d is not defined in the item table!", item.i_index);
    }
}

void SQLCB_GetTFItemAttributeInfo(Database db, DBResultSet results, const char[] error, TFItem item)
{
    if (error[0])
    {
        QSR_LogMessage("Unable to fetch info for TF item: %d. Retrying in 5s\nERROR: %s", item.i_index, error);
        item.i_attmptsToFetchAttribs++;
        CreateTimer(5.0, Timer_RetryGetTFItemAttributeInfo, item);
        return;
    }

    if (results.HasResults)
    {
        int numAttributes;
        while (results.FetchRow())
        {
            item.a_attributes.Set(numAttributes, results.FetchInt(0));
            item.a_attributes.Set(numAttributes, results.FetchFloat(1), 1);
            numAttributes++;
        }

        item.i_numAttributes = numAttributes;
        item.i_attmptsToFetchAttribs = 0;
    }
    else
    {
        item.i_numAttributes = 0;
        item.a_attributes.Clear();
        item.b_fetchedAttribs = true;
    }
}

void SQLCB_GetTFItemColors(Database db, DBResultSet results, const char[] error, TFItem item)
{
    if (error[0])
    {
        QSR_LogMessage("Unable to fetch colors for player %d itemdef %d", item.i_owner, item.i_index);
        item.i_attmptsToFetchColors++;
        CreateTimer(5.0, Timer_RetryGetTFItemColors, item);
        return;
    }

    if (results.HasResults)
    {
        while (results.FetchRow())
        {
            results.FetchString(0, item.st_redColor.name, sizeof(item.st_redColor.name));
            results.FetchString(0, item.st_bluColor.name, sizeof(item.st_bluColor.name));
            item.st_redColor.FromDecimal(results.FetchInt(1));
            item.st_bluColor.FromDecimal(results.FetchInt(2));
        }

        item.i_attmptsToFetchColors = 0;
        item.b_fetchedColors = true;
    }
}