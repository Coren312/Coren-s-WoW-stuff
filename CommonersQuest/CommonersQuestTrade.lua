
local	CQData = nil;
local	CQDataX = nil;
local	CQDataGlobal = nil;
local	CQDataItems = nil;

local	CQH = CommonersQuest.Helpers;

CommonersQuest.Trade = {};

local	TradeData = {};
local	TradeAction = {};
local	TradeChecked = {};
local	TradeHistory;

function	CQH.TradeStates()
	DEFAULT_CHAT_FRAME:AddMessage("TradeData => " .. CQH.TableToString(TradeData));
end

function	CommonersQuest.Initializers.Trade(CQDataMain, CQDataXMain, CQDataGlobalMain, CQDataItemsMain)
	CQData = CQDataMain;
	CQDataX = CQDataXMain;
	CQDataGlobal = CQDataGlobalMain;
	CQDataItems = CQDataItemsMain;
end

function	CommonersQuest.Trade.CanTrade()
	local	bTradeOk, iDelay = TradeFrame:IsVisible() == nil, 60;
	if (bTradeOk) then
		if (TradeData.Init and TradeData.At and (time() - TradeData.At < 30)) then
			bTradeOk = false;
			iDelay = 31 - (time() - TradeData.At);
		end
	end

	return bTradeOk, iDelay;
end

function	CommonersQuest.Trade.ActionSet(sWith, sGiver, sQuest, sAction, sReward, sItem)
	TradeAction[sWith] = { QuestID = tonumber(sQuest), Giver = sGiver, Action = sAction, Reward = tonumber(sReward), Item = sItem, At = time() };
end

function	CommonersQuest.Trade.Show(self)
	if (TradeData and TradeData.With and TradeData.At and (TradeData.At ~= 0)) then
		TradeHistory = { Data = TradeData, Action = TradeAction };
	end

	TradeData = {};
	TradeData.With = TradeFrameRecipientNameText:GetText();
	TradeData.SelfIsA = type(self);
	TradeData.Fake = TradeData.SelfIsA == "string";
	if (TradeData.Fake and CQDataX.Debug) then
		CQH.CommChat("DbgInfo", "Trade", "Internal fake trade recognized.");
		TradeData.With = UnitName("player");
	end

	TradeData.At = 0;
	TradeData.In = nil;
	TradeData.Out = nil;
	TradeData.Rewards = nil;

	if (TradeAction[TradeData.With] == nil) then
		TradeData.With = nil;
		CQH.CommChat("ChatInfo", nil, "Not a trade for us...");
		return
	end

	if (time() - TradeAction[TradeData.With].At > 30) then
		TradeData.With = nil;
		CQH.CommChat("ChatInfo", nil, "Trade request too old. Not considering...");
		return
	end

	TradeData.Init = time();
	TradeData.Action = TradeAction[TradeData.With].Action;
	TradeData.Giver = TradeAction[TradeData.With].Giver;
	TradeData.QuestID = TradeAction[TradeData.With].QuestID;

	local	WhoAmI = UnitName("player");

	if (InCombatLockdown()) then
		CQH.CommChat("ChatInfo", nil, "You're in combat! Not touching cursor...");
		return;
	end
	if (CursorHasItem()) then
		CQH.CommChat("ChatInfo", nil, "Cursor already has an item. Not touching...");
		return;
	end

	CQH.CommChat("DbgSpam", "Trade", "TradeData => " .. CQH.TableToString(TradeData));
	local	oGiver = CQDataGlobal.TradeGiverReady;
	if (oGiver and (oGiver.Taker ~= TradeData.With) and (time() - oGiver.At > 60)) then
		oGiver = nil;
	end
	if ((oGiver == nil) and (CQData[TradeData.With] ~= nil)) then
		oGiver = CQData[TradeData.With].TradeGiverReady;
		if (oGiver) then
			if (CQDataGlobal.TradeGiverReady ~= nil) then
				CQH.CommChat("ChatInfo", nil, "Dropping previous request of a trade by " .. CQDataGlobal.TradeGiverReady.Taker .. " in favor of " .. TradeData.With .. " due to age of request.");
			end
			CQDataGlobal.TradeGiverReady = oGiver;
			CQDataGlobal.TradeGiverReady.Taker = TradeData.With;
		end
	end
	if (oGiver) then
		CQH.CommChat("DbgSpam", "Trade", "TradeGiverReady => " .. CQH.TableToString(oGiver));
		if (WhoAmI ~= TradeData.Giver) then
			oGiver = nil;
			CQH.CommChat("DbgSpam", "Trade", "oGiver: Wrong quest giver, not using.");
		elseif (oGiver.QuestID ~= TradeData.QuestID) then
			oGiver = nil;
			CQH.CommChat("DbgSpam", "Trade", "oGiver: Wrong quest id, not using.");
		end
	end
	local	oTaker;
	if (CQData[TradeData.With] ~= nil) then
		oTaker = CQData[TradeData.With].TradeTakerReady;
		if (oTaker) then
			CQH.CommChat("DbgSpam", "Trade", "TradeTakerReady => " .. CQH.TableToString(oTaker));
			if (TradeData.With ~= TradeData.Giver) then
				oTaker = nil;
				CQH.CommChat("DbgSpam", "Trade", "oTaker: Wrong quest giver, not using.");
			elseif (oTaker.QuestID ~= TradeData.QuestID) then
				oTaker = nil;
				CQH.CommChat("DbgSpam", "Trade", "oTaker: Wrong quest id, not using.");
			end
		end
	end

	-- if we have *mutual* quests, then oGiver *and* oTaker might be set!
	-- TODO: if *both* are set, issue a warning, check timestamp and drop older
	if ((oGiver ~= nil) and (oTaker ~= nil)) then
		CQH.CommChat("ChatImportant", "Trade", "Uhuh... open quests in *both* directions and directions seem to have crossed over? IGNORING THIS TRADE.");
		TradeData = {};
		return
	end

	TradeData.Giver = oGiver;
	TradeData.Taker = oTaker;

	-- CQDataGlobal.TradeGiverReady = { Taker = sFrom, Item = sItem, At = time() };
	-- CQData[sFrom].TradeGiverReady = { QuestID = iQuest, Item = sItem, At = time(), Action = sAction, Reward = iReward };
	if ((oGiver ~= nil) and (oGiver.Taker == TradeData.With)) then
		if (TradeData.Action ~= oGiver.Action) then
			CQH.CommChat("ChatImportant", nil, "Action mismatch: " .. TradeData.Action .. " != " .. oGiver.Action .. "!! IGNORING THIS TRADE.");
			TradeData.Init = nil;
			TradeData.With = nil;
			TradeData.Action = nil;
			return
		end

		if (oGiver.Action == "Bind") then
			if (CursorHasItem()) then
				CQH.CommChat("ChatImportant", nil, "Failed to pickup assigned candidate \"binding item\" " .. sItemFull .. " for quest " .. sQuest .. "  requested by player " .. TradeData.With .. ". (Cursor already *holds* an item.)");
			else
				local	iBagFound, iSlotFound, sItemFull = CQH.FindItemInBags(oGiver.Item);
				-- TODO: cross-validate
				if (iBagFound and iSlotFound) then
					-- PickupItem() seems to NOT do what it says, MUST pickup from Bag/Slot directly
					PickupContainerItem(iBagFound, iSlotFound);

					local	sQuest = CQH.QuestToPseudoLink(oGiver.QuestID);
					if (CursorHasItem()) then
						CQH.CommChat("ChatInfo", nil, "Cursor holds now assigned candidate \"binding item\" " .. sItemFull .. " for quest " .. sQuest .. "  requested by player " .. TradeData.With .. ".");
					else
						CQH.CommChat("ChatImportant", nil, "Failed to pickup assigned candidate \"binding item\" " .. sItemFull .. " for quest " .. sQuest .. "  requested by player " .. TradeData.With .. ".");
					end
				else
					CQH.CommChat("ChatImportant", nil, "Didn't find \"binding item\" " .. sItemFull .. " in your bags (for quest " .. sQuest .. "  requested by player " .. TradeData.With .. "). Did you move it into the bank or on a mule maybe?");
				end
			end

			return
		end

		if (oGiver.Action == "Reward") then
			local	oQuest = CQH.CharQuestToObj(nil, oGiver.QuestID);
			if (oQuest) then
				TradeData.Require = oQuest.Requirements;
				TradeData.Rewards = CQData[TradeData.With].RewardsReserved[oGiver.QuestID];
				CQH.CommChat("DbgInfo", "Trade", "Giver: Require/Reward cross-ref'd.");

				local	oStateGlobal = CQH.InitStateGiver(oQuest, true);
				if (oStateGlobal and oStateGlobal.NoBindingItem) then
					local	sQuest = CQH.QuestToPseudoLink(oQuest.ID, oQuest.Title);
					CQH.CommChat("ChatImportant", "Trade", "Quest " .. sQuest .. " without binding item, immediately starting to pickup rewards...");
					TradeData.NoBindingItem = true;
					TradeData.Recheck = GetTime() - 30;
					TradeData.PendingRewards = true;
				end
			else
				CQH.CommChat("DbgImportant", nil, "Oops? Didn't find quest??");
			end
		end
	end

	-- CQData[sFrom].TradeTakerReady = { QuestID = iQuest, Item = sItem, At = time(), Action = "ReceiveBind" };
	-- CQData[sFrom].RewardsPromised[iQuest].Info.BindingItemCandidate = sItem;
	if (oTaker) then
		if (TradeData.Action ~= oTaker.Action) then
			CQH.CommChat("ChatImportant", nil, "Action mismatch: " .. TradeData.Action .. " != " .. oTaker.Action .. "!! IGNORING THIS TRADE.");
			TradeData.Init = nil;
			TradeData.With = nil;
			TradeData.Action = nil;
			return
		end

		if ((oTaker.Action == "Abandon") or (oTaker.Action == "Reward")) then
			local	sQuest = CQH.QuestToPseudoLink(oTaker.QuestID, nil, TradeData.With);
			local	_, sItemFull = GetItemInfo(oTaker.Item);

			-- quest without binding item?
			local	oQuest = CQH.CharQuestToObj(TradeData.With, oTaker.QuestID);
			if (oQuest and oQuest.State and oQuest.State.NoBindingItem) then
				TradeData.NoBindingItem = true;

				local	bItems = false;
				local	iCnt, i = #oQuest.Requirements;
				for i = 1, iCnt do
					if (oQuest.Requirements[i].Type == "Loot") then
						bItems = true;
						break;
					end
				end

				if (bItems) then
					CQH.CommChat("ChatImportant", nil, "Quest without binding item... please insert the required items to complete the quest manually into the trade window.");
				else
					CQH.CommChat("ChatImportant", nil, "Quest without binding item and without required items... please wait for quest giver to fill in the rewards.");
				end

				return
			end

			local	oQuest = CQH.CharQuestToObj(TradeData.With, oTaker.QuestID);
			if (oQuest and oQuest.State and oQuest.State.NoBindingItem) then
				local	bLoots = false;
				local	iCnt, i = #oQuest.Requirements;
				for i = 1, iCnt do
					if (oQuest.Requirements[i].Type == "Loot") then
						bLoots = true;
						break
					end
				end

				if (bLoots) then
					TradeData.Recheck = GetTime() - 30;
					TradeData.PendingRequire = true;
				end
			end

			if (CursorHasItem()) then
				CQH.CommChat("ChatImportant", nil, "Failed to pickup \"binding item\" " .. sItemFull .. " for quest " .. sQuest .. ". (Cursor already *holds* an item.)");
			else
				local	iBagFound, iSlotFound = CQH.FindItemInBags(oTaker.Item);
				if (iBagFound and iSlotFound) then
					-- PickupItem() seems to NOT do what it says, MUST pickup from Bag/Slot directly
					PickupContainerItem(iBagFound, iSlotFound);

					if (CursorHasItem()) then
						if (oTaker.Action == "Abandon") then
							CQH.CommChat("ChatInfo", nil, "Cursor holds now \"binding item\" " .. sItemFull .. " for quest " .. sQuest .. "  to return. (Quest was aborted by you.)");
						elseif (oTaker.Action == "Reward") then
							CQH.CommChat("ChatInfo", nil, "Cursor holds now \"binding item\" " .. sItemFull .. " for quest " .. sQuest .. "  to exchange for the promised quest reward(s).");
						end
					else
							CQH.CommChat("ChatImportant", nil, "Failed to pickup \"binding item\" " .. sItemFull .. " for quest " .. sQuest .. ".");
					end
				else
						CQH.CommChat("ChatImportant", nil, "Didn't find \"binding item\" " .. sItemFull .. " in your bags (for quest " .. sQuest .. "  given by player " .. TradeData.With .. "). Did you move it into the bank or on a mule maybe?");
				end
			end
		end
	end
end

function	CommonersQuest.Trade.PlayerItemChanged(self, ...)
	TradeData.Recheck = GetTime() - 30;

	local	iIndex = ...;
	local	sItemFullLink;
	if (iIndex) then
		sItemFullLink = GetTradePlayerItemLink(iIndex);
	elseif (TradeData.Fake and CQDataX.Debug) then
		DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: Self = " .. self .. ", Event = PlayerItemChanged");

		if (self == "Bind") then
			local	k, v;
			for k, v in pairs(CQDataItems) do
				if ((type(k) == "string") and v.BindingItemCandidate) then
					DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: (Bind) Item = " .. k);
					sItemFullLink = "|H" .. k .. ":99|h";
					break;
				end
			end
		end

		if (self == "Reward") then
			local	k, v;
			for k, v in pairs(CQDataItems) do
				if ((type(k) == "string") and v.BindingItemGiven and (v.Giver == TradeData.With)) then
					DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: (Reward) Item = " .. k);
					sItemFullLink = "|H" .. k .. ":99|h";
					break;
				end
			end
		end
	end

	local	sFrom = TradeData.With;
	if (sFrom and sItemFullLink) then
		local	sItemLink = string.match(sItemFullLink, "|H(item[:%d%-]+)|h");
		if (sItemLink) then
			sItemLink = CQH.StripLevelFromItemLink(sItemLink);
			if (TradeData.Action == "Bind") then
				local	oItem = CQDataItems[sItemLink]; 
				if (oItem and (oItem.Taker == sFrom) and (oItem.Giver == UnitName("player")) and (oItem.BindingItemCandidate ~= nil)) then
					if (CQH.ValidForBinding(sItemLink)) then
						StaticPopupDialogs["COMMONERSQUEST_QUESTGIVER_ITEMTRADE_ISFORQUEST"].cq_itemlink = sItemLink;

						local	sItemName, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo(sItemLink);
						local	oData = { name = sItemName, texture = sItemTexture, link = sItemLink };
						StaticPopup_Show("COMMONERSQUEST_QUESTGIVER_ITEMTRADE_ISFORQUEST", CQH.QuestToPseudoLink(oItem.QuestID), sFrom, oData);

						return
					end
				end
			elseif ((TradeData.Action == "Abandon") and TradeAction[sFrom]) then
				local	iQuestID = TradeAction[sFrom].QuestID;
				local	oQuest = CQData[sFrom].QuestsCurrent[iQuestID];
				if (oQuest and oQuest.Abandonned) then
					local	oIn, iIn, iInCnt = {}, 0;
					local	oOut, iOut, iOutCnt = {}, 0;

					TradeData.Tmp = { Out = {}, In = {} };

					if (TradeData.Fake and CQDataX.Debug) then
						if (sItemFullLink and (self == "Bind")) then
							oIn[1] = string.match(sItemFullLink, "|H(item:[:%d%-]+)|h");
							DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: (Bind) Item = " .. oIn[1]);
							iInCnt = 1;
							iIn = 1;
						end

						if (sItemFullLink and (self == "Reward")) then
							oIn[1] = string.match(sItemFullLink, "|H(item:[:%d%-]+)|h");
							DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: (Reward) Item = " .. oIn[1]);
							iInCnt = 1;
							iIn = 1;
						end
					else
						local	i;
						for i = 1, 6 do
							local	sLink, _1, _2 = GetTradePlayerItemLink(i);
							if (sLink) then
								sLink = string.match(sLink, "|H(item:[:%d%-]+)|h");
								if (sLink) then
									TradeData.Tmp.Out[i] = { Item = sLink };
									_1, _2, TradeData.Tmp.Out[i].Count = GetTradeTargetItemInfo(i);
									iOutCnt = TradeData.Tmp.Out[i].Count;
								end
								iOut = iOut + 1;
							end
							sLink = GetTradeTargetItemLink(i);
							if (sLink) then
								sLink = string.match(sLink, "|H(item:[:%d%-]+)|h");
								if (sLink) then
									TradeData.Tmp.In[i] = { Item = sLink };
									_1, _2, TradeData.Tmp.In[i].Count = GetTradeTargetItemInfo(i);
									iInCnt = TradeData.Tmp.In[i].Count;
								end
								iIn = iIn + 1;
							end
						end

						TradeData.Tmp.Out[0] = GetPlayerTradeMoney();
						TradeData.Tmp.In[0] = GetTargetTradeMoney();
					end

					if ((iIn == 0) and (iOut == 1) and (sItemLink == oQuest.BindingItem)) then
						CQH.CommChat("ChatImportant", nil, "You can ACCEPT the trade now: Trade window holds now the binding item to abandon the associated quest given by " .. sFrom .. ".");
					else
						CQH.CommChat("ChatImportant", nil, "Unrecognized trade... (" .. iIn .. ":" .. iOut .. ")");
					end
				end
			end
		end
	end
end

function	CommonersQuest.Trade.TargetItemChanged(self, ...)
	TradeData.Recheck = GetTime() - 30;

	local	iIndex = ...;
	local	sItemFullLink;
	if (iIndex) then
		sItemFullLink = GetTradeTargetItemLink(iIndex);
	elseif (TradeData.Fake and CQDataX.Debug) then
		DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: Self = " .. self .. ", Event = TargetItemChanged");

		if (self == "Bind") then
			local	k, v;
			for k, v in pairs(CQDataItems) do
				if ((type(k) == "string") and v.BindingItemCandidate) then
					sItemFullLink = "|H" .. k .. ":99|h";
					break;
				end
			end
		end

		if (self == "Reward") then
			local	k, v;
			for k, v in pairs(CQDataItems) do
				if ((type(k) == "string") and v.BindingItemGiven and (v.Giver == TradeData.With)) then
					sItemFullLink = "|H" .. k .. ":99|h";
					break;
				end
			end
		end
	end

	local	oIn, iIn, iInCnt = {}, 0;
	local	oOut, iOut, iOutCnt = {}, 0;

	TradeData.Tmp = { Out = {}, In = {} };

	if (TradeData.Fake and CQDataX.Debug) then
		if (sItemFullLink and (self == "Bind")) then
			oIn[1] = string.match(sItemFullLink, "|H(item:[:%d%-]+)|h");
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: (Bind) Item = " .. oIn[1]);
			iInCnt = 1;
			iIn = 1;
		end

		if (sItemFullLink and (self == "Reward")) then
			oIn[1] = string.match(sItemFullLink, "|H(item:[:%d%-]+)|h");
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: (Reward) Item = " .. oIn[1]);
			iInCnt = 1;
			iIn = 1;
		end
	else
		local	i;
		for i = 1, 6 do
			local	sLink, _1, _2 = GetTradePlayerItemLink(i);
			if (sLink) then
				sLink = string.match(sLink, "|H(item:[:%d%-]+)|h");
				if (sLink) then
					TradeData.Tmp.Out[i] = { Item = sLink };
					_1, _2, TradeData.Tmp.Out[i].Count = GetTradeTargetItemInfo(i);
					iOutCnt = TradeData.Tmp.Out[i].Count;
				end
				iOut = iOut + 1;
			end
			sLink = GetTradeTargetItemLink(i);
			if (sLink) then
				sLink = string.match(sLink, "|H(item:[:%d%-]+)|h");
				if (sLink) then
					TradeData.Tmp.In[i] = { Item = sLink };
					_1, _2, TradeData.Tmp.In[i].Count = GetTradeTargetItemInfo(i);
					iInCnt = TradeData.Tmp.In[i].Count;
				end
				iIn = iIn + 1;
			end
		end

		TradeData.Tmp.Out[0] = GetPlayerTradeMoney();
		TradeData.Tmp.In[0] = GetTargetTradeMoney();
	end

	local	sFrom = TradeData.With;
	if (TradeData.Action == "Abandon") then
		if (sFrom and sItemFullLink and (iIn == 1) and (iInCnt == 1) and (iOut == 0)) then
			local	sItemLink = string.match(sItemFullLink, "|H(item[:%d%-]+)|h");
			if (sItemLink) then
				sItemLink = CQH.StripLevelFromItemLink(sItemLink);
				local	oItem = CQDataItems[sItemLink]; 
				if (oItem and (oItem.Taker == TradeData.With) and (oItem.Giver == UnitName("player")) and (oItem.BindingItemGiven ~= nil)) then
					CQH.CommChat("ChatImportant", nil, "You can ACCEPT the trade now: Trade window holds now the binding item to abandon the associated quest as requested by " .. sFrom .. ".");
				end
			end
		end
	elseif (TradeData.Action == "Reward") then
		local	oGiver = TradeData.Giver;
		local	oTaker = TradeData.Taker;

		if (oGiver and sFrom and sItemFullLink and (iIn == 1) and (iInCnt == 1) and (iOut == 0)) then
			local	sItemLink = string.match(sItemFullLink, "|H(item[:%d%-]+)|h");
			if (sItemLink) then
				sItemLink = CQH.StripLevelFromItemLink(sItemLink);
				local	oItem = CQDataItems[sItemLink]; 
				if (oItem and (oItem.Taker == TradeData.With) and (oItem.Giver == UnitName("player")) and (oItem.BindingItemGiven ~= nil)) then
					local	oGiver = TradeData.Giver;
					if ((oGiver ~= nil) and (oGiver.Taker == TradeData.With)) then
						if ((oGiver.Action == "Reward") and (TradeData.Rewards ~= nil)) then
							TradeData.Recheck = GetTime() - 30;
							TradeData.PendingRewards = true;
						end
					end
				end
			end
		elseif (oTaker and sFrom and (TradeData.NoBindingItem or (iOut > 0))) then
			-- taker side
			local	sPlayer = TradeData.With;
			local	bBindingFound = false;

			local	oIn, iIn = {}, 0;
			local	oOut, iOut = {}, 0;
			if (TradeData.Fake and CQDataX.Debug) then
				-- nothing.
			else
				local	i = false;
				for i = 1, 6 do
					local	sLink;
					if (TradeData.Tmp.Out[i]) then
						sLink = TradeData.Tmp.Out[i].Item;
						sLink = CQH.StripLevelFromItemLink(sLink);
						if (sLink == oTaker.Item) then
							bBindingFound = true;
						end

						local	iItemID = string.match(sLink, "item:(%d+)");
						if (iItemID) then
							iItemID = tonumber(iItemID);
						end
						if (oOut[iItemID] == nil) then
							oOut[iItemID] = { Cnt = 0 };
						end
						oOut[iItemID].Cnt = oOut[iItemID].Cnt + TradeData.Tmp.Out[i].Count;
						iOut = iOut + 1;
					end
					if (TradeData.Tmp.In[i]) then
						sLink = TradeData.Tmp.In[i].Item;
						local	iItemID = string.match(sLink, "item:(%d+)");
						if (iItemID) then
							iItemID = tonumber(iItemID);
						end
						if (oIn[iItemID] == nil) then
							oIn[iItemID] = { Cnt = 0 };
						end
						oIn[iItemID].Cnt = oIn[iItemID].Cnt + TradeData.Tmp.In[i].Count;
						iIn = iIn + 1;
					end
				end

				oIn[0] = { Name = "Money", Cnt = TradeData.Tmp.In[0] };
				oOut[0] = { Name = "Money", Cnt = TradeData.Tmp.Out[0] };
			end

			local	oQuest = CQH.CharQuestToObj(sPlayer, oTaker.QuestID);
			if (oQuest) then
				TradeData.Require = oQuest.Requirements;
				TradeData.Rewards = CQData[sPlayer].RewardsPromised[oTaker.QuestID];
			else
				CQH.CommChat("DbgImportant", nil, "Oops? Didn't find quest??");
			end

			local	sBindingFound;
			if (bBindingFound) then
				sBindingFound = oTaker.Item;
			elseif (TradeData.NoBindingItem) then
				sBindingFound = "(quest requires no binding item)";
			end
			local	bRequireComplete, bRequireTooMuch,
				bRewardComplete, bRewardTooMuch,
				oMissing = CommonersQuest.Trade.CheckStateReward(sBindingFound, oOut, iOut, oIn, iIn, oTaker);

			if (bRequireComplete and bRewardComplete) then
				if (bRequireTooMuch or bRewardTooMuch) then
					CQH.CommChat("ChatImportant", nil, "ADDITIONAL items are in the trade window. This might NOT validate!");
				else
					CQH.CommChat("ChatImportant", nil, "You can ACCEPT the trade now: Trade window holds now all the right items (and nothing more) to complete the associated quest.");
				end
			elseif (bRequireComplete) then
				CQH.CommChat("ChatInfo", nil, "All the necessary items for completion are in the trade window now. Waiting for rewards to materialize...");
			elseif (bRewardComplete) then
				CQH.CommChat("ChatInfo", nil, "All the promised items for completion are in the trade window now. There are required items missing on YOUR end. You'll have to find and add them manually currently. Sorry!");
			end
		end
	end
end

function	CommonersQuest.Trade.AcceptUpdate(self, ...)
	if (TradeData.Fake and CQDataX.Debug) then
		DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: Self = " .. self .. ", Event = AcceptUpdate");

		local	sItem;
		if (self == "Bind") then
			local	k, v;
			for k, v in pairs(CQDataItems) do
				if ((type(k) == "string") and v.BindingItemCandidate) then
					DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: (Bind) Item = " .. k);
					sItem = "|H" .. k .. ":99|h";
					break;
				end
			end

			TradeData.In = {};
			TradeData.Out = {};
			if (sItem) then
				TradeData.Out[1] = { Item = sItem, Count = 1 };
				TradeData.Out[0] = 0;
				TradeData.In[0] = 0;
			end
		end

		if (self == "Reward") then
			local	k, v;
			for k, v in pairs(CQDataItems) do
				if ((type(k) == "string") and v.BindingItemGiven and (v.Taker == TradeData.With)) then
					DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: (Reward) Item = " .. k);
					sItem = "|H" .. k .. ":99|h";
					break;
				end
			end

			TradeData.In = {};
			TradeData.Out = {};
			if (sItem) then
				TradeData.Out[1] = { Item = sItem, Count = 1 };
				TradeData.Out[0] = 0;
				TradeData.In[0] = 0;
			end
		end
	else
		TradeData.In = {};
		TradeData.Out = {};
		local	i;
		for i = 1, 6 do
			local	sLink, _1, _2 = GetTradePlayerItemLink(i);
			if (sLink) then
				TradeData.Out[i] = {};
				TradeData.Out[i].Item = string.match(sLink, "|H(item:[:%d%-]+)|h");
				_1, _2, TradeData.Out[i].Count = GetTradePlayerItemInfo(i);
			end
			sLink = GetTradeTargetItemLink(i);
			if (sLink) then
				TradeData.In[i] = {};
				TradeData.In[i].Item = string.match(sLink, "|H(item:[:%d%-]+)|h");
				_1, _2, TradeData.In[i].Count = GetTradeTargetItemInfo(i);
			end
		end

		TradeData.Out[0] = GetPlayerTradeMoney();
		TradeData.In[0] = GetTargetTradeMoney();
	end
end

function	CommonersQuest.Trade.RequestedCancel(self, ...)
	TradeData = {};
	CQH.CommChat("ChatImportant", nil, "Trade is being cancelled...");
end

function	CommonersQuest.Trade.Closed(self)
	if (TradeData.Fake and CQDataX.Debug) then
		DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: Self = " .. self .. ", Event = Closed");
	end

	TradeData.At = time();
end

function	CommonersQuest.Trade.UpdateState(dRelTimeNow, iTimeAbs)
	if (TradeData.Init and TradeData.At and (TradeData.At == 0) and
	    (TradeData.PendingRequire or TradeData.PendingRewards) and
	    (dRelTimeNow - TradeData.Recheck > 30)) then
		TradeData.Recheck = dRelTimeNow;

		local	bBindingFound = false;
		local	oGiver = TradeData.Giver;
		local	oTaker = TradeData.Taker;

		local	oIn, iIn = {}, 0;
		local	oOut, iOut = {}, 0;
		if (TradeData.Fake and CQDataX.Debug) then
			local	k, v;
			for k, v in pairs(CQDataItems) do
				if ((type(k) == "string") and v.BindingItemGiven and (v.Taker == TradeData.With)) then
					DEFAULT_CHAT_FRAME:AddMessage("[CQ] Fake-Trade: (Reward) Item = " .. k);
					sItem = "|H" .. k .. ":99|h";
					break;
				end
			end

			if (sItem) then
				bBindingFound = true;
			end

			oIn[0] = { Name = "Money", Cnt = 0 };
			oOut[0] = { Name = "Money", Cnt = 0 };
		else
			local	i = false;
			for i = 1, 6 do
				local	sLink = GetTradePlayerItemLink(i);
				if (sLink) then
					if (oTaker) then
						sItem = string.match(sLink, "|H(item:[:%d%-]+)|h");
						if (sItem) then
							sItem = CQH.StripLevelFromItemLink(sItem);
							if (sItem == oTaker.Item) then
								bBindingFound = true;
							end
						end
					end

					local	iItemID = string.match(sLink, "item:(%d+)");
					if (iItemID) then
						iItemID = tonumber(iItemID);
					end
					local	_, _, iCnt = GetTradePlayerItemInfo(i);
					if (oOut[iItemID] == nil) then
						oOut[iItemID] = { Cnt = 0 };
					end
					oOut[iItemID].Cnt = oOut[iItemID].Cnt + iCnt;
					iOut = iOut + 1;
				end
				sLink = GetTradeTargetItemLink(i);
				if (sLink) then
					if (oGiver) then
						sItem = string.match(sLink, "|H(item:[:%d%-]+)|h");
						if (sItem) then
							sItem = CQH.StripLevelFromItemLink(sItem);
							if (sItem == oGiver.Item) then
								bBindingFound = true;
							end
						end
					end

					local	iItemID = string.match(sLink, "item:(%d+)");
					if (iItemID) then
						iItemID = tonumber(iItemID);
					end
					local	_, _, iCnt = GetTradeTargetItemInfo(i);
					if (oIn[iItemID] == nil) then
						oIn[iItemID] = { Cnt = 0 };
					end
					oIn[iItemID].Cnt = oIn[iItemID].Cnt + iCnt;
					iIn = iIn + 1;
				end
			end

			oIn[0] = { Name = "Money", Cnt = tonumber(GetTargetTradeMoney()) };
			oOut[0] = { Name = "Money", Cnt = tonumber(GetPlayerTradeMoney()) };
		end

		local	sBindingFound;
		if (bBindingFound) then
			sBindingFound = oGiver.Item;
		elseif (TradeData.NoBindingItem) then
			sBindingFound = "(quest requires no binding item)";
		end

		local	bRequireComplete, bRequireTooMuch, bRewardComplete, bRewardTooMuch, oMissing;

		if (TradeData.PendingRewards) then
			bRequireComplete, bRequireTooMuch, bRewardComplete, bRewardTooMuch,
				oMissing = CommonersQuest.Trade.CheckStateReward(sBindingFound, oIn, iIn, oOut, iOut, oGiver);
		elseif (TradeData.PendingRequire) then
			bRequireComplete, bRequireTooMuch, bRewardComplete, bRewardTooMuch,
				oMissing = CommonersQuest.Trade.CheckStateReward(sBindingFound, oOut, iOut, oIn, iIn, TradeData.Taker);
		end

		if (bRequireTooMuch) then
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Trade window holds *more* than the required items for quest completion. This exchange might NOT validate!");
		end
		if (bRewardTooMuch) then
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Trade window holds *more* than the money/item(s) promised as reward(s) for quest completion. This exchange might NOT validate!");
		end

		if (bRequireComplete and not bRequireTooMuch and bRewardComplete and not bRewardTooMuch) then
			CQH.CommChat("ChatImportant", nil, "You can ACCEPT the trade now: Trade window holds now all the right items (and nothing more) to complete the associated quest.");
			return
		end

		local	iLines = 1;
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
		GameTooltip:AddLine("CommonersQuest: Rewards trade status");
		local	k, v;
		for k, v in pairs(oMissing) do
			iLines = iLines + 1;
			GameTooltip:AddLine(v);
		end
		GameTooltip:Show();

		CQH.CommChat("DbgSpam", "Trade", "Tooltip has " .. iLines .. " lines.");

		if (InCombatLockdown() or CursorHasItem()) then
			return
		end

		if (TradeData.PendingRequire and not bRequireComplete) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] !RequireComplete, looking for items...");

			local	oRequireItems = TradeData.RequireItems;

			local	iItem, k, v;
			for k, v in pairs(oRequireItems) do
				if ((oOut[k] == nil) or (oOut[k].Cnt < v.Cnt)) then
					iItem = k;
					break
				end
			end

			if (iItem) then
				local	iCount = oRequireItems[iItem].Cnt;
				if (oOut[iItem]) then
					iCount = iCount - oOut[iItem].Cnt;
				end
				local	iBagFound, iSlotFound, sItemFull, bSplit = CQH.CollateNumItemsInBags(iItem, iCount, true);
				if (iBagFound and iSlotFound) then
					-- PickupItem() seems to NOT do what it says, MUST pickup from Bag/Slot directly
					if (bSplit) then
						if (GetContainerNumFreeSlots(0) > 0) then
							local	iSlotTmp, iSlot, _, iCnt;
							for iSlot = 1, 16 do
								_, iCnt = GetContainerItemInfo(0, iSlot);
								if (iCnt == nil) then
									iSlotTmp = iSlot;
									break
								end
							end

							if (iSlotTmp) then
								SplitContainerItem(iBagFound, iSlotFound, iCount);
								PickupContainerItem(0, iSlotTmp);
								DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Item(s) of larger stack was/were split into backpack slot " .. iSlotTmp .. ". Will pickup next round... (Stack is locked by UI, must wait a few seconds.)");
								TradeData.Recheck = dRelTimeNow - 25;
								return
							end
						else
							DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Need more space in backpack to split stacks of items... :-(");
						end
					else
						PickupContainerItem(iBagFound, iSlotFound);
					end
					if (CursorHasItem()) then
						DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Cursor holds now required item(s) " .. sItemFull .. ".");
					else
						DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Failed to pickup required item(s) " .. sItemFull .. ".");
					end
				end
			end
		elseif (TradeData.PendingRewards and not bRewardComplete) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] !RewardComplete, looking for items...");

			-- pile up rewards on cursor until all is in trade window
			local	oRewardItems = TradeData.RewardItems;

			local	iItem, k, v;
			for k, v in pairs(oRewardItems) do
				if ((oOut[k] == nil) or (oOut[k].Cnt < v.Cnt)) then
					iItem = k;
					break
				end
			end

			if (iItem) then
				local	iCount = oRewardItems[iItem].Cnt;
				if (oOut[iItem]) then
					iCount = iCount - oOut[iItem].Cnt;
				end
				local	iBagFound, iSlotFound, sItemFull, bSplit = CQH.CollateNumItemsInBags(iItem, iCount, true);
				if (iBagFound and iSlotFound) then
					-- PickupItem() seems to NOT do what it says, MUST pickup from Bag/Slot directly
					if (bSplit) then
						if (GetContainerNumFreeSlots(0) > 0) then
							local	iSlotTmp, iSlot, _, iCnt;
							for iSlot = 1, 16 do
								_, iCnt = GetContainerItemInfo(0, iSlot);
								if (iCnt == nil) then
									iSlotTmp = iSlot;
									break
								end
							end

							if (iSlotTmp) then
								SplitContainerItem(iBagFound, iSlotFound, iCount);
								PickupContainerItem(0, iSlotTmp);
								DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Item(s) of larger stack was/were split into backpack slot " .. iSlotTmp .. ". Will pickup next round... (Stack is locked by UI, must wait a few seconds.)");
								TradeData.Recheck = dRelTimeNow - 25;
								return
							end
						else
							DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Need more space in backpack to split stacks of items... :-(");
						end
					else
						PickupContainerItem(iBagFound, iSlotFound);
					end
					if (CursorHasItem()) then
						DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Cursor holds now promised reward item(s) " .. sItemFull .. ".");
					else
						DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Failed to pickup promised reward item(s) " .. sItemFull .. ".");
					end
				end
			else
				local	k, v;
				for k, v in pairs(TradeData.Rewards.Data) do
					if (v.Type == "Money") then
						if (v.Amount ~= GetPlayerTradeMoney()) then
							PickupPlayerMoney(v.Amount);
							if (CursorHasItem()) then
								DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Cursor holds now promised amount of money...");
							else
								DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Failed to pickup promised amount of money...");
							end
						end
						break;
					end
				end
			end
		end
	end

	if ((TradeHistory == nil) and TradeData.Init and TradeData.At and (iTimeAbs - TradeData.At <= 5)) then
		if ((TradeData.Warn == nil) or (dRelTimeNow - TradeData.Warn > 2)) then
			TradeData.Warn = dRelTimeNow;
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Trade with " .. TradeData.With .. " completed (or aborted). Please do *not* start another trade yet...");
		end
	end

	local	TradeData = TradeData;
	local	TradeAction = TradeAction;
	if (TradeHistory ~= nil) then
		if (TradeHistory.Data.Init and TradeHistory.Data.With and TradeHistory.Data.At and TradeHistory.Data.Action and
		    (iTimeAbs - TradeHistory.Data.At < 30) and
		    (iTimeAbs - TradeHistory.Data.At > 5)) then
			if (TradeChecked[TradeHistory.Data.At] == nil) then
				TradeData = TradeHistory.Data;
				TradeAction = TradeHistory.Action;
				TradeHistory = nil;
				DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: You DID start a new trade sooner than requested. :-( Hopefully the previous trade STILL does check out! Recovering data...");
			else
				TradeHistory = nil;
			end
		elseif (TradeHistory.Data.At and (iTimeAbs - TradeHistory.Data.At > 30)) then
			TradeHistory = nil;
		end
	end

	if (TradeData.Init and TradeData.With and TradeData.At and TradeData.Action and
	    (iTimeAbs - TradeData.At < 30) and
	    (iTimeAbs - TradeData.At > 5)) then
		if (TradeChecked[TradeData.At] ~= nil) then
			return
		end
		TradeChecked[TradeData.At] = time();
		TradeData.At = nil;

		local	bRecognizedAction = false;
		local	sPlayer = TradeData.With;
		DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: A trade with " .. sPlayer .. " was completed. Trying to validate result sets... Action was <" .. TradeData.Action .. ">");

		if ((TradeData.Action == "Bind") or (TradeData.Action == "Abandon")) then
			local	iOut, iIn, sItem, i = 0, 0;
			for i = 1, 6 do
				if (TradeData.Out[i]) then
					if (TradeData.Out[i].Count == 1) then
						sItem = TradeData.Out[i].Item;
					end
					iOut = iOut + 1;
				end
				if (TradeData.In[i]) then
					if (TradeData.In[i].Count == 1) then
						sItem = TradeData.In[i].Item;
					end
					iIn = iIn + 1;
				end
			end

			if (sItem) then
				sItem = CQH.StripLevelFromItemLink(sItem);
			end

			local	oItem;
			if (sItem and (iIn + iOut == 1)) then
				oItem = CQData[sPlayer].ItemAccepted[sItem];
			end

			do
				local	_1 = sItem or "<nil>";
				local	_2 = type(oItem);
				CQH.CommChat("DbgSpam", "Trade", "Item = " .. _1 .. " => " .. _2 .. ", iIn = " .. iIn .. ", iOut = " .. iOut);
				if (_2 == "table") then
					CQH.CommChat("DbgSpam", "Trade", "oItem => " .. CQH.TableToString(oItem));
				end
			end

			if (TradeData.Action == "Abandon") then
				if (sItem and (iIn == 1) and (iOut == 0)) then
					-- giver receiving: abandon
					local	oGiver = TradeData.Giver;
					CQDataGlobal.TradeGiverReady = nil;
					if (oGiver and (oGiver.Item == sItem) and (oGiver.Action == TradeData.Action)) then
						bRecognizedAction = true;

						local	iQuestID = oGiver.QuestID;
						sQuest = CQH.QuestToPseudoLink(iQuestID);

						local	WhoAmI = UnitName("player");

						CQData[sPlayer].QuestsGiven[iQuestID] = nil;
						CQDataItems[sItem] = nil;
						local	oRewards = CQData[sPlayer].RewardsReserved[iQuestID];
						local	oItems = CQDataItems;
						if (oRewards) then
							if (oRewards.Data) then
								local	sOops, k, v = "";
								for k, v in pairs(oRewards.Data) do
									if (v.Type == "Item") then
										local	iCount = v.Count or 1;
										if (oItems[v.ItemID] and oItems[v.ItemID].Count[WhoAmI]) then
											oItems[v.ItemID].Count[WhoAmI] = oItems[v.ItemID].Count[WhoAmI] - iCount;
											oItems[v.ItemID].Count["Total#"] = oItems[v.ItemID].Count["Total#"] - iCount;
										else
											local	_, sLink = GetItemInfo(v.ItemID);
											sOops = sOops .. " " .. iCount .. " " .. sLink .. ", ";
										end
									end
								end

								if (sOops ~= "") then
									CQH.CommChat("DbgImportant", nil, "Oops! Failed to account item(s) properly! =>" .. sOops .. " this will screw up availability checks. :-(");
								end
							end

							CQData[sPlayer].RewardsReserved[iQuestID] = nil;
						end

						CQH.CommChat("ChatImportant", nil, "Quest " .. sQuest .. " once accepted by " .. sPlayer .. " is now abandonned, reserved rewards reclaimed, \"binding item\" " .. sItem .. " free for re-use.");
					end
				end
				if (sItem and (iIn == 0) and (iOut == 1)) then
					-- - taker to giver, abandon
					local	oTaker = TradeData.Taker;
					CQData[sPlayer].TradeTakerReady = nil;
					if (oTaker and (oTaker.Item == sItem) and (oTaker.Action == TradeData.Action)) then
						bRecognizedAction = true;

						local	iQuestID = oTaker.QuestID;
						sQuest = CQH.QuestToPseudoLink(iQuestID, nil, sPlayer);
						CQDataItems[sItem] = nil;
						CQData[sPlayer].QuestsCurrent[iQuestID] = nil;
						CQData[sPlayer].RewardsPromised[iQuestID] = nil;
						CQH.CommChat("ChatImportant", nil, "Quest " .. sQuest .. " is now abandonned.");
					end
				end
			end

			if ((TradeData.Action == "Bind") and oItem and oItem.Give and oItem.Take and
				    (oItem.Give.Q == oItem.Take.Q) and (oItem.Give.Giver == oItem.Take.Giver) and
				    (oItem.Give.At >= TradeData.Init) and (oItem.Take.At >= TradeData.Init)) then
				local	oContainer, sQuest;
				if (sItem and (iIn == 1) and (iOut == 0)) then
					-- - taker receiving: binding
					local	oTaker = TradeData.Taker;
					CQData[sPlayer].TradeTakerReady = nil;
					CQH.CommChat("DbgInfo", "Trade", "Bind/Taker's view (1): " .. CQH.TableToString(oTaker));
					if (oTaker and (oTaker.Item == sItem) and (oTaker.Action == TradeData.Action)) then
						-- AcceptedToTake = { Link = sLink, QuestID = iQuest };
						local	oTake = CQData[sPlayer].AcceptedToTake;
						CQH.CommChat("DbgInfo", "Trade", "Bind/Taker's view (2): " .. CQH.TableToString(oTake));
						if ((oTake.Link == sItem) and (oTake.QuestID == oTaker.QuestID)) then
							local	iQuestID = oTake.QuestID;
							CQH.InitTable(CQData[sPlayer].QuestsCurrent, iQuestID);
							oContainer = CQData[sPlayer].QuestsCurrent[iQuestID];
							CQData[sPlayer].QuestsAcknowledgedToTake[iQuestID] = nil;

							sQuest = CQH.QuestToPseudoLink(iQuestID, nil, sPlayer);
							CQH.CommChat("DbgInfo", "Trade", "Bind/Taker's view: OK'ed.");
						end
					end
				end

				if (sItem and (iIn == 0) and (iOut == 1)) then
					-- - giver giving: binding
					local	oGiver = TradeData.Giver;
					CQDataGlobal.TradeGiverReady = nil;
					CQData[TradeData.With].TradeGiverReady = nil;
					CQH.CommChat("DbgInfo", "Trade", "Bind/Giver's view (1): " .. CQH.TableToString(oGiver));
					if (oGiver and (oGiver.Item == sItem) and (oGiver.Action == TradeData.Action)) then
						-- WillingToGive = { Link = sLink, QuestID = iQuest };
						local	oGive = CQData[sPlayer].WillingToGive;
						CQH.CommChat("DbgInfo", "Trade", "Bind/Giver's view (2): " .. CQH.TableToString(oGive));
						if ((oGive.Link == sItem) and (oGive.QuestID == oGiver.QuestID)) then
							local	iQuestID = oGive.QuestID;
							CQDataItems[sItem].BindingItemCandidate = nil;
							CQDataItems[sItem].BindingItemGiven = sItem;
							CQData[sPlayer].RewardsReserved[iQuestID].BindingItemCandidate = nil;
							CQData[sPlayer].RewardsReserved[iQuestID].BindingItemGiven = sItem;

							CQH.InitTable(CQData[sPlayer].QuestsGiven, iQuestID);
							oContainer = CQData[sPlayer].QuestsGiven[iQuestID];
							CQData[sPlayer].QuestsRequestedToGive[iQuestID] = nil;

							sQuest = CQH.QuestToPseudoLink(iQuestID);
							CQH.CommChat("DbgInfo", "Trade", "Bind/Giver's view: OK'ed.");
						end
					end
				end

				if (oContainer) then
					bRecognizedAction = true;

					if (oContainer.BindingItem ~= nil) then
						local	_, sItemLink = GetItemInfo(oContainer.BindingItem);
						DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Oops? Quest " .. sQuest .. " was already accepted and bound to " .. sItemLink .. ".");
					end

					local	_, sItemLink = GetItemInfo(sItem);
					oContainer.BindingItem = sItem;
					oContainer.BindingAt = time();
					oContainer.BindingCompleted = 3;

					CommonersQuestTracking.Update();

					DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Quest " .. sQuest .. " is now fully accepted. Binding item agreed upon is " .. sItemLink .. ".");

					if (TradeData.Fake and CQDataX.Debug) then
					else
						TradeData = table.wipe(TradeData);
						CQData[sPlayer].WillingToGive = nil;
						CQData[sPlayer].AcceptedToTake = nil;
						CQData[sPlayer].ItemAccepted[sItem] = nil;
					end
				else
					DEFAULT_CHAT_FRAME:AddMessage("[CQ] Binding item was not recognized/accepted by at least one player.");
				end
			end
		end

		if (TradeData.Action == "Reward") then
			-- reward exchange
			-- multiple items on both sides:
			-- - taker, giver, binding item, require, reward
			if (TradeData.PendingRewards) then
				-- giver side
				local	bBindingFound = false;
				local	oGiver = TradeData.Giver;

				local	oIn, iIn = {}, 0;
				local	oOut, iOut = {}, 0;
				if (TradeData.Fake and CQDataX.Debug) then
					-- nothing.
				else
					local	i = false;
					for i = 1, 6 do
						local	sLink;
						if (TradeData.Out[i]) then
							sLink = TradeData.Out[i].Item;
							local	iItemID = string.match(sLink, "item:(%d+)");
							if (iItemID) then
								iItemID = tonumber(iItemID);
							end
							if (oOut[iItemID] == nil) then
								oOut[iItemID] = { Cnt = 0 };
							end
							oOut[iItemID].Cnt = oOut[iItemID].Cnt + TradeData.Out[i].Count;
							iOut = iOut + 1;
						end
						if (TradeData.In[i]) then
							sLink = TradeData.In[i].Item;
							sLink = CQH.StripLevelFromItemLink(sLink);
							if (sLink == oGiver.Item) then
								bBindingFound = true;
							end

							local	iItemID = string.match(sLink, "item:(%d+)");
							if (iItemID) then
								iItemID = tonumber(iItemID);
							end
							if (oIn[iItemID] == nil) then
								oIn[iItemID] = { Cnt = 0 };
							end
							oIn[iItemID].Cnt = oIn[iItemID].Cnt + TradeData.In[i].Count;
							iIn = iIn + 1;
						end
					end

					oIn[0] = { Name = "Money", Cnt = TradeData.In[0] };
					oOut[0] = { Name = "Money", Cnt = TradeData.Out[0] };
				end

				local	sBindingFound;
				if (bBindingFound) then
					sBindingFound = oGiver.Item;
				elseif (TradeData.NoBindingItem) then
					sBindingFound = "(quest requires no binding item)";
				end
				local	bRequireComplete, bRequireTooMuch,
					bRewardComplete, bRewardTooMuch,
					oMissing = CommonersQuest.Trade.CheckStateReward(sBindingFound, oIn, iIn, oOut, iOut, oGiver);
				if (bRequireComplete and bRewardComplete) then
					bRecognizedAction = true;

					local	WhoAmI = UnitName("player");
					local	oEntry = { Giver = WhoAmI, Taker = sPlayer, QuestID = oGiver.QuestID, Started = 0, Completed = time() };
					tinsert(CQData[sPlayer].QuestsCompleted, oEntry);
					DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Your Quest " .. CQH.QuestToPseudoLink(oGiver.QuestID) .. " was fully completed by " .. sPlayer .. " with this trade exchange, cleaning up...");

					oEntry.Started = CQData[sPlayer].QuestsGiven[oGiver.QuestID].BindingAt;

					-- update tally of promised rewards
					local	k, v;
					for k, v in pairs(CQData[sPlayer].RewardsReserved[oGiver.QuestID].Data) do
						if (v.Type == "Item") then
							local	iCount = v.Count or 1;
							CQDataItems[v.ItemID].Count[WhoAmI] = CQDataItems[v.ItemID].Count[WhoAmI] - iCount;
							CQDataItems[v.ItemID].Count["Total#"] = CQDataItems[v.ItemID].Count["Total#"] - iCount;
						end
					end
					CQData[sPlayer].RewardsReserved[oGiver.QuestID] = nil;

					-- update binding item & quest
					CQDataItems[oGiver.Item] = nil;
					CQData[sPlayer].QuestsRequestedToGive[oGiver.QuestID] = nil;
					CQData[sPlayer].QuestsGiven[oGiver.QuestID] = nil;
				else
					DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Your Quest " .. CQH.QuestToPseudoLink(oGiver.QuestID) .. " was NOT completed by " .. sPlayer .. " with this trade exchange. IGNORING trade.");
				end
			else
				-- taker side
				local	bBindingFound = false;
				local	oTaker = TradeData.Taker;


				local	oIn, iIn = {}, 0;
				local	oOut, iOut = {}, 0;
				if (TradeData.Fake and CQDataX.Debug) then
					-- nothing.
				else
					local	i = false;
					for i = 1, 6 do
						local	sLink;
						if (TradeData.Out[i]) then
							sLink = TradeData.Out[i].Item;
							sLink = CQH.StripLevelFromItemLink(sLink);
							if (sLink == oTaker.Item) then
								bBindingFound = true;
							end

							local	iItemID = string.match(sLink, "item:(%d+)");
							if (iItemID) then
								iItemID = tonumber(iItemID);
							end
							if (oOut[iItemID] == nil) then
								oOut[iItemID] = { Cnt = 0 };
							end
							oOut[iItemID].Cnt = oOut[iItemID].Cnt + TradeData.Out[i].Count;
							iOut = iOut + 1;
						end
						local	sLink;
						if (TradeData.In[i]) then
							sLink = TradeData.In[i].Item;
							local	iItemID = string.match(sLink, "item:(%d+)");
							if (iItemID) then
								iItemID = tonumber(iItemID);
							end
							if (oIn[iItemID] == nil) then
								oIn[iItemID] = { Cnt = 0 };
							end
							oIn[iItemID].Cnt = oIn[iItemID].Cnt + TradeData.In[i].Count;
							iIn = iIn + 1;
						end
					end

					oIn[0] = { Name = "Money", Cnt = TradeData.In[0] };
					oOut[0] = { Name = "Money", Cnt = TradeData.Out[0] };
				end

				local	oQuest = CQH.CharQuestToObj(sPlayer, oTaker.QuestID);
				if (oQuest) then
					TradeData.Require = oQuest.Requirements;
					TradeData.Rewards = CQData[sPlayer].RewardsPromised[oTaker.QuestID];
				else
					CQH.CommChat("DbgImportant", nil, "Oops? Didn't find quest??");
				end

				local	sBindingFound;
				if (bBindingFound) then
					sBindingFound = oTaker.Item;
				elseif (TradeData.NoBindingItem) then
					sBindingFound = "(quest requires no binding item)";
				end
				local	bRequireComplete, bRequireTooMuch,
					bRewardComplete, bRewardTooMuch,
					oMissing = CommonersQuest.Trade.CheckStateReward(sBindingFound, oOut, iOut, oIn, iIn, oTaker);

				if (bRequireComplete and bRewardComplete) then
					bRecognizedAction = true;

					local	WhoAmI = UnitName("player");
					local	oEntry = { Giver = sPlayer, Taker = WhoAmI, QuestID = oTaker.QuestID, Started = 0, Completed = time() };
					tinsert(CQData[sPlayer].QuestsCompleted, oEntry);
					DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Your quest " .. CQH.QuestToPseudoLink(oTaker.QuestID, nil, sPlayer) .. " given by " .. sPlayer .. " is now fully completed, cleaning up...");

					oEntry.Started = CQData[sPlayer].QuestsCurrent[oTaker.QuestID].BindingAt;

					-- nil-ify data
					CQDataItems[oTaker.Item] = nil;
					CQData[sPlayer].QuestsCurrent[oTaker.QuestID] = nil;
					CQData[sPlayer].RewardsPromised[oTaker.QuestID] = nil;
					CQData[sPlayer].QuestsAcknowledgedToTake[oTaker.QuestID] = nil;
				else
					DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Your quest " .. CQH.QuestToPseudoLink(oTaker.QuestID, nil, sPlayer) .. " given by " .. sPlayer .. " was NOT completed with this trade exchange. IGNORING trade.");
				end
			end
		end

		if (not bRecognizedAction) then
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Ignoring trade result, unknown exchange variant.");
		end

		if (TradeData.Fake and CQDataX.Debug) then
			if (TradeData.Action == "Bind") then
				if (TradeData.Out[1] ~= nil) then
					TradeData.In[1] = TradeData.Out[1];
					TradeData.Out[1] = nil;
					TradeData.At = time();
				else
					local	sItem = TradeData.In[1].Item;
					TradeData = table.wipe(TradeData);
					CQData[sPlayer].AcceptedToTake = nil;
					CQData[sPlayer].WillingToGive = nil;
					CQData[sPlayer].ItemAccepted[sItem] = nil;

					if (CQDataGlobal.TradeGiverReady and (CQDataGlobal.TradeGiverReady.Taker == sPlayer)) then
						CQDataGlobal.TradeGiverReady = nil;
					end
				end
			end
		else
			if (CQDataGlobal.TradeGiverReady and (CQDataGlobal.TradeGiverReady.Taker == sPlayer)) then
				CQDataGlobal.TradeGiverReady = nil;
			end
		end
	end
end

function	CommonersQuest.Trade.CheckStateReward(sBindingFound, oIn, iIn, oOut, iOut, oRole)
	local	sPlayer = TradeData.With;
	local	sItem = oRole.Item;
	local	oMissing = {};

	local	iBindingID;
	if (sBindingFound == nil) then
		tinsert(oMissing, "Requirements: Binding item.");
	else
		iBindingID = string.match(sBindingFound, "item:(%d+)");
		if (iBindingID) then
			iBindingID = tonumber(iBindingID);
		end
	end

	CQH.CommChat("DbgSpam", "Trade", "sBindingFound => " .. (sBindingFound or "<nil>") .. ", ID = " .. (iBindingID or "<nil>") .. " (" .. type(iBindingID) .. ")");
	CQH.CommChat("DbgSpam", "Trade", "oIn => " .. CQH.TableToString(oIn));

	-- check for requirements:
	local	bRequireComplete, bRequireTooMuch = (sBindingFound ~= nil), false;
	local	k, v;
	for k, v in pairs(TradeData.Require) do
		if (v.Type == "Loot") then
			local	iReq = 1;
			if (v.Count) then
				iReq = v.Count;
			end
			if (oIn[v.ItemID].Cnt < iReq) then
				bRequireComplete = false;
				tinsert(oMissing, "Requirements: Item " .. v.ItemID .. ", current = " .. oIn[v.ItemID].Cnt .. ", required = " .. iReq);
			elseif (oIn[v.ItemID].Cnt > iReq) then
				bRequireTooMuch = true;
				tinsert(oMissing, "Requirements: Item " .. v.ItemID .. ", current = " .. oIn[v.ItemID].Cnt .. ", required = " .. iReq);
			end
		end
	end

	for k, v in pairs(oIn) do
		if ((k ~= 0) and (v.Req == nil)) then
			if (k ~= iBindingID) then
				bRequireTooMuch = true;
				CQH.CommChat("DbgSpam", "Trade", "Require/Extra: " .. k .. " (" .. type(k) .. ") != " .. iBindingID .. " (" .. type(iBindingID) .. ")");
				tinsert(oMissing, "Requirements: Item " .. k .. ", current = " .. v.Cnt .. ", required = 0!");
			end
		end
	end

	local	bRewardComplete, bRewardTooMuch;
	if (not bRequireComplete) then
		CQH.CommChat("DbgSpam", "Trade", "Check: Require (_)");

		local	oRequireItems = TradeData.RequireItems;
		if (oRequireItems == nil) then
			oRequireItems = {};
			oRequireItems[0] = { Name = "Money", Cnt = 0 };

			local	iCnt, i = #TradeData.Require;
			for i = 1, iCnt do
				local	v = TradeData.Require[i];
				if (v.Type == "Money") then
					oRequireItems[0].Cnt = v.Amount;
				elseif (v.Type == "Loot") then
					local	iItemID = v.ItemID;
					CQH.InitTable(oRequireItems, iItemID);
					if (oRequireItems[iItemID].Cnt == nil) then
						oRequireItems[iItemID].Cnt = 0;
						oRequireItems[iItemID].Name = v.ItemName;
					end
					oRequireItems[iItemID].Cnt = oRequireItems[iItemID].Cnt + (v.Count or 1);
				end
			end
			TradeData.RequireItems = oRequireItems;
		end
	else
		CQH.CommChat("DbgSpam", "Trade", "Check: Require (x)");

		local	oRewardItems = TradeData.RewardItems;
		if (oRewardItems == nil) then
			oRewardItems = {};
			oRewardItems[0] = { Name = "Money", Cnt = 0 };

			local	k, v;
			for k, v in pairs(TradeData.Rewards.Data) do
				if (v.Type == "Money") then
					oRewardItems[0].Cnt = v.Amount;
				elseif ((v.Type == "Item") and ((v.Choice ~= true) or (v.ItemID == oRole.Reward))) then
					local	iItemID = v.ItemID;
					CQH.InitTable(oRewardItems, iItemID);
					if (oRewardItems[iItemID].Cnt == nil) then
						oRewardItems[iItemID].Cnt = 0;
						oRewardItems[iItemID].Name = v.ItemName;
					end
					oRewardItems[iItemID].Cnt = oRewardItems[iItemID].Cnt + (v.Count or 1);
				end
			end
			TradeData.RewardItems = oRewardItems;
		end

		CQH.CommChat("DbgSpam", "Trade", "oRewardItems => " .. CQH.TableToString(oRewardItems));
		CQH.CommChat("DbgSpam", "Trade", "oOut => " .. CQH.TableToString(oOut));

		bRewardComplete = true;
		bRewardTooMuch = false;
		local	k, v;
		for k, v in pairs(oRewardItems) do
			local	iCntCurr = -1;
			if (oOut[k] ~= nil) then
				oOut[k].Req = v.Cnt;
				iCntCurr = oOut[k].Cnt;
			end

			bRewardComplete = bRewardComplete and iCntCurr >= v.Cnt
			bRewardTooMuch = bRewardTooMuch or (iCntCurr > v.Cnt);
			if (iCntCurr ~= v.Cnt) then
				tinsert(oMissing, v.Name .. " [" .. k .. "]: Trading = " .. iCntCurr .. ", Promised = " .. v.Cnt);
			end
		end

		for k, v in pairs(oOut) do
			if ((k ~= 0) and (v.Req == nil)) then
				bRewardTooMuch = true;
				tinsert(oMissing, "Extra [" .. k .. "]: Trading = " .. v.Cnt .. ", Promised = 0");
			end
		end

		-- check money
		local	iAmount = 0;
		if (oRewardItems[0].Amount) then
			iAmount = oRewardItems[0].Amount;
		end
		bRewardTooMuch = bRewardTooMuch or oOut[0].Cnt > iAmount;
		bRewardComplete = bRewardComplete and oOut[0].Cnt >= iAmount;
		if (oOut[0].Cnt ~= iAmount) then
			tinsert(oMissing, "Money: Trading = " .. oOut[0].Cnt .. ", Promised = " .. iAmount);
		end
	end

	return		bRequireComplete, bRequireTooMuch,
			bRewardComplete, bRewardTooMuch,
			oMissing;
end


