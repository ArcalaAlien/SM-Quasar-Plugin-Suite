--?8
DROP TABLE IF EXISTS `quasar`.`players`;
CREATE TABLE IF NOT EXISTS `quasar`.`players` (
    `id`                INT NOT NULL AUTO_INCREMENT,
    `steam2_id`         VARCHAR(64)     NULL DEFAULT NULL,
    `steam3_id`         VARCHAR(64)     NULL DEFAULT NULL,
    `steam64_id`        VARCHAR(64)     NULL DEFAULT NULL,
    `name`              VARCHAR(128)    NULL DEFAULT NULL,
    `nickname`          VARCHAR(128)    NULL DEFAULT NULL,
    `can_vote`          INT             NOT NULL DEFAULT 1,
    `num_loadouts`      INT             NOT NULL DEFAULT 1,
    `equipped_loadout`  INT             NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `id`,
        `steam2_id`,
        `steam3_id`,
        `steam64_id`));
