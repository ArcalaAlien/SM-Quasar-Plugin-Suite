--?23
DROP TABLE IF EXISTS `quasar`.`tf_items_classes`;
CREATE TABLE IF NOT EXISTS `quasar`.`tf_items_classes` (
    `item_id`       INT NOT NULL DEFAULT -1,
    `class`         INT NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `item_id`,
        `class`
    ),
    CONSTRAINT `FK_ic_items`
        FOREIGN KEY (`item_id`)
        REFERENCES `quasar`.`tf_items` (`id`),
    CONSTRAINT `FK_ic_classes`
        FOREIGN KEY (`class`)
        REFERENCES `quasar`.`tf_classes` (`id`));
