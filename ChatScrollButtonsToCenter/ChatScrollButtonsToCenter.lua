
local	function	_FCF_UpdateButtonSide(chatFrame)
	local	leftDist = math.max(0, chatFrame:GetLeft());
	local	rightDist = math.max(0, GetScreenWidth() - chatFrame:GetRight());
	local	changed = nil;
	if ( leftDist > rightDist ) then
		if ( chatFrame.buttonSide ~= "left" ) then
			FCF_SetButtonSide(chatFrame, "left");
			changed = 1;
		end
	else
		if ( chatFrame.buttonSide ~= "right" or leftDist < 0 ) then
			FCF_SetButtonSide(chatFrame, "right");
			changed = 1;
		end
	end

	return changed;
end

local	function	OnEvent(oFrame, sEvent, ...)
--[[
	if (sEvent == "ADDON_LOADED") then
		local	sWhich = ...;
		if (sWhich == "ChatScrollButtonsToCenter") then
		end
	end
]]--

	if (sEvent == "PLAYER_ENTERING_WORLD") then
		FCF_UpdateButtonSide = _FCF_UpdateButtonSide;

		local	i;
		for i = 1, 10 do
			local	oFrame = _G["ChatFrame" .. i];
			if (oFrame) then
				if (not oFrame.isLocked) then
					FCF_SetLocked(oFrame, 1);
				end

				FCF_UpdateButtonSide(oFrame);
			end
		end

		oFrame:UnregisterEvent(sEvent);
	end

	if (sEvent == "LFG_PROPOSAL_SHOW") then
		-- this doesn't belong here, but it was around...
		PlaySound("ReadyCheck");
	end
end

local	oEventframe = CreateFrame("Frame", nil, UIParent);
-- oEventframe:RegisterEvent("ADDON_LOADED");
oEventframe:RegisterEvent("PLAYER_ENTERING_WORLD");
oEventframe:RegisterEvent("LFG_PROPOSAL_SHOW");
oEventframe:SetScript("OnEvent", OnEvent);

--

-- catch "CLIENT_LOGOUT_ALERT"
hooksecurefunc("StaticPopup_Show", function(sWhich) if (sWhich == "CLIENT_LOGOUT_ALERT") then PlaySound("ReadyCheck"); end end);

