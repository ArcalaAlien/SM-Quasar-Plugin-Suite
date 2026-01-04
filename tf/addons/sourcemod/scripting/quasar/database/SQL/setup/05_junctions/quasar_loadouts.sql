-- ?28
CREATE TABLE IF NOT EXISTS `quasar`.`quasar_loadouts` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `loadout_id` INT NOT NULL DEFAULT 0,
    `trail_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `trail_color_r` INT NOT NULL DEFAULT 255,
    `trail_color_g` INT NOT NULL DEFAULT 255,
    `trail_color_b` INT NOT NULL DEFAULT 255,
    `trail_color_a` INT NOT NULL DEFAULT 255,
    `trail_width` INT NOT NULL DEFAULT 8,
    `connect_sound` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `disconnect_sound` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `death_sound` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `soundboard1_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `soundboard2_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `soundboard3_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `tag_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `name_color` VARCHAR(64) NOT NULL DEFAULT 'NONE',
    `chat_color` VARCHAR(64) NOT NULL DEFAULT 'NONE',
    PRIMARY KEY (
        `id`,
        `steam64_id`,
        `loadout_id`
    ),
    UNIQUE INDEX `idx_quasar_loadouts_id` (`id` ASC),
    INDEX `idx_quasar_loadouts_steam64_id` (`steam64_id` ASC),
    INDEX `idx_quasar_loadouts_loadout_id` (`loadout_id` ASC),
    INDEX `idx_quasar_loadouts_trail_id` (`trail_id` ASC),
    INDEX `idx_quasar_loadouts_connect_sound` (`connect_sound` ASC),
    INDEX `idx_quasar_loadouts_disconnect_sound` (`disconnect_sound` ASC),
    INDEX `idx_quasar_loadouts_death_sound` (`death_sound` ASC),
    INDEX `idx_quasar_loadouts_soundboard_1` (`soundboard1_id` ASC),
    INDEX `idx_quasar_loadouts_soundboard_2` (`soundboard2_id` ASC),
    INDEX `idx_quasar_loadouts_soundboard_3` (`soundboard3_id` ASC),
    INDEX `idx_quasar_loadouts_tag_id` (`tag_id` ASC),
    INDEX `idx_quasar_loadouts_name_color` (`name_color` ASC),
    INDEX `idx_quasar_loadouts_chat_color` (`chat_color` ASC),
    CONSTRAINT `FK_ql_players`
    FOREIGN KEY (`steam64_id`) REFERENCES `quasar`.`players` (`steam64_id`),
    CONSTRAINT `FK_ql_trails`
    FOREIGN KEY (`trail_id`) REFERENCES `quasar`.`trails` (`item_id`),
    CONSTRAINT `FK_ql_sound_c`
    FOREIGN KEY (`connect_sound`) REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_dc`
    FOREIGN KEY (`disconnect_sound`) REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_die`
    FOREIGN KEY (`death_sound`) REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_1`
    FOREIGN KEY (`soundboard1_id`) REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_2`
    FOREIGN KEY (`soundboard2_id`) REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_3`
    FOREIGN KEY (`soundboard3_id`) REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_tags`
    FOREIGN KEY (`tag_id`) REFERENCES `quasar`.`tags` (`item_id`),
    CONSTRAINT `FK_ql_colors_name`
    FOREIGN KEY (`name_color`) REFERENCES `quasar`.`chat_colors` (`format`),
    CONSTRAINT `FK_ql_colors_chat`
    FOREIGN KEY (`chat_color`) REFERENCES `quasar`.`chat_colors` (`format`)
);
