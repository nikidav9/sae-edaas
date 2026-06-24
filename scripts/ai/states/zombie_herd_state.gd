extends State
class_name ZombieHerdState
## Зомби движется в составе стада, используя флокинг (Boids).
##
## Три силы: сплочение (к центроиду), разделение (от соседей), выравнивание.
## Стадо движется к своей цели — которую игрок может перенаправить шумом.
## При появлении добычи в радиусе атаки — переходит в Attack.

const ATTACK_PROXIMITY := 80.0  # Расстояние до базы для перехода к атаке.

func physics_update(delta: float) -> void:
	var z := agent as ZombieController
	if z == null:
		return

	if z.herd_manager == null:
		transition_requested.emit(&"Wander")
		return

	# Обновляем позицию, чтобы HerdManager пересчитывал центроид стада.
	z.herd_manager.update_zombie_position(z.zombie_id, z.global_position)

	# Если остались в одиночестве — вернуться к блужданию.
	if z.herd_manager.get_herd_size(z.zombie_id) <= 1:
		transition_requested.emit(&"Wander")
		return

	# Проверка: база достаточно близко?
	var base_pos: Vector2 = z.herd_manager.base_position
	if base_pos != Vector2.ZERO and z.global_position.distance_to(base_pos) < ATTACK_PROXIMITY:
		transition_requested.emit(&"Attack")
		return

	var herd_target := z.herd_manager.get_herd_target(z.zombie_id)
	var centroid := z.herd_manager.get_herd_centroid(z.zombie_id)

	var steer := _compute_flocking(z, centroid, herd_target)
	z.velocity = steer
	z.move_and_slide()

func _compute_flocking(z: ZombieController, centroid: Vector2, herd_target: Vector2) -> Vector2:
	var b := GameState.balance
	var sep_r: float = b.flocking_separation_radius

	# 1. К цели стада.
	var to_target := (herd_target - z.global_position).normalized() if herd_target != z.global_position else Vector2.ZERO

	# 2. Сплочение — к центроиду стада.
	var cohesion := (centroid - z.global_position).normalized() if centroid != z.global_position else Vector2.ZERO

	# 3. Разделение — от соседних зомби в пуле.
	var separation := Vector2.ZERO
	if z.zombie_pool != null:
		var herd_id := z.herd_manager.get_herd_id_of(z.zombie_id)
		for zid in z.herd_manager.get_herd_members(herd_id):
			if zid == z.zombie_id:
				continue
			var other := z.zombie_pool.get_zombie_by_id(zid)
			if other == null or not is_instance_valid(other):
				continue
			var diff := z.global_position - other.global_position
			var d := diff.length()
			if d < sep_r and d > 0.0:
				separation += diff.normalized() * (sep_r - d) / sep_r

	# 4. Выравнивание — среднее направление стада (упрощённо: к цели).
	var alignment := to_target

	var composite := (
		to_target * 1.0 +
		cohesion * b.flocking_cohesion_weight +
		separation * b.flocking_separation_weight +
		alignment * b.flocking_alignment_weight
	).normalized()

	return composite * b.zombie_herd_speed
