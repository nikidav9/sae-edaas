extends CanvasLayer
class_name SaveMenu
## Меню сохранений/загрузок: 3 слота, автосохранение на слоте 0.
## Открывается кнопкой в HUD. Показывает день и дату каждого слота.

const SLOT_COUNT := SaveSystem.SLOT_COUNT

@onready var panel: PanelContainer = %Panel
@onready var slots_container: VBoxContainer = %SlotsContainer
@onready var title_label: Label = %TitleLabel

var _mode: String = "save"  # "save" | "load"

func _ready() -> void:
	hide()
	EventBus.save_completed.connect(func(_s: int) -> void: _rebuild() if visible else void)
	EventBus.load_completed.connect(func(_s: int) -> void: hide())

func open_save() -> void:
	_mode = "save"
	title_label.text = "Сохранить игру"
	_rebuild()
	_show_panel()

func open_load() -> void:
	_mode = "load"
	title_label.text = "Загрузить игру"
	_rebuild()
	_show_panel()

func toggle_save() -> void:
	if visible and _mode == "save":
		_close()
	else:
		open_save()

# --- Слайд-анимация ---

func _show_panel() -> void:
	show()
	panel.position.y = 500
	var tween := create_tween()
	tween.tween_property(panel, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _close() -> void:
	var tween := create_tween()
	tween.tween_property(panel, "position:y", 500.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(hide)

func _on_close_pressed() -> void:
	_close()

# --- Построение слотов ---

func _rebuild() -> void:
	for c in slots_container.get_children():
		c.queue_free()
	for i in SLOT_COUNT:
		slots_container.add_child(_make_slot_row(i))

func _make_slot_row(slot: int) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Метка слота.
	var slot_label := Label.new()
	slot_label.custom_minimum_size = Vector2(80, 0)
	slot_label.text = "Авто" if slot == 0 else ("Слот %d" % slot)
	slot_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(slot_label)

	# Информация о сейве.
	var info_label := Label.new()
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.add_theme_font_size_override("font_size", 14)
	var info := SaveSystem.slot_info(slot)
	if info.is_empty():
		info_label.text = "— пусто —"
		info_label.modulate = Color(0.5, 0.5, 0.5)
	else:
		var dt := Time.get_datetime_dict_from_unix_time(int(info.get("saved_at", 0)))
		info_label.text = "День %d  ·  %02d:%02d %02d.%02d" % [
			info.get("day", 1),
			dt.get("hour", 0), dt.get("minute", 0),
			dt.get("day", 1),  dt.get("month", 1),
		]
	hbox.add_child(info_label)

	# Кнопка основного действия.
	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(90, 44)
	action_btn.text = "Сохранить" if _mode == "save" else "Загрузить"
	if _mode == "load" and info.is_empty():
		action_btn.disabled = true
		action_btn.modulate = Color(0.5, 0.5, 0.5)
	action_btn.pressed.connect(func() -> void: _on_action(slot))
	hbox.add_child(action_btn)

	# Кнопка удаления (только если есть сейв).
	if not info.is_empty():
		var del_btn := Button.new()
		del_btn.custom_minimum_size = Vector2(44, 44)
		del_btn.text = "🗑"
		del_btn.theme_override_colors = {"font_color": Color(1, 0.3, 0.3)}
		del_btn.pressed.connect(func() -> void: _on_delete(slot))
		hbox.add_child(del_btn)

	# Разделитель снизу.
	var vbox := VBoxContainer.new()
	vbox.add_child(hbox)
	vbox.add_child(HSeparator.new())
	return vbox

# --- Действия ---

func _on_action(slot: int) -> void:
	if _mode == "save":
		SaveSystem.save_game(slot)
		_rebuild()
		# Краткое подтверждение.
		_flash_confirm("Сохранено!")
	else:
		SaveSystem.load_game(slot)
		_close()

func _on_delete(slot: int) -> void:
	SaveSystem.delete_save(slot)
	_rebuild()

func _flash_confirm(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate = Color(0.4, 1.0, 0.4)
	slots_container.add_child(lbl)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tween.tween_callback(lbl.queue_free)

# Заглушка для void-лямбды в connect.
func void() -> void:
	pass
