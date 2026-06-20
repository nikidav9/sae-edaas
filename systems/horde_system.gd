extends Node
class_name HordeSystem
## Блуждающие орды зомби на карте мира.
##
## Орды двигаются по карте, реагируют на шум, могут выйти к базе. Разведчик
## (уникальное умение) видит приближение заранее. Для массовых юнитов на
## экране — object pooling и MultiMeshInstance2D (лимиты в GameBalance).

## Активные орды: id -> {"position": Vector2, "size": int, "target": Vector2}
var _hordes: Dictionary = {}
var _next_id: int = 1

func _ready() -> void:
	EventBus.noise_emitted.connect(_on_noise_emitted)
	EventBus.day_passed.connect(_on_day_passed)

func spawn_horde(position: Vector2, size: int) -> int:
	var id := _next_id
	_next_id += 1
	_hordes[id] = {"position": position, "size": size, "target": position}
	# Разведчик в группе → заранее предупреждаем игрока.
	if GameState.has_ability("scout_recon"):
		EventBus.horde_spotted.emit(id, position)
	return id

func _on_noise_emitted(position: Vector2, loudness: float) -> void:
	if loudness < GameState.balance.horde_noise_threshold:
		return
	# Ближайшие орды переориентируются на источник шума.
	for id in _hordes:
		_hordes[id]["target"] = position

func _on_day_passed(_day: int) -> void:
	# Дневной тик движения/проверки подхода к базе — заглушка под реализацию.
	for id in _hordes:
		var horde: Dictionary = _hordes[id]
		if GameState.has_ability("scout_recon"):
			EventBus.horde_approaching.emit(id, GameState.balance.scout_horde_warning_days)
