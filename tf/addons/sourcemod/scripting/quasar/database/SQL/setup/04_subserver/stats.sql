-- ?19
CREATE TABLE IF NOT EXISTS `quasar`.`PLREPLACE_stats` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `points` DECIMAL NOT NULL DEFAULT 0.0,
    `kills` INT UNSIGNED NOT NULL DEFAULT 0,
    `afk_points` DECIMAL NOT NULL DEFAULT 0.0,
    `afk_kills` INT UNSIGNED NOT NULL DEFAULT 0,
    `first_login` INT NOT NULL DEFAULT -1,
    `last_login` INT NOT NULL DEFAULT -1,
    `playtime` INT NOT NULL DEFAULT 0,
    `time_afk` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_PLREPLACE_stats_id` (`id` ASC),
    UNIQUE INDEX `idx_PLREPLACE_stats_steam64_id` (`steam64_id` ASC),
    INDEX `idx_PLREPLACE_stats_points` (`points` ASC),
    INDEX `idx_PLREPLACE_stats_kills` (`kills` ASC),
    INDEX `idx_PLREPLACE_stats_afk_points` (`afk_points` ASC),
    INDEX `idx_PLREPLACE_stats_afk_kills` (`afk_kills` ASC),
    INDEX `idx_PLREPLACE_stats_first_login` (`first_login` ASC),
    INDEX `idx_PLREPLACE_stats_last_login` (`last_login` ASC),
    INDEX `idx_PLREPLACE_stats_playtime` (`playtime` ASC),
    INDEX `idx_PLREPLACE_stats_time_afk` (`time_afk` ASC),
    CONSTRAINT `FK_players_PLREPLACE_stats`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`)
);
