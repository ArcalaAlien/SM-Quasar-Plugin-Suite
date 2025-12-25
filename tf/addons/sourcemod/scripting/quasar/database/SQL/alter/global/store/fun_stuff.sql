--?16
DROP TABLE IF EXISTS `quasar`.`fun_stuff`;
CREATE TABLE IF NOT EXISTS `quasar`.`fun_stuff` (
    `id`                INT NOT NULL AUTO_INCREMENT,
    `item_id`       VARCHAR(64)  NULL DEFAULT NULL,
    `name`          VARCHAR(64)  NULL DEFAULT NULL,
    `description    VARCHAR(128) NULL DEFAULT NULL
    `price`         INT          NOT NULL DEFAULT 0,
    `function_name` VARCHAR(128) NULL DEFAULT NULL,
    `plugin_name`   VARCHAR(128) NULL DEFAULT NULL,
    `creator_id`    VARCHAR(64)  NOT NULL DEFAULT `QUASAR`,
    PRIMARY KEY (
        `id`,
        `item_id`,
        `name`,
        `function_name`,
    ));
