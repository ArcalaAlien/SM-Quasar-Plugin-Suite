--?24
DROP TABLE IF EXISTS `quasar`.`tf_items_attributes`;
CREATE TABLE IF NOT EXISTS `quasar`.`tf_items_attributes` (
    `item_id`           INT NOT NULL DEFAULT -1,
    `attribute_id`      INT NOT NULL DEFAULT -1,
    `attribute_value`   DECIMAL(10) NULL DEFAULT NULL,
    PRIMARY KEY (
        `item_id`,
        `attribute_id`
    ),
    CONSTRAINT `FK_ia_items`
        FOREIGN KEY (`item_id`)
        REFERENCES `quasar`.`tf_items` (`id`),
    CONSTRAINT `FK_ia_attributes`
        FOREIGN KEY (`attribute_id`)
        REFERENCES `quasar`.`tf_attributes` (`id`));
