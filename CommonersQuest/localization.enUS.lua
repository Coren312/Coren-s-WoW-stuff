
-- these are display-only strings, so it's ok to have them not yet translated
CQKEP_TEXT_SOLVE = "Solve riddle";

CommonersQuest.Strings.Class.Male.DEATHKNIGHT = "Death Knight";
CommonersQuest.Strings.Class.Male.DRUID = "Druid";
CommonersQuest.Strings.Class.Male.HUNTER = "Hunter";
CommonersQuest.Strings.Class.Male.MAGE = "Mage";
CommonersQuest.Strings.Class.Male.PALADIN = "Paladin";
CommonersQuest.Strings.Class.Male.PRIEST = "Priest";
CommonersQuest.Strings.Class.Male.ROGUE = "Rogue";
CommonersQuest.Strings.Class.Male.SHAMAN = "Shaman";
CommonersQuest.Strings.Class.Male.WARRIOR = "Warrior";
CommonersQuest.Strings.Class.Male.WARLOCK = "Warlock";

CommonersQuest.Strings.Race.Alliance.Male.DRAENEI = "Draenei";
CommonersQuest.Strings.Race.Alliance.Male.DWARF = "Dwarf";
CommonersQuest.Strings.Race.Alliance.Male.GNOME = "Gnome";
CommonersQuest.Strings.Race.Alliance.Male.HUMAN = "Human";
CommonersQuest.Strings.Race.Alliance.Male.NIGHTELF = "Night Elf";

CommonersQuest.Strings.Race.Horde.Male.BLOODELF = "Blood Elf";
CommonersQuest.Strings.Race.Horde.Male.ORC = "Orc";
CommonersQuest.Strings.Race.Horde.Male.TAUREN = "Tauren";
CommonersQuest.Strings.Race.Horde.Male.TROLL = "Troll";
CommonersQuest.Strings.Race.Horde.Male.UNDEAD = "Undead";

CommonersQuest.Strings.Duel = {
		Inside = {
			Alliance = { Name = "Ironforge", x = 0.469012648, y = 0.59349728 },
			Horde =    { Name = "Orgrimmar", x = 0.522740901, y = 0.77795029 }
		},
		Outside = {
			Alliance = { Name = "Dun Morogh", x = 0.46522409, y = 0.59821169 },
			Horde =    { Name = "Durotar",    x = 0.46012002, y = 0.14119282 }
		}
	};

-- actually, there is no enGB...
if (GetLocale() == "enUS") or (GetLocale() == "enGB") then
	CommonersQuest.Strings.Item.Questitem = "Quest Item";
	CommonersQuest.Strings.Item.Soulbound = "Soulbound";
	CommonersQuest.Strings.Item.BoundOnPickup = "Binds when picked up";
--	CommonersQuest.Strings.Item.BoundOnEquip = "Binds when equipped";
--	CommonersQuest.Strings.Item.BoundToAccount = "Binds to account";

	CommonersQuestLang.Emotes["apologize"] = "You apologize to %s.  Sorry!";
	CommonersQuestLang.Emotes["awe"] = "You stare at %s in awe.";
	CommonersQuestLang.Emotes["cheer"] = "You cheer at %s.";
	CommonersQuestLang.Emotes["dance"] = "You dance with %s.";
	CommonersQuestLang.Emotes["flirt"] = "You flirt with %s.";
	CommonersQuestLang.Emotes["hug"] = "You hug %s.";
	CommonersQuestLang.Emotes["kiss"] = "You blow a kiss to %s.";
	CommonersQuestLang.Emotes["kneel"] = "You kneel before %s.";
	CommonersQuestLang.Emotes["massage"] = "You massage %s's shoulders."
	CommonersQuestLang.Emotes["rude"] = "You make a rude gesture at %s.";
	CommonersQuestLang.Emotes["snarl"] = "You bare your teeth and snarl at %s.";
end

