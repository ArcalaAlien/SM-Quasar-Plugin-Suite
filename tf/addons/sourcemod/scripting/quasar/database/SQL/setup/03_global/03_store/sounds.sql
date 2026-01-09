-- ?12
CREATE TABLE IF NOT EXISTS `quasar`.`sounds` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `item_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `filepath` VARCHAR(256) NOT NULL DEFAULT 'UNKNOWN',
    `cooldown` DECIMAL NOT NULL DEFAULT 0.1,
    `price` INT NOT NULL DEFAULT 0,
    `activation_phrase` VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN',
    `creator_id` VARCHAR(64) NOT NULL DEFAULT 'QUASAR',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_sound_id` (`id` ASC),
    UNIQUE INDEX `idx_sound_name` (`name` ASC),
    UNIQUE INDEX `idx_sound_item_id` (`item_id` ASC),
    UNIQUE INDEX `idx_sound_activation_phrase` (`activation_phrase` ASC),
    UNIQUE INDEX `idx_sound_filepath` (`filepath` ASC),
    INDEX `idx_sound_cooldown` (`cooldown` ASC),
    INDEX `idx_sound_price` (`price` ASC),
    INDEX `idx_sound_creator_id` (`creator_id` ASC)
);
