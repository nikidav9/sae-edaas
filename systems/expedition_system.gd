extends Node
class_name ExpeditionSystem
## Отправляет NPC в экспедицию за ресурсами. Тикает по дням.
##
## Пока NPC в экспедиции — его умение неактивно в GameState.
## Разведчик (scout_recon) возвращается на expedition_scout_bonus_days быстрее
## и привозит больше лута.

## Таблица ресурсов-наград: случайный пул из доступного.
const LOOT_RESOURCES := ["food", "materials", "medicine"]

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)

## Отправить NPC (по ability_id) в экспедицию.
func start_expedition(ability_id: String) -> void:
	if ability_id.is_empty():
		return
	if GameState.active_expeditions.has(ability_id):
		return  # Уже в экспедиции.
	if not GameState.has_ability(ability_id):
		return

	var b := GameState.balance
	var days := b.expedition_base_days
	if ability_id == "scout_recon":
		days = maxi(1, days - b.expedition_scout_bonus_days)

	# Временно убираем умение (NPC занят).
	GameState.roster_ability_ids.erase(ability_id)
	GameState.active_expeditions[ability_id] = days
	EventBus.expedition_started.emit(ability_id)

func _on_day_passed(_day: int) -> void:
	var finished: Array[String] = []
	for ability_id in GameState.active_expeditions:
		GameState.active_expeditions[ability_id] -= 1
		if GameState.active_expeditions[ability_id] <= 0:
			finished.append(ability_id)
	for ability_id in finished:
		GameState.active_expeditions.erase(ability_id)
		_resolve_expedition(ability_id)

func _resolve_expedition(ability_id: String) -> void:
	var b := GameState.balance
	# Проверка на провал.
	if randf() < b.expedition_failure_chance:
		# NPC пропал без вести — не возвращается.
		EventBus.expedition_failed.emit(ability_id, "Пропал без вести.")
		GameState.change_morale(-0.1)
		return

	# Генерируем лут.
	var loot: Array = _roll_loot(ability_id)
	for entry in loot:
		GameState.change_resource(entry["id"], entry["amount"])

	# Возвращаем умение.
	GameState.add_ability(ability_id)
	EventBus.expedition_completed.emit(ability_id, loot)

func _roll_loot(ability_id: String) -> Array:
	var b := GameState.balance
	var total := randi_range(b.expedition_loot_min, b.expedition_loot_max)
	# Разведчик приносит +50% ресурсов.
	if ability_id == "scout_recon":
		total = int(total * 1.5)
	var loot: Array = []
	for _i in total:
		var res := LOOT_RESOURCES[randi() % LOOT_RESOURCES.size()]
		# Группируем одинаковые ресурсы.
		var found := false
		for entry in loot:
			if entry["id"] == res:
				entry["amount"] += 1
				found = true
				break
		if not found:
			loot.append({"id": res, "amount": 1})
	return loot
