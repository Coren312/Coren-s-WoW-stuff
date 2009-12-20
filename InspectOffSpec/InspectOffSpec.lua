

local	InspectOff = {};

local	oEventframe = CreateFrame("Frame", nil, UIParent);
oEventframe:RegisterEvent("ADDON_LOADED");

function	InspectOff.OnEvent(oFrame, sEvent, ...)
	if (sEvent == "ADDON_LOADED") then
		local	sWhich = ...;
		if (sWhich == "InspectOffSpec") then
			hooksecurefunc("InspectFrame_LoadUI", InspectOff.Init);
		end
	end
end

oEventframe:SetScript("OnEvent", InspectOff.OnEvent);

function	InspectOff.InspectFrame_UpdateTalentTab()
	if ( not InspectFrame.unit ) then
		return;
	end

	local level = UnitLevel(InspectFrame.unit);
	if ( level > 0 and level < 10 ) then
		PanelTemplates_DisableTab(InspectFrame, 3);
		PanelTemplates_DisableTab(InspectFrame, 4);
		local	iPanel = PanelTemplates_GetSelectedTab(InspectFrame);
		if ( iPanel == 3 or iPanel == 4 ) then
			InspectSwitchTabs(1);
		end
	else
		PanelTemplates_EnableTab(InspectFrame, 3);
		PanelTemplates_EnableTab(InspectFrame, 4);
		InspectTalentFrame_UpdateTabs();
	end
end

function	InspectOff.InspectTalentFrame_Refresh(bShow)
	InspectTalentFrame.talentGroup = GetActiveTalentGroup(InspectTalentFrame.inspect);

	local	iHasOff = GetNumTalentGroups(InspectTalentFrame.inspect);
	local	iPanel = PanelTemplates_GetSelectedTab(InspectFrame);
	if ( not bShow ) then
		if ( iHasOff == 1 ) then
			PanelTemplates_DisableTab(InspectFrame, 4);
			if ( iPanel == 4 ) then
				InspectSwitchTabs(3);
			end
		elseif ( iHasOff > 1 ) then
			PanelTemplates_EnableTab(InspectFrame, 4);
		end
	end
	if (( iHasOff > 1 ) and ( iPanel == 4 )) then
		InspectTalentFrame.talentGroup = 3 - GetActiveTalentGroup(InspectTalentFrame.inspect);
	end
	-- DEFAULT_CHAT_FRAME:AddMessage("Refresh: iHasOff = " .. tostring(iHasOff) .. ", iPanel = " .. tostring(iPanel) .. ", iTalentGroup = " .. tostring(InspectTalentFrame.talentGroup));

	InspectTalentFrame.unit = InspectFrame.unit;
	TalentFrame_Update(InspectTalentFrame);
end


function	InspectOff.InspectTalentFrame_OnShow()
	InspectTalentFrame:RegisterEvent("INSPECT_TALENT_READY");
	InspectOff.InspectTalentFrame_Refresh(true);
end

function	InspectOff.Init()
	-- create 4th tab button
--[[
	<Button name="InspectFrameTab3" inherits="CharacterFrameTabButtonTemplate" id="3" text="TALENTS">
		<Anchors>
		   <Anchor point="LEFT" relativeTo="InspectFrameTab2" relativePoint="RIGHT">
				<Offset>
					<AbsDimension x="-16" y="0"/>
				</Offset>
			</Anchor>
		</Anchors>
		<Scripts>
			<OnClick function="InspectFrameTab_OnClick"/>
			<OnEnter>
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(TALENTS, 1.0,1.0,1.0 );
			</OnEnter>
			<OnLeave function="GameTooltip_Hide"/>
		</Scripts>
	</Button>
]]--
	if ( InspectFrameTab4 == nil ) then
		local	oFrame = CreateFrame("Button", "InspectFrameTab4", InspectFrame, "CharacterFrameTabButtonTemplate");
		oFrame:SetID(4);
		oFrame:SetText(TALENTS .. "(2)");
		oFrame:SetPoint("LEFT", "InspectFrameTab3", "RIGHT", -16, 0);
		oFrame:SetScript("OnClick", InspectFrameTab_OnClick);

		-- enable 4th tab
		PanelTemplates_SetNumTabs(InspectFrame, 4);
		PanelTemplates_SetTab(InspectFrame, 1);

		InspectTalentFrame:Hide();

		-- overwrites
		InspectFrame_UpdateTalentTab = InspectOff.InspectFrame_UpdateTalentTab;
		InspectTalentFrame_OnShow = InspectOff.InspectTalentFrame_OnShow;
		InspectTalentFrame:SetScript("OnShow", InspectTalentFrame_OnShow);
	end
end

