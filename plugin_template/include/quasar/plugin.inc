public SharedPlugin __pl_quasarplugin =
{
    name="quasar_plugin",
    file="quasar_plugin.smx",
    #if defined REQUIRE_PLUGIN
        required = 1,
    #else
        required = 0,
    #endif
};

public __pl_quasarplugin_SetNTVOptional()
{

}