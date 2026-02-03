-- ?33
CREATE OR REPLACE VIEW `quasar`.`inventories` AS
SELECT
    plr.steam64_id,
    plr.item_id,
    trl.name AS trail_name,
    trl.vtf_filepath,
    trl.vmt_filepath,
    trl.price AS trail_price,
    tag.name AS tag_name,
    tag.display,
    tag.price AS tag_price,
    snd.name AS sound_name,
    snd.price AS sound_price,
    snd.filepath,
    snd.cooldown,
    snd.activation_phrase,
    ugd.name AS upgrade_name,
    ugd.price AS upgrade_price,
    ugd.description AS upgrade_description
FROM `quasar`.`players_items` AS plr
LEFT JOIN `quasar`.`trails` AS trl
    ON plr.item_id = trl.item_id
LEFT JOIN `quasar`.`tags` AS tag
    ON plr.item_id = tag.item_id
LEFT JOIN `quasar`.`sounds` AS snd
    ON plr.item_id = snd.item_id
LEFT JOIN `quasar`.`upgrades` AS ugd
    ON plr.item_id = ugd.item_id;
