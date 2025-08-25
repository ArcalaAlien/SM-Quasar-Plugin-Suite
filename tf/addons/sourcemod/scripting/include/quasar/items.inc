#if defined _quasar_items_included
    #endinput
#endif
#define _quasar_items_included

public SharedPlugin __pl_quasaritems =
{
    name="quasar_items",
    file="quasar_items.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasaritems_SetNTVOptional()
{

}