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
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_players_id` (`id` ASC),
    UNIQUE INDEX `idx_players_steam2_id` (`steam2_id` ASC),
    UNIQUE INDEX `idx_players_steam3_id` (`steam3_id` ASC),
    UNIQUE INDEX `idx_players_steam64_id` (`steam64_id` ASC),
    UNIQUE INDEX `idx_players_player_name` (`player_name` ASC),
    INDEX `idx_players_nickname` (`nickname` ASC),
    INDEX `idx_players_can_vote` (`can_vote` ASC),
    INDEX `idx_players_num_loadouts` (`num_loadouts` ASC),
    INDEX `idx_players_equipped_loadout` (`equipped_loadout` ASC)
);
