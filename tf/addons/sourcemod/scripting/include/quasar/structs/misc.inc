#define MISCMOD_NONE            0           // No Modules Enabled
#define MISCMOD_NOFALL          (1 << 0)    // No Fall Damage
#define MISCMOD_NOFALLNOISE     (1 << 1)    // No Fall Damage Noise
#define MISCMOD_SP              (1 << 2)    // Spawn Protection
#define MISCMOD_AR              (1 << 3)    // Auto Restart
#define MISCMOD_CRT             (1 << 4)    // Custom Respawn Times
#define MISCMOD_TP              (1 << 5)    // Third Person
#define MISCMOD_FRIENDLY        (1 << 6)    // Friendly
#define MISCMOD_BREAD           (1 << 7)    // Teleport Bread
#define MISCMOD_FOV             (1 << 8)    // Field of View

#define BREADMDL_BAGUETTE       "models/weapons/c_models/c_bread/c_bread_baguette.mdl"
#define BREADMDL_BURNT          "models/weapons/c_models/c_bread/c_bread_burnt.mdl"
#define BREADMDL_CINNAMON       "models/weapons/c_models/c_bread/c_bread_cinnamon.mdl"
#define BREADMDL_CORNBREAD      "models/weapons/c_models/c_bread/c_bread_cornbread.mdl"
#define BREADMDL_CRUMPET        "models/weapons/c_models/c_bread/c_bread_crumpet.mdl"
#define BREADMDL_PLAINLOAF      "models/weapons/c_models/c_bread/c_bread_plainloaf.mdl"
#define BREADMDL_PRETZEL        "models/weapons/c_models/c_bread/c_bread_pretzel.mdl"
#define BREADMDL_RATION         "models/weapons/c_models/c_bread/c_bread_ration.mdl"
#define BREADMDL_RUSSIANBLACK   "models/weapons/c_models/c_bread/c_bread_russianblack.mdl"

#define DEFAULT_FOV 75

enum QSRMiscModuleType
{
    MiscModule_None = 0,
    MiscModule_NoFallDamageNoise,
    MiscModule_NoFallDamage,
    MiscModule_SpawnProtection,
    MiscModule_AutoRestart,
    MiscModule_CustomRespawnTimes,
    MiscModule_ThirdPerson,
    MiscModule_Friendly,
    MiscModule_TeleportBread,
    MiscModule_FOV
}

enum QSRBreadModel
{
    BreadModel_Random = 0,
    BreadModel_Baguette,
    BreadModel_Burnt,
    BreadModel_Cinnamon,
    BreadModel_Cornbread,
    BreadModel_Crumpet,
    BreadModel_PlainLoaf,
    BreadModel_Pretzel,
    BreadModel_Ration,
    BreadModel_RussianBlack
}

enum QSRPov
{
    POV_FirstPerson,
    POV_ThirdPerson
}

enum struct QSRSpInfo
{
    bool  b_enabled;
    bool  b_protected;
    float f_timeLeft;

    Handle h_protectionTimer;

    void Reset()
    {
        if (this.h_protectionTimer != INVALID_HANDLE)
        {
            KillTimer(this.h_protectionTimer);
            this.h_protectionTimer = INVALID_HANDLE;
        }

        this.b_enabled = true;
        this.b_protected = false;
        this.f_timeLeft = 0.0;
    }
}

enum struct QSRRespawnInfo
{
    float  f_respawnTime;
    float  f_respawnTimeLeft;
    bool   b_waiting;

    Handle h_respawnTimer;

    void Reset()
    {
        if (this.h_respawnTimer != INVALID_HANDLE)
        {
            KillTimer(this.h_respawnTimer);
            this.h_respawnTimer = INVALID_HANDLE;
        }

        this.f_respawnTime = 5.0;
        this.f_respawnTimeLeft = 0.0;
        this.b_waiting     = false;
    }
}

#include <quasar/structs/dissolver>
#include <quasar/structs/bread_ent>
