
-- global object

SaneLFGObj2 = { State = {}, Init = {}, Helpers = {}, Maps = { NameToContact = {}, CommData = {} } };

-- unfortunately local in LFGFrame.lua
local	ROLE_DISABLED = false;
local	ROLE_ENABLED  = true;

SaneLFGObj2.oClassToRoles = {
--	CLASS = { DPS, TANK, HEALER },
	DRUID 		= {	ROLE_ENABLED,	ROLE_ENABLED,	ROLE_ENABLED,	},
	PALADIN 	= {	ROLE_ENABLED,	ROLE_ENABLED,	ROLE_ENABLED,	},
	ROGUE 		= {	ROLE_ENABLED,	ROLE_DISABLED,	ROLE_DISABLED,	},
	PRIEST 		= {	ROLE_ENABLED,	ROLE_DISABLED,	ROLE_ENABLED,	},
	WARRIOR 	= {	ROLE_ENABLED,	ROLE_ENABLED,	ROLE_DISABLED,	},
	HUNTER 		= {	ROLE_ENABLED,	ROLE_DISABLED,	ROLE_DISABLED,	},
	MAGE 		= {	ROLE_ENABLED,	ROLE_DISABLED,	ROLE_DISABLED,	},
	WARLOCK 	= {	ROLE_ENABLED,	ROLE_DISABLED,	ROLE_DISABLED,	},
	SHAMAN		= {	ROLE_ENABLED,	ROLE_DISABLED,	ROLE_ENABLED,	},
	DEATHKNIGHT	= {	ROLE_ENABLED,	ROLE_ENABLED,	ROLE_DISABLED,	},
};

SaneLFGObj2.Helpers.stringfromtable = function(oTable, bNoRecurse)
	local	s, k, v = "";
	for k, v in pairs(oTable) do
		if (not bNoRecurse and (type(v) == "table"))  then
			s = s .. ", [" .. k .. "] = < table : { " .. SaneLFGObj2.Helpers.stringfromtable(v) .. " } >";
		else
			s = s .. ", [" .. k .. "] = <" .. tostring(v) .. ">";
		end
	end

	return strsub(s, 3);
end

SaneLFGObj2.Helpers.stringfromlist = function(oTable)
	local	s = "";
	local	iCnt, i = #oTable;
	for i = 1, iCnt do
		s = s .. ", " .. tostring(oTable[i]);
	end

	return strsub(s, 3);
end

SaneLFGObj2.Helpers.DuplicatesDrop = function(sTableName, oTable, sKey, iStart)
	if (iStart == nil) then
		iStart = 1;
	end

	local	iCnt, i, k = #oTable;
	local	oDuplicates = {};
	for i = iStart, iCnt - 1 do
		local	oA = oTable[i];
		for k = i + 1, iCnt do
			local	oB = oTable[k];
			if (oA[sKey] == oB[sKey]) then
				local	iDrop;
				if (oA.iPos1 < oB.iPos1) then
					if (oA.iPos2 >= oB.iPos2) then
						iDrop = k;
						tinsert(oDuplicates, k);
					end
				elseif (oA.iPos1 > oB.iPos1) then
					if (oA.iPos2 <= oB.iPos2) then
						iDrop = i;
						tinsert(oDuplicates, i);
					end
				else
					if (oA.iPos2 >= oB.iPos2) then
						iDrop = k;
						tinsert(oDuplicates, k);
					elseif (oA.iPos2 < oB.iPos2) then
						iDrop = i;
						tinsert(oDuplicates, i);
					end
				end

				if (iDrop) then
					local	s1, m, v = "";
					for m, v in pairs(oTable[i]) do
						s1 = s1 .. ", [" .. m .. "] = <" .. v .. ">";
					end
					local	s2 = "";
					for m, v in pairs(oTable[k]) do
						s2 = s2 .. ", [" .. m .. "] = <" .. v .. ">";
					end

					if (iDrop == i) then
						ChatFrame4:AddMessage("SLFG2DBG: Dropping [" .. i .. "] " .. strsub(s1, 3) .. " in favor of [" .. k .. "] " .. strsub(s2, 3));
					else
						ChatFrame4:AddMessage("SLFG2DBG: Dropping [" .. k .. "] " .. strsub(s2, 3) .. " in favor of [" .. i .. "] " .. strsub(s1, 3));
					end
				end
			end
		end
	end

	if (next(oDuplicates)) then
		local	iDupeCnt = #oDuplicates;
		for i = 1, iDupeCnt do
			oTable[oDuplicates[i]] = nil;
		end

		local	iDropped = 0;

		local	oTableNew = {};
		for i = 1, iCnt do
			if (oTable[i]) then
				oTableNew[#oTableNew + 1] = oTable[i];
				oTable[i] = nil;
			else
				iDropped = iDropped + 1;
			end
		end

		oTable = oTableNew;
		ChatFrame4:AddMessage("SLFG2DBG: ~" .. sTableName .. "~ dropped " .. iDropped .. " overmatched entries, going from " .. iCnt .. " to " .. #oTable .. " entries.");
	end

	return oTable;
end

