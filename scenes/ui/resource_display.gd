extends HBoxContainer
class_name ResourceDisplay
## Виджет одного ресурса: каменная иконка + число.
## Подписывается на EventBus.resource_changed и обновляется сам.

@export var resource_id: String = "food"

@onready var game_icon: GameIcon = $GameIcon
@onready var count_label: Label = $CountLabel

func _ready() -> void:
	game_icon.icon_type = _get_icon_type()
	game_icon.queue_redraw()
	_refresh()
	EventBus.resource_changed.connect(_on_resource_changed)

func _get_icon_type() -> GameIcon.IconType:
	match resource_id:
		"food":      return GameIcon.IconType.FOOD
		"materials": return GameIcon.IconType.MATERIALS
		"medicine":  return GameIcon.IconType.MEDICINE
		"stone":     return GameIcon.IconType.STONE
		"metal":     return GameIcon.IconType.METAL
	return GameIcon.IconType.FOOD

func _refresh() -> void:
	count_label.text = str(GameState.get_resource(resource_id))

func _on_resource_changed(id: String, amount: int) -> void:
	if id == resource_id:
		count_label.text = str(amount)
		_flash(amount)

func _flash(amount: int) -> void:
	var prev := int(count_label.text) if count_label.text.is_valid_int() else amount
	var color := Color(0.4, 1.0, 0.4) if amount >= prev else Color(1.0, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(count_label, "modulate", color, 0.1)
	tween.tween_property(count_label, "modulate", Color.WHITE, 0.4)
