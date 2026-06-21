extends Node2D
class_name DayNightEnvironment
## Визуальный контроллер дня/ночи.
##
## Слушает DayNightSystem через EventBus и плавно меняет:
##   - CanvasModulate (глобальный тинт неба/мира)
##   - DirectionalLight2D (солнце)
##   - Группа "lanterns" активируется ночью автоматически.
##
## Этот узел вставляется в сцену базы/мира, не в autoload.

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var sun_light: DirectionalLight2D = $SunLight

## Длительность плавного перехода между фазами (сек).
@export var transition_duration: float = 6.0

var _tween: Tween
var _day_night_system: DayNightSystem

func _ready() -> void:
	EventBus.day_phase_changed.connect(_on_phase_changed)
	# Находим DayNightSystem среди детей Main (он там живёт).
	_day_night_system = _find_system()
	# Ставим начальный цвет без анимации.
	if _day_night_system:
		canvas_modulate.color = _day_night_system.get_sky_color()
	_update_lanterns(false)

func _process(_delta: float) -> void:
	# Каждый кадр плавно тянемся к текущему цвету — Tween уже делает это,
	# но для SubTween в phase_progress нужен ручной lerp если нет события.
	pass

func _on_phase_changed(phase: int, _progress: float) -> void:
	if _day_night_system == null:
		return
	var target_color := _day_night_system.get_sky_color()
	_animate_to(target_color)
	var is_night := phase == DayNightSystem.Phase.NIGHT
	_update_sun(phase)
	_update_lanterns(is_night)

func _animate_to(color: Color) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(canvas_modulate, "color", color, transition_duration)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _update_sun(phase: int) -> void:
	if sun_light == null:
		return
	match phase:
		DayNightSystem.Phase.DAWN:
			sun_light.energy = 0.4
			sun_light.color = Color(0.9, 0.7, 0.6)
		DayNightSystem.Phase.DAY:
			sun_light.energy = 1.0
			sun_light.color = Color(1.0, 0.98, 0.92)
		DayNightSystem.Phase.DUSK:
			sun_light.energy = 0.5
			sun_light.color = Color(1.0, 0.6, 0.2)
		DayNightSystem.Phase.NIGHT:
			sun_light.energy = 0.05
			sun_light.color = Color(0.3, 0.35, 0.6)

## Включаем/выключаем все фонари в группе "lanterns".
func _update_lanterns(night: bool) -> void:
	get_tree().call_group("lanterns", "set_night_mode", night)

func _find_system() -> DayNightSystem:
	# DayNightSystem — дочерний узел Main (не autoload).
	var root := get_tree().root
	for child in root.get_children():
		var found := child.find_child("DayNightSystem", true, false)
		if found is DayNightSystem:
			return found as DayNightSystem
	return null
