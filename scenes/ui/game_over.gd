extends Control
class_name GameOverScreen

@onready var reason_label: Label = %ReasonLabel
@onready var day_label: Label = %DayLabel
@onready var resources_label: Label = %ResourcesLabel

func _ready() -> void:
	reason_label.text = GameState.game_over_reason
	day_label.text = "Прожито дней: %d" % GameState.current_day
	var r := GameState.resources
	resources_label.text = "Еда: %d  ·  Материалы: %d  ·  Медикаменты: %d" % [
		r.get("food", 0), r.get("materials", 0), r.get("medicine", 0)
	]
	# Плавное появление.
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)

func _on_restart_pressed() -> void:
	GameLoopManager.start_new_game()

func _on_menu_pressed() -> void:
	GameLoopManager.return_to_menu()
