-- ?8
CREATE TABLE IF NOT EXISTS `quasar`.`players` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `steam2_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `steam3_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `player_name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `nickname` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `can_vote` INT NOT NULL DEFAULT 1,
    `num_loadouts` INT NOT NULL DEFAULT 1,
    `equipped_loadout` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `id`,
        `steam2_id`,
        `steam3_id`,
        `steam64_id`
    ),
    UNIQUE INDEX `idx_players_id` (`id` ASC),
    INDEX `idx_players_steam2_id` (`steam2_id` ASC),
    INDEX `idx_players_steam3_id` (`steam3_id` ASC), 
    INDEX `idx_players_steam64_id` (`steam64_id` ASC)
);
