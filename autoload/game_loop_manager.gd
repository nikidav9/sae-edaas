extends Node
## Управляет переходами между сценами и условиями окончания игры.
##
## Единственный источник правды о текущем состоянии игры (меню / играем / финал).
## Переходы сцен: только через этот менеджер, не напрямую.

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const GAME_SCENE := "res://scenes/main.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over.tscn"

## true — если сейчас выполняется переход (блокирует двойной trigger).
var _transitioning: bool = false

func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	EventBus.morale_changed.connect(_on_morale_changed)
	EventBus.player_died.connect(_on_player_died)

# --- Публичный API ---

func start_new_game() -> void:
	if _transitioning:
		return
	GameState.reset()
	_change_scene(GAME_SCENE)
	EventBus.game_started.emit()

func continue_game(slot: int) -> void:
	if _transitioning:
		return
	SaveSystem.load_game(slot)
	_change_scene(GAME_SCENE)
	EventBus.game_started.emit()

func return_to_menu() -> void:
	if _transitioning:
		return
	_change_scene(MAIN_MENU_SCENE)

# --- Условия поражения ---

func _on_morale_changed(new_value: float, _delta: float) -> void:
	if new_value <= 0.0 and not _transitioning:
		EventBus.game_over.emit("Мораль группы упала до нуля.\nЛагерь распался.")

func _on_player_died() -> void:
	if not _transitioning:
		EventBus.game_over.emit("Ты погиб.\nЛагерь остался без лидера.")

func _on_game_over(reason: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	GameState.game_over_reason = reason
	# Пауза для эффекта перед переходом.
	await get_tree().create_timer(1.5).timeout
	_change_scene(GAME_OVER_SCENE)

func _change_scene(path: String) -> void:
	_transitioning = true
	get_tree().change_scene_to_file(path)
	# Сбрасываем флаг после перехода (следующий кадр).
	await get_tree().process_frame
	_transitioning = false
