-- ?25
CREATE TABLE IF NOT EXISTS `quasar`.`players_groups` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `group_id` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `id`,
        `steam64_id`,
        `group_id`
    ),
    UNIQUE INDEX `idx_players_groups_id` (`id` ASC),
    INDEX `idx_players_groups_steam64_id` (`steam64_id` ASC),
    INDEX `idx_players_groups_group_id` (`group_id` ASC),
    CONSTRAINT `FK_storeplayersgroups_players`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`),
    CONSTRAINT `FK_storeplayersgroups_groups`
    FOREIGN KEY (`group_id`)
    REFERENCES `quasar`.`groups` (`id`)
);
