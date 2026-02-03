-- ?29
CREATE TABLE IF NOT EXISTS `quasar`.`tf_loadouts` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `loadout_id` INT NOT NULL DEFAULT 1,
    `loadout_slot` INT NOT NULL DEFAULT 0,
    `class` INT NOT NULL DEFAULT 1,
    `item_id` INT NOT NULL DEFAULT -1,
    `quality` INT NOT NULL DEFAULT 1,
    `level` INT NOT NULL DEFAULT 1,
    `unusual_id` INT NOT NULL DEFAULT -1,
    `paintkit_id` INT NOT NULL DEFAULT -1,
    `warpaint_id` INT NOT NULL DEFAULT -1,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_tf_loadouts_id` (`id` ASC),
    UNIQUE INDEX `idx_tf_loadouts_player_loadout_slot_class` (`steam64_id` ASC, `loadout_id` ASC, `loadout_slot` ASC, `class` ASC),
    INDEX `idx_tf_loadouts_steam64_id` (`steam64_id` ASC),
    INDEX `idx_tf_loadouts_loadout_id` (`loadout_id` ASC),
    INDEX `idx_tf_loadouts_loadout_slot` (`loadout_slot` ASC),
    INDEX `idx_tf_loadouts_class` (`class` ASC),
    INDEX `idx_tf_loadouts_item_id` (`item_id` ASC),
    INDEX `idx_tf_loadouts_quality` (`quality` ASC),
    INDEX `idx_tf_loadouts_level` (`level` ASC),
    INDEX `idx_tf_loadouts_unusual_id` (`unusual_id` ASC),
    INDEX `idx_tf_loadouts_paintkit_id` (`paintkit_id` ASC),
    INDEX `idx_tf_loadouts_warpaint_id` (`warpaint_id` ASC),
    CONSTRAINT `FK_tfl_players`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`),
    CONSTRAINT `FK_tfl_ql`
    FOREIGN KEY (`steam64_id`, `loadout_id`)
    REFERENCES `quasar`.`quasar_loadouts` (`steam64_id`, `loadout_id`),
    CONSTRAINT `FK_tfl_classes`
    FOREIGN KEY (`class`)
    REFERENCES `quasar`.`tf_classes` (`id`),
    CONSTRAINT `FK_tfl_tf_items`
    FOREIGN KEY (`item_id`)
    REFERENCES `quasar`.`tf_items` (`id`),
    CONSTRAINT `FK_tfl_qualities`
    FOREIGN KEY (`quality`)
    REFERENCES `quasar`.`tf_qualities` (`id`),
    CONSTRAINT `FK_tfl_particles`
    FOREIGN KEY (`unusual_id`)
    REFERENCES `quasar`.`tf_particles` (`id`),
    CONSTRAINT `FK_tfl_paint_kits`
    FOREIGN KEY (`paintkit_id`)
    REFERENCES `quasar`.`tf_paint_kits` (`id`),
    CONSTRAINT `FK_tfl_war_paints`
    FOREIGN KEY (`warpaint_id`)
    REFERENCES `quasar`.`tf_war_paints` (`id`)
);
