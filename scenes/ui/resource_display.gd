extends HBoxContainer
class_name ResourceDisplay
## Переиспользуемый виджет одного ресурса: иконка + число.
## Подписывается на EventBus.resource_changed и обновляется сам.

@export var resource_id: String = "food"
@export var icon_texture: Texture2D
@export var label_prefix: String = ""

@onready var prefix_label: Label = $PrefixLabel
@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $CountLabel

func _ready() -> void:
	if label_prefix != "":
		prefix_label.text = label_prefix
		prefix_label.show()
		icon.hide()
	else:
		prefix_label.hide()
		if icon_texture:
			icon.texture = icon_texture
	_refresh()
	EventBus.resource_changed.connect(_on_resource_changed)

func _refresh() -> void:
	count_label.text = str(GameState.get_resource(resource_id))

func _on_resource_changed(id: String, amount: int) -> void:
	if id == resource_id:
		count_label.text = str(amount)
		_flash(amount)

func _flash(amount: int) -> void:
	# Зелёная вспышка при росте, красная при убывании.
	var prev := int(count_label.text) if count_label.text.is_valid_int() else amount
	var color := Color(0.4, 1.0, 0.4) if amount >= prev else Color(1.0, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(count_label, "modulate", color, 0.1)
	tween.tween_property(count_label, "modulate", Color.WHITE, 0.4)
