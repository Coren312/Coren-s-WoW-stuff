if (GetLocale() == "deDE") then
	KARMA_INITIAL_MESSAGE = " geladen. /karma gibt eine Kurzhilfe der Befehle.";
	KARMA_MYADDONS_HELP = {
		"Aufruf: /karma\n\195\150ffnet das " .. KARMA_ITSELF .. "-Fenster. Es kann auch eine Taste mit dem Befehl belegt werden.",
	};
	
	KARMA_CMDLINE_CMDUNKNOWN_PRE = "Befehl >";
	KARMA_CMDLINE_CMDUNKNOWN_POST = "< nicht gefunden.";

	KARMA_CMDLINE_HELP_COLOR1 = "cFF7F8FAF";
	KARMA_CMDLINE_HELP_COLOR2 = "cFF8FAFFF";

	KARMA_CMDLINE_HELP_SHORT = {
		KARMA_ITSELF .. " *** Kurzhilfe|r",
		"Aufruf: '" .. KARMA_CMDSELF .. " <Befehl> [<Argument1>] ...'|" .. KARMA_CMDLINE_HELP_COLOR2 .. "(/kar kann statt " .. KARMA_CMDSELF .. " benutzt werden). Bsp.: '" .. KARMA_CMDSELF .. " window '|r",
		"Oft benutzte Befehle:|r",
		"   help [all|quick|alts|lfm|options|db|exchange] |" .. KARMA_CMDLINE_HELP_COLOR2 .. "('all' liefert eine ziemlich vollst\195\164ndige Hilfe der Befehle, 'quick' listet nur die Befehle, alles andere sind seltene Befehle (erreichbar über das 'normale' UI oder man braucht sie einfach selten)|r",
		"   resetgui |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(setzt die Positionen von Minimap-Icon, Hauptfenster und Suche-Fenster zur\195\188ck)|r",
		"   window (oder win) |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(\195\182ffnet das " .. KARMA_ITSELF .. " Hauptfenster)|r",
		"   options (oder opt) |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(\195\182ffnet das Optionen - Fenster)|r",
		"   showonline |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(\195\182ffnet das " .. KARMA_ITSELF .. " Suche-fenster)|r",
		"   addmember <name> (oder add) |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(f\195\188gt <name> hinzu)|r",
		"   ignore <name> (oder ign) |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(f\195\188gt <name> hinzu und ignoriert ihn/sie durch Setzen seines/ihres " .. KARMA_ITSELF .. "s auf 1)|r",
		"   update <name> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(versucht die Informationen \195\188ber <name> zu aktualisieren, oder \195\188ber das aktuelle Ziel falls <name> fehlt)|r",
		"   remove <name> (oder rem) |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(entfernt <name>)|r",
		"   give <name> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(gibt <name> " .. KARMA_ITSELF .. ")|r",
		"   take <name> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(nimmt <name> " .. KARMA_ITSELF .. " weg)|r",
	};

	KARMA_CMDLINE_HELP_LFM = {
		"Befehle mit Bezug zum \"Suche...\"-Fenster:|r",
		"   checkchannel <channel> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(versucht zu pr\195\188fen, welche " .. KARMA_ITSELF .. " bekannten Spieler/-innen im Kanal <channel> zu finden sind)|r",
		"   checkclass <class> <level> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(versucht zu pr\195\188fen, welche " .. KARMA_ITSELF .. " bekannten Spieler/-innen der Klasse <class> online sind; <level> kann weggelassen werden)|r",
		"   checkallclasses <level> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(versucht zu pr\195\188fen, welche " .. KARMA_ITSELF .. " bekannten Spieler/-innen *jeder* Klasse online sind; <level> kann weggelassen werden)|r",
		"   checkguild <guildname> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(versucht zu pr\195\188fen, welche " .. KARMA_ITSELF .. " bekannten Spieler/-innen aus der Gilde <guildname> online sind, <guildname> kann auch nur ein Fragment sein)|r",
		};

	KARMA_CMDLINE_HELP_OPTIONS = {
		"Befehle mit einem Gegenstück im Optionsfenster:|r",
		"   sortby <[name||played||exp||time]> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(Namenslisten sortieren nach <...>)|r",
		"   colorby <[played||exp||time]> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(Namenslisten einf\195\164rben entsprechend <...>)|r",
		"   karmatips |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(\195\164ndert die Anzeige der " .. KARMA_ITSELF .. " Wertung im Tooltip)|r",
		"   notetips |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(\195\164ndert die Anzeige der Notiz von " .. KARMA_ITSELF .. " im Tooltip)|r",
		"   qcachewarn |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(\195\164ndert die Anzeige der Warnung, da\195\159 " .. KARMA_ITSELF .. " nur einen Teil der Quests sehen kann)|r",
		"   autoignore <[on||off]> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(automatisches Ignorieren an/aus)|r",
		"   autochecktalents |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(aktiviert/deaktiviert das automatische Auslesen der Talente in Gruppen)|r",
		};

	KARMA_CMDLINE_HELP_ALTS = {
		"Befehle zu 'Alts' (Zweitcharakter):|r",
		"   altadd <player1> <player2> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(<player1> und <player2> werden markiert als gleiche Person)|r",
		"   altrem <player> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(<player>s Verbindung aus altadd wird wieder gel\195\182scht)|r",
		"   altlist <player> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(listet die anderen Charaktere zu <player>)|r",
		};

	KARMA_CMDLINE_HELP_DB = {
		"Befehle mit Bezug auf " .. KARMA_ITSELF .. "s interne Datenbasis:|r",
		"   clean |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(entfernt Eintr\195\164ge nach verschiedenen Regeln)|r",
		"   cleanpvp |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(entfernt Eintr\195\164ge von Spielern fremder Server)|r",
		"   veryclean |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(\195\164hnlich wie clean, aber entfernt ALLE Eintr\195\164ge von anderen Servern (PVP-Eintr\195\164ge)|r",
		"   questcache <[-1||0||eine Questnummer]> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(zeigt die " .. KARMA_ITSELF .. " bekannten Questdaten an, -1: vollst\195\164ndige Liste, mit Questnummer (= Zeile im Questlog-Fenster) wird nur diese angezeigt)|r",
		"   skillmodel <[complex||simple]> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(wechselt zwischen (Standard:) einfachem (simple) und komplexem (complex) F\195\164higkeitsmodell)|r",
		};

	KARMA_CMDLINE_HELP_EXCHANGE = {
		"Befehle zum Datenaustausch mit einem anderen, vertrauenswürdigen Spieler:|r",
		"   |cFFFF4010Dieser Vorgang sollte nicht zugelassen oder gestartet werden im regulären Spielverlauf, da es die Gefahr birgt, daß eines von beiden vom Server geworfen wird. Idealerweise sollte man sich zum Austausch in einer populationsarmen Umgebung (NICHT Dalaran) dem süßen Nichtstun hingeben.|r",
		"   |" .. KARMA_CMDLINE_HELP_COLOR2 .. "Zum Speichern der Daten muß beim Empfänger das Zusatzaddon KarmaTrans aktiv sein.|r",
		"   exchangeallow [<name>] |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(erlaubt 'name', interessante Teile aus deiner " .. KARMA_ITSELF .. " Datenbank abzufragen: Informationen, die auch durch ein /who erlangt würden; sowie GUID(eindeutige Charakterkennung auf dem Server), " .. KARMA_ITSELF .. " Wertung und öffentliche Notizen)|r",
		"   exchangerequest <name> [<start>] |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(bittet 'name' darum, den Datentransfer zu beginnen, wahlweise kann auch mit dem Eintrag <start> begonnen werden; die andere Person muß dies VOHER erlaubt haben mit einem 'exchangeallow'!)|r",
		"   exchangetrust <name> <trust value> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(legt einen 'Vertrauen'sfaktor (0.01 .. 1.0) für 'name' fest, der aussagt, wie sehr DU dem Urteilsvermögen des Spielers/der Spielerin vertraust in Bezug auf seine/ihre " .. KARMA_ITSELF .. " Werte)|r",
		"   exchangeupdate |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(dies aktualisiert letzendlich die Datenbank mit allen verfügbaren Informationen)|r",
		"   |" .. KARMA_CMDLINE_HELP_COLOR2 .. "Vollständige Prozedur für einen Austausch A -> B: A exchangeallow B, B exchangerequest A, (geduldig auf den Abschluß des Transfers warten), B exchangetrust A <trust>, B exchangeupdate|r",
		"Befehle, die manuelle Eingriffe brauchen, um von Nutzen zu sein:|r",
		"   export <[*||<name>]> |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(exportiert <name> oder alle Daten der aktuellen Server-Fraktion)|r",
		"   import |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(importiert vorhandene Daten)|r",
		"   transport |" .. KARMA_CMDLINE_HELP_COLOR2 .. "(l\195\182scht die Import -/Export - Daten)|r",
	};

	KARMA_UNKNOWN =	"Unbekannt";
	KARMA_UNKNOWN_ENT =	"Unbekannte Entit\195\164t";

	KARMA_DATEFORMAT = "%d.%m.%Y";

	KARMA_WINEL_OK = "Ok";
	-- KARMA_WINEL_APPLY = "\195\156bernehmen";
	KARMA_WINEL_APPLY = "Ausf\195\188hren";
	KARMA_WINEL_CANCEL = "Abbrechen";

	KARMA_CHATMSG_VARIOUS_REGIONS = "verschiedene Regionen";

	KARMA_WINEL_PARTYLISTTITLE = "aktuelle Gruppe";
	KARMA_WINEL_MEMBERLISTTITLE = "ehemalige Gruppen";

	KARMA_WINEL_NOTESPUBLIC = "'\195\182ffentliche' Notiz";
	KARMA_WINEL_NOTESPUBLICFRAMETITLE = KARMA_WINEL_NOTESPUBLIC .. KARMA_WINEL_FRAG_COLONSPACE .. "(max. 40 Zeichen!)";
	KARMA_WINEL_NOTESSCROLLFRAMETITLE = "private Notiz:";
	KARMA_WINEL_PARTYLISTTITLE = "aktuelle Gruppe";
	KARMA_WINEL_MEMBERLISTTITLE = "ehemalige Gruppen";
	KARMA_WINEL_CHOSENPLAYERTITLE = "Name:";
	KARMA_WINEL_CHOSENPLAYERXPTITLE = "gemeinsame Erfahrung:";
	KARMA_WINEL_CHOSENPLAYERXPACCRUEDTITLE = "Aufsummiert:";
	KARMA_WINEL_CHOSENPLAYERXPPERCENTAGETITLE = "Prozentual:";
	KARMA_WINEL_CHOSENPLAYERTIMETITLE = "gemeinsame Spielzeit:";
	KARMA_WINEL_CHOSENPLAYERTIMEACCRUEDTITLE = "Aufsummiert:";
	KARMA_WINEL_CHOSENPLAYERTIMEPERCENTAGETITLE = "Prozentual:";
	KARMA_WINEL_KARMAINDICATORTITLE = KARMA_ITSELF .. " Einstufung:";
	KARMA_WINEL_KARMAQUESTLIST = "abgeschlossene Quests:";
	KARMA_WINEL_KARMAZONELIST = "erkundete Gebiete:";

	KARMA_WINEL_TALENTSBUTTON = "Talente...";
	KARMA_WINEL_OPTIONSBUTTON = "Optionen...";
	KARMA_WINEL_INVITEBUTTON = "Einladen";
	KARMA_WINEL_UPDATEBUTTON = "Aktualisieren";
	KARMA_WINEL_REMOVEBUTTON = "Entfernen";
	KARMA_WINEL_CLOSEBUTTON = "Schlie\195\159en";
	KARMA_WINEL_POSTTOCHATBUTTON = "An Chat senden";

	KARMA_WINEL_REMOVE_QUESTION_TEXT_PRE = "Bist du dir sicher, da\195\159 du >";
	KARMA_WINEL_REMOVE_QUESTION_TEXT_POST = "< von der Liste streichen m\195\182chtest?";
	KARMA_WINEL_REMOVE_QUESTION_BTN_EXECUTE = "L\195\150SCHEN!";
	KARMA_WINEL_REMOVE_QUESTION_BTN_CANCEL = "Nicht sicher...";

	--
	KARMA_WINEL_FILTER_TITLE = KARMA_WINEL_FILTER .. "kriterien:";
	KARMA_WINEL_FILTER_NAME = "Name: ";
	KARMA_WINEL_FILTER_CLASS = "Klasse: ";
	KARMA_WINEL_FILTER_LEVELFROM = "Stufe von ";
	KARMA_WINEL_FILTER_LEVELTO = " bis ";
	KARMA_WINEL_FILTER_KARMAFROM = KARMA_ITSELF .. " von ";
	KARMA_WINEL_FILTER_KARMATO = " bis ";
	KARMA_WINEL_FILTER_NOTE = "Notiz enth\195\164lt: ";

	--

	KARMA_WINEL_PLAYER_TITLE = "Spieler/-in: ";
	KARMA_WINEL_HPS = "HPS (Heilung)";
	KARMA_WINEL_DPS = "DPS (Schaden)";
	KARMA_WINEL_TANK = "TANK (Mobh\195\188ter)";
	KARMA_WINEL_MELEE = "Nahk\195\164mpfer";
	KARMA_WINEL_RANGED = "Fernk\195\164mpfer";

	--

	KARMA_WINEL_CATEGORYAREATITLE = "Kategorien:";
	KARMA_WINEL_OPTCAT1 = "Sortierung/Einf\195\164rbung";
	KARMA_WINEL_OPTCAT2 = "Tooltip";
	KARMA_WINEL_OPTCAT3 = "auto. Ignor./Warn.";
	KARMA_WINEL_OPTCAT4 = "Chatfenster";
	KARMA_WINEL_OPTCAT5 = "'Virtuelles' " .. KARMA_ITSELF;
	KARMA_WINEL_OPTCAT98 = "Andere";
	KARMA_WINEL_OPTCAT99 = "Datenbank aufr\195\164umen";

	--

	KARMA_WINEL_SORTINGAREATITLE = "Sortierung und Einf\195\164rbung:";
	KARMA_WINEL_SORTBYDROPDOWNTITLE = "Sortieren nach:";
	KARMA_WINEL_COLORBYDROPDOWNTITLE = "Einf\195\164rben nach:";

	KARMA_WINEL_DROPDOWNBYKARMA = KARMA_ITSELF;
	KARMA_WINEL_DROPDOWNBYXP = "Erfahrung mit akt. Char.";
	KARMA_WINEL_DROPDOWNBYTIME = "Spielzeit mit akt. Char.";
	KARMA_WINEL_DROPDOWNBYXPALL = "Erfahrung mit allen Char.";
	KARMA_WINEL_DROPDOWNBYTIMEALL = "Spielzeit mit allen Char.";
	KARMA_WINEL_DROPDOWNBYNAME = "Name";
	KARMA_WINEL_DROPDOWNBYCLASS = "Klasse";
	KARMA_WINEL_DROPDOWNBYJOINED = "in Gruppe";
	KARMA_WINEL_DROPDOWNBYTALENT = "Talentierung";

	KARMA_WINEL_CHATWINDOWSAREATITLE = "Chatfenster Nutzung";
	KARMA_WINEL_CHATDEFAULTTITLE = "Standardfenster:";
	KARMA_WINEL_CHATSECONDARYTITLE = "zweites Fenster:";
	KARMA_WINEL_CHATDEBUGTITLE = "DEBUG Fenster:";
	KARMA_WINEL_CHATDROPDOWNRESET = "Zur\195\188cksetzen";

	KARMA_WINEL_AUTOIGNOREAREATITLE = "automatisches Ignorieren/Warnen:";
	KARMA_WINEL_AUTOIGNOREENABLEDCHECKBOXTITLE = "automat. Ignorieren aktivieren";
	KARMA_WINEL_IGNOREINVITESCHECKBOXTITLE = "Einladungen/Handel/Duelle ignorieren";
	KARMA_WINEL_AUTOIGNORETHRESHOLD = KARMA_ITSELF .. "grenzwert f\195\188r automat. Ignorieren";
	KARMA_WINEL_WARNLOWKARMA_TITLE = "Warnen vor Gruppenmitgliedern mit niedrigem Karm";
	KARMA_WINEL_WARNLOWKARMA_THRESHOLD = KARMA_ITSELF .. "grenzwert f\195\188r Warnung";

	KARMA_WINEL_MARKUPAREATITLE = "Einf\195\164rbung von Chattern";
	KARMA_WINEL_MARKUPENABLEDCHECKBOXTITLE = "Einf\195\164rbung aktivieren";
	KARMA_WINEL_MARKUPCHANNELSCHECKBOXTITLE = "Einf\195\164rbung bei regul\195\164rem Chat";
	KARMA_WINEL_MARKUPWHISPERSCHECKBOXTITLE = "Einf\195\164rbung bei Fl\195\188stern";

	--
	KARMA_WINEL_OPTIONSDBCLEANAREATITLE = "Optionen zum Entr\195\188mpeln der DB:";

	KARMA_WINEL_AUTOCLEANCHECKBOXTITLE = "automatisches L\195\182schen (Mit Vorsicht zu genie\195\159en!)";
	KARMA_WINEL_AUTOCLEANCHECKBOXTOOLTIP = {
			"automatisches L\195\182schen",
			"Dies f\195\188hrt bei jedem Login ein /karma clean aus.",
			"Es ist empfehlenswert, h\195\164ufiger Sicherheitskopien anzulegen,",
			"wenn diese Option aktiviert ist.",
		};
	KARMA_WINEL_AUTOCLEANCHECKBOXTOOLTIPEXTRA = "(Du machst regelm\195\164\195\188ig Sicherheitskopien, oder?)";

	KARMA_WINEL_DBCLEANSECTIONTITLE = "Kriterien zum Behalten/Entfernen von Eintr\195\164gen:";

	KARMA_WINEL_DBCLEANKEEPIFNOTETITLE = "Behalten sofern Notiz vorhanden";
	KARMA_WINEL_DBCLEANKEEPIFNOTETOOLTIP = {
			"Behalten sofern Notiz vorhanden",
			"Wenn diese Option aktiv ist, werden Eintr\195\164ge mit einer Notiz nicht gel\195\182scht.",
			"Diese Option ist auch notwendig, wenn von den Fremdserver-Eintr\195\164gen",
			"diejenigen behalten werden sollen, die eine Notiz haben,",
			"w\195\164hrend die ohne Notiz gel\195\182scht werden sollen!",
		};

	KARMA_WINEL_DBCLEANREMOVEXSERVERTITLE = "Entfernen bei fremdem Server (-> Name (*) <-)";
	KARMA_WINEL_DBCLEANREMOVEXSERVERTOOLTIP = {
			"Entfernen bei fremdem Server (-> Name (*) <-)",
			"Wenn diese Option aktiv ist, werden Fremdserver-Eintr\195\164ge ohne Notiz gel\195\182scht.",
			"Falls die folgende Option NICHT gesetzt ist, werden ALLE Fremdserver-Eintr\195\164ge gel\195\182scht,",
			"selbst diejenigen mit einer Notiz!",
		};

	KARMA_WINEL_DBCLEANKEEPIFKARMATITLE = "Behalten bei einem " .. KARMA_ITSELF .. " ungleich 50";
	KARMA_WINEL_DBCLEANKEEPIFKARMATOOLTIP = {
			"Behalten bei einem " .. KARMA_ITSELF .. " Wert ungleich 50",
			"Wenn diese Option aktiv ist, werden Eintr\195\164ge mit einem " .. KARMA_ITSELF .. " Wert ungleich 50 behalten.",
			"(Diese Pr\195\188fung erfolgt nach den Pr\195\188fungen auf Notiz & Fremdserver.)",
		};

	KARMA_WINEL_DBCLEANKEEPIFQUESTNUMTITLE = "oder mehr Quests zum Behalten";
	KARMA_WINEL_DBCLEANKEEPIFQUESTNUMTOOLTIP = {
			"Behalten wenn zusammen n Quests absolviert",
			"Eintr\195\164ge mit mindestens dieser Anzahl an gemeinsam vorangebrachten/abgeschlossenen Quests werden behalten.",
			"(Diese Pr\195\188fung erfolgt nach den Pr\195\188fungen auf Notiz & Fremdserver.)",
		};

	KARMA_WINEL_DBCLEANKEEPIFREGIONNUMTITLE = "oder mehr Regionen zum Behalten";
	KARMA_WINEL_DBCLEANKEEPIFREGIONNUMTOOLTIP = {
			"Behalten wenn zusammen n Regionen bereist",
			"Eintr\195\164ge mit mindestens dieser Anzahl an gemeinsam bereisten Regionen werden behalten.",
			"Sofern 'PVP Regionen/Zonen nicht mitz\195\164hlen' aktiv ist, werden solche Regionen nicht mitgez\195\164hlt.",
			"(Diese Pr\195\188fung erfolgt nach den Pr\195\188fungen auf Notiz & Fremdserver.)",
		};

	KARMA_WINEL_DBCLEANKEEPIFZONENUMTITLE = "oder mehr Zonen zum Behalten";
	KARMA_WINEL_DBCLEANKEEPIFZONENUMTOOLTIP = {
			"Behalten wenn zusammen n Zonen bereist",
			"Eintr\195\164ge mit mindestens dieser Anzahl an gemeinsam bereisten Zonen werden behalten.",
			"Sofern 'PVP Regionen/Zonen nicht mitz\195\164hlen' aktiv ist, werden solche Zonen,",
			"die als PVP Zonen bekannt sind, nicht mitgez\195\164hlt.",
			"(Diese Pr\195\188fung erfolgt nach den Pr\195\188fungen auf Notiz & Fremdserver.)",
		};

	KARMA_WINEL_DBCLEANIGNOREPVPZONESTITLE = "PVP Regionen/Zonen nicht mitz\195\164hlen";
	KARMA_WINEL_DBCLEANIGNOREPVPZONESTOOLTIP = {
			"PVP Regionen/Zonen nicht mitz\195\164hlen",
			"PVP Regionen/Zonen nicht mitz\195\164hlen f\195\188r die Entscheidung,",
			"ob ein Eintrag behalten werden soll.",
			KARMA_ITSELF .. " wei\195\159 um die PVP Regionen automatisch,",
			"PVP Zonen m\195\188ssen jedoch mindestens einmal bereist werden, damit sie erkannt",
			"und entsprechend markiert werden k\195\182nnen.",
			"(Diese Pr\195\188fung erfolgt nach den Pr\195\188fungen auf Notiz & Fremdserver.)",
		};

	KARMA_WINEL_OPTIONSOTHERAREATITLE = "Andere Optionen:";
	KARMA_WINEL_TARGETCOLOREDCHECKBOXTITLE = "Hintergrund des Ziels in " .. KARMA_ITSELF .. "-Farbe";
	KARMA_WINEL_QCACHWARNCHECKBOXTITLE = "Warnung anzeigen: nur teilw. sichtb. Questlog";
	KARMA_WINEL_MAINWNDTAB_DROPDOWNTITLE = "Hauptfenster:\ninitiale Tab beim \195\150ffnen";
	KARMA_WINEL_AUTOCHECKTALENTSCHECKBOXTITLE = "Automatisch Talente von Gruppenmitgliedern aufnehmen";
	KARMA_WINEL_MINIMAPICONHIDE_TITLE = "Verstecke Minimap-Icon";
	KARMA_WINEL_QUESTSIGNOREDAILIES_TITLE = "t\195\164gliche Quests nicht in die Listen aufnehmen";

	KARMA_WINEL_OPTIONSVIRTUALKARMAAREATITLE = "'virtuelles' " .. KARMA_ITSELF .. ": Spielzeit (EXPERIMENTELL!!)";
	KARMA_WINEL_TIMEKARMA_ENABLE_TITLE = "F\195\188ge 'virtuelles' " .. KARMA_ITSELF .. " f\195\188r gesamte gemeinsame Spielzeit hinzu";
	KARMA_WINEL_TIMEKARMA_MINVAL_TITLE = KARMA_ITSELF .. "schwelle f\195\188r Hinzuf\195\188gen: ";
	KARMA_WINEL_TIMEKARMA_FACTOR_TITLE = KARMA_ITSELF .. " pro Stunde: ";

	KARMA_WINEL_OPTIONSTOOLTIPAREATITLE = "Tooltip";
	KARMA_WINEL_KARMATIPSCHECKBOXTITLE = KARMA_ITSELF .. " im Tooltip anzeigen";
	KARMA_WINEL_NOTETIPSCHECKBOXTITLE = "Notiz im Tooltip anzeigen";
	KARMA_WINEL_TIPS_SKILL_SCHECKBOXTITLE = "F\195\164higkeit im Tooltip anzeigen";
	KARMA_WINEL_TIPS_TALENTS_SCHECKBOXTITLE = "Talente im Tooltip anzeigen";
	KARMA_WINEL_TIPS_ALTS_SCHECKBOXTITLE = "Alts im Tooltip anzeigen";
	KARMA_WINEL_TT_HELP_BOXTITLE = "Hilfe-Tooltips zur UI anzeigen";

	KARMA_WINEL_MINIMENU_TOOLTIP1 = "Linksklick f\195\188r " .. KARMA_ITSELF .. "s Haupt-Fenster";
	KARMA_WINEL_MINIMENU_TOOLTIP2 = "Mitttelklick f\195\188r " .. KARMA_ITSELF .. "s Suche-Fenster";
	KARMA_WINEL_MINIMENU_TOOLTIP3 = "Rechtsklick f\195\188r das Men\195\188";

	KARMA_WINEL_MINIMENU_TARGETIS = ": Anvisiert ist ";
	KARMA_WINEL_MINIMENU_TARGETNONE = ": Niemand ist anvisiert!";
	KARMA_WINEL_MINIMENU_KARMACHANGE = KARMA_ITSELF .. " \195\164ndern um ...";
	KARMA_WINEL_MINIMENU_KARMAADDCHAR = "Spieler/-in in " .. KARMA_ITSELF .. "liste aufnehmen";
	KARMA_WINEL_MINIMENU_KARMADELCHAR = "Spieler/-in aus " .. KARMA_ITSELF .. "liste streichen";
	
	KARMA_WINEL_MINIMENUSUB_INCREASE = "Erh\195\182he " .. KARMA_ITSELF .. " um ...";
	KARMA_WINEL_MINIMENUSUB_DECREASE = "Erniedrige " .. KARMA_ITSELF .. " um ...";

	KARMA_WINEL_REASON_NONE = "keine Notiz";
	KARMA_WINEL_REASON_SKILL = "Skill";
	KARMA_WINEL_REASON_MANNERS_UNCATEGORIZED = "Manieren"; 
	
	KARMA_WINEL_REASON_NINJA = "ninja-looter";
	KARMA_WINEL_REASON_KSER = "KSer";
	KARMA_WINEL_REASON_BOT = "bot";
	KARMA_WINEL_REASON_MANNERS_CONCEITED = "m:eingebildet";
	KARMA_WINEL_REASON_MANNERS_RUDE = "m:unh\195\182flich";
	KARMA_WINEL_REASON_MANNERS_SCAM = "m:scam";
	KARMA_WINEL_REASON_MANNERS_DRAMAQUEEN = "m:drama queen";
	KARMA_WINEL_REASON_SPAM_UNCATEGORIZED = "spam";
	KARMA_WINEL_REASON_SPAM_ALLCAPS = "s:ALLES GROSS";
	KARMA_WINEL_REASON_SPAM_WRONG_CHANNEL = "s:channel Mi\195\159brauch";
	KARMA_WINEL_REASON_SPAM_SPEED = "s:schnelle Wiederholungen";
	
	KARMA_WINEL_REASON_HELP_KILL = "half beim Monstert\195\182ten";
	KARMA_WINEL_REASON_HELP_INFO = "half mit Infos";
	KARMA_WINEL_REASON_HELP_ORGANIZE = "half organisieren";
	KARMA_WINEL_REASON_MANNERS_MODEST = "m:bescheiden";
	KARMA_WINEL_REASON_MANNERS_POLITE = "m:h\195\182flich"; 
	KARMA_WINEL_REASON_MANNERS_GENEROUS = "m:gro\195\159z\195\188gig";
	KARMA_WINEL_REASON_MANNERS_GRACIOUS = "m:g\195\188tig";

	KARMA_BINDING_HEADER_TITLE = KARMA_ITSELF .. ": Tastaturbelegung";
	KARMA_BINDING_WINDOW_TITLE = "\195\150ffnen/Schlie\195\159en des " .. KARMA_ITSELF .. " - Fensters";
	KARMA_BINDING_WINDOW2_TITLE = "\195\150ffnen/Schlie\195\159en des " .. KARMA_ITSELF .. " - Spieler/-in - Online - Fensters";

	KARMA_PVPZONE_WSG = "Kriegshymnenschlucht";
	KARMA_PVPZONE_AB = "Arathibecken";
	KARMA_PVPZONE_AV = "Alteractal";
	KARMA_PVPZONE_ES = "Auge des Sturms";

	KARMA_WINEL_LISTMEMBERTIP_JOINED_ATALL_PRE = "In Gruppe (mit ";
	KARMA_WINEL_LISTMEMBERTIP_JOINED_ATALL_POST = KARMA_WINEL_FRAG_BRACKET_RIGHT .. KARMA_WINEL_FRAG_COLONSPACE;
	KARMA_WINEL_LISTMEMBERTIP_JOINED_CHAR = "In Gruppe mit diesem Char" .. KARMA_WINEL_FRAG_COLONSPACE;
	KARMA_WINEL_LISTMEMBERTIP_UPDATE_OK = "Aktualisiert" .. KARMA_WINEL_FRAG_COLONSPACE;
	KARMA_WINEL_LISTMEMBERTIP_UPDATE_FAIL = "Versucht zu aktualisieren" .. KARMA_WINEL_FRAG_COLONSPACE;
	KARMA_WINEL_LISTMEMBERTIP_UPDATE_NEVER = "Nie aktualisiert...";

	KARMA_CHANNELNAME_LFG = "SucheNachGruppe";

	KARMA_CLASS_DRUID_M = "Druide";
	KARMA_CLASS_DRUID_F = "Druidin";
	KARMA_CLASS_HUNTER_M = "J\195\164ger";
	KARMA_CLASS_HUNTER_F = "J\195\164gerin";
	KARMA_CLASS_MAGE_M = "Magier";
	KARMA_CLASS_MAGE_F = "Magierin";
	KARMA_CLASS_PALADIN_M = "Paladin";
	KARMA_CLASS_PALADIN_F = "Paladin";
	KARMA_CLASS_PRIEST_M = "Priester";
	KARMA_CLASS_PRIEST_F = "Priesterin";
	KARMA_CLASS_ROGUE_M = "Schurke";
	KARMA_CLASS_ROGUE_F = "Schurkin";
	KARMA_CLASS_SHAMAN_M = "Schamane";
	KARMA_CLASS_SHAMAN_F = "Schamanin";
	KARMA_CLASS_WARRIOR_M = "Krieger";
	KARMA_CLASS_WARRIOR_F = "Kriegerin";
	KARMA_CLASS_WARLOCK_M = "Hexenmeister";
	KARMA_CLASS_WARLOCK_F = "Hexenmeisterin";

	KARMA_CLASS_DEATHKNIGHT_M = "Todesritter";
	KARMA_CLASS_DEATHKNIGHT_F = "Todesritter";

	KARMA_RACES_ALLIANCE_LOCALIZED =
		{
			KRA_DRAENEI	= "Draenei",
			KRA_DWARF	= "Zwerg",
			KRA_GNOME	= "Gnom",
			KRA_HUMAN	= "Mensch",
			KRA_NIGHTELF	= "Nachtelf",
		};

	KARMA_RACES_HORDE_LOCALIZED =
		{
			KRH_BLOODELF	= "Blutelf",
			KRH_ORC		= "Orc",
			KRH_TAUREN	= "Taure",
			KRH_TROLL	= "Troll",
			KRH_UNDEAD	= "Untoter",
		};

	KARMA_RACES_ALLIANCE_MALE =
		{
			DRAENEI		= "Draenei",
			DWARF		= "Zwerg",
			GNOME		= "Gnom",
			HUMAN		= "Mensch",
			NIGHTELF	= "Nachtelf",
		};

	KARMA_RACES_HORDE_MALE =
		{
			BLOODELF	= "Blutelf",
			ORC		= "Orc",
			TAUREN		= "Taure",
			TROLL		= "Troll",
			UNDEAD		= "Untoter",
		};

	KARMA_RACES_ALLIANCE_FEMALE =
		{
			DRAENEI		= "Draenei",
			DWARF		= "Zwerg",
			GNOME		= "Gnom",
			HUMAN		= "Mensch",
			NIGHTELF	= "Nachtelfe",
		};

	KARMA_RACES_HORDE_FEMALE =
		{
			BLOODELF	= "Blutelfe",
			ORC		= "Orc",
			TAUREN		= "Taure",
			TROLL		= "Troll",
			UNDEAD		= "Untote",
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
			[5] = "Mangel an elementaren Fertigkeiten: Karte lesen/Questlog verstehen",
			[10] = "Mangel an Basisspielfertigkeit: Folgen in der Gruppe",
			[15] = "Mangel an Basisgruppenfertigkeit: Anweisung folgen/Zusammenspiel",
			[20] = "kann einfachen Anweisungen nachkommen: folgen, angreifen, stop",
			[25] = "kann *ein* Ziel tanken",
			[30] = "ertr\195\164glich bis n\195\188tzlich in einer normalen Instanz",
			[35] = "f\195\164hig, das richtige Ziel anzugreifen (d.h. assist)",
			[40] = "kann ein Ziel einmal CCen (kontrollieren)",
			[45] = "kann *zwei* Ziele tanken",
			[50] = "kann ein Ziel wiederholt und durchg\195\164ngig CCen",
			[55] = "kann CCen und trotzdem auf dem Hauptziel bleiben",
			[60] = "kann *drei* Ziele tanken und dabei den Heiler im Blick behalten",
			[65] = "f\195\164hig, automatisch neu zu assisten, wenn CC sich \195\164dert",
			[70] = "ertr\195\164glich bis n\195\188tzlich in einer heroischen Instanz",
			[75] = "f\195\164hig zu dynamischer CC (z.B. CC wechseln auf den Mob auf dem Heiler)",
			[80] = "f\195\164hig, *zwei* Ziele zu CCen (sprich, kiten)",
			[85] = "kann *vier* Ziele tanken",
			[100] = "ein wahrer Held",
		};

	KARMA_SKILL_LEVELS_SIMPLE =
		{
			[0] = "6: hoffnungsloser Fall",
			[20] = "5: lernt's noch... eines Tages",
			[40] = "4: f\195\164hig zu einfachen Sachen",
			[60] = "3: f\195\164hig zu regul\195\164ren Instanzen",
			[80] = "2: f\195\164hig zu heroischen Instanzen",
			[100] = "1: (*fast*) vollkommen",
		};


	KARMA_WINEL_TRACKINGDATA_BUTTON = "Zeige autom. Daten";
	KARMA_WINEL_OTHERDATA_BUTTON = "Zeige andere Daten";
	KARMA_WINEL_OTHERDATA_TITLE = "Andere Daten";
	KARMA_WINEL_CHOSENPLAYERSKILLTITLE = "F\195\164higk.";
	KARMA_WINEL_CHOSENPLAYERGEARPVETITLE = "R\195\188st./PVE";
	KARMA_WINEL_CHOSENPLAYERGEARPVPTITLE = "R\195\188st./PVP";

	KARMA_WINEL_LFM_TITLE = KARMA_ITSELF_COLONSPACE .. "Suche...";
	KARMA_WINEL_LIST1_TITLE = "Spieler/-in online";
	KARMA_WINEL_POPULATE_TITLE = "Spieler/-in suchen...";
	KARMA_WINEL_LIST2_TITLE = "Spieler/-in ausgew\195\164hlt";

	KARMA_WINEL_SENDMESS_TITLE = "n\195\164chstes Senden auch an diese/-n Spieler/-in";
	KARMA_WINEL_SENTMESS_TITLE = "mind. 1x eine Nachricht gesandt";
	KARMA_WINEL_POSREPLY_TITLE = "zustimmende Antwort bekommen";

	KARMA_WINEL_SENDMESS_TOOLTIP =     "Wenn hier ein H\195\164kchen sitzt,\n"
					.. "wird die Nachricht (unten)\n"
					.. "auch an diese/-n Spieler/-in gesandt\n"
					.. "beim n\195\164chsten Klick auf\n"
					.. "[\"Sende Nachrichten\"]";
	KARMA_WINEL_SENTMESS_TOOLTIP =     "Hier setzt " .. KARMA_ITSELF .. " ein H\195\164kchen,\n"
					.. "nachdem dem/der Spieler/-in eine Nachricht\n"
					.. "(\195\188ber dieses Fenster) gesandt wurde.";
	KARMA_WINEL_POSREPLY_TOOLTIP =     "Wenn hier ein H\195\164kchen sitzt,\n"
					.. "wird diese/-r Spieler/-in eingeladen in\n"
					.. "die Gruppe beim n\195\164chsten\n"
					.. "Klick auf [\"Lade Spieler/-in ein\"]\n"
					.. "(Geht nat\195\188rlich nur, wenn:\n"
					.. "- du der Anf\195\188hrer bist und\n"
					.. "- die Gruppe nicht voll ist)";

	KARMA_WINEL_SEND_TITLE  = "Sendet an alle Spieler/-innen\nmarkiert mit \"Senden\"";
	KARMA_WINEL_SENDMESSAGE_BTNTITLE = "Sende Nachrichten";
	
	KARMA_WINEL_INVITE_TITLE  = "L\195\164dt Spieler/-in markiert\nmit \"zust. Antwort\"";
	KARMA_WINEL_INVITE_BTNTITLE = "Lade Spieler/-in ein";

	KARMA_WINEL_ALTADDBUTTON = "Markiere als ALT von ";
	KARMA_WINEL_ALTREMBUTTON = "Entferne aus entsprechender ALT Liste";

	KARMA_WINEL_POPULATE_CHANNEL_TITLE = "Suche in Channel nach Spielern/-innen:";
	KARMA_WINEL_POPULATE_CHANNELS_TITLE = "Suche in allen Channeln nach Spielern/-innen";
	KARMA_WINEL_POPULATE_LEVEL_TITLE = "Stufenbereich (Klassen-Suche) :";
	KARMA_WINEL_POPULATE_CLASS_TITLE = "Suche nach Spielern/-innen der Klasse:";
	KARMA_WINEL_POPULATE_CLASSES_TITLE = "Suche nach Spielern/-innen ALLER Klassen\n!! DAS DAUERT SEHR LANGE !!\n(ca. 2:30 andauernde /who-Anfragen)";
	KARMA_WINEL_POPULATE_GUILD_TITLE = "Suche nach Spielern/-innen aus Gilde:";

	KARMA_WINEL_FILTERLIST1_TITLE = KARMA_WINEL_FILTER;
	KARMA_WINEL_FILTERLIST1_KARMAMIN_TITLE = "min. " .. KARMA_ITSELF .. ": ";
	KARMA_WINEL_FILTERLIST1_KARMAREQ_TITLE = "Nur " .. KARMA_ITSELF .. " bekannte Spieler/-in\n(also mit " .. KARMA_ITSELF .. " Wertung)";
	KARMA_WINEL_FILTERLIST1_SKILLMIN_TITLE = "min. F\195\164higk.: ";
	KARMA_WINEL_FILTERLIST1_CLASSREQ_TITLE = "Klasse mu\195\159 bekannt sein\n(also keine grauen Eintr\195\164ge)";
	KARMA_WINEL_FILTERLIST1_LEVELRANGE_TITLE = "Stufenbereich: ";

--
--
--

	KARMA_TOOLTIPS["PUBLICNOTE"] =
		{
			"Diese Notiz kann von anderen (mit " .. KARMA_ITSELF .. ") angefordert werden.",
			"",
			"Es werden NUR 40 Zeichen gemerkt!",
			"(Man kann mehr in das Feld *eingeben*, aber das liegt daran, da\195\159 " .. KARMA_ITSELF .. " versucht,",
			"die mangelhafte Internationalisierung - lausiger UTF8-support - auszugleichen.)",
			"*Wie* '\195\182ffentlich' die Notiz und die " .. KARMA_ITSELF .. "-Wertungen sind, kann ver\195\164ndert werden",
			"mit dem Befehl '" .. KARMA_CMDSELF .. " shareconfig'.",
			"Standard: " .. KARMA_ITSELF .. "-Wertung wird nicht herausgegeben, '\195\182ffentliche' Notiz nur an Gildenmitglieder",
		};

	-- KARMA_TOOLTIPS[KARMA_WINEL_FILTER] =
	
	KARMA_TOOLTIPS["FILTER"] =
		{
			"Angaben hier filtern die Liste der Namen.",
			"Filter fangen an mit Typ und Bindestrich, danach folgen ein oder zwei Werte.",
			"M\195\182gliche Filter sind:",
			"n-<Fragment>: filtert auf Namen, die mit <Fragment> anfangen",
			"    (<Fragment> wird meist mit einem Gro\195\159buchstaben anfangen...)",
			"c-<Klasse>: zeigt nur die <Klasse> (kann meist abgek\195\188rzt werden)",
			"l-<Stufe von>-<Stufe bis>: (l ist ein kleines L!) zeigt nur Spieler/-innen",
			"    im angegebenen Stufenbereich (einer der beiden Werte kann weggelassen werden)",
			"k-<" .. KARMA_ITSELF .. " von>-<" .. KARMA_ITSELF .. " bis>: zeigt nur Spieler/-innen mit entsprechendem " .. KARMA_ITSELF,
			"    (auch hier kann ein Wert weggelassen werden)",
			"i-<Fragment>: zeigt nur Spieler/-innen, deren Notiz <Fragment> *irgendwo* enth\195\164lt",
			"Ein Eintrag ohne <Typ>- Qualifizierer wird als n- Filter interpretiert.",
			"Alle 5 Filtertypen k\195\182nnen - mit Leerzeichen getrennt - miteinander kombiniert werden.",
			"",
			"Beispiel: n-A c-Pr l--15 k-51-",
			"Das w\195\188rde die Liste einschr\195\164nken auf alle Priester (c-Pr) bis Stufe 15 (l--15),",
			"    mit positivem " .. KARMA_ITSELF .. " (51 oder h\195\182her: k-51-, man beachte den zweiten Bindestrich!)",
			"    und deren Name mit A anf\195\164ngt (n-A).",
		};

--
--
--

	KARMA_MSG_OOPS = "Ups. Interner Fehler.";
	KARMA_MSG_OOPS_IDENTITY = "Ups! Fatale Identit\195\164tskrise aufgetreten! Sortierung ist weder nach Name noch nach Erfahrung m\195\182glich. :-(";
	KARMA_MSG_OOPS_NOTIMPLEMENTED = "Noch nicht implementiert";

	KARMA_MSG_CANNOT_PRE = "Befehl *";
	KARMA_MSG_CANNOT_POST = "* nicht ausf\195\188hrbar";
	KARMA_MSG_UNKNOWN = " unbekannt.";

	KARMA_MSG_SHORT_DAY = "t";
	-- KARMA_MSG_SHORT_HOUR = "h";			-- like English, keep for line sync
	-- KARMA_MSG_SHORT_MINUTE = "m";		-- like English, keep for line sync
	-- KARMA_MSG_SHORT_SECOND = "s";		-- like English, keep for line sync

	KARMA_MSG_ON = "an";
	KARMA_MSG_OFF = "aus";

	KARMA_MSG_CONFIG_ISNOWON = " ist nun AN.";
	KARMA_MSG_CONFIG_ISNOWOFF = " ist nun AUS.";

	KARMA_MSG_COMMAND = "Befehl ";
	KARMA_MSG_COMMAND_NEEDTARGETORARGUMENT = " wurde aufgerufen ohne Ziel und ohne <Spieler/-in>-Parameter.";
	KARMA_MSG_COMMAND_MISSINGARG = "Notwendiger Parameter fehlt";
	KARMA_MSG_COMMAND_MISSINGARGS = "Notwendige Parameter fehlen";
	KARMA_MSG_COMMAND_NOTMEMBER = "nicht auf der " .. KARMA_ITSELF .. "-Liste";

	KARMA_MSG_COMMANDQUEUE_FULL1 = "Befehlswarteschlange mu\195\159 daf\195\188r leer sein. Derzeit warten noch";
	KARMA_MSG_COMMANDQUEUE_FULL2 = " Befehle auf ihre Ausf\195\188hrung.";

	KARMA_MSG_HELPINSECONDWINDOW = "Kurzhilfe wird im zweiten Fenster angezeigt...";
	KARMA_MSG_HELPCOMMANDLIST = "Vollst\195\164ndige Liste der Befehle:";

	KARMA_MSG_PLAYER_REQARG = "<Spieler/-in>";
	KARMA_MSG_REMOVE_COMPLETED = " wurde aus der " .. KARMA_ITSELF .. "-Liste gel\195\182scht.";

	KARMA_MSG_ADDMEMBER_ADDED = " ist nun auf der " .. KARMA_ITSELF .. "-Liste.";
	KARMA_MSG_IGNOREMEMBER_ADDED = " ist nun auf der " .. KARMA_ITSELF .. "-Liste und wird ignoriert.";
	KARMA_MSG_ADDORIGNMEMBER_OFFLINE = " wurde nicht gefunden. Spieler/-in ist vermutlich nicht online.";

	KARMA_MSG_UPDATEMEMBER_UPDATED = " aktualisiert, Spieler/-in befindet sich in: ";
	KARMA_MSG_UPDATEMEMBER_ONLINE = " ist online und befindet sich in: ";
	KARMA_MSG_UPDATEMEMBER_OFFLINE = " wurde nicht gefunden, Aktualisierung nicht m\195\182glich.";

	KARMA_MSG_CHECKING_FOR = "Suche nach ";
	KARMA_MSG_CHECKCHANNEL_ONE = "Suche in Channel";
	KARMA_MSG_CHECKCHANNEL_ALL = "Stelle Suche f\195\188r alle betretenen Channels in Warteschlange";
	KARMA_MSG_CHECKCHANNEL_RESULTS = "Ergebnisse von Channel";
	KARMA_MSG_CHECKCHANNEL_TOTAL1 = "Channel-Suche";
	KARMA_MSG_CHECKCHANNEL_TOTAL2 = " Namen verglichen, ";
	KARMA_MSG_CHECKCHANNEL_TOTAL3 = " wiedererkannt.";

	KARMA_MSG_WHORESULT_1 = "Ergebnisse f\195\188r ";
	KARMA_MSG_WHORESULT_2 = " sind verf\195\188gbar: ";
	KARMA_MSG_WHORESULT_3 = " Spieler/-innen";
	KARMA_MSG_WHORESULT_4 = " { )-: Ergebnis ist nur bruchst\195\188ckhaft :-( }";

	KARMA_MSG_WHOCATCHED_GOTNOTES = "Notiz zu ";
	KARMA_MSG_WHOCATCHED_NONOTES = "Keine Notiz zu ";

	KARMA_MSG_CONFIG_AUTOIGNORE = "Automatisches Ignorieren";

	KARMA_MSG_QCACHE_SECONDWINDOW = "Quest-Daten werden im zweiten Fenster angezeigt...";
	KARMA_MSG_QCACHE_SUBLISTING = "Zeige an: ";
	KARMA_MSG_QCACHE_COMPLETE = "abgeschlossen = ";
	KARMA_MSG_QCACHE_OBJECTIVESPECIAL = "(Entdecken/andere besondere Aufgabe)";

	KARMA_MSG_INSPECT_OVERRIDE1 = "Anfrage f\195\188r das Betrachten von ";
	KARMA_MSG_INSPECT_OVERRIDE2 = " wurde verworfen durch ein anderes AddOn oder eine GUI-Aktion. Verz\195\182gere die Anfrage bis ";
	KARMA_MSG_INSPECT_OVERRIDE3 = " bearbeitet wurde...";

	KARMA_MSG_CONFIG_TIP_KARMA = "Anzeige der " .. KARMA_ITSELF .. " Wertung im Tooltip";
	KARMA_MSG_CONFIG_TIP_NOTES = "Anzeige der Notizz von " .. KARMA_ITSELF .. " im Tooltip";

	KARMA_MSG_FILTER_SET = KARMA_WINEL_FILTER .. " gesetzt.";
	KARMA_MSG_FILTER_CLEARED = KARMA_WINEL_FILTER .. " auf leer gesetzt.";

	-- Ganz anderes wording als Englisch...
	KARMA_MSG_UPDATE_RANDOM_EMPTYBUCKET1 = "Bei einer (zuf\195\164lligen) Auswahl wurde niemand gefunden, dessen Name mit";
	KARMA_MSG_UPDATE_RANDOM_EMPTYBUCKET2 = "anf\195\164ngt.";

	KARMA_MSG_CONFIG_QCACHEWARN = "Warnung f\195\188r teilweise sichtbares Questlog";

	KARMA_MSG_CHECKCLASS_CLASS = "<Klasse>";
	KARMA_MSG_CHECKCLASS_UNK1 = "Klasse nicht erkannt";
	KARMA_MSG_CHECKCLASS_UNK2 = ", suche \195\188ber alle Rassen der Fraktion.";
	KARMA_MSG_CHECKCLASS_QUEUEING_ONE = "Suche ist nun in der Warteschlange eingereiht f\195\188r Klasse ";
	KARMA_MSG_CHECKCLASS_DONE1 = "Suche f\195\188r Klasse ";
	KARMA_MSG_CHECKCLASS_DONE2 = " abgeschlossen.";

	KARMA_MSG_CHECKCLASS_QUEUEING_ALL = "Warteschlange wird mit Suche \195\188ber ALLE Klassen belegt. Das wird einige Zeit dauern...";
	KARMA_MSG_CHECKCLASS_DONE_QUICK = "Schnelle Suche f\195\188r alle Klassen abgeschlossen. Langsame Suche läuft noch...";
	KARMA_MSG_CHECKCLASS_DONE_ALL = "Suche f\195\188r alle Klassen abgeschlossen.";

	KARMA_MSG_RESETGUI = "Die Positionen der Hauptfenster und des Minimap-Icons wurden nun zur\195\188ckgesetzt und sollten wieder benutztbar sein.";

	KARMA_MSG_CONFIG_AUTOTALENTS = "Automatisches Abfragen der Talente";

	KARMA_MSG_CONFIG_SKILLMODEL_ISNOW = "F\195\164higkeitsmodell ist nun";

	KARMA_MSG_FIELDINIT_ERROR_VALUE = "Ups! Ertappt beim Versuch einer Initialisierung von <unbekanntem Feld> auf ";
	KARMA_MSG_FIELDINIT_ERROR_TABLE = "eine <Tabelle>";

	KARMA_MSG_TIP_SKILL = "F\195\164higkeit";
	KARMA_MSG_TIP_TALENT = "Talente";
	-- KARMA_MSG_TIP_ALTS = "Alts";

	KARMA_MSG_QCACHE_WARNING = "WARNUNG! Das Questlog ist teilweise eingeklappt. Eventuell geht dadurch Questinformation f\195\188r " .. KARMA_ITSELF .. " verloren...";

	KARMA_MSG_DBCLEAN_EXTRAARG = "Datenbank bleibt unber\195\188hrt: Zus\195\164tzlichen Parameter gefunden. Wolltest du eventuell \"/karma clean dryrun\" ausprobieren?";
	KARMA_MSG_DBCLEAN_INGROUP = "Aufr\195\164umen der Datenbank nicht m\195\182glich: Du bist in einer Gruppe.";
	KARMA_MSG_DBCLEAN_PVPREGIONMARKED = "ist nun markiert als PVP Region.";

	KARMA_MSG_DBCLEAN_PRETEXT_NORMAL = "L\195\182sche Eintr\195\164ge aus der Datenbank";
	KARMA_MSG_DBCLEAN_RESULT_NORMAL1 = "In der Datenbank wurden ";
	KARMA_MSG_DBCLEAN_RESULT_NORMAL2 = " Eintr\195\164ge gel\195\182scht, insgesamt verbleiben damit nun";

	KARMA_MSG_DBCLEAN_PRETEXT_DRYRUN = "Zeige den Status der Eintr\195\164ge der Datenbank an";
	KARMA_MSG_DBCLEAN_RESULT_DRYRUN1 = "In der Datenbank wurden ";
	KARMA_MSG_DBCLEAN_RESULT_DRYRUN2 = " Eintr\195\164ge zum L\195\182schen gefunden, insgesamt verblieben bei tats\195\164chlichem L\195\182schen";

	KARMA_MSG_DBCLEAN_RESULT_3 = " Eintr\195\164ge.";

	KARMA_MSG_REMOVE_ISINGROUP1 = "Entfernen";
	KARMA_MSG_REMOVE_ISINGROUP2 = ", Mitglied in der aktuellen Gruppe!";

	KARMA_MSG_TIP_LEVEL = "Stufe";

	KARMA_MSG_AUTOIGNORE_GUILD = "Einladung in eine Gilde von ";
	KARMA_MSG_AUTOIGNORE_PARTY = "Einladung in eine Gruppe von ";
	KARMA_MSG_AUTOIGNORE_TRADE = "Aufforderung zum Handeln von ";
	KARMA_MSG_AUTOIGNORE_DUEL = "Duell-Forderung von ";
	KARMA_MSG_AUTOIGNORE_2 = KARMA_WINEL_FRAG_SPACE .. KARMA_ITSELF .. ") wurde automatisch abgewiesen. (Schwelle f\195\188r autom. Ignorieren ist bei ";
	KARMA_MSG_AUTOIGNORE_3 = KARMA_WINEL_FRAG_SPACE .. KARMA_ITSELF .. ".)";

	KARMA_MSG_MARKUP_WHISPER = " fl\195\188stert:\32";
	KARMA_MSG_MARKUP_CHANNEL = ":\32";

	KARMA_MSG_CHATWND_ISNOW = " Chatfenster ist nun";
	KARMA_MSG_CHATWND_OVERTHERE = "dort dr\195\188ben -->";
	KARMA_MSG_CHATWND_THISONE = " dieses hier.";
	KARMA_MSG_CHATWND_DEFAULTAGAIN = " zur\195\188ck auf... Standard!";
	KARMA_MSG_CHATWND_UNSET = " ungesetzt.";

	KARMA_MSG_CHATWND_DEFAULT = "Standard -";
	KARMA_MSG_CHATWND_SECONDARY = "Zus\195\164tzliches";
	KARMA_MSG_CHATWND_DEBUG = "DEBUG";

	KARMA_MSG_VERSION_NEW1 = "Neuere Version ist verf\195\188gbar: ";
	KARMA_MSG_VERSION_NEW2 = " (seit ";
	KARMA_MSG_VERSION_NEW3 = ")";

	-- KARMA_MSG_LFM_LIST1TIP_ALTS = "Alts";

	KARMA_MSG_CHATSETUP_AUTO = "[autom. zugewiesen] ";
	KARMA_MSG_CHATSETUP_1 = " (";
	KARMA_MSG_CHATSETUP_2_DEFAULT = "Standard-";
	KARMA_MSG_CHATSETUP_2_EXTRA = "weitere ";
	KARMA_MSG_CHATSETUP_2_DEBUG = "DEBUG-";
	KARMA_MSG_CHATSETUP_3 = "Nachrichten -> ";
	KARMA_MSG_CHATSETUP_4 = ")";
	KARMA_MSG_CHATSETUP_DONE = "Fenster gefunden";


	-- KARMA_MSG_ALT_REQARG = "<alt>";
	-- KARMA_MSG_ALT_REQARGS = "<alt1> <alt2>";

	KARMA_MSG_ALT_LIST_NOTMEMBER1 = "Alts von >";
	KARMA_MSG_ALT_LIST_NOTMEMBER2 = "< k\195\182nnen nicht aufgelistet werden";
	KARMA_MSG_ALT_LIST_NOALTS1 = "Keine Alts bekannt zu >";
	-- KARMA_MSG_ALT_LIST_NOALTS2 = "<.";
	-- KARMA_MSG_ALT_LIST_PREFIX = "AltID ";
	KARMA_MSG_ALT_LIST_OOPS_NOALTS1 = "Ups? AltID gesetzt, aber keine Alts gefunden f\195\188r >";
	-- KARMA_MSG_ALT_LIST_OOPS_NOALTS2 = "<.";

	KARMA_MSG_ALT_REM_NOTMEMBER1 = "Entfernen von >";
	KARMA_MSG_ALT_REM_NOTMEMBER2 = "< aus irgendeiner Alt-Gruppe nicht m\195\182glich";
	KARMA_MSG_ALT_REM_NOALTID1 = "";
	KARMA_MSG_ALT_REM_NOALTID2 = " ist nicht in irgendeiner Alt-Gruppe.";
	KARMA_MSG_ALT_REM_DONE1 = ">";
	KARMA_MSG_ALT_REM_DONE2 = "< aus der entsprechenden Alt-Gruppe gel\195\182scht.";
	KARMA_MSG_ALT_REM_OOPS_NOALTS1 = "Ups? AltID gesetzt, aber keine Alts zu >";
	KARMA_MSG_ALT_REM_OOPS_NOALTS2 = "< gefunden? Setze AltID zur\195\188ck";

	KARMA_MSG_ALT_ADD_SAMEPLAYER = "Es m\195\188ssen zwei *verschiedene* Namen als Parameter \195\188bergegeben werden!";
	KARMA_MSG_ALT_ADD_NOTMEMBER = "Die beiden angegebenen Spieler/-innen k\195\182nnen nicht zu Alts verbunden werden: eine/-r oder beide sind nicht in " .. KARMA_ITSELF .. "s Liste.";
	KARMA_MSG_ALT_ADD_ALREADYSAME = "Die beiden angegebenen Spieler/-innen sind bereits in der gleichen Alt-Gruppe.";
	KARMA_MSG_ALT_ADD_NOMERGE = "Das Verschmelzen von zwei verschiedenen Alt-Gruppen ist nicht implementiert. Tut mir leid.";
	KARMA_MSG_ALT_ADD_DONE1 = " und ";
	KARMA_MSG_ALT_ADD_DONE2 = " sind nun beide in Alt-Gruppe #";

	KARMA_MSG_CHECKGUILD_NOARG = "<Gilde>";

	KARMA_MSG_PARTYJOINED_LOWKARMA1 = "WARNUNG";
	KARMA_MSG_PARTYJOINED_LOWKARMA2 = " ist - mit nur ";
	KARMA_MSG_PARTYJOINED_LOWKARMA3 = " " .. KARMA_ITSELF .. " - unter dem gew\195\188nschten Mindestwert von ";
	-- KARMA_MSG_PARTYJOINED_LOWKARMA4 = " " .. KARMA_ITSELF .. "!";

	KARMA_MSG_TALENT_OTHERFRAMES = "Talentb\195\164ume k\195\182nnen nicht untersucht werden: mehrere Fenster haben sich angemeldet, das Ergebnis ist damit nicht eindeutig.";

	KARMA_UNITPOPUP_INCREASE = "Erh\195\182he um ";
	KARMA_UNITPOPUP_DECREASE = "Erniedrige um ";


	KARMA_FRAMES_HELP.Help_KW_MemberList_Frame =
		{
			"Hilfe zu: " .. KARMA_WINEL_MEMBERLISTTITLE,
			"Dies ist die Liste der Spielerinnen, die " .. KARMA_ITSELF .. " \"kennt\".",
			"~",
			"Man kann:",
			"- links-klicken, um den Spieler zur Anzeige auszuw\195\164hlen",
			"- shift-links-klicken, um die Chatzeile mit \"/fl <Spielerin> \" zu \195\182ffnen",
			"- mittel-klicken, um eine Aktualisierung des Spielers zu versuchen",
			"- rechts-klicken, um ein Men\195\188 mit weiteren Optionen zu \195\182ffnen",
			"Das Men\195\188 mit weiteren Optionen schlie\195\159t L\195\182schen sowie",
			"elementare Befehle f\195\188r Alt-Verwaltung ein.",
			"~",
			"Um zwei Spilerinnen als Alts zu verbinden:",
			"- links-klicken des ersten Spielers zur Auswahl",
			"  (die Spielerin wird nun auf der rechten Seite angezeigt)",
			"- rechts-klicken der zweiten Spielerin",
			"- Auswahl von \"" .. KARMA_WINEL_ALTADDBUTTON .. "<erster Spieler>\"",
		};
end

