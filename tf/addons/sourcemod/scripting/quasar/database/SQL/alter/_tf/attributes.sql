--?3
DROP TABLE IF EXISTS `quasar`.`tf_attributes`;
CREATE TABLE IF NOT EXISTS `quasar`.`tf_attributes` (
    `id`            INT NOT NULL DEFAULT -1,
    `name`          VARCHAR(128) NULL DEFAULT NULL,
    `classname`     VARCHAR(128) NULL DEFAULT NULL,
    `description`   VARCHAR(128) NULL DEFAULT NULL,
    PRIMARY KEY (
        `id`
    ));
