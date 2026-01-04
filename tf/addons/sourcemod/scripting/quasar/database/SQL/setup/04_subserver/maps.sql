-- ?20
CREATE TABLE IF NOT EXISTS `quasar`.`PLREPLACE_maps` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `category` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `author` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `workshop_id` VARCHAR(128) NOT NULL DEFAULT 'LOCAL',
    PRIMARY KEY (
        `id`,
        `name`,
        `workshop_id`
    ),
    UNIQUE INDEX `idx_PLREPLACE_map_id` (`id` ASC),
    INDEX `idx_PLREPLACE_map_name` (`name` ASC),
    INDEX `idx_PLREPLACE_map_workshop_id` (`workshop_id` ASC)
);