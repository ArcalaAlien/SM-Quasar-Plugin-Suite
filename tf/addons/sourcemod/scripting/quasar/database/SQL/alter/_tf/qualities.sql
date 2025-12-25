--?4
DROP TABLE IF EXISTS `quasar`.`tf_qualities`;
CREATE TABLE IF NOT EXISTS `quasar`.`tf_qualities` (
    `id`    INT NOT NULL
    `name`  VARCHAR(64) NULL DEFAULT NULL
    PRIMARY KEY (
        `id`
    ));
