extends Node
## Корневой узел игры. Поднимает все игровые системы как дочерние узлы.
##
## Порядок создания: сначала системы без зависимостей, затем те что нужны
## другим системам. Связи между системами устанавливаются после add_child().

var noise_system: NoiseSystem
var horde_system: HordeSystem
var visitor_system: VisitorSystem
var morale_system: MoraleSystem
var day_night_system: DayNightSystem
var dialogue_system: DialogueSystem
var npc_manager: NPCManager
var building_system: BuildingSystem
var stimulus_system: StimulusSystem
var herd_manager: HerdManager
var zombie_pool: ZombiePool
var raid_system: RaidSystem
var expedition_system: ExpeditionSystem
var audio_system: AudioSystem

@onready var player: PlayerController = $PlayerController
@onready var joystick: VirtualJoystick = $GameUI/VirtualJoystick
@onready var expedition_panel: ExpeditionPanel = $ExpeditionPanel

func _ready() -> void:
	# --- Базовые системы (без зависимостей) ---
	noise_system = NoiseSystem.new()
	noise_system.name = "NoiseSystem"
	add_child(noise_system)

	stimulus_system = StimulusSystem.new()
	stimulus_system.name = "StimulusSystem"
	add_child(stimulus_system)

	# --- Стадо зомби (herd зависит от pool, pool создаётся следом) ---
	herd_manager = HerdManager.new()
	herd_manager.name = "HerdManager"
	add_child(herd_manager)

	zombie_pool = ZombiePool.new()
	zombie_pool.name = "ZombiePool"
	add_child(zombie_pool)

	herd_manager.zombie_pool = zombie_pool
	zombie_pool.herd_manager = herd_manager
	zombie_pool.stimulus_system = stimulus_system

	horde_system = HordeSystem.new()
	horde_system.name = "HordeSystem"
	horde_system.zombie_pool = zombie_pool
	horde_system.herd_manager = herd_manager
	add_child(horde_system)

	# --- Рейды ---
	raid_system = RaidSystem.new()
	raid_system.name = "RaidSystem"
	add_child(raid_system)

	# --- Социальные системы ---
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

	expedition_system = ExpeditionSystem.new()
	expedition_system.name = "ExpeditionSystem"
	add_child(expedition_system)

	audio_system = AudioSystem.new()
	audio_system.name = "AudioSystem"
	add_child(audio_system)

	# --- Связываем игрока с джойстиком ---
	if player and joystick:
		player.joystick = joystick

	# --- Кнопка атаки ---
	var attack_btn := get_node_or_null("GameUI/AttackButton") as Button
	if attack_btn:
		attack_btn.pressed.connect(_on_attack_button_pressed)

	# --- Связываем ExpeditioPanel с системой ---
	if expedition_panel:
		expedition_panel.setup(expedition_system)

## Вызывается WorldMap после генерации карты.
func set_base_position(pos: Vector2) -> void:
	npc_manager.base_position = pos
	herd_manager.base_position = pos
	raid_system.base_position = pos

## Кнопка атаки — вызывается из UI.
func _on_attack_button_pressed() -> void:
	if player:
		player.swing()
