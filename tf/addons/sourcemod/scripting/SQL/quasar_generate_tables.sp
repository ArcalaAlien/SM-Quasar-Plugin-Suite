//TODO: MOVE BELOW CODE TO quasar_generate_tables.sp
#define LOG_CREATE_TABLE_QUERY QSR_LogMessage(gH_dbLogFile, MODULE_NAME, s_query)
void Internal_GenerateTFTables() {
    /*
        NOTE:
            If anything goes wrong with this segment
            make sure that the tables are ordered
            correctly in the enum, and here in the
            create statements.
    */
    Transaction h_genTFTablesTrans = new Transaction();
    char s_query[2048];
    char s_tableName[64];
    int i_currentTable = DBTable_TFClasses;

    QSR_LogMessage(gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING TEAM FORTRESS 2 TABLES======");


    // Team Fortress 2 Tables
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_classes`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_classes` (\
            `id`        INT NOT NULL AUTO_INCREMENT,\
            `name`      VARCHAR(16) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `id`\
            )) AUTO_INCREMENT = 1;");
    h_genTFTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_items`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_items` (\
            `id`        INT NOT NULL DEFAULT -1,\
            `name`      VARCHAR(128) NULL DEFAULT NULL,\
            `classname` VARCHAR(128) NULL DEFAULT NULL,\
            `min_level` INT NOT NULL DEFAULT 0,\
            `max_level` INT NOT NULL DEFAULT 99,\
            `slot_name` VARCHAR(16) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `id`\
            ));");
    h_genTFTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_attributes`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_attributes` (\
            `id`            INT NOT NULL DEFAULT -1,\
            `name`          VARCHAR(128) NULL DEFAULT NULL,\
            `classname`     VARCHAR(128) NULL DEFAULT NULL,\
            `description`   VARCHAR(128) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `id`\
            ));");
    h_genTFTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_qualities`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_qualities` (\
            `id`    INT NOT NULL\
            `name`  VARCHAR(64) NULL DEFAULT NULL\
            PRIMARY KEY (\
                `id`\
            ));");
    h_genTFTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_particles`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_particles` (\
            `id`            INT NOT NULL DEFAULT -1,\
            `name`          VARCHAR(128) NULL DEFAULT NULL\
            `type`          VARCHAR(16)  NOT NULL DEFAULT `WEAPON`\
            `system_name`   VARCHAR(128) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `id`\
            ));");
    h_genTFTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_paint_kits`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_paint_kits` (\
            `id`        INT NOT NULL DEFAULT -1,\
            `name`      VARCHAR(128) NULL DEFAULT NULL,\
            `red_color` INT NOT NULL DEFAULT 0,\
            `blu_color` INT NOT NULL DEFAULT 0,\
            PRIMARY KEY (\
                `id`\
            ));");
    h_genTFTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_war_paints`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_war_paints` (\
            `id`    INT NOT NULL DEFAULT -1,\
            `name`  VARCHAR(128) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `id`\
            ));");
    h_genTFTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    gH_db.Execute(
        h_genTFTablesTrans,
        SQLSuccess_TableCreated,
        SQLFail_TableNotCreated,
        priority = DBPrio_High);
}

void Internal_GenerateGlobalTables() {
    /*
        NOTE:
            If anything goes wrong with this segment
            make sure that the tables are ordered
            correctly in the enum, and here in the
            create statements.
    */
   Transaction h_genGlobalTablesTrans = new Transaction();
    char s_query[2048];
    char s_tableName[64];
    int  i_currentTable = DBTable_Players;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING MAIN GLOBAL TABLES======");

    // GENERAL TABLES//
    // Version Table //
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`db_version`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`db_version` (\
            `version` VARCHAR (16) NOT NULL \
            PRIMARY KEY (`version`));\
        INSERT INTO `quasar`.`db_version`\
        VALUES (`%s`);",
        DATABASE_VERSION);
    h_genGlobalTablesTrans.AddQuery(s_query, DBTable_Version);
    LOG_CREATE_TABLE_QUERY;

    // Player Table//
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`players`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`players` (\
            `id`                INT NOT NULL AUTO_INCREMENT,\
            `steam2_id`         VARCHAR(64)     NULL DEFAULT NULL,\
            `steam3_id`         VARCHAR(64)     NULL DEFAULT NULL,\
            `steam64_id`        VARCHAR(64)     NULL DEFAULT NULL,\
            `name`              VARCHAR(128)    NULL DEFAULT NULL,\
            `nickname`          VARCHAR(128)    NULL DEFAULT NULL,\
            `can_vote`          INT             NOT NULL DEFAULT 1,\
            `num_loadouts`      INT             NOT NULL DEFAULT 1,\
            `equipped_loadout`  INT             NOT NULL DEFAULT 0,\
            PRIMARY KEY (\
                `id`,\
                `steam2_id`,\
                `steam3_id`,\
                `steam64_id`));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    // Rank Title Table//
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`rank_titles`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`rank_titles` (\
            `id`            INT NOT NULL AUTO_INCREMENT,\
            `rank_id`       VARCHAR(128) NULL DEFAULT NULL,\
            `name`          VARCHAR(128) NULL DEFAULT NULL,\
            `display`       VARCHAR(128) NULL DEFAULT NULL,\
            `point_target`  DECIMAL(10)  NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `id`,\
                `name`,\
                `display`,\
                `point_target`\
            ));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    // Ignore Table
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`players_ignore`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`players_ignore` (\
            `id`                INT NOT NULL AUTO_INCREMENT,\
            `steam64_id`        VARCHAR(64) NULL DEFAULT NULL,\
            `ignore_target_id`  VARCHAR(64) NULL DEFAULT NULL,\
            `ignoring_voice`    INT         NOT NULL DEFAULT 0,\
            `ignoring_text`     INT         NOT NULL DEFAULT 0,\
            PRIMARY KEY (\
                `id`,\
                `steam64_id`,\
                `ignore_target_id`\
            ),\
            CONSTRAINT `steam64_id`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players_ignore` (`steam64_id`));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    // Store Tables
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`groups`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`groups` (\
            `id`    INT         NOT NULL AUTO_INCREMENT,\
            `name`  VARCHAR(64) NULL\
            PRIMARY KEY (`id`));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`sounds`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`sounds` (\
            `id`                INT NOT NULL AUTO_INCREMENT,\
            `item_id`           VARCHAR(64) NULL DEFAULT NULL,\
            `name`              VARCHAR(64) NULL DEFAULT NULL,\
            `filepath`          VARCHAR(256) NULL DEFAULT NULL,\
            `cooldown`          DECIMAL NOT NULL DEFAULT 0.1,\
            `price`             INT NOT NULL DEFAULT 0,\
            `activation_word`   VARCHAR(32) NULL DEFAULT NULL,\
            `creator_id`        VARCHAR(64) NOT NULL DEFAULT `QUASAR`\
            PRIMARY KEY (\
                `id`,\
                `item_id`,\
                `name`,\
                `filepath`,\
                `activation_word`,\
            ));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`trails`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`trails` (\
            `item_id`       VARCHAR(64)  NULL DEFAULT NULL,\
            `id`                INT NOT NULL AUTO_INCREMENT,\
            `name`          VARCHAR(64)  NULL DEFAULT NULL,\
            `vtf_filepath`  VARCHAR(256) NULL DEFAULT NULL,\
            `vmt_filepath`  VARCHAR(256) NULL DEFAULT NULL,\
            `price`         INT          NOT NULL DEFAULT 0,\
            `creator_id`    VARCHAR(64)  NOT NULL DEFAULT `QUASAR`,\
            PRIMARY KEY (\
                `id`,\
                `item_id`,\
                `name`,\
                `vtf_filepath`,\
                `vmt_filepath`\
            ));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tags`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tags` (\
            `id`                INT NOT NULL AUTO_INCREMENT,\
            `item_id`       VARCHAR(64) NULL DEFAULT NULL,\
            `name`          VARCHAR(64) NULL DEFAULT NULL,\
            `display`       VARCHAR(64) NOT NULL DEFAULT `{pink}[IN{black}VAL{PINK}ID]`,\
            `price`         INT         NOT NULL DEFAULT 0,\
            `creator_id`    VARCHAR(64) NOT NULL DEFAULT `QUASAR`,\
            PRIMARY KEY (\
                `id`,\
                `item_id`,\
                `name`,\
                `display`,\
            ));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`upgrades`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`upgrades` (\
            `id`                INT NOT NULL AUTO_INCREMENT,\
            `item_id`       VARCHAR(64)  NULL DEFAULT NULL,\
            `name`          VARCHAR(64)  NULL DEFAULT NULL,\
            `description    VARCHAR(128) NULL DEFAULT NULL\
            `price`         INT          NOT NULL DEFAULT 0,\
            `function_name` VARCHAR(128) NULL DEFAULT NULL,\
            `plugin_name`   VARCHAR(128) NULL DEFAULT NULL,\
            `creator_id`    VARCHAR(64)  NOT NULL DEFAULT `QUASAR`,\
            PRIMARY KEY (\
                `id`,\
                `item_id`,\
                `name`,\
                `function_name`,\
            ));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    //TODO: CHAT COLORS WILL BE HANDLED UNDER NEW "CUSTOM NICKNAME"
    //SYSTEM.
    //
    //Players will be able to paint their name or their chat
    //an entire color as before, or they can save their name
    //with color tags to have a multicolored name.
    //
    //Players will need Custom Nickname, then Custom Name Colors
    //Players can buy Custom Chat Colors separately.

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`chat_colors`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`chat_colors` (\
            `id`          INT NOT NULL AUTO_INCREMENT,\
            `format`      VARCHAR(64) NULL DEFAULT NULL\
            `name`        VARCHAR(64) NULL DEFAULT NULL\
            `category`    VARCHAR(16) NULL DEFAULT NULL\
            PRIMARY KEY (\
                `id`,\
                `format`,\
                `name`\
            ));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`chat_pack_names`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`chat_pack_names` (\
            `id`    INT NOT NULL AUTO_INCREMENT,\
            `name`  VARCHAR(64) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `id`,\
                `name`\
            ));");
    h_genGlobalTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;
    gH_db.Execute(
        h_genGlobalTablesTrans,
        SQLSuccess_TableCreated,
        SQLFail_TableNotCreated,
        priority = DBPrio_High);
}

void Internal_GenerateSubserverTables() {
    /*
        NOTE:
            If anything goes wrong with this segment
            make sure that the tables are ordered
            correctly in the enum, and here in the
            create statements.
    */
    Transaction h_genSubserverTablesTrans = new Transaction();
    char s_query[2048];
    char s_tableName[64];
    int  i_currentTable = DBTable_SubserverStats;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING MAIN TABLES FOR %s======",
        gS_subserver);
    // Per sub-server main tables
    // Player Stats Table
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_stats`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_stats` (\
            `id`            INT         NOT NULL AUTO_INCREMENT,\
            `steam64_id`    VARCHAR(64) NULL DEFAULT NULL,\
            `points`        DECIMAL     NOT NULL DEFAULT `0.0`,\
            `kills`         INT         UNSIGNED NOT NULL DEFAULT 0,\
            `afk_points`    DECIMAL     NOT NULL DEFAULT `0.0`\
            `afk_kills`     INT         UNSIGNED NOT NULL DEFAULT 0,\
            `first_login`   INT         NOT NULL DEFAULT `-1`\
            `last_login`    INT         NOT NULL DEFAULT `-1`\
            `playtime`      INT         NOT NULL DEFAULT `0`\
            `time_afk`      INT         NOT NULL DEFAULT `0`,\
            PRIMARY KEY (\
                `id`,\
                `steam64_id`),\
            CONSTRAINT `FK_players_%s_stats`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`);",
        gS_subserver,
        gS_subserver,
        gS_subserver);
    h_genSubserverTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    // Map Table
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_maps`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_maps`(\
            `id`            INT             NOT NULL AUTO_INCREMENT,\
            `name`          VARCHAR(128)    NULL DEFAULT NULL\
            `category`      VARCHAR(64)     NOT NULL DEFAULT `NONE`,\
            `author`        VARCHAR(128)    NULL DEFAULT NULL\
            `workshop_id`   VARCHAR(128)    NULL DEFAULT NULL\
            PRIMARY KEY (\
                `id`,\
                `name`\
            ));",
        gS_subserver,
        gS_subserver);
    h_genSubserverTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    // Vote Log Table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_vote_log (VOTE LOGS FOR SUBSERVER %s)",
        gS_subserver,
        gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_vote_log`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_vote_log` (\
            `id`                INT NOT NULL AUTO_INCREMENT,\
            `vote_type`         INT NOT NULL DEFAULT 0,\
            `voter_steam_id`    VARCHAR(64) NULL DEFAULT NULL,\
            `target_steam_id`   VARCHAR(64) NULL DEFAULT NULL,\
            `voter_name`        VARCHAR(128) NULL DEFAULT NULL,\
            `target_name`       VARCHAR(128) NULL DEFAULT NULL,\
            `date`              INT NOT NULL DEFAULT -1,\
            PRIMARY KEY (\
                `id`,\
                `voter_steam_id`),\
            INDEX `FK_vote_log_players_idx` (`voter_steam_id` ASC) VISIBLE,\
            INDEX `FK_vote_log_players2_idx` (`target_steam_id` ASC) VISIBLE,\
            CONSTRAINT `FK_vote_log_players`\
                FOREIGN KEY (`voter_steam_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`),\
            CONSTRAINT `FK_vote_log_players2`\
                FOREIGN KEY (`target_steam_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`);",
        gS_subserver,
        gS_subserver);
    h_genSubserverTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    // Chat log table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_chat_log (CHAT LOGS FOR SUBSERVER %s)",
        gS_subserver,
        gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_chat_log`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_chat_log` (\
            `id`            INT NOT NULL AUTO_INCREMENT,\
            `steam64_id`    VARCHAR(64) NULL DEFAULT NULL,\
            `message`       VARCHAR(256) NULL DEFAULT `NONE`,\
            `date`          INT NOT NULL -1,\
            PRIMARY KEY (\
                `id`,\
                `steam64_id`\
            ),\
            CONSTRAINT `FK_%s_chat_log_players`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`);",
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver);
    h_genSubserverTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;
    gH_db.Execute(
        h_genSubserverTablesTrans,
        SQLSuccess_TableCreated,
        SQLFail_TableNotCreated,
        priority = DBPrio_High);
}

void Internal_GenerateTFJunctionTables() {
    /*
        NOTE:
            If anything goes wrong with this segment
            make sure that the tables are ordered
            correctly in the enum, and here in the
            create statements.
    */
    Transaction h_genTFJuncTablesTrans = new Transaction();
    char s_query[2048];
    char s_tableName[64];
    int  i_currentTable = DBTable_TFItemsClasses;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING TF JUNCTION TABLES======");

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_items_classes`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_items_classes` (\
            `item_id`       INT NOT NULL DEFAULT -1,\
            `class`         INT NOT NULL DEFAULT 0,\
            PRIMARY KEY (\
                `item_id`,\
                `class`\
            ),\
            CONSTRAINT `FK_ic_items`\
                FOREIGN KEY (`item_id`)\
                REFERENCES `quasar`.`tf_items` (`id`),\
            CONSTRAINT `FK_ic_classes`\
                FOREIGN KEY (`class`)\
                REFERENCES `quasar`.`tf_classes` (`id`));");
    h_genTFJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_items_attributes`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_items_attributes` (\
            `item_id`           INT NOT NULL DEFAULT -1,\
            `attribute_id`      INT NOT NULL DEFAULT -1,\
            `attribute_value`   DECIMAL(10) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `item_id`,\
                `attribute_id`\
            ),\
            CONSTRAINT `FK_ia_items`\
                FOREIGN KEY (`item_id`)\
                REFERENCES `quasar`.`tf_items` (`id`),\
            CONSTRAINT `FK_ia_attributes`\
                FOREIGN KEY (`attribute_id`)\
                REFERENCES `quasar`.`tf_attributes` (`id`));");
    h_genTFJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;
    gH_db.Execute(
        h_genTFJuncTablesTrans,
        SQLSuccess_TableCreated,
        SQLFail_TableNotCreated,
        priority = DBPrio_High);
}

void Internal_GenerateGlobalJunctionTables() {
    /*
        NOTE:
            If anything goes wrong with this segment
            make sure that the tables are ordered
            correctly in the enum, and here in the
            create statements.
    */
    Transaction h_genGlobalJuncTablesTrans = new Transaction();
    char s_query[2048];
    char s_tableName[64];
    int  i_currentTable = DBTable_PlayersGroups;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING GLOBAL JUNCTION TABLES======");

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.players_groups (GROUPS PER PLAYER)");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`players_groups`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`players_groups` (\
            `steam64_id` VARCHAR(64)    NULL DEFAULT NULL,\
            `group_id`   INT            NULL     DEFAULT NULL,\
            PRIMARY KEY (\
                `steam64_id`,\
                `group_id`\
            ),\
            CONSTRAINT `FK_storeplayersgroups_groups`\
                FOREIGN KEY (`group_id`)\
                REFERENCES `quasar`.`groups` (`id`));");
    h_genGlobalJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.colors_packs (TEXT COLOR PER PACK)");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`colors_packs`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`colors_packs` (\
            `color_id`          VARCHAR(64) NULL DEFAULT NULL,\
            `pack_id`           VARCHAR(64) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `color_id`,\
                `pack_id`\
            ),\
            CONSTRAINT `FK_clrp_colors`\
                FOREIGN KEY (`color_id`)\
                REFERENCES `quasar`.`chat_colors` (`id`),\
            CONSTRAINT `FK_clrp_packs`\
                FOREIGN KEY (`pack_id`)\
                REFERENCES `quasar`.`chat_colors` (`id`));");
    h_genGlobalJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    // I skip creating a foreign key for item_id because
    // it is a column that references multiple tables.
    // I'm not sure if there's a way to set up a foreign
    // key that way so for now I'm using this workaround.
    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.players_items (PLAYER inventories)");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`players_items`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`players_items` (\
            `steam64_id`    VARCHAR(64) NULL DEFAULT NULL,\
            `item_id`       VARCHAR(64) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `steam64_id`,\
                `item_id`\
            ),\
            CONSTRAINT `FK_pi_players`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`));");
    h_genGlobalJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.quasar_loadouts (SERVER ITEM LOADOUTS)");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`quasar_loadouts`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`quasar_loadouts` (\
            `steam64_id`        VARCHAR(64) NULL DEFAULT NULL,\
            `loadout_id`        INT NOT NULL DEFAULT 0,\
            `trail_id`          VARCHAR(64) NULL DEFAULT NULL,\
            `trail_color_r`     INT NOT NULL DEFAULT 255,\
            `trail_color_g`     INT NOT NULL DEFAULT 255,\
            `trail_color_b`     INT NOT NULL DEFAULT 255,\
            `trail_color_a`     INT NOT NULL DEFAULT 255,\
            `trail_width`       INT NOT NULL DEFAULT 8,\
            `connect_sound`     VARCHAR(64) NULL DEFAULT NULL,\
            `disconnect_sound`  VARCHAR(64) NULL DEFAULT NULL,\
            `death_sound`       VARCHAR(64) NULL DEFAULT NULL,\
            `soundboard_1`      VARCHAR(64) NULL DEFAULT NULL,\
            `soundboard_2`      VARCHAR(64) NULL DEFAULT NULL,\
            `soundboard_3`      VARCHAR(64) NULL DEFAULT NULL,\
            `tag_id`            VARCHAR(64) NULL DEFAULT NULL,\
            `name_color`        VARCHAR(64) NULL DEFAULT NULL,\
            `chat_color`        VARCHAR(64) NULL DEFAULT NULL,\
            PRIMARY KEY (\
                `steam64_id`,\
                `loadout_id`\
            ),\
            CONSTRAINT `FK_ql_players`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`),\
            CONSTRAINT `FK_ql_trails`\
                FOREIGN KEY (`trail_id`)\
                REFERENCES `quasar`.`trails` (`item_id`),\
            CONSTRAINT `FK_ql_sound_c`\
                FOREIGN KEY (`connect_sound`)\
                REFERENCES `quasar`.`sounds` (`item_id`),\
            CONSTRAINT `FK_ql_sound_dc`\
                FOREIGN KEY (`disconnect_sound`)\
                REFERENCES `quasar`.`sounds` (`item_id`),\
            CONSTRAINT `FK_ql_sound_die`\
                FOREIGN KEY (`death_sound`)\
                REFERENCES `quasar`.`sounds` (`item_id`),\
            CONSTRAINT `FK_ql_sound_1`\
                FOREIGN KEY (`soundboard_1`)\
                REFERENCES `quasar`.`sounds` (`item_id`),\
            CONSTRAINT `FK_ql_sound_2`\
                FOREIGN KEY (`soundboard_2`)\
                REFERENCES `quasar`.`sounds` (`item_id`),\
            CONSTRAINT `FK_ql_sound_3`\
                FOREIGN KEY (`soundboard_3`)\
                REFERENCES `quasar`.`sounds` (`item_id`),\
            CONSTRAINT `FK_ql_tags`\
                FOREIGN KEY (`tag_id`)\
                REFERENCES `quasar`.`tags` (`item_id`),\
            CONSTRAINT `FK_ql_colors_name`\
                FOREIGN KEY (`name_color`)\
                REFERENCES `quasar`.`chat_colors` (`format`),\
            CONSTRAINT `FK_ql_colors_chat`\
                FOREIGN KEY (`chat_color`)\
                REFERENCES `quasar`.`chat_colors` (`format`));");
    h_genGlobalJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.tf_loadouts (TF ITEM LOADOUTS)");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`tf_loadouts`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`tf_loadouts` (\
            `steam64_id`    VARCHAR(64) NULL DEFAULT NULL,\
            `loadout_id`    INT NOT NULL DEFAULT 0,\
            `loadout_slot`  INT NOT NULL DEFAULT 0,\
            `class`         INT NOT NULL DEFAULT -1,\
            `item_id`       INT NOT NULL DEFAULT -1,\
            `quality`       INT NOT NULL DEFAULT -1,\
            `level`         INT NOT NULL DEFAULT -1,\
            `unusual_id`    INT NOT NULL DEFAULT -1,\
            `paintkit_id`   INT NOT NULL DEFAULT -1,\
            `warpaint_id`   INT NOT NULL DEFAULT -1,\
            PRIMARY KEY (\
                `steam64_id`,\
                `loadout_id`,\
                `loadout_slot`\
            ),\
            CONSTRAINT `FK_tfl_players`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`)\
            CONSTRAINT `FK_tfl_ql`\
                FOREIGN KEY (`loadout_id`)\
                REFERENCES `quasar`.`quasar_loadouts` (`loadout_id`)\
            CONSTRAINT `FK_tfl_classes`\
                FOREIGN KEY (`class`)\
                REFERENCES `quasar`.`tf_classes` (`id`)\
            CONSTRAINT `FK_tfl_tf_items`\
                FOREIGN KEY (`item_id`)\
                REFERENCES `quasar`.`tf_items` (`id`)\
            CONSTRAINT `FK_tfl_qualities`\
                FOREIGN KEY (`quality`)\
                REFERENCES `quasar`.`tf_qualities` (`id`)\
            CONSTRAINT `FK_tfl_particles`\
                FOREIGN KEY (`unusual_id`)\
                REFERENCES `quasar`.`tf_particles` (`id`)\
            CONSTRAINT `FK_tfl_paint_kits`\
                FOREIGN KEY (`paintkit_id`)\
                REFERENCES `quasar`.`tf_paint_kits` (`id`)\
            CONSTRAINT `FK_tfl_war_paints`\
                FOREIGN KEY (`warpaint_id`)\
                REFERENCES `quasar`.`tf_war_paints` (`id`));");
    h_genGlobalJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.taunt_loadouts (TAUNT LOADOUTS)");
    strcopy(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`taunt_loadouts`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`taunt_loadouts` (\
            `steam64_id`,\
            `tf_loadout_id`,\
            `class`,\
            `taunt_id`,\
            `taunt_slot`,\
            `unusual_id`,\
            PRIMARY KEY (\
                `steam64_id`,\
                `loadout_id`,\
                `taunt_slot`\
            ),\
            CONSTRAINT `FK_tl_players`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`)\
            CONSTRAINT `FK_tl_tf_loadouts`\
                FOREIGN KEY (`tf_loadout_id`)\
                REFERENCES `quasar`.`tf_loadouts` (`loadout_id`)\
            CONSTRAINT `FK_tl_tf_items`\
                FOREIGN KEY (`taunt_id`)\
                REFERENCES `quasar`.`tf_items` (`id`)\
            CONSTRAINT `FK_tl_tf_classes`\
                FOREIGN KEY (`class`)\
                REFERENCES `quasar`.`tf_classes` (`id`)\
            CONSTRAINT `FK_tl_tf_particles`\
                FOREIGN KEY (`unusual_id`)\
                REFERENCES `quasar`.`tf_particles` (`id`));");
    h_genGlobalJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    gH_db.Execute(
        h_genGlobalJuncTablesTrans,
        SQLSuccess_TableCreated,
        SQLFail_TableNotCreated,
        priority = DBPrio_High);
}

void Internal_GenerateSubserverJunctionTables() {
    /*
        NOTE:
            If anything goes wrong with this segment
            make sure that the tables are ordered
            correctly in the enum, and here in the
            create statements.
    */
    Transaction h_genSubserverJuncTablesTrans = new Transaction();
    char s_query[2048];
    char s_tableName[64];
    int  i_currentTable = DBTable_SubserverMapFeedback;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING JUNCTION TABLES FOR %s======",
        gS_subserver);

    // Map feedback table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_maps_feedback (MAP FEEDBACK FOR SUBSERVER %s)",
        gS_subserver,
        gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_maps_feedback`\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_maps_feedback` (\
            `id`            VARCHAR(64)     NOT NULL AUTO_INCREMENT,\
            `map_name`      VARCHAR(128)    NOT NULL DEFAULT `NONE`,\
            `steam64_id`    VARCHAR(64)     NULL DEFAULT NULL,\
            `pos_x`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `pos_y`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `pos_z`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `ang_x`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `ang_y`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `ang_z`         DECIMAL         NOT NULL DEFAULT 0.0,\
            `feedback`      VARCHAR(128)    NOT NULL DEFAULT ``,\
            PRIMARY KEY (\
                `id`,\
                `map`,\
                `steam64_id`\
            ),\
            UNIQUE INDEX `id_UNIQUE` (`id` ASC) VISIBLE\
            CONSTRAINT `FK_%s_maps_feedback`\
                FOREIGN KEY (`map_name`)\
                REFERENCES `quasar`.`%s_maps` (`name`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE,\
            CONSTRAINT `FK_%s_maps_feedback_players`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`));",
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver);
    h_genSubserverJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    // Map Ratings Table
    FormatEx(
        s_tableName,
        sizeof(s_tableName),
        "quasar.%s_maps_ratings (MAP RATINGS TABLE FOR SUBSERVER %s)",
        gS_subserver,
        gS_subserver);
    FormatEx(
        s_query,
        sizeof(s_query), "\
        DROP TABLE IF EXISTS `quasar`.`%s_maps_ratings`;\
        CREATE TABLE IF NOT EXISTS `quasar`.`%s_maps_ratings` (\
            `map_name`      VARCHAR(128) NULL DEFAULT NULL,\
            `steam64_id`    VARCHAR(64)  NULL DEFAULT NULL,\
            `rating`        INT          NOT NULL DEFAULT 0,\
            PRIMARY KEY (\
                `map_name`,\
                `steam64_id`,\
                `rating`\
            ),\
            CONTRAINT `FK_%s_maps_ratings`\
                FOREIGN KEY (`map_name`)\
                REFERENCES `quasar`.`%s_maps` (`name`)\
                ON DELETE CASCADE\
                ON UPDATE CASCADE,\
            CONSTRAINT `FK_%s_players_ratings`\
                FOREIGN KEY (`steam64_id`)\
                REFERENCES `quasar`.`players` (`steam64_id`))",
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver);
    h_genSubserverJuncTablesTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;
    gH_db.Execute(
        h_genSubserverJuncTablesTrans,
        SQLSuccess_TableCreated,
        SQLFail_TableNotCreated,
        priority = DBPrio_High);
}

void Internal_GenerateGlobalTableViews() {
    /*
        NOTE:
            If anything goes wrong with this segment
            make sure that the tables are ordered
            correctly in the enum, and here in the
            create statements.
    */
    Transaction h_genViewsTrans = new Transaction();
    char s_query[2048];
    char s_tableName[64];
    int  i_currentTable = DBTable_InventoryView;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING GLOBAL VIEWS======");

    strcopy(
        s_viewName,
        sizeof(s_viewname),
        "quasar.[inventories]");
    strcopy(
        s_query,
        sizeof(s_query),"\
        DROP TABLE IF EXISTS `quasar`.`[inventories]`;\
        DROP VIEW IF EXISTS `quasar`.`[inventories]`;\
        CREATE OR REPLACE VIEW `quasar`.`[inventories]` AS\
            SELECT\
                plyrItms.steam64_id, plyrItms.item_id\
                strTrls.name, strTrls.vtf_filepath\
                    strTrls.vmt_filepath, strTrls.price\
                strTags.name, strTags.format, strTags.price\
                strSnds.name, strSnds.price, strSnds.filepath\
                    strSnds.cooldown, strSnds.activation_word\
                strUpgd.name, strUpgd.price, strUpgd.description\
            FROM players_items plyrItms\
                LEFT JOIN trails strTrls\
                    ON strTrls.item_id = plyrItms.item_id\
                LEFT JOIN tags strTags\
                    ON strTags.item_id = plyrItms.item_id\
                LEFT JOIN sounds strSnds\
                    ON strSnds.item_id = plyrItms.item_id\
                LEFT JOIN upgrades strUpgd\
                    ON strUpgd.item_id = plyrItms.item_id");
    h_genViewsTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;
    gH_db.Execute(
        h_genViewsTrans,
        SQLSuccess_TableCreated,
        SQLFail_TableNotCreated,
        priority = DBPrio_High);
}

void Internal_GenerateSubserverTableViews() {
    /*
        NOTE:
            If anything goes wrong with this segment
            make sure that the tables are ordered
            correctly in the enum, and here in the
            create statements.
    */
    Transaction h_genViewsTrans = new Transaction();
    char s_query[2048];
    char s_tableName[64];
    int  i_currentTable = DBTable_MapRatingView;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======GENERATING VIEWS FOR %s======",
        gS_subserver);

    FormatEx(
        s_viewName,
        sizeof(s_viewname), "\
        quasar.[%s_map_ratings] (Divide total_rating by total_votes)");
    FormatEx(
        s_query,
        sizeof(s_query), "\
            DROP TABLE IF EXISTS `quasar`.`[%s_map_ratings]`;\
            DROP VIEW IF EXISTS `quasar`.`[%s_map_ratings]` ;\
            CREATE  OR REPLACE VIEW `[%s_map_ratings]` AS\
            SELECT vt.name, total_votes, CAST(total_rating/SUM(total_votes) as decimal) rating\
            FROM (\
                SELECT 	m.name,\
                        COUNT(DISTINCT steam64_id) total_votes,\
                        SUM(pm.rating) total_rating\
                FROM `quasar`.`%s_maps` m\
                    JOIN `quasar`.`%s_maps_ratings` pm\
                        ON m.map = pm.map\
                GROUP BY map\
            ) AS vt\
                JOIN srv_playersmaps pm\
                    ON vt.map = pm.map\
            GROUP BY map, total_votes\
            ORDER BY rating DESC;",
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver,
        gS_subserver);
    h_genViewsTrans.AddQuery(s_query, i_currentTable);
    i_currentTable++;
    LOG_CREATE_TABLE_QUERY;

    gH_db.Execute(
        h_genViewsTrans,
        SQLSuccess_TableCreated,
        SQLFail_TableNotCreated,
        priority = DBPrio_High);
}
#undef LOG_CREATE_TABLE_QUERY


#define SEND_INSERT_QUERY QSR_LogQuery(gH_dbLogFile, gH_db, s_query, SQLCB_FillTableDefaults, s_tableName)
// TF items will be handled separately.
void Internal_FillTableDefaults() {
    char s_query[2048];
    char s_tableName[128];

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======FILLING TABLES WITH DEFAULTS======",
        gS_subserver);

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.groups");
    strcopy(
        s_query,
        sizeof(s_query), "\
        INSERT INTO `quasar`.`groups` (`name`) VALUES\
            ('REGULAR'),\
            ('SUPPORTER'),\
            ('CONTRIBUTOR'),\
            ('DONATOR');");
    SEND_INSERT_QUERY;`

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.upgrades");
    strcopy(
        s_query,
        sizeof(squery), "\
        INSERT INTO `quasar`.`upgrades`\
            (`item_id`, `name`, `description`, `price`) VALUES\
            (`ugd_cht_clr`, `Change Chat Color`,            `Change the entire color of your chat using the !chat command!`, `2500`),\
            (`ugd_nme_clr`, `Change Name Color`,            `Change the entire color of your name using the !chat command!`, `5000`),\
            (`ugd_cst_nik`, `Custom Nickname`,              `Set a custom nickname using !nick <nickname>. If you bought the 'Chat Formatting' upgrade you can use color codes in your nickname!`, `5000`),\
            (`ugd_cht_fmt`, `Chat Formatting`,              `Use color tags, i.e. \{red\}Hello!, in your chat and nickname!`, `5000`),\
            (`ugd_cst_jna`, `Custom Join Announcement`,     `If you bought the 'Join Announcement' upgrade you can set a custom message using !chat`, `7500`),\
            (`ugd_cst_lva`, `Custom Leave Announcement`,    `If you bought the 'Leave Announcement' upgrade you can set a custom message using !chat`, `7500`),\
            (`ugd_jin_ann`, `Join Announcement`,             `Announce to the server when you join!`, `2500`),\
            (`ugd_lev_ann`, `Leave Announcement`,            `Announce to the server when you leave!`, `2500`),\
            (`ugd_cst_jns`, `Join Sound`,                   `Play a sound to the server when you join!`, `5000`),\
            (`ugd_cst_lvs`, `Leave Sound`,                  `Play a sound to the server when you leave!`, `5000`),\
            (`ugd_snd_die`, `Death Sound`,                  `Plays a sound at where you died, when you died.`, `2500`),\
            (`ugd_snd_spk`, `Speak Sounds`,                 `Type the name of a sound you own to play it to the whole server! Universal 5 second cooldown for all sounds.`,`7500`),\
            (`ugd_snd_spc`, `Play Sound in Spec`,           `Play sounds while in spectator mode!`, `10000`),\
            (`ugd_snd_ncd`, `No Sound Cooldown`,            `No cooldown on soundboard item you play!`, `20000`),\
            (`ugd_dnt_crd`, `Donate Credits`,               `Donate credits to your friends on the server!`, `5000`),\
            (`ugd_drp_crd`, `Drop Credits`,                 `Drop a pile of credits that other people can pick up which vanishes after a short amount of time.`, `7500`),\
            (`ugd_pnt_cos`, `Paint Your Cosmetics`,         `Paint your cosmetics with paint kit or custom colors!`, `10000`),\
            (`ugd_uns_wep`, `Unusual Weapons`,              `Set an unusual for your weapons!`, `20000`),\
            (`ugd_uns_cos`, `Unusual Cosmetics`,            `Set an unusual for your cosmetics!`, `20000`),\
            (`ugd_uns_tnt`, `Unusual Taunts`,               `Set an unusual for your taunts!`, `20000`),\
            (`ugd_xtr_ldo`, `Additional Loadout`,            `Purchase up to 3 additional loadouts! Works for Team Fortress and server items.`, `7500`);");
    SEND_INSERT_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.sounds");
    strcopy(
        s_query,
        sizeof(s_query), "\
        INSERT INTO `quasar`.`sounds`\
            (`item_id`, `name`, `filepath`, `cooldown`, `price`, `activation_word`) VALUES\
            (`snd_crct`,    `Correct`,                  `sounds/quasar/correct.mp3`,           1.0,      500,  `correct`),\
            (`snd_wrng`,    `Wrong`,                    `sounds/quasar/wrong.mp3`,             1.0,      500,  `wrong`),\
            (`snd_bruh`,    `Bruh`,                     `sounds/quasar/bruh.mp3`,              1.0,      500,  `bruh),\
            (`snd_crow`,    `Crow`,                     `sounds/quasar/crow.mp3`,              0.5,      250,  `caw`),\
            (`snd_door`,    `opun dorr`,                `sounds/quasar/open_door.mp3`,         1.0,     1000,  `open door`),\
            (`snd_gate`,    `OPEN THE GATE`,            `sounds/quasar/open_the_gate.mp3`,     0.5,      250,  `open the gate`),\
            (`snd_augh`,    `Augh`,                     `sounds/quasar/augh.mp3`,              0.1,     1000,  `augh`),\
            (`snd_tada`,    `Tada`,                     `sounds/quasar/tada.mp3`,              1.0,      250,  `tada`),\
            (`snd_fish`,    `FISH`,                     `sounds/quasar/fish.mp3`,              1.0,      500,  `fish`),\
            (`snd_huh`,     `Huh`,                      `sounds/quasar/huh.mp3`,               0.5,      500,  `huh`),\
            (`snd_uuua`,    `UUUA`,                     `sounds/quasar/uuua.mp3`,              1.0,     1000,  `uuua`),\
            (`snd_aaau`,    `AAAU`,                     `sounds/quasar/aaau.mp3`,              1.0,     1000,  `aaau`),\
            (`snd_yoyi`,    `YOYOI`,                    `sounds/quasar/yoyoi.mp3`,             1.0,      500,  `yoyoi`),\
            (`snd_airh`,    `Air Horn`,                 `sounds/quasar/air_horn.mp3`,          0.2,     1500,  `mlg`),\
            (`snd_bttb`,    `Bad To The Bone`,          `sounds/quasar/bttb.mp3`,              2.0,     1500,  `skull`),\
            (`snd_cdid`,    `Ganon Die`,                `sounds/quasar/cdi_die.mp3`,           0.2,      500,  `it burns`),\
            (`snd_wooo`,    `Cr1tikal Woo`,             `sounds/quasar/cr1tikal_woo.mp3`,      1.0,     1500,  `woo`),\
            (`snd_doit`,    `DOIT`,                     `sounds/quasar/chinese_doit.mp3`,      0.2,      500,  `doit`),\
            (`snd_fwrb`,    `Fart (w Reverb)`,          `sounds/quasar/fwr.mp3`,               2.0,     1000,  `fart`),\
            (`snd_lgyd`,    `Lego Yoda Scream`,         `sounds/quasar/lego_yoda.mp3`,         0.8,      500,  `yoda`),\
            (`snd_mtpe`,    `Metal Pipe`,               `sounds/quasar/metal_pipe.mp3`,        1.0,     2000,  `pipe`),\
            (`snd_alrt`,    `MGS Alert`,                `sounds/quasar/mgs_alert.mp3`,         1.0,     1000,  `snake`),\
            (`snd_oof`,     `Oof`,                      `sounds/quasar/oof.mp3`,               0.2,     2000,  `oof`),\
            (`snd_pngs`,    `Pingas`,                   `sounds/quasar/pingas.mp3`,            0.5,      500,  `pingas`),\
            (`snd_rizz`,    `Rizz`,                     `sounds/quasar/rizz.mp3`,              1.0,      500,  `rizz`),\
            (`snd_spen`,    `SPEEN`,                    `sounds/quasar/speen.mp3`,             1.0,      750,  `speen`),\
            (`snd_sque`,    `Squee`,                    `sounds/quasar/squee.mp3`,             0.2,      750,  `squee`),\
            (`snd_sus`,     `Among Us Sting`,           `sounds/quasar/uhoh_sussy.mp3`,        3.0,     2500,  `sussy`),\
            (`snd_vsce`,    `VSauce Scream`,            `sounds/quasar/vsauce_scream.mp3`,     2.0,     1500,  `vsauce`),\
            (`snd_bonk`,    `Bonk`,                     `sounds/quasar/bonk.mp3`,              0.2,     1000,  `bonk`),\
            (`snd_bbym`,    `Baby Mario`,               `sounds/quasar/baby_mario.mp3`,        0.5,     2500,  `waah`),\
            (`snd_bwmp`,    `Boowomp`,                  `sounds/quasar/boowomp.mp3`,           0.3,     1000,  `boowomp`),\
            (`snd_guts`,    `Gutsman's Ass`,            `sounds/quasar/gutsman.mp3`,           2.0,      500,  `ass`),\
            (`snd_womy`,    `Woomy`,                    `sounds/quasar/woomy.mp3`,             0.4,      750,  `woomy`),\
            (`snd_hkwp`,    `Waterphone`,               `sounds/quasar/hkwphone.mp3`,          4.2,     1500,  `suspense`),\
            (`snd_hlml`,    `Holay Molay`,              `sounds/quasar/holay_molay.mp3`,       0.8,      750,  `holay molay`),\
            (`snd_lean`,    `I LOVE LEAN`,              `sounds/quasar/lean.mp3`,              0.3,     1000,  `lean`),\
            (`snd_bigb`,    `TKFB - Big Man's Back`,    `sounds/quasar/bigman_back.mp3`,       2.0,      750,  `big man's back`),\
            (`snd_bigq`,    `TKFB - QUALUUDES!`,        `sounds/quasar/bigman_ludes.mp3`,      2.8,     1000,  `qualuudes`),\
            (`snd_bigl`,    `TKFB - Big Man Signin Off`,`sounds/quasar/bigman_signoff.mp3`,    1.5,      750,  `signin off`),\
            (`snd_bigk`,    `TKFB - Happy To See Ya`,   `sounds/quasar/bigman_happy.mp3`,      1.7,      750,  `happy to see ya`),\
            (`snd_skbd`,    `Skibidi`,                  `sounds/quasar/skibidi.mp3`,           4.0,     2500,  `skibidi`),\
            (`snd_smk`,     `Smoke Weed`,               `sounds/quasar/snoop_smoke.mp3`,       1.8,     1000,  `weed`),\
            (`snd_shia`,    `Shia LaBeouf DO IT!`,      `sounds/quasar/shia_doit.mp3`,         0.3,      500,  `do it`),\
            (`snd_come`,    `COME!`,                    `sounds/quasar/come.mp3`,              1.0,      500,  `come`),\
            (`snd_w95s`,    `Windows 95 Startup`,       `sounds/quasar/win95_start.mp3`,       5.2,     1000,  `95 startup`),\
            (`snd_w98s`,    `Windows 98 Startup`,       `sounds/quasar/win98_start.mp3`,       6.5,     1000   `98 startup`),\
            (`snd_w98l`,    `Windows 98 Shutdown`,      `sounds/quasar/win98_shut.mp3`,        3.2,     1000,  `98 shutdown`),\
            (`snd_wXPs`,    `Windows XP Startup`,       `sounds/quasar/winXP_start.mp3`,       3.3,     1000,  `xp startup`),\
            (`snd_wXPl`,    `Windows XP Shutdown`,      `sounds/quasar/winXP_shut.mp3`,        2.2,     1000,  `xp shutdown`),\
            (`snd_klnm`,    `Klonoa - Munya`,           `sounds/quasar/klonoa_munya.mp3`,      0.1,      750,  `munya`),\
            (`snd_klnw`,    `Klonoa - WAHOO!`,          `sounds/quasar/klonoa_wahoo.mp3`,      0.1,      750,  `wahoo`),\
            (`snd_yipe`,    `Yipeee`,                   `sounds/quasar/yipee.mp3`,             0.2,     2500,  `yipee`);");
    SEND_INSERT_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.trails");
    strcopy(
        s_query,
        sizeof(s_query), "\
        INSERT INTO `quasar`.`trails`\
            (item_id, name, vtf_filepath, vmt_filepath, price) VALUES\
            (`trl_beam`,     `Regular Beam`,    `materials/quasar/trails/beam.vtf`,        `materials/quasar/trails/beam.vmt`,         500),\
            (`trl_weed`,     `Weed Leaves`,     `materials/quasar/trails/weed.vtf`,        `materials/quasar/trails/weed.vmt`,        1000),\
            (`trl_star`,     `Stars`,           `materials/quasar/trails/stars.vtf`,       `materials/quasar/trails/stars.vmt`,        500),\
            (`trl_dick`,     `Dicks`,           `materials/quasar/trails/phallus.vtf`,     `materials/quasar/trails/phallus.vmt`,     1500),\
            (`trl_rnbw`,     `Rainbow`,         `materials/quasar/trails/rainbow.vtf`,     `materials/quasar/trails/rainbow.vmt`,     2000),\
            (`trl_hrts`,     `Hearts`,          `materials/quasar/trails/hearts.vtf`,      `materials/quasar/trails/hearts.vmt`,      1000),\
            (`trl_swfk`,     `Snowflakes`,      `materials/quasar/trails/snowflakes.vtf`,  `materials/quasar/trails/snowflakes.vmt`,  1500),\
            (`trl_lolo`,     `LOLOLOLO`,        `materials/quasar/trails/lololo.vtf`,      `materials/quasar/trails/lololo.vmt`,      1000),\
            (`trl_wsmh`,     `Will Smith`,      `materials/quasar/trails/willsmith.vtf`,   `materials/quasar/trails/willsmith.vmt`,    750),\
            (`trl_trll`,     `Troll Face`,      `materials/quasar/trails/trollface.vtf`,   `materials/quasar/trails/trollface.vmt`,    750),\
            (`trl_awsm`,     `Awesome Face`,    `materials/quasar/trails/awesomeface.vtf`, `materials/quasar/trails/awesomeface.vmt`, 1000),\
            (`trl_spdg`,     `Snoop Dogg`,      `materials/quasar/trails/snoopdogg.vtf`,   `materials/quasar/trails/snoopdogg.vmt`,   1000),\
            (`trl_tran`,     `Trans Flag`,      `materials/quasar/trails/transflag.vtf`,   `materials/quasar/trails/transflag.vmt`,    250),\
            (`trl_ace`,      `Ace Flag`,        `materials/quasar/trails/aceflag.vtf`,     `materials/quasar/trails/aceflag.vmt`,      250),\
            (`trl_lgbt`,     `LGBT Flag`,       `materials/quasar/trails/lgbtflag.vtf`,    `materials/quasar/trails/lgbtflag.vmt`,     250),\
            (`trl_aro`,      `Aro Flag`,        `materials/quasar/trails/aroflag.vtf`,     `materials/quasar/trails/aroflag.vmt`,      250),\
            (`trl_mtdw`,     `Mountain Dew`,    `materials/quasar/trails/mtndew.vtf`,      `materials/quasar/trails/mtndew.vmt`,      1000),\
            (`trl_mnst`,     `Monster Cans`,    `materials/quasar/trails/mnstrcan.vtf`,    `materials/quasar/trails/mnstrcan.vmt`,    1000),\
            (`trl_nyan`,     `Nyan Cat`,        `materials/quasar/trails/nyancat.vtf`,     `materials/quasar/trails/nyancat.vmt`,     2000);");
    SEND_INSERT_QUERY;

    strcopy(
        s_tableName,
        sizeof(s_tableName),
        "quasar.chat_colors");
    strcopy(
        s_query,
        sizeof(s_query), "\
        INSERT INTO `quasar`.`chat_colors`\
            (`format`, `name`, `category`)\
        VALUES\
            (`aliceblue`,`Alice Blue`,`Greyscale`),\
            (`allies`,`Allies`,`Green`),\
            (`ancient`,`Ancient`,`Red`),\
            (`antiquewhite`,`Antique White`,`Greyscale`),\
            (`aqua`,`Aqua`,`Blue`),\
            (`aquamarine`,`Aquamarine`,`Green`),\
            (`arcana`,`Arcana`,`Green`),\
            (`axis`,`Axis`,`Red`),\
            (`azure`,`Azure`,`Blue`),\
            (`beige`,`Beige`,`Greyscale`),\
            (`bisque`,`Bisque`,`Greyscale`),\
            (`black`,`Black`,`Greyscale`),\
            (`blanchedalmond`,`Blanched Almond`,`Greyscale`),\
            (`blue`,`Blue`,`Blue`),\
            (`blueviolet`,`Blue Violet`,`Pink/Purple`),\
            (`brown`,`Brown`,`Browns`),\
            (`burlywood`,`Burly Wood`,`Browns`),\
            (`cadetblue`,`Cadet Blue`,`Blue`),\
            (`chartreuse`,`Chartreuse`,`Green`),\
            (`chocolate`,`Chocolate`,`Browns`),\
            (`collectors`,`Collectors`,`Red`),\
            (`common`,`Common`,`Blue`),\
            (`community`,`Community`,`Green`),\
            (`coral`,`Coral`,`Orange`),\
            (`cornflowerblue`,`Cornflower Blue`,`Blue`),\
            (`cornsilk`,`Corn Silk`,`Greyscale`),\
            (`corrupted`,`Corrupted`,`Red`),\
            (`crimson`,`Crimson`,`Red`),\
            (`cyan`,`Cyan`,`Blue`),\
            (`darkblue`,`Dark Blue`,`Blue`),\
            (`darkcyan`,`Dark Cyan`,`Blue`),\
            (`darkgoldenrod`,`Dark Goldenrod`,`Browns`),\
            (`darkgray`,`Dark Gray`,`Greyscale`),\
            (`darkgrey`,`Dark Grey`,`Greyscale`),\
            (`darkgreen`,`Dark Green`,`Green`),\
            (`darkkhaki`,`Dark Khaki`,`Yellow`),\
            (`darkmagenta`,`Dark Magenta`,`Pink/Purple`),\
            (`darkolivegreen`,`Dark Olive Green`,`Green`),\
            (`darkorange`,`Dark Orange`,`Orange`),\
            (`darkorchid`,`Dark Orchid`,`Pink/Purple`),\
            (`darkred`,`Dark Red`,`Red`),\
            (`darksalmon`,`Dark Salmon`,`Orange`),\
            (`darkseagreen`,`Dark Sea Green`,`Green`),\
            (`darkslateblue`,`Dark Slate Blue`,`Pink/Purple`),\
            (`darkslategray`,`Dark Slate Gray`,`Greyscale`),\
            (`darkslategrey`,`Dark Slate Grey`,`Greyscale`),\
            (`darkturquoise`,`Dark Turquoise`,`Blue`),\
            (`darkviolet`,`Dark Violet`,`Pink/Purple`),\
            (`deeppink`,`Deep Pink`,`Pink/Purple`),\
            (`deepskyblue`,`Deep Sky Blue`,`Blue`),\
            (`dimgray`,`Dim Gray`,`Greyscale`),\
            (`dimgrey`,`Dim Grey`,`Greyscale`),\
            (`dodgerblue`,`Dodger Blue`,`Blue`),\
            (`exalted`,`Exalted`,`Greyscale`),\
            (`firebrick`,`Fire Brick`,`Red`),\
            (`floralwhite`,`Floral White`,`Greyscale`),\
            (`forestgreen`,`Forest Green`,`Green`),\
            (`frozen`,`Frozen`,`Green`),\
            (`fuschia`,`Fuchsia`,`Pink/Purple`),\
            (`fullblue`,`Full Blue`,`Blue`),\
            (`fullred`,`Full Red`,`Red`),\
            (`gainsboro`,`Gainsboro`,`Greyscale`),\
            (`genuine`,`Genuine`,`Green`),\
            (`ghostwhite`,`Ghost White`,`Greyscale`),\
            (`gold`,`Gold`,`Yellow`),\
            (`goldenrod`,`Goldenrod`,`Yellow`),\
            (`gray`,`Gray`,`Greyscale`),\
            (`grey`,`Grey`,`Greyscale`),\
            (`green`,`Green`,`Green`),\
            (`greenyellow`,`Green Yellow`,`Green`),\
            (`haunted`,`Haunted`,`Green`),\
            (`honeydew`,`Honey Dew`,`Greyscale`),\
            (`hotpink`,`Hot Pink`,`Pink/Purple`),\
            (`immortal`,`Immortal`,`Yellow`),\
            (`indianred`,`Indian Red`,`Red`),\
            (`indigo`,`Indigo`,`Pink/Purple`),\
            (`ivory`,`Ivory`,`Greyscale`),\
            (`khaki`,`Khaki`,`Yellow`),\
            (`lavender`,`Lavender`,`Pink/Purple`),\
            (`lavenderblush`,`Lavender Blush`,`Pink/Purple`),\
            (`lawngreen`,`Lawn Green`,`Green`),\
            (`legendary`,`Legendary`,`Pink/Purple`),\
            (`lemonchiffon`,`Lemon Chiffon`,`Yellow`),\
            (`lightblue`,`Light Blue`,`Blue`),\
            (`lightcoral`,`Light Coral`,`Pink/Purple`),\
            (`lightcyan`,`Light Cyan`,`Blue`),\
            (`lightgoldenrodyellow`,`Light Goldenrod Yellow`,`Yellow`),\
            (`lightgray`,`Light Gray`,`Greyscale`),\
            (`lightgrey`,`Light Grey`,`Greyscale`),\
            (`lightgreen`,`Light Green`,`Green`),\
            (`lightpink`,`Light Pink`,`Pink/Purple`),\
            (`lightsalmon`,`Light Salmon`,`Orange`),\
            (`lightseagreen`,`Light Sea Green`,`Green`),\
            (`lightskyblue`,`Light Sky Blue`,`Blue`),\
            (`lightslategray`,`Light Slate Gray`,`Greyscale`),\
            (`lightslategrey`,`Light Slate Grey`,`Greyscale`),\
            (`lightsteelblue`,`Light Steel Blue`,`Blue`),\
            (`lightyellow`,`Light Yellow`,`Yellow`),\
            (`lime`,`Lime`,`Green`),\
            (`limegreen`,`Lime Green`,`Green`),\
            (`linen`,`Linen`,`Greyscale`),\
            (`magenta`,`Magenta`,`Pink/Purple`),\
            (`maroon`,`Maroon`,`Red`),\
            (`mediumaquamarine`,`Medium Aquamarine`,`Green`),\
            (`mediumblue`,`Medium Blue`,`Blue`),\
            (`mediumorchid`,`Medium Orchid`,`Pink/Purple`),\
            (`mediumpurple`,`Medium Purple`,`Pink/Purple`),\
            (`mediumseagreen`,`Medium Sea Green`,`Green`),\
            (`mediumslateblue`,`Medium Slate Blue`,`Pink/Purple`),\
            (`mediumspringgreen`,`Medium Spring Green`,`Green`),\
            (`mediumturquoise`,`Medium Turquoise`,`Blue`),\
            (`mediumvioletred`,`Medium Violet Red`,`Pink/Purple`),\
            (`midnightblue`,`Midnight Blue`,`Blue`),\
            (`mintcream`,`Mint Cream`,`Greyscale`),\
            (`mistyrose`,`Misty Rose`,`Pink/Purple`),\
            (`moccasin`,`Moccasin`,`Yellow`),\
            (`mythical`,`Mythical`,`Pink/Purple`),\
            (`navajowhite`,`Navajo White`,`Orange`),\
            (`navy`,`Navy`,`Blue`),\
            (`normal`,`Normal`,`Greyscale`),\
            (`oldlace`,`Old Lace`,`Greyscale`),\
            (`olive`,`Olive`,`Green`),\
            (`olivedrab`,`Olive Drab`,`Green`),\
            (`orange`,`Orange`,`Orange`),\
            (`orangered`,`Orange Red`,`Orange`),\
            (`orchid`,`Orchid`,`Pink/Purple`),\
            (`palegoldenrod`,`Pale Goldenrod`,`Yellow`),\
            (`palegreen`,`Pale Green`,`Green`),\
            (`paleturquoise`,`Pale Turquoise`,`Blue`),\
            (`palevioletred`,`Pale Violet Red`,`Pink/Purple`),\
            (`papayawhip`,`Papaya Whip`,`Yellow`),\
            (`peachpuff`,`Peach Puff`,`Orange`),\
            (`peru`,`Peru`,`Browns`),\
            (`pink`,`Pink`,`Pink/Purple`),\
            (`plum`,`Plum`,`Pink/Purple`),\
            (`powderblue`,`Powder Blue`,`Blue`),\
            (`purple`,`Purple`,`Pink/Purple`),\
            (`rare`,`Rare`,`Blue`),\
            (`red`,`Red`,`Red`),\
            (`rosybrown`,`Rosy Brown`,`Browns`),\
            (`royalblue`,`Royal Blue`,`Blue`),\
            (`saddlebrown`,`Saddle Brown`,`Browns`),\
            (`salmon`,`Salmon`,`Orange`),\
            (`sandybrown`,`Sandy Brown`,`Browns`),\
            (`seagreen`,`Sea Green`,`Green`),\
            (`seashell`,`Seashell`,`Greyscale`),\
            (`selfmade`,`Self-Made`,`Green`),\
            (`sienna`,`Sienna`,`Browns`),\
            (`silver`,`Silver`,`Greyscale`),\
            (`skyblue`,`Sky Blue`,`Blue`),\
            (`slateblue`,`Slate Blue`,`Pink/Purple`),\
            (`slategray`,`Slate Gray`,`Greyscale`),\
            (`slategrey`,`Slate Grey`,`Greyscale`),\
            (`snow`,`Snow`,`Greyscale`),\
            (`springgreen`,`Spring Green`,`Green`),\
            (`steelblue`,`Steel Blue`,`Blue`),\
            (`strange`,`Strange`,`Orange`),\
            (`tan`,`Tan`,`Browns`),\
            (`teal`,`Teal`,`Blue`),\
            (`thistle`,`Thistle`,`Pink/Purple`),\
            (`tomato`,`Tomato`,`Orange`),\
            (`turquoise`,`Turquoise`,`Blue`),\
            (`uncommon`,`Uncommon`,`Blue`),\
            (`unique`,`Unique`,`Yellow`),\
            (`unusual`,`Unusual`,`Pink/Purple`),\
            (`valve`,`Valve`,`Pink/Purple`),\
            (`vintage`,`Vintage`,`Blue`),\
            (`violet`,`Violet`,`Pink/Purple`),\
            (`wheat`,`Wheat`,`Yellow`),\
            (`white`,`White`,`Greyscale`),\
            (`whitesmoke`,`White Smoke`,`Greyscale`),\
            (`yellow`,`Yellow`,`Yellow`),\
            (`yellowgreen`,`Yellow Green`,`Green`);");
    SEND_INSERT_QUERY;

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "======FILLED TABLES WITH DEFAULTS======",
        gS_subserver);
}
#undef SEND_INSERT_QUERY


public void SQLSuccess_TableCreated(Database db, any data, int numQueries, DBResultSet[] results, int[] createdTables) {
    for (int i; i < numQueries; i++) {
        gB_upToDateTables[createdTables[i]] = true;
        QSR_LogMessage(
            gH_dbLogFile,
            MODULE_NAME,
            "TABLE CREATED: %s",
            gS_tableNames[createdTables[i]]);
    }
}

public void SQLFail_TableNotCreated(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData) {
    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "TRANSACTION FAILED. \n%s (Fail at %d/%d)\n== Tables ==",
        error,
        failIndex,
        numQueries);

    char s_tableName[64];
    for (int i; i < numQueries; i++) {
        FormatEx(
            s_tableName,
            sizeof(s_tableName),
            "\n%s",
            gS_tableNames[createdTables[i]]);

        if (i < failIndex)
            gB_upToDateTables[i] = true;
    }
}

void SQLCB_FillTableDefaults(Database db, DBResultSet results, const char[] error, const char[] tableName) {
    if (error[0]) {
        QSR_LogMessage(
            gH_dbLogFile,
            MODULE_NAME,
            "ERROR FILLING %s WITH DEFAULTS! %s",
            tableName,
            error);
        return;
    }

    QSR_LogMessage(
        gH_dbLogFile,
        MODULE_NAME,
        "SUCCESSFULLY FILLED %s WITH DEFAULTS!",
        tableName);
}
