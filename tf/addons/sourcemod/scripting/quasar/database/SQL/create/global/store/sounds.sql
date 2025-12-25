--?12
DROP TABLE IF EXISTS `quasar`.`sounds`;
CREATE TABLE IF NOT EXISTS `quasar`.`sounds` (
    `id`                INT NOT NULL AUTO_INCREMENT,
    `item_id`           VARCHAR(64) NULL DEFAULT NULL,
    `name`              VARCHAR(64) NULL DEFAULT NULL,
    `filepath`          VARCHAR(256) NULL DEFAULT NULL,
    `cooldown`          DECIMAL NOT NULL DEFAULT 0.1,
    `price`             INT NOT NULL DEFAULT 0,
    `activation_phrase` VARCHAR(32) NULL DEFAULT NULL,
    `creator_id`        VARCHAR(64) NOT NULL DEFAULT `QUASAR`
    PRIMARY KEY (
        `id`,
        `item_id`,
        `name`,
        `filepath`,
        `activation_phrase`,
    ));
