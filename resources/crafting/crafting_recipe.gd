extends Resource
class_name CraftingRecipe
## Данные одного рецепта крафта.

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
## Ресурсы для крафта: {"resource_id": amount}
@export var input_resources: Dictionary = {}
@export var output_resource: String = ""
@export var output_amount: int = 1
## Если не пусто — рецепт доступен только при наличии этой постройки.
@export var requires_building: StringName = &""
