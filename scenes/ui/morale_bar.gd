extends VBoxContainer
class_name MoraleBar
## Полоска морали с цветовым индикатором: зелёный → жёлтый → красный.

## Пороги для смены цвета (от 0 до 1).
const COLOR_HIGH := Color(0.25, 0.85, 0.35)   # > 0.6
const COLOR_MID  := Color(0.95, 0.80, 0.15)   # 0.3..0.6
const COLOR_LOW  := Color(0.90, 0.20, 0.15)   # < 0.3

@onready var label: Label = $Label
@onready var bar: ProgressBar = $Bar

func _ready() -> void:
	_refresh(GameState.group_morale)
	EventBus.morale_changed.connect(_on_morale_changed)

func _on_morale_changed(new_value: float, _delta: float) -> void:
	_refresh(new_value)

func _refresh(value: float) -> void:
	bar.value = value
	var color: Color
	if value > 0.6:
		color = COLOR_HIGH
	elif value > 0.3:
		color = COLOR_MID
	else:
		color = COLOR_LOW
	# Прокрашиваем саму полоску через StyleBoxFlat.
	var style := StyleBoxFlat.new()
	style.bg_color = color
	bar.add_theme_stylebox_override("fill", style)
	# Мигание при критическом значении.
	if value < 0.3:
		_pulse_warning()

func _pulse_warning() -> void:
	var tween := create_tween()
	tween.tween_property(bar, "modulate", Color(1, 0.3, 0.3, 0.5), 0.3)
	tween.tween_property(bar, "modulate", Color.WHITE, 0.3)
