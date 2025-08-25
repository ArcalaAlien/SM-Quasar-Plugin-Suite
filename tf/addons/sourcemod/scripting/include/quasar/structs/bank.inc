enum struct QSRBankOptions
{
    char    s_walletName[32];
    char    s_creditsName[32];
    int     i_giveAmount;
    float   f_giveInterval;

    float   f_dropCooldown;
    float   f_dropLifetime;
    int     i_minimumDrop;     
    int     i_maximumDrop;
    char    s_dropModelS[256];
    char    s_dropModelM[256];
    char    s_dropModelL[256];

    int     i_minimumDonation;
    int     i_maximumDonation;

    void Empty()
    {
        this.s_walletName = EMPTY_STRING;
        this.s_creditsName = EMPTY_STRING;
        this.s_dropModelS = EMPTY_STRING;
        this.s_dropModelM = EMPTY_STRING;
        this.s_dropModelL = EMPTY_STRING;
        this.i_giveAmount = 0;
        this.i_minimumDrop = 0;
        this.i_maximumDrop = 0;
        this.i_minimumDonation = 0;
        this.i_maximumDonation = 0;
        this.f_dropCooldown = 0.0;
        this.f_dropLifetime = 0.0;
        this.f_giveInterval = 0.0;
    }
}

enum struct QSRCreditPickup
{
    // Self
    int     i_ownerID;
    int     i_modelEntRef;
    int     i_textEntRef;
    int     i_triggerEntRef;
    int     i_creditAmount;
    char    s_entityName[64];
    char    s_message[256];
    float   f_cooldown;
    float   f_timeLeft;
    bool    b_isTransparent;
    Handle  h_lifetimeTimer;
    Handle  h_cooldownTimer;

    bool OnCooldown()
    {
        return (this.f_cooldown > 0.0);
    }

    void CleanUp()
    {
        int index = EntRefToEntIndex(this.i_modelEntRef);
        if (index && IsValidEdict(index)) { RemoveEntity(index); }

        index = EntRefToEntIndex(this.i_textEntRef);
        if (index && IsValidEdict(index)) { RemoveEntity(index); }
    
        index = EntRefToEntIndex(this.i_triggerEntRef);
        if (index && IsValidEdict(index)) { RemoveEntity(index); }

        if (this.h_lifetimeTimer != INVALID_HANDLE)
        {
            KillTimer(this.h_lifetimeTimer);
            this.h_lifetimeTimer = INVALID_HANDLE;
        }

        this.i_ownerID = -1;
        this.i_modelEntRef = -1;
        this.i_textEntRef = -1;
        this.i_triggerEntRef = -1;
        this.i_creditAmount = 0;
        this.s_entityName = EMPTY_STRING;
        this.s_message = EMPTY_STRING;
        this.f_cooldown = 0.0;
        this.f_timeLeft = 0.0;
        this.b_isTransparent = false;
        this.h_lifetimeTimer = INVALID_HANDLE;
    }

    void Reset()
    {
        int index = EntRefToEntIndex(this.i_modelEntRef);
        if (index && IsValidEdict(index)) { RemoveEntity(index); }

        index = EntRefToEntIndex(this.i_textEntRef);
        if (index && IsValidEdict(index)) { RemoveEntity(index); }

        index = EntRefToEntIndex(this.i_triggerEntRef);
        if (index && IsValidEdict(index)) { RemoveEntity(index); }
    
        if (this.h_lifetimeTimer != INVALID_HANDLE)
        {
            KillTimer(this.h_lifetimeTimer);
            this.h_lifetimeTimer = INVALID_HANDLE;
        }

        if (this.h_cooldownTimer != INVALID_HANDLE)
        {
            KillTimer(this.h_cooldownTimer);
            this.h_cooldownTimer = INVALID_HANDLE;
        }

        this.i_ownerID = -1;
        this.i_modelEntRef = -1;
        this.i_textEntRef = -1;
        this.i_triggerEntRef = -1;
        this.i_creditAmount = 0;
        this.s_entityName = EMPTY_STRING;
        this.s_message = EMPTY_STRING;
        this.f_cooldown = 0.0;
        this.f_timeLeft = 0.0;
        this.b_isTransparent = false;
        this.h_lifetimeTimer = INVALID_HANDLE;
        this.h_cooldownTimer = INVALID_HANDLE;
    }
}

enum struct QSRDonateInfo
{
    int i_donatee;
    int i_amount;

    void Reset()
    {
        this.i_donatee = -1;
        this.i_amount = -1;
    }
}

enum QSRDonateMenuMode
{
    QSRDonateMenu_PlayerCredit,
    QSRDonateMenu_Player,
    QSRDonateMenu_Credit
}