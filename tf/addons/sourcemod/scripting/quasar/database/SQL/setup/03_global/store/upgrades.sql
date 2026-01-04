-- ?15
CREATE TABLE IF NOT EXISTS `quasar`.`upgrades` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `item_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `description` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `price` INT NOT NULL DEFAULT 0,
    `creator_id` VARCHAR(64) NOT NULL DEFAULT 'QUASAR',
    PRIMARY KEY (
        `id`,
        `item_id`,
        `name`,
        `description`
    ),
    UNIQUE INDEX `idx_upgrade_id`   (`id` ASC),
    INDEX `idx_upgrade_name` (`name` ASC),
    INDEX `idx_upgrade_item_id` (`item_id` ASC),
    INDEX `idx_upgrade_description` (`description` ASC)
);
