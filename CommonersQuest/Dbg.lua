--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local	oFunctions = {
	"CommonersQuest.Initializers.Base",
	"CommonersQuest.Helpers.Encode",
	"CommonersQuest.Helpers.Decode",
	"CommonersQuest.Helpers.MoneyToString",
	"CommonersQuest.Helpers.TableToString",
	"CommonersQuest.Helpers.AllToString",
	"CommonersQuest.Helpers.TableIsEmpty",
	"CommonersQuest.Helpers.InitTable",
	"CommonersQuest.Helpers.CopyTable",
	"CommonersQuest.Helpers.StripLevelFromItemLink",
	"CommonersQuest.Helpers.ValidForBinding",
	"CommonersQuest.Helpers.CharQuestToObj",
	"CommonersQuest.Helpers.QuestToPseudoLink",
	"CommonersQuest.Helpers.FindItemInBags",
	"CommonersQuest.Helpers.CountItemInBags",
	"CommonersQuest.Helpers.CollateNumItemsInBags",
	"CommonersQuest.Helpers.IsValidTarget",
	"CommonersQuest.Helpers.RequirementToTextBasic",
	"CommonersQuest.Helpers.RequirementToTextForEdit",
	"CommonersQuest.Helpers.RequirementToText",
	"CommonersQuest.Helpers.FormatRequirements",
	"CommonersQuest.Helpers.InitRewardContainer",
	"CommonersQuest.Helpers.InitRewards",
	"CommonersQuest.Helpers.CollateRewards",
	"CommonersQuest.Helpers.SetupRewards",
	"CommonersQuest.Helpers.RewardCheckLock",
	"CommonersQuest.Helpers.InitStateGiver",
	"CommonersQuest.Helpers.CheckInventoryForRewardAvailability",
	"CommonersQuest.Helpers.CanDoQuest",
	"CommonersQuest.Helpers.CommChat",
	"CommonersQuest.Slider.Init",
	"CommonersQuest.Slider.Reset",
	"CommonersQuest.Slider.MappedValueToValue",
	"CommonersQuest.Slider.OnValueChanged",
	"CommonersQuest.Slider.OnOk",
	"CommonersQuest.Initializers.Comm",
	"CommonersQuest.HandleCommunication",
	"CommonersQuest.Initializers.QPanels",
	"CommonersQuest.FrameMain.OnLoad",
	"CommonersQuest.FrameMain.OnEvent",
	"CommonersQuest.FrameMain.OnShow",
	"CommonersQuest.FrameMain.OnHide",
	"CommonersQuest.FrameRewardPanel.OnShow",
	"CommonersQuest.FrameRewardPanel.RewardItemRaiseFrameLevel",
	"CommonersQuest.FrameRewardPanel.RewardCancelButtonClicked",
	"CommonersQuest.FrameRewardPanel.RewardCompleteButtonClicked",
	"CommonersQuest.FrameRewardPanel.MoneyFrame_OnLoad",
	"CommonersQuest.FrameProgressPanel.OnShow",
	"CommonersQuest.FrameProgressPanel.GoodbyeButtonClicked",
	"CommonersQuest.FrameProgressPanel.ProgressCompleteButtonClicked",
	"CommonersQuest.FrameDetailPanel.OnShow",
	"CommonersQuest.FrameDetailPanel.OnUpdate",
	"CommonersQuest.FrameDetailPanel.DetailDeclineButtonClicked",
	"CommonersQuest.FrameDetailPanel.DetailAcceptButtonClicked",
	"CommonersQuest.FrameMoney.OnLoad",
	"CommonersQuest.FrameGreetingPanel.OnShow",
	"CommonersQuest.FrameProgressPanel.RiddleSolve",
	"CommonersQuest.Menu.FindItemByName",
	"CommonersQuest.Menu.UpdateCurrentFrame",
	"CommonersQuest.Menu.StackSplitCallback.SplitStack",
	"CommonersQuest.Menu.ItemCount.Slider",
	"CommonersQuest.Menu.ClickedItem",
	"CommonersQuest.Menu.ClickedItemDo",
	"CommonersQuest.Menu.ClickedEmote",
	"CommonersQuest.Menu.ClickedEmoteDo",
	"CommonersQuest.Menu.ClickedKill",
	"CommonersQuest.Menu.ClickedKillDo",
	"CommonersQuest.Menu.ClickedSurvive",
	"CommonersQuest.Menu.ClickedSurviveDo",
	"CommonersQuest.Menu.ClickedDuel",
	"CommonersQuest.Menu.ClickedDuelDo",
	"CommonersQuest.Menu.ClickedMoney",
	"CommonersQuest.Menu.RiddleEdit",
	"CommonersQuest.Menu.SliderRiddleLockout",
	"CommonersQuest.Menu.ClickedRiddle",
	"CommonersQuest.Menu.ClickedRewardsetDelete",
	"CommonersQuest.Menu.Initialize",
	"CommonersQuest.QuestEdit.InitMenu",
	"CommonersQuest.QuestEdit.InitMenuIndirect",
	"CommonersQuest.FrameGreetingPanel.Init",
	"CommonersQuest.FrameGreetingPanel.QuestActiveButtonClicked",
	"CommonersQuest.FrameGreetingPanel.QuestAbandonnedButtonClicked",
	"CommonersQuest.FrameGreetingPanel.QuestAvailableButtonClicked",
	"CommonersQuest.FrameDetailPanel.Init",
	"CommonersQuest.ItemEnter",
	"CommonersQuest.ItemClicked",
	"CommonersQuest.FrameRewardPanel.Init",
	"CommonersQuest.FrameProgressPanel.Init",
	"CommonersQuest.Initializers.QLog",
	"CommonersQuest.Log.QuestListScrollFrame_OnLoad",
	"CommonersQuest.Log.DetailFrame_AttachToQuestLog",
	"CommonersQuest.Log.DetailFrame_DetachFromQuestLog",
	"CommonersQuest.Log.FrameDetail_OnLoad",
	"CommonersQuest.Log.FrameDetail_OnShow",
	"CommonersQuest.Log.FrameDetail_OnHide",
	"CommonersQuest.Log.TitleButton_OnLoad",
	"CommonersQuest.Log.TitleButton_OnEvent",
	"CommonersQuest.Log.TitleButton_OnClick",
	"CommonersQuest.Log.TitleButton_OnEnter",
	"CommonersQuest.Log.TitleButton_OnLeave",
	"CommonersQuest.Log.FrameMain_OnLoad",
	"CommonersQuest.Log.FrameMain_OnShow",
	"CommonersQuest.Log.FrameMain_OnHide",
	"CommonersQuest.Log.AbandonDialog_OnAccept",
	"CommonersQuest.Log.AbandonDialog_OnCancel",
	"CommonersQuest.Log.AbandonBtnClicked",
	"CommonersQuest.Log.PushCommonersQuest",
	"CommonersQuest.Log.MoneyFrame_OnLoad",
	"CommonersQuest.Log.DailyCountButton_OnEnter",
	"CommonersQuest.Log.CollapseAllButton_OnClick",
	"CommonersQuest.Log.RiddleSolve",
	"CommonersQuest.Log.FrameMain.Update",
	"CommonersQuest.Log.FrameQuest.SetAsLastShown",
	"CommonersQuest.Log.FrameQuest.Init",
	"CommonersQuest.Log.Init",
	"CommonersQuestLogControlPanel_UpdatePosition",
	"CommonersQuestLogControlPanel_UpdateState",
	"CommonersQuestLogShowMapPOI_UpdatePosition",
	"CommonersQuest.OnLoad",
	"CommonersQuest.OnEvent",
	"CommonersQuest.OnUpdateEvent",
	"CommonersQuest.Toggle",
	"CommonersQuest.DumpMsgQ",
	"CommonersQuest.QueueAddonMessage",
	"CommonersQuest.LDBTooltipHide",
	"CommonersQuest.LDBTooltipShow",
	"CommonersQuest.LDBAction",
	"CommonersQuest.SecureHooks.GameTooltip_SetBagItem",
	"CommonersQuest.EventChatMsgYell",
	"CommonersQuest.SecureHooks.ShowUIPanel",
	"CommonersQuest.PlayerInit",
	"CommonersQuest.TargetInitiateQuery",
	"CommonersQuest.QuestIs",
	"CommonersQuest.QuestRequested",
	"CommonersQuest.TradeAccept",
	"CommonersQuest.TradeDeny",
	"CommonersQuest.GreetingPanelReopen",
	"CommonersQuest.GreetingPanel",
	"CommonersQuest.ValidateQuest",
	"CommonersQuest.QuestEdit.InitEdit",
	"CommonersQuest.QuestEdit.QuestAddNew",
	"CommonersQuest.QuestEdit.MoneyRewardInit",
	"CommonersQuest.QuestEdit.MoneyRewardSet",
	"CommonersQuest.QuestEdit.PopupTableFieldSet",
	"CommonersQuest.QuestEdit.PopupTableFieldInit",
	"CommonersQuest.QuestEdit.PopupFieldInit",
	"CommonersQuest.QuestEdit.PopupFieldSet",
	"CommonersQuest.QuestEdit.InputInit",
	"CommonersQuest.QuestEdit.InputCheck",
	"CommonersQuest.QuestEdit.InputSet",
	"CommonersQuest.FetchTitles",
	"CommonersQuest.RequestRewards",
	"CommonersQuest.LDBMenu.QuestActionClicked",
	"CommonersQuest.LDBMenu.RewardSetEdit",
	"CommonersQuest.LDBMenu.RewardSetAddNew",
	"CommonersQuest.LDBMenu.BindingItemAssign",
	"CommonersQuest.LDBMenu.BindingItemUnassign",
	"CommonersQuest.LDBMenu.Initialize",
	"CommonersQuest.LDBMenu.InitializeIndirect",
	"CommonersQuest.LDBMenu.LevelRange.SplitStack",
	"CommonersQuest.LDBMenu.LevelRange.Slider",
	"CommonersQuest.LDBMenu.LevelRange.Set",
	"CommonersQuest.LDBMenu.PreReqLevel",
	"CommonersQuest.LDBMenu.PreReqRepeat",
	"CommonersQuest.LDBMenu.PreReqFaction",
	"CommonersQuest.LDBMenu.PreReqClass",
	"CommonersQuest.LDBMenu.PreReqRace",
	"CommonersQuest.LDBMenu.PreReqSex",
	"CommonersQuest.LDBMenu.PreReqQuest",
	"CommonersQuest.SlashCmdsInit",
	"CommonersQuest.SlashCmdHandler",
	"CommonersQuest.SlashCmdHelp",
	"CommonersQuest.SlashCmdNew",
	"CommonersQuest.SlashCmdTest",
	"CommonersQuest.Initializers.Main",
	"CommonersQuest.Main.OnLoad",
	"CommonersQuest.Main.OnShow",
	"CommonersQuest.Main.Refresh",
	"CommonersQuest.Main.OnEvent",
	"CommonersQuest.Main.QuestClicked",
	"CommonersQuest.Main.QuestEditMenu_Initialize",
	"CommonersQuest.Main.PrereqMenu_Initialize",
	"CommonersQuest.Main.PrereqClicked",
	"CommonersQuest.Main.RequiredClicked",
	"CommonersQuest.Main.RewardsetClicked",
	"CommonersQuest.Main.CheckOnShow",
	"CommonersQuest.Main.CheckOnClick",
	"CommonersQuest.Main.SetupTip",
	"CommonersQuest.Initializers.Rewards",
	"CommonersQuest.Reward.OnLoad",
	"CommonersQuest.Reward.OnShow",
	"CommonersQuest.Reward.OnEvent",
	"CommonersQuest.Reward.OnUpdateEvent",
	"CommonersQuest.Reward.QuestClicked",
	"CommonersQuest.Reward.RewardsetClear",
	"CommonersQuest.Reward.RewardsetClicked",
	"CommonersQuest.Initializers.Tracking",
	"CommonersQuestTracking.Update",
	"CommonersQuestTracking.OnEvent",
	"CQDebug",
	"CQH.TradeStates",
	"CommonersQuest.Initializers.Trade",
	"CommonersQuest.Trade.CanTrade",
	"CommonersQuest.Trade.ActionSet",
	"CommonersQuest.Trade.Show",
	"CommonersQuest.Trade.PlayerItemChanged",
	"CommonersQuest.Trade.TargetItemChanged",
	"CommonersQuest.Trade.AcceptUpdate",
	"CommonersQuest.Trade.RequestedCancel",
	"CommonersQuest.Trade.Closed",
	"CommonersQuest.Trade.UpdateState",
	"CommonersQuest.Trade.CheckStateReward",
};

function	WheresTheLoadFrom()
	local	function	ExtractFunction(oOuter, sInner, sInnerOrg)
			if (oOuter == nil) then
				DEFAULT_CHAT_FRAME:AddMessage("Failed for " .. sInnerOrg .. ". :-(");
				return nil;
			end

			local	iPos = strfind(sInner, "%.");
			if (iPos) then
				local	s1 = strsub(sInner, 1, iPos - 1);
				local	s2 = strsub(sInner, iPos + 1);
				DEFAULT_CHAT_FRAME:AddMessage(".: recursing with oOuter[" .. s1 .. "], " .. s2);
				return ExtractFunction(oOuter[s1], s2, sInnerOrg);
			else
				return oOuter[sInner];
			end
		end

	local	iN = 10;
	local	oHighestN = {};
	for k, v in pairs(oFunctions) do
		local	x = _G[v];
		if (strfind(v, "%.")) then
			x = ExtractFunction(_G, v, v);
		end

		if (type(x) == "function") then
			local	dCPU, iCalls = GetFunctionCPUUsage(x, true);
			local	dCPUPure = GetFunctionCPUUsage(x, false);
			if (#oHighestN < iN) then
				tinsert(oHighestN, { func = x, Name = v, CPU = dCPU, Calls = iCalls, CPUPure = dCPUPure });
			else
				local	dLowest, iLowest, i = oHighestN[1].CPU, 1;
				for i = 2, iN do
					if (oHighestN[i].CPU < dLowest) then
						dLowest = oHighestN[i].CPU;
						iLowest = i;
					end
				end

				if (dCPU > dLowest) then
					oHighestN[iLowest].func = x;
					oHighestN[iLowest].Name = v;
					oHighestN[iLowest].CPU = dCPU;
					oHighestN[iLowest].CPUPure = dCPUPure;
					oHighestN[iLowest].Calls = iCalls;
				end
			end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("=> CPU usage <=");

	local	i;
	for i = 1, #oHighestN do
		DEFAULT_CHAT_FRAME:AddMessage(oHighestN[i].Name .. ": [" .. oHighestN[i].Calls .. "] => " .. oHighestN[i].CPU .. " ~= " .. (oHighestN[i].CPU / oHighestN[i].Calls) .. " -- " .. oHighestN[i].CPUPure);
	end

	DEFAULT_CHAT_FRAME:AddMessage("=><=");
end

