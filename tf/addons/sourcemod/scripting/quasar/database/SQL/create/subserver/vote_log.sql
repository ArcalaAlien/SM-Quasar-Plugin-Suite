--?21
DROP TABLE IF EXISTS `quasar`.`%s_vote_log`;
CREATE TABLE IF NOT EXISTS `quasar`.`%s_vote_log` (
    `id`                INT NOT NULL AUTO_INCREMENT,
    `vote_type`         INT NOT NULL DEFAULT 0,
    `voter_steam_id`    VARCHAR(64) NULL DEFAULT NULL,
    `target_steam_id`   VARCHAR(64) NULL DEFAULT NULL,
    `voter_name`        VARCHAR(128) NULL DEFAULT NULL,
    `target_name`       VARCHAR(128) NULL DEFAULT NULL,
    `date`              INT NOT NULL DEFAULT -1,
    PRIMARY KEY (
        `id`,
        `voter_steam_id`),
    INDEX `FK_vote_log_players_idx` (`voter_steam_id` ASC) VISIBLE,
    INDEX `FK_vote_log_players2_idx` (`target_steam_id` ASC) VISIBLE,
    CONSTRAINT `FK_vote_log_players`
        FOREIGN KEY (`voter_steam_id`)
        REFERENCES `quasar`.`players` (`steam64_id`),
    CONSTRAINT `FK_vote_log_players2`
        FOREIGN KEY (`target_steam_id`)
        REFERENCES `quasar`.`players` (`steam64_id`));
