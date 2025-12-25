--?5
DROP TABLE IF EXISTS `quasar`.`tf_particles`;
CREATE TABLE IF NOT EXISTS `quasar`.`tf_particles` (
    `id`            INT NOT NULL DEFAULT -1,
    `name`          VARCHAR(128) NULL DEFAULT NULL
    `type`          VARCHAR(16)  NOT NULL DEFAULT `WEAPON`
    `system_name`   VARCHAR(128) NULL DEFAULT NULL,
    PRIMARY KEY (
        `id`
    ));
