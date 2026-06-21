extends Resource
class_name GameBalance
## Все баланс-числа в одном Resource. Логика систем читает значения отсюда,
## а не хардкодит их. Дизайнер тюнит баланс через .tres без правки кода.

@export_group("Визитёры")
## Минимальный/максимальный интервал между визитёрами (в днях).
@export var visitor_min_interval_days: int = 1
@export var visitor_max_interval_days: int = 3
## Базовые веса категорий в weighted random пуле (Type как индекс смысла).
@export var weight_friendly: float = 1.0
@export var weight_neutral: float = 1.0
@export var weight_hostile: float = 0.5
@export var weight_dilemma: float = 0.7
## Насколько раздутая репутация среди рейдеров поднимает вес враждебных
## (итоговый вес = weight_hostile * (1 + raider_reputation * этот множитель)).
@export var hostile_reputation_scaling: float = 3.0
## Время на принятие решения в диалоге визитёра (tension), секунды. 0 = без таймера.
@export var visitor_decision_seconds: float = 15.0

@export_group("Мораль")
@export var morale_loss_on_betrayal: float = 0.25
@export var morale_gain_on_rescue: float = 0.1
@export var manipulator_daily_morale_drain: float = 0.05

@export_group("Репутация рейдеров")
@export var reputation_gain_on_rob_trader: float = 0.15
@export var reputation_decay_per_day: float = 0.01

@export_group("Орды / шум")
## Громкость, выше которой орда меняет курс на источник шума.
@export var horde_noise_threshold: float = 0.5
## За сколько дней разведчик видит приближение орды заранее.
@export var scout_horde_warning_days: int = 2

@export_group("День / Ночь")
## Длительность одного игрового дня в реальных секундах.
@export var day_duration_seconds: float = 240.0
## Доля дня, приходящаяся на каждую фазу (сумма = 1.0).
## [dawn, day, dusk, night]
@export var phase_fractions: Array[float] = [0.1, 0.45, 0.1, 0.35]
## Цвета CanvasModulate для каждой фазы: dawn / day / dusk / night.
@export var phase_colors: Array[Color] = [
	Color(0.65, 0.55, 0.70),  # рассвет  — лиловый
	Color(1.00, 0.98, 0.95),  # день     — почти белый, чуть тёплый
	Color(0.85, 0.55, 0.30),  # закат    — оранжевый
	Color(0.13, 0.16, 0.28),  # ночь     — глубокий синий
]

@export_group("Оптимизация (mobile)")
## Жёсткий лимит активных зомби на экране (object pooling).
@export var max_active_zombies: int = 40
## Порог FPS, ниже которого орда переключается на MultiMeshInstance2D.
@export var multimesh_fps_threshold: int = 40
