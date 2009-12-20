
-- ReputationQuestTracker.lua
local	oInit = { Missing = {}, Config = { Factions = {} } };
RepQTrackByKrbrEUPrdmr = { Missing = {}, Config = { Factions = {} } };

local	function	RepQFrame_ValidateData()
	local	function	CheckTable(oTableInit, oTableCurrent)
			local	k, v;
			for k, v in pairs(oTableInit) do
				if (type(oTableCurrent[k]) ~= "table") then
					oTableCurrent[k] = {};
				end

				if (next(v) ~= nil) then
					CheckTable(v, oTableCurrent[k]);
				end
			end
		end

	CheckTable(oInit, RepQTrackByKrbrEUPrdmr);
end

-- TODO: need to store header to quests, so collapsing doesn't "complete" quests

local	bSpam = true;

local	RepQTracker = {};
local	oFactionStandings = {};
local	oAt = {};
local	oGainAt = {};
local	oQuestIDs = {};

--
---
--
local	iAbandonQuestID, bAbandonned;
local	oQuests = {};

--
---
--
local	function	RepQFrame_AbandonPrepare()
	iAbandonQuestID = nil;
	bAbandonned = false;

	local	sName = GetAbandonQuestName();

	local	oFactionNames, k, v = {};
	for k, v in pairs(RepQTrackByKrbrEUPrdmr.Config.Factions) do
		if (ReputationQuestTrackerFactionName[k]) then
			oFactionNames[ReputationQuestTrackerFactionName[k].Name] = k;
		end
	end

	local	k, v;
	for iQID, oQ in pairs(oQuests) do
		if (oQ.Title == sName) then
			local	sName, sNameEN;
			for sName, sNameEN in pairs(oFactionNames) do
				local	x = ReputationQuestTrackerFactionGain[sNameEN][iQID];
				if (x) then
					DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: <" .. iQID .. ": " .. oQ.Title .. "> might've gained " .. x .. " reputation with " .. sName .. ".");
				end
			end

			iAbandonQuestID = iQID;
			return
		end
	end
end

local	function	RepQFrame_AbandonExecute()
	bAbandonned = true;
end

--
---
--
local	function	RepQFrame_QuestCache()
	local	k, v;
	for k, v in pairs(oQuests) do
		v.Old = v.Complete;
	end

	-- first, check for collapsed entries and WARN
	local	iNumEntries = GetNumQuestLogEntries();
	local	previousIsHeader = nil;
	local	Warn = false;
	local	iNumQuests = 0;
	local	i;
	local	sWarnComp = "";
	for i = 1, iNumEntries do
		local	questLogTitleText, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(i);
		if (isHeader == 1) then
			sWarnComp = sWarnComp .. "H";
			if (previousIsHeader == 1) then
				Warn = true;
			end
		else
			sWarnComp = sWarnComp .. "Q";

			local	iCount = GetNumQuestLeaderBoards(i);
			if (iCount and (iCount ~= 0)) then
				extid = GetQuestLink(i);
				if (extid) then
					-- split out the QID itself
					s0, s1, s2, s3 = strsplit("|", extid);
					s1, extid, s3 = strsplit(":", s2);
					extid = tonumber(extid);

					if (oQuests[extid] == nil) then
						oQuests[extid] = { Title = questLogTitleText, Level = level };
					end

					oQuests[extid].Complete = isComplete;
				end
			end
		end
		if (isHeader ~= 1) then
			iNumQuests = iNumQuests + 1;
		end
		previousIsHeader = isHeader;
	end
	-- only last section collapsed?
	if (previousIsHeader == 1) then
		Warn = true;
	end

	local	iNow, iGainAt = time();
	if (next(oGainAt)) then
		iGainAt = iNow;
		while ((oGainAt[iGainAt] == nil) and (iNow - iGainAt < 20)) do
			iGainAt = iGainAt - 1;
		end

		if (oGainAt[iGainAt] == nil) then
			iGainAt = nil;
		end
	end

	-- if something is left with "Old" set, the quest was completed, unless it was abandonned
	local	k, v;
	for k, v in pairs(oQuests) do
		if (v.Old ~= v.Complete) then
			if (bAbandonned and iAbandonQuestID and (k == iAbandonQuestID)) then
				DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Quest " .. iAbandonQuestID .. " was abandonned, forgetting about it.");
				iAbandonQuestID = nil;
				bAbandonned = false;
				oQuests[k] = nil;
			elseif (v.Complete ~= 1) then
				DEFAULT_CHAT_FRAME:AddMessage("[RQT] Quest " .. k .. " NOT completed (" .. tostring(v.CompleteRaw) .. "/" .. tostring(v.Complete) .. ")... forgetting.");
				oQuests[k] = nil;
			else
				-- TODO: is this a valid one?
				DEFAULT_CHAT_FRAME:AddMessage("[RQT] Quest " .. k .. " completed (" .. tostring(v.CompleteRaw) .. "/" .. tostring(v.Complete) .. ")... storing.");

				RepQTrackByKrbrEUPrdmr[k] = { At = iNow, Level = UnitLevel("player") + UnitXP("player") / UnitXPMax("player") };
				oAt[iNow] = k;
				oQuests[k] = nil;

				if (iGainAt) then
					local	sFactionEN, iGainIs;
					for sFactionEN, iGainIs in pairs(oGainAt[iGainAt]) do
						local	iGainExp = ReputationQuestTrackerFactionGain[sFactionEN][k] or 0;

						local	bCorrect;
						-- Human bonus vs. normal people, can't test equality
						if (iGainIs ~= iGainExp) then
							local	iGain = math.abs(iGainIs - iGainExp);
							local	iGainRelError = iGain / iGainIs;
							-- absolutely correct would be 0.1, but rounding errors might f. this up
							bCorrect = math.abs(iGainRelError) < 0.15;
						else
							bCorrect = true;
						end

						if (not bCorrect) then
							local	oTable = RepQTrackByKrbrEUPrdmr.Missing[sFactionEN];
							if (oTable == nil) then
								oTable = { Gains = {}, Data = {} };
								RepQTrackByKrbrEUPrdmr.Missing[sFactionEN] = oTable;
							end

							oTable.Gains[k] = iGainIs;
							oTable.Data[k] = {};
							local	l, w;
							for l, w in pairs(RepQTrackByKrbrEUPrdmr[k]) do
								oTable.Data[k][l] = w;
							end
							oTable.Data[k].FactionAt = iGainAt;
							oTable.Data[k].Name = v.Title;
						end

						if (not bCorrect or bSpam) then
							local	sExpectedGain = "";
							if (iGainExp and (iGainExp > 0) and not bCorrect) then
								sExpectedGain = " (Expected gain was " .. iGainExp .. ", mismatch in DB!)";
							end
							DEFAULT_CHAT_FRAME:AddMessage("[RQT] {" .. k .. "} " .. v.Title .. " gained " .. iGainIs .. "." .. sExpectedGain);
						end
					end
				end
			end
		end
	end
end

local	function	RepQFrame_UpdateFactions()
	local	oFactionNames, k, v = {};
	for k, v in pairs(RepQTrackByKrbrEUPrdmr.Config.Factions) do
		if (v and ReputationQuestTrackerFactionName[k]) then
			oFactionNames[ReputationQuestTrackerFactionName[k].Name] = k;
		end
	end

	local	oFactionAll, k, v = {};
	for k, v in pairs(oFactionStandings) do
		oFactionAll[k] = { old = v };
	end

	local	oFactionNew = {};
	local	iCnt, i = GetNumFactions();
	for i = 1, iCnt do
		local	sName, _, _, _, _, iEarnedValue, _, _, isHeader, isCollapsed, hasRep, _, isChild = GetFactionInfo(i);
		local	sNameEN = oFactionNames[sName];
		if (sNameEN) then
			oFactionNew[sNameEN] = iEarnedValue;
			if (oFactionAll[sNameEN] == nil) then
				oFactionAll[sNameEN] = {};
			end
			oFactionAll[sNameEN].name = sName;
			oFactionAll[sNameEN].new = iEarnedValue;
		end
	end

	if (bSpam) then
		local	i, sOut, k, v = 0, "";
		for k, v in pairs(oFactionAll) do
			i = i + 1;
			sOut = sOut .. "; " .. (v.name or "<unknown>") .. ": " .. (v.old or "<unset>") .. "=>" .. (v.new or "<unset>");
		end
		if (i > 0) then
			DEFAULT_CHAT_FRAME:AddMessage("[RQT] Reputations changed... checking " .. i .. " factions (" .. strsub(sOut, 3) .. ").");
		else
			DEFAULT_CHAT_FRAME:AddMessage("[RQT] Reputations changed... not for any active watched faction.");
		end
	end

--[[
	local	iNow, iQID = time();
	if (next(oAt)) then
		local	iAt = iNow;
		while ((oAt[iAt] == nil) and (iNow - iAt < 30)) do
			iAt = iAt - 1;
		end
		iQID = oAt[iAt];
	end
]]--

	local	iNow = time();
	for k, v in pairs(oFactionAll) do
		if (v.old and v.new and (v.old < v.new)) then
			if (oGainAt[iNow] == nil) then
				oGainAt[iNow] = {};
			end
			oGainAt[iNow][k] = v.new - v.old;
--[[
			local	iGainIs, bCorrect = v.new - v.old, false;
			if (iQID == nil) then
				DEFAULT_CHAT_FRAME:AddMessage("[RQT] Reputation " .. v.name .. " increased... but no recent quest. :-(");
			else
				local	iGainExp = ReputationQuestTrackerFactionGain[k][iQID] or 0;
				-- Human bonus vs. normal people, can't test equality
				if (iGainIs ~= iGainExp) then
					local	iGain = math.abs(iGainIs - iGainExp);
					local	iGainRel = iGain / iGainIs;
					-- absolutely correct would be 0.9 to 1.1, but rounding errors might f. this up
					bCorrect = (iGainRel >= 0.85) and (iGainRel <= 1.15);
				else
					bCorrect = true;
				end

				if (not bCorrect) then
					local	oTable = RepQTrackByKrbrEUPrdmr.Missing[k];
					if (oTable == nil) then
						oTable = { Gains = {}, Data = {} };
						RepQTrackByKrbrEUPrdmr.Missing[k] = oTable;
					end

					oTable.Gains[iQID] = v.new - v.old;
					oTable.Data[iQID] = {};
					local	k, v;
					for k, v in pairs(RepQTrackByKrbrEUPrdmr[iQID]) do
						oTable.Data[iQID][k] = v;
					end
					oTable.Data[iQID].FactionAt = time();
				end

				if (not bCorrect or bSpam) then
					local	sExpectedGain = "";
					if (iGainExp) then
						sExpectedGain = " (Expected gain was " .. iGainExp .. ", mismatch in DB!)";
					end
					DEFAULT_CHAT_FRAME:AddMessage("[RQT] " .. v.name .. " gained " .. (v.new - v.old) .. "." .. sExpectedGain);
				end
			end
]]--
		end
	end

	oFactionStandings = oFactionNew;
end

--
---
--
local	bQuestUpdate = true;

local	function	RepQFrame_OnEvent(oFrame, sEvent, ...)
	if (sEvent == "ADDON_LOADED") then
		local	arg1 = ...;
	 	if (arg1 == "ReputationQuestTracker") then
			oFrame:UnregisterEvent("ADDON_LOADED");

			oFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM");	-- output if that gives reputation
			oFrame:RegisterEvent("GOSSIP_SHOW");		-- output which quests give rep.
			oFrame:RegisterEvent("QUEST_GREETING");		-- output which quests give rep.
			oFrame:RegisterEvent("QUEST_DETAIL");		-- output which quests give rep.
			oFrame:RegisterEvent("QUEST_LOG_UPDATE");	-- the real pain of tracking completed quests

			oFrame:RegisterEvent("UPDATE_FACTION");		-- quests missing proper faction tags

			RepQFrame_ValidateData();

			hooksecurefunc("SetAbandonQuest", RepQFrame_AbandonPrepare);
			hooksecurefunc("AbandonQuest", RepQFrame_AbandonExecute);

			RepQTracker.SlashCmdsInit();
		end
	end

	if ((sEvent == "QUEST_ACCEPT_CONFIRM") or (sEvent == "GOSSIP_SHOW") or (sEvent == "QUEST_GREETING") or (sEvent == "QUEST_DETAIL")) then
		local	oTitles = {};

		if (sEvent == "QUEST_ACCEPT_CONFIRM") then
			-- arg2 is title
			local	arg1, arg2 = ...;
			if (arg2) then
				tinsert(oTitles, arg2);
			end
		end

		if (sEvent == "GOSSIP_SHOW") then
			-- title1, level1, isLowLevel1, title2, level2, isLowLevel2, title3, level3, isLowLevel3
			local	oInfo = { GetGossipAvailableQuests(); };
			local	iIndex, k, v = 0;
			for k, v in pairs(oInfo) do
				iIndex = iIndex + 1;
				if (iIndex == 1) then
					tinsert(oTitles, v);
				end
				if (iIndex == 3) then
					iIndex = 0;
				end
			end
		end

		if (sEvent == "QUEST_GREETING") then
			-- title1, level1, isLowLevel1, title2, level2, isLowLevel2, title3, level3, isLowLevel3
			local	iCnt, i = GetNumAvailableQuests();
			for i = 1, iCnt do
				tinsert(oTitles, GetAvailableTitle(i));
			end
		end

		if (sEvent == "QUEST_DETAIL") then
			local	sTitle = GetTitleText();
			if (sTitle) then
				tinsert(oTitles, sTitle);
			end
		end

		if (next(oTitles) == nil) then
DEFAULT_CHAT_FRAME:AddMessage("[RQT] No q's found.");
			return
		end

		local	oFactions, oGroups, sNameEN, oFactionInfo = {}, {};
		for sNameEN, oFactionInfo in pairs(ReputationQuestTrackerFactionName) do
			if (ReputationQuestTrackerFactionGain[sNameEN] and RepQTrackByKrbrEUPrdmr.Config.Factions[sNameEN]) then
				oFactions[sNameEN] = oFactionInfo;
				tinsert(oGroups, oFactionInfo.Group);
			end
		end

		local	oQIDs = {};
		for k, v in pairs(oTitles) do
			local	i, sGroup;
			for i, sGroup in pairs(oGroups) do
				local	iQID, oQ;
				for iQID, oQ in pairs(ReputationQuestTrackerQuestData[sGroup]) do
					if (oQ.Title == v) then
						tinsert(oQIDs, iQID);
					end
				end
			end
		end

		local	i, iQID;
		for i, iQID in pairs(oQIDs) do
			if (RepQTrackByKrbrEUPrdmr[iQID] == nil) then
				local	sNameEN, oFactionInfo;
				for sNameEN, oFactionInfo in pairs(oFactions) do
					local	iGain = ReputationQuestTrackerFactionGain[sNameEN][iQID];
					if (iGain) then
						local	oQ = ReputationQuestTrackerQuestData[oFactionInfo.Group][iQID];
						DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: <" .. iQID .. ": " .. oQ.Title .. "> would gain " .. iGain .. " reputation with " .. oFactionInfo.Name .. ".");
					end
				end
			end
		end
	elseif (sEvent == "QUEST_LOG_UPDATE") then
		bQuestUpdate = true;
	elseif (sEvent == "UPDATE_FACTION") then
		RepQFrame_UpdateFactions();
	end
end

--
---
--
local	iElapsedSum = 0;

local	function	RepQFrame_OnUpdate(oFrame, iElapsed)
	iElapsedSum = iElapsedSum + iElapsed;
	if (iElapsedSum < 1.0) then
		return
	end
	iElapsedSum = 0;

	if (bQuestUpdate) then
		RepQFrame_QuestCache();
	end
end

--
---
--
function	RepQTracker.SlashCmdsInit()
	SLASH_REPQTRACKER1 = "/repquesttracker";
	SLASH_REPQTRACKER2 = "/rqt";
	SlashCmdList["REPQTRACKER"] = RepQTracker.SlashCmdHandler;

	RepQTracker.SlashCmdMap = {
		help = RepQTracker.SlashCmdHelp,
		toggle = RepQTracker.SlashCmdToggle,
		check = RepQTracker.SlashCmdCheck,
		search = RepQTracker.SlashCmdSearch,
		add = RepQTracker.SlashCmdAddRemove,
		remove = RepQTracker.SlashCmdAddRemove,
		}
end

function	RepQTracker.SlashCmdHandler(cmdline)
	local	iCounter = 0;
	local	args = {};

	local	w;
	for w in string.gmatch(cmdline, "%S+") do
		iCounter = iCounter+1;
		args[iCounter] = w;
	end

	if (RepQTracker.SlashCmdMap[args[1]]) then
		RepQTracker.SlashCmdMap[args[1]](args, iCounter);
	else
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Unknown command >" .. cmdline .. "< Try help.");
	end
end

function	RepQTracker.SlashCmdHelp(args, iCounter)
	local	sCmds, k, v = "";
	for k, v in pairs(RepQTracker.SlashCmdMap) do
		sCmds = sCmds .. ", " .. k;
	end

	if (sCmds ~= "") then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Available commands are " .. strsub(sCmds, 3) .. ".");
	end

	local	sReps, sNameEN, oFactionInfo = "";
	for sNameEN, oFactionInfo in pairs(ReputationQuestTrackerFactionName) do
		if (ReputationQuestTrackerFactionGain[sNameEN]) then
			sReps = sReps .. ", " .. oFactionInfo.Name;
			local	bState = RepQTrackByKrbrEUPrdmr.Config.Factions[sNameEN];
			if (bState == true) then
				sReps = sReps .. "(tracked)";
			end
		else
			sReps = sReps .. ", " .. oFactionInfo.Name .. "(no data)";
		end
	end

	if (sReps ~= "") then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Available reputations are " .. strsub(sReps, 3) .. ".");
	end
end

function	RepQTracker.SlashCmdToggle(args, iCounter)
	if (iCounter ~= 2) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Toggle watch on reputation. Required argument: valid reputation");
		return
	end

	local	sNameEN, k, v;
	for k, v in pairs(ReputationQuestTrackerFactionName) do
		if (v.Name == args[2]) then
			sNameEN = k;
			break;
		end
	end

	if (sNameEN == nil) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: <" .. args[2] .. "> is not a valid reputation. (2)");
		return
	end

	local	bState = RepQTrackByKrbrEUPrdmr.Config.Factions[sNameEN];
	bState = bState ~= true;
	RepQTrackByKrbrEUPrdmr.Config.Factions[sNameEN] = bState;

	if (bState) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: <" .. args[2] .. "> is now tracked.");
	else
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: <" .. args[2] .. "> is no longer tracked.");
	end
end

function	RepQTracker.SlashCmdCheck(args, iCounter)
	if (iCounter ~= 2) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Status report about number of completed quests for a specific reputation. Required argument: valid reputation");
		return
	end

	local	oFactionNames, k, v = {};
	for k, v in pairs(RepQTrackByKrbrEUPrdmr.Config.Factions) do
		if (ReputationQuestTrackerFactionName[k]) then
			oFactionNames[ReputationQuestTrackerFactionName[k].Name] = k;
		end
	end

	local	sFactionEN = oFactionNames[args[2]];
	if (sFactionEN == nil) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: <" .. args[2] .. "> is not a valid reputation. (1)");
		return
	end

	local	oRepTable = ReputationQuestTrackerFactionGain[sFactionEN];
	local	oQuestTable = ReputationQuestTrackerQuestData[ReputationQuestTrackerFactionName[sFactionEN].Group];
	if ((oRepTable == nil) or (oQuestTable == nil)) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: <" .. args[2] .. "> is not a valid reputation. (2)");
		return
	end

	local	iLevel = UnitLevel("player");

	local	oAll, k, v = {};
	for k, v in pairs(oRepTable) do
		local	oQ = oQuestTable[k];
		if (oQ.Level <= iLevel + 7) then
			oAll[k] = 0;
		else
			oAll[k] = 3;
		end
	end

	local	k, v;
	for k, v in pairs(RepQTrackByKrbrEUPrdmr) do
		if ((type(k) == "number") and (oAll[k])) then
			oAll[k] = 1;
		end
	end

	local	k, v;
	for k, v in pairs(oQuests) do
		if (oAll[k]) then
			oAll[k] = 2;
		end
	end

	local	oTotal, k, v = { [0] = 0, [1] = 0, [2] = 0, [3] = 0 };
	for k, v in pairs(oAll) do
		oTotal[v] = oTotal[v] + 1;
	end

	DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Of " .. (oTotal[0] + oTotal[1] + oTotal[2]) .. " quests, you completed " .. oTotal[1] .. ", which leaves " .. (oTotal[0] + oTotal[2]) .. " quests to complete. Of the latter, your questlog contains " .. oTotal[2] .. " quests in progress. As you are level " .. iLevel .. ", this didn't include " .. oTotal[3] .. " quests being 8 or more levels higher.");
end

function	RepQTracker.SlashCmdSearch(args, iCounter)
	if (iCounter < 2) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Find quests of a specific level range for a specific reputation. Possible arguments: valid reputation, level from, level to, min rep gain.");
		return
	end

	local	oFactionNames, k, v = {};
	for k, v in pairs(RepQTrackByKrbrEUPrdmr.Config.Factions) do
		if (ReputationQuestTrackerFactionName[k]) then
			oFactionNames[ReputationQuestTrackerFactionName[k].Name] = k;
		end
	end

	local	sFactionEN = oFactionNames[args[2]];
	if (sFactionEN == nil) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: <" .. args[2] .. "> is not a valid reputation. (1)");
		return
	end

	local	oRepTable = ReputationQuestTrackerFactionGain[sFactionEN];
	local	oQuestTable = ReputationQuestTrackerQuestData[ReputationQuestTrackerFactionName[sFactionEN].Group];
	if ((oRepTable == nil) or (oQuestTable == nil)) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: <" .. args[2] .. "> is not a valid reputation. (2)");
		return
	end

	local	iLevelFrom, iLevelTo, iRepMin = 1, 80, 1;
	if (args[3]) then
		iLevelFrom = tonumber(args[3]) or iLevelFrom;
	end
	if (args[4]) then
		iLevelTo = tonumber(args[4]) or iLevelTo;
	end
	if (args[5]) then
		iRepMin = tonumber(args[5]) or iRepMin;
	end

	DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Looking for <" .. args[2] .. "> in range " .. iLevelFrom .. " to " .. iLevelTo .. ", at least " .. iRepMin .. " reputation gain.");

	local	oList, k, v = {};
	for k, v in pairs(oRepTable) do
		local	oQuest = oQuestTable[k];
		if (oQuest and (oQuest.Level >= iLevelFrom) and (oQuest.Level <= iLevelTo) and (v >= iRepMin)) then
			if ((RepQTrackByKrbrEUPrdmr[k] == nil) and (oQuests[k] == nil)) then
				tinsert(oList, k);
			end
		end
	end

	if (next(oList) == nil) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: No quest missing for reputation " .. args[2] .. " in that level range.");
	else
		local	iMax, i;
		i = 0;
		for k, v in pairs(oList) do
			i = i + 1;
			if (i <= 5) then
				DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Quest " .. v .. " level " .. oQuestTable[v].Level .. " called <" .. oQuestTable[v].Title .. "> in zone " .. oQuestTable[v].Zone .. "."); 
			end
		end

		if (i > 5) then
			DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: " .. (i - 5) .. " more known.");
		end
	end
end

function	RepQTracker.SlashCmdAddRemove(args, iCounter)
	if (iCounter ~= 2) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Manual forced (res-)setting of quest. Required argument: quest id");
		return
	end

	local	k = tonumber(args[2]);
	if ((k == nil) or (k == 0)) then
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Required argument 'quest id' must be numeric.");
		return
	end

	if (args[1] == "add") then
		RepQTrackByKrbrEUPrdmr[k] = { At = time(), Level = UnitLevel("player") + UnitXP("player") / UnitXPMax("player") };
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Quest " .. k .. " stored as completed.");
	elseif (args[1] == "remove") then
		RepQTrackByKrbrEUPrdmr[k] = nil;
		DEFAULT_CHAT_FRAME:AddMessage("ReputationQuestTracker: Quest " .. k .. " not longer stored as completed.");
	end
end

local	RepQFrame = CreateFrame("Frame", nil);
RepQFrame:SetScript("OnEvent", RepQFrame_OnEvent);
RepQFrame:SetScript("OnUpdate", RepQFrame_OnUpdate);
RepQFrame:RegisterEvent("ADDON_LOADED");

