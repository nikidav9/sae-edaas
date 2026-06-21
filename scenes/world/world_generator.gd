extends RefCounted
class_name WorldGenerator
## Процедурная генерация карты мира через FastNoiseLite.
##
## Выдаёт готовые данные карты (WorldMapData), TileMap не трогает — это работа
## WorldMap. Разделение: генератор = данные, сцена = отображение.
##
## Два слоя шума: elevation (биомы) + detail (декор/лут-точки).
## Третий шум (horde_noise) задаёт начальные позиции орд.

const BIOME_DIR := "res://resources/biome_data"

## Результат генерации.
class WorldMapData:
	var seed: int
	var width: int
	var height: int
	## Плоский массив [width*height]: BiomeData для каждой клетки.
	var biome_map: Array[BiomeData] = []
	## Позиции клеток с лутом: Vector2i -> LootTable
	var loot_points: Dictionary = {}
	## Начальные позиции орд (в клетках): Array[Vector2i]
	var horde_positions: Array[Vector2i] = []
	## Позиция базы игрока (центр карты или ближайшая равнина).
	var base_position: Vector2i = Vector2i.ZERO

	func cell_index(x: int, y: int) -> int:
		return y * width + x

	func get_biome(x: int, y: int) -> BiomeData:
		var idx := cell_index(x, y)
		if idx < 0 or idx >= biome_map.size():
			return null
		return biome_map[idx]

var _biomes: Array[BiomeData] = []

## noise1 = elevation (определяет биом), noise2 = detail, noise3 = horde spawnpoints.
var _noise_elevation: FastNoiseLite
var _noise_detail: FastNoiseLite
var _noise_horde: FastNoiseLite

func _init() -> void:
	_load_biomes()
	_setup_noises()

func _load_biomes() -> void:
	_biomes.clear()
	var dir := DirAccess.open(BIOME_DIR)
	if dir == null:
		push_error("WorldGenerator: нет биомов в %s" % BIOME_DIR)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".tres"):
			var b := load(BIOME_DIR.path_join(name)) as BiomeData
			if b:
				_biomes.append(b)
		name = dir.get_next()
	dir.list_dir_end()
	# Сортируем по возрастанию threshold: базовый биом (plains) первый.
	_biomes.sort_custom(func(a: BiomeData, b: BiomeData) -> bool:
		return a.noise_threshold < b.noise_threshold)

func _setup_noises() -> void:
	_noise_elevation = FastNoiseLite.new()
	_noise_elevation.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_elevation.frequency = 0.04

	_noise_detail = FastNoiseLite.new()
	_noise_detail.noise_type = FastNoiseLite.TYPE_CELLULAR
	_noise_detail.frequency = 0.12

	_noise_horde = FastNoiseLite.new()
	_noise_horde.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise_horde.frequency = 0.06

func generate(map_seed: int, width: int, height: int) -> WorldMapData:
	_noise_elevation.seed = map_seed
	_noise_detail.seed = map_seed + 1
	_noise_horde.seed = map_seed + 2

	var data := WorldMapData.new()
	data.seed = map_seed
	data.width = width
	data.height = height

	data.biome_map.resize(width * height)

	for y in height:
		for x in width:
			var elev := _normalized(_noise_elevation.get_noise_2d(x, y))
			var biome := _biome_for(elev)
			data.biome_map[data.cell_index(x, y)] = biome

			# Лут-точки: detail-шум выше 0.7 + биом имеет таблицу лута.
			var detail := _normalized(_noise_detail.get_noise_2d(x, y))
			if detail > 0.7 and biome and biome.loot_table:
				data.loot_points[Vector2i(x, y)] = biome.loot_table

	# Базу ставим в центр карты — если там не болото/пустошь, иначе ищем ближайшую равнину.
	data.base_position = _find_base_position(data, width, height)

	# Орды: horde_noise-пики вдали от базы.
	_place_hordes(data, width, height)

	return data

## Нормализует шум из [-1,1] в [0,1].
func _normalized(v: float) -> float:
	return (v + 1.0) * 0.5

func _biome_for(elevation: float) -> BiomeData:
	var result: BiomeData = _biomes[0] if not _biomes.is_empty() else null
	for b in _biomes:
		if elevation >= b.noise_threshold:
			result = b
	return result

func _find_base_position(data: WorldMapData, width: int, height: int) -> Vector2i:
	var cx := width / 2
	var cy := height / 2
	var center_biome := data.get_biome(cx, cy)
	# Если центр — равнина или пустошь маловероятна — оставляем центр.
	if center_biome and center_biome.id in [&"plains", &"forest"]:
		return Vector2i(cx, cy)
	# Иначе спиральный обход к ближайшей равнине.
	for r in maxi(width, height):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var nx := cx + dx
				var ny := cy + dy
				if nx < 0 or ny < 0 or nx >= width or ny >= height:
					continue
				var b := data.get_biome(nx, ny)
				if b and b.id == &"plains":
					return Vector2i(nx, ny)
	return Vector2i(cx, cy)

func _place_hordes(data: WorldMapData, width: int, height: int) -> void:
	var min_dist := 8 # клеток от базы — орды не стартуют прямо на игроке
	for y in height:
		for x in width:
			var dist := Vector2i(x, y).distance_to(data.base_position)
			if dist < min_dist:
				continue
			var hv := _normalized(_noise_horde.get_noise_2d(x, y))
			var biome := data.get_biome(x, y)
			if biome == null:
				continue
			# Орда появляется если horde-шум > (1 - spawn_chance биома).
			if hv > (1.0 - biome.horde_spawn_chance):
				data.horde_positions.append(Vector2i(x, y))
