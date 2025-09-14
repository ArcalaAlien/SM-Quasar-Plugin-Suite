#if defined _quasar_calendar_included
	#endinput
#endif
#define _quasar_calendar_included

public SharedPlugin __pl_quasarcalendar =
{
    name="quasar_calendar",
    file="quasar_calendar.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarcalendar_SetNTVOptional()
{

}
