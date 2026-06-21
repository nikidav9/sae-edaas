extends Node2D
class_name WindowLight
## Тёплый свет из окна здания. Ночью включается, слабо мерцает.
## Отличается от Lantern: нет спрайта, energy слабее, цвет чуть желтее.

@export var light_color: Color = Color(1.0, 0.88, 0.5, 1.0)
@export var light_energy_night: float = 0.55
@export var flicker_amplitude: float = 0.05

@onready var point_light: PointLight2D = $PointLight2D

var _time: float = 0.0
var _is_night: bool = false

func _ready() -> void:
	add_to_group("lanterns")
	point_light.color = light_color
	point_light.energy = 0.0

func _process(delta: float) -> void:
	if not _is_night:
		return
	_time += delta * 1.8
	var flicker := sin(_time) * 0.5 + sin(_time * 1.7 + 0.5) * 0.5
	point_light.energy = light_energy_night + flicker * flicker_amplitude

func set_night_mode(night: bool) -> void:
	_is_night = night
	if not night:
		point_light.energy = 0.0
