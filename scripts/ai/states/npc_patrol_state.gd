extends State
class_name NPCPatrolState
## NPC обходит точки патруля по периметру базы.
## Разведчик патрулирует дальше (больший радиус) — задаётся через patrol_radius.

## Точки патруля задаются родительским NPCManager'ом или берутся случайно
## в радиусе от позиции базы.
@export var patrol_radius: float = 96.0
@export var points_count: int = 3
@export var wait_at_point: float = 1.5

var _patrol_points: Array[Vector2] = []
var _current_point: int = 0
var _waiting: bool = false
var _wait_timer: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	# Можно передать точки снаружи через msg["points"].
	if msg.has("points"):
		_patrol_points.assign(msg["points"])
	else:
		_generate_points()
	_current_point = 0
	_navigate_current()

func update(delta: float) -> void:
	var npc := agent as NPCController
	if npc == null:
		return

	if _waiting:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_waiting = false
			_current_point = (_current_point + 1) % _patrol_points.size()
			_navigate_current()
		return

	if npc.navigation_finished():
		_waiting = true
		_wait_timer = wait_at_point
		if agent.has_method("play_animation"):
			agent.play_animation("idle")

func _navigate_current() -> void:
	if _patrol_points.is_empty():
		transition_requested.emit(&"Idle")
		return
	var npc := agent as NPCController
	if npc:
		npc.navigate_to(_patrol_points[_current_point])
	if agent.has_method("play_animation"):
		agent.play_animation("walk")

func _generate_points() -> void:
	_patrol_points.clear()
	var npc := agent as NPCController
	var origin := npc.global_position if npc else Vector2.ZERO
	for i in points_count:
		var angle := (TAU / points_count) * i + randf() * 0.4
		_patrol_points.append(origin + Vector2(cos(angle), sin(angle)) * patrol_radius)
