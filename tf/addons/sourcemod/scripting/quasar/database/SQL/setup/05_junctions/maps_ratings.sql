-- ?32
CREATE TABLE IF NOT EXISTS `quasar`.`PLREPLACE_maps_ratings` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `map_name` VARCHAR(128) NOT NULL DEFAULT 'UNKNOWN',
    `steam64_id` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `rating` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `idx_PLREPLACE_maps_ratings_id` (`id` ASC),
    UNIQUE INDEX `idx_PLREPLACE_maps_ratings_map_name` (`map_name` ASC),
    UNIQUE INDEX `idx_PLREPLACE_maps_ratings_steam64_id` (`steam64_id` ASC),
    INDEX `idx_PLREPLACE_maps_ratings_rating` (`rating` ASC),
    CONSTRAINT `FK_PLREPLACE_maps_ratings`
    FOREIGN KEY (`map_name`)
    REFERENCES `quasar`.`PLREPLACE_maps` (`name`),
    CONSTRAINT `FK_PLREPLACE_players_ratings`
    FOREIGN KEY (`steam64_id`)
    REFERENCES `quasar`.`players` (`steam64_id`)
);
