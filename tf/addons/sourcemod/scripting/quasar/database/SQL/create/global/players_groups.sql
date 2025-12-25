--?25
DROP TABLE IF EXISTS `quasar`.`players_groups`;
CREATE TABLE IF NOT EXISTS `quasar`.`players_groups` (
    `steam64_id` VARCHAR(64)    NULL DEFAULT NULL,
    `group_id`   INT            NULL     DEFAULT NULL,
    PRIMARY KEY (
        `steam64_id`,
        `group_id`
    ),
    CONSTRAINT `FK_storeplayersgroups_groups`
        FOREIGN KEY (`group_id`)
        REFERENCES `quasar`.`groups` (`id`));
