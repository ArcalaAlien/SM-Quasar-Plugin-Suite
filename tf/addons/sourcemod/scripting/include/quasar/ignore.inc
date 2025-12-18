#if defined _quasar_ignore_included
	#endinput
#endif
#define _quasar_ignore_included

#define IGNORE_FLAGS_NONE   0
#define IGNORE_FLAGS_CHAT  (1 << 0)
#define IGNORE_FLAGS_VOICE (1 << 1)

#undef MODULE_NAME
#define MODULE_NAME "Ignore"

public SharedPlugin __pl_quasarignore =
{
    name="quasar_ignore",
    file="quasar_ignore.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarmisc_SetNTVOptional()
{
    MarkNativeAsOptional("QSR_IgnoreTargetPlayer");
}

enum Quasar_IgnoreType
{
    IgnoreType_Chat,
    IgnoreType_Voice
};

enum Quasar_IgnoreResult
{
    IgnoreResult_UnknownError,
    IgnoreResult_TargetedAdmin,
    IgnoreResult_InvalidTarget,
    IgnoreResult_InvalidClient,
    IgnoreResult_Unignored = 0,
    IgnoreResult_Ignored
};

/**
 *  Use this to ignore target player for another target player.
 *
 *  @param clientUserId     The UserId of the client who wants to ignore someone.
 *  @param targetUserId     The UserId of the target the client wants to ignore.
 *  @param ignoreType       What do they want to ignore? IgnoreType_Chat or IgnoreType_Voice
 *  @param targetStatus     True if they want to ignore someone, false if they want to unignore someone.
 *
 *  @return IgnoreResult_Disabled if client successfully unignored target,
 *          IgnoreResult_Enabled if client successfully ignored target,
 */
native Quasar_IgnoreResult QSR_IgnoreTargetPlayer(int clientUserId, int targetUserId, Quasar_IgnoreType ignoreType, bool targetStatus);

/**
 *  Use this to check if a client has ignored a user.
 *
 *  @param clientUserId     The UserId of the client to check
 *  @param targetUserId     The UserId of the ignoree to check.
 *  @param ignoreType       IgnoreType_Voice or IgnoreType_Chat
 *
 *  @return True if ignored, false otherwise
 */
native bool QSR_ClientIgnoredTarget(int clientUserId, int targetUserId, Quasar_IgnoreType ignoreType);
