-- ?23
CREATE TABLE IF NOT EXISTS `quasar`.`tf_items_classes` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `item_id` INT NOT NULL DEFAULT -1,
    `class` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `item_id`,
        `class`,
        `id`
    ),
    UNIQUE INDEX `idx_tf_items_classes_id` (`id` ASC),
    INDEX `idx_tf_items_classes_item_id` (`item_id` ASC),
    INDEX `idx_tf_items_classes_class` (`class` ASC),
    CONSTRAINT `FK_ic_items`
    FOREIGN KEY (`item_id`)
    REFERENCES `quasar`.`tf_items` (`id`),
    CONSTRAINT `FK_ic_classes`
    FOREIGN KEY (`class`)
    REFERENCES `quasar`.`tf_classes` (`id`)
);
