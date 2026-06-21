extends Control
class_name VirtualJoystick
## Виртуальный джойстик для мобильного управления (левая половина экрана).
## Возвращает нормализованный вектор направления через get_direction().

const DEAD_ZONE := 10.0
const VISUAL_RADIUS := 60.0

@onready var base_circle: Control = %BaseCircle
@onready var stick_circle: Control = %StickCircle

var direction: Vector2 = Vector2.ZERO
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO

func _ready() -> void:
	_center = size * 0.5

func _input(event: InputEventScreenTouch) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var local_pos := get_local_mouse_position()
	if event.pressed:
		if _touch_index < 0 and event.position.x < get_viewport_rect().size.x * 0.5:
			_touch_index = event.index
			_center = get_global_transform().affine_inverse() * event.position
			_update_stick(_center)
	else:
		if event.index == _touch_index:
			_release()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var local_pos := get_global_transform().affine_inverse() * event.position
	_update_stick(local_pos)

func _update_stick(pos: Vector2) -> void:
	var delta := pos - _center
	var dist := delta.length()
	if dist < DEAD_ZONE:
		direction = Vector2.ZERO
		stick_circle.position = _center - stick_circle.size * 0.5
		return
	var clamped := delta.normalized() * minf(dist, VISUAL_RADIUS)
	direction = delta.normalized() if dist > DEAD_ZONE else Vector2.ZERO
	stick_circle.position = _center + clamped - stick_circle.size * 0.5

func _release() -> void:
	_touch_index = -1
	direction = Vector2.ZERO
	stick_circle.position = _center - stick_circle.size * 0.5

func get_direction() -> Vector2:
	# Также поддерживаем клавиатуру для тестирования на ПК.
	var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if kb.length() > 0.1:
		return kb
	return direction
