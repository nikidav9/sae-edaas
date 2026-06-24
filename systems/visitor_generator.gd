extends RefCounted
class_name VisitorGenerator
## Weighted random генератор визитёров.
##
## Пул грузится из .tres в res://resources/visitor_data/. Шанс враждебных растёт
## с репутацией игрока среди рейдеров (грабил торговцев → чаще приходят враги).
## Числа берём из GameBalance, не хардкодим.

const POOL_DIR := "res://resources/visitor_data"

var _pool: Array[VisitorData] = []

func _init() -> void:
	_load_pool()

func _load_pool() -> void:
	_pool.clear()
	var dir := DirAccess.open(POOL_DIR)
	if dir == null:
		push_warning("VisitorGenerator: пул не найден в %s" % POOL_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(POOL_DIR.path_join(file_name)) as VisitorData
			if res:
				_pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

## Возвращает случайного подходящего визитёра под текущий день и репутацию.
func pick(current_day: int, raider_reputation: float, balance: GameBalance) -> VisitorData:
	if _pool.is_empty():
		return null

	var candidates: Array[VisitorData] = []
	var weights: Array[float] = []
	var total := 0.0

	for v in _pool:
		if current_day < v.min_day:
			continue
		var w := v.spawn_weight * _category_weight(v.type, raider_reputation, balance)
		if w <= 0.0:
			continue
		candidates.append(v)
		weights.append(w)
		total += w

	if candidates.is_empty():
		return null

	var roll := randf() * total
	var acc := 0.0
	for i in candidates.size():
		acc += weights[i]
		if roll <= acc:
			return candidates[i]
	return candidates.back()

func _category_weight(type: int, raider_reputation: float, balance: GameBalance) -> float:
	match type:
		VisitorData.Type.FRIENDLY:
			return balance.weight_friendly
		VisitorData.Type.NEUTRAL:
			return balance.weight_neutral
		VisitorData.Type.HOSTILE:
			return balance.weight_hostile * (1.0 + raider_reputation * balance.hostile_reputation_scaling)
		VisitorData.Type.DILEMMA:
			return balance.weight_dilemma
		_:
			return 1.0
