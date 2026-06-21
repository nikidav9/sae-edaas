extends State
class_name ZombieAttractedState
## Зомби привлечён стимулом и бежит к нему.
## Если стимул угас — возвращается к блужданию.
## Если рядом появляются другие зомби — переходит в стадное поведение.

const ARRIVE_DIST := 24.0
const RECHECK_INTERVAL := 0.5
const LOST_TARGET_DIST := 32.0

var _recheck_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_recheck_timer = 0.0

func physics_update(delta: float) -> void:
	var z := agent as ZombieController
	if z == null:
		return

	# Обновляем стадо.
	if z.herd_manager != null:
		z.herd_manager.update_zombie_position(z.zombie_id, z.global_position)
		if z.herd_manager.get_herd_size(z.zombie_id) > 1:
			transition_requested.emit(&"Herd")
			return

	# Периодически ищем актуальный стимул.
	_recheck_timer -= delta
	if _recheck_timer <= 0.0:
		_recheck_timer = RECHECK_INTERVAL
		_recheck_stimulus(z)

	# Если цель достигнута или потеряна — блуждать.
	if z.attraction_target == Vector2.ZERO:
		transition_requested.emit(&"Wander")
		return
	if z.global_position.distance_to(z.attraction_target) < ARRIVE_DIST:
		z.attraction_target = Vector2.ZERO
		transition_requested.emit(&"Wander")
		return

	_move_toward(z, z.attraction_target, GameState.balance.zombie_attracted_speed)

func _recheck_stimulus(z: ZombieController) -> void:
	if z.stimulus_system == null or z.enemy_data == null:
		z.attraction_target = Vector2.ZERO
		return
	var max_r := maxf(z.enemy_data.hearing_radius,
		maxf(z.enemy_data.smell_radius, z.enemy_data.light_attraction_range))
	var stim := z.stimulus_system.strongest_near(z.attraction_target, max_r * 0.5)
	if stim != null and stim.strength >= GameState.balance.horde_noise_threshold:
		# Обновляем цель на более актуальный стимул.
		z.attraction_target = stim.position
	else:
		# Стимул исчез.
		z.attraction_target = Vector2.ZERO

func _move_toward(z: ZombieController, target: Vector2, speed: float) -> void:
	var dir := (target - z.global_position).normalized()
	z.velocity = dir * speed
	z.move_and_slide()
