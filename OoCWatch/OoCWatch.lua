--
-- OoCWatch.lua: Omen of Clarity Audio Notification
-- Lurosara (Cenarius-US)
--

-- ripped from Omen3:
local flasherOoC, flasherEnergyEightyPLUS;

local	function	FlasherInit(flasher, color_r, color_g, color_b, alpha)
	flasher = CreateFrame("Frame", "OoCWatchOoCFlashFrame")
	flasher:SetToplevel(true)
	flasher:SetFrameStrata("FULLSCREEN_DIALOG")
	flasher:SetAllPoints(UIParent)
	flasher:EnableMouse(false)
	flasher:Hide()
	flasher.texture = flasher:CreateTexture(nil, "BACKGROUND")
	flasher.texture:SetTexture("Interface\\FullScreenTextures\\LowHealth")
	flasher.texture:SetTexture(color_r, color_g, color_b, alpha);
	flasher.texture:SetAllPoints(UIParent)
	flasher.texture:SetBlendMode("ADD")
	flasher:SetScript("OnShow", function(self)
		self.elapsed = 0.15
		self:SetAlpha(0)
	end)
	flasher:SetScript("OnUpdate", function(self, elapsed)
		elapsed = self.elapsed + elapsed
		local alpha = elapsed % 1.3
		if alpha < 0.15 then
			self:SetAlpha(alpha / 0.15)
		elseif alpha < 0.9 then
			self:SetAlpha(1 - (alpha - 0.15) / 0.6)
		else
			self:SetAlpha(0)
		end
		self.elapsed = elapsed
	end)

	return flasher;
end

local function OoCWatch_onEvent(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, ...)
	-- FIXME: Use COMBAT_LOG_EVENT
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		-- timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags
		if arg2 == "SPELL_AURA_APPLIED" then
			if arg6 == UnitGUID("player") then
				--   spellId, spellName, spellSchool, auraType
				if arg9 == 16870 then
					flasherOoC:Show()
				end
			end
		elseif arg2 == "SPELL_AURA_REMOVED" then
			if arg6 == UnitGUID("player") then
				--   spellId, spellName, spellSchool, auraType
				if arg9 == 16870 then
					flasherOoC:Hide()
				end
			end
		end
	elseif event == "UNIT_ENERGY" and arg1 == "player" then
		if InCombatLockdown() then
			if UnitPowerType(arg1) == 3 then
				if UnitPower(arg1) >= 75 then
					flasherEnergyEightyPLUS:Show()
				else
					flasherEnergyEightyPLUS:Hide()
				end
			end
		else
			flasherEnergyEightyPLUS:Hide()
		end
	elseif strsub(event, 1, 12) == "PLAYER_REGEN" then
		flasherOoC:Hide()
		flasherEnergyEightyPLUS:Hide()
	end
end

-- Only do this if we are a Druid.
local playerClass = select(2,UnitClass("player"));
if playerClass == "DRUID" then
	flasherOoC = FlasherInit(flasherOoC, 0.0, 0.0, 1.0, 0.8)
	flasherEnergyEightyPLUS = FlasherInit(flasherEnergyEightyPLUS, 0.0, 1.0, 0.0, 0.4)

	-- Create a dummy frame so we can hook COMBAT_LOG_UNFILTERED.
	local frame = CreateFrame("Frame", "OoCWatchFrame")
	frame:SetScript("OnEvent", OoCWatch_onEvent)
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:RegisterEvent("UNIT_ENERGY")
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

