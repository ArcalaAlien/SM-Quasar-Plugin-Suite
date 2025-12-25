--?22
DROP TABLE IF EXISTS `quasar`.`%s_chat_log`;
CREATE TABLE IF NOT EXISTS `quasar`.`%s_chat_log` (
    `id`            INT NOT NULL AUTO_INCREMENT,
    `steam64_id`    VARCHAR(64) NULL DEFAULT NULL,
    `message`       VARCHAR(256) NULL DEFAULT `NONE`,
    `date`          INT NOT NULL -1,
    PRIMARY KEY (
        `id`,
        `steam64_id`
    ),
    CONSTRAINT `FK_%s_chat_log_players`
        FOREIGN KEY (`steam64_id`)
        REFERENCES `quasar`.`players` (`steam64_id`);
