// MOAR COLORS
// By Dr. McKay
// Inspired by: https://forums.alliedmods.net/showthread.php?t=96831

#if defined _more_colors_included
 #endinput
#endif
#define _more_colors_included

#pragma newdecls optional
#include <regex>

#define MORE_COLORS_VERSION     "2.0.0-MC"
#define MC_MAX_MESSAGE_LENGTH   256
#define MAX_BUFFER_LENGTH       (MC_MAX_MESSAGE_LENGTH * 4)

#define MCOLOR_RED              0xFF4040
#define MCOLOR_BLUE             0x99CCFF
#define MCOLOR_GRAY             0xCCCCCC
#define MCOLOR_GREEN            0x3EFF3E

#define MC_GAME_DODS           0

bool MC_SkipList[MAXPLAYERS+1];
StringMap MC_Trie;
int MC_TeamColors[][] = {{0xCCCCCC, 0x4D7942, 0xFF4040}}; // Multi-dimensional array for games that don't support SayText2. First index is the game index (as defined by the GAME_ defines), second index is team. 0 = spectator, 1 = team1, 2 = team2

static ConVar sm_show_activity;

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client		Client index.
 * @param message		Message (formatting rules).
 *
 * On error/Errors:		If the client is not connected an error will be thrown.
 */
stock void MC_PrintToChat(int client, const char[] message, any ...) {
	MC_CheckTrie();

	if (client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}

	if (!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}

	char buffer[MAX_BUFFER_LENGTH];
	char buffer2[MAX_BUFFER_LENGTH];

	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 3);

	MC_ReplaceColorCodes(buffer2);
	MC_SendMessage(client, buffer2);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags.
 *
 * @param client		Client index.
 * @param message		Message (formatting rules).
 */
stock void MC_PrintToChatAll(const char[] message, any ...) {
	MC_CheckTrie();

	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];

	for (int i = 1; i <= MaxClients; ++i) {
		if (!IsClientInGame(i) || MC_SkipList[i]) {
			MC_SkipList[i] = false;
			continue;
		}

		SetGlobalTransTarget(i);
		Format(buffer, sizeof(buffer), "\x01%s", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 2);

		MC_ReplaceColorCodes(buffer2);
		MC_SendMessage(i, buffer2);
	}
}

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags and teamcolor tag.
 *
 * @param client		Client index.
 * @param author		Author index whose color will be used for teamcolor tag.
 * @param message		Message (formatting rules).
 *
 * On error/Errors:		If the client or author are not connected an error will be thrown
 */
stock void MC_PrintToChatEx(int client, int author, const char[] message, any ...) {
	MC_CheckTrie();

	if (client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}

	if (!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}

	if (author < 0 || author > MaxClients) {
		ThrowError("Invalid client index %i", author);
	}

	if ((author != 0) && !IsClientInGame(author)) {
		ThrowError("Client %i is not in game", author);
	}

	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	MC_ReplaceColorCodes(buffer2, author);
	MC_SendMessage(client, buffer2, author);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags and teamcolor tag.
 *
 * @param author	  Author index whose color will be used for teamcolor tag.
 * @param message   Message (formatting rules).
 *
 * On error/Errors:   If the author is not connected an error will be thrown.
 */
stock void MC_PrintToChatAllEx(int author, const char[] message, any ...) {
	MC_CheckTrie();

	if (author < 0 || author > MaxClients) {
		ThrowError("Invalid client index %i", author);
	}

	if ((author != 0) && !IsClientInGame(author)) {
		ThrowError("Client %i is not in game", author);
	}

	char buffer[MAX_BUFFER_LENGTH];
	char buffer2[MAX_BUFFER_LENGTH];

	for (int i = 1; i <= MaxClients; ++i) {
		if (!IsClientInGame(i) || MC_SkipList[i]) {
			MC_SkipList[i] = false;
			continue;
		}

		SetGlobalTransTarget(i);
		Format(buffer, sizeof(buffer), "\x01%s", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 3);

		MC_ReplaceColorCodes(buffer2, author);
		MC_SendMessage(i, buffer2, author);
	}
}

/**
 * Sends a SayText2 usermessage
 *
 * @param client	Client to send usermessage to
 * @param message	Message to send
 */
stock void MC_SendMessage(int client, const char[] message, int author = 0) {
	if (author == 0) {
		author = client;
	}

	char buffer[MC_MAX_MESSAGE_LENGTH];
	strcopy(buffer, sizeof(buffer), message);

	UserMsg index = GetUserMessageId("SayText2");
	if (index == INVALID_MESSAGE_ID) {
		if (GetEngineVersion() == Engine_DODS) {
			int team = GetClientTeam(author);
			if (team == 0) {
				ReplaceString(buffer, sizeof(buffer), "\x03", "\x04", false); // Unassigned gets green
			}
			else {
				char temp[16];
				Format(temp, sizeof(temp), "\x07%06X", MC_TeamColors[MC_GAME_DODS][team - 1]);
				ReplaceString(buffer, sizeof(buffer), "\x03", temp, false);
			}
		}

		PrintToChat(client, "%s", buffer);
		return;
	}

	Handle buf = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
		Protobuf pb = UserMessageToProtobuf(buf);
		pb.SetInt("ent_idx", author);
		pb.SetBool("chat", true);
		pb.SetString("msg_name", buffer);
		pb.AddString("params", "");
		pb.AddString("params", "");
		pb.AddString("params", "");
		pb.AddString("params", "");
	}
	else {
		BfWrite bf = UserMessageToBfWrite(buf);
		bf.WriteByte(author); // Message author
		bf.WriteByte(true); // Chat message
		bf.WriteString(buffer); // Message text
	}

	EndMessage();
}

/**
 * This function should only be used right in front of
 * MC_PrintToChatAll or MC_PrintToChatAllEx. It causes those functions
 * to skip the specified client when printing the message.
 * After printing the message, the client will no longer be skipped.
 *
 * @param client   Client index
 */
stock void MC_SkipNextClient(int client) {
	if (client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}

	MC_SkipList[client] = true;
}

/**
 * Checks if the colors trie is initialized and initializes it if it's not (used internally)
 *
 * @return			No return
 */
stock void MC_CheckTrie() {
	if (MC_Trie == null) {
		MC_Trie = MC_InitColorTrie();
	}
}

/**
 * Replaces color tags in a string with color codes (used internally by MC_PrintToChat, MC_PrintToChatAll, MC_PrintToChatEx, and MC_PrintToChatAllEx
 *
 * @param buffer		String.
 * @param author		Optional client index to use for {teamcolor} tags, or 0 for none
 * @param removeTags	Optional boolean value to determine whether we're replacing tags with colors, or just removing tags, used by MC_RemoveTags
 * @param maxlen		Optional value for max buffer length, used by MC_RemoveTags
 *
 * On error/Errors:		If the client index passed for author is invalid or not in game.
 */
stock void MC_ReplaceColorCodes(char[] buffer, int author = 0, bool removeTags = false, int maxlen = MAX_BUFFER_LENGTH) {
	MC_CheckTrie();
	if (!removeTags) {
		ReplaceString(buffer, maxlen, "{default}", "\x01", false);
	}
	else {
		ReplaceString(buffer, maxlen, "{default}", "", false);
		ReplaceString(buffer, maxlen, "{teamcolor}", "", false);
	}

	if (author != 0 && !removeTags) {
		if (author < 0 || author > MaxClients) {
			ThrowError("Invalid client index %i", author);
		}

		if (!IsClientInGame(author)) {
			ThrowError("Client %i is not in game", author);
		}

		ReplaceString(buffer, maxlen, "{teamcolor}", "\x03", false);
	}

	int cursor = 0;
	int value;
	char tag[32], buff[32];
	char[] output = new char[maxlen];

	strcopy(output, maxlen, buffer);
	// Since the string's size is going to be changing, output will hold the replaced string and we'll search buffer

	Regex regex = new Regex("{[#a-zA-Z0-9]+}");
	for (int i = 0; i < 1000; i++) { // The RegEx extension is quite flaky, so we have to loop here :/. This loop is supposed to be infinite and broken by return, but conditions have been added to be safe.
		if (regex.Match(buffer[cursor]) < 1) {
			delete regex;
			strcopy(buffer, maxlen, output);
			return;
		}

		regex.GetSubString(0, tag, sizeof(tag));
		MC_StrToLower(tag);
		cursor = StrContains(buffer[cursor], tag, false) + cursor + 1;
		strcopy(buff, sizeof(buff), tag);
		ReplaceString(buff, sizeof(buff), "{", "");
		ReplaceString(buff, sizeof(buff), "}", "");

		if (buff[0] == '#') {
			if (strlen(buff) == 7) {
				Format(buff, sizeof(buff), "\x07%s", buff[1]);
			}
			else if (strlen(buff) == 9) {
				Format(buff, sizeof(buff), "\x08%s", buff[1]);
			}
			else {
				continue;
			}

			if (removeTags) {
				ReplaceString(output, maxlen, tag, "", false);
			}
			else {
				ReplaceString(output, maxlen, tag, buff, false);
			}
		}
		else if (!MC_Trie.GetValue(buff, value)) {
			continue;
		}

		if (removeTags) {
			ReplaceString(output, maxlen, tag, "", false);
		}
		else {
			Format(buff, sizeof(buff), "\x07%06X", value);
			ReplaceString(output, maxlen, tag, buff, false);
		}
	}
	LogError("[MORE COLORS] Infinite loop broken.");
}

/**
 * Gets a part of a string
 *
 * @param input			String to get the part from
 * @param output		Buffer to write to
 * @param maxlen		Max length of output buffer
 * @param start			Position to start at
 * @param numChars		Number of characters to return, or 0 for the end of the string
 */
stock void CSubString(const char[] input, char[] output, int maxlen, int start, int numChars = 0) {
	int i = 0;
	for (;;) {
		if (i == maxlen - 1 || i >= numChars || input[start + i] == '\0') {
			output[i] = '\0';
			return;
		}

		output[i] = input[start + i];
		i++;
	}
}

/**
 * Converts a string to lowercase
 *
 * @param buffer		String to convert
 */
stock void MC_StrToLower(char[] buffer) {
	int len = strlen(buffer);
	for (int i = 0; i < len; i++) {
		buffer[i] = CharToLower(buffer[i]);
	}
}

/**
 * Adds a color to the colors trie
 *
 * @param name			Color name, without braces
 * @param color			Hexadecimal representation of the color (0xRRGGBB)
 * @return				True if color was added successfully, false if a color already exists with that name
 */
stock bool MC_AddColor(const char[] name, int color) {
	MC_CheckTrie();

	int value;

	if (MC_Trie.GetValue(name, value)) {
		return false;
	}

	char newName[64];
	strcopy(newName, sizeof(newName), name);

	MC_StrToLower(newName);
	MC_Trie.SetValue(newName, color);
	return true;
}

/**
 * Removes color tags from a message
 *
 * @param message		Message to remove tags from
 * @param maxlen		Maximum buffer length
 */
stock void MC_RemoveTags(char[] message, int maxlen) {
	MC_ReplaceColorCodes(message, 0, true, maxlen);
}

/**
 * Replies to a command with colors
 *
 * @param client		Client to reply to
 * @param message		Message (formatting rules)
 */
stock void MC_ReplyToCommand(int client, const char[] message, any ...) {
	char buffer[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);

	if (client == 0) {
		MC_RemoveTags(buffer, sizeof(buffer));
		PrintToServer("%s", buffer);
	}
	else if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		MC_RemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, "%s", buffer);
	}
	else {
		MC_PrintToChat(client, "%s", buffer);
	}
}

/**
 * Replies to a command with colors
 *
 * @param client		Client to reply to
 * @param author		Client to use for {teamcolor}
 * @param message		Message (formatting rules)
 */
stock void MC_ReplyToCommandEx(int client, int author, const char[] message, any ...) {
	char buffer[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 4);

	if (client == 0) {
		MC_RemoveTags(buffer, sizeof(buffer));
		PrintToServer("%s", buffer);
	}
	else if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		MC_RemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, "%s", buffer);
	}
	else {
		MC_PrintToChatEx(client, author, "%s", buffer);
	}
}

/**
 * Displays usage of an admin command to users depending on the
 * setting of the sm_show_activity cvar.
 *
 * This version does not display a message to the originating client
 * if used from chat triggers or menus.  If manual replies are used
 * for these cases, then this function will suffice.  Otherwise,
 * MC_ShowActivity2() is slightly more useful.
 * Supports color tags.
 *
 * @param client		Client index doing the action, or 0 for server.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @error
 */
stock int MC_ShowActivity(int client, const char[] format, any ...) {
	if (sm_show_activity == null) {
		sm_show_activity = FindConVar("sm_show_activity");
	}

	char tag[] = "[SM] ";

	char szBuffer[MC_MAX_MESSAGE_LENGTH];
	//char szCMessage[MC_MAX_MESSAGE_LENGTH];
	int value = sm_show_activity.IntValue;
	ReplySource replyto = GetCmdReplySource();

	char name[MAX_NAME_LENGTH] = "Console";
	char sign[MAX_NAME_LENGTH] = "ADMIN";
	bool display_in_chat = false;
	if (client != 0) {
		if (client < 0 || client > MaxClients || !IsClientConnected(client))
			ThrowError("Client index %d is invalid", client);

		GetClientName(client, name, sizeof(name));
		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !id.HasFlag(Admin_Generic, Access_Effective)) {
			sign = "PLAYER";
		}

		/* Display the message to the client? */
		if (replyto == SM_REPLY_TO_CONSOLE) {
			SetGlobalTransTarget(client);
			VFormat(szBuffer, sizeof(szBuffer), format, 3);

			MC_RemoveTags(szBuffer, sizeof(szBuffer));
			PrintToConsole(client, "%s%s", tag, szBuffer);
			display_in_chat = true;
		}
	}
	else {
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(szBuffer, sizeof(szBuffer), format, 3);

		MC_RemoveTags(szBuffer, sizeof(szBuffer));
		PrintToServer("%s%s", tag, szBuffer);
	}

	if (!value) {
		return 1;
	}

	for (int i = 1; i <= MaxClients; ++i) {
		if (!IsClientInGame(i) || IsFakeClient(i) || (display_in_chat && i == client)) {
			continue;
		}

		AdminId id = GetUserAdmin(i);
		SetGlobalTransTarget(i);
		if (id == INVALID_ADMIN_ID || !id.HasFlag(Admin_Generic, Access_Effective)) {
			/* Treat this as a normal user. */
			if ((value & 1) | (value & 2)) {
				char newsign[MAX_NAME_LENGTH];

				if ((value & 2) || (i == client)) {
					newsign = name;
				}
				else {
					newsign = sign;
				}

				VFormat(szBuffer, sizeof(szBuffer), format, 3);

				MC_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
		else {
			/* Treat this as an admin user */
			bool is_root = id.HasFlag(Admin_Root, Access_Effective);
			if ((value & 4) || (value & 8) || ((value & 16) && is_root)) {
				char newsign[MAX_NAME_LENGTH];

				if ((value & 8) || ((value & 16) && is_root) || (i == client)) {
					newsign = name;
				}
				else {
					newsign = sign;
				}

				VFormat(szBuffer, sizeof(szBuffer), format, 3);

				MC_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
	}

	return 1;
}

/**
 * Same as MC_ShowActivity(), except the tag parameter is used instead of "[SM] " (note that you must supply any spacing).
 * Supports color tags.
 *
 * @param client		Client index doing the action, or 0 for server.
 * @param tags			Tag to display with.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @error
 */
stock int MC_ShowActivityEx(int client, const char[] tag, const char[] format, any ...) {
	if (sm_show_activity == null) {
		sm_show_activity = FindConVar("sm_show_activity");
	}

	char szTag[MC_MAX_MESSAGE_LENGTH];
	strcopy(szTag, sizeof(szTag), tag);
	MC_RemoveTags(szTag, sizeof(szTag));

	char szBuffer[MC_MAX_MESSAGE_LENGTH];
	//char szCMessage[MC_MAX_MESSAGE_LENGTH];
	int value = sm_show_activity.IntValue;
	ReplySource replyto = GetCmdReplySource();

	char name[MAX_NAME_LENGTH] = "Console";
	char sign[MAX_NAME_LENGTH] = "ADMIN";
	bool display_in_chat = false;
	if (client != 0) {
		if (client < 0 || client > MaxClients || !IsClientConnected(client)) {
			ThrowError("Client index %d is invalid", client);
		}

		GetClientName(client, name, sizeof(name));
		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !id.HasFlag(Admin_Generic, Access_Effective)) {
			sign = "PLAYER";
		}

		/* Display the message to the client? */
		if (replyto == SM_REPLY_TO_CONSOLE) {
			SetGlobalTransTarget(client);
			VFormat(szBuffer, sizeof(szBuffer), format, 4);

			MC_RemoveTags(szBuffer, sizeof(szBuffer));
			PrintToConsole(client, "%s%s", szTag, szBuffer);
			display_in_chat = true;
		}
	}
	else {
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(szBuffer, sizeof(szBuffer), format, 4);

		MC_RemoveTags(szBuffer, sizeof(szBuffer));
		PrintToServer("%s%s", szTag, szBuffer);
	}

	if (!value) {
		return 1;
	}

	for (int i = 1; i <= MaxClients; ++i) {
		if (!IsClientInGame(i) || IsFakeClient(i) || (display_in_chat && i == client)) {
			continue;
		}

		AdminId id = GetUserAdmin(i);
		SetGlobalTransTarget(i);
		if (id == INVALID_ADMIN_ID || !id.HasFlag(Admin_Generic, Access_Effective)) {
			/* Treat this as a normal user. */
			if ((value & 1) | (value & 2)) {
				char newsign[MAX_NAME_LENGTH];

				if ((value & 2) || (i == client)) {
					newsign = name;
				}
				else {
					newsign = sign;
				}

				VFormat(szBuffer, sizeof(szBuffer), format, 4);

				MC_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
		else {
			/* Treat this as an admin user */
			bool is_root = id.HasFlag(Admin_Root, Access_Effective);
			if ((value & 4) || (value & 8) || ((value & 16) && is_root)) {
				char newsign[MAX_NAME_LENGTH];

				if ((value & 8) || ((value & 16) && is_root) || (i == client)) {
					newsign = name;
				}
				else {
					newsign = sign;
				}

				VFormat(szBuffer, sizeof(szBuffer), format, 4);

				MC_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
	}

	return 1;
}

/**
 * Displays usage of an admin command to users depending on the setting of the sm_show_activity cvar.
 * All users receive a message in their chat text, except for the originating client,
 * who receives the message based on the current ReplySource.
 * Supports color tags.
 *
 * @param client		Client index doing the action, or 0 for server.
 * @param tags			Tag to prepend to the message.
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @error
 */
stock int MC_ShowActivity2(int client, const char[] tag, const char[] format, any ...) {
	if (sm_show_activity == null) {
		sm_show_activity = FindConVar("sm_show_activity");
	}

	char szTag[MC_MAX_MESSAGE_LENGTH];
	strcopy(szTag, sizeof(szTag), tag);
	MC_RemoveTags(szTag, sizeof(szTag));

	char szBuffer[MC_MAX_MESSAGE_LENGTH];
	//char szCMessage[MC_MAX_MESSAGE_LENGTH];
	int value = sm_show_activity.IntValue;
	// ReplySource replyto = GetCmdReplySource();

	char name[MAX_NAME_LENGTH] = "Console";
	char sign[MAX_NAME_LENGTH] = "ADMIN";

	if (client != 0) {
		if (client < 0 || client > MaxClients || !IsClientConnected(client)) {
			ThrowError("Client index %d is invalid", client);
		}

		GetClientName(client, name, sizeof(name));

		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !id.HasFlag(Admin_Generic, Access_Effective)) {
			sign = "PLAYER";
		}

		SetGlobalTransTarget(client);
		VFormat(szBuffer, sizeof(szBuffer), format, 4);

		/* We don't display directly to the console because the chat text
		 * simply gets added to the console, so we don't want it to print
		 * twice.
		 */
		MC_PrintToChatEx(client, client, "%s%s", szTag, szBuffer);
	}
	else {
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(szBuffer, sizeof(szBuffer), format, 4);

		MC_RemoveTags(szBuffer, sizeof(szBuffer));
		PrintToServer("%s%s", szTag, szBuffer);
	}

	if (!value) {
		return 1;
	}

	for (int i = 1; i <= MaxClients; ++i) {
		if (!IsClientInGame(i) || IsFakeClient(i) || i == client) {
			continue;
		}

		AdminId id = GetUserAdmin(i);
		SetGlobalTransTarget(i);
		if (id == INVALID_ADMIN_ID || !id.HasFlag(Admin_Generic, Access_Effective)) {
			/* Treat this as a normal user. */
			if ((value & 1) | (value & 2)) {
				char newsign[MAX_NAME_LENGTH];

				if ((value & 2)) {
					newsign = name;
				}
				else {
					newsign = sign;
				}

				VFormat(szBuffer, sizeof(szBuffer), format, 4);

				MC_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
		else {
			/* Treat this as an admin user */
			bool is_root = id.HasFlag(Admin_Root, Access_Effective);
			if ((value & 4) || (value & 8) || ((value & 16) && is_root)) {
				char newsign[MAX_NAME_LENGTH];


				if ((value & 8) || ((value & 16) && is_root)) {
					newsign = name;
				}
				else {
					newsign = sign;
				}

				VFormat(szBuffer, sizeof(szBuffer), format, 4);

				MC_PrintToChatEx(i, client, "%s%s: %s", tag, newsign, szBuffer);
			}
		}
	}

	return 1;
}

/**
 * Determines whether a color name exists
 *
 * @param color			The color name to check
 * @return				True if the color exists, false otherwise
 */
stock bool CColorExists(const char[] color) {
	MC_CheckTrie();
	int temp;
	return MC_Trie.GetValue(color, temp);
}

/**
 * Returns the hexadecimal representation of a client's team color (will NOT initialize the trie)
 *
 * @param client		Client to get the team color for
 * @return				Client's team color in hexadecimal, or green if unknown
 * On error/Errors:		If the client index passed is invalid or not in game.
 */
stock int CGetTeamColor(int client) {
	if (client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}

	if (!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}

	int value;
	switch(GetClientTeam(client)) {
		case 1: {
			value = MCOLOR_GRAY;
		}
		case 2: {
			value = MCOLOR_RED;
		}
		case 3: {
			value = MCOLOR_BLUE;
		}
		default: {
			value = MCOLOR_GREEN;
		}
	}

	return value;
}

stock StringMap MC_InitColorTrie() {
	StringMap hTrie = new StringMap();
	
	// CGA Colors
	hTrie.SetValue("cgablue", 		0x0000AA);
	hTrie.SetValue("cgagreen", 		0x00AA00);
	hTrie.SetValue("cgacyan", 		0x00AAAA);
	hTrie.SetValue("cgared", 		0xAA0000);
	hTrie.SetValue("cgamagenta", 	0xAA00AA);
	hTrie.SetValue("cgabrown", 		0xAA5500);
	hTrie.SetValue("cgalgrey", 		0xAAAAAA);
	hTrie.SetValue("cgalgray", 		0xAAAAAA);
	hTrie.SetValue("cgadgrey", 		0x555555);
	hTrie.SetValue("cgadgray", 		0x555555);
	hTrie.SetValue("cgalblue", 		0x5555FF);
	hTrie.SetValue("cgalgreen", 	0x55FF55);
	hTrie.SetValue("cgalcyan", 		0x55FFFF);
	hTrie.SetValue("cgalred", 		0xFF5555);
	hTrie.SetValue("cgalmagenta", 	0xFF55FF);
	hTrie.SetValue("cgayellow", 	0xFFFF55);

	// SourceMod
	hTrie.SetValue("aliceblue", 0xF0F8FF);
	hTrie.SetValue("allies", 0x4D7942); // same as Allies team in DoD:S
	hTrie.SetValue("ancient", 0xEB4B4B); // same as Ancient item rarity in Dota 2
	hTrie.SetValue("antiquewhite", 0xFAEBD7);
	hTrie.SetValue("aqua", 0x00FFFF);
	hTrie.SetValue("aquamarine", 0x7FFFD4);
	hTrie.SetValue("arcana", 0xADE55C); // same as Arcana item rarity in Dota 2
	hTrie.SetValue("axis", 0xFF4040); // same as Axis team in DoD:S
	hTrie.SetValue("azure", 0x007FFF);
	hTrie.SetValue("beige", 0xF5F5DC);
	hTrie.SetValue("bisque", 0xFFE4C4);
	hTrie.SetValue("black", 0x000000);
	hTrie.SetValue("blanchedalmond", 0xFFEBCD);
	hTrie.SetValue("blue", 0x99CCFF); // same as BLU/Counter-Terrorist team color
	hTrie.SetValue("blueviolet", 0x8A2BE2);
	hTrie.SetValue("brown", 0xA52A2A);
	hTrie.SetValue("burlywood", 0xDEB887);
	hTrie.SetValue("cadetblue", 0x5F9EA0);
	hTrie.SetValue("chartreuse", 0x7FFF00);
	hTrie.SetValue("chocolate", 0xD2691E);
	hTrie.SetValue("collectors", 0xAA0000); // same as Collector's item quality in TF2
	hTrie.SetValue("common", 0xB0C3D9); // same as Common item rarity in Dota 2
	hTrie.SetValue("community", 0x70B04A); // same as Community item quality in TF2
	hTrie.SetValue("coral", 0xFF7F50);
	hTrie.SetValue("cornflowerblue", 0x6495ED);
	hTrie.SetValue("cornsilk", 0xFFF8DC);
	hTrie.SetValue("corrupted", 0xA32C2E); // same as Corrupted item quality in Dota 2
	hTrie.SetValue("crimson", 0xDC143C);
	hTrie.SetValue("cyan", 0x00FFFF);
	hTrie.SetValue("darkblue", 0x00008B);
	hTrie.SetValue("darkcyan", 0x008B8B);
	hTrie.SetValue("darkgoldenrod", 0xB8860B);
	hTrie.SetValue("darkgray", 0xA9A9A9);
	hTrie.SetValue("darkgrey", 0xA9A9A9);
	hTrie.SetValue("darkgreen", 0x006400);
	hTrie.SetValue("darkkhaki", 0xBDB76B);
	hTrie.SetValue("darkmagenta", 0x8B008B);
	hTrie.SetValue("darkolivegreen", 0x556B2F);
	hTrie.SetValue("darkorange", 0xFF8C00);
	hTrie.SetValue("darkorchid", 0x9932CC);
	hTrie.SetValue("darkred", 0x8B0000);
	hTrie.SetValue("darksalmon", 0xE9967A);
	hTrie.SetValue("darkseagreen", 0x8FBC8F);
	hTrie.SetValue("darkslateblue", 0x483D8B);
	hTrie.SetValue("darkslategray", 0x2F4F4F);
	hTrie.SetValue("darkslategrey", 0x2F4F4F);
	hTrie.SetValue("darkturquoise", 0x00CED1);
	hTrie.SetValue("darkviolet", 0x9400D3);
	hTrie.SetValue("deeppink", 0xFF1493);
	hTrie.SetValue("deepskyblue", 0x00BFFF);
	hTrie.SetValue("dimgray", 0x696969);
	hTrie.SetValue("dimgrey", 0x696969);
	hTrie.SetValue("dodgerblue", 0x1E90FF);
	hTrie.SetValue("exalted", 0xCCCCCD); // same as Exalted item quality in Dota 2
	hTrie.SetValue("firebrick", 0xB22222);
	hTrie.SetValue("floralwhite", 0xFFFAF0);
	hTrie.SetValue("forestgreen", 0x228B22);
	hTrie.SetValue("frozen", 0x4983B3); // same as Frozen item quality in Dota 2
	hTrie.SetValue("fuchsia", 0xFF00FF);
	hTrie.SetValue("fullblue", 0x0000FF);
	hTrie.SetValue("fullred", 0xFF0000);
	hTrie.SetValue("gainsboro", 0xDCDCDC);
	hTrie.SetValue("genuine", 0x4D7455); // same as Genuine item quality in TF2
	hTrie.SetValue("ghostwhite", 0xF8F8FF);
	hTrie.SetValue("gold", 0xFFD700);
	hTrie.SetValue("goldenrod", 0xDAA520);
	hTrie.SetValue("gray", 0xCCCCCC); // same as spectator team color
	hTrie.SetValue("grey", 0xCCCCCC);
	hTrie.SetValue("green", 0x3EFF3E);
	hTrie.SetValue("greenyellow", 0xADFF2F);
	hTrie.SetValue("haunted", 0x38F3AB); // same as Haunted item quality in TF2
	hTrie.SetValue("honeydew", 0xF0FFF0);
	hTrie.SetValue("hotpink", 0xFF69B4);
	hTrie.SetValue("immortal", 0xE4AE33); // same as Immortal item rarity in Dota 2
	hTrie.SetValue("indianred", 0xCD5C5C);
	hTrie.SetValue("indigo", 0x4B0082);
	hTrie.SetValue("ivory", 0xFFFFF0);
	hTrie.SetValue("khaki", 0xF0E68C);
	hTrie.SetValue("lavender", 0xE6E6FA);
	hTrie.SetValue("lavenderblush", 0xFFF0F5);
	hTrie.SetValue("lawngreen", 0x7CFC00);
	hTrie.SetValue("legendary", 0xD32CE6); // same as Legendary item rarity in Dota 2
	hTrie.SetValue("lemonchiffon", 0xFFFACD);
	hTrie.SetValue("lightblue", 0xADD8E6);
	hTrie.SetValue("lightcoral", 0xF08080);
	hTrie.SetValue("lightcyan", 0xE0FFFF);
	hTrie.SetValue("lightgoldenrodyellow", 0xFAFAD2);
	hTrie.SetValue("lightgray", 0xD3D3D3);
	hTrie.SetValue("lightgrey", 0xD3D3D3);
	hTrie.SetValue("lightgreen", 0x99FF99);
	hTrie.SetValue("lightpink", 0xFFB6C1);
	hTrie.SetValue("lightsalmon", 0xFFA07A);
	hTrie.SetValue("lightseagreen", 0x20B2AA);
	hTrie.SetValue("lightskyblue", 0x87CEFA);
	hTrie.SetValue("lightslategray", 0x778899);
	hTrie.SetValue("lightslategrey", 0x778899);
	hTrie.SetValue("lightsteelblue", 0xB0C4DE);
	hTrie.SetValue("lightyellow", 0xFFFFE0);
	hTrie.SetValue("lime", 0x00FF00);
	hTrie.SetValue("limegreen", 0x32CD32);
	hTrie.SetValue("linen", 0xFAF0E6);
	hTrie.SetValue("magenta", 0xFF00FF);
	hTrie.SetValue("maroon", 0x800000);
	hTrie.SetValue("mediumaquamarine", 0x66CDAA);
	hTrie.SetValue("mediumblue", 0x0000CD);
	hTrie.SetValue("mediumorchid", 0xBA55D3);
	hTrie.SetValue("mediumpurple", 0x9370D8);
	hTrie.SetValue("mediumseagreen", 0x3CB371);
	hTrie.SetValue("mediumslateblue", 0x7B68EE);
	hTrie.SetValue("mediumspringgreen", 0x00FA9A);
	hTrie.SetValue("mediumturquoise", 0x48D1CC);
	hTrie.SetValue("mediumvioletred", 0xC71585);
	hTrie.SetValue("midnightblue", 0x191970);
	hTrie.SetValue("mintcream", 0xF5FFFA);
	hTrie.SetValue("mistyrose", 0xFFE4E1);
	hTrie.SetValue("moccasin", 0xFFE4B5);
	hTrie.SetValue("mythical", 0x8847FF); // same as Mythical item rarity in Dota 2
	hTrie.SetValue("navajowhite", 0xFFDEAD);
	hTrie.SetValue("navy", 0x000080);
	hTrie.SetValue("normal", 0xB2B2B2); // same as Normal item quality in TF2
	hTrie.SetValue("oldlace", 0xFDF5E6);
	hTrie.SetValue("olive", 0x9EC34F);
	hTrie.SetValue("olivedrab", 0x6B8E23);
	hTrie.SetValue("orange", 0xFFA500);
	hTrie.SetValue("orangered", 0xFF4500);
	hTrie.SetValue("orchid", 0xDA70D6);
	hTrie.SetValue("palegoldenrod", 0xEEE8AA);
	hTrie.SetValue("palegreen", 0x98FB98);
	hTrie.SetValue("paleturquoise", 0xAFEEEE);
	hTrie.SetValue("palevioletred", 0xD87093);
	hTrie.SetValue("papayawhip", 0xFFEFD5);
	hTrie.SetValue("peachpuff", 0xFFDAB9);
	hTrie.SetValue("peru", 0xCD853F);
	hTrie.SetValue("pink", 0xFFC0CB);
	hTrie.SetValue("plum", 0xDDA0DD);
	hTrie.SetValue("powderblue", 0xB0E0E6);
	hTrie.SetValue("purple", 0x800080);
	hTrie.SetValue("rare", 0x4B69FF); // same as Rare item rarity in Dota 2
	hTrie.SetValue("red", 0xFF4040); // same as RED/Terrorist team color
	hTrie.SetValue("rosybrown", 0xBC8F8F);
	hTrie.SetValue("royalblue", 0x4169E1);
	hTrie.SetValue("saddlebrown", 0x8B4513);
	hTrie.SetValue("salmon", 0xFA8072);
	hTrie.SetValue("sandybrown", 0xF4A460);
	hTrie.SetValue("seagreen", 0x2E8B57);
	hTrie.SetValue("seashell", 0xFFF5EE);
	hTrie.SetValue("selfmade", 0x70B04A); // same as Self-Made item quality in TF2
	hTrie.SetValue("sienna", 0xA0522D);
	hTrie.SetValue("silver", 0xC0C0C0);
	hTrie.SetValue("skyblue", 0x87CEEB);
	hTrie.SetValue("slateblue", 0x6A5ACD);
	hTrie.SetValue("slategray", 0x708090);
	hTrie.SetValue("slategrey", 0x708090);
	hTrie.SetValue("snow", 0xFFFAFA);
	hTrie.SetValue("springgreen", 0x00FF7F);
	hTrie.SetValue("steelblue", 0x4682B4);
	hTrie.SetValue("strange", 0xCF6A32); // same as Strange item quality in TF2
	hTrie.SetValue("tan", 0xD2B48C);
	hTrie.SetValue("teal", 0x008080);
	hTrie.SetValue("thistle", 0xD8BFD8);
	hTrie.SetValue("tomato", 0xFF6347);
	hTrie.SetValue("turquoise", 0x40E0D0);
	hTrie.SetValue("uncommon", 0xB0C3D9); // same as Uncommon item rarity in Dota 2
	hTrie.SetValue("unique", 0xFFD700); // same as Unique item quality in TF2
	hTrie.SetValue("unusual", 0x8650AC); // same as Unusual item quality in TF2
	hTrie.SetValue("valve", 0xA50F79); // same as Valve item quality in TF2
	hTrie.SetValue("vintage", 0x476291); // same as Vintage item quality in TF2
	hTrie.SetValue("violet", 0xEE82EE);
	hTrie.SetValue("wheat", 0xF5DEB3);
	hTrie.SetValue("white", 0xFFFFFF);
	hTrie.SetValue("whitesmoke", 0xF5F5F5);
	hTrie.SetValue("yellow", 0xFFFF00);
	hTrie.SetValue("yellowgreen", 0x9ACD32);


	// Roblox
	hTrie.SetValue("rwhite", 0xF2F3EE);
	hTrie.SetValue("rgrey", 0xA1A5A2);
	hTrie.SetValue("rgray", 0xA1A5A2);
	hTrie.SetValue("rlyellow", 0xF9E999);
	hTrie.SetValue("rbyellow", 0xD7C59A);
	hTrie.SetValue("rlgreenmint", 0xC2DAB8);
	hTrie.SetValue("rlredviolet", 0xE8BAC8);
	hTrie.SetValue("rpblue", 0x80BBDB);
	hTrie.SetValue("rlorangebrown", 0xCB8442);
	hTrie.SetValue("rnougat", 0xCC8E69);
	hTrie.SetValue("rbred", 0xC4281C);
	hTrie.SetValue("rmredviolet", 0xC470A0);
	hTrie.SetValue("rbblue", 0x0C69AC);
	hTrie.SetValue("ryellow", 0xF5CD30);
	hTrie.SetValue("rearthorange", 0x624732);
	hTrie.SetValue("rblack", 0x1B2A35);
	hTrie.SetValue("rdarkgrey", 0x6D6E6C);
	hTrie.SetValue("rdarkgray", 0x6D6E6C);
	hTrie.SetValue("rdarkgreen", 0x287F47);
	hTrie.SetValue("rmgreen", 0xA1C48C);
	hTrie.SetValue("rlyishorange", 0xF3CF9B);
	hTrie.SetValue("rbgreen", 0x4B974B);
	hTrie.SetValue("rdarkorange", 0xA05F35);
	hTrie.SetValue("rlightbluishviolet", 0xC1CADE);
	hTrie.SetValue("rtrred", 0xCD544B);
	hTrie.SetValue("rtrlgblue", 0xC1DFF0);
	hTrie.SetValue("rtrblue", 0x7BB6E8);
	hTrie.SetValue("rtryellow", 0xF7F18D);
	hTrie.SetValue("rlightblue", 0xB4D2E4);
	hTrie.SetValue("rtrgreen", 0x84B68D);
	hTrie.SetValue("rposphwhite", 0xECE8DE);
	hTrie.SetValue("rlightred", 0xEEC4B6);
	hTrie.SetValue("rmred", 0xDA867A);
	hTrie.SetValue("rmblue", 0x6E99CA);
	hTrie.SetValue("rlightgrey", 0xC7C1B7);
	hTrie.SetValue("rbviolet", 0x6B327C);
	hTrie.SetValue("rbyorange", 0xE29B40);
	hTrie.SetValue("rborange", 0xDA8541);
	hTrie.SetValue("rbbgreen", 0x008F9C);
	hTrie.SetValue("rearthyellow", 0x685C43);
	hTrie.SetValue("rbbviolet", 0x435494);
	hTrie.SetValue("rmbviolet", 0x6874AC);
	hTrie.SetValue("rtrmrviolet", 0xE5ADC8);
	hTrie.SetValue("rmygreen", 0xC7D23C);
	hTrie.SetValue("rmbgreen", 0x55A5AF);
	hTrie.SetValue("rlbgreen", 0xB7D7D5);
	hTrie.SetValue("rbygreen", 0xA4BD47);
	hTrie.SetValue("rlygreen", 0xD9E4A7);
	hTrie.SetValue("rmyorange", 0xE7AC58);
	hTrie.SetValue("rbrorange", 0xD36F4C);
	hTrie.SetValue("rbviolet", 0x923978);
	hTrie.SetValue("rlightorange", 0xEAB892);
	hTrie.SetValue("rtrbbviolet", 0xA5A5CB);
	hTrie.SetValue("rgold", 0xDCBC81);
	hTrie.SetValue("rdarknougat", 0xAE7A59);
	hTrie.SetValue("rsilver", 0x9CA3A8);
	hTrie.SetValue("rneonorange", 0xD5733D);
	hTrie.SetValue("rsandblue", 0x74869D);
	hTrie.SetValue("rsandviolet", 0x877C90);
	hTrie.SetValue("rmediumorange", 0xE09864);
	hTrie.SetValue("rearthblue", 0x203A56);
	hTrie.SetValue("rearthgreen", 0x27462D);
	hTrie.SetValue("rsandgreen", 0x789082);
	hTrie.SetValue("rsandred", 0x957977);
	hTrie.SetValue("rdarkred", 0x7B2E2F);
	hTrie.SetValue("rgunmetallic", 0x756C62);
	hTrie.SetValue("rcurry", 0xD7A94B);
	hTrie.SetValue("rfireyellow", 0xF9D62E);
	hTrie.SetValue("rreddishbrown", 0x694028);
	hTrie.SetValue("rfyorange", 0xE8AB2D);
	hTrie.SetValue("rfrorange", 0xCF6024);
	hTrie.SetValue("rmediumstonegrey", 0xA3A2A5);
	hTrie.SetValue("rmediumstonegray", 0xA3A2A5);
	hTrie.SetValue("rroyalblue", 0x4667A4);
	hTrie.SetValue("rdarkroyalblue", 0x23478B);
	hTrie.SetValue("rbrlilac", 0x8E4285);
	hTrie.SetValue("rdarkstonegrey", 0x635F62);
	hTrie.SetValue("rdarkstonegray", 0x635F62);
	hTrie.SetValue("rlightstonegrey", 0xE5E4DF);
	hTrie.SetValue("rlightstonegray", 0xE5E4DF);
	hTrie.SetValue("rdarkcurry", 0xB08E44);
	hTrie.SetValue("rfadedgreen", 0x709578);
	hTrie.SetValue("rturquoise", 0x79B5B5);
	hTrie.SetValue("rlightroyalblue", 0x9FC3E9);
	hTrie.SetValue("rmediumroyalblue", 0x6C81B7);
	hTrie.SetValue("rrust", 0x904C2A);
	hTrie.SetValue("rbrown", 0x7C5C46);
	hTrie.SetValue("rreddishlilac", 0x96709F);
	hTrie.SetValue("rlilac", 0x6B629B);
	hTrie.SetValue("rlightlilac", 0xA7A9CE);
	hTrie.SetValue("rbrightpurple", 0xCD6298);
	hTrie.SetValue("rlightpurple", 0xE4ADC8);
	hTrie.SetValue("rlightpink", 0xDC9095);
	hTrie.SetValue("rlightbrickyellow", 0xF0D5A0);
	hTrie.SetValue("rwarmyellowishorange", 0xEBB87F);
	hTrie.SetValue("rcoolyellow", 0xFDEA8D);
	hTrie.SetValue("rdoveblue", 0x7DBBDD);
	hTrie.SetValue("rmediumlilac", 0x342B75);
	hTrie.SetValue("rslimegreen", 0x506D54);
	hTrie.SetValue("rsmokygrey", 0x5B5D69);
	hTrie.SetValue("rsmokygray", 0x5B5D69);
	hTrie.SetValue("rdarkblue", 0x0010B0);
	hTrie.SetValue("rparsleygreen", 0x2C651D);
	hTrie.SetValue("rsteelblue", 0x527CAE);
	hTrie.SetValue("rstormblue", 0x335882);
	hTrie.SetValue("rlapis", 0x102ADC);
	hTrie.SetValue("rdarkindigo", 0x3D1585);
	hTrie.SetValue("rseagreen", 0x348E40);
	hTrie.SetValue("rshamrock", 0x5B9A4C);
	hTrie.SetValue("rfossil", 0x9FA1AC);
	hTrie.SetValue("rmulberry", 0x592259);
	hTrie.SetValue("rforestgreen", 0x1F801D);
	hTrie.SetValue("rcadetblue", 0x9FADC0);
	hTrie.SetValue("relectricblue", 0x0989CF);
	hTrie.SetValue("reggplant", 0x7B007B);
	hTrie.SetValue("rmoss", 0x7C9C6B);
	hTrie.SetValue("rartichoke", 0x8AAB85);
	hTrie.SetValue("rsagegreen", 0xB9C4B1);
	hTrie.SetValue("rghostgrey", 0xCACBD1);
	hTrie.SetValue("rghostgray", 0xCACBD1);
	hTrie.SetValue("rtrlilac", 0xA75E9B);
	hTrie.SetValue("rplum", 0x7B2F7B);
	hTrie.SetValue("rolivine", 0x94BE81);
	hTrie.SetValue("rlaurelgreen", 0xA8BD99);
	hTrie.SetValue("rquillgrey", 0xDFDFDE);
	hTrie.SetValue("rquillgray", 0xDFDFDE);
	hTrie.SetValue("rcrimson", 0x970000);
	hTrie.SetValue("rmint", 0xB1E5A6);
	hTrie.SetValue("rbabyblue", 0x98C2DB);
	hTrie.SetValue("rcarnationpink", 0xFF98DC);
	hTrie.SetValue("rpersimmon", 0xFF5959);
	hTrie.SetValue("rmaroon", 0x750000);
	hTrie.SetValue("rgold", 0xEFB838);
	hTrie.SetValue("rdaisyorange", 0xF8D96D);
	hTrie.SetValue("rpearl", 0xE7E7EC);
	hTrie.SetValue("rfog", 0xC7D4E4);
	hTrie.SetValue("rsalmon", 0xFF9494);
	hTrie.SetValue("rterracotta", 0xBE6862);
	hTrie.SetValue("rcocoa", 0x562424);
	hTrie.SetValue("rwheat", 0xF1E7C7);
	hTrie.SetValue("rbuttermilk", 0xFEF3BB);
	hTrie.SetValue("rmauve", 0xE0B2D0);
	hTrie.SetValue("rsunrise", 0xD490BD);
	hTrie.SetValue("rtawny", 0x965555);
	hTrie.SetValue("rcashmere", 0xD3BE96);
	hTrie.SetValue("rkhaki", 0xE2DCBC);
	hTrie.SetValue("rlilywhite", 0xEDEAEA);
	hTrie.SetValue("rseashell", 0xE9DADA);
	hTrie.SetValue("rburgundy", 0x883E3E);
	hTrie.SetValue("rcork", 0xBC9B5D);
	hTrie.SetValue("rburlap", 0xC7AC78);
	hTrie.SetValue("rbeige", 0xCABFA3);
	hTrie.SetValue("royster", 0xBBB3B2);
	hTrie.SetValue("rpinecone", 0x6C584B);
	hTrie.SetValue("rfawnbrown", 0xA0844F);
	hTrie.SetValue("rhurricanegrey", 0x958988);
	hTrie.SetValue("rhurricanegray", 0x958988);
	hTrie.SetValue("rcloudygrey", 0xABA89E);
	hTrie.SetValue("rcloudygray", 0xABA89E);
	hTrie.SetValue("rlinen", 0xAF9483);
	hTrie.SetValue("rcopper", 0x966766);
	hTrie.SetValue("rdirtbrown", 0x564236);
	hTrie.SetValue("rbronze", 0x7E683F);
	hTrie.SetValue("rflint", 0x69665C);
	hTrie.SetValue("rdarktaupe", 0x5A4C42);
	hTrie.SetValue("rburntsienna", 0x6A3909);
	hTrie.SetValue("rinstitutionalwhite", 0xF8F8F8);
	hTrie.SetValue("rmidgrey", 0xCDCDCD);
	hTrie.SetValue("rmidgray", 0xCDCDCD);
	hTrie.SetValue("rreallyblack", 0x111111);
	hTrie.SetValue("rreallyred", 0xFF0000);
	hTrie.SetValue("rdeeporange", 0xFFB000);
	hTrie.SetValue("ralder", 0xB480FF);
	hTrie.SetValue("rdustyrose", 0xA34B4B);
	hTrie.SetValue("rolive", 0xC1BE42);
	hTrie.SetValue("rnewyeller", 0xFFFF00);
	hTrie.SetValue("rreallyblue", 0x0000FF);
	hTrie.SetValue("rnavyblue", 0x002060);
	hTrie.SetValue("rdeepblue", 0x2154B9);
	hTrie.SetValue("rcyan", 0x04AFEC);
	hTrie.SetValue("rmagenta", 0xAA00AA);
	hTrie.SetValue("rpink", 0xFF66CC);
	hTrie.SetValue("rdeeporange", 0xFF66CC);
	hTrie.SetValue("rteal", 0x12EED4);
	hTrie.SetValue("rtoothpaste", 0x00FFFF);
	hTrie.SetValue("rlimegreen", 0x00FF00);
	hTrie.SetValue("rcamo", 0x3A7D15);
	hTrie.SetValue("rgrime", 0x7F8E64);
	hTrie.SetValue("rlavender", 0x8C5B9F);
	hTrie.SetValue("rpastellightblue", 0xAFDDFF);
	hTrie.SetValue("rpastelorange", 0xFFC9C9);
	hTrie.SetValue("rpastelviolet", 0xB1A7FF);
	hTrie.SetValue("rpastelbluegreen", 0x9FF3E9);
	hTrie.SetValue("rpastelgreen", 0xCCFFCC);
	hTrie.SetValue("rpastelyellow", 0xFFFFCC);
	hTrie.SetValue("rpastelbrown", 0xFFCC99);
	hTrie.SetValue("rroyalpurple", 0x6225D1);
	hTrie.SetValue("rhotpink", 0xFF00BF);

	return hTrie;
}
