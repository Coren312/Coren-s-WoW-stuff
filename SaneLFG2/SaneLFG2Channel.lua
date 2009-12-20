
SaneLFGObj2.ChannelInfo = {};
SaneLFGObj2.sLFGBase = "SLFG2";

local	CHATFRAME = ChatFrame2;
local	oState = { bInit = true };
local	oRepeat = {};
local	oMirrors = {};

local	stringfromtable = SaneLFGObj2.Helpers.stringfromtable;

function	SaneLFGObj2.MirrorsToString()
	local	s = "";
	local	bAmMirror = false;

	local	iCnt, i, v = #oMirrors;
	for i = 1, iCnt do
		v = oMirrors[i];
		if (v == "_") then
			bAmMirror = true;
		else
			s = s .. ", " .. v;
		end
	end

	return strsub(s, 2), bAmMirror;
end

function	SaneLFGObj2.CheckMirrors(bEntered)
	-- announce that we can/can't mirror
	if (oState.ChannelNr and oState.ChannelName) then
		local	sMsg;
		if (bEntered) then
			sMsg = "$!00:C+";
			tinsert(oMirrors, "_");
		else
			sMsg = "$!00:C-";
			-- error: must be key, not value!
			-- tremove(oMirrors, "_");

			local	k, v, x;
			for k, v in pairs(oMirrors) do
				if (v == "_") then
					x = k;
					break;
				end
			end
			if (x) then
				tremove(oMirrors, x);
			end
		end

		ChatFrame4:AddMessage("SLFG2DBG: Announcing mirror capability = " .. sMsg .. " to channel " .. oState.ChannelNr .. ".");
		ChatThrottleLib:SendChatMessage("BULK", "SaneLFG2", sMsg, "CHANNEL", nil, oState.ChannelNr);
	end
end

function	SaneLFGObj2.ValidateMirror(iNr, sName, bEntered, bInternal)
	-- check if we have a valid channel for mirroring
	SaneLFGObj2.ChannelInfo[sName] = { iNr = iNr, bValid = bEntered, bEnabled = false };
	if (not bInternal) then
		SaneLFGObj2.CheckChannelsDone();
	end
end

function	SaneLFGObj2.CheckChannelsDone()
	-- check if we are in a channel named #LFG%n?
	local	iFound, iFirst, i;
	for i = 0, 10 do
		local	sName = SaneLFGObj2.sLFGBase;
		if (i > 0) then
			sName = sName .. (i - 1);
		end

		local	oChan = SaneLFGObj2.ChannelInfo[sName];
		if (oChan) then
			if (iFound) then
				oChan.bEnabled = false;
			elseif (oChan.bValid) then
				iFound = i;
				oChan.bEnabled = true;
			end
		elseif (iFirst == nil) then
			iFirst = i;
		end
	end

	return iFound, iFirst;
end

function	SaneLFGObj2.CheckChannels()
	if (oState.bInit) then
		oState.bInit = false;

		-- leave *all* numbered LFG channels
		local	i;
		for i = 0, 9 do
			LeaveChannelByName(SaneLFGObj2.sLFGBase .. i);
		end

		local	oList, i, k, v = { GetChannelList() }, 0;
		for k, v in pairs(oList) do
			if (v == SaneLFGObj2.sLFGBase) then
				SaneLFGObj2.ValidateMirror(i, v, true, true);
			end
			i = v;
		end
	end

	-- check if we are in a channel named #LFG
	local	iFound, iFirst = SaneLFGObj2.CheckChannelsDone();

	CHATFRAME:AddMessage("SLFG2DBG: Channel check result = " .. tostring(iFound) .. " / " .. tostring(iFirst));

	if (iFound) then
		local	sName = SaneLFGObj2.sLFGBase;
		if (iFound > 0) then
			sName = sName .. (iFound - 1);
		end

		if (oState.ChannelName ~= sName) then
			CHATFRAME:AddMessage("SaneLFG2: Accepting channel #" .. sName .. " as LFG repeater.");
		end

		oState.ChannelNr = SaneLFGObj2.ChannelInfo[sName].iNr;
		oState.ChannelName = sName;

		local	iCnt, bFound, i = #oMirrors, false;
		for i = 1, iCnt do
			if (oMirrors[i] == "_") then
				bFound = true;
				break
			end
		end

		if (not bFound and SaneLFGObj2.CheckMirrors(SaneLFGObj2.ChannelInfo[sName].bEnabled)) then
		end
	else
		oState.ChannelNr = nil;
		oState.ChannelName = nil;
		if (iFirst) then
			local	oList, i, k, v = { GetChannelList() }, 0;
			for k, v in pairs(oList) do
				i = i + 1;
			end
			if (i < 20) then
				local	sName = SaneLFGObj2.sLFGBase;
				if (iFirst > 0) then
					sName = sName .. (iFirst - 1);
				end

				SaneLFGObj2.bInit = 1;
				SaneLFGObj2.iInitDelay = 10;

				CHATFRAME:AddMessage("SaneLFG2: Joining channel #" .. sName .. " for LFG.");
				JoinChannelByName(sName);
			else
				-- no more channel space left to try! :-(
				CHATFRAME:AddMessage("SaneLFG2: Ten channels are in use - no more space (to look) for (unlocked) LFG channels. :-(");
			end
		else
			-- no more channels left to try! :-(
			CHATFRAME:AddMessage("SaneLFG2: No more namespace for (unlocked) LFG channels. :-(");
		end
	end
end

function	SaneLFGObj2.AddonMessage(...)
	local	arg1, arg2, arg3, arg4 = ...;
	if (arg1 ~= "SANELFG2") then
		return
	end
	if (arg3 ~= "WHISPER") then
		return
	end

	local	sFrom = arg4;
	local	sMsg = arg2;
	if (strsub(sMsg, 1, 1) == "R") then
		-- someone sent a message from their alt to our alt:
		local	sAltAndClass, sTo, sMsgSub = string.match(sMsg, "R([^!]+)!([^!]+)!(.+)");
		local	sAlt, sClassEN;
		if (sAltAndClass) then
			sAlt, sClassEN = string.match(sAltAndClass, "([^:]+):(.+)");
		end
		if (sAlt and sClassEN) then
			if (sAlt ~= sFrom) then
				SaneLFGObj2.Maps.NameToContact[sAlt] = sFrom;
			end

			local	oColors = RAID_CLASS_COLORS[sClassEN];
			if (oColors) then
				sAlt = string.format("|cFF%.2X%.2X%.2X%s|r", oColors.r*255, oColors.g*255, oColors.b*255, sAlt);
			end

			CHATFRAME:AddMessage("{" .. sAlt .. "} => <" .. sTo .. "> : " .. sMsgSub);
		end
	elseif (strsub(sMsg, 1, 1) == "A") then
		-- someone sent a message for us as our alt:
		local	sAlt, sMsgSub = string.match(sMsg, "A([^!]+)!(.+)");
		if (sAlt) then
			CHATFRAME:AddMessage("[" .. sFrom .. "] => <" .. sAlt .. "> : " .. sMsgSub);
		end
	end
end

function	SaneLFGObj2.ChannelMessage(...)
	local	arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12 = ...;

	-- if it's from us: ignore
	if (arg2 == SaneLFGObj2.WhoAmI) then
		-- need to parse back binary message for validation...
		-- TODO: on release no back-parsing!
		if (arg7 ~= 0) then
			return
		end
	end

	if ((arg7 == 1) or (arg7 == 2) or (arg7 == 26)) then
		-- from Blizzard Trade or LFG channel
		SaneLFGObj2.ParseMessageSpam(arg2, arg12, arg1, arg7 == 26, arg9);
	elseif ((arg7 == 0) and (arg8 == oState.ChannelNr)) then
		-- from repeater channel
		SaneLFGObj2.ParseMessagePacked(arg2, arg12, arg1);
	end
end

function	SaneLFGObj2.ParseMessageSpam(sFrom, sGUID, sMessage, bChannelLFG, sChannel, sInternal)
	local	sMsgOrg = sMessage;
	if (strsub(sMessage, 1, 2) == "$!") then
		-- ignore: someone else was sending a formatted message, that should also end up ParseMessagePacked()
		return
	end

	if (string.find(sMessage, "!!!!")) then
		-- ignore: stupid people
		return
	end

	-- if the message is not from LFG and very long, drop it... we might match all kinds of stuff wrongly
	if (not bChannelLFG and (strlen(sMessage) > 128)) then
		ChatFrame4:AddMessage("SLFG2DBG: Skipping very long message from " .. sFrom .. " in #" .. sChannel .. ".");
		return
	end

	-- if identical repeated message, skip parsing and just refresh the timer
	if (not sInternal) then
		local	oTotal = SaneLFGObj2.FactionRealm.ParsedChannel[sFrom];
		if (oTotal ~= nil) then
			if (oTotal.oData.sRaw1 == sMsgOrg) then
				ChatFrame4:AddMessage("SLFG2DBG: No parsing, updated existing entry from " .. sFrom .. ".");
				oTotal.iUpdatedAt = time();
				SaneLFGObj2.MainWndButtonSetup(oTotal.oFrom, oTotal.oData, oTotal.iUpdatedAt);
				return
			end
		end
	end

	-- the formats are very language specific (see CallToArms's non-exact parsing just for keywords)
	-- to make sense in most cases, we need to impose some additional restrictions
	-- => go with rather fixed messages for now
	local	oTable = SaneLFG2Locales.Current.Messages;
	if (oTable == nil) then
		oTable = SaneLFG2Locales["enUS"].Messages;
	end

	local	sMsgLow = strlower(sMessage);

	-- ========================= pre-parse for adds/trades/skills/items/etc. =======================

	-- first, catch some links:
	if (not bChannelLFG and string.find(sMessage, "|Hitem:")) then
		-- LFG channel is allowed to have "<item> reserved"
		return
	end
	if (string.find(sMessage, "|Henchant:")) then
		return
	end

	local	k, v;
	for k, v in pairs(oTable.Skills) do
		if (string.find(sMsgLow, v)) then
			return
		end
	end

	-- if it has "guild" in it, but not "guild run" or "in guild", then it's likely a LFGuild/LFRecruits ad
	if (oTable.Guild) then
		if (string.find(sMsgLow, oTable.Guild[1][1])) then
			local	bOk = false;
			local	iMax, i = #oTable.Guild[2];
			for i = 1, iMax do
				if (string.find(sMsgLow, oTable.Guild[2][i])) then
					bOk = true;
					break
				end
			end

			if (not bOk) then
				return
			end
		end

		-- LF recruits doesn't always carry a "guild" somewhere
		local	iMax, i = #oTable.Guild[1];
		for i = 2, iMax do
			if (string.find(sMsgLow, oTable.Guild[1][i])) then
				return
			end
		end
	end

	-- cut stuff we don't need:
	if (next(oTable.Cut)) then
		local	iMax, i = #oTable.Cut;
		for i = 1, iMax do
			local	pos1, pos2 = string.find(sMsgLow, oTable.Cut[i]);
			while (pos1) do
				-- cut out of original also
				sMessage = strsub(sMessage, 1, pos1 - 1) .. strsub(sMessage, pos2 + 1);
				sMsgLow = strsub(sMsgLow, 1, pos1 - 1) .. strsub(sMsgLow, pos2 + 1);

				pos1, pos2 = string.find(sMsgLow, oTable.Cut[i]);
			end
		end
	end

	-- add spaces around the total string to be able to enforce the word restriction in various parses
	sMessage = " " .. sMessage .. " ";
	sMsgLow = " " .. sMsgLow .. " ";

	-- replace stuff that adds unnecessary tests: reduce similar strings to Xyz10 / Xyz25
	if (string.find(sMsgLow, "%d%d")) then
		local	iMax, i = #oTable.ReplaceA;
		for i = 1, iMax do
			local	pos1, pos2 = string.find(sMsgLow, oTable.ReplaceA[i].a);
			while (pos1) do
				sMsgLow = string.gsub(sMsgLow, oTable.ReplaceA[i].a, oTable.ReplaceA[i].b);

				pos1, pos2 = string.find(sMsgLow, oTable.ReplaceA[i].a, pos1 + 1);
			end
		end
	end
	do
		local	iMax, i = #oTable.ReplaceB;
		for i = 1, iMax do
			local	pos1, pos2 = string.find(sMsgLow, oTable.ReplaceB[i].a);
			while (pos1) do
				sMsgLow = string.gsub(sMsgLow, oTable.ReplaceB[i].a, oTable.ReplaceB[i].b);

				pos1, pos2 = string.find(sMsgLow, oTable.ReplaceB[i].a, pos1 + 1);
			end
		end
	end

	-- what I want as result is the following:
	-- given message X...
	-- => the sender is LFG or LFM
	-- if LFG:
	-- => the sender wants to go to dungeon X, Y, Z
	-- => he can assume the role of healer/dps/tank
	-- if LFM:
	-- => the sender wants to go to dungeon X, Y, Z
	-- => he needs A healers, B dps and C tanks, total D more

	-- new parse idea (20091104):
	--
	-- first, parse if we find 10/25
	-- => raid dungeons might be treated differently as their typical LFG/LFM message include "link achievement, must be overgeared, ..."
	-- => currently skipping this step, potentially this won't be necessary as the LF-RAID- tool is not utterly useless
	--
	-- second, parse out all dungeons, replace with "§|PLACE%i|§"
	-- => check if we get normal and heroic, so we must flag it per dungeon
	-- => finally replace all with "§|PLACES|§"
	--
	-- third, parse out all roles, then remove all role stuff and replace with "§|ROLE%i|§"
	-- => ROLE%i is stored with correspondent key *and* value
	-- => also find stuff like "a great healer" by checking for numbers backwards from the role position
	-- => then check for and/or between roles
	-- => try to analyze for multi-role
	-- => store to sRolesDone
	-- => then collate all "§|ROLE%i|§" to one single "§|ROLES|§"
	--
	-- finally try to analyze the final data if it's LFG or LFM and split to Who/What/Sub

	-- =================================== dungeon parsing =================================

	-- international languages: %w doesn't catch multibyte *at all*, so we can't just go with "[^%w]" :(
	local	sFix = "[%s%.,:;";
	local	sPrefix = sFix .. "%(]";
	local	sPostfix = sFix .. "%)!%?]";

	local	args, pos1, pos2, posStart, i = {};

	local	oDungeons = { [1] = { bNormal = false, bHeroic = false, bRaid = false } };
	local	iDungeonPos1Low, iDungeonPos2High;

	-- 1: Vanilla, 2 = BC, 3 = WotLK (1), 4 = WotLK (2)
	-- parse only for dungeons from found + previous era
	local	iEraCheck, iEra = 4;
	local	sData = sMsgLow;
	for iEra = 4, 1, -1 do
		if ( iEra + 1 >= iEraCheck ) then
			local	sIs, sMatch, pos1, pos2;
			for sIs, sMatch in pairs(oTable.DungeonsShort[iEra]) do
				local	posfrom, postries = 1, 5;
				pos1, pos2 = string.find(sData, sPrefix .. sMatch .. sPostfix, posfrom);
				while (pos1 and (postries > 0)) do
					-- some are only accepted if upper-case (OK, UP, AN, etc.)
					local	bOk = oTable.MustBeCase[sMatch] ~= true;
					if (not bOk) then
						bOk = string.find(sMessage, strupper(sMatch), posfrom);
					end

					if (bOk) then
						if ((iEra == 1) and not strfind(sIs, "%d%d")) then
							oDungeons[1].bNormal = true;
						end
						oDungeons[#oDungeons + 1] = { sName = sIs, iPos1 = pos1, iPos2 = pos2 };
					end

					posfrom = pos1 + 1;
					postries = postries - 1;
					pos1, pos2 = string.find(sData, sPrefix .. sMatch .. sPostfix, posfrom);
				end
			end

			for sMatch, sIs in pairs(oTable.Dungeons[iEra]) do
				local	posfrom, postries = 1, 5;
				pos1, pos2 = string.find(sData, sPrefix .. sMatch .. sPostfix, posfrom);
				while (pos1 and (postries > 0)) do
					if (string.find(sMatch, "%%d")) then
						args[1] = string.match(sData, sPrefix .. sMatch .. sPostfix, posfrom);
						if (args[1]) then
							local	sIsNum = oTable.DungeonsShort[iEra][sIs .. args[1]]; 
							if ( sIsNum ) then
								if (iEra == 1) then
									oDungeons[1].bNormal = true;
								end
								oDungeons[#oDungeons + 1] = { sMatch1 = sMatch, sName = sIs .. args[1], iPos1 = pos1, iPos2 = pos2 };
								oDungeons[1].bRaid = true;

								ChatFrame4:AddMessage("SLFG2DBG: DungeonXX: YY? [1] = <" .. strsub(sData, pos2 + 1, pos2 + 5) .. ">, [2] = <" .. strsub(sData, pos2 + 1, pos2 + 2) .. ">");

								local	sMatchSub = "[%+/] (%d%d)";
								args[2] = string.match(strsub(sData, pos2 + 1, pos2 + 5), sMatchSub, posfrom);
								if (args[2] and (args[2] ~= args[1])) then
									sIsNum = oTable.DungeonsShort[iEra][sIs .. args[2]]; 
									if ( sIsNum ) then
										oDungeons[#oDungeons + 1] = { sMatch2a = sMatchSub, sName = sIs .. args[2], iPos1 = pos2 + 1, iPos2 = pos2 + 5 };
									end
								else
									sMatchSub = "(%d%d)";
									args[2] = string.match(strsub(sData, pos2 + 1, pos2 + 2), sMatchSub, posfrom);
									if (args[2] and (args[2] ~= args[1])) then
										sIsNum = oTable.DungeonsShort[iEra][sIs .. args[2]]; 
										if ( sIsNum ) then
											oDungeons[#oDungeons + 1] = { sMatch2b = sMatchSub, sName = sIs .. args[2], iPos1 = pos2 + 1, iPos2 = pos2 + 2 };
										end
									end
								end
							else
								ChatFrame4:AddMessage("SLFG2DBG: Fail(1) - Match of <" .. sMatch .. "> unto <" .. sData .. ">, match result is <" .. tostring(args[1]) .. ">");
							end
						else
							ChatFrame4:AddMessage("SLFG2DBG: Fail(2) - Match of <" .. sMatch .. "> unto <" .. sData .. ">");
						end
					else
						if (iEra == 1) then
							oDungeons[1].bNormal = true;
						end

						oDungeons[#oDungeons + 1] = { sMatch0 = sMatch, sName = sIs, iPos1 = pos1, iPos2 = pos2 };
					end

					posfrom = pos1 + 1;
					postries = postries - 1;
					pos1, pos2 = string.find(sData, sPrefix .. sMatch .. sPostfix, posfrom);
				end
			end
		end

		-- none found: allow checking of previous era
		if ( #oDungeons == 1 ) then
			iEraCheck = iEra - 1;
		end
	end

	if (sInternal) then
		ChatFrame4:AddMessage("SLFG2DBG: initial oDungeons = { " .. stringfromtable(oDungeons) .. " } ");
	end

	if (#oDungeons > 2) then
		oDungeons = SaneLFGObj2.Helpers.DuplicatesDrop("Dungeons", oDungeons, "sName", 2);
	end

	if (#oDungeons > 1) then
		iDungeonPos1Low = oDungeons[2].iPos1;
		iDungeonPos2High = oDungeons[2].iPos2;
		for i = 3, #oDungeons do
			iDungeonPos1Low = math.min(iDungeonPos1Low, oDungeons[i].iPos1);
			iDungeonPos2High = math.min(iDungeonPos2High, oDungeons[i].iPos2);
		end

		local	x, sHc;
		for x, sHc in pairs(oTable.Heroic) do
			if (string.find(sData, sPrefix .. sHc .. sPostfix)) then
				oDungeons[1].bHeroic = true;
				break
			end
		end

		local	x, sNorm;
		for x, sNorm in pairs(oTable.Normal) do
			if (string.find(sData, sPrefix .. sNorm .. sPostfix)) then
				oDungeons[1].bNormal = true;
				break
			end
		end

		local	iCnt, s = 0;
		local	oQualifiers = { "Raid", "Heroic", "Normal" };
		for i = 1, 3 do
			if (oDungeons[1]["b" .. oQualifiers[i]]) then
				s = oQualifiers[i];
				iCnt = iCnt + 1;
			end
		end

		if (iCnt == 1) then
			oDungeons[1].sDungeonQualifier = s;
		elseif (iCnt > 1) then
			oDungeons[1].sDungeonQualifier = "MIXED";
		end

		-- check for neg. hit
		if (oTable.DungeonLockedOut) then
			local	oHits, iPos1, iPos2 = {};

			local	iCnt, i = #oTable.DungeonLockedOut;
			for i = 1, iCnt do
				iPos1, iPos2 = string.find(sMsgLow, oTable.DungeonLockedOut[i]);
				if (iPos1) then
					tinsert(oHits, { iPos1 = iPos1, iPos2 = iPos2 });
				end
			end

			if (#oHits == 1) then
				local	bUsed = false;

				-- (a) data (saved to dungeon list) data
				local	iPos1 = string.find(sMsgLow, "%(");
				local	iPos2 = string.find(sMsgLow, "%)");
				if (iPos1 and iPos2) then
					local	bInside = (oHits[1].iPos1 >= iPos1) and (oHits[1].iPos2 <= iPos2);
					if (bInside) then
						iCnt = #oDungeons;
						for i = 2, iCnt do
							if ((oDungeons[i].iPos1 >= iPos1) and (oDungeons[i].iPos2 <= iPos2)) then
								oDungeons[i].bNegative = true;
							end
						end

						bUsed = true;
					end
				end

				-- (b) dungeon except dungeon
				if (not bUsed) then
					iCnt = #oDungeons;
					for i = 2, iCnt do
						if (oDungeons[i].iPos1 >= oHits[1].iPos2) then
							oDungeons[i].bNegative = true;
						end
					end

					bUsed = true;
				end
			end
		end

		-- if we got some raid entries, replace the numbers with X, XX, XXV, XL
		if (oDungeons[1].bRaid) then
			local	iDungeonCnt = #oDungeons;
			for i = 2, iDungeonCnt do
				if (oDungeons[i].sMatch) then
					local	sSubOld = strsub(sMsgLow, oDungeons[i].iPos1, oDungeons[i].iPos2);
					local	sSubNew = string.gsub(sSubOld, "10", "X");
					sSubNew = string.gsub(sSubOld, "20", "XX");
					sSubNew = string.gsub(sSubOld, "25", "XXV");
					sSubNew = string.gsub(sSubOld, "40", "XL");
					if (sSubOld ~= sSubNew) then
						sMsgLow = strsub(sMsgLow, 1, oDungeons[i].iPos1 - 1) .. sSubNew .. strsub(sMsgLow, oDungeons[i].iPos2 + 1);
					end
				end
			end
		end

		if (sInternal) then
			ChatFrame4:AddMessage("SLFG2DBG: final oDungeons = { " .. stringfromtable(oDungeons) .. " } ");
		end
	end

	-- TODO: collate multiple entries, replace with "§|PLACES|§"

	-- =================================== role parsing =================================

	local	oRoles, iRoleCnt = {};

	iRoleCnt = #oTable.Roles;
	for i = 1, iRoleCnt do
		local	oRole = oTable.Roles[i];
		posStart = 1;
		repeat
			pos1, pos2 = string.find(sMsgLow, oRole.s, posStart);
			if (pos1) then
				local	iNum = - 1;
				if (oRole.bNum) then
					iNum = string.match(sMsgLow, oRole.s, posStart);
					if (iNum) then
						iNum = tonumber(iNum);
					end
				end

				if (iNum) then
					if (oRole.bMany) then
						iNum = - 9;
					end
					oRoles[#oRoles + 1] = { sRole = oRole.sRole, iNum = iNum, iPos1 = pos1, iPos2 = pos2 };
				end

				posStart = pos1 + 1;
			end
		until (pos1 == nil)
	end

	-- now, check if we got larger and smaller things...
	iRoleCnt = #oRoles;
	if (iRoleCnt > 1) then
		oRoles = SaneLFGObj2.Helpers.DuplicatesDrop("Roles", oRoles, "sRole", 1);
		iRoleCnt = #oRoles;
	end

	local	oSubs;
	if (iRoleCnt > 0) then
		-- we know all positions, check if intermediate strings contain operators
		oSubs = {};

		-- first, build a list of all intermediate positions...
		local	oPos1, oPos2 = {}, {};
		for i = 1, iRoleCnt do
			tinsert(oPos1, oRoles[i].iPos1);
			tinsert(oPos2, oRoles[i].iPos2);
		end
		table.sort(oPos1);
		table.sort(oPos2);

		-- for each iPos1, find the largest smaller iPos2
		local	iPos1Cnt, iPos2Cnt, k = #oPos1, #oPos2;
		for i = 1, iPos1Cnt do
			local	iPos1 = oPos1[i];
			local	iPos2 = -1;
			for k = 1, iPos2Cnt do
				if (iPos1 > oPos2[k]) then
					iPos2 = math.max(iPos2, oPos2[k]);
				end
			end

			if ((iPos2 > 0) and (iPos2 + 1 <= iPos1 - 1)) then
				local	s = strsub(sMsgLow, iPos2 + 1, iPos1 - 1);
				while (string.find(s, "^%s")) do
					s = strsub(s, 2);
				end
				while (string.find(s, "%s$")) do
					s = strsub(s, 1, -2);
				end

				tinsert(oSubs, s);
			end
		end

		if (next(oSubs)) then
			ChatFrame4:AddMessage("SLFG2DBG: Role parse: Subs => " .. SaneLFGObj2.Helpers.stringfromlist(oSubs));
		end

		if ((#oSubs == 1) and (iRoleCnt == 2)) then
			local	bfSpecs, pos1, pos2 = 0, 255, 0;
			for i = 1, iRoleCnt do
				if (math.abs(oRoles[i].iNum) > 1) then
					bfSpecs = 8;
					break
				end

				if (oRoles[i].iPos1 < pos1) then
					pos1 = oRoles[i].iPos1;
				end
				if (oRoles[i].iPos2 < pos2) then
					pos2 = oRoles[i].iPos2;
				end

				if (oRoles[i].sRole == "Tank") then
					bfSpecs = bit.bor(bfSpecs, 1);
				elseif (oRoles[i].sRole == "Heal") then
					bfSpecs = bit.bor(bfSpecs, 2);
				elseif (oRoles[i].sRole == "DPS") then
					bfSpecs = bit.bor(bfSpecs, 4);
				else
					bfSpecs = bit.bor(bfSpecs, 8);
				end
			end

			if (bit.band(bfSpecs, 8) == 0) then
				local	iCnt, l, i = #oTable.Inter;
				local	sSub = " " .. oSubs[1] .. " ";
				for i = 1, iCnt do
					local	oInter = oTable.Inter[i];
					if ((oInter.l == 1) and string.find(sSub, "^%s*" .. oInter.s .. "%s*$")) then
						l = oInter.l;
					end
				end

				-- if (sInternal) then
				ChatFrame4:AddMessage("SLFG2DBG: ... role merge => l = " .. tostring(l) .. ", bfSpecs = " .. tostring(bfSpecs));
				-- end

				if (l == 1) then
					local	sRole;

					if (bfSpecs == 3) then
						sRole = "TankHeal";
					elseif (bfSpecs == 5) then
						sRole = "TankDPS";
					elseif (bfSpecs == 6) then
						sRole = "DPSHeal";
					end

					if (sRole) then
						oRoles[2] = nil;
						oRoles[1] = { sRole = sRole, iNum = 1, iPos1 = pos1, iPos2 = pos2 };
						iRoleCnt = 1;

						ChatFrame4:AddMessage("SLFG2DBG: Merged bi-spec role to " .. sRole .. ".");
					end
				end
			end
		end
	end

	-- TODO: collate multiple entries, replace with "§|ROLES|§"

	-- =================================== final parsing =================================

	if (sInternal) then
		ChatFrame4:AddMessage("SLFG2DBG: Matching against <" .. sMsgLow .. ">.");
	end


	local	bOk = false;
	local	oData = {};
	for i = 1, #oTable.Main do
		local	oMain = oTable.Main[i]; 
		args[1], args[2], args[3], args[4] = string.match(sMsgLow, oMain.s);
		if (args[1]) then
			if (sInternal) then
				ChatFrame4:AddMessage("SLFG2DBG: MatchA[" .. i .. "]: " .. oMain.s .. " => " .. stringfromtable(args));
			end
			bOk = true;

			local	x, k, v;
			for k, v in pairs(oMain) do
				x = nil;
				if (k ~= "s") then
					if (type(v) == "number") then
						if (v < 0) then
							x = - v;
						else
							x = args[v];
						end
					else
						oData[k] = v;
					end
				end

				if (x) then
					if (strsub(k, 1, 1) == "i") then
						x = tonumber(x);
					end
					oData[k] = x;
				end
			end
		end

		if (bOk) then
			break
		end
	end

	if (not bOk and oTable.MainPositional) then
		local	oPositions, iMainCnt, k, pos1, pos2 = {}, #oTable.MainPositional;
		for i = 1, iMainCnt do
			local	oMain = oTable.MainPositional[i]; 
			args[1], args[2], args[3], args[4] = string.match(sMsgLow, oMain.s);
			if (args[1] and sInternal) then
				ChatFrame4:AddMessage("SLFG2DBG: MatchB[" .. i .. "]: " .. oMain.s .. " => " .. stringfromtable(args));
			end
			if (args[oMain.iNumArgs]) then
				-- we need the positional offsets for the substrings
				for k = 1, oMain.iNumArgs do
					pos1, pos2 = string.find(sMsgLow, args[k], 1, true);
					if (pos1) then
						oPositions[k] = { iPos1 = pos1, iPos2 = pos2, sWhat = oMain["sArg" .. k] };
					else
						oPositions[k] = { iPos1 = pos1, iPos2 = pos2, sWhat = "Error: " .. args[k] };
					end
				end

				if (sInternal) then
					ChatFrame4:AddMessage("SLFG2DBG: ... Positions => " .. stringfromtable(oPositions));
				end

				-- now, check if roles/dungeons are in the specified ranges:
				bOk = true;
				for k = 1, oMain.iNumArgs do
					if (oPositions[k].sWhat == "Roles") then
						if (iRoleCnt == 0) then
							ChatFrame4:AddMessage("SLFG2DBG: Role required, none found.");
							bOk = false;
						else
							local	p1, p2, m = oPositions[k].iPos1, oPositions[k].iPos2;
							for m = 1, iRoleCnt do
								if ((oRoles[m].iPos1 < p1 - 1) or
								    (oRoles[m].iPos2 > p2 + 1)) then

									ChatFrame4:AddMessage("SLFG2DBG: Role outside perimeter - " .. stringfromtable(oRoles[m]) .. " vs. " .. p1 .. "->" .. p2);

									bOk = false;
									break;
								end
							end
						end
					elseif (oPositions[k].sWhat == "Dungeons") then
						local	iDungeonCnt = #oDungeons;
						if (iDungeonCnt < 2) then
							ChatFrame4:AddMessage("SLFG2DBG: Dungeon required, none found.");
							bOk = false;
						else
							local	p1, p2, m = oPositions[k].iPos1, oPositions[k].iPos2;
							for m = 2, iDungeonCnt do
								if ((oDungeons[m].iPos1 < p1 - 1) or
								    (oDungeons[m].iPos2 > p2 + 1)) then

									ChatFrame4:AddMessage("SLFG2DBG: Dungeon outside perimeter - " .. stringfromtable(oDungeons[m]) .. " vs. " .. p1 .. "->" .. p2);
									bOk = false;
									break;
								end
							end
						end
					else
						-- missing something?
						ChatFrame4:AddMessage("SLFG2DBG: Parsing failed. (" .. oPositions[k].sWhat .. ")");
						bOk = false;
					end

					if (not bOk) then
						break
					end
				end
			end

			if (bOk) then
				local	x, k, v;
				for k, v in pairs(oMain) do
					x = nil;
					if (k ~= "s") then
						if (type(v) == "number") then
							x = args[v];
						else
							oData[k] = v;
						end
					end

					if (x) then
						if (strsub(k, 1, 1) == "i") then
							x = tonumber(x);
						end
						oData[k] = x;
					end
				end

				break
			end
		end
	end

	iRoleCnt = #oRoles;
	if (not bOk and (iRoleCnt > 0) and (#oDungeons > 1)) then
		if (bChannelLFG) then
			-- point-blank allow LFG channel (neg. hits have hopefully been eliminated earlier...)
			bOk = true;
			oData.bLFG = true;
			oData.bLFM = true;
		else
			-- indirect inference: if at least 2 are wanted, it's LFM
			local	oRolesAccumulated = {};
			for i = 1, iRoleCnt do
				local	sKey = "i" .. oRoles[i].sRole;
				local	iVal = oRoles[i].iNum;
				if (oRolesAccumulated[sKey]) then
					if (oRolesAccumulated[sKey] < 0) then
						if (iVal < 0) then
							oRolesAccumulated[sKey] = math.min(iVal, oRolesAccumulated[sKey]);
						else
							oRolesAccumulated[sKey] = iVal;
						end
					else
						oRolesAccumulated[sKey] = math.max(iVal, oRolesAccumulated[sKey]);
					end
				else
					oRolesAccumulated[sKey] = iVal;
				end
			end

			local	iCurrent = math.abs(oData.iRoleAny or 0)
					+ math.abs(oData.iDPSHeal or 0) + math.abs(oData.iTankDPS or 0) + math.abs(oData.iTankHeal or 0)
					+ math.abs(oData.iDPS or 0) + math.abs(oData.iTank or 0) + math.abs(oData.iHeal or 0);

			if (iCurrent > 1) then
				-- if any sub parsed as "or", this might still be unclear
				local	bOr = false;
				if (oSubs) then
					for i = 1, #oSubs do
						local	k;
						for k = 1, #oTable.Inter do
							if ((oTable.Inter[k].l == 1) and string.find(oSubs[i], oTable.Inter[k])) then
								bOr = true;
								break
							end
						end

						if (bOr) then
							break
						end
					end
				end

				if (not bOr) then
					bOk = true;
					oData.bLFG = false;
					oData.bLFM = true;
				end
			end
		end
	end

	if (not bOk) then
		-- if (bChannelLFG) then
			ChatFrame4:AddMessage("SLFG2DBG: Failed to parse: " .. sMsgLow);
		-- end

		return
	end

	oData.sRaw1 = sMsgOrg;
	oData.sRaw2 = sMsgLow;
	oData.sChannel = sChannel;
	local	iPos = string.find(sChannel, " ");
	if (iPos) then
		oData.sChannel = strsub(sChannel, 1, iPos - 1);
	end

	-- temporary: add *all* role stuff found
	iRoleCnt = #oRoles;
	for i = 1, iRoleCnt do
		local	sKey = "i" .. oRoles[i].sRole;
		local	iVal = oRoles[i].iNum;
		if (oData[sKey]) then
			if (oData[sKey] < 0) then
				if (iVal < 0) then
					oData[sKey] = math.min(iVal, oData[sKey]);
				else
					oData[sKey] = iVal;
				end
			else
				oData[sKey] = math.max(iVal, oData[sKey]);
			end
		else
			oData[sKey] = iVal;
		end
	end

	local	sMsgDbg = "";

	if (not oData.bDefinite and not bLFG) then
		-- if we didn't find a role, skip altogether
		if ((#oRoles == 0) and (#oDungeons == 1)) then
			ChatFrame4:AddMessage("SLFG2DBG: No dungeon, no role, dropped: { " .. SaneLFGObj2.Helpers.stringfromtable(oData, true) .. " }");
			return
		end
	end

	-- if we got of anything more than one thing, it's LFM, no matter what we matched
	if (oData.iDPS and (oData.iDPS > 1) or oData.iTank and (oData.iTank > 1) or oData.iHeal and (oData.iHeal > 1)) then
		oData.bLFG = false;
		oData.bLFM = true;
	end

	-- if we got a total, and the sum doesn't suffice, add to DPS role until reached
	if (oData.iTotal) then
		local	iCurrent = math.abs(oData.iRoleAny or 0)
				+ math.abs(oData.iDPSHeal or 0) + math.abs(oData.iTankDPS or 0) + math.abs(oData.iTankHeal or 0)
				+ math.abs(oData.iDPS or 0) + math.abs(oData.iTank or 0) + math.abs(oData.iHeal or 0);
		if (iCurrent < oData.iTotal) then
			if (oData.iDPS) then
				oData.iDPS = - (math.abs(oData.iDPS or 0) + oData.iTotal - iCurrent);
			else
				-- if only one is set, set that to the value if it's negative
				local	iSet, sWhat = 0;
				if (oData.iTank) then
					iSet = iSet + 1;
					sWhat = "Tank";
				end
				if (oData.iHeal) then
					iSet = iSet + 1;
					sWhat = "Heal";
				end
				if (oData.iTankHeal) then
					iSet = iSet + 1;
					sWhat = "TankHeal";
				end
				if (oData.iTankDPS) then
					iSet = iSet + 1;
					sWhat = "TankDPS";
				end
				if (oData.iDPSHeal) then
					iSet = iSet + 1;
					sWhat = "DPSHeal";
				end
				if (oData.iRoleAny) then
					iSet = iSet + 1;
					sWhat = "RoleAny";
				end

				if (iSet == 1) then
					oData["i" .. sWhat] = - oData.iTotal;
				end
			end
		end
	end

	ChatFrame4:AddMessage("SLFG2DBG: Main+Sub parsed to { " .. SaneLFGObj2.Helpers.stringfromtable(oData, true) .. " }");

	if (#oDungeons > 1) then
		ChatFrame4:AddMessage("SLFG2DBG: Dungeons =>  " .. SaneLFGObj2.Helpers.stringfromlist(oDungeons));
	end

	local	iNow = time();
	local	oFrom = { sFrom = sFrom, sGUID = sGUID };
	local	_, sClassEN = GetPlayerInfoByGUID(oFrom.sGUID);
	if (sClassEN) then
		oFrom.sClassEN = sClassEN;
		if (oData.bLFG and not oData.bLFM and (#oRoles == 0)) then
			local	oClassToRoles = SaneLFGObj2.oClassToRoles[sClassEN];
			if (oClassToRoles[1] and not oClassToRoles[2] and not oClassToRoles[3]) then
				oData.iDPS = 1;
			end
		end
	end

	oData.oDungeons = oDungeons;

	do
		local	oExtra, k, v = {};
		for k, v in pairs(oTable.ExtraReq) do
			local	pos1, pos2 = string.find(sMsgLow, k);
			if (pos1) then
				if (string.find(k, "%%d")) then
					local	iWhich = string.match(sMsgLow, k);
					oExtra[#oExtra + 1] = { iPos1 = pos1, iPos2 = pos2, sReq = v .. iWhich };
				else
					oExtra[#oExtra + 1] = { iPos1 = pos1, iPos2 = pos2, sReq = v };
				end
			end
		end

		if (#oExtra > 0) then
			oExtra = SaneLFGObj2.Helpers.DuplicatesDrop("Extra", oExtra, "sReq", 1);
			if (#oExtra > 0) then
				ChatFrame4:AddMessage("SLFG2DBG: Extra req. => " .. SaneLFGObj2.Helpers.stringfromlist(oExtra));
				oData.oExtra = oExtra;
			end
		end
	end

	if (sInternal) then
		oFrom.sFrom = sInternal;
	else
		SaneLFGObj2.FactionRealm.ParsedChannel[sFrom] = { iAt = iNow, iUpdatedAt = iNow, oFrom = oFrom, oData = oData };

		-- only repeat definite data
		-- (TODO: check amount of extraneous data that might be relavant, like "ranged dps", "4k+ dps", "link [Onyxia 10]" etc.)
		if (oData.bLFG ~= oData.bLFM) then
			local	iCnt, iNext, iFound, i = #oRepeat, iNow + 30;
			for i = 1, iCnt do
				if (oRepeat[i].sFrom == sFrom) then
					iFound = i;
				else
					iNext = math.min(iNext, oRepeat[i].iAt);
				end
			end

			if (oRepeat[iFound]) then
				tremove(oRepeat, iFound);
			end

			-- for each mirror we add 3s of randomness
			tinsert(oRepeat, { sFrom =  sFrom, iAt = iNow + 10 + math.random(5 + 3 * #oMirrors), iTime = iNow });
			iNext = math.min(iNext, oRepeat[#oRepeat].iAt);

			if (SaneLFGObj2.Repeater) then
				SaneLFGObj2.Repeater = math.min(SaneLFGObj2.Repeater, iNext - iNow);
			else
				SaneLFGObj2.Repeater = iNext - iNow;
			end
		end
	end

	SaneLFGObj2.MainWndButtonSetup(oFrom, oData, iNow);
end

function	SaneLFGObj2.ParseMessageTest(sMessage, bLFGChannel)
	if (sMessage) then
		ChatFrame4:AddMessage("==== Inserting fake LFx entry ====");
		SaneLFGObj2.ParseMessageSpam(nil, UnitGUID("player"), sMessage, bLFGChannel == true, "Internal", "X: " .. time() % 3600);
		ChatFrame4:AddMessage("==== ------------------------ ====");

		return
	end

	-- take 10 random messages from history and drop it unto the algorithm
	local	Realm = GetCVar("realmName");
	local	oLines = ChannelLogGlobal[Realm][SaneLFGObj2.sLFGBase];

	local	iTotal = #oLines;
	local	iLine = math.random(iTotal);
	local	oData = oLines[iLine];

	if (oData) then
		ChatFrame4:AddMessage("==== Inserting fake LFx entry ====");
		SaneLFGObj2.ParseMessageSpam(nil, oData.sGUID, oData.sMsg, true, "Internal", "H: " .. iLine);
		ChatFrame4:AddMessage("==== ------------------------ ====");
	end
end

-- =================================== binary transfers =================================
-- =================================== binary transfers =================================
-- =================================== binary transfers =================================

-- own LFGs: current player
-- own LFGs: player alt
-- own LFM: current player, leader or not leader!

-- forwarded LFGx we saw in #LFG

-- so we need:
-- who is the official person looking
-- who is the person to communicate hidden with
-- what are they looking for
-- if LFM: what are the other group members

local	oRoleLongToShort = {
		["RoleAny"] = "X",

		["Tank"] = "T",
		["Heal"] = "H",
		["DPS"] = "D",

		["Melee"] = "M",
		["Ranged"] = "R",

		["TankHeal"] = "P",			-- pala
		["TankDPS"] = "W",			-- warrior
		["DPSHeal"] = "S",			-- shaman
	};

local	oRoleShortToLong = {
		["X"] = "RoleAny",

		["T"] = "Tank",
		["H"] = "Heal",
		["D"] = "DPS",

		["M"] = "Melee",
		["R"] = "Ranged",

		["P"] = "TankHeal",			-- pala
		["W"] = "TankDPS",			-- warrior
		["S"] = "DPSHeal",			-- shaman
	};

function	SaneLFGObj2.SendBinaryLFGMessageFromSelfOrAlt(sFor)
	if (oState.ChannelNr == nil) then
		return
	end

	local	LFGPerRealm = SaneLFGObj2.FactionRealm.LFGPerChar;
	local	oInfo = LFGPerRealm[sFor];
	if ((oInfo.oRoles == nil) or (#oInfo.oRoles == 0)) then
		return
	end
	if ((oInfo.oLFG == nil) or (#oInfo.oLFG == 0)) then
		return
	end

	-- 00: version, subversion

	-- these are LFG messages
	-- G: LFG; D: direct, I: indirect, F: forwarded
	local	sDirect;
	if (sFor == SaneLFGObj2.WhoAmI) then
		sDirect = "D";
	else
		sDirect = "I" .. sFor .. "!" .. oInfo.sClassEN .. "!" .. strsub(oInfo.sGUID, -6);
	end

	-- roles: currently supporting the standard roles, plus melee/ranged flag
	local	sRoles, k, v = "";
	for k, v in pairs(oInfo.oRoles) do
		local	sSub = strsub(k, 2);
		local	sRole = oRoleLongToShort[sSub];
		if (sRole) then
			sRoles = sRoles .. "!" .. sRole;
		end
	end
	if (sRoles == "") then
		ChatFrame4:AddMessage("SLFG2DBG: No role for " .. sFor .. "??");
		return
	end
	sRoles = strsub(sRoles, 2);

	-- dungeons: we need to map this to something shorter, for now: N/H + dungeon or simply the raid instance
	-- => longer string plus § separators
	local	sDungeons = "";
	for k, v in pairs(oInfo.oLFG) do
		if (v.iDifficulty % 100 == 10) then
			sDungeons = sDungeons .. "!N+" .. v.sDungeon;
		elseif (v.iDifficulty % 100 == 20) then
			sDungeons = sDungeons .. "!H+" .. v.sDungeon;
		else
			sDungeons = sDungeons .. "!R+" .. v.sDungeon;
		end
	end
	if (strlen(sDungeons) < 4) then
		return
	end
	sDungeons = strsub(sDungeons, 2);

	local	sMessage = string.format("$!00:G%s:%s:%s", sDirect, sRoles, sDungeons);
	ChatThrottleLib:SendChatMessage("BULK", "SaneLFG2", sMessage, "CHANNEL", nil, oState.ChannelNr);
end

function	SaneLFGObj2.RepeatLFxMessageAsBinary(sFrom, iTime)
	if (oState.ChannelNr == nil) then
		return
	end

	local	oTotal = SaneLFGObj2.FactionRealm.ParsedChannel[sFrom];
	if (oTotal == nil) then
		return
	end

	local	oFrom = oTotal.oFrom;
	local	oData = oTotal.oData;

	local	iCurrent = math.abs(oData.iRoleAny or 0)
			+ math.abs(oData.iDPSHeal or 0) + math.abs(oData.iTankDPS or 0) + math.abs(oData.iTankHeal or 0)
			+ math.abs(oData.iDPS or 0) + math.abs(oData.iTank or 0) + math.abs(oData.iHeal or 0);
	if (iCurrent == 0) then
		ChatFrame4:AddMessage("SLFG2DBG: No role from " .. sFrom .. ". (1)");
		return
	end

	if ((oData.oDungeons == nil) or (#oData.oDungeons <= 1)) then
		ChatFrame4:AddMessage("SLFG2DBG: No dungeon from " .. sFrom .. ".");
		return
	end

	-- G: LFG/M: LFM; F: forwarded
	local	sTypeForwarded = "F" .. (time() - oTotal.iUpdatedAt) .. "!" .. sFrom .. "!" .. strsub(oFrom.sClassEN, 1, 6) .. "!" .. strsub(oFrom.sGUID, -6);
	if (oData.bLFG and not oData.bLFM) then
		sTypeForwarded = "G" .. sTypeForwarded;
	elseif (not oData.bLFG and oData.bLFM) then
		sTypeForwarded = "M" .. sTypeForwarded;
	else
		ChatFrame4:AddMessage("SLFG2DBG: Unclear parse for message from " .. sFrom .. ".");
		return
	end

	-- roles: currently supporting the standard roles, plus melee/ranged flags
	-- we need numbers and roles here
	-- roles are characters, numbers are... numbers :D
	local	sRoles, k, v = "";
	for k, v in pairs(oRoleShortToLong) do
		local	iCount = oData["i" .. v];
		if (iCount) then
			sRoles = sRoles .. "!" .. k .. iCount;
		end
	end

	if (sRoles == "") then
		ChatFrame4:AddMessage("SLFG2DBG: No role from " .. sFrom .. ". (2)");
		return
	end
	sRoles = strsub(sRoles, 2);

	-- dungeons: we need to map this to something shorter, for now: N/H + dungeon or simply the raid instance
	-- => longer string
	-- if the type is unique, we flag all with it, otherwise we have to X/Y :(

	local	sType = "X";
	if     (    oData.oDungeons[1].bNormal and not oData.oDungeons[1].bHeroic and not oData.oDungeons[1].bRaid) then
		sType = "N";
	elseif (not oData.oDungeons[1].bNormal and     oData.oDungeons[1].bHeroic and not oData.oDungeons[1].bRaid) then
		sType = "H";
	elseif (not oData.oDungeons[1].bNormal and not oData.oDungeons[1].bHeroic and     oData.oDungeons[1].bRaid) then
		sType = "R";
	end

	local	sDungeons, iCnt, i, oValue = "", #oData.oDungeons;
	for i = 2, iCnt do
		oValue = oData.oDungeons[i];
		if (oData.oDungeons[i].bNegative) then
			sDungeons = sDungeons .. "!" .. sType .. "-" .. oValue.sName;
		else
			sDungeons = sDungeons .. "!" .. sType .. "+" .. oValue.sName;
		end
	end
	if (strlen(sDungeons) < 4) then
		ChatFrame4:AddMessage("SLFG2DBG: No dungeon(s) from " .. sFrom .. ".");
		return
	end
	sDungeons = strsub(sDungeons, 2);

	-- 00: version, subversion
	local	sMessage = string.format("$!00:%s:%s:%s", sTypeForwarded, sRoles, sDungeons);
	ChatThrottleLib:SendChatMessage("BULK", "SaneLFG2", sMessage, "CHANNEL", nil, oState.ChannelNr);
end

function	SaneLFGObj2.RepeatDo()
	local	iNow = time();
	if (#oRepeat > 0) then
		if (iNow >= oRepeat[1].iAt) then
			local	sFrom = oRepeat[1].sFrom;
			local	iTime = oRepeat[1].iTime;
			tremove(oRepeat, 1);
			SaneLFGObj2.RepeatLFxMessageAsBinary(sFrom, iTime);
		end
	end

	if (#oRepeat > 0) then
		SaneLFGObj2.Repeater = oRepeat[1].iAt - iNow;
		if (SaneLFGObj2.Repeater < 0) then
			SaneLFGObj2.Repeater = 1;
		end
	end

	ChatFrame4:AddMessage("SLFG2DBG: RepeatDo() - next of " .. (#oRepeat) .. " in " .. (SaneLFGObj2.Repeater or "<never>"));
end

function	SaneLFGObj2.RepeatDump()
	local	s, k, v = "";
	for k, v in pairs(oRepeat) do
		s = s .. ", [" .. k .. "] = <" .. v.iAt .. ">";
	end

	ChatFrame4:AddMessage("SLFG2DBG: RepeatDump(): time() = " .. time() .. ", oRepeat => " .. strsub(s, 3));
end

function	SaneLFGObj2.ParseMessagePacked(sFrom, sGUID, sMessage)
	local	sVersion, sMore = string.match(sMessage, "^$!(%d+):(.+)");
	if (sVersion == nil) then
		ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(oTotal) => Version failed.");
		return
	end

	if (sVersion ~= "00") then
		ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(oTotal) => Version incompatible.");
		return
	end

	local	sKindBasic = strsub(sMore, 1, 1);
	if (sKindBasic == "C") then
		-- mirror announcement
		local	iCnt, iFound, i = #oMirrors;
		for i = 1, iCnt do
			if (oMirrors[i] == sFrom) then
				iFound = i;
				break
			end
		end

		if (strsub(sMore, 2, 2) == "+") then
			if (not iFound) then
				tinsert(oMirrors, sFrom);
			end
		else
			if (iFound) then
				tremove(oMirrors, iFound);
			end
		end

		ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(MirrorMessage) => ok.");
		return
	end

	local	sKind, sRoles, sDungeons = string.match(sMessage, "^$!%d+:([^:]+):([^:]+):(.+)$");
	if (sKind == nil) then
		ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(oTotal) => Utterly failed to parse format.");
		return
	end

	local	sKindBasic = strsub(sKind, 1, 1);

	if (sKindBasic == "X") then
		-- X - closing the group (can only be a direct message)
		-- X directly followed by name of player plus all members
		-- TODO
		ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(GroupDone) => TODO.");
		return
	end

	if (sKindBasic == "U") then
		-- TODO: update, still LFx (every Y minutes)
		ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(UpdateTimer) => TODO.");
		return
	end

	if (sKindBasic == "P") then
		-- TODO: party/raid change, list member changes
		-- try both variants, delta and current, see which is longer, post that
		ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(PartyUpdate) => TODO.");
		return
	end

	if ((sKindBasic ~= "G") and (sKindBasic ~= "M")) then
		ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(BasicType) => Failed.");
		return
	end

	local	oFrom = {};

	-- if indirect, we also expect the class and the end of the GUID
	local	sDirect = strsub(sKind, 2, 2);
	local	sKindInfo = strsub(sKind, 3);
	if (sDirect == "D") then
		oFrom.sFrom = sFrom;
		oFrom.sGUID = sGUID;
		local	_, sClassEN = GetPlayerInfoByGUID(sGUID);
		if (sClassEN) then
			oFrom.sClassEN = sClassEN;
		end
	elseif (sDirect == "I") then
		local	sName, sClass, sGUIDFrag = string.match(sKindInfo, "([^!]+)!([^!]+)!([^!]+)");
		if (sName) then
			oFrom.sFrom = sName;
			oFrom.sClassEN = sClass;
			oFrom.sGUIDPartial = sGUIDFrag;

			oFrom.sViaName = sFrom;
			oFrom.sViaGUID = sGUID;
		end
	elseif (sDirect == "F") then
		local	sDelay, sName, sClass, sGUIDFrag = string.match(sKindInfo, "([^!]+)!([^!]+)!([^!]+)!([^!]+)");
		if (sGUIDFrag) then
			oFrom.iAt = time() - tonumber(sDelay);
			oFrom.sFrom = sName;
			oFrom.sClassEN = sClass;
			oFrom.sGUIDPartial = sGUIDFrag;

			oFrom.sForwarderName = sFrom;
			oFrom.sForwarderGUID = sGUID;

			local	oParsed = SaneLFGObj2.FactionRealm.ParsedChannel[sName];
			if (oParsed) then
				if (oParsed.iUpdatedAt + 45 >= time()) then
					local	iCnt, iFound, i = #oRepeat;
					for i = 1, iCnt do
						if (oRepeat[i].sFrom == sFrom) then
							iFound = i;
							break
						end
					end
					if (iFound) then
						tremove(oRepeat, iFound);
					end

					-- TODO: on release, ignore forwarded duplicate
					-- return
				end
			end
		end
	end

	if ((oFrom.sFrom == nil) or (oFrom.sGUID == nil) and (oFrom.sGUIDPartial == nil)) then
		ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(oFrom) => Insufficient information ~ " .. stringfromtable(oFrom));
		return
	end

	ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(oFrom) => " .. stringfromtable(oFrom));

	local	oData = {};
	if (sKindBasic == "G") then
		oData.bLFG = true;
		oData.bLFM = false;
	else
		oData.bLFG = false;
		oData.bLFM = true;
	end

	-- sRoles: can-do roles / required roles
	-- LFG: roleA ! roleB ! roleC
	-- LFM: roleA # ! roleB # ! roleC #
	sRoles = sRoles .. "!";	-- terminate
	local	sSub;
	for sSub in string.gmatch(sRoles, "([^!]+)!") do
		local	sRole = strsub(sSub, 1, 1);
		local	sCount = strsub(sSub, 2);
		local	iCount = 1;
		if (sCount ~= "") then
			iCount = tonumber(sCount);
		end

		local	sKey = oRoleShortToLong[sRole];
		if (sKey) then
			oData["i" .. sKey] = iCount;
		end
	end

	ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(oData) => " .. stringfromtable(oData));

	-- sDungeons: (list of) dungeon(s) + difficulty
	local	oDungeons = { [1] = { bNormal = false, bHeroic = false, bRaid = false } };
	sDungeons = sDungeons .. "!";	-- terminate
	for sSub in string.gmatch(sDungeons, "([^!]+)!") do
		local	sDiff = strsub(sSub, 1, 1);
		local	bNegative = strsub(sSub, 2, 2) == "-";
		local	sName = strsub(sSub, 3);
		oDungeons[#oDungeons + 1] = { sName = sName, bNegative = bNegative };
		if (sDiff ~= "X") then
			if (sDiff == "N") then
				oDungeons[1].bNormal = true;
			elseif (sDiff == "H") then
				oDungeons[1].bHeroic = true;
			elseif (sDiff == "R") then
				oDungeons[1].bRaid = true;
			end
		end
	end

	ChatFrame4:AddMessage("SLFG2DBG: ParseBinary(oDungeons) => " .. stringfromtable(oDungeons));
end

function	SaneLFGObj2.PostGroupChange()
	-- careful: should be delayed if other group members do that as well
end

function	SaneLFGObj2.PostDungeonChange()
	-- careful: should be delayed if other group members do that as well
end

function	SaneLFGObj2.PostGroupDone()
	-- careful: should be delayed if other group members do that as well
end

