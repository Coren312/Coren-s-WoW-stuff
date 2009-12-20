
local	CQData = nil;
local	CQDataX = nil;
local	CQDataGlobal = nil;
local	CQH = CommonersQuest.Helpers;

CommonersQuest.Reward = {};

local	Module = {
		QuestCnt = 0,
		QuestCurr = 0,
		RewardCnt = 0,
		RewardCurr = 0,
	};

function	CommonersQuest.Initializers.Rewards(CQDataMain, CQDataXMain, CQDataGlobalMain)
	CQData = CQDataMain;
	CQDataX = CQDataXMain;
	CQDataGlobal = CQDataGlobalMain;
end

function	CommonersQuest.Reward.OnLoad(self)
end

function	CommonersQuest.Reward.OnShow(self)
	local	iCnt = 0;
	local	function	AddOrUpdateQuestButton(oQuest)
			iCnt = iCnt + 1;
			local	Btn = getglobal("CQKEP_QuestButton" .. iCnt);
			if (Btn == nil) then
				Btn = CreateFrame("Button", "CQKEP_QuestButton" .. iCnt, CommonersQuestRewardframe, "CQKEP_QuestButtonTemplate");
				Btn:SetID(iCnt);
				if (iCnt == 1) then
					Btn:SetPoint("TOPLEFT", "CQKEP_QuestListTitle", "BOTTOMLEFT", 0, -5);
				else
					Btn:SetPoint("TOPLEFT", "CQKEP_QuestButton" .. (iCnt - 1), "BOTTOMLEFT", 0, -2);
				end
			end
			Btn:Show();
			Btn:UnlockHighlight();
			Btn.questID = oQuest.ID;
			getglobal("CQKEP_QuestButton" .. iCnt .. "Text"):SetText(oQuest.ID .. ": " .. oQuest.Title);
		end

	local	k, v;
	for k, v in pairs(CommonersQuest.QuestDB) do
		if (v.ID < 1000000) then
			AddOrUpdateQuestButton(v);
		end
	end

	for k, v in pairs(CQDataGlobal.CustomQuests) do
		AddOrUpdateQuestButton(v);
	end

	CommonersQuestRewardframe:SetHeight(50 + iCnt * 18);

	Module.QuestCnt = iCnt;

	CQH.CommChat("DbgInfo", "Quest", "Found " .. iCnt .. " quests.");

	-- as soon as quests can be deleted, must remove additional buttons
	iCnt = iCnt + 1;
	local	Btn = getglobal("CQKEP_QuestButton" .. iCnt);
	while (Btn ~= nil) do
		Btn:Hide();

		iCnt = iCnt + 1;
		Btn = getglobal("CQKEP_QuestButton" .. iCnt);
	end
end

function	CommonersQuest.Reward.OnEvent(self, event, ...)
end

function	CommonersQuest.Reward.OnUpdateEvent(arg1)
end

function	CommonersQuest.Reward.QuestClicked(self)
	if (Module.QuestCurr > 0) then
		local	QuestNextBtn = getglobal("CQKEP_QuestButton" .. (Module.QuestCurr + 1));
		if (QuestNextBtn and QuestNextBtn:IsShown()) then
			QuestNextBtn:SetPoint("TOPLEFT", "CQKEP_QuestButton" .. Module.QuestCurr, "BOTTOMLEFT", 0, -2);
		end
	end

	local	iCnt = 1;
	local	Btn = getglobal("CQKEP_QuestButton" .. iCnt);
	while (Btn ~= nil) and (Btn:IsShown()) do
		Btn:UnlockHighlight();

		iCnt = iCnt + 1;
		Btn = getglobal("CQKEP_QuestButton" .. iCnt);
	end

	self:LockHighlight();
	Module.QuestCurr = self:GetID();

	local	iCnt = 0;
	local	function	AddOrUpdateRewardsetButton(iQuest, xSet)
			iCnt = iCnt + 1;
			local	Btn = getglobal("CQKEP_RewardsetButton" .. iCnt);
			if (Btn == nil) then
				Btn = CreateFrame("Button", "CQKEP_RewardsetButton" .. iCnt, CommonersQuestRewardframe, "CQKEP_RewardsetButtonTemplate");
				Btn:SetID(iCnt);
			end
			Btn:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 10, -2);
			Btn:Show();
			Btn:UnlockHighlight();
			Btn.questID = iQuest;
			Btn.setX = xSet;
			getglobal("CQKEP_RewardsetButton" .. iCnt .. "Text"):SetText(xSet);
		end

	local	iQuestID = self.questID;
	if (CQDataGlobal.Rewards[iQuestID] ~= nil) then
		local	k, v;
		for k, v in pairs(CQDataGlobal.Rewards[iQuestID]) do
			AddOrUpdateRewardsetButton(iQuestID, k);
		end
	end

	CQH.CommChat("DbgInfo", "Quest", "Found " .. iCnt .. " rewardsets to quest " .. iQuestID);

	Module.RewardCnt = iCnt;

	CommonersQuestRewardframe:SetHeight(50 + Module.QuestCnt * 18 + 5 + Module.RewardCnt * 18);

	if (iCnt > 0) then
		-- re-anchor next quest
		local	QuestNextBtn = getglobal("CQKEP_QuestButton" .. (Module.QuestCurr + 1));
		if (QuestNextBtn and QuestNextBtn:IsShown()) then
			QuestNextBtn:SetPoint("TOPLEFT", "CQKEP_RewardsetButton" .. iCnt, "BOTTOMLEFT", -10, -5);
		end
	end

	-- hide if previous quest had more rewardsets
	iCnt = iCnt + 1;
	local	Btn = getglobal("CQKEP_RewardsetButton" .. iCnt);
	while (Btn ~= nil) do
		Btn:Hide();

		iCnt = iCnt + 1;
		Btn = getglobal("CQKEP_RewardsetButton" .. iCnt);
	end

	CommonersQuest.Reward.RewardsetClear();

	if (Module.RewardCnt == 1) then
		CommonersQuest.Reward.RewardsetClicked(CQKEP_RewardsetButton1);
	end
end

function	CommonersQuest.Reward.RewardsetClear()
	CQKEP_RewardsetListTitle:SetText("Rewards");

	local	i;
	for i = 1, 10 do
		Btn = getglobal("CommonersQuestRewardsItem" .. i);
		Btn:Hide();
	end
end

function	CommonersQuest.Reward.RewardsetClicked(self)
	-- title, money, fixed items, choosable items
	-- use *Base.SetRewards?

	if (Module.RewardCurr > 0) then
		Btn = getglobal("CQKEP_RewardsetButton" .. Module.RewardCurr);
		Btn:UnlockHighlight();
	end

	Module.RewardCurr = self:GetID();
	self:LockHighlight();

	CommonersQuest.Reward.RewardsetClear();

	local	iQuestID = self.questID;
	local	xSet = self.setX;

	CQKEP_RewardsetListTitle:SetText("Rewards: " .. xSet);

	CQH.CommChat("DbgSpam", "Quest", "iQuestID == " .. (iQuestID or "<nil>") .. ", setX == " .. (xSet or "<nil>") .. ".");

	local	oAnchor = CQKEP_RewardsetListTitle;
	local	iTotal = 0;

	local	oSet = CQDataGlobal.Rewards[iQuestID][xSet].Set;
	local	iCnt = #oSet;
	for i = 1, iCnt do
		local	oReward = oSet[i];
		if (oReward.Type == "Item") then
			iTotal = iTotal + 1;
			local questRewardButton = getglobal("CommonersQuestRewardsItem" .. iTotal);
			local questRewardName = getglobal("CommonersQuestRewardsItem" .. iTotal .. "Name");
			local questRewardTexture = getglobal("CommonersQuestRewardsItem" .. iTotal .. "IconTexture");
			local questRewardCount = getglobal("CommonersQuestRewardsItem" .. iTotal .. "Count");
			if (oReward.Count and (oReward.Count > 1)) then
				questRewardCount:SetText(oReward.Count);
			else
				questRewardCount:SetText("");
			end

			local	iItemID = oReward.ItemID;
			questRewardButton:SetID(iItemID);
			-- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture
			local	sItemName, _, _, _, _, _, _, _, _, sItemTexture = GetItemInfo("item:" .. iItemID);
			-- DEFAULT_CHAT_FRAME:AddMessage("[CQ] Item " .. iItemID .. ": <" .. sItemName .. "> => " .. sItemTexture);
			questRewardName:SetText(sItemName);
			questRewardTexture:SetTexture(sItemTexture);
			questRewardTexture:Show();

			questRewardButton:SetScript("OnEnter", CommonersQuest.ItemEnter);
			questRewardButton:SetScript("OnClick", CommonersQuest.ItemClicked);

			if (iTotal == 1) then
				questRewardButton:SetPoint("TOPLEFT", oAnchor, "BOTTOMLEFT", 0, -5);
			elseif (iTotal <= 3) then
				questRewardButton:SetPoint("TOPLEFT", "CommonersQuestRewardsItem" .. (iTotal - 1), "TOPRIGHT", 5, 0);
			else
				questRewardButton:SetPoint("TOPLEFT", "CommonersQuestRewardsItem" .. (iTotal - 3), "BOTTOMLEFT", 0, -2);
			end

			questRewardButton:Show();
		end
	end
end

