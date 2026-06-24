extends Node
class_name DialogueSystem
## Движок диалогов. Управляет текущим узлом, таймером и применяет действия.
##
## Не рисует UI — шлёт события через EventBus. DialogueUI слушает их и
## обновляет экран. Разделение: движок = состояние, UI = отображение.
##
## Жизненный цикл:
##   visitor_arrived → start_dialogue(visitor)
##   → dialogue_node_shown (UI рисует реплику + кнопки)
##   → player нажимает кнопку → select_option(index)
##     или таймер истекает → _on_timeout()
##   → visitor_resolved (если action завершает диалог)

## Испускается когда нужно показать новый узел диалога.
## UI получает текущего визитёра и узел.
signal dialogue_node_shown(visitor: VisitorData, node: DialogueNode)
## Испускается когда диалог завершён (до visitor_resolved в EventBus).
signal dialogue_ended(visitor: VisitorData)
## Тик таймера: осталось секунд (float).
signal timer_tick(seconds_left: float)

var _current_visitor: VisitorData
var _current_tree: DialogueTree
var _current_node: DialogueNode
var _timer: float = 0.0
var _timer_active: bool = false
var _auto_timer: float = 0.0
var _auto_pending: bool = false

func _ready() -> void:
	EventBus.visitor_dialogue_started.connect(_on_dialogue_started)

func _process(delta: float) -> void:
	if _timer_active and _timer > 0.0:
		_timer -= delta
		timer_tick.emit(maxf(_timer, 0.0))
		if _timer <= 0.0:
			_timer_active = false
			_on_timeout()

	if _auto_pending and _auto_timer > 0.0:
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			_auto_pending = false
			_advance_auto()

# --- Запуск ---

func _on_dialogue_started(visitor: VisitorData) -> void:
	if visitor.dialogue_tree == null:
		push_warning("DialogueSystem: у визитёра '%s' нет dialogue_tree" % visitor.display_name)
		_finish(visitor, "dismiss")
		return
	start_dialogue(visitor)

func start_dialogue(visitor: VisitorData) -> void:
	_current_visitor = visitor
	_current_tree = visitor.dialogue_tree
	# Таймер tension: пауза системы дня тоже.
	var total_time := GameState.balance.visitor_decision_seconds if GameState.balance else 15.0
	_timer = total_time
	_timer_active = total_time > 0.0
	# Останавливаем тик дня пока идёт диалог.
	_set_day_paused(true)
	_show_node(_current_tree.entry_node_id)

# --- Навигация по дереву ---

func _show_node(node_id: String) -> void:
	var node := _current_tree.get_node_by_id(node_id)
	if node == null:
		push_error("DialogueSystem: узел '%s' не найден в дереве" % node_id)
		_finish(_current_visitor, "dismiss")
		return
	_current_node = node
	dialogue_node_shown.emit(_current_visitor, node)

	# Авто-переход (монолог NPC без выбора игрока).
	if node.options.is_empty() and not node.auto_next_id.is_empty():
		_auto_timer = node.auto_next_delay
		_auto_pending = true
	elif node.options.is_empty() and node.auto_next_id.is_empty():
		# Последний узел без вариантов → конец.
		_end_after_delay(node.auto_next_delay)

func _advance_auto() -> void:
	if _current_node == null:
		return
	if _current_node.auto_next_id.is_empty():
		_finish(_current_visitor, "")
	else:
		_show_node(_current_node.auto_next_id)

func _end_after_delay(delay: float) -> void:
	_auto_timer = maxf(delay, 0.5)
	_auto_pending = true
	# Узел авто_next_id пуст → _advance_auto вызовет finish.

# --- Выбор игрока ---

## Вызывается из UI когда игрок нажимает кнопку варианта.
func select_option(option_index: int) -> void:
	if _current_node == null or _current_visitor == null:
		return
	var visible_options := _visible_options(_current_node)
	if option_index < 0 or option_index >= visible_options.size():
		return
	_pick_option(visible_options[option_index])

## Возвращает только те варианты, которые игрок реально видит (фильтр по abilities).
func visible_options_for(node: DialogueNode) -> Array[DialogueOption]:
	return _visible_options(node)

func _visible_options(node: DialogueNode) -> Array[DialogueOption]:
	var result: Array[DialogueOption] = []
	for opt in node.options:
		if opt.requires_ability == &"" or GameState.has_ability(String(opt.requires_ability)):
			result.append(opt)
	return result

func _pick_option(option: DialogueOption) -> void:
	# Применяем дельты ресурсов/морали/репутации.
	_apply_deltas(option)
	# Переходим к следующему узлу или завершаем диалог.
	if option.next_node_id.is_empty():
		_finish(_current_visitor, option.action)
	else:
		_show_node(option.next_node_id)

func _on_timeout() -> void:
	if _current_node == null:
		return
	var opts := _visible_options(_current_node)
	if opts.is_empty():
		_finish(_current_visitor, "dismiss")
		return
	var idx: int
	if _current_node.timeout_option_index < 0:
		idx = opts.size() - 1  # последняя = обычно "прогнать"
	else:
		idx = clampi(_current_node.timeout_option_index, 0, opts.size() - 1)
	_pick_option(opts[idx])

# --- Применение эффектов ---

func _apply_deltas(option: DialogueOption) -> void:
	if option.morale_delta != 0.0:
		GameState.change_morale(option.morale_delta)
	if option.raider_reputation_delta != 0.0:
		GameState.change_raider_reputation(option.raider_reputation_delta)
	for res_id in option.resource_cost:
		GameState.change_resource(res_id, -int(option.resource_cost[res_id]))

# --- Завершение ---

func _finish(visitor: VisitorData, action: String) -> void:
	_timer_active = false
	_auto_pending = false
	_set_day_paused(false)
	dialogue_ended.emit(visitor)
	EventBus.visitor_resolved.emit(visitor, action)
	_current_visitor = null
	_current_tree = null
	_current_node = null

func _set_day_paused(paused: bool) -> void:
	# DayNightSystem живёт как дочерний узел Main.
	var root := get_tree().root
	for child in root.get_children():
		var sys := child.find_child("DayNightSystem", true, false)
		if sys is DayNightSystem:
			(sys as DayNightSystem).paused = paused
			return
