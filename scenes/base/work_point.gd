extends Node2D
class_name WorkPoint
## Точка работы — место в лагере, куда приходит NPC с нужным умением.
##
## Одна точка = один NPC. NPCManager ищет свободные точки при рекруте.
## Привязана к структуре (вышка, грядка, мастерская) через ability_id.

## Какое умение нужно чтобы работать в этой точке.
@export var required_ability_id: StringName = &""
## Помечаем визуально в редакторе (иконка или цвет).
@export var debug_color: Color = Color(0.3, 0.8, 0.5, 0.6)

var _occupant: NPCController = null

func is_free() -> bool:
	return _occupant == null or not is_instance_valid(_occupant)

func occupy(npc: NPCController) -> void:
	_occupant = npc

func release() -> void:
	_occupant = null

func _draw() -> void:
	# Видно только в редакторе: крест + кружок.
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, 8.0, debug_color)
	draw_line(Vector2(-10, 0), Vector2(10, 0), debug_color, 2.0)
	draw_line(Vector2(0, -10), Vector2(0, 10), debug_color, 2.0)
