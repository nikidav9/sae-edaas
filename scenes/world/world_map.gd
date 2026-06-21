extends Node2D
class_name WorldMap
## Сцена карты мира: генерирует и отображает тайловый мир.
##
## TileMap — два слоя: 0 = напочвенный (биомы), 1 = декор.
## Туман войны: клетки за пределами радиуса обзора скрыты (CanvasLayer поверх).
## Орды: маркеры на отдельном слое, видны только если есть разведчик (ability scout_recon).

const TILE_SIZE: int = 16 # пикселей (под пиксель-арт)
const MAP_WIDTH: int = 128
const MAP_HEIGHT: int = 128
## Начальный радиус обзора вокруг базы (в клетках).
const BASE_VIEW_RADIUS: int = 6

@onready var tile_map: TileMap = $TileMap
@onready var fog_layer: CanvasLayer = $FogLayer
@onready var horde_markers: Node2D = $HordeMarkers
@onready var base_marker: Sprite2D = $BaseMarker
@onready var camera: Camera2D = $Camera2D

var _map_data: WorldGenerator.WorldMapData
var _revealed: Array[bool] = [] # плоский массив [MAP_WIDTH*MAP_HEIGHT]

## Сцена маркера орды (подставить позже, пока программный квадрат).
@export var horde_marker_scene: PackedScene

func _ready() -> void:
	EventBus.horde_spotted.connect(_on_horde_spotted)
	EventBus.day_passed.connect(_on_day_passed)
	_generate()

func _generate(map_seed: int = 0) -> void:
	if map_seed == 0:
		map_seed = randi()
	var gen := WorldGenerator.new()
	_map_data = gen.generate(map_seed, MAP_WIDTH, MAP_HEIGHT)
	_revealed.resize(MAP_WIDTH * MAP_HEIGHT)
	_revealed.fill(false)
	_paint_tiles()
	_reveal_around(_map_data.base_position, BASE_VIEW_RADIUS)
	_place_base_marker()
	_place_horde_markers()
	_center_camera_on_base()

# --- Тайлы ---

func _paint_tiles() -> void:
	tile_map.clear()
	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			var biome := _map_data.get_biome(x, y)
			if biome == null:
				continue
			# Слой 0: земля.
			tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(biome.ground_tile_id, 0))
			# Слой 1: декор (если biome задаёт деталь и выпал шанс).
			if biome.detail_tile_id >= 0 and randf() < biome.detail_chance:
				tile_map.set_cell(1, Vector2i(x, y), 0, Vector2i(biome.detail_tile_id, 0))

# --- Туман войны ---

func _reveal_around(center: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			var cx := center.x + dx
			var cy := center.y + dy
			if cx < 0 or cy < 0 or cx >= MAP_WIDTH or cy >= MAP_HEIGHT:
				continue
			_revealed[cy * MAP_WIDTH + cx] = true
	_refresh_fog()

func _refresh_fog() -> void:
	# Обновляем туман: скрываем тайлы вне revealed зоны через слой 2 (туман).
	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			var visible := _revealed[y * MAP_WIDTH + x]
			if visible:
				tile_map.erase_cell(2, Vector2i(x, y))
			else:
				tile_map.set_cell(2, Vector2i(x, y), 0, Vector2i(0, 0))

# --- Маркеры ---

func _place_base_marker() -> void:
	if base_marker:
		base_marker.position = Vector2(_map_data.base_position) * TILE_SIZE

func _place_horde_markers() -> void:
	for child in horde_markers.get_children():
		child.queue_free()
	# Орды показываем только если игрок имеет умение разведчика.
	if not GameState.has_ability("scout_recon"):
		return
	for pos in _map_data.horde_positions:
		_add_horde_marker(pos)

func _add_horde_marker(tile_pos: Vector2i) -> void:
	var marker: Node2D
	if horde_marker_scene:
		marker = horde_marker_scene.instantiate() as Node2D
	else:
		# Программный маркер-заглушка (красный квадрат) до появления арта.
		var rect := ColorRect.new()
		rect.color = Color(0.9, 0.1, 0.1, 0.85)
		rect.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
		marker = rect
	marker.position = Vector2(tile_pos) * TILE_SIZE
	horde_markers.add_child(marker)

func _center_camera_on_base() -> void:
	camera.position = Vector2(_map_data.base_position) * TILE_SIZE

# --- Обзор при движении ---

## Вызывается когда игрок/разведчик посещает новую клетку.
func reveal_at(tile_pos: Vector2i, radius: int) -> void:
	_reveal_around(tile_pos, radius)

# --- EventBus ---

func _on_horde_spotted(horde_id: int, position: Vector2) -> void:
	var tile_pos := Vector2i(position / TILE_SIZE)
	# Добавляем маркер орды, если разведчик его видит.
	if GameState.has_ability("scout_recon"):
		_add_horde_marker(tile_pos)

func _on_day_passed(_day: int) -> void:
	# Раз в день репутация может обновить весовую таблицу орд — пока заглушка.
	pass

# --- Ввод (пан камеры) ---

var _drag_start: Vector2 = Vector2.ZERO
var _is_dragging: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		camera.position -= event.relative / camera.zoom
	elif event is InputEventScreenTouch:
		if not event.pressed:
			_is_dragging = false
