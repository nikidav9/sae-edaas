extends Node
class_name NPCManager
## Управляет всеми живыми NPC в базе лагеря.
##
## Слушает npc_recruited → спавнит NPCController.
## Слушает npc_lost → убирает из ростера.
## Назначает WorkPoint при спавне если есть свободная точка для умения NPC.

const NPC_SCENE := preload("res://scenes/characters/npc_survivors/npc_controller.tscn")
const NPC_DATA_DIR := "res://resources/npc_data"

## Смещения спавна новых NPC вокруг центра базы (чтобы не появлялись в одной точке).
const SPAWN_OFFSETS: Array[Vector2] = [
	Vector2(32, 0), Vector2(-32, 0), Vector2(0, 32), Vector2(0, -32),
	Vector2(32, 32), Vector2(-32, 32), Vector2(32, -32), Vector2(-32, -32),
]

## Позиция центра базы. Устанавливается WorldMap при генерации.
var base_position: Vector2 = Vector2.ZERO
## Активные NPC: ability_id → NPCController.
var roster: Dictionary = {}

func _ready() -> void:
	EventBus.npc_recruited.connect(_on_npc_recruited)
	EventBus.npc_lost.connect(_on_npc_lost)

func _on_npc_recruited(npc_data: NPCData) -> void:
	if npc_data == null:
		return
	var key := String(npc_data.ability_id)
	if roster.has(key):
		push_warning("NPCManager: NPC с ability '%s' уже в ростере" % key)
		return
	var npc := _spawn(npc_data)
	roster[key] = npc

func _on_npc_lost(npc_data: NPCData, _reason: String) -> void:
	if npc_data == null:
		return
	var key := String(npc_data.ability_id)
	roster.erase(key)
	# Убираем умение из GameState.
	GameState.roster_ability_ids.erase(String(npc_data.ability_id))

func _spawn(npc_data: NPCData) -> NPCController:
	var npc := NPC_SCENE.instantiate() as NPCController
	npc.npc_data = npc_data
	# Позиция — центр базы + смещение по индексу в ростере.
	var offset := SPAWN_OFFSETS[roster.size() % SPAWN_OFFSETS.size()]
	npc.global_position = base_position + offset
	add_child(npc)
	# Назначаем рабочую точку если есть.
	_try_assign_work_point(npc)
	return npc

func _try_assign_work_point(npc: NPCController) -> void:
	if npc.npc_data == null or npc.npc_data.ability_id == &"":
		return
	# Ищем свободный WorkPoint с нужным ability_id в сцене.
	var points := get_tree().get_nodes_in_group("work_points")
	for point_node in points:
		var wp := point_node as WorkPoint
		if wp == null:
			continue
		if wp.required_ability_id == npc.npc_data.ability_id and wp.is_free():
			wp.occupy(npc)
			npc.assign_work_point(wp)
			return

## Вызывается SaveSystem после load_game: восстанавливает NPC по ростеру GameState.
func restore_from_game_state() -> void:
	# Удаляем текущих NPC.
	for key in roster:
		var npc := roster[key] as NPCController
		if npc and is_instance_valid(npc):
			npc.queue_free()
	roster.clear()
	# Грузим все NPCData из папки один раз.
	var all_data := _load_all_npc_data()
	for ability_id in GameState.roster_ability_ids:
		var npc_data := _find_npc_by_ability(all_data, StringName(ability_id))
		if npc_data:
			var npc := _spawn(npc_data)
			roster[ability_id] = npc
		else:
			push_warning("NPCManager.restore: не найдены данные для ability '%s'" % ability_id)

func _load_all_npc_data() -> Array[NPCData]:
	var result: Array[NPCData] = []
	var dir := DirAccess.open(NPC_DATA_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".tres"):
			var d := load(NPC_DATA_DIR.path_join(name)) as NPCData
			if d:
				result.append(d)
		name = dir.get_next()
	dir.list_dir_end()
	return result

func _find_npc_by_ability(data_list: Array[NPCData], ability_id: StringName) -> NPCData:
	for d in data_list:
		if d.ability_id == ability_id:
			return d
	return null

## Возвращает NPC с нужным умением или null.
func get_npc_with_ability(ability_id: StringName) -> NPCController:
	return roster.get(String(ability_id), null)
