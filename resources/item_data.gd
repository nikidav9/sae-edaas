extends Resource
class_name ItemData
## Данные предмета/ресурса (лут, крафт-материалы, расходники).

enum Category {
	RESOURCE,    ## Сырьё/ресурс лагеря (food, materials, medicine...).
	CONSUMABLE,  ## Расходник (аптечка, паёк).
	TRAP,        ## Ловушка (крафтит механик).
	WEAPON,
	MISC,
}

@export var id: StringName = &""
@export var display_name: String = "Предмет"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var category: Category = Category.RESOURCE

@export_group("Стек / торговля")
@export var max_stack: int = 99
## Базовая ценность для расчёта обмена у торговцев.
@export var base_value: int = 1
