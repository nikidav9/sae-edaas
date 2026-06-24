extends CanvasLayer
class_name HUD
## Главный HUD лагеря: ресурсы, мораль, день, иконка фазы, кнопки.
## Скрывается автоматически когда открыт диалог визитёра.

@onready var day_label: Label = %DayLabel
@onready var phase_icon: GameIcon = %PhaseIcon
@onready var food_display: ResourceDisplay = %FoodDisplay
@onready var materials_display: ResourceDisplay = %MaterialsDisplay
@onready var medicine_display: ResourceDisplay = %MedicineDisplay
@onready var morale_bar: MoraleBar = %MoraleBar
@onready var journal_button: Button = %JournalButton
@onready var journal_panel: JournalPanel = %JournalPanel
@onready var build_button: Button = %BuildButton
@onready var save_button: Button = %SaveButton
@onready var save_menu: SaveMenu = %SaveMenu
@onready var expedition_button: Button = %ExpeditionButton
@onready var craft_button: Button = %CraftButton
@onready var stone_display: ResourceDisplay = %StoneDisplay
@onready var metal_display: ResourceDisplay = %MetalDisplay
@onready var health_label: Label = %HealthLabel
@onready var interaction_prompt: Label = %InteractionPrompt

func _ready() -> void:
	journal_button.pressed.connect(_on_journal_button_pressed)
	build_button.pressed.connect(_on_build_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	expedition_button.pressed.connect(_on_expedition_button_pressed)
	craft_button.pressed.connect(_on_craft_button_pressed)
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.day_phase_changed.connect(_on_phase_changed)
	EventBus.visitor_dialogue_started.connect(_on_dialogue_started)
	EventBus.visitor_resolved.connect(_on_dialogue_ended)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	_refresh_day()
	call_deferred("_init_player_health")

func _on_day_passed(day: int) -> void:
	day_label.text = "День %d" % day

func _on_phase_changed(phase: int, _progress: float) -> void:
	var types: Array = [
		GameIcon.IconType.PHASE_DAWN,
		GameIcon.IconType.PHASE_DAY,
		GameIcon.IconType.PHASE_DUSK,
		GameIcon.IconType.PHASE_NIGHT,
	]
	if phase < types.size():
		phase_icon.icon_type = types[phase]
		phase_icon.queue_redraw()

func _on_dialogue_started(_visitor: VisitorData) -> void:
	hide()

func _on_dialogue_ended(_visitor: VisitorData, _choice: String) -> void:
	show()

func _refresh_day() -> void:
	day_label.text = "День %d" % GameState.current_day

func _on_journal_button_pressed() -> void:
	journal_panel.toggle()

func _on_build_button_pressed() -> void:
	EventBus.build_mode_entered.emit()

func _on_save_button_pressed() -> void:
	save_menu.toggle_save()

func _on_expedition_button_pressed() -> void:
	var panel := get_tree().get_first_node_in_group("expedition_panel") as ExpeditionPanel
	if panel:
		panel.toggle()

func _on_craft_button_pressed() -> void:
	var panel := get_tree().get_first_node_in_group("crafting_panel") as CraftingPanel
	if panel:
		panel.toggle()

func _init_player_health() -> void:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player:
		var max_hp: int = GameState.balance.player_max_health
		health_label.text = "%d/%d" % [player.health, max_hp]

func _on_player_damaged(_amount: int, remaining: int) -> void:
	var max_hp: int = GameState.balance.player_max_health
	health_label.text = "%d/%d" % [remaining, max_hp]

func _on_interaction_prompt_changed(text: String) -> void:
	interaction_prompt.text = text
	interaction_prompt.visible = not text.is_empty()
