--?15
DROP TABLE IF EXISTS `quasar`.`upgrades`;
CREATE TABLE IF NOT EXISTS `quasar`.`upgrades` (
    `id`                INT NOT NULL AUTO_INCREMENT,
    `item_id`       VARCHAR(64)  NULL DEFAULT NULL,
    `name`          VARCHAR(64)  NULL DEFAULT NULL,
    `description    VARCHAR(128) NULL DEFAULT NULL
    `price`         INT          NOT NULL DEFAULT 0,
    `creator_id`    VARCHAR(64)  NOT NULL DEFAULT `QUASAR`,
    PRIMARY KEY (
        `id`,
        `item_id`,
        `name`,
        `function_name`,
    ));
