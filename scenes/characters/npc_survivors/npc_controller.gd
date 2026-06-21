extends CharacterBody2D
class_name NPCController
## Игровой объект одного выжившего NPC в базе лагеря.
##
## Данные (имя, умение, характеристики) — в NPCData.
## Поведение — в StateMachine (Idle / Work / Patrol).
## Связь с миром — только через EventBus и публичные методы.

@export var npc_data: NPCData

@onready var npc_visual: NPCVisual = $NPCVisual
@onready var name_label: Label = $NameLabel
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var state_machine: StateMachine = $StateMachine

var _work_point: Node2D = null
var current_loyalty: float = 0.6

const MOVE_SPEED: float = 80.0

func _ready() -> void:
	if npc_data:
		_apply_data()
	EventBus.morale_changed.connect(_on_morale_changed)
	EventBus.day_passed.connect(_on_day_passed)

func _apply_data() -> void:
	name_label.text = npc_data.display_name
	current_loyalty = npc_data.base_loyalty
	npc_visual.setup(npc_data)
	if npc_data.ability_id == &"scout_recon":
		var patrol_state := state_machine.find_child("Patrol") as NPCPatrolState
		if patrol_state:
			patrol_state.patrol_radius = 192.0

func _physics_process(_delta: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var target := nav_agent.get_next_path_position()
		var direction := (target - global_position).normalized()
		velocity = direction * MOVE_SPEED
		set_facing(sign(direction.x) as int)
	npc_visual.set_moving(velocity.length_squared() > 4.0)
	move_and_slide()

# --- API для State Machine ---

func navigate_to(pos: Vector2) -> void:
	nav_agent.target_position = pos

func navigation_finished() -> bool:
	return nav_agent.is_navigation_finished()

func has_work_point() -> bool:
	return _work_point != null and is_instance_valid(_work_point)

func work_point_position() -> Vector2:
	return _work_point.global_position if has_work_point() else global_position

func assign_work_point(point: Node2D) -> void:
	_work_point = point

func play_animation(anim_name: String) -> void:
	npc_visual.set_moving(anim_name == "walk")

func set_facing(direction: int) -> void:
	npc_visual.set_facing(direction)

# --- Лояльность ---

func _on_morale_changed(new_morale: float, _delta: float) -> void:
	if new_morale < 0.3:
		_change_loyalty(-0.02)

func _on_day_passed(_day: int) -> void:
	_check_food_upkeep()

func _check_food_upkeep() -> void:
	if npc_data == null:
		return
	if GameState.can_afford("food", npc_data.food_upkeep):
		GameState.change_resource("food", -npc_data.food_upkeep)
		_change_loyalty(0.01)
	else:
		_change_loyalty(-0.1)

func _change_loyalty(delta: float) -> void:
	current_loyalty = clampf(current_loyalty + delta, 0.0, 1.0)
	if current_loyalty <= 0.0:
		_leave()

func _leave() -> void:
	if npc_data:
		EventBus.npc_lost.emit(npc_data, "deserted")
	queue_free()
