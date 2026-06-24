extends CanvasLayer
class_name DayNotification
## Кратковременное уведомление при смене дня/ночи.
## Появляется в центре экрана, плавно исчезает.

@onready var label: Label = $Label
@onready var bg: PanelContainer = $BG

## Фразы для ночи (выбираются случайно).
const NIGHT_PHRASES: Array[String] = [
	"Ночь наступила.",
	"Стало темно.",
	"Они выходят ночью.",
	"Держите периметр.",
]

func _ready() -> void:
	hide()
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.night_started.connect(_on_night_started)

func _on_day_passed(day: int) -> void:
	_show_message("День %d" % day, Color(1.0, 0.92, 0.6))

func _on_night_started(_day: int) -> void:
	var phrase: String = NIGHT_PHRASES[randi() % NIGHT_PHRASES.size()]
	_show_message(phrase, Color(0.5, 0.7, 1.0))

func _show_message(text: String, color: Color) -> void:
	label.text = text
	label.add_theme_color_override("font_color", color)
	bg.modulate = Color.WHITE
	label.modulate = Color.WHITE
	show()
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(bg, "modulate:a", 0.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(hide)
