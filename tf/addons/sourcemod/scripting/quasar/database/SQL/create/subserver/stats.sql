--?19
DROP TABLE IF EXISTS `quasar`.`%s_stats`;
CREATE TABLE IF NOT EXISTS `quasar`.`%s_stats` (
    `id`            INT         NOT NULL AUTO_INCREMENT,
    `steam64_id`    VARCHAR(64) NULL DEFAULT NULL,
    `points`        DECIMAL     NOT NULL DEFAULT `0.0`,
    `kills`         INT         UNSIGNED NOT NULL DEFAULT 0,
    `afk_points`    DECIMAL     NOT NULL DEFAULT `0.0`
    `afk_kills`     INT         UNSIGNED NOT NULL DEFAULT 0,
    `first_login`   INT         NOT NULL DEFAULT `-1`
    `last_login`    INT         NOT NULL DEFAULT `-1`
    `playtime`      INT         NOT NULL DEFAULT `0`
    `time_afk`      INT         NOT NULL DEFAULT `0`,
    PRIMARY KEY (
        `id`,
        `steam64_id`),
    CONSTRAINT `FK_players_%s_stats`
        FOREIGN KEY (`steam64_id`)
        REFERENCES `quasar`.`players` (`steam64_id`));
