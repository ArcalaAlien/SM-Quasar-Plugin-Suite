-- ?22
CREATE TABLE IF NOT EXISTS `quasar`.`PLREPLACE_chat_log` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `message` VARCHAR(256) NULL DEFAULT 'NONE',
    `date` INT NOT NULL DEFAULT -1,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_PLREPLACE_chat_log_id` (`id` ASC),
    UNIQUE INDEX `idx_PLREPLACE_chat_log_steam64_id` (`steam64_id` ASC),
    UNIQUE INDEX `idx_PLREPLACE_chat_log_date` (`date` ASC),
    INDEX `idx_PLREPLACE_chat_log_message` (`message` ASC),
    CONSTRAINT `FK_PLREPLACE_chat_log_players`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`)
);
