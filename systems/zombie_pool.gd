extends Node
class_name ZombiePool
## Object-pool зомби. Держит max_active_zombies "спящих" экземпляров.
##
## acquire() активирует зомби и возвращает ссылку.
## release() выключает и возвращает в пул.
## Сцена инстанцируется ровно один раз на весь пул — без рантайм-аллокаций.

const ZOMBIE_SCENE := preload("res://scenes/characters/enemies/zombie_controller.tscn")

## Заполняется из main.gd после создания всех систем.
var herd_manager: HerdManager = null
var stimulus_system: StimulusSystem = null

var _pool: Array[ZombieController] = []
var _active: Dictionary = {}  # zombie_id → ZombieController
var _next_zombie_id: int = 1

func _ready() -> void:
	_prewarm()

func _prewarm() -> void:
	var max_z: int = GameState.balance.max_active_zombies
	for _i in max_z:
		var z := ZOMBIE_SCENE.instantiate() as ZombieController
		z.zombie_id = _next_zombie_id
		_next_zombie_id += 1
		z.set_process(false)
		z.set_physics_process(false)
		z.hide()
		add_child(z)
		_pool.append(z)

## Активирует зомби из пула в указанной позиции. Возвращает null если пул пуст.
func acquire(position: Vector2, enemy_data: EnemyData) -> ZombieController:
	if _pool.is_empty():
		return null
	var z := _pool.pop_back() as ZombieController
	z.global_position = position
	z.enemy_data = enemy_data
	z.herd_manager = herd_manager
	z.stimulus_system = stimulus_system
	z.zombie_pool = self
	z.show()
	z.set_process(true)
	z.set_physics_process(true)
	z.reinitialize()
	_active[z.zombie_id] = z
	return z

## Возвращает зомби в пул (вызывается из ZombieController._die).
func release(z: ZombieController) -> void:
	if not _active.has(z.zombie_id):
		return
	_active.erase(z.zombie_id)
	z.set_process(false)
	z.set_physics_process(false)
	z.hide()
	_pool.append(z)

func get_zombie_by_id(zombie_id: int) -> ZombieController:
	return _active.get(zombie_id, null)

func active_count() -> int:
	return _active.size()

func pool_free_count() -> int:
	return _pool.size()
