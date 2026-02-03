-- ?1
CREATE TABLE IF NOT EXISTS `quasar`.`tf_classes` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_tf_classes_id` (`id` ASC),
    UNIQUE INDEX `idx_tf_classes_name` (`name` ASC)
);
