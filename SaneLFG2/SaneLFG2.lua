
-- master object ~

BINDING_HEADER_SANELFG2 = "SaneLFG2";
BINDING_NAME_SANELFG2_MAINWND = "Open/Close main SaneLFG2 window";
do
	local	sLocale = GetLocale();
	if (SaneLFG2Locales[sLocale]) then
		BINDING_NAME_SANELFG2_MAINWND = SaneLFG2Locales[sLocale].UI.BindingMainWndToggle;
	end
end

SaneLFG2Global = { ServerLocale = {}, LFGPerChar = {}, ParsedChannel = {}, Config = {} };
SaneLFG2PerChar = {};

local	CHATFRAME = ChatFrame2;

local	oEventframe = CreateFrame("Frame", nil, UIParent);

oEventframe:RegisterEvent("ADDON_LOADED");

oEventframe:RegisterEvent("PLAYER_LOGIN");
oEventframe:RegisterEvent("PLAYER_ENTERING_WORLD");
oEventframe:RegisterEvent("PLAYER_LEAVING_WORLD");

-- oEventframe:RegisterEvent("PARTY_LEADER_CHANGED");
oEventframe:RegisterEvent("PARTY_MEMBERS_CHANGED");

oEventframe:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");
oEventframe:RegisterEvent("CHAT_MSG_CHANNEL");
oEventframe:RegisterEvent("CHAT_MSG_ADDON");

function	SaneLFGObj2.OnEvent(oFrame, sEvent, ...)
	if (sEvent == "ADDON_LOADED") then
		local	sWhich = ...;
		if (sWhich == "SaneLFG2") then
			SaneLFGObj2.Realm = GetCVar("realmName");
			SaneLFGObj2.FactionRealm = UnitFactionGroup("player") .. "#" .. SaneLFGObj2.Realm;
			SaneLFGObj2.WhoAmI = UnitName("player");
			local	GUID = UnitGUID("player");

			if (SaneLFG2Global[SaneLFGObj2.FactionRealm] == nil) then
				SaneLFG2Global[SaneLFGObj2.FactionRealm] = {};
			end
			SaneLFGObj2.FactionRealm = SaneLFG2Global[SaneLFGObj2.FactionRealm];

			if (SaneLFGObj2.FactionRealm.ParsedChannel == nil) then
				SaneLFGObj2.FactionRealm.ParsedChannel = {};
			end
			if (SaneLFGObj2.FactionRealm.LFGPerChar == nil) then
				SaneLFGObj2.FactionRealm.LFGPerChar = {};
			end

			local	LFGPerRealm = SaneLFGObj2.FactionRealm.LFGPerChar;
			if (LFGPerRealm[SaneLFGObj2.WhoAmI] == nil) then
				LFGPerRealm[SaneLFGObj2.WhoAmI] = { GUID = GUID };
			elseif (GUID ~= LFGPerRealm[SaneLFGObj2.WhoAmI].GUID) then
				LFGPerRealm[SaneLFGObj2.WhoAmI] = { GUID = GUID };
			end

			local	sVersionNumber = GetAddOnMetadata("SaneLFG", "Version");
			if (sVersionNumber == nil) then
				sVersionNumber = "???";
			end
			SaneLFGObj2.State.sVersionNumber = sVersionNumber;

			local	sVersionDate = GetAddOnMetadata("SaneLFG", "X-Date");
			if (sVersionDate == nil) then
				sVersionDate = "???";
			end
			SaneLFGObj2.State.sVersionDate = sVersionDate;

			local	sClientLocale = GetLocale();
			if (SaneLFG2Locales[sClientLocale]) then
				SaneLFGObj2.State.ServerLocale = sClientLocale;
				SaneLFG2Locales.Current = SaneLFG2Locales[sClientLocale];
			end

			local	sLocale = SaneLFG2Global.ServerLocale[SaneLFGObj2.Realm];
			if (sLocale) then
				if (SaneLFG2Locales[sLocale]) then
					SaneLFGObj2.State.ServerLocale = sLocale;
					SaneLFG2Locales.Current = SaneLFG2Locales[sLocale];
					if (SaneLFG2Locales[sClientLocale]) then
						SaneLFGObj2.State.ClientLocale = sClientLocale;
						SaneLFG2Locales.Current.UI = SaneLFG2Locales[sClientLocale].UI;
					end
				end
			end

			local	sArea, fFunc;
			for sArea, fFunc in pairs(SaneLFGObj2.Init) do
				fFunc();
			end

			local	oParsedChannel = SaneLFGObj2.FactionRealm.ParsedChannel;

			local	iNow = time();
			if (next(oParsedChannel)) then
				local	oRemove = {};
				for k, v in pairs(oParsedChannel) do
					-- development: changed data fixups >>
					v.sRaw1 = v.sRaw;
					if (v.iUpdatedAt == nil) then
						v.iUpdatedAt = v.iAt;
					end
					if (v.oData.sChannel == nil) then
						v.oData.sChannel = "Old";
					end
					-- <<

					v.iAt = v.iUpdatedAt;
					if (v.iAt < iNow - 1200) then
						tinsert(oRemove, k);
					end
				end

				for k, v in pairs(oRemove) do
					oParsedChannel[v] = nil;
				end

				local	oSort = {};
				for k, v in pairs(oParsedChannel) do
					tinsert(oSort, { sName = k, iTime = v.iAt });
				end

				for k = 1, #oSort - 1 do
					for v = k + 1, #oSort do
						if (oSort[k].iTime > oSort[v].iTime) then
							local	x = oSort[k];
							oSort[k] = oSort[v];
							oSort[v] = x;
						end
					end
				end

				for k = 1, #oSort do
					v =  oParsedChannel[oSort[k].sName];
					-- while still in beta: force update on renewal by modifing string slightly
					v.oData.sRaw1 = "#" .. v.oData.sRaw1 .. "#";
					SaneLFGObj2.MainWndButtonSetup(v.oFrom, v.oData, v.iAt);
				end

				SaneLFGObj2.ParsedSortAll = oSort;
			end

			SLASH_SANELFG_V2_X1 = "/sanelfg2";
			SLASH_SANELFG_V2_X2 = "/slfg2";
			SlashCmdList["SANELFG_V2_X"] = SaneLFGObj2.CommandHandler;

			oEventframe:SetScript("OnUpdate", SaneLFGObj2.OnUpdate);
		end	-- if (sWhich == SaneLFG2) then ...

		return
	end	-- if (sEvent == "ADDON_LOADED") then ...

	-- join/leave channel
	if (sEvent == "CHAT_MSG_CHANNEL_NOTICE") then
		local	arg1, _2, _3, arg4, _5, _6, arg7, arg8, arg9 = ...;
		-- arg1:
		-- - YOU_JOINED (real join or re-join after SUSPENDED)
		-- - YOU_LEFT
		-- - YOU_CHANGED (General - Darnassus => General - Teldrassil)
		-- - SUSPENDED (#Trade, #LFGuild city -> outside)
		-- arg7: type (0 = custom, 1..n = Blizzard official channel)
		-- arg8: channel #
		-- arg9: channel name

		--if (arg7 and (arg7 ~= 0)) then
		--	ChatFrame4:AddMessage("SLFG2DBG: Channel change for official channel [" .. arg8 .. ". " .. arg9 .. "]{code " .. arg7 .. "}: " .. arg1);
		--end

		if (arg7 == 26) then	-- LFG channel
			if (arg1 == "YOU_JOINED") then
				SaneLFGObj2.LFGChannelNum = arg8;
				SaneLFGObj2.LFGChannelName = arg9;
				SaneLFGObj2.CheckMirrors(true);
			elseif ((arg1 == "SUSPENDED") or (arg1 == "YOU_LEFT")) then
				SaneLFGObj2.LFGChannelNum = nil;
				SaneLFGObj2.LFGChannelName = nil;
				SaneLFGObj2.CheckMirrors(false);
			end
		end

		if ((arg7 == 0) and (strupper(strsub(arg9, 1, strlen(SaneLFGObj2.sLFGBase)) or "") == SaneLFGObj2.sLFGBase)) then
			if (arg1 == "YOU_JOINED") then
				SaneLFGObj2.ValidateMirror(arg8, arg9, true);
			elseif (arg1 == "YOU_LEFT") then
				SaneLFGObj2.ValidateMirror(arg8, arg9, false);
			end
		end
	end

	-- channel messages
	if (sEvent == "CHAT_MSG_CHANNEL") then
		SaneLFGObj2.ChannelMessage(...);
	end
	-- indirect messages
	if (sEvent == "CHAT_MSG_ADDON") then
		SaneLFGObj2.AddonMessage(...);
	end

	-- party change
	if (sEvent == "PARTY_MEMBERS_CHANGED") then
		SaneLFGObj2.Announce.GroupChange = 10;
	end

	if ((SaneLFGObj2.bInit == nil) and (sEvent == "PLAYER_ENTERING_WORLD")) then
		local	LFGPerRealm = SaneLFGObj2.FactionRealm.LFGPerChar;
		local	LFGRealmPlayer = LFGPerRealm[SaneLFGObj2.WhoAmI];
		local	_, sClassEN = UnitClass("player");
		if (sClassEN) then
			LFGRealmPlayer.sClassEN = sClassEN;
		end
		local _, bTank, bHeal, bDPS = GetLFGRoles();
		LFGRealmPlayer.oRoles = { bTank = bTank == true, bHeal = bHeal == true, bDPS = bDPS == true };
		LFGRealmPlayer.iLevel = UnitLevel("player") + UnitXP("player") / UnitXPMax("player");

		CHATFRAME:AddMessage("SaneLFG2 loaded. Use /sanelfg2 for commands.");

		local	sLocaleStatus = "SaneLFG2: Using locale \"";
		if (SaneLFGObj2.State.ServerLocale) then
			sLocaleStatus = sLocaleStatus .. SaneLFGObj2.State.ServerLocale;
		else
			sLocaleStatus = sLocaleStatus .. "enUS";
		end
		sLocaleStatus = sLocaleStatus .. "\" to parse channels.";
		if (SaneLFGObj2.State.ClientLocale) then
			sLocaleStatus = sLocaleStatus .. " Client locale used for display is \"" .. SaneLFGObj2.State.ClientLocale .. "\".";
		end
		CHATFRAME:AddMessage(sLocaleStatus);

		SaneLFGObj2.bInit = 1;
		SaneLFGObj2.iInitDelay = 20;

		SaneLFGObj2.AnnounceInit();
	end
	if ((SaneLFGObj2.bInit == 2) and (sEvent == "_INIT")) then
		CHATFRAME:AddMessage("SaneLFG: Checking for channel #LFG (or alternatives)...");
		SaneLFGObj2.CheckChannels();
	end
end

oEventframe:SetScript("OnEvent", SaneLFGObj2.OnEvent);

function	SaneLFGObj2.OnUpdate(oFrame, iElapsed)
	if (SaneLFGObj2.iInitDelay) then
		SaneLFGObj2.iInitDelay = SaneLFGObj2.iInitDelay - iElapsed;
		if (SaneLFGObj2.iInitDelay < 0) then
			SaneLFGObj2.bInit = 2;
			SaneLFGObj2.iInitDelay = nil;
			SaneLFGObj2.OnEvent(oFrame, "_INIT");
		end
	end

	if (SaneLFGObj2.SliderUpdate) then
		SaneLFGObj2.SliderUpdate = SaneLFGObj2.SliderUpdate - iElapsed;
		if (SaneLFGObj2.SliderUpdate < 0) then
			SaneLFGObj2.MainWndButtonUpdateTimers();
		end
	end

	if (SaneLFGObj2.Announce.SelfIn) then
		SaneLFGObj2.Announce.SelfIn = SaneLFGObj2.Announce.SelfIn - iElapsed;
		if (SaneLFGObj2.Announce.SelfIn < 0) then
			SaneLFGObj2.AnnounceUpdate();
		end
	end

	if (SaneLFGObj2.Announce.Other) then
		SaneLFGObj2.Announce.Other = SaneLFGObj2.Announce.Other - iElapsed;
		if (SaneLFGObj2.Announce.Other < 0) then
			SaneLFGObj2.AnnounceUpdate();
		end
	end

	if (SaneLFGObj2.Announce.GroupChange) then
		SaneLFGObj2.Announce.GroupChange = SaneLFGObj2.Announce.GroupChange - iElapsed;
		if (SaneLFGObj2.Announce.GroupChange < 0) then
			SaneLFGObj2.PostGroupChange();
		end
	end

	if (SaneLFGObj2.Repeater) then
		SaneLFGObj2.Repeater = SaneLFGObj2.Repeater - iElapsed;
		if (SaneLFGObj2.Repeater < 0) then
			SaneLFGObj2.Repeater = nil;
			SaneLFGObj2.RepeatDo();
		end
	end
end

function	SaneLFGObj2.CommandHandler(...)
	local	arg1 = ...;
	if (strsub(arg1, 1, 5) == "chat ") then
		local	sFrom, sTo, sMsg = string.match(arg1, "chat as ([^%s]+) with ([^%s]+) (.+)");
		if (sFrom and sTo) then
			local	sClassEN;
			if (SaneLFGObj2.FactionRealm.LFGPerChar[sFrom]) then
				sClassEN = SaneLFGObj2.FactionRealm.LFGPerChar[sFrom];
			end
			if (sClassEN) then
				local	sRelay = SaneLFGObj2.Maps.NameToContact[sTo];
				if (sRelay) then
					ChatThrottleLib:SendAddOnMessage("NORMAL", "SaneLFG2", "R" .. sFrom ..":" .. sClassEN .. "!" .. sTo .. "!" .. sMsg, "WHISPER", sRelay);
					CHATFRAME:AddMessage("SaneLFG2: <" .. sFrom .. "> => {" .. sTo .. "} : " .. sMsg);
				else
					ChatThrottleLib:SendAddOnMessage("NORMAL", "SaneLFG2", "R" .. sFrom ..":" .. sClassEN .. "!" .. sTo .. "!" .. sMsg, "WHISPER", sTo);
					CHATFRAME:AddMessage("SaneLFG2: <" .. sFrom .. "> => [" .. sTo .. "] : " .. sMsg);
				end

				local	iCnt, i, iFound = #SaneLFGObj2.Maps.CommData;
				for i = 1, iCnt do
					local	oComm = SaneLFGObj2.Maps.CommData[i];
					if ((oComm.sFrom == sFrom) and (oComm.sTo == sTo) and (oComm.sRelay == sRelay)) then
						iFound = i;
						break;
					end
				end

				if (not iFound) then
					SaneLFGObj2.Maps.CommData[iCnt + 1] = { sFrom = sFrom, sClassEN = sClassEN, sTo = sTo, sRelay = sRelay };
					CHATFRAME:AddMessage("SaneLFG2: QuickID for this conversation is " .. i .. ".");
				end

				return
			else
				CHATFRAME:AddMessage("SaneLFG2: Failed to find information about " .. sFrom .. ".");
			end
		end

		sTo, sMsg = string.match(arg1, "chat with ([^%s]+) (.+)");
		if (sTo) then
			local	sRelay = SaneLFGObj2.Maps.NameToContact[sTo];
			if (sRelay) then
				ChatThrottleLib:SendAddOnMessage("NORMAL", "SaneLFG2", "A" .. sTo .. "!" .. sMsg, "WHISPER", sRelay);
				CHATFRAME:AddMessage("SaneLFG2: => {" .. sTo .. "} : " .. sMsg);
			else
				ChatThrottleLib:SendChatMessage("NORMAL", "SaneLFG2", sMsg, "WHISPER", nil, sTo);
				return
			end

			local	iCnt, i, iFound = #SaneLFGObj2.Maps.CommData;
			for i = 1, iCnt do
				local	oComm = SaneLFGObj2.Maps.CommData[i];
				if ((oComm.sFrom == nil) and (oComm.sTo == sTo) and (oComm.sRelay == sRelay)) then
					iFound = i;
					break;
				end
			end

			if (not iFound) then
				SaneLFGObj2.Maps.CommData[iCnt + 1] = { sFrom = sFrom, sTo = sTo, sRelay = sRelay };
				CHATFRAME:AddMessage("SaneLFG2: QuickID for this conversation is " .. i .. ".");
			end

			return
		end

		local	sID;
		sID, sMsg = string.match(arg1, "chat id (%d+) (.+)");
		if (sID) then
			local	iID = tonumber(sID);
			local	oComm = SaneLFGObj2.Maps.CommData[iID];
			if (oComm) then
				if (oComm.sFrom) then
					local	sRelay = oComm.sRelay;
					if (sRelay == nil) then
						sRelay = oComm.sTo;
					end
					ChatThrottleLib:SendAddOnMessage("NORMAL", "SaneLFG2", "R" .. oComm.sFrom ..":" .. oComm.sClassEN .. "!" .. oComm.sTo .. "!" .. sMsg, "WHISPER", sRelay);
				else
					ChatThrottleLib:SendAddOnMessage("NORMAL", "SaneLFG2", "A" .. oComm.sTo .. "!" .. sMsg, "WHISPER", oComm.sRelay);
				end
			else
				CHATFRAME:AddMessage("SaneLFG2: Invalid conversation ID " .. sID .. ".");
			end
		end
	elseif (arg1 == "show") then
		if (not SaneLFG2MainWnd:IsShown()) then
			SaneLFGObj2.MainWndToggle();
		end
	elseif (arg1 == "hide") then
		if (SaneLFG2MainWnd:IsShown()) then
			SaneLFGObj2.MainWndToggle();
		end
	elseif (arg1 == "mirrors") then
		local	sMirrors, bAmMirror = SaneLFGObj2.MirrorsToString();
		if (sMirrors ~= "") then
			if (bAmMirror) then
				CHATFRAME:AddMessage("SaneLFG2: Current mirrors (beside yourself) are => " .. sMirrors);
			else
				CHATFRAME:AddMessage("SaneLFG2: Current mirrors are => " .. sMirrors);
			end
		else
			if (bAmMirror) then
				CHATFRAME:AddMessage("SaneLFG2: No current mirrors (besides yourself).");
			else
				CHATFRAME:AddMessage("SaneLFG2: No current mirrors.");
			end
		end
	elseif (arg1 == "test") then
		if (not SaneLFG2MainWnd:IsShown()) then
			SaneLFGObj2.MainWndToggle();
		end
		-- SaneLFGObj2.ParseMessageTest("tank lfg any heroic (saved to totc, GD, CoS and Nex) or totc normal", false);
		-- SaneLFGObj2.ParseMessageTest("LFG naxx 10/25", false);
		-- SaneLFGObj2.ParseMessageTest("dd lfg pdk10/pdk25/ony25/naxx25/obsi10", false);
		SaneLFGObj2.ParseMessageTest("suche Leute für 'ne Runde MC und AQ 20 bissl Ruf farmen", false);
	else
		CHATFRAME:AddMessage("SaneLFG2: Unrecognized command <" .. (arg1 or "") .. ">. Currently valid commands are \"show\" and \"hide\".");
	end
end

function	SaneLFGObj2.AnnounceInit()
	SaneLFGObj2.Announce = { Data = {} };

	local	LFGPerRealm, k, v = SaneLFGObj2.FactionRealm.LFGPerChar;
	for k, v in pairs(LFGPerRealm) do
		-- announce only for same char
		if (v.sLFG and v.bLFGActive) then
			if (k == SaneLFGObj2.WhoAmI) then
				SaneLFGObj2.Announce.SelfIs = v;
				SaneLFGObj2.Announce.SelfIn = v.iAnnounce;

				local	sRoles = "";
				for m, x in pairs(v.oRoles) do
					sRoles = sRoles .. "/" .. strsub(m, 2);
				end

				sRoles = strsub(sRoles, 2);

				SaneLFGObj2.Announce.SelfData = "$! " .. sRoles .. " LFG " .. v.sLFG;
			end

			if (SaneLFGObj2.Announce.Other) then
				SaneLFGObj2.Announce.Other = math.min(SaneLFGObj2.Announce.Other, v.iAnnounce);
			else
				SaneLFGObj2.Announce.Other = v.iAnnounce;
			end

			SaneLFGObj2.Announce.Data[k] = v.iAnnounce;
		end
	end

	if (SaneLFGObj2.Announce.SelfIn) then
		SaneLFGObj2.Announce.SelfIn = 600 + time() - SaneLFGObj2.Announce.SelfIn;
	end
	if (SaneLFGObj2.Announce.Other) then
		SaneLFGObj2.Announce.Other = 300 + time() - SaneLFGObj2.Announce.Other;
	end
end

function	SaneLFGObj2.AnnounceUpdate()
	-- did we join something meanwhile?
	if ((GetRealNumPartyMembers() > 0) or (GetRealNumRaidMembers() > 0)) then
		SaneLFGObj2.Announce.SelfIn = nil;
		SaneLFGObj2.Announce.Other = nil;
		return
	end

	if (SaneLFGObj2.Announce.SelfIn) then
		if (SaneLFGObj2.Announce.SelfIn < 0) then
			if (SaneLFGObj2.Announce.SelfData and SaneLFGObj2.LFGChannelNum) then
				SaneLFGObj2.Announce.SelfIs.iAnnounce = time();
				SaneLFGObj2.Announce.SelfIn = 600;
				ChatThrottleLib:SendChatMessage("BULK", "SaneLFG2", SaneLFGObj2.Announce.SelfData, "CHANNEL", nil, SaneLFGObj2.LFGChannelNum);
			else
				SaneLFGObj2.Announce.SelfIn = nil;
			end
		end
	end

	if (SaneLFGObj2.Announce.Other) then
		if (SaneLFGObj2.Announce.Other < 0) then
			-- find the one who's time's up
			local	iNow, sWho, iAnnounce = time();
			for sWho, iAnnounce in pairs(SaneLFGObj2.Announce.Data) do
				if (iAnnounce + 300 < iNow) then
					SaneLFGObj2.SendBinaryLFGMessageFromSelfOrAlt(sWho);
					SaneLFGObj2.Announce.Data[sWho] = iNow;
					break
				end
			end

			-- search the oldest to update
			local	iNew = iNow + 300;
			for sWho, iAnnounce in pairs(SaneLFGObj2.Announce.Data) do
				iNew = math.min(iAnnounce + 300, iNew);
			end

			SaneLFGObj2.Announce.Other = iNew - iNow;
		end
	end
end

