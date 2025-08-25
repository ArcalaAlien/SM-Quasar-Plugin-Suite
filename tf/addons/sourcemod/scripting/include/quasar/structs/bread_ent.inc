// Total number of models we will allow at once.
// If you somehow reach this there's a big problem.
#define MAX_BREAD_ENTITIES (MAXPLAYERS+1)*2
#define MYSELF view_as<int>(this)

static int    _breadICounter;
static int    _breadIEntRef[MAX_BREAD_ENTITIES+1]         = {-1, ...};
static float  _breadFEntLifetime[MAX_BREAD_ENTITIES+1]    = {3.0, ...};
static Handle _breadHEntTimer[MAX_BREAD_ENTITIES+1]       = {INVALID_HANDLE, ...};

methodmap QSRBreadEntity < Handle 
{
    public QSRBreadEntity()
    {
        int _breadIdx = _breadICounter+1;

        if (_breadICounter >= MAX_BREAD_ENTITIES || _breadICounter < 0)
        {
            PrintToServer("[QSR] ERROR! Somehow the bread counter has gone over, or under, the bounds! Currently At: %d, Min: 0, Max %d", _breadIdx, MAX_BREAD_ENTITIES);
            return view_as<QSRBreadEntity>(INVALID_HANDLE);
        }

        _breadICounter++;
        return view_as<QSRBreadEntity>(_breadIdx);
    }

    property int EntReference
    {
        public get()
        {
            return _breadIEntRef[MYSELF];
        }

        public set(int entReference)
        {
            _breadIEntRef[MYSELF] = entReference;
        }
    }

    property float EntLifetime
    {
        public get()
        {
            return _breadFEntLifetime[MYSELF];
        }

        public set(float lifetime)
        {
            _breadFEntLifetime[MYSELF] = lifetime;
        }
    }

    property Handle EntTimer
    {
        public get()
        {
            return _breadHEntTimer[MYSELF];
        }

        public set(Handle timer)
        {
            if (_breadHEntTimer[MYSELF] != INVALID_HANDLE)
            {
                KillTimer(_breadHEntTimer[MYSELF]);
                _breadHEntTimer[MYSELF] = INVALID_HANDLE;
            }

            _breadHEntTimer[MYSELF] = timer;
        }
    }

    public bool Validate()
    {
        int i_entIndex = EntRefToEntIndex(_breadIEntRef[MYSELF]);
        if (i_entIndex != INVALID_ENT_REFERENCE && IsValidEdict(i_entIndex)) { return true; }

        return false;
    }

    public void CleanUp()
    {
        if (this.Validate())
        {
            RemoveEntity(EntRefToEntIndex(_breadIEntRef[MYSELF]));
        }

        _breadICounter--;
        this.Reset();
    }

    public void Reset()
    {
        _breadIEntRef[MYSELF] = -1;
        _breadFEntLifetime[MYSELF] = 3.0;

        if (_breadHEntTimer[MYSELF] != INVALID_HANDLE) { KillTimer(_breadHEntTimer[MYSELF]); }
        _breadHEntTimer[MYSELF] = INVALID_HANDLE;
    }
}

#undef MYSELF