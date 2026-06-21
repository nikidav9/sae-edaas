extends Node
class_name NPCManager
## Управляет всеми живыми NPC в базе лагеря.
##
## Слушает npc_recruited → спавнит NPCController.
## Слушает npc_lost → убирает из ростера.
## Назначает WorkPoint при спавне если есть свободная точка для умения NPC.

const NPC_SCENE := preload("res://scenes/characters/npc_survivors/npc_controller.tscn")

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

## Возвращает NPC с нужным умением или null.
func get_npc_with_ability(ability_id: StringName) -> NPCController:
	return roster.get(String(ability_id), null)
