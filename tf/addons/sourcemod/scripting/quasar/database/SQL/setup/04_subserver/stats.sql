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
    PRIMARY KEY (
        `id`,
        `steam64_id`
    ),
    UNIQUE INDEX `idx_PLREPLACE_stats_id` (`id` ASC),
    INDEX `idx_PLREPLACE_stats_steam64_id` (`steam64_id` ASC),
    CONSTRAINT `FK_players_PLREPLACE_stats`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`)
);