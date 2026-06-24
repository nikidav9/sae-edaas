extends CanvasLayer
class_name ExpeditionPanel
## Панель экспедиций: отправка NPC, отслеживание прогресса, отчёт о результатах.

const NPC_DATA_DIR := "res://resources/npc_data"

@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var content_box: VBoxContainer = %ContentBox
@onready var close_button: Button = %CloseButton

var _expedition_system: ExpeditionSystem = null

func _ready() -> void:
	hide()
	add_to_group("expedition_panel")
	%CloseButton.pressed.connect(_on_close_pressed)
	EventBus.expedition_completed.connect(_on_expedition_resolved.bind(true))
	EventBus.expedition_failed.connect(func(aid, _r): _on_expedition_resolved(aid, false))
	EventBus.npc_recruited.connect(func(_d):
		if visible:
			_rebuild()
	)

func setup(exp_system: ExpeditionSystem) -> void:
	_expedition_system = exp_system

func toggle() -> void:
	if visible:
		_close()
	else:
		_open()

func _open() -> void:
	_rebuild()
	show()
	panel.position.y = 600
	var tween := create_tween()
	tween.tween_property(panel, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _close() -> void:
	var tween := create_tween()
	tween.tween_property(panel, "position:y", 600.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(hide)

func _on_close_pressed() -> void:
	_close()

func _rebuild() -> void:
	for c in content_box.get_children():
		c.queue_free()

	# --- Активные экспедиции ---
	if not GameState.active_expeditions.is_empty():
		var hdr := _make_header("В пути:")
		content_box.add_child(hdr)
		for ability_id in GameState.active_expeditions:
			var days_left: int = GameState.active_expeditions[ability_id]
			var row := _make_active_row(ability_id, days_left)
			content_box.add_child(row)
		content_box.add_child(HSeparator.new())

	# --- Доступные NPC ---
	var all_data := _load_npc_data()
	var available: Array[NPCData] = []
	for d in all_data:
		var aid := String(d.ability_id)
		if GameState.has_ability(aid) and not GameState.active_expeditions.has(aid):
			available.append(d)

	if available.is_empty():
		var lbl := Label.new()
		lbl.text = "Нет доступных бойцов для экспедиции."
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 15)
		content_box.add_child(lbl)
	else:
		var hdr := _make_header("Отправить в экспедицию:")
		content_box.add_child(hdr)
		for d in available:
			content_box.add_child(_make_npc_row(d))

func _make_header(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = Color(0.6, 0.6, 0.6)
	return lbl

func _make_active_row(ability_id: String, days_left: int) -> Control:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = ability_id
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 15)
	var day_lbl := Label.new()
	day_lbl.text = "↩ через %d д." % days_left
	day_lbl.add_theme_font_size_override("font_size", 14)
	day_lbl.modulate = Color(0.6, 0.9, 0.6)
	hbox.add_child(lbl)
	hbox.add_child(day_lbl)
	return hbox

func _make_npc_row(d: NPCData) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = d.display_name if d.get("display_name") else String(d.ability_id)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 15)

	var b := GameState.balance
	var days := b.expedition_base_days
	if d.ability_id == &"scout_recon":
		days = maxi(1, days - b.expedition_scout_bonus_days)
	var dur_lbl := Label.new()
	dur_lbl.text = "%d д." % days
	dur_lbl.add_theme_font_size_override("font_size", 13)
	dur_lbl.modulate = Color(0.7, 0.7, 0.7)

	var btn := Button.new()
	btn.text = "→ Отправить"
	btn.custom_minimum_size = Vector2(110, 40)
	btn.add_theme_font_size_override("font_size", 13)
	var aid := String(d.ability_id)
	btn.pressed.connect(func() -> void:
		if _expedition_system:
			_expedition_system.start_expedition(aid)
			_rebuild()
	)
	hbox.add_child(lbl)
	hbox.add_child(dur_lbl)
	hbox.add_child(btn)
	return hbox

func _on_expedition_resolved(ability_id: String, success: bool) -> void:
	if not visible:
		return
	_rebuild()
	# Краткое уведомление.
	var lbl := Label.new()
	lbl.text = "✓ %s вернулся!" % ability_id if success else "✗ %s не вернулся." % ability_id
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.modulate = Color(0.4, 1.0, 0.4) if success else Color(1.0, 0.4, 0.4)
	lbl.add_theme_font_size_override("font_size", 16)
	content_box.add_child(lbl)
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tween.tween_callback(lbl.queue_free)

func _load_npc_data() -> Array[NPCData]:
	var result: Array[NPCData] = []
	var dir := DirAccess.open(NPC_DATA_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var d := load(NPC_DATA_DIR.path_join(fname)) as NPCData
			if d:
				result.append(d)
		fname = dir.get_next()
	dir.list_dir_end()
	return result
