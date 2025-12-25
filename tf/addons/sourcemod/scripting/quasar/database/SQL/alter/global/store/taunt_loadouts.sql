--?30
DROP TABLE IF EXISTS `quasar`.`taunt_loadouts`;
CREATE TABLE IF NOT EXISTS `quasar`.`taunt_loadouts` (
    `steam64_id`,
    `tf_loadout_id`,
    `class`,
    `taunt_id`,
    `taunt_slot`,
    `unusual_id`,
    PRIMARY KEY (
        `steam64_id`,
        `loadout_id`,
        `taunt_slot`
    ),
    CONSTRAINT `FK_tl_players`
        FOREIGN KEY (`steam64_id`)
        REFERENCES `quasar`.`players` (`steam64_id`)
    CONSTRAINT `FK_tl_tf_loadouts`
        FOREIGN KEY (`tf_loadout_id`)
        REFERENCES `quasar`.`tf_loadouts` (`loadout_id`)
    CONSTRAINT `FK_tl_tf_items`
        FOREIGN KEY (`taunt_id`)
        REFERENCES `quasar`.`tf_items` (`id`)
    CONSTRAINT `FK_tl_tf_classes`
        FOREIGN KEY (`class`)
        REFERENCES `quasar`.`tf_classes` (`id`)
    CONSTRAINT `FK_tl_tf_particles`
        FOREIGN KEY (`unusual_id`)
        REFERENCES `quasar`.`tf_particles` (`id`));
