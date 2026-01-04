-- ?2
CREATE TABLE IF NOT EXISTS `quasar`.`tf_items` (
    `id` INT NOT NULL DEFAULT -1,
    `name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `classname` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `min_level` INT NOT NULL DEFAULT 0,
    `max_level` INT NOT NULL DEFAULT 99,
    `slot_name` VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (
        `id`,
        `name`
    ),
    UNIQUE INDEX `idx_tf_item_id`   (`id` ASC),
    INDEX `idx_tf_item_name` (`name` ASC)
);
