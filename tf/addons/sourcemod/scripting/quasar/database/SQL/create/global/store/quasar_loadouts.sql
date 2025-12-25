--?28
DROP TABLE IF EXISTS `quasar`.`quasar_loadouts`;
CREATE TABLE IF NOT EXISTS `quasar`.`quasar_loadouts` (
    `steam64_id`        VARCHAR(64) NULL DEFAULT NULL,
    `loadout_id`        INT NOT NULL DEFAULT 0,
    `trail_id`          VARCHAR(64) NULL DEFAULT NULL,
    `trail_color_r`     INT NOT NULL DEFAULT 255,
    `trail_color_g`     INT NOT NULL DEFAULT 255,
    `trail_color_b`     INT NOT NULL DEFAULT 255,
    `trail_color_a`     INT NOT NULL DEFAULT 255,
    `trail_width`       INT NOT NULL DEFAULT 8,
    `connect_sound`     VARCHAR(64) NULL DEFAULT NULL,
    `disconnect_sound`  VARCHAR(64) NULL DEFAULT NULL,
    `death_sound`       VARCHAR(64) NULL DEFAULT NULL,
    `soundboard_1`      VARCHAR(64) NULL DEFAULT NULL,
    `soundboard_2`      VARCHAR(64) NULL DEFAULT NULL,
    `soundboard_3`      VARCHAR(64) NULL DEFAULT NULL,
    `tag_id`            VARCHAR(64) NULL DEFAULT NULL,
    `name_color`        VARCHAR(64) NULL DEFAULT NULL,
    `chat_color`        VARCHAR(64) NULL DEFAULT NULL,
    PRIMARY KEY (
        `steam64_id`,
        `loadout_id`
    ),
    CONSTRAINT `FK_ql_players`
        FOREIGN KEY (`steam64_id`)
        REFERENCES `quasar`.`players` (`steam64_id`),
    CONSTRAINT `FK_ql_trails`
        FOREIGN KEY (`trail_id`)
        REFERENCES `quasar`.`trails` (`item_id`),
    CONSTRAINT `FK_ql_sound_c`
        FOREIGN KEY (`connect_sound`)
        REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_dc`
        FOREIGN KEY (`disconnect_sound`)
        REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_die`
        FOREIGN KEY (`death_sound`)
        REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_1`
        FOREIGN KEY (`soundboard_1`)
        REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_2`
        FOREIGN KEY (`soundboard_2`)
        REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_sound_3`
        FOREIGN KEY (`soundboard_3`)
        REFERENCES `quasar`.`sounds` (`item_id`),
    CONSTRAINT `FK_ql_tags`
        FOREIGN KEY (`tag_id`)
        REFERENCES `quasar`.`tags` (`item_id`),
    CONSTRAINT `FK_ql_colors_name`
        FOREIGN KEY (`name_color`)
        REFERENCES `quasar`.`chat_colors` (`format`),
    CONSTRAINT `FK_ql_colors_chat`
        FOREIGN KEY (`chat_color`)
        REFERENCES `quasar`.`chat_colors` (`format`));
