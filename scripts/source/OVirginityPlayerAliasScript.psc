ScriptName OVirginityPlayerAliasScript Extends ReferenceAlias

OVirginityScript Property OVirginity Auto

Event OnInit()
	OVirginity = (GetOwningQuest()) as OVirginityScript
EndEvent

Event OnPlayerLoadGame()
	OVirginity.onload()
EndEvent
