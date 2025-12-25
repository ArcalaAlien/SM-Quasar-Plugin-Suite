--?1
DROP TABLE IF EXISTS `quasar`.`tf_classes`;\
CREATE TABLE IF NOT EXISTS `quasar`.`tf_classes` (\
    `id`        INT NOT NULL AUTO_INCREMENT,\
    `name`      VARCHAR(16) NULL DEFAULT NULL,\
    PRIMARY KEY (\
        `id`\
    )) AUTO_INCREMENT = 1;
