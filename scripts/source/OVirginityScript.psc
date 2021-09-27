ScriptName OVirginityScript Extends Quest
import outils 

;needs StorageUtils from papyrusutils
;int property virginitychance auto

string IsVirginKey = "IsVirgin"
string HymenKey = "IsVirgin"
spell menstruationspell
sound hymenbreak

faction jobInnServer
faction FavorJobsBeggarFaction
faction MarkarthTempleofDibellaFaction
faction ovProstitute

AssociationType property Spouse Auto
race property OldPeopleRace auto

OsexIntegrationMain ostim 


ocumscript ocum

bool Property ShowHymen
	bool Function Get()
		return StorageUtil.GetIntValue(none, "ovirginity.showhymen") as bool
	EndFunction

	Function Set(bool val)
		StorageUtil.SetIntValue(none, "ovirginity.showhymen", val as int)
	EndFunction
EndProperty

int Property virginityChance
	int Function Get()
		return StorageUtil.GetIntValue(none, "ovirginity.virginityChance") 
	EndFunction

	Function Set(int val)
		StorageUtil.SetIntValue(none, "ovirginity.virginityChance", val)
	EndFunction
EndProperty

Event OnInit()

	IsVirginKey = "IsVirgin"
	HymenKey = "HasHymen"

	ostim = outils.getostim()

	menstruationspell = GetFormFromFile(0x000804, "OVirginity.esp") as spell
	hymenbreak = GetFormFromFile(0x000D68, "OVirginity.esp") as sound

	jobInnServer = game.GetFormFromFile(0x0DEE93, "Skyrim.esm") as faction
	FavorJobsBeggarFaction = game.GetFormFromFile(0x060028, "Skyrim.esm") as faction
	MarkarthTempleofDibellaFaction = game.GetFormFromFile(0x0656EA, "Skyrim.esm") as faction
	ovProstitute = GetFormFromFile(0x0805, "ovirginity.esp") as faction

	virginitychance = 30
	ShowHymen = true

	ocum = game.GetFormFromFile(0x000800, "OCum.esp") as ocumscript

	if GetNPCDataInt(game.GetPlayer(), IsVirginKey) == -1
		setVirginity(game.getplayer(), true)
	endif 

	console("Virginity chance: "  + virginitychance)
	OnLoad()

	outils.RegisterForOUpdate(self)
	debug.Notification("OVirginity installed")
	console("OVirginity installed")
EndEvent




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
		if AppearsFemale(npc) ;using appears for speed
			StoreNPCDataBool(npc, HymenKey, true)
		endif 
	else
		virginnum = 0
	endif

	StoreNPCDataInt(npc, IsVirginKey, virginnum)

	if fx && ostim.IsFemale(npc)
		debug.Notification(OSANative.GetDisplayName(npc) + " has lost their virginity")
		BreakHymen(npc)
	endif

endfunction

Function BreakHymen(actor npc)
	if !GetNPCDataBool(npc, HymenKey)
		Console("Hymen already broken")
		return 
	endif 
	if !ShowHymen
		console("fx disabled")
		return 
	endif 
	ApplyBlood(npc)
	ostim.PlaySound(npc, hymenbreak)
EndFunction

function ApplyBlood(actor act)
	ocum.CumOnto(act, "VagBlood")
EndFunction

bool domVirgin
bool subVirgin
bool thirdVirgin

Event OstimStart(string eventName, string strArg, float numArg, Form sender)


	actor[] acts = ostim.GetActors()

	domVirgin = isVirgin(acts[0])
	subvirgin = false
	if acts.length > 1
		subvirgin = isVirgin(acts[1])
	endif
	thirdVirgin = false
	if acts.length > 2
		thirdVirgin = isVirgin(acts[2])
	endif	

	console(osanative.getdisplayname(acts[0]) + " virginity: " + domVirgin)
	if acts.length > 1
		console(osanative.getdisplayname(acts[1]) + " virginity: " + subVirgin)
	endif
	if acts.length > 2
		console(osanative.getdisplayname(acts[2]) + " virginity: " + thirdVirgin)
	endif	

	if !domVirgin && !subVirgin && !thirdVirgin
		console("OVirginity leaving thread early, no virgins found")
		return
	endif	

	ostim.AddSceneMetadata("hasvirgin")

	RegisterForModEvent("ostim_scenechanged_Sx", "OStimSceneChanged")
	RegisterForModEvent("ostim_scenechanged_Pf1", "OStimSceneChanged")
	RegisterForModEvent("ostim_scenechanged_Pf2", "OStimSceneChanged")
	;console("OV script closing out")
EndEvent


Event OStimSceneChanged(String EventName, String StrArg, Float NumArg, Form Sender)
	if ostim.HasSceneMetadata("hasvirgin")
		string cclass = ostim.GetCurrentAnimationClass() 
		if cclass == "Sx"
			if domVirgin
				if ostim.IsSoloScene() && ostim.IsFemale(ostim.GetDomActor())
					console("Dom actor hymen broke!")
					domVirgin = false
					BreakHymen(ostim.GetDomActor())
				else 
					console("Dom actor virginity lost!")
					domVirgin = false
					setVirginity(ostim.GetDomActor(), false, true)
					SendModEvent("ovirginity_lost_dom")
				endif 
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
		elseif (cclass == "Pf1") || (cclass == "Pf2")
			if domvirgin && ostim.IsSoloScene() && ostim.IsFemale(ostim.GetDomActor())
				console("Dom actor hymen broke!")
				domVirgin = false
				BreakHymen(ostim.GetDomActor())
			endif 

			if subVirgin
				console("Sub actor virginity lost!")
				subVirgin = false
				setVirginity(ostim.GetSubActor(), false, true)
				SendModEvent("ovirginity_lost_sub")
			EndIf
		endif 
	endif

EndEvent

bool function calculateVirginity(actor npc)
	int chance = virginityChance

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



Function OnLoad()
	RegisterForModEvent("ostim_start", "OstimStart")
EndFunction

bool function isProstitute(actor npc)
	return npc.IsInFaction(jobInnServer) || npc.IsInFaction(FavorJobsBeggarFaction) || npc.IsInFaction(MarkarthTempleofDibellaFaction) || npc.IsInFaction(ovProstitute)
EndFunction

bool function isMarried(actor npc)
	return npc.HasAssociation(Spouse)
endfunction	

