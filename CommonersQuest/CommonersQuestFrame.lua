
MAX_NUM_COMMONERSQUESTS = 20;

local	CQData = nil;
local	CQDataX = nil;
local	CQDataGlobal = nil;
local	CQH = CommonersQuest.Helpers;

function	CommonersQuest.Initializers.QPanels(CQDataMain, CQDataXMain, CQDataGlobalMain)
	CQData = CQDataMain;
	CQDataX = CQDataXMain;
	CQDataGlobal = CQDataGlobalMain;
end

local	function	FrameShow()
	if (not CommonersQuestFrame:IsShown()) then
		CQH.CommChat("DbgInfo", "Quest", "Showing main quest dialog frame...");
		ShowUIPanel(CommonersQuestFrame);
	end
end

local	function	FrameHide()
	if (CommonersQuestFrame:IsShown()) then
		CQH.CommChat("DbgInfo", "Quest", "Hiding main quest dialog frame...");
		HideUIPanel(CommonersQuestFrame);
	end
end

CommonersQuest.FrameMain.Show = FrameShow;
CommonersQuest.FrameMain.Hide = FrameHide;

function	CommonersQuest.FrameMain.OnLoad(oFrame)
	-- tinsert(UISpecialFrames, oFrame:GetName());

	oFrame:SetAttribute("UIPanelLayout-defined", true)
	oFrame:SetAttribute("UIPanelLayout-enabled", true)
	oFrame:SetAttribute("UIPanelLayout-area", "left")
	oFrame:SetAttribute("UIPanelLayout-pushable", 5)
	oFrame:SetAttribute("UIPanelLayout-width", 384)
end

function	CommonersQuest.FrameMain.OnEvent(oFrame, sEvent, ...)
end

function	CommonersQuest.FrameMain.OnShow(oFrame)
	CommonersQuestFramePortrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
	if ((CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.Player == nil)) then
		local	iID = CommonersQuestFrame:GetID();
		if ((iID == nil) or (iID < 1000)) then
			CQH.CommChat("DbgInfo", "Quest", "FM::OS: Quest " .. (iID or "<nil>") .. " not found[1].");
			FrameHide();
			return
		end

		local	oQuests;
		if (iID < 1000000) then
			oQuests = CommonersQuest.QuestDB;
		else
			oQuests = CommonersQuestKrbrPrdmrOther.CustomQuests;
		end

		if (oQuests == nil) then
			CQH.CommChat("DbgInfo", "Quest", "FM::OS: Quest " .. iID .. " not found[2].");
			FrameHide();
			return
		end

		local	oQuest, k, v;
		for k, v in pairs(oQuests) do
			if (v.ID == iID) then
				oQuest = v;
				break;
			end
		end

		if (oQuest == nil) then
			CQH.CommChat("DbgInfo", "Quest", "FM::OS: Quest " .. iID .. " not found[3].");
			FrameHide();
			return
		end

		if (CommonersQuestFrame.RewardSet ~= nil) then
			local	oRewardSet = CQDataGlobal.Rewards[iID][CommonersQuestFrame.RewardSet];
			if (oRewardSet == nil) then
				CQH.CommChat("DbgInfo", "Quest", "FM::OS: Quest " .. iID .. ", reward set " .. CommonersQuestFrame.RewardSet .. " does not exist?");
				FrameHide();
			elseif (oRewardSet.Locked == true) then
				CQH.CommChat("DbgInfo", "Quest", "FM::OS: Quest " .. iID .. ", reward set " .. CommonersQuestFrame.RewardSet .. " is *locked*.");
				FrameHide();
			else
				CommonersQuestFrameNpcNameText:SetText("<REWARDSET: " .. CommonersQuestFrame.RewardSet .. ">");
			end
		else
			local	oStateGlobal = CQH.InitStateGiver(oQuest);
			if (oStateGlobal.Locked == true) then
				CQH.CommChat("DbgInfo", "Quest", "FM::OS: Quest " .. iID .. " is *locked*... only (re-)viewing.");
				CommonersQuestFrame.ViewMode = true;
				CommonersQuestFrameNpcNameText:SetText("<VIEWMODE: Quest " .. iID .. ">");
			else
				CommonersQuestFrameNpcNameText:SetText("<EDITMODE: Quest " .. iID .. ">");
				oStateGlobal.Modified = time();	
			end
			CommonersQuestFrameNpcNameText:SetTextColor(0, 1, 1);
		end
	elseif (CommonersQuestFrame.Player) then
		CommonersQuestFrameNpcNameText:SetText("Commoner " .. CommonersQuestFrame.Player);
	else
		CommonersQuestFrameNpcNameText:SetText("ERROR");
		CQH.CommChat("DbgInfo", "Quest", "FM::OS: Invalid mode for quest frame. Callstack => " .. debugstack());
		FrameHide();
	end
end

function	CommonersQuest.FrameMain.OnHide(oFrame)
	CommonersQuestFrame.Player = nil;
	CommonersQuestFrame.EditMode = false;
	CommonersQuestFrame.ViewMode = false;
	CommonersQuestFrame.RewardSet = nil;
end

function	CommonersQuest.FrameRewardPanel.OnShow(oFrame)
	if ((CommonersQuestFrame.Player == nil) and (CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.ViewMode ~= true)) then
		CommonersQuestRewardText_EditBtn:Show();
	else
		CommonersQuestRewardText_EditBtn:Hide();
	end
end

function	CommonersQuest.FrameRewardPanel.RewardItemRaiseFrameLevel(oFrame)
end

function	CommonersQuest.FrameRewardPanel.RewardCancelButtonClicked(oButton, sMousebutton)
	FrameHide();
end

function	CommonersQuest.FrameRewardPanel.RewardCompleteButtonClicked(oButton, sMousebutton)
	if ((CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.Player == nil)) then
		if (CommonersQuestFrame.ViewMode ~= true) then
			-- TODO: check against pattern quest to have all texts changed
			CommonersQuest.ValidateQuest(CommonersQuestFrame:GetID(), true, "");
		end

		FrameHide();
	else
		local	sPlayer = CommonersQuestFrame.Player;
		local	iQuest = CommonersQuestFrame:GetID();
		local	oContainer = CQData[sPlayer].QuestsCurrent[iQuest];
		oContainer.ChosenReward = oContainer.ChosenRewardCandidate;
		oContainer.CompletedAll = time();

		if (oContainer.ChosenReward) then
			local	_, sLink = GetItemInfo(oContainer.ChosenReward);
			CQH.CommChat("ChatInfo", "Quest", "Quest completed, selected reward chosen is " .. sLink .. ".");
		else
			CQH.CommChat("ChatInfo", "Quest", "Quest completed.");
		end

		FrameHide();

		if (not CommonersQuest.Trade.CanTrade()) then
			CQH.CommChat("ChatImportant", "Quest", "You already have a trade in progress, not requesting one from " .. sPlayer .. " at the same time...");
		end

		if (CQH.FindItemInBags(oContainer.BindingItem)) then
			CQData[sPlayer].TradeTakerReady = { QuestID = iQuest, Item = oContainer.BindingItem, At = time(), Action = "Reward", Reward = oContainer.ChosenReward };

			local	sReward = 0;
			if (oContainer.ChosenReward) then
				sReward = oContainer.ChosenReward;
			end
			local	sMsg = "?TradeReady:Reward:" .. iQuest .. ":" .. sReward .. ":" .. oContainer.BindingItem;
			CommonersQuest.QueueAddonMessage("COMMONERSQUEST", sMsg, "WHISPER", sPlayer);
		else
			local	_, sLink = GetItemInfo(oContainer.BindingItem);
			CQH.CommChat("ChatImportant", "Quest", "\"Binding item\" " .. sLink .. " not found in your bags! Can't initiate exchange of reward.");
		end
	end
end

function	CommonersQuest.FrameRewardPanel.MoneyFrame_OnLoad(oFrame)
	MoneyFrame_SetType(oFrame, "STATIC");
end

function	CommonersQuest.FrameProgressPanel.OnShow(oFrame)
	if ((CommonersQuestFrame.Player == nil) and (CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.ViewMode ~= true)) then
		CommonersQuestProgressText_EditBtn:Show();
		CommonersQuestProgressRequiredItemsText_MenuBtn:Show();
	else
		CommonersQuestProgressText_EditBtn:Hide();
		CommonersQuestProgressRequiredItemsText_MenuBtn:Hide();
	end
end

function	CommonersQuest.FrameProgressPanel.GoodbyeButtonClicked(oButton, sMousebutton)
	FrameHide();
end

function	CommonersQuest.FrameProgressPanel.ProgressCompleteButtonClicked(oButton, sMousebutton)
	if (sMousebutton == "LeftButton") then
		local	sPlayer = CommonersQuestFrame.Player;
		local	iQuest = CommonersQuestFrame:GetID();
		if (sPlayer and iQuest and (CommonersQuestFrame.EditMode ~= true)) then
			-- if we got a riddle, we do not open the reward panel, but query the giver
			local	oQuest = CQH.CharQuestToObj(sPlayer, iQuest);
			local	oContainer = CQData[sPlayer].QuestsCurrent[iQuest];
			if (oQuest and oContainer) then
				CQH.InitTable(oContainer, "Completed");

				local	sAnswers = "";
				local	iCntTotal, oRiddles, i = #oQuest.Requirements, {};
				for i = 1, iCntTotal do
					local	oReq = oQuest.Requirements[i];
					if ((oReq.Type == "Riddle") and (oContainer.Completed[i] ~= true)) then
						sAnswers = sAnswers .. ":" .. i .. ":" .. (oContainer.Progress[i] or "");
					end
				end

				if (sAnswers ~= "") then
					CQH.CommChat("ChatImportant", nil, "Quest contains (a) riddle(s). Asking quest giver to validate or reject your solution(s)... Please wait.");
					CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?ProgressRiddles:" .. iQuest .. sAnswers, "WHISPER", sPlayer);
					return
				end
			end
		end

		CommonersQuest.FrameRewardPanel.Init(iQuest);
	end
end

function	CommonersQuest.FrameDetailPanel.OnShow(oFrame)
	local	bEditMode = (CommonersQuestFrame.Player == nil) and (CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.ViewMode ~= true);
	if (bEditMode and (CommonersQuestFrame.RewardSet == nil)) then
		CommonersQuestDetailTitleText_EditBtn:Show();
		CommonersQuestDetailDescription_EditBtn:Show();
		CommonersQuestDetailObjectiveText_EditBtn:Show();
	else
		CommonersQuestDetailTitleText_EditBtn:Hide();
		CommonersQuestDetailDescription_EditBtn:Hide();
		CommonersQuestDetailObjectiveText_EditBtn:Hide();
	end

	if (bEditMode and (CommonersQuestFrame.RewardSet ~= nil)) then
		CommonersQuestDetailRewardTitleText_MenuBtn:Show();
	else
		CommonersQuestDetailRewardTitleText_MenuBtn:Hide();
	end
end

function	CommonersQuest.FrameDetailPanel.OnUpdate(oFrame, iElapsed)
end

function	CommonersQuest.FrameDetailPanel.DetailDeclineButtonClicked(oButton, sMousebutton)
	if (CommonersQuestFrame.Player ~= nil) then
		local	sPlayer = CommonersQuestFrame.Player;
		local	iQuest  = CommonersQuestFrame:GetID();
		if (CQData[sPlayer]) then
			if (CQData[sPlayer].QuestsCurrent[iQuest] == nil) then
				CQData[sPlayer].QuestsAcknowledgedToTake[iQuest] = nil;
			end
		end

		CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Decline:" .. iQuest, "WHISPER", sPlayer);
	end

	FrameHide();
end

function	CommonersQuest.FrameDetailPanel.DetailAcceptButtonClicked(oButton, sMousebutton)
	if (sMousebutton == "LeftButton") then
		local	iQuestID = CommonersQuestFrame:GetID();
		if ((CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.Player == nil)) then
			if (CommonersQuestFrame.RewardSet) then
				FrameHide();

				-- TODO: check against pattern quest to have all texts changed
				CommonersQuest.ValidateQuest(iQuestID, true, CommonersQuestFrame.RewardSet);
			else
				CommonersQuest.FrameProgressPanel.Init(iQuestID);
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("Available ID " .. iQuestID .. " from player " .. CommonersQuestFrame.Player .. ": Requesting...");
			CommonersQuest.QuestRequested(CommonersQuestFrame.Player, iQuestID);
			CommonersQuestFrameDetailPanel:Hide();
			FrameHide();
		end
	end
end

function	CommonersQuest.FrameMoney.OnLoad(oFrame)
	MoneyFrame_SetType(oFrame, "STATIC");
end

function	CommonersQuest.FrameGreetingPanel.OnShow(oFrame)
end

--
-- custom element: riddle solve button
--

function	CommonersQuest.FrameProgressPanel.RiddleSolve(self, arg1)
	if (arg1 == "LeftButton") then
		local	sPlayer = CommonersQuestFrame.Player;
		local	iQuest = CommonersQuestFrame:GetID();
		local	oQuest, oContainer;
		if (iQuest and sPlayer and (CommonersQuestFrame.EditMode ~= true)) then
			oQuest = CQH.CharQuestToObj(sPlayer, iQuest);
			oContainer = CQData[sPlayer].QuestsCurrent[iQuest];
		end

		-- edit mode/view mode: clickable to show the riddle shortdesc
		if ((sPlayer == nil) and (CommonersQuestFrame.EditMode == true)) then
			CQH.CommChat("DbgInfo", "Frames", "FrameProgressPanel.RiddleSolve: edit/view mode, using fake progress container");
			oQuest = CQH.CharQuestToObj(nil, iQuest);
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

--
--
--

function	CommonersQuest.Menu.FindItemByName(self)
	-- use a static popup frame, let user enter name, on OK search and add as requirement
	CloseDropDownMenus();
	local	iID = CommonersQuest.Menu.QuestID;
	StaticPopupDialogs["COMMONERSQUEST_SEARCH_REQUIREMENTTARGET"].ID = iID;
	StaticPopupDialogs["COMMONERSQUEST_SEARCH_REQUIREMENTTARGET"].Type = "Item";
	StaticPopup_Show("COMMONERSQUEST_SEARCH_REQUIREMENTTARGET");
end

function	CommonersQuest.Menu.UpdateCurrentFrame()
	if (CommonersQuestFrame:IsShown()) then
		-- GreetingPanel: not possible
		local	iQuestID = CommonersQuestFrame:GetID();
		if (CommonersQuestFrameRewardPanel:IsShown()) then
			CommonersQuest.FrameRewardPanel.Init(iQuestID);
		elseif (CommonersQuestFrameProgressPanel:IsShown()) then
			CommonersQuest.FrameProgressPanel.Init(iQuestID);
		elseif (CommonersQuestFrameDetailPanel:IsShown()) then
			CommonersQuest.FrameDetailPanel.Init(iQuestID);
		end
	end

	if (CommonersQuestMainframe:IsShown()) then
		CommonersQuestMainframe:Hide();
		CommonersQuestMainframe:Show();
	end
end

--[[
CommonersQuest.Menu.StackSplitCallback = {};

function	CommonersQuest.Menu.StackSplitCallback.SplitStack(self, iSplit)
	local	oData = CommonersQuest.Menu.StackSplitCallback.oData;
	oData.Count = iSplit;
	CQH.CommChat("ChatInfo", nil, "Amount set to " .. oData.Count .. ".");

	self.SplitStack = nil;
	CommonersQuest.Menu.UpdateCurrentFrame();
end
]]--

CommonersQuest.Menu.ItemCount = {};

function	CommonersQuest.Menu.ItemCount.Slider(iCount, oData)
	oData.oReq.Count = iCount;
	CommonersQuest.Menu.UpdateCurrentFrame();
end


function	CommonersQuest.Menu.ClickedItem(self, arg1, arg2)
	CommonersQuest.Menu.ClickedItemDo(self, arg1, arg2);
	CommonersQuest.Main.Refresh(CommonersQuestMainframe);
end

function	CommonersQuest.Menu.ClickedItemDo(self, arg1)
	if (CommonersQuest.Menu.GroupObj and CommonersQuest.Menu.Button) then
		local	oItem = {};
		oItem.ItemID = string.match(arg1, "item:(%d+)");
		if (oItem.ItemID) then
			oItem.ItemID = tonumber(oItem.ItemID);
		end
		oItem.ItemName = string.match(arg1, "%[(.+)%]");
		if (CommonersQuest.Menu.GroupField == "Reward") then
			oItem.Type = "Item";
			oItem.Count = 1;
			oItem.Permanent = false;
			if (CommonersQuest.Menu.Button == "LeftButton") then
				oItem.Choice = false;
			elseif (CommonersQuest.Menu.Button == "MiddleButton") then
				oItem.Choice = true;
			end
		elseif (CommonersQuest.Menu.GroupField == "Requirements") then
			oItem.Type = "Loot";
		end

		if (oItem.ItemID and oItem.ItemName and oItem.Type) then
			local	oGrp = CommonersQuest.Menu.GroupObj;
			if ((CommonersQuest.Menu.Button == "LeftButton") or (CommonersQuest.Menu.Button == "MiddleButton")) then
				-- check if stackable, then add to stack
				local	iCnt, i = #oGrp;
				if (iCnt > 0) then
					for i = 1, iCnt do
						local	oItemRef = oGrp[i];
						if ((oItemRef.Type == oItem.Type) and (oItemRef.ItemID == oItem.ItemID)) then
							if (oItemRef.Choice == oItem.Choice) then
								if (oItemRef.Count == nil) then
									oItemRef.Count = 1;
								end
								local	_1, sLink, _3, _4, _5, _6, _7, iStackable = GetItemInfo(oItemRef.ItemID);
								if (iStackable > oItemRef.Count) then
									--[[
									CommonersQuest.Menu.StackSplitCallback.oData = oItemRef;
									self.SplitStack = CommonersQuest.Menu.StackSplitCallback.SplitStack;
									OpenStackSplitFrame(iStackable, self, "BOTTOMLEFT", "TOPLEFT");
									]]--

									local	x, y = self:GetRight(), self:GetBottom();

									local	sText2, sText1 = CQH.QuestToPseudoLink(CommonersQuest.Menu.QuestID);
									local	oData = { oReq = oItemRef };
									sText1 = CommonersQuest.Menu.GroupField .. " count for " .. sLink .. " in quest";

									CloseDropDownMenus();
									CommonersQuest.Slider.Init(sText1, sText2, 1, iStackable, oItemRef.Count, x, y, CommonersQuest.Menu.ItemCount.Slider, oData);
								else
									CQH.CommChat("ChatInfo", nil, "Invalid choice. Must not stack more than " .. iStackable .. " of this item.");
								end
							else
								CQH.CommChat("ChatInfo", nil, "Invalid choice. May not have same itemtype as choosable *and* as fixed reward.");
							end

							CommonersQuest.Menu.UpdateCurrentFrame();
							return
						end
					end
				end

				CQH.CommChat("ChatSpam", nil, "Adding new item...");
				if (oItem.Choice == true) then
					-- insert at front
					local	iCnt, i = #oGrp;
					if (iCnt > 0) then
						for i = (iCnt + 1), 2, -1 do
							oGrp[i] = oGrp[i - 1];
						end
					end
					oGrp[1] = oItem;
				else
					oGrp[#oGrp + 1] = oItem;
				end

				CloseDropDownMenus();
			elseif (CommonersQuest.Menu.Button == "RightButton") then
				local	iCnt, i = #oGrp, 0;
				while (i < iCnt) do
					i = i + 1;
					if ((oGrp[i].Type == oItem.Type) and (oGrp[i].ItemID == oItem.ItemID)) then
						CQH.CommChat("ChatInfo", "Quest", "Removing item from " .. CommonersQuest.Menu.GroupField ..  "[" .. i .. "]");
						if (i == iCnt) then
							oGrp[i] = nil;
						else
							local	j;
							for j = i, iCnt - 1 do
								oGrp[j] = oGrp[j + 1];
							end
							oGrp[iCnt] = nil;
							iCnt = iCnt - 1;
						end
					end
				end

				CloseDropDownMenus();
			end
		end
	end

	CommonersQuest.Menu.UpdateCurrentFrame();
end

function	CommonersQuest.Menu.ClickedEmote(self, arg1, arg2)
	CommonersQuest.Menu.ClickedEmoteDo(self, arg1, arg2);
	CommonersQuest.Main.Refresh(CommonersQuestMainframe);
end

function	CommonersQuest.Menu.ClickedEmoteDo(self, arg1, arg2)
	CloseDropDownMenus();
	if (CommonersQuest.Menu.GroupObj and CommonersQuest.Menu.Button) then
		if (CommonersQuest.Menu.Button == "LeftButton") then
			CQH.CommChat("DbgInfo", "Quest", "Would add emote '/" .. arg1 .. "' as requirement.");
		elseif (CommonersQuest.Menu.Button == "RightButton") then
			local	iCnt = #CommonersQuest.Menu.GroupObj;
			if (arg2 and (arg2 > 0) and (arg2 <= iCnt)) then
				local	oData = CommonersQuest.Menu.GroupObj[arg2];
				CommonersQuest.Menu.GroupObj[arg2] = CommonersQuest.Menu.GroupObj[iCnt];
				CommonersQuest.Menu.GroupObj[iCnt] = nil;

				CQH.CommChat("ChatInfo", "Quest", "Removed emote '/" .. oData.Emote .. " " .. oData.TargetDesc .. "' as requirement.");
			end

			CommonersQuest.Menu.UpdateCurrentFrame();
			return
		else
			return
		end

		local	sGUID = UnitGUID("target");
		if (sGUID) then
			local	sName = UnitName("target");
			local	oReq = { Type = "Emote", Emote = arg1, Friendly = true, TargetName = sName, TargetDesc = sName };

			local	iNPC = tonumber(strsub(sGUID, 5, 5), 16);
			if (bit.band(iNPC, 7) == 0) then
				DEFAULT_CHAT_FRAME:AddMessage("Target is a player.");
				oReq.TargetType = "PC"
				oReq.PlayerGUID = sGUID;
			else
				DEFAULT_CHAT_FRAME:AddMessage("Target is an NPC.");
				local	iNPCID = tonumber(strsub(sGUID, 6, 12), 16);
				oReq.TargetType = "NPC"
				oReq.MobID = iNPCID;

				if (not UnitIsFriend("player", "target")) then
					CQH.CommChat("ChatImportant", "Quest", "|cFFFF8080WARNING!|r For completion, emotes currently require NPCs to be friendly. The targetted NPC is NOT friendly with you. If the faction of this NPC cannot be raised, this quest might be impossible to complete!");
				end
			end

			tinsert(CommonersQuest.Menu.GroupObj, oReq);
			-- use a static popup frame, let user enter NPC description
			local	oData = { Table = oReq, Field = "TargetDesc", Text = sName, };
			StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
			StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", "emote '/" .. arg1 .. "'-target " .. oReq.TargetType .. " '" .. sName .. "'", "'description'");
		else
			CQH.CommChat("ChatSpam", "Quest", "No current target, other methods not yet implemented.");
--[[
			-- use a static popup frame, let user enter NPC name or id, on OK search and add
			CloseDropDownMenus();
			local	iID = CommonersQuestFrame:GetID();
			StaticPopupDialogs["COMMONERSQUEST_SEARCH_REQUIREMENTTARGET"].ID = iID;
			StaticPopupDialogs["COMMONERSQUEST_SEARCH_REQUIREMENTTARGET"].Type = "PC/NPC";
			StaticPopupDialogs["COMMONERSQUEST_SEARCH_REQUIREMENTTARGET"].Emote = arg1;
			StaticPopup_Show("COMMONERSQUEST_SEARCH_REQUIREMENTTARGET");
]]--
		end
	end
end

function	CommonersQuest.Menu.ClickedKill(self, arg1, arg2)
	CommonersQuest.Menu.ClickedKillDo(self, arg1, arg2);
	CommonersQuest.Main.Refresh(CommonersQuestMainframe);
end

function	CommonersQuest.Menu.ClickedKillDo(self, arg1, arg2)
	CloseDropDownMenus();
	if (CommonersQuest.Menu.GroupObj and CommonersQuest.Menu.Button) then
		if (CommonersQuest.Menu.Button == "LeftButton") then
			CQH.CommChat("DbgInfo", "Quest", "Would add kill-order as requirement.");
		elseif (CommonersQuest.Menu.Button == "RightButton") then
			local	iCnt = #CommonersQuest.Menu.GroupObj;
			if (arg2 and (arg2 > 0) and (arg2 <= iCnt)) then
				local	oData = CommonersQuest.Menu.GroupObj[arg2];
				CommonersQuest.Menu.GroupObj[arg2] = CommonersQuest.Menu.GroupObj[iCnt];
				CommonersQuest.Menu.GroupObj[iCnt] = nil;

				CQH.CommChat("ChatInfo", "Quest", "Removed 'kill-order for " .. oData.TargetDesc .. "' as requirement.");
			end

			CommonersQuest.Menu.UpdateCurrentFrame();
			return
		else
			return
		end

		local	sGUID = UnitGUID("target");
		if (sGUID) then
			local	iNPC = tonumber(strsub(sGUID, 5, 5), 16);
			if (bit.band(iNPC, 7) == 0) then
				DEFAULT_CHAT_FRAME:AddMessage("Target is a player. Not a valid choice.");
				return
			end

			local	sFaction = UnitFactionGroup("target");
			if ((sFaction == "Horde") or (sFaction == "Alliance")) then
				DEFAULT_CHAT_FRAME:AddMessage("Not a valid choice: This NPC is afffiliated with the faction <" .. sFaction .. ">");
				return
			end

			local	iNPCID = tonumber(strsub(sGUID, 6, 12), 16);

			local	iCnt = #CommonersQuest.Menu.GroupObj;
			if (iCnt > 0) then
				local	oReq, i;
				for i = 1, iCnt do
					oReq = CommonersQuest.Menu.GroupObj[i];
					if ((oReq.Type == "Kill") and (oReq.TargetType == "NPC") and (oReq.MobID == iNPCID)) then
						break
					else
						oReq = nil;
					end
				end

				if (oReq) then
					CQH.CommChat("DbgInfo", "Quest", "Found same kill-order, increasing size.");

					-- can't use menu button as parent, as this closes!
					local	oFrame = CommonersQuestProgressRequiredItemsText_MenuBtn;

					local	iStackable = 25;
					if (oReq.Count == nil) then
						iStackable = 10;
					elseif (oReq.Count >= 25) then
						iStackable = 100;
					end
					CommonersQuest.Menu.StackSplitCallback.oData = oReq;
					oFrame.SplitStack = CommonersQuest.Menu.StackSplitCallback.SplitStack;
					OpenStackSplitFrame(iStackable, oFrame, "BOTTOMLEFT", "TOPLEFT");
					return
				end
			end


			DEFAULT_CHAT_FRAME:AddMessage("Target is a valid NPC to kill.");

			local	sName = UnitName("target");
			local	oReq = { Type = "Kill", TargetType = "NPC", MobID = iNPCID, TargetName = sName, TargetDesc = sName };

			tinsert(CommonersQuest.Menu.GroupObj, oReq);
			-- use a static popup frame, let user enter NPC description
			local	oData = { Table = oReq, Field = "TargetDesc", Text = sName, };
			StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
			StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", "kill-order target " .. oReq.TargetType .. " '" .. sName .. "'", "'description'");
		else
			CQH.CommChat("ChatSpam", "Quest", "No current target, other methods not yet implemented.");
		end
	end
end

function	CommonersQuest.Menu.ClickedSurvive(self, arg1, arg2)
	CommonersQuest.Menu.ClickedSurviveDo(self, arg1, arg2);
	CommonersQuest.Main.Refresh(CommonersQuestMainframe);
end

function	CommonersQuest.Menu.ClickedSurviveDo(self, arg1, arg2)
	CloseDropDownMenus();
	if (CommonersQuest.Menu.GroupObj and CommonersQuest.Menu.Button) then
		if (CommonersQuest.Menu.Button == "LeftButton") then
			CQH.CommChat("DbgInfo", "Quest", "Would add survive-order as requirement.");
		elseif (CommonersQuest.Menu.Button == "RightButton") then
			local	iCnt = #CommonersQuest.Menu.GroupObj;
			if (arg2 and (arg2 > 0) and (arg2 <= iCnt)) then
				local	oData = CommonersQuest.Menu.GroupObj[arg2];
				CommonersQuest.Menu.GroupObj[arg2] = CommonersQuest.Menu.GroupObj[iCnt];
				CommonersQuest.Menu.GroupObj[iCnt] = nil;

				CQH.CommChat("ChatInfo", "Quest", "Removed 'survive-order for " .. oData.TargetDesc .. "' as requirement.");
			end

			CommonersQuest.Menu.UpdateCurrentFrame();
			return
		else
			return
		end

		local	sGUID = UnitGUID("target");
		if (sGUID) then
			local	sName = UnitName("target");
			local	oReq = { Type = "Survive", TargetName = sName, TargetDesc = sName };

			local	iNPC = tonumber(strsub(sGUID, 5, 5), 16);
			if (bit.band(iNPC, 7) == 0) then
				DEFAULT_CHAT_FRAME:AddMessage("Target is a player to protect.");

				oReq.TargetType = "PC";
				oReq.PlayerGUID = sGUID;
			else
				DEFAULT_CHAT_FRAME:AddMessage("Target is an NPC to protect.");

				local	iNPCID = tonumber(strsub(sGUID, 6, 12), 16);
				oReq.TargetType = "NPC";
				oReq.MobID = iNPCID;
			end

			tinsert(CommonersQuest.Menu.GroupObj, oReq);
			-- use a static popup frame, let user enter NPC description
			local	oData = { Table = oReq, Field = "TargetDesc", Text = sName, };
			StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
			StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", "survive-order target " .. oReq.TargetType .. " '" .. sName .. "'", "'description'");
		else
			CQH.CommChat("ChatSpam", "Quest", "No current target, other methods not yet implemented.");
		end
	end
end

function	CommonersQuest.Menu.ClickedDuel(self, arg1, arg2)
	CommonersQuest.Menu.ClickedDuelDo(self, arg1, arg2);
	CommonersQuest.Main.Refresh(CommonersQuestMainframe);
end

function	CommonersQuest.Menu.ClickedDuelDo(self, arg1, arg2)
	CloseDropDownMenus();
	if (CommonersQuest.Menu.GroupObj and CommonersQuest.Menu.Button) then
		if (CommonersQuest.Menu.Button == "LeftButton") then
			CQH.CommChat("DbgInfo", "Quest", "Would add duel-order as requirement.");
		elseif (CommonersQuest.Menu.Button == "MiddleButton") then
			CQH.CommChat("DbgInfo", "Quest", "Would modify duel-order as requirement.");
		elseif (CommonersQuest.Menu.Button == "RightButton") then
			local	iCnt = #CommonersQuest.Menu.GroupObj;
			if (arg2 and (arg2 > 0) and (arg2 <= iCnt)) then
				local	oData = CommonersQuest.Menu.GroupObj[arg2];
				CommonersQuest.Menu.GroupObj[arg2] = CommonersQuest.Menu.GroupObj[iCnt];
				CommonersQuest.Menu.GroupObj[iCnt] = nil;

				CQH.CommChat("ChatInfo", "Quest", "Removed <" .. CQH.RequirementToTextBasic(oData) .. "> as requirement.");
			end

			CommonersQuest.Menu.UpdateCurrentFrame();
			return
		else
			return
		end

		if (type(arg1) ~= "table") then
			return
		end

		if (CommonersQuest.Menu.Button == "LeftButton") then
			local	oReq;
			if (arg1.PlayerName and arg1.PlayerGUID) then
				if (UnitGUID("target") == arg1.PlayerGUID) then
					oReq = { Type = "Duel", DuelResult = arg1.DuelResult, PlayerName = arg1.PlayerName, PlayerGUID = arg1.PlayerGUID };
					oReq.PlayerFaction = UnitFactionGroup("target");
					local	_;
					_, oReq.PlayerRace = UnitRace("target");
					_, oReq.PlayerClass = UnitClass("target");
				end
			end

			if (arg1.Manual) then
				oReq = { Type = "Duel", DuelResult = arg1.DuelResult };

				-- use a static popup frame, let user enter player name
				local	oData = { Table = oReq, Field = "PlayerName", Text = "<Name>" };
				StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
				StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", "duel-order target player", "'name'");
			end

			if (arg1.Generic) then
				oReq = { Type = "Duel", DuelResult = arg1.DuelResult };
			end

			if (oReq) then
				tinsert(CommonersQuest.Menu.GroupObj, oReq);
			else
				CQH.CommChat("ChatInfo", nil, "Couldn't decode duel requirements. :-(");
			end

			return
		end

		if (CommonersQuest.Menu.Button == "MiddleButton") then
			if (arg1.Index == nil) then
				return
			end

			local	oReq = CommonersQuest.Menu.GroupObj[arg1.Index];
			if (type(oReq) ~= "table") then
				return
			end

			if (oReq.PlayerName and arg1.Toggle) then
				local	bValue = oReq[Toggle] == true;
				oReq[Toggle] = not bValue;
				return
			end

			if (arg1.Edit) then
				if (oReq.PlayerName and (arg1.Edit == "PlayerDesc")) then
					local	oData = { Table = oReq, Field = arg1.Edit, Text = oReq.PlayerName };
					StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
					StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", "duel-order target player '" .. oReq.PlayerName .. "'", "'description'");
				end

				if (arg1.Edit == "Count") then
					local	x, y = self:GetRight(), self:GetBottom();

					local	sText2, sText1 = CQH.QuestToPseudoLink(CommonersQuest.Menu.QuestID);
					local	oData = { oReq = oReq };
					sText1 = CommonersQuest.Menu.GroupField .. " count for selected duel in quest";

					CloseDropDownMenus();
					CommonersQuest.Slider.Init(sText1, sText2, 1, 25, oReq.Count or 1, x, y, CommonersQuest.Menu.ItemCount.Slider, oData);
				end

				return
			end

			local	oKeys, i = { [1] = "PlayerRace", [2] = "PlayerClass", [3] = "PlayerFaction" };
			for i = 1, #oKeys do
				local	sKey = oKeys[i];
				if (arg1[sKey]) then
					if (oReq[sKey] == arg1[sKey]) then
						oReq[sKey] = nil;
						if (sKey == "PlayerFaction") then
							oReq["PlayerRace"] = nil;
						end
					else
						oReq[sKey] = arg1[sKey];
					end

					return
				end
			end
		end
	end
end

function	CommonersQuest.Menu.ClickedMoney(self, arg1, arg2)
	CloseDropDownMenus();
	if (CommonersQuest.Menu.GroupObj and CommonersQuest.Menu.Button) then
		if (CommonersQuest.Menu.Button == "LeftButton") then
			local	iSum, sDbg = 0, "";
			if (arg1) then
				local	iAmount = CommonersQuest.Menu.QuestObj.Reward[arg1].Amount;
				sDbg = sDbg .. " <arg1:" .. arg1 .. " = " .. iAmount .. ">";
				iSum = iAmount;
			else
				sDbg = sDbg .. " <arg1:<nil>";
			end
			if (arg2) then
				local	iAmount = CommonersQuest.Menu.GroupObj[arg2].Amount; 
				sDbg = sDbg .. " <arg2:" .. arg2 .. " = " .. iAmount .. ">";
				iSum = iSum;
			else
				sDbg = sDbg .. " <arg2:<nil>";
			end

			CQH.CommChat("DbgInfo", "Quest", "Would add/edit money as requirement. Current value: " .. iSum .. " via " .. sDbg);

			if (arg2 == nil) then
				arg2 = #CommonersQuest.Menu.GroupObj + 1;
				CommonersQuest.Menu.GroupObj[arg2] = { Type = "Money", Amount = 0 };
			end
			-- oData: Table, Index, Amount, hasDefault
			local	oData = { Table = CommonersQuest.Menu.GroupObj, Index = arg2, Amount = iSum, hasDefault = (arg1 ~= nil) };

			StaticPopupDialogs["COMMONERSQUEST_EDIT_MONEYREWARD"].customdata = oData;
			StaticPopup_Show("COMMONERSQUEST_EDIT_MONEYREWARD");
		elseif (CommonersQuest.Menu.Button == "RightButton") then
			local	iCntFixed, iSum = #CommonersQuest.Menu.QuestObj.Reward;
			if (arg1 and (arg1 > 0) and (arg1 <= iCntFixed)) then
				iSum = CommonersQuest.Menu.QuestObj.Reward[arg1].Amount;
			end

			local	iCntCurrent = #CommonersQuest.Menu.GroupObj;
			if (arg2 and (arg2 > 0) and (arg2 <= iCntCurrent)) then
				local	oData = CommonersQuest.Menu.GroupObj[arg2];
				if (iSum) then
					CommonersQuest.Menu.GroupObj[arg2].Amount = 0;
				else
					CommonersQuest.Menu.GroupObj[arg2] = CommonersQuest.Menu.GroupObj[iCntCurrent];
					CommonersQuest.Menu.GroupObj[iCntCurrent] = nil;
				end

				CQH.CommChat("ChatInfo", "Quest", "CommonersQuest: Removed money <" .. oData.Amount .. "> as reward.");
			elseif (iSum) then
				local	oData = { Type = "Money", Amount = 0 };
				CommonersQuest.Menu.GroupObj[iCntCurrent + 1] = oData;
				CQH.CommChat("ChatInfo", "Quest", "CommonersQuest: Removed money <" .. oData.Amount .. "> as reward.");
			end
		end
	end
end

function	CommonersQuest.Menu.RiddleEdit(self)
	StaticPopup_Hide("COMMONERSQUEST_EDIT_FIELD");

	CQH.CommChat("DbgInfo", "Quest", "Riddle edit: progress = " .. self.Progress);

	local	sFieldInfo;
	local	oData = { Table = self.Table, Progress = self.Progress + 1, Callback = CommonersQuest.Menu.RiddleEdit };
	if (oData.Progress == 1) then
		oData.Field = "RiddleReference";
		oData.Text = "<really short riddle reference shown in quest progress description>";
		sFieldInfo = "'reference'";
	elseif (oData.Progress == 2) then
		oData.Field = "RiddleShortDesc";
		oData.Text = "<short description/hint shown when solving riddle>";
		sFieldInfo = "'short description/hint'";

		oData.Callback = nil;
	end

	if (sFieldInfo) then
		StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
		StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", "riddle information", sFieldInfo);
	end

	return true;
end

function	CommonersQuest.Menu.SliderRiddleLockout(iCount, oData)
	oData.oReq.RiddleLockout = iCount;
	CommonersQuest.Menu.UpdateCurrentFrame();
end

function	CommonersQuest.Menu.ClickedRiddle(self, arg1, arg2)
	CloseDropDownMenus();
	if (CommonersQuest.Menu.GroupObj and CommonersQuest.Menu.Button) then
		if (CommonersQuest.Menu.Button == "LeftButton") then
			CQH.CommChat("DbgInfo", "Quest", "Would add riddle as requirement.");
		elseif (CommonersQuest.Menu.Button == "MiddleButton") then
			CQH.CommChat("DbgInfo", "Quest", "Would modify riddle requirement.");
		elseif (CommonersQuest.Menu.Button == "RightButton") then
			local	iCnt = #CommonersQuest.Menu.GroupObj;
			if (arg2 and (arg2 > 0) and (arg2 <= iCnt)) then
				local	oData = CommonersQuest.Menu.GroupObj[arg2];
				CommonersQuest.Menu.GroupObj[arg2] = CommonersQuest.Menu.GroupObj[iCnt];
				CommonersQuest.Menu.GroupObj[iCnt] = nil;

				CQH.CommChat("ChatInfo", "Quest", "Removed <" .. CQH.RequirementToTextBasic(oData) .. "> as requirement.");
			end

			CommonersQuest.Menu.UpdateCurrentFrame();
			return
		else
			return
		end

		if (CommonersQuest.Menu.Button == "LeftButton") then
			local	iCnt, i = #CommonersQuest.Menu.GroupObj;
			for i = 1, iCnt do
				local	oReq = CommonersQuest.Menu.GroupObj[i];
				if (oReq.Type == "Riddle") then
					CQH.CommChat("ChatInfo", "Quest", "Currently only one riddle per quest allowed. Sorry!");
					return
				end
			end

			oReq = { Type = "Riddle" };
			tinsert(CommonersQuest.Menu.GroupObj, oReq);

			-- use a static popup frame, let user enter reference
			local	oData = { Table = oReq, Field = "RiddleSolution", Text = "<solution for this ridlde>", Callback = CommonersQuest.Menu.RiddleEdit, Progress = 0, Req = oReq };
			StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
			StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", "riddle information", "'solution'");
		end

		if (CommonersQuest.Menu.Button == "MiddleButton") then
			if (type(arg1) ~= "table") then
				return
			end

			if ((arg1.Index == nil) or (arg1.Edit == nil)) then
				return
			end

			local	oReq = CommonersQuest.Menu.GroupObj[arg1.Index];
			if (oReq.Type ~= "Riddle") then
				return
			end

			local	sTitle, sField, sValue;
			if (arg1.Edit == "RiddleReference") then
				sTitle = "quest requirement view";
				sField = "riddle 'reference' (less than 20 chars if possible)";
				sValue = oReq.RiddleReference;
			elseif (arg1.Edit == "RiddleShortDesc") then
				sTitle = "quest requirement view";
				sField = "riddle 'short hint'";
				sValue = oReq.RiddleShortDesc;
			elseif (arg1.Edit == "RiddleSolution") then
				sTitle = "quest requirement view";
				sField = "riddle 'solution'";
				sValue = oReq.RiddleSolution;
			end

			if (sTitle and sField) then
				if (sValue == nil) then
					sValue = "<unset>";
				end

				-- use a static popup frame, let user enter reference
				local	oData = { Table = oReq, Field = arg1.Edit, Text = sValue };
				StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
				StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", sTitle, sField);
			elseif (arg1.Edit == "RiddleLockout") then
				CQH.CommChat("DbgInfo", "Edit", "RiddeLockout called, self is: " .. self:GetName());
				local	x, y = self:GetRight(), self:GetBottom();

				local	oData = { oReq = oReq };
				local	sText1 = "Lockout for wrong solution in minutes to";
				local	sText2 = "riddle " .. arg1.Index .. ": " .. oReq.RiddleReference;

				CloseDropDownMenus();
				local	oMap = { [1] = { F = 1, T = 30, S = 1 }, [2] = { F = 30, T = 120, S = 5 }, [3] = { F = 120, T = 360, S = 15, D = 60 }, [4] = { F = 360, T = 1440, S = 60, D = 60 }, [5] = { F = 1440, T = 2880, S = 180, D = 60 } };
				CommonersQuest.Slider.Init(sText1, sText2, 1, 2880, oReq.RiddleLockout or 1, x, y, CommonersQuest.Menu.SliderRiddleLockout, oData, oMap);
			end
		end
	end
end

function	CommonersQuest.Menu.ClickedRewardsetDelete(self, arg1, arg2)
	CloseDropDownMenus();

	-- if not locked, allow deletion
	local	oRewardSet;
	if (CommonersQuest.Menu.Rewardset and CQDataGlobal.Rewards[arg1]) then
		local	oRewardSets = CQDataGlobal.Rewards[arg1];
		oRewardSet = oRewardSets[arg2];
	end

	if (oRewardSet) then
		local	oQuest = CQH.CharQuestToObj(nil, arg1);
		if (oQuest) then
			local	_, oState = CQH.InitStateGiver(oQuest);
			oState.Enabled = false;
			CQDataGlobal.Rewards[arg1][arg2] = nil;
			CQH.CommChat("ChatInfo", nil, "Dropped reward set " .. arg2 .. " from quest " .. CQH.QuestToPseudoLink(oQuest.ID, oQuest.Title) .. ". (Quest is being disabled to enforce a re-validation.)");

			if (CommonersQuestFrame:IsShown()) then
				FrameHide();
			end
			if (CommonersQuestMainframe:IsShown()) then
				CommonersQuest.Main.Refresh(CommonersQuestMainframe);
			end

			return
		end
	end

	CQH.CommChat("ChatInfo", nil, "Nothing deleted: Quest or reward set not found.");
end

-- req./rew. menu commands
local	RRMC = {
		ITEM = 1,
	};

local	REQMC = {
		EMOTE = 2,
		KILL = 3,
		SURVIVE = 4,
		DUEL = 5,
		RIDDLE = 6,
	};

function	CommonersQuest.Menu.Initialize(self, level)
	if ((CommonersQuest.Menu.GroupTitle == nil) or (CommonersQuest.Menu.QuestID == nil) or
	    (CommonersQuest.Menu.QuestObj == nil) or (CommonersQuest.Menu.GroupObj == nil)) then
		return
	end

	local	info;

	level = level or 1;
	if (level == 1) then
		info = {};
		info.text = "Quest " .. CommonersQuest.Menu.QuestID .. ": " .. CommonersQuest.Menu.GroupTitle;
		info.isTitle = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info);

		info = {};
		if ((CommonersQuest.Menu.Button == "LeftButton") or
		    (CommonersQuest.Menu.Button == "MiddleButton") and (CommonersQuest.Menu.GroupField == "Reward")) then
			info.text = "Items adding...";
		elseif (CommonersQuest.Menu.Button == "RightButton") then
			info.text = "Items removing...";
		end
		info.notCheckable = 1;
		info.value = RRMC.ITEM;
		info.hasArrow = true;
		if (info.text) then
			UIDropDownMenu_AddButton(info);
		end

		if (CommonersQuest.Menu.GroupField == "Requirements") then
			if ((CommonersQuest.Menu.Button == "LeftButton") or (CommonersQuest.Menu.Button == "RightButton")) then
				info = {};
				if (CommonersQuest.Menu.Button == "LeftButton") then
					info.text = "Emotes adding...";
				elseif (CommonersQuest.Menu.Button == "RightButton") then
					info.text = "Emotes removing...";
				end
				info.notCheckable = 1;
				info.value = REQMC.EMOTE;
				info.hasArrow = true;
				UIDropDownMenu_AddButton(info);

				info = {};
				if (CommonersQuest.Menu.Button == "LeftButton") then
					info.text = "Add kill order";
					info.func = CommonersQuest.Menu.ClickedKill;
				elseif (CommonersQuest.Menu.Button == "RightButton") then
					info.text = "Remove kill order";
					info.hasArrow = true;
				end
				info.notCheckable = 1;
				info.value = REQMC.KILL;
				UIDropDownMenu_AddButton(info);

				info = {};
				if (CommonersQuest.Menu.Button == "LeftButton") then
					info.text = "Add survive order";
					info.func = CommonersQuest.Menu.ClickedSurvive;
				elseif (CommonersQuest.Menu.Button == "RightButton") then
					info.text = "Remove survive order";
					info.hasArrow = true;
				end
				info.notCheckable = 1;
				info.value = REQMC.SURVIVE;
				UIDropDownMenu_AddButton(info);

				info = {};
				if (CommonersQuest.Menu.Button == "LeftButton") then
					info.text = "Add duel order";
					info.hasArrow = true;
				elseif (CommonersQuest.Menu.Button == "RightButton") then
					info.text = "Remove duel order";
					info.hasArrow = true;
				end
				info.notCheckable = 1;
				info.value = REQMC.DUEL;
				UIDropDownMenu_AddButton(info);

				info = {};
				if (CommonersQuest.Menu.Button == "LeftButton") then
					info.text = "Add riddle";
					info.func = CommonersQuest.Menu.ClickedRiddle;
				elseif (CommonersQuest.Menu.Button == "RightButton") then
					info.text = "Remove riddle";
					info.hasArrow = true;
				end
				info.notCheckable = 1;
				info.value = REQMC.RIDDLE;
				UIDropDownMenu_AddButton(info);
			end

			if (CommonersQuest.Menu.Button == "MiddleButton") then
				info = {};
				info.text = "Modify duel order";
				info.hasArrow = true;
				info.notCheckable = 1;
				info.value = REQMC.DUEL;
				UIDropDownMenu_AddButton(info);

				info = {};
				info.text = "Modify riddle information";
				info.hasArrow = true;
				info.notCheckable = 1;
				info.value = REQMC.RIDDLE;
				UIDropDownMenu_AddButton(info);
			end
		end

		if (CommonersQuest.Menu.GroupField == "Reward") then
			info = {};

			local	iSum, iCnt, i = 0;

			if (CommonersQuest.Menu.QuestObj.Reward) then
				iCnt = #CommonersQuest.Menu.QuestObj.Reward;
				if (iCnt > 0) then
					for i = 1, iCnt do
						local	oX = CommonersQuest.Menu.QuestObj.Reward[i];
						if (oX.Type == "Money") then
							info.arg1 = i;
							iSum = oX.Amount;
							break;
						end
					end
				end
			end

			iCnt = #CommonersQuest.Menu.GroupObj;
			for i = 1, iCnt do
				local	oX = CommonersQuest.Menu.GroupObj[i];
				if (oX.Type == "Money") then
					info.arg2 = i;
					iSum = oX.Amount;
					break;
				end
			end

			if (CommonersQuest.Menu.Button == "LeftButton") then
				info.text = "Money reward: add/edit";
			elseif (CommonersQuest.Menu.Button == "RightButton") then
				if (iSum ~= 0) then
					info.text = "Money reward: remove <" .. iSum .. ">";
				end
			end

			if (info.text) then
				info.notCheckable = 1;
				info.func = CommonersQuest.Menu.ClickedMoney;
				UIDropDownMenu_AddButton(info);
			end

			-- if not locked, allow deletion
			local	oRewardSet;
			if (CommonersQuest.Menu.Rewardset and CQDataGlobal.Rewards[CommonersQuest.Menu.QuestID]) then
				local	oRewardSets = CQDataGlobal.Rewards[CommonersQuest.Menu.QuestID];
				oRewardSet = oRewardSets[CommonersQuest.Menu.Rewardset];
			end

			if (type(oRewardSet) == "table") then
				info = {};
				info.text = "--------";
				info.notCheckable = 1;
				info.notClickable = 1;
				info.justifyH = "CENTER";
				UIDropDownMenu_AddButton(info);

				info = {};
				info.text = "|cFFFF6060DELETE|r this |cFFFF8080WHOLE|r reward set";
				info.notCheckable = 1;
				if (oRewardSet.State.Locked ~= true) then
					info.func = CommonersQuest.Menu.ClickedRewardsetDelete;
					info.arg1 = CommonersQuest.Menu.QuestID;
					info.arg2 = CommonersQuest.Menu.Rewardset;
				else
					info.notClickable = 1;
				end
				UIDropDownMenu_AddButton(info);
			end
		end

		return
	end

	if (level == 2) then
		if (UIDROPDOWNMENU_MENU_VALUE == nil) or (type(UIDROPDOWNMENU_MENU_VALUE) ~= "number") then
			return
		end

		if (UIDROPDOWNMENU_MENU_VALUE == RRMC.ITEM) then
			local	oItems = {};
			if ((CommonersQuest.Menu.Button == "LeftButton") or (CommonersQuest.Menu.Button == "MiddleButton")) then
				local	bAll, iBag = true;
				for iBag = 0, 4 do
					if (IsBagOpen(iBag)) then
						bAll = false;
					end
				end

				-- build a list of items currently selected
				local	oIDs = {};
				local	iCnt, i = #CommonersQuest.Menu.GroupObj;
				for i = 1, iCnt do
					local	oX = CommonersQuest.Menu.GroupObj[i];
					if (((oX.Type == "Item") or (oX.Type == "Loot")) and (oX.ItemID)) then
						oIDs[oX.ItemID] = 1;
					end
				end

				-- build a list of all items on the player that are not bound
				for iBag = 0, 4 do
					if (bAll or IsBagOpen(iBag)) then
						local	iSlotCnt, iSlot = GetContainerNumSlots(iBag);
						for iSlot = 1, iSlotCnt do
							local	sItem = GetContainerItemLink(iBag, iSlot);
							if (sItem and string.match(sItem, "(item:%d+)")) then
								local	bOk = true;
								CommonersQuestScanningTooltip:ClearLines()
								CommonersQuestScanningTooltip:SetBagItem(iBag, iSlot);
								local	iLineCnt, iLine = CommonersQuestScanningTooltip:NumLines();
								for iLine = 1, iLineCnt do
									local	sLine, k, v = getglobal("CommonersQuestScanningTooltipTextLeft" .. iLine):GetText();
									for k, v in pairs(CommonersQuest.Strings.Item) do
										if (string.match(sLine, v)) then
											bOk = false;
											break;
										end
									end
								end

								if (bOk) then
									info = {};
									info.text = "Bag " .. (iBag + 1) .. ", Slot " .. iSlot .. ": " .. sItem;
									info.func = CommonersQuest.Menu.ClickedItem;
									info.arg1 = sItem;
									local	iItem = tonumber(string.match(sItem, "item:(%d+)"));
									if (oIDs[iItem]) then
										info.checked = 1;
									end
									UIDropDownMenu_AddButton(info, 2);
								end
							end
						end
					end
				end

				if (CommonersQuest.Menu.GroupField == "Requirements") then
					-- add menu entry to insert a name that we then try to find
					info = {};
					info.text = "Add an item by name";
					info.func = CommonersQuest.Menu.FindItemByName;
					UIDropDownMenu_AddButton(info, 2);
				end
			elseif (CommonersQuest.Menu.Button == "RightButton") then
				-- build a list of items currently selected
				local	iCnt, i = #CommonersQuest.Menu.GroupObj;
				for i = 1, iCnt do
					local	oX = CommonersQuest.Menu.GroupObj[i];
					if (((oX.Type == "Item") or (oX.Type == "Loot")) and (oX.ItemID)) then
						local	sItem = "item:" .. oX.ItemID;
						local	_, sLink = GetItemInfo(sItem);
						if (sLink and string.match(sLink, "(item:%d+)")) then
							info = {};
							info.text = "Remove " .. " " .. i .. ": " .. sLink;
							info.notCheckable = 1;
							info.arg1 = sLink;
							info.func = CommonersQuest.Menu.ClickedItem;
							UIDropDownMenu_AddButton(info, 2);
						end
					end
				end
			end

			return
		end

		if (CommonersQuest.Menu.GroupField == "Requirements") then
			if (UIDROPDOWNMENU_MENU_VALUE == REQMC.EMOTE) then
				local	sPrefix;
				if (CommonersQuest.Menu.Button == "LeftButton") then
					sPrefix = "Add ";
					local	k, v;
					for k, v in pairs(CommonersQuestLang.Emotes) do
						info = {};
						info.text = sPrefix .. " Emote: /" .. k;
						info.notCheckable = 1;
						info.arg1 = k;
						info.func = CommonersQuest.Menu.ClickedEmote;
						UIDropDownMenu_AddButton(info, 2);
					end
				elseif (CommonersQuest.Menu.Button == "RightButton") then
					sPrefix = "Remove ";
					local	iNum, iCnt, i = 0, #CommonersQuest.Menu.GroupObj;
					if (iCnt > 0) then
						for i = 1, iCnt do
							local	oX = CommonersQuest.Menu.GroupObj[i];
							if (oX.Type == "Emote") then
								iNum = iNum + 1;

								info = {};
								info.text = sPrefix .. "<" .. CQH.RequirementToTextForEdit(oX) .. ">";
								info.notCheckable = 1;
								info.arg1 = oX.Emote;
								info.arg2 = i;
								info.func = CommonersQuest.Menu.ClickedEmote;
								UIDropDownMenu_AddButton(info, 2);
							end
						end
					end

					if (iNum == 0) then
						info = {};
						info.text = "No emotes currently in requirments.";
						info.notCheckable = 1;
						info.notClickable = 1;
						UIDropDownMenu_AddButton(info, 2);

						return
					end
				end

				return
			end

			if ((UIDROPDOWNMENU_MENU_VALUE == REQMC.KILL) or
			    (UIDROPDOWNMENU_MENU_VALUE == REQMC.SURVIVE) or
			    (UIDROPDOWNMENU_MENU_VALUE == REQMC.DUEL) or
			    (UIDROPDOWNMENU_MENU_VALUE == REQMC.RIDDLE)) then
				if (UIDROPDOWNMENU_MENU_VALUE == REQMC.DUEL) then
					if (CommonersQuest.Menu.Button == "LeftButton") then
						local	sTarget, sServer = UnitName("target");
						if (sServer and (sServer ~= "")) then
							sTarget = sTarget .. "@" .. sServer;
						end
						local	sGUID = UnitGUID("target");
						if (sGUID) then
							local	iNPC = tonumber(strsub(sGUID, 5, 5), 16);
							if (bit.band(iNPC, 7) ~= 0) then
								sTarget = nil;
							end
						end

						local	oDuelResults, sDuelResult, i = { [1] = "win", [2] = "lose" };
						for i = 1, 2 do
							sDuelResult = ": " .. oDuelResults[i];

							info = {};
							info.text = "Duel result" .. sDuelResult;
							info.isTitle = 1;
							info.notCheckable = 1;
							UIDropDownMenu_AddButton(info, 2);

							info = {};
							if (sTarget and sGUID) then
								info.text = "Current target " .. sTarget .. sDuelResult;
								info.func = CommonersQuest.Menu.ClickedDuel;
								info.arg1 = { PlayerName = sTarget, PlayerGUID = sGUID, DuelResult = oDuelResults[i] };
							else
								info.text = "No current target";
								info.disabled = 1;
							end
							info.notCheckable = 1;
							UIDropDownMenu_AddButton(info, 2);

							info = {};
							info.text = "<Enter name>" .. sDuelResult;
							info.func = CommonersQuest.Menu.ClickedDuel;
							info.arg1 = { Manual = true, DuelResult = oDuelResults[i] };
							info.notCheckable = 1;
							UIDropDownMenu_AddButton(info, 2);

							info = {};
							info.text = "Generic target" ..  sDuelResult .. " (after adding click middle to specify)";
							info.func = CommonersQuest.Menu.ClickedDuel;
							info.arg1 = { Generic = true, DuelResult = oDuelResults[i] };
							info.notCheckable = 1;
							UIDropDownMenu_AddButton(info, 2);
						end
					end

					if (CommonersQuest.Menu.Button == "MiddleButton") then
						local	iNum, iCnt, i = 0, #CommonersQuest.Menu.GroupObj;
						if (iCnt > 0) then
							for i = 1, iCnt do
								local	oX = CommonersQuest.Menu.GroupObj[i];
								if (oX.Type == "Duel") then
									info = {};
									info.value = { Type = "Duel", Index = i };
									info.text = "Modify order <" .. CQH.RequirementToTextForEdit(oX) .. ">";
									info.notCheckable = 1;
									info.hasArrow = true;
									UIDropDownMenu_AddButton(info, 2);
								end
							end
						end
					end
				end

				if (UIDROPDOWNMENU_MENU_VALUE == REQMC.RIDDLE) then
					if (CommonersQuest.Menu.Button == "MiddleButton") then
						local	iNum, iCnt, i = 0, #CommonersQuest.Menu.GroupObj;
						if (iCnt > 0) then
							for i = 1, iCnt do
								local	oX = CommonersQuest.Menu.GroupObj[i];
								if (oX.Type == "Riddle") then
									info = {};
									info.value = { Type = "Riddle", Index = i };
									info.text = "Modify riddle <" .. i .. ": " .. (oX.RiddleReference or "???") .. ">";
									info.notCheckable = 1;
									info.hasArrow = true;
									UIDropDownMenu_AddButton(info, 2);
								end
							end
						end
					end
				end

				if (CommonersQuest.Menu.Button == "RightButton") then
					local	sPrefix, sType = "Remove ";
					if (UIDROPDOWNMENU_MENU_VALUE == REQMC.KILL) then
						sType = "Kill";
					elseif (UIDROPDOWNMENU_MENU_VALUE == REQMC.SURVIVE) then
						sType = "Survive";
					elseif (UIDROPDOWNMENU_MENU_VALUE == REQMC.DUEL) then
						sType = "Duel";
					elseif (UIDROPDOWNMENU_MENU_VALUE == REQMC.RIDDLE) then
						sType = "Riddle";
					end

					if (sType == nil) then
						DEFAULT_CHAT_FRAME:AddMessage("[CQ] Invalid menu choice?? 3/4/5 -> ?");
						return
					end

					local	iNum, iCnt, i = 0, #CommonersQuest.Menu.GroupObj;
					if (iCnt > 0) then
						for i = 1, iCnt do
							local	oX = CommonersQuest.Menu.GroupObj[i];
							if (oX.Type == sType) then
								iNum = iNum + 1;

								info = {};
								info.text = sPrefix .. "<" .. CQH.RequirementToTextForEdit(oX) .. ">";
								info.notCheckable = 1;
								info.arg1 = nil;
								info.arg2 = i;
								if (sType == "Kill") then
									info.func = CommonersQuest.Menu.ClickedKill;
								elseif (sType == "Survive") then
									info.func = CommonersQuest.Menu.ClickedSurvive;
								elseif (sType == "Duel") then
									info.func = CommonersQuest.Menu.ClickedDuel;
								elseif (sType == "Riddle") then
									info.func = CommonersQuest.Menu.ClickedRiddle;
								end
								UIDropDownMenu_AddButton(info, 2);
							end
						end
					end

					if (iNum == 0) then
						info = {};
						info.text = "No \"" .. sType .. "\" orders currently in requirments.";
						info.notCheckable = 1;
						info.notClickable = 1;
						UIDropDownMenu_AddButton(info, 2);

						return
					end
				end

				return
			end
		end
	end

	if (level == 3) then
		if (type(UIDROPDOWNMENU_MENU_VALUE) ~= "table") then
			return
		end

		local	oValue = UIDROPDOWNMENU_MENU_VALUE;
		if (oValue.Type == "Duel") then
			local	oX = CommonersQuest.Menu.GroupObj[oValue.Index];
			if ((oX.Type ~= "Duel") or (oX.DuelResult == nil)) then
				-- not a duel or definite player selected
				return
			end

			info = {};
			info.text = "Duel " .. oX.DuelResult;
			if (oX.Count and (oX.Count > 1)) then
				info.text = info.text .. " " .. oX.Count .. " times";
			end
			info.isTitle = 1;
			UIDropDownMenu_AddButton(info, level);

			info = {};
			info.text = "Change count";
			info.func = CommonersQuest.Menu.ClickedDuel;
			info.arg1 = { Index = oValue.Index, Edit = "Count" };
			UIDropDownMenu_AddButton(info, level);

			info = {};
			info.text = "Description of target player";
			if (oX.PlayerName) then
				info.func = CommonersQuest.Menu.ClickedDuel;
				info.arg1 = { Index = oValue.Index, Edit = "PlayerDesc" };
			else
				info.disabled = 1;
			end
			UIDropDownMenu_AddButton(info, level);

			info = {};
			info.text = "Must streak";
			info.func = CommonersQuest.Menu.ClickedDuel;
			info.arg1 = { Index = oValue.Index, Toggle = "DuelStreak" };
			if (oX.DuelStreak) then
				info.checked = 1;
			end
			UIDropDownMenu_AddButton(info, level);

			info = {};
			info.text = "Public area";
			info.func = CommonersQuest.Menu.ClickedDuel;
			info.arg1 = { Index = oValue.Index, Toggle = "DuelArea" };
			if (oX.DuelArea) then
				info.checked = 1;
			end
			UIDropDownMenu_AddButton(info, level);

			if (oX.PlayerGUID) then
				return
			end

			local	oFactions = { [1] = "Alliance", [2] = "Horde" };
			local	i, sFaction;
			for i = 1, 2 do
				sFaction = oFactions[i];

				info = {};
				info.text = "Faction: " .. sFaction;
				info.func = CommonersQuest.Menu.ClickedDuel;
				info.arg1 = { Index = oValue.Index, PlayerFaction = sFaction };
				if (oX.PlayerFaction and (oX.PlayerFaction == sFaction)) then
					info.checked = 1;
				end
				UIDropDownMenu_AddButton(info, level);

				local	k, v;
				for k, v in pairs(CommonersQuest.Strings.Race[sFaction].Male) do
					info = {};
					info.text = "Race: " .. v;
					info.func = CommonersQuest.Menu.ClickedDuel;
					info.arg1 = { Index = oValue.Index, PlayerRace = k };
					if (sFaction ~= oX.PlayerFaction) then
						info.disabled = 1;
					end
					if (oX.PlayerRace and (oX.PlayerRace == k)) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, level);
				end
			end

			local	k, v;
			for k, v in pairs(CommonersQuest.Strings.Class.Male) do
				info = {};
				info.text = "Class: " .. v;
				info.func = CommonersQuest.Menu.ClickedDuel;
				info.arg1 = { Index = oValue.Index, PlayerClass = k };
				if (oX.PlayerClass and (oX.PlayerClass == k)) then
					info.checked = 1;
				end
				if (oX.PlayerFaction == nil) then
					info.disabled = 1;
				end
				UIDropDownMenu_AddButton(info, level);
			end
		end

		if (oValue.Type == "Riddle") then
			local	oX = CommonersQuest.Menu.GroupObj[oValue.Index];
			if (oX.Type ~= "Riddle") then
				-- not a riddle
				return
			end

			info = {};
			info.text = "Change reference <" .. (oX.RiddleReference or "???") .. ">";
			info.func = CommonersQuest.Menu.ClickedRiddle;
			info.arg1 = { Index = oValue.Index, Edit = "RiddleReference" };
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);

			info = {};
			info.text = "Change solution <" .. (oX.RiddleSolution or "<unset>") .. ">";
			info.func = CommonersQuest.Menu.ClickedRiddle;
			info.arg1 = { Index = oValue.Index, Edit = "RiddleSolution" };
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);

			info = {};
			info.text = "Change additional short hint\n<" .. strsub((oX.RiddleShortDesc or "???"), 1, 40) .. "...>";
			info.func = CommonersQuest.Menu.ClickedRiddle;
			info.arg1 = { Index = oValue.Index, Edit = "RiddleShortDesc" };
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);

			info = {};
			local	xLockout = (oX.RiddleLockout or 1);
			if (xLockout > 60) then
				xLockout = math.floor(xLockout / 60) .. "h " .. (xLockout % 60) .. "m";
			else
				xLockout = xLockout .. " minutes";
			end
			info.text = "Change lockout <" .. xLockout .. "> for giving the wrong solution";
			info.func = CommonersQuest.Menu.ClickedRiddle;
			info.arg1 = { Index = oValue.Index, Edit = "RiddleLockout" };
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);
		end
	end
end

function	CommonersQuest.QuestEdit.InitMenu(oFrame, sButton)
	if ((CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.Player == nil)) then
		CommonersQuest.Menu.QuestID = CommonersQuestFrame:GetID();
		local sFrame = oFrame:GetName();
		if (sFrame == "CommonersQuestDetailRewardTitleText_MenuBtn") then
			sKind = "Reward";
		elseif (sFrame == "CommonersQuestProgressRequiredItemsText_MenuBtn") then
			sKind = "Require";
		end

		CommonersQuest.QuestEdit.InitMenuIndirect(oFrame, sButton, sKind, CommonersQuestFrame.RewardSet);
	end
end

function	CommonersQuest.QuestEdit.InitMenuIndirect(oFrame, sButton, sKind, xRewardset)
	if (CommonersQuest.Menu.QuestID) then
		CommonersQuest.Menu.QuestObj = nil;

		local	oQuests;
		if (CommonersQuest.Menu.QuestID < 1000000) then
			oQuests = CommonersQuest.QuestDB;
		else
			oQuests = CommonersQuestKrbrPrdmrOther.CustomQuests;
		end

		local	k, v;
		for k, v in pairs(oQuests) do
			if (v.ID == CommonersQuest.Menu.QuestID) then
				CommonersQuest.Menu.QuestObj = v;
				break;
			end
		end

		CommonersQuest.Menu.Button = nil;
		CommonersQuest.Menu.GroupTitle = nil;
		CommonersQuest.Menu.GroupField = nil;
		CommonersQuest.Menu.GroupObj = nil;

		if (sKind == "Reward") then
			if (sButton == "LeftButton") then
				CQH.CommChat("DbgInfo", "Quest", "Clicked <Reward> to add a fixed reward...");
				CommonersQuest.Menu.GroupTitle = "add fixed";
			elseif (sButton == "MiddleButton") then
				CQH.CommChat("DbgInfo", "Quest", "Clicked <Reward> to add a choosable reward...");
				CommonersQuest.Menu.GroupTitle = "add choosable";
			elseif (sButton == "RightButton") then
				CQH.CommChat("DbgInfo", "Quest", "Clicked <Reward> to remove reward...");
				CommonersQuest.Menu.GroupTitle = "modify current";
			else
				sButton = nil;
			end

			if (sButton) then
				CommonersQuest.Menu.Button = sButton;
				CommonersQuest.Menu.GroupTitle = CommonersQuest.Menu.GroupTitle .. " Rewards";
				CommonersQuest.Menu.GroupField = "Reward";
				CommonersQuest.Menu.GroupObj = CQH.InitRewards(CommonersQuest.Menu.QuestObj.ID, xRewardset);
				CommonersQuest.Menu.Rewardset = xRewardset;
			end
		elseif (sKind == "Require") then
			if (sButton == "LeftButton") then
				CQH.CommChat("DbgInfo", "Quest", "Clicked <Requirements> to add a requirement...");
				CommonersQuest.Menu.GroupTitle = "add new";
			elseif (sButton == "MiddleButton") then
				CQH.CommChat("DbgInfo", "Quest", "Clicked <Requirements> to modfiy (duel) requirement...");
				CommonersQuest.Menu.GroupTitle = "modify current";
			elseif (sButton == "RightButton") then
				CQH.CommChat("DbgInfo", "Quest", "Clicked <Requirements> to remove requirement...");
				CommonersQuest.Menu.GroupTitle = "remove current";
			else
				sButton = nil;
			end

			if (sButton) then
				CommonersQuest.Menu.Button = sButton;
				CommonersQuest.Menu.GroupTitle = CommonersQuest.Menu.GroupTitle .. " requirements";
				CommonersQuest.Menu.GroupField = "Requirements";
				CommonersQuest.Menu.GroupObj = CommonersQuest.Menu.QuestObj.Requirements;
			end
		end

		CommonersQuest.Menu.Button = sButton;
		if (sButton and CommonersQuest.Menu.GroupTitle) then
			ToggleDropDownMenu(1, nil, CommonersQuestMenu, oFrame, 0, 0);
		end
	end
end

--
--
--

function	CommonersQuest.FrameGreetingPanel.Init(oActive, oAvailable, oUnavailable, oPending, oTransferring, bTotalsSpam)
	CommonersQuestGreetingText:SetText("Welcome traveller,\nmight I gather your interest for a quest?");
	CommonersQuestCurrentQuestsText:SetText("Quests in progress");
	CommonersQuestAvailableQuestsText:SetText("Available quests");

	CommonersQuestFrameRewardPanel:Hide();
	CommonersQuestFrameProgressPanel:Hide();
	CommonersQuestFrameDetailPanel:Hide();

	local sPlayer = CommonersQuestFrame.Player;
	local oQuestsGlobal = CommonersQuest.QuestDB;
	local oQuestsCustom = CommonersQuestKrbrPrdmrDataPerChar[sPlayer].QuestsCustom;
	local numActiveQuests = #oActive;
	local numAvailableQuests = #oAvailable;
	local numUnavailableQuests = #oUnavailable;
	local numPendingQuests = #oPending;
	local numTransferringQuests = #oTransferring;

	if (bTotalsSpam) then
		DEFAULT_CHAT_FRAME:AddMessage("You have " .. numActiveQuests .. " quests from " .. sPlayer .. " going. Pending for a binding item are " .. numPendingQuests .. ".");
		DEFAULT_CHAT_FRAME:AddMessage("They currently offer " .. numAvailableQuests .. " more quests and have " .. numUnavailableQuests .. " disabled quests...");
		if (numTransferringQuests > 0) then
			DEFAULT_CHAT_FRAME:AddMessage("Of those, " .. numTransferringQuests .. " quests are being transferred in the background currently.");
		end
	end

	if ( numActiveQuests == 0 ) then
		CommonersQuestCurrentQuestsText:Hide();
		QuestGreetingFrameHorizontalBreak:Hide();
	else
		CommonersQuestCurrentQuestsText:SetPoint("TOPLEFT", CommonersQuestGreetingText, "BOTTOMLEFT", 0, -10);
		CommonersQuestCurrentQuestsText:Show();
		CommonersQuestTitleButton1:SetPoint("TOPLEFT", CommonersQuestCurrentQuestsText, "BOTTOMLEFT", -10, -5);
		for i = 1, numActiveQuests, 1 do
			local iCommonersQuestIndex = oActive[i];
			local	oQuest;
			if (iCommonersQuestIndex > 0) then
				oQuest = oQuestsGlobal[iCommonersQuestIndex];
			else
				oQuest = oQuestsCustom[- iCommonersQuestIndex];
			end

			local	sTitle = oQuest.Title;
			if (oQuest.State and oQuest.State.Encrypted) then
				sTitle = oQuest.ID .. " (encrypted)";
			end

			local questTitleButton = getglobal("CommonersQuestTitleButton" .. i);
			local questTitleButtonIcon = getglobal("CommonersQuestTitleButton" .. i .. "QuestIcon");

			-- overwrite default on-click handler
			questTitleButton:SetScript("OnClick", CommonersQuest.FrameGreetingPanel.QuestActiveButtonClicked);

			local	oQuestCurr = CQData[sPlayer].QuestsCurrent[oQuest.ID];
			if (oQuestCurr and oQuestCurr.Abandonned) then
				-- overwrite default on-click handler
				questTitleButton:SetScript("OnClick", CommonersQuest.FrameGreetingPanel.QuestAbandonnedButtonClicked);

				questTitleButton:SetFormattedText(NORMAL_QUEST_DISPLAY .. " (Abandonned)", sTitle);
				questTitleButtonIcon:SetVertexColor(  1, 0.8, 0.8);
				questTitleButtonIcon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon");
			elseif (oQuest.State and oQuest.State.Dirty) then
				questTitleButton:SetFormattedText(NORMAL_QUEST_DISPLAY .. " (Broken)", sTitle);
				questTitleButtonIcon:SetVertexColor(0.8, 0.4, 0.4);
				questTitleButtonIcon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon");
			else
				questTitleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, sTitle);
				questTitleButtonIcon:SetVertexColor(  1,   1,   1);
				questTitleButtonIcon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon");
			end

			questTitleButton:SetHeight(questTitleButton:GetTextHeight() + 2);
			questTitleButton:SetID(oQuest.ID);
			questTitleButton.isActive = 1;

			questTitleButton:Show();
			if ( i > 1 ) then
				questTitleButton:SetPoint("TOPLEFT", "CommonersQuestTitleButton" .. (i - 1), "BOTTOMLEFT", 0, -2)
			end
		end
	end

	if ( numAvailableQuests + numPendingQuests == 0 ) then
		CommonersQuestAvailableQuestsText:Hide();
		CommonersQuestGreetingFrameHorizontalBreak:Hide();
	else
		if ( numActiveQuests > 0 ) then
			CommonersQuestGreetingFrameHorizontalBreak:SetPoint("TOPLEFT", "CommonersQuestTitleButton" .. numActiveQuests, "BOTTOMLEFT",22,-10);
			CommonersQuestGreetingFrameHorizontalBreak:Show();
			CommonersQuestAvailableQuestsText:SetPoint("TOPLEFT", CommonersQuestGreetingFrameHorizontalBreak, "BOTTOMLEFT", -12, -10);
		else
			CommonersQuestAvailableQuestsText:SetPoint("TOPLEFT", CommonersQuestGreetingText, "BOTTOMLEFT", 0, -10);
		end

		CommonersQuestAvailableQuestsText:Show();

		local	iOffset = numActiveQuests;
		getglobal("CommonersQuestTitleButton"..(iOffset + 1)):SetPoint("TOPLEFT", CommonersQuestAvailableQuestsText, "BOTTOMLEFT", -10, -5);
		for i = 1, (numAvailableQuests + numPendingQuests) do
			local iCommonersQuestIndex, bPending;
			if (i <= numAvailableQuests) then
				iCommonersQuestIndex = oAvailable[i];
				bPending = false;
			else
				iCommonersQuestIndex = oPending[i - numAvailableQuests];
				bPending = true;
			end

			local	oQuest;
			if (iCommonersQuestIndex > 0) then
				oQuest = oQuestsGlobal[iCommonersQuestIndex];
			else
				oQuest = oQuestsCustom[- iCommonersQuestIndex];
			end

			local	sTitle, iID = oQuest.Title, oQuest.ID;
			if (oQuest.State and oQuest.State.Encrypted) then
				sTitle = oQuest.ID .. " (encrypted)";
			end

			local questTitleButton = getglobal("CommonersQuestTitleButton".. (iOffset + i));
			local questTitleButtonIcon = getglobal(questTitleButton:GetName() .. "QuestIcon");

			if (bPending) then
				questTitleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, sTitle);
				questTitleButtonIcon:SetVertexColor(0.5,0.5,0.5);
				questTitleButtonIcon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon");
			else
				questTitleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, sTitle);
				questTitleButtonIcon:SetVertexColor(1,1,1);
				questTitleButtonIcon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon");
			end
			questTitleButton:SetHeight(questTitleButton:GetTextHeight() + 2);
			questTitleButton:SetID(iID);
			questTitleButton.isActive = 0;

			-- overwrite default on-click handler
			questTitleButton:SetScript("OnClick", CommonersQuest.FrameGreetingPanel.QuestAvailableButtonClicked);

			questTitleButton:Show();
			if ( i > 1 ) then
				questTitleButton:SetPoint("TOPLEFT", "CommonersQuestTitleButton".. (iOffset + i - 1),"BOTTOMLEFT", 0, -2)
			end
		end
	end

	if (numTransferringQuests > 0) then
		if ( numAvailableQuests + numPendingQuests == 0 ) then
			CommonersQuestAvailableQuestsText:Show();
			if ( numActiveQuests > 0 ) then
				CommonersQuestGreetingFrameHorizontalBreak:SetPoint("TOPLEFT", "CommonersQuestTitleButton" .. numActiveQuests, "BOTTOMLEFT",22,-10);
				CommonersQuestGreetingFrameHorizontalBreak:Show();
				CommonersQuestAvailableQuestsText:SetPoint("TOPLEFT", CommonersQuestGreetingFrameHorizontalBreak, "BOTTOMLEFT", -12, -10);
			else
				CommonersQuestAvailableQuestsText:SetPoint("TOPLEFT", CommonersQuestGreetingText, "BOTTOMLEFT", 0, -10);
			end
		end

		local	iOffset = numActiveQuests + numAvailableQuests + numPendingQuests;
		if (iOffset < MAX_NUM_COMMONERSQUESTS) then
			local questTitleButton = getglobal("CommonersQuestTitleButton" .. (iOffset + 1));
			if (numAvailableQuests + numPendingQuests == 0) then
				questTitleButton:SetPoint("TOPLEFT", CommonersQuestAvailableQuestsText, "BOTTOMLEFT", -10, -5);
			else
				questTitleButton:SetPoint("TOPLEFT", "CommonersQuestTitleButton" .. iOffset,"BOTTOMLEFT", 0, -2)
			end
		end
		if (iOffset + numTransferringQuests > MAX_NUM_COMMONERSQUESTS) then
			numTransferringQuests = MAX_NUM_COMMONERSQUESTS - iOffset;
		end
		for i = 1, numTransferringQuests do
			local questTitleButton = getglobal("CommonersQuestTitleButton" .. (iOffset + i));
			local questTitleButtonIcon = getglobal(questTitleButton:GetName() .. "QuestIcon");
			questTitleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, oTransferring[i].QuestID .. " (transferring " .. oTransferring[i].Progress .. "%)");
			questTitleButtonIcon:SetVertexColor(0.5,0.5,0.5);
			questTitleButtonIcon:SetTexture("Interface\\GossipFrame\\gossipGossipIcon");
			questTitleButton:SetHeight(questTitleButton:GetTextHeight() + 2);
			questTitleButton:SetScript("OnClick", nil);

			questTitleButton:Show();
			if ( i > 1 ) then
				questTitleButton:SetPoint("TOPLEFT", "CommonersQuestTitleButton".. (iOffset + i - 1),"BOTTOMLEFT", 0, -2)
			end
		end
	end

	for i = (numActiveQuests + numAvailableQuests + numPendingQuests + numTransferringQuests + 1), MAX_NUM_COMMONERSQUESTS, 1 do
		local questTitleButton = getglobal("CommonersQuestTitleButton"..i);
		questTitleButton:Hide();
		questTitleButton:SetScript("OnClick", nil);
	end

	CommonersQuestFrameGreetingPanel:Show();
	if (not CommonersQuestFrame:IsShown()) then
		FrameShow();
	end
end

function	CommonersQuest.FrameGreetingPanel.QuestActiveButtonClicked(self, button, down)
	if (button == "LeftButton") then
		local	iQuestID, sPlayer = self:GetID(), CommonersQuestFrame.Player;
		CQH.CommChat("DbgSpam", "Quest", "Clicked active ID: " .. iQuestID .. " from " .. sPlayer .. ".");

		local	bCompleted = false;	-- TODO: check (currently done in FrameProgressPanel)
		if (bCompleted) then
			CommonersQuest.FrameRewardPanel.Init(iQuestID);
		else
			CommonersQuest.FrameProgressPanel.Init(iQuestID);
		end
	end
end

function	CommonersQuest.FrameGreetingPanel.QuestAbandonnedButtonClicked(self, button, down)
	if (button == "LeftButton") then
		local	iQuestID, sPlayer, bOk = self:GetID(), CommonersQuestFrame.Player, false;
		CQH.CommChat("DbgSpam", "Quest", "Clicked abandonned ID: " .. iQuestID .. " from " .. sPlayer .. ".");
		if (CQData[sPlayer] and CQData[sPlayer].QuestsCurrent[iQuestID]) then
			local	oQuest = CQData[sPlayer].QuestsCurrent[iQuestID];
			local	sMsg = "?Abandon:" .. iQuestID .. ":" .. oQuest.BindingItem;
			CommonersQuest.QueueAddonMessage("COMMONERSQUEST", sMsg, "WHISPER", sPlayer);
		else
			CQH.CommChat("DbgImportant", "Quest", "Oops! Can't abandon " .. iQuestID .. " from " .. sPlayer .. "??!");
		end
	end
end

function	CommonersQuest.FrameGreetingPanel.QuestAvailableButtonClicked(self, button, down)
	if (button == "LeftButton") then
		local	iQuestID, sPlayer = self:GetID(), CommonersQuestFrame.Player;
		CQH.CommChat("DbgSpam", "Quest", "Clicked available ID: " .. iQuestID .. " from  " .. sPlayer .. ".");
		if (iQuestID and sPlayer and not CommonersQuestFrame.Requesting) then
			CommonersQuestFrame.Requesting = true;
			CQH.CommChat("ChatImportant", "Quest", "Available quest " .. CQH.QuestToPseudoLink(iQuestID, nil, CommonersQuestFrame.Player) .. " clicked. Requesting rewards from " .. sPlayer .. "... Please wait!");
			CommonersQuest.RequestRewards(sPlayer, iQuestID);
		end
	end
end

function	CommonersQuest.FrameDetailPanel.Init(iQuestID)
	local bFail = false;

	local oQuest = CommonersQuest.QuestIs(iQuestID);
	if (oQuest == nil) then
		return
	end

	iQuestID = oQuest.ID;
	local	oRewardOther = oQuest.Reward;
	local	oRewardItems;

	if (CommonersQuestFrame.Player == nil) then
		if (CommonersQuestFrame.EditMode) then
			if (CommonersQuestFrame.RewardSet ~= nil) then
				oRewardItems = CQH.InitRewards(oQuest.ID, CommonersQuestFrame.RewardSet);
			end
			if (oRewardItems == nil) then
				oRewardItems = {};
			end
		else
			bFail = true;
		end
	else
		oRewardItems = CommonersQuestKrbrPrdmrDataPerChar[CommonersQuestFrame.Player].RewardsPromised[iQuestID].Data;
	end

	CommonersQuestFrameRewardPanel:Hide();
	CommonersQuestFrameProgressPanel:Hide();
	CommonersQuestFrameGreetingPanel:Hide();

	if (oQuest.State.Encrypted) then
		CommonersQuestTitleText:SetText(oQuest.ID .. " (encrypted)");

		local	sDescOut, sDescIn = "", oQuest.DescAcqIntro;
		while (sDescIn ~= "") do
			sDescOut = sDescOut .. " " .. strsub(sDescIn, 1, 8);
			sDescIn  = strsub(sDescIn, 9);
		end
		CommonersQuestDescription:SetText(sDescOut);

		local	sDescOut, sDescIn = "", oQuest.DescAcqSmall;
		while (sDescIn ~= "") do
			sDescOut = sDescOut .. " " .. strsub(sDescIn, 1, 8);
			sDescIn  = strsub(sDescIn, 9);
		end
		CommonersQuestObjectiveText:SetText(sDescOut);
	else
		CommonersQuestTitleText:SetText(oQuest.Title);
		CommonersQuestDescription:SetText(oQuest.DescAcqIntro);
		CommonersQuestObjectiveText:SetText(oQuest.DescAcqSmall);
	end

	local	bRewardFail = CQH.SetupRewards("CommonersQuestDetail", oRewardOther, oRewardItems);
	if (bRewardFail) then
		bFail = true;
	end

	if (not bFail) then
		CommonersQuestFrame:SetID(iQuestID);
		CommonersQuestFrameDetailPanel:Show();
		if (not CommonersQuestFrame:IsShown()) then
			FrameShow();
		end
	else
		if ((CommonersQuestFrame.Player == nil) and (CommonersQuestFrame.EditMode == true)) then
			DEFAULT_CHAT_FRAME("[CQ] Failed to show panel...");
		end
		CommonersQuestFrameDetailPanel:Hide();
		FrameHide();
	end
end

function	CommonersQuest.ItemEnter(self)
	if (self:GetAlpha() > 0) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetHyperlink("item:" .. self:GetID() .. ":0:0:0:0:0:0:0")
	end

	CursorUpdate(self);
end

function	CommonersQuest.ItemClicked(self)
	if (not HandleModifiedItemClick("item:" .. self:GetID() .. ":0:0:0:0:0:0:0")) then
		if (self.customdata and (CommonersQuestFrame.EditMode == false) and (CommonersQuestFrame.Player ~= nil)) then
			-- clicked choice-item
			local	sPlayer = CommonersQuestFrame.Player;
			local	iQuest = CommonersQuestFrame:GetID();
			CommonersQuestKrbrPrdmrDataPerChar[sPlayer].QuestsCurrent[iQuest].ChosenRewardCandidate = self:GetID();
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Choice item selected: " .. (self:GetID() or "<nil>"));
			CommonersQuestRewardItemHighlight:SetPoint("TOPLEFT", self, "TOPLEFT", -7, 7);
			CommonersQuestRewardItemHighlight:Show();
			CommonersQuestFrameCompleteQuestButton:Enable();
		end
	end
end

function	CommonersQuest.FrameRewardPanel.Init(iQuestID)
	local bFail = false;

	local oQuest = CommonersQuest.QuestIs(iQuestID);
	if (oQuest == nil) then
		return
	end

	iQuestID = oQuest.ID;

	local	sPlayer, oRewards, CQData = CommonersQuestFrame.Player;
	if (sPlayer) then
		CQData = CommonersQuestKrbrPrdmrDataPerChar;
		if ((CQData[sPlayer] == nil) or (CQData[sPlayer].QuestsCurrent[iQuestID] == nil)) then
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Quest not found for this commoner!");
			return;
		end
		oRewards = CQData[sPlayer].RewardsPromised[iQuestID].Data;
		if (oRewards == nil) then
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Quest rewards not found for this commoner!");
			return;
		end
	elseif (CommonersQuestFrame.EditMode) then
		oRewards = CQH.InitRewards(oQuest.ID, -2);
		if (oRewards == nil) then
			oRewards = {};
		end
	else
		bFail = true;
	end

	CommonersQuestRewardTitleText:SetText(oQuest.Title);
	CommonersQuestRewardText:SetText(oQuest.DescDoneSmall);

	CommonersQuestFrameDetailPanel:Hide();
	CommonersQuestFrameProgressPanel:Hide();
	CommonersQuestFrameGreetingPanel:Hide();

	local	bRewardFail = CQH.SetupRewards("CommonersQuestReward", {}, oRewards);
	if (bRewardFail) then
		bFail = true;
	end

	local	bChoose, k, v = false;
	for k, v in pairs(oRewards) do
		if ((v.Type == "Item") and (v.Choice == true)) then
			bChoose = true;
			break;
		end
	end

	if ((CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.Player == nil)) then
		CommonersQuestFrameCompleteQuestButton:Enable();
	elseif (bChoose) then
		-- must choose an item!
		CommonersQuestFrameCompleteQuestButton:Disable();
	else
		CommonersQuestFrameCompleteQuestButton:Enable();
	end

	if (not bFail) then
		CommonersQuestFrame:SetID(iQuestID);
		CommonersQuestFrameRewardPanel:Show();
		if (not CommonersQuestFrame:IsShown()) then
			FrameShow();
		end
	else
		CommonersQuestFrameRewardPanel:Hide();
		FrameHide();
	end
end

function	CommonersQuest.FrameProgressPanel.Init(iQuestID)
	local bFail = false;

	local oQuest = CommonersQuest.QuestIs(iQuestID);
	if (oQuest == nil) then
		return
	end

	iQuestID = oQuest.ID;

	local	CQData, oQuestState, oFailed, oProgress, oCompleted;
	local	sPlayer = CommonersQuestFrame.Player;
	if (sPlayer and (CommonersQuestFrame.EditMode ~= true)) then
		CQData = CommonersQuestKrbrPrdmrDataPerChar;
		if ((CQData[sPlayer] == nil) or (CQData[sPlayer].QuestsCurrent[iQuestID] == nil)) then
			DEFAULT_CHAT_FRAME:AddMessage("Quest not found for this commoner!");
			return;
		end

		oQuestState = CQData[sPlayer].QuestsCurrent[iQuestID];
		if (oQuestState.Failed) then
			oFailed = oQuestState.Failed;
		else
			oFailed = {};
		end
		if (oQuestState.Progress) then
			oProgress = oQuestState.Progress;
		else
			oProgress = {};
		end
		if (oQuestState.Completed) then
			oCompleted = oQuestState.Completed;
		else
			oCompleted = {};
		end
	elseif ((sPlayer == nil) and (CommonersQuestFrame.EditMode == true)) then
			oQuestState = {};
			oQuestState.BindingItem = "item:6948:0:0:0:0:0:0:0";		-- Hearthstone
			oFailed = {};
			oProgress = {};
			oCompleted = {};
	else
		bFail = true;
	end

	CommonersQuestFrameRewardPanel:Hide();
	CommonersQuestFrameDetailPanel:Hide();
	CommonersQuestFrameGreetingPanel:Hide();

	CommonersQuestProgressTitleText:SetText(oQuest.Title);

	CommonersQuestProgressRequiredMoneyText:Hide();
	CommonersQuestProgressRequiredMoneyFrame:Hide();

	-- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture
	local	bItemCacheFailed = false;
	local	sItemName, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo(oQuestState.BindingItem);
	local	sItemID = string.match(oQuestState.BindingItem, "item:([^:]+)");
	local	iItemID = tonumber(sItemID);
	CommonersQuestProgressItem1:SetID(iItemID);
	if ((CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.Player == nil)) then
		sItemName = "|cFF8080FFBinding item|r";
	elseif (CQH.FindItemInBags(oQuestState.BindingItem) == nil) then
		sItemName = GetItemInfo(iItemID);
		if ((sItemName == nil) and (CommonersQuestProgressItem1.Tried ~= iItemID)) then
			sItemName = "(binding item not in cash!)";
			CommonersQuestProgressItem1.Tried = iItemID;
			bItemCacheFailed = true;
		end
		sItemName = "|cFFFF8080" .. sItemName .. "|r";
	end
	CommonersQuestProgressItem1Name:SetText(sItemName);
	CommonersQuestProgressItem1IconTexture:SetTexture(sItemTexture);
	CommonersQuestProgressItem1:SetScript("OnEnter", CommonersQuest.ItemEnter);
	CommonersQuestProgressItem1:SetScript("OnClick", CommonersQuest.ItemClicked);
	CommonersQuestProgressItem1:Show();

	local	iTotal = 0;
	local	function	fSetButton(oRequire, iProgress)
			-- sDescSmall = sDescSmall .. "Acquired: " .. oRequire.Item .. sCompleted;
			local	sItem = "item:" .. oRequire.ItemID;
			local	sItemName, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo(sItem);
-- DEFAULT_CHAT_FRAME:AddMessage("[CQ] Loot[" .. iTotal .. "]: " .. sItem .. " => " .. sItemName);

			iTotal = iTotal + 1;
			local questRewardButton  = getglobal("CommonersQuestProgressItem" .. (iTotal + 1));
			local questRewardName    = getglobal("CommonersQuestProgressItem" .. (iTotal + 1) .. "Name");
			local questRewardTexture = getglobal("CommonersQuestProgressItem" .. (iTotal + 1) .. "IconTexture");
			local questRewardCount   = getglobal("CommonersQuestProgressItem" .. (iTotal + 1) .. "Count");

			local	iMax = 1;
			if (oRequire.Count and (oRequire.Count > 1)) then
				iMax = oRequire.Count;
			end
			iProgress = math.min(iProgress, iMax);

			questRewardButton:SetID(oRequire.ItemID);
			questRewardName:SetText(sItemName);
			if (iProgress == iMax) then
				questRewardName:SetTextColor(0.5,   1, 0.5);
			else
				questRewardName:SetTextColor(  1, 0.5, 0.5);
			end
			questRewardTexture:SetTexture(sItemTexture);
			questRewardCount:SetText(iProgress .. "/" .. iMax);

			questRewardButton:SetScript("OnEnter", CommonersQuest.ItemEnter);
			questRewardButton:SetScript("OnClick", CommonersQuest.ItemClicked);

			questRewardButton:Show();
		end

	local	bQuestComplete, sDescResult, bGotRiddle = CQH.FormatRequirements(oQuest, oFailed, oProgress, oCompleted, fSetButton, CommonersQuestFrame.EditMode);
	local	sDescSmall = oQuest.DescLogSmall .. "\n" .. sDescResult;
	CommonersQuestProgressText:SetText(sDescSmall);

	for i = (2 + iTotal), 6 do
		local questRewardButton = getglobal("CommonersQuestProgressItem" .. i);
		questRewardButton:Hide();
	end

	-- show riddle solve button
	if (bGotRiddle) then
		CommonersQuestProgressRiddle:Show();

		-- we show the binding item button (currently) always, and iTotal counts from 0
		local questRewardButton = getglobal("CommonersQuestProgressItem" .. ((iTotal + 1) - (iTotal % 2)));
		CommonersQuestProgressRiddle:SetPoint("TOPLEFT", questRewardButton, "BOTTOMLEFT");
	else
		CommonersQuestProgressRiddle:Hide();
	end

	if (CQH.FindItemInBags(oQuestState.BindingItem) == nil) then
		bQuestComplete = false;
	end

	if (bQuestComplete or CommonersQuestFrame.EditMode) then
		CommonersQuestFrameCompleteButton:Enable();
	else
		CommonersQuestFrameCompleteButton:Disable();
	end

	if (not bFail) then
		CommonersQuestFrame:SetID(iQuestID);
		CommonersQuestFrameProgressPanel:Show();
		if (not CommonersQuestFrame:IsShown()) then
			FrameShow();
		end

		if (bItemCacheFailed) then
			-- cheat... once.
			CommonersQuest.Menu.UpdateCurrentFrame();
		end
	else
		CommonersQuestFrameProgressPanel:Hide();
		FrameHide();
	end
end

