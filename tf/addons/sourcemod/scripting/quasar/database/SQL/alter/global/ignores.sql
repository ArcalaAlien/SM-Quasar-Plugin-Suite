--?10
DROP TABLE IF EXISTS `quasar`.`ignores`;
CREATE TABLE IF NOT EXISTS `quasar`.`ignores` (
    `id`                INT NOT NULL AUTO_INCREMENT,
    `steam64_id`        VARCHAR(64) NULL DEFAULT NULL,
    `ignore_target_id`  VARCHAR(64) NULL DEFAULT NULL,
    `ignoring_voice`    INT         NOT NULL DEFAULT 0,
    `ignoring_text`     INT         NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `id`,
        `steam64_id`,
        `ignore_target_id`
    ),
    CONSTRAINT `steam64_id`
        FOREIGN KEY (`steam64_id`)
        REFERENCES `quasar`.`ignores` (`steam64_id`));
