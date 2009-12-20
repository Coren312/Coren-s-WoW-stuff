
CommonersQuest.Comm = {};

local	CQData = nil;
local	CQDataX = nil;
local	CQDataGlobal = nil;
local	CQDataItems = nil;

local	CQH = CommonersQuest.Helpers;

function	CommonersQuest.Initializers.Comm(CQDataMain, CQDataXMain, CQDataGlobalMain, CQDataItemsMain)
	CQData = CQDataMain;
	CQDataX = CQDataXMain;
	CQDataGlobal = CQDataGlobalMain;
	CQDataItems = CQDataItemsMain;
end

-- must only get the string once, because salt is already set after first piece!
local	oInfoSplitMostRecent = {};

function	CommonersQuest.HandleCommunication(...)
	local	sAddon, sMsg, sChannel, sFrom = ...;
	if ((sAddon == "COMMONERSQUEST") and (sChannel == "WHISPER")) then
		CQH.CommChat("DbgSpam", "Comm", "<" .. sFrom .. "> -> " .. sMsg);
		CQH.InitTable(CommonersQuest.Version, sFrom);
		CommonersQuest.Version[sFrom].Valid = true;

		if (strsub(sMsg, 1, 1) == "?") then
			if (strsub(sMsg, 2, 6) == "List:") then
				local	sRace, sClass, sSex, sLevel = string.match(sMsg, "%?List:([^:]+):([^:]+):(%d+):(%d+)");
				local	iSex, iLevel;
				if (sSex and sLevel) then
					iSex = tonumber(sSex);
					iLevel = tonumber(sLevel);
				end

				if (iSex and iLevel) then
					-- TODO: check daily.
					local	oGiven, i = {};
					for i = 1, 3 do
						local	oData, bEnabled, bFull;
						if (i == 1) then
							bFull = false;
							if (CQData[sFrom]) then
								oData = CQData[sFrom].QuestsGiven;
							end
							if (oData == nil) then
								oData = {};
							end
						elseif (i == 2) then
							bFull = true;
							bEnabled = true;
							oData = CommonersQuest.QuestDB;
						elseif (i == 3) then
							bFull = true;
							bEnabled = false;
							oData = CommonersQuest.QuestDB;
						end

						local	sIDs, k, v = "";
						for k, v in pairs(oData) do
							local	iModified, iID = 0;
							if (bFull) then
								local	oStateGlobal, oStatePerChar = CQH.InitStateGiver(v);
								-- deleted: don't show at all unless taker already has it
								local	bTakenOrNotDeleted = true;
								if (oStateGlobal.Deleted == true) then
									bTakenOrNotDeleted = false;
									if (CQData[sFrom]) then
										if (CQData[sFrom].QuestsGiven[v.ID]) then
											bTakenOrNotDeleted = true;
										end
									end
								end

								if (bTakenOrNotDeleted and (bEnabled == oStatePerChar.Enabled)) then
									if (CQData[sFrom] and CQData[sFrom].QuestsRequestedToGive[v.ID]) then
										oStateGlobal.Locked = true;		-- ?List command: already requested questid
										iModified = oStateGlobal.Modified;
										iID = v.ID;
										oGiven[iID] = nil;
									elseif (CQH.CanDoQuest(sFrom, v, sRace, sClass, iSex, iLevel)) then
										if (CommonersQuest.ValidateQuest(v.ID, false, sFrom)) then
											oStateGlobal.Locked = true;	-- ?List command: available and CanDo
											iModified = oStateGlobal.Modified;
											iID = v.ID;
											oGiven[iID] = nil;
										else
											CQH.CommChat("DbgInfo", "Quest", "ID " .. v.ID .. ": Quest not valid.");
										end
									else
										CQH.CommChat("DbgInfo", "Quest", "ID " .. v.ID .. ": Quest not available for this faction/race/class/gender/level.");
									end
								end
							else
								local	oQuest = CQH.CharQuestToObj(nil, k);
								if (oQuest) then
									local	oStateGlobal = CQH.InitStateGiver(oQuest);
									oStateGlobal.Locked = true;			-- ?List command: already given
									iModified = oStateGlobal.Modified;
									iID = k;
									oGiven[iID] = 1;
								else
									CQH.CommChat("DbgInfo", "Quest", "ID " .. k .. ": Quest not found?");
								end
							end

							if (iID) then
								if (iID > 1000000) then
									sIDs = sIDs .. ":" .. iID .. "!" .. iModified;
								else
									sIDs = sIDs .. ":" .. iID;
								end
							end
						end

						if (i == 3) then
							local	k, v;
							for k, v in pairs(oGiven) do
								sIDs = sIDs .. ":" .. k .. "!-1";
							end
						end

						CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!List:" .. i .. sIDs, "WHISPER", sFrom);
					end
				end
			elseif (strsub(sMsg, 2, 5) == "Syn:") then
				local	sQuestID, sCookie, sGUID = string.match(sMsg, "%?Syn:(%d+):(%d+):([^:]+)");
				if ((sQuestID ~= nil) and (sCookie ~= nil) and (sGUID ~= nil)) then
					CommonersQuest.PlayerInit(sFrom, sGUID);
					local	iQuestID = tonumber(sQuestID);
					local	iCookie = tonumber(sCookie);

					local	bOk, oRewards, oState, iKey = false;
					if ((CQData[sFrom] == nil) or (CQData[sFrom].RewardsReserved[iQuestID] == nil)) then
						oRewards, oState, iKey = CQH.InitRewards(iQuestID, sFrom);
					end

					if (oRewards and (oState.LockedTo == sFrom) and (oState.Cookie == iCookie)) then
						-- refresh lock
						oState.LockedAt = time();

						local	oRewardsTotals = CQH.CollateRewards(iQuestID, nil, nil, sFrom);
						if (CQH.CheckInventoryForRewardAvailability(iQuestID, sFrom, oRewardsTotals)) then
							CQData[sFrom].QuestsRequestedToGive[iQuestID] = time();
							bOk = true;
						end
					end

					if (bOk) then
						CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?Req:+:" .. iQuestID .. ":" .. iCookie .. ":" .. UnitGUID("player"), "WHISPER", sFrom);
					else
						CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?Req:-:" .. iQuestID .. ":" .. iCookie .. ":#", "WHISPER", sFrom);
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 5) == "Req:") then
				local	sAck, sQuestID, sCookie, sGUID = string.match(sMsg, "%?Req:([%+%-]?):(%d+):(%d+):([^:]+)");
				if (sAck and sQuestID and sCookie and sGUID) then
					local	iQuestID = tonumber(sQuestID);
					local	iCookie = tonumber(sCookie);
					if (iQuestID and iCookie) then
						local	sQuest = CQH.QuestToPseudoLink(iQuestID, nil, sFrom);
						if (sAck == "+") then
							CommonersQuest.PlayerInit(sFrom, sGUID);
							local	iTime = time();
							CQData[sFrom].RewardsPromised[iQuestID].Info.Request.Accepted = iTime;
							CQData[sFrom].QuestsAcknowledgedToTake[iQuestID] = iTime;
							CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Ack:" .. iQuestID .. ":" .. iCookie .. ":" .. UnitGUID("player"), "WHISPER", sFrom);

							local	oGlobalState, k, v;
							for k, v in pairs(CQData[sFrom].QuestsCustom) do
								if (v.ID == iQuestID) then
									oGlobalState = v.State;
								end
							end
							if (oGlobalState and oGlobalState.NoBindingItem) then
								CQH.CommChat("ChatImportant", nil, sFrom .. " accepted the request to complete quest " .. sQuest ..".\nThis quest is flagged as not requiring a binding item, so it's considered taken now.");

								local	sItem = "item:6948:0:0:0:0:0:0:0";	-- Hearthstone
								CQData[sFrom].QuestsAcknowledgedToTake[iQuestID] = nil;

								CQH.InitTable(CQData[sFrom].QuestsCurrent, iQuestID);
								local	oContainer = CQData[sFrom].QuestsCurrent[iQuestID];
								oContainer.BindingItem = sItem;
								oContainer.BindingAt = time();
								oContainer.BindingCompleted = 3;
							else
								CQH.CommChat("ChatImportant", nil, sFrom .. " accepted the request to complete quest " .. sQuest ..".\nThey need to hand you a \"binding item\" now.");
							end
						elseif (sAck == "-") then
							CQH.CommChat("ChatImportant", nil, sFrom .. " declined your request to complete quest " .. sQuest ..".");
						end
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 5) == "Ver:") then
				local	sVersion, sDate = string.match(sMsg, "?Ver:([^:]+):(.+)");
				CommonersQuest.Version[sFrom].Version = sVersion;
				CommonersQuest.Version[sFrom].Date    = sDate;
				CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Ver:" .. CommonersQuest.Version[""].Version .. ":" .. CommonersQuest.Version[""].Date, "WHISPER", sFrom);
			elseif (strsub(sMsg, 2, 6) == "Info:") then
				local	sID, sPart, sSplit = string.match(sMsg, "%?Info:(%d+):(%d+):([%d%-]+)");
				local	iID = tonumber(sID);
				local	iPart = tonumber(sPart);
				local	iSplit = tonumber(sSplit);
				if (iID and iPart and iSplit) then
					local	k, v;
					for k, v in pairs(CommonersQuest.QuestDB) do
						if (v.ID == iID) then
							local	iEncrypt;
							if (CQDataGlobal.Giver.QuestStates[v.ID]) then
								iEncrypt = CQDataGlobal.Giver.QuestStates[v.ID].Key;
							end

							local	sSend;
							if (iSplit <= 0) then
								iPart = iPart + 1;
								iSplit = 0;
							end

							local	sPartKey;
							if (iPart < 100) then
								local	iCnt, sField, l, w = 1;
								for l, w in pairs(CommonersQuest.DBMetaInfo.QuestFields) do
									if ((type(w) == "string") and (w == "string")) then
										if (iCnt == iPart) then
											sField = l;
											break;
										end
										iCnt = iCnt + 1;
									end
								end
								if (sField) then
									sPartKey = sField;
									sSend = sField .. "=" .. CQH.Encode(v[sField], iEncrypt);
								else
									iPart = 101;
								end
							end

							if (iPart > 100) and (iPart < 200) then
								if (iPart <= 100 + #v.Requirements) then
									sSend = "";
									local	oReq, l, w = v.Requirements[iPart - 100];
									local	sExclude;
									if (oReq.Type == "Riddle") then
										sExclude = "RiddleSolution";
									end
									for l, w in pairs(oReq) do
										local	sValue = CQH.AllToString(w);
										if (l ~= "Type") then
											-- Type must be plain for validation
											sValue = CQH.Encode(sValue, iEncrypt);
										end
										if (l ~= sExclude) then
											sSend = sSend .. l .. "=" .. strsub(type(w), 1, 1) .. "-" .. sValue .. ":"; 
										end
									end
									if (sSend ~= "") then
										sPartKey = "+";
										sSend = strsub(sSend, 1, strlen(sSend) - 1);
									else
										DEFAULT_CHAT_FRAME:AddMessage("Failed to encode requirement " .. (iPart - 100) .. "... :-(");
									end
								else
									iPart = 201;
								end
							end

							if (iPart > 200) and (iPart < 300) then
								if (iPart <= 200 + #v.Reward) then
									sSend = "";
									local	l, w;
									for l, w in pairs(v.Reward[iPart - 200]) do
										sSend = sSend .. l .. "=" .. strsub(type(w), 1, 1) .. "-" .. CQH.AllToString(w) .. ":"; 
									end
									if (sSend ~= "") then
										sSend = strsub(sSend, 1, strlen(sSend) - 1);
									else
										DEFAULT_CHAT_FRAME:AddMessage("Failed to encode (default) reward " .. (iPart - 200) .. "... :-(");
									end
								else
									iPart = 301;
								end
							end

							if (iPart > 300) and (iPart < 400) then
								if (iPart == 301) then
									sSend = "";
									local	l, w;
									for l, w in pairs(v.ContractPreReq) do
										sSend = sSend .. l .. "=" .. strsub(type(w), 1, 1) .. "-" .. CQH.AllToString(w) .. ":"; 
									end
									if (sSend ~= "") then
										sSend = strsub(sSend, 1, strlen(sSend) - 1);
									else
										DEFAULT_CHAT_FRAME:AddMessage("Failed to encode prerequisites... :-(");
									end
								else
									iPart = 401;
								end
							end

							if (iPart == 401) then
								sSend = "";
								local	oState = v.State;
								if (CQDataGlobal.Giver.QuestStates[v.ID]) then
									local	m, x;
									for m, x in pairs(CQDataGlobal.Giver.QuestStates[v.ID]) do
										oState[m] = x;
									end
								end
								local	l, w;
								for l, w in pairs(oState) do
									sSend = sSend .. l .. "=" .. strsub(type(w), 1, 1) .. "-" .. CQH.AllToString(w) .. ":"; 
								end
								if (sSend ~= "") then
									sSend = strsub(sSend, 1, strlen(sSend) - 1);
								else
									DEFAULT_CHAT_FRAME:AddMessage("Failed to encode state... :-(");
								end
							end

							if (sSend) then
								local	sPrefix = "!Info:+";
								if (iEncrypt) then
									sPrefix = sPrefix .. "%";
								end
								sPrefix = sPrefix .. ":";

								local	iSegment = 130;
								if ((iPart < 200) and (strlen(sSend) > iSegment)) then
									-- do we need to send valid utf8 code? hm. hopefully not...
									if (iSplit == 0) then
										iSplit = 1;
									else
										iSplit = iSplit + iSegment;
									end

									-- if we encrypted it, we must use the same salt, consistently!
									if (iSplit == 1) then
										oInfoSplitMostRecent[sFrom] = { ID = iID, Part = iPart, Send = sSend };
									else
										local	oSend = oInfoSplitMostRecent[sFrom];
										if ((oSend.ID == iID) and (oSend.Part == iPart)) then
											sSend = oSend.Send;
										else
											sPrefix = "!Info:-:";
										end
									end

									local	sSub = strsub(sSend, iSplit, iSplit + iSegment - 1);
									if (iSplit + (iSegment - 1) >= strlen(sSend)) then
										iSplit = -1;
										CQH.CommChat("DbgSpam", nil, "Split: full string was >> " .. sSend);
									end

									if (iSplit ~= 1) then
										sSub = sPartKey .. "=" .. sSub;
									end
									sSend = sPrefix .. sID .. ":" .. iPart .. ":" .. iSplit .. ":" .. sSub;
								else
									sSend = sPrefix .. sID .. ":" .. iPart .. ":0:" .. sSend;
								end
							elseif (iPart == 402) then
								sSend = "!Info:=:" .. sID;
							else
								sSend = "!Info:-:" .. sID .. ":" .. iPart .. ":" .. iSplit;
							end

							CommonersQuest.QueueAddonMessage("COMMONERSQUEST", sSend, "WHISPER", sFrom);
							break;
						end
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 8) == "Reward:") then
				-- requested currently set reward
				local	sID, sCookie, iID = string.match(sMsg, "%?Reward:(%d+)(.*)");
				if (sID) then
					iID = tonumber(sID);
				end
				CQH.CommChat("DbgSpam", "Comm", "?Reward: Parsed " .. (sID or "?") .. "/" .. (sCookie or "?"));
				if (iID) then
					local	oQuest, k, v;
					for k, v in pairs(CommonersQuest.QuestDB) do
						if (v.ID == iID) then
							oQuest = v;
							break;
						end
					end

					if (oQuest) then
						CQH.InitStateGiver(oQuest);
						local	oRewardsCurrent, oState = CQH.InitRewards(oQuest.ID, sFrom);
						local	iRewardCnt = 0;
						if (oRewardsCurrent) then
							iRewardCnt = #oRewardsCurrent;
						end
						if (oQuest.Reward) then
							iRewardCnt = iRewardCnt + #oQuest.Reward;
						end

						if ((iRewardCnt == 0) or (oRewardsCurrent == nil)) then
							DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: Rewards for quest " .. iID .. " are missing. " .. sFrom .. " was interested...");
							CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Reward:-:" .. iID, "WHISPER", sFrom);
							return
						end

						local	oRewardsTotal, iKey = CQH.CollateRewards(oQuest, oQuest.Reward, oRewardsCurrent, sFrom);
						local	iCnt = #oRewardsTotal;
						if (iCnt > 0) then
							if (oState.LockedTo and (oState.LockedTo ~= sFrom)) then
								DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: " .. sFrom .. " requested actual rewards for quest " .. iID .. ", but all sets are currently locked. Oldest lock is to " .. oState.LockedTo .. " since " .. date("%Y/%m/%d %H:%M", oState.LockedAt) .. "...");
								CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Reward:-:" .. iID, "WHISPER", sFrom);
							else
								oState.Locked = true;		-- ?Reward: reward set lock
								oState.LockedAt = time();
								oState.LockedTo = sFrom;
								if (oState.Cookie == nil) then
									oState.Cookie = oState.LockedAt;
								end

								local	iCookie;
								if (sCookie) then
									iCookie = tonumber(strsub(sCookie, 2));
								end
								local	sSet = "";
								if (iSet) then
									sSet = "Set=n-#" .. iSet .. "#,";
								end
								CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Reward:+:" .. iID .. ":" .. iCnt .. ":0:{" .. sSet .. "Cookie=n-#" .. oState.Cookie .. "#,}", "WHISPER", sFrom);
								if (iCookie and (iCookie == oState.Cookie)) then
									return
								end

								local	sRewards, i;
								for i = 1, iCnt do
									sRewards = ":" .. i .. ":{";
									local	oReward, k, v = oRewardsTotal[i];
									for k, v in pairs(oReward) do
										local	t, x = type(v), CQH.AllToString(v);
										if (t == "boolean") then
											x = strsub(CQH.AllToString(v), 2, -2);
										end
										sRewards = sRewards .. k .. "=" .. strsub(t, 1, 1) .. "-#" .. x .. "#,";
									end
									sRewards = sRewards .. "}";

									CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Reward:+:" .. iID .. ":" .. iCnt .. sRewards, "WHISPER", sFrom);
								end
							end
						else
							CQH.CommChat("DbgInfo", "Comm", "Rewards for quest " .. iID .. " missing at odd place.");
							CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!Reward:-:" .. iID, "WHISPER", sFrom);
						end
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 11) == "TradeReady") then
				local	sAction, sQuest, sReward, sItem = string.match(sMsg, "%?TradeReady:([^:]+):(%d+):(%d+):(.+)");
				if (sAction and sQuest and sReward and sItem and CQData[sFrom]) then
					local	oItem = CQDataItems[sItem];
					local	iQuest = tonumber(sQuest);
					local	iReward = tonumber(sReward);
					local	WhoAmI = UnitName("player");
					if (oItem == nil) then
						-- quest without binding item?
						local	oQuest = CQH.CharQuestToObj(nil, iQuest);
						local	oStateGlobal = CQH.InitStateGiver(oQuest, true);
						if (oStateGlobal and oStateGlobal.NoBindingItem and CQData[sFrom].QuestsGiven[iQuest] and
						    (sItem == CQData[sFrom].QuestsGiven[iQuest].BindingItem)) then
							oItem = { QuestID = iQuest, Giver = WhoAmI, Taker = sFrom, BindingItemGiven = sItem };
						end
					end

					if (oItem) then
						if ((iQuest == oItem.QuestID) and (WhoAmI == oItem.Giver) and (sFrom == oItem.Taker)) then
							if ((sAction == "Bind") and (oItem.BindingItemCandidate ~= nil)) then
								CQData[sFrom].TradeGiverReady = { QuestID = iQuest, Item = sItem, At = time(), Action = sAction };
							elseif ((sAction == "Abandon") and (oItem.BindingItemGiven ~= nil)) then
								CQData[sFrom].TradeGiverReady = { QuestID = iQuest, Item = sItem, At = time(), Action = sAction };
							elseif ((sAction == "Reward") and (oItem.BindingItemGiven ~= nil)) then
								CQData[sFrom].TradeGiverReady = { QuestID = iQuest, Item = sItem, At = time(), Action = sAction, Reward = iReward };
							end

							local	bCanTrade, iTradeDelay = CommonersQuest.Trade.CanTrade();
							local	bTradeOk = bCanTrade;
							if (bTradeOk and (CQDataGlobal.TradeGiverReady ~= nil)) then
								local	TGR = CQDataGlobal.TradeGiverReady;
								if ((TGR.Taker == sFrom) and (TGR.QuestID == iQuest) and (TGR.Item == sItem) and (TGR.Action == sAction) and (TGR.Reward == iReward)) then
									TGR.At = time();
								elseif (time() - TGR.At > 60) then
									CQDataGlobal.TradeGiverReady = nil;
								else
									bTradeOk = false;
								end
							end

							if (bTradeOk) then
								CQDataGlobal.TradeGiverReady = { Taker = sFrom, QuestID = iQuest, Item = sItem, At = time(), Action = sAction, Reward = iReward };
								CommonersQuest.Trade.ActionSet(sFrom, WhoAmI, sQuest, sAction, sReward, sItem);
								CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!" .. strsub(sMsg, 2), "WHISPER", sFrom);
							else
								if (bCanTrade and CQDataGlobal.TradeGiverReady and (CQDataGlobal.TradeGiverReady.Taker ~= sFrom)) then
									iTradeDelay = math.max(0, 61 - (time() - TGR.At));
								end
								local	sMsgOut = "!TradeNotReady:" .. iTradeDelay .. strsub(sMsg, 12);
								CommonersQuest.QueueAddonMessage("COMMONERSQUEST", sMsgOut, "WHISPER", sFrom);
							end
						else
							CQH.CommChat("DbgInfo", "Comm", "Item is not assigned to be binding for this quest/player.");
						end
					else
						CQH.CommChat("DbgInfo", "Comm", "Item is not assigned to be binding.");
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 8) == "Abandon") then
				local	sQuest, sItem = string.match(sMsg, "%?Abandon:(%d+):(.+)");
				if (sQuest and sItem) then
					local	iQuest = tonumber(sQuest);
					if (CQData[sFrom] and CQData[sFrom].QuestsGiven and CQData[sFrom].QuestsGiven[iQuest]) then
						local	oQuestState = CQData[sFrom].QuestsGiven[iQuest];
						oQuestState.Abandonned = true;

						local	oQuest = CQH.CharQuestToObj(nil, iQuest);
						local	oStateGlobal = CQH.InitStateGiver(oQuest, false);
						if (oStateGlobal and oStateGlobal.NoBindingItem) then
							local	WhoAmI = UnitName("player");

							CQData[sFrom].QuestsGiven[iQuest] = nil;
							CQDataItems[sItem] = nil;
							local	oRewards = CQData[sFrom].RewardsReserved[iQuest];
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

								CQData[sFrom].RewardsReserved[iQuest] = nil;
							end

							local	sQuest = CQH.QuestToPseudoLink(iQuest);
							CQH.CommChat("ChatImportant", nil, "Your quest " .. sQuest .. " (without binding item) was abandonned by " .. sFrom .. ".");
						end
					end

					local	sMsgOut = "!" .. strsub(sMsg, 2);
					CommonersQuest.QueueAddonMessage("COMMONERSQUEST", sMsgOut, "WHISPER", sFrom);
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 16) == "ProgressRiddles") then
				local	sQuest, iQuest, oQuest = string.match(sMsg, "%?ProgressRiddles:(%d+):");
				if (sQuest) then
					iQuest = tonumber(sQuest);
					oQuest = CQH.CharQuestToObj(nil, iQuest);
				end
				if (oQuest and CQData[sFrom] and CQData[sFrom].QuestsGiven and CQData[sFrom].QuestsGiven[iQuest]) then
					if (CQData[sFrom].QuestsGiven[iQuest].RiddleLockout) then
						local	iRL = CQData[sFrom].QuestsGiven[iQuest].RiddleLockout;
						local	iNow = time();
						if (iNow < iRL) then
							CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!ProgressRiddles:-:" .. sQuest .. ":" .. (iRL - iNow), "WHISPER", sFrom);
							return
						end
					end

					local	oQR = oQuest.Requirements;

					local	oReqs = {};
					local	iCnt, iRiddles, i = #oQR, 0;
					for i = 1, iCnt do
						if (oQR[i].Type == "Riddle") then
							oReqs[i] = 0;
							iRiddles = iRiddles + 1;
						end
					end

					local	iSub = strfind(sMsg, ":", 18);
					local	sSub = strsub(sMsg, iSub);
					CQH.CommChat("DbgInfo", "Comm", "Checking " .. sSub .. " for correct solutions...");

					local	iSolved, sReqIndex, sSolution = 0;
					for  sReqIndex, sSolution in string.gmatch(sSub, ":(%d+):([^:]+)") do
						local	iReqIndex = tonumber(sReqIndex);
						if ((iReqIndex >= 1) and (iReqIndex <= iCnt) and (oReqs[iReqIndex] ~= nil)) then
							CQH.CommChat("DbgInfo", "Comm", "Req " .. iReqIndex .. ": " ..  (oQR[iReqIndex].RiddleSolution or "<nil>") .. " =?= " .. (sSolution or "<nil>"));
							local	bSolved = oQR[iReqIndex].RiddleSolution == sSolution;
							if (not bSolved and strfind(oQR[iReqIndex].RiddleSolution, "|")) then
								-- multiple solutions: check one at a time
								local	sTotal, iPos, sSub = oQR[iReqIndex].RiddleSolution;
								while (sTotal ~= "") do
									iPos = strfind(sTotal, "|");
									if (iPos) then
										sSub = strsub(sTotal, 1, iPos - 1);
										sTotal = strsub(sTotal, iPos + 1);
									else
										sSub = sTotal;
										sTotal = "";
									end

									sSub = strtrim(sSub);
									if (sSub == sSolution) then
										bSolved = true;
									end
								end
							end

							if (bSolved) then
								if (oReqs[iReqIndex] == 0) then
									iSolved = iSolved + 1;
								end
								oReqs[iReqIndex] = 1;
							end
						end
					end

					CQH.CommChat("DbgInfo", "Comm", "iSolved: " .. iSolved .. ", iRiddles: " .. iRiddles);
					if (iSolved == iRiddles) then
						CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!ProgressRiddles:+:" .. sQuest, "WHISPER", sFrom);
					else
						local	iLockout = 1;
						for i = 1, iCnt do
							if (oReqs[iReqIndex] == 0) then
								iLockout = math.max(iLockout, oReqs[iReqIndex].RiddleLockout or 1);
							end
						end

						local	iNow = time();
						local	iRL = iNow + 60 * iLockout;
						CQData[sFrom].QuestsGiven[iQuest].RiddleLockout = iRL;
						CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "!ProgressRiddles:-:" .. sQuest .. ":" .. iRL, "WHISPER", sFrom);
					end
				end
			else
				CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
			end
-- ################################################################################################################################################################# --
-- ################################################################################################################################################################# --
		elseif (strsub(sMsg, 1, 1) == "!") then
-- ################################################################################################################################################################# --
-- ################################################################################################################################################################# --
			if (strsub(sMsg, 2, 6) == "List:") then
				local	sGroup, sIDs = string.match(sMsg, "!List:(%d+)(.*)");
				if (sIDs and (sIDs ~= "")) then
					local	bPending, iGroup, sID, oData = false, tonumber(sGroup);
					if (iGroup == 1) then
						CQData[sFrom].QuestsList.Status = bit.bor(CQData[sFrom].QuestsList.Status, 1);
						oData = CQData[sFrom].QuestsList.QuestsReceiving;
					elseif (iGroup == 2) then
						CQData[sFrom].QuestsList.Status = bit.bor(CQData[sFrom].QuestsList.Status, 2);
						oData = CQData[sFrom].QuestsList.QuestsProposing;
					elseif (iGroup == 3) then
						CQData[sFrom].QuestsList.Status = bit.bor(CQData[sFrom].QuestsList.Status, 4);
						oData = CQData[sFrom].QuestsList.QuestsUnavailable;
					end

					if (oData) then
-- DEFAULT_CHAT_FRAME:AddMessage("[CQ] sIDs = " .. sIDs);
						for sID in string.gmatch(sIDs, ":([^:]+)") do	-- ??
-- DEFAULT_CHAT_FRAME:AddMessage("[CQ] sID: " .. sID);
							local	iPos, iID, iModified = strfind(sID, "!");
							if (iPos) then
								local	sIDReal, sModified = string.match(sID, "([^!]+)!(.+)");
								iID = tonumber(sIDReal);
								iModified = tonumber(sModified);
							else
								iID = tonumber(sID);
							end

							local	bFound, k, v = false;
							for k, v in pairs(oData) do
								if (v == iID) then
									bFound = true;
									break;
								end
							end

							tinsert(oData, iID);

							if (iID > 1000000) then	-- custom quests
								local	bKnown = false;
								if (type(CQData[sFrom].QuestsCustom) == "table") then
									local	k, v;
									for k, v in pairs(CQData[sFrom].QuestsCustom) do
										if (v.ID == iID) then
											bKnown = CommonersQuest.ValidateQuest(v, false, nil, sFrom);
											if (v.State.Modified ~= iModified) then
												CQH.CommChat("DbgInfo", "Quest", CQH.AllToString(v.State.Modified) .. " ~= " .. CQH.AllToString(iModified) .. " !!");
												CQH.CommChat("ChatImportant", "Quest", "Giver changed quest " .. CQH.QuestToPseudoLink(v.ID, v.Title) .. " after telling you about it. Marking quest as 'impossible to complete' (as we might not be up-to-date on requirements).");
												v.State.Dirty = true;
											end
										end
									end
								end

								if (not bKnown and (iGroup == 2)) then
									local	bFound, k, v = false;
									for k, v in pairs(CQData[sFrom].QuestsList.QuestsTransferring) do
										if (v.QuestID == iID) then
											bFound = true;
											break;
										end
									end

									if (not bFound) then
										tinsert(CQData[sFrom].QuestsList.QuestsTransferring, { QuestID = iID, Progress = "--" });
										bPending = true;
										CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?Info:" .. iID .. ":0:0", "WHISPER", sFrom);
									end
								end
							end
						end
					end

					if (bPending) then
						CQH.CommChat("ChatInfo", nil, "Custom quest(s) found. Additional quest data is still transferred in background.");
					end
				elseif (sGroup) then
					-- received empty data block
					local	iGroup = tonumber(sGroup);
					CQH.CommChat("DbgInfo", "Quest", "Group " .. iGroup .. " is empty.");
					if (iGroup == 1) then
						CQData[sFrom].QuestsList.Status = bit.bor(CQData[sFrom].QuestsList.Status, 1);
					elseif (iGroup == 2) then
						CQData[sFrom].QuestsList.Status = bit.bor(CQData[sFrom].QuestsList.Status, 2);
					elseif (iGroup == 3) then
						CQData[sFrom].QuestsList.Status = bit.bor(CQData[sFrom].QuestsList.Status, 4);
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end


				if (CommonersQuest.LDBTooltipIsMine) then
					local	oFrame = CommonersQuest.LDBTooltipFrame;
					CommonersQuest.LDBTooltipHide();
					CommonersQuest.LDBTooltipShow(oFrame);
				end

				if (CQData[sFrom].QuestsList.Status == 7) then
					CommonersQuest.GreetingPanel(sFrom);
				end
			elseif (strsub(sMsg, 2, 5) == "Ack:") then
				local	sQuestID, sCookie, sGUID = string.match(sMsg, "!Ack:(%d+):(%d+):([^:]+)");
				if ((sQuestID ~= nil) and (sCookie ~= nil) and (sGUID ~= nil)) then
					CommonersQuest.PlayerInit(sFrom, sGUID);
					local	iQuestID = tonumber(sQuestID);
					local	iCookie = tonumber(sCookie);
					local	oRewards, oState, iKey;
					if ((CQData[sFrom] == nil) or (CQData[sFrom].RewardsReserved[iQuestID] == nil)) then
						oRewards, oState, iKey = CQH.InitRewards(iQuestID, sFrom);
					end

					if (oRewards and (oState.LockedTo == sFrom) and (oState.Cookie == iCookie)) then
						-- refresh lock
						oState.LockedAt = time();
						local	oRewardsTotals = CQH.CollateRewards(iQuestID, nil, nil, sFrom);
						if (CQH.CheckInventoryForRewardAvailability(iQuestID, sFrom, oRewardsTotals)) then
							DEFAULT_CHAT_FRAME:AddMessage("[CQ] Moving rewards into subtables...");
							local	oRewards = CommonersQuest.Helpers.CollateRewards(iQuestID, nil, oRewards.Set, sFrom)
							CQData[sFrom].RewardsReserved[iQuestID] = { Data = oRewards, State = oState,
													Info = { Key = iKey, ReservedAt = time() } };

							-- setup global items
							local	WhoAmI = UnitName("player");

							local	k, v;
							for k, v in pairs(oRewards) do
								if (v.Type == "Item") then
									CQH.InitTable(CQDataItems, v.ItemID);
									local	oItem = CQDataItems[v.ItemID];

									CQH.InitTable(oItem, "Count");
									oItem.Count[WhoAmI] = 1;
									if (v.Count) then
										oItem.Count[WhoAmI] = v.Count;
									end

									if (oItem.Count["Total#"] == nil) then
										oItem.Count["Total#"] = 0;
									end
									oItem.Count["Total#"] = oItem.Count["Total#"] + oItem.Count[WhoAmI];
								end
							end
							CQData[sFrom].QuestsRequestedToGive[iQuestID] = time();

							-- lock quest requirements
							local	oGlobalState = CQDataGlobal.Giver.QuestStates[iQuestID];
							oGlobalState.Locked = true;		-- !Ack: quest given

							-- unlock quest rewards
							oState.Locked = false;
							oState.LockedAt = nil;
							oState.LockedTo = nil;
							oState.Cookie = nil;

							local	sQuest = CQH.QuestToPseudoLink(iQuestID);
							if (oGlobalState.NoBindingItem) then
								CQH.CommChat("ChatImportant", nil, sFrom .. " requested to complete quest " .. sQuest ..".\nThis quest is flagged as not requiring a binding item, so it's considered given now.");

								local	sItem = "item:6948:0:0:0:0:0:0:0";	-- Hearthstone
								CQData[sFrom].QuestsRequestedToGive[iQuestID] = nil;
								CQData[sFrom].RewardsReserved[iQuestID].BindingItemGiven = sItem;

								CQH.InitTable(CQData[sFrom].QuestsGiven, iQuestID);
								local	oContainer = CQData[sFrom].QuestsGiven[iQuestID];
								oContainer.BindingItem = sItem;
								oContainer.BindingAt = time();
								oContainer.BindingCompleted = 3;
							else
								CQH.CommChat("ChatImportant", nil, sFrom .. " requested to complete quest " .. sQuest ..".\nYou need to assign a \"binding item\" and give it to them.");
							end
						end
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 5) == "Ver:") then
				local	sVersion, sDate = string.match(sMsg, "!Ver:([^:]+):(.+)");
				if (sVersion and sDate) then
					CommonersQuest.Version[sFrom].Version = sVersion;
					CommonersQuest.Version[sFrom].Date    = sDate;
					CommonersQuest.PlayerInit(sFrom);
					if (CommonersQuest.LDBTooltipIsMine) then
						local	oFrame = CommonersQuest.LDBTooltipFrame;
						CommonersQuest.LDBTooltipHide();
						CommonersQuest.LDBTooltipShow(oFrame);
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 7) == "Info:+") then
				local	sEnc, sID, sPart, sSplit, sData = string.match(sMsg, "!Info:%+(%%?):(%d+):(%d+):([%d%-]+):(.+)");
				local	iID = tonumber(sID);
				local	iPart = tonumber(sPart);
				local	iSplit = tonumber(sSplit);
				if (iID and iPart and iSplit and sData) then
					local	oQuest, k, v;
					for k, v in pairs(CQData[sFrom].QuestsCustom) do
						if (v.ID == iID) then
							oQuest = v;
							break;
						end
					end

					if (oQuest == nil) then
						oQuest = {};
						oQuest.ID = iID;
						CQH.InitTable(oQuest, "State");
						tinsert(CQData[sFrom].QuestsCustom, oQuest);
					end

					if (sEnc == "%") then
						oQuest.State.Encrypted = true;
					end

					local	bOk = false;
					if (iPart < 100) then
						local	sField, sValue = string.match(sData, "([^=]+)=(.+)");
						if (sField and sValue) then
							bOk = true;
							if (iSplit == 0) or (iSplit == 1) then
								oQuest[sField] = sValue;
							else
								oQuest[sField] = oQuest[sField] .. sValue;
							end
						end
					elseif (iPart > 100) and (iPart < 200) then
						if (iPart == 101) then
							CQH.InitTable(oQuest, "Requirements");

							local	oRemove, k, v = {};
							for k, v in pairs(oQuest.Requirements) do
								if (type(v) == "table") then
									oQuest.Requirements[k] = nil;
								end
							end
						end

						local	bEvaluate = false;
						if (iSplit == 0) then
							bEvaluate = true;
							oQuest.Requirements[iPart - 100] = {};
						else
							if (iSplit == 1) then
								oQuest.Requirements[iPart - 100] = sData;
							else
								oQuest.Requirements[iPart - 100] = oQuest.Requirements[iPart - 100] .. strsub(sData, 3);
							end
							if (iSplit == -1) then
								bEvaluate = true;
								sData = oQuest.Requirements[iPart - 100];
								oQuest.Requirements[iPart - 100] = {};
							end
						end

						if (not bEvaluate) then
							bOk = true;
						else
							local	oPart = oQuest.Requirements[iPart - 100];
							local	sSub;
							for sSub in string.gmatch(sData, "([^:]+)") do
								local	sKey, sType, sValue = string.match(sSub, "([^=]+)=(.)-(.+)");
								if (sKey) then
									bOk = true;
									oPart[sKey] = sValue;
									if (sType ~= "s") then
										if (sType == "b") then
											oPart[sKey] = sValue == "{true}";
										elseif (sType == "n") then
											oPart[sKey] = tonumber(sValue);
										else
											bOk = false;
											oPart[sKey] = nil;
											break;
										end
									end
								end
							end

							if (not bOk) then
								DEFAULT_CHAT_FRAME:AddMessage("[CQ] Failed to find structure for info reply. :-( (" .. CQH.AllToString(sData) .. ")");
							end
						end
					elseif (iPart > 200) and (iPart < 300) then
						if (iPart == 201) then
							oQuest.Reward = {};
						end
						oQuest.Reward[iPart - 200] = {};
						local	oPart = oQuest.Reward[iPart - 200];
						local	sSub;
						for sSub in string.gmatch(sData, "([^:]+)") do
							local	sKey, sType, sValue = string.match(sSub, "([^=]+)=(.)-(.+)");
							if (sKey) then
								bOk = true;
								oPart[sKey] = sValue;
								if (sType ~= "s") then
									if (sType == "b") then
										oPart[sKey] = sValue == "{true}";
									elseif (sType == "n") then
										oPart[sKey] = tonumber(sValue);
									else
										bOk = false;
										oPart[sKey] = nil;
										break;
									end
								end
							end
						end
						if (not bOk) then
							DEFAULT_CHAT_FRAME:AddMessage("[CQ] Failed to find structure for info reply. :-( (" .. CQH.AllToString(sData) .. ")");
						end
					elseif (iPart == 301) then
						oQuest.ContractPreReq = {};
						local	oPart = oQuest.ContractPreReq;
						local	sSub;
						for sSub in string.gmatch(sData, "([^:]+)") do
							local	sKey, sType, sValue = string.match(sSub, "([^=]+)=(.)-(.+)");
							if (sKey) then
								bOk = true;
								oPart[sKey] = sValue;
								if (sType ~= "s") then
									if (sType == "b") then
										oPart[sKey] = sValue == "{true}";
									elseif (sType == "n") then
										oPart[sKey] = tonumber(sValue);
									else
										bOk = false;
										oPart[sKey] = nil;
										break;
									end
								end
							end
						end

						if (not bOk) then
							DEFAULT_CHAT_FRAME:AddMessage("[CQ] Failed to find structure for info reply. :-( (" .. CQH.AllToString(sData) .. ")");
						end
					elseif (iPart == 401) then
						local	oState = {};
						local	sSub;
						for sSub in string.gmatch(sData, "([^:]+)") do
							local	sKey, sType, sValue = string.match(sSub, "([^=]+)=(.)-(.+)");
							if (sKey) then
								bOk = true;
								oState[sKey] = sValue;
								if (sType ~= "s") then
									if (sType == "b") then
										oState[sKey] = sValue == "{true}";
									elseif (sType == "n") then
										oState[sKey] = tonumber(sValue);
									else
										bOk = false;
										oState[sKey] = nil;
										break;
									end
								end
							end
						end

						CQH.InitTable(oQuest, "Reward");

						local	k, v;
						for k, v in pairs(oState) do
							if (oQuest.State[k] == nil) then
								oQuest.State[k] = v;
							elseif (oQuest.State[k] ~= v) then
								local	sID, sTitle = "???", "???";
								if (oQuest.ID) then
									sID = oQuest.ID;
								end
								if (oQuest.Title) then
									sTitle = oQuest.Title;
								end
								DEFAULT_CHAT_FRAME:AddMessage("[CQ] Quest giver changed custom quest " .. sID .. ": <" .. sTitle .."> state. Field = " .. k .. ", Value changed from " .. CQH.AllToString(oQuest.State[k]) .. " to " .. CQH.AllToString(v) .. ". This should NOT happen.");
								oQuest.State[k] = v;
							end
						end

						if (not bOk) then
							DEFAULT_CHAT_FRAME:AddMessage("[CQ] Failed to find structure for info reply. :-( (" .. CQH.AllToString(sData) .. ")");
						end
					end

					local	k, v = false;
					for k, v in pairs(CQData[sFrom].QuestsList.QuestsTransferring) do
						if (v.QuestID == iID) then
							local	Progress = v.Progress;
							if  (iPart < 100) then		-- strings
								v.Progress = (iPart - 1) * 6;	-- 0 .. 30
							elseif (iPart < 200) then	-- req
								v.Progress = 45;		-- 30 .. 60
							elseif (iPart < 300) then	-- reward
								v.Progress = 75;		-- 60 .. 90
							elseif (iPart < 400) then	-- reward
								v.Progress = 90;		-- 90
							else
								v.Progress = 95;		-- 95
							end

							if (not bOk) then
								v.Progress = "--";
							end

							if (Progress ~= v.Progress) then
								CommonersQuest.GreetingPanelReopen(sFrom, true);
							end

							break;
						end
					end

					if (bOk) then
						CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?Info:" .. sID .. ":" .. iPart .. ":" .. iSplit, "WHISPER", sFrom);
					else
						DEFAULT_CHAT_FRAME:AddMessage("[CQ] Failed to find structure for info reply. :-(");
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 8) == "Info:=:") then
				local	sID, sPart = string.match(sMsg, "!Info:=:(%d+)");
				local	iID = tonumber(sID);
				if (iID) then
					local	k, v;
					for k, v in pairs(CQData[sFrom].QuestsCustom) do
						if (v.ID == iID) then
							local	bOk = false;
							if (v.State.Encrypted) then
								CQH.CommChat("ChatInfo", nil, "Transfer of quest " .. iID .. " completed. Quest is partially encrypted! Checking...");
							else
								CQH.CommChat("ChatInfo", nil, "Transfer of quest " .. iID .. " completed. Checking...");
							end

							bOk = CommonersQuest.ValidateQuest(v, true, nil, sFrom);
							if (bOk) then
								local	iIndex, k, v;
								for k, v in pairs(CQData[sFrom].QuestsList.QuestsTransferring) do
									if (v.QuestID == iID) then
										iIndex = k;
										break;
									end
								end
								if (iIndex) then
									tremove(CQData[sFrom].QuestsList.QuestsTransferring, iIndex);
									CommonersQuest.GreetingPanelReopen(sFrom, false);
								else
									CQH.CommChat("DbgInfo", "Quest", "Failed to find index for pending transfer??");
								end
							end

							break;
						end
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 8) == "Info:-:") then
				local	sID, sPart, sSplit = string.match(sMsg, "!Info:%-:(%d+):(%d+):(%d+)");
				local	iID = tonumber(sID);
				local	iPart = tonumber(sPart);
				local	iSplit = tonumber(sSplit);
				if (iID and iPart and iSplit) then
					CQH.CommChat("ChatInfo", nil, "Failed to transfer quest " .. iID .. " at part " .. iPart .. " segment " .. iSplit .. ". D'oh! :-(");
					local	k, v;
					for k, v in pairs(CQData[sFrom].QuestsCustom) do
						if (v.ID == iID) then
							v.State = nil;		-- force-break validation.
						end
					end

					local	iIndex, k, v;
					for k, v in pairs(CQData[sFrom].QuestsList.QuestsTransferring) do
						if (v.QuestID == iID) then
							iIndex = k;
							break;
						end
					end
					if (iIndex) then
						tremove(CQData[sFrom].QuestsList.QuestsTransferring, iIndex);
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 8) == "Reward:") then
				local	bOk = strsub(sMsg, 9, 9) == "+";
				if (not bOk) then
					local	sID = string.match(sMsg, "!Reward:%-:(%d+)");
					CQH.CommChat("ChatImportant", nil, "Failed to get rewards from " .. sFrom .. " for quest " .. sID .. ". :-(");
					CommonersQuestFrame.Requesting = false;
				else
					-- requested currently set reward
					local	sID, sCnt, sRewards = string.match(sMsg, "!Reward:%+:(%d+):(%d+)(.*)");
					local	iID, iCnt;
					if (sID and sCnt) then
						iID = tonumber(sID);
						iCnt = tonumber(sCnt);
					end
					if (iID and iCnt) then
						if (sRewards == "") then
							DEFAULT_CHAT_FRAME:AddMessage("CommonersQuest: " .. sFrom .. " failed to get all rewards for quest " .. iID .. ". :-(");
						else
							local	bComplete = false;

							CQH.InitTable(CQData[sFrom].RewardsPromised, iID);
							CQH.InitTable(CQData[sFrom].RewardsPromised[iID], "Data");
							CQH.InitTable(CQData[sFrom].RewardsPromised[iID], "Info");
							CQH.InitTable(CQData[sFrom].RewardsPromised[iID].Info, "Received");
							CQData[sFrom].RewardsPromised[iID].Info.Count = iCnt;

--DEFAULT_CHAT_FRAME:AddMessage("[CQ] Rewards = <" .. sRewards .. ">");
							local	iNum, sReward;
							for sNum, sReward in string.gmatch(sRewards, ":(%d+):{([^{}]+)}") do
--DEFAULT_CHAT_FRAME:AddMessage("[CQ] Reward " .. iNum .. " = <" .. sReward .. ">");
								local	iNum, oData, bFail, sField, sValue = tonumber(sNum), {}, false;
								for sField, sType, sValue in string.gmatch(sReward, "([^=]+)=(.)-#([^#]+)#,") do
--DEFAULT_CHAT_FRAME:AddMessage("[CQ] Rewardfield " .. sField .. ", Type = " .. sType .. ", Value = " .. sValue);
									if (sType == "s") then
										oData[sField] = sValue;
									elseif (sType == "n") then
										oData[sField] = tonumber(sValue);
									elseif (sType == "b") then
										oData[sField] = sValue == "true";
									else
DEFAULT_CHAT_FRAME:AddMessage("[CQ] " .. sFrom .. "/" .. iID .. ": reward " .. iNum .. ", field " .. sField .. ": unknown type " .. sType);
										bFail = true;
									end
								end

								if (not bFail) then
									if (iNum > 0) then
										CQData[sFrom].RewardsPromised[iID].Info.Received[iNum] = { Global = time(), Current = GetTime() };
										CQData[sFrom].RewardsPromised[iID].Data[iNum] = oData;
									else
										if (CQData[sFrom].RewardsPromised[iID].Info.Giver) then
											if (oData.Cookie and (CQData[sFrom].RewardsPromised[iID].Info.Giver.Cookie == oData.Cookie)) then
												bComplete = true;
											else
												DEFAULT_CHAT_FRAME:AddMessage("[CQ] " .. sFrom .. "/" .. iID .. ": reward cookie changed. resetting old rewards.");
												local	oOld = CQData[sFrom].RewardsPromised[iID].Data;
												local	oReq = CQData[sFrom].RewardsPromised[iID].Info.Request;
												CQData[sFrom].RewardsPromised[iID].Data = {};
												local	fNow, k, v = GetTime();
												for k, v in pairs(oOld) do
													local	oInfo = CQData[sFrom].RewardsPromised[iID].Info.Received[k];
													if ((oInfo.Global >= oReq.Global) and (oInfo.Current > oReq.Current)) then
														CQData[sFrom].RewardsPromised[iID].Data[k] = v;
													end
												end
											end
										end

										CQData[sFrom].RewardsPromised[iID].Info.Giver = oData;
										CQData[sFrom].RewardsPromised[iID].Info.Giver.At = { Global = time(), Current = GetTime() };
									end
								end
							end

							local	sMissing, bInfoReq = "", false;
							if ((CQData[sFrom].RewardsPromised[iID].Info.Giver ~= nil) and (CQData[sFrom].RewardsPromised[iID].Info.Giver.At ~= nil)) then
								local	oReq = CQData[sFrom].RewardsPromised[iID].Info.Request;
								local	oReply = CQData[sFrom].RewardsPromised[iID].Info.Giver.At;
								bInfoReq = (oReq.Global <= oReply.Global) and (oReq.Current < oReply.Current);
							end
							if (not bInfoReq) then
								sMissing = sMissing .. " inforeply";
							end
							for iNum = 1, iCnt do
								if (CQData[sFrom].RewardsPromised[iID].Data[iNum] == nil) then
									sMissing = sMissing .. " reward" .. iNum;
								end
							end

							if (sMissing ~= "") then
								CQH.CommChat("DbgInfo", "Comm", sFrom .. "/" .. iID .. ": still missing =" .. sMissing);
							else
								CommonersQuestFrame.Requesting = false;
								if (CommonersQuestFrame:IsShown() and not CommonersQuestFrameDetailPanel:IsShown() and
								    not CommonersQuestFrame.EditMode and (CommonersQuestFrame.Player == sFrom)) then
									CQH.CommChat("DbgInfo", "Comm", sFrom .. "/" .. iID .. ": rewards complete. Showing...");
									CommonersQuest.FrameDetailPanel.Init(iID);
								end
							end
						end
					else
						CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
					end
				end
			elseif (strsub(sMsg, 2, 6) == "Item:") then
				local	bAccepted = strsub(sMsg, 7, 7) == "+";
				if (not bAccepted) then
					CancelTrade();
				end

				local	sDirection, iQuestID, sItemLink = string.match(sMsg, "!Item:[%+%-]?:(....):(%d+):(.+)");
				if (sDirection and iQuestID and sItemLink) then
					iQuestID = tonumber(iQuestID);
					local	_, sItemFullLink = GetItemInfo(sItemLink);
					local	sAction = " ???";
					local	sPossessive, sQuest;
					if (sDirection == "Give") then
						sPossessive = "their";
						sQuest = CQH.QuestToPseudoLink(iQuestID, nil, sFrom);
						if (bAccepted) then
							sAction = " offers";
						else
							sAction = " denied";
						end
					elseif (sDirection == "Take") then
						sPossessive = "your";
						sQuest = CQH.QuestToPseudoLink(iQuestID);
						if (bAccepted) then
							sAction = " accepts";
						else
							sAction = " denied";
						end
					end

					CQH.CommChat("ChatImportant", nil, sFrom .. sAction .. " the item " .. sItemFullLink .. " as binding for " .. sPossessive .. " quest " .. sQuest .. ".");
					CQH.InitTable(CQData[sFrom].ItemAccepted, sItemLink);
					CQH.InitTable(CQData[sFrom].ItemAccepted[sItemLink], sDirection);
					CQData[sFrom].ItemAccepted[sItemLink][sDirection].Q = iQuestID;
					CQData[sFrom].ItemAccepted[sItemLink][sDirection].At = time();
					CQData[sFrom].ItemAccepted[sItemLink][sDirection].Remote = true;

					if (sDirection == "Give") then
						CQData[sFrom].ItemAccepted[sItemLink][sDirection].Giver = sFrom;
						if (CQH.ValidForBinding(sItemLink)) then
							StaticPopupDialogs["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"].cq_from = sFrom;
							StaticPopupDialogs["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"].cq_questid = iQuestID;
							StaticPopupDialogs["COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST"].cq_itemlink = sItemLink;

							local	sItemName, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo(sItemLink);
							local	oData = { name = sItemName, texture = sItemTexture, link = sItemLink };
							StaticPopup_Show("COMMONERSQUEST_QUESTTAKER_ITEMTRADE_ISFORQUEST", CQH.QuestToPseudoLink(iQuestID, nil, sFrom), sFrom, oData);
						end
					else
						CQData[sFrom].ItemAccepted[sItemLink][sDirection].Giver = UnitName("player");
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 21) == "BindingItemCandidate") then
				DEFAULT_CHAT_FRAME:AddMessage("[CQ] BindintItemCandidate was assigned. If target is correct, will query to initiate trade...");
				local	sTarget, sServer = UnitName("target");
				if ((sServer ~= nil) and (sServer ~= "")) then
					sTarget = nil;
				end
				local	sQuest, sItem = string.match(sMsg, "!BindingItemCandidate:(%d+):(.+)");
				local	iQuest;
				if (sQuest) then
					iQuest = tonumber(sQuest);
				end
				if (iQuest and sItem) then
					if (CQData[sFrom].RewardsPromised[iQuest]) then
						CQData[sFrom].RewardsPromised[iQuest].Info.BindingItemCandidate = sItem;

						if (not CommonersQuest.Trade.CanTrade()) then
DEFAULT_CHAT_FRAME:AddMessage("[CQ] You already have a trade in progress, not requesting one from " .. sFrom .. " at the same time...");
						else
							local	iTime = time();
							if (sTarget and (sTarget == sFrom) and
							    ((CQData[sFrom].TradeTakerReady == nil) or
							     (iTime - CQData[sFrom].TradeTakerReady.At > 60))) then
								CQData[sFrom].TradeTakerReady = { QuestID = iQuest, Item = sItem, At = time(), Action = "Bind" };
								CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?TradeReady:Bind:" .. sQuest .. ":0:" .. sItem, "WHISPER", sFrom);
							elseif (CQData[sFrom].TradeTakerReady ~= nil) then
								-- store when giver changes assignment
								if (CQData[sFrom].TradeTakerReady.QuestID == iQuest) then
									CQData[sFrom].TradeTakerReady.Item = sItem;
								end
								if (sTarget and (sTarget == sFrom)) then
DEFAULT_CHAT_FRAME:AddMessage("[CQ] Already sent a message " .. (iTime - CQData[sFrom].TradeTakerReady.At) .. " seconds ago. Skipping...");
								end
							end
						end
					else
DEFAULT_CHAT_FRAME:AddMessage("[CQ] Quest rewards never pulled, can't *bind* quest.");
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 11) == "TradeReady") then
				local	sTarget, sServer = UnitName("target");
				if ((sServer ~= nil) and (sServer ~= "")) then
					sTarget = nil;
				end
				local	sAction, sQuest, sReward, sItem = string.match(sMsg, "!TradeReady:([^:]+):(%d+):(%d+):(.+)");
				if (sTarget and sAction and sQuest and sReward and sItem) then
					local	iTime = time();
					if (sTarget and (sTarget == sFrom) and (CQData[sFrom].TradeTakerReady ~= nil)) then
						if (CQDataX.Debug and UnitIsUnit("player", "target")) then
DEFAULT_CHAT_FRAME:AddMessage("[CQ] Faking trade...");
							CommonersQuest.OnEvent(sAction, "TRADE_SHOW");
						else
DEFAULT_CHAT_FRAME:AddMessage("[CQ] Initiating trade...");
							CommonersQuest.Trade.ActionSet(sFrom, sFrom, sQuest, sAction, sReward, sItem);
							InitiateTrade("target");
						end
					else
						CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 8) == "Decline") then
				local	sQuest = string.match(sMsg, "!Decline:(%d+)");
				if (sQuest) then
					CQH.CommChat("DbgInfo", "Comm", "Quest " .. sQuest .. " was declined by " .. sFrom .. ", unlocking reward set (and potentially binding item candidate).");
					local	iQuest = tonumber(sQuest);
					CQData[sFrom].QuestsRequestedToGive[iQuest] = nil;

					local	iCnt, k, v = 0;
					if (CQDataGlobal.Rewards[iQuest]) then
						for k, v in pairs(CQDataGlobal.Rewards[iQuest]) do
							if (v.State.LockedTo == sFrom) then
								iCnt = iCnt + 1;

								v.State.Locked = false;
								v.State.LockedTo = nil;
								v.State.LockedAt = nil;
								v.State.Cookie = nil;
							end
						end
					end

					if (iCnt ~= 1) then
						CQH.CommChat("DbgImportant", "Comm", "Unlocked unexpected number of rewardsets (" .. iCnt .. ") for quest " .. iQuest .. " declined by player " .. sFrom .. "?");
					end

					local	iCnt, k, v = 0;
					if (CQDataItems) then
						local	oDropKeys = {};
						for k, v in pairs(CQDataItems) do
							if (v.BindingItemCandidate and (v.Giver == UnitName("player")) and (v.Taker == sFrom) and (v.QuestID == iQuest)) then
								tinsert(oDropKeys, k);
								iCnt = iCnt + 1;
							end
						end
						for k, v in pairs(oDropKeys) do
							tremove(CQDataItems, k);
						end
					end

					if (iCnt > 1) then
						CQH.CommChat("DbgImportant", "Comm", "Removed unexpected number of binding item candidates (" .. iCnt .. ") for quest " .. iQuest .. " declined by player " .. sFrom .. "?");
					end
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 8) == "Abandon") then
				local	sQuest, sItem = string.match(sMsg, "!Abandon:(%d+):(.+)");
				local	sTarget, sServer = UnitName("target");
				if ((sServer ~= nil) and (sServer ~= "")) then
					sTarget = nil;
				end

				if (sQuest and sItem and sTarget and (sTarget == sFrom)) then
					local	iQuest = tonumber(sQuest);
					local	oQuest = CQH.CharQuestToObj(sFrom, iQuest);
					if (oQuest and oQuest.State and oQuest.State.NoBindingItem) then
						local	WhoAmI = UnitName("player");

						CQData[sFrom].QuestsCurrent[iQuest] = nil;
						CQDataItems[sItem] = nil;
						CQData[sFrom].RewardsPromised[iQuest] = nil;

						local	sQuest = CQH.QuestToPseudoLink(iQuest);
						CQH.CommChat("ChatImportant", nil, "Quest " .. sQuest .. " from " .. sFrom .. " (without binding item) was abandonned by you.");
						return
					end

					if (not CommonersQuest.Trade.CanTrade()) then
DEFAULT_CHAT_FRAME:AddMessage("[CQ] You already have a trade in progress, not requesting one from " .. sFrom .. " at the same time...");
					else
						if (CQData[sFrom] and CQData[sFrom].QuestsCurrent and CQData[sFrom].QuestsCurrent[iQuest]) then
							local	oQuestState = CQData[sFrom].QuestsCurrent[iQuest];
							if (oQuestState.Abandonned) then
								CQData[sFrom].TradeTakerReady = { QuestID = iQuest, Item = sItem, At = time(), Action = "Abandon" };
								CommonersQuest.QueueAddonMessage("COMMONERSQUEST", "?TradeReady:Abandon:" .. sQuest .. ":0:" .. sItem, "WHISPER", sFrom);
							end
						end
					end
				end
			elseif (strsub(sMsg, 2, 14) == "TradeNotReady") then
				local	sDelay, sAction, sQuest, sReward, sItem = string.match(sMsg, "!TradeNotReady:(%d+):([^:]+):(%d+):(%d+):(.+)");
				if (sDelay and sAction and sQuest and sReward and sItem) then
					local	iQuest = tonumber(sQuest);
					local	sQuestLink = CQH.QuestToPseudoLink(iQuest, nil, sFrom);
					local	_, sItemLink = GetItemInfo(sItem);
					CQH.CommChat("ChatImportant", "Trade", sFrom .. " is busy at the moment and cannot accept a trade to perform <" .. sAction "> on quest " .. sQuestLink .. ", item " .. sItemLink .. ". You should retry in about " .. sDelay .. " seconds again.");
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
				end
			elseif (strsub(sMsg, 2, 16) == "ProgressRiddles") then
				local	sStatus, sQuest, iQuest, oQuest = string.match(sMsg, "!ProgressRiddles:([%+%-]):(%d+)");
				if (sStatus and sQuest) then
					iQuest = tonumber(sQuest);
				else
					CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
					return
				end

				CQH.CommChat("DbgInfo", "Comm", "sStatus = " .. sStatus .. ", iQuest = " .. iQuest);

				if (iQuest and CQData[sFrom] and CQData[sFrom].QuestsCurrent and CQData[sFrom].QuestsCurrent[iQuest]) then
					if (sStatus == "-") then
						local	sText = " later";
						local	iNow = time();
						local	sRL = string.match(sMsg, "!ProgressRiddles:%-:%d+:(%d+)");
						if (sRL) then
							local	iRL = tonumber(sRL);
							if (iRL > iNow) then
								if (iRL - iNow < 300) then
									sText = " in " .. math.floor((iRL - iNow) / 60) .. " minutes and " .. ((iRL - iNow) % 60)  .. " seconds";
								elseif (iRL - iNow < 3600) then
									sText = " in about " .. math.floor((iRL - iNow) / 60) .. " minutes";
								else
									sText = " at " .. date("%Y/%m/%d %H:%M", iRL);
								end
							end
						end

						CQH.CommChat("ChatImportant", nil, "You failed to solve the quest " .. CQH.QuestToPseudoLink(iQuest, nil, sFrom) .. " from " .. sFrom .. " correctly. You'll have to try again" .. sText .. ".");
						return
					end

					if (sStatus == "+") then
						local	oQuest = CQH.CharQuestToObj(sFrom, iQuest);
						local	oQuestState, oCompleted = CQData[sFrom].QuestsCurrent[iQuest];
						if (oQuest and oQuestState) then
							if (oQuestState.Completed) then
								oCompleted = oQuestState.Completed;
							else
								oCompleted = {};
							end

							local	iCnt, i = #oQuest.Requirements;
							for i = 1, iCnt do
								local	oReq = oQuest.Requirements[i];
								if (oReq.Type == "Riddle") then
									oCompleted[i] = true;
								end
							end

							CQH.CommChat("ChatImportant", nil, "You solved the riddles in quest " .. CQH.QuestToPseudoLink(iQuest, nil, sFrom) .. " from " .. sFrom .. " correctly!");
							if (CommonersQuestFrame:IsShown() and CommonersQuestFrameProgressPanel:IsShown()) then
								CommonersQuest.FrameRewardPanel.Init(iQuest);
							else
								CQH.CommChat("ChatImportant", nil, "Failed to switch to reward panel for " .. CQH.QuestToPseudoLink(iQuest, nil, sFrom) .. " from " .. sFrom .. ": You closed the CommonersQuest window in the meantime. :-( (Completion status is stored nontheless.)");
							end
						end
					end
				end
			else
				CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
 			end
		else
			CQH.CommChat("DbgImportant", "Comm", "Failed to parse message: => " .. sMsg);
		end
	end
end


