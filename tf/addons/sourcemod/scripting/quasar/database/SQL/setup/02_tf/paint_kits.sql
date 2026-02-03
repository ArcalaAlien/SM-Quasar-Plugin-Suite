-- ?6
CREATE TABLE IF NOT EXISTS `quasar`.`tf_paint_kits` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `paint_kit_id` INT NOT NULL DEFAULT -1,
    `name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `red_color` INT NOT NULL DEFAULT 0,
    `blu_color` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id` ),
    UNIQUE INDEX `tf_paint_kits_id`             (`id` ASC),
    UNIQUE INDEX `tf_paint_kits_paint_kit_id`   (`paint_kit_id` ASC),
    UNIQUE INDEX `tf_paint_kits_name`           (`name` ASC),
    UNIQUE INDEX `tf_paint_kits_red_color`      (`red_color` ASC),
    UNIQUE INDEX `tf_paint_kits_blu_color`      (`blu_color` ASC)
);
