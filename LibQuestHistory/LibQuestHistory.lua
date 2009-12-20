
LIBQUESTHISTORY_DATAVERSION = 0.54;

-- statistics
MODELL_LibQuestHistoryGlobal = { MetaInfo = {}, Statistics = {} };
-- actual data
MODELL_LibQuestHistoryPerChar = {
	MetaInfo = { Version = LIBQUESTHISTORY_DATAVERSION, Delay = 90 },
	QuestIDs = {},
	-- QuestIDsRaw = {}
};

LibQuestHistoryGlobal = MODELL_LibQuestHistoryGlobal;
LibQuestHistoryPerChar = MODELL_LibQuestHistoryPerChar;

local	LQHG;
local	LQHPC;

function	LibQuestHistory_Check(iQuest)
	local	iBucketSize = LQHPC.MetaInfo.BucketSize;

	local	iBucket = 1 + math.floor((iQuest - 1) / iBucketSize);
	if (LQHPC.QuestIDs[iBucket] == nil) then
		return false;
	end

	local	iKey = iQuest % iBucketSize;
	local	iBit = iKey % 25;
	iKey = (iKey - iBit) / 25;
	local	iValue = LQHPC.QuestIDs[iBucket][1 + iKey] or 0;
	local	iMask = bit.lshift(1, iBit);
	if (bit.band(iValue, iMask) == iMask) then
		return true;
	end

	return false;
end

local	function	Store(iQuest)
	local	iBucketSize = LQHPC.MetaInfo.BucketSize;

	local	iBucket = 1 + math.floor((iQuest - 1) / iBucketSize);
	if (LQHPC.QuestIDs[iBucket] == nil) then
		LQHPC.QuestIDs[iBucket] = {};
	end

	local	iKey = iQuest % iBucketSize;
	local	iBit = iKey % 25;
	iKey = (iKey - iBit) / 25;
	local	iValue = LQHPC.QuestIDs[iBucket][1 + iKey] or 0;
	local	iMask = bit.lshift(1, iBit);
	if (bit.band(iValue, iMask) == 0) then
--		local	iValueOld = iValue;

		iValue = bit.bor(iValue, iMask);
		LQHPC.QuestIDs[iBucket][1 + iKey] = iValue;

--		LQHPC.QuestIDsRaw[iQuest] = { iBucket = iBucket, iBit = iBit, iKey = 1 + iKey, iValueOld = iValueOld, iValueNew = iValue };

		return true;
	end

	return false;
end

local	oEventframe = CreateFrame("Frame", nil, UIParent);

local	function	QueryQuestsCompleted_Hook()
	local	sStack = debugstack();
	-- DEFAULT_CHAT_FRAME:AddMessage("CB: " .. sStack);

	local	bIsMine = false;
	local	iPos1, iPos2 = string.find(sStack, "[C]: in function `QueryQuestsCompleted'", 1, true);
	if (iPos2) then
		if (strfind(sStack, "LibQuestHistory.lua", iPos2, true)) then
			-- DEFAULT_CHAT_FRAME:AddMessage("QQC_H: Mine.");
			bIsMine = true;
		else
			-- DEFAULT_CHAT_FRAME:AddMessage("QQC_H: Not mine. (2)");
		end
	else
		-- DEFAULT_CHAT_FRAME:AddMessage("QQC_H: Not mine. (1)");
	end

	if (not bIsMine) then
		-- if this is not ours, backoff for 10m
		oEventframe.iTimer = 600;
	end
end

local	function	OnEvent(oFrame, sEvent, ...)
	if (sEvent == "ADDON_LOADED") then
		local	sWhich = ...;
		if (sWhich == "LibQuestHistory") then
			oEventframe:RegisterEvent("PLAYER_ENTERING_WORLD");
			oEventframe:RegisterEvent("PLAYER_LEAVING_WORLD");
			oEventframe:RegisterEvent("QUEST_QUERY_COMPLETE");
			hooksecurefunc("QueryQuestsCompleted", QueryQuestsCompleted_Hook);

			LQHG = LibQuestHistoryGlobal;
			LQHPC = LibQuestHistoryPerChar;
			local	iVersion = LQHPC.MetaInfo.Version or 0;
			if (iVersion < LIBQUESTHISTORY_DATAVERSION) then
				LibQuestHistoryPerChar = MODELL_LibQuestHistoryPerChar;
				LQHPC = LibQuestHistoryPerChar;
			end

			oEventframe.iNext = LQHPC.MetaInfo.Delay or 90;
			if (LQHPC.MetaInfo.BucketSize == nil) then
				LQHPC.MetaInfo.BucketSize = 1000;
			end
		end
	end

	if (sEvent == "PLAYER_ENTERING_WORLD") then
		oFrame.iTimer = 0.6 * oFrame.iNext;
	end
	if (sEvent == "PLAYER_LEAVING_WORLD") then
		oFrame.iTimer = nil;
	end

	if (sEvent == "QUEST_QUERY_COMPLETE") then
		local	oData = GetQuestsCompleted();
		local	iCntTotal, iCntNew, k, v = 0, 0;
		for k, v in pairs(oData) do
			if (Store(k)) then
				iCntNew = iCntNew + 1;
			end

			iCntTotal = iCntTotal + 1;
		end

--		if (iCntNew > 0) then
			DEFAULT_CHAT_FRAME:AddMessage("LQH: " .. iCntNew .. " new quests added, " .. (iCntTotal - iCntNew) .. " old quests seen again...");
--		end

		if (oFrame.iTimer == nil) then
			if (iCntNew == 0) then
				oFrame.iNext = math.min(900, oFrame.iNext + 30);
			else
				oFrame.iNext = 120;
			end

			LQHPC.MetaInfo.Delay = oFrame.iNext;
			oFrame.iTimer = oFrame.iNext;
		end
	end
end

local	function	OnUpdate(oFrame, iElapsed)
	if (oFrame.iTimer) then
		oFrame.iTimer = oFrame.iTimer - iElapsed;
		if (oFrame.iTimer < 0) then
			oFrame.iTimer = nil;
			QueryQuestsCompleted();
		end
	end
end

oEventframe:RegisterEvent("ADDON_LOADED");
oEventframe:SetScript("OnEvent", OnEvent);
oEventframe:SetScript("OnUpdate", OnUpdate);

--
--
--

function	LQHStatus()
	if (oEventframe.iTimer) then
		DEFAULT_CHAT_FRAME:AddMessage("LQH: Next request in " .. oEventframe.iTimer .. " seconds.");
	else
		DEFAULT_CHAT_FRAME:AddMessage("LQH: Request sent, waiting for reply...");
	end
end

