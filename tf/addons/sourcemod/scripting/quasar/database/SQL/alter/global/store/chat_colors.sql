--?17
DROP TABLE IF EXISTS `quasar`.`chat_colors`;
CREATE TABLE IF NOT EXISTS `quasar`.`chat_colors` (
    `id`          INT NOT NULL AUTO_INCREMENT,
    `format`      VARCHAR(64) NULL DEFAULT NULL,
    `name`        VARCHAR(64) NULL DEFAULT NULL,
    `price`       INT NOT NULL DEFAULT `100`,
    `category`    VARCHAR(16) NULL DEFAULT NULL,
    PRIMARY KEY (
        `id`,
        `format`,
        `name`
    ));
