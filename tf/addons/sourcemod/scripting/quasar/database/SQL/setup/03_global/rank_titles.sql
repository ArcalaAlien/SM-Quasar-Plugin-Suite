-- ?9
CREATE TABLE IF NOT EXISTS `quasar`.`rank_titles` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `rank_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `display` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `point_target` DECIMAL(10) NOT NULL DEFAULT 0.0,
    `afk_rank` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_rank_title_id` (`id` ASC),
    UNIQUE INDEX `idx_rank_title_rank_id` (`rank_id` ASC),
    UNIQUE INDEX `idx_rank_title_name` (`name` ASC),
    UNIQUE INDEX `idx_rank_title_display` (`display` ASC),
    INDEX `idx_rank_title_point_target` (`point_target` ASC),
    INDEX `idx_rank_title_afk_rank` (`afk_rank` ASC)
);
