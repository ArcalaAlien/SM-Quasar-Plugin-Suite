--?18
DROP TABLE IF EXISTS `quasar`.`color_pack_names`;
CREATE TABLE IF NOT EXISTS `quasar`.`color_pack_names` (
    `id`    INT NOT NULL AUTO_INCREMENT,
    `name`  VARCHAR(64) NULL DEFAULT NULL,
    PRIMARY KEY (
        `id`,
        `name`
    ));
