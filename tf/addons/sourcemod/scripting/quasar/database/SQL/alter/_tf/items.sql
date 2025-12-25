--?2
DROP TABLE IF EXISTS `quasar`.`tf_items`;
CREATE TABLE IF NOT EXISTS `quasar`.`tf_items` (
    `id`        INT NOT NULL DEFAULT -1,
    `name`      VARCHAR(128) NULL DEFAULT NULL,
    `classname` VARCHAR(128) NULL DEFAULT NULL,
    `min_level` INT NOT NULL DEFAULT 0,
    `max_level` INT NOT NULL DEFAULT 99,
    `slot_name` VARCHAR(16) NULL DEFAULT NULL,
    PRIMARY KEY (
        `id`
    ));
