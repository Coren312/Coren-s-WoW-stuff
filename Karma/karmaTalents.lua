
local	KarmaObj = KarmaAvEnK;
local	KOH = KarmaObj.Helpers;

-- Talents: Icons, if we got time... (or re-use existing!)
--[[
local	KARMA_TALENT_UNKNOWN      = "QMark";
local	KARMA_TALENT_DPS_PHYSICAL_MELEE = "RedTriangleM";
local	KARMA_TALENT_DPS_PHYSICAL_RANGE = "RedTriangleR";
local	KARMA_TALENT_DPS_MAGICAL  = "BlueTriangle";
local	KARMA_TALENT_HPS          = "GreenTriangle";
local	KARMA_TALENT_TANK         = "GreyCircle";
]]--

-- Bitfield
-- 1-2-4     : HPS (1), TANK (2), DPS (4), Feral(6)
-- 8-16      : MELEE(8), RANGED(16)
local	KARMA_TALENTS_MAXBITPLUS1 = 5;

local	KARMA_TALENTS =
	{
		[0] = { key = "KARMA_MISSING_INFO", color = "|cFF9F9F9F" },
		[1] = { key = "KARMA_TALENT_HPS", color = "|cFF00FF00" },		-- spec: Dru/Pal/Shm/Pri
		[2] = { key = "KARMA_TALENT_TANK", color = "|cFFFFFFFF" },		-- spec: Dru/Pal/War tanks
		[4] = { key = "KARMA_TALENT_DPS", color = "|cFFFF0000" },		-- spec: all classes
		[6] = { key = "KARMA_TALENT_FERAL", color = "|cFFFF8080" },		-- spec: Feral
		[8] = { key = "KARMA_TALENT_MELEE", color = "|cFFFFA0A0" },		-- spec: Moonkin/Feral, ShamanMelee/Ranged
		[16] = { key = "KARMA_TALENT_RANGED", color = "|cFFFF00FF" }		-- spec: Moonkin/Feral, ShamanMelee/Ranged
	};

-- default talents per class
local	KARMA_TALENTS_DEFAULT = 
	{
		 [1] = 0,	-- druid: HPS/R, FERAL/M, DPS/R
		 [2] = 20,	-- hunter: DPS/R
		 [3] = 20,	-- mage: DPS/R
		 [4] = 0,	-- paladin: HPS/R, TANK/M, DPS/M
		 [5] = 16,	-- priest: HPS/R, DPS/R
		 [6] = 12,	-- rogue: DPS/M
		 [7] = 0,	-- shaman: HPS/R, DPS/M, DPS/R
		 [8] = 8,	-- warrior: TANK/M, DPS/M
		 [9] = 20,	-- warlock: DPS/R
		[10] = 8	-- deathknight: TANK/M, DPS/M
	};

-- possible talents
local	KARMA_TALENT_CLASSMASK =
	{
		 [1] = 31,	-- druid: HPS/R, FERAL/M, DPS/R
		 [2] = 20,	-- hunter: DPS/R
		 [3] = 20,	-- mage: DPS/R
		 [4] = 31,	-- paladin: HPS/R, TANK/M, DPS/M
		 [5] = 21,	-- priest: HPS/R, DPS/R
		 [6] = 12,	-- rogue: DPS/M
		 [7] = 29,	-- shaman: HPS/R, DPS/M, DPS/R
		 [8] = 14,	-- warrior: TANK/M, DPS/M
		 [9] = 20,	-- warlock: DPS/R
		[10] = 14,	-- deathknight: TANK/M, DPS/M
	};

-- talent tree to probable talent
local	KARMA_TALENT_BYTREE =
	{
		 [1] = { [1] = 20, [2] = 14, [3] = 17 },		-- druid: DPS/R, Feral, HPS
		 [2] = { [1] = 20, [2] = 20, [3] = 20 },		-- hunter
		 [3] = { [1] = 20, [2] = 20, [3] = 20 },		-- mage
		 [4] = { [1] = 17, [2] = 10, [3] = 12 },		-- paladin: HPS, Tank, DPS/M
		 [5] = { [1] = 17, [2] = 17, [3] = 20 },		-- priest: HPS, HPS, DPS/R
		 [6] = { [1] = 12, [2] = 12, [3] = 12 },		-- rogue
		 [7] = { [1] = 20, [2] = 12, [3] = 17 },		-- shaman: DPS/R, DPS/M, HPS
		 [8] = { [1] = 12, [2] = 12, [3] = 10 },		-- warrior: DPS/M, DPS/M, Tank
		 [9] = { [1] = 20, [2] = 20, [3] = 20 },		-- warlock
		[10] = { [1] = 12, [2] = 10, [3] = 14 },		-- deathknight: DPS/M, Tank, Feral
	};

local	KARMA_DB_L5_RRFFM = {
			CLASS_ID = "CLSID";
		};
local	KARMA_DB_L5_RRFFM_TALENTTREE = "TALENTTREE";

KarmaObj.Talents.SpecCount = 1;

function	KarmaObj.Talents.ClassIDToTalentsDefault(classid)
	-- KarmaChatDebug("classid = " .. tostring(classid) .. ", K_T_D[classid] = " .. Karma_NilToString(KARMA_TALENTS_DEFAULT[classid]));
	if (classid ~= nil) then
		if (classid < 0) then
			classid = - classid;
		end
		if (classid > 0) and (KARMA_TALENTS_DEFAULT[classid] ~= nil) then
			return KARMA_TALENTS_DEFAULT[classid], KARMA_TALENTS_DEFAULT[classid] ~= KARMA_TALENT_CLASSMASK[classid];
		end
	end

	return 0, false;
end

function	KarmaObj.Talents.MemberObjSpecNumToTalent(oMember, iSpec)
	if (type(oMember) == "table") then
		local	oTree = oMember[KARMA_DB_L5_RRFFM_TALENTTREE];
		if (type(oTree) == "table") then
			local	classid = oMember[KARMA_DB_L5_RRFFM.CLASS_ID];
			if (classid == 0) then
				classid = Karma_ClassToID(Karma_MemberObject_GetClass(oMember));
			end
			if (classid < 0) then
				classid = - classid;
			end

			if (classid and (classid > 0)) then
				local	iTotal, iTabMaxCnt, iTabMaxIx, iTab = 0, -1;
				local	iNumTabs = GetNumTalentTabs();
				for iTab = 1, iNumTabs do
					local	iCnt = oTree["T_" .. iSpec .. "_" .. iTab];
					if (iCnt == nil) and (iSpec == 1) then
						iCnt = oTree["T_" .. iTab];
					end
					if (iCnt) then
						iTotal = iTotal + iCnt.Points;
						if (iCnt.Points > iTabMaxCnt) then
							iTabMaxCnt = iCnt.Points;
							iTabMaxIx = iTab;
						end
					end
				end

				if (iTotal > 0) then
					if (iTabMaxCnt > 40 * iTotal / 71) then
						return KARMA_TALENT_BYTREE[classid][iTabMaxIx];
					end
				end
			end
		end
	end
end

function	KarmaObj.Talents.TreeObjToStringsObj(oTree, bShiftPressed)
	local	aTrees, timeoftalents = { S_1 = "", S_2 = "" };

	if (oTree) and (type(oTree) == "table") then
		if (oTree.Time) then
			timeoftalents = oTree.Time;
		end

		local	sTreeText, value, sTreeName = "";

		local	iNumSpecs = KarmaObj.Talents.SpecCount;
		local	iNumTabs = GetNumTalentTabs();

		local	iSpec, iTab;
		for iSpec = 1, iNumSpecs do
			for iTab = 1, iNumTabs do
				if ((oTree["T_" .. iSpec .. "_" .. iTab] ~= nil) or
				    (iSpec == 1) and (oTree["T_" .. iTab] ~= nil)) then
					-- T_1 .. T_n
					value = oTree["T_" .. iSpec .. "_" .. iTab];
					if (value == nil) and (iSpec == 1) then
						value = oTree["T_" .. iTab];
					end
					if (sTreeText ~= "") then
						sTreeText = sTreeText .. " / ";
					end
					if (bShiftPressed) then
						sTreeName = value.Name
					else
						sTreeName = strsub(value.Name, 1, 4);
					end
					sTreeText = sTreeText .. sTreeName .. KARMA_WINEL_FRAG_COLONSPACE .. tostring(value.Points);
				end
			end
			aTrees["S_" .. iSpec] = sTreeText;
			sTreeText = "";
--			KarmaChatDebug("Talents[" .. iSpec .. "] = " .. aTrees["S_" .. iSpec]);
		end
	end

	return aTrees, timeoftalents;
end

function	KarmaObj.Talents.MemberObjToStringsObj(oMember, bShiftPressed)
	local	oResult, sSummary = {}, "";

	local	iNumSpecs = KarmaObj.Talents.SpecCount;

	local	aTalents = { S_1 = "", S_2 = "" };
	local	iSpec;
	for iSpec = 1, iNumSpecs do
		local	sTalentText, iDerived = "";
		local	iTalent, bPattern = Karma_MemberObject_GetTalentID(oMember, iSpec);
		if (bPattern) then
			iDerived = KarmaObj.Talents.MemberObjSpecNumToTalent(oMember, iSpec);
			if (iDerived) then
				iTalent = iDerived;
			end
		end
		if (iTalent and (iTalent > 0)) then
			sTalentText = KarmaObj.Talents.TalentIDToColorizedText(iTalent) .. "|r";
			if (iDerived) then
				sTalentText = "[" .. sTalentText .. "]";
			end
		end
		aTalents["S_" .. iSpec] = sTalentText;
--		KarmaChatDebug("Talents[" .. iSpec .. "] = " .. aTalents["S_" .. iSpec] .. "/" .. KOH.AllToString(bPattern));
	end

	local	oTree = oMember[KARMA_DB_L5_RRFFM_TALENTTREE];
	local	aTrees, timeoftalents = KarmaObj.Talents.TreeObjToStringsObj(oTree, bShiftPressed);

	for iSpec = 1, iNumSpecs do
		local	sKey = "S_" .. iSpec;

		local	sText = nil;
		if (aTalents[sKey] ~= "") then
			sText = aTalents[sKey];
			if (aTrees[sKey] ~= "") then
				sText = sText .. " {" .. aTrees[sKey] .. "}";
			end
		elseif (aTrees[sKey] ~= "") then
			sText = aTrees[sKey];
		end

		if ((sText ~= nil) and (sText ~= "")) then
			-- only add if it's not already there:
			-- - skip if tree missing and spec equals previous spec
			if (aTrees[sKey] == "") then
				local	iResCnt, iCurr = #oResult;
				if ((iResCnt > 0) and (strfind(aTalents[sKey], "%?") ~= nil)) then
					sText = nil;
				else
					for iCurr = 1, iResCnt do
						if (aTalents["S_" .. iCurr] == aTalents[sKey]) then
							sText = nil;
							break;
						end
					end
				end
			end

			if (sText) then
				sText = KARMA_MSG_TIP_TALENT .. KARMA_WINEL_FRAG_COLONSPACE .. sText;
				tinsert(oResult, sText);
				if (strfind(sText, "%?") == nil) then
					sSummary = sSummary .. " Talents(" .. iSpec .. ")";
				end
			end
		end
	end

	return oResult, sSummary, timeoftalents;
end

function	KarmaObj.Talents.TalentID2Distance(iTalents)
	local	sDistance = "";
	local	val = bit.band(iTalents, 24);
	if (val == 24) then
		sDistance = KARMA_TALENTS[0].color .. KARMA_MISSING_INFO_SMALL .. "|r";
	elseif (val ~= 0) then 
		local	oTalents = KARMA_TALENTS[val];
		if (oTalents) then
			local	oTalentsLocalized = KARMA_TALENTS_LOCALIZED[oTalents.key];
			if (oTalentsLocalized) then
				sDistance = oTalents.color .. oTalentsLocalized .. "|r";
			else
				sDistance = "?L";
			end
		else
			sDistance = "?T";
		end
	end

	return sDistance;
end

function	KarmaObj.Talents.TalentID2TextureDistance(iTalents, iClass)
	if ((iTalents == 0) or (iTalents == nil)) then
		return
	end

	iClass = math.abs(iClass);

	local	sDistance = "";
	if ((bit.band(iTalents, 4) == 4) and				-- only dps can choose
	    ((iClass == 1) or (iClass == 7))) then	-- Druid, Shaman, DK
		sDistance = KarmaObj.Talents.TalentID2Distance(iTalents);
		if (sDistance ~= "") then
			sDistance = "/" .. sDistance;
		end
	end

	-- "Interface\\LFGFrame\\LFGRole":
	-- 0.25: dps, 0.5: tank, 0.75: heal
	if (bit.band(iTalents, 7) == 0) then
		-- no icon to set :-(
		return sDistance;
	end

	if (bit.band(iTalents, 1) == 1) then
		-- healer
		return sDistance, "Interface\\LFGFrame\\LFGRole", 0.75, 1.0;
	end

	if (bit.band(iTalents, 6) == 2) then
		-- tank
		return sDistance, "Interface\\LFGFrame\\LFGRole", 0.5, 0.75;
	end

	if (bit.band(iTalents, 6) == 4) then
		-- dps
		if (bit.band(iTalents, 24) == 16) then
			if (iClass == 2) then				-- hunter
				return sDistance, "Interface\\Icons\\INV_Ammo_Arrow_01", 0, 1;
			elseif (iClass == 3) then			-- mage
				return sDistance, "Interface\\Icons\\Spell_Frost_IceStorm", 0, 1;
			elseif (iClass == 5) then			-- priest
				return sDistance, "Interface\\Icons\\Spell_Shadow_ImprovedVampiricEmbrace", 0, 1;
			elseif ((iClass == 1) or (iClass == 7)) then	-- druid, shaman
				-- Spell_Shaman_Thunderstorm?
				return sDistance, "Interface\\Icons\\Spell_Nature_Lightning", 0, 1;
			elseif (iClass == 9) then			-- warlock
				return sDistance, "Interface\\Icons\\Spell_Shadow_LifeDrain02", 0, 1;
			end
		end

		return sDistance, "Interface\\LFGFrame\\LFGRole", 0.25, 0.5;
	end

	if (bit.band(iTalents, 6) == 6) then
		-- feral/dk hybrid
		return sDistance, "Interface\\LFGFrame\\LFGRole", 0.25, 0.75;
	end
end

function	KarmaObj.Talents.TalentIDToColorizedText(talentid)
	if (talentid) and (talentid > 0) then
		local	talenttext = "";
		local	subid, _subid;
		local	subval = 1;
		local	skip = false;
		-- KARMA_TALENTS_MAXBITPLUS1 = 5
		-- 1(1) = hps, 2(2) = tank, 3(4) = dps <=> %8
		-- 4 (1/16) = melee, 5 (2/24) = ranged <=> %4 / % 24
		_subid = 1;
		for subid = 1, KARMA_TALENTS_MAXBITPLUS1 do
--KarmaChatDebug("subid = " .. tostring(subid) .. ", _subid = " .. tostring(_subid) .. ", talentid = " .. tostring(talentid));
			-- special cases:
			if (_subid == 1) then
				-- neither TANK nor DPS nor HPS set (multispec class)
				if (talentid % 8) == 0 then
					talenttext = talenttext .. KARMA_TALENTS[0].color .. KARMA_MISSING_INFO;
				end
			end
			if (_subid == 4) then
				talenttext = talenttext .. "|r/";
				-- neither M nor R set (multispec class)
				if (talentid % 4 == 0) then
					talenttext = talenttext .. KARMA_TALENTS[0].color .. KARMA_MISSING_INFO_SMALL;
				end
			end

			-- special case: FERAL = 6 (TANK + DPS)
			if (_subid == 2) then
				if (talentid % 4) == 3 then
					subval = 6;
					if KARMA_TALENTS[subval] then
						if KARMA_TALENTS_LOCALIZED[KARMA_TALENTS[subval].key] then
							talenttext = talenttext .. KARMA_TALENTS[subval].color .. KARMA_TALENTS_LOCALIZED[KARMA_TALENTS[subval].key];
						else
							talenttext = talenttext .. "?L";
						end
					else
						talenttext = talenttext .. "?T";
					end
	
					talentid = talentid - 3;
					talentid = talentid / 4;
					subval = 8;
					_subid = _subid + 1;
					skip = true;
				end
			end

			if not skip then
				if (talentid % 2) == 1 then
					if KARMA_TALENTS[subval] then
						if KARMA_TALENTS_LOCALIZED[KARMA_TALENTS[subval].key] then
							talenttext = talenttext .. KARMA_TALENTS[subval].color .. KARMA_TALENTS_LOCALIZED[KARMA_TALENTS[subval].key];
						else
							talenttext = talenttext .. "?L";
						end
					else
						talenttext = talenttext .. "?T";
					end
	
					talentid = talentid - 1;
				end
				talentid = talentid / 2;
				subval = subval * 2;
			else
				skip = false
			end
			_subid = _subid + 1;
		end

		if (talenttext ~= nil) then
			return talenttext .. "|r";
		end
	end

	return (KARMA_TALENTS[0].color .. KARMA_MISSING_INFO .. "|r");
end

