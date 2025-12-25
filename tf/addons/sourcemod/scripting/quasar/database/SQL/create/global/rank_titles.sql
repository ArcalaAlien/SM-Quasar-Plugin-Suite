--?9
DROP TABLE IF EXISTS `quasar`.`rank_titles`;
CREATE TABLE IF NOT EXISTS `quasar`.`rank_titles` (
    `id`            INT NOT NULL AUTO_INCREMENT,
    `rank_id`       VARCHAR(128) NULL DEFAULT NULL,
    `name`          VARCHAR(128) NULL DEFAULT NULL,
    `display`       VARCHAR(128) NULL DEFAULT NULL,
    `point_target`  DECIMAL(10)  NULL DEFAULT NULL,
    PRIMARY KEY (
        `id`,
        `name`,
        `display`,
        `point_target`
    ));
