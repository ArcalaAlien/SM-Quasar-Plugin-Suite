enum struct QSRPlayer
{
    int     i_userid;
    int     i_credits;
    int     i_loginAttempts;
    int     i_fetchInfoAttempts;

    bool    b_isLoggedIn;
    bool    b_isInfoFetched;
    bool    b_sentLoginMessage;

    char    s_steam2ID[MAX_AUTHID_LENGTH];
    char    s_steam3ID[MAX_AUTHID_LENGTH];
    char    s_steam64ID[MAX_AUTHID_LENGTH];
    char    s_name[MAX_NAME_LENGTH];

    Handle  h_pollAuthTimer;

    void Reset()
    {        
        this.i_userid               = -1;
        this.i_credits              = 0;
        this.i_loginAttempts        = 0;
        this.i_fetchInfoAttempts    = 0;

        this.b_isLoggedIn           = false;
        this.b_isInfoFetched        = false;
        this.b_sentLoginMessage     = false;

        this.s_steam2ID             = EMPTY_STRING;
        this.s_steam3ID             = EMPTY_STRING;
        this.s_steam64ID            = EMPTY_STRING;
        this.s_name                 = EMPTY_STRING;

        if (this.h_pollAuthTimer != null)  
        { 
            KillTimer(this.h_pollAuthTimer);
            this.h_pollAuthTimer = null; 
        }
    }
}