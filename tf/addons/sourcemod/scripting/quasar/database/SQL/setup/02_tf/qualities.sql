-- ?4
CREATE TABLE IF NOT EXISTS `quasar`.`tf_qualities` (
    `id` INT NOT NULL,
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (
        `id`,
        `name`
    ),
    UNIQUE INDEX `idx_tf_quality_id`   (`id` ASC),
    INDEX `idx_tf_quality_name` (`name` ASC)
);
