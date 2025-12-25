--?0
DROP TABLE IF EXISTS `quasar`.`db_version`;
CREATE TABLE IF NOT EXISTS `quasar`.`db_version` (
    `version` VARCHAR (16) NOT NULL
PRIMARY KEY (`version`));
