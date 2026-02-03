-- ?10
CREATE TABLE IF NOT EXISTS `quasar`.`ignores` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `ignore_target_steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `ignoring_voice` INT NOT NULL DEFAULT 0,
    `ignoring_text` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_ignores_id` (`id` ASC),
    UNIQUE INDEX `idx_ignores_steam64_id` (`steam64_id` ASC),
    UNIQUE INDEX `idx_ignores_ignore_target_steam64_id` (`ignore_target_steam64_id` ASC),
    INDEX `idx_ignores_ignoring_voice` (`ignoring_voice` ASC),
    INDEX `idx_ignores_ignoring_text` (`ignoring_text` ASC),
    CONSTRAINT `FK_steam64_id`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`),
    CONSTRAINT `FK_ignore_target_steam64_id`
    FOREIGN KEY (`ignore_target_steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`)
);
