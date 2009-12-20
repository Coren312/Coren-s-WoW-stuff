
-----------------------------------------
-- Chat functions
-----------------------------------------

local	KarmaObj = KarmaAvEnK;

KarmaObj.UIChat = {};

local	KARMA_ChatWindowDefault = nil;			-- necessary messages
local	KARMA_ChatWindowSecondary = nil;		-- extensive messages
local	KARMA_ChatWindowDebug = nil;			-- debug messages
local	KARMA_ChatWindowKarma = nil;				-- Karma-only window for extreme spamming liek wtf!

local	KARMA_INDENT = 0;

-----------------------------------------
-- Primary output functions
-----------------------------------------

function	KarmaChatDefault(text, noprefix)
	if (KARMA_ChatWindowDefault) then
		if (noprefix) then
			KARMA_ChatWindowDefault:AddMessage(text, .8, .8, .2);
		else
			KARMA_ChatWindowDefault:AddMessage(KARMA_TITLE .. KARMA_WINEL_FRAG_COLONSPACE .. text, .8, .8, .2);
		end
	end
end

function	KarmaChatSecondary(text, noprefix)
	if (KARMA_ChatWindowSecondary) then
		if (noprefix) then
			KARMA_ChatWindowSecondary:AddMessage(text, .8, .8, .2);
		else
			KARMA_ChatWindowSecondary:AddMessage(KARMA_TITLE .. KARMA_WINEL_FRAG_COLONSPACE .. text, .8, .8, .2);
		end
	end
end

function	KarmaChatSecondaryFallbackDefault(text, noprefix)
	if (KARMA_ChatWindowSecondary) then
		if (noprefix) then
			KARMA_ChatWindowSecondary:AddMessage(text, .8, .8, .2);
		else
			KARMA_ChatWindowSecondary:AddMessage(KARMA_TITLE .. KARMA_WINEL_FRAG_COLONSPACE .. text, .8, .8, .2);
		end
	else
		KarmaChatDefault(text, noprefix);
	end
end

local	DebugIndex = 0;
local	DebugTimestamps = {};
local	DebugMessages = {};
local	DebugStore = function(sLine)
		DebugIndex = DebugIndex + 1;
		if (DebugIndex == 20000) then
			DebugIndex = 1;
		end

		DebugTimestamps[DebugIndex] = time();
		DebugMessages[DebugIndex] = sLine;
	end

function	KarmaDebugSearch(arg1, arg2)
	if (KARMA_ChatWindowDebug) then
		if (type(arg1) == "number") then
			local	iFrom, iCount = arg1, 25;
			if (type(arg2) == "number") then
				iCount = arg2;
			end
			KARMA_ChatWindowDebug:AddMessage("Reprinting lines " .. iFrom .. " to " .. (iFrom + iCount) .. "...", .8, .8, .2);

			local	i, iAbs;
			for iAbs = iFrom, iFrom + iCount do
				i = iAbs ;
				if (i >= 20000) then
					i = i - 20000;
				end
				if (DebugMessages[i]) then
					local	sAt = date("%H:%M:%S ", DebugTimestamps[i]);
					KARMA_ChatWindowDebug:AddMessage(sAt .. DebugMessages[i], .8, .8, .2);
				end
			end
		elseif (type(arg1) == "string") then
			local	sPattern = arg1;
			KARMA_ChatWindowDebug:AddMessage("Checking for " .. sPattern .. " in " .. DebugIndex .. " lines...", .8, .8, .2);

			local	iFound, iAbs, i = 0;
			for iAbs = 1, 19999 do
				i = DebugIndex + iAbs;
				if (i >= 20000) then
					i = i - 20000;
				end
				if (DebugMessages[i]) then
					if (strfind(DebugMessages[i], sPattern)) then
						if (iAbs - iFound > 5) then
							local	j, k;
							for j = 1, 4 do
								k = DebugIndex + iAbs - 5 + j
								if (k >= 20000) then
									k = k - 20000;
								end
								if (DebugMessages[k]) then
									local	sAt = date("%H:%M:%S ", DebugTimestamps[k]);
									KARMA_ChatWindowDebug:AddMessage(sAt .. DebugMessages[k], .8, .8, .2);
								end
							end
						end
						iFound = iAbs;
					end

					if (iFound + 5 >= iAbs) then
						local	sAt = date("%H:%M:%S ", DebugTimestamps[i]);
						KARMA_ChatWindowDebug:AddMessage(sAt .. DebugMessages[i], .8, .8, .2);
					end
				end
			end
		end
	end
end

function	KarmaChatDebug(text, noprefix)
	DebugStore(text);
	if (KARMA_ChatWindowDebug) then
		if (noprefix) then
			KARMA_ChatWindowDebug:AddMessage(text, .8, .8, .2);
		else
			KARMA_ChatWindowDebug:AddMessage(KARMA_TITLE .. "-DBG: " .. text, .8, .8, .2);
		end
	end
end

function	KarmaChatDebugFallbackSecondary(text, noprefix)
	DebugStore(text);
	if (KARMA_ChatWindowDebug) then
		if (noprefix) then
			KARMA_ChatWindowDebug:AddMessage(text, .8, .8, .2);
		else
			KARMA_ChatWindowDebug:AddMessage(KARMA_TITLE .. KARMA_WINEL_FRAG_COLONSPACE .. text, .8, .8, .2);
		end
	else
		KarmaChatSecondary(text, noprefix);
	end
end


-----------------------------------------
-- Secondary output functions (Debug stuff)
-----------------------------------------

function	KarmaChatKarma(text)
	if (KARMA_ChatWindowKarma == nil) then
		return;
	end
	local	iCounter = KARMA_INDENT;
	indenttext = ""
	while (iCounter > 0) do
		indenttext = indenttext.." "
		iCounter = iCounter-1
	end
	KARMA_ChatWindowKarma:AddMessage(indenttext.." == = "..text);
end

function	KarmaObj.ProfileStart(funcname)
	if (KARMA_ChatWindowKarma == nil) then
		return;
	end
	local	iCounter = KARMA_INDENT;
	indenttext = ""
	while (iCounter > 0) do
		indenttext = indenttext.." "
		iCounter = iCounter-1
	end
	KARMA_ChatWindowKarma:AddMessage(indenttext..">>> "..funcname);
	KARMA_INDENT = KARMA_INDENT+1;
end

function	KarmaObj.ProfileStop(funcname)
	if (KARMA_ChatWindowKarma == nil) then
		return;
	end
	indenttext = ""
	KARMA_INDENT = KARMA_INDENT-1;
	if (KARMA_INDENT <0 or KARMA_INDENT  >= 20) then
		KARMA_INDENT = 0;
	end
	local	iCounter = KARMA_INDENT;
	while (iCounter > 0) do
		indenttext = indenttext.." "
		iCounter = iCounter-1
	end
	KARMA_ChatWindowKarma:AddMessage(indenttext.."<<< "..funcname);
end

function	Karma_SetupDebug()
	-- Search for the Profiler's Chat Frame, the tab of the window must be named... "Karma"
	KARMA_ChatWindowDefault = DEFAULT_CHAT_FRAME;
	KARMA_ChatWindowSecondary = nil;
	KARMA_ChatWindowDebug = nil;

	KARMA_INDENT = 0;

	local	i;
	for i = 1, NUM_CHAT_WINDOWS do
		local	chatFrame = getglobal("ChatFrame"..i);
		if (chatFrame) then
			local	temp, shown;
			temp, temp, temp, temp, temp, temp, shown, temp = GetChatWindowInfo(i);
			if (shown or chatFrame.isDocked) then
				local	tab = getglobal(chatFrame:GetName().."Tab");
				local	sName = tab:GetText();
				if (sName == "Karma") then
					KARMA_ChatWindowKarma = chatFrame;
					KarmaChatDefault("Yay! Found debug frame" .. KARMA_WINEL_FRAG_TRIDOTS);
				end
			end
		end
	end
end


-----------------------------------------
-- Configuration functions
-----------------------------------------

-- CONFIG FIELDS (all local)
local	KARMA_CONFIG = {
			CHAT_DEFAULT = "CHAT_DEFAULT",
			CHAT_SECONDARY = "CHAT_SECONDARY",
			CHAT_DEBUG = "CHAT_DEBUG"
			-- == last entry no ",", add to previous == --
		};

--
function	KarmaObj.UIChat.DefaultSet(newFrame)
	KARMA_ChatWindowDefault = newFrame;
end

function	KarmaObj.UIChat.SecondarySet(newFrame)
	KARMA_ChatWindowSecondary = newFrame;
end

function	KarmaObj.UIChat.DebugSet(newFrame)
	KARMA_ChatWindowDebug = newFrame;
end

function	KarmaObj.UIChat.SecondaryNotNil()
	return (KARMA_ChatWindowSecondary ~= nil);
end

function	KarmaObj.UIChat.SecondaryNameGet()
	if (KARMA_ChatWindowSecondary) then
		local	tab = getglobal(KARMA_ChatWindowSecondary:GetName().."Tab");
		return tab:GetText();
	else
		return nil;
	end
end

function	KarmaObj.UIChat.DebugNameGet()
	if (KARMA_ChatWindowDebug) then
		local	tab = getglobal(KARMA_ChatWindowDebug:GetName().."Tab");
		return tab:GetText();
	else
		return nil;
	end
end


function	Karma_SetupChatWindows(silent)
	KARMA_ChatWindowSecondary = nil;
	KARMA_ChatWindowDebug = nil;

	local	ChatWindowDefault_Name = Karma_GetConfigPerChar(KARMA_CONFIG.CHAT_DEFAULT);
	if (ChatWindowDefault_Name == "") then
		ChatWindowDefault_Name = nil;
	end
	local	ChatWindowSecondary_Name = Karma_GetConfigPerChar(KARMA_CONFIG.CHAT_SECONDARY);
	if (ChatWindowSecondary_Name == "") then
		ChatWindowSecondary_Name = nil;
	end
	local	ChatWindowDebug_Name = Karma_GetConfigPerChar(KARMA_CONFIG.CHAT_DEBUG);
	if (ChatWindowDebug_Name == "") then
		ChatWindowDebug_Name = nil;
	end

	local	SecondaryWindow;
	local	VisibleChatWindowCount = 0;
	local	MsgGotcha = "";

	local	i;
	for i = 1, NUM_CHAT_WINDOWS do
		local	chatFrame = getglobal("ChatFrame"..i);
		if (chatFrame) then
			local	temp, shown;
			temp, temp, temp, temp, temp, temp, shown, temp = GetChatWindowInfo(i);
			if (shown or chatFrame.isDocked) then
				VisibleChatWindowCount = VisibleChatWindowCount + 1;
				SecondaryWindow = i;

				local	tab = getglobal(chatFrame:GetName().."Tab");
				local	sName = tab:GetText();
				if (ChatWindowDefault_Name ~= nil) then
					if (sName == ChatWindowDefault_Name) then
						KARMA_ChatWindowDefault = chatFrame;
						-- MsgGotcha .. " (default msgs -> " .. sName .. ")";
						MsgGotcha = MsgGotcha .. KARMA_MSG_CHATSETUP_1 .. KARMA_MSG_CHATSETUP_2_DEFAULT
									.. KARMA_MSG_CHATSETUP_3 .. sName .. KARMA_MSG_CHATSETUP_4;
					end
				end
				if (ChatWindowSecondary_Name ~= nil) then
					if (sName == ChatWindowSecondary_Name) then
						KARMA_ChatWindowSecondary = chatFrame;
						-- MsgGotcha .. " (extra msgs -> " .. sName .. ")";
						MsgGotcha = MsgGotcha .. KARMA_MSG_CHATSETUP_1 .. KARMA_MSG_CHATSETUP_2_EXTRA
									.. KARMA_MSG_CHATSETUP_3 .. sName .. KARMA_MSG_CHATSETUP_4;
					end
				end
				if (ChatWindowDebug_Name ~= nil) then
					if (sName == ChatWindowDebug_Name) then
						KARMA_ChatWindowDebug = chatFrame;
						-- MsgGotcha .. " (DEBUG msgs -> " .. sName .. ")";
						MsgGotcha = MsgGotcha .. KARMA_MSG_CHATSETUP_1 .. KARMA_MSG_CHATSETUP_2_DEBUG
									.. KARMA_MSG_CHATSETUP_3 .. sName .. KARMA_MSG_CHATSETUP_4;
					end
				end
			end
		end
	end

	if (KARMA_ChatWindowSecondary == nil) and (VisibleChatWindowCount == 2) then
		local	chatFrame = getglobal("ChatFrame" .. SecondaryWindow);
		if (chatFrame) then
			local	tab = getglobal(chatFrame:GetName().."Tab");
			local	sName = tab:GetText();
			KARMA_ChatWindowSecondary = chatFrame;
			-- MsgGotcha .. " ([autoassigned] extra msgs -> " .. sName .. ")";
			MsgGotcha = MsgGotcha .. KARMA_MSG_CHATSETUP_1 .. KARMA_MSG_CHATSETUP_AUTO
						.. KARMA_MSG_CHATSETUP_2_EXTRA .. KARMA_MSG_CHATSETUP_3 .. sName
						.. KARMA_MSG_CHATSETUP_4;
		end
	end

	if (MsgGotcha ~= "") and (silent == nil) then
		local	MsgFull = KARMA_MSG_CHATSETUP_DONE .. KARMA_WINEL_FRAG_TRIDOTS .. MsgGotcha;
		if (KARMA_ChatWindowSecondary) then
			KarmaChatSecondary(MsgFull);
		else
			KarmaChatDefault(MsgFull);
		end
	end
end

