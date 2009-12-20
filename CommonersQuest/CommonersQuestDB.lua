
CommonersQuest.Strings = {};
CommonersQuest.Strings.Item = {};
CommonersQuest.Strings.Class = { Male = {} };
CommonersQuest.Strings.Race = {
				Alliance = { Male = {}, Female = {} },
				Horde = { Male = {}, Female = {} }
	};

CommonersQuestLang = {};
CommonersQuestLang.Emotes = {};
CommonersQuestLang.EmoteList = {
		"apologize",
		"awe",
		"cheer",
		"dance",
		"flirt",
		"hug",
		"kiss",
		"kneel",
		"massage",
		"rude",
		"snarl",
	};

COMMONERSQUEST_BINDINGITEMTITLE = "Binding item";

CommonersQuest.DBMetaInfo = {};
CommonersQuest.DBMetaInfo.QuestFields = {};

CommonersQuest.DBMetaInfo.QuestFields.State = "table";
CommonersQuest.DBMetaInfo.QuestFields.StateEntries = {
		Modified = "number",
		Enabled = "boolean",
		Locked = "boolean",
	 };
CommonersQuest.DBMetaInfo.QuestFields.StateEntriesOptional = {
		Modified = false,
		Enabled = true,
		Locked = false,
	};

CommonersQuest.DBMetaInfo.QuestFields.ContractPreReq = "table";
CommonersQuest.DBMetaInfo.QuestFields.ContractPreReqEntries = {
		Faction = "string",
		MinLevel = "number",
		MaxLevel = "number",
		Gender = "number",
		Repeatable = "number",
	};
CommonersQuest.DBMetaInfo.QuestFields.ContractPreReqEntriesOptional = {
		Faction = false,
		MinLevel = true,
		MaxLevel = true,
		Gender = true,
		Repeatable = true,
	};

CommonersQuest.DBMetaInfo.QuestFields.ContractPreClass = "table:optional";
CommonersQuest.DBMetaInfo.QuestFields.ContractPreClassEntries = {
		DEATHKNIGHT = "boolean",
		DRUID = "boolean",
		HUNTER = "boolean",
		MAGE = "boolean",
		PALADIN = "boolean",
		PRIEST = "boolean",
		ROGUE = "boolean",
		SHAMAN = "boolean",
		WARRIOR = "boolean",
		WARLOCK = "boolean",
	};
CommonersQuest.DBMetaInfo.QuestFields.ContractPreClassEntriesOptional = {
		DEATHKNIGHT = true,
		DRUID = true,
		HUNTER = true,
		MAGE = true,
		PALADIN = true,
		PRIEST = true,
		ROGUE = true,
		SHAMAN = true,
		WARRIOR = true,
		WARLOCK = true,
	};

CommonersQuest.DBMetaInfo.QuestFields.ContractPreRace = "table:optional";
CommonersQuest.DBMetaInfo.QuestFields.ContractPreRaceEntries = {
		DRAENEI = "boolean",
		DWARF = "boolean",
		GNOME = "boolean",
		HUMAN = "boolean",
		NIGHTELF = "boolean",
		BLOODELF = "boolean",
		ORC = "boolean",
		TAUREN = "boolean",
		TROLL = "boolean",
		UNDEAD = "boolean",
	};
CommonersQuest.DBMetaInfo.QuestFields.ContractPreRaceEntriesOptional = {
		DRAENEI = true,
		DWARF = true,
		GNOME = true,
		HUMAN = true,
		NIGHTELF = true,
		BLOODELF = true,
		ORC = true,
		TAUREN = true,
		TROLL = true,
		UNDEAD = true,
	};

CommonersQuest.DBMetaInfo.QuestFields.ContractPreQ = "table:optional";
CommonersQuest.DBMetaInfo.QuestFields.ContractPreQEntryType = { [1] = "number" };	-- MUST be a table!

CommonersQuest.DBMetaInfo.QuestFields.ID = "number";
CommonersQuest.DBMetaInfo.QuestFields.Title = "string";
CommonersQuest.DBMetaInfo.QuestFields.DescAcqIntro = "string";
CommonersQuest.DBMetaInfo.QuestFields.DescAcqSmall = "string";
CommonersQuest.DBMetaInfo.QuestFields.DescLogSmall = "string";
CommonersQuest.DBMetaInfo.QuestFields.DescDoneSmall = "string";

CommonersQuest.DBMetaInfo.QuestFields.Requirements = "table";
CommonersQuest.DBMetaInfo.QuestFields.RequirementsEntries = {};
CommonersQuest.DBMetaInfo.QuestFields.RequirementsEntries.Type = "selector";
CommonersQuest.DBMetaInfo.QuestFields.RequirementsEntries.TypeSelector = {
		["Emote"] = { Emote = "string", Friendly = "boolean", TargetName = "string", TargetDesc = "string", TargetType = "string", PlayerGUID = "string", MobID = "number", },
		["Kill"]  = { TargetName = "string", TargetDesc = "string", TargetType = "string", PlayerGUID = "string", MobID = "number", Count = "number" },
		["Survive"]  = { TargetName = "string", TargetDesc = "string", TargetType = "string", PlayerGUID = "string", MobID = "number", },
		["Loot"]  = { ItemID = "number", ItemName = "string", Count = "number" },
		["Duel"]  = { DuelResult = "string", DuelStreak = "boolean", DuelArea = "boolean", PlayerFaction = "string", PlayerDesc = "string", PlayerRace = "string", PlayerClass = "string", PlayerName = "string", PlayerGUID = "string", Count = "number" },
		["Riddle"] = { RiddleReference = "string", RiddleShortDesc = "string", RiddleSolution = "string", RiddleLockout = "number" },
	};
CommonersQuest.DBMetaInfo.QuestFields.RequirementsEntries.TypeOptional = {
		Friendly = true, TargetName = true, PlayerGUID = true, MobID = true, Count = true,
		-- duel stuff: X times class, Y times race, player Z in area ABC
		DuelStreak = true, DuelArea = true, PlayerDesc = true, PlayerRace = true, PlayerClass = true, PlayerName = true,
		-- only on quest giver side available
		RiddleSolution = true, RiddleLockout = true,
	};
CommonersQuest.DBMetaInfo.QuestFields.RequirementsEntries.TypeDescriptor = {
		Emote = "emote", Friendly = "target must be friendly",
		TargetName = "actual name of target", TargetDesc = "description of target in objective",
		TargetType = "NPC or player", PlayerGUID = "player ID", MobID = "mob ID",
		Count = "count",
		ItemID = "item ID", ItemName = "item name",
		DuelResult = "win/lose", DuelStreak = "must be a streak of wins/losses", DuelArea = "must be in a public place for duels",
		PlayerFaction = "faction (Alliance or Horde)", PlayerDesc = "description of player", PlayerRace = "race", PlayerClass = "class",
		PlayerName = "actual name", PlayerGUID = "player ID",
		RiddleReference = "very short reference in objective", RiddleShortDesc = "slightly less short reference in solve-dialog",
		RiddleSolution = "solution(s) to the riddle", RiddleLockout = "lockout duration (for guessing wrong)",
	};

CommonersQuest.DBMetaInfo.QuestFields.Reward = "table";
CommonersQuest.DBMetaInfo.QuestFields.RewardEntries = {};
CommonersQuest.DBMetaInfo.QuestFields.RewardEntries.Type = "selector";
CommonersQuest.DBMetaInfo.QuestFields.RewardEntries.TypeSelector = {
		["Money"] = { Amount = "number", },
		["Title"] = { Title = "string", },
		["Item"]  = { ItemID = "number", Choice = "boolean", ItemName = "string", Count = "number", Permanent = "boolean", },
	};

CommonersQuest.QuestDB = {
				[1] = {
					State = { Modified = 0, Enabled = false, Locked = true, },
					ContractPreReq = { Faction = "Alliance", Gender = 2 },
					ID = 1001,
					Title = "Single dwarf princess looking for...",
					DescAcqIntro = "The princess was like taken by some fire-breathing air-flying thingy with laaarge wings! OMG! What are we gonna do?\n\nI know: YOU go and save her!\n\nPersuade the assistant's scaled assistant of that winged creature to tell you where the princess is held captive. Save the princess kindly. And find a seal to create you a signet.",
					DescAcqSmall = "Try to wheedle out of the assistant's scaled assistant where the princess is being held. Free the princess in a gentleman-like fashion. And then you'll need a seal with slots to put about 3 gems onto it.",
					DescLogSmall = "I hope the princess survives until you get to her...",
					DescDoneSmall = "Well, that... uh. The king's not all that happy, unfortunately. Not surprisingly, true. Still...",
					Requirements = {
							[1] = { Type = "Survive",  TargetDesc = "The daughter of the king", TargetType = "NPC", MobID = 8929 },
							[2] = { Type = "Emote",  Emote = "flirt", Friendly = true, TargetDesc = "The daughter of the king", TargetType = "NPC", MobID = 8929 },
							[3] = { Type = "Kill", TargetDesc = "The assistant's scaled assistant", TargetType = "NPC", MobID = 8929 },
							[4] = { Type = "Loot", ItemName = "A seal with three slots to put gems in", ItemID = 12219 },
					},
					Reward = {
							[1] = { Type = "Money", Amount = 5000 },
							[2] = { Type = "Title", Title = "Prince of ..." },
					},
				},
				[2] = {
					State = { Modified = 0, Enabled = false, Locked = true, },
					ContractPreReq = { Faction = "Alliance" },
					ContractPreQ = { 1001 },
					ID = 1002,
					Title = "So, the princess's gone mad...",
					DescAcqIntro = "Well, the king wants to have a word with you. Afterwards we'll see if there's something we can do to fix this matter...",
					DescAcqSmall = "Tell the king a comforting story of what happened.",
					DescLogSmall = "The king is really taking this to his heart.",
					DescDoneSmall = "The king's kinda upset about this matter. We'll have to progress from a completely different angle, I guess...",
					Requirements = {
							[1] = { Type = "Emote",  Emote = "comfort", TargetDesc = "The king", TargetType = "NPC", MobID = 2784 },
					},
					Reward = {
							[1] = { Type = "Money", Amount = 5000 },
							[2] = { Type = "Item", ItemName = "A seal with three slots to put gems in", ItemID = 12219, Choice = false, Count = 1, Permanent = true },
					},
				},
				[3] = {
					State = { Modified = 0, Enabled = false, Locked = true, },
					ContractPreReq = { Faction = "Alliance" },
					ID = 1010,
					Title = "The Emperor's New Clothes",
					DescAcqIntro = "There are many leaders in the Alliance. Some deserve to be there. Some just inherited their position. Some started with the best of intent, but turned foul inside. And some are just mad and power-hungry.\nBut in an age without jesters, who is willing to tell the truth? Who has the guts to be a mirror of truth?\nMaybe... you?",
					DescAcqSmall = "Visit the leaders of the Alliance and show them the respect that they actually still deserve.",
					DescLogSmall = "Show the leaders of the Alliance, what they deserve!",
					DescDoneSmall = "Know thyself, said the Greek. Thanks to you, some of our leaders might've gotten the hint to look into who they really are. Not that any miracles are to be expected...",
					Requirements = {
							[1] = { Type = "Emote",  Emote = "awe", TargetDesc = "Jaina Proudmoore", TargetType = "NPC", MobID = 4968 },
							[2] = { Type = "Emote",  Emote = "kneel", TargetDesc = "Tyrande Whisperwind", TargetType = "NPC", MobID = 7999 },
							[3] = { Type = "Emote",  Emote = "dance", TargetDesc = "Leader of the Gnomes", TargetType = "NPC", MobID = 7937 },
							[4] = { Type = "Emote",  Emote = "cheer", TargetDesc = "The King of Dwarves", TargetType = "NPC", MobID = 2784 },
							[5] = { Type = "Emote",  Emote = "rude", TargetDesc = "Archdruid of Darnassus", TargetType = "NPC", MobID = 3516 },
							[6] = { Type = "Emote",  Emote = "snarl", TargetDesc = "King of Stormwind", TargetType = "NPC", MobID = 29611 },
					},
					Reward = {
							[1] = { Type = "Money", Amount = 100 },
					},
				},
				[4] = {
					State = { Modified = 0, Enabled = false, Locked = true, },
					ContractPreReq = { Faction = "Any" },
					ID = 1500,
					Title = "A bigger boat maybe...?",
					DescAcqIntro = "Hello stranger, maybe you can help me here...\nNext weekend I want to bring some stuff to the market. I found a customer for a half-tamed wolf, I promised a cousin a sheep and I need to sell some cabbage. On the way, I will need to cross a river, and besides me, the tiny boat just leaves space for one other item. Unfortunately, the wolf is not yet tamed enough to not consider the sheep a nice meal. And the sheep will tear through the cabbage if left alone with it.\nHow can I cross the river and not lose the wolf, the sheep nor the cabbage?",
					DescAcqSmall = "Find one way or another to transport the three items across the river with the boat.",
					DescLogSmall = "The weekend approaches soon... Can you help with a clever idea?",
					DescDoneSmall = "That's the way to go! Thanks a lot.",
					Requirements = {
						[1] = {
							Type = "Riddle",
							RiddleReference = "river crossing",
							RiddleShortDesc = "Enter a string of capitalized first characters of the items to transport. Use - to mark an empty crossing. (Example: \"W-\" would mean: bring the (w)olf across, come back (and find the (s)heep rummaging through the (c)abbage...)",
							RiddleSolution = "S-CSW-S || S-WSC-S",
						},
					},
					["Reward"] = {
					},
				},
			};

CommonersQuest.QuestPattern = {
		State = { Modified = 0, Enabled = false, Locked = false, },
		ContractPreReq = { Faction = "Any", },
		ID = 0,
		Title = "<Short descriptive title>",
		DescAcqIntro = "<Why you should do this quest for whomever, and what is necessary where to complete it>",
		DescAcqSmall = "<Short list of quest objectives (in running sentences)>",
		DescLogSmall = "<Progress sheet: Pretext for list of objectives>",
		DescDoneSmall = "<Text for quest completion goes here>",
		Requirements = {},
		Reward = {},
	};

