--?31
DROP TABLE IF EXISTS `quasar`.`%s_maps_feedback`
CREATE TABLE IF NOT EXISTS `quasar`.`%s_maps_feedback` (
    `id`            VARCHAR(64)     NOT NULL AUTO_INCREMENT,
    `map_name`      VARCHAR(128)    NOT NULL DEFAULT `NONE`,
    `steam64_id`    VARCHAR(64)     NULL DEFAULT NULL,
    `pos_x`         DECIMAL         NOT NULL DEFAULT 0.0,
    `pos_y`         DECIMAL         NOT NULL DEFAULT 0.0,
    `pos_z`         DECIMAL         NOT NULL DEFAULT 0.0,
    `ang_x`         DECIMAL         NOT NULL DEFAULT 0.0,
    `ang_y`         DECIMAL         NOT NULL DEFAULT 0.0,
    `ang_z`         DECIMAL         NOT NULL DEFAULT 0.0,
    `feedback`      VARCHAR(128)    NOT NULL DEFAULT ``,
    PRIMARY KEY (
        `id`,
        `map`,
        `steam64_id`
    ),
    UNIQUE INDEX `id_UNIQUE` (`id` ASC) VISIBLE
    CONSTRAINT `FK_%s_maps_feedback`
        FOREIGN KEY (`map_name`)
        REFERENCES `quasar`.`%s_maps` (`name`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT `FK_%s_maps_feedback_players`
        FOREIGN KEY (`steam64_id`)
        REFERENCES `quasar`.`players` (`steam64_id`));
