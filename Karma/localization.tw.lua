﻿if (GetLocale() == "zhTW") then
KARMA_INITIAL_MESSAGE = " loaded... 使用 /karma 尋求幫助!";
KARMA_MYADDONS_HELP = {
	"Usage: /karma\n將開啟主要視窗. 你也可以設定一個熱鍵.",
};

-- Default language is English. Others can override as provided.

-- Container to all this... to reduce size of global namespace :D
--KARMA*AVENK_LANG = {};


-- never know if someone wants to translate *that*
KARMA_WINEL_FRAG_COLON = ":";				-- asian languages!
KARMA_WINEL_FRAG_COLONSPACE = ": ";			-- asian languages!
KARMA_WINEL_FRAG_SPACE = " ";				-- asian languages!
KARMA_WINEL_FRAG_NEWLINE = "\n";			-- asian languages!
KARMA_WINEL_FRAG_PLUS = "+";				-- asian languages!
KARMA_WINEL_FRAG_BRACKET_LEFT = "(";			-- asian languages!
KARMA_WINEL_FRAG_BRACKET_RIGHT = ")";			-- asian languages!
KARMA_WINEL_FRAG_TRIDOTS = "...";			-- asian languages!

KARMA_ITSELF = "Karma";
KARMA_ITSELF_COLONSPACE = KARMA_ITSELF .. KARMA_WINEL_FRAG_COLONSPACE;
KARMA_CMDSELF = "/karma";

KARMA_TITLE = KARMA_ITSELF;
KARMA_INITIAL_MESSAGE = " loaded... Use " .. KARMA_CMDSELF .. " for help!";
KARMA_MYADDONS_HELP = {
	"Usage: '" .. KARMA_CMDSELF .. "'\nThis will open the main window. You can also bind a key to this."
};

KARMA_CMDLINE_CMDUNKNOWN_PRE = "Command >";
KARMA_CMDLINE_CMDUNKNOWN_POST = "< was not found.";

KARMA_CMDLINE_HELP_COLOR1 = "cFF7F8FAF";
KARMA_CMDLINE_HELP_COLOR2 = "cFF8FAFFF";

KARMA_CMDLINE_HELP_SHORT = {
	KARMA_ITSELF .. " *** Help Info|r",
	"Usage: '" .. KARMA_CMDSELF .. " <command> [<argument>] ...'|" ..KARMA_CMDLINE_HELP_COLOR2 .. "(/kar is an alias for /karma). E.g.: '/karma window'|r",
	"Common commands:|r",
	"   help [all|quick|alts|lfm|options|db|exchange] |" ..KARMA_CMDLINE_HELP_COLOR2 .. "('all' yields a pretty complete help, 'quick' only *lists* all commands, the others are command groups less used (because they can be reached via 'regular' UI elements or they need not be issued that often))|r",
	"   resetgui |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(reset the position of the minimap icon, main window and LFM window)|r",
	"   window (or win) |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(open " .. KARMA_ITSELF .. "'s main window)|r",
	"   options (or opt) |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(open options window)|r",
	"   showonline |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(open " .. KARMA_ITSELF .. "'s LFM window)|r",
	"   addmember <name> (or add) |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(adds <name>)|r",
	"   ignore <name> (or ign) |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(adds and ignores <name> by setting their " .. KARMA_ITSELF .. " to 1)|r",
	"   update <name> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(tries to update <name> or target if no name given)|r",
	"   remove <name> (or rem) |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(removes <name>)|r",
	"   give <name> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(give " .. KARMA_ITSELF .. " to <name>)|r",
	"   take <name> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(take " .. KARMA_ITSELF .. " from <name>)|r",
};

KARMA_CMDLINE_HELP_LFM = {
	"Commands regarding the LFM window:|r",
	"   checkchannel <channel> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(tries to compare players in <channel> versus " .. KARMA_ITSELF .. "'s list)|r",
	"   checkclass <class> <level> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(tries to compare online players of class <class> versus " .. KARMA_ITSELF .. "'s list; level may be omitted)|r",
	"   checkallclasses <level> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(tries to compare online players for all classes versus " .. KARMA_ITSELF .. "'s list; level may be omitted)|r",
	"   checkguild <guildname> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(tries to compare online players of the given guildname (may be just a fragment) versus " .. KARMA_ITSELF .. "'s list)|r",
	};

KARMA_CMDLINE_HELP_OPTIONS = {
	"Commands which have a counterpart in the Options window:|r",
	"   sortby <[name||played||exp||time]> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(sort lists by <...>)|r",
	"   colorby <[played||exp||time]> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(color lists by <...>)|r",
	"   karmatips |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(toggles " .. KARMA_ITSELF .. " rating in tooltip)|r",
	"   notetips |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(toggles " .. KARMA_ITSELF .. "s note in tooltip)|r",
	"   qcachewarn |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(toggles the warning about your questlog being only partially visible)|r",
	"   autoignore <[on||off]> |r",
	"   autochecktalents |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(toggles automatic fetching of talents in groups)|r",
	};

KARMA_CMDLINE_HELP_ALTS = {
	"Commands regarding alternate characters:|r",
	"   altadd <character1> <character2> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(<character1> and <character2> are marked to be the same person)|r",
	"   altrem <character> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(<character> is unlinked from other characters of the person)|r",
	"   altlist <character> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(lists all the alts of <character>)|r",
	};

KARMA_CMDLINE_HELP_DB = {
	"Commands regarding internal databases:|r",
	"   clean |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(removes entries matching various criteria)|r",
	"   cleanpvp |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(removes cross-server entries from BGs)|r",
	"   veryclean |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(similar to clean, but removes ALL cross-server entries)|r",
	"   questcache <[-1||0||a quest id]> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(shows " .. KARMA_ITSELF .. "'s view on the questlog)|r",
	"   skillmodel <[complex||simple]> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(switches between simple (= default) and complex skill model)|r",
	};

KARMA_CMDLINE_HELP_EXCHANGE = {
	"Commands regarding database exchange with a trusted other player:|r",
	"   |cFFFF4010You should NOT allow this unless you are basically idling somewhere, as this bears the danger of disconnecting you or the other player!|r",
	"   |" .. KARMA_CMDLINE_HELP_COLOR2 .. "You MUST enable the helper addon KarmaTrans to receive (and store) any data.|r",
	"   exchangeallow [<name>] |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(allows player 'name' to pull interesting parts of " .. KARMA_ITSELF .. "'s database of yours: the information that can be gathered via /who; and GUID, " .. KARMA_ITSELF .. " ratings and public notes)|r",
	"   exchangerequest <name> [<start>] |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(asks player 'name' to initiate data transfer, optionally starting with entry <start>; the other player must allow this BEFOREHAND with 'exchangeallow'!)|r",
	"   exchangetrust <name> <trust value> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(sets a 'trust' factor (0.01 .. 1.0) for player 'name', defines how strongly you trust the judgement of that player regarding the " .. KARMA_ITSELF .. " value)|r",
	"   exchangeupdate |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(this actually updates your database with all the imported information available)|r",
	"   |" .. KARMA_CMDLINE_HELP_COLOR2 .. "Complete procedure for one exchange of A -> B: A exchangeallow B, B exchangerequest A, (wait patiently), B exchangetrust A <trust>, B exchangeupdate|r",
	"Commands that require manual handling *outside* of WoW to be of any use:|r",
	"   export <[*||<name>]> |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(exports <name> or all datasets of the current server/faction)|r",
	"   import |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(imports available datasets)|r",
	"   transport |" ..KARMA_CMDLINE_HELP_COLOR2 .. "(clears the export&import datasets)|r"
};

-- NOT "SHORT"
KARMA_CMDLINE_HELPMETA_LONG = {
	"ALTS"
};

-- NOT "SHORT"
KARMA_CMDLINE_HELPMETA_FULL = {
	"ALTS", "LFM", "OPTIONS", "DB", "EXCHANGE"
};

-- legacy support for translations
KARMA_CMDLINE_HELPMETA_LEGACY = {
	"LONG"
};


KARMA_UNKNOWN =	"Unknown";
KARMA_UNKNOWN_ENT =	"Unknown Entity";

KARMA_DATEFORMAT = "%m/%d/%Y";

KARMA_WINEL_TITLE = KARMA_ITSELF;

KARMA_WINEL_OK = "確定";
KARMA_WINEL_APPLY = "套用";
KARMA_WINEL_CANCEL = "取消";

KARMA_WINEL_FILTER = "過濾";

KARMA_CHATMSG_VARIOUS_REGIONS = "Various Regions";

KARMA_WINEL_INCREASE = KARMA_WINEL_TITLE .. "++";
KARMA_WINEL_DECREASE = KARMA_WINEL_TITLE .. "--";

KARMA_WINEL_NOTESPUBLIC = "'Public' notes";
KARMA_WINEL_NOTESPUBLICFRAMETITLE = KARMA_WINEL_NOTESPUBLIC .. KARMA_WINEL_FRAG_COLONSPACE .. "(max. 40 characters!)";
KARMA_WINEL_NOTESPUBLICQUERYGUILD = "Query...";
KARMA_WINEL_NOTESPUBLICRESULTS = "<!>";
KARMA_WINEL_NOTESSCROLLFRAMETITLE = "備註:";
KARMA_WINEL_PARTYLISTTITLE = "現在隊伍成員";
KARMA_WINEL_MEMBERLISTTITLE = "組隊記錄";
KARMA_WINEL_CHOSENPLAYERTITLE = "名稱:";
KARMA_WINEL_CHOSENPLAYERXPTITLE = "Experience:";
KARMA_WINEL_CHOSENPLAYERXPACCRUEDTITLE = "Accrued:";
KARMA_WINEL_CHOSENPLAYERXPPERCENTAGETITLE = "Percentage:";
KARMA_WINEL_CHOSENPLAYERTIMETITLE = "Time Played:";
KARMA_WINEL_CHOSENPLAYERTIMEACCRUEDTITLE = "Accrued:";
KARMA_WINEL_CHOSENPLAYERTIMEPERCENTAGETITLE = "Percentage:";
KARMA_WINEL_KARMAINDICATORTITLE = KARMA_ITSELF .. " Rating:";
KARMA_WINEL_KARMAREGIONLIST = "副本記錄:";
KARMA_WINEL_KARMAZONELIST = "冒險區域:";
KARMA_WINEL_KARMAQUESTLIST = "任務合作";
KARMA_WINEL_KARMAACHIEVEMENTLIST = "Achieved together:";
KARMA_WINEL_MAINALTLIST = "Alts:";

KARMA_WINEL_TALENTSBUTTON = "天賦(1)";
KARMA_WINEL_TALENTS2BUTTON = "天賦(2)";
KARMA_WINEL_TALENTWND_TALENT_TITLE = "Talent";
KARMA_WINEL_FILTERBUTTON = KARMA_WINEL_FILTER .. KARMA_WINEL_FRAG_COLONSPACE;
KARMA_WINEL_OPTIONSBUTTON = "設定";
KARMA_WINEL_INVITEBUTTON = "邀請";
KARMA_WINEL_UPDATEBUTTON = "更新";
KARMA_WINEL_NEWFORCEBUTTON = "Forcenew (conflict)";
KARMA_WINEL_UPDATEFORCEBUTTON = "Forceupdate (conflict)";
KARMA_WINEL_REMOVEBUTTON = "移除";
KARMA_WINEL_CLOSEBUTTON = "關閉";
KARMA_WINEL_POSTTOCHATBUTTON = "發佈至頻道";

KARMA_WINEL_REMOVE_QUESTION_TEXT_PRE = "你確定要將『";
KARMA_WINEL_REMOVE_QUESTION_TEXT_POST = "』從名單移除？";
KARMA_WINEL_REMOVE_QUESTION_BTN_EXECUTE = "移除";
KARMA_WINEL_REMOVE_QUESTION_BTN_CANCEL = "取消";

--
KARMA_WINEL_FILTER_TITLE = KARMA_WINEL_FILTER .. " criteria:";
KARMA_WINEL_FILTER_NAME = "名稱 ";
KARMA_WINEL_FILTER_NAMESTARTS = "Name starts with:";
KARMA_WINEL_FILTER_NAMECONTAINS = "and contains:";
KARMA_WINEL_FILTER_CLASS = "職業 ";
KARMA_WINEL_FILTER_LEVELFROM = "等級 從 ";
KARMA_WINEL_FILTER_LEVELTO = " 到 ";
KARMA_WINEL_FILTER_KARMAFROM = KARMA_ITSELF .. " 分數從 ";
KARMA_WINEL_FILTER_KARMATO = " 到 ";
KARMA_WINEL_FILTER_JOINEDAFTER = "Joined after ";
KARMA_WINEL_FILTER_JOINEDBEFORE = " and before ";
KARMA_WINEL_FILTER_JOINED_TITLE = "Joined after/before";
KARMA_WINEL_FILTER_NOTE = "Note contains: ";
KARMA_WINEL_FILTER_NOTEPRIVATE = "Private note contains: ";
KARMA_WINEL_FILTER_NOTEPUBLIC = "Public note contains: ";

--
KARMA_WINEL_PLAYER_TITLE = "玩家: ";
KARMA_WINEL_HPS = "HPS (治療)";
KARMA_WINEL_DPS = "DPS (傷害)";
KARMA_WINEL_TANK = "TANK (坦職)";
KARMA_WINEL_MELEE = "進戰";
KARMA_WINEL_RANGED = "遠程";

--
KARMA_WINEL_CATEGORYAREATITLE = "設定:";
KARMA_WINEL_OPTCAT1 = "排列與顏色";
KARMA_WINEL_OPTCAT2 = "提示資訊";
KARMA_WINEL_OPTCAT3 = "自動警告/忽略";
KARMA_WINEL_OPTCAT4 = "系統訊息";
KARMA_WINEL_OPTCAT5 = "'Virtual' " .. KARMA_ITSELF;
KARMA_WINEL_OPTCAT80 = "共享";
KARMA_WINEL_OPTCAT90 = "其他";
KARMA_WINEL_OPTCAT95 = "標準功能";
KARMA_WINEL_OPTCAT99 = "資料庫清除";

--
KARMA_WINEL_SORTINGAREATITLE = "名單的排列和顏色定義";
KARMA_WINEL_SORTBYDROPDOWNTITLE = "名單排列方式：";
KARMA_WINEL_COLORBYDROPDOWNTITLE = "顏色定義：";

KARMA_WINEL_DROPDOWNBYKARMA = "分數" ;
KARMA_WINEL_DROPDOWNBYXP = "Experience w/ current char";
KARMA_WINEL_DROPDOWNBYTIME = "遊戲歷時 w/ current char";
KARMA_WINEL_DROPDOWNBYXPALL = "Experience w/ all chars";
KARMA_WINEL_DROPDOWNBYTIMEALL = "Time w/ all chars";
KARMA_WINEL_DROPDOWNBYNAME = "玩家名稱";
KARMA_WINEL_DROPDOWNBYCLASS = "職業";
KARMA_WINEL_DROPDOWNBYJOINED = "組隊時間";
KARMA_WINEL_DROPDOWNBYTALENT = "天賦";
KARMA_WINEL_DROPDOWNBYGUILDTOP = "公會 (無公會者排在前面)";
KARMA_WINEL_DROPDOWNBYGUILDBOTTOM = "公會 (無公會者排在後面)";

--
KARMA_WINEL_CHATWINDOWSAREATITLE = "系統訊息顯示於聊天視窗:";
KARMA_WINEL_CHATDEFAULTTITLE = "預設顯示於";
KARMA_WINEL_CHATSECONDARYTITLE = "另外顯示於";
KARMA_WINEL_CHATDEBUGTITLE = "除錯資訊:";
KARMA_WINEL_CHATDROPDOWNRESET = "Reset";

--
KARMA_WINEL_AUTOIGNOREAREATITLE = "Autoignore/AutoWarn Settings:";
KARMA_WINEL_AUTOIGNOREENABLEDCHECKBOXTITLE = "Enable Autoignore";
KARMA_WINEL_IGNOREINVITESCHECKBOXTITLE = "Autoignore Invites/Trades/Duels";
KARMA_WINEL_AUTOIGNORETHRESHOLD = KARMA_ITSELF .. " threshold for Autoignore";
KARMA_WINEL_WARNLOWKARMA_TITLE = "Warn of group members with low " .. KARMA_ITSELF;
KARMA_WINEL_WARNLOWKARMA_THRESHOLD = KARMA_ITSELF .. " threshold for Warning";

--
KARMA_WINEL_MARKUPAREATITLE = "Markup (colorisation of chat names):";
KARMA_WINEL_MARKUPENABLEDCHECKBOXTITLE = "Markup enabled";
KARMA_WINEL_MARKUPVERSIONCHECKBOXTITLE = "newer version";
KARMA_WINEL_MARKUPWHISPERSCHECKBOXTITLE = "Markup in whispers";
KARMA_WINEL_MARKUPCHANNELSCHECKBOXTITLE = "Markup in channels";
KARMA_WINEL_MARKUPYELLSAYEMOTECHECKBOXTITLE = "Markup yell/say/emote";
KARMA_WINEL_MARKUPGUILDCHECKBOXTITLE = "Markup guild chat";
KARMA_WINEL_MARKUPRAIDCHECKBOXTITLE = "Markup raid chat";
KARMA_WINEL_MARKUPBGCHECKBOXTITLE = "Markup battleground chat";

--
KARMA_WINEL_OPTIONSDBCLEANAREATITLE = "資料庫清除選項:";

KARMA_WINEL_AUTOCLEANCHECKBOXTITLE = "自動清除 (請注意使用)";
KARMA_WINEL_AUTOCLEANCHECKBOXTOOLTIP = {
		"自動清除",
		"每次登入時會將資料庫清理.",
		"啟用這個選項建議定期備份",
	};
KARMA_WINEL_AUTOCLEANCHECKBOXTOOLTIPEXTRA = "(你備份好WTF內的資料庫名單嗎?)";

KARMA_WINEL_AUTOCLEANPVPCHECKBOXTITLE = "離開戰場時自動清除所有PVP的名單";

KARMA_WINEL_DBCLEANSECTIONTITLE = "Criteria for keeping/removing entries:";

KARMA_WINEL_DBCLEANKEEPIFNOTETITLE = "Keep if note is not empty";
KARMA_WINEL_DBCLEANKEEPIFNOTETOOLTIP = {
		"Keep if note",
		"If this option is checked, entries with a note are not deleted.",
		"This option is also required, if you want to keep those cross-server",
		"entries with a note and remove those without!"
	};

KARMA_WINEL_DBCLEANREMOVEXSERVERTITLE = "Remove if cross-server (-> Name (*) <-)";
KARMA_WINEL_DBCLEANREMOVEXSERVERTOOLTIP = {
		"Remove if cross-server",
		"If this option is checked, cross-server entries without a note are deleted.",
		"If the following option is NOT set, all cross-server entries are deleted,",
		"even those with a note!"
	};

KARMA_WINEL_DBCLEANKEEPIFKARMATITLE = "Keep if " .. KARMA_ITSELF .. " is not 50";
KARMA_WINEL_DBCLEANKEEPIFKARMATOOLTIP = {
		"Keep if " .. KARMA_ITSELF .. " changed",
		"If this option is checked, entries with a " .. KARMA_ITSELF .. " value different from 50 are kept.",
		"(This check is performed after the checks for note & cross-server.)"
	};

KARMA_WINEL_DBCLEANKEEPIFQUESTNUMTITLE = "or more quests to keep";
KARMA_WINEL_DBCLEANKEEPIFQUESTNUMTOOLTIP = {
		"Keep if quested together",
		"Entries with at least this number of (partial or complete) quest cooperations are kept.",
		"(This check is performed after the checks for note & cross-server.)"
	};

KARMA_WINEL_DBCLEANKEEPIFREGIONNUMTITLE = "or more regions to keep";
KARMA_WINEL_DBCLEANKEEPIFREGIONNUMTOOLTIP = {
		"Keep if travelled regions together",
		"Entries with at least this number of jointly travelled regions are kept.",
		"If 'Ignore PVP regions/zones' is tagged, those are not counted.",
		"(This check is performed after the checks for note & cross-server.)"
	};

KARMA_WINEL_DBCLEANKEEPIFZONENUMTITLE = "or more zones to keep";
KARMA_WINEL_DBCLEANKEEPIFZONENUMTOOLTIP = {
		"Keep if travelled zones together",
		"Entries with at least this number of jointly travelled zones are kept.",
		"If 'Ignore PVP regions/zones' is tagged, those are not counted if known.",
		"(This check is performed after the checks for note & cross-server.)"
	};

KARMA_WINEL_DBCLEANIGNOREPVPZONESTITLE = "忽略PVP區域";
KARMA_WINEL_DBCLEANIGNOREPVPZONESTOOLTIP = {
		"忽略計算PVP的區域",
		"In counting regions/zones visited together, do not count PVP regions/zones.",
		"PVP regions are known to " .. KARMA_ITSELF .. ",",
		"but you have to travel PVP zones at least once,",
		"so they can be acknowledged and marked accordingly.",
		"(This check is performed after the checks for note & cross-server.)"
	};

KARMA_WINEL_DBCLEAN_TESTBUTTON = "嘗試清除";

--

KARMA_WINEL_OPTIONSTOOLTIPAREATITLE = "提示資訊";
KARMA_WINEL_TIPS_SHIFTREQ_CHECKBOXTITLE = "按住SHIFT鍵後點擊滑鼠左鍵才顯示Karma資訊";
KARMA_WINEL_KARMATIPSCHECKBOXTITLE = "顯示 評分";
KARMA_WINEL_PLAYEDTHISCHECKBOXTITLE = "顯示當前角色共同遊戲時間";
KARMA_WINEL_PLAYEDTOTALCHECKBOXTITLE = "顯示所有角色共同遊戲時間";
KARMA_WINEL_NOTETIPSCHECKBOXTITLE = "顯示 備註";
KARMA_WINEL_TIPS_SKILL_SCHECKBOXTITLE = "顯示 技術";
KARMA_WINEL_TIPS_TALENTS_SCHECKBOXTITLE = "顯示 天賦";
KARMA_WINEL_TIPS_ALTS_SCHECKBOXTITLE = "顯示候補關聯名單";
KARMA_WINEL_TT_HELP_BOXTITLE = "Show help tooltips to various UI elements";
KARMA_WINEL_TT_LFMADDKARMA_BOXTITLE = "Inject " .. KARMA_ITSELF .. "'s infos to players in LFM tooltip if available";

KARMA_WINEL_OPTIONSOTHERAREATITLE = "Other options:";
KARMA_WINEL_TARGETCOLOREDCHECKBOXTITLE = "Target background " .. KARMA_ITSELF .. "-colored";
KARMA_WINEL_QCACHWARNCHECKBOXTITLE = "Show warning for (partially) collapsed questlog";
KARMA_WINEL_MAINWNDTAB_DROPDOWNTITLE = "Main window:\ninitial tab on opening";
KARMA_WINEL_AUTOCHECKTALENTSCHECKBOXTITLE = "Automatically fetch talents for party members";
KARMA_WINEL_MINIMAPICONHIDE_TITLE = "隱藏小圖示";
KARMA_WINEL_QUESTSIGNOREDAILIES_TITLE = "不把每日任務列入資料庫紀錄";
KARMA_WINEL_UPDATEWHILEAFK_TITLE = "(Try to) update random members when AFK";
KARMA_WINEL_CONTEXTMENUDEACTIVATE_TITLE = "DON'T add entries for " .. KARMA_ITSELF .. " functions into context menus";
KARMA_WINEL_CONTEXTMENUDEACTIVATE_TOOLTIP = {
		KARMA_ITSELF .. " functions in right-click menus:",
		"If you are using 'Target' and/or 'Focus' of the context menus,",
		"depending on the current game patch version, it will bug out",
		"if an addon (like " .. KARMA_ITSELF .. ") added entries into the context menus",
		"(affects the chat on-name - menu and the unit frame - menu).",
		"If using those functions is important enough for you,",
		"this allows you to DEACTIVATE those entries.",
		"The issue is on Blizzard's end, and given the history of this",
		"feature, it has a 20% chance of getting a fix 'soon' (tm),",
		"and the probability of that yet-to-be-done fix working properly",
		"longer than one minor patch is somewhere around 40%.",
		"-- ",
		"Don't hold your breath... 'soon' is probably around christmas 2012. :-("
	};
KARMA_WINEL_DBSPARSETABLES_TITLE = "Sparse db mode: don't add all tables to new entries";
KARMA_WINEL_DBSPARSETABLES_TOOLTIP = {
		"Database sparse table mode:",
		KARMA_ITSELF .. " can either immediately add all tables that *might* be used",
		"or just add the core amount of tables to work when adding a new player.",
		"While you can save some memory with the core model, the user interface acts",
		"slightly different then and this might be unconvenient.",
		"--",
		"Advantage of adding all tables: on the tracked data you can select one char",
		"of yours and then click through the players list without having to re-select",
		"Disadvantage of adding all tables: used memory is usually a lot higher than",
		"really necessary",
		"--",
		"Advantage of sparse tables: quite some less memory consumption",
		"Disadvantage of sparse tables: the selection of your related char on the",
		"tracked data page kind of has a life on its own...",
		"--",
		"In these days of gigabytes of memory, it really isn't that problematic",
		"if " .. KARMA_ITSELF .. " takes some dozen megabytes. The relevant question is",
		"really the \"memory churn\" (i.e. how much memory it unnecessarily",
		"temporarily requests and disposes - which it does really very little).",
		"--",
		"Still, some (older) people are scared about the amount of memory " .. KARMA_ITSELF .. " uses,",
		"so here's a way to reduce it a bit. :-)",
		"--",
		"Enabling this option does not walk over the database to clean out the already",
		"existing but unused tables. To do that, you have to issue a command (which",
		"eats A LOT OF CPU TIME, DON'T PANIC, IT'S NOT CRASHED, JUST WORKING)",
		"on each server/faction you play on: '" .. KARMA_CMDSELF .. " dbsparse * [execute]'",
		"(Without execute it will list how much it *would* remove, but does not.",
		"If you actually crash, you can do it letter per letter instead of all in",
		"one swoop. Replace * with A*, B*, C* and so on.)"
	};

KARMA_WINEL_OPTIONSVIRTUALKARMAAREATITLE = "自動加分設定 (Beta)";
KARMA_WINEL_TIMEKARMA_ENABLE_TITLE = "根據總遊戲時數自動做加分";
KARMA_WINEL_TIMEKARMA_MINVAL_TITLE = KARMA_ITSELF .. "需要幾分以上才可列入: ";
KARMA_WINEL_TIMEKARMA_FACTOR_TITLE = KARMA_ITSELF .. "每小時自動加分: ";
KARMA_WINEL_TIMEKARMA_SKIPBGTIME_TITLE = "不將BG/WG的時間列入計算(之前紀錄無法改變)";

KARMA_WINEL_SHARINGAREATITLE = "Settings regarding sharing:";
KARMA_WINEL_SHARING_KARMALEVEL = "Share " .. KARMA_ITSELF .. " value:";
KARMA_WINEL_SHARING_PUBLICNOTELEVEL = "Share public note:";
KARMA_WINEL_SHARING_CHANNELNAME = "Channel to share server-wide:";
KARMA_WINEL_SHARING_CHANNELAUTOJOINHIDE = "自動加入頻道並隱藏訊息(在登入時)";

KARMA_SHARELEVELS = {};
KARMA_SHARELEVELS.L0 = "從不";
KARMA_SHARELEVELS.L1 = "總是";
KARMA_SHARELEVELS.L2 = "公會";
KARMA_SHARELEVELS.L3 = "限信任者 (n.y.i.)";

KARMA_WINEL_COREFEATURESAREATITLE = "Standard features of " .. KARMA_ITSELF .. KARMA_WINEL_FRAG_COLON;
KARMA_WINEL_TRACKINGDISABLEQUESTSTITLE = "DISABLE group tracking of quests";
KARMA_WINEL_TRACKINGDISABLEACHIEVEMENTSTITLE = "DISABLE group tracking of achievements";
KARMA_WINEL_TRACKINGDISABLEREGIONSTITLE = "DISABLE group tracking of regions (dungeons)";
KARMA_WINEL_TRACKINGDISABLEZONESTITLE = "DISABLE group tracking of zones";

--
--
----
--
--

KARMA_WINEL_MINIMENU_TOOLTIP1 = "點擊滑鼠左鍵開啟/關閉主視窗";
KARMA_WINEL_MINIMENU_TOOLTIP2 = "點擊滑鼠中鍵開啟/關閉" .. KARMA_ITSELF .. "LFM視窗";
KARMA_WINEL_MINIMENU_TOOLTIP3 = "點擊右鍵開啟快速目錄";

KARMA_WINEL_MINIMENU_KARMA = KARMA_ITSELF;
KARMA_WINEL_MINIMENU_TARGETIS = ": Target is ";
KARMA_WINEL_MINIMENU_TARGETNONE = ": No current target!";
KARMA_WINEL_MINIMENU_KARMACHANGE = "Change " .. KARMA_ITSELF .. " by ...";
KARMA_WINEL_MINIMENU_KARMAADDCHAR = "Add player to " .. KARMA_ITSELF .. "'s list";
KARMA_WINEL_MINIMENU_KARMADELCHAR = "Remove player from " .. KARMA_ITSELF .. "'s list";

KARMA_WINEL_MINIMENUSUB_INCREASE = "Increase " .. KARMA_ITSELF .. " by ...";
KARMA_WINEL_MINIMENUSUB_PLUS = " + ";
KARMA_WINEL_MINIMENUSUB_DECREASE = "Decrease " .. KARMA_ITSELF .. " by ...";
KARMA_WINEL_MINIMENUSUB_MINUS = " - ";

KARMA_WINEL_REASON_NONE = "no note";
KARMA_WINEL_REASON_SKILL = "skill";
KARMA_WINEL_REASON_MANNERS_UNCATEGORIZED = "manners"; 

KARMA_WINEL_REASON_NINJA = "ninja-looter";
KARMA_WINEL_REASON_KSER = "KSer";
KARMA_WINEL_REASON_BOT = "bot";
KARMA_WINEL_REASON_MANNERS_CONCEITED = "m:conceited";
KARMA_WINEL_REASON_MANNERS_RUDE = "m:rude";
KARMA_WINEL_REASON_MANNERS_SCAM = "m:scam";
KARMA_WINEL_REASON_MANNERS_DRAMAQUEEN = "m:drama queen";
KARMA_WINEL_REASON_SPAM_UNCATEGORIZED = "spam";
KARMA_WINEL_REASON_SPAM_ALLCAPS = "s:ALLCAPS";
KARMA_WINEL_REASON_SPAM_WRONG_CHANNEL = "s:channel abuse";
KARMA_WINEL_REASON_SPAM_SPEED = "s:speedy repetitions";

KARMA_WINEL_REASON_HELP_KILL = "helped kill";
KARMA_WINEL_REASON_HELP_INFO = "helped w/info";
KARMA_WINEL_REASON_HELP_ORGANIZE = "helped organize";
KARMA_WINEL_REASON_MANNERS_MODEST = "m:modest";
KARMA_WINEL_REASON_MANNERS_POLITE = "m:polite"; 
KARMA_WINEL_REASON_MANNERS_GENEROUS = "m:generous";
KARMA_WINEL_REASON_MANNERS_GRACIOUS = "m:gracious";

KARMA_BINDING_HEADER_TITLE = KARMA_ITSELF .. " Keybindings";
KARMA_BINDING_WINDOW_TITLE = "Toggle " .. KARMA_ITSELF .. " window";
KARMA_BINDING_WINDOW2_TITLE = "Toggle " .. KARMA_ITSELF .. "-PlayersOnline window";

-- spelling here is likely off...
KARMA_PVPZONE_WSG = "Warsong Gulch";
KARMA_PVPZONE_AB = "Arathi Basin";
KARMA_PVPZONE_AV = "Alterac Valley";
KARMA_PVPZONE_ES = "Eye Of The Storm";
KARMA_PVPZONE_SA = "Strand Of The Ancients";
KARMA_PVPZONE_WG = "Wintergrasp";

KARMA_WINEL_LISTMEMBERTIP_JOINED_ATALL_PRE = "近期與其組隊的角色 ( ";
KARMA_WINEL_LISTMEMBERTIP_JOINED_ATALL_POST = KARMA_WINEL_FRAG_BRACKET_RIGHT .. KARMA_WINEL_FRAG_COLONSPACE;
KARMA_WINEL_LISTMEMBERTIP_JOINED_CHAR = "最後組隊或交談的時間" .. KARMA_WINEL_FRAG_COLONSPACE;
KARMA_WINEL_LISTMEMBERTIP_UPDATE_OK = "更新於" .. KARMA_WINEL_FRAG_COLONSPACE;
KARMA_WINEL_LISTMEMBERTIP_UPDATE_FAIL = "Attempted to update" .. KARMA_WINEL_FRAG_COLONSPACE;
KARMA_WINEL_LISTMEMBERTIP_UPDATE_NEVER = "Never updated...";

KARMA_CHANNELNAME_LFG = "LookingForGroup";

--
--
--

KARMA_CLASS_DRUID_M = "德魯伊";
KARMA_CLASS_DRUID_F = "德魯伊";
KARMA_CLASS_HUNTER_M = "獵人";
KARMA_CLASS_HUNTER_F = "獵人";
KARMA_CLASS_MAGE_M = "法師";
KARMA_CLASS_MAGE_F = "法師";
KARMA_CLASS_PALADIN_M = "聖騎士";
KARMA_CLASS_PALADIN_F = "聖騎士";
KARMA_CLASS_PRIEST_M = "牧師";
KARMA_CLASS_PRIEST_F = "牧師";
KARMA_CLASS_ROGUE_M = "盜賊";
KARMA_CLASS_ROGUE_F = "盜賊";
KARMA_CLASS_SHAMAN_M = "薩滿";
KARMA_CLASS_SHAMAN_F = "薩滿";
KARMA_CLASS_WARRIOR_M = "戰士";
KARMA_CLASS_WARRIOR_F = "戰士";
KARMA_CLASS_WARLOCK_M = "術士";
KARMA_CLASS_WARLOCK_F = "術士";

KARMA_CLASS_DEATHKNIGHT_M = "死亡騎士";
KARMA_CLASS_DEATHKNIGHT_F = "死亡騎士";

KARMA_RACES_ALLIANCE_LOCALIZED =
	{
		KRA_DRAENEI	= "德萊尼",
		KRA_DWARF	= "矮人",
		KRA_GNOME	= "地精",
		KRA_HUMAN	= "人類",
		KRA_NIGHTELF	= "夜精靈"
	};

KARMA_RACES_HORDE_LOCALIZED =
	{
		KRH_BLOODELF	= "-血精靈",
		KRH_ORC		= "獸人",
		KRH_TAUREN	= "牛頭人",
		KRH_TROLL	= "食人妖",
		KRH_UNDEAD	= "不死族"
	};

KARMA_RACES_ALLIANCE_MALE =
	{
		DRAENEI		= "德萊尼",
		DWARF		= "矮人",
		GNOME		= "地精",
		HUMAN		= "人類",
		NIGHTELF	= "夜精靈"
	};

KARMA_RACES_HORDE_MALE =
	{
		BLOODELF	= "男血精靈",
		ORC		= "獸人",
		TAUREN		= "牛頭人",
		TROLL		= "食人妖",
		UNDEAD		= "不死族"
	};

KARMA_RACES_ALLIANCE_FEMALE =
	{
		DRAENEI		= "德萊尼",
		DWARF		= "矮人",
		GNOME		= "地精",
		HUMAN		= "人類",
		NIGHTELF	= "夜精靈"
		};

KARMA_RACES_HORDE_FEMALE =
	{
		BLOODELF	= "女血精靈",
		ORC		= "獸人",
		TAUREN		= "牛頭人",
		TROLL		= "食人妖",
		UNDEAD		= "不死族"
	};

KARMA_MISSING_INFO = "???";
KARMA_MISSING_INFO_SMALL = "?";

KARMA_TALENTS_LOCALIZED =
	{
		KARMA_TALENT_HPS = "HPS",
		KARMA_TALENT_TANK = "TANK",
		KARMA_TALENT_DPS = "DPS",
		KARMA_TALENT_FERAL = "FERAL",
		KARMA_TALENT_MELEE = "M",
		KARMA_TALENT_RANGED = "R"
	};

KARMA_ABILITIES_CC_LOCALIZED =
	{
		KARMA_TALENT_CC_CC0 = "C.",
		KARMA_TALENT_CC_CC1 = "C1",
		KARMA_TALENT_CC_CC2 = "C2",
	};

KARMA_TARGETS_CC_LOCALIZED =
	{
		KARMA_MONSTER_HUMAN = "Humanoid",
		KARMA_MONSTER_UNDEAD = "Undead",
		KARMA_MONSTER_ELEMENT = "Element",
		KARMA_MONSTER_BEAST = "Beast",
		KARMA_MONSTER_DRAKE = "Drake"
	};

KARMA_ABILITIES_AE_LOCALIZED =
	{
		KARMA_TALENT_AE_M1 = "AE1",
		KARMA_TALENT_AE_AE = "AEx"
	};

-- SKILL: 0..100
KARMA_SKILL_LEVELS_COMPLEX = 
	{
	-- able to find their way?
	-- able to understand a quest?
	-- able to follow an order?
	-- able to assist on a target?
	-- able to CC one target?
	-- able to CC one target and still assist on main?
	-- able to CC two targets?
		[0] = "eBayed?",
		[5] = "missing elementary game skills: read map/understand qlog",
		[10] = "missing basic game skill: follow the group",
		[15] = "missing basic group skill: follow an order/cooperative play",
		[20] = "able to follow elementary orders: follow, attack, stop",
		[25] = "can tank *one* target",
		[30] = "tolarable to useful in a regular instance",
		[35] = "able to attack the right target (i.e. assist)",
		[40] = "able to CC one target once",
		[45] = "can tank *two* targets",
		[50] = "able to CC one target repeatedly & continuously",
		[55] = "able to CC while staying on main target",
		[60] = "can tank *three* targets while keeping an eye on the healer",
		[65] = "able to automatically re-assist on change in CC",
		[70] = "tolarable to useful in a heroic instance",
		[75] = "able to CC dynamically (e.g. changing CC to mob on healer)",
		[80] = "able to CC *two* targets (i.e. kiting)",
		[85] = "can tank *four* targets",
		[100] = "a true hero"
	};

KARMA_SKILL_LEVELS_SIMPLE =
	{
		[0] = "爛咖，無可救藥",
		[20] = "馬虎，有待磨練",
		[40] = "普通，平淡無奇",
		[60] = "不錯，表現稱職",
		[80] = "老手，掌握精隨！",
		[100] = "達人，神乎其技！"
	};

-- GEAR: 0..100
KARMA_GEAR_PVE_LEVELS = 
	{
		[0] = "Green, low level",
		[5] = "Green/few Blue, low level",
		[10] = "Blue/Purple set, low level",
		[15] = "Green, equal level",
		[20] = "Green/few Blue, equal level",
		[25] = "Blue, equal level",
		[30] = "Blue set, equal level",
		[35] = "Blue/few Purple, equal level",
		[40] = "Purple, equal level",
		[45] = "Purple: PvE T4",
		[50] = "Purple: PvE T5",
		[55] = "Purple: PvE T6",
		[60] = "Purple: PvE above T6",
		[62] = "Purple: PvE T7",
		[64] = "Purple: PvE T8",
		[66] = "Purple: PvE T9",
		[68] = "Purple: PvE T10",
		[70] = "Purple: PvE above T10",

		[91] = "Purple: PvE always 2nd highest tier/10",
		[94] = "Purple: PvE always 2nd highest tier/25",
		[97] = "Purple: PvE always highest tier/10",
		[100] = "Purple: PvE always highest tier/25"
	};

-- GEAR: 0..100
KARMA_GEAR_PVP_LEVELS = 
	{
		[0] = "Green, low level",
		[5] = "Green/few Blue, low level",
		[10] = "Green, equal level",
		[15] = "Green/few Blue, equal level",
		[20] = "Blue, equal level",
		[25] = "Blue/few Purple, equal level",
		[30] = "Purple, equal level",
		[35] = "Purple: PvP S1",
		[40] = "Purple: PvP S2",
		[45] = "Purple: PvP S3",
		[50] = "Purple: PvP S4",
		[55] = "Purple: PvP above S4",

		[90] = "Purple: PvP always 2nd highest tier",
		[100] = "Purple: PvP always highest tier"
	};

KARMA_LEVEL_RESET = "清除重置";

KARMA_WINEL_TRACKINGDATA_BUTTON = "合作記錄";
KARMA_WINEL_OTHERDATA_BUTTON = "詳細評論";
KARMA_WINEL_OTHERDATA_TITLE = "能力簡評";
KARMA_WINEL_CHOSENPLAYERSKILLTITLE = "技術";
KARMA_WINEL_CHOSENPLAYERGEARPVETITLE = "PVE裝備";
KARMA_WINEL_CHOSENPLAYERGEARPVPTITLE = "PVP裝備";

KARMA_WINEL_LFM_TITLE = KARMA_ITSELF_COLONSPACE .. "召集令";
KARMA_WINEL_LIST1_TITLE = "Players online";
KARMA_WINEL_POPULATE_TITLE = "Populate list...";
KARMA_WINEL_LIST2_TITLE = "Players selected";

KARMA_WINEL_SENDMESS_TITLE = "再對他發出訊息";
KARMA_WINEL_SENTMESS_TITLE = "已發出訊息";
KARMA_WINEL_POSREPLY_TITLE = "獲得積極答覆";

KARMA_WINEL_MESSAGE_TO_SEND_TOOLTIP =	   "This is the message to be sent by the button [\"Send messages\"].\n"
					.. "%t in the text will be replaced with the actual receiver's name.\n"
					.. "(\"Hello %t!\" is sent to Joe as \"Hello Joe!\")\n"
					.. "If you selected an (offline) alt as candidate, additionally %a\n"
					.. "in the text will be replaced with the requested alt's name.\n"
					.. "(\"Hello %t, we need you as %a!\" is sent to Joe playing Jack as\n"
					.. " \"Hello Jack, we need you as Joe!\")";
KARMA_WINEL_SENDMESS_TOOLTIP =	   "If this box is checked,\n"
				.. "the message (at the bottom)\n"
				.. "is also sent to this player\n"
				.. "the next time you click\n"
				.. "[\"Send messages\"]";
KARMA_WINEL_SENTMESS_TOOLTIP = "This box gets *automatically* checked,\n"
							.. "after you sent the player a message here.";
KARMA_WINEL_POSREPLY_TOOLTIP = "If this box is checked,\n"
							.. "this player gets invited\n"
							.. "to your group when you click\n"
							.. "[\"Invite players\"]\n"
							.. "(Only possible if:\n"
							.. "you are the leader and\n"
							.. "the group isn't full yet).";

KARMA_WINEL_QUERYNOTESPUB_BTNTITLE = "Query public notes";

KARMA_WINEL_SEND_TITLE  = "Sends to all players\nchecked \"send\"";
KARMA_WINEL_SENDMESSAGE_BTNTITLE = "Send messages";

KARMA_WINEL_INVITE_TITLE  = "Invites players\nchecked \"pos. reply\"";
KARMA_WINEL_INVITE_BTNTITLE = "Invite players";

KARMA_WINEL_ALTADDBUTTON = "列為召集令候補人選，首選玩家是: ";
KARMA_WINEL_ALTREMBUTTON = "移除出候選人選內";

KARMA_WINEL_POSTTOMEMBER = "評論資料密語給朋友，受評論玩家: ";

KARMA_WINEL_POPULATE_CHANNEL_TITLE = "Check channel for players:";
KARMA_WINEL_POPULATE_CHANNELS_TITLE = "Check all channels for players";
KARMA_WINEL_POPULATE_LEVEL_TITLE = "Level range (class check) :";
KARMA_WINEL_POPULATE_CLASS_TITLE = "Check class for players:";
KARMA_WINEL_POPULATE_CLASSES_TITLE = "Check all classes for players\n!! THIS TAKES A LONG WHILE !!\n(about 2m30s permanent /who-ing)";
KARMA_WINEL_POPULATE_GUILD_TITLE = "Check guild:";

KARMA_WINEL_FILTERLIST1_TITLE = KARMA_WINEL_FILTER;
KARMA_WINEL_FILTERLIST1_KARMAMIN_TITLE = "最低 " .. KARMA_ITSELF .. KARMA_WINEL_FRAG_COLONSPACE;
KARMA_WINEL_FILTERLIST1_KARMAREQ_TITLE = "限定 " .. KARMA_ITSELF .. " 名單內玩家\n(限受過評分者)";
KARMA_WINEL_FILTERLIST1_SKILLMIN_TITLE = "最低技術要求: ";
KARMA_WINEL_FILTERLIST1_CLASSREQ_TITLE = "強制參考技術評論記錄\n(未評論者不列入篩選)";
KARMA_WINEL_FILTERLIST1_LEVELRANGE_TITLE = "等級限制: ";

KARMA_WINEL_LFMALTS = "+Alts";

--
--
--

KARMA_MSG_OOPS = "Oops. Internal error.";
KARMA_MSG_OOPS_IDENTITY = "Oops! Fatal identity crisis detected! Cannot sort names by xp/played. :-(";
KARMA_MSG_OOPS_NOTIMPLEMENTED = "Not yet implemented";

KARMA_MSG_CANNOT_PRE = "Cannot ";
KARMA_MSG_CANNOT_POST = "";
KARMA_MSG_UNKNOWN = " unknown.";

KARMA_MSG_SHORT_DAY = "d";
KARMA_MSG_SHORT_HOUR = "h";
KARMA_MSG_SHORT_MINUTE = "m";
KARMA_MSG_SHORT_SECOND = "s";

KARMA_MSG_ON = "on";
KARMA_MSG_OFF = "off";

KARMA_MSG_CONFIG_ISNOWON = " is now ON.";
KARMA_MSG_CONFIG_ISNOWOFF = " is now OFF.";

KARMA_MSG_COMMAND = "Command ";
KARMA_MSG_COMMAND_NEEDTARGETORARGUMENT = " used with no target nor commandline argument.";
KARMA_MSG_COMMAND_MISSINGARG = "Missing required argument";
KARMA_MSG_COMMAND_MISSINGARGS = "Missing required arguments";
KARMA_MSG_COMMAND_NOTMEMBER = "not on " .. KARMA_ITSELF .. "'s list.";

KARMA_MSG_COMMANDQUEUE_FULL1 = "Command queue must be empty for this. Current status";
KARMA_MSG_COMMANDQUEUE_FULL2 = " commands pending.";

KARMA_MSG_HELPINSECONDWINDOW = "See quick help in secondary window...";
KARMA_MSG_HELPCOMMANDLIST = "Complete command list:";

KARMA_MSG_PLAYER_REQARG = "<player>";
KARMA_MSG_REMOVE_COMPLETED = " was removed from the " .. KARMA_ITSELF .. "'s list of yours.";

KARMA_MSG_ADDMEMBER_ADDED = "已經增加到名單中";
KARMA_MSG_IGNOREMEMBER_ADDED = " was added to " .. KARMA_ITSELF .. "'s list, and ignored.";
KARMA_MSG_ADDORIGNMEMBER_OFFLINE = " was not found. They may not be currently logged on.";

KARMA_MSG_UPDATEMEMBER_UPDATED = " updated, location: ";
KARMA_MSG_UPDATEMEMBER_ONLINE = " online, location: ";
KARMA_MSG_UPDATEMEMBER_OFFLINE = " 不在線上，無法更新資料";

KARMA_MSG_CHECKING_FOR = "Checking for ";
KARMA_MSG_CHECKCHANNEL_ONE = "Checking against channel";
KARMA_MSG_CHECKCHANNEL_ALL = "Queueing checks for all channels you're in";
KARMA_MSG_CHECKCHANNEL_RESULTS = "Results from channel";
KARMA_MSG_CHECKCHANNEL_TOTAL1 = "CheckChannel";
KARMA_MSG_CHECKCHANNEL_TOTAL2 = " names parsed, ";
KARMA_MSG_CHECKCHANNEL_TOTAL3 = " recognized.";

KARMA_MSG_WHORESULT_1 = "Results for ";
KARMA_MSG_WHORESULT_2 = " are in: ";
KARMA_MSG_WHORESULT_3 = " players";
KARMA_MSG_WHORESULT_4 = " { )-: only partial results :-( }";

KARMA_MSG_WHOCATCHED_GOTNOTES = "Notes to ";
KARMA_MSG_WHOCATCHED_NONOTES = "No notes to ";

KARMA_MSG_CONFIG_AUTOIGNORE = "Autoignore";

KARMA_MSG_QCACHE_SECONDWINDOW = "Listing questcache in secondary window...";
KARMA_MSG_QCACHE_SUBLISTING = "Sublisting: ";
KARMA_MSG_QCACHE_COMPLETE = "complete = ";
KARMA_MSG_QCACHE_OBJECTIVESPECIAL = "(discovery/other special objective)";

KARMA_MSG_INSPECT_OVERRIDE1 = "Inspect request for ";
KARMA_MSG_INSPECT_OVERRIDE2 = " was overriden by other AddOn or UI action. Deferring until ";
KARMA_MSG_INSPECT_OVERRIDE3 = " is processed...";

KARMA_MSG_CONFIG_TIP_KARMA = KARMA_ITSELF .. " rating in tooltips";
KARMA_MSG_CONFIG_TIP_NOTES = KARMA_ITSELF .. "'s note in tooltip";

KARMA_MSG_FILTER_SET = "Set filter.";
KARMA_MSG_FILTER_CLEARED = "Cleared filter.";

-- empty comment for line sync
KARMA_MSG_UPDATE_RANDOM_EMPTYBUCKET1 = "No (random) member starting with";
KARMA_MSG_UPDATE_RANDOM_EMPTYBUCKET2 = "found to update.";

KARMA_MSG_CONFIG_QCACHEWARN = "Warning for collapsed questlog";

KARMA_MSG_CHECKCLASS_CLASS = "<class>";
KARMA_MSG_CHECKCLASS_UNK1 = "Failed to decode class";
KARMA_MSG_CHECKCLASS_UNK2 = ", will run over all races.";
KARMA_MSG_CHECKCLASS_QUEUEING_ONE = "Queueing checks for class ";
KARMA_MSG_CHECKCLASS_DONE1 = "Checks for class ";
KARMA_MSG_CHECKCLASS_DONE2 = " finished.";

KARMA_MSG_CHECKCLASS_QUEUEING_ALL = "Queueing checks for ALL classes. This will take a while...";
KARMA_MSG_CHECKCLASS_DONE_QUICK = "Fast checks for all classes finished. Slow checks are still pending...";
KARMA_MSG_CHECKCLASS_DONE_ALL = "Checks for all classes finished.";

KARMA_MSG_RESETGUI = "Main windows and minimap icon have now been reset and should be useable again.";

KARMA_MSG_CONFIG_AUTOTALENTS = "Automatic check for talents";

KARMA_MSG_CONFIG_SKILLMODEL_ISNOW = "Skill model is now";

KARMA_MSG_FIELDINIT_ERROR_VALUE = "Oops! Trying to initialize <unknown field> to ";
KARMA_MSG_FIELDINIT_ERROR_TABLE = "<table>";

KARMA_MSG_TIP_SKILL = "技術";
KARMA_MSG_TIP_TALENT = "天賦";
KARMA_MSG_TIP_ALTS = "Alts";

KARMA_MSG_QCACHE_WARNING = "WARNING! Quest cache is incomplete, questlog is partially collapsed, might lose some quest info...";

KARMA_MSG_DBCLEAN_EXTRAARG = "Won't clean DB: Found extra argument. Did you want to try '" .. KARMA_CMDSELF .. " clean dryrun'?";
KARMA_MSG_DBCLEAN_INGROUP = "Cannot clean DB: you're in a group.";
KARMA_MSG_DBCLEAN_PVPREGIONMARKED = "is now marked as a PvP region.";

KARMA_MSG_DBCLEAN_PRETEXT_NORMAL = "Cleaning entries from DB";
KARMA_MSG_DBCLEAN_RESULT_NORMAL1 = "Cleaned ";
KARMA_MSG_DBCLEAN_RESULT_NORMAL2 = " entries from DB, total count now";

KARMA_MSG_DBCLEAN_PRETEXT_DRYRUN = "Showing entry status of DB";
KARMA_MSG_DBCLEAN_RESULT_DRYRUN1 = "Would have cleaned ";
KARMA_MSG_DBCLEAN_RESULT_DRYRUN2 = " entries from DB, total count then";

KARMA_MSG_DBCLEAN_RESULT_3 = " entries.";

KARMA_MSG_REMOVE_ISINGROUP1 = "remove";
KARMA_MSG_REMOVE_ISINGROUP2 = ", member of current group!";

KARMA_MSG_TIP_LEVEL = "等級";

KARMA_MSG_AUTOIGNORE_GUILD = "Guild invite from ";
KARMA_MSG_AUTOIGNORE_PARTY = "Party invite from ";
KARMA_MSG_AUTOIGNORE_TRADE = "Trade request from ";
KARMA_MSG_AUTOIGNORE_DUEL = "Duel request from ";
KARMA_MSG_AUTOIGNORE_2 = KARMA_WINEL_FRAG_SPACE .. KARMA_ITSELF .. ") auto-declined. (Threshold ";
KARMA_MSG_AUTOIGNORE_3 = KARMA_WINEL_FRAG_SPACE .. KARMA_ITSELF .. ".)";

KARMA_MSG_MARKUP_WHISPER = " whispers:\32";
KARMA_MSG_MARKUP_CHANNEL = ":\32";

KARMA_MSG_CHATWND_ISNOW = " chat window is now";
KARMA_MSG_CHATWND_OVERTHERE = "over there -->";
KARMA_MSG_CHATWND_THISONE = " this one.";
KARMA_MSG_CHATWND_DEFAULTAGAIN = " back to... default!";
KARMA_MSG_CHATWND_UNSET = " unset.";

KARMA_MSG_CHATWND_DEFAULT = "Default";
KARMA_MSG_CHATWND_SECONDARY = "Secondary";
KARMA_MSG_CHATWND_DEBUG = "DEBUG";

KARMA_MSG_VERSION_NEW1 = "Newer version available: ";
KARMA_MSG_VERSION_NEW2 = " (since ";
KARMA_MSG_VERSION_NEW3 = ")";

KARMA_MSG_LFM_LIST1TIP_ALTS = "Alts";

KARMA_MSG_CHATSETUP_AUTO = "[autoassigned] ";
KARMA_MSG_CHATSETUP_1 = " (";
KARMA_MSG_CHATSETUP_2_DEFAULT = "default";
KARMA_MSG_CHATSETUP_2_EXTRA = "extra";
KARMA_MSG_CHATSETUP_2_DEBUG = "DEBUG";
KARMA_MSG_CHATSETUP_3 = " msgs -> ";
KARMA_MSG_CHATSETUP_4 = ")";
KARMA_MSG_CHATSETUP_DONE = "Found windows";

KARMA_MSG_ALT_REQARG = "<alt>";
KARMA_MSG_ALT_REQARGS = "<alt1> <alt2>";

KARMA_MSG_ALT_LIST_NOTMEMBER1 = "Can't list alts of >";
KARMA_MSG_ALT_LIST_NOTMEMBER2 = "<";
KARMA_MSG_ALT_LIST_NOALTS1 = "No alts known to >";
KARMA_MSG_ALT_LIST_NOALTS2 = "<.";
KARMA_MSG_ALT_LIST_PREFIX = "AltID ";
KARMA_MSG_ALT_LIST_OOPS_NOALTS1 = "Oops? AltID set, but no alts for >";
KARMA_MSG_ALT_LIST_OOPS_NOALTS2 = "<.";

KARMA_MSG_ALT_REM_NOTMEMBER1 = "Can't remove >";
KARMA_MSG_ALT_REM_NOTMEMBER2 = "< from any alt group";
KARMA_MSG_ALT_REM_NOALTID1 = "Not in any alt group: ";
KARMA_MSG_ALT_REM_NOALTID2 = ".";
KARMA_MSG_ALT_REM_DONE1 = "Removed >";
KARMA_MSG_ALT_REM_DONE2 = "< from their alt group.";
KARMA_MSG_ALT_REM_OOPS_NOALTS1 = "Oops? AltID set, but no alts for >";
KARMA_MSG_ALT_REM_OOPS_NOALTS2 = "<? Resetting altID";

KARMA_MSG_ALT_ADD_SAMEPLAYER = "Can't alt-link the same player unto themselves. Try *different* players...";
KARMA_MSG_ALT_ADD_NOTMEMBER = "Can't alt-link the two players: one or both are not known to " .. KARMA_ITSELF .. ".";
KARMA_MSG_ALT_ADD_ALREADYSAME = "The two players are already in the same alt group.";
KARMA_MSG_ALT_ADD_NOMERGE = "Merging two different alt groups is not implemented. Sorry.";
KARMA_MSG_ALT_ADD_DONE1 = " and ";
KARMA_MSG_ALT_ADD_DONE2 = " are now both in alt group #";

KARMA_MSG_CHECKGUILD_NOARG = "<guild>";

KARMA_MSG_PARTYJOINED_LOWKARMA1 = "WARNING";
KARMA_MSG_PARTYJOINED_LOWKARMA2 = " is - with just ";
KARMA_MSG_PARTYJOINED_LOWKARMA3 = " " .. KARMA_ITSELF .. " - below the minimum wanted value of ";
KARMA_MSG_PARTYJOINED_LOWKARMA4 = " " .. KARMA_ITSELF .. "!";

KARMA_MSG_TALENT_OTHERFRAMES = "Can't inspect talents: multiple frames being registered, the result is not definite.";

KARMA_UNITPOPUP_CHARADD = "增加到" .. KARMA_ITSELF .. "名單內";
KARMA_UNITPOPUP_CHARDEL = "移除出" .. KARMA_ITSELF .. "名單";

KARMA_UNITPOPUP_INCREASE = "加分 ";
KARMA_UNITPOPUP_DECREASE = "扣分 ";

KARMA_UNITPOPUP_SELECT = "選定";

KARMA_UNITPOPUP_PUBNOTE_CHECKGUILD = "Ask in guild for public notes";
KARMA_UNITPOPUP_PUBNOTE_CHECKCHANNEL = "Ask in channel for public notes";

KARMA_XFACTION_MENU_CHARADD = "Add player";
KARMA_XFACTION_MENU_CHARNOTE = "Add note (written into FILTER editbox) to player";
KARMA_XFACTION_MENU_CHARCHECK = "Check if player is known to " .. KARMA_ITSELF .. " on the 'other side'";

KARMA_MSG_NOTONKARMASLIST1 = "無法評論玩家－";
KARMA_MSG_NOTONKARMASLIST2 = " 該玩家尚未納入名單內，無法選定";

--
--
--

-- Tooltips: any UI element, via extra routines
KARMA_TOOLTIPS = {};

KARMA_TOOLTIPS["PUBLICNOTE"] =
	{
		"This note can be 'requested' by other players (with " .. KARMA_ITSELF .. ").",
		"",
		"Only 40 characters are stored!",
		"(Usually you can *enter* more, but this is due to internationalization errors",
		"that " .. KARMA_ITSELF .. " tries to compensate by itself.)",
		"You can modify, how 'public' this note and your " .. KARMA_ITSELF .. " rating of players is,",
		"with the command '" .. KARMA_CMDSELF .. " shareconfig'.",
		"Default: " .. KARMA_ITSELF .. " rating is not shared, 'public' note is only shared with guild members."
	};

KARMA_TOOLTIPS["FILTER"] =
	{
		"請輸入關鍵字，方便從名單內篩選角色",
		"Filters consist of a type, hypen and one or two values.",
		"Possible filters are:",
		"n-<fragment>: filters on name which must start with <fragment>",
		"    (<fragment> will likely start with a capital letter...)",
		"p-<fragment>: filters on name which must contain <fragment>",
		"    (<fragment> can be anywhere in the name)",
		"c-<class>: only show <class> (can usually be abbrev.)",
		"l-<levelfrom>-<levelto>: only show players in the level range",
		"    (you can omit one value)",
		"k-<karmafrom>-<karmato>: only show players whose " .. KARMA_ITSELF .. " value",
		"    is in the range (again you can omit one value)",
		"i-<fragment>: only show players whose note contains <fragment>",
		"    (<fragment can be anywhere in the note)",
		"A filter entry without a <type>- specifier will be treated as an n- filter.",
		"You can combine all 5 types of filters by separating them with spaces.",
		"",
		"Example: n-L p-ego c-Pr l--15 k-51-",
		"This would show all priests (c-Pr) of up to level 15 (l--15)",
		"    with better than neutral " .. KARMA_ITSELF .. " (k-51-, note the second hyphen) and",
		"    whose name starts with an L (n-L) and further contains an ego (p-ego)."
	};

KARMA_TOOLTIPS["JOINED"] =
	{
		"You can enter a date in various formats:",
		"- like a regular date, year being 4 digits",
		"- as \"nnn days ago\", where nnn is a number",
		"- as \"-nnn\", means the same as \"nnn days ago\""
	};

-- KARMA_ITSELF
-- KARMA_WINEL_FRAG_COLONSPACE
-- KARMA_WINEL_FRAG_TRIDOTS

-- Frame help: requires a KarmaWindow* top level frame
KARMA_FRAMES_HELP = {};

KARMA_FRAMES_HELP.Help_KW_MemberList_Frame =
	{
		"Help to: " .. KARMA_WINEL_MEMBERLISTTITLE,
		"This shows the list of players known to " .. KARMA_ITSELF .. ".",
		"~",
		"You can:",
		"- left-click to select the player as displayed player",
		"- shift-left-click to open the chatline with \"/whisper <player> \"",
		"- middle-click to send an update request for this player",
		"- right-click to open a menu for further options",
		"The menu with further options includes deletion and",
		"basic commands for alt management.",
		"~",
		"To alt-link two players:",
		"- left-click the first player to select",
		"  (the player now gets displayed on the right side)",
		"- right-click the second player",
		"- choose \"" .. KARMA_WINEL_ALTADDBUTTON .. "<first player>\""
	};

KARMA_FRAMES_HELP.Help_KW2_List1_Frame =
	{
		"Help to: " .. KARMA_WINEL_LIST1_TITLE,
		"This shows the list of players currently found online.",
		"~",
		KARMA_ITSELF .. " needs to 'find' the players first, so you'll want",
		"to start with the '" .. KARMA_WINEL_POPULATE_TITLE .. "' button.",
		"~",
		"Then validate your filter options, especially the level range.",
		"(The level range from the '" .. KARMA_WINEL_POPULATE_TITLE .. "' dialog does NOT carry over!)",
		"~",
		"If you've filled the list, clicking on a name selects it into the list",
		"to the right as potential candidate.",
		"~",
		"Players which were seen (by " .. KARMA_ITSELF .. ") in the " .. KARMA_CHANNELNAME_LFG .. " channel",
		"less than 5 mins ago are marked with a green timer, others are yellow."
	};

KARMA_FRAMES_HELP.Help_KW2_PopulateWindow_Frame =
	{
		"Help to: '" .. KARMA_WINEL_POPULATE_TITLE .. "' dialog",
		"This dialog helps you fill the list of the players online.",
		"~",
		"Options that are based on '/who' will not work if any other command",
		"in " .. KARMA_ITSELF .. " is still pending.",
		"~",
		"Most likely, you have joined the " .. KARMA_CHANNELNAME_LFG .. " channel.",
		"So, start there to look: Choose the channel via the selection box, then",
		"click on the first checkbox. Then click apply or ok. (Apply leaves the dialog",
		"open, so use it if you know that you want to search in multiple ways.)",
		"This will search in the channel. Those players " .. KARMA_ITSELF .. " knows are immediately",
		"filled with the available information, the other entries are grey",
		"in the left list of the LFG-window.",
		"~",
		"Continue with people you hang out in a channel with in a similar fashion.",
		"~",
		"Finally, you can choose the largest fill choice: Check all classes.",
		"That will take quite some time, but afterwards you have lots of names..."
	};

KARMA_DUNGEON_DIFFICULTY = {
		[1] = "normal",
		[2] = "heroic",
		[3] = "epic"
	};

-- error message for context menu taint
KARMA_TAINT_MENU = "You used a context menu to target/focus someone and it failed with 'Karma has been blocked ...' (a so-called taint error).\n\n"
		.. "Blizzard (mostly) breaks and (seldom) fixes the causing functions, as of 3.1.2 it is currently broken.\n"
		.. "Given the historic pattern of breaking/fixing, a fix isn't to be *expected* any sooner than christmas 2012.\n"
		.. "Until then, the only way to avoid this error is that Karma DOES NOT ADD ENTRIES into any context menus.\n\n"
		.. "If you prefer to use the 'Target'/'Focus' menu items, click 'DISABLE' to disable Karma adding entries.\n"
		.. "(This will also IMMEDIATELY reload the UI to take effect!)\n"
		.. "If you prefer two non-working menu items but added Karma entries, click 'CANCEL'.\n\n"
		.. "You can also change this setting in the options window at the 'Others' section.";

end