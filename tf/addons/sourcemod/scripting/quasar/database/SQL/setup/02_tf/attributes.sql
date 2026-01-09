-- ?3
CREATE TABLE IF NOT EXISTS `quasar`.`tf_attributes` (
    `id` INT NOT NULL DEFAULT -1,
    `name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `classname` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `description` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_tf_attribute_id` (`id` ASC),
    UNIQUE INDEX `idx_tf_attribute_name` (`name` ASC),
    INDEX `idx_tf_attribute_classname` (`classname` ASC),
    INDEX `idx_tf_attribute_description` (`description` ASC)
);
