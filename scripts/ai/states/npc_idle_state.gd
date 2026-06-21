extends State
class_name NPCIdleState
## Бездействие: NPC стоит, изредка оглядывается. Переходит в Work если есть
## рабочая точка, или в Patrol по таймеру.

@export var idle_duration_min: float = 3.0
@export var idle_duration_max: float = 8.0
@export var look_interval: float = 2.0

var _idle_timer: float = 0.0
var _look_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_idle_timer = randf_range(idle_duration_min, idle_duration_max)
	_look_timer = look_interval
	if agent.has_method("play_animation"):
		agent.play_animation("idle")

func update(delta: float) -> void:
	_idle_timer -= delta
	_look_timer -= delta

	if _look_timer <= 0.0:
		_look_timer = look_interval
		_random_look()

	if _idle_timer <= 0.0:
		_decide_next()

func _random_look() -> void:
	# Случайный поворот спрайта — создаёт ощущение живости без движения.
	if agent.has_method("set_facing"):
		agent.set_facing([-1, 1].pick_random())

func _decide_next() -> void:
	var npc := agent as NPCController
	if npc == null:
		return
	if npc.has_work_point():
		transition_requested.emit(&"Work")
	else:
		transition_requested.emit(&"Patrol")
