
KARMATRANS_AVAILABLE = 0;

function	KarmaTrans_OnLoad()
	this:RegisterEvent("VARIABLES_LOADED");
end

function	KarmaTrans_OnEvent(event)
	if (event == "VARIABLES_LOADED") then
		if (KarmaImp == nil) then
			KarmaImp = {};
		end
		if (KarmaExp == nil) then
			KarmaExp = {};
		end
		if (KarmaForeign == nil) then
			KarmaForeign = {};
		end

		KARMATRANS_AVAILABLE = 1;
	end
end

function	KarmaTrans_OnUpdate(arg1)
end

function	KarmaTrans_Changelog(sAction, sStateFrom, sStateTo)
	local	entry = {};
	entry.at = time();
	entry.ac = sAction;
	entry.s1 = sStateFrom;
	entry.s2 = sStateTo;
	
	if KarmaChangelog == nil then
		KarmaChangelog = {};
	end
	
	tinsert(KarmaChangelog, entry);
end

function	KarmaTrans_ForeignKarmaEntry(sServer, sFaction, sFrom, sForBucket, sForName, iKarma, iPlayed, iLevel, iClass, sRace, sGUID, sNote)
	if (KarmaForeign[sServer .. "#" .. sFaction] == nil) then
		KarmaForeign[sServer .. "#" .. sFaction] = {};
		KarmaForeign[sServer .. "#" .. sFaction].created = time();
	end

	local	oServerFaction = KarmaForeign[sServer .. "#" .. sFaction];
	if (oServerFaction[sFrom] == nil) then
		oServerFaction[sFrom] = {};
		oServerFaction[sFrom].created = time();
	end

	local	oFrom = oServerFaction[sFrom];
	if (oFrom[sForBucket] == nil) then
		oFrom[sForBucket] = {};
	end
	if (oFrom[sForBucket][sForName] == nil) then
		oFrom[sForBucket][sForName] = {};
		oFrom[sForBucket][sForName].created = time();
	end

	oFrom[sForBucket][sForName].at = time();
	oFrom[sForBucket][sForName].Karma = iKarma;
	oFrom[sForBucket][sForName].Level = iLevel;
	oFrom[sForBucket][sForName].Class = iClass;
	oFrom[sForBucket][sForName].Race = sRace;
	oFrom[sForBucket][sForName].Played = iPlayed;
	oFrom[sForBucket][sForName].GUID = sGUID;
	oFrom[sForBucket][sForName].Public = sNote;
end

function	KarmaTrans_ForeignKarmaContinueWithSet(sServer, sFaction, sFrom, sValue)
	if (KarmaForeign[sServer .. "#" .. sFaction] == nil) then
		KarmaForeign[sServer .. "#" .. sFaction] = {};
		KarmaForeign[sServer .. "#" .. sFaction].created = time();
	end

	local	oServerFaction = KarmaForeign[sServer .. "#" .. sFaction];
	if (oServerFaction[sFrom] == nil) then
		oServerFaction[sFrom] = {};
		oServerFaction[sFrom].created = time();
	end

	oServerFaction[sFrom].ContinueWith = sValue;
end

function	KarmaTrans_ForeignKarmaContinueWithGet(sServer, sFaction, sFrom)
	if (KarmaForeign[sServer .. "#" .. sFaction] == nil) then
		KarmaForeign[sServer .. "#" .. sFaction] = {};
		KarmaForeign[sServer .. "#" .. sFaction].created = time();
	end

	local	oServerFaction = KarmaForeign[sServer .. "#" .. sFaction];
	if (oServerFaction[sFrom] == nil) then
		return nil;
	else
		return oServerFaction[sFrom].ContinueWith;
	end
end

local	_sRegion, _sZone;

function	KarmaTrans_LogRegionZone(iRegionID, sRegion, iZoneID, sZone, iZoneType)
	if (sRegion ~= _sRegion) or (sZone ~= _sZone) then
		local	entry = {};
		entry.at = time();
		entry.ac = "RegionZoneChange";

		entry.iR = iRegionID;
		entry.sR = sRegion;
		if (sRegion == nil) then
			entry.sR = "*";
		end

		entry.iZ = iZoneID;
		entry.sZ = sZone;
		if (sZone == nil) then
			entry.sZ = "+";
		end

		entry.iT = iZoneType;
		if (iZoneType == nil) then
			entry.sZ = "-";
		end
		
		if KarmaRegionZoneLog == nil then
			KarmaRegionZoneLog = {};
		end
		
		tinsert(KarmaRegionZoneLog, entry);
	end
end
