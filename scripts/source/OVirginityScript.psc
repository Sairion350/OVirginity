ScriptName OVirginityScript Extends Quest

;needs StorageUtils from papyrusutils
;int property virginitychance auto

string IsVirginKey
spell menstruationspell
sound hymenbreak

faction jobInnServer
faction FavorJobsBeggarFaction
faction MarkarthTempleofDibellaFaction

AssociationType property Spouse Auto
race property OldPeopleRace auto

OsexIntegrationMain ostim 

globalvariable virginityChance

ocumscript ocum

Event OnInit()
	debug.Notification("OVirginity installed")
	console("OVirginity installed")

	IsVirginKey = "IsVirgin"
	ostim = game.GetFormFromFile(0x000801, "Ostim.esp") as OsexIntegrationMain
	menstruationspell = game.GetFormFromFile(0x000804, "OVirginity.esp") as spell
	hymenbreak = game.GetFormFromFile(0x000D68, "OVirginity.esp") as sound

	jobInnServer = game.GetFormFromFile(0x0DEE93, "Skyrim.esm") as faction
	FavorJobsBeggarFaction = game.GetFormFromFile(0x060028, "Skyrim.esm") as faction
	MarkarthTempleofDibellaFaction = game.GetFormFromFile(0x0656EA, "Skyrim.esm") as faction

	virginitychance = game.GetFormFromFile(0x00182D, "OVirginity.esp") as GlobalVariable 

	ocum = game.GetFormFromFile(0x000800, "OCum.esp") as ocumscript

	setVirginity(game.getplayer(), true)
	console("Virginity chance: "  + getvirginitychance())
	OnLoad()
EndEvent

int function GetVirginityChance()
	return virginitychance.GetValue() as int
EndFunction


bool function isVirgin(actor npc)
	int lookup = GetNPCDataInt(npc, IsVirginKey)
	;1 Yes, virgin
	;0 No, not virgin
	;-1 Not yet calculated

	if lookup == 1
		return true
	elseif lookup == 0
		return false
	elseif lookup == -1
		return calculateVirginity(npc)
	endif
EndFunction

function setVirginity(actor npc, bool virgin, bool fx = false)
	int virginnum
	if virgin
		virginnum = 1
	else
		virginnum = 0
	endif

	StoreNPCDataInt(npc, IsVirginKey, virginnum)

	if fx && ostim.IsFemale(npc)
		debug.Notification(npc.GetDisplayName() + " has lost their virginity")
		ApplyBlood(npc)
		ostim.PlaySound(npc, hymenbreak)
	endif

endfunction

function ApplyBlood(actor act)
	ocum.CumOnto(act, "VagBlood")
EndFunction

Event OstimStart(string eventName, string strArg, float numArg, Form sender)
	bool domVirgin = isVirgin(ostim.GetDomActor())
	bool subVirgin = isVirgin(ostim.GetSubActor())
	bool thirdVirgin = false
	if ostim.GetThirdActor()
		thirdVirgin = isVirgin(ostim.GetThirdActor())
	endif	

	console(ostim.GetDomActor().GetDisplayName() + " virginity: " + domVirgin)
	console(ostim.GetSubActor().GetDisplayName() + " virginity: " + subVirgin)
	if ostim.GetThirdActor()
		console(ostim.GetThirdActor().GetDisplayName() + " virginity: " + thirdVirgin)
	endif	

	if !domVirgin && !subVirgin && !thirdVirgin
		console("OVirginity leaving thread early, no virgins found")
		return
	endif	

	while (ostim.AnimationRunning()) && (domVirgin || subVirgin || thirdVirgin)
		if ostim.GetCurrentAnimationClass() == "Sx"
			if domVirgin
				console("Dom actor virginity lost!")
				domVirgin = false
				setVirginity(ostim.GetDomActor(), false, true)
				SendModEvent("ovirginity_lost_dom")
			endif
			if subVirgin
				console("Sub actor virginity lost!")
				subVirgin = false
				setVirginity(ostim.GetSubActor(), false, true)
				SendModEvent("ovirginity_lost_sub")
			EndIf
			if thirdVirgin
				console("third actor virginity lost!")
				thirdVirgin = false
				setVirginity(ostim.GetthirdActor(), false, true)
				SendModEvent("ovirginity_lost_third")
			endif
		elseif (ostim.GetCurrentAnimationClass() == "Pf1") || (ostim.GetCurrentAnimationClass() == "Pf2")
			if subVirgin
				console("Sub actor virginity lost!")
				subVirgin = false
				setVirginity(ostim.GetSubActor(), false, true)
				SendModEvent("ovirginity_lost_sub")
			EndIf
		EndIf

		Utility.Wait(1)
	endwhile

	console("OV script closing out")
EndEvent


bool function calculateVirginity(actor npc)
	int chance = getvirginitychance()

	if isProstitute(npc)
		chance = 2
	endif

	if isMarried(npc)
		chance = 1
	endif

	if npc.GetRace() == OldPeopleRace
		chance = 3
	endif

	bool virgin = ostim.ChanceRoll(chance) 

	setVirginity(npc, virgin)

	return virgin
EndFunction

function StoreNPCDataInt(actor npc, string keys, int num)
	StorageUtil.SetIntValue(npc as form, keys, num)
	;console("Set value " + num + " for key " + keys)
EndFunction

int function GetNPCDataInt(actor npc, string keys)
	return StorageUtil.GetIntValue(npc, keys, -1)
EndFunction

Function OnLoad()
	RegisterForModEvent("ostim_start", "OstimStart")
EndFunction

bool function isProstitute(actor npc)
	return npc.IsInFaction(jobInnServer) || npc.IsInFaction(FavorJobsBeggarFaction) || npc.IsInFaction(MarkarthTempleofDibellaFaction)
EndFunction

bool function isMarried(actor npc)
	return npc.HasAssociation(Spouse)
endfunction	

function console(string in)
	OsexIntegrationMain.Console(in)
EndFunction