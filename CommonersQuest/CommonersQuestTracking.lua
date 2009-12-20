
local	FirstRun, MissingEmote = true, false
local	Refs = {};
local	Handlers = {};

local	CQData = nil;
local	CQDataX = nil;
local	CQDataGlobal = nil;
local	CQH = CommonersQuest.Helpers;

function	CommonersQuest.Initializers.Tracking(CQDataMain, CQDataXMain, CQDataGlobalMain)
	CQData = CQDataMain;
	CQDataX = CQDataXMain;
	CQDataGlobal = CQDataGlobalMain;
end

function	CommonersQuestTracking.Update()
	if (CQData) then
		-- unregister all
		local	sEvent, oHandler;
		for sEvent, oHandler in pairs(Handlers) do
			CommonersQuestTrackingFrame:UnregisterEvent(sEvent);
		end

		local	Events = {};

		local	sChar, oCharData;
		for sChar, oCharData in pairs(CQData) do
			local	oQuests, iQuest, oQuest = oCharData.QuestsCurrent;
			for iQuest, oQuest in pairs(oQuests) do
				if (oQuest.BindingCompleted == 3) then
					CQH.InitTable(oQuest, "Completed");
					CQH.InitTable(oQuest, "Progress");
					CQH.InitTable(oQuest, "Failed");
					local	oFailed = oQuest.Failed;
					if (CQH.TableIsEmpty(oFailed) and not oQuest.Abandonned) then
						local	oCompleted = oQuest.Completed;
						local oDBQuest, k, v;
						if (iQuest < 1000000) then
							for k, v in pairs(CommonersQuest.QuestDB) do
								if (v.ID == iQuest) then
									oDBQuest = v;
								end
							end
						else
							for k, v in pairs(oCharData.QuestsCustom) do
								if (v.ID == iQuest) then
									oDBQuest = v;
								end
							end
						end

						if (oDBQuest) then
							CQH.CommChat("DbgInfo", "Tracking", "Quest " .. iQuest .. " has active objectives.");
							local	iReq, oReq;
							for iReq, oReq in pairs(oDBQuest.Requirements) do
								if ((oCompleted[iReq] == nil) and (oFailed[iReq] == nil)) then
									local	oEntry = { Req = oReq, From = sChar, QuestID = iQuest, ReqIndex = iReq };
									CQH.InitTable(Refs, oReq.Type);
									tinsert(Refs[oReq.Type], oEntry);
								end
							end
						end
					end
				end
			end
		end

		if (Refs["Emote"]) then
			local	iRefEmote, oRefEmote;
			for iRefEmote, oRefEmote in pairs(Refs["Emote"]) do
				if (type(oRefEmote.Req) == "table") then
					CQH.InitTable(Events, "CHAT_MSG_TEXT_EMOTE");
					CQH.InitTable(Events["CHAT_MSG_TEXT_EMOTE"], oRefEmote.Req.Emote);
					local	oContainer, bFound, k, v = Events["CHAT_MSG_TEXT_EMOTE"][oRefEmote.Req.Emote], false;
					for k, v in pairs(oContainer) do
						local	oRefEmoteDuplicate = Refs["Emote"][v];
						if ((oRefEmoteDuplicate.From == oRefEmote.From) and
						    (oRefEmoteDuplicate.QuestID == oRefEmote.QuestID) and
						    (oRefEmoteDuplicate.ReqIndex == oRefEmote.ReqIndex)) then
							CQH.CommChat("DbgInfo", "Tracking", "Oops? Duplicate in requirement TODO list?");
							bFound = true;
							break;
						end
					end
					if (not bFound) then
						tinsert(oContainer, iRefEmote);
					end
					if (FirstRun) then
						if (CommonersQuestLang.Emotes[oRefEmote.Req.Emote] == nil) then
							MissingEmote = true;
							CQH.CommChat("ChatInfo", nil, "Required emote missing in translation: /" .. oRefEmote.Req.Emote);
						end
					end
				end
			end
		end

		if (Refs["Kill"]) then
			local	iRefKill, oRefKill;
			for iRefKill, oRefKill in pairs(Refs["Kill"]) do
				if (type(oRefKill.Req) == "table") then
					CQH.InitTable(Events, "COMBAT_LOG_EVENT_UNFILTERED");
					CQH.InitTable(Events["COMBAT_LOG_EVENT_UNFILTERED"], "Kill");
					CQH.InitTable(Events["COMBAT_LOG_EVENT_UNFILTERED"].Kill, oRefKill.Req.TargetType);
					local	oContainer, bFound, k, v = Events["COMBAT_LOG_EVENT_UNFILTERED"].Kill[oRefKill.Req.TargetType], false;
					for k, v in pairs(oContainer) do
						local	oRefKillDuplicate = Refs["Kill"][v];
						if ((oRefKillDuplicate.From == oRefKill.From) and
						    (oRefKillDuplicate.QuestID == oRefKill.QuestID) and
						    (oRefKillDuplicate.ReqIndex == oRefKill.ReqIndex)) then
							CQH.CommChat("DbgInfo", "Tracking", "Oops? Duplicate in requirement TODO list?");
							bFound = true;
							break;
						end
					end
					if (not bFound) then
						tinsert(oContainer, iRefKill);
					end
				end
			end
		end

		if (Refs["Survive"]) then
			local	iRefSurvive, oRefSurvive;
			for iRefSurvive, oRefSurvive in pairs(Refs["Survive"]) do
				if (type(oRefSurvive.Req) == "table") then
					CQH.InitTable(Events, "COMBAT_LOG_EVENT_UNFILTERED");
					CQH.InitTable(Events["COMBAT_LOG_EVENT_UNFILTERED"], "Survive");
					CQH.InitTable(Events["COMBAT_LOG_EVENT_UNFILTERED"].Survive, oRefSurvive.Req.TargetType);
					local	oContainer, bFound, k, v = Events["COMBAT_LOG_EVENT_UNFILTERED"].Survive[oRefSurvive.Req.TargetType], false;
					for k, v in pairs(oContainer) do
						local	oRefSurviveDuplicate = Refs["Survive"][v];
						if ((oRefSurviveDuplicate.From == oRefSurvive.From) and
						    (oRefSurviveDuplicate.QuestID == oRefSurvive.QuestID) and
						    (oRefSurviveDuplicate.ReqIndex == oRefSurvive.ReqIndex)) then
							CQH.CommChat("DbgInfo", "Tracking", "Oops? Duplicate in requirement TODO list?");
							bFound = true;
							break;
						end
					end
					if (not bFound) then
						tinsert(oContainer, iRefSurvive);
					end
				end
			end
		end

		if (Refs["Duel"]) then
			local	iRefDuel, oRefDuel;
			for iRefDuel, oRefDuel in pairs(Refs["Duel"]) do
				if (type(oRefDuel.Req) == "table") then
					-- there are no useful and proper events here to check that both combattants are at 100% life at the beginning
					-- => must hook some functions which start a duel
					-- must activate COMBAT_LOG_EVENT_UNFILTERED as well on x-faction to catch damage from outside
					CQH.InitTable(Events, "CHAT_MSG_SYSTEM");
					CQH.InitTable(Events["CHAT_MSG_SYSTEM"], "Duel");
					local	oContainer, bFound, k, v = Events["CHAT_MSG_SYSTEM"].Duel, false;
					for k, v in pairs(oContainer) do
						local	oRefDuelDuplicate = Refs["Duel"][v];
						if ((oRefDuelDuplicate.From == oRefDuel.From) and
						    (oRefDuelDuplicate.QuestID == oRefDuel.QuestID) and
						    (oRefDuelDuplicate.ReqIndex == oRefDuel.ReqIndex)) then
							CQH.CommChat("DbgInfo", "Tracking", "Oops? Duplicate in requirement TODO list?");
							bFound = true;
							break;
						end
					end
					if (not bFound) then
						-- need: Name *or* Class *or* Race
						if (oRefDuel.PlayerName or oRefDuel.PlayerClass or oRefDuel.PlayerRace) then
							tinsert(oContainer, iRefDuel);
						else
							CQH.CommChat("DbgInfo", "Tracking", "Oops? Incomplete requirement " .. oRefDuel.ReqIndex .. " in quest " .. oRefDuel.QuestID .. " from " .. oRefDuel.From .. "!");
						end
					end
				end
			end
		end

		-- register what's up
		local	sEvent, oEvent;
		for sEvent, oEvent in pairs(Events) do
			if ((type(Handlers[sEvent]) == "table") and
			    (type(Handlers[sEvent].Function) == "function")) then
				CQH.CommChat("DbgInfo", "Tracking", "Activated handler: " .. sEvent);
				Handlers[sEvent].Data = oEvent;
				CommonersQuestTrackingFrame:RegisterEvent(sEvent);
			else
				CQH.CommChat("DbgImportant", "Tracking", "Missing handler: " .. sEvent);
			end
		end

		-- missing emotes?
		if (not MissingEmote) then
			local	sMissing, k, v = "";
			for k, v in pairs(CommonersQuestLang.EmoteList) do
				if (CommonersQuestLang.Emotes[v] == nil) then
					sMissing = sMissing .. " /" .. v;
					MissingEmote = true;
				end
			end
			if (MissingEmote) then
				CQH.CommChat("DbgImportant", "Tracking", "Missing emotes:" .. sMissing);
			end
		end
		-- missing emotes!
		if (MissingEmote) then
			local	sEvent = "CHAT_MSG_TEXT_EMOTE"; 
			if (Handlers[sEvent].Data == nil) then
				CQH.CommChat("DbgInfo", "Tracking", "Missing emotes! Activating handler (without active quest objectives) so you can report the output in your language.");
				Handlers[sEvent].Data = { "MissingEmote" };
				CommonersQuestTrackingFrame:RegisterEvent(sEvent);
			end
		end

		FirstRun = false;
	end
end

-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --

function	CommonersQuestTracking.OnEvent(self, event, ...)
	if (Handlers[event] and (Handlers[event].Function ~= nil)) then
		Handlers[event].Function(Handlers[event], self, ...);
	end
end

Handlers["CHAT_MSG_TEXT_EMOTE"] = {};
Handlers["CHAT_MSG_TEXT_EMOTE"].Function = function(oContainer, oFrame, ...)
	if (CQH.TableIsEmpty(oContainer.Data)) then
		local	sEvent = "CHAT_MSG_TEXT_EMOTE";
		CQH.CommChat("DbgInfo", "Tracking", "Deactivated handler: " .. sEvent);
		CommonersQuestTrackingFrame:UnregisterEvent(sEvent);
	end

	local	sEmote, sWho = ...;
	local	sTarget, sServer = UnitName("target");
	if ((sServer ~= nil) and (sServer ~= "")) then
		sTarget = nil;
	end

	if ((sTarget ~= nil) and (sWho == UnitName("player")) and not UnitIsUnit("player", "target")) then
		local	sGUID = UnitGUID("target");
		local	bFriendly = UnitIsFriend("player", "target");
		local	iPCNPC = tonumber(strsub(sGUID, 5, 5), 16);
		local	bPC = bit.band(iPCNPC, 7) == 0;
		local	bNPC = bit.band(iPCNPC, 7) ~= 0;
		local	iMobID = 0;
		if (bNPC) then
			iMobID = tonumber(strsub(sGUID, 6, 12), 16);
		end

		local	sUncode = string.gsub(sEmote, sTarget, "%%s");
		local	oEmotes, sKey, sEmoteKey, sEmoteLocal = CommonersQuestLang.Emotes;
		for sEmoteKey, sEmoteLocal in pairs(oEmotes) do
			if (sEmoteLocal == sUncode) then
				sKey = sEmoteKey;
			end
		end

		if (sKey) then
			CQH.CommChat("DbgInfo", "Tracking", sWho .. " => " .. sTarget .. ": /" .. sKey);
			if (not CheckInteractDistance("target", 3)) then
				CQH.CommChat("ChatImportant", nil, "Too far away: This won't count...");
				return
			end

			if (type(oContainer.Data[sKey]) == "table") then
				local	oDropKeys, k, v = {};
				for k, v in pairs(oContainer.Data[sKey]) do
					local	oRef = Refs["Emote"][v];
					local	bOk = true;
					if (oRef.Req.Friendly) then
						bOk = (bFriendly ~= nil);
					end
					if (bNPC and (oRef.Req.TargetType == "NPC")) then
						bOk = bOk and (oRef.Req.MobID == iMobID);
					elseif (bPC and (oRef.Req.TargetType == "PC")) then
						if (oRef.Req.PlayerGUID) then
							bOk = bOk and (oRef.Req.PlayerGUID == sGUID);
						else
							bOk = bOk and (oRef.Req.TargetName == sTarget);
						end
					else
						bOk = false;
					end
					local	oFailed = CommonersQuestKrbrPrdmrDataPerChar[oRef.From].QuestsCurrent[oRef.QuestID].Failed;
					if (oFailed and (#oFailed > 0)) then
						bOk = false
					end
					if (bOk) then
						CQH.CommChat("ChatInfo", nil, "Quest " .. oRef.QuestID .. ", objective " .. oRef.ReqIndex .. " is fulfilled.");
						CQData[oRef.From].QuestsCurrent[oRef.QuestID].Completed[oRef.ReqIndex] = time();
						tinsert(oDropKeys, k);
					end
				end

				local	l, w;
				for l, w in pairs(oDropKeys) do
					tremove(oContainer.Data[sKey], w);
				end
				if (CQH.TableIsEmpty(oContainer.Data[sKey])) then
					oContainer.Data[sKey] = nil;
				end
			end
		elseif (MissingEmote) then
			CQH.CommChat("DbgImportant", "Tracking", sWho .. " => " .. sTarget .. ": Unrecognized emote <" .. sUncode .. "> (from <" .. sEmote .. ">).");
			if (CommonersQuestKrbrPrdmrOtherPerChar and CommonersQuestKrbrPrdmrOtherPerChar.Debug) then
				ChatFrame_OpenChat("/w " .. UnitName("player") .. " " .. sUncode);
			end
		end
	end
end

-- must check *before* death if tapped by player! =>  UnitIsTapped("party[1234]target")

local	TappedUnits = {};

Handlers["COMBAT_LOG_EVENT_UNFILTERED"] = {};
Handlers["COMBAT_LOG_EVENT_UNFILTERED"].Function = function(oContainer, oFrame, ...)
	local	bForceUpdate = false;
	if (CQH.TableIsEmpty(oContainer.Data)) then
		local	sEvent = "COMBAT_LOG_EVENT_UNFILTERED";
		CQH.CommChat("DbgInfo", "Tracking", "Deactivated handler: " .. sEvent);
		CommonersQuestTrackingFrame:UnregisterEvent(sEvent);
	end

	if (oContainer.Data.Survive) then
		local	dAt, sEvent, _, _, _, sDestGUID = ...;
		if (strsub(sEvent, 1, 5) == "UNIT_") then		-- various pointless variants of UNIT_DIED
			local	iPCNPC, iMobID = tonumber(strsub(sDestGUID, 5, 5), 16);
			local	sKey = "NPC";
			if (bit.band(iPCNPC, 7) == 0) then
				sKey = "PC";
				iMobID = tonumber(strsub(sDestGUID, 6, 12), 16);
			end

			if (oContainer.Data.Survive[sKey]) then
				local	oDropKeys, k, v = {};
				for k, v in pairs(oContainer.Data.Survive[sKey]) do
					local	oRef = Refs.Survive[v];
					if (((sKey == "NPC") and (oRef.Req.MobID == iMobID)) or
					    ((sKey == "PC") and (oRef.Req.PlayerGUID == sDestGUID))) then
						CQH.CommChat("ChatImportant", "Tracking", "Quest " .. oRef.QuestID .. ", objective " .. oRef.ReqIndex .. " FAILED.");
						local	oFailed = CQData[oRef.From].QuestsCurrent[oRef.QuestID].Failed;
						oFailed[oRef.ReqIndex] = true;
						tinsert(oDropKeys, k);
						bForceUpdate = true;
					end
				end

				local	l, w;
				for l, w in pairs(oDropKeys) do
					tremove(oContainer.Data.Survive[sKey], w);
				end
				if (CQH.TableIsEmpty(oContainer.Data.Survive[sKey])) then
					oContainer.Data.Survive[sKey] = nil;
					if (CQH.TableIsEmpty(oContainer.Data.Survive)) then
						oContainer.Data.Survive = nil;
					end
				end
			end
		end
	end

	if (oContainer.Data.Kill) then
		if (not InCombatLockdown()) then
			-- hopefully UNIT_DIED arrives before lockdown is removed...
			TappedUnits = table.wipe(TappedUnits);
			return
		end

		local	bInInstance = IsInInstance();

		local	iNPCCnt, iPCCnt = 0, 0;
		if (oContainer.Data.Kill["NPC"]) then
			iNPCCnt = #oContainer.Data.Kill["NPC"];
		end
		if (oContainer.Data.Kill["PC"]) then
			iPCCnt = #oContainer.Data.Kill["PC"];
		end

		-- players (of the opposite faction) cannot be killed in instances
		if (not bInInstance and (iPCCnt > 0)) then
			-- PvP: not supported yet, likely never.
		end

		if (iNPCCnt > 0) then
			local	dAt, sEvent, sSrcGUID, _, _, sDestGUID = ...;

			local	function	GUID2MobID(sGUID)
					local	iPCNPC = tonumber(strsub(sDestGUID, 5, 5), 16);
					if (bit.band(iPCNPC, 7) ~= 0) then
						return tonumber(strsub(sDestGUID, 6, 12), 16);
					end
				end

			local	function	CheckTapped(sGUID, bSet, bValue)
					local	iMobID = GUID2MobID(sGUID);
					if (iMobID) then
						if (TappedUnits[iMobID] == nil) then
							TappedUnits[iMobID] = { At = dAt };
						end
						if (bSet and bValue) then
							TappedUnits[iMobID].Tapped = bValue;
						end
					end
				end

			CheckTapped(sSrcGUID);		-- no unit
			CheckTapped(sDestGUID);		-- no unit

			local	sGUID, bTapped;
			if (UnitExists("target")) then
				sGUID = UnitGUID("target");
				bTapped = UnitIsTappedByPlayer("target");
				CheckTapped(sGUID, true, bTapped);
			end
			if (UnitExists("targettarget")) then
				sGUID = UnitGUID("targettarget");
				bTapped = UnitIsTappedByPlayer("targettarget");
				CheckTapped(sGUID, true, bTapped);
			end
			if (UnitExists("targettargettarget")) then
				sGUID = UnitGUID("targettargettarget");
				bTapped = UnitIsTappedByPlayer("targettargettarget");
				CheckTapped(sGUID, true, bTapped);
			end

			local	iCnt, i = GetNumPartyMembers();
			for i = 1, iCnt do
				local	sPT = "party" .. i .. "target";
				if (UnitExists(sPT)) then
					sGUID = UnitGUID(sPT);
					bTapped = UnitIsTappedByPlayer(sPT);
					CheckTapped(sGUID, true, bTapped);
				end

				sPT = "party" .. i .. "targettarget";
				if (UnitExists(sPT)) then
					sGUID = UnitGUID(sPT);
					bTapped = UnitIsTappedByPlayer(sPT);
					CheckTapped(sGUID, true, bTapped);
				end
			end

			if (strsub(sEvent, 1, 5) == "UNIT_") then 		-- various pointless variants of UNIT_DIED
				local	iMobID = GUID2MobID(sGUID);
				if (TappedUnits[iMobID] and TappedUnits[iMobID].Tapped) then
					local	oDropKeys, k, v = {};
					for k, v in pairs(oContainer.Data.Kill["NPC"]) do
						local	oRef = Refs.Kill[v];
						if (oRef.Req.MobID == iMobID) then
							local	oFailed = CommonersQuestKrbrPrdmrDataPerChar[oRef.From].QuestsCurrent[oRef.QuestID].Failed;
							if (oFailed and (#oFailed > 0)) then
								CQH.CommChat("DbgInfo", "Tracking", "Quest " .. oRef.QuestID .. " already failed, skipping...");
							else
								local	bCompleted = false;
								if ((oRef.Req.Count == nil) or (oRef.Req.Count == 1)) then
									bCompleted = true;
								else
									local	iProgress = CQData[oRef.From].QuestsCurrent[oRef.QuestID].Progress[oRef.ReqIndex];
									if (iProgress == nil) then
										iProgress = 0;
									end
									iProgress = iProgress + 1;
									if (iProgress >= oRef.Req.Count) then
										bCompleted = true;
										iProgress = oRef.Req.Count;
									end

									CQData[oRef.From].QuestsCurrent[oRef.QuestID].Progress[oRef.ReqIndex] = iProgress;
								end

								if (bCompleted) then
									CQData[oRef.From].QuestsCurrent[oRef.QuestID].Completed[oRef.ReqIndex] = time();
									tinsert(oDropKeys, k);
									CQH.CommChat("ChatInfo", nil, "Quest " .. oRef.QuestID .. ", objective " .. oRef.ReqIndex .. " completed.");
								else
									CQH.CommChat("ChatInfo", nil, "Quest " .. oRef.QuestID .. ", objective " .. oRef.ReqIndex .. " progressed...");
								end
							end
						end
					end

					local	l, w;
					for l, w in pairs(oDropKeys) do
						tremove(oContainer.Data.Kill["NPC"], w);
					end
					if (CQH.TableIsEmpty(oContainer.Data.Kill["NPC"])) then
						oContainer.Data.Kill["NPC"] = nil;
						if (CQH.TableIsEmpty(oContainer.Data.Kill)) then
							oContainer.Data.Kill = nil;
						end
					end
				end
			end
		end
	end

	if (bForceUpdate) then
		CommonersQuestTracking.Update();
	end
end

--
---
--
Handlers["CHAT_MSG_SYSTEM"] = {};
Handlers["CHAT_MSG_SYSTEM"].Function = function(oContainer, oFrame, ...)
	if (CQH.TableIsEmpty(oContainer.Data)) then
		local	sEvent = "CHAT_MSG_SYSTEM";
		CQH.CommChat("DbgInfo", "Tracking", "Deactivated handler: " .. sEvent);
		CommonersQuestTrackingFrame:UnregisterEvent(sEvent);
	end

	-- duel:
	-- ["Duel"]  = { DuelResult = "string", DuelArea = "string", Count = "number",
	--		PlayerFaction = "string", PlayerDesc = "string",
	--		PlayerRace = "string", PlayerClass = "string", PlayerName = "string", PlayerGUID = "string" },
	--
	-- - in area X
	-- - win or lose (*g*)
	-- - by name or by race or by class or by race/class

	local	arg1 = ...;
	local	sPattern = string.gsub(DUEL_WINNER_KNOCKOUT, "%%%d%$s", "(.+)");
	local	sWinner, sLoser = string.match(arg1, sPattern);
	if (sWinner and sLoser) then
		local	WhoAmI = UnitName("player");
		local	WhatsMyFaction = UnitFactionGroup("player");
		local	sTarget, sServer = UnitName("target");
		if (((sServer == nil) or (sServer == "")) and
		    ((WhoAmI == sWinner) or (WhoAmI == sLoser)) and
		    ((sTarget == sWinner) or (sTarget == sLoser))) then
			if (((WhoAmI == sLoser) and UnitIsPVP("player")) or
			    ((sTarget == sLoser) and UnitIsPVP("target"))) then
				return
			end

			local	_, sRace = UnitRace("target");
			local	_, sClass = UnitClass("target");
			local	sFaction = UnitFactionGroup("target");
			local	sGUID = UnitGUID("target");

			local	oDropKeys, k, v = {};
			for k, v in pairs(oContainer.Data.Duel) do
				local	oRef = Refs["Duel"][v];
				if (oRef.PlayerFaction == sFaction) then
					local	bMaybe = true;
					if (bMaybe and (oRef.DuelArea == true)) then
						-- force coordinates
						SetMapToCurrentZone();
						if (not WorldMapFrame:IsShown()) then
							WorldMapFrame:Show();
							WorldMapFrame:Hide();
						end

						-- indoor/outdoor (indoor interferes with guards if cross-faction)
						local	sKeyDoors;
						if (sFaction ~= WhatsMyFaction) then 
							sKeyDoors = "Outdoors";
						else
							sKeyDoors = "Indoors";
						end

						-- losing must be at home, winning at the target's faction
						local	sKeyFaction;
						if (oRef.DuelResult == "win") then
							sKeyFaction = sFaction;
						else
							sKeyFaction = WhatsMyFaction;
						end

						-- outdoors: Dun Morogh (IF), Durotar (OG)
						-- indoors : bank area (IF), inside at the dragonhead area (OG)
						if (sKeyDoors and sKeyFaction and
						    CommonersQuest.Strings.Duel[sKeyDoors] and
						    CommonersQuest.Strings.Duel[sKeyDoors][sKeyFaction]) then
							local	oPlace = CommonersQuest.Strings.Duel[sKeyDoors][sKeyFaction];

							local	sRegion = GetRealZoneText();
							if (sRegion ~= oPlace.Name) then
								bMaybe = false;
							else
								local	x, y = GetPlayerMapPosition("player");
								if ((x == 0) and (y == 0)) then
									bMaybe = false;
								elseif ((oPlace.x ~= 0) and (oPlace.y ~= 0)) then
									local	dx = x - oPlace.x;
									local	dy = y - oPlace.y;
									local	distance = math.sqrt(dx * dx + dy * dy);
									if (distance > 0.003) then
										bMaybe = false;
									end
								end
							end

							if (not bMaybe) then
								CQH.CommChat("ChatInfo", nil, "Quest " .. oRef.QuestID .. ", objective " .. oRef.ReqIndex .. " NOT progressed: Outside of expected area (" .. oPlace.Name .. ") or the expected subzone.");
							end
						end
					end

					if (bMaybe) then
						-- by name/race/class
						if (oRef.PlayerName and (oRef.PlayerName ~= sTarget)) then
							bMaybe = false;
						end
						if (oRef.PlayerRace and (oRef.PlayerRace ~= sRace)) then
							bMaybe = false;
						end
						if (oRef.PlayerClass and (oRef.PlayerClass ~= sClass)) then
							bMaybe = false;
						end
						if (oRef.PlayerGUID and (oRef.PlayerGUID ~= sGUID)) then
							bMaybe = false;
						end
					end

					if (bMaybe) then
						-- win/lose
						if (WhoAmI == sWinner) then
							bMaybe = oRef.DuelResult == "win";
						else
							bMaybe = oRef.DuelResult == "lose";
						end

						-- check for streak failure:
						if (oRef.DuelStreak and not bMaybe) then
							CQH.CommChat("ChatInfo", nil, "Quest " .. oRef.QuestID .. ", objective " .. oRef.ReqIndex .. " reset: You must complete this duel objective in *one* streak! Start again...");
							CQData[oRef.From].QuestsCurrent[oRef.QuestID].Progress[oRef.ReqIndex] = 0;
						end
					end

					if (bMaybe) then
						local	bCompleted = false;
						if ((oRef.Req.Count == nil) or (oRef.Req.Count == 1)) then
							bCompleted = true;
						else
							local	iProgress = CQData[oRef.From].QuestsCurrent[oRef.QuestID].Progress[oRef.ReqIndex];
							if (iProgress == nil) then
								iProgress = 0;
							end
							iProgress = iProgress + 1;
							if (iProgress >= oRef.Req.Count) then
								bCompleted = true;
								iProgress = oRef.Req.Count;
							end

							CQData[oRef.From].QuestsCurrent[oRef.QuestID].Progress[oRef.ReqIndex] = iProgress;
						end

						if (bCompleted) then
							CQData[oRef.From].QuestsCurrent[oRef.QuestID].Completed[oRef.ReqIndex] = time();
							tinsert(oDropKeys, k);
							CQH.CommChat("ChatInfo", nil, "Quest " .. oRef.QuestID .. ", objective " .. oRef.ReqIndex .. " completed.");
						else
							CQH.CommChat("ChatInfo", nil, "Quest " .. oRef.QuestID .. ", objective " .. oRef.ReqIndex .. " progressed...");
						end
					end
				end
			end


			local	l, w;
			for l, w in pairs(oDropKeys) do
				tremove(oContainer.Data.Duel, w);
			end
			if (CQH.TableIsEmpty(oContainer.Data.Duel)) then
				oContainer.Data.Duel = nil;
			end
		end
	end
end

function	CQDebug()
--[[
	local	sItem    = "|cffffffff|Hitem:769:0:0:0:0:0:0:1643911040:10|h[Brocken Eberfleisch]|h|r";
	local	sPattern = "|c........|Hitem:[%d%-:]+|h%[.+%]|h|r";
	local	sLen, i = strlen(sPattern);
	for i = 1, sLen do
		local	sSub = strsub(sPattern, 1, i);
		if ((i >= 18) and (i <= 23)) then
			sSub = sSub .. "%+]";
		end

		CQH.CommChat("DbgInfo", "Tracking", i .. ": Pattern = " .. sSub);
		local	sMatch = string.match(sItem, "(" .. sSub .. ")");
		CQH.CommChat("DbgInfo", "Tracking", i .. ": Match = " .. (sMatch or "nil"));
	end
]]--

--[[
		CQDebug(iDepth)

	local	sPattern = "aux actes de";

	local	function	Check(oTable, sPrefix, iDepth)
			local	k, v;
			for k, v in pairs(oTable) do
				if (type(v) == "string") then
					if (strfind(v, sPattern)) then
						print(sPrefix .. "." .. k .. "=>" .. v);
					end
				elseif (type(v) == "table") and (iDepth > 0) then
					Check(v, sPrefix .. "." .. tostring(k), iDepth - 1);
				end
			end
		end

	Check(_G, "_G", iDepth or 5);
]]--
end

