extends CanvasLayer
class_name DialogueUI
## UI экрана диалога с визитёром.
##
## Слушает DialogueSystem (не EventBus напрямую — движок сигнализирует этот UI).
## Рисует: портрет, имя, текст (typewriter), таймер-бар, кнопки вариантов.
## Typewriter: текст появляется посимвольно → добавляет tension даже без таймера.

const TYPEWRITER_SPEED: float = 40.0  # символов/сек

@onready var root_panel: PanelContainer = %RootPanel
@onready var timer_bar: ProgressBar = %TimerBar
@onready var portrait: TextureRect = %Portrait
@onready var speaker_name: Label = %SpeakerName
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var options_container: VBoxContainer = %OptionsContainer

var _dialogue_system: DialogueSystem
var _full_text: String = ""
var _shown_chars: int = 0
var _typewriter_active: bool = false
var _typewriter_timer: float = 0.0
var _current_visitor: VisitorData
var _pending_options: Array[DialogueOption] = []
var _total_time: float = 15.0

func _ready() -> void:
	hide()
	_dialogue_system = _find_dialogue_system()
	if _dialogue_system:
		_dialogue_system.dialogue_node_shown.connect(_on_node_shown)
		_dialogue_system.dialogue_ended.connect(_on_dialogue_ended)
		_dialogue_system.timer_tick.connect(_on_timer_tick)

func _process(delta: float) -> void:
	if not _typewriter_active:
		return
	_typewriter_timer += delta
	var chars_to_show := int(_typewriter_timer * TYPEWRITER_SPEED)
	if chars_to_show > _shown_chars:
		_shown_chars = mini(chars_to_show, _full_text.length())
		dialogue_text.text = _full_text.substr(0, _shown_chars)
		if _shown_chars >= _full_text.length():
			_typewriter_active = false
			_show_options()

# --- Входящие события ---

func _on_node_shown(visitor: VisitorData, node: DialogueNode) -> void:
	_current_visitor = visitor
	show()
	_update_portrait(visitor)
	var speaker := node.speaker if not node.speaker.is_empty() else visitor.display_name
	speaker_name.text = speaker
	_clear_options()
	_pending_options = _dialogue_system.visible_options_for(node)
	# Запускаем typewriter; кнопки появятся после прочтения текста.
	_start_typewriter(node.text)

func _on_dialogue_ended(_visitor: VisitorData) -> void:
	hide()
	_clear_options()

func _on_timer_tick(seconds_left: float) -> void:
	timer_bar.value = seconds_left / _total_time

# --- Typewriter ---

func _start_typewriter(text: String) -> void:
	_full_text = text
	_shown_chars = 0
	_typewriter_timer = 0.0
	_typewriter_active = true
	dialogue_text.text = ""

## Тап по тексту — сразу показывает весь текст (мобильный UX).
func _on_text_panel_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and _typewriter_active:
		_typewriter_active = false
		dialogue_text.text = _full_text
		_shown_chars = _full_text.length()
		_show_options()

# --- Кнопки ---

func _show_options() -> void:
	_clear_options()
	for i in _pending_options.size():
		var opt: DialogueOption = _pending_options[i]
		var btn := Button.new()
		btn.text = opt.label
		btn.custom_minimum_size = Vector2(0, 64)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Серая кнопка если игрок не может себе это позволить (нет ресурсов).
		if not _can_afford(opt):
			btn.modulate = Color(0.6, 0.6, 0.6, 1.0)
			btn.disabled = true
		var idx := i
		btn.pressed.connect(func() -> void: _on_option_pressed(idx))
		options_container.add_child(btn)

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

func _on_option_pressed(index: int) -> void:
	_dialogue_system.select_option(index)

func _can_afford(opt: DialogueOption) -> bool:
	for res_id in opt.resource_cost:
		if not GameState.can_afford(res_id, int(opt.resource_cost[res_id])):
			return false
	return true

# --- Портрет ---

func _update_portrait(visitor: VisitorData) -> void:
	if visitor.portrait:
		portrait.texture = visitor.portrait
		portrait.show()
	else:
		portrait.hide()

# --- Поиск движка ---

func _find_dialogue_system() -> DialogueSystem:
	var root := get_tree().root
	for child in root.get_children():
		var found := child.find_child("DialogueSystem", true, false)
		if found is DialogueSystem:
			return found as DialogueSystem
	return null
