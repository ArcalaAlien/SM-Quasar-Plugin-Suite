--?26
DROP TABLE IF EXISTS `quasar`.`colors_packs`;
CREATE TABLE IF NOT EXISTS `quasar`.`colors_packs` (
    `color_id`          VARCHAR(64) NULL DEFAULT NULL,
    `pack_id`           VARCHAR(64) NULL DEFAULT NULL,
    PRIMARY KEY (
        `color_id`,
        `pack_id`
    ),
    CONSTRAINT `FK_clrp_colors`
        FOREIGN KEY (`color_id`)
        REFERENCES `quasar`.`chat_colors` (`id`),
    CONSTRAINT `FK_clrp_packs`
        FOREIGN KEY (`pack_id`)
        REFERENCES `quasar`.`chat_colors` (`id`));
