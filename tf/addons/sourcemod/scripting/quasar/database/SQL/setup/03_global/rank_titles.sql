-- ?9
CREATE TABLE IF NOT EXISTS `quasar`.`rank_titles` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `rank_id` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `display` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `point_target` DECIMAL(10) NOT NULL DEFAULT 0.0,
    PRIMARY KEY (
        `id`,
        `name`,
        `display`,
        `point_target`
    ),
    UNIQUE INDEX `idx_rank_title_id` (`id` ASC),
    INDEX `idx_rank_title_name` (`name` ASC),
    INDEX `idx_rank_title_display` (`display` ASC),
    INDEX `idx_rank_title_point_target` (`point_target` ASC)
);
