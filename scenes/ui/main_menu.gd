extends Control
class_name MainMenu

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	var has_save := false
	for slot in SaveSystem.SLOT_COUNT:
		if not SaveSystem.slot_info(slot).is_empty():
			has_save = true
			break
	continue_button.disabled = not has_save
	version_label.text = "v0.1 alpha"

	_play_entrance()
	_start_glitch_timer()

func _play_entrance() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	new_game_button.modulate.a = 0.0
	continue_button.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(0.2)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.65)
	tween.tween_interval(0.15)
	tween.tween_property(new_game_button, "modulate:a", 1.0, 0.5)
	tween.tween_interval(0.1)
	tween.tween_property(continue_button, "modulate:a", 1.0, 0.5)

func _start_glitch_timer() -> void:
	var timer := Timer.new()
	timer.one_shot = false
	timer.wait_time = randf_range(3.5, 7.0)
	timer.timeout.connect(_do_glitch.bind(timer))
	add_child(timer)
	timer.start()

func _do_glitch(timer: Timer) -> void:
	# Сохраняем оригинальный цвет чтобы вернуть после глитча
	var orig := title_label.modulate
	var orig_pos := title_label.position

	var tween := create_tween()
	tween.tween_callback(func():
		title_label.modulate = Color(1.0, 0.04, 0.04, 1.0)
		title_label.position = orig_pos + Vector2(randf_range(-8, 8), 0)
	)
	tween.tween_interval(0.042)
	tween.tween_callback(func():
		title_label.modulate = Color(0.04, 0.9, 0.94, 1.0)
		title_label.position = orig_pos + Vector2(randf_range(-5, 5), randf_range(-3, 3))
	)
	tween.tween_interval(0.038)
	tween.tween_callback(func():
		title_label.modulate = Color(1.0, 0.04, 0.04, 1.0)
		title_label.position = orig_pos + Vector2(randf_range(-4, 4), 0)
	)
	tween.tween_interval(0.035)
	tween.tween_callback(func():
		title_label.modulate = orig
		title_label.position = orig_pos
	)
	timer.wait_time = randf_range(3.5, 8.0)

func _on_new_game_pressed() -> void:
	GameLoopManager.start_new_game()

func _on_continue_pressed() -> void:
	var best_slot := -1
	var best_time := 0
	for slot in SaveSystem.SLOT_COUNT:
		var info := SaveSystem.slot_info(slot)
		if info.is_empty():
			continue
		var t := int(info.get("saved_at", 0))
		if t > best_time:
			best_time = t
			best_slot = slot
	if best_slot >= 0:
		GameLoopManager.continue_game(best_slot)
