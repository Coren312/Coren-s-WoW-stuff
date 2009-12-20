----------------------------------------------
-- Global variables
----------------------------------------------

KarmaData = {};
-- Karma data is stored in the following tree:
--	KarmaData = {};
--		REALMS = {};
--			FACTIONLIST = {};
--				CHARACTERLIST = {};
--				MEMBERBUCKETS = {[A] = {} ... [Z] = {}};
--	(20400.x)	ALTGROUPS = {
--								[1] = { ID = 1, AL = { "Foo", "Baz", "Bar" } },
--								[2] = { ID = 2, AL = { "Tick", "Trick", "Track" } },
--								...
--							}
--				QUESTNAMES = {};
--		COMMON = {};
--			REGIONNAMES = {};
--			ZONENAMES = {};
--			FACTIONLIST = {};
--				<Faction> = {};
--					QUESTNAMES = {};
--					QUESTINFOS = {};

local	KarmaObj = KarmaAvEnK;
local	KOH = KarmaObj.Helpers;

-----------------------------------------
-- Low Level Functions
-----------------------------------------

function	Karma_NilToEmptyString(Input)
	if (Input ~= nil) then
		return Input;
	else
		return "";
	end
end

function	Karma_NilToString(value)
	if (value == nil) then
		return "<nil>";
	end
	return value;
end

function	Karma_NilToZero(Input)
	-- KarmaChatDefault("N20: " .. Karma_NilToEmptyString(Input));
	if (Input ~= nil) then
		return Input;
	else
		return 0;
	end
end

function	Karma_CopyTable(table)
	local	copyoftable = {};

	local	index, value;
	for index, value in pairs(table) do
		if (type(value) ~= "table") then
			copyoftable[index] = value;
		else
			copyoftable[index] = Karma_CopyTable(value);
		end
	end

	return copyoftable;
end

function	Karma_TableMerge2Into1(table1, table2)
	-- degenerated cases: no first table
	if (#table1 == 0) then
		return Karma_CopyTable(table2);
	end

	-- first table not empty, second is:
	if (#table2 == 0) then
		return Karma_CopyTable(table1);
	end

	local index, value;

	-- depending on size of the tables, walk one and insert into other
	-- special case: very short table2
	if (#table2 < 3) then
		-- get the three values
		local i = 1;
		local val1, val2, val3;
		for index, value in pairs(table2) do
			if (i == 1) then
				val1 = value;
			end
			if (i == 2) then
				val2 = value;
			end
			if (i == 3) then
				val3 = value;
			end
			i = i + 1;
		end
		-- check if already contained
		for index, value in pairs(table1) do
			if (value == val1) then
				val1 = nil;
			end
			if (value == val2) then
				val2 = nil;
			end
			if (value == val3) then
				val3 = nil;
			end
		end
		-- if not contained, insert
		if (val1 ~= nil) then
			table.insert(table1, val1);
		end
		if (val2 ~= nil) then
			table.insert(table1, val2);
		end
		if (val3 ~= nil) then
			table.insert(table1, val3);
		end

		return Karma_CopyTable(table1);
	end

	-- now to the ugly part...
	-- sure this would be helluva lot nicer, if we had them sorted... not today. :D
	local tablelarge, tablesmall;
	if (#table1 >= #table2) then
		tablelarge = table1;
		tablesmall = table2;
	else
		tablelarge = table2;
		tablesmall = table1;
	end

	-- walk the large table, and check for each value, if it's in the small, otherwise insert
	local table3 = {};
	for index, value in pairs(tablesmall) do
		local key = "K"..index;
		table3[key] = {};
		table3[key].ix = index;
		table3[key].val = value;
		table3[key].found = 0;
	end

	local index1, index2, value1, value2;
	for index1, value1 in pairs(tablelarge) do
		-- check if value1 also in tablesmall, if yes, remove
		for index2, value2 in pairs(tablesmall) do
			if (value1 == value2) then
				local key = "K"..index2;
				table3[key].found = 1;
				break;
			end
		end
	end

	-- now tablesmall should only contain values that are not in tablelarge
	-- just throw them in
	for index, value in pairs(table3) do
		if (value.found == 0) then
			table.insert(tablelarge, value.val);
		end
	end

	return Karma_CopyTable(tablelarge);
end

local	Stacks = {};

function	Karma_FieldInitialize(dict, field, initialvalue, bSilent, bCopy)
	KarmaObj.ProfileStart("Karma_FieldInitialize");

	if (dict == nil) or (field == nil) or (type(dict) ~= "table") then
		if (type(initialvalue) ~= "table") then
			KarmaChatDebugFallbackSecondary(KARMA_MSG_FIELDINIT_ERROR_VALUE .. initialvalue);
		else
			KarmaChatDebugFallbackSecondary(KARMA_MSG_FIELDINIT_ERROR_VALUE .. KARMA_MSG_FIELDINIT_ERROR_TABLE);
		end

		local backtrace = debugstack();
		KarmaChatDebugFallbackSecondary("CB: " .. backtrace);
	elseif (dict[field] == nil) then
		if (bCopy and (type(initialvalue) == "table")) then
			dict[field] = Karma_CopyTable(initialvalue);
		else
			dict[field] = initialvalue;
		end

		if (not bSilent) then
			if (type(initialvalue) ~= "table") then
				local valstr = initialvalue;
				if (valstr == true) then
					valstr = "true";
				elseif (valstr == false) then
					valstr = "false";
				elseif (valstr == nil) then
					valstr = "nil";
				end

				KarmaChatDebug("FI: " .. field .. " -> default: " .. valstr);
			else
				KarmaChatDebug("FI: " .. field .. " -> default: <table>");
			end
		end
	elseif ((initialvalue ~= nil) and (type(initialvalue) == "table") and KOH.TableIsEmpty(initialvalue)) then
		local backtrace = debugstack();
		local	iCount, bFound, i = #Stacks, false;
		for i = 1, iCount do
			if (Stacks[i] == backtrace) then
				bFound = true;
				break;
			end
		end
		if (not bFound) then
			tinsert(Stacks, backtrace);
			KarmaChatDebugFallbackSecondary("Empty table initializer (" .. tostring(iCount + 1) .. "): " .. backtrace);
		end
	end

	KarmaObj.ProfileStop("Karma_FieldInitialize");
end


----------------------------------------------
-- CONSTS
----------------------------------------------

local	KDBC = {};
KDBC.FactionObjectCache = nil;

local	KARMA_SUPPORTEDDATABASEVERSION = 10;

-- TOP LEVEL FIELDS
local	KARMA_DB_L1 = {
			VERSION = "VERSION",
			REALMLIST = "REALMS",
			COMMONLIST = "COMMON"
		};

-- COMMON LEVEL FIELDS: -> DB_L2_C
local	KARMA_DB_L2_C = {
			REGIONNAMES = "REGIONNAMES",
			ZONENAMES = "ZONENAMES",
			FACTION = "FACTIONLIST"
		};

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
			QUESTNAMES = "QUESTNAMES",
			ZONENAMES = "ZONENAMES",
			IGNORE24 = "IGNTMP",

			MEMBERLIST = "MEMBERLIST", -- No longer used after version 3 of the database
			MEMBERBUCKETS = "MEMBERBUCKETS",
			ALTGROUPS = "ALTGROUPS",
			XFACTIONHOLD = "XFACTIONHOLD",
		};

-- REALM/FACTION/<FACTION>/CHARACTERLIST OBJECT FIELDS: DB_L5_RRFFC
local	KARMA_DB_L5_RRFFC = {
			NAME = "NAME";
			XPTOTAL = "XPTOTAL";
			XPLAST = "XPLAST";
			XPMAX = "XPMAX";
			PLAYED = "PLAYED";
			PLAYEDLAST = "PLAYEDLAST";
			CONFIGPERCHAR = "CHARCONFIG";
			XPLVLSUM = "XPLVLSUM";
		};

-- REALM/FACTION/<FACTION>/IGNORE24 OBJECT FIELDS: DB_L5_RRFFI
local	KARMA_DB_L5_RRFFI = {
			GUID = "GUID",
			ACTIONS = "ACTIONS",
			IGNORE = "IGN",
			TIMEOUT = "TIMEOUT",
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
			ADDED_IN = "ADD_Z",

			RACE_EN = "RACEEN",
			CLASS_EN = "CLASSEN",
		};

-- #### --

local		KARMA_DB_L5_RRFFM_CONFLICT = "CONFLICT";

local		KARMA_DB_L5_RRFFM_TALENT = "TALENT";
local		KARMA_DB_L5_RRFFM_TALENTTREE = "TALENTTREE";
local		KARMA_DB_L5_RRFFM_KARMA = "KARMA";
local		KARMA_DB_L5_RRFFM_NOTES = "NOTES";
local		KARMA_DB_L5_RRFFM_PUBLIC_NOTES = "PUBLIC_NOTES";
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

--
--	Legacy broken version
--
local	function	Karma_AccentedToPlain(thechar)
	if (strlen(thechar) == 1) then
		KarmaChatDebug("FIXME: AccentedToPlain only got initial ~ " .. debugstack());
	end

	thechar = strsub(thechar, 1, 1);

	local	asccode = string.byte(thechar);
	-- if (asccode < 127) then
	-- A..Z => return same
	if (asccode >= string.byte("A")) and (asccode <= string.byte("Z")) then
		return thechar;
	end

	-- a..z => return A..Z - version
	if (asccode >= string.byte("a")) and (asccode <= string.byte("z")) then
		return string.upper(thechar);
	end

	-- replace via table - broken variant :D
	local index, value, i;
	for index, value in pairs(KARMA_ALPHACHARS_ACCENT) do
		for i = 1, getn(value) do
			if value[i] == asccode then
				return index;
			end
		end
	end

	-- now, this might be *anything*... better throw it into a bucket we know exists
	--return thechar;
	-- choose a bucket, that is probably rarely used, but *does* exist:
	return "Y";
end

--
--- teh new order
--

function	KarmaObj.DB.Create()
	if (GetCVar("realmName") == nil) or (UnitName("player") == nil) or (UnitFactionGroup("player") == nil) then
		return;
	end

	-- This creates fields in the database as we need them. Thus it is perfectly
	-- safe to call this function over and over again, as it only adds fields as they
	-- are required.
	-- At the end of this function, we will have an empty skeleton database setup.

--DEFAULT_CHAT_FRAME:AddMessage("DBC: 9/REALMs");
	--	ROOT
	Karma_FieldInitialize(KarmaData, KARMA_DB_L1.VERSION, KARMA_SUPPORTEDDATABASEVERSION);
	KOH.TableInit(KarmaData, KARMA_DB_L1.REALMLIST);

--DEFAULT_CHAT_FRAME:AddMessage("DBC: REALM/<current realm>/FACTION/<faction>");

	--	ROOT/REALMS
	local	sRealm = GetCVar("realmName");
	KOH.TableInit(KarmaData[KARMA_DB_L1.REALMLIST], sRealm);
	KOH.TableInit(KarmaData[KARMA_DB_L1.REALMLIST][sRealm], KARMA_DB_L3_RR_FACTION);

	--	ROOT/REALMS["realmName"]/FACTIONS
	local	factionlist = KarmaData[KARMA_DB_L1.REALMLIST][GetCVar("realmName")][KARMA_DB_L3_RR_FACTION];
	KOH.TableInit(factionlist, UnitFactionGroup("player"));

--DEFAULT_CHAT_FRAME:AddMessage("DBC: RRFF/Player");

	-- ROOT/REALMS["realmName"]/FACTIONS["factionname]/
	local	oFaction = factionlist[UnitFactionGroup("player")];
	KOH.TableInit(oFaction, KARMA_DB_L4_RRFF.CHARACTERLIST);
	KOH.TableInit(oFaction, KARMA_DB_L4_RRFF.QUESTNAMES);
	KOH.TableInit(oFaction, KARMA_DB_L4_RRFF.ZONENAMES);
	KOH.TableInit(oFaction, KARMA_DB_L4_RRFF.IGNORE24);
	KarmaObj.DB.I24.Clean(oFaction);

	--	ROOT/REALMS["realmName"]/FACTIONS["factionname]/CHARACTERLIST
	local	lCharacters = oFaction[KARMA_DB_L4_RRFF.CHARACTERLIST];
	KOH.TableInit(lCharacters, UnitName("player"));

	--	ROOT/REALMS["realmName"]/FACTIONS["factionname]/CHARACTERLIST["player"]
	lCharacters = lCharacters[UnitName("player")];
	Karma_FieldInitialize(lCharacters, KARMA_DB_L5_RRFFC.NAME, UnitName("player"));
	Karma_FieldInitialize(lCharacters, KARMA_DB_L5_RRFFC.XPTOTAL, 0);
	Karma_FieldInitialize(lCharacters, KARMA_DB_L5_RRFFC.XPLAST, UnitXP("player"));
	Karma_FieldInitialize(lCharacters, KARMA_DB_L5_RRFFC.XPMAX, UnitXPMax("player"));

	KOH.TableInit(lCharacters, KARMA_DB_L5_RRFFC.CONFIGPERCHAR);

	Karma_FieldInitialize(lCharacters, KARMA_DB_L5_RRFFC.XPLVLSUM, 0);

--DEFAULT_CHAT_FRAME:AddMessage("DBC: COMMONLIST");

	-- Questlists, Zonelists, and Subzonelists NEED NOT be per server!
--		COMMON = {};
--			FACTIONLIST = {};
--				<Faction> = {};
--					QUESTNAMES = {};
	--	ROOT/COMMON
	KOH.TableInit(KarmaData, KARMA_DB_L1.COMMONLIST);

	--	ROOT/COMMON/FACTIONLIST
	KOH.TableInit(KarmaData[KARMA_DB_L1.COMMONLIST], KARMA_DB_L2_C.FACTION);

	--	ROOT/COMMON/FACTIONLIST[<Faction>]
	local	CommonFactionList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION];
	KOH.TableInit(CommonFactionList, UnitFactionGroup("player"));

--DEFAULT_CHAT_FRAME:AddMessage("DBC: COMMON/FACTION/<current faction>/QUESTs");

	--	ROOT/COMMON/FACTIONLIST[<Faction>]/QUESTNAMES
	local	CommonFaction = CommonFactionList[UnitFactionGroup("player")];
	KOH.TableInit(CommonFaction, KARMA_DB_L3_CF_QUESTNAMES);
	KOH.TableInit(CommonFaction, KARMA_DB_L3_CF_QUESTINFOS);

--DEFAULT_CHAT_FRAME:AddMessage("DBC: COMMON/FACTION/<current faction>/REGIONS");

--		COMMON = {};
--			REGIONNAMES = {};
--			ZONENAMES = {};
	--	ROOT/COMMON/ZONENAMES
	KOH.TableInit(KarmaData[KARMA_DB_L1.COMMONLIST], KARMA_DB_L2_C.REGIONNAMES);
	local	CommonZoneList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.REGIONNAMES];
	for k, v in pairs(CommonZoneList) do
		if (type(v) ~= "table") then
			KOH.TableInit(CommonZoneList, k);
			KOH.TableInit(CommonZoneList[k], KARMA_DB_L3_CR.ZONEIDS);
		end
	end

--DEFAULT_CHAT_FRAME:AddMessage("DBC: COMMON/FACTION/<current faction>/ZONES");

	KOH.TableInit(KarmaData[KARMA_DB_L1.COMMONLIST], KARMA_DB_L2_C.ZONENAMES);

	CommonRegionZoneAddCurrent();

	-- Create Member Buckets

--DEFAULT_CHAT_FRAME:AddMessage("DBC: RRFF/Memberbuckets");

	KOH.TableInit(oFaction, KARMA_DB_L4_RRFF.MEMBERBUCKETS);

	local	buckets = {};
	local	result = {};
	local	i = 0;
	local	key, value;

	for i = 1, strlen(KARMA_ALPHACHARS) do
		local	sBucketName = strsub(KARMA_ALPHACHARS, i, i);
		KOH.TableInit(oFaction[KARMA_DB_L4_RRFF.MEMBERBUCKETS], sBucketName);
	end

--DEFAULT_CHAT_FRAME:AddMessage("DBC: RRFF/ALTs");

	-- Create AltGroups Container
	KOH.TableInit(oFaction, KARMA_DB_L4_RRFF.ALTGROUPS);
end

function	KarmaObj.DB.Upgrade()
--DEFAULT_CHAT_FRAME:AddMessage("DBU: " .. KarmaData[KARMA_DB_L1.VERSION] .. " -> " .. KARMA_SUPPORTEDDATABASEVERSION);
--	Loop until the database has been upgraded all the iterations of the formats between.
	if (KarmaData[KARMA_DB_L1.VERSION] == KARMA_SUPPORTEDDATABASEVERSION) then
--DEFAULT_CHAT_FRAME:AddMessage("DBU: done.");
		return;
	end

--DEFAULT_CHAT_FRAME:AddMessage("DBU: working...");

	local	realmlist, realmname, realmdata;
	local	factionlist, factionname, factiondata;
	local	ckey, cvalue, mkey, mvalue, key, value;
	local	cspecificobject;
	while (KarmaData[KARMA_DB_L1.VERSION] ~= KARMA_SUPPORTEDDATABASEVERSION) do
		--
		--	Upgrade from version 2 --> version 3
		--
		if (KarmaData[KARMA_DB_L1.VERSION] == 2) then
			realmlist = KarmaData[KARMA_DB_L1.REALMLIST];
			if (realmlist == nil) then
				return;
			end
			for realmname, realmdata in pairs(realmlist) do
				-- Update to the version 3 database.
				-- Changes are only mandatory field additions to the
				--	Characterlist entries
				--	Memberlist Entries
				factionlist = realmdata[KARMA_DB_L3_RR_FACTION];
				if (factionlist == nil) then
					return;
				end
				for factionname, factiondata in pairs(factionlist) do
					if (factionname ~= nil) then
						for ckey, cvalue in pairs(factiondata[KARMA_DB_L4_RRFF.CHARACTERLIST]) do
							if (cvalue~= nil) then
								cvalue[KARMA_DB_L5_RRFFC.PLAYED] = 0;
								cvalue[KARMA_DB_L5_RRFFC.PLAYEDLAST] = 0;
							end
						end
						for mkey, mvalue in pairs(factiondata[KARMA_DB_L4_RRFF.MEMBERLIST]) do
							if (mvalue~= nil) then
								KOH.TableInit(mvalue, KARMA_DB_L5_RRFFM_CHARACTERS);
								for key, value in pairs(mvalue[KARMA_DB_L5_RRFFM_CHARACTERS]) do
									if (value~= nil) then
										cspecificobject = value;
										cspecificobject[KARMA_DB_L6_RRFFMCC_PLAYED] = 0;
										cspecificobject[KARMA_DB_L6_RRFFMCC_PLAYEDLAST] = 0;
									end
								end
							end
						end
					end
				end
			end
			KarmaData[KARMA_DB_L1.VERSION] = 3;
		end
		---
		---	End upgrade version 2 --> version 3
		---

		if (KarmaData[KARMA_DB_L1.VERSION] == 3) then
			realmlist = KarmaData[KARMA_DB_L1.REALMLIST];
			if (realmlist == nil) then
				return;
			end

			local	buckets, results, i;
			local	sBucketName;
			for realmname, realmdata in pairs(realmlist) do
				-- put lMembers into buckets for quicker sorting, and accessing.
				factionlist = realmdata[KARMA_DB_L3_RR_FACTION];
				if (factionlist == nil) then
					return;
				end

				for factionname, factiondata in pairs(factionlist) do
					if (factionname ~= nil) then
						buckets = {};
						result = {};
						i = 0;

						for i = 1, strlen(KARMA_ALPHACHARS) do
							sBucketName = strsub(KARMA_ALPHACHARS, i, i);
							buckets[sBucketName] = {};
						end
						factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS] = buckets;

						for mkey, mvalue in pairs(factiondata[KARMA_DB_L4_RRFF.MEMBERLIST]) do
							if (mvalue~= nil) then
								sBucketName = Karma_AccentedToPlain(mkey);
								factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS][sBucketName][mkey] = mvalue;
							end
						end
					end
					factiondata[KARMA_DB_L4_RRFF.MEMBERLIST] = nil; -- no longer used get rid of the extra data
				end
			end
			KarmaData[KARMA_DB_L1.VERSION] = 4;
		end
		---
		---	End upgrade version 3 --> version 4;
		---


		if (KarmaData[KARMA_DB_L1.VERSION] == 4) then
			realmlist = KarmaData[KARMA_DB_L1.REALMLIST];
			if (realmlist == nil) then
				return;
			end
			for realmname, realmdata in pairs(realmlist) do
				-- put lMembers into buckets for quicker sorting, and accessing.
				factionlist = realmdata[KARMA_DB_L3_RR_FACTION];
				if (factionlist == nil) then
					return;
				end

				for factionname, factiondata in pairs(factionlist) do
					if (factionname ~= nil) then

						for bkey, bvalue in pairs(factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS]) do
							for mkey, mvalue in pairs(bvalue) do
								if (mvalue~= nil) then
									for ckey, cvalue in pairs(mvalue[KARMA_DB_L5_RRFFM_CHARACTERS]) do
										cvalue[KARMA_DB_L6_RRFFMCC_ZONEIDLIST] = {};
									end
								end
							end
						end
					end
				end
			end
			KarmaData[KARMA_DB_L1.VERSION] = 5;
		end
		---
		---	End upgrade version 4 --> version 5;
		---

		if (KarmaData[KARMA_DB_L1.VERSION] == 5) then
			realmlist = KarmaData[KARMA_DB_L1.REALMLIST];
			if (realmlist == nil) then
				return;
			end
			for realmname, realmdata in pairs(realmlist) do
				-- put lMembers into buckets for quicker sorting, and accessing.
				factionlist = realmdata[KARMA_DB_L3_RR_FACTION];
				if (factionlist == nil) then
					return;
				end

				for factionname, factiondata in pairs(factionlist) do
					if (factionname ~= nil) then
						for bkey, bvalue in pairs(factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS]) do
							for mkey, mvalue in pairs(bvalue) do
								if (mvalue~= nil) then
									for ckey, cvalue in pairs(factiondata[KARMA_DB_L4_RRFF.CHARACTERLIST]) do
										if (ckey~= nil and ckey~= "") then
											Karma_MemberList_Add(mkey, factiondata);
										end
									end
								end
							end
						end
					end
				end
			end
			KarmaData[KARMA_DB_L1.VERSION] = 6;
		end
		---
		---	End upgrade version 5 --> version 6;
		---

		if (KarmaData[KARMA_DB_L1.VERSION] == 6) then
			realmlist = KarmaData[KARMA_DB_L1.REALMLIST];
			if (realmlist == nil) then
				return;
			end
			for realmname, realmdata in pairs(realmlist) do
				-- put lMembers into buckets for quicker sorting, and accessing.
				factionlist = realmdata[KARMA_DB_L3_RR_FACTION];
				if (factionlist == nil) then
					return;
				end

				for factionname, factiondata in pairs(factionlist) do
					if (factionname ~= nil) then
						for bkey, bvalue in pairs(factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS]) do
							for mkey, mvalue in pairs(bvalue) do
								if (mvalue~= nil) then
									mvalue[KARMA_DB_L5_RRFFM.GENDER] = -1;
								end
							end
						end
					end
				end
			end
			KarmaData[KARMA_DB_L1.VERSION] = 7;
		end
		---
		---	End upgrade version 6 --> version 7;
		---

		if (KarmaData[KARMA_DB_L1.VERSION] == 7) then
			realmlist = KarmaData[KARMA_DB_L1.REALMLIST];
			if (realmlist == nil) then
				return;
			end

			local	qkey, qvalue, zkey, zvalue;
			for realmname, realmdata in pairs(realmlist) do
				factionlist = realmdata[KARMA_DB_L3_RR_FACTION];
				if (factionlist == nil) then
					return;
				end

				for factionname, factiondata in pairs(factionlist) do
					if (factionname ~= nil) then
						-- move zonelists and questlists to global
						local factionzonelist = factiondata[KARMA_DB_L4_RRFF.ZONENAMES];
						local zonetranslationlist = {};
						for zkey, zvalue in pairs(factionzonelist) do
							zonetranslationlist[zkey] = CommonRegionZoneAdd(nil, zvalue, nil, nil);
						end

						local factionquestlist = factiondata[KARMA_DB_L4_RRFF.QUESTNAMES];
						local questtranslationlist = {};
						for qkey, qvalue in pairs(factionquestlist) do
							questtranslationlist[qkey] = KarmaObj.DB.CF.QuestListAdd(qvalue, factionname);
						end

						for bkey, bvalue in pairs(factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS]) do
							for mkey, mvalue in pairs(bvalue) do
								if (mvalue~= nil) then
									local charspecificlist = mvalue[KARMA_DB_L5_RRFFM_CHARACTERS];
									for ckey, cvalue in pairs(charspecificlist) do
										local charzonelist = cvalue[KARMA_DB_L6_RRFFMCC_ZONEIDLIST];
										for zkey, zvalue in pairs(charzonelist) do
											if (zvalue > 0) then
												local tmpzvalue = zonetranslationlist[zvalue];
												local newzvalue;
												if (tmpzvalue == nil) then
													KarmaChatDebug(mkey.."::"..ckey..": ["..zkey.."] = "..zvalue.." => nil!");
													newzvalue = 0;
												else
													newzvalue = -tmpzvalue;
												end
												charzonelist[zkey] = newzvalue;
											end
										end

										local charquestlist = cvalue[KARMA_DB_L6_RRFFMCC_QUESTIDLIST];
										for qkey, qvalue in pairs(charquestlist) do
											if (qvalue > 0) then
												local tmpqvalue = questtranslationlist[qvalue];
												local newqvalue;
 												if (tmpqvalue == nil) then
 													KarmaChatDebug(mkey.."::"..ckey..": ["..qkey.."] = "..qvalue.." => nil!");
													newqvalue = 0;
												else
													newqvalue = -tmpqvalue;
 												end
												charquestlist[qkey] = newqvalue;
											end
										end
									end
								end
							end
						end
					end
				end
			end

			for realmname, realmdata in pairs(realmlist) do
				factionlist = realmdata[KARMA_DB_L3_RR_FACTION];
				if (factionlist == nil) then
					return;
				end

				for factionname, factiondata in pairs(factionlist) do
					if (factionname ~= nil) then
						-- remove local zonelists and questlists
						factiondata[KARMA_DB_L4_RRFF.QUESTNAMES] = nil;
						factiondata[KARMA_DB_L4_RRFF.ZONENAMES] = nil;
					end
				end
			end

			KarmaData[KARMA_DB_L1.VERSION] = 8;
		end
		---
		---	End upgrade version 7 --> version 8
		---

		if (KarmaData[KARMA_DB_L1.VERSION] == 8) then
			realmlist = KarmaData[KARMA_DB_L1.REALMLIST];
			if (realmlist == nil) then
				return;
			end

			for realmname, realmdata in pairs(realmlist) do
				factionlist = realmdata[KARMA_DB_L3_RR_FACTION];
				if (factionlist == nil) then
					return;
				end

				for factionname, factiondata in pairs(factionlist) do
					if (factionname ~= nil) then
						for bkey, bvalue in pairs(factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS]) do
							for mkey, mvalue in pairs(bvalue) do
								if (mvalue~= nil) then
									local charspecificlist = mvalue[KARMA_DB_L5_RRFFM_CHARACTERS];
									for ckey, cvalue in pairs(charspecificlist) do
										local charquestexlist = cvalue[KARMA_DB_L6_RRFFMCC_QUESTEXLIST];
										if (type(charquestexlist) == "table") then
											for qid, qexl in pairs(charquestexlist) do
												local qexlnew = {};
												for qkey, qvalue in pairs(qexl) do
													if (type(qkey) == "number") then
														qexlnew["O." .. qkey] = qvalue;
													else
														qexlnew[qkey] = qvalue;
													end
												end

												charquestexlist[qid] = qexlnew;
											end
										end
									end
								end
							end
						end
					end
				end
			end

			KarmaData[KARMA_DB_L1.VERSION] = 9;
		end

		if (KarmaData[KARMA_DB_L1.VERSION] == 9) then
			realmlist = KarmaData[KARMA_DB_L1.REALMLIST];
			if (realmlist == nil) then
				return;
			end

			for realmname, realmdata in pairs(realmlist) do
				factionlist = realmdata[KARMA_DB_L3_RR_FACTION];
				if (factionlist == nil) then
					return;
				end

				local sBucketOld, sBucketNew;
				for factionname, factiondata in pairs(factionlist) do
					if (factionname ~= nil) then
						for bkey, bvalue in pairs(factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS]) do
							for mkey, mvalue in pairs(bvalue) do
								if (mvalue~= nil) then
									sBucketOld = Karma_AccentedToPlain(mkey);
									sBucketNew = KarmaObj.NameToBucket(mkey);
									if (sBucketOld ~= sBucketNew) then
										factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS][sBucketNew][mkey] = mvalue;
										factiondata[KARMA_DB_L4_RRFF.MEMBERBUCKETS][sBucketOld][mkey] = nil;
										KarmaChatDebug("DBUpdate(9->10): Moved <" .. mkey .. "> from Bucket " .. sBucketOld .. " to " .. sBucketNew .. ".");
									end
								end
							end
						end
					end
				end
			end

			KarmaData[KARMA_DB_L1.VERSION] = 10;
		end
	end
end

--###############################################################################################
--###############################################################################################
--###############################################################################################

-----------------------------------------
-- Global Lists
-----------------------------------------

--###############################################################################################
--###############################################################################################
--###############################################################################################

-----------------------------------------
-- Common/Global
-----------------------------------------

function KarmaObj.DB.CG.RegionListGet()
	KarmaObj.ProfileStart("DB.CG.RegionListGet");
	local	CommonRegionList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.REGIONNAMES];
	KarmaObj.ProfileStop("DB.CG.RegionListGet");
	return CommonRegionList;
end

function KarmaObj.DB.CG.ZoneListGet()
	KarmaObj.ProfileStart("DB.CG.ZoneListGet");
	local	CommonZoneList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.ZONENAMES];
	KarmaObj.ProfileStop("DB.CG.ZoneListGet");
	return CommonZoneList;
end

--###############################################################################################
--###############################################################################################
--###############################################################################################

-----------------------------------------
-- Common/PerFaction (but not per server)
-----------------------------------------

-- CommonQuestListGet
function KarmaObj.DB.CF.QuestNameListGet()
	KarmaObj.ProfileStart("DB.CF.QuestNameListGet");
	local	FactionKey = UnitFactionGroup("player");
	local	CommonQuestList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey][KARMA_DB_L3_CF_QUESTNAMES];
	if (CommonQuestList == nil) then
		KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey][KARMA_DB_L3_CF_QUESTNAMES] = {};
		CommonQuestList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey][KARMA_DB_L3_CF_QUESTNAMES];
	end
	KarmaObj.ProfileStop("DB.CF.QuestNameListGet");
	return CommonQuestList;
end

-- CommonQuestInfoListGet
function KarmaObj.DB.CF.QuestInfosListGet()
	KarmaObj.ProfileStart("DB.CF.QuestInfosListGet");
	local	FactionKey = UnitFactionGroup("player");
	local	CommonQuestInfoList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey][KARMA_DB_L3_CF_QUESTINFOS];
	if (CommonQuestInfoList == nil) then
		KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey][KARMA_DB_L3_CF_QUESTINFOS] = {};
		CommonQuestInfoList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey][KARMA_DB_L3_CF_QUESTINFOS];
	end
	KarmaObj.ProfileStop("DB.CF.QuestInfosListGet");
	return CommonQuestInfoList;
end

-- CommonQuestAdd
function KarmaObj.DB.CF.QuestListAdd(Quest, Faction, ExtID)
	local Index, PerfectIndex;

	if (ExtID == nil) then
		KarmaChatDebug("DB.CF.QuestListAdd: ExtID == nil! " .. debugstack());
	end

	local FactionKey = Faction;
	if (FactionKey == nil) then
		FactionKey = UnitFactionGroup("player");
	end

	if (KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey] == nil) then
		-- happens at database conversion for the faction the current char is NOT on
		KOH.TableInit(KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION], FactionKey);
		KOH.TableInit(KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey], KARMA_DB_L3_CF_QUESTNAMES);
		KOH.TableInit(KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey], KARMA_DB_L3_CF_QUESTINFOS);
	end

	local	CommonQuestNamesList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey][KARMA_DB_L3_CF_QUESTNAMES];
	local	CommonQuestInfosList = KarmaData[KARMA_DB_L1.COMMONLIST][KARMA_DB_L2_C.FACTION][FactionKey][KARMA_DB_L3_CF_QUESTINFOS];
	if (CommonQuestNamesList) then
		local Count = 0;
		for k, v in pairs(CommonQuestNamesList) do
			Count = Count + 1;
			if (v == Quest) then
				if (ExtID) then
					local VExtID;
					if (CommonQuestInfosList[k]) then
						VExtID = CommonQuestInfosList[k].ExtID;
					end
					if (VExtID) then
						if (ExtID == VExtID) then
							PerfectIndex = k;
							Index = k;
						end
					else
						Index = k;
					end
				else
					Index = k;
				end
			end
		end

		-- if the perfect Index was before a non-perfect one, Index got overridden, restore from PerfectIndex
		if (PerfectIndex) then
			Index = PerfectIndex;
		end

		if (Index == nil) then
			Index = 1 + Count;
			CommonQuestNamesList[Index] = Quest;
		end

		if (ExtID) then
			if (CommonQuestInfosList[Index] == nil) then
				CommonQuestInfosList[Index] = {};
			end
			CommonQuestInfosList[Index].ExtID = ExtID;
		end
	end

	return Index;
end

--###############################################################################################
--###############################################################################################
--###############################################################################################

-----------------------------------------
-- Server/Faction Object
-----------------------------------------

function	KarmaObj.DB.FactionCacheInit()
	KDBC.FactionObjectCache = KarmaData[KARMA_DB_L1.REALMLIST][GetCVar("realmName")][KARMA_DB_L3_RR_FACTION][UnitFactionGroup("player")];
	if (KDBC.FactionObjectCache == nil) then
		DEFAULT_CHAT_FRAME:AddMessage(debugstack());
	end
end

-- Karma_Faction_GetFactionObject -> KarmaObj.DB.FactionCacheGet
function	KarmaObj.DB.FactionCacheGet(bNoInit)
	KarmaObj.ProfileStart("DB.FactionCacheGet");
	if (KDBC.FactionObjectCache == nil) and (not bNoInit) then
		KarmaObj.DB.FactionCacheInit();
		DEFAULT_CHAT_FRAME:AddMessage(debugstack());
	end
	KarmaObj.ProfileStop("DB.FactionCacheGet");
	return KDBC.FactionObjectCache;
end

-- cross-faction FactionObject (no caching)
function	KarmaObj.DB.FactionOtherGet()
	KarmaObj.ProfileStart("DB.FactionOtherGet");

	local	xFaction;
	if (UnitFactionGroup("player") == "Horde") then
		xFaction = "Alliance";
	else
		xFaction = "Horde";
	end

	KarmaObj.ProfileStop("DB.FactionOtherGet");
	if (xFaction) then
		return KarmaData[KARMA_DB_L1.REALMLIST][GetCVar("realmName")][KARMA_DB_L3_RR_FACTION][xFaction];
	else
		return nil;
	end
end

--
--- accessors
--

-- old per s/f logic
function	KarmaObj.DB.SF.QuestListGet()
	KarmaObj.ProfileStart("Karma_Faction_GetQuestList");
	local	oFaction = KarmaObj.DB.FactionCacheGet();
	local	lQuests = oFaction[KARMA_DB_L4_RRFF.QUESTNAMES];
	KarmaObj.ProfileStop("Karma_Faction_GetQuestList");
	return lQuests;
end

-- old per s/f logic
function	KarmaObj.DB.SF.ZoneListGet()
	KarmaObj.ProfileStart("Karma_Faction_GetZoneList");
	local	oFaction = KarmaObj.DB.FactionCacheGet();
	local	lZones = oFaction[KARMA_DB_L4_RRFF.ZONENAMES];
	KarmaObj.ProfileStop("Karma_Faction_GetZoneList");
	return lZones;
end

function	KarmaObj.DB.SF.CharacterListGet()
	local	oFaction = KarmaObj.DB.FactionCacheGet();
	local	lCharacters = oFaction[KARMA_DB_L4_RRFF.CHARACTERLIST];
	return lCharacters;
end

function	KarmaObj.DB.SF.MemberListGet()
	KarmaObj.ProfileStart("Karma_Faction_GetMemberList");
	local	oFaction = KarmaObj.DB.FactionCacheGet();
	local	lMembers = oFaction[KARMA_DB_L4_RRFF.MEMBERBUCKETS];
	KarmaObj.ProfileStop("Karma_Faction_GetMemberList");
	return lMembers;
end

--###############################################################################################

local	fSparseTestOrDelete = function(sName, oMember, bExecute)
	local	iCount = 0;
	if (oMember) then
		local	oMemPerChar = oMember[KARMA_DB_L5_RRFFM_CHARACTERS];
		if (type(oMemPerChar) == "table") then
			for sChar, oChar in pairs(oMemPerChar) do
				--[[
				-- minimal pointless data:
					["XP"] = 0,
					["XPLVL"] = 0,
					["XPLAST"] = 0,
					["XPMAX"] = 0,
					["PLAYED"] = 0,
					["PLAYEDLAST"] = <any value>,

					["ZONEIDLIST"] = {},
					["QUESTIDLIST"] = {},
					["QUESTEXLIST"] = {},
					["ACHIEVED"] = {},
					["REG_L"] = {},

				-- related field names
					KARMA_DB_L6_RRFFMCC_XP = "XP";
					KARMA_DB_L6_RRFFMCC_XPLAST = "XPLAST";
					KARMA_DB_L6_RRFFMCC_XPMAX = "XPMAX";
					KARMA_DB_L6_RRFFMCC_XPLVL = "XPLVL";

					KARMA_DB_L6_RRFFMCC_PLAYED = "PLAYED";
					KARMA_DB_L6_RRFFMCC_PLAYEDLAST = "PLAYEDLAST";

					KARMA_DB_L6_RRFFMCC_JOINEDLAST = "JOINEDLAST";

					KARMA_DB_L6_RRFFMCC_ZONEIDLIST = "ZONEIDLIST";
					KARMA_DB_L6_RRFFMCC_QUESTIDLIST = "QUESTIDLIST";
					KARMA_DB_L6_RRFFMCC_QUESTEXLIST = "QUESTEXLIST";
					KARMA_DB_L6_RRFFMCC_ACHIEVED = "ACHIEVED";
					KARMA_DB_L6_RRFFMCC_REGIONLIST = "REG_L";
				]]--

				local	iXP     = oChar[KARMA_DB_L6_RRFFMCC_XP];
				local	iPlayed = oChar[KARMA_DB_L6_RRFFMCC_PLAYED];
				local	iJoined = oChar[KARMA_DB_L6_RRFFMCC_JOINEDLAST];
				if (((iXP == nil) or (iXP == 0)) and ((iPlayed == nil) or (iPlayed == 0)) and ((iJoined == nil) or (iJoined == 0))) then
					local	sAnything = "";
					local	sKey, oData;
					for sKey, oData in pairs(oChar) do
						if ((sKey == KARMA_DB_L6_RRFFMCC_XP) or (sKey == KARMA_DB_L6_RRFFMCC_XPLAST) or
						    (sKey == KARMA_DB_L6_RRFFMCC_XPMAX) or (sKey == KARMA_DB_L6_RRFFMCC_XPLVL) or
						    (sKey == KARMA_DB_L6_RRFFMCC_PLAYED) or (sKey == KARMA_DB_L6_RRFFMCC_PLAYEDLAST)) then
							-- nothing to do: already pre-tested or not relevant
						elseif ((sKey == KARMA_DB_L6_RRFFMCC_ZONEIDLIST) or (sKey == KARMA_DB_L6_RRFFMCC_QUESTIDLIST) or
							(sKey == KARMA_DB_L6_RRFFMCC_QUESTEXLIST) or (sKey == KARMA_DB_L6_RRFFMCC_REGIONLIST) or
							(sKey == KARMA_DB_L6_RRFFMCC_ACHIEVED)) then
							if (not KOH.TableIsEmpty(oData)) then
								local	iCnt, sSub, oSub = 0;
								for sSub, oSub in pairs(oData) do
									iCnt = iCnt + 1;
								end
								sAnything = sAnything .. " " .. sKey .. "[" .. iCnt .. "]";
							end
						else	-- leaves JOINEDLAST
							sAnything = sAnything .. " " .. sKey;
						end
					end
					if (sAnything ~= "") then
						KarmaChatSecondary(sName .. "::" .. sChar .. " - " .. sAnything);
					else
						if (bExecute) then
							oMemPerChar[sChar] = nil;
							KarmaChatSecondary(sName .. "::" .. sChar .. " - DROPPED!");
						else
							KarmaChatSecondary(sName .. "::" .. sChar .. " - could drop!");
						end
						iCount = iCount + 1;
					end
				else
					local	sOutput = "";
					if (iXP and (iXP > 0)) then
						if (sOutput ~= "") then
							sOutput = sOutput .. " or";
						end
						sOutput = sOutput .. " xp > 0: " .. Karma_NilToString(iXP);
					end
					if (iPlayed and (iPlayed > 0)) then
						if (sOutput ~= "") then
							sOutput = sOutput .. " or";
						end
						sOutput = sOutput .. " played > 0: " .. Karma_NilToString(iPlayed);
					end
					if (iJoined and (iJoined > 0)) then
						if (sOutput ~= "") then
							sOutput = sOutput .. " or";
						end
						sOutput = sOutput .. " joined > 0: " .. Karma_NilToString(iJoined);
					end
					KarmaChatSecondary(sName .. "::" .. sChar .. " -" .. sOutput);
				end
			end
		end
	end

	return iCount;
end

-- operating on whole memberlist
function	KarmaObj.DB.SF.Sparsify(sPattern, bDrop)
	local	iDropped = 0;
	if (strsub(sPattern, strlen(sPattern)) == "*") then
		local	iLen = strlen(sPattern) - 1;
		local	sPat = strsub(sPattern, 1, iLen);

		local	lMembers = KarmaObj.DB.SF.MemberListGet(oFaction);
		local	sBucketName, oBucketValues;
		for sBucketName, BucketValue in pairs(lMembers) do -- Loop through each bucket
			local	sMemberName, oMember;
			for sMemberName, oMember in pairs(BucketValue) do -- Loop through contents of bucket
				if (strsub(sMemberName, 1, iLen) == sPat) then
					iDropped = iDropped + fSparseTestOrDelete(sMemberName, oMember, bDrop);
				end
			end
		end
	else
		local	oMember = Karma_MemberList_GetObject(sPattern);
		iDropped = fSparseTestOrDelete(sPattern, oMember, bDrop);
	end

	return iDropped;
end

--###############################################################################################
--###############################################################################################
--###############################################################################################

-----------------------------------------
-- Member Object
-----------------------------------------

function	KarmaObj.DB.M.AddedZoneSet(oMember, oMemberChar, iZoneID, bTrack)
	if (type(oMember) == "table") then
		if (oMember[KARMA_DB_L5_RRFFM.ADDED_IN] == nil) then
			local	sOut = "Setting initial zone to <" .. iZoneID .. ">";
			if (not bTrack) then
				sOut = sOut .. " (pvp)";
			end
			KarmaChatDebug(sOut);
			oMember[KARMA_DB_L5_RRFFM.ADDED_IN] = iZoneID;
		end

		if (not bTrack) then
			return
		end

		local	oZones, index, value = oMemberChar[KARMA_DB_L6_RRFFMCC_ZONEIDLIST];
		for index, value in pairs(oZones) do
			if (value == iZoneID) then
				return
			end
		end

		oZones[#oZones + 1] = iZoneID;
	end
end

function	KarmaObj.DB.M.AddedZoneGet(oMember)
	if (type(oMember) == "table") then
		return oMember[KARMA_DB_L5_RRFFM.ADDED_IN];
	end
end

function	KarmaObj.DB.M.Modified(oMember, sField)
	if (type(oMember) == "table") then
		oMember[KARMA_DB_L5_RRFFM.LASTCHANGED_TIME] = time();
		oMember[KARMA_DB_L5_RRFFM.LASTCHANGED_FIELD] = sField;
	end
end

-----------------------------------------
-- Member/Char Object
-----------------------------------------

function	KarmaObj.DB.MC.AchievementAdd(oMember, sChar, iAchievementID, iCriteriaIndex, iCritNum)
	if (type(oMember) == "table") then
		local	charobj = Karma_MemberObject_GetCharacterObject(oMember, sChar);
		if (charobj) then
			local	sAKey = "A" .. iAchievementID;	-- working key (LUA is not good with numeric keys in tables)
			KOH.TableInit(charobj, KARMA_DB_L6_RRFFMCC_ACHIEVED);
			KOH.TableInit(charobj[KARMA_DB_L6_RRFFMCC_ACHIEVED], sAKey);

			local	oAch = charobj[KARMA_DB_L6_RRFFMCC_ACHIEVED][sAKey];
			oAch.At = time();	-- singular criteria
			if (iCriteriaIndex) then
				local	sCKey = "C" .. iCriteriaIndex;
				oAch[sCKey] = time();
			end
			if (iCritNum) then
				oAch["CMAX"] = iCritNum;
			end

			KarmaObj.DB.M.Modified(oMember, "Achievement");
		end
	end
end

function	KarmaObj.DB.MC.AchievementListGet(oMember, sChar)
	if (type(oMember) == "table") then
		local	charobj = Karma_MemberObject_GetCharacterObject(oMember, sChar);
		if (type(charobj) == "table") then
			local	lAchievements = charobj[KARMA_DB_L6_RRFFMCC_ACHIEVED];
			if (type(lAchievements) == "table") then
				local	lResult, sAKey, oValues, sSubKey, oSubVal = {};
				for sAKey, oValues in pairs(lAchievements) do
					lResult[sAKey] = {};
					for sSubKey, oSubVal in pairs(oValues) do
						lResult[sAKey][sSubKey] = oSubVal;
					end
				end

				return lResult;
			end
		end
	end

	return nil;
end

function	KarmaObj.DB.MC.Exists(oMember, sChar)
	if (type(oMember) == "table") then
		local	charobj = Karma_MemberObject_GetCharacterObject(oMember, sChar);
		if (type(charobj) == "table") then
			return true;
		end
	end

	return false;
end

function	KarmaObj.DB.JoinedInInstance(oMember, sChar, sInstance)
	if (type(oMember) ~= "table") or (type(sChar) ~= "string") or (type(sInstance) ~= "string") then
		return false;
	end

	local	charobj = Karma_MemberObject_GetCharacterObject(oMember, sChar);
	if (charobj and charobj[KARMA_DB_L6_RRFFMCC_REGIONLIST]) then
		local	oRegions = charobj[KARMA_DB_L6_RRFFMCC_REGIONLIST];
		if (oRegions) then
			local	CommonRegionList = KarmaObj.DB.CG.RegionListGet();

			local	k, v;
			for k, v in pairs(oRegions) do
				local	iRegionID = v[KARMA_DB_L7_RRFFMCCRR_ID];
				local	sRegion = CommonRegionList[iRegionID].Name;
				if (string.find(sRegion, sInstance)) then
					return true;
				end
			end
		end
	end

	return false;
end

--###############################################################################################
--###############################################################################################
--###############################################################################################

function	KarmaObj.DB.FixupAchCMAX()
	-- CMAX wasn't stored properly at first, this fixes that

	local	lMembers = KarmaObj.DB.SF.MemberListGet(oFaction);
	local	sBucketName, oBucketValues;
	for sBucketName, BucketValue in pairs(lMembers) do -- Loop through each bucket
		local	sMemberName, oMember;
		for sMemberName, oMember in pairs(BucketValue) do -- Loop through contents of bucket
			local	oMemPerChar = oMember[KARMA_DB_L5_RRFFM_CHARACTERS];
			if (type(oMemPerChar) == "table") then
				for sChar, oChar in pairs(oMemPerChar) do
					if (type(oChar[KARMA_DB_L6_RRFFMCC_ACHIEVED]) == "table") then
						local	sAKey, oAch;
						for sAKey, oAch in pairs(oChar[KARMA_DB_L6_RRFFMCC_ACHIEVED]) do
							if (oAch.CMAX == nil) then
								local	iAch = tonumber(strsub(sAKey, 2));
								oAch.CMAX = GetAchievementNumCriteria(iAch);
								if (oAch.CMAX ~= nil) then
									local	_, sAchievementName = GetAchievementInfo(iAch);
									KarmaChatDebug("Fixup(CMAX): nil -> " .. oAch.CMAX .. " for " .. sMemberName .. " in data relating to " .. sChar);
								end
							end
						end
					end
				end
			end
		end
	end
end

--###############################################################################################
--###############################################################################################
--###############################################################################################
--[[
local	KARMA_DB_L5_RRFFI = {
			GUID = "GUID",
			ACTIONS = "ACTIONS",
			IGNORE = "IGN",
			TIMEOUT = "TIMEOUT",
		};
]]--

function	KarmaObj.DB.I24.Clean(oFaction)
	local	oIgn24 = oFaction[KARMA_DB_L4_RRFF.IGNORE24];
	if (next(oIgn24)) then
		local	iNow = time() - 86400;
		local	oDrop, k, v = {};
		for k, v in pairs(oIgn24) do
			if (v[KARMA_DB_L5_RRFFI.TIMEOUT] < iNow) then
				tinsert(oDrop, k);
			end
		end

		local	iCnt, i = #oDrop;
		for i = 1, iCnt do
			oIgn24[oDrop[i]] = nil;
		end
	end
end

function	KarmaObj.DB.I24.Add(sName, sGUID, sEvent, sAction, bIgnore)
	local	oFaction = KarmaObj.DB.FactionCacheGet();
	local	oIgn24 = oFaction[KARMA_DB_L4_RRFF.IGNORE24];
	if (oIgn24[sName] == nil) then
		oIgn24[sName] = { [ KARMA_DB_L5_RRFFI.ACTIONS ] = {} };
	end
	local	oData = oIgn24[sName];

	local	iNow = time();
	oData[KARMA_DB_L5_RRFFI.TIMEOUT] = iNow;
	if (sGUID) then
		oData[KARMA_DB_L5_RRFFI.GUID] = sGUID;
	end
	if (bIgnore ~= nil) then
		oData[KARMA_DB_L5_RRFFI.IGNORE] = bIgnore;
	end

	local	oActions = oData[KARMA_DB_L5_RRFFI.ACTIONS];
	oActions[#oActions + 1] = { iTime = iNow, sEvent = sEvent, sAction = sAction };
end

function	KarmaObj.DB.I24.Check(sName)
	local	oFaction = KarmaObj.DB.FactionCacheGet();
	local	oIgn24 = oFaction[KARMA_DB_L4_RRFF.IGNORE24];
	if (oIgn24[sName] ~= nil) then
		local	oData = oIgn24[sName];
		return oData[KARMA_DB_L5_RRFFI.IGNORE];
	end

	return false;
end

--
--- Import/Export
--

function KarmaObj.DB.ExportOne(Member)
	-- do global export of current server/faction if no name?
	local	sBucketName = KarmaObj.NameToBucket(Member);
	local	lMembers = Karma_Faction_GetMemberList(oFaction);
	local	tMember = lMembers[sBucketName][Member];
	if (tMember == nil) then
		KarmaChatDefault("Can't export " .. args[2] .. KARMA_WINEL_FRAG_COLONSPACE .. KARMA_MSG_COMMAND_NOTMEMBER);
		return;
	end

	-- to export, we need:
	-- (1) the Questnames to ID mapping
	-- (2) the Zones to ID mapping
	-- (3) the player data

	local KarmaTransRoot = nil;
	if (KARMATRANS_AVAILABLE ~= nil) then
		KarmaTransRoot = KarmaExp;
	else
		KarmaTransRoot = KarmaData["_EXP_"];
	end

	if (KarmaTransRoot == nil) then
		KarmaTransRoot = {};
		KarmaTransRoot["CSV"] = {};
		KarmaTransRoot["LUA"] = {};
		KarmaTransRoot["LUA"]["_M"] = {};
		KarmaTransRoot["LUA"]["_Q"] = {};
		KarmaTransRoot["LUA"]["_Z"] = {};
		KarmaTransRoot["LUA"]["_R"] = {};
		KarmaTransRoot["SFD"] = {};
		KarmaTransRoot["SFD"]["SERVER"] = GetRealmName();
		KarmaTransRoot["SFD"]["FACTION"] = UnitFactionGroup("player");
		KarmaTransRoot["SFD"]["DBVERSION"] = KARMA_SUPPORTEDDATABASEVERSION;

		-- assign back
		if (KARMATRANS_AVAILABLE ~= nil) then
			KarmaExp = KarmaTransRoot;
		else
			KarmaData["_EXP_"] = KarmaTransRoot;
		end
	end

	-- for our import: just everything in Blizzard format
	-- must not add anything to this, as LUA also adds it into tMember...
	KarmaTransRoot["LUA"]["_M"][Member] = tMember;

	-- shortcuts
	local ExportRootLUA = KarmaTransRoot["LUA"];
	local ExportRootCSV = KarmaTransRoot["CSV"];

	ExportRootCSV[Member] = {};

	-- for import in a spreadsheet
	-- °: just a char noone uses in notes (hopefully) - any better ideas for a delimiter?
	local CSVText	=  "###P;"	.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM.NAME])
					.. ";"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM_KARMA])
					.. ";"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM.LEVEL])
					.. ";"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM.CLASS])
					.. ";"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM.CLASS_ID])
					.. ";"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM.GENDER])
					.. ";"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM.GUILD])
					.. ";"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM.RACE])
					.. ";°"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM_NOTES])
					.. "°";
	if (tMember[KARMA_DB_L5_RRFFM_TIMESTAMP] ~= nil) then
		CSVText	= CSVText
				.. ";"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_TRY])
				.. ";"		.. Karma_NilToEmptyString(tMember[KARMA_DB_L5_RRFFM_TIMESTAMP][KARMA_DB_L5_RRFFM_TIMESTAMP_SUCCESS]);
	end
	ExportRootCSV[Member]["_G"] = CSVText;

	-- let all the IDs make sense...
	local CQL = CommonQuestListGet();
	local CQIL = CommonQuestInfoListGet();
	local CZL = CommonZoneListGet();
	local RegionListToAdd = {};
	for mychar, infos in pairs(tMember[KARMA_DB_L5_RRFFM_CHARACTERS]) do
		-- convert general CHARACTERS data into CSV format
		ExportRootCSV[Member][mychar] = {};
		ExportRootCSV[Member][mychar]["_X"] = "###PC;" .. Member .. ";" .. mychar
											.. ";" .. Karma_NilToEmptyString(infos[KARMA_DB_L6_RRFFMCC_XPLAST])
											.. ";" .. Karma_NilToEmptyString(infos[KARMA_DB_L6_RRFFMCC_XPMAX])
											.. ";" .. Karma_NilToEmptyString(infos[KARMA_DB_L6_RRFFMCC_XP])
											.. ";" .. Karma_NilToEmptyString(infos[KARMA_DB_L6_RRFFMCC_PLAYEDLAST])
											.. ";" .. Karma_NilToEmptyString(infos[KARMA_DB_L6_RRFFMCC_PLAYED]);

		ExportRootCSV[Member][mychar]["_Q"] = {};
		for index, QID in pairs(infos[KARMA_DB_L6_RRFFMCC_QUESTIDLIST]) do
			local QIDKey = "Q"..QID;
			local QIDPos = - QID;
			if (ExportRootLUA["_Q"][QIDKey] == nil) then
				if (CQL[QIDPos] ~= nil) then
					ExportRootLUA["_Q"][QIDKey] = {};
					ExportRootLUA["_Q"][QIDKey]["ID"] = QID;
					ExportRootLUA["_Q"][QIDKey]["NAME"] = CQL[QIDPos];
					ExportRootLUA["_Q"][QIDKey]["INFOS"] = CQIL[QIDPos];

					local QName = CQL[QIDPos];
					if (QName == nil) then
						QName = "NIL";
					end
					ExportRootCSV[QIDKey] = "###Q2N;" .. QID .. ";" .. QName;

					-- currently only region ID, wanted originally also QObjectives saved...
					local QRegionID;
					if (CQIL[QIDPos] ~= nil) then
						QRegionID = CQIL[QIDPos].RegionID;
					end
					if (QRegionID ~= nil) then
						ExportRootCSV[QIDKey] = ExportRootCSV[QIDKey] .. ";" .. QRegionID;

						table.insert(RegionListToAdd, QRegionID);
					end
				end
			end
			-- last ";" to add completion infos, if available
			ExportRootCSV[Member][mychar]["_Q"][QIDKey] = "###Q2C;" .. QID .. ";" .. Member .. ";" .. mychar .. ";";
		end
		-- QUESTEXLIST is currently fucked up, thanks to a LUA change of maximum stupidity
		-- have to change the DB format again to force it to save the Objective-Nr. explicitly
		-- same for QUESTNAMES. *grmbls* => no action in DB v8

		ExportRootCSV[Member][mychar]["_Z"] = {};
		for index, ZID in pairs(infos[KARMA_DB_L6_RRFFMCC_ZONEIDLIST]) do
			local ZIDKey = "Z"..ZID;
			local ZIDPos = - ZID;
			if (ExportRootLUA["_Z"][ZIDKey] == nil) then
				ExportRootLUA["_Z"][ZIDKey] = {};
				ExportRootLUA["_Z"][ZIDKey]["ID"] = ZID;

				if (CZL[ZIDPos] ~= nil) then
					ExportRootLUA["_Z"][ZIDKey]["NAME"] = CZL[ZIDPos].Name;
					ExportRootLUA["_Z"][ZIDKey]["RID"] = CZL[ZIDPos].RegionID;

					local ZName = CZL[ZIDPos].Name;
					if (ZName == nil) then
						ZName = "NIL";
					end
					ExportRootCSV[ZIDKey] = "###Z2N;" .. ZID .. ";" .. ZName;

					local ZRegionID = CZL[ZIDPos].RegionID
					if (ZRegionID ~= nil) then
						ExportRootCSV[ZIDKey] = ExportRootCSV[ZIDKey] .. ";" .. ZRegionID;

						table.insert(RegionListToAdd, ZRegionID);
					end
				end
			end

			ExportRootCSV[Member][mychar]["_Z"][ZIDKey] = "###Z2C;" .. ZID .. ";" .. Member .. ";" .. mychar .. ";";
		end
	end

	if (#RegionListToAdd > 0) then
		local CRL = CommonRegionListGet();
		for index, RID in pairs(RegionListToAdd) do
			if (RID ~= 0) then
				local RIDKey = "R"..RID;
				if (ExportRootLUA["_R"][RIDKey] == nil) then
					ExportRootLUA["_R"][RIDKey] = {};
					ExportRootLUA["_R"][RIDKey]["ID"] = RID;
					ExportRootLUA["_R"][RIDKey]["NAME"] = CRL[RID].Name;
		
					local RName = CRL[RID].Name;
					if (RName == nil) then
						RName = "NIL";
					end
					ExportRootCSV[RIDKey] = "###R;" .. RID .. ";" .. RName;
				end
			end
		end
	end
end

function KarmaObj.DB.Import(args)
	local KarmaTransRoot = nil;
	if (KARMATRANS_AVAILABLE ~= nil) then
		KarmaTransRoot = KarmaImp;
	else
		KarmaTransRoot = KarmaData["_IMP_"];
	end

	if (type(KarmaTransRoot) ~= "table") then
		-- no *sensible* data
		KarmaChatDefault("No data to import at all.");
		return;
	end

	if KarmaTransRoot == {} then
		-- empty data
		KarmaChatDefault("Import data set empty (1).");
		return;
	end

	if (type(KarmaTransRoot["LUA"]) ~= "table") then
		-- *still* no sensible data
		KarmaChatDefault("Import data set empty (2).");
		return;
	end

	if KarmaTransRoot["LUA"] == {} then
		-- *still* empty data
		KarmaChatDefault("Import data set empty (3).");
		return;
	end

	if (type(KarmaTransRoot["SFD"]) ~= "table") then
		-- unverifyable source
		KarmaChatDefault("Import data set incomplete.");
		return;
	end

	local Server = KarmaTransRoot["SFD"]["SERVER"];
	local Faction = KarmaTransRoot["SFD"]["FACTION"];
	if  (GetRealmName() ~= Server) or
		(UnitFactionGroup("player") ~= Faction) then
		KarmaChatDefault("Import entries' source does not match. Data set is from server "..Karma_NilToString(Server)..", faction "..Karma_NilToString(Faction)..". Import aborted.");
		return;
	end

	local DBVersion = KarmaTransRoot["SFD"]["DBVERSION"];
	if (DBVersion ~= KARMA_SUPPORTEDDATABASEVERSION) then
		KarmaChatDefault("Import entries were exported from an incompatible version (v"..Karma_NilToString(DBVersion)..").");
		KarmaChatDefault("You will have to re-export the data with the current Karma version. Import aborted.");
		return;
	end

	if (args[2] ~= nil) then
		KarmaChatDefault("Trying to only import " .. args[2] .. KARMA_WINEL_FRAG_TRIDOTS);
	else
		KarmaChatDefault("Importing entries" .. KARMA_WINEL_FRAG_TRIDOTS);
	end

	KarmaChatSecondary("Starting import" .. KARMA_WINEL_FRAG_TRIDOTS);

	-- localize
	local ImportMember, ImportData;

	-- we only go from the LUA data, CSV is being ignored.
	-- shortcuts
	local ImportRootLUA = KarmaTransRoot["LUA"];

	-- TODO much later: insert the region info... (i.e. Zone <-> Region mappings)

	-- first get a mapping of the IDs in the data to our current IDs.
	local QIDImp2QIDIntern = {};
	local ImportQID;
	for ImportQID, ImportData in pairs(ImportRootLUA["_Q"]) do
		InternQID = Karma_QuestList_AddQuest(ImportData["NAME"]);
		QIDImp2QIDIntern[ImportQID] = {};
		QIDImp2QIDIntern[ImportQID].ID = InternQID;
	end

	local ZIDImp2ZIDIntern = {};
	local ImportZID;
	for ImportZID, ImportData in pairs(ImportRootLUA["_Z"]) do
		if (ImportData["NAME"] ~= nil) then
			InternZID = Karma_ZoneList_AddZone(ImportData["NAME"]);
			ZIDImp2ZIDIntern[ImportZID] = {};
			ZIDImp2ZIDIntern[ImportZID].ID = InternZID;
		end
	end

	-- now import the list data
	local ImportCount = 0;
	local lMembers = Karma_Faction_GetMemberList(oFaction);
	for ImportMember, ImportData in pairs(ImportRootLUA["_M"]) do
		local DoIt = true;
		if (args[2] ~= nil) then
			if (args[2] ~= ImportMember) then
				DoIt = false;
			else
				KarmaChatSecondary(args[2] .. " found, importing" .. KARMA_WINEL_FRAG_TRIDOTS);
			end
		end

		if (DoIt) then
			ImportCount = ImportCount + 1;

			local sBucketName = KarmaObj.NameToBucket(ImportMember);
			if (lMembers[sBucketName][ImportMember] == nil) then
				Karma_MemberList_Add(ImportMember);
				KarmaChatSecondary("Added "..ImportMember.." to Karma's list" .. KARMA_WINEL_FRAG_TRIDOTS);
			end
	
			local tMember = lMembers[sBucketName][ImportMember];
	
			-- now, don't *lose* data here, that would really be the opposite of why the whole export/import is done...
	
			-- Karma value... tricky one. take max. to allow multiple imports of the same data
			local DeltaImp = ImportData[KARMA_DB_L5_RRFFM_KARMA] - 50;
			local DeltaIntern = tMember[KARMA_DB_L5_RRFFM_KARMA] - 50;
			local ImpKarmaNew;
			if (DeltaIntern == 0) then
				ImpKarmaNew = 50 + DeltaImp;
			elseif (DeltaImp == 0) then
				ImpKarmaNew = 50 + DeltaIntern;
			elseif (DeltaImp > 0) and (DeltaIntern > 0) then
				ImpKarmaNew = 50 + max(DeltaImp, DeltaIntern);
			else
				ImpKarmaNew = 50 + min(DeltaImp, DeltaIntern);
			end
			if (ImpKarmaNew < 0) then
				ImpKarmaNew = 0;
			elseif (ImpKarmaNew > 100) then
				ImpKarmaNew = 100;
			end

			tMember[KARMA_DB_L5_RRFFM_KARMA] = ImpKarmaNew;
	
			if (tMember[KARMA_DB_L5_RRFFM.LEVEL] == 0) and (ImportData[KARMA_DB_L5_RRFFM.LEVEL] > 0) then
				tMember[KARMA_DB_L5_RRFFM.LEVEL] = ImportData[KARMA_DB_L5_RRFFM.LEVEL];
			end
			if (tMember[KARMA_DB_L5_RRFFM.CLASS] == "") and (strlen(Karma_NilToEmptyString(ImportData[KARMA_DB_L5_RRFFM.CLASS])) > 0) then
				tMember[KARMA_DB_L5_RRFFM.CLASS] = ImportData[KARMA_DB_L5_RRFFM.CLASS];
			end
			if (tMember[KARMA_DB_L5_RRFFM.GENDER] == "") and (type(ImportData[KARMA_DB_L5_RRFFM.GENDER]) == "number") then
				tMember[KARMA_DB_L5_RRFFM.GENDER] = ImportData[KARMA_DB_L5_RRFFM.GENDER];
			end
			if (tMember[KARMA_DB_L5_RRFFM.GUILD] == "") and (ImportData[KARMA_DB_L5_RRFFM.GUILD] ~= "") then
				tMember[KARMA_DB_L5_RRFFM.GUILD] = ImportData[KARMA_DB_L5_RRFFM.GUILD];
			end
			if (tMember[KARMA_DB_L5_RRFFM.RACE] == "") and (ImportData[KARMA_DB_L5_RRFFM.RACE] ~= "") then
				tMember[KARMA_DB_L5_RRFFM.RACE] = ImportData[KARMA_DB_L5_RRFFM.RACE];
			end
	
			-- Notes... same problem as above. add if missing to allow multiple imports of the same data
			-- this could backfire, if multiple different subsets of notes are added multiple times in different order
			-- I'd call that user error ;) /Kärbär
			if (string.find(tMember[KARMA_DB_L5_RRFFM_NOTES], ImportData[KARMA_DB_L5_RRFFM_NOTES], 1, true) == nil) then
				tMember[KARMA_DB_L5_RRFFM_NOTES] = tMember[KARMA_DB_L5_RRFFM_NOTES]  .. ImportData[KARMA_DB_L5_RRFFM_NOTES];
			end
	
			for mychar, infos in pairs(ImportData[KARMA_DB_L5_RRFFM_CHARACTERS]) do
				if (tMember[KARMA_DB_L5_RRFFM_CHARACTERS][mychar] == nil) then
					tMember[KARMA_DB_L5_RRFFM_CHARACTERS][mychar] = {};
				end
				local MemChar = tMember[KARMA_DB_L5_RRFFM_CHARACTERS][mychar];

				if (args[2] ~= nil) then
					KarmaChatDebug("K: "..ImportMember.."::"..mychar.." started.");
				end
	
				-- XPLAST, XPMAX:
				-- most recent update of the player to our current (XPLAST) and level max (XPMAX) exp
				-- XP:
				-- accumulation of grouped exp with the player
				-- therefore:
				-- the value with the larger XPMAX or if same, larger XPLAST, wins
				local MemXPMax = Karma_NilToZero(MemChar[KARMA_DB_L6_RRFFMCC_XPMAX]);
				local ImpXPMax = Karma_NilToZero(infos[KARMA_DB_L6_RRFFMCC_XPMAX]);
				if (MemXPMax < ImpXPMax) or
				   ((MemXPMax == ImpXPMax) and
				   (Karma_NilToZero(MemChar[KARMA_DB_L6_RRFFMCC_XPLAST]) <= Karma_NilToZero(infos[KARMA_DB_L6_RRFFMCC_XPLAST]))) then
				   	MemChar[KARMA_DB_L6_RRFFMCC_XPLAST] = infos[KARMA_DB_L6_RRFFMCC_XPLAST];
					MemChar[KARMA_DB_L6_RRFFMCC_XPMAX] = infos[KARMA_DB_L6_RRFFMCC_XPMAX];
				end
				if (Karma_NilToZero(MemChar[KARMA_DB_L6_RRFFMCC_XP]) < Karma_NilToZero(infos[KARMA_DB_L6_RRFFMCC_XP])) then
					MemChar[KARMA_DB_L6_RRFFMCC_XP] = infos[KARMA_DB_L6_RRFFMCC_XP];
				end
	
				-- PLAYEDLAST: timestamp of most recent update to PLAYED
				-- PLAYED: summed playtime
				-- therefore: take larger PLAYED, reset PLAYEDLAST
				MemChar[KARMA_DB_L6_RRFFMCC_PLAYEDLAST] = 0;
				if (Karma_NilToZero(MemChar[KARMA_DB_L6_RRFFMCC_PLAYED]) < Karma_NilToZero(infos[KARMA_DB_L6_RRFFMCC_PLAYED])) then
					MemChar[KARMA_DB_L6_RRFFMCC_PLAYED] = infos[KARMA_DB_L6_RRFFMCC_PLAYED];
				end
	
				local QIDIntern = {};
				for index, QID in pairs(infos[KARMA_DB_L6_RRFFMCC_QUESTIDLIST]) do
					local QIDKey = "Q"..QID;
					if (QIDImp2QIDIntern[QIDKey] ~= nil) then
						table.insert(QIDIntern, QIDImp2QIDIntern[QIDKey].ID);
					end
				end
				local S1, S2, S3;
				S1 = #MemChar[KARMA_DB_L6_RRFFMCC_QUESTIDLIST];
				S2 = #QIDIntern;
				MemChar[KARMA_DB_L6_RRFFMCC_QUESTIDLIST] = Karma_TableMerge2Into1(MemChar[KARMA_DB_L6_RRFFMCC_QUESTIDLIST], QIDIntern);
				S3 = #MemChar[KARMA_DB_L6_RRFFMCC_QUESTIDLIST];
				if (args[2] ~= nil) and (S2 > 0) then
					KarmaChatDebug("K: "..ImportMember.."::"..mychar..": Q "..S1.."+"..S2.."="..S3);
				end
	
				if (infos[KARMA_DB_L6_RRFFMCC_QUESTEXLIST] ~= nil) then
					for index, QIDEx in pairs(infos[KARMA_DB_L6_RRFFMCC_QUESTEXLIST]) do
						-- currently (v8) not really feasible :/
					end
				end
	
				local ZIDIntern = {};
				for index, ZID in pairs(infos[KARMA_DB_L6_RRFFMCC_ZONEIDLIST]) do
					local ZIDKey = "Z"..ZID;
					if (ZIDImp2ZIDIntern[ZIDKey] ~= nil) then
						table.insert(ZIDIntern, ZIDImp2ZIDIntern[ZIDKey].ID);
					end
				end
				S1 = #MemChar[KARMA_DB_L6_RRFFMCC_ZONEIDLIST];
				S2 = #ZIDIntern;
				MemChar[KARMA_DB_L6_RRFFMCC_ZONEIDLIST] = Karma_TableMerge2Into1(MemChar[KARMA_DB_L6_RRFFMCC_ZONEIDLIST], ZIDIntern);
				S3 = #MemChar[KARMA_DB_L6_RRFFMCC_ZONEIDLIST];
				if (args[2] ~= nil) and (S2 > 0) then
					KarmaChatDebug("K: "..ImportMember.."::"..mychar..": Q "..S1.."+"..S2.."="..S3);
				end

				if (args[2] ~= nil) then
					KarmaChatDebug("K: "..ImportMember.."::"..mychar.." ended.");
				end
			end
		end
	end
	
	KarmaChatSecondary("Import complete.");
	KarmaChatDefault("Import complete, "..ImportCount.." entries transmogrified.");
end

function	KarmaObj.DB.ImpExpCleanup()
	if (KARMATRANS_AVAILABLE ~= nil) then
		KarmaExp = nil;
		KarmaImp = nil;
	else
		KarmaData["_EXP_"] = nil;
		KarmaData["_IMP_"] = nil;
	end
end

