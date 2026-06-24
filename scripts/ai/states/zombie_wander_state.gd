extends State
class_name ZombieWanderState
## Зомби бесцельно бродит, пока не унюхает/услышит стимул или не увидит стадо.

const WANDER_RADIUS := 220.0
const ARRIVE_DIST := 18.0
const STIMULUS_CHECK_INTERVAL := 0.4

var _waypoint: Vector2 = Vector2.ZERO
var _has_waypoint: bool = false
var _stimulus_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_has_waypoint = false
	_stimulus_timer = randf_range(0.0, STIMULUS_CHECK_INTERVAL)

func physics_update(delta: float) -> void:
	var z := agent as ZombieController
	if z == null:
		return

	# Обновляем позицию в HerdManager — он сам определит, вступить ли в стадо.
	if z.herd_manager != null:
		z.herd_manager.update_zombie_position(z.zombie_id, z.global_position)
		if z.herd_manager.get_herd_size(z.zombie_id) > 1:
			transition_requested.emit(&"Herd")
			return

	# Периодическая проверка стимулов.
	_stimulus_timer -= delta
	if _stimulus_timer <= 0.0:
		_stimulus_timer = STIMULUS_CHECK_INTERVAL
		if _check_stimuli(z):
			return

	# Движение к случайной точке.
	if not _has_waypoint or z.global_position.distance_to(_waypoint) < ARRIVE_DIST:
		_pick_waypoint(z)

	_move_toward(z, _waypoint, GameState.balance.zombie_wander_speed)

func _check_stimuli(z: ZombieController) -> bool:
	if z.stimulus_system == null or z.enemy_data == null:
		return false
	var stim := z.stimulus_system.strongest_near_typed(
		z.global_position,
		z.enemy_data.hearing_radius,
		z.enemy_data.smell_radius,
		z.enemy_data.light_attraction_range
	)
	if stim != null and stim.strength >= GameState.balance.horde_noise_threshold:
		z.attraction_target = stim.position
		transition_requested.emit(&"Attracted")
		return true
	return false

func _pick_waypoint(z: ZombieController) -> void:
	var angle := randf() * TAU
	var dist := randf_range(40.0, WANDER_RADIUS)
	_waypoint = z.global_position + Vector2(cos(angle), sin(angle)) * dist
	_has_waypoint = true

func _move_toward(z: ZombieController, target: Vector2, speed: float) -> void:
	var dir := (target - z.global_position).normalized()
	z.velocity = dir * speed
	z.move_and_slide()
