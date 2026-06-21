extends Node
class_name HerdManager
## Управляет стадами зомби на карте.
##
## Каждый зомби принадлежит ровно одному стаду (даже если в нём он один).
## Стадо формируется автоматически при сближении зомби. Перенаправить стадо
## можно через redirect_herd() — именно это делает "отвлечение" как в TWD.

class Herd:
	var id: int
	var member_ids: Array[int] = []
	var centroid: Vector2 = Vector2.ZERO
	var target: Vector2 = Vector2.ZERO
	var has_custom_target: bool = false

	func _init(p_id: int, p_pos: Vector2) -> void:
		id = p_id
		centroid = p_pos
		target = p_pos

## Все активные стада: herd_id → Herd.
var _herds: Dictionary = {}
## Карта зомби → стадо: zombie_id → herd_id.
var _zombie_to_herd: Dictionary = {}
var _next_id: int = 1

## Ссылка на пул задаётся снаружи (main.gd) после создания.
var zombie_pool: ZombiePool = null
## Позиция базы — обновляется WorldMap при генерации.
var base_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	EventBus.stimulus_emitted.connect(_on_stimulus_emitted)
	EventBus.day_passed.connect(_on_day_passed)

func _physics_process(_delta: float) -> void:
	_update_centroids()
	_try_merge_nearby_herds()

# --- Публичный API ---

func register_zombie(zombie_id: int, position: Vector2) -> void:
	var herd := _create_herd(position)
	herd.member_ids.append(zombie_id)
	_zombie_to_herd[zombie_id] = herd.id

func unregister_zombie(zombie_id: int) -> void:
	if not _zombie_to_herd.has(zombie_id):
		return
	var herd_id: int = _zombie_to_herd[zombie_id]
	_zombie_to_herd.erase(zombie_id)
	if _herds.has(herd_id):
		var herd: Herd = _herds[herd_id]
		herd.member_ids.erase(zombie_id)
		if herd.member_ids.is_empty():
			_herds.erase(herd_id)
			EventBus.herd_dispersed.emit(herd_id)

## Вызывается из состояний зомби каждый physics_update для обновления членства.
func update_zombie_position(zombie_id: int, position: Vector2) -> void:
	var join_r: float = GameState.balance.zombie_join_herd_radius
	var my_herd_id: int = _zombie_to_herd.get(zombie_id, -1)
	for herd_id in _herds:
		if herd_id == my_herd_id:
			continue
		var herd: Herd = _herds[herd_id]
		if herd.centroid.distance_to(position) <= join_r:
			_join_herd(zombie_id, herd_id, my_herd_id)
			return

func get_herd_target(zombie_id: int) -> Vector2:
	var herd_id: int = _zombie_to_herd.get(zombie_id, -1)
	if _herds.has(herd_id):
		return _herds[herd_id].target
	return Vector2.ZERO

func get_herd_centroid(zombie_id: int) -> Vector2:
	var herd_id: int = _zombie_to_herd.get(zombie_id, -1)
	if _herds.has(herd_id):
		return _herds[herd_id].centroid
	return Vector2.ZERO

func get_herd_size(zombie_id: int) -> int:
	var herd_id: int = _zombie_to_herd.get(zombie_id, -1)
	if _herds.has(herd_id):
		return _herds[herd_id].member_ids.size()
	return 0

func get_herd_id_of(zombie_id: int) -> int:
	return _zombie_to_herd.get(zombie_id, -1)

func get_herd_members(herd_id: int) -> Array[int]:
	if _herds.has(herd_id):
		return _herds[herd_id].member_ids
	return []

## Перенаправляет стадо к точке — основной способ "отвлечь" стадо приманкой/шумом.
func redirect_herd(herd_id: int, new_target: Vector2) -> void:
	if not _herds.has(herd_id):
		return
	_herds[herd_id].target = new_target
	_herds[herd_id].has_custom_target = true
	EventBus.herd_redirected.emit(herd_id, new_target)

# --- Внутренние методы ---

func _create_herd(at_pos: Vector2) -> Herd:
	var herd := Herd.new(_next_id, at_pos)
	_herds[_next_id] = herd
	_next_id += 1
	return herd

func _join_herd(zombie_id: int, new_herd_id: int, old_herd_id: int) -> void:
	if old_herd_id >= 0 and _herds.has(old_herd_id):
		var old_herd: Herd = _herds[old_herd_id]
		old_herd.member_ids.erase(zombie_id)
		if old_herd.member_ids.is_empty():
			_herds.erase(old_herd_id)
			EventBus.herd_dispersed.emit(old_herd_id)

	if not _herds.has(new_herd_id):
		return
	var new_herd: Herd = _herds[new_herd_id]
	if not new_herd.member_ids.has(zombie_id):
		new_herd.member_ids.append(zombie_id)
	_zombie_to_herd[zombie_id] = new_herd_id

	EventBus.zombie_joined_herd.emit(zombie_id, new_herd_id)
	var min_sz: int = GameState.balance.herd_min_size_for_redirect
	if new_herd.member_ids.size() == min_sz:
		EventBus.herd_formed.emit(new_herd_id, new_herd.centroid, new_herd.member_ids.size())

func _update_centroids() -> void:
	if zombie_pool == null:
		return
	for herd_id in _herds:
		var herd: Herd = _herds[herd_id]
		if herd.member_ids.is_empty():
			continue
		var sum := Vector2.ZERO
		var count := 0
		for zid in herd.member_ids:
			var z := zombie_pool.get_zombie_by_id(zid)
			if z != null and is_instance_valid(z):
				sum += z.global_position
				count += 1
		if count > 0:
			herd.centroid = sum / count

func _try_merge_nearby_herds() -> void:
	var ids := _herds.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var id_a: int = ids[i]
			var id_b: int = ids[j]
			if not _herds.has(id_a) or not _herds.has(id_b):
				continue
			var join_r: float = GameState.balance.zombie_join_herd_radius
			if _herds[id_a].centroid.distance_to(_herds[id_b].centroid) <= join_r:
				_merge_into(id_a, id_b)

func _merge_into(keep_id: int, absorb_id: int) -> void:
	if not _herds.has(keep_id) or not _herds.has(absorb_id):
		return
	var keep: Herd = _herds[keep_id]
	var absorb: Herd = _herds[absorb_id]
	for zid in absorb.member_ids:
		if not keep.member_ids.has(zid):
			keep.member_ids.append(zid)
		_zombie_to_herd[zid] = keep_id
	# Если поглощаемое стадо имело принудительную цель — берём её.
	if absorb.has_custom_target and not keep.has_custom_target:
		keep.target = absorb.target
		keep.has_custom_target = true
	_herds.erase(absorb_id)

func _on_stimulus_emitted(_type: int, position: Vector2, strength: float) -> void:
	if strength < GameState.balance.horde_noise_threshold:
		return
	# Перенаправляем ближайшее достаточно большое стадо.
	var closest_id := -1
	var closest_dist := INF
	var min_sz: int = GameState.balance.herd_min_size_for_redirect
	for herd_id in _herds:
		var herd: Herd = _herds[herd_id]
		if herd.member_ids.size() < min_sz:
			continue
		var d := herd.centroid.distance_to(position)
		if d < closest_dist:
			closest_dist = d
			closest_id = herd_id
	if closest_id >= 0:
		redirect_herd(closest_id, position)

func _on_day_passed(_day: int) -> void:
	# К смене дня стада "забывают" принудительную цель и возвращаются к блужданию.
	for herd_id in _herds:
		_herds[herd_id].has_custom_target = false
