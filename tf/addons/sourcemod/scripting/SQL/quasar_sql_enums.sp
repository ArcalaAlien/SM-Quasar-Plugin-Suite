enum QSRDBVersionStatus {
    DBVer_Equal,
    DBVer_NeedsUpdated,
    DBVer_FirstTime
};

enum QSRDBTable {
    // Main Tables
    DBTable_Version,
    DBTable_TFClasses,
    DBTable_TFItems,
    DBTable_TFAttributes,
    DBTable_TFQualities,
    DBTable_TFParticles,
    DBTable_TFPaintKits,
    DBTable_TFWarPaints,
    DBTable_Players,
    DBTable_RankTitles,
    DBTable_PlayersIgnore,
    DBTable_Groups,
    DBTable_Sounds,
    DBTable_Trails,
    DBTable_Tags,
    DBTable_Upgrades,
    DBTable_FunStuff, //TODO: Server Items!
    DBTable_ChatColors,
    DBTable_ColorPackNames,
    DBTable_SubserverStats,
    DBTable_SubserverMaps,
    DBTable_SubserverVotes,
    DBTable_SubserverChatLogs,

    // Junction Tables
    DBTable_TFItemsClasses,
    DBTable_TFItemsAttributes,
    DBTable_PlayersGroups,
    DBTable_ColorsColorPacks,
    DBTable_PlayerInventories,
    DBTable_QuasarLoadouts,
    DBTable_TFLoadouts,
    DBTable_TauntLoadouts,
    DBTable_SubserverMapFeedback,
    DBTable_SubserverPlayerRatings,
    DBTable_InventoryView,
    DBTable_MapRatingView,
    NUM_DBTABLES
};

// Replace SUBSERVER with gS_subserver if you
// use these table names!!!!
static char gS_tableNames[NUM_DBTABLES][] = {
    "quasar.db_version",
    "quasar.tf_classes",
    "quasar.tf_items",
    "quasar.tf_attributes",
    "quasar.tf_qualities",
    "quasar.tf_particles",
    "quasar.tf_paint_kits",
    "quasar.tf_war_paints",
    "quasar.players",
    "quasar.rank_titles",
    "quasar.players_ignore",
    "quasar.groups",
    "quasar.sounds",
    "quasar.trails",
    "quasar.tags",
    "quasar.upgrades",
    "quasar.fun_stuff",
    "quasar.chat_colors",
    "quasar.chat_pack_names",
    "quasar.SUBSERVER_stats",
    "quasar.SUBSERVER_maps",
    "quasar.SUBSERVER_vote_logs",
    "quasar.SUBSERVER_chat_logs",
    "quasar.tf_items_classes",
    "quasar.tf_items_attributes",
    "quasar.players_groups",
    "quasar.colors_packs",
    "quasar.player_items",
    "quasar.quasar_loadouts",
    "quasar.tf_loadouts",
    "quasar.taunt_loadouts",
    "quasar.SUBSERVER_maps_feedback",
    "quasar.SUBSERVER_maps_ratings",
    "quasar.[inventories]",
    "quasar.[SUBSERVER_map_ratings]"
};
