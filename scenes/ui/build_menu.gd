extends CanvasLayer
class_name BuildMenu
## Меню строительства: карточки зданий + режим размещения с призраком + режим сноса.

const GHOST_ALPHA := 0.5

@onready var panel: PanelContainer = %Panel
@onready var cards_container: HFlowContainer = %CardsContainer
@onready var close_button: Button = %CloseButton
@onready var ghost: ColorRect = %Ghost

var _building_system: BuildingSystem
var _grid: BaseGrid
var _selected: BuildingData = null
var _placement_mode: bool = false
var _demolish_mode: bool = false

func _ready() -> void:
	hide()
	ghost.hide()
	close_button.pressed.connect(_on_close_pressed)
	EventBus.build_mode_entered.connect(_on_build_mode_entered)
	EventBus.build_mode_exited.connect(_on_build_mode_exited)

func _find_systems() -> void:
	var root := get_tree().root
	for child in root.get_children():
		if _building_system == null:
			var s := child.find_child("BuildingSystem", true, false)
			if s is BuildingSystem:
				_building_system = s
		if _grid == null:
			var g := child.find_child("BaseGrid", true, false)
			if g is BaseGrid:
				_grid = g

# --- Открытие / закрытие ---

func _on_build_mode_entered() -> void:
	_find_systems()
	_rebuild_cards()
	show()
	_exit_placement()
	_demolish_mode = false
	var tween := create_tween()
	panel.position.y = 400
	tween.tween_property(panel, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_build_mode_exited() -> void:
	_exit_placement()
	_demolish_mode = false
	hide()

func _on_close_pressed() -> void:
	EventBus.build_mode_exited.emit()

# --- Карточки ---

func _rebuild_cards() -> void:
	for c in cards_container.get_children():
		c.queue_free()
	if _building_system == null:
		return

	# Кнопка «Снести» с иконкой
	var demolish_btn := Button.new()
	demolish_btn.custom_minimum_size = Vector2(148, 56)
	demolish_btn.text = ""
	if _demolish_mode:
		demolish_btn.modulate = Color(1.0, 0.42, 0.42)
	demolish_btn.pressed.connect(_toggle_demolish_mode)
	var d_hbox := HBoxContainer.new()
	d_hbox.anchor_right = 1.0
	d_hbox.anchor_bottom = 1.0
	d_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	d_hbox.theme_override_constants_separation = 6
	d_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	demolish_btn.add_child(d_hbox)
	var d_icon := GameIcon.new()
	d_icon.icon_type = GameIcon.IconType.DEMOLISH
	d_icon.draw_background = false
	d_icon.custom_minimum_size = Vector2(28, 28)
	d_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	d_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d_hbox.add_child(d_icon)
	var d_lbl := Label.new()
	d_lbl.text = "Снести"
	d_lbl.add_theme_font_size_override("font_size", 14)
	d_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	d_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d_hbox.add_child(d_lbl)
	cards_container.add_child(demolish_btn)

	for data in _building_system.get_catalogue():
		cards_container.add_child(_make_card(data))

func _toggle_demolish_mode() -> void:
	_demolish_mode = not _demolish_mode
	_exit_placement()
	_rebuild_cards()

func _make_card(data: BuildingData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(148, 0)
	if not data.can_afford():
		panel.modulate = Color(0.60, 0.60, 0.60)

	var vbox := VBoxContainer.new()
	vbox.theme_override_constants_separation = 5
	panel.add_child(vbox)

	# Название здания
	var name_lbl := Label.new()
	name_lbl.text = data.display_name
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_lbl)

	# Стоимость: иконка ресурса + количество
	if not data.build_cost.is_empty():
		var cost_row := HBoxContainer.new()
		cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
		cost_row.theme_override_constants_separation = 5
		vbox.add_child(cost_row)
		for res_id: String in data.build_cost:
			var r_icon := GameIcon.new()
			r_icon.icon_type = _res_icon_type(res_id)
			r_icon.draw_background = false
			r_icon.custom_minimum_size = Vector2(22, 22)
			r_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cost_row.add_child(r_icon)
			var r_lbl := Label.new()
			r_lbl.text = str(data.build_cost[res_id])
			r_lbl.add_theme_font_size_override("font_size", 13)
			r_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cost_row.add_child(r_lbl)

	# Время строительства: иконка молотка + дни
	if data.build_time_days > 0:
		var time_row := HBoxContainer.new()
		time_row.alignment = BoxContainer.ALIGNMENT_CENTER
		time_row.theme_override_constants_separation = 4
		vbox.add_child(time_row)
		var t_icon := GameIcon.new()
		t_icon.icon_type = GameIcon.IconType.BUILD
		t_icon.draw_background = false
		t_icon.custom_minimum_size = Vector2(18, 18)
		t_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		time_row.add_child(t_icon)
		var t_lbl := Label.new()
		t_lbl.text = "%d д." % data.build_time_days
		t_lbl.add_theme_font_size_override("font_size", 12)
		t_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		time_row.add_child(t_lbl)

	# Бонус: иконка + значение
	var b_type := _bonus_icon_type(data)
	var b_text := _bonus_text(data)
	if b_type >= 0 and not b_text.is_empty():
		var bonus_row := HBoxContainer.new()
		bonus_row.alignment = BoxContainer.ALIGNMENT_CENTER
		bonus_row.theme_override_constants_separation = 4
		vbox.add_child(bonus_row)
		var b_icon := GameIcon.new()
		b_icon.icon_type = b_type as GameIcon.IconType
		b_icon.draw_background = false
		b_icon.custom_minimum_size = Vector2(18, 18)
		b_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bonus_row.add_child(b_icon)
		var b_lbl := Label.new()
		b_lbl.text = b_text
		b_lbl.add_theme_font_size_override("font_size", 12)
		b_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bonus_row.add_child(b_lbl)

	# Кнопка «Построить»
	var btn := Button.new()
	btn.text = "Построить"
	btn.add_theme_font_size_override("font_size", 13)
	btn.disabled = not data.can_afford()
	btn.pressed.connect(func() -> void: _select_building(data))
	vbox.add_child(btn)

	return panel

func _res_icon_type(res_id: String) -> GameIcon.IconType:
	match res_id:
		"food":      return GameIcon.IconType.FOOD
		"materials": return GameIcon.IconType.MATERIALS
		"medicine":  return GameIcon.IconType.MEDICINE
		"stone":     return GameIcon.IconType.STONE
		"metal":     return GameIcon.IconType.METAL
	return GameIcon.IconType.MATERIALS

func _bonus_icon_type(data: BuildingData) -> int:
	if data.daily_food > 0:     return GameIcon.IconType.FOOD
	if data.daily_morale > 0.0: return GameIcon.IconType.MORALE
	if data.defense_bonus > 0:  return GameIcon.IconType.SHIELD
	return -1

func _bonus_text(data: BuildingData) -> String:
	if data.daily_food > 0:     return "+%d/д" % data.daily_food
	if data.daily_morale > 0.0: return "+%.0f%%/д" % (data.daily_morale * 100.0)
	if data.defense_bonus > 0:  return "+%d" % data.defense_bonus
	return ""

# --- Режим размещения ---

func _select_building(data: BuildingData) -> void:
	_demolish_mode = false
	_selected = data
	_placement_mode = true
	ghost.size = Vector2(data.size_cells) * BaseGrid.CELL_SIZE
	ghost.color = Color(0.3, 1.0, 0.3, GHOST_ALPHA)
	ghost.show()

func _exit_placement() -> void:
	_placement_mode = false
	_selected = null
	ghost.hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed:
			return
		var world_pos := _screen_to_world(touch.position)
		var cell := _grid.world_to_cell(world_pos) if _grid != null else Vector2i.ZERO

		if _demolish_mode and _grid != null and _building_system != null:
			_building_system.demolish(cell)
			_rebuild_cards()
			return

		if _placement_mode and _selected != null and _grid != null:
			if _grid.can_place(_selected, cell):
				EventBus.build_requested.emit(_selected, cell)
				_exit_placement()
				EventBus.build_mode_exited.emit()

	elif event is InputEventScreenDrag:
		if not _placement_mode or _grid == null:
			return
		var world_pos := _screen_to_world(event.position)
		var cell := _grid.world_to_cell(world_pos)
		var snapped := _grid.cell_to_world(cell)
		ghost.position = snapped
		var can := _grid.can_place(_selected, cell) and _selected.can_afford()
		ghost.color = Color(0.3, 1.0, 0.3, GHOST_ALPHA) if can else Color(1.0, 0.2, 0.2, GHOST_ALPHA)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var cam := get_viewport().get_camera_2d()
	if cam:
		return screen_pos + cam.global_position - get_viewport().get_visible_rect().size * 0.5
	return screen_pos
