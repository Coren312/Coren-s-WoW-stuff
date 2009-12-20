
local	oWindow;
local	State = { Difficulty = 100 };

function	SaneLFGObj2.SetupWndToggle()
	if (oWindow:IsShown()) then
		HideUIPanel(oWindow);
	else
		ShowUIPanel(oWindow);
	end
end

local	iButtonFirst = 10;
local	iButtonLast = 19;

-- menu setups: cross using the code from SaneLFG2Window.lua

local	function	MenuDifficulty_OnClick(self, arg1, arg2)
	State.Difficulty = arg1;
	if (arg1 == 100) then
		arg2 = "Difficulty";
	end

	-- sigh... global reference
	UIDropDownMenu_SetText(SaneLFG2SetupWnd_MenuDifficulty, arg2);
end

local	function	MenuDifficulty_Initialize(oSelf, iLevel)
	SaneLFGObj2.MenuDifficulty_Initialize(oSelf, iLevel, MenuDifficulty_OnClick, State.Difficulty, 2);
end

local	function	MenuDifficulty_OnShow(self)
	SaneLFGObj2.MenuDifficulty_OnShow(self, 80, MenuDifficulty_Initialize);
end

local	iButtonSelected = nil;

local	function	MenuInstance_OnClick(self, arg1, arg2)
	if ((State.Difficulty ~= 100) and iButtonSelected) then
		local	oButton = oWindow.Buttons[iButtonSelected];
		if (not oButton) then
			ChatFrame4:AddMessage("SLFG2DBG: Failed to find button " .. tostring(iButtonSelected) .. "??");
			return
		end

		local	LFGPerRealm = SaneLFGObj2.FactionRealm.LFGPerChar;
		local	sName = oButton.Who.Name;
		if (oButton and sName and LFGPerRealm[sName]) then
			local	oLFG = LFGPerRealm[sName].oLFG;
			if (oLFG == nil) then
				oLFG = {};
				LFGPerRealm[sName].oLFG = oLFG;
			end

			local	iFound;

			local	iCnt, i = #oLFG;
			for i = 1, iCnt do
				if ((oLFG[i].sDungeon == arg2) and (oLFG[i].iDifficulty == State.Difficulty)) then
					iFound = i;
					break;
				end
			end

			if (iFound) then
				tremove(oLFG, iFound);
				if (#oLFG == 0) then
					LFGPerRealm[sName].oLFG = nil;
				end
			elseif (type(arg2) ~= "number") then
				if (#oLFG >= 5) then
					ChatFrame2:AddMessage("SaneLFG2: You may not select more than 5 places per character (currently).");
					return
				end

				local	oEntry = { sDungeon = arg2, iDifficulty = State.Difficulty, sDifficultyShort = "" };
				if (State.Difficulty % 100 == 10) then
					oEntry.sDifficultyShort = "normal";
				elseif (State.Difficulty % 100 == 20) then
					oEntry.sDifficultyShort = "heroic";
				end

				if (string.find(arg2, "daily")) then
					if (string.find(arg2, "normal")) then
						if (State.Difficulty % 100 ~= 10) then
							return
						end
					elseif (string.find(arg2, "hero")) then
						if (State.Difficulty % 100 ~= 20) then
							return
						end
					end
				end

				tinsert(oLFG, oEntry);
			else
				-- "choose all/none": n.y.i.
				ChatFrame2:AddMessage("SaneLFG2: Adding/removing whole sets is not supported yet.");
			end

			SaneLFGObj2.SetupWndButtonUpdateLFG(oButton);
		end
	end
end

local	function	MenuInstance_Initialize(oSelf, iLevel)
	if (State.Difficulty == 100) then
		ChatFrame2:AddMessage("SaneLFG2: Select a difficulty first!");
	elseif (iButtonSelected == nil) then
		ChatFrame2:AddMessage("SaneLFG2: You must choose a character!");
	else
		SaneLFGObj2.MenuInstance_Initialize(oSelf, iLevel, MenuInstance_OnClick, State.Difficulty);
	end
end

local	function	MenuInstance_OnShow(self)
	SaneLFGObj2.MenuInstance_OnShow(self, MenuInstance_Initialize);
end

-- window with
-- char [X] role1, role2, role3 lfg1, lfg2, lfg3, lfg4, lfg5
-- char [ ] role1, role2, role3 lfg1, lfg2, lfg3, lfg4, lfg5

local	oName2Btn = {};

SaneLFGObj2.Init["SetupWnd"] = function()
	oWindow = CreateFrame("Frame", "SaneLFG2SetupWnd", UIParent);
	-- standard left-sliding frame >>
	oWindow:SetAttribute("UIPanelLayout-defined", true)
	oWindow:SetAttribute("UIPanelLayout-enabled", true)
	oWindow:SetAttribute("UIPanelLayout-area", "left")
	oWindow:SetAttribute("UIPanelLayout-pushable", 2)
	oWindow:SetAttribute("UIPanelLayout-width", 520)
	oWindow:SetAttribute("UIPanelLayout-whileDead", true)
	-- standard left-sliding frame <<

	oWindow:SetWidth(520);
	oWindow:SetHeight(235);
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

	-- menu 1: normal/heroic
	local	oMenuDifficulty = CreateFrame("Frame", "SaneLFG2SetupWnd_MenuDifficulty", oWindow, "UIDropDownMenuTemplate");
	oMenuDifficulty:SetID(2);
	oMenuDifficulty:SetPoint("TOPLEFT", oWindow, "TOPLEFT", 0, - 15);
	oMenuDifficulty:SetScript("OnShow", MenuDifficulty_OnShow);
	oMenuDifficulty.bInitial = true;

	-- menu 2: instances
	local	oMenuInstance = CreateFrame("Frame", "SaneLFG2SetupWnd_MenuInstance", oWindow, "UIDropDownMenuTemplate");
	oMenuInstance:SetID(3);
	oMenuInstance:SetPoint("TOPLEFT", oWindow, "TOPLEFT", 105, - 15);
	oMenuInstance:SetScript("OnShow", MenuInstance_OnShow);
	oMenuInstance.bInitial = true;

	-- close button
	local	oCloseBtn = CreateFrame("Button", nil, oWindow, "UIPanelCloseButton");
	oCloseBtn:SetPoint("TOPRIGHT", oWindow, "TOPRIGHT", - 5, - 5);
	oWindow.CloseBtn = oCloseBtn;

	-- ========== lines: ==========

	local	oNames, k, v = {};
	local	LFGPerRealm = SaneLFGObj2.FactionRealm.LFGPerChar;
	for k, v in pairs(LFGPerRealm) do
		tinsert(oNames, k);
	end
	table.sort(oNames);

	local	oButton, i;
	oWindow.Buttons = {};
	for i = iButtonFirst, iButtonLast do
		oButton = CreateFrame("Button", "SaneLFG2SetupWnd_Btn" .. i, oWindow, "SaneLFG2MainWndBtnTemplate");
		oButton:SetID(i);

		if (i == 10) then
			oButton:SetPoint("TOPLEFT", oWindow, "TOPLEFT", 14, - 45);
		else
			oButton:SetPoint("TOPLEFT", "SaneLFG2SetupWnd_Btn" .. (i - 1), "BOTTOMLEFT");
		end

		-- make name a bit longer, crunch roles
		-- normal:
		-- 75 name, 16 LFx/Checkbox, 16 number1, 16 role1a, (8 role1b), 32 role2, 32 role3, x places
		-- crunched:
		-- 75 + 32 name, 16 CB, 16 role1, 16 role2, 16 role3, 16 + x places
		oButton.Who:SetWidth(75 + 32);
		oButton.LFx:SetPoint("TOPLEFT", oButton.Who, "TOPLEFT", 75 + 32, 0);
		oButton.Role1Cnt:SetPoint("TOPLEFT", oButton.LFx, "TOPLEFT", -12, 0);
		oButton.Role2Cnt:SetPoint("TOPLEFT", oButton.Role1Cnt, "TOPLEFT", 18, 0);
		oButton.Role3Cnt:SetPoint("TOPLEFT", oButton.Role2Cnt, "TOPLEFT", 18, 0);
		oButton.Places:SetPoint("TOPLEFT", oButton.Role3Cnt, "TOPLEFT", 60, 0);

		local	sName = oNames[1 + i - iButtonFirst];
		if (sName) then
			oName2Btn[sName] = i;
			oButton.Who.Name = sName;

			local	sNameLvl = sName;
			if (LFGPerRealm[sName].iLevel) then
				sNameLvl = string.format("%s (%.1f)", sName, LFGPerRealm[sName].iLevel);
			end
			oButton.Who:SetText("|cFFA0A0A0" .. sNameLvl .. "|r");
			local	sClassEN = LFGPerRealm[sName].sClassEN;
			if (sClassEN) then
				local	oColors = RAID_CLASS_COLORS[sClassEN];
				if (oColors) then
					oButton.Who:SetText(string.format("|cFF%.2X%.2X%.2X%s|r", oColors.r*255, oColors.g*255, oColors.b*255, sNameLvl));
				end
			end

			-- get roles from LFG tab
			local	oRoles = LFGPerRealm[sName].oRoles;
			if (oRoles) then
				local	iRoleCnt = 1;
				for i = 1, 3 do
					local	bRole, iPos;
					if ( i == 1 ) then
						bRole = oRoles.bTank;
						iPos = 0.5;
					elseif ( i == 2 ) then
						bRole = oRoles.bHeal;
						iPos = 0.75;
					else
						bRole = oRoles.bDPS;
						iPos = 0.25;
					end

					if (bRole) then
						local	oIcon1 = oButton["Role" .. iRoleCnt .. "Icon1"];
						oIcon1:SetTexture("Interface\\LFGFrame\\LFGRole");
						oIcon1:SetTexCoord(iPos, iPos + 0.25, 0, 1);

						local	oIcon2 = oButton["Role" .. iRoleCnt .. "Icon2"];
						if ( oIcon2 ) then
							oIcon2:SetTexture("");
						end

						iRoleCnt = iRoleCnt + 1;
					end
				end
			end

			SaneLFGObj2.SetupWndButtonUpdateLFG(oButton);

			oButton.Checkbox:SetScript("OnShow", function (self) SaneLFGObj2.SetupWndCheckboxOnShow(self) end);
			oButton.Checkbox:SetScript("OnClick", function (self) SaneLFGObj2.SetupWndCheckboxOnClick(self) end);
			oButton.Checkbox:Show();
		else
			oButton.Checkbox:Hide();
		end

		oButton:SetScript("OnClick", function(self) SaneLFGObj2.SetupWndButtonToggleSelect(self) end);

		oWindow.Buttons[i] = oButton;
	end

	HideUIPanel(oWindow);
	tinsert(UISpecialFrames, oWindow:GetName());
end

function	SaneLFGObj2.SetupWndButtonUpdateLFG(oButton)
	local	LFGPerRealm = SaneLFGObj2.FactionRealm.LFGPerChar;
	local	sName = oButton.Who.Name;

	LFGPerRealm[sName].sLFG = nil;
	if (LFGPerRealm[sName].sLFGUnformatted) then
		LFGPerRealm[sName].sLFG = LFGPerRealm[sName].sLFGUnformatted;
	else
		-- picked together selection
		local	oLFG = LFGPerRealm[sName].oLFG;
		if (oLFG) then
			local	sLFG = "";
			local	iCnt, i = #oLFG;
			for i = 1, iCnt do
				sLFG = sLFG .. ", " .. oLFG[i].sDungeon .. " " .. oLFG[i].sDifficultyShort;
			end

			if (strlen(sLFG) > 2) then
				LFGPerRealm[sName].sLFG = strsub(sLFG, 3);
			end
		end
	end

	-- collated or free-form LFG selection
	local	sLFG = LFGPerRealm[sName].sLFG;
	if (sLFG) then
		LFGPerRealm[sName].iAnnounce = time() - 480;
		SaneLFGObj2.AnnounceInit();

		oButton.Places:SetText(sLFG);
		oButton.Checkbox:Enable();
		oButton.Checkbox:SetChecked(LFGPerRealm[sName].bLFGActive);
	else
		LFGPerRealm[sName].bLFGActive = false;

		oButton.Places:SetText("no place(s) defined for LFG yet");
		oButton.Checkbox:Disable();
		oButton.Checkbox:SetChecked(LFGPerRealm[sName].bLFGActive);
	end
end

function	SaneLFGObj2.SetupWndCheckboxOnShow(self)
end

function	SaneLFGObj2.SetupWndCheckboxOnClick(self)
	local	oButton = self:GetParent();
	if (oButton and oButton.Who and oButton.Who.Name) then
		local	LFGPerRealm = SaneLFGObj2.FactionRealm.LFGPerChar;
		local	sName = oButton.Who.Name;
		local	oData = LFGPerRealm[sName];
		if (oData) then
			oData.bLFGActive = not oData.bLFGActive;
			oButton.Checkbox:SetChecked(oData.bLFGActive);
		end
	end
end

function	SaneLFGObj2.SetupWndButtonToggleSelect(self)
	local	iID = self:GetID();
	if (iID == iButtonSelected) then
		self:UnlockHighlight();
		iButtonSelected = nil;
	else
		local	i;
		for i = iButtonFirst, iButtonLast do
			oWindow.Buttons[i]:UnlockHighlight();
		end

		if (self.Who.Name) then
			self:LockHighlight();
			iButtonSelected = iID;
		else
			iButtonSelected = nil;
		end
	end
end

