--[[
	Karma
	by Aveasau

	Karma Resurrection
	by Endareth

	Karma Keeping-Alive
	by Kärbär

	See readme.txt for notes
]]--

----------------------------------------------
-- GLOBALS
----------------------------------------------

KARMA_ININIT = 0;
KARMA_LOADED = 0;

KarmaConfig = {};
local	KarmaConfigLocal = nil;

-- cross-module access
local	KarmaObj = KarmaAvEnK;
local	KOH = KarmaObj.Helpers;

-- various Elements shall get their own arrays here:
KarmaObj.UI.NotesPublic = {};
KarmaObj.UI.Config = {};

KARMA_MAINWND_KEEPOPEN = false;
KARMA_MAINWND_REINSERT = false;

-- for all functions local to this module
local	KarmaModuleLocal =
		{
			-- Version check related
			Version =
				{
					Seen =
						{
							PARTY = {
								Newer = 0,
								Same  = 0,
								Older = 0
								},
							GUILD = {
								Newer = 0,
								Same  = 0,
								Older = 0
								},
							RAID = {
								Newer = 0,
								Same  = 0,
								Older = 0
								}
						}
				},

			-- stuff regarding the command queue
			Command = {},
			Timers = {
					CmdQ = 0,
					CronQ = 0,
					Update = 0,
				},

			-- information containers
			Raid =
				{
					-- current raid
					MemberCnt = 0,
					Name2Index = {},

					-- previous raids
					iIndexHistory = 1,
					HistoryTables =
						{
						}
				},

			-- information containers
			NotesPublic =
				{
					Results = {}
				},

			-- channel information: Blizzard channel, other
			Channels = {},

			-- new chat system
			ChatFilters = {},

			-- Dummy inits
			TalentSpecCount = nil,
			PatternZoneExplored = nil,

			-- UI parts & pieces
			UIConfig = {},
			ColorSpaces = {
				Default1 = {
					Min = { r = 1.0, g = 0.0, b = 0.0 },
					Avg = { r = 0.5, g = 0.5, b = 1.0 },
					Max = { r = 0.0, g = 1.0, b = 0.0 },
				},

				Default2 = {
					Min = { r = 0.7, g = 0.7, b = 0.7 },
					Avg = { r = 0.5, g = 0.5, b = 1.0 },
					Max = { r = 0.3, g = 1.0, b = 0.3 },
				},
			},
			FieldHighLow = {
			},

			-- tooltip: only add Karma info once per target+mouseover
			GameTooltipUnit = nil,

			-- required for partial Achievement tracking
			PlayerRegenEnabledOrMobDied = nil,

			-- only once - flags
			WhoInfoOnlyOnce_Char = nil,
			WarnTrackingOnce = nil,
			KarmaWindow2_ShowInital = 0;
			KarmaWindow2_CreatedButtons = 0;

			-- LFM window: populate menu choices
			LFM_Populate_Channel = nil,
			LFM_Populate_Class = nil,

			-- char select menu: must delay selected until after init
			CharSelection_Index = nil,

			-- mouseover Unit storage
			MouseOverKeepCount = 25,
			MouseOverKeepIndex = 0,
			MouseOverKeepList = {},

			-- chatter history storage
			ChatRememberCount = 10,
			ChatRememberIndex = 0,
			ChatRememberList = {},

			-- Who queue
			ExecutingWhoSince = nil,
			ExecutingWhoBroken = false,

			-- check for terrorist player pending
			AchievementCheckTerrorTimer = 0,
			AchievementCheckTerrorCount = 0,
			AchievementCheckTerrorList = {},

			-- meta-entry for guildless people
			Guildless = "> no guild <",

			-- debugging: region colorization changes
			RegionChangePrevious = "Undefined",

			-- debugging: checking load order
			AddonLoaded = {},
		};

-- BINDING Names
BINDING_HEADER_KARMA = KARMA_BINDING_HEADER_TITLE;
BINDING_NAME_KARMAWINDOW = KARMA_BINDING_WINDOW_TITLE;
BINDING_NAME_KARMAWINDOW2 = KARMA_BINDING_WINDOW2_TITLE;

----------------------------------------------
-- CONSTS
----------------------------------------------

-- COMMON/REGIONNAMES LEVEL FIELDS: DB_L3_CR
local	KARMA_DB_L3_CR = {
			ZONEIDS = "ZONEIDS",
			ISPVPZONE = "PVPZONE",
			ZONETYPE = "ZONETYPE"
		};

-- COMMON/FACTION LEVEL FIELDS: DB_L3_CF
local		KARMA_DB_L3_CF_QUESTNAMES = "QUESTNAMES";
local		KARMA_DB_L3_CF_QUESTINFOS = "QUESTINFOS";

-- REALM LEVEL FIELDS: DB_L3_RR
local		KARMA_DB_L3_RR_FACTION = "FACTIONLIST";

-- REALM/FACTION/<FACTION> LEVEL FIELDS: DB_L4_RRFF
local	KARMA_DB_L4_RRFF = {
			CHARACTERLIST = "CHARACTERLIST",
			MEMBERLIST = "MEMBERLIST",				-- no longer used since version 4 of the database
			MEMBERBUCKETS = "MEMBERBUCKETS",
			ALTGROUPS = "ALTGROUPS",
			QUESTNAMES = "QUESTNAMES",
			ZONENAMES = "ZONENAMES",
			XFACTIONHOLD = "XFACTIONHOLD",
			IGNORE24 = "IGNTMP",
		};

-- REALM/FACTION/<FACTION>/CHARACTERLIST OBJECT FIELDS: DB_L5_RRFFC
local	KARMA_DB_L5_RRFFC = {
			NAME = "NAME";
			XPTOTAL = "XPTOTAL";
			XPLAST = "XPLAST";
			XPMAX = "XPMAX";
			PLAYED = "PLAYED";
			PLAYEDPVP = "PLAYEDPVP";
			PLAYEDLAST = "PLAYEDLAST";
			CONFIGPERCHAR = "CHARCONFIG";
			XPLVLSUM = "XPLVLSUM";
		};

-- Waawaa, "local" limit: 200
-- TODO: more KARMA_DB_??_*_* -> KARMA_DB_??_*.*

-- REALM/FACTION/<FACTION>/MEMBERLIST OBJECT FIELDS: DB_L5_RRFFM
local	KARMA_DB_L5_RRFFM = {
			LASTCHANGED_TIME = "TOUCH_TIME",
			LASTCHANGED_FIELD = "TOUCH_FIELD",

			GUID = "GUID",
			NAME = "NAME",
			ALTGROUP = "ALTID",
			GUILD = "GUILD",
			LEVEL = "LEVEL",
			GENDER = "GENDER",
			RACE = "RACE",
			CLASS = "CLASS",
			CLASS_ID = "CLSID",

			RACE_EN = "RACEEN",
			CLASS_EN = "CLASSEN",
		};

-- #### --

local		KARMA_DB_L5_RRFFM_CONFLICT = "CONFLICT";

local		KARMA_DB_L5_RRFFM_TALENT = "TALENT";
local		KARMA_DB_L5_RRFFM_TALENTTREE = "TALENTTREE";
local		KARMA_DB_L5_RRFFM_KARMA = "KARMA";
local		KARMA_DB_L5_RRFFM_PUBLIC_NOTES = "PUBLIC_NOTES";
local		KARMA_DB_L5_RRFFM_NOTES = "NOTES";
local		KARMA_DB_L5_RRFFM_PUBLIC_NOTES_TIME = "PUBNOTES_TIME";
local		KARMA_DB_L5_RRFFM_NOTES_TIME = "NOTES_TIME";
local		KARMA_DB_L5_RRFFM_PUBLIC_NOTES_HISTORY = "PUBNOTES_HIST";
-- stores imported total sum
local		KARMA_DB_L5_RRFFM_KARMA_IMPORTED = "K_IMP";
-- modifier for "time"-Karma: -1 = use default, 0 = off, 1 = on
local		KARMA_DB_L5_RRFFM_KARMA_TIME = "K_TIME";
-- old concept... dropped.
-- it's impossible to add "-3 underperforming" to "+3 nice" and get a sensible result...
-- must remain a while to clean out intermediate versions
local		KARMA_DB_L5_RRFFM_KARMA_MODSOC = "K_SOC";
local		KARMA_DB_L5_RRFFM_KARMA_MODSKILL = "K_SKILL";
-- TODO: three new values to filter on...
local		KARMA_DB_L5_RRFFM_SKILL = "SKILL";
local		KARMA_DB_L5_RRFFM_GEAR_PVP = "GEAR_PVP";
local		KARMA_DB_L5_RRFFM_GEAR_PVE = "GEAR_PVE";

local		KARMA_DB_L5_RRFFM_TIMESTAMP = "TIMESTAMP";
local		KARMA_DB_L5_RRFFM_TIMESTAMP_TRY = "TRY";
local		KARMA_DB_L5_RRFFM_TIMESTAMP_SUCCESS = "SUCCESS";
local		KARMA_DB_L5_RRFFM_JOINEDLAST_TIME = "JOINEDLAST";
local		KARMA_DB_L5_RRFFM_JOINEDLAST_CHAR = "JOINEDWITH";

local		KARMA_DB_L5_RRFFM_KARMA_TRUST = "K_TRUST";
local		KARMA_DB_L5_RRFFM_SHARE_TRUST = "SHARE_TRUST";

local		KARMA_DB_L5_RRFFM_TERROR = "TERROR";

-- REALM/FACTION/<FACTION>/MEMBERLIST/<Bucket>/<Member>/CHARACTERS/<Character> OBJECT FIELDS: DB_L6_RRFFMCC
-- character specific data
-- container
local		KARMA_DB_L5_RRFFM_CHARACTERS = "CHARACTERSPECIFIC";
-- data
local		KARMA_DB_L6_RRFFMCC_QUESTIDLIST = "QUESTIDLIST";
local		KARMA_DB_L6_RRFFMCC_QUESTEXLIST = "QUESTEXLIST";
local		KARMA_DB_L6_RRFFMCC_ZONEIDLIST = "ZONEIDLIST";
local		KARMA_DB_L6_RRFFMCC_XP = "XP";
local		KARMA_DB_L6_RRFFMCC_XPLAST = "XPLAST";
local		KARMA_DB_L6_RRFFMCC_XPMAX = "XPMAX";
local		KARMA_DB_L6_RRFFMCC_XPLVL = "XPLVL";
local		KARMA_DB_L6_RRFFMCC_PLAYED = "PLAYED";
local		KARMA_DB_L6_RRFFMCC_PLAYEDPVP = "PLAYEDPVP";
local		KARMA_DB_L6_RRFFMCC_PLAYEDLAST = "PLAYEDLAST";
local		KARMA_DB_L6_RRFFMCC_JOINEDLAST = "JOINEDLAST";
local		KARMA_DB_L6_RRFFMCC_ACHIEVED = "ACHIEVED";
-- ../CHARACTERS/<Character>/REGIONLIST OBJECT FIELDS: DB_L7_RRFFMCCR
-- region tracking: which when how long...
-- container
local		KARMA_DB_L6_RRFFMCC_REGIONLIST = "REG_L";			-- list of
-- data
-- KARMA_DB_L7_RRFFMCCRR_ -> KARMA_DB_L7_RRFFMCCRR_
local		KARMA_DB_L7_RRFFMCCRR_KEY = "RL_REGKEY";				-- an ID (RegionID + Difficulty!)
local		KARMA_DB_L7_RRFFMCCRR_ID = "RL_REGID";					-- a RegionID
local		KARMA_DB_L7_RRFFMCCRR_DIFF = "RL_REGDIFF";				-- a difficulty
local		KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL = "REG_TOTAL";		-- summed time
-- another container
local		KARMA_DB_L7_RRFFMCCRR_PLAYEDDAYS = "REG_DAYS";			-- list of
-- and another dataset
local		KARMA_DB_L8_RRFFMCCRRD_KEY = "REG_DAYKEY";					-- an ID
local		KARMA_DB_L8_RRFFMCCRRD_START = "RD_FROM";					-- start (datetime)
local		KARMA_DB_L8_RRFFMCCRRD_END = "RD_TILL";						-- end (datetime)

-- REALM/FACTION/<FACTION>/XFACTIONHOLD OBJECT FIELDS: additional field besides DB_L5_RRFFM
local		KARMA_DB_L5_RRFFX_SOURCE = "SOURCE";
local		KARMA_DB_L5_RRFFX_FACTION = "FACTION";

local		KARMA_ALPHACHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";


-- CONFIG FIELDS (all local)
local	KARMA_CONFIG = {
			-- Options: "Sort/Color"
			SORTFUNCTION = "SORTFUNCTION",
			SORTFUNCTION_TYPE_KARMA = "KARMASORT",
			SORTFUNCTION_TYPE_NAME = "NAMESORT",
			SORTFUNCTION_TYPE_XP	= "XPSORT",
			SORTFUNCTION_TYPE_PLAYED = "PLAYEDSORT",
			SORTFUNCTION_TYPE_CLASS = "CLASSSORT",
			SORTFUNCTION_TYPE_JOINED = "JOINEDSORT",
			SORTFUNCTION_TYPE_TALENT = "TALENTSORT",
			SORTFUNCTION_TYPE_XPALL	= "XPALLSORT",
			SORTFUNCTION_TYPE_PLAYEDALL = "PLAYEDALLSORT",
			SORTFUNCTION_TYPE_GUILD_TOP = "BYGUILD_TOP",
			SORTFUNCTION_TYPE_GUILD_BOTTOM = "BYGUILD_BTM",

			COLORFUNCTION = "COLORFUNCTION",
			COLORFUNCTION_TYPE_XP	= "XPCOLOR",
			COLORFUNCTION_TYPE_PLAYED = "PLAYEDCOLOR",
			COLORFUNCTION_TYPE_KARMA = "KARMACOLOR",
			COLORFUNCTION_TYPE_CLASS = "CLASSCOLOR",
			COLORFUNCTION_TYPE_XPALL = "XPALLCOLOR",
			COLORFUNCTION_TYPE_PLAYEDALL = "PLAYEDALLCOLOR",
			COLORFUNCTION_TYPE_XPLVL = "XPLVLCOLOR";
			COLORFUNCTION_TYPE_XPLVLALL = "XPLVLALLCOLOR";

			COLORSPACE_ENABLE = "COLORSPACE_ENABLE",
			COLORSPACE_KARMA = "COLORSPACE_KARMA",
			COLORSPACE_TIME = "COLORSPACE_TIME",
			COLORSPACE_XP = "COLORSPACE_XP",

			-- Options: "Tooltip"
			TOOLTIP_SHIFTREQ = "TT_SHREQ",
			TOOLTIP_KARMA = "TT_KARMA",
			TOOLTIP_PLAYEDTOTAL = "TT_PLAYEDTOTAL",
			TOOLTIP_PLAYEDTHIS = "TT_PLAYEDTHIS",
			TOOLTIP_NOTES = "TT_NOTES",
			TOOLTIP_SKILL = "TT_SKILL",
			TOOLTIP_TALENTS = "TT_TALENTS",
			TOOLTIP_ALTS = "TT_ALTS",
			TOOLTIP_HELP = "TT_HELP",
			TOOLTIP_LFMADDKARMA = "TT_LFMADDKARMA",

			-- Options: "auto.Ign/Warn"
			AUTOIGNORE_THRESHOLD = "AUTOIGNORE_THRESHOLD",
			AUTOIGNORE = "AUTOIGNORE",
			AUTOIGNORE_INVITES = "AUTOIGNORE_INVITES",
			JOINWARN_THRESHOLD = "JOINWARN_THRESHOLD",
			JOINWARN_ENABLED = "JOINWARN_ENABLED",

			-- Options: "Chat windows"
			CHAT_DEFAULT = "CHAT_DEFAULT",
			CHAT_SECONDARY = "CHAT_SECONDARY",
			CHAT_DEBUG = "CHAT_DEBUG",

			MARKUP_ENABLED = "MARKUP",
			MARKUP_VERSION = "MARKUP_VERSION",
			MARKUP_COLOUR_NAME = "COLOUR_NAME",				-- missing in UI
			MARKUP_COLOUR_KARMA = "COLOUR_KARMA",				-- missing in UI
			MARKUP_SHOW_KARMA = "SHOW_KARMA",				-- missing in UI
			MARKUP_WHISPERS = "MARKUP_WHISPERS",
			MARKUP_CHANNELS = "MARKUP_CHANNELS",
			MARKUP_GUILD = "MARKUP_GUILD",
			MARKUP_RAID = "MARKUP_RAID",
			MARKUP_BG = "MARKUP_BG",
			MARKUP_YELLSAYEMOTE = "MARKUP_YSE",

			-- Options: "virtual Karma"
			TIME_KARMA_DEFAULT = "K_TIME_DEFAULT",
			TIME_KARMA_MINVAL = "K_TIME_MINVAL",
			TIME_KARMA_FACTOR = "K_TIME_FACTOR",
			TIME_KARMA_SKIPBGTIME = "K_TIME_NOTBG",

			-- Options: "Other"
			TARGET_COLORED = "TARGET_COLORED",
			QUESTWARNCOLLAPSED = "QUESTWARN",
			MAINWND_INITIALTAB = "MAINWND_INITTAB",
			TALENTS_AUTOFETCH = "TALENTS_AUTOFETCH",
			MINIMAP_HIDE = "MINIMAP_HIDE",
			QUESTSIGNOREDAILIES = "Q_IGN_DAILY",
			UPDATEWHILEAFK = "UPD_ON_AFK",
			DB_SPARSE = "SPARSEDB",

			-- Options: "DB cleaning"
			CLEAN_AUTO = "AUTOCLEAN",
			CLEAN_AUTOPVP = "AUTOCLEANPVP",
			CLEAN_KEEPIFNOTE = "CLEAN_KEEPIFNOTE",
			CLEAN_REMOVEPVPJOINS = "CLEAN_REM_PVP",
			CLEAN_REMOVEXSERVER = "CLEAN_REMOVEXSERVER",
			CLEAN_KEEPIFKARMA = "CLEAN_KEEPIFKARMA",
			CLEAN_KEEPIFREGIONCOUNT = "CLEAN_KEEPIFREGIONCOUNT",
			CLEAN_KEEPIFZONECOUNT = "CLEAN_KEEPIFZONECOUNT",
			CLEAN_KEEPIFQUESTCOUNT = "CLEAN_KEEPIFQUESTCOUNT",
			CLEAN_IGNOREPVPZONES = "CLEAN_IGNOREPVPZONES",

			-- Options: "Sharing"
			SHARE_ONREQ_KARMA = "SHARE_ONREQ_KARMA",
			SHARE_ONREQ_PUBLICNOTE = "SHARE_ONREQ_PUBNOTE",
			SHARE_CHANNEL_NAME = "SHARE_CHAN_NAME",
			SHARE_CHANNEL_AUTO = "SHARE_CHAN_AUTO",

			-- Options: "Tracking" (UI part TODO)
			RAID_TRACKALL = "RAID_TRACKALL",
			RAID_NOGROUP  = "RAID_NOGROUP",
			TRACK_DISABLEACHIEVEMENT = "TRACK_NOACHIEVEMENT",
			TRACK_DISABLEQUEST = "TRACK_NOQUEST",
			TRACK_DISABLEREGION = "TRACK_NOREGION",
			TRACK_DISABLEZONE = "TRACK_NOZONE",
			TRACK_DISABLEPVPAREAS = "TRACK_NOPVPAREA",

			MENU_DEACTIVATE = "MENU_OFF",
			MENU_WARN = "MENU_WARN",

			-- internal
			DEBUG_ENABLED = "DEBUG",

			-- == last entry no ",", add to previous == --
			BETA = "BETA"
		};

-- not in Option window:
local		KARMA_CONFIG_MINIMAPPOS = "MINIMAP_ANGLE";
local		KARMA_CONFIG_SKILL_MODEL = "SKILL_MODEL";
local		KARMA_CONFIG_MAINWND_LISTPREFIX = "MWND_L_";

local		KARMA_ALPHACHARS_ACCENT =
	{
		["A"] = {[1] = 192, [2] = 193, [4] = 194, [5] = 195, [6] = 196, [7] = 197, [8] = 198},
		["C"] = {[1] = 199},
		["D"] = {[1] = 208},
		["E"] = {[1] = 200, [2] = 201, [3] = 202, [4] = 203},
		["I"] = {[1] = 204, [2] = 205, [3] = 206, [4] = 207},
		["N"] = {[1] = 209},
		["O"] = {[1] = 210, [2] = 211, [3] = 212, [4] = 213, [5] = 214, [6] = 215, [7] = 216},
		["U"] = {[1] = 217, [2] = 218, [3] = 219, [4] = 220},
		["Y"] = {[1] = 221}
	};

-- these tables just cover "Basic-Latin" (U-0000) and "Latin-1" (U-0080)
-- from the UNICODE charts
local		KARMA_ALPHACHARS_UTF8_REVERSE =
	{
	-- all but ½ start with 195, ½ with 197
		[195] = {
				["A"] = { 128, 129, 130, 131, 132, 133, 134 },
				["B"] = { 159 },	-- !! ß -> b
				["C"] = { 135 },
				["D"] = { 144 },
				["E"] = { 136, 137, 138, 139 },
				["I"] = { 140, 141, 142, 143 },
				["N"] = { 145 },	-- ñ -> n
				["O"] = { 146, 147, 148, 149, 150, 152 },
				["U"] = { 153, 154, 155, 156 },
				-- ["Y"] = { ??? }
			},

		[197] = {
					["O"] = { 115 },
			},
	};

local		KARMA_ALPHACHARS_UTF8_FORWARD =
	{
	-- all but ½ start with 195, ½ with 197
		[195] = {
					[128] = "A", [129] = "A", [130] = "A", [131] = "A", [132] = "A", [133] = "A", [134] = "A",
					[159] = "B",	-- !! ß -> b
					[135] = "C",
					[144] = "D",
					[136] = "E", [137] = "E", [138] = "E", [139] = "E",
					[140] = "I", [141] = "I", [142] = "I", [143] = "I",
					[145] = "N",	-- ñ -> n
					[146] = "O", [147] = "O", [148] = "O", [149] = "O", [150] = "O", [152] = "O",
					[153] = "U", [154] = "U", [155] = "U", [156] = "U",
			},

		[197] = {
					[115] = "O",
			},
	};

-- Bitfield
-- 1-2-4     : HPS (1), TANK (2), DPS (4), Feral(6)
-- 8-16      : MELEE(8), RANGED(16)
local	KARMA_TALENTS_MAXBITPLUS1 = 5;

local	KARMA_TALENTS =
	{
		[0] = { key = "KARMA_MISSING_INFO", color = "|cFF9F9F9F" },
		[1] = { key = "KARMA_TALENT_HPS", color = "|cFF00FF00" },		-- spec: Dru/Pal/Shm/Pri
		[2] = { key = "KARMA_TALENT_TANK", color = "|cFFFFFFFF" },		-- spec: Dru/Pal/War tanks
		[4] = { key = "KARMA_TALENT_DPS", color = "|cFFFF0000" },		-- spec: all classes
		[6] = { key = "KARMA_TALENT_FERAL", color = "|cFFFF8080" },		-- spec: Feral
		[8] = { key = "KARMA_TALENT_MELEE", color = "|cFFFFA0A0" },		-- spec: Moonkin/Feral, ShamanMelee/Ranged
		[16] = { key = "KARMA_TALENT_RANGED", color = "|cFF8080FF" }		-- spec: Moonkin/Feral, ShamanMelee/Ranged
	};

local KARMA_TALENT_CLASSMASK =
	{
		 [1] = 31,	-- druid: HPS/R, FERAL/M, DPS/R
		 [2] = 20,	-- hunter: DPS/R
		 [3] = 20,	-- mage: DPS/R
		 [4] = 31,	-- paladin: HPS/R, TANK/M, DPS/M
		 [5] = 21,	-- priest: HPS/R, DPS/R
		 [6] = 12,	-- rogue: DPS/M
		 [7] = 29,	-- shaman: HPS/R, DPS/M, DPS/R
		 [8] = 14,	-- warrior: TANK/M, DPS/M
		 [9] = 20,	-- warlock: DPS/R
		[10] = 14,	-- deathknight: TANK/M, DPS/M
	};

--------------------------------------------------
-- FOLLOWING IS PART OF THE CLASS, NOT TALENTED --
--------------------------------------------------

-- (no need to store at each member, derive from class)
-- Bitfield
-- 1-2-4 : CC: CC.(1), CC1(2), CC2(4)
local	KARMA_ABILITIES_CC_COLOR = "|cFFA0A0F0";
local	KARMA_ABILITIES_CC =
	{
		[0] = "KARMA_MISSING_INFO",
		[1] = "KARMA_TALENT_CC_CC0",
		[2] = "KARMA_TALENT_CC_CC1",
		[4] = "KARMA_TALENT_CC_CC2"
	};

-- Bitfield
-- 1-    : CC: H(uman 1), U(ndead 2), E(lement 4), B(east 8), D(raconian 16)
local	KARMA_TARGETS_CC =
	{
		[0] = "KARMA_MISSING_INFO",
		[1] = "KARMA_MONSTER_HUMAN",
		[2] = "KARMA_MONSTER_UNDEAD",
		[4] = "KARMA_MONSTER_ELEMENT",
		[8] = "KARMA_MONSTER_BEAST",
		[16] = "KARMA_MONSTER_DRAKE"
	};

-- Bitfield
-- 1-2   : AE: M1(128), AE(256)
local	KARMA_ABILITIES_AE =
	{
		[0] = "KARMA_MISSING_INFO",
		[1] = "KARMA_TALENT_AE_M1",
		[2] = "KARMA_TALENT_AE_AE"
	};

local	KARMA_SKILL_LEVELS = nil;

----------------------------------------------
--	Local variables
----------------------------------------------

local	KSLASH = {};
local	KARMA_CURRENTLIST = 1;
local	KARMA_CURRENTMEMBER = nil;
local	KARMA_CURRENTCHAR = nil;
local	KARMA_MEMBERLIST_SIZE = 25;
local	KARMA_MAINLISTS_SIZE = 15;
local	KARMA_ALTLIST_SIZE = 5;
local	KARMA_LFGWND_LIST1_SIZE = 34;
local	KARMA_LFGWND_LIST2_SIZE = 25;

local	KARMA_SELECTEDTAB = nil;

local	KARMA_VERSION_TEXT = nil;
local	KARMA_VERSION_DATE = nil;

local	KARMA_VERSION_TEXT_NEWEST = nil;
local	KARMA_VERSION_DATE_NEWEST = nil;

local	KARMA_EXCHANGE = {
			ENABLED_WITH = nil,

			START_WITH = nil,
			START_FRAG = nil,
			START_AT = nil,

			REQ_IS = nil,
			REQ_AT = nil,

			ACK_IS = nil,
			ACK_AT = nil,

			FIRST = nil,
			COUNT = nil,
			DONE = nil
		};

-- DEBUG
local	KARMA_ALWAYS_WATCH_EVENTS = false;
local	KARMA_SHOW_FORBIDDEN_IN_MAIN = false;

-- testing (quicker) online check...
local	KARMA_OnlineCheckAddedFriend = nil;

-- extended Questlog usage
local	KARMA_QEx_NumPartyMembers = 0;
local	KARMA_QExInitDone = 0;
local	KARMA_QExCreate = 50;
local	KARMA_QExCreateLog = 0;
local	KARMA_QExUpdate = 50;
local	KARMA_QExDisplay = 1;
local	KARMA_QExsWarnComp = "";
local	KARMA_QZone = 1;

local	KARMA_NamesSortedAlpha = nil;
local	KARMA_NamesSortedCustom = nil;

local	KARMA_Filter =
	{
		Total = nil,
		Pattern = nil,
		Name = nil,
		Class = nil,
		LevelFrom = nil,
		LevelTo = nil,
		KarmaFrom = nil,
		KarmaTo = nil,
		JoinedAfter = nil,
		JoinedBefore = nil,
		Notes = nil,
		Public = nil,
		Guild = nil,
		Instance = nil,
	};

local	KARMA_PartyNames = {};
local	KARMA_OtherInfos = {};

local	KARMA_TalentInspect =
	{
		OtherFramesWarn = 1,
		AutofetchConfigCache = nil,
		RequiredCount = 0,
		RequiredList = {},
		RequestQueueTimer = 0,

		RequestedUnit = nil,
		RequestedMember = nil,
		RequestedGUID = nil,

		StateNextTime = nil,
		StateCurrent = 0,
		State1Time = nil,
		State2Time = nil,
		State3Time = nil,
		State4Time = nil,

		NotifyInspectCallCount = 0,
		NotifyInspectCallList = {},
		TalentsReadyCallCount = 0,
		TalentsReadyCallList = {},

		DebugMsgState = nil
	};

-- for hiding the tooltip when the minimap menu was openend
local	KARMA_Minimap_Tooltip_Hide = false;

local	KARMA_QuestCache = {};
local	KARMA_QuestCache_LastUpdated = -1;
local	KARMA_QuestCache_LastQLEC = -1;

-- Queues
local	KARMA_LastUpdateTime = 0;
local	KARMA_LastCronTime = 0;
local	KARMA_LastMessageTime = 0;
local	KARMA_WhoElapsedTime = 0;

local	Karma_Executing_Command = false;
local	Karma_CommandQueue = {}
local	Karma_MessageQueue = {}
local	Karma_Executing_Who = nil;
local	Karma_WhoQueue = {};
local	Karma_CronQueue = {}

local	KARMA_RacesAlliance =
	{
		[1] = "KRA_DRAENEI",
		[2] = "KRA_DWARF",
		[3] = "KRA_GNOME",
		[4] = "KRA_HUMAN",
		[5] = "KRA_NIGHTELF"
	}

local	KARMA_ClassToAllianceRace_Matrix =
	{
		-- races: Draenei, Dwarf, Gnome, Human, Night Elf
		 [1] = "00001",	--	Druid
		 [2] = "11001",	--	Hunter
		 [3] = "10110",	--	Mage
		 [4] = "11010",	--	Paladin
		 [5] = "11011",	--	Priest
		 [6] = "01111",	--	Rogue
		 [7] = "10000",	--	Shaman
		 [8] = "11111",	--	Warrior
		 [9] = "00110",	--	Warlock
		[10] = "11111"	--	Deathknight
	}

local	KARMA_RacesHorde =
	{
		[1] = "KRH_BLOODELF",
		[2] = "KRH_ORC",
		[3] = "KRH_TAUREN",
		[4] = "KRH_TROLL",
		[5] = "KRH_UNDEAD"
	}

local	KARMA_ClassToHordeRace_Matrix =
	{
		-- races: Blood Elf, Orc, Tauren, Troll, Undead
		 [1] = "00100",	--	Druid
		 [2] = "11110",	--	Hunter
		 [3] = "10011",	--	Mage
		 [4] = "10000",	--	Paladin
		 [5] = "10011",	--	Priest
		 [6] = "11011",	--	Rogue
		 [7] = "01110",	--	Shaman
		 [8] = "01111",	--	Warrior
		 [9] = "11001",	--	Warlock
		[10] = "11111"	--	Deathknight
	}

local	KARMA_Online =
		{
			ChannelTime = 0;
			ChannelName = nil;
			PlayersVersion = 0;
			PlayersAll = {};
			PlayersAllFilter = {
					minKarma = 50,
					KarmaReq = 0,
					minSkill = nil,
					ClassKnown = 0,
					LevelFrom = nil,
					LevelTo = nil,
					TalentHPS = 1,
					TalentTANK = 1,
					TalentDPS = 1,
					TalentMelee = 1,
					TalentRange = 1,
					ClassDruid = 1,
					ClassHunter = 1,
					ClassMage = 1,
					ClassPaladin = 1,
					ClassPriest = 1,
					ClassRogue = 1,
					ClassShaman = 1,
					ClassWarlock = 1,
					ClassWarrior = 1,
					ClassDeathknight = 1,
					Alts = false,
				},
			PlayersAllCache =
				{
					Version = 0,
					List1_Raw = {},
					List1_Srt = {},
					List1_Clean = nil
				},
			PlayersChosen = {};
		};

-- Patch routine holders
local	KARMA_OriginalChatFrame_OnEvent = nil;
local	KARMA_Original_Who_Update = nil;

local	KARMA_WarnedOnce = 0;

-- no update on zone type unless time() - Karma_ZoneChanged > 5
local	Karma_ZoneChanged = 0;

-- maybe, maybe not... pondering
--local	oFaction = nil;

local	KARMA_MAXLEVEL = 80;

----------------------------------------------------------------------------------
-- FUNCTION META OBJECTS: too many copies of code, need some tables to simplify...
----------------------------------------------------------------------------------

KarmaModuleLocal.UIConfig.Elements =
	{
--[[
		-- examples:
			-- sublist: CFG, TYPE, DEPENDS, DEFAULT, MINVAL, MAXVAL
		"Object" =									-- boolean Checkbutton
			{ CFG = KARMA_CONFIG*, TYPE = "bool", DEPENDS = KARMA_CONFIG*, DEFAULT = value, MINVAL = value, MAXVAL = value },
		"Object2" = { "Config2", "01" },			-- 0/1 Checkbutton
		"Object2" = { "Config2", "0n" },			-- 0..n editbox
		"Object3" = { "Config3", "karma" },			-- 1..100 editbox
		"Object3" = { "Config3", "number" },		-- distinct values selection (menu)
		"Object3" = { "Config3", "float" },			-- non-integer number (editbox)
		"Object3" = { "Config3", "string" }			-- string values (non-numeric editbox)
]]--

		-- colorspace configurable:
		["KarmaOptionsWindow_ColorSpace_Enable_Checkbox"] =
			{ CFG = KARMA_CONFIG.COLORSPACE_ENABLE, TYPE = "bool" },

		-- markup
		["KarmaOptionWindow_MarkupEnabled_Checkbox"] =
			{ CFG = KARMA_CONFIG.MARKUP_ENABLED, TYPE = "bool" },
		["KarmaOptionWindow_MarkupWhispers_Checkbox"] =
			{ CFG = KARMA_CONFIG.MARKUP_WHISPERS, TYPE = "bool", DEPENDS = KARMA_CONFIG.MARKUP_ENABLED },
		["KarmaOptionWindow_MarkupChannels_Checkbox"] =
			{ CFG = KARMA_CONFIG.MARKUP_CHANNELS, TYPE = "bool", DEPENDS = KARMA_CONFIG.MARKUP_ENABLED },
		["KarmaOptionWindow_MarkupYSE_Checkbox"] =
			{ CFG = KARMA_CONFIG.MARKUP_YELLSAYEMOTE, TYPE = "bool", DEPENDS = KARMA_CONFIG.MARKUP_ENABLED },
		["KarmaOptionWindow_MarkupGuild_Checkbox"] =
			{ CFG = KARMA_CONFIG.MARKUP_GUILD, TYPE = "bool", DEPENDS = KARMA_CONFIG.MARKUP_ENABLED },
		["KarmaOptionWindow_MarkupRaid_Checkbox"] =
			{ CFG = KARMA_CONFIG.MARKUP_RAID, TYPE = "bool", DEPENDS = KARMA_CONFIG.MARKUP_ENABLED },
		["KarmaOptionWindow_MarkupBG_Checkbox"] =
			{ CFG = KARMA_CONFIG.MARKUP_BG, TYPE = "bool", DEPENDS = KARMA_CONFIG.MARKUP_ENABLED },

		-- autoignore
		["KarmaOptionWindow_AutoignoreEnabled_Checkbox"] =
			{ CFG = KARMA_CONFIG.AUTOIGNORE, TYPE = "01" },
		["KarmaOptionWindow_IgnoreInvites_Checkbox"] =
			{ CFG = KARMA_CONFIG.AUTOIGNORE_INVITES, TYPE = "01", DEPENDS = KARMA_CONFIG.AUTOIGNORE },
		["KarmaOptionWindow_IgnoreInvites_Checkbox"] =
			{ CFG = KARMA_CONFIG.AUTOIGNORE_INVITES, TYPE = "01", DEPENDS = KARMA_CONFIG.AUTOIGNORE },
		["KarmaOptionWindow_AutoIgnoreThreshold"] =
			{ CFG = KARMA_CONFIG.AUTOIGNORE_THRESHOLD, TYPE = "karma" },

		-- autowarn
		["KarmaOptionWindow_WarnLowKarma_Checkbox"] =
			{ CFG = KARMA_CONFIG.JOINWARN_ENABLED, TYPE = "01" },
		["KarmaOptionWindow_WarnLowKarma_Threshold"] =
			{ CFG = KARMA_CONFIG.JOINWARN_THRESHOLD, TYPE = "karma" },

		-- Sharing
		["KarmaOptionWindow_Sharing_ChannelAutoJoinHide_Checkbox"] =
			{ CFG = KARMA_CONFIG.SHARE_CHANNEL_AUTO, TYPE = "bool" },

		-- DBClean (1)
		["KarmaOptionWindow_DBClean_AutoClean_Checkbox"] =
			{ CFG = KARMA_CONFIG.CLEAN_AUTO, TYPE = "bool" },

		-- DBClean (2)
		["KarmaOptionWindow_DBClean_KeepIfNote_Checkbox"] =
			{ CFG = KARMA_CONFIG.CLEAN_KEEPIFNOTE, TYPE = "01" },
		["KarmaOptionWindow_DBClean_RemovePvPJoins_Checkbox"] =
			{ CFG = KARMA_CONFIG.CLEAN_REMOVEPVPJOINS, TYPE = "01" },
		["KarmaOptionWindow_DBClean_RemoveXServer_Checkbox"] =
			{ CFG = KARMA_CONFIG.CLEAN_REMOVEXSERVER, TYPE = "01" },
		["KarmaOptionWindow_DBClean_KeepIfKarma_Checkbox"] =
			{ CFG = KARMA_CONFIG.CLEAN_KEEPIFKARMA, TYPE = "01" },
		["KarmaOptionWindow_DBClean_KeepIfQListThres_Editbox"] =
			{ CFG = KARMA_CONFIG.CLEAN_KEEPIFQUESTCOUNT, TYPE = "0n" },
		["KarmaOptionWindow_DBClean_KeepIfZListThres_Editbox"] =
			{ CFG = KARMA_CONFIG.CLEAN_KEEPIFZONECOUNT, TYPE = "0n" },
		["KarmaOptionWindow_DBClean_KeepIfRListThres_Editbox"] =
			{ CFG = KARMA_CONFIG.CLEAN_KEEPIFREGIONCOUNT, TYPE = "0n" },
		["KarmaOptionWindow_DBClean_IgnorePVPZones_Checkbox"] =
			{ CFG = KARMA_CONFIG.CLEAN_IGNOREPVPZONES, TYPE = "01" },

		-- other
		["KarmaOptionWindow_OtherTargetColored_Checkbox"] =
			{ CFG = KARMA_CONFIG.TARGET_COLORED, TYPE = "01", DEFAULT = 1 },
		["KarmaOptionWindow_Other_QCacheWarn_Checkbox"] =
			{ CFG = KARMA_CONFIG.QUESTWARNCOLLAPSED, TYPE = "01", DEFAULT = 1 },
		-- missing: mapping of menu for initial tab
		["KarmaOptionWindow_Other_AutocheckTalents_Checkbox"] =
			{ CFG = KARMA_CONFIG.TALENTS_AUTOFETCH, TYPE = "01" },
		["KarmaOptionWindow_Other_MinimapIconHide_Checkbox"] =
			{ CFG = KARMA_CONFIG.MINIMAP_HIDE, TYPE = "01" },
		["KarmaOptionWindow_Other_QuestsIgnoreDailies_Checkbox"] =
			{ CFG = KARMA_CONFIG.QUESTSIGNOREDAILIES, TYPE = "01" },
		["KarmaOptionWindow_Other_UpdateWhileAFK_Checkbox"] =
			{ CFG = KARMA_CONFIG.UPDATEWHILEAFK, TYPE = "01" },
		["KarmaOptionWindow_Other_ContextMenuDeactivate_Checkbox"] =
			{ CFG = KARMA_CONFIG.MENU_DEACTIVATE, TYPE = "01" },
		["KarmaOptionWindow_Other_DBSparseTables_Checkbox"] =
			{ CFG = KARMA_CONFIG.DB_SPARSE, TYPE = "01" },

		-- virtual Karma
		["KarmaOptionWindow_VirtualKarma_TimeKarma_Checkbox"] =
			{ CFG = KARMA_CONFIG.TIME_KARMA_DEFAULT, TYPE = "01" },
		["KarmaOptionWindow_VirtualKarma_TimeKarmaThreshold_Editbox"] =
			{ CFG = KARMA_CONFIG.TIME_KARMA_MINVAL, TYPE = "karma", DEFAULT = 50 },
		["KarmaOptionWindow_VirtualKarma_TimeKarmaFactor_Editbox"] = 
			{ CFG = KARMA_CONFIG.TIME_KARMA_FACTOR, TYPE = "float", DEFAULT = 0.4, MINVAL = 0.01, MAXVAL = 10.0 },
		["KarmaOptionWindow_VirtualKarma_SkipBGTime_Checkbox"] =
			{ CFG = KARMA_CONFIG.TIME_KARMA_SKIPBGTIME, TYPE = "01", DEFAULT = 1 },

		-- tooltip options
		["KarmaOptionWindow_OtherKarmaTips_Checkbox"] =
			{ CFG = KARMA_CONFIG.TOOLTIP_KARMA, TYPE = "bool" },
		["KarmaOptionWindow_OtherNoteTips_Checkbox"] =
			{ CFG = KARMA_CONFIG.TOOLTIP_NOTES, TYPE = "bool" },
		["KarmaOptionWindow_Tooltip_Skill_Checkbox"] =
			{ CFG = KARMA_CONFIG.TOOLTIP_SKILL, TYPE = "01" },
		["KarmaOptionWindow_Tooltip_Talents_Checkbox"] =
			{ CFG = KARMA_CONFIG.TOOLTIP_TALENTS, TYPE = "01" },
		["KarmaOptionWindow_Tooltip_Alts_Checkbox"] =
			{ CFG = KARMA_CONFIG.TOOLTIP_ALTS, TYPE = "01" },
		["KarmaOptionWindow_Tooltip_Help_Checkbox"] =
			{ CFG = KARMA_CONFIG.TOOLTIP_HELP, TYPE = "01" },

		-- core features: tracking
		["KarmaOptionWindow_CoreFeatures_TrackingDisableQuests_Checkbox"] = 
			{ CFG = KARMA_CONFIG.TRACK_DISABLEQUEST, TYPE = "01", DEFAULT = 0 },
		["KarmaOptionWindow_CoreFeatures_TrackingDisableAchievements_Checkbox"] = 
			{ CFG = KARMA_CONFIG.TRACK_DISABLEACHIEVEMENT, TYPE = "01", DEFAULT = 0 },
		["KarmaOptionWindow_CoreFeatures_TrackingDisableRegions_Checkbox"] = 
			{ CFG = KARMA_CONFIG.TRACK_DISABLEREGION, TYPE = "01", DEFAULT = 0 },
		["KarmaOptionWindow_CoreFeatures_TrackingDisableZones_Checkbox"] = 
			{ CFG = KARMA_CONFIG.TRACK_DISABLEZONE, TYPE = "01", DEFAULT = 0 },
	};

-----------------------------------------------------------------
-- FUNCTIONS: LOCAL (everything that need not be visible outside, could add a whole lot more...)
-----------------------------------------------------------------

-- local	CommonRegionZoneAddCurrent;
local	CommonRegionZoneAdd;
local	CommonRegionListGet;
local	CommonZoneListGet;

local	CommonQuestAdd;
--local	CommonQuestListGet; -- -> KarmaObj.DB.CF.QuestNameListGet;
local	CommonQuestInfoListGet;

local	Karma_IDToClass;
local	Karma_ClassToID;

local	WhoAmI;

-- local just to be on the safe side...
local	Karma_MemberObject_SetName;
local	Karma_MemberObject_SetGUID;

local	KARMA_FriendsFrameVisible = nil;
local	KARMA_FriendsFrameUnregistered = nil;
local	KARMA_WhoRequest = nil;
local	KARMA_WhoRequestIsMine = 0;

local	KARMA_InspectByUser = {};

----------------------------------------------
-- FUNCTIONS: QUICK&SHORT LOCALS
----------------------------------------------
function	KarmaObj.StringInitial(input)
	local	c = strsub(input, 1, 1);
	if (c >= 'A') and (c <= 'Z') then
		return c;
	end

	local	b1 = strbyte(input, 1);

	if (b1 >= 192) and (b1 <= 223) then
		-- two-byte-sequence
		c = strsub(input, 1, 2);
		return c;
	end

	if (b1 >= 224) and (b1 <= 239) then
		-- three-byte-sequence
		c = strsub(input, 1, 3);
		return c;
	end

	if (b1 >= 240) then
		-- four-byte-sequence
		c = strsub(input, 1, 4);
		return c;
	end

	-- giving up...
	return c;
end

function	KarmaObj.StringInitialCapitalized(input)
	local	c = KarmaObj.StringInitial(input);
	return strupper(c) .. strsub(input, 1 + strlen(c));
end

KarmaObj.UTF8 = {};

function	KarmaObj.UTF8.FirstChar(sValue)
	local	b1 = strbyte(sValue, 1);
	if (b1 < 191) then
		-- two-byte-sequence
		c = strsub(sValue, 1, 1);
		return c, 1;
	end

	if (b1 >= 192) and (b1 <= 223) then
		-- two-byte-sequence
		c = strsub(sValue, 1, 2);
		return c, 2;
	end

	if (b1 >= 224) and (b1 <= 239) then
		-- three-byte-sequence
		c = strsub(sValue, 1, 3);
		return c, 3;
	end

	if (b1 >= 240) then
		-- four-byte-sequence
		c = strsub(sValue, 1, 4);
		return c, 4;
	end

	-- actually, shouldn't get here...
	return c, 1;
end

function	KarmaObj.UTF8.LenInChars(_sValue)
	local	iLen = 0;
	local	sValue = _sValue;
	if (sValue == nil) then
		return iLen;
	end

	while (sValue ~= "") do
		local	c1, l1 = KarmaObj.UTF8.FirstChar(sValue);
		iLen = iLen + 1;
		sValue = strsub(sValue, 1 + l1);
	end

	return iLen;
end

function	KarmaObj.UTF8.SubInChars(_sValue, iFrom, iTo)
	local	iLen = 0;
	local	sValue = _sValue;
	if (sValue == nil) then
		return sValue;
	end

	local	sResult = "";
	while (sValue ~= "") do
		local	c1, l1 = KarmaObj.UTF8.FirstChar(sValue);
		iLen = iLen + 1;
		if (iLen >= iFrom) and ((iTo == nil) or (iLen <= iTo)) then
			sResult = sResult .. c1;
		end
		sValue = strsub(sValue, 1 + l1);
	end

	return sResult;
end

--
--	Turn accented characters into plain non accented characters
--	this is very useful for the purpose of sorting, so that all
--	A's regardless of accent get sorted into the same bucket.
--
function	KarmaObj.NameToBucket(input)
	-- direct ASCII
	local	c = KarmaObj.StringInitial(input);
	if (c >= 'A') and (c <= 'Z') then
		return c;
	end

	-- mappable UTF8
	local	b1 = strbyte(c, 1);
	if (KARMA_ALPHACHARS_UTF8_FORWARD[b1]) then
		local	b2 = strbyte(c, 2);
		if (KARMA_ALPHACHARS_UTF8_FORWARD[b1][b2]) then
			return KARMA_ALPHACHARS_UTF8_FORWARD[b1][b2];
		end
	end

	-- other: changed from "Y" to "X", because "Y" is actually not that uncommon...
	return "X";
end

--
-- for pattern searching, convert whole string to ascii
--
function	KarmaObj.StringToASCII(input)
	if (not input) or (input == "") then
		return input;
	end

	local	result = "";

	local	c, cub, b1, b2, d;
	repeat
		-- direct ASCII
		c = KarmaObj.StringInitial(input);
		cup = strupper(c);
		if (cup >= 'A') and (cup <= 'Z') then
			result = result .. c;
		else
			d = c;

			-- mappable UTF8?
			local	b1 = strbyte(cup, 1);
			if (KARMA_ALPHACHARS_UTF8_FORWARD[b1]) then
				local	b2 = strbyte(cup, 2);
				if (KARMA_ALPHACHARS_UTF8_FORWARD[b1][b2]) then
					d = KARMA_ALPHACHARS_UTF8_FORWARD[b1][b2];
				end
			end

			if (c == cup) then
				result = result .. d;
			else
				result = result .. strlower(d);
			end
		end
		input = strsub(input, 1 + strlen(c));
	until (not input or (input == ""));

	return result;
end

--
-- to cut down notes into something not overly large (Pydia's monster notes...)
--
KarmaModuleLocal.Helper = {};
function	KarmaModuleLocal.Helper.ExtractHeader(sText, iLinesMax, iCharsMax)
	if (sText == nil) or (sText == "") then
		return "";
	end

-- KarmaChatDebug("Cutting down >" .. strsub(sText, 1, 100) .."<(...)");

	-- first n lines until an empty line
	-- if no empty line, no more than l lines
	-- total not more than c chars
	local	LINES_MAX = 5;
	local	CHARS_MAX = 200;
	if (iLinesMax) then
		LINES_MAX = iLinesMax;
	end
	if (iCharsMax) then
		CHARS_MAX = iCharsMax;
	end

	local	iLines = 0;
	local	sResult = "";
	for iLine = 1, LINES_MAX do
		iPos = strfind(sText, "\n", 1, true);
		if (iPos == nil) then
			sResult = sResult .. "\n" .. sText;
			sText = "";
			break;
		elseif (iPos == 1) then
			break;
		else
			sResult = sResult .. "\n" .. strsub(sText, 1, iPos - 1);
			sText = strsub(sText, iPos + 1);
		end
	end
	if (strlen(sResult) > CHARS_MAX) then
		sText = strsub(sResult, CHARS_MAX) .. sText;
		sResult = strsub(sResult, 1, CHARS_MAX - 1) .. "(...)";
	end
	if (sText ~= "") then
		sResult = sResult .. "\n### (" .. strlen(sText) .. " more chars)";
	end
	if (sResult ~= "") then
		return strsub(sResult, 2);
	else
		return sResult;
	end
end

----------------------------------------------
-- FUNCTIONS: GLOBAL
----------------------------------------------

function	Karma_WhoAmIInit()
	if (WhoAmI == nil) then
		WhoAmI = UnitName("player");
		if ((WhoAmI == KARMA_UNKNOWN) or (WhoAmI == KARMA_UNKNOWN_ENT)) then
			-- not yet available
			WhoAmI = nil;
		else
			KARMA_CURRENTCHAR = WhoAmI;
			if (KARMA_CURRENTMEMBER ~= nil) then
				-- refresh char dropdown
				Karma_SetCurrentMember(KARMA_CURRENTMEMBER);
			end
		end
	end
end

function	Karma_OnLoad()
	KARMA_ININIT = 1;

	Karma_SetupDebug();
	KarmaObj.ProfileStart("Karma_OnLoad");
	Karma_InitSlash();

	KARMA_VERSION_TEXT = GetAddOnMetadata("Karma", "Version");
	if (KARMA_VERSION_TEXT == nil) then
		KARMA_VERSION_TEXT = "???";
	end
	KARMA_VERSION_DATE = GetAddOnMetadata("Karma", "X-Date");
	if (KARMA_VERSION_DATE == nil) then
		KARMA_VERSION_DATE = "???";
	end

	-- We want this to show up in the main chat window.
	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(KARMA_TITLE .. KARMA_WINEL_FRAG_SPACE .. "v" .. KARMA_VERSION_TEXT .. KARMA_INITIAL_MESSAGE);
	end

	KarmaObj.Talents.SpecCount = 1;
	local	_, _, _, iTOC = GetBuildInfo();
	if (iTOC >= 30100) then
		KarmaObj.Talents.SpecCount = 2;
	end

	this:RegisterEvent("ADDON_LOADED");
	this:RegisterEvent("VARIABLES_LOADED");		-- as of 3.x this **seems** to be deprecated

	-- for debugging of FORBIDDEN popup
	this:RegisterEvent("ADDON_ACTION_FORBIDDEN");

	-- legacy: older tooltip data (potentially translated)
	if (KARMA_FILTER_TOOLTIP) then
		KARMA_TOOLTIPS["FILTER"] = KARMA_FILTER_TOOLTIP;
	end

	KarmaObj.ProfileStop("Karma_OnLoad");
end

function	Karma_SpecAvailable(iSpec)
	return (iSpec >= 1) and (iSpec <= KarmaObj.Talents.SpecCount);
end

function	Karma_FullInitialise()
	if (UnitName("player") ~= nil) and (UnitName("player") ~= UNKNOWNOBJECT) and (UnitName("player") ~= "") then
		Karma_InitializeConfig();

		KarmaObj.DB.Create();
		KarmaObj.DB.Upgrade();
		KarmaObj.DB.FactionCacheInit();

		Karma_IntializePlayerObject();

		-- Sometimes we get crap entries. Clear them
		Karma_CleanDatabase();

		-- => config per char
		KARMA_LOADED = 1;

		-- 2nd call: now charspecific choices are available
		Karma_SetupChatWindows();

		local	iVer = Karma_GetConfig(KARMA_CONFIG.MARKUP_VERSION) or 2;
		if (iVer == 1) then
			-- those should be always safe to taint, they're all non-combat frames
			KarmaChatSecondaryFallbackDefault("Old version of feature 'chat markup' is active. Please change to the new version in options->chat windows->markup, newer version.");
			Karma_InsertChatFramePatch();		-- colourisation, ignore
		end

		-- newer mechanic, if possible other mechanics should be moved here...
		Karma_HookSecureFunctions();

		KarmaObj.Achievements.CacheCreate();
		Karma_CreateQuestCache();
		Karma_MemberList_CreatePartyNamesCache();
		Karma_MemberList_CreateMemberNamesCache();
		Karma_AddTimeToPartyMembers();

		Karma_MinimapIconFrame_InitComplete();

		if (Karma_GetConfig(KARMA_CONFIG_SKILL_MODEL) == "complex") then
			KARMA_SKILL_LEVELS = KARMA_SKILL_LEVELS_COMPLEX;
		else
			KARMA_SKILL_LEVELS = KARMA_SKILL_LEVELS_SIMPLE;
		end

		if (Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_AUTO) == true) then
			KarmaModuleLocal.Command.ChannelAutoQueue();
		end

		if (IsInGuild()) then
			KarmaModuleLocal.Command.VersionQueryQueue("?v1", "GUILD");
		end

		local	oFaction = KarmaObj.DB.FactionCacheGet();
		local	olMembers = oFaction[KARMA_DB_L4_RRFF.XFACTIONHOLD];
		if (type(olMembers) == "table") then
			local	iCount, key, value = 0;
			for key, value in pairs(olMembers) do
				iCount = iCount + 1;
			end
			if (iCount > 0) then
				KarmaModuleLocal.Command.xFactionRemindUpdateQueue(iCount);
			end
		end

		if (Karma_GetConfig(KARMA_CONFIG.MENU_WARN) == 1) then
			-- this happens when the user didn't choose before but quit WoW
			StaticPopup_Show("KARMA_BLIZZARDBROKEMENUS_AGAIN");
		end
	else
		Karma_MemberList_CreatePartyNamesCache();

		-- does this make sense?? somewhat.
		KARMA_ININIT = 100;
	end
end

local function KarmaRegisterWithmyAddOns()
	if ((myAddOnsFrame_Register ~= nil) and (KarmaObj.myAddOnsRegistered ~= 1)) then
		local	KarmaHelp = {};
		local	key, value;

		local	KarmaHelp1 = "";
		for key, value in pairs(KARMA_CMDLINE_HELP_SHORT) do
			KarmaHelp1 = KarmaHelp1 .. value .. "\n";
		end
		KarmaChatDebug(KarmaHelp1);
		tinsert(KarmaHelp, KarmaHelp1);

		local	oHelp = KARMA_CMDLINE_HELPMETA_FULL;
		if (KARMA_CMDLINE_HELP_LONG ~= nil) then
			oHelp = KARMA_CMDLINE_HELPMETA_LEGACY;
		end
		local	KarmaHelp2 = "";
		for key, value in pairs(oHelp) do
			local	oGroup = getglobal("KARMA_CMDLINE_HELP_" .. value);
			if (type(oGroup) == "table") then
				local	ksub, vsub;
				for ksub, vsub in pairs(oGroup) do
					KarmaHelp2 = KarmaHelp2 .. vsub .. "\n";
				end
			end
		end
		KarmaChatDebug(KarmaHelp2);
		tinsert(KarmaHelp, KarmaHelp2);

		local	KarmaDetails = { name = "Karma", author = "K\195\164rb\195\164r" };
		myAddOnsFrame_Register(KarmaDetails, KarmaHelp);
		KarmaObj.myAddOnsRegistered = 1;
	end
end

function	KarmaObj.RegisterWIMModule()
-- WIM bridge
-- WhisperEngine.lua:
--    local WhisperEngine = CreateModule("WhisperEngine");
-- WindowHandler.lua:
--    CallModuleFunction("OnWindowCreated", obj);

	if (WIM and (type(WIM) == "table") and (type(WIM.CreateModule) == "function")) then
		if (KarmaObj.Karma2WIMBridge == nil) then
			KarmaObj.Karma2WIMBridge = WIM.CreateModule("Karma2WIMBridge", true);
			KarmaObj.Karma2WIMBridge.OnWindowCreated = function(self, oWnd)
					if (oWnd and (type(oWnd) == "table") and (oWnd.theUser)) then
						KarmaChatSecondary("(WIM integration) Checking for information about " .. KOH.Name2Clickable(oWnd.theUser) .. "...");
						local	oMember = Karma_MemberList_GetObject(oWnd.theUser);
						if (oMember ~= nil) then
							oWnd.widgets.from:SetText(oWnd.theUser .. " <" .. Karma_MemberObject_GetKarmaModifiedForListWithColors(oMember) .. ">");
						else
							oWnd.widgets.from:SetText(oWnd.theUser .. " <-->");
						end;
					end;
				end;
			KarmaObj.Karma2WIMBridge.enabled = true;
			KarmaChatDebug("Registered WIM module.");
		else
			KarmaChatDebug("WIM module *IS* already registered.");
		end
	else
		KarmaChatDebug("Failed to register WIM module.");
	end
end

KarmaObj.BrokerCallback = {};

function	KarmaObj.BrokerCallback.CQLInfo()
	local	iCmdCnt = #Karma_CommandQueue;
	if (iCmdCnt > 0) then
		local	sMsg = "There are " .. iCmdCnt .. " commands pending.";
		if (not IsControlKeyDown()) then
			return sMsg .. " (CTRL for tech. details)";
		end

		local	sMsgL, sMsgR;

		local	oNames, i = {};
		for i = 1, iCmdCnt do
			local	sName = Karma_CommandQueue[i].sName;
			if (sName and (sName ~= "classcheck done")) then
				tinsert(oNames, sName);
			end
		end

		iCmdCnt = #oNames;
		if (iCmdCnt > 0) then
			sMsg = sMsg .. "\nNext command ";
			local	TimeNow = GetTime();
			if (KarmaModuleLocal.Timers.CmdQ > TimeNow) then
				sMsg = sMsg .. " in " .. format("%.2f", KarmaModuleLocal.Timers.CmdQ - TimeNow) .. " seconds";
			end
			sMsg = sMsg .. " is <" .. oNames[1] .. ">";

			if (iCmdCnt > 1) then
				sMsgL = "";
				local	iL = math.min(5, iCmdCnt);
				for i = 2, iL do
					sMsgL = sMsgL .. "\n[" .. i .. "] " .. oNames[i];
				end

				if (iCmdCnt <= 5) then
					sMsg = sMsg .. sMsgL;
					sMsgL = nil;
				else
					sMsgR = "";
					local	iR = math.min(9, iCmdCnt);
					for i = 6, iR do
						sMsgR = sMsgR .. "\n[" .. i .. "] " .. oNames[i];
					end

					-- cut extra newlines
					sMsgL = strsub(sMsgL, 2);
					sMsgR = strsub(sMsgR, 2);
				end
			end
		end

		return sMsg, sMsgL, sMsgR
	end
end

function	Karma_OnEvent(self, event, ...)
	KarmaObj.ProfileStart("Karma_OnEvent");
	if (DEFAULT_CHAT_FRAME) then
		local	tEventText = ""
		local	iCount = 0;
		tEventText = event;
		for iCount = 1, 10 do
			local	av = getglobal("arg"..iCount);
			if (av and av ~= "") then
				if (av == true) then
					tEventText = tEventText.." arg"..iCount.." = true";
				elseif (av == false) then
					tEventText = tEventText.." arg"..iCount.." = false";
				else
					tEventText = tEventText.." arg"..iCount.." = "..av;
				end
			end
		end

		-- **whole** lot of spam
		if (KARMA_ALWAYS_WATCH_EVENTS == false) then
			KarmaChatKarma(tEventText);
		else
			KarmaChatDebug(tEventText, 1.0, 0, 0.90);
		end
	end

	if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		local	arg1, arg2 = ...;
		if ((strsub(arg2, 1, 5) == "UNIT_") or (strsub(arg2, 1, 6) == "PARTY_")) then
			local	arg1, arg2, arg3, arg4, arg5, arg6, arg7 = ...;
			if (arg7 == nil) then
				arg7 = "<unknown??>";
			end

			local	bMob, sMob = false, " <p.c./pet>";
			if (arg6) then
				local	sType = strsub(arg6, 3, 5);
				local	iType = tonumber(sType, 16);
				-- mask MUST be 0x007, not 0x00F, because merged cross-language BG players can have 0x??8* GUIDs
				if (3 == bit.band(iType, 7)) then
					bMob = true;
					sMob = " <mob>";
				end
			end

			KarmaChatDebug("CLEU: " .. arg2 .. " -> " .. arg7 .. sMob);
			if (bMob) then
				KarmaModuleLocal.PlayerRegenEnabledOrMobDied = GetTime();
			end
		end
	elseif (event == "CHAT_MSG_CHANNEL") then
		Karma_ChatMsg_Channel(self, event, ...);
	elseif (event == "PLAYER_TARGET_CHANGED") then
		Karma_Event_PlayerTargetChanged();
	elseif (event == "UPDATE_MOUSEOVER_UNIT") then
		Karma_Event_UpdateMouseOverUnit();
	elseif (event == "PLAYER_XP_UPDATE") then
		if (KARMA_LOADED == 1) then
			if (Karma_EverythingLoaded()) then
				Karma_AddTimeToPartyMembers();
				Karma_AddXPToPartyMembers();
				KarmaWindow_Update();
			end
		end
	elseif (event == "CHAT_MSG_CHANNEL_NOTICE") then
		local	arg1, _2, _3, arg4, _5, _6, arg7, arg8, arg9 = ...;
		-- KarmaChatDebug("CHAT_MSG_CHANNEL_NOTICE: " .. arg1 .. " => [" .. arg7 .. "] " .. arg8 .. ". " .. arg9);

		-- arg1:
		-- - YOU_JOINED (real join or re-join after SUSPENDED)
		-- - YOU_LEFT
		-- - YOU_CHANGED (General - Darnassus => General - Teldrassil)
		-- - SUSPENDED (#Trade, #LFGuild city -> outside)
		-- arg7: type (0 = custom, 1..n = Blizzard official channel
		-- arg8: channel #
		-- arg9: channel name
		if (arg1 ~= "YOU_CHANGED") then
			local	sChanKarma = Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME);
			if (sChanKarma) then
				local	sChanKarmaLower = strlower(sChanKarma);
				if (sChanKarmaLower == strlower(arg9)) then
					KarmaChatDebug("Changes regarding Karma share channel detected: " .. arg1 .. " => [" .. arg7 .. "] #" .. arg8);
					local	oChanKarma = KarmaModuleLocal.Channels[0];
					if (oChanKarma == nil) then
						KarmaModuleLocal.Channels[0] = {};
						oChanKarma = KarmaModuleLocal.Channels[0];
						oChanKarma.NameUser  = "<internal>";
						oChanKarma.NameShort = "<internal>";
						oChanKarma.BlizzChan = 0;
						oChanKarma.Number    = nil;
					end

					if (arg1 == "YOU_LEFT") then
						oChanKarma.BlizzChan      = 0;
						oChanKarma.Number    = nil;
					elseif (arg1 == "YOU_JOINED") then
						oChanKarma.BlizzChan = arg7;
						if (oChanKarma.BlizzChan ~= 0) then
							KarmaChatDefault("INVALID communication channel <#" .. arg4 .. "> (Blizzard channel)");
							oChanKarma.Number = -1;
						else
							KarmaChatDefault("Found communication channel <#" .. arg4 .. ">");
							oChanKarma.Number = arg8;
						end
					end
				end
			end

			KarmaModuleLocal.Channels[arg8] = {};
			local	oChan = KarmaModuleLocal.Channels[arg8];
			oChan.NameUser  = arg4;
			oChan.NameShort = strlower(arg9);
			oChan.BlizzChan = arg7 or 0;
			oChan.Number    = arg8;
		end
	elseif (event == "CHAT_MSG_ADDON") then
		Karma_ChatMsg_AddOn(self, event, ...);
	elseif (event == "CHAT_MSG_SYSTEM") then
		Karma_ChatMsg_System(self, event, ...);
	elseif (strsub(event, 1, 6) == "QUEST_") then
		-- as those are all we registered starting with QUEST_, skip this longish list?
		-- does process 6 string - comparisons for every event...
		if (event == "QUEST_COMPLETE" or event == "QUEST_FINISHED" or event == "QUEST_LOG_UPDATE" or
			event == "QUEST_ITEM_UPDATE" or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" ) then
			if (KARMA_LOADED == 1) then
				if (Karma_EverythingLoaded()) then
					Karma_UpdateQuest();
					Karma_CreateQuestCache(1);
				end
			end
		end
	elseif (event == "RAID_ROSTER_UPDATE") then
		if (KARMA_LOADED == 1) then
			if (Karma_EverythingLoaded()) then
				if (KarmaModuleLocal.Raid.MemberCnt == 0) then
					Karma_ZoneChanged = time() + 15;
					Karma_AddZoneToPartyMember();
				end

				local	bChanged = KarmaModuleLocal.Raid.MemberCnt ~= GetNumRaidMembers();
				KarmaModuleLocal.Raid.MemberCnt = GetNumRaidMembers();

				if (Karma_GetConfig(KARMA_CONFIG.RAID_TRACKALL) == 1) then
					Karma_AddTimeToPartyMembers(1);

					if (bChanged) then
						Karma_MemberList_ResetMemberNamesCache();
						Karma_MemberList_CreatePartyNamesCache();
						-- Karma_Queue_ReCreatePartyNamesCache();
					end
				end

				-- no args, no infos, says wowwiki
				-- KarmaChatDebug("RRU: " .. Karma_NilToString(arg1) .. "/" .. Karma_NilToString(arg2)
				--				.. "/" .. Karma_NilToString(arg3) .. "/" .. Karma_NilToString(arg4));

				local	oHistory = KarmaModuleLocal.Raid.HistoryTables[KarmaModuleLocal.Raid.iIndexHistory];
				if (oHistory == nil) then
					oHistory = {};
					KarmaModuleLocal.Raid.HistoryTables[KarmaModuleLocal.Raid.iIndexHistory] = oHistory;
				end

				if (oHistory.__Start == nil) then
					if (KarmaModuleLocal.Raid.MemberCnt > 0) then
						oHistory.__Start = time();
					end
				end

				-- need to update in any case, if people changed positions
				local	aSpeedup = KarmaModuleLocal.Raid.Name2Index;
				local	sName, value;
				for sName, value in pairs(aSpeedup) do
					value.valid = 0;
				end

				local	i, sName, iPosHyphen;
				for i = 1, MAX_RAID_MEMBERS do
					sName = GetRaidRosterInfo(i);
					if (sName) then
						iPosHyphen = strfind(sName, "-", 1, true);
						if (iPosHyphen) then
							-- BG "raids"
							sName = strsub(sName, 1, iPosHyphen - 1) .. "@" .. strsub(sName, iPosHyphen + 1);
						end
						if (oHistory[sName] == nil) then
							oHistory[sName] = {};
							oHistory[sName].Sideline = 0;
							oHistory[sName].JoinedFirst = time();
						end

						if (aSpeedup[sName] == nil) then
							aSpeedup[sName] = {};
						end

						if (aSpeedup[sName].index == nil) then
							KarmaChatDebug("RRU: " .. sName .. " joined the raid.");
							if ((oHistory[sName].Joined ~= nil) and (oHistory[sName].Left ~= nil)) then
								oHistory[sName].Sideline = oHistory[sName].Sideline + time() - oHistory[sName].Left;
							end

							oHistory[sName].Joined = time();
							oHistory[sName].Left = nil;
						end

						aSpeedup[sName].index = i;
						aSpeedup[sName].valid = 1;
					end
				end

				for sName, value in pairs(aSpeedup) do
					if (value.valid == 0) then
						KarmaChatDebug("RRU: " .. sName .. " left the raid.");
						aSpeedup[sName] = nil;

						if (oHistory[sName] == nil) then
							oHistory[sName] = {};
							oHistory[sName].Sideline = 0;
							oHistory[sName].Joined = time();
						end

						oHistory[sName].Left = time();
					end
				end

				if (bChanged and (KarmaModuleLocal.Raid.MemberCnt == 0) and
				    (GetNumPartyMembers() == 0) and
				    (Karma_GetConfig(KARMA_CONFIG.CLEAN_AUTOPVP) == 1)) then
					local	args = {};
					Karma_SlashCleanPvp(args);
				end

				-- left a raid, next container
				if (bChanged and (KarmaModuleLocal.Raid.MemberCnt == 0)) then
					oHistory.__End = time();
					KarmaModuleLocal.Raid.iIndexHistory = KarmaModuleLocal.Raid.iIndexHistory + 1;
				end
			end
		end
	elseif (event == "PARTY_MEMBERS_CHANGED") then
		if (KARMA_LOADED == 1) then
			if (Karma_EverythingLoaded()) then
				if (KARMA_QEx_NumPartyMembers < GetNumPartyMembers()) then
					if (KARMA_QEx_NumPartyMembers == 0) then
						Karma_ZoneChanged = time() + 15;
						Karma_AddZoneToPartyMember();
					end

					KARMA_QEx_NumPartyMembers = GetNumPartyMembers();
				end

				Karma_CreateQuestCache(1);
				Karma_AddTimeToPartyMembers(1);

				Karma_MemberList_ResetMemberNamesCache();
				Karma_Queue_ReCreatePartyNamesCache();

				if (KARMA_QEx_NumPartyMembers > GetNumPartyMembers()) then
					KARMA_QEx_NumPartyMembers = GetNumPartyMembers();
					Karma_CreateQuestCache(1);
				end

				KarmaWindow_Update();
			end
		end
	elseif	(event == "ZONE_CHANGED") or
		(event == "ZONE_CHANGED_INDOORS") or
		(event == "ZONE_CHANGED_NEW_AREA") then
		Karma_ZoneChanged = time();
	elseif	(event == "PLAYER_SKINNED") then
		if (Karma_ZoneChanged == 0) then
	 		KarmaChatDebug("Event: >> PLAYER_SKINNED");
			CommonRegionZoneAddCurrent(1);	-- only area you can 'skin' a player in: Alterac valley
	 		KarmaChatDebug("Event: << PLAYER_SKINNED");
		end
 	elseif (event == "INSPECT_TALENT_READY") then
 		Karma_InspectTalentReady();
 	elseif (event == "INSPECT_ACHIEVEMENT_READY") then
 		local	sUnit = KarmaObj.Achievements.CheckTerrorReady();
		if (sUnit and KarmaModuleLocal.AchievementCheckTerrorList[sUnit]) then
			KarmaModuleLocal.AchievementCheckTerrorList[sUnit] = nil;
			KarmaModuleLocal.AchievementCheckTerrorCount = KarmaModuleLocal.AchievementCheckTerrorCount - 1;
			if (KarmaModuleLocal.AchievementCheckTerrorCount <= 0) then
				local	i, k, v = 0;
				for k, v in pairs(KarmaModuleLocal.AchievementCheckTerrorList) do
					i = i + 1;
				end
				KarmaModuleLocal.AchievementCheckTerrorCount = i;
				if (i == 0) then
					KarmaObj.Achievements.CheckTerrorDone(KARMA_PartyNames);
				end
			end
		end
	elseif (event == "INSTANCE_BOOT_START") then
		-- why?
		-- KARMA_LOADED = 0;
	elseif (event == "INSTANCE_BOOT_STOP") then
		-- why?
		-- KARMA_LOADED = 1;
	elseif (event == "PLAYER_LOGIN") then
		-- login event, only once per UI init
		KARMA_ININIT = 3;

		-- uses global config only! => silent
		Karma_SetupChatWindows(1);

		-- should work, does not :(
		-- this:RegisterEvent("MINIMAP_ZONE_CHANGED");
		-- hook same as Minimap
		self:RegisterEvent("ZONE_CHANGED");
		self:RegisterEvent("ZONE_CHANGED_INDOORS");
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA");

		-- to get pvp - zones identified
		self:RegisterEvent("PLAYER_SKINNED");

		-- removed hook to UIParent, do it "regular" style
		self:RegisterEvent("PARTY_INVITE_REQUEST");
		self:RegisterEvent("DUEL_REQUESTED");
		self:RegisterEvent("GUILD_INVITE_REQUEST");
		self:RegisterEvent("TRADE_REQUEST");

		-- achievement tracking
		if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEACHIEVEMENT) ~= 1) then
			self:RegisterEvent("ACHIEVEMENT_EARNED");
			self:RegisterEvent("PLAYER_REGEN_ENABLED");
			self:RegisterEvent("PLAYER_REGEN_DISABLED");
		end

		KARMA_ININIT = 100;
	elseif (event == "ADDON_LOADED") then
		local	arg1 = ...;
		KarmaModuleLocal.AddonLoaded[arg1] = GetTime();
	elseif (event == "VARIABLES_LOADED") then
		self:RegisterEvent("PARTY_MEMBERS_CHANGED");
		self:RegisterEvent("RAID_ROSTER_UPDATE");

		self:RegisterEvent("PLAYER_XP_UPDATE");

		self:RegisterEvent("QUEST_COMPLETE");
		self:RegisterEvent("QUEST_FINISHED");
		self:RegisterEvent("QUEST_ITEM_UPDATE");
		self:RegisterEvent("QUEST_PROGRESS");
		self:RegisterEvent("QUEST_DETAIL");
		self:RegisterEvent("QUEST_LOG_UPDATE");

		self:RegisterEvent("INSTANCE_BOOT_START");
		self:RegisterEvent("INSTANCE_BOOT_STOP");
		self:RegisterEvent("PLAYER_LOGIN");
		self:RegisterEvent("PLAYER_ENTERING_WORLD");

		self:RegisterEvent("PLAYER_TARGET_CHANGED");

		self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH");
		self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN");

		self:RegisterEvent("CHAT_MSG_ADDON");
		self:RegisterEvent("CHAT_MSG_SYSTEM");
		self:RegisterEvent("CHAT_MSG_CHANNEL");
		self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");

		self:RegisterEvent("FRIENDLIST_UPDATE");
		self:RegisterEvent("WHO_LIST_UPDATE");

		self:RegisterEvent("PLAYER_TARGET_CHANGED");

		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT");

		KARMA_ININIT = 2;

		KarmaConfigLocal = KarmaConfig;

		-- message in error dialog:
		-- <AddOn> has been blocked because of an action only useable by Blizzard's UI.
		-- You can disactivate this addon and reload the UI.
		StaticPopupDialogs["KARMA_BLIZZARDBROKEMENUS_AGAIN"] = {
				text = KARMA_TAINT_MENU,
				button1 = "DISABLE",
				button2 = "CANCEL",
				OnAccept = function()
						Karma_SetConfig(KARMA_CONFIG.MENU_DEACTIVATE, 1);
						Karma_SetConfig(KARMA_CONFIG.MENU_WARN, 0);
						ReloadUI();
					end,
				OnCancel = function()
						Karma_SetConfig(KARMA_CONFIG.MENU_DEACTIVATE, 0);
						Karma_SetConfig(KARMA_CONFIG.MENU_WARN, 0);
					end,
				timeout = 0,
				whileDead = 1,
				hideOnEscape = 0,
				showAlert = 1,
				notClosableByLogout = 1
			};
	elseif (event == "PLAYER_ENTERING_WORLD") then
		-- this is the event to say 'zoning'... happens on every loading screen
		if (KARMA_ININIT == 100) then
			KARMA_ININIT = 101;

			Karma_FullInitialise();

			-- register with myAddOns
			KarmaRegisterWithmyAddOns();

			-- new...
			if (KarmaConfig.WIM == 1) then
				KarmaObj.RegisterWIMModule();
			end;

			KARMA_ININIT = 312;
		end;
	elseif	(event == "PARTY_INVITE_REQUEST") or
			(event == "DUEL_REQUESTED") or
			(event == "GUILD_INVITE_REQUEST") or
			(event == "TRADE_REQUEST") then
		Karma_AutoIgnore_Invites(event);
	elseif (event == "ACHIEVEMENT_EARNED") then
		Karma_WhoAmIInit();
		KarmaObj.Achievements.Progress(KARMA_PartyNames, WhoAmI, event, ...);
	elseif (event == "PLAYER_REGEN_ENABLED") then
		KarmaModuleLocal.PlayerRegenEnabledOrMobDied = GetTime();
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		KarmaChatDebug("PRE: -> +CLEU");
	elseif (event == "PLAYER_REGEN_DISABLED") then
		KarmaModuleLocal.PlayerRegenEnabledOrMobDied = nil;
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		KarmaChatDebug("PRD: -> -CLEU");
 	elseif (event == "FRIENDLIST_UPDATE") then
 		Karma_Friendlist_Update();
	elseif (event == "WHO_LIST_UPDATE") then
		KarmaModuleLocal.ExecutingWhoSince = nil;
		KarmaModuleLocal.ExecutingWhoBroken = nil;
		Karma_Who_Update(event, ...);
	elseif (event == "ADDON_ACTION_FORBIDDEN") then
		local backtrace = debugstack();
		local	arg1, arg2, arg3 = ...;
		backtrace = event .. KARMA_WINEL_FRAG_COLONSPACE .. Karma_NilToString(arg1) .. "/" .. Karma_NilToString(arg2) .. "/"
					.. Karma_NilToString(arg3) .. " => " .. backtrace;
		if (KARMA_SHOW_FORBIDDEN_IN_MAIN) then
 			KarmaChatDefault(backtrace);
 		else
 			KarmaChatDebug(backtrace);
 		end

		-- if someone tried target/focus, set a flag to warn on next start
		-- arg1: AddOn
		-- arg2: protected function
		if (arg1 == "Karma") then
			if ((arg2 == "TargetUnit()") or (arg2 == "FocusUnit()")) then
				KarmaChatDebug("Setting flag for disable-warning.");
				Karma_SetConfig(KARMA_CONFIG.MENU_WARN, 1);

				-- might be too soon...
				StaticPopup_Hide("ADDON_ACTION_FORBIDDEN");
				StaticPopup_Show("KARMA_BLIZZARDBROKEMENUS_AGAIN");
			end
		end
	end

	KarmaObj.ProfileStop("Karma_OnEvent");
end

function	Karma_EverythingLoaded()
	if (UnitName("player") ~= nil) and (UnitName("player") ~= "") then
		local	x = KarmaObj.DB.FactionCacheGet(true);
		if (x ~= nil) then
			return true;
		end
	end
	return false;
end


function	Karma_SendWho(sRequest, bResend)
	if (not FriendsFrame:IsVisible()) then
		KARMA_FriendsFrameUnregistered = 1;
		FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE");

		Karma_Executing_Who = time();
		if (bResend == nil) then
			KarmaModuleLocal.ExecutingWhoSince = Karma_Executing_Who;
		end
		SetWhoToUI(1);

		KARMA_WhoRequestIsMine = 1;
		KARMA_WhoRequest = sRequest;
		SendWho(sRequest);

		KarmaChatDebug("(Re-)Sending /who <" .. sRequest .. ">... (command queue length: " .. #Karma_CommandQueue .. ")");
	end;
end

--
-- HookSecureFunc etc.
--
function	Karma_HookSecureFunctions()
	hooksecurefunc("NotifyInspect", Karma_SecureHook_NotifyInspect);

	local	bChannel = false;
	local	sChan = Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME); 
	if ((sChan ~= nil) and (sChan ~= "")) then
		bChannel = true;
	end

	if (Karma_GetConfig(KARMA_CONFIG.MENU_DEACTIVATE) ~= 1) then
		KarmaChatDefault("Shortcuts to " .. KARMA_ITSELF .. " functions in context menus are ACTIVE. (If you're bothered with the taint on target/focus, you can disable this in Options/Other.)");

		UnitPopupButtons["KARMA_SPLITTER"]      = { text = "---------------", dist = 0 };
		UnitPopupButtons["KARMA_CHARADD"]       = { text = KARMA_UNITPOPUP_CHARADD, dist = 0 };
		UnitPopupButtons["KARMA_CHARDEL"]       = { text = KARMA_UNITPOPUP_CHARDEL, dist = 0 };
		UnitPopupButtons["KARMA_GIVE4"]         = { text = KARMA_ITSELF_COLONSPACE .. KARMA_UNITPOPUP_INCREASE .. "4", dist = 0 };
		UnitPopupButtons["KARMA_GIVE1"]         = { text = KARMA_ITSELF_COLONSPACE .. KARMA_UNITPOPUP_INCREASE .. "1", dist = 0 };
		UnitPopupButtons["KARMA_TAKE1"]         = { text = KARMA_ITSELF_COLONSPACE .. KARMA_UNITPOPUP_DECREASE .. "1", dist = 0 };
		UnitPopupButtons["KARMA_TAKE4"]         = { text = KARMA_ITSELF_COLONSPACE .. KARMA_UNITPOPUP_DECREASE .. "4", dist = 0 };
		UnitPopupButtons["KARMA_SELECT"]        = { text = KARMA_ITSELF_COLONSPACE .. KARMA_UNITPOPUP_SELECT, dist = 0 };
		if (IsInGuild()) then
			UnitPopupButtons["KARMA_PUBNOTE_GUILD"] = { text = KARMA_ITSELF_COLONSPACE .. KARMA_UNITPOPUP_PUBNOTE_CHECKGUILD, dist = 0 };
		end
		if (bChannel) then
			UnitPopupButtons["KARMA_PUBNOTE_CHANNEL"] = { text = KARMA_ITSELF_COLONSPACE .. KARMA_UNITPOPUP_PUBNOTE_CHECKCHANNEL, dist = 0 };
		end

		table.insert(UnitPopupMenus["PARTY"], "KARMA_SPLITTER");
		table.insert(UnitPopupMenus["PARTY"], "KARMA_GIVE4");
		table.insert(UnitPopupMenus["PARTY"], "KARMA_GIVE1");
		table.insert(UnitPopupMenus["PARTY"], "KARMA_SELECT");
		if (IsInGuild()) then
			table.insert(UnitPopupMenus["PARTY"], "KARMA_PUBNOTE_GUILD");
		end
		if (bChannel) then
			table.insert(UnitPopupMenus["PARTY"], "KARMA_PUBNOTE_CHANNEL");
		end
		table.insert(UnitPopupMenus["PARTY"], "KARMA_TAKE1");
		table.insert(UnitPopupMenus["PARTY"], "KARMA_TAKE4");

		-- target frame popup
		table.insert(UnitPopupMenus["PLAYER"], "KARMA_SPLITTER");
		table.insert(UnitPopupMenus["PLAYER"], "KARMA_CHARADD");
		table.insert(UnitPopupMenus["PLAYER"], "KARMA_GIVE4");
		table.insert(UnitPopupMenus["PLAYER"], "KARMA_GIVE1");
		table.insert(UnitPopupMenus["PLAYER"], "KARMA_SELECT");
		if (IsInGuild()) then
			table.insert(UnitPopupMenus["PLAYER"], "KARMA_PUBNOTE_GUILD");
		end
		if (bChannel) then
			table.insert(UnitPopupMenus["PLAYER"], "KARMA_PUBNOTE_CHANNEL");
		end
		table.insert(UnitPopupMenus["PLAYER"], "KARMA_TAKE1");
		table.insert(UnitPopupMenus["PLAYER"], "KARMA_TAKE4");
		table.insert(UnitPopupMenus["PLAYER"], "KARMA_CHARDEL");

		-- chat popup
		table.insert(UnitPopupMenus["FRIEND"], "KARMA_SPLITTER");
		table.insert(UnitPopupMenus["FRIEND"], "KARMA_CHARADD");
		table.insert(UnitPopupMenus["FRIEND"], "KARMA_SELECT");
		if (IsInGuild()) then
			table.insert(UnitPopupMenus["FRIEND"], "KARMA_PUBNOTE_GUILD");
		end
		if (bChannel) then
			table.insert(UnitPopupMenus["FRIEND"], "KARMA_PUBNOTE_CHANNEL");
		end

		hooksecurefunc("UnitPopup_OnClick", Karma_SecureHook_UnitPopup_OnClick);
	end

	-- new /who handling
	hooksecurefunc(FriendsFrame, "Show", Karma_SecureHook_FriendsFrame_OnShow);
	hooksecurefunc(FriendsFrame, "Hide", Karma_SecureHook_FriendsFrame_OnHide);
	hooksecurefunc("SendWho", Karma_SecureHook_SendWho);

	-- inspect protection...
	hooksecurefunc("InspectUnit", Karma_SecureHook_InspectUnit);

	-- "discovered: <foo>" handling
	hooksecurefunc(UIErrorsFrame, "AddMessage", Karma_SecureHook_UIErrorsFrame_AddMessage);

	if (Karma_GetConfig(KARMA_CONFIG.MARKUP_VERSION) >= 2) then
		if (Karma_GetConfig(KARMA_CONFIG.MARKUP_VERSION) >= 3) then
			KarmaChatSecondaryFallbackDefault("Newest version of feature 'chat markup' is active.");
			-- overwriting ChatFrame.lua::GetColoredName()
			GetColoredName = KOH.GetColoredName;
			KarmaObj.UI.Chatfilters = KarmaModuleLocal.ChatFilters;
		else
			KarmaChatSecondaryFallbackDefault("New version of feature 'chat markup' is active.");
		end

		-- going for filter function instead of hooking:
		KarmaModuleLocal.ChatFilters.Install();
		hooksecurefunc("ChatFrame_AddMessageEventFilter", Karma_SecureHook_ChatFrame_AddMessageEventFilter);
	end

	Karma_HookTip();
end

---
----
---

function	Karma_SecureHook_NotifyInspect(UnitID)
KarmaChatDebug("NotifyInspect-Hook: " .. Karma_NilToString(UnitID));
	if (KARMA_TalentInspect.StateCurrent >= 1) and
	   (KARMA_TalentInspect.StateCurrent <= 3) then
		local	Entry = {};
		Entry.Time = time();
		Entry.Unit = UnitID;
		tinsert(KARMA_TalentInspect.NotifyInspectCallList, Entry);
		KARMA_TalentInspect.NotifyInspectCallCount = KARMA_TalentInspect.NotifyInspectCallCount + 1;
	end
end


function	Karma_SecureHook_UnitPopup_OnClick()
	local	dropdownFrame = UIDROPDOWNMENU_INIT_MENU;
	local	ddF_Unit, ddF_Name, ddF_Server;
	if (dropdownFrame) then
		ddF_Unit   = dropdownFrame.unit;
		ddF_Name   = dropdownFrame.name;
		ddF_Server = dropdownFrame.server;
	end

-- KarmaChatDebug("Karma_SecureHook_UnitPopup_OnClick: this.value = " .. Karma_NilToString(this.value) .. ", ddF_Unit = " .. Karma_NilToString(ddF_Unit));

	if (this.value) and (type(this.value) == "string") then
		if (strsub(this.value, 1, 6) == "KARMA_") then
			local	sName, sServer;
			if (ddF_Unit ~= nil) then
				sName, sServer = UnitName(ddF_Unit);
				if (sServer and (sServer ~= "")) then
					sName = sName .. "@" .. sServer;
				end
			else
				KarmaChatDebug("No unit given... trying name/server = " .. (ddF_Name or "<nil>") .. " @ " .. (ddF_Server or "<nil>"));
				sName   = ddF_Name;
				sServer = ddF_Server;
				--[[
				if (sNAme == nil) and (dropdownFrame ~= nil) then
					local	k, v;
					for k, v in pairs(dropdownFrame) do
						if (type(v) == "string") then
							KarmaChatDebug("-> [" .. k .. "] = " .. v);
						else
							KarmaChatDebug("-> [" .. k .. "] = <" .. type(v) .. ">");
						end
					end
				end
				]]--
			end

			if (sName) then
				if (strsub(this.value, 7, 10) == "GIVE") then
					local	Num = tonumber(strsub(this.value, 11));
					if (Num) then
						local newval = Karma_IncreaseKarma(sName, true, Num);
						if (newval == nil) then
							KarmaChatDefault(KARMA_MSG_NOTONKARMASLIST1 .. sName .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_NOTONKARMASLIST2);
						end
					end
				elseif (strsub(this.value, 7, 10) == "TAKE") then
					local	Num = tonumber(strsub(this.value, 11));
					if (Num) then
						local newval = Karma_DecreaseKarma(sName, true, Num);
						if (newval == nil) then
							KarmaChatDefault(KARMA_MSG_NOTONKARMASLIST1 .. sName .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_NOTONKARMASLIST2);
						end
					end
				elseif (strsub(this.value, 7, 13) == "CHARADD") then
					local	args = {};
					args[2] = sName;
					Karma_SlashAdd(args);
				elseif (strsub(this.value, 7, 13) == "CHARDEL") then
					local	args = {};
					args[2] = sName;
					Karma_SlashRem(args);
				elseif (strsub(this.value, 7, 13) == "SELECT") then
					if (KARMA_CURRENTMEMBER ~= sName) then
						Karma_SetCurrentMember(sName);
						if (KARMA_CURRENTMEMBER == sName) then
							KarmaWindow_ScrollToCurrentMember();
							KarmaChatDefault("Currently selected member in Karma window set to >" .. sName .. "<");
						else
							KarmaChatDefault(KARMA_MSG_NOTONKARMASLIST1 .. sName .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_NOTONKARMASLIST2);
						end
					else
						KarmaWindow_ScrollToCurrentMember();
					end
				elseif (strsub(this.value, 7, 20) == "PUBNOTE_GUILD") then
					if (IsInGuild()) then
						if (GetNumGuildMembers() > 1) then
							local	args = {};
							args[2] = "$GUILD";
							args[3] = sName;
							-- "?p" - request
							Karma_SlashShareQuery(args, 3);
						else
							KarmaChatDefault("You're the only guild member online to query about " .. sName .. "... (At least that's what the UI claims. Did you open your social frame yet?)");
						end
					else
						KarmaChatDefault("You have to join a guild first to ask them about " .. sName .. "...");
					end
				elseif (strsub(this.value, 7, 22) == "PUBNOTE_CHANNEL") then
					local	args = {};
					args[2] = "#";
					args[3] = sName;
					-- "?p" - request
					Karma_SlashShareQuery(args, 3);
				end
			end

			KarmaWindow_Update();
		end
	end
end


function	Karma_SecureHook_FriendsFrame_OnShow()
	KARMA_FriendsFrameVisible = 1;
	if (Karma_WhoQueue[1] ~= nil) then
		local Msg = "Social frame openend. Stopping /who requests.";
		if (KARMA_FriendsFrameUnregistered == 1) then
			KARMA_FriendsFrameUnregistered = 0;
			FriendsFrame:RegisterEvent("WHO_LIST_UPDATE");
			Msg = Msg .. " Reregistering /who result check.";
		end;
		KarmaChatDefault(Msg);
	end;
end;

function	Karma_SecureHook_FriendsFrame_OnHide()
	KARMA_FriendsFrameVisible = 0;
	if (Karma_WhoQueue[1] ~= nil) then
		KarmaChatSecondary("Social frame closed. Resuming pending /who requests...");
	end;
end;


function	Karma_SecureHook_SendWho(sRequest)
	if (sRequest ~= KARMA_WhoRequest) then
		KARMA_WhoRequestIsMine = 0;
		Karma_Executing_Who = time() + 30;
		if (KARMA_FriendsFrameUnregistered == 1) then
			KARMA_FriendsFrameUnregistered = 0;
			FriendsFrame:RegisterEvent("WHO_LIST_UPDATE");
			KarmaChatDefault("Alternate /who request. Restoring update to /who frame. (You probably have to repeat your /who. Sorry!)");
			KarmaChatDebug("Alternate /who request: calltrace >>" .. debugstack());
		end
	end
end


function	Karma_SecureHook_InspectUnit(sUnit)
	KARMA_InspectByUser.At = time();
	KARMA_InspectByUser.Who = sUnit;
end

function	Karma_SecureHook_UIErrorsFrame_AddMessage(self, message, red, green, blue, alpha)
	-- UIErrorsFrame gets this one:
	-- FrameXML/GlobalStrings.lua:ERR_ZONE_EXPLORED = "Discovered: %s";
	-- ChatWindow gets this one: (or upper if no xp)
	-- FrameXML/GlobalStrings.lua:ERR_ZONE_EXPLORED_XP = "Discovered %s: %d experience gained";

	if (KarmaModuleLocal.PatternZoneExplored == nil) then
		KarmaModuleLocal.PatternZoneExplored = string.gsub(ERR_ZONE_EXPLORED, "(%%s)", "(.+)");
	end

	if (not alpha) then
		alpha = 1.0;
	end
	if (not red) then
		red = 1.0;
	end
	if (not green) then
		green = 1.0;
	end
	if (not blue) then
		blue = 1.0;
	end

	-- we want 1, 1, 0 - but that's floating point
	if (red < 0.99) or (green < 0.99) or (blue > 0.01) then
		return
	end

	KarmaChatDebug("SH(UIEF:AM) -> message: " .. message .. " (pattern <" .. KarmaModuleLocal.PatternZoneExplored .. ">) - alpha, rgb " .. alpha .. " - " .. red .. "/" .. green .. "/" .. blue);

	local	first, last, zone = strfind(message, KarmaModuleLocal.PatternZoneExplored);
	if (first and last and (zone == GetSubZoneText())) then
		-- check callstack?

		local	ZID = CommonRegionZoneAddCurrent();
		if (ZID) then
			local	globalZones = CommonZoneListGet();
			if (globalZones[ZID].Name ~= zone) then
				KarmaChatSecondary("Internal error, area <" .. zone .. "> not found. :(");
				KarmaChatDebug("SH(UIEF:AM) -> returned zone was <" .. (globalZones[ZID].Name or "nil") .. "> ?!");
				return
			end

			SetMapToCurrentZone();
			local posX, posY = GetPlayerMapPosition("player");
			if (posX and (posX ~= 0) and posY and (posY ~= 0)) then
				if (globalZones[ZID].PosX == nil) or (globalZones[ZID].PosY == nil) then
					globalZones[ZID].PosSumX = 0;
					globalZones[ZID].PosSumY = 0;
					globalZones[ZID].PosSumCnt = 0;

					globalZones[ZID].PosX = posX;
					globalZones[ZID].PosY = posY;
				end
				globalZones[ZID].PosSumX = globalZones[ZID].PosSumX + posX;
				globalZones[ZID].PosSumY = globalZones[ZID].PosSumX + posY;
				globalZones[ZID].PosSumCnt = globalZones[ZID].PosSumCnt + 1;

				globalZones[ZID].PosX = globalZones[ZID].PosSumX / globalZones[ZID].PosSumCnt;
				globalZones[ZID].PosY = globalZones[ZID].PosSumY / globalZones[ZID].PosSumCnt;
			end

			if (GetNumPartyMembers() > 0) or
                           (Karma_GetConfig(KARMA_CONFIG.RAID_TRACKALL) == 1) and (GetNumRaidMembers() > 0) then
				local	iMax, sBase;
				if (GetNumRaidMembers() > 0) then
					if (Karma_GetConfig(KARMA_CONFIG.RAID_TRACKALL) == 1) then
						iMax = GetNumRaidMembers();
						sBase = "raid";
					else
						KarmaChatSecondary("New area discovered: <" .. zone .. "> -- tracking in raid is OFF.");
						return
					end
				else
					iMax = GetNumPartyMembers();
					sBase = "party";
				end

				KarmaChatDefault("New area discovered: <" .. zone .. "> -- adding to group/raid.");

				-- we ignore distance here - all in the party shall count, even across the world
				local	i;
				for i = 1, iMax do
					local	sName, sServer = UnitName(sBase .. i);
					local	oMember = Karma_MemberList_GetObject(sName, sServer);
					if (oMember) then
						local	oMemPerChar = oMember[KARMA_DB_L5_RRFFM_CHARACTERS][UnitName("player")];
						KOH.TableInit(oMemPerChar, "EXPLORED_FIRST_TIME");
						oMemPerChar["EXPLORED_FIRST_TIME"]["Z" .. ZID] = time();
					end
				end
			else
				KarmaChatSecondary("New area discovered: <" .. zone .. "> -- would add to group if you were in one...");
			end
		end
	end
end

function	KarmaModuleLocal.ChatFilters.Install()
	local	sEvent, oFilter;
	for sEvent, oFilter in pairs(KarmaModuleLocal.ChatFilters) do
		if (type(oFilter) == "table") then
			ChatFrame_AddMessageEventFilter(sEvent, oFilter.fFilter);
		end
	end
end

function	Karma_SecureHook_ChatFrame_AddMessageEventFilter(event, func)
	-- if it is an event we track, and func is not ours, remove and reinsert us to get into last position again
	if (KarmaModuleLocal.ChatFilters[event]) then
		local	oFilter = KarmaModuleLocal.ChatFilters[event]; 
		if (oFilter.bRedo) then
			if (func ~= oFilter.fFilter) then
				ChatFrame_RemoveMessageEventFilter(event, oFilter.fFilter);
				ChatFrame_AddMessageEventFilter(event, oFilter.fFilter);
			end
		end
	end
end

--
---
--
function	Karma_HookTip()
	-- dead-ugly, thanks to Blizzard:
	-- - SetUnit is NOT called on character images themselves
	-- - UnitColor is NOT called on calls to SetUnit via XPerl (bars, animated head)
	-- - both fire on unitframe::title
	-- so, neither function hook suffices and sometimes *both* are called - well done, Blizzard!
	hooksecurefunc(GameTooltip, "SetUnit", Karma_SecureHook_GameTooltip_SetUnit);
	hooksecurefunc("GameTooltip_UnitColor", Karma_SecureHook_GameTooltip_UnitColor);

	-- hooks to support LFG/LFM notes
	hooksecurefunc(GameTooltip, "SetOwner", Karma_SecureHook_GameTooltip_SetOwner);
	hooksecurefunc(GameTooltip, "AddLine", Karma_SecureHook_GameTooltip_AddLine);

	if (type(LFMButton_OnClick) == "function") then
		-- not anymore in 3.3
		hooksecurefunc("LFMButton_OnClick", Karma_SecureHook_LFMFrameButton_OnClick);
	end
end

function	Karma_SecureHook_GameTooltip_SetUnit(self, sUnit)
	if (sUnit == nil) then
		sUnit = "<none>";
	else
		if (UnitExists(sUnit) and UnitIsPlayer(sUnit) and UnitIsFriend(sUnit, "player")) then
			if (KarmaModuleLocal.GameTooltipUnit ~= nil) then
				return
			end
			KarmaModuleLocal.GameTooltipUnit = sUnit .. "::" .. UnitName(sUnit);

			KarmaChatDebug("KSH_GTT:SU(" .. sUnit .. ")");
			local	TT_Added = Karma_AddTip(sUnit);
			if (TT_Added) then
				GameTooltip:Show();

				-- the color gets lost for reasons completely unknown (UnitColor-Hook doesn't need this!)
				-- => refresh it
				getglobal(self:GetName().."TextLeft1"):SetTextColor(GameTooltip_UnitColor(sUnit, true));
			end
		end
	end
--	KarmaChatDebug("SH(GT:SU) -> unit " .. sUnit);
end

function	Karma_SecureHook_GameTooltip_UnitColor(sUnit, bSelfCall)
	if (bSelfCall) then
		-- call from GameTooltip_SetUnit - hook above
		return
	end

	if (UnitIsPlayer(sUnit) and UnitIsFriend(sUnit, "player")) then
		if (KarmaModuleLocal.GameTooltipUnit ~= nil) then
			return
		end
		KarmaModuleLocal.GameTooltipUnit = sUnit .. "::" .. UnitName(sUnit);

		-- KarmaChatDebug("KSH_GTT:UC(" .. sUnit .. ")");
		local	TT_Added = Karma_AddTip(sUnit);
		if (TT_Added) then
			GameTooltip:Show();
		end
	end
end

local	KARMA_GameTooltipLFM = {
			LFMFrameButtonXIsOwner = 0,
			NameCount = 0,
			Name = "",
			Notes = ""
	};

function	Karma_SecureHook_GameTooltip_SetOwner(self, oFrame, sAnchor, dx, dy)
	KarmaModuleLocal.GameTooltipUnit = nil;

	local	sFrame;
	if ((oFrame) and (type(oFrame) == "table") and
		(oFrame.GetName) and (type(oFrame.GetName) == "function")) then
		sFrame = oFrame:GetName();
	end
	-- strange AddOns call this with a oFrame object that returns *nil* to GetName()! (WIM)
	if (sFrame == nil) or (sFrame == "") then
		sFrame = "<none>";
	end

	if (sAnchor == nil) then
		sAnchor = "<none>";
	end

--	KarmaChatDebug("SH(GT:SO) -> frame " .. sFrame .. ", anchor " .. sAnchor);
	if (strsub(sFrame, 1, 14) == "LFMFrameButton") then
		KARMA_GameTooltipLFM.LFMFrameButtonXIsOwner = 1;
		KARMA_GameTooltipLFM.NameCount = 0;
		KARMA_GameTooltipLFM.Name = "";
		KARMA_GameTooltipLFM.Notes = "";
		KARMA_GameTooltipLFM.Texture = oFrame.partyMembers and (oFrame.partyMembers > 0);
	else
		KARMA_GameTooltipLFM.LFMFrameButtonXIsOwner = 0;
	end
end

function	Karma_SecureHook_GameTooltip_AddLine(self, sText, red, green, blue, bWrap)
	if (sText == nil) or (sText == "") then
--		KarmaChatDebug("SH(GT:AL) -> line <empty>");
		return;
	end

--	KarmaChatDebug("SH(GT:AL) -> line " .. sText .. ", first byte " .. string.byte(sText, 1));

	-- the zones and note of the player are starting with a newline
	local	iByte = string.byte(sText, 1);
	if (KARMA_GameTooltipLFM.LFMFrameButtonXIsOwner == 1) and (iByte ~= 10) and (iByte ~= 32) then
		local	iMinusPos = strfind(sText, '-', 1, true);
		if (iMinusPos) then
			local	iSpacePos = strfind(sText, ' ', 1, true);
			if (iSpacePos) then
				local	sName = strsub(sText, 1, iSpacePos - 1);
--				KarmaChatDebug("SH(GT:AL) -> -> name " .. sName);
				local	oMember = Karma_MemberList_GetObject(sName);
				if (oMember) then
					local	iKarma = Karma_MemberObject_GetKarmaModified(oMember);
					if (iKarma) then
						local	sInfo = "";
						local	sKarma = Karma_MemberObject_GetKarmaWithModifiers(oMember);
						if (iKarma ~= 50) then
							sInfo = sInfo .. " " .. sKarma;
						end
						local	sNotes = Karma_MemberObject_GetNotes(oMember);
						if (sNotes and (sNotes ~= "")) then
							sInfo = sInfo .. " (+ Note)";
						end

						if (sInfo ~= "") then
							KARMA_GameTooltipLFM.NameCount = KARMA_GameTooltipLFM.NameCount + 1;
							KARMA_GameTooltipLFM.Name = sName;
							local	sExtract = KarmaModuleLocal.Helper.ExtractHeader(sNotes);
							KARMA_GameTooltipLFM.Notes = KARMA_GameTooltipLFM.Notes .. "\n" .. KOH.Name2Clickable(sName)
								.. "{" .. Karma_MemberObject_GetKarmaModifiedForListWithColors(oMember) .. "}:\n" .. sExtract;

							if (Karma_GetConfig(KARMA_CONFIG.TOOLTIP_LFMADDKARMA) == 1) then
								--[[
								local	KRed, KGreen, KBlue = Karma_Karma2Color(math.min(100, iKarma));
								if (KARMA_GameTooltipLFM.Texture) then
									-- add bogus texture (as in FrameXML/LFGFrame.lua)
									-- this has to be in kinda reverse order compared to there:
									-- the 'outside' AddTexture matches our line, so we match the already added line we got tripped from
									GameTooltip:AddTexture("");
								end
								GameTooltip:AddDoubleLine("", "Karma: " .. sInfo, nil, nil, nil, KRed, KGreen, KBlue);
								-- GameTooltip:AddLine("-- Karma: " .. sInfo, KRed, KGreen, KBlue);
								]]--

								local	iLine = GameTooltip:NumLines();
								local	oText = _G["GameTooltipTextLeft" .. iLine];
								if (oText) then
									local	sText = oText:GetText();
									local	iPos = strfind(sText, " ");
									local	sInfo = KarmaModuleLocal.ChatFilters.MarkupSender("", oMember);
									-- there is no color given, so we overwrite with bright yellow in the hopes that the common yellow is used
									sText = "|cFFFFFF40" .. strsub(sText, 1, iPos - 1) .. "|r" .. sInfo .. strsub(sText, iPos);
									oText:SetText(sText);
								end
							end

--							KarmaChatDebug("SH(GT:AL) -> -> -> Info " .. sInfo);
						end
					end
				end
			end
		end
	end
end

function	Karma_SecureHook_LFMFrameButton_OnClick()
	if (KARMA_GameTooltipLFM.Notes ~= "") then
		KarmaChatSecondary(KARMA_GameTooltipLFM.Notes);
		if (KARMA_GameTooltipLFM.NameCount == 1) then
			local	bShiftPressed = IsShiftKeyDown();
			if (bShiftPressed) then
				Karma_SetCurrentMember(KARMA_GameTooltipLFM.Name);
			end
		end
	end
end

---
----
---
function	Karma_InspectTalentReady()
	if (KARMA_TalentInspect.StateCurrent >= 1) and
	   (KARMA_TalentInspect.StateCurrent <= 3) then
		local	Entry = {};
		Entry["Time"] = time();

KarmaChatDebug("Talents: time = " .. date("%H:%M:%S", time()));

		local	iNumSpecs = 1;
		local	_, _, _, iTOC = GetBuildInfo();
		if (iTOC >= 30100) then
			iNumSpecs = GetNumTalentGroups(true);
		end

		local	iNumTabs = GetNumTalentTabs(true);
		local	iSpec, iTab, sName, sIconTexture, iPointsSpent, sBackground, sTab;
		for iSpec = 1, iNumSpecs do
			for iTab = 1, iNumTabs do
				sName, sIconTexture, iPointsSpent, sBackground = GetTalentTabInfo(iTab, true, false, iSpec);
				sTab = "T_" .. tostring(iSpec) .. "_" .. tostring(iTab);
				Entry[sTab] = {};
				Entry[sTab].Name = sName;
				Entry[sTab].Points = iPointsSpent;
				KarmaChatDebug("Spec[" .. iSpec .. "].Talents[" .. sTab .. "] = " .. sName .. " has " .. iPointsSpent .. " points.");
			end
		end

		tinsert(KARMA_TalentInspect.TalentsReadyCallList, Entry);
		KARMA_TalentInspect.TalentsReadyCallCount = KARMA_TalentInspect.TalentsReadyCallCount + 1;
	end
end

function	Karma_AutofetchTalents()
	-- 4 states:
	-- state 0: if queue empty, do nothing, else reset states and switch to state 1
	-- state 1: register event, wait 10 seconds
	-- state 2: send NotifyInspect, switch to state 3
	-- state 3: wait for first reply + 10 seconds, then switch to state 4
	-- state 4: unregister event, if *one* NotifyInspect and *one* InspectTalentReady* then accept scan, go to state 0

	if (DebugMsgState == nil) then
		DebugMsgState = KARMA_TalentInspect.StateCurrent;
	end
	if (DebugMsgState ~= KARMA_TalentInspect.StateCurrent) then
		KarmaChatDebug("Karma_AutofetchTalents: [" .. tostring(time() % 60) .. "] state " .. Karma_NilToString(DebugMsgState) .. " => " ..  Karma_NilToString(KARMA_TalentInspect.StateCurrent));
		DebugMsgState = KARMA_TalentInspect.StateCurrent;
	end

	-- state 0: if queue empty, do nothing, else switch to state 0
	if (KARMA_TalentInspect.StateCurrent == 0) then
		-- default case: nothing to do
		if (KARMA_TalentInspect.RequiredCount == 0) then
			return
		end

		if (KARMA_InspectByUser.At ~= nil) then
			if (time() - KARMA_InspectByUser.At < 120) then
				return
			end

			KARMA_InspectByUser.At = nil;
		end

		if (KARMA_TalentInspect.AutofetchConfigCache == nil) then
			KARMA_TalentInspect.AutofetchConfigCache = Karma_GetConfig(KARMA_CONFIG.TALENTS_AUTOFETCH);
			if (KARMA_TalentInspect.AutofetchConfigCache == nil) then
				KARMA_TalentInspect.AutofetchConfigCache = 0;
				Karma_SetConfig(KARMA_CONFIG.TALENTS_AUTOFETCH, KARMA_TalentInspect.AutofetchConfigCache)
				KarmaChatSecondary("Talent scanning in background: setting default state of 'disabled'. Enable with '" .. KARMA_CMDSELF .. " autochecktalents'.");
			end
		end

		if (KARMA_TalentInspect.AutofetchConfigCache ~= 1) then
			return
		end

		-- ok, select a unit, switch to state 1
		local	sUnit, sName, sChoiceUnit, sChoiceName;
		for sUnit, sName in pairs(KARMA_TalentInspect.RequiredList) do
			if (CheckInteractDistance(sUnit, 1) == 1) then
				sChoiceUnit = sUnit;
				sChoiceName = sName;
			end
		end

		if (sChoiceUnit) then
			local	sUnit2Name, sUnit2Server;
			if (UnitIsPlayer(sChoiceUnit)) then
				sUnit2Name, sUnit2Server = UnitName(sChoiceUnit);
				if (sUnit2Server) and (sUnit2Server ~= "") then
					sUnit2Name = sUnit2Name .. "@" .. sUnit2Server;
				end
			end
			if (sUnit2Name == nil) or (sUnit2Name ~= sChoiceName) then
KarmaChatDebug("Unit(" .. sChoiceUnit .. ") changed, removing from talent autofetch queue...");
				KARMA_TalentInspect.RequiredList[sChoiceUnit] = nil;
				sChoiceUnit = nil;

				local	i, key, value;
				i = 0;
				for key, value in pairs(KARMA_TalentInspect.RequiredList) do
					i = i + 1;
				end
				KARMA_TalentInspect.RequiredCount = i;
			end
		end

		if (sChoiceUnit) then
			KARMA_TalentInspect.RequestedUnit   = sChoiceUnit;
			KARMA_TalentInspect.RequestedMember = sChoiceName;
			KARMA_TalentInspect.RequestedGUID   = UnitGUID(sChoiceUnit);
KarmaChatDebug("Selected Unit(" .. KARMA_TalentInspect.RequestedUnit .. ") = " .. KARMA_TalentInspect.RequestedMember);

			KARMA_TalentInspect.State1Time = nil;
			KARMA_TalentInspect.State2Time = nil;
			KARMA_TalentInspect.State3Time = nil;
			KARMA_TalentInspect.State4Time = nil;
	
			KARMA_TalentInspect.NotifyInspectCallCount = 0;
			KARMA_TalentInspect.NotifyInspectCallList = {};
			KARMA_TalentInspect.TalentsReadyCallCount = 0;
			KARMA_TalentInspect.TalentsReadyCallList = {};
	
			KARMA_TalentInspect.StateCurrent = 1;

			-- just to be sure...
			ClearInspectPlayer();
		end
	elseif (KARMA_TalentInspect.StateCurrent == 1) then
		if (KARMA_TalentInspect.State1Time == nil) then
			Karma:RegisterEvent("INSPECT_TALENT_READY");

			KARMA_TalentInspect.State1Time = time();
		elseif ((time() - KARMA_TalentInspect.State1Time) > 8) then
			KARMA_TalentInspect.StateCurrent = 2;
		end
	elseif (KARMA_TalentInspect.StateCurrent == 2) then
		KARMA_TalentInspect.State2Time = time();
		if  (KARMA_InspectByUser.At == nil) and
			(UnitIsPlayer(KARMA_TalentInspect.RequestedUnit) and
			(KARMA_TalentInspect.RequestedGUID == UnitGUID(KARMA_TalentInspect.RequestedUnit))) then
			-- CanInspect(<unit>, <true: show error message>)
			if (CanInspect(KARMA_TalentInspect.RequestedUnit)) then
				NotifyInspect(KARMA_TalentInspect.RequestedUnit);
KarmaChatDebug("Sent scan request for <" .. KARMA_TalentInspect.RequestedUnit .. ">");
			else
KarmaChatDebug("Failed to send scan request for <" .. KARMA_TalentInspect.RequestedUnit .. ">");
			end
		else
			KARMA_TalentInspect.RequestedGUID = nil;
KarmaChatDebug("Unit is meanwhile changed or invalid: " .. KARMA_TalentInspect.RequestedUnit);
		end

		KARMA_TalentInspect.StateCurrent = 3;
	elseif (KARMA_TalentInspect.StateCurrent == 3) then
		if (KARMA_TalentInspect.State3Time == nil) then
			if (KARMA_TalentInspect.TalentsReadyCallCount == 0) then
				if ((time() - KARMA_TalentInspect.State2Time) < 12) then
					return
				end
			end

			KARMA_TalentInspect.State3Time = time();
		elseif ((time() - KARMA_TalentInspect.State3Time) > 4) then
			KARMA_TalentInspect.StateCurrent = 4;
		end
	elseif (KARMA_TalentInspect.StateCurrent == 4) then
		if (KARMA_TalentInspect.State4Time == nil) then
			Karma:UnregisterEvent("INSPECT_TALENT_READY");

			local	bSuccess, bRecount;
			if (KARMA_TalentInspect.NotifyInspectCallCount == 1) and
			   (KARMA_TalentInspect.TalentsReadyCallCount == 1) and
			   UnitIsPlayer(KARMA_TalentInspect.RequestedUnit) and
			   (KARMA_TalentInspect.RequestedGUID == UnitGUID(KARMA_TalentInspect.RequestedUnit)) then
KarmaChatDebug("Got definite scan: Unit(" .. KARMA_TalentInspect.RequestedUnit .. ") = " .. KARMA_TalentInspect.RequestedMember);
				-- got result, if valid member, move the result into the tree
				local	oMember = Karma_MemberList_GetObject(KARMA_TalentInspect.RequestedMember);
				if (oMember) then
					oMember[KARMA_DB_L5_RRFFM_TALENTTREE] = KARMA_TalentInspect.TalentsReadyCallList[1];
					KARMA_TalentInspect.TalentsReadyCallList = {};
					bSuccess = true;
					KarmaChatSecondary("Successfully updated talents on " .. KARMA_TalentInspect.RequestedMember .. ".");
				end

				if (KARMA_TalentInspect.RequiredList[KARMA_TalentInspect.RequestedUnit] == KARMA_TalentInspect.RequestedMember) then
					KARMA_TalentInspect.RequiredList[KARMA_TalentInspect.RequestedUnit] = nil;
					bRecount = true;
				end
			else
local sReason = "";
if (KARMA_TalentInspect.NotifyInspectCallCount ~= 1) then
	sReason = sReason .. " (ICC != 1)";
end
if (KARMA_TalentInspect.TalentsReadyCallCount ~= 1) then
	sReason = sReason .. " (RCC != 1)";
end
KarmaChatDebug("Failed to get a definite scan: " .. KARMA_TalentInspect.RequestedUnit .. " <-" .. sReason);
				-- remove from queue if it changed or went invalid
				local	sName, sServer;
				if (UnitIsPlayer(KARMA_TalentInspect.RequestedUnit)) then
					sName, sServer = UnitName(KARMA_TalentInspect.RequestedUnit);
					if (sServer) and (sServer ~= "") then
						sName = sName .. "@" .. sServer;
					end
					if (KARMA_TalentInspect.RequiredList[KARMA_TalentInspect.RequestedUnit] ~= sName) then
KarmaChatDebug("Unit changed: Unit(" .. KARMA_TalentInspect.RequestedUnit .. ") {" .. KARMA_TalentInspect.RequiredList[KARMA_TalentInspect.RequestedUnit] .. "} -> {" .. sName .. "}");
						KARMA_TalentInspect.RequiredList[KARMA_TalentInspect.RequestedUnit] = nil;
						bRecount = true;
					end
				else
KarmaChatDebug("Unit went invalid: Unit(" .. KARMA_TalentInspect.RequestedUnit .. ") != " .. KARMA_TalentInspect.RequiredList[KARMA_TalentInspect.RequestedUnit]);
					KARMA_TalentInspect.RequiredList[KARMA_TalentInspect.RequestedUnit] = nil;
					bRecount = true;
				end
			end

			if (bRecount) then
				local	i, key, value;
				i = 0;
				for key, value in pairs(KARMA_TalentInspect.RequiredList) do
					i = i + 1;
				end
				KARMA_TalentInspect.RequiredCount = i;
			end

			if (bSuccess) then
				KARMA_TalentInspect.State4Time = time() - 15;
			else
				-- failed: increase counter, message on every 10th failure
				if (KARMA_TalentInspect.RequestedMember) then
					if (KARMA_OtherInfos[KARMA_TalentInspect.RequestedMember] == nil) then
						KARMA_OtherInfos[KARMA_TalentInspect.RequestedMember] = {};
					end

					local	iTIFCount = KARMA_OtherInfos[KARMA_TalentInspect.RequestedMember].TalentInspectFailed;
					if (iTIFCount == nil) then
						iTIFCount = 1;
					else
						iTIFCount = iTIFCount + 1;
						if ((iTIFCount % 10) == 0) then
							KarmaChatSecondaryFallbackDefault("Failed the " .. iTIFCount .. "th time to fetch talents for player " .. KARMA_TalentInspect.RequestedMember .. "...");
						end
					end
					KARMA_OtherInfos[KARMA_TalentInspect.RequestedMember].TalentInspectFailed = iTIFCount;
				end
				KARMA_TalentInspect.State4Time = time();
			end

			KARMA_TalentInspect.RequestedUnit   = nil;
			KARMA_TalentInspect.RequestedMember = nil;
			KARMA_TalentInspect.RequestedGUID   = nil;

		elseif ((time() - KARMA_TalentInspect.State4Time) > 20) then
			KARMA_TalentInspect.StateCurrent = 0;
		end
	end
end

function	Karma_AutofetchTalents_Status()
	KarmaChatDebug("Karma_AutofetchTalents: [" .. tostring(time() % 60) .. "] state " .. Karma_NilToString(DebugMsgState) .. " => " ..  Karma_NilToString(KARMA_TalentInspect.StateCurrent));

	local	key, value;
	for key, value in pairs(KARMA_TalentInspect) do
		if (type(value) == "table") then
			KarmaChatDebug("-- " .. key .. " => <table>");
		else
			KarmaChatDebug("-- " .. key .. " => " .. value);
		end
	end

	KarmaChatDebug("***");
end

function	Karma_AddToTalentQueue(sUnit)
	if (CanInspect(sUnit, true)) then
		if (KARMA_TalentInspect.RequiredList == nil) then
			KARMA_TalentInspect.RequiredList = {};
		end

		local	sName, sServer = UnitName(sUnit);
		if (sServer and (sServer ~= "")) then
			sName = sName .. "@" .. sServer;
		end
		KARMA_TalentInspect.RequiredList[sUnit] = sName;
		KARMA_TalentInspect.RequiredCount = KARMA_TalentInspect.RequiredCount + 1;
	end
end

function	Karma_TimeKarma_Status(sName, iSet)
	if (sName == nil) then
		if (iSet) and (type(iSet) == "number") then
			Karma_SetConfig(KARMA_CONFIG.TIME_KARMA_DEFAULT, iSet);
		end
		KarmaChatDebug("Time->Karma global setting: " .. Karma_GetConfig(KARMA_CONFIG.TIME_KARMA_DEFAULT));
	else
		local	oMember = Karma_MemberList_GetObject(sName);
		if (oMember == nil) then
			KarmaChatDebug("Not a member: " .. Karma_NilToString(sName));
		else
			if (iSet) and (type(iSet) == "number") then
				oMember[KARMA_DB_L5_RRFFM_KARMA_TIME] = iSet;
			end
			KarmaChatDebug("Time->Karma: " .. oMember[KARMA_DB_L5_RRFFM_KARMA_TIME]);
		end
	end
end

--------------------
-- Slash Commands --
--------------------
function	Karma_InitSlash()
	SLASH_KARMA1 = KARMA_CMDSELF;
	SLASH_KARMA2 = "/kar";
	SlashCmdList["KARMA"] = function(argfield, argcnt)
		Karma_SlashCommandHandler(argfield, argcnt);
	end

	KSLASH = {
		window = Karma_ToggleWindow,
		win = Karma_ToggleWindow,
		addmember = Karma_SlashAdd,
		add = Karma_SlashAdd,
		addguild = Karma_SlashAddGuild,
		ignore = Karma_SlashIgn,
		ign = Karma_SlashIgn,
		remove = Karma_SlashRem,
		rem = Karma_SlashRem,
		give = Karma_SlashGive,
		take = Karma_SlashTake,
		sortby = Karma_SlashSort,
		colorby = Karma_SlashCol,
		colourby = Karma_SlashCol,
		options  = Karma_SlashOpt,
		opt = Karma_SlashOpt,
		autoignore = Karma_SlashAuto,
		questcache = Karma_SlashCache,
		clean = Karma_SlashClean,
		cleanpvp = Karma_SlashCleanPvp,
		karmatips = Karma_SlashKarmaTips,
		notetips = Karma_SlashNoteTips,
		update = Karma_SlashUpdate,
		export = Karma_SlashExport,
		import = Karma_SlashImport,
		transport = Karma_SlashTransport,
		help = Karma_SlashHelp,
		filter = Karma_SlashFilter,
		qcachewarn = Karma_SlashQCacheWarn,
		checkclass = Karma_SlashCheckClassOnline,
		checkchannel = Karma_SlashCheckOnlineInChannel,
		checkallclasses = Karma_SlashCheckAllClassesOnline,
		checkguild = Karma_SlashCheckGuild,
		showonline = Karma_SlashShowOnline,
		altadd = Karma_SlashAltAdd,
		altrem = Karma_SlashAltRemove,
		altlist = Karma_SlashAltList,
		altcheck = Karma_SlashAltCheck,
		resetgui = Karma_SlashResetGUI,
		pausequeuedwhos = Karma_SlashPauseWho,				-- TODO: needs help entry and *code*
		autochecktalents = Karma_SlashAutocheckTalents,
		skillmodel = Karma_SlashSkillModel,
		mouseover = Karma_MouseOverUnitLog_Status,
		xinfo = Karma_CrossFactionInfo,
		xnote = Karma_CrossFactionNote,
		xupdate = Karma_CrossFactionUpdate,
		forcenew = Karma_MemberForceNew,
		forceupdate = Karma_MemberForceUpdate,
		forcecheck = Karma_MemberForceCheck,
		exchangeallow = Karma_ExchangeAllow,
		exchangerequest = Karma_ExchangeRequest,
		exchangestatus = Karma_ExchangeStatus,
		exchangeupdate = Karma_ExchangeUpdate,
		exchangetrust = Karma_ExchangeTrust,
		cql = Karma_SlashCQList,
		pql = Karma_SlashPQList,
		wql = Karma_SlashWQList,
		pubnoteset = Karma_SlashPubNoteSet,
		pubnoteget = Karma_SlashPubNoteGet,
		pubnoteclear = Karma_SlashPubNoteClear,
		wim_module = Karma_SlashWIMModule,
		shareconfig = Karma_SlashShareConfig,
		sharequery = Karma_SlashShareQuery,
		raid = Karma_SlashRaid,
		dbsparse = Karma_SlashDBSparse,
		tracking = Karma_SlashTracking
	};
end

function	Karma_SlashCommandHandler(msg, bSilent)
	local	args = {};
	local	iCounter = 0;
	local	i = 0;

	-- Split commands
	-- %w+: alphanumeric chars, does not include e.g. accented letters
	-- => only sufficient for command, but not for character names
	-- %S+: all but space chars
	local	w;
	for w in string.gmatch(msg, "%S+") do
		iCounter = iCounter+1;
		args[iCounter] = w;
	end

	if (KSLASH[args[1]]) then
		KSLASH[args[1]](args, iCounter);
	elseif (bSilent ~= true) then
		if args[1] then
			KarmaChatDefault(KARMA_CMDLINE_CMDUNKNOWN_PRE .. args[1].. KARMA_CMDLINE_CMDUNKNOWN_POST);
		end

		local	sSecondary = KarmaObj.UIChat.SecondaryNameGet();
		if (sSecondary ~= nil) then
			KarmaChatDefault(KARMA_MSG_HELPINSECONDWINDOW .. " [" .. sSecondary .. "]");
		end

		local	helpindex, helpline, versionpos;
		for helpindex, helpline in pairs(KARMA_CMDLINE_HELP_SHORT) do
			if (helpindex == 1) then
				versionpos = strfind(helpline, "***", 1, true);
				if (versionpos) then
					helpline = strsub(helpline, 1, versionpos - 1) .. KARMA_VERSION_TEXT .. strsub(helpline, versionpos + 3);
				end
			end
			KarmaChatSecondaryFallbackDefault("|" .. KARMA_CMDLINE_HELP_COLOR1 .. "-- " .. helpline, 1);
		end
	end
end

function Karma_SlashHelp(args)
	if (args[2] == "quick") then
		local	key, value, unsorted;
		local	lines = {};
		unsorted = "Commands (unsorted): ==[";
		for key, value in pairs(KSLASH) do
			if (strlen(unsorted) + strlen(key) > 300) then
				KarmaChatDebug(unsorted);
				unsorted = "(cont'd)";
			end
			unsorted = unsorted .. " " .. key;
			tinsert(lines, key);
		end
		KarmaChatDebug(unsorted .. " ]==");
		KOH.GenericSort(lines);
		local	line = "";
		for key, value in pairs(lines) do
			line = line .. " " .. value;
		end
		KarmaChatDefault(KARMA_MSG_HELPCOMMANDLIST .. line);
		return;
	end;

	local	sSecondary = KarmaObj.UIChat.SecondaryNameGet();
	if (sSecondary ~= nil) then
		KarmaChatDefault(KARMA_MSG_HELPINSECONDWINDOW .. " [" .. sSecondary .. "]");
	end

	local	sGroup;
	if ((args[2] ~= nil) and (args[2] ~= "")) then
		sGroup = strupper(args[2]);
		if ((sGroup ~= "LONG") and (sGroup ~= "FULL")) then
			local	oGroup = getglobal("KARMA_CMDLINE_HELP_" .. sGroup);
			if (type(oGroup) == "table") then
				local	helpkeysub, helplinesub;
				for helpkeysub, helplinesub in pairs(oGroup) do
					KarmaChatSecondaryFallbackDefault("|" .. KARMA_CMDLINE_HELP_COLOR1 .. "-- " .. helplinesub, 1);
				end

				return
			end
		end

		if (sGroup ~= "ALL") then
			KarmaChatSecondaryFallbackDefault("Unrecognized command group: " .. args[2] .. "; only displaying regular help.");
		end
	end

	local	oHelpGroups = KARMA_CMDLINE_HELPMETA_LONG;
	if (KARMA_CMDLINE_HELP_LONG ~= nil) then
		-- legacy
		oHelpGroups = KARMA_CMDLINE_HELPMETA_LEGACY;
	elseif (sGroup == "ALL") then
		oHelpGroups = KARMA_CMDLINE_HELPMETA_FULL;
	end

	local	helpindex, helpline, versionpos;
	for helpindex, helpline in pairs(KARMA_CMDLINE_HELP_SHORT) do
		if (helpindex == 1) then
			versionpos = strfind(helpline, "***", 1, true);
			if (versionpos) then
				helpline = strsub(helpline, 1, versionpos - 1) .. KARMA_VERSION_TEXT .. strsub(helpline, versionpos + 3);
			end
		end
		KarmaChatSecondaryFallbackDefault("|" .. KARMA_CMDLINE_HELP_COLOR1 .. "-- " .. helpline, 1);
	end

	for helpindex, helpline in pairs(oHelpGroups) do
		local	oGroup = getglobal("KARMA_CMDLINE_HELP_" .. helpline);
		if (type(oGroup) == "table") then
			local	helpkeysub, helplinesub;
			for helpkeysub, helplinesub in pairs(oGroup) do
				KarmaChatSecondaryFallbackDefault("|" .. KARMA_CMDLINE_HELP_COLOR1 .. "-- " .. helplinesub, 1);
			end
		end
	end
end

function	Karma_SlashCQList()
	local	sMsg = "Length of command queue at this time: " .. getn(Karma_CommandQueue) .. " commands pending.";
	local	TimeNow = GetTime();
	if (KarmaModuleLocal.Timers.CmdQ > TimeNow) then
		sMsg = sMsg .. " Next command in " .. format("%.2f", KarmaModuleLocal.Timers.CmdQ - TimeNow) .. " seconds.";
	end
	KarmaChatSecondary(sMsg);
	for i = 1, getn(Karma_CommandQueue) do
		KarmaChatSecondary("[" .. i .. "] " .. Karma_CommandQueue[i].sName);
	end
end

function	Karma_SlashPQList()
	local	sMsg = "Length of cron queue at this time: " .. getn(Karma_CronQueue) .. " sets pending.";
	KarmaChatSecondary(sMsg);
	for i = 1, getn(Karma_CronQueue) do
		local	sName = "<unknown!!>";
		if ((Karma_CronQueue[i].CmdList ~= nil) and (Karma_CronQueue[i].CmdList[1] ~= nil)) then
			sName = Karma_CronQueue[i].CmdList[1].sName;
		end
		if (sName == nil) then
			sName = "<unknown??>";
		end
		KarmaChatSecondary("[" .. i .. "] @ [" .. date("%H:%M:%S", time() + (Karma_CronQueue[i].At - GetTime())) .. "] " .. sName);
	end
end

function	Karma_SlashWQList()
	KarmaChatSecondary("Length of /who queue at this time: " .. getn(Karma_WhoQueue) .. " commands pending.");
	for i = 1, getn(Karma_WhoQueue) do
		KarmaChatSecondary("[" .. i .. "] " .. Karma_WhoQueue[i].text);
	end
end

function Karma_SlashAdd(args)
	if (args[2] == nil) then
		local	sName, sServer = UnitName("target");
		if (sServer and (sServer ~= "")) then
			sName = sName .. "@" .. sServer;
		end
		args[2] = sName;
		if (args[2]) then
			KarmaChatSecondary("No name on command line... using current target <" .. args[2] .. ">.");
		end
	end

	if (args[2] ~= nil and args[2] ~= "") then
		Karma_Command_AddMember_Insert(args);
	end
end

function Karma_SlashAddGuild(args, iCnt)
	if (args[2] == nil) then
		KarmaChatSecondary("No name to add on command line!");
		return
	end

	local	sGuild, i = args[2];
	for	i = 3, iCnt do
		sGuild = sGuild .. " " .. args[i];
	end

	local	sGuildPure = sGuild;
	sGuild = "<" .. sGuild .. ">";
	local	guildobj = Karma_MemberList_GetObject(sGuild);
	if (guildobj == nil) then
		Karma_MemberList_Add(sGuild);
		Karma_MemberList_Update(sGuild, nil, nil, nil, sGuildPure);

		guildobj = Karma_MemberList_GetObject(sGuild);
		guildobj.Meta = "GUILD";

		KarmaChatDebug("Added meta 'guild' " .. sGuild .. ".");
	else
		KarmaChatDebug("Found meta 'guild' " .. sGuild .. ", not added again.");
	end
end

function Karma_SlashIgn(args)
	if (args[2] == nil) then
		local	sName, sServer = UnitName("target");
		if (sServer and (sServer ~= "")) then
			sName = sName .. "@" .. sServer;
		end
		args[2] = sName;
		if (args[2]) then
			KarmaChatSecondary("No name on command line... using current target <" .. args[2] .. ">.");
		end
	end

	if (args[2] ~= nil and args[2] ~= "") then
		Karma_Command_AddIgnore_Insert(args);
	end
end

function Karma_SlashRem(args)
	if (args[2] == nil) then
		KarmaChatDefault(KARMA_MSG_COMMAND_MISSINGARG .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_PLAYER_REQARG);
		return
	end

	if (args[2] == KARMA_CURRENTMEMBER) then
		Karma_SetCurrentMember(nil);
	end;

	Karma_MemberList_ResetMemberNamesCache();
	Karma_MemberList_Remove(args[2]);
	KarmaWindow_UpdateMemberList();

	KarmaChatDefault(args[2] .. KARMA_MSG_REMOVE_COMPLETED);
end

function Karma_SlashGive(args)
	if (args[2] == nil) then
		local	sName, sServer = UnitName("target");
		if (sServer and (sServer ~= "")) then
			sName = sName .. "@" .. sServer;
		end
		args[2] = sName;
		if (args[2]) then
			KarmaChatSecondary("No name on command line... using current target <" .. args[2] .. ">.");
		end
	end

	if (args[2] ~= nil) then
		Karma_IncreaseKarma(args[2], false, 3);
		Karma_SetCurrentMember(args[2]);
	else
		KarmaChatDefault(KARMA_MSG_COMMAND .. args[1] .. KARMA_MSG_COMMAND_NEEDTARGETORARGUMENT);
	end
end

function Karma_SlashTake(args)
	if (args[2] == nil) then
		local	sName, sServer = UnitName("target");
		if (sServer and (sServer ~= "")) then
			sName = sName .. "@" .. sServer;
		end
		args[2] = sName;
		if (args[2]) then
			KarmaChatSecondary("No name on command line... using current target <" .. args[2] .. ">.");
		end
	end

	if (args[2] ~= nil) then
		Karma_DecreaseKarma(args[2], false, 3);
		Karma_SetCurrentMember(args[2]);
	else
		KarmaChatDefault(KARMA_MSG_COMMAND .. args[1] .. KARMA_MSG_COMMAND_NEEDTARGETORARGUMENT);
	end
end

function Karma_SlashSort(args, iCounter)
	if (iCounter >= 2) then
		if (args[2] == "sName") then
			Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_NAME);
		elseif (args[2] == "xp" or args[2] == "exp") then
			Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_XP);
		elseif (args[2] == "karma") then
			Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_KARMA);
		elseif (args[2] == "played") then
			Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_PLAYED);
		elseif (args[2] == "class") then
			Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_CLASS);
		elseif (args[2] == "joined") then
			Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_JOINED);
		elseif (args[2] == "talent") then
			Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_TALENT);
		elseif (args[2] == "guildtop") then
			Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_TOP);
		elseif (args[2] == "guildbottom") then
			Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_BOTTOM);
		end
		KarmaWindow_Update();
	end
end

function Karma_SlashCol(args, iCounter)
	if (iCounter >= 2) then
		if (args[2] == "xp" or args[2] == "exp") then
			Karma_SetConfig(KARMA_CONFIG.COLORFUNCTION, KARMA_CONFIG.COLORFUNCTION_TYPE_XP);
		elseif (args[2] == "karma") then
			Karma_SetConfig(KARMA_CONFIG.COLORFUNCTION, KARMA_CONFIG.COLORFUNCTION_TYPE_KARMA);
		elseif (args[2] == "played") then
			Karma_SetConfig(KARMA_CONFIG.COLORFUNCTION, KARMA_CONFIG.COLORFUNCTION_TYPE_PLAYED);
		elseif (args[2] == "class") then
			Karma_SetConfig(KARMA_CONFIG.COLORFUNCTION, KARMA_CONFIG.COLORFUNCTION_TYPE_CLASS);
		end
		KarmaWindow_Update();
	end
end

function Karma_SlashOpt(args)
	KarmaOptionsWindow_Show();
end

function Karma_SlashAuto(args, iCounter)
	local	bNewConfig = Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE);

	if (iCounter == 1) then
		if (bNewConfig == 1) then
			bNewConfig = 0;
		else
			bNewConfig = 1;
		end

		Karma_SetConfig(KARMA_CONFIG.AUTOIGNORE, bNewConfig);
	elseif (iCounter == 2) then
		for key, value in pairs(tOnOff) do
			if (strupper(value) == strupper(args[2])) then
				bNewConfig = key;
			end
		end
	end

	if (bNewConfig == 1) then
		KarmaChatDefault(KARMA_MSG_CONFIG_AUTOIGNORE .. KARMA_MSG_CONFIG_ISNOWON);
	else
		KarmaChatDefault(KARMA_MSG_CONFIG_AUTOIGNORE .. KARMA_MSG_CONFIG_ISNOWOFF);
	end
end

function Karma_SlashCache(args)
	if (KarmaObj.UIChat.SecondaryNotNil()) then
		KarmaChatDefault(KARMA_MSG_QCACHE_SECONDWINDOW);
	end

	local listsubid = 0;
	if (args[2] ~= nil) then
		listsubid = tonumber(args[2]);
		KarmaChatSecondaryFallbackDefault(KARMA_MSG_QCACHE_SUBLISTING .. args[2]);
	end

	for sName, values in pairs(KARMA_QuestCache) do
		local id = Karma_NilToString(values.id);
		local extid = Karma_NilToString(values.extid);
		KarmaChatSecondaryFallbackDefault("[" .. id .. "] " .. "{" .. extid .. "} " .. sName .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_QCACHE_COMPLETE .. values.complete);
		if (listsubid == id) or (listsubid == -1) then
			local QObjs;
			if (values.objectives ~= nil) then
				QObjs = values.objectives;
			else
				QObjs = {};
				Karma_GetQuestObjectives(values.id, QObjs, 1);
			end

			if (QObjs ~= nil) then
				if (type(QObjs.objectives) ~= "table") then
					KarmaChatSecondaryFallbackDefault(KARMA_MSG_QCACHE_OBJECTIVESPECIAL);
				else
					for qobjid, qobj in pairs(QObjs.objectives) do
						KarmaChatSecondaryFallbackDefault(qobj.type .. "~" .. qobj.desc .. KARMA_MSG_QCACHE_COMPLETE .. qobj.progress);
					end
				end
				KarmaChatSecondaryFallbackDefault("-----------------------------------------------");
			end
		end
	end
end

function Karma_SlashClean(args)
	Karma_ClearUnused(KarmaObj.DB.FactionCacheGet(), args[2]);
end

function Karma_SlashCleanPvp(args)
	Karma_ClearUnused(KarmaObj.DB.FactionCacheGet(), args[2], 1);
end

function	Karma_SlashKarmaTips(args)
	local	bNewConfig = Karma_GetConfig(KARMA_CONFIG.TOOLTIP_KARMA);

	bNewConfig = not bNewConfig;
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_KARMA, bNewConfig);

	if bNewConfig then
		KarmaChatDefault(KARMA_MSG_CONFIG_TIP_KARMA .. KARMA_MSG_CONFIG_ISNOWON);
	else
		KarmaChatDefault(KARMA_MSG_CONFIG_TIP_KARMA .. KARMA_MSG_CONFIG_ISNOWOFF);
	end
end

function	Karma_SlashNoteTips(args)
	local	bNewConfig = Karma_GetConfig(KARMA_CONFIG.TOOLTIP_NOTES);

	bNewConfig = not bNewConfig;
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_NOTES, bNewConfig);

	if bNewConfig then
		KarmaChatDefault(KARMA_MSG_CONFIG_TIP_NOTES .. KARMA_MSG_CONFIG_ISNOWON);
	else
		KarmaChatDefault(KARMA_MSG_CONFIG_TIP_NOTES .. KARMA_MSG_CONFIG_ISNOWOFF);
	end
end

function	Karma_SlashFilter(args)
	-- convert array back to string...
	local	CurrentFilter = "";
	local	Delimiter = "";
	local	Space = " ";
	for k, v in pairs(args) do
		if (k > 1) then
			CurrentFilter = CurrentFilter .. Delimiter .. v;
			Delimiter = Space;
		end
	end

	if (CurrentFilter ~= "") then
		Karma_ExecuteFilter(CurrentFilter);
		KarmaWindow_Filter_EditBox:SetText(KARMA_Filter.Total);
		KarmaChatSecondaryFallbackDefault(KARMA_MSG_FILTER_SET);
	else
		Karma_ExecuteFilter(nil);
		KarmaWindow_Filter_EditBox:SetText("");
		KarmaChatSecondaryFallbackDefault(KARMA_MSG_FILTER_CLEARED);
	end
end

local BucketValues = nil;

function Karma_SlashUpdate(args, iCounter, force)
	if (args[2] == nil) then
		local	sName, sServer = UnitName("target");
		if (sServer and (sServer ~= "")) then
			sName = sName .. "@" .. sServer;
		end
		args[2] = sName;
		if (args[2] == nil) then
			args[2] = "";
		end
	end
	if (args[2] == "") then
		local i, BucketValue;
		if (BucketValues == nil) then
			BucketValues = {};
			for i = 1, strlen(KARMA_ALPHACHARS) do
				BucketValue = {};
				BucketValue.Bucket = strsub(KARMA_ALPHACHARS, i, i);
				BucketValue.Value = 100000;
				tinsert(BucketValues, BucketValue);
			end
		end

		local FirstValue = 0;
		for i, BucketValue in pairs(BucketValues) do
			BucketValue.First = FirstValue;
			FirstValue = FirstValue + BucketValue.Value;
		end
		if (FirstValue == 0) then
			-- no data.
			return
		end

		-- select a random incomplete/non-KARMA_MAXLEVEL list member, try older entries with higher probability
		local	Choice = math.random(0, FirstValue - 1);
		local	sBucketName = nil;
		for i, BucketValue in pairs(BucketValues) do
			if (sBucketName == nil) then
				if (BucketValue.First <= Choice) and (Choice < BucketValue.First + BucketValue.Value) then
					sBucketName = BucketValue.Bucket;
				end
			end
		end

		if (sBucketName == nil) then
			KarmaChatDebug("Fallback! " .. Choice .. " ?? <-> " .. FirstValue);
			i = math.random(1, strlen(KARMA_ALPHACHARS));
			sBucketName = strsub(KARMA_ALPHACHARS, i, i);
		else
			KarmaChatDebug("Bucket selected: " .. sBucketName .. " (" .. Choice .. "/" .. FirstValue .. ")");
		end

		local	lMembers = KarmaObj.DB.SF.MemberListGet();
		local	lBucketMembers = lMembers[sBucketName];
		local	lCandidates = {};
		i = 0;
		local	j = 0;
		local	Now = time();
		for member, obj in pairs(lBucketMembers) do
			local	impdat = 0;
			local	bonus = 1;
			if ((obj.Meta ~= nil) or (strfind(member, "@") ~= nil)) then
				bonus = 0;
			else
				if (obj[KARMA_DB_L5_RRFFM.LEVEL] > 0) then
					bonus = bonus + KARMA_MAXLEVEL - obj[KARMA_DB_L5_RRFFM.LEVEL];
				else
					bonus = bonus + 50;
					impdat = 1;
				end
				if (obj[KARMA_DB_L5_RRFFM.CLASS] == "") then
					bonus = bonus + 25;
					impdat = 1;
				end
				if (obj[KARMA_DB_L5_RRFFM.RACE] == "") then
					bonus = bonus + 5;
					impdat = 1;
				end

				if (obj[KARMA_DB_L5_RRFFM.GUILD] == "") then
					bonus = bonus + 2;
				end
			end

			if (bonus > 0) then
				lCandidates[i] = {};
				lCandidates[i][0] = member;
				lCandidates[i][1] = j;
				local	Try;
				local	Success;
				if (obj[KARMA_DB_L5_RRFFM_TIMESTAMP] == nil) then
					-- like never tried...
					bonus = bonus + 100000;
				else
					local	Try = obj[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_TRY];
					local	Success = obj[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_SUCCESS];
					if (Try ~= nil) and (Success ~= nil) then
						if (Try == 0) then
							-- never tried...
							bonus = bonus + 100000;
						elseif (Success == 0) then
							-- never succeeded
							bonus = bonus + 1000;
						elseif (time() - Success > 7 * 24 * 60 * 60) then
							-- the more recent the last try, the lower the bonus
							-- => add difference in hours between last try and now...
							bonus = bonus + floor((time() - Try) / 3600);
						elseif (impdat ~= 1) then
							-- less than 7 days from most recent update,
							-- *only* non-crucial info missing
							bonus = 1;
						end
					end
				end

				if (type(obj[KARMA_DB_L5_RRFFM_CONFLICT]) == "table") then
					local	sConflict = obj[KARMA_DB_L5_RRFFM_CONFLICT].Conflict;
					if (obj[KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
						bonus = bonus + 20000;
					end
				end

				bonus = floor(bonus * obj[KARMA_DB_L5_RRFFM_KARMA] / 10);
				j = j + bonus;
				lCandidates[i][2] = j;
				i = i + 1;

				-- KarmaChatDefault("i: "..i..", Name = "..member..", Score: ".. j - bonus .. " -> "..j);
			end
		end -- for

		for i, BucketValue in pairs(BucketValues) do
			if (BucketValue.Bucket == sBucketName) then
				if (i == 0) or (j == 0) then
					KarmaChatDebug("Bucket is 'empty': " .. sBucketName .. ", dropping" .. KARMA_WINEL_FRAG_TRIDOTS);
					BucketValues[i] = nil;
				else
					BucketValue.Value = j;
				end
			end
		end

		KarmaChatDebug("Random selection: Bucket = " .. sBucketName .. ", i = " .. i .. ", jmax = " .. j);
		if (i > 0) and (j > 0) then
			local imax = i - 1;
			local jmax = j;
			j = math.random(0, jmax - 1);
			for i = 0, imax do
				if (j >= lCandidates[i][1]) and (j < lCandidates[i][2]) then
					args[2] = lCandidates[i][0];
					break;
				end
			end
		else
			KarmaChatDefault(KARMA_MSG_UPDATE_RANDOM_EMPTYBUCKET1 .. " <" .. sBucketName .. "> " .. KARMA_MSG_UPDATE_RANDOM_EMPTYBUCKET2);
		end
	end

	if (args[2] ~= "") then
		local	tMember = Karma_MemberList_GetObject(args[2]);
		if (tMember == nil) then
			if (force == nil) then
				KarmaChatDefault(KARMA_MSG_CANNOT_PRE .. args[1] .. KARMA_MSG_CANNOT_POST
								.. KARMA_WINEL_FRAG_SPACE .. args[2] .. KARMA_WINEL_FRAG_COLONSPACE
								.. KARMA_MSG_COMMAND_NOTMEMBER);
				return;
			end
		else
			if (tMember[KARMA_DB_L5_RRFFM_TIMESTAMP] == nil) then
				tMember[KARMA_DB_L5_RRFFM_TIMESTAMP] = {};
				tMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_SUCCESS] = 0;
			end

			tMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_TRY] = time();
		end

		-- KarmaChatDefault("Karma: Trying to update info on " .. args[2] .. KARMA_WINEL_FRAG_TRIDOTS);
		Karma_Command_UpdateMember_Insert(args);
	end
end

function Karma_SlashQCacheWarn(args)
	local	bNewConfig = Karma_GetConfig(KARMA_CONFIG.QUESTWARNCOLLAPSED);

	if (type(bNewConfig) ~= "number") then
		bNewConfig = 0;
	end

	bNewConfig = 1 - bNewConfig;
	Karma_SetConfig(KARMA_CONFIG.QUESTWARNCOLLAPSED, bNewConfig);

	if (bNewConfig == 1) then
		KarmaChatDefault(KARMA_MSG_CONFIG_QCACHEWARN .. KARMA_MSG_CONFIG_ISNOWON);
	else
		KarmaChatDefault(KARMA_MSG_CONFIG_QCACHEWARN .. KARMA_MSG_CONFIG_ISNOWOFF);
	end
end

function Karma_SlashShowOnline(args)
	KarmaWindow2_UpdateList1();
	KarmaWindow2:Show();
end

function Karma_SlashCheckOnlineInChannel(args)
	if (args[2] ~= nil) and (args[2] ~= "") then
		Karma_QueueCommandChannelCheck(args[2]);
	end
end

function Karma_CheckOnlineInChannelResults(blobofnames)
	if (not KARMA_Online.ChannelName) then
		return
	end

	local	bIsLFGChannel;
	local	iLFG, sLFG = GetChannelName(KARMA_CHANNELNAME_LFG);

	if (type(KARMA_Online.ChannelName) == "number") then
		KarmaChatSecondaryFallbackDefault(KARMA_MSG_CHECKCHANNEL_RESULTS .. " #" .. KARMA_Online.ChannelName .. ":");
		bIsLFGChannel = KARMA_Online.ChannelName == iLFG;
	else
		KarmaChatSecondaryFallbackDefault(KARMA_MSG_CHECKCHANNEL_RESULTS .. " <" .. KARMA_Online.ChannelName .. ">:");
		bIsLFGChannel = KARMA_Online.ChannelName == sLFG;
	end

	local	lMembers = KarmaObj.DB.SF.MemberListGet();

	local	sName, sBucketName, sMemberName, oMember;
	local	iResultCount = 0;
	local	iMemberCount = 0;
	for sName in string.gmatch(blobofnames, "%S+") do
		sMemberName = strsub(sName, 1, strlen(sName) - 1);

		-- channel mod has * in front
		if (strsub(sMemberName, 1, 1) == "*") then
			sMemberName = strsub(sMemberName, 2);
		end

		if (KARMA_Online.PlayersAll[sMemberName] == nil) then
			KARMA_Online.PlayersAll[sMemberName] = {};
		end
		KARMA_Online.PlayersAll[sMemberName].time = time();
		if (bIsLFGChannel) then
			KARMA_Online.PlayersAll[sMemberName].lfg = time();
		else
			KARMA_Online.PlayersAll[sMemberName].lfg = nil;
		end
		KARMA_Online.PlayersVersion = KARMA_Online.PlayersVersion + 1;

		oMember = Karma_MemberList_GetObject(sMemberName, nil, lMembers);
		if (oMember ~= nil) then
			local	sGuild = Karma_MemberObject_GetGuild(oMember);
			if (sGuild == nil) then
				sGuild = "";
			end
			if (sGuild ~= "") then
				sGuild = "<" .. sGuild .. "> ";
			end
			local	iLevel = Karma_MemberObject_GetLevel(oMember);
			local	sClass = Karma_MemberObject_GetClass(oMember);
			local	sKarma = Karma_MemberObject_GetKarmaModifiedForListWithColors(oMember);
			local	sMemberName_clickable = KOH.Name2Clickable(sMemberName);
			KarmaChatDebug(sMemberName .. "{" .. sKarma .. "} " .. sGuild .. iLevel .. " " .. sClass .. " online.");
			iMemberCount = iMemberCount + 1;
		end

		iResultCount = iResultCount + 1;
	end

	-- we don't want to appear ourselves
	KARMA_Online.PlayersAll[UnitName("player")] = nil;

	KarmaChatSecondaryFallbackDefault(KARMA_MSG_CHECKCHANNEL_TOTAL1 .. KARMA_WINEL_FRAG_COLONSPACE .. iResultCount .. KARMA_MSG_CHECKCHANNEL_TOTAL2 .. iMemberCount .. KARMA_MSG_CHECKCHANNEL_TOTAL3);
	KarmaWindow2_UpdateList1();
end

local	function Karma_CheckClassOnline(args)
	local	FactionRaceListComplete, FactionRaceListLocalized, ClassRaceMatrix;
	if (UnitFactionGroup("player") == "Alliance") then
		ClassRaceMatrix = KARMA_ClassToAllianceRace_Matrix;
		FactionRaceListComplete = KARMA_RacesAlliance;
		FactionRaceListLocalized = KARMA_RACES_ALLIANCE_LOCALIZED;
	else
		ClassRaceMatrix = KARMA_ClassToHordeRace_Matrix;
		FactionRaceListComplete = KARMA_RacesHorde;
		FactionRaceListLocalized = KARMA_RACES_HORDE_LOCALIZED;
	end

	-- need independent copy to delete the stuff we don't want
	local	FactionRaceListCheck = Karma_CopyTable(FactionRaceListComplete);

	local	ClassID = Karma_ClassToID(args[2]);
	local	iRaceCount = 5;
	if (ClassID ~= 0) then
		ClassID = math.abs(ClassID);
		local	iIndex;
		local	ClassToRace = ClassRaceMatrix[ClassID];
		KarmaChatDebug("ClassID = " .. ClassID .. " => Vector = " .. ClassToRace);
		local	DbgText = "";
		local	RemKey, RemVal;
		for iIndex = 1, 5 do
			if (strsub(ClassToRace, iIndex, iIndex) == "0") then
				DbgText = DbgText .. Karma_NilToString(FactionRaceListComplete[iIndex]) .. ", ";
				for RemKey, RemVal in pairs(FactionRaceListCheck) do
					if (RemVal == FactionRaceListComplete[iIndex]) then
						tremove(FactionRaceListCheck, RemKey);
						iRaceCount = iRaceCount - 1;
						break
					end
				end
			end
		end
		KarmaChatDebug("Removed: " .. DbgText);
	else
		KarmaChatDefault(KARMA_MSG_CHECKCLASS_UNK1 .. " <" .. args[2] .. ">" .. KARMA_MSG_CHECKCLASS_UNK2);
	end

	local	CCO_Args = {};
	CCO_Args[2] = args[2];	-- mandatory: class
	CCO_Args[4] = args[3];	-- maybe: level

	local	Races, sRace = {};
	for key, value in pairs(FactionRaceListCheck) do
		sRace = FactionRaceListLocalized[value];
		tinsert(Races, sRace);
	end

	-- first one without race to get a quick initial set, unless only one race (druid, paladin@Horde, shaman@Alliance)
	if (iRaceCount > 1) then
		KarmaChatDebug("Multi-race case for " .. args[2] .. "...");
		Karma_Command_CompareClassOnline_Insert(CCO_Args, Races);
	else
		KarmaChatDebug("Mono-race case for " .. args[2] .. "...");
		CCO_Args[3] = sRace;
		Karma_Command_CompareClassOnline_Insert(CCO_Args);
	end
	KarmaChatDebug("Queued request(s) to check for class " .. args[2] .. KARMA_WINEL_FRAG_TRIDOTS);

	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "classcheck done", func = Karma_ClassCheckCompleted, args = Karma_CopyTable(args) };
end

function Karma_ClassCheckCompleted(args)
	KarmaWindow2_UpdateList1();
	local	iCnt, bFound, i = #Karma_CommandQueue, false;
	for i = 1, iCnt do
		-- if we requeued checks, requeue this as well
		local	Cmd = Karma_CommandQueue[i]; 
		if (Cmd.method and (Cmd.method == Karma_Command_CompareClassOnline_Start) and Cmd.args and (Cmd.args.sClass == args[2])) then
			bFound = true;
			break;
		end
	end

	if (bFound) then
		Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "classcheck done", func = Karma_ClassCheckCompleted, args = args };
	else
		KarmaChatSecondaryFallbackDefault(KARMA_MSG_CHECKCLASS_DONE1 .. args[2] .. KARMA_MSG_CHECKCLASS_DONE2);
	end
end

function Karma_SlashCheckClassOnline(args)
	if (args[2] == nil) or (args[2] == "") then
		KarmaChatDefault(KARMA_MSG_COMMAND_MISSINGARG .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_CHECKCLASS_CLASS);
		return
	end

	if Karma_Executing_Command then
		KarmaChatDefault(KARMA_MSG_COMMANDQUEUE_FULL1 .. KARMA_WINEL_FRAG_COLONSPACE .. #Karma_CommandQueue .. KARMA_MSG_COMMANDQUEUE_FULL2);
		return
	end

	KarmaChatDefault(KARMA_MSG_CHECKCLASS_QUEUEING_ONE .. args[2] .. KARMA_WINEL_FRAG_TRIDOTS);

	-- lock queue
	Karma_Executing_Command = true;


	-- queue all
	Karma_CheckClassOnline(args);

	-- unlock queue
	Karma_Executing_Command = false;
end

function Karma_CheckAllClassesCompleted(args)
	local	iCnt, bFound, i = #Karma_CommandQueue, false;
	for i = 1, iCnt do
		-- if we requeued checks, requeue this as well
		local	Cmd = Karma_CommandQueue[i]; 
		if (Cmd.method and (Cmd.method == Karma_Command_CompareClassOnline_Start)) then
			bFound = true;
			break;
		end
	end

	if (bFound) then
		if (args.bFirst) then
			KarmaChatDefault(KARMA_MSG_CHECKCLASS_DONE_QUICK);
		end

		-- "Job done" message
		Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "classcheck done all", func = Karma_CheckAllClassesCompleted, args = {}};
	else
		KarmaChatDefault(KARMA_MSG_CHECKCLASS_DONE_ALL);
	end
end

function Karma_SlashCheckAllClassesOnline(args)
	if Karma_Executing_Command then
		KarmaChatDefault(KARMA_MSG_COMMANDQUEUE_FULL1 .. KARMA_WINEL_FRAG_COLONSPACE .. #Karma_CommandQueue .. KARMA_MSG_COMMANDQUEUE_FULL2);
		return
	end

	KarmaChatDefault(KARMA_MSG_CHECKCLASS_QUEUEING_ALL);

	-- lock queue
	Karma_Executing_Command = true;


	-- shift level, if argument was given
	args[3] = args[2];
	-- default to KARMA_MAXLEVEL if missing... (or player level +/-3 like /who?)
	if (args[3] == nil) or (args[3] == "") then
		args[3] = KARMA_MAXLEVEL;
	end

	-- queue *all*
	local iCounter;
	for iCounter = 1, 10 do
		args[2] = Karma_IDToClass(iCounter);
		Karma_CheckClassOnline(args);
	end

	-- "Job done" message
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "classcheck done all", func = Karma_CheckAllClassesCompleted, args = { bFirst = true }};

	-- unlock queue
	Karma_Executing_Command = false;
end

function	Karma_SlashCheckGuild(args)
	if (args[2] ~= nil) and (args[2] ~= "") then
		Karma_Command_CompareGuildOnline_Insert(args);
	else
		KarmaChatDefault(KARMA_MSG_COMMAND_MISSINGARG .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_CHECKGUILD_NOARG);
	end
end

function Karma_SlashResetGUI(args)
	Karma_MinimapIconFrame_ResetIcon();
	Karma_MinimapIconFrame_InitComplete();

	KarmaWindow:Hide();
	KarmaWindow:ClearAllPoints();
	KarmaWindow:SetPoint("CENTER");
	KarmaWindow:Show();

	KarmaWindow2:Hide();
	KarmaWindow2:ClearAllPoints();
	KarmaWindow2:SetPoint("CENTER");
	KarmaWindow2:Show();

	KarmaChatDefault(KARMA_MSG_RESETGUI);
end

function Karma_AltID2Names(altid, maxperline, prefix)
	local	AltsObj = KarmaObj.DB.FactionCacheGet()[KARMA_DB_L4_RRFF.ALTGROUPS];
	if (AltsObj == nil) then
		KarmaChatDefault(KARMA_MSG_OOPS);
		return "";
	end

	if (maxperline == nil) then
		maxperline = 99;
	end
	if (prefix == nil) then
		prefix = "";
	end

	local	key, value;
	for key, value in pairs(AltsObj) do
		if (value.ID == altid) then
			local	key2, value2, iCnt, sLine;
			sLine = prefix;
			iCnt = 0;
			for key2, value2 in pairs(value.AL) do
				if (iCnt > maxperline) then
					sLine = sLine .. "\n" .. prefix;
					iCnt = 0;
				end

				sLine = sLine .. " " .. value2;
				iCnt = iCnt + 1;
			end

			return sLine;
		end
	end

	return "<Oops?>";
end

function Karma_SlashAltList(args)
	if (args[2] == nil) or (args[2] == "") then
		KarmaChatDefault(KARMA_MSG_COMMAND_MISSINGARG .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_ALT_REQARG);
		return
	end

	local	oMember = Karma_MemberList_GetObject(args[2]);
	if (oMember == nil) then
		KarmaChatDefault(KARMA_MSG_ALT_LIST_NOTMEMBER1 .. args[2] .. KARMA_MSG_ALT_LIST_NOTMEMBER2
							.. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_COMMAND_NOTMEMBER);
		return
	end

	local	altid = Karma_MemberObject_GetAltID(oMember);
	if (altid == -1) then
		KarmaChatDefault(KARMA_MSG_ALT_LIST_NOALTS1 .. args[2] .. KARMA_MSG_ALT_LIST_NOALTS2);
		return
	end

	local	text = Karma_AltID2Names(altid);
	if (text ~= "") then
		KarmaChatDefault(KARMA_MSG_ALT_LIST_PREFIX .. tostring(altid) .. KARMA_WINEL_FRAG_COLONSPACE .. text);
	else
		KarmaChatDefault(KARMA_MSG_ALT_LIST_OOPS_NOALTS1 .. args[2] .. KARMA_MSG_ALT_LIST_OOPS_NOALTS2);
	end
end

function Karma_SlashAltRemove(args)
	if (args[2] == nil) or (args[2] == "") then
		KarmaChatDefault(KARMA_MSG_COMMAND_MISSINGARG .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_ALT_REQARG);
		return
	end

	local	AltsObj = KarmaObj.DB.FactionCacheGet()[KARMA_DB_L4_RRFF.ALTGROUPS];
	if (AltsObj == nil) then
		KarmaChatDefault(KARMA_MSG_OOPS);
		return
	end

	local	oMember = Karma_MemberList_GetObject(args[2]);
	if (oMember == nil) then
		KarmaChatDefault(KARMA_MSG_ALT_REM_NOTMEMBER1 .. args[2] .. KARMA_MSG_ALT_REM_NOTMEMBER2
							.. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_COMMAND_NOTMEMBER);
		return
	end

	local	altid = Karma_MemberObject_GetAltID(oMember);
	if (altid == -1) then
		KarmaChatDefault(KARMA_MSG_ALT_REM_NOALTID1 .. args[2] .. KARMA_MSG_ALT_REM_NOALTID2);
		return
	end

	local	key, value;
	for key, value in pairs(AltsObj) do
		if (value.ID == altid) then
			local	subkey, subvalue;
			for subkey, subvalue in pairs(value.AL) do
				if (subvalue == args[2]) then
					tremove(value.AL, subkey);
					break;
				end
			end
			Karma_MemberObject_SetAltID(oMember, -1);
			KarmaChatDefault(KARMA_MSG_ALT_REM_DONE1 .. args[2] .. KARMA_MSG_ALT_REM_DONE2);

			return
		end
	end

	Karma_MemberObject_SetAltID(oMember, -1);
	KarmaChatDefault(KARMA_MSG_ALT_REM_OOPS_NOALTS1 .. args[2] .. KARMA_MSG_ALT_REM_OOPS_NOALTS2
						.. KARMA_WINEL_FRAG_TRIDOTS);
end

function Karma_SlashAltAdd(args)
	-- arg2 = A, arg3 = B, both can be on alt-groups already!
	if (args[2] == nil) or (args[2] == "") or (args[3] == nil) or (args[3] == "") then
		KarmaChatDefault(KARMA_MSG_COMMAND_MISSINGARGS .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_ALT_REQARGS);
		return
	end

	if (args[2] == args[3]) then
		KarmaChatDefault(KARMA_MSG_ALT_ADD_SAMEPLAYER);
		return
	end

	local	AltsObj = KarmaObj.DB.FactionCacheGet()[KARMA_DB_L4_RRFF.ALTGROUPS];
	if (AltsObj == nil) then
		KarmaChatDefault(KARMA_MSG_OOPS);
		return
	end

	local	oMember1 = Karma_MemberList_GetObject(args[2]);
	local	oMember2 = Karma_MemberList_GetObject(args[3]);
	if (oMember1 == nil) or (oMember2 == nil) then
		KarmaChatDefault(KARMA_MSG_ALT_ADD_NOTMEMBER);
		return
	end

	local	altid1 = Karma_MemberObject_GetAltID(oMember1);
	local	altid2 = Karma_MemberObject_GetAltID(oMember2);

	if (altid1 == -1) and (altid2 == -1) then
		-- new group
		local	max_i = 0;
		local	key, value;
		for key, value in pairs(AltsObj) do
			local	i = value.ID;
			if (i > max_i) then
				max_i = i;
			end
		end

		max_i = max_i + 1;
		local	Obj = {};
		Obj.ID = max_i;
		Obj.AL = {};
		tinsert(Obj.AL, args[2]);
		tinsert(Obj.AL, args[3]);

		tinsert(AltsObj, Obj);

		Karma_MemberObject_SetAltID(oMember1, max_i);
		Karma_MemberObject_SetAltID(oMember2, max_i);

		KarmaChatDefault(args[2] .. KARMA_MSG_ALT_ADD_DONE1 .. args[3] .. KARMA_MSG_ALT_ADD_DONE2 .. tostring(max_i));
		return
	end

	if (altid1 ~= -1) and (altid2 ~= -1) then
		if (altid1 == altid2) then
			KarmaChatDefault(KARMA_MSG_ALT_ADD_ALREADYSAME);
		else
			-- merge groups: too much work :-D TODO?
			KarmaChatDefault(KARMA_MSG_ALT_ADD_NOMERGE);
		end

		return
	end

	-- add member to group
	local	altid;
	if (altid1 == -1) then
		altid = altid2;
	else
		altid = altid1;
	end

	local	Obj;
	for key, value in pairs(AltsObj) do
		if (value.ID == altid) then
			Obj = AltsObj[key];
		end
	end

	if (altid1 == -1) then
		tinsert(Obj.AL, args[2]);
		Karma_MemberObject_SetAltID(oMember1, altid);
	else
		tinsert(Obj.AL, args[3]);
		Karma_MemberObject_SetAltID(oMember2, altid);
	end
	
	KarmaChatDefault(args[2] .. KARMA_MSG_ALT_ADD_DONE1 .. args[3] .. KARMA_MSG_ALT_ADD_DONE2 .. tostring(altid));
end

function	Karma_SlashAltCheck(args)
	local	bExecute = (args[2] == "execute");
	if (bExecute and KARMA_CURRENTMEMBER) then
		KarmaChatSecondary("Unsetting currently selected member to not screw up UI.");
		Karma_SetCurrentMember(nil);
	end

	-- lazy variant. could probably merge the two parses into one faster...

	local	AltsObj = KarmaObj.DB.FactionCacheGet()[KARMA_DB_L4_RRFF.ALTGROUPS];
	if (AltsObj == nil) then
		AltsObj = {};
	end

	local	lMembers = KarmaObj.DB.SF.MemberListGet();
	if (lMembers == nil) then
		lMembers = {};
	end

	for iBucketNum = 1, strlen(KARMA_ALPHACHARS) do
		local	sBucketName = strsub(KARMA_ALPHACHARS, iBucketNum, iBucketNum);
		local	lBucketMembers = lMembers[sBucketName];
		if (type(lBucketMembers) ~= "table") then
			KarmaChatDebug("Oopsie: Bucket " .. sBucketName .. " doesn't exist??!");
		else
			local	sMember, oMember;
			for sMember, oMember in pairs(lBucketMembers) do
				local	altid = Karma_MemberObject_GetAltID(oMember);
				if (altid ~= nil) and (altid ~= -1) then
					local	bFound;
					local	altgroupkey, altgroupvalue, altgrouplist;
					for altgroupkey, altgroupvalue in pairs(AltsObj) do
						if (altgroupvalue.ID == altid) then
							altgrouplist = AltsObj[altgroupkey];
							for altkey, altvalue in pairs(altgrouplist.AL) do
								if (sMember == altvalue) then
									bFound = true;
									break;
								end
							end

							break;
						end
					end
					if (not bFound) then
						if (bExecute) then
							KarmaChatSecondary("Alt " .. sMember .. " supposed to be in group #" .. altid .. ", but not found. Resetting " .. sMember .. ".");
							Karma_MemberObject_SetAltID(oMember, -1);
						else
							KarmaChatSecondary("Alt " .. sMember .. " supposed to be in group #" .. altid .. ", but not found. Would reset " .. sMember .. ".");
						end
					end
				end
			end
		end
	end

	local	altgroupkey, altgroupvalue, altgrouplist;
	for altgroupkey, altgroupvalue in pairs(AltsObj) do
		altgrouplist = AltsObj[altgroupkey];
		KarmaChatDebug("Checking alt group #" .. altgroupvalue.ID .. " containing: " .. Karma_AltID2Names(altgroupvalue.ID));
		for altkey, altvalue in pairs(altgrouplist.AL) do
			local	bValid;
			local	altid = -1;
			local	oMember = Karma_MemberList_GetObject(altvalue);
			if (oMember) then
				altid = Karma_MemberObject_GetAltID(oMember);
				bValid = (altgroupvalue.ID == altid);
			end

			if (not bValid) then
				if (bExecute) then
					KarmaChatSecondary("Alt " .. altvalue .. " supposed to be in group #" .. altgroupvalue.ID .. ", but disagrees. Removing from group.");
					tremove(altgrouplist.AL, altkey);
				else
					KarmaChatSecondary("Alt " .. altvalue .. " supposed to be in group #" .. altgroupvalue.ID .. ", but disagrees. Would remove from group.");
				end
			end
		end
	end
end

--- TODO ---
function Karma_SlashPauseWho(args)
	KarmaChatDefault(KARMA_MSG_OOPS_NOTIMPLEMENTED .. KARMA_WINEL_FRAG_TRIDOTS);
end

function Karma_SlashAutocheckTalents(args)
	KARMA_TalentInspect.AutofetchConfigCache = Karma_GetConfig(KARMA_CONFIG.TALENTS_AUTOFETCH);
	if (KARMA_TalentInspect.AutofetchConfigCache == nil) then
		KARMA_TalentInspect.AutofetchConfigCache = 1;
	else
		KARMA_TalentInspect.AutofetchConfigCache = 1 - KARMA_TalentInspect.AutofetchConfigCache;
	end
		
	Karma_SetConfig(KARMA_CONFIG.TALENTS_AUTOFETCH, KARMA_TalentInspect.AutofetchConfigCache);
	if (KARMA_TalentInspect.AutofetchConfigCache == 1) then
		KarmaChatDefault(KARMA_MSG_CONFIG_AUTOTALENTS .. KARMA_MSG_CONFIG_ISNOWON);
	else
		KarmaChatDefault(KARMA_MSG_CONFIG_AUTOTALENTS .. KARMA_MSG_CONFIG_ISNOWOFF);
	end
end

function Karma_SlashSkillModel(args)
	if (args[2] == "simple") then
		Karma_SetConfig(KARMA_CONFIG_SKILL_MODEL, "simple");
		KARMA_SKILL_LEVELS = KARMA_SKILL_LEVELS_SIMPLE;
		KarmaChatDefault(KARMA_MSG_CONFIG_SKILLMODEL_ISNOW .. " *simple*.");
	elseif (args[2] == "complex") then
		Karma_SetConfig(KARMA_CONFIG_SKILL_MODEL, "complex");
		KARMA_SKILL_LEVELS = KARMA_SKILL_LEVELS_COMPLEX;
		KarmaChatDefault(KARMA_MSG_CONFIG_SKILLMODEL_ISNOW .. " *complex*.");
	else
		KarmaChatDefault(KARMA_MSG_COMMAND_MISSINGARG .. KARMA_WINEL_FRAG_COLONSPACE .. "<[complex||simple]>");
	end
end

function	Karma_CrossFactionInfo(args)
	if (args[2] == nil) or (args[2] == "") then
		local	sName, sServer = UnitName("target");
		if (sServer and (sServer ~= "")) then
			sName = sName .. "@" .. sServer;
		end
		args[2] = sName;
	end

	if (args[2] == nil) or (args[2] == "") then
		KarmaChatDefault(KARMA_MSG_COMMAND_MISSINGARG .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_PLAYER_REQARG);
		return;
	end

	local	mouseoverindex = tonumber(args[2]);
	if (mouseoverindex) and (mouseoverindex > 0) then
		args[2] = KarmaModuleLocal.MouseOverKeepList[mouseoverindex].Name;
	end

	local	bFound = false;

	local	oXFaction = KarmaObj.DB.FactionOtherGet();
	if (oXFaction) and (type(oXFaction) == "table") then
		oXlMembers = oXFaction[KARMA_DB_L4_RRFF.MEMBERBUCKETS];
		if (oXlMembers) and (type(oXlMembers) == "table") then
			local	XBucketkey = KarmaObj.NameToBucket(args[2]);
			local	oXlBucket = oXlMembers[XBucketkey];
			if (oXlBucket) and (type(oXlBucket) == "table") then
				local	oXMember = oXlBucket[args[2]];
				if (oXMember) then
					local	sGuild = Karma_MemberObject_GetGuild(oXMember);
					if (sGuild) and (sGuild ~= "") then
						sGuild = " <" .. sGuild .. ">";
					else
						sGuild = "";
					end
					local	sKarma = Karma_MemberObject_GetKarmaWithModifiers(oXMember);
					local	sNote = Karma_MemberObject_GetNotes(oXMember);
					if (sNote) and (sNote ~= "") then
						sNote = "- Notes: " .. sNote;
					else
						sNote = "- no notes.";
					end

					KarmaChatDefault("|cFFFF8080" .. args[2] .. "|r " .. sGuild .. " {" .. sKarma .. "} " .. sNote);
					bFound = true;
				end
			end
		end
	end

	if (not bFound) then
		-- to do: localize
		local	xFaction;
		if (UnitFactionGroup("player") == "Horde") then
			xFaction = "Alliance";
		else
			xFaction = "Horde";
		end

		KarmaChatDefault("Player >" .. args[2] .. "< is not listed on Karma's table for the " .. xFaction .. ".");
	end
end

function	Karma_CrossFactionNote(args)
	if	(args[2] == nil) or (args[2] == "") or
		(args[3] == nil) or (args[3] == "") or
		(args[4] == nil) or (args[4] == "") then
		-- to do: localize
		KarmaChatDefault(KARMA_MSG_COMMAND_MISSINGARG .. KARMA_WINEL_FRAG_COLONSPACE .. "<playername or mouseover-index> +/-/!<Karma> +/!<Note> (where +: add, -: take away, !: set to value)");
		return;
	end

	local	mouseoverindex = tonumber(args[2]);
	if (mouseoverindex) and (mouseoverindex > 0) then
		args[2] = KarmaModuleLocal.MouseOverKeepList[mouseoverindex].Name;
	end

	local	argModKarma = strsub(args[3], 1, 1);
	local	argValKarma = tonumber(strsub(args[3], 2));
	if ((argModKarma ~= "+") and (argModKarma ~= "-") and (argModKarma ~= "!")) or (argValKarma == nil) then
		-- to do: localize
		KarmaChatDefault("Second argument must be: +/-/!<Karma>");
		return;
	end

	local	argModNote = strsub(args[4], 1, 1);
	local	argValNote = strsub(args[4], 2);
	if (argModNote ~= "+") and (argModNote ~= "!") then
		-- to do: localize
		KarmaChatDefault("Third argument must be: +/!<Note>");
		return;
	end
	local	i = 5;
	while (args[i] ~= nil) do
		argValNote = argValNote .. " " .. args[i];
		i = i + 1;
	end

	local	xFaction;
	if (UnitFactionGroup("player") == "Horde") then
		xFaction = "Alliance";
	else
		xFaction = "Horde";
	end

	if (mouseoverindex) then
		if (xFaction ~= KarmaModuleLocal.MouseOverKeepList[mouseoverindex].Faction) then
			-- to do: localize
			KarmaChatDefault("Player is on *YOUR* faction. This command is for cross-faction players.");
			return;
		end
	end

	local	bFound = false;
	if (xFaction) then
		local	oXFaction = KarmaObj.DB.FactionOtherGet();
		if (oXFaction) and (type(oXFaction) == "table") then
			oXlMembers = oXFaction[KARMA_DB_L4_RRFF.MEMBERBUCKETS];
			if (oXlMembers) and (type(oXlMembers) == "table") then
				local	XBucketkey = KarmaObj.NameToBucket(args[2]);
				local	oXlBucket = oXlMembers[XBucketkey];
				if (oXlBucket) and (type(oXlBucket) == "table") then
					local	oXMember = oXlBucket[args[2]];
					if (oXMember) then
						local	iKarma = Karma_MemberObject_GetKarma(oXMember);
						local	sKarma = Karma_MemberObject_GetKarmaWithModifiers(oXMember);
						local	sNote = Karma_MemberObject_GetNotes(oXMember);
						if (sNote) and (sNote ~= "") then
							sNote = "- Notes: " .. sNote;
						else
							sNote = "- no notes.";
						end

						-- to do: localize
						KarmaChatDefault("Modifying entry for |cFFFF8080" .. args[2] .. "|r {" .. sKarma .. "} " .. sNote);

						argValKarma = floor(argValKarma);
						if (argModKarma == "+") then
							iKarma = iKarma + argValKarma;
						elseif (argModKarma == "-") then
							iKarma = iKarma - argValKarma;
						elseif (argModKarma == "!") then
							iKarma = argValKarma;
						end
						if (iKarma < 1) or (iKarma > 100) then
							iKarma = math.max(1, math.min(100, iKarma));
							KarmaChatDefault("Karma change: " .. argModKarma .. argValKarma .. " results in invalid Karma value. Changed to " .. iKarma ..".");
						end
						Karma_MemberObject_SetKarma(oXMember, iKarma);

						sNote = Karma_MemberObject_GetNotes(oXMember);
						if (argValNote ~= "") then
							argValNote = argValNote .. "\n";
						end
						if (argModNote == "+") then
							sNote = sNote .. argValNote;
						elseif (argModNote == "!") then
							sNote = argValNote;
						end
						Karma_MemberObject_SetNotes(oXMember, sNote);

						sKarma = Karma_MemberObject_GetKarmaWithModifiers(oXMember);
						if (sNote) and (sNote ~= "") then
							sNote = "- Notes: " .. sNote;
						else
							sNote = "- no notes.";
						end

						-- to do: localize
						KarmaChatDefault("Changed entry reads as |cFFFF8080" .. args[2] .. "|r {" .. sKarma .. "} " .. sNote);

						bFound = true;
					end
				end
			end

			if (not bFound) then
				KOH.TableInit(oXFaction, KARMA_DB_L4_RRFF.XFACTIONHOLD);
				oXlMembers = oXFaction[KARMA_DB_L4_RRFF.XFACTIONHOLD];
				KOH.TableInit(oXlMembers, args[2]);
				local	oXMember = oXlMembers[args[2]];
				oXMember[KARMA_DB_L5_RRFFM.NAME] = args[2];
				oXMember[KARMA_DB_L5_RRFFM_KARMA] = args[3];
				oXMember[KARMA_DB_L5_RRFFM_NOTES] = argModNote .. argValNote;
				oXMember[KARMA_DB_L5_RRFFM_TIMESTAMP] = time();
				oXMember[KARMA_DB_L5_RRFFX_SOURCE] = UnitName("player");
				if (mouseoverindex) then
					local	value = KarmaModuleLocal.MouseOverKeepList[mouseoverindex];
					oXMember[KARMA_DB_L5_RRFFM.GUID] = value.GUID;
					oXMember[KARMA_DB_L5_RRFFM.RACE] = value.Race;
					oXMember[KARMA_DB_L5_RRFFM.LEVEL] = value.Level;
					oXMember[KARMA_DB_L5_RRFFM.CLASS] = value.Class;
					oXMember[KARMA_DB_L5_RRFFX_FACTION] = xFaction;
				end

				-- to do: localize
				KarmaChatDefault("Stored entry for " .. args[2] .. " in holding space. You'll have to login at the \"other\" side to let Karma add the player to its list and update them accordingly.");
			end
		end
	end
end

function	Karma_CrossFactionUpdate(args)
	if (#Karma_CommandQueue > 0) then
		-- to do: localize
		KarmaChatDefault("Command queue must be empty for this... (" .. #Karma_CommandQueue .. " commands pending)");
		return;
	end

	Karma_Executing_Command = true;

	KarmaChatDefault("Starting cross-faction update...");

	local	sQueued = "";
	local	sSkipped = nil;

	local	oFaction = KarmaObj.DB.FactionCacheGet();
	local	olMembers = oFaction[KARMA_DB_L4_RRFF.XFACTIONHOLD];
	if (olMembers) and (type(olMembers) == "table") then
		local	oMember, bExecute;
		local	args = {};
		for key, value in pairs(olMembers) do
			KarmaChatSecondary("Looking at entry for >" .. key .. "< created by " .. value[KARMA_DB_L5_RRFFX_SOURCE] .. " on " .. date("%Y-%m-%d %H:%M", value[KARMA_DB_L5_RRFFM_TIMESTAMP]));
			oMember = Karma_MemberList_GetObject(key);
			if (oMember == nil) then
				sQueued = sQueued .. " " .. key;
				args[2] = key;
				Karma_Command_AddMember_Insert(args);
				KarmaChatSecondary("Trying to add >" .. key .. "< to Karma's list first... (must be online for that!) Reissue the command to actually store the information.")
			elseif (key == KARMA_CURRENTMEMBER) then
				sSkipped = key;
				KarmaChatSecondary("Couldn't update " .. key ..": currently selected in Karma's main window. Result of a potential note change is not definite. Holding off.");
			else
				bExecute = true;
				local	sError = "";

				-- verify: GUID, Race, Level, Class, Faction
				if	(value.GUID) then
					local	sGUID = Karma_MemberObject_GetGUID(oMember);
					if (sGUID) and (sGUID ~= "") then
						if (value.GUID ~= sGUID) then
							bExecute = false;
							sError = sError .. " GUID";
						end
					end
				end

				if	(value.Race) then
					local	sRace = Karma_MemberObject_GetRace(oMember);
					if (sRace) and (sRace ~= "") then
						if (value.Race ~= sRace) then
							bExecute = false;
							sError = sError .. " race";
						end
					end
				end

				if	(value.Level) then
					local	iLevel = Karma_MemberObject_GetLevel(oMember);
					if (iLevel) and (iLevel ~= 0) then
						if (value.Level > iLevel) then
							bExecute = false;
							sError = sError .. " level";
						end
					end
				end

				if	(value.Class) then
					local	sClass = Karma_MemberObject_GetClass(oMember);
					if (sClass) and (sClass ~= "") then
						if (value.Class ~= sClass) then
							bExecute = false;
							sError = sError .. " class";
						end
					end
				end

				if	(value.Faction) then
					if (value.Faction ~= UnitFactionGroup("player")) then
						bExecute = false;
						sError = sError .. " faction";
					end
				end

				if (not bExecute) then
					-- to do: localize
					KarmaChatSecondary("Couldn't update " .. key .." due to mismatch:" .. sError);
				else
					local	iKarma = Karma_MemberObject_GetKarma(oMember);
					local	sKarma = Karma_MemberObject_GetKarmaWithModifiers(oMember);
					local	sNote = Karma_MemberObject_GetNotes(oMember);
					if (sNote) and (sNote ~= "") then
						sNote = "- Notes: " .. sNote;
					else
						sNote = "- no notes.";
					end

					-- to do: localize
					KarmaChatDefault("Modifying entry for |cFF80FF80" .. key .. "|r {" .. sKarma .. "} " .. sNote);

					if (value.GUID) then
						local	sGUID = Karma_MemberObject_GetGUID(oMember);
						if (sGUID == nil) then
							KarmaChatSecondary("There was no GUID for " .. key .. ", entering the cross-faction one!");
							Karma_MemberObject_SetGUID(oMember, value.GUID);
						end
					end

					local	argModKarma = strsub(value[KARMA_DB_L5_RRFFM_KARMA], 1, 1);
					local	argValKarma = tonumber(strsub(value[KARMA_DB_L5_RRFFM_KARMA], 2));

					argValKarma = floor(argValKarma);
					if (argModKarma == "+") then
						iKarma = iKarma + argValKarma;
					elseif (argModKarma == "-") then
						iKarma = iKarma - argValKarma;
					elseif (argModKarma == "!") then
						iKarma = argValKarma;
					end
					if (iKarma < 1) or (iKarma > 100) then
						iKarma = math.max(1, math.min(100, iKarma));
						KarmaChatDefault("Karma change: " .. value[KARMA_DB_L5_RRFFM_KARMA] .. " results in invalid Karma value. Changed to " .. iKarma);
					end
					Karma_MemberObject_SetKarma(oMember, iKarma);

					local	argModNote = strsub(value[KARMA_DB_L5_RRFFM_NOTES], 1, 1);
					local	argValNote = strsub(value[KARMA_DB_L5_RRFFM_NOTES], 2);

					sNote = Karma_MemberObject_GetNotes(oMember);
					if (argValNote ~= "") then
						argValNote = argValNote .. "\n";
					end
					if (argModNote == "+") then
						sNote = sNote .. argValNote;
					elseif (argModNote == "!") then
						sNote = argValNote;
					end
					Karma_MemberObject_SetNotes(oMember, sNote);

					sKarma = Karma_MemberObject_GetKarmaWithModifiers(oMember);
					if (sNote) and (sNote ~= "") then
						sNote = "- Notes: " .. sNote;
					else
						sNote = "- no notes.";
					end

					-- to do: localize
					KarmaChatSecondary("Changed entry reads as |cFF80FF80" .. key .. "|r {" .. sKarma .. "} " .. sNote);
	
					-- entry done, drop
					olMembers[key] = nil;
				end
			end
		end
	end

	if (sQueued ~= "") then
		KarmaChatDefault("-- Queued to add first:" .. sQueued);
	end
	if (sSkipped) then
		KarmaChatDefault("-- Skipped (selected): " .. sSkipped);
	end
	KarmaChatDefault("***")

	Karma_Executing_Command = false;
end

function	Karma_MemberForceNew(args)
	if (args[2] == nil) or (args[2] == "") then
		KarmaChatDefault("Missing argument: <player>");
		return;
	end

	do
		local	lMembers = KarmaObj.DB.SF.MemberListGet();
		local	sBucketName = KarmaObj.NameToBucket(args[2]);
		if (lMembers[sBucketName][args[2]] == nil) then
			KarmaChatDefault("Invalid argument: >" .. args[2] .. "< not on Karma's list.");
			return;
		end

		if (args[2] == KARMA_CURRENTMEMBER) then
			Karma_SetCurrentMember(nil);
		end
	
		local	sDate = date("%Y%m%d", time());
		local	i = 1;
		local	key = args[2] .. "." .. sDate .. ":" .. i;
		while (lMembers[sBucketName][key] ~= nil) do
			i = i + 1;
		end
	
		-- store as version to a new key
		lMembers[sBucketName][key] = lMembers[sBucketName][args[2]];
		Karma_MemberObject_SetName(lMembers[sBucketName][key], key);

		if (type(lMembers[sBucketName][key][KARMA_DB_L5_RRFFM_CONFLICT]) == "table") then
			if (lMembers[sBucketName][key][KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
				lMembers[sBucketName][key][KARMA_DB_L5_RRFFM_CONFLICT].Resolved = time();
			end
		end

		-- unlink the two entries
		lMembers[sBucketName][args[2]] = nil;
	end

	Karma_MemberList_Add(args[2]);
	Karma_MemberList_Update(args[2]);
	Karma_MemberList_CreatePartyNamesCache();
	Karma_MemberList_ResetMemberNamesCache();
end

function	Karma_MemberForceUpdate(args)
	if (args[2] == nil) or (args[2] == "") then
		KarmaChatDefault("Missing argument: <player>");
		return;
	end

	do
		local	oMember = Karma_MemberList_GetObject(args[2]);
		if (oMember == nil) then
			KarmaChatDefault("Invalid argument: >" .. args[2] .. "< not on Karma's list.");
		end
	
		oMember[KARMA_DB_L5_RRFFM.GUID] = nil;
		oMember[KARMA_DB_L5_RRFFM.LEVEL] = 0;
		oMember[KARMA_DB_L5_RRFFM.CLASS_ID] = 0;
		oMember[KARMA_DB_L5_RRFFM.RACE] = "";
		oMember[KARMA_DB_L5_RRFFM.LASTCHANGED_TIME] = time();
		oMember[KARMA_DB_L5_RRFFM.LASTCHANGED_FIELD] = "forced update";

		if (type(oMember[KARMA_DB_L5_RRFFM_CONFLICT]) == "table") then
			if (oMember[KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
				oMember[KARMA_DB_L5_RRFFM_CONFLICT].Resolved = time();
			end
		end
	end

	KarmaChatDefault("Player " .. KOH.Name2Clickable(args[2]) .. " has been reset.");
	Karma_MemberList_Update(args[2]);
	Karma_MemberList_CreatePartyNamesCache();
	Karma_MemberList_ResetMemberNamesCache();

	Karma_SlashUpdate(args, 2);
end

function	Karma_MemberForceCheck(args)
	local	bExecute = (args[2] == "execute");
	if (bExecute and KARMA_CURRENTMEMBER) then
		KarmaChatSecondary("Unsetting currently selected member to not screw up UI.");
		Karma_SetCurrentMember(nil);
	end

	local	lMembers = KarmaObj.DB.SF.MemberListGet();
	if (lMembers == nil) then
		lMembers = {};
	end

	local	iBucketNum;
	for iBucketNum = 1, strlen(KARMA_ALPHACHARS) do
		local	sBucketName = strsub(KARMA_ALPHACHARS, iBucketNum, iBucketNum);
		local	lBucketMembers = lMembers[sBucketName];
		if (type(lBucketMembers) ~= "table") then
			KarmaChatDebug("Oopsie: Bucket " .. sBucketName .. " doesn't exist??!");
		else
			local	sMember, oMember;
			for sMember, oMember in pairs(lBucketMembers) do
				if (sMember ~= Karma_MemberObject_GetName(oMember)) then
					KarmaChatSecondary("Mismatch due to forcenew: " .. sMember .. " =!= " .. Karma_MemberObject_GetName(oMember));
					if (bExecute) then
						KarmaChatSecondary("Overwriting former name with metakeyed name.");
						Karma_MemberObject_SetName(oMember, sMember);
					end
				end
			end
		end
	end
end

function	Karma_ExchangeAllow(args)
	if (args[2] == nil) or (args[2] == "") then
		if (KARMA_EXCHANGE.ENABLED_WITH ~= nil) then
			KarmaChatDefault("Player >" .. KARMA_EXCHANGE.ENABLED_WITH .. "< is now not anymore allowed to pull Karma values...");
		end
		KARMA_EXCHANGE.ENABLED_WITH = nil;
	else
		KARMA_EXCHANGE.ENABLED_WITH = args[2];
		KarmaChatDefault("Player >" .. args[2] .. "< is at the moment allowed to pull Karma values...");
	end
end

function	Karma_ExchangeRequest(args)
	if (KARMATRANS_AVAILABLE ~= 1) or (type(KarmaForeign) ~= "table") then
		-- TODO: xlate
		KarmaChatDefault("KarmaTrans not enabled. Nothing to do.");
		return;
	end

	if (args[2] == nil) or (args[2] == "") then
		KarmaChatDefault("Missing arguments: <player> [<alphabetic character to begin with>]");
		return;
	end

	local	sRequest = "?x1:";
	if (args[3] ~= nil) then
		if (strlen(args[3]) ~= 1) or (strfind(KARMA_ALPHACHARS, args[3]) == nil) then
			KarmaChatDefault("Additional argument invalid: [<alphabetic character to begin with>] (must be in range of A to Z)");
			return;
		else
			sRequest = sRequest .. args[3] .. "*";
		end
	else
		if (KarmaTrans_ForeignKarmaContinueWithGet ~= nil) then
			local	sServer, sFaction, sName;
			sServer = GetCVar("realmName");
			sFaction = UnitFactionGroup("player");
			local	sName = KarmaTrans_ForeignKarmaContinueWithGet(sServer, sFaction, args[2]);
			if (sName) then
				sRequest = sRequest .. sName;
			end
		end
	end

	KARMA_EXCHANGE.START_WITH = args[2];
	KARMA_EXCHANGE.START_FRAG = strsub(sRequest, 5);
	KARMA_EXCHANGE.START_AT = GetTime();

	KARMA_EXCHANGE.REQ_IS = KARMA_EXCHANGE.START_FRAG;
	KARMA_EXCHANGE.REQ_AT = GetTime();

	KARMA_EXCHANGE.ACK_IS = nil;
	KARMA_EXCHANGE.ACK_AT = nil;

	KARMA_EXCHANGE.FIRST = nil;
	KARMA_EXCHANGE.COUNT = 0;
	KARMA_EXCHANGE.DONE = nil;

	KarmaChatDefault("Asking >" .. args[2] .. "< for some Karma data: Names, total times joined and assigned Karma values...");
	SendAddonMessage("KARMA", sRequest, "WHISPER", args[2]);
end

function	Karma_ExchangeStatus()
	if (KARMATRANS_AVAILABLE ~= 1) or (type(KarmaForeign) ~= "table") then
		-- TODO: xlate
		KarmaChatDefault("KarmaTrans not enabled. Nothing to do.");
		return;
	end

	local	key, value, text;
	text = "Karma_ExchangeStatus() -> ";
	for key, value in pairs(KARMA_EXCHANGE) do
		text = text .. key .. ": " .. value .. "; ";
	end
	KarmaChatDefault(text);
end

function	Karma_ExchangeTrust(args)
	if	(args[2] == nil) or (args[2] == "") or
		(args[3] == nil) or (args[3] == "") then
		-- TODO: xlate
		KarmaChatDefault("Params: <player> <trust value (0.01 .. 1.0)>");
		return;
	end

	local	oMember = Karma_MemberList_GetObject(args[2]);
	local	trust = tonumber(args[3]);
	if (trust ~= nil) and (trust >= 0.01) and (trust <= 1.0) then
		oMember[KARMA_DB_L5_RRFFM_KARMA_TRUST] = trust;

		-- TODO: xlate
		KarmaChatDefault("Trust for >" .. args[2] .. "< is now " .. trust);
	end
end

function	Karma_ExchangeUpdate()
	if (KARMATRANS_AVAILABLE ~= 1) or (type(KarmaForeign) ~= "table") then
		-- TODO: xlate
		KarmaChatDefault("KarmaTrans not enabled. Nothing to do.");
		return;
	end

	local	sServer = GetCVar("realmName"); -- GetRealmName(): not sure about localization
	local	sFaction = UnitFactionGroup("player");
	local	sServFact = sServer .. "#" .. sFaction;

	if (type(KarmaForeign[sServFact]) ~= "table") then
		-- TODO: xlate
		KarmaChatDefault("No data from other players. Nothing to do.");
		return;
	end

	-- set all KARMA_DB_L5_RRFFM_KARMA_IMPORTED to 0
	do
		local	oFaction = KarmaObj.DB.FactionCacheGet();
		local	bucket, memberlist, membername, memberdata;
		for bucket, memberlist in pairs(oFaction[KARMA_DB_L4_RRFF.MEMBERBUCKETS]) do
KarmaChatDebug("reset bucket " .. bucket .. "...");
			for membername, memberdata in pairs(memberlist) do
				memberdata[KARMA_DB_L5_RRFFM_KARMA_IMPORTED] = 0;
			end
		end
	end

	local	bAddAllowed = 0;
	if (Karma_GetConfig(KARMA_CONFIG.DEBUG_ENABLED) == 1) then
		bAddAllowed = 1;
	end

	local	oForeign = KarmaForeign[sServFact];
	local	supplier, buckets;
	for supplier, buckets in pairs(oForeign) do
		if (type(buckets) == "table") then
			-- TODO: we want to factor in how much we trust the supplier...
			-- in test phase hardcoded to factor 0.2
			local	suppliertrust = 0.2;
			do
				local	oSupplier = Karma_MemberList_GetObject(supplier);
				if (oSupplier[KARMA_DB_L5_RRFFM_KARMA_TRUST] ~= nil) then
					suppliertrust = oSupplier[KARMA_DB_L5_RRFFM_KARMA_TRUST];
				end
			end

			local	bucket, playerlist;
			for bucket, playerlist in pairs(buckets) do
				local	player, data;
KarmaChatDebug("sup " .. supplier .. ", bucket " .. bucket .. "...");
				if (type(playerlist) == "table") then
					for player, data in pairs(playerlist) do
						local	oMember = Karma_MemberList_GetObject(player);
						if (oMember == nil) and (data.Karma ~= 50) and (bAddAllowed == 1) then
							-- add if enough (interesting) real info is available
							if (data.Level) and (data.Class) and (data.Race) then
								Karma_MemberList_Add(player);
								oMember = Karma_MemberList_GetObject(player);
								if (oMember) then
									oMember[KARMA_DB_L5_RRFFM.LEVEL] = data.Level;
									oMember[KARMA_DB_L5_RRFFM.CLASS_ID] = data.Class;
									oMember[KARMA_DB_L5_RRFFM.CLASS] = Karma_IDToClass(data.Class);
									oMember[KARMA_DB_L5_RRFFM.RACE] = data.Race;
								end
								Karma_MemberList_Update(player);
							end
						end

						if (oMember ~= nil) then
							local	delta = data.Karma - 50;
							if (data.Played < 180) and (math.abs(delta) > 5) then
								-- if just short groupage, no factor, assuming real stupidity
								-- (like e.g. someone ninja'ing adamantite while you clear)
								oMember[KARMA_DB_L5_RRFFM_KARMA_IMPORTED] = delta;
							else
								-- otherwise, factor to offset that humans are... human
								-- max. delta is 40, assuming loss of max. 5 per hour
								local	maxloss = math.floor(5 * data.Played / 3600 + 0.5);
								maxloss = math.min(maxloss, 40);
								if (math.abs(delta) > maxloss) then
									if (delta < 0) then
										delta = - maxloss
									else
										delta = maxloss;
									end
								end

								if (delta < 0) then
									delta = math.ceil(delta * suppliertrust);
								else
									delta = math.floor(delta * suppliertrust);
								end

								if (oMember[KARMA_DB_L5_RRFFM_KARMA_IMPORTED] == nil) then
									oMember[KARMA_DB_L5_RRFFM_KARMA_IMPORTED] = 0;
								end
	
								oMember[KARMA_DB_L5_RRFFM_KARMA_IMPORTED] = oMember[KARMA_DB_L5_RRFFM_KARMA_IMPORTED] + delta;
							end
						end
					end
				end
			end
		end
	end
end

function	Karma_SlashPubNoteSet(args)
	if	(args[2] == nil) or (args[2] == "") or
		(args[3] == nil) or (args[3] == "") then
		KarmaChatDefault("Missing arguments: <player> <note>");
		return;
	end

	local	oMember =  Karma_MemberList_GetObject(args[2]);
	if (oMember == nil) then
		KarmaChatDefault("Player <" .. args[2] .. "> unknown.");
		return;
	end

	local	sNote = args[3];
	local	i = 4;
	while (args[i]) do
		sNote = sNote .. " " .. args[i];
		i = i + 1;
	end

	Karma_MemberObject_SetPublicNotes(oMember, sNote);
	KarmaChatDefault("Public note for player <" .. args[2] .. "> reads now: " .. sNote);
end

function	Karma_SlashPubNoteGet(args)
	if (args[2] == nil) or (args[2] == "") then
		KarmaChatDefault("Missing argument: <player>");
		return;
	end

	local	oMember =  Karma_MemberList_GetObject(args[2]);
	if (oMember == nil) then
		KarmaChatDefault("Player <" .. args[2] .. "> unknown.");
		return;
	end

	local	sNote = Karma_MemberObject_GetPublicNotes(oMember);
	KarmaChatDefault("Public note for player <" .. args[2] .. "> is currently: " .. sNote);
end

function	Karma_SlashPubNoteClear(args)
	if (args[2] == nil) or (args[2] == "") then
		KarmaChatDefault("Missing argument: <player>");
		return;
	end

	local	oMember =  Karma_MemberList_GetObject(args[2]);
	if (oMember == nil) then
		KarmaChatDefault("Player <" .. args[2] .. "> unknown.");
		return;
	end

	local	sNote = Karma_MemberObject_GetPublicNotes(oMember);
	Karma_MemberObject_SetPublicNotes(oMember, "");
	KarmaChatDefault("Public note for player <" .. args[2] .. "> deleted. Previously, it was set to: " .. sNote);
end

function	Karma_SlashWIMModule(args)
	local	Set_b, Set_s;
	if (KarmaConfig.WIM == 1) then
		Set_s = "disabled";
		Set_b = 0;
	else
		Set_s = "enabled";
		Set_b = 1;
	end
	KarmaChatDefault("Karma's WIM module will be " .. Set_s .. " at next re-initialization.");
	KarmaConfig.WIM = Set_b;
end

function	Karma_SlashShareConfig(args)
	if ((args[2] == nil) or (args[2] == "")) then
		KarmaChatDefault("Insufficient arguments: <category> <value>.");
		KarmaChatDefault("For categories 'karma' or 'pubnote' (for public note), the following values are valid: 0 = never, 1 = always, 2 = via GUILD, 3 = with trusted people only (n.y.i.).");
		KarmaChatDefault("For category 'channel', 'value' is the name of the channel to use, or nothing to reset.");

		local	iKarma = 0;
		local	iPubNote = 0;
		local	sChan = "<none>";
		if (Karma_GetConfig(KARMA_CONFIG.SHARE_ONREQ_KARMA) ~= nil) then
			iKarma = Karma_GetConfig(KARMA_CONFIG.SHARE_ONREQ_KARMA);
		end
		if (Karma_GetConfig(KARMA_CONFIG.SHARE_ONREQ_PUBLICNOTE) ~= nil) then
			iPubNote = Karma_GetConfig(KARMA_CONFIG.SHARE_ONREQ_PUBLICNOTE);
		end
		if (Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME) ~= nil) then
			sChan = Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME);
		end
		KarmaChatDefault("Current settings: 'karma' -> " .. iKarma .. ", 'pubnote' -> " .. iPubNote .. ", 'channel' -> " .. sChan);
		return;
	end

	if ((args[2] ~= "karma") and (args[2] ~= "pubnote") and (args[2] ~= "channel")) then
		KarmaChatDefault("Category invalid: <" .. args[2] .. ">. ");
		return;
	end

	-- channel
	if (args[2] == "channel") then
		if ((args[3] == nil) or (args[3] == "")) then
			Karma_SetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME, nil);
			args[3] = "<none>";
		else
			Karma_SetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME, args[3]);
		end

		KarmaModuleLocal.Channels[0] = nil;
		KarmaChatDefault("Channel for sharing is now: " .. args[3]);
		return
	end


	-- karma, pubnote

	if (args[3] == nil) then
		args[3] = "";
	end
	local	iValue = tonumber(args[3]);
	if (iValue == 0) and (args[3] ~= "0") then
		KarmaChatDefault("Mode invalid: <" .. args[2] .. ">. Valid modes are 0, 1, 2, 3.");
		return;
	end

	local	sMode = "never";
	if (iValue == 1) then
		sMode = "always";
	elseif (iValue == 2) then
		sMode = "via GUILD";
	elseif (iValue == 3) then
		sMode = "with trusted people";
	end

	-- 0: never, 1: always, 2: via GUILD, 3: with trusted people only
	if (args[2] == "karma") then
		Karma_SetConfig(KARMA_CONFIG.SHARE_ONREQ_KARMA, iValue);
		KarmaChatDefault("Sharemode for Karma is now: " .. sMode);
	end
	if (args[2] == "pubnote") then
		Karma_SetConfig(KARMA_CONFIG.SHARE_ONREQ_PUBLICNOTE, iValue);
		KarmaChatDefault("Sharemode for public note is now: " .. sMode);
	end
end

function	Karma_SlashShareQuery(args, iCounter, internal)
	if (args[2] == nil) or (args[2] == "") or (args[3] == nil) or (args[3] == "") then
		if (internal == nil) then
			KarmaChatDefault("Missing arguments: <audience> <player>");
			KarmaChatDefault("<Audience> is $guild, #channel or another player. <Player> is the player you want information about.");
		end

		return false;
	end

	local	sChanKarma = Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME);
	local	bChan = strsub(args[2], 1, 1) == "#"
	if (bChan) then
		if (sChanKarma and (sChanKarma ~= "")) then
			args[2] = "#" .. sChanKarma;
		else
			return true;
		end
	end

	local	bMeta = strsub(args[2], 1, 1) == "$";
	if (internal == nil) then
		local	sAudience;
		if (bChan) then
			sAudience = "in " .. args[2];
		elseif (bMeta) then
			sAudience = "in " .. strlower(strsub(args[2], 2));
		else
			sAudience = args[2];
		end
		local	oMember = Karma_MemberList_GetObject(args[3]);
		if (oMember) then
			KarmaChatDefault("Asking " .. sAudience .. " about <" .. args[3] .. ">, results will be silently collected.");
		else
			KarmaChatDefault("Asking " .. sAudience .. " about <" .. args[3] .. ">.");
		end
	else
		KarmaChatDebug("Internal SSQ (internal = true)");
	end

	-- "?p" - request
	local	bResult = false;
	if (bChan) then
		local	KarmaChatFunc;
		if (internal == nil) then
			KarmaChatFunc = KarmaChatSecondaryFallbackDefault;
		else
			KarmaChatFunc = KarmaChatDebug;
		end
		local	sName = Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME);
		if (sName == nil) then
			KarmaChatFunc("Sharequery failed: No channel yet defined for " .. KARMA_ITSELF .. " to use for requests. You have to define one with '/" .. KARMA_CMDSELF .. " shareconfig channel <name>'.");
		else
			local	iID = GetChannelName(sName);
			if (iID == 0) then
				KarmaChatFunc("Sharequery failed: You have not joined channel #" .. sName .. " yet!");
			else
				if (KarmaModuleLocal.Channels[0]) then
					local	iChan = KarmaModuleLocal.Channels[0].Number; 
					if (iChan and (iChan > 0)) then		-- § = 194,167
						local	sDecReq = args[3];
						local	sEncReq = "";
						while (sDecReq ~= "") do
							local	iMulti;
							local	iRand = random(1, 5);
							if (iRand == 1) then
								sEncReq = sEncReq .. "+";
								iMulti = 121;	-- 17
							elseif (iRand == 2) then
								sEncReq = sEncReq .. "-";
								iMulti = 230;	-- 19
							elseif (iRand == 3) then
								sEncReq = sEncReq .. "!";
								iMulti = 190;	-- 23
							elseif (iRand == 4) then
								sEncReq = sEncReq .. "?";
								iMulti = 195;	-- 29
							else
								sEncReq = sEncReq .. "=";
								iMulti = 199;	-- 31
							end

							if (iMulti) then
								local	iVal = strbyte(sDecReq, 1, 1);
								if (iVal and iVal ~= 0) then
									sEncReq = sEncReq .. format("%03d", (iVal * iMulti) % 257);
								else
									sEncReq = "";
									sDecRec = "";
								end
							else
								sEncReq = "";
								sDecRec = "";
							end
							if (sDecReq ~="") then
								sDecReq = strsub(sDecReq, 2);
							end
						end
						if (sEncReq ~= "") then
							SendChatMessage("\194\167KARMA:?p1:" .. sEncReq, "CHANNEL", nil, iChan);
							bResult = true;
						else
							KarmaChatDefault("Oops! Error in encoding name <" .. args[3] .. ">. Please report this error back!");
						end
					else
						KarmaChatFunc("Sharequery failed: Channel #" .. sName .. " not recognized as private yet. Say something there!");
					end
				else
						KarmaChatFunc("Sharequery failed: Channel status of #" .. sName .. " unknown, waiting for more chatter.");
				end
			end
		end
	elseif (bMeta) then
		SendAddonMessage("KARMA", "?p1:" .. args[3], strupper(strsub(args[2], 2)));
		bResult = true;
	else
		SendAddonMessage("KARMA", "?p1:" .. args[3], "WHISPER", args[2]);
		bResult = true;
	end

	return bResult;
end

function	Karma_SlashRaid(args, iCounter)
	if (iCounter < 2) then
		KarmaChatDefault("Missing arguments: <option> <switch>");
		KarmaChatDefault("<Options> are: trackall, hidegroup. <Switches> are on/off/toggle.");
		return
	end

	local	sOutputsub = "currently ";

	local	tValue;
	if (iCounter == 3) then
		local	sSwitch = strlower(args[3]);
		if (sSwitch == "on") then
			tValue = 1;
		elseif (sSwitch == "off") then
			tValue = 0;
		elseif (sSwitch == "toggle") then
			tValue = -1;
		else
			KarmaChatDefault("Valid <switches> are on/off/toggle.");
			return
		end
	end

	local	sOutputsub = "currently ";
	if (tValue) then
		sOutputsub = "now ";
	end

	local	sKey, sOutput;
	local	sOption = strlower(args[2]);
	if (sOption == "trackall") then
		sKey = KARMA_CONFIG.RAID_TRACKALL;
		sOutput = "Tracking the whole raid is ";
	elseif (sOption == "hidegroup") then
		sKey = KARMA_CONFIG.RAID_NOGROUP;
		sOutput = "Hiding the group in raids is ";
	else
		KarmaChatDefault("Valid <options> are: trackall, hidegroup.");
		return
	end

	local	bEnabled = 1 == Karma_GetConfig(sKey);
	if (tValue) then
		if (tValue == -1) then
			bEnabled = not bEnabled;
		else
			bEnabled = tValue == 1;
		end

		if (bEnabled) then
			Karma_SetConfig(sKey, 1);
		else
			Karma_SetConfig(sKey, 0);
		end
	end

	local	sEnabled = "off";
	if (bEnabled) then
		sEnabled = "on";
	end

	KarmaChatDefault(sOutput .. sOutputsub .. sEnabled .. ".");
end

function	Karma_SlashDBSparse(args, iCounter)
	if (Karma_GetConfig(KARMA_CONFIG.DB_SPARSE) ~= 1) then	-- dbsparse
		KarmaChatDefault("DBSparse: Sparse tables mode is not enabled.");
		return
	end

	if ((args[2] == nil) or (args[2] == "")) then
		KarmaChatDefault("DBSparse: Missing parameter <character/pattern>. Valid parameters are e.g. Arwen, Ar* or *. If no star is at the end, the name must match exactly. If there is a star, the name must start exactly like the pattern.");
		return
	end

	local	bDrop = args[3] == "execute";
	if (bDrop) then
		KarmaChatDefault("DBSparse: Execute given, will *actually* delete tables without information!");
	else
		KarmaChatDefault("DBSparse: 2nd parameter 'execute' not given, only giving information about contents of tables.");
	end

	local	iDropped = KarmaObj.DB.SF.Sparsify(args[2], bDrop);
	if (iDropped > 0) then
		if (bDrop) then
			KarmaChatDefault("DBSparse: Dropped " .. iDropped .. " tables without information.");
		else
			KarmaChatDefault("DBSparse: Found " .. iDropped .. " tables without information.");
		end
	else
		KarmaChatDefault("DBSparse: Database is already sparse (for this server/faction).");
	end
end

function	Karma_SlashTracking(args, iCounter)
	if ((args[2] == nil) or (args[2] == "") or (args[3] == nil) or (args[3] == "")) then
		KarmaChatDefault("Missing arguments to command: <enable||disable||status> <quests||zones||regions||achievements>");
		return
	end

	local	sField;
	if (args[3] == "quests") then
		sField = KARMA_CONFIG.TRACK_DISABLEQUEST;
	elseif (args[3] == "zones") then
		sField = KARMA_CONFIG.TRACK_DISABLEZONE;
	elseif (args[3] == "regions") then
		sField = KARMA_CONFIG.TRACK_DISABLEREGION;
	elseif (args[3] == "achievements") then
		sField = KARMA_CONFIG.TRACK_DISABLEACHIEVEMENT;
	end
	if (sField == nil) then
		KarmaChatDefault("Second argument to command must be one of: <quests||zones||regions||achievements>");
		return
	end

	local	sFrag = "now";
	if (args[2] == "enable") then
		Karma_SetConfig(sField, 0);
	elseif (args[2] == "disable") then
		Karma_SetConfig(sField, 1);
	elseif (args[2] == "status") then
		sFrag = "currently";
	else
		KarmaChatDefault("First argument to command must be one of: <enable||disable||status>");
		return
	end

	local	value = Karma_GetConfig(sField);
	if (value == 1) then
		KarmaChatDefault("Tracking of <" .. args[3] .. "> is " .. sFrag .. " DISabled.");
	else
		KarmaChatDefault("Tracking of <" .. args[3] .. "> is " .. sFrag .. " enabled.");
	end
end

-----------------------------------------
-- Import/Export Database Commands
-----------------------------------------

function Karma_SlashExport(args)
	if (KARMATRANS_AVAILABLE ~= nil) then
		if (KARMATRANS_AVAILABLE == 0) then
			KarmaChatDefault("No export, KarmaTrans available but not fully initialized.");
			return;
		else
			KarmaExp = nil;
		end
	else
		KarmaData["_EXP_"] = nil;
	end

	if (args[2] ~= nil) and (args[2] ~= "") then
		local	lNames = {};
		if (args[2] == "*") then
			local	lMembers = KarmaObj.DB.SF.MemberListGet();
			local	BucketName, Bucket;
			for BucketName, Bucket in pairs(lMembers) do
				local	MemberName, MemberBucket;
				for MemberName, MemberBucket in pairs(Bucket) do
					table.insert(lNames, MemberName);
				end
			end
		elseif (strsub(args[2], 2, 1) == "*") then
			-- allow one bucket as export: A* = bucket["A"]
			local	lMembers = KarmaObj.DB.SF.MemberListGet();
			if (lMembers[strsub(args[2], 1, 1)] ~= nil) then
				local	MemberName, MemberBucket;
				for MemberName, MemberBucket in pairs(lMembers[strsub(args[2], 1, 1)]) do
					table.insert(lNames, MemberName);
				end
			end
		end
		KarmaChatDefault("Trying to export " .. #lNames .. " entries" .. KARMA_WINEL_FRAG_TRIDOTS);
		for Index, Member in pairs(lNames) do
			KarmaObj.DB.ExportOne(Member);
		end
		KarmaChatDefault("Export of " .. #lNames .. " entries completed.");
	else
		KarmaChatDefault("Removing export data.");
		KarmaData["_EXP_"] = nil;
	end
end

function Karma_SlashImport(args)
	KarmaObj.DB.Import(args);
end

function	Karma_SlashTransport()
	KarmaObj.DB.ImpExpCleanup();
end

------------------
------------------
------------------

function	Karma_PlayerIsInRaid()
	return (GetNumRaidMembers() > 0);
end

CommonRegionZoneAddCurrent = function(CurrentIsPvPRegion)
	local	CurrentRegionText = GetZoneText();
	local	CurrentRegionRealText = GetRealZoneText();

	local	CurrentZoneText = GetMinimapZoneText();
	local	CurrentZoneRealText = GetSubZoneText();

	local	CurrentIsInstance;
	if (CurrentIsPvPRegion == nil) and (Karma_ZoneChanged == 0) then
		local	bInInstance, sType = IsInInstance();
		if (bInInstance) then
			if (sType == "pvp") or (sType == "arena") then
				CurrentIsPvPRegion = 1;
			elseif (sType == "party") then
				CurrentIsInstance = 5;
			elseif (sType == "raid") then
				CurrentIsInstance = 10;
			end
		else
			CurrentIsInstance = 0;
		end
	end

	return CommonRegionZoneAdd(CurrentRegionText, CurrentZoneText, CurrentRegionRealText, CurrentZoneRealText, CurrentIsPvPRegion, CurrentIsInstance);
end

CommonRegionZoneAdd = function(RegionText, ZoneText, RegionRealText, ZoneRealText, IsPvPRegion, IsInstance)
	if (UnitIsDeadOrGhost("player")) then
		IsPvPRegion = nil;
		IsInstance  = nil;
	end

	local posX, posY = GetPlayerMapPosition("player");
	if (((posX == nil) or (posX == 0)) and ((posY == nil) or (posY == 0))) then
		--- not yet fully zoned, but not sure: old world dungeons *have* no map :-(
		if (not UnitOnTaxi("player") and not IsMounted("player") and not WorldMapFrame:IsShown()) then
			SetMapToCurrentZone();
		end
	end

	local	CommonRegionList = KarmaObj.DB.CG.RegionListGet();
	local	CommonZoneList = KarmaObj.DB.CG.ZoneListGet();

	local	CurrentRegionID = nil;
	local	CurrentRegionItem = nil;
	local	CurrentZoneID = nil;
	local	CurrentZoneItem = nil;
	if (CommonRegionList ~= nil) and (RegionText ~= nil) and (RegionText ~= "") then
		-- Region to Zone - List
		local Count = 0;
		for k, v in pairs(CommonRegionList) do
			if (v.Name == RegionText) then
				CurrentRegionID = k;
				break;
			end
			Count = Count + 1;
		end

		if (CurrentRegionID == nil) then
			CurrentRegionID = Count + 1;
			KOH.TableInit(CommonRegionList, CurrentRegionID);
		end

		CurrentRegionItem = CommonRegionList[CurrentRegionID];
		if CurrentRegionItem.Name == nil then
			CurrentRegionItem.Name = RegionText;
		end

		if (CurrentRegionItem.NameReal == nil) and (RegionRealText ~= nil) then
			CurrentRegionItem.NameReal = RegionRealText;
		end

		if (Karma_ZoneChanged == 0) then
			if (IsPvPRegion ~= CurrentRegionItem[KARMA_DB_L3_CR.ISPVPZONE]) then
		 		KarmaChatDebug("CommonRegionZoneAdd: IsPvPRegion(" .. RegionText .. ") => " .. Karma_NilToString(IsPvPRegion));
				CurrentRegionItem[KARMA_DB_L3_CR.ISPVPZONE] = IsPvPRegion;
			end

			if (IsInstance ~= nil) then
				local	OldValue = CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE] or "nil";
				if	(CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE] == nil) or
					(CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE] == 0) then
					CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE] = IsInstance;
				elseif (CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE] >= 5) then		-- only cast upwards...
					CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE] = max(CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE], IsInstance);
				end
				local	NewValue = CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE] or "nil";
				if (OldValue ~= NewValue) then
					KarmaChatDebug("Region.Type: " .. OldValue .. "->" .. NewValue);
				end
			end
		end

		KOH.TableInit(CurrentRegionItem, KARMA_DB_L3_CR.ZONEIDS);
	end

	if (CommonZoneList ~= nil) and (ZoneText ~= nil) and (ZoneText ~= "") then
		-- Zonelist
		local	Count = 0;
		for k, v in pairs(CommonZoneList) do
			if (v.Name == ZoneText) then
				CurrentZoneID = k;
				break;
			end
			Count = Count + 1;
		end

		if (CurrentZoneID == nil) then
			CurrentZoneID = Count + 1;
			KOH.TableInit(CommonZoneList, CurrentZoneID);
		end
		CurrentZoneItem = CommonZoneList[CurrentZoneID];
		if CurrentZoneItem.Name == nil then
			CurrentZoneItem.Name = ZoneText;
		end

		if (CurrentZoneItem.NameReal == nil) and (ZoneRealText ~= nil) then
			CurrentZoneItem.NameReal = ZoneRealText;
		end

		-- Zone to Region - Link
		if CurrentRegionItem ~= nil then
			if (CurrentZoneItem.RegionID == nil) and (CurrentRegionID ~= nil) then
				CurrentZoneItem.RegionID = CurrentRegionID;
			end

			-- add Zone to Region
			local Found = false;
			for k, v in pairs(CurrentRegionItem[KARMA_DB_L3_CR.ZONEIDS]) do
				if v == CurrentZoneID then
					Found = true;
					break;
				end
			end
			if not Found then
				table.insert(CurrentRegionItem[KARMA_DB_L3_CR.ZONEIDS], CurrentZoneID);
			end
		elseif (CurrentZoneItem.RegionID ~= nil) then
			CurrentRegionID = CurrentZoneItem.RegionID;
		end
	end

	if (KarmaTrans_LogRegionZone ~= nil) and (Karma_GetConfig(KARMA_CONFIG.DEBUG_ENABLED) == 1) then
		if (CurrentRegionItem == nil) and (CurrentRegionID ~= nil) then
			CurrentRegionItem = CommonRegionList[CurrentRegionID];
		end
		if (CurrentRegionItem ~= nil) and (CurrentZoneItem ~= nil) then
			KarmaTrans_LogRegionZone(CurrentRegionID, CurrentRegionItem.Name, CurrentZoneID,
				CurrentZoneItem.Name, CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE]);
		elseif (CurrentRegionItem == nil) and (CurrentZoneItem ~= nil) then
			KarmaTrans_LogRegionZone(CurrentRegionID, nil,                    CurrentZoneID,
				CurrentZoneItem.Name, nil);
		else
			KarmaTrans_LogRegionZone(CurrentRegionID, nil,                    CurrentZoneID,
				nil,                  nil);
		end
	end

	if ((Karma_ZoneChanged == 0) and (KarmaModuleLocal.RegionChangePrevious ~= RegionText)) then
		KarmaChatDebug("Region changed: " .. KarmaModuleLocal.RegionChangePrevious .. " -> " .. RegionText);
		local	bInInstance, sType = IsInInstance();
		KarmaChatDebug("Expected Type: pvp=" .. Karma_NilToString(IsPvPRegion) .. ", inst=" .. Karma_NilToString(IsInstance) .. "; UI: " .. Karma_NilToString(bInInstance) .. "/" .. Karma_NilToString(sType));
		if ((CurrentRegionItem ~= nil) and (CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE] ~= nil)) then
			local	sPvP = "";
			if (CurrentRegionItem[KARMA_DB_L3_CR.ISPVPZONE] == 1) then
				sPvP = "/pvp";
			end
			KarmaChatDebug("Current Type: " .. CurrentRegionItem[KARMA_DB_L3_CR.ZONETYPE] .. sPvP);
		end
		KarmaModuleLocal.RegionChangePrevious = RegionText;
	end

	return CurrentZoneID, CurrentRegionID;
end

CommonRegionListGet = function()
	return KarmaObj.DB.CG.RegionListGet();
end

CommonZoneListGet = function()
	return KarmaObj.DB.CG.ZoneListGet();
end

CommonQuestAdd = function(Quest, Faction, ExtID)
	return KarmaObj.DB.CF.QuestListAdd(Quest, Faction, ExtID);
end

CommonQuestInfoListGet = function()
	return KarmaObj.DB.CF.QuestInfosListGet(Quest, Faction, ExtID);
end

-- new: class id instead of class (for multilingual users)
Karma_IDToClass = function(ClassID)
	if (ClassID == nil) or (ClassID == 0) then
		KarmaChatDebug("Failed to translate ClassID " .. Karma_NilToString(ClassID) .. " to name. (1)");
		return "";
	end;

	if (type(ClassID) ~= "number") then
		KarmaChatDebug("ID2Class: Callstack >> " .. debugstack());
		return "";
	end

	if (ClassID > 0) then
		if     (ClassID == 1) then
			return KARMA_CLASS_DRUID_M;
		elseif (ClassID == 2) then
			return KARMA_CLASS_HUNTER_M;
		elseif (ClassID == 3) then
			return KARMA_CLASS_MAGE_M;
		elseif (ClassID == 4) then
			return KARMA_CLASS_PALADIN_M;
		elseif (ClassID == 5) then
			return KARMA_CLASS_PRIEST_M;
		elseif (ClassID == 6) then
			return KARMA_CLASS_ROGUE_M;
		elseif (ClassID == 7) then
			return KARMA_CLASS_SHAMAN_M;
		elseif (ClassID == 8) then
			return KARMA_CLASS_WARRIOR_M;
		elseif (ClassID == 9) then
			return KARMA_CLASS_WARLOCK_M;
		elseif (ClassID == 10) then
			return KARMA_CLASS_DEATHKNIGHT_M;
		end;
	else
		if     (ClassID == - 1) then
			return KARMA_CLASS_DRUID_F;
		elseif (ClassID == - 2) then
			return KARMA_CLASS_HUNTER_F;
		elseif (ClassID == - 3) then
			return KARMA_CLASS_MAGE_F;
		elseif (ClassID == - 4) then
			return KARMA_CLASS_PALADIN_F;
		elseif (ClassID == - 5) then
			return KARMA_CLASS_PRIEST_F;
		elseif (ClassID == - 6) then
			return KARMA_CLASS_ROGUE_F;
		elseif (ClassID == - 7) then
			return KARMA_CLASS_SHAMAN_F;
		elseif (ClassID == - 8) then
			return KARMA_CLASS_WARRIOR_F;
		elseif (ClassID == - 9) then
			return KARMA_CLASS_WARLOCK_F;
		elseif (ClassID == - 10) then
			return KARMA_CLASS_DEATHKNIGHT_F;
		end;
	end;

	KarmaChatDebug("Failed to translate ClassID " .. ClassID .. " to name. (2)");
	return "";
end;

Karma_ClassToID = function(ClassAsName)
	if     (ClassAsName == KARMA_CLASS_DRUID_M) then
		return 1;
	elseif (ClassAsName == KARMA_CLASS_HUNTER_M) then
		return 2;
	elseif (ClassAsName == KARMA_CLASS_MAGE_M) then
		return 3;
	elseif (ClassAsName == KARMA_CLASS_PALADIN_M) then
		return 4;
	elseif (ClassAsName == KARMA_CLASS_PRIEST_M) then
		return 5;
	elseif (ClassAsName == KARMA_CLASS_ROGUE_M) then
		return 6;
	elseif (ClassAsName == KARMA_CLASS_SHAMAN_M) then
		return 7;
	elseif (ClassAsName == KARMA_CLASS_WARRIOR_M) then
		return 8;
	elseif (ClassAsName == KARMA_CLASS_WARLOCK_M) then
		return 9;
	elseif (ClassAsName == KARMA_CLASS_DEATHKNIGHT_M) then
		return 10;
	end;

	if     (ClassAsName == KARMA_CLASS_DRUID_F) then
		return - 1;
	elseif (ClassAsName == KARMA_CLASS_HUNTER_F) then
		return - 2;
	elseif (ClassAsName == KARMA_CLASS_MAGE_F) then
		return - 3;
	elseif (ClassAsName == KARMA_CLASS_PALADIN_F) then
		return - 4;
	elseif (ClassAsName == KARMA_CLASS_PRIEST_F) then
		return - 5;
	elseif (ClassAsName == KARMA_CLASS_ROGUE_F) then
		return - 6;
	elseif (ClassAsName == KARMA_CLASS_SHAMAN_F) then
		return - 7;
	elseif (ClassAsName == KARMA_CLASS_WARRIOR_F) then
		return - 8;
	elseif (ClassAsName == KARMA_CLASS_WARLOCK_F) then
		return - 9;
	elseif (ClassAsName == KARMA_CLASS_DEATHKNIGHT_F) then
		return - 10;
	end;

	if (ClassAsName ~= nil) and (ClassAsName ~= "") then
		KarmaChatDebug("Failed to translate ClassName " .. ClassAsName .. " to ID.");
	end;

	return 0;
end;

--
--- two tab logic
--
local	KarmaWindow_Partitions =
		{
			[1] = {
				"KarmaWindow_CharSelection_DropDown",
				"KarmaWindow_TrackingData_Frame",
				"KarmaWindow_ListChoice_Area",
				"KarmaWindow_RegionList_EnclosingArea",
				"KarmaWindow_ZoneList_EnclosingArea",
				"KarmaWindow_QuestList_EnclosingArea",
				"KarmaWindow_AchievementList_EnclosingArea"
				},
			[2] = {
				"KarmaWindow_OtherData_Frame",
				"KarmaWindow_AltList_EnclosingArea",
				"KarmaWindow_NotesPublicBorder_Frame",
				"KarmaWindow_NotesPublicQuery_Button",
				"KarmaWindow_NotesPublicResults_Button",
				"KarmaWindow_NotesBorder_Frame"
				};
		};

function	KarmaWindow_SelectTab(arg)
	PanelTemplates_SetTab(KarmaWindow, arg);
	if (arg == 1) then
		local	key, value, frameobj;
		for key, value in pairs(KarmaWindow_Partitions[2]) do
			frameobj = getglobal(value);
			frameobj:Hide();
		end

		for key, value in pairs(KarmaWindow_Partitions[1]) do
			frameobj = getglobal(value);
			frameobj:Show();
		end

		KARMA_SELECTEDTAB = 1;

		KarmaWindow_Lists_SetAnchors();
	elseif (arg == 2) then
		local	key, value, frameobj;
		for key, value in pairs(KarmaWindow_Partitions[1]) do
			frameobj = getglobal(value);
			frameobj:Hide();
		end
		for key, value in pairs(KarmaWindow_Partitions[2]) do
			frameobj = getglobal(value);
			frameobj:Show();
		end

		KARMA_SELECTEDTAB = 2;
	end
end

function	KarmaWindow_OnLoad()
	-- create list buttons:
	local	FrameL = { "RegionList", "ZoneList", "QuestList", "AchievementList" };

	local	key, listname, i, sButton, oParent, sTemplate, oButton, sButtonPrev; 
	for key, listname in pairs(FrameL) do
		for i = 2, KARMA_MAINLISTS_SIZE do
			sButton = listname .. "_GlobalButton" .. tostring(i);
			oParent = getglobal("KarmaWindow_" .. listname .. "_Frame");
			sTemplate = listname .. "_GlobalButtonTemplate";
			oButton = CreateFrame("Button", sButton, oParent, sTemplate);
			oButton:SetID(i);
			sButtonPrev = listname .. "_GlobalButton" .. tostring(i - 1);
			oButton:SetPoint("TOPLEFT", sButtonPrev, "BOTTOMLEFT");
		end
	end

	local	AltButtonsL = { "KarmaValue", "Level", "Name" };
	listname = "AltList";
	local	btnname;
	for key, btnname in pairs(AltButtonsL) do
		for i = 2, KARMA_ALTLIST_SIZE do
			sButton = listname .. "_" .. btnname .. "Button" .. tostring(i);
			oParent = getglobal("KarmaWindow_" .. listname .. "_Frame");
			sTemplate = listname .. "_" .. btnname .. "ButtonTemplate";
			oButton = CreateFrame("Button", sButton, oParent, sTemplate);
			oButton:SetID(i);
			sButtonPrev = listname .. "_" .. btnname .. "Button" .. tostring(i - 1);
			oButton:SetPoint("TOPLEFT", sButtonPrev, "BOTTOMLEFT");
		end
	end

	PanelTemplates_SetNumTabs(KarmaWindow, 2);
	KarmaWindow_SelectTab(1);
end

--
--- list order and alignment on tab 1
--
function	KarmaWindow_Lists_SetAnchors()
	if (KARMA_SELECTEDTAB ~= 1) then
		return;
	end

	local	key, value, frameobj;
	local	ListsL = {};
	local	iCount = 0;
	for key, value in pairs(KarmaWindow_Partitions[1]) do
		if (strsub(value, strlen(value) - 17) == "List_EnclosingArea") then
			local	ListChar = strsub(value, 13, 13);
			if (ListChar ~= nil) and (ListChar ~= "")  then
				if (Karma_GetConfig(KARMA_CONFIG_MAINWND_LISTPREFIX .. ListChar) ~= 1) then
					frameobj = getglobal(value);
					frameobj:Hide();
				else
					tinsert(ListsL, value);
					iCount = iCount + 1;
				end
			end
		end
	end

	if (iCount == 0) then
		return;
	end

	-- todo: find out this value with UI-funcs:
	local	iWndSpace = 400;

	local	iListWidth = floor(iWndSpace / iCount);
	local	sPreviousFrame, sListname, listobj, btnobj, btntxtobj;
	for key, value in pairs(ListsL) do
		local	ListChar = strsub(value, 13, 13);
-- KarmaChatDebug("ListChar: " .. Karma_NilToString(ListChar));
		frameobj = getglobal(value);
		local	PointL = {};
		local	i, j;

--[[
		for i = 1, frameobj:GetNumPoints() do
			sPoint, sRelativeTo, sRelativePoint, iXOffset, iYOffset = frameobj:GetPoint(i)
			PointL[i] = {};
			PointL[i].P  = sPoint;
			PointL[i].RT = sRelativeTo;
			PointL[i].RP = sRelativePoint;
			PointL[i].XO = iXOffset;
			PointL[i].YO = iYOffset;

KarmaChatDebug(ListChar .. "L: " .. sPoint .. " -> " .. sRelativeTo:GetName() .. "." .. sRelativePoint .. " +{" .. iXOffset .. ", " .. iYOffset .. "}");
		end
]]--

		-- initially, all lists should be:
		-- TOPLEFT -> KarmaWindow_ListChoice_Area.TOPRIGHT +{0, -20}
		if (sPreviousFrame == nil) then
			frameobj:SetPoint("TOPLEFT", KarmaWindow_ListChoice_Area, "TOPRIGHT", 0, -20);
		else
			frameobj:SetPoint("TOPLEFT", sPreviousFrame, "TOPRIGHT");
		end

		frameobj:SetWidth(iListWidth);
		sListname = gsub(value, "EnclosingArea", "", 1)
		listobj = getglobal(sListname .. "Frame");
		if (listobj) then
			listobj:SetWidth(iListWidth);

			j = 1;
			sListname = strsub(sListname, 13);
			btnobj = getglobal(sListname .. "GlobalButton" .. j);
			if (btnobj == nil) then
KarmaChatDebug(ListChar .. "L: !" .. sListname .. "GlobalButton" .. j .. "?");
			end
			while (btnobj ~= nil) do
				btnobj:SetWidth(iListWidth - 30);
				btntxtobj = getglobal(sListname .. "GlobalButton" .. j .. "_Text");
				btntxtobj:SetWidth(iListWidth - 30);

				j = j + 1;
				btnobj = getglobal(sListname .. "GlobalButton" .. j);
			end
		end
		frameobj:Show();

		sPreviousFrame = value;
	end
end

function	KarmaWindow_OnUpdateEvent(iElapsed)
	local	iCurrent = KarmaModuleLocal.Timers.Update + iElapsed;
	if (iCurrent < 0.5) then
		KarmaModuleLocal.Timers.Update = iCurrent;
		return
	end

	KarmaModuleLocal.Timers.Update = 0;
	KarmaWindow_OnUpdateEventDo();
end

function	KarmaWindow_OnUpdateEventDo()
	local	TimeNow = GetTime();

	-- we have to delay the event, because regen is enabled just *before* the achievements are updated
	if (KarmaModuleLocal.PlayerRegenEnabledOrMobDied ~= nil) then
		if (TimeNow - KarmaModuleLocal.PlayerRegenEnabledOrMobDied > 2.5) then
			Karma_WhoAmIInit();
			if (WhoAmI) then
				KarmaModuleLocal.PlayerRegenEnabledOrMobDied = nil;
				KarmaObj.Achievements.UpdateTest(KARMA_PartyNames, WhoAmI);
			end
		end
		-- don't let anything else waste even a single CPU cycle,
		-- we want to be as close to PlayerRegen as possible!
		return
	end

	if (TimeNow - KarmaModuleLocal.Timers.CmdQ >= 0.3) then
		KarmaModuleLocal.Timers.CmdQ = TimeNow;
		local	CQSize = #Karma_CommandQueue;
		if (CQSize == 0) then
			if UnitIsAFK("player") and (UnitName("target") == nil) then
				if (Karma_GetConfig(KARMA_CONFIG.UPDATEWHILEAFK) == 1) then
					local	args = {};
					Karma_SlashUpdate(args);
				end
			end
		end

		if (Karma_Executing_Command == false) and (CQSize > 0) then
			local	elem = Karma_CommandQueue[1];
			local	i;
			if (CQSize > 1) then
				for i = 2, CQSize do
					if (Karma_CommandQueue[i] ~= nil) then
						Karma_CommandQueue[i-1] = Karma_CommandQueue[i];
					end
				end
				Karma_CommandQueue[CQSize] = nil;
			else
				Karma_CommandQueue = {};
			end

			if (elem ~= nil) then
				if (elem.func) then
					KarmaChatDebug(date("[%H:%M:%S]", time()) .. " Executing <" .. elem.sName .. "> (f)");
					elem.func(elem.args);
				elseif (elem.method) then
					KarmaChatDebug(date("[%H:%M:%S]", time()) .. " Executing <" .. elem.sName .. "> (m)");
					elem.method(elem);
				else
					KarmaChatDebug("Uuh. Function to command <" .. elem.sName .. "> non-existant?");
				end

				return
			end
		end
	end

	if (TimeNow - KARMA_LastMessageTime >= 1.5) then
		KARMA_LastMessageTime = TimeNow;
		local	CQSize = #Karma_MessageQueue;
		if (CQSize > 0) then
			local	elem = Karma_MessageQueue[1];
			local	i;
			if (CQSize > 1) then
				for i = 2, CQSize do
					if (Karma_MessageQueue[i] ~= nil) then
						Karma_MessageQueue[i-1] = Karma_MessageQueue[i];
					end
				end
				Karma_MessageQueue[CQSize] = nil;
			else
				Karma_MessageQueue = {};
			end

			if (elem ~= nil) then
				if (elem.func ~= nil) then
					elem.func(elem);
				end
				SendChatMessage(elem.text, elem.chattype, nil, elem.target);

				return
			end
		end
	end

	-- /who wasn't getting thru, retry.
	if (KARMA_FriendsFrameVisible ~= 1) and ((Karma_Executing_Who == nil) or (time() - Karma_Executing_Who > 5)) then
		if (Karma_WhoQueue[1] ~= nil) then
			local	iDelta = 180;
			if (KarmaModuleLocal.ExecutingWhoBroken) then
				iDelta = 60;
			end
			if (KarmaModuleLocal.ExecutingWhoSince and (time() - KarmaModuleLocal.ExecutingWhoSince > iDelta)) then
				if (KarmaModuleLocal.ExecutingWhoBroken) then
					KarmaChatSecondaryFallbackDefault("|cFFFF8080Reminder: /who still not working... ('/console reloadui'!)");
					KarmaModuleLocal.ExecutingWhoSince = time() - iDelta + 30;	-- => every 30s
				else
					KarmaChatDefault("|cFFFF2020WARNING: Failed to complete /who since three minutes. /who is seemingly BROKEN at this time. Please execute a '/reloadui' command as soon as possible. This error cannot be fixed by " .. KARMA_ITSELF .. " (and is usually triggered by WhoLib from ACE).");
				end
				Karma_Who_Process();	-- not ideal, but better than nothing...
				KarmaModuleLocal.ExecutingWhoBroken = true;
				return
			end
			if (Karma_WhoQueue[1].text ~= nil) then
				Karma_SendWho(Karma_WhoQueue[1].text, true);
				return
			end
		else
			KarmaModuleLocal.ExecutingWhoSince = nil;
			Karma_Executing_Who = nil;
		end
	end

	if (TimeNow - KARMA_LastUpdateTime >= 10) then
		KARMA_LastUpdateTime = TimeNow;
		if (KARMA_LOADED == 1) then
			if (Karma_GetConfig(KARMA_CONFIG.RAID_TRACKALL) == 1) and
			   (GetNumRaidMembers() > 0) then
				Karma_AddTimeToPartyMembers();
				KARMA_LastUpdateTime = KARMA_LastUpdateTime + 50;
			else
				Karma_AddTimeToPartyMembers();
			end
			KarmaWindow_Update();
			if (KarmaWindow2:IsVisible()) then
				KarmaWindow2_UpdateList1();
				KarmaWindow2_UpdateList2();
			end
		end
	end

	if (TimeNow - KARMA_TalentInspect.RequestQueueTimer >= 2) then
		KARMA_TalentInspect.RequestQueueTimer = TimeNow;
		Karma_AutofetchTalents();
	end

	if (TimeNow - KarmaModuleLocal.Timers.CronQ > 1) then
		KarmaModuleLocal.Timers.CronQ = TimeNow;
		if (#Karma_CronQueue ~= 0) then
			local	iCron, iCronMax = 0, #Karma_CronQueue;
			for iCron = 1, iCronMax do
				if (TimeNow > Karma_CronQueue[iCron].At) then
					local	oCron = Karma_CronQueue[iCron];
					if (iCron ~= iCronMax) then
						Karma_CronQueue[iCron] = Karma_CronQueue[iCronMax];
					end
					Karma_CronQueue[iCronMax] = nil;

					local	oCmdList = oCron.CmdList;
					local	iCmdMax = #oCmdList;
					local	iCmdTop = #Karma_CommandQueue;
					local	iCmd;
					for iCmd = 1, iCmdMax do
						Karma_CommandQueue[iCmdTop + iCmd] = oCmdList[iCmd];
						if (oCmdList[iCmd].sName) then
							KarmaChatDebug(date("[%H:%M:%S]", time()) .. " Activating <" .. oCmdList[iCmd].sName .. ">");
						else
							KarmaChatDebug(date("[%H:%M:%S]", time()) .. " Activating <unknown cmd>");
						end
					end

					return
				end
			end
		end
	end

	-- KARMA_EXCHANGE: only if nothing else is going on
	if (KARMA_EXCHANGE.ACK_AT ~= nil) and (KARMA_EXCHANGE.DONE == nil) then
		if	(#Karma_CommandQueue == 0) and (#Karma_MessageQueue == 0) and
			(KARMA_TalentInspect.RequiredCount == 0) and (KARMA_EXCHANGE.START_WITH ~= nil) then
			if	(TimeNow - KARMA_EXCHANGE.ACK_AT >= 0.5) and
				(TimeNow - KARMA_EXCHANGE.REQ_AT >= 1.0) then

				local	sRequest = "?x1:" .. KARMA_EXCHANGE.ACK_IS;
				
				KARMA_EXCHANGE.REQ_IS = KARMA_EXCHANGE.ACK_IS;
				KARMA_EXCHANGE.REQ_AT = GetTime();
			
				KARMA_EXCHANGE.ACK_IS = nil;
				KARMA_EXCHANGE.ACK_AT = nil;

				SendAddonMessage("KARMA", sRequest, "WHISPER", KARMA_EXCHANGE.START_WITH);
			end
		end
	end

	if (TimeNow - KarmaModuleLocal.AchievementCheckTerrorTimer >= 60) then
		KarmaModuleLocal.AchievementCheckTerrorTimer = TimeNow;
		if (KarmaModuleLocal.AchievementCheckTerrorCount > 0) then
			KarmaObj.Achievements.CheckTerrorQuery(KarmaModuleLocal.AchievementCheckTerrorList);
			if (next(KarmaModuleLocal.AchievementCheckTerrorList) == nil) then
				KarmaModuleLocal.AchievementCheckTerrorCount = 0;	-- left group etc.
			end
		end
	end

	if (Karma_ZoneChanged ~= 0) then
		if (time() - Karma_ZoneChanged > 15) then
			Karma_ZoneChanged = 0;
			CommonRegionZoneAddCurrent();
			Karma_AddZoneToPartyMember();
		end
	end
end

function	Karma_AddTip(sUnit)
--	Attempts to add Karma info to tooltip
	local	TT_Added = false;
	local	sSummary = "";
	local	sMember, sServer = UnitName(sUnit);
	local	oMember = Karma_MemberList_GetObject(sMember, sServer);
	local	bShiftReq = 1 == Karma_GetConfig(KARMA_CONFIG.TOOLTIP_SHIFTREQ);
	local	bShiftPressed = IsShiftKeyDown();
	if (oMember ~= nil) then
		local	sPlayed, bPlayed = "";
		do
			local	iSeconds;
			if (1 == Karma_GetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTOTAL)) then
				iSeconds = Karma_MemberObject_GetTotalTimePlayedSummedUp(oMember);
				sPlayed = " (total)";
			elseif (1 == Karma_GetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTHIS)) then
				iSeconds = Karma_MemberObject_GetTimePlayed(oMember);
				sPlayed = " (with current char)";
			end
			if (iSeconds) then
				if (iSeconds > 0) then
					bPlayed = true;
					sPlayed = " -- over " .. KOH.Duration2String(iSeconds) .. sPlayed;
				else
					sPlayed = " -- never joined" .. sPlayed;
				end
			end
		end

		if Karma_GetConfig(KARMA_CONFIG.TOOLTIP_KARMA) then
			local	iKarma = Karma_MemberObject_GetKarmaModified(oMember);
			iKarma = math.min(100, iKarma);
			local	iRed, iGreen, iBlue = Karma_Karma2Color(iKarma);
			local	sKarma = Karma_MemberObject_GetKarmaWithModifiers(oMember);
			sKarma = format("|c%s%s|r", ColourToString(1, iRed, iGreen, iBlue), sKarma);
			if (bShiftReq and not bShiftPressed) then
				if (iKarma ~= 50) then
					sSummary = sSummary .. sKarma;
					if (bPlayed) then
						sSummary = sSummary .. " Time";
					end
				end
			else
				sKarma = KARMA_ITSELF .. KARMA_WINEL_FRAG_COLONSPACE .. sKarma;
				GameTooltip:AddLine(sKarma .. sPlayed, 1, 1, 1);
				TT_Added = true;
			end
		end

		if (Karma_GetConfig(KARMA_CONFIG.TOOLTIP_SKILL) == 1) then
			local	iSkill = Karma_MemberObject_GetSkill(oMember);
			if (iSkill >= 0) and (KARMA_SKILL_LEVELS[iSkill]) then
				local	sSkill = KARMA_MSG_TIP_SKILL .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_SKILL_LEVELS[iSkill];
				if (bShiftReq and not bShiftPressed) then
					sSummary = sSummary .. " Skill";
				else
					GameTooltip:AddLine(sSkill, 0.9, 0.6, 0.9);
					TT_Added = true;
				end
			end
		end

		if (Karma_GetConfig(KARMA_CONFIG.TOOLTIP_TALENTS) == 1) then
			local	oLines, sSummarySub, iTimeOfTalents = KarmaObj.Talents.MemberObjToStringsObj(oMember, bShiftPressed);

			if (bShiftReq and not bShiftPressed) then
				sSummary = sSummary .. sSummarySub;
			else
				local	i;
				for i = 1, #oLines do
					if (iTimeOfTalents) then
						GameTooltip:AddLine("Talents as of " .. date(KARMA_DATEFORMAT, iTimeOfTalents) .. ":", 1, 1, 1);
						iTimeOfTalents = nil;
					end
					GameTooltip:AddLine(oLines[i], 1, 1, 1);
					TT_Added = true;
				end
			end
		end

		if (Karma_GetConfig(KARMA_CONFIG.TOOLTIP_ALTS) == 1) then
			local	iAltID = Karma_MemberObject_GetAltID(oMember);
			if (iAltID) and (iAltID >= 0) then
				local	sAlts = Karma_AltID2Names(iAltID, 5, KARMA_MSG_TIP_ALTS .. KARMA_WINEL_FRAG_COLONSPACE);
				if (sAlts) and (sAlts ~= "") then
					if (bShiftReq and not bShiftPressed) then
						sSummary = sSummary .. " Alts";
					else
						GameTooltip:AddLine(sAlts, 0.9, 0.6, 0.9);
						TT_Added = true;
					end
				end
			end
		end

		if Karma_GetConfig(KARMA_CONFIG.TOOLTIP_NOTES) then
			local	sNote = Karma_MemberObject_GetNotes(oMember);
			if (sNote) and (sNote ~= "") then
				if (bShiftReq and not bShiftPressed) then
					sSummary = sSummary .. " Notes";
				else
					local	sExtract = KarmaModuleLocal.Helper.ExtractHeader(sNote);
					GameTooltip:AddLine(sExtract, 0.7, 0.9, 0.7, 1);
					TT_Added = true;
				end
			end
		end

		if (bShiftReq and not bShiftPressed) and (sSummary ~= "") then
			sSummary = KARMA_ITSELF .. KARMA_WINEL_FRAG_COLONSPACE .. sSummary;
			GameTooltip:AddLine(sSummary, 0.8, 1, 0.8, 1);
			TT_Added = true;
		end
	end

	return TT_Added;
end

function	Karma_IntializePlayerObject()
	local	oPlayer = Karma_GetPlayerObject();

	Karma_FieldInitialize(oPlayer, KARMA_DB_L5_RRFFC.PLAYED, 0);
	Karma_FieldInitialize(oPlayer, KARMA_DB_L5_RRFFC.PLAYEDPVP, 0);
	Karma_FieldInitialize(oPlayer, KARMA_DB_L5_RRFFC.PLAYEDLAST, 0);
	oPlayer[KARMA_DB_L5_RRFFC.PLAYEDLAST] = GetTime();
end

function	Karma_GetPlayerObject(char)
	KarmaObj.ProfileStart("Karma_GetPlayerObject");

	if (char == nil) then
		char = UnitName("player");
	end
	local	lCharacter = KarmaObj.DB.SF.CharacterListGet();
	local	oPlayer = lCharacter[char];

	KarmaObj.ProfileStop("Karma_GetPlayerObject");
	return oPlayer;
end

-----------------------------------------
--	Cacheing routines
-----------------------------------------
function	Karma_MemberList_ResetMemberNamesCache()
	KARMA_NamesSortedAlpha = nil;
	KARMA_NamesSortedCustom = nil;
end

function	Karma_MemberList_CreateMemberNamesCache()
	KARMA_NamesSortedAlpha = {};
	KARMA_NamesSortedCustom = {};

	local	MemberNames = {};
	local	lMembers = KarmaObj.DB.SF.MemberListGet();
	local	iNumEntries = getn(lMembers);
	local	BucketValue, sBucketName;

	local	i = 0;
	local	FilterLenTotal;

	local	flPattern, flName, flClass, flLevelFrom, flLevelTo, flKarmaFrom, flKarmaTo;
	local	flJoinedAfter, flJoinedBefore, flNotes, flPublic, flGuild, flInstance;

	if KARMA_Filter.Total == nil then
		FilterLenTotal = 0;
	else
		FilterLenTotal = strlen(KARMA_Filter.Total);

		flPattern = 0;
		if KARMA_Filter.Pattern ~= nil then
			flPattern = strlen(KARMA_Filter.Pattern);
		end
		flName = 0;
		if KARMA_Filter.Name ~= nil then
			flName = strlen(KARMA_Filter.Name);
		end
		flClass = 0;
		if KARMA_Filter.Class ~= nil then
			flClass = strlen(KARMA_Filter.Class);
		end
		flLevelTo = 0;
		if KARMA_Filter.LevelTo ~= nil then
			flLevelTo = KARMA_Filter.LevelTo;
		end
		flLevelFrom = 0;
		if KARMA_Filter.LevelFrom ~= nil then
			flLevelFrom = KARMA_Filter.LevelFrom;
		end
		flKarmaFrom = 0;
		if KARMA_Filter.KarmaFrom ~= nil then
			flKarmaFrom = KARMA_Filter.KarmaFrom;
		end
		flKarmaTo = 0;
		if KARMA_Filter.KarmaTo ~= nil then
			flKarmaTo = KARMA_Filter.KarmaTo;
		end
		flJoinedAfter = 0;
		if KARMA_Filter.JoinedAfter ~= nil then
			flJoinedAfter = KARMA_Filter.JoinedAfter;
		end
		flJoinedBefore = 0;
		if KARMA_Filter.JoinedBefore ~= nil then
			flJoinedBefore = KARMA_Filter.JoinedBefore;
		end
		flNotes = 0;
		if KARMA_Filter.Notes ~= nil then
			flNotes = strlen(KARMA_Filter.Notes);
		end
		flPublic = 0;
		if KARMA_Filter.Public ~= nil then
			flPublic = strlen(KARMA_Filter.Public);
		end
		flGuild = 0;
		if KARMA_Filter.Guild ~= nil then
			flGuild = strlen(KARMA_Filter.Guild);
		end
		flInstance = 0;
		if KARMA_Filter.Instance ~= nil then
			flInstance = strlen(KARMA_Filter.Instance);
		end
	end

	local	EntryAdd;
	local	Once = 5;
	for sBucketName, BucketValue in pairs(lMembers) do
		for key, value in pairs(BucketValue) do
			EntryAdd = 1;
			if FilterLenTotal > 0 then
				if flPattern > 0 then
					local	keyasascii = KarmaObj.StringToASCII(key);
					if (not string.find(keyasascii, KARMA_Filter.Pattern, 1, true)) then
						EntryAdd = 0;
					end
-- DEBUG>>
--					local	ck = strsub(key, 1, 1);
--					if (ck < 'A') or (ck > 'Z') then
--						KarmaChatDebug("FilterName: Filter = < " .. KARMA_Filter.Pattern .. " > , Key = < " .. key .. " > , AscKey = < " .. keyasascii .. " > , EntryAdd = " .. EntryAdd);
--					end
-- <<DEBUG
				end
				if flName > 0 then
					if (1 ~= string.find(key, KARMA_Filter.Name, 1, true)) then
						EntryAdd = 0;
					end
				end
				if flClass > 0 then
					local vClass = nil;
					-- if ID is set...
					if (type(value[KARMA_DB_L5_RRFFM.CLASS_ID]) == "number") then
						-- ... to a real value ...
						if (value[KARMA_DB_L5_RRFFM.CLASS_ID] ~= 0) then
							local vClsFrmID = Karma_IDToClass(value[KARMA_DB_L5_RRFFM.CLASS_ID]);
							-- ... and we can convert it: assign
							if (vClsFromID ~= "") then
								vClass = vClsFromID;
							end;
						end;
					end;
					-- ID not set, invalid or inconvertible
					if (vClass == nil) then
						vClass = value[KARMA_DB_L5_RRFFM.CLASS];
					end;
--					if (Once == 1) then
--						KarmaChatDefault("flClass > 0: vClass = " .. vClass .. ", K_FC = " .. KARMA_Filter.Class);
--					end
					if (vClass ~= nil) then
						if (vClass ~= "") then
							if 1 ~= string.find(vClass, KARMA_Filter.Class, 1, true) then
								EntryAdd = 0;
							end
						elseif 1 ~= string.find(KARMA_UNKNOWN, KARMA_Filter.Class, 1, true) then
							EntryAdd = 0;
						end
					end
				end
				if (flLevelFrom > 0) or (flLevelTo > 0) then
					local vLevel = value[KARMA_DB_L5_RRFFM.LEVEL];
--					if (Once == 1) then
--						KarmaChatDefault("flLevelFrom + flLevelTo > 0: vLevel = " .. vLevel
--														.. ", K_FLF = " .. Karma_NilToString(KARMA_Filter.LevelFrom)
--														.. ", K_FLT = " .. Karma_NilToString(KARMA_Filter.LevelTo));
--					end
					if (vLevel ~= nil) then
						if (vLevel > 0) then
							if (flLevelFrom > 0) and (KARMA_Filter.LevelFrom > vLevel) then
								EntryAdd = 0;
							end
							if (flLevelTo > 0) and (KARMA_Filter.LevelTo < vLevel) then
								EntryAdd = 0;
							end
						end
					end
				end
				if (flKarmaFrom > 0) or (flKarmaTo > 0) then
					local vKarma = Karma_MemberObject_GetKarmaModified(value);
--					if (Once == 1) then
--						KarmaChatDefault("flKarmaFrom + flKarmaTo > 0: vKarma = " .. vKarma
--														.. ", K_FKF = " .. Karma_NilToString(KARMA_Filter.KarmaFrom)
--														.. ", K_FKT = " .. Karma_NilToString(KARMA_Filter.KarmaTo));
--					end
					if (vKarma ~= nil) then
						if (vKarma > 0) then
							if (flKarmaFrom > 0) and (KARMA_Filter.KarmaFrom > vKarma) then
								EntryAdd = 0;
							end
							if (flKarmaTo > 0) and (KARMA_Filter.KarmaTo < vKarma) then
								EntryAdd = 0;
							end
						end
					end
				end
				if ((flJoinedAfter ~= 0) or (flJoinedBefore ~= 0)) then
					local	vJoined = value[KARMA_DB_L5_RRFFM_JOINEDLAST_TIME];
					if (vJoined ~= nil) then
--						if (Once > 0) then
--							KarmaChatDebug("flJoined* set: vJoined = " .. vJoined .. ", K_FJ = " ..
--								Karma_NilToString(KARMA_Filter.JoinedAfter) .. " -> " .. Karma_NilToString(KARMA_Filter.JoinedBefore));
--						end
						local	tNow = time();
						if ((flJoinedAfter < 0) and (tNow + (flJoinedAfter * 86400) > vJoined)) then
							EntryAdd = 0;
						elseif ((flJoinedAfter > 0) and (flJoinedAfter > vJoined)) then
							EntryAdd = 0;
						end
						if ((flJoinedBefore < 0) and (tNow + (flJoinedBefore * 86400) < vJoined)) then
							EntryAdd = 0;
						elseif ((flJoinedBefore > 0) and (flJoinedBefore < vJoined)) then
							EntryAdd = 0;
						end
					else
						EntryAdd = 0;
					end
				end
				if flNotes > 0 then
					local vNotes = value[KARMA_DB_L5_RRFFM_NOTES];
--					if (Once > 0) then
--						KarmaChatDefault("flNotes > 0: vNotes = " .. vNotes .. ", K_FC = " .. KARMA_Filter.Notes);
--					end
					if (vNotes ~= nil) then
						if nil == strfind(vNotes, KARMA_Filter.Notes) then
							EntryAdd = 0;
						end
					else
						EntryAdd = 0;
					end
				end
				if flPublic > 0 then
					local vPublic = value[KARMA_DB_L5_RRFFM_PUBLIC_NOTES];
--					if (Once == 1) then
--						KarmaChatDefault("flPublic > 0: vPublic = " .. vPublic .. ", K_FC = " .. KARMA_Filter.Public);
--					end
					if (vPublic ~= nil) then
						if nil == strfind(vPublic, KARMA_Filter.Public) then
							EntryAdd = 0;
						end
					else
						EntryAdd = 0;
					end
				end
				if flGuild > 0 then
					local vGuild = value[KARMA_DB_L5_RRFFM.GUILD];
--					if (Once == 1) then
--						KarmaChatDefault("flPublic > 0: vPublic = " .. vPublic .. ", K_FC = " .. KARMA_Filter.Public);
--					end
					if ((vGuild ~= nil) and (vGuild ~= "")) then
						if nil == strfind(vGuild, KARMA_Filter.Guild) then
							EntryAdd = 0;
						end
					elseif (KARMA_Filter.Guild ~= KarmaModuleLocal.Guildless) then
						EntryAdd = 0;
					end
				end
				if flInstance > 0 then
					-- worst of all filters... must walk over instance list
					if not KarmaObj.DB.JoinedInInstance(value, KARMA_CURRENTCHAR, KARMA_Filter.Instance) then
						EntryAdd = 0;
					end
				end

				if (Once > 0) then
					Once = Once - 1;
				end
			end
			if EntryAdd == 0 then
				if KARMA_CURRENTMEMBER ~= nil then
					if key == KARMA_CURRENTMEMBER then
						EntryAdd = 1;
					end
				end
			end
			if EntryAdd == 1 then
				MemberNames[i] = key;
				i = i + 1;
			end
		end
	end
	iNumEntries = i;
	KARMA_NamesSortedAlpha = KOH.AlphaBucketSort(MemberNames);
	KARMA_NamesSortedCustom = Karma_MemberFieldNumericSort(KARMA_NamesSortedAlpha);
end

local	function	Karma_CleanupRegions(oMember)
	local	CommonRegionList = KarmaObj.DB.CG.RegionListGet();

	if (type(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) == "table") then
		local	sPlayer, oPlayer;
		for sPlayer, oPlayer in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
			if (type(oPlayer[KARMA_DB_L6_RRFFMCC_REGIONLIST]) == "table") then
				KarmaChatDebug("Checking regionlist for " .. sPlayer .. "...");

				local	iRegion, oRegion;
				for iRegion, oRegion in pairs(oPlayer[KARMA_DB_L6_RRFFMCC_REGIONLIST]) do
					local	sName = CommonRegionList[oRegion[KARMA_DB_L7_RRFFMCCRR_ID]].Name;
					KarmaChatDebug("Checking list of region " .. sName .. "...");

					local	iDay, oDay, iCount;
					iCount = 0;
					for iDay, oDay in pairs(oRegion[KARMA_DB_L7_RRFFMCCRR_PLAYEDDAYS]) do
						iCount = iCount + 1;
						local	iStart = oDay[KARMA_DB_L8_RRFFMCCRRD_START];
						local	iEnd = oDay[KARMA_DB_L8_RRFFMCCRRD_END];
						if (iStart and iEnd and (time() - iEnd > 87600)) then
							if (abs(iEnd - iStart) < 30) then
								iCount = iCount - 1;
								KarmaChatDebug("Killing flakey entry [" .. sName .. "]: " .. date("%Y-%m-%d %H:%M", iStart) .. " " .. KOH.Duration2String(math.abs(iEnd - iStart)));
								oRegion[KARMA_DB_L7_RRFFMCCRR_PLAYEDDAYS][iDay] = nil;
							end
						end
					end

					if (iCount == 0) then
						KarmaChatDebug("Nothing left in regionlist for " .. sName .. "... dropping entirely.");
						oPlayer[KARMA_DB_L6_RRFFMCC_REGIONLIST][iRegion] = nil;
					end
				end
			else
				KarmaChatDebug("No regionlist for " .. sPlayer .. " yet...");
			end
		end
	end
end

function	Karma_MemberList_CreatePartyNamesCache()
	local	i = 0;
	local	VerAlreadyReq = 0;

	local	KARMA_PartyNamesOld = {};
	local	key, value;
	for key, value in pairs(KARMA_PartyNames) do
		KARMA_PartyNamesOld[key] = 1;
	end
	value = nil;

	KARMA_PartyNames = {};
	local	sUnit, sName, sServer, sCombined, bHaveUnknown;

	Karma_WhoAmIInit();

	local	iMax = GetNumPartyMembers();
	local	sBase = "party";
	if (GetNumRaidMembers() > 0) then
		if (Karma_GetConfig(KARMA_CONFIG.RAID_TRACKALL) == 1) then
			iMax = GetNumRaidMembers();
			sBase = "raid";
		elseif (Karma_GetConfig(KARMA_CONFIG.RAID_NOGROUP) == 1) then
			return
		end
	end

	if ((iMax > 0) and (KarmaModuleLocal.WarnTrackingOnce == nil)) then
		if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEQUEST) == 1) then
			KarmaChatDefault("|cFFFF2020Quest tracking is currently DISabled.|r");
		end
		if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEZONE) == 1) then
			KarmaChatDefault("|cFFFF2020Zone tracking is currently DISabled.|r");
		end
		if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEREGION) == 1) then
			KarmaChatDefault("|cFFFF2020Region (= dungeon) tracking is currently DISabled.|r");
		end
		if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEACHIEVEMENT) == 1) then
			KarmaChatDefault("|cFFFF2020Achievement tracking is currently DISabled.|r");
		end

		KarmaModuleLocal.WarnTrackingOnce = 1;
	end

	local	iNow = time();
	for i = 1, iMax do
		sUnit = sBase .. i;
		sName, sServer = UnitName(sUnit);
		if (sName ~= nil) and (sName ~= WhoAmI) then
			-- Unknown or information not yet available (e.g. when joining a 40 player raid)
			if  ((sName == KARMA_UNKNOWN) or (UnitHealthMax(sUnit) == 1)) then
				bHaveUnknown = true;
			end

			sCombined = sName;
			if (sServer) and (sServer ~= "") then
				sCombined = sName .. "@" .. sServer;
			end

			local	iCC, sReason = Karma_MemberList_CollisionCheck(sCombined, sUnit);
			if (iCC == 1) then
				if (sName ~= KARMA_UNKNOWN) then
					KarmaChatDefault("|cFFFF4040WARNING!|r Cannot add or change any information for >" .. KOH.Name2Clickable(sCombined) .. "< : " .. sReason .. "! Either do a '" .. KARMA_CMDSELF .. " forceupdate " .. sCombined .. "' or a '" .. KARMA_CMDSELF .. " forcenew " .. sCombined .. "'!", true);
				end
				KARMA_PartyNames[sCombined] = nil;
			else
				Karma_MemberList_Add(sCombined, true);
				Karma_MemberList_Update(sCombined);
				KARMA_PartyNames[sCombined] = Karma_MemberList_GetObject(sCombined);
				if (KARMA_OtherInfos[sCombined] == nil) then
					Karma_CleanupRegions(KARMA_PartyNames[sCombined]);
					KARMA_OtherInfos[sCombined] = {};
				end

				if (KARMA_OtherInfos[sCombined].ver) then
					VerAlreadyReq = VerAlreadyReq + 1;
				end

				-- TODO: switch to disable this
				if (KARMA_OtherInfos[sCombined].Queried == nil) then
					KARMA_OtherInfos[sCombined].Queried = 0;
					Karma_QueueCommandShareQuery(sCombined);
				end

				if (sName ~= KARMA_UNKNOWN) then
					local	iTime = 0;
					if (KARMA_PartyNames[sCombined][KARMA_DB_L5_RRFFM_TALENTTREE] ~= nil) then
						iTime = KARMA_PartyNames[sCombined][KARMA_DB_L5_RRFFM_TALENTTREE]["Time"];
					end
	
					-- if most recent update is more than 12 hours old...
					if (iNow - iTime) > 43200 then
						KARMA_TalentInspect.RequiredList[sUnit] = sCombined;
					end

					if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEACHIEVEMENT) ~= 1) then
						local	iUpdate = 0;
						if (KARMA_PartyNames[sCombined][KARMA_DB_L5_RRFFM_TERROR] ~= nil) then
							iUpdate = KARMA_PartyNames[sCombined][KARMA_DB_L5_RRFFM_TERROR].Updated;
						end
						if (iUpdate and (iNow - iUpdate > 43200)) then
							KarmaModuleLocal.AchievementCheckTerrorList[sUnit] = sCombined;
						end
					end
				end
			end
		end
	end

	KARMA_TalentInspect.RequiredCount = 0;
	for sUnit, sName in pairs(KARMA_TalentInspect.RequiredList) do
		KARMA_TalentInspect.RequiredCount = KARMA_TalentInspect.RequiredCount + 1;
	end
	KarmaModuleLocal.AchievementCheckTerrorCount = 0;
	for sUnit, sName in pairs(KarmaModuleLocal.AchievementCheckTerrorList) do
		KarmaModuleLocal.AchievementCheckTerrorCount = KarmaModuleLocal.AchievementCheckTerrorCount + 1;
	end

	local	bPartyChanged;
	for key, value in pairs(KARMA_PartyNames) do
		if (KARMA_PartyNamesOld[key] ~= 1) then
			bPartyChanged = true;
		end
	end

	if (bPartyChanged) and (iMax > 0) then
		if (VerAlreadyReq < iMax) then
			if (GetRealNumRaidMembers() > 0) then
				KarmaModuleLocal.Command.VersionQueryQueue("?v1", "RAID");
			elseif (GetRealNumPartyMembers() > 0) then
				KarmaModuleLocal.Command.VersionQueryQueue("?v1", "PARTY");
			end
		end

		KARMA_TalentInspect.OtherFramesWarn = 1;

		local	bWarn, iWarnLevel;
		if (Karma_GetConfig(KARMA_CONFIG.JOINWARN_ENABLED) == 1) then
			iWarnLevel = Karma_GetConfig(KARMA_CONFIG.JOINWARN_THRESHOLD);
		end
		if (iWarnLevel) then
			iWarnLevel = tonumber(iWarnLevel);
			for key, value in pairs(KARMA_PartyNames) do
				local	iKarma = Karma_MemberObject_GetKarmaModified(KARMA_PartyNames[key]);
				if (iKarma) and (iKarma < iWarnLevel) and (KARMA_OtherInfos[key].warn == nil) then
					KarmaChatDefault("|cFFFF4040" .. KARMA_MSG_PARTYJOINED_LOWKARMA1 .. KARMA_WINEL_FRAG_COLONSPACE
						.. key .. KARMA_MSG_PARTYJOINED_LOWKARMA2 .. iKarma
						.. KARMA_MSG_PARTYJOINED_LOWKARMA3 .. iWarnLevel .. KARMA_MSG_PARTYJOINED_LOWKARMA4, true);
					KARMA_OtherInfos[key].warn = 1;
					bWarn = true;
				end
			end
		end
		if (bWarn) then
			PlaySoundFile("Sound\\Creature\\HoundmasterLoksey\\HoundmasterLokseyAggro01.wav");
		end
	end

	if ((KARMA_CURRENTLIST == 2) and (sBase == "raid")) then
		Karma_MemberList_ResetMemberNamesCache();
	end

	if (bHaveUnknown) then
		KarmaChatDebug("Got an *Unknown* as party member. Queueing a second call to CreatePartyNamesCache in 10 seconds...");
		Karma_Queue_ReCreatePartyNamesCache();
	end
end

function	Karma_Queue_ReCreatePartyNamesCache()
	-- sometimes we get an "Unknwon" and this is then wrongly assigned until the party changes!
	-- so: delayed update to cache

	-- now also called regularly instead of Create, because of the update mechanism of Blizzard to send events as 0, 1, 2, ... n as party size
	-- therefore, check if already in progress:
	local	i, iMax;
	iMax = getn(Karma_CommandQueue);
	for i = iMax, 1, -1 do
		if (Karma_CommandQueue[i].sName == "CreatePartyNamesCache") then
			KarmaChatDebug("Already queued a CPNC, skipping additional.");
			return
		end
	end

	local	oEntry = {};
	oEntry.At = GetTime() + 10;
	oEntry.CmdList = {};
	oEntry.CmdList[1] = { sName = "CreatePartyNamesCache", func = Karma_MemberList_CreatePartyNamesCache, args = {} };

	Karma_CronQueue[#Karma_CronQueue + 1] = oEntry;
end

function	Karma_GetQuestObjectives(qIndex, qContainer, qForce)
	if 	(qIndex == nil) or (qContainer == nil) or
		((KARMA_QExCreate == 0) and (qForce == nil)) then
		return;
	end

	if (KARMA_QExInitDone == 0) then
		-- WoW is *not* properly intializing objectives without opening the QLog :(
		-- ToggleQuestLog();
		QuestLog_OnShow();
		QuestLog_OnHide();
		KARMA_QExInitDone = 1;
	end

	if (KARMA_QExCreateLog > qIndex) then
		KarmaChatDebug("K_GQO: >> qIndex = " .. qIndex);
	end

	qContainer.objectives = nil;

	local qTotalProgress = 0;
	local qObjectiveCount = GetNumQuestLeaderBoards(qIndex);
	if qObjectiveCount then
		if (qObjectiveCount > 0) then
			qContainer.objectives = {};

			local qObjective;
			for qObjective = 1, qObjectiveCount do
				local	qdesc, qtype, qdone = GetQuestLogLeaderBoard(qObjective, qIndex);
				qContainer.objectives[qObjective] = {};
				qContainer.objectives[qObjective].desc = qdesc;
				qContainer.objectives[qObjective].type = qtype;
				if (qdone == nil) then
					qdone = 0;
				end
				qContainer.objectives[qObjective].done = qdone;
				local qProgress = 0;
				if (qdone == 1) then
					qProgress = 100;
				end

				-- try to find a ": <num>/<num>"...
				-- item, monster: obvious
				-- object: e.g. Burning Steppes quests (e.g. Broodling Essence)
				if (qtype == "item") or (qtype == "object") or (qtype == "monster") then
					local colonpos = strfind(qdesc, ":");
					if (colonpos ~= nil) then
						local slashpos = strfind(qdesc, "/", colonpos);
						if (slashpos ~= nil) then
							local sCountCurr = strsub(qdesc, colonpos + 1, slashpos - 1);
							local sCountTotal = strsub(qdesc, slashpos + 1);
							local iCountCurr = tonumber(sCountCurr);
							local iCountTotal = tonumber(sCountTotal);
							if (iCountCurr ~= nil) and (iCountTotal ~= nil) and (iCountTotal > 0) then
								qProgress = ceil(100 * iCountCurr / iCountTotal);
							end
						end
					end
				end

				qContainer.objectives[qObjective].progress = qProgress;
				qTotalProgress = qTotalProgress + qProgress;
			end
		end
	end

	qContainer.totalProgress = qTotalProgress;


	if (KARMA_QExCreateLog > qIndex) then
		KarmaChatDebug("K_GQO: << qIndex = " .. qIndex);
	end
end

function	Karma_CreateQuestCache(force, Switch1, Switch2, Switch3)
	KarmaObj.ProfileStart("Karma_CreateQuestCache");

	if (Switch1 ~= nil) then
		KARMA_QExCreate = Switch1;
		if (KARMA_QEx_NumPartyMembers == 0) then
			KARMA_QEx_NumPartyMembers = 1;
		end
		KarmaChatDebug("K_CQC: QExC <- 50, QEx_NPM > 0");
	end
	if (Switch2 ~= nil) then
		KARMA_QExCreateLog = Switch2;
		KarmaChatDebug("K_CQC: QExCL <- 50");
	end
	if (Switch3 ~= nil) then
		KARMA_QExUpdate = Switch3;
		KarmaChatDebug("K_CQC: QExU <- 50");
	end

	local	iOldTotal, iOldDaily, iOldCompleted, k, v = 0, 0, 0;
	for k, v in pairs(KARMA_QuestCache) do
		iOldTotal = iOldTotal + 1;
		if (v.daily == 1) then
			iOldDaily = iOldDaily + 1;
		end
		if (v.complete == 1) then
			iOldCompleted = iOldCompleted + 1;
		end
	end

	-- incredible often the QL refreshes like mad for no particular reason... stop that.
	-- force it down to .2s delays
	local	gtSeconds = ceil(GetTime() * 5);
	if (KARMA_QuestCache_LastUpdated + 5 > gtSeconds) then
		if (force ~= 1) then
			KarmaObj.ProfileStop("Karma_CreateQuestCache");
			return;
		end
	end

	-- first, check for collapsed entries and WARN
	local	iNumEntries = GetNumQuestLogEntries();
	local	previousIsHeader = nil;
	local	Warn = false;
	local	iNumQuests = 0;
	local	i;
	local	sWarnComp = "";
	for i = 1, iNumEntries do
		local	questLogTitleText, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(i);
		if (isHeader == 1) then
			sWarnComp = sWarnComp .. "H";
			if (previousIsHeader == 1) then
				Warn = true;
			end
		else
			sWarnComp = sWarnComp .. "Q";
		end
		if (isHeader ~= 1) then
			iNumQuests = iNumQuests + 1;
		end
		previousIsHeader = isHeader;
	end
	-- only last section collapsed?
	if (previousIsHeader == 1) then
		Warn = true;
	end

	if (force ~= 1) then
		-- count same?
		if (KARMA_QuestCache_LastQLEC == iNumQuests) then
			-- same count, do nothing
			KarmaObj.ProfileStop("Karma_CreateQuestCache");
			return
		end
		-- only partial info currently?
		if Warn and (KARMA_QuestCache_LastQLEC > iNumQuests) then
			-- something is collapsed and we got more in cache
			-- => assume cache is more correct
			KarmaObj.ProfileStop("Karma_CreateQuestCache");
			return
		end
	end

	-- should go into UI...
	if Karma_GetConfig(KARMA_CONFIG.QUESTWARNCOLLAPSED) == 0 then
		if Warn then
			Warn = KARMA_WarnedOnce == 0;
			KARMA_WarnedOnce = 1;
		end
	elseif Karma_GetConfig(KARMA_CONFIG.QUESTWARNCOLLAPSED) == nil then
		Karma_SetConfig(KARMA_CONFIG.QUESTWARNCOLLAPSED, 1);
	end
	if (Warn) and (sWarnComp ~= KARMA_QExsWarnComp) then
		KarmaChatSecondaryFallbackDefault(KARMA_MSG_QCACHE_WARNING);
	end

	KARMA_QExsWarnComp = sWarnComp;

	KARMA_QuestCache_LastUpdated = gtSeconds;
	KARMA_QuestCache_LastQLEC = iNumQuests;
	KARMA_QuestCache = {};

	local	i = 0;
	local	iNumCached, iNumDaily, iNumCompleted = 0, 0, 0;
	local	extid, s0, s1, s2, s3;
	for i = 1, iNumEntries do
		-- suggestedGroup: new with 2.0.3 (stupid Blizzard, why not insert new params at the end?)
		local	questLogTitleText, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(i);
		if (questLogTitleText ~= nil and questLogTitleText ~= "" and isHeader ~= 1) then
			-- isComplete: tristate (-1 (failed), nil (todo), +1 (succeeded))
			if (isComplete == nil) then
				isComplete = 0;
			end

			extid = GetQuestLink(i);
			if (extid) then
				-- split out the QID itself
				s0, s1, s2, s3 = strsplit("|", extid);
				s1, extid, s3 = strsplit(":", s2);
			end
 
			local	oQC = {};
			oQC.id = i;
			Karma_GetQuestObjectives(oQC.id, oQC, force);
			if ((oQC.objectives == nil) or ((#oQC.objectives == 1) and (oQC.objectives[1].type == "log"))) then
				-- tracking of this is buggy on Blizzard's end (toggles completed around)
				KarmaChatDebug("Karma_CreateQuestCache: Ignoring <" .. i .. ": " .. questLogTitleText .. ">.");
				KARMA_QuestCache[questLogTitleText] = nil;
				oQC = nil;
			end

			if (oQC) then
				KARMA_QuestCache[questLogTitleText] = oQC;
				iNumCached = iNumCached + 1;

				oQC.extid = extid;
				oQC.complete = isComplete;
				if (isComplete == 1) then
					iNumCompleted = iNumCompleted + 1;
				end
				if (isDaily) then
					oQC.daily = 1;
					iNumDaily = iNumDaily + 1;
				else
					oQC.daily = 0;
				end
			end
		end
	end

	KarmaChatDebug("Karma_CreateQuestCache-Old: Total Count = " .. iOldTotal .. ", " .. iOldDaily .. " 'daily's; " .. iOldCompleted .. " completed.");
	KarmaChatDebug("Karma_CreateQuestCache-New: Total Count = " .. iNumCached .. ", " .. iNumDaily .. " 'daily's; " .. iNumCompleted .. " completed.");

	KarmaObj.ProfileStop("Karma_CreateQuestCache");
end

function	Karma_UpdateQuest(event)
	KarmaObj.ProfileStart("Karma_UpdateQuest");

	if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEQUEST) == 1) then
		KarmaChatDebug("Quest tracking is currently disabled.");
		return
	end

	local sName, value, i;
	local UpdateWindow = false;
	for sName, value in pairs(KARMA_QuestCache) do
		for i = 1, GetNumQuestLogEntries() do
			local	questLogTitleText, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i);
			if (sName == questLogTitleText) then
				if (isComplete == nil) then
					isComplete = 0;
				end

				-- DEBUG:
				if (value.complete ~= isComplete) then
					KarmaChatDebug("Karma: " .. sName .. KARMA_WINEL_FRAG_COLONSPACE .. Karma_NilToString(value.complete) .. " -> " .. Karma_NilToString(isComplete));
				end
				-- :DEBUG

				-- new: count *partial* progress on quest goals also
				if (KARMA_QExUpdate > i) and (value.objectives ~= nil) then
					local QuestObjectives = {};
					Karma_GetQuestObjectives(i, QuestObjectives);
					if (QuestObjectives.totalProgress ~= nil) and (value.totalProgress ~= nil) then
						if (QuestObjectives.totalProgress > 1 + value.totalProgress) then
							KarmaChatDebug("Karma: " .. sName .. KARMA_WINEL_FRAG_COLONSPACE .. value.totalProgress .. " -> " .. QuestObjectives.totalProgress .. " (1)");
							Karma_AddQuestToPartyMembers(sName, value, QuestObjectives, value.extid, value.daily);
							UpdateWindow = true;
						end
					end
				else
					-- old: only count as completed, when going from incomplete to completed
					if (value.complete == 0) and (isComplete == 1) then
						KarmaChatDebug("Karma: " .. sName .. KARMA_WINEL_FRAG_COLONSPACE .. "0 -> 1 (2)");
						Karma_AddQuestToPartyMembers(sName, nil, nil, value.extid, value.daily);
						UpdateWindow = true;
					end
				end
			end
		end
	end

	if (UpdateWindow) then
		KarmaWindow_Update();
	end

	KarmaObj.ProfileStop("Karma_UpdateQuest");
end


-----------------------------------------
-- QuestList routines
-----------------------------------------

-- OnClick: self-send link
function	KarmaWindow_QuestList_OnClick(mousebutton)
	if	(mousebutton == "LeftButton") and (IsShiftKeyDown()) and
		(DEFAULT_CHAT_FRAME) and not DEFAULT_CHAT_FRAME.editBox:IsShown() then
		local	btntxt = getglobal(this:GetName() .. "_Text");
		if (btntxt) then
			local	questid = btntxt.ExtID;
			if (questid) then
				local	text = "http://wow.allakhazam.com/db/quest.html?wquest=" .. questid .. ";locale=" .. GetLocale();
				ChatFrame_OpenChat(text);
			end
		end
	end
end

-- Adds the quest to the quest list, then returns the uniqueid for that quest.
-- If the quest is already in the list then this will return the uniqueid already in existance.

--[[function	Karma_QuestList_AddQuest(questname)
	KarmaObj.ProfileStart("Karma_QuestList_AddQuest");
	local	lQuests;
	lQuests = KarmaObj.DB.SF.QuestListGet();
	if (lQuests == nil) then
		KarmaChatDebug("lQuests == nil");
	else
		KarmaChatDebug("lQuests ~= nil");
	end
	for key, value in pairs(lQuests) do
		if (value == questname) then
			KarmaObj.ProfileStop("Karma_QuestList_AddQuest");
			return key;
		end
	end
	local	newid = getn(lQuests)+1;
	lQuests[newid] = questname;
	KarmaObj.ProfileStop("Karma_QuestList_AddQuest");
	return newid;
end]]--

function	Karma_QuestList_AddQuest(questname, extid)
	-- negative = new global list
	local QID = - CommonQuestAdd(questname, nil, extid);
	return QID;
end

function QuestListNamesSortFunc(i1, i2)
	if (i1.RegionName < i2.RegionName) then
		return true;
	elseif (i1.RegionName > i2.RegionName) then
		return false;
	else
		if (i1.name < i2.name) then
			return true;
		else
			return false;
		end
	end
end

-- Generates a list of names, based on the input of a list of quest ids.
function	Karma_QuestList_GetListOfNames(questids)
	local	questnames = {};

	local	globalRegions = CommonRegionListGet();
	local	localQuests = KarmaObj.DB.SF.QuestListGet();
	local	globalQuests = KarmaObj.DB.CF.QuestNameListGet();
	local	globalQuestInfos = CommonQuestInfoListGet();
	local	questitem, regionitem;
	local	RegionsAddedL = {};
	local	x = 1;
	for key, value in pairs(questids) do
		if (value < 0) then
			local posval = - value;
			if (globalQuests[posval] ~= "") then
				questitem = {};
				questitem.id = value;
				questitem.name = globalQuests[posval];
				questitem.RegionName = "";
				if (globalQuestInfos[posval] ~= nil) then
					questitem.ExtID = globalQuestInfos[posval].ExtID;
					questitem.RegionID = globalQuestInfos[posval].RegionID;
					questitem.RegionName = nil;
					if (globalRegions[questitem.RegionID]) then
						questitem.RegionName = globalRegions[questitem.RegionID].Name;
					elseif (questitem.RegionID == 0) then
						questitem.RegionName = KARMA_CHATMSG_VARIOUS_REGIONS;
					end

					if (questitem.RegionName ~= nil) then
						if (RegionsAddedL[questitem.RegionID] == nil) then
							RegionsAddedL[questitem.RegionID] = 1;

							regionitem = {};
							regionitem.name = "";
							regionitem.RegionID = questitem.RegionID;
							regionitem.RegionName = questitem.RegionName;
							tinsert(questnames, regionitem);
							x = x + 1;
						end
					end
				end
				tinsert(questnames, questitem);
				x = x + 1;
			end
		end

		if (value > 0) then
			if (localQuests[value] ~= "") then
				questitem = {};
				questitem.id = value;
				questitem.name = localQuests[value];
				tinsert(questnames, questitem);
				x = x+1;
				end
			end
		end

	KOH.GenericSort(questnames, QuestListNamesSortFunc);
	return questnames;
end

-----------------------------------------
-- ZoneList routines
-----------------------------------------
-- Adds the zone to the zone list, then returns the uniqueid for that zone.
-- If the zone is already in the list then this will return the uniqueid already in existance.

--[[function	Karma_ZoneList_AddZone(zonename)
	KarmaObj.ProfileStart("Karma_ZoneList_AddZone");
	local	lZones;
	lZones = KarmaObj.DB.SF.ZoneListGet();
	if (lZones == nil) then
		KarmaChatDebug("lZones == nil");
	else
		KarmaChatDebug("lZones ~= nil");
	end
	for key, value in pairs(lZones) do
		if (value == zonename) then
			KarmaObj.ProfileStop("Karma_ZoneList_AddZone");
			return key;
		end
	end
	local	newid = getn(lZones)+1;
	lZones[newid] = zonename;
	KarmaObj.ProfileStop("Karma_ZoneList_AddZone");
	return newid;
end]]--

function	Karma_ZoneList_AddZone(zonename)
	local ZID, RID = CommonRegionZoneAdd(nil, zonename, nil, nil);
	if ZID == nil then
		return nil;
	else
		return - ZID, RID;
	end
end

function	Karma_CompareZoneList(Entry1, Entry2)
	if (Entry1.Region ~= nil) or (Entry2.Region ~= nil) then
		local	Region1, Region2;
		if Entry1.Region == nil then
			Region1 = "";
		else
			Region1 = Entry1.Region;
		end
		if Entry2.Region == nil then
			Region2 = "";
		else
			Region2 = Entry2.Region;
		end

		if Region1 < Region2 then
			return true;
		end
		if Region1 > Region2 then
			return false;
		end
	end

	local rv = Entry1.Zone < Entry2.Zone;
	return rv;
end

-- Generates a list of names, based on the input of a list of zone ids.
function	Karma_ZoneList_GetListOfNames(zoneids, iRegioncount)
	local	zonenames = {};
	iRegioncount = 0;
	if (type(zoneids) ~= "table") then
		return	zonenames, iRegioncount;
	end

	local	localZones = KarmaObj.DB.SF.ZoneListGet();
	local	globalZones = CommonZoneListGet();
 	local	x = 1;
	local	OldCount = 0;

	for key, value in pairs(zoneids) do
		if value > 0 then
			OldCount = OldCount + 1;
		end
	end

	if OldCount > 0 then
		for key, value in pairs(zoneids) do
			if (value < 0) then
				local posval = - value;
				if (globalZones[posval].Name ~= "") then
					zonenames[x] = globalZones[posval].Name;
					x = x+1;
				end
			end
			if (value > 0) then
				if (localZones[value] ~= "") then
					zonenames[x] = localZones[value];
					x = x+1;
				end
			end
		end
		KOH.GenericSort(zonenames, nil);
	else
		local	globalRegions = CommonRegionListGet();
		local	RegionsL = {};
		for key, value in pairs(zoneids) do
			local posval = - value;
			if (globalZones[posval].Name ~= "") then
				zonenames[x] = {};
				zonenames[x].Zone = globalZones[posval].Name;
				if globalZones[posval].RegionID ~= nil then
					local	RegionID = globalZones[posval].RegionID;
					if globalRegions[RegionID] ~= nil then
						zonenames[x].Region = globalRegions[RegionID].Name;
						if (RegionsL[RegionID] == nil) then
							RegionsL[RegionID] = 1;

							x = x + 1;
							zonenames[x] = {};
							zonenames[x].RegionID = RegionID;
							zonenames[x].Region = globalRegions[RegionID].Name;
							zonenames[x].Zone = "";
						end
					end
				end
				x = x + 1;
			end
		end

		KOH.GenericSort(zonenames, Karma_CompareZoneList);
	end

	return zonenames, iRegionCount;
end


-----------------------------------------
-- MEMBERLIST FUNCTIONS
-----------------------------------------

function	Karma_MemberList_GetMemberNamesSortedAlpha()
	if (KARMA_NamesSortedAlpha == nil) then
		Karma_MemberList_CreateMemberNamesCache();
	end

	return Karma_CopyTable(KARMA_NamesSortedAlpha);
end

function	Karma_MemberList_GetMemberNamesSortedCustom()
	if (KARMA_NamesSortedCustom == nil) then
		Karma_MemberList_CreateMemberNamesCache();
	end

	return Karma_CopyTable(KARMA_NamesSortedCustom);
end

local	function	Karma_SameUnit(sName1, sServer1, sName2, sServer2)
	local	Result = true;
	if (sName1 ~= sName2) then
		Result = false;
	end

	if (sServer1 == "") then
		sServer1 = nil;
	end
	if (sServer2 == "") then
		sServer2 = nil;
	end
	if (Result) then
		Result = sServer1 == sServer2;
	end

--[[
local	ResStr = "false";
if (Result) then
	ResStr = "true";
end
KarmaChatDebug("SameUnit: " .. Karma_NilToString(sName1) .. "@" .. Karma_NilToString(sServer1) .. " == "
							.. Karma_NilToString(sName2) .. "@" .. Karma_NilToString(sServer2) .. "? " .. ResStr);
]]--

	return Result;
end

function	Karma_MemberList_MemberNameToUnitName(sMemberName)
	local	iPos = strfind(sMemberName, "@", 1, true);
	local	sServerName = "";
	if (iPos) then
		sServerName = strsub(sMemberName, iPos + 1);
		sMemberName = strsub(sMemberName, 1, iPos - 1);
	end

	local	membercount = GetNumPartyMembers();
	local	iCounter, sUnitID;
	for iCounter = 1, membercount do
		sUnitID = "party" .. iCounter;
		sUnitName, sUnitServer = UnitName(sUnitID);
		if Karma_SameUnit(sMemberName, sServerName, sUnitName, sUnitServer) then
			return sUnitID;
		end
	end

	local	membercount = GetNumRaidMembers();
	local	iCounter, sUnitID;
	for iCounter = 1, membercount do
		sUnitID = "raid" .. iCounter;
		sUnitName, sUnitServer = UnitName(sUnitID);
		if Karma_SameUnit(sMemberName, sServerName, sUnitName, sUnitServer) then
			return sUnitID;
		end
	end

	local	sUnitName, sUnitServer;
	sUnitName, sUnitServer = UnitName("target");
	if Karma_SameUnit(sMemberName, sServerName, sUnitName, sUnitServer) then
		return "target";
	end

	sUnitName, sUnitServer = UnitName("mouseover");
	if Karma_SameUnit(sMemberName, sServerName, sUnitName, sUnitServer) then
		return "mouseover";
	end

	return nil;
end

function	Karma_MemberList_Add(sMemberName, bInGroup)
	if (sMemberName == nil or sMemberName == "") then
		return;
	end

	local	playername = nil;
	local	lMembers = KarmaObj.DB.SF.MemberListGet();

	if (lMembers == nil) then
		return;
	end

	local	sBucketName = KarmaObj.NameToBucket(sMemberName);
	KOH.TableInit(lMembers[sBucketName], sMemberName);
	local	oMember = lMembers[sBucketName][sMemberName];

	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.LASTCHANGED_TIME, time(), true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.LASTCHANGED_FIELD, "Created", true);
	if (bInGroup) then
		oMember[KARMA_DB_L5_RRFFM.LASTCHANGED_TIME] = time();
		oMember[KARMA_DB_L5_RRFFM.LASTCHANGED_FIELD] = "Joined";
	end

	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.NAME, sMemberName, true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.ALTGROUP, -1, true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.GUILD, "", true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.LEVEL, 0, true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.GENDER, "", true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.RACE, "", true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.CLASS, "", true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM.CLASS_ID, 0, true);

	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_TALENT, 0, true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_KARMA, 50, true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_PUBLIC_NOTES, "", true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_NOTES, "", true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_PUBLIC_NOTES_HISTORY, "", true);

	-- new:
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_SKILL, -1, true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_GEAR_PVE, -1, true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_GEAR_PVP, -1, true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_KARMA_IMPORTED, 0, true);
	Karma_FieldInitialize(oMember, KARMA_DB_L5_RRFFM_KARMA_TIME, -1, true);

	KOH.TableInit(oMember, KARMA_DB_L5_RRFFM_TIMESTAMP);
	Karma_FieldInitialize(oMember[KARMA_DB_L5_RRFFM_TIMESTAMP], KARMA_DB_L5_RRFFM_TIMESTAMP_TRY, 0, true);
	Karma_FieldInitialize(oMember[KARMA_DB_L5_RRFFM_TIMESTAMP], KARMA_DB_L5_RRFFM_TIMESTAMP_SUCCESS, 0, true);

	KOH.TableInit(oMember, KARMA_DB_L5_RRFFM_CHARACTERS);

	local	CharContainerAdd = function(oMember, sPlayer)
			local	bCreated = oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer] == nil;
			KOH.TableInit(oMember[KARMA_DB_L5_RRFFM_CHARACTERS], sPlayer);

			Karma_FieldInitialize(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_PLAYED, 0, true);
			Karma_FieldInitialize(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_PLAYEDLAST, GetTime(), true);

			Karma_FieldInitialize(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_XP, 0, true);
			Karma_FieldInitialize(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_XPLAST, 0, true);
			Karma_FieldInitialize(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_XPMAX, 0, true);
			Karma_FieldInitialize(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_XPLVL, 0, true);
			
			KOH.TableInit(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_QUESTIDLIST);
			KOH.TableInit(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_QUESTEXLIST);

			KOH.TableInit(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_ZONEIDLIST);

			KOH.TableInit(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_ACHIEVED);

			KOH.TableInit(oMember[KARMA_DB_L5_RRFFM_CHARACTERS][sPlayer], KARMA_DB_L6_RRFFMCC_REGIONLIST);

			return bCreated;
		end

	Karma_WhoAmIInit();
	if (Karma_GetConfig(KARMA_CONFIG.DB_SPARSE) == 1) then	-- dbsparse
		if (bInGroup) then
			if (CharContainerAdd(oMember, WhoAmI)) then
				KarmaChatDebug("Adding container to " .. sMemberName .. " for " .. WhoAmI .. "; via: " .. debugstack());
			end
		end
	else
		local	bOk = false;
		local	oFaction = KarmaObj.DB.FactionCacheGet();
		for ckey, cvalue in pairs(oFaction[KARMA_DB_L4_RRFF.CHARACTERLIST]) do
			CharContainerAdd(oMember, ckey);
			if (ckey == WhoAmI) then
				bOk = true;
			end
		end
		if (not bOk) then
			CharContainerAdd(oMember, WhoAmI);
		end
	end
end

function	Karma_MemberList_Remove(sMemberName)
	local	lMembers = KarmaObj.DB.SF.MemberListGet();
	local	sBucketName = KarmaObj.NameToBucket(sMemberName);
	local	oMember = lMembers[sBucketName][sMemberName];
	if (oMember) then
		lMembers[sBucketName][sMemberName] = nil;
	end
	KarmaWindow_Update();
end

function	Karma_MemberList_GetFieldHighLow(fieldname, oMember)
	local	lowfield = 999999999;
	local	highfield = 0;
	local	iCounter = 0;

	if (oMember and KarmaModuleLocal.FieldHighLow[fieldname]) then
		local	oField = KarmaModuleLocal.FieldHighLow[fieldname];
		local	xVal = oMember[fieldname];
		if (xVal) then
			if  (xVal < oField.Low) then
				oField.Low = xVal;
			end
			if  (xVal > oField.High) then
				oField.High = xVal;
			end
		end

		lowfield = oField.Low;
		highfield = oField.High;
		iCounter = oField.Counter;
	else
		local	lMembers = KarmaObj.DB.SF.MemberListGet();
		local	perbuckets = {};
		local	mbname, mbvalue;
		for mbname, mbvalue in pairs(lMembers) do
			if (mbvalue ~= nil) then
				local	sName, record;
				for sName, record in pairs(mbvalue) do
					if (record ~= nil) then
						local	pobj = Karma_MemberObject_GetCharacterObject(record);
						if (pobj and pobj[fieldname]) then
							iCounter = iCounter + 1;
							if (pobj[fieldname] < lowfield) then
								lowfield = pobj[fieldname];
							end
							if (pobj[fieldname] > highfield) then
								highfield = pobj[fieldname];
							end
						end
					end
				end
			end
		end

		local	oField = KarmaModuleLocal.FieldHighLow[fieldname];
		if (oField == nil) then
			oField = {};
			KarmaModuleLocal.FieldHighLow[fieldname] = oField;
		end
		oField.Low = lowfield;
		oField.High = highfield;
		oField.Counter = iCounter;
	end

	if (lowfield > highfield) then
		return 0, 0, 0;
	end

	local	average = (highfield - lowfield) / iCounter;
	return lowfield, highfield, average;
end

function	Karma_MemberList_GetHighLow_TotalFieldSummedUp(fieldname, oMember)
	local	lowfield = 999999999;
	local	highfield = 0;
	local	iCounter = 0;

	if (oMember and KarmaModuleLocal.FieldHighLow[fieldname]) then
		local	oField = KarmaModuleLocal.FieldHighLow[fieldname];
		local	iSum;
		if (oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) then
			iSum = 0;
			local	sChar, oChar;
			for sChar, oChar in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
				if (oChar[fieldname]) then
					iSum = iSum + oChar[fieldname];
				end
			end
		end

		if (iSum) then
			if  (iSum < oField.Low) then
				oField.Low = iSum;
			end
			if  (iSum > oField.High) then
				oField.High = iSum;
			end
		end

		lowfield = oField.Low;
		highfield = oField.High;
		iCounter = oField.Counter;
	else
		local	lMembers = KarmaObj.DB.SF.MemberListGet();
		local	perbuckets = {};
		local	mbname, mbvalue;
		for mbname, mbvalue in pairs(lMembers) do
			if (mbvalue ~= nil) then
				local	sName, record;
				for sName, record in pairs(mbvalue) do
					if (record ~= nil) then
						iCounter = iCounter + 1;
						local	iSum = 0;
						if (record[KARMA_DB_L5_RRFFM_CHARACTERS]) then
							local	sChar, oChar;
							for sChar, oChar in pairs(record[KARMA_DB_L5_RRFFM_CHARACTERS]) do
								if (oChar[fieldname]) then
									iSum = iSum + oChar[fieldname];
								end
							end
						end

						if (iSum < lowfield) then
							lowfield = iSum;
						end
						if (iSum > highfield) then
							highfield = iSum;
						end
					end
				end
			end
		end

		local	oField = KarmaModuleLocal.FieldHighLow[fieldname];
		if (oField == nil) then
			oField = {};
			KarmaModuleLocal.FieldHighLow[fieldname] = oField;
		end
		oField.Low = lowfield;
		oField.High = highfield;
		oField.Counter = iCounter;
	end

	if (lowfield > highfield) then
		return 0, 0, 0;
	end

	local	average = (highfield - lowfield) / iCounter;
	return lowfield, highfield, average;
end

--
-- Collision check routine
-- if this returns 1, Karma_MemberList_Update should not be called
--
function	Karma_MemberList_CollisionCheckActually(oMember, sCombined, sUnit, iLevel, iClassID, sRace)
	-- Collision check:
	-- - GUID must be equal (easy one...)
	if  (sUnit) and (oMember[KARMA_DB_L5_RRFFM.GUID]) and
		(oMember[KARMA_DB_L5_RRFFM.GUID] == UnitGUID(sUnit)) then
		return 0, "=GUID";
	end

	-- - non-trivial cases: if values are both available, then...
	-- a) level must be greater or equal
	-- b) classid must be equal
	-- b) race must be equal

	local	retval = 0;
	local	retstr = "";

	if (iLevel == nil) and (sUnit ~= nil) then
		iLevel = UnitLevel(sUnit);
	end
	if	(iLevel) and (oMember[KARMA_DB_L5_RRFFM.LEVEL]) and
		(iLevel > 0) and (oMember[KARMA_DB_L5_RRFFM.LEVEL] > 0) and
		(oMember[KARMA_DB_L5_RRFFM.LEVEL] > iLevel) then
		retval = 1;
		retstr = " !Level: " .. iLevel .. " (new) < " .. oMember[KARMA_DB_L5_RRFFM.LEVEL] .. " (old)";
	end

	if (iClassID == nil) and (sUnit ~= nil) then
		local	sClass = UnitClass(sUnit);
		if (sClass) then
			iClassID = Karma_ClassToID(sClass);
		end
	end
	if	(iClassID) and (iClassID ~= 0) and
		(oMember[KARMA_DB_L5_RRFFM.CLASS_ID]) and (oMember[KARMA_DB_L5_RRFFM.CLASS_ID] ~= 0) and
		(math.abs(iClassID) ~= math.abs(oMember[KARMA_DB_L5_RRFFM.CLASS_ID])) then
		retval = 1;
		retstr = retstr .. " !ClassID: " .. iClassID .. " (new) != " .. oMember[KARMA_DB_L5_RRFFM.CLASS_ID] .. " (old)";
	end

	if (sRace == nil) and (sUnit ~= nil) then
		sRace = UnitRace(sUnit);
	end
	if  (sRace) and (sRace ~= "") and
		(oMember[KARMA_DB_L5_RRFFM.RACE]) and (oMember[KARMA_DB_L5_RRFFM.RACE] ~= "") and
		(sRace ~= oMember[KARMA_DB_L5_RRFFM.RACE]) then
		retval = 1;
		retstr = retstr .. " !Race: " .. sRace .. " (new) != " .. oMember[KARMA_DB_L5_RRFFM.RACE] .. " (old)";
	end

	return retval, retstr;
end

function	Karma_MemberList_CollisionCheck(sCombined, sUnit, iLevel, iClassID, sRace)
	local	oMember = Karma_MemberList_GetObject(sCombined);
	if (oMember == nil) then
		return 0, "not on list";
	end

	local	retval, retstr;

	if (type(oMember[KARMA_DB_L5_RRFFM_CONFLICT]) == "table") then
		retstr = oMember[KARMA_DB_L5_RRFFM_CONFLICT].Conflict;
		if (oMember[KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
			return 1, retstr;
		end
	end

	retval, retstr = Karma_MemberList_CollisionCheckActually(oMember, sCombined, sUnit, iLevel, iClassID, sRace);
	if (retval == 1) then
		if (type(oMember[KARMA_DB_L5_RRFFM_CONFLICT]) ~= "table") then
			oMember[KARMA_DB_L5_RRFFM_CONFLICT] = {};
		end

		if (oMember[KARMA_DB_L5_RRFFM_CONFLICT].At == nil) then
			oMember[KARMA_DB_L5_RRFFM_CONFLICT].At = time();
		end
		oMember[KARMA_DB_L5_RRFFM_CONFLICT].Conflict = retstr;
		oMember[KARMA_DB_L5_RRFFM_CONFLICT].Resolved = 0;
	end

	return retval, retstr;
end

--
-- Update parts of the member record which might have changed.
-- Also set the parts which might not yet have been set.
--
function	Karma_MemberList_Update(sMemberName, level, class, race, guild)
	if (sMemberName == "" or sMemberName == nil) then
		return;
	end

	local	oMember = Karma_MemberList_GetObject(sMemberName);
	if (oMember == nil) then
		return;
	end

	-- delete: unused.
	oMember[KARMA_DB_L5_RRFFM_KARMA_MODSOC] = nil;
	oMember[KARMA_DB_L5_RRFFM_KARMA_MODSKILL] = nil;
	-- this shall be per char
	oMember[KARMA_DB_L6_RRFFMCC_REGIONLIST] = nil;

	local	iClassID = Karma_ClassToID(class);
	local	iCC, sReason = Karma_MemberList_CollisionCheck(sMemberName, nil, level, iClassID, race);
	if (iCC == 1) then
		if (sMemberName ~= KARMA_UNKNOWN) then
			local	sMemberName_Clickable = KOH.Name2Clickable(sMemberName);
			KarmaChatSecondary("Karma |cFFFF8080*can't*|r update >" .. sMemberName_Clickable .. "< : " .. sReason .. ". Use '" .. KARMA_CMDSELF .. " forcenew <player>' to backup the current entry and add a new one, or '" .. KARMA_CMDSELF .. " forceupdate <player>' to remove any conflicting data on the existing entry.", true);
		end

		return;
	end

	-- don't lose /who data unnecessarily...
	if (level ~= nil) then
		oMember[KARMA_DB_L5_RRFFM.LEVEL] = level;

		local	timestamp = time();
		if (oMember[KARMA_DB_L5_RRFFM_TIMESTAMP] == nil) then
			oMember[KARMA_DB_L5_RRFFM_TIMESTAMP] = {};
			oMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_TRY] = timestamp;
		end
		oMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_SUCCESS] = timestamp;
	end
	if (class ~= nil) then
		oMember[KARMA_DB_L5_RRFFM.CLASS] = class;
		local ClassID = Karma_ClassToID(class);
		if (ClassID ~= 0) then
			oMember[KARMA_DB_L5_RRFFM.CLASS_ID] = ClassID;
		end
	end
	if (race ~= nil) then
		oMember[KARMA_DB_L5_RRFFM.RACE] = race;
	end
	if (guild ~= nil) then
		oMember[KARMA_DB_L5_RRFFM.GUILD] = guild;
	end

	if (oMember[KARMA_DB_L5_RRFFM_TIMESTAMP] == nil) then
		oMember[KARMA_DB_L5_RRFFM_TIMESTAMP] = {};
	end

	local timestamp = time();
	if ((level ~= nil) and (class ~= nil) and (race ~= nil)) then
		oMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_TRY] = timestamp;
		oMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_SUCCESS] = timestamp;
	end

	Karma_WhoAmIInit();
	if (WhoAmI ~= nil) then
		if (Karma_GetConfig(KARMA_CONFIG.DB_SPARSE) ~= 1) then	-- dbsparse
			if (oMember[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI] == nil) then
				oMember[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI] = {};
			end
		end

		if (oMember[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI] ~= nil) then
			oMember[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI][KARMA_DB_L6_RRFFMCC_PLAYEDLAST] = GetTime();
			oMember[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI][KARMA_DB_L6_RRFFMCC_XPLAST] = UnitXP("player");
			oMember[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI][KARMA_DB_L6_RRFFMCC_XPMAX] = UnitXPMax("player");
		end
	end

	local	unitname = Karma_MemberList_MemberNameToUnitName(sMemberName);
	if (unitname == nil) then
		-- If the unit isn't in the party, no Unit* - functions...
		return
	end

	oMember[KARMA_DB_L5_RRFFM.GUID] = UnitGUID(unitname);

	oMember[KARMA_DB_L5_RRFFM.LEVEL] = UnitLevel(unitname);
	oMember[KARMA_DB_L5_RRFFM.CLASS] = UnitClass(unitname);
	local ClassID = Karma_ClassToID(oMember[KARMA_DB_L5_RRFFM.CLASS]);
	if (ClassID ~= 0) then
		oMember[KARMA_DB_L5_RRFFM.CLASS_ID] = ClassID;
	end
	oMember[KARMA_DB_L5_RRFFM.GENDER] = UnitSex(unitname);
	oMember[KARMA_DB_L5_RRFFM.RACE] = UnitRace(unitname);

	-- guild is not properly given for distant units, only allow if close
	if (CheckInteractDistance(unitname, 1) == 1) then
		oMember[KARMA_DB_L5_RRFFM.GUILD] = GetGuildInfo(unitname);
	end
	if (oMember[KARMA_DB_L5_RRFFM.GUILD] == nil) then
		oMember[KARMA_DB_L5_RRFFM.GUILD] = "";
	end

	oMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_TRY] = timestamp;
	oMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_SUCCESS] = timestamp;
end

--
--
--
function	Karma_MemberList_GetObject(sMemberName, sServerName, lMembers)
	if (sMemberName == nil) or (sMemberName == "") then
		return nil;
	end

	if (sServerName) and (sServerName ~= "") then
		sMemberName = sMemberName .. "@" .. sServerName;
	end

	if (lMembers == nil) then
		lMembers = KarmaObj.DB.SF.MemberListGet();
	end

	local	sBucketName = KarmaObj.NameToBucket(sMemberName);
	local	oMember = lMembers[sBucketName][sMemberName];
	return oMember;
end

-----------------------------------------
-- MEMBEROBJECT FUNCTIONS
-----------------------------------------
function	Karma_MemberObject_GetName(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM.NAME];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetXP(oMember)
	if (type(oMember) == "table") then
		local	charobj = Karma_MemberObject_GetCharacterObject(oMember);
		if (charobj == nil) then
			return 0;
		end
		return charobj[KARMA_DB_L6_RRFFMCC_XP];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetTotalXPSummedUp(oMember)
	if	(type(oMember) ~= "table") or
		(oMember[KARMA_DB_L5_RRFFM_CHARACTERS] == nil) then
		return 0;
	end

	local	iSum, key, value = 0;
	for key, value in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
		iSum = iSum + (value[KARMA_DB_L6_RRFFMCC_XP] or 0);
	end

	return iSum;
end

function	Karma_MemberObject_GetXPLVL(oMember)
	if (type(oMember) == "table") then
		local	charobj = Karma_MemberObject_GetCharacterObject(oMember);
		if (charobj == nil) then
			return 0;
		end

		return charobj[KARMA_DB_L6_RRFFMCC_XPLVL];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetTotalXPLVLSummedUp(oMember)
	if	(type(oMember) ~= "table") or
		(oMember[KARMA_DB_L5_RRFFM_CHARACTERS] == nil) then
		return 0;
	end

	local	iSum, key, value = 0;
	for key, value in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
		iSum = iSum + (value[KARMA_DB_L6_RRFFMCC_XPLVL] or 0);
	end

	return iSum;
end

function	Karma_MemberObject_GetTimePlayed(oMember)
	if (type(oMember) == "table") then
		local	charobj = Karma_MemberObject_GetCharacterObject(oMember);
		if (charobj == nil) then
			return nil;
		end

		return charobj[KARMA_DB_L6_RRFFMCC_PLAYED];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetTotalTimePlayedSummedUp(oMember)
	local	iSum = 0;
	if	(type(oMember) ~= "table") or
		(oMember[KARMA_DB_L5_RRFFM_CHARACTERS] == nil) then
		return iSum;
	end

	local	key, value;
	for key, value in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
		if (value[KARMA_DB_L6_RRFFMCC_PLAYED]) then
			iSum = iSum + value[KARMA_DB_L6_RRFFMCC_PLAYED];
		end
	end

	return iSum;
end

function	Karma_MemberObject_GetTimeJoinedTimeTotal(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM_JOINEDLAST_TIME];
	else
		return 0;
	end
end

function	Karma_MemberObject_GetTimeJoinedCharTotal(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM_JOINEDLAST_CHAR];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetTimeJoinedChar(oMember, sChar)
	if (type(oMember) == "table") then
		local	charobj = Karma_MemberObject_GetCharacterObject(oMember, sChar);
		if (charobj == nil) then
			return 0;
		end
		return charobj[KARMA_DB_L6_RRFFMCC_JOINEDLAST];
	else
		return 0;
	end
end

function	Karma_MemberObject_GetKarma(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM_KARMA];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetKarmaModifier(oMember)
	if (type(oMember) == "table") then
		local	value = oMember[KARMA_DB_L5_RRFFM_KARMA];
		local	bModified = false;

		local	val_imp = oMember[KARMA_DB_L5_RRFFM_KARMA_IMPORTED];
		if (val_imp) and (val_imp ~= 0) then
			bModified = true;
			value = value + val_imp;
		end

		local	minval = Karma_GetConfig(KARMA_CONFIG.TIME_KARMA_MINVAL);
		if (minval == nil) then
			minval = 50;
		end
		local	timemember = oMember[KARMA_DB_L5_RRFFM_KARMA_TIME];
		if (timemember == 0) or (value < minval) then
			return value, 0, nil;
		end

		if (timemember ~= 1) then
			local	timeglobal = Karma_GetConfig(KARMA_CONFIG.TIME_KARMA_DEFAULT);
			if (timeglobal == 1) then
				timemember = timeglobal;
			end
		end

		local	timesum = 0;
		if (timemember == 1) then
			local	factor = Karma_GetConfig(KARMA_CONFIG.TIME_KARMA_FACTOR);
			if (factor == nil) then
				factor = 0.4;
			end

			local	iSkipBGPlayed = Karma_GetConfig(KARMA_CONFIG.TIME_KARMA_SKIPBGTIME);
			if (iSkipBGPlayed == nil) then
				iSkipBGPlayed = 1;
			end

			local	char, charobj;
			for char, charobj in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
				if (charobj[KARMA_DB_L6_RRFFMCC_PLAYED]) then
					timesum = timesum + charobj[KARMA_DB_L6_RRFFMCC_PLAYED];
					if ((iSkipBGPlayed == 1) and (charobj[KARMA_DB_L6_RRFFMCC_PLAYEDPVP] ~= nil)) then
						timesum = timesum - charobj[KARMA_DB_L6_RRFFMCC_PLAYEDPVP];
					end
				end
			end
			timesum = (timesum / 3600) * factor;
			bModified = bModified or (timesum >= 0.5);
		end

		return value, math.floor(timesum + 0.5), bModified;
	else
		return nil, nil;
	end
end

function	Karma_MemberObject_GetKarmaModified(oMember)
	if (type(oMember) == "table") then
		local	value, iMod, bMod = Karma_MemberObject_GetKarmaModifier(oMember);
		if (iMod ~= nil) then
			return value + iMod, bMod;
		end
	end

	return nil, nil;
end

function	Karma_MemberObject_GetKarmaModifiedForListWithColors(oMember)
	local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
	if (iKarma) then
		local	sKarma = iKarma;
		if (iKarma > 100) then
			sKarma = "++";
		end
		if (bModified) then
			sKarma = "*" .. sKarma;
		end

		iKarma = math.min(iKarma, 100);
		local	iRed, iGreen, iBlue = Karma_Karma2Color(iKarma);
		sKarma = "|c" .. ColourToString(1, iRed, iGreen, iBlue) .. sKarma .. "|r";

		return sKarma, iKarma;
	end

	return "", 50;
end

function	Karma_MemberObject_GetKarmaWithModifiers(oMember)
	if (type(oMember) == "table") then
		local	valueplusimp, iMod, bMod = Karma_MemberObject_GetKarmaModifier(oMember);
		if (iMod == nil) then
			return valueplusimp;
		end

		local	value = oMember[KARMA_DB_L5_RRFFM_KARMA];
		local	val_imp = oMember[KARMA_DB_L5_RRFFM_KARMA_IMPORTED];
		if (val_imp == nil) then
			val_imp = 0;
		end

		local	bModified = false;

		local	valstr = value .. " rK";
		if (val_imp ~= 0) then
			bModified = true;
			valstr = valstr .. ", " .. val_imp .. " iK";
		end

		if (iMod > 0) then
			bModified = true;
			valstr = valstr .. ", " .. iMod .. " tK";
		end

		if (bModified) then
			return valstr;
		else
			return value;
		end
	else
		return nil;
	end
end

function	Karma_MemberObject_GetLevel(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM.LEVEL];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetRace(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM.RACE];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetClass(oMember)
	if (type(oMember) == "table") then
		local	iID = oMember[KARMA_DB_L5_RRFFM.CLASS_ID];
		if ((type(iID) ~= "number") or (iID == 0)) then
			iID = Karma_ClassToID(oMember[KARMA_DB_L5_RRFFM.CLASS]);
			if (iID and (iID ~= 0)) then
				oMember[KARMA_DB_L5_RRFFM.CLASS_ID] = iID;
			end
		end

		if (iID and (iID ~= 0)) then
			local Tmp = Karma_IDToClass(iID);
			if (Tmp ~= "") then
				return Tmp, iID;
			end
		end

		return oMember[KARMA_DB_L5_RRFFM.CLASS];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetClassWOGender(oMember)
	local ClassName = Karma_MemberObject_GetClass(oMember);
	local ClassID = Karma_ClassToID(ClassName);
	if  (ClassID < 0) then
		ClassID = - ClassID;
	end;

	return Karma_IDToClass(ClassID);
end

function	Karma_MemberObject_GetTalentIDRaw(oMember, iSpec)
	if (type(oMember) == "table") then
		if (iSpec == nil) then
			iSpec = 1;
		end
		local	Result = oMember[KARMA_DB_L5_RRFFM_TALENT .. "_" .. iSpec];
		if (Result == nil) then
			if (iSpec == 1) then
				Result = oMember[KARMA_DB_L5_RRFFM_TALENT];
				if (Result) then
					oMember[KARMA_DB_L5_RRFFM_TALENT .. "_" .. iSpec] = oMember[KARMA_DB_L5_RRFFM_TALENT];
				end
			end
			if (Result == nil) then
				Result = 0;
			end
		end

		return Result;
	else
		return nil;
	end
end

function	Karma_MemberObject_GetTalentID(oMember, iSpec)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_TALENT] == nil) then
			oMember[KARMA_DB_L5_RRFFM_TALENT] = 0;
		end
		local	talentid = Karma_MemberObject_GetTalentIDRaw(oMember, iSpec);
		if (talentid == 0) then
			-- KarmaChatDebug("no talent set, retrieving from class" .. KARMA_WINEL_FRAG_TRIDOTS);
			local	classid = oMember[KARMA_DB_L5_RRFFM.CLASS_ID];
			if (classid == 0) then
				classid = Karma_ClassToID(Karma_MemberObject_GetClass(oMember));
			end

			local	talentid, pattern = KarmaObj.Talents.ClassIDToTalentsDefault(classid); 
			return talentid, pattern;
		end

		return talentid, false;
	else
		return nil, false;
	end
end

function	Karma_MemberObject_GetTalentColorizedText(oMember, iSpec)
	local	iTalentID, bPattern, iDerived = Karma_MemberObject_GetTalentID(oMember, iSpec);
	if (bPattern) then
		iDerived = KarmaObj.Talents.MemberObjSpecNumToTalent(oMember, iSpec);
		if (iDerived) then
			iTalentID = iDerived;
		end
	end
	local	sResult = KarmaObj.Talents.TalentIDToColorizedText(iTalentID);
	if (iDerived) then
		sResult = "[" .. sResult .. "]";
	end
	return sResult, iTalentID;
end

function	Karma_MemberObject_GetGuild(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM.GUILD];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetNotes(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM_NOTES];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetPrivateNotesCut(oMember, iLinesMax, iCharsMax)
	if (type(oMember) == "table") then
		local	sNotes = oMember[KARMA_DB_L5_RRFFM_NOTES];
		if (sNotes) then
			return KarmaModuleLocal.Helper.ExtractHeader(sNotes, iLinesMax, iCharsMax);
		end
	end
end

function	Karma_MemberObject_GetPublicNotes(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetAltID(oMember)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM.ALTGROUP] == nil) then
			oMember[KARMA_DB_L5_RRFFM.ALTGROUP] = -1;
		end
		return oMember[KARMA_DB_L5_RRFFM.ALTGROUP];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetSkill(oMember)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_SKILL] == nil) then
			oMember[KARMA_DB_L5_RRFFM_SKILL] = -1;
		end
		return oMember[KARMA_DB_L5_RRFFM_SKILL];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetSkillText(oMember)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_SKILL] == nil) then
			oMember[KARMA_DB_L5_RRFFM_SKILL] = -1;
		end

		local	iSkill = oMember[KARMA_DB_L5_RRFFM_SKILL];
		if (iSkill >= 0) and (KARMA_SKILL_LEVELS[iSkill] ~= nil) then
			local	sModel = Karma_GetConfig(KARMA_CONFIG_SKILL_MODEL);
			if (sModel == "complex") then
				return (tostring(iSkill) .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_SKILL_LEVELS[iSkill]);
			else
				return KARMA_SKILL_LEVELS[iSkill];
			end
		end
	end

	return nil;
end

function	Karma_MemberObject_GetGearPVP(oMember)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_GEAR_PVP] == nil) then
			oMember[KARMA_DB_L5_RRFFM_GEAR_PVP] = -1;
		end
		return oMember[KARMA_DB_L5_RRFFM_GEAR_PVP];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetGearPVE(oMember)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_GEAR_PVE] == nil) then
			oMember[KARMA_DB_L5_RRFFM_GEAR_PVE] = -1;
		end
		return oMember[KARMA_DB_L5_RRFFM_GEAR_PVE];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetGender(oMember)
	if (type(oMember) == "table") then
		local genderTable = { "", MALE, FEMALE };
		return genderTable[oMember[KARMA_DB_L5_RRFFM.GENDER]]
	else
		return nil;
	end
end

function	Karma_MemberObject_GetGUID(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM.GUID];
	else
		return nil;
	end
end

function	Karma_MemberObject_GetTimestampTry(oMember)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_TIMESTAMP] ~= nil) then
			return oMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_TRY];
		end
	end

	return 0;
end

function	Karma_MemberObject_GetTimestampSuccess(oMember)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_TIMESTAMP] ~= nil) then
			return oMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_SUCCESS];
		end
	end

	return 0;
end

function	Karma_MemberObject_GetQuestList(oMember)
	if (type(oMember) == "table") then
		charobj = Karma_MemberObject_GetCharacterObject(oMember);
		if (charobj) then
			return charobj[KARMA_DB_L6_RRFFMCC_QUESTIDLIST];
		else
			return nil;
		end
	else
		return nil;
	end
end

function	Karma_MemberObject_GetQuestExList(oMember)
	if (type(oMember) == "table") then
		charobj = Karma_MemberObject_GetCharacterObject(oMember);
		if (charobj) then
			return charobj[KARMA_DB_L6_RRFFMCC_QUESTEXLIST];
		else
			return nil;
		end
	else
		return nil;
	end
end

function	Karma_MemberObject_GetZoneList(oMember)
	if (type(oMember) == "table") then
		charobj = Karma_MemberObject_GetCharacterObject(oMember);
		if (charobj) then
			return charobj[KARMA_DB_L6_RRFFMCC_ZONEIDLIST];
		else
			return nil;
		end
	else
		return nil;
	end
end

function	Karma_MemberObject_GetTotalQuestListCount(oMember)
	if (type(oMember) == "table") then
		local TotalQuestListCount = 0;
		for char, charobj in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
			if (charobj[KARMA_DB_L6_RRFFMCC_QUESTIDLIST]) then
				for index, QID in pairs(charobj[KARMA_DB_L6_RRFFMCC_QUESTIDLIST]) do
					TotalQuestListCount = TotalQuestListCount + 1;
				end
			end
		end

		return TotalQuestListCount;
	else
		return 0;
	end
end

local function IsPvpZone(ZID)
	local ZKey = - ZID;
	local ZL = CommonZoneListGet();
	if (type(ZL) == "table") then
		if (ZL[ZKey] ~= nil) then
			local RKey = ZL[ZKey].RegionID;
			if (RKey ~= nil) then
				local RL = CommonRegionListGet();
				if (type(RL) == "table") then
					if (RL[RKey] ~= nil) then
						return RL[RKey][KARMA_DB_L3_CR.ISPVPZONE] == 1;
					else
						KarmaChatDebug(KARMA_TITLE.."-DBG: RL[" .. RKey .. "] == nil!");
					end
				end
			end
		else
			KarmaChatDebug(KARMA_TITLE.."-DBG: ZL[" .. ZID .. "] == nil!");
		end
	end

	return false;
end

-- >> toying around part 1
function	TextEncode(text)
	local	char, toggle, rnd;

	local	out = "";

	local	i;
	local	textlen = strlen(text);
	if (textlen ~= nil) then
		KarmaChatDebug("encode: " .. textlen .. " characters");
	else
		KarmaChatDebug("encode not possible: type = " .. type(text));
		return "";
	end

	local	firstspacepos = strfind(text, " ", 1, true);
	if (firstspacepos == nil) or (firstspacepos < 3) then
		KarmaChatDebug("encode not possible: not enough text");
		return "";
	end

	-- early fixed modification for quick identification:
	-- strupper last char in first word and double first space
	for i = 1, firstspacepos - 1 do
		char = strsub(text, i, i);
		out = out .. char;
	end
	i = firstspacepos + 1;
	char = strsub(text, i, i);
	out = out .. " ^ " .. char .. char;
	
	-- must not change seed...
	math.randomseed(20070519);

	-- modify message 'slightly'
	for i = firstspacepos + 2, textlen do
		char = strsub(text, i, i);
		if (strupper(char) == "") or (strlower(char) == "") then
			-- inconvertible: don't touch
			out = out .. char;
		else
			rnd = math.random(41);
			if (char == " ") then
				out = out .. char;
				if (rnd < 7) then
					out = out .. char;
				end
			else
				toggle = strlower(char);
				if (toggle == char) then
					toggle = strupper(char);
				end
				if (rnd > 36) then
					out = out .. toggle;
				elseif (rnd < 4) then
					out = out .. char .. strlower(char);
				else
					out = out .. char;
				end
			end
		end
	end

	out = out .. ".,.´`´`";

	KarmaChatDebug("encode: done");

	return	out;
end
-- << toying around part 1

-- >> toying around part 2
function	TextDecode(text)
end
-- << toying around part 2

-- Karma_TEST: development helper ;) (start)
function	Karma_TEST(cmd, arg, arg2)
	KarmaObj.UI.MsgAddOnForceHandling = 2;

	if (cmd == -9) then
		local ZKey = - arg;
		local ZL = CommonZoneListGet();
		if (type(ZL) == "table") then
			if (ZL[ZKey] ~= nil) then
				KarmaChatDebug("Zone: " .. KarmaObj.Helpers.TableToString(ZL[ZKey]));

				local RKey = ZL[ZKey].RegionID;
				if (RKey ~= nil) then
					local RL = CommonRegionListGet();
					if (type(RL) == "table") then
						if (RL[RKey] ~= nil) then
							KarmaChatDebug("Region: " .. KarmaObj.Helpers.TableToString(RL[RKey]));
						end
					end
				end
			end
		end

		return
	end

	if (cmd == -8) then
		local	sIn = string.format(ERR_INVITED_TO_GROUP_SS, "Test", "Test");
		KarmaChatDebug("In: " .. string.gsub(sIn, "\124", "\124\124"));
		local	sPattern = string.gsub(ERR_INVITED_TO_GROUP_SS, "|Hplayer:%%s|h%[%%s%]|h", "|Hplayer:[^|]+|h%%[(.+)%%]|h");
		KarmaChatDebug("Pattern: " .. string.gsub(sPattern, "\124", "\124\124"));
		local	sName = string.match(sIn, sPattern);
		KarmaChatDebug("Match: " .. (sName or "<nil>"));
		if (sName) then
			DEFAULT_CHAT_FRAME:AddMessage("Karma: |cFF8080FFInvite to group by " .. sName .. ".|r");
		end

		return
	end

	if (cmd == -7) then
		if (KarmaModuleLocal.AchievementCheckTerrorCount == 0) then
			KarmaModuleLocal.AchievementCheckTerrorTimer = GetTime() + 50;
			KarmaModuleLocal.AchievementCheckTerrorCount = 1;
			KarmaModuleLocal.AchievementCheckTerrorList["target"] = UnitName("target");
		end

		return
	end

	if (cmd == -6) then
		KarmaModuleLocal.PlayerRegenEnabledOrMobDied = GetTime();
		return
	end

	if (cmd == -5) then
		local	oMember = Karma_MemberList_GetObject(arg);
		if (oMember) then
			Karma_CleanupRegions(oMember)
		else
			KarmaChatDebug("Unknown player.");
		end
	end

	if (cmd == -4) then
		local	sName, aData, sFrom, aInfo, sInfos;
		for sName, aData in pairs(KarmaModuleLocal.NotesPublic.Results) do
			sInfos = sName .. ": ";
			for sFrom, aInfo in pairs(aData) do
				sInfos = sInfos .. sFrom .. "(";
				if (aInfo.sKarma) then
					sInfos = sInfos .. "K";
				end
				if (aInfo.sNotePub) then
					sInfos = sInfos .. "N" .. strlen(aInfo.sNotePub);
				end
				sInfos = sInfos .. ") ";
			end
			KarmaChatDebug(sName .. ": " .. sInfos);
		end
	end

	if (cmd == -3) then
		KarmaObj.UI.MsgAddOnForceHandling = nil;
		local	_, iMax = GetNumWhoResults();
		local	i;
		for i = 1, iMax do
			SendAddonMessage("KARMA", "?v1", "WHISPER", GetWhoInfo(i));
		end
		KarmaChatDebug("Sent " .. iMax .. " version requests. Chaman, Chassuer, Chevalier, Demo, Druide, Guerrier, Mage, Pala, Pretre, Voleur!");
	end

	if (cmd == -2) then
		if (arg == "GUILD") or (arg == "PARTY") or (arg == "RAID") then
			SendAddonMessage("KARMA", "?v1", arg);
		else
			SendAddonMessage("KARMA", "?v1", "WHISPER", arg);
		end

		return;
	end

	if (cmd == -1) then
		if (KARMA_TalentInspect.RequiredCount == 0) then
			local	sUnit = "target";
			if (CheckInteractDistance(sUnit, 1) == 1) then
				local	sName, sServer = UnitName("target");
				if (sServer) and (sServer ~= "") then
					sName = sName .. "@" .. sServer
				end
				KARMA_TalentInspect.RequiredList[sUnit] = sName;
				KARMA_TalentInspect.RequiredCount = 1;
			end
		end

		return
	end

	if (cmd == 0) then
		-- scriptErrors -> 1
		SetCVar("scriptErrors", true);
		-- scriptKarmaObj.Profile -> 1? true?
		SetCVar("scriptKarmaObj.Profile", true);

		UpdateAddOnCPUUsage();

		local	i = 1;
		if (arg) then
			i = arg;
		end
		local	name, time;
		local	done = false;
		while not done do
			name = GetAddOnInfo(i);
			if name ~= nil then
				time = GetAddOnCPUUsage(i);
				KarmaChatSecondary(name .. KARMA_WINEL_FRAG_COLONSPACE .. time);
			else
				done = true;
			end
			i = i + 1;
		end
	end

	if (cmd == 1) then
		if (arg == nil) then
			arg = "player";
		end

		if not UnitExists(arg) then
			arg = "player";
		end
		
		KarmaChatSecondary("Karma_TEST: arg = " .. Karma_NilToString(arg));

		local x, y = GetPlayerMapPosition(arg);
		KarmaChatSecondary("x/y = " .. x .. "/" .. y);

		Karma_ScanningTooltip:ClearLines()
		Karma_ScanningTooltip:SetUnit(arg);

		local	i;
		for i = 1, Karma_ScanningTooltip:NumLines() do
			local mytext = getglobal("Karma_ScanningTooltipTextLeft" .. i)
			local text = mytext:GetText()
			KarmaChatSecondary("[" .. i .. "]: " .. text);
		end
	end

	if (cmd == 2) then
		local	trigraphs = {};
		local	tri = "";
		local	trimax = "";
		local	trimaxnum = 0;
		local	Memberlist = Karma_MemberList_GetMemberNamesSortedAlpha();
		local	i, Name;
		for i, Name in pairs(Memberlist) do
			local j, len;
			len = strlen(Name);
			for j = 1, len - 2 do
				tri = strsub(Name, j, j + 2);
				if (trigraphs[tri] == nil) then
					trigraphs[tri] = 0;
				end

				trigraphs[tri] = trigraphs[tri] + 1;
			end
		end

		local	trishort = {};
		for tri, i in pairs(trigraphs) do
			if (i > trimaxnum) then
				trimaxnum = i;
				trimax = tri;
			end
			if (i > 5) then
				KarmaChatDebug(tri .. " : " .. i);
			else
				if (trishort[i] == nil) then
					trishort[i] = 0;
				end
				trishort[i] = trishort[i] + 1;
			end
		end

		for tri, i in pairs(trishort) do
			KarmaChatDebug("#" .. tri .. "-tris : " .. i);
		end

		KarmaChatDebug("best: " .. trimax .. " : " .. trimaxnum);

		if (arg ~= nil) then
			local args = {};
			args[1] = "checkonline";
			if (arg == nil) then
				args[2] = trimax;
			else
				args[2] = arg;
			end
			args[3] = KARMA_Filter.Class;

			Karma_Command_CheckOnline_Insert(args);
		end
	end

	if (cmd == 3) then
		local	digraphs = {};
		local	di = "";
		local	dimax = "";
		local	dimaxnum = 0;
		local	Memberlist = Karma_MemberList_GetMemberNamesSortedAlpha();
		local	i, Name;
		for i, Name in pairs(Memberlist) do
			local j, len;
			len = strlen(Name);
			for j = 1, len - 1 do
				di = strsub(Name, j, j + 1);
				if (digraphs[di] == nil) then
					digraphs[di] = 0;
				end

				digraphs[di] = digraphs[di] + 1;
			end
		end

		local	dishort = {};
		for di, i in pairs(digraphs) do
			if (i > dimaxnum) then
				dimaxnum = i;
				dimax = di;
			end
			if (i > 3) then
				KarmaChatDebug(di .. " : " .. i);
			else
				if (dishort[i] == nil) then
					dishort[i] = 0;
				end
				dishort[i] = dishort[i] + 1;
			end
		end

		for di, i in pairs(dishort) do
			KarmaChatDebug("#" .. di .. "-dis : " .. i);
		end

		KarmaChatDebug("best: " .. dimax .. " : " .. dimaxnum);

		if (arg ~= nil) then
			local args = {};
			args[1] = "checkonline";
			if (arg == nil) then
				args[2] = dimax;
			else
				args[2] = arg;
			end
			args[3] = KARMA_Filter.Class;

			Karma_Command_CheckOnline_Insert(args);
		end
	end

	if (cmd == 4) and (arg ~= nil) then
		local	about = arg2;
		if (about == nil) then
			about = UnitName("player");
		end
		if (about) then
			local	arg_u = strupper(arg);
			local	args = {};
			args[2] = arg;
			args[3] = about;
			if (arg_u == "GUILD") or (arg_u == "PARTY") or (arg_u == "RAID") then
				KarmaChatDebug("Karma_TEST(4): to <" .. arg .. "> about [" .. about .. "]");
				args[2] = "$" .. arg_u;
			else
				KarmaChatDebug("Karma_TEST(4): to <WHISPER:" .. arg .. "> about [" .. about .. "]");
			end
			-- "?p" - request
			Karma_SlashShareQuery(args, 3);
		end
	end

	if (cmd == 5) and (arg ~= nil) then
		local	out = TextEncode(arg);
		KarmaChatDebug("encode: " .. arg .. " -> " .. out);
	end

	if (cmd == 6) and (arg ~= nil) then
		local	out = TextDecode(arg);
		KarmaChatDebug("decode: " .. arg .. " -> " .. out);
	end

--[[
	if (cmd == 42) then
		local i, FCount, name, level, class, area, connected, status;
		local found = 0;
		FCount = GetNumFriends();
		for i = 1, FCount do
			name, level, class, area, connected, status = GetFriendInfo(i);
			if (name == arg) then
				KarmaChatDefault("Karma_TEST: " .. name .. " found, online = " .. Karma_NilToString(connected));
				found = 1;
				break;
			end;
		end;
	
		if (found == 0) then
			local DefaultMessages = { GetChatWindowMessages(DEFAULT_CHAT_FRAME:GetID()) };
			local MLML = "";
			for i, name in pairs(DefaultMessages) do
				MLML = MLML .. name .. " / ";
			end
			KarmaChatDefault("Karma_TEST: pre channels = " .. MLML);
	
			RemoveChatWindowMessages(DEFAULT_CHAT_FRAME:GetID(), "SYSTEM");
	
			local DefaultMessages = { GetChatWindowMessages(DEFAULT_CHAT_FRAME:GetID()) };
			local MLML = "";
			for i, name in pairs(DefaultMessages) do
				MLML = MLML .. name .. " / ";
			end
			KarmaChatDefault("Karma_TEST: post channels = " .. MLML);
	
			-- KarmaChatDefault("Karma_TEST: adding");
			KARMA_OnlineCheckAddedFriend = arg;
			AddFriend(arg);
		end;
	end;
]]--
end;
-- Karma_TEST: development helper ;) (end)

function	Karma_Friendlist_Update()
	if (KARMA_OnlineCheckAddedFriend ~= nil) then
		local i, FCount, name, level, class, area, connected, status;
		FCount = GetNumFriends();
		for i = 1, FCount do
			name, level, class, area, connected, status = GetFriendInfo(i);
			if name == KARMA_OnlineCheckAddedFriend then
				KarmaChatDefault("Karma_TEST: " .. name .. " found, online = " .. Karma_NilToString(connected));
				break;
			end
		end
	
		RemoveFriend(KARMA_OnlineCheckAddedFriend);
		KARMA_OnlineCheckAddedFriend = nil;
		AddChatWindowMessages(DEFAULT_CHAT_FRAME:GetID(), "SYSTEM");
	end
end

function	Karma_MemberObject_GetTotalZoneListCount(oMember, bVerbose)
	if (type(oMember) == "table") then
		local TotalZoneListCount = 0;
		local PvpZoneListCount = 0;
		local IgnorePvpZones = Karma_GetConfig(KARMA_CONFIG.CLEAN_IGNOREPVPZONES);
		for char, charobj in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
			if (charobj[KARMA_DB_L6_RRFFMCC_ZONEIDLIST]) then
				for index, ZID in pairs(charobj[KARMA_DB_L6_RRFFMCC_ZONEIDLIST]) do
					if (IgnorePvpZones == 1) and IsPvpZone(ZID) then
						PvpZoneListCount = PvpZoneListCount + 1;
					else
						TotalZoneListCount = TotalZoneListCount + 1;
					end
				end
			end
		end

		if (bVerbose)  then
			KarmaChatDebug(KARMA_TITLE.."::MO::GETZLC(" .. oMember[KARMA_DB_L5_RRFFM.NAME] .. "): ".. PvpZoneListCount .. "/" .. TotalZoneListCount);
		end

		return TotalZoneListCount;
	else
		return 0;
	end
end

function	Karma_MemberObject_GetTotalRegionCount(oMember, bVerbose)
	if (type(oMember) == "table") then
		local	ZoneIDlist = {};
		local	RegionIDlist = {};

		local	CommonRegionList = KarmaObj.DB.CG.RegionListGet();
		local	IgnorePvpZones = Karma_GetConfig(KARMA_CONFIG.CLEAN_IGNOREPVPZONES);
		local	PvpZoneListCount = 0;

		local	char, charobj;
		for char, charobj in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
			if (charobj[KARMA_DB_L6_RRFFMCC_ZONEIDLIST]) then
				local	index, ZID;
				for index, ZID in pairs(charobj[KARMA_DB_L6_RRFFMCC_ZONEIDLIST]) do
					if (IgnorePvpZones == 1) and IsPvpZone(ZID) then
						if (bVerbose) then
							KarmaChatDebug(KARMA_TITLE.."::MO::GETRLC::ZL: iZoneID is pvp => " .. ZID);
						end
						PvpZoneListCount = PvpZoneListCount + 1;
					else
						tinsert(ZoneIDlist, - ZID);
					end
				end
			end

			if (charobj[KARMA_DB_L6_RRFFMCC_REGIONLIST]) then
				local	i1, oRegion;
				for i1, oRegion in pairs(charobj[KARMA_DB_L6_RRFFMCC_REGIONLIST]) do
					local	iRegionID = oRegion[KARMA_DB_L7_RRFFMCCRR_ID];
					if (bVerbose) then
						KarmaChatDebug(KARMA_TITLE.."::MO::GETRLC::RL: iRegionID == " .. iRegionID);
					end

					if (IgnorePvpZones == 1) then
						local	oRegion = CommonRegionList[iRegionID];
						if (oRegion[KARMA_DB_L3_CR.ISPVPZONE] == 1) then
							PvpZoneListCount = PvpZoneListCount + 1000;
						else
							tinsert(RegionIDlist, iRegionID);
						end
					else
						tinsert(RegionIDlist, iRegionID);
					end
				end
			end
		end
		table.sort(ZoneIDlist);

		local CZL = CommonZoneListGet();
		local ZIDPrev = 0;
		local i, ZID, ZRegionID;
		for i, ZID in pairs(ZoneIDlist) do
			if ZID ~= ZIDPrev then
				ZRegionID = CZL[ZID].RegionID
				if (ZRegionID ~= nil) then
					tinsert(RegionIDlist, ZRegionID);
				end
			end
			ZIDPrev = ZID;
		end
		table.sort(RegionIDlist);

		local TotalRegionCount = 0;
		local RIDPrev = 0;
		local i, RID;
		for i, RID in pairs(RegionIDlist) do
			if (RID ~= RIDPrev) then
				TotalRegionCount = TotalRegionCount + 1;
			end
			RIDPrev = RID;
		end

		if (bVerbose)  then
			KarmaChatDebug(KARMA_TITLE.."::MO::GETRLC(" .. oMember[KARMA_DB_L5_RRFFM.NAME] .. "): ".. PvpZoneListCount .. "/" .. TotalRegionCount);
		end

		return TotalRegionCount;
	else
		return 0;
	end
end

function	Karma_MemberObject_GetCharacterObject(oMember, charactername)
	if (charactername == nil) then
		charactername = KARMA_CURRENTCHAR;
	end
	if (charactername == nil) then
		return nil;
	end

	if (oMember[KARMA_DB_L5_RRFFM_CHARACTERS] == nil or
		oMember[KARMA_DB_L5_RRFFM_CHARACTERS][charactername] == nil) then
		if (Karma_GetConfig(KARMA_CONFIG.DB_SPARSE) == 1) then	-- dbsparse
			-- don't add lots of containers anymore
			if (oMember[KARMA_DB_L5_RRFFM_CHARACTERS] == nil) then
				return nil;
			end
		else
			-- Create all the fields required for this particular character/member.
			if (charactername == UnitName("player")) then
				Karma_MemberList_Add(Karma_MemberObject_GetName(oMember));
				Karma_MemberList_Update(Karma_MemberObject_GetName(oMember));
			end
		end
	end

	return oMember[KARMA_DB_L5_RRFFM_CHARACTERS][charactername];
end


-- Set Functions

-- dangerous setters => local'ed.
-- required for forcenew/forcecheck
Karma_MemberObject_SetName = function (oMember, name)
	if (type(oMember) == "table") then
		KarmaObj.DB.M.Modified(oMember, "NameByForceChange");
		oMember[KARMA_DB_L5_RRFFM.NAME] = name;
		oMember[KARMA_DB_L5_RRFFM.NAME .. ":SIC"] = name;
	end
end

-- required for xupdate
Karma_MemberObject_SetGUID = function(oMember, sGUID)
	if (type(oMember) == "table") then
		oMember[KARMA_DB_L5_RRFFM.GUID] = sGUID;
	end
end

--[[
-- unused
function	Karma_MemberObject_SetTimePlayed(oMember, played)
	if (type(oMember) == "table") then
		local	charobj = Karma_MemberObject_GetCharacterObject(oMember);
		charobj[KARMA_DB_L6_RRFFMCC_PLAYED] = played;
	end
end
]]--


function	Karma_MemberObject_SetKarma(oMember, karmarating)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_KARMA] ~= karmarating) then
			KarmaObj.DB.M.Modified(oMember, "Karma value");
			oMember[KARMA_DB_L5_RRFFM_KARMA] = karmarating;
		end
	end
end

function	Karma_MemberObject_SetTalentID(oMember, iSpec, iTalent)
	if (type(oMember) == "table") then
		if (iTalent) then
			local	sKey = KARMA_DB_L5_RRFFM_TALENT .. "_" .. iSpec;
			if (oMember[sKey] ~= iTalent) then
				KarmaObj.DB.M.Modified(oMember, "Talent " .. (iSpec or ""));
				oMember[sKey] = iTalent;
			end
			if (iSpec == 1) then	-- TODO: dual-cleanup
				oMember[KARMA_DB_L5_RRFFM_TALENT] = iTalent;
			end
		end
	end
end

function	Karma_MemberObject_SetAltID(oMember, altid)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM.ALTGROUP] ~= altid) then
			KarmaObj.DB.M.Modified(oMember, "Alt group");
			oMember[KARMA_DB_L5_RRFFM.ALTGROUP] = altid;
		end
	end
end

function	Karma_MemberObject_SetNotes(oMember, text)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_NOTES] ~= text) then
			if	(KarmaTrans_Changelog ~= nil) and
			    (Karma_GetConfig(KARMA_CONFIG.DEBUG_ENABLED) == 1) then
				KarmaTrans_Changelog("KMOSetNotes(" .. oMember[KARMA_DB_L5_RRFFM.NAME] .. ")", oMember[KARMA_DB_L5_RRFFM_NOTES], text);
			end

			oMember[KARMA_DB_L5_RRFFM_NOTES_TIME] = time();
			oMember[KARMA_DB_L5_RRFFM_NOTES] = text;

			KarmaObj.DB.M.Modified(oMember, "Private notes");
		end
	end
end

function	Karma_MemberObject_SetPublicNotes(oMember, text)
	if (type(oMember) == "table") then
		-- we don't want this to be *long*
		text = KarmaObj.UTF8.SubInChars(text, 1, 40);
		if (oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES] ~= text) then
			if	(KarmaTrans_Changelog ~= nil) and
			    (Karma_GetConfig(KARMA_CONFIG.DEBUG_ENABLED) == 1) then
				KarmaTrans_Changelog("KMOSetPublicNotes(" .. oMember[KARMA_DB_L5_RRFFM.NAME] .. ")", oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES], text);
			end

			if ((oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES] ~= nil) and
			    (oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES] ~= "")) then
				local	iOld = 0;
				if (oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES_TIME]) then
					iOld = oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES_TIME];
				end
				if (time() - iOld > 76800) then
					local	sValue = oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES_HISTORY];
					sValue = sValue .. date(KARMA_DATEFORMAT .. " %H:%M:%S", iOld) .. ": >>\n" .. oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES] .. "\n<<\n\n";
					oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES_HISTORY] = sValue;
				end
			end

			oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES_TIME] = time();
			oMember[KARMA_DB_L5_RRFFM_PUBLIC_NOTES] = text;

			KarmaObj.DB.M.Modified(oMember, "'Public' notes");
		end
	end
end

function	Karma_MemberObject_SetSkill(oMember, iSkill)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_SKILL] ~= iSkill) then
			KarmaObj.DB.M.Modified(oMember, "Skill");
			oMember[KARMA_DB_L5_RRFFM_SKILL] = iSkill;
		end
	end
end

function	Karma_MemberObject_SetGearPVP(oMember, iLevel)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_GEAR_PVP] ~= iLevel) then
			KarmaObj.DB.M.Modified(oMember, "PvP gear");
			oMember[KARMA_DB_L5_RRFFM_GEAR_PVP] = iLevel;
		end
	end
end

function	Karma_MemberObject_SetGearPVE(oMember, iLevel)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM_GEAR_PVE] ~= iLevel) then
			KarmaObj.DB.M.Modified(oMember, "PvE gear");
			oMember[KARMA_DB_L5_RRFFM_GEAR_PVE] = iLevel;
		end
	end
end

-----------------------------------------
-- ACCESSOR FUNCTIONS
-----------------------------------------

function	Karma_AddCharacterToDatabase(oMember)
	KarmaObj.ProfileStart("Karma_AddCharacterToDatabase");
	Karma_MemberList_Add(oMember[KARMA_DB_L5_RRFFM.NAME]);
	Karma_MemberList_Update(oMember[KARMA_DB_L5_RRFFM.NAME]);
	KarmaObj.ProfileStop("Karma_AddCharacterToDatabase");
end

function	Karma_RegionTypeResetAll()
	local	RegionList, iIndex, oRegion = KarmaObj.DB.CG.RegionListGet();
	for iIndex, oRegion in pairs(RegionList) do
		if ((oRegion[KARMA_DB_L3_CR.ISPVPZONE] ~= nil) or (oRegion[KARMA_DB_L3_CR.ZONETYPE] ~= nil)) then
			KarmaChatDebug("Region[" .. (oRegion.Name or "<nil>") .. "].Type: pvp=" .. (oRegion[KARMA_DB_L3_CR.ISPVPZONE] or "<nil>") .. ", inst=" .. (oRegion[KARMA_DB_L3_CR.ZONETYPE] or "<nil>") .. " -> nil/nil");
			oRegion[KARMA_DB_L3_CR.ISPVPZONE] = nil;
			oRegion[KARMA_DB_L3_CR.ZONETYPE] = nil;
		end
	end
end


function	Karma_CleanDatabase()
	-- Not a lot of point in having people listed who have no notes, neutral(50) karma, and no quest/area info.
	KarmaObj.ProfileStart("Karma_CleanDatabase");
	if (Karma_GetConfig(KARMA_CONFIG.CLEAN_AUTO)) then
		Karma_ClearUnused(KarmaObj.DB.FactionCacheGet());
	end
	KarmaObj.ProfileStop("Karma_CleanDatabase");
end

function	Karma_ClearUnused(oFaction, extra, pvponly_b)
	-- This will attempt to delete any members that have no karma, notes, and zone/quest info
	local	IsDryRun = false;
	local	CheckOnlyBucket, CheckOnlyChar;
	if (extra ~= nil) then
		IsDryRun = extra == "dryrun";
		CheckOnlyChar = (type(extra) == "string") and (strsub(extra, 1, 5) == "test:");
		if (not IsDryRun and not CheckOnlyChar) then
			KarmaChatDefault(KARMA_MSG_DBCLEAN_EXTRAARG);
			return
		end

		if (CheckOnlyChar) then
			IsDryRun = true;
			CheckOnlyChar = strsub(extra, 6);
			CheckOnlyBucket = KarmaObj.NameToBucket(CheckOnlyChar);
			KarmaChatDefault("Only checking char " .. CheckOnlyChar .. "...");
		end
	end

	-- must not remove people from list who are in party, so demand that we are not in a party...
	if (GetNumPartyMembers() > 0) and not IsDryRun then
		KarmaChatDefault(KARMA_MSG_DBCLEAN_INGROUP);
		return
	end

	-- Known bug: Removing doesn't work properly if the Karma window is open.
	-- Maybe does now, since all Karma_GetMemberObject were changed into Karma_MemberList_GetObject? Gotta test some day... TODO.
	if not IsDryRun and KarmaWindow:IsVisible() then
		KarmaWindow:Hide();
	end

	Karma_SetCurrentMember(nil);

	local KeepReasons;

	local RL = CommonRegionListGet();
	for i, v in pairs(RL) do
		if	(v.Name == KARMA_PVPZONE_WSG) or
			(v.Name == KARMA_PVPZONE_AB) or
			(v.Name == KARMA_PVPZONE_AV) or
			(v.Name == KARMA_PVPZONE_ES) or
			(v.Name == KARMA_PVPZONE_SA) or
			(v.Name == KARMA_PVPZONE_WG) then
			KarmaChatDebug("<" .. v.Name .. ">: will be/is marked as pvp-region.");
			if (v[KARMA_DB_L3_CR.ISPVPZONE] ~= 1) then
				KarmaChatDefault("<" .. v.Name .. "> " .. KARMA_MSG_DBCLEAN_PVPREGIONMARKED);
				v[KARMA_DB_L3_CR.ISPVPZONE] = 1;
			end
		end
	end

	local	sMsgStart;
	if IsDryRun then
		sMsgStart = KARMA_MSG_DBCLEAN_PRETEXT_DRYRUN .. KARMA_WINEL_FRAG_TRIDOTS;
	else
		sMsgStart = KARMA_MSG_DBCLEAN_PRETEXT_NORMAL .. KARMA_WINEL_FRAG_TRIDOTS;
	end
	if (pvponly_b == 1) then
		sMsgStart = sMsgStart .. " (pvp entries)";
	end
	KarmaChatDefault(sMsgStart);

	local	KarmaValue;
	local	RemoveEntry, ForceRemoveEntry, PartyIndex;

	-- configurable 'clean' parameters
	local	KARMA_CleanCheckNoteNotEmpty;
	if (Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFNOTE) ~= 0) then
		KARMA_CleanCheckNoteNotEmpty = 1;
	else
		KARMA_CleanCheckNoteNotEmpty = 0;
	end

	local	KARMA_CleanCheckNotPvPJoin;
	if (Karma_GetConfig(KARMA_CONFIG.CLEAN_REMOVEPVPJOINS) ~= 0) then
		KARMA_CleanCheckNotPvPJoin = 1;
	else
		KARMA_CleanCheckNotPvPJoin = 0;
	end

	local	KARMA_CleanCheckNotXServer;
	if (Karma_GetConfig(KARMA_CONFIG.CLEAN_REMOVEXSERVER) ~= 0) then
		KARMA_CleanCheckNotXServer = 1;
	else
		KARMA_CleanCheckNotXServer = 0;
	end

	local	KARMA_CleanCheckKarmaNot50;
	if (Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFKARMA) ~= 0) then
		KARMA_CleanCheckKarmaNot50 = 1;
	else
		KARMA_CleanCheckKarmaNot50 = 0;
	end

	local	KARMA_CleanCheckQuestlistThreshold;
	local Value = Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFQUESTCOUNT);
	if (Value ~= nil) then
		Value = tonumber(Value);
	end
	if (type(Value) == "number") then
		KARMA_CleanCheckQuestlistThreshold = Value;
	else
		KARMA_CleanCheckQuestlistThreshold = 1;
	end

	local	KARMA_CleanCheckRegionlistThreshold;
	Value = Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFREGIONCOUNT);
	if (Value ~= nil) then
		Value = tonumber(Value);
	end
	if (type(Value) == "number") then
		KARMA_CleanCheckRegionlistThreshold = Value;
	else
		KARMA_CleanCheckRegionlistThreshold = 2;
	end

	local	KARMA_CleanCheckZonelistThreshold;
	Value = Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFZONECOUNT);
	if (Value ~= nil) then
		Value = tonumber(Value);
	end
	if (type(Value) == "number") then
		KARMA_CleanCheckZonelistThreshold = Value;
	else
		KARMA_CleanCheckZonelistThreshold = 4;
	end

	-- dryrun message
	local	MsgStart = "Cleanup dryrun ";

	local	MsgCountKeep = 0;
	local	MsgLinesCountKeep = 1;
	local	MsgCurrentKeep = "";
	local	MsgCurrentKeepList = {};

	local	MsgCountRemove = 0;
	local	MsgLinesCountRemove = 1;
	local	MsgCurrentRemove = "";
	local	MsgCurrentRemoveList = {};

	local	RemoveCount = 0;
	local	TotalCount = 0;
	local	lMembers = KarmaObj.DB.SF.MemberListGet(oFaction);
	for sBucketName, BucketValue in pairs(lMembers) do -- Loop through each bucket
		if (not CheckOnlyBucket or (sBucketName == CheckOnlyBucket)) then
			for sMemberName, value in pairs(BucketValue) do -- Loop through contents of bucket
				if (not CheckOnlyChar or (sMemberName == CheckOnlyChar)) then
					-- Dealing with an entry in this bucket
					local	oMember = value;
					TotalCount = TotalCount + 1;
					KarmaValue = Karma_MemberObject_GetKarmaModified(oMember);

					ForceRemoveEntry = 0;
					RemoveEntry = 1;

					if (IsDryRun) then
						KeepReasons = "";
					end

					-- pre-test: definitely remove these entries
					if	(
							(KarmaValue == nil) or
							(strupper(sMemberName) == strupper(KARMA_UNKNOWN_ENT)) or
							(strupper(sMemberName) == strupper(KARMA_UNKNOWN))
						) then
						ForceRemoveEntry = 1;
						RemoveEntry = 0; -- skip further tests
						if IsDryRun then
							KeepReasons = KeepReasons .. "-K|UNK!";
						end
					end

					-- now for the (soon to be configurable) parts...

					-- keep entry if note is not empty
					if ((RemoveEntry == 1) or IsDryRun) and (KARMA_CleanCheckNoteNotEmpty == 1) then
						local NoteValue = Karma_MemberObject_GetNotes(oMember);
						if (NoteValue ~= nil) and (NoteValue ~= "") then
							RemoveEntry = 0;
							if IsDryRun then
								KeepReasons = KeepReasons  .. "+N";
							end
						end
					end

					-- force-remove entry if joined in pvp and no note
					if ((RemoveEntry == 1) or IsDryRun) and (KARMA_CleanCheckNotPvPJoin == 1) then
						local	ZID = KarmaObj.DB.M.AddedZoneGet(oMember);
						if (ZID and IsPvpZone(ZID)) then
							ForceRemoveEntry = 1;
							RemoveEntry = 0; -- skip further tests
							if IsDryRun then
								KeepReasons = KeepReasons  .. "-PVP!";
							end
						end
					end

					-- force-remove entry if XServer and no note
					if ((RemoveEntry == 1) or IsDryRun) and (KARMA_CleanCheckNotXServer == 1) then
						if (string.find(sMemberName, "(*)", 1, true) ~= nil) or
						   (string.find(sMemberName, "@", 1, true) ~= nil) then
							ForceRemoveEntry = 1;
							RemoveEntry = 0; -- skip further tests
							if IsDryRun then
								KeepReasons = KeepReasons  .. "-*!";
							end
						end
					end

					-- keep entry if Karma is not 50
					if ((RemoveEntry == 1) or IsDryRun) and (KARMA_CleanCheckKarmaNot50 == 1) then
						if (KarmaValue ~= 50) and (KarmaValue ~= nil) then
							RemoveEntry = 0;
							if IsDryRun then
								KeepReasons = KeepReasons  .. "+K";
							end
						end
					end

					-- keep entry if Questlist has threshold entries
					if ((RemoveEntry == 1) or IsDryRun) and (KARMA_CleanCheckQuestlistThreshold > 0) then
						local TotalQuestListCount = Karma_MemberObject_GetTotalQuestListCount(oMember);
						if (TotalQuestListCount >= KARMA_CleanCheckQuestlistThreshold) then
							RemoveEntry = 0;
							if IsDryRun then
								KeepReasons = KeepReasons  .. "+Q(" .. TotalQuestListCount .. ")";
							end
						end
					end

					-- keep entry if Zonelist has threshold entries
					if ((RemoveEntry == 1) or IsDryRun) and (KARMA_CleanCheckZonelistThreshold > 0) then
						local TotalZoneListCount = Karma_MemberObject_GetTotalZoneListCount(oMember, CheckOnlyChar);
						if (TotalZoneListCount >= KARMA_CleanCheckZonelistThreshold) then
							RemoveEntry = 0;
							if IsDryRun then
								KeepReasons = KeepReasons  .. "+Z(" .. TotalZoneListCount .. ")";
							end
						end
					end

					-- keep entry if Zonelist-Region-total has threshold entries
					if ((RemoveEntry == 1) or IsDryRun) and (KARMA_CleanCheckRegionlistThreshold > 0) then
						local TotalRegionCount = Karma_MemberObject_GetTotalRegionCount(oMember, CheckOnlyChar);
						if (TotalRegionCount >= KARMA_CleanCheckRegionlistThreshold) then
							RemoveEntry = 0;
							if IsDryRun then
								KeepReasons = KeepReasons  .. "+R(" .. TotalRegionCount .. ")";
							end
						end
					end

					-- cleanpvp: drop all pvp but those with Karma/Note
					if (pvponly_b == 1) and (ForceRemoveEntry ~= 1) then
						RemoveEntry = 0;
					end

					if (RemoveEntry == 1) or (ForceRemoveEntry == 1) then
						if IsDryRun then
							MsgCurrentRemove = MsgCurrentRemove .. " |cFFFF3F3F-" .. sMemberName .. "(" .. KeepReasons .. ")";
							MsgCountRemove = MsgCountRemove + 1;
						else
							Karma_MemberList_Remove(sMemberName);
						end
						RemoveCount = RemoveCount + 1;
					else
						if IsDryRun then
							MsgCurrentKeep = MsgCurrentKeep .. " |cFF3FFF3F+" .. sMemberName .. "(" .. KeepReasons .. ")";
							MsgCountKeep = MsgCountKeep + 1;
						end
					end

					if IsDryRun then
						if MsgCountKeep >= 12 then
							MsgCurrentKeep = MsgStart .. " (" .. MsgLinesCountKeep .. ") =>" .. MsgCurrentKeep;
							MsgCurrentKeepList[MsgLinesCountKeep] = MsgCurrentKeep;
							MsgLinesCountKeep = MsgLinesCountKeep + 1;

							MsgCurrentKeep = "";
							MsgCountKeep = 0;
						end
						if MsgCountRemove >= 12 then
							MsgCurrentRemove = MsgStart .. " (" .. MsgLinesCountRemove .. ") =>" .. MsgCurrentRemove;
							MsgCurrentRemoveList[MsgLinesCountRemove] = MsgCurrentRemove;
							MsgLinesCountRemove = MsgLinesCountRemove + 1;

							MsgCurrentRemove = "";
							MsgCountRemove = 0;
						end
					end
				end
			end
		end
	end

	if IsDryRun then
		-- don't forget the last segment!
		if MsgCountKeep > 0 then
			MsgCurrentKeep = MsgStart .. " (" .. MsgLinesCountKeep .. ") =>" .. MsgCurrentKeep;
			MsgCurrentKeepList[MsgLinesCountKeep] = MsgCurrentKeep;
			MsgLinesCountKeep = MsgLinesCountKeep + 1;

			MsgCurrentKeep = "";
			MsgCountKeep = 0;
		end
		if MsgCountRemove > 0 then
			MsgCurrentRemove = MsgStart .. " (" .. MsgLinesCountRemove .. ") =>" .. MsgCurrentRemove;
			MsgCurrentRemoveList[MsgLinesCountRemove] = MsgCurrentRemove;
			MsgLinesCountRemove = MsgLinesCountRemove + 1;

			MsgCurrentRemove = "";
			MsgCountRemove = 0;
		end

		local	iLine;
		for iLine = 1, MsgLinesCountKeep - 1 do
			KarmaChatDebug(MsgCurrentKeepList[iLine]);
		end
		for iLine = 1, MsgLinesCountRemove - 1 do
			KarmaChatSecondary(MsgCurrentRemoveList[iLine]);
		end

		KarmaChatDefault(KARMA_MSG_DBCLEAN_RESULT_DRYRUN1 .. RemoveCount .. KARMA_MSG_DBCLEAN_RESULT_DRYRUN2
							.. KARMA_WINEL_FRAG_COLONSPACE .. (TotalCount - RemoveCount)
							.. KARMA_MSG_DBCLEAN_RESULT_3);
	else
		KarmaChatDefault(KARMA_MSG_DBCLEAN_RESULT_NORMAL1 .. RemoveCount .. KARMA_MSG_DBCLEAN_RESULT_NORMAL2
							.. KARMA_WINEL_FRAG_COLONSPACE .. (TotalCount - RemoveCount)
							.. KARMA_MSG_DBCLEAN_RESULT_3);
	end

	Karma_MemberList_CreateMemberNamesCache();
end

--
-- ----------------------------------------------------------------------------
--

function	Karma_AddCurrentPartyToDatabase()
	KarmaObj.ProfileStart("Karma_AddCurrentPartyToDatabase");
	-- This goes through the current party members and adds them to the
	-- database.
	Karma_VisitAllGroupMembers(Karma_AddCharacterToDatabase, nil);

	KarmaObj.ProfileStop("Karma_AddCurrentPartyToDatabase");
end

--
-- Add zone to 1
--
local	ZoneAddTime = 0;
local	ZoneAddFlag = 1;
local	ZoneAddDone = 0;
local	ZoneIdPrev = 0;
local	ZoneId = 0;
local	RegionGap = 900;				-- 15m Relog-Gap allowed
local	RegionLogID = nil;
local	RegionLogKey = nil;
local	RegionLogDayID = nil;
local	RegionLogDayKey = nil;

function	Karma_AddZoneToPartyMember(oMember, memberfield_character)
	local	iTime = GetTime();

	-- delay after zoning
	if (Karma_ZoneChanged ~= 0) then
		ZoneAddFlag = 0;
		ZoneAddTime = iTime + 20;

		KarmaChatDebug("AddZoneToPartyMember: Reset AddFlag due to zone change.");
		return
	end

	-- don't add anything while we're dead
	if (UnitIsGhost("player") == 1) then
		-- next 'real' update should be triggered by zoning
		ZoneAddFlag = 0;
		ZoneAddTime = iTime + 120;

		KarmaChatDebug("AddZoneToPartyMember: Reset AddFlag due to you being a ghost.");
		return
	end

	-- prelude postactive: set time and zone
	-- (only once per update for the party, therefore extra call in Add*ToPartyMembers())
	if (memberfield_character == nil) then
		local	iParty = GetNumPartyMembers();
		local	iRaid = GetNumRaidMembers();
		if (iRaid > 0) then
			iParty = 0;
		end
		if (ZoneAddTime < iTime) then
			ZoneAddFlag = 1;
			ZoneAddTime = iTime + 20 + iParty * 5 + iRaid * 5;

			if (ZoneIdPrev ~= ZoneId) then
				-- one faster update, maybe someone died or was just out of line of sight or zoned slow
				ZoneAddTime = iTime + 20;
			end
		elseif (ZoneAddDone == 1) then
			ZoneAddFlag = 0;
			ZoneAddDone = 0;
			ZoneIdPrev = ZoneId;
		end

		if (iParty + iRaid > 0) then
			local	sStack = debugstack(3, 1, 0);
			KarmaChatDebug("AddZoneToPartyMember: Flag = " .. ZoneAddFlag .. ", next in " .. (ZoneAddTime - GetTime()) .. " (from " .. sStack .. ")");
		end

		return
	end

-- KarmaChatDebug("AddZoneToPartyMember: >>");

	-- get UnitID (name does not work for UnitXXX - functions)
	local uname = Karma_MemberList_MemberNameToUnitName(Karma_MemberObject_GetName(oMember));
	if (uname == nil) or not UnitExists(uname) then
		KarmaChatDebug("AddZoneToPartyMember: Failed to find matching unit for <" .. Karma_MemberObject_GetName(oMember) .. ">");
		return
	end

	-- new: only add if visible... no list for leechers
	if (UnitIsVisible(uname) == nil) then
-- KarmaChatDebug("AddZoneToPartyMember: << (2)");
		return
	end

	local	RegionID, negZoneID;
	-- ZoneId, RegionID = Karma_ZoneList_AddZone(GetMinimapZoneText());
	negZoneID, RegionID = CommonRegionZoneAddCurrent();
	if (negZoneID == nil) then
-- KarmaChatDebug("AddZoneToPartyMember: << (3.1) " .. GetMinimapZoneText());
		return;
	end

	ZoneId = - negZoneID;

	-- new: every 60 seconds be enough for the same zone..
	if (ZoneAddFlag == 0) then
-- KarmaChatDebug("AddZoneToPartyMember: << (3)");
		return
	end

	ZoneAddDone = 1;
	KarmaChatDebug("Region/Zone update...");

	local	bTrackZonePvP = true;
	if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEPVPAREAS) == 1) then
		if (IsPvpZone(ZoneId)) then
			KarmaChatDebug("Pvp area tracking disabled.");
			bTrackZonePvP = false;
		end
	end

	local	bTrackZoneNormal = true;
	if (bTrackZonePvP and (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEZONE) == 1)) then
		KarmaChatDebug("Zone tracking disabled.");
		bTrackZoneNormal = false;
	end

	KarmaObj.DB.M.AddedZoneSet(oMember, memberfield_character, ZoneId, bTrackZonePvP and bTrackZoneNormal);

	if (not bTrackZonePvP) then
		return
	end

-- KarmaChatDebug("AddZoneToPartyMember: RegionID = " .. (RegionID or "nil"));
	if (RegionID) then
		local	bInInstance, iType = IsInInstance();
-- KarmaChatDebug("AddZoneToPartyMember: bInInstance = " .. (bInInstance or "nil") .. ", iType = " .. (iType or "nil"));
		if (bInInstance) and (iType == "party") or (iType == "raid") then
			if (Karma_GetConfig(KARMA_CONFIG.TRACK_DISABLEREGION) == 1) then
				KarmaChatDebug("Region tracking disabled.");
				return
			end


			local	iDifficulty = GetInstanceDifficulty();
			if (iType == "raid") then
				iDifficulty = iDifficulty + 10;
			end
			local	bRegionKeysValid;

			-- if we add to same region since last time, maybe don't have to check thru all regions...
			if (RegionLogID) and (RegionKey) then
				local	RegionLog = memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST][RegionLogID];
				if (type(RegionLog) == "table") then
					if  (RegionLog[KARMA_DB_L7_RRFFMCCRR_KEY] == RegionLogKey) and
						(RegionLog[KARMA_DB_L7_RRFFMCCRR_ID] == RegionID) and
						(RegionLog[KARMA_DB_L7_RRFFMCCRR_DIFF] == iDifficulty) then
						bRegionKeysValid = true;
					end
				end
			end

			-- didn't have key yet or different key than region? check thru all regions...
			if (bRegionKeysValid == nil) then
				local	key, value;
				for key, value in pairs(memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST]) do
					if  (value[KARMA_DB_L7_RRFFMCCRR_ID] == RegionID) and
						(value[KARMA_DB_L7_RRFFMCCRR_DIFF] == iDifficulty) then
						RegionLogID = key;
						RegionLogKey = value[KARMA_DB_L7_RRFFMCCRR_KEY];
						bRegionKeysValid = true;
					end
				end
			end

			-- still invalid? add new entry
			if (bRegionKeysValid == nil) then
				RegionLogID = 1 + #memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST];
				RegionLogKey = time();

				-- if we move fast across zone boundaries after being ported e.g.,
				-- time() might become be a duplicate key by accident
				-- check and if true, increase until unique
				local	key, value, maxkey;
				maxkey = 0;
				for key, value in pairs(memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST]) do
					if (value[KARMA_DB_L7_RRFFMCCRR_KEY] >= RegionLogKey) then
						maxkey = value[KARMA_DB_L7_RRFFMCCRR_KEY];
					end
				end
				if (maxkey > 0) then
					RegionLogKey = maxkey + 1;
				end

				memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST][RegionLogID] = {};

				local	RegionLog = memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST][RegionLogID];
				RegionLog[KARMA_DB_L7_RRFFMCCRR_KEY] = RegionLogKey;
				RegionLog[KARMA_DB_L7_RRFFMCCRR_ID] = RegionID;
				RegionLog[KARMA_DB_L7_RRFFMCCRR_DIFF] = iDifficulty;
				RegionLog[KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL] = 0;
				RegionLog[KARMA_DB_L7_RRFFMCCRR_PLAYEDDAYS] = {};
				bRegionKeysValid = true;
KarmaChatDebug("AddZoneToPartyMember: added new RegionLog entry, {" .. RegionID .. ": " .. RegionLogKey .. ", " .. iDifficulty .. "}");
			end

			if (type(memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST]) ~= "table") then
KarmaChatDebug("Oops: RegionList broken (1)");
				return;
			end
			if (type(memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST][RegionLogID]) ~= "table") then
KarmaChatDebug("Oops: RegionList broken (2)");
				return;
			end
			if (type(memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST][RegionLogID][KARMA_DB_L7_RRFFMCCRR_PLAYEDDAYS]) ~= "table") then
KarmaChatDebug("Oops: RegionList broken (3)");
				return;
			end

			-- set total to negative, so we know that we need to add up the times to show:
			local	RegionLog = memberfield_character[KARMA_DB_L6_RRFFMCC_REGIONLIST][RegionLogID];
			RegionLog[KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL] = - abs(RegionLog[KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL]);

			-- ok, now we have a container with the zone/difficulty
			-- now we've gotta check for a subcontainer with times
			local	Days = RegionLog[KARMA_DB_L7_RRFFMCCRR_PLAYEDDAYS];
			local	bRegionDayValid;
			if (RegionLogDayID) then
				local	Day = Days[RegionLogDayID];
				if (type(Day) == "table") and
					(Day[KARMA_DB_L8_RRFFMCCRRD_KEY] == RegionLogDayKey) then
					local	endtime = Day[KARMA_DB_L8_RRFFMCCRRD_END];
					if (time() - endtime) < RegionGap then
						bRegionDayValid = true;
					end
				end
			end

			if (bRegionDayValid == nil) then
				local	key, value, endtime, enddelta;
				enddelta = RegionGap;								-- 10 minutes gap allowed for relogging
				for key, value in pairs(Days) do
					if (type(value) == "table") then
						endtime = value[KARMA_DB_L8_RRFFMCCRRD_END];
						if (time() - endtime) < enddelta then
							bRegionDayValid = true;
							RegionLogDayID = key;
							RegionLogDayKey = value[KARMA_DB_L8_RRFFMCCRRD_KEY];
							enddelta = time() - endtime;
						end
					end
				end
			end

			-- if the starttime is more than 12 hours away, don't accept the key
			if (bRegionDayValid) then
				local	starttime = Days[RegionLogDayID][KARMA_DB_L8_RRFFMCCRRD_START];
				if (starttime == nil) or ((time() - starttime) > 43200) then
					bRegionDayValid = nil;
					RegionLogDayID = nil;
					RegionLogDayKey = nil;
				end
			end

			-- nothing found or something found but thrown away: add new.
			if (bRegionDayValid == nil) then
				RegionLogDayID = 1 + #Days;
				RegionLogDayKey = time();
				-- if we move fast across zone boundaries after being ported e.g.,
				-- time() might become be a duplicate key by accident
				-- check and if true, increase until unique
				local	key, value, maxkey;
				maxkey = 0;
				for key, value in pairs(Days) do
					if (value[KARMA_DB_L8_RRFFMCCRRD_KEY] >= RegionLogDayKey) then
						maxkey = value[KARMA_DB_L8_RRFFMCCRRD_KEY];
					end
				end
				if (maxkey > 0) then
					RegionLogDayKey = maxkey + 1;
				end

				Days[RegionLogDayID] = {};
				local	Day = Days[RegionLogDayID];
				Day[KARMA_DB_L8_RRFFMCCRRD_KEY] = RegionLogDayKey;
				Day[KARMA_DB_L8_RRFFMCCRRD_START] = RegionLogDayKey;
				Day[KARMA_DB_L8_RRFFMCCRRD_END] = RegionLogDayKey;
KarmaChatDebug("AddZoneToPartyMember: adding new Day, {" .. RegionLogDayID .. ": " .. RegionLogDayKey .. "}");
			end

			if (type(Days[RegionLogDayID]) ~= "table") then
KarmaChatDebug("Oops: RegionDayList broken (1)");
				return;
			end

-- KarmaChatDebug("AddZoneToPartyMember: Instance start at " .. date("%m-%d %H:%M:%S", Days[RegionLogDayID][KARMA_DB_L8_RRFFMCCRRD_START])
-- 	.. ", end expanded from " .. date("%H:%M:%S", Days[RegionLogDayID][KARMA_DB_L8_RRFFMCCRRD_END]) .. " to " .. date("%H:%M:%S", time()));

			-- now hopefully there's a full-blown correct entry... just move the endtime.
			local	Day = Days[RegionLogDayID];
			Day[KARMA_DB_L8_RRFFMCCRRD_END] = time();
		end
	end

-- KarmaChatDebug("AddZoneToPartyMember: << (4)");
end

--
-- Add xp to 1
--
function	Karma_AddXPToPartyMember(oMember)
	KarmaObj.ProfileStart("Karma_AddXPToPartyMember");
	local	newxp = UnitXP("player");
	local	accrued = 0;

	KOH.TableInit(oMember, KARMA_DB_L5_RRFFM_CHARACTERS);
	local	memberfield_characterlist = oMember[KARMA_DB_L5_RRFFM_CHARACTERS];

	KOH.TableInit(memberfield_characterlist, UnitName("player"));
	local	memberfield_character = memberfield_characterlist[UnitName("player")];

	KOH.TableInit(memberfield_character, KARMA_DB_L6_RRFFMCC_QUESTIDLIST);
	KOH.TableInit(memberfield_character, KARMA_DB_L6_RRFFMCC_QUESTEXLIST);
	KOH.TableInit(memberfield_character, KARMA_DB_L6_RRFFMCC_ZONEIDLIST);
	Karma_FieldInitialize(memberfield_character, KARMA_DB_L6_RRFFMCC_XP, 0);
	Karma_FieldInitialize(memberfield_character, KARMA_DB_L6_RRFFMCC_XPLAST, UnitXP("player"));
	Karma_FieldInitialize(memberfield_character, KARMA_DB_L6_RRFFMCC_XPMAX, UnitXPMax("player"));

	local	accrued_rel = 0;
	Karma_FieldInitialize(memberfield_character, KARMA_DB_L6_RRFFMCC_XPLVL, 0);

	local	memlast = memberfield_character[KARMA_DB_L6_RRFFMCC_XPLAST];
	local	memmax = memberfield_character[KARMA_DB_L6_RRFFMCC_XPMAX];
	if (newxp < memlast) then
		-- Ding!
		accrued = (memmax - memlast) + newxp;
		accrued_rel = (memmax - memlast) / memmax + newxp / UnitXPMax("player");
	else
		accrued = newxp - memlast;
		accrued_rel = (newxp - memlast) / memmax;
	end

	memberfield_character[KARMA_DB_L6_RRFFMCC_XPLAST] = UnitXP("player");
	memberfield_character[KARMA_DB_L6_RRFFMCC_XPMAX] = UnitXPMax("player");

	-- only add to visibles
	local name = Karma_MemberObject_GetName(oMember);
	local uname = Karma_MemberList_MemberNameToUnitName(name);
	local addit = true;
	if (uname ~= nil) and UnitExists(uname) then
		addit = false;
		if (UnitIsDeadOrGhost(uname) or UnitIsVisible(uname)) then
			addit = true;
		end
	end

	if (addit) then
		memberfield_character[KARMA_DB_L6_RRFFMCC_XP] = memberfield_character[KARMA_DB_L6_RRFFMCC_XP] + accrued;
		memberfield_character[KARMA_DB_L6_RRFFMCC_XPLVL] = memberfield_character[KARMA_DB_L6_RRFFMCC_XPLVL] + accrued_rel;
	end

	Karma_AddZoneToPartyMember(oMember, memberfield_character);

	KarmaObj.ProfileStop("Karma_AddXPToPartyMember");
end

--
-- Add xp to self
--
function	Karma_AddXPToPlayer()
	KarmaObj.ProfileStart("Karma_AddXPToPlayer");
	local	newxp = UnitXP("player");
	local	accrued = 0;

	local	oPlayer = Karma_GetPlayerObject();

	Karma_FieldInitialize(oPlayer, KARMA_DB_L5_RRFFC.XPTOTAL, 0);
	Karma_FieldInitialize(oPlayer, KARMA_DB_L5_RRFFC.XPLAST, UnitXP("player"));
	Karma_FieldInitialize(oPlayer, KARMA_DB_L5_RRFFC.XPMAX, UnitXPMax("player"));

	local	accruedlvl = 0;
	Karma_FieldInitialize(oPlayer, KARMA_DB_L5_RRFFC.XPLVLSUM, 0);

	local	playlast = oPlayer[KARMA_DB_L5_RRFFC.XPLAST];
	local	playmax = oPlayer[KARMA_DB_L5_RRFFC.XPMAX]
	if (newxp < playlast) then
		-- Ding!
		accrued = (playmax - playlast) + newxp;
		accruedlvl = (playmax - playlast) / playmax + newxp / UnitXPMax("player");
	else
		accrued = newxp - playlast;
		accruedlvl = (newxp - playlast) / playmax;
	end

	oPlayer[KARMA_DB_L5_RRFFC.XPTOTAL] = oPlayer[KARMA_DB_L5_RRFFC.XPTOTAL] + accrued;
	oPlayer[KARMA_DB_L5_RRFFC.XPLAST] = UnitXP("player");
	oPlayer[KARMA_DB_L5_RRFFC.XPMAX] = UnitXPMax("player");

	oPlayer[KARMA_DB_L5_RRFFC.XPLVLSUM] = oPlayer[KARMA_DB_L5_RRFFC.XPLVLSUM] + accruedlvl;

	KarmaObj.ProfileStop("Karma_AddXPToPlayer");
end

--
-- Add time to 1
--
function	Karma_AddTimeToPartyMember(oMember, isPvp)
	KarmaObj.ProfileStart("Karma_AddTimeToPartyMember");

	local	newtime = GetTime();
	local	timebetween = 0;
	local	joinedlast = time();

	oMember[KARMA_DB_L5_RRFFM_JOINEDLAST_TIME] = joinedlast;
	oMember[KARMA_DB_L5_RRFFM_JOINEDLAST_CHAR] = UnitName("player");

	KOH.TableInit(oMember, KARMA_DB_L5_RRFFM_CHARACTERS);
	local	memberfield_characterlist = oMember[KARMA_DB_L5_RRFFM_CHARACTERS];

	KOH.TableInit(memberfield_characterlist, UnitName("player"));
	local	memberfield_character = memberfield_characterlist[UnitName("player")];

	Karma_FieldInitialize(memberfield_character, KARMA_DB_L6_RRFFMCC_PLAYED, 0);
	Karma_FieldInitialize(memberfield_character, KARMA_DB_L6_RRFFMCC_PLAYEDLAST, newtime);

	if (memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYEDLAST] == 0) then
		memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYEDLAST] = newtime;
	end

	memberfield_character[KARMA_DB_L6_RRFFMCC_JOINEDLAST] = joinedlast;

	timebetween = newtime - memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYEDLAST];
	if (timebetween  >= 0) then
		-- only add to visibles
		local name = Karma_MemberObject_GetName(oMember);
		local uname = Karma_MemberList_MemberNameToUnitName(name);
		local addit = true;
		if (uname ~= nil) and UnitExists(uname) then
			addit = false;
			if (UnitIsDeadOrGhost(uname) or UnitIsVisible(uname)) then
				addit = true;
			end
		end

		if (addit) then
if (timebetween > 180) then
	KarmaChatDebug("AddTimeToPartyMember: adding " .. floor(timebetween) .. " to " .. name .. " (unit: " .. Karma_NilToString(uname) .. ")");
end
			memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYED] = memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYED] + timebetween;
			if (isPvp) then
				if (memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYEDPVP] == nil) then
					memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYEDPVP] = 0;
				end
				memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYEDPVP] = memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYEDPVP] + timebetween;
			end
--else
--KarmaChatDebug("AddTimeToPartyMember: not adding " .. floor(timebetween) .. " to " .. name .. " (unit: " .. Karma_NilToString(uname) .. ")");
		end
	end

	memberfield_character[KARMA_DB_L6_RRFFMCC_PLAYEDLAST] = newtime;

	Karma_AddZoneToPartyMember(oMember, memberfield_character);

	KarmaObj.ProfileStop("Karma_AddTimeToPartyMember");
end

--
-- Add time to self
--
function	Karma_AddTimeToPlayer(addtoself, isPvp)
	KarmaObj.ProfileStart("Karma_AddTimeToPlayer");

	local	newtime = GetTime();
	local	timebetween = 0;

	local	oPlayer = Karma_GetPlayerObject();

	Karma_FieldInitialize(oPlayer, KARMA_DB_L5_RRFFC.PLAYED, 0);
	Karma_FieldInitialize(oPlayer, KARMA_DB_L5_RRFFC.PLAYEDLAST, newtime);

	timebetween = newtime - oPlayer[KARMA_DB_L5_RRFFC.PLAYEDLAST];
	if (addtoself == 1) then
		oPlayer[KARMA_DB_L5_RRFFC.PLAYED] = oPlayer[KARMA_DB_L5_RRFFC.PLAYED] + timebetween;
		if (isPvp) then
			oPlayer[KARMA_DB_L5_RRFFC.PLAYEDPVP] = oPlayer[KARMA_DB_L5_RRFFC.PLAYEDPVP] + timebetween;
		end
	end
	oPlayer[KARMA_DB_L5_RRFFC.PLAYEDLAST] = newtime;

	KarmaObj.ProfileStop("Karma_AddTimeToPlayer");
end

--
-- Add xp to party
--
function	Karma_AddXPToPartyMembers()
	KarmaObj.ProfileStart("Karma_AddXPToPartyMembers");

	-- check timer for zone list update
	Karma_AddZoneToPartyMember();

	Karma_AddXPToPlayer();
	-- Calculate and add the appropriate amount of xp to each character in the party.
	Karma_VisitAllGroupMembers(Karma_AddXPToPartyMember, nil);

	-- (re-)set timer for zone list update
	Karma_AddZoneToPartyMember();

	KarmaObj.ProfileStop("Karma_AddXPToPartyMembers");
end

--
-- Add time to party
--
function	Karma_AddTimeToPartyMembers(addtoself)
	KarmaObj.ProfileStart("Karma_AddTimeToPartyMembers");

	-- check timer for zone list update
	Karma_AddZoneToPartyMember();

	-- force-add if called from event "party changed"
	if ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) then
		addtoself = 1;
	end
	local	isPvp, RegionName = false, GetZoneText();
	if ((RegionName == KARMA_PVPZONE_WSG) or (RegionName == KARMA_PVPZONE_AB) or (RegionName == KARMA_PVPZONE_AV) or
	    (RegionName == KARMA_PVPZONE_ES) or (RegionName == KARMA_PVPZONE_SA) or (RegionName == KARMA_PVPZONE_WG)) then
		isPvp = true;
	end
	Karma_AddTimeToPlayer(addtoself, isPvp);

	Karma_VisitAllGroupMembers(Karma_AddTimeToPartyMember, isPvp);

	-- (re-)set timer for zone list update
	Karma_AddZoneToPartyMember();

	KarmaObj.ProfileStop("Karma_AddTimeToPartyMembers");
end

function	Karma_RegionLog_Status(arg)
	if (arg) then
		local	oMember = Karma_MemberList_GetObject(arg);
		if (oMember) then
			local	oMemChar = oMember[KARMA_DB_L5_RRFFM_CHARACTERS][KARMA_CURRENTCHAR];
			if (oMemChar) then
				local	oRegL = oMemChar[KARMA_DB_L6_RRFFMCC_REGIONLIST];
				if (oRegL) then
					KarmaChatSecondary("RegionLog_Status: ");

					local	RegionList = CommonRegionListGet();

					local	key, value, subkey, subvalue;
					for key, value in pairs(oRegL) do
						local	iTotal = abs(value[KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL]);

						local	sTotal = "";
						if (iTotal >= 86400) then
							sTotal = math.floor(iTotal / 86400) .. "d ";
							iTotal = iTotal % 86400;
						end
						sTotal = sTotal .. math.floor(iTotal / 3600) .. "h";

						iTotal = math.max(0, iTotal);
						KarmaChatSecondary("RegionLog[" .. key .. "] = { "
							.. value[KARMA_DB_L7_RRFFMCCRR_KEY] .. ", " ..  value[KARMA_DB_L7_RRFFMCCRR_ID] .. " = "
							.. RegionList[value[KARMA_DB_L7_RRFFMCCRR_ID]].Name .. ", "
							.. value[KARMA_DB_L7_RRFFMCCRR_DIFF] .. ", " .. sTotal);

						local	starttime, endtime;
						for subkey, subvalue in pairs(value[KARMA_DB_L7_RRFFMCCRR_PLAYEDDAYS]) do
							starttime = subvalue[KARMA_DB_L8_RRFFMCCRRD_START];
							endtime = subvalue[KARMA_DB_L8_RRFFMCCRRD_END];
							iTotal = iTotal + (endtime - starttime);
							KarmaChatSecondary(" -- Day[" .. subkey .. "] = " .. date("%Y-%m-%d", subvalue[KARMA_DB_L8_RRFFMCCRRD_START]) .. " from " .. date("%H:%M:%S", subvalue[KARMA_DB_L8_RRFFMCCRRD_START]) .. " to " .. date("%H:%M:%S", subvalue[KARMA_DB_L8_RRFFMCCRRD_END]));
						end

						if (value[KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL] <= 0) then
							value[KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL] = iTotal;
						end
					end

					KarmaChatSecondary("***");
				end
			end
		end
	end
end
--
-- ----------------------------------------------------------------------------
--

function	Karma_UpdateCurrentTargetNameColor()
	local	i
	local	sMemberName, membernameobj, oMember

	local	bTargetColored = Karma_GetConfig(KARMA_CONFIG.TARGET_COLORED);
	if (bTargetColored ~= 0) and TargetFrame:IsVisible() then
		local	targetname, targetserver = UnitName("target");
		if (targetserver and (targetserver ~= "")) then
			targetname = targetname .. "@" .. targetserver;
		end
		if (targetname ~= nil) then
			if (UnitFactionGroup("player") == UnitFactionGroup("target") and UnitIsPlayer("target")) then
				local	lMembers = KarmaObj.DB.SF.MemberListGet();
				local	red, green, blue
				if (lMembers[KarmaObj.NameToBucket(targetname)][targetname]~= nil) then
					red, green, blue = Karma_MemberList_GetColors(targetname);
				else
					red = 0.80;
					green = 0.80;
					blue = 0.80;
				end
				TargetName:SetTextColor(1, 1, 1);
				TargetFrameNameBackground:SetVertexColor(red, green, blue);
			end
		end
	end
end

function	Karma_AdjustPartyMemberNameColors()
	local	i
	local	iPartyMembers;
	local	sMemberName, membernameobj, oMember

	iPartyMembers = GetNumPartyMembers();
	if (iPartyMembers == 0) then
		return;
	end

	local	bTargetColored = Karma_GetConfig(KARMA_CONFIG.TARGET_COLORED);
	if (bTargetColored ~= 0) and TargetFrame:IsVisible() then
		local	targetname, targetserver = UnitName("target");
		if (targetserver and (targetserver ~= "")) then
			targetname = targetname .. "@" .. targetserver;
		end
		if (targetname ~= nil) then
			if (UnitFactionGroup("player") == UnitFactionGroup("target") and UnitIsPlayer("target")) then
				local	red, green, blue = Karma_MemberList_GetColors(Karma_MemberObject_GetName(targetname));
				TargetName:SetTextColor(red, green, blue);
			end
		end
	end

	for i = 1, iPartyMembers do
		membernameobject = getglobal("PartyMemberFrame"..i.."Name");
		if (membernameobject ~= nil) then
			sMemberName = membernameobject:GetText();
			if (sMemberName ~= nil) then
				oMember = Karma_MemberList_GetObject(sMemberName);
				if (oMember) then
					local	red, green, blue
					red, green, blue = Karma_MemberList_GetColors(Karma_MemberObject_GetName(oMember));
					membernameobject:SetTextColor(red, green, blue);
				end
			end
		end
	end
end

function	Karma_AddQuestToIndividualPartyMember(oMember, questid, state1, state2)
	KarmaObj.ProfileStart("Karma_AddQuestToIndividualPartyMember");
	local	lQuests;
	lQuests = Karma_MemberObject_GetQuestList(oMember);
	local	key, value;
	local	duplicate = false;
	duplicate = false;

	for key, value in pairs(lQuests) do
		if (questid == value) then
			duplicate = true;
			break;
		end
	end
	if (duplicate == false) then
		lQuests[getn(lQuests)+1] = questid;
	end

	if (KARMA_QExUpdate > 0) and (state1 ~= nil) and (state2 ~= nil) then
		KarmaChatDebug("Karma_AddQuestToIndividualPartyMember: >> QuestObjectives");
		local lQEx = Karma_MemberObject_GetQuestExList(oMember);
		if (lQEx ~= nil) then
			if (type(lQEx) ~= "table") then
				lQEx = {};
			end

			if (lQEx[questid] == nil) or (type(lQEx[questid]) ~= "table") then
				lQEx[questid] = {};
				lQEx[questid].SummedProgress = nil;
				lQEx[questid].ObjectiveTotal = nil;
			end

			local ObjCount = 0;
			local SummedProgress = 0;
			if (state1.objectives ~= nil) then
				for key, value in pairs(state1.objectives) do
					local okey = "O."..key;
					local pro1 = state1.objectives[key].progress;
					local pro2 = state2.objectives[key].progress;
					if (state1.objectives[key].progress + 1 < state2.objectives[key].progress) then
						if (lQEx[questid][okey] == nil) then
							lQEx[questid][okey] = 0;
						end

						lQEx[questid][okey] = lQEx[questid][okey] + pro2 - pro1;
						SummedProgress = SummedProgress + pro2 - pro1;
					end

					ObjCount = ObjCount + 1;
				end
			end

			if (lQEx[questid].ObjectiveTotal == nil) then
				lQEx[questid].ObjectiveTotal = ObjCount * 100;
			end
			if (lQEx[questid].SummedProgress == nil) then
				lQEx[questid].SummedProgress = 0;
			end

			lQEx[questid].SummedProgress = lQEx[questid].SummedProgress + SummedProgress;
		end
		KarmaChatDebug("Karma_AddQuestToIndividualPartyMember: << QuestObjectives");
	end

	KarmaObj.ProfileStop("Karma_AddQuestToIndividualPartyMember");
end

function	Karma_AddQuestToPartyMembers(questname, state1, state2, extid, daily)
	KarmaObj.ProfileStart("Karma_AddQuestToPartyMembers");

	-- if config option is set, don't add dailies
	if (daily == 1) and (KARMA_CONFIG.QUESTSIGNOREDAILIES == 1) then
KarmaChatDebug("Daily quest, config option says no adding, not adding.");
		KarmaObj.ProfileStop("Karma_AddQuestToPartyMembers");
		return;
	end

	local	questid = Karma_QuestList_AddQuest(questname, extid);
	-- DEBUG:
	KarmaChatDebug("Karma: " .. questname .. " -> QID = " .. questid .. ", ExtID = " .. Karma_NilToString(extid));
	-- :DEBUG
	if (questid < 0) then
		local	questposid = - questid;
		local	CurrentZoneID = CommonRegionZoneAddCurrent();
		local	globalZoneList = CommonZoneListGet();

		local	globalQuestInfoList = CommonQuestInfoListGet();
		if (globalQuestInfoList[questposid] == nil) then
			globalQuestInfoList[questposid] = {}
		end
		if globalZoneList[CurrentZoneID] then
			if globalZoneList[CurrentZoneID].RegionID then
				if (globalQuestInfoList[questposid].RegionID == nil) then
					globalQuestInfoList[questposid].RegionID = globalZoneList[CurrentZoneID].RegionID;
				elseif (globalQuestInfoList[questposid].RegionID ~= 0) and
					(globalQuestInfoList[questposid].RegionID ~= globalZoneList[CurrentZoneID].RegionID) then
					globalQuestInfoList[questposid].RegionID = 0;
				end

				-- DEBUG:
				KarmaChatDebug("Karma: " .. questname .. " -> RID = " .. globalZoneList[CurrentZoneID].RegionID);
				-- :DEBUG
			end
		end
	end

	Karma_VisitAllGroupMembers(Karma_AddQuestToIndividualPartyMember, questid, state1, state2);
	KarmaObj.ProfileStop("Karma_AddQuestToPartyMembers");
end

-- For each group member, either retrieve, or create a member object, and then pass it
-- to the specified function.
function	Karma_VisitAllGroupMembers(func, user, extra1, extra2)
	KarmaObj.ProfileStart("Karma_VisitAllGroupMembers");
	-- Now update the list of players that this character is grouped with.
	local	oMember;
	for sMemberName, oMember in pairs(KARMA_PartyNames) do
		if (oMember) then
			func(oMember, user, extra1, extra2);
		end
	end

	KarmaObj.ProfileStop("Karma_VisitAllGroupMembers");
end

---
----
---
function	Karma_CurrentMember_PostToChat(toplayer)
	KarmaObj.ProfileStart("Karma_CurrentMember_PostToChat");
	if (toplayer == "") then
		toplayer = nil;
	end

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember) and (DEFAULT_CHAT_FRAME) then
		local	ChatType, DefaultChatEditBox;
		local	DoIt = 0;
		if (toplayer ~= nil) then
			DoIt = 1;
		else
			DefaultChatEditBox = DEFAULT_CHAT_FRAME.editBox;
			ChatType = DefaultChatEditBox:GetAttribute("chatType");
			if (ChatType ~= "WHISPER") and (ChatType ~= "CHANNEL") then
				-- todo: localize
				KarmaChatDefault("Not supported for \"" .. ChatType .. "\", must be talking to a specific target. (Only channels and whispers are allowed... either open the chatline by pressing 'r' (reply, i.e. whisper) or type return and \"/w <player> \" or \"/# \", then click.)");
			elseif (#Karma_MessageQueue > 0) then
				-- todo: localize
				KarmaChatDefault("Chat queue must be empty for this. Currently there are " .. #Karma_MessageQueue .. " lines queued.");
			else
				DoIt = 1;
			end
		end

		if (DoIt == 1) then
			-- implicit lock to queue
			KARMA_LastMessageTime = GetTime() + 30;

			local	Infos = {};
			local	i = 1;
			Infos[i] = "";
			local	iLevel = Karma_MemberObject_GetLevel(oMember);
			local	sRace = Karma_MemberObject_GetRace(oMember);
			local	sClass = Karma_MemberObject_GetClass(oMember);
			if (iLevel) and (iLevel > 0) then
				Infos[i] = Infos[i] .. " " .. iLevel;
			end
			if (sRace) and (sRace ~= "") then
				Infos[i] = Infos[i] .. " " .. sRace;
			end
			if (sClass) and (sClass ~= "") then
				Infos[i] = Infos[i] .. " " .. sClass;
			end
			if (Infos[i] ~= "") then
				Infos[i] = "Karma infos on >" .. KARMA_CURRENTMEMBER .. "< " .. Infos[i];
				i = i + 1;
			end

			local	sNotesPublic = Karma_MemberObject_GetPublicNotes(oMember);
			if (sNotesPublic) and (sNotesPublic ~= "") then
				Infos[i] = KARMA_WINEL_NOTESPUBLIC .. KARMA_WINEL_FRAG_COLONSPACE .. sNotesPublic;
				i = i + 1;
			end

			local	sKarma = Karma_MemberObject_GetKarmaWithModifiers(oMember);
			if (sKarma) and (sKarma ~= "") then
				Infos[i] = KARMA_ITSELF .. KARMA_WINEL_FRAG_COLONSPACE .. sKarma;
				local	sNotes = Karma_MemberObject_GetNotes(oMember);
				if (sNotes) and (sNotes ~= "") then
					Infos[i] = Infos[i] .. " - " .. KARMA_WINEL_NOTESSCROLLFRAMETITLE .. KARMA_WINEL_FRAG_SPACE .. strlen(sNotes) .. " chars";
				else
					Infos[i] = Infos[i] .. " - " .. KARMA_MSG_WHOCATCHED_NONOTES .. KARMA_CURRENTMEMBER;
				end
				i = i + 1;
			end

			local	sSkill = Karma_MemberObject_GetSkillText(oMember);
			if (sSkill) and (sSkill ~= "") then
				Infos[i] = KARMA_MSG_TIP_SKILL .. KARMA_WINEL_FRAG_COLONSPACE .. sSkill;
				i = i + 1;
			end

			local	bHasEntries, EntriesL, iTotal = Karma_RegionList_GetLines(oMember);
			if (bHasEntries == 1) then
				local	dur, key, value = 0;
				for key, value in pairs(EntriesL) do
				end

				Infos[i] = "Tracked dungeons: " .. #EntriesL .. " visits total over " .. KOH.Duration2String(iTotal);
				i = i + 1;
			end

			Infos[i] = "--## the end ##--";
			i = i + 1;

			local	chattarget;
			if (toplayer ~= nil) then
				chattarget = toplayer;
				ChatType = "WHISPER";
				KarmaChatDefault("Whispering Karma's infos about >" .. KARMA_CURRENTMEMBER .. "< to " .. chattarget .. "...");
			else
				if (ChatType == "WHISPER") then
					chattarget = DefaultChatEditBox:GetAttribute("tellTarget");
					KarmaChatDefault("Whispering Karma's infos about >" .. KARMA_CURRENTMEMBER .. "< to " .. chattarget .. "...");
				end
				if (ChatType == "CHANNEL") then
					chattarget = DefaultChatEditBox:GetAttribute("channelTarget");
					KarmaChatDefault("Sending Karma's infos about >" .. KARMA_CURRENTMEMBER .. "< into channel " .. chattarget .. "...");
				end
			end

KarmaChatDebug("ChatType: " .. Karma_NilToString(ChatType) .. ", chattarget: " .. Karma_NilToString(chattarget) .. " (toplayer: " .. Karma_NilToString(toplayer) .. ")");

			if (ChatType and chattarget) then
				local	k, elem;
				for k = 1, i - 1 do
					elem = {};
					elem.text = Infos[k];
					elem.chattype = ChatType;
					elem.target = chattarget;
					Karma_MessageQueue[1 + #Karma_MessageQueue] = elem;
				end
			end

			KARMA_LastMessageTime = GetTime() + 0.5;
		end
	end

	KarmaObj.ProfileStop("Karma_CurrentMember_PostToChat");
end

-----------------------------------------
-- COLOR FUNCTIONS
-----------------------------------------

function	ColourToString(iAlpha, iRed, iGreen, iBlue)
--[[
	if (iAlpha == nil) or (iRed == nil) or (iGreen == nil) or (iBlue == nil) then
		KarmaChatDebug("ColourToString: invalid input from -- " .. debugstack());
		return "FFFF4040";
	end
]]--
	return string.format("%.2X%.2X%.2X%.2X", iAlpha*255, iRed*255, iGreen*255, iBlue*255)
end

function	Karma_MemberList_GetColors(sMemberName)
	if (Karma_GetConfig(KARMA_CONFIG.COLORFUNCTION) == nil) then
		Karma_SetConfig(KARMA_CONFIG.COLORFUNCTION, KARMA_CONFIG.COLORFUNCTION_TYPE_KARMA);
	end
	local	colorfunction	= Karma_GetConfig(KARMA_CONFIG.COLORFUNCTION);
	if (colorfunction	== KARMA_CONFIG.COLORFUNCTION_TYPE_XP) then
		return Karma_GetColors_XP(sMemberName);
	elseif (colorfunction	== KARMA_CONFIG.COLORFUNCTION_TYPE_PLAYED) then
		return Karma_GetColors_Played(sMemberName);
	elseif (colorfunction	== KARMA_CONFIG.COLORFUNCTION_TYPE_KARMA) then
		return Karma_GetColors_Karma(sMemberName);
	elseif (colorfunction	== KARMA_CONFIG.COLORFUNCTION_TYPE_CLASS) then
		return Karma_GetColors_Class(sMemberName);
	elseif (colorfunction	== KARMA_CONFIG.COLORFUNCTION_TYPE_XPALL) then
		return Karma_GetColors_XP(sMemberName, true);
	elseif (colorfunction	== KARMA_CONFIG.COLORFUNCTION_TYPE_PLAYEDALL) then
		return Karma_GetColors_Played(sMemberName, true);
	elseif (colorfunction	== KARMA_CONFIG.COLORFUNCTION_TYPE_XPLVL) then
		return Karma_GetColors_XPLVL(sMemberName);
	elseif (colorfunction	== KARMA_CONFIG.COLORFUNCTION_TYPE_XPLVLALL) then
		return Karma_GetColors_XPLVL(sMemberName, true);
	end
	return 1, 1, 1;
end

function	Karma_Value2Color(sContext, iValue)
	KarmaObj.ProfileStart("Karma_Value2Color");

	-- new: more color change between 40 and 60, where most players end up
		-- r, g: 1 Karma = 0.01 change, b: 1 Karma = 0.02 change
		-- 40-60: r, g: 1 Karma = 0.02
		-- => r(40->60) = 0.7 -> 0.3, g(40->60) = 0.3 -> 0.7
		-- => r(0 ->40) = 1.0 -> 0.7, g(0 ->40) = 0.0 -> 0.3
		-- => r(60->++) = 0.3 -> 0.0, g(60->++) = 0.7 -> 1.0
	local	red;
	local	green;
	local	blue  = 1.0 -  0.02 * math.abs(iValue - 50);

	if (iValue >= 60) then
		red   = 0.3 - (iValue - 60) * 0.0075;
		green = 0.7 + (iValue - 60) * 0.0075;
	elseif (iValue >= 40) then
		red   = 0.7 - (iValue - 40) * 0.02;
		green = 0.3 + (iValue - 40) * 0.02;
	else
		red   = 1.0 - (iValue     ) * 0.0075;
		green =       (iValue     ) * 0.0075;
	end

	-- even newer: let user define the three border colors and interpolate
	if (Karma_GetConfig(KARMA_CONFIG.COLORSPACE_ENABLE)) then
		-- normalize
		iValue = math.min(100, math.max(0, iValue));

		-- again, we want 40-60 to be "stronger" than other values
		local	oFrom, oTo, dFactor;
		if (iValue < 50) then
			oFrom = KarmaObj.Colorspace.ValueGet(sContext, "Min");
			oTo   = KarmaObj.Colorspace.ValueGet(sContext, "Avg");
			--  0 .. 50 => 0 .. 1?
			--  0 .. 40 =>   0 .. 2/3
			-- 40 .. 50 => 2/3 ..   1
			if (iValue < 40) then
				dFactor = iValue / 60;
			else
				dFactor = 2/3 + (iValue - 40) / 30;
			end
		else
			oFrom = KarmaObj.Colorspace.ValueGet(sContext, "Avg");
			oTo   = KarmaObj.Colorspace.ValueGet(sContext, "Max");
			-- 50 .. 100 =>   0 .. 1?
			-- 50 ..  60 =>   0 .. 1/3
			-- 60 .. 100 => 1/3 ..   1
			if (iValue < 60) then
				dFactor = (iValue - 50) / 30;
			else
				dFactor = 1/3 + (iValue - 60) / 60;
			end
		end

		red   = oFrom.r + (oTo.r - oFrom.r) * dFactor;
		green = oFrom.g + (oTo.g - oFrom.g) * dFactor;
		blue  = oFrom.b + (oTo.b - oFrom.b) * dFactor;
	end

	KarmaObj.ProfileStop("Karma_Value2Color");

	return red, green, blue;
end

function	Karma_GetColors_Played(sMemberName, bTotal)
	KarmaObj.ProfileStart("Karma_GetColors_Time");
	local	oMember = Karma_MemberList_GetObject(sMemberName);
	if (oMember == nil) then
		return 0.8, 0.8, 0.8;
	end

	local	membertime, low, high, average;
	if (bTotal) then
		membertime = Karma_MemberObject_GetTotalTimePlayedSummedUp(oMember);
		low, high, average = Karma_MemberList_GetHighLow_TotalFieldSummedUp(KARMA_DB_L6_RRFFMCC_PLAYED, oMember);
	else
		membertime = Karma_MemberObject_GetTimePlayed(oMember);
		low, high, average = Karma_MemberList_GetFieldHighLow(KARMA_DB_L6_RRFFMCC_PLAYED, oMember);
	end

	if (membertime == nil) then
		membertime = low;
	end
	local	percentage = ((membertime - low)/(0.01 + (high - low))) * 100;

	percentstep = percentage/5;
	local	green = percentstep*0.08;
	local	blue = (1.0-(percentstep*0.09));
	if (blue < 0) then
		blue = 0;
	end
	if (green > 1.0) then
		green = 1.0
	end

	local	red = 0.0;

	if (Karma_GetConfig(KARMA_CONFIG.COLORSPACE_ENABLE)) then
		red, green, blue = Karma_Value2Color("Time", percentage);
	end

	--	KarmaChatDebug("red == "..red.." green == "..green.." blue == "..blue);
	KarmaObj.ProfileStop("Karma_GetColors_Time");

	return red, green, blue;
end

function	Karma_GetColors_XP(sMemberName, bTotal)
	KarmaObj.ProfileStart("Karma_GetColors_XP");
	local	oMember = Karma_MemberList_GetObject(sMemberName);
	if (oMember == nil) then
		return 1, 1, 1;
	end

	local	memberxp, low, high, average;
	if (bTotal) then
		memberxp = Karma_MemberObject_GetTotalXPSummedUp(oMember);
		low, high, average = Karma_MemberList_GetHighLow_TotalFieldSummedUp(KARMA_DB_L6_RRFFMCC_XP, oMember);
	else
		memberxp = Karma_MemberObject_GetXP(oMember);
		low, high, average = Karma_MemberList_GetFieldHighLow(KARMA_DB_L6_RRFFMCC_XP, oMember);
	end
	if (memberxp == nil) then
		memberxp = low;
	end

	local	percentage = ((memberxp - low)/(0.01 + (high - low))) * 100;

	percentstep = percentage/5;
	local	green = percentstep*0.08;
	local	blue = (1.0-(percentstep*0.09));
	if (blue < 0) then
		blue = 0;
	end
	if (green > 1.0) then
		green = 1.0
	end
	local	red = 0.0;

	if (Karma_GetConfig(KARMA_CONFIG.COLORSPACE_ENABLE)) then
		red, green, blue = Karma_Value2Color("XP", percentage);
	end

	KarmaObj.ProfileStop("Karma_GetColors_XP");

	return red, green, blue;
end

function	Karma_GetColors_XPLVL(sMemberName, bTotal)
	KarmaObj.ProfileStart("Karma_GetColors_XP");
	local	oMember = Karma_MemberList_GetObject(sMemberName);
	if (oMember == nil) then
		return 1, 1, 1;
	end

	local	memberxp, low, high, average;
	if (bTotal) then
		memberxp = Karma_MemberObject_GetTotalXPLVLSummedUp(oMember);
		low, high, average = Karma_MemberList_GetHighLow_TotalFieldSummedUp(KARMA_DB_L6_RRFFMCC_XPLVL, oMember);
	else
		memberxp = Karma_MemberObject_GetXPLVL(oMember);
		low, high, average = Karma_MemberList_GetFieldHighLow(KARMA_DB_L6_RRFFMCC_XPLVL, oMember);
	end
	if (memberxp == nil) then
		memberxp = low;
	end

	local	percentage = ((memberxp - low)/(0.01 + (high - low))) * 100;

	percentstep = percentage/5;
	local	green = percentstep*0.08;
	local	blue = (1.0-(percentstep*0.09));
	if (blue < 0) then
		blue = 0;
	end
	if (green > 1.0) then
		green = 1.0
	end
	local	red = 0.0;

	if (Karma_GetConfig(KARMA_CONFIG.COLORSPACE_ENABLE)) then
		red, green, blue = Karma_Value2Color("XP", percentage);
	end

	KarmaObj.ProfileStop("Karma_GetColors_XP");

	return red, green, blue;
end

function	Karma_Karma2Color(iKarma)
	return Karma_Value2Color("Karma", iKarma);
end

function	Karma_GetColors_Karma(sMemberName)
	KarmaObj.ProfileStart("Karma_GetColors_Karma");
		-- Calculate the color of the karma bar.
	-- The better the person the greener the karma.
	-- The worse the person the redder the karma.
	local	oMember = Karma_MemberList_GetObject(sMemberName);
	if (oMember == nil) then
		return 1, 1, 1;
	end

	local	iKarma = Karma_MemberObject_GetKarmaModified(oMember);
	iKarma = math.min(iKarma, 100);

	local	red, green, blue = Karma_Karma2Color(iKarma);

	KarmaObj.ProfileStop("Karma_GetColors_Karma");
	return red, green, blue;
end

function	Karma_ClassMToColor(sClassWOGender)
	local	red = 0.8;
	local	green = 0.8;
	local	blue = 0.8;

	-- RAID_CLASS_COLORS: defined in Fonts.xml...
	local	Class = sClassWOGender;
	if (Class) and (Class ~= "") then
		local	Colors = nil;
		if (Class == KARMA_CLASS_DRUID_M) then
			Colors = RAID_CLASS_COLORS["DRUID"];
		end
		if (Class == KARMA_CLASS_HUNTER_M) then
			Colors = RAID_CLASS_COLORS["HUNTER"];
		end
		if (Class == KARMA_CLASS_MAGE_M) then
			Colors = RAID_CLASS_COLORS["MAGE"];
		end
		if (Class == KARMA_CLASS_PALADIN_M) then
			Colors = RAID_CLASS_COLORS["PALADIN"];
		end
		if (Class == KARMA_CLASS_PRIEST_M) then
			Colors = RAID_CLASS_COLORS["PRIEST"];
		end
		if (Class == KARMA_CLASS_ROGUE_M) then
			Colors = RAID_CLASS_COLORS["ROGUE"];
		end
		if (Class == KARMA_CLASS_SHAMAN_M) then
			Colors = RAID_CLASS_COLORS["SHAMAN"];
		end
		if (Class == KARMA_CLASS_WARRIOR_M) then
			Colors = RAID_CLASS_COLORS["WARRIOR"];
		end
		if (Class == KARMA_CLASS_WARLOCK_M) then
			Colors = RAID_CLASS_COLORS["WARLOCK"];
		end
		if (Class == KARMA_CLASS_DEATHKNIGHT_M) then
			Colors = RAID_CLASS_COLORS["DEATHKNIGHT"];
		end
	
		if (Colors ~= nil) then
			red = Colors.r;
			green = Colors.g;
			blue = Colors.b;
		end
	end

	return red, green, blue;
end

function	Karma_GetColors_Class(sMemberName)
	KarmaObj.ProfileStart("Karma_GetColors_Class");
		-- Calculate the color of the karma bar.
	-- The better the person the greener the karma.
	-- The worse the person the redder the karma.
	local	oMember = Karma_MemberList_GetObject(sMemberName);
	if (oMember == nil) then
		KarmaObj.ProfileStop("Karma_GetColors_Class");
		return 0.8, 0.8, 0.8;
	end

	if (oMember.Meta) then
		KarmaObj.ProfileStop("Karma_GetColors_Class");
		return 0.0, 1.0, 0.0;
	end

	local	sClassWOGender = Karma_MemberObject_GetClassWOGender(oMember);

	KarmaObj.ProfileStop("Karma_GetColors_Class");
	return Karma_ClassMToColor(sClassWOGender);
end

------------------------------------------------------
--		SORTING FUNCTIONS
------------------------------------------------------

-- whoohoo, this one is *actually* used!
function	Karma_MemberSort_CompareName(memname1, memname2)
	if (memname1 == nil) or (memname2 == nil) then
		return false;
	end
	if (memname1 < memname2) then
		return true;
	end
	return false;
end

--
--	This function does a sort based on some numeric field in the
--	oMember. Because we are now using version 4 of the database
--	GetMemberObject is now on par with AlphaBucketSort routine.
--	This sorts into numbered buckets, which always come in order.
--

--	The bucket borders should actually be different for various
--	sort kinds: by time, by xp (absolute), by xp (relative)

local	LARGE_NUMERIC_SORTING_BUCKETS = {
	 [1] = { max =       0, records = {}},
	 [2] = { max =      50, records = {}},
	 [3] = { max =     150, records = {}},
	 [4] = { max =     450, records = {}},
	 [5] = { max =    1350, records = {}},
	 [6] = { max =    4050, records = {}},
	 [7] = { max =   10000, records = {}},
	 [8] = { max =   20000, records = {}},
	 [9] = { max =   40000, records = {}},
	[10] = { max =   80000, records = {}},
	[11] = { max =  160000, records = {}},
	[12] = { max =  320000, records = {}},
	[13] = { max =  640000, records = {}},
	[14] = { max = 1280000, records = {}},
	[15] = { max = 3000000, records = {}},
	[16] = { max = 9000000, records = {}},
	[17] = { max =      -1, records = {}}
};

--	Changed to logarithmic.
local	SMALL_NUMERIC_SORTING_BUCKETS;

function	Karma_SortNameValuePairsByValue(table1, cmpfunc)
	-- The following method is Lua's built in sort library sort(table1)
	-- is it? looks just like good old bubble sort...
	local	lo, hi, min, j, iCount
	lo = 1
	hi = getn(table1)
	for iCount = lo, hi do
		-- find smallest 'bubble'...
		min = iCount
		for j = iCount, hi do
			if table1[j].sortvalue < table1[min].sortvalue then
				min = j;
			end
		end

		-- ...and let it 'sink' to lowest spot (or: all larger bubbles 'rise' to higher spots)
		local	temp = table1[min]
		table1[min] = table1[iCount]
		table1[iCount] = temp
	end

	return table1
end

function	Karma_SortNameValuePairsByName(table1, cmpfunc)
	-- The following method is Lua's built in sort library sort(table1)
	-- is it? looks just like good old bubble sort...
	local	lo, hi, min, j, iCount;
	lo = 1
	hi = getn(table1)
	for iCount = lo, hi do
		-- find smallest 'bubble'...
		min = iCount
		for j = iCount, hi do
			-- REVERSE (to compensate for reversal in main loop)
			if table1[j].name > table1[min].name then
				min = j;
			end
		end

		-- ...and let it 'sink' to lowest spot (or: all larger bubbles 'rise' to higher spots)
		local	temp = table1[min]
		table1[min] = table1[iCount]
		table1[iCount] = temp
	end

	return table1;
end

function	Karma_MemberFieldNumericSort(table1, sortfunc)
	local i=0;
	local key,value;
	local result={};
	local buckets={};
	local tempbuckets={};
	local temp = {};
	local index,name;

	local sortfunction;
	if (sortfunc) then
		sortfunction = sortfunc;
	else
		sortfunction = Karma_GetConfig(KARMA_CONFIG.SORTFUNCTION);
	end;

	if (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_NAME) then
		return table1;
	end;

	if (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_KARMA) then
		for i = 1, 100 do
			buckets[i] = {};
		end
	elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_CLASS) then
		-- make buckets on-the-fly ~
	elseif ((sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_TOP) or
		(sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_BOTTOM)) then
		-- make buckets on-the-fly ~
	elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_TALENT) then
		-- tank, hps, dps, unset
		for i = 1, 4 do
			buckets[i] = {};
		end
	else
		local	BucketsStatic = SMALL_NUMERIC_SORTING_BUCKETS;
		if (BucketsStatic == nil) then
			SMALL_NUMERIC_SORTING_BUCKETS = {};
			BucketsStatic = SMALL_NUMERIC_SORTING_BUCKETS;
			for i = 1, 49 do
				BucketsStatic[i] = { max = (i - 1) / 2 };
			end
			BucketsStatic[50] = { max = - 1 };
		end

		-- Okay we need to create buckets for the other sort values.
		for i = 1, #BucketsStatic do
			buckets[i] = BucketsStatic[i];
			buckets[i].records = {};
			tempbuckets[i] = {};
		end
	end

	Karma_WhoAmIInit();

	local	iNow, iClassID = time();
	for key, value in pairs(table1) do
		if (value ~=nil  and value~="") then
			local memberobj = Karma_MemberList_GetObject(value);
			local bucketname = 0;
			if (memberobj and (memberobj.Meta == nil)) then
				if     (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_KARMA) then
					bucketname = Karma_MemberObject_GetKarmaModified(memberobj);
					if (bucketname) and (bucketname > 100) then
						bucketname = 100;
					end
				elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_CLASS) then
					bucketname = nil;
					local	iClassID = memberobj[KARMA_DB_L5_RRFFM.CLASS_ID];
					if (iClassID) then
						if (iClassID < 0) then
							iClassID = - iClassID;
						end
						bucketname = Karma_IDToClass(iClassID);
					end

					if (bucketname == nil) or (bucketname == "") then
						bucketname = memberobj[KARMA_DB_L5_RRFFM.CLASS];
					end

	 				if (bucketname == nil) or (bucketname == "") then
	 					bucketname = "???";
	 				end
				elseif ((sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_TOP) or
					(sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_BOTTOM)) then
					bucketname = memberobj[KARMA_DB_L5_RRFFM.GUILD];
					if (bucketname == nil) or (bucketname == "") then
						bucketname = KarmaModuleLocal.Guildless;
					end
				elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_XP) then
					if (memberobj[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI]) then
						bucketname = memberobj[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI][KARMA_DB_L6_RRFFMCC_XP];
						if (bucketname == nil) then
							bucketname = 0;
						end
					end
					if (bucketname > 0) then
						bucketname = math.log(bucketname) * 2;
					end
				elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_PLAYED) then
					if (memberobj[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI]) then
						bucketname = memberobj[KARMA_DB_L5_RRFFM_CHARACTERS][WhoAmI][KARMA_DB_L6_RRFFMCC_PLAYED];
						if (bucketname == nil) then
							bucketname = 0;
						end
					end
					if (bucketname > 0) then
						bucketname = math.log(bucketname) * 2;
					end
				elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_XPALL) then
					local	sChar, oChar;
					for sChar, oChar in pairs(memberobj[KARMA_DB_L5_RRFFM_CHARACTERS]) do
						if (oChar[KARMA_DB_L6_RRFFMCC_XP]) then
							bucketname = bucketname + oChar[KARMA_DB_L6_RRFFMCC_XP];
						end
					end
					if (bucketname > 0) then
						bucketname = math.log(bucketname) * 2;
					end
				elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_PLAYEDALL) then
					local	sChar, oChar;
					for sChar, oChar in pairs(memberobj[KARMA_DB_L5_RRFFM_CHARACTERS]) do
						if (oChar[KARMA_DB_L6_RRFFMCC_PLAYED]) then
							bucketname = bucketname + oChar[KARMA_DB_L6_RRFFMCC_PLAYED];
						end
					end
					if (bucketname > 0) then
						bucketname = math.log(bucketname) * 2;
					end
				elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_JOINED) then
					bucketname = memberobj[KARMA_DB_L5_RRFFM_JOINEDLAST_TIME];
					if (bucketname == nil) then
						bucketname = 0;
					elseif (bucketname > 0) then
						-- more than two years? 94672800 seconds (94672800 = 3 years)
						if (iNow - bucketname > 63072000) then
							bucketname = math.log10(bucketname) - 7;
							if (bucketname < 0.75) then
								bucketname = 0.75;
							end
						else
							bucketname = 24 - (iNow - bucketname) / 86400 / 40;
						end
					end
				elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_TALENT) then
					bucketname = memberobj[KARMA_DB_L5_RRFFM_TALENT];
					if (bucketname == nil) then
						local classid = memberobj[KARMA_DB_L5_RRFFM.CLASS_ID];
						bucketname = KarmaObj.Talents.ClassIDToTalentsDefault(classid);
					end
				end

	 			if (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_CLASS) then
	 				if (buckets[bucketname] == nil) then
	 					buckets[bucketname] = {};
	 				end

					buckets[bucketname][getn(buckets[bucketname]) + 1] = value;
				elseif ((sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_TOP) or
					(sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_BOTTOM)) then
	 				if (buckets[bucketname] == nil) then
	 					buckets[bucketname] = {};
	 				end

					buckets[bucketname][getn(buckets[bucketname]) + 1] = value;
	 			elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_TALENT) then
	 				-- hps, tank, dps:
	 				-- 1 = hps
-- KarmaChatDebug("value = " .. value .. ", bucketname = " .. Karma_NilToString(bucketname));
	 				if (bucketname % 2 ~= 0) then
	 					buckets[4][getn(buckets[4]) + 1] = value;
	 				-- 2 = tank
	 				elseif (bucketname % 4 ~= 0) then
	 					buckets[3][getn(buckets[3]) + 1] = value;
	 				elseif (bucketname % 7 ~= 0) then
	 					buckets[2][getn(buckets[2]) + 1] = value;
	 				else
	 					buckets[1][getn(buckets[1]) + 1] = value;
	 				end
	 			elseif (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_KARMA) then
	 				if (bucketname == nil) then
	 					bucketname = 50;
						KarmaChatDebug("Karma_MemberFieldNumericSort "..value.." :: "..sortfunction.." has no karma?!");
	 				end
					if (buckets[bucketname] == nil) then
						buckets[bucketname] = {};
					end

					buckets[bucketname][getn(buckets[bucketname]) + 1] = value;
				else
					for i= 1, getn(buckets) do
						if (bucketname <= buckets[i].max) then
							buckets[i].records[getn(buckets[i].records) + 1] = { name = value, sortvalue = bucketname };
							break;
						elseif (buckets[i].max == -1) then
							buckets[i].records[getn(buckets[i].records) + 1] = { name = value, sortvalue = bucketname };
						end
					end
				end
			end
		end
	end

	if (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_KARMA) or
	   (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_CLASS) or
	   (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_TOP) or
	   (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_BOTTOM) or
	   (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_TALENT) then
		tempbuckets = buckets;
	else
		for i = 1, getn(buckets) do
			if (i > 1) then
				Karma_SortNameValuePairsByValue(buckets[i].records);
			else
				-- special case the first bucket is for those you've never gotten any time/exp with.
				Karma_SortNameValuePairsByName(buckets[i].records);
			end

			local x = 0;
			for x = getn(buckets[i].records), 1, -1 do
				tempbuckets[i][getn(tempbuckets[i]) + 1] = buckets[i].records[x].name;
			end
		end

		local	iTotals = 0;
		for i = 1, #buckets do
			iTotals = iTotals + #buckets[i].records;
		end
		local	sUsage = "numeric distribution sort: total = " .. iTotals .. ", bucket usage = ";
		iTotals = iTotals / #buckets;
		for i = 1, #buckets do
			sUsage = sUsage .. format("%d: %.2f, ", i, #buckets[i].records / iTotals);
		end
		KarmaChatDebug(sUsage);
	end

	-- this does a complete reversal of all the results.
	if (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_CLASS) then
		local	counter = 1;
		local	class, bucket;
		for class, bucket in pairs(tempbuckets) do
			local name = "";
			for index, name in pairs(bucket) do
				result[counter] = name;
				counter = counter + 1;
			end
		end
	elseif ((sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_TOP) or
		(sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_BOTTOM)) then
		local	counter = 1;
		local	oGuilds = {};
		local	guild, bucket;
		for guild, bucket in pairs(tempbuckets) do
			if (guild ~= KarmaModuleLocal.Guildless) then
				tinsert(oGuilds, guild);
			end
		end

		table.sort(oGuilds);

		do
			local	guildobj = Karma_MemberList_GetObject("<" .. KarmaModuleLocal.Guildless .. ">");
			if (guildobj == nil) then
				local	sCmd = "addguild " .. KarmaModuleLocal.Guildless;
				Karma_SlashCommandHandler(sCmd, true);
				guildobj = Karma_MemberList_GetObject("<" .. KarmaModuleLocal.Guildless .. ">");
			end
			if (not bFiltered and (guildobj ~= nil)) then
				local	bucket = tempbuckets[KarmaModuleLocal.Guildless];
				if (bucket and not KOH.TableIsEmpty(bucket)) then
					guildobj[KARMA_DB_L5_RRFFM.LEVEL] = #bucket;
				end
			end
		end

		if (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_TOP) then
			local	bucket = tempbuckets[KarmaModuleLocal.Guildless];
			if (bucket and not KOH.TableIsEmpty(bucket)) then
				result[counter] = "<" .. KarmaModuleLocal.Guildless .. ">";
				counter = counter + 1;
				for index, name in pairs(bucket) do
					result[counter] = name;
					counter = counter + 1;
				end
			end
		end

		local	bFiltered = (KARMA_Filter.Total ~= nil) and (strlen(KARMA_Filter.Total) > 0);
		for index, guild in pairs(oGuilds) do
			local	bucket = tempbuckets[guild];
			if (bucket and not KOH.TableIsEmpty(bucket)) then
				result[counter] = "<" .. guild .. ">";
				counter = counter + 1;
				local	conterfrom = counter;
				for index, name in pairs(bucket) do
					result[counter] = name;
					counter = counter + 1;
				end
				local	guildobj = Karma_MemberList_GetObject("<" .. guild .. ">");
				if (guildobj == nil) then
					local	sCmd = "addguild " .. guild;
					Karma_SlashCommandHandler(sCmd, true);
					guildobj = Karma_MemberList_GetObject("<" .. guild .. ">");
				end
				if (not bFiltered and (guildobj ~= nil)) then
					guildobj[KARMA_DB_L5_RRFFM.LEVEL] = counter - conterfrom;
				end
			end
		end

		if (sortfunction == KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_BOTTOM) then
			local	bucket = tempbuckets[KarmaModuleLocal.Guildless];
			if (bucket and not KOH.TableIsEmpty(bucket)) then
				result[counter] = "<" .. KarmaModuleLocal.Guildless .. ">";
				counter = counter + 1;
				for index, name in pairs(bucket) do
					result[counter] = name;
					counter = counter + 1;
				end
			end
		end
	else
		local	counter = 1;
		for i = 1, getn(tempbuckets) do
			local	name;
			for index, name in pairs(tempbuckets[(getn(tempbuckets) + 1) - i]) do
				result[counter] = name;
				counter = counter + 1;
			end
		end
	end

	return result;
end

-----------------------------------------
--	GUI FUNCTIONS
-----------------------------------------

function Karma_UpdateMember(Membername, force)
	-- update info, if online
	if (Membername ~= nil) then
		local fakeargs = {}
		fakeargs[2] = Membername;
		Karma_SlashUpdate(fakeargs, 2, force);
	end
end

function Karma_UpdateCurrentMember()
	-- allows to Update random member, if none selected in Karma window
	local fakeargs = {}
	fakeargs[2] = KARMA_CURRENTMEMBER;
	Karma_SlashUpdate(fakeargs);
end

function	Karma_RemoveMember_Really(Membername)
	if (arg1 ~= nil) then
		local fakeargs = {}
		fakeargs[2] = Membername;
		Karma_SlashRem(fakeargs);
	end
end

function	Karma_RemoveMember(Membername)
	-- update info, if online
	if (Membername ~= nil) and (Membername ~= "") then
		local DoIt = true;
		local	i, iMax, sBase;
		if (GetNumRaidMembers() > 0) then
			iMax = GetNumRaidMembers();
			sBase = "raid";
		else
			iMax = GetNumPartyMembers();
			sBase = "party";
		end
		for i = 1, iMax do
			local	sGroupName, sGroupServer = UnitName(sBase .. i);
			if (sGroupServer and (sGroupServer ~= "")) then
				sGroupName = sGroupName .. "@" .. sGroupServer;
			end
			if (strupper(Membername) == strupper(sGroupName)) then
				KarmaChatDefault(KARMA_MSG_CANNOT_PRE .. KARMA_MSG_REMOVE_ISINGROUP1 .. KARMA_MSG_CANNOT_POST .. " >" .. Membername .. "<" .. KARMA_MSG_REMOVE_ISINGROUP2);
				DoIt = false;
			end
		end

		if DoIt then
			Karma_DialogBox_Text:SetText(KARMA_WINEL_REMOVE_QUESTION_TEXT_PRE .. Membername .. KARMA_WINEL_REMOVE_QUESTION_TEXT_POST);
			Karma_DialogBox_ButtonLeft:SetText(KARMA_WINEL_REMOVE_QUESTION_BTN_EXECUTE);
			Karma_DialogBox_ButtonRight:SetText(KARMA_WINEL_REMOVE_QUESTION_BTN_CANCEL);

			Karma_DialogBox.CallbackLeft_func = Karma_RemoveMember_Really;
			Karma_DialogBox.CallbackLeft_arg1 = Membername;
			Karma_DialogBox:SetAlpha(1.0);
			Karma_DialogBox:Show();

			-- to be closeable by ESC...
			tinsert(UISpecialFrames, Karma_DialogBox:GetName());
		end
	end
end

function	Karma_ToggleWindow()
	KARMA_MAINWND_KEEPOPEN = false;
	if ( KarmaWindow:IsVisible() ) then
		KarmaWindow:Hide();
	else
		Karma_CreateQuestCache(1);

		KarmaWindow:Show();
		KarmaWindow_DressUp();
		KarmaWindow_Update();
	end
end

function	KarmaWindowKeyUp(index)
	Karma_ToggleWindow();
end

function	Karma_ToggleWindow2()
	if (KarmaWindow2:IsVisible()) then
		KarmaWindow2:Hide();
	else
		KarmaWindow2:Show();
	end
end

function	KarmaWindow2KeyUp(index)
	Karma_ToggleWindow2();
end

local	KarmaWindow_FirstOpen = true;

function	KarmaWindow_DressUp()
	KarmaObj.ProfileStart("KarmaWindowDressUp");
	KarmaWindow_Title:SetText(KARMA_TITLE .. KARMA_WINEL_FRAG_SPACE .. "v" .. KARMA_VERSION_TEXT);

	if KarmaWindow_FirstOpen then
		KarmaWindow_FirstOpen = false;
		local	i = Karma_GetConfig(KARMA_CONFIG.MAINWND_INITIALTAB);
		if (i) then
			KarmaWindow_SelectTab(i);
		end
	end

	KarmaObj.ProfileStop("KarmaWindowDressUp");
end

--
--	This function should always be safe to call.
--
function	KarmaWindow_Update(force)
	if Karma_EverythingLoaded() then
		if (KarmaWindow:IsVisible() or force) then
			KarmaWindow_UpdateCurrentMember();
			KarmaWindow_UpdateKarmaBar();
			KarmaWindow_UpdateRegionList();
			KarmaWindow_UpdateZoneList();
			KarmaWindow_UpdateQuestList();
			KarmaWindow_UpdateAchievementList();
			KarmaWindow_UpdateMemberList();
			KarmaWindow_UpdatePartyList();
			KarmaWindow_UpdateAltList();
		end

		Karma_AdjustPartyMemberNameColors();
		Karma_UpdateCurrentTargetNameColor();
	end
end

--
--	Handler for clicks in the partylist
--
function	KarmaWindow_PartyList_OnClick(mousebutton, buttonobject)
	KarmaObj.ProfileStart("KarmaWindow_PartyList_OnClick")

	if (mousebutton == "LeftButton") then
		local	id = buttonobject:GetID();
		local	button = getglobal("PartyList_GlobalButton"..id.."_Text");
		local	text = button:GetText();
		if (text ~= nil) and (text ~= "") then
			if (IsShiftKeyDown()) then
				if (DEFAULT_CHAT_FRAME) and not DEFAULT_CHAT_FRAME.editBox:IsShown() then
					ChatFrame_SendTell(text);
				end
			else
				Karma_SetCurrentMember(text);
				KarmaWindow_ScrollToCurrentMember();
			end
		end
	elseif (mousebutton == "RightButton") then
		local	oMember = Karma_MemberList_GetObject(text);
		if (oMember) then
			if	(oMember[KARMA_DB_L5_RRFFM_CONFLICT] ~= nil) and
				(oMember[KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
				KarmaWindow2_List1_SelectedMember = text;
				Karma_MemberConflict_Menu.Caller = buttonobject:GetName();
				ToggleDropDownMenu(1, nil, Karma_MemberConflict_Menu, buttonobject, 0, 0);
			end
		end	
	end

	KarmaObj.ProfileStop("KarmaWindow_PartyList_OnClick")
end

--
--	Handler for right-clicks in the member list
--
local	MemberlistClickedBtn = nil;
local	MemberlistClickedBtnText = nil;
local	MemberlistClickedName = nil;

local KARMA_MEMBERLIST_MENU_DROPDOWN = {
	[1] = {sName = KARMA_WINEL_INVITEBUTTON, iCommand = 100, bSameServer = 1},
	[2] = {sName = KARMA_WINEL_NEWFORCEBUTTON, iCommand = 700, bOnConflict = 1},
	[3] = {sName = KARMA_WINEL_UPDATEFORCEBUTTON, iCommand = 800, bOnConflict = 1},
	[4] = {sName = KARMA_WINEL_UPDATEBUTTON, iCommand = 200, bSameServer = 1},
	[5] = {sName = KARMA_WINEL_REMOVEBUTTON, iCommand = 300},
	[6] = {sName = KARMA_WINEL_ALTADDBUTTON, iCommand = 400, bNotOnCurrMemberClicked = 1, bAddCurrentMember = 1},
	[7] = {sName = KARMA_WINEL_ALTREMBUTTON, iCommand = 500},
	[8] = {sName = KARMA_WINEL_POSTTOMEMBER, iCommand = 600, bNotOnCurrMemberClicked = 1, bAddCurrentMember = 1},
};

function	Karma_MemberlistMenu_Initialize()
	KarmaObj.ProfileStart("Karma_MemberlistMenu_Initialize")

	if (MemberlistClickedName ~= nil) and (MemberlistClickedName ~= KARMA_UNKNOWN) then
		local	iAt = strfind(MemberlistClickedName, "@", 1, true);
		local	bSameServer = iAt == nil;

		local	info;
		info = {};
		info.text = KARMA_WINEL_TITLE .. KARMA_WINEL_FRAG_COLONSPACE .. MemberlistClickedName;
		info.isTitle = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info);

		local	oMember = Karma_MemberList_GetObject(MemberlistClickedName);
		local	bConflict = false;
		if (oMember ~= nil) and (oMember[KARMA_DB_L5_RRFFM_CONFLICT] ~= nil) then
			bConflict = true;
		end
		local	bIsCurrentMember = false;
		if (KARMA_CURRENTMEMBER) and (MemberlistClickedName ~= KARMA_CURRENTMEMBER) then
			bIsCurrentMember = true;
		end

		info = {};
		for i = 1, getn(KARMA_MEMBERLIST_MENU_DROPDOWN) do
			if  (
					(bSameServer or (KARMA_MEMBERLIST_MENU_DROPDOWN[i].bSameServer ~= 1))
				and
					(bIsCurrentMember or (KARMA_MEMBERLIST_MENU_DROPDOWN[i].bNotOnCurrMemberClicked ~= 1))
				and
					(bConflict or (KARMA_MEMBERLIST_MENU_DROPDOWN[i].bOnConflict ~= 1))
				) then

				if (KARMA_MEMBERLIST_MENU_DROPDOWN[i].bAddCurrentMember == 1) then
					info.text = KARMA_MEMBERLIST_MENU_DROPDOWN[i].sName .. Karma_NilToString(KARMA_CURRENTMEMBER);
				else
					info.text = KARMA_MEMBERLIST_MENU_DROPDOWN[i].sName;
				end
				info.notCheckable = 1;
	
				info.func = Karma_MemberlistMenu_OnSelect;
				info.arg1 = KARMA_MEMBERLIST_MENU_DROPDOWN[i].iCommand;
				info.arg2 = MemberlistClickedName;
	
				UIDropDownMenu_AddButton(info);
			end
		end
	end

	KarmaObj.ProfileStop("Karma_MemberlistMenu_Initialize")
end

function	Karma_MemberlistMenu_OnSelect(self, arg1, arg2)
	KarmaObj.ProfileStart("Karma_MemberlistMenu_OnSelect")

	local	oMember = Karma_MemberList_GetObject(arg2);
	if (oMember ~= nil) then
		if (arg1 == 100) then
			 InviteUnit(arg2);
		elseif (arg1 == 200) then
			Karma_UpdateMember(arg2);
		elseif (arg1 == 300) then
			Karma_RemoveMember(arg2);
		elseif (arg1 == 400) and (KARMA_CURRENTMEMBER) and (arg2 ~= KARMA_CURRENTMEMBER) then
			local	args = {};
			args[2] = arg2;
			args[3] = KARMA_CURRENTMEMBER;
			Karma_SlashAltAdd(args);
		elseif (arg1 == 500) then
			local	args = {};
			args[2] = arg2;
			Karma_SlashAltRemove(args);
		elseif (arg1 == 600) then
			if (DEFAULT_CHAT_FRAME) and not DEFAULT_CHAT_FRAME.editBox:IsShown() then
				Karma_CurrentMember_PostToChat(arg2);
			end
		elseif (arg1 == 700) then
			local	args = {};
			args[2] = arg2;
			Karma_MemberForceNew(args);
		elseif (arg1 == 800) then
			local	args = {};
			args[2] = arg2;
			Karma_MemberForceUpdate(args);
		end
	end

	KarmaObj.ProfileStop("Karma_MemberlistMenu_OnSelect")
end

--
--	Handler for right-clicks in the memberlist for non-members (= Mouseover-List)
--
local	XFactionClickedBtn = nil;
local	XFactionClickedName = nil;

local KARMA_XFACTION_MENU_DROPDOWN = {
	[1] = {sName = KARMA_UNITPOPUP_CHARADD,			iCommand = 1000, bSameFaction = true	},
	[2] = {sName = KARMA_UNITPOPUP_PUBNOTE_CHECKGUILD,	iCommand = 1100, bSameFaction = true	},
	[3] = {sName = KARMA_UNITPOPUP_PUBNOTE_CHECKCHANNEL,	iCommand = 1150, bSameFaction = true	},
	[4] = {sName = KARMA_XFACTION_MENU_CHARADD,		iCommand = 1200, bSameFaction = false	},
	[5] = {sName = KARMA_XFACTION_MENU_CHARNOTE,		iCommand = 1300, bSameFaction = false	},
	[6] = {sName = KARMA_XFACTION_MENU_CHARCHECK,		iCommand = 1400, bSameFaction = false	},
};

function	Karma_XFactionMenu_Initialize()
	KarmaObj.ProfileStart("XFactionMenu_Initialize")

	if ((MemberlistClickedBtn ~= nil) and
	    (MemberlistClickedName ~= nil) and (MemberlistClickedName ~= KARMA_UNKNOWN)) then
		local	bSameFaction = false;
		if ((MemberlistClickedBtn.KarmaMouseoverIndex ~= nil) and (MemberlistClickedBtn.KarmaMouseoverGUID ~= nil)) then
			local	oMouseover = KarmaModuleLocal.MouseOverKeepList[MemberlistClickedBtn.KarmaMouseoverIndex];
			if ((oMouseover ~= nil) and (oMouseover.GUID == MemberlistClickedBtn.KarmaMouseoverGUID)) then
				bSameFaction = oMouseover.Faction == UnitFactionGroup("player");
			else
				KarmaChatDebug("KW_ML_OC: oMouseover nil or GUID mismatch");
				return
			end
		else
			KarmaChatDebug("KW_ML_OC: MemberlistClickedBtn Index or GUID unset");
			return
		end

		local	info;
		info = {};
		info.text = KARMA_WINEL_TITLE .. KARMA_WINEL_FRAG_COLONSPACE .. MemberlistClickedName;
		info.isTitle = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info);

		info.text = "Operates in " .. KARMA_ITSELF .. "'s data or holding space";
		info.isTitle = 0;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info);

		info = {};
		for i = 1, getn(KARMA_XFACTION_MENU_DROPDOWN) do
			if  (bSameFaction == KARMA_XFACTION_MENU_DROPDOWN[i].bSameFaction) then
				info.text = KARMA_XFACTION_MENU_DROPDOWN[i].sName;
				info.notCheckable = 1;

				info.func = Karma_XFactionMenu_OnSelect;
				info.arg1 = KARMA_XFACTION_MENU_DROPDOWN[i].iCommand;
				info.arg2 = MemberlistClickedName;

				UIDropDownMenu_AddButton(info);
			end
		end
	end

	KarmaObj.ProfileStop("Karma_XFactionMenu_Initialize")
end

function	Karma_XFactionMenu_OnSelect(self, arg1, arg2)
	KarmaObj.ProfileStart("Karma_XFactionMenu_OnSelect")

	if (arg1 == 1000) then
		local	args = {};
		args[2] = arg2;
		Karma_SlashAdd(args);
	elseif (arg1 == 1100) then
		local	args = {};
		args[2] = "$GUILD";
		args[3] = arg2;
		Karma_SlashShareQuery(args, 3);
	elseif (arg1 == 1150) then
		local	args = {};
		args[2] = "#";
		args[3] = arg2;
		Karma_SlashShareQuery(args, 3);
	elseif (arg1 == 1200) then
		local	args = {};
		args[2] = arg2;
		args[3] = "+0";
		args[4] = "+" .. date(KARMA_DATEFORMAT .. " %H:%M:%S", time()) .. " <added from cross-faction mouseover>";
		Karma_CrossFactionNote(args);
	elseif (arg1 == 1300) then
		local	sText = KarmaWindow_Filter_EditBox:GetText();
		if ((sText ~= nil) and (sText ~= "")) then
			local	args = {};
			args[2] = arg2;
			args[3] = "+0";
			args[4] = "+" .. date(KARMA_DATEFORMAT .. " %H:%M:%S", time()) .. " <added from cross-faction mouseover>: " .. sText;
			Karma_CrossFactionNote(args);
		else
			KarmaChatDefault("Enter the corresponding note into the filter editbox at the bottom first!");
		end
	elseif (arg1 == 1400) then
		local	args = {};
		args[2] = arg2;
		Karma_CrossFactionInfo(args);
	end


	KarmaObj.ProfileStop("Karma_XFactionMenu_OnSelect")
end

--
--- clicks on memberlist/...
--
function	KarmaWindow_MemberList_OnClick(mousebutton, buttonobject)
	KarmaObj.ProfileStart("KarmaWindow_MemberList_OnClick")

	local	id = buttonobject:GetID();
	MemberlistClickedBtn = getglobal("MemberList_GlobalButton" .. id);
	MemberlistClickedBtnText = getglobal("MemberList_GlobalButton" .. id .. "_Text");
	MemberlistClickedName = MemberlistClickedBtnText:GetText();

	KarmaChatDebug(mousebutton .. " on " .. Karma_NilToString(MemberlistClickedName));


	Karma_WhoAmIInit();
	if ((MemberlistClickedName == WhoAmI) or (MemberlistClickedName == nil) or
	    (MemberlistClickedName == KARMA_UNKNOWN) or (MemberlistClickedName == KARMA_UNKNOWN_ENT)) then
		return
	end

	local	iAt = strfind(MemberlistClickedName, "@", 1, true);
	local	bSameServer = iAt == nil;

	local	bSameFaction = true;
	if (KARMA_CURRENTLIST == 3) then
		bSameFaction = false;
		if ((buttonobject ~= nil) and (buttonobject.KarmaMouseoverIndex ~= nil) and (buttonobject.KarmaMouseoverGUID ~= nil)) then
			local	oMouseover = KarmaModuleLocal.MouseOverKeepList[buttonobject.KarmaMouseoverIndex];
			if ((oMouseover ~= nil) and (oMouseover.GUID == buttonobject.KarmaMouseoverGUID)) then
				bSameFaction = oMouseover.Faction == UnitFactionGroup("player");
			else
				KarmaChatDebug("KW_ML_OC: oMouseover nil or GUID mismatch");
			end
		else
			KarmaChatDebug("KW_ML_OC: buttonobject nil or Index!=GUID");
		end
	end

	local	bFailFaction = false;
	local	bFailServer = false;
	if (mousebutton == "LeftButton") then
		if (IsShiftKeyDown()) then
			if (DEFAULT_CHAT_FRAME) and not DEFAULT_CHAT_FRAME.editBox:IsShown() then
				if (bSameServer) then
					ChatFrame_SendTell(MemberlistClickedName, nil);
				else
					local	sTarget = strsub(MemberlistClickedName, 1, iAt - 1) + "-" + strsub(MemberlistClickedName, iAt + 1);
					ChatFrame_SendTell(sTarget, nil);
				end
			end
		else
			if (buttonobject.bIsMember) then
				Karma_SetCurrentMember(MemberlistClickedName);
				if (KARMA_CURRENTMEMBER) then
					KarmaChatDebug("KARMA_CURRENTMEMBER -> "..KARMA_CURRENTMEMBER);
				end
			else
				bFailFaction = true;
			end
		end
	end

	if (mousebutton == "MiddleButton") then
		if (buttonobject.bIsMember) then
			if (bSameServer) then
				Karma_UpdateMember(MemberlistClickedName);
			else
				bFailServer = true;
			end
		else
			bFailFaction = true;
		end
	end

	if (mousebutton == "RightButton") then
		if ((KARMA_CURRENTLIST == 3) and (not buttonobject.bIsMember)) then
			GameTooltip:Hide();
			ToggleDropDownMenu(1, nil, Karma_XFactionMenu, MemberlistClickedBtn, 0, 0);
		else
			GameTooltip:Hide();
			ToggleDropDownMenu(1, nil, Karma_MemberlistMenu, MemberlistClickedBtn, 0, 0);
		end
	end

	if (bFailFaction) then
		KarmaChatDefault("This player is either not on " .. KARMA_ITSELF .. "'s list or on the other faction. You can not select or update it. (Shift-clicking or right-clicking are possible...)");
	end
	if (bFailServer) then
		KarmaChatDefault("This player is on another server. You can not update it. (Shift-clicking or right-clicking are possible...)");
	end

	KarmaObj.ProfileStop("KarmaWindow_MemberList_OnClick")
end

function	Karma_CurrentMemberValid()
	if (KARMA_CURRENTMEMBER) and (KARMA_CURRENTMEMBER ~= "") then
		return true;
	else
		return false;
	end
end

function	Karma_SetCurrentMember(sName)
	KarmaWindow_CharSelection_DropDown:Hide();

	if (KARMA_CURRENTMEMBER) then
		KarmaChatDebug("KARMA_CURRENTMEMBER: " .. KARMA_CURRENTMEMBER .. " -> <nil>");

		KARMA_CURRENTMEMBER = nil;
		KarmaWindow_Update(true);
		KarmaWindow_NotesInitializeText();
	end

	if (sName) and (sName ~= "") then
		local	oMember = Karma_MemberList_GetObject(sName);
		if (oMember) then
			KarmaChatDebug("KARMA_CURRENTMEMBER: <nil> -> " .. sName);

			KARMA_CURRENTMEMBER = sName;
			KarmaWindow_Update(true);
			KarmaWindow_NotesInitializeText();
		end
	end

	if (KARMA_SELECTEDTAB == 1) then
		KarmaWindow_CharSelection_DropDown:Show();
	end
end

-- Scrolls to the current member in the members list.
-- This is not done every update. This is just so that the
-- current member is always visible when certain operations
-- have been done. Namely increases and decreases in the
-- karma value.
function	KarmaWindow_ScrollToCurrentMember()
	if (not Karma_CurrentMemberValid()) then
		KarmaChatDebug("Scroll: Noone selected.");
		return false;
	end

	local	MemberNames, sMemberName;
	if (KARMA_CURRENTLIST == 1) then
		MemberNames = Karma_MemberList_GetMemberNamesSortedCustom();
	elseif ((KARMA_CURRENTLIST == 2) and (Karma_GetConfig(KARMA_CONFIG.RAID_TRACKALL) == 1)) then
		MemberNames = {};
		local	Dummy;
		for sMemberName, Dummy in pairs(KARMA_PartyNames) do
			tinsert(MemberNames, sMemberName);
		end
	end
	if (MemberNames == nil) then
		KarmaChatDebug("Scroll: Invalid base set.");
		return false;
	end

	local	i, iKey, iNumEntries, iIndex = 0;
	for iKey, sMemberName in pairs(MemberNames) do
		i = i + 1;
		if (sMemberName == KARMA_CURRENTMEMBER) then
			iIndex = i;
		end
	end
	iNumEntries = i;
	KarmaChatDebug("Scroll: " .. KARMA_CURRENTMEMBER .. " = " .. Karma_NilToString(iIndex) .. "/" .. iNumEntries);

	if ((iNumEntries  <= 25) or (iIndex == nil)) then
		FauxScrollFrame_SetOffset(KarmaWindow_MemberList_ScrollFrame, 0);
		KarmaWindow_MemberList_ScrollFrameScrollBar:SetValue(0);
		return (iIndex ~= nil);
	end

	if (iIndex <= 25) then
		FauxScrollFrame_SetOffset(KarmaWindow_MemberList_ScrollFrame, 0);
		KarmaWindow_MemberList_ScrollFrameScrollBar:SetValue(0);
	else
KarmaChatDebug("KW_S2CM: iIndex = " .. iIndex);
		KarmaWindow_MemberList_ScrollFrameScrollBar:SetValue((iIndex - 1) * 13);
		FauxScrollFrame_SetOffset(KarmaWindow_MemberList_ScrollFrame, iIndex - 1);
	end

	return true;
end

function	KarmaWindow_UpdatePartyList()
	KarmaObj.ProfileStart("KarmaWindow_UpdatePartyList");
	local	lMembers, button, i, iNumEntries
	local	sMembername, sServername;
	local	oMember;
	local	red, green, blue, iKarma, bModified, sKarma;

	iNumEntries = GetNumPartyMembers();

	-- clear all buttons from current values:
	for i = 1, 4 do
		local	karmavaluetext = getglobal("PartyList_KarmaValue"..i.."_Text");
		karmavaluetext:SetText("");

		local	buttontext = getglobal("PartyList_GlobalButton"..i.."_Text");
		buttontext:SetText("");

		local	button = getglobal("PartyList_GlobalButton"..i);
		button:UnlockHighlight();
	end

	if (GetNumRaidMembers() > 0) and
	   (Karma_GetConfig(KARMA_CONFIG.RAID_NOGROUP) == 1) then
		local	buttontext = getglobal("PartyList_GlobalButton2_Text");
		buttontext:SetText("-= RAID MODE =-");
		return
	end

	for i = 1, iNumEntries do
		sMembername, sServername = UnitName("party"..i);
		if (sServername) and (sServername ~= "") then
			sMembername = sMembername .. "@" .. sServername;
		end;

		local	button = getglobal("PartyList_GlobalButton"..i);
		local	buttontext = getglobal("PartyList_GlobalButton"..i.."_Text");
		buttontext:SetText(sMembername);
		if (sMembername == KARMA_CURRENTMEMBER) then
			button:LockHighlight();
		end;

		red, green, blue = Karma_MemberList_GetColors(sMembername);
		buttontext:SetTextColor(red, green, blue);

		local	karmavaluetext = getglobal("PartyList_KarmaValue"..i.."_Text");
		local	oMember = Karma_MemberList_GetObject(sMembername);
		if (oMember) then
			iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
			if (iKarma >= 100) then
				sKarma = "++";
			else
				sKarma = iKarma;
			end
			if (bModified) then
				sKarma = "*" .. sKarma;
			end
			karmavaluetext:SetText(sKarma);
		end

		red, green, blue = Karma_GetColors_Karma(sMembername);
		karmavaluetext:SetTextColor(red, green, blue);

		if (oMember) then
			if	(type(oMember[KARMA_DB_L5_RRFFM_CONFLICT]) == "table") and
				(oMember[KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
				karmavaluetext:SetText("CF!");
				karmavaluetext:SetTextColor(1, 0, 0);
			end
		end
	end

	KarmaObj.ProfileStop("KarmaWindow_UpdatePartyList");
end

function	KarmaWindow_UpdateMemberList()
	KarmaObj.ProfileStart("KarmaWindowUpdateMemberList");

	-- clear all buttons from current values:
	local	i;
	for i = 1, KARMA_MEMBERLIST_SIZE do
		local	karmavaluetext = getglobal("MemberList_KarmaValue"..i.."_Text");
		karmavaluetext:SetText("");

		local	buttontext = getglobal("MemberList_GlobalButton"..i.."_Text");
		buttontext:SetText("");

		local	button = getglobal("MemberList_GlobalButton"..i);
		button:UnlockHighlight();

		button.KarmaMouseoverIndex = nil;
		button.KarmaMouseoverGUID  = nil;
		button.bIsMember = false;
	end

	local	Dummy, sMembername, sMyFaction;
	sMyFaction = UnitFactionGroup("player");
	Karma_WhoAmIInit();

	local	iNumEntries;
	local	MemberNames;
	if (KARMA_CURRENTLIST == 1) then
		MemberNames = Karma_MemberList_GetMemberNamesSortedCustom();
	elseif ((KARMA_CURRENTLIST == 2) and (Karma_GetConfig(KARMA_CONFIG.RAID_TRACKALL) == 1)) then
		MemberNames = {};
		for sMembername, Dummy in pairs(KARMA_PartyNames) do
			tinsert(MemberNames, sMembername);
		end
	elseif (KARMA_CURRENTLIST == 3) then
		MemberNames = {};
		GUID2Index = {};
		local	iKey, oMouseOver;
		for iKey, oMouseOver in pairs(KarmaModuleLocal.MouseOverKeepList) do
			GUID2Index[oMouseOver.GUID] = iKey;
			tinsert(MemberNames, oMouseOver.GUID);
		end
	elseif (KARMA_CURRENTLIST < 0) then
		local	iKey, iCount = - KARMA_CURRENTLIST, 0;
		if (type(KarmaModuleLocal.Raid.HistoryTables[iKey]) == "table") then
			local	oHistory = KarmaModuleLocal.Raid.HistoryTables[iKey];
			MemberNames = {};
			for sMembername, Dummy in pairs(oHistory) do
				if ((sMembername ~= "__Start") and (sMembername ~= "__End") and (sMembername ~= WhoAmI)) then
					iCount = iCount + 1;
					tinsert(MemberNames, sMembername);
				end
			end
		end
		KarmaChatDebug("History #" .. iKey .. ": " .. iCount .. " players.");
	end

	if (MemberNames == nil) then
		return
	end

	i = 0;
	for Dummy, sMembername in pairs(MemberNames) do
		i = i + 1;
	end
	iNumEntries = i;

	local	iCounter = 1;
	local	nindex = 1;
	for Dummy, sMembername in pairs(MemberNames) do
		--search the index of the array for the current users name
		if (nindex - FauxScrollFrame_GetOffset(KarmaWindow_MemberList_ScrollFrame)  >= 0) then
			if (iCounter <= KARMA_MEMBERLIST_SIZE) then
				local	iKey, oMouseover;
				if (KARMA_CURRENTLIST == 3) then
					iKey = GUID2Index[sMembername];
					if (iKey and (KarmaModuleLocal.MouseOverKeepList[iKey]) and (KarmaModuleLocal.MouseOverKeepList[iKey].GUID == sMembername)) then
						oMouseover = KarmaModuleLocal.MouseOverKeepList[iKey];
						sMembername = oMouseover.Name;
					else
						iKey = nil;
						sMembername = nil;
					end
				end

				local	buttontext = getglobal("MemberList_GlobalButton"..iCounter.."_Text");
				buttontext:SetTextColor(0.8, 0.8, 0.8);
				local	button = getglobal("MemberList_GlobalButton"..iCounter);
				local	karmavaluetext = getglobal("MemberList_KarmaValue"..iCounter.."_Text");

				button.KarmaMouseoverIndex = iKey;
				button.KarmaMouseoverGUID  = nil;
				button.bIsMember = false;

				if (sMembername) then
					buttontext:SetText(sMembername);
					if (sMembername == KARMA_CURRENTMEMBER) then
						button:LockHighlight();
					end

					local	oMember = Karma_MemberList_GetObject(sMembername);
					if (oMember) then
						button.bIsMember = true;

						local	iKarma, bModified, sKarma, red, green, blue;
						iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
						red, green, blue = Karma_MemberList_GetColors(Karma_MemberObject_GetName(oMember));
						buttontext:SetTextColor(red, green, blue);

						red, green, blue = Karma_GetColors_Karma(sMembername);

						if (iKarma >= 100) then
							sKarma = "++";
						else
							sKarma = iKarma;
						end
						if (bModified) then
							sKarma = "*" .. sKarma;
						end
						karmavaluetext:SetText(sKarma);
						karmavaluetext:SetTextColor(red, green, blue);
					end
				end

				if (oMouseover ~= nil) then
					if (not button.bIsMember) then
--[[
		Value.GUID = UnitGUID("mouseover");
		Value.Faction = UnitFactionGroup("mouseover");
		Value.Name = UnitName("mouseover");
		Value.Race = UnitRace("mouseover");
		Value.Level = UnitLevel("mouseover");
		Value.Class = UnitClass("mouseover");

		Value.Time = time();
		Value.Zone = GetZoneText() .. ": " ..  GetSubZoneText();
]]--
						local	ClassID = Karma_ClassToID(oMouseover.Class);
						if  (ClassID < 0) then
							ClassID = - ClassID;
						end;
						local	sClass = Karma_IDToClass(ClassID);
						if (sClass and (sClass ~= "")) then
							local	iRed, iGreen, iBlue = Karma_ClassMToColor(sClass);
							buttontext:SetTextColor(iRed, iGreen, iBlue);
						end

						if (oMouseover.Level) then
							karmavaluetext:SetText("L" .. oMouseover.Level);
						else
							karmavaluetext:SetText("L??");
						end
						if (oMouseover.Faction == sMyFaction) then
							karmavaluetext:SetTextColor(0.4, 1.0, 0.4);
						else
							karmavaluetext:SetTextColor(1.0, 0.4, 0.4);
						end
					end

					button.KarmaMouseoverGUID = oMouseover.GUID;
				end

				iCounter = iCounter+1;
			else
				break
			end
		end
		nindex = nindex+1;
	end

	--	function FauxScrollFrame_Update(frame, numItems, numToDisplay, valueStep, button, smallWidth, bigWidth, highlightFrame, smallHighlightWidth, bigHighlightWidth )
	-- valueStep = line height in Pixel!
	local	ExtraLines = KARMA_MEMBERLIST_SIZE - (KARMA_MEMBERLIST_SIZE % 2);
	ExtraLines = ExtraLines / 2;
	-- KarmaChatDebug("ML: FSF_U(" .. KarmaWindow_MemberList_ScrollFrame:GetName() .. ", " .. iNumEntries + ExtraLines .. ", " .. KARMA_MEMBERLIST_SIZE .. ", ...)");
	FauxScrollFrame_Update(KarmaWindow_MemberList_ScrollFrame, iNumEntries + ExtraLines, KARMA_MEMBERLIST_SIZE, 13, nil, 0, 0);
	KarmaObj.ProfileStop("KarmaWindowUpdateMemberList");
end

function	KarmaWindow_UpdateCurrentMember()
	KarmaObj.ProfileStart("KarmaWindow_UpdateCurrentMember");

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember == nil) then
		if (KARMA_CURRENTMEMBER ~= nil) then
			Karma_SetCurrentMember(nil);
		end

		KarmaWindow_ChosenPlayer:SetText("");
		KarmaWindow_ChosenPlayerInfo:SetText("");
		KarmaWindow_ChosenPlayerXPPercentage:SetText("");
		KarmaWindow_ChosenPlayerXPAccrued:SetText("");
		KarmaWindow_ChosenPlayerTimePercentage:SetText("");
		KarmaWindow_ChosenPlayerTimeAccrued:SetText("");
		KarmaWindow_ChosenPlayerSkillValue:SetText("");
		KarmaWindow_ChosenPlayerGearPVEValue:SetText("");
		KarmaWindow_ChosenPlayerGearPVPValue:SetText("");
		KarmaWindow_Notes_EditBox:SetText("");

		return -- Perfectly reasonable.
	end

	KarmaWindow_ChosenPlayer:SetText(KARMA_CURRENTMEMBER);

	local	playerinfo = "";
	if (oMember.Meta ~= nil) then
		-- currently only GUILD meta:
		-- lvl: storing number of people we know in this guild
		local	playerlvl = Karma_MemberObject_GetLevel(oMember);
		if (playerlvl and (playerlvl > 0)) then
			local	sGuild = Karma_MemberObject_GetGuild(oMember);
			if (sGuild ~= KarmaModuleLocal.Guildless) then
				playerinfo = playerlvl .. " (known) members";
			else
				playerinfo = playerlvl .. " players";
			end
		end
	else
		local	playerlvl, playerclass, playertalent;
		playerlvl = Karma_MemberObject_GetLevel(oMember) or "";
		playerclass = Karma_MemberObject_GetClass(oMember) or "";
		if (playerclass ~= "") then
			local	red, green, blue = Karma_GetColors_Class(KARMA_CURRENTMEMBER);
			playerclass = "|c" .. string.format("FF%2x%2x%2x", floor(red * 255), floor(green * 255), floor(blue * 255)) .. playerclass
		end

		playertalent = Karma_MemberObject_GetTalentColorizedText(oMember, 1);
		playerinfo = playerlvl .. " " .. playerclass .. "|cFFFFFFFF (" .. playertalent .. "|cFFFFFFFF";
		if (KarmaObj.Talents.SpecCount == 2) then
			local	playertalent2 = Karma_MemberObject_GetTalentColorizedText(oMember, 2);
			if ((playertalent2 ~= nil) and (playertalent2 ~= 0) and (playertalent2 ~= playertalent)) then
				playerinfo = playerinfo .. " + " .. playertalent2 .. "|cFFFFFFFF)";
			end
		end
		playerinfo = playerinfo .. ")";
	end
	KarmaWindow_ChosenPlayerInfo:SetText(playerinfo);

	local iSkill = Karma_MemberObject_GetSkill(oMember);
	if (iSkill >= 0) and (KARMA_SKILL_LEVELS[iSkill] ~= nil) then
		local	sModel = Karma_GetConfig(KARMA_CONFIG_SKILL_MODEL);
		if (sModel == "complex") then
			KarmaWindow_ChosenPlayerSkillValue:SetText(tostring(iSkill) .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_SKILL_LEVELS[iSkill]);
		else
			KarmaWindow_ChosenPlayerSkillValue:SetText(KARMA_SKILL_LEVELS[iSkill]);
		end
	else
		KarmaWindow_ChosenPlayerSkillValue:SetText("");
	end

	local iGearlvl = Karma_MemberObject_GetGearPVE(oMember);
	if (iGearlvl >= 0) and (KARMA_GEAR_PVE_LEVELS[iGearlvl] ~= nil) then
		KarmaWindow_ChosenPlayerGearPVEValue:SetText(KARMA_GEAR_PVE_LEVELS[iGearlvl]);
	else
		KarmaWindow_ChosenPlayerGearPVEValue:SetText("");
	end

	iGearlvl = Karma_MemberObject_GetGearPVP(oMember);
	if (iGearlvl >= 0) and (KARMA_GEAR_PVP_LEVELS[iGearlvl] ~= nil) then
		KarmaWindow_ChosenPlayerGearPVPValue:SetText(KARMA_GEAR_PVP_LEVELS[iGearlvl]);
	else
		KarmaWindow_ChosenPlayerGearPVPValue:SetText("");
	end

	local	memberaccrue_abs;
	if (KARMA_CURRENTCHAR == nil) then
		memberaccrue_abs = Karma_MemberObject_GetTotalXPSummedUp(oMember);
	else
		memberaccrue_abs = Karma_MemberObject_GetXP(oMember);
	end
	if (memberaccrue_abs == nil) then
		memberaccrue_abs = 0;
	end
	local	memberaccrue_rel = Karma_MemberObject_GetXPLVL(oMember);

	do
		local	txt = memberaccrue_abs;
		if (memberaccrue_rel) then
			txt = txt .. " (" .. string.format("%.2f", memberaccrue_rel) .. ")";
		end
		KarmaWindow_ChosenPlayerXPAccrued:SetText(txt);
	end

	local	playeraccrue_abs;
	local	playeraccrue_rel;
	local	oPlayer;
	if (KARMA_CURRENTCHAR) then
		oPlayer = Karma_GetPlayerObject(KARMA_CURRENTCHAR);
	end
	if (oPlayer) then
		playeraccrue_abs = oPlayer[KARMA_DB_L5_RRFFC.XPTOTAL];
		playeraccrue_rel = oPlayer[KARMA_DB_L5_RRFFC.XPLVLSUM];
	end

	if (playeraccrue_abs == nil) or (playeraccrue_abs == 0) then
		KarmaWindow_ChosenPlayerXPPercentage:SetText("0.0");
	else
		local	per = 100 * tonumber(memberaccrue_abs) / tonumber(playeraccrue_abs);
		local	txt = string.format("%.2f", per);
		if (memberaccrue_rel) and (playeraccrue_rel) and (playeraccrue_rel > 0) then
			txt = txt .. " (" .. string.format("%.2f",
					100 * tonumber(memberaccrue_rel) / tonumber(playeraccrue_rel)) .. ")";
		end
		KarmaWindow_ChosenPlayerXPPercentage:SetText(txt);
	end

	local	membertotal;
	if (KARMA_CURRENTCHAR == nil) then
		membertotal = Karma_MemberObject_GetTotalTimePlayedSummedUp(oMember);
	else
		membertotal = Karma_MemberObject_GetTimePlayed(oMember);
	end
	if (membertotal == nil) then
		membertotal = 0;
	end
	KarmaWindow_ChosenPlayerTimeAccrued:SetText(KOH.Duration2String(membertotal));

	local	playertotal;
	if (oPlayer) then
		playertotal = oPlayer[KARMA_DB_L5_RRFFC.PLAYED];
	end
	if (playertotal == nil) or (playertotal == 0) then
		KarmaWindow_ChosenPlayerTimePercentage:SetText("0.0");
	else
		per = 100 * (membertotal / playertotal);
		KarmaWindow_ChosenPlayerTimePercentage:SetText(string.format("%.2f", per));
	end

	KarmaObj.ProfileStop("KarmaWindow_UpdateCurrentMember")
end

function	KarmaWindow_UpdateQuestList()
	KarmaObj.ProfileStart("KarmaWindow_UpdateQuestList")
	local	i, button;
	for i = 1, KARMA_MAINLISTS_SIZE do
		button = getglobal("QuestList_GlobalButton"..i.."_Text");
		button:SetText("");
	end

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember == nil) then
		KarmaObj.ProfileStop("KarmaWindow_UpdateQuestList")
		return;
	end

	local	questidlist = Karma_MemberObject_GetQuestList(oMember);
	if (questidlist == nil) then
		return
	end

	local	lQEx = nil;
	if (KARMA_QExDisplay > 0) then
		--KarmaChatDebug("KarmaWindow_UpdateQuestList: >> Karma_MemberObject_GetQuestExList");
		lQEx = Karma_MemberObject_GetQuestExList(oMember);
		--if lQEx == nil then
		--	KarmaChatDebug("KarmaWindow_UpdateQuestList: lQEx == nil.");
		--end
		--KarmaChatDebug("KarmaWindow_UpdateQuestList: << Karma_MemberObject_GetQuestExList");
	end

	local	iCounter = 1;
	local	nindex = 0;

	local	lQuestNames = Karma_QuestList_GetListOfNames(questidlist);
	local	lQuestInfos = CommonQuestInfoListGet();

	-- now counting lQuestNames instead of questidlist, because of added region entries
	local iNumEntries = 0;
	local key, value;
	for key, value in pairs(lQuestNames) do
		iNumEntries = iNumEntries + 1;
	end

	for key, value in pairs(lQuestNames) do
		--search the index of the array for the current users sName
		if (nindex - FauxScrollFrame_GetOffset(KarmaWindow_QuestList_ScrollFrame)  >= 0) then
			if (iCounter  <= KARMA_MAINLISTS_SIZE) then
				button = getglobal("QuestList_GlobalButton"..iCounter.."_Text");
				button.ExtID = nil;
				local globalQKey = value.id;
				local btntxt = value.name;
				if (KARMA_QZone > 0) then
					--KarmaChatDebug("KW_UQL: globalQKey = " .. globalQKey);
					if (globalQKey == nil) then
						-- region header entry:
						btntxt = value.RegionName .. ":";
					elseif (lQuestInfos ~= nil) and (globalQKey < 0) then
						--KarmaChatDebug("KW_UQL: lQuestInfos ~= nil");
						local globalQKeyPos = - globalQKey;
						local RegionID = nil;
						if (lQuestInfos[globalQKeyPos] ~= nil) then
							--KarmaChatDebug("KW_UQL: lQuestInfos[" .. globalQKeyPos .. "] ~= nil");
							RegionID = lQuestInfos[globalQKeyPos].RegionID;
							local ExtID = lQuestInfos[globalQKeyPos].ExtID;
							if (ExtID) then
								button.ExtID = ExtID;
								btntxt = btntxt .. " {" .. ExtID .. "}";
							end
						end
						if (RegionID ~= nil) then
							btntxt = "- " .. btntxt;
						else
							btntxt = "? " .. btntxt;
						end
					end
				end

				if (KARMA_QExDisplay > 0) then
					if (lQEx ~= nil) and (globalQKey ~= nil) then
						if (lQEx[globalQKey] ~= nil) then
							--KarmaChatDebug("KW_UQL: lQEx[" .. globalQKey .. "] ~= nil");
							local SummedProgress = lQEx[globalQKey].SummedProgress;
							if (SummedProgress == nil) then
								SummedProgress = 0;
							end
							local ObjectiveTotal = lQEx[globalQKey].ObjectiveTotal;
							if (ObjectiveTotal == nil) then
								ObjectiveTotal = 0;
							end
							btntxt = btntxt .. " [" .. SummedProgress .. "/" .. ObjectiveTotal .. "]";
							--KarmaChatDebug("KW_UQL: btntxt = " .. btntxt);
						end
					end
				end

				button:SetText(btntxt);
				iCounter = iCounter + 1;
			end
		end

		nindex = nindex + 1;
	end

	FauxScrollFrame_Update(KarmaWindow_QuestList_ScrollFrame, iNumEntries + 5, KARMA_MAINLISTS_SIZE, 13, nil, 0, 0);
	KarmaObj.ProfileStop("KarmaWindow_UpdateQuestList")
end


function	KarmaWindow_UpdateZoneList()
	KarmaObj.ProfileStart("KarmaWindow_UpdateZoneList")

	local	i, button;
	for i = 1, KARMA_MAINLISTS_SIZE do
		local	button = getglobal("ZoneList_GlobalButton"..i.."_Text");
		button:SetText("");
	end

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember == nil) then
		KarmaObj.ProfileStop("KarmaWindow_UpdateZoneList")
		return;
	end

	local	zoneidlist = Karma_MemberObject_GetZoneList(oMember);
	local	key, value;

	local	iCounter = 1;
	local	nindex = 0;
	local	lZones = Karma_ZoneList_GetListOfNames(zoneidlist);

	-- now counting lZones instead of zoneidlist, because of added region entries
	i = 0;
	for key, value in pairs(lZones) do
		i = i + 1;
	end
	local	iNumEntries = i;

	for key, value in pairs(lZones) do
		--search the index of the array for the current users sName
		if (nindex - FauxScrollFrame_GetOffset(KarmaWindow_ZoneList_ScrollFrame)  >= 0) then
			if (iCounter  <= KARMA_MAINLISTS_SIZE) then
				button = getglobal("ZoneList_GlobalButton" .. iCounter .. "_Text");
				button.RegionID = nil;
				if type(value) == "table" then
					if (value.Region ~= nil) and (value.Region ~= "") then
						if (value.Zone ~= "") then
							button:SetText("- " .. value.Zone);
						else
							button.RegionID = value.RegionID;
							button:SetText(value.Region .. ":");
						end
					else
						button:SetText("? " .. value.Zone);
					end
				else
	 				button:SetText(value);
				end
				iCounter = iCounter + 1;
			end
		end
		nindex = nindex + 1;
	end

	FauxScrollFrame_Update(KarmaWindow_ZoneList_ScrollFrame, iNumEntries + 5, KARMA_MAINLISTS_SIZE, 13, nil, 0, 0);
	KarmaObj.ProfileStop("KarmaWindow_UpdateZoneList")
end

function	KarmaWindow_UpdateRegionList()
	KarmaObj.ProfileStart("KarmaWindow_UpdateRegionList")

	local	i, button;
	for i = 1, KARMA_MAINLISTS_SIZE do
		local	button = getglobal("RegionList_GlobalButton"..i.."_Text");
		button:SetText("");
	end

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember == nil) then
		KarmaObj.ProfileStop("KarmaWindow_UpdateRegionList")
		return;
	end

	local	iNumEntries = 0;
	local	bGotRegions, lRegions = Karma_RegionList_GetLines(oMember);

	-- now counting lZones instead of zoneidlist, because of added region entries
	i = 0;
	for key, value in pairs(lRegions) do
		i = i + 1;
	end

	local	iNumEntries = i;
	local	key, value;
	local	iCounter = 1;
	local	nindex = 0;

	for key, value in pairs(lRegions) do
		--search the index of the array for the current users sName
		if (nindex - FauxScrollFrame_GetOffset(KarmaWindow_RegionList_ScrollFrame)  >= 0) then
			if (iCounter  <= KARMA_MAINLISTS_SIZE) then
				button = getglobal("RegionList_GlobalButton" .. iCounter .. "_Text");
 				button:SetText(value);
				iCounter = iCounter + 1;
			end
		end
		nindex = nindex + 1;
	end

	FauxScrollFrame_Update(KarmaWindow_RegionList_ScrollFrame, iNumEntries + 5, KARMA_MAINLISTS_SIZE, 13, nil, 0, 0);
	KarmaObj.ProfileStop("KarmaWindow_UpdateRegionList")
end

function	KarmaWindow_UpdateAchievementList()
	KarmaObj.ProfileStart("KarmaWindow_UpdateAchievementList")

	local	i, btnObj, btnText;
	for i = 1, KARMA_MAINLISTS_SIZE do
		local	btnText = getglobal("AchievementList_GlobalButton"..i.."_Text");
		btnText:SetText("");
	end

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if ((oMember == nil) or (KARMA_CURRENTCHAR == nil)) then
		KarmaObj.ProfileStop("KarmaWindow_UpdateAchievementList")
		return;
	end

	local	iNumEntries = 0;
	local	lKeys, lAchievements = KarmaObj.Achievements.LinesGet(oMember, KARMA_CURRENTCHAR);
	if (lAchievements == nil) then
		return;
	end

	local	iNumEntries = lKeys.__Count;

	local	iCounter = 1;
	local	iBase = FauxScrollFrame_GetOffset(KarmaWindow_AchievementList_ScrollFrame);
	for iOffset = iBase, iBase + KARMA_MAINLISTS_SIZE - 1 do
		local	btnObj = getglobal("AchievementList_GlobalButton" .. iCounter);
		btnObj.AchievementData = nil;
		local	sKey = lKeys[(iOffset - iBase) + 1];
		if (sKey) then
			btnText = getglobal("AchievementList_GlobalButton" .. iCounter .. "_Text");
			local	sType = strsub(sKey, 1, 1);
			if (sType == "C") then
				local	CatID = tonumber(strsub(sKey, 2));
				btnText:SetText(GetCategoryInfo(CatID) .. ":");
			elseif (sType == "A") then
				btnObj.AchievementData = lAchievements[sKey];
				btnObj.AchievementTitle = lAchievements[sKey].AchievementTitle;
				btnObj.AchievementID = lAchievements[sKey].AchievementID;
				btnText:SetText(" -- " .. lAchievements[sKey].AchievementTitle);
			end
		end
		iCounter = iCounter + 1;
	end

	FauxScrollFrame_Update(KarmaWindow_AchievementList_ScrollFrame, iNumEntries + 5, KARMA_MAINLISTS_SIZE, 13, nil, 0, 0);
	KarmaObj.ProfileStop("KarmaWindow_UpdateAchievementList")
end

function	KarmaWindow_NotesInitializeText()
	KarmaObj.ProfileStart("KarmaWindow_NotesInitializeText")

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember == nil) then
		KarmaWindow_NotesPublic_EditBox:SetText("");
		KarmaWindow_Notes_EditBox:SetText("");
		KarmaObj.ProfileStop("KarmaWindow_NotesInitializeText")
		return;
	end

	local	scrollBar = getglobal(KarmaWindow_Notes_EditBox:GetParent():GetParent():GetName().."ScrollBar")
	scrollBar:SetValue(0);
	KarmaWindow_Notes_EditBox:GetParent():GetParent():UpdateScrollChildRect();

	local	sNotes;

	sNotes = Karma_MemberObject_GetPublicNotes(oMember);
	if (sNotes) then
		KarmaWindow_NotesPublic_EditBox:SetText(sNotes);
	else
		KarmaWindow_NotesPublic_EditBox:SetText("");
	end

	sNotes = Karma_MemberObject_GetNotes(oMember);
	KarmaWindow_Notes_EditBox:SetText(sNotes);

	KarmaObj.ProfileStop("KarmaWindow_NotesInitializeText")
end

function	KarmaWindow_NotePublic_UpdateText()
	KarmaObj.ProfileStart("KarmaWindow_NotesUpdateText");

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember ~= nil) then
		Karma_MemberObject_SetPublicNotes(oMember, KarmaWindow_NotesPublic_EditBox:GetText());
	end

	KarmaObj.ProfileStop("KarmaWindow_NotesUpdateText");
end

function	KarmaWindow_NotesUpdateText()
	KarmaObj.ProfileStart("KarmaWindow_NotesUpdateText")

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember ~= nil) then
		Karma_MemberObject_SetNotes(oMember, KarmaWindow_Notes_EditBox:GetText());
	end

	KarmaObj.ProfileStop("KarmaWindow_NotesUpdateText")
end

function	KarmaObj.UI.NotePublic_Editbox_Tooltip(self, title, key, anchor)
	-- ANCHOR_BOTTOMLEFT: links unten
	if Karma_ShowTooltipHelp() and (type(KARMA_TOOLTIPS[key]) == "table") then
		if (anchor) then
			GameTooltip:SetOwner(self, anchor);
		else
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
		end
	
		GameTooltip:AddLine(KARMA_WINEL_TITLE .. KARMA_WINEL_FRAG_COLONSPACE .. title);
		local	bNextIsBrighter = false;
		for key, value in pairs(KARMA_TOOLTIPS[key]) do
			if (value == "") then
				bNextIsBrighter = true;
			else
				if (bNextIsBrighter) then
					GameTooltip:AddLine(value, 0.9, 0.9, 0.9);
					bNextIsBrighter = false;
				else
					GameTooltip:AddLine(value, 0.8, 0.8, 0.8);
				end
			end
		end
	
		GameTooltip:Show();
	end
end

function	KarmaWindow_UpdateKarmaBar()
	KarmaObj.ProfileStart("KarmaWindow_UpdateKarmaBar")

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember == nil) then
		KarmaWindow_KarmaSlider:SetValue(50);
		KarmaWindow_KarmaIndicator:SetValue(50);
		KarmaWindow_KarmaTextIndicator:SetText("50");
		KarmaObj.ProfileStop("KarmaWindow_UpdateKarmaBar")
		return;
	end

	-- KarmaChatDebug(KARMA_CURRENTMEMBER.." karmarating = "..Karma_MemberObject_GetKarma(oMember));
	local	iKarma = Karma_MemberObject_GetKarma(oMember);
	KarmaWindow_KarmaSlider:SetValue(iKarma);
	KarmaWindow_KarmaIndicator:SetValue(iKarma);
	KarmaWindow_KarmaTextIndicator:SetText(Karma_MemberObject_GetKarmaWithModifiers(oMember));

	if (iKarma == 1) then
		KarmaWindow_KarmaUpButton:Enable();
		KarmaWindow_KarmaDownButton:Disable();
	elseif (iKarma == 100) then
		KarmaWindow_KarmaUpButton:Disable();
		KarmaWindow_KarmaDownButton:Enable();
	else
		KarmaWindow_KarmaUpButton:Enable();
		KarmaWindow_KarmaDownButton:Enable();
	end

	local	red, green, blue;
	red, green, blue = Karma_GetColors_Karma(Karma_MemberObject_GetName(oMember));
	KarmaWindow_KarmaIndicator:SetStatusBarColor(red, green, blue);

	KarmaObj.ProfileStop("KarmaWindow_UpdateKarmaBar")
end

function	Karma_ChangeKarma(sMemberName, scroll, value, note)
	KarmaObj.ProfileStart("Karma_ChangeKarma")

	local	oMember = Karma_MemberList_GetObject(sMemberName);
	if (oMember == nil) then
		KarmaObj.ProfileStop("Karma_ChangeKarma")
		return;
	end

	local	curkarma = Karma_MemberObject_GetKarma(oMember);
	curkarma = curkarma + value;
	if (curkarma <= 0) then
		curkarma = 1;
	end
	if (curkarma > 100) then
		curkarma = 100;
	end
	Karma_MemberObject_SetKarma(oMember, curkarma);

	if (note ~= nil) then
		local	currnote = Karma_MemberObject_GetNotes(oMember);
		if currnote == nil then
			currnote = "";
		end

		currnote = currnote .. note .. KARMA_WINEL_FRAG_NEWLINE;
		Karma_MemberObject_SetNotes(oMember, currnote)
	end

	if (scroll) then
		KarmaWindow_ScrollToCurrentMember();
		KarmaWindow_Update();
	end
	KarmaObj.ProfileStop("Karma_ChangeKarma")
end

function	Karma_DecreaseKarma(sMemberName, scroll, value)
	KarmaObj.ProfileStart("Karma_DecreaseKarma")

	local	oMember = Karma_MemberList_GetObject(sMemberName);
	if (oMember == nil) then
		KarmaObj.ProfileStop("Karma_DecreaseKarma")
		return nil;
	end

	if (value == nil) then
		value = 1;
	end

	local	curkarma = Karma_MemberObject_GetKarma(oMember);
	curkarma = curkarma - value;
	if (curkarma <= 0) then
		curkarma = 1;
	end
	Karma_MemberObject_SetKarma(oMember, curkarma);
	if (scroll) then
		KarmaWindow_ScrollToCurrentMember();
		KarmaWindow_Update();
	end

	KarmaObj.ProfileStop("Karma_DecreaseKarma")
	return curkarma;
end

function	Karma_IncreaseKarma(sMemberName, scroll, value)
	KarmaObj.ProfileStart("Karma_IncreaseKarma")

	local	oMember = Karma_MemberList_GetObject(sMemberName);
	if (oMember == nil) then
		KarmaObj.ProfileStop("Karma_IncreaseKarma")
		return nil;
	end

	if (value == nil) then
		value = 1;
	end

	local	curkarma = Karma_MemberObject_GetKarma(oMember);
	curkarma = curkarma + value;
	if (curkarma > 100) then
		curkarma = 100;
	end
	Karma_MemberObject_SetKarma(oMember, curkarma);
	if (scroll) then
		KarmaWindow_ScrollToCurrentMember();
		KarmaWindow_Update();
	end

	KarmaObj.ProfileStop("Karma_IncreaseKarma")
	return curkarma;
end

function	KarmaWindow_KarmaSlider_OnValueChanged()
	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember) then
		local	oldvalue = Karma_MemberObject_GetKarma(oMember);
		local	newvalue = KarmaWindow_KarmaSlider:GetValue();

		Karma_MemberObject_SetKarma(oMember, newvalue);
		KarmaWindow_KarmaIndicator:SetValue(newvalue);
		KarmaWindow_KarmaTextIndicator:SetText(Karma_MemberObject_GetKarmaWithModifiers(oMember));

		if (abs(oldvalue - newvalue) > 5) then
			KarmaChatSecondary("Changing Karma on " .. KARMA_CURRENTMEMBER .. " from " .. oldvalue .. " to " .. newvalue .."...");
		end
	end
end

function	KarmaWindow_KarmaSlider_OnMouseUp()
	KarmaWindow_KarmaChanged_RefreshSort();
end

function	KarmaWindow_KarmaIndicator_UpDownButtons(up)
	if (up) then
		Karma_IncreaseKarma(KARMA_CURRENTMEMBER, true, 1);
	else
		Karma_DecreaseKarma(KARMA_CURRENTMEMBER, true, 1);
	end
end

function	KarmaWindow_KarmaIndicator_OnMouseUp()
	KarmaWindow_KarmaChanged_RefreshSort();
end

function	KarmaWindow_KarmaChanged_RefreshSort()
	-- if sorting by Karma, this might change the order...
	local	sortby = Karma_GetConfig(KARMA_CONFIG.SORTFUNCTION);
	if (sortby == KARMA_CONFIG.SORTFUNCTION_TYPE_KARMA) then
		-- ... so force refresh of order, but CPU usage is too high to do it "live"
		Karma_MemberList_ResetMemberNamesCache();
		KarmaWindow_Update();
		KarmaWindow_ScrollToCurrentMember();
	else
		KarmaWindow_Update();
	end
end

--
---
--
function	KarmaWindow_Showtip(WndObj, sName, bJoined, iMouseover)
	GameTooltip:SetOwner(WndObj, "ANCHOR_LEFT");
	local	mo = Karma_MemberList_GetObject(sName);

	local	red, green, blue;
	red, green, blue = Karma_GetColors_Karma(sName);
	GameTooltip:SetText(sName, red, green, blue);

	-- tooltip text has the form:
	--	Guild
	--	Gender, Race, Class, Level
	if (mo and (mo.Meta == nil)) then
		local	guild = Karma_MemberObject_GetGuild(mo);
		if (guild ~= "" and guild) then
			GameTooltip:AddLine("<"..guild..">", 1, 1, 1);
		end
	end

	local	temptext = ""
	local	level;
	if (mo) then
		if (mo.Meta == nil) then
			level = Karma_MemberObject_GetLevel(mo);
		end
	elseif (iMouseover) then
		level = KarmaModuleLocal.MouseOverKeepList[iMouseover].Level;
	end
	if (level) then
		local	gender;
		local	race;
		local	class;

		if (mo) then
			gender = Karma_MemberObject_GetGender(mo);
			race = Karma_MemberObject_GetRace(mo);
			class = Karma_MemberObject_GetClass(mo);
		elseif (iMouseover) then
			race = KarmaModuleLocal.MouseOverKeepList[iMouseover].Race;
			class = KarmaModuleLocal.MouseOverKeepList[iMouseover].Class;
		end

		if (gender) then
			temptext = string.format(KARMA_MSG_TIP_LEVEL .. " %s %s %s %s", level, gender, Karma_NilToString(race), Karma_NilToString(class));
		else
			temptext = string.format(KARMA_MSG_TIP_LEVEL .. " %s %s %s", level, Karma_NilToString(race), Karma_NilToString(class));
		end
		GameTooltip:AddLine(temptext, 1, 1, 1);
	end

	if (mo and (mo.Meta == nil) and (Karma_GetConfig(KARMA_CONFIG.TOOLTIP_TALENTS) == 1)) then
		local	oLines, sSummarySub, iTimeOfTalents = KarmaObj.Talents.MemberObjToStringsObj(mo, bShiftPressed);

		if (bShiftReq and not bShiftPressed) then
			sSummary = sSummary .. sSummarySub;
		else
			local	i;
			for i = 1, #oLines do
				if (iTimeOfTalents) then
					GameTooltip:AddLine("Talents as of " .. date(KARMA_DATEFORMAT, iTimeOfTalents) .. ":", 1, 1, 1);
					iTimeOfTalents = nil;
				end
				GameTooltip:AddLine(oLines[i], 1, 1, 1);
				TT_Added = true;
			end
		end
	end

	local	sPlayed = "";
	if (mo and (mo.Meta == nil)) then
		local	iSeconds;
		if (1 == Karma_GetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTOTAL)) then
			iSeconds = Karma_MemberObject_GetTotalTimePlayedSummedUp(mo);
			sPlayed = " (total)";
		elseif (1 == Karma_GetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTHIS)) then
			iSeconds = Karma_MemberObject_GetTimePlayed(mo);
			sPlayed = " (with current char)";
		end
		if (iSeconds) then
			if (iSeconds > 0) then
				sPlayed = " -- over " .. KOH.Duration2String(iSeconds) .. sPlayed;
			else
				sPlayed = " -- never joined" .. sPlayed;
			end
		end
	end

	local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(mo);
	if (mo and bModified) then
		iKarma = math.min(100, iKarma);
		local	iRed, iGreen, iBlue = Karma_Karma2Color(iKarma);
		local	sKarma = Karma_MemberObject_GetKarmaWithModifiers(mo);
		sKarma = format(KARMA_ITSELF .. KARMA_WINEL_FRAG_COLONSPACE .. "|c%s%s|r", ColourToString(1, iRed, iGreen, iBlue), sKarma);
		GameTooltip:AddLine(sKarma .. sPlayed, 1, 1, 1);
	end

	if (bJoined and mo and (mo.Meta == nil)) then
		local	joinedTime = Karma_MemberObject_GetTimeJoinedTimeTotal(mo);
		if (joinedTime and (joinedTime > 0)) then
			local	joinedChar = Karma_MemberObject_GetTimeJoinedCharTotal(mo);
			if (joinedChar == nil) then
				joinedChar = KARMA_UNKNOWN;
			end
			temptext = KARMA_WINEL_LISTMEMBERTIP_JOINED_ATALL_PRE .. joinedChar .. KARMA_WINEL_LISTMEMBERTIP_JOINED_ATALL_POST
					.. date(KARMA_DATEFORMAT .. " %H:%M:%S", joinedTime);
			GameTooltip:AddLine(temptext, 1, 1, 1);
		end

		Karma_WhoAmIInit();
		local	joinedTime = Karma_MemberObject_GetTimeJoinedChar(mo, WhoAmI);
		if (joinedTime and (joinedTime > 0)) then
				temptext = KARMA_WINEL_LISTMEMBERTIP_JOINED_CHAR .. date(KARMA_DATEFORMAT .. " %H:%M:%S", joinedTime);
			GameTooltip:AddLine(temptext, 1, 1, 1);
		end
	
		-- "!*t" would be the path to ideal formatting, but returns a table..
		-- lazy for now, %m,%d,&y is not Mac-compatible though!
		local Try = Karma_MemberObject_GetTimestampTry(mo);
		local Success = Karma_MemberObject_GetTimestampSuccess(mo);
		if (Success) and (Success ~= 0) then
			temptext = KARMA_WINEL_LISTMEMBERTIP_UPDATE_OK .. date(KARMA_DATEFORMAT .. " %H:%M:%S", Success);
		elseif (Try) and (Try ~= 0) then
			temptext = KARMA_WINEL_LISTMEMBERTIP_UPDATE_FAIL .. date(KARMA_DATEFORMAT .. " %H:%M:%S", Try);
		else
			temptext = KARMA_WINEL_LISTMEMBERTIP_UPDATE_NEVER;
		end
		GameTooltip:AddLine(temptext, 1, 1, 1);
	end

	if (mo) then
		-- TODO: configurable
		if (mo[KARMA_DB_L5_RRFFM_TERROR]) then
			local	iTotal, k, v = 0;
			for k, v in pairs(mo[KARMA_DB_L5_RRFFM_TERROR]) do
				if (type(k) == "number") then
					iTotal = iTotal + 1;
				end
			end

			if (iTotal == 5) then
				GameTooltip:AddLine("For The Alliance/For The Horde: Completed. :-(", 1, 0.375, 0.375);
			elseif (iTotal > 0) then
				GameTooltip:AddLine("For The Alliance/For The Horde: Partly completed (" .. (iTotal * 25) .. "%). :-|", 1, 1, 0.375);
			else
				GameTooltip:AddLine("For The Alliance/For The Horde: Not started. :-)", 0.375, 1, 0.375);
			end
		end
	end

--[[
Value.GUID = UnitGUID("mouseover");
Value.Faction = UnitFactionGroup("mouseover");
Value.Name = UnitName("mouseover");
Value.Race = UnitRace("mouseover");
Value.Level = UnitLevel("mouseover");
Value.Class = UnitClass("mouseover");

Value.Time = time();
Value.Zone = GetZoneText() .. ": " ..  GetSubZoneText();
]]--

	if (iMouseover) then
		local	sSeen = "Seen in " .. KarmaModuleLocal.MouseOverKeepList[iMouseover].Zone;
		GameTooltip:AddLine(sSeen, 1, 1, 1);
		sSeen = "At " .. date(KARMA_DATEFORMAT .. " %H:%M:%S", KarmaModuleLocal.MouseOverKeepList[iMouseover].Time);
		GameTooltip:AddLine(sSeen, 1, 1, 1);
	end

	if (KARMA_CURRENTLIST < 0) then
		local	iIndex = - KARMA_CURRENTLIST;
		local	oHistory = KarmaModuleLocal.Raid.HistoryTables[iIndex];
		if (oHistory and (type(oHistory[sName]) == "table")) then
			local	oEntry = oHistory[sName];
			local	sJoined = "Joined initially at " .. date(KARMA_DATEFORMAT .. " %H:%M:%S", oEntry.JoinedFirst);
			GameTooltip:AddLine(sJoined, 1, 1, 1);

			local	iLeft = oEntry.Left;
			if (iLeft == nil) then
				iLeft = time();
			else
				local	sLeft = "Left finally at " .. date(KARMA_DATEFORMAT .. " %H:%M:%S", oEntry.Left);
				GameTooltip:AddLine(sLeft, 1, 1, 1);
			end
			-- KarmaChatDebug("History: " .. sName .. " = " .. oEntry.JoinedFirst .. " -> " .. iLeft .. " (- " .. oEntry.Sideline .. ")");
			local	iTimeInRaid = iLeft - oEntry.JoinedFirst - oEntry.Sideline;
			local	iRaidTotal;
			if (oHistory.__End) then
				iRaidTotal = oHistory.__End - oHistory.__Start;
			else
				iRaidTotal = time() - oHistory.__Start;
			end
			local	sLeft = "Total time in raid: " .. KOH.Duration2String(iTimeInRaid) .. format(" (%.1f%%)", 100.0 * iTimeInRaid / iRaidTotal);
			GameTooltip:AddLine(sLeft, 1, 1, 1);
		end
	end

	if (mo and (mo.Meta == nil)) then
		local	iModified, sModified = mo[KARMA_DB_L5_RRFFM.LASTCHANGED_TIME], mo[KARMA_DB_L5_RRFFM.LASTCHANGED_FIELD];
		if ((iModified ~= nil) and (sModified ~= nil)) then
			local	sAdd = "MRC: " .. sModified .. "@" .. date(KARMA_DATEFORMAT .. " %H:%M:%S", iModified);
			GameTooltip:AddLine(sAdd, 1, 1, 1);
		end

		if (type(mo[KARMA_DB_L5_RRFFM_CONFLICT]) == "table") then
			local	sConflict = mo[KARMA_DB_L5_RRFFM_CONFLICT].Conflict;
			if (mo[KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
				GameTooltip:AddLine("CONFLICT: " .. sConflict, 1, 0.6, 0.2);
			end
		end
	end

	GameTooltip:Show();
end


function	KarmaWindow_PartyList_OnEnter()
	local	id = this:GetID();
	local	button = getglobal("PartyList_GlobalButton"..id.."_Text");
	local	sName = button:GetText();
	if (sName ~= nil and sName ~= "" and sName ~= KARMA_UNKNOWN and sName ~= KARMA_UNKNOWN_ENT) then
		KarmaWindow_Showtip(this, sName, false);
	end
end

function	KarmaWindow_MemberList_OnEnter()
	local	id = this:GetID();
	local	buttontext = getglobal("MemberList_GlobalButton"..id.."_Text");
	local	sName = buttontext:GetText();
	if (sName ~= nil and sName ~= "" and sName ~= KARMA_UNKNOWN and sName ~= KARMA_UNKNOWN_ENT) then
		if (KARMA_CURRENTLIST == 3) then
			local	button = getglobal("MemberList_GlobalButton" .. id);
			local	iKey = button.KarmaMouseoverIndex;
			if (iKey and (KarmaModuleLocal.MouseOverKeepList[iKey]) and (KarmaModuleLocal.MouseOverKeepList[iKey].GUID == button.KarmaMouseoverGUID)) then
				KarmaWindow_Showtip(this, sName, false, iKey);
			else
				KarmaWindow_Showtip(this, sName, true);
			end
		else
			KarmaWindow_Showtip(this, sName, true);
		end
	end
end

function	KarmaWindow_QuestList_OnEnter()
	local	id = this:GetID();
	local	button = getglobal("QuestList_GlobalButton"..id.."_Text");
	local	sName = button:GetText();
	if (sName ~= nil) and (sName ~= "") then
		if (strsub(sName, strlen(sName)) == ":") then
			sName = strsub(sName, 1, strlen(sName) - 1);
		end
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		GameTooltip:SetText(sName, red, green, blue);
		GameTooltip:Show();
	end
end

function	Karma_RegionList_GetLines(oMember, aRegionID, aName)
	local	bFound, iSumTotals = 0, 0;
	local	Result = {};

	local	GetList = function(oRegL, bFound, iSumTotals, Result)
			local	RegionList = CommonRegionListGet();
			local	key, value, subkey, subvalue;
			for key, value in pairs(oRegL) do
				local	iRegionID = value[KARMA_DB_L7_RRFFMCCRR_ID];
				if (aRegionID == nil) or (iRegionID == aRegionID) then
					local	sDiff = KARMA_DUNGEON_DIFFICULTY[value[KARMA_DB_L7_RRFFMCCRR_DIFF]];
					if (sDiff == nil) then
						sDiff = value[KARMA_DB_L7_RRFFMCCRR_DIFF] .. "?";
					end
					if (RegionList[iRegionID][KARMA_DB_L3_CR.ISPVPZONE] == 1) then
						sDiff = sDiff .. " <pvp>";
					end
					if (RegionList[iRegionID][KARMA_DB_L3_CR.ZONETYPE]) then
						sDiff = sDiff .. "/" .. RegionList[iRegionID][KARMA_DB_L3_CR.ZONETYPE];
					end
					if (RegionList[iRegionID][KARMA_DB_L3_CR.ISPVPZONE] == 1) then
						sDiff = sDiff .. " <pvp>";
					end

					local	iTotal = abs(value[KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL]);

					local	sTotal = "";
					if (iTotal >= 86400) then
						sTotal = math.floor(iTotal / 86400) .. "d ";
						iTotal = iTotal % 86400;
					end
					sTotal = sTotal .. math.floor(iTotal / 3600) .. "h ";
					iTotal = iTotal % 3600;
					sTotal = sTotal .. math.floor(iTotal / 60) .. "m";

					iTotal = math.max(0, iTotal);

					if (aName) then
						tinsert(Result, aName .. " (" .. sDiff .. ") :   " .. sTotal);
					else
						aName = RegionList[iRegionID].Name;
						tinsert(Result, aName .. " (" .. sDiff .. ") :   " .. sTotal);
						aName = nil;
					end

					local	starttime, endtime;
					iTotal = 0;
					for subkey, subvalue in pairs(value[KARMA_DB_L7_RRFFMCCRR_PLAYEDDAYS]) do
						starttime = subvalue[KARMA_DB_L8_RRFFMCCRRD_START];
						endtime = subvalue[KARMA_DB_L8_RRFFMCCRRD_END];
						iTotal = iTotal + (endtime - starttime);
						tinsert(Result, "-- " .. date("%Y-%m-%d", subvalue[KARMA_DB_L8_RRFFMCCRRD_START])
							.. ": from " .. date("%H:%M:%S", subvalue[KARMA_DB_L8_RRFFMCCRRD_START])
							.. " to " .. date("%H:%M:%S", subvalue[KARMA_DB_L8_RRFFMCCRRD_END]));
					end

					iSumTotals = iSumTotals + iTotal;
					if (value[KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL] <= 0) then
						value[KARMA_DB_L7_RRFFMCCRR_PLAYEDTOTAL] = iTotal;
					end

					bFound = 1;
				end
			end

			return bFound, iSumTotals, Result;
		end



	if ((oMember ~= nil) and (oMember[KARMA_DB_L5_RRFFM_CHARACTERS] ~= nil)) then
		if (KARMA_CURRENTCHAR ~= nil) then
			local	oMemChar = oMember[KARMA_DB_L5_RRFFM_CHARACTERS][KARMA_CURRENTCHAR];
			if (oMemChar) then
				local	oRegL = oMemChar[KARMA_DB_L6_RRFFMCC_REGIONLIST];
				if ((type(oRegL) == "table") and not KOH.TableIsEmpty(oRegL)) then
					bFound, iSumTotals = GetList(oRegL, bFound, iSumTotals, Result);
				end
			end
		else
			local	sName, oMemChar;
			for sName, oMemChar in pairs(oMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
				local	oRegL = oMemChar[KARMA_DB_L6_RRFFMCC_REGIONLIST];
				if ((type(oRegL) == "table") and not KOH.TableIsEmpty(oRegL)) then
					tinsert(Result, "|cFFFFFFFF=< " .. sName .. " >=|r");
					bFound, iSumTotals = GetList(oRegL, bFound, iSumTotals, Result);
					tinsert(Result, "|cFFFFFFFF--------------------------|r");
				end
			end
		end
	end

	return bFound, Result, iSumTotals;
end

function	KarmaWindow_RegionList_OnEnter()
	local	id = this:GetID();
	local	button = getglobal("RegionList_GlobalButton"..id.."_Text");
	local	sName = button:GetText();
	if (sName ~= nil) and (sName ~= "") then
		if (strsub(sName, strlen(sName)) == ":") then
			sName = strsub(sName, 1, strlen(sName) - 1);
		end

		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		GameTooltip:SetText(sName, red, green, blue);
		GameTooltip:Show();
	end
end

function	KarmaWindow_ZoneList_OnEnter()
	local	id = this:GetID();
	local	button = getglobal("ZoneList_GlobalButton"..id.."_Text");
	local	sName = button:GetText();
	if (sName ~= nil) and (sName ~= "") then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		if (button.RegionID == nil) then
			GameTooltip:SetText(sName, red, green, blue);
		else
			sName = strsub(sName, 1, strlen(sName) - 1)

			local	bFound = 0;
			local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
			if (oMember) then
				local	EntriesL;
				bFound, EntriesL = Karma_RegionList_GetLines(oMember, button.RegionID, sName);
				if (bFound) then
					local	key, value;
					for key, value in pairs(EntriesL) do
						GameTooltip:AddLine(value);
					end
				end
			end
			if (bFound == 0) then
				GameTooltip:SetText(sName, red, green, blue);
			end
		end

		GameTooltip:Show();
	end
end

function	KarmaWindow_AchievementList_OnEnter(self)
	KarmaObj.Achievements.ListTip(self);
end

function	KarmaWindow_AchievementList_OnClick(mouse, frame)
	KarmaObj.Achievements.OnClick(mouse, frame);
end

--
function	Karma_HelpQuestionMark_OnEnter(arg1, this)
	local	oFrame = this:GetParent();
	local	sFrameName = oFrame:GetName();
	if (sFrameName ~= "") and (sFrameName ~= nil) then
		KarmaChatDebug("Looking for help for " .. sFrameName .. ".");

		local	replace = "KarmaWindow";
		local	len = strlen(replace);
		if (strsub(sFrameName, 1, len) == replace) then
			sFrameName = "Help_KW" .. strsub(sFrameName, len + 1);
		end
		replace = "Karma";
		len = strlen(replace);
		if (strsub(sFrameName, 1, len) == replace) then
			sFrameName = "Help_K" .. strsub(sFrameName, len + 1);
		end

		if (type(KARMA_FRAMES_HELP) == "table") then
			if (type(KARMA_FRAMES_HELP[sFrameName]) == "table") then
				GameTooltip:SetOwner(this, "ANCHOR_RIGHT");

				local	key, value, later;
				for key, value in pairs(KARMA_FRAMES_HELP[sFrameName]) do
					if (later) then
						if (value == "~") then
							GameTooltip:AddDoubleLine("~~~~", "~~~~", 1, 1, 1, 1, 1, 1);
						else
							GameTooltip:AddLine(value, 1, 1, 1);
						end
					else
						GameTooltip:AddLine(value, red, green, blue);
						later = true;
					end
				end

				GameTooltip:Show();
			else
				KarmaChatDebug("Missing help for " .. sFrameName .. ".");
			end
		end
	end
end

---
----
---
function	KarmaWindow_AltList_OnEnter()
	local	id = this:GetID();
	local	button = getglobal("AltList_NameButton"..id.."_Text");
	local	sName = button:GetText();
	if (sName ~= nil) and (sName ~= "") then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		GameTooltip:SetText(sName, red, green, blue);
		GameTooltip:Show();
	end
end

function	KarmaWindow_AltList_OnClick(mousebtn, btnobj)
	local	id = btnobj:GetID();
	local	button = getglobal("AltList_NameButton"..id.."_Text");
	local	sName = button:GetText();
	if (sName ~= nil) and (sName ~= "") then
		KarmaChatDebug("Switching to alt <" .. sName .. ">");
		Karma_SetCurrentMember(sName);
		KarmaWindow_ScrollToCurrentMember();
	else
		KarmaChatDebug("Trying to select >nil< alt.");
	end
end

function	KarmaWindow_UpdateAltList()
	KarmaObj.ProfileStart("KarmaWindow_UpdateAltList")

	local	i, button;
	for i = 1, KARMA_ALTLIST_SIZE do
		button = getglobal("AltList_KarmaValueButton"..i.."_Text");
		button:SetText("");
		button = getglobal("AltList_LevelButton"..i.."_Text");
		button:SetText("");
		button = getglobal("AltList_NameButton"..i.."_Text");
		button:SetText("");
	end

	local	AltsObj = KarmaObj.DB.FactionCacheGet()[KARMA_DB_L4_RRFF.ALTGROUPS];
	if (AltsObj == nil) then
		if (KARMA_CURRENTMEMBER) then
			KarmaChatDebug("No alt groups defined.");
		end
		FauxScrollFrame_Update(KarmaWindow_AltList_ScrollFrame, floor(KARMA_ALTLIST_SIZE / 2), KARMA_ALTLIST_SIZE, 13, nil, 0, 0);
		KarmaObj.ProfileStop("KarmaWindow_UpdateAltList")
		return
	end

	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember == nil) then
		if (KARMA_CURRENTMEMBER) then
			KarmaChatDebug(KARMA_CURRENTMEMBER .. ": Ups? Not on Karma's list??");
		end
		FauxScrollFrame_Update(KarmaWindow_AltList_ScrollFrame, floor(KARMA_ALTLIST_SIZE / 2), KARMA_ALTLIST_SIZE, 13, nil, 0, 0);
		KarmaObj.ProfileStop("KarmaWindow_UpdateAltList")
		return;
	end

	local	altid = Karma_MemberObject_GetAltID(oMember);
	if (altid == -1) then
--		KarmaChatDebug(KARMA_CURRENTMEMBER .. ": no alts.");
		FauxScrollFrame_Update(KarmaWindow_AltList_ScrollFrame, floor(KARMA_ALTLIST_SIZE / 2), KARMA_ALTLIST_SIZE, 13, nil, 0, 0);
		KarmaObj.ProfileStop("KarmaWindow_UpdateAltList")
		return
	end

	local	lAlts;
	local	key, value;
	for key, value in pairs(AltsObj) do
		if (value.ID == altid) then
			lAlts = Karma_CopyTable(value.AL);
			break;
		end
	end
	if (lAlts == nil) then
		lAlts = {};
	else
		lAlts = KOH.AlphaBucketSort(lAlts);
	end

	local	iNumEntries = 0;
	i = 0;
	for key, value in pairs(lAlts) do
		i = i + 1;
	end

	KarmaChatDebug(KARMA_CURRENTMEMBER .. ": " .. i .. " alts in same alt-group.");

	local	iNumEntries = i;
	local	iCounter = 1;
	local	nindex = 0;
	local	iKarma, bModified, sKarma, r, g, b;
	for key, value in pairs(lAlts) do
		--search the index of the array for the current users sName
		if (nindex - FauxScrollFrame_GetOffset(KarmaWindow_AltList_ScrollFrame)  >= 0) then
			if (iCounter <= KARMA_ALTLIST_SIZE) then
				local	oMemberAlt = Karma_MemberList_GetObject(value);
				if (oMemberAlt) then
					button = getglobal("AltList_KarmaValueButton" .. iCounter .. "_Text");
					iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMemberAlt);
					if (iKarma) then
						if (iKarma > 99) then
							sKarma = "++";
						else
							sKarma = iKarma;
						end
						if (bModified) then
							sKarma = "*" .. sKarma;
						end
						button:SetText(sKarma);

						iKarma = math.min(iKarma, 100);
						r, g, b = Karma_Karma2Color(iKarma);
						button:SetTextColor(r, g, b);
					end

					button = getglobal("AltList_LevelButton" .. iCounter .. "_Text");
					local	iLevel = Karma_MemberObject_GetLevel(oMemberAlt);
					if (iLevel) and (iLevel > 0) then
						button:SetText(iLevel);
					else
						button:SetText("??");
					end
				end

				button = getglobal("AltList_NameButton" .. iCounter .. "_Text");
				button:SetText(value);
				r, g, b = Karma_GetColors_Class(value);
				button:SetTextColor(r, g, b);

				iCounter = iCounter + 1;
			end
		end
		nindex = nindex + 1;
	end
	FauxScrollFrame_Update(KarmaWindow_AltList_ScrollFrame, iNumEntries + floor(KARMA_ALTLIST_SIZE / 2), KARMA_ALTLIST_SIZE, 13, nil, 0, 0);

	KarmaObj.ProfileStop("KarmaWindow_UpdateAltList")
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

---
---- CharSelection Menu
---
function	KarmaWindow_ListSelection_DropDown_Initialize()
	local	info;

	info = {};
	info.value = 1;
	info.text = KARMA_WINEL_MEMBERLISTTITLE;
	info.arg1 = 1;
	info.func = KarmaWindow_ListSelection_DropDown_OnClick;

	UIDropDownMenu_AddButton(info);

	if (Karma_GetConfig(KARMA_CONFIG.RAID_TRACKALL) == 1) then
		info = {};
		info.value = 2;
		info.text = "Current raid";
		info.arg1 = 2;
		info.func = KarmaWindow_ListSelection_DropDown_OnClick;

		UIDropDownMenu_AddButton(info);
	end

	info = {};
	info.value = 3;
	info.text = "Mouse-'Seen'";
	info.arg1 = 3;
	info.func = KarmaWindow_ListSelection_DropDown_OnClick;

	UIDropDownMenu_AddButton(info);

	if (Karma_GetConfig(KARMA_CONFIG.RAID_TRACKALL) == 1) then
		local	iKey, oHistory;
		for iKey, oHistory in pairs(KarmaModuleLocal.Raid.HistoryTables) do
			info = {};
			info.value = 1000 + iKey;
			info.text = "raid history #" .. iKey;
			info.arg1 = 1000 + iKey;
			info.func = KarmaWindow_ListSelection_DropDown_OnClick;

			UIDropDownMenu_AddButton(info);
		end
	end
end

function	KarmaWindow_ListSelection_DropDown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaWindow_ListSelection_DropDown_Initialize);
	UIDropDownMenu_SetWidth(this, 125);
	UIDropDownMenu_SetButtonWidth(this, 18);

	UIDropDownMenu_SetSelectedID(KarmaWindow_ListSelection_DropDown, KARMA_CURRENTLIST);
end

function	KarmaWindow_ListSelection_DropDown_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaWindow_ListSelection_DropDown, this:GetID());
	if (arg1 ~= nil) and (arg1 ~= "") then
		if (arg1 > 1000) then
			KARMA_CURRENTLIST = 1000 - arg1;
		else
			KARMA_CURRENTLIST = arg1;
		end
KarmaChatDebug("Selected current list: " .. arg1);
		KarmaWindow_Update();
	end
end

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

---
---- CharSelection Menu
---
function	KarmaWindow_CharSelection_DropDown_Initialize()
	local	info;

	info = {};
	info.value = 1;
	info.isTitle = 1;
	info.notCheckable = 1;
	info.text = "List data sources by character:";

	UIDropDownMenu_AddButton(info);

	local	oMember;
	if (KARMA_CURRENTMEMBER ~= nil) then
		oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	end
	local	oCharacterL = KarmaObj.DB.SF.CharacterListGet();
	if ((KARMA_CURRENTMEMBER == nil) or (oMember == nil) or (oCharacterL == nil)) then
		info = {};
		info.value = 2;
		info.text = "-- nothing available --";
		info.arg1 = "";

		UIDropDownMenu_AddButton(info);

		KarmaModuleLocal.CharSelection_Index = 2;

		return
	end

	local	bHasCurrentChar, iHasCurrentChar = (KARMA_CURRENTCHAR == nil);
	local	sCharAvail, iCharAvail;

	Karma_WhoAmIInit();
	key = WhoAmI;

	if (KarmaObj.DB.MC.Exists(oMember, key)) then
		if (KARMA_CURRENTCHAR == key) then
			bHasCurrentChar = true;
			iHasCurrentChar = 2;
		end
		if (sCharAvail == nil) then
			sCharAvail = key;
			iCharAvail = 2;
		end

		info = {};
		info.value = 2;
		info.text = "Show data related to >" .. key .. "<";
		info.arg1 = key;
		info.func = KarmaWindow_CharSelection_DropDown_OnClick;

		UIDropDownMenu_AddButton(info);
	end

	local	i, value = 3;
	for key, value in pairs(oCharacterL) do
		if ((key ~= WhoAmI) and KarmaObj.DB.MC.Exists(oMember, key)) then
			if (KARMA_CURRENTCHAR == key) then
				bHasCurrentChar = true;
				iHasCurrentChar = i;
			end
			if (sCharAvail == nil) then
				sCharAvail = key;
				iCharAvail = i;
			end

			info = {};
			info.value = i;
			info.text = "Show data related to >" .. key .. "<";
			info.arg1 = key;
			info.func = KarmaWindow_CharSelection_DropDown_OnClick;

			UIDropDownMenu_AddButton(info);

			i = i + 1;
		end
	end

	info = {};
	info.value = i;
	info.text  = "Show total data";
	info.arg1  = nil;
	info.func = KarmaWindow_CharSelection_DropDown_OnClick;

	UIDropDownMenu_AddButton(info);

	KarmaModuleLocal.CharSelection_Index = nil;
	if (not bHasCurrentChar) then
		if (KARMA_CURRENTCHAR ~= nil) then
			KARMA_CURRENTCHAR = sCharAvail;
			Karma_MemberList_ResetMemberNamesCache();
			KarmaWindow_Update();

			if (iCharAvail) then
				KarmaChatDebug("Force-selected current char: " .. Karma_NilToString(sCharAvail));
				KarmaModuleLocal.CharSelection_Index = - iCharAvail;
			end
		end
	else
		KarmaChatDebug("Selected current char in entry " .. Karma_NilToString(iHasCurrentChar));
		KarmaModuleLocal.CharSelection_Index = iHasCurrentChar;
	end

	if (KarmaModuleLocal.CharSelection_Index == nil) then
		KarmaChatDebug("No entries to current char and/or no current char selected. Fall-through to all data.");
		KarmaModuleLocal.CharSelection_Index = i;
	end
end

function	KarmaWindow_CharSelection_DropDown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaWindow_CharSelection_DropDown_Initialize);
	UIDropDownMenu_SetWidth(this, 210);
	UIDropDownMenu_SetButtonWidth(this, 25);

	local	bRefresh = false;
	if (KarmaModuleLocal.CharSelection_Index < 0) then
		bRefresh = true;
		KarmaModuleLocal.CharSelection_Index = - KarmaModuleLocal.CharSelection_Index;
	end
	UIDropDownMenu_SetSelectedValue(KarmaWindow_CharSelection_DropDown, KarmaModuleLocal.CharSelection_Index);
	if (bRefresh) then
		KarmaWindow_Update();
	end
end

function	KarmaWindow_CharSelection_DropDown_OnClick(self, arg1)
	UIDropDownMenu_SetSelectedID(KarmaWindow_CharSelection_DropDown, this:GetID());
	if (arg1 ~= "") then
		KARMA_CURRENTCHAR = arg1;
		Karma_MemberList_ResetMemberNamesCache();
		KarmaWindow_Update();

		KarmaChatDebug("Selected current char: " .. Karma_NilToString(arg1));
	end
end

---
---- list choice
---
function	KarmaWindow_ListChoice_Checkbox_OnLoad(ListChar)
	if (ListChar) and (ListChar ~= "") then
		this:SetChecked(Karma_GetConfig(KARMA_CONFIG_MAINWND_LISTPREFIX .. ListChar));
		KarmaWindow_Lists_SetAnchors();
	end
end

function	KarmaWindow_ListChoice_Checkbox_OnClick(ListChar)
	if (ListChar) and (ListChar ~= "") then
		Karma_SetConfig(KARMA_CONFIG_MAINWND_LISTPREFIX .. ListChar, KOH.Nil1To01(this:GetChecked()));
		KarmaWindow_Lists_SetAnchors();
	end
end

---
---- Skill Button
---
function	Karma_SkillButton_Menu_Initialize()
	KarmaObj.ProfileStart("Karma_SkillButton_Menu_Initialize")

	if (Karma_CurrentMemberValid()) then
		local	info;
		info = {};
		info.text = KARMA_CURRENTMEMBER .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_WINEL_CHOSENPLAYERSKILLTITLE;
		info.isTitle = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.func = Karma_SkillButton_Menu_OnSelect;
		info.arg2 = KARMA_CURRENTMEMBER;
		for i = 0, 100 do
			if (KARMA_SKILL_LEVELS[i]) then
				info.text = KARMA_SKILL_LEVELS[i];
				info.arg1 = i;
		
				UIDropDownMenu_AddButton(info);
			end
		end

		info.text = "----------------------------------------";
		info.notClickable = 1;
		info.arg1 = nil;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.func = Karma_SkillButton_Menu_OnSelect;
		info.text = KARMA_LEVEL_RESET;
		info.arg1 = -1;
		info.arg2 = KARMA_CURRENTMEMBER;
		UIDropDownMenu_AddButton(info);
	end

	KarmaObj.ProfileStop("Karma_SkillButton_Menu_Initialize")
end

function	Karma_SkillButton_Menu_OnSelect(self, arg1, arg2)
	KarmaObj.ProfileStart("Karma_SkillButton_Menu_OnSelect")

	local	oMember = Karma_MemberList_GetObject(arg2);
	if (oMember ~= nil) and (arg1 ~= nil) then
		Karma_MemberObject_SetSkill(oMember, arg1);
		KarmaWindow_Update();
	end

	KarmaObj.ProfileStop("Karma_SkillButton_Menu_OnSelect")
end

function	KarmaWindow_SkillButton_OnClick(mousebutton, buttonobject)
	KarmaObj.ProfileStart("KarmaWindow_SkillButton_OnClick")

	GameTooltip:Hide()
	if (Karma_CurrentMemberValid()) then
		ToggleDropDownMenu(1, nil, Karma_SkillButton_Menu, buttonobject, 0, 0);
	end

	KarmaObj.ProfileStop("KarmaWindow_SkillButton_OnClick")
end

---
---- Gear/PVE Button
---
function	Karma_GearPVEButton_Menu_Initialize()
	KarmaObj.ProfileStart("Karma_GearPVEButton_Menu_Initialize")

	if (Karma_CurrentMemberValid()) then
		local	info;
		info = {};
		info.text = KARMA_CURRENTMEMBER .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_WINEL_CHOSENPLAYERGEARPVETITLE;
		info.isTitle = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.func = Karma_GearPVEButton_Menu_OnSelect;
		info.arg2 = KARMA_CURRENTMEMBER;
		for i = 0, 100 do
			if (KARMA_GEAR_PVE_LEVELS[i]) then
				info.text = KARMA_GEAR_PVE_LEVELS[i];
				info.arg1 = i;
		
				UIDropDownMenu_AddButton(info);
			end
		end

		info.text = "----------------------------------------";
		info.notClickable = 1;
		info.arg1 = nil;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.func = Karma_GearPVEButton_Menu_OnSelect;
		info.text = KARMA_LEVEL_RESET;
		info.arg1 = -1;
		info.arg2 = KARMA_CURRENTMEMBER;
		UIDropDownMenu_AddButton(info);
	end

	KarmaObj.ProfileStop("Karma_GearPVEButton_Menu_Initialize")
end

function	Karma_GearPVEButton_Menu_OnSelect(self, arg1, arg2)
	KarmaObj.ProfileStart("Karma_GearPVEButton_Menu_OnSelect")

	local	oMember = Karma_MemberList_GetObject(arg2);
	if (oMember ~= nil) and (arg1 ~= nil) then
		Karma_MemberObject_SetGearPVE(oMember, arg1);
		KarmaWindow_Update();
	end

	KarmaObj.ProfileStop("Karma_GearPVEButton_Menu_OnSelect")
end

function	KarmaWindow_GearPVEButton_OnClick(mousebutton, buttonobject)
	KarmaObj.ProfileStart("KarmaWindow_GearPVEButton_OnClick")

	GameTooltip:Hide()
	if (Karma_CurrentMemberValid()) then
		ToggleDropDownMenu(1, nil, Karma_GearPVEButton_Menu, buttonobject, 0, 0);
	end

	KarmaObj.ProfileStop("KarmaWindow_GearPVEButton_OnClick")
end

---
---- Gear/PVP Button
---
function	Karma_GearPVPButton_Menu_Initialize()
	KarmaObj.ProfileStart("Karma_GearPVPButton_Menu_Initialize")

	if (Karma_CurrentMemberValid()) then
		local	info;
		info = {};
		info.text = KARMA_CURRENTMEMBER .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_WINEL_CHOSENPLAYERGEARPVPTITLE;
		info.isTitle = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.func = Karma_GearPVPButton_Menu_OnSelect;
		info.arg2 = KARMA_CURRENTMEMBER;
		for i = 0, 100 do
			if (KARMA_GEAR_PVP_LEVELS[i]) then
				info.text = KARMA_GEAR_PVP_LEVELS[i];
				info.arg1 = i;
		
				UIDropDownMenu_AddButton(info);
			end
		end

		info.text = "----------------------------------------";
		info.notClickable = 1;
		info.arg1 = nil;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.func = Karma_GearPVPButton_Menu_OnSelect;
		info.text = KARMA_LEVEL_RESET;
		info.arg1 = -1;
		info.arg2 = KARMA_CURRENTMEMBER;
		UIDropDownMenu_AddButton(info);
	end

	KarmaObj.ProfileStop("Karma_GearPVPButton_Menu_Initialize")
end

function	Karma_GearPVPButton_Menu_OnSelect(self, arg1, arg2)
	KarmaObj.ProfileStart("Karma_GearPVPButton_Menu_OnSelect")

	local	oMember = Karma_MemberList_GetObject(arg2);
	if (oMember ~= nil) and (arg1 ~= nil) then
		Karma_MemberObject_SetGearPVP(oMember, arg1);
		KarmaWindow_Update();
	end

	KarmaObj.ProfileStop("Karma_GearPVPButton_Menu_OnSelect")
end

function	KarmaWindow_GearPVPButton_OnClick(mousebutton, buttonobject)
	KarmaObj.ProfileStart("KarmaWindow_GearPVPButton_OnClick")

	GameTooltip:Hide()
	if (Karma_CurrentMemberValid()) then
		ToggleDropDownMenu(1, nil, Karma_GearPVPButton_Menu, buttonobject, 0, 0);
	end

	KarmaObj.ProfileStop("KarmaWindow_GearPVPButton_OnClick")
end

--
-- Page 2
--
function	KarmaObj.UI.NotesPublic.QueryBtnClicked(arg1, self)
	if (KARMA_CURRENTMEMBER == nil) then
		KarmaChatDefault("No player selected!");
		return
	end

	if (GetNumGuildMembers() > 1) then
		local	args = {};
		args[2] = "$GUILD";
		args[3] = KARMA_CURRENTMEMBER;
		-- "?p" - request
		Karma_SlashShareQuery(args, 3, true);
	else
		KarmaChatDefault("You're the only guild member online to query about " .. KARMA_CURRENTMEMBER .. "... (At least that's what the UI claims. Did you open your social frame yet?)");
	end


	local	args = {};
	args[2] = "#";
	args[3] = KARMA_CURRENTMEMBER;
	-- "?p" - request
	Karma_SlashShareQuery(args, 3, true);
end

function	KarmaObj.UI.NotesPublic.ResultsTip(arg1, self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	if (KARMA_CURRENTMEMBER ~= nil) then
		GameTooltip:AddLine("Karma/public notes about: " .. KARMA_CURRENTMEMBER, 1, 1, 0);
		GameTooltip:AddLine(" ");

		if (KarmaModuleLocal.NotesPublic.Results[KARMA_CURRENTMEMBER] ~= nil) then
			local	sFrom, aStance;
			for sFrom, aStance in pairs(KarmaModuleLocal.NotesPublic.Results[KARMA_CURRENTMEMBER]) do
				local	sFromOut = sFrom;
				local	red, green, blue = Karma_GetColors_Karma(sFrom);
				if (red + green + blue < 2.95) then
					sFromOut = format("|cFF%02X%02X%02X%s|r", red, green, blue, sFrom);
				end

				local	sLine = sFromOut .. " says:";
				if (aStance.sKarma) then
					sLine = sLine .. " [" .. aStance.sKarma .. "]";
				end
				if (aStance.sNotePub) then
					sLine = sLine .. " => <<" .. aStance.sNotePub .. ">>";
				end
				GameTooltip:AddLine(sLine, 1, 1, 1);
			end
		else
			GameTooltip:AddLine("No information available.");
		end
	else
		GameTooltip:AddLine("No player selected.");
	end

	GameTooltip:Show();
end

-----------------------------------------
--	UNITPopUp Patch
-----------------------------------------

function	Karma_InsertChatFramePatch()
	if (KARMA_OriginalChatFrame_OnEvent == nil) then
		KARMA_OriginalChatFrame_OnEvent = ChatFrame_OnEvent;
		ChatFrame_OnEvent = Karma_ChatFrame_OnEvent;
	end
end

-- TODO: change to hooksecurefunc? or will that open the FriendsFrame on /who?
--[[
function	Karma_InsertWhoUpdatePatch()
	if (KARMA_Original_Who_Update == nil) then
		KARMA_Original_Who_Update = FriendsFrame_OnEvent
		FriendsFrame_OnEvent = Karma_Who_Update;
	end
end
]]--

function	Karma_Event_PlayerTargetChanged()
	if (KarmaWindow:IsVisible() and Karma_CurrentMemberValid()) then
		return;
	end

	-- window is not open or no member is chosen
	if  (UnitName("target") ~= nil) and (UnitName("target") ~= KARMA_UNKNOWN) and
		UnitIsPlayer("target") and not (UnitIsUnit("target", "player")) and 
		(UnitFactionGroup("target") == UnitFactionGroup("player")) then

		local	targetname, targetserver = UnitName("target");
		local	oMember = Karma_MemberList_GetObject(targetname, targetserver);
		if (oMember) then
			if (targetserver and (targetserver ~= "")) then
				targetname = targetname .. "@" .. targetserver;
			end
			Karma_SetCurrentMember(targetname);
		end
	end
end

function	Karma_Event_UpdateMouseOverUnit()
	if (UnitIsPlayer("mouseover") and not UnitIsUnit("player", "mouseover") and not IsInInstance()) then
		local	key, value;
		for key, value in pairs(KarmaModuleLocal.MouseOverKeepList) do
			if (value.GUID == UnitGUID("mouseover")) then
				value.Time = time();
				return;
			end
		end

		-- not yet in storage. add
		KarmaModuleLocal.MouseOverKeepIndex = KarmaModuleLocal.MouseOverKeepIndex + 1;
		if (KarmaModuleLocal.MouseOverKeepIndex == KarmaModuleLocal.MouseOverKeepCount + 1) then
			KarmaModuleLocal.MouseOverKeepIndex = 1;
		end
		KarmaModuleLocal.MouseOverKeepList[KarmaModuleLocal.MouseOverKeepIndex] = {};
		local	Value = KarmaModuleLocal.MouseOverKeepList[KarmaModuleLocal.MouseOverKeepIndex];
		Value.GUID = UnitGUID("mouseover");
		Value.Faction = UnitFactionGroup("mouseover");
		local	sName, sServer = UnitName("mouseover");
		if (sServer and (sServer ~= "")) then
			sName = sName .. "@" .. sServer;
		end
		Value.Name = sName;
		Value.Race = UnitRace("mouseover");
		Value.Level = UnitLevel("mouseover");
		Value.Class = UnitClass("mouseover");
		Value.Sex = UnitSex("mouseover");

		Value.Time = time();
		Value.Zone = GetZoneText() .. ": " ..  GetSubZoneText();
		local	_x, _y = GetPlayerMapPosition("player");
		if (_x == 0) and (_y == 0) then
			SetMapToCurrentZone();
			_x, _y = GetPlayerMapPosition("player");
		end
		Value.Koords = { x = _x, y = _y };
	end
end

function	Karma_MouseOverUnitLog_Compare(val1, val2)
	return (val1.Time < val2.Time);
end

function	Karma_MouseOverUnitLog_Status(args)
	local	i, order, key, trans, value, name2click;
	local	playerfaction = UnitFactionGroup("player");
	if (args[2]) and (args[2] ~= "") then
		local	key = tonumber(args[2]);
		if (key) then
			value = KarmaModuleLocal.MouseOverKeepList[key];
			if (value.Faction == playerfaction) then
				name2click = "|cFF80FF80" .. KOH.Name2Clickable(value.Name) .. "|r";
			else
				name2click = "|cFFFF8080" .. value.Name .. "|r";
			end
			KarmaChatSecondary("[" .. key .. ": " .. value.Faction .. "] " .. name2click .. " " .. value.Race .. " " .. value.Level .. " " .. value.Class .. " (" .. date("%H:%M:%S", value.Time) .. ")");
			KarmaChatSecondary("-- seen at " .. value.Zone .. " { X = " .. value.Koords.x .. ", Y = " .. value.Koords.y .. " }");
		else
			for i = 1, KarmaModuleLocal.MouseOverKeepCount do
				if (KarmaModuleLocal.MouseOverKeepList[i]) then
					value = KarmaModuleLocal.MouseOverKeepList[i];
					if (strfind(value.Name, args[2], 1, true) ~= nil) then
						if (value.Faction == playerfaction) then
							name2click = "|cFF80FF80" .. KOH.Name2Clickable(value.Name) .. "|r";
						else	-- foreign also clickable to be able to shift-click to copy to chatline
							name2click = "|cFFFF8080" .. KOH.Name2Clickable(value.Name) .. "|r";
						end
						KarmaChatSecondary("[" .. i .. ": " .. value.Faction .. "] " .. name2click .. " " .. value.Race .. " " .. value.Level .. " " .. value.Class .. " (" .. date("%H:%M:%S", value.Time) .. ")");
						KarmaChatSecondary("-- seen at " .. value.Zone .. " { X = " .. value.Koords.x .. ", Y = " .. value.Koords.y .. " }");
					end
				end
			end
		end

		return
	end

	KarmaChatSecondary("Most recent up to " .. KarmaModuleLocal.MouseOverKeepCount .. " mouse-overs:");

	local	order = {};
	for i = 1, KarmaModuleLocal.MouseOverKeepCount do
		if (KarmaModuleLocal.MouseOverKeepList[i]) then
			order[i] = { Index = i, Time = KarmaModuleLocal.MouseOverKeepList[i].Time };
		end
	end

	KOH.GenericSort(order, Karma_MouseOverUnitLog_Compare);

	local	trans;
	for key, trans in pairs(order) do
		value = KarmaModuleLocal.MouseOverKeepList[trans.Index];
		if (value) then
			if (value.Faction == playerfaction) then
				name2click = "|cFF80FF80" .. KOH.Name2Clickable(value.Name) .. "|r";
			else
				name2click = "|cFFFF8080" .. value.Name .. "|r";
			end
			KarmaChatSecondary("{" .. trans.Index .. ": " .. value.Faction .. "} " .. name2click .. " " .. value.Race .. " " .. value.Level .. " " .. value.Class .. " (" .. date("%H:%M:%S", value.Time) .. ")");
		end
	end

	KarmaChatSecondary("***");
end

-----------------------------------------
--	Other commands
-----------------------------------------

function	Karma_CommandChannelCheck(args)
	local	Channel = args.sChannel;
	if (strlen(Channel) == 1) then
		if (tonumber(Channel)) then
			Channel = tonumber(Channel);
		end
	end
	if (type(Channel) == "number") then
		KarmaChatDefault(KARMA_MSG_CHECKCHANNEL_ONE .. " #" .. args.sChannel);
	else
		KarmaChatDefault(KARMA_MSG_CHECKCHANNEL_ONE .. " <" .. args.sChannel .. ">");
	end
	KARMA_Online.ChannelTime = time();
	KARMA_Online.ChannelName = Channel;
	ListChannelByName(Channel);

	-- delay next command by 15 seconds (automatic reset in ChatEvent is after 10.x seconds)
	KarmaModuleLocal.Timers.CmdQ = GetTime() + 15;
end

function	Karma_QueueCommandChannelCheck(channel)
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "channelcheck - " .. channel, func = Karma_CommandChannelCheck, args = { sChannel = channel }};
end

-----------------------------------------
--	Karma_Who_Update - Callees
-----------------------------------------

function	Karma_Command_AddIgnore_Insert(args)
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "addignorecheck - "..args[2], func = Karma_Command_AddIgnore_Start, args = {sName = args[2]}};
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "updatewindow", func = Karma_Command_UpdateMembers, args = {}};
end

function	Karma_Command_AddIgnore_Start(args)
	Karma_Executing_Command = true;

	-- Create a who command and send it to the server for processing
	local	whotext = WHO_TAG_NAME.."\""..args.sName.."\""
	Karma_WhoQueue[getn(Karma_WhoQueue)+1] = {func = Karma_AddIgnore_Complete, sName = args.sName, text = whotext};

	Karma_SendWho(whotext);
end

function	Karma_AddIgnore_Complete(addname)
	local	numWhos, totalCount = GetNumWhoResults();
	local	sName, sNameLower, guild, level, race, class, zone, group, mo
	local	i = 0;
	local	found = false;
	-- Huh? Makes it impossible to have an accented letter as first in name, which is a common tactic of pvp losers...
	-- addname = string.upper(KarmaObj.NameToBucket(strsub(addname, 1, 1)))..strsub(addname, 2)
	local addnameLower = strlower(addname);
	for i = 1, totalCount do
		sName, guild, level, race, class, zone, group = GetWhoInfo(i);
		sNameLower = strlower(sName);
		if (sNameLower == addnameLower) then
			Karma_MemberList_Add(sName);
			Karma_MemberList_Update(sName, level, class, race, guild);
			mo = Karma_MemberList_GetObject(addname);
			Karma_MemberObject_SetKarma(mo, 1);
			KarmaChatDefault(addname .. KARMA_MSG_IGNOREMEMBER_ADDED);
			found = true;
		end
	end
	if (found == false) then
		KarmaChatDefault(addname .. KARMA_MSG_ADDORIGNMEMBER_OFFLINE);
	end
	if (FriendsFrame:IsVisible()) then
		SetWhoToUI(1);
	else
		SetWhoToUI(0);
	end

	Karma_Executing_Who = nil;
	Karma_Executing_Command = false;
end

function	Karma_Command_AddMember_Insert(args)
	local	bForce = args[3] == "force";
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = { 	sName = "addmembercheck - " .. args[2],
								func = Karma_Command_AddMember_Start,
								args = { sName = args[2], bForce = bForce }
							};
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = { sName = "updatewindow", func = Karma_Command_UpdateMembers, args = {}};
end

function	Karma_Command_AddMember_Start(args)
	Karma_Executing_Command = true;
	-- Create a who command and send it to the server for processing
	local	whotext = WHO_TAG_NAME.."\""..args.sName.."\""
	Karma_WhoQueue[getn(Karma_WhoQueue)+1] = { method = Karma_AddMember_Complete, sName = args.sName, bForce = args.bForce, text = whotext};

	Karma_SendWho(whotext);
end

function	Karma_AddMember_Complete(data)
	local	addname = data.sName;
	local	numWhos, totalCount = GetNumWhoResults();
	local	sName, sNameLower, guild, level, race, class, zone, group;
	local	i = 0;
	local	found = false;
	-- Huh? Makes it impossible to have an accented letter as first in name, which is a common tactic of pvp losers...
	-- addname = string.upper(KarmaObj.NameToBucket(strsub(addname, 1, 1)))..strsub(addname, 2)
	local addnameLower = strlower(addname);
	for i = 1, totalCount do
		sName, guild, level, race, class, zone, group = GetWhoInfo(i);
		sNameLower = strlower(sName);
		if (sNameLower == addnameLower) then
			Karma_MemberList_Add(sName);
			Karma_MemberList_Update(sName, level, class, race, guild);
			local	addname_clickable = KOH.Name2Clickable(addname);
			KarmaChatDefault(addname_clickable .. KARMA_MSG_ADDMEMBER_ADDED);

			local	oMember = Karma_MemberList_GetObject(sName);
			if (oMember) then
				local	sPlayerFaction, key, value = UnitFactionGroup("player");
				for key, value in pairs(KarmaModuleLocal.ChatRememberList) do
					if ((value.Name == sName) and (value.Faction == sPlayerFaction) and (value.Class == class) and (value.Race == race)) then
						-- value: GUID, Name, Time, Class, ClassEN, Race, RaceEN, Faction, Sex
						oMember[KARMA_DB_L5_RRFFM.GUID] = value.GUID;
						oMember[KARMA_DB_L5_RRFFM.GENDER] = value.Sex;
					end
				end
			end

			found = true;
		end
	end
	if (found == false) then
		if (data.bForce) then
			KarmaChatDefault("No information available. Still adding " .. addname .. " as requested.");
			Karma_MemberList_Add(addname);
			Karma_MemberList_Update(addname);
		else
			KarmaChatDefault(addname .. KARMA_MSG_ADDORIGNMEMBER_OFFLINE);
		end
	end
	if (FriendsFrame:IsVisible()) then
		SetWhoToUI(1);
	else
		SetWhoToUI(0);
	end

	Karma_Executing_Who = nil;
	Karma_Executing_Command = false;
end

function	Karma_Command_UpdateMember_Insert(args)
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "updatemembercheck - " .. args[2], func = Karma_Command_UpdateMember_Start, args = {sName = args[2]}};
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "updatemember completed - " .. args[2], func = Karma_Command_UpdateMembers, args = {}};
end

function	Karma_Command_UpdateMember_Start(args)
	Karma_Executing_Command = true;
	-- Create a who command and send it to the server for processing
	local	whotext = WHO_TAG_NAME.."\""..args.sName.."\""
	Karma_WhoQueue[getn(Karma_WhoQueue)+1] = {func = Karma_UpdateMember_Complete, sName = args.sName, text = whotext};

	Karma_SendWho(whotext);
end

function	Karma_UpdateMember_Complete(addname)
	local	numWhos, totalCount = GetNumWhoResults();
	local	sName, sNameLower, guild, level, race, class, zone, group
	local	i = 0;
	local	found = false;
	for i = 1, totalCount do
		sName, guild, level, race, class, zone, group = GetWhoInfo(i);

		if (KARMA_Online.PlayersAll[sName] == nil) then
			KARMA_Online.PlayersAll[sName] = {};
		end
		KARMA_Online.PlayersAll[sName].time = time();
		KARMA_Online.PlayersAll[sName].zone = zone;
		-- non-members!
		KARMA_Online.PlayersAll[sName].guild = guild;
		KARMA_Online.PlayersAll[sName].level = level;
		KARMA_Online.PlayersAll[sName].class = class;

		KARMA_Online.PlayersVersion = KARMA_Online.PlayersVersion + 1;

		if (sName == addname) then
			-- no adding here, must already be on the list
			Karma_MemberList_Update(sName, level, class, race, guild);
			local	Msg = KOH.Name2Clickable(sName);
			if (guild) and (guild ~= "") then
				Msg = Msg .. " <" .. guild .. ">";
			end
			KarmaChatSecondary(Msg .. KARMA_MSG_UPDATEMEMBER_UPDATED .. Karma_NilToEmptyString(zone));
			found = true;
		end
	end
	if (found == false) and not UnitIsAFK("player") then
		KarmaChatDefault(addname .. KARMA_MSG_UPDATEMEMBER_OFFLINE);
	end
	if (FriendsFrame:IsVisible()) then
		SetWhoToUI(1);
	else
		SetWhoToUI(0);
	end

	Karma_Executing_Who = nil;
	Karma_Executing_Command = false;
end

function	Karma_Command_UpdateMembers(args)
	Karma_MemberList_ResetMemberNamesCache();
	KarmaWindow_Update();
end

function	Karma_Command_CheckOnline_Insert(args)
	local	CmdName = "onlinecheck - " .. args[2];
	if (args[3] ~= nil) then
		CmdName = CmdName .. " ~ " .. args[3];
	end
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = CmdName, func = Karma_Command_CheckOnline_Start, args = {sName = args[2], sClass = args[3]}};
end

function	Karma_Command_CheckOnline_Start(args)
	Karma_Executing_Command = true;

	-- Create a who command and send it to the server for processing
	local	whotext = WHO_TAG_NAME.."\""..args.sName.."\"";
	if (args.sClass ~= nil) then
		whotext = whotext .. " " .. WHO_TAG_CLASS .. args.sClass;
	end

	KarmaChatDebug("Sending " .. whotext);

	Karma_WhoQueue[getn(Karma_WhoQueue)+1] = {func = Karma_CheckOnline_Complete, sName = args.sName, sClass = args.sClass, text = whotext};

	Karma_SendWho(whotext);
end

function	Karma_CheckOnline_Complete(namefrag, classfrag)
	local	numWhos, totalCount = GetNumWhoResults();
	KarmaChatDebug("Results for /who (n-" .. namefrag .. ", c-" .. Karma_NilToEmptyString(classfrag) .. "): " .. totalCount .. ", accessible " .. numWhos);

	local	lMembers = KarmaObj.DB.SF.MemberListGet();

	local	sName, guild, level, race, class, zone, group
	local	i = 0;
	local	found = false;
	local	oMember;
	for i = 1, numWhos do
		sName, guild, level, race, class, zone, group = GetWhoInfo(i);

		if (KARMA_Online.PlayersAll[sName] == nil) then
			KARMA_Online.PlayersAll[sName] = {};
		end
		KARMA_Online.PlayersAll[sName].time = time();
		KARMA_Online.PlayersAll[sName].zone = zone;
		-- non-members!
		KARMA_Online.PlayersAll[sName].guild = guild;
		KARMA_Online.PlayersAll[sName].level = level;
		KARMA_Online.PlayersAll[sName].class = class;

		KARMA_Online.PlayersVersion = KARMA_Online.PlayersVersion + 1;

		oMember = Karma_MemberList_GetObject(sName, nil, lMembers);
		if (oMember ~= nil) then
			Karma_MemberList_Update(sName, level, class, race, guild);
			local	Msg = KOH.Name2Clickable(sName);
			if (guild) and (guild ~= "") then
				Msg = Msg .. " <" .. guild .. ">";
			end
			KarmaChatSecondary(Msg .. KARMA_MSG_UPDATEMEMBER_ONLINE .. Karma_NilToEmptyString(zone));
		end
	end

	if (FriendsFrame:IsVisible()) then
		SetWhoToUI(1);
	else
		SetWhoToUI(0);
	end

	Karma_Executing_Who = nil;
	Karma_Executing_Command = false;
end

function	Karma_Command_CompareClassOnline_Insert(args, races)
	local	CmdName = "classcall - " .. args[2];
	local	params = { sClass = args[2], sRace = args[3], sLevel = args[4] };
	if (args[3] ~= nil) then
		CmdName = CmdName .. " ~ race = " .. args[3];
	end
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = { sName = CmdName, method = Karma_Command_CompareClassOnline_Start, args = params, races = races };
end

function	Karma_Command_CompareClassOnline_Start(oData)
	local	args = oData.args;
	if args.sClass == nil then
		return
	end

	Karma_Executing_Command = true;

	local	sOutput = args.sClass;

	-- Create a who command and send it to the server for processing
	local	whotext = WHO_TAG_CLASS .. args.sClass;
	if (args.sRace ~= nil) then
		sOutput = args.sRace .. "+" .. sOutput;
		whotext = whotext .. " ".. WHO_TAG_RACE .. args.sRace;
	end
	if (args.sLevel ~= nil) then
		sOutput = sOutput .. "(" .. args.sLevel .. ")";
		-- there is no "WHO_TAG_LEVEL"...
		whotext = whotext .. " ".. args.sLevel;
	end

	KarmaChatSecondaryFallbackDefault(KARMA_MSG_CHECKING_FOR .. sOutput .. KARMA_WINEL_FRAG_TRIDOTS);
	KarmaChatDebug("Sending /who " .. whotext .. KARMA_WINEL_FRAG_TRIDOTS);

	Karma_WhoQueue[getn(Karma_WhoQueue)+1] = { method = Karma_Command_CompareClassOnline_Complete, text = whotext, args = args, races = oData.races};

	Karma_SendWho(whotext);
end

function	Karma_Command_CompareClassOnline_Complete(oData)
	local	args = oData.args;
	local	whoclass, whorace, whotext = args.sClass, args.sRace, oData.text;
	local	numWhos, totalCount = GetNumWhoResults();

	KarmaChatDebug("Results for /who " .. Karma_NilToString(whotext) .. KARMA_WINEL_FRAG_COLONSPACE .. totalCount .. ", accessible " .. numWhos);
	if (numWhos > 0) then
		local whoargs = whoclass;
		if (whorace) then
			whoargs = whorace .. "+" .. whoargs;
		end
		local	Msg = KARMA_MSG_WHORESULT_1 .. whoargs .. KARMA_MSG_WHORESULT_2 .. tostring(totalCount) .. KARMA_MSG_WHORESULT_3;
		if (numWhos == 50) then
			Msg = Msg .. KARMA_MSG_WHORESULT_4;
		end
		KarmaChatSecondaryFallbackDefault(Msg);
	end

	local	lMembers = KarmaObj.DB.SF.MemberListGet();

	local	sName, guild, level, race, class, zone, group
	local	i = 0;
	local	found = false;
	local	oMember;
	for i = 1, numWhos do
		sName, guild, level, race, class, zone, group = GetWhoInfo(i);

		if (KARMA_Online.PlayersAll[sName] == nil) then
			KARMA_Online.PlayersAll[sName] = {};
		end
		KARMA_Online.PlayersAll[sName].time = time();
		KARMA_Online.PlayersAll[sName].zone = zone;
		-- non-members!
		KARMA_Online.PlayersAll[sName].guild = guild;
		KARMA_Online.PlayersAll[sName].level = level;
		KARMA_Online.PlayersAll[sName].class = class;

		KARMA_Online.PlayersVersion = KARMA_Online.PlayersVersion + 1;

		oMember = Karma_MemberList_GetObject(sName, nil, lMembers);
		if (oMember ~= nil) then
			local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
			if (bModified) then
				iKarma = "*" .. iKarma;
			end
			Karma_MemberList_Update(sName, level, class, race, guild);
			local	sNameClickable = KOH.Name2Clickable(sName);
			KarmaChatSecondary(sNameClickable .. "{" .. iKarma .. "} " .. KARMA_MSG_UPDATEMEMBER_ONLINE .. Karma_NilToEmptyString(zone));
		end
	end

	if (numWhos == 50) then
		if ((whorace == nil) and (type(oData.races) == "table")) then
			local	argswithrace = {};
			argswithrace[2] = args.sClass;
			argswithrace[4] = args.sLevel;
			local	k, v;
			for k, v in pairs(oData.races) do
				argswithrace[3] = v;
				Karma_Command_CompareClassOnline_Insert(argswithrace);
			end
		elseif (whorace and args.sLevel and (args.sLevel ~= "80")) then
			local	sFrom, sTo = string.match(args.sLevel, "(%d+)%-(%d+)");
			if (sFrom and sTo) then
				local	iFrom, iTo = tonumber(sFrom), tonumber(sTo);
				if (iFrom and iTo and (iFrom ~= iTo)) then
					local	argswithrace = {};
					argswithrace[2] = args.sClass;
					argswithrace[3] = whorace;

					local	iMiddle = math.ceil((iFrom + iTo) / 2);
					if (iTo == KARMA_MAXLEVEL) then
						-- split off max level first, this will almost always overflow
						iMiddle = KARMA_MAXLEVEL;
					end

					if ((iMiddle - 1) > iFrom) then
						argswithrace[4] = iFrom .. "-" .. (iMiddle - 1);
					else
						argswithrace[4] = iFrom;
					end
					Karma_Command_CompareClassOnline_Insert(argswithrace);
					if (iMiddle ~= iTo) then
						argswithrace[4] = iMiddle .. "-" .. iTo;
					else
						argswithrace[4] = iTo;
					end
					Karma_Command_CompareClassOnline_Insert(argswithrace);
				end
			end
		end
	end

	if (FriendsFrame:IsVisible()) then
		SetWhoToUI(1);
	else
		SetWhoToUI(0);
	end

	Karma_Executing_Who = nil;
	Karma_Executing_Command = false;
end

function	Karma_Command_CompareGuildOnline_Insert(args)
	Karma_CommandQueue[getn(Karma_CommandQueue)+1] = {sName = "guildcall", func = Karma_Command_CompareGuildOnline_Start, args = args };
end

function	Karma_Command_CompareGuildOnline_Start(args)
	Karma_Executing_Command = true;

	-- Create a who command and send it to the server for processing
	args[1] = "";
	local	whotext = WHO_TAG_GUILD .. "\"" .. strsub(table.concat(args, " "), 2) .. "\"";
	KarmaChatDebug("Sending /who " .. whotext .. KARMA_WINEL_FRAG_TRIDOTS);
	KarmaChatSecondaryFallbackDefault(KARMA_MSG_CHECKING_FOR .. "<" .. strsub(whotext, 4, strlen(whotext) - 1) .. ">" .. KARMA_WINEL_FRAG_TRIDOTS);

	Karma_WhoQueue[getn(Karma_WhoQueue)+1] = {func = Karma_Command_CompareGuildOnline_Complete, text = whotext};

	Karma_SendWho(whotext);
end

function	Karma_Command_CompareGuildOnline_Complete(whoname, whoclass, whorace, whotext)
	local	numWhos, totalCount = GetNumWhoResults();

	KarmaChatDebug("Results for /who " .. whotext .. KARMA_WINEL_FRAG_COLONSPACE .. totalCount .. ", accessible " .. numWhos);
	if (numWhos > 0) then
		local	Msg = KARMA_MSG_WHORESULT_1 .. "<" .. strsub(whotext, 4, strlen(whotext) - 1) .. ">" .. KARMA_MSG_WHORESULT_2 .. tostring(totalCount) .. KARMA_MSG_WHORESULT_3;
		if (numWhos == 50) then
			Msg = Msg .. KARMA_MSG_WHORESULT_4;
		end
		KarmaChatSecondaryFallbackDefault(Msg);
	end

	local	lMembers = KarmaObj.DB.SF.MemberListGet();

	local	sName, guild, level, race, class, zone, group
	local	i = 0;
	local	found = false;
	local	oMember;
	for i = 1, numWhos do
		sName, guild, level, race, class, zone, group = GetWhoInfo(i);

		if (KARMA_Online.PlayersAll[sName] == nil) then
			KARMA_Online.PlayersAll[sName] = {};
		end
		KARMA_Online.PlayersAll[sName].time = time();
		KARMA_Online.PlayersAll[sName].zone = zone;
		-- non-members!
		KARMA_Online.PlayersAll[sName].guild = guild;
		KARMA_Online.PlayersAll[sName].level = level;
		KARMA_Online.PlayersAll[sName].class = class;

		KARMA_Online.PlayersVersion = KARMA_Online.PlayersVersion + 1;

		oMember = Karma_MemberList_GetObject(sName, nil, lMembers);
		if (oMember ~= nil) then
			local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
			if (bModified) then
				iKarma = "*" .. iKarma;
			end
			Karma_MemberList_Update(sName, level, class, race, guild);
			local	sNameClickable = KOH.Name2Clickable(sName);
			KarmaChatSecondary(sNameClickable .. "{" .. iKarma .. "} " .. KARMA_MSG_UPDATEMEMBER_ONLINE .. Karma_NilToEmptyString(zone));
		end
	end

	if (FriendsFrame:IsVisible()) then
		SetWhoToUI(1);
	else
		SetWhoToUI(0);
	end

	Karma_Executing_Who = nil;
	Karma_Executing_Command = false;
end


local function WhoUpdateShowKarmaAndNote()
	if (GetNumWhoResults() == 1) then
		local	sName, guild, level, race, class, zone, group = GetWhoInfo(1);
		if (KarmaModuleLocal.WhoInfoOnlyOnce_Char ~= sName) then
			KarmaModuleLocal.WhoInfoOnlyOnce_Char = sName;

			local	lMembers = KarmaObj.DB.SF.MemberListGet();
			local	sBucketName = KarmaObj.NameToBucket(sName);
			if (lMembers[sBucketName][sName] ~= nil) then
				Karma_MemberList_Update(sName, level, class, race, guild);
				local	oMember = Karma_MemberList_GetObject(sName);
				local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
				if (bModified) then
					iKarma = "*" .. iKarma;
				end
				local	sNameClickable = KOH.Name2Clickable(sName);
				local	sSkill = Karma_MemberObject_GetSkillText(oMember);
				if (sSkill) then
					sSkill = "\n-> Skill: " .. sSkill;
				else
					sSkill = "";
				end
				local	sNote = Karma_MemberObject_GetNotes(oMember);
				if sNote and (sNote ~= "") then
					local	sExtract = KarmaModuleLocal.Helper.ExtractHeader(sNote);
					KarmaChatSecondary(KARMA_MSG_WHOCATCHED_GOTNOTES .. sNameClickable .. "{" .. iKarma .. "}:" .. sSkill .. "\n" .. sExtract);
				else
					KarmaChatSecondary(KARMA_MSG_WHOCATCHED_NONOTES .. sNameClickable .. "{" .. iKarma .. "}" .. sSkill .. ".");
				end
			else
				KarmaChatDebug(sName .. KARMA_MSG_UNKNOWN);
			end
		else
			KarmaChatDebug("Note already showed for this char.");
		end
	elseif (GetNumWhoResults() > 0) then
		KarmaChatDebug("Multiple /who results.");
	end
end

function	Karma_Who_Update(event, ...)
	if (KARMA_WhoRequestIsMine ~= 1) then
		return
	end

	KARMA_WhoRequestIsMine = 0;

	if (event ~= nil) then
		KarmaChatDebug("Karma_Who_Update: " .. event);
	end

	if (#Karma_WhoQueue == 0) then
		if (KARMA_Original_Who_Update ~= nil) then
			KARMA_Original_Who_Update(event, ...);
		end;
		WhoUpdateShowKarmaAndNote();
		return
	end

	Karma_Who_Process();
end

function	Karma_Who_Process()
	local	elem = Karma_WhoQueue[1];
	local	i;
	if (#Karma_WhoQueue > 1) then
		for i = 2, #Karma_WhoQueue do
			Karma_WhoQueue[i - 1] = Karma_WhoQueue[i];
		end
		Karma_WhoQueue[#Karma_WhoQueue] = nil;
	else
		Karma_WhoQueue = {};
	end

	if (type(elem.method) == "function") then
		elem:method();
	elseif (type(elem.func) == "function") then
		elem.func(elem.sName, elem.sClass, elem.sRace, elem.text);
	end

	WhoUpdateShowKarmaAndNote();
end

-----------------------------------------
-- Invite patch
-----------------------------------------

function	Karma_AutoIgnore_Invites(event)
	if (Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE) ~= 1) or
	   (Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE_INVITES) ~= 1) then
		return;
	end

	local	oMember = Karma_MemberList_GetObject(arg1);
	if (oMember == nil) then
		return;
	end

	local	karma = Karma_MemberObject_GetKarma(oMember);
	local	threshold = tonumber(Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE_THRESHOLD));
	if (karma > threshold) then
		return;
	end

	local	Msg = arg1 .. " (" .. karma .. KARMA_MSG_AUTOIGNORE_2 .. threshold .. KARMA_MSG_AUTOIGNORE_3;
	if (event == "GUILD_INVITE_REQUEST") then
		KarmaChatDefault(KARMA_MSG_AUTOIGNORE_GUILD .. Msg);
		DeclineGuild();
		StaticPopup_Hide("GUILD_INVITE");

		return;
	end

	if (event == "PARTY_INVITE_REQUEST") then
		KarmaChatDefault(KARMA_MSG_AUTOIGNORE_PARTY .. Msg);
		DeclineGroup();
		StaticPopup_Hide("PARTY_INVITE");

		return;
	end

	if (event == "TRADE_REQUEST") then
		KarmaChatDefault(KARMA_MSG_AUTOIGNORE_TRADE .. Msg);
		CancelTrade();
		StaticPopup_Hide("TRADE");

		return;
	end

	if (event == "DUEL_REQUESTED") then
		KarmaChatDefault(KARMA_MSG_AUTOIGNORE_DUEL .. Msg);
		CancelDuel();
		StaticPopup_Hide("DUEL_REQUESTED");

		return;
	end
end

-----------------------------------------
-- CHAT FUNCTIONS -- NEW METHOD ---------
-----------------------------------------

function	KarmaModuleLocal.ChatRememberStore(sName, sGUID, sMsg)
	local	iNow = time();
	local	iOldestIndex, iOldestTime = 0, -1;
	local	key, value;
	for key, value in pairs(KarmaModuleLocal.ChatRememberList) do
		if (value.GUID == sGUID) then
			if ((value.Message ~= sMsg) or (iNow - value.Time > 5)) then
				KOH.TableInit(value, "Messages");
				local	iCnt, i = #value.Messages;
				if (iCnt < 3) then
					iCnt = iCnt + 1;
					value.Messages[iCnt] = { Message = sMsg, At = iNow };
				else
					for i = 1, 2 do
						value.Messages[i] = value.Messages[i + 1];
					end
					value.Messages[3] = { Message = sMsg, At = iNow };
				end
			end

			value.Message = sMsg;
			value.Time = iNow;
			return;
		end

		if ((iOldestTime == -1) or (value.Time < iOldestTime)) then
			iOldestIndex = key;
			iOldestTime = value.Time;
		end
	end

	-- not yet in storage. add
	if (KarmaModuleLocal.ChatRememberList[KarmaModuleLocal.ChatRememberCount] == nil) then
		KarmaModuleLocal.ChatRememberIndex = KarmaModuleLocal.ChatRememberIndex + 1;
		if (KarmaModuleLocal.ChatRememberIndex == KarmaModuleLocal.ChatRememberCount + 1) then
			KarmaModuleLocal.ChatRememberIndex = 1;
		end
	else
		-- drop oldest
		KarmaModuleLocal.ChatRememberIndex = iOldestIndex;
	end

	KarmaModuleLocal.ChatRememberList[KarmaModuleLocal.ChatRememberIndex] = {};
	local	Value = KarmaModuleLocal.ChatRememberList[KarmaModuleLocal.ChatRememberIndex];
	Value.GUID = sGUID;
	Value.Name = sName;
	Value.Time = iNow;

	local	localizedClass, englishClass, localizedRace, englishRace, sex = GetPlayerInfoByGUID(sGUID);
	Value.Class = localizedClass;
	Value.ClassEN = englishClass;
	Value.Race = localizedRace;
	Value.RaceEN = englishRace;

	local	sRace, k, v = strupper(englishRace);
	for k, v in pairs(KARMA_RACES_ALLIANCE_LOCALIZED) do
		if (sRace == strsub(k, 5)) then
			Value.Faction = "Alliance";
			break
		end
	end
	for k, v in pairs(KARMA_RACES_HORDE_LOCALIZED) do
		if (sRace == strsub(k, 5)) then
			Value.Faction = "Horde";
			break
		end
	end

	Value.Sex = sex;
end

KarmaModuleLocal.ChatFilters["CHAT_MSG_SYSTEM"] = {	bRedo = false	};

KarmaModuleLocal.ChatFilters["CHAT_MSG_SYSTEM"].fFilter = function(ChatFrameSelf, event, ...)
	local	arg1 = ...;

	KarmaChatDebug("System MSG: <" .. arg1 .. ">.");

	do
		-- what does INVITATION represent? old baggage?
		-- "|Hplayer:%%s|h%[%%s%]|h" => "|Hplayer:[^|]+|h%[(.+)%]|h"
		local	sPattern = string.gsub(ERR_INVITED_TO_GROUP_SS, "|Hplayer:%%s|h%[%%s%]|h", "|Hplayer:[^|]+|h%%[(.+)%%]|h");
		local	sName = string.match(arg1, sPattern);
		if (sName) then
			KarmaChatDebug("|cFF8080FFInvite to group by " .. sName .. ".|r");
			KarmaObj.DB.I24.Add(sName, nil, "INVITE", "INVITE_A", nil);
		end
	end

	do
		local	sPattern = string.gsub(ERR_INVITED_ALREADY_IN_GROUP_SS, "|Hplayer:%%s|h%[%%s%]|h", "|Hplayer:[^|]+|h%%[(.+)%%]|h");
		local	sName = string.match(arg1, sPattern);
		if (sName) then
			KarmaChatDebug("|cFF8080FFFailed invite to group by " .. sName .. ".|r");
			KarmaObj.DB.I24.Add(sName, nil, "INVITE", "INVITE_B", nil);
		end
	end

	return false;
end

KarmaModuleLocal.ChatFilters["CHAT_MSG_CHANNEL_LIST"] = {	bRedo = false	};

KarmaModuleLocal.ChatFilters["CHAT_MSG_CHANNEL_LIST"].fFilter = function(ChatFrameSelf, event, ...)
	local	arg1, arg2, arg3, arg4 = ...;
	if (KARMA_Online.ChannelName) then
		-- larger channels can take more than 5s!
		if (time() > KARMA_Online.ChannelTime + 10) then
			KARMA_Online.ChannelTime = 0;
			KARMA_Online.ChannelName = nil;
		else
			local	isChannel = false;
			if (type(KARMA_Online.ChannelName) == "number") then
				-- by number
				local	iChannel = tonumber(strsub(arg4, 1, 1));
				if (iChannel == KARMA_Online.ChannelName) then
					isChannel = true;
				end
			else
				-- by name: compensate e.g. "General - Stormwind City" by cutting at first space
				local	sChannel = strsub(arg4, 4);
				local	iPosSpace = strfind(sChannel, " ", 1, true);
				if (iPosSpace) then
					sChannel = strsub(sChannel, 1, iPosSpace - 1);
				end
				if (sChannel == KARMA_Online.ChannelName) then
					isChannel = true;
				end
			end

			if (isChannel) then
				KarmaChatDebug("ChannelList to <" .. strsub(arg4, 4) .. ">: {" .. arg1 .. "}");
				Karma_CheckOnlineInChannelResults(" " .. arg1 .. ",");
				return true;
			else
				KarmaChatDebug("ChannelList to <" .. strsub(arg4, 4) .. ">: {" .. arg1 .. "} (probably not by Karma)");
			end
		end
	end

	return false;
end

KarmaModuleLocal.ChatFilters.fChannelFilter = function(ChatFrameSelf, event, ...)
	local	arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12 = ...;

	Karma_WhoAmIInit();
	if (arg2 == WhoAmI) then
		return false;
	end

	if (arg12 and (arg12 ~= "")) then
		KarmaModuleLocal.ChatRememberStore(arg2, arg12, arg1);
		if (event == "CHAT_MSG_WHISPER") then
			KarmaObj.DB.I24.Add(arg2, arg12, event, arg1);
		end
	end

	if (not Karma_GetConfig(KARMA_CONFIG.MARKUP_ENABLED)) then
		return false;
	end

	local	sConfig;
	local	oEvent = KarmaModuleLocal.ChatFilters[event];
	if (oEvent and oEvent.sConfig) then
		sConfig = oEvent.sConfig;
	end
	if (sConfig and Karma_GetConfig(sConfig) or (Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE) == 1)) then
		local	oMember = Karma_MemberList_GetObject(arg2);
		if (oMember == nil) then
			return false;
		end

		local	karma = Karma_MemberObject_GetKarma(oMember);
		local	threshold = tonumber(Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE_THRESHOLD));
		if (karma <= threshold) then
			-- ignore by threshold
			return true;
		end

		-- Markup: by overwriting GetColoredName()
		if (Karma_GetConfig(KARMA_CONFIG.MARKUP_VERSION) >= 3) then
			return false;
		end

		-- Markup: self-made
		if ((type(ChatFrameSelf) == "table") and (type(ChatFrameSelf.GetName) == "function")) then
			-- if it ias a valid frame: WIM fails to provide AddMessage, so we can't return true, because we didn't output anything
			local	sFramename = ChatFrameSelf:GetName();
			if ((type(sFramename) == "string") and (strsub(sFramename, 1, 9) == "ChatFrame")) then
				KarmaModuleLocal.ChatFilters.DefaultOutput(oMember, ChatFrameSelf, event, ...);
				return true;
			end

			KarmaChatDebug("Invalid self in fChannelFilter for event " .. event .. ": " .. Karma_NilToString(sFramename));
		end
	end

	return false;
end

KarmaModuleLocal.ChatFilters["CHAT_MSG_CHANNEL"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_CHANNELS	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_CHANNEL"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;

KarmaModuleLocal.ChatFilters["CHAT_MSG_SAY"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_YELLSAYEMOTE	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_SAY"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;
KarmaModuleLocal.ChatFilters["CHAT_MSG_YELL"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_YELLSAYEMOTE	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_YELL"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;
KarmaModuleLocal.ChatFilters["CHAT_MSG_EMOTE"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_YELLSAYEMOTE	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_EMOTE"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;
KarmaModuleLocal.ChatFilters["CHAT_MSG_TEXT_EMOTE"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_YELLSAYEMOTE	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_TEXT_EMOTE"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;

KarmaModuleLocal.ChatFilters["CHAT_MSG_BATTLEGROUND"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_BG	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_BATTLEGROUND"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;
KarmaModuleLocal.ChatFilters["CHAT_MSG_BATTLEGROUND_LEADER"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_BG	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_BATTLEGROUND_LEADER"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;

KarmaModuleLocal.ChatFilters["CHAT_MSG_GUILD"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_GUILD	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_GUILD"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;
KarmaModuleLocal.ChatFilters["CHAT_MSG_OFFICER"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_GUILD	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_OFFICER"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;

KarmaModuleLocal.ChatFilters["CHAT_MSG_PARTY"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_RAID	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_PARTY"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;

KarmaModuleLocal.ChatFilters["CHAT_MSG_RAID"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_RAID	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_RAID"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;
KarmaModuleLocal.ChatFilters["CHAT_MSG_RAID_LEADER"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_RAID	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_RAID_LEADER"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;

KarmaModuleLocal.ChatFilters["CHAT_MSG_WHISPER"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_WHISPER	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_WHISPER"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;
KarmaModuleLocal.ChatFilters["CHAT_MSG_DND"] = {	bRedo = true, sConfig = KARMA_CONFIG.MARKUP_WHISPER	};
KarmaModuleLocal.ChatFilters["CHAT_MSG_DND"].fFilter = KarmaModuleLocal.ChatFilters.fChannelFilter;

function	KarmaModuleLocal.ChatFilters.MarkupSender(sSender, oMember)
	local	sMarkup = sSender;

	if (Karma_GetConfig(KARMA_CONFIG.MARKUP_COLOUR_NAME) and (sSender ~= "")) then
		local	sClassWOGender = Karma_MemberObject_GetClassWOGender(oMember);
		if (sClassWOGender and (sClassWOGender ~= "")) then
			local	iRed, iGreen, iBlue = Karma_ClassMToColor(sClassWOGender);
			sMarkup = format("|c%s%s|r", ColourToString(1, iRed, iGreen, iBlue), sMarkup);
		end
	end

	local	sKarma = "";
	if (Karma_GetConfig(KARMA_CONFIG.MARKUP_SHOW_KARMA)) then
		local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
		if (iKarma ~= 50) then
			iKarma = math.min(iKarma, 100);
			if (bModified) then
				bModified = "*";
			else
				bModified = "";
			end

			if (Karma_GetConfig(KARMA_CONFIG.MARKUP_COLOUR_KARMA)) then
				local	iRed, iGreen, iBlue = Karma_Karma2Color(iKarma);
				sKarma = format(" {|c%s%s%s|r}", ColourToString(1, iRed, iGreen, iBlue), bModified, iKarma);
			else
				sKarma = format(" {%s%s}", bModified, iKarma);
			end
		end
	end
	sMarkup = sMarkup .. sKarma

	local	sNotes = Karma_MemberObject_GetNotes(oMember);
	if (sNotes) and (sNotes ~= "") then
		sMarkup = sMarkup .. "+";
	end

	return sMarkup;
end

function	KarmaModuleLocal.ChatFilters.DefaultOutput(oMember, self, event, ...)
	local	arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11 = ...;

	local type = strsub(event, 10);
	local info = ChatTypeInfo[type];
	local channelLength = strlen(arg4);

	-- whee, the check if there is *actually* something to be displayed is made *AFTER* the filters...
	-- what a braindamaged nonsense. *sigh*
	if ( (strsub(type, 1, 7) == "CHANNEL") and (type ~= "CHANNEL_LIST") and ((arg1 ~= "INVITE") or (type ~= "CHANNEL_NOTICE_USER")) ) then
		if ( arg1 == "WRONG_PASSWORD" ) then
			local staticPopup = _G[StaticPopup_Visible("CHAT_CHANNEL_PASSWORD") or ""];
			if ( staticPopup and staticPopup.data == arg9 ) then
				-- Don't display invalid password messages if we're going to prompt for a password (bug 102312)
				return;
			end
		end

		local found = 0;
		for index, value in pairs(self.channelList) do
			if ( channelLength > strlen(value) ) then
				-- arg9 is the channel name without the number in front...
				if ( ((arg7 > 0) and (self.zoneChannelList[index] == arg7)) or (strupper(value) == strupper(arg9)) ) then
					found = 1;
					info = ChatTypeInfo["CHANNEL"..arg8];
					if ( (type == "CHANNEL_NOTICE") and (arg1 == "YOU_LEFT") ) then
						self.channelList[index] = nil;
						self.zoneChannelList[index] = nil;
					end
					break;
				end
			end
		end
		if ( (found == 0) or not info ) then
			return;
		end
	end

	if ( type == "TEXT_EMOTE" ) then
		self:AddMessage(arg1, info.r, info.g, info.b, info.id);
	else
		-- channel is active for current frame, do the output

		-- stripped fontHeight (unused), moved body, renamed coloredName as sSenderMarkedup and moved

		-- Add AFK/DND flags
		local pflag;
		if(strlen(arg6) > 0) then
			if ( arg6 == "GM" ) then
				--If it was a whisper, dispatch it to the GMChat addon.
				if ( type == "WHISPER" ) then
					return
				end

				--Add Blizzard Icon, this was sent by a GM
				pflag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:0:2:0:-3|t ";
			else
				pflag = _G["CHAT_FLAG_"..arg6];
			end
		else
			pflag = "";
		end
		if ( type == "WHISPER_INFORM" and GMChatFrame_IsGM and GMChatFrame_IsGM(arg2) ) then
			return
		end

		local showLink = 1;
		if ( strsub(type, 1, 7) == "MONSTER" or strsub(type, 1, 9) == "RAID_BOSS") then
			showLink = nil;
		else
			arg1 = gsub(arg1, "%%", "%%%%");
		end

		-- Search for icon links and replace them with texture links.
		if ( arg7 < 1 or ( arg7 >= 1 and CHAT_SHOW_ICONS ~= "0" ) ) then
			local term;
			for tag in string.gmatch(arg1, "%b{}") do
				term = strlower(string.gsub(tag, "[{}]", ""));
				if ( ICON_TAG_LIST[term] and ICON_LIST[ICON_TAG_LIST[term]] ) then
					arg1 = string.gsub(arg1, tag, ICON_LIST[ICON_TAG_LIST[term]] .. "0|t");
				end
			end
		end

		local	sSenderMarkedup = KarmaModuleLocal.ChatFilters.MarkupSender(arg2, oMember);
		local body;

		if ( (strlen(arg3) > 0) and (arg3 ~= "Universal") and (arg3 ~= self.defaultLanguage) ) then
			local languageHeader = "["..arg3.."] ";
			if ( showLink and (strlen(arg2) > 0) ) then
				body = format(_G["CHAT_"..type.."_GET"]..languageHeader..arg1, pflag.."|Hplayer:"..arg2..":"..arg11.."|h".."["..sSenderMarkedup.."]".."|h");
			else
				KarmaChatDebug("Type " .. type .. ": arg2 <> MARKUP? (1)");
				body = format(_G["CHAT_"..type.."_GET"]..languageHeader..arg1, pflag..arg2);
			end
		else
			if ( showLink and (strlen(arg2) > 0) and (type ~= "EMOTE") ) then
				body = format(_G["CHAT_"..type.."_GET"]..arg1, pflag.."|Hplayer:"..arg2..":"..arg11.."|h".."["..sSenderMarkedup.."]".."|h");
			elseif ( showLink and (strlen(arg2) > 0) and (type == "EMOTE") ) then
				body = format(_G["CHAT_"..type.."_GET"]..arg1, pflag.."|Hplayer:"..arg2..":"..arg11.."|h"..sSenderMarkedup.."|h");
			else
				KarmaChatDebug("Type " .. type .. ": arg2 <> MARKUP? (2)");
				body = format(_G["CHAT_"..type.."_GET"]..arg1, pflag..arg2, arg2);
			end
		end

		-- Add Channel
		arg4 = gsub(arg4, "%s%-%s.*", "");
		if(channelLength > 0) then
			body = "|Hchannel:"..arg8.."|h["..arg4.."]|h "..body;
		end

		self:AddMessage(body, info.r, info.g, info.b, info.id);

		if ( type == "WHISPER" ) then
			ChatEdit_SetLastTellTarget(arg2);
			if ( self.tellTimer and (GetTime() > self.tellTimer) ) then
				PlaySound("TellMessage");
			end
			self.tellTimer = GetTime() + CHAT_TELL_ALERT_TIME;
			FCF_FlashTab(self);
		end
	end
end

-----------------------------------------
-- CHAT FUNCTIONS -- OLD METHOD ---------
-----------------------------------------

function	Karma_ChatFrame_OnEvent(self, event, ...)
	-- KarmaChatDebug("Karma_ChatFrame_OnEvent: event = [" .. event .. "]");

	local	_type = type;		-- really weird overwriting of elementary function in original Blizzard code...
	local	arg1, arg2, arg3, arg4 = ...;

	if (event == "CHAT_MSG_SYSTEM") and (arg1 ~= nil) and (GetNumWhoResults() == 1) then
		-- undocumented(?) who-reply: arg1 comes as: "|Hplayer:ABCDE[ABCDE]"
		if (strsub(arg1, 1, 9) == "|Hplayer:") then
			local sMemberName = strsub(arg1, 10);
			local openingbracket = strfind(sMemberName, "[", 1, true);
			if (openingbracket) then
				sMemberName = strsub(sMemberName, openingbracket + 1);
				local closingbracket = strfind(sMemberName, "]", 1, true);
				if (closingbracket) then
					sMemberName = strsub(sMemberName, 1, closingbracket - 1);
					KarmaChatDebug("Potential /who <" .. sMemberName .. "> spotted!");
					WhoUpdateShowKarmaAndNote();
				end
			end
		end

		return KARMA_OriginalChatFrame_OnEvent(self, event, ...);
	end

	if (strsub(event, 1, 8) == "CHAT_MSG") then
		local	type = strsub(event, 10);
		local	info = ChatTypeInfo[type];

		local	channelLength = strlen(arg4);
		if ((strsub(type, 1, 7) == "CHANNEL") and (type ~= "CHANNEL_LIST") and (type ~= "CHANNEL_NOTICE")) then
			if (Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE) == 1) then
				local	oMember = Karma_MemberList_GetObject(arg2);
				if (oMember == nil) then
					KARMA_OriginalChatFrame_OnEvent(self, event, ...);
				else
					local	karma = Karma_MemberObject_GetKarma(oMember);
					local	threshold = tonumber(Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE_THRESHOLD));
					if (karma <= threshold) then
						-- ignore else do the normal thing
					else
						Karma_HandleMarkup(self, event, ...);
					end
				end
			else
				Karma_HandleMarkup(self, event, ...);
			end

			return;
		end

		if     (type == "SYSTEM") then
			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		elseif (type == "TEXT_EMOTE") or (type == "SKILL") or (type == "LOOT") then
			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		elseif (strsub(type, 1, 7) == "COMBAT_") then
			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		elseif (strsub(type, 1, 6) == "SPELL_") then
			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		elseif (type == "IGNORED") then
			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		elseif (type == "CHANNEL_LIST") then
			if (time() > KARMA_Online.ChannelTime + 10) then
				KARMA_Online.ChannelTime = 0;
				KARMA_Online.ChannelName = nil;
			else
				local	isChannel = false;
				if (_type(KARMA_Online.ChannelName) == "number") then
					-- by number
					local	iChannel = tonumber(strsub(arg4, 1, 1));
					if (iChannel == KARMA_Online.ChannelName) then
						isChannel = true;
					end
				else
					-- by name: compensate e.g. "General - Stormwind City" by cutting at first space
					local	sChannel = strsub(arg4, 4);
					local	iPosSpace = strfind(sChannel, " ", 1, true);
					if (iPosSpace) then
						sChannel = strsub(sChannel, 1, iPosSpace - 1);
					end
					if (sChannel == KARMA_Online.ChannelName) then
						isChannel = true;
					end
				end

				if (isChannel) then
					KarmaChatDebug("ChannelList to <" .. strsub(arg4, 4) .. ">: {" .. arg1 .. "}");
					Karma_CheckOnlineInChannelResults(" " .. arg1 .. ",");
					return;
				else
					KarmaChatDebug("ChannelList to <" .. strsub(arg4, 4) .. ">: {" .. arg1 .. "} (probably not by Karma)");
				end
			end

			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
-- handled above
--		elseif (type == "CHANNEL_NOTICE_USER") then
--			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		elseif (type == "CHANNEL_NOTICE") then
			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		elseif (type == "TRADESKILLS") then		-- perceived
			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
--		elseif (type == "SPELL_TRADESKILLS") then
--			KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		else
			if (Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE) == 1) then
				local	oMember = Karma_MemberList_GetObject(arg2);
				if (oMember == nil) then
					KARMA_OriginalChatFrame_OnEvent(self, event, ...);
				else
					local	karma = Karma_MemberObject_GetKarma(oMember);
					local	threshold = tonumber(Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE_THRESHOLD));
					if (karma <= threshold) then
						-- ignore else do the normal thing
					else
						Karma_HandleMarkup(self, event, ...);
					end
				end
			else
				Karma_HandleMarkup(self, event, ...);
			end
		end

		return;
	else
		KARMA_OriginalChatFrame_OnEvent(self, event, ...);
	end
end

function	Karma_HandleMarkup(self, event, ...)
	if (not Karma_GetConfig(KARMA_CONFIG.MARKUP_ENABLED)) then
		return KARMA_OriginalChatFrame_OnEvent(self, event, ...);
	end

	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11 = ...;
	if ((arg2 == nil) or (arg2 == "")) then
		KarmaChatDebug("Unexpected event without sender: " .. event);
		KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		return
	end

	local	sMsg, sSender, sChan, sStatus, sChatIndex, sChatNoNum = arg1, arg2, arg4, arg6, arg7, arg9;
	local	tMemberlist = KarmaObj.DB.SF.MemberListGet();
	local	sSenderStatus = "";

	local	i = strfind(sSender, "-");	-- Got to handle cross server BG
	if (i) then
		sSender = strsub(sSender, 1, i - 1);
	end

	--KarmaChatDebug("Event from "..sSender..","..arg2);
	local	sBucket = KarmaObj.NameToBucket(sSender);
	if (tMemberlist[sBucket][sSender] == nil) then
		return KARMA_OriginalChatFrame_OnEvent(self, event, ...);
	end

	if (strlen(sStatus) > 0) then
		sSenderStatus = TEXT(getglobal("CHAT_FLAG_" .. sStatus));
		if sSenderStatus == nil then
			KarmaChatDebug("sSenderStatus == nil (setting to \"\" from sStatus = " .. sStatus);
			sSenderStatus = "";
		end
	end

	if	(event == "CHAT_MSG_WHISPER") then
		if (Karma_GetConfig(KARMA_CONFIG.MARKUP_WHISPERS)) then
			local	sBody = sSenderStatus .. Karma_MarkupSender(sSender) .. KARMA_MSG_MARKUP_WHISPER .. sMsg;
			local	oInfo = ChatTypeInfo["WHISPER"];

			self:AddMessage(sBody, oInfo.r, oInfo.g, oInfo.b, oInfo.id);

			ChatEdit_SetLastTellTarget(arg2);

			if (self.tellTimer and (GetTime() > self.tellTimer)) then
				PlaySound("TellMessage");
			end
			self.tellTimer = GetTime() + CHAT_TELL_ALERT_TIME;
			FCF_FlashTab(self);	-- flashes title of tab on window if hidden
		else
			return KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		end
	elseif	((event == "CHAT_MSG_CHANNEL") and
			(sSender ~= UnitName("player"))) then
		-- skip if message starts with "<GEM" (GEM 2.x), "GEM3" (GEM 3.x) or "§" (Karma's own stuff)
		if (strsub(sMsg, 1, 4) == "<GEM") or (strsub(sMsg, 1, 4) == "GEM3") or (strsub(sMsg, 1, 2) == "§") then
			return KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		end

		if (Karma_GetConfig(KARMA_CONFIG.MARKUP_CHANNELS)) then
			local	sChanName = gsub(sChan, "%s%-%s.*", ""); -- cribbed from ChatFrame.lua
			local	iFound = 0;
			local	oInfo;
			for index, value in pairs(self.channelList) do
				if ( ((sChatIndex > 0) and (self.zoneChannelList[index] == sChatIndex)) or (strupper(value) == strupper(sChatNoNum)) ) then
					iFound = 1;
					oInfo = ChatTypeInfo["CHANNEL"..arg8];
					if ( (type == "CHANNEL_NOTICE") and (sMsg == "YOU_LEFT") ) then
						self.channelList[index] = nil;
						self.zoneChannelList[index] = nil;
					end
					break;
				end
			end

			if ((iFound == 0) or not oInfo) then
				return KARMA_OriginalChatFrame_OnEvent(self, event, ...);
			end

			local	sBody = sSenderStatus .."[" .. sChanName .. "] " .. Karma_MarkupSender(sSender) .. KARMA_MSG_MARKUP_CHANNEL .. sMsg;

			self:AddMessage(sBody, oInfo.r, oInfo.g, oInfo.b, oInfo.id);
		else
			return KARMA_OriginalChatFrame_OnEvent(self, event, ...);
		end
	else
		return KARMA_OriginalChatFrame_OnEvent(self, event, ...);
	end
end

function	Karma_MarkupSender(sName)
	local	oMember = Karma_MemberList_GetObject(sName);
	if (not oMember) then
		return sName;
	end

	local	sMarkup = "";
	local	iRed, iGreen, iBlue
	iRed, iGreen, iBlue = Karma_MemberList_GetColors(Karma_MemberObject_GetName(oMember));

	if (Karma_GetConfig(KARMA_CONFIG.MARKUP_COLOUR_NAME)) then
		sMarkup = format(TEXT("[|c%s|Hplayer:%s|h%s|h|r]"), ColourToString(1, iRed, iGreen, iBlue), sName, sName);
	else
		sMarkup = KOH.Name2Clickable(sName);
	end

	local	sKarma = "";
	if (Karma_GetConfig(KARMA_CONFIG.MARKUP_SHOW_KARMA)) then
		local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
		if (bModified) then
			bModified = "*";
		else
			bModified = "";
		end
		if (Karma_GetConfig(KARMA_CONFIG.MARKUP_COLOUR_KARMA)) then
			sKarma = format(TEXT(" {|c%s%s%s|r}"), ColourToString(1, iRed, iGreen, iBlue), bModified, iKarma);
		else
			sKarma = format(TEXT(" {%s%s}"), bModified, iKarma);
		end
	end

	sMarkup = sMarkup .. sKarma
--	sMarkup = "[|c"..ColourToString(1, iRed, iGreen, iBlue).."|Hplayer:"..sName.."|r] <|c"..ColourToString(0, iRed, iGreen, iBlue) .. iKarma .. "|r>";

	local	sNotes = Karma_MemberObject_GetNotes(oMember);
	if (sNotes) and (sNotes ~= "") then
		sMarkup = sMarkup .. "+";
	end

	return sMarkup;
end

-----------------------------------------
-- CONFIG FUNCTIONS
-----------------------------------------

function	Karma_InitializeConfig()
	if (KarmaConfig == nil) then
		KarmaConfig = {};
	end

	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.AUTOIGNORE_THRESHOLD, 10);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.AUTOIGNORE, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.AUTOIGNORE_INVITES, 1);

	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.JOINWARN_ENABLED, 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.JOINWARN_THRESHOLD, 35);

	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.SORTFUNCTION, KARMA_CONFIG.SORTFUNCTION_TYPE_KARMA);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.COLORFUNCTION, KARMA_CONFIG.COLORFUNCTION_TYPE_KARMA);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.COLORSPACE_ENABLE, false);
	if (not Karma_GetConfig(KARMA_CONFIG.COLORSPACE_ENABLE)) then
		KarmaConfig[KARMA_CONFIG.COLORSPACE_KARMA] = nil;
		KarmaConfig[KARMA_CONFIG.COLORSPACE_TIME] = nil;
		KarmaConfig[KARMA_CONFIG.COLORSPACE_XP] = nil;
	end
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.COLORSPACE_KARMA, KarmaModuleLocal.ColorSpaces.Default1, nil, true);
	KarmaModuleLocal.ColorSpaces.Karma = KarmaConfig[KARMA_CONFIG.COLORSPACE_KARMA];
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.COLORSPACE_TIME, KarmaModuleLocal.ColorSpaces.Default2, nil, true);
	KarmaModuleLocal.ColorSpaces.Time = KarmaConfig[KARMA_CONFIG.COLORSPACE_TIME];
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.COLORSPACE_XP, KarmaModuleLocal.ColorSpaces.Default2, nil, true);
	KarmaModuleLocal.ColorSpaces.XP = KarmaConfig[KARMA_CONFIG.COLORSPACE_XP];

	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_ENABLED, true);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_VERSION, 2);

	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_WHISPERS, true);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_CHANNELS, true);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_GUILD, true);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_RAID, true);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_BG, true);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_YELLSAYEMOTE, true);

	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_COLOUR_NAME, true);	-- TODO: !UI
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_COLOUR_KARMA, true);	-- TODO: !UI
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MARKUP_SHOW_KARMA, true);	-- TODO: !UI

	--
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.CLEAN_AUTO, false);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.CLEAN_KEEPIFNOTE, 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.CLEAN_REMOVEPVPJOINS, 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.CLEAN_REMOVEXSERVER, 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.CLEAN_KEEPIFKARMA, 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.CLEAN_KEEPIFQUESTCOUNT, 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.CLEAN_KEEPIFREGIONCOUNT, 2);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.CLEAN_KEEPIFZONECOUNT, 4);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.CLEAN_IGNOREPVPZONES, 1);

	-- 0: never, 1: always, 2: via GUILD, 3: with trusted people only
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.SHARE_ONREQ_KARMA, 3);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.SHARE_ONREQ_PUBLICNOTE, 2);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.SHARE_CHANNEL_NAME, "CommGlobal");
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.SHARE_CHANNEL_AUTO, false);

	-- Tracking:
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.RAID_TRACKALL, 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.RAID_NOGROUP, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TRACK_DISABLEACHIEVEMENT, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TRACK_DISABLEQUEST, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TRACK_DISABLEREGION, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TRACK_DISABLEZONE, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TRACK_DISABLEPVPAREAS, 1);

	--
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TARGET_COLORED, 1);

	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TOOLTIP_SHIFTREQ, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TOOLTIP_KARMA, true);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TOOLTIP_SKILL, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TOOLTIP_TALENTS, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TOOLTIP_ALTS, 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TOOLTIP_NOTES, false);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TOOLTIP_HELP, 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TOOLTIP_LFMADDKARMA, 1);

	--
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MINIMAP_HIDE, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.QUESTSIGNOREDAILIES, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.UPDATEWHILEAFK, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.DB_SPARSE, 0);

	--
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TIME_KARMA_DEFAULT, 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TIME_KARMA_MINVAL, 50);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TIME_KARMA_FACTOR, 0.4);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.TIME_KARMA_SKIPBGTIME, 1);

	--
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG.MENU_DEACTIVATE, 1);

	--
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG_MAINWND_LISTPREFIX .. "R", 0);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG_MAINWND_LISTPREFIX .. "Z", 1);
	Karma_FieldInitialize(KarmaConfig, KARMA_CONFIG_MAINWND_LISTPREFIX .. "Q", 1);
end

function	Karma_GetConfig(config)
	if (KarmaConfigLocal == nil) then
		return nil;
	end

	if (config == nil) then
		KarmaChatDebug("Oops? Requested <nil> config. Doh! >> " .. debugstack());
		return nil;
	end

	return KarmaConfigLocal[config];
end

function	Karma_SetConfig(config, value)
	if (KarmaConfigLocal == nil) then
		return;
	end

	local valstr = value;
	if value == true then
		valstr = "true";
	elseif value == false then
		valstr = "false";
	elseif value == nil then
		valstr = "nil";
	end
	KarmaChatDebug("Setting " .. config .. " to value " .. valstr);

	KarmaConfigLocal[config] = value;
end

function	Karma_GetConfigPerChar(config)
	if (KarmaConfigLocal == nil) then
		return nil;
	end

	if (config == nil) then
		KarmaChatDebug("Oops? Requested <nil> config. Doh! >> " .. debugstack());
		return nil;
	end

	if (KARMA_LOADED == 1) then
		if Karma_EverythingLoaded() then
			local	lCharacters = KarmaObj.DB.SF.CharacterListGet();
			local	CharConfig = lCharacters[UnitName("player")][KARMA_DB_L5_RRFFC.CONFIGPERCHAR];
			local	CharConfigValue = CharConfig[config];
			if (CharConfigValue ~= nil) then
				KarmaChatDebug("Using per-char value of " .. config);
				return CharConfigValue;
			end

			return KarmaConfigLocal[config];
		end
	else
		return nil;
	end
end

function	Karma_SetConfigPerChar(config, value)
	if (KarmaConfigLocal == nil) then
		return;
	end

	local valstr = value;
	if value == true then
		valstr = "true";
	elseif value == false then
		valstr = "false";
	elseif value == nil then
		valstr = "nil";
	end
	KarmaChatDebug("Setting " .. config .. " to value " .. valstr);

	KarmaConfigLocal[config] = value;

	if (KARMA_LOADED == 1) then
		if Karma_EverythingLoaded() then
			local	lCharacters = KarmaObj.DB.SF.CharacterListGet();
			local	CharConfig = lCharacters[UnitName("player")][KARMA_DB_L5_RRFFC.CONFIGPERCHAR];
			KarmaChatDebug("Storing per-char value for " .. config);
			CharConfig[config] = value;
		end
	end
end
-----------------------------------------
--	Karma Options Window
-----------------------------------------

local KARMA_OPTIONS_SORTTYPE_DROPDOWN = {
	{ sName = KARMA_WINEL_DROPDOWNBYKARMA,		sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_KARMA },
	{ sName = KARMA_WINEL_DROPDOWNBYXP,		sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_XP },
	{ sName = KARMA_WINEL_DROPDOWNBYTIME,		sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_PLAYED },
	{ sName = KARMA_WINEL_DROPDOWNBYXPALL,		sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_XPALL },
	{ sName = KARMA_WINEL_DROPDOWNBYTIMEALL,	sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_PLAYEDALL },
	{ sName = KARMA_WINEL_DROPDOWNBYNAME,		sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_NAME },
	{ sName = KARMA_WINEL_DROPDOWNBYCLASS,		sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_CLASS },
	{ sName = KARMA_WINEL_DROPDOWNBYJOINED,		sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_JOINED },
	{ sName = KARMA_WINEL_DROPDOWNBYTALENT,		sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_TALENT },
	{ sName = KARMA_WINEL_DROPDOWNBYGUILDTOP,	sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_TOP },
	{ sName = KARMA_WINEL_DROPDOWNBYGUILDBOTTOM,	sortType = KARMA_CONFIG.SORTFUNCTION_TYPE_GUILD_BOTTOM },
};

function	KarmaWindowOptions_SortByDropDown_Initialize()
	local	info, i;
	for i = 1, getn(KARMA_OPTIONS_SORTTYPE_DROPDOWN) do
		info = {};
		info.text = KARMA_OPTIONS_SORTTYPE_DROPDOWN[i].sName;
		info.func = KarmaWindowOptions_SortByDropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function	KarmaWindowOptions_SortByDropDown_OnShow()
 	UIDropDownMenu_Initialize(this, KarmaWindowOptions_SortByDropDown_Initialize);
 	UIDropDownMenu_SetWidth(this, 180);
 	UIDropDownMenu_SetButtonWidth(this, 24);

	local	i;
 	for i = 1, getn(KARMA_OPTIONS_SORTTYPE_DROPDOWN) do
		if (KARMA_OPTIONS_SORTTYPE_DROPDOWN[i].sortType == Karma_GetConfig(KARMA_CONFIG.SORTFUNCTION)) then
			UIDropDownMenu_SetSelectedID(KarmaOptionsWindow_SortType_DropDown, i);
		end
	end
end

function	KarmaWindowOptions_SortByDropDown_OnClick()
	UIDropDownMenu_SetSelectedID(KarmaOptionsWindow_SortType_DropDown, this:GetID());
	if ( KARMA_OPTIONS_SORTTYPE_DROPDOWN[UIDropDownMenu_GetSelectedID(KarmaOptionsWindow_SortType_DropDown)].sortType ) then
		Karma_SetConfig(KARMA_CONFIG.SORTFUNCTION, KARMA_OPTIONS_SORTTYPE_DROPDOWN[UIDropDownMenu_GetSelectedID(KarmaOptionsWindow_SortType_DropDown)].sortType);
		Karma_MemberList_ResetMemberNamesCache();
		KarmaWindow_Update();
	end
end

local KARMA_OPTIONS_COLORTYPE_DROPDOWN = {
	{sName = KARMA_WINEL_DROPDOWNBYKARMA, sortType = KARMA_CONFIG.COLORFUNCTION_TYPE_KARMA},
	{sName = KARMA_WINEL_DROPDOWNBYCLASS, sortType = KARMA_CONFIG.COLORFUNCTION_TYPE_CLASS},
	{sName = KARMA_WINEL_DROPDOWNBYTIME, sortType = KARMA_CONFIG.COLORFUNCTION_TYPE_PLAYED},
	{sName = KARMA_WINEL_DROPDOWNBYTIMEALL, sortType = KARMA_CONFIG.COLORFUNCTION_TYPE_PLAYEDALL},
	{sName = KARMA_WINEL_DROPDOWNBYXPLVL, sortType = KARMA_CONFIG.COLORFUNCTION_TYPE_XPLVL},
	{sName = KARMA_WINEL_DROPDOWNBYXPLVLALL, sortType = KARMA_CONFIG.COLORFUNCTION_TYPE_XPLVLALL},
	{sName = KARMA_WINEL_DROPDOWNBYXP, sortType = KARMA_CONFIG.COLORFUNCTION_TYPE_XP},
	{sName = KARMA_WINEL_DROPDOWNBYXPALL, sortType = KARMA_CONFIG.COLORFUNCTION_TYPE_XPALL},
};

function	KarmaWindowOptions_ColorByDropDown_Initialize()
	local	info;
	for i = 1, getn(KARMA_OPTIONS_COLORTYPE_DROPDOWN), 1 do
		info = {};
		info.text = KARMA_OPTIONS_COLORTYPE_DROPDOWN[i].sName;
		info.func = KarmaWindowOptions_ColorByDropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function	KarmaWindowOptions_ColorByDropDown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaWindowOptions_ColorByDropDown_Initialize);
 	UIDropDownMenu_SetWidth(this, 180);
	UIDropDownMenu_SetButtonWidth(this, 24);

	local	i;
	for i = 1, getn(KARMA_OPTIONS_COLORTYPE_DROPDOWN) do
		if (KARMA_OPTIONS_COLORTYPE_DROPDOWN[i].sortType == Karma_GetConfig(KARMA_CONFIG.COLORFUNCTION)) then
			UIDropDownMenu_SetSelectedID(KarmaOptionsWindow_ColorType_DropDown, i);
		end
	end
end

function	KarmaWindowOptions_ColorByDropDown_OnClick()
	UIDropDownMenu_SetSelectedID(KarmaOptionsWindow_ColorType_DropDown, this:GetID());
	if ( KARMA_OPTIONS_COLORTYPE_DROPDOWN[UIDropDownMenu_GetSelectedID(KarmaOptionsWindow_ColorType_DropDown)].sortType ) then
		Karma_SetConfig(KARMA_CONFIG.COLORFUNCTION, KARMA_OPTIONS_COLORTYPE_DROPDOWN[UIDropDownMenu_GetSelectedID(KarmaOptionsWindow_ColorType_DropDown)].sortType);
		KarmaWindow_Update();
	end
end

KarmaObj.Colorspace = {};

function	KarmaObj.Colorspace.ValueInit(sName)
	local	oGroup = KarmaModuleLocal.ColorSpaces[sName];
	if (oGroup == nil) then
		local	Def = KarmaModuleLocal.ColorSpaces.Default2;
		if (sName == "Karma") then
			Def = KarmaModuleLocal.ColorSpaces.Default1;
		end

		KarmaModuleLocal.ColorSpaces[sName] = Karma_CopyTable(Def);
		KarmaChatDebug("Colorspace: Init(" .. sName .. ") - copied.");
	end
end

function	KarmaObj.Colorspace.ValueGet(sName, sSuffix)
	KarmaObj.Colorspace.ValueInit(sName);

	local	oGroup = KarmaModuleLocal.ColorSpaces[sName];
	if (oGroup) then
		local	oItem = oGroup[sSuffix];
		if (oItem) then
			return oItem;
		end
	end

	return { r = 1, g = 1, b = 1 };
end

function	KarmaObj.Colorspace.ValueSet(sName, sSuffix, oValues)
	KarmaObj.Colorspace.ValueInit(sName);

	local	oGroup = KarmaModuleLocal.ColorSpaces[sName];
	if (oGroup) then
		local	oItem = oGroup[sSuffix];
		if (oItem) then
			oItem.r = oValues.r;
			oItem.g = oValues.g;
			oItem.b = oValues.b;
		end
	end

	if (sName and sSuffix) then
		local	oConfigs = KarmaConfig[KARMA_CONFIG["COLORSPACE_" .. strupper(sName)]];
		if (oConfigs) then
			local	oConfig = oConfigs[sSuffix];
			if (oConfig) then
				oConfig.r = oValues.r;
				oConfig.g = oValues.g;
				oConfig.b = oValues.b;
			end
		end
	end
end

function	KarmaObj.Colorspace.Init(oFrame)
	local	sNameFull, sName, sSuffix = oFrame:GetName();

	local	oTexture = _G[sNameFull .. "Texture"];
	oTexture:SetTexture("");
	oTexture:SetTexture(1, 1, 1);

	if (sNameFull) then
		sSuffix = strsub(sNameFull, -8);
		sName = strsub(sNameFull, 31, -10);

		local	oBtn1 = _G[sName .. "_" .. strsub(sSuffix, 1, 3)];
		local	oBtn2 = _G[sName .. "_" .. strsub(sSuffix, 6, 8)];
		if (oBtn1 and oBtn2) then
			local	sText = oBtn1:GetText() .. " => " .. oBtn2.GetText();
			local	oText = _G[sNameFull .. "Text"];
			oText:SetText(sText);
		end
	end
end

function	KarmaObj.Colorspace.Show(oFrame)
	local	sNameFull, sName, sSuffix = oFrame:GetName();
	if (sNameFull) then
		sSuffix = strsub(sNameFull, -8);
		sName = strsub(sNameFull, 31, -10);
	end

	local	oFrom, oTo;
	if (sSuffix == "MinToAvg") then
		oFrom = KarmaObj.Colorspace.ValueGet(sName, "Min");
		oTo   = KarmaObj.Colorspace.ValueGet(sName, "Avg");
	elseif (sSuffix == "AvgToMax") then
		oFrom = KarmaObj.Colorspace.ValueGet(sName, "Avg");
		oTo   = KarmaObj.Colorspace.ValueGet(sName, "Max");
	end

	if ((oFrom == nil) or (oTo == nil)) then
		KarmaChatDebug("Colorgradient: " .. (sName or "???") .. "/" .. (sSuffix or "???") .. " -- missing.");
		return
	end

	local	oTexture = _G[sNameFull .. "Texture"];
	oTexture:SetGradient("HORIZONTAL", oFrom.r, oFrom.g, oFrom.b, oTo.r, oTo.g, oTo.b);
	oTexture:Show();
end

function	KarmaAvEnK.Colorspace.ModifyDone()
	if (not ColorPickerFrame:IsShown()) then
		ColorPickerFrame.oData = nil;
		ColorPickerFrame.func = nil;
		ColorPickerFrame.cancelFunc = nil;
		if (InterfaceOptionsFrame:GetFrameStrata() ~= "HIGH") then
			ColorPickerFrame:SetFrameStrata("DIALOG");
		end
	end
end

function	KarmaAvEnK.Colorspace.ModifyDo()
	local	oData = ColorPickerFrame.oData;
	if (oData) then
		local	oSelect = oData.oSelect;
		local	r, g, b = ColorPickerFrame:GetColorRGB();
		if (oSelect and r and g and b) then
			oSelect.r = r;
			oSelect.g = g;
			oSelect.b = b;
		end

		KarmaObj.Colorspace.ValueSet(oData.sKeyMain, oData.sKeySub, oSelect);

		local	oFrame = oData.oFrame;
		if (oFrame) then
			local	sName = oFrame:GetName();
			local	sSuffix = strsub(sName, -3);
			if (sSuffix ~= "Max") then
				local	oGradient = _G[strsub(sName, 1, -4) .. "MinToAvg"];
				KarmaObj.Colorspace.Show(oGradient);
			end
			if (sSuffix ~= "Min") then
				local	oGradient = _G[strsub(sName, 1, -4) .. "AvgToMax"];
				KarmaObj.Colorspace.Show(oGradient);
			end
		end
	end

	KarmaAvEnK.Colorspace.ModifyDone();
end

function	KarmaAvEnK.Colorspace.Modify(oFrame)
	if (not Karma_GetConfig(KARMA_CONFIG.COLORSPACE_ENABLE)) then
		return
	end

	local	sNameFull, sName, sSuffix = oFrame:GetName();
	if (sNameFull) then
		sSuffix = strsub(sNameFull, -3);
		sName = strsub(sNameFull, 31, -5);
	end

	local	oSelect;
	if ((sSuffix == "Min") or (sSuffix == "Avg") or (sSuffix == "Max")) then
		oSelect = KarmaObj.Colorspace.ValueGet(sName, sSuffix);
	end

	if (oSelect and not ColorPickerFrame:IsShown()) then
		ColorPickerFrame.func = nil;
		ColorPickerFrame:SetColorRGB(oSelect.r, oSelect.g, oSelect.b);
		if (InterfaceOptionsFrame:GetFrameStrata() ~= "HIGH") then
			ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG");
		end

		ColorPickerFrame.oData  = { sKeyMain = sName, sKeySub = sSuffix, oSelect = oSelect, oFrame = oFrame };
		ColorPickerFrame.func = KarmaAvEnK.Colorspace.ModifyDo;
		ColorPickerFrame.cancelFunc = KarmaAvEnK.Colorspace.ModifyDone;
		ColorPickerFrame:Show();
	end
end

--
--
--
function	KarmaWindowOptions_ChatDefaultDropDown_Initialize()
	local	info;
	local	i;
	for i = 1, NUM_CHAT_WINDOWS do
		local	chatFrame = getglobal("ChatFrame"..i);
		if (chatFrame) then
			local	temp, shown;
			temp, temp, temp, temp, temp, temp, shown, temp = GetChatWindowInfo(i);
			if (shown or chatFrame.isDocked) then
				local	tab = getglobal(chatFrame:GetName().."Tab");
				local	sName = tab:GetText();

				KarmaChatDebug("ChatDefault_Init: [" .. i .. "] => " .. sName);

				info = {};
				info.value = i;
				info.text = sName;
				info.arg1 = sName;
				info.arg2 = i;
				info.func = KarmaWindowOptions_ChatDefaultDropDown_OnClick;
				UIDropDownMenu_AddButton(info);
			end
		end
	end

	info = {};
	info.value = -1;
	info.text = KARMA_WINEL_CHATDROPDOWNRESET;
	info.arg1 = KARMA_WINEL_CHATDROPDOWNRESET;
	info.arg2 = -1;
	info.func = KarmaWindowOptions_ChatDefaultDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end

function	KarmaWindowOptions_ChatDefaultDropDown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaWindowOptions_ChatDefaultDropDown_Initialize);
	UIDropDownMenu_SetWidth(this, 100);
	UIDropDownMenu_SetButtonWidth(this, 24);

	-- hopefully overriden...
	UIDropDownMenu_SetSelectedID(this, 0);

	local	found = false;
	local	ConfigChatDefault = Karma_GetConfigPerChar(KARMA_CONFIG.CHAT_DEFAULT);
	if (ConfigChatDefault ~= nil) and (ConfigChatDefault ~= "") then
		local	i;
		for i = 1, NUM_CHAT_WINDOWS do
			local	chatFrame = getglobal("ChatFrame"..i);
			if (chatFrame) then
				local	temp, shown;
				temp, temp, temp, temp, temp, temp, shown, temp = GetChatWindowInfo(i);
				if (shown or chatFrame.isDocked) then
					local	tab = getglobal(chatFrame:GetName().."Tab");
					local	sName = tab:GetText();
					if (sName == ConfigChatDefault) then
						KarmaChatDebug("ChatDefault_Set: [" .. i .. "] <= " .. sName);
						UIDropDownMenu_SetSelectedID(this, i);
						found = true;
						break;
					end
				end
			end
		end
	end

	if not found then
		KarmaChatDebug("ChatDefault_Set: [1] <= DEFAULT_CHAT_FRAME");
		UIDropDownMenu_SetSelectedID(this, 1);
	end
end

function	KarmaWindowOptions_ChatDefaultDropDown_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaOptionsWindow_ChatDefault_DropDown, this:GetID());
	if (arg1 ~= nil) and (arg2 ~= nil) then
		if (arg2 > 0) then
			local chatFrame = getglobal("ChatFrame" .. arg2);
			if chatFrame then
				KarmaObj.UIChat.DefaultSet(chatFrame);
				KarmaChatDefault(KARMA_MSG_CHATWND_DEFAULT .. KARMA_MSG_CHATWND_ISNOW .. " <" .. arg1 .. ">");
				Karma_SetConfigPerChar(KARMA_CONFIG.CHAT_DEFAULT, arg1);
				KarmaWindow_Update();
			end
		else
			KarmaObj.UIChat.DefaultSet(DEFAULT_CHAT_FRAME);
			KarmaChatDefault(KARMA_MSG_CHATWND_DEFAULT .. KARMA_MSG_CHATWND_ISNOW .. KARMA_MSG_CHATWND_DEFAULTAGAIN);
			Karma_SetConfigPerChar(KARMA_CONFIG.CHAT_DEFAULT, "");
			KarmaWindow_Update();
		end
	end
end

function	KarmaWindowOptions_ChatSecondaryDropDown_Initialize()
	local	info;
	local	i;
	for i = 1, NUM_CHAT_WINDOWS do
		local	chatFrame = getglobal("ChatFrame" .. i);
		if (chatFrame) then
			local	temp, shown;
			temp, temp, temp, temp, temp, temp, shown, temp = GetChatWindowInfo(i);
			if (shown or chatFrame.isDocked) then
				local	tab = getglobal(chatFrame:GetName().."Tab");
				local	sName = tab:GetText();

				KarmaChatDebug("ChatSecondary_Init: [" .. i .. "] => " .. sName);

				info = {};
				info.value = i;
				info.text = sName;
				info.arg1 = sName;
				info.arg2 = i;
				info.func = KarmaWindowOptions_ChatSecondaryDropDown_OnClick;
				UIDropDownMenu_AddButton(info);
			end
		end
	end

	info = {};
	info.value = -1;
	info.text = KARMA_WINEL_CHATDROPDOWNRESET;
	info.arg1 = KARMA_WINEL_CHATDROPDOWNRESET;
	info.arg2 = -1;
	info.func = KarmaWindowOptions_ChatSecondaryDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end

function	KarmaWindowOptions_ChatSecondaryDropDown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaWindowOptions_ChatSecondaryDropDown_Initialize);
	UIDropDownMenu_SetWidth(this, 100);
	UIDropDownMenu_SetButtonWidth(this, 24);

	-- hopefully overriden...
	UIDropDownMenu_SetSelectedID(this, 0);

	local sNameCurrently = KarmaObj.UIChat.SecondaryNameGet();
	if sNameCurrently == nil then
		sNameCurrently = Karma_GetConfigPerChar(KARMA_CONFIG.CHAT_SECONDARY);
		if (sNameCurrently == "") then
			sNameCurrently = nil;
		end
	end

	local	found = false;
	if sNameCurrently ~= nil then
		KarmaChatDebug("ChatSecondary_Set: [???] <= " .. sNameCurrently);

		local	i;
		for i = 1, NUM_CHAT_WINDOWS do
			local	chatFrame = getglobal("ChatFrame"..i);
			if (chatFrame) then
				local	temp, shown;
				temp, temp, temp, temp, temp, temp, shown, temp = GetChatWindowInfo(i);
				if (shown or chatFrame.isDocked) then
					local	tab = getglobal(chatFrame:GetName().."Tab");
					local	sName = tab:GetText();
	
					if (sName == sNameCurrently) then
						KarmaChatDebug("ChatSecondary_Set: [" .. i .. "] <= " .. sName);
						UIDropDownMenu_SetSelectedID(this, i);
						found = true;
						break;
					end
				end
			end
		end
	end

	if not found and (sNameCurrently ~= nil) then
		KarmaChatDebug("ChatSecondary_Set: [???] <= " .. sNameCurrently);
	end
end

function	KarmaWindowOptions_ChatSecondaryDropDown_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaOptionsWindow_ChatSecondary_DropDown, this:GetID());
	if (arg1 ~= nil) and (arg2 ~= nil) then
		if (arg2 > 0) then
			local chatFrame = getglobal("ChatFrame" .. arg2);
			if chatFrame then
				KarmaObj.UIChat.SecondarySet(chatFrame);
				KarmaChatDefault(KARMA_MSG_CHATWND_SECONDARY .. KARMA_MSG_CHATWND_ISNOW .. " <" .. arg1 .. "> " .. KARMA_MSG_CHATWND_OVERTHERE);
				KarmaChatSecondary(KARMA_MSG_CHATWND_SECONDARY .. KARMA_MSG_CHATWND_ISNOW .. KARMA_MSG_CHATWND_THISONE);
				Karma_SetConfigPerChar(KARMA_CONFIG.CHAT_SECONDARY, arg1);
				KarmaWindow_Update();
			end
		else
			KarmaObj.UIChat.SecondarySet(nil);
			KarmaChatDefault(KARMA_MSG_CHATWND_SECONDARY .. KARMA_MSG_CHATWND_ISNOW .. KARMA_MSG_CHATWND_UNSET);
			Karma_SetConfigPerChar(KARMA_CONFIG.CHAT_SECONDARY, "");
			KarmaWindow_Update();
		end
	end
end

-- DEBUG window
function	KarmaWindowOptions_ChatDebugDropDown_Initialize()
	local	info;
	local	i;
	for i = 1, NUM_CHAT_WINDOWS do
		local	chatFrame = getglobal("ChatFrame" .. i);
		if (chatFrame) then
			local	temp, shown;
			temp, temp, temp, temp, temp, temp, shown, temp = GetChatWindowInfo(i);
			if (shown or chatFrame.isDocked) then
				local	tab = getglobal(chatFrame:GetName().."Tab");
				local	sName = tab:GetText();

				KarmaChatDebug("ChatDebug_Init: [" .. i .. "] => " .. sName);

				info = {};
				info.value = i;
				info.text = sName;
				info.arg1 = sName;
				info.arg2 = i;
				info.func = KarmaWindowOptions_ChatDebugDropDown_OnClick;
				UIDropDownMenu_AddButton(info);
			end
		end
	end

	info = {};
	info.value = -1;
	info.text = KARMA_WINEL_CHATDROPDOWNRESET;
	info.arg1 = KARMA_WINEL_CHATDROPDOWNRESET;
	info.arg2 = -1;
	info.func = KarmaWindowOptions_ChatDebugDropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end

function	KarmaWindowOptions_ChatDebugDropDown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaWindowOptions_ChatDebugDropDown_Initialize);
	UIDropDownMenu_SetWidth(this, 100);
	UIDropDownMenu_SetButtonWidth(this, 24);

	-- hopefully overriden...
	UIDropDownMenu_SetSelectedID(this, 0);

	local sNameCurrently = KarmaObj.UIChat.DebugNameGet();
	if sNameCurrently == nil then
		sNameCurrently = Karma_GetConfigPerChar(KARMA_CONFIG.CHAT_DEBUG);
		if (sNameCurrently == "") then
			sNameCurrently = nil;
		end
	end

	local	found = false;
	if sNameCurrently ~= nil then
		KarmaChatDebug("ChatDebug_Set: [???] <= " .. sNameCurrently);

		local	i;
		for i = 1, NUM_CHAT_WINDOWS do
			local	chatFrame = getglobal("ChatFrame"..i);
			if (chatFrame) then
				local	temp, shown;
				temp, temp, temp, temp, temp, temp, shown, temp = GetChatWindowInfo(i);
				if (shown or chatFrame.isDocked) then
					local	tab = getglobal(chatFrame:GetName().."Tab");
					local	sName = tab:GetText();

					if (sName == sNameCurrently) then
						KarmaChatDebug("ChatDebug_Set: [" .. i .. "] <= " .. sName);
						UIDropDownMenu_SetSelectedID(this, i);
						found = true;
						break;
					end
				end
			end
		end
	end

	if not found and (sNameCurrently ~= nil) then
		KarmaChatDebug("ChatDebug_Set: [???] <= " .. sNameCurrently);
	end
end

function	KarmaWindowOptions_ChatDebugDropDown_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaOptionsWindow_ChatDebug_DropDown, this:GetID());
	if (arg1 ~= nil) and (arg2 ~= nil) then
		if (arg2 > 0) then
			local chatFrame = getglobal("ChatFrame" .. arg2);
			if chatFrame then
				KarmaObj.UIChat.DebugSet(chatFrame);
				KarmaChatDefault(KARMA_MSG_CHATWND_DEBUG .. KARMA_MSG_CHATWND_ISNOW .. " <" .. arg1 .. "> " .. KARMA_MSG_CHATWND_OVERTHERE);
				KarmaChatDebug(KARMA_MSG_CHATWND_DEBUG .. KARMA_MSG_CHATWND_ISNOW .. KARMA_MSG_CHATWND_THISONE);
				Karma_SetConfigPerChar(KARMA_CONFIG.CHAT_DEBUG, arg1);
				KarmaWindow_Update();
			end
		else
			KarmaObj.UIChat.DebugSet(nil);
			KarmaChatDefault(KARMA_MSG_CHATWND_DEBUG .. KARMA_MSG_CHATWND_ISNOW .. KARMA_MSG_CHATWND_UNSET);
			Karma_SetConfigPerChar(KARMA_CONFIG.CHAT_DEBUG, "");
			KarmaWindow_Update();
		end
	end
end

--
--
--
function	KarmaOptionWindow_AutoignoreEnabled_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE));
end

function	KarmaOptionWindow_AutoignoreEnabled_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.AUTOIGNORE, KOH.Nil1To01(this:GetChecked()));
end

function	KarmaOptionWindow_IgnoreInvites_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE_INVITES));
end

function	KarmaOptionWindow_IgnoreInvites_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.AUTOIGNORE_INVITES, KOH.Nil1To01(this:GetChecked()));
end

function	KarmaOptionWindow_AutoIgnoreThreshold_OnShow()
	this:SetText(Karma_GetConfig(KARMA_CONFIG.AUTOIGNORE_THRESHOLD));
end

function	KarmaOptionWindow_AutoIgnoreThreshold_OnChanged()
	Karma_SetConfig(KARMA_CONFIG.AUTOIGNORE_THRESHOLD, this:GetText());
end

--
----
--   Sharing
----
--
-- SHARE_ONREQ_KARMA
--
function	KarmaOptionWindow_Sharing_KarmaLevel_Menu_Initialize()
	local	i = 0;
	while (KARMA_SHARELEVELS["L" .. i] ~= nil) do
		local	info = {};
		info.value = i;
		info.text = KARMA_SHARELEVELS["L" .. i];
		info.arg1 = info.text;
		info.arg2 = i;
		info.func = KarmaOptionWindow_Sharing_KarmaLevel_Menu_OnClick;
		UIDropDownMenu_AddButton(info);

		i = i + 1;
	end
end

function	KarmaOptionWindow_Sharing_KarmaLevel_Menu_OnShow(self)
	UIDropDownMenu_Initialize(self, KarmaOptionWindow_Sharing_KarmaLevel_Menu_Initialize);
	UIDropDownMenu_SetWidth(self, 100);
	UIDropDownMenu_SetButtonWidth(self, 24);
	UIDropDownMenu_JustifyText(self, "LEFT");

	local	bSet = false;
	local	iLevel = Karma_GetConfig(KARMA_CONFIG.SHARE_ONREQ_KARMA);
	if (iLevel ~= nil) then
		local	sLevel = KARMA_SHARELEVELS["L" .. iLevel];
		if (sLevel ~= nil) then
			bSet = true;
			UIDropDownMenu_SetSelectedID(self, iLevel);
			UIDropDownMenu_SetText(self, sLevel);
		end
	end
	if (not bSet) then
		UIDropDownMenu_SetSelectedID(self, 0);
	end
end

function	KarmaOptionWindow_Sharing_KarmaLevel_Menu_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaOptionWindow_Sharing_KarmaLevel_Menu, self:GetID());
	if (arg1 ~= nil) and (arg2 ~= nil) then
		Karma_SetConfig(KARMA_CONFIG.SHARE_ONREQ_KARMA, arg2);
		KarmaChatSecondary("Share level for " .. KARMA_ITSELF .. " value is now: " .. arg1 .. " (" .. arg2 .. ")");
	end
end

--
-- SHARE_ONREQ_PUBLICNOTE
--
function	KarmaOptionWindow_Sharing_PublicnoteLevel_Menu_Initialize()
	local	i = 0;
	while (KARMA_SHARELEVELS["L" .. i] ~= nil) do
		local	info = {};
		info.value = i;
		info.text = KARMA_SHARELEVELS["L" .. i];
		info.arg1 = info.text;
		info.arg2 = i;
		info.func = KarmaOptionWindow_Sharing_PublicnoteLevel_Menu_OnClick;
		UIDropDownMenu_AddButton(info);

		i = i + 1;
	end
end

function	KarmaOptionWindow_Sharing_PublicnoteLevel_Menu_OnShow(self)
	UIDropDownMenu_Initialize(self, KarmaOptionWindow_Sharing_PublicnoteLevel_Menu_Initialize);
	UIDropDownMenu_SetWidth(self, 100);
	UIDropDownMenu_SetButtonWidth(self, 24);
	UIDropDownMenu_JustifyText(self, "LEFT");

	-- hopefully overriden...
	UIDropDownMenu_SetSelectedID(self, 0);

	local	bSet = false;
	local	iLevel = Karma_GetConfig(KARMA_CONFIG.SHARE_ONREQ_PUBLICNOTE);
	if (iLevel ~= nil) then
		local	sLevel = KARMA_SHARELEVELS["L" .. iLevel];
		if (sLevel ~= nil) then
			bSet = true;
			UIDropDownMenu_SetSelectedID(self, iLevel);
			UIDropDownMenu_SetText(self, sLevel);
		end
	end
	if (not bSet) then
		UIDropDownMenu_SetSelectedID(self, 0);
	end
end

function	KarmaOptionWindow_Sharing_PublicnoteLevel_Menu_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaOptionWindow_Sharing_PublicnoteLevel_Menu, self:GetID());
	if (arg1 ~= nil) and (arg2 ~= nil) then
		Karma_SetConfig(KARMA_CONFIG.SHARE_ONREQ_PUBLICNOTE, arg2);
		KarmaChatSecondary("Share level for public note is now: " .. arg1 .. " (" .. arg2 .. ")");
	end
end

function	KarmaOptionWindow_Sharing_ChannelName_OnShow()
	local	sText = Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME);
	if (sText) then
		this:SetText(sText);
	end
end

function	KarmaOptionWindow_Sharing_ChannelName_OnChanged()
	local	sText = this:GetText();
	if (sText == "") then
		sText = nil;
	end
	Karma_SetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME, sText);
end

--
--
--
function	KarmaOptionWindow_WarnLowKarma_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.JOINWARN_ENABLED));
end

function	KarmaOptionWindow_WarnLowKarma_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.JOINWARN_ENABLED, KOH.Nil1To01(this:GetChecked()));
end

function	KarmaOptionWindow_WarnLowKarma_Threshold_OnShow()
	local Threshold = Karma_GetConfig(KARMA_CONFIG.JOINWARN_THRESHOLD);
	if (Threshold) then
		this:SetText(Threshold);
	end
end

function	KarmaOptionWindow_WarnLowKarma_Threshold_OnChanged()
	Karma_SetConfig(KARMA_CONFIG.JOINWARN_THRESHOLD, this:GetText());
end

--
--
--
function	KarmaOptionWindow_DBClean_AutoClean_Checkbox_OnLoad()
	this:SetChecked(KOH.BooleanToInt(Karma_GetConfig(KARMA_CONFIG.CLEAN_AUTO)));
end

function	KarmaOptionWindow_DBClean_AutoClean_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.CLEAN_AUTO, KOH.IntToBoolean(this:GetChecked()));
end

--
function	KarmaOptionWindow_DBClean_AutoCleanPvP_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.CLEAN_AUTOPVP));
end

function	KarmaOptionWindow_DBClean_AutoCleanPvP_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.CLEAN_AUTOPVP, KOH.Nil1To01(this:GetChecked()));
end

--
function	KarmaOptionWindow_DBClean_KeepIfNote_Checkbox_OnLoad()
	local	KeepIfNote = Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFNOTE);
	if (KeepIfNote ~= 0) then
		this:SetChecked(KeepIfNote);
	end
end

function	KarmaOptionWindow_DBClean_KeepIfNote_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.CLEAN_KEEPIFNOTE, KOH.Nil1To01(this:GetChecked()));
end

--
function	KarmaOptionWindow_DBClean_RemovePvPJoins_Checkbox_OnLoad()
	local	RemovePvPJoins = Karma_GetConfig(KARMA_CONFIG.CLEAN_REMOVEPVPJOINS);
	if (RemovePvPJoins ~= 0) then
		this:SetChecked(RemovePvPJoins);
	end
end

function	KarmaOptionWindow_DBClean_RemovePvPJoins_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.CLEAN_REMOVEPVPJOINS, KOH.Nil1To01(this:GetChecked()));
end

--
function	KarmaOptionWindow_DBClean_RemoveXServer_Checkbox_OnLoad()
	local	RemoveXServer = Karma_GetConfig(KARMA_CONFIG.CLEAN_REMOVEXSERVER);
	if (RemoveXServer ~= 0) then
		this:SetChecked(RemoveXServer);
	end
end

function	KarmaOptionWindow_DBClean_RemoveXServer_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.CLEAN_REMOVEXSERVER, KOH.Nil1To01(this:GetChecked()));
end

--
function	KarmaOptionWindow_DBClean_KeepIfKarma_Checkbox_OnLoad()
	local	KeepIfKarma = Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFKARMA);
	if (KeepIfKarma ~= 0) then
		this:SetChecked(KeepIfKarma);
	end
end

function	KarmaOptionWindow_DBClean_KeepIfKarma_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.CLEAN_KEEPIFKARMA, KOH.Nil1To01(this:GetChecked()));
end

--
function	KarmaOptionWindow_DBClean_KeepIfQListThres_OnShow()
	if (Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFQUESTCOUNT) == nil) then
		Karma_SetConfig(KARMA_CONFIG.CLEAN_KEEPIFQUESTCOUNT, 1);
	end
	this:SetText(Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFQUESTCOUNT));
end

function	KarmaOptionWindow_DBClean_KeepIfQListThres_OnChanged()
	local	Value = tonumber(this:GetText());
	if (type(Value) == "number") and (Value >= 0) then
		Karma_SetConfig(KARMA_CONFIG.CLEAN_KEEPIFQUESTCOUNT, Value);
	end
end

--
function	KarmaOptionWindow_DBClean_KeepIfZListThres_OnShow()
	if (Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFZONECOUNT) == nil) then
		Karma_SetConfig(KARMA_CONFIG.CLEAN_KEEPIFZONECOUNT, 1);
	end
	this:SetText(Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFZONECOUNT));
end

function	KarmaOptionWindow_DBClean_KeepIfZListThres_OnChanged()
	local	Value = tonumber(this:GetText());
	if (type(Value) == "number") and (Value >= 0) then
		Karma_SetConfig(KARMA_CONFIG.CLEAN_KEEPIFZONECOUNT, Value);
	end
end

--
function	KarmaOptionWindow_DBClean_KeepIfRListThres_OnShow()
	if (Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFREGIONCOUNT) == nil) then
		Karma_SetConfig(KARMA_CONFIG.CLEAN_KEEPIFREGIONCOUNT, 1);
	end
	this:SetText(Karma_GetConfig(KARMA_CONFIG.CLEAN_KEEPIFREGIONCOUNT));
end

function	KarmaOptionWindow_DBClean_KeepIfRListThres_OnChanged()
	local	Value = tonumber(this:GetText());
	if (type(Value) == "number") then
		Karma_SetConfig(KARMA_CONFIG.CLEAN_KEEPIFREGIONCOUNT, Value);
	end
end

--
function	KarmaOptionWindow_DBClean_IgnorePVPZones_Checkbox_OnLoad()
	local	IgnorePVPZones = Karma_GetConfig(KARMA_CONFIG.CLEAN_IGNOREPVPZONES);
	if (IgnorePVPZones ~= 0) then
		this:SetChecked(IgnorePVPZones);
	end
end

function	KarmaOptionWindow_DBClean_IgnorePVPZones_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.CLEAN_IGNOREPVPZONES, KOH.Nil1To01(this:GetChecked()));
end

function	KarmaOptionWindow_DBClean_Test_OnClick()
	Karma_ClearUnused(KarmaObj.DB.FactionCacheGet(), "dryrun");
end

--
--
--

-- ************************************************************************ --
-- ************************************************************************ --
function	KarmaOptionWindow_Other_MainWndTab_Dropdown_Initialize()
	local	MainWndTabs = {
		[ 1 ] = KARMA_WINEL_TRACKINGDATA_BUTTON,
		[ 2 ] = KARMA_WINEL_OTHERDATA_BUTTON
		};

	local	info;
	local	i;
	for i = 1, #MainWndTabs do
		info = {};
		info.value = i;
		info.text = MainWndTabs[i];
		info.arg1 = MainWndTabs[i];
		info.arg2 = i;
		info.func = KarmaOptionWindow_Other_MainWndTab_Dropdown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function	KarmaOptionWindow_Other_MainWndTab_Dropdown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaOptionWindow_Other_MainWndTab_Dropdown_Initialize);
	UIDropDownMenu_SetWidth(this, 150);
	UIDropDownMenu_SetButtonWidth(this, 24);

	-- hopefully overriden...
	local	id = Karma_GetConfig(KARMA_CONFIG.MAINWND_INITIALTAB);
	if (id) then
		UIDropDownMenu_SetSelectedID(this, id);
	else
		UIDropDownMenu_SetSelectedID(this, 1);
	end
end

function	KarmaOptionWindow_Other_MainWndTab_Dropdown_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaOptionWindow_Other_MainWndTab_Dropdown, this:GetID());
	if (arg2) and (arg2 > 0) then
		Karma_SetConfig(KARMA_CONFIG.MAINWND_INITIALTAB, arg2);
	end
end
-- ************************************************************************ --
-- ************************************************************************ --

function	KarmaOptionWindow_Other_AutocheckTalents_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TALENTS_AUTOFETCH) == 1);
end

function	KarmaOptionWindow_Other_AutocheckTalents_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TALENTS_AUTOFETCH, KOH.Nil1To01(this:GetChecked()));
	KARMA_TalentInspect.AutofetchConfigCache = nil;
end

function	KarmaOptionWindow_Other_MinimapIconHide_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.MINIMAP_HIDE) == 1);
end

function	KarmaOptionWindow_Other_MinimapIconHide_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.MINIMAP_HIDE, KOH.Nil1To01(this:GetChecked()));
	Karma_MinimapIconFrame_ResetIcon();
	Karma_MinimapIconFrame_InitComplete();
end

--
--
--
function	KarmaOptionWindow_VirtualKarma_TimeKarma_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TIME_KARMA_DEFAULT) == 1);
end

function	KarmaOptionWindow_VirtualKarma_TimeKarma_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TIME_KARMA_DEFAULT, KOH.Nil1To01(this:GetChecked()));
end

function	KarmaOptionWindow_VirtualKarma_TimeKarmaThreshold_Editbox_OnShow()
	local	value = Karma_GetConfig(KARMA_CONFIG.TIME_KARMA_MINVAL);
	if (type(value) == "number") then
		if (value < 1) or (value > 99) then
			value = 50;
			Karma_SetConfig(KARMA_CONFIG.TIME_KARMA_MINVAL, value);
		end
	else
		value = 50;
		Karma_SetConfig(KARMA_CONFIG.TIME_KARMA_MINVAL, value);
	end

	this:SetText(value);
end

function	KarmaOptionWindow_VirtualKarma_TimeKarmaThreshold_Editbox_OnChanged()
	local	value = tonumber(this:GetText());
	if (type(value) == "number") then
		if (value >= 1) and (value <= 99) then
			Karma_SetConfig(KARMA_CONFIG.TIME_KARMA_MINVAL, value);
		end
	end
end

function	KarmaOptionWindow_VirtualKarma_TimeKarmaFactor_Editbox_OnShow()
	local	value = Karma_GetConfig(KARMA_CONFIG.TIME_KARMA_FACTOR);
	if (type(value) == "number") then
		if (value < 0.01) or (value > 10) then
			value = 0.4;
			Karma_SetConfig(KARMA_CONFIG.TIME_KARMA_FACTOR, value);
		end
	else
		value = 50;
		Karma_SetConfig(KARMA_CONFIG.TIME_KARMA_FACTOR, value);
	end

	this:SetText(value);
end

function	KarmaOptionWindow_VirtualKarma_TimeKarmaFactor_Editbox_OnChanged()
	local	value = tonumber(this:GetText());
	if (type(value) == "number") then
		if (value >= 0.01) and (value <= 10) then
			Karma_SetConfig(KARMA_CONFIG.TIME_KARMA_FACTOR, value);
		end
	end
end

--
--
--
function	KarmaOptionWindow_Tooltip_ShiftReq_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_SHIFTREQ) ~= 0);
end

function	KarmaOptionWindow_Tooltip_ShiftReq_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_SHIFTREQ, KOH.Nil1To01(this:GetChecked()));
end


function	KarmaOptionWindow_OtherKarmaTips_Checkbox_OnLoad()
	this:SetChecked(KOH.BooleanToInt(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_KARMA)));
end

function	KarmaOptionWindow_OtherKarmaTips_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_KARMA, KOH.IntToBoolean(this:GetChecked()));
end

-- pair >>
function	KarmaOptionWindow_OtherPlayedThisTips_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTHIS));
end

function	KarmaOptionWindow_OtherPlayedThisTips_Checkbox_OnClick()
	local	iChecked = KOH.Nil1To01(this:GetChecked());
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTHIS, iChecked);
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTOTAL, 1 - iChecked);
	KarmaOptionWindow_OtherPlayedTotalTips_Checkbox:SetChecked(1 - iChecked);
end

function	KarmaOptionWindow_OtherPlayedTotalTips_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTOTAL));
end

function	KarmaOptionWindow_OtherPlayedTotalTips_Checkbox_OnClick()
	local	iChecked = KOH.Nil1To01(this:GetChecked());
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTOTAL, iChecked);
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_PLAYEDTHIS, 1 - iChecked);
	KarmaOptionWindow_OtherPlayedThisTips_Checkbox:SetChecked(1 - iChecked);
end
-- pair <<

function	KarmaOptionWindow_OtherNoteTips_Checkbox_OnLoad()
	this:SetChecked(KOH.BooleanToInt(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_NOTES)));
end

function	KarmaOptionWindow_OtherNoteTips_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_NOTES, KOH.IntToBoolean(this:GetChecked()));
end


function	KarmaOptionWindow_Tooltip_Skill_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_SKILL) ~= 0);
end

function	KarmaOptionWindow_Tooltip_Skill_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_SKILL, KOH.Nil1To01(this:GetChecked()));
end

function	KarmaOptionWindow_Tooltip_Talents_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_TALENTS) ~= 0);
end

function	KarmaOptionWindow_Tooltip_Talents_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_TALENTS, KOH.Nil1To01(this:GetChecked()));
end

function	KarmaOptionWindow_Tooltip_Alts_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_ALTS) ~= 0);
end

function	KarmaOptionWindow_Tooltip_Alts_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_ALTS, KOH.Nil1To01(this:GetChecked()));
end


function	Karma_ShowTooltipHelp()
	return Karma_GetConfig(KARMA_CONFIG.TOOLTIP_HELP) ~= 0;
end

function	KarmaOptionWindow_Tooltip_Help_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_HELP) ~= 0);
end

function	KarmaOptionWindow_Tooltip_Help_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_HELP, KOH.Nil1To01(this:GetChecked()));
end

function	KarmaOptionWindow_Tooltip_LFMAddKarma_Checkbox_OnLoad()
	this:SetChecked(Karma_GetConfig(KARMA_CONFIG.TOOLTIP_LFMADDKARMA) ~= 0);
end

function	KarmaOptionWindow_Tooltip_LFMAddKarma_Checkbox_OnClick()
	Karma_SetConfig(KARMA_CONFIG.TOOLTIP_LFMADDKARMA, KOH.Nil1To01(this:GetChecked()));
end

function	KarmaObj.UI.Config.CheckBox_MarkupVersion_OnLoad(self)
	if (Karma_GetConfig(KARMA_CONFIG.BETA)) then
		this:SetChecked(Karma_GetConfig(KARMA_CONFIG.MARKUP_VERSION) >= 3);
	else
		this:SetChecked(Karma_GetConfig(KARMA_CONFIG.MARKUP_VERSION) >= 2);
	end
end

function	KarmaObj.UI.Config.CheckBox_MarkupVersion_OnClick()
	if (Karma_GetConfig(KARMA_CONFIG.BETA)) then
		Karma_SetConfig(KARMA_CONFIG.MARKUP_VERSION, 2 + KOH.Nil1To01(this:GetChecked()));
	else
		Karma_SetConfig(KARMA_CONFIG.MARKUP_VERSION, 1 + KOH.Nil1To01(this:GetChecked()));
	end
	KarmaChatSecondaryFallbackDefault("Setting will be effective with next relogging.");
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--		["KarmaOptionWindow_MarkupWhispers_Checkbox"] =
--			{ CFG = KARMA_CONFIG.MARKUP_WHISPERS, TYPE = "bool", DEPENDS = KARMA_CONFIG.MARKUP_ENABLED },

function	KarmaObj.UI.Config.CheckBox_OnLoad(self)
	local	sName = self:GetName();
	if (KarmaModuleLocal.UIConfig.Elements[sName]) then
		local	oElement = KarmaModuleLocal.UIConfig.Elements[sName];
		local	bOn = false;
		local	Value = Karma_GetConfig(oElement.CFG);
		if (Value == nil) then
			Value = oElement.DEFAULT;
		end
		if (oElement.TYPE == "bool") then
			bOn = true == Value;
		elseif (oElement.TYPE == "01") then
			bOn = 1 == Value;
		end

		if (bOn) then
			self:SetChecked(1);
		else
			self:SetChecked(0);
		end
	else
		KarmaChatDebug("KOUIC.CB: missing element " .. sName);
	end
end

function	KarmaObj.UI.Config.CheckBox_OnClick(self)
	local	sName = self:GetName();
	if (KarmaModuleLocal.UIConfig.Elements[sName]) then
		local	oElement = KarmaModuleLocal.UIConfig.Elements[sName];
		if (oElement.DEPENDS) then
			local	bDepOn = false;
			if (oElement.TYPE == "bool") then
				bDepOn = true == Karma_GetConfig(oElement.DEPENDS);
			elseif (oElement.TYPE == "01") then
				bDepOn = 1 == Karma_GetConfig(oElement.DEPENDS);
			end
			if (not bDepOn) then
				-- restore state in UI to stored one
				KarmaObj.UI.Config.CheckBox_OnLoad(self);
				return
			end
		end

		local	bOn = 1 == self:GetChecked();
		if (oElement.TYPE == "bool") then
			Karma_SetConfig(oElement.CFG, bOn);
		elseif (oElement.TYPE == "01") then
			if (bOn) then
				Karma_SetConfig(oElement.CFG, 1);
			else
				Karma_SetConfig(oElement.CFG, 0);
			end
		end
	else
		KarmaChatDebug("KOUIC.CB: missing element " .. sName);
	end
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

---
---- Minimap Icon: positioning and menu
---
local function MinimapSetPosFromAngle(angle)
	local	xcenter, ycenter = Minimap:GetCenter()
	local	xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom();
	-- (xcenter, ycenter) + r * (cos angle, sin angle)
	local	r = xcenter - xmin + 10;
	local	cos_a = cos(angle);
	local	sin_a = sin(angle);

	if (GetMinimapShape) then
		if (GetMinimapShape() ~= "ROUND") then
			-- square minimap: r = f(angle)
			if (abs(cos_a) > abs(sin_a)) then
				r = r / abs(cos_a);
			else
				r = r / abs(sin_a);
			end;
		end;
	end;

	Karma_MinimapIconFrame:SetPoint("CENTER", "Minimap", "CENTER", - r * cos_a, r * sin_a);
end

function	Karma_MinimapIconFrame_OnLoad()
	Karma_MinimapIconFrame:RegisterForClicks("LeftButtonUp","MiddleButtonUp","RightButtonUp");
	Karma_MinimapIconFrame:RegisterForDrag("LeftButton");
	Karma_MinimapIconFrame_ResetIcon();
end

function	Karma_MinimapIconFrame_ResetIcon()
	-- forced initial position, just so SimpleMinimap doesn't f*** it up completely
	Karma_MinimapIconFrame:ClearAllPoints();
	MinimapSetPosFromAngle(180);
	if (Karma_GetConfig(KARMA_CONFIG.MINIMAP_HIDE) ~= 1) then
		Karma_MinimapIconFrame:Show();
	else
		Karma_MinimapIconFrame:Hide();
	end
end

function	Karma_MinimapIconFrame_InitComplete()
	-- faction object not ready in OnLoad
	local IconPos = Karma_GetConfigPerChar(KARMA_CONFIG_MINIMAPPOS);
	if (IconPos == nil) then
		IconPos = 180;
	end

	MinimapSetPosFromAngle(IconPos);

	if (Karma_GetConfig(KARMA_CONFIG.MINIMAP_HIDE) == 1) then
		Karma_MinimapIconFrame:Hide();
	end
end

function	Karma_MinimapIconFrame_IconDragStart()
	Karma_MinimapIconFrame:LockHighlight();
	Karma_MinimapIconFrame:StartMoving()
end

function	Karma_MinimapIconFrame_IconDragStop()
	Karma_MinimapIconFrame:StopMovingOrSizing();
	Karma_MinimapIconFrame:UnlockHighlight();
	Karma_MinimapIconFrame_IconDrag(true);
end

function	Karma_MinimapIconFrame_IconDragging()
	Karma_MinimapIconFrame_IconDrag(false);
end

function	Karma_MinimapIconFrame_IconDrag(store)
	local xcenter, ycenter = Minimap:GetCenter()
	local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom();
	local xpos, ypos = GetCursorPosition();

--KarmaChatDebug("Minimap: Center (x, y) = (" .. xcenter .. ", " .. ycenter .. ")");
--KarmaChatDebug("Minimap: LeftBottom (x, y) = (" .. xmin .. ", " .. ymin .. ")");
--KarmaChatDebug("Minimap: Center (x, y) = (" .. xpos .. ", " .. ypos .. ")");

	xpos = xmin - xpos / Minimap:GetEffectiveScale() + 70;
	ypos =        ypos / Minimap:GetEffectiveScale() - ymin - 70;

	local IconPos = math.deg(math.atan2(ypos,xpos));

--KarmaChatDebug("Minimap: IconPos = " .. IconPos .. " from (x, y) = (" .. xpos .. ", " .. ypos .. ")");

	MinimapSetPosFromAngle(IconPos);
	if (store) then
		Karma_SetConfigPerChar(KARMA_CONFIG_MINIMAPPOS, IconPos);
	end
end

function	Karma_MinimapIconFrame_TooltipShow()
	if not KARMA_Minimap_Tooltip_Hide then
		GameTooltip:SetOwner(Karma_MinimapIconFrame, "ANCHOR_BOTTOMLEFT");

		GameTooltip:AddLine(KARMA_WINEL_TITLE);

		local	text, key, iPos;
		text = KARMA_WINEL_MINIMENU_TOOLTIP1;
		key  = GetBindingKey("KARMAWINDOW");
		if (key) and (key ~= "") then
			-- un-caps modifiers
			key = string.reverse(key);
			iPos = strfind(key, "-", 1, true);
			if (iPos) then
				key = strsub(key, 1, iPos) .. strlower(strsub(key, iPos + 1));
			end
			key = string.reverse(key);

			text = text .. " (" .. key .. ")";
		end
		GameTooltip:AddLine(text,.9,.9,.9);
		local	text, key;
		text = KARMA_WINEL_MINIMENU_TOOLTIP2;
		key  = GetBindingKey("KARMAWINDOW2");
		if (key) and (key ~= "") then
			-- un-caps modifiers
			key = string.reverse(key);
			iPos = strfind(key, "-", 1, true);
			if (iPos) then
				key = strsub(key, 1, iPos) .. strlower(strsub(key, iPos + 1));
			end
			key = string.reverse(key);

			text = text .. " (" .. key .. ")";
		end
		GameTooltip:AddLine(text,.9,.9,.9);
		GameTooltip:AddLine(KARMA_WINEL_MINIMENU_TOOLTIP3,.9,.9,.9);

		local targetname, targetserver = UnitName("target");
		if (targetserver and (targetserver ~= "")) then
			targetname = targetname .. "@" .. targetserver;
		end
		if (targetname ~= nil) then
			if (UnitFactionGroup("player") == UnitFactionGroup("target") and UnitIsPlayer("target")) then
				local oMember = Karma_MemberList_GetObject(targetname);
				if (oMember ~= nil) then
					local	red, green, blue = Karma_MemberList_GetColors(targetname);
					local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
					local	sKarma;
					if (bModified) then
						sKarma = "*" .. iKarma;
					else
						sKarma = iKarma;
					end
					local	sNote = Karma_MemberObject_GetNotes(oMember);
					if (sNote ~= "") then
						GameTooltip:AddLine(targetname .. KARMA_WINEL_FRAG_COLONSPACE .. sKarma .. KARMA_WINEL_FRAG_SPACE .. KARMA_WINEL_TITLE, red, green, blue);
						local	sExtract = KarmaModuleLocal.Helper.ExtractHeader(sNote);
						GameTooltip:AddLine(sExtract,.8,.8,.8,1);
					elseif (iKarma ~= 50) then
						GameTooltip:AddLine(targetname .. KARMA_WINEL_FRAG_COLONSPACE .. sKarma .. KARMA_WINEL_FRAG_SPACE .. KARMA_WINEL_TITLE, red, green, blue);
					end
				end
			end
		end

		GameTooltip:Show();
	end
end

function	Karma_MinimapIconFrame_TooltipHide()
	KARMA_Minimap_Tooltip_Hide = false;
	GameTooltip:Hide();
end

function	Karma_MinimapIconFrame_Clicked(arg1)
	if (arg1 == "LeftButton") then
		Karma_ToggleWindow();
	elseif (arg1 == "MiddleButton") then
		Karma_ToggleWindow2();
	elseif (arg1 == "RightButton") then
		-- what do we want here... definitely Karma++/--
		ToggleDropDownMenu(1, nil, Karma_Minimap_Menu, this, 30, 30);
		KARMA_Minimap_Tooltip_Hide = true;
		GameTooltip:Hide();
	else
		KarmaChatDebug("Minimap icon: clicked " .. arg1 .. " (unhandled)");
	end
end

local KARMA_MINIMAP_MENU_DROPDOWN = {
	[1] = {sName = KARMA_WINEL_INCREASE, iCommand = 503, bMemberOnly = true },
	[2] = {sName = KARMA_WINEL_DECREASE, iCommand = 497, bMemberOnly = true },
	[3] = {sName = KARMA_WINEL_MINIMENU_KARMACHANGE, iCommand = -1, bMemberOnly = true },
	[4] = {sName = KARMA_WINEL_MINIMENU_KARMAADDCHAR, iCommand = 100, bMemberOnly = false },
	[5] = {sName = KARMA_WINEL_MINIMENU_KARMASELCHAR, iCommand = 102, bMemberOnly = true },
	[6] = {sName = KARMA_WINEL_MINIMENU_KARMADELCHAR, iCommand = 101, bMemberOnly = true },
};

local KARMA_MINIMAP_MENUSUBSUBGOOD_DROPDOWN = {
	[1] = {sName = KARMA_WINEL_REASON_SKILL},
	[2] = {sName = KARMA_WINEL_REASON_HELP_KILL},
	[3] = {sName = KARMA_WINEL_REASON_HELP_INFO},
	[4] = {sName = KARMA_WINEL_REASON_HELP_ORGANIZE},
	[5] = {sName = KARMA_WINEL_REASON_MANNERS_UNCATEGORIZED},
	[6] = {sName = KARMA_WINEL_REASON_MANNERS_MODEST},
	[7] = {sName = KARMA_WINEL_REASON_MANNERS_POLITE},
	[8] = {sName = KARMA_WINEL_REASON_MANNERS_GENEROUS},
	[9] = {sName = KARMA_WINEL_REASON_MANNERS_GRACIOUS},
};

local KARMA_MINIMAP_MENUSUBSUBEVIL_DROPDOWN = {
	[1] = {sName = KARMA_WINEL_REASON_NINJA},
	[2] = {sName = KARMA_WINEL_REASON_KSER},
	[3] = {sName = KARMA_WINEL_REASON_SKILL},
	[4] = {sName = KARMA_WINEL_REASON_BOT},
	[5] = {sName = KARMA_WINEL_REASON_MANNERS_UNCATEGORIZED},
	[6] = {sName = KARMA_WINEL_REASON_MANNERS_CONCEITED},
	[7] = {sName = KARMA_WINEL_REASON_MANNERS_RUDE},
	[8] = {sName = KARMA_WINEL_REASON_MANNERS_SCAM},
	[9] = {sName = KARMA_WINEL_REASON_MANNERS_DRAMAQUEEN},
	[10] = {sName = KARMA_WINEL_REASON_SPAM_UNCATEGORIZED},
	[11] = {sName = KARMA_WINEL_REASON_SPAM_ALLCAPS},
	[12] = {sName = KARMA_WINEL_REASON_SPAM_WRONG_CHANNEL},
	[13] = {sName = KARMA_WINEL_REASON_SPAM_SPEED},
};

local	MenuTargetNameIndirect = nil;
local	MenuTargetNameSource = nil;
local	MenuTargetName = nil;
local	MenuTargetValid = false;

function	Karma_MinimapMenu_Initialize(self, level)
	Karma_WhoAmIInit();
	local	sPlayerFaction = UnitFactionGroup("player");
	local	sName, sServer = UnitName("target");
	if ((sName == WhoAmI) or sServer and (sServer ~= "")) then
		sName = nil;
	end

	local	targetname = sName;
	local	HaveValidTarget, bIsMember = false, false;
	if (targetname ~= nil) then
		if (sPlayerFaction == UnitFactionGroup("target") and UnitIsPlayer("target")) then
			HaveValidTarget = true;
			bIsMember = (Karma_MemberList_GetObject(targetname) ~= nil);
		end
	end

	MenuTargetValid = HaveValidTarget;
	if (targetname == nil) then
		targetname = MenuTargetNameIndirect;
		HaveValidTarget = targetname ~= nil;
		bIsMember = (Karma_MemberList_GetObject(targetname) ~= nil);
	end

	local	info;
	if (level == 1) then
		MenuTargetName = targetname;

		info = {};
		if (HaveValidTarget) then
			info.text = KARMA_WINEL_TITLE .. KARMA_WINEL_MINIMENU_TARGETIS .. targetname;
		else
			info.text = KARMA_WINEL_TITLE .. KARMA_WINEL_MINIMENU_TARGETNONE;
		end
		if (MenuTargetNameIndirect and (MenuTargetNameIndirect ~= targetname)) then
			info.text = info.text .. "\n|cFFFF6060(indirect target overwritten)|r";
		end

		info.isTitle = 1;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info);

		for i = 1, getn(KARMA_MINIMAP_MENU_DROPDOWN) do
			info = {};
			info.text = KARMA_MINIMAP_MENU_DROPDOWN[i].sName;
			info.notCheckable = 1;

			info.func = Karma_MinimapMenu_OnSelect;
			info.arg1 = KARMA_MINIMAP_MENU_DROPDOWN[i].iCommand;
			info.arg2 = targetname;

			if (info.arg1 == -1) then
				info.hasArrow = 1;
			end

			if (KARMA_MINIMAP_MENU_DROPDOWN[i].bMemberOnly ~= nil) then
				if (KARMA_MINIMAP_MENU_DROPDOWN[i].bMemberOnly ~= bIsMember) then
					info.disabled = 1;
				end
			end

			UIDropDownMenu_AddButton(info);
		end

		info = {};
		info.text = "------------";
		info.notCheckable = 1;
		info.notClickable = 1;
		info.justifyH = "CENTER";
		UIDropDownMenu_AddButton(info);

		info = {};
		info.text = "Target from chat...";
		info.value = "chat";
		info.notCheckable = 1;
		info.hasArrow = 1;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.text = "Target from mouseover...";
		info.value = "mouseover";
		info.notCheckable = 1;
		info.hasArrow = 1;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.text = "Target from history...";
		info.value = "history";
		info.notCheckable = 1;
		info.hasArrow = 1;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.text = "Reset target";
		info.notCheckable = 1;
		info.func = Karma_MinimapMenu_OnSelect;
		info.arg1 = 200;
		info.arg2 = 0;
		UIDropDownMenu_AddButton(info);

		info = {};
		info.text = "------------";
		info.notCheckable = 1;
		info.notClickable = 1;
		info.justifyH = "CENTER";
		UIDropDownMenu_AddButton(info);

		info = {};
		info.text = TEXT(CANCEL);
		info.notCheckable = 1;
		info.func = Karma_MinimapMenu_OnSelect;
		info.arg1 = 0;
		info.arg2 = nil;
		UIDropDownMenu_AddButton(info);

		UIDropDownMenu_SetAnchor(this);
	elseif (level == 2) and (MenuTargetName == targetname) then
		-- Submenu
		-- choices for setting indirect menu targets
		if (UIDROPDOWNMENU_MENU_VALUE == "chat") then
			if (KarmaModuleLocal.ChatRememberList[1] ~= nil) then
				local	oKey = {};
				for i = 1, KarmaModuleLocal.ChatRememberCount do
					local	Value = KarmaModuleLocal.ChatRememberList[i];
					if (Value) then
						oKey[i] = { Key = i, Value = Value.Time };
					end
				end

				KOH.GenericSort(oKey, function(a, b) return a.Value < b.Value end);

				local	k, v;
				for k, v in pairs(oKey) do
					local	Value = KarmaModuleLocal.ChatRememberList[v.Key];

					info = {};
					info.text = Value.Name;
					if (Value.ClassEN) then
						local oColor = RAID_CLASS_COLORS[Value.ClassEN];
						if (oColor) then
							info.text = string.format("\124cFF%.2X%.2X%.2X", oColor.r*255, oColor.g*255, oColor.b*255) .. info.text .. "\124r";
						end
					elseif (Value.Class) then
					end
					info.text = info.text .. " (" .. strsub(Value.Faction or "?", 1, 1) .. ")";
					info.notCheckable = 1;
					if (sPlayerFaction == Value.Faction) then
						info.value = { Source = "chat", Key = v.Key };
						info.func = Karma_MinimapMenu_OnSelect;
						info.arg1 = 201;
						info.arg2 = Value.Name;
						info.hasArrow = 1;
					else
						info.disabled = 1;
					end
					UIDropDownMenu_AddButton(info, level);
				end
			end
		elseif (UIDROPDOWNMENU_MENU_VALUE == "mouseover") then
			if (KarmaModuleLocal.MouseOverKeepList[1] ~= nil) then
				local	oKey = {};
				for i = 1, KarmaModuleLocal.MouseOverKeepCount do
					local	Value = KarmaModuleLocal.MouseOverKeepList[i];
					if (Value) then
						oKey[i] = { Key = i, Value = Value.Time };
					end
				end

				KOH.GenericSort(oKey, function(a, b) return a.Value < b.Value end);

				local	k, v;
				for k, v in pairs(oKey) do
					local	Value = KarmaModuleLocal.MouseOverKeepList[v.Key];

					info = {};
					info.text = Value.Name;
					if (Value.ClassEN) then
						local oColor = RAID_CLASS_COLORS[Value.ClassEN];
						if (oColor) then
							info.text = string.format("\124cFF%.2X%.2X%.2X", oColor.r*255, oColor.g*255, oColor.b*255) .. info.text .. "\124r";
						end
					elseif (Value.Class) then
						local ClassID = Karma_ClassToID(Value.Class);
						if  (ClassID < 0) then
							ClassID = - ClassID;
						end
						local	sClassWOGender = Karma_IDToClass(ClassID);
						local	r, g, b = Karma_ClassMToColor(sClassWOGender);
						info.text = string.format("\124cFF%.2X%.2X%.2X", r*255, g*255, b*255) .. info.text .. "\124r";
					end
					info.text = info.text .. " (" .. strsub(Value.Faction or "?", 1, 1) .. ")";
					info.notCheckable = 1;
					if (sPlayerFaction == Value.Faction) then
						info.value = { Source = "mouseover", Key = v.Key };
						info.func = Karma_MinimapMenu_OnSelect;
						info.arg1 = 202;
						info.arg2 = Value.Name;
						info.hasArrow = 1;
					else
						info.disabled = 1;
					end
					UIDropDownMenu_AddButton(info, level);
				end
			end
		elseif (UIDROPDOWNMENU_MENU_VALUE == "history") then
			local	iMax = KarmaModuleLocal.Raid.iIndexHistory;
			local	oHistories = KarmaModuleLocal.Raid.HistoryTables;
			local	oHistory = oHistories[1];
			if ((iMax > 1) or (oHistory ~= nil)) then
				local	i;
				for i = 1, iMax do
					oHistory = oHistories[i];
					if (oHistory ~= nil) then
						info = {};
						info.text = i .. ": " .. date("%H:%M", oHistory.__Start) .. " => " .. date("%H:%M", oHistory.__End or time());
						info.value = { Source = "history", Set = i };
						info.notCheckable = 1;
						info.hasArrow = 1;
						UIDropDownMenu_AddButton(info, level);
					end
				end
			end
		elseif (HaveValidTarget and (MenuTargetName == targetname)) then
			local values;
			values = {};
			values = { 1, 2, 5, 10 };
			info = {};
			info.text = KARMA_WINEL_MINIMENUSUB_INCREASE;
			info.notCheckable = 1;
			info.notClickable = 1;
			UIDropDownMenu_AddButton(info, 2);

			for i = 1, getn(values) do
				local	value = values[i];

				info = {};
				info.text = KARMA_WINEL_MINIMENUSUB_PLUS .. value;
				info.func = Karma_MinimapMenu_OnSelect;
				info.notCheckable = 1;
				info.hasArrow = 1;
				info.value = 500 + value;
				info.arg1 = 500 + value;
				info.arg2 = targetname;
				UIDropDownMenu_AddButton(info, 2);
			end

			info = {};
			info.text = KARMA_WINEL_MINIMENUSUB_DECREASE;
			info.notCheckable = 1;
			info.notClickable = 1;
			UIDropDownMenu_AddButton(info, 2);

			for i = 1, getn(values) do
				local	value = values[i];

				info = {};
				info.text = KARMA_WINEL_MINIMENUSUB_MINUS .. value;
				info.func = Karma_MinimapMenu_OnSelect;
				info.notCheckable = 1;
				info.hasArrow = 1;
				info.value = 500 - value;
				info.arg1 = 500 - value;
				info.arg2 = targetname;
				UIDropDownMenu_AddButton(info, 2);
			end
		end
	elseif (level == 3) then
		if (type(UIDROPDOWNMENU_MENU_VALUE) == "table") then
			local	oData = UIDROPDOWNMENU_MENU_VALUE;
			if (oData.Source == "chat") then
				local	Value = KarmaModuleLocal.ChatRememberList[oData.Key];
				if (Value.Messages) then
					local	iCnt, i = #Value.Messages;
					for i = 1, iCnt do
						local	sMsg = Value.Messages[i].Message;
						local	sLen = KarmaObj.UTF8.LenInChars(sMsg);
						if (sLen > 40) then
							if (sLen > 80) then
								sMsg = KarmaObj.UTF8.SubInChars(sMsg, 1, 40) .. "\n_________" .. KarmaObj.UTF8.SubInChars(sMsg, 41, 77) .. "...";
							else
								sMsg = KarmaObj.UTF8.SubInChars(sMsg, 1, 40) .. "\n_________" .. KarmaObj.UTF8.SubInChars(sMsg, 41);
							end
						end

						info = {};
						info.text = date("%H:%M:%S ", Value.Messages[i].At) .. sMsg;
						info.func = Karma_MinimapMenu_OnSelect;
						info.arg1 = 205;
						info.arg2 = { Source = oData.Source, Key = oData.Key, Message = i };
						info.notCheckable = 1;
						UIDropDownMenu_AddButton(info, level);
					end
				end
			end
			if (oData.Source == "mouseover") then
				local	Value = KarmaModuleLocal.MouseOverKeepList[oData.Key];

				info = {};
				info.text = date("%H:%M:%S ", Value.Time) .. "Seen in " .. Value.Zone;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
			end
			if (oData.Source == "history") then
				local	oHistories = KarmaModuleLocal.Raid.HistoryTables;
				local	oHistory = oHistories[oData.Set];
				if (oHistory ~= nil) then
					local	iTotal, k, v = (oHistory.__End or time()) - oHistory.__Start;
					for k, v in pairs(oHistory) do
						if ((k ~= "__Start") and (k ~= "__End") and (k ~= WhoAmI)) then
							local	iLeft = v.Left or time();
							local	iTimeInRaid = iLeft - v.JoinedFirst - v.Sideline;

							info = {};
							info.text = k;		-- TODO: class color, Karma rating
							info.text = info.text .. ": " .. date("%H:%M", v.JoinedFirst) .. " => " .. date("%H:%M", v.Left or time()) .. format(" (%.2f%%)", 100 * iTimeInRaid / iTotal);
							info.notCheckable = 1;
							UIDropDownMenu_AddButton(info, level);
						end
					end
				end
			end
		end

		if ((type(UIDROPDOWNMENU_MENU_VALUE) == "number") and HaveValidTarget and (MenuTargetName == targetname)) then
			-- Subsubmenu: parent selection required!
			info = {};
			info.text = KARMA_WINEL_REASON_NONE;
			info.notCheckable = 1;
			info.func = Karma_MinimapMenu_OnSelect;
			info.arg1 = 0;
			info.arg2 = nil;
			UIDropDownMenu_AddButton(info, 3);

			local	ParentID = UIDROPDOWNMENU_MENU_VALUE;
			local	Menu = nil;
			if (ParentID >= 500) then
				Menu = KARMA_MINIMAP_MENUSUBSUBGOOD_DROPDOWN;
			else
				Menu = KARMA_MINIMAP_MENUSUBSUBEVIL_DROPDOWN;
			end
			for i = 1, getn(Menu) do
				info = {};
				info.text = Menu[i].sName;
				info.notCheckable = 1;

				info.func = Karma_MinimapMenu_OnSelect;
				info.arg1 = i * 1000 + ParentID;
				info.arg2 = targetname;

				if ((info.arg1 > 0) or (info.arg1 == -1)) and (HaveValidTarget == false) then
					info.disabled = 1;
					info.arg1 = -2;
				else
					info.disabled = nil;
				end

				UIDropDownMenu_AddButton(info, 3);
			end

			info = {};
			info.text = "------------";
			info.notCheckable = 1;
			info.notClickable = 1;
			info.justifyH = "CENTER";
			UIDropDownMenu_AddButton(info, 3);

			info = {};
			info.text = TEXT(CANCEL);
			info.notCheckable = 1;
			info.func = Karma_MinimapMenu_OnSelect;
			info.arg1 = 0;
			if (this:GetParent() ~= nil) then
				ParentID =  UIDROPDOWNMENU_MENU_VALUE;
				-- KarmaChatDebug("Karma_MinimapMenu_Initialize(3): ParentID = " .. Karma_NilToString(ParentID));
			end
			info.arg2 = nil;
			UIDropDownMenu_AddButton(info, 3);
		end
	end
end

function Karma_MinimapMenu_OnSelect(self, arg1, arg2)
	CloseDropDownMenus();
	if (arg1 ~= nil) then
		if (arg2 == nil) then
			-- KarmaChatDebug("Karma_MinimapMenu_OnSelect: Action " .. arg1);
			if (arg1 == 0) then
				CloseDropDownMenus();
			end
		else
			local noteSel = math.floor(arg1 / 1000);
			arg1 = arg1 % 1000;

			KarmaChatDebug("Karma_MinimapMenu_OnSelect: Action " .. arg1 .. "/" .. noteSel .. " on target " .. arg2);

			local note = nil;
			if (noteSel > 0) then
				if (arg1 > 500) then
					note = KARMA_WINEL_FRAG_PLUS .. (arg1 - 500) .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MINIMAP_MENUSUBSUBGOOD_DROPDOWN[noteSel].sName;
				else
					note = (arg1 - 500) .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MINIMAP_MENUSUBSUBEVIL_DROPDOWN[noteSel].sName;
				end
			end

			if (arg1 >= 400) then
				-- KarmaChatDebug("Karma_MinimapMenu_OnSelect: Action " .. arg1 .. " on target " .. arg2 .. " with note " .. Karma_NilToString(note));
				Karma_ChangeKarma(arg2, false, arg1 - 500, note);
			elseif (arg1 == 100) then
				-- if target, add directly, otherwise regular add
				local	sTargetName;
				if (MenuTargetValid) then
					local	sTargetServer;
					sTargetName, sTargetServer = UnitName("target");
					if (sTargetServer and (sTargetServer ~= "")) then
						sTargetName = sTargetName .. "@" .. sTargetServer;
					end
				end
				if (sTargetName and (sTargetName == arg2)) then
					Karma_MemberList_Add(arg2);
					-- Karma_MemberList_Update(arg2, level, class, race, guild);
					Karma_MemberList_Update(arg2, UnitLevel("target"), UnitClass("target"), UnitRace("target"));
					Karma_UpdateMember(args2);
					if (KARMA_CURRENTMEMBER == nil) then
						Karma_SetCurrentMember(arg2);
					end
				else
					local	args = { [2] = arg2 };
					Karma_Command_AddMember_Insert(args);
					KarmaChatSecondaryFallbackDefault("Queued /who to add " .. arg2 .. " to the list of known players.");
				end
			elseif (arg1 == 101) then
				if (arg2 == KARMA_CURRENTMEMBER) then
					Karma_SetCurrentMember(nil);
				end;
				Karma_MemberList_Remove(arg2);
				Karma_MemberList_ResetMemberNamesCache();
			elseif (arg1 == 102) then
				Karma_SetCurrentMember(arg2);
			elseif (arg1 == 200) then
				if (MenuTargetNameIndirect) then
					KarmaChatSecondaryFallbackDefault("Indirect target " .. MenuTargetNameIndirect .. " has been reset.");
					MenuTargetNameIndirect = nil;
				end
			elseif (arg1 == 201) then
				MenuTargetNameSource = "chat";
				MenuTargetNameIndirect = arg2;
				if (MenuTargetNameIndirect) then
					KarmaChatSecondaryFallbackDefault("Indirect target is now " .. MenuTargetNameIndirect .. " (from chat).");
				end
			elseif (arg1 == 202) then
				MenuTargetNameSource = "mouseover";
				MenuTargetNameIndirect = arg2;
				if (MenuTargetNameIndirect) then
					KarmaChatSecondaryFallbackDefault("Indirect target is now " .. MenuTargetNameIndirect .. " (from mouseover).");
				end
			end
		end
	end
end

---
---- Tooltips 
---
local	Karma_ObjectIsTipData =
	{
		["KarmaOptionsWindow_ColorSpace_Enable_Checkbox"] = KARMA_TOOLTIPS["COLORSPACE_ENABLE_CHECKBOX"],

		["KarmaOptionWindow_DBClean_AutoClean_Checkbox"] = KARMA_WINEL_AUTOCLEANCHECKBOXTOOLTIP,
		["KarmaOptionWindow_DBClean_KeepIfNote_Checkbox"] = KARMA_WINEL_DBCLEANKEEPIFNOTETOOLTIP,
		["KarmaOptionWindow_DBClean_RemovePvPJoins_Checkbox"] = KARMA_WINEL_DBCLEANREMOVEPVPJOINSTOOLTIP,
		["KarmaOptionWindow_DBClean_RemoveXServer_Checkbox"] = KARMA_WINEL_DBCLEANREMOVEXSERVERTOOLTIP,
		["KarmaOptionWindow_DBClean_KeepIfKarma_Checkbox"] = KARMA_WINEL_DBCLEANKEEPIFKARMATOOLTIP,
		["KarmaOptionWindow_DBClean_KeepIfQListThres_Editbox"] = KARMA_WINEL_DBCLEANKEEPIFQUESTNUMTOOLTIP,
		["KarmaOptionWindow_DBClean_KeepIfRListThres_Editbox"] = KARMA_WINEL_DBCLEANKEEPIFREGIONNUMTOOLTIP,
		["KarmaOptionWindow_DBClean_KeepIfZListThres_Editbox"] = KARMA_WINEL_DBCLEANKEEPIFZONENUMTOOLTIP,
		["KarmaOptionWindow_DBClean_IgnorePVPZones_Checkbox"] = KARMA_WINEL_DBCLEANIGNOREPVPZONESTOOLTIP,

		["KarmaOptionWindow_Other_ContextMenuDeactivate_Checkbox"] = KARMA_WINEL_CONTEXTMENUDEACTIVATE_TOOLTIP,
		["KarmaOptionWindow_Other_DBSparseTables_Checkbox"] = KARMA_WINEL_DBSPARSETABLES_TOOLTIP,

		["KarmaOptionWindow_DBClean_Test_Button"] = KARMA_WINEL_DBCLEAN_TESTTOOLTIP,

		-- TODO: add Filter-Tooltip
	};

local	Karma_ObjectIsTipExtraData =
	{
		["KarmaOptionWindow_DBClean_AutoClean_Checkbox"] = KARMA_WINEL_AUTOCLEANCHECKBOXTOOLTIPEXTRA,
	};

local	function	FillTooltip(fieldoftext)
	if (type(fieldoftext) == "table") then
		local	first = true;
		for i, text in pairs(fieldoftext) do
			if first then
				GameTooltip:AddLine(KARMA_WINEL_TITLE .. KARMA_WINEL_FRAG_COLONSPACE .. text);
				first = false;
			else
				GameTooltip:AddLine(text,.9,.9,.9);
			end
		end
	elseif (type(fieldoftext) == "string") then
		GameTooltip:AddLine(fieldoftext, 1, 1, 0);
	else
		KarmaChatDebug("Help text in unrecognized format!");
	end
end

function Karma_FromTable_Tooltip()
	local	Name = this:GetName();
	if (Karma_ObjectIsTipData[Name]) then
		GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT");

		FillTooltip(Karma_ObjectIsTipData[Name]);
		if (Karma_ObjectIsTipExtraData[Name]) then
			GameTooltip:AddLine(Karma_ObjectIsTipExtraData[Name],.9,.6,.4);
		end

		GameTooltip:Show();
	else
		KarmaChatDebug("Missing help text for object <" .. Name .. ">!");
	end
end

---
---- Option window: initialization
---
function	KarmaOptionsWindow_OnLoad(self)
	-- hook it to Addons - panel (okay/cancel do nothing for us)
	self.name   = KARMA_ITSELF;
	InterfaceOptions_AddCategory(self);
end

function	KarmaOptionsWindow_Show()
	if (not KarmaOptionsWindow:IsVisible()) then
		InterfaceOptionsFrame_OpenToCategory(KarmaOptionsWindow);
	end
end

---
---- Option window: categories
---
local	KARMA_OPTIONWINDOW_CAT = {};

function	KarmaObj.UI.OptWnd.CatAdd(frame, id)
	KOH.TableInit(KARMA_OPTIONWINDOW_CAT, id);
	tinsert(KARMA_OPTIONWINDOW_CAT[id], frame);
end

function KarmaOptionWindowCategoriesHideAll()
	local	id, oCat, key, frame;
	for id, oCat in pairs(KARMA_OPTIONWINDOW_CAT) do
		for key, frame in pairs(oCat) do
			frame:Hide();
		end
	end
end

local	Karma_OptionWindowCatCount = 5;

function KarmaOptionWindowCategory_OnClick(btnobj)
	KarmaOptionWindowCategoriesHideAll();

	local	id, oCat;
	for id, oCat in pairs(KARMA_OPTIONWINDOW_CAT) do
		getglobal("KarmaOptionWindowCategory_Button" .. id):UnlockHighlight();
	end
	btnobj:LockHighlight();

	local	btnid = btnobj:GetID();
	if (KARMA_OPTIONWINDOW_CAT[btnid]) then
		local	key, value;
		for key, value in pairs(KARMA_OPTIONWINDOW_CAT[btnid]) do
			value:Show();
		end
	end
end

---
---- Main window: Filter stuff
---
function	Karma_ParseFilter(F)
	local Pattern, Name, C, LF, LT, KF, KT, JoinedAfter, JoinedBefore, Notes, Pub, Guild, Instance;
	if F ~= nil then
		-- force copy
		F = strsub(F, 1)
		while F ~= "" do
			local	SpacePos = strfind(F, " ", 1);
			local	FSub = nil;
			if SpacePos ~= nil then
				FSub = strsub(F, 1, SpacePos - 1);
				F = strsub(F, SpacePos + 1);
			else
				FSub = F;
				F = "";
			end

			local	Type, Value;
			if strsub(FSub, 2, 2) == "-" then
				Type = strsub(FSub, 1, 1);
				Value = strsub(FSub, 3);
				-- if Value starts with a "...
				if (Value and (strsub(Value, 1, 1) == "\"")) then
					-- ... find a matching " afterwards, followed by space or end of line
					local	iMatch = strfind(F, "\"");
					if (iMatch and ((iMatch == strlen(F)) or (strsub(F, iMatch + 1, iMatch + 1) == " "))) then
						Value = Value .. " " .. strsub(F, 1, iMatch);
						F = strsub(F, iMatch + 1);
					end

					-- if it's properly quoted, remove the quotes
					local	iValLen = strlen(Value);
					if (strsub(Value, iValLen, iValLen) == "\"") then
						Value = strsub(Value, 2, iValLen - 1);
					end
				end
			else
				Type = "n";
				Value = FSub;
			end

			if (Value ~= "") then
				if Type == "p" then
					Pattern = Value;
				elseif Type == "n" then
					Name = Value;
				elseif Type == "c" then
					C = Value;
				elseif Type == "i" then
					Notes = Value;
				elseif Type == "u" then
					Pub = Value;
				elseif Type == "a" then
					JoinedAfter = tonumber(Value);
				elseif Type == "b" then
					JoinedBefore = tonumber(Value);
				elseif Type == "g" then
					Guild = Value;
				elseif Type == "r" then
					Instance = Value;
				else
					local	ValueFrom = Value;
					local	ValueTo   = Value;
					local	MinusPos  = strfind(Value, "-", 1);
					if MinusPos ~= nil then
						ValueFrom = strsub(Value, 1, MinusPos - 1);
						ValueTo   = strsub(Value, MinusPos + 1);
					end
						
					if Type == "l" then
						LF = ValueFrom;
						LT = ValueTo;
					end
					if Type == "k" then
						KF = ValueFrom;
						KT = ValueTo;
					end
				end
			end
		end

		if (Name == "") then
			Name = nil;
		end
		if (Name) then
			Name = KarmaObj.StringInitialCapitalized(Name);
		end
		if (C == "") then
			C = nil;
		end
		if (LF == "") then
			LF = nil;
		end
		if (LT == "") then
			LT = nil;
		end
		if (KF == "") then
			KF = nil;
		end
		if (KT == "") then
			KT = nil;
		end
		if (Notes == "") then
			Notes = nil;
		end
		if (Pub == "") then
			Pub = nil;
		end
		if (Guild == "") then
			Guild = nil;
		end
		if (Instance == "") then
			Instance = nil;
		end
	end

	return Pattern, Name, C, LF, LT, KF, KT, JoinedAfter, JoinedBefore, Notes, Pub, Guild, Instance;
end

function Karma_ExecuteFilter(CurrentFilter)
	local	cfPattern, cfName, cfClass, cfLevelFrom, cfLevelTo, cfKarmaFrom, cfKarmaTo,
		cfJoinedAfter, cfJoinedBefore, cfNotes, cfPublic, cfGuild, cfInstance = Karma_ParseFilter(CurrentFilter);
	if CurrentFilter ~= KARMA_Filter.Total then
		KARMA_Filter.Total = CurrentFilter;

--		KarmaChatDefault("Karma: Filter(N, C, L, V) = (" .. Karma_NilToString(cfName)
--			.. ", " .. Karma_NilToString(cfClass) .. ", " .. Karma_NilToString(cfLevel)
--			.. ", " .. Karma_NilToString(cfKarma));

		KARMA_Filter.Pattern = cfPattern;
		KARMA_Filter.Name = cfName;
		KARMA_Filter.Class = cfClass;
		KARMA_Filter.LevelFrom = tonumber(cfLevelFrom);
		KARMA_Filter.LevelTo = tonumber(cfLevelTo);
		KARMA_Filter.KarmaFrom = tonumber(cfKarmaFrom);
		KARMA_Filter.KarmaTo = tonumber(cfKarmaTo);
		KARMA_Filter.JoinedAfter = cfJoinedAfter;
		KARMA_Filter.JoinedBefore = cfJoinedBefore;
		KARMA_Filter.Notes = cfNotes;
		KARMA_Filter.Public = cfPublic;
		KARMA_Filter.Guild = cfGuild;
		KARMA_Filter.Instance = cfInstance;

		local	sDbg, k, v = "";
		for k, v in pairs(KARMA_Filter) do
			if (v ~= nil) then
				sDbg = sDbg .. " / " .. k .. " = <" .. v .. ">";
			end
		end
		if (sDbg ~= "") then
			KarmaChatDebug("Parsed: >> " .. strsub(sDbg, 4) .. " <<");
		end

		Karma_MemberList_ResetMemberNamesCache();
		KarmaWindow_UpdateMemberList();
	end
end

function KarmaWindow_FilterUpdateText()
	local	CurrentFilter = KarmaWindow_Filter_EditBox:GetText();
	if strlen(CurrentFilter) == 0 then
		CurrentFilter = nil;
	end

	Karma_ExecuteFilter(CurrentFilter);
end

function	KarmaObj.UI.Filter_Editbox_Tooltip(self, title, key, anchor)
	-- ANCHOR_BOTTOMLEFT: links unten
	if Karma_ShowTooltipHelp() and (type(KARMA_TOOLTIPS[key]) == "table") then
		if (anchor) then
			GameTooltip:SetOwner(self, anchor);
		else
			GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
		end
	
		GameTooltip:AddLine(KARMA_WINEL_TITLE .. KARMA_WINEL_FRAG_COLONSPACE .. title);
		local	bNextIsBrighter = false;
		for key, value in pairs(KARMA_TOOLTIPS[key]) do
			if (value == "") then
				bNextIsBrighter = true;
			else
				if (bNextIsBrighter) then
					GameTooltip:AddLine(value, 0.9, 0.9, 0.9);
					bNextIsBrighter = false;
				else
					GameTooltip:AddLine(value, 0.8, 0.8, 0.8);
				end
			end
		end
	
		GameTooltip:Show();
	end
end

function	Karma_FilterInit()
	if (KARMA_Filter.Total ~= nil) then
		if (KARMA_Filter.Name ~= nil) then
			KarmaFilterWindow_NameStarts_Editbox:SetText(KARMA_Filter.Name);
		end
		if (KARMA_Filter.Class ~= nil) then
			KarmaFilterWindow_Class_Editbox:SetText(KARMA_Filter.Class);
		end
		if (KARMA_Filter.LevelFrom ~= nil) then
			KarmaFilterWindow_LevelFrom_Editbox:SetText(KARMA_Filter.LevelFrom);
		end
		if (KARMA_Filter.LevelTo ~= nil) then
			KarmaFilterWindow_LevelTo_Editbox:SetText(KARMA_Filter.LevelTo);
		end
		if (KARMA_Filter.KarmaFrom ~= nil) then
			KarmaFilterWindow_KarmaFrom_Editbox:SetText(KARMA_Filter.KarmaFrom);
		end
		if (KARMA_Filter.KarmaTo ~= nil) then
			KarmaFilterWindow_KarmaTo_Editbox:SetText(KARMA_Filter.KarmaTo);
		end
		if (KARMA_Filter.JoinedAfter ~= nil) then
			if (KARMA_Filter.JoinedAfter < 0) then
				local	sText = tostring(- KARMA_Filter.JoinedAfter) .. " days ago";
				KarmaFilterWindow_JoinedAfter_Editbox:SetText(sText);
			elseif (KARMA_Filter.JoinedAfter > 1000000) then
				KarmaFilterWindow_JoinedAfter_Editbox:SetText(date(KARMA_DATEFORMAT, KARMA_Filter.JoinedAfter));
			end
		end
		if (KARMA_Filter.JoinedBefore ~= nil) then
			if (KARMA_Filter.JoinedBefore < 0) then
				local	sText = tostring(- KARMA_Filter.JoinedBefore) .. " days ago";
				KarmaFilterWindow_JoinedBefore_Editbox:SetText(sText);
			elseif (KARMA_Filter.JoinedBefore > 1000000) then
				KarmaFilterWindow_JoinedBefore_Editbox:SetText(date(KARMA_DATEFORMAT, KARMA_Filter.JoinedBefore));
			end
		end
		if (KARMA_Filter.Notes ~= nil) then
			KarmaFilterWindow_NotePrivate_Editbox:SetText(KARMA_Filter.Notes);
		end
		if (KARMA_Filter.Public ~= nil) then
			KarmaFilterWindow_NotePublic_Editbox:SetText(KARMA_Filter.Public);
		end
	end
end

function	Karma_FilterOk()
	local	StrToDate = function(Value)
			-- direct value: valid if negative, equals days ago
			local	Result = tonumber(Value);

			if (Result == nil) then
				-- "nnn days ago" -> -nnn
				Result = string.gsub(Value, "(%d+) days ago", "%1");
				if (Result) then
					Result = tonumber(Result);
					if (Result) then
						Result = - Result;
					end
				end
			end

			if ((Result == nil) or (type(Result) ~= "number") or (Result < - 3650) or ((Result >= 0) and (Result < 9000000))) then
				-- split at known delimiters (if any language uses other, need to adjust...)
				local	a1, a2, a3, x = strsplit(".", Value);
				if (a2 == nil) then
					a1, a2, a3, x = strsplit("-", Value);
					if (a2 == nil) then
						a1, a2, a3, x = strsplit("/", Value);
					end
				end

				-- yay, exactly 3 args
				if ((a3 ~= nil) and (x == nil)) then
					a1 = tonumber(a1);
					a2 = tonumber(a2);
					a3 = tonumber(a3);
				end

				if ((a1 ~= nil) and (a2 ~= nil) and (a3 ~= nil)) then
					local	a = { [1] = a1, [2] = a2, [3] = a3 };

					-- now we need to assign it to day, month, year in the same order as we would output it ourselves...
					local	d, m, y;

					local	PosArg, Max, Pos = {}, 0;
					Pos = strfind(KARMA_DATEFORMAT, "%d", 1, true);
					if (Pos) then
						PosArg[Pos] = "D";
						Max = math.max(Pos, Max);
					end
					Pos = strfind(KARMA_DATEFORMAT, "%m", 1, true);
					if (Pos) then
						PosArg[Pos] = "M";
						Max = math.max(Pos, Max);
					end
					Pos = strfind(KARMA_DATEFORMAT, "%Y", 1, true);
					if (Pos) then
						PosArg[Pos] = "Y";
						Max = math.max(Pos, Max);
					end
					Pos = 1;
					for x = 1, Max do
						if (PosArg[x]) then
							if (PosArg[x] == "D") then
								d = a[Pos];
								Pos = Pos + 1;
							elseif (PosArg[x] == "M") then
								m = a[Pos];
								Pos = Pos + 1;
							elseif (PosArg[x] == "Y") then
								y = a[Pos];
								Pos = Pos + 1;
							end
						end
					end

					-- got all assigned, try to convert only if in sensible ranges
					if ((d ~= nil) and (m ~= nil) and (y ~= nil)) then
						if ((d >= 1) and (d <= 31) and (m >= 1) and (m <= 12) and (y >= 2000)) then
							local	tValue = { year = y, month = m, day = d };
							Result = time(tValue);
						end
					end
				end
			end

			return Result;
		end

	local	NewTotal = "";
	local	Delimiter = "";
	local	Space = " ";

	local	text = KarmaFilterWindow_NameStarts_Editbox:GetText();
	if (text ~= "") then
		NewTotal = NewTotal .. Delimiter .. "n-" .. text;
		Delimiter = Space;
	end

	text = KarmaFilterWindow_NameContains_Editbox:GetText();
	if (text ~= "") then
		NewTotal = NewTotal .. Delimiter .. "p-" .. text;
		Delimiter = Space;
	end

	text = KarmaFilterWindow_Class_Editbox:GetText();
	if (text ~= "") then
		NewTotal = NewTotal .. Delimiter .. "c-" .. text;
		Delimiter = Space;
	end

	local	textFrom = KarmaFilterWindow_LevelFrom_Editbox:GetText();
	local	textTo = KarmaFilterWindow_LevelTo_Editbox:GetText();
	if (textFrom ~= "") or (textTo ~= "") then
		NewTotal = NewTotal .. Delimiter .. "l-" .. textFrom .. "-" .. textTo;
		Delimiter = Space;
	end

	textFrom = KarmaFilterWindow_KarmaFrom_Editbox:GetText();
	textTo = KarmaFilterWindow_KarmaTo_Editbox:GetText();
	if (textFrom ~= "") or (textTo ~= "") then
		NewTotal = NewTotal .. Delimiter .. "k-" .. textFrom .. "-" .. textTo;
		Delimiter = Space;
	end

	text = KarmaFilterWindow_JoinedAfter_Editbox:GetText();
	if (text ~= "") then
		local	iValue = StrToDate(text);
		if (iValue) then
			NewTotal = NewTotal .. Delimiter .. "a-" .. iValue;
			Delimiter = Space;
		end
	end

	text = KarmaFilterWindow_JoinedBefore_Editbox:GetText();
	if (text ~= "") then
		local	iValue = StrToDate(text);
		if (iValue) then
			NewTotal = NewTotal .. Delimiter .. "b-" .. iValue;
			Delimiter = Space;
		end
	end

	text = KarmaFilterWindow_NotePrivate_Editbox:GetText();
	if (text ~= "") then
		if (strfind(text, " ")) then
			text = "\"" .. text .. "\"";
		end
		NewTotal = NewTotal .. Delimiter .. "i-" .. text;
		Delimiter = Space;
	end

	text = KarmaFilterWindow_NotePublic_Editbox:GetText();
	if (text ~= "") then
		if (strfind(text, " ")) then
			text = "\"" .. text .. "\"";
		end
		NewTotal = NewTotal .. Delimiter .. "u-" .. text;
		Delimiter = Space;
	end

	KarmaWindow_Filter_EditBox:SetText(NewTotal);
end

function	KarmaModuleLocal.Command.VersionQuery(args)
	local	VerReq = args.VerReq;
	local	VerAudience = args.VerAudience;
	local	Skipped = true;
	KarmaChatDebug("Version request pending for <" .. VerAudience .. "> - checking...");
	if (KarmaModuleLocal.Version.Seen[VerAudience]) then
		if (KarmaModuleLocal.Version.Seen[VerAudience].Newer == 0) then	-- if someone announced newer, don't shout about being a lazy non-updater...
			if (KarmaModuleLocal.Version.Seen[VerAudience].Same == 0) or	-- either noone said anything yet?
			   (KarmaModuleLocal.Version.Seen[VerAudience].Older > 0) then	-- or they were all older versions: tell them
				KarmaChatDebug("Version requested, as noone said anything about a newer version in <" .. VerAudience .. ">");
				KarmaModuleLocal.Version.Seen[VerAudience].Same  = 0;
				KarmaModuleLocal.Version.Seen[VerAudience].Older = 0;
				SendAddonMessage("KARMA", VerReq, VerAudience);
				Skipped = false;
			else
				SkipReason = "Seen same: " .. KarmaModuleLocal.Version.Seen[VerAudience].Same .. " or no older: " .. KarmaModuleLocal.Version.Seen[VerAudience].Older;
			end
		else
			SkipReason = "Seen newer: " .. KarmaModuleLocal.Version.Seen[VerAudience].Newer;
		end
	else
		KarmaChatDebug("Unexpected audience: " .. VerAudience);
	end
	if (Skipped) then
		KarmaChatDebug("Version request for <" .. VerAudience .. "> skipped.");
	end
end

function	KarmaModuleLocal.Command.VersionQueryQueue(_VerReq, _VerAudience)
	local	oEntry = {};
	oEntry.At = GetTime() + 20 + random(10);
	oEntry.CmdList = {};
	oEntry.CmdList[1] = { sName = "VersionQuery", func = KarmaModuleLocal.Command.VersionQuery, args = { VerReq = _VerReq, VerAudience = _VerAudience } };

	Karma_CronQueue[#Karma_CronQueue + 1] = oEntry;
end

--
--
--
function	KarmaModuleLocal.Command.ChannelTest(args)
	if (args.sChan) then
		local	iChan = GetChannelName(args.sChan);
		if (iChan ~= 0) then
			local	oChanKarma = KarmaModuleLocal.Channels[0];
			if ((type(oChanKarma) ~= "table") or
			    (type(oChanKarma) == "table") and (oChanKarma.Number == nil)) then
				KarmaChatSecondaryFallbackDefault("Sending test message to channel " .. iChan .. ": #" .. args.sChan);
				SendChatMessage("Test!", "CHANNEL", nil, iChan);
			else
				KarmaChatSecondaryFallbackDefault("Channel #" .. args.sChan .. " already validated or rejected, not testing.");
			end
		else
			KarmaChatSecondaryFallbackDefault("Channel #" .. args.sChan .. " not yet joined. Can't test.");
		end
	end
end

function	KarmaModuleLocal.Command.ChannelAuto(args)
	local	sChan = Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME);
	if ((sChan ~= nil) and (sChan ~= "")) then
		local	oChannels = { GetChannelList() };
		local	k, v, bFound;
		bFound = false;
		for k, v in pairs(oChannels) do
			if ((type(v) == "string") and (sChan == v)) then
				bFound = true;
			end
		end

		if (not bFound) then
			KarmaChatSecondary("Auto-joining " .. sChan .. "...");
			JoinChannelByName(sChan, nil, DEFAULT_CHAT_FRAME:GetID());
		end

		local	i;
		for i = 1, NUM_CHAT_WINDOWS do
			RemoveChatWindowChannel(i, sChan);
		end

		local	oEntry = {};
		oEntry.At = GetTime() + 240 + random(120);
		oEntry.CmdList = {};
		oEntry.CmdList[1] = { sName = "ChannelTest", func = KarmaModuleLocal.Command.ChannelTest, args = { sChan = sChan} };

		Karma_CronQueue[#Karma_CronQueue + 1] = oEntry;
	end
end

function	KarmaModuleLocal.Command.ChannelAutoQueue()
	local	oEntry = {};
	oEntry.At = GetTime() + 20 + random(10);
	oEntry.CmdList = {};
	oEntry.CmdList[1] = { sName = "ChannelAutoJoinHide", func = KarmaModuleLocal.Command.ChannelAuto, args = {} };

	Karma_CronQueue[#Karma_CronQueue + 1] = oEntry;
end

--
--
--
function	KarmaModuleLocal.Command.xFactionRemindUpdate(args)
	KarmaChatDefault("There is cross-faction information for " .. args.iCount .. " players stored into " .. KARMA_ITSELF .. "'s hold. Transfer it into the main database with '" .. KARMA_CMDSELF .. " xupdate'!");
end

function	KarmaModuleLocal.Command.xFactionRemindUpdateQueue(_iCount)
	local	oEntry = {};
	oEntry.At = GetTime() + 30 + random(30);
	oEntry.CmdList = {};
	oEntry.CmdList[1] = { sName = "xFactionRemindUpdate", func = KarmaModuleLocal.Command.xFactionRemindUpdate, args = { iCount = _iCount} };

	Karma_CronQueue[#Karma_CronQueue + 1] = oEntry;
end

---
---- ChatMsg_AddOn: invisible inter-AddOn-communication
---
function	Karma_ChatMsg_AddOn(self, event, ...)
	local	arg1, arg2, arg3, arg4 = ...;
	Karma_WhoAmIInit();

	local	Msg = "ChatMsg_AddOn(" .. arg1 .. "): <" .. arg2 .. "> via " .. arg3;
	if (arg4 ~= nil) then
		Msg = Msg .. " from " .. arg4;
	end
	if (arg1 == "KARMA") and (arg4 == WhoAmI) then
		if (KarmaObj.UI.MsgAddOnForceHandling) then
			KarmaChatDebug(Msg .. " (from self, forced handling)");
		else
			KarmaChatDebug(Msg .. " (from self, no handling)");
		end
	end

	if (arg1 == "KARMA") and ((arg4 ~= WhoAmI) or KarmaObj.UI.MsgAddOnForceHandling) and
		((arg3 == "PARTY") or (arg3 == "WHISPER") or (arg3 == "GUILD") or (arg3 == "CHANNEL")) then

		if (KarmaObj.UI.MsgAddOnForceHandling) then
			KarmaObj.UI.MsgAddOnForceHandling = KarmaObj.UI.MsgAddOnForceHandling - 1;
			if (KarmaObj.UI.MsgAddOnForceHandling == 0) then
				KarmaObj.UI.MsgAddOnForceHandling = nil;
			end
		end

		KarmaChatDebug(Msg);

		if (KARMA_OtherInfos[arg4] == nil) then
			KARMA_OtherInfos[arg4] = {};
		end

		if (arg2) and (arg2 ~= "") then
			-- request?
			if (strsub(arg2, 1, 1) == "?") then
				-- version request
				if (strsub(arg2, 2) == "v") then
					SendAddonMessage("KARMA", "!v" .. KARMA_VERSION_TEXT, arg3, arg4);
				elseif (strsub(arg2, 2) == "v1") then
					SendAddonMessage("KARMA", "!v1:" .. KARMA_VERSION_TEXT .. ":" .. KARMA_VERSION_DATE, arg3, arg4);
				end

				-- player info request
				if (strsub(arg2, 2, 4) == "p1:") then
					local	sName = strsub(arg2, 5);
					local	oMember = Karma_MemberList_GetObject(sName);
					if (oMember) then
						-- Sharing: 0: never, 1: always, 2: via GUILD, 3: with trusted people only
						local	iKarma = Karma_GetConfig(KARMA_CONFIG.SHARE_ONREQ_KARMA);
						local	iPubNote = Karma_GetConfig(KARMA_CONFIG.SHARE_ONREQ_PUBLICNOTE);
						local	bTrustKarma, bTrustNote = false, false
						if (iKarma == 3) or (iPubNote == 3) then
							oRequester = Karma_MemberList_GetObject(arg4);
							if (oRequester and (oRequester[KARMA_DB_L5_RRFFM_SHARE_TRUST] ~= nil)) then
								local	iTrust = oRequester[KARMA_DB_L5_RRFFM_SHARE_TRUST];
								if (1 == bit.band(iTrust, 1)) then
									bTrustKarma = true;
								end
								if (2 == bit.band(iTrust, 2)) then
									bTrustNote = true;
								end
							end
						end

						local	sReply = "";

						if ((iKarma == 1) or
						    ((iKarma == 2) and (arg3 == "GUILD")) or
						    ((iKarma == 3) and bTrustKarma)) then
							sReply = sReply .. ":k" .. Karma_MemberObject_GetKarma(oMember);
						end

						if ((iPubNote == 1) or
						    ((iPubNote == 2) and (arg3 == "GUILD")) or
						    ((iPubNote == 3) and bTrustNote)) then
							local	sNote  = Karma_MemberObject_GetPublicNotes(oMember); 
							if (sNote and (sNote ~= "")) then
								if ((strsub(sNote, 1, 1) == "#") or strfind(sNote, ":")) then
									sNote = string.gsub(sNote, "#", "##");
									sNote = string.gsub(sNote, "!", "#!");
									sNote = string.gsub(sNote, ":", "#!#!");
									sNote = "#" .. sNote;
								end
								sReply = sReply .. ":np" .. sNote;
							end
						end

						-- *always* reply in WHISPER!
						if (sReply ~= "") then
							SendAddonMessage("KARMA", "!p1:" .. sName .. sReply, "WHISPER", arg4);
						end
					end
				end

				-- data exchange request
				if ((strsub(arg2, 2, 4) == "x1:") or (strsub(arg2, 2, 4) == "x2:")) then
					-- only in whisper and must be explicitly allowed
					if (arg3 == "WHISPER") and (KARMA_EXCHANGE.ENABLED_WITH == arg4) then
						local	sBucket, sBorder, sFlags;
						local	iVersion = tonumber(strsub(arg2, 3, 3));

						if (iVersion == 1) then
							sBorder = strsub(arg2, 5);
						elseif (iVersion == 2) then
							local	sDetails = strsub(arg2, 5);
							local	iPos = strfind(sDetails, ":");
							if (iPos) then
								sBorder = strsub(sDetails, 1, iPos - 1);
								sDetails = strsub(sDetails, iPos + 1); 
								local	iPos = strfind(sDetails, ":");
								if (iPos) then
									sFlags = strsub(sDetails, 1, iPos - 1);
								else
									sFlags = sDetails;
								end
							else
								sBorder = sDetails;
							end
							if (sFlags == nil) then
								sFlags = "";
							end
						end

						if (sBorder and (sBorder ~= "")) then
							sBucket = KarmaObj.NameToBucket(sBorder);
						else
							sBucket = "A";
							sBorder = "";
						end
	
						local	sReply = "!x" .. strsub(arg2, 3, 3) .. "+";
	
						local	lMembers = KarmaObj.DB.SF.MemberListGet(oFaction);
						if (lMembers) then
							local	MAXCOUNT = 5;
							local	oBucket = lMembers[sBucket];
							if (oBucket) then
								local	bSkipEmpty = false;
								local	bSkipUnchanged = false;
								local	bSkipUnjoined = false;
								if (iVersion >= 2) then
									-- Skip empty entries
									bSkipEmpty = (strfind(sFlags, "See ") ~= nil);
									-- Skip unchanged entries since
									iSkipUnchanged = string.match(sFlags, "Sues:(%d+) ");
									if (iSkipUnchanged) then
										iSkipUnchanged = tonumber(iSkipUnchanged);
									end
									bSkipUnchanged = (iSkipUnchanged ~= nil);
									-- Skip never joined entries
									bSkipUnjoined = (strfind(sFlags, "Snje ") ~= nil);
								end
								local	Found = (sBorder == "") or (strsub(sBorder, 2, 2) == "*");
								local	Count = 0;
								local	sName, oMember, bSkip;
								for sName, oMember in pairs(oBucket) do
									if (not Found) then
										Found = sName == sBorder;
									end
									if (Found) then
										if (Count < MAXCOUNT) then
											local	iKarma = Karma_MemberObject_GetKarma(oMember);
											local	sClass = Karma_MemberObject_GetClass(oMember);
											local	iClass = Karma_ClassToID(sClass);
											local	sNote  = Karma_MemberObject_GetPublicNotes(oMember); 
											if (sNote and (sNote ~= "")) then
												if ((strsub(sNote, 1, 1) == "#") or strfind(sNote, ":")) then
													sNote = string.gsub(sNote, "#", "##");
													sNote = string.gsub(sNote, "!", "#!");
													sNote = string.gsub(sNote, ":", "#!#!");
													sNote = "#" .. sNote;
												end
												sNote = ":np" .. sNote;
											else
												sNote = "";
											end
											local	sGUID = Karma_MemberObject_GetGUID(oMember);
											if (sGUID and (sGUID ~= "")) then
												sGUID = ":id" .. strsub(sGUID, -4);
											else
												sGUID = "";
											end
											local	iTotalTime = Karma_MemberObject_GetTotalTimePlayedSummedUp(oMember);

											bSkip = false;
											if (bSkipEmpty) then
												bSkip = bSkip or ((iKarma == 50) and (iTotalTime == 0) and (sNote == ""));
											end

											if (not bSkip) then
												local	sAdd =     ":p" .. sName
														.. sGUID
														.. ":l" .. Karma_MemberObject_GetLevel(oMember)
														.. ":k" .. iKarma
														.. sNote
														.. ":ci" .. iClass
														.. ":rs" .. Karma_MemberObject_GetRace(oMember)
														.. ":tt" .. math.floor(iTotalTime);
												-- looong public note?
												if (strlen(sAdd) >= 200) then
													sAdd =     ":p" .. sName
														.. sGUID
														.. ":l" .. Karma_MemberObject_GetLevel(oMember)
														.. ":k" .. iKarma
														.. ":ci" .. iClass
														.. ":rs" .. Karma_MemberObject_GetRace(oMember)
														.. ":tt" .. math.floor(iTotalTime);
												end
												-- already close to limit?
												if (strlen(sReply) + strlen(sAdd) < 200) then
													sReply = sReply .. sAdd;
													Count = Count + 1;
												else
													sReply = sReply .. ":p" .. sName .. "*";
													Count = MAXCOUNT + 1;
													break;
												end
											end
										elseif (Count == MAXCOUNT) then
											sReply = sReply .. ":p" .. sName .. "*";
											Count = Count + 1;
											break;
										end
									end
								end

								if (Count ~= MAXCOUNT + 1) then
									local	iPos = strfind(KARMA_ALPHACHARS, sBucket);
									if (iPos == nil) or ((iPos + 1) > strlen(KARMA_ALPHACHARS)) then
										iPos = 1;
									else
										iPos = iPos + 1;
									end
									sReply = sReply .. ":p" .. strsub(KARMA_ALPHACHARS, iPos, iPos) .. "**";
								end
		
								SendAddonMessage("KARMA", sReply, arg3, arg4);
							end
						end
					else
						if (KARMA_EXCHANGE.ENABLED_WITH ~= arg4) then
							KarmaChatSecondary("Data exchange request by >" .. KOH.Name2Clickable(arg4) .. "< refused. Use '" .. KARMA_CMDSELF .. " exchangeallow " .. arg4 .. "' to allow them.");
						end

						SendAddonMessage("KARMA", "!x1-", arg3, arg4);
					end
				end
			end

			-- reply?
			if (strsub(arg2, 1, 1) == "!") then
				if (strsub(arg2, 2, 2) == "v") then
					local	iPos;
					local	vermajmin, vermaj, vermin, verdat;
	
					-- version reply: v1
					if (strsub(arg2, 2, 4) == "v1:") then
						-- compare...
						KarmaChatDebug("Version reply v1: <" .. strsub(arg2, 5) .. "> from " .. arg4);
						if (KARMA_OtherInfos[arg4].ver == nil) then
							KARMA_OtherInfos[arg4].ver = strsub(arg2, 5);
							iPos = strfind(KARMA_OtherInfos[arg4].ver, ":", 1, true);
							if (iPos) then
								vermajmin = strsub(KARMA_OtherInfos[arg4].ver, 1, iPos - 1);
								verdat = strsub(KARMA_OtherInfos[arg4].ver, iPos + 1);
							else
								vermajmin = KARMA_OtherInfos[arg4].ver;
							end
						end
					-- version reply (old)
					elseif (strsub(arg2, 4, 4) ~= ":") then
						-- compare...
						KarmaChatDebug("Version reply v0: <" .. strsub(arg2, 3) .. "> from " .. arg4);
						if (KARMA_OtherInfos[arg4].ver == nil) then
							KARMA_OtherInfos[arg4].ver = strsub(arg2, 3);
							vermajmin = KARMA_OtherInfos[arg4].ver;
						end
					end
	
					if (vermajmin) then
						iPos = strfind(vermajmin, ".", 1, true);
						if (iPos) then
							vermaj = tonumber(strsub(vermajmin, 1, iPos - 1), 16);
							vermin = tonumber(strsub(vermajmin, iPos + 1), 16);
						else
							vermaj = vermajmin;
						end
	
						local	mymajmin, mymaj, mymin, mydat;
						mymajmin = KARMA_VERSION_TEXT;
						iPos = strfind(mymajmin, ".", 1, true);
						if (iPos) then
							mymaj = tonumber(strsub(mymajmin, 1, iPos - 1), 16);
							mymin = tonumber(strsub(mymajmin, iPos + 1), 16);
						end

						local	Msg;
						if (vermajmin) and (mymajmin) and (vermajmin ~= mymajmin) then
							if (vermin) and (mymin) then
								if (vermaj > mymaj) or ((vermaj == mymaj) and (vermin > mymin)) then
									Msg = KARMA_MSG_VERSION_NEW1 .. vermajmin;
								end
							elseif (vermajmin > mymajmin) then
								Msg = KARMA_MSG_VERSION_NEW1 .. vermajmin;
							end
						end

						local	VersionSeen = KarmaModuleLocal.Version.Seen[arg3];
						if (type(VersionSeen) == "table") then
							if (vermajmin == mymajmin) then
								VersionSeen.Same = VersionSeen.Same + 1;
							else
								if (vermin) and (mymin) then
									if (vermaj > mymaj) or ((vermaj == mymaj) and (vermin > mymin)) then
										VersionSeen.Newer = VersionSeen.Newer + 1;
									else
										VersionSeen.Older = VersionSeen.Older + 1;
									end
								elseif (vermajmin > mymajmin) then
									VersionSeen.Newer = VersionSeen.Newer + 1;
								else
									VersionSeen.Older = VersionSeen.Older + 1;
								end
							end
						end

KarmaChatDebug("Version from " .. arg4 .. KARMA_WINEL_FRAG_COLONSPACE .. vermajmin .. "(" .. Karma_NilToString(verdat) .. ")");

						if (Msg) then
							if (KARMA_VERSION_TEXT_NEWEST ~= nil) then
								if (vermajmin == KARMA_VERSION_TEXT_NEWEST) then
									-- if same: skip
									Msg = nil;
								else
									local	newmajmin, newmaj, newmin;
									local	newmajmin = KARMA_VERSION_TEXT_NEWEST;
									iPos = strfind(newmajmin, ".", 1, true);
									if (iPos) then
										newmaj = tonumber(strsub(newmajmin, 1, iPos - 1), 16);
										newmin = tonumber(strsub(newmajmin, iPos + 1), 16);
									end

KarmaChatDebug("MostRecent-Seen: " .. Karma_NilToString(newmaj) .. "~" .. Karma_NilToString(newmin)
						.. " vs. " .. Karma_NilToString(vermaj) .. "~" .. Karma_NilToString(vermin));

									-- if newer: assign & display; if older: ignore
									if (vermin) and (newmin) then
										if (vermaj > newmaj) or ((vermaj == newmaj) and (vermin > newmin)) then
											KARMA_VERSION_TEXT_NEWEST = vermajmin;
											KARMA_VERSION_DATE_NEWEST = verdat;
										else
											Msg = nil;
										end
									else
										if (vermajmin > mymajmin) then
											KARMA_VERSION_TEXT_NEWEST = vermajmin;
											KARMA_VERSION_DATE_NEWEST = verdat;
										else
											Msg = nil;
										end
									end
								end
							else
								KARMA_VERSION_TEXT_NEWEST = vermajmin;
								KARMA_VERSION_DATE_NEWEST = verdat;
							end
						end

						if (Msg) then
							if (verdat) and (strfind(verdat, "?", 1, true) == nil) then
								Msg = Msg .. KARMA_MSG_VERSION_NEW2 .. verdat .. KARMA_MSG_VERSION_NEW3;
							end
							KarmaChatDefault(Msg);
						end
					end
				end

				-- player info reply
				if (strsub(arg2, 2, 4) == "p1:") then
					local	iPos = strfind(arg2, ":", 5, true);
					if (iPos) then
						local	sName = strsub(arg2, 5, iPos - 1);
						local	sInfo = strsub(arg2, iPos + 1);
						local	bSpam = true;
						do
							local	oMember = Karma_MemberList_GetObject(sName);
							if (oMember) then
								bSpam = false;
							end
						end
						if (bSpam) then
							KarmaChatDebug("Infos from " .. arg4 .. " about " .. sName .. " = <" .. sInfo .. ">: No object, will spam.");
						else
							KarmaChatDebug("Infos from " .. arg4 .. " about " .. sName .. " = <" .. sInfo .. ">: Have object, no spamming.");
						end
						if (KarmaModuleLocal.NotesPublic.Results[sName] == nil) then
							KarmaModuleLocal.NotesPublic.Results[sName] = {};
						end
						if (KarmaModuleLocal.NotesPublic.Results[sName][arg4] == nil) then
							KarmaModuleLocal.NotesPublic.Results[sName][arg4] = {};
						end

						local	oContainer = KarmaModuleLocal.NotesPublic.Results[sName][arg4];
						while (sInfo ~= "") do
							iPos = strfind(sInfo, ":", 1, true);
							if (strsub(sInfo, 1, 1) == "k") then
								local	sKarma, iKarma;
								if (iPos) then
									sKarma = strsub(sInfo, 2, iPos - 1);
								else
									sKarma = strsub(sInfo, 2);
								end
								iKarma = tonumber(sKarma);
								if (iKarma and (iKarma > 0)) then
									if (iKarma > 90) then
										sKarma = "a lot of positive Karma";
									elseif (iKarma > 70) then
										sKarma = "much positive Karma";
									elseif (iKarma > 60) then
										sKarma = "some positive Karma";
									elseif (iKarma > 50) then
										sKarma = "positive Karma";
									elseif (iKarma < 10) then
										sKarma = "a lot of negative Karma";
									elseif (iKarma < 30) then
										sKarma = "much negative Karma";
									elseif (iKarma < 40) then
										sKarma = "some negative Karma";
									elseif (iKarma < 50) then
										sKarma = "negative Karma";
									else	-- 50.
										sKarma = "unmodified Karma";
									end

									oContainer.sKarma = sKarma;
									if (bSpam) then
										KarmaChatSecondary(arg4 .. " has assigned " .. sKarma .. " to " .. sName .. ".");
									end
								else
									KarmaChatDebug("Invalid Karma value in reply from " .. arg4 .. ": <" .. sKarma .. ">");
								end
							elseif (strsub(sInfo, 1, 2) == "np") then
								local	sNote;
								if (iPos) then
									sNote = strsub(sInfo, 3, iPos - 1);
								else
									sNote = strsub(sInfo, 3);
								end

								if (strsub(sNote, 1, 1) == "#") then
									sNote = strsub(sNote, 2);
									sNote = string.gsub(sNote, "#!#!", ":");
									sNote = string.gsub(sNote, "#!", "!");
									sNote = string.gsub(sNote, "##", "#");
								end

								oContainer.sNotePub = sNote;
								if (bSpam) then
									KarmaChatSecondary(arg4 .. " has added a public note to " .. sName .. ": " .. sNote);
								end
							end

							if (iPos) then
								sInfo = strsub(sInfo, iPos + 1);
							else
								sInfo = "";
							end
						end
					end
				end

				-- data exchange reply
				if (strsub(arg2, 2, 2) == "x") then
					if (arg4 == nil) or (KARMA_EXCHANGE.START_WITH ~= arg4) then
						KarmaChatSecondary("Unsolicited data exchange reply by " .. arg4 .. " - ignored.");
					elseif (strsub(arg2, 3, 3) == "1") then
						if (strsub(arg2, 4, 4) == "-") then
							KarmaChatSecondary("Data exchange request was refused by " .. arg4 .. ". :(");
						elseif (strsub(arg2, 4, 5) == "+:") then
							KarmaChatDebug("Data exchange request was processed by " .. arg4 .. ".");

							if (KarmaTrans_ForeignKarmaEntry == nil) then
								KarmaChatDebug("No use: KarmaTrans is not active. Stopping.");
							end

							local	sServer = GetCVar("realmName"); -- GetRealmName(): not sure about localization
							local	sFaction = UnitFactionGroup("player");
							local	sData = strsub(arg2, 6);
							if (strsub(sData, -1, -1) ~= ":") then
								sData = sData .. ":";
							end
							local	iPos, sFragment;
							local	sPlayer, iKarma, iLevel, iClass, sRace, iPlayed, sNote, sGUID;
							while (sData ~= "") do
								local	iPos = strfind(sData, ":");
								if (iPos == nil) then
									sFragment = sData;
								else
									sFragment = strsub(sData, 1, iPos - 1);
									sData = strsub(sData, iPos + 1);
								end

								if (strsub(sFragment, 1, 1) == "p") then
									-- store data
									if	(sPlayer ~= nil) and (iKarma ~= nil) and (iPlayed ~= nil) then
										local	sBucket = KarmaObj.NameToBucket(sPlayer);
										KarmaTrans_ForeignKarmaEntry(sServer, sFaction, arg4, sBucket, sPlayer, iKarma, iPlayed, iLevel, iClass, sRace, sGUID, sNote);
KarmaChatDebug("Storing: " .. arg4 .. " -> " .. sPlayer .. ": " .. iKarma .. " / " .. iPlayed);
										if (KARMA_EXCHANGE.DONE ~= nil) then
											KARMA_EXCHANGE.COUNT = KARMA_EXCHANGE.COUNT + 1;
										end
									elseif (sPlayer ~= nil) then
KarmaChatDebug("Hmmmmmm: " .. arg4 .. " -> " .. Karma_NilToString(sPlayer) .. ": " .. Karma_NilToString(iKarma) .. " / " .. Karma_NilToString(iPlayed));
									end

									-- next player
									sPlayer = strsub(sFragment, 2);

									-- seen everything once?
									if	(sPlayer == KARMA_EXCHANGE.FIRST) then
										KARMA_EXCHANGE.START_WITH = nil;
										KARMA_EXCHANGE.FIRST = nil;
										KARMA_EXCHANGE.DONE = GetTime();
										KarmaChatDefault("Data exchange with >" .. arg4 .. "< completed. Entry count: " .. KARMA_EXCHANGE.COUNT .. " Duration of exchange: " .. KOH.Duration2String(KARMA_EXCHANGE.DONE - KARMA_EXCHANGE.START_AT));
									end

									-- didn't start with anything: set to first encountered entry
									if (KARMA_EXCHANGE.FIRST == nil) then
										KARMA_EXCHANGE.FIRST = sPlayer;
									end

									-- end of sequence marker?
									if (strsub(sPlayer, -1, -1) == "*") then
										sPlayer = nil;
										KARMA_EXCHANGE.ACK_IS = strsub(sFragment, 2, -2);
KarmaChatDebug("End of group reached, will continue with >" .. KARMA_EXCHANGE.ACK_IS .. "<");
										if (KarmaTrans_ForeignKarmaContinueWithSet ~= nil) then
											KarmaTrans_ForeignKarmaContinueWithSet(sServer, sFaction, arg4, KARMA_EXCHANGE.ACK_IS);
										end
									end

									iKarma = nil;
									iLevel = nil;
									iClass = nil;
									sRace = nil;
									iPlayed = nil;
									sNote = nil;
									sGUID = nil;
								elseif (strsub(sFragment, 1, 1) == "k") then
									iKarma = tonumber(strsub(sFragment, 2));
								elseif (strsub(sFragment, 1, 1) == "l") then
									iLevel = tonumber(strsub(sFragment, 2));
								elseif (strsub(sFragment, 1, 2) == "ci") then
									iClass = tonumber(strsub(sFragment, 3));
								elseif (strsub(sFragment, 1, 2) == "rs") then
									sRace = strsub(sFragment, 3);
								elseif (strsub(sFragment, 1, 2) == "tt") then
									iPlayed = tonumber(strsub(sFragment, 3));
								elseif (strsub(sFragment, 1, 2) == "id") then
									sGUID = strsub(sFragment, 3);
								elseif (strsub(sFragment, 1, 2) == "np") then
									sNote = strsub(sFragment, 3);
									if (strsub(sNote, 1, 1) == "#") then
										sNote = strsub(sNote, 2);
										sNote = string.gsub(sNote, "#!#!", ":");
										sNote = string.gsub(sNote, "#!", "!");
										sNote = string.gsub(sNote, "##", "#");
									end
								end
							end

							KARMA_EXCHANGE.ACK_AT = GetTime() + strlen(arg2) / 100;
						end
					end
				end
			end
		end
	end
end


function	Karma_ChatMsg_System(self, event, ...)
	local	arg1 = ...;
	if (Karma_GetConfig(KARMA_CONFIG.MARKUP_VERSION) >= 2) then
		-- undocumented(?) who-reply: arg1 comes as: "|Hplayer:ABCDE[ABCDE]"
		if (strsub(arg1, 1, 9) == "|Hplayer:") then
			local sMemberName = strsub(arg1, 10);
			local openingbracket = strfind(sMemberName, "[", 1, true);
			if (openingbracket) then
				sMemberName = strsub(sMemberName, openingbracket + 1);
				local closingbracket = strfind(sMemberName, "]", 1, true);
				if (closingbracket) then
					sMemberName = strsub(sMemberName, 1, closingbracket - 1);
					KarmaChatDebug("Potential /who <" .. sMemberName .. "> spotted!");
					WhoUpdateShowKarmaAndNote();
				end
			end
		end
	end
end

--
---
--
function	Karma_ChatMsg_Channel(self, event, ...)
	local	arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 = ...;
	if (arg8 and arg9) then
		if (KarmaModuleLocal.Channels[arg8] == nil) then
			KarmaModuleLocal.Channels[arg8] = {};
			local	oChan = KarmaModuleLocal.Channels[arg8];
			oChan.NameUser  = arg4;
			oChan.NameShort = strlower(arg9);
			oChan.BlizzChan = arg7 or 0;
			oChan.Number    = arg8;
		end

		local	oChanKarma = KarmaModuleLocal.Channels[0];
		if (oChanKarma == nil) then
			KarmaModuleLocal.Channels[0] = {};
			oChanKarma = KarmaModuleLocal.Channels[0];
			oChanKarma.NameUser  = "<internal>";
			oChanKarma.NameShort = "<internal>";
			oChanKarma.BlizzChan = 0;
			oChanKarma.Number    = nil;
		end

		if (oChanKarma.Number == nil) then
			local	sChanKarma = Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME);
			if (sChanKarma) then
				local	sChanKarmaLower = strlower(sChanKarma);
				local	oChan = KarmaModuleLocal.Channels[arg8];
				if (sChanKarmaLower == oChan.NameShort) then
					if (oChan.BlizzChan ~= 0) then
						KarmaChatDefault("INVALID communication channel <#" .. arg4 .. "> (Blizzard channel)");
						oChanKarma.Number = -1;
					else
						KarmaChatDefault("Found communication channel <#" .. arg4 .. ">");
						oChanKarma.Number = arg8;
					end
				end
			else
				oChanKarma.Number = -1;
			end
		end

		if (oChanKarma.Number) then
			if (arg8 == oChanKarma.Number) then
				-- Karma channel.
				KarmaChatDebug("Comm{" .. arg8 .. ": " .. arg2 .. "} => " .. arg1);
				if (strsub(arg1, 1, 2) == "\194\167") then	-- § = 194,167
					if (strsub(arg1, 3, 8) == "KARMA:") then
						if (strsub(arg1, 9, 12) == "?p1:") then
							local	sEncReq = strsub(arg1, 13);
							if (strlen(sEncReq) % 4 == 0) then
								local	sDecReq = "";
								local	cClass;
								while (sEncReq ~= "") do
									cClass = strsub(sEncReq, 1, 1);
									local	iMulti;
									if (cClass == "+") then
										iMulti = 17;
									elseif (cClass == "-") then
										iMulti = 19;
									elseif (cClass == "!") then
										iMulti = 23;
									elseif (cClass == "?") then
										iMulti = 29;
									elseif (cClass == "=") then
										iMulti = 31;
									end

									if (iMulti) then
										local	iVal = tonumber(strsub(sEncReq, 2, 4));
										if (iVal and iVal ~= 0) then
											sDecReq = sDecReq .. string.char((iVal * iMulti) % 257);
										else
											KarmaChatDebug("Ieks: " .. strsub(sEncReq, 2, 4) .. " - inconvertible?");
											sEncReq = "";
											sDecRec = "";
										end
									else
										KarmaChatDebug("Ieks: " .. cClass .. " - invalid class?");
										sEncReq = "";
										sDecRec = "";
									end
									if (sEncReq ~="") then
										sEncReq = strsub(sEncReq, 5);
									end
								end

								if (sDecReq ~= "") then
									KarmaChatDebug("Decoded: " .. sDecReq);

									-- reply: lazy reuse...
									Karma_ChatMsg_AddOn(self, event, "KARMA", "?p1:" .. sDecReq, "CHANNEL", arg2);
								else
									KarmaChatDebug("Failed to decode: " .. strsub(arg1, 13));
								end
							else
								KarmaChatDebug("Malformed request:" .. strsub(arg1, 9, 12) .. " - not a name following.");
							end
						else
							KarmaChatDebug("Unknown request:" .. strsub(arg1, 9, 12));
						end
					else
						-- KarmaChatDebug("Not a Karma message, missing KARMA: string.");
					end
				else
					-- KarmaChatDebug("Not an AddOn message, missing paragraph sign.");
				end
			end
		end
	else
		KarmaChatDebug("--== channels information ==-- ");
		for k, v in pairs(KarmaModuleLocal.Channels) do
			KarmaChatDebug("-- [" .. k .. "] " .. v.NameUser .. ": {" .. v.BlizzChan .. "} " .. v.NameShort);
		end
		KarmaChatDebug("--== -------------------- ==-- ");
	end
end

-----------------------------------------
-- TALENT WINDOW
-----------------------------------------

Karma_TalentWindow_Membername = nil;

Karma_TalentWindow_MemberResult = nil;

function	Karma_TalentInit(oWnd)
	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember == nil) then
		this:Hide();
	end

	local	iSpec = oWnd.iSpec;

	Karma_TalentWindow_Membername = KARMA_CURRENTMEMBER;
	KarmaTalentWindow_Player_Name:SetText(Karma_TalentWindow_Membername);

	local	sTalentTitle = KARMA_WINEL_TALENTWND_TALENT_TITLE;
	if (iSpec) then
		sTalentTitle = sTalentTitle .. KARMA_WINEL_FRAG_SPACE .. iSpec;
	end
	sTalentTitle = sTalentTitle .. KARMA_WINEL_FRAG_COLON;
	KarmaTalentWindow_Talent_Title:SetText(sTalentTitle);
	local	oTree = oMember[KARMA_DB_L5_RRFFM_TALENTTREE];
	local	aTrees = KarmaObj.Talents.TreeObjToStringsObj(oTree, bShiftPressed);
	if (aTrees["S_" .. iSpec] ~= "") then
		KarmaTalentWindow_Talent_Value:SetText(aTrees["S_" .. iSpec]);
	else
		KarmaTalentWindow_Talent_Value:SetText("???");
	end

	local	classid = oMember[KARMA_DB_L5_RRFFM.CLASS_ID];
	if (classid == 0) then
		classid = Karma_ClassToID(Karma_MemberObject_GetClass(oMember));
	end
	if (classid < 0) then
		classid = - classid;
	end
	if (classid > 0) then
		local	talentmask = KARMA_TALENT_CLASSMASK[classid];
		local	iBit, CheckBoxObj;
		for iBit = 1, KARMA_TALENTS_MAXBITPLUS1 do
			if (iBit == 1) then
				CheckBoxObj = KarmaTalentWindow_HPS_Checkbox;
			end
			if (iBit == 2) then
				CheckBoxObj = KarmaTalentWindow_Tank_Checkbox;
			end
			if (iBit == 3) then
				CheckBoxObj = KarmaTalentWindow_DPS_Checkbox;
			end
			if (iBit == 4) then
				CheckBoxObj = KarmaTalentWindow_Melee_Checkbox;
			end
			if (iBit == 5) then
				CheckBoxObj = KarmaTalentWindow_Ranged_Checkbox;
			end
			if ((talentmask % 2) == 1) then
				CheckBoxObj:Enable();
			else
				CheckBoxObj:Disable();
			end
			talentmask = math.floor(talentmask / 2);
		end

		Karma_TalentWindow_MemberResult = Karma_MemberObject_GetTalentIDRaw(oMember, iSpec);
		if (Karma_TalentWindow_MemberResult == 0) then
			Karma_TalentWindow_MemberResult = KarmaObj.Talents.ClassIDToTalentsDefault(classid);
		end
		local	TalentResult = Karma_TalentWindow_MemberResult;
		for iBit = 1, KARMA_TALENTS_MAXBITPLUS1 do
			if (iBit == 1) then
				CheckBoxObj = KarmaTalentWindow_HPS_Checkbox;
			end
			if (iBit == 2) then
				CheckBoxObj = KarmaTalentWindow_Tank_Checkbox;
			end
			if (iBit == 3) then
				CheckBoxObj = KarmaTalentWindow_DPS_Checkbox;
			end
			if (iBit == 4) then
				CheckBoxObj = KarmaTalentWindow_Melee_Checkbox;
			end
			if (iBit == 5) then
				CheckBoxObj = KarmaTalentWindow_Ranged_Checkbox;
			end
			CheckBoxObj:SetChecked(TalentResult % 2);

			TalentResult = math.floor(TalentResult / 2);
		end

		KarmaTalentWindow_Result_Editbox:SetText(KarmaObj.Talents.TalentIDToColorizedText(Karma_TalentWindow_MemberResult));
	end
end

function	Karma_TalentUpdate(clicked)
	-- HPS: => Ranged
	if (clicked == "H") then
		if (KarmaTalentWindow_HPS_Checkbox:GetChecked()) then
			KarmaTalentWindow_DPS_Checkbox:SetChecked(0);
			KarmaTalentWindow_Tank_Checkbox:SetChecked(0);
			KarmaTalentWindow_Melee_Checkbox:SetChecked(0);
			KarmaTalentWindow_Ranged_Checkbox:SetChecked(1);
		end
	end
	-- Tank: => Melee
	if (clicked == "T") then
		if (KarmaTalentWindow_Tank_Checkbox:GetChecked()) then
			KarmaTalentWindow_HPS_Checkbox:SetChecked(0);
			KarmaTalentWindow_Melee_Checkbox:SetChecked(1);
			KarmaTalentWindow_Ranged_Checkbox:SetChecked(0);
		end
	end
	-- DPS: => !HPS
	if (clicked == "D") then
		if (KarmaTalentWindow_DPS_Checkbox:GetChecked()) then
			KarmaTalentWindow_HPS_Checkbox:SetChecked(0);
		end
	end
	-- R: => !M
	if (clicked == "R") then
		if (KarmaTalentWindow_Ranged_Checkbox:GetChecked()) then
			KarmaTalentWindow_Tank_Checkbox:SetChecked(0);
			KarmaTalentWindow_Melee_Checkbox:SetChecked(0);
		end
	end
	-- M: => !R
	if (clicked == "M") then
		if (KarmaTalentWindow_Melee_Checkbox:GetChecked()) then
			KarmaTalentWindow_HPS_Checkbox:SetChecked(0);
			KarmaTalentWindow_Ranged_Checkbox:SetChecked(0);
		end
	end

	Karma_TalentWindow_MemberResult = 0;
	local	iBit;
	local	iBitValue = 1;
	for iBit = 1, KARMA_TALENTS_MAXBITPLUS1 do
		if (iBit == 1) then
			CheckBoxObj = KarmaTalentWindow_HPS_Checkbox;
		end
		if (iBit == 2) then
			CheckBoxObj = KarmaTalentWindow_Tank_Checkbox;
		end
		if (iBit == 3) then
			CheckBoxObj = KarmaTalentWindow_DPS_Checkbox;
		end
		if (iBit == 4) then
			CheckBoxObj = KarmaTalentWindow_Melee_Checkbox;
		end
		if (iBit == 5) then
			CheckBoxObj = KarmaTalentWindow_Ranged_Checkbox;
		end

		if (CheckBoxObj:GetChecked()) then
			Karma_TalentWindow_MemberResult = Karma_TalentWindow_MemberResult + iBitValue;
		end
		iBitValue = iBitValue * 2;
	end

	local	TitleObj = getglobal("KarmaTalentWindow_Result_Editbox");
	TitleObj:SetText(KarmaObj.Talents.TalentIDToColorizedText(Karma_TalentWindow_MemberResult));
end

function	Karma_TalentDone(ExitOk)
	KarmaTalentWindow:Hide();
	if (ExitOk) then
		local	oMember = Karma_MemberList_GetObject(Karma_TalentWindow_Membername);
		if (oMember) and (Karma_TalentWindow_MemberResult) then
			Karma_MemberObject_SetTalentID(oMember, KarmaTalentWindow.iSpec, Karma_TalentWindow_MemberResult); 
			KarmaWindow_Update();
		end
	end
end

function	KarmaWindow_OtherData_OnEnter()
	local	oMember = Karma_MemberList_GetObject(KARMA_CURRENTMEMBER);
	if (oMember) then
		local	bHaveLines;
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");

		local	iSkill = Karma_MemberObject_GetSkill(oMember);
		if (iSkill >= 0) then
			local	sSkill = KARMA_SKILL_LEVELS[iSkill];
			if (sSkill) then
				local	sModel = Karma_GetConfig(KARMA_CONFIG_SKILL_MODEL);
				if (sModel == "complex") then
					sSkill = KARMA_WINEL_CHOSENPLAYERSKILLTITLE .. KARMA_WINEL_FRAG_SPACE .. tostring(iSkill) .. KARMA_WINEL_FRAG_COLONSPACE .. sSkill;
				else
					sSkill = KARMA_WINEL_CHOSENPLAYERSKILLTITLE .. KARMA_WINEL_FRAG_SPACE .. sSkill;
				end

				bHaveLines = true;
				GameTooltip:AddLine(sSkill, 1, 1, 1);
			end
		end

		local	iGear, sGear;
		iGear = Karma_MemberObject_GetGearPVE(oMember);
		if (iGear >= 0) then
			sGear = KARMA_GEAR_PVE_LEVELS[iGear];
			if (sGear) then
				bHaveLines = true;
				sGear = KARMA_WINEL_CHOSENPLAYERGEARPVETITLE .. KARMA_WINEL_FRAG_COLONSPACE .. sGear;
				GameTooltip:AddLine(sGear, 1, 1, 1);
			end
		end
		iGear = Karma_MemberObject_GetGearPVP(oMember);
		if (iGear >= 0) then
			sGear = KARMA_GEAR_PVP_LEVELS[iGear];
			if (sGear) then
				bHaveLines = true;
				sGear = KARMA_WINEL_CHOSENPLAYERGEARPVPTITLE .. KARMA_WINEL_FRAG_COLONSPACE .. sGear;
				GameTooltip:AddLine(sGear, 1, 1, 1);
			end
		end

		if (bHaveLines) then
			GameTooltip:Show();
		end
	end
end

-----------------------------------------
-- WndLFG
-----------------------------------------

function	Karma_PlayerLevelRange()
	local	minlvl, islvl, maxlvl, delta;
	islvl = UnitLevel("player");

	-- lower levels => bigger range to include
	if (islvl < 41) then
		delta = 7;
	elseif (islvl < 51) then
		delta = 6;
	elseif (islvl < 61) then
		delta = 5;
	elseif (islvl < 71) then
		delta = 4;
	elseif (islvl < 80) then
		delta = 3;
	else
		delta = 2;
	end

	minlvl = math.max(islvl - delta, 1);
	maxlvl = math.min(islvl + delta, KARMA_MAXLEVEL);

	return minlvl, maxlvl;
end

-- ************************************************************************ --
-- ************************************************************************ --
function	KarmaWindow2_FilterList1_SkillMin_DropDown_Initialize()
	local	info;
	local	i;
	info = {};
	info.func = KarmaWindow2_FilterList1_SkillMin_DropDown_OnClick;
	for i = 0, 100 do
		if (KARMA_SKILL_LEVELS[i]) then
			info.value = i;
			info.text = KARMA_SKILL_LEVELS[i];
			info.arg1 = KARMA_SKILL_LEVELS[i];
			info.arg2 = i;
			info.notCheckable = 1;

			UIDropDownMenu_AddButton(info);
		end
	end
end

function	KarmaWindow2_FilterList1_SkillMin_DropDown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaWindow2_FilterList1_SkillMin_DropDown_Initialize);
	UIDropDownMenu_SetWidth(this, 250);
	UIDropDownMenu_SetButtonWidth(this, 24);

	-- hopefully overriden...
	if (KARMA_Online.PlayersAllFilter.minSkill) then
		UIDropDownMenu_SetSelectedID(this, KARMA_Online.PlayersAllFilter.minSkill);
	else
		UIDropDownMenu_SetSelectedID(this, 0);
	end
end

local	KarmaWindow2_FilterList1_SkillMin_DropDown_Selection = nil;

function	KarmaWindow2_FilterList1_SkillMin_DropDown_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaWindow2_FilterList1_SkillMin_DropDown, this:GetID());
	KarmaWindow2_FilterList1_SkillMin_DropDown_Selection = arg2;
end
-- ************************************************************************ --
-- ************************************************************************ --

function	KarmaWindow2_FilterList1_Init()
	if (KARMA_Online.PlayersAllFilter.minKarma) then
		KarmaWindow2_FilterList1_KarmaMin_Editbox:SetText(tostring(KARMA_Online.PlayersAllFilter.minKarma));
	else
		KarmaWindow2_FilterList1_KarmaMin_Editbox:SetText("");
	end

	if (KARMA_Online.PlayersAllFilter.KarmaReq) then
		KarmaWindow2_FilterList1_KarmaReq_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.KarmaReq);
	else
		KarmaWindow2_FilterList1_KarmaReq_Checkbutton:SetChecked(0);
	end

	if (KARMA_Online.PlayersAllFilter.ClassKnown) then
		KarmaWindow2_FilterList1_ClassReq_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassKnown);
	else
		KarmaWindow2_FilterList1_ClassReq_Checkbutton:SetChecked(0);
	end

	-- Level range
	if (KARMA_Online.PlayersAllFilter.LevelFrom) and (KARMA_Online.PlayersAllFilter.LevelTo) then
		KarmaWindow2_FilterList1_LevelRange_Editbox:SetText(tostring(KARMA_Online.PlayersAllFilter.LevelFrom)
													.. "-" .. tostring(KARMA_Online.PlayersAllFilter.LevelTo));
	else
		-- local	minlvl, maxlvl = Karma_PlayerLevelRange();
		local	minlvl, maxlvl = 1, KARMA_MAXLEVEL;
		KarmaWindow2_FilterList1_LevelRange_Editbox:SetText(tostring(minlvl) .. "-" .. tostring(maxlvl));
		KARMA_Online.PlayersAllFilter.LevelFrom = minlvl;
		KARMA_Online.PlayersAllFilter.LevelTo = maxlvl;
	end

	-- Talents: HPS/TANK/DPS Melee/Ranged
	if (KARMA_Online.PlayersAllFilter.TalentHPS) then
		KarmaWindow2_FilterList1_HPS_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.TalentHPS);
	else
		KarmaWindow2_FilterList1_HPS_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.TalentTANK) then
		KarmaWindow2_FilterList1_TANK_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.TalentTANK);
	else
		KarmaWindow2_FilterList1_TANK_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.TalentDPS) then
		KarmaWindow2_FilterList1_DPS_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.TalentDPS);
	else
		KarmaWindow2_FilterList1_DPS_Checkbutton:SetChecked(1);
	end

	if (KARMA_Online.PlayersAllFilter.TalentMelee) then
		KarmaWindow2_FilterList1_Melee_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.TalentMelee);
	else
		KarmaWindow2_FilterList1_Melee_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.TalentRange) then
		KarmaWindow2_FilterList1_Range_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.TalentRange);
	else
		KarmaWindow2_FilterList1_Range_Checkbutton:SetChecked(1);
	end

	-- Classes
	if (KARMA_Online.PlayersAllFilter.ClassDruid) then
		KarmaWindow2_FilterList1_Druid_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassDruid);
	else
		KarmaWindow2_FilterList1_Druid_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.ClassHunter) then
		KarmaWindow2_FilterList1_Hunter_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassHunter);
	else
		KarmaWindow2_FilterList1_Hunter_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.ClassMage) then
		KarmaWindow2_FilterList1_Mage_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassMage);
	else
		KarmaWindow2_FilterList1_Mage_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.ClassPaladin) then
		KarmaWindow2_FilterList1_Paladin_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassPaladin);
	else
		KarmaWindow2_FilterList1_Paladin_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.ClassPriest) then
		KarmaWindow2_FilterList1_Priest_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassPriest);
	else
		KarmaWindow2_FilterList1_Priest_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.ClassRogue) then
		KarmaWindow2_FilterList1_Rogue_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassRogue);
	else
		KarmaWindow2_FilterList1_Rogue_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.ClassShaman) then
		KarmaWindow2_FilterList1_Shaman_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassShaman);
	else
		KarmaWindow2_FilterList1_Shaman_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.ClassWarlock) then
		KarmaWindow2_FilterList1_Warlock_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassWarlock);
	else
		KarmaWindow2_FilterList1_Warlock_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.ClassWarrior) then
		KarmaWindow2_FilterList1_Warrior_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassWarrior);
	else
		KarmaWindow2_FilterList1_Warrior_Checkbutton:SetChecked(1);
	end
	if (KARMA_Online.PlayersAllFilter.ClassDeathknight) then
		KarmaWindow2_FilterList1_Deathknight_Checkbutton:SetChecked(KARMA_Online.PlayersAllFilter.ClassDeathknight);
	else
		KarmaWindow2_FilterList1_Deathknight_Checkbutton:SetChecked(1);
	end
end

function	KarmaWindow2_FilterList1_Ok()
	local	sValue, iValue;

	KARMA_Online.PlayersAllFilter.minKarma = nil;
	sValue = KarmaWindow2_FilterList1_KarmaMin_Editbox:GetText();
	if (sValue) and (sValue ~= "") then
		iValue = tonumber(sValue);
		if (iValue) then
			KARMA_Online.PlayersAllFilter.minKarma = iValue;
		end
	end

	if (KarmaWindow2_FilterList1_KarmaReq_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.KarmaReq = 1;
	else
		KARMA_Online.PlayersAllFilter.KarmaReq = 0;
	end

	KARMA_Online.PlayersAllFilter.minSkill = KarmaWindow2_FilterList1_SkillMin_DropDown_Selection;
	if (KARMA_Online.PlayersAllFilter.minSkill) then
		if (KARMA_SKILL_LEVELS[KARMA_Online.PlayersAllFilter.minSkill] == nil) then
			KARMA_Online.PlayersAllFilter.minSkill = nil;
		end
	end

	if (KarmaWindow2_FilterList1_ClassReq_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassKnown = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassKnown = 0;
	end

	local	LevelRange = KarmaWindow2_FilterList1_LevelRange_Editbox:GetText();
	if (tonumber(LevelRange) ~= nil) then
		KARMA_Online.PlayersAllFilter.LevelFrom = tonumber(LevelRange);
		KARMA_Online.PlayersAllFilter.LevelTo = tonumber(LevelRange);
	else
		local	iPosHyphen = strfind(tostring(LevelRange), "-", 1, true);
		if (iPosHyphen) then
			local	LevelFrom = strsub(tostring(LevelRange), 1, iPosHyphen - 1);
			local	LevelTo = strsub(tostring(LevelRange), iPosHyphen + 1);
			if (tonumber(LevelFrom) and tonumber(LevelTo)) then
				KARMA_Online.PlayersAllFilter.LevelFrom = tonumber(LevelFrom);
				KARMA_Online.PlayersAllFilter.LevelTo = tonumber(LevelTo);
			end
		end
	end

	if (KarmaWindow2_FilterList1_HPS_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.TalentHPS = 1;
	else
		KARMA_Online.PlayersAllFilter.TalentHPS = 0;
	end
	if (KarmaWindow2_FilterList1_TANK_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.TalentTANK = 1;
	else
		KARMA_Online.PlayersAllFilter.TalentTANK = 0;
	end
	if (KarmaWindow2_FilterList1_DPS_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.TalentDPS = 1;
	else
		KARMA_Online.PlayersAllFilter.TalentDPS = 0;
	end

	if (KarmaWindow2_FilterList1_Melee_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.TalentMelee = 1;
	else
		KARMA_Online.PlayersAllFilter.TalentMelee = 0;
	end
	if (KarmaWindow2_FilterList1_Range_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.TalentRange = 1;
	else
		KARMA_Online.PlayersAllFilter.TalentRange = 0;
	end

	if (KarmaWindow2_FilterList1_Druid_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassDruid = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassDruid = 0;
	end
	if (KarmaWindow2_FilterList1_Hunter_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassHunter = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassHunter = 0;
	end
	if (KarmaWindow2_FilterList1_Mage_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassMage = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassMage = 0;
	end
	if (KarmaWindow2_FilterList1_Paladin_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassPaladin = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassPaladin = 0;
	end
	if (KarmaWindow2_FilterList1_Priest_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassPriest = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassPriest = 0;
	end
	if (KarmaWindow2_FilterList1_Rogue_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassRogue = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassRogue = 0;
	end
	if (KarmaWindow2_FilterList1_Shaman_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassShaman = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassShaman = 0;
	end
	if (KarmaWindow2_FilterList1_Warlock_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassWarlock = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassWarlock = 0;
	end
	if (KarmaWindow2_FilterList1_Warrior_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassWarrior = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassWarrior = 0;
	end
	if (KarmaWindow2_FilterList1_Deathknight_Checkbutton:GetChecked()) then
		KARMA_Online.PlayersAllFilter.ClassDeathknight = 1;
	else
		KARMA_Online.PlayersAllFilter.ClassDeathknight = 0;
	end

	KARMA_Online.PlayersVersion = KARMA_Online.PlayersVersion + 1;
	KarmaWindow2_UpdateList1();
end

function	KarmaWindow2_Alts_Toggle()
	KARMA_Online.PlayersAllFilter.Alts = not KARMA_Online.PlayersAllFilter.Alts;
	local	sTitle = KarmaWindow2_Alts_Button:GetText();
	if (KARMA_Online.PlayersAllFilter.Alts) then
		sTitle = "-" .. strsub(sTitle, 2);
	else
		sTitle = "+" .. strsub(sTitle, 2);
	end
	KarmaWindow2_Alts_Button:SetText(sTitle);

	KARMA_Online.PlayersVersion = KARMA_Online.PlayersVersion + 1;
	KarmaWindow2_UpdateList1();
end

-- ************************************************************************ --
-- ************************************************************************ --
function	KarmaWindow2_PopulateWindow_Channel_DropDown_Initialize()
	local	info;
	local	i, id, name;
	for i = 1, 10 do
		id, name = GetChannelName(i);
		if (id == i) then
			info = {};
			info.value = i;
			info.text = tostring(id) .. KARMA_WINEL_FRAG_COLONSPACE .. name;
			info.arg1 = name;
			info.arg2 = i;
			info.func = KarmaWindow2_PopulateWindow_Channel_DropDown_OnClick;
			UIDropDownMenu_AddButton(info);
		end
	end
end

function	KarmaWindow2_PopulateWindow_Channel_DropDown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaWindow2_PopulateWindow_Channel_DropDown_Initialize);
	UIDropDownMenu_SetWidth(this, 150);
	UIDropDownMenu_SetButtonWidth(this, 24);

	-- hopefully overriden...
	UIDropDownMenu_SetSelectedID(this, 0);
end

function	KarmaWindow2_PopulateWindow_Channel_DropDown_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaWindow2_PopulateWindow_Channel_DropDown, this:GetID());
	KarmaModuleLocal.LFM_Populate_Channel = arg2;
end
-- ************************************************************************ --
-- ************************************************************************ --

-- ************************************************************************ --
-- ************************************************************************ --
function	KarmaWindow2_PopulateWindow_Class_DropDown_Initialize()
	local	info;
	local	i;
	for i = 1, 10 do
		info = {};
		info.value = i;
		info.text = Karma_IDToClass(i);
		info.arg1 = info.text;
		info.arg2 = i;
		info.func = KarmaWindow2_PopulateWindow_Class_DropDown_OnClick;
		UIDropDownMenu_AddButton(info);
	end
end

function	KarmaWindow2_PopulateWindow_Class_DropDown_OnShow()
	UIDropDownMenu_Initialize(this, KarmaWindow2_PopulateWindow_Class_DropDown_Initialize);
	UIDropDownMenu_SetWidth(this, 150);
	UIDropDownMenu_SetButtonWidth(this, 24);

	-- hopefully overriden...
	UIDropDownMenu_SetSelectedID(this, 0);
end

function	KarmaWindow2_PopulateWindow_Class_DropDown_OnClick(self, arg1, arg2)
	UIDropDownMenu_SetSelectedID(KarmaWindow2_PopulateWindow_Class_DropDown, this:GetID());
	KarmaModuleLocal.LFM_Populate_Class = arg2;
end
-- ************************************************************************ --
-- ************************************************************************ --

function	KarmaWindow2_PopulateWindow_Level_Editbox_OnShow()
	local	text = KarmaWindow2_PopulateWindow_Level_Editbox:GetText();
	if (text == nil) or (text == "") then
		local	minlvl, maxlvl = Karma_PlayerLevelRange();
		KarmaWindow2_PopulateWindow_Level_Editbox:SetText(tostring(minlvl) .. "-" .. tostring(maxlvl));
	end
end

function	KarmaWindow2_PopulateWindow_ClickedSearch(which)
	local	CheckBoxes = {
				KarmaWindow2_PopulateWindow_Channel_Checkbox,
				KarmaWindow2_PopulateWindow_Channels_Checkbox,
				KarmaWindow2_PopulateWindow_Class_Checkbox,
				KarmaWindow2_PopulateWindow_Classes_Checkbox,
				KarmaWindow2_PopulateWindow_Guild_Checkbox
			};
	local key, value;
	for key, value in pairs(CheckBoxes) do
		if (value ~= which) then
			value:SetChecked(0);
		end
	end
end

function	KarmaWindow2_PopulateWindow_Execute()
KarmaChatDebug(">> KarmaWindow2_PopulateWindow_Execute");
	if (KarmaWindow2_PopulateWindow_Channel_Checkbox:GetChecked() == 1) then
		if (KarmaModuleLocal.LFM_Populate_Channel) and (KarmaModuleLocal.LFM_Populate_Channel > 0) then
			Karma_QueueCommandChannelCheck(KarmaModuleLocal.LFM_Populate_Channel);
			KarmaWindow2_PopulateWindow_Channel_Checkbox:SetChecked(0);
			-- UIDropDownMenu_SetSelectedID(KarmaWindow2_PopulateWindow_Channel_DropDown, 0);
			-- UIDropDownMenu_SetText(KarmaWindow2_PopulateWindow_Channel_DropDown, "");
		end
	elseif (KarmaWindow2_PopulateWindow_Channels_Checkbox:GetChecked() == 1) then
		KarmaChatDefault(KARMA_MSG_CHECKCHANNEL_ALL .. KARMA_WINEL_FRAG_TRIDOTS);
		local	i, id, name;
		for i = 1, 10 do
			id, name = GetChannelName(i);
			if (id == i) then
				Karma_QueueCommandChannelCheck(id);
			end
		end

		KarmaWindow2_PopulateWindow_Channels_Checkbox:SetChecked(0);
	end

	local	levelrange = KarmaWindow2_PopulateWindow_Level_Editbox:GetText();
	if (KarmaWindow2_PopulateWindow_Class_Checkbox:GetChecked() == 1) then
		local	id = KarmaWindow2_PopulateWindow_Class_DropDown.selectedID;
		if (KarmaModuleLocal.LFM_Populate_Class) then
			if (Karma_Executing_Command) then
				KarmaChatDefault(KARMA_MSG_COMMANDQUEUE_FULL1 .. KARMA_WINEL_FRAG_COLONSPACE .. #Karma_CommandQueue .. KARMA_MSG_COMMANDQUEUE_FULL2);
			else
				local	args = {};
				args[2] = Karma_IDToClass(KarmaModuleLocal.LFM_Populate_Class);
				args[3] = levelrange;
				Karma_SlashCheckClassOnline(args);
				KarmaModuleLocal.LFM_Populate_Class = nil;

				KarmaWindow2_PopulateWindow_Class_Checkbox:SetChecked(0);
				-- UIDropDownMenu_SetSelectedID(KarmaWindow2_PopulateWindow_Class_DropDown, 0);
				-- UIDropDownMenu_SetText(KarmaWindow2_PopulateWindow_Class_DropDown, "");
			end
		end
	elseif (KarmaWindow2_PopulateWindow_Classes_Checkbox:GetChecked() == 1) then
		-- checkallclasses: if yes, then last if no command is running
		if (Karma_Executing_Command) then
			KarmaChatDefault(KARMA_MSG_COMMANDQUEUE_FULL1 .. KARMA_WINEL_FRAG_COLONSPACE .. #Karma_CommandQueue .. KARMA_MSG_COMMANDQUEUE_FULL2);
		else
			local	args = {};
			args[2] = levelrange;
			Karma_SlashCheckAllClassesOnline(args);
			KarmaWindow2_PopulateWindow_Classes_Checkbox:SetChecked(0);
		end
	elseif (KarmaWindow2_PopulateWindow_Guild_Checkbox:GetChecked()) then
		local	guildname = KarmaWindow2_PopulateWindow_Guild_Editbox:GetText();
		if (guildname) and (guildname ~= "") then
			if (Karma_Executing_Command) then
				KarmaChatDefault(KARMA_MSG_COMMANDQUEUE_FULL1 .. KARMA_WINEL_FRAG_COLONSPACE .. #Karma_CommandQueue .. KARMA_MSG_COMMANDQUEUE_FULL2);
			else
				local	args = {};
				args[1] = "checkguild";
				args[2] = guildname;
				Karma_SlashCheckGuild(args);

				KarmaWindow2_PopulateWindow_Guild_Checkbox:SetChecked(0);
			end
		end
	end
KarmaChatDebug("<< KarmaWindow2_PopulateWindow_Execute");
end

function	KarmaObj.UI.OnLeave()
	GameTooltip:Hide();
end

function	KarmaWindow2_Message_EditBox_Tooltip()
	if Karma_ShowTooltipHelp() then
		GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT");
		GameTooltip:AddLine(KARMA_WINEL_MESSAGE_TO_SEND_TOOLTIP, 1, 1, 1);
		GameTooltip:Show();
	end
end

function	KarmaWindow2_SendMessage_OnEnter()
	if Karma_ShowTooltipHelp() then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		GameTooltip:AddLine(KARMA_WINEL_SENDMESS_TOOLTIP, 1, 1, 1);
		GameTooltip:Show();
	end
end

function	KarmaWindow2_SentMessage_OnEnter()
	if Karma_ShowTooltipHelp() then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		GameTooltip:AddLine(KARMA_WINEL_SENTMESS_TOOLTIP, 1, 1, 1);
		GameTooltip:Show();
	end
end

function	KarmaWindow2_PositiveReply_OnEnter()
	if Karma_ShowTooltipHelp() then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
		GameTooltip:AddLine(KARMA_WINEL_POSREPLY_TOOLTIP, 1, 1, 1);
		GameTooltip:Show();
	end
end

function	KarmaWindow2_SentMessage(entry)
	if (KARMA_Online.PlayersAll[entry.target].sendmess == 1) then
		KARMA_Online.PlayersAll[entry.target].sendmess = nil;
		KARMA_Online.PlayersAll[entry.target].sentmess = 1;

		KarmaWindow2_UpdateList2();
	end
end

function	KarmaWindow2_Invite()
	local	sMembername, Dummy;
	for sMembername, Dummy in pairs(KARMA_Online.PlayersChosen) do
		if (KARMA_Online.PlayersAll[sMembername].posreply == 1) then
			InviteUnit(sMembername);
		end
	end
end

function	Karma_CommandShareQuery(args)
	local	sAudience = args[2];
	local	sName = args[3];
	if (Karma_SlashShareQuery(args, 3, true)) then
		if (KARMA_OtherInfos[sName]) then
			if (sAudience == "$GUILD") then
				KARMA_OtherInfos[sName].Queried = bit.bor(KARMA_OtherInfos[sName].Queried, 1);
			end
			if (sAudience == "#") then
				KARMA_OtherInfos[sName].Queried = bit.bor(KARMA_OtherInfos[sName].Queried, 2);
			end
		end
	else
		Karma_QueueCommandShareQuery(sName);
	end

	-- delay next command by 5 seconds (we don't want other people to kill themselves by sending us notes!!)
	KarmaModuleLocal.Timers.CmdQ = GetTime() + 5;
end

function	Karma_QueueCommandShareQuery(sPlayername)
	if (IsInGuild() and (GetNumGuildMembers() > 1)) then
		Karma_CommandQueue[getn(Karma_CommandQueue)+1] = { sName = "sharequery - $GUILD - " .. sPlayername, func = Karma_CommandShareQuery, args = { [ 2 ] = "$GUILD", [ 3 ] = sPlayername } };
	end

	local	sChannel = Karma_GetConfig(KARMA_CONFIG.SHARE_CHANNEL_NAME);
	if (sChannel and (sChannel ~= "")) then
		Karma_CommandQueue[getn(Karma_CommandQueue)+1] = { sName = "sharequery - # - " .. sPlayername, func = Karma_CommandShareQuery, args = { [ 2 ] = "#", [ 3 ] = sPlayername } };
	end
end

function	KarmaWindow2_QueryNotesPub()
	local	sPlayername, Dummy, sQueued, iCount;
	sQueued = "";
	iCount = 0;
	for sPlayername, Dummy in pairs(KARMA_Online.PlayersChosen) do
		if (KARMA_Online.PlayersAll[sPlayername].queried ~= 1) then
			Karma_QueueCommandShareQuery(sPlayername);
			KARMA_Online.PlayersAll[sPlayername].queried = 1;
			sQueued = sQueued .. " " .. sPlayername;
			iCount = iCount + 1;
		end
	end

	KarmaChatSecondaryFallbackDefault("Queued sharedquery-requests for:" .. sQueued .. " (" .. iCount .. " total).");
end

function	KarmaWindow2_SendMessage()
	local	sMembername, Dummy, Text, iPos;
	Text = KarmaWindow2_Message_EditBox:GetText();
	iPos = strfind(Text, "%%");
	if (Text) and (Text ~= "") then
		for sMembername, Dummy in pairs(KARMA_Online.PlayersChosen) do
			local	oOnline = KARMA_Online.PlayersAll[sMembername];
			if (oOnline.sendmess == 1) then
				local	entry = {};
				entry.func = KarmaWindow2_SentMessage;
				entry.chattype = "WHISPER";
				if (oOnline.alt == true) then
					entry.target = oOnline.main;
				else
					entry.target = sMembername;
				end
				if (iPos) then
					-- replace %t with telltarget, %a with alt name
					entry.text = string.gsub(Text, "%%t", entry.target);
					if (oOnline.alt) then
						entry.text = string.gsub(Text, "%%a", sMembername);
					end
				else
					entry.text = Text;
				end
	
				Karma_MessageQueue[#Karma_MessageQueue + 1] = entry;
			end
		end
	end
end

function	KarmaWindow2_SendMessage_OnClick(button, buttonobject)
	local	id = buttonobject:GetID();
	local	button = getglobal("List2_Name" .. id .. "_Text");
	local	sMembername = button:GetText();
	if (sMembername ~= nil) and (sMembername ~= "") then
		if (KARMA_Online.PlayersAll[sMembername]) then
			local	CheckBoxObj = getglobal("List2_SendMessage" .. id);
			if (CheckBoxObj:GetChecked()) then
				KARMA_Online.PlayersAll[sMembername].sendmess = 1;
			else
				KARMA_Online.PlayersAll[sMembername].sendmess = nil;
			end
		end
	end
end

function	KarmaWindow2_PositiveReply_OnClick(button, buttonobject)
	local	id = buttonobject:GetID();
	local	button = getglobal("List2_Name"..id.."_Text");
	local	sMembername = button:GetText();
	if (sMembername ~= nil) and (sMembername ~= "") then
		if (KARMA_Online.PlayersAll[sMembername]) then
			local	CheckBoxObj = getglobal("List2_PositiveReply" .. id);
			if (CheckBoxObj:GetChecked()) then
				KARMA_Online.PlayersAll[sMembername].posreply = 1;
			else
				KARMA_Online.PlayersAll[sMembername].posreply = nil;
			end
		end
	end
end

local	KarmaWindow2_List1_SelectedMember;

function	Karma_MemberConflict_Menu_Initialize()
	KarmaObj.ProfileStart("Karma_MemberConflict_Menu_Initialize")

	local	oMember;
	if (KarmaWindow2_List1_SelectedMember ~= nil) then
		oMember = Karma_MemberList_GetObject(KarmaWindow2_List1_SelectedMember);
	end

	if (oMember) then
		local	sConflict = "";
		if	(oMember[KARMA_DB_L5_RRFFM_CONFLICT] ~= nil) and
			(oMember[KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
			sConflict = oMember[KARMA_DB_L5_RRFFM_CONFLICT].Conflict;
		end

		local	bLFMList = 	("List1_Name" == strsub(Karma_MemberConflict_Menu.Caller, 1, 10)) or
					("List2_Name" == strsub(Karma_MemberConflict_Menu.Caller, 1, 10));
		if (bLFMList or (sConflict ~= "")) then
			local	info;
			info = {};
			info.text = KarmaWindow2_List1_SelectedMember .. ": " .. (sConflict or "");
			info.isTitle = 1;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info);

			-- this gets secretly crapped by UIDropDownMenu.lua
			info.disabled = nil;

			-- remove title fields, prepare entry fields
			info.isTitle = nil;
			info.arg2 = KarmaWindow2_List1_SelectedMember;
			info.func = Karma_MemberConflict_Menu_OnSelect;

			if (sConflict ~= "") then
				info.text = "FORCE update of stored data to logged on player";
				info.arg1 = 1;
				UIDropDownMenu_AddButton(info);

				info.text = "Backup currently stored data and create a new entry";
				info.arg1 = 2;
				UIDropDownMenu_AddButton(info);
			end

			if (bLFMList) then
				info.text = "Select player in " .. KARMA_ITSELF .. "'s main window";
				info.arg1 = 3;
				UIDropDownMenu_AddButton(info);
			end
		end
	end

	KarmaObj.ProfileStop("Karma_MemberConflict_Menu_Initialize")
end

function	Karma_MemberConflict_Menu_OnSelect(self, arg1, arg2)
	KarmaObj.ProfileStart("Karma_MemberConflict_Menu_OnSelect")

	local	oMember = Karma_MemberList_GetObject(arg2);
	if (oMember ~= nil) and (arg1 ~= nil) then
		if (arg1 == 1) then
			local	args = {};
			args[2] = arg2;
			Karma_MemberForceUpdate(args);
		elseif (arg1 == 2) then
			local	args = {};
			args[2] = arg2;
			Karma_MemberForceNew(args);
		elseif (arg1 == 3) then
			Karma_SetCurrentMember(arg2);
			KarmaWindow_ScrollToCurrentMember();
			if (not KarmaWindow:IsVisible()) then
				KarmaWindow:Show();
			else
				KarmaWindow:Raise();
			end
		end
	end

	KarmaObj.ProfileStop("Karma_MemberConflict_Menu_OnSelect")
end

function	KarmaWindow_List1_OnClick(mousebutton, buttonobject)
	local	id = buttonobject:GetID();
	local	button = getglobal("List1_Name"..id.."_Text");
	local	sMembername = button.Membername;
	if (sMembername ~= nil) and (sMembername ~= "") then
		if (mousebutton == "LeftButton") then
			if (KARMA_Online.PlayersChosen[sMembername] == nil) then
				KARMA_Online.PlayersChosen[sMembername] = 1;

				KarmaWindow2_UpdateList2();
			end
		elseif (mousebutton == "MiddleButton") then
			Karma_UpdateMember(sMembername, true);
		elseif (mousebutton == "RightButton") then
			local	oMember = Karma_MemberList_GetObject(sMembername);
			if (oMember) then
				KarmaWindow2_List1_SelectedMember = sMembername;
				Karma_MemberConflict_Menu.Caller = buttonobject:GetName();
				ToggleDropDownMenu(1, nil, Karma_MemberConflict_Menu, buttonobject, 0, 0);
			end
		end
	end
end

function	KarmaWindow_List2_OnClick(mousebutton, buttonobject)
	local	id = buttonobject:GetID();
	local	button = getglobal("List2_Name"..id.."_Text");
	local	sMembername = button.Membername;
	if (sMembername ~= nil) and (sMembername ~= "") then
		if (mousebutton == "LeftButton") then
			KARMA_Online.PlayersChosen[sMembername] = nil;
			KarmaWindow2_UpdateList2();
		elseif (mousebutton == "RightButton") then
			local	oMember = Karma_MemberList_GetObject(sMembername);
			if (oMember) then
				KarmaWindow2_List1_SelectedMember = sMembername;
				Karma_MemberConflict_Menu.Caller = buttonobject:GetName();
				ToggleDropDownMenu(1, nil, Karma_MemberConflict_Menu, buttonobject, 0, 0);
			end
		end
	end
end

function	KarmaWindow_List1_OnEnter()
	local	id = this:GetID();
	local	button = getglobal("List1_Name"..id.."_Text");
	local	sName = button.Membername;
	if (sName ~= nil and sName ~= "" and sName ~= KARMA_UNKNOWN and sName ~= KARMA_UNKNOWN_ENT) then
		if (KARMA_Online.PlayersAll[sName]) then
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
			if (KARMA_Online.PlayersAll[sName].zone) then
				GameTooltip:AddLine(KARMA_Online.PlayersAll[sName].zone, 1, 1, 1);
			end

			local	bGotGuild;
			if (KARMA_Online.PlayersAll[sName].guild) and (KARMA_Online.PlayersAll[sName].guild ~= "") then
				bGotGuild = true;
			end

			if (KARMA_Online.PlayersAll[sName].lfg and
			    (time() - KARMA_Online.PlayersAll[sName].lfg < 300)) then
				local	sec = time() - KARMA_Online.PlayersAll[sName].lfg;
				local	min = math.floor(sec / 60);
				sec = sec % 60;
				if (sec < 10) then
					sec = "0" .. sec;
				end
				GameTooltip:AddLine("|cFF40FF40" .. KARMA_CHANNELNAME_LFG .. "|r less than " .. min .. ":" .. sec .. " ago", 1, 1, 1);
			end

			local	oMember = Karma_MemberList_GetObject(sName);
			if (oMember) then
				if	(oMember[KARMA_DB_L5_RRFFM_CONFLICT] ~= nil) and
					(oMember[KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
					GameTooltip:AddLine("CONFLICT: " .. oMember[KARMA_DB_L5_RRFFM_CONFLICT].Conflict, 1, 0, 0);
				end

				local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
				if (bModified) then
					local	red, green, blue = Karma_Karma2Color(iKarma);
					GameTooltip:AddLine(KARMA_ITSELF .. KARMA_WINEL_FRAG_COLONSPACE .. Karma_MemberObject_GetKarmaWithModifiers(oMember), red, green, blue);
				end

				if (bGotGuild) then
					GameTooltip:AddLine("<" .. KARMA_Online.PlayersAll[sName].guild .. ">", 1, 1, 1);
				else
					local	Guild = Karma_MemberObject_GetGuild(oMember);
					if (Guild) and (Guild ~= "") then
						GameTooltip:AddLine("<" .. Guild .. ">", 1, 1, 1);
					end
				end

				local	altid = Karma_MemberObject_GetAltID(oMember);
				if (altid) and (altid >= 0) then
					local	sAlts = Karma_AltID2Names(altid, 5, KARMA_MSG_LFM_LIST1TIP_ALTS .. KARMA_WINEL_FRAG_COLONSPACE);
					if (sAlts) and (sAlts ~= "") then
						GameTooltip:AddLine(sAlts, 0.8, 1, 1);
					end
				end

				if (Karma_GetConfig(KARMA_CONFIG.TOOLTIP_TALENTS) == 1) then
					local	oLines, sSummarySub, iTimeOfTalents = KarmaObj.Talents.MemberObjToStringsObj(oMember, bShiftPressed);

					local	i;
					for i = 1, #oLines do
						if (iTimeOfTalents) then
							GameTooltip:AddLine("Talents as of " .. date(KARMA_DATEFORMAT, iTimeOfTalents) .. ":", 1, 1, 1);
							iTimeOfTalents = nil;
						end
						GameTooltip:AddLine(oLines[i], 1, 1, 1);
					end
				end

				local	sNote = Karma_MemberObject_GetNotes(oMember);
				if (sNote) and (sNote ~= "") then
					GameTooltip:AddLine("-------------------------", 1, 1, 0);
					local	sExtract = KarmaModuleLocal.Helper.ExtractHeader(sNote);
					GameTooltip:AddLine(sExtract, 0.7, 0.9, 0.7, 1);
				end
			elseif (bGotGuild) then
				GameTooltip:AddLine("<" .. KARMA_Online.PlayersAll[sName].guild .. ">", 1, 1, 1);
			end

			GameTooltip:Show();
		end
	end
end

function	KarmaWindow_List2_OnEnter()
	local	id = this:GetID();
	local	button = getglobal("List2_Name"..id.."_Text");
	local	sName = button.Membername;
	if (sName ~= nil and sName ~= "" and sName ~= KARMA_UNKNOWN and sName ~= KARMA_UNKNOWN_ENT) then
		if (KARMA_Online.PlayersAll[sName]) and
			(KARMA_Online.PlayersAll[sName].zone or KARMA_Online.PlayersAll[sName].guild or KarmaModuleLocal.NotesPublic.Results[sName]) then
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT");

			if (KARMA_Online.PlayersAll[sName].zone) then
				GameTooltip:AddLine(KARMA_Online.PlayersAll[sName].zone, 1, 1, 1);
			end
			if (KARMA_Online.PlayersAll[sName].guild) and (KARMA_Online.PlayersAll[sName].guild ~= "") then
				GameTooltip:AddLine("<" .. KARMA_Online.PlayersAll[sName].guild .. ">", 1, 1, 1);
			end

			if (KarmaModuleLocal.NotesPublic.Results[sName] ~= nil) then
				local	sFrom, aStance;
				for sFrom, aStance in pairs(KarmaModuleLocal.NotesPublic.Results[sName]) do
					local	sFromOut = sFrom;
					local	red, green, blue = Karma_GetColors_Karma(sFrom);
					if (red + green + blue < 2.95) then
						sFromOut = format("|cFF%02x%02x%02x%s|r", blue, green, red, sFrom);
					end

					local	sLine = sFromOut .. " says:";
					if (aStance.sKarma) then
						sLine = sLine .. " [" .. aStance.sKarma .. "]";
					end
					if (aStance.sNotePub) then
						sLine = sLine .. " => <<" .. aStance.sNotePub .. ">>";
					end
					GameTooltip:AddLine(sLine, 1, 1, 1);
				end
			else
				GameTooltip:AddLine("No information available.");
			end

			GameTooltip:Show();
		end
	end
end

local	Karma_ClassToBucket =
	{
		[  5 ] =  1;	-- priest
		[  7 ] =  2;	-- shaman
		[  1 ] =  3;	-- druid
		[  4 ] =  4;	-- paladin
		[  8 ] =  5;	-- warrior
		[ 10 ] =  6;	-- deathknight
		[  6 ] =  7;	-- rogue
		[  3 ] =  8;	-- mage
		[  9 ] =  9;	-- warlock
		[  2 ] = 10;	-- hunter
	};

function	KARMA_OnlinePlayersAll_Sort(lMemberNames)
	-- two big buckets:
		-- with Karma
		-- without Karma
	local	PlayersWKarma = {};
	local	PlayersWOKarma = {};

	-- Karma bucket:
		-- bucket 1: HPS
		-- bucket 2: TANK, FERAL
		-- bucket 9: DPS
		-- bucket 3-8, 10-13: Karma_ClassToBucket
		-- bucket 14: w/o class
	local	iCount;
	for iCount = 1, 14 do
		PlayersWKarma[iCount] = {};
	end

	-- non-Karma bucket:
		-- bucket 1-10: Karma_ClassToBucket
		-- bucket 11: w/o class
	local	iCount;
	for iCount = 1, 11 do
		PlayersWOKarma[iCount] = {};
	end

	Karma_WhoAmIInit();

	local	key, value, classbucket, bucket, iSpec, iClass, sClass, iShift, iDelta, iLevel;
	local	aTalents = {};
	for key, value in pairs(lMemberNames) do
		if (value == WhoAmI) then
			lMemberNames[key] = nil;
		else
			local	oMember = Karma_MemberList_GetObject(value);
			if (oMember) then
				iShift = 1;
				iDelta = 2;
				local	bPattern;
				for iSpec = 1, KarmaObj.Talents.SpecCount do
					aTalents["S_" .. iSpec], bPattern = Karma_MemberObject_GetTalentID(oMember, iSpec);
					if (bPattern) then
						local	iDerived = KarmaObj.Talents.MemberObjSpecNumToTalent(oMember, iSpec);
						if (iDerived) then
							aTalents["S_" .. iSpec] = iDerived;
						end
					end
				end
				for iSpec = KarmaObj.Talents.SpecCount, 2, -1 do
					if (aTalents["S_" .. iSpec] == aTalents["S_1"]) then
						aTalents["S_" .. iSpec] = nil;
					end
				end
				iLevel = Karma_MemberObject_GetLevel(oMember);
				-- forceupdate'd member? -> don't lose because of level -> 0...
				if (iLevel == 0) then
					iLevel = nil;
				end
				sClass = Karma_MemberObject_GetClass(oMember);
				iClass = Karma_ClassToID(sClass);
			else
				iShift = 0;
				iDelta = 0;
				iTalent = nil;
				iTalentRaw = nil;
				iLevel = KARMA_Online.PlayersAll[value].level;
				sClass = KARMA_Online.PlayersAll[value].class;
				iClass = Karma_ClassToID(sClass);
			end

			bucket = 11;
			if (oMember) then
				for iSpec = 1, KarmaObj.Talents.SpecCount do
					local	iTalent = aTalents["S_" .. iSpec];
					if (iTalent) and (iTalent ~= 0) then
						iTalent = bit.band(iTalent, 7);
						if (iTalent ~= 0) then
							if (bit.band(iTalent, 1) == 1) then
								-- HPS: -1 (1)
								if (bucket) then
									bucket = math.min(bucket, -1);
								else
									bucket = -1;
								end
							elseif (bit.band(iTalent, 2) == 2) then
								-- TANK/FERAL: 0 (2)
								if (bucket) then
									bucket = math.min(bucket, 0);
								else
									bucket = 0;
								end
							elseif (bit.band(iTalent, 4) == 4) then
								-- DPS: 7 (9)
								if (bucket) then
									bucket = math.min(bucket, 7);
								else
									bucket = 7;
								end
							end
						end
-- KarmaChatDebug(Karma_MemberObject_GetName(oMember) .. ".Talent[" .. iSpec .. "] = " .. iTalent);	-- ###
					end
				end
			end

			classbucket = nil;
			if (iClass) and (iClass ~= 0) then
				if (iClass < 0) then
					iClass = - iClass;
				end

				if (Karma_ClassToBucket[iClass]) then
					classbucket = Karma_ClassToBucket[iClass];

					if ((bucket == 11) or
					    (bucket == 7) and (classbucket >= 7)) then
						bucket = classbucket;
						if (bucket >= 7) then
							bucket = bucket + iShift;
						end
					end
				end
			end

			local	bAdd = true;
			if (iLevel) and (KARMA_Online.PlayersAllFilter.LevelFrom) and (KARMA_Online.PlayersAllFilter.LevelTo) then
				if (iLevel < KARMA_Online.PlayersAllFilter.LevelFrom) or (iLevel > KARMA_Online.PlayersAllFilter.LevelTo) then
					bAdd = false;
				end
			end

			if (bAdd) and (oMember) then
				if (KARMA_Online.PlayersAllFilter.minKarma) then
					local	iKarma = Karma_MemberObject_GetKarma(oMember);
					if (iKarma) and (iKarma > 0) then
						if (iKarma < KARMA_Online.PlayersAllFilter.minKarma) then
							bAdd = false;
						end
					end
				end

				if (bAdd) and (KARMA_Online.PlayersAllFilter.minSkill) then
					local	iSkill = Karma_MemberObject_GetSkill(oMember);
					if (iSkill) and (iSkill >= 0) then
						if (iSkill < KARMA_Online.PlayersAllFilter.minSkill) then
							bAdd = false;
						end
					end
				end
			end

			if (bAdd) and (oMember) then
				if (bucket == -1) and (KARMA_Online.PlayersAllFilter.TalentHPS ~= 1) then
					bAdd = false;
				elseif (bucket == 0) and (KARMA_Online.PlayersAllFilter.TalentTANK ~= 1) then
					bAdd = false;
				elseif (bucket == 7) and (KARMA_Online.PlayersAllFilter.TalentDPS ~= 1) then
					bAdd = false;
				end
			end

			if (bAdd) and (iClass) and (classbucket) then
				-- some classes cannot be HPS, DPS, TANK...
				-- KARMA_TALENT_CLASSMASK sums the total of each class
				local	classmask = KARMA_TALENT_CLASSMASK[iClass];
				local	role, distance = 0, 0;
				for iSpec = 1, KarmaObj.Talents.SpecCount do
					local	iTalent = aTalents["S_" .. iSpec];
					if (iTalent) and (iTalent ~= 0) then
						role     = bit.bor(role,     bit.band(iTalent,  7));
						distance = bit.bor(distance, bit.band(iTalent, 24));
					end
				end
				if (role == 0) then
					role = bit.band(classmask, 7);
				end
				if (distance == 0) then
					distance = bit.band(classmask, 24);
				end

				local	choicemask = 0;
				if (KARMA_Online.PlayersAllFilter.TalentHPS == 1) then
					choicemask = choicemask + 1;
				end
				if (KARMA_Online.PlayersAllFilter.TalentTANK == 1) then
					choicemask = choicemask + 2;
				end
				if (KARMA_Online.PlayersAllFilter.TalentDPS == 1) then
					choicemask = choicemask + 4;
				end
				if (bit.band(role, choicemask) == 0) then
					bAdd = false;
				end

				choicemask = 0;
				if (KARMA_Online.PlayersAllFilter.TalentMelee == 1) then
					choicemask = choicemask + 8;
				end
				if (KARMA_Online.PlayersAllFilter.TalentRange == 1) then
					choicemask = choicemask + 16;
				end
				if (bit.band(distance, choicemask) == 0) then
					bAdd = false;
				end
			end

			if (bAdd) and (iClass) and (classbucket) then
				if (iClass == 1) and (KARMA_Online.PlayersAllFilter.ClassDruid ~= 1) then
					bAdd = false;
				elseif (iClass == 2) and (KARMA_Online.PlayersAllFilter.ClassHunter ~= 1) then
					bAdd = false;
				elseif (iClass == 3) and (KARMA_Online.PlayersAllFilter.ClassMage ~= 1) then
					bAdd = false;
				elseif (iClass == 4) and (KARMA_Online.PlayersAllFilter.ClassPaladin ~= 1) then
					bAdd = false;
				elseif (iClass == 5) and (KARMA_Online.PlayersAllFilter.ClassPriest ~= 1) then
					bAdd = false;
				elseif (iClass == 6) and (KARMA_Online.PlayersAllFilter.ClassRogue ~= 1) then
					bAdd = false;
				elseif (iClass == 7) and (KARMA_Online.PlayersAllFilter.ClassShaman ~= 1) then
					bAdd = false;
				elseif (iClass == 8) and (KARMA_Online.PlayersAllFilter.ClassWarrior ~= 1) then
					bAdd = false;
				elseif (iClass == 9) and (KARMA_Online.PlayersAllFilter.ClassWarlock ~= 1) then
					bAdd = false;
				elseif (iClass == 10) and (KARMA_Online.PlayersAllFilter.ClassDeathknight ~= 1) then
					bAdd = false;
				end
			end

			if (bAdd) then
				if (oMember) then
					if (PlayersWKarma[bucket + 2]) then
						tinsert(PlayersWKarma[bucket + 2], value);
-- KarmaChatDebug("player " .. value .. " => bucket " .. bucket);
					else
						KarmaChatDebug("Failed to add " .. value .. ", selected bucket " .. bucket .. " is invalid.");
					end
				else
					if (PlayersWOKarma[bucket]) then
						tinsert(PlayersWOKarma[bucket], value);
					else
						KarmaChatDebug("Failed to add " .. value .. ", selected bucket " .. bucket .. " is invalid.");
					end
				end
			end
		end
	end

	local	SkipClassLess;
	if (KARMA_Online.PlayersAllFilter.ClassKnown == 1) then
		SkipClassLess = 1;
	else
		SkipClassLess = 0;
	end

	local	timecurrent = time();

	local	Result = {};

	for iCount = 1, (14 - SkipClassLess) do
		for key, value in pairs(PlayersWKarma[iCount]) do
			local	bLFG   = ((KARMA_Online.PlayersAll[value].lfg ~= nil) and
					  (timecurrent - KARMA_Online.PlayersAll[value].lfg < 300));
			if (bLFG) then
				tinsert(Result, value);
			end
		end
	end

	for iCount = 1, (14 - SkipClassLess) do
		for key, value in pairs(PlayersWKarma[iCount]) do
			local	bLFG   = ((KARMA_Online.PlayersAll[value].lfg ~= nil) and
					  (timecurrent - KARMA_Online.PlayersAll[value].lfg < 300));
			if (not bLFG) then
				tinsert(Result, value);
			end
		end
	end

	if (KARMA_Online.PlayersAllFilter.KarmaReq ~= 1) then
		for iCount = 1, (11 - SkipClassLess) do
			for key, value in pairs(PlayersWOKarma[iCount]) do
				local	bLFG   = ((KARMA_Online.PlayersAll[value].lfg ~= nil) and
						  (timecurrent - KARMA_Online.PlayersAll[value].lfg < 300));
				if (bLFG) then
					tinsert(Result, value);
				end
			end
		end
		for iCount = 1, (11 - SkipClassLess) do
			for key, value in pairs(PlayersWOKarma[iCount]) do
				local	bLFG   = ((KARMA_Online.PlayersAll[value].lfg ~= nil) and
						  (timecurrent - KARMA_Online.PlayersAll[value].lfg < 300));
				if (not bLFG) then
					tinsert(Result, value);
				end
			end
		end
	end

	return Result;
end

local	RegionnamesToRegionIDs = {};

local	function	UpdateRegions()
	-- KARMA_Online.PlayersAll[sMembername].zone: add RegionID field
	local	RegionList = CommonRegionListGet();
	local	key, value, subkey, subvalue;
	for key, value in pairs(KARMA_Online.PlayersAll) do
		if (value.zone ~= nil) and (value.RegionID == nil) then
			if (RegionnamesToRegionIDs[value.zone] ~= nil) then
				value.RegionID = RegionnamesToRegionIDs[value.zone];
			else
				for subkey, subvalue in pairs(RegionList) do
					if (subvalue.Name == value.zone) then
						value.RegionID = subkey;
					end
				end

				RegionnamesToRegionIDs[value.zone] = value.RegionID;
			end
		end
	end
end

function	KarmaWindow2_UpdateList(which)
	KarmaObj.ProfileStart("KarmaWindow2_UpdateList");

	local	timecurrent = time();

	local	MemberNames;
	local	key, value;

	local	ListSize, ScrollFrame;
	if (which == "List1_") then
		ListSize = KARMA_LFGWND_LIST1_SIZE;
		ScrollFrame = KarmaWindow2_List1_ScrollFrame;
	else
		ListSize = KARMA_LFGWND_LIST2_SIZE;
		ScrollFrame = KarmaWindow2_List2_ScrollFrame;
	end

	if (which == "List1_") then
		-- delete entries over 60m (once per minute)
		if (KARMA_Online.PlayersAllCache.List1_Clean == nil) then
			KARMA_Online.PlayersAllCache.List1_Clean = timecurrent;
		elseif (timecurrent - KARMA_Online.PlayersAllCache.List1_Clean > 60) then
			local	bUpdate;
			for key, value in pairs(KARMA_Online.PlayersAll) do
				-- only if not selected...
				if (KARMA_Online.PlayersChosen[key] == nil) then
					-- ... and age > 60m
					if (timecurrent - value.time > 3600) then
						KARMA_Online.PlayersAll[key] = nil;
						bUpdate = true;
					end
				end

				if ((value.lfg ~= nil) and (timecurrent - value.lfg > 300)) then
					value.lfg = nil;
					bUpdate = true;
				end
			end
			-- request cache update
			if (bUpdate) then
				KARMA_Online.PlayersVersion = KARMA_Online.PlayersVersion + 1;
			end
		end

		if (KARMA_Online.PlayersVersion ~= KARMA_Online.PlayersAllCache.Version) then
			UpdateRegions();

			KARMA_Online.PlayersAllCache.Version = Version;
			KARMA_Online.PlayersAllCache.List1_Raw = {};
			KARMA_Online.PlayersAllCache.List1_Srt = {};

			local	AltsObj;
			if (KARMA_Online.PlayersAllFilter.Alts) then
				AltsObj = KarmaObj.DB.FactionCacheGet()[KARMA_DB_L4_RRFF.ALTGROUPS];
			end
			local	oRemove, oAdd = {}, {};
			for key, value in pairs(KARMA_Online.PlayersAll) do
				if (value.alt) then
					if (AltsObj == nil) then
						tinsert(oRemove, key);
					end
				else
					-- KarmaChatDebug("MemberNames += " .. key);
					tinsert(KARMA_Online.PlayersAllCache.List1_Raw, key);
					if (AltsObj) then
						local	oMember = Karma_MemberList_GetObject(key);
						if (oMember) then
							local	altid = Karma_MemberObject_GetAltID(oMember);
							if (altid ~= -1) then
								local	key1, value1;
								for key1, value1 in pairs(AltsObj) do
									if (value1.ID == altid) then
										local	key2, value2;
										for key2, value2 in pairs(value1.AL) do
											if (value2 ~= key) then
												tinsert(KARMA_Online.PlayersAllCache.List1_Raw, value2);
												oAdd[value2] = { main = key, alt = true, time = value.time, zone = value.zone };
											end
										end

										break;
									end
								end
							end
						end
					end
				end
			end
			for key, value in pairs(oRemove) do
				KARMA_Online.PlayersAll[key] = nil;
			end
			for key, value in pairs(oAdd) do
				if (KARMA_Online.PlayersAll[key] == nil) then
					KARMA_Online.PlayersAll[key] = value;
				end
			end

			MemberNames = Karma_CopyTable(KARMA_Online.PlayersAllCache.List1_Raw);
			
			-- pre-sort alphabetically, then into special sort into buckets
			MemberNames = KOH.AlphaBucketSort(MemberNames);
			MemberNames = KARMA_OnlinePlayersAll_Sort(MemberNames);

			KARMA_Online.PlayersAllCache.List1_Srt = Karma_CopyTable(MemberNames);
		else
			MemberNames = KARMA_Online.PlayersAllCache.List1_Srt;
		end
	else
		MemberNames = {};
		for key, value in pairs(KARMA_Online.PlayersChosen) do
			-- KarmaChatDebug("MemberNames += " .. key);
			tinsert(MemberNames, key);
		end

		-- pre-sort alphabetically, then into special sort into buckets
		MemberNames = KOH.AlphaBucketSort(MemberNames);
		MemberNames = KARMA_OnlinePlayersAll_Sort(MemberNames);
	end

	local	i = 0;
	for key, value in pairs(MemberNames) do
		i = i + 1;
	end
	local	iNumEntries = i;

-- KarmaChatDebug("KarmaWindow2_UpdateList(" .. which .. "): " .. tostring(iNumEntries) .. " entries.");

	-- clear all buttons from current values:
	local	oTalentBtn = { [1] = "L", [2] = "R" };
	local	buttontext, k;
	for i = 1, ListSize do
		buttontext = getglobal(which .. "Online"..i.."_Text");
		buttontext:SetText("");
		buttontext = getglobal(which .. "KarmaValue"..i.."_Text");
		buttontext:SetText("");
		buttontext = getglobal(which .. "Name"..i.."_Text");
		buttontext:SetText("");
		buttontext.Membername = nil;
		buttontext = getglobal(which .. "ClassLvl"..i.."_Text");
		buttontext:SetText("");
		for k = 1, 2 do
			buttontext = getglobal(which .. "Talent" .. i .. "_Text" .. oTalentBtn[k]);
			buttontext:SetText("");
			buttontext = getglobal(which .. "Talent" .. i .. "_Icon" .. oTalentBtn[k]);
			buttontext:SetTexture("");
		end
		buttontext = getglobal(which .. "Talent" .. i .. "_TextWide");
		buttontext:SetText("");
		buttontext = getglobal(which .. "Location"..i.."_Text");
		buttontext:SetText("");

		if (which == "List2_") then
			buttontext = getglobal(which .. "SendMessage"..i);
			buttontext:SetChecked(0);
			buttontext = getglobal(which .. "SentMessage"..i);
			buttontext:SetChecked(0);
			buttontext = getglobal(which .. "PositiveReply"..i);
			buttontext:SetChecked(0);
		end
	end

	local	RegionList = CommonRegionListGet();

	local	iCounter = 1;
	local	nindex = 1;
	local	oMember, sClass, iClass, iSpec, iTalents, sTalents;
	local	timediff, minutes, seconds;
	local	red, green, blue;
	local	iSpecCount = math.min(KarmaObj.Talents.SpecCount, 2);
	for key, sMembername in pairs(MemberNames) do
		--search the index of the array for the current users name
		if (nindex - FauxScrollFrame_GetOffset(ScrollFrame)  >= 0) then
			if (iCounter <= ListSize) then
				timediff = timecurrent - KARMA_Online.PlayersAll[sMembername].time;
				minutes = floor(timediff / 60);
				seconds = timediff - (minutes * 60);
				if (seconds < 10) then
					seconds = "0".. tostring(seconds);
				end
				local checktime;
				if (timediff >= 600) then
					checktime = tostring(minutes) .. "m";
				else
					checktime = tostring(minutes) .. ":" .. tostring(seconds);
				end
				if (KARMA_Online.PlayersAll[sMembername].lfg and
				    (timecurrent - KARMA_Online.PlayersAll[sMembername].lfg < 300)) then
					checktime = "|cFF40FF40" .. checktime .. "|r";
				end

				buttontext = getglobal(which .. "Online"..iCounter.."_Text");
				buttontext:SetText(checktime);

				local	zonetext = getglobal(which .. "Location"..iCounter.."_Text");
				if (KARMA_Online.PlayersAll[sMembername].zone) then
					local	Color = "|cFFA0A0A0";
					local	RegionID = KARMA_Online.PlayersAll[sMembername].RegionID;
					if (RegionID ~= nil) and (RegionList[RegionID] ~= nil) then
						local	bPvp = RegionList[RegionID][KARMA_DB_L3_CR.ISPVPZONE];
						local	iInstance = RegionList[RegionID][KARMA_DB_L3_CR.ZONETYPE];
						if (bPvp) or (iInstance == 1) then
							Color = "|cFFFF4040";				-- red
						elseif (iInstance) then
							if (iInstance == 0) then
								Color = "|cFFFFFF00";			-- yellow
							elseif (iInstance == 5) then
								Color = "|cFF00FFFF";			-- turquoise
							elseif (iInstance == 10) then
								Color = "|cFF6060FF";			-- blue
							elseif (iInstance == 25) then
								Color = "|cFFFF00FF";			-- purple
							end
						end
					end

					if (which == "List1_") then
						zonetext:SetText(Color .. KARMA_Online.PlayersAll[sMembername].zone .. "|r");
					else
						-- cut down, don't want it to creep under the checkboxes
						zonetext:SetText(Color .. strsub(KARMA_Online.PlayersAll[sMembername].zone, 1, 12) .. "|r");
					end
				end

				local	nametext = getglobal(which .. "Name"..iCounter.."_Text");
				nametext:SetText(sMembername);
				nametext.Membername = sMembername;
				if (KARMA_Online.PlayersAllFilter.Alts) then
					if (KARMA_Online.PlayersAll[sMembername].alt) then
						nametext:SetText("(" .. sMembername .. ")");
						local	zone = zonetext:GetText() or "<place unknown>";
						zonetext:SetText("Main: " .. KARMA_Online.PlayersAll[sMembername].main .. " >> " .. zone);
					end
				end

				local	bTalent = false;

				oMember = Karma_MemberList_GetObject(sMembername);
				if (oMember == nil) then
					sClass = KARMA_Online.PlayersAll[sMembername].class;
					if (KARMA_Online.PlayersAll[sMembername].class) then
						iClass = Karma_ClassToID(sClass);
						if (iClass < 0) then
							iClass = - iClass;
						end
						sClass = Karma_IDToClass(iClass);
					end
					red, green, blue = Karma_ClassMToColor(sClass);
					nametext:SetTextColor(red, green, blue);

					if (KARMA_Online.PlayersAll[sMembername].level and KARMA_Online.PlayersAll[sMembername].class) then
						local	sClassSub = KARMA_Online.PlayersAll[sMembername].class;
						local	iSpace = strfind(sClassSub, " ", 1, true);
						if (iSpace) then
							sClassSub = strsub(sClassSub, 1, iSpace - 1);
						end
						local	classlvltext = getglobal(which .. "ClassLvl"..iCounter.."_Text");
						classlvltext:SetText(KARMA_Online.PlayersAll[sMembername].level .. sClassSub);

						local	sClass = KARMA_Online.PlayersAll[sMembername].class;
						local	iClass = Karma_ClassToID(sClass);
						if (sClass and iClass) then
							iTalents = KARMA_TALENT_CLASSMASK[math.abs(iClass)];
							if (iTalents and (bit.band(iTalents, 7) == 4)) then
								local	sDistance, sTexture, xmin, xmax = KarmaObj.Talents.TalentID2TextureDistance(iTalents, iClass);
								if (sTexture) then
									bTalent = true;
									local	texture    = getglobal(which .. "Talent" .. iCounter .. "_IconL");
									texture:SetTexture(sTexture);
									texture:SetTexCoord(xmin, xmax, 0, 1);
									local	talenttext = getglobal(which .. "Talent" .. iCounter .. "_TextL");
									talenttext:SetText(sDistance);
								end
							end
						end
					end
				else
					red, green, blue = Karma_GetColors_Class(sMembername);
					nametext:SetTextColor(red, green, blue);

					red, green, blue = Karma_GetColors_Karma(sMembername);
					local	iKarma, bModified = Karma_MemberObject_GetKarmaModified(oMember);
					local	sKarma;
					if (iKarma >= 100) then
						sKarma = "++";
					else
						sKarma = iKarma;
					end
					if (bModified) then
						sKarma = "*" .. sKarma;
					end
					local	karmavaluetext = getglobal(which .. "KarmaValue"..iCounter.."_Text");
					karmavaluetext:SetText(sKarma);
					karmavaluetext:SetTextColor(red, green, blue);

					local	sClass, iClass = Karma_MemberObject_GetClass(oMember);
					local	classlvltext = getglobal(which .. "ClassLvl"..iCounter.."_Text");
					if	(oMember[KARMA_DB_L5_RRFFM_CONFLICT] ~= nil) and
						(oMember[KARMA_DB_L5_RRFFM_CONFLICT].Resolved == 0) then
						classlvltext:SetText("|cFFFF0000CONFLICT!|r");
					else
						local	sClassSub = sClass;
						-- cutting the deathknight
						local	iSpace = strfind(sClassSub, " ", 1, true);
						if (iSpace) then
							sClassSub = strsub(sClassSub, 1, iSpace - 1);
						end
						classlvltext:SetText(Karma_MemberObject_GetLevel(oMember) .. sClassSub);
					end

					bTalent = true;
					local	oTalents, bOnlyText, bOnlyTextures, j, i = {}, true, true;
					for i = 1, iSpecCount do
						sTalents, iTalents = Karma_MemberObject_GetTalentColorizedText(oMember, i);
						local	talenttext = getglobal(which .. "Talent" .. iCounter .. "_Text" .. oTalentBtn[i]);
						local	texture    = getglobal(which .. "Talent" .. iCounter .. "_Icon" .. oTalentBtn[i]);
						local	sDistance, sTexture, xmin, xmax = KarmaObj.Talents.TalentID2TextureDistance(iTalents, iClass);
						if (sTexture) then
							texture:SetTexture(sTexture);
							texture:SetTexCoord(xmin, xmax, 0, 1);
							talenttext:SetText(sDistance);

							oTalents[i] = { Texture = sTexture, Distance = sDistance };
							bOnlyText = false;
						else
							texture:SetTexture("");
							for j = 1, i - 1 do
								if (oTalents[j] and (sTalents == oTalents[j].AsText)) then
									sTalents = "";
									break;
								end
							end

							talenttext:SetText(sTalents);
							if (sTalents ~= "") then
								oTalents[i] = { AsText = sTalents };
								bOnlyTextures = false;
							end
						end
					end

					if (iSpecCount > 1) then
						-- caveat: speccount == 2
						if (bOnlyText and (oTalents[iSpecCount] == nil)) then
							local	talenttextL = getglobal(which .. "Talent" .. iCounter .. "_Text" .. oTalentBtn[1]);
							local	talenttextW = getglobal(which .. "Talent" .. iCounter .. "_TextWide");
							talenttextW:SetText(talenttextL:GetText());
							talenttextL:SetText("");
						end
						-- caveat: speccount == 2
						if (bOnlyTextures) then
							local	bEqual = (oTalents[1] ~= nil) and (oTalents[iSpecCount] ~= nil);
							if (bEqual) then
								bEqual = (oTalents[1].Texture  == oTalents[iSpecCount].Texture) and
									 (oTalents[1].Distance == oTalents[iSpecCount].Distance);
							end
							if (bEqual) then
								local	talenttext = getglobal(which .. "Talent" .. iCounter .. "_Text" .. oTalentBtn[iSpecCount]);
								local	texture    = getglobal(which .. "Talent" .. iCounter .. "_Icon" .. oTalentBtn[iSpecCount]);
								texture:SetTexture(nil);
								talenttext:SetText("");
							end
						end
					end
				end

				if (not bTalent) then
					local	sText = KARMA_MISSING_INFO;
					local	sClass = KARMA_Online.PlayersAll[sMembername].class;
					local	iClass = Karma_ClassToID(sClass);
					if (sClass and iClass) then
						iTalents = KARMA_TALENT_CLASSMASK[math.abs(iClass)];
						if (iTalents and (iTalents ~= 0)) then
							-- above we tested for DPS/?, now only ???/M and ???/R remains
							if (bit.band(iTalents, 3) ~= 0) then
								local	iDistance = bit.band(iTalents, 24);
								if (iDistance ~= 24) then
									sText = sText .. "/" .. KarmaObj.Talents.TalentID2Distance(iDistance);
								end
							end
						end
					end

					local	talenttext = getglobal(which .. "Talent" .. iCounter .. "_TextWide");
					talenttext:SetText(sText);
				end

				if (which == "List2_") then
					if (KARMA_Online.PlayersAll[sMembername].sendmess == 1) then
						buttontext = getglobal(which .. "SendMessage" .. iCounter);
						buttontext:SetChecked(1);
					end

					if (KARMA_Online.PlayersAll[sMembername].sentmess == 1) then
						buttontext = getglobal(which .. "SentMessage" .. iCounter);
						buttontext:SetChecked(1);
					end

					if (KARMA_Online.PlayersAll[sMembername].posreply == 1) then
						buttontext = getglobal(which .. "PositiveReply" .. iCounter);
						buttontext:SetChecked(1);
					end
				end

				iCounter = iCounter+1;
			end
		end
		nindex = nindex+1;
	end

	local	ExtraLines = ListSize - (ListSize % 2);
	ExtraLines = ExtraLines / 2;
	FauxScrollFrame_Update(ScrollFrame, iNumEntries + ExtraLines, ListSize, 13, nil, 0, 0);

	KarmaObj.ProfileStop("KarmaWindow2_UpdateList");
end

function	KarmaWindow2_UpdateList1()
	KarmaWindow2_UpdateList("List1_");
end

function	KarmaWindow2_UpdateList2()
	KarmaWindow2_UpdateList("List2_");
end

function	KarmaWindow2_OnShow()
	if (KarmaModuleLocal.KarmaWindow2_ShowInital == 0) then
		KarmaModuleLocal.KarmaWindow2_ShowInital = 1;
		if (GetChannelName(KARMA_CHANNELNAME_LFG) > 0) then
			Karma_QueueCommandChannelCheck(KARMA_CHANNELNAME_LFG);
		end
	end

	if (GetGuildInfo("player") ~= nil) then
		GuildRoster();
		Karma_WhoAmIInit();
		local	iNow = time();
		if (GetNumGuildMembers() > 1) then
			local	iCnt, i = GetNumGuildMembers();
			for i = 1, iCnt do
				local	sName, _, _, iLvl, sClass, sZone = GetGuildRosterInfo(i);
				if (sName and (sName ~= WhoAmI)) then
					local	oPlayer = KARMA_Online.PlayersAll[sName];
					if (oPlayer == nil) then
						oPlayer = {};
						KARMA_Online.PlayersAll[sName] = oPlayer;
					end

					oPlayer.time = iNow;
					oPlayer.level = iLvl;
					oPlayer.class = sClass;
					oPlayer.zone = sZone;
				end
			end
		end
	end

	KarmaWindow2_UpdateList1();
	KarmaWindow2_UpdateList2();
end

function	KarmaWindow2_CreateButtons()
	if (KarmaModuleLocal.KarmaWindow2_CreatedButtons == 0) then
		KarmaModuleLocal.KarmaWindow2_CreatedButtons = 1;

		local	ButtonList = { "Online", "KarmaValue", "Name", "ClassLvl", "Talent", "Location" };
		local	CheckButtonList = { "SendMessage", "SentMessage", "PositiveReply" };
		local	p, parentobj, prefix, ListSize, y, i, btnobj, template;
		for p = 1, 2 do
			if (p == 1) then
				parentobj = getglobal("KarmaWindow2_List1_Frame");
				prefix = "List1_";
				ListSize = KARMA_LFGWND_LIST1_SIZE;
				y = 0;
			else
				parentobj = getglobal("KarmaWindow2_List2_Frame");
				prefix = "List2_";
				ListSize = KARMA_LFGWND_LIST2_SIZE;
				y = -4;
			end
			for i = 2, ListSize do
				for key, value in pairs(ButtonList) do
					-- FrameType, Name, parentFrame, inheritFrame
					template = "List_" .. value .. "Template";
					if (value == "Name") then
						template = prefix .. value .. "Template";
					end
					btnobj = CreateFrame("Button", prefix .. value .. tostring(i), parentobj, template);
					btnobj:SetID(i);
					btnobj:SetPoint("TOPLEFT", prefix .. value .. tostring(i - 1), "BOTTOMLEFT", 0, y);
				end

				if (p == 2) then
					for key, value in pairs(CheckButtonList) do
						-- FrameType, Name, parentFrame, inheritFrame
						template = "List_" .. value .. "Template";
						btnobj = CreateFrame("CheckButton", prefix .. value .. tostring(i), parentobj, template);
						btnobj:SetID(i);
						btnobj:SetPoint("LEFT", prefix .. value .. tostring(i - 1), "LEFT");
						btnobj:SetPoint("TOP", prefix .. "Name" .. tostring(i), "TOP", 0, 4);
						if (value == "SentMessage") then
							btnobj:Disable();
						end
					end
				end
			end
		end

		btnobj = getglobal("List2_SentMessage1");
		if (btnobj) then
			btnobj:Disable();
		end
	end
end

