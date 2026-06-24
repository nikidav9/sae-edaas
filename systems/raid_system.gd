extends Node
class_name RaidSystem
## Планирует и проводит рейды враждебных людей на базу.
##
## Рейды начинаются после raid_min_day. Частота и размер растут с raider_reputation.
## Разведчик (scout_recon) предупреждает за N дней. Снайпер (tower_sniper) снижает размер.

const RAIDER_SCENE := preload("res://scenes/characters/enemies/raider_controller.tscn")
const SPAWN_RADIUS := 640.0  # Рейдеры появляются за периметром базы.

## Задаётся main.gd / WorldMap.
var base_position: Vector2 = Vector2.ZERO

var _days_until_raid: int = -1  # -1 = ещё не инициализировано
var _active_raiders: Array[RaiderController] = []
var _killed_count: int = 0

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)

func _on_day_passed(day: int) -> void:
	var b := GameState.balance
	if day < b.raid_min_day:
		return

	if _days_until_raid < 0:
		_schedule_next_raid()
		return

	_days_until_raid -= 1
	if _days_until_raid == 1 and GameState.has_ability("scout_recon"):
		var count := _calc_raid_count()
		EventBus.raid_incoming.emit(count)
	if _days_until_raid <= 0:
		_launch_raid()

func _schedule_next_raid() -> void:
	var b := GameState.balance
	var rep_factor := 1.0 - GameState.raider_reputation * 0.5  # репутация сокращает интервал
	_days_until_raid = maxi(1, int(b.raid_interval_days * rep_factor))

func _calc_raid_count() -> int:
	var b := GameState.balance
	var count := b.raid_base_count + int(GameState.raider_reputation * b.raid_reputation_scaling)
	# Снайпер на башне — сокращает размер рейда на треть.
	if GameState.has_ability("tower_sniper"):
		count = int(count * 0.67)
	return clampi(count, 1, b.raid_max_count)

func _launch_raid() -> void:
	var count := _calc_raid_count()
	_killed_count = 0
	EventBus.raid_started.emit(count)

	for i in count:
		var r := RAIDER_SCENE.instantiate() as RaiderController
		r.raid_system = self
		# Спавн по кругу вокруг базы.
		var angle := (float(i) / count) * TAU + randf() * 0.3
		r.global_position = base_position + Vector2(cos(angle), sin(angle)) * SPAWN_RADIUS
		get_parent().add_child(r)
		_active_raiders.append(r)

	_schedule_next_raid()

## Вызывается RaiderController при гибели.
func on_raider_killed(r: RaiderController) -> void:
	_active_raiders.erase(r)
	_killed_count += 1
	GameState.change_raider_reputation(0.05)
	_check_raid_end()

## Вызывается RaiderController при отступлении.
func on_raider_escaped(r: RaiderController) -> void:
	_active_raiders.erase(r)
	_check_raid_end()

func _check_raid_end() -> void:
	if _active_raiders.is_empty():
		var repelled := _killed_count > 0
		EventBus.raid_ended.emit(repelled)
		if repelled:
			GameState.change_morale(0.05)
