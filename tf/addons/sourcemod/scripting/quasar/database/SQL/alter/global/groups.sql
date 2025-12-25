--?11
DROP TABLE IF EXISTS `quasar`.`groups`;
CREATE TABLE IF NOT EXISTS `quasar`.`groups` (
    `id`    INT         NOT NULL AUTO_INCREMENT,
    `name`  VARCHAR(64) NULL
    PRIMARY KEY (`id`));
