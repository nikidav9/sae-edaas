extends Node2D
class_name Lantern
## Фонарь/источник тёплого света. Активируется ночью, мерцает.
##
## Добавить в группу "lanterns" в редакторе (или в _ready) — тогда
## DayNightEnvironment автоматически включит/выключит все фонари разом.
##
## Для окна здания: тот же скрипт, поставить window_color.

@export var light_color: Color = Color(1.0, 0.75, 0.3, 1.0)   # тёплый янтарь
@export var light_energy_day: float = 0.0
@export var light_energy_night: float = 1.2
@export var flicker_speed: float = 3.5    # Hz колебаний яркости
@export var flicker_amplitude: float = 0.15  # ±амплитуда от base energy

@onready var point_light: PointLight2D = $PointLight2D
@onready var sprite: Sprite2D = $Sprite2D  # иконка фонаря (placeholder пока)

var _base_energy: float = 0.0
var _time: float = 0.0
var _is_night: bool = false

func _ready() -> void:
	add_to_group("lanterns")
	point_light.color = light_color
	point_light.energy = light_energy_day
	_base_energy = light_energy_day

func _process(delta: float) -> void:
	if not _is_night:
		return
	_time += delta * flicker_speed
	# Мерцание: сумма двух синусоид с разными частотами — выглядит органично.
	var flicker := sin(_time) * 0.6 + sin(_time * 2.3 + 1.1) * 0.4
	point_light.energy = _base_energy + flicker * flicker_amplitude

## Вызывается из группы DayNightEnvironment.call_group("lanterns", "set_night_mode", true/false).
func set_night_mode(night: bool) -> void:
	_is_night = night
	_base_energy = light_energy_night if night else light_energy_day
	if not night:
		point_light.energy = light_energy_day
