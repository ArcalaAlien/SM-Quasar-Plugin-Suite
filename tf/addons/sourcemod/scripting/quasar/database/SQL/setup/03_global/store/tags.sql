-- ?14
CREATE TABLE IF NOT EXISTS `quasar`.`tags` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `item_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `display` VARCHAR(64) NOT NULL DEFAULT '{pink}[IN{black}VAL{PINK}ID]',
    `price` INT NOT NULL DEFAULT 0,
    `creator_id` VARCHAR(64) NOT NULL DEFAULT 'QUASAR',
    PRIMARY KEY (
        `id`,
        `item_id`,
        `name`,
        `display`
    ),
    UNIQUE INDEX `idx_tag_id`   (`id` ASC),
    INDEX `idx_tag_name` (`name` ASC),
    INDEX `idx_tag_item_id` (`item_id` ASC),
    INDEX `idx_tag_display` (`display` ASC)
);
