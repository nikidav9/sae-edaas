extends Node2D
class_name BaseGrid
## Сетка клеток лагеря для размещения зданий.
## Отслеживает занятые клетки, проверяет коллизии при размещении.

const CELL_SIZE: int = 32  # пикселей, совпадает с TILE_SIZE в WorldMap
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 20

## Занятые клетки: Vector2i → building_id (StringName).
var _occupied: Dictionary = {}
## Размещённые здания: cell → Building node.
var _buildings: Dictionary = {}

# --- Проверка ---

func can_place(data: BuildingData, origin_cell: Vector2i) -> bool:
	for dy in data.size_cells.y:
		for dx in data.size_cells.x:
			var cell := origin_cell + Vector2i(dx, dy)
			if not _in_bounds(cell):
				return false
			if _occupied.has(cell):
				return false
	return true

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_HEIGHT

# --- Размещение / удаление ---

func occupy(data: BuildingData, origin_cell: Vector2i, building_node: Node2D) -> void:
	for dy in data.size_cells.y:
		for dx in data.size_cells.x:
			var cell := origin_cell + Vector2i(dx, dy)
			_occupied[cell] = data.id
	_buildings[origin_cell] = building_node

func release(origin_cell: Vector2i, data: BuildingData) -> void:
	for dy in data.size_cells.y:
		for dx in data.size_cells.x:
			_occupied.erase(origin_cell + Vector2i(dx, dy))
	_buildings.erase(origin_cell)

# --- Конвертация координат ---

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i((world_pos / CELL_SIZE).floor())

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE

func snap_to_grid(world_pos: Vector2) -> Vector2:
	return cell_to_world(world_to_cell(world_pos))

# --- Состояние для сохранения ---

func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for cell in _buildings:
		var b := _buildings[cell] as Building
		if b and b.building_data:
			result["%d,%d" % [cell.x, cell.y]] = {
				"id": String(b.building_data.id),
				"health": b.current_health,
				"days_left": b.construction_days_left,
			}
	return result
