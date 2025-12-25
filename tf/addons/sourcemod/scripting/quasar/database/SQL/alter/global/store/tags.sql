--?14
DROP TABLE IF EXISTS `quasar`.`tags`;
CREATE TABLE IF NOT EXISTS `quasar`.`tags` (
    `id`                INT NOT NULL AUTO_INCREMENT,
    `item_id`       VARCHAR(64) NULL DEFAULT NULL,
    `name`          VARCHAR(64) NULL DEFAULT NULL,
    `display`       VARCHAR(64) NOT NULL DEFAULT `{pink}[IN{black}VAL{PINK}ID]`,
    `price`         INT         NOT NULL DEFAULT 0,
    `creator_id`    VARCHAR(64) NOT NULL DEFAULT `QUASAR`,
    PRIMARY KEY (
        `id`,
        `item_id`,
        `name`,
        `display`,
    ));
