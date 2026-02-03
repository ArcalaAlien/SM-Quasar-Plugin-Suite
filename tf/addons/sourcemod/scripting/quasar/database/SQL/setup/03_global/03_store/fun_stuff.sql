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
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_fun_stuff_id` (`id` ASC),
    UNIQUE INDEX `idx_fun_stuff_name` (`name` ASC),
    UNIQUE INDEX `idx_fun_stuff_item_id` (`item_id` ASC),
    UNIQUE INDEX `idx_fun_stuff_description` (`description` ASC),
    UNIQUE INDEX `idx_fun_stuff_function_name` (`function_name` ASC),
    INDEX `idx_fun_stuff_price` (`price` ASC),
    INDEX `idx_fun_stuff_plugin_name` (`plugin_name` ASC),
    INDEX `idx_fun_stuff_creator_id` (`creator_id` ASC)
);
