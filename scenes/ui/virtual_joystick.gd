extends Control
class_name VirtualJoystick
## Плавающий виртуальный джойстик (LDOE-стиль).
## Появляется в точке касания левой половины экрана.
## Правая половина зарезервирована для кнопки действия.

const DEAD_ZONE := 8.0
const MAX_RADIUS := 80.0

@onready var base_circle: Control = %BaseCircle
@onready var stick_circle: Control = %StickCircle

var direction: Vector2 = Vector2.ZERO
var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	base_circle.hide()
	stick_circle.hide()

func get_direction() -> Vector2:
	var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if kb.length() > 0.1:
		return kb
	return direction

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)

func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Принимаем только касания левой половины экрана
		if event.position.x >= get_viewport_rect().size.x * 0.5:
			return
		if _touch_index >= 0:
			return
		_touch_index = event.index
		_origin = event.position
		base_circle.position = _origin - base_circle.size * 0.5
		stick_circle.position = _origin - stick_circle.size * 0.5
		base_circle.show()
		stick_circle.show()
		direction = Vector2.ZERO
	elif event.index == _touch_index:
		_release()

func _on_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var delta := event.position - _origin
	var dist := delta.length()
	var clamped := delta.normalized() * minf(dist, MAX_RADIUS)
	stick_circle.position = _origin + clamped - stick_circle.size * 0.5
	direction = clamped.normalized() if dist > DEAD_ZONE else Vector2.ZERO

func _release() -> void:
	_touch_index = -1
	direction = Vector2.ZERO
	base_circle.hide()
	stick_circle.hide()
