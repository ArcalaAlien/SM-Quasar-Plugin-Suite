-- ?31
CREATE TABLE IF NOT EXISTS `quasar`.`PLREPLACE_maps_feedback` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `map_name` VARCHAR(128) NOT NULL DEFAULT 'NONE',
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'NONE',
    `pos_x` DECIMAL NOT NULL DEFAULT 0.0,
    `pos_y` DECIMAL NOT NULL DEFAULT 0.0,
    `pos_z` DECIMAL NOT NULL DEFAULT 0.0,
    `ang_x` DECIMAL NOT NULL DEFAULT 0.0,
    `ang_y` DECIMAL NOT NULL DEFAULT 0.0,
    `ang_z` DECIMAL NOT NULL DEFAULT 0.0,
    `feedback` VARCHAR(128) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_PLREPLACE_maps_feedback_id` (`id` ASC),
    UNIQUE INDEX `idx_PLREPLACE_maps_feedback_map_name` (`map_name` ASC),
    UNIQUE INDEX `idx_PLREPLACE_maps_feedback_steam64_id` (`steam64_id` ASC),
    INDEX `idx_PLREPLACE_maps_feedback_feedback` (`feedback` ASC),
    INDEX `idx_PLREPLACE_maps_feedback_pos_x` (`pos_x` ASC),
    INDEX `idx_PLREPLACE_maps_feedback_pos_y` (`pos_y` ASC),
    INDEX `idx_PLREPLACE_maps_feedback_pos_z` (`pos_z` ASC),
    INDEX `idx_PLREPLACE_maps_feedback_ang_x` (`ang_x` ASC),
    INDEX `idx_PLREPLACE_maps_feedback_ang_y` (`ang_y` ASC),
    INDEX `idx_PLREPLACE_maps_feedback_ang_z` (`ang_z` ASC),
    CONSTRAINT `FK_PLREPLACE_maps_feedback`
    FOREIGN KEY (`map_name`)
    REFERENCES `quasar`.`PLREPLACE_maps` (`name`),
    CONSTRAINT `FK_PLREPLACE_maps_feedback_players`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`)
);
