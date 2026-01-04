-- ?6
CREATE TABLE IF NOT EXISTS `quasar`.`tf_paint_kits` (
    `id` INT NOT NULL DEFAULT -1,
    `name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `red_color` INT NOT NULL DEFAULT 0,
    `blu_color` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `id`,
        `name`,
        `red_color`,
        `blu_color`
    ),
    UNIQUE INDEX `id` (`id` ASC),
    INDEX `name` (`name` ASC),
    INDEX `red_color` (`red_color` ASC),
    INDEX `blu_color` (`blu_color` ASC)
);
