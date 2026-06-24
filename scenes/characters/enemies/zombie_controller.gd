extends CharacterBody2D
class_name ZombieController
## Экземпляр зомби, управляемый StateMachine из 4 состояний.
##
## Создаётся пулом (ZombiePool) и переиспользуется. reinitialize() сбрасывает
## всё состояние при повторном acquire(). Смерть → release() обратно в пул.

## Уникальный ID в пределах текущей сессии (присваивается пулом).
var zombie_id: int = 0
## Данные типа зомби (walker, runner, …).
var enemy_data: EnemyData = null
## Куда привлечён стимулом (AtractedState читает/пишет).
var attraction_target: Vector2 = Vector2.ZERO

## Ссылки на системы — задаются ZombiePool.acquire().
var herd_manager: HerdManager = null
var stimulus_system: StimulusSystem = null
var zombie_pool: ZombiePool = null

var health: int = 30
var is_dead: bool = false

@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	# Сцена используется как прогретый пул — не инициализируем до reinitialize().
	pass

## Вызывается ZombiePool.acquire() после установки всех полей.
func reinitialize() -> void:
	is_dead = false
	attraction_target = Vector2.ZERO
	if enemy_data != null:
		health = enemy_data.max_health
	else:
		health = 30
	# Регистрируемся в HerdManager.
	if herd_manager != null:
		herd_manager.register_zombie(zombie_id, global_position)
	# Запускаем FSM с начального состояния.
	if state_machine != null:
		state_machine.transition_to(&"Wander")

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	if herd_manager != null:
		herd_manager.unregister_zombie(zombie_id)
	if zombie_pool != null:
		zombie_pool.release(self)
