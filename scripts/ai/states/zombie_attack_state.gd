extends State
class_name ZombieAttackState
## Зомби атакует базу: наносит урон морали группы и испускает сигнал base_attacked.
## Если отступает за пределы attack_range — возвращается в Herd.

var _attack_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_attack_timer = 0.0

func physics_update(delta: float) -> void:
	var z := agent as ZombieController
	if z == null:
		return

	var b := GameState.balance
	var base_pos: Vector2 = Vector2.ZERO
	if z.herd_manager != null:
		base_pos = z.herd_manager.base_position

	# Проверяем, что всё ещё в зоне атаки.
	if base_pos != Vector2.ZERO and z.global_position.distance_to(base_pos) > b.zombie_attack_range * 3.0:
		transition_requested.emit(&"Herd")
		return

	# Движемся к базе.
	if base_pos != Vector2.ZERO:
		var dir := (base_pos - z.global_position).normalized()
		z.velocity = dir * (b.zombie_herd_speed * 0.7)
		z.move_and_slide()

	# Атакуем по интервалу.
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = b.zombie_attack_interval
		_do_attack(b)

func _do_attack(b: GameBalance) -> void:
	EventBus.base_attacked.emit(1)
	GameState.change_morale(-b.zombie_attack_morale_loss)
