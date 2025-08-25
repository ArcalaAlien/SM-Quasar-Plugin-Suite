// MOAR COLORS
// By Dr. McKay
// Inspired by: https://forums.alliedmods.net/showthread.php?t=96831

#if defined _colors_included
 #endinput
#endif
#define _colors_included

#include <regex>

#define MORE_COLORS_VERSION		"1.9.1"
#define MAX_MESSAGE_LENGTH		256
#define MAX_BUFFER_LENGTH		(MAX_MESSAGE_LENGTH * 4)

#define COLOR_RED				0xFF4040
#define COLOR_BLUE				0x99CCFF
#define COLOR_GRAY				0xCCCCCC
#define COLOR_GREEN				0x3EFF3E

#define GAME_DODS				0

new bool:CSkipList[MAXPLAYERS + 1];
new Handle:CTrie;
new CTeamColors[][] = {{0xCCCCCC, 0x4D7942, 0xFF4040}}; // Multi-dimensional array for games that don't support SayText2. First index is the game index (as defined by the GAME_ defines), second index is team. 0 = spectator, 1 = team1, 2 = team2

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 * 
 * @param client		Client index.
 * @param message		Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:		If the client is not connected an error will be thrown.
 */
stock CPrintToChat(client, const String:message[], any:...) {
	CCheckTrie();
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	if(!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}
	decl String:buffer[MAX_BUFFER_LENGTH], String:buffer2[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 3);
	CReplaceColorCodes(buffer2);
	CSendMessage(client, buffer2);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags.
 * 
 * @param client		Client index.
 * @param message		Message (formatting rules).
 * @noreturn
 */
stock CPrintToChatAll(const String:message[], any:...) {
	CCheckTrie();
	decl String:buffer[MAX_BUFFER_LENGTH], String:buffer2[MAX_BUFFER_LENGTH];
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || CSkipList[i]) {
			CSkipList[i] = false;
			continue;
		}
		SetGlobalTransTarget(i);
		Format(buffer, sizeof(buffer), "\x01%s", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 2);
		CReplaceColorCodes(buffer2);
		CSendMessage(i, buffer2);
	}
}

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags and teamcolor tag.
 * 
 * @param client		Client index.
 * @param author		Author index whose color will be used for teamcolor tag.
 * @param message		Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:		If the client or author are not connected an error will be thrown
 */
stock CPrintToChatEx(client, author, const String:message[], any:...) {
	CCheckTrie();
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	if(!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}
	if(author <= 0 || author > MaxClients) {
		ThrowError("Invalid client index %i", author);
	}
	if(!IsClientInGame(author)) {
		ThrowError("Client %i is not in game", author);
	}
	decl String:buffer[MAX_BUFFER_LENGTH], String:buffer2[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	CReplaceColorCodes(buffer2, author);
	CSendMessage(client, buffer2, author);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags and teamcolor tag.
 *
 * @param author	  Author index whose color will be used for teamcolor tag.
 * @param message   Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:   If the author is not connected an error will be thrown.
 */
stock CPrintToChatAllEx(author, const String:message[], any:...) {
	CCheckTrie();
	if(author <= 0 || author > MaxClients) {
		ThrowError("Invalid client index %i", author);
	}
	if(!IsClientInGame(author)) {
		ThrowError("Client %i is not in game", author);
	}
	decl String:buffer[MAX_BUFFER_LENGTH], String:buffer2[MAX_BUFFER_LENGTH];
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || CSkipList[i]) {
			CSkipList[i] = false;
			continue;
		}
		SetGlobalTransTarget(i);
		Format(buffer, sizeof(buffer), "\x01%s", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 3);
		CReplaceColorCodes(buffer2, author);
		CSendMessage(i, buffer2, author);
	}
}

/**
 * Sends a SayText2 usermessage
 * 
 * @param client	Client to send usermessage to
 * @param message	Message to send
 * @noreturn
 */
stock CSendMessage(client, const String:message[], author=0) {
	if(author == 0) {
		author = client;
	}
	decl String:buffer[MAX_MESSAGE_LENGTH], String:game[16];
	GetGameFolderName(game, sizeof(game));
	strcopy(buffer, sizeof(buffer), message);
	new UserMsg:index = GetUserMessageId("SayText2");
	if(index == INVALID_MESSAGE_ID) {
		if(StrEqual(game, "dod")) {
			new team = GetClientTeam(author);
			if(team == 0) {
				ReplaceString(buffer, sizeof(buffer), "\x03", "\x04", false); // Unassigned gets green
			} else {
				decl String:temp[16];
				Format(temp, sizeof(temp), "\x07%06X", CTeamColors[GAME_DODS][team - 1]);
				ReplaceString(buffer, sizeof(buffer), "\x03", temp, false);
			}
		}
		PrintToChat(client, "%s", buffer);
		return;
	}
	new Handle:buf = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
		PbSetInt(buf, "ent_idx", author);
		PbSetBool(buf, "chat", true);
		PbSetString(buf, "msg_name", buffer);
		PbAddString(buf, "params", "");
		PbAddString(buf, "params", "");
		PbAddString(buf, "params", "");
		PbAddString(buf, "params", "");
	} else {
		BfWriteByte(buf, author); // Message author
		BfWriteByte(buf, true); // Chat message
		BfWriteString(buf, buffer); // Message text
	}
	EndMessage();
}

/**
 * This function should only be used right in front of
 * CPrintToChatAll or CPrintToChatAllEx. It causes those functions
 * to skip the specified client when printing the message.
 * After printing the message, the client will no longer be skipped.
 * 
 * @param client   Client index
 * @noreturn
 */
stock CSkipNextClient(client) {
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	CSkipList[client] = true;
}

/**
 * Checks if the colors trie is initialized and initializes it if it's not (used internally)
 * 
 * @return			No return
 */
stock CCheckTrie() {
	if(CTrie == INVALID_HANDLE) {
		CTrie = InitColorTrie();
	}
}

/**
 * Replaces color tags in a string with color codes (used internally by CPrintToChat, CPrintToChatAll, CPrintToChatEx, and CPrintToChatAllEx
 *
 * @param buffer		String.
 * @param author		Optional client index to use for {teamcolor} tags, or 0 for none
 * @param removeTags	Optional boolean value to determine whether we're replacing tags with colors, or just removing tags, used by CRemoveTags
 * @param maxlen		Optional value for max buffer length, used by CRemoveTags
 * @noreturn
 * 
 * On error/Errors:		If the client index passed for author is invalid or not in game.
 */
stock CReplaceColorCodes(String:buffer[], author=0, bool:removeTags=false, maxlen=MAX_BUFFER_LENGTH) {
	CCheckTrie();
	if(!removeTags) {
		ReplaceString(buffer, maxlen, "{default}", "\x01", false);
	} else {
		ReplaceString(buffer, maxlen, "{default}", "", false);
		ReplaceString(buffer, maxlen, "{teamcolor}", "", false);
	}
	if(author != 0 && !removeTags) {
		if(author < 0 || author > MaxClients) {
			ThrowError("Invalid client index %i", author);
		}
		if(!IsClientInGame(author)) {
			ThrowError("Client %i is not in game", author);
		}
		ReplaceString(buffer, maxlen, "{teamcolor}", "\x03", false);
	}
	new cursor = 0;
	new value;
	decl String:tag[32], String:buff[32], String:output[maxlen];
	strcopy(output, maxlen, buffer);
	// Since the string's size is going to be changing, output will hold the replaced string and we'll search buffer
	
	new Handle:regex = CompileRegex("{[a-zA-Z0-9]+}");
	for(new i = 0; i < 1000; i++) { // The RegEx extension is quite flaky, so we have to loop here :/. This loop is supposed to be infinite and broken by return, but conditions have been added to be safe.
		if(MatchRegex(regex, buffer[cursor]) < 1) {
			CloseHandle(regex);
			strcopy(buffer, maxlen, output);
			return;
		}
		GetRegexSubString(regex, 0, tag, sizeof(tag));
		CStrToLower(tag);
		cursor = StrContains(buffer[cursor], tag, false) + cursor + 1;
		strcopy(buff, sizeof(buff), tag);
		ReplaceString(buff, sizeof(buff), "{", "");
		ReplaceString(buff, sizeof(buff), "}", "");
		
		if(!GetTrieValue(CTrie, buff, value)) {
			continue;
		}
		
		if(removeTags) {
			ReplaceString(output, maxlen, tag, "", false);
		} else {
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
 * @noreturn
 */
stock CSubString(const String:input[], String:output[], maxlen, start, numChars=0) {
	new i = 0;
	for(;;) {
		if(i == maxlen - 1 || i >= numChars || input[start + i] == '\0') {
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
 * @noreturn
 */
stock CStrToLower(String:buffer[]) {
	new len = strlen(buffer);
	for(new i = 0; i < len; i++) {
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
stock bool:CAddColor(const String:name[], color) {
	CCheckTrie();
	new value;
	if(GetTrieValue(CTrie, name, value)) {
		return false;
	}
	decl String:newName[64];
	strcopy(newName, sizeof(newName), name);
	CStrToLower(newName);
	SetTrieValue(CTrie, newName, color);
	return true;
}

/**
 * Removes color tags from a message
 * 
 * @param message		Message to remove tags from
 * @param maxlen		Maximum buffer length
 * @noreturn
 */
stock CRemoveTags(String:message[], maxlen) {
	CReplaceColorCodes(message, 0, true, maxlen);
}

/**
 * Replies to a command with colors
 * 
 * @param client		Client to reply to
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CReplyToCommand(client, const String:message[], any:...) {
	decl String:buffer[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, "%s", buffer);
	} else {
		CPrintToChat(client, "%s", buffer);
	}
}

/**
 * Replies to a command with colors
 * 
 * @param client		Client to reply to
 * @param author		Client to use for {teamcolor}
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CReplyToCommandEx(client, author, const String:message[], any:...) {
	decl String:buffer[MAX_BUFFER_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 4);
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, "%s", buffer);
	} else {
		CPrintToChatEx(client, author, "%s", buffer);
	}
}

/**
 * Shows admin activity with colors
 * 
 * @param client		Client performing an action
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CShowActivity(client, const String:message[], any:...) {
	CCheckTrie();
	if(client < 0 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
	}
	if(client != 0 && !IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
	}
	decl String:buffer[MAX_BUFFER_LENGTH], String:buffer2[MAX_BUFFER_LENGTH];
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 3);
	CReplaceColorCodes(buffer2);
	ShowActivity(client, "%s", buffer2);
}

/**
 * Shows admin activity with colors
 * 
 * @param client		Client performing an action
 * @param tag			Tag to prepend to the message (color tags supported)
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CShowActivityEx(client, const String:tag[], const String:message[], any:...) {
	CCheckTrie();
	if(client < 0 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
	}
	if(client != 0 && !IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
	}
	decl String:buffer[MAX_BUFFER_LENGTH], String:buffer2[MAX_BUFFER_LENGTH];
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	CReplaceColorCodes(buffer2);
	strcopy(buffer, sizeof(buffer), tag);
	CReplaceColorCodes(buffer);
	ShowActivityEx(client, tag, "%s", buffer2);
}

/**
 * Shows admin activity with colors
 * 
 * @param client		Client performing an action
 * @param tag			Tag to prepend to the message (color tags supported)
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CShowActivity2(client, const String:tag[], const String:message[], any:...) {
	CCheckTrie();
	if(client < 0 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
	}
	if(client != 0 && !IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
	}
	decl String:buffer[MAX_BUFFER_LENGTH], String:buffer2[MAX_BUFFER_LENGTH];
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	CReplaceColorCodes(buffer2);
	strcopy(buffer, sizeof(buffer), tag);
	CReplaceColorCodes(buffer);
	ShowActivity2(client, buffer, "%s", buffer2);
}

/**
 * Determines whether a color name exists
 * 
 * @param color			The color name to check
 * @return				True if the color exists, false otherwise
 */
stock bool:CColorExists(const String:color[]) {
	CCheckTrie();
	new temp;
	return GetTrieValue(CTrie, color, temp);
}

/**
 * Returns the hexadecimal representation of a client's team color (will NOT initialize the trie)
 *
 * @param client		Client to get the team color for
 * @return				Client's team color in hexadecimal, or green if unknown
 * On error/Errors:		If the client index passed is invalid or not in game.
 */
stock CGetTeamColor(client) {
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	if(!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}
	new value;
	switch(GetClientTeam(client)) {
		case 1: {
			value = COLOR_GRAY;
		}
		case 2: {
			value = COLOR_RED;
		}
		case 3: {
			value = COLOR_BLUE;
		}
		default: {
			value = COLOR_GREEN;
		}
	}
	return value;
}

stock Handle:InitColorTrie() {
	new Handle:hTrie = CreateTrie();
	SetTrieValue(hTrie, "aliceblue", 0xF0F8FF);
	SetTrieValue(hTrie, "allies", 0x4D7942); // same as Allies team in DoD:S
	SetTrieValue(hTrie, "ancient", 0xEB4B4B); // same as Ancient item rarity in Dota 2
	SetTrieValue(hTrie, "antiquewhite", 0xFAEBD7);
	SetTrieValue(hTrie, "aqua", 0x00FFFF);
	SetTrieValue(hTrie, "aquamarine", 0x7FFFD4);
	SetTrieValue(hTrie, "arcana", 0xADE55C); // same as Arcana item rarity in Dota 2
	SetTrieValue(hTrie, "axis", 0xFF4040); // same as Axis team in DoD:S
	SetTrieValue(hTrie, "azure", 0x007FFF);
	SetTrieValue(hTrie, "beige", 0xF5F5DC);
	SetTrieValue(hTrie, "bisque", 0xFFE4C4);
	SetTrieValue(hTrie, "black", 0x000000);
	SetTrieValue(hTrie, "blanchedalmond", 0xFFEBCD);
	SetTrieValue(hTrie, "blue", 0x99CCFF); // same as BLU/Counter-Terrorist team color
	SetTrieValue(hTrie, "blueviolet", 0x8A2BE2);
	SetTrieValue(hTrie, "brown", 0xA52A2A);
	SetTrieValue(hTrie, "burlywood", 0xDEB887);
	SetTrieValue(hTrie, "cadetblue", 0x5F9EA0);
	SetTrieValue(hTrie, "chartreuse", 0x7FFF00);
	SetTrieValue(hTrie, "chocolate", 0xD2691E);
	SetTrieValue(hTrie, "collectors", 0xAA0000); // same as Collector's item quality in TF2
	SetTrieValue(hTrie, "common", 0xB0C3D9); // same as Common item rarity in Dota 2
	SetTrieValue(hTrie, "community", 0x70B04A); // same as Community item quality in TF2
	SetTrieValue(hTrie, "coral", 0xFF7F50);
	SetTrieValue(hTrie, "cornflowerblue", 0x6495ED);
	SetTrieValue(hTrie, "cornsilk", 0xFFF8DC);
	SetTrieValue(hTrie, "corrupted", 0xA32C2E); // same as Corrupted item quality in Dota 2
	SetTrieValue(hTrie, "crimson", 0xDC143C);
	SetTrieValue(hTrie, "cyan", 0x00FFFF);
	SetTrieValue(hTrie, "darkblue", 0x00008B);
	SetTrieValue(hTrie, "darkcyan", 0x008B8B);
	SetTrieValue(hTrie, "darkgoldenrod", 0xB8860B);
	SetTrieValue(hTrie, "darkgray", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgrey", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgreen", 0x006400);
	SetTrieValue(hTrie, "darkkhaki", 0xBDB76B);
	SetTrieValue(hTrie, "darkmagenta", 0x8B008B);
	SetTrieValue(hTrie, "darkolivegreen", 0x556B2F);
	SetTrieValue(hTrie, "darkorange", 0xFF8C00);
	SetTrieValue(hTrie, "darkorchid", 0x9932CC);
	SetTrieValue(hTrie, "darkred", 0x8B0000);
	SetTrieValue(hTrie, "darksalmon", 0xE9967A);
	SetTrieValue(hTrie, "darkseagreen", 0x8FBC8F);
	SetTrieValue(hTrie, "darkslateblue", 0x483D8B);
	SetTrieValue(hTrie, "darkslategray", 0x2F4F4F);
	SetTrieValue(hTrie, "darkslategrey", 0x2F4F4F);
	SetTrieValue(hTrie, "darkturquoise", 0x00CED1);
	SetTrieValue(hTrie, "darkviolet", 0x9400D3);
	SetTrieValue(hTrie, "deeppink", 0xFF1493);
	SetTrieValue(hTrie, "deepskyblue", 0x00BFFF);
	SetTrieValue(hTrie, "dimgray", 0x696969);
	SetTrieValue(hTrie, "dimgrey", 0x696969);
	SetTrieValue(hTrie, "dodgerblue", 0x1E90FF);
	SetTrieValue(hTrie, "exalted", 0xCCCCCD); // same as Exalted item quality in Dota 2
	SetTrieValue(hTrie, "firebrick", 0xB22222);
	SetTrieValue(hTrie, "floralwhite", 0xFFFAF0);
	SetTrieValue(hTrie, "forestgreen", 0x228B22);
	SetTrieValue(hTrie, "frozen", 0x4983B3); // same as Frozen item quality in Dota 2
	SetTrieValue(hTrie, "fuchsia", 0xFF00FF);
	SetTrieValue(hTrie, "fullblue", 0x0000FF);
	SetTrieValue(hTrie, "fullred", 0xFF0000);
	SetTrieValue(hTrie, "gainsboro", 0xDCDCDC);
	SetTrieValue(hTrie, "genuine", 0x4D7455); // same as Genuine item quality in TF2
	SetTrieValue(hTrie, "ghostwhite", 0xF8F8FF);
	SetTrieValue(hTrie, "gold", 0xFFD700);
	SetTrieValue(hTrie, "goldenrod", 0xDAA520);
	SetTrieValue(hTrie, "gray", 0xCCCCCC); // same as spectator team color
	SetTrieValue(hTrie, "grey", 0xCCCCCC);
	SetTrieValue(hTrie, "green", 0x3EFF3E);
	SetTrieValue(hTrie, "greenyellow", 0xADFF2F);
	SetTrieValue(hTrie, "haunted", 0x38F3AB); // same as Haunted item quality in TF2
	SetTrieValue(hTrie, "honeydew", 0xF0FFF0);
	SetTrieValue(hTrie, "hotpink", 0xFF69B4);
	SetTrieValue(hTrie, "immortal", 0xE4AE33); // same as Immortal item rarity in Dota 2
	SetTrieValue(hTrie, "indianred", 0xCD5C5C);
	SetTrieValue(hTrie, "indigo", 0x4B0082);
	SetTrieValue(hTrie, "ivory", 0xFFFFF0);
	SetTrieValue(hTrie, "khaki", 0xF0E68C);
	SetTrieValue(hTrie, "lavender", 0xE6E6FA);
	SetTrieValue(hTrie, "lavenderblush", 0xFFF0F5);
	SetTrieValue(hTrie, "lawngreen", 0x7CFC00);
	SetTrieValue(hTrie, "legendary", 0xD32CE6); // same as Legendary item rarity in Dota 2
	SetTrieValue(hTrie, "lemonchiffon", 0xFFFACD);
	SetTrieValue(hTrie, "lightblue", 0xADD8E6);
	SetTrieValue(hTrie, "lightcoral", 0xF08080);
	SetTrieValue(hTrie, "lightcyan", 0xE0FFFF);
	SetTrieValue(hTrie, "lightgoldenrodyellow", 0xFAFAD2);
	SetTrieValue(hTrie, "lightgray", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgrey", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgreen", 0x99FF99);
	SetTrieValue(hTrie, "lightpink", 0xFFB6C1);
	SetTrieValue(hTrie, "lightsalmon", 0xFFA07A);
	SetTrieValue(hTrie, "lightseagreen", 0x20B2AA);
	SetTrieValue(hTrie, "lightskyblue", 0x87CEFA);
	SetTrieValue(hTrie, "lightslategray", 0x778899);
	SetTrieValue(hTrie, "lightslategrey", 0x778899);
	SetTrieValue(hTrie, "lightsteelblue", 0xB0C4DE);
	SetTrieValue(hTrie, "lightyellow", 0xFFFFE0);
	SetTrieValue(hTrie, "lime", 0x00FF00);
	SetTrieValue(hTrie, "limegreen", 0x32CD32);
	SetTrieValue(hTrie, "linen", 0xFAF0E6);
	SetTrieValue(hTrie, "magenta", 0xFF00FF);
	SetTrieValue(hTrie, "maroon", 0x800000);
	SetTrieValue(hTrie, "mediumaquamarine", 0x66CDAA);
	SetTrieValue(hTrie, "mediumblue", 0x0000CD);
	SetTrieValue(hTrie, "mediumorchid", 0xBA55D3);
	SetTrieValue(hTrie, "mediumpurple", 0x9370D8);
	SetTrieValue(hTrie, "mediumseagreen", 0x3CB371);
	SetTrieValue(hTrie, "mediumslateblue", 0x7B68EE);
	SetTrieValue(hTrie, "mediumspringgreen", 0x00FA9A);
	SetTrieValue(hTrie, "mediumturquoise", 0x48D1CC);
	SetTrieValue(hTrie, "mediumvioletred", 0xC71585);
	SetTrieValue(hTrie, "midnightblue", 0x191970);
	SetTrieValue(hTrie, "mintcream", 0xF5FFFA);
	SetTrieValue(hTrie, "mistyrose", 0xFFE4E1);
	SetTrieValue(hTrie, "moccasin", 0xFFE4B5);
	SetTrieValue(hTrie, "mythical", 0x8847FF); // same as Mythical item rarity in Dota 2
	SetTrieValue(hTrie, "navajowhite", 0xFFDEAD);
	SetTrieValue(hTrie, "navy", 0x000080);
	SetTrieValue(hTrie, "normal", 0xB2B2B2); // same as Normal item quality in TF2
	SetTrieValue(hTrie, "oldlace", 0xFDF5E6);
	SetTrieValue(hTrie, "olive", 0x9EC34F);
	SetTrieValue(hTrie, "olivedrab", 0x6B8E23);
	SetTrieValue(hTrie, "orange", 0xFFA500);
	SetTrieValue(hTrie, "orangered", 0xFF4500);
	SetTrieValue(hTrie, "orchid", 0xDA70D6);
	SetTrieValue(hTrie, "palegoldenrod", 0xEEE8AA);
	SetTrieValue(hTrie, "palegreen", 0x98FB98);
	SetTrieValue(hTrie, "paleturquoise", 0xAFEEEE);
	SetTrieValue(hTrie, "palevioletred", 0xD87093);
	SetTrieValue(hTrie, "papayawhip", 0xFFEFD5);
	SetTrieValue(hTrie, "peachpuff", 0xFFDAB9);
	SetTrieValue(hTrie, "peru", 0xCD853F);
	SetTrieValue(hTrie, "pink", 0xFFC0CB);
	SetTrieValue(hTrie, "plum", 0xDDA0DD);
	SetTrieValue(hTrie, "powderblue", 0xB0E0E6);
	SetTrieValue(hTrie, "purple", 0x800080);
	SetTrieValue(hTrie, "rare", 0x4B69FF); // same as Rare item rarity in Dota 2
	SetTrieValue(hTrie, "red", 0xFF4040); // same as RED/Terrorist team color
	SetTrieValue(hTrie, "rosybrown", 0xBC8F8F);
	SetTrieValue(hTrie, "royalblue", 0x4169E1);
	SetTrieValue(hTrie, "saddlebrown", 0x8B4513);
	SetTrieValue(hTrie, "salmon", 0xFA8072);
	SetTrieValue(hTrie, "sandybrown", 0xF4A460);
	SetTrieValue(hTrie, "seagreen", 0x2E8B57);
	SetTrieValue(hTrie, "seashell", 0xFFF5EE);
	SetTrieValue(hTrie, "selfmade", 0x70B04A); // same as Self-Made item quality in TF2
	SetTrieValue(hTrie, "sienna", 0xA0522D);
	SetTrieValue(hTrie, "silver", 0xC0C0C0);
	SetTrieValue(hTrie, "skyblue", 0x87CEEB);
	SetTrieValue(hTrie, "slateblue", 0x6A5ACD);
	SetTrieValue(hTrie, "slategray", 0x708090);
	SetTrieValue(hTrie, "slategrey", 0x708090);
	SetTrieValue(hTrie, "snow", 0xFFFAFA);
	SetTrieValue(hTrie, "springgreen", 0x00FF7F);
	SetTrieValue(hTrie, "steelblue", 0x4682B4);
	SetTrieValue(hTrie, "strange", 0xCF6A32); // same as Strange item quality in TF2
	SetTrieValue(hTrie, "tan", 0xD2B48C);
	SetTrieValue(hTrie, "teal", 0x008080);
	SetTrieValue(hTrie, "thistle", 0xD8BFD8);
	SetTrieValue(hTrie, "tomato", 0xFF6347);
	SetTrieValue(hTrie, "turquoise", 0x40E0D0);
	SetTrieValue(hTrie, "uncommon", 0xB0C3D9); // same as Uncommon item rarity in Dota 2
	SetTrieValue(hTrie, "unique", 0xFFD700); // same as Unique item quality in TF2
	SetTrieValue(hTrie, "unusual", 0x8650AC); // same as Unusual item quality in TF2
	SetTrieValue(hTrie, "valve", 0xA50F79); // same as Valve item quality in TF2
	SetTrieValue(hTrie, "vintage", 0x476291); // same as Vintage item quality in TF2
	SetTrieValue(hTrie, "violet", 0xEE82EE);
	SetTrieValue(hTrie, "wheat", 0xF5DEB3);
	SetTrieValue(hTrie, "white", 0xFFFFFF);
	SetTrieValue(hTrie, "whitesmoke", 0xF5F5F5);
	SetTrieValue(hTrie, "yellow", 0xFFFF00);
	SetTrieValue(hTrie, "yellowgreen", 0x9ACD32);

	SetTrieValue(hTrie, "rblxwhite", 0xF2F3EE);
	SetTrieValue(hTrie, "rblxgrey", 0xA1A5A2);
	SetTrieValue(hTrie, "rblxgray", 0xA1A5A2);
	SetTrieValue(hTrie, "rblxlightyellow", 0xF9E999);
	SetTrieValue(hTrie, "rblxbrickyellow", 0xD7C59A);
	SetTrieValue(hTrie, "rblxlightgreenmint", 0xC2DAB8);
	SetTrieValue(hTrie, "rblxlightredviolet", 0xE8BAC8);
	SetTrieValue(hTrie, "rblxpastelblue", 0x80BBDB);
	SetTrieValue(hTrie, "rblxlightorangebrown", 0xCB8442);
	SetTrieValue(hTrie, "rblxnougat", 0xCC8E69);
	SetTrieValue(hTrie, "rblxbrightred", 0xC4281C);
	SetTrieValue(hTrie, "rblxmedredviolet", 0xC470A0);
	SetTrieValue(hTrie, "rblxbrightblue", 0x0C69AC);
	SetTrieValue(hTrie, "rblxbrightyellow", 0xF5CD30);
	SetTrieValue(hTrie, "rblxearthorange", 0x624732);
	SetTrieValue(hTrie, "rblxblack", 0x1B2A35);
	SetTrieValue(hTrie, "rblxdarkgrey", 0x6D6E6C);
	SetTrieValue(hTrie, "rblxdarkgrey", 0x6D6E6C);
	SetTrieValue(hTrie, "rblxdarkgreen", 0x287F47);
	SetTrieValue(hTrie, "rblxmedgreen", 0xA1C48C);
	SetTrieValue(hTrie, "rblxlightyellowishorange", 0xF3CF9B);
	SetTrieValue(hTrie, "rblxbrightgreen", 0x4B974B);
	SetTrieValue(hTrie, "rblxdarkorange", 0xA05F35);
	SetTrieValue(hTrie, "rblxlightbluishviolet", 0xC1CADE);
	SetTrieValue(hTrie, "rblxtrred", 0xCD544B);
	SetTrieValue(hTrie, "rblxtrlgblue", 0xC1DFF0);
	SetTrieValue(hTrie, "rblxtrblue", 0x7BB6E8);
	SetTrieValue(hTrie, "rblxtryellow", 0xF7F18D);
	SetTrieValue(hTrie, "rblxlightblue", 0xB4D2E4);
	SetTrieValue(hTrie, "rblxtrgreen", 0x84B68D);
	SetTrieValue(hTrie, "rblxposphwhite", 0xECE8DE);
	SetTrieValue(hTrie, "rblxlightred", 0xEEC4B6);
	SetTrieValue(hTrie, "rblxmediumred", 0xDA867A);
	SetTrieValue(hTrie, "rblxmediumblue", 0x6E99CA);
	SetTrieValue(hTrie, "rblxlightgrey", 0xC7C1B7);
	SetTrieValue(hTrie, "rblxbrightviolet", 0x6B327C);
	SetTrieValue(hTrie, "rblxbrightyellowishorange", 0xE29B40);
	SetTrieValue(hTrie, "rblxbrightorange", 0xDA8541);
	SetTrieValue(hTrie, "rblxbrightbluishgreen", 0x008F9C);
	SetTrieValue(hTrie, "rblxearthyellow", 0x685C43);
	SetTrieValue(hTrie, "rblxbrightbluishviolet", 0x435494);
	SetTrieValue(hTrie, "rblxmediumbluishviolet", 0x6874AC);
	SetTrieValue(hTrie, "rblxtrmedireddishviolet", 0xE5ADC8);
	SetTrieValue(hTrie, "rblxmedyellowishgreen", 0xC7D23C);
	SetTrieValue(hTrie, "rblxmedbluishgreen", 0x55A5AF);
	SetTrieValue(hTrie, "rblxlightbluishgreen", 0xB7D7D5);
	SetTrieValue(hTrie, "rblxbrightyellowishgreen", 0xA4BD47);
	SetTrieValue(hTrie, "rblxlightyellowishgreen", 0xD9E4A7);
	SetTrieValue(hTrie, "rblxmedyellowishorange", 0xE7AC58);
	SetTrieValue(hTrie, "rblxbrightreddishorange", 0xD36F4C);
	SetTrieValue(hTrie, "rblxbrightreddishviolet", 0x923978);
	SetTrieValue(hTrie, "rblxlightorange", 0xEAB892);
	SetTrieValue(hTrie, "rblxtrbrightbluishviolet", 0xA5A5CB);
	SetTrieValue(hTrie, "rblxgold", 0xDCBC81);
	SetTrieValue(hTrie, "rblxdarknougat", 0xAE7A59);
	SetTrieValue(hTrie, "rblxsilver", 0x9CA3A8);
	SetTrieValue(hTrie, "rblxneonorange", 0xD5733D);
	SetTrieValue(hTrie, "rblxsandblue", 0x74869D);
	SetTrieValue(hTrie, "rblxsandviolet", 0x877C90);
	SetTrieValue(hTrie, "rblxmediumorange", 0xE09864);
	SetTrieValue(hTrie, "rblxearthblue", 0x203A56);
	SetTrieValue(hTrie, "rblxearthgreen", 0x27462D);
	SetTrieValue(hTrie, "rblxsandgreen", 0x789082);
	SetTrieValue(hTrie, "rblxsandred", 0x957977);
	SetTrieValue(hTrie, "rblxdarkred", 0x7B2E2F);
	SetTrieValue(hTrie, "rblxgunmetallic", 0x756C62);
	SetTrieValue(hTrie, "rblxcurry", 0xD7A94B);
	SetTrieValue(hTrie, "rblxfireyellow", 0xF9D62E);
	SetTrieValue(hTrie, "rblxreddishbrown", 0x694028);
	SetTrieValue(hTrie, "rblxflameyellowishorange", 0xE8AB2D);
	SetTrieValue(hTrie, "rblxflamereddishorange", 0xCF6024);
	SetTrieValue(hTrie, "rblxmediumstonegrey", 0xA3A2A5);
	SetTrieValue(hTrie, "rblxmediumstonegray", 0xA3A2A5);
	SetTrieValue(hTrie, "rblxroyalblue", 0x4667A4);
	SetTrieValue(hTrie, "rblxdarkroyalblue", 0x23478B);
	SetTrieValue(hTrie, "rblxbrightreddishlilac", 0x8E4285);
	SetTrieValue(hTrie, "rblxdarkstonegrey", 0x635F62);
	SetTrieValue(hTrie, "rblxdarkstonegray", 0x635F62);
	SetTrieValue(hTrie, "rblxlightstonegrey", 0xE5E4DF);
	SetTrieValue(hTrie, "rblxlightstonegray", 0xE5E4DF);
	SetTrieValue(hTrie, "rblxdarkcurry", 0xB08E44);
	SetTrieValue(hTrie, "rblxfadedgreen", 0x709578);
	SetTrieValue(hTrie, "rblxturquoise", 0x79B5B5);
	SetTrieValue(hTrie, "rblxlightroyalblue", 0x9FC3E9);
	SetTrieValue(hTrie, "rblxmediumroyalblue", 0x6C81B7);
	SetTrieValue(hTrie, "rblxrust", 0x904C2A);
	SetTrieValue(hTrie, "rblxbrown", 0x7C5C46);
	SetTrieValue(hTrie, "rblxreddishlilac", 0x96709F);
	SetTrieValue(hTrie, "rblxlilac", 0x6B629B);
	SetTrieValue(hTrie, "rblxlightlilac", 0xA7A9CE);
	SetTrieValue(hTrie, "rblxbrightpurple", 0xCD6298);
	SetTrieValue(hTrie, "rblxlightpurple", 0xE4ADC8);
	SetTrieValue(hTrie, "rblxlightpink", 0xDC9095);
	SetTrieValue(hTrie, "rblxlightbrickyellow", 0xF0D5A0);
	SetTrieValue(hTrie, "rblxwarmyellowishorange", 0xEBB87F);
	SetTrieValue(hTrie, "rblxcoolyellow", 0xFDEA8D);
	SetTrieValue(hTrie, "rblxdoveblue", 0x7DBBDD);
	SetTrieValue(hTrie, "rblxmediumlilac", 0x342B75);
	SetTrieValue(hTrie, "rblxslimegreen", 0x506D54);
	SetTrieValue(hTrie, "rblxsmokygrey", 0x5B5D69);
	SetTrieValue(hTrie, "rblxsmokygray", 0x5B5D69);
	SetTrieValue(hTrie, "rblxdarkblue", 0x0010B0);
	SetTrieValue(hTrie, "rblxparsleygreen", 0x2C651D);
	SetTrieValue(hTrie, "rblxsteelblue", 0x527CAE);
	SetTrieValue(hTrie, "rblxstormblue", 0x335882);
	SetTrieValue(hTrie, "rblxlapis", 0x102ADC);
	SetTrieValue(hTrie, "rblxdarkindigo", 0x3D1585);
	SetTrieValue(hTrie, "rblxseagreen", 0x348E40);
	SetTrieValue(hTrie, "rblxshamrock", 0x5B9A4C);
	SetTrieValue(hTrie, "rblxfossil", 0x9FA1AC);
	SetTrieValue(hTrie, "rblxmulberry", 0x592259);
	SetTrieValue(hTrie, "rblxforestgreen", 0x1F801D);
	SetTrieValue(hTrie, "rblxcadetblue", 0x9FADC0);
	SetTrieValue(hTrie, "rblxelectricblue", 0x0989CF);
	SetTrieValue(hTrie, "rblxeggplant", 0x7B007B);
	SetTrieValue(hTrie, "rblxmoss", 0x7C9C6B);
	SetTrieValue(hTrie, "rblxartichoke", 0x8AAB85);
	SetTrieValue(hTrie, "rblxsagegreen", 0xB9C4B1);
	SetTrieValue(hTrie, "rblxghostgrey", 0xCACBD1);
	SetTrieValue(hTrie, "rblxghostgray", 0xCACBD1);
	SetTrieValue(hTrie, "rblxtrlilac", 0xA75E9B);
	SetTrieValue(hTrie, "rblxplum", 0x7B2F7B);
	SetTrieValue(hTrie, "rblxolivine", 0x94BE81);
	SetTrieValue(hTrie, "rblxlaurelgreen", 0xA8BD99);
	SetTrieValue(hTrie, "rblxquillgrey", 0xDFDFDE);
	SetTrieValue(hTrie, "rblxquillgray", 0xDFDFDE);
	SetTrieValue(hTrie, "rblxcrimson", 0x970000);
	SetTrieValue(hTrie, "rblxmint", 0xB1E5A6);
	SetTrieValue(hTrie, "rblxbabyblue", 0x98C2DB);
	SetTrieValue(hTrie, "rblxcarnationpink", 0xFF98DC);
	SetTrieValue(hTrie, "rblxpersimmon", 0xFF5959);
	SetTrieValue(hTrie, "rblxmaroon", 0x750000);
	SetTrieValue(hTrie, "rblxgold", 0xEFB838);
	SetTrieValue(hTrie, "rblxdaisyorange", 0xF8D96D);
	SetTrieValue(hTrie, "rblxpearl", 0xE7E7EC);
	SetTrieValue(hTrie, "rblxfog", 0xC7D4E4);
	SetTrieValue(hTrie, "rblxsalmon", 0xFF9494);
	SetTrieValue(hTrie, "rblxterracotta", 0xBE6862);
	SetTrieValue(hTrie, "rblxcocoa", 0x562424);
	SetTrieValue(hTrie, "rblxwheat", 0xF1E7C7);
	SetTrieValue(hTrie, "rblxbuttermilk", 0xFEF3BB);
	SetTrieValue(hTrie, "rblxmauve", 0xE0B2D0);
	SetTrieValue(hTrie, "rblxsunrise", 0xD490BD);
	SetTrieValue(hTrie, "rblxtawny", 0x965555);
	SetTrieValue(hTrie, "rblxcashmere", 0xD3BE96);
	SetTrieValue(hTrie, "rblxkhaki", 0xE2DCBC);
	SetTrieValue(hTrie, "rblxlilywhite", 0xEDEAEA);
	SetTrieValue(hTrie, "rblxseashell", 0xE9DADA);
	SetTrieValue(hTrie, "rblxburgundy", 0x883E3E);
	SetTrieValue(hTrie, "rblxcork", 0xBC9B5D);
	SetTrieValue(hTrie, "rblxburlap", 0xC7AC78);
	SetTrieValue(hTrie, "rblxbeige", 0xCABFA3);
	SetTrieValue(hTrie, "rblxoyster", 0xBBB3B2);
	SetTrieValue(hTrie, "rblxpinecone", 0x6C584B);
	SetTrieValue(hTrie, "rblxfawnbrown", 0xA0844F);
	SetTrieValue(hTrie, "rblxhurricanegrey", 0x958988);
	SetTrieValue(hTrie, "rblxhurricanegray", 0x958988);
	SetTrieValue(hTrie, "rblxcloudygrey", 0xABA89E);
	SetTrieValue(hTrie, "rblxcloudygray", 0xABA89E);
	SetTrieValue(hTrie, "rblxlinen", 0xAF9483);
	SetTrieValue(hTrie, "rblxcopper", 0x966766);
	SetTrieValue(hTrie, "rblxdirtbrown", 0x564236);
	SetTrieValue(hTrie, "rblxbronze", 0x7E683F);
	SetTrieValue(hTrie, "rblxflint", 0x69665C);
	SetTrieValue(hTrie, "rblxdarktaupe", 0x5A4C42);
	SetTrieValue(hTrie, "rblxburntsienna", 0x6A3909);
	SetTrieValue(hTrie, "rblxinstitutionalwhite", 0xF8F8F8);
	SetTrieValue(hTrie, "rblxmidgrey", 0xCDCDCD);
	SetTrieValue(hTrie, "rblxmidgray", 0xCDCDCD);
	SetTrieValue(hTrie, "rblxreallyblack", 0x111111);
	SetTrieValue(hTrie, "rblxreallyred", 0xFF0000);
	SetTrieValue(hTrie, "rblxdeeporange", 0xFFB000);
	SetTrieValue(hTrie, "rblxalder", 0xB480FF);
	SetTrieValue(hTrie, "rblxdustyrose", 0xA34B4B);
	SetTrieValue(hTrie, "rblxolive", 0xC1BE42);
	SetTrieValue(hTrie, "rblxnewyeller", 0xFFFF00);
	SetTrieValue(hTrie, "rblxreallyblue", 0x0000FF);
	SetTrieValue(hTrie, "rblxnavyblue", 0x002060);
	SetTrieValue(hTrie, "rblxdeepblue", 0x2154B9);
	SetTrieValue(hTrie, "rblxcyan", 0x04AFEC);
	SetTrieValue(hTrie, "rblxcgabrown", 0xAA5500);
	SetTrieValue(hTrie, "rblxmagenta", 0xAA00AA);
	SetTrieValue(hTrie, "rblxpink", 0xFF66CC);
	SetTrieValue(hTrie, "rblxdeeporange", 0xFF66CC);
	SetTrieValue(hTrie, "rblxteal", 0x12EED4);
	SetTrieValue(hTrie, "rblxtoothpaste", 0x00FFFF);
	SetTrieValue(hTrie, "rblxlimegreen", 0x00FF00);
	SetTrieValue(hTrie, "rblxcamo", 0x3A7D15);
	SetTrieValue(hTrie, "rblxgrime", 0x7F8E64);
	SetTrieValue(hTrie, "rblxlavender", 0x8C5B9F);
	SetTrieValue(hTrie, "rblxpastellightblue", 0xAFDDFF);
	SetTrieValue(hTrie, "rblxpastelorange", 0xFFC9C9);
	SetTrieValue(hTrie, "rblxpastelviolet", 0xB1A7FF);
	SetTrieValue(hTrie, "rblxpastelbluegreen", 0x9FF3E9);
	SetTrieValue(hTrie, "rblxpastelgreen", 0xCCFFCC);
	SetTrieValue(hTrie, "rblxpastelyellow", 0xFFFFCC);
	SetTrieValue(hTrie, "rblxpastelbrown", 0xFFCC99);
	SetTrieValue(hTrie, "rblxroyalpurple", 0x6225D1);
	SetTrieValue(hTrie, "rblxhotpink", 0xFF00BF);

	return hTrie;
}