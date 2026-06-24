extends State
class_name RaiderApproachState
## Рейдер движется к базе. Если нашёл цель в радиусе атаки — переходит к атаке.

const ATTACK_RANGE := 52.0

func physics_update(_delta: float) -> void:
	var r := agent as RaiderController
	if r == null:
		return

	var base_pos: Vector2 = r.raid_system.base_position if r.raid_system else Vector2.ZERO
	if base_pos == Vector2.ZERO:
		return

	# Переход к атаке если достаточно близко.
	if r.global_position.distance_to(base_pos) <= ATTACK_RANGE:
		transition_requested.emit(&"Attack")
		return

	var dir := (base_pos - r.global_position).normalized()
	r.velocity = dir * GameState.balance.raider_move_speed
	r.move_and_slide()
