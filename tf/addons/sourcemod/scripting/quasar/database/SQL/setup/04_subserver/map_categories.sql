-- ?35
CREATE TABLE IF NOT EXISTS `quasar`.`PLREPLACE_map_categories` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `map_prefix` VARCHAR(64) NOT NULL DEFAULT 'ctf_',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_PLREPLACE_map_categories_id` (`id` ASC),
    INDEX `idx_PLREPLACE_map_categories_name` (`name` ASC),
    INDEX `idx_PLREPLACE_map_categories_map_prefix` (`map_prefix` ASC)
);