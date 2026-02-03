-- ?36
CREATE TABLE IF NOT EXISTS `quasar`.`PLREPLACE_maps_map_categories` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `map_id` INT NOT NULL DEFAULT -1,
    `category_id` INT NOT NULL DEFAULT -1,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_PLREPLACE_maps_map_categories_id` (`id` ASC),
    INDEX `idx_PLREPLACE_maps_map_categories_map_id` (`map_id` ASC),
    INDEX `idx_PLREPLACE_maps_map_categories_category_id` (`category_id` ASC),
    FOREIGN KEY (`map_id`) REFERENCES `quasar`.`PLREPLACE_maps`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`category_id`) REFERENCES `quasar`.`PLREPLACE_map_categories`(`id`) ON DELETE CASCADE
);