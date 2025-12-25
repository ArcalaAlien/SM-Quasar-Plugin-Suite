--?20
DROP TABLE IF EXISTS `quasar`.`%s_maps`;
CREATE TABLE IF NOT EXISTS `quasar`.`%s_maps`(
    `id`            INT             NOT NULL AUTO_INCREMENT,
    `name`          VARCHAR(128)    NULL DEFAULT NULL
    `category`      VARCHAR(64)     NOT NULL DEFAULT `NONE`,
    `author`        VARCHAR(128)    NULL DEFAULT NULL
    `workshop_id`   VARCHAR(128)    NULL DEFAULT NULL
    PRIMARY KEY (
        `id`,
        `name`
    ));
