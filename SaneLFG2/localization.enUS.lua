
-- tables for comment scanning (comment is converted to lowercase before compare)

SaneLFG2Locales = {};

SaneLFG2Locales["enUS"] = {
	Heal = { "heal" },
	Tank = { "tank", "[^%w]mt[^%w]", "[^%w]ot[^%w]" },
	DPS = { "dps", "dd" },

	Messages = {
		-- neg. hits for #Trade
		Skills = {
			-- tradeskills
			" ench", " inscr", "smith", "engineer", "tailor", " jc", " jewel", " alchem",
			-- "books" of tradeskills
			"trade:%d+",
			-- tradeskill items
			"glyph", "recipe", "schema", "plan",
			-- trades
			"wtb[%s%:]", "wts[%s%:]", " ah ", " pay", " mats ", " buy", " sell",
			-- pvp: 2v2, 3v3, 5v5
			"%dv%d",
		},

		Guild = {
			[1] = {
				[1] = "guild",
				[2] = " recruit",
				[3] = " for info",
				[4] = " for more info",
			},
			[2] = {
				[1] = " in guild",
				[2] = "guild run",
			},
		},

		Cut = {
			[1] = "/w me for invites?!*",
			[1] = "/w me!*",
		},

		ReplaceA = {
			[1] = { a = "10 ?man", b = "10" },
			[2] = { a = "25 ?man", b = "25" },
			[3] = { a = "10m%.?[%s]", b = "10 " },
			[4] = { a = "25m%.?[%s]", b = "25 " },
			[5] = { a = "%s*10", b = "10" },
			[6] = { a = "%s*25", b = "25" },
			[7] = { a = "%s*20", b = "20" },
			[8] = { a = "%s*40", b = "40" },
		},
		ReplaceB = {
			-- kinda cheating here :D
			[1] = { a = " one ", b = " 1 " },
			[2] = { a = " a few ", b = " a_few " },
			[3] = { a = " a ", b = " 1 " },
			[4] = { a = " two ", b = " 2 " },
			[5] = { a = "([^%s])([%(%)%.%+%-,/!:&%^])", b = "%1 %2" },
			[6] = { a = "([%(%)%.%+%-,/!:&%^])([^%s])", b = "%1 %2" },
		},

		Main = {
			---------
			-- LFM --
			---------

			[1] = {
				s = "^ lf(%d+)m (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				iTotal = 1,
				sSub = 2,
			},
			[2] = {
				s = "^ lfm (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sSub = 1,
			},
			[3] = {
				s = " lf (.+) for (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sWho = 1,
				sWhat = 2,
			},
			[4] = {
				s = "need (.+) for (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sWho = 1,
				sWhat = 2,
			},
			[5] = {
				s = "(.+) needed for (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sWho = 1,
				sWhat = 2,
			},
			[6] = {
				s = "forming (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sSub = 1,
			},
			[7] = {
				s = "^ lf (.+)",
				bLFG = false,
				bLFM = true,
				sSub = 1,
			},
			[8] = {
				s = "^ looking for (.+)",
				bLFG = false,
				bLFM = true,
				sSub = 1,
			},
			[9] = {
				s = "(.*) last spot (.*)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sWhat = 1,
				sSub = 1,
			},

			---------
			-- LFG --
			---------

			[10] = {
				s = "(.+) lfg? (.+)",
				bLFG = true,
				bLFM = false,
				sWho = 1,
				sWhat = 2,
			},
			[11] = {
				s = "lfg? (.+) as (.+)",
				bLFG = true,
				bLFM = false,
				sWhat = 1,
				sWho = 2,
			},
			[12] = {
				s = "(.+) lfg $",
				bLFG = true,
				bLFM = false,
				bDefinite = true,
				sWho = 1,
			},
			[13] = {
				s = "lfg (.+)",
				bLFG = true,
				bLFM = false,
				bDefinite = true,
				sWhat = 1,
			},
		},
		MainPositional = {
			-- LFG/LFM with positional requirements on dungeons & dragons... eh, roles
			[1] = {
				s = "(.+) looking for (.+)",
				bLFG = true,
				bLFM = false,
				iNumArgs = 2,
				sArg1 = "Roles",
				sArg2 = "Dungeons",
			},
		},
		Roles = {
			[1] = {
				s = "(%d+)%s?tank.?",
				sRole = "Tank",
				bNum = true,
			},
			[2] = {
				s = "(tanks)",
				sRole = "Tank",
				bNum = false,
				bMany = true,
			},
			[3] = {
				s = "(tank[^s])",
				sRole = "Tank",
				bNum = false,
			},

			[4] = {
				s = "(%d+)%s?healers?",
				sRole = "Heal",
				bNum = true,
			},
			[5] = {
				s = "(%d+)%s?heals?",
				sRole = "Heal",
				bNum = true,
			},
			[6] = {
				s = "(healers)",
				sRole = "Heal",
				bNum = false,
				bMany = true,
			},
			[7] = {
				s = "(heals)",
				sRole = "Heal",
				bNum = false,
				bMany = true,
			},
			[8] = {
				s = "(healer[^s])",
				sRole = "Heal",
				bNum = false,
			},
			[9] = {
				s = "(heal[^es])",
				sRole = "Heal",
				bNum = false,
			},

			[10] = {
				s = "(%d+)%s?dps",
				sRole = "DPS",
				bNum = true,
			},
			[11] = {
				s = "(dps)",
				sRole = "DPS",
				bNum = false,
			},

			[12] = {
				s = "(%d+)%s?ranged?%s?dps",
				sRole = "DPS",
				sRoleSub = "Ranged",
				bNum = true,
			},
			[13] = {
				s = "ranged?%s?(dps)",
				sRole = "DPS",
				sRoleSub = "Ranged",
				bNum = false,
			},

			[14] = {
				s = "(%d+)%s?melee%s?dps",
				sRole = "DPS",
				sRoleSub = "Melee",
				bNum = true,
			},
			[15] = {
				s = "melee%s?(dps)",
				sRole = "DPS",
				sRoleSub = "Ranged",
				bNum = false,
			},

			[16] = {
				s = "(%d+)%s?random",
				sRole = "Any",
				bNum = true,
			},
			[17] = {
				s = "(random[^s])",
				sRole = "Any",
				bNum = false,
			},

			[18] = {
				s = "(a few dps)",
				sRole = "DPS",
				bNum = false,
				bMany = true,
			},
			[19] = {
				s = "(some dps)",
				sRole = "DPS",
				bNum = false,
				bMany = true,
			},
		},
		Places = {
			[1] = {
				s = " to (.+)$",
				sWhat = 1,
			},
			[2] = {
				s = " for (.+)$",
				sWhat = 1,
			},
		},
		Inter = {
			[1] = { s = " or ", l = 1 },
			[2] = { s = " / ", l = 1 },
			[3] = { s = " and ", l = 2 },
			[4] = { s = "&", l = 2 },
			[5] = { s = " + ", l = 2 },
			[6] = { s = " , ", l = 2 },
		},

		Dungeons = {
			-- "old world", no heroic version available
			[1] = {
				["dead ?mines"] = "DeadMines",
				["uldaman"] = "Uldaman",
				["dire ?maul"] = "DireMaul",
			},

			-- BC
			[2] = {
			},

			-- WotLK pre-3.2
			[3] = {
				[" violet"] = "VioletHold",

				["an"] = "AzjolNerub",
				["(azjol%s*[%-`´']*%s*)?nerub"] = "AzjolNerub",
				["ahn[%s%-`´']*kahet"] = "AhnKahet",
				["old%s*kingdom"] = "AhnKahet",

				["drak[%s%-`´']*tharon"] = "DrakTharon",
				["gun[%s%-`´']*drak"] = "Gundrak",

				-- raids
				["voa(%d+)"] = "VaultOfArchavon",
				["naxx?(%d+)"] = "Naxxramas",
			},

			-- WotLK post-3.2
			[4] = {
				-- specials
				["any normal"] = "AnyNormal",
				["any heroic"] = "AnyHeroic",
				["daily normal"] = "DailyNormal",
				["daily heroic"] = "DailyHeroic",

				-- dungeons
				["tot?c"] = "TrialOfTheChampion",

				-- raids
				["tot?c(%d+)"] = "TrialOfTheCrusader",

				["onyx?(%d+)"] = "Onyxia",
				["onyxia(%d+)"] = "Onyxia",
				["ulduar(%d+)"] = "Ulduar",

				-- 3.3
				["forge of souls"] = "ForgeOfSouls",
			},
		},

		-- unique short to long names table
		DungeonsShort = {
			-- "old world"
			[1] = {
				["DeadMines"] = "dm1",
				["Stockades"] = "stockades",
				["ScarletMonastery"] = "sm",
				["ZulFarrak"] = "zf",
				["Maraudon"] = "maraudon",
				["SunkenTemple"] = "st",
				["DireMaul"] = "dm2",
				["BlackRockDepths"] = "brd",
				["Scholomance"] = "scholo",

				["LowerBlackRockSpire"] = "lbrs",
				["UpperBlackRockSpire"] = "ubrs",

				["MoltenCore40"] = "mc",
				["BlackWingLair40"] = "bwl",

				["AhnQiraj20"] = "aq20",
				["AhnQiraj40"] = "aq40",
			},

			-- BC
			[2] = {
				["TempestKeep"] = "tk",
				["ZulAman10"] = "za",
			},

			-- WotLK pre-3.2
			[3] = {
				["UtgardeKeep"] = "uk",
				["Nexus"] = "nexus",
				["VioletHold"] = "vh",

				["AzjolNerub"] = "azjol",
				["AhnKahet"] = "ok",

				["DrakTharon"] = "dtk",
				["Gundrak"] = "gd",

				["HallsOfStone"] = "hos",
				["HallsOfLightning"] = "hol",
				["UtgardePinnacle"] = "up",
				["CoT4:Stratholme"] = "cos",

				-- raids
				["VaultOfArchavon10"] = "voa10",
				["VaultOfArchavon25"] = "voa25",
				["Naxxramas10"] = "naxx10",
				["Naxxramas25"] = "naxx25",
			},

			-- WotLK post-3.2
			[4] = {
				-- specials
				["AnyNormal"] = "any nhc",
				["AnyHeroic"] = "any hc",
				["AnyRaid"] = "any raid",

				-- goes away with 3.3:
				["DailyNormal"] = "daily nhc",
				["DailyHeroic"] = "daily hc",

				["TrialOfTheChampion"] = "totc",

				-- raids
				["TrialOfTheCrusader10"] = "toc10",
				["TrialOfTheCrusader25"] = "toc25",

				["Onyxia10"] = "ony10",
				["Onyxia25"] = "ony25",
				["Ulduar10"] = "ulduar10",
				["Ulduar25"] = "ulduar25",

				-- 3.3: new stuff
				["ForgeOfSouls"] = "fos",
				["PitOfSaron"] = "pos",
				["HallsOfReflection"] = "hor",
			},
		},
		DungeonAny = {
			"any instance",
			"any heroic",
			"any hc",
		},
		MustBeCase = {
			["st"] = true,
			["an"] = true,
			["ok"] = true,
			["gd"] = true,
			["up"] = true,
		},
		DungeonLockedOut = {
			"saved",
			"except",
			"but",
			"cleared",
		},

		Heroic = {
			"heroic",
			"hero",
			"hc",
		},

		Normal = {
			"normal",
			"nhc",
		},

		ExtraReq = {
			["link"] = "AC*",
			["achievement:(%d+)"] = "AC",
			["xp"] ="XP",
			["gear"] = "IL",
			["equip"] = "IL",
		},
	},

	UI = {
		BindingMainWndToggle = "Open/Close main SaneLFG2 window",
	},
};

SaneLFG2Locales.Current = SaneLFG2Locales["enUS"];

