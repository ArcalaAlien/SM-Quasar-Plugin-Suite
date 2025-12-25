--?27
DROP TABLE IF EXISTS `quasar`.`players_items`;
CREATE TABLE IF NOT EXISTS `quasar`.`players_items` (
    `steam64_id`    VARCHAR(64) NULL DEFAULT NULL,
    `item_id`       VARCHAR(64) NULL DEFAULT NULL,
    PRIMARY KEY (
        `steam64_id`,
        `item_id`
    ),
    CONSTRAINT `FK_pi_players`
        FOREIGN KEY (`steam64_id`)
        REFERENCES `quasar`.`players` (`steam64_id`));
