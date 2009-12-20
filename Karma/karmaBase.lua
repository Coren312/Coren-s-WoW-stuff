
-- Karma's global anchor
KarmaAvEnK = {};

-- cross-module access
local	KarmaObj = KarmaAvEnK;

KarmaObj.UI = {};			-- UI anchor
KarmaObj.UI.OptWnd = {};		-- Options window stuff
KarmaObj.Slash = {};			-- Slash commands anchor
KarmaObj.Achievements = {};		-- Achievements anchor
KarmaObj.Talents = {};			-- Talents anchor
KarmaObj.DB = {};			-- DB anchor

KarmaObj.DB.CG = {};			-- common/global
KarmaObj.DB.CF = {};			-- common/faction
KarmaObj.DB.SF = {};			-- server/faction
KarmaObj.DB.I24 = {};			-- ignore24
KarmaObj.DB.M = {};			-- member
KarmaObj.DB.MC = {};			-- member/char

--
--
--

KarmaObj.Helpers = {};			-- small helper functions, moved to here

local	KARMA_ALPHACHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

--------------------------------------------------------------------------------
---
---                         QUICK&SHORT HELPERS
---
--------------------------------------------------------------------------------

function	KarmaObj.Helpers.TableIsEmpty(tValue)
	-- next(tTable, [ itStart ] ) returns the first key/value pair when itStart is nil
	if (tValue == nil) then
		KarmaChatDebug("KOH.TIE: nil via => " .. debugstack());
	end

	return ((type(tValue) ~= "table") or (next(tValue) == nil));
end

function	KarmaObj.Helpers.TableToString(oTable)
	local	s = "";
	if (type(oTable) ~= "table") then
		s = "?< " .. type(oTable) .. ">";
	else
		local	k, v;
		for k, v in pairs(oTable) do
			if (type(v) == "table") then
				s = s .. ", [" .. tostring(k) .. "] = { " ..  KarmaObj.Helpers.TableToString(v) .. " }";
			else
				s = s .. ", [" .. tostring(k) .. "] = <" ..  tostring(v) .. ">";
			end
		end

		s = strsub(s, 3);
	end

	return s;
end

function	KarmaObj.Helpers.AllToString(value)
	if (value == nil) then
		return "<nil>";
	else
		local	t = type(value);
		if ((t == "number") or (t == "string"))  then
			return value;
		elseif (type(value) == "boolean") then
			if (value) then
				return "<boolean:true>";
			else
				return "<boolean:false>";
			end
		else
			return "<" .. t .. ">";
		end
	end
end

function	KarmaObj.Helpers.BooleanToInt(value)
	if (value) then
		return 1;
	else
		return 0;
	end
end

function	KarmaObj.Helpers.IntToBoolean(value)
	if value == 1 then
		return true;
	else
		return false;
	end
end

function	KarmaObj.Helpers.Nil1To01(value)
	if value == 1 then
		return 1;
	else
		return 0;
	end
end

function	KarmaObj.Helpers.Name2Clickable(sName, sNameDisplayed)
	if (sNameDisplayed == nil) then
		sNameDisplayed = sName;
	end
	return format("[|Hplayer:%s|h%s|h]", sName, sNameDisplayed);
end

function	KarmaObj.Helpers.Duration2String(iTotalSeconds)
	local	retval = "";
	iTotalSeconds = floor(iTotalSeconds);
	if (iTotalSeconds > 86400) then
		retval = floor(iTotalSeconds / 86400) .. KARMA_MSG_SHORT_DAY .. KARMA_WINEL_FRAG_SPACE;
		iTotalSeconds = iTotalSeconds % 86400;
	end

	local	iHours, iMinutes, iSeconds;
	iHours = floor(iTotalSeconds / 3600);
	iTotalSeconds = iTotalSeconds % 3600;
	iMinutes = floor(iTotalSeconds / 60);
	iSeconds = iTotalSeconds % 60;

	if (iHours > 0) or (retval ~= "") then
		retval = retval .. format("%02d", iHours) .. KARMA_MSG_SHORT_HOUR .. KARMA_WINEL_FRAG_SPACE;
	end

	retval = retval .. format("%02d" .. KARMA_MSG_SHORT_MINUTE .. KARMA_WINEL_FRAG_SPACE .. " %02d" .. KARMA_MSG_SHORT_SECOND, iMinutes, iSeconds);
	return retval;
end

function	KarmaObj.Helpers.TableInit(oContainer, sKey)
	if (oContainer == nil) or (sKey == nil) or (type(oContainer) ~= "table") then
		local backtrace = debugstack();
		KarmaChatDebugFallbackSecondary(KARMA_MSG_FIELDINIT_ERROR_VALUE .. KARMA_MSG_FIELDINIT_ERROR_TABLE);
		KarmaChatDebugFallbackSecondary("CB: " .. backtrace);
	elseif (oContainer[sKey] == nil) then
		oContainer[sKey] = {};
	end
end



--------------------------------------------------------------------------------
---
---                              SORTING
---
--------------------------------------------------------------------------------

-- The following method is used instead of Lua's built in sort library sort(table1)
--     which doesn't work well on non-numeric keys
-- TODO: romg, bubblesort... this must be quicksorted!
function	KarmaObj.Helpers.GenericSort(table1, cmpfunc)
	local	lo, hi, min, j, iCount, iTotalCount;
	for k, v in pairs(table1) do
		if (lo == nil) then
			lo = k;
		elseif (k < lo) then
			lo = k;
		end
		if (hi == nil) then
			hi = k;
		elseif (k > hi) then
			hi = k;
		end
	end

	if (lo and hi) then	-- empty table?
		for iCount = lo, hi do
			min = iCount;
			if (table1[min]) then
			 	for j = iCount, hi do
					if (table1[j]) then
						-- find smallest to put in front
				 		if (cmpfunc == nil) then
					 		if table1[j] < table1[min] then
					 			min = j;
				 			end
						elseif cmpfunc(table1[j], table1[min]) then
							min = j;
			 			end
					end
				end

				-- traditional swap, don't swap unto itself
				if (min ~= iCount) then
					local	temp = table1[min]
					table1[min] = table1[iCount]
					table1[iCount] = temp;
			 	end
			end
		end
	end

	return table1;
end

-- This function returns a new table of the sorted table
-- For large amounts of data this is faster that the generic
-- sorting. for instance in a list which contains 676 evenly
-- distribued values (across the alphabet, using the first character),
-- this function only requires 17000 compares, where a straight
-- comparison requires 500000.
function	KarmaObj.Helpers.AlphaBucketSort(table1)
	local	buckets = {};
	local	result = {};
	local	i = 0;
	local	key, value;

	for i = 1, strlen(KARMA_ALPHACHARS) do
		local	sBucketName = strsub(KARMA_ALPHACHARS, i, i);
		buckets[sBucketName] = {};
	end

	for key, value in pairs(table1) do
		if (value ~= nil and value~= "") then
			local	sBucketName = KarmaObj.NameToBucket(value);
			buckets[sBucketName][getn(buckets[sBucketName])+1] = value;
		end
	end

	for key, value in pairs(buckets) do
		buckets[key] = KarmaObj.Helpers.GenericSort(value, Karma_MemberSort_CompareName);
	end

	local	iCounter = 1;
	for i = 1, strlen(KARMA_ALPHACHARS) do
		local	sBucketName = strsub(KARMA_ALPHACHARS, i, i);
		local	curbucket = buckets[sBucketName];
		local	item = nil;
		local	index = 0;
		for index, item in pairs(curbucket) do
			result[iCounter] = item;
			iCounter = iCounter+1;
		end
	end

	return result;
end

-- copy of ChatFrame.lua::GetColoredName()
local	KARMA_CONFIG =
		{
			MARKUP_ENABLED = "MARKUP",
		--	MARKUP_VERSION = "MARKUP_VERSION",
			MARKUP_COLOUR_NAME = "COLOUR_NAME",				-- missing in UI
			MARKUP_COLOUR_KARMA = "COLOUR_KARMA",				-- missing in UI
			MARKUP_SHOW_KARMA = "SHOW_KARMA",				-- missing in UI
			MARKUP_WHISPERS = "MARKUP_WHISPERS",
			MARKUP_CHANNELS = "MARKUP_CHANNELS",
			MARKUP_GUILD = "MARKUP_GUILD",
			MARKUP_RAID = "MARKUP_RAID",
			MARKUP_BG = "MARKUP_BG",
			MARKUP_YELLSAYEMOTE = "MARKUP_YSE",

		--	BETA = "BETA"
		};

function	KarmaObj.Helpers.GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
	if (arg12 == nil) or (arg12 == "") then
		return arg2
	end

	local	chatType = strsub(event, 10);
	if (strsub(chatType, 1, 7) == "WHISPER") then
		chatType = "WHISPER";
	end
	if (strsub(chatType, 1, 7) == "CHANNEL") then
		chatType = "CHANNEL" .. arg8;
	end

	local	bMarkup = Karma_GetConfig(KARMA_CONFIG.MARKUP_ENABLED);
	if (KarmaObj.UI.Chatfilters) then
		local	sKey;
		if (KarmaObj.UI.Chatfilters[event]) then
			sKey = KarmaObj.UI.Chatfilters[event].sConfig;
		else
			KarmaChatDebug("GetColoredName(): event has no sConfig? <" .. event .. ">");
		end
		if (sKey) then
			bMarkup = bMarkup and Karma_GetConfig(sKey);
		end
	end

	local	info = ChatTypeInfo[chatType];
	if (info and (bMarkup or info.colorNameByClass)) then
		local	sColorPost = "\124r";
		local	oMember = Karma_MemberList_GetObject(arg2);
		if (info.colorNameByClass and (not bMarkup or (oMember == nil))) then
			local localizedClass, englishClass, localizedRace, englishRace, sex = GetPlayerInfoByGUID(arg12);
			if (englishClass) then
				local classColorTable = RAID_CLASS_COLORS[englishClass];
				if (not classColorTable) then
					return arg2;
				end

				local	sColorPre = string.format("\124cff%.2x%.2x%.2x", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255);
				return sColorPre .. arg2 .. sColorPost;
			end
		end

		if (bMarkup and oMember) then
			local	r, g, b = Karma_MemberList_GetColors(Karma_MemberObject_GetName(oMember));
			local	sColorPre = string.format("\124cff%.2x%.2x%.2x", r*255, g*255, b*255);

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

			local	sNotes = Karma_MemberObject_GetNotes(oMember);
			if (sNotes) and (sNotes ~= "") then
				sKarma = sKarma .. "+";
			end

			if (Karma_GetConfig(KARMA_CONFIG.MARKUP_COLOUR_NAME)) then
				return "[" .. sColorPre .. arg2 .. sColorPost .. "]" .. sKarma;
			elseif (info.colorNameByClass) then
				local localizedClass, englishClass, localizedRace, englishRace, sex = GetPlayerInfoByGUID(arg12);
				if (englishClass) then
					local classColorTable = RAID_CLASS_COLORS[englishClass];
					if (not classColorTable) then
						return arg2;
					end

					local	sColorPre = string.format("\124cff%.2x%.2x%.2x", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255);
					return sColorPre .. arg2 .. sColorPost .. sKarma;
				end
			else
				return arg2 .. sKarma;
			end
		end
	end

	return arg2;
end

--
--
--

-- debug: call oMember functions by name
function	KarmaObj.Helpers.CallByName(sName, fFunc, ...)
	if ((type(sName) == "string") and (type(fFunc) == "function")) then
		local	oMember = Karma_MemberList_GetObject(sName);
		if (oMember) then
			local	xResult = fFunc(oMember, ...);
			KarmaChatDebug("Result: " .. KarmaObj.Helpers.AllToString(xResult));
		end
	end
end

