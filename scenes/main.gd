extends Node
## Корневой узел игры. Поднимает игровые системы как дочерние узлы.
##
## Системы живут здесь (не в autoload/), как требует архитектура: autoload —
## только GameState/EventBus/SaveSystem/NotificationManager. Системы общаются
## между собой исключительно через EventBus.

var noise_system: NoiseSystem
var horde_system: HordeSystem
var visitor_system: VisitorSystem
var morale_system: MoraleSystem
var day_night_system: DayNightSystem
var dialogue_system: DialogueSystem
var npc_manager: NPCManager
var building_system: BuildingSystem

func _ready() -> void:
	noise_system = NoiseSystem.new()
	noise_system.name = "NoiseSystem"
	add_child(noise_system)

	horde_system = HordeSystem.new()
	horde_system.name = "HordeSystem"
	add_child(horde_system)

	visitor_system = VisitorSystem.new()
	visitor_system.name = "VisitorSystem"
	add_child(visitor_system)

	morale_system = MoraleSystem.new()
	morale_system.name = "MoraleSystem"
	add_child(morale_system)

	day_night_system = DayNightSystem.new()
	day_night_system.name = "DayNightSystem"
	add_child(day_night_system)

	dialogue_system = DialogueSystem.new()
	dialogue_system.name = "DialogueSystem"
	add_child(dialogue_system)

	npc_manager = NPCManager.new()
	npc_manager.name = "NPCManager"
	add_child(npc_manager)

	building_system = BuildingSystem.new()
	building_system.name = "BuildingSystem"
	add_child(building_system)
