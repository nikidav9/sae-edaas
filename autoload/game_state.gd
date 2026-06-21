extends Node
## Центральное состояние игры (источник правды).
##
## Хранит данные; НЕ содержит сложной логики систем — системы читают/меняют
## состояние через публичные методы и сообщают о фактах через EventBus.
## Всё, что сериализуется, должно попадать в to_dict()/from_dict().

const BALANCE_PATH := "res://resources/balance/game_balance.tres"

# --- Прогресс ---
var current_day: int = 1
var is_night: bool = false

# --- Социальные метрики (0.0 .. 1.0) ---
var group_morale: float = 0.7
## Репутация среди рейдеров: чем выше — тем чаще приходят враждебные визитёры.
var raider_reputation: float = 0.0

# --- Ресурсы лагеря ---
var resources: Dictionary = {
	"food": 20,
	"materials": 15,
	"medicine": 5,
}

# --- Группа: id умений рекрутированных NPC (умения уникальны, не дублируются) ---
var roster_ability_ids: Array[String] = []

# --- Журнал визитёров (для Diary/Journal UI) ---
var visitor_journal: Array[Dictionary] = []

# --- Экспедиции: ability_id → дней до возвращения ---
var active_expeditions: Dictionary = {}

# --- Игровой цикл ---
var game_over_reason: String = ""

# --- Баланс (выносим числа из логики сюда) ---
var balance: GameBalance

func _ready() -> void:
	_load_balance()

func _load_balance() -> void:
	if ResourceLoader.exists(BALANCE_PATH):
		balance = load(BALANCE_PATH) as GameBalance
	if balance == null:
		balance = GameBalance.new()
		push_warning("GameBalance не найден по %s — использую значения по умолчанию." % BALANCE_PATH)

# --- Ресурсы ---
func get_resource(id: String) -> int:
	return int(resources.get(id, 0))

func change_resource(id: String, delta: int) -> void:
	resources[id] = maxi(0, get_resource(id) + delta)
	EventBus.resource_changed.emit(id, resources[id])

func can_afford(id: String, amount: int) -> bool:
	return get_resource(id) >= amount

# --- Мораль / репутация ---
func change_morale(delta: float) -> void:
	group_morale = clampf(group_morale + delta, 0.0, 1.0)
	EventBus.morale_changed.emit(group_morale, delta)

func change_raider_reputation(delta: float) -> void:
	raider_reputation = clampf(raider_reputation + delta, 0.0, 1.0)
	EventBus.raider_reputation_changed.emit(raider_reputation, delta)

# --- Группа ---
func has_ability(ability_id: String) -> bool:
	return ability_id in roster_ability_ids

func add_ability(ability_id: String) -> void:
	if ability_id.is_empty() or has_ability(ability_id):
		return
	roster_ability_ids.append(ability_id)
	EventBus.ability_unlocked.emit(ability_id)

# --- Журнал ---
func log_visitor(entry: Dictionary) -> void:
	visitor_journal.append(entry)

# --- Цикл дня ---
func advance_day() -> void:
	current_day += 1
	is_night = false
	EventBus.day_passed.emit(current_day)

# --- Сериализация (используется SaveSystem) ---
func to_dict() -> Dictionary:
	return {
		"current_day": current_day,
		"is_night": is_night,
		"group_morale": group_morale,
		"raider_reputation": raider_reputation,
		"resources": resources.duplicate(true),
		"roster_ability_ids": roster_ability_ids.duplicate(),
		"visitor_journal": visitor_journal.duplicate(true),
		"active_expeditions": active_expeditions.duplicate(true),
	}

func from_dict(data: Dictionary) -> void:
	current_day = int(data.get("current_day", 1))
	is_night = bool(data.get("is_night", false))
	group_morale = float(data.get("group_morale", 0.7))
	raider_reputation = float(data.get("raider_reputation", 0.0))
	resources = (data.get("resources", {}) as Dictionary).duplicate(true)
	roster_ability_ids.assign(data.get("roster_ability_ids", []))
	visitor_journal.assign(data.get("visitor_journal", []))
	active_expeditions = (data.get("active_expeditions", {}) as Dictionary).duplicate(true)

## Сброс в состояние новой игры (вызывается GameLoopManager).
func reset() -> void:
	current_day = 1
	is_night = false
	group_morale = 0.7
	raider_reputation = 0.0
	resources = {"food": 20, "materials": 15, "medicine": 5}
	roster_ability_ids.clear()
	visitor_journal.clear()
	active_expeditions.clear()
	game_over_reason = ""
