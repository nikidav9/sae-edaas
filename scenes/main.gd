extends Node
## Корневой узел игры. Поднимает все игровые системы как дочерние узлы.
##
## Порядок создания: сначала системы без зависимостей, затем те что нужны
## другим системам. Связи между системами устанавливаются после add_child().

const RESOURCE_NODE_SCENE := preload("res://scenes/world/resource_node.tscn")

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
var base_grid: BaseGrid

@onready var player: PlayerController = $PlayerController
@onready var joystick: VirtualJoystick = $GameUI/VirtualJoystick
@onready var expedition_panel: ExpeditionPanel = $ExpeditionPanel
@onready var crafting_panel_node: CraftingPanel = $CraftingPanel

func _ready() -> void:
	# --- Базовые системы ---
	noise_system = NoiseSystem.new()
	noise_system.name = "NoiseSystem"
	add_child(noise_system)

	stimulus_system = StimulusSystem.new()
	stimulus_system.name = "StimulusSystem"
	add_child(stimulus_system)

	# --- Стадо зомби ---
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

	# --- Строительство ---
	base_grid = BaseGrid.new()
	base_grid.name = "BaseGrid"
	add_child(base_grid)

	building_system = BuildingSystem.new()
	building_system.name = "BuildingSystem"
	building_system.grid = base_grid
	add_child(building_system)

	expedition_system = ExpeditionSystem.new()
	expedition_system.name = "ExpeditionSystem"
	add_child(expedition_system)

	audio_system = AudioSystem.new()
	audio_system.name = "AudioSystem"
	add_child(audio_system)

	# --- Навигация для NPC ---
	_setup_navigation()

	# --- Игрок ---
	if player and joystick:
		player.joystick = joystick

	# --- Кнопка действия (контекстно: добыча / атака) ---
	var action_btn := get_node_or_null("GameUI/AttackButton") as Button
	if action_btn:
		action_btn.button_down.connect(_on_action_button_down)
		action_btn.button_up.connect(_on_action_button_up)

	# --- Экспедиции ---
	if expedition_panel:
		expedition_panel.setup(expedition_system)

	# --- Крафт ---
	if crafting_panel_node:
		crafting_panel_node.setup(building_system)

	# --- Ресурсные узлы на карте ---
	_spawn_resources()

## Вызывается WorldMap после генерации карты.
func set_base_position(pos: Vector2) -> void:
	npc_manager.base_position = pos
	herd_manager.base_position = pos
	raid_system.base_position = pos

# --- Кнопка действия ---

func _on_action_button_down() -> void:
	if player:
		player.start_action()

func _on_action_button_up() -> void:
	if player:
		player.stop_action()

# --- Навигационная область для NPC ---

func _setup_navigation() -> void:
	var nav_region := NavigationRegion2D.new()
	nav_region.name = "NavRegion"
	var nav_poly := NavigationPolygon.new()
	var outline := PackedVector2Array([
		Vector2(-600, -400), Vector2(600, -400),
		Vector2(600, 400), Vector2(-600, 400)
	])
	nav_poly.add_outline(outline)
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly
	add_child(nav_region)

# --- Ресурсные узлы ---

func _spawn_resources() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	# Деревья — 14 штук
	for i in 14:
		_place_node(rng, ResourceNode.NodeType.TREE, 90.0, 360.0)
	# Камни — 7 штук
	for i in 7:
		_place_node(rng, ResourceNode.NodeType.ROCK, 110.0, 380.0)
	# Кусты — 10 штук (ближе, чтобы еду было легче найти)
	for i in 10:
		_place_node(rng, ResourceNode.NodeType.BUSH, 70.0, 300.0)

func _place_node(rng: RandomNumberGenerator, type: ResourceNode.NodeType,
		min_dist: float, max_dist: float) -> void:
	var node := RESOURCE_NODE_SCENE.instantiate() as ResourceNode
	node.node_type = type
	var angle := rng.randf() * TAU
	var dist := rng.randf_range(min_dist, max_dist)
	node.position = Vector2(cos(angle), sin(angle)) * dist
	add_child(node)
