--?6
DROP TABLE IF EXISTS `quasar`.`tf_paint_kits`;
CREATE TABLE IF NOT EXISTS `quasar`.`tf_paint_kits` (
    `id`        INT NOT NULL DEFAULT -1,
    `name`      VARCHAR(128) NULL DEFAULT NULL,
    `red_color` INT NOT NULL DEFAULT 0,
    `blu_color` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `id`
    ));
