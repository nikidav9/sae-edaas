extends Resource
class_name BuildingData
## Данные одного типа постройки. Новые здания — только .tres, без правки кода.

@export var id: StringName = &""
@export var display_name: String = "Постройка"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Размер (в клетках сетки)")
@export var size_cells: Vector2i = Vector2i(1, 1)

@export_group("Стоимость")
## Ключи — resource_id (String), значения — int количество.
@export var build_cost: Dictionary = {}
@export var build_time_days: int = 1

@export_group("Характеристики")
@export var max_health: int = 100
@export var defense_bonus: int = 0
## Ежедневное производство еды (огород, амбар).
@export var daily_food: int = 0
## Ежедневный бонус морали (дом, костёр).
@export var daily_morale: float = 0.0

@export_group("Разблокировки")
## Здание этого id должно быть построено чтобы показать постройку в меню.
@export var requires_building: StringName = &""

@export_group("NPC / умения")
@export var provides_work_for_ability: StringName = &""
@export var builder_ability_id: StringName = &"mechanic_traps"

@export_group("Визуал")
@export_file("*.tscn") var building_scene: String = ""
@export_file("*.tscn") var scaffold_scene: String = ""

func can_afford() -> bool:
	for res_id in build_cost:
		if not GameState.can_afford(res_id, int(build_cost[res_id])):
			return false
	return true

func pay_cost() -> void:
	for res_id in build_cost:
		GameState.change_resource(res_id, -int(build_cost[res_id]))
