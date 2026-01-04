-- ?0
CREATE TABLE IF NOT EXISTS `quasar`.`db_version` (
    `db_version` VARCHAR(16) NOT NULL DEFAULT 'NULL VERSION',
    PRIMARY KEY (`db_version`),
    UNIQUE INDEX `idx_db_version` (`db_version` ASC)
);
