extends Resource
class_name LootTable
## Таблица лута: взвешенный список предметов для спавна в точке.
##
## Используется биомами и лут-точками. Числа — в ресурсе, не в коде.

@export_group("Записи лута")
## Ключи: item id (StringName), значения: float веса.
## Пример: {"food": 1.0, "medicine": 0.3, "materials": 0.7}
@export var entries: Dictionary = {}
## Минимальное и максимальное количество предметов при одном лутинге.
@export var min_count: int = 1
@export var max_count: int = 3

## Возвращает массив пар [item_id, quantity] по одному roll'у.
func roll() -> Array[Dictionary]:
	if entries.is_empty():
		return []

	var ids: Array = entries.keys()
	var weights: Array = entries.values()
	var total := 0.0
	for w in weights:
		total += float(w)

	var count := randi_range(min_count, max_count)
	var result: Array[Dictionary] = []

	for _i in count:
		var r := randf() * total
		var acc := 0.0
		for j in ids.size():
			acc += float(weights[j])
			if r <= acc:
				result.append({"id": ids[j], "qty": 1})
				break

	return result
