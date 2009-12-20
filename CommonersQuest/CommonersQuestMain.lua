
local	CQData = nil;
local	CQDataX = nil;
local	CQDataGlobal = nil;
local	CQDataItems = nil;

local	CQH = CommonersQuest.Helpers;

CommonersQuest.Main = { State = {}, Collapsed = {} };

local	Module = {
		QuestCnt = 0,
		QuestCurr = 0,
		RewardCnt = 0,
		RewardCurr = 0,
	};

function	CommonersQuest.Initializers.Main(CQDataMain, CQDataXMain, CQDataGlobalMain, CQDataItemsMain)
	CQData = CQDataMain;
	CQDataX = CQDataXMain;
	CQDataGlobal = CQDataGlobalMain;
	CQDataItems = CQDataItemsMain;
end

--[[

new layout:

[x] Show pre-requisites [x] Show requirements [x] Show rewards
[x] Show enabled quests [x] Show disabled quests [x] Show incomplete quests

Hide
[ ] Quest 1002: Women...       | Rewardset 1: ...
	Pre-Req: ...           | Rewardset 2: ...
	Require: ...           | Rewardset 3: ...

[x] Quest 1003: Men...         | Rewardsets: 2

additional frames:

Due to bad CPU usage with many frames anchored to each other, every quest now gets
an additional grouping frame, all its items are anchored there and only the grouping
frames are on the main scrollframe.
]]--

local	getglobal = getglobal;

function	CommonersQuest.Main.OnLoad(self)
	CommonersQuestMainQuestStateLockedLockedFG:SetTexture("Interface\\Icons\\INV_ValentinesBoxOfChocolates01");
	CommonersQuestMainQuestStateLockedText:SetText("locked quest");

	CommonersQuestMainQuestStateEditableLockedFG:SetTexture("Interface\\Icons\\INV_ValentinesCard02");
	CommonersQuestMainQuestStateEditableText:SetText("editable quest");
end

function	CommonersQuest.Main.OnShow(self)
	CommonersQuest.Main.Refresh(self);
end

--[[
local	oTimers = {};
local	oTimersSub = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 };

function	CQTimers()
	local	iCnt, i = #oTimers;
	for i = 1, iCnt do
		DEFAULT_CHAT_FRAME:AddMessage(i .. ": " .. oTimers[i].t .. " => " .. oTimers[i].p);
	end

	local	iCnt, i = #oTimersSub;
	for i = 1, iCnt do
		DEFAULT_CHAT_FRAME:AddMessage(i .. ": " .. oTimersSub[i]);
	end
end
]]--

function	CommonersQuest.Main.Refresh(self)
--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Start" };

	-- CQH.CommChat("DbgInfo", "Quest", "State = <" .. CQH.TableToString(CommonersQuest.Main.State) .. ">");
	local	iTotal, iItem, iReward = 0, 0, 0;

	-- workaround to GetBottom() randomization when the button is "moved" while visible
	iTotal = iTotal + 1;
	local	Btn = getglobal("CQKEP_Main_QuestButton" .. iTotal);
	while (Btn) do
		Btn:Hide();
		local	BtnPrereq = getglobal("CQKEP_Main_PrereqButton" .. iTotal);
		if (BtnPrereq ~= nil) then
			BtnPrereq:Hide();
		end
		local	BtnReq = getglobal("CQKEP_Main_ReqButton" .. iTotal);
		if (BtnReq ~= nil) then
			BtnReq:Hide();
		end
		local	BtnEnd = getglobal("CQKEP_Main_QuestEnd" .. iTotal);
		if (BtnEnd ~= nil) then
			BtnEnd:Hide();
		end

		iTotal = iTotal + 1;
		Btn = getglobal("CQKEP_Main_QuestButton" .. iTotal);
	end

	iItem = iItem + 1;
	local	Btn = getglobal("CQKEP_Main_ItemButton" .. iItem);
	while (Btn) do
		Btn:Hide();
		iItem = iItem + 1;
		Btn = getglobal("CQKEP_Main_ItemButton" .. iItem);
	end

	iReward = iReward + 1;
	local	Btn = getglobal("CQKEP_Main_RewardButton" .. iReward);
	while (Btn) do
		Btn:Hide();
		iReward = iReward + 1;
		Btn = getglobal("CQKEP_Main_RewardButton" .. iReward);
	end

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Initial hiding done" };

	iTotal, iItem, iReward = 0, 0, 0;

	local	function	AddOrUpdateQuestButton(oQuest, bEnabled, bInvalid, bLocked)
			if (bInvalid) then
				if (not CommonersQuest.Main.State.Invalid) then
					return
				end
			end
			if (bEnabled) then
				if (not CommonersQuest.Main.State.Enabled) then
					return
				end
			else
				if (not CommonersQuest.Main.State.Disabled) then
					return
				end
			end

--			local	iStart, iEnd;
--			iStart = GetTime();

			local	iQuestID = oQuest.ID;

			iTotal = iTotal + 1;

			local	oQuestframe = _G["CQKEP_Main_Questframe" .. iTotal];
			if (oQuestframe == nil) then
				oQuestframe = CreateFrame("Frame", "CQKEP_Main_Questframe" .. iTotal, CommonersQuestMainScrollChildFrame);
				oQuestframe:SetWidth(CommonersQuestMainScrollChildFrame:GetWidth() - 25);
				oQuestframe:SetHeight(20);
				oQuestframe:SetID(iTotal);
			end

			if (iTotal == 1) then
				oQuestframe:SetPoint("TOPLEFT", "CommonersQuestMainScrollChildFrame", "TOPLEFT");
			else
				oQuestframe:SetPoint("TOPLEFT", "CQKEP_Main_Questframe" .. (iTotal - 1), "BOTTOMLEFT");
			end
			oQuestframe:Show();

			local	Btn = getglobal("CQKEP_Main_QuestButton" .. iTotal);
			if (Btn == nil) then
				Btn = CreateFrame("Button", "CQKEP_Main_QuestButton" .. iTotal,  oQuestframe, "CQKEP_Main_QuestButtonTemplate");
				Btn:SetID(iTotal);
			end
			Btn.Tip = "Click left to fully expand/collapse/expand this quest.\nClick middle to check the validitity of the quest.\nClick right to enable/view/disable/edit this quest or add a rewardset.";

			do
				local	BtnLockFG = getglobal("CQKEP_Main_QuestButton" .. iTotal .. "LockedFG");
				local	BtnLockBG = getglobal("CQKEP_Main_QuestButton" .. iTotal .. "LockedBG");
				if (bLocked) then
					-- BtnLock:SetTexture("Interface\\Icons\\INV_Misc_Gift_01");
					BtnLockFG:SetTexture("Interface\\Icons\\INV_ValentinesBoxOfChocolates01");
					BtnLockBG:SetTexture(1, 0.3, 0.3);
				else
					-- BtnLock:SetTexture("Interface\\Icons\\INV_Misc_Note_04");
					BtnLockFG:SetTexture("Interface\\Icons\\INV_ValentinesCard02");
					BtnLockBG:SetTexture(0.5, 1, 0.5);
				end

				local	BtnText = getglobal("CQKEP_Main_QuestButton" .. iTotal .. "Text");
				BtnText:SetText("Quest " .. CQH.QuestToPseudoLink(oQuest.ID, oQuest.Title));
				if (bInvalid) then
					BtnText:SetTextColor(  1,   1, 0.5);
				elseif (not bEnabled) then
					BtnText:SetTextColor(  1, 0.5, 0.5);
				else
					BtnText:SetTextColor(0.5,   1, 0.5);
				end
			end

			Btn:SetPoint("TOPLEFT", oQuestframe, "TOPLEFT");
			Btn.questID = iQuestID;
			Btn:Show();

			local	BtnEnd = getglobal("CQKEP_Main_QuestEnd" .. iTotal);
			if (BtnEnd == nil) then
				BtnEnd = CreateFrame("Frame", "CQKEP_Main_QuestEnd" .. iTotal,  oQuestframe, "CQKEP_Main_QuestEndTemplate");
			end

			-- potentially not used
			local	BtnPrereq = getglobal("CQKEP_Main_PrereqButton" .. iTotal);
			if (BtnPrereq ~= nil) then
				BtnPrereq:Hide();
			end
			local	BtnReq = getglobal("CQKEP_Main_ReqButton" .. iTotal);
			if (BtnReq ~= nil) then
				BtnReq:Hide();
			end

			-- rebuild from the ground up
			local	sAnchorLeft, sAnchorRight = "CQKEP_Main_QuestButton" .. iTotal;
			BtnEnd:SetPoint("LEFT", sAnchorLeft, "LEFT");

			if (CommonersQuest.Main.Collapsed[iQuestID] == nil) then
				CommonersQuest.Main.Collapsed[iQuestID] = 0;
			end

--			iEnd = GetTime();
--			oTimersSub[1] = oTimersSub[1] + iEnd - iStart;
--			iStart = GetTime();

			if (CommonersQuest.Main.Collapsed[iQuestID] >= 0) then
				local	bShowAll = CommonersQuest.Main.Collapsed[iQuestID] == 1;
				if (CommonersQuest.Main.State.PreReq ~= false) then
					local	sPreReq, sTip, k, v = "", "";
					for k, v in pairs(oQuest.ContractPreReq) do
						local	bAdd, w = true, v;
						if (k == "Faction") then
							bAdd = v ~= "Any";
						elseif (k == "Repeatable") then
							bAdd = v ~= -1;
							if (bAdd) then
								if (v == 0) then
									w = "Always";
								else
									w = v .. " days";
								end
							end
						elseif (k == "Gender") then
							if (v == 2) then
								w = "Male";
							elseif (v == 3) then
								w = "Female";
							else
								w = "??? (" .. v .. ")";
							end
						end
						if (bAdd) then
							sPreReq = sPreReq .. ", " .. k .. ": " .. w;
						end
					end
					if (not CQH.TableIsEmpty(oQuest.ContractPreClass)) then
						local	sTipSub, l, w = "";
						for l, w in pairs(oQuest.ContractPreClass) do
							if (w) then
								sTipSub = sTipSub .. ", " .. l;
							end
						end
						if (sTipSub ~= "") then
							sTip = sTip .. "\nClasses: " .. strsub(sTipSub, 3);
						end

						sPreReq = sPreReq .. ", (" .. iCnt .. " class(es))";
					end
					if (not CQH.TableIsEmpty(oQuest.ContractPreRace)) then
						local	sTipSub, iCnt, l, w = "", 0;
						for l, w in pairs(oQuest.ContractPreRace) do
							if (w) then
								iCnt = iCnt + 1;
								sTipSub = sTipSub .. ", " .. l;
							end
						end
						if (sTipSub ~= "") then
							sTip = sTip .. "\nRaces: " .. strsub(sTipSub, 3);
						end

						sPreReq = sPreReq .. ", (" .. iCnt .. " race(s))";
					end
					if (not CQH.TableIsEmpty(oQuest.ContractPreQ)) then
						local	iCnt, l, w = 0;
						for l, w in pairs(oQuest.ContractPreQ) do
							iCnt = iCnt + 1;
							sTip = sTip .. "\nPre-quest: " .. CQH.QuestToPseudoLink(w);
						end

						sPreReq = sPreReq .. ", (" .. iCnt .. " quest(s))";
					end
					if (bShowAll or (sPreReq ~= "")) then
						local	Btn = getglobal("CQKEP_Main_PrereqButton" .. iTotal);
						if (Btn == nil) then
							Btn = CreateFrame("Button", "CQKEP_Main_PrereqButton" .. iTotal,  oQuestframe, "CQKEP_Main_PrereqButtonTemplate");
							Btn:SetID(iTotal);
						end

						if (iQuestID >= 1000000) then
							if (sTip ~= "") then
								sTip = sTip .. "\n ";
							end
							sTip = sTip .. "\nClick right to modifiy.";
							Btn.questID = iQuestID;
						else
							Btn.questID = nil;
						end
						if (sTip ~= "") then
							sTip = strsub(sTip, 2);
						end
						Btn.Tip = sTip;

						local	BtnText = getglobal("CQKEP_Main_PrereqButton" .. iTotal .. "Text");
						BtnText:SetText("Prereq.: " .. strsub(sPreReq, 3));

						Btn:SetPoint("TOPLEFT", sAnchorLeft, "BOTTOMLEFT");
						Btn:Show();

						sAnchorLeft = "CQKEP_Main_PrereqButton" .. iTotal;
					end
				end

--				iEnd = GetTime();
--				oTimersSub[2] = oTimersSub[2] + iEnd - iStart;
--				iStart = GetTime();

				if (CommonersQuest.Main.State.Req ~= false) then
					local	oMetaReq, iCnt, sTip, i = {}, #oQuest.Requirements, "";
					for i = 1, iCnt do
						local	oReq = oQuest.Requirements[i];
						if (oMetaReq[oReq.Type] == nil) then
							oMetaReq[oReq.Type] = 0;
						end
						oMetaReq[oReq.Type] = oMetaReq[oReq.Type] + 1;
						if (oReq.Type ~= "Loot") then
							sTip = sTip .. "\n" .. CQH.RequirementToTextForEdit(oReq);
						end
					end

					local	sReq, k, v = "";
					for k, v in pairs(oMetaReq) do
						if (k ~= "Loot") then
							sReq = sReq .. ", " .. k .. "(" .. v .. ")";
						end
					end
					if (bShowAll or (sReq ~= "") or oMetaReq["Loot"]) then
						local	Btn = getglobal("CQKEP_Main_ReqButton" .. iTotal);
						if (Btn == nil) then
							Btn = CreateFrame("Button", "CQKEP_Main_ReqButton" .. iTotal,  oQuestframe, "CQKEP_Main_RequiredButtonTemplate");
							Btn:SetID(iTotal);
						end

						if (iQuestID >= 1000000) then
							if (sTip ~= "") then
								sTip = sTip .. "\n ";
							end
							sTip = sTip .. "\nClick left to add/modify requirements\nClick middle to modify duel/riddle parameters\nClick right to remove requirements";
							Btn.questID = iQuestID;
						else
							Btn.questID = nil;
						end
						if (sTip ~= "") then
							sTip = strsub(sTip, 2);
						end
						Btn.Tip = sTip;

						local	BtnText = getglobal("CQKEP_Main_ReqButton" .. iTotal .. "Text");
						BtnText:SetText("Require.: " .. strsub(sReq, 3));

						Btn:SetPoint("TOPLEFT", sAnchorLeft, "BOTTOMLEFT");
						Btn:Show();

						sAnchorLeft = "CQKEP_Main_ReqButton" .. iTotal;

						if (oMetaReq["Loot"]) then
							local	iThis = 0;
							for i = 1, iCnt do
								local	oReq = oQuest.Requirements[i];
								if (oReq.Type == "Loot") then
									-- create and setup buttons
									iThis = iThis + 1;
									iItem = iItem + 1;
									local	Btn = getglobal("CQKEP_Main_ItemButton" .. iItem);
									if (Btn == nil) then
										Btn = CreateFrame("Button", "CQKEP_Main_ItemButton" .. iItem,  oQuestframe, "CQKEP_TinyItemTemplate");
										Btn:SetScript("OnEnter", CommonersQuest.ItemEnter);
										Btn:SetScript("OnClick", CommonersQuest.ItemClicked);
									end
									Btn:SetID(oReq.ItemID);
									Btn.questID = iQuestID;
									Btn:Show();

									local	_, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo(oReq.ItemID);
									local	BtnTexture = getglobal("CQKEP_Main_ItemButton" .. iItem .. "IconTexture");
									BtnTexture:SetTexture(sItemTexture);
									BtnTexture:Show();
									local	BtnCount = getglobal("CQKEP_Main_ItemButton" .. iItem .. "Count");
									if (oReq.Count and (oReq.Count > 1)) then
										BtnCount:SetText(oReq.Count or 1);
										BtnCount:Show();
									else
										BtnCount:Hide();
									end

									if (iThis == 1) then
										Btn:SetPoint("TOPLEFT", sAnchorLeft, "BOTTOMLEFT", 40, 0);
										sAnchorLeft = "CQKEP_Main_ItemButton" .. iItem;
									else
										Btn:SetPoint("TOPLEFT", "CQKEP_Main_ItemButton" .. (iItem - 1), "TOPRIGHT", 2, 0);
									end
								end
							end
						end
					end
				end

--				iEnd = GetTime();
--				oTimersSub[3] = oTimersSub[3] + iEnd - iStart;
--				iStart = GetTime();

				if (CommonersQuest.Main.State.Rew ~= false) then
					local	iQuestID, k, v = oQuest.ID;
					for k, v in pairs(CQDataGlobal.Rewards[iQuestID]) do
						local	iCnt, sReward, sTip, i = #v.Set, "", "";
						for i = 1, iCnt do
							local	oReward = v.Set[i];
							if (oReward.Type == "Money") then
								if (oReward.Amount ~= 0) then
									sReward = sReward .. ", Money (" .. CQH.MoneyToString(oReward.Amount) .. ")";
								end
							elseif (oReward.Type == "Title") then
								sReward = sReward .. ", Title";
								sTip = sTip .. "\nTitle: " .. oReward.Title;
							end
						end

						-- reward button with: title, money reward
						local	sBtnText = "Rewardset " .. k;
						if (sReward ~= "") then
							sBtnText = sBtnText .. ": " .. strsub(sReward, 3);
						end

						iReward = iReward + 1;
						local	Btn = getglobal("CQKEP_Main_RewardButton" .. iReward);
						if (Btn == nil) then
							Btn = CreateFrame("Button", "CQKEP_Main_RewardButton" .. iReward,  oQuestframe, "CQKEP_Main_RewardsetButtonTemplate");
							Btn:SetID(iReward);
						end
						if (sTip ~= "") then
							sTip = sTip .. "\n ";
						end
						sTip = "Rewardset " .. k .. ":" .. sTip .. "\nClick left to add/modify fixed reward\nClick middle to add choosable reward\nClick right to remove a reward";
						Btn.Tip = sTip;
						Btn.questID = iQuestID;
						Btn.rewardsetX = k;

						local	BtnText = getglobal("CQKEP_Main_RewardButton" .. iReward .. "Text");
						BtnText:SetText(sBtnText);

						Btn:SetPoint("TOPLEFT", "CQKEP_Main_QuestButton" .. iTotal, "TOPRIGHT", 50, 0);
						Btn:Show();

						sAnchorRight = "CQKEP_Main_RewardButton" .. iReward;

						-- loot buttons
						local	iThis = 0;
						for i = 1, iCnt do
							local	oReward = v.Set[i];
							if (oReward.Type == "Item") then
								iThis = iThis + 1;
								iItem = iItem + 1;
								local	Btn = getglobal("CQKEP_Main_ItemButton" .. iItem);
								if (Btn == nil) then
									Btn = CreateFrame("Button", "CQKEP_Main_ItemButton" .. iItem,  oQuestframe, "CQKEP_TinyItemTemplate");
									Btn:SetScript("OnEnter", CommonersQuest.ItemEnter);
									Btn:SetScript("OnClick", CommonersQuest.ItemClicked);
								end
								Btn:SetID(oReward.ItemID);
								Btn:Show();

								local	_, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo(oReward.ItemID);
								local	BtnTexture = getglobal("CQKEP_Main_ItemButton" .. iItem .. "IconTexture");
								BtnTexture:SetTexture(sItemTexture);
								BtnTexture:Show();
								local	BtnCount = getglobal("CQKEP_Main_ItemButton" .. iItem .. "Count");
								if (oReward.Count and (oReward.Count > 1)) then
									BtnCount:SetText(oReward.Count or 1);
									BtnCount:Show();
								else
									BtnCount:Hide();
								end

								if (iThis == 1) then
									Btn:SetPoint("TOPLEFT", sAnchorRight, "BOTTOMLEFT", 20, 0);
									sAnchorRight = "CQKEP_Main_ItemButton" .. iItem;
								else
									Btn:SetPoint("TOPLEFT", "CQKEP_Main_ItemButton" .. (iItem - 1), "TOPRIGHT", 2, 0);
								end
							end
						end
					end
				end
			end

--			iEnd = GetTime();
--			oTimersSub[4] = oTimersSub[4] + iEnd - iStart;
--			iStart = GetTime();

			local	sAnchor;
			if (sAnchorRight == nil) then
				sAnchor = sAnchorLeft;
			else
				local	iYL = 10000;
				local	oAnchorLeft = getglobal(sAnchorLeft);
				if (oAnchorLeft) then
					iYL = oAnchorLeft:GetBottom();
				end
				local	iYR = 10000;
				local	oAnchorRight = getglobal(sAnchorRight);
				if (oAnchorRight) then
					iYR = oAnchorRight:GetBottom();
				end
				if (iYL < iYR) then
					sAnchor = sAnchorLeft;
				else
					sAnchor = sAnchorRight;
				end

				-- CQH.CommChat("DbgSpam", "Quest", "AL = " .. strsub(sAnchorLeft, 12) .. "/iYL = " .. math.floor(iYL) .. ", AR = " .. strsub(sAnchorRight, 12) .. "/iYR = " .. math.floor(iYR) .. "; => " .. strsub(sAnchor, 12));
			end

			BtnEnd:SetPoint("TOP", sAnchor, "BOTTOM");

			-- DEFAULT_CHAT_FRAME:AddMessage("Y1: " .. BtnEnd:GetTop() .. ", Y2: " .. oQuestframe:GetTop());
			oQuestframe:SetHeight(10 + oQuestframe:GetTop() - BtnEnd:GetTop());

--			iEnd = GetTime();
--			oTimersSub[5] = oTimersSub[5] + iEnd - iStart;
--			iStart = GetTime();
		end

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Creating quest blocks" };

	local	k, v;
	for k, v in pairs(CommonersQuest.QuestDB) do
		if (v.ID < 1000000) then
			local	bDeleted = false;
			local	bEnabled = false;
			if (CQDataX.Giver.QuestStates[v.ID]) then
				bDeleted = CQDataX.Giver.QuestStates[v.ID].Deleted == true;
				bEnabled = CQDataX.Giver.QuestStates[v.ID].Enabled == true;
			end
			if (bDeleted ~= true) then
				local	bInvalid = not CommonersQuest.ValidateQuest(v.ID, false, -2);
				AddOrUpdateQuestButton(v, bEnabled, bInvalid, true);
			end
		end
	end

	for k, v in pairs(CQDataGlobal.CustomQuests) do
		local	bDeleted = false;
		local	bEnabled = false;
		local	bLocked = false;
		if (CQDataX.Giver.QuestStates[v.ID]) then
			bEnabled = CQDataX.Giver.QuestStates[v.ID].Enabled == true;
		end
		if (CQDataGlobal.Giver.QuestStates[v.ID]) then
			bDeleted = CQDataGlobal.Giver.QuestStates[v.ID].Deleted == true;
			bLocked = CQDataGlobal.Giver.QuestStates[v.ID].Locked == true;
		end
		if (bDeleted ~= true) then
			local	bInvalid = not CommonersQuest.ValidateQuest(v.ID, false, -2);
			AddOrUpdateQuestButton(v, bEnabled, bInvalid, bLocked);
		end
	end

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Quest blocks: hiding unused/hidden" };

	do
		local	iQTotal = iTotal + 1;
		local	oQuestframe = _G["CQKEP_Main_Questframe" .. iQTotal];
		while (oQuestframe) do
			oQuestframe:Hide();
			iQTotal = iQTotal + 1;
			oQuestframe = _G["CQKEP_Main_Questframe" .. iQTotal];
		end
	end

--	[#oTimers + 1] = { t = GetTime(), p = "Quest blocks done" };

	-- CQH.CommChat("DbgSpam", "Quest", "---------------------------------");

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Creating totals" };

	-- reserved reward totals
	iReward = iReward + 1;
	local	Btn = getglobal("CQKEP_Main_RewardButton" .. iReward);
	if (Btn == nil) then
		Btn = CreateFrame("Button", "CQKEP_Main_RewardButton" .. iReward,  CommonersQuestMainScrollChildFrame, "CQKEP_Main_RewardsetButtonTemplate");
		Btn:SetID(iReward);
	end

	local	BtnText = getglobal("CQKEP_Main_RewardButton" .. iReward .. "Text");
	BtnText:SetText("Total reserved rewards:");

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Totals done" };

	if (iTotal == 0) then
		Btn:SetPoint("TOPLEFT", "CommonersQuestMainScrollChildFrame", "TOPLEFT");
	else
		Btn:SetPoint("TOPLEFT", "CQKEP_Main_QuestEnd" .. iTotal, "BOTTOMLEFT", 0, -20);
	end
	Btn:Show();

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Bottom defined" };

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Post positioning start" };

	local	iThis, k, v = 0;
	for k, v in pairs(CQDataItems) do
		if ((type(k) == "number") and ((v.Count == nil) or (v.Count["Total#"] ~= 0))) then
			iThis = iThis + 1;
			iItem = iItem + 1;
			local	Btn = getglobal("CQKEP_Main_ItemButton" .. iItem);
			if (Btn == nil) then
				Btn = CreateFrame("Button", "CQKEP_Main_ItemButton" .. iItem,  CommonersQuestMainScrollChildFrame, "CQKEP_TinyItemTemplate");
				Btn:SetScript("OnEnter", CommonersQuest.ItemEnter);
				Btn:SetScript("OnClick", CommonersQuest.ItemClicked);
			end
			Btn:SetID(k);
			Btn:Show();

			local	_, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo(k);
			local	BtnTexture = getglobal("CQKEP_Main_ItemButton" .. iItem .. "IconTexture");
			BtnTexture:SetTexture(sItemTexture);
			BtnTexture:Show();
			local	BtnCount = getglobal("CQKEP_Main_ItemButton" .. iItem .. "Count");
			local	iCount;
			if (v.Count and v.Count["Total#"]) then
				iCount = v.Count["Total#"];
			end
			if (iCount) then
				BtnCount:SetText(iCount);
			else
				BtnCount:SetText("???");
			end
			BtnCount:Show();

			if (iThis == 1) then
				Btn:SetPoint("TOPLEFT", "CQKEP_Main_RewardButton" .. iReward, "BOTTOMLEFT", 20, 0);
			else
				Btn:SetPoint("TOPLEFT", "CQKEP_Main_ItemButton" .. (iItem - 1), "TOPRIGHT", 2, 0);
			end
		end
	end

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Post positioning end" };

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Hiding unused buttons start" };

	iTotal = iTotal + 1;
	local	Btn = getglobal("CQKEP_Main_QuestButton" .. iTotal);
	while (Btn) do
		Btn:Hide();
		local	BtnPrereq = getglobal("CQKEP_Main_PrereqButton" .. iTotal);
		if (BtnPrereq ~= nil) then
			BtnPrereq:Hide();
		end
		local	BtnReq = getglobal("CQKEP_Main_ReqButton" .. iTotal);
		if (BtnReq ~= nil) then
			BtnReq:Hide();
		end
		local	BtnEnd = getglobal("CQKEP_Main_QuestEnd" .. iTotal);
		if (BtnEnd ~= nil) then
			BtnEnd:Hide();
		end

		iTotal = iTotal + 1;
		Btn = getglobal("CQKEP_Main_QuestButton" .. iTotal);
	end

	iItem = iItem + 1;
	local	Btn = getglobal("CQKEP_Main_ItemButton" .. iItem);
	while (Btn) do
		Btn:Hide();
		iItem = iItem + 1;
		Btn = getglobal("CQKEP_Main_ItemButton" .. iItem);
	end

	iReward = iReward + 1;
	local	Btn = getglobal("CQKEP_Main_RewardButton" .. iReward);
	while (Btn) do
		Btn:Hide();
		iReward = iReward + 1;
		Btn = getglobal("CQKEP_Main_RewardButton" .. iReward);
	end

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "Hiding unused buttons end" };

--	oTimers[#oTimers + 1] = { t = GetTime(), p = "End" };
end

function	CommonersQuest.Main.OnEvent(self, event, ...)
end

function	CommonersQuest.Main.QuestClicked(self, mousebtn)
	if (mousebtn == "LeftButton") then
		-- collapse/expand
		local	iValue = CommonersQuest.Main.Collapsed[self.questID] + 1;
		if (iValue == 2) then
			iValue = -1;
		end
		CommonersQuest.Main.Collapsed[self.questID] = iValue;
		CommonersQuest.Main.Refresh(CommonersQuestMainframe);
	end
	if (mousebtn == "MiddleButton") then
		local	oQuest = CQH.CharQuestToObj(nil, self.questID);
		if (oQuest) then
			local	function	fFillTip(sAudience, sImportance, sMessage)
					if (strsub(sAudience, 1, 4) == "Chat") then
						GameTooltip:AddLine(sMessage);
					end
				end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			local	bResult = CommonersQuest.ValidateQuest(oQuest.ID, true, -2, nil, fFillTip);
			if (bResult) then
				GameTooltip:AddLine(" ");
				GameTooltip:AddLine("Quest is valid.");
			end
			GameTooltip:Show();
		end
	end
	if (mousebtn == "RightButton") then
		CommonersQuestMainQuestEditMenu.questID = self.questID;
		ToggleDropDownMenu(1, nil, CommonersQuestMainQuestEditMenu, self, 0, 0);
	end
end

function	CommonersQuest.Main.QuestEditMenu_Initialize(oFrame, iLevel)
	if (oFrame.questID == nil) then
		return
	end

	local	oQuest = CQH.CharQuestToObj(nil, oFrame.questID);
	local	bValid = CommonersQuest.ValidateQuest(oFrame.questID, false, -2);
	local	oStateGlobal, oStatePerChar = CQH.InitStateGiver(oQuest);

	local	info = {};
	info.text = "Quest" .. CQH.QuestToPseudoLink(oQuest.ID, oQuest.Title);
	info.notCheckable = 1;
	info.isTitle = 1;
	UIDropDownMenu_AddButton(info, iLevel);

	local	MMC = CommonersQuest.MMC;
	local	MMT = CommonersQuest.MMT;

	local	function	fDo(bOk, oParent, oQuest, iLevel)
			info = {};
			info.text = MMT[oParent];
			if (oParent == MMC.EDITQUEST) then
				info.text = "Edit quest texts";
			end
			info.value = oQuest.ID * 16 + oParent;
			info.func = CommonersQuest.LDBMenu.QuestActionClicked;
			info.arg1 = oParent;
			info.arg2 = oQuest.ID;
			if (not bOk) then
				info.disabled = 1;
			end
			if (oParent == MMC.ENABLE) then
				if (oStatePerChar.Enabled) then
					info.checked = 1;
				end
			elseif (oParent == MMC.DISABLE) then
				if (not oStatePerChar.Enabled) then
					info.checked = 1;
				end
			end
			UIDropDownMenu_AddButton(info, iLevel);
		end

	local	oParent;
	for oParent = MMC.ENABLE, MMC.EDITQUEST do
		local	bShow, bOk, bArrow = true;
		if (oParent == MMC.ENABLE) then
			bOk = (oStatePerChar.Enabled ~= true);
			if (bOk) then
				bOk = CommonersQuest.ValidateQuest(oQuest.ID);
			end
		elseif (oParent == MMC.VIEWQUEST) then
			bShow = (oStateGlobal.Locked == true);
			bOk = true;
		elseif (oParent == MMC.DISABLE) then
			bOk = (oStatePerChar.Enabled == true);
		elseif (oParent == MMC.EDITQUEST) then
			bShow = (oStateGlobal.Locked ~= true);
			bOk = true;
		else
			bShow = false;
		end

		if (bShow) then
			fDo(bOk, oParent, oQuest, iLevel);
		end
	end

	info = {};
	info.text = MMT[MMC.REWARDSETADDNEW];
	info.func = CommonersQuest.LDBMenu.RewardSetAddNew;
	info.arg1 = oQuest.ID;
	UIDropDownMenu_AddButton(info, iLevel);

	info = {};
	info.text = "-----------------------";
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	info.notClickable = 1;
	UIDropDownMenu_AddButton(info, iLevelOut);

	info = {};
	info.text = MMT[MMC.SETKEY];
	info.func = CommonersQuest.LDBMenu.QuestActionClicked;
	info.arg1 = MMC.SETKEY;
	info.arg2 = oQuest.ID;
	if (oStateGlobal.Key) then
		info.checked = 1;
		info.disabled = 1;
		info.text = info.text .. ": " .. oStateGlobal.Key;
	end
	UIDropDownMenu_AddButton(info, iLevelOut);

	info = {};
	info.text = MMT[MMC.DELKEY];
	info.func = CommonersQuest.LDBMenu.QuestActionClicked;
	info.arg1 = MMC.DELKEY;
	info.arg2 = oQuest.ID;
	if (oStateGlobal.Key == nil) then
		info.disabled = 1;
	end
	UIDropDownMenu_AddButton(info, iLevelOut);

	info = {};
	info.text = MMT[MMC.YELLKEY];
	info.func = CommonersQuest.LDBMenu.QuestActionClicked;
	info.arg1 = MMC.YELLKEY;
	info.arg2 = oQuest.ID;
	if (oStateGlobal.Key == nil) then
		info.disabled = 1;
	end
	UIDropDownMenu_AddButton(info, iLevelOut);

	if ((oStateGlobal.Locked ~= true) and (oStatePerChar.Enabled ~= true)) then
		info = {};
		info.text = "-----------------------";
		info.justifyH = "CENTER";
		info.notClickable = 1;
		UIDropDownMenu_AddButton(info, iLevelOut);

		info = {};
		info.text = MMT[MMC.BINDALLOWNONE];
		info.func = CommonersQuest.LDBMenu.QuestActionClicked;
		info.arg1 = MMC.BINDALLOWNONE;
		info.arg2 = oQuest.ID;
		if (oStateGlobal.NoBindingItem == true) then
			info.checked = 1;
		end
		UIDropDownMenu_AddButton(info, iLevel);
	end

	info = {};
	info.text = "-----------------------";
	info.justifyH = "CENTER";
	info.notClickable = 1;
	UIDropDownMenu_AddButton(info, iLevelOut);

	info = {};
	info.text = MMT[MMC.COPYQUEST];
	info.func = CommonersQuest.LDBMenu.QuestActionClicked;
	info.arg1 = MMC.COPYQUEST;
	info.arg2 = oQuest.ID;
	UIDropDownMenu_AddButton(info, iLevel);

	info = {};
	info.text = MMT[MMC.DELETEQUEST];
	info.func = CommonersQuest.LDBMenu.QuestActionClicked;
	info.arg1 = MMC.DELETEQUEST;
	info.arg2 = oQuest.ID;
	UIDropDownMenu_AddButton(info, iLevel);
end

function	CommonersQuest.Main.PrereqMenu_Initialize(oFrame, iLevel)
	if (oFrame.questID) then
		CQH.CommChat("DbgSpam", nil, "Going in... questID = " .. oFrame.questID .. ", level = " .. (iLevel or 1));

		iLevel = iLevel or 1;
		if (iLevel == 1) then
			oParent = oFrame.questID * 16 + CommonersQuest.MMC.EDITREPREQ;
		else
			oParent = UIDROPDOWNMENU_MENU_VALUE;
		end
		CommonersQuest.LDBMenu.InitializeIndirect(oFrame, oParent, 2 + iLevel, iLevel);
	end
end


function	CommonersQuest.Main.PrereqClicked(self, mousebtn)
	if (self.questID == nil) then
		CQH.CommChat("ChatInfo", nil, "You cannot change the pre-requirements for default quests. Sorry!");
	else
		CQH.CommChat("DbgInfo", "Edit", "Clicked on pre-req for " .. (self.questID or "<nil>") .. " with " .. (mousebtn or "<nil>") .. "...");

		local	oState = CQDataGlobal.Giver.QuestStates[self.questID];
		if (oState and oState.Locked) then
			CQH.CommChat("ChatInfo", nil, "You cannot change the pre-requirements for this quest any longer, as it is locked. Sorry!");
		else
			CommonersQuestPrereqMenu.questID = self.questID;
			ToggleDropDownMenu(1, nil, CommonersQuestPrereqMenu, self, 0, 0);
		end
	end
end

function	CommonersQuest.Main.RequiredClicked(self, mousebtn)
	if (self.questID == nil) then
		CQH.CommChat("ChatInfo", nil, "You cannot change the requirements for default quests. Sorry!");
	else
		CQH.CommChat("DbgInfo", "Edit", "Clicked on requirements for " .. (self.questID or "<nil>") .. " with " .. (mousebtn or "<nil>") .. "...");

		local	oState = CQDataGlobal.Giver.QuestStates[self.questID];
		if (oState and oState.Locked) then
			CQH.CommChat("ChatInfo", nil, "You cannot change the requirements for this quest any longer, as it is locked. Sorry!");
		else
			CommonersQuest.Menu.QuestID = self.questID;
			CommonersQuest.QuestEdit.InitMenuIndirect(self, mousebtn, "Require");
		end
	end
end

function	CommonersQuest.Main.RewardsetClicked(self, mousebtn)
	if ((self.questID ~= nil) and (self.rewardsetX ~= nil)) then
		CQH.CommChat("DbgInfo", "Edit", "Clicked on reward set " .. self.rewardsetX .. " for " .. self.questID .. " with " .. (mousebtn or "<nil>") .. "...");

		local	oRewardset;
		if (self.questID and CQDataGlobal.Rewards[self.questID]) then
			local	oRewardsets = CQDataGlobal.Rewards[self.questID];
			oRewardset = oRewardsets[self.rewardsetX];
		end

		if (oRewardset) then
			CQH.RewardCheckLock(oRewardset);
			if (oRewardset.State.Locked) then
				CQH.CommChat("ChatInfo", nil, "You cannot change this rewardset at this time, as it is locked for " .. (oRewardset.State.LockedTo or "<error!>") .. ". Sorry!");
			else
				CommonersQuest.Menu.QuestID = self.questID;
				CommonersQuest.QuestEdit.InitMenuIndirect(self, mousebtn, "Reward", self.rewardsetX);
			end
		end
	end
end

function	CommonersQuest.Main.CheckOnShow(self)
	local	sKey = strsub(self:GetName(), 12);
	sKey = strsub(sKey, 1, -10);

	local	bState = CommonersQuest.Main.State[sKey];
	if (bState == nil) then
		CommonersQuest.Main.State[sKey] = true;
		bState = true;
	end

	self:SetChecked(bState);
end

function	CommonersQuest.Main.CheckOnClick(self, mousebtn)
	if (mousebtn == "LeftButton") then
		local	sKey = strsub(self:GetName(), 12);
		sKey = strsub(sKey, 1, -10);

		local	bState = not CommonersQuest.Main.State[sKey];
		CommonersQuest.Main.State[sKey] = bState;

		CommonersQuest.Main.Refresh(CommonersQuestMainframe);
	end
end

function	CommonersQuest.Main.SetupTip(self)
	if (self.Tip and (self.Tip ~= "")) then
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");

		-- get rid of larger first line
		GameTooltip:AddLine(" ");
		GameTooltipTextLeft1:SetText("");

		local	oLines, iCnt, i = {}, 0;
		local	sTip = self.Tip;
		while (sTip ~= "") do
			local	iPos = strfind(sTip, "\n");
			if (iPos) then
				iCnt = iCnt + 1;
				oLines[iCnt] = strsub(sTip, 1, iPos - 1);
				sTip = strsub(sTip, iPos + 1);
			else
				iCnt = iCnt + 1;
				oLines[iCnt] = sTip;
				sTip = "";
			end
		end

		for i = 1, iCnt do
			GameTooltip:AddLine(oLines[i]);
		end
		GameTooltip:Show();
		if (GameTooltip:GetWidth() > 500) then
			GameTooltip:SetWidth(425);
			for i = 1, iCnt do
				_G["GameTooltipTextLeft" .. (i + 1)]:SetWidth(400);
			end
			GameTooltip:Show();
		end
	end
end

