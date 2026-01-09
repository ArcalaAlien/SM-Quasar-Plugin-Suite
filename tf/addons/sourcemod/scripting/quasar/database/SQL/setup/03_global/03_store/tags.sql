-- ?14
CREATE TABLE IF NOT EXISTS `quasar`.`tags` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `item_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `display` VARCHAR(64) NOT NULL DEFAULT '{pink}[IN{black}VAL{PINK}ID]',
    `price` INT NOT NULL DEFAULT 0,
    `creator_id` VARCHAR(64) NOT NULL DEFAULT 'QUASAR',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_tags_id` (`id` ASC),
    UNIQUE INDEX `idx_tags_item_id` (`item_id` ASC),
    UNIQUE INDEX `idx_tags_name` (`name` ASC),
    UNIQUE INDEX `idx_tags_display` (`display` ASC),
    INDEX `idx_tags_price` (`price` ASC),
    INDEX `idx_tags_creator_id` (`creator_id` ASC)
);
