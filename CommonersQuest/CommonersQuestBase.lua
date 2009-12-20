
-- Outside of global anchoer, COMBAT_LOG should be handled as lean as possible
CommonersQuestTracking = {};

-- global anchor
CommonersQuest = {};
CommonersQuest.MaxLevel = 80;

-- tiny all-purpose helpers
CommonersQuest.Helpers = {};

-- cross-module slider for various #-choices
CommonersQuest.Slider = {};

-- static popups (indirectly added to allow localization)
CommonersQuest.StaticPopups = {};

-- special functions
CommonersQuest.SecureHooks = {};
CommonersQuest.Initializers = {};

-- version anchor
CommonersQuest.Version = {};		-- container for version info
CommonersQuest.Version[""] = {};	-- my own version

-- frames anchors
CommonersQuest.FrameMain = {};
CommonersQuest.FrameProgressPanel = {};
CommonersQuest.FrameRewardPanel = {};
CommonersQuest.FrameDetailPanel = {};
CommonersQuest.FrameMoney = {};
CommonersQuest.FrameGreetingPanel = {};

-- questlog
CommonersQuest.Log = {};

-- editing stuff
CommonersQuest.QuestEdit = {};
CommonersQuest.Menu = {};

BINDING_HEADER_COMMONERSQUEST = "CommonersQuest by Kärbär";
BINDING_NAME_COMMONERSQUEST_KRBREUPRDMRE_EDIT = "Opens or closes CommonersQuest's edit window";
BINDING_NAME_COMMONERSQUEST_KRBREUPRDMRE_QLOG = "Opens or closes CommonersQuest's questlog";

-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --

local	CQInitOk = false;

local	CQData = nil;
local	CQDataX = nil;
local	CQDataGlobal = nil;
local	CQDataItems = nil;

local	CQH = CommonersQuest.Helpers;

function	CommonersQuest.Initializers.Base(CQDataMain, CQDataXMain, CQDataGlobalMain, CQDataItemsMain)
	CQInitOk = true;
	CQData = CQDataMain;
	CQDataX = CQDataXMain;
	CQDataGlobal = CQDataGlobalMain;
	CQDataItems = CQDataItemsMain;
end

local	CharsForByteToChars = "0123456789abcdef";
local	function	ByteToChars(iByte)
	if ((iByte < 0) or (iByte > 255)) then
		return "xx";
	else
		local	LoIndex = bit.band(iByte, 15);
		local	HiByte = math.floor(iByte / 16);
		local	HiIndex = bit.band(HiByte, 15);
		return (strsub(CharsForByteToChars, 1 + HiIndex, 1 + HiIndex) .. strsub(CharsForByteToChars, 1 + LoIndex, 1 + LoIndex));
	end
end

local	BytesForCharsToByte = nil;
local	function	CharsToByte(sChars)
	if ((type(sChars) ~= "string") or (strlen(sChars) ~= 2)) then
		return 0;
	else
		if (BytesForCharsToByte == nil) then
			BytesForCharsToByte = {};
			local	iCnt, i = strlen(CharsForByteToChars);
			for i = 1, iCnt do
				BytesForCharsToByte[strbyte(strsub(CharsForByteToChars, i, i))] = i - 1;
			end
		end

		local	iHi = BytesForCharsToByte[strbyte(strsub(sChars, 1, 1))] or 0;
		local	iLo = BytesForCharsToByte[strbyte(strsub(sChars, 2, 2))] or 0;

		return (iHi * 16 + iLo);
	end
end

local	iModulus = 2^24;

-- local	iPrime = 2^32 - 7;	-- TODO: get an actual prime here
function	CommonersQuest.Helpers.Encode(sText, iKey)
	if ((type(sText) ~= "string") or (type(iKey) ~= "number")) then
		return sText;
	else
		local	iSalt = math.floor(random(65536));
local	sDebug = "Salt: " .. iSalt;
		local	iByte = math.floor(iSalt / 256);
		local	sResult = ByteToChars(iByte) .. ByteToChars(bit.band(iSalt, 255));

		local	iLow, iHigh, iCarry, iByteIn = iSalt, 0;
		local	iCnt, i = strlen(sText);
		for i = 1, iCnt do
			iLow = iLow * iKey;
sDebug = sDebug .. "\n" .. iLow;
			iCarry = math.floor(iLow / iModulus);
			iLow = math.floor(iLow % iModulus);

			iHigh = iHigh * iKey + iCarry;
sDebug = sDebug .. "/" .. iHigh;
			iCarry = math.floor(iHigh / iModulus);
			iHigh = math.floor(iHigh % iModulus);

			iByteIn = strbyte(sText, i, i);
			iByte = (iLow % 256 + iByteIn) % 256;
sDebug = sDebug .. " ~~ " .. iHigh .. "/" .. iLow .. "::" .. iByteIn .. "=>" .. iByte;
			iLow = iLow + iCarry + iByteIn;

			sResult = sResult .. ByteToChars(iByte);
		end

-- CQH.CommChat("DbgSpam", nil, sDebug);

		return "$1~" .. sResult;
	end
end

function	CommonersQuest.Helpers.Decode(sText, iKey)
	if ((type(sText) ~= "string") or (type(iKey) ~= "number")) then
		return sText;
	elseif (strsub(sText, 1, 3) == "$1~") then
		sText = strsub(sText, 4);

		local	iSalt = CharsToByte(strsub(sText, 1, 2)) * 256 + CharsToByte(strsub(sText, 3, 4));
local	sDebug = "Salt: " .. iSalt;
		local	sResult = "";

		local	iLow, iHigh, iCarry, iPos, iByteOut, iByteIn = iSalt, 0;
		local	iCnt, i = strlen(sText) / 2;
		for i = 3, iCnt do
			iLow = iLow * iKey;
sDebug = sDebug .. "\n" .. iLow;
			iCarry = math.floor(iLow / iModulus);
			iLow = math.floor(iLow % iModulus);

			iHigh = iHigh * iKey + iCarry;
sDebug = sDebug .. "/" .. iHigh;
			iCarry = math.floor(iHigh / iModulus);
			iHigh = math.floor(iHigh % iModulus);

			iPos = i * 2 - 1;
--sDebug = sDebug .. " " .. strsub(sText, iPos, iPos + 1) .. "?";
			iByteOut = CharsToByte(strsub(sText, iPos, iPos + 1));
			iByteIn = (512 + iByteOut - (iLow % 256)) % 256;
sDebug = sDebug .. " ~~ " .. iHigh .. "/" .. iLow .. "::" .. iByteOut .. "=>" .. iByteIn;
			iLow = iLow + iCarry + iByteIn;

			sResult = sResult .. strchar(iByteIn);
		end

-- CQH.CommChat("DbgSpam", nil, sDebug);

		return sResult;
	end
end

function	CommonersQuest.Helpers.MoneyToString(iAmount)
	local	sResult = "";
	if (iAmount >= 100 * 100) then
		local	iGold = math.floor(iAmount / 10000);
		iAmount = iAmount - iGold * 10000;
		sResult = sResult .. iGold .. "g ";
	end

	if (iAmount >= 100) then
		local	iSilver = math.floor(iAmount / 100);
		iAmount = iAmount - iSilver * 100;
		sResult = sResult .. iSilver .. "s ";
	end

	if (iAmount > 0) then
		sResult = sResult .. iAmount .. "c ";
	end

	return strsub(sResult, 1, -2);
end

function	CommonersQuest.Helpers.TableToString(oTable)
	local	sType = type(oTable);
	if (sType ~= "table") then
		if (sType == "nil") then
			return "<nil>";
		else
			return strsub(type(oTable), 1, 1) .. "-" .. CQH.AllToString(oTable);
		end
	end

	local	sResult, k, v, t = "";
	for k, v in pairs(oTable) do
		tk = type(k);
		tv = type(v);
		if (tv == "table") then
			sResult = sResult .. strsub(tk, 1, 1) .. "-" .. k .. " = { " .. CQH.TableToString(v) .. " }, ";
		else
			sResult = sResult .. strsub(tk, 1, 1) .. "-" .. k .. " = " .. strsub(tv, 1, 1) .. "-" .. CQH.AllToString(v) .. ", ";
		end
	end

	return sResult;
end

function	CommonersQuest.Helpers.AllToString(oAnything)
	if (oAnything == nil) then
		return "<nil>";
	else
		local	sType = type(oAnything);
		if ((sType == "string") or (sType == "number")) then
			return oAnything;
		elseif (sType == "boolean") then
			if (oAnything) then
				return "{true}";
			else
				return "{false}";
			end
		else
			return "<" .. sType .. ">";
		end
	end
end

function	CommonersQuest.Helpers.TableIsEmpty(oTable)
	return (type(oTable) ~= "table") or (next(oTable) == nil);
end

function	CommonersQuest.Helpers.InitTable(oTable, oKey)
	if ((type(oTable) == "table") and (oKey ~= nil)) then
		if (type(oTable[oKey]) ~= "table") then
			oTable[oKey] = {};
		end
	else
		CQH.CommChat("DbgImportant", "Quest", "Oops: Broken initializer call -> " .. debugstack());
	end
end

function	CommonersQuest.Helpers.CopyTable(oTableFrom)
	local	function	Traverse(oTableIn, oTableOut)
			local	k, v;
			for k, v in pairs(oTableIn) do
				if (type(v) ~= "table") then
					oTableOut[k] = v;
				else
					oTableOut[k] = Traverse(v, {});
				end
			end

			return oTableOut;
		end

	local	oTableTo = {};
	return Traverse(oTableFrom, oTableTo);
end

function	CommonersQuest.Helpers.StripLevelFromItemLink(sItemLink)
	local	sReturn = sItemLink;
	if (sItemLink) then
		local	iPos = strlen(sItemLink);
		while (iPos > 0) do
			if (strsub(sItemLink, iPos, iPos) == ':') then
				break;
			end
			iPos = iPos - 1;
		end
		if (strsub(sItemLink, iPos, iPos) == ':') then
			sReturn = strsub(sItemLink, 1, iPos - 1);
--			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Cutting " .. sItemLink .. " at " .. iPos .. " to " .. sReturn);
		else
			CQH.CommChat("DbgImportant", "Item", "SLFIL: NOT cutting " .. sItemLink .. " at " .. iPos .. "?");
		end
	else
		CQH.CommChat("DbgImportant", "Item", "SLFIL: NOT cutting " .. sItemLink .. "?");
	end

	return sReturn;
end

function	CommonersQuest.Helpers.ValidForBinding(sItem)
	-- level already stripped!
	local	_, _, iQuality, _, _, _, _, iItemStackCount = GetItemInfo(sItem);
	if ((iQuality >= 2) or (iItemStackCount > 1)) then
		return false
	end

	if (strsub(sItem, -2) == ":0") then
		return false;
	end

	return true;
end

function	CommonersQuest.Helpers.CharQuestToObj(sPlayer, iID)
	if (iID < 1000000) then
		local	k, v;
		for k, v in pairs(CommonersQuest.QuestDB) do
			if (iID == v.ID) then
				return v;
			end
		end
	elseif (sPlayer) then
		if (CQData[sPlayer] and
		    CQData[sPlayer].QuestsCustom) then
			local	k, v;
			for k, v in pairs(CQData[sPlayer].QuestsCustom) do
				if (iID == v.ID) then
					return v;
				end
			end
		end
	else
		local	k, v;
		for k, v in pairs(CQDataGlobal.CustomQuests) do
			if (iID == v.ID) then
				return v;
			end
		end
	end
end

function	CommonersQuest.Helpers.QuestToPseudoLink(iID, sTitle, sPlayer)
	local	sTitleReal = sTitle;
	if (sTitle == nil) then
		local	oQuest = CommonersQuest.Helpers.CharQuestToObj(sPlayer, iID);
		if (oQuest == nil) then
			sTitleReal = nil;
			if (iID < 1000000) then
				sTitle = "Missing info: <GlobalQuest::" .. iID .. ">";
			else
				sTitle = "Missing info: <" .. (sPlayer or "<Unknown>") .. "::" .. iID .. ">";
			end
		else
			sTitle = oQuest.Title;
			sTitleReal = sTitle;
		end
	end

	return (iID .. ": |cFF80A0FF[" .. sTitle .. "]|r"), sTitleReal;
end

function	CommonersQuest.Helpers.FindItemInBags(xItemID)
	-- xItemID:  string (full link) or number (just an itemid)
	local	iBag;
	for iBag = 0, 4 do
		local	iSlotCnt, iSlot = GetContainerNumSlots(iBag);
		for iSlot = 1, iSlotCnt do
			local	sItem = GetContainerItemLink(iBag, iSlot);
			if (sItem) then
				local	sItemLink = string.match(sItem, "|H(item[:%d%-]+)|h");
				if (sItemLink) then
					sItemLink = CQH.StripLevelFromItemLink(sItemLink);
					if (type(xItemID) == "string") then
						if (xItemID == sItemLink) then
							return iBag, iSlot, sItem
						end
					elseif (type(xItemID) == "number") then
						local	iItemID = tonumber(string.match(sItemLink, "item:(%d+)"));
						if (xItemID == iItemID) then
							return iBag, iSlot, sItem;
						end
					end
				end
			end
		end
	end
end

function	CommonersQuest.Helpers.CountItemInBags(xItemID)
	-- xItemID:  string (full link) or number (just an itemid)
	local	iTotal, iBag = 0;
	for iBag = 0, 4 do
		local	iSlotCnt, iSlot = GetContainerNumSlots(iBag);
		for iSlot = 1, iSlotCnt do
			local	sItem = GetContainerItemLink(iBag, iSlot);
			if (sItem) then
				local	sItemLink = string.match(sItem, "|H(item[:%d%-]+)|h");
				if (sItemLink) then
					sItemLink = CQH.StripLevelFromItemLink(sItemLink);
					if (type(xItemID) == "string") then
						if (xItemID == sItemLink) then
							local	_, iCount = GetContainerItemInfo(iBag, iSlot);
							iTotal = iTotal + iCount;
						end
					elseif (type(xItemID) == "number") then
						local	iItemID = tonumber(string.match(sItemLink, "item:(%d+)"));
						if (xItemID == iItemID) then
							local	_, iCount = GetContainerItemInfo(iBag, iSlot);
							iTotal = iTotal + iCount;
						end
					end
				end
			end
		end
	end

	return iTotal;
end

function	CommonersQuest.Helpers.CollateNumItemsInBags(iItemID, iCount, bSilent)
	-- xItemID:  string (full link) or number (just an itemid)
	local	_, sLink, _, _, _, _, _, iItemStackCount = GetItemInfo(iItemID);
	if (iItemStackCount < iCount) then
		if (not bSilent) then
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Item " .. sLink .. " is not splitting as expected!");
		end
		return
	end

	local	oData, iTotal, iBag = {}, 0;
	for iBag = 0, 4 do
		local	iSlotCnt, iSlot = GetContainerNumSlots(iBag);
		for iSlot = 1, iSlotCnt do
			local	sItem = GetContainerItemLink(iBag, iSlot);
			if (sItem) then
				local	sItemInSlotID = string.match(sItem, "item:(%d+):");
				if (sItemInSlotID) then
					local	iItemInSlotID = tonumber(sItemInSlotID);
					if (iItemID == iItemInSlotID) then
						if (iItemStackCount == 1) then
							return iBag, iSlot, sLink, false;
						end

						local	_, iCount = GetContainerItemInfo(iBag, iSlot);
						local	oEntry = { Count = iCount, Bag = iBag, Slot = iSlot };
						tinsert(oData, oEntry);
						iTotal = iTotal + iCount;
					end
				end
			end
		end
	end

	if (iTotal < iCount) then
		if (not bSilent) then
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Item " .. sLink .. ": insuffient quantity!");
		end
		return
	end

	-- first, hope for the best...
	local	iTooMuch = 1000000;

	local	oCandidate;

	local	iBiggestCnt, iBiggestIndex, iBiggestBag, iBiggestSlot, k, v = 0;
	for k, v in pairs(oData) do
		if (iBiggestCnt < v.Count) then
			iBiggestIndex = k;
			iBiggestCnt = v.Count;
			iBiggestBag = v.Bag;
			iBiggestSlot = v.Slot;
		end

		if (v.Count == iCount) then
			-- yay, best case :)
			return v.Bag, v.Slot, sLink, false;
		elseif (v.Count > iCount) then
			local	iTooMuchThis = v.Count - iCount;
			if (iTooMuchThis < iTooMuch) then
				iTooMuch = iTooMuchThis;
				oCandidate = v;
			end
		end
	end

	if (oCandidate) then
		return oCandidate.Bag, oCandidate.Slot, sLink, true;
	end

	-- stack up? too much trouble. let the user do some work ~
	if (not bSilent) then
		DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Item " .. sLink .. ": no stack found has suffient quantity! Please cleanup your inventory and create a pile of at least " .. iCount .. " pieces.");
	end
end

function	CommonersQuest.Helpers.IsValidTarget()
	if (UnitIsPlayer("target") and UnitIsFriend("player", "target")) then
		local	_, sServer = UnitName("target");
		if ((sServer ~= nil) and (sServer ~= "")) then
			return false;
		end

		local	DebugOrNotPlayer = CQDataX.Debug == true;
		if (not DebugOrNotPlayer) then
			DebugOrNotPlayer = not UnitIsUnit("player", "target");
			CQH.CommChat("DbgSpam", nil, "!UnitIsUnit => " .. CommonersQuest.Helpers.AllToString(DebugOrNotPlayer));
		end
		if (DebugOrNotPlayer) then
			return true;
		end
	end

	return false;
end

function	CommonersQuest.Helpers.RequirementToTextBasic(oReq, bEditMode)
	if (type(oReq) ~= "table") then
		CQH.CommChat("DbgInfo", "Edit", "CQH.R2TB: oReq not a table. Via => " .. debugstack());
	end

	local	sText, sType = nil, oReq.Type;
	if (sType == "Emote") then
		local	sTarget = oReq.TargetDesc;
		if (sTarget == nil) then
			sTarget = oReq.TargetName;
		end
		sText = "/" .. oReq.Emote .. " to: " .. (sTarget or "<missing target!!>");
		if (bEditMode) then
			if (oReq.TargetName) then
				sText = sText .. " (actual name: \"" .. (oReq.TargetName or "<missing target!!>")  .. "\")";
			end
		end
	elseif (sType == "Kill") then
		local	sTarget = oReq.TargetDesc;
		if (sTarget == nil) then
			sTarget = oReq.TargetName;
		end
		sText = "Murder: " .. (sTarget or "<missing target!!>");
		if (bEditMode) then
			if (oReq.TargetName) then
				sText = sText .. " (actual name: \"" .. (oReq.TargetName or "<missing target!!>")  .. "\")";
			end
		end
	elseif (sType == "Survive") then
		local	sTarget = oReq.TargetDesc;
		if (sTarget == nil) then
			sTarget = oReq.TargetName;
		end
		sText = "Save: " .. (sTarget or "<missing target!!>");
		if (bEditMode) then
			if (oReq.TargetName) then
				sText = sText .. " (actual name: \"" .. (oReq.TargetName or "<missing target!!>")  .. "\")";
			end
		end
	elseif (sType == "Duel") then
		if (oReq.PlayerName) then
			sText = oReq.PlayerName;
			if (oReq.PlayerDesc) then
				sText = oReq.PlayerDesc;
			end
		elseif (oReq.PlayerFaction) then
			sText = oReq.PlayerFaction;
		else
			sText = "???";
		end

		if (oReq.PlayerRace) then
			sText = sText .. " " .. oReq.PlayerRace;
		end
		if (oReq.PlayerClass) then
			sText = sText .. " " .. oReq.PlayerClass;
		end

		if (oReq.DuelResult == nil) then
			oReq.DuelResult = "lose";
		end
		sText = "Duel: " .. oReq.DuelResult .. " vs. " .. sText;

		if (oReq.DuelArea) then
			sText = sText .. " in public";
		end
		if (oReq.DuelStreak) then
			sText = sText .. ", must streak";
		end
		if (bEditMode and oReq.PlayerName and oReq.PlayerDesc) then
			sText = sText .. " (actual player name: \"" .. oReq.PlayerName .. "\")";
		end
	elseif (sType == "Loot") then
		local	sName = oReq.ItemName;
		if (sName == nil) then
			sName = GetItemInfo("item:" .. oReq.ItemID);
		end
		sText = "Grab: " .. (sName or "<missing item!!>");
	elseif (sType == "Riddle") then
		sText = "Answer: " .. (oReq.RiddleReference or "<missing reference!!>") .. "?";
		if (bEditMode) then
			local	iLockout = oReq.RiddleLockout or 1;
			if (iLockout < 90) then
				sText = sText .. "\n=> Lockout: " .. iLockout .. " minutes";
			else
				local	sLockout = iLockout % 60;
				if (sLockout < 60) then
					sLockout = "0" .. sLockout;
				end
				sLockout = math.floor(iLockout / 60) .. "h " .. sLockout .. "m";
				sText = sText .. "\n=> Lockout: " .. iLockout .. " minutes";
			end
			sText = sText .. "\n=> Solution: " .. (oReq.RiddleSolution or "<missing solution!!>")
				      .. "\n=> Hint: " .. (oReq.RiddleShortDesc or "<missing short desc/hint!!>");
		end
	end

	return sText;
end

function	CommonersQuest.Helpers.RequirementToTextForEdit(oReq)
	local	sText = CQH.RequirementToTextBasic(oReq, true);
	if (oReq.Count and (oReq.Count > 1)) then
		sText = sText .. " - " .. oReq.Count;
	end

	return sText;
end

function	CommonersQuest.Helpers.RequirementToText(oReq, xProgress, bFailed, bCompleted)
	local	sText, sType, iIsCount = CQH.RequirementToTextBasic(oReq), oReq.Type;
	if (sType == "Kill") then
		local	iMax, iCurr = 1, 0;
		if (xProgress) then
			iCurr = xProgress;
		end
		if (oReq.Count) then
			iMax = oReq.Count;
		end
		sText = sText .. " - " .. iCurr .. "/" .. iMax;
	elseif (sType == "Survive") then
		if (bFailed) then
			sText = sText .. " - FAILED.";
		end
	elseif (sType == "Loot") then
		-- must be checked every time
		local	iReqCount = oReq.Count or 1;
		bCompleted = xProgress and (xProgress >= iReqCount);
	elseif (sType == "Riddle") then
		if (bCompleted) then
			sText = sText .. " - solved.";
		elseif ((xProgress ~= nil) and (xProgress ~= 0) and (xProgress ~= "")) then
			bCompleted = true;
			sText = sText .. " - guessing \"" .. xProgress .. "\".";
		end
	end

	return sText, sType, bCompleted, iIsCount;
end

function	CommonersQuest.Helpers.FormatRequirements(oQuest, oFailed, oProgress, oCompleted, fSetButton, bEditMode)
	local	oRequirements = oQuest.Requirements;
	local	sDescResultTotal = "";
	local	bQuestComplete, bGotRiddle, i = (bEditMode ~= true), false;
	for i = 1, #oRequirements do
		local	oRequire = oRequirements[i]
		local	xProgress = oProgress[i] or 0;
		local	bFailed = oFailed[i] ~= nil;
		local	bCompleted, sCompleted = (oCompleted[i] ~= nil), "";
		local	sDescEnd, sDescResult = "";
		if (bCompleted) then
--			sCompleted = ": 1/1";
			sDescResult = "\n|cFF333333";		-- ~0.2³
			sDescEnd = "|r";
		else
--			sCompleted = ": 0/1";
			sDescResult = "\n";
		end

		if (oRequire.Type == "Loot") then
			xProgress = CQH.CountItemInBags(oRequire.ItemID);
			if (fSetButton) then
				fSetButton(oRequire, xProgress);
			end
			local	sText, sType;
			sText, sType, bCompleted = CommonersQuest.Helpers.RequirementToText(oRequire, xProgress, bFailed, bCompleted); 
		else
			local	sText, _;
			if (bEditMode == true) then
				sText = CommonersQuest.Helpers.RequirementToTextForEdit(oRequire);
			else
				sText, _, bCompleted = CommonersQuest.Helpers.RequirementToText(oRequire, xProgress, bFailed, bCompleted);
			end
			if (sText) then
				sDescResult = sDescResult .. sText;
			else
				CQH.CommChat("DbgImportant", "Quest", "FR: Fail: " .. oRequire.Type);
				bFail = true;
			end
		end

		sDescResult = sDescResult .. sDescEnd;

		if (bCompleted ~= true) then
			bQuestComplete = false;
		end

		if (oRequire.Type ~= "Loot") then
			sDescResultTotal = sDescResultTotal .. sDescResult;
		end
		if (oRequire.Type == "Riddle") then
			bGotRiddle = true;
		end
	end

	return bQuestComplete, sDescResultTotal, bGotRiddle;
end

function	CommonersQuest.Helpers.InitRewardContainer(iQuestID)
	if (CQDataGlobal.Rewards[iQuestID] == nil) then
		CQDataGlobal.Rewards[iQuestID] = {};
		if (iQuestID < 1000000) then
			CQDataGlobal.Rewards[iQuestID]["DEFAULT"] = {};
			local	oGroup = CQDataGlobal.Rewards[iQuestID]["DEFAULT"];
			CQH.InitTable(oGroup, "Set");
			CQH.InitTable(oGroup, "State");
			oGroup.State.AvailableCount = -1;

			local	oQuest, k, v;
			for k, v in pairs(CommonersQuest.QuestDB) do
				if (v.ID == iQuestID) then
					oQuest = v;
					break;
				end
			end

			if (oQuest) then
				local	k, v;
				for k, v in pairs(oQuest.Reward) do
					tinsert(oGroup.Set, v);
				end
			end
		end
	end
end

function	CommonersQuest.Helpers.InitRewards(iQuestID, IDorPlayer, bSilent)
	if (type(iQuestID) ~= "number") then
		CQH.CommChat("DbgImportant", "Quest", "InitRewards: Invalid quest identifier. Via => " .. debugstack());
		return
	end
	if (IDorPlayer == nil) then
		CQH.CommChat("DbgImportant", "Quest", "InitRewards: Missing proper group identifier => " .. debugstack());
		return
	end

	CQH.InitRewardContainer(iQuestID);

	local	iKey, oRewards, oState, oGroup;

	local	oStateOldest = { LockedAt = time() + 600 };

	if (IDorPlayer == -2) then
		local	iIndex, k, v;
		for k, v in pairs(CQDataGlobal.Rewards[iQuestID]) do
			if ((v.State.AvailableCount ~= 0) and 
			    ((#v.Set > 0) or (iQuestID < 1000000))) then	-- default quests always have a valid reward (money)
				iIndex = k;
				break;
			end
		end

		if (iIndex) then
			iKey = iIndex;
			oGroup = CQDataGlobal.Rewards[iQuestID][iIndex];
		end
	elseif (IDorPlayer == -1) then
		iKey = time();
		CQDataGlobal.Rewards[iQuestID][iKey] = {};
		oGroup = CQDataGlobal.Rewards[iQuestID][iKey];
	elseif (type(IDorPlayer) == "number") then
		iKey = IDorPlayer;
		oGroup = CQDataGlobal.Rewards[iQuestID][iKey];
	elseif (type(IDorPlayer) == "string") then
		local	iTime, iIndex, k, v = time();
		for k, v in pairs(CQDataGlobal.Rewards[iQuestID]) do
			if (v.State.LockedTo) then
				if (v.State.LockedTo == IDorPlayer) then
					iIndex = k;
					break;
				elseif (iTime - v.State.LockedAt > 300) then
					-- unlock unclaimed reward after 5 minutes
					v.State.LockedAt = nil;
					v.State.LockedTo = nil;
					v.State.Cookie = nil;
				elseif (oStateOldest.LockedAt > v.State.LockedAt) then
					oStateOldest.LockedAt = v.State.LockedAt;
					oStateOldest.LockedTo = v.State.LockedTo;
				end
			end
		end

		if (iIndex == nil) then
			for k, v in pairs(CQDataGlobal.Rewards[iQuestID]) do
				if ((v.State.AvailableCount ~= 0) and (v.State.LockedTo == nil) and 
				    ((#v.Set > 0) or (iQuestID < 1000000))) then	-- default quests always have a valid reward (money)
					iIndex = k;
					break;
				end
			end
		end

		if (iIndex) then
			iKey = iIndex;
			oGroup = CQDataGlobal.Rewards[iQuestID][iIndex];
		elseif (not bSilent) then
			CQH.CommChat("DbgInfo", "Quest", "InitRewards: Failed to find a valid reward set for quest " .. iQuestID);
		end
	end

	if (oGroup ~= nil) then
		CQH.InitTable(oGroup, "Set");
		CQH.InitTable(oGroup, "State");

		oRewards = oGroup.Set;
		oState   = oGroup.State;
		oState.AvailableCount = -1;
	elseif (not bSilent and (IDorPlayer ~= -2)) then
		CQH.CommChat("DbgImportant", "Quest", "InitRewards: Failed to find something matching group identifier <" .. IDorPlayer .. "> via => " .. debugstack());
	end

	local	oStateReturn = oState;
	if (oStateReturn == nil) then
		oStateReturn = oStateOldest;
	end

	return oRewards, oStateReturn, iKey;
end

function	CommonersQuest.Helpers.CollateRewards(QuestRef, oRewardsGlobal, oRewardsCurrent, IDorPlayer)
	if (IDorPlayer == nil) then
		CQH.CommChat("DbgImportant", "Quest", "CollateRewards: Missing proper group identifier.");
		return
	end

	if (oRewardsGlobal == nil) then
		if (type(QuestRef) == "number") then
			local	k, v;
			for k, v in pairs(CommonersQuest.QuestDB) do
				if (QuestRef == v.ID) then
					oRewardsGlobal = v.Reward;
					break;
				end
			end
		else
			oRewardsGlobal = QuestRef.Reward;
		end
	end

	local	iKey;
	if (oRewardsCurrent == nil) then
		local	_;
		if (type(QuestRef) == "number") then
			oRewardsCurrent, _, iKey = CQH.InitRewards(QuestRef, IDorPlayer);
		else
			oRewardsCurrent, _, iKey = CQH.InitRewards(QuestRef.ID, IDorPlayer);
		end
	end

	local	oRewardsTotal, iCnt, i = {};

	iCnt = #oRewardsGlobal;
	if (iCnt > 0) then
		for i = 1, iCnt do
			local	oReward = oRewardsGlobal[i];
			if ((oReward.Type ~= "Item") or (oReward.Permanent == true)) then
				tinsert(oRewardsTotal, oReward);
			end
		end
	end

	local	iMoney;
	iCnt = 0;
	if (oRewardsCurrent) then
		iCnt = #oRewardsCurrent;
	end
	if (iCnt > 0) then
		for i = 1, iCnt do
			local	oReward = oRewardsCurrent[i];
			if (oReward.Type == "Item") then
				if (oReward.ItemID < 0) then
					local	iIndex, l, w;
					for l, w in pairs(oRewardsTotal) do
						if ((w.Type == "Item") and w.Permanent and (w.ItemID == - oReward.ItemID)) then
							iIndex = l;
							break;
						end
					end
					if (iIndex) then
						local	iCnt = #oRewardsTotal;
						oRewardsTotal[iIndex] = oRewardsTotal[iCnt];
						oRewardsTotal[iCnt] = 0;
					end
				else
					tinsert(oRewardsTotal, oReward);
				end
			else
				local	bFound, l, w = false;
				for l, w in pairs(oRewardsTotal) do
					if (oReward.Type == w.Type) then
						if (oReward.Type == "Money") then
							iMoney = oReward.Amount;
						end
						bFound = true;
						oRewardsTotal[l] = oReward;
						break;
					end
				end
				if (not bFound) then
					tinsert(oRewardsTotal, oReward);
				end
			end
		end
	end

	if (iMoney and (iMoney == 0)) then
		iCnt = #oRewardsTotal;
		local	iIndex;
		for i = 1, iCnt do
			local	oReward = oRewardsTotal[i];
			if (oReward.Type == "Money") then
				iIndex = i;
				break;
			end
		end

		if (iIndex) then
			local	iCnt = #oRewardsTotal;
			oRewardsTotal[iIndex] = oRewardsTotal[iCnt];
			oRewardsTotal[iCnt] = 0;
		end
	end

	return oRewardsTotal, iKey;
end

function	CommonersQuest.Helpers.SetupRewards(sPrefix, oRewardOther, oRewardItems, sBindingitemLink, bNoBindingItemRequired)
	local	bFail = false;

	local	MoneyFrame = getglobal(sPrefix .. "MoneyFrame");
	MoneyFrame.staticMoney = nil;
	MoneyFrame:Hide();
	getglobal(sPrefix .. "HonorFrame"):Hide();
	getglobal(sPrefix .. "TalentFrame"):Hide();
	getglobal(sPrefix .. "SpellLearnText"):Hide();
	getglobal(sPrefix .. "PlayerTitleFrame"):Hide();

	local	iCntChoose, iCntAlways, bGotMoney, i, oReward = 0, 0;
	for i = 1, #oRewardOther do
		oReward = oRewardOther[i];
		if ((oReward.Type == "Money") and (oReward.Amount > 0)) then
			bGotMoney = true;
		end
	end

	for i = 1, #oRewardItems do
		oReward = oRewardItems[i];
		if (oReward.Type == "Item") then
			if (oReward.Choice) then
				iCntChoose = iCntChoose + 1;
			else
				iCntAlways = iCntAlways + 1;
			end
		elseif ((oReward.Type == "Money") and (oReward.Amount > 0)) then
			bGotMoney = true;
		end
	end

	CQH.CommChat("DbgInfo", "Quest", "ChooseCnt = " .. iCntChoose .. ", AlwaysCnt = " .. iCntAlways .. ", bGotMoney = " .. CQH.AllToString(bGotMoney));

	local	oChooseText = getglobal(sPrefix .. "ItemChooseText");
	local	oReceiveText = getglobal(sPrefix .. "ItemReceiveText");

	local	oChooseAnchor = oChooseText;
	local	oAnywaysAnchor = oReceiveText;
	if (iCntChoose > 0) then
		oChooseText:Show();
		oChooseText:SetText(REWARD_CHOICES);			-- "You can choose one of these rewards:"
		if (sPrefix == "CommonersQuestReward") then
			oChooseText:SetText(REWARD_CHOOSE);			-- "Choose one of these rewards:"
		end
		if  (bGotMoney or (iCntAlways > 0)) then
			oReceiveText:SetText(REWARD_ITEMS);		-- "You receive anyways:"
			oReceiveText:SetPoint("TOPLEFT", sPrefix .. "RewardTitleText", "BOTTOMLEFT", 0, -5);
			oReceiveText:Show();
		else
			oReceiveText:Hide();
			oAnywaysAnchor = oChooseAnchor;
		end
	else
		oChooseText:Hide();
		oChooseAnchor = sPrefix .. "RewardTitleText";
		if (bGotMoney or (iCntAlways > 0)) then
			oReceiveText:SetText(REWARD_ITEMS_ONLY);	-- "You receive:"
			oReceiveText:SetPoint("TOPLEFT", sPrefix .. "RewardTitleText", "BOTTOMLEFT", 0, -5);
			oReceiveText:Show();
		else
			oReceiveText:Hide();
			oAnywaysAnchor = getglobal(sPrefix .. "RewardTitleText");
		end
	end

	local	iCurrChoose, iCurrAlways, iTotal, iRewardOtherCnt, bAnchorTitle, iCnt, oAnchor, oReward = 0, 0, 0, #oRewardOther, false;
	for i = 1, (iRewardOtherCnt + #oRewardItems) do
		if (i <= iRewardOtherCnt) then
			oReward = oRewardOther[i];
		else
			oReward = oRewardItems[i - iRewardOtherCnt];
		end
		if (oReward.Type == "Money") then
			if (bGotMoney) then
				MoneyFrame.staticMoney = oReward.Amount;
				MoneyFrame:Show();
			end
		elseif (oReward.Type == "Title") then
			bAnchorTitle = true;
			getglobal(sPrefix .. "PlayerTitleFrameTitle"):SetText(oReward.Title);
		elseif (oReward.Type == "Item") then
			if (i > iRewardOtherCnt) then
				if (oReward.Choice) then
					iCurrChoose = iCurrChoose + 1;
					iCnt = iCurrChoose;
					oAnchor = oChooseAnchor;
				else
					if (iCurrChoose > 0) then
						local	iRef = iTotal;
						if (iRef % 2 == 0) then
							iRef = iRef - 1;
						end
						getglobal(sPrefix .. "ItemReceiveText"):SetPoint("TOPLEFT", sPrefix .. "Item" .. iRef, "BOTTOMLEFT", 0, -5);
					end

					iCurrAlways = iCurrAlways + 1;
					iCnt = iCurrAlways;
					oAnchor = oAnywaysAnchor;
				end
				iTotal = iTotal + 1;
				local questRewardButton = getglobal(sPrefix .. "Item" .. iTotal);
				local questRewardName = getglobal(sPrefix .. "Item" .. iTotal .. "Name");
				local questRewardTexture = getglobal(sPrefix .. "Item" .. iTotal .. "IconTexture");
				local questRewardCount = getglobal(sPrefix .. "Item" .. iTotal .. "Count");
				if (oReward.Count and (oReward.Count > 1)) then
					questRewardCount:SetText(oReward.Count);
				else
					questRewardCount:SetText("");
				end

				local	iItemID = oReward.ItemID;
				questRewardButton:SetID(iItemID);
				-- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture
				local	sItemName, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo("item:" .. iItemID);
-- DEFAULT_CHAT_FRAME:AddMessage("[CQ] Item " .. iItemID .. ": <" .. sItemName .. "> => " .. sItemTexture);
				questRewardName:SetText(sItemName);
				questRewardTexture:SetTexture(sItemTexture);
				questRewardTexture:Show();

				questRewardButton:SetScript("OnEnter", CommonersQuest.ItemEnter);
				questRewardButton:SetScript("OnClick", CommonersQuest.ItemClicked);
				questRewardButton.customdata = oReward.Choice;

				if (iCnt == 1) then
-- DEFAULT_CHAT_FRAME:AddMessage("[CQ] Aligning: " .. questRewardButton:GetName() .. " -> " .. oAnchor:GetName());
					questRewardButton:SetPoint("TOPLEFT", oAnchor, "BOTTOMLEFT", 0, -2)
				elseif (iCnt == 2) then
					questRewardButton:SetPoint("TOPLEFT", sPrefix .. "Item" .. (iTotal - 1), "TOPRIGHT", 0, 0)
				else
					questRewardButton:SetPoint("TOPLEFT", sPrefix .. "Item" .. (iTotal - 2), "BOTTOMLEFT", 0, -2)
				end

				questRewardButton:Show();
			end
		else
			if ((CommonersQuestFrame.Player == nil) and (CommonersQuestFrame.EditMode == true)) then
				CQH.CommChat("DbgImportant", "Quest", "Failed to show unknown reward type " .. oReward.Type .. "...");
			end
			bFail = true;
		end
	end
	local	oFrameLowest = sPrefix .. "Item" .. iTotal;
	for i = (iTotal + 1), MAX_NUM_ITEMS do
		local questRewardButton = getglobal(sPrefix .. "Item" .. i);
		questRewardButton:Hide();
	end

	if (bGotMoney and (iCntChoose > 0) and (iCntAlways == 0)) then
		local	iRef = iTotal;
		if (iRef % 2 == 0) then
			iRef = iRef - 1;
		end
		CQH.CommChat("DbgSpam", "Quest", sPrefix .. "ItemReceiveText aligned to " .. sPrefix .. "Item" .. iRef .. ".");

		oReceiveText:SetPoint("TOPLEFT", sPrefix .. "Item" .. iRef, "BOTTOMLEFT", 0, -5);
		oReceiveText:Show();
	end

	if (bAnchorTitle) then
		local	titleFrame = getglobal(sPrefix .. "PlayerTitleFrame");
		if (iCurrAlways > 0) then
			iRef = iTotal;
			if (iCurrAlways % 2 == 0) then
				iRef = iRef - 1;
			end

			titleFrame:SetPoint("TOPLEFT", sPrefix .. "Item" .. iRef, "BOTTOMLEFT", 0, -2)
		elseif (bGotMoney) then
			titleFrame:SetPoint("TOPLEFT", sPrefix .. "ItemReceiveText", "BOTTOMLEFT", 0, -5)
		else
			titleFrame:SetPoint("TOPLEFT", sPrefix .. "RewardTitleText", "BOTTOMLEFT", 0, -5)
		end

		titleFrame:Show();
		oFrameLowest = sPrefix .. "PlayerTitleFrame";
	end

	if (sPrefix == "CommonersQuestLog") then
		local	bUnknownReward = (#oRewardOther + #oRewardItems == 0) and (sBindingitemLink == nil);

		local	iBindingitemID;
		if (sBindingitemLink ~= nil) then
			iBindingitemID = string.match(sBindingitemLink, "item:(%d+)");
			if (iBindingitemID) then
				iBindingitemID = tonumber(iBindingitemID);
			end
		else
			sBindingitemLink = "item:6948:0:0:0:0:0:0:0";		-- Hearthstone
			iBindingitemID = 6948;
		end

		local questBindingitemButton = getglobal(sPrefix .. "Bindingitem");
		local questBindingitemName = getglobal(sPrefix .. "BindingitemName");
		local questBindingitemTexture = getglobal(sPrefix .. "BindingitemIconTexture");

		if ((sBindingitemLink ~= nil) and (iBindingitemID ~= nil)) then
			questBindingitemButton:SetID(iBindingitemID);
			-- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture
			local	sItemName, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo(sBindingitemLink);
			questBindingitemName:SetText(sItemName);
			questBindingitemTexture:SetTexture(sItemTexture);
			questBindingitemTexture:Show();

			questBindingitemButton:SetScript("OnEnter", CommonersQuest.ItemEnter);
			questBindingitemButton:SetScript("OnClick", CommonersQuest.ItemClicked);
		end
		if (iBindingitemID == 6948) then
			questBindingitemName:SetText("Not yet given.");
		end
		if (CQH.FindItemInBags(sBindingitemLink) == nil) then
			questBindingitemName:SetTextColor(1, 0.5, 0.5);
		end

		if (bNoBindingItemRequired) then
			CommonersQuestLogBindingitemTitleText:Hide();
			CommonersQuestLogBindingitem:Hide();
			CommonersQuestLogRewardTitleText:SetPoint("TOPLEFT", "CommonersQuestLogCommonersQuestDescription", "BOTTOMLEFT", 0, -15);
		else
			CommonersQuestLogBindingitemTitleText:Show();
			CommonersQuestLogBindingitem:Show();
			CommonersQuestLogRewardTitleText:SetPoint("TOPLEFT", sPrefix .. "Bindingitem", "BOTTOMLEFT", 0, -10);
		end

		if (bUnknownReward) then
			local questRewardButton = CommonersQuestLogItem1;
			local questRewardName = CommonersQuestLogItem1Name;
			local questRewardTexture = CommonersQuestLogItem1IconTexture;
			local questRewardCount = CommonersQuestLogItem1Count;

			questRewardName:SetText("No reward requested.");
			questRewardCount:SetText("");

			-- INV_Misc_QuestionMark.png
			questRewardTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			questRewardTexture:Show();

			questRewardButton:SetID(0);
			questRewardButton:SetScript("OnEnter", nil);
			questRewardButton:SetScript("OnClick", nil);

			questRewardButton:SetPoint("TOPLEFT", sPrefix .. "RewardTitleText", "BOTTOMLEFT", 0, -5)
			questRewardButton:Show();

			oFrameLowest = "CommonersQuestLogItem1";
		end
	end

	return bFail;
end

function	CommonersQuest.Helpers.RewardCheckLock(oRewardset)
	if (oRewardset.State.Locked) then
		-- lock old enough to remove?
		if ((oRewardset.State.LockedAt == nil) or
		    (time() - oRewardset.State.LockedAt > 3600)) then
			-- over an hour old seems "old enough"...
			local	sOld = "";
			if (oRewardset.State.LockedTo) then
				sOld = sOld .. " for " .. oRewardset.State.LockedTo;
			end
			if (oRewardset.State.LockedAt) then
				sOld = sOld .. " (more than " .. ((time() - oRewardset.State.LockedAt) / 3600) .. " hours old)";
			end
			sOld = sOld .. ".";
			CQH.CommChat("ChatSpam", "Quest", "Dropping rewardset lock" .. sOld);

			oRewardset.State.Locked = false;
			oRewardset.State.LockedTo = nil;
			oRewardset.State.LockedAt = nil;
			oRewardset.State.Cookie = nil;
		end
	end
end

function	CommonersQuest.Helpers.InitStateGiver(oQuest, bNoCreate)
	if (type(oQuest) ~= "table") then
		return
	end

	local	oStateGlobal = CQDataGlobal.Giver.QuestStates[oQuest.ID];		-- init
	if (not bNoCreate and (oStateGlobal == nil)) then
		oStateGlobal = oQuest.State;
		if (oStateGlobal == nil) then
			oStateGlobal = {};
		end
		oStateGlobal.Enabled = nil;	-- held local
		CQDataGlobal.Giver.QuestStates[oQuest.ID] = oStateGlobal;		-- init
	end

	local	oStateChar = CQDataX.Giver.QuestStates[oQuest.ID];		-- init
	if (not bNoCreate and (oStateChar == nil)) then
		oStateChar = {};

		local	k, v;
		for k, v in pairs(oStateGlobal) do
			oStateChar[k] = v;
		end
		oStateChar.Enabled = false;	-- init
		oStateChar.Locked = nil;	-- held global
		oStateChar.Modified = nil;	-- held global
		oStateChar.Key = nil;		-- held global
		oStateChar.NoBindingItem = nil;	-- held global
		CQDataX.Giver.QuestStates[oQuest.ID] = oStateChar;	-- init
	end

	return oStateGlobal, oStateChar;
end

function	CommonersQuest.Helpers.CheckInventoryForRewardAvailability(iQuestID, sPlayer, oRewards)
	if (oRewards == nil) then
		return false;
	end

	local	oItems, iBag = {};
	for iBag = 0, 4 do
		local	iSlotCnt, iSlot = GetContainerNumSlots(iBag);
		for iSlot = 1, iSlotCnt do
			local	sItem = GetContainerItemLink(iBag, iSlot);
			if (sItem) then
				sItem = string.match(sItem, "item:(%d+)");
				if (sItem) then
					local	iItem = tonumber(sItem);
					local	_, iCount = GetContainerItemInfo(iBag, iSlot);
					CQH.InitTable(oItems, iItem);
					if (oItems[iItem].Count == nil) then
						oItems[iItem].Count = 0;
					end
					oItems[iItem].Count = oItems[iItem].Count + iCount;
				end
			end
		end
	end

	local	k, v;
	for k, v in pairs(CQDataItems) do
		if (oItems[k]) then
			oItems[k].Count = oItems[k].Count - v.Count["Total#"];
		end
	end

	local	k, v;
	for k, v in pairs(oRewards) do
		if (v.Type == "Item") then
			local	_, sLink = GetItemInfo(v.ItemID);
			if (sLink == nil) then
				sLink = "<" .. v.ItemID .. ":not in local cache>";
			end
			local	sQLink = CQH.QuestToPseudoLink(iQuestID);

			if (oItems[v.ItemID] == nil) then
				DEFAULT_CHAT_FRAME:AddMessage("No " .. sLink .. " availabe for " .. iQuestID .. " requested by player " .. sFrom .. ".");
				return false;
			end

			local	iCntReq = v.Count;
			if (iCntReq == nil) then
				iCntReq = 1;
			end
			oItems[v.ItemID].Count = oItems[v.ItemID].Count - iCntReq;
			if (oItems[v.ItemID].Count < 0) then
				CQH.CommChat("ChatImportant", nil, "Insufficient amount of " .. sLink .. " for " .. iQuestID .. " requested by player " .. sPlayer .. ". :-(");
				return false;
			end
		end
	end

	return true;
end

function	CommonersQuest.Helpers.CanDoQuest(sWho, oQuest, sRace, sClass, iSex, iLevel)
	local	k, v;
	for k, v in pairs(oQuest.ContractPreReq) do
		if (k == "Faction") then
			if ((v ~= "Any") and (v ~= UnitFactionGroup("player"))) then
				return false;
			end
		elseif (k == "MinLevel") then
			if (iLevel < v) then
				return false;
			end
		elseif (k == "MaxLevel") then
			if (iLevel > v) then
				return false;
			end
		elseif (k == "Race") then
			if (sRace ~= v) then
				return false;
			end
		elseif (k == "Class") then
			if (sClass ~= v) then
				return false;
			end
		elseif (k == "Gender") then
			if (iSex ~= v) then
				return false;
			end
		end
	end

	-- 0: always, -1/missing: once, >0: every n days
	local	iRepeatable = oQuest.ContractPreReq.Repeatable or -1;
	if (iRepeatable ~= 0) then
		local	WhoAmI = UnitName("player");
		if (CQData and CQData[sWho] and CQData[sWho].QuestsCompleted) then
			local	iCompleted, l, w = 0;
			for l, w in pairs(CQData[sWho].QuestsCompleted) do
				if ((oQuest.ID == w.QuestID) and (sWho == w.Taker) and (WhoAmI == w.Giver)) then
					iCompleted = math.max(iCompleted, w.Completed);
				end
			end

			if (iCompleted > 0) then
				if (iRepeatable > 0) then
					if (iCompleted + iRepeatable * 86400 >= time()) then
						CQH.CommChat("DbgInfo", "Comm", "Not giving repeatable quest " .. oQuest.ID .. ": Completed too recently.");
						return false;
					end
				else
					CQH.CommChat("DbgInfo", "Comm", "Not giving quest " .. oQuest.ID .. ": Only-once kind and already completed.");
					return false;
				end
			end
		end
	end

	if (oQuest.ContractPreQ) then
		local	oQuestIDs, k, v = {};
		for k, v in pairs(oQuest.ContractPreQ) do
			oQuestIDs[v] = 0;
		end

		local	WhoAmI = UnitName("player");
		if (CQData and CQData[sWho] and CQData[sWho].QuestsCompleted) then
			local	iCompleted, l, w = 0;
			for l, w in pairs(CQData[sWho].QuestsCompleted) do
				if ((sWho == w.Taker) and (WhoAmI == w.Giver)) then
					oQuestIDs[w.QuestID] = 1;
				end
			end
		end

		for k, v in pairs(oQuestIDs) do
			if (v == 0) then
				CQH.CommChat("DbgInfo", "Comm", "Not giving quest " .. oQuest.ID .. ", missing prereq. quest " .. k .. ".");
				return false;
			end
		end
	end

	return true;
end

-- ########################################################################## --
-- ########################################################################## --

CommonersQuest.ChatMsgType = {
		["ChatImportant"] = 1, ["ChatInfo"] = 3, ["ChatSpam"] = 5,
		["DbgImportant"] = 101, ["DbgInfo"] = 103, ["DbgSpam"] = 105,
	};

function	CommonersQuest.Helpers.CommChat(sType, sArea, sMsg)
	if (not CQInitOk) then
		return
	end

	-- sArea: Comm, Quest, Trade, Frame, Log
	local	iType, sPrefix = CommonersQuest.ChatMsgType[sType];
	if (iType == nil) then
		DEFAULT_CHAT_FRAME:AddMessage("FAIL! => " .. debugstack());
		iType = 101;
	end

	if (iType < 100) then
		sPrefix = "CommonersQuest: ";
	else
		sPrefix = "[CQ] ";
		if (iType >= 103) then
			if (CQDataX.Debug ~= true) then
				return
			end

			if (sArea ~= nil) then
				if (CQDataGlobal.ChatAreaSpam) then
					if (CQDataGlobal.ChatAreaSpam[sArea] == true) then
						sPrefix = "{CQ} ";
					else
						return
					end
				end
			end
		end
	end


	-- TODO: split to chat windows
	local	color = { r = 1, g = 0.9, b = 0.7 };
	if ((iType % 100) == 1) then
		color = { r = 1, g = 0.7, b = 0.1 };
	elseif ((iType % 100) == 5) then
		color = { r = 0.7, g = 0.5, b = 0.1 };
	end
	DEFAULT_CHAT_FRAME:AddMessage(sPrefix .. sMsg, 1, 0.9, 0.7);
end

-- ########################################################################## --
-- ########################################################################## --

function	CommonersQuest.Slider.Init(sText1, sText2, iMin, iMax, iCurr, iX, iY, fCallback, oData, oMap)
	CommonersQuest.Slider.oData = { fCallback = fCallback, oData = oData, iCurr = iCurr };
	CommonersQuest.Slider.oMap = oMap;

	CommonersQuestSliderFrameText1:SetText(sText1);
	CommonersQuestSliderFrameText2:SetText(sText2);

	CommonersQuestSliderFrameSliderText:SetText(iCurr);
	CommonersQuestSliderFrameSliderLow:SetText(iMin);
	CommonersQuestSliderFrameSliderHigh:SetText(iMax);

	local	iCurrMapped = iCurr;
	if (oMap) then
		local	sDebug = "";
		iMin = 0;
		iMax = 0;
		local	iCnt, i = #oMap;
		for i = 1, iCnt do
			oMap[i].O = iMax;
			if (iCurr >= iMax) then
				iCurrMapped = math.floor((iCurr - oMap[i].F) / oMap[i].S);
			end

			iMax = iMax + math.floor((oMap[i].T - oMap[i].F) / oMap[i].S);
			sDebug = sDebug .. ", " .. i .. ": " .. oMap[i].O .. " (" .. oMap[i].F .. " -> " .. oMap[i].T .. ")";
		end

		CQH.CommChat("DbgSpam", "Edit", "map offsets - " .. strsub(sDebug, 3) .. "; iMax = " .. iMax);
	end

	CommonersQuestSliderFrameSlider:SetMinMaxValues(iMin, iMax);
	CommonersQuestSliderFrameSlider:SetValueStep(1);
	CommonersQuestSliderFrameSlider:SetValue(iCurrMapped);

	CommonersQuestSliderFrame:ClearAllPoints();
	CommonersQuestSliderFrame:SetPoint("BOTTOMLEFT", iX, iY);
	CommonersQuestSliderFrame:Show();
end

function	CommonersQuest.Slider.Reset()
	CommonersQuest.Slider.oData = nil;
	CommonersQuest.Slider.oMap = nil;
	CommonersQuestSliderFrame:Hide();
end

function	CommonersQuest.Slider.MappedValueToValue(iValue)
	if (CommonersQuest.Slider.oMap) then
		local	oMap, iValueMapped, sValueMapped = CommonersQuest.Slider.oMap;
		local	iCnt, i = #oMap;
		for i = 1, iCnt do
			if (oMap[i].O <= iValue) then
				if ((i == iCnt) or (oMap[i + 1].O > iValue)) then
					iValueMapped = oMap[i].F + (iValue - oMap[i].O) * oMap[i].S;
					sValueMapped = iValueMapped;
					if (oMap[i].D) then
						local	iValueSub = iValueMapped % oMap[i].D;
						if (iValueSub < 10) then
							iValueSub = "0" .. iValueSub;
						end
						sValueMapped = math.floor(iValueMapped / oMap[i].D) .. ":" .. iValueSub;
					end
				end
			end
		end

		CQH.CommChat("DbgSpam", "Edit", "iValue = " .. iValue .. " results in mapping " .. (iValueMapped or "<nil>") .. "/" .. (sValueMapped or "<nil>"));

		return iValueMapped, sValueMapped;
	else
		return iValue, iValue;
	end
end

function	CommonersQuest.Slider.OnValueChanged(self)
	if (CommonersQuest.Slider.oData) then
		local	iCurr, sCurr = CommonersQuest.Slider.MappedValueToValue(self:GetValue());
		CommonersQuest.Slider.oData.iCurr = iCurr;
		CommonersQuestSliderFrameSliderText:SetText(sCurr);
	end
end

function	CommonersQuest.Slider.OnOk(self)
	if (type(CommonersQuest.Slider.oData.fCallback) == "function") then
		CommonersQuest.Slider.oData.fCallback(CommonersQuest.Slider.oData.iCurr, CommonersQuest.Slider.oData.oData);
	end

	CommonersQuest.Slider.Reset();
end

-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --

CommonersQuest.StaticPopups["COMMONERSQUEST_QUESTGIVER_ITEMTRADE_ISFORQUEST"] = {
		text = "Offer this item to bind the requested quest\n%s\nto player %s?",
		button1 = "ACCEPT",
		button2 = "CANCEL",
		OnAccept = function()
				CommonersQuest.TradeAccept("Give");
			end,
		OnCancel = function()
				CommonersQuest.TradeDeny("Give");
			end,
		timeout = 0,
		hasItemFrame = 1,
		whileDead = 0,
		hideOnEscape = 1,
		showAlert = 0,
		notClosableByLogout = 0
	};

CommonersQuest.StaticPopups["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"] = {
		text = "Accept this item to bind the requested quest\n%s\nfrom player %s?",
		button1 = "ACCEPT",
		button2 = "CANCEL",
		OnAccept = function()
				CommonersQuest.TradeAccept("Take");
			end,
		OnCancel = function()
				CommonersQuest.TradeDeny("Take");
			end,
		timeout = 0,
		hasItemFrame = 1,
		whileDead = 0,
		hideOnEscape = 1,
		showAlert = 0,
		notClosableByLogout = 0
	};

CommonersQuest.StaticPopups["COMMONERSQUEST_EDIT_FIELDCONTENT"] = {
		text = "Edit field ??? to:",
		textbase = "Edit field %s to:",
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 1024,
		hasWideEditBox = 1,
		OnAccept = function(self)
			CommonersQuest.QuestEdit.PopupFieldSet(self);
		end,
		OnShow = function(self)
			CommonersQuest.QuestEdit.PopupFieldInit(self);
		end,
		OnHide = nil,
		EditBoxOnEnterPressed = nil,
		EditBoxOnEscapePressed = nil,
		timeout = 0,
		exclusive = 1,
		whileDead = 0,
		hideOnEscape = 1
	};

CommonersQuest.StaticPopups["COMMONERSQUEST_SEARCH_REQUIREMENTTARGET"] = {
		text = "Requirement target (item/NPC):",
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 1024,
		hasWideEditBox = 1,
		OnAccept = function(self)
			CommonersQuest.QuestEdit.InputSet(self);
		end,
		OnShow = function(self)
			CommonersQuest.QuestEdit.InputInit(self);
		end,
		OnHide = nil,
		EditBoxOnEnterPressed = function(self)
			CommonersQuest.QuestEdit.InputCheck(self);
		end,
		EditBoxOnEscapePressed = nil,
		timeout = 0,
		exclusive = 1,
		whileDead = 0,
		hideOnEscape = 1
	};

CommonersQuest.StaticPopups["COMMONERSQUEST_BIND_ITEM_TO_QUEST"] = {
		text = "Quest:\n%s\n\nRequested by: %s\n\nAre you sure you want to bind this item\nto this quest for this player?",
		button1 = YES,
		button2 = NO,
		OnAccept = function(self)
			CommonersQuest.BindingConfirm();
		end,
		OnCancel = function (self)
			-- CommonersQuest.BindingReset();
		end,
		OnUpdate = function (self)
			if (not CursorHasItem()) then
				StaticPopup_Hide("COMMONERSQUEST_BIND_ITEM_TO_QUEST");
			end
		end,
		hasItemFrame = 1,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1
	};

CommonersQuest.StaticPopups["COMMONERSQUEST_EDIT_FIELD"] = {
		text = "Edit %s - field %s:",
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 1024,
		hasWideEditBox = 1,
		OnAccept = function(self)
			return CommonersQuest.QuestEdit.PopupTableFieldSet(self);
		end,
		OnShow = function(self)
			CommonersQuest.QuestEdit.PopupTableFieldInit(self);
		end,
		OnHide = nil,
		EditBoxOnEnterPressed = nil,
		EditBoxOnEscapePressed = nil,
		timeout = 0,
		exclusive = 1,
		whileDead = 0,
		hideOnEscape = 1
	};

CommonersQuest.StaticPopups["COMMONERSQUEST_EDIT_MONEYREWARD"] = {
		text = "Set money reward to:",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnShow = function(self)
			CommonersQuest.QuestEdit.MoneyRewardInit(self);
		end,
		OnAccept = function(self)
			CommonersQuest.QuestEdit.MoneyRewardSet(self);
		end,
		OnHide = function(self)
			MoneyInputFrame_ResetMoney(self.moneyInputFrame);
		end,
		hasMoneyInputFrame = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 0,
		hideOnEscape = 1
	};

CommonersQuest.StaticPopups["COMMONERSQUEST_ABANDON_QUEST"] = {
		text = "Quest:\n%s\n\nGiven by: %s\n\nAre you SURE you want to abandon this quest by this player?",
		button1 = YES,
		button2 = NO,
		OnAccept = function(self)
			CommonersQuest.Log.AbandonDialog_OnAccept(self);
		end,
		OnCancel = function (self)
			CommonersQuest.Log.AbandonDialog_OnCancel(self);
		end,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1
	};

