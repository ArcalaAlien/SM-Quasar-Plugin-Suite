-- ?30
CREATE TABLE IF NOT EXISTS `quasar`.`taunt_loadouts` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `tf_loadout_id` INT DEFAULT 1,
    `class` INT DEFAULT 1,
    `taunt_id` INT DEFAULT 0,
    `taunt_slot` INT DEFAULT 0,
    `unusual_id` INT DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_taunt_loadouts_id` (`id` ASC),
    UNIQUE INDEX `idx_tl_player_loadout_slot_class` (`steam64_id` ASC, `tf_loadout_id` ASC, `taunt_slot` ASC, `class` ASC),
    INDEX `idx_tl_players_steam64_id` (`steam64_id` ASC),
    INDEX `idx_tl_tf_loadout_id` (`tf_loadout_id` ASC),
    INDEX `idx_tl_tf_items` (`taunt_id` ASC),
    INDEX `idx_tl_tf_classes` (`class` ASC),
    INDEX `idx_tl_tf_particles` (`unusual_id` ASC),
    CONSTRAINT `FK_tl_players`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`),
    CONSTRAINT `FK_tl_tf_loadouts`
    FOREIGN KEY (`steam64_id`, `tf_loadout_id`)
    REFERENCES `quasar`.`tf_loadouts` (`steam64_id`, `loadout_id`),
    CONSTRAINT `FK_tl_tf_items`
    FOREIGN KEY (`taunt_id`)
    REFERENCES `quasar`.`tf_items` (`id`),
    CONSTRAINT `FK_tl_tf_classes`
    FOREIGN KEY (`class`)
    REFERENCES `quasar`.`tf_classes` (`id`),
    CONSTRAINT `FK_tl_tf_particles`
    FOREIGN KEY (`unusual_id`)
    REFERENCES `quasar`.`tf_particles` (`id`)
);
