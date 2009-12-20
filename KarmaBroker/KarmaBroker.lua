
KarmaBroker = { LDBMenu = {} };

function	KarmaBroker.OnLoad()
	KarmaBrokerEventframe:RegisterEvent("ADDON_LOADED");

--	hooksecurefunc(GameTooltip, "AddTexture", KarmaBroker.SH_GTT_AT);
end

--[[
function	KarmaBroker.SH_GTT_AT(self, sName, iXMin, iXMax, iYMin, iYMax)
	local	sMsg = "KB.SH_GTT_AT: " .. sName;
	if (iXMin) then
		sMsg = sMsg .. " => " .. iXMin .. ", " .. iXMax .. ", " .. iYMin .. ", " .. iYMax;
	end
	DEFAULT_CHAT_FRAME:AddMessage(sMsg);
end
]]--

function	KarmaBroker.OnEvent(self, event, ...)
	local	arg1 = ...;
	if (event == "ADDON_LOADED") and (arg1 == "KarmaBroker") then
		local	oData = {
				type = "launcher",
				label = " Karma",
				icon = "Interface\\AddOns\\KarmaBroker\\YinYang",
				OnClick = function(clickedframe, mousebtn)
						KarmaBroker.LDBAction(clickedframe, mousebtn);
					end,
				OnEnter = function(oFrame)
						KarmaBroker.LDBTooltipShow(oFrame);
					end,
				OnLeave = function()
						KarmaBroker.LDBTooltipHide();
					end,
			};

		local ldb = LibStub:GetLibrary("LibDataBroker-1.1");
		ldb:NewDataObject("KarmaBroker", oData);
	end
end

local	OnEventSum = 0;

function	KarmaBroker.OnUpdateEvent(iElapsed)
	OnEventSum = OnEventSum + iElapsed;
	if (OnEventSum < 0.2) then
		return
	end

	OnEventSum = 0;
	if (KarmaBroker.TooltipHide) then
		if (GameTooltip:GetOwner() ~= KarmaBroker.LDBTooltipFrame) then
			KarmaBroker.LDBTooltipFrame = nil;
			KarmaBroker.LDBTooltipIsMine = false;

			KarmaBroker.TooltipHide = false;
		elseif (not MouseIsOver(GameTooltip, 5, 5, 5, 5)) then
			if (GameTooltip:GetOwner() == KarmaBroker.LDBTooltipFrame) then
				GameTooltip:Hide();
			end

			KarmaBroker.LDBTooltipFrame = nil;
			KarmaBroker.LDBTooltipIsMine = false;

			KarmaBroker.TooltipHide = false;
		end
	end
end

function	KarmaBroker.LDBAction(clickedframe, mousebtn)
	if (mousebtn == "LeftButton") then
		Karma_ToggleWindow();
	elseif (mousebtn == "MiddleButton") then
		Karma_ToggleWindow2();
	elseif (mousebtn == "RightButton") then
		if (GameTooltip:GetOwner() == KarmaBroker.LDBTooltipFrame) then
			GameTooltip:Hide();
		end
		KarmaBroker.LDBTooltipFrame = nil;
		KarmaBroker.LDBTooltipIsMine = false;

		ToggleDropDownMenu(1, nil, Karma_Minimap_Menu, clickedframe, 30, 30);
	end
end

function	KarmaBroker.LDBTooltipShow(oFrame)
	KarmaBroker.TooltipHide = false;
	KarmaBroker.LDBTooltipFrame = oFrame;
	KarmaBroker.LDBTooltipIsMine = true;

	GameTooltip:SetOwner(oFrame, "ANCHOR_TOPLEFT");
	GameTooltip:AddLine("[Karma: Broker] by Kärbär@EU-Proudmoore", 1, 1, 0);

	local	WhoAmI = UnitName("player");

	local	function	UnitToLine(sUnit, iLinesMax)
			local	sName, sServer, sLineL, sLineR, iTextureOffset1, iTextureOffset2 = UnitName(sUnit);
			if (sServer and (sServer ~= "")) then
				sName = sName .. "@" .. sServer;
			end

			if (sName == WhoAmI) then
				return nil;
			end

			local	oMember = Karma_MemberList_GetObject(sName);
			if (oMember) then
				local	iKarma = Karma_MemberObject_GetKarmaModified(oMember);
				local	sClassWOGender = Karma_MemberObject_GetClassWOGender(oMember);
				local	dClassR, dClassG, dClassB = Karma_ClassMToColor(sClassWOGender);

				sLineL = format("|cFF%.2X%.2X%.2X%s|r [lvl %d]:", dClassR * 255, dClassG * 255, dClassB * 255, sName, UnitLevel(sUnit));

				local	sKarma, iKarma = Karma_MemberObject_GetKarmaModifiedForListWithColors(oMember);
				if (sKarma and (iKarma ~= 50)) then
					sLineL = sLineL .. ", Karma " .. sKarma;
				end

				local	sPrivate = Karma_MemberObject_GetPrivateNotesCut(oMember, iLinesMax, iLinesMax * 50);
				if (sPrivate and (sPrivate ~= "")) then
					sLineR = "--> private notes:\n" .. sPrivate;
				end

				local	bGotPriv = sLineR ~= nil;
				if (not bGotPriv) then
					sLineR = "";
				end

				local	sTalents1 = Karma_MemberObject_GetTalentColorizedText(oMember, 1);
				local	sTalents, bDual, sTalents2 = sTalents1, false;
				if (KarmaAvEnK.Talents.SpecCount >= 2) then
					sTalents2 = Karma_MemberObject_GetTalentColorizedText(oMember, 2);
					if (sTalents2 and (sTalents2 ~= sTalents1) and (strfind(sTalents2, "%?") == nil)) then
						if (strfind(sTalents1, "%?") == nil) then
							bDual = true;
							sTalents = sTalents .. "+" .. sTalents2;
						else
							sTalents1 = sTalents2;
							sTalents2 = nil;

							sTalents = sTalents1;
						end
					end
				end
				if (sTalents and (sTalents ~= "")) then
					if (bGotPriv) then
						sLineL = sLineL .. "\n=> talents: " .. sTalents;
					else
						sLineR = sLineR .. ", <" .. sTalents .. ">";
					end
				end

				-- need to look for active spec!
				-- 0.25: dps, 0.5: tank, 0.75: heal
				if (sTalents1 and not strfind(sTalents1, "%?")) then
					local	bHaveFeral, bHaveDPS, bHaveTANK = false, false, false
					if (strfind(sTalents1, "DPS")) then
						bHaveDPS = true;
						iTextureOffset1 = 0.25;
					elseif (strfind(sTalents1, "TANK")) then
						bHaveTANK = true;
						iTextureOffset1 = 0.5;
					elseif (strfind(sTalents1, "HPS")) then
						iTextureOffset1 = 0.75;
					elseif (strfind(sTalents1, "FERAL")) then
						bHaveFeral = true;
					end

					if (bDual) then
						if (strfind(sTalents2, "DPS")) then
							bHaveDPS = true;
							iTextureOffset2 = 0.25;
						elseif (strfind(sTalents2, "TANK")) then
							bHaveTANK = true;
							iTextureOffset2 = 0.5;
						elseif (strfind(sTalents2, "HPS")) then
							iTextureOffset2 = 0.75;
						elseif (strfind(sTalents2, "FERAL")) then
							bHaveFeral = true;
						end
					end

					if (iTextureOffset2 and (iTextureOffset1 == nil)) then
						iTextureOffset1 = iTextureOffset2;
						iTextureOffset2 = nil;
					end

					if (bHaveFeral) then
						if (not bHaveDPS and not bHaveTANK) then
							if (iTextureOffset1 == nil) then
								iTextureOffset1 = 0.25;
								iTextureOffset2 = 0.5;
							elseif (iTextureOffset2 == nil) then
								iTextureOffset2 = 0.5;
							end
						elseif (bHaveDPS ~= bHaveTANK) then
							if (iTextureOffset2 == nil) then
								iTextureOffset2 = 0.75 - iTextureOffset1;
							end
						end
					end
				end
--DEFAULT_CHAT_FRAME:AddMessage("1: " .. (iTextureOffset1 or "<nil>") .. ", 2: " .. (iTextureOffset2 or "<nil>"));

				local	sSkill = Karma_MemberObject_GetSkillText(oMember);
				if (sSkill) then
					if (bGotPriv) then
						sLineL = sLineL .. "\n=> skill: *" .. sSkill .. "*";
					else
						sLineR = sLineR .. ", skill: *" .. sSkill .. "*";
					end
				end

				local	sPublic = Karma_MemberObject_GetPublicNotes(oMember);
				if (sPublic and (sPublic ~= "")) then
					if (bGotPriv) then
						sLineL = sLineL .. "\n=> public notes: \"" .. sPublic .. "\"";
					else
						sLineR = sLineR .. ", pub. notes: \"" .. sPublic .. "\"";
					end
				end

				if (not bGotPriv and (sLineR ~= "")) then
					sLineR = strsub(sLineR, 3);
				end
				if (sLineR == "") then
					sLineR = nil;
				end
			else
				local	_, sClass = UnitClass(sUnit);
				local	Colors = RAID_CLASS_COLORS[sClass];
				if (type(Colors) == "table") then
					sLineL = format("|cFF%.2X%.2X%.2X", Colors.r * 255, Colors.g * 255, Colors.b * 255);
				else
					sLineL = "|cFF808080";
				end
				sLineL = sLineL .. sName .. "|r [lvl " .. UnitLevel(sUnit) .. "]: |cFFFFFF00unknown to Karma|r";
			end

			return sLineL, sLineR, iTextureOffset1, iTextureOffset2;
		end

	local	function	LinesToTip(sUnit, iLinesMax)
			local	sLineL, sLineR, iTextureOffset1, iTextureOffset2 = UnitToLine(sUnit, iLinesMax);
			local	sLSplit, sRSplit;
			if (sLineL and sLineR) then
				-- this is not working if the newline counts don't match
				-- => make them match
				local	iL, iR = 1, 1;
				local	sTmp = sLineL;
				iPos = strfind(sTmp, "\n");
				while (iPos) do
					iL = iL + 1;
					sTmp = strsub(sTmp, iPos + 1);
					iPos = strfind(sTmp, "\n");
				end
				if ((iL > 1) and (sTmp == "")) then
					iL = iL - 1;
				end
				local	sTmp = sLineR;
				iPos = strfind(sTmp, "\n");
				while (iPos) do
					iR = iR + 1;
					sTmp = strsub(sTmp, iPos + 1);
					iPos = strfind(sTmp, "\n");
				end
				if ((iR > 1) and (sTmp == "")) then
					iR = iR - 1;
				end

				if (iL < iR) then
					local	i;
					for i = iL + 1, iR do
						sLineL = sLineL .. "\n ";
					end
				elseif (iL > iR) then
					local	i;
					for i = iR + 1, iL do
						sLineR = sLineR .. "\n ";
					end
				end

				if (iTextureOffset2 ~= nil) then
					local	iPosL = strfind(sLineL, "\n");
					if (iPosL) then
						sLSplit = strsub(sLineL, iPosL + 1);
						sLineL = strsub(sLineL, 1, iPosL - 1);
					end
					local	iPosR = strfind(sLineR, "\n");
					if (iPosR) then
						sRSplit = strsub(sLineL, iPosR + 1);
						sLineR = strsub(sLineR, 1, iPosR - 1);
						if (sLSplit == nil) then
							sLSplit = "";
						end
					end
				end

				GameTooltip:AddDoubleLine(sLineL, sLineR);
			elseif (sLineL) then
				if (iTextureOffset2 ~= nil) then
					local	iPosL = strfind(sLineL, "\n");
					if (iPosL) then
						sLSplit = strsub(sLineL, iPosL + 1);
						sLineL = strsub(sLineL, 1, iPosL - 1);
					end
				end

				GameTooltip:AddLine(sLineL);
			end

			if (iTextureOffset1 == nil) then
				GameTooltip:AddTexture("");
			else
				GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", iTextureOffset1, iTextureOffset1 + 0.25, 0, 1);
			end

			if (sLSplit and sRSplit) then
				GameTooltip:AddDoubleLine(sLSplit, sRSplit);
			elseif (sLSplit) then
				GameTooltip:AddLine(sLSplit);
			end
			if (iTextureOffset2 ~= nil) then
				if (sLSplit == nil) then
					GameTooltip:AddLine(" ");
				end
				GameTooltip:AddTexture("Interface\\LFGFrame\\LFGRole", iTextureOffset2, iTextureOffset2 + 0.25, 0, 1);
			end
		end

	local	bAnything = false;
	if (GetNumRaidMembers() > 0) then
		bAnything = true;

		GameTooltip:AddLine(" ");
		local	iCnt, i = GetNumRaidMembers();
		GameTooltip:AddLine("Raid: " .. iCnt .. " members");
		for i = 1, iCnt do
			LinesToTip("raid".. i, 2);
		end
	elseif (GetNumPartyMembers() > 0) then
		bAnything = true;

		GameTooltip:AddLine(" ");
		local	iCnt, i = GetNumPartyMembers();
		GameTooltip:AddLine("Group: " .. iCnt .. " members");
		for i = 1, iCnt do
			LinesToTip("party".. i, 4);
		end
	end

	if (UnitIsPlayer("target") and UnitIsFriend("player", "target") and not UnitIsUnit("player", "target")) then
		bAnything = true;

		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("Target:");
		LinesToTip("target", 6);
	end

	if (not bAnything) then
		GameTooltip:AddLine("Click left to open Karma's main window");
		GameTooltip:AddLine("Click middle to open Karma's LFM window");
		GameTooltip:AddLine("Click right for a menu");

		local	sCQLInfo, sCQLInfoL, sCQLInfoR = KarmaAvEnK.BrokerCallback.CQLInfo();
		if (sCQLInfo) then
			GameTooltip:AddLine(" ");
			GameTooltip:AddLine(sCQLInfo);
			if (sCQLInfoL and sCQLInfoR) then
				GameTooltip:AddDoubleLine(sCQLInfoL, sCQLInfoR);
			end
		end
	end

	GameTooltip:Show();
end

function	KarmaBroker.LDBTooltipHide()
	KarmaBroker.TooltipHide = true;
end

