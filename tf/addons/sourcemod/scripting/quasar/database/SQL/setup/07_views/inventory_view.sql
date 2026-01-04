-- ?33
CREATE OR REPLACE VIEW `quasar`.`inventories` AS
SELECT
    PLYRITMS.steam64_id,
    PLYRITMS.item_id,
    STRTRLS.NAME AS trail_name,
    STRTRLS.vtf_filepath,
    STRTRLS.vmt_filepath,
    STRTRLS.price AS trail_price,
    STRTAGS.name AS tag_name,
    STRTAGS.display,
    STRTAGS.price AS tag_price,
    STRSNDS.name AS sound_name,
    STRSNDS.price AS sound_price,
    STRSNDS.filepath,
    STRSNDS.cooldown,
    STRSNDS.activation_phrase,
    STRUPGD.name AS upgrade_name,
    STRUPGD.price AS upgrade_price,
    STRUPGD.description AS upgrade_description
FROM players_items AS PLYRITMS
LEFT JOIN trails AS STRTRLS
    ON PLYRITMS.item_id = STRTRLS.item_id
LEFT JOIN tags AS STRTAGS
    ON PLYRITMS.item_id = STRTAGS.item_id
LEFT JOIN sounds AS STRSNDS
    ON PLYRITMS.item_id = STRSNDS.item_id
LEFT JOIN upgrades AS STRUPGD
    ON PLYRITMS.item_id = STRUPGD.item_id;
