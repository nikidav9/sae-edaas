extends State
class_name RaiderAttackState
## Рейдер атакует базу: наносит урон ресурсам и морали.
## Отступает если получил много урона или рейд провалился.

var _attack_timer: float = 0.0
const RETREAT_HP_THRESHOLD := 0.3  # Отступает при < 30% здоровья.

func enter(_msg: Dictionary = {}) -> void:
	_attack_timer = 0.0

func physics_update(delta: float) -> void:
	var r := agent as RaiderController
	if r == null:
		return

	# Отступление при низком HP.
	if float(r.health) / float(r.max_health) < RETREAT_HP_THRESHOLD:
		transition_requested.emit(&"Retreat")
		return

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = GameState.balance.zombie_attack_interval  # переиспользуем интервал атаки
		_do_attack(r)

func _do_attack(r: RaiderController) -> void:
	# Урон материалам/укреплениям базы.
	GameState.change_resource("materials", -1)
	GameState.change_morale(-0.02)
	EventBus.base_attacked.emit(1)
	# Шум от нападения (зомби тоже реагируют).
	EventBus.noise_emitted.emit(r.global_position, 0.7)
