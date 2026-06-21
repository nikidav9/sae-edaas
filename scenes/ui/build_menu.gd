extends CanvasLayer
class_name BuildMenu
## Меню строительства: карточки зданий + режим размещения с призраком.
##
## Поток:
##   1. Игрок нажимает кнопку Build в HUD → EventBus.build_mode_entered
##   2. BuildMenu показывает панель с карточками каталога.
##   3. Игрок тапает карточку → входит в режим размещения (placement mode).
##   4. Призрак следует за пальцем, зелёный = можно, красный = нельзя.
##   5. Игрок тапает позицию → EventBus.build_requested → меню скрывается.
##   6. Крестик или повторный тап без места → выход из режима.

const GHOST_ALPHA := 0.5

@onready var panel: PanelContainer = %Panel
@onready var cards_container: HFlowContainer = %CardsContainer
@onready var close_button: Button = %CloseButton
@onready var ghost: ColorRect = %Ghost

var _building_system: BuildingSystem
var _grid: BaseGrid
var _selected: BuildingData = null
var _placement_mode: bool = false

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
	var tween := create_tween()
	panel.position.y = 400
	tween.tween_property(panel, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_build_mode_exited() -> void:
	_exit_placement()
	hide()

func _on_close_pressed() -> void:
	EventBus.build_mode_exited.emit()

# --- Карточки ---

func _rebuild_cards() -> void:
	for c in cards_container.get_children():
		c.queue_free()
	if _building_system == null:
		return
	for data in _building_system.get_catalogue():
		cards_container.add_child(_make_card(data))

func _make_card(data: BuildingData) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(140, 110)
	var cost_text := ""
	for res_id in data.build_cost:
		cost_text += "%s: %d  " % [res_id, data.build_cost[res_id]]
	btn.text = "%s\n%s\n%s" % [
		data.display_name,
		cost_text.strip_edges(),
		("⏳ %d д." % data.build_time_days) if data.build_time_days > 0 else "Мгновенно"
	]
	btn.disabled = not data.can_afford()
	if not data.can_afford():
		btn.modulate = Color(0.6, 0.6, 0.6)
	btn.pressed.connect(func() -> void: _select_building(data))
	return btn

# --- Режим размещения ---

func _select_building(data: BuildingData) -> void:
	_selected = data
	_placement_mode = true
	# Настраиваем призрак под размер здания.
	ghost.size = Vector2(data.size_cells) * BaseGrid.CELL_SIZE
	ghost.color = Color(0.3, 1.0, 0.3, GHOST_ALPHA)
	ghost.show()

func _exit_placement() -> void:
	_placement_mode = false
	_selected = null
	ghost.hide()

func _input(event: InputEvent) -> void:
	if not _placement_mode or _selected == null or _grid == null:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var world_pos := _screen_to_world(touch.position)
			var cell := _grid.world_to_cell(world_pos)
			if _grid.can_place(_selected, cell):
				EventBus.build_requested.emit(_selected, cell)
				_exit_placement()
				EventBus.build_mode_exited.emit()
	elif event is InputEventScreenDrag:
		var world_pos := _screen_to_world(event.position)
		var cell := _grid.world_to_cell(world_pos)
		var snapped := _grid.cell_to_world(cell)
		ghost.position = snapped
		var can := _grid.can_place(_selected, cell) and _selected.can_afford()
		ghost.color = Color(0.3, 1.0, 0.3, GHOST_ALPHA) if can else Color(1.0, 0.2, 0.2, GHOST_ALPHA)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	# Приближение: ищем Camera2D в сцене.
	var cam := get_viewport().get_camera_2d()
	if cam:
		return screen_pos + cam.global_position - get_viewport().get_visible_rect().size * 0.5
	return screen_pos
