-- ?18
CREATE TABLE IF NOT EXISTS `quasar`.`color_packs` (
    `id` INT NOT NULL DEFAULT 0,
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `creator_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `price` INT NOT NULL DEFAULT 2500,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_color_pack_id` (`id` ASC),
    UNIQUE INDEX `idx_color_pack_name` (`name` ASC),
    INDEX `idx_color_pack_price` (`price` ASC),
    INDEX `idx_color_pack_creator_id` (`creator_id` ASC)
);
