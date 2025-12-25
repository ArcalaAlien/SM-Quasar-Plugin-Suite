--?34
DROP TABLE IF EXISTS `quasar`.`[%s_total_map_rating]`;
DROP VIEW IF EXISTS `quasar`.`[%s_total_map_rating]` ;
CREATE  OR REPLACE VIEW `[%s_total_map_ratings]` AS
SELECT vt.name, total_votes, CAST(total_rating/SUM(total_votes) as decimal) rating
FROM (
    SELECT 	m.name,
            COUNT(DISTINCT steam64_id) total_votes,
            SUM(pm.rating) total_rating
    FROM `quasar`.`%s_maps` m
        JOIN `quasar`.`%s_maps_ratings` pm
            ON m.map = pm.map
    GROUP BY map
) AS vt
    JOIN srv_playersmaps pm
        ON vt.map = pm.map
GROUP BY map, total_votes
ORDER BY rating DESC;
