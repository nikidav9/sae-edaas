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

# --- Зомби-системы ---
var stimulus_system: StimulusSystem
var herd_manager: HerdManager
var zombie_pool: ZombiePool

func _ready() -> void:
	noise_system = NoiseSystem.new()
	noise_system.name = "NoiseSystem"
	add_child(noise_system)

	# Зомби-системы: порядок важен — stimulus → herd → pool → horde.
	stimulus_system = StimulusSystem.new()
	stimulus_system.name = "StimulusSystem"
	add_child(stimulus_system)

	herd_manager = HerdManager.new()
	herd_manager.name = "HerdManager"
	add_child(herd_manager)

	zombie_pool = ZombiePool.new()
	zombie_pool.name = "ZombiePool"
	add_child(zombie_pool)

	# Связываем зависимости после создания всех узлов.
	herd_manager.zombie_pool = zombie_pool
	zombie_pool.herd_manager = herd_manager
	zombie_pool.stimulus_system = stimulus_system

	horde_system = HordeSystem.new()
	horde_system.name = "HordeSystem"
	horde_system.zombie_pool = zombie_pool
	horde_system.herd_manager = herd_manager
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

## Вызывается WorldMap после генерации — устанавливает позицию базы.
func set_base_position(pos: Vector2) -> void:
	npc_manager.base_position = pos
	herd_manager.base_position = pos
