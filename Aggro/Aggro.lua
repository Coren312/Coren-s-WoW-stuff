
local	AggroCmdHandler;

local	iTimer;

local	oCurrent = {};
local	sTankUnit;
local	oRoles = {};

local	function	CheckParty()
	iTimer = 86400;
	local	iCnt = GetRealNumPartyMembers();
	if (iCnt == 4) then
		local	iDPS, iOther = 0, 0;

		local	i;
		for i = 1, 5 do
			local	sUnit = "party" .. i;
			if (i == 5) then
				sUnit = "player";
			end

			local	sName, sServer = UnitName(sUnit);
			if (sServer and (sServer ~= "")) then
				sName = sName .. "@" .. sServer;
			end

			oCurrent[i] = sName;
			if (sName == nil) then
				return
			end

			if (oRoles[sName] == nil) then
				oRoles[sName] = {};
			end

			if (type(UnitGroupRolesAssigned) == "function") then
				local	bTank, bHeal, bDPS = UnitGroupRolesAssigned(sUnit);
				if (bTank) then
					if (not oRoles[sName].bTank) then
						ChatFrame1:AddMessage("Aggro: <" .. sName .. "> => tank");
					end
					oRoles[sName].bTank = true;
					oRoles[sName].bHeal = nil;
					oRoles[sName].bOther = true;
					oRoles[sName].bDPS = nil;
				elseif (bHeal) then
					if (not oRoles[sName].bHeal) then
						ChatFrame1:AddMessage("Aggro: <" .. sName .. "> => heal");
					end
					oRoles[sName].bTank = nil;
					oRoles[sName].bHeal = true;
					oRoles[sName].bOther = true;
					oRoles[sName].bDPS = nil;
				elseif (bDPS) then
					if (not oRoles[sName].bDPS) then
						ChatFrame1:AddMessage("Aggro: <" .. sName .. "> => dps");
					end
					oRoles[sName].bTank = nil;
					oRoles[sName].bHeal = nil;
					oRoles[sName].bOther = nil;
					oRoles[sName].bDPS = true;
				end
			end

			oRoles[sName].iUnit = i;
			oRoles[sName].sUnit = sUnit;
			if (oRoles[sName].bDPS) then
				iDPS = iDPS + 1;
			elseif (oRoles[sName].bOther) then
				iOther = iOther + 1;
			end
		end

		if (iOther == 2) then
			for i = 1, 5 do
				local	sName = oCurrent[i];
				if (not oRoles[sName].bOther) then
					oRoles[sName].bDPS = true;
				end
			end
		elseif (iDPS == 3) then
			for i = 1, 5 do
				local	sName = oCurrent[i];
				if (not oRoles[sName].bDPS) then
					oRoles[sName].bOther = true;
				end
			end
		end

		sTankUnit = nil;
		iDPS, iOther = 0, 0;
		for i = 1, 5 do
			local	sName = oCurrent[i];
			if (oRoles[sName]) then
				if (oRoles[sName].bDPS) then
					iDPS = iDPS + 1;
				elseif (oRoles[sName].bOther) then
					iOther = iOther + 1;
					if (oRoles[sName].bTank) then
						sTankUnit = oRoles[sName].sUnit;
					end
				end
			end
		end

		if ((iDPS ~= 3) or (iOther ~= 2)) then
			ChatFrame1:AddMessage("Aggro: Must define missing roles. Current status: #DPS = " .. iDPS .. ", #Other = " .. iOther .. ".");
		else
			iTimer = 1;
		end
	end
end

local	function	OnEvent(oFrame, sEvent, ...)
	if (sEvent == "ADDON_LOADED") then
		local	sWhich = ...;
		if (sWhich == "Aggro") then
			-- init
			iTimer = 86400;

			SLASH_AGGRO1 = "/aggro";
			SlashCmdList["AGGRO"] = AggroCmdHandler;
		end
	end

	if (sEvent == "PARTY_MEMBERS_CHANGED") then
		CheckParty();
	end
end

local	function	OnUpdate(oFrame, iElapsed)
	iTimer = iTimer - iElapsed;
	if (iTimer < 0) then
		iTimer = 1;

		local	iCnt, i = GetRealNumPartyMembers();
		for i = 1, iCnt do
			local	sName = oCurrent[i];
			if (oRoles[sName] and oRoles[sName].bDPS) then
				local	sUnit = "party" .. i;
				local	sTarget = sUnit .. "target";
				if (UnitExists(sTarget)) then
					local	bDPSTanking, _, _, _, iDPSThreatRaw = UnitDetailedThreatSituation(sUnit, sTarget);
					if (bDPSTanking) then
						if (sTankUnit) then
							local	_, _, _, iTankThreatPct, iTankThreatRaw = UnitDetailedThreatSituation(sTankUnit, sTarget);
							if (iTankThreatRaw) then
								ChatFrame2:AddMessage("|cFFFFFF00Aggro: <" .. sName .. "> pulled ahead of the tank, threat margin: " .. (iTankThreatRaw - iDPSThreatRaw) .. ", relative threat: " .. (100 / (iTankThreatPct / 100)) .. "|r");
							else
								ChatFrame2:AddMessage("|cFFFF4040Aggro: <" .. sName .. "> solos <" .. UnitName(sTarget) .. ">.|r");
							end
						else
							ChatFrame2:AddMessage("|cFFFFA000Aggro: <" .. sName .. "> is having the full attention of <" .. UnitName(sTarget) .. ">.|r");
						end
					end
				end
			end
		end
	end
end

local	oEventframe = CreateFrame("Frame", nil, UIParent);
oEventframe:RegisterEvent("ADDON_LOADED");
oEventframe:RegisterEvent("PARTY_MEMBERS_CHANGED");
oEventframe:SetScript("OnEvent", OnEvent);
oEventframe:SetScript("OnUpdate", OnUpdate);

AggroCmdHandler = function(sText)
	if (strsub(sText, 1, 5) == "role ") then
		if (strsub(sText, 6, 9) == "tank") then
			local	sName, sServer = UnitName("target");
			if (sServer and (sServer ~= "")) then
				sName = sName .. "@" .. sServer;
			end
			if (not oRoles[sName]) then
				oRoles[sName] = {};
			end
			oRoles[sName].bDPS = nil;
			oRoles[sName].bOther = true;
			oRoles[sName].bTank = true;

			local	iUnit = oRoles[sName].iUnit;
			if (iUnit) then
				if (iUnit == 5) then
					sTankUnit = "player";
				else
					sTankUnit = "party" .. iUnit;
				end
			end
			ChatFrame1:AddMessage("Aggro: " .. sName .. " is now marked as 'tank'.");
		elseif (strsub(sText, 6, 9) == "heal") then
			local	sName, sServer = UnitName("target");
			if (sServer and (sServer ~= "")) then
				sName = sName .. "@" .. sServer;
			end
			if (not oRoles[sName]) then
				oRoles[sName] = {};
			end
			oRoles[sName].bDPS = nil;
			oRoles[sName].bOther = true;
			oRoles[sName].bHeal = true;
			ChatFrame1:AddMessage("Aggro: " .. sName .. " is now marked as 'heal'.");
		elseif (strsub(sText, 6, 8) == "dps") then
			local	sName, sServer = UnitName("target");
			if (sServer and (sServer ~= "")) then
				sName = sName .. "@" .. sServer;
			end
			if (not oRoles[sName]) then
				oRoles[sName] = {};
			end
			oRoles[sName].bOther = nil;
			oRoles[sName].bDPS = true;
			ChatFrame1:AddMessage("Aggro: " .. sName .. " is now marked as 'dps'.");
		else
			ChatFrame1:AddMessage("Aggro: Target a player, then issue '/aggro role tank|heal|dps'.");
			return
		end

		CheckParty();
	elseif (sText == "dump") then
		local	iCnt, i, sUnit = GetRealNumPartyMembers();
		for i = 1, iCnt + 1 do
			if (i <= iCnt) then
				sUnit = "party" .. i;
			else
				sUnit = "player";
			end
			local	sName, sServer = UnitName(sUnit);
			if (sServer and (sServer ~= "")) then
				sName = sName .. "@" .. sServer;
			end
			if (oRoles[sName]) then
				local	s, k, v = "";
				for k, v in pairs(oRoles[sName]) do
					s = s .. ", [" .. k .. "] = <" .. tostring(v) .. ">";
				end
				ChatFrame1:AddMessage("Aggro: <" .. sName .. "> => " .. strsub(s, 3));
			end
		end
	elseif (sText == "reset") then
		oRoles = {};
		ChatFrame1:AddMessage("Aggro: All role assigments have been reset.");
	else
		ChatFrame1:AddMessage("Aggro: Missing or unknown command. Valid commands are: role, reset.");
	end
end

