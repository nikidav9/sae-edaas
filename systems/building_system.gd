extends Node
class_name BuildingSystem
## Управляет всеми постройками лагеря.
##
## Загружает пул BuildingData из res://resources/building_data/.
## Принимает build_requested от UI, проверяет деньги/место, размещает здание.
## Считает суммарный defense_bonus и моральные эффекты костра.

const BUILDING_DIR := "res://resources/building_data"
const BUILDING_SCENE := preload("res://scenes/base/building.tscn")

## Ссылка на BaseGrid — задаётся извне (из сцены базы).
var grid: BaseGrid = null
## Все доступные типы зданий.
var catalogue: Array[BuildingData] = []
## Живые здания: origin_cell → Building.
var _placed: Dictionary = {}
## Суммарный бонус обороны от всех зданий.
var total_defense_bonus: int = 0

func _ready() -> void:
	_load_catalogue()
	EventBus.build_requested.connect(_on_build_requested)
	EventBus.building_destroyed.connect(_on_building_destroyed)
	EventBus.day_passed.connect(_on_day_passed)

func _load_catalogue() -> void:
	var dir := DirAccess.open(BUILDING_DIR)
	if dir == null:
		push_warning("BuildingSystem: каталог не найден: %s" % BUILDING_DIR)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".tres"):
			var b := load(BUILDING_DIR.path_join(name)) as BuildingData
			if b:
				catalogue.append(b)
		name = dir.get_next()
	dir.list_dir_end()

# --- Размещение ---

func _on_build_requested(data: BuildingData, cell: Vector2i) -> void:
	if grid == null:
		push_error("BuildingSystem: grid не задан")
		return
	if not data.can_afford():
		return
	if not grid.can_place(data, cell):
		return
	data.pay_cost()
	_place(data, cell)

func _place(data: BuildingData, cell: Vector2i) -> void:
	var building := BUILDING_SCENE.instantiate() as Building
	building.building_data = data
	building.position = grid.cell_to_world(cell)
	# Масштаб по размеру здания (приближение до арта).
	building.scale = Vector2(data.size_cells)
	add_child(building)
	building.construction_completed.connect(_on_construction_completed.bind(cell))
	building.destroyed.connect(_on_building_node_destroyed.bind(data, cell))
	grid.occupy(data, cell, building)
	_placed[cell] = building
	EventBus.building_placed.emit(data, cell)

# --- Завершение строительства ---

func _on_construction_completed(building: Building, cell: Vector2i) -> void:
	total_defense_bonus += building.building_data.defense_bonus if building.building_data else 0

# --- Разрушение ---

func _on_building_node_destroyed(data: BuildingData, cell: Vector2i, _building: Building) -> void:
	total_defense_bonus -= data.defense_bonus
	grid.release(cell, data)
	_placed.erase(cell)

func _on_building_destroyed(_id: StringName, _cell: Vector2i) -> void:
	pass  # внешние подписчики если нужны

# --- Дневной тик (костёр → мораль) ---

func _on_day_passed(_day: int) -> void:
	for cell in _placed:
		var b := _placed[cell] as Building
		if b and b.is_built and b.building_data and b.building_data.id == &"campfire":
			GameState.change_morale(0.02)

# --- Запросы извне ---

func get_catalogue() -> Array[BuildingData]:
	return catalogue

func has_building(building_id: StringName) -> bool:
	for cell in _placed:
		var b := _placed[cell] as Building
		if b and b.building_data and b.building_data.id == building_id and b.is_built:
			return true
	return false
