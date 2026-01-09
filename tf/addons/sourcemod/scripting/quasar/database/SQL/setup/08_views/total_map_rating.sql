-- ?34
CREATE OR REPLACE VIEW `quasar`.`PLREPLACE_total_map_rating` AS
SELECT
    vt.name,
    vt.total_votes,
    CAST(vt.total_rating / NULLIF(vt.total_votes, 0) AS DECIMAL(10, 4))
        AS rating
FROM (
    SELECT
        m.name,
        COUNT(DISTINCT pmr.steam64_id) AS total_votes,
        SUM(pmr.rating) AS total_rating
    FROM `quasar`.`PLREPLACE_maps` AS m
    INNER JOIN `quasar`.`PLREPLACE_maps_ratings` AS pmr
        ON m.name = pmr.map_name
    GROUP BY m.name
) AS vt
INNER JOIN `quasar`.`PLREPLACE_maps_ratings` AS srv_pm
    ON vt.name = srv_pm.map_name
GROUP BY vt.name, vt.total_votes
ORDER BY rating DESC;
