--?13
DROP TABLE IF EXISTS `quasar`.`trails`;
CREATE TABLE IF NOT EXISTS `quasar`.`trails` (
    `item_id`       VARCHAR(64)  NULL DEFAULT NULL,
    `id`                INT NOT NULL AUTO_INCREMENT,
    `name`          VARCHAR(64)  NULL DEFAULT NULL,
    `vtf_filepath`  VARCHAR(256) NULL DEFAULT NULL,
    `vmt_filepath`  VARCHAR(256) NULL DEFAULT NULL,
    `price`         INT          NOT NULL DEFAULT 0,
    `creator_id`    VARCHAR(64)  NOT NULL DEFAULT `QUASAR`,
    PRIMARY KEY (
        `id`,
        `item_id`,
        `name`,
        `vtf_filepath`,
        `vmt_filepath`
    ));
