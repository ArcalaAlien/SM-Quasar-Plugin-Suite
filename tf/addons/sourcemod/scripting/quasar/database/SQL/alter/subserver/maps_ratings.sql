--?32
DROP TABLE IF EXISTS `quasar`.`%s_maps_ratings`;
CREATE TABLE IF NOT EXISTS `quasar`.`%s_maps_ratings` (
    `map_name`      VARCHAR(128) NULL DEFAULT NULL,
    `steam64_id`    VARCHAR(64)  NULL DEFAULT NULL,
    `rating`        INT          NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `map_name`,
        `steam64_id`,
        `rating`
    ),
    CONTRAINT `FK_%s_maps_ratings`
        FOREIGN KEY (`map_name`)
        REFERENCES `quasar`.`%s_maps` (`name`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT `FK_%s_players_ratings`
        FOREIGN KEY (`steam64_id`)
        REFERENCES `quasar`.`players` (`steam64_id`));
