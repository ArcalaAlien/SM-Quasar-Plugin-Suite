-- ?18
CREATE TABLE IF NOT EXISTS `quasar`.`color_pack_names` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (
        `id`,
        `name`
    ),
    UNIQUE INDEX `idx_color_pack_name_id`   (`id` ASC),
    INDEX `idx_color_pack_name_name` (`name` ASC)
);
