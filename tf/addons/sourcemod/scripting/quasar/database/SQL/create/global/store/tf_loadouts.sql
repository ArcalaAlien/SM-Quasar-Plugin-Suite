--?29
DROP TABLE IF EXISTS `quasar`.`tf_loadouts`;
CREATE TABLE IF NOT EXISTS `quasar`.`tf_loadouts` (
    `steam64_id`    VARCHAR(64) NULL DEFAULT NULL,
    `loadout_id`    INT NOT NULL DEFAULT 0,
    `loadout_slot`  INT NOT NULL DEFAULT 0,
    `class`         INT NOT NULL DEFAULT -1,
    `item_id`       INT NOT NULL DEFAULT -1,
    `quality`       INT NOT NULL DEFAULT -1,
    `level`         INT NOT NULL DEFAULT -1,
    `unusual_id`    INT NOT NULL DEFAULT -1,
    `paintkit_id`   INT NOT NULL DEFAULT -1,
    `warpaint_id`   INT NOT NULL DEFAULT -1,
    PRIMARY KEY (
        `steam64_id`,
        `loadout_id`,
        `loadout_slot`
    ),
    CONSTRAINT `FK_tfl_players`
        FOREIGN KEY (`steam64_id`)
        REFERENCES `quasar`.`players` (`steam64_id`)
    CONSTRAINT `FK_tfl_ql`
        FOREIGN KEY (`loadout_id`)
        REFERENCES `quasar`.`quasar_loadouts` (`loadout_id`)
    CONSTRAINT `FK_tfl_classes`
        FOREIGN KEY (`class`)
        REFERENCES `quasar`.`tf_classes` (`id`)
    CONSTRAINT `FK_tfl_tf_items`
        FOREIGN KEY (`item_id`)
        REFERENCES `quasar`.`tf_items` (`id`)
    CONSTRAINT `FK_tfl_qualities`
        FOREIGN KEY (`quality`)
        REFERENCES `quasar`.`tf_qualities` (`id`)
    CONSTRAINT `FK_tfl_particles`
        FOREIGN KEY (`unusual_id`)
        REFERENCES `quasar`.`tf_particles` (`id`)
    CONSTRAINT `FK_tfl_paint_kits`
        FOREIGN KEY (`paintkit_id`)
        REFERENCES `quasar`.`tf_paint_kits` (`id`)
    CONSTRAINT `FK_tfl_war_paints`
        FOREIGN KEY (`warpaint_id`)
        REFERENCES `quasar`.`tf_war_paints` (`id`));
