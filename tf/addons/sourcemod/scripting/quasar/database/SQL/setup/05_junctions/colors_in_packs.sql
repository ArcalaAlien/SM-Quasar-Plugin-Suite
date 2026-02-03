-- ?26
CREATE TABLE IF NOT EXISTS `quasar`.`colors_in_packs` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `color_format` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `pack_id` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_colors_packs_id` (`id` ASC),
    UNIQUE INDEX `idx_colors_packs_pack_id` (`pack_id` ASC),
    INDEX `idx_colors_packs_color_format` (`color_format` ASC),
    CONSTRAINT `FK_colors_packs_colors`
    FOREIGN KEY (`color_format`)
    REFERENCES `quasar`.`chat_colors` (`format`),
    CONSTRAINT `FK_colors_packs_packs`
    FOREIGN KEY (`pack_id`)
    REFERENCES `quasar`.`color_packs` (`id`)
);
