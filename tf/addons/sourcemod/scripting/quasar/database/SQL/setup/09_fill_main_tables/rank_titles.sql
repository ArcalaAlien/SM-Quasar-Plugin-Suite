-- ?9
REPLACE INTO `quasar`.`rank_titles` (`rank_id`, `name`, `display`, `point_target`, `afk_rank`) VALUES
('rnk_newb', 'Newbie', '{red}Newbie', 0, DEFAULT),
('rnk_begn', 'Beginner', '{orange}Beginner', 3000, DEFAULT),
('rnk_rglr', 'Regular', '{yellow}Regular', 6000, DEFAULT),
('rnk_aclt', 'Acolyte', '{lime}Acolyte', 12500, DEFAULT),
('rnk_mstr', 'Master', '{blue}Master', 25000, DEFAULT),
('rnk_gmtr', 'Grandmaster', '{violet}Grandmaster', 50000, DEFAULT),
('rnk_god', 'God', '{magenta}God', 100000, DEFAULT),
('rnk_afk_I', 'AFK I', '{white}AFK{red}I', 5000, 1),
('rnk_afk_II', 'AFK II', '{white}AFK{orange}II', 10000, 1),
('rnk_afk_III', 'AFK III', '{white}AFK{yellow}III', 25000, 1),
('rnk_afk_IV', 'AFK IV', '{white}AFK{lime}IV', 50000, 1),
('rnk_afk_V', 'AFK V', '{white}AFK{blue}V', 75000, 1),
('rnk_afk_VI', 'AFK VI', '{white}AFK{magenta}VI', 100000, 1);
