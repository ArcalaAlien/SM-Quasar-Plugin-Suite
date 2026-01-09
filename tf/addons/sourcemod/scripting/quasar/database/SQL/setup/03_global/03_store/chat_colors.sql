-- ?17
CREATE TABLE IF NOT EXISTS `quasar`.`chat_colors` (
    `format` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `name` VARCHAR(64) NOT NULL DEFAULT 'UNKNOWN',
    `price` INT NOT NULL DEFAULT 100,
    `category` VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN',
    PRIMARY KEY (`format`),
    UNIQUE INDEX `idx_chat_color_name` (`name` ASC),
    UNIQUE INDEX `idx_chat_color_format` (`format` ASC),
    INDEX `idx_chat_color_price` (`price` ASC),
    INDEX `idx_chat_color_category` (`category` ASC)
);
