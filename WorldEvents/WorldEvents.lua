
WorldEvents = {};

local	WorldEventsHere;
local	oBuffs = {
			[3559] = { sFilter = "HELPFUL", sIcon = "Interface\\Icons\\Achievement_WorldEvent_Thanksgiving" };
	};

local	oData = { Ach = {}, Check = {} };

-- foward declarations
local	oEventframe;
local	Helpers_AddTrackedAchievement;

--
--
--

local	function	TTS(oTable)
	local	s = "";
	if (type(oTable) ~= "table") then
		return "?<" .. type(oTable) .. ">";
	else
		local	k, v;
		for k, v in pairs(oTable) do
			if (type(v) == "table") then
				s = s .. ", [" .. tostring(k) .. "] = < { " .. TTS(v) .. " } >";
			else
				s = s .. ", [" .. tostring(k) .. "] = <" .. tostring(v)  .. ">";
			end
		end
	end

	return strsub(s, 3);
end

function	WE_Dump()
	DEFAULT_CHAT_FRAME:AddMessage("WorldEventsHere = { " .. TTS(WorldEventsHere) .. " }.");
	DEFAULT_CHAT_FRAME:AddMessage("oData = { " .. TTS(oData) .. " }.");
end

local	CalenderInitState = 0;

function	WorldEvents_CalenderInit()
	if (CalenderInitState) then
		if (CalenderInitState == 0) then
			CalenderInitState = time() + 30;

			Calendar_LoadUI();
			Calendar_Show();
			Calendar_Hide();
--			local	_, iMonth, iDay, iYear = CalendarGetDate();
--			CalendarSetAbsMonth(iMonth, iYear);
		elseif (CalenderInitState > time()) then
			CalenderInitState = nil;
		end

		return false;
	end

	local	iCnt, i;

	local	oCandidates = {};
	local	monthOffset = 0;
	local	_, iMonth, iDay, iYear = CalendarGetDate();
	CalendarSetAbsMonth(iMonth, iYear);
	iCnt = CalendarGetNumDayEvents(monthOffset, iDay);
	if (iCnt > 0) then
		local	k;
		for k = 1, iCnt do
			local title, hour, minute, calendarType, sequenceType = CalendarGetDayEvent(monthOffset, iDay, k);
			if (calendarType == "HOLIDAY") then
				DEFAULT_CHAT_FRAME:AddMessage("World event " .. k .. ": " .. title);
				tinsert(oCandidates, title);
			end
		end
	end

	if (#oCandidates == 0) then
		DEFAULT_CHAT_FRAME:AddMessage("WorldEvents: No candidates today.");
		return true;
	end

	-- 155: World Events
	local	oCatAll = GetCategoryList();
	local	oCatWorldEvents = {};
	iCnt = #oCatAll;
	for i = 1, iCnt do
		local	title, parent = GetCategoryInfo(oCatAll[i]);
		if (parent == 155) then
			local	k;
			for k = 1, #oCandidates do
				if (strfind(strlower(oCandidates[k]), strlower(title))) then
					tinsert(oCatWorldEvents, oCatAll[i]);
					break
				end
			end
		end
	end

	iCnt = #oCatWorldEvents;
	for i = 1, iCnt do
		local	iCat = oCatWorldEvents[i]; 
		local	iAchCnt, k = GetCategoryNumAchievements(iCat);
		for k = 1, iAchCnt do
			local	iAch, sName, _, bDone = GetAchievementInfo(iCat, k);
			if (not bDone) then
				-- DEFAULT_CHAT_FRAME:AddMessage("A: " .. iAch .. " (" .. sName .. ") checking...");
				Helpers_AchievementCheck(iAch, sName);
			end
		end
	end

	return true;
end

function	Helpers_AchievementCheck(id, sName)
	local	iCnt, i = GetAchievementNumCriteria(id);
	if (sName == nil) then
		local	_;
		_, sName = GetAchievementInfo(id);
	end
	if (iCnt > 2) then
		local	oPotential = {};
		local	iTotal = 0;
		for i = 1, iCnt do
			local	criteriaString, criteriaType, completed, quantity, reqQuantity = GetAchievementCriteriaInfo(id, i);
			local	criteriaStringUpper = " " .. strupper(criteriaString) .. " ";
			local	sRace, sClass, iSub = false;
			for iSub = 1, 4 do
				local	k, v;
				for k, v in pairs(WorldEventsHere[iSub]) do
					if (strfind(criteriaStringUpper, " " .. v .. " ", 1, true)) then
						if (iSub <= 2) then
							sRace = k;
						else
							sClass = k;
						end
					end
				end
			end

			if (sRace or sClass) then
				iTotal = iTotal + 1;
				if (not completed) then
					DEFAULT_CHAT_FRAME:AddMessage("A: " .. id .. "." .. i .. " => " .. criteriaString .. " (" .. (sRace or "any") .. "/" .. (sClass or "any") .. ")");
					oPotential[#oPotential + 1] = { iPos = i, sCriteria = criteriaString, sRace = sRace, sClass = sClass };
				end
			end
		end

		-- race/class always have at least 3 combinations to drive players crazy
		if (iTotal >= 3) then
			local	iFound = #oData.Ach + 1;
			iCnt = #oData.Ach;
			for i = 1, iCnt do
				if (oData.Ach[i].id == id) then
					iFound = i;
					break;
				end
			end
			oData.Ach[iFound] = { id = id, sName = sName, oSub = oPotential };

			iCnt = #oPotential;
			for i = 1, iCnt do
				if (oPotential[i].sClass) then
					oData.Check[oPotential[i].sClass] = true;
				end
				if (oPotential[i].sRace) then
					oData.Check[oPotential[i].sRace] = true;
				end
			end

			DEFAULT_CHAT_FRAME:AddMessage("A: " .. id .. " \"" .. sName .. "\" => pushed.");
			oEventframe:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
		end
	end
end

--
--
--

local	function	OnEvent(oFrame, sEvent, ...)
	if (sEvent == "ADDON_LOADED") then
		local	sWhich = ...;
		if (sWhich == "WorldEvents") then
			local	sRealm = GetCVar("realmName");
			if (WorldEvents[sRealm] == nil) then
				WorldEvents[sRealm] = {};
			end
			local	sLocale = GetLocale();
			if (WorldEvents[sLocale] == nil) then
				WorldEvents[sLocale] = { [1] = {}, [2] = {}, [3] = {}, [4] = {} };
			end
			WorldEventsHere = WorldEvents[sLocale];

			hooksecurefunc("AddTrackedAchievement", Helpers_AchievementCheck);
			oFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
		end

		return
	end

	if (sEvent == "UPDATE_MOUSEOVER_UNIT") then
		if (#oData.Ach == 0) then
			if (not WorldEvents_CalenderInit()) then
				return
			end

			if (#oData.Ach == 0) then
				DEFAULT_CHAT_FRAME:AddMessage("WorldEvents: Nothing current and/or missing today.");
				oFrame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT");
				return
			end
		end

		if (UnitExists("mouseover") and UnitIsPlayer("mouseover")) then
			local	sFaction = UnitFactionGroup("mouseover");
			local	sRace, sRaceEN = UnitRace("mouseover");
			local	sClass, sClassEN = UnitClass("mouseover");
			local	iSex = UnitSex("mouseover");
			if (not sFaction or not sRace or not sClass or not iSex) then
				return
			end

			if (WorldEventsHere[iSex - 1][sRaceEN] == nil) then
				WorldEventsHere[iSex - 1][sRaceEN] = strupper(sRace);
			end
			if (WorldEventsHere[iSex + 1][sClassEN] == nil) then
				WorldEventsHere[iSex + 1][sClassEN] = strupper(sClass);
			end

			if (oData.Check[sRaceEN] or oData.Check[sClassEN]) then
				local	oRef;

				local	iCnt, i = #oData.Ach;
				for i = 1, iCnt do
					local	bBuffOk = true;
					local	iAch = oData.Ach[i].id;
					if (oBuffs[iAch]) then
						-- check if the unit already has the buff we want to put on
						local	sAchFilter = oBuffs[iAch].sFilter;
						local	sAchIcon = oBuffs[iAch].sIcon;
						local	l;
						for l = 1, 40 do
							local	_, _, sIcon = UnitAura("mouseover", l, sAchFilter);
							if (sIcon and (sIcon == sAchIcon)) then
								-- DEFAULT_CHAT_FRAME:AddMessage("WorldEvents: Target has buff.");
								bBuffOk = false;
							end
						end
					end

					if (bBuffOk) then
						local	iCntSub, iSub = #oData.Ach[i].oSub;
						for iSub = 1, iCntSub do
							local	oEntry = oData.Ach[i].oSub[iSub];
							local	bOk = true;
							if (oEntry.sRace) then
								bOk = bOk and (oEntry.sRace == sRaceEN);
							end
							if (oEntry.sClass) then
								bOk = bOk and (oEntry.sClass == sClassEN);
							end

							if (bOk) then
								oRef = { iAch = oData.Ach[i].id, sAch = oData.Ach[i].sName, iSub = iSub, oData = oEntry };
								break;
							end
						end
					end
				end

				if (oRef) then
					local	s1, s2 = UnitName("mouseover");
					s2 = "|Hplayer:" .. s1 .. "|h[" .. s1 .. "]|r";
					-- UIFrameFlash(UIParent, 0.15, 0.15, 0.3, true, 0, 0);
					-- UIFrameFlash(Minimap, 0.15, 0.15, 0.3, true, 0, 0);
					-- UIFrameFlash(MainMenuBar, 0.15, 0.15, 0.3, true, 0, 0);
					UIFrameFlash(WatchFrame, 0.15, 0.15, 0.3, true, 0, 0);
					PlaySound("Fishing Reel in");
					DEFAULT_CHAT_FRAME:AddMessage(sRace .. " " .. sClass .. " => " .. s2 .. " for " .. oRef.iAch .. ": \"" .. oRef.sAch .. "\" part " .. oRef.iSub .. " (" .. oRef.oData.sCriteria .. ")");
				end
			end
		end
	end
end

oEventframe = CreateFrame("Frame", nil, UIParent);
oEventframe:RegisterEvent("ADDON_LOADED");
oEventframe:SetScript("OnEvent", OnEvent);


