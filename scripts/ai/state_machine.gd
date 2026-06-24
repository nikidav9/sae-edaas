extends Node
class_name StateMachine
## Простая машина состояний для NPC и зомби.
##
## Состояния — дочерние узлы типа State. Имя узла = имя состояния.
## Использование: положить StateMachine как ребёнка агента, внутрь — узлы State.

@export var initial_state: NodePath
## Агент, которым управляют состояния. Если пусто — берётся родитель машины.
@export var agent_path: NodePath

var current_state: State = null
var _states: Dictionary = {}
var _agent: Node = null

func _ready() -> void:
	_agent = get_node(agent_path) if not agent_path.is_empty() else get_parent()
	for child in get_children():
		if child is State:
			var s := child as State
			_states[s.name] = s
			s.agent = _agent
			s.transition_requested.connect(_on_transition_requested)
	if not initial_state.is_empty():
		current_state = get_node(initial_state) as State
		if current_state:
			current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	if not _states.has(state_name):
		push_warning("StateMachine: нет состояния '%s'" % state_name)
		return
	if current_state:
		current_state.exit()
	current_state = _states[state_name]
	current_state.enter(msg)

func _on_transition_requested(to_state_name: StringName) -> void:
	transition_to(to_state_name)
