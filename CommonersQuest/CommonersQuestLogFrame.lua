
local	CQData = nil;
local	CQDataX = nil;
local	CQDataGlobal = nil;
local	CQH = CommonersQuest.Helpers;

function	CommonersQuest.Initializers.QLog(CQDataMain, CQDataXMain, CQDataGlobalMain)
	CQData = CQDataMain;
	CQDataX = CQDataXMain;
	CQDataGlobal = CQDataGlobalMain;
end

-- log state flags
CommonersQuest.Log.State = {};
-- current content
CommonersQuest.Log.Rows = {};
-- expanded header lines
CommonersQuest.Log.State.Expanded = {};

-- frame containers
CommonersQuest.Log.FrameMain = {};
CommonersQuest.Log.FrameQuest = {};

-- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## --
-- ## ---- ## ---- ## ---- ## -- 3.2 adaptions (start) --- ## ---- ## ---- ## --
-- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## --

-- dropped with 3.2 from QuestLogFrame.lua:
-- QUESTS_DISPLAYED = 6;
-- QUESTLOG_QUEST_HEIGHT = 16;
local	QUESTS_DISPLAYED = QUESTS_DISPLAYED or 6;
local	QUESTLOG_QUEST_HEIGHT = QUESTLOG_QUEST_HEIGHT or 16;
-- moved to Constants.lua and slightly renamed:
local	QuestDifficultyColor = QuestDifficultyColors;

-- 
-- local helper functions -- two more arguments and I could've used the original function :-(
--

local function _QuestLog_HighlightQuest(questLogTitle)
  local prevParent = CommonersQuestLogHighlightFrame:GetParent();
  if ( prevParent and prevParent ~= questLogTitle ) then
    -- set prev quest's colors back to normal
    local prevName = prevParent:GetName();
    prevParent:UnlockHighlight();
    prevParent.tag:SetTextColor(prevParent.r, prevParent.g, prevParent.b);
    prevParent.groupMates:SetTextColor(prevParent.r, prevParent.g, prevParent.b);
  end
  if ( questLogTitle ) then
    local name = questLogTitle:GetName();
    -- highlight the quest's colors
    questLogTitle.tag:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    questLogTitle.groupMates:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    questLogTitle:LockHighlight();
    -- reposition highlight frames
    CommonersQuestLogHighlightFrame:SetParent(questLogTitle);
    CommonersQuestLogHighlightFrame:SetPoint("TOPLEFT", questLogTitle, "TOPLEFT", 0, 0);
    CommonersQuestLogHighlightFrame:SetPoint("BOTTOMRIGHT", questLogTitle, "BOTTOMRIGHT", 0, 0);
    CommonersQuestLogSkillHighlight:SetVertexColor(questLogTitle.r, questLogTitle.g, questLogTitle.b);
    CommonersQuestLogHighlightFrame:Show();
  else
    QuestLogHighlightFrame:Hide();
  end
end


function	CommonersQuest.Log.QuestListScrollFrame_OnLoad(self)
  HybridScrollFrame_OnLoad(self);
--  self.update = QuestLog_Update;
  HybridScrollFrame_CreateButtons(self, "CommonersQuestLogTitleButtonTemplate");
end

function CommonersQuest.Log.DetailFrame_AttachToQuestLog()
  CommonersQuestLogDetailScrollFrame:SetParent(CommonersQuestLogFrame);
  CommonersQuestLogDetailScrollFrame:ClearAllPoints();
  CommonersQuestLogDetailScrollFrame:SetPoint("TOPRIGHT", CommonersQuestLogFrame, "TOPRIGHT", -32, -77);
  CommonersQuestLogDetailScrollFrame:SetHeight(333);
  CommonersQuestLogDetailScrollFrameScrollBar:SetPoint("TOPLEFT", CommonersQuestLogDetailScrollFrame, "TOPRIGHT", 6, -13);
  CommonersQuestLogDetailScrollFrameScrollBackgroundBottomRight:Hide();
  CommonersQuestLogDetailScrollFrameScrollBackgroundTopLeft:Hide();
end

function CommonersQuest.Log.DetailFrame_DetachFromQuestLog()
  CommonersQuestLogDetailScrollFrame:SetParent(CommonersQuestLogDetailFrame);
  CommonersQuestLogDetailScrollFrame:ClearAllPoints();
  CommonersQuestLogDetailScrollFrame:SetPoint("TOPLEFT", CommonersQuestLogDetailFrame, "TOPLEFT", 19, -76);
  CommonersQuestLogDetailScrollFrame:SetHeight(334);
  CommonersQuestLogDetailScrollFrameScrollBar:SetPoint("TOPLEFT", CommonersQuestLogDetailScrollFrame, "TOPRIGHT", 6, -16);
  CommonersQuestLogDetailScrollFrameScrollBackgroundBottomRight:Show();
  CommonersQuestLogDetailScrollFrameScrollBackgroundTopLeft:Show();
end

function	CommonersQuest.Log.FrameDetail_OnLoad(oFrame)
	CommonersQuest.Log.DetailFrame_DetachFromQuestLog();
end

function	CommonersQuest.Log.FrameDetail_OnShow(oFrame)
end

function	CommonersQuest.Log.FrameDetail_OnHide(oFrame)
end

-- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## --
-- ## ---- ## ---- ## ---- ## -- 3.2 adaptions (end)  ---- ## ---- ## ---- ## --
-- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## --

function	CommonersQuest.Log.TitleButton_OnLoad(self)
end

function	CommonersQuest.Log.TitleButton_OnEvent(self, event, ...)
end

function	CommonersQuest.Log.TitleButton_OnClick(self, button, down)
	local	oRow = CommonersQuest.Log.Rows[self.Index];
	if (oRow) then
		if (oRow.Title) then
			if (oRow.Collapsed) then
				CommonersQuest.Log.State.Expanded[oRow.ExpandAs] = true;
			else
				CommonersQuest.Log.State.Expanded[oRow.ExpandAs] = nil;
			end
		else
			CommonersQuest.Log.State.SelectedID = { RefChar = oRow.RefChar, RefID = oRow.RefID, RefQ = oRow.RefQ, Index = self.Index };
			CommonersQuest.Log.FrameQuest.Init();
		end

		CommonersQuest.Log.FrameMain.Update();
	end
end

function	CommonersQuest.Log.TitleButton_OnEnter(self)
end

function	CommonersQuest.Log.TitleButton_OnLeave(self)
	if (CommonersQuest.Log.State.SelectedID) then
		if (self:GetID() ~= (CommonersQuest.Log.State.SelectedID.Index - HybridScrollFrame_GetOffset(CommonersQuestLogScrollFrame))) then
			self.tag:SetTextColor(self.r, self.g, self.b);
		end
	end
	GameTooltip:Hide();
end

function	CommonersQuest.Log.FrameMain_OnLoad(oFrame)
	tinsert(UISpecialFrames, oFrame:GetName());
	-- it should be so simple... but isn't.
	-- UIPanelWindows["CommonersQuestLogFrame"] = { area = "left", pushable = 0 };
end

function	CommonersQuest.Log.FrameMain_OnShow(oFrame)
	PlaySound("igCustomquestLogOpen");

	-- 3.2
	CommonersQuestLogControlPanel_UpdatePosition();
	CommonersQuest.Log.DetailFrame_AttachToQuestLog();
end

function	CommonersQuest.Log.FrameMain_OnHide(oFrame)
	PlaySound("igCustomquestLogClose");

	-- 3.2
	CommonersQuestLogControlPanel_UpdatePosition();
	CommonersQuest.Log.DetailFrame_DetachFromQuestLog()
end

function	CommonersQuest.Log.AbandonDialog_OnAccept(self)
	local	oData = StaticPopupDialogs["COMMONERSQUEST_ABANDON_QUEST"].customdata;
	local	RefChar, RefID = oData.RefChar, oData.RefID;
	local	oQuest = CQData[RefChar].QuestsCurrent[RefID];
	oQuest.Abandonned = time();

	CommonersQuestTracking.Update();
	CommonersQuest.Log.FrameMain.Update();
end

function	CommonersQuest.Log.AbandonDialog_OnCancel(self)
	CommonersQuest.Log.FrameMain.Update();
end

function	CommonersQuest.Log.AbandonBtnClicked(self)
	self:Disable();

	local	RefChar, RefID = CommonersQuest.Log.State.SelectedID.RefChar, CommonersQuest.Log.State.SelectedID.RefID;
	if (CQData[RefChar] and CQData[RefChar].QuestsCurrent[RefID]) then
		StaticPopupDialogs["COMMONERSQUEST_ABANDON_QUEST"].customdata = { RefChar = RefChar, RefID = RefID };
		StaticPopup_Show("COMMONERSQUEST_ABANDON_QUEST", CQH.QuestToPseudoLink(RefID, nil, RefChar), RefChar);
	end
end

function	CommonersQuest.Log.PushCommonersQuest()
end

function	CommonersQuest.Log.MoneyFrame_OnLoad(oFrame)
	MoneyFrame_SetType(oFrame, "STATIC");
end

function	CommonersQuest.Log.DailyCountButton_OnEnter(self)
--	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
--	GameTooltip:SetText(format(QUEST_LOG_DAILY_TOOLTIP, GetMaxDailyCommonersQuests(), SecondsToTime(GetCommonersQuestResetTime(), nil, 1)));
end

function	CommonersQuest.Log.CollapseAllButton_OnClick(self)
	if (self.collapsed == 1) then
		-- expand all
		local	oRows = CommonersQuest.Log.Rows;
		local	oExpand = CommonersQuest.Log.State.Expanded;
		local	iIndex, oRow;
		for iIndex, oRow in pairs(oRows) do
			if (oRow.Title) then
				CommonersQuest.Log.State.Expanded[oRow.ExpandAs] = true;
			end
		end
	else
		-- collapse all
		CommonersQuest.Log.State.Expanded = {};	-- me lazy...
	end

	CommonersQuest.Log.FrameMain.Update();
end

--
-- custom element: riddle solve button
--

function	CommonersQuest.Log.RiddleSolve(self, arg1)
	if (arg1 == "LeftButton") then
		local	sPlayer = CommonersQuest.Log.State.SelectedID.RefChar;
		local	iQuest = CommonersQuest.Log.State.SelectedID.RefID;
		if (sPlayer and iQuest) then
			local	oQuest = CQH.CharQuestToObj(sPlayer, iQuest);
			local	oContainer = CQData[sPlayer].QuestsCurrent[iQuest];

			if ((oContainer == nil) and CQDataX.Debug and (UnitName("player") == sPlayer)) then
				CQH.CommChat("DbgInfo", "Log", "Log.RiddleSolve: debug/using fake progress container");
				oContainer = { Progress = {} };
			end

			if (oQuest and oContainer) then
				local	iCntTotal, oRiddles, i = #oQuest.Requirements, {};
				for i = 1, iCntTotal do
					local	oReq = oQuest.Requirements[i];
					if (oReq.Type == "Riddle") then
						oRiddles[#oRiddles + 1] = i;
					end
				end

				CQH.InitTable(oContainer, "Progress");
				if (#oRiddles == 1) then
					-- use a static popup frame, let user enter riddle result
					local	iReq = oRiddles[1];
					local	oReq = oQuest.Requirements[iReq];
					local	oData = { Table = oContainer.Progress, Field = iReq, Text = (oContainer.Progress[iReq] or "<answer>") };
					StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
					StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", "answer to " .. oReq.RiddleReference, "additional hint tells you " .. oReq.RiddleShortDesc);
				elseif (#oRiddles > 1) then
					-- show popup to select which riddle
				end
			end
		end
	end
end

--
--
--

local	CommonersQuestDifficultyColorStandard = { r = 0, g = 1, b = 1, font = nil };

function	CommonersQuest.Log.FrameMain.Update()
	if (CommonersQuestDifficultyColorStandard.font == nil) then
		CommonersQuestDifficultyColorStandard.font = CommonersQuestDifficultyStandard;
	end

	CommonersQuest.Log.Rows = {};
	local	oRows = CommonersQuest.Log.Rows;
	local	oCurrent, oPending, oProposed = CommonersQuest.FetchTitles();
	if ((oCurrent == nil) and (oPending == nil) and (oProposed == nil)) then
		CQH.CommChat("ChatImportant", nil, "No quests in the log yet.");
		EmptyCommonersQuestLogFrame:Show();
	else
		EmptyCommonersQuestLogFrame:Hide();
	end

	-- oFoo = { sChar = { { ID, Title }, { ID, Title }, }, sChar = { ...

	local	iCurrentTotal, iProposedTotal = 0, 0;
	if (oCurrent ~= nil) then
		local	sChar, oQuests;
		for sChar, oQuests in pairs(oCurrent) do
			local	sExpandAs = "CURR:" .. sChar;
			if (CommonersQuest.Log.State.Expanded[sExpandAs]) then
				oRows[#oRows + 1] = { Title = true, Collapsed = false, Text = sChar .. ": Current quests", ExpandAs = sExpandAs };
				local	iNum, oQuest;
				for iNum, oQuest in pairs(oQuests) do
					local	sText = oQuest.ID .. ": " .. oQuest.Title;
					oRows[#oRows + 1] = { Title = false, Collapsed = false, RefChar = sChar, RefID = oQuest.ID, RefQ = oQuest, Text = sText, Dirty = oQuest.Dirty, Active = true, Abandonned = oQuest.Abandonned };
				end
			else
				oRows[#oRows + 1] = { Title = true, Collapsed = true, Text = sChar .. ": Current quests (" .. #oQuests .. ")", ExpandAs = sExpandAs };
			end
			iCurrentTotal = iCurrentTotal + #oQuests;
		end
	end

	if (oPending ~= nil) then
		local	sChar, oQuests;
		for sChar, oQuests in pairs(oPending) do
			local	sExpandAs = "PEND:" .. sChar;
			if (CommonersQuest.Log.State.Expanded[sExpandAs]) then
				oRows[#oRows + 1] = { Title = true, Collapsed = false, Text = sChar .. ": Pending quests", ExpandAs = sExpandAs };
				local	iNum, oQuest;
				for iNum, oQuest in pairs(oQuests) do
					local	sText = oQuest.ID .. ": " .. oQuest.Title;
					oRows[#oRows + 1] = { Title = false, Collapsed = false, RefChar = sChar, RefID = oQuest.ID, RefQ = oQuest, Text = sText, Pending = true };
				end
			else
				oRows[#oRows + 1] = { Title = true, Collapsed = true, Text = sChar .. ": Pending quests (" .. #oQuests .. ")", ExpandAs = sExpandAs };
			end
			iProposedTotal = iProposedTotal + #oQuests;
		end
	end

	if (oProposed ~= nil) then
		local	sChar, oQuests;
		for sChar, oQuests in pairs(oProposed) do
			local	sExpandAs = "PROP:" .. sChar;
			if (CommonersQuest.Log.State.Expanded[sExpandAs]) then
				oRows[#oRows + 1] = { Title = true, Collapsed = false, Text = sChar .. ": Available quests", ExpandAs = sExpandAs };
				local	iNum, oQuest;
				for iNum, oQuest in pairs(oQuests) do
					local	sText = oQuest.ID .. ": " .. oQuest.Title;
					oRows[#oRows + 1] = { Title = false, Collapsed = false, RefChar = sChar, RefID = oQuest.ID, RefQ = oQuest, Text = sText, Proposed = false };
				end
			else
				oRows[#oRows + 1] = { Title = true, Collapsed = true, Text = sChar .. ": Available quests (" .. #oQuests .. ")", ExpandAs = sExpandAs };
			end
			iProposedTotal = iProposedTotal + #oQuests;
		end
	end

	local iEntryCnt = #oRows;
	if (CommonersQuest.Log.State.SelectedID ~= nil) then
		local	bFound, i = false;
		for i = 1, iEntryCnt do
			if ((oRows[i].RefChar == CommonersQuest.Log.State.SelectedID.RefChar) and
			    (oRows[i].RefID   == CommonersQuest.Log.State.SelectedID.RefID)) then
				bFound = true;
			end
		end

		if (not bFound) then
			CommonersQuest.Log.State.SelectedID = nil;
		end
	end

	CommonersQuestLogFrame.hasTimer = nil;
	if (CommonersQuest.Log.State.SelectedID == nil) then
		CommonersQuestLogFrameAbandonButton:Disable();
		if (#oRows == 0) then
			CommonersQuestLogNoCommonersQuestsText:Show();
		else
			CommonersQuestLogNoCommonersQuestsText:Hide();
		end

--		CommonersQuestLogDetailFrame:Hide();
		CommonersQuestLogDetailScrollFrame:Hide();
	else
		CommonersQuestLogFrameAbandonButton:Disable();
		local	iCnt, i = #oRows;
		for i = 1, iCnt do
			if ((oRows[i].RefChar == CommonersQuest.Log.State.SelectedID.RefChar) and
			    (oRows[i].RefID   == CommonersQuest.Log.State.SelectedID.RefID)) then
				if (oRows[i].Active and not oRows[i].Abandonned) then
					CommonersQuestLogFrameAbandonButton:Enable();
					break;
				end
			end
		end

--		CommonersQuestLogDetailFrame:Show();
		CommonersQuestLogDetailScrollFrame:Show();
	end

	-- Update commoners' quest count
	CommonersQuestLogCommonersQuestCount:SetFormattedText(QUEST_LOG_COUNT_TEMPLATE, iCurrentTotal, iCurrentTotal + iProposedTotal);

	-- Update the quest listing
	CommonersQuestLogHighlightFrame:Hide();

	local oButtons = CommonersQuestLogScrollFrame.buttons;
	local iButtonCnt = #oButtons;
	local iScrollOffset = HybridScrollFrame_GetOffset(CommonersQuestLogScrollFrame);
	local iButtonHeight = oButtons[1]:GetHeight();

	local	iNumPartyMembers, i = GetNumPartyMembers();
	for i = 1, iButtonCnt, 1 do
		local	questLogTitle = oButtons[i];				-- getglobal("CommonersQuestLogTitle"..i);
		local	questIndex = iScrollOffset + i;
		questLogTitle.Index = questIndex;
		local	questTitleTag = questLogTitle.tag;			-- getglobal("CommonersQuestLogTitle"..i.."Tag");
		local	questNumGroupMates = questLogTitle.groupMates;		-- getglobal("CommonersQuestLogTitle"..i.."GroupMates");
		local	questCheck = questLogTitle.check;			-- getglobal("CommonersQuestLogTitle"..i.."Check");
		local	questNormalText = questLogTitle.normalText;		-- getglobal("CommonersQuestLogTitle"..i.."NormalText");
-- local	questHighlight = getglobal("CommonersQuestLogTitle"..i.."Highlight");
		if (questIndex <= iEntryCnt) then
			local	oRow = oRows[questIndex];
			local	questLogTitleText = oRow.Text;
			local	isHeader = oRow.Title;
			local	isCollapsed = oRow.Collapsed;

			local	level, questTag, suggestedGroup, isComplete, isDaily;
--			local	questLogTitleText, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetCustomquestLogTitle(questIndex);
			if (isHeader) then
				if (questLogTitleText) then
					questLogTitle:SetText(questLogTitleText);
				else
					questLogTitle:SetText("");
				end

				if ( isCollapsed ) then
					questLogTitle:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
				else
					questLogTitle:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
				end
-- questHighlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
				questNumGroupMates:SetText("");
				questTitleTag:Hide();
				questCheck:Hide();
			else
				if ( ENABLE_COLORBLIND_MODE == "1" ) then
					questLogTitleText = "["..level.."] " .. questLogTitleText;
				end
				questLogTitle:SetText("  "..questLogTitleText);

				-- this isn't a header, hide the header textures
				questLogTitle:SetNormalTexture("");
				questLogTitle:SetHighlightTexture("");

				-- If not a header see if any nearby group mates are on this quest
				local	partyMembersOnCustomquest = 0;
				if ( iNumPartyMembers ~= 0 ) then
					for j = 1, iNumPartyMembers do
--[[
-- TODO
						if ( IsUnitOnCustomquest(questIndex, "party"..j) ) then
							partyMembersOnCustomquest = partyMembersOnCustomquest + 1;
						end
]]--
					end
				end

				if ( partyMembersOnCustomquest > 0 ) then
					questNumGroupMates:SetText("["..partyMembersOnCustomquest.."]");
					questNumGroupMates:Show();
				else
					questNumGroupMates:SetText("");
					questNumGroupMates:Hide();
				end

				-- questTag: quest status/daily
				if (oRow.Abandonned) then
					questTag = "Abandonned";
				elseif (oRow.Dirty) then
					questTag = "Broken";
				elseif (isComplete and isComplete < 0 ) then
					questTag = FAILED;
				elseif (isComplete and isComplete > 0 ) then
					questTag = COMPLETE;
				elseif (oRow.Pending) then
					questTag = "Pending";
				elseif (isDaily) then
					if (questTag) then
						questTag = format(DAILY_QUEST_TAG_TEMPLATE, questTag);
					else
						questTag = DAILY;
					end
				end

				if (questTag) then
					questTitleTag:SetText("("..questTag..")");
					questTitleTag:Show();
				else
					questTitleTag:SetText("");
					questTitleTag:Hide();
				end

				-- show the quest check if the quest is being watched
				questCheck:Hide();
				--[[
				if ( IsQuestWatched(questIndex) ) then
					questCheck:Show();
				else
					questCheck:Hide();
				end
				]]--
			end

			-- resize the title button so everything fits where it's supposed to
			QuestLogTitleButton_Resize(questLogTitle);

			-- Color the quest title and highlight according to the difficulty level
			if (isHeader) then
				color = QuestDifficultyColor["header"];
			else
				if (oRow.Dirty or oRow.Abandonned) then
					color = QuestDifficultyColor["impossible"];		-- red
				elseif (oRow.Pending) then
					color = QuestDifficultyColor["verydifficult"];		-- orange
				else
					color = CommonersQuestDifficultyColorStandard;		-- turqoise
				end
			end
			questTitleTag:SetTextColor(color.r, color.g, color.b);
			questLogTitle:SetNormalFontObject(color.font);
			questNumGroupMates:SetTextColor(color.r, color.g, color.b);
			questLogTitle.r = color.r;
			questLogTitle.g = color.g;
			questLogTitle.b = color.b;
			questLogTitle:Show();

			-- Place the highlight and lock the highlight state
			local	bLockHighlight = false;
			if (not isHeader) then
				local	oSelectedID = CommonersQuest.Log.State.SelectedID;
				if (oSelectedID) then
					if ((oSelectedID.RefChar == oRow.RefChar) and (oSelectedID.RefID == oRow.RefID)) then
						_QuestLog_HighlightQuest(questLogTitle);
						bLockHighlight = true;
					end
				end
			end

			if (not bLockHighlight) then
				questLogTitle:UnlockHighlight();
			end
		else
			questLogTitle.isHeader = nil;
			questLogTitle:Hide();
		end
	end

	-- ScrollFrame update: (3.2.x => moved update down and CommonersQuestLogListScrollFrame -> CommonersQuestLogScrollFrame, FauxScrollFrame -> HybridScrollFrame)
	-- FauxScrollFrame_Update(CommonersQuestLogListScrollFrame, #oRows, QUESTS_DISPLAYED, QUESTLOG_QUEST_HEIGHT, nil, nil, nil, CommonersQuestLogHighlightFrame, 293, 316);
	HybridScrollFrame_Update(CommonersQuestLogScrollFrame, #oRows * iButtonHeight, iButtonCnt * iButtonHeight);

	-- Set the expand/collapse all button texture
	local iHeaderCnt, iCollapsedCnt, i = 0, 0;
	-- Somewhat redundant loop, but cleaner than the alternatives
	for i = 1, iEntryCnt, 1 do
		if (oRows[i] and oRows[i].Title) then
			iHeaderCnt = iHeaderCnt + 1;
			if ( oRows[i].Collapsed ) then
				iCollapsedCnt = iCollapsedCnt + 1;
			end
		end
	end

--[[
	-- If all headers are not expanded then show collapse button, otherwise show the expand button
	if ( iHeaderCnt ~= iCollapsedCnt ) then
		CommonersQuestLogCollapseAllButton.collapsed = nil;
		CommonersQuestLogCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
	else
		CommonersQuestLogCollapseAllButton.collapsed = 1;
		CommonersQuestLogCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
	end
]]--

	-- Determine whether the selected quest is pushable or not
	if (iEntryCnt == 0) then
		CommonersQuestFramePushCommonersQuestButton:Disable();
--[[
	-- TODO
	elseif ( GetCustomquestLogPushable() and ( GetNumPartyMembers() > 0 or GetNumRaidMembers() > 1 ) ) then
		CommonersQuestFramePushCommonersQuestButton:Enable();
]]--
	else
		CommonersQuestFramePushCommonersQuestButton:Disable();
	end

	return true;
end

--Used to attach an empty spacer frame to the last shown object
function CommonersQuest.Log.FrameQuest.SetAsLastShown(frame, spacerFrame)
	if (not spacerFrame) then
		spacerFrame = CommonersQuestLogSpacerFrame;
	end
	spacerFrame:SetPoint("TOP", frame, "BOTTOM", 0, 0);
end

function	CommonersQuest.Log.FrameQuest.Init(doNotScroll)
	local	oSelectedID = CommonersQuest.Log.State.SelectedID;
	if (oSelectedID == nil) then
		CQH.CommChat("DbgImportant", "Quest", "Call to QuestInit without valid selection.");
	else
		local	bFail = false;

		local	oQuestData = CQH.CharQuestToObj(oSelectedID.RefChar, oSelectedID.RefID);
		local	oQuestState = CommonersQuestKrbrPrdmrDataPerChar[oSelectedID.RefChar].QuestsCurrent[oSelectedID.RefID];
		local	oQuestFailed, oQuestProgress, oQuestCompleted;
		if (oQuestState) then
			oQuestFailed = oQuestState.Failed;
			if (oQuestFailed == nil) then
				oQuestFailed = {};
			end
			oQuestProgress = oQuestState.Progress;
			if (oQuestProgress == nil) then
				oQuestProgress = {};
			end
			oQuestCompleted = oQuestState.Completed;
			if (oQuestCompleted == nil) then
				oQuestCompleted = {};
			end
		else
			-- not a current quest: empty progress set
			oQuestFailed = {};
			oQuestProgress = {};
			oQuestCompleted = {};
		end

		if ((oQuestData == nil) or (oQuestCompleted == nil)) then
			bFail = true;
			local	sWhat = "";
			if (oQuestCompleted == nil) then
				sWhat = sWhat .. " progress";
			end
			if (oQuestData == nil) then
				sWhat = sWhat .. " data";
			end

			CQH.CommChat("DbgImportant", "Quest", "Call to QuestInit failed: missing object(s)" .. sWhat);
		else
			local	questID = oSelectedID.RefID;
			local	questTitle = oQuestData.Title;
			if (oQuestData.State and oQuestData.State.Encrypted) then
				questTitle = oQuestData.ID .. " (encrypted)";
			end
			if (not questTitle) then
				questTitle = "";
			end
--[[
			if ( IsCurrentCustomquestFailed() ) then
				questTitle = questTitle.." - ("..FAILED..")";
			end
]]--
			CommonersQuestLogCommonersQuestTitle:SetText(questTitle);

--			local	questDescription, questObjectives = GetCustomquestLogCustomquestText();
			local	questDescription, questObjectives = oQuestData.DescAcqIntro, oQuestData.DescLogSmall;
			if (oQuestData.State and oQuestData.State.Encrypted) then
				local	sDescOut, sDescIn = "", oQuestData.DescAcqIntro;
				while (sDescIn ~= "") do
					sDescOut = sDescOut .. " " .. strsub(sDescIn, 1, 8);
					sDescIn  = strsub(sDescIn, 9);
				end
				questDescription = strsub(sDescOut, 2);

				local	sDescOut, sDescIn = "", oQuestData.DescLogSmall;
				while (sDescIn ~= "") do
					sDescOut = sDescOut .. " " .. strsub(sDescIn, 1, 8);
					sDescIn  = strsub(sDescIn, 9);
				end
				questObjectives = strsub(sDescOut, 2);
			end

			CommonersQuestLogObjectivesText:SetText(questObjectives);

			local questTimer;		-- = GetCustomquestLogTimeLeft();
			if ( questTimer ) then
				CommonersQuestLogFrame.hasTimer = 1;
				CommonersQuestLogFrame.timePassed = 0;
				CommonersQuestLogTimerText:Show();
				CommonersQuestLogTimerText:SetText(TIME_REMAINING.." "..SecondsToTime(questTimer));
				CommonersQuestLogObjective1:SetPoint("TOPLEFT", "CommonersQuestLogTimerText", "BOTTOMLEFT", 0, -10);
			else
				CommonersQuestLogFrame.hasTimer = nil;
				CommonersQuestLogTimerText:Hide();
				CommonersQuestLogObjective1:SetPoint("TOPLEFT", "CommonersQuestLogObjectivesText", "BOTTOMLEFT", 0, -10);
			end

			-- Show Customquest Watch if track quest is checked
--			local numObjectives = GetNumCustomquestLeaderBoards();
			local	oReqs, bHasRiddle = oQuestData.Requirements, false;
			local	iNumObjectives, iNonItem, iItem, i = #oReqs, 0, 0;
			for i= 1, iNumObjectives, 1 do
				local	oLine = getglobal("CommonersQuestLogObjective" .. i);
--				local	text, type, finished = GetCustomquestLogLeaderBoard(i);
				local	oReq, iProgress = oReqs[i], oQuestProgress[i];
				if (oReq.Type == "Loot") then
					iProgress = CQH.CountItemInBags(oReq.ItemID);
				end
				local	text, sType, finished, iscount = CQH.RequirementToText(oReq, iProgress, oQuestFailed[i], (oQuestCompleted[i] ~= nil));
				if (not text or strlen(text) == 0) then
					text = "??" .. sType;
				end
				if (finished) then
					oLine:SetTextColor(0.2, 0.2, 0.2);
					if (oReq.Type ~= "Loot") then
						text = text .. " (" .. COMPLETE .. ")";
					end
				else
					oLine:SetTextColor(0, 0, 0);
				end
				if (oReq.Type == "Loot") then
					text = text .. ": " .. math.min((iscount or 0), (oReq.Count or 1)) .. "/" .. (oReq.Count or 1);
				end
				oLine:SetText(text);
				oLine:Show();
				CommonersQuest.Log.FrameQuest.SetAsLastShown(oLine);

				if (oReq.Type == "Riddle") then
					bHasRiddle = true;
				end
			end

			for i= (iNumObjectives + 1), MAX_OBJECTIVES, 1 do
				getglobal("CommonersQuestLogObjective" .. i):Hide();
			end

--[[
			-- If there's money required then anchor and display it
			if ( GetCustomquestLogRequiredMoney() > 0 ) then
				if ( numObjectives > 0 ) then
					CustomquestLogRequiredMoneyText:SetPoint("TOPLEFT", "CustomquestLogObjective"..numObjectives, "BOTTOMLEFT", 0, -4);
				else
					CustomquestLogRequiredMoneyText:SetPoint("TOPLEFT", "CustomquestLogObjectivesText", "BOTTOMLEFT", 0, -10);
				end

				MoneyFrame_Update("CustomquestLogRequiredMoneyFrame", GetCustomquestLogRequiredMoney());

				if ( GetCustomquestLogRequiredMoney() > GetMoney() ) then
					-- Not enough money
					CustomquestLogRequiredMoneyText:SetTextColor(0, 0, 0);
					SetMoneyFrameColor("CustomquestLogRequiredMoneyFrame", "red");
				else
					CustomquestLogRequiredMoneyText:SetTextColor(0.2, 0.2, 0.2);
					SetMoneyFrameColor("CustomquestLogRequiredMoneyFrame", "white");
				end
				CustomquestLogRequiredMoneyText:Show();
				CustomquestLogRequiredMoneyFrame:Show();
			else
]]--
				CommonersQuestLogRequiredMoneyText:Hide();
				CommonersQuestLogRequiredMoneyFrame:Hide();
--			end

--[[
			if ( GetCustomquestLogGroupNum() > 0 ) then
				local suggestedGroupString = format(QUEST_SUGGESTED_GROUP_NUM, GetCustomquestLogGroupNum());
				CustomquestLogSuggestedGroupNum:SetText(suggestedGroupString);
				CustomquestLogSuggestedGroupNum:Show();
				CustomquestLogSuggestedGroupNum:ClearAllPoints();
				if ( GetCustomquestLogRequiredMoney() > 0 ) then
					CustomquestLogSuggestedGroupNum:SetPoint("TOPLEFT", "CustomquestLogRequiredMoneyText", "BOTTOMLEFT", 0, -4);
				elseif ( numObjectives > 0 ) then
					CustomquestLogSuggestedGroupNum:SetPoint("TOPLEFT", "CustomquestLogObjective"..numObjectives, "BOTTOMLEFT", 0, -4);
				elseif ( questTimer ) then
					CustomquestLogSuggestedGroupNum:SetPoint("TOPLEFT", "CustomquestLogTimerText", "BOTTOMLEFT", 0, -10);
				else
					CustomquestLogSuggestedGroupNum:SetPoint("TOPLEFT", "CustomquestLogObjectivesText", "BOTTOMLEFT", 0, -10);
				end
			else
]]--
				CommonersQuestLogSuggestedGroupNum:Hide();
--			end

			local	sDescTitleAnchor;
--			if ( GetCustomquestLogGroupNum() > 0 ) then
--				sDescTitleAnchor = "CustomquestLogSuggestedGroupNum";
--			elseif ( GetCustomquestLogRequiredMoney() > 0 ) then
--				sDescTitleAnchor = "CustomquestLogRequiredMoneyText";
--			elseif ( numObjectives > 0 ) then
			if (iNumObjectives > 0) then
				sDescTitleAnchor = "CommonersQuestLogObjective" .. iNumObjectives;
			else
				if (questTimer) then
					sDescTitleAnchor = "CommonersQuestLogTimerText";
				else
					sDescTitleAnchor = "CommonersQuestLogObjectivesText";
				end
			end

			if (bHasRiddle) then
				CommonersQuestLogRiddle:SetPoint("TOPLEFT", sDescTitleAnchor, "BOTTOMLEFT", 0, -5);
				CommonersQuestLogRiddle:Show();
				CommonersQuest.Log.FrameQuest.SetAsLastShown(CommonersQuestLogRiddle);

				sDescTitleAnchor = "CommonersQuestLogRiddle";

				local	oRows = CommonersQuest.Log.Rows;
				local	bEnable, jCnt, j = false, #oRows;
				for j = 1, jCnt do
					if ((oRows[j].RefChar == CommonersQuest.Log.State.SelectedID.RefChar) and
					    (oRows[j].RefID   == CommonersQuest.Log.State.SelectedID.RefID)) then
						if (oRows[j].Active and not oRows[j].Abandonned) then
							bEnable = true;
						end
					end
				end

				if (bEnable) then
					CommonersQuestLogRiddle:Enable();
				else
					CommonersQuestLogRiddle:Disable();
				end
			else
				CommonersQuestLogRiddle:Hide();
			end

			CommonersQuestLogDescriptionTitle:SetPoint("TOPLEFT", sDescTitleAnchor, "BOTTOMLEFT", 0, -10);

			if (questDescription) then
				CommonersQuestLogCommonersQuestDescription:SetText(questDescription);
				CommonersQuest.Log.FrameQuest.SetAsLastShown(CommonersQuestLogCommonersQuestDescription);
			end

			local	iQuestID = oSelectedID.RefID;
			local	oRewards;
			if (CommonersQuestKrbrPrdmrDataPerChar[oSelectedID.RefChar]) then
				local	oTemp = CommonersQuestKrbrPrdmrDataPerChar[oSelectedID.RefChar];
				if  (oTemp.RewardsPromised and oTemp.RewardsPromised[oSelectedID.RefID]) then
					oRewards = oTemp.RewardsPromised[oSelectedID.RefID].Data;
				end
			end
			if (oRewards == nil) then
				bFail = bFail or (oQuestState ~= nil);
				if (not bFail) then
					oRewards = {};
				else
					CQH.CommChat("DbgImportant", "Quest", "Missing rewards...");
				end
			end

			if (not bFail) then
				local	sBindingItem;
				if (CommonersQuestKrbrPrdmrDataPerChar[oSelectedID.RefChar]) then
					local	oTemp = CommonersQuestKrbrPrdmrDataPerChar[oSelectedID.RefChar];
					if (oTemp.QuestsCurrent and oTemp.QuestsCurrent[oSelectedID.RefID]) then
						local	oTempSub = oTemp.QuestsCurrent[oSelectedID.RefID];
						sBindingItem = oTempSub.BindingItem;
					end
				end
				local	oFrameLowest = CQH.SetupRewards("CommonersQuestLog", {}, oRewards, sBindingItem, oQuestData.State.NoBindingItem);
				if (oFrameLowest) then
					CommonersQuest.Log.FrameQuest.SetAsLastShown(oFrameLowest);
				end
			end
--			CommonersQuestFrameItems_Update("CommonersQuestLog");

			if (not doNotScroll) then
				CommonersQuestLogDetailScrollFrameScrollBar:SetValue(0);
			end
		end

		if (not bFail) then
			CQH.CommChat("DbgInfo", "Quest", "Call to QuestInit successful.");

			CommonersQuestLogDetailScrollFrame:Show();
		else
			CQH.CommChat("DbgImportant", "Quest", "Call to QuestInit failed.");

			CommonersQuestLogDetailScrollFrame:Hide();
			CommonersQuestLogFrame:Hide();
		end

		CommonersQuestLogControlPanel_UpdatePosition();
	end
end

function	CommonersQuest.Log.Init()
	if (CommonersQuest.Log.FrameMain.Update()) then
		CommonersQuestLogFrame:Show();
		CommonersQuestLogScrollFrame:Show();
		if (CommonersQuest.Log.State.SelectedID) then
			CommonersQuest.Log.FrameQuest.Init();
		end
	else
		CommonersQuestLogFrame:Hide();
		CommonersQuestLogScrollFrame:Hide();
	end
end

-- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## --
-- ## ---- ## ---- ## ---- ## -- 3.2 additions (start) --- ## ---- ## ---- ## --
-- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## ---- ## --

--
-- Hide/Show/Re-Anchor (uselessly complicated new quest frame model by Blizzard)
--

-- TODO.

--
-- QuestLogControlPanel
--

function CommonersQuestLogControlPanel_UpdatePosition()
  local parent;
  if ( CommonersQuestLogFrame:IsShown() ) then
    parent = CommonersQuestLogFrame;
    CommonersQuestLogControlPanel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 18, 11);
    CommonersQuestLogControlPanel:SetWidth(307);
  elseif ( CommonersQuestLogDetailFrame:IsShown() ) then
    parent = CommonersQuestLogDetailFrame;
    CommonersQuestLogControlPanel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 18, 5);
    CommonersQuestLogControlPanel:SetWidth(327);
  end
  if ( parent ) then
    CommonersQuestLogControlPanel:SetParent(parent);
    CommonersQuestLogControlPanel:Show();
  else
    CommonersQuestLogControlPanel:Hide();
  end
end

function CommonersQuestLogControlPanel_UpdateState()
--[[
  local questLogSelection = GetQuestLogSelection();

  if ( questLogSelection == 0 ) then
    QuestLogFrameAbandonButton:Disable();
    QuestLogFrameTrackButton:Disable();
    QuestLogFramePushQuestButton:Disable();
  else
    if ( GetAbandonQuestName() ) then
      QuestLogFrameAbandonButton:Enable();
    else
      QuestLogFrameAbandonButton:Disable();
    end

    QuestLogFrameTrackButton:Enable();

    if ( GetQuestLogPushable() and ( GetNumPartyMembers() > 0 or GetNumRaidMembers() > 1 ) ) then
      QuestLogFramePushQuestButton:Enable();
    else
      QuestLogFramePushQuestButton:Disable();
    end
  end
]]--
end

function CommonersQuestLogShowMapPOI_UpdatePosition()
end

