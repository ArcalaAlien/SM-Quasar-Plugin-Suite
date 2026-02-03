-- ?24
CREATE TABLE IF NOT EXISTS `quasar`.`tf_items_attributes` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `item_id` INT NOT NULL DEFAULT -1,
    `attribute_id` INT NOT NULL DEFAULT -1,
    `attribute_value` DECIMAL(10) NOT NULL DEFAULT 0.0,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_tf_items_attributes_id` (`id` ASC),
    UNIQUE INDEX `idx_tf_items_attributes_item_id` (`item_id` ASC),
    UNIQUE INDEX `idx_tf_items_attributes_attribute_id` (`attribute_id` ASC),
    INDEX `idx_tf_items_attributes_attribute_value` (`attribute_value` ASC),
    CONSTRAINT `FK_ia_items`
    FOREIGN KEY (`item_id`)
    REFERENCES `quasar`.`tf_items` (`id`),
    CONSTRAINT `FK_ia_attributes`
    FOREIGN KEY (`attribute_id`)
    REFERENCES `quasar`.`tf_attributes` (`id`)
);
