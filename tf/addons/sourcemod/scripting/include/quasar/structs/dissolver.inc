static int    _dissolverIEntRef;
static char   _dissolverSTarget[256];
static int    _dissolverIMagnitude;
static int    _dissolverIDissolveType;

enum DissolveType
{
    DissolveType_Energy,
    DissolveType_HeavyElectrical,
    DissolveType_LightElectrical,
    DissolveType_Core
}

/**
 *  Wrapper for an "ent_entity_dissolver" entity.
 * 
 *  You only need one of these per plugin.
 *  Initialize OnMapStart, close OnMapEnd!!
 */
methodmap QSRDissolver __nullable__
{
    public QSRDissolver()
    {
        int i_idx = CreateEntityByName("env_entity_dissolver");
        PrintToServer("i_idx: %d", i_idx);

        if (i_idx == -1 || !IsValidEdict(i_idx)) 
        { 
            return null; 
        }
        
        _dissolverIEntRef = EntIndexToEntRef(i_idx);
        return view_as<QSRDissolver>(_dissolverIEntRef);
    }

    property int Magnitude
    {
        public get()
        {
            return _dissolverIMagnitude;
        }

        public set(int magnitude)
        {
            int i_idx = EntRefToEntIndex(_dissolverIEntRef);
            if (!this.Validate())
            {
                PrintToServer("[QSR] Unable to set magnitude, dissolver is invalid!");
                return;
            }

            _dissolverIMagnitude = magnitude;
            DispatchKeyValueInt(i_idx, "magnitude", magnitude);
        
        }
    }

    property DissolveType DissolveEffect
    {
        public get()
        {
            return view_as<DissolveType>(_dissolverIDissolveType);
        }

        public set(DissolveType effect)
        {
            int i_idx = EntRefToEntIndex(_dissolverIEntRef);
            if (!this.Validate())
            {
                PrintToServer("[QSR] Unable to set dissolve effect, dissolver is invalid!");
                return;
            }

            _dissolverIDissolveType = view_as<int>(effect);
            DispatchKeyValueInt(i_idx, "dissolvetpye", view_as<int>(effect));
        }
    }

    public bool SetTarget(int entRef)
    {
        int i_targetIdx = EntRefToEntIndex(entRef),
            i_idx       = EntRefToEntIndex(_dissolverIEntRef);

        if (!IsValidEntity(i_targetIdx))
        {
            PrintToServer("[QSR] Target for env_dissolver_entity is invalid!");
            strcopy(_dissolverSTarget, sizeof(_dissolverSTarget), "INVALID_TARGET");
            return false;
        }

        char s_entityName[256];
        GetEntPropString(i_targetIdx, Prop_Data, "m_iName", s_entityName, sizeof(s_entityName));
        strcopy(_dissolverSTarget, sizeof(_dissolverSTarget), s_entityName);
    }

    public void Dissolve()
    {
        if (!this.Validate())
        {
            PrintToServer("[QSR] Dissolver is not valid!");
            return;
        }

        if (!_dissolverSTarget[0] || StrEqual(_dissolverSTarget, "INVALID_TARGET"))
        {
            PrintToServer("[QSR] Target for env_dissolver_entity is invalid! Cannot dissolve.");
            return;
        }

        int i_idx = EntRefToEntIndex(_dissolverIEntRef);
        AcceptEntityInput(i_idx, "Dissolve", 0);
    }

    public bool Validate()
    {
        int i_idx = EntRefToEntIndex(_dissolverIEntRef);

        if (!i_idx || i_idx == INVALID_ENT_REFERENCE || !IsValidEntity(i_idx)) { PrintToServer("Dissolver Ref: %d Index: %d", _dissolverIEntRef, i_idx); return false; }
        return true;
    }

    public void Close()
    {
        if (this.Validate())
        {
            int i_idx = EntRefToEntIndex(_dissolverIEntRef);
            RemoveEntity(i_idx);
        }

        _dissolverIEntRef = -1;
        _dissolverIMagnitude = 1;
        _dissolverIDissolveType = 0;
        _dissolverSTarget = "";
    }
}