-- ?27
CREATE TABLE IF NOT EXISTS `quasar`.`players_items` (
    `id`            INT NOT NULL AUTO_INCREMENT,
    `steam64_id`    VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `item_id`       VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (
        `id`,
        `steam64_id`,
        `item_id`
    ),
    UNIQUE INDEX `idx_players_items_id` (`id` ASC),
    INDEX `idx_players_items_steam64_id` (`steam64_id` ASC),
    INDEX `idx_players_items_item_id` (`item_id` ASC),
    CONSTRAINT `FK_pi_players`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`)
);
