extends State
class_name NPCWorkState
## NPC движется к рабочей точке и выполняет свою уникальную работу.
## Анимация и эффект определяются ability_id из NPCData.

## Сколько секунд работает прежде чем вернуться в Idle.
@export var work_cycle_seconds: float = 20.0

var _work_timer: float = 0.0
var _arrived: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_arrived = false
	_work_timer = work_cycle_seconds
	var npc := agent as NPCController
	if npc and npc.has_work_point():
		npc.navigate_to(npc.work_point_position())
	if agent.has_method("play_animation"):
		agent.play_animation("walk")

func update(delta: float) -> void:
	var npc := agent as NPCController
	if npc == null:
		return

	if not _arrived:
		if npc.navigation_finished():
			_arrived = true
			_start_working(npc)
		return

	_work_timer -= delta
	if _work_timer <= 0.0:
		transition_requested.emit(&"Idle")

func _start_working(npc: NPCController) -> void:
	var anim := _work_animation(npc.npc_data.ability_id if npc.npc_data else &"")
	if npc.has_method("play_animation"):
		npc.play_animation(anim)
	# Механик шумит при работе → эмитим шум.
	if npc.npc_data and npc.npc_data.ability_id == &"mechanic_traps":
		EventBus.noise_emitted.emit(npc.global_position, 0.4)

func _work_animation(ability_id: StringName) -> String:
	match ability_id:
		&"tower_sniper":   return "aim"
		&"mechanic_traps": return "craft"
		&"medic_heal":     return "tend"
		&"scout_recon":    return "scan"
		&"farmer_food":    return "farm"
		_:                 return "work"
