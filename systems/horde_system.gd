extends Node
class_name HordeSystem
## Управляет спавном зомби-орд на карте мира.
##
## При spawn_horde() активирует зомби из ZombiePool вокруг точки спавна.
## Реагирует на шум через StimulusSystem → HerdManager.

const WALKER_DATA := preload("res://resources/enemy_data/zombie_walker.tres")
const SPAWN_SCATTER := 48.0  # Радиус разброса зомби в пятне орды.

## Задаются из main.gd после создания всех систем.
var zombie_pool: ZombiePool = null
var herd_manager: HerdManager = null

## Активные орды для разведчика: id → {"position": Vector2, "size": int}
var _hordes: Dictionary = {}
var _next_horde_id: int = 1

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)

## Спавнит орду size зомби вокруг position.
## Возвращает id орды для дальнейшего отслеживания.
func spawn_horde(position: Vector2, size: int) -> int:
	var horde_id := _next_horde_id
	_next_horde_id += 1
	_hordes[horde_id] = {"position": position, "size": size}

	# Разведчик в ростере — предупреждаем заранее.
	if GameState.has_ability("scout_recon"):
		EventBus.horde_spotted.emit(horde_id, position)

	if zombie_pool == null:
		return horde_id

	var spawned := 0
	for _i in size:
		if zombie_pool.active_count() >= GameState.balance.max_active_zombies:
			break
		var angle := randf() * TAU
		var dist := randf_range(0.0, SPAWN_SCATTER)
		var pos := position + Vector2(cos(angle), sin(angle)) * dist
		var z := zombie_pool.acquire(pos, WALKER_DATA)
		if z != null:
			spawned += 1

	return horde_id

func _on_day_passed(day: int) -> void:
	if GameState.has_ability("scout_recon") and not _hordes.is_empty():
		for horde_id in _hordes:
			EventBus.horde_approaching.emit(horde_id, GameState.balance.scout_horde_warning_days)
