#if defined _client_prefs_stocks_included
	#endinput
#endif
#define _client_prefs_stocks_included

#include <clientprefs>

enum CookieDataType {
	CookieType_Unknown,
	CookieType_Boolean,
	CookieType_Integer,
	CookieType_Real,
	CookieType_String,
};

methodmap Cookie < Handle
{
	public Cookie(const char[] name, const char[] description, CookieAccess access=CookieAccess_Protected)
	{
		if(name[0] == 0)
			return view_as<Cookie>(INVALID_HANDLE);
		return view_as<Cookie>(RegClientCookie(name, description, access));
	}
	
	property bool IsValid
	{
		public get() { return this != null; }
	}
	
	public bool HasValue(int iClient)
	{
		if(this == null)
			return false;
		if(!AreClientCookiesCached(iClient))
			return false;
		
		char sValue[1024]; // EXTREMELY generous buffer for testing
		GetClientCookie(iClient, this, sValue, sizeof(sValue));
		
		return sValue[0] != '\0';
	}

	public void SetPrefabMenu(CookieMenu type, const char[] display, CookieMenuHandler handler=INVALID_FUNCTION, any info=0)
	{
		SetCookiePrefabMenu(this, type, display, handler, info);
	}
	
	public void SetValue(int iClient, const char[] sValue="")
	{
		if(this == null)
		{
			LogError("[SM] Tried to set a cookie with an invalid cookie handle!");
			return;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to set a cookie for a client that isn't cached yet!");
			return;
		}
		SetClientCookie(iClient, this, sValue);
	}
	
	public void GetValue(int iClient, char[] sValue, int iMaxLen)
	{
		if(this == null)
		{
			LogError("[SM] Tried to set a cookie with an invalid cookie handle!");
			return;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to set a cookie for a client that isn't cached yet!");
			return;
		}
		GetClientCookie(iClient, this, sValue, iMaxLen);
	}
	
	public void SetInt(int iClient, int iNum=0)
	{
		if(this == null)
		{
			LogError("[SM] Tried to set a cookie with an invalid cookie handle!");
			return;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to set a cookie for a client that isn't cached yet!");
			return;
		}
		char sCookieVal[65];
		IntToString(iNum, sCookieVal, sizeof(sCookieVal));
		SetClientCookie(iClient, this, sCookieVal);
	}
	
	public int GetInt(int iClient)
	{
		if(this == null)
		{
			LogError("[SM] Tried to get a cookie with an invalid cookie handle!");
			return 0;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to get a cookie for a client that isn't cached yet!");
			return 0;
		}
		char sCookieVal[65];
		GetClientCookie(iClient, this, sCookieVal, sizeof(sCookieVal));
		return StringToInt(sCookieVal);
	}
	
	public void SetFloat(int iClient, float fFloat=0.0)
	{
		if(this == null)
		{
			LogError("[SM] Tried to set a cookie with an invalid cookie handle!");
			return;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to set a cookie for a client that isn't cached yet!");
			return;
		}
		char sCookieVal[65];
		FloatToString(fFloat, sCookieVal, sizeof(sCookieVal));
		SetClientCookie(iClient, this, sCookieVal);
	}
	
	public float GetFloat(int iClient)
	{
		if(this == null)
		{
			LogError("[SM] Tried to get a cookie with an invalid cookie handle!");
			return 0.0;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to get a cookie for a client that isn't cached yet!");
			return 0.0;
		}
		char sCookieVal[65];
		GetClientCookie(iClient, this, sCookieVal, sizeof(sCookieVal));
		return StringToFloat(sCookieVal);
	}
	
	public void SetBool(int iClient, bool bEnabled=false)
	{
		if(this == null)
		{
			LogError("[SM] Tried to set a cookie with an invalid cookie handle!");
			return;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to set a cookie for a client that isn't cached yet!");
			return;
		}
		char sCookieVal[4];
		Format(sCookieVal, sizeof(sCookieVal), "%s", bEnabled ? "on" : "off");
		SetClientCookie(iClient, this, sCookieVal);
	}
	
	public bool GetBool(int iClient)
	{
		if(this == null)
		{
			LogError("[SM] Tried to get a cookie with an invalid cookie handle!");
			return false;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to get a cookie for a client that isn't cached yet!");
			return false;
		}
		char sCookieVal[4];
		GetClientCookie(iClient, this, sCookieVal, sizeof(sCookieVal));
		return StrEqual(sCookieVal, "off") ? false : true;
	}
	
	public void SetArray(int iClient, const any[] inArray, int iCount, CookieDataType type=CookieType_Unknown)
	{
		if(this == null)
		{
			LogError("[SM] Tried to set a cookie with an invalid cookie handle!");
			return;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to set a cookie for a client that isn't cached yet!");
			return;
		}
		if(type == CookieType_Unknown)
		{
			LogError("[SM] Tried to set an array but didn't specify the data type!");
			return;
		}
		
		char[][] sBuffer = new char[iCount][65];
		for(int i; i < iCount; ++i)
		{
			switch(type)
			{
				case CookieType_Integer:
					IntToString(inArray[i], sBuffer[i], 65);
				case CookieType_Real:
					FloatToString(inArray[i], sBuffer[i], 65);
				default:
				{
					LogError("[SM] Unknown cookie value type provided, ignoring.");
					return;
				}
			}
		}
		
		char[] sValue = new char[(65 * iCount) + iCount];
		ImplodeStrings(sBuffer, iCount, ";", sValue, (65 * iCount) + iCount);
		
		SetClientCookie(iClient, this, sValue);
	}
	
	public void GetArray(int iClient, any[] outArray, int iCount, CookieDataType type=CookieType_Unknown)
	{
		if(this == null)
		{
			LogError("[SM] Tried to get a cookie with an invalid cookie handle!");
			return;
		}
		if(!AreClientCookiesCached(iClient))
		{
			LogError("[SM] Tried to get a cookie for a client that isn't cached yet!");
			return;
		}
		if(type == CookieType_Unknown)
		{
			LogError("[SM] Tried to get an array but didn't specify the data type!");
			return;
		}
		
		char[] sBuffer = new char[(65 * iCount) + iCount];
		GetClientCookie(iClient, this, sBuffer, (65 * iCount) + iCount);
		
		char[][] sValue = new char[iCount][65];
		ExplodeString(sBuffer, ";", sValue, iCount, 65);
		
		for(int i; i < iCount; ++i)
		{
			switch(type)
			{
				case CookieType_Integer:
					outArray[i] = StringToInt(sValue[i]);
				case CookieType_Real:
					outArray[i] = StringToFloat(sValue[i]);
				default:
				{
					LogError("[SM] Unknown cookie value type provided, ignoring.");
					return;
				}
			}
		}
	}
}

stock void SetClientCookieInt(int iClient, Handle hCookie, int iIn=0)
{
	if(hCookie == INVALID_HANDLE)
	{
		LogError("[SM] Tried to set a cookie with an invalid cookie handle!");
		return;
	}
	if(!AreClientCookiesCached(iClient))
	{
		LogError("[SM] Tried to set a cookie for a client that isn't cached yet!");
		return;
	}
	
	char sCookieVal[65];
	IntToString(iIn, sCookieVal, sizeof(sCookieVal));
	SetClientCookie(iClient, hCookie, sCookieVal);
}

stock void SetClientCookieFloat(int iClient, Handle hCookie, float fIn=0.0)
{
	if(hCookie == INVALID_HANDLE)
	{
		LogError("[SM] Tried to set a cookie with an invalid cookie handle!");
		return;
	}
	if(!AreClientCookiesCached(iClient))
	{
		LogError("[SM] Tried to set a cookie for a client that isn't cached yet!");
		return;
	}
	
	char sCookieVal[65];
	FloatToString(fIn, sCookieVal, sizeof(sCookieVal));
	SetClientCookie(iClient, hCookie, sCookieVal);
}

stock void SetClientCookieBool(int iClient, Handle hCookie, bool bOn=false)
{
	if(hCookie == INVALID_HANDLE)
	{
		LogError("[SM] Tried to set a cookie with an invalid cookie handle!");
		return;
	}
	if(!AreClientCookiesCached(iClient))
	{
		LogError("[SM] Tried to set a cookie for a client that isn't cached yet!");
		return;
	}
	
	char sCookieVal[2];
	Format(sCookieVal, sizeof(sCookieVal), "%s", bOn ? "1" : "0");
	SetClientCookie(iClient, hCookie, sCookieVal);
}

stock int GetClientCookieInt(int iClient, Handle hCookie)
{
	if(hCookie == INVALID_HANDLE)
	{
		LogError("[SM] Tried to get a cookie with an invalid cookie handle!");
		return 0;
	}
	if(!AreClientCookiesCached(iClient))
	{
		LogError("[SM] Tried to get a cookie for a client that isn't cached yet!");
		return 0;
	}
	
	char sCookieVal[65];
	GetClientCookie(iClient, hCookie, sCookieVal, sizeof(sCookieVal));
	return StringToInt(sCookieVal);
}

stock float GetClientCookieFloat(int iClient, Handle hCookie)
{
	if(hCookie == INVALID_HANDLE)
	{
		LogError("[SM] Tried to get a cookie with an invalid cookie handle!");
		return 0.0;
	}
	if(!AreClientCookiesCached(iClient))
	{
		LogError("[SM] Tried to get a cookie for a client that isn't cached yet!");
		return 0.0;
	}
	
	char sCookieVal[65];
	GetClientCookie(iClient, hCookie, sCookieVal, sizeof(sCookieVal));
	return StringToFloat(sCookieVal);
}

stock bool GetClientCookieBool(int iClient, Handle hCookie)
{
	if(hCookie == INVALID_HANDLE)
	{
		LogError("[SM] Tried to get a cookie with an invalid cookie handle!");
		return false;
	}
	if(!AreClientCookiesCached(iClient))
	{
		LogError("[SM] Tried to get a cookie for a client that isn't cached yet!");
		return false;
	}
	
	char sCookieVal[2];
	GetClientCookie(iClient, hCookie, sCookieVal, sizeof(sCookieVal));
	return view_as<bool>(StringToInt(sCookieVal));
}
