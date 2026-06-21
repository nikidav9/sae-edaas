extends CanvasLayer
class_name HUD
## Главный HUD лагеря: ресурсы, мораль, день, иконка фазы, кнопка журнала.
## Скрывается автоматически когда открыт диалог визитёра.

## Иконки фаз суток (текстовые заглушки до появления арта).
const PHASE_ICONS: Array[String] = ["🌅", "☀️", "🌇", "🌙"]

@onready var day_label: Label = %DayLabel
@onready var phase_icon: Label = %PhaseIcon
@onready var food_display: ResourceDisplay = %FoodDisplay
@onready var materials_display: ResourceDisplay = %MaterialsDisplay
@onready var medicine_display: ResourceDisplay = %MedicineDisplay
@onready var morale_bar: MoraleBar = %MoraleBar
@onready var journal_button: Button = %JournalButton
@onready var journal_panel: JournalPanel = %JournalPanel
@onready var build_button: Button = %BuildButton

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.day_phase_changed.connect(_on_phase_changed)
	EventBus.visitor_dialogue_started.connect(_on_dialogue_started)
	EventBus.visitor_resolved.connect(_on_dialogue_ended)
	_refresh_day()

func _on_day_passed(day: int) -> void:
	day_label.text = "День %d" % day

func _on_phase_changed(phase: int, _progress: float) -> void:
	if phase < PHASE_ICONS.size():
		phase_icon.text = PHASE_ICONS[phase]

func _on_dialogue_started(_visitor: VisitorData) -> void:
	# Скрываем HUD пока идёт диалог — диалоговый UI занимает нижнюю часть.
	hide()

func _on_dialogue_ended(_visitor: VisitorData, _choice: String) -> void:
	show()

func _refresh_day() -> void:
	day_label.text = "День %d" % GameState.current_day

func _on_journal_button_pressed() -> void:
	journal_panel.toggle()

func _on_build_button_pressed() -> void:
	EventBus.build_mode_entered.emit()
