extends CharacterBody2D
class_name PlayerController
## Персонаж игрока: движение (джойстик / WASD), добыча ресурсов удержанием, ближний бой.

var health: int = 100
var _max_health: int = 100
var _attack_cooldown: float = 0.0
var _facing: Vector2 = Vector2.DOWN

var joystick: VirtualJoystick = null

@onready var attack_area: Area2D = $AttackArea

# --- Добыча ресурсов ---
var _gather_target: ResourceNode = null
var _is_holding_action: bool = false
var _interaction_timer: float = 0.0
var _last_prompt_id: int = -1

signal health_changed(new_hp: int, max_hp: int)

func _ready() -> void:
	add_to_group("player")
	_max_health = GameState.balance.player_max_health
	health = _max_health

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_move(delta)
	_tick_gather(delta)
	_interaction_timer -= delta
	if _interaction_timer <= 0.0:
		_interaction_timer = 0.2
		_update_interaction_prompt()

func _move(_delta: float) -> void:
	var dir := Vector2.ZERO
	if joystick != null:
		dir = joystick.get_direction()
	if dir.length() > 0.1:
		_facing = dir.normalized()
		velocity = _facing * GameState.balance.player_move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, GameState.balance.player_move_speed)
	move_and_slide()

# --- Контекстная кнопка действия (атака / добыча) ---

## button_down — либо начинаем добычу, либо атакуем.
func start_action() -> void:
	var resource := _get_nearest_resource(64.0)
	if resource != null:
		_gather_target = resource
		_is_holding_action = true
	else:
		swing()

## button_up — отменяем добычу если шла.
func stop_action() -> void:
	if _gather_target != null:
		_gather_target.cancel_gather()
	_gather_target = null
	_is_holding_action = false

func _tick_gather(delta: float) -> void:
	if not _is_holding_action or _gather_target == null:
		return
	if not is_instance_valid(_gather_target) or _gather_target.is_depleted():
		stop_action()
		return
	if _gather_target.tick_gather(delta):
		_gather_target = null
		_is_holding_action = false

# --- Ближний бой ---

func swing() -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = GameState.balance.player_attack_cooldown
	attack_area.position = _facing * GameState.balance.player_attack_range
	for body in attack_area.get_overlapping_bodies():
		if body is ZombieController:
			(body as ZombieController).take_damage(GameState.balance.player_attack_damage)
		elif body is RaiderController:
			(body as RaiderController).take_damage(GameState.balance.player_attack_damage)
	EventBus.noise_emitted.emit(global_position, 0.6)

# --- Урон ---

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	EventBus.player_damaged.emit(amount, health)
	health_changed.emit(health, _max_health)
	if health <= 0:
		EventBus.player_died.emit()

# --- Поиск ближайшего ресурса ---

func _get_nearest_resource(max_dist: float) -> ResourceNode:
	var nearest: ResourceNode = null
	var min_dist := max_dist
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if not is_instance_valid(node):
			continue
		var rn := node as ResourceNode
		if rn == null or rn.is_depleted():
			continue
		var d := global_position.distance_to(rn.global_position)
		if d < min_dist:
			min_dist = d
			nearest = rn
	return nearest

func _update_interaction_prompt() -> void:
	var resource := _get_nearest_resource(64.0)
	var new_id: int = resource.get_instance_id() if resource != null else -1
	if new_id == _last_prompt_id:
		return
	_last_prompt_id = new_id
	if resource != null:
		var names := {
			ResourceNode.NodeType.TREE: "Дерево",
			ResourceNode.NodeType.ROCK: "Камень",
			ResourceNode.NodeType.BUSH: "Куст",
		}
		var n: String = names.get(resource.node_type, "Ресурс")
		EventBus.interaction_prompt_changed.emit("Удержи ⚒ — %s ×%d" % [n, resource.amount])
	else:
		EventBus.interaction_prompt_changed.emit("")
