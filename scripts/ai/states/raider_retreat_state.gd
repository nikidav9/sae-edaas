extends State
class_name RaiderRetreatState
## Рейдер убегает с базы в случайном направлении.
## После достаточного расстояния — исчезает (удаляется из сцены).

const FLEE_DISTANCE := 600.0
const FLEE_SPEED_MULT := 1.3

var _start_pos: Vector2 = Vector2.ZERO

func enter(_msg: Dictionary = {}) -> void:
	var r := agent as RaiderController
	if r:
		_start_pos = r.global_position

func physics_update(_delta: float) -> void:
	var r := agent as RaiderController
	if r == null:
		return

	var base_pos: Vector2 = r.raid_system.base_position if r.raid_system else Vector2.ZERO
	var flee_dir: Vector2
	if base_pos != Vector2.ZERO:
		flee_dir = (r.global_position - base_pos).normalized()
	else:
		flee_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	r.velocity = flee_dir * GameState.balance.raider_move_speed * FLEE_SPEED_MULT
	r.move_and_slide()

	if r.global_position.distance_to(_start_pos) > FLEE_DISTANCE:
		r.despawn()
