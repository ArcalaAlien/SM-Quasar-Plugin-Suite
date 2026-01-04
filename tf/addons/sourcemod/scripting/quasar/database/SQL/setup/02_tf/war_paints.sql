-- ?7
CREATE TABLE IF NOT EXISTS `quasar`.`tf_war_paints` (
    `id` INT NOT NULL DEFAULT -1,
    `name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (
        `id`,
        `name`
    ),
    UNIQUE INDEX `idx_tf_war_paint_id`   (`id` ASC),
    INDEX `idx_tf_war_paint_name` (`name` ASC)
);
