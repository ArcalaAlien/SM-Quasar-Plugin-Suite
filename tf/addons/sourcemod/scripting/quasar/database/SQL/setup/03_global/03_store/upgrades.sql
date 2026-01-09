-- ?15
CREATE TABLE IF NOT EXISTS `quasar`.`upgrades` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `item_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `description` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `price` INT NOT NULL DEFAULT 0,
    `creator_id` VARCHAR(64) NOT NULL DEFAULT 'QUASAR',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_upgrade_id` (`id` ASC),
    UNIQUE INDEX `idx_upgrade_name` (`name` ASC),
    UNIQUE INDEX `idx_upgrade_item_id` (`item_id` ASC),
    UNIQUE INDEX `idx_upgrade_description` (`description` ASC),
    INDEX `idx_upgrade_price` (`price` ASC),
    INDEX `idx_upgrade_creator_id` (`creator_id` ASC)
);
