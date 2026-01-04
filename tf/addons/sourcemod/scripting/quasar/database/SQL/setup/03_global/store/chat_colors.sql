-- ?17
CREATE TABLE IF NOT EXISTS `quasar`.`chat_colors` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `format` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `price` INT NOT NULL DEFAULT 100,
    `category` VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (
        `id`,
        `format`,
        `name`
    ),
    UNIQUE INDEX `idx_chat_color_id`   (`id` ASC),
    INDEX `idx_chat_color_name` (`name` ASC),
    INDEX `idx_chat_color_format` (`format` ASC)
);