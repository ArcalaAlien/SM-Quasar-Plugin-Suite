--?33
DROP TABLE IF EXISTS `quasar`.`[inventories]`;
DROP VIEW IF EXISTS `quasar`.`[inventories]`;
CREATE OR REPLACE VIEW `quasar`.`[inventories]` AS
    SELECT
        plyrItms.steam64_id, plyrItms.item_id
        strTrls.name, strTrls.vtf_filepath
            strTrls.vmt_filepath, strTrls.price
        strTags.name, strTags.format, strTags.price
        strSnds.name, strSnds.price, strSnds.filepath
            strSnds.cooldown, strSnds.activation_word
        strUpgd.name, strUpgd.price, strUpgd.description
    FROM players_items plyrItms
        LEFT JOIN trails strTrls
            ON strTrls.item_id = plyrItms.item_id
        LEFT JOIN tags strTags
            ON strTags.item_id = plyrItms.item_id
        LEFT JOIN sounds strSnds
            ON strSnds.item_id = plyrItms.item_id
        LEFT JOIN upgrades strUpgd
            ON strUpgd.item_id = plyrItms.item_id;
