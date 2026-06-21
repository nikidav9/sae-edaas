extends Resource
class_name BiomeData
## Данные биома. Новые биомы добавляются как .tres без правки генератора.
##
## Генератор читает noise_threshold и layer_id: тайл с наименьшим threshold,
## чьё значение >= шуму, становится биомом в данной точке карты.

@export var id: StringName = &""
@export var display_name: String = "Биом"
@export_multiline var description: String = ""

@export_group("Генерация тайлов")
## Пороговое значение шума (0..1): биом появляется когда noise >= threshold.
## Биомы проверяются по возрастанию threshold (самый низкий → самый "базовый").
@export_range(0.0, 1.0, 0.01) var noise_threshold: float = 0.0
## ID тайла в TileSet для напочвенного слоя.
@export var ground_tile_id: int = 0
## ID тайла для слоя деталей (деревья, камни, обломки). -1 = нет декора.
@export var detail_tile_id: int = -1
## Вероятность появления декора (0..1).
@export_range(0.0, 1.0, 0.05) var detail_chance: float = 0.3

@export_group("Геймплей")
## Замедление движения игрока/NPC в этом биоме (1.0 = нет эффекта).
@export_range(0.1, 2.0, 0.05) var movement_modifier: float = 1.0
## Ссылка на таблицу лута, характерного для биома.
@export var loot_table: LootTable
## Базовый шанс спавна орды в данном биоме за тик дня.
@export_range(0.0, 1.0, 0.01) var horde_spawn_chance: float = 0.05
## Видим ли биом на карте без разведки (false = туман войны до посещения).
@export var revealed_by_default: bool = false
