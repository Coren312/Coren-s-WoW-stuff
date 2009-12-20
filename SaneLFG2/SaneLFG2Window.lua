
local	oWindow;

function	SaneLFGObj2.MainWndToggle()
	if (oWindow:IsShown()) then
		HideUIPanel(oWindow);
	else
		ShowUIPanel(oWindow);
	end
end

local	iButtonFirst = 10;
local	iButtonLast = 29;

local	State = { LFx = 100, Difficulty = 100, Instance = {} };

local	function	MenuLFx_OnClick(self, arg1, arg2)
	if (arg1 and (State.LFx ~= arg1)) then
		State.LFx = arg1;
		if (arg1 == 100) then
			arg2 = "LFx";
		end
		-- sigh... global reference
		UIDropDownMenu_SetText(SaneLFG2MainWnd_MenuLFx, arg2);
		SaneLFGObj2.MainWndButtonFilterChange();
	end
end

local	function	MenuLFx_Initialize()
	local	oData = {
			{ ID = 100, Name = "Any", },
			{ ID = 200, Name = "LFG/Unknown", },
			{ ID = 300, Name = "LFM/Unknown", },
			{ ID = 400, Name = "Only LFG", },
			{ ID = 500, Name = "Only LFM", },
			};

	local	info, i;

	for i = 1, 5 do
		info = {};
		info.text = oData[i].Name;
		info.func = MenuLFx_OnClick;
		info.arg1 = oData[i].ID;
		info.arg2 = info.text;
		if (State.LFx == info.arg1) then
			info.checked = true;
		end
		UIDropDownMenu_AddButton(info);
	end
end

local	function	MenuLFx_OnShow(self)
	if (self.bInitial) then
		self.bInitial = false;
	 	UIDropDownMenu_SetWidth(self, 95);
	 	UIDropDownMenu_SetButtonWidth(self, 24);
		UIDropDownMenu_JustifyText(self, "LEFT");
		UIDropDownMenu_SetText(self, "LFx");
	end

 	UIDropDownMenu_Initialize(self, MenuLFx_Initialize);
end

local	function	MenuDifficulty_OnClick(self, arg1, arg2)
	if (arg1 and (State.Difficulty ~= arg1)) then
		State.Difficulty = arg1;
		if (arg1 == 100) then
			arg2 = "Difficulty";
		end
		-- sigh... global reference
		UIDropDownMenu_SetText(SaneLFG2MainWnd_MenuDifficulty, arg2);
		SaneLFGObj2.MainWndButtonFilterChange();
	end
end

local	oMenuDifficulty = {
		[1] = {
			{ ID = 100, Name = "Any", },
			{ ID = 110, Name = "NORMAL/Unknown", },
			{ ID = 120, Name = "HEROIC/Unknown", },
			{ ID = 130, Name = "RAID/Unknown", },
			{ ID = 210, Name = "Only NORMAL", },
			{ ID = 220, Name = "Only HEROIC", },
			{ ID = 230, Name = "Only RAID", },
		},
		[2] = {
			{ ID = 100, Name = "Undefined", },
			{ ID = 110, Name = "NORMAL", },
			{ ID = 120, Name = "HEROIC", },
			{ ID = 160, Name = "RAID-10", },		-- BC and later raids
			{ ID = 175, Name = "RAID-25", },		-- BC and later raids
			{ ID = 170, Name = "RAID-20", },		-- pre-BC raids
			{ ID = 190, Name = "RAID-40", },		-- pre-BC raids
		},
	};

function	SaneLFGObj2.MenuDifficulty_Initialize(oSelf, iLevel, fFunc, iValue, iTable)
	if (iTable and oMenuDifficulty[iTable]) then
		iLevel = iLevel or 1;
		local	oMenu = oMenuDifficulty[iTable];

		local	iCnt, i, info = #oMenu;
		for i = 1, iCnt do
			info = {};
			info.text = oMenu[i].Name;
			info.func = fFunc;
			info.arg1 = oMenu[i].ID;
			info.arg2 = info.text;
			if (info.arg1 == iValue) then
				info.checked = true;
			end

			UIDropDownMenu_AddButton(info, iLevel);
		end
	end
end

local	function	MenuDifficulty_Initialize(oSelf, iLevel)
	SaneLFGObj2.MenuDifficulty_Initialize(oSelf, iLevel, MenuDifficulty_OnClick, State.Difficulty, 1);
end

function	SaneLFGObj2.MenuDifficulty_OnShow(self, iWidth, fInit)
	if (self.bInitial) then
		self.bInitial = false;
	 	UIDropDownMenu_SetWidth(self, iWidth);
	 	UIDropDownMenu_SetButtonWidth(self, 24);
		UIDropDownMenu_JustifyText(self, "LEFT");
		UIDropDownMenu_SetText(self, "Difficulty");
	end

 	UIDropDownMenu_Initialize(self, fInit);
end

local	function	MenuDifficulty_OnShow(self)
	SaneLFGObj2.MenuDifficulty_OnShow(self, 120, MenuDifficulty_Initialize);
end

local	function	MenuInstance_OnClick(self, arg1, arg2)
end

local	oMenuInstance = {
		[1] = "pre-BC era",
		[2] = "BC era",
		[3] = "older WotLK",
		[4] = "younger WotLK",
	};

function	SaneLFGObj2.MenuInstance_Initialize(oSelf, iLevel, fFunc, iDifficulty2)
	iLevel = iLevel or 1;
	local	info;

	if (iLevel == 1) then
		local	iFirst, iLast, i = 1, #oMenuInstance;
		if (iDifficulty2) then
			local	iDiffSub = iDifficulty2 % 100;
			if ((iDiffSub == 20) or (iDiffSub == 60) or (iDiffSub == 75)) then
				-- no heroic, raid10, raid25 in old world
				iFirst = 2;
			end
			if ((iDiffSub == 70) or (iDiffSub == 90)) then
				-- no raid20, raid40 after BC?
				iLast = 2;
			end
		end
		for i = iFirst, iLast do
			info = {};
			info.text = oMenuInstance[i];
			info.value = i;
			info.notCheckable = true;
			info.hasArrow = true;
			UIDropDownMenu_AddButton(info, iLevel);
		end
	elseif (iLevel == 2) then
		local	iSet = UIDROPDOWNMENU_MENU_VALUE;
		info = {};
		info.text = "Select ALL";
		info.func = fFunc;
		info.arg1 = nil;
		info.arg2 = 100 + iSet;
		UIDropDownMenu_AddButton(info, iLevel);

		info = {};
		info.text = "Select NONE";
		info.func = fFunc;
		info.arg1 = nil;
		info.arg2 = 200 + iSet;
		UIDropDownMenu_AddButton(info, iLevel);

		info = {};
		info.text = "Invert selection";
		info.func = fFunc;
		info.arg1 = nil;
		info.arg2 = 300 + iSet;
		UIDropDownMenu_AddButton(info, iLevel);

		info = {};
		info.text = "- - - - - - - - - - - - - - - ";
		info.notClickable = true;
		UIDropDownMenu_AddButton(info, iLevel);

		local	oDungeons = SaneLFG2Locales.Current.Messages.DungeonsShort[iSet];
		if (oDungeons) then
			local	iRaidSize;
			if (iDifficulty2) then
				if (iDifficulty2 % 100 > 50) then
					iRaidSize = (iDifficulty2 % 100) - 50;
				elseif (iDifficulty2 % 100 >= 10) then
					iRaidSize = 5;
				end
			end

			local	oOut = {};
			local	k, v;
			for k, v in pairs(oDungeons) do
				local	match = string.match(k, "(%d+)");
				if (match) then
					if (not iRaidSize or (iRaidSize == tonumber(match))) then
						tinsert(oOut, "R " .. k);
					end
				elseif (not iRaidSize or (iRaidSize == 5)) then
					tinsert(oOut, "D " .. k);
				end
			end

			table.sort(oOut);

			v = #oOut;
			for k = 1, v do
				info = {};
				info.text = iSet .. ": " .. oOut[k];
				info.func = fFunc;
				info.arg1 = strsub(oOut[k], 1, 1);
				info.arg2 = strsub(oOut[k], 3);
				UIDropDownMenu_AddButton(info, iLevel);
			end
		end
	end
end

local	function	MenuInstance_Initialize(oSelf, iLevel)
	SaneLFGObj2.MenuInstance_Initialize(oSelf, iLevel, MenuInstance_OnClick);
end

function	SaneLFGObj2.MenuInstance_OnShow(self, fInit)
	if (self.bInitial) then
		self.bInitial = false;
	 	UIDropDownMenu_SetWidth(self, 95);
	 	UIDropDownMenu_SetButtonWidth(self, 24);
		UIDropDownMenu_JustifyText(self, "LEFT");
		UIDropDownMenu_SetText(self, "Instances");
	end

 	UIDropDownMenu_Initialize(self, fInit);
end

local	function	MenuInstance_OnShow(self)
	SaneLFGObj2.MenuInstance_OnShow(self, MenuInstance_Initialize);
end

SaneLFGObj2.Init["MainWnd"] = function()
	oWindow = CreateFrame("Frame", "SaneLFG2MainWnd", UIParent);
	-- standard left-sliding frame >>
	oWindow:SetAttribute("UIPanelLayout-defined", true)
	oWindow:SetAttribute("UIPanelLayout-enabled", true)
	oWindow:SetAttribute("UIPanelLayout-area", "left")
	oWindow:SetAttribute("UIPanelLayout-pushable", 2)
	oWindow:SetAttribute("UIPanelLayout-width", 520)
	oWindow:SetAttribute("UIPanelLayout-whileDead", true)
	-- standard left-sliding frame <<

	oWindow:SetWidth(520);
	oWindow:SetHeight(455);
	oWindow:SetPoint("CENTER", 0, 0);

	oWindow:SetScript("OnMouseDown", function () if (arg1 == "LeftButton") then oWindow:StartMoving(); end end);
	oWindow:SetScript("OnMouseUp", function () oWindow:StopMovingOrSizing(); end);

	oWindow:EnableMouse(true);
	oWindow:SetMovable(true);
	oWindow:SetFrameStrata("DIALOG");

	local	oBackdrop = {
		-- bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		bgFile = "Interface\\AddOns\\SaneLFG2\\MainWndBG",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	};
	oWindow:SetBackdrop(oBackdrop);

	-- ========== elements at top ==========

	-- menus MUST have a frame name!
	-- menu 1: any/lfg+any/lfm+any/lfg strict/lfm strict
	local	oMenuLFx = CreateFrame("Frame", "SaneLFG2MainWnd_MenuLFx", oWindow, "UIDropDownMenuTemplate");
	oMenuLFx:SetID(1);
	oMenuLFx:SetPoint("TOPLEFT", oWindow, "TOPLEFT", 0, - 15);
	oMenuLFx:SetScript("OnShow", MenuLFx_OnShow);
	oMenuLFx.bInitial = true;

	-- menu 2: normal/heroic
	local	oMenuDifficulty = CreateFrame("Frame", "SaneLFG2MainWnd_MenuDifficulty", oWindow, "UIDropDownMenuTemplate");
	oMenuDifficulty:SetID(2);
	oMenuDifficulty:SetPoint("TOPLEFT", oWindow, "TOPLEFT", 120, - 15);
	oMenuDifficulty:SetScript("OnShow", MenuDifficulty_OnShow);
	oMenuDifficulty.bInitial = true;

	-- menu 3: instances (TODO: new window for it)
	local	oMenuInstance = CreateFrame("Frame", "SaneLFG2MainWnd_MenuInstance", oWindow, "UIDropDownMenuTemplate");
	oMenuInstance:SetID(3);
	oMenuInstance:SetPoint("TOPLEFT", oWindow, "TOPLEFT", 265, - 15);
	oMenuInstance:SetScript("OnShow", MenuInstance_OnShow);
	oMenuInstance.bInitial = true;

	-- Setup button
	local	oSetup = CreateFrame("Button", nil, oWindow, "UIPanelButtonTemplate");
	oSetup:SetPoint("TOPLEFT", oWindow, "TOPLEFT", 400, - 15 - 1);
	oSetup:SetWidth(80);
	oSetup:SetHeight(25);
	oSetup:SetText("Setup");
	oSetup:SetScript("OnClick", function () SaneLFGObj2.SetupWndToggle() end);
	oWindow.oSetup = oSetup;

	-- close button
	local	oCloseBtn = CreateFrame("Button", nil, oWindow, "UIPanelCloseButton");
	oCloseBtn:SetPoint("TOPRIGHT", oWindow, "TOPRIGHT", - 5, - 5);
	oWindow.CloseBtn = oCloseBtn;

	-- ========== lines: ==========
	local	OnEnter = function(self) SaneLFGObj2.MainWndButtonEnter(self) end;
	local	OnClick = function(self, button) SaneLFGObj2.MainWndButtonClick(self, button) end;

	local	oButton, i;
	oWindow.Buttons = {};
	for i = iButtonFirst, iButtonLast do
		oButton = CreateFrame("Button", "SaneLFG2MainWnd_Btn" .. i, oWindow, "SaneLFG2MainWndBtnTemplate");
		oButton:SetID(i);

		if (i == 10) then
			oButton:SetPoint("TOPLEFT", oWindow, "TOPLEFT", 14, - 45);
		else
			oButton:SetPoint("TOPLEFT", "SaneLFG2MainWnd_Btn" .. (i - 1), "BOTTOMLEFT");
		end

		oButton:SetText("Button " .. i);
		oButton.Checkbox:Hide();

		oButton:SetScript("OnEnter", OnEnter);
		oButton:SetScript("OnClick", OnClick);
		oButton:SetScript("OnLeave", GameTooltip_Hide);

		oWindow.Buttons[i] = oButton;
	end

	-- ========== elements at bottom ==========

	oButton = CreateFrame("Button", "SaneLFG2MainWnd_Tip", oWindow);
	oButton:SetID(1);
	oButton:SetPoint("TOPLEFT", "SaneLFG2MainWnd_Btn" .. iButtonLast, "BOTTOMLEFT");
	oButton:SetWidth(492);
	oButton:SetHeight(44);

	-- no documentation that makes (working) sense for how to pin the font object of a button :-(
	-- therefore, not using the button font, but smacking another one on top of it, that IS pinnable
	local	oFontString = oButton:CreateFontString("SaneLFG2MainWnd_TipFont", "ARTWORK", "GameFontNormalSmallLeft");
	oFontString:SetPoint("TOPLEFT", oButton, "TOPLEFT");
	oFontString:SetPoint("BOTTOMRIGHT", oButton, "BOTTOMRIGHT");

	oWindow.Tip = oFontString;
	HideUIPanel(oWindow);
	tinsert(UISpecialFrames, oWindow:GetName());
end

local	iButtonNext = 0;
local	oNames = {};
local	oName2Btn = {};

function	SaneLFGObj2.MainWndButtonFilterChange()
	-- drop all old data
	local	iBtn;
	for iBtn = iButtonFirst, iButtonLast do
		local	oButton = oWindow.Buttons[iBtn];
		SaneLFGObj2.MainWndButtonClear(oButton);
	end

	-- repopulate by time:
	local	oNamesAndTimes, oDrop = {}, {};
	local	iNow, iCnt, k, v = time();
	for k, v in pairs(SaneLFGObj2.FactionRealm.ParsedChannel) do
		if (v.iUpdatedAt < iNow - 1200) then
			tinsert(oDrop, k);
		else
			oNamesAndTimes[#oNamesAndTimes + 1] = { iAt = v.iUpdatedAt, sName = k };
		end
	end

	-- drop entries older than 20m without feedback
	iCnt = #oDrop;
	if (iCnt > 0) then
		for k = 1, iCnt do
			SaneLFGObj2.FactionRealm.ParsedChannel[oDrop[k]] = nil;
		end
	end

	iCnt = #oNamesAndTimes;
	for k = 1, iCnt - 1 do
		for v = k + 1, iCnt do
			if (oNamesAndTimes[k].iAt > oNamesAndTimes[v].iAt) then
				local	x = oNamesAndTimes[k];
				oNamesAndTimes[k] = oNamesAndTimes[v];
				oNamesAndTimes[v] = x;
			end
		end
	end

	iButtonNext = 0;
	for k = 1, iCnt do
		local	oTotal = SaneLFGObj2.FactionRealm.ParsedChannel[oNamesAndTimes[k].sName];
		SaneLFGObj2.MainWndButtonSetup(oTotal.oFrom, oTotal.oData, oTotal.iUpdatedAt);
	end
end

function	SaneLFGObj2.MainWndButtonFilterCheck(oFrom, oData)
	local	bIn = true;
	if (State.LFx ~= 100) then
		if ((State.LFx == 200) and not oData.bLFG) then
			bIn = false;
		elseif ((State.LFx == 300) and not oData.bLFM) then
			bIn = false;
		elseif ((State.LFx == 400) and (not oData.bLFG or oData.bLFM)) then
			bIn = false;
		elseif ((State.LFx == 500) and (oData.bLFG or not oData.bLFM)) then
			bIn = false;
		end
	end
	if (State.Difficulty ~= 100) then
		local	iWhich = State.Difficulty % 100;
		local	bStrict = State.Difficulty >= 200;
		local	oValues = oData.oDungeons[1];
		local	bAnything = oValues.bNormal or oValues.bHeroic or oValues.bRaid;
		if (bStrict or bAnything) then
			if (iWhich == 10) then
				if (not oData.oDungeons[1].bNormal) then
					bIn = false;
				end
			end
			if (iWhich == 20) then
				if (not oData.oDungeons[1].bHeroic) then
					bIn = false;
				end
			end
			if (iWhich == 30) then
				if (not oData.oDungeons[1].bRaid) then
					bIn = false;
				end
			end
		end
	end

	return bIn;
end

function	SaneLFGObj2.MainWndButtonSetup(oFrom, oData, iAt)
	-- if this is pure refresh, use previous button
	local	iBtnOld, oButtonOld;
	if (oName2Btn[oFrom.sFrom]) then
		local	iBtnOld = oName2Btn[oFrom.sFrom];
		local	oButtonOld = oWindow.Buttons[iBtnOld];
		if (oData.sRaw1 == oButtonOld.sRaw) then
			oButtonOld.MsgAt = iAt;
			SaneLFGObj2.MainWndButtonUpdateTimers();
			return
		end
	end

	-- check if it's in the filter
	local	bIn = SaneLFGObj2.MainWndButtonFilterCheck(oFrom, oData);
	if (not bIn) then
		oNames[oFrom.sFrom] = nil;
		if (iBtnOld) then
			oName2Btn[oFrom.sFrom] = nil;
		else
			return
		end
	end

	oNames[oFrom.sFrom] = iAt;

	local	iBtn, oButton;
	if (oName2Btn[oFrom.sFrom] ~= nil) then
		-- re-use old button
		iBtn = oName2Btn[oFrom.sFrom];
		oButton = oWindow.Buttons[iBtn];
	end

	if (oButton == nil) then
		-- find a new button...

		-- first, look if we have an unused one
		local	iAge, iPos = time();
		local	iBtnRange, iBtnOff = 1 + iButtonLast - iButtonFirst;
		for iBtnOff = 0, iButtonLast - iButtonFirst do
			iBtn = (iButtonNext + iBtnOff) % iBtnRange;
			oButton = oWindow.Buttons[iButtonFirst + iBtn];
			if (oButton.Who.Name == nil) then
				break
			end
			if (oButton.MsgAt < iAge) then
				iPos = iBtn;
				iAge = oButton.MsgAt;
			end
		end

		if (oButton) then
			iButtonNext = iBtn + 1;
			iBtn = iBtn + iButtonFirst;
		else
			-- no luck? drop the oldest one
			iBtn = iPos + iButtonFirst;
			oButton = oWindow.Buttons[iBtn];
		end
	end

	SaneLFGObj2.MainWndButtonSetupDo(oButton, oFrom, oData);
	oName2Btn[oFrom.sFrom] = iBtn;

	oButton.MsgAt = iAt;

	SaneLFGObj2.MainWndButtonUpdateTimers();
end

function	SaneLFGObj2.MainWndButtonClear(oButton)
	if (oButton.Who.Name and oName2Btn[oButton.Who.Name]) then
		oName2Btn[oButton.Who.Name] = nil;
	end

	oButton:SetText("");
	oButton.sRaw = nil;
	oButton.Who:SetText("");
	oButton.Who.Name = nil;
	oButton.Who.Contact = nil;
	oButton.LFx:SetTexture("");

	local	i;
	for i = 1, 3 do
		local	oText = oButton["Role" .. i .. "Cnt"];
		if ( oText ) then
			oText:SetText("");
		end

		local	oIcon1 = oButton["Role" .. i .. "Icon1"];
		oIcon1:SetTexture("");
		local	oIcon2 = oButton["Role" .. i .. "Icon2"];
		if ( oIcon2 ) then
			oIcon2:SetTexture("");
		end
	end

	oButton.Places:SetText("");
	oButton.Tip = nil;
	oButton.MsgAt = nil;
	oButton.Slider:Hide();
end

function	SaneLFGObj2.MainWndButtonSetupDo(oButton, oFrom, oData)
	if (oButton) then
		oButton:SetText("");
		oButton.sRaw = oData.sRaw1;

		if (oFrom.sClassEN) then
			local	oColors = RAID_CLASS_COLORS[oFrom.sClassEN];
			if (oColors) then
				oButton.Who:SetText(string.format("|cFF%.2X%.2X%.2X%s|r", oColors.r*255, oColors.g*255, oColors.b*255, oFrom.sFrom));
			else
				oButton.Who:SetText("|cFFA0A0A0" .. oFrom.sFrom .. "|r");
			end
		else
			oButton.Who:SetText("|cFFA0A0A0" .. oFrom.sFrom .. "|r");
		end
		oButton.Who.Name = oFrom.sFrom;
		if (oFrom.sViaName) then
			SaneLFGObj2.Maps.NameToContact[oFrom.sFrom] = oFrom.sViaName;
			oButton.Who.Contact = oFrom.sViaName;
		end

		if ( oData.bLFG and oData.bLFM or not oData.bLFG and not oData.bLFM ) then
			oButton.LFx:SetTexture("Interface\\Icons\\Spell_Shadow_SoothingKiss.png‎");
		elseif ( oData.bLFG ) then
			oButton.LFx:SetTexture("Interface\\Icons\\Spell_Holy_DivineSpirit.png‎");
		elseif ( oData.bLFM ) then
			oButton.LFx:SetTexture("Interface\\Icons\\Spell_Holy_PrayerofSpirit.png‎");
		end

		local	iRoleCnt, i = 1;

		-- reset role icons:
		for i = 1, 3 do
			local	oIcon1 = oButton["Role" .. iRoleCnt .. "Icon1"];
			oIcon1:SetTexture("");

			if (i == 1) then
				local	oIcon2 = oButton["Role" .. i .. "Icon2"];
				oIcon2:SetTexture("");
				local	oIcon3 = oButton["Role" .. i .. "Icon3"];
				oIcon3:SetTexture("");
			end
		end

		-- the only real difference between LFG and LFM is that LFG needs no numbers
		local	bNoCnt = oData.bLFG and not oData.bLFM;

		-- well, LFM has also *mixed* role icons
		-- currently only parsing any-role and *one* bi-role

		-- dps/tank and tank/heal can be pulled at once, dps/heal must be puzzled together
		-- that's why we have a normal icon and two half-icons on the first role
		if ((oData.iTankDPS == 1) or (oData.iTankHeal == 1) or (oData.iDPSHeal == 1)) then
			if (oData.iTankDPS == 1) then
				local	oText = oButton["Role" .. iRoleCnt .. "Cnt"];
				if ( oText ) then
					oText:SetText("");
				end

				local	oIcon1 = oButton["Role" .. iRoleCnt .. "Icon1"];
				oIcon1:SetTexture("Interface\\LFGFrame\\LFGRole");
				oIcon1:SetTexCoord(0.25, 0.75, 0, 1);

				iRoleCnt = iRoleCnt + 1;
			elseif (oData.iTankHeal) then
				local	oText = oButton["Role" .. iRoleCnt .. "Cnt"];
				if ( oText ) then
					oText:SetText("");
				end

				local	oIcon1 = oButton["Role" .. iRoleCnt .. "Icon1"];
				oIcon1:SetTexture("Interface\\LFGFrame\\LFGRole");
				oIcon1:SetTexCoord(0.5, 1, 0, 1);

				iRoleCnt = iRoleCnt + 1;
			elseif (oData.iDPSHeal) then
				local	oText = oButton["Role" .. iRoleCnt .. "Cnt"];
				if ( oText ) then
					oText:SetText("");
				end

				local	iRoleNow = 1;
				if (iRoleCnt ~= 1) then
					-- swap first to current, use first
				end

				local	oIcon = oButton["Role" .. iRoleNow .. "Icon1"];
				oIcon:SetTexture("");

				local	oIcon2 = oButton["Role" .. iRoleNow .. "Icon2"];
				oIcon2:SetTexture("Interface\\LFGFrame\\LFGRole");
				oIcon2:SetTexCoord(0.25, 0.5, 0, 1);

				local	oIcon3 = oButton["Role" .. iRoleNow .. "Icon3"];
				oIcon3:SetTexture("Interface\\LFGFrame\\LFGRole");
				oIcon3:SetTexCoord(0.75, 1, 0, 1);

				iRoleCnt = iRoleCnt + 1;
			end
		end

		-- iDPSHeal MUST be on the first icon, that's why this is coming after bi-roles
		if (oData.iRoleAny) then
			local	oText = oButton["Role" .. iRoleCnt .. "Cnt"];
			if (oText) then
				if (bNoCnt) then
					oText:SetText("");
				else
					oText:SetText(oData.iRoleAny);
				end
			end

			local	oIcon1 = oButton["Role" .. iRoleCnt .. "Icon1"];
			oIcon1:SetTexture("Interface\\LFGFrame\\LFGRole");
			oIcon1:SetTexCoord(0.25, 1, 0, 1);

			iRoleCnt = iRoleCnt + 1;
		end

		for i = 1, 3 do
			local	iRole, iPos;
			if ( i == 1 ) then
				iRole = oData.iTank;
				iPos = 0.5;
			elseif ( i == 2 ) then
				iRole = oData.iHeal;
				iPos = 0.75;
			else
				iRole = oData.iDPS;
				iPos = 0.25;
			end

			if ( iRole ) then
				if (iRole < 0) then
					iRole = math.abs(iRole) .. "?";
				end
				local	oText = oButton["Role" .. iRoleCnt .. "Cnt"];
				if ( oText ) then
					if (bNoCnt) then
						oText:SetText("");
					else
						oText:SetText(iRole);
					end
				end

				local	oIcon1 = oButton["Role" .. iRoleCnt .. "Icon1"];
				oIcon1:SetTexture("Interface\\LFGFrame\\LFGRole");
				oIcon1:SetTexCoord(iPos, iPos + 0.25, 0, 1);

				local	oIcon2 = oButton["Role" .. iRoleCnt .. "Icon2"];
				if ( oIcon2 ) then
					oIcon2:SetTexture("");
					local	oIcon3 = oButton["Role" .. iRoleCnt .. "Icon3"];
					if (oIcon3) then
						oIcon3:SetTexture("");
					end
				end

				iRoleCnt = iRoleCnt + 1;
			end
		end

		for i = iRoleCnt, 3 do
			local	oText = oButton["Role" .. i .. "Cnt"];
			if ( oText ) then
				oText:SetText("");
			end

			local	oIcon1 = oButton["Role" .. i .. "Icon1"];
			oIcon1:SetTexture("");
			local	oIcon2 = oButton["Role" .. i .. "Icon2"];
			if ( oIcon2 ) then
				oIcon2:SetTexture("");
				local	oIcon3 = oButton["Role" .. iRoleCnt .. "Icon3"];
				if (oIcon3) then
					oIcon3:SetTexture("");
				end
			end
		end

		-- places: currently just a string
		local	oPlaces = oButton.Places;
		if ( oPlaces ) then
			local	oDungeons = oData.oDungeons;
			if ( #oDungeons > 1 ) then
				local	sOut = "";
				local	iCnt, i = #oDungeons;
				for i = 2, iCnt do
					if (oDungeons[i].bNegative) then
						sOut = sOut .. ", |cFFFF8080not|r " .. oDungeons[i].sName;
					else
						sOut = sOut .. ", " .. oDungeons[i].sName;
					end
				end

				oPlaces:SetText("<" .. strsub(sOut, 3) .. ">");
				if (oDungeons[1].sDungeonQualifier) then
					oPlaces:SetText("<" .. oDungeons[1].sDungeonQualifier .. ": " .. strsub(sOut, 3) .. ">");
				end
			else
				local	sText;
				if ( oData.sWhat ) then
					sText = oData.sWhat;
				elseif ( oData.sSub ) then
					sText = oData.sSub;
				end

				if (sText) then
					if (string.find(sText, "|h")) then
						sText = string.gsub(sText, "|h([^%[|])", "|H%1");
					end
					oPlaces:SetText(sText);
				else
					oPlaces:SetText("???");
				end
			end
		end

		local	sTip, k, v = "";
		for k, v in pairs(oData) do
			if (type(v) == "table") then
				-- dungeons
				if (k == "oDungeons") then
					local	s, iCnt, i = "", #v;
					for i = 2, iCnt do
						if (v[i].bNegative) then
							s = s .. ", |cFFFF8080not|r " .. v[i].sName;
						else
							s = s .. ", " .. v[i].sName;
						end
					end
					if (v[1].sDungeonQualifier) then
						s = ", " .. v[1].sDungeonQualifier .. ": " .. strsub(s, 3);
					end

					if (strlen(s) > 2) then
						sTip = sTip .. "[" .. k .. "] = <" .. strsub(s, 3) .. ">\n";
					end
				else
					sTip = sTip .. "[" .. k .. "] = { " .. SaneLFGObj2.Helpers.stringfromtable(v) .. " }\n";
				end
			else
				sTip = sTip .. "[" .. k .. "] = <" .. tostring(v) .. ">\n";
			end
		end

		if (string.find(sTip, "|h")) then
			sTip = string.gsub(sTip, "|h([^%[|])", "|H%1");
		end
		oButton.Tip = sTip;
		oButton.sChannel = oData.sChannel;
	end
end

function	SaneLFGObj2.MainWndButtonUpdateTimers()
	SaneLFGObj2.Youngest = 0;
	local	iNow = time();
	local	iBtn, oButton;
	for iBtn = iButtonFirst, iButtonLast do
		oButton = oWindow.Buttons[iBtn];
		local	iAt = oButton.MsgAt or 0;
		local	iWidth = iNow - iAt;
		if ( iWidth > 900 ) then
			SaneLFGObj2.MainWndButtonClear(oButton);
		else
			SaneLFGObj2.Youngest = math.max(SaneLFGObj2.Youngest, iAt);
			if ( iWidth > 600 ) then
				oButton.Slider:Hide();
				oButton:SetAlpha(math.max(0.2, (900 - iWidth) / 600));
			else
				local	dCurrent = iWidth / 300;
				-- 0, 1, 0.5 => 1, 1, 0.5 => 1, 0, 0.5
				oButton.Slider:SetStatusBarColor(math.min(dCurrent, 1.0), math.min(1.0, 2.0 - dCurrent), 0.25);
				oButton.Slider:SetValue(iWidth);
				oButton.Slider:Show();
				oButton:SetAlpha(math.min(1.0, (900 - iWidth) / 600));
			end
		end
	end

	if ( SaneLFGObj2.Youngest + 600 >= iNow ) then
		SaneLFGObj2.SliderUpdate = 1;
	else
		SaneLFGObj2.SliderUpdate = nil;
	end
end

function	SaneLFGObj2.MainWndButtonEnter(oButton)
	if (oButton and oButton.Tip) then
		GameTooltip:SetOwner(oButton, "ANCHOR_BOTTOMRIGHT");
		local	sTip = "";
		if (SaneLFG2Global.Config.bDebug) then
			sTip = "\n" .. oButton.Tip;
		else
			if (oButton.sChannel) then
				sTip = " in [" .. oButton.sChannel .. "] :";
			end
			if (oButton.sRaw) then
				sTip = sTip .. "\n" .. oButton.sRaw;
			end
		end
		if (oButton.MsgAt) then
			local	iNow = time();
			local	iMin = math.floor((iNow - oButton.MsgAt) / 60);
			local	iSec = (iNow - oButton.MsgAt) % 60;
			local	sAt = date(" at [%H:%M] (", oButton.MsgAt) .. iMin .. "m" .. iSec .. "s ago)";
			sTip = sAt .. sTip;
		end
		sTip = oButton.Who:GetText() .. sTip;
		GameTooltip:SetText(sTip);
		GameTooltip:Show();

		local	sText = "[" .. oButton.sChannel .. "] " .. oButton.Who:GetText() .. ": " .. oButton.sRaw;
		oWindow.Tip:SetText(sText);
	end
end

function	SaneLFGObj2.MainWndButtonClick(oButton, sMouse)
	if (oButton and oButton.Who and oButton.Who.Name and (sMouse == "LeftButton")) then
		if (oButton.Who.Contact) then
			ChatFrame_OpenChat("/slfg2 chat as <your alt> with " .. oButton.Who.Name .. " ");
		else
			if (IsShiftKeyDown()) then
				SendWho(oButton.Who.Name);
			else
				ChatFrame_SendTell(oButton.Who.Name);
			end
		end
	end
end

