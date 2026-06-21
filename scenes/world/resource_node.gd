extends StaticBody2D
class_name ResourceNode
## Ресурсный узел на карте: дерево, камень или куст.
## Игрок подходит и удерживает кнопку действия чтобы добыть ресурс.

enum NodeType { TREE = 0, ROCK = 1, BUSH = 2 }

@export var node_type: NodeType = NodeType.TREE

@onready var visual: Polygon2D = $Visual
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var resource_id: String = "materials"
var amount: int = 5
var gather_time: float = 2.0
var respawn_days: int = 3

var _gather_progress: float = 0.0
var _is_depleted: bool = false
var _day_depleted: int = 0

func _ready() -> void:
	add_to_group("resource_nodes")
	progress_bar.visible = false
	_apply_type()
	EventBus.day_passed.connect(_on_day_passed)

func _apply_type() -> void:
	match node_type:
		NodeType.TREE:
			resource_id = "materials"
			amount = 5
			gather_time = 2.0
			respawn_days = 3
			visual.polygon = PackedVector2Array([0,-26, 14,-8, 6,-8, 6,16, -6,16, -6,-8, -14,-8])
			visual.color = Color(0.18, 0.52, 0.14)
			label.text = "🌲"
		NodeType.ROCK:
			resource_id = "materials"
			amount = 3
			gather_time = 3.0
			respawn_days = 5
			visual.polygon = PackedVector2Array([-10,-6, -4,-14, 4,-14, 12,-6, 12,8, 4,14, -4,14, -12,8])
			visual.color = Color(0.54, 0.51, 0.47)
			label.text = "🪨"
		NodeType.BUSH:
			resource_id = "food"
			amount = 2
			gather_time = 1.0
			respawn_days = 1
			visual.polygon = PackedVector2Array([-14,2, -8,-12, 0,-16, 8,-12, 14,2, 10,14, -10,14])
			visual.color = Color(0.14, 0.4, 0.1)
			label.text = "🫐"

## Вызывается PlayerController каждый кадр пока удерживается кнопка.
## Возвращает true когда добыча завершена.
func tick_gather(delta: float) -> bool:
	if _is_depleted:
		return false
	_gather_progress += delta
	progress_bar.value = (_gather_progress / gather_time) * 100.0
	progress_bar.visible = true
	if _gather_progress >= gather_time:
		_complete()
		return true
	return false

## Вызывается когда игрок отпустил кнопку раньше времени.
func cancel_gather() -> void:
	_gather_progress = 0.0
	progress_bar.visible = false

func is_depleted() -> bool:
	return _is_depleted

func _complete() -> void:
	_is_depleted = true
	_day_depleted = GameState.current_day
	GameState.change_resource(resource_id, amount)
	progress_bar.visible = false
	visual.modulate.a = 0.25
	label.visible = false
	collision_shape.set_deferred("disabled", true)

func _on_day_passed(day: int) -> void:
	if _is_depleted and day >= _day_depleted + respawn_days:
		_is_depleted = false
		_gather_progress = 0.0
		visual.modulate.a = 1.0
		label.visible = true
		collision_shape.set_deferred("disabled", false)
