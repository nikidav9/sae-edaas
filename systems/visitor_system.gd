extends Node
class_name VisitorSystem
## Система визитёров — ключевая фича.
##
## Раз в visitor_min..max дней к лагерю подходит случайный визитёр. Игрок не
## знает заранее, друг это или враг. Решение принимается через диалог с
## таймером (tension). Скрытая природа раскрывается со временем внутри периметра.
##
## Система НЕ рисует UI: испускает события через EventBus, UI слушает.

var _generator: VisitorGenerator
var _days_until_next: int = 0
## Визитёры, принятые в лагерь и ещё не раскрывшие скрытую природу.
## Каждый элемент: {"visitor": VisitorData, "day_admitted": int}
var _pending_reveals: Array[Dictionary] = []

func _ready() -> void:
	_generator = VisitorGenerator.new()
	_schedule_next()
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.visitor_resolved.connect(_on_visitor_resolved)

func _schedule_next() -> void:
	var b := GameState.balance
	_days_until_next = randi_range(b.visitor_min_interval_days, b.visitor_max_interval_days)

func _on_day_passed(day: int) -> void:
	_process_reveals(day)

	_days_until_next -= 1
	if _days_until_next > 0:
		return
	_schedule_next()
	_spawn_visitor(day)

func _spawn_visitor(day: int) -> void:
	var visitor := _generator.pick(day, GameState.raider_reputation, GameState.balance)
	if visitor == null:
		return
	EventBus.visitor_arrived.emit(visitor)
	EventBus.visitor_dialogue_started.emit(visitor)
	# UI подхватывает диалог и по таймеру вернёт выбор через visitor_resolved.

func _on_visitor_resolved(visitor: VisitorData, choice: String) -> void:
	GameState.log_visitor({
		"day": GameState.current_day,
		"id": String(visitor.id),
		"name": visitor.display_name,
		"choice": choice,
	})

	if choice == "admit":
		_admit(visitor)
	elif choice == "rob" and visitor.type == VisitorData.Type.NEUTRAL:
		GameState.change_raider_reputation(GameState.balance.reputation_gain_on_rob_trader)

func _admit(visitor: VisitorData) -> void:
	if visitor.is_recruitable():
		GameState.add_ability(String(visitor.ability_id))
		if visitor.npc_data:
			EventBus.npc_recruited.emit(visitor.npc_data)
	# Скрытая природа раскроется позже, уже внутри периметра.
	if visitor.has_hidden_nature():
		_pending_reveals.append({"visitor": visitor, "day_admitted": GameState.current_day})

func _process_reveals(day: int) -> void:
	var still_hidden: Array[Dictionary] = []
	for entry in _pending_reveals:
		var visitor: VisitorData = entry["visitor"]
		var days_inside: int = day - int(entry["day_admitted"])
		var delay_hit := visitor.reveal_delay_days > 0 and days_inside >= visitor.reveal_delay_days
		var chance_hit := visitor.reveal_chance > 0.0 and randf() < visitor.reveal_chance
		if delay_hit or chance_hit:
			_reveal(visitor)
		else:
			still_hidden.append(entry)
	_pending_reveals = still_hidden

func _reveal(visitor: VisitorData) -> void:
	EventBus.visitor_true_nature_revealed.emit(visitor, visitor.hidden_trait)
	match visitor.hidden_trait:
		VisitorData.HiddenTrait.MANIPULATOR:
			GameState.change_morale(-GameState.balance.manipulator_daily_morale_drain)
		VisitorData.HiddenTrait.BETRAYER:
			GameState.change_morale(-GameState.balance.morale_loss_on_betrayal)
		VisitorData.HiddenTrait.INFECTED:
			EventBus.base_attacked.emit(1) # угроза изнутри периметра
		VisitorData.HiddenTrait.RAIDER_SCOUT:
			EventBus.horde_approaching.emit(-1, GameState.balance.scout_horde_warning_days)
		_:
			pass
