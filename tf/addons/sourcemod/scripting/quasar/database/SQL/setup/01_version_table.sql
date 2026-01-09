-- ?0
CREATE TABLE IF NOT EXISTS `quasar`.`db_version` (
    `qdb_version` VARCHAR(16) NOT NULL DEFAULT 'NULL VERSION',
    PRIMARY KEY (`qdb_version`),
    UNIQUE INDEX `idx_db_version` (`qdb_version` ASC)
);
