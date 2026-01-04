-- ?16
CREATE TABLE IF NOT EXISTS `quasar`.`fun_stuff` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `item_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `description` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `price` INT NOT NULL DEFAULT 0,
    `function_name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `plugin_name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `creator_id` VARCHAR(64) NOT NULL DEFAULT 'QUASAR',
    PRIMARY KEY (
        `id`,
        `item_id`,
        `name`
    ),
    UNIQUE INDEX `idx_fun_stuff_id`   (`id` ASC),
    INDEX `idx_fun_stuff_name` (`name` ASC),
    INDEX `idx_fun_stuff_item_id` (`item_id` ASC)
);
