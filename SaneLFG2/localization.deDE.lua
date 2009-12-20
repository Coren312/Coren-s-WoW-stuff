
SaneLFG2Locales["deDE"] = {
	Heal = { "heal", "heil" },
	Tank = { "tank", "[^%w]mt[^%w]", "[^%w]ot[^%w]" },
	DPS = { "dps", "dd" },

	Messages = {
		-- neg. hits for #Trade
		Skills = {
			-- tradeskills
			" ench", " inscr", "smith", "engineer", "tailor", " jc",
			-- "books" of tradeskills
			"trade:%d+",
			-- tradeskill items
			"glyph", "rezept", "schema", "plan",
			-- trades
			" ah ", " tg", " mats ", " biete",
			-- pvp: 2v2, 3v3, 5v5
			"%dvs?%d", "%don%d",
		},

		Guild = {
			[1] = {
				[1] = "gilde",
				[2] = " rekrut",
				[3] = " für info",
				[4] = " für mehr info",
				[4] = " fragen",
			},
			[2] = {
				[1] = " in der gilde",
				[2] = "gildenrun",
			},
		},

		Cut = {
			[1] = "/w me für invite",
			[1] = "/w me",
		},

		ReplaceA = {
			[1] = { a = "10er", b = "10" },
			[2] = { a = "25er", b = "25" },
			[3] = { a = "%s*10", b = "10" },
			[4] = { a = "%s*25", b = "25" },
			[5] = { a = "%s*20", b = "20" },
			[6] = { a = "%s*40", b = "40" },
			[7] = { a = "lvl%s*%d+", b = "" },
		},
		ReplaceB = {
			-- kinda cheating here :D
			[1] = { a = " einen ", b = " 1 " },
			[2] = { a = " eine ", b = " 1 " },
			[3] = { a = " ein ", b = " 1 " },
			[4] = { a = " zwei ", b = " 2 " },
			[5] = { a = "([^%s])([%(%)%.%+%-,/!:&%^])", b = "%1 %2" },
			[6] = { a = "([%(%)%.%+%-,/!:&%^])([^%s])", b = "%1 %2" },

			-- specials:
			[7] = { a = " fuer", b = " für" },
			[8] = { a = "für(%d+)", b = "für %1" },
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
				s = "lf (.+) für (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sWho = 1,
				sWhat = 2,
			},
			[4] = {
				s = "forming (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sSub = 1,
			},
			[5] = {
				s = "^ lf (.+)",
				bLFG = false,
				bLFM = true,
				sSub = 1,
			},

			[6] = {
				s = "noch (.+) für (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sWho = 1,
				sWhat = 2,
			},
			[7] = {
				s = "(.+) noch für (.+)",
				bLFG = false,
				bLFM = true,
				bDefinite = true,
				sWho = 1,
				sWhat = 2,
			},

			---------
			-- LFG --
			---------

			[8] = {
				s = "lfg? (.+) als (.+)",
				bLFG = true,
				bLFM = false,
				bDefinite = true,
				sWhat = 1,
				sWho = 2,
			},
			[9] = {
				s = "(.+) lfg$",
				bLFG = true,
				bLFM = false,
				sWho = 1,
			},
			[10] = {
				s = "(.+) lfg (.+)",
				bLFG = true,
				bLFM = false,
				sWho = 1,
				sWhat = 2,
			},
			[11] = {
				s = "lfg (.+)$",
				bLFG = true,
				bLFM = false,
				sWhat = 1,
			},

			[12] = {
				s = "(.+) such[et] gruppe für (.+)",
				bLFG = true,
				bLFM = false,
				bDefinite = true,
				sWho = 1,
				sWhat = 2,
			},
			[13] = {
				s = "(.+) such[et] grp für (.+)",
				bLFG = true,
				bLFM = false,
				bDefinite = true,
				sWho = 1,
				sWhat = 2,
			},
			[14] = {
				s = "such[et] gruppe für (.+)",
				bLFG = true,
				bLFM = false,
				bDefinite = true,
				sWho = 1,
				sWhat = 2,
			},
		},

		MainPositional = {
			-- LFG/LFM with positional requirements on dungeons & dragons... eh, roles
			[1] = {
				s = "^ such[etn]* (.+) für (.+)",
				bLFG = false,
				bLFM = true,
				iNumArgs = 2,
				sArg1 = "Roles",
				sArg2 = "Dungeons",
			},
			[2] = {
				s = "(.+) für (.+) gesucht",
				bLFG = false,
				bLFM = true,
				iNumArgs = 2,
				sArg1 = "Roles",
				sArg2 = "Dungeons",
			},
			[3] = {
				s = "(.+) gesucht für (.+)",
				bLFG = false,
				bLFM = true,
				iNumArgs = 2,
				sArg1 = "Roles",
				sArg2 = "Dungeons",
			},
			[4] = {
				s = "suchen? leute für (.+)",
				bLFG = false,
				bLFM = true,
				iNumArgs = 1,
				sArg1 = "Dungeons",
			},
			[5] = {
				s = "(.+) such[et]n? anschlu[^%s]+ an (.+)",
				bLFG = true,
				bLFM = false,
				iNumArgs = 2,
				sArg1 = "Roles",
				sArg2 = "Dungeons",
			},
			[6] = {
				s = "(.+) such[et]n? anschlu[^%s]+ für (.+)",
				bLFG = true,
				bLFM = false,
				iNumArgs = 2,
				sArg1 = "Roles",
				sArg2 = "Dungeons",
			},

			[7] = {
				s = "(.+) such[et]n? anschlu[^%s]+ oder leute für (.+)",
				bLFG = true,
				bLFM = true,
				iNumArgs = 2,
				sArg1 = "Roles",
				sArg2 = "Dungeons",
			},
		},

		Roles = {
			[1] = {
				s = "(%d+)%s?tank[`'´]?[`'´]?s?",
				sRole = "Tank",
				bNum = true,
			},
			[2] = {
				s = "(tank[`'´]?[`'´]?s)",
				sRole = "Tank",
				bNum = false,
				bMany = true,
			},
			[3] = {
				s = "(tank)",
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
				s = "(healer)",
				sRole = "Heal",
				bNum = false,
			},
			[8] = {
				s = "(heals)",
				sRole = "Heal",
				bNum = false,
				bMany = true,
			},
			[9] = {
				s = "(heal)",
				sRole = "Heal",
				bNum = false,
			},

			[10] = {
				s = "(%d+)%s?heil",
				sRole = "Heal",
				bNum = true,
			},
			[11] = {
				s = "(heiler)",
				sRole = "Heal",
				bNum = false,
			},

			[12] = {
				s = "(%d+)%s?dps",
				sRole = "DPS",
				bNum = true,
			},
			[13] = {
				s = "(dps)",
				sRole = "DPS",
				bNum = false,
			},

			[14] = {
				s = "(%d+)%s?dd[`'´]?[`'´]?s?",
				sRole = "DPS",
				bNum = true,
			},
			[15] = {
				s = "(dd[´]?[´]?s)",
				sRole = "DPS",
				bNum = false,
				bMany = true,
			},
			[16] = {
				s = "(dd)",
				sRole = "DPS",
				bNum = false,
			},
		},
		Places = {
			[1] = {
				s = " nach (.+)$",
				sWhat = 1,
			},
			[2] = {
				s = " für (.+)$",
				sWhat = 1,
			},
		},
		Inter = {
			[1] = { s = "oder", l = 1 },
			[2] = { s = "/", l = 1 },
			[3] = { s = "und", l = 2 },
			[4] = { s = "&", l = 2 },
			[5] = { s = "+", l = 2 },
			[6] = { s = ",", l = 2 },
		},

		Dungeons = {
			-- "old world", no heroic version available
			[1] = {
				["todesminen"] = "DeadMines",
				["uldaman"] = "Uldaman",
				["zul[`'´]?[`'´]?farrak"] = "ZulFarrak",
				["düsterbruch"] = "DireMaul",
				["brt"] = "BlackRockDepths",			-- from the era of mixed translations (Blackrock Tiefen)
			},

			-- BC
			[2] = {
				["hdz1"] = "CoT1:EscapeOfThrall",
				["hdz2"] = "CoT2:DarkPortal",
				["hdz4"] = "CoT4:Stratholme",
			},

			-- WotLK pre-3.2
			[3] = {
				-- dungeons
				["burg"] = "UtgardeKeep",
				["vio[^%s]*"] = "VioletHold",

				["drak[%s%-`´']*tharon"] = "DrakTharon",
				["gun[%s%-`´']*drak"] = "GunDrak",

				["(azjol%s*[%-`´']*%s*)?nerub"] = "AzjolNerub",
				["ahn(%s*[%-`´']*%s*)?kahet"] = "AhnKahet",
				["altes Königreich"] = "AhnKahet",

				["turm"] = "UtgardePinnacle",

				-- raids
				["ak(%d+)"] = "VaultOfArchavon",
				["naxx?(%d+)"] = "Naxxramas",
			},

			-- WotLK post-3.2
			[4] = {
				-- mutilations of daily stupid Germans utter
				["da[iy]l[iy]e?"] = "daily",
				["da[iy]l[iy]e? hero"] = "daily hero",
				["hero da[iy]l[iy]e?"] = "daily hero",

				-- dungeons
				["pdc"] = "TrialOfTheChampion",
				["pdk(%d+)"] = "TrialOfTheCrusader",

				-- raids
				["ony(%d+)"] = "Onyxia",
				["onyxia(%d+)"] = "Onyxia",

				["uldua?r?(%d+)"] = "Ulduar",

				-- 3.3
				-- ["forge of souls"] = "ForgeOfSouls",
			},
		},

		-- unique short to long names table
		DungeonsShort = {
			-- "old world"
			[1] = {
				["DeadMines"] = "dm1",
				["ScarletMonastery"] = "kloster",
				["ZulFarrak"] = "zf",
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
				["ZulAman10"] = "za",
			},

			-- WotLK pre-3.2
			[3] = {
				["UtgardeKeep"] = "bu",
				["Nexus"] = "nexus",
				["VioletHold"] = "vf",

				["AzjolNerub"] = "azjol",
				["AhnKahet"] = "kahet",				-- *ǹot* AK: AK is VoA in German

				["DrakTharon"] = "dt",
				["GunDrak"] = "gundrak",

				["HallsOfStone"] = "hds",
				["HallsOfLightning"] = "hdb",
				["UtgardePinnacle"] = "tu",
				["CoT4:Stratholme"] = "cos",

				["VaultOfArchavon10"] = "ak10",
				["VaultOfArchavon25"] = "ak25",
				["Naxxramas10"] = "naxx10",
				["Naxxramas25"] = "naxx25",
			},

			-- WotLK post-3.2
			[4] = {
				-- specials

				-- goes away with 3.3:
				["daily hero"] = "daily hc",
				["daily normal"] = "daily nhc",

				-- dungeons
				["TrialOfTheChampion"] = "totc",

				-- raids
				["TrialOfTheCrusader10"] = "toc10",
				["TrialOfTheCrusader25"] = "toc25",

				["Onyxia10"] = "ony10",
				["Onyxia25"] = "ony25",

				["Ulduar10"] = "ulduar10",
				["Ulduar25"] = "ulduar25",

				-- 3.3+
			--	["ForgeOfSouls"] = "fos",
			--	["PitOfSaron"] = "pos",
			--	["HallsOfReflection"] = "hor",
			},
		},
		DungeonAny = {
			"hero ini",
			"irgen[dt]%s*eine ini",
		},
		MustBeCase = {
		},
		DungeonLockedOut = {
			"saved",
			"au[sß][sß]er",
		},

		Heroic = {
			"heroisch",
			"heroic",
			"hero",
			"hc",
		},

		Normal = {
			"normal",
			"nhc",
			"nh",							-- questionable...
		},

		ExtraReq = {
			["link"] = "AC*",
			["achievement:(%d+)"] = "AC",
			["xp"] ="XP",
			["gear"] = "IL",
			["equip"] = "IL",
			["ausrüstung"] = "IL",
		},
	},

	UI = {
		BindingMainWndToggle = "Öffnen/Schließen SaneLFG2 Hauptfenster",
	},
};

