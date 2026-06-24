extends Node
class_name NoiseSystem
## Шум-механика.
##
## Действия (выстрел снайпера, работа механика) создают шум. Орды слышат шум
## в радиусе и тянутся к источнику. Система — посредник: принимает событие шума
## и сообщает заинтересованным (horde_system слушает horde-логику отдельно).

func _ready() -> void:
	EventBus.noise_emitted.connect(_on_noise_emitted)

## Удобный вход для геймплейного кода: создать шум в точке.
func emit_noise(position: Vector2, loudness: float) -> void:
	EventBus.noise_emitted.emit(position, clampf(loudness, 0.0, 1.0))

func _on_noise_emitted(position: Vector2, loudness: float) -> void:
	# Орды реагируют только на шум выше порога (баланс, не хардкод).
	if loudness < GameState.balance.horde_noise_threshold:
		return
	# Здесь horde_system (или сами орды) подхватят и сменят курс.
	# Логику движения держим в horde_system, чтобы не дублировать.
	pass
