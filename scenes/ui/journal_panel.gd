extends CanvasLayer
class_name JournalPanel
## Дневник/журнал: лог всех встреч с визитёрами и принятых решений.
## Открывается кнопкой в HUD, закрывается кнопкой внутри или тапом фона.

@onready var scroll: ScrollContainer = %ScrollContainer
@onready var entries_container: VBoxContainer = %EntriesContainer
@onready var panel: PanelContainer = %Panel
@onready var empty_label: Label = %EmptyLabel

func _ready() -> void:
	hide()
	EventBus.visitor_resolved.connect(_on_visitor_resolved)

func toggle() -> void:
	if visible:
		_close()
	else:
		_open()

func _open() -> void:
	_rebuild_entries()
	show()
	# Слайд снизу вверх.
	panel.position.y = 300
	var tween := create_tween()
	tween.tween_property(panel, "position:y", 0.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _close() -> void:
	var tween := create_tween()
	tween.tween_property(panel, "position:y", 300.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(hide)

func _rebuild_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()

	var journal: Array = GameState.visitor_journal
	empty_label.visible = journal.is_empty()

	# Показываем в обратном хронологическом порядке (новые вверху).
	for i in range(journal.size() - 1, -1, -1):
		var entry: Dictionary = journal[i]
		entries_container.add_child(_make_entry(entry))

func _make_entry(entry: Dictionary) -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var header := Label.new()
	var day := int(entry.get("day", 0))
	var name_str: String = entry.get("name", "???")
	header.text = "День %d  —  %s" % [day, name_str]
	header.add_theme_font_size_override("font_size", 16)
	container.add_child(header)

	var choice_label := Label.new()
	choice_label.text = _choice_text(entry.get("choice", ""))
	choice_label.add_theme_color_override("font_color", _choice_color(entry.get("choice", "")))
	choice_label.add_theme_font_size_override("font_size", 13)
	container.add_child(choice_label)

	# Разделитель.
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	container.add_child(sep)

	return container

func _choice_text(choice: String) -> String:
	match choice:
		"recruit": return "  Принят в группу"
		"admit":   return "  Впущен в лагерь"
		"dismiss": return "  Прогнан"
		"reject":  return "  Отказано"
		"rob":     return "  Ограблен"
		"trade":   return "  Обмен состоялся"
		_:         return "  Ушёл"

func _choice_color(choice: String) -> Color:
	match choice:
		"recruit", "admit", "trade": return Color(0.4, 0.9, 0.4)
		"dismiss", "reject":         return Color(0.8, 0.8, 0.8)
		"rob":                       return Color(1.0, 0.4, 0.2)
		_:                           return Color.WHITE

func _on_visitor_resolved(_visitor: VisitorData, _choice: String) -> void:
	# Если журнал открыт — обновляем немедленно.
	if visible:
		_rebuild_entries()

func _on_close_pressed() -> void:
	_close()

func _on_backdrop_pressed() -> void:
	_close()
