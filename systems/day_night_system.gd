extends Node
class_name DayNightSystem
## Система игрового времени: фазы суток, переходы, сигналы через EventBus.
##
## Логика (время) здесь. Визуал (цвет, свет) — в DayNightEnvironment.
## Так можно заменить визуал или запустить быстрый тест-прогон дней без рендера.

enum Phase { DAWN, DAY, DUSK, NIGHT }

## Текущая фаза суток (читается снаружи, не изменяется напрямую).
var current_phase: Phase = Phase.DAY
## Нормализованное время внутри текущего дня [0..1].
var day_progress: float = 0.0
## Прогресс внутри текущей фазы [0..1] (нужен визуалу для lerp цвета).
var phase_progress: float = 0.0

## Пауза тика дня (например в диалоге с визитёром).
var paused: bool = false

var _phase_starts: Array[float] = []  # накопленные границы фаз [0..1]

func _ready() -> void:
	_build_phase_starts()
	# Стартуем в начале дня.
	day_progress = _phase_starts[Phase.DAY]
	_update_phase(true)

func _process(delta: float) -> void:
	if paused or GameState.balance == null:
		return
	var duration := GameState.balance.day_duration_seconds
	if duration <= 0.0:
		return
	day_progress += delta / duration
	if day_progress >= 1.0:
		day_progress -= 1.0
		GameState.advance_day()
	_update_phase(false)

func _build_phase_starts() -> void:
	_phase_starts.clear()
	var acc := 0.0
	var fractions: Array[float] = GameState.balance.phase_fractions if GameState.balance else [0.1, 0.45, 0.1, 0.35]
	for f in fractions:
		_phase_starts.append(acc)
		acc += f

func _update_phase(force: bool) -> void:
	var new_phase := _phase_for(day_progress)
	# Прогресс внутри фазы (для lerp в Environment).
	var next_start := _phase_starts[new_phase + 1] if new_phase + 1 < _phase_starts.size() else 1.0
	var span := next_start - _phase_starts[new_phase]
	phase_progress = (day_progress - _phase_starts[new_phase]) / maxf(span, 0.0001)

	if new_phase == current_phase and not force:
		return
	var old_phase := current_phase
	current_phase = new_phase
	_emit_phase_event(old_phase, new_phase)

func _phase_for(progress: float) -> Phase:
	# Идём с конца: берём последнюю фазу, чей старт <= progress.
	var result := Phase.DAWN
	for i in _phase_starts.size():
		if progress >= _phase_starts[i]:
			result = i as Phase
	return result

func _emit_phase_event(old_phase: Phase, new_phase: Phase) -> void:
	match new_phase:
		Phase.NIGHT:
			GameState.is_night = true
			EventBus.night_started.emit(GameState.current_day)
		Phase.DAY:
			GameState.is_night = false
		_:
			pass
	# Обобщённый сигнал для визуала — сообщаем новую фазу и прогресс.
	EventBus.day_phase_changed.emit(new_phase, phase_progress)

## Возвращает текущий интерполированный цвет фазы для CanvasModulate.
func get_sky_color() -> Color:
	if GameState.balance == null:
		return Color.WHITE
	var colors: Array[Color] = GameState.balance.phase_colors
	if colors.size() < 4:
		return Color.WHITE
	var next_phase := (current_phase + 1) % 4
	return colors[current_phase].lerp(colors[next_phase], phase_progress)
