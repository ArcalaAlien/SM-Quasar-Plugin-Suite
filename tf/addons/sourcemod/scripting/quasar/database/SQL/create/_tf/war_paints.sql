--?7
DROP TABLE IF EXISTS `quasar`.`tf_war_paints`;
CREATE TABLE IF NOT EXISTS `quasar`.`tf_war_paints` (
    `id`    INT NOT NULL DEFAULT -1,
    `name`  VARCHAR(128) NULL DEFAULT NULL,
    PRIMARY KEY (
        `id`
    ));
