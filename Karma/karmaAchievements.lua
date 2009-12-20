
-- cross-module access
local	KarmaObj = KarmaAvEnK;
local	KOH = KarmaObj.Helpers;

local	AchievementCategoryUnknown = "UNKNOWN";

local	KarmaModuleLocal =
		{
			-- criteria update cache:
				-- { [1] =
				--		{ [CatID] =
				--			{ [AchID] = { [1] = true, [2] = false, Count = 2, Completed = false, Category = CatID },
				--			... },
				--		... },
				--   [2] =
				--		{ [AchID] = { [1] = true, [2] = false, Count = 2, Completed = false, Category = CatID },
				--		... },
				-- }
			AchievementCache = { [1] = {}, [2] = {} },

			-- 165 is actually PvP/Arena, but why make it more difficult than necessary...
			AchievementCategoriesCheck = true,
			AchievementCategories =
				{
					[   165 ] = "GROUP",	-- pvp/arena

					[ 14808 ] = "GROUP",	-- dungeon/classic
					[ 14805 ] = "GROUP",	-- dungeon/BC
					[ 14806 ] = "GROUP",	-- dungeon/LK/normal
					[ 14921 ] = "GROUP",	-- dungeon/LK/heroic

					[ 14922 ] = "RAID10",	-- raid/LK/normal
					[ 14923 ] = "RAID25",	-- raid/LK/heroic
					[ 14961 ] = "RAID10",	-- raid/LK/Ulduar/normal
					[ 14962 ] = "RAID25",	-- raid/LK/Ulduar/heroic
					[ 15001 ] = "RAID10",	-- raid/LK/CotC/normal
					[ 15002 ] = "RAID25",	-- raid/LK/CotC/heroic

					[ 15041 ] = "RAID10",	-- raid/LK-3.3/IcecrownCitadel
					[ 15042 ] = "RAID25",	-- raid/LK-3.3/IcecrownCitadel
				 },

				-- handpicked candidates & list
			AchievementListSeasonal =
				{
					-- World events:
						-- Winterveil (156):
							-- 273/279: Save Metzen / Questline for Grinch
								-- not considered (barely anyone does this as group)
							-- 1687: Throw snow on race/class
								-- requires: spell cast tracking
								-- not considered (but would like to...)
							-- 1690: dance as snowman with another snowman
								-- requires: emote tracking
								-- not considered (but would like to...)

						-- Hallow's End (158):
							-- 238: get transmogrified via staves
								-- requires: spell cast tracking
								-- not considered (but would like to...)
							-- 255: kill the headless horseman in scarlet monastery
								-- mono-criteria: mob kill
								-- not for cache, but for accept
					[  255 ] = { CatType = "GROUP" },
							-- 291: convert races into pumpkin heads
								-- requires: spell cast tracking
								-- not considered (but would like to...)
							-- 292: collect the two rare drops of the headless horseman
								-- criteria: 2 items (pet, helm)
					[  292 ] = { CatType = "GROUP" },

						-- Noblegarden (159):
							-- 2416: Un'Goro, lay egg as bunny
								-- requires: check who gave the bunny buff when gaining achievement
								-- not considered (but would like to...)

						-- Lunar Festival (160):
							-- 937: Complete Elune's Blessing Q (which is: kill Omen)
								-- does this complete at kill or at completing quest at NPC?
								-- requires: potentially track if mob killed == Omen, save raid, on quest completion use saved raid to add achievement
								-- not considered, need more info

						-- Midsummer (161):
							-- 263: kill Ahune in Slave Pens, also as q 11972
								-- mono-criteria: mob kill
								-- not for cache, but for accept
					[  263 ] = { CatType = "GROUP" },

						-- Brewfest (162):
							-- 295: kill Coren Direbrew in blackrock depths
								-- mono-criteria: mob kill
								-- not for cache, but for accept
					[  295 ] = { CatType = "GROUP" },

						-- Children's Week (163):
							-- 1786: the most idiotic achievement of assholiness in the current World of Warcraft (as of 3.1.2)
								-- not considered
							-- 1790: kill Ymiron with your orphan out (requires *you* surviving)
								-- mono-criteria: mob kill
								-- not for cache, but for accept
					[ 1790 ] = { CatType = "GROUP" },

						-- Love is in the Air (187): (my favorite!)
							-- 260: mend the hearts of 20 characters
								-- not considered (for fairness reasons would have to track *all* mended hearts...)
							-- 1188: shoot people a ugly flying goblin pet
								-- requires: spell cast tracking
								-- not considered (for fairness reasons would have to track *all* petified chars...)
							-- 1291: romantic picnic in Dalaran with someone else
								-- requires: open item (basket) tracking, check all people in the area for the heart buff
								-- not considered (but would like to...)
							-- 1703: get a rose petal clicky
								-- mono-criteria: loot
								-- not for cache, but for accept
					[ 1703 ] = { CatType = "GROUP" },

					-- General: none of this goes into cache, as they are all 'one-shot'
						-- level 10, 20, 30, 40, 50, 60, 70, 80
					[    6 ] = { CatType = AchievementCategoryUnknown },
					[    7 ] = { CatType = AchievementCategoryUnknown },
					[    8 ] = { CatType = AchievementCategoryUnknown },
					[    9 ] = { CatType = AchievementCategoryUnknown },
					[   10 ] = { CatType = AchievementCategoryUnknown },
					[   11 ] = { CatType = AchievementCategoryUnknown },
					[   12 ] = { CatType = AchievementCategoryUnknown },
					[   13 ] = { CatType = AchievementCategoryUnknown },

						-- won a need/greed purple with 100
					[  558 ] = { CatType = AchievementCategoryUnknown },
					[  559 ] = { CatType = AchievementCategoryUnknown },

						-- money, money, money...
					[ 1176 ] = { CatType = AchievementCategoryUnknown },	--    100g
					[ 1177 ] = { CatType = AchievementCategoryUnknown },	--  1.000g
					[ 1178 ] = { CatType = AchievementCategoryUnknown },	--  5.000g
					[ 1180 ] = { CatType = AchievementCategoryUnknown },	-- 10.000g
					[ 1181 ] = { CatType = AchievementCategoryUnknown },	-- 25.000g
				},
			AchievementsListPerCategoryOnce = false,
		};

local	KARMA_CONFIG =
		{
			RAID_TRACKALL = "RAID_TRACKALL",
			TRACK_DISABLEACHIEVEMENT = "TRACK_NOACHIEVEMENT",
			DEBUG_ENABLED = "DEBUG",
			BETA = "BETA"
		};

local	KARMA_DB_L5_RRFFM_TERROR = "TERROR";

-- function	Karma_CreateAchievementsCache()
function	KarmaObj.Achievements.CacheCreate()
	local	bDebug = Karma_GetConfig(KARMA_CONFIG.DEBUG_ENABLED) == 1;

	if (KarmaModuleLocal.AchievementCategoriesCheck) then
		-- check if we got any *new* categories in dungeon/raid (only done once at startup)
		local	lCategoryAll = GetCategoryList();
		local	iKey, iCategoryID;
		for iKey, iCategoryID in pairs(lCategoryAll) do
			local	sCategoryTitle, iParentCategoryID = GetCategoryInfo(iCategoryID);
			if ((iParentCategoryID == 168) and (KarmaModuleLocal.AchievementCategories[iCategoryID] == nil)) then
				KarmaChatSecondaryFallbackDefault("Oops! Missing a whole *category* from achievement tracking: " .. sCategoryTitle);
				KarmaModuleLocal.AchievementCategories[iCategoryID] = AchievementCategoryUnknown;
			end
		end

		KarmaModuleLocal.AchievementCategoriesCheck = false;
		KarmaModuleLocal.AchievementsListPerCategoryOnce = true;
	end

	local	Store = function(iAchID, iCatID)
			local	iID, sAchievementName, iPoints, bAchievementCompleted = GetAchievementInfo(iAchID);
			local	iMax = GetAchievementNumCriteria(iAchID);
			if ((not bAchievementCompleted) and iMax and (iMax > 1)) then
				local	oCat;
				if (iCatID) then
					KOH.TableInit(KarmaModuleLocal.AchievementCache[1], iCatID);
					oCat = KarmaModuleLocal.AchievementCache[1][iCatID];
				else
					oCat = KarmaModuleLocal.AchievementCache[2];
					iCatID = GetAchievementCategory(iAchID);
				end

				oCat[iAchID] = {};
				local	oAch = oCat[iAchID]; 

				local	i;
				for i = 1, iMax do
					local	sName, iType, bCriteriaCompleted = GetAchievementCriteriaInfo(iAchID, i);
					oAch[i] = bCriteriaCompleted;
				end

				oAch.Completed = bAchievementCompleted;
				oAch.Count = iMax;
				oAch.Category = iCatID;

				return true;
			end

			return false;
		end

	-- TODO:
	--  97 (Group) : EXPLORATION

	--  95 (Group) : PvP -> 165 : Arena
	-- 168 (Group) : Dungeons & Raids
	local	iCategoryID, sCategoryType;
	for iCategoryID, sCategoryType in pairs(KarmaModuleLocal.AchievementCategories) do
		local	sCategoryTitle, iParentCategoryID = GetCategoryInfo(iCategoryID);
		if (sCategoryTitle) then
			if (KarmaModuleLocal.AchievementsListPerCategoryOnce) then
				KarmaChatDebug("Category #" .. iCategoryID .. " (" .. sCategoryType .. "): " .. sCategoryTitle .. " -->");
			end

			local	iMax = GetCategoryNumAchievements(iCategoryID);
			if (iMax and (iMax > 0)) then
				local	sAll, iAll = "", 0;
				local	i, iAchievementID, sAchievementName, _, bCompleted;
				for i = 1, iMax do
					iAchievementID, sAchievementName, _, bCompleted = GetAchievementInfo(iCategoryID, i);
					local	bStored = Store(iAchievementID, iCategoryID);
					if (bStored or bDebug) then
						if (KarmaModuleLocal.AchievementsListPerCategoryOnce) then
							if (bCompleted) then
								sAll = sAll .. " |cFF00FF00(" .. sAchievementName .. ")|r";
							elseif (bStored) then
								sAll = sAll .. " <" .. sAchievementName .. ">";
							else
								sAll = sAll .. " [" .. sAchievementName .. "]";
							end
							iAll = iAll + 1;
							if ((iAll % 10) == 0) then
								KarmaChatDebug(format("[%d]", (iAll / 10)) .. sAll);
								sAll = "";
							end
						end
					end
				end
				if (KarmaModuleLocal.AchievementsListPerCategoryOnce) then
					if (sAll ~= "") then
						KarmaChatDebug(format("[%d]", ((iAll + 9) / 10)) .. sAll);
					end
				end
			else
				KarmaChatDebug("Achievement category without achievements? #" .. iCategoryID);
			end
			if (KarmaModuleLocal.AchievementsListPerCategoryOnce) then
				KarmaChatDebug("<--");
			end
		end
	end

	local	iCategoryGeneralID, iCategoryWorldEventsID = 92, 155;
	local	sCategoryGeneralID     = GetCategoryInfo(iCategoryGeneralID);
	local	sCategoryWorldEventsID = GetCategoryInfo(iCategoryWorldEventsID);
	if (KarmaModuleLocal.AchievementsListPerCategoryOnce) then
		KarmaChatDebug("Category groups #" .. iCategoryGeneralID .. "/" .. iCategoryWorldEventsID .. " (VARIOUS): "
						   .. sCategoryGeneralID .. "/" .. sCategoryWorldEventsID .. " -->");
	end

	local	sAll, iAll = "", 0;
	local	iAchievementID, oAchInfo;
	for iAchievementID, oAchInfo in pairs(KarmaModuleLocal.AchievementListSeasonal) do
		local	bStored = Store(iAchievementID);
		if (bStored or bDebug) then
			if (KarmaModuleLocal.AchievementsListPerCategoryOnce) then
				local	_, sAchievementName, _, bCompleted = GetAchievementInfo(iAchievementID);
				if (bCompleted) then
					sAll = sAll .. " |cFF00FF00(" .. sAchievementName .. ")|r";
				elseif (bStored) then
					sAll = sAll .. " <" .. sAchievementName .. ">";
				else
					sAll = sAll .. " [" .. sAchievementName .. "]";
				end
				iAll = iAll + 1;
				if ((iAll % 10) == 0) then
					KarmaChatDebug(format("[%d]", (iAll / 10)) .. sAll);
					sAll = "";
				end
			end
		end
	end
	if (KarmaModuleLocal.AchievementsListPerCategoryOnce) then
		if (sAll ~= "") then
			KarmaChatDebug(format("[%d]", ((iAll + 9) / 10)) .. sAll);
		end
	end

	if (KarmaModuleLocal.AchievementsListPerCategoryOnce) then
		KarmaChatDebug("<--");
	end

	KarmaModuleLocal.AchievementsListPerCategoryOnce = false;
end

local	AchievementsProgressExecute = function(oParty, sPlayer, sEvent, iAchievementID, bSpecial)
	if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEACHIEVEMENT) == 1) then
		KarmaChatDebug("Achievement tracking is disabled.");
		return
	end

	if (WhoAmI == nil) then
		WhoAmI = UnitName("player");
	end

	local	DoAchievementAdd = function(iAchID, iCritIx, iCritNum)
			local	sName, sContainer;
			for sName, sContainer in pairs(oParty) do
				if (sName ~= WhoAmI) then
					local	oMember = Karma_MemberList_GetObject(sName);
					if (oMember) then
						if (iCritIx == nil) then
							KarmaChatDebug("Achievement #" .. iAchID .. " (completion) -> " .. sName);
						else
							KarmaChatDebug("Achievement #" .. iAchID .. "." .. iCritIx .. " -> " .. sName);
						end
						KarmaObj.DB.MC.AchievementAdd(oMember, sPlayer, iAchID, iCritIx, iCritNum);
					end
				end
			end
		end;

	KarmaChatDebug("Achievement(" .. sEvent .. ") progressed or completed: " .. iAchievementID);

	-- is there any 'hidden until other achievement reached' in Arena/Dungeon/Raid? dunno. better be on the safe side:
	local	oAch;
	if (bSpecial) then
		oAch = KarmaModuleLocal.AchievementCache[2][iAchievementID];
		if (oAch == nil) then
			KarmaChatDebug("IEKS! Achievement tracking: Internal inconsistency with cache for world events. :(");
			return
		end
	else
		local	iCategoryID = GetAchievementCategory(iAchievementID);
		KOH.TableInit(KarmaModuleLocal.AchievementCache[1], iCategoryID);
		KOH.TableInit(KarmaModuleLocal.AchievementCache[1][iCategoryID], iAchievementID);
		oAch = KarmaModuleLocal.AchievementCache[1][iCategoryID][iAchievementID];
	end

	local	iMax, iCriteriaIndex = GetAchievementNumCriteria(iAchievementID); 
	if (iMax > 1) then
		local	i;
		for i = 1, iMax do
			local	sName, iType, bCriteriaCompleted = GetAchievementCriteriaInfo(iAchievementID, i);
			if (oAch[i] ~= bCriteriaCompleted) then
				iCriteriaIndex = i;
				KarmaChatDebug("Achieved criteria #" .. iCriteriaIndex .. " in achievement " .. iAchievementID .. " completed.");
				DoAchievementAdd(iAchievementID, iCriteriaIndex, iMax);
				oAch[i] = bCriteriaCompleted;
			end
		end
	end

	local	_, _, _, bAchievementCompleted = GetAchievementInfo(iAchievementID);
	if (oAch.Completed ~= bAchievementCompleted) then
		DoAchievementAdd(iAchievementID);
		oAch.Completed = bAchievementCompleted;
		KarmaChatDebug("Achievement completed: " .. iAchievementID);
	end
end

-- function	Karma_AchievementProgress(sEvent, iAchievementID, ...)
function	KarmaObj.Achievements.Progress(oParty, sPlayer, sEvent, iAchievementID, ...)
	local	arg2, arg3, arg4, arg5 = ...;
	KarmaChatDebug("Achievement: " .. sEvent .. ", " .. KOH.AllToString(iAchievementID) .. ", " .. KOH.AllToString(arg2) .. ", "
			.. KOH.AllToString(arg3) .. ", " .. KOH.AllToString(arg4) .. ", " .. KOH.AllToString(arg5) .. ", ...");

	local	iID, sAchievementName = GetAchievementInfo(iAchievementID);
	KarmaChatDebug("Earned new achievement #" .. iAchievementID .. ": <" .. Karma_NilToString(sAchievementName) .. ">");
	if (sAchievementName == nil) then
		-- uuh... huh?!
		return
	end

	local	iCategoryID = GetAchievementCategory(iAchievementID);
	local	sCategoryTitle, iParentCategoryID = GetCategoryInfo(iCategoryID);
	KarmaChatDebug("In category #" .. iCategoryID .. ": <" .. Karma_NilToString(sCategoryTitle) .. ">");

	--  95 (Group) : PvP -> 165 : Arena
	-- 168 (Group) : Dungeons & Raids
	local	bValid, bSpecial = false, false
	if ((iParentCategoryID == 168) or (iCategoryID == 165)) then
		bValid = true;
	elseif (KarmaModuleLocal.AchievementListSeasonal[iAchievementID] ~= nil) then
		bValid = true;
		bSpecial = true;
	end

	if (bValid) then
		KarmaChatDebug("Valid achievement for (group) tracking, checking further.");
		AchievementsProgressExecute(oParty, sPlayer, sEvent, iAchievementID, bSpecial);
	end
end

-- function	Karma_AchievementTest()
function	KarmaObj.Achievements.UpdateTest(oParty, sPlayer)
	if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEACHIEVEMENT) == 1) then
		return
	end

	local	sCatTypeReq = "SPECIAL";	-- tbd (SPELL, BUFF, ... + SELFTOTARGET, TARGETTOSELF
	if (GetNumRaidMembers() > 0) then
		sCatTypeReq = "RAID10";
		if (GetInstanceDifficulty() == 2) then
			sCatTypeReq = "RAID25";
		end
	elseif (GetNumPartyMembers() > 0) then
		sCatTypeReq = "GROUP";
	end

	-- -----------------------------------------------------------
	-- TODO:
	-- if the number of achievements changed (new one added because old completed,
	-- we *might* need to check what was added!
	-- it would require a new achievement, that
	-- * has partial progress
	-- * only shows after completing another one
	-- * is relevant for group/raid (i.e. kill mob, loot boss mob item)
	-- as soon as more is tracked (spell cast/item used on target or from target),
	-- this might have to be reviewed
	-- currently I know of no case where it is relevant for this function
	-- -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	--	local	oCacheOld = KarmaModuleLocal.AchievementCache;
	--	KarmaModuleLocal.AchievementCache = {};
	--	KarmaObj.Achievements.CacheCreate();
	--	local	oCacheNew = KarmaModuleLocal.AchievementCache;
	--	KarmaModuleLocal.AchievementCache = oCacheOld;
	-- -----------------------------------------------------------

	local	CheckAch = function(iAch, oAch)
			if (oAch.Count == nil) then
				-- added via event to cache: -> should be handled correctly there
				return false;
			end

			local	bChange, i = false;
			for i = 1, oAch.Count do
				local	sName, iType, bCriteriaCompleted = GetAchievementCriteriaInfo(iAch, i);
				if (oAch[i] ~= bCriteriaCompleted) then
					bChange = true;
					break;
				end
			end

			return bChange;
		end

	local	iCatID, oCat;
	for iCatID, oCat in pairs(KarmaModuleLocal.AchievementCache[1]) do
		-- only check applicable categories:
		local	bCatValid = true;
		if (KarmaModuleLocal.AchievementCategories[iCatID] ~= nil) then
			if ((KarmaModuleLocal.AchievementCategories[iCatID] ~= sCatTypeReq) and
			    (KarmaModuleLocal.AchievementCategories[iCatID] ~= AchievementCategoryUnknown)) then
				bCatValid = false;
				KarmaChatDebug("Skipping category #" .. iCatID .. ": " .. GetCategoryInfo(iCatID));
			end
		end

		if (bCatValid) then
			local	iAch, oAch;
			for iAch, oAch in pairs(oCat) do
				if (CheckAch(iAch, oAch)) then
					KarmaChatDebug("Achievement updating (1): " .. iAch);
					AchievementsProgressExecute(oParty, sPlayer, "ACHIEVEMENT_PROGRESS_DEDUCED", iAch, false);
				end
			end
		end
	end

	for iAch, oAch in pairs(KarmaModuleLocal.AchievementCache[2]) do
		local	sCatType = KarmaModuleLocal.AchievementListSeasonal[iAch].CatType;
		if ((sCatType == sCatTypeReq) or
		    (sCatType == AchievementCategoryUnknown)) then
			if (CheckAch(iAch, oAch)) then
				KarmaChatDebug("Achievement updating (2): " .. iAch);
				AchievementsProgressExecute(oParty, sPlayer, "ACHIEVEMENT_PROGRESS_DEDUCED", iAch, false);
			end
		end
	end
end

function	KarmaObj.Achievements.LinesGet(oMember, sChar)
	local	lAchievements = KarmaObj.DB.MC.AchievementListGet(oMember, sChar);
	if (type(lAchievements) ~= "table") then
		return;
	end

	local	TotalKeysCount = 0;	-- Cats + Achs

	local	lCats = {};		-- CatIDs
	local	lCat2AchID = {};	-- CatID, AchL

	local	sAKey, oValues;
	for sAKey, oValues in pairs(lAchievements) do
		oValues.AchievementID = tonumber(strsub(sAKey, 2));
		local	_, sTitle = GetAchievementInfo(oValues.AchievementID);
		oValues.AchievementTitle = sTitle;
		oValues.CategoryID = GetAchievementCategory(oValues.AchievementID);
		if (lCat2AchID[oValues.CategoryID] == nil) then
			tinsert(lCats, oValues.CategoryID);
			lCat2AchID[oValues.CategoryID] = {};
			TotalKeysCount = TotalKeysCount + 1;
		end
		tinsert(lCat2AchID[oValues.CategoryID], oValues.AchievementID);
		TotalKeysCount = TotalKeysCount + 1;
	end
	table.sort(lCats);
	local	iCat;
	for iCat, oValues in pairs(lCat2AchID) do
		table.sort(oValues);
	end

	local	sDbg = "";

	local	iKey, lKeys, iDummy, iSubDummy, iAch = 0, {};
	for iDummy, iCat in pairs(lCats) do
		iKey = iKey + 1;
		lKeys[iKey] = "C" .. iCat;
		sDbg = "Cat key " .. lKeys[iKey] .. ":";
		for iSubDummy, iAch in pairs(lCat2AchID[iCat]) do
			iKey = iKey + 1;
			lKeys[iKey] = "A" .. iAch;
			sDbg = sDbg .. " " .. lKeys[iKey];
		end
		KarmaChatDebug(sDbg);
	end
	lKeys.__Count = iKey;

	return lKeys, lAchievements;
end

function	KarmaObj.Achievements.ListTip(self)
	local	id = self:GetID();
	local	btnText = getglobal("AchievementList_GlobalButton" .. id .. "_Text");
	local	sName = btnText:GetText();
	if (sName ~= nil) and (sName ~= "") then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		local	btnObj = getglobal("AchievementList_GlobalButton" .. id);
		if (btnObj.AchievementData == nil) then
			GameTooltip:SetText(sName, 1, 1, 0);
		else
			local	oAch = btnObj.AchievementData;
			GameTooltip:AddLine(oAch.AchievementTitle .. " (" .. oAch.AchievementID .. ")", 1, 1, 0);
			local	iMax = oAch["CMAX"];
			if (iMax) then
				local	iAch, i = 0;
				for i = 1, iMax do
					local	tsAch = oAch["C" .. i];
					if (tsAch) then
						iAch = iAch + 1;
						GameTooltip:AddLine("Criteria achieved on " .. date(KARMA_DATEFORMAT .. " %H:%M", tsAch) .. ":", 1, 1, 1);
						GameTooltip:AddLine("-- " .. GetAchievementCriteriaInfo(oAch.AchievementID, i), 1, 1, 1);
					end
				end
				if (iAch == iMax) then
					GameTooltip:AddLine("Completed on " .. date(KARMA_DATEFORMAT .. " %H:%M", oAch.At), 1, 1, 1);
				else
					GameTooltip:AddLine(format("%d%% achieved with this player", (100 * iAch) / iMax), 1, 1, 1);
				end
			else
				GameTooltip:AddLine("Completed on " .. date(KARMA_DATEFORMAT .. " %H:%M", oAch.At), 1, 1, 1);
			end

			GameTooltip:AddLine("Shift-click to create a link in the chatbox.", 0, 1, 1);
			GameTooltip:AddLine("Middle-click to show the achievement UI with this achievement selected.", 0, 1, 1);
		end

		GameTooltip:Show();
	end
end

function	KarmaObj.Achievements.OnClick(mouse, btnObj)
	if (btnObj.AchievementData == nil) then
		KarmaChatDebug("Clicked: " .. mouse .. " on achievement button, having no infos.");
		GameTooltip:SetText(sName, 1, 1, 0);
	else
		local	oAch = btnObj.AchievementData;
		KarmaChatDebug("Clicked: " .. mouse .. " on achievement button, achievement id = " .. oAch.AchievementID);
		if ((mouse == "LeftButton") and (IsShiftKeyDown())) then
			ChatFrameEditBox:Insert(GetAchievementLink(oAch.AchievementID));
		elseif (mouse == "MiddleButton") then
			if (not IsAddOnLoaded("Blizzard_AchievementUI")) then
				LoadAddOn("Blizzard_AchievementUI");
				KarmaChatSecondaryFallbackDefault("Had to load achievement UI first, please click again...");
			else
				if (AchievementFrame == nil) then
					KarmaChatDefault("Loading the achievement UI failed for unknown reasons. Can't display...");
				else
					if (not AchievementFrame:IsShown()) then
						AchievementFrame_ToggleAchievementFrame();
						-- ShowUIPanel(AchievementFrame);
						-- AchievementFrameTab_OnClick(1);
					end
					AchievementFrame_SelectAchievement(oAch.AchievementID);
				end
			end
		end
	end
end

local	bInit = false;

local	CheckTerrorUnitNameReq;
local	CheckTerrorUnitNameIs;
local	CheckTerrorUnitNameNow;
local	CheckTerrorUnitSetAt = 0;
local	CheckTerrorUnitIsMine;

function	ClearAchievementComparisonUnitHook()
	CheckTerrorUnitNameNow = nil;
	CheckTerrorUnitSetAt = 0;
end

function	SetAchievementComparisonUnitHook(sUnit)
	CheckTerrorUnitNameNow = sUnit;
	CheckTerrorUnitSetAt = GetTime();
end

function	KarmaObj.Achievements.CheckTerrorQuery(oList)
	-- list of missing terror checks, key = unit, value = name(@server)
	if (not bInit) then
		bInit = true;
		hooksecurefunc("ClearAchievementComparisonUnit", ClearAchievementComparisonUnitHook);
		hooksecurefunc("SetAchievementComparisonUnit", SetAchievementComparisonUnitHook);
	end

	-- first check if frame is defined: AchUI is LOD
	if (InCombatLockdown() or AchievementFrame and AchievementFrame:IsShown()) then
		return
	end

	local	iNow = GetTime();
	if (iNow - CheckTerrorUnitSetAt < 30) then
		return
	end

	if (oList[CheckTerrorUnitNameNow]) then
		if (CheckTerrorUnitNameReq ~= CheckTerrorUnitNameNow) then
			if (CheckTerrorUnitIsMine and (CheckTerrorUnitIsMine < CheckTerrorUnitSetAt)) then
				-- user/other addon requested other unit
				return
			end
		elseif (CheckTerrorUnitIsMine and (iNow - CheckTerrorUnitIsMine < 30)) then
			-- requested less than 30s ago
			return
		end
	elseif (CheckTerrorUnitSetAt and (iNow - CheckTerrorUnitSetAt < 30)) then
		return
	end

	local	k, v;
	for k, v in pairs(oList) do
		if (CheckInteractDistance(k, 1)) then
			CheckTerrorUnitNameReq = k;
			break;
		end
	end

	-- nothing found in range?
	if (CheckTerrorUnitNameReq == nil) then
		-- check if the units are still valid
		local	oRemove, k, v;
		for k, v in pairs(oList) do
			if (not UnitExists(k)) then
				oRemove = oRemove or {};
				tinsert(oRemove, k);
			end
		end

		if (oRemove) then
			for k, v in pairs(oRemove) do
				oList[v] = nil;
			end
		end
	end

	if (CheckTerrorUnitNameReq) then
		local	sServer;
		CheckTerrorUnitNameIs, sServer = UnitName(CheckTerrorUnitNameReq);
		if (sServer and (sServer ~= "")) then
			CheckTerrorUnitNameIs = CheckTerrorUnitNameIs .. "@" .. sServer;
		end

		Karma:RegisterEvent("INSPECT_ACHIEVEMENT_READY");

		local	sOut = "Checking unit " .. CheckTerrorUnitNameReq .. " for terror achievements...";
		if (AchievementFrame and AchievementFrameComparison) then
			AchievementFrameComparison:UnregisterEvent("INSPECT_ACHIEVEMENT_READY");
			sOut = sOut .. " (event unset in AchUI to STFU)";
		end
		KarmaChatDebug(sOut);

		ClearAchievementComparisonUnit();
		SetAchievementComparisonUnit(CheckTerrorUnitNameReq);
		CheckTerrorUnitIsMine = GetTime();
	end
end

local	oIDAlliance = { 610, 611, 612, 613, 614, };
local	oIDHorde = { 615, 616, 617, 618, 619, };

function	KarmaObj.Achievements.CheckTerrorReady()
	if ((CheckTerrorUnitNameNow ~= nil) and (CheckTerrorUnitNameReq == CheckTerrorUnitNameNow) and
	    (math.abs(CheckTerrorUnitIsMine - CheckTerrorUnitSetAt) < 1)) then
		local	sName, sServer = UnitName(CheckTerrorUnitNameReq);
		if (sServer and (sServer ~= "")) then
			sName = sName .. "@" .. sServer;
		end
		if (sName ~= CheckTerrorUnitNameIs) then
			CheckTerrorUnitNameReq = nil;
			CheckTerrorUnitIsMine = nil;
			return
		end

		local	oMember = Karma_MemberList_GetObject(sName);
		if (oMember == nil) then
			CheckTerrorUnitNameReq = nil;
			CheckTerrorUnitIsMine = nil;
			return
		end

		KOH.TableInit(oMember, KARMA_DB_L5_RRFFM_TERROR);
		local	oStore = oMember[KARMA_DB_L5_RRFFM_TERROR];
		oStore.Updated = time();

		local	oIDs;
		if (UnitFactionGroup(CheckTerrorUnitNameReq) == "Alliance") then
			oIDs = oIDAlliance;
		else
			oIDs = oIDHorde;
		end

		local	iTotal = 0;
		if (oIDs) then
			local	Index, ID;
			for Index, ID in pairs(oIDs) do
				local	bCompleted, iMonth, iDay, iYear = GetAchievementComparisonInfo(ID);
				local	sOut = "?";
				if (bCompleted) then
					iTotal = iTotal + 1;
					oStore[ID] = iYear * 512 + iMonth * 32 + iDay;
					sOut = "YES. :-(";
				else
					sOut = "No. :-)";
				end
				KarmaChatDebug("Checked unit " .. CheckTerrorUnitNameReq .. " for terror achievement " .. ID .. ": " .. sOut);
			end
		end

		if (GetNumRaidMembers() == 0) then
			if (iTotal == 5) then
				KarmaChatDefault("|cFFFF6060" .. (UnitName(CheckTerrorUnitNameReq) or CheckTerrorUnitNameReq) .. " completed For The Alliance/For The Horde. :-( |r");
			elseif (iTotal > 0) then
				KarmaChatDefault("|cFFFFFF60" .. (UnitName(CheckTerrorUnitNameReq) or CheckTerrorUnitNameReq) .. " completed " .. (iTotal * 25) .. "% For The Alliance/For The Horde. :-| |r");
			else
				KarmaChatDefault("|cFF60FF60" .. (UnitName(CheckTerrorUnitNameReq) or CheckTerrorUnitNameReq) .. " has not participated in For The Alliance/For The Horde. :-) |r");
			end
		end

		Karma:UnregisterEvent("INSPECT_ACHIEVEMENT_READY");
		if (AchievementFrame and AchievementFrameComparison) then
			AchievementFrameComparison:RegisterEvent("INSPECT_ACHIEVEMENT_READY");
		end

		local	sUnit = CheckTerrorUnitNameReq;
		CheckTerrorUnitNameReq = nil;
		CheckTerrorUnitIsMine = nil;

		return sUnit;
	end
end

function	KarmaObj.Achievements.CheckTerrorDone(oPartyNames)
	local	oIDs;
	if (UnitFactionGroup("player") == "Alliance") then
		oIDs = oIDAlliance;
	else
		oIDs = oIDHorde;
	end

	-- oPartyNames: name@server = oMember
	local	iTotalNo, iTotalPartial, k, v = 0, 0;
	for k, v in pairs(oPartyNames) do
		local	oState = v[KARMA_DB_L5_RRFFM_TERROR];
		if (oState and next(oState)) then
			local	iProgress, Index, ID = 0;
			for Index, ID in pairs(oIDs) do
				if (oState[ID]) then
					iProgress = iProgress + 1;
				end
			end
			if (iProgress == 5) then
				iTotalPartial = iTotalPartial + 1;
			elseif (iProgress > 0) then
				iTotalPartial = iTotalPartial + iProgress / 4;
			else
				iTotalNo = iTotalNo + 1;
			end
		else
			iTotalNo = iTotalNo + 1;
		end
	end

	local	iNum = GetNumRaidMembers() - 1;
	if (iNum > 0) then
		local	iTerrorists = iNum - iTotalNo;
		if (iTerrorists > 0) then
			KarmaChatDefault("Mob players in this raid: " .. iTerrorists .. " averaging a cowardice level of " .. format("%.2d", 100 * iTotalPartial / iTerrorists) .. "%.");
		end
	end
end

