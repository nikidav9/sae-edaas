extends Node
class_name StimulusSystem
## Агрегирует раздражители (шум, свет, запах) с затуханием по времени.
##
## Системы испускают стимулы через EventBus.noise_emitted или add_light/add_smell.
## Зомби запрашивают strongest_near() для поиска цели.

enum StimulusType { NOISE = 0, LIGHT = 1, SMELL = 2 }

class Stimulus:
	var id: int
	var type: int
	var position: Vector2
	var strength: float

	func _init(p_id: int, p_type: int, p_pos: Vector2, p_str: float) -> void:
		id = p_id
		type = p_type
		position = p_pos
		strength = p_str

var _stimuli: Array = []
var _next_id: int = 1

func _ready() -> void:
	EventBus.noise_emitted.connect(_on_noise_emitted)

func _process(delta: float) -> void:
	var decay: float = GameState.balance.stimulus_decay_per_second * delta
	var i := _stimuli.size() - 1
	while i >= 0:
		_stimuli[i].strength -= decay
		if _stimuli[i].strength <= 0.0:
			_stimuli.remove_at(i)
		i -= 1

func add_stimulus(type: int, position: Vector2, strength: float) -> int:
	var s := Stimulus.new(_next_id, type, position, strength)
	_next_id += 1
	_stimuli.append(s)
	EventBus.stimulus_emitted.emit(type, position, strength)
	return s.id

func add_light(position: Vector2, intensity: float) -> int:
	return add_stimulus(StimulusType.LIGHT, position, intensity)

func add_smell(position: Vector2, strength: float) -> int:
	return add_stimulus(StimulusType.SMELL, position, strength)

## Возвращает самый сильный стимул в радиусе radius от position, или null.
func strongest_near(position: Vector2, radius: float) -> Stimulus:
	var best: Stimulus = null
	var best_str := 0.0
	for s in _stimuli:
		if s.position.distance_to(position) <= radius and s.strength > best_str:
			best = s
			best_str = s.strength
	return best

## Возвращает лучший стимул с учётом разных радиусов на разные типы.
func strongest_near_typed(position: Vector2,
		noise_r: float, smell_r: float, light_r: float) -> Stimulus:
	var best: Stimulus = null
	var best_str := 0.0
	for s in _stimuli:
		var r := noise_r
		if s.type == StimulusType.SMELL:
			r = smell_r
		elif s.type == StimulusType.LIGHT:
			r = light_r
		if s.position.distance_to(position) <= r and s.strength > best_str:
			best = s
			best_str = s.strength
	return best

func _on_noise_emitted(position: Vector2, loudness: float) -> void:
	add_stimulus(StimulusType.NOISE, position, loudness)
