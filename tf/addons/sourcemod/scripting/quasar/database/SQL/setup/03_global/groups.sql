-- ?11
CREATE TABLE IF NOT EXISTS `quasar`.`groups` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (
        `id`,
        `name`
    ),
    UNIQUE INDEX `idx_group_id`   (`id` ASC),
    INDEX `idx_group_name` (`name` ASC)
);
