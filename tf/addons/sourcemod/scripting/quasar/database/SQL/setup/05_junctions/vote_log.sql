-- ?21
CREATE TABLE IF NOT EXISTS `quasar`.`PLREPLACE_vote_log` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `vote_type` INT NOT NULL DEFAULT 0,
    `voter_steam_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `target_steam_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `voter_name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `target_name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `date` INT NOT NULL DEFAULT -1,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_PLREPLACE_vote_log_id` (`id` ASC),
    UNIQUE INDEX `idx_PLREPLACE_vote_log_date` (`date` ASC),
    INDEX `idx_PLREPLACE_vote_log_vote_type` (`vote_type` ASC),
    INDEX `idx_PLREPLACE_vote_log_voter_steam_id` (`voter_steam_id` ASC),
    INDEX `idx_PLREPLACE_vote_log_target_steam_id` (`target_steam_id` ASC),
    INDEX `idx_PLREPLACE_vote_log_voter_name` (`voter_name` ASC),
    INDEX `idx_PLREPLACE_vote_log_target_name` (`target_name` ASC),
    CONSTRAINT `FK_vote_log_players`
    FOREIGN KEY (`voter_steam_id`)
    REFERENCES `quasar`.`players` (`steam64_id`),
    CONSTRAINT `FK_vote_log_players2`
    FOREIGN KEY (`target_steam_id`)
    REFERENCES `quasar`.`players` (`steam64_id`)
);
