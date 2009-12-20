
local	CQData = nil;
local	CQDataX = nil;
local	CQDataGlobal = nil;
local	CQDataItems = nil;

local	CQH = CommonersQuest.Helpers;

CommonersQuest.LDBMenu = {};

local	Module = {
			-- update/second
			Update = {
					At = 0,
					Sum = 0,
				},

			-- messages queued to send
			MessageSent = 0,
			Messages = {
				},
		};

function	CommonersQuest.OnLoad()
	CommonersQuest.Version[""].Version = GetAddOnMetadata("CommonersQuest", "Version");
	if (CommonersQuest.Version[""].Version == nil) then
		CommonersQuest.Version[""].Version = "???";
	end
	CommonersQuest.Version[""].Date = GetAddOnMetadata("CommonersQuest", "X-Date");
	if (CommonersQuest.Version[""].Date == nil) then
		CommonersQuest.Version[""].Date = "???";
	end

	CommonersQuestEventframe:RegisterEvent("ADDON_LOADED");
end

function	CommonersQuest.OnEvent(self, event, ...)
	local	arg1 = ...;
	if (event == "ADDON_LOADED") and (arg1 == "CommonersQuest") then
		CommonersQuestEventframe:UnregisterEvent("ADDON_LOADED");

		if (type(CommonersQuestKrbrPrdmrDataPerChar) ~= "table") then
			CommonersQuestKrbrPrdmrDataPerChar = {};
		end
		CQData = CommonersQuestKrbrPrdmrDataPerChar;

		if (type(CommonersQuestKrbrPrdmrOtherPerChar) ~= "table") then
			CommonersQuestKrbrPrdmrOtherPerChar = {};
		end
		CQDataX = CommonersQuestKrbrPrdmrOtherPerChar;
		CQH.InitTable(CQDataX, "Giver");
		CQH.InitTable(CQDataX.Giver, "QuestStates");		-- init

		if (type(CommonersQuestKrbrPrdmrOther) ~= "table") then
			CommonersQuestKrbrPrdmrOther = {};
		end
		CQDataGlobal = CommonersQuestKrbrPrdmrOther;

		local	sServer = GetCVar("realmname");
		local	sFaction = UnitFactionGroup("player");
		CQH.InitTable(CQDataGlobal, sServer .. "#" .. sFaction);

		-- Items need to be per-server/faction
		CQDataItems = CQDataGlobal[sServer .. "#" .. sFaction].Items;
		if (type(CQDataItems) ~= "table") then
			if (type(CQDataGlobal.Items) == "table") then
				CQDataItems = CQDataGlobal.Items;
				CQDataGlobal.Items = nil;
				DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Moved item table to per-server structure.");
			else
				CQDataItems = {};
			end
			CQDataGlobal[sServer .. "#" .. sFaction].Items = CQDataItems;
		end

		local	sModule, fFunc;
		for sModule, fFunc in pairs(CommonersQuest.Initializers) do
			fFunc(CQData, CQDataX, CQDataGlobal, CQDataItems);
		end

		-- new layout
		CQH.InitTable(CQDataGlobal, "Giver");
		CQH.InitTable(CQDataGlobal.Giver, "QuestStates");	-- init

		CQH.InitTable(CQDataGlobal, "CustomQuests");
		CQH.InitTable(CQDataGlobal, "Rewards");
		if (CQDataGlobal.Giver.CustomQuestsNextID == nil) then
			CQDataGlobal.Giver.CustomQuestsNextID = 1000001;
		end

		local	k, v;
		for k, v in pairs(CQDataGlobal.CustomQuests) do
			if (CommonersQuest.ValidateQuest(v.ID, false, -2)) then
				tinsert(CommonersQuest.QuestDB, v);
			end
		end

		if (CQDataX.QuestKey1 == nil) then
			CQDataX.QuestKey1 = time();
		end
		if (CQDataX.QuestKey2 == nil) then
			CQDataX.QuestKey2 = math.random();
		end

		local	k, v;
		for k, v in pairs(CommonersQuest.StaticPopups) do
			StaticPopupDialogs[k] = v;
		end

		-- /yell CQH: Quest <ID> can be decrypted with key <key>.
		ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", CommonersQuest.EventChatMsgYell);

		CommonersQuest.SlashCmdsInit();

		CommonersQuestEventframe:RegisterEvent("CHAT_MSG_ADDON");

		CommonersQuestEventframe:RegisterEvent("TRADE_SHOW");
		CommonersQuestEventframe:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED");
		CommonersQuestEventframe:RegisterEvent("TRADE_TARGET_ITEM_CHANGED");
		CommonersQuestEventframe:RegisterEvent("TRADE_ACCEPT_UPDATE");
		CommonersQuestEventframe:RegisterEvent("TRADE_REQUEST_CANCEL");
		CommonersQuestEventframe:RegisterEvent("TRADE_CLOSED");

		local	oData = {
				type = "launcher",
				label = "CQ",
				icon = "Interface\\GossipFrame\\ActiveQuestIcon",
				OnClick = function(clickedframe, mousebtn)
						CommonersQuest.LDBAction(clickedframe, mousebtn);
					end,
				OnEnter = function(oFrame)
						CommonersQuest.LDBTooltipShow(oFrame);
					end,
				OnLeave = function()
						CommonersQuest.LDBTooltipHide();
					end,
			};
		local ldb = LibStub:GetLibrary("LibDataBroker-1.1");
		ldb:NewDataObject("CommonersQuest", oData);

		hooksecurefunc(GameTooltip, "SetBagItem", CommonersQuest.SecureHooks.GameTooltip_SetBagItem);
		hooksecurefunc("ShowUIPanel", CommonersQuest.SecureHooks.ShowUIPanel);

		CommonersQuestTracking.Update();
	elseif (event == "CHAT_MSG_ADDON") then
		CommonersQuest.HandleCommunication(...);
	elseif (event == "TRADE_SHOW") then
		CommonersQuest.Trade.Show(self);
	elseif (event == "TRADE_PLAYER_ITEM_CHANGED") then
		CommonersQuest.Trade.PlayerItemChanged(self, ...);
	elseif (event == "TRADE_TARGET_ITEM_CHANGED") then
		CommonersQuest.Trade.TargetItemChanged(self, ...);
	elseif (event == "TRADE_ACCEPT_UPDATE") then
		CommonersQuest.Trade.AcceptUpdate(self, ...);
	elseif (event == "TRADE_REQUEST_CANCEL") then
		CommonersQuest.Trade.RequestedCancel(self, ...);
	elseif (event == "TRADE_CLOSED") then
		CommonersQuest.Trade.Closed(self);
	end
end

function	CommonersQuest.OnUpdateEvent(iElapsed)
	Module.Update.Sum = Module.Update.Sum + iElapsed;
	if (Module.Update.Sum < 0.5) then
		return
	end

	if (InCombatLockdown()) then
		return
	end

	Module.Update.Sum = 0;
	Module.Update.AtRel = GetTime();
	Module.Update.AtAbs = time();

	CommonersQuest.Trade.UpdateState(Module.Update.AtRel, Module.Update.AtAbs);

	if ((#Module.Messages > 0) and (Module.Update.AtRel - Module.MessageSent > 1)) then
		local	oMsg = Module.Messages[1];

		local	oNext, iCnt, i = {}, #Module.Messages;
		for i = 2, iCnt do
			oNext[i - 1] = Module.Messages[i];
		end
		Module.Messages = oNext;

		CQH.CommChat("DbgSpam", "Comm", "Sending => " .. oMsg.Target .. ": " .. oMsg.Msg .. " -- " .. (iCnt - 1) .. " pending.");
		SendAddonMessage("COMMONERSQUEST", oMsg.Msg, "WHISPER", oMsg.Target);
		Module.MessageSent = Module.Update.AtRel + (strlen(oMsg.Msg) + 30) / 50;
	end
end

function	CommonersQuest.Toggle(oFrame, iWindow)
	if (iWindow == 1) then
		if (CommonersQuestMainframe:IsShown()) then
			CommonersQuestMainframe:Hide();
		else
			CommonersQuestMainframe:Show();
		end
	elseif (iWindow == 2) then
		if (CommonersQuestLogFrame:IsShown()) then
			CommonersQuestLogFrame:Hide();
		else
			CommonersQuest.Log.Init();
		end
	end
end

function	CommonersQuest.DumpMsgQ(Context)
	local	sAll, iCnt, i = "", #Module.Messages;
	for i = 1, iCnt do
		sAll = sAll .. ", [" .. i .. "] = <" .. strsub(Module.Messages[i].Msg, 1, 8) .. "...>";
	end
	local	iNext = math.floor(math.max(0, Module.MessageSent + 1 - Module.Update.AtRel) * 10 + 0.5) / 10;
	CQH.CommChat("DbgSpam", "Comm", "{" .. Context .. "} in " .. iNext .. " seconds: " .. strsub(sAll, 2));
end

function	CommonersQuest.QueueAddonMessage(ID, Msg, Channel, Target)
	local	iCnt, i = #Module.Messages;

	CQH.CommChat("DbgSpam", "Comm", "#" .. (iCnt + 1) .. " => " .. Target .. ": " .. Msg);

	for i = 1, iCnt do
		if ((Module.Messages[1].Msg == Msg) and (Module.Messages[1].Msg == Target)) then
DEFAULT_CHAT_FRAME:AddMessage("[CQ] Skipping #" .. (iCnt + 1) .. " => " .. Target .. ": " .. Msg);
			return
		end
	end

	if (strsub(Msg, 1, 1) == "!") then
		local	oNext, iInsert = {};
		for i = 1, iCnt do
			if (iInsert) then
				oNext[i + 1] = Module.Messages[i];
			elseif (strsub(Module.Messages[i].Msg, 1, 1) ~= "!") then
				iInsert = i;
				oNext[i + 1] = Module.Messages[i];
			else
				oNext[i] = Module.Messages[i];
			end
		end
		if (iInsert == nil) then
			iInsert = iCnt + 1;
		end
		oNext[iInsert] = { Msg = Msg, Target = Target };
		Module.Messages = oNext;
		CQH.CommChat("DbgSpam", "Comm", "iInsert = " .. iInsert);
	else
		Module.Messages[iCnt + 1] = { Msg = Msg, Target = Target };
	end
end

function	CommonersQuest.LDBTooltipHide()
	GameTooltip:Hide();

	CommonersQuest.LDBTooltipFrame = nil;
	CommonersQuest.LDBTooltipIsMine = false;
end

function	CommonersQuest.LDBTooltipShow(oFrame)
	CommonersQuest.LDBTooltipFrame = oFrame;
	CommonersQuest.LDBTooltipIsMine = true;

	GameTooltip:SetOwner(oFrame, "ANCHOR_TOPLEFT");
	GameTooltip:AddLine("CommonersQuest by Kärbär@EU-Proudmoore", 1, 1, 1);

	if (CQH.IsValidTarget()) then
		local	sPlayer, sServer = UnitName("target");
		if ((sServer ~= nil) and (sServer ~= "")) then
			GameTooltip:AddLine(sPlayer .. " is from another server: " .. sServer, 0.8, 0.8, 0.8);
		elseif (CommonersQuest.Version[sPlayer] and CommonersQuest.Version[sPlayer].Valid) then
			GameTooltip:AddLine(sPlayer .. " might have some quests to offer!", 0.4, 1, 0.4);
			GameTooltip:AddLine(" ");

			if (CQData[sPlayer]) then
				if (not CommonersQuest.PlayerInit(sPlayer, UnitGUID("target"))) then
					CQH.CommChat("ChatImportant", nil, "Player <" .. sPlayer.. "> is a *different* character than we expected. (Unique identifier does not match!)");
					return
				end

				if (CQData[sPlayer].QuestsList and CQData[sPlayer].QuestsList.Request) then
					if (CQData[sPlayer].QuestsList.Status ~= 7) then
						local	iProgress, iStatus = 0, CQData[sPlayer].QuestsList.Status;
						if (bit.band(iStatus, 1) == 1) then
							iProgress = iProgress + 33;
						end
						if (bit.band(iStatus, 2) == 2) then
							iProgress = iProgress + 33;
						end
						if (bit.band(iStatus, 4) == 4) then
							iProgress = iProgress + 33;
						end

						GameTooltip:AddLine("Currently retrieving quest information... " .. iProgress .. "% (since " .. date("%H:%M:%S", CQData[sPlayer].QuestsList.Request) .. ")", 0.4, 1, 0.4);
					end
				end

				local	iQuestID, iAt;
				for iQuestID, iAt in pairs(CQData[sPlayer].QuestsRequestedToGive) do
					local	sQuest, sName = CQH.QuestToPseudoLink(iQuestID);
					if (sName) then
						if ((CQData[sPlayer].QuestsGiven[iQuestID] == nil) or
						    (CQData[sPlayer].QuestsGiven[iQuestID].BindingItem == nil)) then
							GameTooltip:AddLine(sPlayer .. " is waiting for an item to bind the quest " .. sQuest .. ".", 0.8, 1, 0.4);
						elseif ((CQData[sPlayer].QuestsGiven[iQuestID].BindingItem ~= nil) and
							(CQData[sPlayer].QuestsGiven[iQuestID].BindingCompleted ~= 3)) then
							local	_, sItem = GetItemInfo(CQData[sPlayer].QuestsGiven[iQuestID].BindingItem);
							local	sWhen = date("%Y/%m%d %H:%M", CQData[sPlayer].QuestsGiven[iQuestID].BindingAt);
							GameTooltip:AddLine(sPlayer .. " is in the process of accepting the quest " .. sQuest .. " being bound to item " .. sItem .. " - " .. sWhen, 0.4, 1, 0.4);
						end
					end
				end
				for iQuestID, iAt in pairs(CQData[sPlayer].QuestsAcknowledgedToTake) do
					local	sQuest, sName = CQH.QuestToPseudoLink(iQuestID);
					if (sName) then
						if ((CQData[sPlayer].QuestsCurrent[iQuestID] == nil) or
						    (CQData[sPlayer].QuestsCurrent[iQuestID].BindingItem == nil)) then
							GameTooltip:AddLine("You're waiting for an item from " .. sPlayer .. " to bind the quest " .. sQuest .. ".", 0.8, 1, 0.4);
						elseif ((CQData[sPlayer].QuestsCurrent[iQuestID].BindingItem ~= nil) and
							(CQData[sPlayer].QuestsCurrent[iQuestID].BindingCompleted ~= 3)) then
							local	_, sItem = GetItemInfo(CQData[sPlayer].QuestsCurrent[iQuestID].BindingItem);
							local	sWhen = date("%Y/%m%d %H:%M", CQData[sPlayer].QuestsCurrent[iQuestID].BindingAt);
							GameTooltip:AddLine("You're in the process of accepting the quest " .. sQuest .. " from " .. sPlayer .. " being bound to item " .. sItem .. " - " .. sWhen, 0.4, 1, 0.4);
						end
					end
				end

				local	bOnce, k, v = true;
				for k, v in pairs(CQData[sPlayer].QuestsGiven) do
					if (bOnce) then
						GameTooltip:AddLine(sPlayer .. ": Quests they (want to) do for you", 1, 1, 1);
						bOnce = false;
					end

					local	oQuest, l, w;
					for l, w in pairs(CommonersQuest.QuestDB) do
						if (w.ID == k) then
							oQuest = w;
							break;
						end
					end
					local	oStateGlobal, oStatePerChar = CQH.InitStateGiver(oQuest, true);

					local	sQuest, sTitle;
					if (oQuest) then
						sTitle = oQuest.Title;
					end
					sQuest, sTitle = CQH.QuestToPseudoLink(k, sTitle);
					if ((oStatePerChar == nil) or (oStatePerChar.Enabled ~= true)) then
						sQuest = CQH.QuestToPseudoLink(k, sTitle .. " (disabled)");
					end

					local	sWhen = "";
					if (v.BindingAt) then
						sWhen = date(" since %Y/%m/%d %H:%M", v.BindingAt);
					end
					local	sBound, sItem = "", "<NONE!!>";
					if (v.BindingItem) then
						local	_;
						_, sItem = GetItemInfo(v.BindingItem);
					end
					if (oStateGlobal.NoBindingItem) then
						sBound = " (no binding item req.)";
					else
						sBound = " bound to item " .. sItem;
					end

					if (v.BindingCompleted ~= 3) then
						if (sTitle) then
							GameTooltip:AddLine("Requested: " .. sQuest .. sBound .. sWhen, 0.5, 1, 0);
						else
							GameTooltip:AddLine("Requested: <unknown quest?>" .. sBound .. sWhen .. "!", 0, 0.5, 1);
						end
					else
						if (sTitle) then
							GameTooltip:AddLine("In progress: " .. sQuest .. sBound .. sWhen, 0, 1, 0);
						else
							GameTooltip:AddLine("In progress: <unknown quest?>" .. sBound .. sWhen .. "!", 1, 0, 1);
						end
					end
				end

				if (not bOnce) then
					GameTooltip:AddLine(" ");
				end

				bOnce = true;
				for k, v in pairs(CQData[sPlayer].QuestsCurrent) do
					if (bOnce) then
						GameTooltip:AddLine(sPlayer .. ": Quests you (want to) do for them", 1, 1, 1);
						bOnce = false;
					end

					local	sWhen = "";
					if (v.BindingAt) then
						sWhen = date(" since %Y/%m/%d %H:%M", v.BindingAt);
					end
					local	sBound = "";
					local	_, sItem = GetItemInfo(v.BindingItem);
					if (sItem) then
						sBound = " bound to item " .. sItem;
					end
 					if (v.BindingCompleted ~= 3) then
						local	sQuest, sName = CQH.QuestToPseudoLink(k, nil, sPlayer);
						if (sName) then
							GameTooltip:AddLine("Requested: " .. sQuest .. sBound .. sWhen, 0.5, 1, 0);
						else
							GameTooltip:AddLine("Requested: <unknown quest?>" .. sBound .. sWhen .. "!", 0, 0.5, 1);
						end
					elseif (v.State and v.State.Dirty) then
						local	sQuest, sName = CQH.QuestToPseudoLink(k, nil, sPlayer);
						if (sName) then
							GameTooltip:AddLine("Lost? : " .. sQuest .. sBound .. sWhen, 0, 1, 0);
						else
							GameTooltip:AddLine("Lost? : <unknown quest?>" .. sBound .. sWhen .. "!", 1, 0, 1);
						end
						GameTooltip:AddLine(sPlayer .. " |cFFFF4040changed|r this quest! You'll have to re-negotiate with them.", 1, 0, 0);
					end
				end
			end
		else
			CQH.InitTable(CommonersQuest.Version, sPlayer);
			if  (CommonersQuest.Version[sPlayer].CheckReq == nil) then
				GameTooltip:AddLine(sPlayer .. ": Checking... (this might not update until you re-enter the \"!\" area)", 0.6, 0.7, 1);
				CommonersQuest.Version[sPlayer].CheckReq = time();
				CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?Ver:" .. CommonersQuest.Version[""].Version .. ":" .. CommonersQuest.Version[""].Date, "WHISPER", sPlayer);
			elseif (time() - CommonersQuest.Version[sPlayer].CheckReq < 10) then
				GameTooltip:AddLine(sPlayer .. ": Still waiting for reply... (this might not update until you re-enter the \"!\" area)", 0.6, 0.7, 1);
			else
				GameTooltip:AddLine(sPlayer .. ": No reply. Player most likely hasn't got CommonersQuest.", 1, 1, 0);
			end
		end
	elseif (UnitName("target") ~= nil) then
		GameTooltip:AddLine(UnitName("target") .. ": Not a valid target.", 0.8, 0.8, 0.8);
	else
		GameTooltip:AddLine("No (valid) target.", 0.8, 0.8, 0.8);
	end

	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("Click left to initiate quest communication (with a valid target).");
	GameTooltip:AddLine("Click shift-left to initiate quest dialogs based on previous communication.");
	GameTooltip:AddLine("Click middle to open CommonersQuest log.");
	GameTooltip:AddLine("Click right to edit quests and rewards.");

	GameTooltip:Show();
end

function	CommonersQuest.LDBAction(oFrame, mousebtn)
	if (mousebtn == "LeftButton") then
		local	sPlayer, sServer = UnitName("target");
		if ((sServer ~= nil) and (sServer ~= "")) then
			CQH.CommChat("ChatImportant", nil, sPlayer .. " is from another server: " .. sServer);
		elseif (sPlayer and CommonersQuest.Version[sPlayer]) then
			if (CommonersQuest.Version[sPlayer].Valid) then
				if (IsShiftKeyDown() and CQData[sPlayer] and CQData[sPlayer].QuestsList and (CQData[sPlayer].QuestsList.Status == 7)) then
					CommonersQuest.GreetingPanel(sPlayer);
				else
					CommonersQuest.TargetInitiateQuery(IsShiftKeyDown());
				end
			elseif (time() - CommonersQuest.Version[sPlayer].CheckReq < 10) then
				CQH.CommChat("ChatImportant", nil, "Still checking version... Click again when the version has been validated!");
			else
				CQH.CommChat("ChatImportant", nil, "No CommonersQuest found at targetted player.");
			end
		end
	elseif (mousebtn == "MiddleButton") then
		CQH.CommChat("DbgInfo", "Log", "Trying to open questlog...");
		CommonersQuestLogFrame:Hide();
		CommonersQuest.Log.Init();
	elseif (mousebtn == "RightButton") then
		ToggleDropDownMenu(1, nil, CommonersQuestLDBMenu, oFrame, 0, 0);
	elseif (mousebtn ~= nil) then
		CQH.CommChat("DbgInfo", "Log", "No action assigned to mousebtn = " .. mousebtn);
	end
end

function	CommonersQuest.SecureHooks.GameTooltip_SetBagItem(oFrametip, iBag, iSlot)
	local	_, sItem = oFrametip:GetItem();
	if (sItem) then
		local	sItemLink = string.match(sItem, "|H(item[:%d%-]+)|h");
		if (sItemLink) then
			sItemLink = CQH.StripLevelFromItemLink(sItemLink);
			if (CQDataItems[sItemLink] ~= nil) then
				local	sGiver = CQDataItems[sItemLink].Giver;
				local	sTaker = CQDataItems[sItemLink].Taker;
				local	iQuest = CQDataItems[sItemLink].QuestID;
				local	sSince = "";
				if (CQDataItems[sItemLink].BindingItemCandidate) then
					sSince = date(" since %Y/%m/%d %H:%M", CQDataItems[sItemLink].BindingItemCandidate);
					GameTooltip:AddLine("CommonersQuest: Quest " .. CQH.QuestToPseudoLink(iQuest) .. sSince, 0, 1, 0);
					if (UnitName("player") ~= sGiver) then
						sGiver = " from " .. sGiver;
					else
						sGiver = "";
					end
					GameTooltip:AddLine("Marked as binding item for quest " .. iQuest .. " requested by player " .. sTaker .. sGiver .. ".", 0, 1, 0);
				else
					if (UnitName("player") ~= sTaker) then
						sTaker = " given to " .. sTaker;
					else
						sTaker = "";
					end
					GameTooltip:AddLine("CommonersQuest: Quest " .. CQH.QuestToPseudoLink(iQuest) .. sSince, 1, 1, 0);
					GameTooltip:AddLine("This item is bound to quest " .. iQuest .. " from player " .. sGiver .. sTaker .."!", 1, 1, 0);
				end
				GameTooltipTextLeft1:SetTextColor(0, 1, 1);
				GameTooltip:Show();
			end
		end
	end
end

function	CommonersQuest.EventChatMsgYell(oFrame, sEvent, ...)
	local	sMessage, sAuthor, sLanguage = ...;
	if (sAuthor and CQData[sAuthor]) then
		if (strsub(sMessage, 1, 5) == "[CQI]") then
			CQH.CommChat("DbgInfo", "Quest", "Decryption: checking for quest id + key from quest giver " .. sAuthor .. "...");

			local	oQuest;

			local	sQID, sKey = string.match(sMessage, "%[CQI%] (%d+) (%d+)");
			local	iQID, iKey;
			if (sQID and sKey) then
				iQID = tonumber(sQID);
				iKey = tonumber(sKey);
				if (iQID and iKey) then
					oQuest = CQH.CharQuestToObj(sAuthor, iQID);
				end
			end

			if (oQuest == nil) then
				CQH.CommChat("ChatInfo", "Quest", "Decryption: Quest " .. sQID .. " not found!");
			elseif (oQuest.State and oQuest.State.Encrypted) then
				local	bOk = true;
				CQH.CommChat("DbgInfo", "Quest", "Decryption: Trying to decode " .. sQID .. " with key " .. sKey .. "...");

				local	k, v;
				for k, v in pairs(oQuest) do
					if (type(v) == "string") then
						oQuest[k] = CQH.Decode(v, iKey);
					end
				end

				local	oMeta = CommonersQuest.DBMetaInfo.QuestFields.RequirementsEntries.TypeSelector;

				local	iCnt, i = #oQuest.Requirements;
				for i = 1, iCnt do
					local	oReq, k, v = oQuest.Requirements[i];
					for k, v in pairs(oReq) do
						if (k ~= "Type") then
							if (type(v) == "string") then
								oReq[k] = CQH.Decode(v, iKey);

								local	sType = oMeta[oReq.Type][k];
								if (sType ~= "string") then
									if (sType == "boolean") then
										if (oReq[k] == "{false}") then
											oReq[k] = false;
										elseif (oReq[k] == "{true}") then
											oReq[k] = true;
										else
											bOk = false;
											oReq[k] = "ERROR:" .. oReq[k];
										end
									elseif (sType == "number") then
										local	iNum = tonumber(oReq[k]);
										if (iNum) then
											oReq[k] = iNum;
										else
											bOk = false;
											oReq[k] = "ERROR:" .. oReq[k];
										end
									end
								end
							end
						end
					end
				end

				if (bOk) then
					CQH.CommChat("ChatInfo", "Quest", "Decryption: Quest " .. sQID .. " decrypted.");

					oQuest.State.Encrypted = nil;
					CommonersQuest.ValidateQuest(oQuest, true, nil, sAuthor);
				else
					CQH.CommChat("ChatImportant", "Quest", "Decryption: Failed to decrypt quest " .. sQID .. " correctly!");
				end

			else
				CQH.CommChat("ChatInfo", "Quest", "Decryption: Quest " .. sQID .. " isn't encrypted?!");
			end
		end
	end

	return false;
end

function	CommonersQuest.SecureHooks.ShowUIPanel()
	-- brute-force: close all on whatever the user opens
	-- CommonersQuestFrame:Hide();	-- now a panel itself!
	CommonersQuestLogFrame:Hide();
end

function	CommonersQuest.PlayerInit(sPlayer, sGUID)
	local	bOk = true;

--	DEFAULT_CHAT_FRAME:AddMessage("Initalizing data container for " .. sPlayer .. "...");

	CQH.InitTable(CQData, sPlayer);
	if (CQData[sPlayer].GUID == nil) then
		CQData[sPlayer].GUID = sGUID;
	elseif (sGUID ~= nil) then
		bOk = CQData[sPlayer].GUID == sGUID;
	end

	-- ?List - !List stuff:
	CQH.InitTable(CQData[sPlayer], "QuestsList");
	-- quests the giver thinks the giver has given
	CQH.InitTable(CQData[sPlayer].QuestsList, "QuestsReceiving");
	-- quests the giver has proposed
	CQH.InitTable(CQData[sPlayer].QuestsList, "QuestsProposing");
	-- quests the giver has, but inactive
	CQH.InitTable(CQData[sPlayer].QuestsList, "QuestsUnavailable");
	-- quests the giver has, but in transfer
	CQH.InitTable(CQData[sPlayer].QuestsList, "QuestsTransferring");

	-- items the giver has proposed
	CQH.InitTable(CQData[sPlayer], "RewardsReserved");
	-- items the taker hopes to get
	CQH.InitTable(CQData[sPlayer], "RewardsPromised");

	-- quests that the giver is requested
	CQH.InitTable(CQData[sPlayer], "QuestsRequestedToGive");
	-- quests that the taker requests
	CQH.InitTable(CQData[sPlayer], "QuestsAcknowledgedToTake");

	-- quests the giver thinks the taker has
	CQH.InitTable(CQData[sPlayer], "QuestsGiven");
	-- quests the taker thinks he has
	CQH.InitTable(CQData[sPlayer], "QuestsCurrent");

	-- the taker's copy of a custom quest of giver
	CQH.InitTable(CQData[sPlayer], "QuestsCustom");

	-- items to bind
	CQH.InitTable(CQData[sPlayer], "ItemAccepted");

	-- history on giver's end
	CQH.InitTable(CQData[sPlayer], "QuestsCompleted");

	return bOk;
end

function	CommonersQuest.TargetInitiateQuery()
	if (CommonersQuestFrame:IsShown()) then
		CommonersQuest.FrameMain.Hide();
	end

	local	sPlayer, sServer = UnitName("target");
	if (CQH.IsValidTarget()) then
		local	sGUID   = UnitGUID("target");
		if (CommonersQuest.PlayerInit(sPlayer, sGUID)) then
			if (CQData[sPlayer].QuestsList.Request and (time() - CQData[sPlayer].QuestsList.Request < 30)) then
				CQH.CommChat("ChatInfo", nil, UnitName("target") .. ": Request for quests information already in progress.");
			else
				CQData[sPlayer].QuestsList.Request = time();
				CQData[sPlayer].QuestsList.Status = 0;

				local	k, v;
				for k, v in pairs(CQData[sPlayer].QuestsList) do
					if (type(v) == "table") then
						v = table.wipe(v);
					end
				end

				local	_, sRace = UnitRace("player");
				local	_, sClass = UnitClass("player");
				local	sReq = "?List:" .. sRace .. ":" .. sClass .. ":" .. UnitSex("player") .. ":" .. UnitLevel("player");
				CommonersQuest.QueueAddonMessage("COMMONERSQUEST", sReq, "WHISPER", sPlayer);
				CQH.CommChat("ChatInfo", nil, UnitName("target") .. ": Requesting quests information...");
			end
		else
			local	sMsg = "Not a valid target: " .. sPlayer .. " (GUID mismatch, this character was deleted and recreated!)";
			CQH.CommChat("ChatInfo", nil, "Not a valid target: " .. sMsg);
		end
	else
		if (sPlayer ~= nil) then
			local	sMsg = "Not a valid target: " .. sPlayer;
			if ((sServer ~= nil) and (sServer ~= "")) then
				sMsg = sMsg .. "@" .. sServer .. " (foreign server)";
			end
			CQH.CommChat("ChatInfo", nil, "Not a valid target: " .. sMsg);
		else
			CQH.CommChat("ChatInfo", nil, "No (valid) target.");
		end
	end
end

function	CommonersQuest.QuestIs(iQuestID)
	if ((CommonersQuestFrame.Player == nil) and (CommonersQuestFrame.EditMode == true)) then
		local	oQuests;
		if (iQuestID < 1000000) then
			oQuests = CommonersQuest.QuestDB;
		else
			oQuests = CQDataGlobal.CustomQuests;
		end

		local oQuest, k, v;
		for k, v in pairs(oQuests) do
			if (v.ID == iQuestID) then
				oQuest = v;
				break;
			end
		end

		if (oQuest) then
			CQH.CommChat("DbgInfo", "Quest", "Edit mode... showing quest " .. CQH.QuestToPseudoLink(iQuestID, oQuest.Title) .. " you are *giving*.");
		else
			CQH.CommChat("DbgImportant", "Quest", "Failed to initialize edit mode for quest " .. (iQuestID or "<missing id?>") .. " ==> " .. debugstack());
		end

		return oQuest;
	end

	local	sPlayer = CommonersQuestFrame.Player;
	if (sPlayer == nil) then
		CQH.CommChat("DbgImportant", "Quest", "No clue who's quest we're trying to show here...?");
		if (CommonersQuestFrame:IsShown()) then
			CommonersQuest.FrameMain.Hide();
		end
		return;
	end

	local oQuest;
	if (iQuestID < 1000000) then
		local k, v;
		for k, v in pairs(CommonersQuest.QuestDB) do
			if (v.ID == iQuestID) then
				oQuest = v;
			end
		end
	else
		local k, v;
		for k, v in pairs(CQData[sPlayer].QuestsCustom) do
			if (v.ID == iQuestID) then
				oQuest = v;
			end
		end
	end

	if (oQuest == nil) then
		DEFAULT_CHAT_FRAME:AddMessage("ID not found: " .. iQuestID);
		if (CommonersQuestFrame:IsShown()) then
			CommonersQuest.FrameMain.Hide();
		end
	end

	return oQuest;
end

function	CommonersQuest.QuestRequested(sPlayer, iQuestID)
	CommonersQuest.PlayerInit(sPlayer);
	if (CQData[sPlayer].QuestsAcknowledgedToTake[iQuestID] == nil) then
		local	sCookie = ":" .. CQData[sPlayer].RewardsPromised[iQuestID].Info.Giver.Cookie .. ":";
		CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?Syn:" .. iQuestID .. sCookie .. UnitGUID("player"), "WHISPER", sPlayer);
	else
		DEFAULT_CHAT_FRAME:AddMessage("You already HAVE accepted this quest. The exchange of a \"binding item\" is still pending though.");
	end
end

function	CommonersQuest.TradeAccept(sFor)
	local	sFrom, sItemLink, iQuest, sGiver;
	if (sFor == "Give") then
		sItemLink = StaticPopupDialogs["COMMONERSQUEST_QUESTGIVER_ITEMTRADE_ISFORQUEST"].cq_itemlink;
		local	oItemInfo = CQDataItems[sItemLink];
		iQuest = oItemInfo.QuestID;
		sFrom = oItemInfo.Taker;
		sGiver = UnitName("player");
		CQData[sFrom].WillingToGive = { Link = sItemLink, QuestID = iQuest };
	elseif (sFor == "Take") then
		sFrom = StaticPopupDialogs["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"].cq_from;
		iQuest = StaticPopupDialogs["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"].cq_questid;
		sItemLink = StaticPopupDialogs["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"].cq_itemlink;
		sGiver = sFrom;
		CQData[sFrom].AcceptedToTake = { Link = sItemLink, QuestID = iQuest };
	end

	CQH.InitTable(CQData[sFrom].ItemAccepted, sItemLink);
	CQH.InitTable(CQData[sFrom].ItemAccepted[sItemLink], sFor);
	CQData[sFrom].ItemAccepted[sItemLink][sFor].Giver = sGiver;
	CQData[sFrom].ItemAccepted[sItemLink][sFor].Q = iQuest;
	CQData[sFrom].ItemAccepted[sItemLink][sFor].At = time();
	CQData[sFrom].ItemAccepted[sItemLink][sFor].Local = true;

	CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Item:+:" .. sFor .. ":" .. iQuest .. ":" .. sItemLink, "WHISPER", sFrom);
end

function	CommonersQuest.TradeDeny(sFor)
	CancelTrade();

	local	sFrom, iQuest, sLink;
	if (sFor == "Give") then
		sLink = StaticPopupDialogs["COMMONERSQUEST_QUESTGIVER_ITEMTRADE_ISFORQUEST"].cq_itemlink;
		local	oItemInfo = CQDataItems[sLink];
		iQuest = oItemInfo.QuestID;
		sFrom = oItemInfo.Taker;
		CQData[oItemInfo.Taker].WillingToGive = nil;
	elseif (sFor == "Take") then
		sFrom = StaticPopupDialogs["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"].cq_from;
		iQuest = StaticPopupDialogs["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"].cq_questid;
		sLink = StaticPopupDialogs["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"].cq_itemlink;
		CQData[sFrom].AcceptedToTake = nil;
	end

	CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Item:-:" .. sFor .. ":" .. iQuest .. ":" .. sLink, "WHISPER", sFrom);
end

function	CommonersQuest.GreetingPanelReopen(sPlayer, bNoCheck)
	if (CommonersQuestFrame:IsShown()) then
		if (CommonersQuestFrameGreetingPanel:IsShown()) then
			if ((sPlayer == CommonersQuestFrame.Player) and not CommonersQuestFrame.EditMode) then
				CommonersQuest.GreetingPanel(sPlayer, bNoCheck);
			end
		end
	end
end

function	CommonersQuest.GreetingPanel(sPlayer, bNoCheck)
	CQData[sPlayer].QuestsList.Request = 0;
	if (CQData[sPlayer].QuestsList.Status ~= 7) then
		return
	end

	local	k, v;

	local	iAll = 0;
	local	oAll = {};
	for k, v in pairs(CQData[sPlayer].QuestsList.QuestsProposing) do
		iAll = iAll + 1;
		oAll[v] = {};
		oAll[v].Status = 1;

		if (CQData[sPlayer].QuestsCurrent) then
			local	l, w;
			for l, w in pairs(CQData[sPlayer].QuestsCurrent) do
				if (l == v) then
					CQH.InitTable(w, "State");
					if (w.State.Closed) then
						CQH.CommChat("ChatImportant", nil, sPlayer .. " has |cFF60FF60re-enabled|r a quest you were on: " .. CQH.QuestToPseudoLink(v, nil, sPlayer));
					end
					w.State.Closed = false;
				end
			end
		end
	end
	for k, v in pairs(CQData[sPlayer].QuestsList.QuestsUnavailable) do
		iAll = iAll + 1;
		oAll[v] = {};
		oAll[v].Status = 3;
	end
	for k, v in pairs(CQData[sPlayer].QuestsList.QuestsReceiving) do
		CQH.InitTable(oAll, v);
		if (oAll[v].Status == 3) then
			if (CQData[sPlayer].QuestsCurrent) then
				local	l, w;
				for l, w in pairs(CQData[sPlayer].QuestsCurrent) do
					if (l == v) then
						CQH.InitTable(w, "State");
						if (w.State.Closed ~= true) then
							CQH.CommChat("ChatImportant", nil, sPlayer .. " has |cFFFFFF00disabled|r a quest you were on: " .. CQH.QuestToPseudoLink(v, nil, sPlayer) .. "  (You should still be able to complete it. You just can't re-get it if you abandon it...)");
						end
						w.State.Closed = true;
					end
				end
			end
		end

		oAll[v].Status = 2;
	end
	for k, v in pairs(CQData[sPlayer].QuestsList.QuestsTransferring) do
		CQH.InitTable(oAll, v.QuestID);
		oAll[v.QuestID].Status = 0;
	end

	local	oActive = {};
	local	oAvailable = {};
	local	oUnavailable = {};
	local	oPending = {};
	for k, v in pairs(oAll) do
		local	iIndex;
		if (k < 1000000) then
			local	l, w;
			for l, w in pairs(CommonersQuest.QuestDB) do
				if (w.ID == k) then
					iIndex = l;
					break;
				end
			end
		else
			local	l, w;
			for l, w in pairs(CQData[sPlayer].QuestsCustom) do
				if (w.ID == k) then
					if ((v.Status ~= 1) or bNoCheck or CommonersQuest.ValidateQuest(w, false, nil, sPlayer)) then
						iIndex = - l;
					else
						v.Status = nil;
					end
					break;
				end
			end
		end

		if (v.Status == 1) then
			local	bPending = false;
			if (CQData[sPlayer].QuestsAcknowledgedToTake and (#CQData[sPlayer].QuestsAcknowledgedToTake > 0)) then
				local	l, w;
				for l, w in pairs(CQData[sPlayer].QuestsAcknowledgedToTake) do
					if (w == v) then
						bPending = true;
						tinsert(oPending, iIndex);
						break
					end
				end
			end
			if (not bPending) then
				tinsert(oAvailable, iIndex);
			end
		elseif (v.Status == 2) then
			tinsert(oActive, iIndex);
		elseif (v.Status == 3) then
			tinsert(oUnavailable, iIndex);
		end
	end

	-- TODO: check for mismatches between QuestsReceiving and QuestsCurrent

--	DEFAULT_CHAT_FRAME:AddMessage("Received: " .. iAll .. " quests total, "  .. #oAvailable .. " available quests and " .. #oActive .. " active ones.");

	CommonersQuest.FrameMain.Hide();

	CommonersQuestFrame.EditMode = false;
	CommonersQuestFrame.Player = sPlayer;
	CommonersQuest.FrameGreetingPanel.Init(oActive, oAvailable, oUnavailable, oPending, CQData[sPlayer].QuestsList.QuestsTransferring);
end

function	CommonersQuest.ValidateQuest(oQuest, bVerbose, iRewardSet, sPlayer, fChannel)
	local	bOk = true;

	if (fChannel == nil) then
		fChannel = CQH.CommChat;
	end

	if (bVerbose) then
		local	iQuest = oQuest;
		if (type(oQuest) ~= "number") then
			iQuest = oQuest.ID;
		end
		fChannel("DbgSpam", "Quest", "Validating quest " .. iQuest .. " / reward set " .. (iRewardSet or "??"));
	end

	local	oGlobalRewards, bNullRewardOk;
	if (type(oQuest) == "number") then
		local	iQuest = oQuest;
		if (iQuest < 1000000) then
			local	k, v;
			for k, v in pairs(CommonersQuest.QuestDB) do
				if (v.ID == iQuest) then
					if (bVerbose) then
						fChannel("DbgSpam", "Quest", "Found quest " .. iQuest .. " in common database.");
					end
					oQuest = v;
				end
			end
		else
			local	k, v;
			for k, v in pairs(CQDataGlobal.CustomQuests) do
				if (v.ID == iQuest) then
					if (bVerbose) then
						fChannel("DbgSpam", "Quest", "Found quest " .. iQuest .. " in user-generated database.");
					end
					oQuest = v;
				end
			end
		end

		local	_, sRewardSetOut;
		oGlobalRewards, _, sRewardSetOut = CQH.InitRewards(oQuest.ID, (iRewardSet or ""), true);
		if (iRewardSet == nil) then
			iRewardSet = "<nil>";
		end
		iRewardSet = "[" .. iRewardSet .. "]=>[" .. (sRewardSetOut or "???") .. "]";
		if (oGlobalRewards and (#oGlobalRewards > 0)) then
			if (bVerbose) then
				fChannel("ChatSpam", "Quest", "Quest " .. oQuest.ID .. " has currently at least one valid and lockable reward set " .. iRewardSet .. " defined.");
			end
		else
			bOk = false;
			if (bVerbose) then
				fChannel("ChatSpam", "Quest", "Quest " .. oQuest.ID .. " lacks a valid and lockable reward set.");
			else
				return bOk;
			end
		end
	else
		fChannel("DbgInfo", "Quest", "Quest " .. oQuest.ID .. " from " .. sPlayer .. ": Delaying the validation of rewards.");
		bNullRewardOk = true;
		if (sPlayer and CQData[sPlayer] and CQData[sPlayer].RewardsPromised[oQuest.ID]) then
			oGlobalRewards = CQData[sPlayer].RewardsPromised[oQuest.ID].Data;
		end
	end

	if ((type(oQuest) ~= "table") or (type(oQuest.ID) ~= "number")) then
		if (bVerbose) then
			fChannel("DbgInfo", "Quest", "Invalid quest reference.");
		end

		return false;
	end

	local	function	CheckSelector(oMeta, Mk, MEk, Qv, bVerbose)
			local	bOk = true;

			-- selector: multiple entries
			local	QSubk, QSubv;
			for QSubk, QSubv in pairs(Qv) do
				local	QEv = QSubv[MEk];
				local	QuestEntryType = type(QEv);
				if (QuestEntryType ~= "string") then
					bOk = false;
					if (bVerbose) then
						fChannel("ChatSpam", "Quest", "Selector [" .. QSubk .. "] " .. Mk .. "." .. MEk .. " should be of type <string> but is <" .. QuestEntryType .. ">");
					else
						return bOk;
					end
				else
					local	oSels = oMeta[Mk .. "Entries"][MEk .. "Selector"];
					local	oOpts = oMeta[Mk .. "Entries"][MEk .. "Optional"];
					local	oDesc = oMeta[Mk .. "Entries"][MEk .. "Descriptor"];
					if (type(oSels) == "table") then
						local	oSel = oSels[QEv];
						if (type(oSel) == "table") then
							local	Selk, Selv;
							for Selk, Selv in pairs(oSel) do
								local	QuestSelectorValueType = type(QSubv[Selk]);
								if (QuestSelectorValueType == "nil") then
									if (oOpts and oOpts[Selk]) then
										if (bVerbose) then
											fChannel("DbgSpam", "Quest", "Selector [" .. QSubk .. "] " .. QEv .. ": Field " .. Mk .. "." .. Selk .. " should be of type <" .. Selv .. "> but is <" .. QuestSelectorValueType .. ">. Optional Field, not counting for validation.");
										end
										Selv = "nil";
									end
								end
								if (QuestSelectorValueType ~= Selv) then
									bOk = false;
									if (bVerbose) then
										local	sDesc = "";
										if (oDesc and oDesc[Selk]) then
											sDesc = " (" .. oDesc[Selk] .. ")";
										end
										if (QuestSelectorValueType == "nil") then
											fChannel("ChatSpam", "Quest", "Selector [" .. QSubk .. "] " .. QEv .. ": Field " .. Mk .. "." .. Selk .. sDesc .. " is mandatory, but not set (yet).");
										else
											fChannel("ChatSpam", "Quest", "Selector [" .. QSubk .. "] " .. QEv .. ": Field " .. Mk .. "." .. Selk .. sDesc .. " should be of type <" .. Selv .. "> but is <" .. QuestSelectorValueType .. ">! Oops!");
										end
									else
										return bOk;
									end
								end
							end
						else
							bOk = false;
							if (bVerbose) then
								fChannel("ChatSpam", "Quest", "Selector [" .. QSubk .. "] " .. Mk .. "." .. MEk .. ": Choice not found!");
							else
								return bOk;
							end
						end
					else
						bOk = false;
						if (bVerbose) then
							fChannel("ChatSpam", "Quest", "Selector [" .. QSubk .. "] " .. Mk .. "." .. MEk .. ": Definition completely missing!!");
						else
							return bOk;
						end
					end
				end
			end

			return bOk;
		end

	if (bVerbose) then
		fChannel("ChatSpam", "Quest", "Now recursing into structure of quest " .. oQuest.ID .. " for validation...");
	end

	local	bEncrypted = oQuest.State.Encrypted;
	if (bEncrypted) then
		fChannel("ChatSpam", "Quest", "The quest " .. oQuest.ID .. " from " .. sPlayer .. " contains encrypted parts! The validation result might be not quite correct after decryption...");
	end

	local	oMeta = CommonersQuest.DBMetaInfo.QuestFields;
	local	Mk, Mv;
	for Mk, Mv in pairs(oMeta) do
		local	MetaType = type(Mv);
		if (MetaType == "string") then
			local	Qv = oQuest[Mk];
			local	QuestType = type(Qv);
			if (Mv == "table:optional") then
				if ((Qv == nil) or (QuestType == "table")) then
					QuestType = Mv;
				end
			end
			if (QuestType ~= Mv) then
				bOk = false;
				if (bVerbose) then
					fChannel("ChatSpam", "Quest", "Field " .. Mk .. " should be of type <" .. Mv .. "> but is <" .. QuestType .. ">");
				else
					return bOk;
				end
			elseif ((Mv == "table") or (Mv == "table:optional")) then
				if (Qv == nil) then
					if (bVerbose) then
						fChannel("DbgSpam", "Quest", "Skipping missing optional " .. Mk .. " (" .. Mv .. ")...");
					end
				else
					if (bVerbose) then
						fChannel("DbgSpam", "Quest", "Recursing into " .. Mk .. " (" .. Mv .. ")...");
					end

					if (oMeta[Mk .. "Entries"]) then
						local	MEk, MEv;
						for MEk, MEv in pairs(oMeta[Mk .. "Entries"]) do
							local	MetaEntryType = type(MEv);
							if (MetaEntryType == "string") then
								if (MEv ~= "selector") then
									local	QEv = Qv[MEk];
									local	QuestEntryType = type(QEv);
									if (QuestEntryType ~= MEv) then
										local	bOptional = false;
										if (QuestEntryType == "nil") then
											if (oMeta[Mk .. "EntriesOptional"] and oMeta[Mk .. "EntriesOptional"][MEk]) then
												bOptional = true;
											end
										end

										if (not bOptional) then
											bOk = false;
											if (bVerbose) then
												fChannel("ChatSpam", "Quest", "Field " .. Mk .. "." .. MEk .. " should be of type <" .. MEv .. "> but is <" .. QuestEntryType .. ">");
											else
												return bOk;
											end
										end
									end
								else
									local	iSelectorCnt = #Qv;
									if ((Mk == "Reward") and (oGlobalRewards ~= nil)) then
										iSelectorCnt = iSelectorCnt + #oGlobalRewards;
									end

									if (iSelectorCnt == 0) then
										if ((Mk == "Reward") and bNullRewardOk) then
											if (bVerbose) then
												fChannel("DbgInfo", "Quest", "Selector group " .. Mk .. " is EMPTY. But rewards are delayed, ignoring.");
											end
										else
											bOk = false;
											if (bVerbose) then
												fChannel("ChatSpam", "Quest", "Selector group " .. Mk .. " is EMPTY.");
											else
												return bOk;
											end
										end
									end

									if (CheckSelector(oMeta, Mk, MEk, Qv, bVerbose)) then
										if (bVerbose and (#Qv > 0)) then
											fChannel("DbgSpam", "Quest", "Selector group " .. Mk .. "/Global (size " .. #Qv .. ") found valid.");
										end
									else
										bOk = false;
										if (not bVerbose) then
											return false;
										end
									end

									if ((Mk == "Reward") and (oGlobalRewards ~= nil)) then
										if (CheckSelector(oMeta, Mk, MEk, oGlobalRewards, bVerbose)) then
											if (bVerbose and (#oGlobalRewards > 0)) then
												fChannel("DbgSpam", "Quest", "Selector group " .. Mk .. "/RewardSet " .. (iRewardSet or "<nil>") .. " (size " .. #oGlobalRewards .. ") found valid.");
											end
										else
											bOk = false;
											if (not bVerbose) then
												return false;
											end
										end
									end
								end
							end
						end
					end

					if (oMeta[Mk .. "EntryType"]) then
						-- pre-Quest list: just a list of numbers
						local	sType = oMeta[Mk .. "EntryType"][1];
						local	QLk, QLv;
						for QLk, QLv in pairs(Qv) do
							if (type(QLv) ~= sType) then
								bOk = false;
								if (bVerbose) then
									fChannel("ChatSpam", "Quest", "Group " .. Mk .. " contains invalid entries (" .. type(QLv) .. " ~= " .. sType .. ").");
								else
									return false;
								end
							end
						end
					end
				end
			end
		end
	end

	if (bVerbose) then
		local	sValid = "invalid";
		if (bOk) then
			sValid = "valid";
		end
		fChannel("ChatInfo", "Quest", "Quest " .. CQH.QuestToPseudoLink(oQuest.ID, oQuest.Title) .. " analyzed and found " .. sValid .. ".");
	end

	return bOk;
end

-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --

function	CommonersQuest.QuestEdit.InitEdit(oFrame, sButton)
	if ((CommonersQuestFrame.EditMode == true) and (CommonersQuestFrame.Player == nil)) then
		local	sName, sField = oFrame:GetName();
		if (sName == "CommonersQuestDetailTitleText_EditBtn") then
			sField = "Title";
		elseif (sName == "CommonersQuestDetailDescription_EditBtn") then
			sField = "DescAcqIntro";
		elseif (sName == "CommonersQuestDetailObjectiveText_EditBtn") then
			sField = "DescAcqSmall";
		elseif (sName == "CommonersQuestProgressText_EditBtn") then
			sField = "DescLogSmall";
		elseif (sName == "CommonersQuestRewardText_EditBtn") then
			sField = "DescDoneSmall";
		end

		if (sField) then
			CQH.CommChat("DbgInfo", "Quest", "IE: Clicked <" .. sField .. "> to edit...");
			local	iID = CommonersQuestFrame:GetID();
			StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELDCONTENT"].ID = iID;
			StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELDCONTENT"].Field = sField;
			StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELDCONTENT"].Multiline = sField ~= "Title";
			StaticPopup_Show("COMMONERSQUEST_EDIT_FIELDCONTENT");
		end
	end
end

function	CommonersQuest.QuestEdit.QuestAddNew()
	-- add a new container, return ID
	local	oQuest = {};
	local	k, v;
	for k, v in pairs(CommonersQuest.QuestPattern) do
		if (type(v) == "table") then
			oQuest[k] = {};

			local	l, w;
			for l, w in pairs(v) do
				oQuest[k][l] = w;
			end
		else
			oQuest[k] = v;
		end
	end
	oQuest.ID = CQDataGlobal.Giver.CustomQuestsNextID;
	oQuest.State.Modified = time();

	tinsert(CQDataGlobal.CustomQuests, oQuest);

	CQDataGlobal.Giver.CustomQuestsNextID = CQDataGlobal.Giver.CustomQuestsNextID + 1;

	if (CommonersQuestFrame:IsShown()) then
		CommonersQuest.FrameMain.Hide();
	end

	CommonersQuestFrame.Player = nil;
	CommonersQuestFrame.EditMode = true;
	CommonersQuest.FrameDetailPanel.Init(oQuest.ID);
end

--
--

function	CommonersQuest.QuestEdit.MoneyRewardInit(oFrame)
	-- oData: Table, Index, Amount, hasDefault
	local	oData = StaticPopupDialogs[oFrame.which].customdata;
	MoneyInputFrame_SetCopper(oFrame.moneyInputFrame, oData.Amount);
end

function	CommonersQuest.QuestEdit.MoneyRewardSet(oFrame)
	-- oData: Table, Index, Amount, hasDefault
	local	oData = StaticPopupDialogs[oFrame.which].customdata;
	local	iAmount = MoneyInputFrame_GetCopper(oFrame.moneyInputFrame);
	if (iAmount == 0) then
		if (hasDefault) then
			oData.Table[oData.Index].Amount = 0;
		else
			local	iCnt = #oData.Table;
			oData.Table[oData.Index] = oData.Table[iCnt];
			oData.Table[iCnt] = nil;
		end
	else
		oData.Table[oData.Index].Amount = iAmount;
	end

	CommonersQuest.Menu.UpdateCurrentFrame();
end

--
--

function	CommonersQuest.QuestEdit.PopupTableFieldSet(oFrame)
	-- oData: Table, Field, Text
	local	oData = StaticPopupDialogs[oFrame.which].customdata;
	StaticPopupDialogs[oFrame.which].customdata = nil;

	local	sText = oFrame.wideEditBox:GetText();
	if (oData and sText and (sText ~= "")) then
		oData.Table[oData.Field] = sText;
		CommonersQuest.Menu.UpdateCurrentFrame();

		if (type(oData.Callback) == "function") then
			CQH.CommChat("DbgInfo", "Quest", "Edit: Field set, calling callback routine back...");
			return oData:Callback();
		end
	end
end

function	CommonersQuest.QuestEdit.PopupTableFieldInit(oFrame)
	-- oData: Table, Field, Text
	local	oData = StaticPopupDialogs[oFrame.which].customdata;
	oFrame.wideEditBox:SetText(oData.Text);
	oFrame.wideEditBox:HighlightText();
	oFrame.wideEditBox:SetFocus();
end

--
--

function	CommonersQuest.QuestEdit.PopupFieldInit(oFrame)
	local	oPopup = StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELDCONTENT"];
	local	iID = oPopup.ID;
	local	sField = oPopup.Field;

	local	sText, k, v;
	if (iID and sField) then
		for k, v in pairs(CQDataGlobal.CustomQuests) do
			if (v.ID == iID) then
				sText = v[sField];
				break;
			end
		end
	end

	if (sText) then
		if (oPopup.Multiline) then
			sText = string.gsub(sText, "\n", "\\n");
		end

		oFrame.text:SetText(format(oPopup.textbase, sField));
		oFrame.wideEditBox:SetText(sText);
		oFrame.wideEditBox:SetFocus();
	else
		oPopup.ID = nil;
		oPopup.Field = nil;
		oFrame:Hide();
	end
end

function	CommonersQuest.QuestEdit.PopupFieldSet(oFrame)
	local	oPopup = StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELDCONTENT"];
	local	iID = oPopup.ID;
	local	sField = oPopup.Field;

	local	sText = oFrame.wideEditBox:GetText();
	local	sTextOld, oQuest, k, v;
	if (iID and sField) then
		for k, v in pairs(CQDataGlobal.CustomQuests) do
			if (v.ID == iID) then
				oQuest = v;
				break;
			end
		end
	end

	if (oPopup.Multiline) then
		sText = string.gsub(sText, "\\n", "\n");
	end
	if (sField and (sText ~= oQuest[sField])) then
		CQH.CommChat("DbgInfo", "Quest", "PFS: Changed: <" .. (oQuest[sField] or "<nil>") .. "> to <" .. sText .. ">");
		oQuest[sField] = sText;
	end

	CommonersQuest.Menu.UpdateCurrentFrame();
end

function	CommonersQuest.QuestEdit.InputInit(oFrame)
	local	oPopup = StaticPopupDialogs["COMMONERSQUEST_SEARCH_REQUIREMENTTARGET"]; 
	local	iID = oPopup.ID;
	if (iID) then
		if (oPopup.Type == "Item") then
			oFrame.text:SetText("Enter full item name (or an item link):");
			oFrame.wideEditBox:SetText("Rusty dagger");
			oFrame.wideEditBox:SetFocus();
		elseif (oPopup.Type == "PC/NPC") then
		end
	end
end

function	CommonersQuest.QuestEdit.InputCheck(oFrame)
	local	sText = oFrame.wideEditBox:GetText();
	local	sName, sLink = GetItemInfo(sText);
	if (sLink) then
		oFrame.wideEditBox:SetText(sLink);
	end
end

function	CommonersQuest.QuestEdit.InputSet(oFrame)
	local	oPopup = StaticPopupDialogs["COMMONERSQUEST_SEARCH_REQUIREMENTTARGET"]; 
	local	iID = oPopup.ID;
	local	sText = oFrame.wideEditBox:GetText();
	if (iID and (sText) and (sText ~= "")) then
		if (oPopup.Type == "Item") then
			-- remove our level from item
			CQH.CommChat("DbgInfo", "Quest", "IS: Interpreting item input <" .. sText .. ">...");
			local	sText = oFrame.wideEditBox:GetText();
			local	sName, sLink = GetItemInfo(sText);
			if (sLink) then
				local	sItemID = string.match(sLink, "item:([%d%-]+)");
				local	iItemID = tonumber(sItemID);
				if (iItemID) then
					local	oItem = {};
					oItem.Type = "Loot";
					oItem.ItemID = iItemID;
					oItem.ItemName = sName;
					tinsert(CommonersQuest.Menu.GroupObj, oItem);

					CQH.CommChat("DbgInfo", "Quest", "IS: Added item " .. sLink .. ".");
				end
			end
		elseif (oPopup.Type == "PC/NPC") then
		end
	end

	CommonersQuest.Menu.UpdateCurrentFrame();
end

-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --

function	CommonersQuest.FetchTitles()
	local	oQuestsCurrent, oQuestsPending, oQuestsProposed;

	local	sChar, oChar;
	for sChar, oChar in pairs(CQData) do
		local	oQuestsCurrentIDs = {};
		if (oChar.QuestsCurrent) then
			local	oQuestsOfChar;

			-- update state if available
			local	iIndex, oQuestStored;
			for iIndex, oQuestStored in pairs(oChar.QuestsCustom) do
				if (oChar.QuestsCurrent[oQuestStored.ID] ~= nil) then
					CQH.InitTable(oChar.QuestsCurrent[oQuestStored.ID], "State");
					oChar.QuestsCurrent[oQuestStored.ID].State.Dirty = oQuestStored.State.Dirty;
				end
			end


			local	iID, oQuest;
			for iID, oQuest in pairs(oChar.QuestsCurrent) do
				local	_, sTitle = CQH.QuestToPseudoLink(iID, nil, sChar);
				if (sTitle) then
					local	oEntry = {};
					oEntry.ID = iID;
					oEntry.Title = sTitle;
					oEntry.Dirty = oQuest.State and oQuest.State.Dirty;
					oEntry.Abandonned = oQuest.Abandonned;

					if (oQuestsOfChar == nil) then
						oQuestsOfChar = {};
					end
					tinsert(oQuestsOfChar, oEntry);
					oQuestsCurrentIDs[iID] = 1;
				end
			end

			if (oQuestsOfChar) then
				if (oQuestsCurrent == nil) then
					oQuestsCurrent = {};
				end
				-- TODO: sort by title
				oQuestsCurrent[sChar] = oQuestsOfChar;
			end
		end

		if (oChar.QuestsList.QuestsProposing) then
			local	oQuestsPendingOfChar, oQuestsProposedOfChar;

			local	iIndex, iID;
			for iIndex, iID in pairs(oChar.QuestsList.QuestsProposing) do
				if (oQuestsCurrentIDs[iID] ~= 1) then
					local	_, sTitle = CQH.QuestToPseudoLink(iID, nil, sChar);
					if (sTitle) then
						local	oEntry = {};
						oEntry.ID = iID;
						oEntry.Title = sTitle;
						oEntry.Pending = false;
						if (oChar.QuestsCurrent[iID]) then
							oEntry.Pending = oChar.QuestsCurrent[iID].BindingCompleted ~= 3;
						elseif (oChar.QuestsAcknowledgedToTake[iID]) then
							oEntry.Pending = true;
						end

						local	oQuestsOfChar;
						if (oEntry.Pending) then
							if (oQuestsPendingOfChar == nil) then
								oQuestsPendingOfChar = {};
							end
							oQuestsOfChar = oQuestsPendingOfChar;
						else
							if (oQuestsProposedOfChar == nil) then
								oQuestsProposedOfChar = {};
							end
							oQuestsOfChar = oQuestsProposedOfChar;
						end

						tinsert(oQuestsOfChar, oEntry);
					end
				end
			end

			if (oQuestsPendingOfChar) then
				if (oQuestsPending == nil) then
					oQuestsPending = {};
				end
				-- TODO: sort by title
				oQuestsPending[sChar] = oQuestsPendingOfChar;
			end
			if (oQuestsProposedOfChar) then
				if (oQuestsProposed == nil) then
					oQuestsProposed = {};
				end
				-- TODO: sort by title
				oQuestsProposed[sChar] = oQuestsProposedOfChar;
			end
		end
	end

	-- TODO: sort by name
	return oQuestsCurrent, oQuestsPending, oQuestsProposed;
end

function	CommonersQuest.RequestRewards(sPlayer, iQuestID)
	CQH.InitTable(CQData[sPlayer].RewardsPromised, iQuestID);
	CQH.InitTable(CQData[sPlayer].RewardsPromised[iQuestID], "Data");
	CQH.InitTable(CQData[sPlayer].RewardsPromised[iQuestID], "Info");

	local	oData = CQData[sPlayer].RewardsPromised[iQuestID];
	oData.Info.Request = { Global = time(), Current = GetTime() };

	local	Cookie;
	if (oData.Info.Giver) then
		local	bMissing, iCnt, i = false, oData.Info.Count;
		if (iCnt == nil) then
			bMissing = true;
		else
			for i = 1, iCnt do
				if (oData.Data[i] == nil) then
					bMissing = true;
				end
			end
		end

		if (not bMissing and oData.Info.Giver and oData.Info.Giver.Cookie) then
			Cookie = ":" .. oData.Info.Giver.Cookie;
		else
			oData.Data = {};
			oData.Info.Received = {};
		end
	end

	CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?Reward:" .. iQuestID .. (Cookie or ""), "WHISPER", sPlayer);
end

-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --

-- main menu command ids
CommonersQuest.MMC = {
		BINDASSIGNITEM = 10,
		BINDALLOWNONE = 11,

		REWARDSETADDNEW = 20,

		COPYQUEST = 30,
		DELETEQUEST = 31,
		UNDELETEQUEST = 32,

		SETKEY = 40,
		DELKEY = 41,
		YELLKEY = 42,

		ENABLE = 1,
		VIEWQUEST = 2,
		DISABLE = 3,

		EDITQUEST = 4,
		EDITREPREQ = 5,
		EDITREWARD = 6,
	};

-- main menu texts
CommonersQuest.MMT = {};

local	MMC = CommonersQuest.MMC;
local	MMT = CommonersQuest.MMT;

MMT[MMC.BINDASSIGNITEM] = "Assign binding items to pending quests";
MMT[MMC.BINDALLOWNONE] = "Quest is given without binding item";

MMT[MMC.REWARDSETADDNEW] = "Add a new reward set";

MMT[MMC.ENABLE] = "Enable quest";
MMT[MMC.VIEWQUEST] = "View quest";
MMT[MMC.DISABLE] = "Disable quest";
MMT[MMC.EDITQUEST] = "Edit quest: infos/requirements";
MMT[MMC.EDITREPREQ] = "Edit quest repeat./prereq.";
MMT[MMC.EDITREWARD] = "Edit quest reward sets";

MMT[MMC.COPYQUEST] = "Create a copy of this quest";
MMT[MMC.DELETEQUEST] = "Delete quest";
MMT[MMC.UNDELETEQUEST] = "Undelete quest";

MMT[MMC.SETKEY] = "Set an encryption key";
MMT[MMC.DELKEY] = "Unset the encryption key";
MMT[MMC.YELLKEY] = "Yell the encryption key";

local	function	EncryptionKeyEntered(oData)
	local	sValue = oData.Table[oData.Field];
	local	iValue = tonumber(sValue);
	if (iValue and (math.floor(iValue) ~= iValue)) then
		iValue = nil;
	end

	oData.Table[oData.Field] = nil;
	if (iValue and (iValue > 0) and (iValue < 2^31)) then
		CQH.CommChat("ChatImportant", nil, "Key is a valid number. Transfers of this quest will from now on be encrypted with this key.");
		oData.Table[oData.Field] = iValue;
	else
		CQH.CommChat("ChatImportant", nil, "Key was *not* a valid number, ignored. The key must be a natural number between 1 and " .. (2^31 - 1) .. ".");
	end
end

function	CommonersQuest.LDBMenu.QuestActionClicked(oFrame, iAction, iQuestID)
	CQH.CommChat("DbgInfo", "Quest", "QuestActionClicked: QuestID = " .. iQuestID .. ", Action = " .. iAction);
	if ((iAction == MMC.ENABLE) or (iAction == MMC.DISABLE)) then
		-- enable/disable quest
		local	oQuest;
		if (iQuestID < 1000000) then
			local	k, v;
			for k, v in pairs(CommonersQuest.QuestDB) do
				if (v.ID == iQuestID) then
					oQuest = v;
					break;
				end
			end
		else
			local	k, v;
			for k, v in pairs(CQDataGlobal.CustomQuests) do
				if (v.ID == iQuestID) then
					oQuest = v;
					break;
				end
			end
		end

		if (oQuest) then
			local	_, oStatePerChar = CQH.InitStateGiver(oQuest);
			oStatePerChar.Enabled = iAction == MMC.ENABLE;
			if (oStatePerChar.Enabled) then
				local	iKey, k, v = nil;
				for k, v in pairs(CommonersQuest.QuestDB) do
					if (v.ID == oQuest.ID) then
						iKey = k;
						break;
					end
				end

				local	bValid = CommonersQuest.ValidateQuest(oQuest.ID, false, -2);
				if (not bValid) then
					if (iKey) then
						tremove(CommonersQuest.QuestDB, iKey);
					end
					oStatePerChar.Enabled = false;
					CQH.CommChat("ChatInfo", nil, "Failed to enable quest " .. CQH.QuestToPseudoLink(oQuest.ID, oQuest.Title) .. ": Quest is invalid!");
				else
					if (iKey) then
						CQH.CommChat("DbgInfo", "Quest", "Enabled: Updated record in QuestDB.");
						CommonersQuest.QuestDB[iKey] = oQuest;
					else
						CQH.CommChat("DbgInfo", "Quest", "Enabled: Inserted record into QuestDB.");
						tinsert(CommonersQuest.QuestDB, oQuest);
					end
				end
			end
		end
	elseif ((iAction == MMC.EDITQUEST) or (iAction == MMC.VIEWQUEST)) then
		if (CommonersQuestFrame:IsShown()) then
			CommonersQuest.FrameMain.Hide();
		end

		CommonersQuestFrame.EditMode = true;
		CommonersQuestFrame.Player = nil;
		CommonersQuestFrame.RewardSet = nil;
		if (iAction == MMC.VIEWQUEST) then
			CommonersQuestFrame.ViewMode = true;
		end
		CommonersQuest.FrameDetailPanel.Init(iQuestID);
	elseif (iAction == MMC.COPYQUEST) then
		-- add a new container, return ID
		local	oQuestFrom = CQH.CharQuestToObj(nil, iQuestID);
		if (oQuestFrom == nil) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Huh? How did you do *that*?");
			return
		end

		local	oQuest = CQH.CopyTable(oQuestFrom);
		oQuest.ID = CQDataGlobal.Giver.CustomQuestsNextID;
		oQuest.State.Locked = false;
		oQuest.State.Modified = time();

		tinsert(CQDataGlobal.CustomQuests, oQuest);

		CQDataGlobal.Giver.CustomQuestsNextID = CQDataGlobal.Giver.CustomQuestsNextID + 1;

		DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Quest " .. oQuestFrom.ID .. " has been copied to new id " .. oQuest.ID .. ". Reward sets have *not* been copied.");
	elseif ((iAction == MMC.DELETEQUEST) or (iAction == MMC.UNDELETEQUEST)) then
		local	oQuest = CQH.CharQuestToObj(nil, iQuestID);
		if (oQuest == nil) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Huh? How did you do *that*?");
			return
		end

		local	oStateGlobal = CQH.InitStateGiver(oQuest);
		oStateGlobal.Deleted = iAction == MMC.DELETEQUEST;
		if (oStateGlobal.Deleted) then
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Quest is now \"deleted\" (from your eyes). People on it can still complete it though.");
		end
	elseif (iAction == MMC.SETKEY) then
		local	oQuest = CQH.CharQuestToObj(nil, iQuestID);
		if (oQuest == nil) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Huh? How did you do *that*?");
			return
		end

		local	oStateGlobal = CQH.InitStateGiver(oQuest);

		-- use a static popup frame, let user enter a key or just accept the generated one
		local	oData = { Table = oStateGlobal, Field = "Key", Text = math.random(2^31 - 1), Callback = EncryptionKeyEntered };
		StaticPopupDialogs["COMMONERSQUEST_EDIT_FIELD"].customdata = oData;
		StaticPopup_Show("COMMONERSQUEST_EDIT_FIELD", "quest information", "'encryption key (number)'");
	elseif (iAction == MMC.DELKEY) then
		local	oQuest = CQH.CharQuestToObj(nil, iQuestID);
		if (oQuest == nil) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Huh? How did you do *that*?");
			return
		end

		local	oStateGlobal = CQH.InitStateGiver(oQuest);
		oStateGlobal.Key = nil;
		CQH.CommChat("ChatImportant", nil, "Quest key has been reset.");
	elseif (iAction == MMC.YELLKEY) then
		local	oQuest = CQH.CharQuestToObj(nil, iQuestID);
		if (oQuest == nil) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Huh? How did you do *that*?");
			return
		end

		local	oStateGlobal = CQH.InitStateGiver(oQuest);
		local	sMsg = "[CQI] " .. iQuestID .. " " .. oStateGlobal.Key;
		SendChatMessage(sMsg, "YELL");
	elseif (iAction == MMC.BINDALLOWNONE) then
		local	oQuest = CQH.CharQuestToObj(nil, iQuestID);
		if (oQuest == nil) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Huh? How did you do *that*?");
			return
		end

		local	oState = CQH.InitStateGiver(oQuest);
		oState.NoBindingItem = oState.NoBindingItem ~= true;
		if (oState.NoBindingItem) then
			CQH.CommChat("ChatImportant", nil, "Quest is flagged to work *without* binding item. (Not suggested for all but pure item(s) for money reward quests, as this means that the association between a trade and the quest supposed to be completed with it may not be recognized properly.)");
		else
			CQH.CommChat("ChatImportant", nil, "Quest is flagged to work in the regular way with a binding item.");
 		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Menu partially t.b.i.");
	end

	if (CommonersQuestMainframe:IsShown()) then
		CommonersQuest.Main.Refresh(CommonersQuestMainframe);
	end
end

function	CommonersQuest.LDBMenu.RewardSetEdit(oFrame, iQuestID, iSetID)
	CQH.CommChat("DbgInfo", "Quest", "RewardSetEdit: QuestID = " .. iQuestID .. ", SetID = " .. iSetID);

	if (CommonersQuestFrame:IsShown()) then
		CommonersQuest.FrameMain.Hide();

		CommonersQuestFrame.EditMode = true;
		CommonersQuestFrame.Player = nil;
		CommonersQuestFrame.RewardSet = iSetID;
		CommonersQuest.FrameDetailPanel.Init(iQuestID);
	end

	if (CommonersQuestMainframe:IsShown()) then
		CommonersQuest.Main.Refresh(CommonersQuestMainframe);
	end
end

function	CommonersQuest.LDBMenu.RewardSetAddNew(oFrame, iQuestID)
	CQH.CommChat("DbgInfo", "Quest", "RewardSetAddNew: QuestID = " .. iQuestID);

	local	oRewardSet, oState, iSetID = CQH.InitRewards(iQuestID, -1);

	if (CommonersQuestFrame:IsShown()) then
		CommonersQuest.FrameMain.Hide();
		CommonersQuestFrame.EditMode = true;
		CommonersQuestFrame.Player = nil;
		CommonersQuestFrame.RewardSet = iSetID;
		CommonersQuest.FrameDetailPanel.Init(iQuestID);
	end

	if (CommonersQuestMainframe:IsShown()) then
		CommonersQuest.Main.Refresh(CommonersQuestMainframe);
	end
end

function	CommonersQuest.LDBMenu.BindingItemAssign(oFrame, oItem, oQuestInfo)
	-- oItem = { Bag = iBag, Slot = iSlot, Item = sItemLink };
	-- oQuestInfo = { Taker = sChar, QuestID = iQuestID };
	local	sItem, sItemLink = GetContainerItemLink(oItem.Bag, oItem.Slot);
	if (sItem) then
		sItemLink = string.match(sItem, "|H(item[:%d%-]+)|h");
		sItemLink = CQH.StripLevelFromItemLink(sItemLink);
	end
	if (sItemLink == oItem.Item) then
		DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Assigning " .. sItem .. " to player " .. oQuestInfo.Taker .. "/quest "
			.. CQH.QuestToPseudoLink(oQuestInfo.QuestID) .. " currently in bag " .. (oItem.Bag + 1) .. " slot " .. oItem.Slot .. ".");
		CQDataItems[oItem.Item] = { Taker = oQuestInfo.Taker, Giver = UnitName("player"), QuestID = oQuestInfo.QuestID, BindingItemCandidate = time() };
		CQData[oQuestInfo.Taker].RewardsReserved[oQuestInfo.QuestID].BindingItemCandidate = { Item = oItem.Item, At = time() };
		CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!BindingItemCandidate:" .. oQuestInfo.QuestID .. ":" .. oItem.Item, "WHISPER", oQuestInfo.Taker);
	end
end

function	CommonersQuest.LDBMenu.BindingItemUnassign(oFrame, oItem, oQuestInfo)
	-- oItem = { Bag = iBag, Slot = iSlot, Item = sItemLink };
	-- oQuestInfo = { Taker = sChar, QuestID = iQuestID };
	local	sItem, sItemLink = GetContainerItemLink(oItem.Bag, oItem.Slot);
	if (sItem) then
		sItemLink = string.match(sItem, "|H(item[:%d%-]+)|h");
		sItemLink = CQH.StripLevelFromItemLink(sItemLink);
	end
	if (sItemLink and (sItemLink == oItem.Item) and CQDataItems[oItem.Item] and  (UnitName("player") == CQDataItems[oItem.Item].Giver)) then
		if (CQData[oQuestInfo.Taker] and CQData[oQuestInfo.Taker].RewardsReserved[oQuestInfo.QuestID] and CQData[oQuestInfo.Taker].RewardsReserved[oQuestInfo.QuestID].BindingItemCandidate and
		    (CQData[oQuestInfo.Taker].RewardsReserved[oQuestInfo.QuestID].BindingItemCandidate.Item == oItem.Item)) then
			DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Withdrawing assignment of " .. sItem .. " to player " .. oQuestInfo.Taker .. "/quest "
				.. CQH.QuestToPseudoLink(oQuestInfo.QuestID) .. " currently in bag " .. (oItem.Bag + 1) .. " slot " .. oItem.Slot .. ".");
			CQDataItems[oItem.Item] = nil;
			CQData[oQuestInfo.Taker].RewardsReserved[oQuestInfo.QuestID].BindingItemCandidate = nil;
		else
			local	sItem = "<missing frozen reward :: item>";
			if (CQData[oQuestInfo.Taker] and CQData[oQuestInfo.Taker].RewardsReserved[oQuestInfo.QuestID] and CQData[oQuestInfo.Taker].RewardsReserved[oQuestInfo.QuestID].BindingItemCandidate) then
				sItem = CQData[oQuestInfo.Taker].RewardsReserved[oQuestInfo.QuestID].BindingItemCandidate.Item;
			end
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Oops? " .. oQuestInfo.Taker .. "=>" .. oQuestInfo.QuestID .. "=>" .. sItem .. " <> " .. oItem.Item .. " ??");
		end
	else
		local	Giver = "<missing giver>";
		if (CQDataItems[oItem.Item]) then
			Giver = CQDataItems[oItem.Item].Giver;
		end
		DEFAULT_CHAT_FRAME:AddMessage("[CQ] Oops? " .. (sItemLink or "???") .. " <> " .. oItem.Item .. " or !" .. Giver .. " ??");
	end
end

function	CommonersQuest.LDBMenu.Initialize(oFrame, iLevel)
	iLevel = iLevel or 1;

--[[
	if (iLevel > 1) then
		local listFrame = getglobal("DropDownList".. iLevel);
		if (listFrame:GetLeft() > 800) then
			listFrame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 0, 0);
			-- DEFAULT_CHAT_FRAME:AddMessage("[CQ] Switched menu direction.");
		end
	end
]]--

	CommonersQuest.LDBMenu.InitializeIndirect(oFrame, UIDROPDOWNMENU_MENU_VALUE, iLevel, iLevel);
end

function	CommonersQuest.LDBMenu.InitializeIndirect(oFrame, oParent, iLevelIn, iLevelOut)
	local	info;

	if (iLevelIn == 1) then
		info = {};
		info.text = "CommonersQuest: main menu";
		info.isTitle = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = "Toggle main quest edit window";
		info.notCheckable = 1;
		info.func = CommonersQuest.Toggle;
		info.arg1 = 1;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = "-----------------------";
		info.justifyH = "CENTER";
		info.notCheckable = 1;
		info.notClickable = 1;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.SETKEY];
		info.notCheckable = 1;
		info.value = MMC.SETKEY;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.DELKEY];
		info.notCheckable = 1;
		info.value = MMC.DELKEY;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.YELLKEY];
		info.notCheckable = 1;
		info.value = MMC.YELLKEY;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = "-----------------------";
		info.justifyH = "CENTER";
		info.notCheckable = 1;
		info.notClickable = 1;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.BINDASSIGNITEM];
		info.notCheckable = 1;
		info.value = MMC.BINDASSIGNITEM;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.ENABLE];
		info.notCheckable = 1;
		info.value = MMC.ENABLE;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.VIEWQUEST];
		info.notCheckable = 1;
		info.value = MMC.VIEWQUEST;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.DISABLE];
		info.notCheckable = 1;
		info.value = MMC.DISABLE;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = "Add new quest";
		info.notCheckable = 1;
		info.func = CommonersQuest.QuestEdit.QuestAddNew;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.EDITQUEST];
		info.notCheckable = 1;
		info.value = MMC.EDITQUEST;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.EDITREPREQ];
		info.notCheckable = 1;
		info.value = MMC.EDITREPREQ;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.EDITREWARD];
		info.notCheckable = 1;
		info.value = MMC.EDITREWARD;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = "-----------------------";
		info.justifyH = "CENTER";
		info.notCheckable = 1;
		info.notClickable = 1;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.COPYQUEST];
		info.notCheckable = 1;
		info.value = MMC.COPYQUEST;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.DELETEQUEST];
		info.notCheckable = 1;
		info.value = MMC.DELETEQUEST;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.UNDELETEQUEST];
		info.notCheckable = 1;
		info.value = MMC.UNDELETEQUEST;
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, iLevelOut);

		return
	end

	if (iLevelIn == 2) then
		if (oParent == nil) or (type(oParent) ~= "number") then
			return
		end

		if ((oParent >= MMC.ENABLE) and (oParent <= MMC.EDITREWARD) or
		    (oParent >= MMC.COPYQUEST) and (oParent <= MMC.UNDELETEQUEST) or
		    (oParent >= MMC.SETKEY) and (oParent <= MMC.YELLKEY)) then
			-- Enable: Enable = false und Locked = false
			-- Disable: Enable = true

			local	k, v;
			for k, v in pairs(CommonersQuest.QuestDB) do
				local	oStateGlobal, oStatePerChar = CQH.InitStateGiver(v);
				if (v.ID < 1000000) then
					oStateGlobal.Locked = true;	-- premade quests, just to be on the safe side
				end

				local	bShow, bOk, bArrow = true;
				if (oParent == MMC.ENABLE) then
					bOk = (oStatePerChar.Enabled ~= true);
					if (bOk) then
						bOk = CommonersQuest.ValidateQuest(v.ID);
					end
				elseif (oParent == MMC.VIEWQUEST) then
					bOk = true;
				elseif (oParent == MMC.DISABLE) then
					bOk = (oStatePerChar.Enabled == true);
				elseif ((oParent == MMC.EDITQUEST) or
					(oParent == MMC.EDITREPREQ)) then
					bShow = false;	-- can't modify default quests!
				elseif (oParent == MMC.EDITREWARD) then
					bOk = true;
					bArrow = true;
				elseif (oParent == MMC.COPYQUEST) then
					bOk = true;
				elseif (oParent == MMC.DELETEQUEST) then
					bOk = true;
				elseif (oParent == MMC.UNDELETEQUEST) then
					bOk = true;
				elseif (oParent == MMC.SETKEY) then
					bOk = oStateGlobal.Key == nil;
				elseif ((oParent == MMC.DELKEY) or
					(oParent == MMC.YELLKEY)) then
					bOk = oStateGlobal.Key ~= nil;
				end

				-- deleted + !showdeleted or !deleted and showdeleted
				local	bDeleted = oStateGlobal.Deleted == true;
				if (bDeleted == (oParent ~= MMC.UNDELETEQUEST)) then
					bShow = false;
				end

				if (bShow and (v.ID < 1000000)) then
					info = {};
					info.text = "Quest" .. CQH.QuestToPseudoLink(v.ID, v.Title);
					info.notCheckable = 1;
					info.value = v.ID * 16 + oParent;
					if (bArrow) then
						info.hasArrow = true;
					else
						info.func = CommonersQuest.LDBMenu.QuestActionClicked;
						info.arg1 = oParent;
						info.arg2 = v.ID;
					end
					if (not bOk) then
						info.disabled = 1;
					end
					if (oParent == MMC.ENABLE) then
						info.notCheckable = nil;
						if (oStatePerChar.Enabled) then
							info.checked = 1;
						end
					end
					UIDropDownMenu_AddButton(info, iLevelOut);
				end
			end

			for k, v in pairs(CQDataGlobal.CustomQuests) do
				local	oStateGlobal, oStatePerChar = CQH.InitStateGiver(v);
				local	bShow, bOk, bArrow = true;
				if (oParent == MMC.ENABLE) then
					bOk = (oStatePerChar.Enabled ~= true);
					if (bOk) then
						bOk = CommonersQuest.ValidateQuest(v.ID);
					end
				elseif (oParent == MMC.VIEWQUEST) then
					bShow = (oStateGlobal.Locked == true);
					bOk = true;
				elseif (oParent == MMC.DISABLE) then
					bOk = (oStatePerChar.Enabled == true);
				elseif ((oParent == MMC.EDITQUEST) or
					(oParent == MMC.EDITREPREQ)) then
					bShow = (oStateGlobal.Locked ~= true);
					bOk = true;
					bArrow = oParent == MMC.EDITREPREQ;
				elseif (oParent == MMC.EDITREWARD) then
					bOk = true;
					bArrow = true;
				elseif (oParent == MMC.COPYQUEST) then
					bOk = true;
				elseif (oParent == MMC.DELETEQUEST) then
					bOk = true;
				elseif (oParent == MMC.UNDELETEQUEST) then
					bOk = true;
				elseif (oParent == MMC.SETKEY) then
					bOk = oStateGlobal.Key == nil;
				elseif ((oParent == MMC.DELKEY) or
					(oParent == MMC.YELLKEY)) then
					bOk = oStateGlobal.Key ~= nil;
				end

				-- deleted + !showdeleted or !deleted and showdeleted
				local	bDeleted = oStateGlobal.Deleted == true;
				if (bDeleted == (oParent ~= MMC.UNDELETEQUEST)) then
					bShow = false;
				end

				if (bShow) then
					info = {};
					info.text = "Quest" .. CQH.QuestToPseudoLink(v.ID, v.Title);
					info.notCheckable = 1;
					info.value = v.ID * 16 + oParent;
					if (bArrow) then
						info.hasArrow = true;
					else
						info.func = CommonersQuest.LDBMenu.QuestActionClicked;
						info.arg1 = oParent;
						info.arg2 = v.ID;
					end
					if (not bOk) then
						info.disabled = 1;
					end
					if (oParent == MMC.ENABLE) then
						info.notCheckable = nil;
						if (oStatePerChar.Enabled) then
							info.checked = 1;
						end
					end
					UIDropDownMenu_AddButton(info, iLevelOut);
				end
			end
		end

		if (oParent == MMC.BINDASSIGNITEM) then
			local	bAll, sBags, iBag = true, "";
			for iBag = 0, 4 do
				if (IsBagOpen(iBag)) then
					bAll = false;
					sBags = sBags .. " " .. (iBag + 1);
				end
			end

			if (bAll == false) then
				info = {};
				info.text = "Only showing items from open bags" .. sBags;
				info.isTitle = 1;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, iLevelOut);
			end

			-- build a list of all items on the player that are not bound
			for iBag = 0, 4 do
				if (bAll or IsBagOpen(iBag)) then
					local	iSlotCnt, iSlot = GetContainerNumSlots(iBag);
					for iSlot = 1, iSlotCnt do
						local	sItem = GetContainerItemLink(iBag, iSlot);
						if (sItem and string.match(sItem, "(item:%d+)")) then
							local	sItemLink = string.match(sItem, "|H(item[:%d%-]+)|h");
							sItemLink = CQH.StripLevelFromItemLink(sItemLink);
							if (CQH.ValidForBinding(sItemLink)) then
								local	bOk = true;
								CommonersQuestScanningTooltip:ClearLines()
								CommonersQuestScanningTooltip:SetBagItem(iBag, iSlot);
								local	iLineCnt, iLine = CommonersQuestScanningTooltip:NumLines();
								for iLine = 1, iLineCnt do
									local	sLine, k, v = getglobal("CommonersQuestScanningTooltipTextLeft" .. iLine):GetText();
									for k, v in pairs(CommonersQuest.Strings.Item) do
										if (string.match(sLine, v)) then
											bOk = false;
										end
									end
								end

								if (bOk) then
									info = {};
									info.text = "Bag " .. (iBag + 1) .. ", Slot " .. iSlot .. ": " .. sItem;
									info.notCheckable = 1;
									info.value = { Bag = iBag, Slot = iSlot, Item = sItemLink };
									info.hasArrow = true;
									UIDropDownMenu_AddButton(info, iLevelOut);
								end
							end
						end
					end
				end
			end
		end

		return
	end

	if (iLevelIn == 3) then
		if (oParent == nil) then
			return
		end

		if (type(oParent) == "number") then
			local	iCmd = oParent % 16;
			local	iQuest = (oParent - iCmd) / 16;
			if (iCmd == MMC.EDITREPREQ) then
				local	oQuest, k, v;
				for k, v in pairs(CQDataGlobal.CustomQuests) do
					if (v.ID == iQuest) then
						oQuest = v;
						break
					end
				end

				-- repeatability
				info = {};
				info.value = { Kind = "PreReq", Quest = iQuest, Req = "Repeat" };
				info.text = "Repeatability";
				info.notCheckable = 1;
				info.hasArrow = true;
				UIDropDownMenu_AddButton(info, iLevelOut);

				info = {};
				info.text = "Pre-requirements:";
				info.isTitle = 1;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, iLevelOut);

				-- faction
				info = {};
				info.value = { Kind = "PreReq", Quest = iQuest, Req = "Faction" };
				info.text = "Faction";
				info.notCheckable = 1;
				info.hasArrow = true;
				UIDropDownMenu_AddButton(info, iLevelOut);

				-- level
				info = {};
				if (oQuest.ContractPreReq.MinLevel) then
					info.text = "Min. level: " .. oQuest.ContractPreReq.MinLevel .. " (1 to reset)";
				else
					info.text = "Min. level";
				end
				info.notCheckable = 1;
				info.func = CommonersQuest.LDBMenu.PreReqLevel;
				info.arg1 = iQuest; 
				info.arg2 = false;
				UIDropDownMenu_AddButton(info, iLevelOut);
				info = {};
				if (oQuest.ContractPreReq.MaxLevel) then
					info.text = "Max. level: " .. oQuest.ContractPreReq.MaxLevel .. " (" .. CommonersQuest.MaxLevel .. " to reset)";
				else
					info.text = "Max. level";
				end
				info.notCheckable = 1;
				info.func = CommonersQuest.LDBMenu.PreReqLevel;
				info.arg1 = iQuest; 
				info.arg2 = true;
				UIDropDownMenu_AddButton(info, iLevelOut);

				-- class
				info = {};
				info.value = { Kind = "PreReq", Quest = iQuest, Req = "Class" };
				info.text = "Class";
				info.notCheckable = 1;
				info.hasArrow = true;
				UIDropDownMenu_AddButton(info, iLevelOut);

				-- race
				info = {};
				info.value = { Kind = "PreReq", Quest = iQuest, Req = "Race" };
				info.text = "Race";
				info.notCheckable = 1;
				info.hasArrow = true;
				UIDropDownMenu_AddButton(info, iLevelOut);

				-- gender
				info = {};
				info.value = { Kind = "PreReq", Quest = iQuest, Req = "Gender" };
				info.text = "Gender";
				info.notCheckable = 1;
				info.hasArrow = true;
				UIDropDownMenu_AddButton(info, iLevelOut);

				-- preQs
				info = {};
				info.value = { Kind = "PreReq", Quest = iQuest, Req = "Quests" };
				info.text = "Completed quest(s)";
				info.notCheckable = 1;
				info.hasArrow = true;
				UIDropDownMenu_AddButton(info, iLevelOut);
			end

			if (iCmd == MMC.EDITREWARD) then
				local	oRewards = CQDataGlobal.Rewards[iQuest];
				if (oRewards == nil) then
					CQH.InitRewardContainer(iQuest);
				else
					local	k, v;
					for k, v in pairs(oRewards) do
						info = {};
						info.notCheckable = 1;

						CQH.RewardCheckLock(v);

						if (v.State.Locked) then
							info.disabled = 1;
							info.text = "Reward set " .. k .. ": LOCKED";
						else
							info.text = "Edit reward set: " .. k;
							info.func = CommonersQuest.LDBMenu.RewardSetEdit;
							info.arg1 = iQuest;
							info.arg2 = k;
						end
						UIDropDownMenu_AddButton(info, iLevelOut);
					end
				end

				info = {};
				info.text = MMT[MMC.REWARDSETADDNEW];
				info.notCheckable = 1;
				info.func = CommonersQuest.LDBMenu.RewardSetAddNew;
				info.arg1 = iQuest;
				UIDropDownMenu_AddButton(info, iLevelOut);
			end

			return
		end

		if (type(oParent) == "table") then
			-- { Bag = iBag, Slot = iSlot, Item = sItem }
			local	oItemRef = oParent;
			if (CQDataItems[oItemRef.Item]) then
				local	oInfo, bCanUnbind = CQDataItems[oItemRef.Item];

				local	bCanUnbind, bShowUnbind;
				if (oInfo.BindingItemCandidate) then
					info = {};
					info.text = "Candidate for '" .. CQH.QuestToPseudoLink(oInfo.QuestID) .. "'";
					bShowUnbind = true;
					bCanUnbind = (oInfo.Giver == UnitName("player"));
					if (not bCanUnbind) then
						info.text = info.text .. " given by " .. oInfo.Giver;
					end
					info.isTitle = 1;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, iLevelOut);
				end

				if (bShowUnbind) then
					info = {};
					info.text = "Withdraw \"binding item\" reserved for player " .. oInfo.Taker;
					info.notCheckable = 1;
					if (not bCanUnbind) then
						info.disabled = 1;
					end
					info.func = CommonersQuest.LDBMenu.BindingItemUnassign;
					info.arg1 = oParent;
					info.arg2 = { Taker = oInfo.Taker, QuestID = oInfo.QuestID };
					UIDropDownMenu_AddButton(info, iLevelOut);
				end
			else
				local	sChar, oChar;
				for sChar, oChar in pairs(CQData) do
					local	iIndex, iQuestID;
					for iQuestID, iRequestedAt in pairs(oChar.QuestsRequestedToGive) do
						DEFAULT_CHAT_FRAME:AddMessage("[CQ] checking " .. iQuestID .. "...");
						if ((oChar.QuestsGiven[iQuestID] == nil) and
						    (oChar.RewardsReserved[iQuestID] ~= nil)) then
							local	sBindingItem = oChar.RewardsReserved[iQuestID].BindingItemCandidate;
							if (sBindingItem == nil) then
								info = {};
								info.text = "'" .. CQH.QuestToPseudoLink(iQuestID) .. "' requested by " .. sChar;
								info.notCheckable = 1;
								info.func = CommonersQuest.LDBMenu.BindingItemAssign;
								info.arg1 = oItemRef;
								info.arg2 = { Taker = sChar, QuestID = iQuestID };
								UIDropDownMenu_AddButton(info, iLevelOut);
							end
						end
					end
				end
			end
		end
	end

	if (iLevelIn == 4) then
		if (oParent == nil) then
			return
		end

		if (type(oParent) == "table") then
			-- info.value = { Kind = "PreReq", Quest = iQuest, Cmd = 1 };
			local	oData  = oParent;
			local	oQuest, k, v;
			for k, v in pairs(CQDataGlobal.CustomQuests) do
				if (v.ID == oData.Quest) then
					oQuest = v;
					break
				end
			end

			if (oQuest == nil) then
				return
			end

			if (oData.Kind and (oData.Kind == "PreReq")) then
				-- Repeatability
				if (oData.Req == "Repeat") then
					local	iRepeatable = oQuest.ContractPreReq.Repeatable or -1;

					info = {};
					info.text = "Never repeatable";
					info.func = CommonersQuest.LDBMenu.PreReqRepeat;
					info.arg1 = oData.Quest;
					info.arg2 = -1;
					if (info.arg2 == iRepeatable) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "Always repeatable";
					info.func = CommonersQuest.LDBMenu.PreReqRepeat;
					info.arg1 = oData.Quest;
					info.arg2 = 0;
					if (info.arg2 == iRepeatable) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "Daily";
					info.func = CommonersQuest.LDBMenu.PreReqRepeat;
					info.arg1 = oData.Quest;
					info.arg2 = 1;
					if (info.arg2 == iRepeatable) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "Weekly";
					info.func = CommonersQuest.LDBMenu.PreReqRepeat;
					info.arg1 = oData.Quest;
					info.arg2 = 7;
					if (info.arg2 == iRepeatable) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "Fortnightly";
					info.func = CommonersQuest.LDBMenu.PreReqRepeat;
					info.arg1 = oData.Quest;
					info.arg2 = 14;
					if (info.arg2 == iRepeatable) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "Monthly";
					info.func = CommonersQuest.LDBMenu.PreReqRepeat;
					info.arg1 = oData.Quest;
					info.arg2 = 30;
					if (info.arg2 == iRepeatable) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "Yearly";
					info.func = CommonersQuest.LDBMenu.PreReqRepeat;
					info.arg1 = oData.Quest;
					info.arg2 = 365;
					if (info.arg2 == iRepeatable) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);
				end

				-- Faction
				if (oData.Req == "Faction") then
					local	sFaction = oQuest.ContractPreReq.Faction or "Any";

					info = {};
					info.text = "Alliance";
					info.func = CommonersQuest.LDBMenu.PreReqFaction;
					info.arg1 = oData.Quest;
					info.arg2 = "Alliance";
					if ((sFaction == "Any") or (sFaction == info.arg2)) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "Horde";
					info.func = CommonersQuest.LDBMenu.PreReqFaction;
					info.arg1 = oData.Quest;
					info.arg2 = "Horde";
					if ((sFaction == "Any") or (sFaction == info.arg2)) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);
				end

				-- Class (using tables from Karma...)
				if (oData.Req == "Class") then
					info = {};
					info.text = "Specific classes:";
					info.isTitle = 1;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, iLevelOut);

					local	k, v;
					for k, v in pairs(RAID_CLASS_COLORS) do
						info = {};
						info.text = CommonersQuest.Strings.Class.Male[k];
						info.func = CommonersQuest.LDBMenu.PreReqClass;
						info.arg1 = oData.Quest;
						info.arg2 = k;
						if (oQuest.ContractPreClass and oQuest.ContractPreClass[info.arg2]) then
							info.checked = 1;
						end
						UIDropDownMenu_AddButton(info, iLevelOut);
					end

					info = {};
					info.text = "All classes:";
					info.isTitle = 1;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "All classes";
					info.func = CommonersQuest.LDBMenu.PreReqClass;
					info.arg1 = oData.Quest;
					info.arg2 = nil;
					if (oQuest.ContractPreClass == nil) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);
				end

				-- Race (using tables from Karma...)
				if (oData.Req == "Race") then
					info = {};
					info.text = "Specific races:";
					info.isTitle = 1;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, iLevelOut);

					local	k, v;
					for k, v in pairs(CommonersQuest.Strings.Race.Alliance.Male) do
						info = {};
						info.text = v;
						info.func = CommonersQuest.LDBMenu.PreReqRace;
						info.arg1 = oData.Quest;
						info.arg2 = k;
						if (oQuest.ContractPreRace and oQuest.ContractPreRace[info.arg2]) then
							info.checked = 1;
						end
						UIDropDownMenu_AddButton(info, iLevelOut);
					end
					for k, v in pairs(CommonersQuest.Strings.Race.Horde.Male) do
						info = {};
						info.text = v;
						info.func = CommonersQuest.LDBMenu.PreReqRace;
						info.arg1 = oData.Quest;
						info.arg2 = k;
						if (oQuest.ContractPreRace and oQuest.ContractPreRace[info.arg2]) then
							info.checked = 1;
						end
						UIDropDownMenu_AddButton(info, iLevelOut);
					end

					info = {};
					info.text = "All races:";
					info.isTitle = 1;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "All races";
					info.func = CommonersQuest.LDBMenu.PreReqRace;
					info.arg1 = oData.Quest;
					info.arg2 = nil;
					if (oQuest.ContractPreRace == nil) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);
				end

				-- Gender
				if (oData.Req == "Gender") then
					info = {};
					info.text = "Male";
					info.func = CommonersQuest.LDBMenu.PreReqSex;
					info.arg1 = oData.Quest;
					info.arg2 = 2;
					if (oQuest.ContractPreReq.Gender ~= 3) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);

					info = {};
					info.text = "Female";
					info.func = CommonersQuest.LDBMenu.PreReqSex;
					info.arg1 = oData.Quest;
					info.arg2 = 3;
					if (oQuest.ContractPreReq.Gender ~= 2) then
						info.checked = 1;
					end
					UIDropDownMenu_AddButton(info, iLevelOut);
				end

				-- Quests
				if (oData.Req == "Quests") then
					local	oQIDs = {};
					if (oQuest.ContractPreQ) then
						local	k, v;
						for k, v in pairs(oQuest.ContractPreQ) do
							oQIDs[v] = 1;
						end
					end

					local	k, v;
					for k, v in pairs(CommonersQuest.QuestDB) do
						if (v.ID < 1000000) then
							info = {};
							info.text = CQH.QuestToPseudoLink(v.ID, v.Title);
							info.func = CommonersQuest.LDBMenu.PreReqQuest;
							info.arg1 = oData.Quest;
							info.arg2 = v.ID;
							if (oQIDs[v.ID] == 1) then
								info.checked = 1;
							end
							UIDropDownMenu_AddButton(info, iLevelOut);
						end
					end

					for k, v in pairs(CQDataGlobal.CustomQuests) do
						if (v.ID ~= oQuest.ID) then
							info = {};
							info.text = CQH.QuestToPseudoLink(v.ID, v.Title);
							info.func = CommonersQuest.LDBMenu.PreReqQuest;
							info.arg1 = oData.Quest;
							info.arg2 = v.ID;
							if (oQIDs[v.ID] == 1) then
								info.checked = 1;
							end
							UIDropDownMenu_AddButton(info, iLevelOut);
						end
					end
				end
			end
		end
	end
end

CommonersQuest.LDBMenu.LevelRange = {};

--[[
function	CommonersQuest.LDBMenu.LevelRange.SplitStack(oFrame, iSplit)
	CommonersQuestSplitAnchorframe:Hide();
	CommonersQuestSplitAnchorframe.SplitStack = nil;

	local	iQuest = CommonersQuest.LDBMenu.LevelRange.oData.iQuest;
	local	bMax   = CommonersQuest.LDBMenu.LevelRange.oData.bMax;

	CommonersQuest.LDBMenu.LevelRange.Set(iQuest, bMax, iSplit);
end
]]--

function	CommonersQuest.LDBMenu.LevelRange.Slider(oSlider, oData)
	CommonersQuest.Slider.Reset()

	local	iQuest = oData.iQuest;
	local	bMax   = oData.bMax;
	local	iPos   = oSlider:GetValue();

	CommonersQuest.LDBMenu.LevelRange.Set(iQuest, bMax, iPos);
end

function	CommonersQuest.LDBMenu.LevelRange.Set(iQuest, bMax, iValue)
	local	oQuest, k, v;
	for k, v in pairs(CQDataGlobal.CustomQuests) do
		if (v.ID == iQuest) then
			oQuest = v;
			break
		end
	end

	if (oQuest == nil) then
		return
	end

	if (bMax) then
		if (oQuest.ContractPreReq.MinLevel) then
			if (iValue < oQuest.ContractPreReq.MinLevel) then
				return;
			end
		end

		if (iValue == CommonersQuest.MaxLevel) then
			oQuest.ContractPreReq.MaxLevel = nil;
		else
			oQuest.ContractPreReq.MaxLevel = iValue;
		end

		CQH.CommChat("DbgInfo", "Quest", "Changed max. level for " .. oQuest.ID .. " to " .. iValue .. ".");
	else
		if (oQuest.ContractPreReq.MaxLevel) then
			if (iValue > oQuest.ContractPreReq.MaxLevel) then
				return;
			end
		end

		if (iValue == 1) then
			oQuest.ContractPreReq.MinLevel = nil;
		else
			oQuest.ContractPreReq.MinLevel = iValue;
		end

		CQH.CommChat("DbgInfo", "Quest", "Changed min. level for " .. oQuest.ID .. " to " .. iValue .. ".");
	end
end

function	CommonersQuest.LDBMenu.PreReqLevel(oFrame, iQuest, bMax)
	local	oQuest, k, v;
	for k, v in pairs(CQDataGlobal.CustomQuests) do
		if (v.ID == iQuest) then
			oQuest = v;
			break
		end
	end

	if (oQuest == nil) then
		return
	end

	local	iMin = oQuest.ContractPreReq.MinLevel or                       1;
	local	iMax = oQuest.ContractPreReq.MaxLevel or CommonersQuest.MaxLevel;

	local	x, y = oFrame:GetLeft(), oFrame:GetBottom();

--[[
	CQH.CommChat("DbgInfo", "Quest", "Anchorframe at " .. x .. ", " .. y .. ".");

	CommonersQuestSplitAnchorframe:SetScale(oFrame:GetEffectiveScale());
	CommonersQuestSplitAnchorframe:ClearAllPoints();
	CommonersQuestSplitAnchorframe:SetPoint("BOTTOMLEFT", x, y);
	CommonersQuestSplitAnchorframe:SetWidth(3);
	CommonersQuestSplitAnchorframe:SetHeight(3);
	CommonersQuestSplitAnchorframe:Show();

	CommonersQuest.LDBMenu.LevelRange.oData = { bMax = bMax, iQuest = iQuest };
	CommonersQuestSplitAnchorframe.SplitStack = CommonersQuest.LDBMenu.LevelRange.SplitStack;
	if (bMax) then
		CQH.CommChat("DbgInfo", "Quest", "Opening 'split' frame to set max. level for " .. oQuest.ID .. " (max = " .. CommonersQuest.MaxLevel .. ").");
		OpenStackSplitFrame(CommonersQuest.MaxLevel, CommonersQuestSplitAnchorframe, "CENTER", "CENTER");
	else
		CQH.CommChat("DbgInfo", "Quest", "Opening 'split' frame to set min. level for " .. oQuest.ID .. " (max = " .. iMax .. ").");
		OpenStackSplitFrame(iMax, CommonersQuestSplitAnchorframe, "CENTER", "CENTER");
	end
]]--

	local	sText2, sText1 = CQH.QuestToPseudoLink(oQuest.ID, oQuest.Title);
	local	oData = { iQuest = iQuest, bMax = bMax };
	if (bMax) then
		iMax = CommonersQuest.MaxLevel;
		iCurr = oQuest.ContractPreReq.MaxLevel or iMax;
		sText1 = "Setting max. level for quest:";
	else
		iMin =                       1;
		iCurr = oQuest.ContractPreReq.MinLevel or iMin;
		sText1 = "Setting min. level for quest:";
	end

	CloseDropDownMenus();
	CommonersQuest.Slider.Init(sText1, sText2, iMin, iMax, iCurr, x, y, CommonersQuest.LDBMenu.LevelRange.Slider, oData);
end

function	CommonersQuest.LDBMenu.PreReqRepeat(oFrame, iQuest, iRepeat)
	local	oQuest, k, v;
	for k, v in pairs(CQDataGlobal.CustomQuests) do
		if (v.ID == iQuest) then
			oQuest = v;
			break
		end
	end

	if (oQuest == nil) then
		return
	end

	oQuest.ContractPreReq.Repeatable = iRepeat;

	CQH.CommChat("DbgInfo", "Quest", "Changed repeatability for " .. oQuest.ID .. " to " .. iRepeat .. ".");
end

function	CommonersQuest.LDBMenu.PreReqFaction(oFrame, iQuest, sFaction)
	local	oQuest, k, v;
	for k, v in pairs(CQDataGlobal.CustomQuests) do
		if (v.ID == iQuest) then
			oQuest = v;
			break
		end
	end

	if (oQuest == nil) then
		return
	end

	local	OtherFaction = { ["Alliance"] = "Horde", ["Horde"] = "Alliance" };
	local	sFactionOld = oQuest.ContractPreReq.Faction or "Any";
	if (sFactionOld == "Any") then
		oQuest.ContractPreReq.Faction = OtherFaction[sFaction];
	elseif (sFactionOld ~= sFaction) then
		oQuest.ContractPreReq.Faction = "Any";
	end

	CQH.CommChat("DbgInfo", "Quest", "Changed faction for " .. oQuest.ID .. " to " .. oQuest.ContractPreReq.Faction .. ".");
end

function	CommonersQuest.LDBMenu.PreReqClass(oFrame, iQuest, sClass)
	local	oQuest, k, v;
	for k, v in pairs(CQDataGlobal.CustomQuests) do
		if (v.ID == iQuest) then
			oQuest = v;
			break
		end
	end

	if (oQuest == nil) then
		return
	end

	if (sClass == nil) then
		oQuest.ContractPreClass = nil;
	else
		CQH.InitTable(oQuest, "ContractPreClass");
		oQuest.ContractPreClass[sClass] = not (oQuest.ContractPreClass[sClass] == true);
	end

	CQH.CommChat("DbgInfo", "Quest", "Changed class for " .. oQuest.ID .. " to " .. CQH.TableToString(oQuest.ContractPreClass) .. ".");
end

function	CommonersQuest.LDBMenu.PreReqRace(oFrame, iQuest, sRace)
	local	oQuest, k, v;
	for k, v in pairs(CQDataGlobal.CustomQuests) do
		if (v.ID == iQuest) then
			oQuest = v;
			break
		end
	end

	if (oQuest == nil) then
		return
	end

	if (sRace == nil) then
		oQuest.ContractPreRace = nil;
	else
		CQH.InitTable(oQuest, "ContractPreRace");
		oQuest.ContractPreRace[sRace] = not (oQuest.ContractPreRace[sRace] == true);
	end

	CQH.CommChat("DbgInfo", "Quest", "Changed race for " .. oQuest.ID .. " to " .. CQH.TableToString(oQuest.ContractPreRace) .. ".");
end

function	CommonersQuest.LDBMenu.PreReqSex(oFrame, iQuest, iSex)
	local	oQuest, k, v;
	for k, v in pairs(CQDataGlobal.CustomQuests) do
		if (v.ID == iQuest) then
			oQuest = v;
			break
		end
	end

	if (oQuest == nil) then
		return
	end

	if (oQuest.ContractPreReq.Gender == nil) then
		oQuest.ContractPreReq.Gender = 5 - iSex;
	elseif (oQuest.ContractPreReq.Gender ~= iSex) then
		oQuest.ContractPreReq.Gender = nil;
	end

	CQH.CommChat("DbgInfo", "Quest", "Changed gender for " .. oQuest.ID .. " to " .. CQH.AllToString(oQuest.ContractPreReq.Gender) .. ".");
end

function	CommonersQuest.LDBMenu.PreReqQuest(oFrame, iQuest, iQuestPre)
	local	oQuest, k, v;
	for k, v in pairs(CQDataGlobal.CustomQuests) do
		if (v.ID == iQuest) then
			oQuest = v;
			break
		end
	end

	if (oQuest == nil) then
		return
	end

	local	oQIDs = {};
	if (oQuest.ContractPreQ) then
		local	k, v;
		for k, v in pairs(oQuest.ContractPreQ) do
			oQIDs[v] = k;
		end
	end

	if (oQIDs[iQuestPre]) then
		tremove(oQuest.ContractPreQ, oQIDs[iQuestPre]);
		if (CQH.TableIsEmpty(oQuest.ContractPreQ)) then
			oQuest.ContractPreQ = nil;
		end
	else
		CQH.InitTable(oQuest, "ContractPreQ");
		tinsert(oQuest.ContractPreQ, iQuestPre);
	end

	CQH.CommChat("DbgInfo", "Quest", "Changed pre-quest(s) for " .. oQuest.ID .. " to " .. CQH.TableToString(oQuest.ContractPreQ) .. ".");
end

-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --
-- ########################################################################## --

function	CommonersQuest.SlashCmdsInit()
	SLASH_COMMONERSQUEST1 = "/commonersquest";
	SlashCmdList["COMMONERSQUEST"] = CommonersQuest.SlashCmdHandler;

	CommonersQuest.SlashCmdMap = {
		help = CommonersQuest.SlashCmdHelp,
		new = CommonersQuest.SlashCmdNew,
		test = CommonersQuest.SlashCmdTest,
		}
end

function	CommonersQuest.SlashCmdHandler(cmdline)
	local	iCounter = 0;
	local	args = {};

	local	w;
	for w in string.gmatch(cmdline, "%S+") do
		iCounter = iCounter+1;
		args[iCounter] = w;
	end

	if (CommonersQuest.SlashCmdMap[args[1]]) then
		CommonersQuest.SlashCmdMap[args[1]](args, iCounter);
	else
		DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Unknown command >" .. cmdline .. "<");
	end
end

function	CommonersQuest.SlashCmdHelp(args, iCnt)
	local	sCmds, k, v = "";
	for k, v in pairs(CommonersQuest.SlashCmdMap) do
		sCmds = sCmds .. " " .. k;
	end
	DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Commands are:" .. sCmds);
	DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: \"binding item\" - This must be a non-stacking item of common or lower quality that is given from the quest giver to the quest taker as a token. When the quest is completed, the item is to be handed back in exchange for the quest reward.");
end

function	CommonersQuest.SlashCmdNew(args, iCnt)
	if (args[2] == "setstring") then
		if (iCnt > 4) then
			local	iQuestID = tonumber(args[3]);
			local	Field = args[4];

			local	oQuest, k, v;
			for k, v in pairs(CQDataGlobal.CustomQuests) do
				if (v.ID == iQuestID) then
					oQuest = v;
					break;
				end
			end

			if (oQuest) then
				local	sValue, i = args[5];
				for i = 6, iCnt do
					sValue = sValue .. " " .. args[i];
				end
				local	sLen, sOut = strlen(sValue), "";
				i = 0;
				while (i < sLen) do
					i = i + 1;
					local	sChar = strsub(sValue, i, i);
					if (sChar == "\\") then
						local	sNext = strsub(sValue, i + 1, i + 1);
						if (sNext == "n") then
							sOut = sOut .. "\n";
							i = i + 1;
						else
							sOut = sOut .. strsub(sValue, i, i);
						end
					else
						sOut = sOut .. strsub(sValue, i, i);
					end
				end

				if (sOut == "nil") then
					DEFAULT_CHAT_FRAME:AddMessage("Resetting string " .. Field .. ".");
					oQuest[Field] = nil;
				else
					DEFAULT_CHAT_FRAME:AddMessage("Setting string " .. Field .. " to <" .. sOut .. ">");
					oQuest[Field] = sOut;
				end
			end
		end
	elseif (args[2] == "reward") then
		if (iCnt > 4) then
			local	iQuestID = tonumber(args[3]);

			local	oQuest, k, v;
			for k, v in pairs(CQDataGlobal.CustomQuests) do
				if (v.ID == iQuestID) then
					oQuest = v;
					break;
				end
			end

			if (oQuest) then
				CQH.InitTable(oQuest, "Reward");

				local	sAction = args[4];
				if (sAction == "del") and (iCnt > 4) then
					local	iRewardID = tonumber(args[5]);
					if (oQuest.Reward[iRewardID] ~= nil) then
						local	sReward, k, v = "";
						for k, v in pairs(oQuest.Reward[iRewardID]) do
							sReward = sReward .. " [" .. k .. "] = <" .. v .. ">";
						end
						DEFAULT_CHAT_FRAME:AddMessage("Deleted reward " .. iRewardID .. ":" .. sReward);
						oQuest.Reward[iRewardID] = nil;
					end
				elseif (sAction == "add") and (iCnt > 5) then
					local	iRewardID = tonumber(args[5]);
					local	sRewardType = args[6];

					local	bValid, oReward = true, {};
					local	iArgPos = 7;
					local	oMeta = CommonersQuest.DBMetaInfo.QuestFields.RewardEntries.TypeSelector[sRewardType];
					if (oMeta) then
						oReward.Type = sRewardType;

						local	sLast, Mk, Mv;
						for Mk, Mv in pairs(oMeta) do
							if (args[iArgPos] == nil) then
								bValid = false;
								break;
							elseif (args[iArgPos] ~= "nil") then
								local	Argv = args[iArgPos];
								if (Mv == "number") then
									Argv = tonumber(Argv);
								elseif (Mv == "boolean") then
									if (Argv == "true") then
										Argv = true;
									elseif (Argv == "false") then
										Argv = false;
									else
										Argv = nil;
									end
								end
								if (type(Argv) == Mv) then
									oReward[Mk] = Argv;
									sLast = Mk;
								else
									bValid = false;
									break;
								end
							end
							iArgPos = iArgPos + 1;
						end

						if (sLast and (iCnt >= iArgPos)) then
							local	i;
							for i = iArgPos, iCnt do
								oReward[sLast] = oReward[sLast] .. " " .. args[i];
							end
						end

						if (bValid) then
							if (sRewardType == "Item") then
								-- if we got an itemlink, split it out
								-- "|cffffffff|Hitem:769:0:0:0:0:0:0:1643911040:10|h[Brocken Eberfleisch]|h|r"
								--                                          "|c........|Hitem:[%d%-:]+|h%[.+%]|h|r"
								local	sItem = string.match(oReward.Name, "(|c........|Hitem:[%d%-:]+|h%[.+%]|h|r)");
								if (sItem) then
									local	sItemID = string.match(oReward.Name, "item:([%d]+):");
									local	sItemName = string.match(oReward.Name, "%[(.+)%]");
									if (sItemID and sItemName) then
										DEFAULT_CHAT_FRAME:AddMessage("Replacing itemlink with ID and name.");
										oReward.ItemID = tonumber(sItemID);
										oReward.Name = sItemName;
									end
								elseif (string.match(oReward.Name, "(item:[%d]+)")) then
									DEFAULT_CHAT_FRAME:AddMessage("Failed matching itemlink properly. :-(");
								end
							end

							local	sReward, k, v = "";
							for k, v in pairs(oReward) do
								sReward = sReward .. " [" .. k .. "] = <" .. CQH.AllToString(v) .. ">";
							end
							DEFAULT_CHAT_FRAME:AddMessage("Setting reward " .. iRewardID .. ":" .. sReward);
							oQuest.Reward[iRewardID] = oReward;
						else
							local	sReward, k, v = "";
							for k, v in pairs(oMeta) do
								sReward = sReward .. " [" .. k .. " <" .. CQH.AllToString(v) .. ">]";
							end
							DEFAULT_CHAT_FRAME:AddMessage("Failed to add reward. Required data fields for {" .. sRewardType .. "} :" .. sReward);
						end
					else
						local	sTypes, Mk, Mv = "";
						for Mk, Mv in pairs(CommonersQuest.DBMetaInfo.QuestFields.RewardEntries.TypeSelector) do
							sTypes = sTypes .. " " .. Mk;
						end
						DEFAULT_CHAT_FRAME:AddMessage("Invalid reward type. Possible choices:" .. sTypes);
					end
				end
			end
		end
	elseif (args[2] == "require") then
		if (iCnt > 4) then
			local	iQuestID = tonumber(args[3]);

			local	oQuest, k, v;
			for k, v in pairs(CQDataGlobal.CustomQuests) do
				if (v.ID == iQuestID) then
					oQuest = v;
					break;
				end
			end

			if (oQuest) then
				CQH.InitTable(oQuest, "Requirements");

				local	sAction = args[4];
				if (sAction == "del") and (iCnt > 4) then
					local	iRequireID = tonumber(args[5]);
					if (oQuest.Requirements[iRequireID] ~= nil) then
						local	sRequirement, k, v = "";
						for k, v in pairs(oQuest.Requirements[iRequireID]) do
							sRequirement = sRequirement .. " [" .. k .. "] = <" .. v .. ">";
						end
						DEFAULT_CHAT_FRAME:AddMessage("Deleted requirement " .. iRequireID .. ":" .. sRequirement);
						oQuest.sRequirement[iRequireID] = nil;
					end
				elseif (sAction == "add") and (iCnt > 5) then
					local	iRequireID = tonumber(args[5]);
					local	sRequirementType = args[6];

					local	bValid, oRequirement = true, {};
					local	iArgPos = 7;
					local	oMeta = CommonersQuest.DBMetaInfo.QuestFields.RequirementsEntries.TypeSelector[sRequirementType];
					if (oMeta) then
						oRequirement.Type = sRequirementType;

						local	sLast, Mk, Mv;
						for Mk, Mv in pairs(oMeta) do
							if (args[iArgPos] == nil) then
								bValid = false;
								break;
							elseif (args[iArgPos] ~= "nil") then
								local	Argv = args[iArgPos];
								if (Mv == "number") then
									Argv = tonumber(Argv);
								elseif (Mv == "boolean") then
									if (Argv == "true") then
										Argv = true;
									elseif (Argv == "false") then
										Argv = false;
									else
										Argv = nil;
									end
								end
								if (type(Argv) == Mv) then
									oRequirement[Mk] = Argv;
									sLast = Mk;
								else
									bValid = false;
									break;
								end
							end
							iArgPos = iArgPos + 1;
						end

						if (sLast and (iCnt >= iArgPos)) then
							local	i;
							for i = iArgPos, iCnt do
								oRequirement[sLast] = oRequirement[sLast] .. " " .. args[i];
							end
						end

						if (bValid) then
							if (sRequirementType == "Loot") then
								-- if we got an itemlink, split it out
								-- "|cffffffff|Hitem:769:0:0:0:0:0:0:1643911040:10|h[Brocken Eberfleisch]|h|r"
								--                                          "|c........|Hitem:[%d%-:]+|h%[.+%]|h|r"
								local	sItem = string.match(oRequirement.Item, "(|c........|Hitem:[%d%-:]+|h%[.+%]|h|r)");
								if (sItem) then
									local	sItemID = string.match(oRequirement.Item, "item:([%d]+):");
									local	sItemName = string.match(oRequirement.Item, "%[(.+)%]");
									if (sItemID and sItemName) then
										DEFAULT_CHAT_FRAME:AddMessage("Replacing itemlink with ID and name.");
										oRequirement.ItemID = tonumber(sItemID);
										oRequirement.Item = sItemName;
									end
								elseif (string.match(oRequirement.Item, "(item:[%d]+)")) then
									DEFAULT_CHAT_FRAME:AddMessage("Failed matching itemlink properly. :-(");
								end
							end

							local	sRequirement, k, v = "";
							for k, v in pairs(oRequirement) do
								sRequirement = sRequirement .. " [" .. k .. "] = <" .. CQH.AllToString(v) .. ">";
							end
							DEFAULT_CHAT_FRAME:AddMessage("Setting requirement " .. iRequireID .. ":" .. sRequirement);
							oQuest.Requirements[iRequireID] = oRequirement;
						else
							local	sRequirement, k, v = "";
							for k, v in pairs(oMeta) do
								sRequirement = sRequirement .. " [" .. k .. " <" .. CQH.AllToString(v) .. ">]";
							end
							DEFAULT_CHAT_FRAME:AddMessage("Failed to add requirement. Required data fields for {" .. sRequirementType .. "} :" .. sRequirement);
						end
					else
						local	sTypes, Mk, Mv = "";
						for Mk, Mv in pairs(CommonersQuest.DBMetaInfo.QuestFields.RequirementsEntries.TypeSelector) do
							sTypes = sTypes .. " " .. Mk;
						end
						DEFAULT_CHAT_FRAME:AddMessage("Invalid requirement type. Possible choices:" .. sTypes);
					end
				end
			end
		end
	elseif (args[2] == "prerequisite") then
		if (iCnt > 4) then
			local	iQuestID = tonumber(args[3]);

			local	oQuest, k, v;
			for k, v in pairs(CQDataGlobal.CustomQuests) do
				if (v.ID == iQuestID) then
					oQuest = v;
					break;
				end
			end

			if (oQuest) then
				CQH.InitTable(oQuest, "ContractPreReq");

				local	sPreReq = args[4];
				local	oMeta = CommonersQuest.DBMetaInfo.QuestFields.ContractPreReqEntries[sPreReq];
				if (oMeta) then
					if (args[5] == "nil") then
						if (CommonersQuest.DBMetaInfo.QuestFields.ContractPreReqEntriesOptional[sPreReq]) then
							if (oQuest.ContractPreReq[sPreReq]) then
								DEFAULT_CHAT_FRAME:AddMessage("Removing optional prerequisite " .. sTypes .. " (was: " .. oQuest.ContractPreReq[sPreReq] .. ").");
								oQuest.ContractPreReq[sPreReq] = nil;
							end
						else
							DEFAULT_CHAT_FRAME:AddMessage("Prerequisite " .. sTypes .. " is not optional, cannot remove!");
						end
					else
						local	Argv = args[5];
						if (oMeta == "number") then
							Argv = tonumber(Argv);
						elseif (oMeta == "boolean") then
							if (Argv == "true") then
								Argv = true;
							elseif (Argv == "false") then
								Argv = false;
							else
								Argv = nil;
							end
						end
						if (type(Argv) == oMeta) then
							DEFAULT_CHAT_FRAME:AddMessage("Prerequisite " .. sPreReq .. " set to: " .. CQH.AllToString(Argv));
							oQuest.ContractPreReq[sPreReq] = Argv;
						else
							DEFAULT_CHAT_FRAME:AddMessage("Prerequisite " .. sPreReq .. ": Must be type " .. oMeta);
						end
					end
				else
					local	sTypes, Mk, Mv = "";
					for Mk, Mv in pairs(CommonersQuest.DBMetaInfo.QuestFields.ContractPreReqEntries) do
						sTypes = sTypes .. " " .. Mk;
					end
					DEFAULT_CHAT_FRAME:AddMessage("Invalid prerequisite. Possible choices:" .. sTypes);
				end
			end
		end
	elseif (args[2] == "check") then
		if (iCnt == 3) then
			local	iQuestID = tonumber(args[3]);

			local	oQuest, k, v;
			for k, v in pairs(CQDataGlobal.CustomQuests) do
				if (v.ID == iQuestID) then
					oQuest = v;
					break;
				end
			end

			if (oQuest) then
				CommonersQuest.ValidateQuest(oQuest.ID, true);
			end
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("Subcommands: init, set, check");
		DEFAULT_CHAT_FRAME:AddMessage("<init>: initializes new quest container, returning the id.");
		DEFAULT_CHAT_FRAME:AddMessage("<setstring> <id> <field> <value...>: sets quest id string field to value...");
		DEFAULT_CHAT_FRAME:AddMessage("<check> <id>: checks if all required fields are there for a valid quest.");
		DEFAULT_CHAT_FRAME:AddMessage("<require/reward> <id> <del> <#>: deletes requirement/reward # from quest id");
		DEFAULT_CHAT_FRAME:AddMessage("<require/reward> <id> <add> <#> <type> <args for type...>: sets requirement/reward # in quest id to type/args");
		DEFAULT_CHAT_FRAME:AddMessage("prerequisite <id> <prereq> <value>: sets prerequisite prereq to value for quest id");
	end
end

function	CommonersQuest.SlashCmdTest(args, iCnt)
	if (args[2] == "query") and (iCnt == 4) then
		PickupContainerItem(tonumber(args[3]), tonumber(args[4]));
		local	sType, _, sLink = GetCursorInfo();
		if (sType == "item") then
			local	sName, _, _, _, _, _, _, _, _, sTexture = GetItemInfo(sLink);
			local	oItem = { name = sName, texture = sTexture, link = sLink };
			local	sPlayer = UnitName("target") or UnitName("player");
			StaticPopup_Show("COMMONERSQUEST_BIND_ITEM_TO_QUEST", CQH.QuestToPseudoLink(1001), sPlayer, oItem);
		end
	elseif (args[2] == "setitem") then
		if (iCnt < 6) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Invalid args: " .. iCnt);
		else
			local	sDirection = args[3];
			local	sPlayer = args[4];
			if (sPlayer ~= UnitName("player")) then
				DEFAULT_CHAT_FRAME:AddMessage("[CQ] This command is only available for debugging.");
				return
			end

			local	sQuestID = args[5];
			if ((sDirection ~= "in") and (sDirection ~= "out")) or (CQData[sPlayer] == nil) or (tonumber(sQuestID) == nil) then
				DEFAULT_CHAT_FRAME:AddMessage("[CQ] Invalid args: " .. sDirection .. "/" .. sPlayer .. "/" .. sQuestID);
			else
				local	sItem, i = args[6];
				for i = 7, iCnt do
					sItem = sItem .. " " .. args[i];
				end
				local	sItemLink = string.match(sItem, "|H(item[:%d%-]+)|h");
				sItemLink = CQH.StripLevelFromItemLink(sItemLink);
				local	_, _, iQuality, _, _, _, _, iItemStackCount = GetItemInfo(sItemLink);
				DEFAULT_CHAT_FRAME:AddMessage("[CQ] Item " .. sItem .. " => " .. sItemLink .. "@" .. sQuestID .. " - Qual = " .. iQuality
								.. ", Stck = " .. iItemStackCount .. " (iArgs = " .. iCnt .. ")");
				local	iQuestID = tonumber(sQuestID);
				if (sDirection == "out") then
					CQH.InitTable(CQData[sPlayer].QuestsGiven, iQuestID);
					if (CQData[sPlayer].QuestsGiven[iQuestID].BindingItem == nil) then
						CQData[sPlayer].QuestsGiven[iQuestID].BindingItem = sItemLink;
						CQData[sPlayer].QuestsGiven[iQuestID].BindingAt = time();
					else
						DEFAULT_CHAT_FRAME:AddMessage("[CQ] Given quest " .. sQuestID .. " already bound to " .. CQData[sPlayer].QuestsGiven[iQuestID].BindingItem);
					end
				else
					CQH.InitTable(CQData[sPlayer].QuestsCurrent, iQuestID);
					if (CQData[sPlayer].QuestsCurrent[iQuestID].BindingItem == nil) then
						CQData[sPlayer].QuestsCurrent[iQuestID].BindingItem = sItemLink;
						CQData[sPlayer].QuestsCurrent[iQuestID].BindingAt = time();
					else
						DEFAULT_CHAT_FRAME:AddMessage("[CQ] Taken quest " .. sQuestID .. " already bound to " .. CQData[sPlayer].QuestsCurrent[iQuestID].BindingItem);
					end
				end
			end
		end
	elseif (args[2] == "editquest") then
		if (iCnt < 4) then
			DEFAULT_CHAT_FRAME:AddMessage("[CQ] Invalid args: " .. iCnt);
		else
			local	sPlayer = args[3];
			if (sPlayer ~= UnitName("player")) then
				DEFAULT_CHAT_FRAME:AddMessage("[CQ] This command is only available for debugging.");
				return
			end
			local	sQuestID = args[4];
			local	iQuestID = tonumber(sQuestID);
			if (iQuestID < 1000000) then
				DEFAULT_CHAT_FRAME:AddMessage("[CQ] Cannot edit default quests.");
				return
			end

			local	oQuest, k, v;
			for k, v in pairs(CQDataGlobal.CustomQuests) do
				if (v.ID == iQuestID) then
					oQuest = v;
				end
			end

			if (oQuest) then
				if (CommonersQuestFrame:IsShown()) then
					CommonersQuest.FrameMain.Hide();
				end

				CommonersQuestFrame.EditMode = true;
				CommonersQuestFrame.Player = nil;
				CommonersQuest.FrameDetailPanel.Init(oQuest.ID);
			end
		end
	end
end

