extends Control
class_name MainMenu

@onready var continue_button: Button = %ContinueButton
@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	$VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
	%ContinueButton.pressed.connect(_on_continue_pressed)
	# Кнопка "Продолжить" активна только если есть хотя бы один сейв.
	var has_save := false
	for slot in SaveSystem.SLOT_COUNT:
		if not SaveSystem.slot_info(slot).is_empty():
			has_save = true
			break
	continue_button.disabled = not has_save
	version_label.text = "День 1  •  v0.1"

func _on_new_game_pressed() -> void:
	GameLoopManager.start_new_game()

func _on_continue_pressed() -> void:
	# Берём самый свежий сейв (manual > auto).
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
