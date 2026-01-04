-- ?5
CREATE TABLE IF NOT EXISTS `quasar`.`tf_particles` (
    `id` INT NOT NULL DEFAULT -1,
    `name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `type` VARCHAR(16) NOT NULL DEFAULT 'WEAPON',
    `system_name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (
        `id`,
        `name`
    ),
    UNIQUE INDEX `idx_tf_particle_id`   (`id` ASC),
    INDEX `idx_tf_particle_name` (`name` ASC)
);
