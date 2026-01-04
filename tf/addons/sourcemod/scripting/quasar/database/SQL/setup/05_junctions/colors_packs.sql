-- ?26
CREATE TABLE IF NOT EXISTS `quasar`.`colors_packs` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `color_id` INT NOT NULL DEFAULT 0,
    `pack_id` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (
        `id`,
        `color_id`,
        `pack_id`
    ),
    UNIQUE INDEX `idx_colors_packs_id` (`id` ASC),
    INDEX `idx_colors_packs_color_id` (`color_id` ASC),
    INDEX `idx_colors_packs_pack_id` (`pack_id` ASC),
    CONSTRAINT `FK_clrp_colors`
    FOREIGN KEY (`color_id`)
    REFERENCES `quasar`.`chat_colors` (`id`),
    CONSTRAINT `FK_clrp_packs`
    FOREIGN KEY (`pack_id`)
    REFERENCES `quasar`.`color_pack_names` (`id`)
);
