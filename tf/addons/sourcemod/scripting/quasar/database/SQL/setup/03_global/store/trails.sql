-- ?13
CREATE TABLE IF NOT EXISTS `quasar`.`trails` (
    `item_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `vtf_filepath` VARCHAR(256) NOT NULL DEFAULT 'UNKNOWN',
    `vmt_filepath` VARCHAR(256) NOT NULL DEFAULT 'UNKNOWN',
    `price` INT NOT NULL DEFAULT 0,
    `creator_id` VARCHAR(64) NOT NULL DEFAULT 'QUASAR',
    PRIMARY KEY (
        `id`,
        `item_id`,
        `name`,
        `vtf_filepath`,
        `vmt_filepath`
    ),
    UNIQUE INDEX `idx_trail_id`   (`id` ASC),
    INDEX `idx_trail_name` (`name` ASC),
    INDEX `idx_trail_item_id` (`item_id` ASC),
    INDEX `idx_trail_vtf_filepath` (`vtf_filepath` ASC),
    INDEX `idx_trail_vmt_filepath` (`vmt_filepath` ASC)
);
